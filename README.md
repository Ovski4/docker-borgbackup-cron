Borg backup cron
=================

A docker image to backup periodically a folder using borg.
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
   -e MAIL_TO=user@recipient.com \
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
