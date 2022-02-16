# 'make' builds everything
# 'make clean' deletes everything except source files and Makefile
#
# You need to set NAME, PART and PROC for your project.
# NAME is the base name for most of the generated files.

# solves problem with awk while building linux kernel
# solution taken from http://www.googoolia.com/wp/2015/04/21/awk-symbol-lookup-error-awk-undefined-symbol-mpfr_z_sub/
LD_LIBRARY_PATH =

BUILD_DIR = build/linux-image

NAME = led_blinker
PART = xc7z010clg400-1
PROC = ps7_cortexa9_0

CORES = axi_axis_reader_v1_0 port_slicer_v1_0 dna_reader_v1_0 axi_sts_register_v1_0\

DAQ_PARTS = xc7z010clg400-1 xc7z020clg400-1\

VIVADO = vivado -nolog -nojournal -mode batch
XSCT = xsct
RM = rm -rf

UBOOT_TAG = 2021.04
LINUX_TAG = 5.10
DTREE_TAG = xilinx-v2020.2

UBOOT_DIR = $(BUILD_DIR)/tmp/u-boot-$(UBOOT_TAG)
LINUX_DIR = $(BUILD_DIR)/tmp/linux-$(LINUX_TAG)
DTREE_DIR = $(BUILD_DIR)/tmp/device-tree-xlnx-$(DTREE_TAG)

UBOOT_TAR = $(BUILD_DIR)/tmp/u-boot-$(UBOOT_TAG).tar.bz2
LINUX_TAR = $(BUILD_DIR)/tmp/linux-$(LINUX_TAG).tar.xz
DTREE_TAR = $(BUILD_DIR)/tmp/device-tree-xlnx-$(DTREE_TAG).tar.gz

UBOOT_URL = https://ftp.denx.de/pub/u-boot/u-boot-$(UBOOT_TAG).tar.bz2
LINUX_URL = https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$(LINUX_TAG).80.tar.xz
DTREE_URL = https://github.com/Xilinx/device-tree-xlnx/archive/$(DTREE_TAG).tar.gz

RTL8188_TAR = $(BUILD_DIR)/tmp/rtl8188eu-v5.2.2.4.tar.gz
RTL8188_URL = https://github.com/lwfinger/rtl8188eu/archive/v5.2.2.4.tar.gz

RTL8192_TAR = $(BUILD_DIR)/tmp/rtl8192cu-fixes-master.tar.gz
RTL8192_URL = https://github.com/pvaret/rtl8192cu-fixes/archive/master.tar.gz

.PRECIOUS: $(BUILD_DIR)/tmp/cores/% $(BUILD_DIR)/tmp/%.xpr $(BUILD_DIR)/tmp/%.xsa $(BUILD_DIR)/tmp/%.bit $(BUILD_DIR)/tmp/%.fsbl/executable.elf $(BUILD_DIR)/tmp/%.tree/system-top.dts

all: daq_bitfiles $(BUILD_DIR)/tmp/$(NAME).bit $(BUILD_DIR)/boot.bin $(BUILD_DIR)/uImage $(BUILD_DIR)/devicetree.dtb linux

daq_bitfiles: $(addsuffix .bit, $(addprefix bitfiles/daq_,$(DAQ_PARTS)))

bitfiles/daq_%.bit:
	sh scripts/make_fpga_project.sh $*
	sh scripts/make_implementation.sh $*
	
linux: daq_bitfiles $(BUILD_DIR)/tmp/$(NAME).bit $(BUILD_DIR)/boot.bin $(BUILD_DIR)/uImage $(BUILD_DIR)/devicetree.dtb
	sh scripts/alpine.sh

cores: $(addprefix tmp/cores/, $(CORES))

xpr: $(BUILD_DIR)/tmp/$(NAME).xpr

bit: $(BUILD_DIR)/tmp/$(NAME).bit

$(UBOOT_TAR):
	mkdir -p $(@D)
	curl -L $(UBOOT_URL) -o $@

$(LINUX_TAR):
	mkdir -p $(@D)
	curl -L $(LINUX_URL) -o $@

$(DTREE_TAR):
	mkdir -p $(@D)
	curl -L $(DTREE_URL) -o $@

$(RTL8188_TAR):
	mkdir -p $(@D)
	curl -L $(RTL8188_URL) -o $@

$(RTL8192_TAR):
	mkdir -p $(@D)
	curl -L $(RTL8192_URL) -o $@

$(UBOOT_DIR): $(UBOOT_TAR)
	mkdir -p $@
	tar -jxf $< --strip-components=1 --directory=$@
	patch -d $(BUILD_DIR)/tmp -p 0 < linux-image/patches/u-boot-$(UBOOT_TAG).patch
	cp linux-image/patches/zynq_red_pitaya_defconfig $@/configs
	cp linux-image/patches/zynq-red-pitaya.dts $@/arch/arm/dts

