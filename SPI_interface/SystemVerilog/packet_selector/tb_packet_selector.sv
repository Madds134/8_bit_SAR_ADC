module tb_packet_selector;
    logic [3:0] req;
    logic [7:0] data_in;
    logic [1:0] grant;
    logic valid;
    logic [31:0] packet_out;

    packet_selector dut (
        .req(req),
        .data_in(data_in),
        .grant(grant),
        .valid(valid),
        .packet_out(packet_out)
    );

    initial begin
        $display("Time | Req | Grant | valid | Packet");
        $monitor("%4t | %b | %0d | %b | %h", $time, req, grant, valid, packet_out);

        req = 4'b0000; data_in = 8'h00; #10;
        req = 4'b0001; data_in = 8'h11; #10;
        req = 4'b0010; data_in = 8'h22; #10;
        req = 4'b0100; data_in = 8'h33; #10;
        req = 4'b1000; data_in = 8'h44; #10;
        req = 4'b1010; data_in = 8'h55; #10;
        $finish;
    end
endmodule
