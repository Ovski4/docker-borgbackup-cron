FROM ovski/ansible:v2.20.0

# Install borg
RUN apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-virtualenv \
    libacl1-dev libacl1 \
    libssl-dev \
    liblz4-dev libzstd-dev libxxhash-dev \
    build-essential \
    pkg-config python3-pkgconfig \
    borgbackup

# Install packages for mysqldump
RUN apt-get install -y mariadb-client python3-apt
RUN pip3 install PyMySql

# Install cron
RUN apt-get install -y cron

COPY backup_script.sh /var/backup_script.sh
RUN chmod +x /var/backup_script.sh

COPY borgbackup_cron.template /etc/cron.d/borgbackup_cron.template

# envsubst (from gettext-base) is used at container start to render the cron template
RUN apt-get install -y gettext-base

# Clone ansible playbooks
RUN apt-get --allow-releaseinfo-change update && apt-get install -y git
RUN git clone --depth 1 https://github.com/Ovski4/ansible-playbook-smtp-email.git /var/smtp-email-playbook
RUN git clone --depth 1 https://github.com/Ovski4/ansible-playbook-mysql-dump.git /var/mysql-dump-playbook
RUN git clone --depth 1 https://github.com/Ovski4/ansible-playbook-mongo-dump.git /var/mongo-dump-playbook
RUN git clone --depth 1 https://github.com/Ovski4/ansible-playbook-borg-backup.git /var/borg-backup-playbook
RUN git clone --depth 1 https://github.com/Ovski4/ansible-playbook-elasticsearch-snapshot.git /var/elasticsearch-snapshot-playbook

# Setup entrypoint
COPY entrypoint.sh /var/entrypoint.sh
RUN chmod +x /var/entrypoint.sh
ENTRYPOINT [ "/var/entrypoint.sh" ]

CMD ["cron", "-f"]
