library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


package txt_util is

    -- prints a message to the screen
    procedure print(text: string);

    -- prints the message when active
    -- useful for debug switches
    procedure print(active: boolean; text: string);

    -- converts std_logic into a character
    function chr(sl: std_logic) return character;

    -- converts std_logic into a string (1 to 1)
    function str(sl: std_logic) return string;

    -- converts std_logic_vector into a string (binary base)
    function str(slv: std_logic_vector) return string;

    -- converts boolean into a string
    function str(b: boolean) return string;

    -- converts an integer into a single character
    -- (can also be used for hex conversion and other bases)
    function chr(int: integer) return character;
    
    function int_to_ascii(int: integer) return character;

    -- converts integer into string using specified base
    function str(int: integer; base: integer) return string;

    -- converts integer to string, using base 10
    function str(int: integer) return string;

    -- convert std_logic_vector into a string in hex format
    function hstr(slv: std_logic_vector) return string;


    -- functions to manipulate strings
    -----------------------------------

    -- convert a character to upper case
    function to_upper(c: character) return character;

    -- convert a character to lower case
    function to_lower(c: character) return character;

    -- convert a string to upper case
    function to_upper(s: string) return string;

    -- convert a string to lower case
    function to_lower(s: string) return string;

   
    
    -- functions to convert strings into other formats
    --------------------------------------------------
    
    -- converts a character into std_logic
    function to_std_logic(c: character) return std_logic; 
    
    -- converts a string into std_logic_vector
    function to_std_logic_vector(s: string) return std_logic_vector; 
    
    -- converts a hex string into std_logic_vector
    -- CEDA Addition by Joseph
    function hex_to_std_logic_vector(s: string; hexLen: integer) return std_logic_vector; 
    
	-- Conversion functions NATURAL <-> STD_LOGIC_VECTOR
	-- CEDA Addition by Joseph
	function Std_Logic_Vector_To_Natural ( SLV : std_logic_vector) return NATURAL;
	function Natural_To_Std_Logic_Vector (val, SIZE : integer) return std_logic_vector;

  
    -- file I/O
    -----------
       
    -- read variable length string from input file
    procedure str_read(file in_file: TEXT; 
                       res_string: out string);
        
    -- print string to a file and start new line
    procedure print(file out_file: TEXT;
                    new_string: in  string);
    
    -- print character to a file and start new line
    procedure print(file out_file: TEXT;
                    char:       in  character);
                    
end txt_util;




