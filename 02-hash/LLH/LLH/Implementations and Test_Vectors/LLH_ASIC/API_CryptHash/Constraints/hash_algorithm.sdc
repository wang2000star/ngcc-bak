set PERIOD_NODE_CLOCK 2 ;## 10ns/100M

create_clock -name node_clock [get_ports aclk] -period [expr $PERIOD_NODE_CLOCK]

set_input_delay  -clock v_node_clock    [expr 0.6*${PERIOD_NODE_CLOCK}]   [all_inputs ] 
set_output_delay -clock v_node_clock    [expr 0.6*${PERIOD_NODE_CLOCK}]   [all_outputs] 


set_clock_uncertainty [expr 0.4] -setup [get_clocks node_clock]
set_false_path -from [get_cells u_axi/reg0_reg*] 
set_false_path -from [get_cells u_axi/reg2_reg*] 
set_false_path -from [get_cells u_axi/reg3_reg*] 
set_false_path -from [get_cells u_msg_padder/group_reg*]


set_max_delay 5.0 -from [get_cells u_msg_padder/group_reg*] -to [get_cells u_msg_padder/group_reg*]
set_max_delay 5.0 -from [get_cells u_msg_padder/remain_data*] -to [get_cells u_msg_padder/remain_data*]
set_max_delay 5.0 -from [get_cells u_msg_padder/group_reg*] -to [get_cells u_msg_padder/state_reg*]
set_max_delay 5.0 -from [get_cells u_msg_padder/buf_data_reg*] -to [get_cells u_msg_padder/buf_data_reg*]
set_max_delay 5.0 -from [get_cells u_msg_padder/state_reg*] -to [get_cells u_msg_padder/buf_data_reg*]
set_max_delay 5.0 -from [get_cells u_msg_padder/group_reg*] -to [get_cells u_msg_padder/clk_cg_clock_1/latch*]
set_max_delay 5.0 -from [get_cells u_msg_padder/group_reg*] -to [get_cells u_msg_padder/clk_cg_clock_3/latch*]

