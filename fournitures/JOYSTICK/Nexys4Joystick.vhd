library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity Nexys4Joystick is
  port (
    -- les 16 switchs
    sw : in std_logic_vector (15 downto 0);
    -- les 5 boutons noirs
    btnC, btnU, btnL, btnR, btnD : in std_logic;
    -- horloge
    mclk : in std_logic;
    -- les 16 leds
    led : out std_logic_vector (15 downto 0);
    -- les anodes pour sélectionner les afficheurs 7 segments à utiliser
    an : out std_logic_vector (7 downto 0);
    -- valeur affichée sur les 7 segments (point décimal compris, segment 7)
    seg : out std_logic_vector (7 downto 0);   
    -- l'indicateur d'initiation de la transmission
    ss : out std_logic;
    -- master output, slave input
    mosi : out std_logic;
    -- master input, slave output
    miso : in std_logic;
    -- horloge pour l’échange
    sclk : out std_logic
  );
end Nexys4Joystick;

architecture synthesis of Nexys4Joystick is

  component diviseurClk
    generic(facteur : natural);
    port (
    clk, reset : in  std_logic;
    nclk       : out std_logic);
  end component;

  component All7Segments 
    Port ( clk : in  std_logic;
           reset : in std_logic;
           e0 : in std_logic_vector (3 downto 0);
           e1 : in std_logic_vector (3 downto 0);
           e2 : in std_logic_vector (3 downto 0);
           e3 : in std_logic_vector (3 downto 0);
           e4 : in std_logic_vector (3 downto 0);
           e5 : in std_logic_vector (3 downto 0);
           e6 : in std_logic_vector (3 downto 0);
           e7 : in std_logic_vector (3 downto 0);
           an : out std_logic_vector (7 downto 0);
           ssg : out std_logic_vector (7 downto 0));
   end component;

  component MasterJoystick
    port ( rst : in std_logic;
           clk : in std_logic;
           en : in std_logic;
           v : in std_logic_vector (1 downto 0);
           miso : in std_logic;
           ss   : out std_logic;
           sclk : out std_logic;
           mosi : out std_logic;
           x : out std_logic_vector (9 downto 0);
           y : out std_logic_vector (9 downto 0);
           boutons3 : out std_logic_vector (2 downto 0);
           busy : out std_logic);
  end component;

  -- l'horloge du MasterJoyestick
  signal masterclk : std_logic;
  -- reset
  signal rst : std_logic;
  -- les entrées de l'afficheur 8 7segments
  signal x0, x1, x2, y0, y1, y2 : std_logic_vector (3 downto 0);
  -- les coordonnées x et y reçus
  signal x, y : std_logic_vector (9 downto 0);
  -- an inermédiaire
  signal an_inter : std_logic_vector (7 downto 0);

begin

  -- Instantiation de l'afficheur 8 7 segments
  Inst_7seg : All7Segments
    port map (e0 => x0,
              e1 => x1,
              e2 => x2,
              e3 => "0000",
              e4 => y0,
              e5 => y1,
              e6 => y2,
              e7 => "0000",
              clk => mclk,
              reset => rst,
              ssg => seg,
              an => an_inter);

  -- Instantiation du diviseur d'horloge avec facteur 50, càd 2Mhz
  -- et puisque sclk et 2 fois plus lente donc sclk 1Mhz (c'est le maximum possible)
  Inst_diviseurCLK : diviseurClk 
    generic map (50)
    port map (clk => mclk,
              reset => rst,
              nclk => masterclk);

  -- Instantiation du MasterJoystick
  -- les 3 boutons du Joyestick commendent sur les leds 2, 1 et 0
  -- les deux leds du joyestick sont commendés par les switchs 0 et 1
  Inst_MasterJ : MasterJoystick
    port map (rst => rst,
              clk => masterclk,
              en => sw(15),
              v => sw (1 downto 0),
              miso => miso,
              ss => ss,
              sclk => sclk,
              mosi => mosi,
              x => x,
              y => y,
              boutons3 => led(2 downto 0),
              busy => led(15));

  rst <= not btnC;

  an <= '1'&an_inter(6 downto 4)&'1'&an_inter(2 downto 0);

  led(14 downto 3) <= (others => '0');

  -- affichage de x et y en hexadecimal
  x0 <= x(3 downto 0);
  x1 <= x(7 downto 4);
  x2 <= "00"&x(9 downto 8);

  y0 <= y(3 downto 0);
  y1 <= y(7 downto 4);
  y2 <= "00"&y(9 downto 8);
    
end synthesis;
