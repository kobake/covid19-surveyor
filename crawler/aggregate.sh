#!/bin/bash
set -e

###
### About
### grep.shで./tmpに収集した情報を結合し、ソートし、重複を取り除くスクリプト
###
### Dependency
### - make wget
### - make grep
###
### Usage
### - make aggregate
###


# ファイルを結合して一つにまとめる
cat ./tmp/grep_コロナ_*.txt.tmp > ./tmp/cat.txt.tmp
# ソートする
sort ./tmp/cat.txt.tmp > ./tmp/sort.txt.tmp
# 重複を取り除く
uniq -d ./tmp/sort.txt.tmp > ./tmp/results.txt

# results.txtからurlのみを抜き出す
urls=""
for line in `cat ./tmp/results.txt`; do
    url=$line
    url=`echo ${url} | cut -d':' -f 1`
    url=`echo ${url} | sed -z 's/\.\/www-data\///g'`
    urls=("${urls}\n${url}")
done

echo -e $urls > ./tmp/urls.txt.tmp

uniq ./tmp/urls.txt.tmp > ./tmp/urls.txt
