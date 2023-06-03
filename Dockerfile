FROM matomo:4.14.2-apache
LABEL org.opencontainers.image.description "Matomo, formerly Piwik, is the most common free and open source web analytics application to track online visits to one or more websites and display reports on these visits for analysis"

ENV MATOMO_DATABASE_ENABLE_SSL=0
ENV MATOMO_DATABASE_SSL_NO_VERIFY=0
ENV MATOMO_DATABASE_PORT_NUMBER=3306

env MATOMO_GENERAL_FORCE_SSL=0
env MATOMO_GENERAL_ASSUME_SECURE_PROTOCOL=0

RUN set -ex && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    libapache2-mod-geoip=1.2.10-1+b1 \
    gettext-base=0.21-4 \
    wget=1.21-1+deb11u1 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY download_plugins.sh entrypoint.sh /
RUN chmod 755 /entrypoint.sh /download_plugins.sh && \
  mkdir /plugins && \
  ROOTDIR=/ /download_plugins.sh && \
  perl -pi -e 's{VirtualHost *:80}{VirtualHost *:8080}g' /etc/apache2/sites-available/000-default.conf && \
  perl -pi -e 's{Listen 80}{Listen 8080}' /etc/apache2/ports.conf && \
  mkdir -p /var/www/html && \
  chown -R 1001:1001 /var/www/html

COPY config.ini.php /config.ini.tmpl

WORKDIR /var/www/html
RUN tar cf - --one-file-system -C /usr/src/matomo . | tar xf - -C /var/www/html && \
  chown -R 1001:1001 . && \
  mkdir -p /var/www/html/plugins/SecurityInfo && \
    tar xzf /plugins/plugin-*.tgz --strip-components 1 -C /var/www/html/plugins/SecurityInfo && \
  mkdir -p /var/www/html/plugins/LoginOIDC && \
    tar xzf /plugins/matomo-*.tgz --strip-components 1 -C /var/www/html/plugins/LoginOIDC && \
    mkdir -p /var/www/html/tmp/{assets,cache,logs,tcpdf,templates_c}/ && \
    find /var/www/html/tmp -type f -exec chmod 644 {} \; && \
    find /var/www/html/tmp -type d -exec chmod 755 {} \; && \
    find /var/www/html/tmp/{assets,cache,logs,tcpdf,templates_c}/ -type f -exec chmod 644 {} \; && \
    find /var/www/html/tmp/{assets,cache,logs,tcpdf,templates_c}/ -type d -exec chmod 755 {} \; && \
    cd /var/www/html/misc && ln -s /usr/share/GeoIP/GeoLite2-ASN.mmdb ./ && \
    cd /var/www/html/misc && ln -s /usr/share/GeoIP/GeoLite2-City.mmdb ./ && \
    cd /var/www/html/misc && ln -s /usr/share/GeoIP/GeoLite2-Country.mmdb ./
USER 1001
RUN touch config/config.ini.php; ./console core:create-security-files
