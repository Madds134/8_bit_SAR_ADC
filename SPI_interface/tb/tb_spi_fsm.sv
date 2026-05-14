// DEPRECATED
`timescale 1ns/1ps

module tb_spi_fsm;
    logic sclk;
    logic cs_n;
    logic mosi;
    logic [6:0] addr;
    logic reg_write_en;
    logic tx_load_en;
    logic [15:0] pattern;
  	logic [7:0] w_data;
  	logic miso;
  	logic [4:0] bit_count;
  	logic [7:0] rx_data;
  	logic cmd_valid;
    logic [7:0] pga_ctrl;
    logic [7:0] adc_cfg;
  	logic [6:0] rf_addr;
  	
  	// Instantiate the rx_shift_register
    rx_shift_register r_reg(
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .bit_count(bit_count),
      	.rx_data(rx_data),
      	.cmd_valid(cmd_valid)
    );
  	
     // Instantiate the bit_counter
    bit_counter count(
        .sclk(sclk),
        .cs_n(cs_n),
        .bit_count(bit_count)
    );

    spi_fsm dut(
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
      	.rx_data(rx_data),
      	.bit_count(bit_count),
        .addr(addr),
      	.cmd_valid(cmd_valid),
        .reg_write_en(reg_write_en),
      	.tx_load_en(tx_load_en),
      	.rf_addr(rf_addr)
      
    );
  
  	tx_shift_register sr (
        .sclk(sclk),
        .cs_n(cs_n),
      	.bit_count(dut.bit_count),
      	.data(w_data),
        .tx_load_en(tx_load_en),
        .miso(miso)
    );

    register_file rf (
        .sclk(sclk),
        .cs_n(cs_n),
        .reg_write_en(reg_write_en),
        .w_data(rx_data),
      	.addr(rf_addr),
        .r_data(w_data),
        .pga_ctrl(pga_ctrl),
        .adc_cfg(adc_cfg)
    );
  	

    always #20 sclk = ~sclk;

    initial begin
        $dumpfile("spi_fsm.vcd");
        $dumpvars(0, dut);
      	$dumpvars(0, sr);
      	$dumpvars(0, rf);

        sclk = 0;
        cs_n = 1;
        mosi = 0;
        pattern = 16'h81FF;
//       	w_data = 8'h55;

        #10;
        @(negedge sclk);
        mosi = pattern[15];
        cs_n = 0;

      for (int i = 14; i >= 0; i--) begin
            @(negedge sclk);
            mosi = pattern[i];
        end

        @(negedge sclk);
      	#80;
        cs_n = 1;
        mosi = 0;

        #200;
        $finish;
    end
endmodule