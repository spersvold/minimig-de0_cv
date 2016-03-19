// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// ========================================================================
// File        : minimig_de0_cv_top.v
// Author      : Steffen Persvold (spersvold@gmail.com)
// Created     : March 23, 2016
// ========================================================================
// Description : Minimig DE0-CV Board Top File
// ========================================================================
//
// Minimig is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Minimig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// board type define
`define MINIMIG_DE0_CV

`include "minimig_defines.vh"

module minimig_de0_cv_top
  (
   // clock inputs
   input  wire           CLOCK_50,   // 50 MHz
   input  wire           CLOCK2_50,  // 50 MHz
   input  wire           CLOCK3_50,  // 50 MHz
   input  wire           CLOCK4_50,  // 50 MHz
   // reset input
   input  wire           RESET_N,
   // push button inputs
   input  wire [  4-1:0] KEY,        // Pushbutton[3:0]
   // switch inputs
   input  wire [ 10-1:0] SW,         // Toggle Switch[9:0]
   // 7-seg display outputs
   output wire [  7-1:0] HEX0,       // Seven Segment Digit 0
   output wire [  7-1:0] HEX1,       // Seven Segment Digit 1
   output wire [  7-1:0] HEX2,       // Seven Segment Digit 2
   output wire [  7-1:0] HEX3,       // Seven Segment Digit 3
   output wire [  7-1:0] HEX4,       // Seven Segment Digit 4
   output wire [  7-1:0] HEX5,       // Seven Segment Digit 5
   // LED outputs
   output wire [ 10-1:0] LEDR,       // LED Red[9:0]
   // VGA
   output wire           VGA_HS,     // VGA H_SYNC
   output wire           VGA_VS,     // VGA V_SYNC
   output wire [  4-1:0] VGA_R,      // VGA Red[3:0]
   output wire [  4-1:0] VGA_G,      // VGA Green[3:0]
   output wire [  4-1:0] VGA_B,      // VGA Blue[3:0]
   // PS2
   inout  wire           PS2_DAT,    // PS2 Keyboard Data
   inout  wire           PS2_CLK,    // PS2 Keyboard Clock
   inout  wire           PS2_MDAT,   // PS2 Mouse Data
   inout  wire           PS2_MCLK,   // PS2 Mouse Clock
   // SDRAM
   inout  wire [ 16-1:0] DRAM_DQ,    // SDRAM Data bus 16 Bits
   output wire [ 13-1:0] DRAM_ADDR,  // SDRAM Address bus 13 Bits
   output wire           DRAM_LDQM,  // SDRAM Low-byte Data Mask
   output wire           DRAM_UDQM,  // SDRAM High-byte Data Mask
   output wire           DRAM_WE_N,  // SDRAM Write Enable
   output wire           DRAM_CAS_N, // SDRAM Column Address Strobe
   output wire           DRAM_RAS_N, // SDRAM Row Address Strobe
   output wire           DRAM_CS_N,  // SDRAM Chip Select
   output wire [  2-1:0] DRAM_BA,    // SDRAM Bank Address
   output wire           DRAM_CLK,   // SDRAM Clock
   output wire           DRAM_CKE,   // SDRAM Clock Enable
   // Micro SD-Card
   output wire           SD_CLK,     // SD-Card serial clock      - spi CLK
   output wire           SD_CMD,     // SD-Card command/response  - spi MOSI
   inout  wire [  4-1:0] SD_DATA,    // SD-Card serial data       - spi MISO [0], spi CS [3]
   // GPIO
   inout  wire [ 36-1:0] GPIO_0,     // General Purpose I/O Slot 0
   inout  wire [ 36-1:0] GPIO_1      // General Purpose I/O Slot 1
   );

   // GPIO mapping

`define JOYA        GPIO_0[ 7:0]    // joystick port A
`define JOYB        GPIO_0[15:8]    // joystick port B

`define UART_TXD    GPIO_0[21]      // UART Transmitter
`define UART_RXD    GPIO_0[20]      // UART Receiver

