########### data block to fetch projects under specific folder id ###########
/*data "google_projects" "folder-projects" {
  filter = "parent.id:${var.folder_id} lifecycleState:ACTIVE"
}
data "google_project" "project" {
    count = length(data.google_projects.folder-projects.projects)
    project_id = data.google_projects.folder-projects.projects[count.index].project_id
}
}*/
  
############ os config tenable policy - ubuntu ##############

resource "google_os_config_os_policy_assignment" "oc-tenable-test" {


 # count = length(data.google_project.project[*].project_id)
 # project = data.google_project.project[count.index].project_id
   project = "us-con-gcp-npr-dev100y-081021"
  
  location = "us-east1-b"
  name = "oc-tenable-test"
  description = "os policy assignment"

  instance_filter {
    all = false
    inventories {
      os_short_name = "ubuntu"
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
        id = "ensure-nessus-active"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(systemctl is-active nessusagent.service) == 'active' ]]; then echo 'Nessus Agent is Installed State is active - Link Status Check Required'; exit 100; else exit 101; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "echo 'Nessus Agent service not active'; exit 100"
            }         
          }
       }

      resources {
        id = "nessus-inactive"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(systemctl is-active nessusagent.service) == 'inactive' ]]; then echo 'Nessus Agent is Installed State is inactive - start the nessus service'; exit 101; else exit 100; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "echo 'Nessus Agent service is inactive'; sudo service nessusagent start; exit 100"
            }         
          }
       }


      resources {
        id = "link-nessus"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(service nessusagent status | grep 'active (running') ]]; then echo 'Nessus Agent is Installed State is running - Link Status Check Required'; exit 101; else exit 100; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "if [[ $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'error') || $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'warn') || $(/opt/nessus_agent/sbin/nessuscli agent status | grep 'Not linked') ]]; then echo 'Nessus Agent is not linked properly. Linking the agent'; nessuskey=a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16; NessusGroup=gcp-oc-$(curl 'http://metadata.google.internal/computeMetadata/v1/project/attributes/cshortname' -H 'Metadata-Flavor: Google'); /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups=''$NessusGroup''; exit 101; else echo 'Nessus agent is already linked to host'; exit 100; fi"
            }         
          }
       }
     
      resources {
        id = "install-nessus-agent"
        exec {
          validate {
            interpreter = "SHELL"
            script      = "if [[ $(systemctl is-active nessusagent.service) == 'unknown' ]]; then exit 101; else exit 100; fi"
          }

          enforce {
            interpreter = "SHELL"
            script      = "nessuskey=a521b5ff16a5d5272109d675bba8d84bd07e7126d686c1966ec8e1fce13abd16; NessusGroup=gcp-oc-$(curl 'http://metadata.google.internal/computeMetadata/v1/project/attributes/cshortname' -H 'Metadata-Flavor: Google'); dpkg -r NessusAgent; echo 'download package and installing'; sudo apt-get install jq -y; curl -s -L 'https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/17306/download?i_agree_to_tenable_license_agreement=true' --output /home/packages/nessus.deb; sleep 10;  sudo dpkg -i /home/packages/nessus.deb; /opt/nessus_agent/sbin/nessuscli agent link --host=cloud.tenable.com --port=443 --key=$nessuskey --groups=''$NessusGroup''; sudo /bin/systemctl start nessusagent.service; sudo /bin/systemctl status nessusagent.service; exit 100"
                        
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
