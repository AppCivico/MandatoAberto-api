package MandatoAberto::Controller::API::Politician::VotoLegalIntegration;
use common::sense;
use Moose;
use namespace::autoclean;

use Furl;
use JSON::MaybeXS;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

with "CatalystX::Eta::Controller::AutoBase";
with 'CatalystX::Eta::Controller::AutoListPOST';

__PACKAGE__->config(
    # AutoBase.
    result => "DB::PoliticianVotolegalIntegration",

    # AutoListPOST
    prepare_params_for_create => sub {
        my ($self, $c, $params) = @_;

        my $furl = Furl->new();

        my $security_token = $ENV{VOTOLEGAL_SECURITY_TOKEN};
        die \['missing env', 'VOTOLEGAL_SECURITY_TOKEN'] unless $security_token;

        my $votolegal_email = $c->req->params->{votolegal_email};
        die \['votolegal_email', 'missing'] unless $votolegal_email;

        my $politician = $c->stash->{politician};

        my $res = $furl->post(
            $ENV{VOTOLEGAL_API_URL} . '/candidate/mandatoaberto_integration',
            [],
            {
                security_token   => $security_token,
                email            => $votolegal_email,
                mandatoaberto_id => $politician->id
            }
        );
        die $res->decoded_content unless $res->is_success;

        $res = decode_json $res->decoded_content;

        die \['invalid response', 'id'] if !$res->{id} || !$res->{username};

        $params->{politician_id} = $politician->id;
        $params->{votolegal_id}  = $res->{id};
        $params->{username}      = $res->{username};

        return $params;
    },
);

sub root : Chained('/api/politician/object') : PathPart('') : CaptureArgs(0) { }

sub base : Chained('root') : PathPart('votolegal-integration') : CaptureArgs(0) { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_POST { }

__PACKAGE__->meta->make_immutable;

1;

