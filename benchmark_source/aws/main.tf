terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
    region  = var.region
    profile = var.profile
    shared_credentials_files = ["./credentials"]
}


resource "aws_instance" "benchmark_server" {

  for_each = toset(var.instances_type)
  ami           = var.server_ami
  instance_type = each.value
  key_name      = "se-keypair"
  tags = {
    "Name" = "benchmark-${each.value}"
  }
  user_data = file("startup-script")
  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
    tags = {
      "Name" = "benchmark-${each.value}"
    }
  }
}