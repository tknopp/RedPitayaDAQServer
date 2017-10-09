#!/bin/bash

sh ./scripts/make_all_cores.sh
vivado -nolog -nojournal -mode batch -source ./src/fpga/build.tcl
