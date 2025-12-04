`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2025 23:44:21
// Design Name: 
// Module Name: tb_traffic_controller
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

`timescale 1ns/1ps

module tb_traffic_controller;

    reg clk, rst;
    reg [1:0] congestion_level;
    reg fail_safe_en;

    wire [1:0] active_phase;
    wire yellow, all_red, fail_safe_active;
    wire [15:0] green_time_ticks;

    // DUT
    traffic_controller dut (
        .clk(clk),
        .rst(rst),
        .congestion_level(congestion_level),
        .fail_safe_en(fail_safe_en),
        .active_phase(active_phase),
        .yellow(yellow),
        .all_red(all_red),
        .fail_safe_active(fail_safe_active),
        .green_time_ticks(green_time_ticks)
    );

    initial clk = 0;
    always #1 clk = ~clk;

    localparam MEM_SIZE = 20;
    reg [1:0] level_mem [0:MEM_SIZE-1];

    integer idx;
    integer FRAME_CYCLES;

    initial begin
        
        idx = 0;
   
        congestion_level = 0;
        fail_safe_en = 0;

 
        $dumpfile("traffic.vcd");
        $dumpvars(0, tb_traffic_controller);

        FRAME_CYCLES = 5000;

        rst = 1;
        #10 rst = 0;

        for (idx = 0; idx < MEM_SIZE; idx = idx + 1)
            level_mem[idx] = 0;

        idx = 0;


        $display("Loading levels.mem...");
        $readmemh("levels.mem", level_mem);
        $display("Done loading.");


        for (idx = 0; idx < MEM_SIZE; idx = idx + 1) begin
            congestion_level = level_mem[idx];

            $display("TB: Applying level_mem[%0d] = %0d at time %0t",
                     idx, congestion_level, $time);

            repeat(FRAME_CYCLES) @(posedge clk);

            if (idx == 10)
                fail_safe_en = 1;
        end

        $display("Simulation complete at %0t", $time);
        $finish;
    end

endmodule

