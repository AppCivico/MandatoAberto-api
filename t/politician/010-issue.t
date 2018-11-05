use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    my $security_token = $ENV{CHATBOT_SECURITY_TOKEN};

    my $recipient_fb_id = fake_words(1)->();
    my $message         = fake_words(1)->();

    my $issue_rs = $schema->resultset('Issue');

    create_politician(
        fb_page_id           => fake_words(1)->(),
        fb_page_access_token => fake_words(1)->()
    );
    my $politician_id = stash "politician.id";

    rest_post "/api/chatbot/recipient",
        name                => "create recipient",
        automatic_load_item => 0,
        stash               => 'r1',
        [
            origin_dialog  => fake_words(1)->(),
            politician_id  => $politician_id,
            name           => fake_name()->(),
            fb_id          => $recipient_fb_id,
            email          => fake_email()->(),
            cellphone      => fake_digits("+551198#######")->(),
            gender         => fake_pick( qw/F M/ )->(),
            security_token => $security_token
        ]
    ;

    my $recipient = $schema->resultset("Recipient")->find(stash "r1.id");

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i1",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => $message,
            security_token => $security_token,
            entities       => encode_json(
                {
                    id        => 'a8736300-e5b3-4ab8-a29e-c379ef7f61de',
                    timestamp => '2018-09-19T21 => 39 => 43.452Z',
                    lang      => 'pt-br',
                    result    => {
                        source           => 'agent',
                        resolvedQuery    => 'O que você acha do aborto?',
                        action           => '',
                        actionIncomplete => 0,
                        parameters       => {},
                        contexts         => [],
                        metadata         => {
                            intentId                  => '4c3f7241-6990-4c92-8332-cfb8d437e3d1',
                            webhookUsed               => 0,
                            webhookForSlotFillingUsed => 0,
                            isFallbackIntent          => 0,
                            intentName                => 'direitos_animais'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
                }
            )
        ]
    ;
    my $first_issue_id = stash "i1.id";
    my $first_issue    = $issue_rs->find($first_issue_id);

    rest_get "/api/politician/$politician_id/issue",
        name    => "get issues without login",
        is_fail => 1,
        code    => 403
    ;

    api_auth_as "user_id" => $politician_id;

    rest_get "/api/politician/$politician_id/issue",
        name  => "get issues",
        list  => 1,
        stash => "get_issues",
        [ filter => 'open' ]
    ;

    stash_test "get_issues" => sub {
        my $res = shift;

        ok( defined $res->{itens_count}, 'itens_count is defined' );

        is ($res->{issues}->[0]->{message}, $message, 'issue message');
        is ($res->{issues}->[0]->{open},  1, 'issue status');
        is ($res->{issues}->[0]->{reply}, undef, 'issue reply');
        is ($res->{issues}->[0]->{updated_at}, undef, 'issue updated timestamp');
        is ($res->{issues}->[0]->{ignored}, 0, 'issue is not ignored');
        is ($res->{issues}->[0]->{replied}, 0, 'issue is not replied');
    };

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue with reply with more than 2000 chars",
        is_fail => 1,
        code    => 400,
        [ reply => fake_paragraphs(100)->() ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "ignoring issue without flag",
        is_fail => 1,
        code    => 400,
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue (ignoring) with reply",
        is_fail => 1,
        code    => 400,
        [
            ignore => 1,
            reply  => 'foobar'
        ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name => "updating issue without reply",
        [ ignore => 1 ]
    ;

    rest_put "/api/politician/$politician_id/issue/$first_issue_id",
        name    => "updating issue alredy closed",
        is_fail => 1,
        code    => 400
    ;

    rest_get "/api/politician/$politician_id/issue/$first_issue_id",
        name  => "get only one issue",
        stash => 'r1'
    ;

    stash_test 'r1' => sub {
        my $res = shift;

        is ( $res->{ignored}, 1, 'issue was ignored' );
    };

    # Testando issue com conteúdo "Participar"
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i9",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => 'Participar',
            security_token => $security_token
        ]
    ;

    rest_reload_list 'get_issues';
    stash_test 'get_issues.list' => sub {
        my $res = shift;

        is ( scalar @{ $res->{issues} }, 0, 'no open issues' );
    };

    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i2",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
            entities       => encode_json(
                {
                    id        => 'a8736300-e5b3-4ab8-a29e-c379ef7f61de',
                    timestamp => '2018-09-19T21 => 39 => 43.452Z',
                    lang      => 'pt-br',
                    result    => {
                        source           => 'agent',
                        resolvedQuery    => 'O que você acha do aborto?',
                        action           => '',
                        actionIncomplete => 0,
                        parameters       => {},
                        contexts         => [],
                        metadata         => {
                            intentId                  => '4c3f7241-6990-4c92-8332-cfb8d437e3d1',
                            webhookUsed               => 0,
                            webhookForSlotFillingUsed => 0,
                            isFallbackIntent          => 0,
                            intentName                => 'direitos_animais'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
                }
            )
        ]
    ;
    my $second_issue_id = stash "i2.id";
    my $second_issue    = $issue_rs->find($second_issue_id);

    # Testando batch ignore de issues
    db_transaction{
        $first_issue->update( { reply => undef, open => 1 } );
        $second_issue->update( { reply => undef, open => 1 } );

        $first_issue  = $first_issue->discard_changes;
        $second_issue = $second_issue->discard_changes;

        rest_put "/api/politician/$politician_id/issue/batch-ignore",
            name    => 'batch ignore without ids',
            is_fail => 1,
            code    => 400
        ;

        rest_put "/api/politician/$politician_id/issue/batch-ignore",
            name => 'batch ignore',
            code => 200,
            [ ids => "$first_issue_id, $second_issue_id" ]
        ;

        rest_get "/api/politician/$politician_id/issue",
            name  => 'get ignored issues',
            stash => 'get_ignored_issues',
            list  => 1,
            [ filter => 'ignored' ]
        ;

        stash_test 'get_ignored_issues' => sub {
            my $res = shift;

            is( scalar @{ $res->{issues} }, 2, '2 ignored issues' );
        }
    };

    # Testando batch delete de issues
    db_transaction{
        $first_issue->update( { reply => undef, open => 1 } );
        $second_issue->update( { reply => undef, open => 1 } );

        $first_issue  = $first_issue->discard_changes;
        $second_issue = $second_issue->discard_changes;

        rest_put "/api/politician/$politician_id/issue/batch-delete",
          name    => 'batch delete without ids',
          is_fail => 1,
          code    => 400;

        rest_put "/api/politician/$politician_id/issue/batch-delete",
          name => 'batch delete',
          code => 200,
          [ ids => "$first_issue_id, $second_issue_id" ];

        rest_get "/api/politician/$politician_id/issue",
          name  => 'get deleted issues',
          stash => 'get_deleted_issues',
          list  => 1,
          [ filter => 'open' ];

        stash_test 'get_deleted_issues' => sub {
            my $res = shift;

            is( scalar @{ $res->{issues} }, 0, '0 issues' );
          }
    };

    # Criando um grupo para adicionar o recipiente
    # no fechamento da segunda issue
    my $group = $schema->resultset("Group")->create(
        {
            politician_id    => $politician_id,
            name             => 'foobar',
            filter           => '{}',
            status           => 'ready',
            recipients_count => 0
        }
    );

    my $group_id = $group->id;

    # Fechando uma issue e segmentando o recipient
    rest_put "/api/politician/$politician_id/issue/$second_issue_id",
        name => "updating issue without reply",
        [
            ignore => 0,
            groups => "[$group_id]",
            reply  => fake_words(1)->()
        ]
    ;

    is ($group->discard_changes->recipients_count, 1, 'one recipient on group');

    # Respondendo issue com mídia
    rest_post "/api/chatbot/issue",
        name                => "issue creation",
        automatic_load_item => 0,
        stash               => "i3",
        [
            politician_id  => $politician_id,
            fb_id          => $recipient_fb_id,
            message        => fake_words(1)->(),
            security_token => $security_token,
            entities       => encode_json(
                {
                    id        => 'a8736300-e5b3-4ab8-a29e-c379ef7f61de',
                    timestamp => '2018-09-19T21 => 39 => 43.452Z',
                    lang      => 'pt-br',
                    result    => {
                        source           => 'agent',
                        resolvedQuery    => 'O que você acha do aborto?',
                        action           => '',
                        actionIncomplete => 0,
                        parameters       => {},
                        contexts         => [],
                        metadata         => {
                            intentId                  => '4c3f7241-6990-4c92-8332-cfb8d437e3d1',
                            webhookUsed               => 0,
                            webhookForSlotFillingUsed => 0,
                            isFallbackIntent          => 0,
                            intentName                => 'direitos_animais'
                        },
                        fulfillment => { speech =>  '', messages =>  [] },
                        score       => 1
                    },
                    status    => { code =>  200, errorType =>  'success' },
                    sessionId => '1938538852857638'
                }
            )
        ]
    ;
    my $third_issue_id = stash "i3.id";

    rest_put "/api/politician/$politician_id/issue/$third_issue_id",
        name  => "updating issue with media",
        files => { file => "$Bin/picture.jpg", },
    ;

    my $third_issue    = $issue_rs->find($third_issue_id);
    ok ( defined( $third_issue->saved_attachment_id ), 'defined' );
};

done_testing();