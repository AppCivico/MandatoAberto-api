#!/bin/bash
export PIDFILE=/tmp/start_server.pid;

cd /src;
source /home/app/perl5/perlbrew/etc/bashrc;
source envfile.sh;

if [ -e "$PIDFILE" ]; then
    kill -HUP $(cat $PIDFILE)
fi

pgrep -f MandatoAberto::Daemon::Emailsd | xargs kill -INT
pgrep -f MandatoAberto::Daemon::Segmenterd | xargs kill -INT