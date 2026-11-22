# TEMPLATE: check time units against the .lib before use.
# Values are in library time units (ns assumed).
set clk_period $::env(CLK_NS)

create_clock -name clk -period $clk_period [get_ports clk]
set_clock_uncertainty 0.1 [get_clocks clk]

# Combinational din -> match is constrained by these two delays
set_input_delay  [expr {$clk_period * 0.3}] -clock clk [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
set_output_delay [expr {$clk_period * 0.3}] -clock clk [all_outputs]

# Asynchronous reset: not a timed data path (recovery/removal checked in P&R)
set_false_path -from [get_ports rst_n]
