/*
 * Driver code for the 7 segment common anode display on the Basys-3 board
 * This is wrriten to be used as a fragment in a larger project
 * Written by Shubhayu Das
 * Date: 11th November 2021
 * 
 * I am referring to page 15 of the Basys 3 manual: 
 * https://digilent.com/reference/_media/basys3:basys3_rm.pdf
 * 
 * I am going left to right, (when the VGA port faces up , and the FPGA chip faces the user)
 *
 * Inputs:
 * INPUT_WIDTH: Number of bits needed to represent max(number). Can be left to 15.
 * SEV_SEG_PRESCALAR: Clock division factor, internal to the display
 *
 * clk: I think a maximum frequency of 1 to 5kHz should be enough
 * number: 0 -> 9. Pass the 4 digit DECIMAL number. Active HIGH input.
 * decimal_points: Pass a 1 to to light up corresponding decimal point {4'b0010 will light up AN1's decimal point(dp)}
 *                 Note that this input is active HIGH. I will convert it as per need in this module
 *
 * Wiring pinout:
 * [3:0] anodes   -> {W4, V4, U4, U2}                       // corresponding to {AN3, AN2, AN1, AN0}
 * [7:0] cathodes -> {W7, W6, U8, V8, U5, V5, U7, V7}       // corresponding to {a, b, c, d, e, f, g, dp} of 7-seg
 * 
 * The 7-seg displays are going to be time multiplexed.
 * The active display's anode needs to be pulled LOW
 * The cathodes are active LOW, so pull down to 0 to activate the segment.
 * This is taken care of in the digit_to_logic_mapping array
 *
 * The hex digit to binary mapping(active high) can be found here: 
 * https://www.multisim.com/help/components/7-segment-display/
 *
*/

module seven_seg_drive #(
    parameter INPUT_WIDTH = 15,
    SEV_SEG_PRESCALAR = 4
)(
    input                               i_clk,
    input       [INPUT_WIDTH-1:0]       number,
    input       [3:0]                   decimal_points,
    output reg  [3:0]                   anodes,
    output reg  [7:0]                   cathodes
);

    localparam [0:9][6:0] digit_to_logic_mapping = {      // This mapping is active low
            7'b0000001,     // 0
            7'b1001111,     // 1
            7'b0010010,     // 2
            7'b0000110,     // 3
            7'b1001100,     // 4
            7'b0100100,     // 5
            7'b0100000,     // 6
            7'b0001111,     // 7
            7'b0000000,     // 8
            7'b0000100      // 9
        };

    reg [3:0] i;
    reg [3:0][3:0] digits;                  // Store the BCD digits as they are converted
    reg [1:0] current_digit;                // Keep track of which display to activate

    reg clk;
    reg [SEV_SEG_PRESCALAR:0] local_counter;

    initial begin
        current_digit = 0;
        
        anodes = 4'b1111;
        cathodes = 8'b0;
        
        digits = {4'h0, 4'h0, 4'h0, 4'h0};

        clk = 0;
        local_counter = 0;
    end

    always @(posedge i_clk) begin
        local_counter <= local_counter + 1;

        if(local_counter == 1<<SEV_SEG_PRESCALAR) begin
            local_counter <= 0;
            clk <= ~clk;
        end
    end

    // Choosing which digit to display
    always @(posedge clk) begin
        current_digit <= current_digit + 1;
    end

    // Convert the integer to 4-digit BCD
    always @(posedge clk) begin        
       digits = {4'h0, 4'h0, 4'h0, 4'h0};
        
       for(i = 0; i < INPUT_WIDTH; i = i + 1) begin

           digits[3]   = (digits[3] >= 5)? digits[3] + 3 : digits[3];
           digits[2]   = (digits[2] >= 5)? digits[2] + 3 : digits[2];
           digits[1]   = (digits[1] >= 5)? digits[1] + 3 : digits[1];
           digits[0]   = (digits[0] >= 5)? digits[0] + 3 : digits[0];

           {digits[3], digits[2], digits[1], digits[0]} = {
                {digits[3][2:0], digits[2][3]},
                {digits[2][2:0], digits[1][3]},
                {digits[1][2:0], digits[0][3]},
                {digits[0][2:0], number[INPUT_WIDTH-1-i]}
            };
       end   
    end

    // Converting the BCD digits and the decimal point signal into actual outputs
    always @(current_digit, decimal_points) begin
        anodes      <= ~(1<<current_digit);
        cathodes    <= {
            digit_to_logic_mapping[digits[current_digit]],
            ~decimal_points[current_digit]
        };

    end

endmodule