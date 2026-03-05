module tb;
    logic clk;
    logic rst;
    logic start;
    logic done;

    entype dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done)
    );
    always #5 clk=~clk;
    initial begin
        rst = 1;
        clk = 1;
        start = 0;
        #5;
        rst = 0;
        start = 1;
        #25;
        start = 0;
        #10;
        start = 1;
        #30
        $finish;
    end
    initial begin
        $monitor("Time =%0t | rst=%b | start=%b | done=%b",
        $time, rst, start, done);
    end
endmodule

