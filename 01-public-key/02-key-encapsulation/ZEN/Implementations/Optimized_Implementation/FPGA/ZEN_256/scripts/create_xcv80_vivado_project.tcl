proc usage {} {
  puts "usage: vivado -mode batch -source create_xcv80_vivado_project.tcl -tclargs <project_dir> <project_name> <part_name> <profile> <iface> ?clock_period_ns? ?synth_stage?"
  puts "  profile: safe | balanced | timing | aggr"
  puts "  iface:   raw | axil"
  puts "  synth_stage: synth | ooc | oo"
  exit 1
}

if {$argc < 5} {
  usage
}

lassign $argv project_dir project_name part_name profile iface clock_period_ns synth_stage
if {$argc < 6 || $clock_period_ns eq ""} {
  set clock_period_ns "10.000"
}
if {$argc < 7 || $synth_stage eq ""} {
  set synth_stage "synth"
}
if {$synth_stage eq "oo"} {
  set synth_stage "ooc"
}
if {$synth_stage ne "synth" && $synth_stage ne "ooc"} {
  error "unsupported synth_stage '$synth_stage', expected 'synth', 'ooc', or 'oo'"
}

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
source [file join $script_dir vivado_common.tcl]

zen_assert_valid_profile_iface $profile $iface

set top_name [zen_top_name $profile $iface xcv80]
set clock_port [zen_clock_port $iface]
set rtl_files [zen_collect_top_project_rtl_files $root_dir $top_name $iface xcv80]

file mkdir $project_dir
set xdc_path [file join $project_dir "${project_name}_auto_clock.xdc"]
zen_write_clock_xdc $xdc_path $clock_port $clock_period_ns

create_project -force $project_name $project_dir -part $part_name
set_param general.maxThreads 1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property source_mgmt_mode None [current_project]

add_files -norecurse $rtl_files
add_files -fileset constrs_1 -norecurse $xdc_path
set_property top $top_name [current_fileset]
zen_apply_verilog_defines_to_project $profile xcv80

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

if {[llength [get_runs synth_1 -quiet]] > 0} {
  if {$synth_stage eq "ooc"} {
    set flatten_mode "tool_default"
    reset_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY [get_runs synth_1]
    reset_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE [get_runs synth_1]
    reset_property strategy [get_runs synth_1]
    set_property -dict [list {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} {-mode out_of_context}] [get_runs synth_1]
  } else {
    set flatten_mode "tool_default"
    reset_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY [get_runs synth_1]
    reset_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE [get_runs synth_1]
    reset_property strategy [get_runs synth_1]
    set_property -dict [list {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} {}] [get_runs synth_1]
  }
}

puts "Created project:"
puts "  board_family = xcv80"
puts "  project_dir = $project_dir"
puts "  project_name = $project_name"
puts "  part_name = $part_name"
puts "  top_name = $top_name"
puts "  iface = $iface"
puts "  profile = $profile"
puts "  synth_stage = $synth_stage"
puts "  flatten_hierarchy = $flatten_mode"
puts "  clock_port = $clock_port"
puts "  clock_period_ns = $clock_period_ns"
puts "  verilog_define = [join [zen_verilog_defines $profile xcv80] { }]"
puts "  rtl_file_count = [llength $rtl_files]"
puts "  xdc = $xdc_path"
