#!/bin/bash
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
source envfile.sh
perl script/daemon/PollNotificationd start -f 1>>/data/log/pollnotification.log 2>>/data/log/pollnotification.error.log
