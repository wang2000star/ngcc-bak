proc usage {} {
  puts "usage: vivado -mode batch -source create_xcvu37p_vivado_project.tcl -tclargs <project_dir> <project_name> <part_name> <profile> <iface> ?clock_period_ns?"
  puts "  profile: safe | balanced | timing | aggr"
  puts "  iface:   raw | axil"
  exit 1
}

if {$argc < 5} {
  usage
}

lassign $argv project_dir project_name part_name profile iface clock_period_ns
if {$argc < 6 || $clock_period_ns eq ""} {
  set clock_period_ns "5.000"
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
source [file join $script_dir vivado_common.tcl]

zen_assert_valid_profile_iface $profile $iface

set top_name [zen_top_name $profile $iface]
set clock_port [zen_clock_port $iface]
set rtl_files [zen_collect_rtl_files $root_dir]

file mkdir $project_dir
set xdc_path [file join $project_dir "${project_name}_auto_clock.xdc"]
zen_write_clock_xdc $xdc_path $clock_port $clock_period_ns

create_project -force $project_name $project_dir -part $part_name
set_param general.maxThreads 1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property source_mgmt_mode All [current_project]

add_files -norecurse $rtl_files
add_files -fileset constrs_1 -norecurse $xdc_path
set_property top $top_name [current_fileset]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

if {[llength [get_runs synth_1 -quiet]] > 0} {
  set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs synth_1]
  set_property strategy Flow_RuntimeOptimized [get_runs synth_1]
}

puts "Created project:"
puts "  project_dir = $project_dir"
puts "  project_name = $project_name"
puts "  part_name = $part_name"
puts "  top_name = $top_name"
puts "  iface = $iface"
puts "  profile = $profile"
puts "  clock_port = $clock_port"
puts "  clock_period_ns = $clock_period_ns"
puts "  xdc = $xdc_path"
