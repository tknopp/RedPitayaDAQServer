#!/bin/bash

declare -a parts=("xc7z010clg400-1" "xc7z020clg400-1")

for part in ${parts[@]}; do
   ./scripts/make_fpga_project.sh "$part"
   ./scripts/make_implementation.sh "$part"
done

