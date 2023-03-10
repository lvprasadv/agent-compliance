#!/bin/bash

ErrorCount=0
bucketname="ocgdev-lbk-agent"
nessuskey="a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16"
NessusGroup=gcp-oc-$(curl 'http://metadata.google.internal/computeMetadata/v1/project/attributes/cshortname' -H 'Metadata-Flavor: Google')
nessuslog="/opt/NessusInstall.log"
tmlog="/opt/TMInstall.log"

ls -ld /home/packages #Check if packages directory already exists

if [ $? -eq 0 ]; then
  echo "Packages directory already exists "
else
  echo "Creating packages directory for agents."
  sudo mkdir /home/packages
fi

cd /home/packages

NessusActive()
{
    service nessusagent start
    service nessusagent status | grep "active (running)"
    if [ $? -eq 0 ]
	 then
  	    echo "Nessus Agent is Installed, State is running - Link Status Check Required " >>$nessuslog
        NessusLink
  	    exit 1
     else
     fi
}

NessusLink()
{
            /opt/nessus_agent/sbin/nessuscli agent status | grep error
  	    agentLinkStatus=$(echo $?)
            /opt/nessus_agent/sbin/nessuscli agent status | grep warn
            agentLinkStatusWarn=$(echo $?)
            /opt/nessus_agent/sbin/nessuscli agent status | grep "Not linked"
  	    agentLinkno=$(echo $?)            
            if [ $agentLinkStatusWarn -eq "0" ] || [ $agentLinkStatus -eq "0" ] || [ $agentLinkno -eq "0" ]
             then
              echo "Nessus Agent is not linked properly. Linking the agent" >>$nessuslog
	      #/opt/nessus_agent/sbin/nessuscli agent unlink --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'"
              /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'"
              exit 1
             else
              echo "Nessus Agent is Linked properly." >>$nessuslog
              exit 0
            fi 
}

