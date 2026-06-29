provider "aws" {
  region = var.aws_region
}

variable "ami_source" {
  description = "Choose how to resolve AMIs for the app instances. Use 'self' for custom AMIs baked in this account or 'public' for a public Ubuntu base AMI."
  type        = string
  default     = "self"

  validation {
    condition     = contains(["self", "public"], var.ami_source)
    error_message = "ami_source must be either 'self' or 'public'."
  }
}

locals {
  # Decode YAML and convert the array of objects into a map keyed by the 'id' field
  raw_catalog = yamldecode(file("${path.module}/catalog.yml"))["images"]
  catalog     = { for app in local.raw_catalog : app.id => app }
}

data "aws_ami" "app_amis" {
  for_each    = var.ami_source == "self" ? local.catalog : {}
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = [each.value.ami_filter_name]
  }
}

data "aws_ami" "public_base_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  resolved_ami_ids = {
    for app_id, app in local.catalog : app_id => var.ami_source == "self" ? data.aws_ami.app_amis[app_id].id : data.aws_ami.public_base_ami.id
  }
}

resource "aws_security_group" "app_sgs" {
  for_each    = local.catalog
  name        = "${each.key}-web-sg"
  description = "Managed Security Group for ${each.value.name}"

  ingress {
    from_port   = each.value.http_port
    to_port     = each.value.http_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_servers" {
  for_each               = local.catalog
  ami                    = local.resolved_ami_ids[each.key]
  instance_type          = each.value.instance_type
  vpc_security_group_ids = [aws_security_group.app_sgs[each.key].id]

  tags = {
    Name = "${each.value.name} Production"
  }
}
