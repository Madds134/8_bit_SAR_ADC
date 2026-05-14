// Module: rx_shift_register
// Project: 8-bit SAR ADC for TinyTapeout
// Function:
//   Samples MOSI on each SPI clock and assembles incoming bytes for the command
//   decoder and write-data path. A full SPI transaction is treated as a 16-bit
//   frame: command byte first, followed by data byte.
module rx_shift_register (
    input wire sclk,          // SPI clock.
    input wire cs_n,          // Active-low chip select. High clears the frame.
    input wire mosi,          // Serial data input from SPI master.
    input reg [4:0] bit_count, // Current bit index within the active SPI frame.
    output reg [7:0] rx_data, // Last completed command or data byte.
    output wire cmd_valid     // Pulses when the command byte is available.
);
    reg [7:0] shift_register;

    // Shift incoming MOSI data MSB-first while cs_n is asserted. The byte is
    // copied to rx_data at the command and data byte boundaries so downstream
    // logic can consume stable parallel data.
    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            shift_register <= 8'd0;
            rx_data <= 8'd0;
        end
        else begin
            // The final bit of the frame is captured directly into rx_data
            // below; skipping the shift avoids an unnecessary post-frame update.
            if(bit_count != 5'd15) begin
                shift_register <= {shift_register[6:0], mosi};
            end

            // Latch a completed byte after bit 7 and bit 15. Including the
            // current MOSI sample preserves the just-received final bit.
            if(bit_count == 5'd7 || bit_count == 5'd15) begin
                rx_data <= {shift_register[6:0], mosi};
            end
        end
    end

    // Assert for one SCLK after the command byte is latched, allowing the
    // decoder to capture rx_data before the data byte continues shifting in.
    assign cmd_valid = (bit_count == 5'd8);
endmodule
