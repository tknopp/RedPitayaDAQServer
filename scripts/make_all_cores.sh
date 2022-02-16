#!/bin/bash

default_part="xc7z010clg400-1"
part=${1:=$default_part}

prefix="./src/fpga/cores/"
for core in ./src/fpga/cores/* ; do
    core=${core#$prefix}
    vivado -nolog -nojournal -mode batch -source scripts/core.tcl -tclargs ${core} ${part}
done
