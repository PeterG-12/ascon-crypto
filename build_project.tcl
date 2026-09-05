# Build Script: ASCON-128 + NEORV32 SoC
# Target Board: Artix-7 Wukong (XC7A100TFGG676-2)

# 1. Define project parameters
set proj_name    "ascon_soc"
set proj_dir     "./build"
set fpga_part    "xc7a100tfgg676-2"
set bd_script    "./fpga/scripts/create_soc_bd.tcl"
set constr_file  "./fpga/constraints/wukong_soc_constr.xdc"
set neorv_ip_dir "./submodules/neorv32/rtl/system_integration/neorv32_vivado_ip_work/packaged_ip"

# Check if Neorv32 is package if no, package it
if {![file exists $neorv_ip_dir]} {
    puts "Packaging NEORV32 IP..."
    source ./submodules/neorv32/rtl/system_integration/neorv32_vivado_ip.tcl
}

create_project $proj_name $proj_dir -part $fpga_part -force

# Create ip catalog
set_property ip_repo_paths [list ./ip_repo/ascon_aead128 $neorv_ip_dir] [current_project]
update_ip_catalog

# Take the block diagram script
source $bd_script

# Build using both block diagram and the HDL wrapper
set bd_file [get_files [get_property FILE_NAME [current_bd_design]]]
set wrapper_path [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_path
set_property top [file rootname [file tail $wrapper_path]] [current_fileset]

# Add the constraints
add_files -fileset constrs_1 $constr_file

update_compile_order -fileset sources_1

puts " Success: Project '$proj_name' created and ready for synthesis!"
