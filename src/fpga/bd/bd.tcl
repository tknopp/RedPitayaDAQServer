
################################################################
# This is a generated script based on design: system
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2021.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# reset_manager, enable_ramping_slice, bram_address_converter, sequence_slice, sequence_stepper, signal_cfg_slice, signal_composer, signal_cfg_slice, signal_composer, bram_address_converter, bram_address_converter

# Please add the sources of those modules before sourcing this Tcl script.


# The design that will be created by this Tcl script contains the following 
# block design container source references:
# signal_calib, signal_ramp, waveform_gen, waveform_gen_awg

# Please add the sources before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name system

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
pavel-demin:user:axis_red_pitaya_adc:1.0\
pavel-demin:user:axis_red_pitaya_dac:1.0\
xilinx.com:ip:clk_wiz:6.0\
jbeuke:user:dio:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:selectio_wiz:5.1\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:xadc_wiz:3.3\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:xlslice:1.0\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:blk_mem_gen:8.4\
koheron:user:pdm:1.0\
pavel-demin:user:axi_cfg_register:1.0\
pavel-demin:user:axi_sts_register:1.0\
xilinx.com:ip:processing_system7:5.5\
xilinx.com:ip:axis_dwidth_converter:1.1\
pavel-demin:user:axis_ram_writer:1.0\
pavel-demin:user:axis_variable:1.0\
xilinx.com:ip:cic_compiler:4.0\
jbeuke:user:divide_by_two:1.0\
xilinx.com:ip:fir_compiler:7.2\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
reset_manager\
enable_ramping_slice\
bram_address_converter\
sequence_slice\
sequence_stepper\
signal_cfg_slice\
signal_composer\
signal_cfg_slice\
signal_composer\
bram_address_converter\
bram_address_converter\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

##################################################################
# CHECK Block Design Container Sources
##################################################################
set bCheckSources 1
set list_bdc_active "signal_calib, signal_ramp, waveform_gen, waveform_gen_awg"

array set map_bdc_missing {}
set map_bdc_missing(ACTIVE) ""
set map_bdc_missing(BDC) ""

