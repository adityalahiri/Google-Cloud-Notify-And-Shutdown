# This bash script takes commands from slack and shuts down Google Cloud instances. It reduces your bills.
# You need the following libraties pre-installed
# 1. jq - for json parsing. Install using sudo apt-get install jq
# 2. curl. ( Usually pre-installed )
# 3. Type crontab -e and write this in the end - @reboot bash /home/arrayslayer/slackGcpShutDown.sh
# this is the path of this script and you are putting this as a cron job that runs on every reboot.

# Fetching the Google Cloud Instance Name for this machine.
INSTANCE_NAME=$(curl http://169.254.169.254/0.1/meta-data/hostname -s | cut -d "." -f1)
# Variable for shutting down alert message content that will be sent to slac channel.
SHUT_DOWN="-is-shutting-down"

# res2 is a variable which stores the previous value of the instance that was ordered to shut down.
# this is used to avoid issuing of multiple shutdown commands on the same instance.
res2="hello"

# the shutdown hotword is represented as sd. User must say sd instance-name on slack. 
sd="sd"

# keep checking slack!
while true
do

# fetch the last message's text (count=1)
res1=$(curl -v -s -H "Accept:application/json" -H "Accept:text/xml" -H "Accept:application/xml" -H "Accept:*/*" "https://slack.com/api/channels.history?token=your-slack-app-token&count=1&pretty=1" | jq -r '.messages[].text')

# checking if both res1 and res2 are same. If yes, it means that the last slack message has
# already been through this process so just ignore and continue.
if [[ "$res2" == "$res1" ]];then
    
    continue;

else
    
    # set the last slack message to be the current slack message
    res2=$res1
    
    # check if the current message has the substring sd in it
    if [[ $res1 == *"sd"* ]]; then
        # converting the message text to an array of strings, thereby, separating sd and instance-name
        stringarray=($res1)
        # this is the instance we have to shut down.
        toShutDown=${stringarray[1]}

        #if the instance to shut down is the same as the instance of this machine, get inside this block.
        if [[ "$toShutDown" == "$INSTANCE_NAME" ]]; then

            # Put a message on slack that you are shutting down this instance        
            curl -X POST -H 'Authorization: Bearer your-slack-app-token' \
            -H 'Content-type: application/json' \
            --data '{"channel":"general","text":"'$INSTANCE_NAME$SHUT_DOWN'"}' \
            https://hooks.slack.com/services/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
            
            #shut down this instance
            #sudo poweroff
        fi
    fi
fi
done