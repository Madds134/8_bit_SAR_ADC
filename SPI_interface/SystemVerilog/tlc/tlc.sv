module traffic_light (
    input logic clk,
    input logic rst,
    output logic red,
    output logic yellow,
    output logic green
);

    typedef enum logic [1:0] {
        RED = 2'b00,
        YELLOW = 2'b01,
        GREEN = 2'b11
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin 
        if(rst) 
            state <= RED;
        else
            state <= next_state;
    end
    always_comb begin
        next_state = state;
        red = 0;
        yellow = 0;
        green = 0;
        case(state)
            RED: begin
                red = 1;
                next_state = YELLOW;
            end
            YELLOW: begin
                yellow = 1;
                next_state = GREEN;
            end
            GREEN: begin
                green = 1;
                next_state = RED;
            end
        endcase
    end
endmodule