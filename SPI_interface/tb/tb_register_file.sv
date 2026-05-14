// DEPRECATED
`timescale 1ns/1ps
module tb_register_file;
    logic sclk;
    logic reg_write_en;
    logic cs_n;
    logic [7:0] w_data;
  	logic [6:0] addr;
    logic [7:0] r_data;
    logic [7:0] pga_cfg;
    logic [7:0] adc_cfg;

    register_file dut (
        .sclk(sclk),
        .reg_write_en(reg_write_en),
        .cs_n(cs_n),
        .w_data(w_data),
        .addr(addr),
        .r_data(r_data),
        .pga_ctrl(pga_cfg),
        .adc_cfg(adc_cfg)
    );

    always #50 sclk = ~sclk;

    initial begin
        sclk = 1'b0;
        cs_n = 1'b1;
        reg_write_en = 1'b0;
        w_data = 8'h00;
        addr = 3'd0;

        $dumpfile("register_file.vcd");
        $dumpvars(0, tb_register_file);

        $display("Starting Register File Verification");
        #100;

        // Write 0xFF to addr 2
        $display("Write 0xFF to register 2");
        cs_n = 1'b0;
        reg_write_en = 1'b1;
        w_data = 8'hFF;
        addr = 3'd2;

        // give a clock edge to write
        @(posedge sclk);
        #1;

        // stop writing
        reg_write_en = 1'b0;

        // Read back
        #10;
        if (r_data !== 8'hFF)
            $display("ERROR: readback r_data=%h expected FF", r_data);
        else
            $display("SUCCESS: readback matched: %h", r_data);

        // Raise CS to latch pga/adccfg outputs
        cs_n = 1'b1;
        #10;

        $display("pga_cfg=%h adc_cfg=%h", pga_cfg, adc_cfg);

        $display("Done");
        $finish;
    end
endmodule