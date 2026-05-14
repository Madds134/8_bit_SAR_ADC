`timescale 1ns/1ps
module tb_tsb;
    logic sdo_data_in;
    logic cs_n;
    logic sdo_data_out;
    logic oe;
    logic [7:0] pattern;
    logic sclk;

    tri_state_buffer dut (
        .sdo_data_in(sdo_data_in),
        .cs_n(cs_n),
        .sdo_data_out(sdo_data_out),
        .oe(oe)
    );

    // Clock only
    always #50 sclk = ~sclk;

    initial begin
        // init signals
        sclk        = 1'b0;
        sdo_data_in = 1'b0;
        cs_n        = 1'b1;

        $dumpfile("tri_state_buffer.vcd");
        $dumpvars(0, tb_tsb);

        #20;
        $display("cs_n is driven low, claiming the bus");
        cs_n = 1'b1;

        pattern = 8'h66;

        for (integer i = 7; i >= 0; i = i - 1) begin
            sdo_data_in = pattern[i];
            @(negedge sclk);
        end

        #20;
        $finish;
    end
endmodule