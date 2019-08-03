#!/bin/bash

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
domain="Argus-Presse"
rootFolder=$(date +%Y%m%d-%H%M%S)
echo "working in folder $rootFolder"
mkdir -p $rootFolder
cd $rootFolder

# GET sur la page de login
curl 'https://github.com/login' --compressed -s -c cookie_github_0.txt -o login.txt

# récupération du authenticity_token
token=$(grep "authenticity_token" login.txt | awk -F "value=\"" '{print $NF}' | awk -F "\"" '{print $1}' | sed "s/\//%2F/g" | sed "s/+/%2B/g" | sed "s/=/%3D/g")
echo "authenticity_token = $token"
# authentification au site GitHub avec le user et password passés en paramètre :
curl 'https://github.com/session' -H 'Origin: https://github.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.146 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://github.com/' -H 'Connection: keep-alive' --data  "commit=Sign+in&utf8=%E2%9C%93&authenticity_token=$token&login=$username&password=$password" --compressed -L -s -b cookie_github_0.txt -c cookie_github_1.txt -o output_post.txt

# récupération de la première page du domaine
i=1
echo "telechargement de la premiere page"
curl "https://github.com/$domain?page=$i" --compressed -s -b cookie_github_1.txt -o page$i.txt

# téléchargement des dépôts de la page
grep "<a href=\"/$domain/" page$i.txt | awk -F "$domain/" '{print $2}' | awk -F "\"" '{print $1}' | tr "\n" ";" | awk -F ";" '{print $0}' | awk -F ";" -v var="$domain" '{for(i=1; i<NF; i++){print "clone du depot "$i" ";system("echo git@github.com:"var"/"$i".git");}}'

# tant qu'il y a une page suivante, on la télécharge et on récupère ses dépôts
while [ $(grep -c "a class=\"next_page\"" page$i.txt) -eq "1" ]
do
    ((i++))
    echo "telechargement de la page $i"
    curl "https://github.com/$domain?page=$i" --compressed -s -b cookie_github_1.txt -o page$i.txt
    grep "<a href=\"/$domain/" page$i.txt | awk -F "$domain/" '{print $2}' | awk -F "\"" '{print $1}' | tr "\n" ";" | awk -F ";" '{print $0}' | awk -F ";" -v var="$domain" '{for(i=1; i<NF; i++){print "clone du depot "$i" ";system("echo git@github.com:"var"/"$i".git");}}'
done

echo "fin"

exit 0



