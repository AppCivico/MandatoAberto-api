use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    create_politician;
    my $politician_id = stash "politician.id";

    api_auth_as user_id => $politician_id;

    rest_get "/api/admin/dialog",
        name    => 'get dialogs as politician',
        is_fail => 1,
        code    => 403,
    ;

    api_auth_as user_id => 1;

    my $dialog_name       = fake_words(1)->();
    my $dialog_desciption = fake_words(1)->();

    rest_post "/api/admin/dialog",
        name    => 'creating dialog without name',
        is_fail => 1,
        code    => 400,
        [
            description => $dialog_desciption
        ]
    ;

    rest_post "/api/admin/dialog",
        name    => 'creating dialog without description',
        is_fail => 1,
        code    => 400,
        [
            name => $dialog_name
        ]
    ;

    rest_post "/api/admin/dialog",
        name                => 'creating dialog',
        automatic_load_item => 0,
        stash               => 'd1',
        [
            name        => $dialog_name,
            description => $dialog_desciption
        ]
    ;

    my $dialog_id = stash "d1.id";

    rest_post "/api/admin/dialog/$dialog_id/question",
        name    => 'question without name',
        is_fail => 1,
        code    => 400,
        [
            content       => "Foobar",
            citizen_input => 'bazbar'
        ]
    ;

    rest_post "/api/admin/dialog/$dialog_id/question",
        name    => 'question without content',
        is_fail => 1,
        code    => 400,
        [
            name          => 'foo',
            citizen_input => 'bazbar'
        ]
    ;

    rest_post "/api/admin/dialog/$dialog_id/question",
        name    => 'question without citizen_input',
        is_fail => 1,
        code    => 400,
        [
            name          => 'foo',
            content       => "Foobar",
        ]
    ;

    rest_post "/api/admin/dialog/$dialog_id/question",
        name    => "Question with citizen input with more than 20 chars",
        is_fail => 1,
        code    => 400,
        [
            name          => 'foo',
            content       => "Foobar",
            citizen_input => fake_paragraphs(3)->()
        ]
    ;

    rest_post "/api/admin/dialog/$dialog_id/question",
        name                => "Sucessful question",
        automatic_load_item => 0,
        stash               => "q1",
        [
            name          => 'foo',
            content       => "Foobar",
            citizen_input => 'bazbar'
        ]
    ;
    my $question_id = stash "q1.id";

    rest_post "/api/admin/dialog/$dialog_id/question",
        name    => "Question with name that alredy exists",
        is_fail => 1,
        code    => 400,
        [
            name          => 'foo',
            content       => "Foobar",
            citizen_input => 'bazbar'
        ]
    ;

    rest_get "/api/admin/dialog",
        name  => 'get dialogs',
        list  => 1,
        stash => "get_dialogs"
    ;

    stash_test "get_dialogs" => sub {
        my $res = shift;

        my $dialog   = $res->{dialogs}->[0];
        my $question = $dialog->{questions}->[0];

        is ($dialog->{id},          $dialog_id,              'dialog id');
        is ($dialog->{name},        $dialog_name,            'dialog name');
        is ($dialog->{description}, $dialog_desciption,      'dialog description');
        is ($dialog->{created_by},  'lucas.ansei@eokoe.com', 'admin email');
        is ($dialog->{updated_by},  undef,                   'dialog has never been updated');

        is ($question->{id},            $question_id,            'question id');
        is ($question->{citizen_input}, 'bazbar',                'question citizen_input');
        is ($question->{content},       'Foobar',                'question content');
        is ($question->{created_by},    'lucas.ansei@eokoe.com', 'admin email');
        is ($question->{updated_by},    undef,                   'question has never been updated');
    };

    rest_put "/api/admin/dialog/$dialog_id",
        name    => 'updating dialog with repeated name',
        is_fail => 1,
        code    => 400,
        [
            name => $dialog_name
        ]
    ;

    rest_put "/api/admin/dialog/$dialog_id",
        name => 'updating dialog name',
        [
            name => 'fake dialog'
        ]
    ;

    rest_put "/api/admin/dialog/$dialog_id/question/$question_id",
        name    => 'updating question with repeated name',
        is_fail => 1,
        code    => 400,
        [
            name => 'foo'
        ]
    ;

    rest_put "/api/admin/dialog/$dialog_id/question/$question_id",
        name => "updating question content",
        [
            content => 'fake question'
        ]
    ;

    rest_reload_list "get_dialogs";

    stash_test "get_dialogs.list" => sub {
        my $res = shift;

        my $dialog   = $res->{dialogs}->[0];
        my $question = $dialog->{questions}->[0];

        is ($dialog->{id},          $dialog_id,              'dialog id');
        is ($dialog->{name},        'fake dialog',           'updated dialog name');
        is ($dialog->{description}, $dialog_desciption,      'dialog description');
        is ($dialog->{created_by},  'lucas.ansei@eokoe.com', 'admin email');
        is ($dialog->{updated_by},  'lucas.ansei@eokoe.com', 'dialog has been updated');

        is ($question->{id},            $question_id,            'question id');
        is ($question->{citizen_input}, 'bazbar',                'question citizen_input');
        is ($question->{content},       'fake question',         'updated question content');
        is ($question->{created_by},    'lucas.ansei@eokoe.com', 'admin email');
        is ($question->{updated_by},    'lucas.ansei@eokoe.com', 'question has been updated');
    };
};

done_testing();