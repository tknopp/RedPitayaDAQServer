#!/bin/bash

default_part="xc7z010clg400-1"
part=${1:=$default_part}

sh scripts/make_all_cores.sh ${part}
vivado -nolog -nojournal -mode batch -source src/fpga/build.tcl ${part}
