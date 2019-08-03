#!/bin/bash


ALERT_THRESHOLD=5
globalErrorCount=0
intervalle=5s
resetTime=3600

iterationsBeforeReset=$((resetTime/intervalle))
iterations=0
echo "iterationsBeforeReset : $iterationsBeforeReset"
logFile="/var/log/auth.log"

#TODO si répertoire inexistant le créer
tmpLogFile="/home/alex/scripts/log/tmplog.txt"

rm "$tmpLogFile"
tail -f -n 0 "$logFile" > "$tmpLogFile" &
pidEcho=$!

#Aug 30 21:08:28 alex-G73Sw sshd[25861]: Failed password for alex78160 from 192.168.0.254 port 55104 ssh2

while true
do

   iterations=$((iterations+1))

   if [ "$iterations" -ge "$iterationsBeforeReset" ]
   then
      echo "reset"
      iterations=0
      # reset du compteur
      errorCount=0
   fi

   echo "attente $intervalle"
   sleep "$intervalle"

# on recherche le nombre d'occurences de la chaine "Failed password"
# depuis le dernier test donc, après ce test, on réinitialise le tmpLogFile
# mais on conserve le compteur global

   errorCount=$(grep -c "Failed password" "$tmpLogFile")
   # récupérer toutes les lignes qui suivent chaque occurence et extraire la phrase
   # last message repeated x times si elle existe et prendre le x et l'ajouter
   if [ "$errorCount" -gt "0" ]
   then   
      complement=$(grep -A 1 "Failed password" "$tmpLogFile" | grep "last message repeated" | awk -F 'repeated ' '{print $NF}' | awk '{print $1}' | awk -v somme=0 '{for(i=1; i<=NF; i++){print $(i-1); somme+=$(i-1);}print somme}' | tail -1)
   else
      complement=0
   fi

   if [ -z "$complement" ]
   then
      complement=0
   fi
   
   errorCount=$((errorCount+complement))
   complement=0
   echo "error = $errorCount"
   echo "complement = $complement"

   if [ $errorCount -gt $ALERT_THRESHOLD ]
   then
      echo "ALERTE, ARRET DU SSH"
      sudo service ssh stop
      echo "arret du serveur ssh" | mail -s "ssh - alerte securite" alexandre.genelle@gmail.com
      echo "arret du serveur ssh" | mail -s "ssh - alerte securite"  alexandre.genelle@argus-presse.fr
      exit 1
   fi

   # on réinitialise le fichier tmp de logs
   echo "destfile avant reset : "
   cat "$tmpLogFile"

done

