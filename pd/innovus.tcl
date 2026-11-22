# TEMPLATE (not yet run). Command and option names differ between versions:
# check `help <cmd>`, innovus.cmd after a GUI run, and the lab reference flow.
# Environment: NETLIST, TECH_LEF, CELL_LEF, GDS_MAP, CELL_GDS, TOP, UTIL
read_mmmc pd/mmmc_template.tcl
read_physical -lef [list $::env(TECH_LEF) $::env(CELL_LEF)]
read_netlist $::env(NETLIST)
init_design

create_floorplan -core_size_by_utilization $::env(UTIL) -aspect_ratio 1 -core_margin_by die -core_margin 10

# Power: replace net, pin and layer names with the PDK's
connect_global_net VDD -type pg_pin -pin_base_name VDD -all
connect_global_net VSS -type pg_pin -pin_base_name VSS -all
# add_rings / add_stripes / route_special: fill in with PDK layers

place_opt_design
ccopt_design
route_design
opt_design -post_route -setup -hold

# add_fillers -base_cell { ... }      ;# filler names from the LEF
verify_drc
verify_connectivity
report_timing > post_route_timing.rpt

# write_stream $::env(TOP).gds -map_file $::env(GDS_MAP) -merge [list $::env(CELL_GDS)] -unit 1000
exit
