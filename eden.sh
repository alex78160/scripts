#!/bin/bash

export LANG=en_US.UTF-8
if [ -z $1 ]
then
  echo "il manque le user name"
  exit 1
fi

username="$1"

if [ -z $2 ]
then
  echo "il manque le password"
  exit 1
fi

password="$2"

rootfolder="/media/data/dev/alex78160/scripts/eden/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$rootfolder"
LOGFILE="$rootfolder/eden.txt"
cd $rootfolder
echo -e "date : $(date +%Y-%m-%d\ %H:%M:%S)\n" >> $LOGFILE

curl 'https://www.myedenred.fr/ctr?Length=7' -H 'Origin: https://www.myedenred.fr' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://www.myedenred.fr/ExtendedAccount/Logon?ReturnUrl=%2f' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --data "ReturnUrl=%2F&Email=$username&Password=$password&RememberMe=false&X-Requested-With=XMLHttpRequest" --compressed -s -c cookie-eden.txt -o output-eden1.html

curl 'https://www.myedenred.fr/' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://www.myedenred.fr/ExtendedAccount/Logon?ReturnUrl=%2f' -H 'Connection: keep-alive' --compressed -s -b cookie-eden.txt -o output-eden2.html

solde=$(grep -m 2 "Solde" output-eden2.html | awk -F "</strong>" '{printf $1}' | awk -F ">" '{print $NF}')
echo -e "solde ticket restaurant : $solde\n" >> $LOGFILE

curl 'https://www.myedenred.fr/ExtendedCard?q=QjNkSzdKelZSVHhsakc2TE9haTBnOUdBNGZJUmxvRStBeVdaaWNhaEpoUT01' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://www.myedenred.fr/ExtendedAccount/Logon?ReturnUrl=%2f' -H 'Connection: keep-alive' --compressed -s -b cookie-eden.txt -o output-eden3.html

soldeJour=$(grep -B 1 "solde du jour" output-eden3.html | head -n 1 | awk -F "<strong>" '{print $NF}' | awk -F "</strong>" '{print $1}')
echo -e "solde du jour : $soldeJour\n" >> $LOGFILE

curl 'https://www.myedenred.fr/Card/Transaction?q=Z2NrT1NuME9LbkFzdnRYRDJjVTJ6UzNiQTBzRGY3d0RuUnpITTNBYnJ3WT01' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://www.myedenred.fr/ExtendedAccount/Logon?ReturnUrl=%2f' -H 'Connection: keep-alive' --compressed -s -b cookie-eden.txt -o output-eden4.html

cat output-eden4.html | tr -d '\r' | tr '\n' ';' | awk -F "table-transaction" '{print $2}' | awk -F "<td" '{for(i=1; i<=NF; i++){if ($i ~ "badge-l") {val=index($i,"<span>");print "date : "substr($i,val-5,5);} else if ($i ~ "<h3>"){val=index($i,"</i>"); val2=index($i,"<strong>"); val3=index($i,"</strong>"); val4=substr($i,val+5,val2-val-7); sub(" *", "", val4); sub(/[ \t\r\n]+$/, "", val4); sub(";", "", val4); val5=substr($i, val2+8, val3-val2-8); sub(";", "", val5); sub(/^[ \t\r\n]+/, "", val5); print "facture : "val4" - "val5} else if ($i ~ "al-r"){val=index($i, "-;"); val2=index($i, "</span>"); val3=substr($i, val+2, val2-val-7); sub(" *", "", val3); sub(/[ \t\r\n]+$/, "", val3); print "montant : "val3"\n"}}}' >> $LOGFILE

#cat $LOGFILE | mail -s "jenkins - solde ticket restaurant : $solde" alexandre.genelle@argus-presse.fr
cat $LOGFILE

