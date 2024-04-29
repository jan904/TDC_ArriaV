create_clock -name CLK12M -period 83.333 [get_ports {clk}]

derive_clock_uncertainty

set_false_path -from [get_ports {signal_in}]
set_false_path -from * -to [get_ports {signal_out*}]


