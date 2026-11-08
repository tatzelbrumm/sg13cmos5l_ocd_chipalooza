# Makefile for sg13cmos5l_ocd_chipalooza --- the Open Circuit Design
# "Chipalooza" analog harness chip for the IHP SG13CMOS5L shuttle.
#
#	make		list every target with a one-line description
#	make check	report which derived views are out of date
#
# WHAT THIS IS.  Every step of this flow is already a script, and the
# scripts are the authority on how each step runs.  This file does not
# reimplement them;  it gives each one a short name, puts them in the
# order the README lays out, and records which directory each expects to
# be run from --- the detail that is easy to get wrong and that fails in
# confusing ways (run_gen_filled_final_gds.sh, for one, deletes
# $(PROJECT).mag relative to the current directory, so it must run in
# magic/).
#
# WHAT THIS IS NOT.  It is not a dependency-driven build.  Synthesis,
# layout assembly and LVS all want a human to look at the result before
# the next step runs, and several take hours, so no target here silently
# triggers another.  The ordering below is the intended order;  `make
# check' is what tells you whether something upstream has moved since a
# derived view was built.
#
# The README numbers the flow (1) to (17) and those numbers appear in
# the comments below.  Steps 12, 16 and 17 name scripts by their old
# caravel_openframe names;  the scripts called here are the current ones.

PDK_ROOT ?= $(HOME)/gits
PDK      ?= ihp-sg13cmos5l
export PDK_ROOT PDK

# PROJECT names the final top-level cell.  It is unset by default so
# that each script applies its own default (the final GDS defaults to
# sg13cmos5l_ocd_chipalooza_final, extraction and LVS of the top level
# default to sg13cmos5l_ocd_chipalooza --- one value would be wrong for
# one of them).  IHP supplies the real name at submission:
#
#	make PROJECT=<ihp_name> gds-final drc-final extract-top lvs-top
#
ifneq ($(PROJECT),)
export PROJECT
endif

MAKEFLAGS += --no-print-directory

# ---------------------------------------------------------------------
# Default:  the catalogue.  Descriptions live next to their targets as
# `## text', so this list cannot drift away from the targets themselves.

.PHONY: help
help:
	@echo "sg13cmos5l_ocd_chipalooza --- make targets"
	@echo ""
	@sed -n 's/^\([a-z][a-z0-9-]*\):.*## \(.*\)/\1|\2/p' $(MAKEFILE_LIST) \
	 | awk -F'|' '{printf "  %-22s %s\n", $$1, $$2}'
	@echo ""
	@echo "  PDK_ROOT=$(PDK_ROOT)  PDK=$(PDK)"
	@echo "  Set PROJECT=<name> for the final top-level cell name."

.PHONY: check
check:					## report out-of-date derived views
	@./scripts/check_staleness.py

# ---------------------------------------------------------------------
# Setup  (README 1-3)

.PHONY: setup
setup:					## import PDK cell views into magic/ libraries
	./scripts/setup.sh

.PHONY: setup-custom
setup-custom:				## import custom pad views from slot projects into magic/custom_io
	./scripts/setup_custom.sh

# ---------------------------------------------------------------------
# Configuration and generated views  (README 4-7)
#
# parse_config.py refuses to overwrite an existing output, so `clean-config'
# (which moves the old ones to archive/) comes first when re-running.

.PHONY: config
config:					## config.txt -> padframe verilog, wrapper, padframe tcl
	./scripts/parse_config.py

.PHONY: clean-config
clean-config:				## move config.txt-generated files to archive/
	./scripts/run_clean.sh

.PHONY: padframe
padframe:				## generate magic/sg13cmos5l_padframe.mag
	./scripts/run_gen_padframe.sh

.PHONY: user-id
user-id:				## set the project ID in layout and verilog
	./scripts/set_user_id.py

.PHONY: wrappers
wrappers:				## carve the 18 slot wrapper layouts out of the frame
	./scripts/run_gen_user_wrappers.sh

.PHONY: symbols
symbols:				## regenerate the derived xschem symbols and _lvs.v views
	./scripts/run_gen_xschem_syms.sh

