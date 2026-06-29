packer {
  required_plugins {
    amazon  = { version = ">= 1.2.8", source = "github.com/hashicorp/amazon" }
    ansible = { version = ">= 1.1.1", source = "github.com/hashicorp/ansible" }
  }
}

variable "app_id" { type = string }
variable "ami_name_prefix" { type = string }
variable "instance_type" { type = string }
variable "playbook_path" { type = string }

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"
  instance_type = var.instance_type
  region        = "us-east-1"
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "ansible" {
    playbook_file = var.playbook_path
    user          = "ubuntu"
    use_proxy     = false

    extra_arguments = [
      "--extra-vars", "@packer_vars.json"
    ]
  }
}