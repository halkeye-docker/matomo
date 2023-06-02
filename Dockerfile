FROM matomo:4.14.2-apache
LABEL org.opencontainers.image.description "Matomo, formerly Piwik, is the most common free and open source web analytics application to track online visits to one or more websites and display reports on these visits for analysis"

ENV MATOMO_DATABASE_ENABLE_SSL=0
ENV MATOMO_DATABASE_SSL_NO_VERIFY=0

RUN set -ex && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    gettext-base=0.21-4 \
    wget=1.21-1+deb11u1 && \
  apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY download_plugins.sh entrypoint.sh /
RUN chmod 755 /entrypoint.sh /download_plugins.sh && \
  mkdir /plugins && \
  ROOTDIR=/ /download_plugins.sh && \
	tar cf - --one-file-system -C /usr/src/matomo . | tar xf - && \
	chown -R www-data:www-data . && \
	mkdir -p /var/www/html/plugins/SecurityInfo && \
    tar xzf /plugins/plugin-*.tgz --strip-components 1 -C /var/www/html/plugins/SecurityInfo && \
	mkdir -p /var/www/html/plugins/LoginOIDC && \
    tar xzf /plugins/matomo-*.tgz --strip-components 1 -C /var/www/html/plugins/LoginOIDC

COPY config.ini.php /config.ini.tmpl

