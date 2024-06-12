create_clock -name CLKINTOP_125_P -period 8.000 [get_ports {clk}]
derive_pll_clocks 
derive_clock_uncertainty


set_false_path -from [get_ports {signal_in}]

set_false_path -from detect_signal:detect_signal_inst|reset_reg -to delay_line:delay_line_inst|carry4:delayblock|*
