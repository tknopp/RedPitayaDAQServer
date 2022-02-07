JOBS=`nproc 2> /dev/null || echo 1`

make -j $JOBS cores

make NAME=led_blinker all

PRJS="led_blinker_122_88"

printf "%s\n" $PRJS | xargs -n 1 -P $JOBS -I {} make NAME={} PART=xc7z020clg400-1 bit

sudo sh scripts/alpine.sh
