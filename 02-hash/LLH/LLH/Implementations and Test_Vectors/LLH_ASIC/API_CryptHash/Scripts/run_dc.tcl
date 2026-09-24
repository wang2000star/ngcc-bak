#============================================================================
# Scripts: SYNTHESIS_DC.tcl
# Function: run rtl synthesis
# PgTag: 174384c3807ad8092e47b0d7ea82d93ce8df4771 - Tue Oct 14 16:13:45 2025 +0800
#============================================================================
file mkdir ${g_rptdir}/WORK

#============================================================================
# Translate LSTcfg variable to g_variable group
#============================================================================
runStage ${g_rptdir}/01_set_gconfig.rpt {
    set g_design_name $env(G_DESIGN_NAME)
    set g_task_name   syn
    set g_current_script [info script]
    # config set g_* group vars
    source ./g_variable_local.tcl
    setDefault g_design_import_file "../IMPORT/${g_design_name}_rtl_list.vcs"
    setDefault g_syn_timingcons_file "../IMPORT/${g_design_name}_timing_cons.tcl"
    setDefault g_dc_mcmm_file "../IMPORT/${g_design_name}_mcmm_cons.tcl"
    setDefault g_topgraphical_cons "../IMPORT/${g_design_name}_topo_cons.tcl"
    setDefault g_design_nickname [format "GS%03d" [expr int(rand()*1000)]]
};#LSEndof set_gconfig

#============================================================================
# check dc/dcg flow
#============================================================================
if { $g_enable_topgraphical && ![shell_is_in_topographical_mode] } {
    echo "DC is NOT in topographical mode, exiting..."; exit
} elseif { !$g_enable_topgraphical && [shell_is_in_topographical_mode] } {
    echo "DC is in topographical mode, exiting..."; exit
}

#============================================================================
# set message
#============================================================================
runStage ${g_rptdir}/02_set_message.rpt {
    foreach one_message $g_suppress_message {
        suppress_message $one_message
    }
    foreach one_message $g_limitstr_message one_number $g_limitnum_message {
        set_message_info -id $one_message -limit $one_number
    }
    set compile_instance_name_prefix U${g_task_name}
};#LSEndof set_message

#============================================================================
# set host option and clean design
#============================================================================
runStage ${g_rptdir}/03_set_hosts.rpt {
    if { $g_cpu_num>16 } {
        echo "LSTWarning: in dc_shell, max cpu number is 16"
        set g_cpu_num 16 
    }
    set disable_multicore_resource_checks true
    set_host_options -max_cores $g_cpu_num
    report_host_options
};#LSEndof set_hosts

#============================================================================
# create mw for topo
#============================================================================
runStage ${g_rptdir}/04_create_milkyway.rpt {
    if { $g_enable_topgraphical } {
        exec rm -rf ${g_rptdir}/${g_design_name}.mw
        create_mw_lib ${g_rptdir}/${g_design_name}.mw -technology $mw_tech_file -mw_reference_library $mw_ref_library
        open_mw_lib ${g_rptdir}/${g_design_name}.mw
        set_tlu_plus_files -max_tlu $mw_nom_tlu_file -min_tlu $mw_nom_tlu_file -tech2itf $mw_tlu_map_file
    } else {
        echo "None dc topo flow , so no need to create mw lib"
    }
};#LSEndof create_milkyway

#============================================================================
# use block_abstraction
#============================================================================
runStage ${g_rptdir}/05_read_blockabstract.rpt {
    if { $g_enable_subblockabstract } {
        set_top_implementation_options -block_references $g_refs_of_subblockabstract
        set errcnt 0
        if { $g_ddc_of_subblockabstract eq "" } {
            set tfiles ""
            foreach blk $g_refs_of_subblockabstract { 
                lappend tfiles ../IMPORT/${blk}.ddc 
            }
        } else { 
            set tfiles $g_ddc_of_subblockabstract 
        }

        foreach blk $g_refs_of_subblockabstract afile $tfiles {
            if { [file exists $afile] } {
                read_ddc $afile
            } else {
                error "file $afile does not exist ..." ; incr errcnt 
            }
        }
        if { $errcnt>0 } { echo "Error: some submodules' ddc do not exist ..." ; exit 1 }
    }
};#LSEndof read_blockabstract

