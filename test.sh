#!/bin/bash

#cat browse.html | sed ':a;N;$!ba;s/\n/;;/g' | awk -F "collapseobj_categories" '{print $NF}' | awk -F "collapseobj_search" '{print $1}' | sed "s/;;/\n/g" | grep "browse.php?category=" | awk '{for (i=1; i<=NF; i++){if(($i ~ "browse.php?") && !($i ~ "img") && !($i ~ "</a>")) system("echo "substr($i,7,length($i)-7)" >> urls.txt"); else if ($i ~ "<b>") {system("echo "substr($0,index($0,"<b>")+3,index($0,"</b>")-index($0,"<b>")-3)" >> titles.txt")} else if (($i ~ "title=\"\">") && !($i ~ "<b>")) {system("echo "substr($0,index($0,"title=\"\">")+9,index($0,"</a>")-index($0,"title=\"\">")-9)" >> titles.txt")} else if (($i ~ "title") && !($i ~ "title=\"\"") && ($(i-1) ~ "category")) {system("echo "substr($0,index($0,"\">")+2,index($0,"</a>")-index($0,"\">")-2)" >> titles.txt")}}}'

while true
do
    echo $(date +"%Y-%m-%d %H:%M:%S,%3N") >> /home/alex/out.txt
    sleep 10
done
exit


variable=$(pwd)
echo "variable = "$variable
cpt=10
intvar=$cpt
((cpt--))
echo "cpt = $cpt"
if (($cpt > 10))
then
    echo "sup 10"
else
    echo "pas sup 10"
fi
exit 0


start=$(date +%s)
echo "$start"
sleep 4
end=$(date +%s)
echo "$end"
duration=$((end-start))
echo "duration = $duration"
exit

ok=1
while read line2 && [ $ok -eq "0" ]
do
	echo "line2 = $line2"
done < ttt1
exit

category="mmm/4kkk"
    if echo "$category" | grep "/"
    then
        echo "ok"
		else
		echo "ko"
    fi
    exit


while true
do
    date +"%Y-%m-%d %H:%M:%S,%3N"
    sleep 0.1
done
exit


rm -f urls.txt

cat browse.html | sed ':a;N;$!ba;s/\n/;;/g' | awk -F "collapseobj_categories" '{print $NF}' | awk -F "collapseobj_search" '{print $1}' | sed "s/;;/\n/g" | grep "browse.php?category=" | awk '{for (i=1; i<=NF; i++){if(($i ~ "browse.php?") && !($i ~ "img") && !($i ~ "</a>")) system("echo -n "substr($i,7,length($i)-7)" >> urls.txt"); else if ($i ~ "<b>") {system("echo \";\""substr($0,index($0,"<b>")+3,index($0,"</b>")-index($0,"<b>")-3)" >> urls.txt")} else if (($i ~ "title=\"\">") && !($i ~ "<b>")) {system("echo \";\""substr($0,index($0,"title=\"\">")+9,index($0,"</a>")-index($0,"title=\"\">")-9)" >> urls.txt")} else if (($i ~ "title") && !($i ~ "title=\"\"") && ($(i-1) ~ "category")) {system("echo \";\""substr($0,index($0,"\">")+2,index($0,"</a>")-index($0,"\">")-2)" >> urls.txt")}}}'

while read line
do
    url=$(echo $line | awk -F ";" '{print $1}')
    category=$(echo $line | awk -F ";" '{print $2}')
    echo "url = $url"
    echo "cat = $category"
    echo "creation du repertoire pour la categorie $category"
    mkdir $category
    cd $category
    echo "telechargement de la page associee a la categorie"
    curl "$url" --compressed -s -b authCookie.txt -o currentCategory.html
    pageCount=$(grep -A 2 -m 1 "navcontainer_f" currentCategory.html | tail -1 | awk -F "- " '{print $2}' | awk -F "<" '{print $1}')
    echo "pageCount = $pageCount"
    for i in $(seq 1 $pageCount)
    do
        echo "page : $i"
        curl "$url&page=$i" --compressed -s -b authCookie.txt -o currentPage.html
        grep "download.php?id=" currentPage.html | awk '{for(i=1; i<=NF; i++){if ($i ~ "href="){print substr($i,7,index($i,"\">")-7)}}}' > links.txt
        nbFiles=$(cat links.txt | wc -l)
        echo "nombre de torrents : $nbFiles"

        while read line2
        do
            curl -O -J -L -b authCookie.txt -s $line2
        done < links.txt
    done
    echo "on remonte d'un dossier"
    cd ..
    #curl -O -J -L -b authCookie.txt -s $line
done < urls.txt


