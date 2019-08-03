#!/bin/bash

# ecrit la temperature du GPU à intervalles réguliers dans un fichier de log
# by agenelle

current_directory=$(dirname $(readlink -f "$0"))
cd $current_directory

# définition de l'intervalle entre 2 mesures et des seuils d'alerte et d'arrêt d'urgence
defaultSleepInterval=60
warningSleepInterval=10
sleepInterval=$defaultSleepInterval
warningThreshold=90
# arrêt de la machine au delà de 95°C
shutdownThreshold=95
max_kilo=256
max_bytes=$(($max_kilo*1024))

# si le fichier de log n'existe pas on le cree
if [ ! -f temp.log ]
then
   touch temp.log
fi

while true
do
   while [ $(du -b temp.log | cut -f 1) -le "$max_bytes" ]
   do
      currentTemp=$(nvidia-settings -q $DISPLAY[gpu:0]/gpucoretemp[0] -t)
      if (($currentTemp > $shutdownThreshold))
      then
         # log + ARRET IMMEDIAT de la machine car temperature GPU > 95°C : on n'attend pas la coupure materielle brutale au dela de 100°C
         (echo "$(date) - CRITICAL ! GPU temp above $shutdownThreshold ! emergency shutdown !" && echo $currentTemp) >> temp.log
         notify-send -t 5000 "CRITICAL : GPU temp above $shutdownThreshold ! emergency shutdown !"
         sudo shutdown -P now
         # cet exit est inutile normalement car la machine s'arrete !!!!!!
         exit 0
      elif (($currentTemp > $warningThreshold))
      then
         echo "$(date) - warning ! GPU temp above $warningThreshold !" >> temp.log
         notify-send -t 10000 "=========================================================================================================================================== ****************************************************************** WARNING ! GPU temp above $warningThreshold ! ************************************************************ ==========================================================================================================================================="
         sleepInterval=$warningSleepInterval
      else
         date >> temp.log
         sleepInterval=$defaultSleepInterval
      fi
      echo $currentTemp >> temp.log
      sleep $sleepInterval
   done
   mv temp.log temp-$(date +%Y-%m-%d-%H-%M-%S).log
   touch temp.log
done

