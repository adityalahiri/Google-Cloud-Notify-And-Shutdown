# Google-Cloud-Notify-And-Shutdown
There are two bash scripts.

1. slackAndMailNotify.sh

This bash script will help reduce your Google Cloud bills. 
The script keeps polling the CPU Load averaged over a period of 15 minutes.
It then sends out slack alerts and alerts via the mail to notify you of the idle state if found.
After a given number of alerts, if still no action is taken and the system is idle, it shuts down the instance.

You need the following-
1. A Google Cloud instance (duh)
2. bc unix command for basic math operations. Install using sudo apt-get install bc
3. SendGrid API KEY for sending email notification.
4. Slack App token and a slack channel to post alerts to.
5. Type crontab -e and write this in the end - @reboot bash /home/arrayslayer/saving.sh
this is the path of this script and you are putting this as a cron job that runs on every reboot.


Command line arguments : 
1. Slack Count -> A slack alert is sent these many number of times. Default value is 10.

2. Mail Count -> An E-mail alert is sent these many number of times after the slack count is exceeded. Default value is 5.

If your global count has exceeded the Mail Count value, your instance will be shut down.

3. Threshold -> This is the user specified value of minimum CPU Load that instance must have
average over 15 minutes to not to be considered idle. If the CPU Load is lesser than this,
Global count increases. Default value is 0.4.

4. Poll Time -> This is the time in seconds after which the average load is found again
and is then compared with the threshold. Default value is 60 seconds.



2. slackGcpShutDown.sh

This bash script takes commands from slack and shuts down Google Cloud instances. It reduces your bills.
You need the following libraties pre-installed
1. jq - for json parsing. Install using sudo apt-get install jq
2. curl. ( Usually pre-installed )
3. Type crontab -e and write this in the end - @reboot bash /home/arrayslayer/slackGcpShutDown.sh
this is the path of this script and you are putting this as a cron job that runs on every reboot.

Usage- On your slack, just post, 
sd instance-name
If the instance name matches the host instance, the instance would be shut down and a notification will be sent on
slack too.
