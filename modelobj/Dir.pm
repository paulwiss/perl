#!/usr/bin/perl
use 5.010;
# description
package Dir;
sub new
{
   my $class = shift;
   my $self = {
      _path => shift,
      _files => [],
   };
#   say $class;
#   say $self->{_path};
   bless $self, $class;
   return $self;
}

sub setPath {
   my ($self, $path) = @_;
   $self->{_path} = $path if defined($path);
}

sub getPath {
    my( $self ) = @_;
    return $self->{_path};
}

sub addFile {
   my $file = shift;
#   push $self->{_files}, $file if defined($file);
   my $filesref = $self->{_files};
   # Not an ARRAY reference at Dir.pm line 32.
   push $filesref, $file if defined($file);
}

# package must return true
1;

