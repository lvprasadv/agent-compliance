########### data block to fetch projects under specific folder id ###########
/*data "google_projects" "folder-projects" {
  filter = "parent.id:${var.folder_id} lifecycleState:ACTIVE"
}
data "google_project" "project" {
    count = length(data.google_projects.folder-projects.projects)
    project_id = data.google_projects.folder-projects.projects[count.index].project_id
}
}*/
  
############ os config policy - tenable ##############

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
    id                            = "nessus_agent_policy"
    allow_no_resource_group_match = false
    mode                          = "ENFORCEMENT"
    resource_groups {

      resources {
        id = "ensure-agents-online"

        exec {
          validate {

            interpreter = "SHELL"
            script      = "if systemctl is-active --quiet nessusagent.service; then exit 100; else exit 101; fi"

          }

          enforce {
            interpreter = "SHELL"
            script      = "gsutil cp gs://{{bucket_name}}/{{all_agent_check}}.sh /root; sleep 20s; dos2unix /root/{{all_agent_check}}.sh; bash /root/{{all_agent_check}}.sh"
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
