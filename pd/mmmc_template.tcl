# TEMPLATE (not yet run). Single corner to start; add a second corner for hold later.
create_library_set  -name libs -timing [list $::env(LIB_DIR)/$::env(LIB_FILE)]
create_rc_corner    -name rc   -qrc_tech $::env(QRC_TECH)
create_delay_corner -name dc   -library_set libs -rc_corner rc
create_constraint_mode -name cm -sdc_files [list $::env(SDC_FILE)]
create_analysis_view -name view -delay_corner dc -constraint_mode cm
set_analysis_view -setup {view} -hold {view}
