#!/bin/bash -e
if [ -d "bin" ]; then
  cd bin;
fi

GIT_DIR=$(git rev-parse --show-toplevel)
CWD=$(pwd)
source $GIT_DIR/envfile.sh
cd $GIT_DIR/bin

dbicdump -o dump_directory=../../lib -o components='["TimeStamp", "PassphraseColumn"]' -o overwrite_modifications=1 -o generate_pod=1 MandatoAberto::Schema "dbi:Pg:dbname=${POSTGRESQL_DBNAME};host=${POSTGRESQL_HOST}" $POSTGRESQL_USER $POSTGRESQL_PASSWORD

cd $CWD
