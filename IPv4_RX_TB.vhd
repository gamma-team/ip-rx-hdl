----------------------------------------------------------------------------------
-- Company: University of Pittsburgh
-- Engineer: Justin Samstag
-- 
-- Create Date: 02/20/2017 10:21:46 AM
-- Design Name: IPv4 Receiver Test Bench
-- Module Name: IPv4_RX_TB - Behavioral
-- Project Name: ECE-2140 Team Gamma
-- Target Devices: Zync-7000
-- Tool Versions: 
-- Description: Test Bench for the IPv4 Receiver module of the UDP offload engine
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;
USE WORK.TXT_UTIL.ALL;

ENTITY IPv4_RX_TB IS
END IPv4_RX_TB;

ARCHITECTURE Behavioral OF IPv4_RX_TB IS
-- output file
FILE Data_output        : TEXT OPEN WRITE_MODE IS "output.txt";
-- CONSTANT declarations
-- data width of interfacing buses
CONSTANT data_width     : POSITIVE := 8;
-- clock period in ns
CONSTANT period         : TIME := 10 ns;

-- test bench internal signals
SIGNAL Load_complete    : STD_LOGIC := '0';
-- interfacing signals
SIGNAL Clk              : STD_LOGIC := '0';
SIGNAL Rst              : STD_LOGIC := '0';
SIGNAL Data_in          : STD_LOGIC_VECTOR(data_width * 8 - 1 DOWNTO 0);
SIGNAL Data_in_valid    : STD_LOGIC_VECTOR(data_width - 1 DOWNTO 0);
SIGNAL Data_in_start    : STD_LOGIC;
SIGNAL Data_in_end      : STD_LOGIC;
SIGNAL Data_in_err      : STD_LOGIC;
SIGNAL Data_out         : STD_LOGIC_VECTOR(data_width * 8 - 1 DOWNTO 0);
SIGNAL Data_out_valid   : STD_LOGIC_VECTOR(data_width - 1 DOWNTO 0);
SIGNAL Data_out_start   : STD_LOGIC;
SIGNAL Data_out_end     : STD_LOGIC;
SIGNAL Data_out_err     : STD_LOGIC;

-- Component declaration from Github
COMPONENT ip_rx IS
    GENERIC (
        -- Input and output bus width in bytes, must be a power of 2
        width : POSITIVE := 8
    );
    PORT (
        -- All ports are assumed to be synchronous with Clk
        Clk : IN STD_LOGIC;
        Rst : IN STD_LOGIC;
        -- Data input bus for data from the MAC.
        -- Byte offsets (all integer types are big endian):
        -- 0: IP version and header length (1 byte)
        -- 2: Total packet length (2 bytes)
        -- 9: Protocol (1 byte)
        -- 10: Header checksum (2 bytes)
        -- 12: Source IP address (4 bytes)
        -- 16: Destination IP address (4 bytes)
        -- 20: IP datagram's data section (if IP header length field = 5)
        Data_in : IN STD_LOGIC_VECTOR(width * 8 - 1 DOWNTO 0);
        -- Assertion indicates which Data_in bytes are valid.
        Data_in_valid : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        -- Asserted when the first data is available on Data_in.
        Data_in_start : IN STD_LOGIC;
        -- Asserted when the last valid data is available on Data_in.
        Data_in_end : IN STD_LOGIC;
        -- Indicate that there has been an error in the current data stream.
        -- Data_in will be ignored until the next Data_in_start assertion.
        Data_in_err : IN STD_LOGIC;

        -- IPv4 payload data output bus to the UDP module.
        -- Byte offsets (all integer types are big endian):
        -- 0: Source IP address
        -- 4: Destination IP address
        -- 8: Protocol
        -- 9: IP datagram's data section
        Data_out : OUT STD_LOGIC_VECTOR(width * 8 - 1 DOWNTO 0);
        -- Assertion indicates which Data_out bytes are valid.
        Data_out_valid : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        -- Asserted when the first data is available on Data_out.
        Data_out_start : OUT STD_LOGIC;
        -- Asserted when the last data is available on Data_out.
        Data_out_end : OUT STD_LOGIC;
        -- Indicate that there has been an error in the current datagram.
        -- Data_out should be ignored until the next Data_out_start assertion.
        Data_out_err : OUT STD_LOGIC
    );
END COMPONENT;

BEGIN
-- Instantiate the ip_rx module
IPv4_RX_i: ip_rx
-- Pass the data width generic to the module
GENERIC MAP(width => data_width)
-- Map the signals from the module to test bench
PORT MAP(
Clk                => Clk,
Rst                => Rst,
Data_in            => Data_in,
Data_in_valid      => Data_in_valid,
Data_in_start      => Data_in_start,
Data_in_end        => Data_in_end,
Data_in_err        => Data_in_err,
Data_out           => Data_out,
Data_out_valid     => Data_out_valid,
Data_out_start     => Data_out_start,
Data_out_end       => Data_out_end,
Data_out_err       => Data_out_err
);

