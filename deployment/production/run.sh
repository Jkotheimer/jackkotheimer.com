#!/usr/bin/env bash

cp /srv/deployment/production/nginx.conf /etc/nginx/nginx.conf
service nginx status &>/dev/null && service nginx restart || service nginx start

# Keep the container alive forever, overwriting old versions as new ones present themselves
while :; do
	diff /srv/deployment/production/run.sh $0 &>/dev/null
	[ $? -eq 1 ] && cp /srv/deployment/production/run.sh $0 && exec $0 $@
	
	sleep 30
done
