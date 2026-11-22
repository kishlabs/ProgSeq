# Synthesis (Genus 25.1)

| File | Purpose |
|---|---|
| `genus.tcl` | Flow script (TEMPLATE, not yet run) |
| `constraints_template.sdc` | Constraints (TEMPLATE) |

Run: `DESIGN=progseq_top CLK_NS=10 genus -f synth/genus.tcl -log genus.log`

Set `LIB_DIR`, `LIB_FILE` and `RTL_FILES` in your shell. Never commit libraries; reports and netlists stay out of the repo until the publication policy allows them (`docs/pd_plan.md`).
