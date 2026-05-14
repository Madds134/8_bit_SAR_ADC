// Module: tri_state_buffer
// Project: 8-bit SAR ADC for TinyTapeout
// Function:
//   Provides the output-data and output-enable controls for the SPI SDO/MISO
//   pad. The pad is driven only while chip select is asserted.
module tri_state_buffer (
    input wire sdo_data_in,  // Serial data from the TX shift register.
    input wire cs_n,         // Active-low chip select.
    output wire sdo_data_out, // Data forwarded to the output pad.
    output wire oe           // Output enable for the tri-state pad.
);

    // Data is passed through combinationally; the pad enable determines whether
    // the external SDO/MISO pin is actively driven.
    assign sdo_data_out = sdo_data_in;

    // Drive the output only during an active SPI transaction.
    assign oe = !cs_n;
endmodule
