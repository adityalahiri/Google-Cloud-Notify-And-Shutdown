# This bash script will help reduce your Google Cloud bills. 
# The script keeps polling the CPU Load averaged over a period of 15 minutes.
# It then sends out slack alerts and alerts via the mail to notify you of the idle state if found.
# After a given number of alerts, if still no action is taken and the system is idle, it shuts down the instance.

# You need the following-
# 1. A Google Cloud instance (duh)
# 2. bc unix command for basic math operations. Install using sudo apt-get install bc
# 3. SendGrid API KEY for sending email notification.
# 4. Slack App token and a slack channel to post alerts to.
# 5. Type crontab -e and write this in the end - @reboot bash /home/arrayslayer/saving.sh
# this is the path of this script and you are putting this as a cron job that runs on every reboot.

# Let global count be a variable that increases by 1 everytime your instance's load is less than the threshold.
# Global count is initially 0.

# Command line arguments : 
# 1. Slack Count -> If the global count is less than this value, a slack alert is sent. In other words,
# for these many number of times, whenever your instance load is less than the threshold, the script
# reacts by sending a slack alert. Defaut value is 10.

# 2. Mail Count -> Once the Global Count exceeds the Slack Count value,
# an E-mail alert is sent these many number of times. Deafult value is 5.

# If your global count has exceeded the Mail Count value, your instance will be shut down.

# 3. Threshold -> This is the user specified value of minimum CPU Load that instance must have
# average over 15 minutes to not to be considered idle. If the CPU Load is lesser than this,
# Global count increases. Default value is 0.4.

# 4. Poll Time -> This is the time in seconds after which the average load is found again
# and is then compared with the threshold. Default value is 60 seconds.

# Declaring default values of variables

threshold=0.4 #If the average CPU load over the last 15 minutes is lesser than threhold, increase count
count=0 # global count variable that keeps track of how many times the threshold has been crossed
slackCount=10 # Until the global count is lesser than slack count, alerts are sent to the slack channel.
mailCount=5 # If the global count > slack count but less than this mail count, alerts are sent to mail.
pollTime=60 # Time in seconds after which the average load is found again and process is repeated.

# if the command line arguments are provided assign them to the variables and ovveride default values.

if [ "$1" != "" ]; then
  slackCount=$1
fi

if [ "$2" != "" ]; then
  mailCount=$2
fi

if [ "$3" != "" ]; then
  threshold=$3
fi

if [ "$4" != "" ]; then
  pollTime=$4
fi

# Getting the instance name of the machine.
#INSTANCE_NAME=$(curl http://169.254.169.254/0.1/meta-data/hostname -s | cut -d "." -f1)
INSTANCE_NAME="aditya-201"
HAS_BEGUN="-has-begun-and-is-idle" 
IS_IDLE="-is-idle"
# begin checking

while true
do

  # get the average CPU load over the last 15 minutes.
  load=$(uptime | sed -e 's/.*load average: //g' | awk '{ print $3 }')
  
  # check whether the average load computed is lesser than the threshold or not.
  res=$(echo $load'<'$threshold | bc -l)

  if (( $res )) # if the load is lesser than the threshold, enter.
  then
    echo "Idling.."
    ((count+=1)) # increasing the global count by 1.
    if((count==1))
      then
        curl -X POST -H 'Authorization: Bearer your-slack-app-token' \
        -H 'Content-type: application/json' \
        --data '{"channel":"general","text":"'$INSTANCE_NAME$HAS_BEGUN'"}' \
        https://hooks.slack.com/services/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 

    fi
    if((count<=slackCount)) # if the condition is true send Slack Alert/
      then
        echo "Sending slack"
        slackhost="gcpsave" # the slack host on which the alert is sent.

        # the key "channel" specifies on which slack channel the message is sent.
        # webhook must be configured on the slack host.

        curl -X POST -H 'Authorization: Bearer your-slack-app-token' \
        -H 'Content-type: application/json' \
        --data '{"channel":"general","text":"'$INSTANCE_NAME$IS_IDLE'"}' \
        https://hooks.slack.com/services/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 

    fi

    if((count<=(slackCount+mailCount) && count>slackCount)) # alert to mail if this condition holds.
    then 
    echo "sending mail"
        
        # uses sendgrid api to send mails.

        SENDGRID_API_KEY="your-own-api-key-from-sendGrid"
        EMAIL_TO="emailid@host.com"
        FROM_EMAIL="adityalahiri13@gmail.com"
        FROM_NAME="Aditya Lahiri"


        bodyHTML="<p>Your Google Cloud instance is dull.</p>"

        maildata='{"personalizations": [{"to": [{"email": "'${EMAIL_TO}'"}]}],"from": {"email": "'${FROM_EMAIL}'", 
        "name": "'${FROM_NAME}'"},"subject": "'${INSTANCE_NAME}'","content": [{"type": "text/html", "value": "'${bodyHTML}'"}]}'

        curl --request POST \
        --url https://api.sendgrid.com/v3/mail/send \
        --header 'Authorization: Bearer '$SENDGRID_API_KEY \
        --header 'Content-Type: application/json' \
         --data "'$maildata'"
    fi

    if ((count>(slackCount+mailCount))) # when the global count has increased even the limit for alert via mails, then shut down the system
      then
      echo Shutting down

      # wait a little bit more before actually pulling the plug
      sleep 3000
      sudo poweroff # Shuts down the instance.
    fi
  fi

  echo "Idle minutes count = $count" # print current status of the global count.
  sleep $pollTime # sleep before starting the next iteration.

done