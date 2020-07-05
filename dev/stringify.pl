#!/usr/bin/perl
#
# See:
#
# http://perldesignpatterns.com/?DepthFirstRecursion
#
use strict;
use warnings;

my %hash = (
  'a' => {
    'one' => 1111,
    'two' => 222,
  },
  'b' => [ 'foo', 'bar' ],
  'c' => 'test',
  'd' => {
    'states' => {
      'virginia' => 'richmond',
      'texas' => 'austin',
    },
    'planets' => [ 'venus','earth','mars' ],
    'constellations' => ['orion','ursa major' ],
    'galaxies' => {
      'milky way' => 'barred spiral',
      'm87' => 'elliptical',
    },
  },
);

&expand_references2(\%hash);

sub expand_references2 {
  my $indenting = -1;
  my $inner; $inner = sub {
    my $ref = $_[0];
    my $key = $_[1];
    $indenting++;
    if(ref $ref eq 'ARRAY'){
      print '  ' x $indenting,' ';
      printf("\"%s\": [ ",($key) ? $key : ' ');
      $inner->($_) for @{$ref};
      print '  ' x $indenting,'], ';
    }elsif(ref $ref eq 'HASH'){
      print '  ' x $indenting,'{ ';
      printf(" \"%s\":\n",($key) ? $key : '');
      for my $k(sort keys %{$ref}){
        $inner->($ref->{$k},$k);
      }
      print '  ' x $indenting,'}, ';
    }else{
      if($key){
        print ' ' x $indenting,$key,': ',$ref,"\n";
      }else{
        print ' ' x $indenting,$ref,",\n ";
      }
    }
    $indenting--;
  };
  $inner->($_) for @_;
}
