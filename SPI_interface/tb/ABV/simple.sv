`timescale 1ns/1ps

module tb_spi_bench1;
    logic sclk = 0;
    logic cs_n = 1;
    logic mosi = 0;
    logic [7:0] w_data = 8'hA5;

    wire miso;
    wire reg_write_en;
    wire [6:0] o_addr;

    spi_interface dut (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .w_data(w_data),
        .miso(miso),
        .reg_write_en(reg_write_en),
        .o_addr(o_addr)
    );

    always #5 sclk = ~sclk;

    // SPI Helper tasks 
    task automatic start_frame();
        @(negedge sclk);
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
        stop_frame();
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

    // Simple assertion
    property p_no_write_when_cs_high;
        @(posedge sclk) cs_n |-> !reg_write_en;
    endproperty
    assert property (p_no_write_when_cs_high)
        else $error("reg_write_en high while cs_n is high");

    property p_cmd_valid_boundary;
        @(posedge sclk) disable iff (cs_n)
            dut.cmd_valid |-> (dut.bit_count == 5'd8);
    endproperty
    assert property (p_cmd_valid_boundary)
        else $error("cmd_valid asserted at wrong bit_count");
    
    property p_no_overlap;
        @(posedge sclk)
            !(reg_write_en && dut.tx_load_en);
    endproperty
    assert property (p_no_overlap)
        else $error("reg_write_en and tx_load_en asserted together");
    

    
    initial begin
      	$dumpfile("tb_spi_bench1.vcd");
      	$dumpvars(0, tb_spi_bench1);
        repeat (3) @(posedge sclk);

        // TEST 1: Write command to address 3
        $display("\nTEST 1: Write to addr 3, data 0x5A");
        spi_write(7'h03, 8'h5A);

        repeat (2) @(posedge sclk);

        assert (o_addr == 7'h03)
            else $error("Address check failed after write: expected 3. hot %0d", o_addr);

        $finish;
    end
endmodule
