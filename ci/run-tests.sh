#!/bin/bash
source ~/perl5/perlbrew/etc/bashrc
DIR=$(git rev-parse --show-toplevel)
cd $DIR
echo "doing cpanm --installdeps on $DIR"
cpanm Module::Install::Catalyst App::Sqitch App::ForkProve -n
cpanm -n --installdeps .
sqitch deploy -t $1
TRACE=1 forkprove -MDonm -j4  -lvr t/