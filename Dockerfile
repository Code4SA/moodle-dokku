FROM code4sa/moodle-base:latest

MAINTAINER Code For South Africa <info@code4sa.org>

VOLUME ["/var/moodledata"]
EXPOSE 80
COPY moodle-config.php /var/www/html/config.php

CMD ["/etc/apache2/foreground.sh"]
