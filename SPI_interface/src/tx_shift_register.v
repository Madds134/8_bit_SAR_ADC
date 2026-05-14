// Module: tx_shift_register
// Project: 8-bit SAR ADC for TinyTapeout
// Function:
//   Loads parallel readback data from the register file and shifts it out
//   MSB-first on MISO during SPI read transactions.
module tx_shift_register (
    input wire sclk,          // SPI clock.
    input wire [4:0] bit_count, // Current bit index within the SPI frame.
    input wire cs_n,          // Active-low chip select. High clears TX state.
    input wire [7:0] data,    // Parallel byte to transmit on read transfers.
    input wire tx_load_en,    // One-cycle load request from the SPI FSM.
    output wire miso          // Current serial output bit.
);

reg [7:0] shift_register;
reg loaded;

// Update MISO on the falling edge so the output is stable before the SPI master
// samples on the following rising edge.
always @(negedge sclk or posedge cs_n) begin
    if(cs_n) begin
        shift_register <= 8'b0;
        loaded <= 1'b0;
    end
    else begin
        // Load each read byte once per frame, then shift it out MSB-first.
        if(tx_load_en && !loaded) begin
            shift_register <= data;
            loaded <= 1'b1;
        end
        else if(bit_count <= 5'd16) begin
            shift_register <= {shift_register[6:0], 1'b0};
        end
    end
end

// The MSB is driven continuously; shifting advances the next bit into position.
assign miso = shift_register[7];
endmodule
