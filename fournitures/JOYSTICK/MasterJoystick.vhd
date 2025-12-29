-- fichier à écraser avec le fichier généré par ISE (New Source)
-- fichier à écraser avec le fichier généré par ISE (New Source)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MasterJoystick is
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
end MasterJoystick;

architecture behavior of MasterJoystick is

    -- types
    type t_etat is (repos, attente, debut_echange, echange);

    -- signaux internes
    signal din, dout : std_logic_vector (7 downto 0);
    signal en_1octet, busy_1octet : std_logic;
    signal etat : t_etat;

    -- l'interface du sous-composant er_1octet
    component er_1octet 
        port ( rst : in std_logic ;
                clk : in std_logic ;
                en : in std_logic ;
                din : in std_logic_vector (7 downto 0) ;
                miso : in std_logic ;
                sclk : out std_logic ;
                mosi : out std_logic ;
                dout : out std_logic_vector (7 downto 0) ;
                busy : out std_logic);
    end component;

begin

    -- instantiation de er_1octet
    Inst_er_1oct : er_1octet 
    port map ( rst => rst,
                clk => clk,
                en => en_1octet,
                din => din,
                miso => miso,
                sclk => sclk,
                mosi => mosi,
                dout => dout,
                busy => busy_1octet);
                
    process (clk, rst)

        -- compteur des octets à envoyer, si cpt_octet = 0 càd les 5 octets sont déjà envoyés
        variable cpt_octet : natural;
        
        -- compteur de cycles d'horloge d'attente
        variable cpt_att : natural;

        -- 2 bits à envoyer
        variable bits_env : std_logic_vector (1 downto 0);

        variable x_low, y_low: std_logic_vector (7 downto 0);

    begin

        if (rst = '0') then

            -- réinitialisation des variables du process
            -- et des signaux calculés par le process

            -- l'indicateur d'initiation de la transmission (ss = '1' pour repos)
            ss <= '1';

            -- l'indicateur de fonctionnement/occupation
            busy <= '0';

            -- les données reçues : x, y et les 3 boutons de joystick
            x <= (others => 'U');
            y <= (others => 'U');
            boutons3 <= (others => 'U');

            -- initialisation des compteurs
            cpt_octet := 0;
            cpt_att := 0;

            -- l'état
            etat <= repos;

        elsif (rising_edge(clk)) then
            
            case etat is
                
                when repos => 
                -- état d'attente d'un ordre de transmission
                
                    if (en = '1') then 
                        
                        -- Initialisation de la transmission
                        ss <= '0';

                        -- on signale qu'on est occupé
                        busy <= '1';

                        -- on commence par le premier octet
                        cpt_octet := 1;

                        -- on attend 30 cycles d'horloge vant transmettre le premier bit, càd 15 microsecondes
                        cpt_att := 30;

                        -- on stocke les 2 bits à envoyer
                        bits_env := v;

                        etat <= attente;

                    end if;
                    
                when attente =>  
                -- état d'attente au debut de la transmission ou entre deux échanges d'octet              
                    
                    if (cpt_att > 0) then
                    
                        cpt_att := cpt_att - 1;
                    
                    elsif (cpt_att = 0) then 
                    
                        -- Initialisation de l'échange d'un octet
                        en_1octet <= '1';
                        
                        if (cpt_octet = 1) then

                            -- le premier octets avec les 2 bits pour les 2 leds du Joystick
                            din <= "100000"&bits_env;

                            -- mettre à jour l'octet suivant à envoyer
                            cpt_octet := 2;

                            -- on attend 20 cycles d'horloge entre deux échanges d'octets, càd 10 microsecondes
                            cpt_att := 20;
                        
                        else 

                            -- octets non utilisé
                            din <= "00000000";

                            if (cpt_octet = 5) then

                                -- c'était le dernier octet à enoyer
                                cpt_octet := 0;

                            else

                                -- mettre à jour l'octet suivant à envoyer
                                cpt_octet := cpt_octet + 1;

                                
                                cpt_att := 20;
                        
                            end if;

                        end if;
                        
                        etat <= debut_echange;
                        
                    end if;
                
                when debut_echange => 

                    -- on rabaisse 'en_1octet'
                    en_1octet <= '0';
                    etat <= echange;
                    
                when echange => 
                -- état de l'échange d'un octet
                    
                    -- si c'était le dernier octet en revient au repos
                    -- sinon on termine la transmission après une période d'attente
                    -- on recupère les octets reçus
                    if (busy_1octet = '0') then
                    
                        if (cpt_octet = 2) then
                            
                            -- on récupère x_low
                            x_low := dout;
                            etat <= attente;
                            
                        elsif (cpt_octet = 3) then 

                            -- on recupére le 2ème octet avec les 2bits à poid fort de x
                            -- on récupère donc x 
                            x <= dout(1 downto 0)&x_low;
                            etat <= attente;

                        elsif (cpt_octet = 4) then
                            
                            -- on récupère y_low
                            y_low := dout;
                            etat <= attente;
                            
                        elsif (cpt_octet = 5) then 

                            -- on recupére le 2ème octet avec les 2bits à poid fort de y
                            -- on récupère donc y 
                            y <= dout(1 downto 0)&y_low;
                            etat <= attente;

                        elsif (cpt_octet = 0) then

                            -- on recupére les 3 boutons du Joyestick
                            boutons3 <= dout(2 downto 0);

                            -- on termine la transmission
                            ss <= '1';

                            -- on signale qu'on n'est plus occupé
                            busy <= '0'; 

                            -- on revient à l'état initial
                            etat <= repos;

                        end if;          
                                
                    end if;
            end case;
        end if;

    end process;

end behavior;