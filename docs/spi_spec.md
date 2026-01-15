# SPI Specification — 8-bit SAR ADC Digital Interface

## Overview
This document defines the SPI slave interface used to control and read back the SAR ADC digital block. The SPI link provides access to a small register map (CFG/STATUS/RESULT).

This design targets TinyTapeout and uses a synthesizable Verilog subset.

---

## Electrical Signals
- `cs_n` : Chip Select (active low). Frame boundary indicator.
- `sclk` : SPI serial clock from master (external, asynchronous to system `clk`).
- `mosi` : Master Out Slave In.
- `miso` : Master In Slave Out.

---

## SPI Mode and Bit Order
- Mode: **SPI Mode 0**
  - CPOL = 0 (SCLK idles low)
  - CPHA = 0 (sample MOSI on rising edge)
- Bit order: **MSB-first**
- `miso` is shifted/updated on the falling edge (negedge) of `sclk`.

---

## Framing Rules
- A transaction occurs while `cs_n = 0`.
- Shifting is disabled when `cs_n = 1`.
- Each command uses **2 bytes (16 bits)** while CS remains asserted.

If CS deasserts early:
- Partial commands are discarded.
- Internal byte/bit counters reset on CS deassert.

---

## Command Format (16-bit)
Two bytes are transferred while `cs_n = 0`:

### Byte 0: Command
- Bit[7] = R/W
  - `0` = Write
  - `1` = Read
- Bit[6:0] = Address (`ADDR`)

### Byte 1: Data
- Write: `DATA` is written to the addressed register (if writable)
- Read: Byte 1 is typically a dummy value from the master

---

## Read Timing (Pipelined Read)
Reads are **pipelined** to simplify implementation:

1. Master sends a read command (Byte0) and clocks Byte1 (dummy).
2. The slave prepares the requested register value as the **next transmit byte**.
3. Master performs a subsequent byte transfer (either:
   - within a following command frame, or
   - as a dedicated “read data” frame) to receive the data on MISO.

Defined behavior:
- The byte returned after a read command is the data for that read.
- If no prior read is pending, returned data is `0x00`.

(If later changed to same-transaction reads, update this section and DV tests accordingly.)

---

## Register Access Rules
- Writes to RO registers are ignored.
- Reads of unmapped addresses return `0x00` (unless otherwise stated in regmap).

---

## Concurrency / Corner Cases
### Start while Busy
If `CFG.START` is written while `STATUS.BUSY=1`:
- Conversion is **not restarted**
- `STATUS.OVERRUN` is set to `1`

### Reset behavior
On reset assertion:
- All registers return to defined reset values
- Partial SPI frames are discarded
- SPI shifter and counters reset

---

## Performance Notes
- `sclk` is asynchronous to system `clk`; the design uses a CDC bridge for byte transfers.
- Maximum supported `sclk` depends on CDC strategy and implementation margins; DV will verify correct behavior under representative rates.
