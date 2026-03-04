module tb_half_adder begin
    logic a, b;
    logic sum, cout;

    // Initialize DUT
    half_adder dut (
        .a(a),
        .b(b),
        .sum(sum),
        .cout(cout)
    );

    // Run each test case
    inital begin
        $dumpfile("half_adder.vcd");
        $dumpvars(0, dut);

        a=0; b=0; #10;
        a=0; b=1; #10;
        a=1; b=0; #10;
        a=1; b=1; #10;

        $finish;
    end
endmodule
