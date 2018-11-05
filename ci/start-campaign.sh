#!/bin/bash
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
source envfile.sh
perl script/daemon/Campaignsd start -f 1>>/data/log/campaign.log 2>>/data/log/campaign.error.log