#============================================================================
# import design
#============================================================================
runStage ${g_rptdir}/06_design_import.rpt {
    set_app_var hdlin_preserve_sequential all
    set_svf ${g_rptdir}/outputs/${g_design_name}.svf
    define_design_lib WORK -path ${g_rptdir}/WORK

    if { $g_power_opt_saif ne "unknown" } { saif_map -start ; file mkdir ${g_rptdir}/power }

    set synInputExt [file extension $g_design_import_file]
    switch -exact $synInputExt {
        ".vcs" {
            set_app_var hdlin_auto_save_templates true
            analyze -f verilog [defineRTL -mode vcs -file $g_design_import_file]
            elaborate ${g_design_name}
            set_app_var hdlin_auto_save_templates false
        }
        ".ddc" {
            read_ddc $g_design_import_file
        }
        ".tcl" {
            source $g_design_import_file
        }
        default {
            echo "Error: Unrecognized synthesis input file type $g_design_import_file, so exit..." ;
            echo "       Supported input file extensions are one of .vcs, .ddc, .tcl ..."
            exit 1
        }
    }
};#LSEndof design_import

#============================================================================
# link design
#============================================================================
runStage ${g_rptdir}/07_link_design.rpt {
    current_design ${g_design_name}
    set status [link]
    if { !$status && !$g_continue_on_link_error } {
        puts stdout "##########################"
        puts stdout "ERROR: COMMAND link FAILED"
        puts stdout "##########################"
        redirect ../RUN/run_info.rpt -append {
            echo "SYN dc_shell script prematurely exited because link failed."
        }
        exit 1
    }
    write -f ddc -hier -o ${g_rptdir}/outputs/${g_design_name}_link.ddc
};#LSEndof link_design

#============================================================================
# rc scaling
#============================================================================
runStage ${g_rptdir}/08_scaling_captran.rpt {
    scalingLibPinMaxCapAndTran $g_max_cap_scaling_factor $g_max_tran_scaling_factor
};#LSEndof scaling_captran

#============================================================================
# load icc setup variable
#============================================================================
runStage ${g_rptdir}/09_load_options.rpt {
    source /export/eda/edalib/smic/12nmSFe/phy_rebuild/tech_13M/smic6T12T/0.1/flow/synopsys_dc.setup
    foreach xpattern $g_user_dont_use {
        lappend g_dont_use $xpattern "user defined" 
    }
    defineDontUse \
        -forbidden_patterns ${g_forbidden_cells} \
        -dontuse_patterns $g_dont_use \
        -allowed_cells $g_user_need_use
    if {$g_enable_clock_map} {set clock_use_cell_list " */CLKINV3_96S6T16UL */CLKINV4_96S6T16UL */CLKINV5_96S6T16UL */CLKINV6_96S6T16UL */CLKINV8_96S6T16UL */CLKINV10_96S6T16UL */CLKINV12_96S6T16UL */CLKINV14_96S6T16UL */CLKINV16_96S6T16UL */CLKLANQV2_96S6T16UL */CLKLANQV4_96S6T16UL */CLKLANQV6_96S6T16UL */CLKLANQV8_96S6T16UL */CLKLANQV10_96S6T16UL */CLKLANQV12_96S6T16UL */CLKLANQV14_96S6T16UL */CLKLANQV16_96S6T16UL */CLKMUX2V2_96S6T16UL */CLKMUX2V4_96S6T16UL */CLKAND2V4_96S6T16UL */CLKOR2V4_96S6T16UL"
        lappend clock_use_cell_list "scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLANQV6_96S6T16UL"
        lappend clock_use_cell_list "scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLAHQV6_96S6T16UL"
        set_attr [get_lib_cells $clock_use_cell_list] dont_use false
        set_target_library_subset -top                                                       -dont_use [get_lib_cells $clock_use_cell_list]
        set_target_library_subset -top -clock_path -use [get_lib_cells $clock_use_cell_list] -dont_use [get_lib_cells "*/*"]
        unset clock_use_cell_list
    }
};#LSEndof load_options

