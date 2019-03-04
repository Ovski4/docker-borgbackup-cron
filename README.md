Borg backup cron
=================

A docker image to backup periodically a folder using borg.
Additionnally this image can dump a mysql database in the same folder beforehand.

Build
-----

```
git clone git@gitlab.com:ovski-projects/docker-images/borgbackup-cron.git
cd borgbackup-cron
docker build -t ovski/borgbackup-cron:latest .
```

Usage
-----

1. Make sure borg is installed on your remote server
2. Make sure the public key associated with the given private key is present in the ~/.ssh/authorized_keys file of your remote server
3. Replace the value of the environment variables of the following command according to your needs.

```bash
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
   ovski/borgbackup-cron
```

With mysql dump

```bash
docker run \
   # ... other options
   -e MYSQL_USER=/var/folder_to_backup \
   -e MYSQL_DATABASE=/var/folder_to_backup \
   -e MYSQL_PASSWORD=/var/folder_to_backup \
   ovski/borgbackup-cron
```

You can also use secrets in a stack to store sensitive information.
Instead of specifiying environment variables, create the following secrets in /var/secrets (default location):

```
/run/secrets/borg_passphrase instead of BORG_PASSPHRASE
/run/secrets/db_password instead of MYSQL_PASSWORD
```
