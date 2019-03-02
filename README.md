Borg backup cron
=================

A docker image to backup periodically a folder using borg

Build
-----

```
git clone git@gitlab.com:ovski-projects/docker-images/borgbackup-cron.git
cd borgbackup-cron
docker build -t ovski/borgbackup-cron:latest .
```

Usage
-----

docker run \
   -d \
   -v /path/to/folder_to_backup:/var/folder_to_backup \
   -v /path/to/backup_user_private_key:/var/run/backup_user_private_key \
   -e SSH_KNOWN_HOSTS=my-server.com,27.189.111.145 \
   -e SSH_CONNECTION=backup_user@my-server.com \
   -e PRIVATE_KEY_PATH=/var/run/backup_user_private_key \
   -e BORG_REPO_PATH=/home/backup_user/borg_repositories \
   -e BORG_REPO_NAME=folder_to_backup \
   -e BORG_PASSPHRASE=youyouthatsnotgood \
   -e LOCAL_FOLDER=/var/folder_to_backup \
   -e GITLAB_USER=gitlab+deploy-token-99999 \
   -e GITLAB_PASSWORD=keyhereverysecret \
   ovski/borgbackup-cron

You can also use secrets in a stack to store sensitive information.
Instead of specifiying environment variables, create the following secrets in /var/secrets (default location):

```
/run/secrets/borg_passphrase
/run/secrets/gitlab_user
/run/secrets/gitlab_password
```
