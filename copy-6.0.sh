#!/bin/bash
# ci-dessous pour corriger le problème du format du fichier .sh
# qui génère des erreur à l'éxécution
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is needed

#######################################################################################################
# DESCRIPTION
#######################################################################################################

usage="$(basename "$0") [-s dossier] [-d dossier] [-f fichier] [-t heures] [-T heures] [-x fichier] [-i] [-v] [-c] [-C] [-F] [-q] [-b] [-h]\n
Script permettant de copier un dossier source vers un dossier de destination.\n
L'interet de ce script est qu'il permet de spécifier des restrictions sur la date de dernière modif\n
 (ex : traiter seulement les fichiers modifiés dans la dernière heure)\n
De plus, on peut spécifier dans un fichier une liste de patterns à exclure dans la copie, comme *CVS* par exemple.\n
Ce fichier contiendra chaque pattern sur une ligne.\n
On peut specifier des options pour loguer dans la console, dans un fichier, ou les deux.\n
On peut egalement choisir entre un traitement iteratif ou recursif des dossiers.\n
Une autre option permet de garder une sauvegarde d'un fichier de destination écrasé, au cas où...\n
Ce dernier est plus long pour une copie complete mais bien plus rapide lorsqu'une partie des dossiers a deja ete copiee.\n
Il est possible de demander confirmation sur écrasement de fichier local ou bien de spécifier\n
une date de dernière modif du fichier local permettant de l'écraser en silence s'il est ancien.\n
ex : ./copy-5.0.sh -s /media/data/argus/dev/sh/test/argusCMS -d /media/data/argus/dev/sh/test/cms -x x.txt -f lognew.txt\n
ex : ./copy-5.0.sh -x x.txt -f log.txt -v -c -F -t 2 -T 1 -s /cygdrive/c/dev/tmp/argusCMS -d /cygdrive/c/dev/tmp/cms\n
copie de /cygdrive/c/dev/tmp/argusCMS vers /cygdrive/c/dev/tmp/dest, en mode verbeux, en récursif, sans demander confirmation\n
d'écrasemment de fichier local sauf si la modif locale date d'il y a plus d'une heure. \n
Ne traite que les fichiers du repertoire source modifies dans les 2 dernieres heures.\n
Exclut les fichiers dont le pattern matche l'un des patterns du fichier x.txt (qui écrasent ceux par défaut).\n
Logue dans log.txt et aussi dans la console. \n
2 exemples sur les dossiers reels :\n
1: copie des fichiers du projet CVS vers le projet cms :\n
 ./copy-5.0.sh -x x.txt -v -f log_2.txt -t 1 -s /cygdrive/c/dev/workspaces/ever/argusCMS -d /cygdrive/c/dev/projets/cms \n
2: en sens inverse : a faire afin de pouvoir remonter les modifs sous CVS :\n
./copy-5.0.sh -x x.txt -v -f log_4.txt -s /cygdrive/c/dev/projets/cms/apps/argusCMS -d /cygdrive/c/dev/workspaces/ever/argusCMS/apps/argusCMS \n
Description des paramètres :\n
    -s  definit le chemin du repertoire source (requis)\n
    -d  definit le chemin du repertoire de destination (requis)\n
    -f  fichier pour enregistrer les logs (optionnel)\n
    -t  diffTime en secondes (source) : les fichiers sources modifies apres now-diffTime seront traites (optionnel)\n
    -T  diffTime en secondes (dest) : les fichiers dest modifies avant now-diffTime seront ecrases sans avertissement (optionnel)\n
    -x  definit les patterns d'exclusion dans un fichier AU FORMAT UNIX POUR LES FIN DE LIGNES (un par ligne) : ecrase celui par defaut (optionnel)\n
    -i  indique un traitement iteratif (optionnel)\n
    -v  mode verbeux (optionnel)\n
    -c  pour loguer dans la console (optionnel)\n
    -C  pour proposer de comparer les fichiers en cas de différence (afficher le diff) avant de choisir d'écraser ou non\n
    -F  force / no prompt : ne pas demander avant d'ecraser un fichier local (comme pour ceux traites par la regle du diffTime dest (option -T)) (optionnel)\n
    -q  quick : ne fait pas de tests sur les dates ni de diff sur les dossiers, diff uniquement sur les fichiers. Ecrase les options t, T. ATTENTION TRAITEMENT INCOMPLET A IMPLEMENTER : ETUDIER LES TRAITEMENTS COUTEUX ET RAJOUTER LA CONDITION IF $quick POUR NE PAS LES EXECUTER\n
    -b  backup : effectue une sauvegarde (.bak) d'un fichier de destination écrasé\n
    -h  affiche l'aide (optionnel)"

