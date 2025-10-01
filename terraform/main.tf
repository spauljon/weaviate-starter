terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- Default VPC ---
data "aws_vpc" "default" {
  default = true
}

# --- Optional: pick subnets by AZ ---
data "aws_subnets" "by_az" {
  count = var.subnet_id == "" && var.availability_zone != "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

# --- Fallback: any subnet in default VPC ---
data "aws_subnets" "any" {
  count = var.subnet_id == "" && var.availability_zone == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Decide the subnet id ---
locals {
  chosen_subnet_id = var.subnet_id != "" ? var.subnet_id : (
    var.availability_zone != "" ?
    tolist(data.aws_subnets.by_az[0].ids)[0] :
    tolist(data.aws_subnets.any[0].ids)[0]
  )
  ssh_cidr = var.ssh_allowed_cidr != "" ? var.ssh_allowed_cidr : var.allowed_cidr
}

# --- Get details of chosen subnet ---
data "aws_subnet" "chosen" {
  id = local.chosen_subnet_id
}

# --- Latest Amazon Linux 2023 AMI ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- Security Group ---
resource "aws_security_group" "weaviate_sg" {
  name        = "${var.name_prefix}-sg"
  description = "Allow 8080 from allowed CIDR; optional SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Weaviate"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  dynamic "ingress" {
    for_each = var.key_name == "" ? [] : [1]

    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [local.ssh_cidr]
    }
  }

  egress {
    description      = "All egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

# --- IAM for Secrets Manager ---
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "weaviate_role" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "secrets_read" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.openai_secret_arn]
  }
}

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.name_prefix}-secrets-read"
  description = "Allow EC2 to read OpenAI API key from Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_read.json
}

resource "aws_iam_role_policy_attachment" "attach_secrets_read" {
  role       = aws_iam_role.weaviate_role.name
  policy_arn = aws_iam_policy.secrets_read.arn
}

resource "aws_iam_instance_profile" "weaviate_profile" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.weaviate_role.name
}

# --- User Data Template ---
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh.tmpl")

  vars = {
    OPENAI_SECRET_ARN    = var.openai_secret_arn
    ENABLE_OPENAI_MODULE = var.enable_openai_module ? "true" : "false"
  }
}

# --- EC2 Instance ---
resource "aws_instance" "weaviate" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  subnet_id         = data.aws_subnet.chosen.id
  availability_zone = data.aws_subnet.chosen.availability_zone

  vpc_security_group_ids      = [aws_security_group.weaviate_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  iam_instance_profile = aws_iam_instance_profile.weaviate_profile.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    encrypted             = true
    delete_on_termination = true
  }

  user_data                   = data.template_file.user_data.rendered
  user_data_replace_on_change = true

  tags = {
    Name           = "${var.name_prefix}-ec2"
    SubnetSelected = data.aws_subnet.chosen.id
    SubnetAZ       = data.aws_subnet.chosen.availability_zone
    SubnetCIDR     = data.aws_subnet.chosen.cidr_block
  }
}
