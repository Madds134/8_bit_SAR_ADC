`timescale 1ns/1ps
module tb_spi_controller;
    logic sclk;
    logic cs_n;
    logic freeze;
    logic cmd_done;
    logic frame_done;
    logic [7:0] in_data;
    logic read_write;
    logic [6:0] addr;
    logic tx_load_en;
    logic reg_write_en;


    // Instaniate the Bit counter
    bit_counter counter (
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done)
    );
    
    // Instantiate the decoder
    decoder command_decoder (
        .sclk(sclk),
        .cs_n(cs_n),
        .cmd_done(cmd_done),
        .in_data(in_data),
        .read_write(read_write),
        .addr(addr)
    );

    // Instantiate the spi_controller
    spi_controller dut (
        .cs_n(cs_n),
        .read_write(read_write),
        .cmd_done(cmd_done),
        .frame_done(frame_done),
        .tx_load_en(tx_load_en),
        .reg_write_en(reg_write_en)
    );

    always #50 sclk = ~sclk;

    initial begin
        // Start in idle
        cs_n = 1;
        sclk = 0;
        $dumpfile("spi_controller.vcd");
        $dumpvars(0, counter);
        $display("Starting frame");
        #20;
      	cs_n = 0;
        in_data = 8'hFF;
      	#20;
        repeat (20) begin
          @(negedge sclk);
        end
        #100;
        cs_n = 1;
        #20;
        $finish;
    end
endmodule