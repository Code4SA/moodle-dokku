# Dockerfiles for moodle base image and dokku Dockerfile deploy

Set up the database according to https://docs.moodle.org/31/en/PostgreSQL

## Building base image

This image is usually built by docker hub and pulled by the dokku host. You don't usually need to build it yourself.

```shell
docker build -t moodle-base:latest -f Dockerfile-base .
```

## Building app image for local testing

Note if you want to use a locally-built base image you should change the FROM statement in `Dockerfile`

```shell
docker build -t moodle-dokku:latest -f Dockerfile .
```

## Run locally

```shell
docker run -i --net=host -v `pwd`/moodledata:/var/moodledata --name=moodle moodle-dokku:latest
```

### Restart a previously-run container

docker start -i moodle

Visit it at http://localhost/

## Deploy to production

Add remote to your local repo

    git remote add dokku dokku@dokku6.code4sa.org:moodle

Configure environment variables on server

```
dokku config:set moodle \
      DB_HOST=postgresql94-prod.cnc362bhpvfe.eu-west-1.rds.amazonaws.com \
      DB_NAME=moodle \
      DB_USER=moodle \
      DB_PASSWORD=... \
      MOODLE_URL=http://learn.code4sa.org
dokku docker-options:add moodle build,run,deploy "-v /var/log/moodle/apache2:/var/log/apache2"
dokku docker-options:add moodle build,run,deploy "-v /var/moodle/:/var/moodledata"
dokku proxy:ports-add moodle http:80:80
```

Push any config/dockerfile updates to dokku. Dokku will build an image based on Dockerfile.

    git push dokku master
