// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2006, 2007 Dennis van Weeren
//
// This file is part of Minimig
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
//
//
//
// This module interfaces Minimig's synchronous bus to the 68SEC000 CPU
//
// cycle exact CIA interface:
// ECLK low for 6 cycles and high for 4
// data latched with falling edge of ECLK
// VPA sampled 3 CLKs before rising edge of ECLK
// VMA asserted one clock later if VPA recognized
// DTACK sampled one clock before ECLK falling edge
//
//             ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     ___
// CLK     ___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___
//         ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     ___
// CPU_CLK    \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/
//         ___ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______
//         ___X___0___X___1___X___2___X___3___X___4___X___5___X___6___X___7___X___8___X___9___X___0___
//         ___                                                 _______________________________
// ECLK       \_______________________________________________/                               \_______
//                                    |       |_VMA_asserted
//                                    |_VPA_sampled                   _______________           ______
//                                                                            \\\\\\\\_________/       DTACK asserted (7MHz)
//                                                                                    |__DTACK_sampled (7MHz)
//                                                                    _____________________     ______
//                                                                                         \___/       DTACK asserted (28MHz)
//                                                                                          |__DTACK_sampled (28MHz)
//
// NOTE: in 28MHz mode this timing model is not (yet?) supported, CPU talks to CIAs with no waitstates
//


