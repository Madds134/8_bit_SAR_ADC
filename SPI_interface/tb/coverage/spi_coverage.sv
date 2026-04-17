module spi_coverage (
    input logic sclk,
    input logic cs_n,
    input logic txn_valid,
    input logic aborted,
    input logic rw,
    input logic [6:0] addr,
    input logic [7:0] data_byte
);

    localparam logic [6:0] ADC_CFG_ADDR = 7'h00;
    localparam logic [6:0] ADC_RESULT_ADDR = 7'h01;
    localparam logic [6:0] STATUS_ADDR = 7'h02;
    localparam logic [6:0] PGA_CTRL_ADDR = 7'h03;

    bit prev_valid;
    bit prev_rw;
    bit prev_aborted;
    bit [6:0] prev_addr;

    integer idle_cycles;
    bit cur_back_to_back;
    bit cur_wr_then_rd_same_addr;
    bit cur_supported;

    function automatic bit supported_addr(input logic [6:0] a);
        case (a)
            ADC_CFG_ADDR,
            ADC_RESULT_ADDR,
            STATUS_ADDR,
            PGA_CTRL_ADDR: supported_addr = 1'b1;
            default: supported_addr = 1'b0;
        endcase
    endfunction

    covergroup spi_cg with function sample(
        bit aborted_s,
        bit rw_s,
        bit [6:0] addr_s,
        bit [7:0] data_s,
        bit back_to_back_s,
        bit wr_then_rd_same_addr_s,
        bit supported_s
    );

    cp_abort: coverpoint aborted_s {
        bins complete = {0};
        bins abort = {1};
    }

    cp_rw: coverpoint rw_s iff (!aborted_s){
        bins write = {0};
        bins read = {1};
    }

    cp_addr: coverpoint addr_s iff (!aborted_s) {
        bins adc_cfg = {ADC_CFG_ADDR};
        bins adc_result = {ADC_RESULT_ADDR};
        bins status = {STATUS_ADDR};
        bins pga_ctrl = {PGA_CTRL_ADDR};
        bins unsupported = default;
    }

    cp_supported: coverpoint supported_s iff (!aborted_s) {
        bins supported = {1};
        bins unsupported = {0};
    }

    cp_data_patters: coverpoint data_s iff (!aborted_s && !rw_s) {
        bins zero = {8'h00};
        bins all_ones = {8'h11};
        bins all_aa = {8'hAA};
        bins all_55 = {8'h55};
        bins other = default;
    }

    cp_back_to_back: coverpoint back_to_back_s {
        bins no = {0};
        bins yes = {1};
    }

    cp_wr_then_rd_same: coverpoint wr_then_rd_same_addr_s {
        bins no = {0};
        bins yes = {1};
    }

    rw_x_addr: cross cp_rw, cp_addr;
    rw_x_supported: cross cp_rw, cp_supported;
    endgroup

    spi_cg cg = new();

    inital begin
        prev_valid = 0;
        prev_rw = 0;
        prev_aborted = 0;
        prev_addr = 0;
        idle_cycles = 0;
        cur_back_to_back = 0;
        cur_wr_then_rd_same_addr = 0;
        cur_supported = 0;
    end

    always @(posedge sclk) begin
        if(cs_n)
            idle_cycles <= idle_cycles + 1;
    end

    always @(negedge cs_n) begin
        cur_back_to_back <= prev_valid && (idle_cycles <= 1);
        idle_cycles <= 0;
    end

    always @(posedge txn_valid) begin
        cur_supported = supported_addr(addr);

        cur_wr_then_rd_same_addr =
            prev_valid &&
            !prev_aborted &&
            !aborted &&
            !prev_rw &&
            rw &&
            (prev_addr == addr);

        cg.sample(
            aborted,
            rw,
            addr,
            data_byte,
            cur_back_to_back,
            cur_wr_then_rd_same_addr,
            cur_supported
        );

        prev_valid <= 1'b1;
        prev_ew <= rw;
        prev_aborted <= aborted;
        prev_addr <= addr;
    end

    final begin
        $display("\n[COV] Functional Coverage = 0.2f%%", cg.get_inst_coverage());
    end
endmodule  

// SPI and consecutive frames