#============================================================================
# uniquify designs
#============================================================================
runStage ${g_rptdir}/10_design_uniquify.rpt {
    current_design ${g_design_name}
    if { ${g_uniquify_force} } {
        set_app_var uniquify_naming_style ${g_design_nickname}_%s_%d
        uniquify -force
    }
};#LSEndof design_uniquify

#============================================================================
# loading timing constraints
#============================================================================
runStage ${g_rptdir}/11_read_constraints.rpt {

	current_design ${g_design_name}
	set_operating_conditions \
	  -analysis_type bc_wc \
	  -max ssg_v0p72_125c -max_library scc12nsfe_96sdb_6tc16p52_enhance_lvt_ssg_v0p72_125c_ccs.db:scc12nsfe_96sdb_6tc16p52_enhance_lvt_ssg_v0p72_125c_ccs \
	  -min ssg_v0p72_125c -min_library scc12nsfe_96sdb_6tc16p52_enhance_lvt_ssg_v0p72_125c_ccs.db:scc12nsfe_96sdb_6tc16p52_enhance_lvt_ssg_v0p72_125c_ccs
	
	if { "NA" ne "NA" } {
	set_wire_load_model -library NA -name NA
	  }
	set synInputExt [file extension $g_syn_timingcons_file]
	switch -exact $synInputExt {
	  ".tcl" { pgSource $g_syn_timingcons_file }
	  ".sdc" { read_sdc $g_syn_timingcons_file }
	  default {
	    echo "Error: Unrecognized constraints file type $g_syn_timingcons_file ..."
	    echo "       Supported constraints files are one of .sdc, .tcl ..."
	  }}
	# DRV constraints
	set_max_transition 0.2 [current_design]
	set_max_transition 0.03 [all_outputs]
	set_max_fanout 32 [current_design]
	set_max_fanout 4 [all_inputs]
    if { $g_power_opt_saif ne "unknown" } {
        reset_switching_activity
        set myWords [split ${g_power_opt_saif} ":"]
        read_saif -input [lindex $myWords 0] -instance_name [lindex $myWords 1] -verbose -auto_map_names
        report_saif -hierarchy -rtl_saif -missing > ${g_rptdir}/power/saif_missing.before_compile.rpt
        set_leakage_optimization false
        set_dynamic_optimization true
        set_app_var compile_enable_total_power_optimization true ;### DCNXT Topo
        set_compile_power_high_effort -total true ;### physical mode
    }
};#LSEndof read_constraints

#============================================================================
# set physical constraints
#============================================================================
runStage ${g_rptdir}/12_graphical_cons.rpt {
    current_design ${g_design_name}
    if { $g_enable_topgraphical } {
        source $g_topgraphical_cons
    }
};#LSEndof graphical_cons

#============================================================================
# insert clock gating manually
#============================================================================
runStage ${g_rptdir}/13_presyn_clockgating.rpt {
    current_design ${g_design_name}
    if { $g_enable_clockgating_insertion } {
		set_attr [get_lib_cells scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLANQV6_96S6T16UL] dont_use false
		set_attr [get_lib_cells scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLAHQV6_96S6T16UL] dont_use false
		#set clock gating
		set_clock_gating_style \
		  -sequential_cell latch \
		  -positive_edge_logic { integrated:scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLANQV6_96S6T16UL } \
		  -negative_edge_logic { integrated:scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLAHQV6_96S6T16UL } \
		  -control_point before  \
		  -control_signal scan_enable \
		  -minimum_bitwidth 4 \
		  -max_fanout 100000000
		
		set power_cg_gated_clock_net_naming_style "%c_cg_clock_%d"
		set power_cg_cell_naming_style "%c_cg_clock_%d"
		
		insert_clock_gating
		report_clock_gating -verbose -ungated -gating_elements -nosplit -multi_stage
		propagate_constraints -gate_clock
		
		set_attr [get_lib_cells scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLANQV6_96S6T16UL] dont_use true
		set_attr [get_lib_cells scc12nsfe_96sdb_6tc16p52_enhance_ulvt_ssg_v0p72_125c_ccs/CLKLAHQV6_96S6T16UL] dont_use true

    }
};#LSEndof presyn_clockgating

