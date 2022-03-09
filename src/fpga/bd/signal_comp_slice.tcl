
################################################################
# This is a generated script based on design: signal_comp_slice
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
# source signal_comp_slice_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z010clg400-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name signal_comp_slice

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
  set Din [ create_bd_port -dir I -from 719 -to 0 Din ]
  set comp_0_amp [ create_bd_port -dir O -from 15 -to 0 comp_0_amp ]
  set comp_0_cfg [ create_bd_port -dir O -from 63 -to 0 comp_0_cfg ]
  set comp_0_freq [ create_bd_port -dir O -from 47 -to 0 comp_0_freq ]
  set comp_0_phase [ create_bd_port -dir O -from 47 -to 0 comp_0_phase ]
  set comp_1_amp [ create_bd_port -dir O -from 15 -to 0 comp_1_amp ]
  set comp_1_cfg [ create_bd_port -dir O -from 63 -to 0 comp_1_cfg ]
  set comp_1_freq [ create_bd_port -dir O -from 47 -to 0 comp_1_freq ]
  set comp_1_phase [ create_bd_port -dir O -from 47 -to 0 comp_1_phase ]
  set comp_2_amp [ create_bd_port -dir O -from 15 -to 0 comp_2_amp ]
  set comp_2_cfg [ create_bd_port -dir O -from 63 -to 0 comp_2_cfg ]
  set comp_2_freq [ create_bd_port -dir O -from 47 -to 0 comp_2_freq ]
  set comp_2_phase [ create_bd_port -dir O -from 47 -to 0 comp_2_phase ]
  set comp_3_amp [ create_bd_port -dir O -from 15 -to 0 comp_3_amp ]
  set comp_3_cfg [ create_bd_port -dir O -from 63 -to 0 comp_3_cfg ]
  set comp_3_freq [ create_bd_port -dir O -from 47 -to 0 comp_3_freq ]
  set comp_3_phase [ create_bd_port -dir O -from 47 -to 0 comp_3_phase ]
  set offset [ create_bd_port -dir O -from 15 -to 0 offset ]

  # Create instance: amplitude_A_comp_0_slice1, and set properties
  set amplitude_A_comp_0_slice1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 amplitude_A_comp_0_slice1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {79} \
   CONFIG.DIN_TO {64} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {16} \
 ] $amplitude_A_comp_0_slice1

  # Create instance: amplitude_A_comp_1_slice, and set properties
  set amplitude_A_comp_1_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 amplitude_A_comp_1_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {79} \
   CONFIG.DIN_TO {64} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {16} \
 ] $amplitude_A_comp_1_slice

  # Create instance: amplitude_A_comp_2_slice, and set properties
  set amplitude_A_comp_2_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 amplitude_A_comp_2_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {79} \
   CONFIG.DIN_TO {64} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {16} \
 ] $amplitude_A_comp_2_slice

  # Create instance: amplitude_A_comp_3_slice, and set properties
  set amplitude_A_comp_3_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 amplitude_A_comp_3_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {79} \
   CONFIG.DIN_TO {64} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {16} \
 ] $amplitude_A_comp_3_slice

  # Create instance: cfg_A_comp_0_slice, and set properties
  set cfg_A_comp_0_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 cfg_A_comp_0_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {63} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {64} \
 ] $cfg_A_comp_0_slice

  # Create instance: cfg_A_comp_1_slice, and set properties
  set cfg_A_comp_1_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 cfg_A_comp_1_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {63} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {64} \
 ] $cfg_A_comp_1_slice

  # Create instance: cfg_A_comp_2_slice, and set properties
  set cfg_A_comp_2_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 cfg_A_comp_2_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {63} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {64} \
 ] $cfg_A_comp_2_slice

  # Create instance: cfg_A_comp_3_slice, and set properties
  set cfg_A_comp_3_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 cfg_A_comp_3_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {63} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {64} \
 ] $cfg_A_comp_3_slice

  # Create instance: freq_A_comp_0_slice, and set properties
  set freq_A_comp_0_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 freq_A_comp_0_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {127} \
   CONFIG.DIN_TO {80} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $freq_A_comp_0_slice

  # Create instance: freq_A_comp_1_slice, and set properties
  set freq_A_comp_1_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 freq_A_comp_1_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {127} \
   CONFIG.DIN_TO {80} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $freq_A_comp_1_slice

  # Create instance: freq_A_comp_2_slice, and set properties
  set freq_A_comp_2_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 freq_A_comp_2_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {127} \
   CONFIG.DIN_TO {80} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $freq_A_comp_2_slice

  # Create instance: freq_A_comp_3_slice, and set properties
  set freq_A_comp_3_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 freq_A_comp_3_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {127} \
   CONFIG.DIN_TO {80} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $freq_A_comp_3_slice

  # Create instance: phase_A_comp_0_slice, and set properties
  set phase_A_comp_0_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 phase_A_comp_0_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {175} \
   CONFIG.DIN_TO {128} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $phase_A_comp_0_slice

  # Create instance: phase_A_comp_1_slice, and set properties
  set phase_A_comp_1_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 phase_A_comp_1_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {175} \
   CONFIG.DIN_TO {128} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $phase_A_comp_1_slice

  # Create instance: phase_A_comp_2_slice, and set properties
  set phase_A_comp_2_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 phase_A_comp_2_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {175} \
   CONFIG.DIN_TO {128} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $phase_A_comp_2_slice

  # Create instance: phase_A_comp_3_slice, and set properties
  set phase_A_comp_3_slice [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 phase_A_comp_3_slice ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {175} \
   CONFIG.DIN_TO {128} \
   CONFIG.DIN_WIDTH {176} \
   CONFIG.DOUT_WIDTH {48} \
 ] $phase_A_comp_3_slice

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {191} \
   CONFIG.DIN_TO {16} \
   CONFIG.DIN_WIDTH {720} \
   CONFIG.DOUT_WIDTH {176} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {367} \
   CONFIG.DIN_TO {192} \
   CONFIG.DIN_WIDTH {720} \
   CONFIG.DOUT_WIDTH {176} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {543} \
   CONFIG.DIN_TO {368} \
   CONFIG.DIN_WIDTH {720} \
   CONFIG.DOUT_WIDTH {176} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {719} \
   CONFIG.DIN_TO {544} \
   CONFIG.DIN_WIDTH {720} \
   CONFIG.DOUT_WIDTH {176} \
 ] $xlslice_3

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_WIDTH {528} \
   CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_4

  # Create port connections
  connect_bd_net -net Din_1 [get_bd_pins amplitude_A_comp_0_slice1/Din] [get_bd_pins cfg_A_comp_0_slice/Din] [get_bd_pins freq_A_comp_0_slice/Din] [get_bd_pins phase_A_comp_0_slice/Din] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net Din_2 [get_bd_ports Din] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din] [get_bd_pins xlslice_4/Din]
  connect_bd_net -net amplitude_A_channel_1_slice1_Dout [get_bd_ports comp_0_amp] [get_bd_pins amplitude_A_comp_0_slice1/Dout]
  connect_bd_net -net amplitude_A_comp_1_slice_Dout [get_bd_ports comp_1_amp] [get_bd_pins amplitude_A_comp_1_slice/Dout]
  connect_bd_net -net amplitude_A_comp_2_slice_Dout [get_bd_ports comp_2_amp] [get_bd_pins amplitude_A_comp_2_slice/Dout]
  connect_bd_net -net amplitude_A_comp_3_slice_Dout [get_bd_ports comp_3_amp] [get_bd_pins amplitude_A_comp_3_slice/Dout]
  connect_bd_net -net cfg_A_comp_1_slice_Dout [get_bd_ports comp_1_cfg] [get_bd_pins cfg_A_comp_1_slice/Dout]
  connect_bd_net -net cfg_A_comp_2_slice_Dout [get_bd_ports comp_2_cfg] [get_bd_pins cfg_A_comp_2_slice/Dout]
  connect_bd_net -net cfg_A_comp_3_slice_Dout [get_bd_ports comp_3_cfg] [get_bd_pins cfg_A_comp_3_slice/Dout]
  connect_bd_net -net freq_A_channel_1_slice_Dout [get_bd_ports comp_0_freq] [get_bd_pins freq_A_comp_0_slice/Dout]
  connect_bd_net -net freq_A_comp_1_slice_Dout [get_bd_ports comp_1_freq] [get_bd_pins freq_A_comp_1_slice/Dout]
  connect_bd_net -net freq_A_comp_2_slice_Dout [get_bd_ports comp_2_freq] [get_bd_pins freq_A_comp_2_slice/Dout]
  connect_bd_net -net freq_A_comp_3_slice_Dout [get_bd_ports comp_3_freq] [get_bd_pins freq_A_comp_3_slice/Dout]
  connect_bd_net -net phase_A_channel_1_slice1_Dout [get_bd_ports comp_0_cfg] [get_bd_pins cfg_A_comp_0_slice/Dout]
  connect_bd_net -net phase_A_channel_1_slice_Dout [get_bd_ports comp_0_phase] [get_bd_pins phase_A_comp_0_slice/Dout]
  connect_bd_net -net phase_A_comp_1_slice_Dout [get_bd_ports comp_1_phase] [get_bd_pins phase_A_comp_1_slice/Dout]
  connect_bd_net -net phase_A_comp_2_slice_Dout [get_bd_ports comp_2_phase] [get_bd_pins phase_A_comp_2_slice/Dout]
  connect_bd_net -net phase_A_comp_3_slice_Dout [get_bd_ports comp_3_phase] [get_bd_pins phase_A_comp_3_slice/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins amplitude_A_comp_1_slice/Din] [get_bd_pins cfg_A_comp_1_slice/Din] [get_bd_pins freq_A_comp_1_slice/Din] [get_bd_pins phase_A_comp_1_slice/Din] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins amplitude_A_comp_2_slice/Din] [get_bd_pins cfg_A_comp_2_slice/Din] [get_bd_pins freq_A_comp_2_slice/Din] [get_bd_pins phase_A_comp_2_slice/Din] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins amplitude_A_comp_3_slice/Din] [get_bd_pins cfg_A_comp_3_slice/Din] [get_bd_pins freq_A_comp_3_slice/Din] [get_bd_pins phase_A_comp_3_slice/Din] [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net xlslice_4_Dout [get_bd_ports offset] [get_bd_pins xlslice_4/Dout]

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


