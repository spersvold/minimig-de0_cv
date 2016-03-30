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
// This is the playfield engine.
// It takes the raw bitplane data and generates a
// single or dual playfield
// it also generated the nplayfield valid data signals which are needed
// by the main video priority logic in Denise


module denise_playfields
  (
   input  wire        aga,
   input  wire [ 8:1] bpldata,      // raw bitplane data in
   input  wire        dblpf,        // double playfield select
   input  wire [ 2:0] pf2of,        // playfield 2 offset into color table
   input  wire [ 6:0] bplcon2,      // bplcon2 (playfields priority)
   output reg  [ 2:1] nplayfield,   // playfield 1,2 valid data
   output reg  [ 7:0] plfdata       // playfield data out
   );

   //local signals
   wire               pf2pri;        // playfield 2 priority over playfield 1
   wire [2:0]         pf2p;          // playfield 2 priority code
   reg  [7:0]         pf2of_val;     // playfield 2 offset value

   assign pf2pri = bplcon2[6];
   assign pf2p = bplcon2[5:3];

   always @ (*) begin
      case(pf2of)
        3'd0 : pf2of_val = 8'd0;
        3'd1 : pf2of_val = 8'd2;
        3'd2 : pf2of_val = 8'd4;
        3'd3 : pf2of_val = 8'd8;
        3'd4 : pf2of_val = 8'd16;
        3'd5 : pf2of_val = 8'd32;
        3'd6 : pf2of_val = 8'd64;
        3'd7 : pf2of_val = 8'd128;
      endcase
   end

   //generate playfield 1,2 data valid signals
   always @(*) begin
      if (dblpf) begin //dual playfield
         if (bpldata[7] || bpldata[5] || bpldata[3] || bpldata[1]) //detect data valid for playfield 1
           nplayfield[1] = 1;
         else
           nplayfield[1] = 0;

         if (bpldata[8] || bpldata[6] || bpldata[4] || bpldata[2]) //detect data valid for playfield 2
           nplayfield[2] = 1;
         else
           nplayfield[2] = 0;
      end
      else begin //single playfield is always playfield 2
         nplayfield[1] = 0;
         if (bpldata[8:1]!=8'b000000)
           nplayfield[2] = 1;
         else
           nplayfield[2] = 0;
      end
   end

   //playfield 1 and 2 priority logic
   always @(*) begin
      if (dblpf) begin //dual playfield
         if (pf2pri) begin //playfield 2 (2,4,6) has priority
            if (nplayfield[2])
              if (aga)
                plfdata[7:0] = {4'b0000,bpldata[8],bpldata[6],bpldata[4],bpldata[2]} + pf2of_val;
              else
                plfdata[7:0] = {4'b0000,1'b1,bpldata[6],bpldata[4],bpldata[2]};
            else if (nplayfield[1])
              plfdata[7:0] = {4'b0000,bpldata[7],bpldata[5],bpldata[3],bpldata[1]};
            else //both planes transparant, select background color
              plfdata[7:0] = 8'b00000000;
         end
         else begin //playfield 1 (1,3,5) has priority
            if (nplayfield[1])
              plfdata[7:0] = {4'b0000,bpldata[7],bpldata[5],bpldata[3],bpldata[1]};
            else if (nplayfield[2])
              if (aga)
                plfdata[7:0] = {4'b0000,bpldata[8],bpldata[6],bpldata[4],bpldata[2]} + pf2of_val;
              else
                plfdata[7:0] = {4'b0000,1'b1,bpldata[6],bpldata[4],bpldata[2]};
            else //both planes transparent, select background color
              plfdata[7:0] = 8'b00000000;
         end
      end
      else begin //normal single playfield (playfield 2 only)
         //OCS/ECS undocumented feature when bpu=5 and pf2pri>5 (Swiv score display)
         if ((pf2p>5) && bpldata[5] && !aga)
           plfdata[7:0] = {8'b00010000};
         else
           plfdata[7:0] = bpldata[8:1];
      end
   end

endmodule
