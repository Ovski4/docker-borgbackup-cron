FROM ovski/ansible:v2.10.6

# Clone ansible playbooks
RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/Ovski4/ansible-playbook-mysql-dump.git /var/mysql-dump-playbook
RUN git clone https://github.com/Ovski4/ansible-playbook-mongo-dump.git /var/mongo-dump-playbook
RUN git clone https://github.com/Ovski4/ansible-playbook-borg-backup.git /var/borg-backup-playbook
RUN git clone https://github.com/Ovski4/ansible-playbook-elasticsearch-snapshot.git /var/elasticsearch-snapshot-playbook

# Install borg
RUN apt-get install -y \
    python3-dev \
    python-virtualenv \
    libssl-dev openssl \
    libacl1-dev libacl1 \
    build-essential \
    borgbackup

# Install packages for mysqldump
RUN apt-get install -y mariadb-client python3-apt
RUN pip3 install PyMySql

# Install cron
RUN apt-get install -y cron

COPY backup_script.sh /var/backup_script.sh
RUN chmod +x /var/backup_script.sh

COPY borgbackup_cron /etc/cron.d/borgbackup_cron
RUN chmod +x /etc/cron.d/borgbackup_cron
RUN crontab /etc/cron.d/borgbackup_cron

# Setup entrypoint
COPY entrypoint.sh /var/entrypoint.sh
RUN chmod +x /var/entrypoint.sh
ENTRYPOINT [ "/var/entrypoint.sh" ]

CMD ["cron", "-f"]
