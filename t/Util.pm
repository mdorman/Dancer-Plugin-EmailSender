package t::Util;

BEGIN {$ENV{EMAIL_SENDER_TRANSPORT} = 'Test'};

use Email::Sender::Simple qw{};
use Test::More;
use Sub::Exporter -setup => {exports => [qw{body_is body_like header_is header_like with_email}]};

sub body_is ($$) {
    my ($email, $value) = @_;
    if (my $body = $email->get_body) {
        is ($body, $value, "Checking email body for $value");
    }
}

sub body_like ($$) {
    my ($email, $regex) = @_;
    if (my $body = $email->get_body) {
        like ($body, $regex, "Checking email body for $regex");
    }
}

sub header_is ($$$) {
    my ($email, $checking, $value) = @_;
    if (my $header = $email->get_header ($checking)) {
        is ($header, $value, "Checking header $checking against value $value");
    }
}

sub header_like ($$$) {
    my ($email, $checking, $regex) = @_;
    if (my $header = $email->get_header ($checking)) {
        like ($header, $regex, "Checking email header for $regex");
    }
}

sub with_email (&) {
    my ($sub) = @_;
    if (my $email = shift @{Email::Sender::Simple->default_transport->deliveries}) {
        $sub->($email->{email});
    }
}

1;
