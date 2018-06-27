use utf8;
package MandatoAberto::Schema::Result::PrivateReply;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PrivateReply

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

=head1 TABLE: C<private_reply>

=cut

__PACKAGE__->table("private_reply");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'private_reply_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 item

  data_type: 'text'
  is_nullable: 0

=head2 post_id

  data_type: 'text'
  is_nullable: 0

=head2 comment_id

  data_type: 'text'
  is_nullable: 1

=head2 permalink

  data_type: 'text'
  is_nullable: 1

=head2 reply_sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 fb_user_id

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "private_reply_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "item",
  { data_type => "text", is_nullable => 0 },
  "post_id",
  { data_type => "text", is_nullable => 0 },
  "comment_id",
  { data_type => "text", is_nullable => 1 },
  "permalink",
  { data_type => "text", is_nullable => 1 },
  "reply_sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "fb_user_id",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 politician

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Politician>

=cut

__PACKAGE__->belongs_to(
  "politician",
  "MandatoAberto::Schema::Result::Politician",
  { user_id => "politician_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-06-13 14:38:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5zOjuEq5FaNSB5szzpO6vA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use WebService::HttpCallback::Async;

use JSON::MaybeXS;
use URI::Escape;
use DateTime;
use DateTime::Format::DateParse;
use DateTime::Format::Pg;
use MandatoAberto::Utils qw/is_test/;

has _httpcb => (
    is         => "ro",
    isa        => "WebService::HttpCallback::Async",
    lazy_build => 1,
);

sub send {
    my ($self) = @_;

    # Valido se o político está com as private replies ativas
    # e também se não está dentro da janela de 'delay'
    my $politician           = $self->politician;
    my $private_reply_config = $politician->politician_private_reply_config;

    if ( $private_reply_config->active ) {

        my $private_reply_rs        = $self->result_source->schema->resultset("PrivateReply");
        my $last_sent_private_reply = $private_reply_rs->get_last_sent_private_reply( $self->politician_id, $self->fb_user_id );

        if ( $last_sent_private_reply ) {
            my $ts  = DateTime::Format::DateParse->parse_datetime( $last_sent_private_reply->created_at );
            my $now = DateTime->now();
            my $delay_between_private_replies = DateTime::Format::Pg->parse_interval($private_reply_config->delay_between_private_replies);

            my $now_minus_delay = $now->subtract_duration($delay_between_private_replies);

            my $flag = DateTime->compare( $now_minus_delay, $ts );

            return 1 unless $flag == 1;
        }

        my $access_token = $politician->fb_page_access_token;

        my $politician_name = $politician->name;
        my $office_name     = $politician->office->name;
        my $article         = $politician->gender eq 'F' ? 'da' : 'do';

        my $item_id = $self->comment_id ? $self->comment_id : $self->post_id;

        if ( is_test() ) {
            $self->update( { reply_sent => 1 } );
            return 1;
        } else {
            $self->_httpcb->add(
                url     => "$ENV{FB_API_URL}/$item_id/private_replies?access_token=$access_token",
                method  => "post",
                headers => 'Content-Type: application/json',
                body    => encode_json {
                    message => "Sou o Assistente virtual $article $office_name $politician_name. Sou um robô que vai te ajudar a conhecer nosso trabalho e entregar mensagens para nossa equipe.\n\nVi que você realizou um comentário em nossa página. Se quiser enviar uma mensagem para nossa equipe ou saber mais sobre nosso trabalho, digite 'Sim'."
                }
            );

            $self->update( { reply_sent => 1 } );
        }

    }

    return 1;
}

sub _build__httpcb { WebService::HttpCallback::Async->instance }

__PACKAGE__->meta->make_immutable;
1;