package body txt_util is




   -- prints text to the screen

   procedure print(text: string) is
     variable msg_line: line;
     begin
       write(msg_line, text);
       writeline(output, msg_line);
   end print;




   -- prints text to the screen when active

   procedure print(active: boolean; text: string)  is
     begin
      if active then
         print(text);
      end if;
   end print;


   -- converts std_logic into a character

   function chr(sl: std_logic) return character is
    variable c: character;
    begin
      case sl is
         when 'U' => c:= 'U';
         when 'X' => c:= 'X';
         when '0' => c:= '0';
         when '1' => c:= '1';
         when 'Z' => c:= 'Z';
         when 'W' => c:= 'W';
         when 'L' => c:= 'L';
         when 'H' => c:= 'H';
         when '-' => c:= '-';
      end case;
    return c;
   end chr;



   -- converts std_logic into a string (1 to 1)

   function str(sl: std_logic) return string is
    variable s: string(1 to 1);
    begin
        s(1) := chr(sl);
        return s;
   end str;



   -- converts std_logic_vector into a string (binary base)
   -- (this also takes care of the fact that the range of
   --  a string is natural while a std_logic_vector may
   --  have an integer range)

   function str(slv: std_logic_vector) return string is
     variable result : string (1 to slv'length);
     variable r : integer;
   begin
     r := 1;
     for i in slv'range loop
        result(r) := chr(slv(i));
        r := r + 1;
     end loop;
     return result;
   end str;


   function str(b: boolean) return string is

    begin
       if b then
          return "true";
      else
        return "false";
       end if;
    end str;


   -- converts an integer into a character
   -- for 0 to 9 the obvious mapping is used, higher
   -- values are mapped to the characters A-Z
   -- (this is usefull for systems with base > 10)
   -- (adapted from Steve Vogwell's posting in comp.lang.vhdl)

   function chr(int: integer) return character is
    variable c: character;
   begin
        case int is
          when  0 => c := '0';
          when  1 => c := '1';
          when  2 => c := '2';
          when  3 => c := '3';
          when  4 => c := '4';
          when  5 => c := '5';
          when  6 => c := '6';
          when  7 => c := '7';
          when  8 => c := '8';
          when  9 => c := '9';
          when 10 => c := 'A';
          when 11 => c := 'B';
          when 12 => c := 'C';
          when 13 => c := 'D';
          when 14 => c := 'E';
          when 15 => c := 'F';
          when 16 => c := 'G';
          when 17 => c := 'H';
          when 18 => c := 'I';
          when 19 => c := 'J';
          when 20 => c := 'K';
          when 21 => c := 'L';
          when 22 => c := 'M';
          when 23 => c := 'N';
          when 24 => c := 'O';
          when 25 => c := 'P';
          when 26 => c := 'Q';
          when 27 => c := 'R';
          when 28 => c := 'S';
          when 29 => c := 'T';
          when 30 => c := 'U';
          when 31 => c := 'V';
          when 32 => c := 'W';
          when 33 => c := 'X';
          when 34 => c := 'Y';
          when 35 => c := 'Z';
          when others => c := '?';
        end case;
        return c;
    end chr;



   -- converts an integer into an ascii character
   function int_to_ascii(int: integer) return character is
    variable c: character;
   begin
        case int is
          when  10 => c := LF;
          when  13 => c := CR;
          when  32 => c := ' ';
          when  33 => c := '!';
          when  34 => c := '"';
          when  35 => c := '#';
          when  36 => c := '$';
          when  37 => c := '%';
          when  38 => c := '&';
          when  39 => c := ''';
          when  40 => c := '(';
          when  41 => c := ')';
          when  42 => c := '*';
          when  43 => c := '+';
          when  44 => c := ',';
          when  45 => c := '-';
          when  46 => c := '.';
          when  47 => c := '/';
          when  48 => c := '0';
          when  49 => c := '1';
          when  50 => c := '2';
          when  51 => c := '3';
          when  52 => c := '4';
          when  53 => c := '5';
          when  54 => c := '6';
          when  55 => c := '7';
          when  56 => c := '8';
          when  57 => c := '9';
          when  58 => c := ':';
          when  59 => c := ';';
          when  60 => c := '<';
          when  61 => c := '=';
          when  62 => c := '>';
          when  63 => c := '?';
          when  64 => c := '@';
          when  65 => c := 'A';
          when  66 => c := 'B';
          when  67 => c := 'C';
          when  68 => c := 'D';
          when  69 => c := 'E';
          when  70 => c := 'F';
          when  71 => c := 'G';
          when  72 => c := 'H';
          when  73 => c := 'I';
          when  74 => c := 'J';
          when  75 => c := 'K';
          when  76 => c := 'L';
          when  77 => c := 'M';
          when  78 => c := 'N';
          when  79 => c := 'O';
          when  80 => c := 'P';
          when  81 => c := 'Q';
          when  82 => c := 'R';
          when  83 => c := 'S';
          when  84 => c := 'T';
          when  85 => c := 'U';
          when  86 => c := 'V';
          when  87 => c := 'W';
          when  88 => c := 'X';
          when  89 => c := 'Y';
          when  90 => c := 'Z';
          when  91 => c := '[';
          when  92 => c := '\';
          when  93 => c := ']';
          when  94 => c := '^';
          when  95 => c := '_';
          when  96 => c := '`';
          when  97 => c := 'a';
          when  98 => c := 'b';
          when  99 => c := 'c';
          when 100 => c := 'd';
          when 101 => c := 'e';
          when 102 => c := 'f';
          when 103 => c := 'g';
          when 104 => c := 'h';
          when 105 => c := 'i';
          when 106 => c := 'j';
          when 107 => c := 'k';
          when 108 => c := 'l';
          when 109 => c := 'm';
          when 110 => c := 'n';
          when 111 => c := 'o';
          when 112 => c := 'p';
          when 113 => c := 'q';
          when 114 => c := 'r';
          when 115 => c := 's';
          when 116 => c := 't';
          when 117 => c := 'u';
          when 118 => c := 'v';
          when 119 => c := 'w';
          when 120 => c := 'x';
          when 121 => c := 'y';
          when 122 => c := 'z';
          when 123 => c := '{';
          when 124 => c := '|';
          when 125 => c := '}';
          when 126 => c := '~';
          when others => c := '?';
        end case;
        return c;
    end int_to_ascii;


   -- convert integer to string using specified base
   -- (adapted from Steve Vogwell's posting in comp.lang.vhdl)

   function str(int: integer; base: integer) return string is

    variable temp:      string(1 to 10);
    variable num:       integer;
    variable abs_int:   integer;
    variable len:       integer := 1;
    variable power:     integer := 1;

   begin

    -- bug fix for negative numbers
    abs_int := abs(int);

    num     := abs_int;

    while num >= base loop                     -- Determine how many
      len := len + 1;                          -- characters required
      num := num / base;                       -- to represent the
    end loop ;                                 -- number.

    for i in len downto 1 loop                 -- Convert the number to
      temp(i) := chr(abs_int/power mod base);  -- a string starting
      power := power * base;                   -- with the right hand
    end loop ;                                 -- side.

    -- return result and add sign if required
    if int < 0 then
       return '-'& temp(1 to len);
     else
       return temp(1 to len);
    end if;

   end str;


  -- convert integer to string, using base 10
  function str(int: integer) return string is

   begin

    return str(int, 10) ;

   end str;



   -- converts a std_logic_vector into a hex string.
   function hstr(slv: std_logic_vector) return string is
       variable hexlen: integer;
       variable longslv : std_logic_vector(131 downto 0) := (others => '0');
       variable hex : string(1 to 32);
       variable fourbit : std_logic_vector(3 downto 0);
     begin
       hexlen := (slv'left+1)/4;
       if (slv'left+1) mod 4 /= 0 then
         hexlen := hexlen + 1;
       end if;
       longslv(slv'left downto 0) := slv;
       for i in (hexlen -1) downto 0 loop
         fourbit := longslv(((i*4)+3) downto (i*4));
         case fourbit is
           when "0000" => hex(hexlen -I) := '0';
           when "0001" => hex(hexlen -I) := '1';
           when "0010" => hex(hexlen -I) := '2';
           when "0011" => hex(hexlen -I) := '3';
           when "0100" => hex(hexlen -I) := '4';
           when "0101" => hex(hexlen -I) := '5';
           when "0110" => hex(hexlen -I) := '6';
           when "0111" => hex(hexlen -I) := '7';
           when "1000" => hex(hexlen -I) := '8';
           when "1001" => hex(hexlen -I) := '9';
           when "1010" => hex(hexlen -I) := 'A';
           when "1011" => hex(hexlen -I) := 'B';
           when "1100" => hex(hexlen -I) := 'C';
           when "1101" => hex(hexlen -I) := 'D';
           when "1110" => hex(hexlen -I) := 'E';
           when "1111" => hex(hexlen -I) := 'F';
           when "ZZZZ" => hex(hexlen -I) := 'z';
           when "UUUU" => hex(hexlen -I) := 'u';
           when "XXXX" => hex(hexlen -I) := 'x';
           when others => hex(hexlen -I) := '?';
         end case;
       end loop;
       return hex(1 to hexlen);
     end hstr;



   -- functions to manipulate strings
   -----------------------------------


   -- convert a character to upper case

   function to_upper(c: character) return character is

      variable u: character;

    begin

       case c is
        when 'a' => u := 'A';
        when 'b' => u := 'B';
        when 'c' => u := 'C';
        when 'd' => u := 'D';
        when 'e' => u := 'E';
        when 'f' => u := 'F';
        when 'g' => u := 'G';
        when 'h' => u := 'H';
        when 'i' => u := 'I';
        when 'j' => u := 'J';
        when 'k' => u := 'K';
        when 'l' => u := 'L';
        when 'm' => u := 'M';
        when 'n' => u := 'N';
        when 'o' => u := 'O';
        when 'p' => u := 'P';
        when 'q' => u := 'Q';
        when 'r' => u := 'R';
        when 's' => u := 'S';
        when 't' => u := 'T';
        when 'u' => u := 'U';
        when 'v' => u := 'V';
        when 'w' => u := 'W';
        when 'x' => u := 'X';
        when 'y' => u := 'Y';
        when 'z' => u := 'Z';
        when others => u := c;
    end case;

      return u;

   end to_upper;


   -- convert a character to lower case

   function to_lower(c: character) return character is

      variable l: character;

    begin

       case c is
        when 'A' => l := 'a';
        when 'B' => l := 'b';
        when 'C' => l := 'c';
        when 'D' => l := 'd';
        when 'E' => l := 'e';
        when 'F' => l := 'f';
        when 'G' => l := 'g';
        when 'H' => l := 'h';
        when 'I' => l := 'i';
        when 'J' => l := 'j';
        when 'K' => l := 'k';
        when 'L' => l := 'l';
        when 'M' => l := 'm';
        when 'N' => l := 'n';
        when 'O' => l := 'o';
        when 'P' => l := 'p';
        when 'Q' => l := 'q';
        when 'R' => l := 'r';
        when 'S' => l := 's';
        when 'T' => l := 't';
        when 'U' => l := 'u';
        when 'V' => l := 'v';
        when 'W' => l := 'w';
        when 'X' => l := 'x';
        when 'Y' => l := 'y';
        when 'Z' => l := 'z';
        when others => l := c;
    end case;

      return l;

   end to_lower;



   -- convert a string to upper case

   function to_upper(s: string) return string is

     variable uppercase: string (s'range);

   begin

     for i in s'range loop
        uppercase(i):= to_upper(s(i));
     end loop;
     return uppercase;

   end to_upper;



   -- convert a string to lower case

   function to_lower(s: string) return string is

     variable lowercase: string (s'range);

   begin

     for i in s'range loop
        lowercase(i):= to_lower(s(i));
     end loop;
     return lowercase;

   end to_lower;



-- functions to convert strings into other types


-- converts a character into a std_logic

function to_std_logic(c: character) return std_logic is 
    variable sl: std_logic;
    begin
      case c is
        when 'U' => 
           sl := 'U'; 
        when 'X' =>
           sl := 'X';
        when '0' => 
           sl := '0';
        when '1' => 
           sl := '1';
        when 'Z' => 
           sl := 'Z';
        when 'W' => 
           sl := 'W';
        when 'L' => 
           sl := 'L';
        when 'H' => 
           sl := 'H';
        when '-' => 
           sl := '-';
        when others =>
           sl := 'X'; 
    end case;
   return sl;
  end to_std_logic;


-- converts a string into std_logic_vector

function to_std_logic_vector(s: string) return std_logic_vector is 
  variable slv: std_logic_vector(s'high-s'low downto 0);
  variable k: integer;
begin
   k := s'high-s'low;
  for i in s'range loop
     slv(k) := to_std_logic(s(i));
     k      := k - 1;
  end loop;
  return slv;
end to_std_logic_vector;                                       



-- converts a hex string into std_logic_vector
-- 
-- s        : The string to convert into a SLV
-- hexLen   : The length of the string (# of hex characters)
--
-- CEDA Addition by Joseph

function hex_to_std_logic_vector(s: string; hexLen: integer) return std_logic_vector is
-- slv: std_logic_vector
  constant DATA_LENGTH  : integer := (hexLen*4);
  variable slv          : std_logic_vector(DATA_LENGTH-1 downto 0) := (others => '0');
  variable hexChar      : character;
  variable fourbit      : std_logic_vector(3 downto 0);
  begin
    -- go through each character in string and convert to a fourbit value
    -- this loop goes through the string from left to right (big endian)
    -- therefore, have to assign MSB first
    for i in s'range loop
      hexChar := s(i);  -- get char
      case hexChar is
        when '0'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0000";
        when '1'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0001";
        when '2'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0010";
        when '3'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0011";
        when '4'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0100";
        when '5'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0101";
        when '6'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0110";
        when '7'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "0111";
        when '8'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1000";
        when '9'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1001";
        when 'A'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1010";
        when 'B'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1011";
        when 'C'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1100";
        when 'D'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1101";
        when 'E'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1110";
        when 'F'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "1111";
        when 'Z'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "ZZZZ";
        when 'U'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "UUUU";
        when 'X'    => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "XXXX";
        when others => slv(DATA_LENGTH-(i*4)+3 downto DATA_LENGTH-(i*4)) := "UUUU";
      end case;
    end loop;
    -- return the final SLV
    return slv;
end hex_to_std_logic_vector;

-- CEDA Addtions by Joseph
-- downloaded from: 
-- http://www.pa.msu.edu/hep/d0/ftp/run2b/l1cal/hardware/channel_link_tester/channel_link_tester_firmware/common/utilit_1.vhd
--
-- Convert standard logic vector to natural
--
function Std_Logic_Vector_To_Natural ( SLV : std_logic_vector) return NATURAL is

	variable Result : NATURAL := 0;     -- conversion result

	begin
	    for i in SLV'range loop
            Result:= Result * 2;  -- shift the variable to left
            case SLV(i) is
                when '1' | 'H' => Result := Result + 1;
                when '0' | 'L' => Result := Result + 0;
                when others    => null;
            end case;
        end loop;

    return Result;
end Std_Logic_Vector_To_Natural;

--
-- Convert natural to standard logic vector of given size
--
function Natural_To_Std_Logic_Vector (val, SIZE : integer) return std_logic_vector is
    variable signed_result      : signed(SIZE-1 downto 0);
	variable result             : std_logic_vector(SIZE-1 downto 0);
	variable l_val              : NATURAL := val;
    variable is_neg             : boolean := false;
	
	begin
	-- synopsys translate_off
	assert SIZE > 1 report "Error : function missuse : Natural_To_Std_Logic_Vector(val, negative size)"
	severity failure;
	-- synopsys translate_on
    
    -- CEDA Addition --
    -- check for negative number
    if (l_val <= 0) then
      is_neg := true;
    end if;
	
	for i in 0 to result'length-1 loop
		if (l_val mod 2) = 0 then
			signed_result(i) := '0';
		else
			signed_result(i) := '1';
		end if;
		l_val := l_val/2;
	end loop;
    
    -- if negative, invert + 1
    if (is_neg) then
      result := std_logic_vector(NOT(signed_result) + 1);
    else
      result := std_logic_vector(signed_result);
    end if;
    
	return result;
end Natural_To_Std_Logic_Vector;




----------------
--  file I/O  --
----------------



-- read variable length string from input file
     
procedure str_read(file in_file: TEXT; 
                   res_string: out string) is
       
       variable l:         line;
       variable c:         character;
       variable is_string: boolean;
       
   begin
           
     readline(in_file, l);
     -- clear the contents of the result string
     for i in res_string'range loop
         res_string(i) := ' ';
     end loop;   
     -- read all characters of the line, up to the length  
     -- of the results string
     for i in res_string'range loop
        read(l, c, is_string);
        res_string(i) := c;
        if not is_string then -- found end of line
           exit;
        end if;   
     end loop; 
                     
end str_read;


-- print string to a file
procedure print(file out_file: TEXT;
                new_string: in  string) is
       
       variable l: line;
       
   begin
      
     write(l, new_string);
     writeline(out_file, l);
                     
end print;


-- print character to a file and start new line
procedure print(file out_file: TEXT;
                char: in  character) is
       
       variable l: line;
       
   begin
      
     write(l, char);
     writeline(out_file, l);
                     
end print;



-- appends contents of a string to a file until line feed occurs
-- (LF is considered to be the end of the string)

procedure str_write(file out_file: TEXT; 
                    new_string: in  string) is
 begin
      
   for i in new_string'range loop
      print(out_file, new_string(i));
      if new_string(i) = LF then -- end of string
         exit;
      end if;
   end loop;               
                     
end str_write;




end txt_util;
