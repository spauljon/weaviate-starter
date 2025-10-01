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

availability_zone = "us-east-1c" # or leave empty to let TF pick the first default subnet
