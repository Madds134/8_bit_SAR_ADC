module bit_counter (
    input wire sclk, // SPI clock
    input wire cs_n, // Active low chip select
    output reg [4:0] bit_count
);


// Sequential logic for bit tracking
// cs_n is used as asynchronous reset to ensure immediate readiness upon frame initation.
always @(posedge sclk or posedge cs_n) begin
    if (cs_n) begin // Reset
        bit_count <= 5'b0;
    end
    else begin
        if(bit_count < 5'd16) begin
            bit_count <= bit_count + 5'd1;
        end
    end
end
endmodule