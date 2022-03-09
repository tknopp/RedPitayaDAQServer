
################################################################
# This is a generated script based on design: signal_comp_compose
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
# source signal_comp_compose_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name signal_comp_compose

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
xilinx.com:ip:c_addsub:12.0\
xilinx.com:ip:util_vector_logic:2.0\
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
  set S [ create_bd_port -dir O -from 15 -to 0 -type data S ]
  set aclk [ create_bd_port -dir I -type clk -freq_hz 125000000 aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
   CONFIG.ASSOCIATED_RESET {disable_dac} \
 ] $aclk
  set disable_dac [ create_bd_port -dir I disable_dac ]
  set dyn_offset_disable [ create_bd_port -dir I dyn_offset_disable ]
  set m_axis_data_tvalid_1 [ create_bd_port -dir O -from 0 -to 0 m_axis_data_tvalid_1 ]
  set offset [ create_bd_port -dir I -from 15 -to 0 offset ]
  set seq [ create_bd_port -dir I -from 15 -to 0 -type data seq ]
  set valid0 [ create_bd_port -dir I -from 0 -to 0 valid0 ]
  set valid1 [ create_bd_port -dir I -from 0 -to 0 valid1 ]
  set valid2 [ create_bd_port -dir I -from 0 -to 0 valid2 ]
  set valid3 [ create_bd_port -dir I -from 0 -to 0 valid3 ]
  set wave0 [ create_bd_port -dir I -from 15 -to 0 -type data wave0 ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type generated dependency signed format bool minimum {} maximum {}} value TRUE}}}} DATA_WIDTH 16}} \
 ] $wave0
  set wave1 [ create_bd_port -dir I -from 15 -to 0 -type data wave1 ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type generated dependency signed format bool minimum {} maximum {}} value TRUE}}}} DATA_WIDTH 16}} \
 ] $wave1
  set wave2 [ create_bd_port -dir I -from 15 -to 0 -type data wave2 ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type generated dependency signed format bool minimum {} maximum {}} value TRUE}}}} DATA_WIDTH 16}} \
 ] $wave2
  set wave3 [ create_bd_port -dir I -from 15 -to 0 -type data wave3 ]
  set_property -dict [ list \
   CONFIG.LAYERED_METADATA {xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 16} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type generated dependency signed format bool minimum {} maximum {}} value TRUE}}}} DATA_WIDTH 16}} \
 ] $wave3

  # Create instance: c_addsub_0, and set properties
  set c_addsub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_0 ]
  set_property -dict [ list \
   CONFIG.A_Width {16} \
   CONFIG.B_Value {0000000000000000} \
   CONFIG.B_Width {16} \
   CONFIG.CE {false} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {16} \
 ] $c_addsub_0

  # Create instance: c_addsub_1, and set properties
  set c_addsub_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_1 ]
  set_property -dict [ list \
   CONFIG.A_Width {16} \
   CONFIG.B_Value {0000000000000000} \
   CONFIG.B_Width {16} \
   CONFIG.CE {false} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {16} \
 ] $c_addsub_1

  # Create instance: c_addsub_2, and set properties
  set c_addsub_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_2 ]
  set_property -dict [ list \
   CONFIG.A_Width {16} \
   CONFIG.B_Value {0000000000000000} \
   CONFIG.B_Width {16} \
   CONFIG.CE {false} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {16} \
 ] $c_addsub_2

  # Create instance: c_addsub_3, and set properties
  set c_addsub_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_3 ]
  set_property -dict [ list \
   CONFIG.A_Width {16} \
   CONFIG.B_Value {0000000000000000} \
   CONFIG.B_Width {16} \
   CONFIG.Bypass {true} \
   CONFIG.CE {false} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {16} \
 ] $c_addsub_3

  # Create instance: c_addsub_4, and set properties
  set c_addsub_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_4 ]
  set_property -dict [ list \
   CONFIG.A_Width {16} \
   CONFIG.B_Value {0000000000000000} \
   CONFIG.B_Width {16} \
   CONFIG.CE {false} \
   CONFIG.Latency {1} \
   CONFIG.Out_Width {16} \
   CONFIG.SCLR {true} \
   CONFIG.SINIT {false} \
 ] $c_addsub_4

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {1} \
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

  # Create port connections
  connect_bd_net -net c_addsub_0_S [get_bd_pins c_addsub_0/S] [get_bd_pins c_addsub_1/A]
  connect_bd_net -net c_addsub_1_S [get_bd_pins c_addsub_1/S] [get_bd_pins c_addsub_2/B]
  connect_bd_net -net c_addsub_2_S [get_bd_pins c_addsub_2/S] [get_bd_pins c_addsub_4/B]
  connect_bd_net -net c_addsub_3_S [get_bd_pins c_addsub_3/S] [get_bd_pins c_addsub_4/A]
  connect_bd_net -net c_addsub_4_S [get_bd_ports S] [get_bd_pins c_addsub_4/S]
  connect_bd_net -net clk_wiz_0_clk_internal [get_bd_ports aclk] [get_bd_pins c_addsub_0/CLK] [get_bd_pins c_addsub_1/CLK] [get_bd_pins c_addsub_2/CLK] [get_bd_pins c_addsub_3/CLK] [get_bd_pins c_addsub_4/CLK]
  connect_bd_net -net disable_dac_1 [get_bd_ports disable_dac] [get_bd_pins c_addsub_4/SCLR]
  connect_bd_net -net dyn_offset_disable_1 [get_bd_ports dyn_offset_disable] [get_bd_pins c_addsub_3/BYPASS]
  connect_bd_net -net offset_1 [get_bd_ports offset] [get_bd_pins c_addsub_3/B]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_ports m_axis_data_tvalid_1] [get_bd_pins util_vector_logic_2/Res]
  connect_bd_net -net waveform_gen_0_m_axis_data_tvalid_1 [get_bd_ports valid0] [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net waveform_gen_0_wave [get_bd_ports wave0] [get_bd_pins c_addsub_0/A]
  connect_bd_net -net waveform_gen_1_m_axis_data_tvalid_1 [get_bd_ports valid1] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net waveform_gen_1_wave [get_bd_ports wave1] [get_bd_pins c_addsub_0/B]
  connect_bd_net -net waveform_gen_2_m_axis_data_tvalid_1 [get_bd_ports valid2] [get_bd_pins util_vector_logic_1/Op2]
  connect_bd_net -net waveform_gen_2_wave [get_bd_ports wave2] [get_bd_pins c_addsub_1/B]
  connect_bd_net -net waveform_gen_3_m_axis_data_tvalid_1 [get_bd_ports valid3] [get_bd_pins util_vector_logic_2/Op2]
  connect_bd_net -net waveform_gen_3_wave [get_bd_ports wave3] [get_bd_pins c_addsub_2/A]
  connect_bd_net -net xlslice_4_Dout [get_bd_ports seq] [get_bd_pins c_addsub_3/A]

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


