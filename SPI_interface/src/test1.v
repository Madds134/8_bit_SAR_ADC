// MODULE FROM PREVIOUS EDAPLAYGROUND TEST (MAY NOT BE STABLE/CORRECT)
module spi_interface (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
  	input wire [7:0] w_data,

    output wire miso,
    output wire reg_write_en,
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
              if(bit_count == 5'd16) begin
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