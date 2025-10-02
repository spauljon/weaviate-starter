#!/usr/bin/env bash

args=( -s weaviate )
args+=("$@")

"$(dirname $0)"/compose.sh "${args[@]}"
