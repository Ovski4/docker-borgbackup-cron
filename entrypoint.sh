#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [[ -n "$SSH_KNOWN_HOSTS" ]]; then
    echo "Adding domains and ips to known hosts"
    mkdir -p ~/.ssh
    touch ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
    while IFS=' ' read -ra entries; do
        for entry in "${entries[@]}"; do
            ssh-keyscan ${entry} >> ~/.ssh/known_hosts
        done
    done <<< "$SSH_KNOWN_HOSTS"
fi

if [[ -f /run/secrets/borg_passphrase ]]; then
    echo "Setting BORG_PASSPHRASE env variable from secret"
    export BORG_PASSPHRASE=$(cat /run/secrets/borg_passphrase)
elif [[ -z "$BORG_PASSPHRASE" ]]; then
    echo "BORG_PASSPHRASE env variable not set. Exiting"
    exit 1
fi

if [[ -f /run/secrets/mysql_password ]]; then
    echo "Setting MYSQL_PASSWORD env variable from secret"
    export MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
fi

if [[ -f /run/secrets/pg_password ]]; then
    echo "Setting PG_PASSWORD env variable from secret"
    export PG_PASSWORD=$(cat /run/secrets/pg_password)
fi

if [[ -f /run/secrets/smtp_password ]]; then
    echo "Setting SMTP_PASSWORD env variable from secret"
    export SMTP_PASSWORD=$(cat /run/secrets/smtp_password)
fi

# Make env variables accessible in crontab
declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

# Render cron template to actual crontab at container start so schedule can be configured via env
BACKUP_CRON_SCHEDULE="${BACKUP_CRON_SCHEDULE:-0 1 * * *}"
export BACKUP_CRON_SCHEDULE
envsubst < /etc/cron.d/borgbackup_cron.template > /etc/cron.d/borgbackup_cron
chmod +x /etc/cron.d/borgbackup_cron
crontab /etc/cron.d/borgbackup_cron

exec "$@"