if { $bCheckSources == 1 } {
   set list_check_srcs "\ 
signal_calib \
signal_ramp \
waveform_gen \
waveform_gen_awg \
"

   common::send_gid_msg -ssname BD::TCL -id 2056 -severity "INFO" "Checking if the following sources for block design container exist in the project: $list_check_srcs .\n\n"

   foreach src $list_check_srcs {
      if { [can_resolve_reference $src] == 0 } {
         if { [lsearch $list_bdc_active $src] != -1 } {
            set map_bdc_missing(ACTIVE) "$map_bdc_missing(ACTIVE) $src"
         } else {
            set map_bdc_missing(BDC) "$map_bdc_missing(BDC) $src"
         }
      }
   }

   if { [llength $map_bdc_missing(ACTIVE)] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2057 -severity "ERROR" "The following source(s) of Active variants are not found in the project: $map_bdc_missing(ACTIVE)" }
      common::send_gid_msg -ssname BD::TCL -id 2060 -severity "INFO" "Please add source files for the missing source(s) above."
      set bCheckIPsPassed 0
   }
   if { [llength $map_bdc_missing(BDC)] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2059 -severity "WARNING" "The following source(s) of variants are not found in the project: $map_bdc_missing(BDC)" }
      common::send_gid_msg -ssname BD::TCL -id 2060 -severity "INFO" "Please add source files for the missing source(s) above."
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: waveform_awg1
proc create_hier_cell_waveform_awg1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_waveform_awg1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI


  # Create pins
  create_bd_pin -dir O -from 15 -to 0 S
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I bram_aresetn
  create_bd_pin -dir I -from 47 -to 0 freq
  create_bd_pin -dir I -from 47 -to 0 phase

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_0

  # Create instance: bram_address_convert_0, and set properties
  set block_name bram_address_converter
  set block_cell_name bram_address_convert_0
  if { [catch {set bram_address_convert_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bram_address_convert_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: waveform_gen_awg_0, and set properties
  set waveform_gen_awg_0 [ create_bd_cell -type container -reference waveform_gen_awg waveform_gen_awg_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen_awg.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen_awg.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen_awg.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen_awg.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_awg_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net awg_bram_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net bram_address_convert_0_addr [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins bram_address_convert_0/addr]
  connect_bd_net -net bram_aresetn_1 [get_bd_pins bram_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  connect_bd_net -net bram_wave_1 [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins waveform_gen_awg_0/bram_wave]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_pins aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins bram_address_convert_0/clk] [get_bd_pins waveform_gen_awg_0/aclk]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins waveform_gen_awg_0/aresetn]
  connect_bd_net -net signal_cfg_slice_0_comp_0_freq [get_bd_pins freq] [get_bd_pins waveform_gen_awg_0/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_0_phase [get_bd_pins phase] [get_bd_pins waveform_gen_awg_0/phase]
  connect_bd_net -net waveform_gen_awg_0_bram_element [get_bd_pins bram_address_convert_0/elAddr] [get_bd_pins waveform_gen_awg_0/bram_element]
  connect_bd_net -net waveform_gen_awg_0_wave_awg [get_bd_pins S] [get_bd_pins waveform_gen_awg_0/wave_awg]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins blk_mem_gen_0/enb] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: waveform_awg
proc create_hier_cell_waveform_awg { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_waveform_awg() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI


  # Create pins
  create_bd_pin -dir O -from 15 -to 0 S
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I bram_aresetn
  create_bd_pin -dir I -from 47 -to 0 freq
  create_bd_pin -dir I -from 47 -to 0 phase

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_0

  # Create instance: bram_address_convert_0, and set properties
  set block_name bram_address_converter
  set block_cell_name bram_address_convert_0
  if { [catch {set bram_address_convert_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bram_address_convert_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: waveform_gen_awg_0, and set properties
  set waveform_gen_awg_0 [ create_bd_cell -type container -reference waveform_gen_awg waveform_gen_awg_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen_awg.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen_awg.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen_awg.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen_awg.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_awg_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins bram_address_convert_0/clk] [get_bd_pins waveform_gen_awg_0/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins waveform_gen_awg_0/aresetn]
  connect_bd_net -net blk_mem_gen_0_doutb [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins waveform_gen_awg_0/bram_wave]
  connect_bd_net -net bram_address_convert_0_addr [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins bram_address_convert_0/addr]
  connect_bd_net -net bram_aresetn_1 [get_bd_pins bram_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  connect_bd_net -net signal_cfg_slice_0_comp_0_freq [get_bd_pins freq] [get_bd_pins waveform_gen_awg_0/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_0_phase [get_bd_pins phase] [get_bd_pins waveform_gen_awg_0/phase]
  connect_bd_net -net waveform_awg_wave_awg [get_bd_pins S] [get_bd_pins waveform_gen_awg_0/wave_awg]
  connect_bd_net -net waveform_gen_awg_0_bram_element [get_bd_pins bram_address_convert_0/elAddr] [get_bd_pins waveform_gen_awg_0/bram_element]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins blk_mem_gen_0/enb] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: sign_extend_B
proc create_hier_cell_sign_extend_B { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_sign_extend_B() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -from 13 -to 0 In0
  create_bd_pin -dir O -from 15 -to 0 dout

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {14} \
   CONFIG.IN1_WIDTH {1} \
   CONFIG.IN2_WIDTH {1} \
   CONFIG.NUM_PORTS {3} \
 ] $xlconcat_2

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {13} \
   CONFIG.DIN_TO {13} \
   CONFIG.DIN_WIDTH {14} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_2

  # Create port connections
  connect_bd_net -net red_pitaya_dfilt1_A_adc_dat_o [get_bd_pins In0] [get_bd_pins xlconcat_2/In0] [get_bd_pins xlslice_2/Din]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins dout] [get_bd_pins xlconcat_2/dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins xlconcat_2/In1] [get_bd_pins xlconcat_2/In2] [get_bd_pins xlslice_2/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: sign_extend_A
proc create_hier_cell_sign_extend_A { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_sign_extend_A() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -from 13 -to 0 In0
  create_bd_pin -dir O -from 15 -to 0 dout

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {14} \
   CONFIG.IN1_WIDTH {1} \
   CONFIG.IN2_WIDTH {1} \
   CONFIG.NUM_PORTS {3} \
 ] $xlconcat_2

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {13} \
   CONFIG.DIN_TO {13} \
   CONFIG.DIN_WIDTH {14} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_2

  # Create port connections
  connect_bd_net -net red_pitaya_dfilt1_A_adc_dat_o [get_bd_pins In0] [get_bd_pins xlconcat_2/In0] [get_bd_pins xlslice_2/Din]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins dout] [get_bd_pins xlconcat_2/dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins xlconcat_2/In1] [get_bd_pins xlconcat_2/In2] [get_bd_pins xlslice_2/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: signal_compose1
proc create_hier_cell_signal_compose1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_signal_compose1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 awg_bram


  # Create pins
  create_bd_pin -dir I -from 831 -to 0 Din
  create_bd_pin -dir O -from 15 -to 0 -type data S
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I bram_aresetn
  create_bd_pin -dir I disable_dac
  create_bd_pin -dir I enable_ramping
  create_bd_pin -dir O -from 0 -to 0 m_axis_data_tvalid_1
  create_bd_pin -dir I -from 15 -to 0 offset
  create_bd_pin -dir O -from 1 -to 0 ramp_state_1
  create_bd_pin -dir I start_ramp_down

  # Create instance: signal_calib_0, and set properties
  set signal_calib_0 [ create_bd_cell -type container -reference signal_calib signal_calib_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {signal_calib.bd} \
   CONFIG.ACTIVE_SYNTH_BD {signal_calib.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {signal_calib.bd} \
   CONFIG.LIST_SYNTH_BD {signal_calib.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $signal_calib_0

  # Create instance: signal_cfg_slice_0, and set properties
  set block_name signal_cfg_slice
  set block_cell_name signal_cfg_slice_0
  if { [catch {set signal_cfg_slice_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $signal_cfg_slice_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: signal_composer_0, and set properties
  set block_name signal_composer
  set block_cell_name signal_composer_0
  if { [catch {set signal_composer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $signal_composer_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: signal_ramp_0, and set properties
  set signal_ramp_0 [ create_bd_cell -type container -reference signal_ramp signal_ramp_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {signal_ramp.bd} \
   CONFIG.ACTIVE_SYNTH_BD {signal_ramp.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {signal_ramp.bd} \
   CONFIG.LIST_SYNTH_BD {signal_ramp.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $signal_ramp_0

  # Create instance: waveform_awg1
  create_hier_cell_waveform_awg1 $hier_obj waveform_awg1

  # Create instance: waveform_gen_0, and set properties
  set waveform_gen_0 [ create_bd_cell -type container -reference waveform_gen waveform_gen_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_0

  # Create instance: waveform_gen_1, and set properties
  set waveform_gen_1 [ create_bd_cell -type container -reference waveform_gen waveform_gen_1 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_1

  # Create instance: waveform_gen_2, and set properties
  set waveform_gen_2 [ create_bd_cell -type container -reference waveform_gen waveform_gen_2 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_2

  # Create instance: waveform_gen_3, and set properties
  set waveform_gen_3 [ create_bd_cell -type container -reference waveform_gen waveform_gen_3 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_3

  # Create interface connections
  connect_bd_intf_net -intf_net awg_bram_1 [get_bd_intf_pins awg_bram] [get_bd_intf_pins waveform_awg1/S_AXI]

  # Create port connections
  connect_bd_net -net Din_1 [get_bd_pins Din] [get_bd_pins signal_cfg_slice_0/cfg_data]
  connect_bd_net -net bram_aresetn_1 [get_bd_pins bram_aresetn] [get_bd_pins waveform_awg1/bram_aresetn]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_pins aclk] [get_bd_pins signal_calib_0/aclk] [get_bd_pins signal_composer_0/clk] [get_bd_pins signal_ramp_0/aclk] [get_bd_pins waveform_awg1/aclk] [get_bd_pins waveform_gen_0/aclk] [get_bd_pins waveform_gen_1/aclk] [get_bd_pins waveform_gen_2/aclk] [get_bd_pins waveform_gen_3/aclk]
  connect_bd_net -net disable_dac_1 [get_bd_pins disable_dac] [get_bd_pins signal_composer_0/disable_dac]
  connect_bd_net -net enable_ramping_1 [get_bd_pins enable_ramping] [get_bd_pins signal_ramp_0/enableRamping]
  connect_bd_net -net offset_1 [get_bd_pins offset] [get_bd_pins signal_composer_0/seq]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins signal_ramp_0/aresetn] [get_bd_pins waveform_awg1/aresetn] [get_bd_pins waveform_gen_0/aresetn] [get_bd_pins waveform_gen_1/aresetn] [get_bd_pins waveform_gen_2/aresetn] [get_bd_pins waveform_gen_3/aresetn]
  connect_bd_net -net signal_cfg_slice_0_calib_offset [get_bd_pins signal_calib_0/calib_offset] [get_bd_pins signal_cfg_slice_0/calib_offset]
  connect_bd_net -net signal_cfg_slice_0_calib_scale [get_bd_pins signal_calib_0/calib_scale] [get_bd_pins signal_cfg_slice_0/calib_scale]
  connect_bd_net -net signal_cfg_slice_0_comp_0_amp [get_bd_pins signal_cfg_slice_0/comp_0_amp] [get_bd_pins waveform_gen_0/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_0_cfg [get_bd_pins signal_cfg_slice_0/comp_0_cfg] [get_bd_pins waveform_gen_0/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_0_freq [get_bd_pins signal_cfg_slice_0/comp_0_freq] [get_bd_pins waveform_awg1/freq] [get_bd_pins waveform_gen_0/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_0_phase [get_bd_pins signal_cfg_slice_0/comp_0_phase] [get_bd_pins waveform_awg1/phase] [get_bd_pins waveform_gen_0/phase]
  connect_bd_net -net signal_cfg_slice_0_comp_1_amp [get_bd_pins signal_cfg_slice_0/comp_1_amp] [get_bd_pins waveform_gen_1/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_1_cfg [get_bd_pins signal_cfg_slice_0/comp_1_cfg] [get_bd_pins waveform_gen_1/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_1_freq [get_bd_pins signal_cfg_slice_0/comp_1_freq] [get_bd_pins waveform_gen_1/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_1_phase [get_bd_pins signal_cfg_slice_0/comp_1_phase] [get_bd_pins waveform_gen_1/phase]
  connect_bd_net -net signal_cfg_slice_0_comp_2_amp [get_bd_pins signal_cfg_slice_0/comp_2_amp] [get_bd_pins waveform_gen_2/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_2_cfg [get_bd_pins signal_cfg_slice_0/comp_2_cfg] [get_bd_pins waveform_gen_2/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_2_freq [get_bd_pins signal_cfg_slice_0/comp_2_freq] [get_bd_pins waveform_gen_2/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_2_phase [get_bd_pins signal_cfg_slice_0/comp_2_phase] [get_bd_pins waveform_gen_2/phase]
  connect_bd_net -net signal_cfg_slice_0_comp_3_amp [get_bd_pins signal_cfg_slice_0/comp_3_amp] [get_bd_pins waveform_gen_3/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_3_cfg [get_bd_pins signal_cfg_slice_0/comp_3_cfg] [get_bd_pins waveform_gen_3/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_3_freq [get_bd_pins signal_cfg_slice_0/comp_3_freq] [get_bd_pins waveform_gen_3/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_3_phase [get_bd_pins signal_cfg_slice_0/comp_3_phase] [get_bd_pins waveform_gen_3/phase]
  connect_bd_net -net signal_cfg_slice_0_offset [get_bd_pins signal_cfg_slice_0/offset] [get_bd_pins signal_composer_0/offset]
  connect_bd_net -net signal_cfg_slice_0_ramp_freq [get_bd_pins signal_cfg_slice_0/ramp_freq] [get_bd_pins signal_ramp_0/freq]
  connect_bd_net -net signal_composer_0_signal_out [get_bd_pins signal_composer_0/signal_out] [get_bd_pins signal_ramp_0/signal_in]
  connect_bd_net -net signal_composer_0_signal_valid [get_bd_pins m_axis_data_tvalid_1] [get_bd_pins signal_composer_0/signal_valid]
  connect_bd_net -net signal_ramp_0_ramp_state [get_bd_pins ramp_state_1] [get_bd_pins signal_ramp_0/ramp_state]
  connect_bd_net -net signal_ramp_0_signal_out [get_bd_pins signal_calib_0/signal_in] [get_bd_pins signal_ramp_0/signal_out]
  connect_bd_net -net start_ramp_down_1 [get_bd_pins start_ramp_down] [get_bd_pins signal_ramp_0/startRampDown]
  connect_bd_net -net waveform_gen_0_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid0] [get_bd_pins waveform_gen_0/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_0_wave [get_bd_pins signal_composer_0/wave0] [get_bd_pins waveform_gen_0/wave]
  connect_bd_net -net waveform_gen_1_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid1] [get_bd_pins waveform_gen_1/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_1_wave [get_bd_pins signal_composer_0/wave1] [get_bd_pins waveform_gen_1/wave]
  connect_bd_net -net waveform_gen_2_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid2] [get_bd_pins waveform_gen_2/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_2_wave [get_bd_pins signal_composer_0/wave2] [get_bd_pins waveform_gen_2/wave]
  connect_bd_net -net waveform_gen_3_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid3] [get_bd_pins waveform_gen_3/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_3_wave [get_bd_pins signal_composer_0/wave3] [get_bd_pins waveform_gen_3/wave]
  connect_bd_net -net waveform_gen_awg_0_wave_awg [get_bd_pins S] [get_bd_pins waveform_awg1/S]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: signal_compose
proc create_hier_cell_signal_compose { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_signal_compose() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 awg_bram


  # Create pins
  create_bd_pin -dir I -from 831 -to 0 Din
  create_bd_pin -dir O -from 15 -to 0 -type data S
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I bram_aresetn
  create_bd_pin -dir I disable_dac
  create_bd_pin -dir I enable_ramping
  create_bd_pin -dir O -from 0 -to 0 m_axis_data_tvalid_1
  create_bd_pin -dir I -from 15 -to 0 offset
  create_bd_pin -dir O -from 1 -to 0 ramp_state_0
  create_bd_pin -dir I start_ramp_down

  # Create instance: signal_calib_0, and set properties
  set signal_calib_0 [ create_bd_cell -type container -reference signal_calib signal_calib_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {signal_calib.bd} \
   CONFIG.ACTIVE_SYNTH_BD {signal_calib.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {signal_calib.bd} \
   CONFIG.LIST_SYNTH_BD {signal_calib.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $signal_calib_0

  # Create instance: signal_cfg_slice_0, and set properties
  set block_name signal_cfg_slice
  set block_cell_name signal_cfg_slice_0
  if { [catch {set signal_cfg_slice_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $signal_cfg_slice_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: signal_composer_0, and set properties
  set block_name signal_composer
  set block_cell_name signal_composer_0
  if { [catch {set signal_composer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $signal_composer_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: signal_ramp, and set properties
  set signal_ramp [ create_bd_cell -type container -reference signal_ramp signal_ramp ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {signal_ramp.bd} \
   CONFIG.ACTIVE_SYNTH_BD {signal_ramp.bd} \
   CONFIG.ENABLE_DFX {false} \
   CONFIG.LIST_SIM_BD {signal_ramp.bd} \
   CONFIG.LIST_SYNTH_BD {signal_ramp.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $signal_ramp

  # Create instance: waveform_awg
  create_hier_cell_waveform_awg $hier_obj waveform_awg

  # Create instance: waveform_gen_0, and set properties
  set waveform_gen_0 [ create_bd_cell -type container -reference waveform_gen waveform_gen_0 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_0

  # Create instance: waveform_gen_1, and set properties
  set waveform_gen_1 [ create_bd_cell -type container -reference waveform_gen waveform_gen_1 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_1

  # Create instance: waveform_gen_2, and set properties
  set waveform_gen_2 [ create_bd_cell -type container -reference waveform_gen waveform_gen_2 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_2

  # Create instance: waveform_gen_3, and set properties
  set waveform_gen_3 [ create_bd_cell -type container -reference waveform_gen waveform_gen_3 ]
  set_property -dict [ list \
   CONFIG.ACTIVE_SIM_BD {waveform_gen.bd} \
   CONFIG.ACTIVE_SYNTH_BD {waveform_gen.bd} \
   CONFIG.ENABLE_DFX {0} \
   CONFIG.LIST_SIM_BD {waveform_gen.bd} \
   CONFIG.LIST_SYNTH_BD {waveform_gen.bd} \
   CONFIG.LOCK_PROPAGATE {0} \
 ] $waveform_gen_3

  # Create interface connections
  connect_bd_intf_net -intf_net awg_bram_1 [get_bd_intf_pins awg_bram] [get_bd_intf_pins waveform_awg/S_AXI]

  # Create port connections
  connect_bd_net -net Din_1 [get_bd_pins Din] [get_bd_pins signal_cfg_slice_0/cfg_data]
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins signal_calib_0/aclk] [get_bd_pins signal_composer_0/clk] [get_bd_pins signal_ramp/aclk] [get_bd_pins waveform_awg/aclk] [get_bd_pins waveform_gen_0/aclk] [get_bd_pins waveform_gen_1/aclk] [get_bd_pins waveform_gen_2/aclk] [get_bd_pins waveform_gen_3/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins signal_ramp/aresetn] [get_bd_pins waveform_awg/aresetn] [get_bd_pins waveform_gen_0/aresetn] [get_bd_pins waveform_gen_1/aresetn] [get_bd_pins waveform_gen_2/aresetn] [get_bd_pins waveform_gen_3/aresetn]
  connect_bd_net -net bram_aresetn_1 [get_bd_pins bram_aresetn] [get_bd_pins waveform_awg/bram_aresetn]
  connect_bd_net -net disable_dac_1 [get_bd_pins disable_dac] [get_bd_pins signal_composer_0/disable_dac]
  connect_bd_net -net offset_1 [get_bd_pins offset] [get_bd_pins signal_composer_0/seq]
  connect_bd_net -net ramping_enable_1 [get_bd_pins enable_ramping] [get_bd_pins signal_ramp/enableRamping]
  connect_bd_net -net signal_cfg_slice_0_calib_offset [get_bd_pins signal_calib_0/calib_offset] [get_bd_pins signal_cfg_slice_0/calib_offset]
  connect_bd_net -net signal_cfg_slice_0_calib_scale [get_bd_pins signal_calib_0/calib_scale] [get_bd_pins signal_cfg_slice_0/calib_scale]
  connect_bd_net -net signal_cfg_slice_0_comp_0_amp [get_bd_pins signal_cfg_slice_0/comp_0_amp] [get_bd_pins waveform_gen_0/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_0_cfg [get_bd_pins signal_cfg_slice_0/comp_0_cfg] [get_bd_pins waveform_gen_0/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_0_freq [get_bd_pins signal_cfg_slice_0/comp_0_freq] [get_bd_pins waveform_awg/freq] [get_bd_pins waveform_gen_0/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_0_phase [get_bd_pins signal_cfg_slice_0/comp_0_phase] [get_bd_pins waveform_awg/phase] [get_bd_pins waveform_gen_0/phase]
  connect_bd_net -net signal_cfg_slice_0_comp_1_amp [get_bd_pins signal_cfg_slice_0/comp_1_amp] [get_bd_pins waveform_gen_1/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_1_cfg [get_bd_pins signal_cfg_slice_0/comp_1_cfg] [get_bd_pins waveform_gen_1/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_1_freq [get_bd_pins signal_cfg_slice_0/comp_1_freq] [get_bd_pins waveform_gen_1/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_1_phase [get_bd_pins signal_cfg_slice_0/comp_1_phase] [get_bd_pins waveform_gen_1/phase]
  connect_bd_net -net signal_cfg_slice_0_comp_2_amp [get_bd_pins signal_cfg_slice_0/comp_2_amp] [get_bd_pins waveform_gen_2/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_2_cfg [get_bd_pins signal_cfg_slice_0/comp_2_cfg] [get_bd_pins waveform_gen_2/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_2_freq [get_bd_pins signal_cfg_slice_0/comp_2_freq] [get_bd_pins waveform_gen_2/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_2_phase [get_bd_pins signal_cfg_slice_0/comp_2_phase] [get_bd_pins waveform_gen_2/phase]
  connect_bd_net -net signal_cfg_slice_0_comp_3_amp [get_bd_pins signal_cfg_slice_0/comp_3_amp] [get_bd_pins waveform_gen_3/amplitude]
  connect_bd_net -net signal_cfg_slice_0_comp_3_cfg [get_bd_pins signal_cfg_slice_0/comp_3_cfg] [get_bd_pins waveform_gen_3/cfg_data]
  connect_bd_net -net signal_cfg_slice_0_comp_3_freq [get_bd_pins signal_cfg_slice_0/comp_3_freq] [get_bd_pins waveform_gen_3/freq]
  connect_bd_net -net signal_cfg_slice_0_comp_3_phase [get_bd_pins signal_cfg_slice_0/comp_3_phase] [get_bd_pins waveform_gen_3/phase]
  connect_bd_net -net signal_cfg_slice_0_offset [get_bd_pins signal_cfg_slice_0/offset] [get_bd_pins signal_composer_0/offset]
  connect_bd_net -net signal_cfg_slice_0_ramp_freq [get_bd_pins signal_cfg_slice_0/ramp_freq] [get_bd_pins signal_ramp/freq]
  connect_bd_net -net signal_composer_0_signal_out [get_bd_pins signal_composer_0/signal_out] [get_bd_pins signal_ramp/signal_in]
  connect_bd_net -net signal_composer_0_signal_valid [get_bd_pins m_axis_data_tvalid_1] [get_bd_pins signal_composer_0/signal_valid]
  connect_bd_net -net signal_ramp_ramp_state [get_bd_pins ramp_state_0] [get_bd_pins signal_ramp/ramp_state]
  connect_bd_net -net signal_ramp_signal_out [get_bd_pins signal_calib_0/signal_in] [get_bd_pins signal_ramp/signal_out]
  connect_bd_net -net start_ramp_down_1 [get_bd_pins start_ramp_down] [get_bd_pins signal_ramp/startRampDown]
  connect_bd_net -net waveform_awg_wave_awg [get_bd_pins S] [get_bd_pins waveform_awg/S]
  connect_bd_net -net waveform_gen_0_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid0] [get_bd_pins waveform_gen_0/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_0_wave [get_bd_pins signal_composer_0/wave0] [get_bd_pins waveform_gen_0/wave]
  connect_bd_net -net waveform_gen_1_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid1] [get_bd_pins waveform_gen_1/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_1_wave [get_bd_pins signal_composer_0/wave1] [get_bd_pins waveform_gen_1/wave]
  connect_bd_net -net waveform_gen_2_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid2] [get_bd_pins waveform_gen_2/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_2_wave [get_bd_pins signal_composer_0/wave2] [get_bd_pins waveform_gen_2/wave]
  connect_bd_net -net waveform_gen_3_m_axis_data_tvalid_1 [get_bd_pins signal_composer_0/valid3] [get_bd_pins waveform_gen_3/m_axis_data_tvalid_1]
  connect_bd_net -net waveform_gen_3_wave [get_bd_pins signal_composer_0/wave3] [get_bd_pins waveform_gen_3/wave]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: write_to_ram
proc create_hier_cell_write_to_ram { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_write_to_ram() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi


  # Create pins
  create_bd_pin -dir I -from 31 -to 0 Din
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -from 15 -to 0 decimation
  create_bd_pin -dir I -type rst keep_alive_aresetn
  create_bd_pin -dir I s_axis_data_tvalid
  create_bd_pin -dir O -from 63 -to 0 sts_data

  # Create instance: axis_dwidth_converter_0, and set properties
  set axis_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {8} \
   CONFIG.S_TDATA_NUM_BYTES {4} \
 ] $axis_dwidth_converter_0

  # Create instance: axis_ram_writer_1, and set properties
  set axis_ram_writer_1 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_ram_writer:1.0 axis_ram_writer_1 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {24} \
 ] $axis_ram_writer_1

  # Create instance: axis_variable_decimation_A, and set properties
  set axis_variable_decimation_A [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_variable:1.0 axis_variable_decimation_A ]
  set_property -dict [ list \
   CONFIG.AXIS_TDATA_WIDTH {16} \
 ] $axis_variable_decimation_A

  # Create instance: axis_variable_decimation_B, and set properties
  set axis_variable_decimation_B [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_variable:1.0 axis_variable_decimation_B ]
  set_property -dict [ list \
   CONFIG.AXIS_TDATA_WIDTH {16} \
 ] $axis_variable_decimation_B

  # Create instance: cic_compiler_A, and set properties
  set cic_compiler_A [ create_bd_cell -type ip -vlnv xilinx.com:ip:cic_compiler:4.0 cic_compiler_A ]
  set_property -dict [ list \
   CONFIG.Clock_Frequency {125} \
   CONFIG.Filter_Type {Decimation} \
   CONFIG.Fixed_Or_Initial_Rate {8} \
   CONFIG.HAS_ARESETN {true} \
   CONFIG.Input_Data_Width {16} \
   CONFIG.Input_Sample_Frequency {125} \
   CONFIG.Maximum_Rate {8192} \
   CONFIG.Minimum_Rate {4} \
   CONFIG.Number_Of_Stages {6} \
   CONFIG.Output_Data_Width {16} \
   CONFIG.Quantization {Truncation} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Rate_Changes {Programmable} \
 ] $cic_compiler_A

  # Create instance: cic_compiler_B, and set properties
  set cic_compiler_B [ create_bd_cell -type ip -vlnv xilinx.com:ip:cic_compiler:4.0 cic_compiler_B ]
  set_property -dict [ list \
   CONFIG.Clock_Frequency {125} \
   CONFIG.Filter_Type {Decimation} \
   CONFIG.Fixed_Or_Initial_Rate {8} \
   CONFIG.HAS_ARESETN {true} \
   CONFIG.Input_Data_Width {16} \
   CONFIG.Input_Sample_Frequency {125} \
   CONFIG.Maximum_Rate {8192} \
   CONFIG.Minimum_Rate {4} \
   CONFIG.Number_Of_Stages {6} \
   CONFIG.Output_Data_Width {16} \
   CONFIG.Quantization {Truncation} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Rate_Changes {Programmable} \
 ] $cic_compiler_B

  # Create instance: divide_by_two_0, and set properties
  set divide_by_two_0 [ create_bd_cell -type ip -vlnv jbeuke:user:divide_by_two:1.0 divide_by_two_0 ]

  # Create instance: fir_compiler_1, and set properties
  set fir_compiler_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_compiler_1 ]
  set_property -dict [ list \
   CONFIG.BestPrecision {true} \
   CONFIG.Clock_Frequency {125} \
   CONFIG.CoefficientVector {\
9.925103405823654e-6, -4.174363282738153e-5, -5.51901793488376e-5,\
7.368959088121815e-5, 0.00015990473687184194, -6.76620396082366e-5,\
-0.0003346964692496276, -3.9313022473348724e-5, 0.0005560562181887152,\
0.0003225578127550501, -0.0007467674417401369, -0.0008420592613214142,\
0.0007671235211513573, 0.0016018044027042001, -0.00042717093620696226,\
-0.0025052594870282234, -0.00047306360426935745, 0.0033218592560732216,\
0.002075564973101382, -0.003681857378456846, -0.004378381518006709,\
0.0031142208631228657, 0.007150965272845437, -0.0011339320674475808,\
-0.009875779306823484, -0.0026274562840349655, 0.01174025558643619,\
0.008267468617760211, -0.011694071059013518, -0.015463246390667961,\
0.008569880890248936, 0.02335524917895585, -0.0012434662137906153,\
-0.030475702526067405, -0.011215696029381172, 0.03468814181782342,\
0.029481462816320546, -0.03299020455574372, -0.05412187304631057,\
0.020670791935294395, 0.08620564090140646, 0.012279627206068015,\
-0.12872548525128363, -0.10014341802122498, 0.18180203856402496,\
0.4770892664568863, 0.47708926645688643, 0.18180203856402533,\
-0.10014341802122484, -0.12872548525128372, 0.012279627206067881,\
0.08620564090140649, 0.02067079193529451, -0.05412187304631054,\
-0.0329902045557438, 0.029481462816320483, 0.03468814181782345,\
-0.01121569602938112, -0.030475702526067405, -0.0012434662137906513,\
0.02335524917895585, 0.008569880890248972, -0.01546324639066795,\
-0.01169407105901354, 0.008267468617760182, 0.01174025558643619,\
-0.002627456284034945, -0.009875779306823478, -0.0011339320674475855,\
0.007150965272845437, 0.0031142208631228757, -0.004378381518006705,\
-0.003681857378456855, 0.0020755649731013692, 0.003321859256073219,\
-0.0004730636042693505, -0.002505259487028216, -0.00042717093620696166,\
0.0016018044027042, 0.0007671235211513586, -0.0008420592613214133,\
-0.0007467674417401388, 0.00032255781275504627, 0.0005560562181887131,\
-3.931302247334831e-5, -0.000334696469249626, -6.76620396082356e-5,\
0.00015990473687184224, 7.368959088121812e-5, -5.519017934883768e-5,\
-4.174363282738155e-5, 9.925103405823647e-6} \
   CONFIG.Coefficient_Fractional_Bits {24} \
   CONFIG.Coefficient_Sets {1} \
   CONFIG.Coefficient_Sign {Signed} \
   CONFIG.Coefficient_Structure {Non_Symmetric} \
   CONFIG.Coefficient_Width {24} \
   CONFIG.ColumnConfig {12} \
   CONFIG.Data_Width {16} \
   CONFIG.Decimation_Rate {2} \
   CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
   CONFIG.Filter_Type {Decimation} \
   CONFIG.Has_ARESETn {true} \
   CONFIG.Interpolation_Rate {1} \
   CONFIG.Number_Channels {1} \
   CONFIG.Number_Paths {2} \
   CONFIG.Output_Rounding_Mode {Convergent_Rounding_to_Even} \
   CONFIG.Output_Width {16} \
   CONFIG.Quantization {Quantize_Only} \
   CONFIG.RateSpecification {Frequency_Specification} \
   CONFIG.Rate_Change_Type {Integer} \
   CONFIG.SamplePeriod {1} \
   CONFIG.Sample_Frequency {31.25} \
   CONFIG.Zero_Pack_Factor {1} \
 ] $fir_compiler_1

  # Create instance: sign_extend_A
  create_hier_cell_sign_extend_A $hier_obj sign_extend_A

  # Create instance: sign_extend_B
  create_hier_cell_sign_extend_B $hier_obj sign_extend_B

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_1

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {42} \
 ] $xlconstant_0

  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {402653184} \
   CONFIG.CONST_WIDTH {32} \
 ] $xlconstant_2

  # Create instance: xlconstant_AA_HV, and set properties
  set xlconstant_AA_HV [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_AA_HV ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0x4c5f} \
   CONFIG.CONST_WIDTH {18} \
 ] $xlconstant_AA_HV

  # Create instance: xlconstant_BB_HV, and set properties
  set xlconstant_BB_HV [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_BB_HV ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0x2f38b} \
   CONFIG.CONST_WIDTH {25} \
 ] $xlconstant_BB_HV

  # Create instance: xlslice_A, and set properties
  set xlslice_A [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_A ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {13} \
   CONFIG.DOUT_WIDTH {14} \
 ] $xlslice_A

  # Create instance: xlslice_B, and set properties
  set xlslice_B [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_B ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {29} \
   CONFIG.DIN_TO {16} \
   CONFIG.DOUT_WIDTH {14} \
 ] $xlslice_B

  # Create interface connections
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS] [get_bd_intf_pins axis_ram_writer_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_ram_writer_1_M_AXI [get_bd_intf_pins m_axi] [get_bd_intf_pins axis_ram_writer_1/M_AXI]
  connect_bd_intf_net -intf_net axis_variable_2_M_AXIS [get_bd_intf_pins axis_variable_decimation_A/M_AXIS] [get_bd_intf_pins cic_compiler_A/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net axis_variable_decimation_B_M_AXIS [get_bd_intf_pins axis_variable_decimation_B/M_AXIS] [get_bd_intf_pins cic_compiler_B/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net fir_compiler_1_M_AXIS_DATA [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS] [get_bd_intf_pins fir_compiler_1/M_AXIS_DATA]

  # Create port connections
  connect_bd_net -net aresetn3_1 [get_bd_pins keep_alive_aresetn] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net axis_ram_writer_1_sts_total_data [get_bd_pins sts_data] [get_bd_pins axis_ram_writer_1/sts_total_data]
  connect_bd_net -net axis_red_pitaya_adc_1_m_axis_tdata [get_bd_pins Din] [get_bd_pins xlslice_A/Din] [get_bd_pins xlslice_B/Din]
  connect_bd_net -net axis_red_pitaya_adc_1_m_axis_tvalid [get_bd_pins s_axis_data_tvalid] [get_bd_pins cic_compiler_A/s_axis_data_tvalid] [get_bd_pins cic_compiler_B/s_axis_data_tvalid]
  connect_bd_net -net cic_compiler_A_m_axis_data_tdata [get_bd_pins cic_compiler_A/m_axis_data_tdata] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net cic_compiler_A_m_axis_data_tvalid [get_bd_pins cic_compiler_A/m_axis_data_tvalid] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net cic_compiler_B_m_axis_data_tdata [get_bd_pins cic_compiler_B/m_axis_data_tdata] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net cic_compiler_B_m_axis_data_tvalid [get_bd_pins cic_compiler_B/m_axis_data_tvalid] [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_pins aclk] [get_bd_pins axis_dwidth_converter_0/aclk] [get_bd_pins axis_ram_writer_1/aclk] [get_bd_pins axis_variable_decimation_A/aclk] [get_bd_pins axis_variable_decimation_B/aclk] [get_bd_pins cic_compiler_A/aclk] [get_bd_pins cic_compiler_B/aclk] [get_bd_pins fir_compiler_1/aclk]
  connect_bd_net -net decimation_1 [get_bd_pins decimation] [get_bd_pins axis_variable_decimation_A/cfg_data] [get_bd_pins axis_variable_decimation_B/cfg_data] [get_bd_pins divide_by_two_0/input_vector]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins axis_dwidth_converter_0/aresetn] [get_bd_pins axis_variable_decimation_A/aresetn] [get_bd_pins axis_variable_decimation_B/aresetn] [get_bd_pins cic_compiler_A/aresetn] [get_bd_pins cic_compiler_B/aresetn] [get_bd_pins fir_compiler_1/aresetn] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net sign_extend_B_dout [get_bd_pins cic_compiler_B/s_axis_data_tdata] [get_bd_pins sign_extend_B/dout]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins fir_compiler_1/s_axis_data_tvalid] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins axis_ram_writer_1/aresetn] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins fir_compiler_1/s_axis_data_tdata] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins cic_compiler_A/s_axis_data_tdata] [get_bd_pins sign_extend_A/dout]
  connect_bd_net -net xlconstant_2_dout [get_bd_pins axis_ram_writer_1/cfg_data] [get_bd_pins xlconstant_2/dout]
  connect_bd_net -net xlslice_A_Dout [get_bd_pins sign_extend_A/In0] [get_bd_pins xlslice_A/Dout]
  connect_bd_net -net xlslice_B_Dout [get_bd_pins sign_extend_B/In0] [get_bd_pins xlslice_B/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: system
proc create_hier_cell_system_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_system_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M02_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_HP0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 awg_0_bram

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 awg_1_bram

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 seq_bram


  # Create pins
  create_bd_pin -dir O -type clk FCLK_CLK0
  create_bd_pin -dir O -type rst FCLK_RESET0_N
  create_bd_pin -dir I -type clk S_AXI_HP0_ACLK
  create_bd_pin -dir I -from 63 -to 0 adc_sts
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir O -from 95 -to 0 cfg_data
  create_bd_pin -dir I -from 31 -to 0 curr_pdm_values
  create_bd_pin -dir O -from 1663 -to 0 dac_cfg
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -from 31 -to 0 reset_sts
  create_bd_pin -dir I -from 31 -to 0 sts_data

  # Create instance: axi_cfg_register_cfg, and set properties
  set axi_cfg_register_cfg [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 axi_cfg_register_cfg ]
  set_property -dict [ list \
   CONFIG.AXI_ADDR_WIDTH {32} \
   CONFIG.CFG_DATA_WIDTH {96} \
 ] $axi_cfg_register_cfg

  # Create instance: axi_cfg_register_dac, and set properties
  set axi_cfg_register_dac [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_cfg_register:1.0 axi_cfg_register_dac ]
  set_property -dict [ list \
   CONFIG.AXI_ADDR_WIDTH {32} \
   CONFIG.CFG_DATA_WIDTH {1664} \
 ] $axi_cfg_register_dac

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {7} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.STRATEGY {2} \
 ] $axi_interconnect_1

  # Create instance: axi_sts_register_DIOIn, and set properties
  set axi_sts_register_DIOIn [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_sts_register:1.0 axi_sts_register_DIOIn ]
  set_property -dict [ list \
   CONFIG.AXI_ADDR_WIDTH {32} \
   CONFIG.STS_DATA_WIDTH {32} \
 ] $axi_sts_register_DIOIn

  # Create instance: axi_sts_register_adc, and set properties
  set axi_sts_register_adc [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_sts_register:1.0 axi_sts_register_adc ]
  set_property -dict [ list \
   CONFIG.AXI_ADDR_WIDTH {32} \
   CONFIG.STS_DATA_WIDTH {64} \
 ] $axi_sts_register_adc

  # Create instance: axi_sts_register_pdm, and set properties
  set axi_sts_register_pdm [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_sts_register:1.0 axi_sts_register_pdm ]
  set_property -dict [ list \
   CONFIG.AXI_ADDR_WIDTH {32} \
   CONFIG.STS_DATA_WIDTH {32} \
 ] $axi_sts_register_pdm

  # Create instance: axi_sts_register_reset, and set properties
  set axi_sts_register_reset [ create_bd_cell -type ip -vlnv pavel-demin:user:axi_sts_register:1.0 axi_sts_register_reset ]
  set_property -dict [ list \
   CONFIG.AXI_ADDR_WIDTH {32} \
   CONFIG.STS_DATA_WIDTH {32} \
 ] $axi_sts_register_reset

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list \
   CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
   CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
   CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {50.000000} \
   CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
   CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} \
   CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
   CONFIG.PCW_CAN0_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN0_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN1_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN1_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_CAN1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_CAN_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_CAN_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_CAN_PERIPHERAL_VALID {0} \
   CONFIG.PCW_CLK0_FREQ {50000000} \
   CONFIG.PCW_CLK1_FREQ {10000000} \
   CONFIG.PCW_CLK2_FREQ {10000000} \
   CONFIG.PCW_CLK3_FREQ {10000000} \
   CONFIG.PCW_CPU_CPU_6X4X_MAX_RANGE {667} \
   CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
   CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
   CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333} \
   CONFIG.PCW_DCI_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
   CONFIG.PCW_DCI_PERIPHERAL_FREQMHZ {10.159} \
   CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
   CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
   CONFIG.PCW_DDR_HPRLPR_QUEUE_PARTITION {HPR(0)/LPR(32)} \
   CONFIG.PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL {15} \
   CONFIG.PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
   CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DDR_PORT0_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT1_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT2_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_PORT3_HPR_ENABLE {0} \
   CONFIG.PCW_DDR_RAM_HIGHADDR {0x1FFFFFFF} \
   CONFIG.PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL {2} \
   CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {0} \
   CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET0_RESET_ENABLE {0} \
   CONFIG.PCW_ENET1_GRP_MDIO_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_ENET1_PERIPHERAL_FREQMHZ {1000 Mbps} \
   CONFIG.PCW_ENET1_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_POLARITY {Active Low} \
   CONFIG.PCW_EN_4K_TIMER {0} \
   CONFIG.PCW_EN_CAN0 {0} \
   CONFIG.PCW_EN_CAN1 {0} \
   CONFIG.PCW_EN_CLK0_PORT {1} \
   CONFIG.PCW_EN_CLK1_PORT {0} \
   CONFIG.PCW_EN_CLK2_PORT {0} \
   CONFIG.PCW_EN_CLK3_PORT {0} \
   CONFIG.PCW_EN_DDR {1} \
   CONFIG.PCW_EN_EMIO_CAN0 {0} \
   CONFIG.PCW_EN_EMIO_CAN1 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_CD_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_ENET0 {0} \
   CONFIG.PCW_EN_EMIO_ENET1 {0} \
   CONFIG.PCW_EN_EMIO_GPIO {0} \
   CONFIG.PCW_EN_EMIO_I2C0 {0} \
   CONFIG.PCW_EN_EMIO_I2C1 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART0 {0} \
   CONFIG.PCW_EN_EMIO_MODEM_UART1 {0} \
   CONFIG.PCW_EN_EMIO_PJTAG {0} \
   CONFIG.PCW_EN_EMIO_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_SDIO1 {0} \
   CONFIG.PCW_EN_EMIO_SPI0 {0} \
   CONFIG.PCW_EN_EMIO_SPI1 {0} \
   CONFIG.PCW_EN_EMIO_SRAM_INT {0} \
   CONFIG.PCW_EN_EMIO_TRACE {0} \
   CONFIG.PCW_EN_EMIO_TTC0 {0} \
   CONFIG.PCW_EN_EMIO_TTC1 {0} \
   CONFIG.PCW_EN_EMIO_UART0 {0} \
   CONFIG.PCW_EN_EMIO_UART1 {0} \
   CONFIG.PCW_EN_EMIO_WDT {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO0 {0} \
   CONFIG.PCW_EN_EMIO_WP_SDIO1 {0} \
   CONFIG.PCW_EN_ENET0 {0} \
   CONFIG.PCW_EN_ENET1 {0} \
   CONFIG.PCW_EN_GPIO {0} \
   CONFIG.PCW_EN_I2C0 {0} \
   CONFIG.PCW_EN_I2C1 {0} \
   CONFIG.PCW_EN_MODEM_UART0 {0} \
   CONFIG.PCW_EN_MODEM_UART1 {0} \
   CONFIG.PCW_EN_PJTAG {0} \
   CONFIG.PCW_EN_QSPI {0} \
   CONFIG.PCW_EN_SDIO0 {0} \
   CONFIG.PCW_EN_SDIO1 {0} \
   CONFIG.PCW_EN_SMC {0} \
   CONFIG.PCW_EN_SPI0 {0} \
   CONFIG.PCW_EN_SPI1 {0} \
   CONFIG.PCW_EN_TRACE {0} \
   CONFIG.PCW_EN_TTC0 {0} \
   CONFIG.PCW_EN_TTC1 {0} \
   CONFIG.PCW_EN_UART0 {0} \
   CONFIG.PCW_EN_UART1 {0} \
   CONFIG.PCW_EN_USB0 {0} \
   CONFIG.PCW_EN_USB1 {0} \
   CONFIG.PCW_EN_WDT {0} \
   CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {4} \
   CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK_CLK0_BUF {TRUE} \
   CONFIG.PCW_FCLK_CLK1_BUF {FALSE} \
   CONFIG.PCW_FCLK_CLK2_BUF {FALSE} \
   CONFIG.PCW_FCLK_CLK3_BUF {FALSE} \
   CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
   CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} \
   CONFIG.PCW_GPIO_EMIO_GPIO_WIDTH {64} \
   CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0} \
   CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C0_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C0_RESET_ENABLE {0} \
   CONFIG.PCW_I2C1_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_I2C1_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {25} \
   CONFIG.PCW_I2C_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_RESET_POLARITY {Active Low} \
   CONFIG.PCW_IMPORT_BOARD_PRESET {cfg/red_pitaya.xml} \
   CONFIG.PCW_IOPLL_CTRL_FBDIV {48} \
   CONFIG.PCW_IO_IO_PLL_FREQMHZ {1600.000} \
   CONFIG.PCW_IRQ_F2P_INTR {1} \
   CONFIG.PCW_IRQ_F2P_MODE {DIRECT} \
   CONFIG.PCW_MIO_TREE_PERIPHERALS {\
unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned} \
   CONFIG.PCW_MIO_TREE_SIGNALS {\
unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned#unassigned} \
   CONFIG.PCW_NAND_CYCLES_T_AR {1} \
   CONFIG.PCW_NAND_CYCLES_T_CLR {1} \
   CONFIG.PCW_NAND_CYCLES_T_RC {11} \
   CONFIG.PCW_NAND_CYCLES_T_REA {1} \
   CONFIG.PCW_NAND_CYCLES_T_RR {1} \
   CONFIG.PCW_NAND_CYCLES_T_WC {11} \
   CONFIG.PCW_NAND_CYCLES_T_WP {1} \
   CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
   CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_CS0_T_PC {1} \
   CONFIG.PCW_NOR_CS0_T_RC {11} \
   CONFIG.PCW_NOR_CS0_T_TR {1} \
   CONFIG.PCW_NOR_CS0_T_WC {11} \
   CONFIG.PCW_NOR_CS0_T_WP {1} \
   CONFIG.PCW_NOR_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_CS1_T_PC {1} \
   CONFIG.PCW_NOR_CS1_T_RC {11} \
   CONFIG.PCW_NOR_CS1_T_TR {1} \
   CONFIG.PCW_NOR_CS1_T_WC {11} \
   CONFIG.PCW_NOR_CS1_T_WP {1} \
   CONFIG.PCW_NOR_CS1_WE_TIME {0} \
   CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
   CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_SRAM_CS0_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS0_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS0_WE_TIME {0} \
   CONFIG.PCW_NOR_SRAM_CS1_T_CEOE {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_PC {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_RC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_TR {1} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WC {11} \
   CONFIG.PCW_NOR_SRAM_CS1_T_WP {1} \
   CONFIG.PCW_NOR_SRAM_CS1_WE_TIME {0} \
   CONFIG.PCW_OVERRIDE_BASIC_CLOCK {0} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY0 {0.080} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY1 {0.063} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY2 {0.057} \
   CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY3 {0.068} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 {-0.047} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 {-0.025} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 {-0.006} \
   CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 {-0.017} \
   CONFIG.PCW_PCAP_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_PCAP_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PLL_BYPASSMODE_ENABLE {0} \
   CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
   CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 3.3V} \
   CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_QSPI_INTERNAL_HIGHADDRESS {0xFCFFFFFF} \
   CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_SD0_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_CD_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD1_GRP_WP_ENABLE {0} \
   CONFIG.PCW_SD1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_SDIO_PERIPHERAL_VALID {0} \
   CONFIG.PCW_SMC_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SMC_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_SMC_PERIPHERAL_VALID {0} \
   CONFIG.PCW_SPI0_GRP_SS0_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI0_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS0_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_SPI1_GRP_SS2_ENABLE {0} \
   CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_SPI_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {166.666666} \
   CONFIG.PCW_SPI_PERIPHERAL_VALID {0} \
   CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {64} \
   CONFIG.PCW_S_AXI_HP3_DATA_WIDTH {64} \
   CONFIG.PCW_TPIU_PERIPHERAL_CLKSRC {External} \
   CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TPIU_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_TRACE_GRP_16BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_2BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_32BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_4BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_GRP_8BIT_ENABLE {0} \
   CONFIG.PCW_TRACE_INTERNAL_WIDTH {2} \
   CONFIG.PCW_TRACE_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_UART0_BAUD_RATE {115200} \
   CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_UART1_BAUD_RATE {115200} \
   CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
   CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
   CONFIG.PCW_UART_PERIPHERAL_VALID {0} \
   CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
   CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {0} \
   CONFIG.PCW_UIPARAM_DDR_AL {0} \
   CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
   CONFIG.PCW_UIPARAM_DDR_BL {8} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.25} \
   CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {32 Bit} \
   CONFIG.PCW_UIPARAM_DDR_CL {7} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH {54.563} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH {54.563} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH {54.563} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH {54.563} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_CLOCK_STOP_EN {0} \
   CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
   CONFIG.PCW_UIPARAM_DDR_CWL {6} \
   CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {1024 MBits} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH {101.239} \
   CONFIG.PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH {79.5025} \
   CONFIG.PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH {60.536} \
   CONFIG.PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH {71.7715} \
   CONFIG.PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH {104.5365} \
   CONFIG.PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH {70.676} \
   CONFIG.PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH {59.1615} \
   CONFIG.PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {0} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH {81.319} \
   CONFIG.PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY {160} \
   CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {8 Bits} \
   CONFIG.PCW_UIPARAM_DDR_ECC {Disabled} \
   CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
   CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333333} \
   CONFIG.PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
   CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
   CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J128M8 JP-125} \
   CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {14} \
   CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
   CONFIG.PCW_UIPARAM_DDR_T_FAW {30.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RC {48.75} \
   CONFIG.PCW_UIPARAM_DDR_T_RCD {7} \
   CONFIG.PCW_UIPARAM_DDR_T_RP {7} \
   CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {0} \
   CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB0_RESET_ENABLE {0} \
   CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_USB1_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB1_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_POLARITY {Active Low} \
   CONFIG.PCW_USE_AXI_NONSECURE {0} \
   CONFIG.PCW_USE_CROSS_TRIGGER {0} \
   CONFIG.PCW_USE_FABRIC_INTERRUPT {0} \
   CONFIG.PCW_USE_M_AXI_GP1 {1} \
   CONFIG.PCW_USE_S_AXI_HP0 {1} \
   CONFIG.PCW_USE_S_AXI_HP1 {0} \
   CONFIG.PCW_WDT_PERIPHERAL_CLKSRC {CPU_1X} \
   CONFIG.PCW_WDT_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_WDT_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_WDT_PERIPHERAL_FREQMHZ {133.333333} \
 ] $processing_system7_0

  # Create instance: rst_ps7_0_125M, and set properties
  set rst_ps7_0_125M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_125M ]

  # Create instance: xlconstant_6, and set properties
  set xlconstant_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_6 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M02_AXI] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_cfg_register_dac/S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_sts_register_adc/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins axi_sts_register_DIOIn/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins axi_sts_register_pdm/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M05_AXI [get_bd_intf_pins axi_cfg_register_cfg/S_AXI] [get_bd_intf_pins axi_interconnect_0/M05_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M06_AXI [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins axi_sts_register_reset/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins seq_bram] [get_bd_intf_pins axi_interconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins awg_0_bram] [get_bd_intf_pins axi_interconnect_1/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins awg_1_bram] [get_bd_intf_pins axi_interconnect_1/M02_AXI]
  connect_bd_intf_net -intf_net axis_ram_writer_0_m_axi [get_bd_intf_pins S_AXI_HP0] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_pins DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_pins FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP1 [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP1]

  # Create port connections
  connect_bd_net -net axi_cfg_register_1_cfg_data1 [get_bd_pins dac_cfg] [get_bd_pins axi_cfg_register_dac/cfg_data]
  connect_bd_net -net axi_cfg_register_1_cfg_data2 [get_bd_pins cfg_data] [get_bd_pins axi_cfg_register_cfg/cfg_data]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_pins S_AXI_HP0_ACLK] [get_bd_pins axi_cfg_register_cfg/aclk] [get_bd_pins axi_cfg_register_dac/aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins axi_interconnect_0/M05_ACLK] [get_bd_pins axi_interconnect_0/M06_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/M01_ACLK] [get_bd_pins axi_interconnect_1/M02_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_sts_register_DIOIn/aclk] [get_bd_pins axi_sts_register_adc/aclk] [get_bd_pins axi_sts_register_pdm/aclk] [get_bd_pins axi_sts_register_reset/aclk] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins rst_ps7_0_125M/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins dcm_locked] [get_bd_pins rst_ps7_0_125M/dcm_locked]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins FCLK_CLK0] [get_bd_pins processing_system7_0/FCLK_CLK0]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins FCLK_RESET0_N] [get_bd_pins processing_system7_0/FCLK_RESET0_N]
  connect_bd_net -net rst_ps7_0_125M_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins rst_ps7_0_125M/interconnect_aresetn]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins axi_cfg_register_cfg/aresetn] [get_bd_pins axi_cfg_register_dac/aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins axi_interconnect_0/M05_ARESETN] [get_bd_pins axi_interconnect_0/M06_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/M01_ARESETN] [get_bd_pins axi_interconnect_1/M02_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_sts_register_DIOIn/aresetn] [get_bd_pins axi_sts_register_adc/aresetn] [get_bd_pins axi_sts_register_pdm/aresetn] [get_bd_pins axi_sts_register_reset/aresetn] [get_bd_pins rst_ps7_0_125M/peripheral_aresetn]
  connect_bd_net -net sts_data1_1 [get_bd_pins curr_pdm_values] [get_bd_pins axi_sts_register_pdm/sts_data]
  connect_bd_net -net sts_data_1 [get_bd_pins reset_sts] [get_bd_pins axi_sts_register_reset/sts_data]
  connect_bd_net -net sts_data_2 [get_bd_pins sts_data] [get_bd_pins axi_sts_register_DIOIn/sts_data]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins adc_sts] [get_bd_pins axi_sts_register_adc/sts_data]
  connect_bd_net -net xlconstant_6_dout [get_bd_pins rst_ps7_0_125M/ext_reset_in] [get_bd_pins xlconstant_6/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: sequencer
proc create_hier_cell_sequencer { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_sequencer() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 seq_bram


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -from 63 -to 0 adc_sts
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I bram_aresetn
  create_bd_pin -dir I -from 15 -to 0 cfg_data
  create_bd_pin -dir I -type clk ddr_clk
  create_bd_pin -dir O -from 3 -to 0 dout
  create_bd_pin -dir O -from 1 -to 0 enable_dac
  create_bd_pin -dir I -type rst keep_alive_aresetn
  create_bd_pin -dir O -from 31 -to 0 oa_dac
  create_bd_pin -dir O -from 31 -to 0 pdm_sts
  create_bd_pin -dir O -from 1 -to 0 seq_ramp_down

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [ list \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {true} \
   CONFIG.Enable_32bit_Address {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Fill_Remaining_Memory_Locations {false} \
   CONFIG.Load_Init_File {false} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Operating_Mode_A {WRITE_FIRST} \
   CONFIG.Port_A_Write_Rate {50} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Read_Width_A {128} \
   CONFIG.Read_Width_B {128} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {true} \
   CONFIG.Use_RSTB_Pin {true} \
   CONFIG.Write_Width_A {128} \
   CONFIG.Write_Width_B {128} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $blk_mem_gen_0

  # Create instance: bram_address_convert_0, and set properties
  set block_name bram_address_converter
  set block_cell_name bram_address_convert_0
  if { [catch {set bram_address_convert_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bram_address_convert_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.ELEMENT_SHIFT_SIZE {4} \
 ] $bram_address_convert_0

  # Create instance: pdm_1, and set properties
  set pdm_1 [ create_bd_cell -type ip -vlnv koheron:user:pdm:1.0 pdm_1 ]

  # Create instance: pdm_2, and set properties
  set pdm_2 [ create_bd_cell -type ip -vlnv koheron:user:pdm:1.0 pdm_2 ]

  # Create instance: pdm_3, and set properties
  set pdm_3 [ create_bd_cell -type ip -vlnv koheron:user:pdm:1.0 pdm_3 ]

  # Create instance: pdm_4, and set properties
  set pdm_4 [ create_bd_cell -type ip -vlnv koheron:user:pdm:1.0 pdm_4 ]

  # Create instance: sequence_slice_0, and set properties
  set block_name sequence_slice
  set block_cell_name sequence_slice_0
  if { [catch {set sequence_slice_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $sequence_slice_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: sequence_stepper_0, and set properties
  set block_name sequence_stepper
  set block_cell_name sequence_stepper_0
  if { [catch {set sequence_stepper_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $sequence_stepper_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_7, and set properties
  set util_vector_logic_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_7 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {4} \
 ] $util_vector_logic_7

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {4} \
 ] $xlconcat_0

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {12} \
   CONFIG.DOUT_WIDTH {13} \
 ] $xlslice_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net seq_bram_1 [get_bd_intf_pins seq_bram] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins bram_address_convert_0/clk] [get_bd_pins sequence_stepper_0/clk]
  connect_bd_net -net adc_sts_1 [get_bd_pins adc_sts] [get_bd_pins sequence_stepper_0/writepointer]
  connect_bd_net -net aresetn3_1 [get_bd_pins keep_alive_aresetn] [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net blk_mem_gen_0_doutb [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins sequence_slice_0/seq_data]
  connect_bd_net -net bram_address_convert_0_addr [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins bram_address_convert_0/addr]
  connect_bd_net -net bram_aresetn_1 [get_bd_pins bram_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  connect_bd_net -net cfg_data_1 [get_bd_pins cfg_data] [get_bd_pins sequence_stepper_0/stepSize]
  connect_bd_net -net ddr_clk_1 [get_bd_pins ddr_clk] [get_bd_pins pdm_1/clk] [get_bd_pins pdm_2/clk] [get_bd_pins pdm_3/clk] [get_bd_pins pdm_4/clk]
  connect_bd_net -net pdm_1_dout [get_bd_pins pdm_1/dout] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net pdm_2_dout [get_bd_pins pdm_2/dout] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net pdm_3_dout [get_bd_pins pdm_3/dout] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net pdm_4_dout [get_bd_pins pdm_4/dout] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins pdm_1/aresetn] [get_bd_pins pdm_2/aresetn] [get_bd_pins pdm_3/aresetn] [get_bd_pins pdm_4/aresetn] [get_bd_pins sequence_stepper_0/aresetn] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net sequence_slice_0_dac_value_0 [get_bd_pins sequence_slice_0/dac_value_0] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net sequence_slice_0_dac_value_1 [get_bd_pins sequence_slice_0/dac_value_1] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net sequence_slice_0_enable_dac [get_bd_pins enable_dac] [get_bd_pins sequence_slice_0/enable_dac]
  connect_bd_net -net sequence_slice_0_enable_dac_ramp_down [get_bd_pins seq_ramp_down] [get_bd_pins sequence_slice_0/enable_dac_ramp_down]
  connect_bd_net -net sequence_slice_0_enable_pdm [get_bd_pins sequence_slice_0/enable_pdm] [get_bd_pins util_vector_logic_7/Op2]
  connect_bd_net -net sequence_slice_0_pdm_value_0 [get_bd_pins pdm_1/din] [get_bd_pins sequence_slice_0/pdm_value_0]
  connect_bd_net -net sequence_slice_0_pdm_value_1 [get_bd_pins pdm_2/din] [get_bd_pins sequence_slice_0/pdm_value_1]
  connect_bd_net -net sequence_slice_0_pdm_value_2 [get_bd_pins pdm_3/din] [get_bd_pins sequence_slice_0/pdm_value_2]
  connect_bd_net -net sequence_slice_0_pdm_value_3 [get_bd_pins pdm_4/din] [get_bd_pins sequence_slice_0/pdm_value_3]
  connect_bd_net -net util_vector_logic_7_Res [get_bd_pins dout] [get_bd_pins util_vector_logic_7/Res]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins util_vector_logic_7/Op1] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins oa_dac] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins blk_mem_gen_0/enb] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins bram_address_convert_0/elAddr] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins pdm_sts] [get_bd_pins sequence_stepper_0/step_counter] [get_bd_pins xlslice_0/Din]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: fourier_synth_standard
proc create_hier_cell_fourier_synth_standard { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_fourier_synth_standard() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 awg_0_bram

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 awg_1_bram


  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I bram_aresetn
  create_bd_pin -dir I -from 1663 -to 0 cfg_data
  create_bd_pin -dir I -from 1 -to 0 enable_dac
  create_bd_pin -dir I -from 1 -to 0 enable_ramping
  create_bd_pin -dir I -from 31 -to 0 oa_dac
  create_bd_pin -dir O -from 1 -to 0 ramp_state_0
  create_bd_pin -dir O -from 1 -to 0 ramp_state_1
  create_bd_pin -dir I -from 1 -to 0 seq_ramp_down
  create_bd_pin -dir I -from 1 -to 0 start_ramp_down
  create_bd_pin -dir O -from 31 -to 0 synth_tdata
  create_bd_pin -dir O -from 0 -to 0 synth_tvalid

  # Create instance: enable_ramping_slice_0, and set properties
  set block_name enable_ramping_slice
  set block_cell_name enable_ramping_slice_0
  if { [catch {set enable_ramping_slice_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $enable_ramping_slice_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: signal_compose
  create_hier_cell_signal_compose $hier_obj signal_compose

  # Create instance: signal_compose1
  create_hier_cell_signal_compose1 $hier_obj signal_compose1

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {2} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_2

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {831} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {1664} \
   CONFIG.DOUT_WIDTH {832} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1663} \
   CONFIG.DIN_TO {832} \
   CONFIG.DIN_WIDTH {1664} \
   CONFIG.DOUT_WIDTH {832} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DIN_WIDTH {32} \
   CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {32} \
   CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_3

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {2} \
 ] $xlslice_4

  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {2} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_5

  # Create interface connections
  connect_bd_intf_net -intf_net awg_0_bram_1 [get_bd_intf_pins awg_0_bram] [get_bd_intf_pins signal_compose/awg_bram]
  connect_bd_intf_net -intf_net awg_1_bram_1 [get_bd_intf_pins awg_1_bram] [get_bd_intf_pins signal_compose1/awg_bram]

  # Create port connections
  connect_bd_net -net Din_1_1 [get_bd_pins signal_compose1/offset] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins signal_compose/aclk] [get_bd_pins signal_compose1/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins signal_compose/aresetn] [get_bd_pins signal_compose1/aresetn]
  connect_bd_net -net bram_aresetn_1 [get_bd_pins bram_aresetn] [get_bd_pins signal_compose/bram_aresetn] [get_bd_pins signal_compose1/bram_aresetn]
  connect_bd_net -net cfg_data_1 [get_bd_pins cfg_data] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net enable_dac_1 [get_bd_pins enable_dac] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net enable_ramping_1 [get_bd_pins enable_ramping] [get_bd_pins enable_ramping_slice_0/enable_ramping]
  connect_bd_net -net enable_ramping_slice_0_enable_ramping_0 [get_bd_pins enable_ramping_slice_0/enable_ramping_0] [get_bd_pins signal_compose/enable_ramping]
  connect_bd_net -net enable_ramping_slice_0_enable_ramping_1 [get_bd_pins enable_ramping_slice_0/enable_ramping_1] [get_bd_pins signal_compose1/enable_ramping]
  connect_bd_net -net enable_ramping_slice_0_start_ramp_down_0 [get_bd_pins enable_ramping_slice_0/start_ramp_down_0] [get_bd_pins signal_compose/start_ramp_down]
  connect_bd_net -net enable_ramping_slice_0_start_ramp_down_1 [get_bd_pins enable_ramping_slice_0/start_ramp_down_1] [get_bd_pins signal_compose1/start_ramp_down]
  connect_bd_net -net oa_dac_1 [get_bd_pins oa_dac] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din]
  connect_bd_net -net seq_ramp_down_1 [get_bd_pins seq_ramp_down] [get_bd_pins enable_ramping_slice_0/seq_ramp_down]
  connect_bd_net -net signal_compose1_S [get_bd_pins signal_compose1/S] [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net signal_compose1_m_axis_data_tvalid_1 [get_bd_pins signal_compose1/m_axis_data_tvalid_1] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net signal_compose1_ramp_state_1 [get_bd_pins ramp_state_1] [get_bd_pins signal_compose1/ramp_state_1]
  connect_bd_net -net signal_compose_S [get_bd_pins signal_compose/S] [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net signal_compose_ramp_state_0 [get_bd_pins ramp_state_0] [get_bd_pins signal_compose/ramp_state_0]
  connect_bd_net -net signal_gen_m_axis_data_tvalid_1 [get_bd_pins signal_compose/m_axis_data_tvalid_1] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net start_ramp_down_1 [get_bd_pins start_ramp_down] [get_bd_pins enable_ramping_slice_0/start_ramp_down]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins synth_tvalid] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins util_vector_logic_2/Res] [get_bd_pins xlslice_4/Din] [get_bd_pins xlslice_5/Din]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins synth_tdata] [get_bd_pins xlconcat_2/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins signal_compose/Din] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins signal_compose1/Din] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins signal_compose/offset] [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net xlslice_4_Dout [get_bd_pins signal_compose/disable_dac] [get_bd_pins xlslice_4/Dout]
  connect_bd_net -net xlslice_5_Dout [get_bd_pins signal_compose1/disable_dac] [get_bd_pins xlslice_5/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

  set Vaux0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux0 ]

  set Vaux1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux1 ]

  set Vaux8 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux8 ]

  set Vaux9 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux9 ]

  set Vp_Vn [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn ]

  set daisy_clk_i [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 daisy_clk_i ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $daisy_clk_i

  set daisy_clk_o [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:diff_clock_rtl:1.0 daisy_clk_o ]


  # Create ports
  set adc_clk_n_i [ create_bd_port -dir I adc_clk_n_i ]
  set adc_clk_p_i [ create_bd_port -dir I adc_clk_p_i ]
  set adc_csn_o [ create_bd_port -dir O adc_csn_o ]
  set adc_dat_a_i [ create_bd_port -dir I -from 13 -to 0 adc_dat_a_i ]
  set adc_dat_b_i [ create_bd_port -dir I -from 13 -to 0 adc_dat_b_i ]
  set adc_enc_n_o [ create_bd_port -dir O -from 0 -to 0 adc_enc_n_o ]
  set adc_enc_p_o [ create_bd_port -dir O -from 0 -to 0 adc_enc_p_o ]
  set dac_clk_o [ create_bd_port -dir O dac_clk_o ]
  set dac_dat_o [ create_bd_port -dir O -from 13 -to 0 dac_dat_o ]
  set dac_pwm_o [ create_bd_port -dir O -from 3 -to 0 dac_pwm_o ]
  set dac_rst_o [ create_bd_port -dir O dac_rst_o ]
  set dac_sel_o [ create_bd_port -dir O dac_sel_o ]
  set dac_wrt_o [ create_bd_port -dir O dac_wrt_o ]
  set daisy_n_i [ create_bd_port -dir I daisy_n_i ]
  set daisy_n_o [ create_bd_port -dir O -from 0 -to 0 daisy_n_o ]
  set daisy_p_i [ create_bd_port -dir I daisy_p_i ]
  set daisy_p_o [ create_bd_port -dir O -from 0 -to 0 daisy_p_o ]
  set ext_DIO0_N [ create_bd_port -dir I ext_DIO0_N ]
  set ext_DIO0_P [ create_bd_port -dir IO ext_DIO0_P ]
  set ext_DIO1_N [ create_bd_port -dir O -from 0 -to 0 ext_DIO1_N ]
  set ext_DIO1_P [ create_bd_port -dir IO ext_DIO1_P ]
  set ext_DIO2_N [ create_bd_port -dir IO ext_DIO2_N ]
  set ext_DIO2_P [ create_bd_port -dir IO ext_DIO2_P ]
  set ext_DIO3_N [ create_bd_port -dir IO ext_DIO3_N ]
  set ext_DIO3_P [ create_bd_port -dir IO ext_DIO3_P ]
  set ext_DIO4_N [ create_bd_port -dir IO ext_DIO4_N ]
  set ext_DIO4_P [ create_bd_port -dir IO ext_DIO4_P ]
  set ext_DIO5_N [ create_bd_port -dir IO ext_DIO5_N ]
  set ext_DIO5_P [ create_bd_port -dir IO ext_DIO5_P ]
  set ext_DIO6_N [ create_bd_port -dir IO ext_DIO6_N ]
  set ext_DIO6_P [ create_bd_port -dir IO ext_DIO6_P ]
  set ext_DIO7_N [ create_bd_port -dir IO ext_DIO7_N ]
  set ext_DIO7_P [ create_bd_port -dir IO ext_DIO7_P ]
  set led_o [ create_bd_port -dir O -from 7 -to 0 led_o ]

  # Create instance: axis_red_pitaya_adc_0, and set properties
  set axis_red_pitaya_adc_0 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_red_pitaya_adc:1.0 axis_red_pitaya_adc_0 ]

  # Create instance: axis_red_pitaya_dac_0, and set properties
  set axis_red_pitaya_dac_0 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_red_pitaya_dac:1.0 axis_red_pitaya_dac_0 ]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {80.0} \
   CONFIG.CLKIN2_JITTER_PS {80.0} \
   CONFIG.CLKOUT1_JITTER {112.962} \
   CONFIG.CLKOUT1_PHASE_ERROR {112.379} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {250.000} \
   CONFIG.CLKOUT2_JITTER {128.871} \
   CONFIG.CLKOUT2_PHASE_ERROR {112.379} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {104.620} \
   CONFIG.CLKOUT3_PHASE_ERROR {112.379} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {375.000} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLKOUT4_JITTER {224.358} \
   CONFIG.CLKOUT4_PHASE_ERROR {112.379} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {7.8125} \
   CONFIG.CLKOUT4_USED {true} \
   CONFIG.CLK_OUT1_PORT {clk_ddr} \
   CONFIG.CLK_OUT2_PORT {clk_internal} \
   CONFIG.CLK_OUT3_PORT {clk_375MHz} \
   CONFIG.CLK_OUT4_PORT {clk_pdm} \
   CONFIG.ENABLE_CLOCK_MONITOR {false} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {6.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
   CONFIG.MMCM_CLKIN2_PERIOD {8.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {3.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {2} \
   CONFIG.MMCM_CLKOUT3_DIVIDE {96} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {4} \
   CONFIG.PRIMITIVE {MMCM} \
   CONFIG.PRIM_IN_FREQ {125.000} \
   CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.SECONDARY_IN_FREQ {125.000} \
   CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
   CONFIG.USE_INCLK_SWITCHOVER {true} \
   CONFIG.USE_RESET {true} \
 ] $clk_wiz_0

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {80.0} \
   CONFIG.CLKOUT1_JITTER {119.348} \
   CONFIG.CLKOUT1_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {8.000} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.PRIM_IN_FREQ {125.000} \
 ] $clk_wiz_1

  # Create instance: dio_0, and set properties
  set dio_0 [ create_bd_cell -type ip -vlnv jbeuke:user:dio:1.0 dio_0 ]

  # Create instance: fourier_synth_standard
  create_hier_cell_fourier_synth_standard [current_bd_instance .] fourier_synth_standard

  # Create instance: proc_sys_reset_bram, and set properties
  set proc_sys_reset_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_bram ]

  # Create instance: proc_sys_reset_fourier_synth, and set properties
  set proc_sys_reset_fourier_synth [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_fourier_synth ]

  # Create instance: proc_sys_reset_pdm, and set properties
  set proc_sys_reset_pdm [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_pdm ]

  # Create instance: proc_sys_reset_write_to_ram, and set properties
  set proc_sys_reset_write_to_ram [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_write_to_ram ]

  # Create instance: proc_sys_reset_xadc, and set properties
  set proc_sys_reset_xadc [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_xadc ]

  # Create instance: reset_manager_0, and set properties
  set block_name reset_manager
  set block_cell_name reset_manager_0
  if { [catch {set reset_manager_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $reset_manager_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: selectio_wiz_1, and set properties
  set selectio_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:selectio_wiz:5.1 selectio_wiz_1 ]
  set_property -dict [ list \
   CONFIG.BUS_DIR {OUTPUTS} \
   CONFIG.BUS_IO_STD {DIFF_HSTL_I_18} \
   CONFIG.BUS_SIG_TYPE {DIFF} \
   CONFIG.CLK_EN {true} \
   CONFIG.CLK_FWD {true} \
   CONFIG.CLK_FWD_IO_STD {DIFF_HSTL_I_18} \
   CONFIG.CLK_FWD_SIG_TYPE {DIFF} \
   CONFIG.CONFIG_CLK_FWD {false} \
   CONFIG.SELIO_BUS_IN_DELAY {NONE} \
   CONFIG.SELIO_CLK_BUF {MMCM} \
   CONFIG.SELIO_CLK_IO_STD {DIFF_HSTL_I_18} \
   CONFIG.SELIO_CLK_SIG_TYPE {DIFF} \
   CONFIG.SELIO_INTERFACE_TYPE {NETWORKING} \
   CONFIG.SERIALIZATION_FACTOR {4} \
   CONFIG.SYSTEM_DATA_WIDTH {1} \
 ] $selectio_wiz_1

  # Create instance: selectio_wiz_2, and set properties
  set selectio_wiz_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:selectio_wiz:5.1 selectio_wiz_2 ]
  set_property -dict [ list \
   CONFIG.BUS_DIR {INPUTS} \
   CONFIG.BUS_IO_STD {DIFF_HSTL_I_18} \
   CONFIG.BUS_SIG_TYPE {DIFF} \
   CONFIG.CLK_EN {false} \
   CONFIG.CLK_FWD {false} \
   CONFIG.CLK_FWD_IO_STD {DIFF_HSTL_I_18} \
   CONFIG.CLK_FWD_SIG_TYPE {DIFF} \
   CONFIG.CONFIG_CLK_FWD {false} \
   CONFIG.SELIO_BUS_IN_DELAY {NONE} \
   CONFIG.SELIO_CLK_BUF {BUFIO} \
   CONFIG.SELIO_CLK_IO_STD {DIFF_HSTL_I_18} \
   CONFIG.SELIO_CLK_SIG_TYPE {DIFF} \
   CONFIG.SELIO_INTERFACE_TYPE {NETWORKING} \
   CONFIG.SERIALIZATION_FACTOR {4} \
   CONFIG.SYSTEM_DATA_WIDTH {1} \
 ] $selectio_wiz_2

  # Create instance: sequencer
  create_hier_cell_sequencer [current_bd_instance .] sequencer

  # Create instance: system
  create_hier_cell_system_1 [current_bd_instance .] system

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0 ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {OBUFDS} \
 ] $util_ds_buf_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_1

  # Create instance: write_to_ram
  create_hier_cell_write_to_ram [current_bd_instance .] write_to_ram

  # Create instance: xadc_wiz_0, and set properties
  set xadc_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc_wiz_0 ]
  set_property -dict [ list \
   CONFIG.ADC_CONVERSION_RATE {1000} \
   CONFIG.CHANNEL_ENABLE_VAUXP0_VAUXN0 {true} \
   CONFIG.CHANNEL_ENABLE_VAUXP1_VAUXN1 {true} \
   CONFIG.CHANNEL_ENABLE_VAUXP8_VAUXN8 {true} \
   CONFIG.CHANNEL_ENABLE_VAUXP9_VAUXN9 {true} \
   CONFIG.CHANNEL_ENABLE_VP_VN {true} \
   CONFIG.DCLK_FREQUENCY {125} \
   CONFIG.ENABLE_RESET {false} \
   CONFIG.EXTERNAL_MUX_CHANNEL {VP_VN} \
   CONFIG.INTERFACE_SELECTION {Enable_AXI} \
   CONFIG.SEQUENCER_MODE {Off} \
   CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE} \
   CONFIG.XADC_STARUP_SELECTION {independent_adc} \
 ] $xadc_wiz_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {9} \
 ] $xlconcat_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {24} \
 ] $xlconstant_1

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {47} \
   CONFIG.DIN_TO {32} \
   CONFIG.DIN_WIDTH {96} \
   CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {31} \
   CONFIG.DIN_TO {16} \
   CONFIG.DIN_WIDTH {96} \
   CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {8} \
   CONFIG.DIN_WIDTH {96} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_3

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {71} \
   CONFIG.DIN_TO {64} \
   CONFIG.DIN_WIDTH {96} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_4

  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {79} \
   CONFIG.DIN_TO {72} \
   CONFIG.DIN_WIDTH {96} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_5

  # Create instance: xlslice_6, and set properties
  set xlslice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_6 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {87} \
   CONFIG.DIN_TO {80} \
   CONFIG.DIN_WIDTH {96} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_6

  # Create interface connections
  connect_bd_intf_net -intf_net Vaux0_1 [get_bd_intf_ports Vaux0] [get_bd_intf_pins xadc_wiz_0/Vaux0]
  connect_bd_intf_net -intf_net Vaux1_1 [get_bd_intf_ports Vaux1] [get_bd_intf_pins xadc_wiz_0/Vaux1]
  connect_bd_intf_net -intf_net Vaux8_1 [get_bd_intf_ports Vaux8] [get_bd_intf_pins xadc_wiz_0/Vaux8]
  connect_bd_intf_net -intf_net Vaux9_1 [get_bd_intf_ports Vaux9] [get_bd_intf_pins xadc_wiz_0/Vaux9]
  connect_bd_intf_net -intf_net Vp_Vn_1 [get_bd_intf_ports Vp_Vn] [get_bd_intf_pins xadc_wiz_0/Vp_Vn]
  connect_bd_intf_net -intf_net axis_ram_writer_0_m_axi [get_bd_intf_pins system/S_AXI_HP0] [get_bd_intf_pins write_to_ram/m_axi]
  connect_bd_intf_net -intf_net daisy_clk_i_1 [get_bd_intf_ports daisy_clk_i] [get_bd_intf_pins selectio_wiz_2/diff_clk_in]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins system/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins system/FIXED_IO]
  connect_bd_intf_net -intf_net selectio_wiz_1_diff_clk_to_pins [get_bd_intf_ports daisy_clk_o] [get_bd_intf_pins selectio_wiz_1/diff_clk_to_pins]
  connect_bd_intf_net -intf_net system_M02_AXI [get_bd_intf_pins system/M02_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net system_awg_0_bram [get_bd_intf_pins fourier_synth_standard/awg_0_bram] [get_bd_intf_pins system/awg_0_bram]
  connect_bd_intf_net -intf_net system_awg_1_bram [get_bd_intf_pins fourier_synth_standard/awg_1_bram] [get_bd_intf_pins system/awg_1_bram]
  connect_bd_intf_net -intf_net system_seq_bram [get_bd_intf_pins sequencer/seq_bram] [get_bd_intf_pins system/seq_bram]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports ext_DIO0_P] [get_bd_pins reset_manager_0/trigger]
  connect_bd_net -net Net1 [get_bd_ports ext_DIO1_P] [get_bd_pins reset_manager_0/watchdog]
  connect_bd_net -net Net2 [get_bd_ports ext_DIO2_P] [get_bd_pins reset_manager_0/reset_ack]
  connect_bd_net -net Net3 [get_bd_ports ext_DIO3_P] [get_bd_pins reset_manager_0/instant_reset]
  connect_bd_net -net Net4 [get_bd_ports ext_DIO4_P] [get_bd_pins reset_manager_0/alive_signal]
  connect_bd_net -net Net5 [get_bd_ports ext_DIO5_P] [get_bd_pins reset_manager_0/master_trigger]
  connect_bd_net -net Net6 [get_bd_ports ext_DIO7_P] [get_bd_pins dio_0/DIO_0]
  connect_bd_net -net Net7 [get_bd_ports ext_DIO7_N] [get_bd_pins dio_0/DIO_1]
  connect_bd_net -net Net8 [get_bd_ports ext_DIO6_P] [get_bd_pins dio_0/DIO_2]
  connect_bd_net -net Net9 [get_bd_ports ext_DIO6_N] [get_bd_pins dio_0/DIO_3]
  connect_bd_net -net Net10 [get_bd_ports ext_DIO5_N] [get_bd_pins dio_0/DIO_4]
  connect_bd_net -net Net11 [get_bd_ports ext_DIO4_N] [get_bd_pins dio_0/DIO_5]
  connect_bd_net -net Net12 [get_bd_ports ext_DIO3_N] [get_bd_pins dio_0/DIO_6]
  connect_bd_net -net Net13 [get_bd_ports ext_DIO2_N] [get_bd_pins dio_0/DIO_7]
  connect_bd_net -net adc_clk_n_i_1 [get_bd_ports adc_clk_n_i] [get_bd_pins axis_red_pitaya_adc_0/adc_clk_n]
  connect_bd_net -net adc_clk_p_i_1 [get_bd_ports adc_clk_p_i] [get_bd_pins axis_red_pitaya_adc_0/adc_clk_p]
  connect_bd_net -net adc_dat_a_i_1 [get_bd_ports adc_dat_a_i] [get_bd_pins axis_red_pitaya_adc_0/adc_dat_a]
  connect_bd_net -net adc_dat_b_i_1 [get_bd_ports adc_dat_b_i] [get_bd_pins axis_red_pitaya_adc_0/adc_dat_b]
  connect_bd_net -net axis_red_pitaya_adc_0_adc_clk [get_bd_pins axis_red_pitaya_adc_0/adc_clk] [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net axis_red_pitaya_adc_0_adc_csn [get_bd_ports adc_csn_o] [get_bd_pins axis_red_pitaya_adc_0/adc_csn]
  connect_bd_net -net axis_red_pitaya_adc_0_m_axis_tdata [get_bd_pins axis_red_pitaya_adc_0/m_axis_tdata] [get_bd_pins write_to_ram/Din]
  connect_bd_net -net axis_red_pitaya_adc_0_m_axis_tvalid [get_bd_pins axis_red_pitaya_adc_0/m_axis_tvalid] [get_bd_pins write_to_ram/s_axis_data_tvalid]
  connect_bd_net -net axis_red_pitaya_dac_0_dac_clk [get_bd_ports dac_clk_o] [get_bd_pins axis_red_pitaya_dac_0/dac_clk]
  connect_bd_net -net axis_red_pitaya_dac_0_dac_dat [get_bd_ports dac_dat_o] [get_bd_pins axis_red_pitaya_dac_0/dac_dat]
  connect_bd_net -net axis_red_pitaya_dac_0_dac_rst [get_bd_ports dac_rst_o] [get_bd_pins axis_red_pitaya_dac_0/dac_rst]
  connect_bd_net -net axis_red_pitaya_dac_0_dac_sel [get_bd_ports dac_sel_o] [get_bd_pins axis_red_pitaya_dac_0/dac_sel]
  connect_bd_net -net axis_red_pitaya_dac_0_dac_wrt [get_bd_ports dac_wrt_o] [get_bd_pins axis_red_pitaya_dac_0/dac_wrt]
  connect_bd_net -net clk_wiz_0_clk_ddr [get_bd_pins axis_red_pitaya_dac_0/ddr_clk] [get_bd_pins clk_wiz_0/clk_ddr] [get_bd_pins sequencer/ddr_clk]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_pins axis_red_pitaya_dac_0/aclk] [get_bd_pins clk_wiz_0/clk_internal] [get_bd_pins fourier_synth_standard/aclk] [get_bd_pins proc_sys_reset_bram/slowest_sync_clk] [get_bd_pins proc_sys_reset_fourier_synth/slowest_sync_clk] [get_bd_pins proc_sys_reset_pdm/slowest_sync_clk] [get_bd_pins proc_sys_reset_write_to_ram/slowest_sync_clk] [get_bd_pins proc_sys_reset_xadc/slowest_sync_clk] [get_bd_pins reset_manager_0/clk] [get_bd_pins selectio_wiz_1/clk_in] [get_bd_pins sequencer/aclk] [get_bd_pins system/S_AXI_HP0_ACLK] [get_bd_pins util_ds_buf_0/OBUF_IN] [get_bd_pins write_to_ram/aclk] [get_bd_pins xadc_wiz_0/s_axi_aclk]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins axis_red_pitaya_dac_0/locked] [get_bd_pins clk_wiz_0/locked] [get_bd_pins selectio_wiz_1/clock_enable] [get_bd_pins system/dcm_locked]
  connect_bd_net -net clk_wiz_1_clk_out1 [get_bd_pins clk_wiz_0/clk_in2] [get_bd_pins clk_wiz_1/clk_out1]
  connect_bd_net -net daisy_n_i_1 [get_bd_ports daisy_n_i] [get_bd_pins selectio_wiz_2/data_in_from_pins_n]
  connect_bd_net -net daisy_p_i_1 [get_bd_ports daisy_p_i] [get_bd_pins selectio_wiz_2/data_in_from_pins_p]
  connect_bd_net -net dio_0_DIO_0_in [get_bd_pins dio_0/DIO_0_in] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net dio_0_DIO_1_in [get_bd_pins dio_0/DIO_1_in] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net dio_0_DIO_2_in [get_bd_pins dio_0/DIO_2_in] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net dio_0_DIO_3_in [get_bd_pins dio_0/DIO_3_in] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net dio_0_DIO_4_in [get_bd_pins dio_0/DIO_4_in] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net dio_0_DIO_5_in [get_bd_pins dio_0/DIO_5_in] [get_bd_pins xlconcat_0/In5]
  connect_bd_net -net dio_0_DIO_6_in [get_bd_pins dio_0/DIO_6_in] [get_bd_pins xlconcat_0/In6]
  connect_bd_net -net dio_0_DIO_7_in [get_bd_pins dio_0/DIO_7_in] [get_bd_pins xlconcat_0/In7]
  connect_bd_net -net ext_DIO0_N_1 [get_bd_ports ext_DIO0_N] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net fourier_synth_standard_ramp_state_0 [get_bd_pins fourier_synth_standard/ramp_state_0] [get_bd_pins reset_manager_0/ramp_state_0]
  connect_bd_net -net fourier_synth_standard_ramp_state_1 [get_bd_pins fourier_synth_standard/ramp_state_1] [get_bd_pins reset_manager_0/ramp_state_1]
  connect_bd_net -net fourier_synth_standard_synth_tdata [get_bd_pins axis_red_pitaya_dac_0/s_axis_tdata] [get_bd_pins fourier_synth_standard/synth_tdata]
  connect_bd_net -net fourier_synth_standard_synth_tvalid [get_bd_pins axis_red_pitaya_dac_0/s_axis_tvalid] [get_bd_pins fourier_synth_standard/synth_tvalid]
  connect_bd_net -net pdm_oa_dac [get_bd_pins fourier_synth_standard/oa_dac] [get_bd_pins sequencer/oa_dac]
  connect_bd_net -net pdm_pdm_sts [get_bd_pins sequencer/pdm_sts] [get_bd_pins system/curr_pdm_values]
  connect_bd_net -net proc_sys_reset_bram_peripheral_aresetn [get_bd_pins fourier_synth_standard/bram_aresetn] [get_bd_pins proc_sys_reset_bram/peripheral_aresetn] [get_bd_pins sequencer/bram_aresetn]
  connect_bd_net -net proc_sys_reset_fourier_synth_peripheral_aresetn [get_bd_pins fourier_synth_standard/aresetn] [get_bd_pins proc_sys_reset_fourier_synth/peripheral_aresetn] [get_bd_pins system/aresetn]
  connect_bd_net -net proc_sys_reset_pdm_peripheral_aresetn [get_bd_pins proc_sys_reset_pdm/peripheral_aresetn] [get_bd_pins sequencer/aresetn]
  connect_bd_net -net proc_sys_reset_write_to_ram_peripheral_aresetn [get_bd_pins proc_sys_reset_write_to_ram/peripheral_aresetn] [get_bd_pins write_to_ram/aresetn]
  connect_bd_net -net proc_sys_reset_xadc_peripheral_aresetn [get_bd_pins proc_sys_reset_xadc/peripheral_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]
  connect_bd_net -net reset_manager_0_bram_aresetn [get_bd_pins proc_sys_reset_bram/ext_reset_in] [get_bd_pins reset_manager_0/bram_aresetn]
  connect_bd_net -net reset_manager_0_fourier_synth_aresetn [get_bd_pins proc_sys_reset_fourier_synth/ext_reset_in] [get_bd_pins reset_manager_0/fourier_synth_aresetn]
  connect_bd_net -net reset_manager_0_led [get_bd_ports led_o] [get_bd_pins reset_manager_0/led]
  connect_bd_net -net reset_manager_0_pdm_aresetn [get_bd_pins proc_sys_reset_pdm/ext_reset_in] [get_bd_pins reset_manager_0/pdm_aresetn]
  connect_bd_net -net reset_manager_0_ramping_enable [get_bd_pins fourier_synth_standard/enable_ramping] [get_bd_pins reset_manager_0/ramping_enable]
  connect_bd_net -net reset_manager_0_reset_sts [get_bd_pins reset_manager_0/reset_sts] [get_bd_pins system/reset_sts]
  connect_bd_net -net reset_manager_0_start_ramp_down [get_bd_pins fourier_synth_standard/start_ramp_down] [get_bd_pins reset_manager_0/start_ramp_down]
  connect_bd_net -net reset_manager_0_write_to_ram_aresetn [get_bd_pins proc_sys_reset_write_to_ram/ext_reset_in] [get_bd_pins reset_manager_0/write_to_ram_aresetn]
  connect_bd_net -net reset_manager_0_xadc_aresetn [get_bd_pins proc_sys_reset_xadc/ext_reset_in] [get_bd_pins reset_manager_0/xadc_aresetn]
  connect_bd_net -net selectio_wiz_1_data_out_to_pins_n [get_bd_ports daisy_n_o] [get_bd_pins selectio_wiz_1/data_out_to_pins_n]
  connect_bd_net -net selectio_wiz_1_data_out_to_pins_p [get_bd_ports daisy_p_o] [get_bd_pins selectio_wiz_1/data_out_to_pins_p]
  connect_bd_net -net selectio_wiz_2_clk_out [get_bd_pins clk_wiz_1/clk_in1] [get_bd_pins selectio_wiz_2/clk_out]
  connect_bd_net -net sequencer_enable_dac [get_bd_pins fourier_synth_standard/enable_dac] [get_bd_pins sequencer/enable_dac]
  connect_bd_net -net sequencer_seq_ramp_down [get_bd_pins fourier_synth_standard/seq_ramp_down] [get_bd_pins sequencer/seq_ramp_down]
  connect_bd_net -net system_FCLK_RESET0_N [get_bd_pins system/FCLK_RESET0_N] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net system_cfg_data [get_bd_pins fourier_synth_standard/cfg_data] [get_bd_pins system/dac_cfg]
  connect_bd_net -net system_cfg_data1 [get_bd_pins system/cfg_data] [get_bd_pins xlslice_1/Din] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din] [get_bd_pins xlslice_4/Din] [get_bd_pins xlslice_5/Din] [get_bd_pins xlslice_6/Din]
  connect_bd_net -net system_peripheral_aresetn [get_bd_pins reset_manager_0/peripheral_aresetn] [get_bd_pins system/peripheral_aresetn]
  connect_bd_net -net util_ds_buf_0_OBUF_DS_N [get_bd_ports adc_enc_n_o] [get_bd_pins util_ds_buf_0/OBUF_DS_N]
  connect_bd_net -net util_ds_buf_0_OBUF_DS_P [get_bd_ports adc_enc_p_o] [get_bd_pins util_ds_buf_0/OBUF_DS_P]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins clk_wiz_0/clk_in_sel] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins sequencer/adc_sts] [get_bd_pins system/adc_sts] [get_bd_pins write_to_ram/sts_data]
  connect_bd_net -net xlconcat_0_dout1 [get_bd_ports dac_pwm_o] [get_bd_pins sequencer/dout]
  connect_bd_net -net xlconcat_0_dout2 [get_bd_pins system/sts_data] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_ports ext_DIO1_N] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins xlconcat_0/In8] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlconstant_5_dout [get_bd_pins clk_wiz_0/reset] [get_bd_pins clk_wiz_1/reset] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins reset_manager_0/keep_alive_aresetn] [get_bd_pins sequencer/keep_alive_aresetn] [get_bd_pins write_to_ram/keep_alive_aresetn]
  connect_bd_net -net xlslice_1_Dout1 [get_bd_pins sequencer/cfg_data] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins write_to_ram/decimation] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins reset_manager_0/reset_cfg] [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net xlslice_4_Dout [get_bd_pins dio_0/value] [get_bd_pins xlslice_4/Dout]
  connect_bd_net -net xlslice_5_Dout [get_bd_pins dio_0/state] [get_bd_pins xlslice_5/Dout]
  connect_bd_net -net xlslice_6_Dout [get_bd_pins reset_manager_0/ramping_cfg] [get_bd_pins xlslice_6/Dout]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs sequencer/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x80028000 -range 0x00008000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs fourier_synth_standard/signal_compose1/waveform_awg1/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x80020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs fourier_synth_standard/signal_compose/waveform_awg/axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x40004000 -range 0x00001000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs system/axi_cfg_register_cfg/s_axi/reg0] -force
  assign_bd_address -offset 0x40000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs system/axi_cfg_register_dac/s_axi/reg0] -force
  assign_bd_address -offset 0x40006000 -range 0x00001000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs system/axi_sts_register_DIOIn/s_axi/reg0] -force
  assign_bd_address -offset 0x40001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs system/axi_sts_register_adc/s_axi/reg0] -force
  assign_bd_address -offset 0x40003000 -range 0x00001000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs system/axi_sts_register_pdm/s_axi/reg0] -force
  assign_bd_address -offset 0x40005000 -range 0x00001000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs system/axi_sts_register_reset/s_axi/reg0] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces system/processing_system7_0/Data] [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces write_to_ram/axis_ram_writer_1/M_AXI] [get_bd_addr_segs system/processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


