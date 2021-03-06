-- file: selectio_wiz_v4_1_0.vhd
-- (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity selectio_wiz_v4_1_0 is
generic
 (-- width of the data for the system
  sys_w       : integer := 2;
  -- width of the data for the device
  dev_w       : integer := 12);
port
 (
  -- From the system into the device
  DATA_IN_FROM_PINS       : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_TO_DEVICE       : out   std_logic_vector(dev_w-1 downto 0);

  BITSLIP                 : in    std_logic;                    -- Bitslip module is enabled in NETWORKING mode
                                                                -- User should tie it to '0' if not needed
 
-- Clock and reset signals
  CLK_IN                  : in    std_logic;                    -- Single ended Fast clock from IOB
  CLK_DIV_OUT             : out   std_logic;                    -- Slow clock output
  CLK_RESET               : in    std_logic;                    -- Reset signal for Clock circuit
  IO_RESET                : in    std_logic);                   -- Reset signal for IO circuit
end selectio_wiz_v4_1_0;

architecture xilinx of selectio_wiz_v4_1_0 is
  attribute CORE_GENERATION_INFO            : string;
  attribute CORE_GENERATION_INFO of xilinx  : architecture is "selectio_wiz_v4_1_0,selectio_wiz_v4_1,{component_name=selectio_wiz_v4_1_0,bus_dir=INPUTS,bus_sig_type=SINGLE,bus_io_std=LVCMOS25,use_serialization=true,use_phase_detector=false,serialization_factor=6,enable_bitslip=false,enable_train=false,system_data_width=2,bus_in_delay=NONE,bus_out_delay=NONE,clk_sig_type=SINGLE,clk_io_std=LVCMOS18,clk_buf=BUFIO2,active_edge=RISING,clk_delay=NONE,v6_bus_in_delay=NONE,v6_bus_out_delay=NONE,v6_clk_buf=BUFIO,v6_active_edge=DDR,v6_ddr_alignment=SAME_EDGE_PIPELINED,v6_oddr_alignment=SAME_EDGE,ddr_alignment=C0,v6_interface_type=NETWORKING,interface_type=NETWORKING,v6_bus_in_tap=0,v6_bus_out_tap=0,v6_clk_io_std=LVCMOS25,v6_clk_sig_type=SINGLE}";
  constant clock_enable            : std_logic := '1';
  signal unused : std_logic;
  signal clk_in_int                : std_logic;
  signal clk_div                   : std_logic;
  signal clk_div_int               : std_logic;
  signal clk_in_int_buf            : std_logic;


  -- After the buffer
  signal data_in_from_pins_int     : std_logic_vector(sys_w-1 downto 0);
  -- Between the delay and serdes
  signal data_in_from_pins_delay   : std_logic_vector(sys_w-1 downto 0);
  signal ce_in_uc          : std_logic;
  signal inc_in_uc         : std_logic;
  signal regrst_in_uc      : std_logic;
  signal ce_out_uc              : std_logic;
  signal inc_out_uc             : std_logic;
  signal regrst_out_uc          : std_logic;
  constant num_serial_bits         : integer := dev_w/sys_w;
  type serdarr is array (0 to 13) of std_logic_vector(sys_w-1 downto 0);
  -- Array to use intermediately from the serdes to the internal
  --  devices. bus "0" is the leftmost bus
  -- * fills in starting with 0
  signal iserdes_q                 : serdarr := (( others => (others => '0')));
  signal serdesstrobe             : std_logic;
  signal icascade1                : std_logic_vector(sys_w-1 downto 0);
  signal icascade2                : std_logic_vector(sys_w-1 downto 0);
  signal clk_in_int_inv           : std_logic;



begin




  -- Create the clock logic
     ibufg_clk_inst : IBUFG
       generic map (
         IOSTANDARD => "LVCMOS25")
       port map (
         I          => CLK_IN,
         O          => clk_in_int);
-- High Speed BUFIO clock buffer
     bufio_inst : BUFIO
       port map (
         O => clk_in_int_buf,
         I => clk_in_int);
-- BUFR generates the slow clock
     clkout_buf_inst : BUFR
       generic map (
          SIM_DEVICE => "7SERIES",
          BUFR_DIVIDE => "3")
       port map (
          O           => clk_div,
          CE          => '1',
          CLR         => CLK_RESET,
          I           => clk_in_int);


   CLK_DIV_OUT <= clk_div; --This is regional clock;
  
  -- We have multiple bits- step over every bit, instantiating the required elements
  pins: for pin_count in 0 to sys_w-1 generate 
  begin
    -- Instantiate the buffers
    ----------------------------------
    -- Instantiate a buffer for every bit of the data bus
     ibuf_inst : IBUF
       generic map (
         IOSTANDARD => "LVCMOS25")
       port map (     
         I          => DATA_IN_FROM_PINS    (pin_count),
         O          => data_in_from_pins_int(pin_count));


    -- Pass through the delay
    -----------------------------------
   data_in_from_pins_delay(pin_count) <= data_in_from_pins_int(pin_count);

     -- Instantiate the serdes primitive
     ----------------------------------

     clk_in_int_inv <= not (clk_in_int_buf);    


     -- declare the iserdes
     iserdese2_master : ISERDESE2
       generic map (
         DATA_RATE         => "DDR",
         DATA_WIDTH        => 6,
         INTERFACE_TYPE    => "NETWORKING", 
         DYN_CLKDIV_INV_EN => "FALSE",
         DYN_CLK_INV_EN    => "FALSE",
         NUM_CE            => 2,
         OFB_USED          => "FALSE",
         IOBDELAY          => "NONE",                             -- Use input at D to output the data on Q1-Q6
         SERDES_MODE       => "MASTER")
       port map (
         Q1                => iserdes_q(0)(pin_count),
         Q2                => iserdes_q(1)(pin_count),
         Q3                => iserdes_q(2)(pin_count),
         Q4                => iserdes_q(3)(pin_count),
         Q5                => iserdes_q(4)(pin_count),
         Q6                => iserdes_q(5)(pin_count),
         Q7                => iserdes_q(6)(pin_count),
         Q8                => iserdes_q(7)(pin_count),
         SHIFTOUT1         => open,
         SHIFTOUT2         => open,
         BITSLIP           => BITSLIP,                            -- 1-bit Invoke Bitslip. This can be used with any 
                                                                  -- DATA_WIDTH, cascaded or not.
         CE1               => clock_enable,                       -- 1-bit Clock enable input
         CE2               => clock_enable,                       -- 1-bit Clock enable input
         CLK               => clk_in_int_buf,                     -- Fast Source Synchronous SERDES clock from BUFIO
         CLKB              => clk_in_int_inv,                     -- Locally inverted clock
         CLKDIV            => clk_div,                            -- Slow clock driven by BUFR
         CLKDIVP           => '0',
         D                 => data_in_from_pins_delay(pin_count), -- 1-bit Input signal from IOB.
         DDLY              => '0',
         RST               => IO_RESET,                           -- 1-bit Asynchronous reset only.
         SHIFTIN1          => '0',
         SHIFTIN2          => '0',
        -- unused connections
         DYNCLKDIVSEL      => '0',
         DYNCLKSEL         => '0',
         OFB               => '0',
         OCLK              => '0',
         OCLKB             => '0',
         O                 => open);                              -- unregistered output of ISERDESE1


     -- Concatenate the serdes outputs together. Keep the timesliced
     --   bits together, and placing the earliest bits on the right
     --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     --       the output will be 3210, 7654, ...
     -------------------------------------------------------------

     in_slices: for slice_count in 0 to num_serial_bits-1 generate begin
        -- This places the first data in time on the right
        DATA_IN_TO_DEVICE(slice_count*sys_w+sys_w-1 downto slice_count*sys_w) <=
          iserdes_q(num_serial_bits-slice_count-1);
        -- To place the first data in time on the left, use the
        --   following code, instead
        -- DATA_IN_TO_DEVICE(slice_count*sys_w+sys_w-1 downto sys_w) <=
        --   iserdes_q(slice_count);
     end generate in_slices;


  end generate pins;





end xilinx;



