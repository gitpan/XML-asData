package XML::asData;

use strict;
our $VERSION = '20.1';

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( doc root objects ));
use Encode qw(encode_utf8);
use Error;
use Scalar::Util qw(blessed reftype);
use XML::LibXML;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->root("envelope");
  $self->objects(1);
  return $self;
}

sub as_xml {
  my $self = shift;
  my $data = shift;
  my $doc = $self->as_libxml($data);
  return $doc->toString(0);
}

sub as_libxml {
  my $self = shift;
  my $data = shift;

  my $doc = XML::LibXML::Document->new("1.0", "UTF8");
  $self->doc($doc);
  my $envelope = $doc->createElement($self->root);
  $doc->setDocumentElement($envelope);

  $self->as_xml_aux($envelope, $data);
  return $doc;
}

sub as_data {
  my $self = shift;
  my $xml  = shift;

  my $p = XML::LibXML->new;
  my $doc = $p->parse_string($xml);
  $self->doc($doc);
  my $root = $doc->documentElement();
  return $self->as_data_aux($root);
}

sub as_xml_aux {
  my($self, $node, $contents) = @_;

  my $class = blessed $contents;
  my $type = reftype $contents;

  if (not $type) {
    # normal scalar
    if (defined $contents) {
      my $octets = encode_utf8($contents);
      $node->addChild( $self->doc->createTextNode($octets) );
    } else {
      $node->setAttribute('undef', 1);
    }
    return;
  }

  if ($class eq 'XML::LibXML::Element') {
    # an XML fragment
    $node->addChild( $contents );
    return;
  }

  if ($class) {
    if ($self->objects) {
      $node->setAttribute('class', $class);
    } else {
      throw Error::Simple("XML::asData: Objects disabled, but $class found");
    }
  }

  if ($type eq 'ARRAY') {
    # an array ref
    $node->setAttribute('list', 1);
    foreach my $e (@$contents) {
      my $elem = $self->doc->createElement('elem');
      $node->addChild($elem);
      $self->as_xml_aux($elem, $e);
    }
  } elsif ($type eq 'HASH') {
    # a hash ref
    $node->setAttribute('hash', 1);
    foreach my $k (sort keys %$contents) {
      my $key = $self->doc->createElement('key');
      $node->addChild($key);
      $self->as_xml_aux($key, $k);

      my $value = $self->doc->createElement('value');
      $node->addChild($value);
      $self->as_xml_aux($value, $contents->{$k});
    }
  } else {
    throw Error::Simple("XML::asData: Objects disabled, but $class found");
  }
}

sub as_data_aux {
  my($self, $node) = @_;
  my $value;

  my $field = $node->nodeName();
  return unless $node->nodeType == 1;

  if ($node->getAttribute('undef')) {
    # undef
  } elsif ($node->getAttribute('list')) {
    foreach my $child ($node->childNodes) {
      push @$value, $self->as_data_aux($child);
    }
  } elsif ($node->getAttribute('hash')) {
    my($k, $v);
    my $flip = 0;
    foreach my $child ($node->childNodes) {
      next unless $child->nodeType == 1;
      if ($flip == 0) {
	$k = $self->as_data_aux($child);
	$flip = 1;
      } else {
	$v = $self->as_data_aux($child);
	$value->{$k} = $v;
	$flip = 0;
      }
    }
  } else {
    $value = $node->textContent();
  }

  my $class = $node->getAttribute('class');
  if ($class) {
    if ($self->objects) {
      bless $value, $class;
    } else {
      die "XML::asData: Objects disabled, but $class found";
    }
  }

  return $value;
}

1;

__END__

=head1 NAME

XML::asData - serialise data structures to XML and back again

=head1 SYNOPSIS

  use XML::asData;
  my $x     = XML::asData->new;

  my $data  = ... ; # some data structure
  my $xml   = $x->as_xml($data);
  my $data2 = $x->as_data($xml);

=head1 DESCRIPTION

The module takes a Perl data structure and outputs XML representing
that structure. It can of course also do the reverse. This is somewhat
similar to XML::Simple, except that it uses XML::LibXML to do its
dirty work (which is fast). Also, the module makes sure to use UTF8 in
the XML.

=head1 METHODS

=head2 new

This is the constructor.

  my $x = XML::asData->new;

=head2 as_xml($data)

This takes a Perl data structure and returns XML.

  my $xml = $x->as_xml($data);

=head2 as_data($xml)

This takes XML output by this module and turns it back into a Perl
data structure.

=head2 root($name)

This sets the root element name in the XML. It defaults to "envelope".

  $x->root('sexy');

=head2 objects($bool)

This sets whether the module should serialize and deserialize
objects. You might want to disable this. It defaults to true.

  $x->objects(0);

=head1 AUTHOR

Leon Brocard, acme@astray.com

=head1 COPYRIGHT

Copyright 2004 Fotango.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Simple>

=cut

