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
