#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Add known hosts
if [[ -n "$SSH_KNOWN_HOSTS" ]]; then
    echo "Adding domains and ips to known hosts"
    mkdir -p ~/.ssh
    touch ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
    while IFS=' ' read -ra entries; do
        for entry in "${entries[@]}"; do
            ssh-keyscan -Ht rsa ${entry} >> ~/.ssh/known_hosts
        done
    done <<< "$SSH_KNOWN_HOSTS"
fi

# Clone ansible playbooks
echo "Cloning ansible gitlab repositories"
git clone https://gitlab.com/ovski-projects/infra/ansible-playbooks/borg-backup.git /var/borg-backup-playbook
git clone https://gitlab.com/ovski-projects/infra/ansible-playbooks/mysql-dump.git /var/mysql-dump-playbook

# Set borg passphrase env variable
if [[ -f /run/secrets/borg_passphrase ]]; then
    echo "Setting BORG_PASSPHRASE env variable from secret"
    export BORG_PASSPHRASE=$(cat /run/secrets/borg_passphrase)
elif [[ -z "$BORG_PASSPHRASE" ]]; then
    echo "BORG_PASSPHRASE env variable not set. Exiting"
    exit 1
fi

if [[ -f /run/secrets/db_password ]]; then
    echo "Setting MYSQL_PASSWORD env variable from secret"
    export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

# Make env variables accessible in crontab
declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

exec "$@"
