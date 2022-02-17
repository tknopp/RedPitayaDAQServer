# FPGA Development

There may be needs to change the FPGA image. The following explains how this can be done.

## Preparation

If you want to make changes to the FPGA design, you need to install [Vivado 2021.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html). More infos for setting up a development machine we refer to the following [recource](http://pavel-demin.github.io/red-pitaya-notes/development-machine/).

After following the installation steps, you need to clone the repository into a directory of your choice and then regenerate the IP cores and the project by running

`./make_fpga_project.sh`.

Afterwards you can start Vivado and open the recreated project in `./build/fpga/firmware/RedPitayaDAQServer.xpr`. Apply the changes you need and then create the bitfile by using 'Flow -> Generate Bitstream'. This runs the synthesis and implementation steps and output the Bitfile to `./build/fpga/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bit`.

After creating the respective bitfile you need to copy it to your Red Pitayas. You can use

`scp ./build/fpga/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bin root@<IP>:/root/RedPitayaDAQServer/bitfiles/daq_<xc7z010clg400-1,xc7z020clg400-1>.bin`

for this. Set your IP and FPGA version accordingly.

Since using git with Vivado can be annoying here are some hints how you can make your changes ready for git:

* If you only changed some stuff in the blockdesign, you just have to export the blockdesign to `./src/fpga/bd` by using 'File -> Export -> Export Block Design' in Vivado.
* Changes to the project settings have to be done in `./src/fpga/build.tcl` in order to not lose the ability to recreate your changed project.
* For your own IP cores, just create a new directory in `./src/fpga/cores` and copy and adapt the `core_config.tcl` of another core. Afterwards re-run `make_cores.tcl`.