#============================================================================
# variable dump for check
#============================================================================
runStage ${g_rptdir}/14_dump_variables.rpt {
    current_design ${g_design_name}
    printvar *
};#LSEndof dump_variables

#============================================================================
# check timing before synthesis
#============================================================================
runStage ${g_rptdir}/15_presyn_check.rpt {
    current_design ${g_design_name}
    eval check_timing ${g_check_timing_options}
};#LSEndof presyn_check

#============================================================================
# compile ultra
#============================================================================
runStage ${g_rptdir}/16_compile_ultra.rpt {
    current_design ${g_design_name}
    set_fix_multiple_port_nets -all -buffer_constants
    set_auto_disable_drc_nets -on_clock_network true -constant false
    echo "Information: all register before synthesis is [sizeof_col [all_registers]]"
    if { $g_enable_topgraphical } {
        eval "compile_ultra -spg $g_compile_options"
    } else {
        eval "compile_ultra $g_compile_options"
    }
    checkUnmapCell ;# check if has some unmapped cells
    checkAlib      ;# update newly generated alib file
    echo "Information: all register after synthesis is [sizeof_col [all_registers]]"
    echo "Information: all 3-pin register after synthesis is [sizeof_col [filter_col [all_registers] pin_number<=3]]"
};#LSEndof compile_ultra

#============================================================================
# rename design
#============================================================================
runStage ${g_rptdir}/17_rename_design.rpt {
    if { ${g_uniquify_force} } {
        set non_rename_design [get_designs -filter "full_name!~${g_design_name} and full_name!~${g_design_nickname}_* and undefined(ilm_cell_area) and undefined(ilm_total_area)"]
        if { [sizeof_col $non_rename_design]>0 } { rename_design $non_rename_design -prefix ${g_design_nickname}_}
        unset -nocomplain non_rename_design
        current_design ${g_design_name}
        link
    }
};#LSEndof rename_design

#============================================================================
# write first
#============================================================================
runStage ${g_rptdir}/18_write_first.rpt {
    set_app_var verilogout_no_tri true
    set_fix_multiple_port_nets -all -buffer_constants
    change_name -rule verilog -hier

    write -f verilog -hier -o ${g_rptdir}/outputs/${g_design_name}_0.v
    write -f ddc     -hier -o ${g_rptdir}/outputs/${g_design_name}_0.ddc
    redirect ${g_rptdir}/reports/${g_design_name}_0.max.rpt  { report_auto_timing -max_paths $g_rpt_maxpaths -sig 6 -del max }
    redirect ${g_rptdir}/reports/${g_design_name}_0.max.sum  { report_auto_timing -max_paths $g_rpt_maxpaths -sig 6 -del max -summary }
    redirect ${g_rptdir}/reports/${g_design_name}_0.qor      { report_qor }
    redirect ${g_rptdir}/reports/${g_design_name}_0.pwr      { report_power }
    redirect -append ${g_rptdir}/reports/${g_design_name}_0.qor  { report_area ; report_area -hier }
};#LSEndof write_first

#============================================================================
# compile incremental
#============================================================================
runStage ${g_rptdir}/19_compile_incr.rpt {
    current_design ${g_design_name}
    set_fix_multiple_port_nets -all -buffer_constants
    set_auto_disable_drc_nets -on_clock_network true -constant false
    if { $g_enable_topgraphical } {
        eval "compile_ultra -spg -inc $g_compile_incr_options"
    } else {
        eval "compile_ultra -inc $g_compile_incr_options"
    }
};#LSEndof compile_incr

