library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.and_reduce;

entity PPU is
    port(
        rst, clk        : in std_logic;
        CS, r_nw        : in std_logic;
        address         : in std_logic_vector(2 downto 0);
        NMI             : out std_logic;
        hsync, vsync    : out std_logic;
        pixel_index     : out std_logic_vector(7 downto 0);
        VRAM_r_nw       : out std_logic;
        VRAM_address    : out std_logic_vector(13 downto 0);
        VRAM_data       : inout std_logic_vector(7 downto 0);
        data            : inout std_logic_vector(7 downto 0)
    );
end PPU;

architecture Behavioral of PPU is
    -- Types
    type array8_vector8 is array(7 downto 0) of std_logic_vector(7 downto 0);
    type array8_stdlogic is array(7 downto 0) of std_logic;

    -- CPU interface registers
    signal PPUCTRL, PPUMASK, PPUSTATUS, OAMADDR : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Internal registers
    signal clk_counter              : integer range 0 to 11 := 0; -- Master clock tick
    signal data_out                 : std_logic_vector(7 downto 0) := (others => '0');
    signal read_buffer              : std_logic_vector(7 downto 0) := (others => '0');
    signal OAM_secondary_address    : std_logic_vector(4 downto 0) := (others => '0');
    signal sprite_counter           : integer range 0 to 7 := 0;
    signal sprite_evaluation_active : std_logic := '0';
    signal sprite_zero_exist        : std_logic;
    signal previous_OAMADDR         : std_logic_vector(7 downto 0) := (others => '0');

    -- VRAM address registers
    signal v : std_logic_vector(14 downto 0) := (others => '0'); -- Current VRAM address
    signal t : std_logic_vector(14 downto 0) := (others => '0'); -- Temporary VRAM address
    signal x : std_logic_vector(2 downto 0) := (others => '0');  -- Fine X scroll
    signal w : std_logic := '0';                                 -- First or second write toggle    
    
    -- Timing registers
    signal cycle_counter        : integer range 0 to 340 := 0;
    signal line_counter         : integer range 0 to 261 := 0;
    signal odd_frame_flag       : std_logic := '0';
    signal byte_counter         : integer range 0 to 3 := 0;
    
    -- Temporary hold registers
    signal nametable_register, low_pattern_register, high_pattern_register  : std_logic_vector(7 downto 0) := (others => '0');
    signal attribute_register                                               : std_logic_vector(1 downto 0) := (others => '0');
    signal sprite_y_register, sprite_tile_register                          : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Rendering registers
    signal background_pattern_shifter_low, background_pattern_shifter_high             : std_logic_vector(15 downto 0) := (others => '0');
    signal background_attribute_shifter_low, background_attribute_shifter_high         : std_logic_vector(8 downto 0) := (others => '0');
    signal sprite_pattern_shifter_low, sprite_pattern_shifter_high                     : array8_vector8 := (others => (others => '0'));
    signal sprite_x_counter, sprite_attribute                                          : array8_vector8 := (others => (others => '0'));
    
    -- Internal signals
    signal palette_address_selected      : std_logic;
    signal VRAM_data_reversed            : std_logic_vector(0 to 7);
    signal VRAM_address_out              : std_logic_vector(13 downto 0);
    signal OAM_r_nw                      : std_logic;
    signal OAM_data                      : std_logic_vector(7 downto 0);
    signal OAM_secondary_r_nw            : std_logic;
    signal OAM_secondary_data            : std_logic_vector(7 downto 0);
    signal palette_r_nw                  : std_logic;
    signal palette_address               : std_logic_vector(4 downto 0);
    signal palette_data                  : std_logic_vector(7 downto 0);
    signal selected_background_pattern   : std_logic_vector(1 downto 0);
    signal selected_background_attribute : std_logic_vector(1 downto 0);
    signal selected_sprite_pattern       : std_logic_vector(1 downto 0);
    signal selected_sprite_attribute     : std_logic_vector(7 downto 0);
    signal palette_index                 : std_logic_vector(4 downto 0);
    
    -- Control signals
    -- Generic
    signal rendering_active              : std_logic;
    signal frame_start_signal            : std_logic;
    signal horizontal_start_signal       : std_logic;
    
    -- Set-Clr
    signal set_sprite_overflow, clr_sprite_overflow     : std_logic;
    signal set_sprite_zero, clr_sprite_zero             : std_logic;
    signal set_vertical_blank, clr_vertical_blank       : std_logic;
    signal set_sprite_zero_exist, clr_sprite_zero_exist : std_logic;

    -- Rendering
    signal fill_nametable_register, fill_attribute_register, fill_low_pattern_register, fill_high_pattern_register          : std_logic;
    signal fill_sprite_y_register, fill_sprite_tile_register                                                                : std_logic;
    signal fill_sprite_pattern_shifter_low, fill_sprite_pattern_shifter_high, fill_sprite_x_counter, fill_sprite_attribute  : array8_stdlogic;
    signal increment_horizontal_v, increment_vertical_v, set_horizontal_v, set_vertical_v                                   : std_logic; 
    signal move_shift_registers, reload_shift_registers                                                                     : std_logic;
    
    -- Sprite
    signal OAM_address_increment, OAM_address_increment_4, OAM_address_increment_5, OAM_address_reset   : std_logic;
    signal OAM_secondary_address_increment, OAM_secondary_address_reset                                 : std_logic;
    signal byte_counter_increment, sprite_counter_increment, sprite_counter_reset                       : std_logic;
    signal start_sprite_evaluation, stop_sprite_evaluation                                              : std_logic;
    
    -- Constants
    constant last_cycle         : integer := 340;
    constant pre_render_line    : integer := 261;
    constant zero8              : std_logic_vector(7 downto 0) := (others => '0');
    constant zero2              : std_logic_vector(1 downto 0) := (others => '0');
    
    -- Helper functions
    function select_attribute(signal v: std_logic_vector(14 downto 0); signal data: std_logic_vector(7 downto 0)) return std_logic_vector is
        variable attribute_value, attribute_position : std_logic_vector(1 downto 0);
    begin
        -- Attributes for background are 16x16 pixel and 1 byte contains 4 attributes meaning 32x32 pixel
        -- In order to select right attribute we use second bit of coarse Y and coarse X (bit 6 and 1)
        attribute_position := v(6) & v(1);
        case attribute_position is
            when "00" => -- Top left 16x16 pixel of 32x32 pixel area
                attribute_value := data(1 downto 0);
            when "01" => -- Top right 16x16 pixel of 32x32 pixel area
                attribute_value := data(3 downto 2);
            when "10" => -- Bottom left 16x16 pixel of 32x32 pixel area
                attribute_value := data(5 downto 4);
            when "11" => -- Bottom right 16x16 pixel of 32x32 pixel area
                attribute_value := data(7 downto 6);
            when others =>
                attribute_value := data(1 downto 0);
        end case;
        
        return attribute_value;
    end function;
    
    function coarse_x_increment(signal v: std_logic_vector(14 downto 0)) return std_logic_vector is 
        variable new_v : std_logic_vector(14 downto 0);
    begin
        if(v(4 downto 0) = "11111") then 
            -- If coarse X reached to end switch to next nametable
            new_v := v(14 downto 11) & (not v(10)) & v(9 downto 5) & "00000";
        else
            -- If coarse X not reached to end increment coarse X
            new_v := v + 1;
        end if;
        
        return new_v;
    end function;
    
    function y_increment(signal v: std_logic_vector(14 downto 0)) return std_logic_vector is
        variable new_v : std_logic_vector(14 downto 0);
    begin
        if(v(14 downto 12) /= "111") then
            -- If fine Y not reached to end increment it
            new_v := v + "001000000000000";
        elsif(v(9 downto 5) = "11101") then
            -- If fine Y reached to end and coarse Y reached to attribute table skip it and wrap to next nametable
            new_v := "000" & (not v(11)) & v(10) & "00000" & v(4 downto 0);
        elsif(v(9 downto 5) = "11111") then
            -- If fine Y reached to end and coarse Y reached to end of nametable wrap to begining of current nametable
            new_v := "000" & v(11 downto 10) & "00000" & v(4 downto 0);
        else
            -- If fine Y reached to end and coarse Y not reached to end increment it
            new_v := ("000" & v(11 downto 0)) + "000000000100000";
        end if;
        
        return new_v;
    end function;
