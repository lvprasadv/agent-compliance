########### data block to fetch projects under specific folder id ###########
/*data "google_projects" "folder-projects" {
  filter = "parent.id:${var.folder_id} lifecycleState:ACTIVE"
}
data "google_project" "project" {
    count = length(data.google_projects.folder-projects.projects)
    project_id = data.google_projects.folder-projects.projects[count.index].project_id
}

data "google_storage_bucket_object" "script" {
  name   = "script.sh"
  bucket = "ocgdev-lbk-agent"
}*/
  
############ os config policy - tenable ##############

resource "google_os_config_os_policy_assignment" "oc-linux" {


 # count = length(data.google_project.project[*].project_id)
 # project = data.google_project.project[count.index].project_id
   project = "us-con-gcp-svc-dev100x-081021"
  
  location = "us-east1-b"
  name = "oc-all-agents-validation"

  instance_filter {
    all = false
    inventories {
      os_short_name = "centos"
    }
    inventories {
      os_short_name = "ubuntu"
    }
    inventories {
      os_short_name = "rhel"
    }
    inventories {
      os_short_name = "debian"
    } 
  }

  os_policies {
    id                            = "agents-status"
    allow_no_resource_group_match = false
    mode                          = "ENFORCEMENT"
    resource_groups {

      resources {

        id = "ensure-agents-installed"
        pkg {
          desired_state = "INSTALLED"
          rpm {
            source {
              gcs {
                bucket     = var.bucket_name
                object     = var.nessus_centos
                generation = var.gen_number_nessus_centos
              }
            }
          }
        }
      }

      resources {
        id = "ensure-agents-online"

        exec {
          validate {

            interpreter = "SHELL"
            script      = "if systemctl is-active --quiet nessusagent.service; then exit 100; else exit 101; fi"

          }

          enforce {
            interpreter = "SHELL"
           # script      = "gsutil cp gs://{{bucket_name}}/{{all_agent_check}}.sh /root; sleep 20s; dos2unix /root/{{all_agent_check}}.sh; bash /root/{{all_agent_check}}.sh"
            file {
             local_path = "./files/all_agent_script.sh"
             }
            }         
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

/*resource "google_os_config_os_policy_assignment" "windows" {


  count = length(data.google_project.project[*].project_id)
  project = data.google_project.project[count.index].project_id

  location = "us-east1-b"

  name = "tenable-windows"

  instance_filter {
    all = false
    inventories {
      os_short_name = "windows"
    }
    inventories {
      os_short_name = "rhel"
    }
  }

  os_policies {
    id                            = "tenable-always-up-policy"
    allow_no_resource_group_match = false
    mode                          = "ENFORCEMENT"
    resource_groups {

      resources {

        id = "ensure-tenable-pkg-installed"
        pkg {
          desired_state = "INSTALLED"
          rpm {
            source {
              gcs {
                bucket     = var.bucket_name
                object     = var.nessus_windows
                generation = var.gen_number_nessus_windows
              }
            }
          }
        }
      }

      resources {
        id = "ensure-tenable-is-up"

        exec {
          validate {

            interpreter = "POWERSHELL"
            script      = "$service = Get-Service -Name 'Tenable Nessus Agent'
                           if ($service.Status -eq 'Running') {exit 100} else {exit 101}"

          }

          enforce {
            interpreter = "POWERSHELL"
            file {
              local_path = "./files/tenable_windows_script.sh"

            }
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      fixed = 1
    }
    min_wait_duration = "10s"
  }
}
*/
