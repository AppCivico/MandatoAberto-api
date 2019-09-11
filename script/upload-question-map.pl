#!/usr/bin/env perl
use common::sense;
use Text::CSV;
use JSON;

use MandatoAberto::SchemaConnected qw(get_schema);

my $schema = get_schema();

my $question_rs     = $schema->resultset('QuestionnaireQuestion');
my $question_map_rs = $schema->resultset('QuestionnaireMap');

my $csv = Text::CSV->new( { binary => 1, auto_diag => 1 } );

my @rows;
my $question_map;
my $i = 1;

#########################################
# ALWAYS UPDATE THIS NUMBER ACCORDINGLY #
#########################################
my $version = 1;

open my $fh, "<:encoding(utf8)", "quiz.csv" or die "screening.csv: $!";
while (my $row = $csv->getline($fh)) {
    next if $row->[0] eq 'code';

    my $row = {
        code              => $row->[0],
        text              => $row->[1],
        type              => $row->[2],
        questionnaire_map_id => $version,

        (
            $row->[2] eq 'multiple_choice' ?
                ( multiple_choices => $row->[3] ) : ( )
        ),
        (
            $row->[4] ?
                ( extra_quick_replies => $row->[4] ) : ( )
        ),
        (
            $row->[5] ?
                ( rules => $row->[5] ) :
                ( )
        )
    };

    push @rows, $row;

    $question_map->{$i} = $row->{code};
    $i++;
}
close $fh;

$question_map_rs->create(
    {
        map         => to_json($question_map),
        type_id => 1
    }
);
$question_rs->populate(\@rows);
