#!/usr/bin/env bash

args=( -s terraform )
args+=("$@")

"$(dirname $0)"/compose.sh "${args[@]}"
