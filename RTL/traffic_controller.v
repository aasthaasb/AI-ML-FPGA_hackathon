`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2025 23:35:22
// Design Name: 
// Module Name: traffic_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Features:
//  - Dynamic green time from ML level (0..3) via LUT
//  - Yellow = fixed, All-Red = fixed
//  - Minimum green enforced
//  - Fail-safe mode when ML is stuck or manual fail-safe asserted


module traffic_controller (
    input  wire        clk,
    input  wire        rst,               
    input  wire [1:0]  congestion_level,  
    input  wire        fail_safe_en,     

    output reg  [1:0]  active_phase,      
    output reg         yellow,            
    output reg         all_red,           
    output reg         fail_safe_active,  
    output reg [15:0]  green_time_ticks   
);

    localparam integer SCALE           = 10;   // 1 tick = (1 ms * SCALE)
    localparam integer YELLOW_TICKS    = (2000  / SCALE);  // 2s
    localparam integer ALLRED_TICKS    = (1000  / SCALE);  // 1s
    localparam integer FAILSAFE_TICKS  = (8000  / SCALE);  // 8s
    localparam integer MIN_GREEN_TICKS = (4000  / SCALE);  // 4s

    reg [15:0] green_lut [0:3];
    initial begin
        green_lut[0] = (4000  / SCALE);  // level 0 -> 4s
        green_lut[1] = (6000  / SCALE);  // level 1 -> 6s
        green_lut[2] = (10000 / SCALE);  // level 2 ->10s
        green_lut[3] = (16000 / SCALE);  // level 3 ->16s
    end

    localparam integer S_NS_GREEN  = 3'd0;
    localparam integer S_NS_YELLOW = 3'd1;
    localparam integer S_ALL_RED1  = 3'd2;
    localparam integer S_EW_GREEN  = 3'd3;
    localparam integer S_EW_YELLOW = 3'd4;
    localparam integer S_ALL_RED2  = 3'd5;

    reg [2:0] state, next_state;
    reg [31:0] timer;

    reg [1:0] prev_level;
    reg [15:0] same_count;
    localparam integer STUCK_THRESH = 30; 

    initial begin
        state = S_NS_GREEN;
        next_state = S_NS_GREEN;
        active_phase = 2'd0;
        yellow = 1'b0;
        all_red = 1'b0;
        fail_safe_active = 1'b0;
        green_time_ticks = MIN_GREEN_TICKS;
        timer = 32'd0;
        prev_level = 2'd0;
        same_count = 16'd0;
    end

    always @(posedge clk) begin
        if (rst) begin
            prev_level <= 2'd0;
            same_count <= 16'd0;
            fail_safe_active <= 1'b0;
        end else begin
            if (congestion_level == prev_level)
                same_count <= same_count + 1'b1;
            else begin
                same_count <= 16'd0;
                prev_level <= congestion_level;
            end

            if (same_count > STUCK_THRESH)
                fail_safe_active <= 1'b1;
            else
                fail_safe_active <= fail_safe_en | (same_count > STUCK_THRESH);
        end
    end


    always @(posedge clk) begin
        if (rst) timer <= 32'd0;
        else if (timer > 0) timer <= timer - 1'b1;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_NS_GREEN:  if (timer == 0) next_state = S_NS_YELLOW;
            S_NS_YELLOW: if (timer == 0) next_state = S_ALL_RED1;
            S_ALL_RED1:  if (timer == 0) next_state = S_EW_GREEN;
            S_EW_GREEN:  if (timer == 0) next_state = S_EW_YELLOW;
            S_EW_YELLOW: if (timer == 0) next_state = S_ALL_RED2;
            S_ALL_RED2:  if (timer == 0) next_state = S_NS_GREEN;
            default: next_state = S_NS_GREEN;
        endcase
    end


    always @(posedge clk) begin
        if (rst) begin
            state <= S_NS_GREEN;
            active_phase <= 2'd0;
            yellow <= 1'b0;
            all_red <= 1'b0;
            timer <= 32'd0;
            green_time_ticks <= MIN_GREEN_TICKS;
        end else begin
            state <= next_state;


            yellow <= 1'b0;
            all_red <= 1'b0;

            case (next_state)
                S_NS_GREEN: begin
                    active_phase <= 2'd0;
                    if (fail_safe_active)
                        green_time_ticks <= FAILSAFE_TICKS;
                    else begin
                        if (green_lut[congestion_level] < MIN_GREEN_TICKS)
                            green_time_ticks <= MIN_GREEN_TICKS;
                        else
                            green_time_ticks <= green_lut[congestion_level];
                    end
                    timer <= green_time_ticks;
                end

                S_NS_YELLOW: begin
                    yellow <= 1'b1;
                    timer <= YELLOW_TICKS;
                end

                S_ALL_RED1: begin
                    all_red <= 1'b1;
                    timer <= ALLRED_TICKS;
                end

                S_EW_GREEN: begin
                    active_phase <= 2'd1;
                    if (fail_safe_active)
                        green_time_ticks <= FAILSAFE_TICKS;
                    else
                        green_time_ticks <= green_lut[congestion_level];
                    timer <= green_time_ticks;
                end

                S_EW_YELLOW: begin
                    yellow <= 1'b1;
                    timer <= YELLOW_TICKS;
                end

                S_ALL_RED2: begin
                    all_red <= 1'b1;
                    timer <= ALLRED_TICKS;
                end

                default: begin
                    timer <= MIN_GREEN_TICKS;
                end
            endcase
        end
    end

endmodule
