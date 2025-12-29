library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MasterOpl is
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
end MasterOpl;

architecture behavior of MasterOpl is

  -- types
  type t_etat is (repos, attente, debut_echange, echange);

  -- signaux internes
  signal din, dout : std_logic_vector (7 downto 0);
  signal en_1octet, busy_1octet : std_logic;
  signal op1, op2 : std_logic_vector (7 downto 0);
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
    
    -- compteur des octets à envoyer, si cpt_octet = 0 càd les 3 octets sont déjà envoyés
    variable cpt_octet : natural;

    -- compteur de cycles d'horloge d'attente
    variable cpt_att : natural;
    
  begin
  
    if (rst = '0') then

        -- réinitialisation des variables du process
        -- et des signaux calculés par le process

        -- l'indicateur d'initiation de la transmission (ss = '1' pour repos)
        ss <= '1';

        -- l'indicateur de fonctionnement/occupation
        busy <= '0';

        -- les octets reçus : ”non et”, ”non ou” et ”xor” 
        -- entre les deux opérandes de la transmission précédente.
        val_nand <= (others => 'U');
        val_nor <= (others => 'U');
        val_xor <= (others => 'U');

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

                    -- on attend 15 cycles d'horloge vant transmettre le premier bit
                    -- on initialise à 13 et non pas à 14, car er_1octet commence la transmisison
                    -- du premier bit 1 cycle après le passage de en_1octet à 1
                    -- on applique la même logique sur les autres périodes d'attente
                    cpt_att := 13;

                    -- on stocke les octets à envoyer
                    op1 <= v1;
                    op2 <= v2;

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

                        din <= op1;

                        -- mettre à jour l'octet suivant à envoyer
                        cpt_octet := 2;

                        -- pour attendre 3 cycles d'horloge avant de transmettre 
                        -- le 2ème octet
                        cpt_att := 1;
                        
                    elsif (cpt_octet = 2) then

                        din <= op2;

                        -- mettre à jour l'octet suivant à envoyer
                        cpt_octet := 3;

                        -- pour attendre 5 cycles d'horloge avant de transmettre 
                        -- le 3ème octet
                        cpt_att := 3;
                        
                    elsif (cpt_octet = 3) then

                        -- octet non utilisé
                        din <= "00000000";

                        -- c'était le dernier octet à enoyer
                        cpt_octet := 0;

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
                        
                        -- on récupère le premier octet reçu nand
                        val_nand <= dout;
                        etat <= attente;
                        
                    elsif (cpt_octet = 3) then 

                        -- on récupère le 2ème octet reçu nor
                        val_nor <= dout;
                        etat <= attente;
                        
                    elsif (cpt_octet = 0) then

                        -- on récupère le dernier octet reçu xor
                        val_xor <= dout;

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
