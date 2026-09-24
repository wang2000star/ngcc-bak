set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
source [file join $script_dir vivado_common.tcl]

set profile "balanced"
set iface "raw"
set board_family "xcvu37p"
set part_name [zen_default_part_name $board_family]
set clock_period_ns [zen_default_clock_period_ns]
set thread_count 1
set flatten_mode "none"
set out_dir [file join $root_dir "build_vivado_${board_family}" "direct_synth_balanced_raw"]

if {[info exists ::env(PROFILE)] && $::env(PROFILE) ne ""} {
  set profile $::env(PROFILE)
}
if {[info exists ::env(IFACE)] && $::env(IFACE) ne ""} {
  set iface $::env(IFACE)
}
if {[info exists ::env(BOARD_FAMILY)] && $::env(BOARD_FAMILY) ne ""} {
  set board_family $::env(BOARD_FAMILY)
}
zen_assert_valid_board_family $board_family
set part_name [zen_default_part_name $board_family]
if {[info exists ::env(XCVU37P_PART)] && $::env(XCVU37P_PART) ne "" && $board_family eq "xcvu37p"} {
  set part_name $::env(XCVU37P_PART)
}
if {[info exists ::env(XCV80_PART)] && $::env(XCV80_PART) ne "" && $board_family eq "xcv80"} {
  set part_name $::env(XCV80_PART)
}
if {[info exists ::env(CLOCK_PERIOD_NS)] && $::env(CLOCK_PERIOD_NS) ne ""} {
  set clock_period_ns $::env(CLOCK_PERIOD_NS)
}
if {[info exists ::env(LOWMEM_THREADS)] && [string is integer -strict $::env(LOWMEM_THREADS)] && $::env(LOWMEM_THREADS) > 0} {
  set thread_count $::env(LOWMEM_THREADS)
}
if {[info exists ::env(LOWMEM_FLATTEN_HIERARCHY)] && $::env(LOWMEM_FLATTEN_HIERARCHY) ne ""} {
  set flatten_mode $::env(LOWMEM_FLATTEN_HIERARCHY)
}
if {[info exists ::env(LOWMEM_OUT_DIR)] && $::env(LOWMEM_OUT_DIR) ne ""} {
  set out_dir [file normalize $::env(LOWMEM_OUT_DIR)]
} else {
  set out_dir [file join $root_dir "build_vivado_${board_family}" "direct_synth_${profile}_${iface}"]
}

zen_assert_valid_profile_iface $profile $iface

set top_name [zen_top_name $profile $iface $board_family]
set clock_port [zen_clock_port $iface]
set rtl_files [zen_collect_rtl_files $root_dir $board_family]

file mkdir $out_dir

if {[llength [get_projects -quiet]] > 0} {
  close_project
}

set_param general.maxThreads $thread_count
create_project -in_memory ${top_name}_direct -part $part_name
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

read_verilog -sv {*}$rtl_files

set xdc_path [file join $out_dir "${top_name}_auto_clock.xdc"]
zen_write_clock_xdc $xdc_path $clock_port $clock_period_ns
read_xdc $xdc_path

set dcp_path [file join $out_dir "${top_name}.dcp"]
set util_rpt [file join $out_dir "${top_name}_utilization_synth.rpt"]
set timing_rpt [file join $out_dir "${top_name}_timing_summary_synth.rpt"]

puts "DIRECT_SYNTH_TOP=$top_name"
puts "DIRECT_SYNTH_BOARD=$board_family"
puts "DIRECT_SYNTH_IFACE=$iface"
puts "DIRECT_SYNTH_PART=$part_name"
puts "DIRECT_SYNTH_CLOCK_PORT=$clock_port"
puts "DIRECT_SYNTH_CLOCK_PERIOD_NS=$clock_period_ns"
puts "DIRECT_SYNTH_THREADS=$thread_count"
puts "DIRECT_SYNTH_FLATTEN=$flatten_mode"
puts "DIRECT_SYNTH_OUT_DIR=$out_dir"

synth_design -top $top_name -part $part_name -flatten_hierarchy $flatten_mode
write_checkpoint -force -noxdef $dcp_path
report_utilization -file $util_rpt
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -file $timing_rpt

puts "DIRECT_SYNTH_DONE=1"
puts "DIRECT_SYNTH_DCP=$dcp_path"
puts "DIRECT_SYNTH_UTIL=$util_rpt"
puts "DIRECT_SYNTH_TIMING=$timing_rpt"
