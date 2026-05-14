// MODULE FROM PREVIOUS EDAPLAYGROUND TEST (MAY NOT BE STABLE/CORRECT)
module spi_fsm (
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,

    output reg  [6:0] addr,
    output reg        reg_write_en,
    output reg        tx_load_en,
    output wire [2:0] state_test
);

    localparam IDLE  = 3'd0,
               CMD   = 3'd1,
               READ  = 3'd2,
               WRITE = 3'd3,
               DONE  = 3'd4;

    reg [2:0] state, next_state;
    reg       read_write;

    wire      freeze, cmd_done, frame_done;
    wire [7:0] rx_data;
    wire [4:0] b_count;

    rx_shift_register u_rx (
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done),
        .rx_data(rx_data)
    );

    bit_counter u_cnt (
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done),
        .count(b_count)
    );

    // Next-state and output logic
    always @(*) begin
        next_state    = state;
        reg_write_en  = 1'b0;
        tx_load_en    = 1'b0;

        case (state)
            IDLE: begin
                if (!cs_n)
                    next_state = CMD;
            end

            CMD: begin
                if (cmd_done) begin
                    if (read_write)
                        next_state = READ;
                    else
                        next_state = WRITE;
                end
            end

            READ: begin
                tx_load_en = 1'b1;
                if (frame_done)
                    next_state = DONE;
            end

            WRITE: begin
                reg_write_en = 1'b1;
                if (frame_done)
                    next_state = DONE;
            end

            DONE: begin
                if (cs_n)
                    next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential logic
    always @(posedge sclk or posedge cs_n) begin
        if (cs_n) begin
            state       <= IDLE;
            read_write  <= 1'b0;
            addr        <= 7'd0;
        end else begin
            state <= next_state;

            // first command bit = R/W
            if (b_count == 5'd0)
                read_write <= mosi;

            // after full command byte captured
            if (cmd_done)
                addr <= rx_data[6:0];
        end
    end

    assign state_test = state;

endmodule
// Module: bit_counter
// Project: 8-bit SAR ADC for TinyTapeout
// Function: Tracks SPI clock cycles to enforce 10 bit frame boundaries.
//           Provides a freeze outut signal to prevent data wrap around/over clocking.

// Module: bit_counter
// Project: 8-bit SAR ADC for TinyTapeout
// Function: Tracks SPI clock cycles to enforce 10 bit frame boundaries.
//           Provides a freeze outut signal to prevent data wrap around/over clocking.

module bit_counter (
    input wire sclk, // SPI clock
    input wire cs_n, // Active low chip select
    output reg freeze, // Control signal for other blocks when count 10 bits
    output reg cmd_done, // Pulse at 8 bits
    output reg frame_done, // Pulse at 16 bits
    output reg [4:0] count
);

// Internal 4-bit counter to track bits 0 through 10
reg [4:0] bit_count;

// Sequential logic for bit tracking
// cs_n is used as asynchronous reset to ensure immediate readiness upon frame initation.
always @(negedge sclk or posedge cs_n) begin
    if (cs_n) begin // Reset
        bit_count <= 5'b0;
        freeze <= 1'b0;
        cmd_done <= 1'b0;
        frame_done <= 1'b0;
    end
    else begin
        cmd_done <= 1'b0;
        frame_done <= 1'b0;
        freeze <= 1'b0;

        if(bit_count < 5'd16) begin
            bit_count <= bit_count + 5'd1;
            if(bit_count == 5'd7) begin
                cmd_done <= 1'b1;
            end
            if(bit_count == 5'd15) begin // Latch bit counter if > 15
                frame_done <= 1'b1;
            end
        end
      	if (bit_count >= 5'd15) begin
          freeze <= 1'b1;
      	end
      	else begin
          freeze <= 1'b0;
        end
    end
end
assign count = bit_count;
endmodule
    




module rx_shift_register (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    input wire freeze,
    input wire cmd_done,
    input wire frame_done,
    output reg [7:0] rx_data
);
    reg [7:0] shift_register;
    
    // Increment the shift register on each clock pulse and freeze control signal not asserted
    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            shift_register <= 8'd0;
        end
        else if(!freeze) begin
            shift_register <= {shift_register[6:0], mosi};
        end
    end

    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            rx_data <= 8'd0;
        end
        else if (cmd_done || frame_done) begin
            rx_data <= shift_register;
        end 

    end
endmodule






