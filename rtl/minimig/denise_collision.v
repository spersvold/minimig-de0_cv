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
// this is the collision detection module


module denise_collision
  (
   input  wire        clk,             // 28MHz clock
   input  wire        clk7_en,
   input  wire        reset,           // reset
   input  wire        aga,             // aga enabled
   input  wire [ 8:1] reg_address_in,  // register adress inputs
   input  wire [15:0] data_in,         // bus data in
   output wire [15:0] data_out,        // bus data out
   input  wire        dblpf,           // dual playfield signal, required to support undocumented feature
   input  wire [ 7:0] bpldata,         // bitplane serial video data in
   input  wire [ 7:0] nsprite
   );

   //register names and adresses
   localparam CLXCON  = 9'h098;
   localparam CLXCON2 = 9'h10e;
   localparam CLXDAT  = 9'h00e;

   //local signals
   reg [15:0]         clxcon;          // collision detection control register
   reg [15:0]         clxcon2;         // collision reg 2
   reg [14:0]         clxdat;          // collision detection data register
   wire [3:0]         sprmatch;        // sprite group matches clxcon settings
   wire               oddmatch;        // odd bitplane data matches clxcon settings
   wire               evenmatch;       // even bitplane data matches clxcon settings

   //--------------------------------------------------------------------------------------

   //CLXCON register
   always @(posedge clk)
     if (clk7_en) begin
        if (reset) //reset to safe value
          clxcon <= 16'h0fff;
        else if (reg_address_in[8:1] == CLXCON[8:1])
          clxcon <= data_in;
     end

   always @ (posedge clk)
     if (clk7_en) begin
        if (reset || (reg_address_in[8:1] == CLXCON[8:1]))
          clxcon2 <= #1 16'h0000;
        else if (aga && (reg_address_in[8:1] == CLXCON2[8:1]))
          clxcon2 <= #1 data_in;
     end

   //--------------------------------------------------------------------------------------

   //generate bitplane match signal
   wire [7:0] bm;
   assign bm = (bpldata[7:0] ^ ~{clxcon2[1:0],clxcon[5:0]}) | (~{clxcon2[7:6],clxcon[11:6]}); // JB: playfield collision detection fix

   // this is the implementation of an undocumented function in the real Denise chip, developed by Yaqube.
   // trigger was the game Rotor. mentioned in WinUAE sources to be the only known game needing this feature.
   // it also fixes the Spaceport instandly helicopter crash at takeoff
   // and Archon-1 'sticky effect' of player sprite at the battlefield.
   // the OCS mystery is cleaning up :)
   assign oddmatch = bm[6] & bm[4] & bm[2] & bm[0] & (dblpf | evenmatch);
   assign evenmatch = bm[7] & bm[5] & bm[3] & bm[1];

   //generate sprite group match signal
   /*assign sprmatch[0] = (nsprite[0] | (nsprite[1]) & clxcon[12]);*/
   /*assign sprmatch[1] = (nsprite[2] | (nsprite[3]) & clxcon[13]);*/
   /*assign sprmatch[2] = (nsprite[4] | (nsprite[5]) & clxcon[14]);*/
   /*assign sprmatch[3] = (nsprite[6] | (nsprite[7]) & clxcon[15]);*/
   assign sprmatch[0] = nsprite[0] | (nsprite[1] & clxcon[12]);
   assign sprmatch[1] = nsprite[2] | (nsprite[3] & clxcon[13]);
   assign sprmatch[2] = nsprite[4] | (nsprite[5] & clxcon[14]);
   assign sprmatch[3] = nsprite[6] | (nsprite[7] & clxcon[15]);

   //--------------------------------------------------------------------------------------

   //detect collisions
   wire [14:0] cl;
   reg         clxdat_read_del;

   assign cl[0]  = evenmatch   & oddmatch;    //odd to even bitplanes
   assign cl[1]  = oddmatch    & sprmatch[0];  //odd bitplanes to sprite 0(or 1)
   assign cl[2]  = oddmatch    & sprmatch[1];  //odd bitplanes to sprite 2(or 3)
   assign cl[3]  = oddmatch    & sprmatch[2];  //odd bitplanes to sprite 4(or 5)
   assign cl[4]  = oddmatch    & sprmatch[3];  //odd bitplanes to sprite 6(or 7)
   assign cl[5]  = evenmatch   & sprmatch[0];  //even bitplanes to sprite 0(or 1)
   assign cl[6]  = evenmatch   & sprmatch[1];  //even bitplanes to sprite 2(or 3)
   assign cl[7]  = evenmatch   & sprmatch[2];  //even bitplanes to sprite 4(or 5)
   assign cl[8]  = evenmatch   & sprmatch[3];  //even bitplanes to sprite 6(or 7)
   assign cl[9]  = sprmatch[0] & sprmatch[1];  //sprite 0(or 1) to sprite 2(or 3)
   assign cl[10] = sprmatch[0] & sprmatch[2];  //sprite 0(or 1) to sprite 4(or 5)
   assign cl[11] = sprmatch[0] & sprmatch[3];  //sprite 0(or 1) to sprite 6(or 7)
   assign cl[12] = sprmatch[1] & sprmatch[2];  //sprite 2(or 3) to sprite 4(or 5)
   assign cl[13] = sprmatch[1] & sprmatch[3];  //sprite 2(or 3) to sprite 6(or 7)
   assign cl[14] = sprmatch[2] & sprmatch[3];  //sprite 4(or 5) to sprite 6(or 7)

   wire        clxdat_read = (reg_address_in[8:1]==CLXDAT[8:1]);// clxdat read

   always @(posedge clk)
     if (clk7_en) begin
        clxdat_read_del <= clxdat_read;
     end

   //register detected collisions
   always @(posedge clk)
     if (clk7_en) begin
        //  if (reg_address_in[8:1]==CLXDAT[8:1])    //if clxdat is read, clxdat is cleared to all zero's
        if (!clxdat_read & clxdat_read_del)  //if clxdat is read, clxdat is cleared to all zero's after read
          clxdat <= 0;
        else //else register collisions
          clxdat <= clxdat[14:0] | cl[14:0];
     end

   //--------------------------------------------------------------------------------------

   //reading of clxdat register
   assign data_out = reg_address_in[8:1]==CLXDAT[8:1] ? {1'b1,clxdat[14:0]} : 16'd0;

endmodule