begin   

    -- Structure
    process(ALL) begin
        data <= (others => 'Z');
        VRAM_r_nw <= '1';
        VRAM_data <= (others => 'Z');
        VRAM_address <= VRAM_address_out;
        palette_r_nw <= '1';
        palette_data <= (others => 'Z');
        palette_address <= '0' & palette_index(3 downto 2) & "00" when palette_index(4) = '1' and palette_index(1 downto 0) = "00" else
                           palette_index;
        OAM_r_nw <= '1';
        OAM_data <= (others => 'Z');
        VRAM_data_reversed <= VRAM_data; -- Assign reverse of VRAM_data (indexes are reversed look to declerations)
        set_sprite_zero <= '0';
        
        NMI <= '0' when PPUCTRL(7) = '1' and PPUSTATUS(7) = '1' else
               '1';
    
        palette_address_selected <= '1' when and_reduce(v(13 downto 8)) else
                                    '0';
        
        if(CS = '1') then
            if(r_nw = '1') then -- If CPU is reading use data bus
                data <= data_out;
            elsif(rendering_active = '0' and clk_counter = 5) then -- If CPU is writing and ppu doesn't use RAMs
                if(address = "111") then -- PPUDATA
                    if(palette_address_selected = '0') then -- If address corresponds to VRAM
                        VRAM_r_nw <= '0';
                        VRAM_data <= data;
                    else
                        palette_r_nw <= '0';
                        palette_data <= data;
                    end if;
                elsif(address = "100") then -- OAMDATA
                    OAM_r_nw <= '0';
                    OAM_data <= data;
                end if;
            end if;
        end if;
        
        if(rendering_active = '0') then -- If ppu doesn't use rams
            VRAM_address <= v(13 downto 0);
            if(palette_address_selected = '1') then
                palette_address <= v(4 downto 0);
            else
                palette_address <= (others => '0');
            end if;
        end if;
        
        -- Outputs of background shifters
        selected_background_pattern <= "00" when PPUMASK(3) = '0' or (2 <= cycle_counter and cycle_counter <= 9 and PPUMASK(1) = '0') else
                                       background_pattern_shifter_high(15 - conv_integer(x)) & background_pattern_shifter_low(15 - conv_integer(x));
        selected_background_attribute <= background_attribute_shifter_high(8 - conv_integer(x)) & background_attribute_shifter_low(8 - conv_integer(x));
        
        -- Outputs of sprite shifters for 8 sprites
        for i in 7 downto 0 loop
            -- Output sprite with lowest index that is active and opaque
            if(sprite_x_counter(i) = zero8 and (sprite_pattern_shifter_low(i)(7) = '1' or sprite_pattern_shifter_high(i)(7) = '1')) then 
                selected_sprite_pattern <= "00" when PPUMASK(4) = '0' or (2 <= cycle_counter and cycle_counter <= 9 and PPUMASK(2) = '0') else
                                           sprite_pattern_shifter_high(i)(7) & sprite_pattern_shifter_low(i)(7);
                selected_sprite_attribute <= sprite_attribute(i);
                
                if(sprite_zero_exist = '1' and i = 0 and selected_background_pattern = zero2) then
                    set_sprite_zero <= '1';
                end if;
            end if;
        end loop;
                    
        -- Outputs palette offset to palette memory
        palette_index <= (others => '0') when selected_background_pattern = zero2 and selected_sprite_pattern = zero2 else
                         '1' & selected_sprite_attribute(1 downto 0) & selected_sprite_pattern when selected_background_pattern = zero2 or (selected_sprite_pattern /= zero2 and selected_sprite_attribute(5) = '0') else
                         '0' & selected_background_attribute & selected_background_pattern;        
    end process;

    -- Controller
    process(clk) begin
        if(rising_edge(clk)) then 
            if(rst = '1') then
                PPUCTRL <= (others => '0');
                PPUMASK <= (others => '0');
                PPUSTATUS <= (others => '0');
                OAMADDR <= (others => '0');
                OAM_secondary_address <= (others => '0');
                sprite_counter <= 0;
                sprite_evaluation_active <= '0';
                v <= (others => '0');
                t <= (others => '0');
                x <= (others => '0');
                w <= '0';
                cycle_counter <= 0;
                line_counter <= 0;
                odd_frame_flag <= '0';
                byte_counter <= 0;
            else
                -- Master clock tick
                clk_counter <= clk_counter + 1;
            
                -- CPU tick
                if(clk_counter = 5 and CS = '1') then 
                    data_out <= (others => '0'); -- Default value send when registers are not read accessible
                    
                    case address is
                        --PPUCTRL
                        when "000" => 
                            if(r_nw = '0') then
                                PPUCTRL <= data;
                                t(11 downto 10) <= data(1 downto 0);
                            end if;
                        
                        --PPUMASK
                        when "001" => 
                            if(r_nw = '0') then
                                PPUMASK <= data;
                            end if;
                        
                        --PPUSTATUS
                        when "010" =>
                            if(r_nw = '1') then
                                data_out <= PPUSTATUS;
                                PPUSTATUS(7) <= '0';
                                w <= '0';
                            end if;
                            
                        --OAMADDR
                        when "011" =>
                            if(r_nw = '0') then
                                OAMADDR <= data;
                            end if;
                            
                        --OAMDATA
                        when "100" =>
                            if(r_nw = '1') then
                                data_out <= OAM_data;
                            else
                                OAMADDR <= OAMADDR + 1;
                            end if;
                        
                        --PPUSCROLL
                        when "101" =>
                            if(r_nw = '0') then
                                if(w = '0') then
                                    t(4 downto 0) <= data(7 downto 3);
                                    x <= data(2 downto 0);
                                    w <= '1';
                                else
                                    t(9 downto 5) <= data(7 downto 3);
                                    t(14 downto 12) <= data(2 downto 0);
                                    w <= '0';
                                end if;
                            end if;
                        
                        --PPUADDR
                        when "110" =>
                            if(r_nw = '0') then
                                if(w = '0') then
                                    t(14 downto 8) <= '0' & data(5 downto 0);
                                    w <= '1';
                                else
                                    t(7 downto 0) <= data(7 downto 0);
                                    v <= t(14 downto 8) & data(7 downto 0);
                                    w <= '0';
                                end if;
                            end if;
                        
                        --PPUDATA
                        when "111" =>
                            v <= v + 1 when PPUCTRL(2) = '0' else
                                 v + 32;
                        
                            if(r_nw = '1') then
                                read_buffer <= VRAM_data;
                                
                                if(palette_address_selected) then
                                    data_out <= palette_data;
                                else
                                    data_out <= read_buffer; 
                                end if;
                            end if;
                            
                        when others =>
                    end case;
                end if;    
            end if;  
            
            -- PPU ticks
            if(clk_counter = 3 or clk_counter = 7 or clk_counter = 11) then 
                pixel_index <= palette_data;
                vsync <= frame_start_signal;
                hsync <= horizontal_start_signal;
            
                PPUSTATUS(5) <= '1' when set_sprite_overflow = '1' else
                                '0' when clr_sprite_overflow = '1';
                                
                PPUSTATUS(6) <= '1' when set_sprite_zero = '1' else
                                '0' when clr_sprite_zero = '1';
    
                PPUSTATUS(7) <= '1' when set_vertical_blank = '1' else
                                '0' when clr_vertical_blank = '1';
                                
                OAMADDR <= OAMADDR + 1 when OAM_address_increment = '1' else
                           OAMADDR + 4 when OAM_address_increment_4 = '1' else
                           OAMADDR + 5 when OAM_address_increment_5 = '1' else
                           (others => '0') when OAM_address_reset = '1';
                           
                previous_OAMADDR <= OAMADDR;
                           
                OAM_secondary_address <= OAM_secondary_address + 1 when OAM_secondary_address_increment = '1' else
                                         (others => '0') when OAM_secondary_address_reset = '1';
                
                byte_counter <= byte_counter + 1 when byte_counter_increment = '1';
                
                sprite_counter <= sprite_counter + 1 when sprite_counter_increment = '1' else
                                0 when sprite_counter_reset = '1';
                                
                sprite_evaluation_active <= '1' when start_sprite_evaluation = '1' else
                                            '0' when stop_sprite_evaluation = '1';
                                            
                sprite_zero_exist <= '1' when set_sprite_zero_exist = '1' else
                                     '0' when clr_sprite_zero_exist = '1';
                                
                nametable_register <= VRAM_data when fill_nametable_register = '1';
                attribute_register <= select_attribute(v, VRAM_data) when fill_attribute_register = '1';
                low_pattern_register <= VRAM_data when fill_low_pattern_register = '1';
                high_pattern_register <= VRAM_data when fill_high_pattern_register = '1';
                
                sprite_y_register <= OAM_secondary_data when fill_sprite_y_register = '1';
                sprite_tile_register <= OAM_secondary_data when fill_sprite_tile_register = '1';
                for i in 0 to 7 loop
                    sprite_attribute(i) <= OAM_secondary_data when fill_sprite_attribute(i) = '1';
                    sprite_x_counter(i) <= OAM_secondary_data when fill_sprite_x_counter(i) = '1';
                    sprite_pattern_shifter_low(i) <= VRAM_data when fill_sprite_pattern_shifter_low(i) = '1' and sprite_attribute(i)(6) = '0' else
                                                     VRAM_data_reversed when fill_sprite_pattern_shifter_low(i) = '1' and sprite_attribute(i)(6) = '1';
                    sprite_pattern_shifter_high(i) <= VRAM_data when fill_sprite_pattern_shifter_high(i) = '1' and sprite_attribute(i)(6) = '0' else
                                                      VRAM_data_reversed when fill_sprite_pattern_shifter_low(i) = '1' and sprite_attribute(i)(6) = '1';
                end loop;
                                
                v <= coarse_x_increment(v) when increment_horizontal_v = '1' else
                     y_increment(v) when increment_vertical_v = '1' else
                     v(14 downto 11) & t(10) & v(9 downto 5) & t(4 downto 0) when set_horizontal_v = '1' else
                     t(14 downto 11) & v(10) & t(9 downto 5) & v(4 downto 0) when set_vertical_v = '1';
                
                if(move_shift_registers) then
                    background_pattern_shifter_low <= background_pattern_shifter_low(14 downto 7) & low_pattern_register when reload_shift_registers else
                                                      background_pattern_shifter_low(14 downto 0) & '0';
                    background_pattern_shifter_high <= background_pattern_shifter_high(14 downto 7) & high_pattern_register when reload_shift_registers else
                                                       background_pattern_shifter_high(14 downto 0) & '0';
                                                   
                    background_attribute_shifter_low <= background_attribute_shifter_low(7 downto 0) & attribute_register(0) when reload_shift_registers else
                                                        background_attribute_shifter_low(7 downto 0) & background_attribute_shifter_low(0);
                    background_attribute_shifter_high <= background_attribute_shifter_high(7 downto 0) & attribute_register(1) when reload_shift_registers else
                                                         background_attribute_shifter_high(7 downto 0) & background_attribute_shifter_high(0);
                                                     
                    for i in 0 to 7 loop
                        sprite_x_counter(i) <= sprite_x_counter(i) - 1 when sprite_x_counter(i) /= zero8;
                        sprite_pattern_shifter_low(i) <= sprite_pattern_shifter_low(i)(6 downto 0) & '0' when sprite_x_counter(i) = zero8;
                        sprite_pattern_shifter_high(i) <= sprite_pattern_shifter_high(i)(6 downto 0) & '0' when sprite_x_counter(i) = zero8;
                    end loop;
                end if;
                                
                if(line_counter = pre_render_line and cycle_counter = last_cycle and odd_frame_flag = '1') then
                    cycle_counter <= 1;
                    line_counter <= 0;
                    odd_frame_flag <= '0';
                elsif(line_counter = pre_render_line and cycle_counter = last_cycle and odd_frame_flag = '0') then
                    cycle_counter <= 0;
                    line_counter <= 0;
                    odd_frame_flag <= '1';
                else
                    cycle_counter <= cycle_counter + 1;
                    line_counter <= line_counter + 1 when cycle_counter = 340;
                end if;
            end if;  
        end if;
    end process;
    
    -- Renderer Decoder
    process(ALL) 
        variable render_lines, fetch_cycles, shift_cycles, sprite_cycles, frame_start, horizontal_start  : boolean;
        variable secondary_oam_clear_cycles, sprite_evaluation_cycles, first_sprite_evaluation_cycles    : boolean;
        variable vertical_increment_cycle, vertical_set_cycles, horizontal_set_cycle                     : boolean;
        variable vblank_set_cycle, flag_clr_cycle                                                        : boolean;
        
        variable sprite_length : integer range 0 to 16;
        variable tile_y_offset : std_logic_vector(7 downto 0);
    begin
        -- Helper Signals
        render_lines                   := ((0 <= line_counter) and (line_counter <= 239)) or line_counter = pre_render_line;
        frame_start                    := line_counter = 0 and cycle_counter = 2;
        horizontal_start               := cycle_counter = 2;
        fetch_cycles                   := ((1 <= cycle_counter) and (cycle_counter <= 340));
        shift_cycles                   := ((2 <= cycle_counter) and (cycle_counter <= 257)) or ((322 <= cycle_counter) and (cycle_counter <= 337));
        sprite_cycles                  := (257 <= cycle_counter) and (cycle_counter <= 320);
        secondary_oam_clear_cycles     := line_counter /= pre_render_line and (1 <= cycle_counter) and (cycle_counter <= 64);
        sprite_evaluation_cycles       := line_counter /= pre_render_line and (65 <= cycle_counter) and (cycle_counter <= 256);
        first_sprite_evaluation_cycles := line_counter /= pre_render_line and cycle_counter = 65;
        vertical_increment_cycle       := cycle_counter = 256;
        vertical_set_cycles            := line_counter = pre_render_line and (280 <= cycle_counter) and (cycle_counter <= 304);
        horizontal_set_cycle           := cycle_counter = 257;
        vblank_set_cycle               := line_counter = 241 and cycle_counter = 1;
        flag_clr_cycle                 := line_counter = pre_render_line and cycle_counter = 1;
        
        sprite_length := 8 when PPUCTRL(5) = '0' else
                         16;
                         
        tile_y_offset := conv_std_logic_vector(line_counter - conv_integer(unsigned(sprite_y_register)), tile_y_offset'length) when sprite_attribute(sprite_counter)(7) = '1' else
                         conv_std_logic_vector(sprite_length + conv_integer(unsigned(sprite_y_register)) - line_counter - 1, tile_y_offset'length);

        -- Default Signals
        VRAM_address_out <= v(13 downto 0);
        OAM_secondary_r_nw <= '1';
        OAM_secondary_data <= (others => 'Z');
        
        rendering_active <= '0';
        frame_start_signal <= '0';
        horizontal_start_signal <= '0';
        
        set_sprite_overflow <= '0'; clr_sprite_overflow <= '0';
        set_sprite_zero <= '0'; clr_sprite_zero <= '0';
        set_vertical_blank <= '0'; clr_vertical_blank <= '0';
        set_sprite_zero_exist <= '0'; clr_sprite_zero_exist <= '0';
    
        fill_nametable_register <= '0'; fill_attribute_register <= '0'; fill_low_pattern_register <= '0'; fill_high_pattern_register <= '0';
        fill_sprite_y_register <= '0'; fill_sprite_tile_register <= '0';
        for i in 0 to 7 loop 
            fill_sprite_pattern_shifter_low(i) <= '0'; fill_sprite_pattern_shifter_high(i) <= '0'; fill_sprite_x_counter(i) <= '0'; fill_sprite_attribute(i) <= '0';
        end loop;
        increment_horizontal_v <= '0'; increment_vertical_v <= '0'; set_horizontal_v <= '0'; set_vertical_v <= '0';
        move_shift_registers <= '0'; reload_shift_registers <= '0';
        
        OAM_address_increment <= '0'; OAM_address_increment_4 <= '0'; OAM_address_increment_5 <= '0'; OAM_address_reset <= '0';
        OAM_secondary_address_increment <= '0'; OAM_secondary_address_reset <= '0';
        byte_counter_increment <= '0'; sprite_counter_increment <= '0'; sprite_counter_reset <= '0';
        start_sprite_evaluation <= '0'; stop_sprite_evaluation <= '0';
        
        -- Decoder Logic
        if(vblank_set_cycle) then
            set_vertical_blank <= '1';
        elsif(render_lines and PPUMASK(3) = '1' and PPUMASK(4) = '1') then     
            rendering_active <= '1';
            
            if(cycle_counter = 0) then
                OAM_secondary_address_reset <= '1';
            elsif(cycle_counter = 320) then
                OAM_address_reset <= '1';
            end if;
            
            if(frame_start) then
                frame_start_signal <= '1';
            end if;
            
            if(horizontal_start) then
                horizontal_start_signal <= '1';
            end if;

            if(flag_clr_cycle) then
                clr_sprite_overflow <= '1';
                clr_sprite_zero <= '1';
                clr_vertical_blank <= '1';
            end if;
        
            if(vertical_set_cycles) then
                set_vertical_v <= '1';
            end if;
           
            if(fetch_cycles) then          
                if(horizontal_set_cycle) then
                    set_horizontal_v <= '1';
                end if;
                
                if(shift_cycles) then
                    move_shift_registers <= '1';
                end if;
            
                case conv_std_logic_vector(cycle_counter-1, 3) is
                    when "000" => -- Nametable fetch, sprite y coordinate fetch
                        VRAM_address_out <= "10" & v(11 downto 0);
                        fill_nametable_register <= '1';
                        if(shift_cycles) then
                            reload_shift_registers <= '1';
                        end if;
                        if(sprite_cycles) then
                            fill_sprite_y_register <= '1';
                            OAM_secondary_address_increment <= '1';
                        end if;
                        
                    when "001" => -- Sprite tile index fetch
                        if(sprite_cycles) then
                            fill_sprite_tile_register <= '1';
                            OAM_secondary_address_increment <= '1';
                        end if;
                        
                    when "010" => -- Background attribute fetch, sprite attribute fetch
                        VRAM_address_out <= "10" & v(11 downto 10) & "1111" & v(9 downto 7) & v(4 downto 2);
                        fill_attribute_register <= '1';
                        if(sprite_cycles) then
                            fill_sprite_attribute(sprite_counter) <= '1';
                            OAM_secondary_address_increment <= '1';
                        end if;
                        
                    when "011" => -- Sprite x coordinate fetch
                        if(sprite_cycles) then
                            fill_sprite_x_counter(sprite_counter) <= '1';
                            OAM_secondary_address_increment <= '1';
                        end if;
                        
                    when "100" => -- Background low pattern fetch, sprite low pattern fetch
                        if(sprite_cycles) then
                            VRAM_address_out <= '0' & PPUCTRL(3) & sprite_tile_register & '0' & tile_y_offset(2 downto 0) when PPUCTRL(5) = '0' else
                                                '0' & sprite_tile_register(0) & sprite_tile_register(7 downto 1) & tile_y_offset(3) & '0' & tile_y_offset(2 downto 0);
                            fill_sprite_pattern_shifter_low(sprite_counter) <= '1';
                        else
                            VRAM_address_out <= '0' & PPUCTRL(4) & nametable_register & '0' & v(14 downto 12);
                            fill_low_pattern_register <= '1';
                        end if;
                        
                    when "101" => 
                        -- Not necessary because RAM access take 1 cycle for this implementation (2 cycle on real PPU)
                    
                    when "110" => -- Background high pattern fetch, sprite high pattern fetch
                        if(sprite_cycles) then
                            VRAM_address_out <= '0' & PPUCTRL(3) & sprite_tile_register & '1' & tile_y_offset(2 downto 0) when PPUCTRL(5) = '0' else
                                                '0' & sprite_tile_register(0) & sprite_tile_register(7 downto 1) & tile_y_offset(3) & '1' & tile_y_offset(2 downto 0);
                            fill_sprite_pattern_shifter_high(sprite_counter) <= '1';
                            sprite_counter_increment <= '1';
                        else
                            VRAM_address_out <= '0' & PPUCTRL(4) & nametable_register & '1' & v(14 downto 12);
                            fill_high_pattern_register <= '1';
                        end if;                      
                    
                    when "111" =>
                        if(not sprite_cycles) then
                            if(vertical_increment_cycle) then
                                increment_vertical_v <= '1';
                            else
                                increment_horizontal_v <= '1';
                            end if;
                        end if;
                    
                    when others =>
                end case;
                
                if(secondary_oam_clear_cycles) then 
                    OAM_secondary_r_nw <= '0';
                    OAM_secondary_data <= x"FF";
                    OAM_secondary_address_increment <= '1';
                    clr_sprite_zero_exist <= '1';
                end if;
                
                if(sprite_evaluation_cycles) then                                     
                    if(not first_sprite_evaluation_cycles and OAMADDR < previous_OAMADDR) then 
                        stop_sprite_evaluation <= '1';
                    end if;
                    
                    if(sprite_evaluation_active = '1') then
                        if((byte_counter = 0 and (OAM_data <= line_counter) and (line_counter < OAM_data + sprite_length)) or byte_counter /= 0) then
                            if(sprite_counter < 8) then
                                if(first_sprite_evaluation_cycles) then
                                    set_sprite_zero_exist <= '1';
                                end if;
                            
                                sprite_counter_increment <= '1' when byte_counter = 3;
                                
                                OAM_secondary_r_nw <= '0';
                                OAM_secondary_data <= OAM_data;
                                OAM_address_increment <= '1';
                                OAM_secondary_address_increment <= '1';
                                byte_counter_increment <= '1';
                            else
                                set_sprite_overflow <= '1';
                                stop_sprite_evaluation <= '1';
                            end if;
                        else
                            if(sprite_counter < 8) then
                                OAM_address_increment_4 <= '1';
                            else
                                OAM_address_increment_5 <= '1'; -- Glitchy increment (Hardware Bug)
                            end if;
                        end if;
                    else
                        OAM_secondary_address_reset <= '1';
                        sprite_counter_reset <= '1';
                        OAM_address_increment_4 <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Internal RAMS
    OAM: entity work.RAM
    generic map(
        ADDRESS_WIDTH => 8
    )
    port map(
        clk     => clk,
        WE      => not OAM_r_nw,
        CS      => std_logic'('1'),
        address => OAMADDR,
        data    => OAM_data
    );
    
    OAM_secondary: entity work.RAM
    generic map(
        ADDRESS_WIDTH => 5
    )
    port map(
        clk     => clk,
        WE      => not OAM_secondary_r_nw,
        CS      => std_logic'('1'),
        address => OAM_secondary_address,
        data    => OAM_secondary_data
    );
    
    palette_memory: entity work.RAM
    generic map(
        ADDRESS_WIDTH => 5
    )
    port map(
        clk     => clk,
        WE      => not palette_r_nw,
        CS      => std_logic'('1'),
        address => palette_address,
        data    => palette_data
    );

end Behavioral;





















