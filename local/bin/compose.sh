#!/usr/bin/env bash

## usage
usage() {
  echo "usage: $0 [-s <compose stack>] "
  echo "    parameters:"
  echo "        -h: help (show usage)"
  echo "        -s [stack]: the compose stack, defaults to 'awscli'"

  exit 1;
}

process_args() {
  local tok
  g_rest=()
  g_stack=awscli

  args=("$@")
  for ((i=0; i<${#args[@]}; i++)); do
    tok="${args[i]}"
    case "$tok" in
      -s)
        if (( i+1 < ${#args[@]} )); then
          g_stack="${args[i+1]}"
          ((i++))                  # skip its value
        else
          echo "error: $tok requires a value" >&2
          exit 2
        fi
        ;;
      *)  # anything else is kept
        g_rest+=("$tok")
        ;;
    esac
  done

}

process_args "$@"

source "$(dirname "$0")/prologue.sh"

# shellcheck disable=SC2154
docker compose -f "${compose_dir}/${g_stack}"-compose.yml --project-name "${g_stack}" "${g_rest[@]}"
