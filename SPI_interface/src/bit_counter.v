// Module: bit_counter
// Project: 8-bit SAR ADC for TinyTapeout
// Function: Tracks SPI clock cycles to enforce 10 bit frame boundaries.
//           Provides a freeze outut signal to prevent data wrap around/over clocking.

module bit_counter (
    input wire sclk, // SPI clock
    input wire cs_n, // Active low chip select
    output reg freeze // Control signal for other blocks when count 10 bits
);

// Internal 4-bit counter to track bits 0 through 10
reg [3:0] bit_count;

// Sequential logic for bit tracking
// cs_n is used as asynchronous reset to ensure immediate readiness upon frame initation.
always @(negedge sclk or posedge cs_n) begin
    if (cs_n) begin // Reset
        bit_count <= 4'b0;
        freeze <= 1'b0;
    end
    else if (bit_count >= 10) begin // 10 bits have been shifted
        freeze <= 1'b1;
    end
    else begin
        bit_count <= bit_count + 1'b1;
        freeze <= 1'b0;
    end
end
endmodule
    


