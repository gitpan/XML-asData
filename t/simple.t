#!/usr/bin/perl

use strict;
use warnings;
use Test::Exception;
use Test::More tests => 26;
use lib qw(lib t);

use Clone qw(clone);

use_ok('XML::asData');
use_ok('TestClass');
my $x = XML::asData->new;

$x->root('sexy');
$x->objects(1);

my $undef;
my $string = 'string';
my $integer = 42;
my $float = 1.23;
my $arrayref = [1, 2, 4, 8];
my $hashref = {
  a => 1,
  b => 2,
  c => 3,
};
my $complicated = {
  undef     => $undef,
  string    => $string,
  integer   => $integer,
  float     => $float,
  arrayref  => $arrayref,
  arrayref2 => [$undef, $string, $integer, $float],
  hashref   => $hashref,
};

my $not_utf8 = ({
 'short' => 'IXS3',
 'compatible' => 0,
 'name' => 'Digital IXUS v³',
 'type' => 'camera'
});

my $object = TestClass->new;
$object->foo($string);
$object->bar($arrayref);
$object->quux($hashref);

my @data = ($undef, $string, $integer, $float, $arrayref, $hashref,
$complicated, $not_utf8, $object);

foreach my $data (@data) {
  test($data);
}

# Now check that objects really are disabled when we want them to be

my $data = $object;
my($xml, $from_xml);
$x->objects(0);
throws_ok { $xml = $x->as_xml($data) } qr/Objects disabled/;
$x->objects(1);
lives_ok { $xml = $x->as_xml($data) };
$x->objects(0);
throws_ok { $from_xml = $x->as_data($xml) } qr/Objects disabled/;
$x->objects(1);
lives_ok { $from_xml = $x->as_data($xml) };
is_deeply($data, $from_xml);
is(ref($data),ref($from_xml));

sub test {
  my $data = shift;

  my $xml = $x->as_xml($data);
  my $from_xml = $x->as_data($xml);

  is_deeply($data, $from_xml);
  is(ref($data),ref($from_xml));
}

