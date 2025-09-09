provider "aws" {
  region = "ap-southeast-2" # change if needed
}

# --- Get Latest Ubuntu 22.04 AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "attack_range" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "attack-range-server"
  }
}

# --- Security Group ---
resource "aws_security_group" "attack_range_sg" {
  name        = "attack-range-sg"
  description = "Security group for attack-range-server"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # replace with your IP for safety
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom TCP 8000–9999
  ingress {
    from_port   = 8000
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Attach SG to EC2
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.attack_range_sg.id
  network_interface_id = aws_instance.attack_range.primary_network_interface_id
}

# --- Output Public IP ---
output "attack_range_public_ip" {
  value = aws_instance.attack_range.public_ip
}

# --- Create Ansible Inventory File ---
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"

  content = <<EOT
[attack_range]
${aws_instance.attack_range.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file="/mnt/c/Users/Dhaarun M V/OneDrive/Documents/Downloads/Attack_range.pem" ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}
