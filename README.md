# Dockerfiles for moodle base image and dokku Dockerfile deploy

Set up the database according to https://docs.moodle.org/31/en/PostgreSQL

# Upgrading

Moodle automatically checks for upgrades and informs users of available upgrades on the website.

To upgrade:

1. Backup files
  - `ubuntu@dokku6:~$ sudo tar -czf moodle_files_2017-01-24.tgz /var/moodle`
  - `robin:~$ scp ubuntu@dokku6.code4sa.org:moodle_files_2017-01-24.tgz .`
  - Upload the backup to Google Drive
1. Backup the database
  - Our database is snapshotted nightly but it's nice to have an easy-to-restore copy at hand during an upgrade to minimise effort and downtime.
  - Note moodle uses hundreds of tables and indices - it will take over 10 minutes for it to even start outputting data. Wait. Relax. Go get some coffee. Keep an eye on it. Check that it's all ok at the end.
  - `pg_dump "postgres://moodle:...@postgresql94-prod.cnc362bhpvfe.eu-west-1.rds.amazonaws.com/moodle" -O -c --if-exists|gzip > prod_2017-01-24.sql.gz`
1. [Rebuild the base docker image](https://hub.docker.com/r/code4sa/moodle-base/~/settings/automated-builds/) which will download the latest minor version of the major version currently selected by Dockerfile-base.
2. Pull the latest base image on the app server
  - `ubuntu@dokku6:~$ docker pull code4sa/moodle-base:latest`
3. Rebuild the app image on the app server
  - `ubuntu@dokku6:~$ dokku ps:rebuild moodle`
4. Visit the site, login as Admin, follow the database upgrade instructions
5. Check that everything looks ok.

## Building base image

This image is usually built by docker hub and pulled by the dokku host. You don't usually need to build it yourself.

```shell
docker build -t code4sa/moodle-deps-base:latest -f Dockerfile-deps-base .
docker build -t code4sa/moodle-base:latest -f Dockerfile-base .
```

## Building app image for local testing

```shell
docker build -t code4sa/moodle-dokku:latest -f Dockerfile --build-arg NEWRELIC_KEY=... .
```

## Run locally

```shell
docker run -i --net=host -v `pwd`/moodledata:/var/moodledata --name=moodle code4s/moodle-dokku:latest
```

### Restart a previously-run container

docker start -i moodle

Visit it at http://localhost/

## Deploy to production

Moodle is deployed to dokku using "Dockerfile deployment". As usual, we push this repository to dokku. Dokku will see the Dockerfile and build it to create the app image and start the container as usual. This Dockerfile depends on a base image code4sa/moodle-base which we usually [build on Docker Hub](https://hub.docker.com/r/code4sa/moodle-base/~/settings/automated-builds/).

Add remote to your local repo

    git remote add dokku dokku@dokku6.code4sa.org:moodle

Configure environment variables and options on server, replacing ... with appropriate values

```
dokku config:set moodle \
      DB_HOST=postgresql94-prod.cnc362bhpvfe.eu-west-1.rds.amazonaws.com \
      DB_NAME=moodle \
      DB_USER=moodle \
      DB_PASSWORD=... \
      MOODLE_URL=https://learn.code4sa.org
dokku docker-options:add moodle build,run,deploy "-v /var/log/moodle/apache2:/var/log/apache2"
dokku docker-options:add moodle build,run,deploy "-v /var/moodle/:/var/moodledata"
dokku docker-options:add moodle build "--build-arg NEWRELIC_KEY=..."
dokku proxy:ports-add moodle http:80:80
```

If the base image has been updated, ensure the latest image is on the host

    ubuntu@dokku6:~$ docker pull code4sa/moodle-base:latest

Push any config/dockerfile updates to dokku. Dokku will build an image based on Dockerfile.

    git push dokku master

## Configure Cron

*/1 * * * * dokku --rm run  moodle /usr/bin/php /var/www/html/admin/cli/cron.php > /dev/null