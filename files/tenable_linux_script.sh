groupName=gcp-oc-$(curl 'http://metadata.google.internal/computeMetadata/v1/project/attributes/cshortname' -H 'Metadata-Flavor: Google')
nessuskey=a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16
/opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups="'$NessusGroup'"
/bin/systemctl start nessusagent.service && exit 100
