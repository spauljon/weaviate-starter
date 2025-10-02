region = "us-east-1"

allowed_cidr = "91.196.69.250/32"

ssh_allowed_cidr = "91.196.69.250/32"

key_name = "weaviate-key"

instance_type = "t3.small"

root_volume_size_gb = 20

name_prefix = "weaviate"

openai_secret_arn = "arn:aws:secretsmanager:us-east-1:533267282838:secret:weaviate/openai-d2flZb"

enable_openai_module = true

subnet_id = "" # leave empty to auto-select

availability_zone = "us-east-1c"

ecr_repo_uri = "533267282838.dkr.ecr.us-east-1.amazonaws.com/weaviate-agent"

image_tag = "latest"

bedrock_model_id = "anthropic.claude-3-5-haiku-20241022-v1:0"

vpc_cidr_for_sg = "172.31.0.0/16"

private_zone_name = "vpc.internal"

app_runner_public = true
