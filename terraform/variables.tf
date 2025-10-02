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

# App Runner / container image
variable "ecr_repo_uri" {
  description = "ECR repo URI for the agent image (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/weaviate-agent)"
  type        = string
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID (e.g., anthropic.claude-3-5-haiku-20241022-v1:0)"
  type        = string
}

variable "weaviate_scheme" {
  description = "http or https to reach EC2 Weaviate"
  type        = string
  default     = "http"
}

variable "app_runner_public" {
  description = "Whether App Runner should expose a public HTTPS URL"
  type        = bool
  default     = true
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the internal NLB (min 2 AZs recommended)"
  type        = list(string)
  default     = []
}

variable "weaviate_port" {
  description = "Weaviate listen port"
  type        = number
  default     = 8080
}

variable "private_zone_name" {
  description = "Private hosted zone FQDN for internal service discovery (e.g., internal.example.com)"
  type        = string
}

variable "weaviate_internal_hostname" {
  description = "Hostname to create inside the private zone (e.g., weaviate)"
  type        = string
  default     = "weaviate"
}

variable "vpc_cidr_for_sg" {
  description = "VPC CIDR used to allow NLB->instance traffic on the target SG (because NLB preserves source IP)"
  type        = string
}

