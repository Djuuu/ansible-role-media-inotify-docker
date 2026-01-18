#!/usr/bin/env bash

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
