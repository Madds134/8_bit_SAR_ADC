module tb;
    logic [3:0] in;
    logic [1:0] out;
    logic valid;

    pri_enc dut (.in(in), .out(out), .valid(valid));

    initial begin
        in = 4'b0000; #10;
        $display("%0t\t%b\t%b\t%b", $time, in, out, valid);
        in = 4'b0001; #10;
        $display("%0t\t%b\t%b\t%b", $time, in, out, valid);
        in = 4'b0010; #10;
        $display("%0t\t%b\t%b\t%b", $time, in, out, valid);
        in = 4'b0100; #10;
        $display("%0t\t%b\t%b\t%b", $time, in, out, valid);
        i = 4'b1010; #10;
        $display("%0t\t%b\t%b\t%b", $time, in, out, valid);
        $finish;
    end
endmodule