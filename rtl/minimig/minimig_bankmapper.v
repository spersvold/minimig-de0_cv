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
// This module maps physical 512KB blocks of every memory chip to different memory ranges in Amiga

module minimig_bankmapper
  (
   input  wire       chip0,           // chip ram select: 1st 512 KB block
   input  wire       chip1,           // chip ram select: 2nd 512 KB block
   input  wire       chip2,           // chip ram select: 3rd 512 KB block
   input  wire       chip3,           // chip ram select: 4th 512 KB block
   input  wire       slow0,           // slow ram select: 1st 512 KB block
   input  wire       slow1,           // slow ram select: 2nd 512 KB block
   input  wire       slow2,           // slow ram select: 3rd 512 KB block
   input  wire       kick,            // Kickstart ROM address range select
   input  wire       kick1mb,         // 1MB Kickstart 'upper' half
   input  wire       cart,            // Action Reply memory range select
   input  wire       aron,            // Action Reply enable
   input  wire       ecs,             // ECS chipset enable
   input  wire [3:0] memory_config,   // memory configuration
   output reg  [7:0] bank             // bank select
   );

   wire              nchip1 = chip1 & !ecs;
   wire              nchip3 = chip3 & !ecs;

   always @(*) begin
      case ({aron,memory_config})
        5'b0_0000 : bank = {  kick, kick1mb,  1'b0,  1'b0,   1'b0,  1'b0,          1'b0,  chip3 | chip2 |  chip1 | chip0 }; // 0.5M CHIP
        5'b0_0001 : bank = {  kick, kick1mb,  1'b0,  1'b0,   1'b0,  1'b0, chip3 | chip1,          chip2 |          chip0 }; // 1.0M CHIP
        5'b0_0010 : bank = {  kick, kick1mb,  1'b0,  1'b0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP
        5'b0_0011 : bank = {  kick, kick1mb,  1'b0,  1'b0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP
        5'b0_0100 : bank = {  kick, kick1mb,  1'b0, slow0,   1'b0,  1'b0,          1'b0, nchip3 | chip2 | nchip1 | chip0 }; // 0.5M CHIP + 0.5MB SLOW
        5'b0_0101 : bank = {  kick, kick1mb,  1'b0, slow0,   1'b0,  1'b0, chip3 | chip1,          chip2 |          chip0 }; // 1.0M CHIP + 0.5MB SLOW
        5'b0_0110 : bank = {  kick, kick1mb,  1'b0, slow0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP + 0.5MB SLOW
        5'b0_0111 : bank = {  kick, kick1mb,  1'b0, slow0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP + 0.5MB SLOW
        5'b0_1000 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0,          1'b0,  chip3 | chip2 |  chip1 | chip0 }; // 0.5M CHIP + 1.0MB SLOW
        5'b0_1001 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0, chip3 | chip1,          chip2 |          chip0 }; // 1.0M CHIP + 1.0MB SLOW
        5'b0_1010 : bank = {  kick, kick1mb, slow1, slow0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP + 1.0MB SLOW
        5'b0_1011 : bank = {  kick, kick1mb, slow1, slow0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP + 1.0MB SLOW
        5'b0_1100 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0,          1'b0,  chip3 | chip2 |  chip1 | chip0 }; // 0.5M CHIP + 1.5MB SLOW
        5'b0_1101 : bank = {  kick, kick1mb, slow1, slow0,   1'b0,  1'b0, chip3 | chip1,          chip2 |          chip0 }; // 1.0M CHIP + 1.5MB SLOW
        5'b0_1110 : bank = {  kick, kick1mb, slow1, slow0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP + 1.5MB SLOW
        5'b0_1111 : bank = {  kick, kick1mb, slow1, slow0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP + 1.5MB SLOW

        5'b1_0000 : bank = {  kick, kick1mb, cart,   1'b0,   1'b0,  1'b0,          1'b0,  chip3 | chip2 |  chip1 | chip0 }; // 0.5M CHIP
        5'b1_0001 : bank = {  kick, kick1mb, cart,   1'b0,   1'b0,  1'b0, chip1 | chip3,          chip2 |          chip0 }; // 1.0M CHIP
        5'b1_0010 : bank = {  kick, kick1mb, cart,   1'b0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP
        5'b1_0011 : bank = {  kick, kick1mb, cart,   1'b0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP
        5'b1_0100 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0,          1'b0, nchip3 | chip2 | nchip1 | chip0 }; // 0.5M CHIP + 0.5MB SLOW
        5'b1_0101 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, chip1 | chip3,          chip2 |          chip0 }; // 1.0M CHIP + 0.5MB SLOW
        5'b1_0110 : bank = {  kick, kick1mb, cart,  slow0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP + 0.5MB SLOW
        5'b1_0111 : bank = {  kick, kick1mb, cart,  slow0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP + 0.5MB SLOW
        5'b1_1000 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0,          1'b0,  chip3 | chip2 |  chip1 | chip0 }; // 0.5M CHIP + 1.0MB SLOW
        5'b1_1001 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, chip1 | chip3,          chip2 |          chip0 }; // 1.0M CHIP + 1.0MB SLOW
        5'b1_1010 : bank = {  kick, kick1mb, cart,  slow0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP + 1.0MB SLOW
        5'b1_1011 : bank = {  kick, kick1mb, cart,  slow0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP + 1.0MB SLOW
        5'b1_1100 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0,          1'b0, chip3 |  chip2 | chip1 |  chip0 }; // 0.5M CHIP + 1.5MB SLOW
        5'b1_1101 : bank = {  kick, kick1mb, cart,  slow0,   1'b0,  1'b0, chip1 | chip3,          chip2 |          chip0 }; // 1.0M CHIP + 1.5MB SLOW
        5'b1_1110 : bank = {  kick, kick1mb, cart,  slow0,   1'b0, chip2,         chip1,                           chip0 }; // 1.5M CHIP + 1.5MB SLOW
        5'b1_1111 : bank = {  kick, kick1mb, cart,  slow0,  chip3, chip2,         chip1,                           chip0 }; // 2.0M CHIP + 1.5MB SLOW
      endcase
   end

endmodule
