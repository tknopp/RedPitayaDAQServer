
################################################################
# This is a generated script based on design: hbridgewaveform
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
# source hbridgewaveform_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# hbridge_signalgen

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name hbridgewaveform

# This script was generated for a remote BD. To create a non-remote design,
# change the variable <run_remote_bd_flow> to <0>.

set run_remote_bd_flow 1
if { $run_remote_bd_flow == 1 } {
  # Set the reference directory for source file relative paths (by default 
  # the value is script directory path)
  set origin_dir ./.julia/dev/RedPitayaDAQServer/src/fpga/bd

  # Use origin directory path location variable, if specified in the tcl shell
  if { [info exists ::origin_dir_loc] } {
     set origin_dir $::origin_dir_loc
  }

  set str_bd_folder [file normalize ${origin_dir}]
  set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

  # Check if remote design exists on disk
  if { [file exists $str_bd_filepath ] == 1 } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <$str_bd_filepath> already exists!"}
     common::send_gid_msg -ssname BD::TCL -id 2031 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0>."
     common::send_gid_msg -ssname BD::TCL -id 2032 -severity "INFO" "Also make sure there is no design <$design_name> existing in your current project."

     return 1
  }

  # Check if design exists in memory
  set list_existing_designs [get_bd_designs -quiet $design_name]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2033 -severity "ERROR" "The design <$design_name> already exists in this project! Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2034 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Check if design exists on disk within project
  set list_existing_designs [get_files -quiet */${design_name}.bd]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2035 -severity "ERROR" "The design <$design_name> already exists in this project at location:
    $list_existing_designs"}
     catch {common::send_gid_msg -ssname BD::TCL -id 2036 -severity "ERROR" "Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2037 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Now can create the remote BD
  # NOTE - usage of <-dir> will create <$str_bd_folder/$design_name/$design_name.bd>
  create_bd_design -dir $str_bd_folder $design_name
} else {

  # Create regular design
  if { [catch {create_bd_design $design_name} errmsg] } {
     common::send_gid_msg -ssname BD::TCL -id 2038 -severity "INFO" "Please set a different value to variable <design_name>."

     return 1
  }
}