$(LINUX_DIR): $(LINUX_TAR) $(RTL8188_TAR) $(RTL8192_TAR)
	mkdir -p $@
	tar -Jxf $< --strip-components=1 --directory=$@
	mkdir -p $@/drivers/net/wireless/realtek/rtl8188eu
	mkdir -p $@/drivers/net/wireless/realtek/rtl8192cu
	tar -zxf $(RTL8188_TAR) --strip-components=1 --directory=$@/drivers/net/wireless/realtek/rtl8188eu
	tar -zxf $(RTL8192_TAR) --strip-components=1 --directory=$@/drivers/net/wireless/realtek/rtl8192cu
	patch -d $(BUILD_DIR)/tmp -p 0 < linux-image/patches/linux-$(LINUX_TAG).patch
	cp linux-image/patches/zynq_ocm.c $@/arch/arm/mach-zynq
	cp linux-image/patches/cma.c $@/drivers/char
	cp linux-image/patches/xilinx_devcfg.c $@/drivers/char
	cp linux-image/patches/xilinx_zynq_defconfig $@/arch/arm/configs

$(DTREE_DIR): $(DTREE_TAR)
	mkdir -p $@
	tar -zxf $< --strip-components=1 --directory=$@

$(BUILD_DIR)/uImage: $(LINUX_DIR)
	make -C $< mrproper
	make -C $< ARCH=arm xilinx_zynq_defconfig
	make -C $< ARCH=arm -j $(shell nproc 2> /dev/null || echo 1) \
	  CROSS_COMPILE=arm-linux-gnueabihf- UIMAGE_LOADADDR=0x8000 \
	  uImage modules
	cp $</arch/arm/boot/uImage $@

$(UBOOT_DIR)/u-boot.bin: $(UBOOT_DIR)
	mkdir -p $(@D)
	make -C $< mrproper
	make -C $< ARCH=arm zynq_red_pitaya_defconfig
	make -C $< ARCH=arm -j $(shell nproc 2> /dev/null || echo 1) \
	  CROSS_COMPILE=arm-linux-gnueabihf- all

$(BUILD_DIR)/boot.bin: $(BUILD_DIR)/tmp/$(NAME).fsbl/executable.elf $(UBOOT_DIR)/u-boot.bin
	echo "img:{[bootloader] $(BUILD_DIR)/tmp/$(NAME).fsbl/executable.elf [load=0x4000000,startup=0x4000000] $(UBOOT_DIR)/u-boot.bin}" > $(BUILD_DIR)/tmp/boot.bif
	bootgen -image $(BUILD_DIR)/tmp/boot.bif -w -o i $@

$(BUILD_DIR)/devicetree.dtb: $(BUILD_DIR)/uImage $(BUILD_DIR)/tmp/$(NAME).tree/system-top.dts
	$(LINUX_DIR)/scripts/dtc/dtc -I dts -O dtb -o $(BUILD_DIR)/devicetree.dtb \
	  -i $(BUILD_DIR)/tmp/$(NAME).tree $(BUILD_DIR)/tmp/$(NAME).tree/system-top.dts

$(BUILD_DIR)/tmp/cores/%: linux-image/cores/%/core_config.tcl linux-image/cores/%/*.v
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/core.tcl -tclargs $* $(PART)

$(BUILD_DIR)/tmp/%.xpr: linux-image/projects/% $(addprefix $(BUILD_DIR)/tmp/cores/, $(CORES))
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/project.tcl -tclargs $* $(PART)

$(BUILD_DIR)/tmp/%.xsa: $(BUILD_DIR)/tmp/%.xpr
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/hwdef.tcl -tclargs $*

$(BUILD_DIR)/tmp/%.bit: $(BUILD_DIR)/tmp/%.xpr
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/bitstream.tcl -tclargs $*

$(BUILD_DIR)/tmp/%.fsbl/executable.elf: $(BUILD_DIR)/tmp/%.xsa
	mkdir -p $(@D)
	$(XSCT) linux-image/scripts/fsbl.tcl $* $(PROC)

$(BUILD_DIR)/tmp/%.tree/system-top.dts: $(BUILD_DIR)/tmp/%.xsa $(DTREE_DIR)
	mkdir -p $(@D)
	$(XSCT) linux-image/scripts/devicetree.tcl $* $(PROC) $(DTREE_DIR)
	sed -i 's|#include|/include/|' $@
	patch -d $(@D) < linux-image/patches/devicetree.patch
	
server: 
	git submodule update --init
	@$(MAKE) install -C libs/scpi-parser
	@$(MAKE) -C libs/scpi-parser
	@$(MAKE) -C src/lib
	@$(MAKE) -C src/server
	@$(MAKE) -C src/test
	cp scripts/daq_server_scpi /etc/init.d/
	chmod +x /etc/init.d/daq_server_scpi
	rc-update add daq_server_scpi default

clean:
	$(RM) $(BUILD_DIR)/uImage $(BUILD_DIR)/boot.bin $(BUILD_DIR)/devicetree.dtb $(BUILD_DIR)/tmp
	$(RM) .Xil usage_statistics_webtalk.html usage_statistics_webtalk.xml
	$(RM) vivado*.jou vivado*.log vivado*.str
	$(RM) webtalk*.jou webtalk*.log
	@$(MAKE) -C src/lib clean
	@$(MAKE) -C src/server clean
