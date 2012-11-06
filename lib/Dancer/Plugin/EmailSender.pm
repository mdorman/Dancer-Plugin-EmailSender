package Dancer::Plugin::EmailSender;
#ABSTRACT: Easily use Email::Sender from Dancer

use Carp qw{croak};
use Dancer ':syntax';
use Dancer::Plugin;
use Email::MIME;
use Email::Sender::Simple qw{sendmail};
use Module::Load 'load';
use Scalar::Util 'blessed';
use Test::More import => ['!pass'];
use strict;
use warnings;

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::EmailSender;

    post '/signup' => sub {
        sendemail {
            body            => '...',
            'envelope-from' => 'signup-@ironicdesign.com-@[]' # Allows VERP-handling with postfix
            from            => 'mdorman@ironicdesign.com',
            subject         => 'Welcome to our site',
            to              => param ('email')
        };
    };

=head1 DESCRIPTION

This plugin makes constructing and sending emails from L<Dancer>
applications as simple and flexible as possible.  Since it uses
L<Email::Sender>, in many cases, no explicit configuration may be
required, though several configuration options are available.

=head1 CONFIGURATION

=head2 Transport

C<Dancer::Plugin::EmailSender> allows you to choose and configure a
particular transport, should you not wish to use the one that
C<Email::Sender> would choose by default (as discussed in
L<Email::Sender::Manual::QuickStart/Picking_a_Transport>)

Simply add a C<transport> key, pointing to a set of options that must
include a C<class> entry stating the class to be used for the
transport, while any additional entries will be used as parameters for
instantiating the transport:

For example, to sending mail using SMTPS via Gmail:

    plugins:
      EmailSender:
        transport:
          class: SMTP:
          ssl: 1
          host: 'smtp.gmail.com'
          port: 465
          sasl_username: 'mdorman@ironicdesign.com'
          sasl_password: 'NotMuchOfASecret'

Or perhaps to use the default Sendmail transport, but give an explicit
path to the sendmail program:

    plugins:
      EmailSender:
        transport:
          class: Sendmail
          sendmail: '/usr/sbin/sendmail'

=head2 Headers

You may provide a set of default headers in the configuration.  These
I<will> be overridden by any headers you include in the invocation of
C<sendemail>:

    plugins:
      EmailSender:
        headers:
          From: 'noreply@ironicdesign.com'
          X-Mailer: 'Degronkulator 3.14'
          X-Accept-Language: 'en'

=method sendemail

This function will optionally construct, and then send, an email.  It
takes a hashref of parameters.  They can be divided up as to their
purpose:

=head3 Specifying the content to send

To specify the content of the email to send, you may either:

=over 4

=item Provide a complete email to be sent

If a completed email (in a format that is acceptable to
C<Email::Abstract> is provided in an C<email> parameter, that is the
email that will be used.

=item Provide parameters to construct an email

These parameters include:

=over

=item headers

A hashref of additional headers to add to the email.

=item from

The address from which the email should be sent.

=item to

An arrayref od address to which the email should be sent.

=back

=back

=head3 To specify how the email is sent

In addition, you may optionally specify the transport as well as the
sending and receiving addresses for the SMTP transaction, allowing
them to be different from the values in the headers of your email.  To
do this you can include either or both of:

=over 4

=item envelope-from

This is the address that will be used as the sending address during
the SMTP transaction.

=item envelope-to

This is the list of addresse that will be used as recipients during
the SMTP transaction.

=item transport

This parameter should contain a hashref that corresponds to the

=back

An exception will be thrown if sending the email fails, so plan
appropriately.

=cut

register sendemail => sub {
    my ($args) = @_ or croak 'You must pass me information on what to send';
    ref $args eq "HASH" or croak 'You must pass me a hashref to describe the email';

    my $config = plugin_setting;

    my $email;

    if ($args->{email}) {
        $email = Email::Abstract->new ($args->{email});
    } else {
        my $headers = {%{ref $config->{headers} eq 'HASH' ? $config->{headers} : {}}, %{ref $args->{headers} eq 'HASH' ? $args->{headers} : {}}, From => $args->{from}, To => join ",", ref $args->{to} eq 'ARRAY' ? @{$args->{to}} : ()};
        $email = Email::Abstract->new (Email::MIME->create (header_str => [%{$headers}], body => $args->{body}));
    }

    croak 'Could not extract or construct an email from our parameters' unless ($email);

    my $params = {};
    ($params->{from} = $args->{'envelope-from'}) or $email->get_header ('from') or croak 'You must tell me who the email is from';
    ($params->{to} = $args->{'envelope-to'}) or $email->get_header ('to') or croak 'You must tell me to whom to send the email';

    if (blessed $args->{transport}) {
        $params->{transport} = $args->{transport};
    } elsif (!defined $args->{transport} and blessed $config->{transport}) {
        $params->{transport} = $config->{transport};
    } else {
        my $transport = {%{ref $config->{transport} eq 'HASH' ? $config->{transport} : {}}, %{ref $args->{transport} eq 'HASH' ? $args->{transport} : {}}};
        if (my $choice = delete $transport->{class}) {
            my $class = "Email::Sender::Transport::$choice";
            load $class;
            $params->{transport} = $class->new ($transport);
        }
    }

    return sendmail $email, $params;
};

register_plugin;

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>, though significant
inspiration for the interface came from C<Dancer::Plugin::Email>,
which was written by:

=over 4

=item *

Naveed Massjouni <naveedm9@gmail.com>

=item *

Al Newkirk <awncorp@cpan.org>

=back

=cut

1;
