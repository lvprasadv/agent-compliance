/*########### data block to fetch projects under specific folder id ###########
data "google_projects" "folder-projects" {
  filter = "parent.id:${var.folder_id} lifecycleState:ACTIVE"
}
data "google_project" "project" {
    count = length(data.google_projects.folder-projects.projects)
    project_id = data.google_projects.folder-projects.projects[count.index].project_id
}
*/
############ os config policy - tenable ##############

resource "google_os_config_os_policy_assignment" "tenable_centos" {


  count = length(data.google_project.project[*].project_id)
  project = data.google_project.project[count.index].project_id

  location = "us-east1-b"

  name = "tenable-centos"

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
                object     = "NessusAgent-8.3.1-es7.x86_64.rpm"
                generation = var.gen_number_nessus_centos
              }
            }
          }
        }
      }

      resources {
        id = "ensure-tenable-is-up"

        exec {
          validate {

            interpreter = "SHELL"
            script      = "if systemctl is-active --quiet nessusagent.service; then exit 100; else exit 101; fi"

          }

          enforce {
            interpreter = "SHELL"
            file {
              local_path = "./files/tenable_linux_script.sh"

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

resource "google_os_config_os_policy_assignment" "tenable_ubuntu" {


  count = length(data.google_project.project[*].project_id)
  project = data.google_project.project[count.index].project_id

  location = "us-east1-b"

  name = "tenable-ubuntu"

  instance_filter {
    all = false
    inventories {
      os_short_name = "ubuntu"
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
                object     = "NessusAgent-8.3.1-ubuntu1110_amd64.deb"
                generation = var.gen_number_nessus_ubuntu
              }
            }
          }
        }
      }

      resources {
        id = "ensure-tenable-is-up"

        exec {
          validate {

            interpreter = "SHELL"
            script      = "if systemctl is-active --quiet nessusagent.service; then exit 100; else exit 101; fi"

          }

          enforce {
            interpreter = "SHELL"
            file {
              local_path = "./files/tenable_linux_script.sh"

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

resource "google_os_config_os_policy_assignment" "tenable_debian" {


  count = length(data.google_project.project[*].project_id)
  project = data.google_project.project[count.index].project_id

  location = "us-east1-b"

  name = "tenable-debian"

  instance_filter {
    all = false
    inventories {
      os_short_name = "debian"
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
                object     = "NessusAgent-8.3.1-debian6_amd64.deb"
                generation = var.gen_number_nessus_debian
              }
            }
          }
        }
      }

      resources {
        id = "ensure-tenable-is-up"

        exec {
          validate {

            interpreter = "SHELL"
            script      = "if systemctl is-active --quiet nessusagent.service; then exit 100; else exit 101; fi"

          }

          enforce {
            interpreter = "SHELL"
            file {
              local_path = "./files/tenable_linux_script.sh"

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


resource "google_os_config_os_policy_assignment" "tenable_windows" {


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
                object     = "NessusAgent-7.0.1-x64.msi"
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
