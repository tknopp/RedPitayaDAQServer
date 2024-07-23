# 'make' builds everything
# 'make clean' deletes everything except source files and Makefile
#
# You need to set NAME, PART and PROC for your project.
# NAME is the base name for most of the generated files.

# solves problem with awk while building linux kernel
# solution taken from http://www.googoolia.com/wp/2015/04/21/awk-symbol-lookup-error-awk-undefined-symbol-mpfr_z_sub/
LD_LIBRARY_PATH =

NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
#MAKEFLAGS += -j$(NPROCS)

LINUX_BUILD_DIR = build/linux-image
FPGA_BUILD_DIR = build/fpga

NAME = led_blinker
PART = xc7z010clg400-1
PROC = ps7_cortexa9_0

BLINKER_CORES = axi_axis_reader_v1_0 port_slicer_v1_0 dna_reader_v1_0 axi_sts_register_v1_0

DAQ_CORES = axi_cfg_register_v1_0 axis_variable_v1_0 pdm_multiplexer_v1_0 \
  axis_breaker_v1_0 burstMode_v1_0 pdm_v1_0 \
  axis_ram_writer_v1_0 cfg_clk_div_v1_1 pdm_value_supply_v1_0 \
  axis_red_pitaya_adc_v1_0 clk_div_v1_0 red_pitaya_dfilt1_v1_0 \
  axis_red_pitaya_dac_v1_0 dio_v1_0 shift_by_n_v1_0 \
  axis_select_v1_0 divide_by_two_v1_0 signal_generator_v1_0 \
  axi_sts_register_v1_0 fourier_synthesizer_v1_0 sequence_bram_reader_v1_0

DAQ_PARTS = xc7z010clg400-1 xc7z020clg400-1

VIVADO = vivado -nolog -nojournal -mode batch
XSCT = xsct
RM = rm -rf

UBOOT_TAG = 2021.04
LINUX_TAG = 5.10
DTREE_TAG = xilinx-v2020.2

UBOOT_DIR = $(LINUX_BUILD_DIR)/tmp/u-boot-$(UBOOT_TAG)
LINUX_DIR = $(LINUX_BUILD_DIR)/tmp/linux-$(LINUX_TAG)
DTREE_DIR = $(LINUX_BUILD_DIR)/tmp/device-tree-xlnx-$(DTREE_TAG)

UBOOT_TAR = $(LINUX_BUILD_DIR)/tmp/u-boot-$(UBOOT_TAG).tar.bz2
LINUX_TAR = $(LINUX_BUILD_DIR)/tmp/linux-$(LINUX_TAG).tar.xz
DTREE_TAR = $(LINUX_BUILD_DIR)/tmp/device-tree-xlnx-$(DTREE_TAG).tar.gz

UBOOT_URL = https://ftp.denx.de/pub/u-boot/u-boot-$(UBOOT_TAG).tar.bz2
LINUX_URL = https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$(LINUX_TAG).80.tar.xz
DTREE_URL = https://github.com/Xilinx/device-tree-xlnx/archive/$(DTREE_TAG).tar.gz

RTL8188_TAR = $(LINUX_BUILD_DIR)/tmp/rtl8188eu-v5.2.2.4.tar.gz
RTL8188_URL = https://github.com/lwfinger/rtl8188eu/archive/v5.2.2.4.tar.gz

RTL8192_TAR = $(LINUX_BUILD_DIR)/tmp/rtl8192cu-fixes-master.tar.gz
RTL8192_URL = https://github.com/pvaret/rtl8192cu-fixes/archive/master.tar.gz

.PRECIOUS: $(LINUX_BUILD_DIR)/tmp/cores/% $(LINUX_BUILD_DIR)/tmp/%.xpr $(LINUX_BUILD_DIR)/tmp/%.xsa $(LINUX_BUILD_DIR)/tmp/%.bit $(LINUX_BUILD_DIR)/tmp/%.fsbl/executable.elf $(LINUX_BUILD_DIR)/tmp/%.tree/system-top.dts

all: linux

daq_bitfiles: $(addsuffix .bit, $(addprefix bitfiles/daq_,$(DAQ_PARTS)))

bitfiles/daq_%.bit: daq_cores
ifeq ("$(wildcard bitfiles/daq_$*.bit)","")
	vivado -nolog -nojournal -mode batch -source src/fpga/build.tcl -tclargs $*
	vivado -nolog -nojournal -mode batch -source scripts/runSynthAndImpl.tcl -tclargs $*
	mkdir -p bitfiles
	cp build/fpga/$*/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bit bitfiles/daq_$*.bit
endif
	
linux: daq_bitfiles $(LINUX_BUILD_DIR)/tmp/$(NAME).bit $(LINUX_BUILD_DIR)/boot.bin $(LINUX_BUILD_DIR)/uImage $(LINUX_BUILD_DIR)/devicetree.dtb
	sh scripts/alpine.sh

blinker_cores: $(addprefix tmp/cores/, $(BLINKER_CORES))

#$(subst $(SPACE),_,$(wordlist 1,$(call subtract,$(words $(subst _, ,$(1))),2),$(subst _, ,$(1)))) # Doesn't work yet
define strip_core_version
$(shell python3 -c "print('_'.join('$(1)'.split('_')[:-2]))")
endef

