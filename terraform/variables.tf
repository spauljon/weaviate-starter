variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "allowed_cidr" {
  description = "Your IP/VPN CIDR (e.g., 203.0.113.5/32) to allow access to port 8080"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed for SSH (port 22). If empty, falls back to allowed_cidr."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "EC2 key pair name to enable SSH (leave empty to disable SSH ingress)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for Weaviate"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size_gb" {
  description = "Root gp3 volume size (GB)"
  type        = number
  default     = 20
}

variable "name_prefix" {
  description = "Name prefix for resources (used in tags and IAM role names)"
  type        = string
  default     = "weaviate"
}

variable "openai_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret that stores the OpenAI API key"
  type        = string
}

variable "enable_openai_module" {
  description = "Enable text2vec-openai at boot (requires openai_secret_arn)"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Optional: explicit subnet ID to use (overrides AZ)"
  type        = string
  default     = ""
}

variable "availability_zone" {
  description = "Optional: if subnet_id is empty, pick a subnet in this AZ"
  type        = string
  default     = ""
}
