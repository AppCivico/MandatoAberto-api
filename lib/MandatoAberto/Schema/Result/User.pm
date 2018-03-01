use utf8;
package MandatoAberto::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_id_seq'

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 password

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 approved

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 approved_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 confirmed

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 confirmed_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_id_seq",
  },
  "email",
  { data_type => "text", is_nullable => 0 },
  "password",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "approved",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "approved_at",
  { data_type => "timestamp", is_nullable => 1 },
  "confirmed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "confirmed_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("user_email_key", ["email"]);

=head1 RELATIONS

=head2 politician

Type: might_have

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->might_have(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_confirmations

Type: has_many

Related object: L<MandatoAberto::Schema::Result::UserConfirmation>

=cut

__PACKAGE__->has_many(
  "user_confirmations",
  "MandatoAberto::Schema::Result::UserConfirmation",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_forgot_passwords

Type: has_many

Related object: L<MandatoAberto::Schema::Result::UserForgotPassword>

=cut

__PACKAGE__->has_many(
  "user_forgot_passwords",
  "MandatoAberto::Schema::Result::UserForgotPassword",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<MandatoAberto::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "MandatoAberto::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_sessions

Type: has_many

Related object: L<MandatoAberto::Schema::Result::UserSession>

=cut

__PACKAGE__->has_many(
  "user_sessions",
  "MandatoAberto::Schema::Result::UserSession",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-02-28 21:49:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RbfhRtgVoY/6rRy5TJRjdg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->remove_column("password");
__PACKAGE__->add_column(
    password => {
        data_type        => "text",
        passphrase       => 'crypt',
        passphrase_class => "BlowfishCrypt",
        passphrase_args  => {
            cost        => 8,
            salt_random => 1,
        },
        passphrase_check_method => "check_password",
        is_nullable             => 0,
    },
);

use MandatoAberto::Mailer::Template;
use MandatoAberto::Utils;

use Digest::SHA1 qw(sha1_hex);
use Digest::SHA qw(sha256_hex);

sub new_session {
    my ($self) = @_;

    my $schema = $self->result_source->schema;

    my $session = $schema->resultset('UserSession')->search({
        user_id      => $self->id,
        valid_until  => { '>=' => \"NOW()" },
    })->next;

    my $roles = [ map { $_->name } $self->roles ];

    if ( !defined($session) ) {
        $session = $self->user_sessions->create({
            api_key      => random_string(128),
            valid_until  => \"(NOW() + '20 minutes'::interval)",
        });
    }

    return {
        user_id => $self->id,
        roles   => [ map { $_->name } $self->roles ],
        api_key => $session->api_key,
    };
}

sub send_email_forgot_password {
    my ($self, $token) = @_;

    my $email = MandatoAberto::Mailer::Template->new(
        to       => $self->email,
        from     => 'no-reply@mandatoaberto.org.br',
        subject  => "Mandato Aberto - Recuperação de senha",
        template => get_data_section('forgot_password.tt'),
        vars     => {
            name  => $self->politician->name,
            token => $token,
        },
    )->build_email();

    my $queued = $self->result_source->schema->resultset("EmailQueue")->create({ body => $email->as_string });

    return $queued;
}

sub send_email_approved {
    my ($self) = @_;

    my $email = MandatoAberto::Mailer::Template->new(
        to       => $self->email,
        from     => 'no-reply@mandatoaberto.com.br',
        subject  => "Mandato Aberto - Boas vindas",
        template => get_data_section('approved.tt'),
        vars     => { name  => $self->politician->name },
    )->build_email();

    return $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
}

sub send_email_confirmation {
    my ($self) = @_;

    my $user_confirmation = $self->user_confirmations->create({
        token       => sha1_hex(Time::HiRes::time()),
        valid_until => \"(NOW() + '3 days'::interval)",
    });

    my $email = MandatoAberto::Mailer::Template->new(
        to       => $self->email,
        from     => 'no-reply@mandatoaberto.com.br',
        subject  => "Mandato Aberto - Confirmação de cadastro",
        template => get_data_section('register_confirmation.tt'),
        vars     => {
            name  => $self->politician->name,
            token => $user_confirmation->token,
        },
    )->build_email();

    return $self->result_source->schema->resultset('EmailQueue')->create({ body => $email->as_string });
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__

@@ approved.tt

<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html charset=UTF-8">
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

@@ forgot_password.tt

<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html charset=UTF-8">
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
<p><b>Olá, [% name %]. </b></p>
<p> <strong> </strong>Recebemos a sua solicitação para uma nova senha de acesso ao Mandato Aberto.
É muito simples, clique no botão abaixo para trocar sua senha.</p>
  </td>
</tr>
<tr>
<td height="30"></td>
</tr>
<tr>
<td align="center" bgcolor="#ffffff" valign="top" style="padding-top:20px">
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border-collapse:separate; border-radius:7px; margin:0">
<tbody>
<tr>
<td align="center" valign="middle"><a href="http://devcp.mandatoaberto.com.br/reset-password/[% token %]" target="_blank" class="x_btn" style="background:#B04783; border-radius:8px; color:#ffffff; font-family:'Montserrat',Arial,sans-serif; font-size:15px; padding:16px 24px 15px 24px; text-decoration:none; text-transform:uppercase"><strong>TROCAR MINHA SENHA</strong></a></td>
</tr>
</tbody>
</table>
</td>
</tr>
<tr>
<td height="40"></td>
</tr>
<tr>
<td align="justify" style="color:#999999; font-size:13px; font-style:normal; font-weight:normal; line-height:16px"><strong id="docs-internal-guid-d5013b4e-a1b5-bf39-f677-7dd0712c841b">
  <p>Caso você não tenha solicitado esta alteração de senha, por favor desconsidere esta mensagem, nenhuma alteração foi feita na sua conta.</p>
  Equipe Mandato Aberto</strong><a href="mailto:contato@mandatoaberto.org.br" target="_blank" style="color:#4ab957"></a></td>
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
<span><strong>Mandato Aberto</strong></span></td>
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

@@ register_confirmation.tt

<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html charset=UTF-8">
</head>
<body>
<div leftmargin="0" marginheight="0" marginwidth="0" topmargin="0" style="background-color:#f5f5f5; font-family:'Montserrat',Arial,sans-serif; margin:0; padding:0; width:100%">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse">
<tbody>
<tr>
<td>
<table align="center" border="0" cellpadding="0" cellspacing="0" class="x_deviceWidth" width="600" style="border-collapse:collapse">
<tbody>
<td colspan="2"><img src="https://saveh.com.br/images/emails/header.jpg" class="x_deviceWidth" style="border-radius:7px 7px 0 0; float:left"></td>
</tr>
<tr>
<td bgcolor="#ffffff" colspan="2" style="background-color:rgb(255,255,255); border-radius:0 0 7px 7px; font-family:'Montserrat',Arial,sans-serif; font-size:13px; font-weight:normal; line-height:24px; padding:30px 0; text-align:center; vertical-align:top">
<table align="center" border="0" cellpadding="0" cellspacing="0" width="84%" style="border-collapse:collapse">
<tbody>
<tr>
  <td align="justify" style="color:#666666; font-family:'Montserrat',Arial,sans-serif; font-size:16px; font-weight:300; line-height:23px; margin:0">
    <p><span><b>Bem vindo, [% name %]!</b><br>
      <br></span></p>
    <p><strong></strong>Para que você possa utilizar a plataforma é necessário que você confirme o seu cadastro.</p>
  </td>
</tr>
<tr>
<td align="center" bgcolor="#ffffff" valign="top" style="padding-top:20px">
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border-collapse:separate; border-radius:7px; margin:0">
<tbody>
<tr>
<td align="center" valign="middle"><a href="https://saveh.com.br/account/validate/?token=[% token %]" target="_blank" class="x_btn" style="background:#3ad8f1; border-radius:8px; color:#ffffff; font-family:'Montserrat',Arial,sans-serif; font-size:15px; padding:16px 24px 15px 24px; text-decoration:none; text-transform:uppercase"><strong>CONFIRMAR</strong></a></td>
</tr>
</tbody>
</table>
</td>
</tr>
<tr>
<td height="40"></td>
</tr>
<tr>
<td align="justify" style="color:#999999; font-size:13px; font-style:normal; font-weight:normal; line-height:16px"><strong id="docs-internal-guid-d5013b4e-a1b5-bf39-f677-7dd0712c841b">
  <p>Caso você não tenha realizado o cadastro e tenha recebido este e-mail por engano, por favor desconsidere esta mensagem.</p>
  <p>Equipe Saveh</p></strong></td>
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
<span><strong>Saveh</strong></span></td>
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