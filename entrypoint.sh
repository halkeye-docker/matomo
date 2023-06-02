#!/bin/bash
set -e
set -x

envsubst < /config.ini.tmpl > /tmp/config.ini.php
while IFS=',' read -ra MATOMO_TRUSTED_HOSTS; do
	for i in "${MATOMO_TRUSTED_HOSTS[@]}"; do
		perl -pi -e "s{#trusted_hosts}{trusted_hosts[] = \"$i\"\n#trusted_hosts}g" /var/www/html/config/config.ini.php
	done
done <<< "$MATOMO_TRUSTED_HOSTS"
perl -pi -e '/#trusted_hosts/d' /tmp/config.ini.php
cat /tmp/config.ini.php > /var/www/html/config/config.ini.php
rm /tmp/config.ini.php

# dont let anyone write to it though
chmod 555 /var/www/html/config/config.ini.php

exec "$@"