NessusInActive()
{
    service nessusagent start
    sleep 10
    service nessusagent status | grep "active (running)"
    if [ $? -eq 0 ]
	 then
       echo "Nessus Agent is Running, Linking the agent"
       NessusLink
     else
  	   echo "Nessus Agent is not getting started due to errors, so re-installing.">>$nessuslog
	   NessusInstallation
    fi

}
NessusInstallation()
{

OSNAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
OSRHEL='"Red Hat Enterprise Linux Server"'
#OSSUSE='"SLES"'
OSUBUN='"Ubuntu"'
OSDEB='"Debian GNU/Linux"'
OSCENT='"CentOS Linux"'

if [ "$OSNAME" = "$OSRHEL" ] || [ "$OSNAME" = "$OSCENT" ]
then
        echo "OS is RedHat or CentOS" >>$nessuslog
	sudo yum install epel-release -y
	sudo yum update -y
	sudo yum install jq -y
	sudo rpm -e NessusAgent
	AGENTPACKAGEID=$(curl -s -L https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents | jq '[.downloads[] | select(.name | contains("es7.x86_64.rpm")) ] | max_by(.created_at) | .id')
        echo "The Agent Package ID for RHEL/CENTOS is $AGENTPACKAGEID" >>$nessuslog
        wget "https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/$AGENTPACKAGEID/download?i_agree_to_tenable_license_agreement=true" -O /home/packages/nessus.rpm
        #instead of wget we can use curl using below command
	#curl -s -L "https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/$AGENTPACKAGEID/download?i_agree_to_tenable_license_agreement=true" --output /home/packages/nessus.rpm
	sudo rpm -ivh /home/packages/nessus.rpm >>$nessuslog
        echo "**************Nessus agent is installed successfully ***************************" >>$nessuslog

 elif [ "$OSNAME" = "$OSUBUN" ]
then
        echo "OS is UBUNTU" >>$nessuslog
	sudo apt-get update
	sudo apt-get install jq -y
	sudo apt install wget
	dpkg -r NessusAgent
	AGENTPACKAGEID=$(curl -s -L https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents | jq '[.downloads[] | select(.name | contains("ubuntu1110_amd64.deb")) ] | max_by(.created_at) | .id')
        echo "The Agent Package ID for UBUNTU is $AGENTPACKAGEID" >>$nessuslog
        wget "https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/$AGENTPACKAGEID/download?i_agree_to_tenable_license_agreement=true" -O /home/packages/nessus.deb
        sudo dpkg -i /home/packages/nessus.deb >>$nessuslog
        echo "**************Nessus agent is installed successfully ***************************" >>$nessuslog

 elif [ "$OSNAME" = "$OSDEB" ]
then
        echo "OS is DEBIAN" >>$nessuslog
	sudo apt-get update
	sudo apt-get install jq -y
	sudo apt install wget
	dpkg -r NessusAgent
	AGENTPACKAGEID=$(curl -s -L https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents | jq '[.downloads[] | select(.name | contains("debian10_amd64.deb")) ] | max_by(.created_at) | .id')
        echo "The Agent Package ID for UBUNTU is $AGENTPACKAGEID" >>$nessuslog
        wget "https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/$AGENTPACKAGEID/download?i_agree_to_tenable_license_agreement=true" -O /home/packages/nessus.deb
        sudo dpkg -i /home/packages/nessus.deb >>$nessuslog
        echo "**************Nessus agent is installed successfully ***************************" >>$nessuslog

else
        echo "UNSUPPORTED OS. Skipping Nessus Installation.." >$nessuslog
fi
echo -e "Linking the agent to the Portal" >>$nessuslog
        /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'" >>$nessuslog
        sudo /bin/systemctl start nessusagent.service >>$nessuslog
        sudo /bin/systemctl status nessusagent.service >>$nessuslog
}


 ########################### TM ###################################

 TrendmicroInstall()
{

	if [[ "$(curl -s 'http://metadata.google.internal/computeMetadata/v1/instance/attributes/' -H 'Metadata-Flavor: Google' | grep 'TrendLinuxPolicyID')" ]]; then
	        trendLinuxPolicyID=$(curl -s 'http://metadata.google.internal/computeMetadata/v1/instance/attributes/TrendLinuxPolicyID' -H 'Metadata-Flavor: Google')
	 elif [[ "$(curl -s 'http://metadata.google.internal/computeMetadata/v1/project/attributes/' -H 'Metadata-Flavor: Google' | grep 'TrendLinuxPolicyID')" ]]; then
	        trendLinuxPolicyID=$(curl -s 'http://metadata.google.internal/computeMetadata/v1/project/attributes/TrendLinuxPolicyID' -H 'Metadata-Flavor: Google')
	 else
	        trendLinuxPolicyID="null"
    fi

      /usr/bin/google-cloud-sdk/bin/gsutil cp gs://$bucketname/AgentDeploymentScript.sh /home/packages >>$tmlog
      sleep 5s
      sudo bash /home/packages/AgentDeploymentScript.sh $trend_policy_id >>$tmlog
}

TrendmicroStart()
{
    systemctl start ds_agent.service >>$tmlog
    systemctl is-active ds_agent.service | grep -i "active" | | grep -v 'inactive'   # This will fetch only active and remove line containing inactive output 
    if [ $? -eq 0 ]
	   then
       echo "Trendmicro agent is started and running" >>$tmlog
     else
  	   echo "Trendmicro agent is inactive so installing again" >>$tmlog
	     TrendmicroInstall
    fi
    
}

##### Execution starts for nessus
if [ "$(systemctl is-active nessusagent.service)" = "inactive" ]; 

 then
   NessusInActive
  elseif [ "$(systemctl is-active nessusagent.service)" = "active" ]
  then
   NessusActive
  elseif [ "$(systemctl is-active nessusagent.service)" = "unknown" ]
  then
   NessusInstallation
 else
   echo "Nessus Agent is missing" >>$nessuslog
   NessusInstallation
 fi   
 

##### Execution starts for tm
if [ "$(systemctl is-active ds_agent.service)" = "inactive" ]; 
 then
  TrendmicroStart
  elif [ "$(systemctl is-active ds_agent.service)" = "active" ]
   then
   echo "Trendmicro agent is already installed and running" >>$tmlog
  else
   echo "TM Agent is missing.. Install TM agent" >>$tmlog
   TrendmicroInstall
 fi
