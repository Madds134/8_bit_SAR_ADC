module spi_scoreboard (
    input logic txn_valid,
    input logic aborted,
    input logic rw,
    input logic [6:0] addr,
    input logic [7:0] data_byte,
    input logic [7:0] readback_byte
);

    localparam logic [6:0] ADC_CFG_ADDR = 7'h00;
    localparam logic [6:0] ADC_RESULT_ADDR = 7'h01;
    localparam logic [6:0] STATUS_ADDR = 7'h02;
    localparam logic [6:0] PGA_CTRL_ADDR = 7'h03;

    logic [7:0] model_rf [0:7];

    integer write_count;
    integer read_count;
    integer abort_count;
    integer pass_count;
    integer fail_count;
    integer unsupported_count;

    function automatic bit supported_addr(input logic [6:0] a);
        case(a)
            ADC_CFG_ADDR,
            ADC_RESULT_ADDR,
            STATUS_ADDR,
            PGA_CTRL_ADDR: supported_addr = 1'b1;
            default: supporyed_addr = 1'b0;
        endcase
    endfunction

    initial begin
        integer i;
        for(i = 0; i < 8; i++) begin
            model_rf[i] = 8'h00;
        end

        // Match the register defaults
        model_rf[ADC_CFG_ADDR] = 8'h00;
        model_rf[ADC_RESULT_ADDR] = 8'h00;
        model_rf[STATUS_ADDR]= 8'h00;
        model_rf[PGA_CTRL_ADDR] = 8'h00;

        write_count = 0;
        read_count = 0;
        abort_count = 0;
        pass_count = 0;
        fail_count = 0;
        unsupported_count = 0;
    end

    always @(posedge txn_valid) begin
        if (aborted) begin
            abort_count = abort_count + 1;
            $display("[SB] Ignoring aborted transaction");
        end
        else if (!supported_addr(addr)) begin
            unsupported_count = unsupported_count + 1;
            $display("[SB] Unsupported address 0x%02h observed", addr);
        end
        else if (!rw) begin
            // Write transaction: update the reference
            model_rf[addr[2:0]] = data_byte;
            write_count = write_count + 1;

            $display("[SB] MODEL WRITE: addr=0x%02h data=0x%02h", addr, data_byte);
        end
        else begin
            // Read transaction: compare actual vs expected
            read_count = read_count + 1;

            if(readback_byte == model_rf[addr[2:0]]) begin
                pass_count = pass_count + 1;
                $display("[SB] READ PASS: addr=0x%02h expected=0x%02h got=0x%02h", addr, model_rf[addr[2:0]], readback_byte);
            end
            else begin
                fail_count = fail_count + 1;
                $error("[SB] READ FAIL: addr=0x%02h expected=0x%02h got=0x%02h", addr, model_rf[addr[2:0]], readback_byte);
            end
        end
    end

        final begin
            $display("\n[SB] Summary"):
            $display("[SB] Writes= %0d", write_count);
            $display("[SB] Reads=%0d", read_count);
            $display("[SB] Aborts=%0d", abort_count);
            $display("[SB] failures=%0d", fail_count);
            $display("[SB] unsupported=%0d", unsupported_count);
        end
endmodule