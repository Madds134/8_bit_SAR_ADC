`timescale 1ns/1ps

module tb_spi_bench1;
    logic sclk = 0;
    logic cs_n = 1;
    logic mosi = 0;
    logic [7:0] w_data;

    wire miso;
    wire reg_write_en;
    wire [6:0] o_addr;

    // Monitor outputs
    logic       mon_txn_valid;
    logic       mon_frame_done;
    logic       mon_aborted;
    logic       mon_rw;
    logic [6:0] mon_addr;
    logic [7:0] mon_cmd_byte;
    logic [7:0] mon_data_byte;
    logic [7:0] mon_readback_byte;

    // TB-side register model matching your register_file defaults
    logic [7:0] tb_rf [0:7];
    logic [7:0] tb_pga_ctrl;
    logic [7:0] tb_adc_cfg;

    localparam logic [6:0] ADC_CFG_ADDR    = 7'h00;
    localparam logic [6:0] ADC_RESULT_ADDR = 7'h01;
    localparam logic [6:0] STATUS_ADDR     = 7'h02;
    localparam logic [6:0] PGA_CTRL_ADDR   = 7'h03;

    function automatic bit supported_addr(input logic [6:0] a);
        case (a)
            ADC_CFG_ADDR,
            ADC_RESULT_ADDR,
            STATUS_ADDR,
            PGA_CTRL_ADDR: supported_addr = 1'b1;
            default:       supported_addr = 1'b0;
        endcase
    endfunction

    // Feed DUT read data from TB backing model
    assign w_data = (o_addr < 7'd8) ? tb_rf[o_addr[2:0]] : 8'h00;

    spi_interface dut (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .w_data(w_data),
        .miso(miso),
        .reg_write_en(reg_write_en),
        .o_addr(o_addr)
    );

    spi_assertions u_assertions (
        .sclk(sclk),
        .cs_n(cs_n),
        .reg_write_en(reg_write_en),
        .tx_load_en(dut.tx_load_en),
        .cmd_valid(dut.cmd_valid),
        .bit_count(dut.bit_count)
    );

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

    spi_scoreboard u_scoreboard (
        .txn_valid(mon_txn_valid),
        .aborted(mon_aborted),
        .rw(mon_rw),
        .addr(mon_addr),
        .data_byte(mon_data_byte),
        .readback_byte(mon_readback_byte)
    );

    spi_coverage u_coverage (
        .sclk(sclk),
        .cs_n(cs_n),
        .txn_valid(mon_txn_valid),
        .aborted(mon_aborted),
        .rw(mon_rw),
        .addr(mon_addr),
        .data_byte(mon_data_byte)
    );

    always #5 sclk = ~sclk;

    initial begin
        integer i;
        for (i = 0; i < 8; i++) begin
            tb_rf[i] = 8'h00;
        end

        // Match your register file defaults
        tb_rf[ADC_CFG_ADDR]    = 8'h00;
        tb_rf[ADC_RESULT_ADDR] = 8'h55;
        tb_rf[STATUS_ADDR]     = 8'h00;
        tb_rf[PGA_CTRL_ADDR]   = 8'h00;

        tb_pga_ctrl = 8'h00;
        tb_adc_cfg  = 8'h00;
    end

    // Update TB model from observed write transactions
    always @(posedge mon_txn_valid) begin
        if (!mon_aborted && !mon_rw && supported_addr(mon_addr)) begin
            tb_rf[mon_addr[2:0]] <= mon_data_byte;
        end
    end

    // Mimic your active-register update on end-of-frame
    always @(posedge cs_n) begin
        tb_pga_ctrl <= tb_rf[PGA_CTRL_ADDR];
        tb_adc_cfg  <= tb_rf[ADC_CFG_ADDR];
    end

    // SPI helper tasks
    task automatic start_frame;
        @(negedge sclk);
        cs_n <= 1'b0;
    endtask

    task automatic stop_frame;
        @(negedge sclk);
        cs_n <= 1'b1;
        mosi <= 1'b0;
    endtask

    task automatic send_byte(input logic [7:0] data);
        for (int i = 7; i >= 0; i--) begin
            @(negedge sclk);
            mosi <= data[i];
            @(posedge sclk);
        end
    endtask

    task automatic send_byte_capture_miso(
        input  logic [7:0] tx_byte,
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
        input  logic [6:0] addr,
        output logic [7:0] data_out
    );
        start_frame();
        send_byte({1'b1, addr});
        send_byte_capture_miso(8'h00, data_out);
        stop_frame();
    endtask

    initial begin
        logic [7:0] rd_data;

        $dumpfile("tb_spi_bench1.vcd");
        $dumpvars(0, tb_spi_bench1);

        repeat (3) @(posedge sclk);

        // Read reset/default values
        $display("\nTEST 1: Read default adc_cfg");
        spi_read(ADC_CFG_ADDR, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 8'h00)
            else $error("Expected adc_cfg default 0x00, got 0x%02h", rd_data);

        $display("\nTEST 2: Read default adc_result");
        spi_read(ADC_RESULT_ADDR, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 8'h55)
            else $error("Expected adc_result default 0x55, got 0x%02h", rd_data);

        // Write/read adc_cfg
        $display("\nTEST 3: Write adc_cfg = 0xA3");
        spi_write(ADC_CFG_ADDR, 8'hA3);
        repeat (2) @(posedge sclk);

        $display("\nTEST 4: Read back adc_cfg");
        spi_read(ADC_CFG_ADDR, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 8'hA3)
            else $error("Expected adc_cfg readback 0xA3, got 0x%02h", rd_data);

        // Write/read pga_ctrl
        $display("\nTEST 5: Write pga_ctrl = 0x5A");
        spi_write(PGA_CTRL_ADDR, 8'h5A);
        repeat (2) @(posedge sclk);

        $display("\nTEST 6: Read back pga_ctrl");
        spi_read(PGA_CTRL_ADDR, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 8'h5A)
            else $error("Expected pga_ctrl readback 0x5A, got 0x%02h", rd_data);

        // Data pattern coverage
        $display("\nTEST 7: Write 0x00 to status");
        spi_write(STATUS_ADDR, 8'h00);

        $display("\nTEST 8: Write 0xFF to adc_result");
        spi_write(ADC_RESULT_ADDR, 8'hFF);

        $display("\nTEST 9: Write 0xAA to adc_cfg");
        spi_write(ADC_CFG_ADDR, 8'hAA);

        $display("\nTEST 10: Write 0x55 to pga_ctrl");
        spi_write(PGA_CTRL_ADDR, 8'h55);

        // Back-to-back write then read same address
        $display("\nTEST 11: Back-to-back write/read same address");
        spi_write(PGA_CTRL_ADDR, 8'h3C);
        spi_read(PGA_CTRL_ADDR, rd_data);
        repeat (2) @(posedge sclk);
        assert (rd_data == 8'h3C)
            else $error("Expected pga_ctrl readback 0x3C, got 0x%02h", rd_data);

        // Unsupported address
        $display("\nTEST 12: Unsupported address write");
        spi_write(7'h10, 8'h99);
        repeat (2) @(posedge sclk);

        // Abort case
        $display("\nTEST 13: Abort after command byte");
        start_frame();
        send_byte({1'b0, ADC_CFG_ADDR});
        stop_frame();
        repeat (2) @(posedge sclk);

        $finish;
    end

endmodule