#!/usr/bin/env bash

if [ -d "script" ]; then
  cd script;
fi

source ../envfile.sh

perl mandatoaberto_create.pl model DB DBIC::Schema MandatoAberto::Schema create=static components=TimeStamp,PassphraseColumn 'dbi:Pg:dbname=mandatoaberto_dev;host=localhost' postgres trustable quote_names=1 overwrite_modifications=1

cd ..;

rm -f lib/MandatoAberto/Model/DB.pm.new;
rm -f t/model_DB.t;
rm -f t/model_DB.t.new;