define GEN_DAQ_CORE_RULE
$(FPGA_BUILD_DIR)/${daq_part}/cores/$(call strip_core_version,$(daq_core)).xpr: src/fpga/cores/$(daq_core)/core_config.tcl src/fpga/cores/$(daq_core)/*.v
	#mkdir -p $(@D)
	$(VIVADO)  -source scripts/core.tcl -tclargs ${daq_core} ${daq_part}
endef

$(foreach daq_part,$(DAQ_PARTS), \
$(foreach daq_core,$(DAQ_CORES), \
$(eval $(GEN_DAQ_CORE_RULE)) \
) \
)

define GEN_DAQ_CORES_PART_RULE
daq_cores_${daq_part}: $(addsuffix .xpr, $(addprefix $(FPGA_BUILD_DIR)/${daq_part}/cores/, $(foreach daq_core,$(DAQ_CORES),$(call strip_core_version,$(daq_core)))))
endef

$(foreach daq_part,$(DAQ_PARTS), \
$(eval $(GEN_DAQ_CORES_PART_RULE)) \
)

daq_cores: $(addprefix daq_cores_,$(DAQ_PARTS))

xpr: $(LINUX_BUILD_DIR)/tmp/$(NAME).xpr

bit: $(LINUX_BUILD_DIR)/tmp/$(NAME).bit

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
	patch -d $(LINUX_BUILD_DIR)/tmp -p 0 < linux-image/patches/u-boot-$(UBOOT_TAG).patch
	cp linux-image/patches/zynq_red_pitaya_defconfig $@/configs
	cp linux-image/patches/zynq-red-pitaya.dts $@/arch/arm/dts

$(LINUX_DIR): $(LINUX_TAR) $(RTL8188_TAR) $(RTL8192_TAR)
	mkdir -p $@
	tar -Jxf $< --strip-components=1 --directory=$@
	mkdir -p $@/drivers/net/wireless/realtek/rtl8188eu
	mkdir -p $@/drivers/net/wireless/realtek/rtl8192cu
	tar -zxf $(RTL8188_TAR) --strip-components=1 --directory=$@/drivers/net/wireless/realtek/rtl8188eu
	tar -zxf $(RTL8192_TAR) --strip-components=1 --directory=$@/drivers/net/wireless/realtek/rtl8192cu
	patch -d $(LINUX_BUILD_DIR)/tmp -p 0 < linux-image/patches/linux-$(LINUX_TAG).patch
	cp linux-image/patches/zynq_ocm.c $@/arch/arm/mach-zynq
	cp linux-image/patches/cma.c $@/drivers/char
	cp linux-image/patches/xilinx_devcfg.c $@/drivers/char
	cp linux-image/patches/xilinx_zynq_defconfig $@/arch/arm/configs

$(DTREE_DIR): $(DTREE_TAR)
	mkdir -p $@
	tar -zxf $< --strip-components=1 --directory=$@

$(LINUX_BUILD_DIR)/uImage: $(LINUX_DIR)
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

$(LINUX_BUILD_DIR)/boot.bin: $(LINUX_BUILD_DIR)/tmp/$(NAME).fsbl/executable.elf $(UBOOT_DIR)/u-boot.bin
	echo "img:{[bootloader] $(LINUX_BUILD_DIR)/tmp/$(NAME).fsbl/executable.elf [load=0x4000000,startup=0x4000000] $(UBOOT_DIR)/u-boot.bin}" > $(LINUX_BUILD_DIR)/tmp/boot.bif
	bootgen -image $(LINUX_BUILD_DIR)/tmp/boot.bif -w -o i $@

$(LINUX_BUILD_DIR)/devicetree.dtb: $(LINUX_BUILD_DIR)/uImage $(LINUX_BUILD_DIR)/tmp/$(NAME).tree/system-top.dts
	$(LINUX_DIR)/scripts/dtc/dtc -I dts -O dtb -o $(LINUX_BUILD_DIR)/devicetree.dtb \
	  -i $(LINUX_BUILD_DIR)/tmp/$(NAME).tree $(LINUX_BUILD_DIR)/tmp/$(NAME).tree/system-top.dts

$(LINUX_BUILD_DIR)/tmp/cores/%: linux-image/cores/%/core_config.tcl linux-image/cores/%/*.v
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/core.tcl -tclargs $* $(PART)

$(LINUX_BUILD_DIR)/tmp/%.xpr: linux-image/projects/% $(addprefix $(LINUX_BUILD_DIR)/tmp/cores/, $(BLINKER_CORES))
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/project.tcl -tclargs $* $(PART)

$(LINUX_BUILD_DIR)/tmp/%.xsa: $(LINUX_BUILD_DIR)/tmp/%.xpr
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/hwdef.tcl -tclargs $*

$(LINUX_BUILD_DIR)/tmp/%.bit: $(LINUX_BUILD_DIR)/tmp/%.xpr
	mkdir -p $(@D)
	$(VIVADO) -source linux-image/scripts/bitstream.tcl -tclargs $*

$(LINUX_BUILD_DIR)/tmp/%.fsbl/executable.elf: $(LINUX_BUILD_DIR)/tmp/%.xsa
	mkdir -p $(@D)
	$(XSCT) linux-image/scripts/fsbl.tcl $* $(PROC)

$(LINUX_BUILD_DIR)/tmp/%.tree/system-top.dts: $(LINUX_BUILD_DIR)/tmp/%.xsa $(DTREE_DIR)
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
	cp scripts/daq_server_scpi /etc/init.d/
	chmod +x /etc/init.d/daq_server_scpi
	rc-update add daq_server_scpi default

clean:
	$(RM) $(LINUX_BUILD_DIR)/uImage $(LINUX_BUILD_DIR)/boot.bin $(LINUX_BUILD_DIR)/devicetree.dtb $(LINUX_BUILD_DIR)/tmp
	$(RM) -r bitfiles
	$(RM) -r build/fpga
	$(RM) red-pitaya*.zip
	$(RM) .Xil usage_statistics_webtalk.html usage_statistics_webtalk.xml
	$(RM) vivado*.jou vivado*.log vivado*.str
	$(RM) webtalk*.jou webtalk*.log
	@$(MAKE) -C src/lib clean
	@$(MAKE) -C src/server clean
