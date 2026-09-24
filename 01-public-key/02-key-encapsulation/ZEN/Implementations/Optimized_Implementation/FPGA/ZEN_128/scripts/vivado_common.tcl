proc zen_valid_profiles {} {
  return {safe balanced timing aggr}
}

proc zen_valid_ifaces {} {
  return {raw axil}
}

proc zen_valid_board_families {} {
  return {xcvu37p xcv80}
}

proc zen_default_clock_period_ns {} {
  return "5.000"
}

proc zen_default_part_name {{board_family xcvu37p}} {
  zen_assert_valid_board_family $board_family
  switch -- $board_family {
    xcvu37p { return "xcvu37p-fsvh2892-2-e" }
    xcv80 { return "xcv80-lsva4737-2MHP-e-S" }
    default {
      error "unsupported board family '$board_family'"
    }
  }
}

proc zen_assert_valid_board_family {board_family} {
  if {[lsearch -exact [zen_valid_board_families] $board_family] < 0} {
    error "unsupported board family '$board_family'; expected one of [join [zen_valid_board_families] {, }]"
  }
}

proc zen_assert_valid_profile {profile} {
  if {[lsearch -exact [zen_valid_profiles] $profile] < 0} {
    error "unsupported profile '$profile'; expected one of [join [zen_valid_profiles] {, }]"
  }
}

proc zen_assert_valid_profile_iface {profile iface} {
  zen_assert_valid_profile $profile
  if {[lsearch -exact [zen_valid_ifaces] $iface] < 0} {
    error "unsupported iface '$iface'; expected one of [join [zen_valid_ifaces] {, }]"
  }
}

proc zen_verilog_defines {profile {board_family xcvu37p}} {
  zen_assert_valid_profile $profile
  zen_assert_valid_board_family $board_family

  set defines {}
  if {$board_family eq "xcv80"} {
    lappend defines USE_XCV80
  }

  switch -- $profile {
    safe     { lappend defines USE_SAFE }
    timing   { lappend defines USE_TIMING }
    aggr     { lappend defines USE_AGGR }
    balanced { }
    default {
      error "unsupported profile '$profile'"
    }
  }

  return $defines
}

proc zen_apply_verilog_defines_to_project {profile {board_family xcvu37p}} {
  set defines [zen_verilog_defines $profile $board_family]
  if {[llength $defines] > 0} {
    set_property verilog_define $defines [current_fileset]
    if {[llength [get_filesets sim_1 -quiet]] > 0} {
      set_property verilog_define $defines [get_filesets sim_1]
    }
  } else {
    if {[llength [current_fileset -quiet]] > 0} {
      reset_property verilog_define [current_fileset]
    }
    if {[llength [get_filesets sim_1 -quiet]] > 0} {
      reset_property verilog_define [get_filesets sim_1]
    }
  }
}

proc zen_read_verilog_with_defines {rtl_files profile {board_family xcvu37p}} {
  set read_args [list -sv]
  foreach define_name [zen_verilog_defines $profile $board_family] {
    lappend read_args -define $define_name
  }
  eval read_verilog $read_args {*}$rtl_files
}

proc zen_top_name {profile iface {board_family xcvu37p}} {
  zen_assert_valid_profile_iface $profile $iface
  zen_assert_valid_board_family $board_family
  set top_prefix "zen_accel_${board_family}"
  switch -- "${profile}:${iface}" {
    "safe:raw"      { return "${top_prefix}_safe_top" }
    "balanced:raw"  { return "${top_prefix}_top" }
    "timing:raw"    { return "${top_prefix}_timing_top" }
    "aggr:raw"      { return "${top_prefix}_aggr_top" }
    "safe:axil"     { return "${top_prefix}_safe_axil_top" }
    "balanced:axil" { return "${top_prefix}_axil_top" }
    "timing:axil"   { return "${top_prefix}_timing_axil_top" }
    "aggr:axil"     { return "${top_prefix}_aggr_axil_top" }
    default {
      error "internal top selection failure for ${board_family}:${profile}:${iface}"
    }
  }
}

proc zen_clock_port {iface} {
  if {$iface eq "raw"} {
    return "clk"
  }
  if {$iface eq "axil"} {
    return "s_axil_aclk"
  }
  error "unsupported iface '$iface'"
}

