#!/usr/bin/env bash

[ -z "$ENV" ] && ENV=dev
cp /srv/deployment/$ENV/nginx.conf /etc/nginx/nginx.conf
service nginx status &>/dev/null && service nginx restart || service nginx start

# Keep the container alive forever, overwriting old versions as new ones present themselves
while :; do
	diff /srv/deployment/$ENV/run.sh $0 &>/dev/null
	[ $? -eq 1 ] && cp /srv/deployment/$ENV/run.sh $0 && exec $0 $@
	
	sleep 30
done
