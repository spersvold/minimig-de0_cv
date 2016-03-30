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
// sprite priority logic module
// this module checks the playfields and sprites video status and
// determines if playfield or sprite data must be sent to the video output
// sprite/playfield priority is configurable through the bplcon2 bits

module denise_spritepriority
  (
   input  wire [5:0] bplcon2,       // playfields vs sprites priority setting
   input  wire [2:1] nplayfield,    // playfields video status
   input  wire [7:0] nsprite,       // sprites video status
   output reg        sprsel         // sprites select signal output
   );

   // local signals
   reg  [2:0]        sprcode;       // sprite code
   wire [3:0]        sprgroup;      // grouped sprites
   wire              pf1front;      // playfield 1 is on front of sprites
   wire              pf2front;      // playfield 2 is on front of sprites

   // group sprites together
   assign  sprgroup[0] = (nsprite[1:0]==2'd0) ? 1'b0 : 1'b1;
   assign  sprgroup[1] = (nsprite[3:2]==2'd0) ? 1'b0 : 1'b1;
   assign  sprgroup[2] = (nsprite[5:4]==2'd0) ? 1'b0 : 1'b1;
   assign  sprgroup[3] = (nsprite[7:6]==2'd0) ? 1'b0 : 1'b1;

   // sprites priority encoder
   always @(*) begin
      if (sprgroup[0])
        sprcode = 3'd1;
      else if (sprgroup[1])
        sprcode = 3'd2;
      else if (sprgroup[2])
        sprcode = 3'd3;
      else if (sprgroup[3])
        sprcode = 3'd4;
      else
        sprcode = 3'd7;
   end

   // check if playfields are in front of sprites
   assign pf1front = sprcode[2:0]>bplcon2[2:0] ? 1'b1 : 1'b0;
   assign pf2front = sprcode[2:0]>bplcon2[5:3] ? 1'b1 : 1'b0;

   // generate final playfield/sprite select signal
   always @(*) begin
      if (sprcode[2:0]==3'd7) // if no valid sprite data, always select playfields
        sprsel = 1'b0;
      else if (pf1front && nplayfield[1]) // else if pf1 in front and valid data, select playfields
        sprsel = 1'b0;
      else if (pf2front && nplayfield[2]) // else if pf2 in front and valid data, select playfields
        sprsel = 1'b0;
      else // else select sprites
        sprsel = 1'b1;
   end

endmodule