current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
pavel-demin:user:axis_variable:1.0\
xilinx.com:ip:dds_compiler:6.0\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlslice:1.0\
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
hbridge_signalgen\
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

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



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

  # Create ports
  set H1out [ create_bd_port -dir O -from 0 -to 0 -type data H1out ]
  set H2out [ create_bd_port -dir O -from 0 -to 0 -type data H2out ]
  set aclk [ create_bd_port -dir I -type clk -freq_hz 125000000 aclk ]
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set enable_All [ create_bd_port -dir I enable_All ]
  set enable_H1 [ create_bd_port -dir I -type data enable_H1 ]
  set enable_H2 [ create_bd_port -dir I -type data enable_H2 ]
  set freq [ create_bd_port -dir I -from 47 -to 0 freq ]
  set phase [ create_bd_port -dir I -from 47 -to 0 phase ]
  set pulswidth [ create_bd_port -dir I -from 15 -to 0 pulswidth ]
  set resync [ create_bd_port -dir I resync ]

  # Create instance: axis_variable_A_channel_1, and set properties
  set axis_variable_A_channel_1 [ create_bd_cell -type ip -vlnv pavel-demin:user:axis_variable:1.0 axis_variable_A_channel_1 ]
  set_property -dict [ list \
   CONFIG.AXIS_TDATA_WIDTH {96} \
 ] $axis_variable_A_channel_1

  # Create instance: dds_compiler_A_channel_1, and set properties
  set dds_compiler_A_channel_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:dds_compiler:6.0 dds_compiler_A_channel_1 ]
  set_property -dict [ list \
   CONFIG.Amplitude_Mode {Full_Range} \
   CONFIG.DATA_Has_TLAST {Not_Required} \
   CONFIG.DDS_Clock_Rate {125} \
   CONFIG.Frequency_Resolution {4.440893e-7} \
   CONFIG.Has_ACLKEN {false} \
   CONFIG.Has_ARESETn {true} \
   CONFIG.Has_Phase_Out {true} \
   CONFIG.Has_TREADY {false} \
   CONFIG.Latency {2} \
   CONFIG.Latency_Configuration {Auto} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.M_PHASE_Has_TUSER {Not_Required} \
   CONFIG.Noise_Shaping {None} \
   CONFIG.Output_Frequency1 {0} \
   CONFIG.Output_Selection {Sine} \
   CONFIG.Output_Width {3} \
   CONFIG.PINC1 {0} \
   CONFIG.POFF1 {0} \
   CONFIG.Parameter_Entry {Hardware_Parameters} \
   CONFIG.PartsPresent {Phase_Generator_only} \
   CONFIG.Phase_Increment {Programmable} \
   CONFIG.Phase_Offset_Angles1 {0} \
   CONFIG.Phase_Width {48} \
   CONFIG.Phase_offset {Programmable} \
   CONFIG.Resync {false} \
   CONFIG.S_PHASE_Has_TUSER {Not_Required} \
   CONFIG.Spurious_Free_Dynamic_Range {88} \
 ] $dds_compiler_A_channel_1

  # Create instance: hbridge_signalgen_0_upgraded_ipi, and set properties
  set block_name hbridge_signalgen
  set block_cell_name hbridge_signalgen_0_upgraded_ipi
  if { [catch {set hbridge_signalgen_0_upgraded_ipi [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hbridge_signalgen_0_upgraded_ipi eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.AXIS_TDATA_PHASE_WIDTH {48} \
   CONFIG.CFG_DATA_WIDTH {14} \
 ] $hbridge_signalgen_0_upgraded_ipi

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_2

  # Create instance: util_vector_logic_3, and set properties
  set util_vector_logic_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_3 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_3

  # Create instance: util_vector_logic_4, and set properties
  set util_vector_logic_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_4 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_4

  # Create instance: util_vector_logic_5, and set properties
  set util_vector_logic_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_5 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_5

  # Create instance: xlconcat_A_channel_1, and set properties
  set xlconcat_A_channel_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_A_channel_1 ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {48} \
   CONFIG.IN1_WIDTH {48} \
   CONFIG.IN2_WIDTH {8} \
   CONFIG.NUM_PORTS {2} \
 ] $xlconcat_A_channel_1

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {13} \
   CONFIG.DIN_WIDTH {16} \
   CONFIG.DOUT_WIDTH {14} \
 ] $xlslice_0

  # Create interface connections
  connect_bd_intf_net -intf_net axis_variable_A_channel_1_M_AXIS [get_bd_intf_pins axis_variable_A_channel_1/M_AXIS] [get_bd_intf_pins dds_compiler_A_channel_1/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net dds_compiler_A_channel_1_M_AXIS_PHASE [get_bd_intf_pins dds_compiler_A_channel_1/M_AXIS_PHASE] [get_bd_intf_pins hbridge_signalgen_0_upgraded_ipi/s_axis_phase]

  # Create port connections
  connect_bd_net -net aresetn_1 [get_bd_ports aresetn] [get_bd_pins axis_variable_A_channel_1/aresetn] [get_bd_pins hbridge_signalgen_0_upgraded_ipi/aresetn] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_ports aclk] [get_bd_pins axis_variable_A_channel_1/aclk] [get_bd_pins dds_compiler_A_channel_1/aclk] [get_bd_pins hbridge_signalgen_0_upgraded_ipi/clk]
  connect_bd_net -net enable_All_1 [get_bd_ports enable_All] [get_bd_pins util_vector_logic_4/Op1] [get_bd_pins util_vector_logic_5/Op1]
  connect_bd_net -net enable_H1_1 [get_bd_ports enable_H1] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net enable_H2_1 [get_bd_ports enable_H2] [get_bd_pins util_vector_logic_3/Op1]
  connect_bd_net -net freq_1 [get_bd_ports freq] [get_bd_pins xlconcat_A_channel_1/In0]
  connect_bd_net -net hbridge_signalgen_0_upgraded_ipi_H1 [get_bd_pins hbridge_signalgen_0_upgraded_ipi/H1] [get_bd_pins util_vector_logic_2/Op2]
  connect_bd_net -net hbridge_signalgen_0_upgraded_ipi_H2 [get_bd_pins hbridge_signalgen_0_upgraded_ipi/H2] [get_bd_pins util_vector_logic_3/Op2]
  connect_bd_net -net phase_1 [get_bd_ports phase] [get_bd_pins xlconcat_A_channel_1/In1]
  connect_bd_net -net pulswidth_1 [get_bd_ports pulswidth] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net resync_1 [get_bd_ports resync] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins dds_compiler_A_channel_1/aresetn] [get_bd_pins util_vector_logic_1/Res]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins util_vector_logic_2/Res] [get_bd_pins util_vector_logic_4/Op2]
  connect_bd_net -net util_vector_logic_3_Res [get_bd_pins util_vector_logic_3/Res] [get_bd_pins util_vector_logic_5/Op2]
  connect_bd_net -net util_vector_logic_4_Res [get_bd_ports H1out] [get_bd_pins util_vector_logic_4/Res]
  connect_bd_net -net util_vector_logic_5_Res [get_bd_ports H2out] [get_bd_pins util_vector_logic_5/Res]
  connect_bd_net -net xlconcat_A_channel_1_dout [get_bd_pins axis_variable_A_channel_1/cfg_data] [get_bd_pins xlconcat_A_channel_1/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins hbridge_signalgen_0_upgraded_ipi/cfg_data] [get_bd_pins xlslice_0/Dout]

  # Create address segments


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