#######################################################################################################
# INITIALISATION DES VARIABLES
#######################################################################################################

# date de début
debut=$(date +%s)

# sauvegarde de IFS et redefinition
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

#source_folder="/media/data/argus/dev/sh/test/argusCMS"
#dest_folder="/media/data/argus/dev/sh/test/cms"
#source_folder="/cygdrive/c/dev/workspaces/ever/argusCMS"
#dest_folder="/cygdrive/c/dev/projets/cms"
logToFile=false;
logToConsole=false;
useTime=false;
useTimeDest=false;
recursive=true;
prompt=true;
verbose=false;
backup=false;
quick=false;
compare=false;
logFile="/media/data/argus/dev/sh/log8.txt"
excludeStr=""
excludeStrDiff=""
excludePatternList=("*CVS*" "*.project*" "*.classpath*")

# diffTime en secondes
# on ne vas traiter que les fichiers sources modifiés après now-diffTime
# exemple : on considère que le dernier update a eu lieu il y a moins de 24h
# et le précédent il y a 3 jours. On souhaite donc traiter uniquement les fichiers du dossier source
# qui ont été modifiés il y a moins de 24 heures
# on fixe donc diffTime=24x3600 pour traiter les fichiers modifiés après now-diffTime
diffTime=$((3600*24))

# diffTime pour la destination : permet d'ecraser les fichiers locaux differents sans confirmation s'ils sont anciens
diffTimeDest=$((3600*24))

#######################################################################################################
# LECTURE DES PARAMETRES
#######################################################################################################

# si aucun parametre n'est renseigne on affiche l'aide
if [ $# -eq 0 ]
then
   echo -e "$usage"
   IFS=$SAVEIFS
   exit 1
fi

# lecture des parametres passes en entree
while getopts s:d:f:t:T:x:ivcCFqbh opts; do
   case ${opts} in
      s) 
         source_folder=${OPTARG} ;;
      d) 
         dest_folder=${OPTARG} ;;
      f)
         logToFile=true;
         logFile=${OPTARG} ;;
      t)
         useTime=true;
         time=${OPTARG};
         diffTime=$((3600*time)) ;;
      T)
         useTimeDest=true;
         timeDest=${OPTARG};
         diffTimeDest=$((3600*timeDest)) ;;
      x)
         excludeFile=${OPTARG} ;;
      i)
         recursive=false ;;
      v) 
         verbose=true ;;
      c)
         logToConsole=true ;;
      C)
         compare=true ;;
      F)
         prompt=false ;;
      q)
         quick=true ;;
      b)
         backup=true ;;
      h) 
         echo -e $usage
         IFS=$SAVEIFS
         exit 0;;
      *) 
         echo -e $usage
         IFS=$SAVEIFS
         exit 0;;
   esac
done

#######################################################################################################
# CONTROLE DES PARAMETRES REQUIS
#######################################################################################################

if [ -z "$source_folder" ]
then
   echo "le répertoire source est requis"
   IFS=$SAVEIFS
   exit 1
else
   if [ ! -d "$source_folder" ]
   then
      echo "le repertoire source $source_folder n'existe pas"
      IFS=$SAVEIFS
      exit 1
   fi
