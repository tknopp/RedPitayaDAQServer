#!/bin/bash

prefix="./src/fpga/cores/"
for core in ./src/fpga/cores/* ; do
    core=${core#$prefix}
    vivado -nolog -nojournal -mode batch -source scripts/core.tcl -tclargs ${core} xc7z010clg400-1
done
