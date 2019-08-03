# scripts
test scripts. some of them can be useful...

bash/
   capture.sh* : test script capture packets
   
   checkAlive.sh* : checks if a host is alive
   
   checkHosts.sh : checks if new hosts are up or current hosts are down
   
   checklogin : daemon for checkLogin.sh
   
   checklogin.sh* : checks auth.log and shuts down ssh service if too many intrusion attempts are identified 
   
   compare.sh* : compares 2 lists : checks if members of 1st list are present in 2nd list
   
   copy.sh : copy files from source to destination. Useful when the files are located on an external USB drive : the scripts detects transfer errors and then reconnects the drive, remounts the partition and resumes the copy process 
   
   eden.sh : connects and authentify a user to the edenred site and display the account amount and the last transactions (2 mandatory parameters : user and password)
   
   kickallx.sh* : gathers all players IP in the current session and call kick.sh for all of them to boot them, splitting the host list in as many sublists as the number of accounts
   
   kickeg.sh* : kicks eg : send deauthentification packets to my access point in order to disconnect my little brother's laptop !
   
   kick.sh* : call a famous booter, log in and fill the test form to launch one or several stress tests (many options available)
   
   max.sh* : returns the max
   
   min.sh* : returns the min
   
   mount.sh* : mount test
   
   moyenne.sh* : average
   
   net.sh* : wifi connection
   
   resetUSBRaid.sh* : reset usb
   
   resetUSB.sh* : reset usb
   
   restartUSB.sh* : reset usb
   
   sms2.sh : send sms
   
   stopUSB.sh : stop usb device
   
   temp.sh : logs GPU core temp every minute
   
   xs.sh : (replace user and password with real account) : authentication on xspeeds.eu web site : bypass anti-bot system, write cookies (clearance and session) and pages in a new timestamped folder
   
   xs-dl-pages.sh : (1 parameter : folder created by xs.sh : first launch xs.sh) : download x pages of torrent files from xspeeds.eu web site
   
   dl_github.sh : given a domain, user name and password, the script opens a session on github and downloads all the repositories in the domain
   
   curls.sh.asc : This is the encrypted cygwin version. To call the script, use script.sh described below. If you use it in a standard Unix environment, replace "powershell kill" with "kill" and "cygstart "/cygdrive/c/Users/alex/Desktop/Tor Browser/Browser/firefox.exe"" with an appropriate command to launch Firefox on your system.
   This script uses confidential informations, such as username, password, url of hidden website. Such data is stored in an encrypted file : params.txt.asc. The current script first decrypts the param file and read the "key=value" lines to initialize variables. The decrypted file is then destroyed. This script can be used to boot an IP with appropriate method, duration, strength. The stress test can belaunched inside an infinite loop. It is also possible to check the remaining duration of the current attack, or to stop an attack. This process uses a socks5 proxy (tor) to prevent being tracked and identified. It ensures tor is started, otherwise it tries to lauch tor.
   
   script.sh : This script is used to decrypt curls.sh.asc, run it and delete the decrypted file.
   
   
   





