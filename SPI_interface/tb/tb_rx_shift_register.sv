// DEPRECATED
`timescale 1ns/1ps
module tb_rx_shift_register;
    logic sclk, cs_n, mosi;
    logic freeze, cmd_done, frame_done;
    logic [7:0] data;
  	logic [15:0] pattern;

    bit_counter u_count (
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done)
    );

    rx_shift_register dut (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done),
        .data(data)
    );

    always #50 sclk = ~sclk;

    integer i;
    initial begin
        sclk = 1'b0;
        cs_n = 1'b1;
        mosi = 1'b0;

        $dumpfile("rx_shift_register.vcd");
        $dumpvars(0, tb_rx_shift_register);

        #100;
        cs_n = 1'b0;
        pattern = 16'h6655;

        // Drive MOSI stable BEFORE the posedge where DUT samples
      for (i = 15; i >= 0; i = i - 1) begin
            mosi = pattern[i];
            @(posedge sclk);   // match DUT sampling edge
        end

        // keep clocking a bit so frame_done can happen if desired
        repeat (20) @(posedge sclk);

        cs_n = 1'b1;
        #100;
        $finish;
    end
endmodule