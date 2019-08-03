#!/bin/bash

rootFolder=$(date +%Y%m%d-%H%M%S)
rootUrl="https://www.xspeeds.eu/"
host=$(echo $rootUrl | awk -F "://" '{print $2}' | awk -F "/" '{print $1}')
tLength=${#host}
wait="wait.html"
sourceScript="sourceScript.js"
newScript="newScript.js"
clearanceCookie="clearanceCookie.txt"
loginForm="loginForm.html"
firstCookie="firstCookie.txt"
authCookie="authCookie.txt"
login="login.html"
browse="browse.html"
clearanceCookieName="cf_clearance"
sessionUidCookieName="c_secure_uid"
sessionPassCookieName="c_secure_pass"
user="alex78160"
password="***"
maxIterations=5
waitBeforeAttempts=4
iteration=0
clearanceCookieOk=false
authCookieOk=false

echo -n "enter the password for $user : "
read -s password

echo "tLength = $tLength"
echo "working in folder $rootFolder"

mkdir $rootFolder
cd $rootFolder


while ([ $clearanceCookieOk == false ] || [ $authCookieOk == false ]) && ((iteration < maxIterations))
do
    rm -f $wait
    rm -f $firstCookie
    rm -f $newScript
    rm -f $clearanceCookie
    rm -f $loginForm
    rm -f $authCookie
    rm -f $login
    ((iteration++))
    echo "getting wait page..."
    curl "$rootUrl" -H 'Host: www.xspeeds.eu' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -o $wait -s -c $firstCookie
    echo "building js file to evaluate jschl_answer value..."
    grep -A 8 "setTimeout(function(){" $wait | tail -8 > $sourceScript

    i=0
    while read line
    do
        ((i++))
        if [ $i -eq 8 ]
        then
            echo $line | sed "s/t.length;/$tLength/" | sed "s/'; 121'/;/" | sed "s/a.value/var test/" >> $newScript
        elif [ $i -eq 1 ]
        then
            echo $line >> $newScript
        fi
    done < $sourceScript
    echo "console.log(test.toFixed(10));" >> $newScript

    v1=$(grep "jschl_vc" $wait | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}')
    #v2=$(grep "pass" $wait | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}' | sed "s/+/%2B/g" | sed "s/\//%2F/g")
    v2=$(grep "pass" $wait | awk -F "value=\"" '{print $2}' | awk -F "\"" '{print $1}' | sed "s/+/%2b/g" | sed "s/\//%2f/g" | sed "s/\./%2e/g" | sed "s/-/%2d/g")
    v3=$(node $newScript)

    echo "v1=$v1"
    echo "v2=$v2"
    echo "v3=$v3"

    echo "sleeping 3 seconds to simulate JavaScript setTimeout..."
    sleep 3

    echo "getting clearance cookie..."

    curl "https://www.xspeeds.eu/cdn-cgi/l/chk_jschl?jschl_vc=$v1&pass=$v2&jschl_answer=$v3" -H "Host: www.xspeeds.eu" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.5" -H "Referer: https://www.xspeeds.eu/" -H "Connection: keep-alive" -H "Upgrade-Insecure-Requests: 1" -b $firstCookie -c $clearanceCookie -s -L -o $loginForm --http2

    echo "checking clearance cookie..."
    if grep -q $clearanceCookieName $clearanceCookie
    then
        echo "clearance cookie ok"
        clearanceCookieOk=true
    else
        echo "failure while getting clearance cookie (attempt #$iteration)"
        echo "waiting $waitBeforeAttempts seconds before next attempt ..."
        sleep $waitBeforeAttempts
        continue
    fi

    echo "authenticating user=$user ..."

    curl 'https://www.xspeeds.eu/takelogin.php' -H 'Host: www.xspeeds.eu' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Referer: https://www.xspeeds.eu/' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' --data "username=$user&password=$password" -b $clearanceCookie -c $authCookie -s -L -o $login

    echo "checking session cookie..."
    if grep -q $sessionUidCookieName $authCookie && grep -q $sessionPassCookieName $authCookie && ! grep -q "deleted" $authCookie
    then
        echo "session cookie ok"
        authCookieOk=true
        break
    else
        echo "failure while getting session cookie (attempt #$iteration)"
        echo "waiting $waitBeforeAttempts seconds before next attempt ..."
        sleep $waitBeforeAttempts
        continue
    fi
done

if [ $clearanceCookieOk == false ] || [ $authCookieOk == false ]
then
    echo "error while getting one of the required cookies : failure after $iteration attempts"
    exit 1
fi

echo "getting browse page..."

curl 'https://www.xspeeds.eu/browse.php' -H 'Host: www.xspeeds.eu' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: https://www.xspeeds.eu/index.php?logged=true' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -b $authCookie -s -o $browse

