provider "aws" {
  region = var.aws_region
}

locals {
  # Decode YAML and convert the array of objects into a map keyed by the 'id' field
  raw_catalog = yamldecode(file("${path.module}/catalog.yml"))["images"]
  catalog     = { for app in local.raw_catalog : app.id => app }
}

data "aws_ami" "app_amis" {
  for_each    = local.catalog
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = [each.value.ami_filter_name]
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
  ami                    = data.aws_ami.app_amis[each.key].id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = [aws_security_group.app_sgs[each.key].id]

  tags = {
    Name = "${each.value.name} Production"
  }
}
