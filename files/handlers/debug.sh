#!/usr/bin/env bash

update_debug() {
  local path="$1"
  local event="$2"

  echo "DEBUG: ${event} ${path}"
}
