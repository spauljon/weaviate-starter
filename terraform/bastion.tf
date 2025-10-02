resource "aws_security_group" "bastion_ssh_sg" {
  name        = "${var.name_prefix}-bastion-ssh-sg"
  description = "SSH bastion (22 from ssh_allowed_cidr)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      var.ssh_allowed_cidr
    ]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = [
      "0.0.0.0/0"
    ]
    ipv6_cidr_blocks = [
      "::/0"
    ]
  }

  tags = {
    Name = "${var.name_prefix}-bastion-ssh-sg"
  }
}

resource "aws_instance" "bastion_ssh" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = local.chosen_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_ssh_sg.id]

  user_data = <<-BASH
    #!/usr/bin/bash
    dnf -y update
    dnf -y install bind-utils nmap-ncat
  BASH

  tags = { Name = "${var.name_prefix}-bastion-ssh" }
}

output "bastion_ssh_public_ip" {
  value = aws_instance.bastion_ssh.public_ip
}