module minimig_m68k_bridge
  (
   input  wire        clk,                          // 28 MHz system clock
   input  wire        clk7_en,
   input  wire        clk7n_en,
   input  wire        blk,
   input  wire        c1,                           // clock enable signal
   input  wire        c3,                           // clock enable signal
   input  wire [ 9:0] eclk,                         // ECLK enable signal
   input  wire        vpa,                          // valid peripheral address (CIAs)
   input  wire        dbr,                          // data bus request, Gary keeps CPU off the bus (custom chips transfer data)
   input  wire        dbs,                          // data bus slowdown (access to chip ram or custom registers)
   input  wire        xbs,                          // cross bridge access (active dbr holds off CPU access)
   input  wire        nrdy,                         // target device is not ready
   output wire        bls,                          // blitter slowdown, tells the blitter that CPU wants the bus
   input  wire        cck,                          // colour clock enable, active when dma can access the memory bus
   input  wire        cpu_speed,                    // CPU speed select request
   input  wire [ 3:0] memory_config,                // system memory config
   output reg         turbo,                        // indicates current CPU speed mode
   input  wire        _as,                          // m68k adress strobe
   input  wire        _lds,                         // m68k lower data strobe d0-d7
   input  wire        _uds,                         // m68k upper data strobe d8-d15
   input  wire        r_w,                          // m68k read / write
   output wire        _dtack,                       // m68k data acknowledge to cpu
   output wire        rd,                           // bus read
   output wire        hwr,                          // bus high write
   output wire        lwr,                          // bus low write
   input  wire [23:1] address,                      // external cpu address bus
   output wire [23:1] address_out,                  // internal cpu address bus output
   output wire [15:0] data,                         // external cpu data bus
   input  wire [15:0] cpudatain,
   output wire [15:0] data_out,                     // internal data bus output
   input  wire [15:0] data_in,                      // internal data bus input
   // UserIO interface
   input  wire        _cpu_reset,
   input  wire        cpu_halt,
   input  wire        host_cs,
   input  wire [23:1] host_adr,
   input  wire        host_we,
   input  wire [ 1:0] host_bs,
   input  wire [15:0] host_wdat,
   output wire [15:0] host_rdat,
   output wire        host_ack
   );

   localparam VCC = 1'b1;
   localparam GND = 1'b0;

   /*
    68000 bus timing diagram

              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
            7 . 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 0 . 1
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
               ___     ___     ___     ___     ___     ___     ___     ___     ___
    CLK    ___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
           _____________________________________________                         _____
    R/W                 \_ _ _ _ _ _ _ _ _ _ _ _/       \_______________________/
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
           _________ _______________________________ _______________________________ _
    ADDR   _________X_______________________________X_______________________________X_
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
           _____________                     ___________                     _________
    /AS                 \___________________/           \___________________/
              .....   .   .   .       .   .   .....   .   .   .   .       .   .....
           _____________        READ         ___________________    WRITE    _________
    /DS                 \___________________/                   \___________/
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
           _____________________     ___________________________     _________________
    /DTACK                      \___/                           \___/
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
                                         ___
    DIN    -----------------------------<___>-----------------------------------------
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
                                                             ___________________
    DOUT   -------------------------------------------------<___________________>-----
              .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
    */

   wire               doe;                     // data buffer output enable
   reg [15:0]         ldata_in;                // latched data_in
   wire               enable;                  // enable
   reg                lr_w,l_as,l_dtack;       // synchronised inputs
   reg                l_uds,l_lds;

   //reg                l_as28m;        // latched address strobe in turbo mode

   reg                lvpa;                    // latched valid peripheral address (CIAs)
   reg                vma;                     // valid memory address (synchronised VPA with ECLK)
   reg                _ta;                     // transfer acknowledge

   // halt is enabled when halt request comes in and cpu bus is idle
   reg                halt=0;
   always @ (posedge clk)
     if (clk7_en) begin
        if (_as && cpu_halt)
          halt <= #1 1'b1;
        else if (_as && !cpu_halt)
          halt <= #1 1'b0;
     end

   // CPU speed mode is allowed to change only when there is no bus access
   always @(posedge clk)
     if (clk7_en) begin
        if (_as)
          turbo <= cpu_speed;
     end

   // latched valid peripheral address
   always @(posedge clk)
     if (clk7_en) begin
        lvpa <= vpa;
     end

   //vma output
   always @(posedge clk)
     if (clk7_en) begin
        if (eclk[9])
          vma <= 0;
        else if (eclk[3] && lvpa)
          vma <= 1;
     end

   //latched CPU bus control signals
   always @ (posedge clk)
     if (clk7_en) begin
        lr_w    <= !halt ? r_w : !host_we;
        l_as    <= !halt ? _as : !host_cs;
        l_dtack <= _dtack;
     end

   always @(posedge clk) begin
      l_uds <= !halt ? _uds : !(host_bs[1]);
      l_lds <= !halt ? _lds : !(host_bs[0]);
   end

   reg _as28m;
   always @(posedge clk)
     _as28m <= !halt ? _as : !host_cs;

   reg l_as28m;
   always @(posedge clk)
     if (clk7_en) begin
        l_as28m <= _as28m;
     end

   wire _as_and_cs;
   assign _as_and_cs = !halt ? _as : !host_cs;

   // data transfer acknowledge in normal mode
   reg  _ta_n;
   always @(posedge clk or posedge _as_and_cs)
     if (_as_and_cs)
       _ta_n <= VCC;
     else if (clk7n_en)
       if (!l_as && cck && ((!vpa && !(dbr && dbs)) || (vpa && vma && eclk[8])) && !nrdy)
         _ta_n <= GND;

   assign host_ack = !_ta_n;
   assign _dtack   =  _ta_n;

   // synchronous control signals
   assign enable = ((~l_as & ~l_dtack & ~cck & ~turbo) | (~l_as28m & l_dtack & ~(dbr & xbs) & ~nrdy & turbo));
   assign rd = (enable & lr_w);

   // in turbo mode l_uds and l_lds may be delayed by 35 ns
   assign hwr = (enable & ~lr_w & ~l_uds);
   assign lwr = (enable & ~lr_w & ~l_lds);

   //blitter slow down signalling, asserted whenever CPU is missing bus access to chip ram, slow ram and custom registers
   assign bls = dbs & ~l_as & l_dtack;

   // generate data buffer output enable
   assign doe = r_w & ~_as;

   // --------------------------------------------------------------------------------------

   // data_out multiplexer and latch
   assign data_out = !halt ? cpudatain : host_wdat;

   always @(posedge clk)
     if (!c1 && c3 && enable)
       ldata_in <= data_in;

   // --------------------------------------------------------------------------------------

   // CPU data bus tristate buffers and output data multiplexer
   //assign data[15:0] = doe ? ldata_in[15:0] : 16'bz;
   assign data[15:0] = ldata_in;
   assign host_rdat = ldata_in;

   assign address_out[23:1] = !halt ? address[23:1] : host_adr[23:1];

endmodule
