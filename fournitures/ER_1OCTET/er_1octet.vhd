library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity er_1octet is
  port ( rst : in std_logic ;
         clk : in std_logic ;
         en : in std_logic ;
         din : in std_logic_vector (7 downto 0) ;
         miso : in std_logic ;
         sclk : out std_logic ;
         mosi : out std_logic ;
         dout : out std_logic_vector (7 downto 0) ;
         busy : out std_logic);
end er_1octet;

architecture behavioral_3 of er_1octet is

  type t_etat is (repos, reception, envoi);
  signal etat : t_etat;
  signal registre : std_logic_vector (7 downto 0);

begin

  process(clk, rst)

    variable cpt : natural;

  begin

    if (rst = '0') then

      -- réinitialisation des variables du process
      -- et des signaux calculés par le process

      -- le compeur de bits
      cpt := 7;

      -- le registre d'envoi/reception
      registre <= (others => 'U');

      -- horloge pour l’échange
      sclk <= '1';

      -- master output, slave input
      mosi <= 'U';

      -- l'octet reçu
      dout <= (others => 'U');

      -- l'indicateur de fonctionnement/occupation
      busy <= '0';

      -- l'état
      etat <= repos;

    elsif (rising_edge(clk)) then

      case etat is

        when repos => 
        -- état d'attente d'un ordre d'envoi

          if (en = '1') then

            -- on initialise le compteur de bits à 7
            cpt := 7;

            -- on signale qu'on est occupé
            busy <= '1';

            -- on stocke l'octet à envoyer
            registre <= din;

            -- on envoie le bit de poids fort (7)
            mosi <= din(cpt);

            -- on reçu au front descendant de sclk
            -- et on envoi au front montant de sclk
            sclk <= '0';

            etat <= reception;

          end if;

        when reception =>
        -- état de reception de bits

          sclk <= '1';

          -- on stocke le bit reçu dans la postion (cpt)
          -- dans registre après l'avoir déjà envoyer
          registre(cpt) <= miso;

          -- si c'était le dernier bit (0), 
          -- on a fini de recevoir l'octet
          if (cpt > 0) then
            cpt := cpt-1;
            etat <= envoi;

          elsif (cpt = 0) then

            -- on signale qu'on n'est plus occupé
            busy <= '0';

            -- registre est un signal
            dout(7 downto 1) <= registre(7 downto 1);
            dout(0) <= miso;

            -- on revient à l'état de repos initial
            etat <= repos;

          end if;

        when envoi =>
        -- état d'envoi de bits 

          sclk <= '0';

          -- on evoie le bit de position (cpt)
          mosi <= registre(cpt);

          etat <= reception;
          
      end case;
    end if;
  end process;

end behavioral_3;