fi
if [ -z "$dest_folder" ]
then
   echo "le répertoire dest est requis"
   IFS=$SAVEIFS
   exit 1
else
   if [ ! -d "$dest_folder" ]
   then
      echo "le repertoire dest $dest_folder n'existe pas"
      IFS=$SAVEIFS
      exit 1
   fi
fi

#######################################################################################################
# DEFINITION DES FONCTIONS
#######################################################################################################

# cette fonction permet d'ecrire les logs dans un fichier ou dans la console, ou les deux, en incluant la date
function log() {
   if ($logToFile && $logToConsole)
   then
      echo [$(date +%Y-%m-%d\ %H:%M:%S:%N | cut -c -23)] "$1" | tee -a "$logFile"
   else
      if ($logToFile)
      then
         echo [$(date +%Y-%m-%d\ %H:%M:%S:%N | cut -c -23)] "$1" >> "$logFile"
      else
         echo [$(date +%Y-%m-%d\ %H:%M:%S:%N | cut -c -23)] "$1"
      fi
   fi
}

# Cette fonction calcule et affiche le temps ecoule entre les 2 dates passees en parametres
function dureetotale() {
   dt=$(($2 - $1))
   ds=$((dt % 60))
   dm=$(((dt / 60) % 60))
   dh=$((dt / 3600))
   echo $(printf "duree totale : %02d:%02d:%02d\n" $dh $dm $ds)
}

# cette fonction détermine le timestamp (en secondes) de dernière modification du fichier en paramètre
# s'il s'agit d'un répertoire, alors la fonction cherchera le dernier fichier modifié
# le résultat est placé dans la variable result (false en cas de problème)
function getLastModifiedTime() {
   $verbose && log "getLastModifiedTime - param : $1"
   if [[ -d "$1" ]]
   then
      $verbose && log "$1 est un repertoire"
      result=$(find "$1" -exec date -r {} +%s \; | sort -n -r | head -1)
   else
      if [[ -f "$1" ]]
      then
         $verbose && log "$1 est un fichier"
         result=$(date -r "$1" +%s)
      else
         $verbose && log "erreur : fichier $1 indetermine"
         result=false
      fi
   fi
   $verbose && log "getLastModifiedTime - result : $result"
}

# cette fonction compare 2 fichiers ou répertoires (récursivement) avec un diff
# le résultat true ou false est placé dans la variable result
function compareFiles() {
   $verbose && log "compareFiles - params : $1 - $2"
   commandeDiff="diff $excludeStrDiff -rq \"$1\" \"$2\" > /dev/null 2>&1"
   $verbose && log "commande diff : $commandeDiff"
   if $(eval $commandeDiff)
   then
      $verbose && log "fichiers identiques"
      result=true
   else
      $verbose && log "fichiers différents"
      result=false
   fi
   $verbose && log "compareFiles - result : $result"
}

# cette fonction affiche un avertissement et demande confirmation O/N
# à l'utilisateur. La réponse true ou false est stockée dans la variable result
function alert() {
   while true; do
      read -p "$1 (O/N)" yn
      case $yn in
         [Oo]* ) result=true; break;;
         [Nn]* ) result=false; return;;
         * ) echo "entrez O ou N";;
      esac
   done
}

# cette fonction contrôle les droits d'accès au fichier / dossier passé en paramètres
# et s'ils ne sont pas à 777 la fonction les positionne
function checkAndSetFullPermissions() {
   $verbose && log "checkAndSetFullPermissions - param : $1"
   permissions=$(stat -c "%a" "$1")
   if [[ "$permissions" == "777" ]]
   then
      log "checkAndSetFullPermissions - droits 777 OK sur $1"
   else
      log "checkAndSetFullPermissions - droits pas bon sur $1, on les change"
      chmod 777 -R "$1"
   fi
   $verbose && log "checkAndSetFullPermissions - fin"
}