# ---------------------------------------------------------------------
# User projects
#
# The eighteen user projects are submodules at dependencies/slot_<N>,
# cloned from the URLs in config.txt and pinned to the commits recorded
# there.  See scripts/get_projects.sh --help for the file format.
#
# Slot numbers narrow any of these to a subset:
#
#	make projects SLOTS="3 7 12"

SLOTS ?=

.PHONY: projects projects-status projects-update projects-clean
projects:				## clone the user projects named in config.txt
	./scripts/get_projects.sh $(SLOTS)

projects-status:			## report each slot against config.txt
	@./scripts/get_projects.sh --status $(SLOTS)

# Updated slots are left on a detached HEAD at the pinned commit.  To put
# a slot back on its branch (when the pinned commit is the branch tip):
#
#	git -C dependencies/slot_<N> checkout -B main origin/main
#
# "-B" resets the local branch, which is needed after a repository swap
# (the local "main" is still the old repository's), but it also drops
# any local commits on that branch, so check "git log" in the slot first.
projects-update:			## move projects onto the versions in config.txt
	./scripts/get_projects.sh --update $(SLOTS)

# Refuses to discard a project with uncommitted changes in it;  add
# FORCE=1 to remove it anyway.  What is committed always comes back
# from config.txt, so this is only as destructive as the edits you
# have not committed.
projects-clean:				## remove all project submodules (empty harness)
	./scripts/get_projects.sh --clean $(if $(FORCE),--force) $(SLOTS)

.PHONY: projects-gds
projects-gds:				## find each project's slot_<N>.gds, write the placement Tcl
	./scripts/get_project_gds.sh $(SLOTS)

# ---------------------------------------------------------------------
# Digital blocks  (README 8)
#
# LibreLane runs inside a nix shell;  see librelane/*/README.  These
# targets run it if it is on PATH and otherwise say so rather than
# failing with something obscure.  Results are not committed --- only
# the final GDS in gds/ and the .pnl.v in verilog/gl/.

.PHONY: def
def:					## generate the DEF floorplans for both digital blocks
	./scripts/run_gen_hk_def.sh
	./scripts/run_gen_ctrl_def.sh

.PHONY: synth-hk synth-ctrl
synth-hk:				## LibreLane: synthesize/place/route housekeeping_top
	@$(MAKE) -f $(firstword $(MAKEFILE_LIST)) librelane-run DESIGN=housekeeping_top

synth-ctrl:				## LibreLane: synthesize/place/route user_project_control
	@$(MAKE) -f $(firstword $(MAKEFILE_LIST)) librelane-run DESIGN=user_project_control

.PHONY: librelane-run
librelane-run:
	@command -v librelane >/dev/null || { \
	  echo "librelane is not on PATH.  It runs inside a nix shell:"; \
	  echo "    cd <librelane repo>  &&  nix-shell"; \
	  echo "then come back and re-run this target.  See librelane/$(DESIGN)/README."; \
	  exit 1; }
	cd librelane/$(DESIGN) && \
	 systemd-run --user --scope -p MemoryMax=24G -p MemorySwapMax=0 -- \
	 librelane config.yaml --manual-pdk --pdk $(PDK) --pdk-root $(PDK_ROOT)

# ---------------------------------------------------------------------
# Simulation
#
# cocotb lives in a venv under verilog/dv (see its README).  Its makefile
# include needs cocotb-config on PATH at PARSE time, so even `clean'
# fails without it --- hence the venv goes on PATH for both targets.

DV      := verilog/dv
DV_VENV := $(abspath $(DV)/venv/bin)
DV_MAKE  = PATH=$(DV_VENV):$$PATH $(MAKE) -C $(DV)

.PHONY: dv-venv-check
dv-venv-check:
	@test -x $(DV_VENV)/cocotb-config || { \
	  echo "No cocotb venv in $(DV)/.  Create it once with:"; \
	  echo "    cd $(DV) && python3 -m venv venv && \\"; \
	  echo "        ./venv/bin/pip install -r requirements.txt"; \
	  exit 1; }

