use common::sense;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use MandatoAberto::Test::Further;

my $schema = MandatoAberto->model("DB");

db_transaction {
    rest_post "/api/register/dialog",
        name    => "post without login",
        is_fail => 1,
        code    => 403
    ;

    # Um político não pode criar um dialogo
    create_politician;
    api_auth_as user_id => stash "politician.id";

    rest_post "/api/register/dialog",
        name    => "post made by a politician",
        is_fail => 1,
        code    => 403
    ;

    # Criando uma conta admin
    my $user = $schema->resultset("User")->create({
        email    => fake_email()->(),
        password => "foobar"
    });

    $schema->resultset("UserRole")->create({
        user_id => $user->id,
        role_id => 1
    });


    api_auth_as user_id => $user->id;

    my $name        = fake_words(1)->();
    my $description = fake_words(1)->();

    rest_post "/api/register/dialog",
        name                => "Creating dialog",
        automatic_load_item => 0,
        stash               => 'd1',
        [
            name        => $name,
            description => $description
        ]
    ;

    rest_post "/api/register/dialog",
        name    => "Dialog alredy exists",
        is_fail => 1,
        code    => 400,
        [
            name        => $name,
            description => $description
        ]
    ;

    rest_post "/api/register/dialog",
        name    => "Dialog without name",
        is_fail => 1,
        code    => 400,
        [ description => $description ]
    ;

    rest_post "/api/register/dialog",
        name    => "Dialog without name",
        is_fail => 1,
        code    => 400,
        [ name => $name ]
    ;
};

done_testing();