library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FMEAS_MIN is
 port (         clk:    	in std_logic;
    		reset:    	in std_logic;
   		freq_in:   	in std_logic;
                onmode:         in std_logic; 
   		edge_count_out: out std_logic_vector (15 downto 0));
end FMEAS_MIN;

---------------------------------------------------------------------------
architecture behavior of FMEAS_MIN is
signal edge_counter:  unsigned (15 downto 0):= "0000000000000000";
signal timer:   unsigned (19 downto 0):= "00000000000000000000";
signal reset_edge_counter: std_logic:= '0';
 --signal onmode: std_logic:= '0'; 
 signal startcountflag: std_logic:= '0';
 Signal counting_active: std_logic:= '0'; 
 signal countingflag: std_logic:= '0';
TYPE state IS (Standby, startcount, Waitack, counting); --states for timer counter
SIGNAL pr_state, nx_state: state;

TYPE edge_counter_state IS (standby, counting); -- states for edge counter
SIGNAL edge_pr_state, edge_nx_state: edge_counter_state;

begin 

P1:    PROCESS (reset, clk)
    BEGIN
        IF    (reset='1') THEN
                pr_state <= standby;
        ELSIF (clk'EVENT AND clk='1') THEN
                pr_state <= nx_state;
        END IF;
    END PROCESS;


TIMER_STATEMACHINE: PROCESS (clk) 
BEGIN
    CASE pr_state IS
        WHEN standby =>
         if (onmode = '1') then
         nx_state <= startcount;
         else nx_state <= pr_state;
         END IF;

      when startcount =>
        startcountflag <= '1';
        nx_state <= waitack;

      when waitack =>
      if (counting_active = '1') then 
      nx_state <= counting;
      else 
      nx_state <= pr_state;
      end if;

      When counting => 
 	countingflag <= '1';
        if (onmode = '0') then 
 	nx_state <= standby;
        END if;
end case;
end process;


TIMER_COUNTER: process (clk, reset)
BEGIN
if (countingflag = '1') then
    if ( reset = '1') then
     timer <= (others => '0');
     edge_count_out <= (others => '0');
     reset_edge_counter <= '0';
   elsif (rising_edge(clk)) then
     reset_edge_counter <= '0';
     timer <= timer + 1;

     
     if ( timer = X"FFFFF" ) then 
     edge_count_out <= std_logic_vector(edge_counter);
     reset_edge_counter <= '1';
  end if;
  end if;
end if;
end process;        


EDGE_COUNTER_REGISTER: PROCESS (reset, clk)
    BEGIN
        IF    (reset='1') THEN
                edge_pr_state <= standby;
                --edge_counter <= (others => '0');
        ELSIF (clk'EVENT AND clk='1') THEN
                edge_pr_state <= edge_nx_state;
        END IF;
    END PROCESS;


EDGE_COUNTER_START: process(clk)

 BEGIN
        CASE edge_pr_state IS
            WHEN standby =>
            counting_active <= '0';
            IF(startcountflag='1') THEN edge_nx_state <= counting;
            END IF;

            WHEN counting =>
            counting_active <= '1';
            IF(startcountflag='0') THEN edge_nx_state <= standby;
            END IF;
end case;
end process;

EDGE_COUNTING: PROCESS (freq_in,reset_edge_counter)

Begin

if (counting_active = '1') THEN
   if (reset_edge_counter = '1') then
    edge_counter <= (others => '0');
   elsif (rising_edge(freq_in)) then
    edge_counter <= edge_counter + 1;
  end if;
end if;

end process;


end behavior;