-- Clock Generating process: Loops forever
clock: PROCESS
BEGIN
    -- Toggle clock signal
    Clk <= NOT(Clk);
    
    -- Wait for half of clock period
    WAIT FOR period/2;
END PROCESS;

-- Reset process: executes once at beginning of
-- test bench then never again
reset: PROCESS
BEGIN
    Rst <= '0';
    -- 1 clock cycle prior to reset
    WAIT FOR period;
    
    -- reset for 5 clock cycles to ensure start up
    Rst <= '1';
    WAIT FOR 5*period;
    Rst <= '0';
    
    -- Wait forever
    WAIT;
END PROCESS;

FILE_LOADER: PROCESS
    FILE     Test_file : TEXT;
    VARIABLE Data_din  : STD_LOGIC_VECTOR(data_width * 8 - 1 DOWNTO 0);
    VARIABLE Data_vin  : STD_LOGIC_VECTOR(data_width - 1 DOWNTO 0);
    VARIABLE Data_sin  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    VARIABLE Data_ein  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    VARIABLE V_space   : CHARACTER;
    VARIABLE Rdata     : LINE;
    VARIABLE Start     : STD_LOGIC;
BEGIN
    -- set the load completion signal to 0
    Load_complete <= '0';
    
    -- set module inputs to 0
    Data_in           <= (OTHERS => '0');
    Data_in_valid     <= (OTHERS => '0');
    Data_in_start     <= '0';
    Data_in_end       <= '0';
    Data_in_err       <= '0';
    -- wait for 10 clock cycles
    WAIT FOR 10 * period;
    
    REPORT "TB - loading test data";
    -- open test case file
    file_open(Test_file, "RX_test.txt", READ_MODE);
    
    WHILE NOT ENDFILE(Test_file) loop
        -- read line from file
        READLINE(Test_file, Rdata);
        HREAD(Rdata, Data_din);
        READ(Rdata, V_space);
        HREAD(Rdata, Data_vin);
        READ(Rdata, V_space);
        HREAD(Rdata, Data_sin);
        READ(Rdata, V_space);
        HREAD(Rdata, Data_ein);
        -- insert data protocol here
        Data_in <= Data_din;
        Data_in_valid <= Data_vin;
        Data_in_start <= Data_sin(0);
        Data_in_end <= Data_ein(0);
        
        -- Wait for rising edge to change data
        -- possible change to falling edge for more stable clock edges
        WAIT UNTIL RISING_EDGE(Clk);
    END LOOP;
    
    -- set module inputs to 0
    Data_in           <= (OTHERS => '0');
    Data_in_valid     <= (OTHERS => '0');
    Data_in_start     <= '0';
    Data_in_end       <= '0';
        
    -- Close the File
    FILE_CLOSE(Test_file);
    REPORT "Test Load Complete";
    
    WAIT FOR period;
    
    -- Set load complete variable
    Load_complete <= '1';
    
    -- Wait forever after
    WAIT;
END PROCESS FILE_LOADER;

MODULE_RESULTS: PROCESS
    VARIABLE Data_dout    : STD_LOGIC_VECTOR(data_width * 8 - 1 DOWNTO 0);
    VARIABLE Buff         : LINE;
    VARIABLE Data_eout    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    VARIABLE Data_sout    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    VARIABLE Data_vout    : STD_LOGIC_VECTOR(data_width - 1 DOWNTO 0);
    VARIABLE V_space      : CHARACTER := ' ';
    VARIABLE Started      : STD_LOGIC := '0';
BEGIN
    IF (Data_out_start = '1') THEN
        Started := '1';
    END IF;
    IF (Started = '1') THEN
        Data_dout := Data_out;
        Data_vout := Data_out_valid;
        Data_sout := (0=>Data_out_start, OTHERS => '0');
        Data_eout := (0=>Data_out_end, OTHERS => '0');
        WRITE(Buff, HSTR(Data_dout));
        WRITE(Buff, V_space);
        WRITE(Buff, HSTR(Data_vout));
        WRITE(Buff, V_space);
        WRITE(Buff, HSTR(Data_sout));
        WRITE(Buff, V_space);
        WRITE(Buff, HSTR(Data_eout));
        WRITELINE(Data_output, Buff);
        
        -- insert data protocol
    END IF;
        -- wait for clk cycle
    WAIT UNTIL RISING_EDGE(Clk);
    
    IF (Data_out_end = '1') THEN
    -- insert final write
        Data_dout := Data_out;
        Data_vout := Data_out_valid;
        Data_sout := (0=>Data_out_start, OTHERS => '0');
        Data_eout := (0=>Data_out_end, OTHERS => '0');
        WRITE(Buff, HSTR(Data_dout));
        WRITE(Buff, V_space);
        WRITE(Buff, HSTR(Data_vout));
        WRITE(Buff, V_space);
        WRITE(Buff, HSTR(Data_sout));
        WRITE(Buff, V_space);
        WRITE(Buff, HSTR(Data_eout));
        WRITELINE(Data_output, Buff);
        FILE_CLOSE(Data_output);
        WAIT;
    END IF;
            
END PROCESS MODULE_RESULTS;

END Behavioral;