`define AUDIO_LEFT  GPIO_1[28]      // sigma-delta DAC output left
`define AUDIO_RIGHT GPIO_1[29]      // sigma-delta DAC output right


   ////////////////////////////////////////
   // internal signals                   //
   ////////////////////////////////////////

   // clock
   wire                  pll_in_clk;
   wire                  clk_sys;
   wire                  clk_chip;
   wire                  clk_sdram;
   wire                  pll_locked;
   wire                  clk_7;
   wire                  clk7_en;
   wire                  clk7n_en;
   wire                  c1;
   wire                  c3;
   wire                  cck;
   wire [ 10-1:0]        eclk;

   // reset
   wire                  pll_rst;
   wire                  sdctl_rst;
   wire                  rst_minimig;

   // host
   wire [ 24-1:0]        hostAddr;
   wire [  3-1:0]        hostState;
   wire                  hostL;
   wire                  hostU;
   wire [ 16-1:0]        hostWR;
   wire [ 16-1:0]        hostRD;
   wire                  hostena;

   // ctrl
   wire                  ctrl_txd;
   wire                  ctrl_rxd;

   // tg68
   wire                  tg68_rst;
   wire [ 16-1:0]        tg68_dat_in;
   wire [ 16-1:0]        tg68_dat_out;
   wire [ 32-1:0]        tg68_adr;
   wire [  3-1:0]        tg68_IPL;
   wire                  tg68_dtack;
   wire                  tg68_as;
   wire                  tg68_uds;
   wire                  tg68_lds;
   wire                  tg68_rw;
   wire                  tg68_ena7RD;
   wire                  tg68_ena7WR;
   wire                  tg68_enaWR;
   wire [ 16-1:0]        tg68_cout;
   wire                  tg68_cpuena;
   wire [  4-1:0]        cpu_config;
   wire [  6-1:0]        memcfg;
   wire                  vsync;
   wire                  turbochipram;
   wire                  turbokick;
   wire                  cache_inhibit;
   wire [ 32-1:0]        tg68_cad;
   wire [  6-1:0]        tg68_cpustate;
   wire                  tg68_nrst_out;
   wire                  tg68_cdma;
   wire                  tg68_clds;
   wire                  tg68_cuds;
   wire [  4-1:0]        tg68_CACR_out;
   wire [ 32-1:0]        tg68_VBR_out;
   wire                  tg68_ovr;

   // minimig
   wire                  minimig_rst_out;
   wire [ 16-1:0]        ram_data;      // sram data bus
   wire [ 16-1:0]        ramdata_in;    // sram data bus in
   wire [ 48-1:0]        chip48;        // big chip read
   wire [ 22-1:1]        ram_address;   // sram address bus
   wire                  _ram_bhe;      // sram upper byte select
   wire                  _ram_ble;      // sram lower byte select
   wire                  _ram_we;       // sram write enable
   wire                  _ram_oe;       // sram output enable
   wire                  _15khz;        // scandoubler disable
   wire                  sdo;           // SPI data output
   wire [ 15-1:0]        ldata;         // left DAC data
   wire [ 15-1:0]        rdata;         // right DAC data
   wire                  floppy_fwr;
   wire                  floppy_frd;
   wire                  hd_fwr;
   wire                  hd_frd;
   wire                  minimig_txd;
   wire                  minimig_rxd;
   wire                  fifo_full;
   wire                  pwrled;

   wire                  vs;
   wire                  hs;
   wire [  8-1:0]        red;
   wire [  8-1:0]        green;
   wire [  8-1:0]        blue;
   reg                   vs_reg;
   reg                   hs_reg;
   reg [  4-1:0]         red_reg;
   reg [  4-1:0]         green_reg;
   reg [  4-1:0]         blue_reg;

   // sdram
   wire                  reset_out;
   wire [  4-1:0]        sdram_cs;

   // ctrl
   wire [  4-1:0]        SPI_CS_N;
   wire                  SPI_DI;

   wire                  clk_50;

   wire                  rst_ext;
   wire [  4-1:0]        ctrl_cfg;
   wire [  4-1:0]        ctrl_status;
   wire [  4-1:0]        sys_status;

   wire                  rom_status;
   wire                  ram_status;
   wire                  reg_status;

   wire [ 24-1:0]        dram_adr;
   wire                  dram_cs;
   wire                  dram_we;
   wire [  4-1:0]        dram_sel;
   wire [ 32-1:0]        dram_dat_w;
   wire [ 32-1:0]        dram_dat_r;
   wire                  dram_ack;
   wire                  dram_err;

   wire [ 24-1:0]        bridge_adr;
   wire                  bridge_cs;
   wire                  bridge_we;
   wire [  2-1:0]        bridge_sel;
   wire [ 16-1:0]        bridge_dat_w;
   wire [ 16-1:0]        bridge_dat_r;
   wire                  bridge_ack;
   wire                  bridge_err = 1'b0;

   // indicators
   wire [  8-1:0]        track;

   // uart
   wire                  uart_sel;

   ////////////////////////////////////////
   // synchronizers                      //
   ////////////////////////////////////////

   i_sync #(.DW(4)) i_sync_ctrl_50
     (
      .clk  (clk_50),
      .i    ({vsync, ~tg68_rst, minimig_rst_out, ~reset_out}),
      .o    (sys_status)
      );

   ////////////////////////////////////////
   // toplevel assignments               //
   ////////////////////////////////////////

   // clock
   assign pll_in_clk       = CLOCK_50;

   // reset
   assign pll_rst          = !SW[0];
   assign sdctl_rst        = pll_locked & SW[0] & RESET_N;

   // UART
   assign `UART_TXD        = uart_sel ? ctrl_txd  : minimig_txd;
   assign ctrl_rxd         = uart_sel ? `UART_RXD : 1'b1;
   assign minimig_rxd      = uart_sel ? 1'b1      : `UART_RXD;

   // SD card
   assign SD_DATA[3]       = SPI_CS_N[0];

   // SDRAM
   assign DRAM_CKE         = 1'b1;
   assign DRAM_CLK         = clk_sdram;
   assign DRAM_CS_N        = sdram_cs[0];

   // ctrl
   assign SPI_DI           = !SPI_CS_N[0] ? SD_DATA[0] : sdo;
   assign rst_ext          = !RESET_N;
   assign uart_sel         = SW[5];
   assign ctrl_cfg         = SW[4:1];

   // minimig
   assign _15khz           = SW[9];

   // VGA data
   always @ (posedge clk_chip) begin
      vs_reg    <= #1 vs;
      hs_reg    <= #1 hs;
      red_reg   <= #1 red[7:4];
      green_reg <= #1 green[7:4];
      blue_reg  <= #1 blue[7:4];
   end

   assign VGA_VS  = vs_reg;
   assign VGA_HS  = hs_reg;
   assign VGA_R   = red_reg;
   assign VGA_G   = green_reg;
   assign VGA_B   = blue_reg;

   ////////////////////////////////////////
   // modules                            //
   ////////////////////////////////////////

   // control block
   ctrl_top_nosram ctrl_top
     (
      // system
      .clk_in       (CLOCK2_50        ),  // input 50MHz clock
      .rst_ext      (rst_ext          ),  // external reset input
      .clk_out      (clk_50           ),  // output 50MHz clock from internal PLL
      .rst_out      (                 ),  // reset output from internal reset generator
      .rst_minimig  (rst_minimig      ),  // minimig reset output
      .rst_cpu      (                 ),  // TG68K reset output
      // config
      .ctrl_cfg     (ctrl_cfg         ),  // config for ctrl module
      // status
      .rom_status   (rom_status       ),  // ROM slave activity
      .ram_status   (ram_status       ),  // RAM slave activity
      .reg_status   (reg_status       ),  // REG slave activity
      .ctrl_status  (ctrl_status      ),  // CTRL LEDs
      .sys_status   (sys_status       ),  // SYS status input
      // Host RAM interface
      .ram_adr      (dram_adr         ),
      .ram_cs       (dram_cs          ),
      .ram_we       (dram_we          ),
      .ram_sel      (dram_sel         ),
      .ram_dat_w    (dram_dat_w       ),
      .ram_dat_r    (dram_dat_r       ),
      .ram_ack      (dram_ack         ),
      .ram_err      (dram_err         ),
      // UART
      .uart_txd     (ctrl_txd         ),  // UART transmit output
      .uart_rxd     (ctrl_rxd         ),  // UART receive input
      // SPI
      .spi_cs_n     (SPI_CS_N         ),  // SPI chip select output
      .spi_clk      (SD_CLK           ),  // SPI clock
      .spi_do       (SD_CMD           ),  // SPI data input
      .spi_di       (SPI_DI           )   // SPI data output
      );

   // qmem async 32-to-16 bridge
   qmem_bridge #
     (
      .MAW (24),
      .MSW (4 ),
      .MDW (32),
      .SAW (24),
      .SSW (2 ),
      .SDW (16)
      )
   qmem_bridge
     (
      // master
      .m_clk        (clk_50           ),
      .m_adr        (dram_adr         ),
      .m_cs         (dram_cs          ),
      .m_we         (dram_we          ),
      .m_sel        (dram_sel         ),
      .m_dat_w      (dram_dat_w       ),
      .m_dat_r      (dram_dat_r       ),
      .m_ack        (dram_ack         ),
      .m_err        (dram_err         ),
      // slave
      .s_clk        (clk_sys          ),
      .s_adr        (bridge_adr       ),
      .s_cs         (bridge_cs        ),
      .s_we         (bridge_we        ),
      .s_sel        (bridge_sel       ),
      .s_dat_w      (bridge_dat_w     ),
      .s_dat_r      (bridge_dat_r     ),
      .s_ack        (bridge_ack       ),
      .s_err        (bridge_err       )
      );

   assign hostAddr =  {1'b0, bridge_adr[23], bridge_adr[21:0]};
   assign hostL    = ~bridge_sel[0];
   assign hostU    = ~bridge_sel[1];
   assign hostWR   = bridge_dat_w;

   // convert from bridge cs/ack to state
   reg        hostena_d;
   reg [1:0]  host_state;

   always @(posedge clk_sys) begin
      hostena_d <= hostena;
   end

   assign hostState[2] = 1'b0;
   assign hostState[1] = bridge_cs;
   assign hostState[0] = bridge_we | ~bridge_cs;

   assign bridge_dat_r = hostRD;
   assign bridge_ack   = hostena & !hostena_d & bridge_cs;

   // indicators
   indicators indicators
     (
      .clk          (clk_chip         ), // clock ( 28.687500MHz)
      .clk7_en      (clk7_en          ), // 7MHz clock enable
      .rst          (~pll_locked      ),
      .track        (track            ),
      .f_wr         (floppy_fwr       ),
      .f_rd         (floppy_frd       ),
      .h_wr         (hd_fwr           ),
      .h_rd         (hd_frd           ),
      .status       ({rom_status, ram_status, reg_status, 1'b0}),
      .ctrl_status  (ctrl_status      ),
      .sys_status   (sys_status       ),
      .fifo_full    (fifo_full        ),
      .hex_0        (HEX0             ),
      .hex_1        (HEX1             ),
      .hex_2        (HEX2             ),
      .hex_3        (HEX3             ),
      .led_g        (                 ),
      .led_r        (LEDR             )
      );

   assign HEX4 = 7'h7f;
   assign HEX5 = 7'h7f;

   // amiga clocks
   amiga_clk amiga_clk
     (
      .rst          (pll_rst          ), // async reset input
      .clk_in       (pll_in_clk       ), // input clock     ( 27.000000MHz)
      .clk_114      (clk_sys          ), // output clock c0 (114.750000MHz)
      .clk_sdram    (clk_sdram        ), // output clock c2 (114.750000MHz, -146.25 deg)
      .clk_28       (clk_chip         ), // output clock c1 ( 28.687500MHz)
      .clk_7        (clk_7            ), // output clock 7  (  7.171875MHz)
      .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
      .clk7n_en     (clk7n_en         ), // 7MHz negedge output clock enable (on 28MHz clock domain)
      .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
      .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
      .cck          (cck              ), // colour clock output (3.54 MHz)
      .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
      .locked       (pll_locked       )  // pll locked output
      );

   // TG68K main CPU
   TG68K tg68k
     (
      .clk          (clk_sys          ),
      .reset        (tg68_rst         ),
      .clkena_in    (1'b1             ),
      .IPL          (tg68_IPL         ),
      .dtack        (tg68_dtack       ),
      .vpa          (1'b1             ),
      .ein          (1'b1             ),
      .addr         (tg68_adr         ),
      .data_read    (tg68_dat_in      ),
      .data_write   (tg68_dat_out     ),
      .as           (tg68_as          ),
      .uds          (tg68_uds         ),
      .lds          (tg68_lds         ),
      .rw           (tg68_rw          ),
      .e            (                 ),
      .vma          (                 ),
      .wrd          (                 ),
      .ena7RDreg    (tg68_ena7RD      ),
      .ena7WRreg    (tg68_ena7WR      ),
      .enaWRreg     (tg68_enaWR       ),
      .fromram      (tg68_cout        ),
      .ramready     (tg68_cpuena      ),
      .cpu          (cpu_config[1:0]  ),
      .turbochipram (turbochipram     ),
      .turbokick    (turbokick        ),
      .cache_inhibit(cache_inhibit    ),
      .fastramcfg   ({&memcfg[5:4],memcfg[5:4]}),
      .eth_en       (1'b1             ), // TODO
      .sel_eth      (                 ),
      .frometh      (16'd0            ),
      .ethready     (1'b0             ),
      .ovr          (tg68_ovr         ),
      .ramaddr      (tg68_cad         ),
      .cpustate     (tg68_cpustate    ),
      .nResetOut    (tg68_nrst_out    ),
      .cpuDMA       (tg68_cdma        ),
      .ramlds       (tg68_clds        ),
      .ramuds       (tg68_cuds        ),
      .CACR_out     (tg68_CACR_out    ),
      .VBR_out      (tg68_VBR_out     )
      );

   // sdram controller
   sdram_ctrl sdram
     (
      // sys
      .sysclk         (clk_sys          ),
      .c_7m           (clk_7            ),
      .reset_in       (sdctl_rst        ),
      .cache_rst      (tg68_rst         ),
      .reset_out      (reset_out        ),
      .cache_inhibit  (cache_inhibit    ),
      .cpu_cache_ctrl (tg68_CACR_out    ),

      // sdram
      .sdaddr         (DRAM_ADDR        ),
      .sd_cs          (sdram_cs         ),
      .ba             (DRAM_BA          ),
      .sd_we          (DRAM_WE_N        ),
      .sd_ras         (DRAM_RAS_N       ),
      .sd_cas         (DRAM_CAS_N       ),
      .dqm            ({DRAM_UDQM, DRAM_LDQM}),
      .sdata          (DRAM_DQ          ),
      // host
      .hostAddr       (hostAddr         ),
      .hostState      (hostState        ),
      .hostL          (hostL            ),
      .hostU          (hostU            ),
      .hostWR         (hostWR           ),
      .hostRD         (hostRD           ),
      .hostena        (hostena          ),
      // chip
      .chipAddr       ({2'b00, ram_address[21:1]}),
      .chipL          (_ram_ble         ),
      .chipU          (_ram_bhe         ),
      .chipRW         (_ram_we          ),
      .chip_dma       (_ram_oe          ),
      .chipWR         (ram_data         ),
      .chipRD         (ramdata_in       ),
      .chip48         (chip48           ),
      // cpu
      .cpuAddr        (tg68_cad[24:1]   ),
      .cpustate       (tg68_cpustate    ),
      .cpuL           (tg68_clds        ),
      .cpuU           (tg68_cuds        ),
      .cpu_dma        (tg68_cdma        ),
      .cpuWR          (tg68_dat_out     ),
      .cpuRD          (tg68_cout        ),
      .enaWRreg       (tg68_enaWR       ),
      .ena7RDreg      (tg68_ena7RD      ),
      .ena7WRreg      (tg68_ena7WR      ),
      .cpuena         (tg68_cpuena      )
      );

   // minimig top
   minimig minimig
     (
      //m68k pins
      .cpu_address      (tg68_adr[23:1]   ), // M68K address bus
      .cpu_data         (tg68_dat_in      ), // M68K data bus
      .cpudata_in       (tg68_dat_out     ), // M68K data in
      ._cpu_ipl         (tg68_IPL         ), // M68K interrupt request
      ._cpu_as          (tg68_as          ), // M68K address strobe
      ._cpu_uds         (tg68_uds         ), // M68K upper data strobe
      ._cpu_lds         (tg68_lds         ), // M68K lower data strobe
      .cpu_r_w          (tg68_rw          ), // M68K read / write
      ._cpu_dtack       (tg68_dtack       ), // M68K data acknowledge
      ._cpu_reset       (tg68_rst         ), // M68K reset
      ._cpu_reset_in    (tg68_nrst_out    ), // M68K reset out
      .cpu_vbr          (tg68_VBR_out     ), // M68K VBR
      .ovr              (tg68_ovr         ), // NMI override address decoding
      //sram pins
      .ram_data         (ram_data         ), // SRAM data bus
      .ramdata_in       (ramdata_in       ), // SRAM data bus in
      .ram_address      (ram_address[21:1]), // SRAM address bus
      ._ram_bhe         (_ram_bhe         ), // SRAM upper byte select
      ._ram_ble         (_ram_ble         ), // SRAM lower byte select
      ._ram_we          (_ram_we          ), // SRAM write enable
      ._ram_oe          (_ram_oe          ), // SRAM output enable
      .chip48           (chip48           ), // big chipram read
      //system  pins
      .rst_ext          (rst_minimig      ), // reset from ctrl block
      .rst_out          (minimig_rst_out  ), // minimig reset status
      .clk              (clk_chip         ), // output clock c1 ( 28.687500MHz)
      .clk7_en          (clk7_en          ), // 7MHz clock enable
      .clk7n_en         (clk7n_en         ), // 7MHz negedge clock enable
      .c1               (c1               ), // clk28m clock domain signal synchronous with clk signal
      .c3               (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
      .cck              (cck              ), // colour clock output (3.54 MHz)
      .eclk             (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
      //rs232 pins
      .rxd              (minimig_rxd      ), // RS232 receive
      .txd              (minimig_txd      ), // RS232 send
      .cts              (1'b0             ), // RS232 clear to send
      .rts              (                 ), // RS232 request to send
      //I/O
      ._joy1            (`JOYA            ), // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right] (default mouse port)
      ._joy2            (`JOYB            ), // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right] (default joystick port)
      ._15khz           (_15khz           ), // scandoubler disable
      .pwrled           (pwrled           ), // power led
      .msdat            (PS2_MDAT         ), // PS2 mouse data
      .msclk            (PS2_MCLK         ), // PS2 mouse clk
      .kbddat           (PS2_DAT          ), // PS2 keyboard data
      .kbdclk           (PS2_CLK          ), // PS2 keyboard clk
      //host controller interface (SPI)
      ._scs             (SPI_CS_N[3:1]    ), // SPI chip select
      .direct_sdi       (SD_DATA[0]       ), // SD Card direct in
      .sdi              (SD_CMD           ), // SPI data input
      .sdo              (sdo              ), // SPI data output
      .sck              (SD_CLK           ), // SPI clock
      //video
      ._hsync           (hs               ), // horizontal sync
      ._vsync           (vs               ), // vertical sync
      .red              (red              ), // red
      .green            (green            ), // green
      .blue             (blue             ), // blue
      //audio
      .left             (`AUDIO_LEFT      ), // audio bitstream left
      .right            (`AUDIO_RIGHT     ), // audio bitstream right
      .ldata            (ldata            ), // left DAC data
      .rdata            (rdata            ), // right DAC data
      //user i/o
      .cpu_config       (cpu_config       ), // CPU config
      .memcfg           (memcfg           ), // memory config
      .turbochipram     (turbochipram     ), // turbo chipRAM
      .turbokick        (turbokick        ), // turbo kickstart
      .init_b           (vsync            ), // vertical sync for MCU (sync OSD update)
      .fifo_full        (fifo_full        ),
      // fifo / track display
      .trackdisp        (track            ), // floppy track number
      .secdisp          (                 ), // sector
      .floppy_fwr       (floppy_fwr       ), // floppy fifo writing
      .floppy_frd       (floppy_frd       ), // floppy fifo reading
      .hd_fwr           (hd_fwr           ), // hd fifo writing
      .hd_frd           (hd_frd           )  // hd fifo  ading
      );

endmodule

