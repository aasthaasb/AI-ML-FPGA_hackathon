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

    // Instantiate DUT
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
    always #1 clk = ~clk; // 1ns half-period -> 2ns period

    localparam MEM_SIZE = 20;
    reg [1:0] level_mem [0:MEM_SIZE-1];

    integer idx;
    integer FRAME_CYCLES;

    initial begin
        idx = 0;
        congestion_level = 2'd0;
        fail_safe_en = 1'b0;

 
        $dumpfile("traffic.vcd");
        $dumpvars(0, tb_traffic_controller);

        FRAME_CYCLES = 5000; 

        rst = 1;
        repeat (10) @(posedge clk); 

        rst = 0;
        @(posedge clk);

        for (idx = 0; idx < MEM_SIZE; idx = idx + 1)
            level_mem[idx] = 2'd0;

        idx = 0;

        $display("Loading levels.mem into level_mem...");
        $readmemh("levels.mem", level_mem);
        $display("Loaded levels.mem.");

        for (idx = 0; idx < MEM_SIZE; idx = idx + 1) begin
            congestion_level = level_mem[idx];
            $display("TB: Applying level_mem[%0d] = %0d at time %0t", idx, congestion_level, $time);

            repeat (FRAME_CYCLES) @(posedge clk);

            if (idx == 10) begin
                $display("TB: Asserting manual fail_safe_en at idx %0d time %0t", idx, $time);
                fail_safe_en = 1'b1;
            end
        end
        repeat (100) @(posedge clk);

        $display("Simulation complete at time %0t", $time);
        $finish;
    end

endmodule


