`timescale 1ns/1ns

module tb_controller;
    reg clk, rx, ref_clk;
    wire rx_busy, converted, data_valid;
    wire tx, tx_busy;
    wire [7:0] cathodes;
    wire [3:0] anodes;
    
    controller DUT(
        .clk_100MHz(clk),
        .rx(rx),           // B18
        .tx(tx),          // A18
        .rx_busy(rx_busy),     // U16
        .converted(converted),   // E19
        .data_valid(data_valid),  // U19
        .tx_busy(tx_busy),     // V19
        .cathodes(cathodes),
        .anodes(anodes)
    );
    
    reg [15:0] num1 = 16'd523;
    reg [15:0] num2 = 16'd423;
    reg [4:0] i;
    
    initial begin
        clk = 0;
        rx = 1;
       
        // Sending the first number 
        #8680 rx = 0; ref_clk = 0;
       
        for(i = 0; i < 8; i=i+1) begin
            #8680 rx = num1[i];
            $display("[%2d] First number(low byte) - bit[%1d]: %1b", $time, i, num1[i]);
        end
        #8680 rx = 1;
        
        #8680 rx = 0;
        for(i = 8; i < 16; i=i+1) begin
            #8680 rx = num1[i];
            $display("[%2d] First number(high byte) - bit[%1d]: %1b", $time, i, num1[i]);
        end
        
        #8680 rx = 1;
        
        // Sending the second number
        #(8680*2) rx = 0;
               
        for(i = 0; i < 8; i=i+1) begin
            #8680 rx = num2[i];
            $display("[%2d] Second number(low byte) - bit[%1d]: %1b", $time, i, num2[i]);
        end
        #8680 rx = 1;
        
        #8680 rx = 0;
        for(i = 8; i < 16; i=i+1) begin
            #8680 rx = num2[i];
            $display("[%2d] Second number(high byte) - bit[%1d]: %1b", $time, i, num2[i]);
        end
        
        #8680 rx = 1;
    end
    
    always #5 clk <= ~clk;
    always #4340 ref_clk <= ~ref_clk;
endmodule