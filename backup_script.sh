#!/bin/bash

if [[ ! -z "$MYSQL_USER" && ! -z "$MYSQL_DATABASE" && ! -z "$MYSQL_PASSWORD" ]]; then
    ansible-playbook /var/mysql-dump-playbook/main.yml \
        -e "mysql_dumps_target_folder=$LOCAL_FOLDER/mysql_dumps" \
        -e "prune=yes" \
        -e "db_user=$MYSQL_USER" \
        -e "db_password=$MYSQL_PASSWORD" \
        -e "db_host=mysql" \
        -e "db_name=$MYSQL_DATABASE"
fi

ansible-playbook /var/borg-backup-playbook/main.yml \
    -e "ssh_connection=$SSH_CONNECTION" \
    -e "private_key_path=$PRIVATE_KEY_PATH" \
    -e "borg_repo_path=$BORG_REPO_PATH" \
    -e "borg_repo_name=$BORG_REPO_NAME" \
    -e "borg_passphrase=$BORG_PASSPHRASE" \
    -e "local_folder=$LOCAL_FOLDER"