proc zen_ooc_wrapper_top {module_name} {
  switch -- $module_name {
    zen_msg_codec               { return zen_ooc_msg_codec_top }
    zen_ct_pack_row_core        { return zen_ooc_ct_pack_row_core_top }
    zen_pk_unpack_seq_core      { return zen_ooc_pk_unpack_seq_core_top }
    zen_sk_unpack_seq_core      { return zen_ooc_sk_unpack_seq_core_top }
    zen_keypair_pack_seq_core   { return zen_ooc_keypair_pack_seq_core_top }
    zen_sampler_core            { return zen_ooc_sampler_core_top }
    zen_ntt_core                { return zen_ooc_ntt_core_top }
    zen_basemul_core            { return zen_ooc_basemul_core_top }
    zen_baseinv_core            { return zen_ooc_baseinv_core_top }
    zen_binary_core             { return zen_ooc_binary_core_top }
    zen_binary_fast_inv_core    { return zen_ooc_binary_fast_inv_core_top }
    zen_pke_enc_core            { return zen_ooc_pke_enc_core_top }
    zen_pke_keygen_core         { return zen_ooc_pke_keygen_core_top }
    zen_pke_dec_core            { return zen_ooc_pke_dec_core_top }
    default {
      if {[string match "zen_ooc_*" $module_name]} {
        return $module_name
      }
      error "unsupported OOC module '$module_name'"
    }
  }
}

proc zen_collect_rtl_files {root_dir {board_family xcvu37p}} {
  zen_assert_valid_board_family $board_family
  set rtl_dir [file join $root_dir "rtl"]
  set filelist_path [file join $rtl_dir "filelist_${board_family}.f"]
  if {![file exists $filelist_path]} {
    error "missing canonical RTL filelist: $filelist_path"
  }

  set rtl_files {}
  set fh [open $filelist_path r]
  while {[gets $fh line] >= 0} {
    set trimmed [string trim $line]
    if {$trimmed eq ""} {
      continue
    }
    if {[string match "#*" $trimmed]} {
      continue
    }
    set rtl_file [file normalize [file join $rtl_dir $trimmed]]
    if {![file exists $rtl_file]} {
      close $fh
      error "missing RTL file from filelist: $rtl_file"
    }
    lappend rtl_files $rtl_file
  }
  close $fh
  return $rtl_files
}

proc zen_collect_top_project_rtl_files {root_dir top_name iface {board_family xcvu37p}} {
  set rtl_files [zen_collect_rtl_files $root_dir $board_family]
  set filtered_files {}

  foreach rtl_file $rtl_files {
    set file_name [file tail $rtl_file]
    set module_name [file rootname $file_name]

    if {$file_name eq "zen_ooc_probe_wrappers.sv"} {
      continue
    }

    if {[string match "zen_accel_${board_family}_*top.sv" $file_name] && ($module_name ne $top_name)} {
      continue
    }

    if {($iface eq "raw") && ($file_name eq "zen_accel_axil_wrapper.sv")} {
      continue
    }

    lappend filtered_files $rtl_file
  }

  return $filtered_files
}

proc zen_collect_ooc_project_rtl_files {root_dir {board_family xcvu37p}} {
  set rtl_files [zen_collect_rtl_files $root_dir $board_family]
  set filtered_files {}

  foreach rtl_file $rtl_files {
    set file_name [file tail $rtl_file]

    if {[string match "zen_accel_${board_family}_*top.sv" $file_name]} {
      continue
    }

    if {$file_name eq "zen_accel_axil_wrapper.sv"} {
      continue
    }

    lappend filtered_files $rtl_file
  }

  set wrapper_file [file normalize [file join $root_dir "rtl" "zen_ooc_probe_wrappers.sv"]]
  if {[file exists $wrapper_file]} {
    lappend filtered_files $wrapper_file
  }

  return $filtered_files
}

proc zen_write_clock_xdc {xdc_path clock_port clock_period_ns} {
  set xdc_fh [open $xdc_path w]
  puts $xdc_fh "# Auto-generated portable clock constraint."
  puts $xdc_fh "create_clock -name ${clock_port} -period ${clock_period_ns} \[get_ports ${clock_port}\]"
  close $xdc_fh
}

proc zen_metric_from_report {report_text regex_list default_value} {
  foreach pattern $regex_list {
    if {[regexp -line -nocase -- $pattern $report_text -> value]} {
      return [string map {"," ""} $value]
    }
  }
  return $default_value
}

proc zen_slack_or_na {args} {
  set flat_args {}
  foreach arg $args {
    if {[llength $arg] > 1} {
      set flat_args [concat $flat_args $arg]
    } else {
      lappend flat_args $arg
    }
  }
  set paths [get_timing_paths {*}$flat_args]
  if {[llength $paths] == 0} {
    return "NA"
  }
  return [get_property SLACK [lindex $paths 0]]
}
