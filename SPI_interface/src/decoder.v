module decoder (
    input wire sclk,
    input wire cs_n,
    input wire cmd_done,
    input wire [7:0] in_data,
    output reg read_write,
    output reg [6:0] addr
);

    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            read_write <= 1'b0;
            addr <= 7'h00;
        end
        else if(cmd_done) begin
            read_write <= in_data[7];
            addr <= in_data[6:0];
        end
        else begin
            read_write <= 1'b0;
            addr <= 7'h00;
        end
    end
endmodule


    


