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
    //   assign red        = '0;
    //   assign green      = '0;
    //   assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;

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

    localparam freq_100_A1  = 44000,
               freq_100_A1s = 46616,
               freq_100_B1  = 49388,
               freq_100_C   = 52325,
               freq_100_Cs  = 55437,
               freq_100_D   = 58733,
               freq_100_Ds  = 62225,
               freq_100_E   = 65926,
               freq_100_F   = 69846,
               freq_100_Fs  = 73999,
               freq_100_G   = 78399,
               freq_100_Gs  = 83061,
               freq_100_A   = 88000,
               freq_100_As  = 93233,
               freq_100_B   = 98777;
               freq_100_C1  = 104650;
               freq_100_C1s = 110870;
               freq_100_D1  = 117410;
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

    wire check_A1   = check_freq (freq_100_A1  , distance );
    wire check_A1s  = check_freq (freq_100_A1s  , distance );
    wire check_B1   = check_freq (freq_100_B1  , distance );
    wire check_C    = check_freq (freq_100_C  , distance );
    wire check_Cs   = check_freq (freq_100_Cs , distance );
    wire check_D    = check_freq (freq_100_D  , distance );
    wire check_Ds   = check_freq (freq_100_Ds , distance );
    wire check_E    = check_freq (freq_100_E  , distance );
    wire check_F    = check_freq (freq_100_F  , distance );
    wire check_Fs   = check_freq (freq_100_Fs , distance );
    wire check_G    = check_freq (freq_100_G  , distance );
    wire check_Gs   = check_freq (freq_100_Gs , distance );
    wire check_A    = check_freq (freq_100_A  , distance );
    wire check_As   = check_freq (freq_100_As , distance );
    wire check_B    = check_freq (freq_100_B  , distance );
    wire check_C1   = check_freq (freq_100_C1  , distance );
    wire check_C1s  = check_freq (freq_100_C1s  , distance );
    wire check_D1   = check_freq (freq_100_D1  , distance );

    //------------------------------------------------------------------------

    localparam w_note = 18;

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

    // always_ff @ (posedge clk or posedge rst)
    //     if (rst)
    //         abcdefgh <= 8'b00000000;
    //     else
    //         case (t_note)
    //         C  : abcdefgh <= 8'b10011100;  // C   // abcdefgh
    //         Cs : abcdefgh <= 8'b10011101;  // C#
    //         D  : abcdefgh <= 8'b01111010;  // D   //   --a--
    //         Ds : abcdefgh <= 8'b01111011;  // D#  //  |     |
    //         E  : abcdefgh <= 8'b10011110;  // E   //  f     b
    //         F  : abcdefgh <= 8'b10001110;  // F   //  |     |
    //         Fs : abcdefgh <= 8'b10001111;  // F#  //   --g--
    //         G  : abcdefgh <= 8'b10111100;  // G   //  |     |
    //         Gs : abcdefgh <= 8'b10111101;  // G#  //  e     c
    //         A  : abcdefgh <= 8'b11101110;  // A   //  |     |
    //         As : abcdefgh <= 8'b11101111;  // A#  //   --d--  h
    //         B  : abcdefgh <= 8'b00111110;  // B
    //         default : abcdefgh <= 8'b00000010;
    //         endcase

    assign digit = w_digit' (1);

