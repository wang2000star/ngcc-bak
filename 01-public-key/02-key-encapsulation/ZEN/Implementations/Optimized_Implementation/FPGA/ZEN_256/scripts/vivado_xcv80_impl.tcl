proc usage {} {
  puts "usage: vivado -mode batch -source vivado_xcv80_impl.tcl -tclargs <top> <clock_port> <part> <period_ns> <out_dir> <run_name> <stage> ?<max_threads>?"
  puts "  stage: synth | impl | ooc"
  exit 1
}

if {$argc < 7} {
  usage
}

lassign $argv top_name clock_port part_name clk_period_ns out_dir run_name stage max_threads
if {$stage eq "oo"} {
  set stage "ooc"
}
if {$stage ne "synth" && $stage ne "impl" && $stage ne "ooc"} {
  error "unsupported stage '$stage', expected 'synth', 'impl', or 'ooc'"
}
if {$argc < 8 || $max_threads eq ""} {
  set max_threads 1
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
source [file join $script_dir vivado_common.tcl]

file mkdir $out_dir

set rtl_files [zen_collect_rtl_files $root_dir xcv80]
set xdc_path [file join $out_dir "${run_name}.xdc"]
zen_write_clock_xdc $xdc_path $clock_port $clk_period_ns

if {[llength [get_projects -quiet]] > 0} {
  close_project
}

set_param general.maxThreads $max_threads

create_project -in_memory $run_name -part $part_name
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

read_verilog -sv {*}$rtl_files
read_xdc $xdc_path

set flatten_mode "tool_default"
set synth_args [list -top $top_name -part $part_name]
if {$stage ne "ooc"} {
  lappend synth_args -flatten_hierarchy none
  set flatten_mode "none"
}
if {$stage eq "ooc"} {
  lappend synth_args -mode out_of_context
}
eval synth_design $synth_args

write_checkpoint -force -noxdef [file join $out_dir "${run_name}_post_synth.dcp"]
report_utilization -file [file join $out_dir "${run_name}_util_post_synth.rpt"]
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -file [file join $out_dir "${run_name}_timing_post_synth.rpt"]
report_timing -max_paths 5 -nworst 1 -file [file join $out_dir "${run_name}_timing_paths_post_synth.rpt"]

set synth_util_text [report_utilization -return_string]
set synth_luts [zen_metric_from_report $synth_util_text {
  {^\|\s*Slice LUTs\*?\s*\|\s*([0-9,]+)\s*\|}
  {^\|\s*CLB LUTs\*?\s*\|\s*([0-9,]+)\s*\|}
} "NA"]
set synth_ffs [zen_metric_from_report $synth_util_text {
  {^\|\s*Slice Registers\s*\|\s*([0-9,]+)\s*\|}
  {^\|\s*CLB Registers\s*\|\s*([0-9,]+)\s*\|}
} "NA"]
set synth_brams [zen_metric_from_report $synth_util_text {
  {^\|\s*Block RAM Tile\s*\|\s*([0-9,]+(?:\.[0-9]+)?)\s*\|}
  {^\|\s*BRAM Tiles\s*\|\s*([0-9,]+(?:\.[0-9]+)?)\s*\|}
} "NA"]
set synth_dsps [zen_metric_from_report $synth_util_text {
  {^\|\s*DSPs\s*\|\s*([0-9,]+)\s*\|}
} "NA"]
set synth_setup_wns [zen_slack_or_na {-setup -max_paths 1 -nworst 1}]
set synth_hold_wns [zen_slack_or_na {-hold -max_paths 1 -nworst 1}]

set impl_luts "NA"
set impl_ffs "NA"
set impl_brams "NA"
set impl_dsps "NA"
set impl_setup_wns "NA"
set impl_hold_wns "NA"

if {$stage eq "impl"} {
  opt_design
  place_design
  phys_opt_design
  route_design

  write_checkpoint -force -noxdef [file join $out_dir "${run_name}_post_route.dcp"]
  report_utilization -file [file join $out_dir "${run_name}_util_post_route.rpt"]
  report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -file [file join $out_dir "${run_name}_timing_post_route.rpt"]
  report_route_status -file [file join $out_dir "${run_name}_route_status.rpt"]

  set impl_util_text [report_utilization -return_string]
  set impl_luts [zen_metric_from_report $impl_util_text {
    {^\|\s*Slice LUTs\*?\s*\|\s*([0-9,]+)\s*\|}
    {^\|\s*CLB LUTs\*?\s*\|\s*([0-9,]+)\s*\|}
  } "NA"]
  set impl_ffs [zen_metric_from_report $impl_util_text {
    {^\|\s*Slice Registers\s*\|\s*([0-9,]+)\s*\|}
    {^\|\s*CLB Registers\s*\|\s*([0-9,]+)\s*\|}
  } "NA"]
  set impl_brams [zen_metric_from_report $impl_util_text {
    {^\|\s*Block RAM Tile\s*\|\s*([0-9,]+(?:\.[0-9]+)?)\s*\|}
    {^\|\s*BRAM Tiles\s*\|\s*([0-9,]+(?:\.[0-9]+)?)\s*\|}
  } "NA"]
  set impl_dsps [zen_metric_from_report $impl_util_text {
    {^\|\s*DSPs\s*\|\s*([0-9,]+)\s*\|}
  } "NA"]
  set impl_setup_wns [zen_slack_or_na {-setup -max_paths 1 -nworst 1}]
  set impl_hold_wns [zen_slack_or_na {-hold -max_paths 1 -nworst 1}]
}

set metrics_path [file join $out_dir "${run_name}_metrics.txt"]
set metrics_fh [open $metrics_path w]
puts $metrics_fh "run_name=${run_name}"
puts $metrics_fh "top_name=${top_name}"
puts $metrics_fh "clock_port=${clock_port}"
puts $metrics_fh "part_name=${part_name}"
puts $metrics_fh "clk_period_ns=${clk_period_ns}"
puts $metrics_fh "stage=${stage}"
puts $metrics_fh "max_threads=${max_threads}"
puts $metrics_fh "synth_luts=${synth_luts}"
puts $metrics_fh "synth_ffs=${synth_ffs}"
puts $metrics_fh "synth_brams=${synth_brams}"
puts $metrics_fh "synth_dsps=${synth_dsps}"
puts $metrics_fh "synth_setup_wns=${synth_setup_wns}"
puts $metrics_fh "synth_hold_wns=${synth_hold_wns}"
puts $metrics_fh "impl_luts=${impl_luts}"
puts $metrics_fh "impl_ffs=${impl_ffs}"
puts $metrics_fh "impl_brams=${impl_brams}"
puts $metrics_fh "impl_dsps=${impl_dsps}"
puts $metrics_fh "impl_setup_wns=${impl_setup_wns}"
puts $metrics_fh "impl_hold_wns=${impl_hold_wns}"
close $metrics_fh

puts "FLOW_DONE=1"
puts "FLOW_TOP=${top_name}"
puts "FLOW_STAGE=${stage}"
puts "FLOW_FLATTEN=${flatten_mode}"
puts "FLOW_OUT_DIR=${out_dir}"
puts "FLOW_METRICS=${metrics_path}"
