########### data block to fetch projects under specific folder id ###########
/*data "google_projects" "folder-projects" {
  filter = "parent.id:${var.folder_id} lifecycleState:ACTIVE"
}
data "google_project" "project" {
    count = length(data.google_projects.folder-projects.projects)
    project_id = data.google_projects.folder-projects.projects[count.index].project_id
}
}*/
  
############ os config tenable policy - centos/rhel ##############

resource "google_os_config_os_policy_assignment" "oc-tenable" {


 # count = length(data.google_project.project[*].project_id)
 # project = data.google_project.project[count.index].project_id
   project = "us-con-gcp-npr-dev100y-081021"
  
  location = "us-east1-b"
  name = "oc-tenable"

  instance_filter {
    all = false
    inventories {
      os_short_name = "centos"
    }
    inventories {
      os_short_name = "rhel"
    }
  }

  os_policies {
    id                            = "nessus-agent-policy"
    allow_no_resource_group_match = false
    mode                          = "ENFORCEMENT"
    resource_groups {

      resources {
        id = "create-packages-dir"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [ -d /home/packages ]; then exit 100; else exit 101; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "echo 'Creating packages directory for agents.'; sudo mkdir /home/packages; exit 100 "
            }         
          }
       }
      
      resources {
        id = "ensure-nessus-running"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(systemctl is-active nessusagent.service) == 'active' ]]; then echo 'Nessus Agent is Installed State is active - Link Status Check Required'; exit 100; else exit 101; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "echo 'Starting Nessus Agent service.'; sudo systemctl start nessusagent.service; exit 100 "
            }         
          }
       }

      resources {
        id = "validate-nessus-status"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(service nessusagent status | grep 'active (running') ]]; then echo 'Nessus Agent is Installed State is running - Link Status Check Required'; exit 100; else exit 101; fi"
          }

          #enforce {
          #  interpreter = "SHELL"
          #  script      = "if [[ $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'error') || $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'warn') || $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'Not linked')]]; then echo 'Nessus Agent is not linked properly. Linking the agent'; nessuskey='a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16'; NessusGroup='gcp-oc-dev'; /opt/nessus_agent/sbin/nessuscli agent link --port=443 --key=$nessuskey --groups=''$NessusGroup''; "
          #  }         
          }
       }     
     
      resources {
        id = "uninstall-reinstall-nessus-agent"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(systemctl is-active nessusagent.service) == 'inactive' || $(systemctl is-active nessusagent.service) == 'unknown' ]]; then exit 101; else exit 100; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "service nessusagent start; sleep 10; nessuskey='a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16'; NessusGroup=gcp-oc-$(curl 'http://metadata.google.internal/computeMetadata/v1/project/attributes/cshortname' -H 'Metadata-Flavor: Google'); if [[ $(systemctl is-active nessusagent.service) == 'active' ]]; then echo 'Nessus Agent is Installed State is active - Link Status Check Required'; if [[ $(/opt/nessus_agent/sbin/nessuscli agent status | grep -e 'error') || $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'warn') || $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'Not linked')]]; then echo 'Nessus Agent is not linked properly. Linking the agent'; /opt/nessus_agent/sbin/nessuscli agent link --port=443 --key=$nessuskey --groups=''$NessusGroup''; exit 101; else echo 'Nessus agent is linked'; fi; else echo 'Uninstalling and reinstalling Nessus Agent';  /opt/nessus_agent/sbin/nessuscli agent unlink --host=cloud.tenable.com --port=443 --key=$nessuskey --groups=''$NessusGroup''; sudo rpm -e NessusAgent; echo 'download rpm package'; sudo yum install epel-release -y; sudo yum install jq -y; AGENTPACKAGEID=$(curl -s -L https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents | jq '[.downloads[] | select(.name | contains('es7.x86_64.rpm')) ] | max_by(.created_at) | .id'); curl -s -L 'https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/$AGENTPACKAGEID/download?i_agree_to_tenable_license_agreement=true' --output /home/packages/nessus.rpm; sudo rpm -ivh /home/packages/nessus.rpm; /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups=''$NessusGroup''; sudo /bin/systemctl start nessusagent.service; sudo /bin/systemctl status nessusagent.service; exit 100; fi"
                        
            }         
          }
       }
     
     }
    }

  rollout {
    disruption_budget {
      fixed = 10
    }
    min_wait_duration = "10s"
   }
}
