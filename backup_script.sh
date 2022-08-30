#!/bin/bash

send_email() {
    ansible-playbook /var/smtp-email-playbook/main.yml \
        -e "smtp_user=$SMTP_USER" \
        -e "smtp_password=$SMTP_PASSWORD" \
        -e "smtp_port=$SMTP_PORT" \
        -e "smtp_host=$SMTP_HOST" \
        -e "mail_to='$MAIL_TO'" \
        -e "mail_body='$MAIL_BODY'" \
        -e "mail_subject='$MAIL_SUBJECT'"
}

if [[ ! -z "$SMTP_USER" && ! -z "$SMTP_PASSWORD" && ! -z "$SMTP_PORT" && ! -z "$SMTP_HOST" && ! -z "$MAIL_TO" && ! -z "$MAIL_BODY" && ! -z "$MAIL_SUBJECT" ]]; then
    set -o errexit -o errtrace
    trap send_email ERR
fi

if [[ ! -z "$MYSQL_USER" && ! -z "$MYSQL_DATABASE" && ! -z "$MYSQL_PASSWORD" && ! -z "$MYSQL_HOST" ]]; then
    ansible-playbook /var/mysql-dump-playbook/main.yml \
        -e "mysql_dumps_target_folder=$LOCAL_FOLDER" \
        -e "prune=yes" \
        -e "db_user=$MYSQL_USER" \
        -e "db_password=$MYSQL_PASSWORD" \
        -e "db_host=$MYSQL_HOST" \
        -e "db_name=$MYSQL_DATABASE"
fi

if [[ ! -z "$MONGO_HOST" && ! -z "$MONGO_DATABASE" && ! -z "$MONGO_PORT" ]]; then
    ansible-playbook /var/mongo-dump-playbook/main.yml \
        -e "mongo_dumps_target_folder=$LOCAL_FOLDER" \
        -e "prune=yes" \
        -e "db_port=$MONGO_PORT" \
        -e "db_host=$MONGO_HOST" \
        -e "db_name=$MONGO_DATABASE"
fi

if [[ ! -z "$ELASTICSEARCH_HOST" && ! -z "$ELASTICSEARCH_REPOSITORY" && ! -z "$ELASTICSEARCH_PORT" ]]; then
    ansible-playbook /var/elasticsearch-snapshot-playbook/main.yml \
        -e "elasticsearch_port=$ELASTICSEARCH_PORT" \
        -e "elasticsearch_host=$ELASTICSEARCH_HOST" \
        -e "elasticsearch_repository=$ELASTICSEARCH_REPOSITORY"
fi

ansible-playbook /var/borg-backup-playbook/main.yml \
    -e "ssh_connection=$SSH_CONNECTION" \
    -e "private_key_path=$PRIVATE_KEY_PATH" \
    -e "borg_repo_path=$BORG_REPO_PATH" \
    -e "borg_repo_name=$BORG_REPO_NAME" \
    -e "borg_passphrase=$BORG_PASSPHRASE" \
    -e "local_folder=$LOCAL_FOLDER"
