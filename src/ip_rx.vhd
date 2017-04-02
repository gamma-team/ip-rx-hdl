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
    
    attribute dont_touch : string;

    SIGNAL data_in_sig : DATA_BUS;
    SIGNAL start_len_read_sig : UNSIGNED(15 DOWNTO 0);
    attribute dont_touch of start_len_read_sig: signal is "true";
    SIGNAL p0_data_in : DATA_BUS;
    SIGNAL p0_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p0_data_in_start : STD_LOGIC;
    SIGNAL p0_data_in_end : STD_LOGIC;
    SIGNAL p0_data_in_err : STD_LOGIC;
    SIGNAL p0_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p0_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p0_chk_accum_sig: signal is "true";

    SIGNAL p1_data_in : DATA_BUS;
    SIGNAL p1_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p1_data_in_start : STD_LOGIC;
    SIGNAL p1_data_in_end : STD_LOGIC;
    SIGNAL p1_data_in_err : STD_LOGIC;
    SIGNAL p1_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p1_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p1_chk_accum_sig: signal is "true";

    SIGNAL p2_data_in : DATA_BUS;
    SIGNAL p2_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p2_data_in_start : STD_LOGIC;
    SIGNAL p2_data_in_end : STD_LOGIC;
    SIGNAL p2_data_in_err : STD_LOGIC;
    SIGNAL p2_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p2_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p2_chk_accum_sig: signal is "true";

    SIGNAL p3_data_in : DATA_BUS;
    SIGNAL p3_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p3_data_in_start : STD_LOGIC;
    SIGNAL p3_data_in_end : STD_LOGIC;
    SIGNAL p3_data_in_err : STD_LOGIC;
    SIGNAL p3_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p3_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p3_chk_accum_sig: signal is "true";

    SIGNAL p4_data_in : DATA_BUS;
    SIGNAL p4_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p4_data_in_start : STD_LOGIC;
    SIGNAL p4_data_in_end : STD_LOGIC;
    SIGNAL p4_data_in_err : STD_LOGIC;
    SIGNAL p4_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p4_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p4_chk_accum_sig: signal is "true";

    SIGNAL p5_data_in : DATA_BUS;
    SIGNAL p5_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p5_data_in_start : STD_LOGIC;
    SIGNAL p5_data_in_end : STD_LOGIC;
    SIGNAL p5_data_in_err : STD_LOGIC;
    SIGNAL p5_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p5_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p5_chk_accum_sig: signal is "true";

    SIGNAL p6_data_in : DATA_BUS;
    SIGNAL p6_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p6_data_in_start : STD_LOGIC;
    SIGNAL p6_data_in_end : STD_LOGIC;
    SIGNAL p6_data_in_err : STD_LOGIC;
    SIGNAL p6_len_read_sig : UNSIGNED(15 DOWNTO 0);
    SIGNAL p6_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p6_chk_accum_sig: signal is "true";

    SIGNAL p7_data_in : DATA_BUS;
    SIGNAL p7_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p7_data_in_start : STD_LOGIC;
    SIGNAL p7_data_in_end : STD_LOGIC;
    SIGNAL p7_data_in_err : STD_LOGIC;
    SIGNAL p7_len_read_sig : UNSIGNED(15 DOWNTO 0);
    attribute dont_touch of p7_len_read_sig: signal is "true";
    SIGNAL p7_chk_accum_sig : UNSIGNED(20 DOWNTO 0);
    attribute dont_touch of p7_chk_accum_sig: signal is "true";

    SIGNAL p8_data_in : DATA_BUS;
    SIGNAL p8_data_in_valid
        : STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    SIGNAL p8_data_in_start : STD_LOGIC;
    SIGNAL p8_data_in_end : STD_LOGIC;
    SIGNAL p8_data_in_err : STD_LOGIC;
    
