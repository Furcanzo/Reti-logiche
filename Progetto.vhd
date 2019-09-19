------------------------------------------------------------------------------------------------------
--                                                                                  
--  PROGETTO RETI LOGICHE 2018/19 - INGEGNERIA INFORMATICA - Sezione Prof. William Fornaciari
--
--  Buratti Roberto (codice persona 10577247, matricola 869112)
--  Bersani Alessio (codice persona 10520128, matricola 867660) 
--
------------------------------------------------------------------------------------------------------
library IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_signed.all;
USE ieee.numeric_std.ALL;

entity project_reti_logiche is
    Port (
           i_clk : in std_logic;                            --clock
           i_start : in std_logic;                          --start
           i_rst : in std_logic;                            --reset
           i_data : in std_logic_vector(7 downto 0);        --dati in ingresso dalla RAM
           o_address : out std_logic_vector(15 downto 0);   --indirizzo per chiedere dato
           o_done : out std_logic;                          --a fine computazione va a 1
           o_en : out std_logic;                            --permette di leggere la RAM
           o_we : out std_logic;                            --permette la scrittura nella RAM
           o_data : out std_logic_vector(7 downto 0)        --risultato
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
--stati in cui si può trovare il componente
type STATO is (INIZIALE, ESTRAZIONE_MASK, ESTRAZIONE_P_X, ESTRAZIONE_P_Y,ASP, ESTRAZIONE_X, ESTRAZIONE_Y, ASP_CENTR, CALCOLA_DIST, WRITE_MASK, DONE, PRE);

signal state, state_next : STATO;                                   --stato attuale del componente e stato prossimo
signal mask, mask_next : std_logic_vector(7 downto 0);              --maschera d'ingresso attuale e prossima
signal x, x_next : natural range 0 to 255;                          --valore di x del punto da valutare attuale e prossimo
signal y, y_next : natural range 0 to 255;                          --valore di y del punto da valutare attuale e prossimo
signal x_centr, x_centr_next: natural range 0 to 255;               --valore di x del centroide da valutare attuale e prossimo
signal y_centr, y_centr_next: natural range 0 to 255;               --valore di y del centroide da valutare attuale e prossimo
signal dist_min, dist_min_next : natural range 0 to 511;            --distanza minima attuale e prossima
signal mask_out, mask_out_next: std_logic_vector (7 downto 0);      --maschera d'uscita attuale e prossima
signal i, i_next: natural range 0 to 7;                             --indice per lo spostamento sulla maschera attuale e prossimo
       
begin
    process (i_clk, i_rst)
       begin
      --controllo segnale reset
       if(i_rst = '1') then	
             state <= INIZIALE;
       
       --sincronizzazione su fronte di salita e aggiornamento dei segnali
       elsif (rising_edge(i_clk)) then
             state <= state_next;
             mask <= mask_next;
             x <=x_next;
             y <=y_next;
             x_centr <= x_centr_next;
             y_centr <= y_centr_next;
             dist_min <= dist_min_next;
             mask_out<= mask_out_next;
             i<= i_next;
           
       end if;
    end process;
    
    process (i_start, i_data, mask, x, y, x_centr, y_centr, dist_min, mask_out, i, state)
       
       begin
       --assegnamenti di default
            state_next <= state;
            mask_next <= mask;
            x_next <=x;
            y_next <=y;
            x_centr_next <= x_centr;
            y_centr_next <= y_centr;
            dist_min_next <= dist_min;
            mask_out_next<= mask_out;
            i_next<=i;
            o_address<="0000000000000000";
            o_done<='0';
            o_en<='0';
            o_we<='0';
            o_data<="00000000";
            
          case state is
            
               when INIZIALE =>
               --inizializza il processo
                    if(i_start='1') then
                        mask_next<="00000000";
                        x_next<=0;
                        y_next<=0;
                        x_centr_next<=0;
                        y_centr_next<=0;
                        dist_min_next<=511;
                        mask_out_next<="00000000";
                        i_next<=0;
                        state_next <= ESTRAZIONE_MASK;
                     else
                        state_next<=INIZIALE;
                     end if;
                  
               when ESTRAZIONE_MASK =>
               --estrae la maschera d'ingresso
                    o_en <= '1';
                    o_we<='0';
                    o_address<= "0000000000000000";
                    state_next<=ESTRAZIONE_P_X;
                 
               when ESTRAZIONE_P_X =>
               --estrae la coordinate x del punto da valutare
                    o_en<='1';
                    mask_next<=i_data;                   
                    o_address<= "0000000000010001";
                    state_next<=ESTRAZIONE_P_Y;
                
               when ESTRAZIONE_P_Y =>
               --estrae la coordinate y del punto da valutare
                    o_en<='1';
                    x_next<=to_Integer(unsigned( i_data));
                    o_address<= "0000000000010010";
                    state_next<=ASP;     
               
               when ASP =>
               --aspetta un ciclo di clock
                    y_next<=to_integer(unsigned(i_data));
                    state_next<= ESTRAZIONE_X;
                
               when ESTRAZIONE_X =>
               --estrae la coordinate x del centroide
                    if (mask(i)='0') then
                        if (i=7) then
                            state_next<=WRITE_MASK;
                        else
                            i_next<=i+1;
                        end if;
                        
                        else
                            o_en<='1';
                            case i is
                                when 0=> o_address<="0000000000000001";
                                when 1=> o_address<="0000000000000011";
                                when 2=> o_address<="0000000000000101";
                                when 3=> o_address<="0000000000000111";
                                when 4=> o_address<="0000000000001001";
                                when 5=> o_address<="0000000000001011";
                                when 6=> o_address<="0000000000001101";
                                when 7=> o_address<="0000000000001111";
                            end case;
                            state_next<= ESTRAZIONE_Y;
                    end if;
                   
               when ESTRAZIONE_Y=>
               --estrae la coordinate x del centroide
                    x_centr_next<=to_integer(unsigned(i_data));
                    o_en<='1';
                    case i is
                         when 0=> o_address<="0000000000000010";
                         when 1=> o_address<="0000000000000100";
                         when 2=> o_address<="0000000000000110";
                         when 3=> o_address<="0000000000001000";
                         when 4=> o_address<="0000000000001010";
                         when 5=> o_address<="0000000000001100";
                         when 6=> o_address<="0000000000001110";
                         when 7=> o_address<="0000000000010000";
                    end case;
                    state_next<=ASP_CENTR;
                    
               when ASP_CENTR =>
               --aspetta un ciclo di clock
                    y_centr_next<=to_integer(unsigned(i_data));
                    state_next<= CALCOLA_DIST;
                    
               when CALCOLA_DIST =>
               --calcola la distanza di Manhattan e salva la minima
                    if (abs(y-y_centr)+abs(x-x_centr)=dist_min) then
                        mask_out_next(i)<='1';
                        
                    elsif (abs(y-y_centr)+abs(x-x_centr)<dist_min) then
                        mask_out_next<="00000000";
                        mask_out_next (i) <='1';
                        dist_min_next<=abs(y-y_centr)+abs(x-x_centr);
                    end if;
                    i_next<=i+1;
                    if (i=7) then
                        state_next<=WRITE_MASK;
                    else               
                        state_next<=ESTRAZIONE_X;
                    end if;
                
               when WRITE_MASK =>
               --scrive la maschera d'uscita nella RAM
                    o_en<='1';
                    o_we<='1';
                    o_address<="0000000000010011";
                    o_data<=mask_out;
                    state_next<=DONE;
                    
               when DONE =>
               --segnala la fine della computazione
                    o_done<='1';
                    if (i_start='0') then
                        o_done<='0';
                        state_next<=PRE;
                    end if;
                    
               when PRE =>
               --stato pozzo
                    state_next<=PRE;
            end case;

    end process;
    
end Behavioral;