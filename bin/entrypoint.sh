#!/usr/bin/env sh

export OPENAI_APIKEY=$(cat /run/secrets/openai_api_key)
export ANTHROPIC_APIKEY=$(cat /run/secrets/anthropic_api_key)

exec /bin/weaviate "$@"
