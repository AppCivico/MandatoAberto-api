package MandatoAberto::Controller::Politician::Contact;
use Mojo::Base 'Mojolicious::Controller';

# __PACKAGE__->config(
#     # AutoBase.
#     result => "DB::PoliticianContact",

#     list_key  => "politician_contact",
#     build_row => sub {
#         return { $_[0]->get_columns() };
#     },

#     prepare_params_for_create => sub {
#         my ($self, $c, $params) = @_;

#         $params->{politician_id} = $c->current_user->id;

#         return $params;
#     },
# );

sub post {
    my $c = shift;

    my $politician_contact = $c->schema->resultset('PoliticianContact')->execute(
        $c,
        for  => "create",
        with => {
            %{ $c->req->params->to_hash },
            politician_id => $c->current_user->id,
        },
    );

    $politician_contact->id;

    return $c->render(
        json => {
            id        => $politician_contact->id,
            facebook  => $politician_contact->facebook,
            twitter   => $politician_contact->twitter,
            cellphone => $politician_contact->cellphone,
            email     => $politician_contact->email,
            instagram => $politician_contact->instagram
        },
        status => 200,
    );
}

sub list_GET {
    my ($self, $c) = @_;

    my $politician = $c->stash->{politician};

    return $self->status_ok(
        $c,
        entity => {
            politician_contact => {
                politician_id => $politician->id,

                map {
                    my $c = $_;
                    id        => $c->get_column('id'),
                    facebook  => $c->get_column('facebook'),
                    twitter   => $c->get_column('twitter'),
                    email     => $c->get_column('email'),
                    cellphone => $c->get_column('cellphone'),
                    url       => $c->get_column('url'),
                    instagram => $c->get_column('instagram')
                } $politician->politician_contacts->all()
            }
        }
    );
}

1;
