#!/bin/bash

ansible-playbook /var/borg-backup-playbook/main.yml \
    -e ssh_connection=$SSH_CONNECTION \
    -e private_key_path=$PRIVATE_KEY_PATH \
    -e borg_repo_path=$BORG_REPO_PATH \
    -e borg_repo_name=$BORG_REPO_NAME \
    -e borg_passphrase=$BORG_PASSPHRASE \
    -e local_folder=$LOCAL_FOLDER
