module tb_8_1_mux;
    logic [7:0] d;
    logic [2:0] sel;
    logic y;

    // Initalize the DUT
    mux8_1 dut ( .d(d), .sel(sel), .y(y));

    initial begin
        $dumpfile("mux8_1.vcd");
        $dumpvars(0, dut);
        d = 8'b1010_1101;
        sel = 3'b000; #10;
        sel = 3'b001; #10;
        sel = 3'b010; #10;
        sel = 3'b011; #10;
        sel = 3'b100; #10;
        sel = 3'b101; #10;
        sel = 3'b110; #10;
        sel = 3'b111; #10;
        $finish;
    end
endmodule