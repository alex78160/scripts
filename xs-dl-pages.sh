#!/bin/bash

if [ -z $1 ]
then
    echo "il manque le chemin du dossier contenant les cookies et la page de navigation"
    exit 1
fi

rootFolder=$1

if [ ! -d "$rootFolder" ]
then
    echo "le repertoire $rootFolder n'existe pas"
    exit 1
fi

echo "working in folder $rootFolder"

cd $rootFolder

pageCount=$(grep -A 2 -m 1 "navcontainer_f" browse.html | tail -1 | awk -F "- " '{print $2}' | awk -F "<" '{print $1}')
echo "pageCount = $pageCount"

for i in $(seq 1 3)
do
    echo "page : $i"
    #wget "https://www.xspeeds.eu/browse.php?include_dead_torrents=no&page=$i&scrollto=tspager" -q --load-cookies=authCookie.txt -O currentPage.html
    curl "https://www.xspeeds.eu/browse.php?include_dead_torrents=no&page=$i&scrollto=tspager" --compressed -s -b authCookie.txt -o currentPage.html
    grep "download.php?id=" currentPage.html | awk '{for(i=1; i<=NF; i++){if ($i ~ "href="){print substr($i,7,index($i,"\">")-7)}}}' > links$i.txt
    nbFiles=$(cat links$i.txt | wc -l)
    echo "nombre de torrents : $nbFiles"

    while read line
    do
        curl -O -J -L -b authCookie.txt -s $line
    done < links$i.txt
done

