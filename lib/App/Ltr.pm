package App::Ltr;
# Export all subs in package. Not for use in production code!
#https://stackoverflow.com/questions/732133/how-can-i-export-all-subs-in-a-perl-package
#
#
use strict; use warnings;

use Data::Dumper qw(Dumper);
use Cwd;

our $VERSION = '0.01';

sub import {
  no strict 'refs';

      my $caller = caller;

    while (my ($name, $symbol) = each %{__PACKAGE__ . '::'}) {
        next if      $name eq 'BEGIN';   # don't export BEGIN blocks
        next if      $name eq 'import';  # don't export this sub
        next unless *{$symbol}{CODE};    # export subs only
  
       my $imported = $caller . '::' . $name;
       *{ $imported } = \*{ $symbol };
    }
}

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };


sub remove_ws {
   my $rx = qr{("[^"]+"|[^" ]+)} ;
#
   my (@out, $data); 
   while ($data =~ /$rx/g) {
      $_ = $1;
      s/\n//;
      push @out, $_
   } 
}


sub parse_json {
   my ($stringlist) = @_;

   my $instr;
   my (@out, @line, @word);
   my $json_keywords_rx = qr(true|false|null);
   my $json_values_rx = qr(\s+|\d+);
   my $json_terminals_rx = qr(\s+|\{|\}|\[|\]|\,);

   my $wordline ; $wordline = sub {
      if(@word > 1){
         my ($w) = join('', @word);
         undef @word; 
         push @line, ($w =~ /$json_values_rx/) 
            ? $w 
            : (($w =~ /$json_keywords_rx/) 
               ? '\\"' . $w . '"' 
               : '"' . $w . '"') ;
      }
      push @line, @_;
   };

  foreach (@$stringlist){
    my $prev = '';
    foreach (split('', $_)){
      if($instr){
        if(/"/){
          push @line, join("", @word , '"');
          undef @word ;  undef $instr;
        }else{
          push @word, $_;
        }
      }else{
        if(/"/){
          $wordline->($_);
          $instr = 1;
        }elsif(/\:/){
          $wordline->(' => ');
        }elsif(/$json_terminals_rx/){
          $wordline->($_);
        }elsif(/\n/){
        }else{
          push @word, $_ 
        }
      }
      $prev = $_;
    }
    $wordline->();
    push @out, join('', @line);
    undef @line;
  } 
  my ($json_txt) = join("\n", @out);
  my ($json) = eval $json_txt;
  die "Err: could not parse json ($@) " unless $json;
  return $json;
}

sub parse_json_file {
  my $file = $ARGV[0]; 
  open my $fh, '<', $file or die;
  #$/ = undef;
  my  @data = <$fh>;
  close $fh;

 return parse_json(\@data);
}

sub _cat {
   my ($file) = @_;

   my $path;

   if(-f $file){
      $path = $file;
   }else{
      my $cwd = getcwd;
      $path = $cwd . '/' . $file;
      die "Err: filepath $path not exist"
    }

   open my $fh, '<', $path or die "Err: cannot read file $path $!";
   my  @data = map {chomp;$_ ; }  <$fh>;
   close $fh;
   return @data;
}

sub _match {
   my ($rx) = @_;

   my $v = $_;

   my @matches;
   my @res;
   if($_ =~ /$rx/){
      @matches = ($_ =~ /$rx/);
      @res = (join('', @matches) == 1  ) ? ($v) : @matches ;
   }
    @res;

}

sub _opendir {
  #     usage "opendir(directory)" if @_ != 1;
    my $dirhandle;
     CORE::opendir($dirhandle, $_[0])
   ? $dirhandle
   : undef;
 }

 sub readdir {
   #   usage "readdir(dirhandle)" if @_ != 1;
     CORE::readdir($_[0]);
 }

sub ls {
    my ($dir) = @_;



    my @fs = map { chomp; $_;  }  qx|ls $dir|;
    return @fs;

  #_opendir(my $dh, $dir) or die "Err: cannot read directory $dir: $!";
  #my @fs;
  #while (my $file = readdir($dh)) {
  #  push @fs, $file;
  #}
  #closedir($dh);
  #return @fs;
}

