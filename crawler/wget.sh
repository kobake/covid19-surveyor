#!/bin/bash
set -e

###
### About:
###   引数で指定されたCSVファイルを対象にミラーリングするシェルスクリプト
###   入力CSVのフォーマットは
###   組織名,略称,URL
###
### Dependency:
###   None
###
### Input:
###   コマンドライン引数で与えられた CSV ファイル群
###
### Output:
###   ./www-data/*
###
### Usage (run script directly)
###   $ ./crawler/wget.sh {file1} [{file2}] [{file3}] ...
###
###   e.g.) $ ./crawler/wget.sh data/test.csv
###         $ ./crawler/wget.sh data/gov.csv data/pref.csv data/city.csv
###
### Usage (make command)
###   $ make wget
###

. ./lib/url-helper.sh

# tested
get_target_urls() {
    urls=()
    # $#は引数の個数
    while (( $# > 0 )); do
        # $1は1つ目の引数
        urls=("${urls[@]} $(cat $1 | cut -d',' -f 3)")
        # shiftで次の引数を$1に入れている
        shift
    done
    echo ${urls}
    return 0
}

# tested
get_target_domains() {
    domains=()
    while (( $# > 0 )); do
        domain=$(get_domain_by_url $1)
        # domains配列に追加
        domains=("${domains} $domain")
        shift
    done
    echo $domains
    return 0
}

main() {
    args=$*
    urls=$(get_target_urls $args)
    domains=$(get_target_domains $urls)
    # ダウンロード対象の拡張子
    ext=$(jq -r .ext[] ./accepted-file-extensions.json | tr '\n' '|' | rev | cut -c 2- | rev)

    pushd www-data
    # urls配列の中身をwgetに渡している
    echo ${urls} | xargs -n 1 echo | xargs -P 16 -I{} wget -l 2 -r --accept-regex "\.(${ext})$" --no-check-certificate {}
    echo ${domains} | xargs -n 1 echo | xargs -I{} cp -f ../robots.txt {}
    popd
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main $@
fi
