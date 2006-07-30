use Test::More tests => 9;
use ok XML::All;

my $xml = < <a href='/'>1<b>2</b><em>3</em></a> >;

is($$xml, 'a');
is(join(",", @$xml), "1,<b>2</b>,<em>3</em>");
is(join(",", %$xml), "href,/");

is($xml->b, '<b>2</b>');
is(($xml->b * 10), 20);
is($xml->(), 1);

$$xml = 'link';
is($xml, < <link href='/'>1<b>2</b><em>3</em></link> >);

is(($xml->em + <hr/>), '<em>3<hr/></em>');

# inplace edits not yet working
