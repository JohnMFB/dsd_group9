LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY hexcalc IS
	PORT (
		clk_50MHz : IN STD_LOGIC; -- system clock (50 MHz)
		SEG7_anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- anodes of eight 7-seg displays
		SEG7_seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0); -- common segments of 7-seg displays
        btn_center : IN STD_LOGIC; -- Start game
        btn_up : IN STD_LOGIC; -- User input for up arrow
        btn_left : IN STD_LOGIC; -- User input for left arrow
        btn_right : IN STD_LOGIC; -- User input for right arrow
        btn_down : IN STD_LOGIC -- User input for down arrow
        );
END hexcalc;

ARCHITECTURE Behavioral OF hexcalc IS

	COMPONENT leddec16 IS
		PORT (
			dig : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			data : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
		);
	END COMPONENT;
    constant MAX_SEQ_LEN : integer := 19;
    type seq_type is array (0 to MAX_SEQ_LEN) of integer range 1 to 3; -- Adjust the range based on your display needs
    signal sequence : seq_type := (1, 3, 2, 1, 2, 3, 1, 2, 3, 2, 1, 3, 2, 1, 3, 2, 1, 3, 2, 1);
	SIGNAL display : std_logic_vector (15 DOWNTO 0); -- value to be displayed
	SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0); -- 7-seg multiplexing clock
	TYPE state_type IS (IDLE, DISPLAY_SEQ, USER_INPUT, CHECK_INPUT, SHOW_RESULT);
	SIGNAL next_state, current_state : state_type := IDLE; -- present and next states
	SIGNAL seq_index : integer range 0 to 3 := 0;
		SIGNAL cnt : std_logic_vector(20 DOWNTO 0); -- counter to generate timing signals
	signal delay_counter: integer := 0;
BEGIN

	Clock : PROCESS (clk_50MHz)--display and timing
	BEGIN
		IF rising_edge(clk_50MHz) THEN -- on rising edge of clock
			cnt <= cnt + 1; -- increment counter
		END IF;
	END PROCESS;
	
	led_mpx <= cnt(19 DOWNTO 17); -- 7-seg multiplexing clock
	
    led1 : leddec16
    PORT MAP(
        dig => led_mpx, data => display, 
        anode => SEG7_anode, seg => SEG7_seg
    );
    FSM_Clock : PROCESS
    BEGIN
    WAIT UNTIL rising_edge(clk_50MHz);
    current_state <= next_state;
    END PROCESS;
		MEMORYGAMEFSM : PROCESS -- state machine clock process
		BEGIN
		    wait until rising_edge(clk_50MHz);
			
			
			CASE current_state IS -- depending on present state...
				WHEN IDLE => -- waiting for next digit in 1st operand entry
					IF btn_center = '1' THEN
					   next_state <= DISPLAY_SEQ;
					   seq_index <= 0;
					   display <= "0000000000000000";
					ELSE
					   next_state <= IDLE;
					END IF;					
                -- Assuming each display corresponds to 4 bits (a single hex digit), and only displays '1'
                    WHEN DISPLAY_SEQ =>
    IF delay_counter < 50000000 THEN
        delay_counter <= delay_counter + 1;  -- Continue counting
    ELSE
        delay_counter <= 0;  -- Reset counter for next display update
        -- Clear previous display
        display <= (others => '0');
        -- Update display according to the sequence
        CASE seq_index IS
            WHEN 0 =>
                display((0*4+3) DOWNTO (0*4)) <= "0001";  -- Display '1' at position 1 (100)
            WHEN 1 =>
                display((1*4+3) DOWNTO (1*4)) <= "0001";  -- Display '1' at position 2 (010)
            WHEN 2 =>
                display((2*4+3) DOWNTO (2*4)) <= "0001";  -- Display '1' at position 3 (001)
            WHEN OTHERS =>
                display <= (others => '0');
        END CASE;
        
        IF seq_index < MAX_SEQ_LEN THEN
            seq_index <= seq_index + 1;
        ELSE
            next_state <= USER_INPUT;  -- Move to user input after last display
            seq_index <= 0;  -- Reset index for user input checking
        END IF;
    END IF;
				WHEN USER_INPUT =>
                    -- Check user input according to sequence
                    IF (btn_left = '1' AND sequence(seq_index) = 1) OR
                       (btn_center = '1' AND sequence(seq_index) = 2) OR
                       (btn_right = '1' AND sequence(seq_index) = 3) THEN
                        IF seq_index < MAX_SEQ_LEN THEN
                            seq_index <= seq_index + 1;  -- Move to next in sequence
                        ELSE
                            next_state <= CHECK_INPUT;  -- All inputs received, check them
                        END IF;
                    ELSE
                        -- Optional: handle wrong input, possibly reset or indicate error
                        display <= (others => '1');  -- Example: turn all segments on to indicate error
                        next_state <= IDLE;  -- Reset game
                    END IF;
				WHEN SHOW_RESULT => -- waiting for next digit in 2nd operand
                    IF btn_center = '1' THEN
                        next_state <= IDLE;
                    ELSE
                        next_state <= SHOW_RESULT;
                    END IF;
                WHEN OTHERS =>
                    next_state <= IDLE;
			END CASE;
			
		END PROCESS;
END Behavioral;
