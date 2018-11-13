use utf8;
package MandatoAberto::Schema::Result::DirectMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::DirectMessage

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

=head1 TABLE: C<direct_message>

=cut

__PACKAGE__->table("direct_message");

=head1 ACCESSORS

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 campaign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 quick_replies

  data_type: 'json'
  is_nullable: 1

=head2 attachment_type

  data_type: 'text'
  is_nullable: 1

=head2 attachment_template

  data_type: 'text'
  is_nullable: 1

=head2 attachment_url

  data_type: 'text'
  is_nullable: 1

=head2 saved_attachment_id

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "content",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "campaign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "quick_replies",
  { data_type => "json", is_nullable => 1 },
  "attachment_type",
  { data_type => "text", is_nullable => 1 },
  "attachment_template",
  { data_type => "text", is_nullable => 1 },
  "attachment_url",
  { data_type => "text", is_nullable => 1 },
  "saved_attachment_id",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</campaign_id>

=back

=cut

__PACKAGE__->set_primary_key("campaign_id");

=head1 RELATIONS

=head2 campaign

Type: belongs_to

Related object: L<MandatoAberto::Schema::Result::Campaign>

=cut

__PACKAGE__->belongs_to(
  "campaign",
  "MandatoAberto::Schema::Result::Campaign",
  { id => "campaign_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-10-24 10:54:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SsbopSvFw+r9hZ/WKZMWkg


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use JSON::MaybeXS;

sub groups_rs {
    my ($self) = @_;

    return $self->campaign->politician->groups->search(
        { 'me.id' => { 'in' => $self->campaign->groups || [] } }
    );
}

sub message_type {
    my ($self) = @_;

    my $ret;
    if ( $self->content && !$self->saved_attachment_id && !$self->attachment_url ) {
        # Mensagem apenas de texto
        $ret = 'text';
    }
    elsif ( $self->saved_attachment_id && $self->attachment_type && !$self->content ) {
        # Mensagem apenas de mídia (midia no FB)
        $ret = 'attachment_on_fb';
    }
    elsif ( $self->attachment_url && $self->attachment_type && !$self->content ) {
        # Mensagem apenas de mídia (midia via URL)
        $ret = 'attachment_on_web';
    }
    elsif ( $self->content && ( $self->saved_attachment_id || $self->attachment_url ) ) {
        # Mensagem de texto e midia
        $ret = 'text_and_attachment';
    }
    else {
        die 'failed to identify message type';
    }

    return $ret;
}

sub build_message_object {
    my ($self) = @_;

    my $message_type = $self->message_type;

    my $ret;
    if ( $message_type eq 'text' || $message_type eq 'text_and_attachment' ) {
        # Esse if verifica por tanto text quanto por text_and_attachment
        # pois o text_and_attachment uma requisição será enviada apenas com a mensagem de texto
        # e depois uma requisição será enviada apenas com a mídia (thanks facebook).
        $ret = {
            text => $self->content,
            quick_replies => [
                {
                    content_type => 'text',
                    title        => "Voltar para o início",
                    payload      => 'greetings'
                }
            ]
        };

    }
    elsif ( $message_type eq 'attachment_on_fb' ) {

        # É attachment logo pode ser video, imagem ou template
        # Obs: quando há o saved_attachment_id significa que recebemos o arquivo
        # e o enviamos para o Facebook hospedar.
        if ( $self->attachment_type ne 'template' ) {
            $ret = {
                attachment => {
                    type    => $self->attachment_type,
                    payload => {
                        attachment_id => $self->saved_attachment_id
                    }
                },
                quick_replies   => [
                    {
                        content_type => 'text',
                        title        => "Voltar para o início",
                        payload      => 'greetings'
                    }
                ]
            };
        }
        else {

            # É um template
            $ret = {
                attachment_type => $self->attachment_type,
                template        => $self->template,
                quick_replies   => [
                    {
                        content_type => 'text',
                        title        => "Voltar para o início",
                        payload      => 'greetings'
                    }
                ]
            };
        }

    }
    elsif ( $message_type eq 'attachment_on_web' ) {
        # TODO
    }
    else {
        die 'invalid direct_message, check manually';
    }

    return $ret;
}

sub build_headers {
    my ($self, $recipient) = @_;

    my $message_type = $self->message_type;

    my $ret;
    if ( $message_type eq 'text_and_attachment' ) {

        my $attachment_req = encode_json {
            url     => $ENV{FB_API_URL} . '/me/messages?access_token=' . $self->campaign->politician->fb_page_access_token,
            method  => "post",
            headers => 'Content-Type: application/json',
            body    => {
                messaging_type => "UPDATE",
                recipient => {
                    id => $recipient->fb_id
                },
                message => {
                    attachment => {
                        type    => $self->attachment_type,
                        payload => {
                            attachment_id => $self->saved_attachment_id
                        }
                    },
                    quick_replies   => [
                        {
                            content_type => 'text',
                            title        => "Voltar para o início",
                            payload      => 'greetings'
                        }
                    ]
                }
            }
        };

        $ret = "Content-Type: application/json\nnext_req: $attachment_req";
    }
    else {
        $ret = 'Content-Type: application/json'
    }

    return $ret;
}

__PACKAGE__->meta->make_immutable;
1;
