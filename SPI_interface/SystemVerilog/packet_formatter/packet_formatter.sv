module packet_formatter (
    input [7:0] byte0,
    input [7:0] byte1,
    input [7:0] byte2,
    input [7:0] byte3,
    output reg [19:0] packet_out
);
    reg [3:0] nib0, nib1, nib2, nib3;
    reg [3:0] checksum;
    
    always @(*) begin
        // Extract nibbles
        nib0 = byte0[3:0];
        nib1 = byte1[3:0];
        nib2 = byte2[3:0];
        nib3 = byte3[3:0];
        checksum = nib0 ^ nib1 ^ nib2 ^ nib3;
        packet_out = {nib0, nib1, nib2, nib3, checksum};
    end
endmodule