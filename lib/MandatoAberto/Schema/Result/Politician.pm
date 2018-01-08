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

=head2 fb_app_id

  data_type: 'text'
  is_nullable: 1

=head2 fb_app_secret

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
  "fb_app_id",
  { data_type => "text", is_nullable => 1 },
  "fb_app_secret",
  { data_type => "text", is_nullable => 1 },
  "fb_page_access_token",
  { data_type => "text", is_nullable => 1 },
  "gender",
  { data_type => "text", is_nullable => 0 },
  "address_state_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "address_city_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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

=head2 citizens

Type: has_many

Related object: L<MandatoAberto::Schema::Result::Citizen>

=cut

__PACKAGE__->has_many(
  "citizens",
  "MandatoAberto::Schema::Result::Citizen",
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

=head2 politician_chatbots

Type: has_many

Related object: L<MandatoAberto::Schema::Result::PoliticianChatbot>

=cut

__PACKAGE__->has_many(
  "politician_chatbots",
  "MandatoAberto::Schema::Result::PoliticianChatbot",
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-12-07 14:21:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bpDsUPY/YM06w1geau51mA


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
                fb_app_id => {
                    required   => 0,
                    type       => "Str",
                },
                fb_app_secret => {
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
                $self->set_get_started_button($values{fb_page_access_token});
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

sub set_get_started_button {
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
            }
        }
    );
    die $res->decoded_content unless $res->is_success;

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
    die $res->decoded_content unless $res->is_success;

    my $decoded_res = decode_json $res->decoded_content;
    my $untreated_data = $decoded_res->{data}->[0]->{values};
    my $treated_data = {};

    for (my $i = 0; $i < scalar @{ $untreated_data } ; $i++) {
        my $data_per_day = $untreated_data->[$i];

        my $day = DateTime::Format::DateParse->parse_datetime($data_per_day->{end_time});

        $treated_data->{labels}->[$i] = $day->day() . '/' . $day->month();
        $treated_data->{datasets}->[$i]->{label} = $treated_data->{labels}->[$i];
        $treated_data->{datasets}->[$i]->{data}  = $data_per_day->{value};
    }
    
    return $treated_data;
}

__PACKAGE__->meta->make_immutable;
1;
