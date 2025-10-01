#!/usr/bin/env bash

aws ec2 create-key-pair \
  --key-name weaviate-key \
  --query 'KeyMaterial' \
  --output text > weaviate-key.pem
