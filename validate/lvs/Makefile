# Structural equivalence between the simulated top level and the
# schematic.  See README.
#
#   make netlist     elaborate digital_top into a structural netlist
#   make lvs         compare that netlist against the schematic
#   make selftest    check the comparison can actually detect an error
#   make clean
#
# SCHEMATIC is the SPICE netlist xschem writes for the same block.

ROOT       := $(abspath ../..)
RTL        := $(ROOT)/verilog/rtl
PDK_ROOT   ?= $(HOME)/gits
PDK        ?= ihp-sg13cmos5l
TOP        := digital_top
SCHEMATIC  ?= $(ROOT)/xschem/$(TOP).spice

NETLIST := $(TOP).struct.v

all: netlist

blackboxes.v: gen_blackboxes.py
	./gen_blackboxes.py > $@

# "flatten" is deliberately NOT used.  netgen compares hierarchically
# and says which subcircuit failed, which is worth much more than one
# undifferentiated pile of 700 instances.  The blackboxes stay opaque
# either way.
# TWO write_verilog passes.  "-blackboxes" is exclusive, not additive:
# it writes ONLY the blackbox modules, and a plain write_verilog writes
# only the non-blackbox ones.  Both halves are needed, and the blackbox
# half is not optional --- without the port declarations netgen infers
# each placeholder's pins from the connections it sees, so a pin that is
# only ever tied to a constant is inferred out of existence and silently
# excluded from the comparison.  That is how 18 proj_addr buses and the
# SRAM tie-offs went unchecked when this was first written.
$(NETLIST): lvs_top.v blackboxes.v $(RTL)/$(TOP).v
	yosys -q -p "read_verilog -sv -I. -I$(RTL) lvs_top.v; \
	             hierarchy -top $(TOP); \
	             proc; opt_clean; \
	             write_verilog -noattr -noexpr -blackboxes $@.bb; \
	             write_verilog -noattr -noexpr $@.top"
	cat $@.bb $@.top > $@
	rm -f $@.bb $@.top

netlist: $(NETLIST)
	@./check_netlist.py $(NETLIST)

lvs: $(NETLIST)
	@test -f $(SCHEMATIC) || { \
	    echo "No schematic netlist at $(SCHEMATIC)."; \
	    echo "Set SCHEMATIC=<path to the xschem .spice output>."; \
	    exit 1; }
	netgen -batch lvs "$(NETLIST) $(TOP)" "$(SCHEMATIC) $(TOP)" \
	    setup.tcl comp.out
	@tail -3 comp.out

selftest: $(NETLIST)
	./selftest.py

clean:
	rm -f $(NETLIST) $(NETLIST).bb $(NETLIST).top comp.out selftest_*.out

.PHONY: all netlist lvs selftest clean