# cette fonction copie le fichier source (1er param) vers le fichier dest (2e param)
# simplement avec la commande cp
function copy() {
   $verbose && log "copy param : $1 - $2"
   #log "copy $1 vers $2"
   #TODO ici ajouter la commande cp ...
   cp "$1" "$2"
}

function processElement() {
   $verbose && log "processElement arg1 : $1 - arg2 : $2"
   #for file in $(find "$1" -maxdepth 1 -not -path "*CVS*" -not -path "*.project*" -not -path "*.classpath*")

   commandeFind="find \"$1\" -maxdepth 1 $excludeStr"
   $verbose && log "commande find : $commandeFind"

   for file in $(eval $commandeFind)
   do
      $verbose && log "fichier source en cours : $file"
      if [ "$file" == "$1" ]
      then
         $verbose && log "fichier racine, on passe"
         continue
      else
         # si useTime et si le fichier est trop ancien
         if ($useTime) && !($quick)
         then
		    # recherche de la date de la dernière modif
            getLastModifiedTime "$file"
            lastModified=$result
			if (($lastModified <= $lastTime))
			then
               # on ne traite pas
               log "fichier $file trop ancien, on ne traite pas"
               continue
            fi
         fi
         # sinon (pas de useTime ou fichier récent)
         
         # on traite
         $verbose && log "fichier $file a traiter"
         # on extrait le suffixe du fichier : partie du file path après le dossier racine source
         # c'est ce suffixe qui sera concaténé au répertoire racine destination pour créer le fichier destination
         suffix=$(echo "$file" | awk -F "$source_folder" '{print $NF}')
         $verbose && log "suffix : $suffix"

         # construction du file path du fichier / dossier destination
         destFile="$dest_folder$suffix"
         $verbose && log "destFile : $destFile"

         if [[ -d "$file" ]]
         then
            $verbose && log "$file est un repertoire"
            if [ ! -d "$destFile" ]
            then
               $verbose && log "$destFile n'existe pas on le cree"
               $verbose && log "creation repertoire $destFile"
               mkdir "$destFile"
            else
               $verbose && log "$destFile existe"
			   if !($quick)
               then
                  compareFiles "$file" "$destFile"
                  if ($result)
                  then
                     $verbose && log "$file et $destFile sont identiques, on ne traite pas"
                     continue
                  else
                     $verbose && log "$file et $destFile sont différents, on traite"
                  fi
               fi
            fi
            $verbose && log "appel process $file - $destFile"
            processElement "$file" "$destFile"
         else
            if [[ -f "$file" ]]
            then
               $verbose && log "$file est un fichier"
               if [ ! -f "$destFile" ]
               then
                  $verbose && log "$destFile n'existe pas"
                  $verbose && log "nouveau fichier a copier inexistant en destination : $destFile"
               else
                  $verbose && log "$destFile existe"
                  compareFiles "$file" "$destFile"
                  if ($result)
                  then
                     $verbose && log "$file et $destFile sont identiques, on ne traite pas"
                     continue
                  else
                     $verbose && log "$file et $destFile sont différents, on traite"
                  fi
                  
                  # en mode non rapide on appelle getLastModifiedTime
                  if !($quick)
                  then
                     # récupération de la date de dernière modif du fichier dest
                     getLastModifiedTime "$destFile"
                     lastModifiedDest=$result                     
                  fi
                  
                  # si demande de confirmation d'écrasement ou (useTimeDest et fichier dest récent)
                  # si quick on ne  s'occupe pas du lastModified
                  if ($prompt) || (!($quick) && ($useTimeDest) && (($lastModifiedDest > $lastTimeDest)))
                  then
                     if ($compare)
                     then
                        alert "Les fichiers source : $file et cible : $destFile sont différents. Voulez-vous afficher le diff ?"
                        if ($result)
                        then
                           diff "$file" "$destFile"
                        fi
                     fi
                     # le fichier va être écrasé, avertissement
                     alert "Le fichier $destFile existe, et va être écrasé par $file car ces fichiers sont différents. Voulez-vous poursuivre ? "
                     if !($result)
                     then
                        # annulation
                        log "fichier local $destFile conservé"
                        continue
                     fi
                  else
                     log "ecrasement sans confirmation du fichier $destFile"
                  fi
                  if ($backup)
                  then
                     log "sauvegarde du fichier $destFile"
                     backupFile="$destFile.bak"
                     # récupération du dernier fichier de sauvegarde, s'il existe
                     lastBackup=$(ls $(dirname "$destFile") | grep $(basename "$destFile").bak | sort -r | head -1)
                     if [ -n "$lastBackup" ]
                     then
                        $verbose && log "derniere sauvegarde de $destFile : $lastBackup"
                        # extraction de ce qui suit .bak
                        backupSuffix=$(echo -n "$lastBackup" | awk -F "bak" '{print $NF}')
                        if [ -n "$backupSuffix" ]
                        then
                           $verbose && log "backupSuffix : $backupSuffix"
                           re='^[0-9]+$'
                           if [[ $backupSuffix =~ $re ]]
                           then
                              $verbose && log "$backupSuffix est un nombre"
                              newBackupSuffix=$((backupSuffix+1))
                              backupFile="$destFile.bak$newBackupSuffix"
                           fi
                        else
                           $verbose && log "pas de suffixe : on l'initialise à 1"
                           backupFile="$destFile.bak1"
                        fi
                     fi
                     $verbose && log "fichier de sauvegarde : $backupFile"
					 cp "$destFile" "$backupFile"
                  fi
               fi
               copy "$file" "$destFile"
            else
               log "erreur : fichier $file indetermine"
            fi
         fi
      fi
   done
}

