#!/usr/bin/env bash

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# subshells and functions inherit ERR traps
set -E

# store hostname
HOSTNAME="$(hostname)"

# store date
DATE="$(date +%Y-%m-%d)"

# set colour codes
yellow=$(echo -e "setaf 3\nbold" | tput -S)
blue=$(echo -e "setaf 6\nbold" | tput -S)
reset=$(tput sgr0)

# create temporary backup directory
LOCALDIR="$(mktemp -d)"

# run on exit
function cleanup {
  # remove temp directory
  rm -rf "$LOCALDIR"

  # start all containers
  COMPOSEDIR="/root/docker"
  PROJECTNAME="docker"
  cd "$COMPOSEDIR" && /usr/local/bin/docker-compose -f "$COMPOSEDIR"/docker-compose.yml -p "$PROJECTNAME" start
}
trap cleanup EXIT

# set remote backup directory
BACKUP1REMOTE="backup1:Backups/Internal/Docker/$HOSTNAME/$DATE"

# set compose directory
COMPOSEDIR="/root/docker"

# echo a blank line to begin
echo -e ""

# iterate through all containers, backing up any volumes
for CONTAINER in $(/usr/local/bin/docker-compose -f "$COMPOSEDIR"/docker-compose.yml ps -q); do
  # store container name
  CONTAINER_NAME="$(docker ps --filter "id=$CONTAINER" --format "{{.Names}}")"

  # find all volume mounts
  VOLUMES=($(docker inspect -f '{{ json .Mounts }}' $CONTAINER | jq '.[] | .Name' | grep -v "null" | grep "docker_" | grep -v "docker_traefik" | sed 's/"//g'))

  # count number of volume mounts
  VOLUME_COUNT=${#VOLUMES[@]}

  # if no volume mounts are found, do nothing
  if [ $VOLUME_COUNT -eq 0 ]; then
    echo -e "No volumes found for $CONTAINER_NAME.\n"
  # otherwise, stop the container and back up each mount
  else
    echo "${yellow}Stopping container $CONTAINER_NAME.${reset}"
    docker stop "$CONTAINER" 1> /dev/null
    for VOLUME in ${VOLUMES[*]}; do
      echo " [ ] Backing up volume $VOLUME."
      docker run -t --rm -v "$VOLUME":/"$VOLUME":ro -v "$LOCALDIR":/target registry.docker.as212934.net/backup:latest /bin/ash -c "cd /$VOLUME && tar -czf - . --xform s:'^./':: | pv -t -r -b > /target/"$DATE"_"$VOLUME".tgz"
      echo -ne "`tput cuu 2`\033[0J [x] Backed up volume $VOLUME.\n"
    done
    echo -e "${blue}Starting container $CONTAINER_NAME.${reset}\n"
    docker start "$CONTAINER" 1> /dev/null
  fi
done

# create backup directory on dropbox
rclone mkdir "$BACKUP1REMOTE"

# copy files over to dropbox
rclone copy --verbose "$LOCALDIR" "$BACKUP1REMOTE"