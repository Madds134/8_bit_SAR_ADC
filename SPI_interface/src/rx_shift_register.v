module rx_shift_register (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    input wire freeze,
    input wire cmd_done,
    input wire frame_done,
    output reg [7:0] rx_data,
    output wire cmd_valid
);
    reg [7:0] shift_register;
    reg cmd_done_d;

    always @(posedge sclk or psoedge cs_n) begin
        if(cs_n) begin
            shift_register <= 8'd0;
            rx_data <= 8'd0;
            cmd_done_d <= 1'b0;
        end
        else begin
            cmd_done_d <= cmd_done;

            if(!freeze) begin
                shift_register <= {shift_register[6:0], mosi};
            end
            if(cmd_done || frame_done) begin
                rx_data <= {shift_register[6:0], mosi};
            end
        end
    end
    assign cmd_valid = cmd_done_d;
endmodule