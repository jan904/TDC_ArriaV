create_clock -name CLKINTOP_125_P -period 8.000 [get_ports {clk}]
derive_pll_clocks 
derive_clock_uncertainty


set_false_path -from [get_ports {signal_in}]

set_false_path -from delay_line:delay_line_inst|carry4:delayblock|Sum_vector* -to encoder:encoder_inst|*
set_false_path -from detect_signal:detect_signal_inst|* -to memory:memory_inst|altsyncram:altsyncram_component|altsyncram_a434:auto_generated|altsyncram_5013:altsyncram1* 

set_net_delay -from detect_signal:detect_signal_inst|signal_running_reg -max -to delay_line:delay_line_inst|carry4:delayblock|* 2
set_max_skew -from [get_clocks *] -to delay_line:delay_line_inst|carry4:delayblock|* 1

set_false_path -from * -to [get_ports {signal_out*}]