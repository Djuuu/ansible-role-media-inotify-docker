#!/usr/bin/env bash

update_navidrome() {
  local path="$1"
  local event="$2"

  [[ -z $NAVIDROME_BASE_URL ]] && echo "NAVIDROME_BASE_URL not set" && return 1
  [[ -z $NAVIDROME_VERSION  ]] && echo "NAVIDROME_VERSION not set"  && return 1
  [[ -z $NAVIDROME_CLIENT   ]] && echo "NAVIDROME_CLIENT not set"   && return 1
  [[ -z $NAVIDROME_USER     ]] && echo "NAVIDROME_USER not set"     && return 1
  [[ -z $NAVIDROME_TOKEN    ]] && echo "NAVIDROME_TOKEN not set"    && return 1
  [[ -z $NAVIDROME_SALT     ]] && echo "NAVIDROME_SALT not set"     && return 1

  local query="u=${NAVIDROME_USER}&v=${NAVIDROME_VERSION}&c=${NAVIDROME_CLIENT}&t=${NAVIDROME_TOKEN}&s=${NAVIDROME_SALT}"

  echo "Updating Navidrome: ${path}"

  curl "${NAVIDROME_BASE_URL}/startScan?${query}" \
    -s -o /dev/null -w "%{http_code}\n"
}
