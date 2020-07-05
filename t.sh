#if [ -t 0 ] ; then echo not a pipe; else echo "pipe"; fi


args=
for a in $@; do
  args="$args $a"
done

for a in $args; do
  echo axa $a
done


for f in $(seq 1000) ; do
#  perl -w -I. -MUpl -e 'print(trim("kakaa"))'
  #perl -e '1+1'
  /bin/dash ./upl '1+1'
done

