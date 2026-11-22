# ============================================================================
# PROCESSOR_PIPELINE.sdc - Synopsys Design Constraints for RISC-V Pipeline
# ============================================================================
# Default target clock for Altera DE2 / Cyclone II FPGA Board:
# 50 MHz Clock -> Period = 20.000 ns (Duty cycle 50%: 0.000 to 10.000 ns)
# ============================================================================

create_clock -name {clock} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clock}]

# Automatically derive clock uncertainties
derive_clock_uncertainty

