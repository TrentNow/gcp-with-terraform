terraform {
 backend "gcs" {
   bucket  = "v-terraform-admin"
   path    = "/terraform.tfstate"
   project = "v-terraform-admin"
 }
}