sub filter {
  my (@args) = @_;


  die 'asss' . $_;

  return 'lslsls';
}

sub _get {
  my ($key) = @_;

  return $_->{$key};
}

sub _concat {
  join('', @_);
}
my %kw = (
  cat => sub { _cat (@_) },
  "." => sub { _concat(@_) },
);


my $var = "";

sub parse_pipeline {
   my ($pipeline) = @_;

   my $pipe_terminals_rx = qr-\s|\(|\)|\{|\}|\[|\]|\,-;

   my (@pline, @exprs, @word);
  

   my ($cmd);
   my $wordexpr ; $wordexpr = sub {
      if(@word > 0){
        my $w =  join('', @word,);
        if(exists $kw{$w}){
          push @exprs, $kw{$w}
        }else{
         push @exprs, ($w =~ /^\s*\$_/) ? \$var : $w ;
        }
        undef @word; 
     }
     push @exprs, @_;
   };

   my ($instr);
    foreach (split('', $pipeline)){
      if($instr){
        if(/"/){
          push @exprs, join('', '',  @word, '');
          undef @word; undef $instr;
        }else{
          push @word, $_;
        }
      }else{
        if(/"/){
         $instr = 1;
         $wordexpr->();
        }elsif(/\s/){
          $wordexpr->( ) ;
        }elsif(/$pipe_terminals_rx/){
          $wordexpr->( $_ ) ;
        }elsif(/\|/){
         push @pline, [ @exprs];
         undef @exprs;
        }else{
          push @word, $_ 
        }
      }
  } 
  $wordexpr->();
   push @pline, [ @exprs ];
   undef @exprs;
  return @pline;
}


sub create_clos {
   my ($first, $bind_ref, @eparms) = @_;


   my ($clos);
  if (@eparms == 0) {
      $clos = sub {
         $first->($_);
         }
  }elsif ($$bind_ref) {
      $clos = sub {
         my ($inp) = $_;
         my @eargs = map { ((ref $_ eq 'SCALAR') ? $inp : $_) } @eparms;
         $first->(@eargs);
         }
   }else{
    $clos = sub {
        $first->(@eparms)
      };
    }
   return $clos;
}

sub eval_pipeline {
  my ($pline) = @_;

  my @res;

  my $eval_args; $eval_args = sub {
    my ( @args) = @_;

    my $binder;
    my @eargs;
    foreach my $a (@args){
      my $arg_type = ref $a;
      if($arg_type eq 'SCALAR'){
        $binder=1;
        push @eargs, \$binder;
      }elsif($arg_type eq ''){
        push @eargs, $a
      }else{
         die 'Err: invalid arg' . $arg_type . "\n";
      }
    }
    return (\$binder, @eargs);
  };


   foreach my $e (@$pline){
      my ($first,@rest) = @$e;

      my $first_type = ref $first;
      if( $first_type eq 'CODE'){
         my ($bind_ref, @eparms) = $eval_args->( @rest);
         my ($clos) = create_clos ($first, $bind_ref, @eparms); 
         @res = map $clos->($_),  @res;
    }elsif($first_type eq 'SCALAR'){
      print 'VVV' . "\n";
    }elsif($first_type eq ''){
      my @infix = grep { $_ if (ref $_ eq 'CODE' )} @rest;
      
      if(@infix == 1){
         die "Err: invalid number of infix args" unless (@rest == 2);

         my @parms = ($first, $rest[1]);

         my ($bind_ref, @eparms) = $eval_args->(@parms);
         my ($clos) = create_clos ($infix[0], $bind_ref, @eparms); 
         @res = map $clos->($_),  @res;
      }elsif(@infix == 0){
         @res = ($first, @rest);
      }else{
        die "Err: invalid infix op";
      }
    }else{
      die 'Err: unknows' . "\n";
    }
  }

  return \@res;


}

sub pipe {
   my ($pipeline) = @_;

   my @line =  parse_pipeline($pipeline);

   my ($res) = eval_pipeline(\@line);

   return $res;


   my $last = ($line[$#line] =~ /^\s*sort/) ? pop @line : undef;

   my @r = eval(shift @line); 
   
 }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Nano::Pl - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Nano::Pl;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Nano::Pl, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

ben, E<lt>ben@sd.apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by ben

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
