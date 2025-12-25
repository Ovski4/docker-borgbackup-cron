Borg backup cron
================

A Docker image for periodic folder backups using Borg.

This image is designed to run alongside other containers and back up their data volumes on a scheduled basis. It works well with setups defined via docker-compose.yml or Docker Swarm stack.yml files.

Full tutorial can be read at https://baptiste.bouchereau.pro/tutorial/backup-docker-volumes-with-borg/.

Additionnally this image can:
* dump a mysql database in the same folder beforehand
* dump a mongo database
* create an elasticsearch snapshot
* send an email on failure

You can also run the cron job directly by overriding the command with `/var/backup_script.sh`

Table of contents
-----------------

- [Build](#build)
- [Usage](#usage)
  - [With mysql dump](#with-mysql-dump)
  - [With mongo dump](#with-mongo-dump)
  - [With elasticsearch snapshot](#with-elasticsearch-snapshot)
  - [Sending an email on failure](#sending-an-email-on-failure)
  - [Use secrets instead of env variables](#use-secrets-instead-of-env-variables)
  - [Example with docker compose](#example-with-docker-compose)

Build
-----

```
git clone https://github.com/Ovski4/docker-borgbackup-cron.git
cd docker-borgbackup-cron
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

### With mysql dump

```bash
docker run \
   # ... other options
   -e MYSQL_USER=myuser \
   -e MYSQL_DATABASE=mydbname \
   -e MYSQL_PASSWORD=mypass \
   -e MYSQL_HOST=mysql \
   ovski/borgbackup-cron
```

### With mongo dump

```bash
docker run \
   # ... other options
   -e MONGO_PORT=27017 \
   -e MONGO_DATABASE=my_mongo_dbname \
   -e MONGO_HOST=mongo \
   ovski/borgbackup-cron
```

### With elasticsearch snapshot

```bash
docker run \
   # ... other options
   -e ELASTICSEARCH_PORT=9200 \
   -e ELASTICSEARCH_HOST=elasticsearch \
   -e ELASTICSEARCH_REPOSITORY=backup \
   ovski/borgbackup-cron
```

### Sending an email on failure

```bash
docker run \
   # ... other options
   -e SMTP_USER=smtpuser@gmail.com \
   -e SMTP_PASSWORD=smtppassword \
   -e SMTP_PORT=465 \
   -e SMTP_HOST=smtp.gmail.com \
   -e MAIL_TO=Test User <user@domain.com> \
   -e MAIL_BODY="Email content" \
   -e MAIL_SUBJECT="Email subject" \
   ovski/borgbackup-cron
```

### Use secrets instead of env variables

You can also use secrets in a stack to store sensitive information.
Instead of specifiying environment variables, create the following secrets in /var/secrets (default location):

```
/run/secrets/borg_passphrase instead of BORG_PASSPHRASE
/run/secrets/db_password instead of MYSQL_PASSWORD
/run/secrets/smtp_password instead of SMTP_PASSWORD
```

### Example with docker compose

> Taking a nextcloud app as an example, here is an excerpt of a docker compose configuration that will backup nextcloud data and create a mysql dump as well.

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
