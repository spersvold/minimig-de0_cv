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
// syscontrol handles the startup of the FGPA,
// after fpga config, it automatically does a global system reset and asserts boot.
// the boot signal puts gary in a special mode so that the bootrom
// is mapped into the system memory map.	The firmware in the bootrom
// then loads the kickstart via the diskcontroller into the kickstart ram area.
// When kickstart has been loaded, the bootrom asserts bootdone by selecting both cia's at once.
// This resets the system for a second time but it also de-asserts boot.
// Thus, the system now boots as a regular amiga.
// Subsequent resets by asserting mrst will not assert boot again.
//
// JB:
// 2008-07-11	- reset to bootloader
// 2009-03-13	- shorter reset
// 2009-08-17	- reset generator modification

module minimig_syscontrol
  (
   input  wire clk,                    // bus clock
   input  wire clk7_en,
   input  wire cnt,                    // pulses for counting
   input  wire mrst,                   // master/user reset input
   output wire reset                   // global synchronous system reset
   );

   //local signals
   reg         smrst0, smrst1;         // registered input
   reg [2:0]   rst_cnt = 0;            // reset timer SHOULD BE CLEARED BY CONFIG
   wire        _rst;                   // local reset signal

   //asynchronous mrst input synchronizer
   always @(posedge clk) begin
      if (clk7_en) begin
         smrst0 <= mrst;
         smrst1 <= smrst0;
      end
   end

   //reset timer and mrst control
   always @(posedge clk) begin
      if (clk7_en) begin
         if (smrst1)
           rst_cnt <= 3'd0;
         else if (!_rst && cnt)
           rst_cnt <= rst_cnt + 3'd1;
      end
   end

   assign _rst = rst_cnt[2];

   //global reset output
   assign reset = ~_rst;

endmodule
