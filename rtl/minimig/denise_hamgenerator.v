// -*- mode: verilog; mode: font-lock; indent-tabs-mode: nil -*-
// vi: set et ts=3 sw=3 sts=3:
//
// Copyright 2006, 2007 Dennis van Weeren
// Copyright 2008, Jakub Bednarski
// Copyright 2011-2015, Rok Krajnc
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
// this module handles the hold and modify mode (HAM)
// the module has its own colour pallete bank, this is to let
// the sprites run simultaneously with a HAM playfield


module denise_hamgenerator
  (
   input  wire        clk,              // 28MHz clock
   input  wire        clk7_en,          // 7MHz clock enable
   input  wire [ 8:1] reg_address_in,   // register adress inputs
   input  wire [11:0] data_in,          // bus data in
   input  wire [ 7:0] select,           // colour select input
   input  wire [ 7:0] bplxor,           // clut address xor value
   input  wire [ 2:0] bank,             // color bank select
   input  wire        loct,             // 12-bit pallete select
   input  wire        ham8,             // HAM8 mode
   output reg  [23:0] rgb               // RGB output
   );

   // register names and adresses
   localparam COLORBASE = 9'h180;         // colour table base address

   // select xor
   wire [ 7:0]        select_xored = select ^ bplxor;

   // color ram
   wire [ 7:0]        wr_adr = {bank[2:0], reg_address_in[5:1]};
   wire               wr_en  = (reg_address_in[8:6] == COLORBASE[8:6]) && clk7_en;
   wire [31:0]        wr_dat = {4'b0, data_in[11:0], 4'b0, data_in[11:0]};
   wire [ 3:0]        wr_bs  = loct ? 4'b0011 : 4'b1111;
   wire [ 7:0]        rd_adr = ham8 ? {2'b00, select_xored[7:2]} : select_xored;
   reg  [31:0]        rd_dat;
   reg  [23:0]        rgb_prev;
   reg  [ 7:0]        select_r;

   // color lut
   reg  [31:0]        clut[0:255];

   always @(posedge clk) begin
      if (wr_en & wr_bs[0]) clut[wr_adr][ 7: 0] <= wr_dat[ 7: 0];
      if (wr_en & wr_bs[1]) clut[wr_adr][15: 8] <= wr_dat[15: 8];
      if (wr_en & wr_bs[2]) clut[wr_adr][23:16] <= wr_dat[23:16];
      if (wr_en & wr_bs[2]) clut[wr_adr][31:24] <= wr_dat[31:24];
      rd_dat <= clut[rd_adr];
   end

   // pack color values
   wire [11:0] color_hi = rd_dat[12-1+16:0+16];
   wire [11:0] color_lo = rd_dat[12-1+ 0:0+ 0];
   wire [23:0] color = {color_hi[11:8], color_lo[11:8], color_hi[7:4], color_lo[7:4], color_hi[3:0], color_lo[3:0]};

   // register previous rgb value
   always @ (posedge clk) begin
      rgb_prev <= #1 rgb;
   end

   // register previous select
   always @ (posedge clk) begin
      select_r <= #1 select_xored;
   end

   // HAM instruction decoder/processor
   always @ (*) begin
      if (ham8) begin
         case (select_r[1:0])
           2'b00: // load rgb output with colour from table
             rgb = color;
           2'b01: // hold green and red, modify blue
             rgb = {rgb_prev[23:8],select_r[7:2],rgb_prev[1:0]};
           2'b10: // hold green and blue, modify red
             rgb = {select_r[7:2],rgb_prev[17:16],rgb_prev[15:0]};
           2'b11: // hold blue and red, modify green
             rgb = {rgb_prev[23:16],select_r[7:2],rgb_prev[9:8],rgb_prev[7:0]};
           default:
             rgb = color;
         endcase
      end
      else begin
         case (select_r[5:4])
           2'b00: // load rgb output with colour from table
             rgb = color;
           2'b01: // hold green and red, modify blue
             rgb = {rgb_prev[23:8],select_r[3:0],select_r[3:0]};
           2'b10: // hold green and blue, modify red
             rgb = {select_r[3:0],select_r[3:0],rgb_prev[15:0]};
           2'b11: // hold blue and red, modify green
             rgb = {rgb_prev[23:16],select_r[3:0],select_r[3:0],rgb_prev[7:0]};
           default:
             rgb = color;
         endcase
      end
   end

endmodule
