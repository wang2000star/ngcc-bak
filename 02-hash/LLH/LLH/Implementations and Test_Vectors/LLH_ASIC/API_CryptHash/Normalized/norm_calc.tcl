#!/usr/bin/env tclsh

# ==========================================
# 配置区域
# ==========================================

set input_data_list {
    "293.1794,5986.7874,22089.0197,28389.9990"
}

set decay_val "0.11059"
set python_cmd "python3"
set script_name "normalize.py"

set run_count 1


puts "开始批量执行任务..."
puts "共有 [llength $input_data_list] 组输入数据，每组执行 $run_count 次。"
puts "----------------------------------------"

set total_runs 0
set failed_runs 0

foreach input_data $input_data_list {
    puts "\n>>> 处理输入数据: $input_data"
    
    set safe_name [string map {"," "_" "." "_"} $input_data]
    set output_flag "-o result_${safe_name}.log"
    

    for {set i 1} {$i <= $run_count} {incr i} {
        incr total_runs
        
        puts "第 $i/$run_count 次 运行中..."
        
        set cmd_list [list $python_cmd $script_name -i $input_data -d $decay_val {*}$output_flag]
        
        if {[catch {exec {*}$cmd_list} result]} {
            puts stderr "执行失败: $result"
            incr failed_runs
        } else {
            puts "完成。输出文件: [lindex $cmd_list end]"
        }
    }
}

puts "\n----------------------------------------"
puts "所有任务结束。"
puts "总运行次数：$total_runs"
puts "失败次数：$failed_runs"
