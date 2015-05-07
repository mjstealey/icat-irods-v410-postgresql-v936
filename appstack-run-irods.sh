#!/bin/bash

# appstack-run-irods.sh
# Author: Michael Stealey <michael.j.stealey@gmail.com>

echo "*** RUN SCRIPT appstack-run-irods.sh ***"

APPSTACK_PATH=${PWD}'/appstack'

echo "*** update github submodules ***"
git submodule init && git submodule update

# build data image
echo "*** docker build -t appstack-data . ***"
docker build -t appstack-data .

# build docker appstack images
${APPSTACK_PATH}/appstack-build.sh ${APPSTACK_PATH}

# Launch data volume as docker container data
echo "*** docker run appstack-data as data ***"
docker run --name data -v /srv/pgsql:/var/lib/pgsql/9.3/data -v /srv/irods:/var/lib/irods -v /etc/irods \
    -v /srv/log:/var/log -v /root/.secret -it -d appstack-data
sleep 1s

# Setup postgreql database
echo "*** docker run setup-postgresql-v9.3.6 ***"
docker run --rm --volumes-from data -it setup-postgresql-v9.3.6
sleep 1s

# Launch postgres database as docker container db
echo "*** docker run postgresql-v9.3.6 as db ***"
docker run -u postgres --name db --volumes-from data -d postgresql-v9.3.6
sleep 3s

# Setup irods environment
echo "*** docker run setup-irods-icat-v4.0.3 ***"
docker run --rm --volumes-from data --link db:db -it setup-irods-icat-v4.1.0
sleep 3s

# Lauch irods environment as docker container icat
echo "*** docker run irods-icat-v4.0.3 as icat ***"
docker run --volumes-from data --name icat --link db:db -d irods-icat-v4.1.0

echo "*** FINISHED SCRIPT appstack-run-irods.sh ***"