BEGIN
    -- Input signal wiring
    gen_in_data: FOR i IN 0 TO width - 1 GENERATE
        data_in_sig(i) <= Data_in((i + 1) * 8 - 1 DOWNTO i * 8);
    END GENERATE;
    
    PROCESS(Clk)
        VARIABLE checksum_buffer : UNSIGNED(20 DOWNTO 0);
    BEGIN
        IF rising_edge(Clk) THEN
            IF Rst = '1' THEN
                start_len_read_sig <= (OTHERS => '0');

                p0_data_in <= (OTHERS => x"00");
                p0_data_in_valid <= (OTHERS => '0');
                p0_data_in_start <= '0';
                p0_data_in_end <= '0';
                p0_data_in_err <= '0';
                p0_len_read_sig <= (OTHERS => '0');
                p0_chk_accum_sig <= (OTHERS => '0');

                p1_data_in <= (OTHERS => x"00");
                p1_data_in_valid <= (OTHERS => '0');
                p1_data_in_start <= '0';
                p1_data_in_end <= '0';
                p1_data_in_err <= '0';
                p1_len_read_sig <= (OTHERS => '0');
                p1_chk_accum_sig <= (OTHERS => '0');

                p2_data_in <= (OTHERS => x"00");
                p2_data_in_valid <= (OTHERS => '0');
                p2_data_in_start <= '0';
                p2_data_in_end <= '0';
                p2_data_in_err <= '0';
                p2_len_read_sig <= (OTHERS => '0');
                p2_chk_accum_sig <= (OTHERS => '0');

                p3_data_in <= (OTHERS => x"00");
                p3_data_in_valid <= (OTHERS => '0');
                p3_data_in_start <= '0';
                p3_data_in_end <= '0';
                p3_data_in_err <= '0';
                p3_len_read_sig <= (OTHERS => '0');
                p3_chk_accum_sig <= (OTHERS => '0');

                p4_data_in <= (OTHERS => x"00");
                p4_data_in_valid <= (OTHERS => '0');
                p4_data_in_start <= '0';
                p4_data_in_end <= '0';
                p4_data_in_err <= '0';
                p4_len_read_sig <= (OTHERS => '0');
                p4_chk_accum_sig <= (OTHERS => '0');

                p5_data_in <= (OTHERS => x"00");
                p5_data_in_valid <= (OTHERS => '0');
                p5_data_in_start <= '0';
                p5_data_in_end <= '0';
                p5_data_in_err <= '0';
                p5_len_read_sig <= (OTHERS => '0');
                p5_chk_accum_sig <= (OTHERS => '0');

                p6_data_in <= (OTHERS => x"00");
                p6_data_in_valid <= (OTHERS => '0');
                p6_data_in_start <= '0';
                p6_data_in_end <= '0';
                p6_data_in_err <= '0';
                p6_len_read_sig <= (OTHERS => '0');
                p6_chk_accum_sig <= (OTHERS => '0');

                p7_data_in <= (OTHERS => x"00");
                p7_data_in_valid <= (OTHERS => '0');
                p7_data_in_start <= '0';
                p7_data_in_end <= '0';
                p7_data_in_err <= '0';
                p7_len_read_sig <= (OTHERS => '0');
                p7_chk_accum_sig <= (OTHERS => '0');

                p8_data_in <= (OTHERS => x"00");
                p8_data_in_valid <= (OTHERS => '0');
                p8_data_in_start <= '0';
                p8_data_in_end <= '0';
                p8_data_in_err <= '0';
                
                checksum_buffer := (others => '0');

            ELSE
                -- Begin sets for Stage 0 of Pipeline
                -- This is before Pre-Stage 0 so p0_data_in_valid changes
                -- overwrite values from Data_in_valid
                p0_data_in <= data_in_sig;
                p0_data_in_valid <= Data_in_valid;
                p0_data_in_start <= Data_in_start;
                p0_data_in_end <= Data_in_end;
                p0_data_in_err <= Data_in_err;
                start_len_read_sig <= start_len_read_sig + unsigned'(""&Data_in_valid(7))
                                        + unsigned'(""&Data_in_valid(6))+ unsigned'(""&Data_in_valid(5))
                                        + unsigned'(""&Data_in_valid(4))+ unsigned'(""&Data_in_valid(3))
                                        + unsigned'(""&Data_in_valid(2))+ unsigned'(""&Data_in_valid(1))
                                        + unsigned'(""&Data_in_valid(0));
                    
                p0_len_read_sig <= start_len_read_sig + unsigned'(""&Data_in_valid(7));
                IF Data_in_end = '1' THEN
                    start_len_read_sig <= (OTHERS => '0');
                    p0_chk_accum_sig <= (OTHERS => '0');
                    
                END IF;
                -- End sets for Stage 0 of Pipeline

                -- Start Pre-Stage 0 of Pipeline

                IF Data_in_valid(7) = '1' THEN
                -- start_valid_count hasn't been added to start_len_read_sig yet
                    CASE TO_INTEGER(start_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p0_data_in_valid(7) <= '0';
                        WHEN 9 =>
                            IF data_in_sig(7) /= UDP_PROTO THEN
                                p0_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p0_data_in_valid(7) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF start_len_read_sig < 20 THEN
                         -- Todo: test other ways of padding to see effect
                        IF start_len_read_sig MOD 2 = 0 THEN
                            p0_chk_accum_sig <= "00000" & UNSIGNED(data_in_sig(7)) & x"00";
                        ELSE
                            p0_chk_accum_sig <= "0" & x"000" & UNSIGNED(data_in_sig(7));
                        END IF;
                    ELSE
                        p0_chk_accum_sig <= (OTHERS => '0');
                    END IF;
                    --p0_len_read_sig <= start_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 1 of Pipeline

                p1_data_in <= p0_data_in;
                p1_data_in_valid <= p0_data_in_valid;
                p1_data_in_start <= p0_data_in_start;
                p1_data_in_end <= p0_data_in_end;
                IF p1_data_in_err = '0' THEN
                    p1_data_in_err <= p0_data_in_err;
                END IF;
                p1_len_read_sig <= p0_len_read_sig;
                p1_chk_accum_sig <= p0_chk_accum_sig;

                -- End sets for Stage 1 of Pipeline

                -- Start of Stage 0

                IF p0_data_in_valid(6) = '1' THEN
                    CASE TO_INTEGER(p0_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p1_data_in_valid(6) <= '0';
                        WHEN 9 =>
                            IF p0_data_in(6) /= UDP_PROTO THEN
                                p1_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p1_data_in_valid(6) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p0_len_read_sig < 20 THEN
                        IF p0_len_read_sig MOD 2 = 0 THEN
                            p1_chk_accum_sig <= UNSIGNED(p0_data_in(6)) & x"00"
                                + p0_chk_accum_sig;
                        ELSE
                            p1_chk_accum_sig <= x"00" & UNSIGNED(p0_data_in(6))
                                + p0_chk_accum_sig;
                        END IF;
                    END IF;
                    p1_len_read_sig <= p0_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 2 of Pipeline

                p2_data_in <= p1_data_in;
                p2_data_in_valid <= p1_data_in_valid;
                p2_data_in_start <= p1_data_in_start;
                p2_data_in_end <= p1_data_in_end;
                IF p2_data_in_err = '0' THEN
                    p2_data_in_err <= p1_data_in_err;
                END IF;
                p2_len_read_sig <= p1_len_read_sig;
                p2_chk_accum_sig <= p1_chk_accum_sig;

                -- End sets for Stage 2 of Pipeline

                -- Start of Stage 1

                IF p1_data_in_valid(5) = '1' THEN
                    CASE TO_INTEGER(p1_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p2_data_in_valid(5) <= '0';
                        WHEN 9 =>
                            IF p1_data_in(5) /= UDP_PROTO THEN
                                p2_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p2_data_in_valid(5) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p1_len_read_sig < 20 THEN
                        IF p1_len_read_sig MOD 2 = 0 THEN
                            p2_chk_accum_sig <= UNSIGNED(p1_data_in(5)) & x"00"
                                + p1_chk_accum_sig;
                        ELSE
                            p2_chk_accum_sig <= x"00" & UNSIGNED(p1_data_in(5))
                                + p1_chk_accum_sig;
                        END IF;
                    END IF;
                    p2_len_read_sig <= p1_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 3 of Pipeline

                p3_data_in <= p2_data_in;
                p3_data_in_valid <= p2_data_in_valid;
                p3_data_in_start <= p2_data_in_start;
                p3_data_in_end <= p2_data_in_end;
                IF p3_data_in_err = '0' THEN
                    p3_data_in_err <= p2_data_in_err;
                END IF;
                p3_len_read_sig <= p2_len_read_sig;
                p3_chk_accum_sig <= p2_chk_accum_sig;

                -- End sets for Stage 3 of Pipeline

                -- Start of Stage 2

                IF p2_data_in_valid(4) = '1' THEN
                    CASE TO_INTEGER(p2_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p3_data_in_valid(4) <= '0';
                        WHEN 9 =>
                            IF p2_data_in(4) /= UDP_PROTO THEN
                                p3_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p3_data_in_valid(4) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p2_len_read_sig < 20 THEN
                        IF p2_len_read_sig MOD 2 = 0 THEN
                            p3_chk_accum_sig <= UNSIGNED(p2_data_in(4)) & x"00"
                                + p2_chk_accum_sig;
                        ELSE
                            p3_chk_accum_sig <= x"00" & UNSIGNED(p2_data_in(4))
                                + p2_chk_accum_sig;
                        END IF;
                    END IF;
                    p3_len_read_sig <= p2_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 4 of Pipeline

                p4_data_in <= p3_data_in;
                p4_data_in_valid <= p3_data_in_valid;
                p4_data_in_start <= p3_data_in_start;
                p4_data_in_end <= p3_data_in_end;
                IF p4_data_in_err = '0' THEN
                    p4_data_in_err <= p3_data_in_err;
                END IF;
                p4_len_read_sig <= p3_len_read_sig;
                p4_chk_accum_sig <= p3_chk_accum_sig;

                -- End sets for Stage 4 of Pipeline

                -- Start of Stage 3

                IF p3_data_in_valid(3) = '1' THEN
                    CASE TO_INTEGER(p3_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p4_data_in_valid(3) <= '0';
                        WHEN 9 =>
                            IF p3_data_in(3) /= UDP_PROTO THEN
                                p4_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p4_data_in_valid(3) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p3_len_read_sig < 20 THEN
                        IF p3_len_read_sig MOD 2 = 0 THEN
                            p4_chk_accum_sig <= UNSIGNED(p3_data_in(3)) & x"00"
                                + p3_chk_accum_sig;
                        ELSE
                            p4_chk_accum_sig <= x"00" & UNSIGNED(p3_data_in(3))
                                + p3_chk_accum_sig;
                        END IF;
                    END IF;
                    p4_len_read_sig <= p3_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 5 of Pipeline

                p5_data_in <= p4_data_in;
                p5_data_in_valid <= p4_data_in_valid;
                p5_data_in_start <= p4_data_in_start;
                p5_data_in_end <= p4_data_in_end;
                IF p5_data_in_err = '0' THEN
                    p5_data_in_err <= p4_data_in_err;
                END IF;
                p5_len_read_sig <= p4_len_read_sig;
                p5_chk_accum_sig <= p4_chk_accum_sig;

                -- End sets for Stage 5 of Pipeline

                -- Start of Stage 4

                IF p4_data_in_valid(2) = '1' THEN
                    CASE TO_INTEGER(p4_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p5_data_in_valid(2) <= '0';
                        WHEN 9 =>
                            IF p4_data_in(2) /= UDP_PROTO THEN
                                p5_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p5_data_in_valid(2) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p4_len_read_sig < 20 THEN
                        IF p4_len_read_sig MOD 2 = 0 THEN
                            p5_chk_accum_sig <= UNSIGNED(p4_data_in(2)) & x"00"
                                + p4_chk_accum_sig;
                        ELSE
                            p5_chk_accum_sig <= x"00" & UNSIGNED(p4_data_in(2))
                                + p4_chk_accum_sig;
                        END IF;
                    END IF;
                    p5_len_read_sig <= p4_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 6 of Pipeline

                p6_data_in <= p5_data_in;
                p6_data_in_valid <= p5_data_in_valid;
                p6_data_in_start <= p5_data_in_start;
                p6_data_in_end <= p5_data_in_end;
                IF p6_data_in_err = '0' THEN
                    p6_data_in_err <= p5_data_in_err;
                END IF;
                p6_len_read_sig <= p5_len_read_sig;
                p6_chk_accum_sig <= p5_chk_accum_sig;

                -- End sets for Stage 6 of Pipeline

                -- Start of Stage 5

                IF p5_data_in_valid(1) = '1' THEN
                    CASE TO_INTEGER(p5_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p6_data_in_valid(1) <= '0';
                        WHEN 9 =>
                            IF p5_data_in(1) /= UDP_PROTO THEN
                                p6_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p6_data_in_valid(1) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p5_len_read_sig < 20 THEN
                        IF p5_len_read_sig MOD 2 = 0 THEN
                            p6_chk_accum_sig <= UNSIGNED(p5_data_in(1)) & x"00"
                                + p5_chk_accum_sig;
                        ELSE
                            p6_chk_accum_sig <= x"00" & UNSIGNED(p5_data_in(1))
                                + p5_chk_accum_sig;
                        END IF;
                    END IF;
                    p6_len_read_sig <= p5_len_read_sig + 1;
                END IF;

                -- Start sets for Stage 7 of Pipeline

                p7_data_in <= p6_data_in;
                p7_data_in_valid <= p6_data_in_valid;
                p7_data_in_start <= p6_data_in_start;
                p7_data_in_end <= p6_data_in_end;
                IF p7_data_in_err = '0' THEN
                    p7_data_in_err <= p6_data_in_err;
                END IF;
                p7_len_read_sig <= p6_len_read_sig;
                p7_chk_accum_sig <= p6_chk_accum_sig;

                -- End sets for Stage 7 of Pipeline

                -- Start of Stage 6

                IF p6_data_in_valid(0) = '1' THEN
                    CASE TO_INTEGER(p6_len_read_sig) IS
                        WHEN 0 to 8 =>
                            p7_data_in_valid(0) <= '0';
                        WHEN 9 =>
                            IF p6_data_in(0) /= UDP_PROTO THEN
                                p7_data_in_err <= '1';
                            END IF;
                        WHEN 10 | 11 =>
                            p7_data_in_valid(0) <= '0';
                        WHEN OTHERS =>
                            NULL;
                    END CASE;
                    IF p6_len_read_sig < 20 THEN
                        IF p6_len_read_sig MOD 2 = 0 THEN
                            p7_chk_accum_sig <= UNSIGNED(p6_data_in(0)) & x"00"
                                + p6_chk_accum_sig;
                        ELSE
                            p7_chk_accum_sig <= x"00" & UNSIGNED(p6_data_in(0))
                                + p6_chk_accum_sig;
                        END IF;
                    END IF;
                    p7_len_read_sig <= p6_len_read_sig + 1;
                END IF;

                -- Sets for Stage 8 of Pipeline (Output)
                
                p8_data_in <= p7_data_in;
                p8_data_in_valid <= p7_data_in_valid;
                p8_data_in_start <= p7_data_in_start;
                p8_data_in_end <= p7_data_in_end;
                IF p8_data_in_err = '0' THEN
                    p8_data_in_err <= p7_data_in_err;
                END IF;
                
                -- End sets for Stage 8 of Pipeline (Output)

                -- Start of Stage 7

                checksum_buffer := checksum_buffer + p7_chk_accum_sig;
                IF checksum_buffer(20 DOWNTO 16) /= "00000" THEN
                    checksum_buffer := unsigned'(x"0000" & checksum_buffer(20 DOWNTO 16)) +
                        unsigned'("00000" & checksum_buffer(15 DOWNTO 0));
                END IF;
                IF (p8_data_in_end = '1') THEN
                    checksum_buffer := (others => '0');
                END IF;
                IF TO_INTEGER(p7_len_read_sig) > 19 THEN
                    IF checksum_buffer /= x"FFFF" THEN
                        p8_data_in_err <= '1';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Output signal wiring
    gen_out_data: FOR i IN 0 TO width - 1 GENERATE
        Data_out((i + 1) * 8 - 1 DOWNTO i * 8) <= p8_data_in(i);
    END GENERATE;
    Data_out_valid <= p8_data_in_valid;
    Data_out_start <= p8_data_in_start;
    Data_out_end <= p8_data_in_end;
    Data_out_err <= p8_data_in_err;
END ARCHITECTURE;
