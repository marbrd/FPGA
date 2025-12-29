-- fichier à écraser avec le fichier de test généré par ISE (New Source)
-- le nom du composant de test doit être TestOpl (respect minuscules/majuscules)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TestOpl is
end TestOpl;

architecture behavioral of TestOpl is

    component MasterOpl 
        port ( rst : in std_logic;
            clk : in std_logic;
            en : in std_logic;
            v1 : in std_logic_vector (7 downto 0);
            v2 : in std_logic_vector(7 downto 0);
            miso : in std_logic;
            ss   : out std_logic;
            sclk : out std_logic;
            mosi : out std_logic;
            val_nand : out std_logic_vector (7 downto 0);
            val_nor : out std_logic_vector (7 downto 0);
            val_xor : out std_logic_vector (7 downto 0);
            busy : out std_logic);
    end component;

    component SlaveOpl 
    port(
        sclk : in  std_logic;
        mosi : in  std_logic;
        miso : out std_logic;
        ss   : in  std_logic
    );
    end component;

    -- inputsMaster
    signal reset : std_logic := '0';
    signal clk : std_logic := '0';
    signal en : std_logic := '0';
    signal v1 : std_logic_vector(7 downto 0) := (others => '0');
    signal v2 : std_logic_vector(7 downto 0) := (others => '0');
    signal miso : std_logic := '0';

    -- outputsMaster
    signal ss : std_logic;
    signal sclk : std_logic;
    signal mosi : std_logic;
    signal val_nand : std_logic_vector(7 downto 0);
    signal val_nor : std_logic_vector(7 downto 0);
    signal val_xor : std_logic_vector(7 downto 0);
    signal busy : std_logic;

    -- Clock period definitions
    constant clk_period : time := 10 ns;

begin

    InstMaster : MasterOpl 
    port map ( rst => reset,
            clk => clk,
            en => en,
            v1 => v1,
            v2 => v2,
            miso => miso,
            ss => ss,
            sclk => sclk,
            mosi => mosi,
            val_nand => val_nand,
            val_nor => val_nor,
            val_xor => val_xor,
            busy => busy);

    InstSlave : SlaveOpl
    port map ( sclk => sclk,
            mosi => mosi,
            miso => miso,
            ss => ss);
            
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;


    -- Stimulus process
    stim_proc: process
    begin                
        -- hold reset state for 100 ns.
        wait for 100 ns;  
        reset <= '1';

        wait for clk_period*10;

        -- nand "11111111"  0xFF
        -- nor  "00000000"  0x0
        -- xor  "11111111"  0xFF
        v1 <= "10110101";
        v2 <= "01001010";

        en <= '1';

        wait for clk_period;

        v1 <= (others => 'U');
        v2 <= (others => 'U');
        en <= '0';

        wait for 80*clk_period;

        -- nand "10011111" 0x9F
        -- nor  "00010011" 0x13
        -- xor  "10001100" 0x8C
        v1 <= "11100100";
        v2 <= "01101000";

        en <= '1';

        wait for clk_period;

        v1 <= (others => 'U');
        v2 <= (others => 'U');
        en <= '0';

        wait for 80*clk_period;

        -- nand "10010111" 0x97
        -- nor  "00000000" 0x0
        -- xor  "10010111" 0x97
        v1 <= "11111111";
        v2 <= "01101000";

        en <= '1';

        wait for clk_period;

        v1 <= (others => 'U');
        v2 <= (others => 'U');
        en <= '0';

        wait for 80*clk_period;

        -- nand "11111111" 0xFF
        -- nor  "11111111" 0xFF
        -- xor  "00000000" 0x0
        v1 <= "00000000";
        v2 <= "00000000";

        en <= '1';

        wait for clk_period;

        v1 <= (others => 'U');
        v2 <= (others => 'U');
        en <= '0';

        wait for 80*clk_period;

        -- nand "11011011" 0xDB
        -- nor  "00001001" 0x09
        -- xor  "11010010" 0xD2
        v1 <= "10110110";
        v2 <= "01100100";

        en <= '1';

        wait for clk_period;

        v1 <= (others => 'U');
        v2 <= (others => 'U');
        en <= '0';

        wait for 80*clk_period;

        -- pour recupérer les résultats des derniers octets
        v1 <= "00000000";
        v2 <= "00000000";

        en <= '1';

        wait for clk_period;

        v1 <= (others => 'U');
        v2 <= (others => 'U');
        en <= '0';

        wait;
    end process;

end behavioral;