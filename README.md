Ansible Role: Media-Inotify-Docker
==================================

Docker-inotify project to notify media servers on file changes.

- https://github.com/devodev/docker-inotify

When media servers access files from a network share (SMB, NFS, ...), there can be issues with file change notifications
preventing real-time monitoring to work properly. In that case, you can run this service on your storage host (NAS) to
notify external media servers through their API when files are created, moved or deleted.

Supported media servers:
- [Jellyfin](https://jellyfin.org/)
- [Navidrome](https://navidrome.org/)

Requirements
------------

Requires the following to be installed:
- docker
- docker compose

Role Variables
--------------

Common Docker projects variables:

```yaml
# Base directory for Docker projects
docker_projects_path: # /var/apps
```

Available role variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Media inotify variables

# devodev/inotify image version
media_inotify_image_version: latest

# Events to watch (devodev/inotify defaults: [modify, delete, delete_self])
media_inotify_events:
  - create
  - move
  - delete

# Watch all subdirectories with unlimited depth
media_inotify_recursive: true

# Media server credentials

# Jellyfin
media_inotify_jellyfin_base_url: "" # ex: https://jellyfin.example.net
media_inotify_jellyfin_token: ""

# Navidrome
media_inotify_navidrome_base_url: "" # ex: https://navidrome.example.net/rest
media_inotify_navidrome_version: "1.16.1" # Subsonic API version
media_inotify_navidrome_client: "custom-update"
media_inotify_navidrome_user: "" # Navidrome username
media_inotify_navidrome_token: "" # md5(password + salt) (ex: echo -n "*****" | md5sum)
media_inotify_navidrome_salt: "" # custom salt used to generate token

# Watch definitions
media_inotify_watches: []
# Example:
#   - name: video
#
#     # Base directory to watch for events
#     watch_from: /share/Media/Video # on storage host
#     notify_to: /data/video         # as seen from media service (note: irrelevant for Navidrome)
#
#     # Sub-directories to watch (optional)
#     dirs:
#       - Movies
#       - Series
#       - Documentaries
#
#     # File extensions to watch (optional)
#     ext: ["avi","flv","mkv","mov","mp4","wmv","mpeg","mpg","srt","sub","idx","nfo"]
#
#     # Services to update ("jellyfin" | "navidrome")
#     update_services:
#       - jellyfin
```

Dependencies
------------

This role depends on :
- [djuuu.docker_project](https://github.com/Djuuu/ansible-role-docker-project)

Example Playbook
----------------

```yaml
- hosts: example
  gather_facts: false

  roles:
    - djuuu.media_inotify_docker
```

Adding other media servers
--------------------------

1. Create a new bash script in `files/handlers/` named after your service (e.g., `myserver.sh`).
2. Define a function named `update_<service_name>` (e.g., `update_myserver`).
   The function receives two arguments:
   - `$1`: The mapped path of the file to update on the target media server
   - `$2`: The inotify event type ('CREATE', 'MODIFY', 'MOVED_FROM', 'MOVED_TO', 'DELETE', 'CREATE,ISDIR', ...)
3. Use the service name in the `update_services` list in your configuration.

The main script automatically sources all files in the `handlers/` directory and calls the appropriate update function
based on the service name.

License
-------

Beerware License
