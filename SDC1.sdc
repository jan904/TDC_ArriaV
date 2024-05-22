create_clock -name CLKINTOP_125_P -period 8 [get_ports {clk}]

derive_clock_uncertainty
derive_pll_clocks

set_false_path -from [get_ports {signal_in}]
set_false_path -from * -to [get_ports {signal_out*}]


