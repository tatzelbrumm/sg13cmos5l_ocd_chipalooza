# cocotb testbench for the Chipalooza harness digital subsystem.
#
#   make                              run every test
#   make COCOTB_TEST_MODULES=test_spi  run one module
#   make COCOTB_TESTCASE=test_nop_command
#   make WAVES=1                      dump a VCD
#
# Needs cocotb and iverilog.  PDK_ROOT/PDK must point at the IHP PDK so
# that sim_defs.v can find the SRAM and standard-cell models.

SIM           ?= icarus
TOPLEVEL_LANG ?= verilog
PDK_ROOT      ?= $(HOME)/gits
PDK           ?= ihp-sg13cmos5l

RTL := $(abspath $(shell pwd)/../rtl)

VERILOG_SOURCES = $(shell pwd)/dut.v
COCOTB_TOPLEVEL = digital_top
# cocotb 2.x renamed these:  MODULE -> COCOTB_TEST_MODULES and
# TOPLEVEL -> COCOTB_TOPLEVEL.  The old names still work but emit a
# deprecation warning on every run.  (TOPLEVEL_LANG was not renamed.)
COCOTB_TEST_MODULES ?= $(shell ls test_*.py 2>/dev/null | sed 's/\.py//' | paste -sd,)

# -gno-specify: the PDK cell models use "ifnone" with edge-sensitive
# paths, which iverilog cannot parse.  The specify blocks are all
# zero-delay anyway, so nothing is lost.
COMPILE_ARGS += -g2012 -gno-specify -I$(RTL) -I$(PDK_ROOT)/$(PDK)

ifeq ($(WAVES),1)
    COMPILE_ARGS += -DWAVES
endif

# Drop cached bytecode at parse time, before cocotb's makefile defines
# its targets.  Python validates __pycache__ on mtime with one-second
# granularity, so an edit to harness.py that does not change the file
# length can be silently ignored if it lands in the same second --- which
# produced a confusing run where restored code still behaved as the
# edited version.  Do NOT express this as "sim: drop-pycache" before the
# include;  that hijacks the default goal and make does nothing.
$(shell rm -rf __pycache__)

include $(shell cocotb-config --makefiles)/Makefile.sim

# Rebuild when any RTL changes, not just when dut.v does.
#
# VERILOG_SOURCES lists only dut.v, because everything else arrives
# through `include in sim_defs.v --- and make cannot see an include.  So
# an edit to housekeeping.v or user_project_control.v left the previously
# compiled sim.vvp in place and the tests silently ran against the OLD
# RTL.  That cost real time: a fix to the dig_ena latch appeared to have
# no effect at all until sim_build was removed by hand.  Naming the RTL
# as an extra prerequisite of the compiled image makes it rebuild.
$(SIM_BUILD)/sim.vvp: $(wildcard $(RTL)/*.v) $(wildcard $(RTL)/*.vh)

clean::
	rm -rf __pycache__ results.xml sim_build *.vcd
