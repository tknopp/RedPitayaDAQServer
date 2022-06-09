
################################################################
# This is a generated script based on design: waveform_gen
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
# source waveform_gen_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name waveform_gen

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
pavel-demin:user:axis_variable:1.0\
xilinx.com:ip:dds_compiler:6.0\
xilinx.com:ip:mult_gen:12.0\
jbeuke:user:signal_generator:1.0\
xilinx.com:ip:xlconcat:2.1\
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
  set aclk [ create_bd_port -dir I -type clk -freq_hz 125000000 aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {aresetn} \
 ] $aclk
  set amplitude [ create_bd_port -dir I -from 15 -to 0 -type data amplitude ]
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set cfg_data [ create_bd_port -dir I -from 47 -to 0 cfg_data ]
  set freq [ create_bd_port -dir I -from 47 -to 0 freq ]
  set m_axis_data_tvalid_1 [ create_bd_port -dir O m_axis_data_tvalid_1 ]
  set phase [ create_bd_port -dir I -from 47 -to 0 phase ]
  set wave [ create_bd_port -dir O -from 15 -to 0 -type data wave ]

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
   CONFIG.Has_ARESETn {true} \
   CONFIG.Has_Phase_Out {true} \
   CONFIG.Has_TREADY {false} \
   CONFIG.Latency {9} \
   CONFIG.Latency_Configuration {Auto} \
   CONFIG.M_DATA_Has_TUSER {Not_Required} \
   CONFIG.M_PHASE_Has_TUSER {Not_Required} \
   CONFIG.Noise_Shaping {Phase_Dithering} \
   CONFIG.Output_Frequency1 {0} \
   CONFIG.Output_Selection {Sine} \
   CONFIG.Output_Width {14} \
   CONFIG.PINC1 {0} \
   CONFIG.POFF1 {0} \
   CONFIG.Parameter_Entry {System_Parameters} \
   CONFIG.PartsPresent {Phase_Generator_and_SIN_COS_LUT} \
   CONFIG.Phase_Increment {Programmable} \
   CONFIG.Phase_Offset_Angles1 {0} \
   CONFIG.Phase_Width {48} \
   CONFIG.Phase_offset {Programmable} \
   CONFIG.S_PHASE_Has_TUSER {Not_Required} \
   CONFIG.Spurious_Free_Dynamic_Range {84} \
 ] $dds_compiler_A_channel_1

  # Create instance: mult_gen_0, and set properties
  set mult_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mult_gen:12.0 mult_gen_0 ]
  set_property -dict [ list \
   CONFIG.Multiplier_Construction {Use_Mults} \
   CONFIG.OutputWidthHigh {28} \
   CONFIG.OutputWidthLow {13} \
   CONFIG.PipeStages {3} \
   CONFIG.PortAWidth {16} \
   CONFIG.PortBWidth {16} \
   CONFIG.SyncClear {false} \
   CONFIG.Use_Custom_Output_Width {true} \
 ] $mult_gen_0

  # Create instance: signal_generator_0, and set properties
  set signal_generator_0 [ create_bd_cell -type ip -vlnv jbeuke:user:signal_generator:1.0 signal_generator_0 ]
  set_property -dict [ list \
   CONFIG.AXIS_TDATA_PHASE_WIDTH {48} \
   CONFIG.CFG_DATA_WIDTH {48} \
 ] $signal_generator_0

  # Create instance: xlconcat_A_channel_1, and set properties
  set xlconcat_A_channel_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_A_channel_1 ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {48} \
   CONFIG.IN1_WIDTH {48} \
 ] $xlconcat_A_channel_1

  # Create interface connections
  connect_bd_intf_net -intf_net axis_variable_A_channel_1_M_AXIS [get_bd_intf_pins axis_variable_A_channel_1/M_AXIS] [get_bd_intf_pins dds_compiler_A_channel_1/S_AXIS_CONFIG]
  connect_bd_intf_net -intf_net dds_compiler_A_channel_1_M_AXIS_DATA [get_bd_intf_pins dds_compiler_A_channel_1/M_AXIS_DATA] [get_bd_intf_pins signal_generator_0/s_axis]
  connect_bd_intf_net -intf_net dds_compiler_A_channel_1_M_AXIS_PHASE [get_bd_intf_pins dds_compiler_A_channel_1/M_AXIS_PHASE] [get_bd_intf_pins signal_generator_0/s_axis_phase]

  # Create port connections
  connect_bd_net -net amplitude_A_channel_1_slice1_Dout [get_bd_ports amplitude] [get_bd_pins mult_gen_0/A]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_ports aclk] [get_bd_pins axis_variable_A_channel_1/aclk] [get_bd_pins dds_compiler_A_channel_1/aclk] [get_bd_pins mult_gen_0/CLK] [get_bd_pins signal_generator_0/clk]
  connect_bd_net -net freq_1 [get_bd_ports freq] [get_bd_pins xlconcat_A_channel_1/In0]
  connect_bd_net -net mult_gen_0_P [get_bd_ports wave] [get_bd_pins mult_gen_0/P]
  connect_bd_net -net phase_1 [get_bd_ports phase] [get_bd_pins xlconcat_A_channel_1/In1]
  connect_bd_net -net phase_A_channel_1_slice1_Dout [get_bd_ports cfg_data] [get_bd_pins signal_generator_0/cfg_data]
  connect_bd_net -net rst_ps7_0_125M_peripheral_aresetn [get_bd_ports aresetn] [get_bd_pins axis_variable_A_channel_1/aresetn] [get_bd_pins dds_compiler_A_channel_1/aresetn] [get_bd_pins signal_generator_0/aresetn]
  connect_bd_net -net signal_generator_0_m_axis_tdata [get_bd_pins mult_gen_0/B] [get_bd_pins signal_generator_0/m_axis_tdata]
  connect_bd_net -net signal_generator_0_m_axis_tvalid [get_bd_ports m_axis_data_tvalid_1] [get_bd_pins signal_generator_0/m_axis_tvalid]
  connect_bd_net -net xlconcat_A_channel_1_dout [get_bd_pins axis_variable_A_channel_1/cfg_data] [get_bd_pins xlconcat_A_channel_1/dout]

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


