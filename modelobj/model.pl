#!/usr/bin/perl
use warnings;
use strict;
use 5.010;
# description
use Dir;
my $object = new Dir("testpath1");
say $object->getPath();
$object->setPath("testpath2");
say $object->getPath();
$object->addFile("test file");

