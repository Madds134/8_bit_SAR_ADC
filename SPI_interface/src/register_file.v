// Module: register_file
// Project: 8-bit SAR ADC for TinyTapeout
// Function:
//   Implements the SPI-accessible control register space. Writes are committed
//   on the rising edge of cs_n so configuration changes take effect only after
//   the current SPI frame has completed.

// Mock Register Space for testing at this time:
//   0x00: ADC configuration register, mirrored to adc_cfg
//   0x01: Reserved/user register, reset value 0x55
//   0x02: Reserved/user register
//   0x03: PGA control register, mirrored to pga_ctrl
module register_file (
    input  sclk,          // SPI clock. Present for interface consistency.
    input  rst,           // Asynchronous active-high reset.
    input  reg_write_en,  // Write strobe qualified by the SPI command decoder.
    input  cs_n,          // Active-low chip select. Rising edge ends the frame.
    input  [7:0] w_data,  // Data byte to commit on a valid write transaction.
    input  [6:0] addr,    // Register address decoded from the SPI command byte.
    output reg [7:0] r_data, // Combinational read data for the selected address.

    output reg [7:0] pga_ctrl, // Latched PGA control output.
    output reg [7:0] adc_cfg   // Latched ADC configuration output.
);
    reg [7:0] register [0:7];

    // Commit register writes and update external control outputs at
    // the end of the SPI frame.
    always @(posedge cs_n or posedge rst) begin
        if (rst) begin
            register[3'h00] <= 8'h00;
            register[3'h01] <= 8'h55;
            register[3'h02] <= 8'h00;
            register[3'h03] <= 8'h00;
            pga_ctrl        <= 8'h00;
            adc_cfg         <= 8'h00;
        end else begin
            if (reg_write_en) begin
                case (addr)
                    3'h00: register[addr] <= w_data;
                    3'h01: register[addr] <= w_data;
                    3'h02: register[addr] <= w_data;
                    3'h03: register[addr] <= w_data;
                endcase
            end

            // Forward the  value to mirrored outputs during the same cs_n edge; otherwise, hold the previously stored register.
            pga_ctrl <= (reg_write_en && addr == 3'h03) ? w_data : register[3'h03];
            adc_cfg  <= (reg_write_en && addr == 3'h00) ? w_data : register[3'h00];
        end
    end

    // Reads are combinational so the SPI transmit path can source data during
    // the active frame at any time without additional clock edge.
    always @(*) begin
        r_data = register[addr];
    end

endmodule
