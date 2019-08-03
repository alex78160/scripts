#!/bin/bash

if [ -z "$1" ]; then
	echo "pas de numero de suivi en parametre"
	exit 1
fi
numero=$1
attente=10
#erreur : 3Y00127983170
# ok : 3Y00127984139
#3Y00127977735 last

curl "https://www.laposte.fr/outils/suivre-vos-envois" -H "Host: www.laposte.fr" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:60.0) Gecko/20100101 Firefox/60.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3" --compressed -H "DNT: 1" -H "Connection: keep-alive" -H "Upgrade-Insecure-Requests: 1" --silent -c cookie.txt -o /dev/null

curl "https://api.laposte.fr/ssu/v1/suivi-unifie/idship/$numero?lang=fr_FR" -H 'Accept: application/json' -H 'Referer: https://www.laposte.fr/outils/suivre-vos-envois' -H 'Origin: https://www.laposte.fr' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36' --compressed --silent --output suivi.json -b cookie.txt
nbEvents=$(env json="$(cat suivi.json)"  node -e "var object = JSON.parse(process.env.json); console.log(object.shipment.event.length);")

while [ "$nbEvents" -eq "1" ]; do
	echo "1 seul event, attente $attente"
	sleep $attente
	curl "https://api.laposte.fr/ssu/v1/suivi-unifie/idship/$numero?lang=fr_FR" -H 'Accept: application/json' -H 'Referer: https://www.laposte.fr/outils/suivre-vos-envois' -H 'Origin: https://www.laposte.fr' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36' --compressed --silent --output suivi.json -b cookie.txt
	nbEvents=$(env json="$(cat suivi.json)"  node -e "var object = JSON.parse(process.env.json); console.log(object.shipment.event.length);")
done

lastEvent=$(env json="$(cat suivi.json)"  node -e "var object = JSON.parse(process.env.json); console.log(JSON.stringify(object.shipment.event[0]));")
echo "last event : $lastEvent"
#TODO mail à envoyer

finalEventStatus=$(env json="$(cat suivi.json)"  node -e "var object = JSON.parse(process.env.json); console.log(object.shipment.timeline[4].status);")

if $finalEventStatus; then
	echo "courrier distribue !"
	exit 0
fi

while true; do
	curl "https://api.laposte.fr/ssu/v1/suivi-unifie/idship/$numero?lang=fr_FR" -H 'Accept: application/json' -H 'Referer: https://www.laposte.fr/outils/suivre-vos-envois' -H 'Origin: https://www.laposte.fr' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36' --compressed --silent --output suivi.json -b cookie.txt
	nbEventsNewAndLastEvent=$(env json="$(cat suivi.json)"  node -e "var object = JSON.parse(process.env.json); console.log(object.shipment.event.length + \"/\" + JSON.stringify(object.shipment.event[0]));")
	nbEventsNew=$(echo $nbEventsNewAndLastEvent | awk -F "/" '{print $1}')
	if [ "$nbEvents" -eq "$nbEventsNew" ]; then
		sleep $attente
	else
		lastEvent=$(echo $nbEventsNewAndLastEvent | awk -F "/" '{print $2}')
		echo "nbEvents : $nbEventsNew - last event : $lastEvent"
		#TODO mail à envoyer
		nbEvents=$nbEventsNew
	fi
done
