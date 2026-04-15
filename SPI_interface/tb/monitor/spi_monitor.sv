module spi_monitor (
    input logic sclk,
    input logic cs_n,
    input logic mosi,
    input logic miso,

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
        in_frame = 1'b0;
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
        in_frame <= 1'b1;
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