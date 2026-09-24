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

proc zen_assert_valid_profile_iface {profile iface} {
  if {[lsearch -exact [zen_valid_profiles] $profile] < 0} {
    error "unsupported profile '$profile'; expected one of [join [zen_valid_profiles] {, }]"
  }
  if {[lsearch -exact [zen_valid_ifaces] $iface] < 0} {
    error "unsupported iface '$iface'; expected one of [join [zen_valid_ifaces] {, }]"
  }
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
  set paths [eval get_timing_paths $args]
  if {[llength $paths] == 0} {
    return "NA"
  }
  return [get_property SLACK [lindex $paths 0]]
}
