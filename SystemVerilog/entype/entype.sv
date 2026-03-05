module entype(
    input logic clk,
    input logic rst,
    input logic start,
    output logic done
);
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        LOAD = 2'b01,
        PROCESS = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        done = 0;
        case(state)
            IDLE: begin
                if(start) begin
                    next_state = LOAD;
                end
            end
            LOAD: begin
                next_state = PROCESS;
            end
            PROCESS: begin
                next_state = DONE;
            end
            DONE: begin
                done = 1;
                next_state = IDLE;
            end
        endcase
    end
endmodule