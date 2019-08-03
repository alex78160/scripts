#!/bin/bash
# script permettant de detecter, a partir d'une liste d'IP de depart, toute nouvelle addresse
# ou celles qui ont disparu.
fileInit="file-init.txt"
fileCapture="capture-tmp.txt"
sleepInterval=20
interface=eth0
reseau=192.168.1.0-255
# saisir les parametres en entree :
# -f file : logToFile
# -i interface : interface reseau pour les recherches
# -t time : temps d'attente entre 2 scans
# -s : silent : pas de log dans la console
# -r reseau : IP ou plage pour les requêtes ex : 192.168.0.1-255
# -m mail : mail destinataire des alertes
# -v : verbose

function machineDown() {
   echo "old down : $1"
}

function machineUp() {
   echo "new up : $1"
}

if [ -f "$fileInit" ]; then
   echo "$fileInit existe, on le supprime"
   rm "$fileInit"
fi

if [ -f "$fileCapture" ]; then
   echo "$fileCapture existe, on le supprime"
   rm "$fileCapture"
fi

echo "collecte initiale"
#nmap -sP -e eth0 192.168.0.0-255 > output1.txt
#cat output1.txt | grep "scan report for" | awk -F 'scan report for' '{print $NF}' | awk '{if(index($0,"(")==0) {trim=$0; gsub(" ","",trim); print trim;} else {indexStart=index($0,"("); indexEnd=index($0,")"); diff=indexEnd-indexStart; print substr($0, indexStart+1, diff-1);}}' > "$fileInit"
nmap -sP "$reseau" | grep "scan report for" | awk -F 'scan report for' '{print $NF}' | awk '{if(index($0,"(")==0) {trim=$0; gsub(" ","",trim); print trim;} else {indexStart=index($0,"("); indexEnd=index($0,")"); diff=indexEnd-indexStart; print substr($0, indexStart+1, diff-1);}}' > "$fileInit"

echo "constitution de la liste initiale"
listeInitiale=(`cat $fileInit`)

echo "${#listeInitiale[@]} elements trouves : "
for ((i=1; i<=${#listeInitiale[@]}; i++)) 
do 
   echo "element : ${listeInitiale[$i-1]}"
done

echo "entree dans la boucle infinie"

while true
do
   echo "sleep $sleepInterval"
   sleep "$sleepInterval"
   echo "lancement commande"
   nmap -sP "$reseau" | grep "scan report for" | awk -F 'scan report for' '{print $NF}' | awk '{if(index($0,"(")==0) {trim=$0; gsub(" ","",trim); print trim;} else {indexStart=index($0,"("); indexEnd=index($0,")"); diff=indexEnd-indexStart; print substr($0, indexStart+1, diff-1);}}' > "$fileCapture"
   echo "constitution de la nouvelle liste"
   listeCourante=(`cat $fileCapture`)


   # recherche des elements supprimes
   # parcours de la liste initiale et pour chaque élément, vérifier s'il est dans la nouvelle liste
   for ((i=1; i<=${#listeInitiale[@]}; i++)) 
   do 
      elementInitial="${listeInitiale[$i-1]}"
      #echo "element initial : $elementInitial"
      echo "recherche de $elementInitial dans listeCourante"
      trouve=false;
      for ((j=1; j<=${#listeCourante[@]}; j++)) 
      do
         elementCourant="${listeCourante[$j-1]}"
         echo "elementCourant : $elementCourant"
         if [[ "$elementCourant" == "$elementInitial" ]]
         then
            echo "trouve"
            trouve=true
            break;
         fi
      done
      if (! $trouve)
      then
         echo "$elementInitial non trouve"
         machineDown "$elementInitial"
      fi 
   done

   # recherche des nouveaux elements : 
   # parcours de la listeCourante et pour chaque element,
   # s'il n'est pas present dans listeInitiale, alors il est nouveau
   for ((i=1; i<=${#listeCourante[@]}; i++)) 
   do 
      elementCourant="${listeCourante[$i-1]}"
      #echo "element courant : $elementCourant"
      echo "recherche de $elementCourant dans listeInitiale"
      trouve=false;
      for ((j=1; j<=${#listeInitiale[@]}; j++)) 
      do
         elementInitial="${listeInitiale[$j-1]}"
         echo "elementInitial : $elementInitial"
         if [[ "$elementCourant" == "$elementInitial" ]]
         then
            echo "trouve"
            trouve=true
            break;
         fi
      done
      if (! $trouve)
      then
         echo "$elementCourant non trouve"
         machineUp "$elementCourant"
      fi 
   done

   echo "le tableau courant devient le tableau initial"
   listeInitiale=("${listeCourante[@]}")
   echo "listeInitiale nouvelle : ${listeInitiale[@]}"
   # on reboucle ensuite à interalles réguliers

done

