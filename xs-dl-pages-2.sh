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

rm -f urls.txt

cat browse.html | sed ':a;N;$!ba;s/\n/;;/g' | awk -F "collapseobj_categories" '{print $NF}' | awk -F "collapseobj_search" '{print $1}' | sed "s/;;/\n/g" | grep "browse.php?category=" | awk '{for (i=1; i<=NF; i++){if(($i ~ "browse.php?") && !($i ~ "img") && !($i ~ "</a>")) system("echo -n "substr($i,7,length($i)-7)" >> urls.txt"); else if ($i ~ "<b>") {system("echo \";\""substr($0,index($0,"<b>")+3,index($0,"</b>")-index($0,"<b>")-3)" >> urls.txt")} else if (($i ~ "title=\"\">") && !($i ~ "<b>")) {system("echo \";\""substr($0,index($0,"title=\"\">")+9,index($0,"</a>")-index($0,"title=\"\">")-9)" >> urls.txt")} else if (($i ~ "title") && !($i ~ "title=\"\"") && ($(i-1) ~ "category")) {system("echo \";\""substr($0,index($0,"\">")+2,index($0,"</a>")-index($0,"\">")-2)" >> urls.txt")}}}'

#TODO 1 : problème : il y a quelques échecs : download.php... -> ajouter des traces et voir
#TODO 2 : ajouter un "&" à la fin du curl de download. A chaque download, ajouter dans un fichier une ligne contenant l'url en cours et le nom du fichier si possible ? 
#TODO 2 suite : A la fin du traitement de chaque catégorie, parcourir ce fichier et retenter...
#TODO 3 : détecter technical difficulties
#TODO 4 : comprendre pourquoi le temps d'éxécution augmente page après page

while read line
do
    url=$(echo $line | awk -F ";" '{print $1}')
    category=$(echo $line | awk -F ";" '{print $2}')
    echo "url = $url"
    echo "cat = $category"
    if echo "$category" | grep "/"
    then
        echo "un / trouve dans le nom : on le remplace par un -"
        category=$(echo $category | tr "/" "-")
    fi
    if [ -d "$category" ]
    then
        echo "le repertoire $category existe, on passe"
        continue
    fi
    echo "date : $(date +%Y/%m/%d\ %H:%M:%S)"
    echo "creation du repertoire pour la categorie $category"
    mkdir "$category"
    cd "$category"
    pwd
    echo "telechargement de la page associee a la categorie"
    curl "$url" --compressed -s -b ../authCookie.txt -o currentCategory.html
    pageCount=$(grep -A 2 -m 1 "navcontainer_f" currentCategory.html | tail -1 | awk -F "- " '{print $2}' | awk -F "<" '{print $1}')
    echo "pageCount = $pageCount"
    for i in $(seq 1 $pageCount)
    do
        echo "page : $i"
        date
        start=$(date +%s)
        curl "$url&page=$i" --compressed -s -b ../authCookie.txt -o currentPage.html
        grep "download.php?id=" currentPage.html | awk '{for(i=1; i<=NF; i++){if ($i ~ "href="){print substr($i,7,index($i,"\">")-7)}}}' > links.txt
        nbFiles=$(cat links.txt | wc -l)
        echo "nombre de torrents : $nbFiles"
        while read line2
        do
            ok=0
            while [ $ok -eq "0" ]
            do
                suffix=$(echo $line2 | awk -F "id=" '{print $NF}')
                curl -O -J -L -C - -b ../authCookie.txt -s -D dump_$suffix.txt --limit-rate 900K --max-time 60 --retry 3 $line2
                filename=$(grep "filename=" dump_$suffix.txt | awk -F "=" '{print $NF}' | awk -F ";" '{print $1}')
                if echo "$filename" | grep ".torrent" > /dev/null || [ -z "$filename" ]
                then
                    # nom de fichier correct ou vide car interdit
                    ok=1
                else
                    echo "nom de fichier incorrect : $filename"
                    ok=0
                fi
            done
        done < links.txt
        rm currentPage.html
        rm links.txt
        end=$(date +%s)
        duration=$((end-start))
        echo "duree page $i = $duration s"
    done
    rm currentCategory.html
    echo "on remonte d'un dossier"
    cd ..
done < urls.txt

rm urls.txt

