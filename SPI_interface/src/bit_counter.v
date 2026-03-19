// Module: bit_counter
// Project: 8-bit SAR ADC for TinyTapeout
// Function: Tracks SPI clock cycles to enforce 10 bit frame boundaries.
//           Provides a freeze outut signal to prevent data wrap around/over clocking.

module bit_counter (
    input wire sclk, // SPI clock
    input wire cs_n, // Active low chip select
    output reg cmd_done, // Pulse at 8 bits
    output reg frame_done // Pulse at 16 bits
);

// Internal 4-bit counter to track bits 0 through 10
reg [4:0] bit_count;

// Sequential logic for bit tracking
// cs_n is used as asynchronous reset to ensure immediate readiness upon frame initation.
always @(posedge sclk or posedge cs_n) begin
    if (cs_n) begin // Reset
        bit_count <= 5'b0;
        cmd_done <= 1'b0;
        frame_done <= 1'b0;
    end
    else begin
        cmd_done <= 1'b0;

        if(bit_count < 5'd16) begin
            bit_count <= bit_count + 5'd1;
            if(bit_count == 5'd7) begin
                cmd_done <= 1'b1;
            end
            if(bit_count == 5'd15) begin // Latch bit counter if > 15
                frame_done <= 1'b1;
            end
        end
    end
end
endmodule
    


