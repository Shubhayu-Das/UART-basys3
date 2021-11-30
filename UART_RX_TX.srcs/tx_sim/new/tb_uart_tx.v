`timescale 10ns/10ns

module tb_uart_tx;

reg clk, ref_clk;

reg [7:0] test_sequence = 8'b11010101;
reg tx_enable;
wire tx, tx_busy;

uart_tx DUT(
    .clk(clk),
    .data(test_sequence),
    .tx_enable(tx_enable),
    .tx(tx),
    .tx_busy(tx_busy)
);

initial begin
    tx_enable = 0;
    clk = 0;
    
    #191 tx_enable = 1;
    #100 tx_enable = 0;
    #145 ref_clk = 0;
end

// Define a 100MHz/27 clock, time period = 27*2ns
always #27 clk = ~clk;
always #434 ref_clk = ~ref_clk;

endmodule