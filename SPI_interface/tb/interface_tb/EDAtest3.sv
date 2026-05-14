`timescale 1ns/1ps

module tb_spi_bench1;
    logic sclk = 0;
    logic cs_n = 1;
    logic mosi = 0;
    wire  [7:0] w_data;
    wire  [7:0] o_data;
    logic       rst = 1;

    wire miso;
    wire reg_write_en;
    wire [6:0] o_addr;

    // Monitor outputs
    logic mon_txn_valid;
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
        .o_data(o_data),
        .o_addr(o_addr)
    );

    register_file u_rf (
        .sclk        (sclk),
        .rst         (rst),
        .reg_write_en(reg_write_en),
        .cs_n        (cs_n),
        .w_data      (o_data),
        .addr        (o_addr),
        .r_data      (w_data)
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
        .txn_valid(mon_txn_valid),
        .frame_done(mon_frame_done),
        .aborted(mon_aborted),
        .rw(mon_rw),
        .addr(mon_addr),
        .cmd_byte(mon_cmd_byte),
        .data_byte(mon_data_byte),
        .readback_byte(mon_readback_byte)
    );

    // Scoreboard: compares monitor outputs against register model
    spi_scoreboard u_sb (
        .txn_valid(mon_txn_valid),
        .aborted(mon_aborted),
        .rw(mon_rw),
        .addr(mon_addr),
        .data_byte(mon_data_byte),
        .readback_byte(mon_readback_byte)
    );

    // Coverage: samples functional coverpoints on each transaction
    spi_coverage u_cov (
        .sclk(sclk),
        .cs_n(cs_n),
        .txn_valid(mon_txn_valid),
        .aborted(mon_aborted),
        .rw(mon_rw),
        .addr(mon_addr),
        .data_byte(mon_data_byte)
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

    // Bit-level helpers
    task automatic send_partial_byte (
        input logic [7:0] data,
        input int nbits
    );
        for (int i = 7; i >= (8 - nbits); i--) begin
            @(negedge sclk);
            mosi <= data[i];
            @(posedge sclk);
        end
    endtask

task automatic send_stream_bits(
    input logic [15:0] stream,
    input int nbits          // was: int unsigned
);
    for(int i = 15; i >= (16 - nbits); i--) begin
        @(negedge sclk);
        mosi <= stream[i];
        @(posedge sclk);
    end
endtask

    task automatic send_extra_zeros (
        input int unsigned bits
    );
        for (int i = 0; i < bits; i++) begin
            @(negedge sclk);
            mosi <= 1'b0;
            @(posedge sclk);
        end
    endtask

    // Random transaction task
    task automatic drive_spi_txn(input spi_txn tx);
        logic [15:0] frame_bits;

        // Apply gap with cs_n high
        repeat (tx.gap_cycles) @(posedge sclk);

        // Build 16-bit frame
        // [15:8] = command {rw, addr}
        // [7:0] = data
        frame_bits = {tx.rw, tx.addr, (tx.rw ? 8'h00 : tx.data)};

        tx.print("DRV");

        case(tx.frame_kind)
            SPI_FULL: begin
                start_frame();
                send_stream_bits(frame_bits, 16);
                stop_frame();
            end

            SPI_ABORT_MID_CMD: begin
                start_frame();
                send_stream_bits(frame_bits, tx.abort_after_bits);
                stop_frame();
            end

            SPI_ABORT_MID_DATA: begin
                start_frame();
                send_stream_bits(frame_bits, tx.abort_after_bits);
                stop_frame();
            end

            SPI_EXTRA_CLOCKS: begin
                start_frame();
                send_stream_bits(frame_bits, 16);
                send_extra_zeros(tx.extra_clocks);
                stop_frame();
            end

            default: begin
                $error("Unknown frame_kind");
            end
        endcase
    endtask

    // CRV legal runner
    task automatic run_legal_crv(input int unsigned n_txns);
        spi_legal_txn tx;

        $display("Legal Constrained Random");

        for(int i = 0; i < n_txns; i++) begin
            tx = new();

            assert (tx.randomize())
                else $fatal(1, "Failed to randomize legal transaction");
            
            drive_spi_txn(tx);

            // Let monitor / scoreboard / coverage settle
            repeat (2) @(posedge sclk);
        end
    endtask

    // Stress test runner
    task automatic run_stress_crv(input int unsigned n_txns);
        spi_stress_txn tx;

        $display("Stress Random Test");

        for(int i = 0; i < n_txns; i++) begin
            tx = new();

            assert(tx.randomize())
                else $fatal(1, "failed to randomize stress transaction");
            
            drive_spi_txn(tx);

            repeat (2) @(posedge sclk);
        end
    endtask

    initial begin
        logic [7:0] rd_data;
      	spi_legal_txn wr;   // declare at top
    spi_legal_txn rd;
        rst = 1;
        repeat (2) @(posedge sclk);
        rst = 0;

//         $dumpfile("tb_spi_bench3.vcd");
//         $dumpvars(0, tb_spi_bench1);

        repeat (3) @(posedge sclk);

        // Test 1: Write command to address 3
        $display("\nTest 1: Read default adc_result");
        spi_read(7'h01, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 7'h55)
            else $error("Expected adc_result default 0x55, got 0x%02h", rd_data);
        
        $display("\nTest 2: Write/read pga_ctrl");
        spi_write(7'h03, 8'h5A);
        repeat (2) @(posedge sclk);
        spi_read(7'h03, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 8'h5A)
            else $error("Expected pga_ctrl readback 0x5A, got 0x%02h", rd_data);

        // CRV
      run_legal_crv(500);

        // run stress tests
      run_stress_crv(500);
      
      

        repeat (5) @(posedge sclk);
        $finish;
    end
endmodule