


### Variables

ErrorCount=0
#bucketname="ocgsh-csv-lbk-admin"ocgdev-lbk-agent
bucketname="ocgdev-lbk-agent"
nessuskey="a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16"
NessusGroup=gcp-oc-$(curl 'http://metadata.google.internal/computeMetadata/v1/project/attributes/cshortname' -H 'Metadata-Flavor: Google')


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
  	    echo "Nessus Agent is Installed, State is running - Link Status Check Required "
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
              echo "Nessus Agent is not linked properly. Linking the agent"
	          #/opt/nessus_agent/sbin/nessuscli agent unlink --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'"
              /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'"
              exit 1
             else
              echo "Nessus Agent is Linked properly."
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
  	   echo "Nessus Agent is not getting started due to errors, so re-installing."
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
        echo "OS is RedHat or CentOS" >>/opt/NessusInstall.log
		sudo rpm -e NessusAgent*
		gsutil cp gs://$bucketname/NessusAgent-8.3.1-es7.x86_64.rpm /home/packages
		sudo rpm -ivh /home/packages/Nessus*.rpm >>/opt/NessusInstall.log
        echo "**************Nessus agent is installed successfully ***************************"

 elif [ "$OSNAME" = "$OSUBUN" ]
then
        echo "OS is UBUNTU" >>/opt/NessusInstall.log
		dpkg -r NessusAgent*
		gsutil cp gs://$bucketname/NessusAgent-8.3.1-ubuntu1110_amd64.deb /home/packages
		sudo dpkg -i /home/packages/Nessus*.rpm >>/opt/NessusInstall.log
        echo "**************Nessus agent is installed successfully ***************************"

 elif [ "$OSNAME" = "$OSDEB" ]
then
        echo "OS is DEBIAN" >>/opt/NessusInstall.log
		dpkg -r NessusAgent*
		gsutil cp gs://$bucketname/NessusAgent-8.3.1-debian6_amd64.deb /home/packages
		sudo dpkg -i /home/packages/Nessus*.rpm >>/opt/NessusInstall.log
        echo "**************Nessus agent is installed successfully ***************************"

else
        echo "UNSUPPORTED OS. Skipping Nessus Installation.." >/opt/NessusInstall.log
fi
echo -e "Linking the agent to the Portal" >>/opt/NessusInstall.log
        /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'" >>/opt/NessusInstall.log
        sudo /bin/systemctl start nessusagent.service >>/opt/NessusInstall.log
        sudo /bin/systemctl status nessusagent.service >>/opt/NessusInstall.log


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
   echo "Nessus Agent is missing"
   NessusInstallation
 fi   
 

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

      /usr/bin/google-cloud-sdk/bin/gsutil cp gs://$bucketname/AgentDeploymentScript.sh /home/packages >>/opt/TMInstall.log
      sleep 5s
      sudo bash /home/packages/AgentDeploymentScript.sh $trend_policy_id >>/opt/TMInstall.log
}

TrendmicroStart()
{
    systemctl start ds_agent.service >>/opt/TMInstall.log
    systemctl is-active ds_agent.service | grep -i "active" | | grep -v 'inactive'   # This will fetch only active and remove line containing inactive output 
    if [ $? -eq 0 ]
	   then
       echo "Trendmicro agent is started and running" >>/opt/TMInstall.log
     else
  	   echo "Trendmicro agent is inactive so installing again" >>/opt/TMInstall.log
	     TrendmicroInstall
    fi
    
}

##### Execution starts for tm
if [ "$(systemctl is-active ds_agent.service)" = "inactive" ]; 
 then
  TrendmicroStart
  elseif [ "$(systemctl is-active ds_agent.service)" = "active" ]
  then
   echo "Trendmicro agent is already installed and running" >>/opt/TMInstall.log
  else
   echo "TM Agent is missing.. Install TM agent" >>/opt/TMInstall.log
   TrendmicroInstall
 fi
