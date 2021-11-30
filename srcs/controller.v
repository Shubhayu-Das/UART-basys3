`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIITB - VL504
// Engineer: Shubhayu Das
// 
// Create Date: 27.11.2021 00:15:42
// Design Name: Controller for UART RX(115200 baud rate
// Module Name: controller
// Project Name: Testing working of UART RX FSM, with oversampling
// Target Devices: Basys 3 dev board
// Tool Versions: Vivado 2019.1
// Description: Master controller for receiving 2 32 bit numbers, and sending their sum
// 
// Dependencies: uart_rx.v seven_seg_drive.v
// 
// Revision: 1
// Additional Comments: Wow, this actually works!
// 
//////////////////////////////////////////////////////////////////////////////////


module controller(
    input clk_100MHz,
    input rx,           // B18
    output tx,          // A18
    output rx_busy,     // U16
    output converted,   // E19
    output data_valid,  // U19
    output tx_busy,     // V19
    output [7:0] cathodes,
    output [3:0] anodes
);
    
    // FSM states
    localparam RX_NUM_1_LB = 0; // Receive low-byte of first number
    localparam RX_NUM_1_HB = 1; // Receive high-byte of first number
    localparam RX_NUM_2_LB = 2; // Receive low-byte of second number
    localparam RX_NUM_2_HB = 3; // Receive high-byte of second number
    localparam TX_NUM_1 = 4;    // Send high byte of sum
    localparam TX_NUM_2 = 5;    // Send low byte of sum
    
    // Local control logic variables
    // FSM state
    reg [2:0] state;
    
    // This variable is super critical in preventing wrong FSM state changes
    reg allow_next;     // Local signal to prevent race conditions 
    
    // IO related variables
    reg flush_ctrl;     // Flush the RX data after reading
    reg tx_enable_ctrl; // Allow tranmission of output, after data is settled
    
    wire [7:0] uart_data;   // The actual RX UART data
    reg [7:0] out_data;     // The data that will be sent over TX
    reg [7:0] byte_buffer;  // Store low byte of the second number 
    reg [15:0] sum;         // Store the actual sum and incoming data
    
    // UART clock related variables
    reg clk_uart;           // (100MHz) / (BAUD_RATE*OVERSAMPLING*2) 
    reg [4:0] counter;
    
    // See UART RX module
    uart_rx uart_rx_115200 (
        .rx(rx),
        .i_clk(clk_uart),
        .flush(flush_ctrl),
        .data(uart_data),
        .converted(converted),
        .data_valid(data_valid),
        .busy(rx_busy)
    );
    
    // See UART TX module
    uart_tx uart_tx_115200(
        .clk(clk_uart),
        .tx_enable(tx_enable_ctrl),
        .data(out_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );
    
    // Good old seven segment driver
    seven_seg_drive #(
        .INPUT_WIDTH(16),
        .SEV_SEG_PRESCALAR(18)
    ) display (
        .i_clk(clk_100MHz),
        .number(sum[9:0]),
        .decimal_points(4'h0),
        .anodes(anodes),
        .cathodes(cathodes)
    );
    
    initial begin
        counter = 0;
        clk_uart = 0;
        
        flush_ctrl = 0;
        tx_enable_ctrl = 0;
        
        sum = 0;
        out_data = 0;
        byte_buffer = 0;
        
        state = RX_NUM_1_LB;
        allow_next = 0;
    end
    
    // Divided clock for UART @ 115200 baud
    always @(posedge clk_100MHz) begin
        counter <= counter + 1;
        
        if(counter == 5'd27) begin
            counter <= 0;
            clk_uart <= ~clk_uart;
        end
    end
    
    always @(posedge clk_uart) begin
        case(state)
            RX_NUM_1_LB: begin
                tx_enable_ctrl <= 0;
                
                if(converted) begin
                    sum <= {8'b0, uart_data};
                    flush_ctrl <= 1;        // Flush UART RX registers
                    state <= RX_NUM_1_HB;
                end
            end

            RX_NUM_1_HB: begin
                // Once RX module has produced the final output(converted)
                // and registers are cleared(converted is set low), go ahead
                if(~flush_ctrl && ~converted)
                    allow_next <= 1;        // Allow RX after registers cleared
                    
                if(converted && ~flush_ctrl && allow_next) begin
                    sum <= {uart_data, sum[7:0]};
                    flush_ctrl <= 1;        // Data read, flush RX register
                    allow_next <= 0;
                    state <= RX_NUM_2_LB;
                end
                else
                    flush_ctrl <= 0;
            end
            
            // These states are exactly the same as "RX_NUM_1_HB" state
            RX_NUM_2_LB: begin
                if(~flush_ctrl && ~converted)
                    allow_next <= 1;
                    
                if(converted && ~flush_ctrl && allow_next) begin
                    byte_buffer <= uart_data;
                    flush_ctrl <= 1;
                    allow_next <= 0;
                    state <= RX_NUM_2_HB;
                end
                else
                    flush_ctrl <= 0;
            end
            
            RX_NUM_2_HB: begin
                if(~flush_ctrl && ~converted)
                    allow_next <= 1;
                    
                if(converted && ~flush_ctrl && allow_next) begin
                    sum <= sum + {uart_data, byte_buffer};
                    byte_buffer <= 0;
                    flush_ctrl <= 1;
                    allow_next <= 0;
                    state <= TX_NUM_1;
                end
                else
                    flush_ctrl <= 0;
            end

            // Calculations done, send data back
            TX_NUM_1: begin
                out_data <= sum[15:8];
                
                // Once TX is complete, allow going to next state
                if(~tx_busy && ~allow_next)
                    tx_enable_ctrl <= 1;
                else begin
                    allow_next <= 1;
                    flush_ctrl <= 0;
                    tx_enable_ctrl <= 0;
                end
                
                // TX complete, go to next state
                if(~tx_busy && allow_next) begin
                    allow_next <= 0;
                    state <= TX_NUM_2;
                end
            end
            
            // Exactly the same as the previous state
            TX_NUM_2: begin
                out_data <= sum[7:0];
                
                if(~tx_busy && ~allow_next)
                    tx_enable_ctrl <= 1;
                else begin
                    allow_next <= 1;
                    tx_enable_ctrl <= 0;
                end
                
                if(~tx_busy && allow_next) begin
                    allow_next <= 0;
                    state <= RX_NUM_1_LB;
                end
            end
        endcase
    end
endmodule