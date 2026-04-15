`timescale 1ns/1ps

module tb_spi_bench1;
    logic sclk = 0;
    logic cs_n = 1;
    logic mosi = 0;
    logic [7:0] w_data = 8'hA5;

    wire miso;
    wire reg_write_en;
    wire [6:0] o_addr;

    // Monitor outputs
    logic mon_frame_done;
    logic mon_aborted;
    logic mon_rw;
    logic [6:0] mon_addr;
    logic [7:0] mon_cmd_byte;
    logic [7:0] mon_data_byte;
    logic [7:0] mon_readback_byte;

    spi_interface dut (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .w_data(w_data),
        .miso(miso),
        .reg_write_en(reg_write_en),
        .o_addr(o_addr)
    );

    // Seperate assertion module
    spi_assertions u_assertions (
        .sclk(sclk),
        .cs_n(cs_n),
        .reg_write_en(reg_write_en),
        .tx_load_en(dut.tx_load_en),
        .cmd_valid(dut.cmd_valid),
        .bit_count(dut.bit_count)
    );

    // Passive monitor
    spi_monitor u_monitor (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .frame_done(mon_frame_done),
        .aborted(mon_aborted),
        .rw(mon_rw),
        .addr(mon_addr),
        .cmd_byte(mon_cmd_byte),
        .data_byte(mon_data_byte),
        .readback_byte(mon_readback_byte)
    );

    always #5 sclk = ~sclk;

    task automatic start_frame();
      @(posedge sclk);
        cs_n <= 1'b0;
    endtask

    
    task automatic stop_frame();
        @(negedge sclk);
        cs_n  <= 1'b1;
        mosi  <= 1'b0;
    endtask


    task automatic send_byte(input logic [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(negedge sclk);
            mosi <= data[i];
            @(posedge sclk);
        end
    endtask

    task automatic send_byte_capture_miso(
        input logic [7:0] tx_byte,
        output logic [7:0] rx_byte
    );
        for (int i = 7; i >= 0; i--) begin
            @(negedge sclk);
            mosi <= tx_byte[i];
            @(posedge sclk);
            rx_byte[i] = miso;
        end
    endtask

    task automatic spi_write(
        input logic [6:0] addr,
        input logic [7:0] data
    );
        start_frame();
        send_byte({1'b0, addr});
        send_byte(data);
    endtask

    task automatic spi_read(
        input logic [6:0] addr,
        output logic [7:0] data_out
    );
        start_frame();
        send_byte({1'b1, addr});
        send_byte_capture_miso(8'h00, data_out);
        stop_frame();
    endtask

    initial begin
        $dumpfile("tb_spi_bench1.vcd");
        $dumpvars(0, tb_spi_bench1);

        repeat (3) @(posedge sclk);

        // Test 1: Write command to address 3
        $display("\nTest 11: Write to addr 3, data 0x5A");
        spi_write(7'h03, 8'h5A);

        repeat (2) @(posedge sclk);

         assert (o_addr == 7'h03)
            else $error("Address check failed after write: expected 3, got %0d", o_addr);
        
        // Monitor-based checks
        // assert (mon_frame_done)
        //     else $error("Monitor did not report frame_done");

        assert (!mon_aborted)
            else $error("Monitor incorrectly marked write frame as aborted");

        assert (mon_cmd_byte == 8'h03)
            else $error("Monitor cmd byte wrong: expected 0x03, got 0x%02h", mon_cmd_byte);

        assert (mon_rw == 1'b0)
            else $error("Monitor decoded wrong R/W bit for write");

        assert (mon_addr == 7'h03)
            else $error("Monitor addr wrong: expected 0x03, got 0x%02h", mon_addr);

        assert (mon_data_byte == 8'h5A)
            else $error("Monitor data byte wrong: expected 0x5A, got 0x%02h", mon_data_byte);

        $finish;
    end
endmodule