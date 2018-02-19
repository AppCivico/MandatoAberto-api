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

=head2 private_reply_activated

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

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
  "private_reply_activated",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-02-19 10:05:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I0B6NPOq5TlSIsw8ltJC8A


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
                },
                fb_page_access_token => {
                    required   => 0,
                    type       => "Str",
                },
                new_password => {
                    required => 0,
                    type     => "Str"
                },
                private_reply_activated => {
                    required => 0,
                    type     => "Bool"
                }
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

    my $start_date = DateTime->now->subtract( days => $range )->epoch();
    my $end_date   = DateTime->now->epoch();

    my $res = $furl->get(
        $ENV{FB_API_URL} . "/$page_id/insights?access_token=$access_token&metric=page_messages_active_threads_unique&since=$start_date&until=$end_date",
    );
    return 0 unless $res->is_success;

    my $decoded_res = decode_json $res->decoded_content;
    my $untreated_data = $decoded_res->{data}->[0]->{values};
    my $treated_data = {};

    if ($untreated_data) {
        for (my $i = 0; $i < scalar @{ $untreated_data } ; $i++) {
            my $data_per_day = $untreated_data->[$i];

            my $day = DateTime::Format::DateParse->parse_datetime($data_per_day->{end_time});

            $treated_data->{labels}->[$i] = $day->day() . '/' . $day->month();
            $treated_data->{data}->[$i]   = $data_per_day->{value};
        }
        $treated_data->{title} = 'Acessos por dia';
        $treated_data->{subtitle} = "Gráfico de acessos únicos por dia";
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
        subject  => "Mandato Aberto - Boas vindas",
        template => get_data_section('greetings.tt'),
        vars     => {
            name  => $self->name,
        },
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

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ greetings.tt
<!doctype html>
<html>
<head>
<meta charset="UTF-8">
</head>
<body>
<div leftmargin="0" marginheight="0" marginwidth="0" topmargin="0" style="background-color:#f5f5f5; font-family:'Montserrat',Arial,sans-serif; margin:0; padding:0; width:100%">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse">
<tbody>
<tr>
<td>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="600" style="border-collapse:collapse">
<tbody>
<tr>
<td height="50"></td>
</tr>
<tr>
<td bgcolor="#ffffff" colspan="2" style="background-color:rgb(255,255,255); border-radius:0 0 7px 7px; font-family:'Montserrat',Arial,sans-serif; font-size:13px; font-weight:normal; line-height:24px; padding:30px 0; text-align:center; vertical-align:top">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="84%" style="border-collapse:collapse">
<tbody>
<tr>
<td align="justify" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
<p style="text-align: center;"><a href="https://mandatoaberto.com.br/"><img src="https://gallery.mailchimp.com/3db402cdd48dbf45ea97bd7da/images/940adc5a-6e89-468e-9a03-2a4769245c79.png" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></a></p>
<br>
</span>
</p>
<p align="center"> <strong> </strong>Seu cadastro foi aprovado!</p>
<p align="center"><b>Boas-vindas ao Mandato Aberto.</b></p>
<p>Monte agora seu Chatbot (robô que simula uma ação humana em uma conversação). Em pouco tempo ele  estará  ativo e pronto para iniciar uma interação sem intervenção humana, registrando ocorrências e fornecendo informação verificada.</p>
<p>Garanta sua presença digital eficiente e muito além do "bom dia", 24 horas por dia, 7 dias por semana, dentro ou fora do período eleitoral.</p>
<p>Transparência e inovação, coloque a tecnologia a serviço da população.</p>
<p align="center"><b>Próximos passos</b></p>
<p>Customize seu assistente digital. É só ir até opção de menu Diálogos e começar a preencher. </p>
<ul>
<li>Escolha a saudação do seu assistente social, essa será a primeira mensagem que seu assistente enviara para os cidadãos que interagirem com ele. Para isso é só selecionar uma das opções disponíveis.</li>
<li>Preencha os dados seus dados de contato para que seu assistente digital possa informar para os cidadãos.</li>
<li>Responda as perguntas feitas na página de diálogos e seu bot irá incorporar mais diálogos.</li>
</ul>
<p>Agora é só escolher a sua página do Facebook onde o bot ficará hospedada, para isso, vá até o item do menu Perfil, e click no botão Facebook, e é só selecionar a página. Pronto, agora seu assistente digital estará pronto para se comunicar com os cidadãos.
</p>
<p align="center"><b>O que mais posso fazer?</b></p>
<p>No Mandato Aberto, você pode.</p>
<p>Através da sessão Apoiadores, você pode ver todas as pessoas que interagiram com seu assistente digital.</p>
<p>Você também pode visualizar alguns indicadores sobres as interações dos cidadãos com seu assistente digital, como .. Além disso, você pode criar outras interações do seu assistente digital com os cidadãos.
</p>
<p><b>Criando enquetes</b></p>
<p>Crie enquetes para que as pessoas que interagirem com seu assistente digital possam responder, contribuindo para as tomadas de decisão do gabinete.</p>
<p>É muito simples, é só preencher o nome da enquete, os textos das enquetes e as duas opções de respostas que você queira que o usuário responda. Após preencher os dados, você pode avisar seu assistente digital que ele pode divulgar a enquete, clicando em "Ativar", ou pode salvar a enquete e só liberá-la depois para seu assistente digital, para isso é só tirar a seleção "sim", do campo "Registar enquete ativa?", e quando quiser ativá-lá, é só ir na sessão Minhas Enquetes, selecioná-la e clicar em Ativar.
</p>
<p>Por exemplo:</p>
<p>[Imagem plataforma]</p>
<p>O seu assistente digital enviará assim?</p>
<p>[Imagem plataforma]</p>
<p><b>Enviando notificações</b></p>
<p>Através do Mandato Aberto é possível enviar mensagens diretas aos cidadãos que já interagiram com seu assistente digital, é só você criar seu texto e enviar, e pronto, todos os cidadão que já interagiram com o assistente digital receberão seu mensagem no Facebook Messenger.
</p>
<p>Por exemplo:</p>
<p>[Imagem plataforma]</p>
<p>O seu assistente digital enviará assim?</p>
<p>[Imagem plataforma]</p>
</td>
</tr>
<tr>
<td height="30"></td>
</tr>

<tr>
<td height="30"></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="540" style="border-collapse:collapse">
<tbody>
<tr>
<td align="center" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:11px; font-weight:300; line-height:16px; margin:0; padding:30px 0px">
<span><strong>Mandato Aberto</strong></span>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
</div>
</div></div>
</body>
</html>

@@ premium-active.tt

<!doctype html>
<html>
<head>
<meta charset="UTF-8">
</head>
<body>
<div leftmargin="0" marginheight="0" marginwidth="0" topmargin="0" style="background-color:#f5f5f5; font-family:'Montserrat',Arial,sans-serif; margin:0; padding:0; width:100%">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse">
<tbody>
<tr>
<td>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="600" style="border-collapse:collapse">
<tbody>
<tr>
<td height="50"></td>
</tr>
<tr>
<td bgcolor="#ffffff" colspan="2" style="background-color:rgb(255,255,255); border-radius:0 0 7px 7px; font-family:'Montserrat',Arial,sans-serif; font-size:13px; font-weight:normal; line-height:24px; padding:30px 0; text-align:center; vertical-align:top">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="84%" style="border-collapse:collapse">
<tbody>
<tr>
<td align="justify" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
<p style="text-align: center;"><a href="https://midialibre.org.br/"><img src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/c75c64c5-c400-4c18-9564-16b4a7116b03.png" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></a></p>
<p><b>Olá, [% name %]. </b></p>
<br></span>
</p>
<p> <strong> </strong>Agradecemos seu compromisso em valorizar a imprensa. Seu apoio é fundamental para que, juntos, jornalistas e o público criem uma mídia cada vez mais livre e democrática.</p>
<p>A partir de agora você poderá distribuir seus Libres com facilidade e segurança em toda a rede de veículos e jornalistas que utilizam nossa plataforma.</p>
<p>Em seu perfil em nosso site, você pode acompanhar o balanço de sua conta, consultar e a lista de matérias, artigos e conteúdos que você apoiou.</p>
<p>E fique de olho em nossos informes e atualizações. Libre é uma ferramenta nova e em constante evolução. Ao longo dos próximos meses vamos ampliar nossa rede de veículos, aprimorando o funcionamento e criando novas funcionalidades em nosso site.</p>
<p>Qualquer dúvida procure nosso FAQ ou escreva para nós.
<br><br>A mídia Libre conta com você!</p>
</td>
</tr>
<tr>
<td height="30"></td>
</tr>
<tr>
<td align="justify" style="color:#999999; font-size:13px; font-style:normal; font-weight:normal; line-height:16px">
<strong id="docs-internal-guid-d5013b4e-a1b5-bf39-f677-7dd0712c841b">
<p>Dúvidas? Acesse <a href="https://midialibre.org.br/ajuda/" target="_blank" style="color:#4ab957">Perguntas frequentes</a>.</p>
Equipe Libre
</strong>
<a href="mailto:contato@midialibre.org.br" target="_blank" style="color:#4ab957"></a>
</td>
</tr>
<tr>
<td height="30"></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="540" style="border-collapse:collapse">
<tbody>
<tr>
<td align="center" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:11px; font-weight:300; line-height:16px; margin:0; padding:30px 0px">
<span><strong>Libre</strong></span>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
</div>
</div></div>
</body>
</html>

@@ premium-inactive.tt

<!doctype html>
<html>
<head>
<meta charset="UTF-8">
</head>
<body>
<div leftmargin="0" marginheight="0" marginwidth="0" topmargin="0" style="background-color:#f5f5f5; font-family:'Montserrat',Arial,sans-serif; margin:0; padding:0; width:100%">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse">
<tbody>
<tr>
<td>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="600" style="border-collapse:collapse">
<tbody>
<tr>
<td height="50"></td>
</tr>
<tr>
<td bgcolor="#ffffff" colspan="2" style="background-color:rgb(255,255,255); border-radius:0 0 7px 7px; font-family:'Montserrat',Arial,sans-serif; font-size:13px; font-weight:normal; line-height:24px; padding:30px 0; text-align:center; vertical-align:top">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="84%" style="border-collapse:collapse">
<tbody>
<tr>
<td align="justify" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
<p style="text-align: center;"><a href="https://midialibre.org.br/"><img src="https://gallery.mailchimp.com/af2df78bcac96c77cfa3aae07/images/c75c64c5-c400-4c18-9564-16b4a7116b03.png" class="x_deviceWidth" style="border-radius:7px 7px 0 0; align: center"></a></p>
<p><b>Olá, [% name %]. </b></p>
<br></span>
</p>
<p> <strong> </strong>Agradecemos seu compromisso em valorizar a imprensa. Seu apoio é fundamental para que, juntos, jornalistas e o público criem uma mídia cada vez mais livre e democrática.</p>
<p>A partir de agora você poderá distribuir seus Libres com facilidade e segurança em toda a rede de veículos e jornalistas que utilizam nossa plataforma.</p>
<p>Em seu perfil em nosso site, você pode acompanhar o balanço de sua conta, consultar e a lista de matérias, artigos e conteúdos que você apoiou.</p>
<p>E fique de olho em nossos informes e atualizações. Libre é uma ferramenta nova e em constante evolução. Ao longo dos próximos meses vamos ampliar nossa rede de veículos, aprimorando o funcionamento e criando novas funcionalidades em nosso site.</p>
<p>Qualquer dúvida procure nosso FAQ ou escreva para nós.
<br><br>A mídia Libre conta com você!</p>
</td>
</tr>
<tr>
<td height="30"></td>
</tr>
<tr>
<td align="justify" style="color:#999999; font-size:13px; font-style:normal; font-weight:normal; line-height:16px">
<strong id="docs-internal-guid-d5013b4e-a1b5-bf39-f677-7dd0712c841b">
<p>Dúvidas? Acesse <a href="https://midialibre.org.br/ajuda/" target="_blank" style="color:#4ab957">Perguntas frequentes</a>.</p>
Equipe Libre
</strong>
<a href="mailto:contato@midialibre.org.br" target="_blank" style="color:#4ab957"></a>
</td>
</tr>
<tr>
<td height="30"></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="540" style="border-collapse:collapse">
<tbody>
<tr>
<td align="center" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:11px; font-weight:300; line-height:16px; margin:0; padding:30px 0px">
<span><strong>Libre</strong></span>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
</div>
</div></div>
</body>
</html>