#============================================================================
# write results
#============================================================================
runStage ${g_rptdir}/20_write_results.rpt {
    if { $g_power_opt_saif ne "unknown" } {
        report_saif -hierarchy -rtl_saif > ${g_rptdir}/power/report_saif.after_compile.rpt
        report_saif -hierarchy -rtl_saif -missing  > ${g_rptdir}/power/saif_missing.after_compile.rpt
        report_saif -hierarchy > ${g_rptdir}/power/report_saif_all.after_compile.rpt
        write_saif -output ${g_rptdir}/power/dc_out.saif
        write_saif -output ${g_rptdir}/power/dc_out_rtl.saif -rtl
    }

    set_app_var verilogout_no_tri true
    set_fix_multiple_port_nets -all -buffer_constants
    change_name -rule verilog -hier

    write -f verilog -hier -o ${g_rptdir}/outputs/${g_design_name}.v
    write -f ddc     -hier -o ${g_rptdir}/outputs/${g_design_name}.ddc
    redirect ${g_rptdir}/reports/${g_design_name}.max.rpt  { report_auto_timing -max_paths $g_rpt_maxpaths -sig 6 -del max }
    redirect ${g_rptdir}/reports/${g_design_name}.max.sum  { report_auto_timing -max_paths $g_rpt_maxpaths -sig 6 -del max -summary }
    redirect ${g_rptdir}/reports/${g_design_name}.qor      { report_qor }
    redirect ${g_rptdir}/reports/${g_design_name}.pwr      { report_power }
    redirect -append ${g_rptdir}/reports/${g_design_name}.qor  { report_area ; report_area -hier }

    if { $g_enable_clockgating_insertion && $g_enable_clock_ungate_report} {
        redirect ${g_rptdir}/reports/${g_design_name}.clock_ungate.rpt { report_clock_gating -ungated -nosplit -verbose }
        exec /bin/gzip ${g_rptdir}/reports/${g_design_name}.clock_ungate.rpt
    }

    set_svf -off
    checkSynthesis \
        -clock_gating 13_presyn_clockgating.rpt \
        -timing_check 15_presyn_check.rpt \
        -compile_process 16_compile_ultra.rpt \
        -compile_incr 19_compile_incr.rpt

    if { $g_power_opt_saif ne "unknown" } {

        report_power -nosplit > ${g_rptdir}/power/power.txt
        report_power -hier -nosplit > ${g_rptdir}/power/power_hier.txt
        report_clocks -nosplit > ${g_rptdir}/power/all_clock.txt
        report_power -cell -hierarchy -nosplit > ${g_rptdir}/power/power_all_cell.txt
        report_activity > ${g_rptdir}/power/report_activity.rpt
        report_saif > ${g_rptdir}/power/report_saif.rpt

        write_saif -output ${g_rptdir}/power/dc_out_changename.saif
        write_saif -output ${g_rptdir}/power/dc_out_changename_rtl.saif -rtl
        write_saif -output ${g_rptdir}/power/dc_out_changename_propagated.saif -propagated

        saif_map -type primepower -write_map ${g_rptdir}/power/saifmap.primepower.tcl
        saif_map -type ptpx -write_map       ${g_rptdir}/power/saifmap.ptpx.tcl
        saif_map -write_map                  ${g_rptdir}/power/saifmap.name_map.tcl
    }

    writeInfo $g_rptdir/outputs/${g_design_name}.info.tcl

    file link -symbolic ${g_rptdir}/exports/${g_design_name}.v       ${g_rptdir}/outputs/${g_design_name}.v
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.ddc     ${g_rptdir}/outputs/${g_design_name}.ddc
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.qor     ${g_rptdir}/reports/${g_design_name}.qor
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.pwr     ${g_rptdir}/reports/${g_design_name}.pwr
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.max.rpt ${g_rptdir}/reports/${g_design_name}.max.rpt
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.max.sum ${g_rptdir}/reports/${g_design_name}.max.sum
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.svf     ${g_rptdir}/outputs/${g_design_name}.svf
    file link -symbolic ${g_rptdir}/exports/${g_design_name}.info.tcl ${g_rptdir}/outputs/${g_design_name}.info.tcl

};#LSEndof write_results

#============================================================================
# create blockabstract
#============================================================================
runStage ${g_rptdir}/21_create_blockabstract.rpt {
    current_design ${g_design_name}
    if { $g_enable_blockabstract } {
        create_block_abstraction
        write -f ddc -hier -o ${g_rptdir}/outputs/${g_design_name}.bam.ddc
        file link -symbolic ${g_rptdir}/exports/${g_design_name}.bam.ddc \
            ${g_rptdir}/outputs/${g_design_name}.bam.ddc
    }
};#LSEndof create_blockabstract

set mstatus [showMetrics ${g_rptdir}/runtime.rpt]
if { $mstatus } {
    puts "##################"
    puts "# Some Error happened before, please check"
    puts "##################"
    exit 1
}

exit