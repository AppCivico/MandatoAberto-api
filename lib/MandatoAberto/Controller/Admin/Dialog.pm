package MandatoAberto::Controller::Admin::Dialog;
use Mojo::Base 'MandatoAberto::Controller';

sub stasher {
    my $c = shift;

    my $dialog_id = $c->param('dialog_id');
    my $dialog = $c->schema->resultset('Dialog')->search( { 'me.id' => $dialog_id } )->next;
    if (!ref $dialog) {
        $c->reply_not_found;
        $c->detach();
    }
    $c->stash(dialog => $dialog);

    return $c;
}

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $params->{admin_id} = $c->current_user->id;

    my $dialog = $c->schema->resultset('Dialog')->execute(
        $c,
        for => 'create',
        with => $params,
    );

    return $c
    #->redirect_to('current')
    ->render(
        status => 201,
        json   => { id => $dialog->id },
    );
}

# with "CatalystX::Eta::Controller::AutoBase";
# with "CatalystX::Eta::Controller::AutoResultPUT";
# with "CatalystX::Eta::Controller::AutoResultGET";
# with "CatalystX::Eta::Controller::AutoListPOST";

# __PACKAGE__->config(
#     # AutoBase.
#     result => "DB::Dialog",

#     # AutoResultPUT.
#     object_key                => "dialog",
#     result_put_for            => "update",
#     prepare_params_for_update => sub {
#         my ($self, $c, $params) = @_;

#         $params->{admin_id} = $c->user->id;

#         return $params;
#     },

#     # AutoResultGET
#     build_row => sub { return { $_[0]->get_columns() } },

# sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
#     my ($self, $c, $dialog_id) = @_;

#     $c->stash->{collection} = $c->stash->{collection}->search( { id => $dialog_id } );

#     my $dialog = $c->stash->{collection}->find($dialog_id);
#     $c->detach("/error_404") unless ref $dialog;

#     $c->stash->{dialog} = $dialog;
# }

# sub list_GET {
#     my ($self, $c) = @_;

#     return $self->status_ok(
#         $c,
#         entity => {
#             $c->stash->{collection}->get_dialogs_with_data
#         }
#     )
# }

# sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

# sub result_PUT { }

# sub result_GET { }

1;