package Dancer::Plugin::EmailSender;
#ABSTRACT: Easily use Email::Sender from Dancer

use Carp qw{croak};
use Dancer ':syntax';
use Dancer::Plugin;
use Email::Sender::Simple qw{sendmail};
use Email::MIME;
use Module::Load 'load';
use Try::Tiny;
use strict;
use warnings;

register emailsender => sub {
    my ($args) = @_ or croak 'You must pass me information on what to send';

    ref $args eq "HASH" or croak 'You must pass me a hashref to describe the email';

    my $params = {};
    $params->{from} = $args->{'envelope-from'} || $args->{from} or croak 'You must tell me who the email is from';
    $params->{to} = $args->{'envelope-to'} || $args->{to} or croak 'You must tell me to whom to send the email';

    my $config = plugin_setting;

    my $headers = {%{$config->{headers} || {}}, %{$args->{headers} || {}}, from => $args->{from}, to => join ",", @{$args->{to}}};

    my $email = Email::MIME->create (header_str => [%{$headers}], body => $args->{body});

    if (my ($transport) = keys %{$config->{transport} || {}}) {
        my $class = "Email::Sender::Transport::$transport";
        load $class;
        $params->{transport} = $class->new ($config->{transport}->{$transport} || {});
    }

    return sendmail $email, $params;
};

register_plugin;

1;
