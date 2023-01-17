 variable "folder_id" {
   description = "Folder id where to list projects."
   type        = string
}

 variable "bucket_name" {
   description = "Bucket where exe are placed"
   type        = string
}

 variable "gen_number_linux_presnapshot" {
   description = "Generation number of linux presnapshot available in GCS"
   type        = string
}

 variable "gen_number_nessus_centos" {
   description = "Generation number of centos nessus agent available in GCS"
   type        = string
}

 variable "gen_number_nessus_ubuntu" {
   description = "Generation number of ubuntu nessus agent available in GCS"
   type        = string
}

 variable "gen_number_nessus_debian" {
   description = "Generation number of debian nessus agent available in GCS"
   type        = string
}


 variable "gen_number_nessus_windows" {
   description = "Generation number of windows nessus agent available in GCS"
   type        = string
}
