#!/bin/dash
# Copyright (c) 2020 ben
# Licensed under the GPL license. See Copying.txt in the project root.


HELP="Print the result of a Perl expression"
USAGE="[help] | <expression> [expression arg] | <expression> -f <file>" 


die () { echo "$@" 1>&2; exit 1; }
warn () { echo "$@" 1>&2; }
usage () { [ -n "$1" ] && warn "$1"; local app=$(basename $0); die "usage - $app: $USAGE"; }
help () { warn "Help: $HELP" ; usage ; }


uperl_dir=$(dirname $0)

uperl="${uperl_dir}/uperl"

uperl_module="$uperl_dir/Upl.pm" 

repl () {
      if which rlwrap >> /dev/null ; then
         echo 'Interactive Perl Shell'
         rlwrap -A -pgreen -S"perl> " ${uperl} -w -n -e 'chomp; ($r) = eval(); print(($@) ? $@ : "$_ = $r\n");';
      else
         ${uperl} -w -n -e 'chomp; ($r) = eval(); print(($@) ? $@ : "$_ = $r\n");';
      fi
}

filerun(){
      case "$2" in
         -f|--file)
            ${uperl} -w -I${uperl_dir} -MUpl -e 'Upl::import(); my $e=$ARGV[0]; my $f=$ARGV[2]; open(my $fh,"<", $f) || die "Err: cannot open file $f"; while(<$fh>){print(join(" ", eval($e)))}; close $fh;' "$@"
         ;;
         *)
            usage "arg $2 is invalid"
         ;;
      esac
}

${uperl} -w -I${uperl_dir} -MUpl -e 'print join("\n", Upl::pipe(@ARGV));' "$@"
exit


case "$#" in 
   0)
      usage
   ;;
   1)
   case "$1" in
      help) help;;
      repl) repl;;
      *)
         ${uperl} -w -I${uperl_dir} -MUpl -e 'Upl::import(); my @r= eval(shift); foreach my $e (@ARGV){@r = map{ eval($e) } @r}; print join(" ", @r);' "$@"
         #${uperl} -w -I${uperl_dir} -MUpl -e 'Upl::import(); $_ = $ARGV[1]; print(join(" ", eval(shift)));' "$@"
      ;;
   esac
   ;;
   *)
         ${uperl} -w -I${uperl_dir} -MUpl -e 'print join(" ", Upl::pipe(@ARGV));' "$@"
         #${uperl} -w -I${uperl_dir} -MUpl -e 'Upl::import(); my @r= eval(shift); foreach my $e (@ARGV){@r = grep { $_ ne "" } map{ eval($e) } @r; }; print join(" ", @r);' "$@"
   ;;
esac

#  while [ $# -gt 0 ]; do
#     arg="$1"
#     shift
#     case "$arg" in
#        -h|--help) help ;;
#       -m) 
#         module_input=$1
#         shift
#          ;;
#        -*) die "Err: invalid option use -h for help" ;;
#        *) 
#          if [ -z "$expression_input" ] ; then
#            expression_input="$arg"
#          else
#           expression_args="${expression_args} $arg"
#          fi
#        ;;
#    esac
#  done

#if [ -t 0 ] ; then echo terminal; else echo "pipe"; fi
