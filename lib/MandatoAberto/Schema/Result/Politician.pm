use utf8;
package MandatoAberto::Schema::Result::Politician;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::Politician

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<politician>

=cut

__PACKAGE__->table("politician");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 party_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 office_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 fb_page_id

  data_type: 'text'
  is_nullable: 1

=head2 fb_page_access_token

  data_type: 'text'
  is_nullable: 1

=head2 gender

  data_type: 'text'
  is_nullable: 0

=head2 address_state_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 address_city_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 premium

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 premium_updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 picframe_url

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "party_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "office_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "fb_page_id",
  { data_type => "text", is_nullable => 1 },
  "fb_page_access_token",
  { data_type => "text", is_nullable => 1 },
  "gender",
  { data_type => "text", is_nullable => 0 },
  "address_state_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "address_city_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "premium",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "premium_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "picframe_url",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 RELATIONS

=head2 address_city

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::City>

=cut

__PACKAGE__->belongs_to(
  "address_city",
  "MandatoAberto::Schema::Result::City",
  { id => "address_city_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 address_state

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::State>

=cut

__PACKAGE__->belongs_to(
  "address_state",
  "MandatoAberto::Schema::Result::State",
  { id => "address_state_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 answers

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Answer>

=cut

__PACKAGE__->has_many(
  "answers",
  "MandatoAberto::Schema::Result::Answer",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 direct_messages

Type: has_many

Related object: L<MandatoAberto::Schema::Result::DirectMessage>

=cut

__PACKAGE__->has_many(
  "direct_messages",
  "MandatoAberto::Schema::Result::DirectMessage",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 groups

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Group>

=cut

__PACKAGE__->has_many(
  "groups",
  "MandatoAberto::Schema::Result::Group",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issues

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issues",
  "MandatoAberto::Schema::Result::Issue",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 office

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Office>

=cut

__PACKAGE__->belongs_to(
  "office",
  "MandatoAberto::Schema::Result::Office",
  { id => "office_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 party

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Party>

=cut

__PACKAGE__->belongs_to(
  "party",
  "MandatoAberto::Schema::Result::Party",
  { id => "party_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 politician_chatbot_conversations

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianChatbotConversation>

=cut

__PACKAGE__->has_many(
  "politician_chatbot_conversations",
  "MandatoAberto::Schema::Result::PoliticianChatbotConversation",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politician_contacts

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianContact>

=cut

__PACKAGE__->has_many(
  "politician_contacts",
  "MandatoAberto::Schema::Result::PoliticianContact",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politician_private_reply_config

Type: might_have

Related object: L<MandatoAberto::Schema::Result::PoliticianPrivateReplyConfig>

=cut

__PACKAGE__->might_have(
  "politician_private_reply_config",
  "MandatoAberto::Schema::Result::PoliticianPrivateReplyConfig",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politician_votolegal_integrations

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianVotolegalIntegration>

=cut

__PACKAGE__->has_many(
  "politician_votolegal_integrations",
  "MandatoAberto::Schema::Result::PoliticianVotolegalIntegration",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 politicians_greeting

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianGreeting>

=cut

__PACKAGE__->has_many(
  "politicians_greeting",
  "MandatoAberto::Schema::Result::PoliticianGreeting",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_propagates

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PollPropagate>

=cut

__PACKAGE__->has_many(
  "poll_propagates",
  "MandatoAberto::Schema::Result::PollPropagate",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 polls

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Poll>

=cut

__PACKAGE__->has_many(
  "polls",
  "MandatoAberto::Schema::Result::Poll",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 private_replies

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PrivateReply>

=cut

__PACKAGE__->has_many(
  "private_replies",
  "MandatoAberto::Schema::Result::PrivateReply",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 recipients

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Recipient>

=cut

__PACKAGE__->has_many(
  "recipients",
  "MandatoAberto::Schema::Result::Recipient",
  { "foreign.politician_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "MandatoAberto::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-06-13 17:37:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BSbvdI3L0lnI0CguI18+iw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

with 'MandatoAberto::Role::Verification';
with 'MandatoAberto::Role::Verification::TransactionalActions::DBIC';

use MandatoAberto::Utils;
use Furl;
use JSON::MaybeXS;
use HTTP::Request;
use IO::Socket::SSL;
use DateTime;
use DateTime::Format::DateParse;
use MandatoAberto::Types qw/URI/;

sub verifiers_specs {
    my $self = shift;

    return {
        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                name => {
                    required => 0,
                    type     => "Str",
                },
                address_state_id => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $address_state_id = $_[0]->get_value('address_state_id');
                        $self->result_source->schema->resultset("State")->search({ id => $address_state_id })->count;
                    },
                },
                address_city_id => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $address_city_id  = $_[0]->get_value('address_city_id');
                        my $address_state_id = $_[0]->get_value('address_state_id');

                        $self->result_source->schema->resultset("City")->search( { id => $address_city_id} )->count;
                    },
                },
                party_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $party_id = $_[0]->get_value('party_id');
                        $self->result_source->schema->resultset("Party")->search({ id => $party_id })->count;
                    }
                },
                office_id => {
                    required   => 0,
                    type       => "Int",
                    post_check => sub {
                        my $office_id = $_[0]->get_value('office_id');
                        $self->result_source->schema->resultset("Office")->search({ id => $office_id })->count;
                    }
                },
                fb_page_id => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $fb_page_id = $_[0]->get_value('fb_page_id');
                        $self->result_source->schema->resultset("Politician")->search( { fb_page_id => $fb_page_id } )->count and die \["fb_page_id", "alredy exists"];

                        return 1;
                    }
                },
                fb_page_access_token => {
                    required   => 0,
                    type       => "Str",
                    post_check => sub {
                        my $fb_page_access_token = $_[0]->get_value('fb_page_access_token');
                        $self->result_source->schema->resultset("Politician")->search( { fb_page_access_token => $fb_page_access_token } )->count and die \["fb_page_access_token", "alredy exists"];

                        return 1;
                    }
                },
                new_password => {
                    required => 0,
                    type     => "Str"
                },
                private_reply_activated => {
                    required => 0,
                    type     => "Bool"
                },
                picframe_url => {
                    required => 0,
                    type     => URI
                },
            }
        ),
    };
}

sub action_specs {
    my ($self) = @_;

    return {
        update => sub {
            my $r = shift;

            my %values = $r->valid_values;
            not defined $values{$_} and delete $values{$_} for keys %values;

            if ($values{address_city_id} && !$values{address_state_id}) {
                my $address_state = $self->address_state_id;

                my $new_address_city_id = $self->result_source->schema->resultset("City")->search(
                    {
                        'me.id'    => $values{address_city_id},
                        'state.id' => $address_state
                    },
                    { prefetch => 'state' }
                )->count;

                die \["address_city_id", "city does not belong to state id: $address_state"] unless $new_address_city_id;
            }

            if ( ( $values{address_state_id} && !$values{address_city_id} ) ) {
                die \["address_city_id", 'missing'];
            }

            if ($values{new_password} && length $values{new_password} < 6) {
                die \["new_password", "must have at least 6 characters"];
            }

            if ($values{fb_page_access_token}) {
                # O access token gerado pela primeira vez é o de vida curta
                # portanto devo pegar o mesmo e gerar um novo token de vida longa
                # API do Facebook: https://developers.facebook.com/docs/facebook-login/access-tokens/expiration-and-extension
                my $short_lived_token = $values{fb_page_access_token};
                $values{fb_page_access_token} = $self->get_long_lived_access_token($short_lived_token);

                # Setando o botão get started
                $self->set_get_started_button_and_persistent_menu($values{fb_page_access_token});
            }

            if ( exists $values{private_reply_activated} ) {
                my $private_reply_activated = delete $values{private_reply_activated};

                $self->politician_private_reply_config->update( { active => $private_reply_activated } );
            }

            # Caso ocorra mudança no fb_page_id e o político possuir integração do voto legal
            # devo avisar o novo page_id ao voto legal
            if ( $values{fb_page_id} && $self->has_votolegal_integration() ) {
                $self->politician_votolegal_integrations->next->update_votolegal_integration();
            }

            $self->user->update( { password => $values{new_password} } ) and delete $values{new_password} if $values{new_password};

            $self->update(\%values);
        }
    };
}

sub get_long_lived_access_token {
    my $short_lived_token = $_[1];

    if (is_test()) {
        return 1;
    }

    my $furl = Furl->new();

    my $url = $ENV{FB_API_URL} . "/oauth/access_token?grant_type=fb_exchange_token&client_id=$ENV{FB_APP_ID}&client_secret=$ENV{FB_APP_SECRET}&fb_exchange_token=$short_lived_token";

    my $res = $furl->get($url);
    die $res->decoded_content unless $res->is_success;

    my $decoded_res = decode_json $res->decoded_content;
    my $long_lived_access_token = $decoded_res->{access_token};
    die $decoded_res unless $long_lived_access_token;

    return $long_lived_access_token;
}

sub set_get_started_button_and_persistent_menu {
    my $access_token = $_[1];

    if (is_test()) {
        return 1;
    }

    my $furl = Furl->new();

    my $url = "https://graph.facebook.com/v2.6/me/messenger_profile?access_token=$access_token";

    my $res = $furl->post(
        $url,
        [ 'Content-Type' => "application/json" ],
        encode_json {
            get_started => {
                payload => 'greetings'
            },
            persistent_menu => [
                {
                    locale                  => 'default',
                    composer_input_disabled => 'false',
                    call_to_actions         => [
                        {
                            title   => "Ir para o início",
                            type    => 'postback',
                            payload => 'greetings'
                        }
                    ]
                }
            ]
        }
    );
    return 0 unless $res->is_success;

    return decode_json $res->decoded_content;
}

sub get_citizen_interaction {
    my ($self, $range) = @_;

    if (is_test()) {
        return 1;
    }

    my $page_id      = $self->fb_page_id;
    my $access_token = $self->fb_page_access_token;

    my $furl = Furl->new();

    my $start_date = DateTime->now->subtract( days => $range );
    my $end_date   = DateTime->now;

    my $start_date_epoch = $start_date->epoch();
    my $end_date_epoch   = $end_date->epoch();

    my $res = $furl->get(
        $ENV{FB_API_URL} . "/$page_id/insights?access_token=$access_token&metric=page_messages_active_threads_unique&since=$start_date_epoch&until=$end_date_epoch",
    );
    return 0 unless $res->is_success;

    my $decoded_res    = decode_json $res->decoded_content;
    my $untreated_data = $decoded_res->{data}->[0]->{values};

    # Setando o título e subtítulo do gráfico
    my $treated_data = {
        title    => 'Acessos por dia',
        subtitle => "Gráfico de acessos únicos por dia"
    };

    if ($untreated_data) {
        for (my $i = 0; $i < scalar @{ $untreated_data } ; $i++) {
            my $data_per_day = $untreated_data->[$i];

            my $day = DateTime::Format::DateParse->parse_datetime($data_per_day->{end_time});

            $treated_data->{labels}->[$i] = $day->day() . '/' . $day->month();
            $treated_data->{data}->[$i]   = $data_per_day->{value};
        }
    } else {
        # Caso não retorne nada do Facebook devo retornar um gráfico
        # com os gráficos em 0 para o range determinado.
        for (my $j = 0; $j < $range; $j++) {

            my $day = $start_date->add( days => 1 );

            $treated_data->{labels}->[$j] = $day->day() . '/' . $day->month();
            $treated_data->{data}->[$j]   = 0;
        }
    }

    # Forçando métricas para a conta de demonstração
    if ($self->id == 255) {
        $treated_data->{data} = [132, 167, 89, 178, 246, 359, 478];
    }

    return $treated_data;
}

sub get_current_facebook_page {
    my ($self) = @_;

    if (is_test()) {
        return 1;
    }

    my $furl = Furl->new();

    my $page_id      = $self->fb_page_id;
    my $access_token = $self->fb_page_access_token;

    my $res = $furl->get(
        $ENV{FB_API_URL} . "/me?fields=id,name,picture.type(large)&access_token=$access_token",
    );
    return 0 unless $res->is_success;

    return decode_json $res->decoded_content;
}

sub send_greetings_email {
    my ($self) = @_;

    my $email = MandatoAberto::Mailer::Template->new(
        to       => $self->user->email,
        from     => 'no-reply@mandatoaberto.com.br',
        subject  => "Mandato Aberto - Como o Mandato Aberto trabalha a seu favor?",
        template => get_data_section('greetings.tt'),
    )->build_email();

    return $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
}

sub send_premium_activated_email {
    my ($self) = @_;

    my $email = MandatoAberto::Mailer::Template->new(
        to       => $self->user->email,
        from     => 'no-reply@mandatoaberto.com.br',
        subject  => "Mandato Aberto - Mensagens diretas habilitadas",
        template => get_data_section('premium-active.tt'),
        vars     => {
            name  => $self->name,
        },
    )->build_email();

    return $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
}

sub send_premium_deactivated_email {
    my ($self) = @_;

    my $email = MandatoAberto::Mailer::Template->new(
        to       => $self->user->email,
        from     => 'no-reply@mandatoaberto.com.br',
        subject  => "Mandato Aberto - Mensagens diretas desativadas",
        template => get_data_section('premium-inactive.tt'),
        vars     => {
            name  => $self->name,
        },
    )->build_email();

    return $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
}

sub activate_premium {
    my ($self) = @_;

    $self->send_premium_activated_email();

    return $self->update(
        {
            premium            => 1,
            premium_updated_at => \'NOW()'
        }
    );
}

sub deactivate_premium {
    my ($self) = @_;

    $self->send_premium_deactivated_email();

    return $self->update(
        {
            premium            => 0,
            premium_updated_at => \'NOW()'
        }
    );
}

sub get_current_pendency {
    my ($self) = @_;

    my $approved = $self->user->approved;
    my $premium  = $self->premium;

    if ( !$approved ) {
        return 'Pendente aprovação';
    }
    elsif ( $approved && !$premium ) {
        return 'Premium não ativado';
    }
    else {
        return 'Sem pendências';
    }
}

sub send_new_register_email {
    my ($self) = @_;

    my $email = MandatoAberto::Mailer::Template->new(
        to       => 'contato@appcivico.com',
        from     => 'no-reply@mandatoaberto.com.br',
        subject  => "Mandato Aberto - Novo cadastro",
        template => get_data_section('new-register.tt'),
        vars     => {
            email         => $self->user->email,
            name          => $self->name,
            gender        => $self->gender,
            office        => $self->office->name,
            party         => $self->party->name,
            address_state => $self->address_state,
            address_city  => $self->address_city,
        },
    )->build_email();

    return $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
}

sub has_votolegal_integration {
    my ($self) = @_;

    return $self->politician_votolegal_integrations->count > 0 ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ greetings.tt

<!doctype html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
    <head>
        <!-- NAME: 1 COLUMN - FULL WIDTH -->
        <!--[if gte mso 15]>
        <xml>
            <o:OfficeDocumentSettings>
            <o:AllowPNG/>
            <o:PixelsPerInch>96</o:PixelsPerInch>
            </o:OfficeDocumentSettings>
        </xml>
        <![endif]-->
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Como o Mandato Aberto trabalha ao seu favor</title>

    <style type="text/css">
        p{
            margin:10px 0;
            padding:0;
        }
        table{
            border-collapse:collapse;
        }
        h1,h2,h3,h4,h5,h6{
            display:block;
            margin:0;
            padding:0;
        }
        img,a img{
            border:0;
            height:auto;
            outline:none;
            text-decoration:none;
        }
        body,#bodyTable,#bodyCell{
            height:100%;
            margin:0;
            padding:0;
            width:100%;
        }
        .mcnPreviewText{
            display:none !important;
        }
        #outlook a{
            padding:0;
        }
        img{
            -ms-interpolation-mode:bicubic;
        }
        table{
            mso-table-lspace:0pt;
            mso-table-rspace:0pt;
        }
        .ReadMsgBody{
            width:100%;
        }
        .ExternalClass{
            width:100%;
        }
        p,a,li,td,blockquote{
            mso-line-height-rule:exactly;
        }
        a[href^=tel],a[href^=sms]{
            color:inherit;
            cursor:default;
            text-decoration:none;
        }
        p,a,li,td,body,table,blockquote{
            -ms-text-size-adjust:100%;
            -webkit-text-size-adjust:100%;
        }
        .ExternalClass,.ExternalClass p,.ExternalClass td,.ExternalClass div,.ExternalClass span,.ExternalClass font{
            line-height:100%;
        }
        a[x-apple-data-detectors]{
            color:inherit !important;
            text-decoration:none !important;
            font-size:inherit !important;
            font-family:inherit !important;
            font-weight:inherit !important;
            line-height:inherit !important;
        }
        .templateContainer{
            max-width:600px !important;
        }
        a.mcnButton{
            display:block;
        }
        .mcnImage,.mcnRetinaImage{
            vertical-align:bottom;
        }
        .mcnTextContent{
            word-break:break-word;
        }
        .mcnTextContent img{
            height:auto !important;
        }
        .mcnDividerBlock{
            table-layout:fixed !important;
        }
    /*
    @tab Page
    @section Background Style
    @tip Set the background color and top border for your email. You may want to choose colors that match your company's branding.
    */
        body,#bodyTable{
            /*@editable*/background-color:#FAFAFA;
        }
    /*
    @tab Page
    @section Background Style
    @tip Set the background color and top border for your email. You may want to choose colors that match your company's branding.
    */
        #bodyCell{
            /*@editable*/border-top:0;
        }
    /*
    @tab Page
    @section Heading 1
    @tip Set the styling for all first-level headings in your emails. These should be the largest of your headings.
    @style heading 1
    */
        h1{
            /*@editable*/color:#202020;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:26px;
            /*@editable*/font-style:normal;
            /*@editable*/font-weight:bold;
            /*@editable*/line-height:125%;
            /*@editable*/letter-spacing:normal;
            /*@editable*/text-align:left;
        }
    /*
    @tab Page
    @section Heading 2
    @tip Set the styling for all second-level headings in your emails.
    @style heading 2
    */
        h2{
            /*@editable*/color:#202020;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:22px;
            /*@editable*/font-style:normal;
            /*@editable*/font-weight:bold;
            /*@editable*/line-height:125%;
            /*@editable*/letter-spacing:normal;
            /*@editable*/text-align:left;
        }
    /*
    @tab Page
    @section Heading 3
    @tip Set the styling for all third-level headings in your emails.
    @style heading 3
    */
        h3{
            /*@editable*/color:#202020;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:20px;
            /*@editable*/font-style:normal;
            /*@editable*/font-weight:bold;
            /*@editable*/line-height:125%;
            /*@editable*/letter-spacing:normal;
            /*@editable*/text-align:left;
        }
    /*
    @tab Page
    @section Heading 4
    @tip Set the styling for all fourth-level headings in your emails. These should be the smallest of your headings.
    @style heading 4
    */
        h4{
            /*@editable*/color:#202020;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:18px;
            /*@editable*/font-style:normal;
            /*@editable*/font-weight:bold;
            /*@editable*/line-height:125%;
            /*@editable*/letter-spacing:normal;
            /*@editable*/text-align:left;
        }
    /*
    @tab Preheader
    @section Preheader Style
    @tip Set the background color and borders for your email's preheader area.
    */
        #templatePreheader{
            /*@editable*/background-color:#FAFAFA;
            /*@editable*/background-image:none;
            /*@editable*/background-repeat:no-repeat;
            /*@editable*/background-position:center;
            /*@editable*/background-size:cover;
            /*@editable*/border-top:0;
            /*@editable*/border-bottom:0;
            /*@editable*/padding-top:9px;
            /*@editable*/padding-bottom:9px;
        }
    /*
    @tab Preheader
    @section Preheader Text
    @tip Set the styling for your email's preheader text. Choose a size and color that is easy to read.
    */
        #templatePreheader .mcnTextContent,#templatePreheader .mcnTextContent p{
            /*@editable*/color:#656565;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:12px;
            /*@editable*/line-height:150%;
            /*@editable*/text-align:left;
        }
    /*
    @tab Preheader
    @section Preheader Link
    @tip Set the styling for your email's preheader links. Choose a color that helps them stand out from your text.
    */
        #templatePreheader .mcnTextContent a,#templatePreheader .mcnTextContent p a{
            /*@editable*/color:#656565;
            /*@editable*/font-weight:normal;
            /*@editable*/text-decoration:underline;
        }
    /*
    @tab Header
    @section Header Style
    @tip Set the background color and borders for your email's header area.
    */
        #templateHeader{
            /*@editable*/background-color:#FFFFFF;
            /*@editable*/background-image:none;
            /*@editable*/background-repeat:no-repeat;
            /*@editable*/background-position:center;
            /*@editable*/background-size:cover;
            /*@editable*/border-top:0;
            /*@editable*/border-bottom:0;
            /*@editable*/padding-top:9px;
            /*@editable*/padding-bottom:0;
        }
    /*
    @tab Header
    @section Header Text
    @tip Set the styling for your email's header text. Choose a size and color that is easy to read.
    */
        #templateHeader .mcnTextContent,#templateHeader .mcnTextContent p{
            /*@editable*/color:#202020;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:16px;
            /*@editable*/line-height:150%;
            /*@editable*/text-align:left;
        }
    /*
    @tab Header
    @section Header Link
    @tip Set the styling for your email's header links. Choose a color that helps them stand out from your text.
    */
        #templateHeader .mcnTextContent a,#templateHeader .mcnTextContent p a{
            /*@editable*/color:#2BAADF;
            /*@editable*/font-weight:normal;
            /*@editable*/text-decoration:underline;
        }
    /*
    @tab Body
    @section Body Style
    @tip Set the background color and borders for your email's body area.
    */
        #templateBody{
            /*@editable*/background-color:#FFFFFF;
            /*@editable*/background-image:none;
            /*@editable*/background-repeat:no-repeat;
            /*@editable*/background-position:center;
            /*@editable*/background-size:cover;
            /*@editable*/border-top:0;
            /*@editable*/border-bottom:0;
            /*@editable*/padding-top:9px;
            /*@editable*/padding-bottom:9px;
        }
    /*
    @tab Body
    @section Body Text
    @tip Set the styling for your email's body text. Choose a size and color that is easy to read.
    */
        #templateBody .mcnTextContent,#templateBody .mcnTextContent p{
            /*@editable*/color:#202020;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:16px;
            /*@editable*/line-height:150%;
            /*@editable*/text-align:left;
        }
    /*
    @tab Body
    @section Body Link
    @tip Set the styling for your email's body links. Choose a color that helps them stand out from your text.
    */
        #templateBody .mcnTextContent a,#templateBody .mcnTextContent p a{
            /*@editable*/color:#2BAADF;
            /*@editable*/font-weight:normal;
            /*@editable*/text-decoration:underline;
        }
    /*
    @tab Footer
    @section Footer Style
    @tip Set the background color and borders for your email's footer area.
    */
        #templateFooter{
            /*@editable*/background-color:#FAFAFA;
            /*@editable*/background-image:none;
            /*@editable*/background-repeat:no-repeat;
            /*@editable*/background-position:center;
            /*@editable*/background-size:cover;
            /*@editable*/border-top:0;
            /*@editable*/border-bottom:0;
            /*@editable*/padding-top:9px;
            /*@editable*/padding-bottom:9px;
        }
    /*
    @tab Footer
    @section Footer Text
    @tip Set the styling for your email's footer text. Choose a size and color that is easy to read.
    */
        #templateFooter .mcnTextContent,#templateFooter .mcnTextContent p{
            /*@editable*/color:#656565;
            /*@editable*/font-family:Helvetica;
            /*@editable*/font-size:12px;
            /*@editable*/line-height:150%;
            /*@editable*/text-align:center;
        }
    /*
    @tab Footer
    @section Footer Link
    @tip Set the styling for your email's footer links. Choose a color that helps them stand out from your text.
    */
        #templateFooter .mcnTextContent a,#templateFooter .mcnTextContent p a{
            /*@editable*/color:#656565;
            /*@editable*/font-weight:normal;
            /*@editable*/text-decoration:underline;
        }
    @media only screen and (min-width:768px){
        .templateContainer{
            width:600px !important;
        }

}   @media only screen and (max-width: 480px){
        body,table,td,p,a,li,blockquote{
            -webkit-text-size-adjust:none !important;
        }

}   @media only screen and (max-width: 480px){
        body{
            width:100% !important;
            min-width:100% !important;
        }

}   @media only screen and (max-width: 480px){
        #bodyCell{
            padding-top:10px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnRetinaImage{
            max-width:100% !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImage{
            width:100% !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnCartContainer,.mcnCaptionTopContent,.mcnRecContentContainer,.mcnCaptionBottomContent,.mcnTextContentContainer,.mcnBoxedTextContentContainer,.mcnImageGroupContentContainer,.mcnCaptionLeftTextContentContainer,.mcnCaptionRightTextContentContainer,.mcnCaptionLeftImageContentContainer,.mcnCaptionRightImageContentContainer,.mcnImageCardLeftTextContentContainer,.mcnImageCardRightTextContentContainer,.mcnImageCardLeftImageContentContainer,.mcnImageCardRightImageContentContainer{
            max-width:100% !important;
            width:100% !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnBoxedTextContentContainer{
            min-width:100% !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImageGroupContent{
            padding:9px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnCaptionLeftContentOuter .mcnTextContent,.mcnCaptionRightContentOuter .mcnTextContent{
            padding-top:9px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImageCardTopImageContent,.mcnCaptionBottomContent:last-child .mcnCaptionBottomImageContent,.mcnCaptionBlockInner .mcnCaptionTopContent:last-child .mcnTextContent{
            padding-top:18px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImageCardBottomImageContent{
            padding-bottom:9px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImageGroupBlockInner{
            padding-top:0 !important;
            padding-bottom:0 !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImageGroupBlockOuter{
            padding-top:9px !important;
            padding-bottom:9px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnTextContent,.mcnBoxedTextContentColumn{
            padding-right:18px !important;
            padding-left:18px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcnImageCardLeftImageContent,.mcnImageCardRightImageContent{
            padding-right:18px !important;
            padding-bottom:0 !important;
            padding-left:18px !important;
        }

}   @media only screen and (max-width: 480px){
        .mcpreview-image-uploader{
            display:none !important;
            width:100% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Heading 1
    @tip Make the first-level headings larger in size for better readability on small screens.
    */
        h1{
            /*@editable*/font-size:22px !important;
            /*@editable*/line-height:125% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Heading 2
    @tip Make the second-level headings larger in size for better readability on small screens.
    */
        h2{
            /*@editable*/font-size:20px !important;
            /*@editable*/line-height:125% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Heading 3
    @tip Make the third-level headings larger in size for better readability on small screens.
    */
        h3{
            /*@editable*/font-size:18px !important;
            /*@editable*/line-height:125% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Heading 4
    @tip Make the fourth-level headings larger in size for better readability on small screens.
    */
        h4{
            /*@editable*/font-size:16px !important;
            /*@editable*/line-height:150% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Boxed Text
    @tip Make the boxed text larger in size for better readability on small screens. We recommend a font size of at least 16px.
    */
        .mcnBoxedTextContentContainer .mcnTextContent,.mcnBoxedTextContentContainer .mcnTextContent p{
            /*@editable*/font-size:14px !important;
            /*@editable*/line-height:150% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Preheader Visibility
    @tip Set the visibility of the email's preheader on small screens. You can hide it to save space.
    */
        #templatePreheader{
            /*@editable*/display:block !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Preheader Text
    @tip Make the preheader text larger in size for better readability on small screens.
    */
        #templatePreheader .mcnTextContent,#templatePreheader .mcnTextContent p{
            /*@editable*/font-size:14px !important;
            /*@editable*/line-height:150% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Header Text
    @tip Make the header text larger in size for better readability on small screens.
    */
        #templateHeader .mcnTextContent,#templateHeader .mcnTextContent p{
            /*@editable*/font-size:16px !important;
            /*@editable*/line-height:150% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Body Text
    @tip Make the body text larger in size for better readability on small screens. We recommend a font size of at least 16px.
    */
        #templateBody .mcnTextContent,#templateBody .mcnTextContent p{
            /*@editable*/font-size:16px !important;
            /*@editable*/line-height:150% !important;
        }

}   @media only screen and (max-width: 480px){
    /*
    @tab Mobile Styles
    @section Footer Text
    @tip Make the footer content text larger in size for better readability on small screens.
    */
        #templateFooter .mcnTextContent,#templateFooter .mcnTextContent p{
            /*@editable*/font-size:14px !important;
            /*@editable*/line-height:150% !important;
        }

}</style></head>
    <body>
        <center>
            <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
                <tr>
                    <td align="center" valign="top" id="bodyCell">
                        <!-- BEGIN TEMPLATE // -->
                        <table border="0" cellpadding="0" cellspacing="0" width="100%">
                            <tr>
                                <td align="center" valign="top" id="templatePreheader">
                                    <!--[if (gte mso 9)|(IE)]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                                    <tr>
                                    <td align="center" valign="top" width="600" style="width:600px;">
                                    <![endif]-->
                                    <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                                        <tr>
                                            <td valign="top" class="preheaderContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
                <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
                <tr>
                <![endif]-->

                <!--[if mso]>
                <td valign="top" width="600" style="width:600px;">
                <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding: 0px 18px 9px; text-align: center;">

                            Mandato Aberto - Boas vindas e funções da plataforma&nbsp;<br>
<a href="*|ARCHIVE|*" target="_blank">Visualizar este e-mail no navegador</a>
                        </td>
                    </tr>
                </tbody></table>
                <!--[if mso]>
                </td>
                <![endif]-->

                <!--[if mso]>
                </tr>
                </table>
                <![endif]-->
            </td>
        </tr>
    </tbody>
</table></td>
                                        </tr>
                                    </table>
                                    <!--[if (gte mso 9)|(IE)]>
                                    </td>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                            <tr>
                                <td align="center" valign="top" id="templateHeader">
                                    <!--[if (gte mso 9)|(IE)]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                                    <tr>
                                    <td align="center" valign="top" width="600" style="width:600px;">
                                    <![endif]-->
                                    <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                                        <tr>
                                            <td valign="top" class="headerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnImageBlock" style="min-width:100%;">
    <tbody class="mcnImageBlockOuter">
            <tr>
                <td valign="top" style="padding:9px" class="mcnImageBlockInner">
                    <table align="left" width="100%" border="0" cellpadding="0" cellspacing="0" class="mcnImageContentContainer" style="min-width:100%;">
                        <tbody><tr>
                            <td class="mcnImageContent" valign="top" style="padding-right: 9px; padding-left: 9px; padding-top: 0; padding-bottom: 0; text-align:center;">


                                        <img align="center" alt="" src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/fdc9220b-36f2-4272-acff-01da054e3325.png" width="564" style="max-width:600px; padding-bottom: 0; display: inline !important; vertical-align: bottom;" class="mcnImage">


                            </td>
                        </tr>
                    </tbody></table>
                </td>
            </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
                <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
                <tr>
                <![endif]-->

                <!--[if mso]>
                <td valign="top" width="600" style="width:600px;">
                <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <div style="text-align: center;"><span style="font-size:24px"><span style="color:#808080"><em><span style="font-family:georgia,times,times new roman,serif">A equipe Mandato Aberto agradece seu cadastro!</span></em></span></span><br>
<span style="font-family:georgia,times,times new roman,serif"><span style="font-size:14px"><span style="color:#696969">Iremos validar seu cadastro em breve. Aguarde nossa confirmação por email.</span></span></span></div>

                        </td>
                    </tr>
                </tbody></table>
                <!--[if mso]>
                </td>
                <![endif]-->

                <!--[if mso]>
                </tr>
                </table>
                <![endif]-->
            </td>
        </tr>
    </tbody>
</table></td>
                                        </tr>
                                    </table>
                                    <!--[if (gte mso 9)|(IE)]>
                                    </td>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                            <tr>
                                <td align="center" valign="top" id="templateBody">
                                    <!--[if (gte mso 9)|(IE)]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                                    <tr>
                                    <td align="center" valign="top" width="600" style="width:600px;">
                                    <![endif]-->
                                    <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                                        <tr>
                                            <td valign="top" class="bodyContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
                <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
                <tr>
                <![endif]-->

                <!--[if mso]>
                <td valign="top" width="600" style="width:600px;">
                <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <span style="color:#696969"><span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">Acreditamos que o diálogo transparente entre pessoas e governos é o caminho para inovar e impactar positivamente a realidade de todos. </span></span>
                        </td>
                    </tr>
                </tbody></table>
                <!--[if mso]>
                </td>
                <![endif]-->

                <!--[if mso]>
                </tr>
                </table>
                <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width:100%; padding:18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top: 2px solid #EAEAEA;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
                <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
                <tr>
                <![endif]-->

                <!--[if mso]>
                <td valign="top" width="600" style="width:600px;">
                <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <p><span style="font-size:20px"><span style="color:#696969"><strong><em><span style="font-family:georgia,times,times new roman,serif">Conheça algumas funções da plataforma Mandato Aberto:</span></em></strong></span></span></p>

                        </td>
                    </tr>
                </tbody></table>
                <!--[if mso]>
                </td>
                <![endif]-->

                <!--[if mso]>
                </tr>
                </table>
                <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnCaptionBlock">
    <tbody class="mcnCaptionBlockOuter">
        <tr>
            <td class="mcnCaptionBlockInner" valign="top" style="padding:9px;">


<table align="left" border="0" cellpadding="0" cellspacing="0" class="mcnCaptionBottomContent">
    <tbody><tr>
        <td class="mcnCaptionBottomImageContent" align="center" valign="top" style="padding:0 9px 9px 9px;">



            <img alt="" src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/f61db70f-7650-424d-a5ba-a7a7ae764f3a.png" width="564" style="max-width:600px;" class="mcnImage">


        </td>
    </tr>
    <tr>
        <td class="mcnTextContent" valign="top" style="padding:0 9px 0 9px;" width="564">
            <ul>
    <li><span style="color:#696969"><span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">Ferramenta analítica de sua rede social.</span></span><br>
    &nbsp;</li>
    <li><span style="color:#696969"><span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">Painel de controle para monitorar em tempo real todas sua interações.</span></span><br>
    &nbsp;</li>
    <li><span style="color:#696969"><span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">Notificações para rede de contatos sem custos adicionais no Facebook</span></span><br>
    &nbsp;</li>
</ul>
<span style="color:#696969"><span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">Criação de fluxos no assistente digital para descrever informações sobre o perfil. Mandato Aberto é uma plataforma livre de chatbot (assistente digital) que irá auxiliar na comunicação e segmentação de contatos.<br>
<br>
A plataforma foi desenvolvida para atender lideranças políticas em exercício de cargos públicos ou não. </span></span><br>
<br>
<span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif"><a href="https://mandatoaberto.com.br/sobre/" target="_blank"><span style="color:#bc3984">Saiba mais</span></a></span>
        </td>
    </tr>
</tbody></table>





            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnBoxedTextBlock" style="min-width:100%;">
    <!--[if gte mso 9]>
    <table align="center" border="0" cellspacing="0" cellpadding="0" width="100%">
    <![endif]-->
    <tbody class="mcnBoxedTextBlockOuter">
        <tr>
            <td valign="top" class="mcnBoxedTextBlockInner">

                <!--[if gte mso 9]>
                <td align="center" valign="top" ">
                <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;" class="mcnBoxedTextContentContainer">
                    <tbody><tr>

                        <td style="padding-top:9px; padding-left:18px; padding-bottom:9px; padding-right:18px;">

                            <table border="0" cellspacing="0" class="mcnTextContentContainer" width="100%" style="min-width: 100% !important;background-color: #404040;">
                                <tbody><tr>
                                    <td valign="top" class="mcnTextContent" style="padding: 18px;color: #F2F2F2;font-family: Helvetica;font-size: 14px;font-weight: normal;text-align: center;">
                                        <span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">*Consulte um de nossos especialistas, para saber sobre o uso da plataforma durante o período eleitoral</span><span style="color:#696969"><span style="font-family:open sans,helvetica neue,helvetica,arial,sans-serif">.&nbsp;</span></span>
                                    </td>
                                </tr>
                            </tbody></table>
                        </td>
                    </tr>
                </tbody></table>
                <!--[if gte mso 9]>
                </td>
                <![endif]-->

                <!--[if gte mso 9]>
                </tr>
                </table>
                <![endif]-->
            </td>
        </tr>
    </tbody>
</table></td>
                                        </tr>
                                    </table>
                                    <!--[if (gte mso 9)|(IE)]>
                                    </td>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                            <tr>
                                <td align="center" valign="top" id="templateFooter">
                                    <!--[if (gte mso 9)|(IE)]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                                    <tr>
                                    <td align="center" valign="top" width="600" style="width:600px;">
                                    <![endif]-->
                                    <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                                        <tr>
                                            <td valign="top" class="footerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowBlock" style="min-width:100%;">
    <tbody class="mcnFollowBlockOuter">
        <tr>
            <td align="center" valign="top" style="padding:9px" class="mcnFollowBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentContainer" style="min-width:100%;">
    <tbody><tr>
        <td align="center" style="padding-left:9px;padding-right:9px;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;" class="mcnFollowContent">
                <tbody><tr>
                    <td align="center" valign="top" style="padding-top:9px; padding-right:9px; padding-left:9px;">
                        <table align="center" border="0" cellpadding="0" cellspacing="0">
                            <tbody><tr>
                                <td align="center" valign="top">
                                    <!--[if mso]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0">
                                    <tr>
                                    <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:0; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://mandatoaberto.com.br/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/color-link-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                    <!--[if mso]>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                        </tbody></table>
                    </td>
                </tr>
            </tbody></table>
        </td>
    </tr>
</tbody></table>

            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 10px 18px 25px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top: 2px solid #EEEEEE;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
                <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
                <tr>
                <![endif]-->

                <!--[if mso]>
                <td valign="top" width="600" style="width:600px;">
                <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            Mandato Aberto é uma plataforma aberta e baseada em software livre, os realizadores não se responsabilizam pelas informações fornecidas pelos gestores políticos, nem pelo comportamento deles durante os respectivos mandatos.<br>
<br>
Este projeto é distribuído sob a licença Affero General Public License.
                        </td>
                    </tr>
                </tbody></table>
                <!--[if mso]>
                </td>
                <![endif]-->

                <!--[if mso]>
                </tr>
                </table>
                <![endif]-->
            </td>
        </tr>
    </tbody>
</table></td>
                                        </tr>
                                    </table>
                                    <!--[if (gte mso 9)|(IE)]>
                                    </td>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                        </table>
                        <!-- // END TEMPLATE -->
                    </td>
                </tr>
            </table>
        </center>
    </body>
</html>


@@ premium-active.tt

<!doctype html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
  <head>
    <!-- NAME: ANNOUNCE -->
    <!--[if gte mso 15]>
    <xml>
      <o:OfficeDocumentSettings>
      <o:AllowPNG/>
      <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
    <![endif]-->
    <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>*|MC:SUBJECT|*</title>

    <style type="text/css">
    p{
      margin:10px 0;
      padding:0;
    }
    table{
      border-collapse:collapse;
    }
    h1,h2,h3,h4,h5,h6{
      display:block;
      margin:0;
      padding:0;
    }
    img,a img{
      border:0;
      height:auto;
      outline:none;
      text-decoration:none;
    }
    body,#bodyTable,#bodyCell{
      height:100%;
      margin:0;
      padding:0;
      width:100%;
    }
    .mcnPreviewText{
      display:none !important;
    }
    #outlook a{
      padding:0;
    }
    img{
      -ms-interpolation-mode:bicubic;
    }
    table{
      mso-table-lspace:0pt;
      mso-table-rspace:0pt;
    }
    .ReadMsgBody{
      width:100%;
    }
    .ExternalClass{
      width:100%;
    }
    p,a,li,td,blockquote{
      mso-line-height-rule:exactly;
    }
    a[href^=tel],a[href^=sms]{
      color:inherit;
      cursor:default;
      text-decoration:none;
    }
    p,a,li,td,body,table,blockquote{
      -ms-text-size-adjust:100%;
      -webkit-text-size-adjust:100%;
    }
    .ExternalClass,.ExternalClass p,.ExternalClass td,.ExternalClass div,.ExternalClass span,.ExternalClass font{
      line-height:100%;
    }
    a[x-apple-data-detectors]{
      color:inherit !important;
      text-decoration:none !important;
      font-size:inherit !important;
      font-family:inherit !important;
      font-weight:inherit !important;
      line-height:inherit !important;
    }
    .templateContainer{
      max-width:600px !important;
    }
    a.mcnButton{
      display:block;
    }
    .mcnImage,.mcnRetinaImage{
      vertical-align:bottom;
    }
    .mcnTextContent{
      word-break:break-word;
    }
    .mcnTextContent img{
      height:auto !important;
    }
    .mcnDividerBlock{
      table-layout:fixed !important;
    }
  /*
  @tab Page
  @section Heading 1
  @style heading 1
  */
    h1{
      /*@editable*/color:#222222;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:40px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:center;
    }
  /*
  @tab Page
  @section Heading 2
  @style heading 2
  */
    h2{
      /*@editable*/color:#222222;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:34px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:left;
    }
  /*
  @tab Page
  @section Heading 3
  @style heading 3
  */
    h3{
      /*@editable*/color:#444444;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:22px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:left;
    }
  /*
  @tab Page
  @section Heading 4
  @style heading 4
  */
    h4{
      /*@editable*/color:#999999;
      /*@editable*/font-family:Georgia;
      /*@editable*/font-size:20px;
      /*@editable*/font-style:italic;
      /*@editable*/font-weight:normal;
      /*@editable*/line-height:125%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:center;
    }
  /*
  @tab Header
  @section Header Container Style
  */
    #templateHeader{
      /*@editable*/background-color:#transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Header
  @section Header Interior Style
  */
    .headerContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Header
  @section Header Text
  */
    .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{
      /*@editable*/color:#808080;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:16px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:left;
    }
  /*
  @tab Header
  @section Header Link
  */
    .headerContainer .mcnTextContent a,.headerContainer .mcnTextContent p a{
      /*@editable*/color:#00ADD8;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  /*
  @tab Body
  @section Body Container Style
  */
    #templateBody{
      /*@editable*/background-color:#FFFFFF;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Body
  @section Body Interior Style
  */
    .bodyContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Body
  @section Body Text
  */
    .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{
      /*@editable*/color:#808080;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:16px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:left;
    }
  /*
  @tab Body
  @section Body Link
  */
    .bodyContainer .mcnTextContent a,.bodyContainer .mcnTextContent p a{
      /*@editable*/color:#00ADD8;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  /*
  @tab Footer
  @section Footer Style
  */
    #templateFooter{
      /*@editable*/background-color:#transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Footer
  @section Footer Interior Style
  */
    .footerContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Footer
  @section Footer Text
  */
    .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{
      /*@editable*/color:#FFFFFF;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:12px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:center;
    }
  /*
  @tab Footer
  @section Footer Link
  */
    .footerContainer .mcnTextContent a,.footerContainer .mcnTextContent p a{
      /*@editable*/color:#FFFFFF;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  @media only screen and (min-width:768px){
    .templateContainer{
      width:600px !important;
    }

} @media only screen and (max-width: 480px){
    body,table,td,p,a,li,blockquote{
      -webkit-text-size-adjust:none !important;
    }

} @media only screen and (max-width: 480px){
    body{
      width:100% !important;
      min-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnRetinaImage{
      max-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImage{
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnCartContainer,.mcnCaptionTopContent,.mcnRecContentContainer,.mcnCaptionBottomContent,.mcnTextContentContainer,.mcnBoxedTextContentContainer,.mcnImageGroupContentContainer,.mcnCaptionLeftTextContentContainer,.mcnCaptionRightTextContentContainer,.mcnCaptionLeftImageContentContainer,.mcnCaptionRightImageContentContainer,.mcnImageCardLeftTextContentContainer,.mcnImageCardRightTextContentContainer,.mcnImageCardLeftImageContentContainer,.mcnImageCardRightImageContentContainer{
      max-width:100% !important;
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnBoxedTextContentContainer{
      min-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupContent{
      padding:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnCaptionLeftContentOuter .mcnTextContent,.mcnCaptionRightContentOuter .mcnTextContent{
      padding-top:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardTopImageContent,.mcnCaptionBottomContent:last-child .mcnCaptionBottomImageContent,.mcnCaptionBlockInner .mcnCaptionTopContent:last-child .mcnTextContent{
      padding-top:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardBottomImageContent{
      padding-bottom:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupBlockInner{
      padding-top:0 !important;
      padding-bottom:0 !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupBlockOuter{
      padding-top:9px !important;
      padding-bottom:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnTextContent,.mcnBoxedTextContentColumn{
      padding-right:18px !important;
      padding-left:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardLeftImageContent,.mcnImageCardRightImageContent{
      padding-right:18px !important;
      padding-bottom:0 !important;
      padding-left:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcpreview-image-uploader{
      display:none !important;
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 1
  @tip Make the first-level headings larger in size for better readability on small screens.
  */
    h1{
      /*@editable*/font-size:30px !important;
      /*@editable*/line-height:125% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 2
  @tip Make the second-level headings larger in size for better readability on small screens.
  */
    h2{
      /*@editable*/font-size:26px !important;
      /*@editable*/line-height:125% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 3
  @tip Make the third-level headings larger in size for better readability on small screens.
  */
    h3{
      /*@editable*/font-size:20px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 4
  @tip Make the fourth-level headings larger in size for better readability on small screens.
  */
    h4{
      /*@editable*/font-size:18px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Boxed Text
  @tip Make the boxed text larger in size for better readability on small screens. We recommend a font size of at least 16px.
  */
    .mcnBoxedTextContentContainer .mcnTextContent,.mcnBoxedTextContentContainer .mcnTextContent p{
      /*@editable*/font-size:14px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Header Text
  @tip Make the header text larger in size for better readability on small screens.
  */
    .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{
      /*@editable*/font-size:16px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Body Text
  @tip Make the body text larger in size for better readability on small screens. We recommend a font size of at least 16px.
  */
    .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{
      /*@editable*/font-size:16px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Footer Text
  @tip Make the footer content text larger in size for better readability on small screens.
  */
    .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{
      /*@editable*/font-size:14px !important;
      /*@editable*/line-height:150% !important;
    }

}</style></head>
    <body>
        <center>
            <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
                <tr>
                    <td align="center" valign="top" id="bodyCell">
                        <!-- BEGIN TEMPLATE // -->
                        <table border="0" cellpadding="0" cellspacing="0" width="100%">
              <tr>
                <td align="center" valign="top" id="templateHeader" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="headerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnImageBlock" style="min-width:100%;">
    <tbody class="mcnImageBlockOuter">
            <tr>
                <td valign="top" style="padding:9px" class="mcnImageBlockInner">
                    <table align="left" width="100%" border="0" cellpadding="0" cellspacing="0" class="mcnImageContentContainer" style="min-width:100%;">
                        <tbody><tr>
                            <td class="mcnImageContent" valign="top" style="padding-right: 9px; padding-left: 9px; padding-top: 0; padding-bottom: 0; text-align:center;">


                                        <img align="center" alt="" src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/07641236-7b5b-47b2-a704-9003cba109e6.jpg" width="564" style="max-width:1024px; padding-bottom: 0; display: inline !important; vertical-align: bottom;" class="mcnImage">


                            </td>
                        </tr>
                    </tbody></table>
                </td>
            </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
              <tr>
                <td align="center" valign="top" id="templateBody" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="bodyContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
        <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
        <tr>
        <![endif]-->

        <!--[if mso]>
        <td valign="top" width="600" style="width:600px;">
        <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <h4>Você agora é um assinante premium da plataforma!</h4>

<h1><span style="font-size:20px">Recebemos a confirmação de pagamento&nbsp;com sucesso.</span></h1>

                        </td>
                    </tr>
                </tbody></table>
        <!--[if mso]>
        </td>
        <![endif]-->

        <!--[if mso]>
        </tr>
        </table>
        <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 9px 18px 0px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
        <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
        <tr>
        <![endif]-->

        <!--[if mso]>
        <td valign="top" width="600" style="width:600px;">
        <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <p dir="ltr" style="text-align: left;"><span style="font-size:15px">Agora você é um&nbsp;assinante&nbsp;premium da plataforma Mandato Aberto. Confira as vantagens:</span></p>

<ul dir="ltr">
  <li style="text-align: left;"><span style="font-size:16px"><strong><font color="#cc3399">Envie mensagens diretas e ilimitadas para seus seguidores sem nenhum custo adicional;</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong><font color="#cc3399">Receba&nbsp;conteúdo estratégico para aumentar o relacionamento em sua página;</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong><font color="#cc3399">Mobilize seus seguidores e evite a ação de fakes news e&nbsp;robôs em sua base;&nbsp;</font></strong></span></li>
</ul>

                        </td>
                    </tr>
                </tbody></table>
        <!--[if mso]>
        </td>
        <![endif]-->

        <!--[if mso]>
        </tr>
        </table>
        <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 9px 18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top-width: 1px;border-top-style: solid;border-top-color: #E0E0E0;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 18px 18px 0px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnButtonBlock" style="min-width:100%;">
    <tbody class="mcnButtonBlockOuter">
        <tr>
            <td style="padding-top:0; padding-right:18px; padding-bottom:18px; padding-left:18px;" valign="top" align="center" class="mcnButtonBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" class="mcnButtonContentContainer" style="border-collapse: separate !important;border-radius: 3px;background-color: #E0629A;">
                    <tbody>
                        <tr>
                            <td align="center" valign="middle" class="mcnButtonContent" style="font-family: Helvetica; font-size: 18px; padding: 18px;">
                                <a class="mcnButton " title="Saiba mais" href="https://mandatoaberto.com.br/" target="_self" style="font-weight: bold;letter-spacing: -0.5px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;">Saiba mais</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </td>
        </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
                            <tr>
                <td align="center" valign="top" id="templateFooter" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="footerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowBlock" style="min-width:100%;">
    <tbody class="mcnFollowBlockOuter">
        <tr>
            <td align="center" valign="top" style="padding:9px" class="mcnFollowBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentContainer" style="min-width:100%;">
    <tbody><tr>
        <td align="center" style="padding-left:9px;padding-right:9px;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;" class="mcnFollowContent">
                <tbody><tr>
                    <td align="center" valign="top" style="padding-top:9px; padding-right:9px; padding-left:9px;">
                        <table align="center" border="0" cellpadding="0" cellspacing="0">
                            <tbody><tr>
                                <td align="center" valign="top">
                                    <!--[if mso]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0">
                                    <tr>
                                    <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:10px; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://www.facebook.com/AppCivicoCSB/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-facebook-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:10px; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="http://www.twitter.com/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-twitter-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:0; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://mandatoaberto.com.br/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-link-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                    <!--[if mso]>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                        </tbody></table>
                    </td>
                </tr>
            </tbody></table>
        </td>
    </tr>
</tbody></table>

            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top-width: 2px;border-top-style: solid;border-top-color: #505050;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
                        </table>
                        <!-- // END TEMPLATE -->
                    </td>
                </tr>
            </table>
        </center>
    </body>
</html>


@@ premium-inactive.tt

<!doctype html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
  <head>
    <!-- NAME: ANNOUNCE -->
    <!--[if gte mso 15]>
    <xml>
      <o:OfficeDocumentSettings>
      <o:AllowPNG/>
      <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
    <![endif]-->
    <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>*|MC:SUBJECT|*</title>

    <style type="text/css">
    p{
      margin:10px 0;
      padding:0;
    }
    table{
      border-collapse:collapse;
    }
    h1,h2,h3,h4,h5,h6{
      display:block;
      margin:0;
      padding:0;
    }
    img,a img{
      border:0;
      height:auto;
      outline:none;
      text-decoration:none;
    }
    body,#bodyTable,#bodyCell{
      height:100%;
      margin:0;
      padding:0;
      width:100%;
    }
    .mcnPreviewText{
      display:none !important;
    }
    #outlook a{
      padding:0;
    }
    img{
      -ms-interpolation-mode:bicubic;
    }
    table{
      mso-table-lspace:0pt;
      mso-table-rspace:0pt;
    }
    .ReadMsgBody{
      width:100%;
    }
    .ExternalClass{
      width:100%;
    }
    p,a,li,td,blockquote{
      mso-line-height-rule:exactly;
    }
    a[href^=tel],a[href^=sms]{
      color:inherit;
      cursor:default;
      text-decoration:none;
    }
    p,a,li,td,body,table,blockquote{
      -ms-text-size-adjust:100%;
      -webkit-text-size-adjust:100%;
    }
    .ExternalClass,.ExternalClass p,.ExternalClass td,.ExternalClass div,.ExternalClass span,.ExternalClass font{
      line-height:100%;
    }
    a[x-apple-data-detectors]{
      color:inherit !important;
      text-decoration:none !important;
      font-size:inherit !important;
      font-family:inherit !important;
      font-weight:inherit !important;
      line-height:inherit !important;
    }
    .templateContainer{
      max-width:600px !important;
    }
    a.mcnButton{
      display:block;
    }
    .mcnImage,.mcnRetinaImage{
      vertical-align:bottom;
    }
    .mcnTextContent{
      word-break:break-word;
    }
    .mcnTextContent img{
      height:auto !important;
    }
    .mcnDividerBlock{
      table-layout:fixed !important;
    }
  /*
  @tab Page
  @section Heading 1
  @style heading 1
  */
    h1{
      /*@editable*/color:#222222;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:40px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:center;
    }
  /*
  @tab Page
  @section Heading 2
  @style heading 2
  */
    h2{
      /*@editable*/color:#222222;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:34px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:left;
    }
  /*
  @tab Page
  @section Heading 3
  @style heading 3
  */
    h3{
      /*@editable*/color:#444444;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:22px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:left;
    }
  /*
  @tab Page
  @section Heading 4
  @style heading 4
  */
    h4{
      /*@editable*/color:#999999;
      /*@editable*/font-family:Georgia;
      /*@editable*/font-size:20px;
      /*@editable*/font-style:italic;
      /*@editable*/font-weight:normal;
      /*@editable*/line-height:125%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:center;
    }
  /*
  @tab Header
  @section Header Container Style
  */
    #templateHeader{
      /*@editable*/background-color:#transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Header
  @section Header Interior Style
  */
    .headerContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Header
  @section Header Text
  */
    .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{
      /*@editable*/color:#808080;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:16px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:left;
    }
  /*
  @tab Header
  @section Header Link
  */
    .headerContainer .mcnTextContent a,.headerContainer .mcnTextContent p a{
      /*@editable*/color:#00ADD8;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  /*
  @tab Body
  @section Body Container Style
  */
    #templateBody{
      /*@editable*/background-color:#FFFFFF;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Body
  @section Body Interior Style
  */
    .bodyContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Body
  @section Body Text
  */
    .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{
      /*@editable*/color:#808080;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:16px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:left;
    }
  /*
  @tab Body
  @section Body Link
  */
    .bodyContainer .mcnTextContent a,.bodyContainer .mcnTextContent p a{
      /*@editable*/color:#00ADD8;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  /*
  @tab Footer
  @section Footer Style
  */
    #templateFooter{
      /*@editable*/background-color:#transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Footer
  @section Footer Interior Style
  */
    .footerContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Footer
  @section Footer Text
  */
    .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{
      /*@editable*/color:#FFFFFF;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:12px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:center;
    }
  /*
  @tab Footer
  @section Footer Link
  */
    .footerContainer .mcnTextContent a,.footerContainer .mcnTextContent p a{
      /*@editable*/color:#FFFFFF;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  @media only screen and (min-width:768px){
    .templateContainer{
      width:600px !important;
    }

} @media only screen and (max-width: 480px){
    body,table,td,p,a,li,blockquote{
      -webkit-text-size-adjust:none !important;
    }

} @media only screen and (max-width: 480px){
    body{
      width:100% !important;
      min-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnRetinaImage{
      max-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImage{
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnCartContainer,.mcnCaptionTopContent,.mcnRecContentContainer,.mcnCaptionBottomContent,.mcnTextContentContainer,.mcnBoxedTextContentContainer,.mcnImageGroupContentContainer,.mcnCaptionLeftTextContentContainer,.mcnCaptionRightTextContentContainer,.mcnCaptionLeftImageContentContainer,.mcnCaptionRightImageContentContainer,.mcnImageCardLeftTextContentContainer,.mcnImageCardRightTextContentContainer,.mcnImageCardLeftImageContentContainer,.mcnImageCardRightImageContentContainer{
      max-width:100% !important;
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnBoxedTextContentContainer{
      min-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupContent{
      padding:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnCaptionLeftContentOuter .mcnTextContent,.mcnCaptionRightContentOuter .mcnTextContent{
      padding-top:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardTopImageContent,.mcnCaptionBottomContent:last-child .mcnCaptionBottomImageContent,.mcnCaptionBlockInner .mcnCaptionTopContent:last-child .mcnTextContent{
      padding-top:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardBottomImageContent{
      padding-bottom:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupBlockInner{
      padding-top:0 !important;
      padding-bottom:0 !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupBlockOuter{
      padding-top:9px !important;
      padding-bottom:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnTextContent,.mcnBoxedTextContentColumn{
      padding-right:18px !important;
      padding-left:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardLeftImageContent,.mcnImageCardRightImageContent{
      padding-right:18px !important;
      padding-bottom:0 !important;
      padding-left:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcpreview-image-uploader{
      display:none !important;
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 1
  @tip Make the first-level headings larger in size for better readability on small screens.
  */
    h1{
      /*@editable*/font-size:30px !important;
      /*@editable*/line-height:125% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 2
  @tip Make the second-level headings larger in size for better readability on small screens.
  */
    h2{
      /*@editable*/font-size:26px !important;
      /*@editable*/line-height:125% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 3
  @tip Make the third-level headings larger in size for better readability on small screens.
  */
    h3{
      /*@editable*/font-size:20px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 4
  @tip Make the fourth-level headings larger in size for better readability on small screens.
  */
    h4{
      /*@editable*/font-size:18px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Boxed Text
  @tip Make the boxed text larger in size for better readability on small screens. We recommend a font size of at least 16px.
  */
    .mcnBoxedTextContentContainer .mcnTextContent,.mcnBoxedTextContentContainer .mcnTextContent p{
      /*@editable*/font-size:14px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Header Text
  @tip Make the header text larger in size for better readability on small screens.
  */
    .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{
      /*@editable*/font-size:16px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Body Text
  @tip Make the body text larger in size for better readability on small screens. We recommend a font size of at least 16px.
  */
    .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{
      /*@editable*/font-size:16px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Footer Text
  @tip Make the footer content text larger in size for better readability on small screens.
  */
    .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{
      /*@editable*/font-size:14px !important;
      /*@editable*/line-height:150% !important;
    }

}</style></head>
    <body>
        <center>
            <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
                <tr>
                    <td align="center" valign="top" id="bodyCell">
                        <!-- BEGIN TEMPLATE // -->
                        <table border="0" cellpadding="0" cellspacing="0" width="100%">
              <tr>
                <td align="center" valign="top" id="templateHeader" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="headerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnImageBlock" style="min-width:100%;">
    <tbody class="mcnImageBlockOuter">
            <tr>
                <td valign="top" style="padding:9px" class="mcnImageBlockInner">
                    <table align="left" width="100%" border="0" cellpadding="0" cellspacing="0" class="mcnImageContentContainer" style="min-width:100%;">
                        <tbody><tr>
                            <td class="mcnImageContent" valign="top" style="padding-right: 9px; padding-left: 9px; padding-top: 0; padding-bottom: 0; text-align:center;">


                                        <img align="center" alt="" src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/a2839517-d98e-445b-8449-767dfafb0bcc.jpg" width="564" style="max-width:5653px; padding-bottom: 0; display: inline !important; vertical-align: bottom;" class="mcnImage">


                            </td>
                        </tr>
                    </tbody></table>
                </td>
            </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
              <tr>
                <td align="center" valign="top" id="templateBody" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="bodyContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
        <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
        <tr>
        <![endif]-->

        <!--[if mso]>
        <td valign="top" width="600" style="width:600px;">
        <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <h4>Não recebemos a confirmação de pagamento para sua assinatura&nbsp;premium da plataforma.</h4>

<h1><span style="font-size:20px">Sua assinatura não foi realizada.</span></h1>

                        </td>
                    </tr>
                </tbody></table>
        <!--[if mso]>
        </td>
        <![endif]-->

        <!--[if mso]>
        </tr>
        </table>
        <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
        <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
        <tr>
        <![endif]-->

        <!--[if mso]>
        <td valign="top" width="600" style="width:600px;">
        <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <p dir="ltr" style="text-align: center;"><span style="font-size:18px">Agradecemos seu contato.<br>
Mas, não&nbsp;identificamos seu pagamento.<br>
Pedimos para que verifique com sua operadora &nbsp;e retorne o contato conosco.</span></p>

                        </td>
                    </tr>
                </tbody></table>
        <!--[if mso]>
        </td>
        <![endif]-->

        <!--[if mso]>
        </tr>
        </table>
        <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 9px 18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top-width: 1px;border-top-style: solid;border-top-color: #E0E0E0;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 18px 18px 0px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnButtonBlock" style="min-width:100%;">
    <tbody class="mcnButtonBlockOuter">
        <tr>
            <td style="padding-top:0; padding-right:18px; padding-bottom:18px; padding-left:18px;" valign="top" align="center" class="mcnButtonBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" class="mcnButtonContentContainer" style="border-collapse: separate !important;border-top-left-radius: 3px;border-top-right-radius: 3px;border-bottom-right-radius: 3px;border-bottom-left-radius: 3px;background-color: #E0629A;">
                    <tbody>
                        <tr>
                            <td align="center" valign="middle" class="mcnButtonContent" style="font-family: Helvetica; font-size: 18px; padding: 18px;">
                                <a class="mcnButton " title="Fale com a gente" href="http://contato@mandatoaberto.com.br" target="_self" style="font-weight: bold;letter-spacing: -0.5px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;">Fale com a gente</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </td>
        </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
                            <tr>
                <td align="center" valign="top" id="templateFooter" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="footerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowBlock" style="min-width:100%;">
    <tbody class="mcnFollowBlockOuter">
        <tr>
            <td align="center" valign="top" style="padding:9px" class="mcnFollowBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentContainer" style="min-width:100%;">
    <tbody><tr>
        <td align="center" style="padding-left:9px;padding-right:9px;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;" class="mcnFollowContent">
                <tbody><tr>
                    <td align="center" valign="top" style="padding-top:9px; padding-right:9px; padding-left:9px;">
                        <table align="center" border="0" cellpadding="0" cellspacing="0">
                            <tbody><tr>
                                <td align="center" valign="top">
                                    <!--[if mso]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0">
                                    <tr>
                                    <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:10px; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://www.facebook.com/AppCivicoCSB/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-facebook-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:10px; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="http://www.twitter.com/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-twitter-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:0; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://mandatoaberto.com.br/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-link-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                    <!--[if mso]>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                        </tbody></table>
                    </td>
                </tr>
            </tbody></table>
        </td>
    </tr>
</tbody></table>

            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top-width: 2px;border-top-style: solid;border-top-color: #505050;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
                        </table>
                        <!-- // END TEMPLATE -->
                    </td>
                </tr>
            </table>
        </center>
    </body>
</html>

@@ new-register.tt

<!doctype html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
  <head>
    <!-- NAME: ANNOUNCE -->
    <!--[if gte mso 15]>
    <xml>
      <o:OfficeDocumentSettings>
      <o:AllowPNG/>
      <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
    <![endif]-->
    <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>*|MC:SUBJECT|*</title>

    <style type="text/css">
    p{
      margin:10px 0;
      padding:0;
    }
    table{
      border-collapse:collapse;
    }
    h1,h2,h3,h4,h5,h6{
      display:block;
      margin:0;
      padding:0;
    }
    img,a img{
      border:0;
      height:auto;
      outline:none;
      text-decoration:none;
    }
    body,#bodyTable,#bodyCell{
      height:100%;
      margin:0;
      padding:0;
      width:100%;
    }
    .mcnPreviewText{
      display:none !important;
    }
    #outlook a{
      padding:0;
    }
    img{
      -ms-interpolation-mode:bicubic;
    }
    table{
      mso-table-lspace:0pt;
      mso-table-rspace:0pt;
    }
    .ReadMsgBody{
      width:100%;
    }
    .ExternalClass{
      width:100%;
    }
    p,a,li,td,blockquote{
      mso-line-height-rule:exactly;
    }
    a[href^=tel],a[href^=sms]{
      color:inherit;
      cursor:default;
      text-decoration:none;
    }
    p,a,li,td,body,table,blockquote{
      -ms-text-size-adjust:100%;
      -webkit-text-size-adjust:100%;
    }
    .ExternalClass,.ExternalClass p,.ExternalClass td,.ExternalClass div,.ExternalClass span,.ExternalClass font{
      line-height:100%;
    }
    a[x-apple-data-detectors]{
      color:inherit !important;
      text-decoration:none !important;
      font-size:inherit !important;
      font-family:inherit !important;
      font-weight:inherit !important;
      line-height:inherit !important;
    }
    .templateContainer{
      max-width:600px !important;
    }
    a.mcnButton{
      display:block;
    }
    .mcnImage,.mcnRetinaImage{
      vertical-align:bottom;
    }
    .mcnTextContent{
      word-break:break-word;
    }
    .mcnTextContent img{
      height:auto !important;
    }
    .mcnDividerBlock{
      table-layout:fixed !important;
    }
  /*
  @tab Page
  @section Heading 1
  @style heading 1
  */
    h1{
      /*@editable*/color:#222222;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:40px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:center;
    }
  /*
  @tab Page
  @section Heading 2
  @style heading 2
  */
    h2{
      /*@editable*/color:#222222;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:34px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:left;
    }
  /*
  @tab Page
  @section Heading 3
  @style heading 3
  */
    h3{
      /*@editable*/color:#444444;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:22px;
      /*@editable*/font-style:normal;
      /*@editable*/font-weight:bold;
      /*@editable*/line-height:150%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:left;
    }
  /*
  @tab Page
  @section Heading 4
  @style heading 4
  */
    h4{
      /*@editable*/color:#999999;
      /*@editable*/font-family:Georgia;
      /*@editable*/font-size:20px;
      /*@editable*/font-style:italic;
      /*@editable*/font-weight:normal;
      /*@editable*/line-height:125%;
      /*@editable*/letter-spacing:normal;
      /*@editable*/text-align:center;
    }
  /*
  @tab Header
  @section Header Container Style
  */
    #templateHeader{
      /*@editable*/background-color:#transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Header
  @section Header Interior Style
  */
    .headerContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Header
  @section Header Text
  */
    .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{
      /*@editable*/color:#808080;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:16px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:left;
    }
  /*
  @tab Header
  @section Header Link
  */
    .headerContainer .mcnTextContent a,.headerContainer .mcnTextContent p a{
      /*@editable*/color:#00ADD8;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  /*
  @tab Body
  @section Body Container Style
  */
    #templateBody{
      /*@editable*/background-color:#FFFFFF;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Body
  @section Body Interior Style
  */
    .bodyContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Body
  @section Body Text
  */
    .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{
      /*@editable*/color:#808080;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:16px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:left;
    }
  /*
  @tab Body
  @section Body Link
  */
    .bodyContainer .mcnTextContent a,.bodyContainer .mcnTextContent p a{
      /*@editable*/color:#00ADD8;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  /*
  @tab Footer
  @section Footer Style
  */
    #templateFooter{
      /*@editable*/background-color:#transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0px;
      /*@editable*/padding-bottom:0px;
    }
  /*
  @tab Footer
  @section Footer Interior Style
  */
    .footerContainer{
      /*@editable*/background-color:transparent;
      /*@editable*/background-image:none;
      /*@editable*/background-repeat:no-repeat;
      /*@editable*/background-position:center;
      /*@editable*/background-size:cover;
      /*@editable*/border-top:0;
      /*@editable*/border-bottom:0;
      /*@editable*/padding-top:0;
      /*@editable*/padding-bottom:0;
    }
  /*
  @tab Footer
  @section Footer Text
  */
    .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{
      /*@editable*/color:#FFFFFF;
      /*@editable*/font-family:Helvetica;
      /*@editable*/font-size:12px;
      /*@editable*/line-height:150%;
      /*@editable*/text-align:center;
    }
  /*
  @tab Footer
  @section Footer Link
  */
    .footerContainer .mcnTextContent a,.footerContainer .mcnTextContent p a{
      /*@editable*/color:#FFFFFF;
      /*@editable*/font-weight:normal;
      /*@editable*/text-decoration:underline;
    }
  @media only screen and (min-width:768px){
    .templateContainer{
      width:600px !important;
    }

} @media only screen and (max-width: 480px){
    body,table,td,p,a,li,blockquote{
      -webkit-text-size-adjust:none !important;
    }

} @media only screen and (max-width: 480px){
    body{
      width:100% !important;
      min-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnRetinaImage{
      max-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImage{
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnCartContainer,.mcnCaptionTopContent,.mcnRecContentContainer,.mcnCaptionBottomContent,.mcnTextContentContainer,.mcnBoxedTextContentContainer,.mcnImageGroupContentContainer,.mcnCaptionLeftTextContentContainer,.mcnCaptionRightTextContentContainer,.mcnCaptionLeftImageContentContainer,.mcnCaptionRightImageContentContainer,.mcnImageCardLeftTextContentContainer,.mcnImageCardRightTextContentContainer,.mcnImageCardLeftImageContentContainer,.mcnImageCardRightImageContentContainer{
      max-width:100% !important;
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnBoxedTextContentContainer{
      min-width:100% !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupContent{
      padding:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnCaptionLeftContentOuter .mcnTextContent,.mcnCaptionRightContentOuter .mcnTextContent{
      padding-top:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardTopImageContent,.mcnCaptionBottomContent:last-child .mcnCaptionBottomImageContent,.mcnCaptionBlockInner .mcnCaptionTopContent:last-child .mcnTextContent{
      padding-top:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardBottomImageContent{
      padding-bottom:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupBlockInner{
      padding-top:0 !important;
      padding-bottom:0 !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageGroupBlockOuter{
      padding-top:9px !important;
      padding-bottom:9px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnTextContent,.mcnBoxedTextContentColumn{
      padding-right:18px !important;
      padding-left:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcnImageCardLeftImageContent,.mcnImageCardRightImageContent{
      padding-right:18px !important;
      padding-bottom:0 !important;
      padding-left:18px !important;
    }

} @media only screen and (max-width: 480px){
    .mcpreview-image-uploader{
      display:none !important;
      width:100% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 1
  @tip Make the first-level headings larger in size for better readability on small screens.
  */
    h1{
      /*@editable*/font-size:30px !important;
      /*@editable*/line-height:125% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 2
  @tip Make the second-level headings larger in size for better readability on small screens.
  */
    h2{
      /*@editable*/font-size:26px !important;
      /*@editable*/line-height:125% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 3
  @tip Make the third-level headings larger in size for better readability on small screens.
  */
    h3{
      /*@editable*/font-size:20px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Heading 4
  @tip Make the fourth-level headings larger in size for better readability on small screens.
  */
    h4{
      /*@editable*/font-size:18px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Boxed Text
  @tip Make the boxed text larger in size for better readability on small screens. We recommend a font size of at least 16px.
  */
    .mcnBoxedTextContentContainer .mcnTextContent,.mcnBoxedTextContentContainer .mcnTextContent p{
      /*@editable*/font-size:14px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Header Text
  @tip Make the header text larger in size for better readability on small screens.
  */
    .headerContainer .mcnTextContent,.headerContainer .mcnTextContent p{
      /*@editable*/font-size:16px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Body Text
  @tip Make the body text larger in size for better readability on small screens. We recommend a font size of at least 16px.
  */
    .bodyContainer .mcnTextContent,.bodyContainer .mcnTextContent p{
      /*@editable*/font-size:16px !important;
      /*@editable*/line-height:150% !important;
    }

} @media only screen and (max-width: 480px){
  /*
  @tab Mobile Styles
  @section Footer Text
  @tip Make the footer content text larger in size for better readability on small screens.
  */
    .footerContainer .mcnTextContent,.footerContainer .mcnTextContent p{
      /*@editable*/font-size:14px !important;
      /*@editable*/line-height:150% !important;
    }

}</style></head>
    <body>
        <center>
            <table align="center" border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable">
                <tr>
                    <td align="center" valign="top" id="bodyCell">
                        <!-- BEGIN TEMPLATE // -->
                        <table border="0" cellpadding="0" cellspacing="0" width="100%">
              <tr>
                <td align="center" valign="top" id="templateHeader" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="headerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnImageBlock" style="min-width:100%;">
    <tbody class="mcnImageBlockOuter">
            <tr>
                <td valign="top" style="padding:9px" class="mcnImageBlockInner">
                    <table align="left" width="100%" border="0" cellpadding="0" cellspacing="0" class="mcnImageContentContainer" style="min-width:100%;">
                        <tbody><tr>
                            <td class="mcnImageContent" valign="top" style="padding-right: 9px; padding-left: 9px; padding-top: 0; padding-bottom: 0; text-align:center;">


                                        <img align="center" alt="" src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/07641236-7b5b-47b2-a704-9003cba109e6.jpg" width="564" style="max-width:1024px; padding-bottom: 0; display: inline !important; vertical-align: bottom;" class="mcnImage">


                            </td>
                        </tr>
                    </tbody></table>
                </td>
            </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
              <tr>
                <td align="center" valign="top" id="templateBody" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="bodyContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
        <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
        <tr>
        <![endif]-->

        <!--[if mso]>
        <td valign="top" width="600" style="width:600px;">
        <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <h4>Recebemos um novo cadastro!</h4>


                        </td>
                    </tr>
                </tbody></table>
        <!--[if mso]>
        </td>
        <![endif]-->

        <!--[if mso]>
        </tr>
        </table>
        <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 9px 18px 0px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnTextBlock" style="min-width:100%;">
    <tbody class="mcnTextBlockOuter">
        <tr>
            <td valign="top" class="mcnTextBlockInner" style="padding-top:9px;">
                <!--[if mso]>
        <table align="left" border="0" cellspacing="0" cellpadding="0" width="100%" style="width:100%;">
        <tr>
        <![endif]-->

        <!--[if mso]>
        <td valign="top" width="600" style="width:600px;">
        <![endif]-->
                <table align="left" border="0" cellpadding="0" cellspacing="0" style="max-width:100%; min-width:100%;" width="100%" class="mcnTextContentContainer">
                    <tbody><tr>

                        <td valign="top" class="mcnTextContent" style="padding-top:0; padding-right:18px; padding-bottom:9px; padding-left:18px;">

                            <p dir="ltr" style="text-align: left;"><span style="font-size:15px">Dados cadastrais:</span></p>

<ul dir="ltr">
  <li style="text-align: left;"><span style="font-size:16px"><strong>Email: <font color="#cc3399"> [% email %];</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong>Nome: <font color="#cc3399"> [% name %];</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong>Cargo: <font color="#cc3399"> [% office %];</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong>G&#xEA;nero: <font color="#cc3399"> [% gender %];</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong>Partido: <font color="#cc3399"> [% party %];</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong>Estado <font color="#cc3399"> [% address_state %];</font></strong></span></li>
  <li style="text-align: left;"><span style="font-size:16px"><strong>Cidade: <font color="#cc3399"> [% address_city %];</font></strong></span></li>
</ul>

                        </td>
                    </tr>
                </tbody></table>
        <!--[if mso]>
        </td>
        <![endif]-->

        <!--[if mso]>
        </tr>
        </table>
        <![endif]-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 9px 18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top-width: 1px;border-top-style: solid;border-top-color: #E0E0E0;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 18px 18px 0px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnButtonBlock" style="min-width:100%;">
    <tbody class="mcnButtonBlockOuter">
        <tr>
            <td style="padding-top:0; padding-right:18px; padding-bottom:18px; padding-left:18px;" valign="top" align="center" class="mcnButtonBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" class="mcnButtonContentContainer" style="border-collapse: separate !important;border-radius: 3px;background-color: #E0629A;">
                    <tbody>
                        <tr>
                            <td align="center" valign="middle" class="mcnButtonContent" style="font-family: Helvetica; font-size: 18px; padding: 18px;">
                                <a class="mcnButton " title="Saiba mais" href="https://mandatoaberto.com.br/" target="_self" style="font-weight: bold;letter-spacing: -0.5px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;">Saiba mais</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </td>
        </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
                            <tr>
                <td align="center" valign="top" id="templateFooter" data-template-container>
                  <!--[if (gte mso 9)|(IE)]>
                  <table align="center" border="0" cellspacing="0" cellpadding="0" width="600" style="width:600px;">
                  <tr>
                  <td align="center" valign="top" width="600" style="width:600px;">
                  <![endif]-->
                  <table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" class="templateContainer">
                    <tr>
                                      <td valign="top" class="footerContainer"><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowBlock" style="min-width:100%;">
    <tbody class="mcnFollowBlockOuter">
        <tr>
            <td align="center" valign="top" style="padding:9px" class="mcnFollowBlockInner">
                <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentContainer" style="min-width:100%;">
    <tbody><tr>
        <td align="center" style="padding-left:9px;padding-right:9px;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width:100%;" class="mcnFollowContent">
                <tbody><tr>
                    <td align="center" valign="top" style="padding-top:9px; padding-right:9px; padding-left:9px;">
                        <table align="center" border="0" cellpadding="0" cellspacing="0">
                            <tbody><tr>
                                <td align="center" valign="top">
                                    <!--[if mso]>
                                    <table align="center" border="0" cellspacing="0" cellpadding="0">
                                    <tr>
                                    <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:10px; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://www.facebook.com/AppCivicoCSB/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-facebook-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:10px; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="http://www.twitter.com/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-twitter-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                        <!--[if mso]>
                                        <td align="center" valign="top">
                                        <![endif]-->


                                            <table align="left" border="0" cellpadding="0" cellspacing="0" style="display:inline;">
                                                <tbody><tr>
                                                    <td valign="top" style="padding-right:0; padding-bottom:9px;" class="mcnFollowContentItemContainer">
                                                        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnFollowContentItem">
                                                            <tbody><tr>
                                                                <td align="left" valign="middle" style="padding-top:5px; padding-right:10px; padding-bottom:5px; padding-left:9px;">
                                                                    <table align="left" border="0" cellpadding="0" cellspacing="0" width="">
                                                                        <tbody><tr>

                                                                                <td align="center" valign="middle" width="24" class="mcnFollowIconContent">
                                                                                    <a href="https://mandatoaberto.com.br/" target="_blank"><img src="https://cdn-images.mailchimp.com/icons/social-block-v2/outline-color-link-48.png" style="display:block;" height="24" width="24" class=""></a>
                                                                                </td>


                                                                        </tr>
                                                                    </tbody></table>
                                                                </td>
                                                            </tr>
                                                        </tbody></table>
                                                    </td>
                                                </tr>
                                            </tbody></table>

                                        <!--[if mso]>
                                        </td>
                                        <![endif]-->

                                    <!--[if mso]>
                                    </tr>
                                    </table>
                                    <![endif]-->
                                </td>
                            </tr>
                        </tbody></table>
                    </td>
                </tr>
            </tbody></table>
        </td>
    </tr>
</tbody></table>

            </td>
        </tr>
    </tbody>
</table><table border="0" cellpadding="0" cellspacing="0" width="100%" class="mcnDividerBlock" style="min-width:100%;">
    <tbody class="mcnDividerBlockOuter">
        <tr>
            <td class="mcnDividerBlockInner" style="min-width: 100%; padding: 18px;">
                <table class="mcnDividerContent" border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;border-top-width: 2px;border-top-style: solid;border-top-color: #505050;">
                    <tbody><tr>
                        <td>
                            <span></span>
                        </td>
                    </tr>
                </tbody></table>
<!--
                <td class="mcnDividerBlockInner" style="padding: 18px;">
                <hr class="mcnDividerContent" style="border-bottom-color:none; border-left-color:none; border-right-color:none; border-bottom-width:0; border-left-width:0; border-right-width:0; margin-top:0; margin-right:0; margin-bottom:0; margin-left:0;" />
-->
            </td>
        </tr>
    </tbody>
</table></td>
                    </tr>
                  </table>
                  <!--[if (gte mso 9)|(IE)]>
                  </td>
                  </tr>
                  </table>
                  <![endif]-->
                </td>
                            </tr>
                        </table>
                        <!-- // END TEMPLATE -->
                    </td>
                </tr>
            </table>
        </center>
    </body>
</html>
