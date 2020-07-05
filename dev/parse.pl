
use strict;
use warnings;

use Data::Dumper qw(Dumper);


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
         print Dumper \@word unless $w;
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
