# Phase 0 Plan — SPI Interface + ADC Digital Control (TinyTapeout)

## Goal
Deliver a **verified** SPI slave interface (external SCLK/CS/MOSI/MISO) that controls and reads back an **8-bit SAR ADC digital controller**, in a TinyTapeout-compatible Verilog subset.

Phase 0 ends when:
- SPI protocol works per spec (write/read)
- CDC is correct and tested (no dropped/duplicated bytes)
- Register map works (RO/RW rules enforced)
- SPI can start a conversion and read back STATUS/RESULT (behavioral ADC model acceptable)
- A regression test suite passes and is runnable with one command

---

## Scope
### In scope
- SPI slave (Mode 0, MSB-first)
- CDC boundary (SCLK domain → system `clk` domain)
- Register file: CFG/STATUS/RESULT (+ optional VIN_TST)
- SAR control FSM (digital) + behavioral comparator model for DV
- DV: directed tests + basic random regression + assertions + coverage goals

### Out of scope (Phase 0)
- Analog CDAC/comparator transistor-level accuracy
- Full-chip integration and pad ring details
- UVM (optional later)

---

## Repo layout
adc_spi/
src/ # synthesizable DUT (Verilog-2001-safe)
tb/ # testbench + scripts
docs/ # phase0/spec/regmap/testplan
Makefile
README.md


---

## Milestones and acceptance criteria

### M0 — Environment + Repo Baseline
**Tasks**
- WSL/Ubuntu set up; open repo in VS Code [WSL]
- Install: git, make, iverilog, gtkwave, verilator, yosys
- Initialize git, commit repo skeleton, push to GitHub

**Acceptance**
- `iverilog -V`, `yosys -V`, `verilator --version` work
- Repo has `src/ tb/ docs/` and Phase 0 docs committed

---

### M1 — SPI Shift Engine (SCLK domain)
**Tasks**
- Implement `src/spi_shift_sclk.v`
  - Mode 0: sample MOSI on posedge SCLK, shift MISO on negedge SCLK
  - Only active when CS asserted (`cs_n=0`)
  - Emit `rx_byte_sclk` + `rx_valid_sclk` each 8 bits
  - Accept `tx_byte_sclk` load via `tx_valid_sclk`

- Create minimal TB `tb/tb_spi_shift.v` to verify:
  - One-byte receive correctness
  - Correct bit order (MSB-first)
  - CS gating works

**Acceptance**
- `make sim_shift` produces `wave.vcd`
- Received byte matches expected in TB (self-checking)

---

### M2 — CDC Bridge (SCLK ↔ clk)
**Tasks**
- Implement `src/spi_cdc_bridge.v`
  - RX: toggle handshake SCLK→clk for bytes
  - TX: toggle handshake clk→SCLK for bytes
  - 2-flop synchronizers on toggles in each receiving domain
- TB: random stream of bytes on SPI; verify no drops/duplicates in clk domain

**Acceptance**
- 1k+ random bytes transfer without mismatch across CDC
- No raw SCLK-domain signals are consumed directly in clk domain (other than via CDC)

---

### M3 — Command Parser + Register File (clk domain)
**Tasks**
- Implement `src/spi_cmd_parser.v` (two-byte command protocol)
- Implement `src/regfile.v`
  - CFG is RW
  - STATUS/RESULT are RO
  - Reset values per regmap
- TB: write CFG, read STATUS/RESULT using pipelined reads

**Acceptance**
- Directed tests: reg reset, write/read-back, RO write ignored, illegal addr returns defined value

---

### M4 — ADC Control Integration (clk domain)
**Tasks**
- Implement `src/sar_ctrl.v` (8-cycle SAR FSM)
- Behavioral comparator model using `VIN_TST` (DV-only):
  - comparator = (vin_tst >= trial_code)
- STATUS updates: BUSY/DONE/OVERRUN
- RESULT updates upon DONE

**Acceptance**
- SPI start conversion sets BUSY then DONE, RESULT matches model
- Start-while-busy behavior matches spec (ignore + set OVERRUN)

---

### M5 — DV Regression + Documentation Freeze
**Tasks**
- Implement full directed suite + random regression
- Add assertions for protocol + FSM invariants
- Add functional coverage goals (tracked in logs)
- Freeze `spi_spec.md` and `regmap.md`

**Acceptance**
- `make regress` passes (multiple seeds)
- `docs/verification_summary.md` created with what is verified and known limitations

---

## Immediate Next Actions (do now)
1. Fill in `docs/spi_spec.md` and `docs/regmap.md`
2. Implement `src/spi_shift_sclk.v`
3. Build `tb/tb_spi_shift.v` + `Makefile` target `make sim_shift`
4. Commit + push after each milestone
