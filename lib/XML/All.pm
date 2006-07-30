package XML::All;

use 5.006001;
use strict;
use warnings;
use XML::Twig;
use Tie::Simple;
use Class::InsideOut ();
use Exporter::Lite;

our @EXPORT = qw( xml );
our $VERSION = '0.01';

Class::InsideOut::private(twig => my %twig);

use XML::Literal sub {
    my $obj = Class::InsideOut::register( bless \(my $s), __PACKAGE__ );
    my $xml = XML::Twig->new;
    $xml->parse($_[0]);
    $twig{ Class::InsideOut::id($obj) } = $xml->root;
    bless($obj);
};

my $xmlify = sub {
    my $xml = XML::Twig->new;
    $xml->parse($_[0]);
    return $xml->root;
};

my $vivify = sub {
    my $res = Class::InsideOut::register( bless \(my $s), __PACKAGE__ );
    $twig{ Class::InsideOut::id($res) } = $_[0];
    bless($res);
};

sub xml {
    if (ref($_[0]) and ref($_[0])->isa(__PACKAGE__)) {
        my $obj = $twig{Class::InsideOut::id(shift(@_))};
        my @children = map { $vivify->($_) } $obj->children(join('', 'xml', map { "[$_]" } @_ ));
        wantarray ? @children : $children[0];
    }
    elsif ($_[0] =~ /^\s*</) {
        my $xml = XML::Twig->new;
        $xml->parse($_[0]);
        return $vivify->($xml);
    }
    else {
        my $xml = XML::Twig->new;
        $xml->parsefile($_[0]);
        return $vivify->($xml);
    }
}

sub AUTOLOAD :lvalue {
    my $meth = our $AUTOLOAD;
    $meth =~ s/.*:://;

    return if $meth eq 'DEMOLISH' or $meth eq 'DESTROY';

    my $xml = shift;
    my $obj = $twig{Class::InsideOut::id($xml)};
    my @children = $obj->children(join('', $meth, map { "[$_]" } @_ ));
    if (wantarray and @children != 1) {
        @children = map { $vivify->($_) } @children;
        return @children;
    }
    else {
        $children[0] or return undef;
        my $res = Class::InsideOut::register( bless \(my $s), __PACKAGE__ );
        $twig{ Class::InsideOut::id($res) } = $children[0];
        bless($res);
        return $res;
    }
}

my $make_sub;
BEGIN { $make_sub = sub {
    my ($sym, $call) = @_;
    return (
        $sym => sub {
            my $obj = $twig{Class::InsideOut::id($_[0])} || $xmlify->($_[0]);
            my $tgt = $twig{Class::InsideOut::id($_[1])} || $xmlify->($_[1]);
            ($obj, $tgt) = ($tgt, $obj) if $_[2];
            my $cpy = $obj->copy;
            $call->($cpy, $tgt);
            $vivify->($cpy);
        },
        "$sym=" => sub {
            my $obj = $twig{Class::InsideOut::id($_[0])} || $xmlify->($_[0]);
            my $tgt = $twig{Class::InsideOut::id($_[1])} || $xmlify->($_[1]);

            ($obj, $tgt) = ($tgt, $obj) if $_[2];
            $call->($obj, $tgt);
            $vivify->($obj);
        },
    );
} };

use overload (
    '${}' => sub {
        my $obj = $twig{Class::InsideOut::id($_[0])};
        tie my $scalar, 'Tie::Simple', $obj,
            FETCH   => sub { $obj->tag },
            STORE   => sub { defined($_[0]) ? $obj->set_tag($_[1]) : $obj->erase };
        return \$scalar;
    },
    '@{}' => sub {
        my $obj = $twig{Class::InsideOut::id($_[0])};
        [map {$vivify->($_)} $obj->children];
    },
    '%{}' => sub {
        my $obj = $twig{Class::InsideOut::id($_[0])};
        $obj->atts;
    },
    '&{}' => sub {
        my $obj = $twig{Class::InsideOut::id($_[0])};
        sub { map { $_->is_text ? $_->text : () } $obj->children };
    },
    '0+'  => sub {
        my $obj = $twig{Class::InsideOut::id($_[0])};
        $obj->text;
    },
    '""'  => sub {
        my $obj = $twig{Class::InsideOut::id($_[0])};
        $obj->sprint;
    },
    'bool' => sub { 1 },
    $make_sub->('+' => sub { $_[1]->paste(last_child => $_[0] )}),
), fallback => 1;

1;

__END__

=head1 NAME 

XML::All - Overloaded XML objects

=head1 SYNOPSIS

    use XML::All;
     
    my $xml = < <a href='/'>1 <b>2</b> <em>3</em></a> >;
     
    print $$xml;            # a
    print join ", ", @$xml; # 1, <b>2</b>, <em>3</em>
    print join ", ", %$xml; # href, '/'
     
    print $xml->b();        # <b>2</b>
    print $xml->b() * 10;   # 20
    print $xml->();         # 1
     
    $$xml = 'link';
    print $xml;             # <link href='/'>...</link>
     
    my $em = $xml->em + <hr/>;
    print $em;              # <em>3<hr/></em>

=head1 DESCRIPTION

This module provides a handy wrapper around L<XML::Twig> and
L<XML::Literal> to provide easy accessors to the XML structures.

=head1 NOTES

This is a I<preview release>; all APIs are subject to change, and
stream processing mode is not yet in place.  Please be patient and
don't depend on this module for your production code just now. :)

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT (The "MIT" License)

Copyright 2006 by Audrey Tang <cpan@audreyt.org>.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is fur-
nished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE X
CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
