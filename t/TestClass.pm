package TestClass;
use strict;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( foo bar quux ));

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

1;
