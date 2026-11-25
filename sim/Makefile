# =====================================================================
# Asynchronous FIFO Verification & Build Makefile (Vivado XSIM)
# =====================================================================

# Project Variables
FILELIST    := list.f
RTL_TOP     := async_fifo
TB_TOP      := terminal_explainer_tb
SNAPSHOT    := fifo_sim_snapshot
WDB_FILE    := $(SNAPSHOT).wdb
VCD_FILE    := presentation_waveform.vcd

# Tool Flags
XVLOG_FLAGS := -sv -f $(FILELIST) --relax
XELAB_FLAGS := -debug typical --mt auto -L work

# Define all phony targets
.PHONY: all compile elaborate sim wave wave_vivado clean

# Default target
all: compile elaborate sim

# ---------------------------------------------------------------------
# 1. Compile SystemVerilog RTL & Testbench
# ---------------------------------------------------------------------
compile:
	@echo ">>> [1/3] Compiling SystemVerilog sources from $(FILELIST)..."
	xvlog $(XVLOG_FLAGS) -log xvlog.log

# ---------------------------------------------------------------------
# 2. Elaborate Design & Generate Simulation Snapshot
# ---------------------------------------------------------------------
elaborate: compile
	@echo ">>> [2/3] Elaborating top module $(TB_TOP)..."
	xelab $(XELAB_FLAGS) $(TB_TOP) -s $(SNAPSHOT) -log xelab.log

# ---------------------------------------------------------------------
# 3. Run Batch Simulation in Terminal (Generates VCD & WDB)
# ---------------------------------------------------------------------
sim: elaborate
	@echo ">>> [3/3] Running simulation in batch mode..."
	xsim $(SNAPSHOT) -R -log xsim.log

# ---------------------------------------------------------------------
# 4. View Waveforms
# ---------------------------------------------------------------------
# Use this to open the lightweight .vcd file in GTKWave
wave_gtk:
	@echo ">>> Opening waveform in GTKWave..."
	gtkwave $(VCD_FILE) &

# Use this to open the Vivado simulator GUI natively
wave:
	@echo ">>> Opening waveform in Vivado GUI..."
	xsim $(SNAPSHOT) -gui &

# ---------------------------------------------------------------------
# 5. Clean Environment
# ---------------------------------------------------------------------
clean:
	@echo ">>> Cleaning up simulation binaries, logs, waveforms, and temp directories..."
	rm -rf xsim.dir .Xil vivado_proj
	rm -f *.log *.jou *.pb *.wdb *.vcd *.str xsim_gui.tcl build_vivado.tcl
