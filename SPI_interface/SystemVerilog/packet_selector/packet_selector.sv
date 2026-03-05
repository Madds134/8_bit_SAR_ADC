module packet_selector (
    input logic [3:0] req,
    input logic [7:0] data_in,
    output logic [1:0] grant,
    output logic valid,
    output logic [31:0] packet_out
);

    // ENUM
    typedef enum logic [1:0]{
        IDLE,
        ACTIVE
    } state_t;

    state_t state;

    // Packet
    typedef struct packed {
        logic [7:0] header;
        logic [7:0] payload;
        logic [15:0] unused;
    } packet_t;
    typedef union packed{
        packet_t fields;
      logic [31:0] raw;
    } packet_u;
    packet_u pkt;

    // Valid check
    always_comb begin
      valid = !(req inside{4'b0000});
        state = valid ? ACTIVE : IDLE;
    end

    // Grant logic
    always_comb begin
        grant = 2'd0;
        if(state == ACTIVE) begin
            priority if(req[0]) grant = 2'd0;
            else if(req[1]) grant = 2'd1;
            else if(req[2]) grant = 2'd2;
            else if(req[3]) grant = 2'd3;
        end
    end
    
    // Packet form
    always_comb begin
        pkt.fields.header = {6'd0, grant};
        pkt.fields.payload = data_in;
        pkt.fields.unused = 16'd0;
        packet_out = pkt.raw;
    end
endmodule