.PHONY: sim
sim: dv-venv-check			## run the cocotb testbench suite
	$(DV_MAKE)

.PHONY: sim-one
sim-one: dv-venv-check			## run one module:  make sim-one T=test_spi
	@test -n "$(T)" || { echo "set T=<module>, e.g. make sim-one T=test_spi"; exit 1; }
	$(DV_MAKE) COCOTB_TEST_MODULES=$(T)

.PHONY: sim-clean
sim-clean: dv-venv-check		## remove cocotb build products
	$(DV_MAKE) clean

# ---------------------------------------------------------------------
# Netlist extraction

.PHONY: extract-sch extract-sch-top
extract-sch:				## xschem: chipalooza_frame schematic -> spice
	cd xschem && ./run_extract_chipalooza_frame.sh

extract-sch-top:			## xschem: chip top level schematic -> spice
	cd xschem && ./run_extract_ocd_chipalooza.sh

.PHONY: extract-frame extract-padframe extract-top
extract-frame:				## magic: chipalooza_frame layout -> spice
	cd magic && ./run_extract_chipalooza_frame.sh

extract-padframe:			## magic: padframe layout -> spice
	cd magic && ./run_extract_padframe.sh

extract-top:				## magic: chip top level layout -> spice  (README 16)
	cd magic && ./run_extract_chipalooza_top.sh

# ---------------------------------------------------------------------
# Verification
#
# lvs-verilog is the three-way check's middle leg:  schematic against the
# same verilog the testbenches run.  lvs-frame, -padframe and -top are
# layout against schematic.

.PHONY: lvs-verilog lvs-frame lvs-padframe lvs-top
lvs-verilog:				## netgen: chipalooza_frame schematic vs. verilog
	$(MAKE) -C validate/lvs lvs

lvs-frame:				## netgen: chipalooza_frame layout vs. schematic
	cd validate && ./run_lvs_chipalooza_frame.sh

lvs-padframe:				## netgen: padframe layout vs. verilog
	cd validate && ./run_lvs_padframe.sh

lvs-top:				## netgen: chip top level  (README 17)
	cd validate && ./run_lvs_ocd_chipalooza.sh

.PHONY: drc drc-final
drc:					## klayout DRC on the pre-fill GDS
	cd validate && ./run_klayout_drc.sh

drc-final:				## klayout DRC on the final filled GDS  (README 15)
	cd validate && ./run_klayout_drc_final.sh

# ---------------------------------------------------------------------
# Assembly  (README 11-14)
#
# In order:  slot GDS, pre-fill top-level GDS, fill pattern, final GDS.

.PHONY: gds-slots gds-prefill fill gds-final
gds-slots:				## write gds/slot<N>_wrapper.gds for all 18 slots  (11)
	./scripts/run_gen_wrapper_gds.sh

gds-prefill:				## assemble the pre-fill top-level GDS  (12)
	./scripts/run_gen_prefill_gds.sh

fill:					## generate the fill pattern GDS  (13)
	cd gds && ../scripts/generate_fill.py sg13cmos5l_ocd_chipalooza.gds.gz -dist

gds-final:				## assemble the post-fill final GDS  (14)
	cd magic && ../scripts/run_gen_filled_final_gds.sh

# ---------------------------------------------------------------------
# Putting it all together
#
# Hint:  Do each step manually unless you know everything is in working
# condition and will go smoothly.
#
# "make all" does the full custom build.  In the case where no non-default
# pads are declared in config.txt, "make all-default" suffices, avoiding
# the regeneration of the padframe and user wrapper layouts.
# 

.PHONY: all all-default
all:
	make setup
	make projects
	make setup-custom
	make clean-config
	make config
	make padframe
	make wrappers
	make gds-slots
	make user-id
	make projects-gds
	make gds-prefill
	make fill
	make gds-final
	make drc-final

all-default:
	make setup
	make projects
	make user-id
	make projects-gds
	make gds-prefill
	make fill
	make gds-final
	make drc-final

.PHONY: clean
clean: sim-clean			## remove simulation and LVS build products
	$(MAKE) -C validate/lvs clean
