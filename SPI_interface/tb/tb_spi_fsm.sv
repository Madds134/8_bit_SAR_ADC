`timescale 1ns/1ps

module tb_spi_fsm;
    logic sclk;
    logic cs_n;
    logic mosi;
    logic [6:0] addr;
    logic reg_write_en;
    logic tx_load_en;
    logic [15:0] pattern;

    spi_fsm dut(
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .addr(addr),
        .reg_write_en(reg_write_en),
        .tx_load_en(tx_load_en)
    );

    always #20 sclk = ~sclk;

    initial begin
        $dumpfile("spi_fsm.vcd");
        $dumpvars(0, dut);

        sclk = 0;
        cs_n = 1;
        mosi = 0;
        pattern = 16'hFFFF;

        #10;
        @(negedge sclk);
        mosi = pattern[15];
        cs_n = 0;

      for (int i = 14; i >= 0; i--) begin
            @(negedge sclk);
            mosi = pattern[i];
        end

        @(negedge sclk);
        cs_n = 1;
        mosi = 0;

        #200;
        $finish;
    end
endmodule