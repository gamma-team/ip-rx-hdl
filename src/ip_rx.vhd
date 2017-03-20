-- IP receiver module
--
-- Author: Antony Gillette
-- Date: 03/2017

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ip_rx IS
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
        -- 0: Protocol
        -- 1: Source IP address
        -- 5: Destination IP address
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
END ENTITY;

ARCHITECTURE normal OF ip_rx IS
    CONSTANT UDP_PROTO : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"11";
    TYPE DATA_BUS IS ARRAY (width - 1 DOWNTO 0)
        OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Keeping pipeline prefix for potential future addition
    SIGNAL p0_data_in : DATA_BUS;
    SIGNAL p0_data_in_valid
        : STD_LOGIC_VECTOR(Data_in_valid'length - 1 DOWNTO 0);
    SIGNAL p0_data_in_start : STD_LOGIC;
    SIGNAL p0_data_in_end : STD_LOGIC;
    SIGNAL p0_data_in_err : STD_LOGIC;

    SIGNAL p0_len_read_place : UNSIGNED(15 DOWNTO 0);
    SIGNAL p0_chk_accum_place : UNSIGNED(16 DOWNTO 0);
    SIGNAL data_in_sig : DATA_BUS;

BEGIN
    -- Input signal wiring
    gen_in_data: FOR i IN 0 TO width - 1 GENERATE
        data_in_sig(i) <= Data_in((i + 1) * 8 - 1 DOWNTO i * 8);
    END GENERATE;

    PROCESS(Clk)
        VARIABLE p0_len_read : UNSIGNED(p0_len_read_place'length - 1 DOWNTO 0);
        VARIABLE p0_chk_accum : UNSIGNED(p0_chk_accum_place'length - 1 DOWNTO 0);
    BEGIN
        IF rising_edge(Clk) THEN
            IF Rst = '1' THEN
                p0_data_in <= (OTHERS => x"00");
                p0_data_in_valid <= (OTHERS => '0');
                p0_data_in_start <= '0';
                p0_data_in_end <= '0';
                p0_data_in_err <= '0';
                p0_len_read_place <= (OTHERS => '0');
                p0_chk_accum_place <= (OTHERS => '0');
            ELSE
                p0_data_in <= data_in_sig;
                p0_data_in_valid <= Data_in_valid;
                p0_data_in_start <= Data_in_start;
                p0_data_in_end <= Data_in_end;
                p0_data_in_err <= Data_in_err;

                p0_len_read := p0_len_read_place;
                p0_chk_accum := p0_chk_accum_place;
                IF Data_in_start = '1' THEN
                    p0_len_read := (OTHERS => '0');
                END IF;
                FOR i IN 0 TO width - 1 LOOP
                    IF Data_in_valid(i) = '1' THEN
                        -- Protocol (offset 9) and addresses (12-19) are sent
                        CASE TO_INTEGER(p0_len_read) IS
                            WHEN 0 to 8 =>
                                p0_data_in_valid(i) <= '0';
                            WHEN 9 =>
                                IF data_in_sig(i) /= UDP_PROTO THEN
                                    p0_data_in_err <= '1';
                                END IF;
                            WHEN 10 | 11 =>
                                p0_data_in_valid(i) <= '0';
                            WHEN OTHERS =>
                                NULL;
                        END CASE;
                        IF p0_len_read < 20 AND i MOD 2 = 1 THEN
                            p0_chk_accum := p0_chk_accum + (UNSIGNED(
                                data_in_sig(i-1)) & UNSIGNED(data_in_sig(i)));
                            IF p0_chk_accum(16) = '1' THEN
                                p0_chk_accum(16) := '0';
                                p0_chk_accum := p0_chk_accum + 1;
                            END IF;
                        END IF;
                        p0_len_read := p0_len_read + 1;
                    END IF;
                END LOOP;
                p0_len_read_place <= p0_len_read;
                p0_chk_accum_place <= p0_chk_accum;
                IF p0_len_read >= 20 THEN
                    IF p0_chk_accum /= x"FFFF" THEN
                        p0_data_in_err <= '1';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Output signal wiring
    gen_out_data: FOR i IN 0 TO width - 1 GENERATE
        Data_out((i + 1) * 8 - 1 DOWNTO i * 8) <= p0_data_in(i);
    END GENERATE;
    Data_out_valid <= p0_data_in_valid;
    Data_out_start <= p0_data_in_start;
    Data_out_end <= p0_data_in_end;
    Data_out_err <= p0_data_in_err;
END ARCHITECTURE;
