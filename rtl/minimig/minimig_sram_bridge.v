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
// This module interfaces the minimig's synchronous bus to the asynchronous sram
// on the Minimig rev1.0 board
//
// JB:
// 2008-09-23	- generation of write strobes moved to clk28m clock domain
//
// SP:
// 2016-03-24 - cleanup

module minimig_sram_bridge
  (
   //clocks
   input  wire        clk,               // 28 MHz system clock
   input  wire        c1,                   // clock enable signal
   input  wire        c3,                   // clock enable signal
   //chipset internal port
   input  wire [ 7:0] bank,                 // memory bank select (512KB)
   input  wire [18:1] address_in,           // bus address
   input  wire [15:0] data_in,              // bus data in
   output wire [15:0] data_out,             // bus data out
   input  wire        rd,                   // bus read
   input  wire        hwr,                  // bus high byte write
   input  wire        lwr,                  // bus low byte write
   //SRAM external signals
   output wire        _bhe,                 // sram upper byte
   output wire        _ble,                 // sram lower byte
   output wire        _we,                  // sram write enable
   output wire        _oe,                  // sram output enable
   output wire [ 3:0] _ce,                  // sram chip enable
   output wire [21:1] address,              // sram address bus
   output wire [15:0] data,                 // sram data data out
   input  wire [15:0] ramdata_in            // sram data data in
   );

   parameter BUS_TYPE = "INTERNAL";

   /* basic timing diagram

   phase          : Q0  : Q1  : Q2  : Q3  : Q0  : Q1  : Q2  : Q3  : Q0  : Q1  :
                  :     :     :     :     :     :     :     :     :     :     :
                               ___________             ___________             ___________
   clk                     ___/           \___________/           \___________/           \_____ (7.09 MHz - dedicated clock)

                  :     :     :     :     :     :     :     :     :     :     :
                       __    __    __    __    __    __    __    __    __    __    __
   clk28m          ___/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__ (28.36 MHz - dedicated clock)
                  :     :     :     :     :     :     :     :     :     :     :
                               ___________             ___________             ___________
   c1                      ___/           \___________/           \___________/           \_____ (7.09 MHz)
                  :     :     :     :     :     :     :     :     :     :     :
                                     ___________             ___________             ___________
   c3                      _________/           \___________/           \___________/            (7.09 MHz)
                  :     :     :     :     :     :     :     :     :     :     :
                           _________                   _____                   _____
   _ce                              \_________________/     \_________________/     \___________ (ram chip enable)
                  :     :     :     :     :     :     :     :     :     :     :
                           _______________             ___________             ___________
   _we                                    \___________/           \___________/           \_____ (ram write strobe)
                  :     :     :     :     :     :     :     :     :     :     :
                           _________                   _____                   _____
   _oe                              \_________________/     \_________________/     \___________ (ram output enable)
                  :     :     :     :     :     :     :     :     :     :     :
                                     _________________       _________________       ___________
   doe                     _________/                 \_____/                 \_____/            (data bus output enable)
                  :     :     :     :     :     :     :     :     :     :     :
    */

   wire               enable;                         // indicates memory access cycle

   // generate enable signal if any of the banks is selected
   assign enable = (bank[7:0]==8'b00000000) ? 1'b0 : 1'b1;
   //assign enable = |bank[7:0];

   generate
      if (BUS_TYPE == "EXTERNAL") begin : gen_ext_sram

         //generate _we
         reg _we_r = 1'b1;
         always @(posedge clk)
           if (!c1 && !c3) // deassert write strobe in Q0
             _we_r <= 1'b1;
           else if (c1 && c3 && enable && !rd)     //assert write strobe in Q2
             _we_r <= 1'b0;

         assign _we = _we_r;

         // generate ram output enable _oe
         reg _oe_r = 1'b1;
         always @(posedge clk)
           if (!c1 && !c3) // deassert output enable in Q0
             _oe_r <= 1'b1;
           else if (c1 && !c3 && enable && rd)     //assert output enable in Q1 during read cycle
             _oe_r <= 1'b0;

         assign _oe = _oe_r;

         // generate ram upper byte enable _bhe
         reg _bhe_r = 1'b1;
         always @(posedge clk)
           if (!c1 && !c3) // deassert upper byte enable in Q0
             _bhe_r <= 1'b1;
           else if (c1 && !c3 && enable && rd) // assert upper byte enable in Q1 during read cycle
             _bhe_r <= 1'b0;
           else if (c1 && c3 && enable && hwr) // assert upper byte enable in Q2 during write cycle
             _bhe_r <= 1'b0;

         assign _bhe = _bhe_r;

         // generate ram lower byte enable _ble
         reg _ble_r = 1'b1;
         always @(posedge clk)
           if (!c1 && !c3) // deassert lower byte enable in Q0
             _ble_r <= 1'b1;
           else if (c1 && !c3 && enable && rd) // assert lower byte enable in Q1 during read cycle
             _ble_r <= 1'b0;
           else if (c1 && c3 && enable && lwr) // assert lower byte enable in Q2 during write cycle
             _ble_r <= 1'b0;

         assign _ble = _ble_r;

         // generate sram chip selects (every sram chip is 512K x 16bits)
         reg [3:0] _ce_r = 4'b1111;
         always @(posedge clk)
           if (!c1 && !c3) // deassert chip selects in Q0
             _ce_r[3:0] <= 4'b1111;
           else if (c1 && !c3) // assert chip selects in Q1
             _ce_r[3:0] <= {~|bank[7:6],~|bank[5:4],~|bank[3:2],~|bank[1:0]};

         assign _ce = _ce_r;

         // ram address bus
         reg [21:1] address_r;
         always @(posedge clk)
           if (c1 && !c3 && enable)        // set address in Q1
             address_r <= {bank[7]|bank[6]|bank[5]|bank[4],  bank[7]|bank[6]|bank[3]|bank[2],  bank[7]|bank[5]|bank[3]|bank[1],  address_in[18:1]};

         assign address = address_r;

      end // block: gen_ext_sram
      else begin : gen_int_sram

         // generate _we
         assign _we = (!hwr && !lwr) | !enable;

         // generate ram output enable _oe
         assign _oe = !rd | !enable;
         //assign _oe = !enable;

         // generate ram upper byte enable _bhe
         assign _bhe = !hwr | !enable;

         // generate ram lower byte enable _ble
         assign _ble = !lwr | !enable;

         // no chip enables on internal bus
         assign _ce = 4'b1111;

         // ram address bus
         assign address = {bank[7]|bank[6]|bank[5]|bank[4],  bank[7]|bank[6]|bank[3]|bank[2],  bank[7]|bank[5]|bank[3]|bank[1],  address_in[18:1]};

      end // block: gen_int_sram

   endgenerate

   // bus data_out multiplexer
   assign data_out[15:0] = (enable && rd) ? ramdata_in[15:0] : 16'b0000000000000000;

   assign data[15:0] = data_in[15:0];

endmodule
