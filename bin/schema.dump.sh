#!/bin/bash -e
GIT_DIR=$(git rev-parse --show-toplevel)
CWD=$(pwd)
source $GIT_DIR/envfile.sh
cd $GIT_DIR

dbicdump -Ilib -o dump_directory=./lib -o use_moose=1 -o components='["InflateColumn::DateTime", "TimeStamp", "PassphraseColumn"]' -o overwrite_modifications=1 -o generate_pod=1 MandatoAberto::Schema "dbi:Pg:dbname=${POSTGRESQL_DBNAME};host=${POSTGRESQL_HOST}" $POSTGRESQL_USER $POSTGRESQL_PASSWORD

cd $CWD
