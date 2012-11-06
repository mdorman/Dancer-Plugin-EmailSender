#!/usr/bin/perl

use strict;
use warnings;
use Dancer qw{:tests};
use Dancer::Plugin::EmailSender;
use Log::Any::Adapter qw{Stderr};
use Test::Fatal;
use Test::More import => ['!pass'];
use t::Util qw{body_is body_like header_is header_like with_email};

setting logger => 'LogAny';

like (exception {emailsender}, qr/^You must pass me information on what to send/, 'Test for failure with no arguments');
like (exception {emailsender ''}, qr/^You must pass me a hashref to describe the email/, 'Test for failure with wrong type of arguments');
like (exception {emailsender {}}, qr/^You must tell me who the email is from/, 'Test for failure with missing from');
like (exception {emailsender {from => 'mdorman@ironicdesign.com'}}, qr/^You must tell me to whom to send the email/, 'Test for failure with missing to');
like (exception {emailsender {'envelope-from' => 'mdorman@ironicdesign.com'}}, qr/^You must tell me to whom to send the email/, 'Test for failure with missing to');

ok (emailsender ({from => 'mdorman@ironicdesign.com', to => ['mdorman@ironicdesign.com']}), 'Test for successful transmission');

with_email {
    my ($email) = @_;
    body_is $email, '';
    header_is $email, 'from', 'mdorman@ironicdesign.com';
    header_is $email, 'to', 'mdorman@ironicdesign.com';
};

ok (emailsender ({from => 'mdorman@ironicdesign.com', to => ['mdorman@ironicdesign.com'], body => 'This is a trivial body.'}), 'Test for successful transmission');

with_email {
    my ($email) = @_;
    body_is $email, 'This is a trivial body.';
    header_is $email, 'from', 'mdorman@ironicdesign.com';
    header_is $email, 'to', 'mdorman@ironicdesign.com';
};

done_testing;
