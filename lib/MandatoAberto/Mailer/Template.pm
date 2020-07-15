package MandatoAberto::Mailer::Template;
use Moose;
use namespace::autoclean;
use utf8;

use Template;
use File::MimeInfo;
use MIME::Lite;
use Encode;

use MandatoAberto::Types qw(EmailAddress);

has to => (
    is       => "ro",
    isa      => EmailAddress,
    required => 1,
);

has subject => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

has from => (
    is       => 'ro',
    isa      => EmailAddress,
    required => 1,
);

has attachments => (
    is      => "rw",
    isa     => "ArrayRef[HashRef]",
    traits  => ["Array"],
    default => sub { [] },
    handles => { add_attachment => "push" },
);

has template => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

has vars => (
    is       => "ro",
    isa      => "HashRef",
    default  => sub { {} },
);

sub build_email {
    my ($self) = @_;

    my $tt = Template->new(EVAL_PERL => 0);

    my $content ;
    $tt->process(
        \$self->template,
        $self->vars,
        \$content,
    );

    my $email = MIME::Lite->new(
        To       => $self->to,
        Subject  => Encode::encode("MIME-Header", $self->subject),
        From     => $self->from,
        Type     => "text/html",
        Data     => $content,
        Encoding => 'base64',
    );
    $email->attr('content-type.charset' => 'UTF-8');

    my $organization_name = $self->{vars}->{organization_name};

    # if ($organization_name) {
    #     $organization_name =~ s/[^\x00-\x7f]//g;

    #     $email->attach(
    #         Type => 'TEXT',
    #         Data => "Enviado em nome de: $organization_name"
    #     );
    # }

    my @required_data = qw(path file_name name);
    for my $attachment (@{ $self->attachments }) {
        defined $attachment->{$_} or die "missing $_" for @required_data;

        $email->attach(
            Path        => $attachment->{path},
            Type        => mimetype($attachment->{file_name}),
            Filename    => $attachment->{name},
            Disposition => "attachment",
            Encoding    => "base64",
        );
    }

    return $email;
}

__PACKAGE__->meta->make_immutable;

1;

