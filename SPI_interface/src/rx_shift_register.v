module rx_shift_register (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    input wire freeze,
    input wire cmd_done,
    input wire frame_done,
    output reg [7:0] rx_data
);
    reg [7:0] shift_register;
    
    // Increment the shift register on each clock pulse and freeze control signal not asserted
    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            shift_register <= 8'd0;
        end
        else if(!freeze) begin
            shift_register <= {shift_register[6:0], mosi};
        end
    end

    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            rx_data <= 8'd0;
        end
        else if (cmd_done) begin
            rx_data <= shift_register;
        end 
        else if (frame_done) begin
            rx_data <= shift_register;
        end
    end
endmodule



