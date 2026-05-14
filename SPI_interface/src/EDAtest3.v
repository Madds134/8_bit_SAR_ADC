// Code your design here
module spi_interface (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
  	input wire [7:0] w_data,

    output wire miso,
    output wire reg_write_en,
  	output wire [7:0] o_data,
  	output wire [6:0] o_addr
);
    reg [4:0] bit_count;
    reg [7:0] rx_data;
    wire cmd_valid;
    wire tx_load_en;

	
    // Instantiate the RX shift register
    rx_shift_register rsr (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .bit_count(bit_count),
        .rx_data(rx_data),
        .cmd_valid(cmd_valid)
    );

    // Instantiate the bit counter
    bit_counter bc (
        .sclk(sclk),
        .cs_n(cs_n),
        .bit_count(bit_count)
    );

    // Instantiate the tx shift register
    tx_shift_register tsr (
        .sclk(sclk),
        .bit_count(bit_count),
        .cs_n(cs_n),
        .data(w_data),
        .tx_load_en(tx_load_en),
        .miso(miso)
    );

    // Instantiate the FSM
    spi_fsm fsm (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .rx_data(rx_data),
        .bit_count(bit_count),
        .cmd_valid(cmd_valid),
        .rf_addr(o_addr),
        .reg_write_en(reg_write_en),
        .tx_load_en(tx_load_en)
    );
	assign o_data = rx_data;

endmodule

