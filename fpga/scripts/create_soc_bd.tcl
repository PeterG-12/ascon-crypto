
################################################################
# This is a generated script based on design: neorv32_aead128
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
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_gid_msg -ssname BD::TCL -id 2040 -severity "CRITICAL WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been changes to the IP between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the functionality and configuration of the design."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source neorv32_aead128_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a100tfgg676-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name neorv32_aead128

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
NEORV32:user:neorv32_vivado_ip:*\
peterg:user:ascon_aead128:*\
xilinx.com:ip:smartconnect:*\
xilinx.com:ip:proc_sys_reset:*\
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
  set clk_0 [ create_bd_port -dir I -type clk clk_0 ]
  set resetn_0 [ create_bd_port -dir I -type rst resetn_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $resetn_0
  set jtag_tck_i_0 [ create_bd_port -dir I jtag_tck_i_0 ]
  set jtag_tdi_i_0 [ create_bd_port -dir I jtag_tdi_i_0 ]
  set jtag_tms_i_0 [ create_bd_port -dir I jtag_tms_i_0 ]
  set jtag_tdo_o_0 [ create_bd_port -dir O jtag_tdo_o_0 ]
  set uart0_txd_o_0 [ create_bd_port -dir O uart0_txd_o_0 ]
  set uart0_rxd_i_0 [ create_bd_port -dir I uart0_rxd_i_0 ]

  # Create instance: neorv32_vivado_ip_0, and set properties
  set neorv32_vivado_ip_0 [ create_bd_cell -type ip -vlnv NEORV32:user:neorv32_vivado_ip neorv32_vivado_ip_0 ]
  set_property -dict [list \
    CONFIG.CACHE_BURSTS_EN {true} \
    CONFIG.CLOCK_FREQUENCY {50000000} \
    CONFIG.DMEM_EN {true} \
    CONFIG.DMEM_SIZE {32768} \
    CONFIG.IMEM_EN {true} \
    CONFIG.IMEM_SIZE {32768} \
    CONFIG.IO_UART0_EN {true} \
    CONFIG.OCD_EN {true} \
    CONFIG.RISCV_ISA_Zicntr {true} \
    CONFIG.XBUS_EN {true} \
  ] $neorv32_vivado_ip_0


  # Create instance: ascon_aead128_0, and set properties
  set ascon_aead128_0 [ create_bd_cell -type ip -vlnv peterg:user:ascon_aead128 ascon_aead128_0 ]

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
  set_property CONFIG.NUM_SI {1} $axi_smc


  # Create instance: rst_clk_0_100M, and set properties
  set rst_clk_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clk_0_100M ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins ascon_aead128_0/s00_axi]
  connect_bd_intf_net -intf_net neorv32_vivado_ip_0_m_axi [get_bd_intf_pins neorv32_vivado_ip_0/m_axi] [get_bd_intf_pins axi_smc/S00_AXI]

  # Create port connections
  connect_bd_net -net ascon_aead128_0_module_interrupt_o  [get_bd_pins ascon_aead128_0/module_interrupt_o] \
  [get_bd_pins neorv32_vivado_ip_0/irq_mei_i]
  connect_bd_net -net clk_0_1  [get_bd_ports clk_0] \
  [get_bd_pins neorv32_vivado_ip_0/clk] \
  [get_bd_pins axi_smc/aclk] \
  [get_bd_pins ascon_aead128_0/s00_axi_aclk] \
  [get_bd_pins rst_clk_0_100M/slowest_sync_clk]
  connect_bd_net -net jtag_tck_i_0_1  [get_bd_ports jtag_tck_i_0] \
  [get_bd_pins neorv32_vivado_ip_0/jtag_tck_i]
  connect_bd_net -net jtag_tdi_i_0_1  [get_bd_ports jtag_tdi_i_0] \
  [get_bd_pins neorv32_vivado_ip_0/jtag_tdi_i]
  connect_bd_net -net jtag_tms_i_0_1  [get_bd_ports jtag_tms_i_0] \
  [get_bd_pins neorv32_vivado_ip_0/jtag_tms_i]
  connect_bd_net -net neorv32_vivado_ip_0_jtag_tdo_o  [get_bd_pins neorv32_vivado_ip_0/jtag_tdo_o] \
  [get_bd_ports jtag_tdo_o_0]
  connect_bd_net -net neorv32_vivado_ip_0_uart0_txd_o  [get_bd_pins neorv32_vivado_ip_0/uart0_txd_o] \
  [get_bd_ports uart0_txd_o_0]
  connect_bd_net -net resetn_0_1  [get_bd_ports resetn_0] \
  [get_bd_pins rst_clk_0_100M/ext_reset_in]
  connect_bd_net -net rst_clk_0_100M_peripheral_aresetn  [get_bd_pins rst_clk_0_100M/peripheral_aresetn] \
  [get_bd_pins axi_smc/aresetn] \
  [get_bd_pins ascon_aead128_0/s00_axi_aresetn] \
  [get_bd_pins neorv32_vivado_ip_0/resetn]
  connect_bd_net -net uart0_rxd_i_0_1  [get_bd_ports uart0_rxd_i_0] \
  [get_bd_pins neorv32_vivado_ip_0/uart0_rxd_i]

  # Create address segments
  assign_bd_address -offset 0x44A00000 -range 0x00001000 -target_address_space [get_bd_addr_spaces neorv32_vivado_ip_0/m_axi] [get_bd_addr_segs ascon_aead128_0/s00_axi/reg0] -force


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


