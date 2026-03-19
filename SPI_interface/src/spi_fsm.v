module spi_fsm (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
  	input wire cmd_valid,
    
    output reg [6:0] addr,
    output reg reg_write_en,
    output reg tx_load_en
);

    localparam IDLE=0, CMD=1, READ=2, WRITE=3;
    reg [2:0] next_state, state;
    reg read_write;
    wire freeze, cmd_done, frame_done;
    wire [7:0] rx_data;

    // Instantiate the rx_shift_register
    rx_shift_register r_reg(
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done),
      	.rx_data(rx_data),
      	.cmd_valid(cmd_valid)
    );

    // Instantiate the bit_counter
    bit_counter count(
        .sclk(sclk),
        .cs_n(cs_n),
        .freeze(freeze),
        .cmd_done(cmd_done),
        .frame_done(frame_done)
    );

    always @(*) begin
        next_state = state;
        reg_write_en = 0;
        tx_load_en = 0;
        case(state) 
            IDLE: begin
                next_state = (cs_n) ? IDLE : CMD;
            end
            CMD: begin
                if (cmd_done) begin
                    if (read_write) begin
                        next_state = READ;
                    end
                    else if (!read_write) begin
                        next_state = WRITE;    
                    end
                end
            end
            READ: begin
                tx_load_en = 1;
                if(frame_done) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ;
                end
            end
            WRITE: begin
                tx_load_en = 1;
                reg_write_en = 1;
                if(frame_done) begin
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
endmodule