#   - SI lastModified du source > lastTime (ex : il y a une heure) OU true si l'option lastTime n'est pas choisie (tout traiter) ALORS
#      - SI diff src dest différent (dest inexistant ou différent) ALORS
#         - SI lastModified du dest > lastTime2 (à définir : permet de ne pas écraser des modifs locales récentes) ALORS
#            TRAITER
#         - SINON (modifs locales) 
#            demander confirmation avec avertissement avant de traiter
#      - SINON (diff identique)
#         PASSER
#   - SINON (fichier src plus ancien que le dernier update)
#      PASSER AU SUIVANT



# traitement récursif : plus rapide sauf pour les copies en masse (très grand nombre de modifs un peu partout)
# convient pour 95% des usages
function recursiveProcessing() {
   log "recursiveProcessing - on se place dans le repertoire source : $1"
   cd "$1"
   processElement "$1" "$2"
   log "recursiveProcessing - fin"
}


# traitement itératif
# FIXME : NON TESTE, UTILISER LE TRAITEMENT RECURSIF POUR L'INSTANT
function iterativeProcessing() {
   cd "$source_folder"
   for file in $(find . -not -path "*CVS*" -not -path "*.project*")
   do
      #$fullVerbose && log "on se place dans $newsource"
      log "fichier en cours : $file"

      # recherche de la date de la dernière modif
      getLastModifiedTime "$file"
      lastModified=$result
      # si useTime et si le fichier est trop ancien
      if ($useTime) && (($lastModified <= $lastTime))
      then
         # on ne traite pas
         log "fichier $file trop ancien, on ne traite pas"
         continue
      # sinon (pas de useTime ou fichier récent)
      else
         # on traite
         log "fichier $file a traiter"
         # construction du file path du fichier / dossier destination
         destFile="$2/$file"
         log "destFile : $destFile"
         compareFiles "$file" "$destFile"
            
         if ($result)
         then
            log "$file et $destFile sont identiques, on ne traite pas"
            continue
         else
            log "$file et $destFile sont différents, on traite"

            if [[ -d "$file" ]]
            then
               log "$file est un repertoire"
               log "repertoire : $destFile"
               if [ ! -d "$destFile" ]
               then
                  log "$destFile n'existe pas on le cree"
                  mkdir "$destFile"
               else
                  log "$destFile existe"
               fi
            else
               if [[ -f "$file" ]]
               then
                  log "$file est un fichier"
                  if [ ! -f $destFile ]
                  then
                     log "$destFile n'existe pas"
                     log "nouveau fichier a copier = $destFile"
                  else
                     log  $destFile" existe"
                     # le fichier va être écrasé, avertissement
                     alert "Le fichier $destFile existe, et va être écrasé par $file car ces fichiers sont différents. Voulez-vous poursuivre ? "
                     if !($result)
                     then
                        # annulation
                        log "fichier local $destFile conservé"
                        continue
                     fi
                  fi
                  copy "$1/$file" "$destFile"
               else
                  log "$file est indetermine"
               fi
            fi
         fi
      fi
   done
}

