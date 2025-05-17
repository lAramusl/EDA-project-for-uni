`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
      // assign red        = '0;
       //assign green      = '0;
       //assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------
    //
    //  Exercise 1: Uncomment this instantation
    //  to see the value coming from the microphone (in hexadecimal).
    //
    //------------------------------------------------------------------------

    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (mic)), .*);

    //------------------------------------------------------------------------
    //
    //  Measuring frequency
    //
    //------------------------------------------------------------------------

    // It is enough for the counter to be 20 bit. Why?

    logic [23:0] prev_mic;
    logic [19:0] counter;
    logic [19:0] distance;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic <= '0;
            counter  <= '0;
            distance <= '0;
        end
        else
        begin
            prev_mic <= mic;

            // Crossing from negative to positive numbers

            if (  prev_mic [$left ( prev_mic )] == 1'b1
                & mic      [$left ( mic      )] == 1'b0 )
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)  // To prevent overflow
            begin
               counter <= counter + 20'h1;
            end
        end

    //------------------------------------------------------------------------
    //
    //  Exercise 2: Uncomment this instantation
    //  to see the value of the counter.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (counter)), .*);

    //------------------------------------------------------------------------
    //
    //  Exercise 3: Uncomment this instantation
    //  to see the period of the sound wave coming from the microphone.
    //
    //------------------------------------------------------------------------

    // seven_segment_display # (w_digit)
    // i_7segment (.number (w_number' (distance [19:4])), .*);

    //------------------------------------------------------------------------
    //
    //  Determining the note
    //
    //------------------------------------------------------------------------

    `ifdef USE_STANDARD_FREQUENCIES

    localparam freq_100_C  = 26163,
               freq_100_Cs = 27718,
               freq_100_D  = 29366,
               freq_100_Ds = 31113,
               freq_100_E  = 32963,
               freq_100_F  = 34923,
               freq_100_Fs = 36999,
               freq_100_G  = 39200,
               freq_100_Gs = 41530,
               freq_100_A  = 44000,
               freq_100_As = 46616,
               freq_100_B  = 49388;
    `else

    // Custom measured frequencies

    // localparam freq_100_C   = 52325,
    //            freq_100_Cs  = 55437,
    //            freq_100_D   = 58733,
    //            freq_100_Ds  = 62225,
    //            freq_100_E   = 65926,
    //            freq_100_F   = 69846,
    //            freq_100_Fs  = 73999,
    //            freq_100_G   = 78399,
    //            freq_100_Gs  = 83061,
    //            freq_100_A   = 88000,
    //            freq_100_As  = 93233,
    //            freq_100_B   = 98777;
    localparam freq_100_C  = 26163,
               freq_100_Cs = 27718,
               freq_100_D  = 29366,
               freq_100_Ds = 31113,
               freq_100_E  = 32963,
               freq_100_F  = 34923,
               freq_100_Fs = 36999,
               freq_100_G  = 39200,
               freq_100_Gs = 41530,
               freq_100_A  = 44000,
               freq_100_As = 46616,
               freq_100_B  = 49388;
    `endif

    //------------------------------------------------------------------------

    function [19:0] high_distance (input [18:0] freq_100);
       high_distance = clk_mhz * 1000 * 1000 / freq_100 * 103;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] low_distance (input [18:0] freq_100);
       low_distance = clk_mhz * 1000 * 1000 / freq_100 * 97;
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq_single_range (input [18:0] freq_100, input [19:0] distance);

       check_freq_single_range =    distance > low_distance  (freq_100)
                                  & distance < high_distance (freq_100);
    endfunction

    //------------------------------------------------------------------------

    function [19:0] check_freq (input [18:0] freq_100, input [19:0] distance);

       check_freq =   check_freq_single_range (freq_100 * 4 , distance)
                    | check_freq_single_range (freq_100 * 2 , distance)
                    | check_freq_single_range (freq_100     , distance);

    endfunction

    //------------------------------------------------------------------------

    wire check_C  = check_freq (freq_100_C  , distance );
    wire check_Cs = check_freq (freq_100_Cs , distance );
    wire check_D  = check_freq (freq_100_D  , distance );
    wire check_Ds = check_freq (freq_100_Ds , distance );
    wire check_E  = check_freq (freq_100_E  , distance );
    wire check_F  = check_freq (freq_100_F  , distance );
    wire check_Fs = check_freq (freq_100_Fs , distance );
    wire check_G  = check_freq (freq_100_G  , distance );
    wire check_Gs = check_freq (freq_100_Gs , distance );
    wire check_A  = check_freq (freq_100_A  , distance );
    wire check_As = check_freq (freq_100_As , distance );
    wire check_B  = check_freq (freq_100_B  , distance );

    //------------------------------------------------------------------------

    localparam w_note = 12;

    wire [w_note - 1:0] note = { check_C  , check_Cs , check_D  , check_Ds ,
                                 check_E  , check_F  , check_Fs , check_G  ,
                                 check_Gs , check_A  , check_As , check_B  };

    localparam [w_note - 1:0] no_note = 12'b0,

                              C  = 12'b1000_0000_0000,
                              Cs = 12'b0100_0000_0000,
                              D  = 12'b0010_0000_0000,
                              Ds = 12'b0001_0000_0000,
                              E  = 12'b0000_1000_0000,
                              F  = 12'b0000_0100_0000,
                              Fs = 12'b0000_0010_0000,
                              G  = 12'b0000_0001_0000,
                              Gs = 12'b0000_0000_1000,
                              A  = 12'b0000_0000_0100,
                              As = 12'b0000_0000_0010,
                              B  = 12'b0000_0000_0001;

    localparam [w_note - 1:0] Df = Cs, Ef = Ds, Gf = Fs, Af = Gs, Bf = As;

    //------------------------------------------------------------------------
    //
    //  Note filtering
    //
    //------------------------------------------------------------------------

    logic  [w_note - 1:0] d_note;  // Delayed note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            d_note <= no_note;
        else
            d_note <= note;

    logic  [19:0] t_cnt;           // Threshold counter
    logic  [w_note - 1:0] t_note;  // Thresholded note

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_cnt <= 0;
        else
            if (note == d_note)
                t_cnt <= t_cnt + 1;
            else
                t_cnt <= 0;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            t_note <= no_note;
        else
            if (& t_cnt)
                t_note <= d_note;

    //------------------------------------------------------------------------
    //
    //  The output to seven segment display
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            abcdefgh <= 8'b00000000;
        else
            case (t_note)
            C  : abcdefgh <= 8'b10011100;  // C   // abcdefgh
            Cs : abcdefgh <= 8'b10011101;  // C#
            D  : abcdefgh <= 8'b01111010;  // D   //   --a--
            Ds : abcdefgh <= 8'b01111011;  // D#  //  |     |
            E  : abcdefgh <= 8'b10011110;  // E   //  f     b
            F  : abcdefgh <= 8'b10001110;  // F   //  |     |
            Fs : abcdefgh <= 8'b10001111;  // F#  //   --g--
            G  : abcdefgh <= 8'b10111100;  // G   //  |     |
            Gs : abcdefgh <= 8'b10111101;  // G#  //  e     c
            A  : abcdefgh <= 8'b11101110;  // A   //  |     |
            As : abcdefgh <= 8'b11101111;  // A#  //   --d--  h
            B  : abcdefgh <= 8'b00111110;  // B
            default : abcdefgh <= 8'b00000010;
            endcase

    assign digit = w_digit' (1);

    //------------------------------------------------------------------------
    //
    //  Exercise 4: Replace filtered note with unfiltered note.
    //  Do you see the difference?
    //
    //------------------------------------------------------------------------

    typedef enum logic [1:0] {
        CORRECT = 2'd0,
        WRONG   = 2'd1,
        NONE    = 2'd2
    } NoteState_t;
     
 
    typedef struct packed {
        logic [9:0] note_x;
        logic [8:0] note_y;
        logic [w_note - 1:0] note_name;
    } NoteData_t;

    localparam int note_count = 62;

    NoteData_t notes [note_count];

    NoteState_t note_states[note_count];

    initial begin
    for (int i = 0; i < note_count; i++)
        note_states[i] = NONE;
    end


    initial
    begin
        notes[0]  = '{note_x:  30, note_y:  22, note_name: E};
        notes[1]  = '{note_x:  90, note_y:  18, note_name: G};
        notes[2]  = '{note_x: 150, note_y:  24, note_name: D};
        notes[3]  = '{note_x: 210, note_y:  26, note_name: C};
        notes[4]  = '{note_x: 270, note_y:  24, note_name: D};
        notes[5]  = '{note_x: 330, note_y:  22, note_name: E};
        notes[6]  = '{note_x: 390, note_y:  18, note_name: G};
        notes[7]  = '{note_x: 450, note_y:  24, note_name: D};
        notes[8]  = '{note_x:  30, note_y:  52, note_name: E};
        notes[9]  = '{note_x:  90, note_y:  48, note_name: G};
        notes[10] = '{note_x: 150, note_y:  40, note_name: D};
        notes[11] = '{note_x: 210, note_y:  42, note_name: C};
        notes[12] = '{note_x: 270, note_y:  48, note_name: G};
        notes[13] = '{note_x: 330, note_y:  50, note_name: F};
        notes[14] = '{note_x: 390, note_y:  52, note_name: E};
        notes[15] = '{note_x: 450, note_y:  54, note_name: D};
        notes[16] = '{note_x:  30, note_y:  82, note_name: E};
        notes[17] = '{note_x:  90, note_y:  78, note_name: G};
        notes[18] = '{note_x: 150, note_y:  84, note_name: D};
        notes[19] = '{note_x: 210, note_y:  86, note_name: C};
        notes[20] = '{note_x: 270, note_y:  84, note_name: D};
        notes[21] = '{note_x: 330, note_y:  82, note_name: E};
        notes[22] = '{note_x: 390, note_y:  78, note_name: G};
        notes[23] = '{note_x: 450, note_y:  84, note_name: D};
        notes[24] = '{note_x:  30, note_y: 112, note_name: E};
        notes[25] = '{note_x:  90, note_y: 108, note_name: G};
        notes[26] = '{note_x: 150, note_y: 100, note_name: D};
        notes[27] = '{note_x: 210, note_y: 102, note_name: C};
        notes[28] = '{note_x: 270, note_y: 108, note_name: G};
        notes[29] = '{note_x:  30, note_y: 138, note_name: G};
        notes[30] = '{note_x:  90, note_y: 140, note_name: F};
        notes[31] = '{note_x: 150, note_y: 142, note_name: E};
        notes[32] = '{note_x: 210, note_y: 140, note_name: F};
        notes[33] = '{note_x: 270, note_y: 142, note_name: E};
        notes[34] = '{note_x: 330, note_y: 146, note_name: C};
        notes[35] = '{note_x:  30, note_y: 171, note_name: F};
        notes[36] = '{note_x:  90, note_y: 172, note_name: E};
        notes[37] = '{note_x: 150, note_y: 174, note_name: D};
        notes[38] = '{note_x: 210, note_y: 172, note_name: E};
        notes[39] = '{note_x: 270, note_y: 174, note_name: D};
        notes[40] = '{note_x: 330, note_y: 179, note_name: A};
        notes[41] = '{note_x:  30, note_y: 198, note_name: G};
        notes[42] = '{note_x:  90, note_y: 200, note_name: F};
        notes[43] = '{note_x: 150, note_y: 202, note_name: E};
        notes[44] = '{note_x: 210, note_y: 200, note_name: F};
        notes[45] = '{note_x: 270, note_y: 202, note_name: E};
        notes[46] = '{note_x: 330, note_y: 206, note_name: C};
        notes[47] = '{note_x: 390, note_y: 200, note_name: F};
        notes[48] = '{note_x: 450, note_y: 193, note_name: C};
        notes[49] = '{note_x:  30, note_y: 232, note_name: E};
        notes[50] = '{note_x:  90, note_y: 228, note_name: G};
        notes[51] = '{note_x: 150, note_y: 234, note_name: D};
        notes[52] = '{note_x: 210, note_y: 236, note_name: C};
        notes[53] = '{note_x: 270, note_y: 234, note_name: D};
        notes[54] = '{note_x: 330, note_y: 232, note_name: E};
        notes[55] = '{note_x: 390, note_y: 228, note_name: G};
        notes[56] = '{note_x: 450, note_y: 234, note_name: D};
        notes[57] = '{note_x:  30, note_y: 262, note_name: E};
        notes[58] = '{note_x:  90, note_y: 258, note_name: G};
        notes[59] = '{note_x: 150, note_y: 250, note_name: D};
        notes[60] = '{note_x: 210, note_y: 253, note_name: C};
        notes[61] = '{note_x: 270, note_y: 258, note_name: G};
    end

    typedef enum logic [1:0] {
        IDLE,
        PLAYING,
        WIN,
        FAIL
    } GameState;

    GameState game_state;

    logic [7:0] note_index;
    logic game_active;
    logic prev_key, key_pressed;
    logic [w_note - 1:0] current_note;

    always_ff @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            prev_key <= 0;
            key_pressed <= 0;
        end
        else
        begin
            prev_key <= key[0];
            key_pressed <= ~prev_key & key[0];
        end
    end
   
    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        if ( y == 9 || y == 12 || y == 16 || y == 20 || y == 24 ||
             y == 39  || y == 42  || y == 46  || y == 50  || y == 54 ||
             y == 68  || y == 72  || y == 76  || y == 80  || y == 84 ||
             y == 99  || y == 103 || y == 106 || y == 110 || y == 114 ||
             y == 129 || y == 133 || y == 137 || y == 141 || y == 144 ||
             y == 159 || y == 163 || y == 167 || y == 171 || y == 174 ||
             y == 189 || y == 193 || y == 197 || y == 201 || y == 205 ||
             y == 220 || y == 224 || y == 228 || y == 232 || y == 236 ||
             y == 248 || y == 252 || y == 256 || y == 260 || y == 264)
        begin
            red   = 100;
            green = 100;
            blue  = 0;
        end

        for (int i = 0; i < note_count; i++) begin
            if ((x - notes[i].note_x)*(x - notes[i].note_x) <= 9 &&
                (y - notes[i].note_y)*(y - notes[i].note_y) <= 4)
                 begin

                red = 255;
                green = 255;
                blue = 0;

                case (note_states[i])
                    CORRECT: begin red = 0;   green = 255; blue = 0; end
                    WRONG:   begin red = 255; green = 0;   blue = 0; end
                    default: ;
                endcase
            end
        end
    end



always_ff @(posedge clk or posedge rst)
begin
    if (rst) begin
        game_state    <= IDLE;
        note_index    <= 0;
        current_note  <= no_note;
        for (int i = 0; i < note_count; i++) begin
            notes[i].note_state <= NONE;
        end
    end else begin
        case (game_state)
            IDLE: begin
                if (key_pressed) begin
                    game_state  <= PLAYING;
                    note_index  <= 0;
                end
            end
            PLAYING: begin
                current_note <= t_note;
                if (key_pressed) begin
                    game_state <= IDLE;
                    note_index <= 0;
                end else if (current_note != no_note) begin
                    if (current_note == notes[note_index].note_name) begin
                        notes[note_index].note_state <= CORRECT;
                        if (note_index == note_count - 1)
                            game_state <= WIN;
                        else
                            note_index <= note_index + 1;
                    end else begin
                        notes[note_index].note_state <= WRONG;
                        game_state <= FAIL;
                    end
                end
            end
            WIN, FAIL: begin
                if (key_pressed) begin
                    game_state <= IDLE;
                    note_index <= 0;
                end
            end
        endcase
    end
end



    

endmodule