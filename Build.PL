#!/usr/bin/perl
use warnings;
use strict;
use Module::Build;

Module::Build->new(
  create_makefile_pl => 'traditional',
  license     => 'perl',
  module_name => 'XML::asData',
  requires    => {
    'Class::Accessor::Fast' => 0,
    'Clone'           => 0,
    'Encode'          => 0,
    'Error'           => 0,
    'Scalar::Util'    => 0,
    'Test::Exception' => 0,
    'XML::LibXML'     => 0,
  },
)->create_build_script;