#######################################################################################################
# TRAITEMENT PRINCIPAL
#######################################################################################################

log "source folder : $source_folder"
log "dest folder : $dest_folder"

# comparaison texte [ "$s1" == "$s2" ] pour s2 inclus dans s1 if [[ $s1 == *"$s2"* ]].

# reinitialisation du fichier de log
if ($logToFile)
then
   if [ -f $logFile ]
   then
      rm $logFile
   fi
   touch "$logFile"
   #exec &> "$logFile"
   # on recupere le chemin complet du fichier
   logFile=$(readlink -e "$logFile")
fi

now=$(date +%s)

echo "now : $now"
lastTime=$((now-diffTime))
echo "lastTime : $lastTime"
lastTimeDest=$((now-diffTimeDest))
echo "lastTimeDest : $lastTimeDest"

#TODO test si les 2 répertoires existent bien
log "controle des droits"

$verbose && log "controle des droits du dossier source $source_folder"
checkAndSetFullPermissions "$source_folder"
$verbose && log "controle des droits du dossier cible $dest_folder"
checkAndSetFullPermissions "$dest_folder"

# si un fichier est spécifié pour les patterns d'exclusions alors on contrôle ses droits d'accès,
# on les modifie éventuellement et on contruit la liste des patterns à partir du contenu de ce fichier
if [ -n "$excludeFile" ]
then
   $verbose && log "controle des droits du fichier d'exclusion $excludeFile"
   checkAndSetFullPermissions "$excludeFile"
   $verbose && log "extraction des patterns d'exclusion du fichier $excludeFile"
   excludePatternList=(`cat $excludeFile`)
fi

# construction de la chaine des patterns d'exclusion pour le find
log "${#excludePatternList[@]} pattern trouves : "
for ((j=1; j<=${#excludePatternList[@]}; j++)) 
do 
   $verbose && log "pattern : ${excludePatternList[$j-1]}"
   excludeStr=$excludeStr" -not -path \""${excludePatternList[$j-1]}"\""
done
$verbose && log "excludeStr = $excludeStr"

# construction de la chaine des patterns d'exclusion pour le diff
log "${#excludePatternList[@]} pattern trouves : "
for ((j=1; j<=${#excludePatternList[@]}; j++)) 
do 
   $verbose && log "pattern : ${excludePatternList[$j-1]}"
   excludeStrDiff=$excludeStrDiff" -x \""${excludePatternList[$j-1]}"\""
done
$verbose && log "excludeStrDiff = $excludeStrDiff"

#TODO : fichiers supprimés ?

log "appel du traitement récursif source : $source_folder - dest : $dest_folder"
recursiveProcessing "$source_folder" "$dest_folder"

log "modifications des droits du répertoire cible"
chmod 777 -R "$dest_folder"

echo "fin"

fin=$(date +%s)
dureetotale $debut $fin
IFS=$SAVEIFS

#######################################################################################################
# FIN DU TRAITEMENT
#######################################################################################################





