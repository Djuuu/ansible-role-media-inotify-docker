#!/usr/bin/env bash

[[ -z $WATCH_FROM ]] && echo "WATCH_FROM not set" && exit 1
[[ -z $NOTIFY_TO  ]] && echo "NOTIFY_TO not set"  && exit 1

WATCH_FROM="${WATCH_FROM%/}/" # ensure trailing slash
NOTIFY_TO="${NOTIFY_TO%/}/" # ensure trailing slash


check_event_handled() {
  local event=$1

  case $event in
    CREATE)       return 0 ;;
    MODIFY)       return 0 ;;
    MOVED_FROM)   return 0 ;;
    MOVED_TO)     return 0 ;;
    DELETE)       return 0 ;;

    # Ignore directory creation (only consider files)
    CREATE,ISDIR) echo "Ignoring event: ${event}"; exit ;;

    MODIFY,ISDIR)       return 0 ;;
    MOVED_FROM,ISDIR)   return 0 ;;
    MOVED_TO,ISDIR)     return 0 ;;

    # Ignore directory deletion (only consider files)
    DELETE,ISDIR) echo "Ignoring event: ${event}"; exit ;;

    *) return 0 ;;
  esac
}

check_path_handled() {
  local path=$1

  [[ $path != "${WATCH_FROM}"* ]] &&
    echo "Path not handled: ${path}" &&
    exit

  [[ -z $WATCH_DIRS ]] && return 0 # no dir filter

  local dir
  while IFS='|' read -d '|' -r dir || [[ -n "$dir" ]]; do
    if [[ $path == "${WATCH_FROM}${dir}"* ]]; then
      return 0
    fi
  done <<< "${WATCH_DIRS}|"

  echo "Ignoring path: ${path}"
  exit
}

check_ext_handled() {
  local path=$1

  [[ -z $WATCH_EXT ]] && return 0 # no ext filter

  local extension
  extension="${1##*.}" # extract extension
  extension="${extension,,}" # to lowercase

  local ext
  while IFS='|' read -d '|' -r ext || [[ -n "$ext" ]]; do
    [[ $extension == "$ext" ]] && return 0
  done <<< "${WATCH_EXT}|"

  echo "Ignoring extension: ${1}"
  exit
}

map_path() {
  echo "${1/#$WATCH_FROM/$NOTIFY_TO}"
}

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  echo "$s"
}

update_jellyfin() {
  local path="$1"
  local event="$2"

  local updateType

  [[ -z $JELLYFIN_BASE_URL ]] && echo "JELLYFIN_BASE_URL not set" && return 1
  [[ -z $JELLYFIN_TOKEN    ]] && echo "JELLYFIN_TOKEN not set"    && return 1

  case $event in
    CREATE)       updateType="Created"  ;;
    MODIFY)       updateType="Modified" ;;
    MOVED_FROM)   updateType="Modified" ;;
    MOVED_TO)     updateType="Modified" ;;
    DELETE)       updateType="Deleted"  ;;

    # CREATE,ISDIR)   ;; # unhandled
    MODIFY,ISDIR)     updateType="Modified" ;;
    MOVED_FROM,ISDIR) updateType="Modified" ;;
    MOVED_TO,ISDIR)   updateType="Modified" ;;
    # DELETE,ISDIR)   ;; # unhandled

    *)
      updateType="Modified"
      echo "event is $event ???"
      ;;
  esac

  echo "Updating Jellyfin: ${updateType} ${path}"

  path=$(json_escape "$path")

  local data="{\"Updates\": [{\"Path\": \"${path}\",\"UpdateType\": \"${updateType}\"}]}"
  #echo "${data}"

  curl -X 'POST' \
    -H "Authorization: MediaBrowser Token=${JELLYFIN_TOKEN}, Client=custom-watcher" \
    -H 'Content-Type: application/json' \
    "${JELLYFIN_BASE_URL}/Library/Media/Updated" \
    -d "${data}" \
    -s -w "%{http_code}\n"
}

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


main() {
  # shellcheck disable=SC2034
  local timestamp=$1
  local directory=${2%/} # strip trailing slash
  local event=$3
  local filename=$4

  local event_path="$directory/$filename"
  local action

  echo "--------------------------------------------------"
  echo "event: ${event} ${event_path}"

  check_event_handled "$event"
  check_path_handled "$event_path"
  [[ -f $event_path ]] &&
    check_ext_handled "$event_path"

  local file_target
  file_target=$(map_path "$event_path")

  while IFS=',' read -d ',' -r action || [[ -n "$action" ]]; do
    [[ -z ${action//$'\n'/} ]] && continue

    case $action in
      jellyfin)  update_jellyfin "${file_target}" "${event}" ;;
      navidrome) update_navidrome "${file_target}" "${event}" ;;
      *) echo "Unhandled update action: $action" ;;
    esac
  done <<< "${WATCH_UPDATE},"
}

main "$@"
