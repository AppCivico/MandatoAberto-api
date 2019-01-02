use utf8;
package MandatoAberto::Schema::Result::PoliticianVotolegalIntegration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MandatoAberto::Schema::Result::PoliticianVotolegalIntegration

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

=head1 TABLE: C<politician_votolegal_integration>

=cut

__PACKAGE__->table("politician_votolegal_integration");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'politician_votolegal_integration_id_seq'

=head2 politician_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 votolegal_id

  data_type: 'integer'
  is_nullable: 0

=head2 votolegal_email

  data_type: 'text'
  is_nullable: 0

=head2 website_url

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 greeting

  data_type: 'text'
  is_nullable: 1

=head2 custom_url

  data_type: 'text'
  is_nullable: 1

=head2 active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politician_votolegal_integration_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "votolegal_id",
  { data_type => "integer", is_nullable => 0 },
  "votolegal_email",
  { data_type => "text", is_nullable => 0 },
  "website_url",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "username",
  { data_type => "text", is_nullable => 0 },
  "greeting",
  { data_type => "text", is_nullable => 1 },
  "custom_url",
  { data_type => "text", is_nullable => 1 },
  "active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-09-26 10:44:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AePOHmbZS7fjf1zYc5wNgw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

use MandatoAberto::Utils qw/is_test/;

use Furl;
use JSON::MaybeXS;

sub update_votolegal_integration {
    my ($self) = @_;

    my $security_token = $ENV{VOTOLEGAL_SECURITY_TOKEN};
    die \['missing env', 'VOTOLEGAL_SECURITY_TOKEN'] unless $security_token;

    my $furl = Furl->new();

    my $res;
    if ( is_test() ) {
        $res = $MandatoAberto::Test::votolegal_response;
    }
    else {
        $res = $furl->post(
            $ENV{VOTOLEGAL_API_URL} . '/candidate/mandatoaberto_integration',
            [],
            {
                page_id          => $self->politician->fb_page_id,
                security_token   => $security_token,
                email            => $self->votolegal_email,
                mandatoaberto_id => $self->politician_id,
                greeting         => $self->greeting
            }
        );
        die \['votolegal_email', 'non existent on voto legal'] unless $res->is_success;

        $res = decode_json $res->decoded_content;
    }

    die \['invalid response', 'id'] if !$res->{id} || !$res->{username};

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
