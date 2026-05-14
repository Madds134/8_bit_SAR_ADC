// Module: spi_fsm
// Project: 8-bit SAR ADC for TinyTapeout
// Function:
//   Controls the SPI transaction flow after byte reception. The FSM decodes the
//   command byte, selects read or write behavior, requests TX data loading for
//   reads, and enables register-file writes during the data phase.
module spi_fsm (
    input wire sclk,          // SPI clock.
    input wire cs_n,          // Active-low chip select. High terminates frame.
    input wire mosi,          // Serial input, reserved for interface visibility.
    input wire [7:0] rx_data, // Last byte received by the RX shift register.
    input wire [4:0] bit_count, // Current bit index within the SPI frame.
    input wire cmd_valid,     // Indicates rx_data contains a valid command byte.
    
    output reg reg_write_en,  // Enables register-file commit for write frames.
    output reg tx_load_en,    // Loads read data into the TX shift register.
    output wire [6:0] rf_addr // Register-file address for read/write access.
);

    localparam IDLE=0, CMD=1, READ=2, WRITE=3;
    reg [2:0] next_state, state;
    reg read_write;
    reg [6:0] addr;

    // Combinational next-state and control decode. Outputs default low so
    // control pulses are asserted only in the states that require them.
    always @(*) begin
        next_state = state;
        reg_write_en = 0;
        tx_load_en = 0;
        case(state) 
            IDLE: begin
                // Enter command collection once cs_n is asserted and the frame
                // is active. Stay idle after a completed frame until cs_n rises.
                next_state = (cs_n || bit_count == 4'd15) ? IDLE : CMD;
            end
            CMD: begin
                // Command format: bit 7 selects read/write, bits 6:0 select
                // the register address.
                if (cmd_valid) begin
                    if (rx_data[7]) begin
                        // For reads, request the addressed register data before
                        // the data byte is shifted out on MISO.
                        tx_load_en = 1'b1;
                        next_state = READ;
                    end
                    else if (!rx_data[7]) begin
                        next_state = WRITE;    
                    end
                end
            end
            READ: begin
                // Remain in READ until the 16-bit transaction completes.
                if(bit_count == 5'd16) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ;
                end
            end
            WRITE: begin
                // Hold write enable active through the data phase. The register
                // file commits the write at the frame boundary.
                reg_write_en = 1;
                if(bit_count == 5'd16) begin
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

    // Sequential state and command-address storage. cs_n acts as an
    // asynchronous frame reset so a deasserted chip-select immediately returns to idle.
    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin
            state <= IDLE;
            read_write <= 1'b0;
            addr <= 7'd0;
        end
        else begin
            state <= next_state;
            // Capture command fields once per frame for use during the data
            // phase after rx_data begins shifting the next byte.
            if(cmd_valid) begin
                read_write <= rx_data[7];
                addr <= rx_data[6:0];
            end
        end
    end

    // Present the new command address immediately during cmd_valid so the read
    // path can load data without waiting for addr to update on the next edge.
    assign rf_addr = (cmd_valid) ? rx_data[6:0] : addr;
endmodule
