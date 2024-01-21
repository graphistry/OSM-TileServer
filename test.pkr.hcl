

# variables.pkr.hcl
variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_secret_key" {
  type    = string
  default = ""
}

packer {
  #  "variables": {
  #    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
  #    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}"
  #  }

  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


source "amazon-ebs" "ubuntu" {
  # access_key    = "{{user `aws_access_key`}}"
  # secret_key    = "{{user `aws_secret_key`}}"
  region        = "us-east-2"
  instance_type = "m6id.2xlarge"
  source_ami    = "ami-05fb0b8c1424f266b"
  ssh_username  = "ubuntu"
  ami_name      = "OSM-TileServer-{{timestamp}}"


  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 200
    volume_type           = "gp2"
    delete_on_termination = true
  }
}



build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/partial/",
      "sudo apt-get clean",
      "sudo apt-get update",
      # Add the default Ubuntu repositories
      "sudo apt-add-repository main",
      "sudo apt-add-repository universe",
      "sudo apt-add-repository restricted",
      "sudo apt-add-repository multiverse",
      "sudo apt-get update",
      "sudo apt-get install -y make",
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo chmod 777 /var/run/docker.sock"
    ]
  }

  provisioner "shell" {
    inline = [
      "git clone https://github.com/openmaptiles/openmaptiles.git",
      "cd openmaptiles",
      "make",
      "./quickstart.sh north-america/us/us-virgin-islands",
      "./quickstart.sh north-america/us/delaware"
    ]
  }
}

