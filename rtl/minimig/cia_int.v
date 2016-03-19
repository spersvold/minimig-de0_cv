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
// along with this program.  If not, see <http:// www.gnu.org/licenses/>.

module cia_int
  (
   input  wire       clk,         // clock
   input  wire       clk7_en,
   input  wire       wr,          // write enable
   input  wire       reset,       // reset
   input  wire       icrs,        // intterupt control register select
   input  wire       ta,          // ta (set TA bit in ICR register)
   input  wire       tb,          // tb (set TB bit in ICR register)
   input  wire       alrm,        // alrm (set ALRM bit ICR register)
   input  wire       flag,        // flag (set FLG bit in ICR register)
   input  wire       ser,         // ser (set SP bit in ICR register)
   input  wire [7:0] data_in,     // bus data in
   output wire [7:0] data_out,    // bus data out
   output wire       irq          // intterupt out
   );

   reg [4:0]         icr = 5'd0;      // interrupt register
   reg [4:0]         icrmask = 5'd0;  // interrupt mask register

   // reading of interrupt data register
   assign data_out[7:0] = icrs && !wr ? {irq,2'b00,icr[4:0]} : 8'b0000_0000;

   // writing of interrupt mask register
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          icrmask[4:0] <= 5'b0_0000;
        else if (icrs && wr)
          begin
             if (data_in[7])
               icrmask[4:0] <= icrmask[4:0] | data_in[4:0];
             else
               icrmask[4:0] <= icrmask[4:0] & (~data_in[4:0]);
          end
     end

   // register new interrupts and/or changes by user reads
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)// synchronous reset
          icr[4:0] <= 5'b0_0000;
        else if (icrs && !wr)
          begin// clear latched intterupts on read
             icr[0] <= ta;      // timer a
             icr[1] <= tb;      // timer b
             icr[2] <= alrm;       // timer tod
             icr[3] <= ser;       // external ser input
             icr[4] <= flag;      // external flag input
          end
        else
          begin// keep latched intterupts
             icr[0] <= icr[0] | ta;    // timer a
             icr[1] <= icr[1] | tb;    // timer b
             icr[2] <= icr[2] | alrm;  // timer tod
             icr[3] <= icr[3] | ser;    // external ser input
             icr[4] <= icr[4] | flag;  // external flag input
          end
     end

   // generate irq output (interrupt request)
   assign irq = (icrmask[0] & icr[0]) |
                (icrmask[1] & icr[1]) |
                (icrmask[2] & icr[2]) |
                (icrmask[3] & icr[3]) |
                (icrmask[4] & icr[4]);

endmodule
