region = "us-east-1"

allowed_cidr = "91.196.69.165/32"

ssh_allowed_cidr = "91.196.69.165/32"

key_name = "weaviate-key"

instance_type = "t3.small"

root_volume_size_gb = 20

name_prefix = "weaviate"

openai_secret_arn = "arn:aws:secretsmanager:us-east-1:533267282838:secret:weaviate/openai-d2flZb"

enable_openai_module = true

subnet_id         = ""           # leave empty to auto-select

availability_zone = "us-east-1c"

ecr_repo_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/weaviate-agent"

image_tag        = "latest"

bedrock_model_id = "anthropic.claude-3-5-haiku-20241022-v1:0"

private_subnet_ids = [
  "subnet-095eb9e0fea702338"
]

# Your VPC CIDR (so the instance SG can allow TCP 8080 from inside the VPC)
vpc_cidr_for_sg = "10.0.0.0/16"

# --- Compute target (the instance currently running Weaviate) ---
# If you create the instance with Terraform, see the notes below to avoid hardcoding this.
weaviate_instance_id = "i-0123456789abcdef0"

# --- Weaviate port (leave as default if you didn't change it) ---
weaviate_port = 8080

# --- Internal DNS (Route 53 Private Hosted Zone) ---
# OPTION 1: You ALREADY HAVE a private hosted zone with this name and it's associated to the VPC:
private_zone_name   = "internal.example.com"
create_private_zone = false

# OPTION 2: You want Terraform to CREATE the private hosted zone in this VPC:
# private_zone_name   = "internal.example.com"
# create_private_zone = true

# The host label that will be created inside the zone (FQDN will be host + zone)
weaviate_internal_hostname = "weaviate"

# --- Existing vars from your stack (fill as you already do) ---
region            = "us-east-1"
allowed_cidr      = "203.0.113.5/32"  # your VPN/home IP for port 8080 (if you also expose public)
ssh_allowed_cidr  = "203.0.113.5/32"  # or empty "" to fall back to allowed_cidr in your SG logic
key_name          = "your-ec2-keypair-name"
instance_type     = "t3.small"
root_volume_size_gb = 20
name_prefix       = "weaviate"

# Secrets / app config you already use
openai_secret_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:openai-api-key-xxxxx"
enable_openai_module  = true

# Optional subnet pinning (only if you use those elsewhere)
subnet_id          = ""
availability_zone  = ""

# App image + Bedrock settings you already had
ecr_repo_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/weaviate-agent"
image_tag        = "latest"
bedrock_model_id = "anthropic.claude-3-5-haiku-20241022-v1:0"

# If you use App Runner elsewhere in this stack
weaviate_scheme     = "http"
app_runner_public   = true
