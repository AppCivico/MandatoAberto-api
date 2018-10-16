use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

use DateTime;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    # Criando diálogo para ser preenchido
    my $dialog      = create_dialog();
    $dialog         = $schema->resultset('Dialog')->find( $dialog->{id} );
    my $dialog_name = $dialog->name;

    my $question = create_question( dialog_id => $dialog->id );
    $question    = $schema->resultset('Question')->find( $question->{id} );

    my $politician = create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = $politician->{id};
    $politician       = $schema->resultset('Politician')->find($politician_id);

    $politician->user->update( { approved => 1 } );

    my $recipient = create_recipient(
        name          => 'foo',
        politician_id => $politician_id
    );
    $recipient = $schema->resultset('Recipient')->find($recipient->{id});

    my $log_rs = $schema->resultset('Log');

    my $issue;

    subtest 'Politician | Create logs' => sub {
        api_auth_as user_id => $politician_id;

        subtest 'Edit profile' => sub {
            rest_put "/api/politician/$politician_id",
                name => 'update politician',
                [ name => 'foobar' ]
            ;

            is( $log_rs->count, 1, 'one log entry' );
            ok( my $profile_log = $log_rs->search( { action_id => 9 } )->next, 'profile update log' );

            is( $profile_log->field_id,      undef,          'profile log does not have field_id' );
            is( $profile_log->recipient_id,  undef,          'profile log does not have recipient_id' );
            is( $profile_log->politician_id, $politician_id, 'profile log politician_id' );

            rest_get "/api/politician/$politician_id/logs/admin",
                name  => 'get admin logs',
                stash => 'get_admin_logs',
                list  => 1,
            ;

            stash_test 'get_admin_logs' => sub {
                my $res = shift;

                is( ref $res->{logs}, 'ARRAY', 'logs is an array' );

                ok( my $log = $res->{logs}->[0], 'first log' );
                ok( defined $log->{created_at},  'log has created_at param' );
                ok( defined $log->{description}, 'log has description param' );

                ok( $log->{description} eq 'foobar atualizou o perfil.', 'description ok' );
            }
        };

        subtest 'Create/update greetings' => sub {
            rest_post "/api/politician/$politician_id/greeting",
                name                => 'politician greeting',
                automatic_load_item => 1,
                code                => 200,
                [
                    on_facebook => 'foobar',
                    on_website  => 'foobar2'
                ]
            ;

            is( $log_rs->count, 2, 'two log entries' );
            ok( my $profile_log = $log_rs->search( { action_id => 10 } )->next, 'greetings update log' );

            is( $profile_log->field_id,      undef,          'greetings log does not have field_id' );
            is( $profile_log->recipient_id,  undef,          'greetings log does not have recipient_id' );
            is( $profile_log->politician_id, $politician_id, 'greetings log politician_id' );

            rest_reload_list 'get_admin_logs';
            stash_test 'get_admin_logs.list' => sub {
                my $res = shift;

                ok( my $log = $res->{logs}->[1], 'log' );

                ok( $log->{description} eq 'foobar atualizou as boas-vindas.', 'description ok' );
            }
        };

        subtest 'Create/update contacts' => sub {
            rest_post "/api/politician/$politician_id/contact",
                name                => "politician contact",
                automatic_load_item => 0,
                code                => 200,
                [
                    twitter  => '@lucas_ansei',
                    facebook => 'https://facebook.com/lucasansei',
                    email    => 'foobar@email.com',
                    url      => 'https://www.google.com'
                ]
            ;

            is( $log_rs->count, 3, 'three log entries' );
            ok( my $profile_log = $log_rs->search( { action_id => 11 } )->next, 'contact update log' );

            is( $profile_log->field_id,      undef,          'contact log does not have field_id' );
            is( $profile_log->recipient_id,  undef,          'contact log does not have recipient_id' );
            is( $profile_log->politician_id, $politician_id, 'contact log politician_id' );

            rest_reload_list 'get_admin_logs';
            stash_test 'get_admin_logs.list' => sub {
                my $res = shift;

                ok( my $log = $res->{logs}->[2], 'log' );

                ok( $log->{description} eq 'foobar atualizou os contatos.', 'description ok' );
            }
        };

        subtest 'Create/update answers' => sub {
            answer_question(
                politician_id => $politician_id,
                question_id   => $question->id
            );

            is( $log_rs->count, 4, 'four log entries' );
            ok( my $profile_log = $log_rs->search( { action_id => 12 } )->next, 'answer update/create log' );

            ok( defined $profile_log->field_id, 'answer log field_id' );
            is( $profile_log->recipient_id,  undef,          'answer log does not have recipient_id' );
            is( $profile_log->politician_id, $politician_id, 'answer log politician_id' );

            rest_reload_list 'get_admin_logs';
            stash_test 'get_admin_logs.list' => sub {
                my $res = shift;

                ok( my $log = $res->{logs}->[3], 'log' );

                ok( $log->{description} eq "foobar atualizou o diálogo: '$dialog_name'.", 'description ok' );
            }
        };

        subtest 'Create/update knowledge base' => sub {

            my ($entity, $entity_name);
            subtest 'Chatbot | Create issue' => sub {
                $issue = create_issue(
                    politician_id => $politician_id,
                    fb_id         => $recipient->fb_id
                );
                $issue = $schema->resultset('Issue')->find($issue->{id});

                ok(
                    $entity = $schema->resultset('PoliticianEntity')->search( { politician_id => $politician_id } )->next,
                    'politician entity'
                );

                $entity_name = $entity->human_name;
            };

            my $knowledge_base = create_knowledge_base(
                politician_id => $politician_id,
                entity_id     => $entity->id
            );
            $knowledge_base = $schema->resultset('PoliticianKnowledgeBase')->find( $knowledge_base->{id} );

            is( $log_rs->count, 5, 'five log entries' );
            ok( my $profile_log = $log_rs->search( { action_id => 13 } )->next, 'knowledge base update/create log' );

            ok( defined $profile_log->field_id, 'answer log field_id' );
            is( $profile_log->recipient_id,  undef,          'answer log does not have recipient_id' );
            is( $profile_log->politician_id, $politician_id, 'answer log politician_id' );

            rest_reload_list 'get_admin_logs';
            stash_test 'get_admin_logs.list' => sub {
                my $res = shift;

                ok( my $log = $res->{logs}->[4], 'log' );

                ok( $log->{description} eq "foobar atualizou a resposta do tipo '$entity_name' para o tema: '$entity_name'.", 'description ok' );
            }
        };
};

done_testing();