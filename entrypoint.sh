#!/bin/bash

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
if [[ ! -z "$GITLAB_USER" && ! -z "$GITLAB_PASSWORD" ]]; then
    echo "Cloning ansible gitlab repository"
    git clone https://${GITLAB_USER}:${GITLAB_PASSWORD}@gitlab.com/ovski-projects/infra/ansible.git /var/ansible
elif [[ -f /run/secrets/gitlab_user && -f /run/secrets/gitlab_password ]]; then
    GITLAB_USER=$(cat /run/secrets/gitlab_user)
    GITLAB_PASSWORD=$(cat /run/secrets/gitlab_password)
    git clone https://${GITLAB_USER}:${GITLAB_PASSWORD}@gitlab.com/ovski-projects/infra/ansible.git /var/ansible
else
    echo "Gitlab credentials not set. Exiting"
    exit 1
fi

# Set borg passphrase env variable
if [[ -f /run/secrets/borg_passphrase ]]; then
    echo "Setting BORG_PASSPHRASE env variable from secret"
    export BORG_PASSPHRASE=$(cat /run/secrets/borg_passphrase)
elif [[ -z "$BORG_PASSPHRASE" ]]; then
    echo "BORG_PASSPHRASE env variable not set. Exiting"
    exit 1
fi

# Make env variables accessible in crontab
declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

echo "Run the crontab in the foreground"
cron -f
