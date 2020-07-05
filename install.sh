


target_dir=$1

[ -d "$target_dir" ] || {
   echo 'usage:<installation directory>' 1>&2
   exit 1
}
   


rm -f $target_dir/ltr
cp ltr $target_dir/ltr

