#!/bin/bash
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
source envfile.sh
perl script/daemon/Segmenterd start -f 1>>/data/log/segmenter.log 2>>/data/log/segmenter.error.log