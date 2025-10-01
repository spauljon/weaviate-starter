#!/usr/bin/env bash

SECRET=$(< /work/.private/openai.txt)

aws secretsmanager create-secret \
  --name weaviate/openai \
  --secret-string ${SECRET}