module spi_fsm (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
  	input wire [7:0] rx_data,
  	input wire [4:0] bit_count,
  	input wire cmd_valid,
    
    output reg reg_write_en,
    output reg tx_load_en,
  	output wire [6:0] rf_addr
);

    localparam IDLE=0, CMD=1, READ=2, WRITE=3;
    reg [2:0] next_state, state;
    reg read_write;
    reg [6:0] addr;


    always @(*) begin
        next_state = state;
        reg_write_en = 0;
        tx_load_en = 0;
        case(state) 
            IDLE: begin
                next_state = (cs_n || bit_count == 4'd15) ? IDLE : CMD;
            end
            CMD: begin
              if (cmd_valid) begin
                    if (rx_data[7]) begin
                      	tx_load_en = 1'b1;
                        next_state = READ;
                    end
                    else if (!rx_data[7]) begin
                        next_state = WRITE;    
                    end
                end
            end
            READ: begin
              if(bit_count == 5'd15) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ;
                end
            end
            WRITE: begin
              if(bit_count == 5'd16) begin
                    reg_write_en = 1;
                    next_state = IDLE;
                end
                else begin
                    next_state = WRITE;
                end
            end
            default:
            next_state = IDLE;  
        endcase
    end

    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            state <= IDLE;
            read_write <= 1'b0;
            addr <= 7'd0;
        end
        else begin
            state <= next_state;
          if(cmd_valid) begin
                read_write <= rx_data[7];
                addr <= rx_data[6:0];
            end
        end
    end
  assign rf_addr = (cmd_valid) ? rx_data[6:0] : addr;
endmodule
module rx_shift_register (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    input reg [4:0] bit_count,
    output reg [7:0] rx_data,
    output wire cmd_valid
);
    reg [7:0] shift_register;

  always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            shift_register <= 8'd0;
            rx_data <= 8'd0;
        end
        else begin
          if(bit_count != 5'd16) begin
                shift_register <= {shift_register[6:0], mosi};
            end
          if(bit_count == 5'd7 || bit_count == 5'd15) begin
                rx_data <= {shift_register[6:0], mosi};
            end
        end
    end
  assign cmd_valid = (bit_count == 5'd8);
endmodule

module tx_shift_register (
    input wire sclk,
    input wire [4:0] bit_count,
    input wire cs_n,
    input wire [7:0] data,
    input wire tx_load_en,
    output wire miso
);

reg [7:0] shift_register;
reg loaded;

always @(negedge sclk or posedge cs_n) begin
    if(cs_n) begin
        shift_register <= 8'b0;
      	loaded <= 1'b0;
    end
    else begin
        if(tx_load_en && !loaded) begin
            shift_register <= data;
            loaded <= 1'b1;
        end
      else if(bit_count <= 5'd16) begin
            shift_register <= {shift_register[6:0], 1'b0};
        end
    end
end
assign miso = shift_register[7];
endmodule

module bit_counter (
    input wire sclk, // SPI clock
    input wire cs_n, // Active low chip select
    output reg [4:0] bit_count
);


// Sequential logic for bit tracking
// cs_n is used as asynchronous reset to ensure immediate readiness upon frame initation.
always @(posedge sclk or posedge cs_n) begin
    if (cs_n) begin // Reset
        bit_count <= 5'b0;
    end
    else begin
        if(bit_count < 5'd16) begin
            bit_count <= bit_count + 5'd1;
        end
    end
end
endmodule


module spi_assertions (
    input logic sclk,
    input logic cs_n,
    input logic reg_write_en,
    input logic tx_load_en,
    input logic cmd_valid,
    input logic [4:0] bit_count
);

    // No Write enable when chip select is active
    property p_no_write_when_cs_high;
        @(posedge sclk) cs_n |-> !reg_write_en;
    endproperty

    a_no_write_when_cs_high: assert property (p_no_write_when_cs_high)
        else $error("reg_write_en high when cs_n is high");

    // cmd_valid should only happen at the command-byte boundary
    property p_cmd_valid_boundary;
        @(posedge sclk) disable iff (cs_n)
            cmd_valid |-> (bit_count == 5'd8);
    endproperty

    a_cmd_valid_boundary: assert property (p_cmd_valid_boundary)
        else $error("cmd_valid asserted at wrong bit_count");
    
    // Do not allow write and tx load at the same time
    property p_no_overlap;
        @(posedge sclk)
            !(reg_write_en && tx_load_en);
    endproperty

    a_no_overlap: assert property (p_no_overlap)
        else $error("reg_write_en and tx_load_en asserted together");
endmodule
      
module spi_monitor (
    input logic sclk,
    input logic cs_n,
    input logic mosi,
    input logic miso,

    output logic txn_valid,
    output logic frame_done,
    output logic aborted,
    output logic rw,
    output logic [6:0] addr,
    output logic [7:0] cmd_byte,
    output logic [7:0] data_byte,
    output logic [7:0] readback_byte
);

    logic in_frame;
    logic [4:0] bit_count;
    logic [7:0] cmd_shift;
    logic [7:0] data_shift;
    logic [7:0] read_shift;

    initial begin
        in_frame  = 1'b0;
        txn_valid = 1'b0;
        frame_done = 1'b0;
        aborted = 1'b0;
        rw = 1'b0;
        addr = '0;
        cmd_byte = '0;
        data_byte = '0;
        readback_byte = '0;
        bit_count = '0;
        cmd_shift = '0;
        data_shift = '0;
        read_shift = '0;
    end

    // Start of frame
    always @(negedge cs_n) begin
        in_frame  <= 1'b1;
        txn_valid <= 1'b0;
        frame_done <= 1'b0;
        aborted <= 1'b0;
        rw <= 1'b0;
        addr <= '0;
        cmd_byte <= '0;
        data_byte <= '0;
        readback_byte <= '0;
        bit_count <= '0;
        cmd_shift <= '0;
        data_shift <= '0;
        read_shift <= '0;
    end

    // Sample bus activity
    // Assuming MOSI/MISO 
    always @(posedge sclk) begin
        if (!cs_n && in_frame) begin
            if(bit_count < 5'd8) begin
                cmd_shift <= {cmd_shift[6:0], mosi};

                if(bit_count == 5'd7) begin
                    cmd_byte <= {cmd_shift[6:0], mosi};
                    rw <= {cmd_shift[6:0], mosi}[7];
                    addr <= {cmd_shift[6:0], mosi}[6:0];
                end
            end
            else if (bit_count < 5'd16) begin
                data_shift <= {data_shift[6:0], mosi};

                if(bit_count == 5'd15)
                    data_byte <= {data_shift[6:0], mosi};
                
                if (rw) begin
                    read_shift <= {read_shift[6:0], miso};

                    if(bit_count == 5'd15)
                        readback_byte <= {read_shift[6:0], miso};
                end
            end

            bit_count <= bit_count + 5'd1;
        end
    end

    // End of frame
    always @(posedge cs_n) begin
        if (in_frame) begin
            frame_done <= 1'b1;
            txn_valid  <= 1'b1;
            aborted <= (bit_count != 5'd16);
            in_frame <= 1'b0;

            if(bit_count != 5'd16) begin
                $display("[MON] ABORTED frame: bits_seen=%0d cmd=0x%02h rw=%0b addr=0x%02h data=0x%02h readback=0x%02h",
                bit_count, cmd_byte, rw, addr, data_byte, readback_byte);
            end
            else if (rw) begin
                $display("[MON] READ Frame: cmd=0x%02h addr=0x%02h readback=0x%02h",
                cmd_byte, addr, readback_byte);
            end
            else begin
                $display("[MON] WRITE Frame: cmd=0x%02h addr=0x%02h data=0x%02h",
                cmd_byte, addr, data_byte);
            end
        end
    end
endmodule

      
typedef enum int {
    SPI_FULL,
    SPI_ABORT_MID_CMD,
    SPI_ABORT_MID_DATA,
    SPI_EXTRA_CLOCKS
} spi_frame_kind_e;

class spi_txn;
    rand bit rw;
    rand bit [6:0] addr;
    rand bit [7:0] data;
    rand int unsigned gap_cycles;
    rand spi_frame_kind_e frame_kind;
    rand int unsigned abort_after_bits;
    rand int unsigned extra_clocks;

    function string kind_name();
        case (frame_kind)
            SPI_FULL: return "FULL";
            SPI_ABORT_MID_CMD: return "ABORT_MID_CMD";
            SPI_ABORT_MID_DATA: return "ABORT_MID_DATA";
            SPI_EXTRA_CLOCKS: return "EXTRA_CLOCKS";
            default: return "UNKNOWN";
        endcase
    endfunction

    function void print(string tag="TXN");
        $display("[%s] kind=%s rw=%0d addr=0x%02h data=0x%02h gap=%0d abort_bits=%0d extra_clocks=%0d",
                tag, kind_name(), rw, addr, data, gap_cycles, abort_after_bits, extra_clocks);
    endfunction
endclass

// Legal transaction class
// It allows: supported addresses, full frames, no aborts, no extra clocks
// IF/FUTURE: adc_result and status are read only, then the constraint needs to be tighened to only allow writes to 0x00 and 0x03
class spi_legal_txn extends spi_txn;

    constraint c_legal {
        addr inside {7'h00, 7'h01, 7'h02, 7'h03};
        frame_kind == SPI_FULL;
        gap_cycles inside {[1:5]};
        abort_after_bits == 0;
        extra_clocks == 0;
        rw dist {0 := 1, 1:= 1};
    }
endclass

// Stress transaction class
// It adds: unsupported addresses, short frames, aborts mid command, aborts mid data, extra clocks, back to back traffic
class spi_stress_txn extends spi_txn;
    constraint c_stress {
        rw dist {0 := 1, 1 := 1};

        // Supported plus unsupported space
        addr dist {
            [7'h00:7'h03] := 70,
            [7'h04:7'h7F] := 30
        };

        // Small gaps for back to back traffic
        gap_cycles inside {[0:2]};

        frame_kind dist {
            SPI_FULL := 40,
            SPI_ABORT_MID_CMD := 20,
            SPI_ABORT_MID_DATA := 20,
            SPI_EXTRA_CLOCKS := 20
        };

        if (frame_kind == SPI_FULL) {
            abort_after_bits == 0;
            extra_clocks == 0;
        }

        if(frame_kind == SPI_ABORT_MID_CMD) {
            abort_after_bits inside {[1:7]};
            extra_clocks == 0;
        }

        if (frame_kind == SPI_ABORT_MID_DATA) {
            abort_after_bits inside {[9:15]};
            extra_clocks == 0;
        }

        if (frame_kind == SPI_EXTRA_CLOCKS) {
            abort_after_bits == 0;
            extra_clocks inside {[1:8]};
        }
    }
endclass
          
          
          
module register_file (
    input  sclk,
    input  rst,
    input  reg_write_en,
    input  cs_n,
    input  [7:0] w_data,
    input  [6:0] addr,
    output reg [7:0] r_data,

    output reg [7:0] pga_ctrl,
    output reg [7:0] adc_cfg
);
    reg [7:0] register [0:7];

    always @(posedge cs_n or posedge rst) begin
        if (rst) begin
            register[3'h00] <= 8'h00;
            register[3'h01] <= 8'h55;
            register[3'h02] <= 8'h00;
            register[3'h03] <= 8'h00;
            pga_ctrl        <= 8'h00;
            adc_cfg         <= 8'h00;
        end else begin
            if (reg_write_en) begin
                case (addr)
                    3'h00: register[addr] <= w_data;
                    3'h01: register[addr] <= w_data;
                    3'h02: register[addr] <= w_data;
                    3'h03: register[addr] <= w_data;
                endcase
            end
            pga_ctrl <= (reg_write_en && addr == 3'h03) ? w_data : register[3'h03];
            adc_cfg  <= (reg_write_en && addr == 3'h00) ? w_data : register[3'h00];
        end
    end

    always @(*) begin
        r_data = register[addr];
    end

endmodule

module spi_scoreboard (
    input logic txn_valid,
    input logic aborted,
    input logic rw,
    input logic [6:0] addr,
    input logic [7:0] data_byte,
    input logic [7:0] readback_byte
);
    localparam logic [6:0] ADC_CFG_ADDR    = 7'h00;
    localparam logic [6:0] ADC_RESULT_ADDR = 7'h01;
    localparam logic [6:0] STATUS_ADDR     = 7'h02;
    localparam logic [6:0] PGA_CTRL_ADDR   = 7'h03;

    logic [7:0] model_rf [0:7];

    integer write_count, read_count, abort_count;
    integer pass_count, fail_count, unsupported_count;

    function automatic bit supported_addr(input logic [6:0] a);
        case(a)
            ADC_CFG_ADDR,
            ADC_RESULT_ADDR,
            STATUS_ADDR,
            PGA_CTRL_ADDR: supported_addr = 1'b1;
            default:       supported_addr = 1'b0;
        endcase
    endfunction

    initial begin
        integer i;
        for(i = 0; i < 8; i++) model_rf[i] = 8'h00;
        model_rf[ADC_RESULT_ADDR] = 8'h55;
        write_count = 0; read_count = 0; abort_count = 0;
        pass_count  = 0; fail_count = 0; unsupported_count = 0;
    end

    always @(posedge txn_valid) begin
        if (aborted) begin
            abort_count++;
            $display("[SB] Ignoring aborted transaction");
        end
        else if (!supported_addr(addr)) begin
            unsupported_count++;
            $display("[SB] Unsupported address 0x%02h observed", addr);
        end
        else if (!rw) begin
            model_rf[addr[2:0]] = data_byte;
            write_count++;
            $display("[SB] MODEL WRITE: addr=0x%02h data=0x%02h", addr, data_byte);
        end
        else begin
            read_count++;
            if (readback_byte == model_rf[addr[2:0]]) begin
                pass_count++;
                $display("[SB] READ PASS: addr=0x%02h expected=0x%02h got=0x%02h",
                         addr, model_rf[addr[2:0]], readback_byte);
            end else begin
                fail_count++;
                $error("[SB] READ FAIL: addr=0x%02h expected=0x%02h got=0x%02h",
                       addr, model_rf[addr[2:0]], readback_byte);
            end
        end
    end

    final begin
        $display("\n[SB] Summary");
        $display("[SB] Writes=%0d  Reads=%0d  Aborts=%0d  Failures=%0d  Unsupported=%0d",
                 write_count, read_count, abort_count, fail_count, unsupported_count);
    end
endmodule

module spi_coverage (
    input logic sclk,
    input logic cs_n,
    input logic txn_valid,
    input logic aborted,
    input logic rw,
    input logic [6:0] addr,
    input logic [7:0] data_byte
);
    localparam logic [6:0] ADC_CFG_ADDR    = 7'h00;
    localparam logic [6:0] ADC_RESULT_ADDR = 7'h01;
    localparam logic [6:0] STATUS_ADDR     = 7'h02;
    localparam logic [6:0] PGA_CTRL_ADDR   = 7'h03;

    bit prev_valid, prev_rw, prev_aborted;
    bit [6:0] prev_addr;
    integer idle_cycles;
    bit cur_back_to_back, cur_wr_then_rd_same_addr, cur_supported;

    function automatic bit supported_addr(input logic [6:0] a);
        case (a)
            ADC_CFG_ADDR,
            ADC_RESULT_ADDR,
            STATUS_ADDR,
            PGA_CTRL_ADDR: supported_addr = 1'b1;
            default:       supported_addr = 1'b0;
        endcase
    endfunction

    covergroup spi_cg with function sample(
        bit aborted_s, bit rw_s, bit [6:0] addr_s, bit [7:0] data_s,
        bit back_to_back_s, bit wr_then_rd_same_addr_s, bit supported_s
    );
        cp_abort: coverpoint aborted_s {
            bins complete = {0}; bins abort = {1};
        }
        cp_rw: coverpoint rw_s iff (!aborted_s) {
            bins write = {0}; bins read = {1};
        }
        cp_addr: coverpoint addr_s iff (!aborted_s) {
            bins adc_cfg     = {ADC_CFG_ADDR};
            bins adc_result  = {ADC_RESULT_ADDR};
            bins status      = {STATUS_ADDR};
            bins pga_ctrl    = {PGA_CTRL_ADDR};
            bins unsupported = default;
        }
        cp_supported: coverpoint supported_s iff (!aborted_s) {
            bins supported = {1}; bins unsupported = {0};
        }
        cp_data_patterns: coverpoint data_s iff (!aborted_s && !rw_s) {
            bins zero     = {8'h00};
            bins all_ones = {8'hFF};
            bins all_aa   = {8'hAA};
            bins all_55   = {8'h55};
            bins other    = default;
        }
        cp_back_to_back: coverpoint back_to_back_s {
            bins no = {0}; bins yes = {1};
        }
        cp_wr_then_rd_same: coverpoint wr_then_rd_same_addr_s {
            bins no = {0}; bins yes = {1};
        }
        rw_x_addr:      cross cp_rw, cp_addr;
        rw_x_supported: cross cp_rw, cp_supported;
    endgroup

    spi_cg cg = new();

    initial begin
        prev_valid = 0; prev_rw = 0; prev_aborted = 0; prev_addr = 0;
        idle_cycles = 0;
        cur_back_to_back = 0; cur_wr_then_rd_same_addr = 0; cur_supported = 0;
    end

    always @(posedge sclk) begin
        if (cs_n) idle_cycles <= idle_cycles + 1;
    end

    always @(negedge cs_n) begin
        cur_back_to_back <= prev_valid && (idle_cycles <= 1);
        idle_cycles      <= 0;
    end

    always @(posedge txn_valid) begin
        cur_supported = supported_addr(addr);
        cur_wr_then_rd_same_addr =
            prev_valid && !prev_aborted && !aborted &&
            !prev_rw && rw && (prev_addr == addr);

        cg.sample(aborted, rw, addr, data_byte,
                  cur_back_to_back, cur_wr_then_rd_same_addr, cur_supported);

        prev_valid   <= 1'b1;
        prev_rw      <= rw;
        prev_aborted <= aborted;
        prev_addr    <= addr;
    end

    final begin
        $display("\n[COV] Functional Coverage = %0.2f%%", cg.get_inst_coverage());
    end
endmodule
