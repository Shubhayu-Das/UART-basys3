`timescale 10ns/1ns
module tb_uart_rx;


reg ref_clk;

reg input_rx, clk, flush;
wire [7:0] data;
wire converted, data_valid, busy;

uart_rx DUT(
    .rx(input_rx),
    .i_clk(clk),
    .flush(flush),
    .data(data),
    .busy(busy),
    .converted(converted),
    .data_valid(data_valid)
);

reg [7:0] test_sequence = 8'b11010101;
reg current_bit;
integer i;

initial begin
    clk = 0;
    input_rx = 1;
    current_bit = 0;
    flush = 0;

    // Send the start bit
    #189 input_rx = 0; ref_clk = 0;
    
    // Send the test pattern
    for(i = 0; i < 8; i=i+1) begin
        current_bit = test_sequence[i];
        if(i == 0)
            #679 input_rx = current_bit;
        else
            #868 input_rx = current_bit;
        $display("[%2d] bit: %1b", $time, current_bit);
    end

    // Send the stop bit
    #56 input_rx = 1;
    
    // Flush the currently received data
    #2000 flush = 1;
    #54   flush = 0;
    
    // Send the data again, for LOLs
    #189 input_rx = 0; ref_clk = 0;
    
    // Send the test pattern
    for(i = 0; i < 8; i=i+1) begin
        current_bit = test_sequence[i];
        #868 input_rx = current_bit;
        
        $display("[%2d] (second time bit: %1b", $time, current_bit);
    end
end

// Define a 100MHz/27 clock, time period = 27*2ns
always #27 clk = ~clk;
always #434 ref_clk = ~ref_clk;
endmodule