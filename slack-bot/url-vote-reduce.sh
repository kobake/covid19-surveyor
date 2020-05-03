#!/bin/bash
set -e

#
# Summary:
#   Redis に貯まった回答結果をもとに、スコアが 1 以上であるものだけを抽出し、
#   csv を出力する (Makefile 経由で data/reduce-vote.csv というファイルが生成される)
#
# CSV出力例:
#   --------------------------------------------------------------------------------
#   # Summary: 投票結果により有効とみなされたページ一覧
#   # Generated: 2020-05-02 01:26:36 +0900, in /home/ubuntu/vscovid-crawler
#   #
#   # 市区町村名,都道府県名,ページURL,ページタイトル,ページ内文章
#   札幌市,北海道,https://www.city.sapporo.jp/kinkyu/seikatsushien/202003/index.html,生活支援ガイド／札幌市,ホーム&gt;新型コロナウイルス感染症について&gt;生活支援ガイド 生活支援ガイドは、新
#   村山市,山形県,https://www.city.murayama.lg.jp/jigyosha/shoukougyousien/tokunaisikinnaruhuxa.html,利子補給融資制度『徳内資金α』について　村山市,新型コロナウイルス感染症に関連する商工業支援 市は、新型コロナウイルス感染症の影響により、
#   ....
#   ....
#   --------------------------------------------------------------------------------
#
# Input:
#   Redis: Key: vscovid-crawler-vote:result-{url_hash} ... vote 方式の全投票
#          Value: "-2", "-1", "0", "1", "2", ... 等の投票結果を示す数値文字列

# 依存lib
. ./lib/_common.sh
. ./lib/url-helper.sh
. ./lib/string-helper.sh

get_row_by_url() {
    url=$1
    orgname=$(get_orgname_by_url $url)
    prefname=$(get_prefname_by_url $url)
    res=$(wget -q -O - --timeout=5 $url) # ここが重い
    if [ $? -ne 0 ]; then
        echo "RETURN"
        return 1
    fi
    title=$(get_title_by_res "$res")
    desc=$(get_desc_by_res "$res" | remove_newline_and_comma)
    echo $orgname,$prefname,$url,$title,$desc
}


get_url_by_md5() {
    md5=$1
    url=$(grep "$md5" ./data/urls-md5.csv | head -1 | cut -d',' -f 2)
    echo $url
}

main() {
    # ヘッダ行
    echo "# Summary: 投票結果により有効とみなされたページ一覧"
    echo "# Generated: `tokyo_datetime`, in `pwd`"
    echo "#"
    echo "# 市区町村名,都道府県名,ページURL,ページタイトル,ページ内文章"

    # 走査対象キー配列
    keys=($(redis-cli KEYS "vscovid-crawler-vote:result-*"))

    # 進捗表示準備
    total=${#keys[@]}
    i=0

    # 走査
    for key in ${keys[@]}; do
        # -- -- 進捗表示 -- -- #
        i=$((i+1))
        >&2 echo "... url-vote-reduce $i/$total $key"

        # -- -- 判定 -- -- #
        # Redis のキー値から MD5 を抽出
        # 例: vscovid-crawler-vote:result-a69422fd8877321cd534d983de001720 -> a69422fd8877321cd534d983de001720
        md5=$(echo $key| cut -d'-' -f 4)

        # 投票によるスコア値が 0 以下の場合は出力を行わない
        score=$(redis-cli GET $key)
        if [[ $score == "0" ]]; then
            continue
        elif [[ $score == -* ]]; then
            continue
        fi

        # MD5 -> URL
        url=`get_url_by_md5 $md5`
        if [[ $url == "" ]]; then
            continue
        fi

        # -- -- 進捗表示 -- -- #
        >&2 echo "... -> url = $url"

        # -- -- 出力 -- -- #
        echo `get_row_by_url $url`
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main $@
fi