module tx_shift_register (
    input wire sclk,
    input wire [4:0] bit_count,
    input wire cs_n,
    input wire [7:0] data,
    input wire tx_load_en,
    output wire miso
);

reg [7:0] shift_register;
reg loaded;

always @(negedge sclk or posedge cs_n) begin
    if(cs_n) begin
        shift_register <= 8'b0;
      	loaded <= 1'b0;
    end
    else begin
        if(tx_load_en && !loaded) begin
            shift_register <= data;
            loaded <= 1'b1;
        end
      	else if(!(bit_count == 4'd16)) begin
            shift_register <= {shift_register[6:0], 1'b0};
        end
    end
end
assign miso = shift_register[7];
endmodule

