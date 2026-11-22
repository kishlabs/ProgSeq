# TEMPLATE (not yet run). Verify commands with `help <cmd>` on Genus 25.1.
# Environment: DESIGN, CLK_NS, LIB_DIR, LIB_FILE, RTL_FILES (space separated)
set DESIGN $::env(DESIGN)
set RUN    "runs/${DESIGN}_$::env(CLK_NS)ns"
file mkdir $RUN

set_db init_lib_search_path $::env(LIB_DIR)
set_db library              $::env(LIB_FILE)

read_hdl [split $::env(RTL_FILES) " "]
elaborate $DESIGN
check_design -unresolved

read_sdc synth/constraints_template.sdc

syn_generic
syn_map
syn_opt

report_timing > $RUN/timing.rpt
report_area   > $RUN/area.rpt
report_power  > $RUN/power.rpt
report_gates  > $RUN/gates.rpt

write_hdl > $RUN/${DESIGN}_netlist.v
write_sdc > $RUN/${DESIGN}_out.sdc
exit
