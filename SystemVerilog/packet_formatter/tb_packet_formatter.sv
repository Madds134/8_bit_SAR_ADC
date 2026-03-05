module tb_packet_formatter;

    reg [7:0] byte0, byte1, byte2, byte 3;
    wire [19:0] packet_out;

    packet_formatter dut( .byte0(byte0), .byte1(byte1), . byte2(byte2),
    .byte3(byte3), .packet_out(packet_out));

    initial begin
        $dumpfile("packet_formatter.vcd");
        $dumpvars(0, tb_packet_formatter);
        byte0 = 8'hA3;
        byte1 = 8'h87;
        byte2 = 8'hC1;
        byte3 = 8'hD5;

        #10;
        $display("Packet Packet = %h", packet_out);
        #10;
        $finish;
    end
endmodule
