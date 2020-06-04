/*
This template is for provisioning of
  any resource that uses instances such as
  EC2 and RDS
*/

provider "aws" {
  profile = "terraform"
  region  = "ap-southeast-1"
}