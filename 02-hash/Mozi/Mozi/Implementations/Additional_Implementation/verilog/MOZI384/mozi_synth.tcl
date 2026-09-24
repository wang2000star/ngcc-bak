# MOZI384 synthesis script for Synopsys Design Compiler.
# Run this script from the MOZI384 source directory.

set DESIGN_NAME "MOZI384"
set TOP_MODULE  "hash_top"
set LIB_ROOT    "../../../LIBS"

set RTL_FILES [list \
    "Mozi.v" \
    "MoziRound.v" \
    "MoziSbox.v" \
    "MoziMC.v" \
    "MoziSR.v" \
    "MoziRCON.v" \
]

proc synthesize_mozi {tech_name search_path_value target_lib power_clock_period} {
    global DESIGN_NAME TOP_MODULE RTL_FILES LIB_ROOT

    # Setting Environment
    if {[file exists WORK]} {file delete -force WORK}
    file mkdir WORK
    define_design_lib WORK -path "./WORK"

    # Setting Libraries
    set_app_var search_path "${LIB_ROOT}/${search_path_value}"
    set_app_var target_library $target_lib
    set_app_var link_library [concat * $target_lib]
    set_app_var alib_library_analysis_path "${LIB_ROOT}/ALIB/"

    # Loading Design
    analyze -format verilog -library WORK $RTL_FILES

    # Elaborating Design (synthesis into generic logic cells)
    elaborate -library WORK $TOP_MODULE
    current_design $TOP_MODULE
    link
    check_design

    # Timing Constraints
    # Clock period is intentionally set to an unreachable value, matching the
    # SPEEDY synthesis method and keeping maximum optimization pressure.
    create_clock -period 0.0000001 -name my_clock [get_ports clk]

    # Area
    set_max_area 1000000

    # Miscellaneous
    # Flatten the round datapath below the top-level controller.
    ungroup -flatten [get_cells u_round/*]

    # Preventing Multi-output ports
    set_fix_multiple_port_nets -all -buffer_constants

    # Compiling Design (mapping into logic cells of logic library + optimization to meet the constraints)
    compile_ultra -no_autoungroup

    # Incremental Compile (repeat incremental compiles to keep the optimization incentive alive)
    compile_ultra -incremental -no_autoungroup
    compile_ultra -incremental -no_autoungroup
    compile_ultra -incremental -no_autoungroup

    # Uniquify
    uniquify -force

    # Writing Synthesized Design
    set netlist_dir "Netlist_${tech_name}"
    file mkdir $netlist_dir
    write -format verilog -hierarchy -output "${netlist_dir}/${DESIGN_NAME}.v"
    change_names -rules vhdl -hier
    write -format vhdl -hierarchy -output "${netlist_dir}/${DESIGN_NAME}.vhd"

    # Reporting
    set report_dir "Report_${tech_name}"
    file mkdir $report_dir
    report_timing -significant_digits 13 > "${report_dir}/${DESIGN_NAME}.tim.rpt"
    report_area -hierarchy > "${report_dir}/${DESIGN_NAME}.area.rpt"

    # Use the SPEEDY-style relaxed clock for power reporting.
    catch {remove_clock [get_clocks my_clock]}
    create_clock -period $power_clock_period -name my_clock [get_ports clk]
    report_power -analysis_effort high -verbose > "${report_dir}/${DESIGN_NAME}.power.rpt"

    # Removing Current Design
    remove_design -all
}

synthesize_mozi \
    "45nm" \
    "NanGate_45nm" \
    "NangateopenCellLibrary_typical.db" \
    10.0

synthesize_mozi \
    "15nm" \
    "NanGate_15nm" \
    "NanGate_15nm_OCL_typical_conditional_ccs.db" \
    10000.0
