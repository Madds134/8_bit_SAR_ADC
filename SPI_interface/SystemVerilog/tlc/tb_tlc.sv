module tb;
    logic clk;
    logic rst;
    logic red;
    logic yellow;
    logic green;

    traffic_light dut (
        .clk(clk),
        .rst(rst),
        .red(red),
        .yellow(yellow),
        .green(green)
    );
    always #5 clk=~clk;
    initial begin
        $dumpfile("fsm_waveform.vcd");
        $dumpvars(0, dut);
        clk = 0;
        rst = 0;
        // Apply reset properly
        #2;
        rst = 1; // valid posedge set
        #15; // hold across clock edge
        rst = 0;

        #100;
        $finish;
    end
    initial begin
        $monitor("Time =%0t | rst =%b | red=%b | yellow=%b | green = %b",
        $time,rst,red,yellow,green);
    end
endmodule
