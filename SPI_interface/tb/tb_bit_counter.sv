`timescale 1ns/1ps
module tb_bit_counter;
    logic sclk;
    logic cs_n;
    logic freeze;

    bit_counter dut (
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze)
    );

    // Clock generation: 10 MHz if timescale is 1ns (period = 100 ns)
    always #50 sclk = ~sclk;

    initial begin
        sclk = 1'b0;
        cs_n = 1'b1; // Start in IDLE

        $dumpfile("bit_counter.vcd");
        $dumpvars(0, tb_bit_counter);

        $display("Starting Bit Counter Verification");
        #100;

        // Standard frame: drop CS and clock
        cs_n = 1'b0;
        $display("cs_n dropped. Sending 12 clock pulses to test freeze logic");

        // Send 12 clock pulses (counting edges depends on your DUT design)
        repeat (12) begin
            @(negedge sclk);
        end

        #20;
        if (freeze == 1'b1)
            $display("SUCCESS: Freeze asserted after threshold");
        else
            $display("ERROR: Freeze failed to assert");

        #100;
        cs_n = 1'b1; // Pull CS_N high to reset
        #20;

        if (freeze == 1'b0)
            $display("SUCCESS: Freeze de-asserted on CS_N high");
        else
            $display("ERROR: Freeze stuck asserted after CS_N high");

        #200;
        $display("Verification Complete");
        $finish;
    end
endmodule