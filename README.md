Borg backup cron
================

A Docker image that performs **scheduled, encrypted, deduplicated backups** of Docker volumes using **BorgBackup**.

It is designed to run alongside your existing containers (Docker Compose or Docker Swarm) and periodically back up application data to a remote Borg repository over SSH.

Full tutorial can be read at https://baptiste.bouchereau.pro/tutorial/backup-docker-volumes-with-borg/.

Table of contents
-----------------

- [Features](#features)
- [Backup schedule](#backup-schedule)
- [Build](#build)
- [Usage](#usage)
  - [With MySQL / MariaDB dump](#with-mysql-mariadb-dump)
  - [With mongo dump](#with-mongo-dump)
  - [With elasticsearch snapshot](#with-elasticsearch-snapshot)
  - [Sending an email on failure](#sending-an-email-on-failure)
  - [Using Docker secrets (recommended)](#using-docker-secrets-recommended)
  - [Example with Docker Compose](#example-with-docker-compose)
- [Restoring backups](#restoring-backups)
- [Reference links](#reference-links)

Features
--------

- 📦 Incremental, encrypted backups with Borg
- ⏱️ Automated backups via cron
- 🐳 Designed for Docker Compose & Docker Swarm
- 🗄️ Optional database dumps:
  - MySQL
  - MongoDB
- 🔍 Elasticsearch snapshot support
- 📧 Email notification on backup failure
- 🔐 Supports Docker secrets for sensitive data
- ▶️ Can be run manually (one-shot backup)

Backup schedule
---------------

By default, backups are executed via cron inside the container.

- The crontab process is the container main process. Its job runs automatically when the container is started.
- The default schedule is every day at 1AM. Set your own schedule by setting the `BACKUP_CRON_SCHEDULE` env var (examples below).
- You can also run the cron job directly by overriding the command with value `/var/backup_script.sh`.

Timezone handling depends on the container configuration (use TZ if needed).

Build
-----

```
git clone https://github.com/Ovski4/docker-borgbackup-cron.git
cd docker-borgbackup-cron
docker build -t ovski/borgbackup-cron:latest .
```

Usage
-----

1. Ensure borg is installed on your **remote server**.
2. Add the public SSH key to `~/.ssh/authorized_keys` on your remote server.
3. Run the container with the required environment variables.

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
   -e BACKUP_CRON_SCHEDULE="0 1 * */1 *"
   ovski/borgbackup-cron
```

> You can use use [https://crontab.guru/](https://crontab.guru/) and copy the crontab value in `BACKUP_CRON_SCHEDULE`.

### With MySQL / MariaDB dump

```bash
-e MYSQL_USER=myuser \
-e MYSQL_DATABASE=mydbname \
-e MYSQL_PASSWORD=mypass \
-e MYSQL_HOST=mysql
```

### With MongoDB dump

```bash
-e MONGO_PORT=27017 \
-e MONGO_DATABASE=my_mongo_dbname \
-e MONGO_HOST=mongo
```

### With Elasticsearch snapshot

```bash
-e ELASTICSEARCH_PORT=9200 \
-e ELASTICSEARCH_HOST=elasticsearch \
-e ELASTICSEARCH_REPOSITORY=backup
```

### Email notification on failure

```bash
-e SMTP_USER=smtpuser@gmail.com \
-e SMTP_PASSWORD=smtppassword \
-e SMTP_PORT=465 \
-e SMTP_HOST=smtp.gmail.com \
-e MAIL_TO=Test User <user@domain.com> \
-e MAIL_BODY="Backup failed" \
-e MAIL_SUBJECT="Backup job failed. Check container logs for details." \
```

### Using Docker secrets (recommended)

For better security, sensitive values can be provided using Docker secrets instead of environment variables.
Create the following files in `/run/secrets` (default location):

| Secret file     | Environment variable |
| --------------- | -------------------- |
| borg_passphrase | BORG_PASSPHRASE      |
| db_password     | MYSQL_PASSWORD       |
| smtp_password   | SMTP_PASSWORD        |

### Example with Docker Compose

> Taking a nextcloud app as an example, here is an excerpt of a docker compose configuration that will backup nextcloud data and create a MySQL dump.

```yml
volumes:
  mysql:
  data:

services:

  mysql:
    image: mysql
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_USER: nextcloud
      MYSQL_DATABASE: nextcloud
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - mysql:/var/lib/mysql
    secrets:
      - db_root_password
      - db_password

  php:
    image: nextcloud
    volumes:
      - data:/var/www/html
    depends_on:
      - mysql

  nginx:
    image: nginx:1.15.8-alpine
    ...
    volumes:
      - data:/var/www/html

  ...

  backup_cron:
    image: ovski/borgbackup-cron:latest
    volumes:
      - data:/var/docker_volumes/nextcloud/app/data
    environment:
      SSH_CONNECTION: backup_user@your.server.net
      PRIVATE_KEY_PATH: /run/secrets/backup_server_user_private_key
      BORG_REPO_PATH: /home/backup_user/borg_repositories
      BORG_REPO_NAME: nextcloud
      LOCAL_FOLDER: /var/docker_volumes/nextcloud
      MYSQL_USER: nextcloud
      MYSQL_DATABASE: nextcloud
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
      MAIL_TO: Test User <user@domain.com> \
      MAIL_SUBJECT: Backup failed
      MAIL_BODY: |
        Backup for nextcloud app failed.
        Run "docker composer logs -f backup_cron" for more information
      SSH_KNOWN_HOSTS: your.server.net,38.26.55.241
    secrets:
      - backup_server_user_private_key
      - borg_passphrase
      - db_password

secrets:

  ...

  backup_server_user_private_key:
    file: secret_backup_server_user_private_key.txt
  borg_passphrase:
    file: secret_borg_passphrase.txt
  db_root_password:
    file: secret_db_root_password.txt
  db_password:
    file: secret_db_password.txt
```

Restoring backups
-----------------

To restore data:
1. Connect to the backup server
2. Use standard Borg commands:

```bash
borg list /path/to/repo
borg extract /path/to/repo::archive_name
```

Refer to the Borg documentation: https://borgbackup.readthedocs.io/

Reference links
---------------

This image relies on the following Ansible playbooks:

- Borg backup tasks: https://github.com/Ovski4/ansible-playbook-borg-backup.git
- MySQL dump creation: https://github.com/Ovski4/ansible-playbook-mysql-dump.git
- MongoDB dump creation: https://github.com/Ovski4/ansible-playbook-mongo-dump.git
- Elasticsearch snapshot creation: https://github.com/Ovski4/ansible-playbook-elasticsearch-snapshot.git
- SMTP email sending: https://github.com/Ovski4/ansible-playbook-smtp-email.git