// OUR CODE STARTS HERE -----------------------------=====================================<<<<<<<<<<<<<<<<<<<<<<<<

    
    typedef struct packed {
        logic [9:0] note_x;
        logic [8:0] note_y;
        logic [w_note - 1:0] note_name;
    } NoteData_t;

    localparam int note_count = 62;


    NoteData_t notes [note_count] =
    '{
        //8
        '{note_x:  40, note_y: 100, note_name: E },
        '{note_x: 120, note_y:  95, note_name: G },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: C },
        '{note_x: 360, note_y: 100, note_name: D },
        '{note_x: 440, note_y: 105, note_name: E },
        '{note_x: 520, note_y: 110, note_name: G },
        '{note_x: 600, note_y: 115, note_name: D },
        //8
        '{note_x:  40, note_y: 100, note_name: E },
        '{note_x: 120, note_y:  95, note_name: G },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: C },
        '{note_x: 360, note_y: 100, note_name: G },
        '{note_x: 440, note_y: 105, note_name: F },
        '{note_x: 520, note_y: 110, note_name: E },
        '{note_x: 600, note_y: 115, note_name: D },
        //8
        '{note_x:  40, note_y: 100, note_name: E },
        '{note_x: 120, note_y:  95, note_name: G },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: C },
        '{note_x: 360, note_y: 100, note_name: D },
        '{note_x: 440, note_y: 105, note_name: E },
        '{note_x: 520, note_y: 110, note_name: G },
        '{note_x: 600, note_y: 115, note_name: D },
        //5
        '{note_x:  40, note_y: 100, note_name: E },
        '{note_x: 120, note_y:  95, note_name: G },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: C },
        '{note_x: 360, note_y: 100, note_name: G },
        //6
        '{note_x:  40, note_y: 100, note_name: G },
        '{note_x: 120, note_y:  95, note_name: F },
        '{note_x: 200, note_y:  90, note_name: E },
        '{note_x: 280, note_y:  95, note_name: F },
        '{note_x: 360, note_y: 100, note_name: E },
        '{note_x: 440, note_y: 105, note_name: C },
        //6
        '{note_x:  40, note_y: 100, note_name: F },
        '{note_x: 120, note_y:  95, note_name: E },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: E },
        '{note_x: 360, note_y: 100, note_name: D },
        '{note_x: 440, note_y: 105, note_name: A },
        //8
        '{note_x:  40, note_y: 100, note_name: G },
        '{note_x: 120, note_y:  95, note_name: F },
        '{note_x: 200, note_y:  90, note_name: E },
        '{note_x: 280, note_y:  95, note_name: F },
        '{note_x: 360, note_y: 100, note_name: E },
        '{note_x: 440, note_y: 105, note_name: C },
        '{note_x: 520, note_y: 110, note_name: F },
        '{note_x: 600, note_y: 115, note_name: C },
        //8
        '{note_x:  40, note_y: 100, note_name: E },
        '{note_x: 120, note_y:  95, note_name: G },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: C },
        '{note_x: 360, note_y: 100, note_name: D },
        '{note_x: 440, note_y: 105, note_name: E },
        '{note_x: 520, note_y: 110, note_name: G },
        '{note_x: 600, note_y: 115, note_name: D },
        //5
        '{note_x:  40, note_y: 100, note_name: E },
        '{note_x: 120, note_y:  95, note_name: G },
        '{note_x: 200, note_y:  90, note_name: D },
        '{note_x: 280, note_y:  95, note_name: C },
        '{note_x: 360, note_y: 100, note_name: G }
    };

    function logic is_in_circle(
        input int pixel_x,    
        input int pixel_y,    
        input int circle_cx,  
        input int circle_cy,  
        input int radius     
    );
        int dx = pixel_x - circle_cx;
        int dy = pixel_y - circle_cy;
        int r_squared = radius * radius;
        is_in_circle = (dx * dx + dy * dy) <= r_squared;
    endfunction

    always_ff @(posedge clk) begin
        red   = 0;
        green = 0;
        blue  = 0;
        

        if ( y == 15  || y == 22  || y == 29  || y == 36  || y == 43  ||
             y == 68  || y == 75  || y == 82  || y == 89  || y == 96  ||
             y == 121 || y == 128 || y == 135 || y == 142 || y == 149 ||
             y == 174 || y == 181 || y == 188 || y == 195 || y == 202 ||
             y == 227 || y == 234 || y == 241 || y == 248 || y == 255 ||
             y == 280 || y == 287 || y == 294 || y == 301 || y == 308 ||
             y == 333 || y == 340 || y == 347 || y == 354 || y == 361 ||
             y == 386 || y == 393 || y == 400 || y == 407 || y == 414 ||
             y == 439 || y == 446 || y == 453 || y == 460 || y == 467 )
        begin
            red   = 32;
            green = 32;
        end

        for (int i = 0; i < note_count; i++) begin
            if (is_in_circle(x, y, notes[i].note_x, notes[i].note_y, 3)) begin
                if (game_active && i == note_index) begin
                    if (show_success)
                        red = 0;
                    else if (show_failure)
                        green = 0;
                end else begin
                    red = 32;
                    green = 32;
                end
            end
        end
            
    end
    
//Game
    typedef enum logic [1:0] {
        IDLE,
        PLAYING,
        WIN,
        FAIL
    } GameState;

    GameState game_state;

    logic [6:0] note_index;
    logic game_active;
    logic prev_key, key_pressed;
    logic show_success, show_failure;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_key     <= 0;
            key_pressed  <= 0;
        end else begin
            prev_key     <= key[0];
            key_pressed  <= ~prev_key & key[0];
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            game_state   <= IDLE;
            note_index   <= 0;
            game_active  <= 0;
            show_success <= 0;
            show_failure <= 0;
        end else begin
            case (game_state)

                IDLE: begin
                    show_success <= 0;
                    show_failure <= 0;
                    if (key_pressed) begin
                        game_active <= 1;
                        game_state <= PLAYING;
                        note_index <= 0;
                    end
                end

                PLAYING: begin
                    if (key_pressed) begin
                        game_state <= IDLE;
                        game_active <= 0;
                    end else if (t_note != no_note) begin
                        if (t_note == notes[note_index].note_name) begin
                            show_success <= 1;
                            show_failure <= 0;
                            if (note_index == note_count - 1) begin
                                game_state <= WIN;
                            end else begin
                                note_index <= note_index + 1;
                            end
                        end else begin
                            show_success <= 0;
                            show_failure <= 1;
                            game_state <= FAIL;
                        end
                    end
                end

                FAIL: begin
                    note_index <= 0;
                    if (key_pressed) begin
                     game_state <= IDLE;
                    end
                end

                WIN: begin
                    if (key_pressed) begin
                         game_state <= IDLE;
                    end
                end

            endcase
        end
    end


endmodule
