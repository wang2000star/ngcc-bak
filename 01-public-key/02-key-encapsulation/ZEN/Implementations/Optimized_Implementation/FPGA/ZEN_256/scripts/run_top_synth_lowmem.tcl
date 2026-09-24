set script_dir [file dirname [file normalize [info script]]]
set direct_tcl [file join $script_dir "run_top_synth_direct_lowmem.tcl"]
puts "INFO: run_top_synth_lowmem.tcl now delegates to run_top_synth_direct_lowmem.tcl"
puts "INFO: reason: launch_runs -jobs 1 does not reliably limit internal synth threads in newer Vivado releases"
source $direct_tcl
