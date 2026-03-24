module spi_fsm (
    input wire sclk,
    input wire cs_n,
    input wire mosi,
  	input wire [7:0] rx_data,
  input wire [4:0] bit_count,
    
    output reg [6:0] addr,
    output reg reg_write_en,
    output reg tx_load_en
);

    localparam IDLE=0, CMD=1, READ=2, WRITE=3;
    reg [2:0] next_state, state;
    reg read_write;


    always @(*) begin
        next_state = state;
        reg_write_en = 0;
        tx_load_en = 0;
        case(state) 
            IDLE: begin
                next_state = (cs_n || bit_count == 4'd15) ? IDLE : CMD;
            end
            CMD: begin
                if (bit_count == 4'd7) begin
                    tx_load_en = 1'b1;
                    if (rx_data[7]) begin
                        next_state = READ;
                    end
                    else if (!rx_data[7]) begin
                        next_state = WRITE;    
                    end
                end
            end
            READ: begin
              if(bit_count == 4'd16) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ;
                end
            end
            WRITE: begin
                reg_write_en = 1;
              if(bit_count == 4'd16) begin
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
          if(bit_count == 4'd7) begin
                read_write <= rx_data[7];
                addr <= rx_data[6:0];
            end
        end
    end
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
      	else if(!(bit_count == 4'd16)) begin
            shift_register <= {shift_register[6:0], 1'b0};
        end
    end
end
assign miso = shift_register[7];
endmodule

