module rx_shift_register (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    input reg [4:0] bit_count,
    output reg [7:0] rx_data,
    output wire cmd_valid
);
    reg [7:0] shift_register;

  always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            shift_register <= 8'd0;
            rx_data <= 8'd0;
        end
        else begin
            if(!bit_count == 4'd15) begin
                shift_register <= {shift_register[6:0], mosi};
            end
          if(bit_count == 4'd7 || bit_count == 4'd15) begin
                rx_data <= {shift_register[6:0], mosi};
            end
        end
    end
  assign cmd_valid = (bit_count == 4'd8);
endmodule