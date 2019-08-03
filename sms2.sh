#!/bin/sh
echo "param1 = $1"
echo "param2 = $2"
adb shell am start -a android.intent.action.SENDTO -d sms:"$2" --es sms_body "$1" --ez exit_on_sent true;
adb shell input keyevent 22;
adb shell input keyevent 66;

