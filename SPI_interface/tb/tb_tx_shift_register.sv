// DEPRECATED
`timescale 1ns/1ps
module tb_tx_shift_register;
    logic sclk;
    logic cs_n;
    logic freeze;
    logic [7:0] data;
    logic tx_load_en;
    logic miso;
    logic cmd_done;
    logic frame_done;

    // Instantiate the DUT
    tx_shift_regiser dut (
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze),
        .data(data),
        .tx_load_en(tx_load_en),
        .miso(miso)
    );

    // Instantiate the bit counter
    bit_counter counter (
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done)
    );

    always #50 sclk = ~sclk;

    initial begin
        // Start in idle
        cs_n = 1;
        tx_load_en = 0;
        #20;
        $dumpfile("tx_shift_register.vcd");
        $dumpvars(0, dut);
        $display("Starting Verification");
        cs_n = 0;
        #20;
        $finish;
    end
endmodule