FROM code4sa/moodle-base:latest

MAINTAINER Code For South Africa <info@code4sa.org>

VOLUME ["/var/moodledata"]
EXPOSE 80
COPY moodle-config.php /var/www/html/config.php
RUN echo newrelic-php5 newrelic-php5/application-name string "Code4SA Learn Moodle" | \
    debconf-set-selections
ARG NEWRELIC_KEY=
RUN echo newrelic-php5 newrelic-php5/license-key string $NEWRELIC_KEY | \
    debconf-set-selections

RUN mkdir /app
COPY CHECKS /app/CHECKS

CMD ["/etc/apache2/foreground.sh"]
