// Module: spi_interface
// Project: 8-bit SAR ADC for TinyTapeout
// Function:
//   Top-level SPI datapath/control wrapper. This module receives MOSI data,
//   tracks frame progress, decodes command timing, and shifts readback data onto
//   MISO for the register-file interface.
module spi_interface (
    input wire sclk,          // SPI clock from the external master.
    input wire cs_n,          // Active-low chip select framing each transfer.
    input wire mosi,          // Serial input from the SPI master.
    input wire [7:0] w_data,  // Parallel read data returned by register file.

    output wire miso,         // Serial output driven toward the SPI master.
    output wire reg_write_en, // Write enable forwarded to the register file.
    output wire [6:0] o_addr  // Register address decoded from the command byte.
);
    reg [4:0] bit_count;
    reg [7:0] rx_data;
    wire cmd_valid;
    wire tx_load_en;

    // RX path: samples MOSI and presents completed command/data bytes to the
    // FSM. cmd_valid marks the cycle when the command byte is available.
    rx_shift_register rsr (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .bit_count(bit_count),
        .rx_data(rx_data),
        .cmd_valid(cmd_valid)
    );

    // Frame counter: tracks bit position while cs_n is asserted so all SPI
    // blocks agree on command/data byte boundaries.
    bit_counter bc (
        .sclk(sclk),
        .cs_n(cs_n),
        .bit_count(bit_count)
    );

    // TX path: loads register-file read data when requested by the FSM and
    // shifts it out on MISO during the response phase.
    tx_shift_register tsr (
        .sclk(sclk),
        .bit_count(bit_count),
        .cs_n(cs_n),
        .data(w_data),
        .tx_load_en(tx_load_en),
        .miso(miso)
    );

    // Transaction controller: decodes read/write commands, drives the register
    // file address/write enable, and requests TX loading for read transfers.
    spi_fsm fsm (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .rx_data(rx_data),
        .bit_count(bit_count),
        .cmd_valid(cmd_valid),
        .rf_addr(o_addr),
        .reg_write_en(reg_write_en),
        .tx_load_en(tx_load_en)
    );

endmodule
