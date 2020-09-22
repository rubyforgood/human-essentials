#!/bin/bash

export RAILS_ROOT=/opt/diaper

cd /opt/diaper/bin
if [ "$1" = 'diaper' ]; then
    psql "${DATABASE_URL}" -c '\dt;' 2>&1 \
        | head -n1 \
        | grep -P "(Did not find|does not exist)" >/dev/null
    if [ $? -eq 0 ]; then
        bundle exec rails db:setup
    fi
    bundle exec rails server -p ${DIAPER_PORT} -b 0.0.0.0
else
    exec "$@"
fi
