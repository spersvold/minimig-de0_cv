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
// 2048 words deep, 16 bits wide, fifo
// data is written into the fifo when wr=1
// reading is more or less asynchronous if you read during the rising edge of clk
// because the output data is updated at the falling edge of the clk
// when rd=1, the next data word is selected


module paula_floppy_fifo
  (
   input  wire        clk,                    // bus clock
   input  wire        clk7_en,
   input  wire        reset,                  // reset
   input  wire [15:0] in,                     // data in
   output reg  [15:0] out,                    // data out
   input  wire        rd,                     // read from fifo
   input  wire        wr,                     // write to fifo
   output reg         empty,                  // fifo is empty
   output wire        full,                   // fifo is full
   output wire [11:0] cnt                     // number of entries in FIFO
   );

   //local signals and registers
   reg [15:0]         mem [2047:0];           // 2048 words by 16 bit wide fifo memory (for 2 MFM-encoded sectors)
   reg [11:0]         in_ptr;                 // fifo input pointer
   reg [11:0]         out_ptr;                // fifo output pointer
   wire               equal;                  // lower 11 bits of in_ptr and out_ptr are equal

   // count of FIFO entries
   assign cnt = in_ptr - out_ptr;

   //main fifo memory (implemented using synchronous block ram)
   always @(posedge clk)
     if (clk7_en) begin
        if (wr)
          mem[in_ptr[10:0]] <= in;
     end

   always @(posedge clk)
     if (clk7_en) begin
        out <= mem[out_ptr[10:0]];
     end

   //fifo write pointer control
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          in_ptr <= 12'd0;
        else if(wr)
          in_ptr <= in_ptr + 12'd1;
     end

   // fifo read pointer control
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          out_ptr <= 12'd0;
        else if (rd)
          out_ptr <= out_ptr + 12'd1;
     end

   // check lower 11 bits of pointer to generate equal signal
   assign equal = (in_ptr[10:0]==out_ptr[10:0]) ? 1'b1 : 1'b0;

   // assign output flags, empty is delayed by one clock to handle ram delay
   always @(posedge clk)
     if (clk7_en) begin
        if (equal && (in_ptr[11]==out_ptr[11]))
          empty <= 1'b1;
        else
          empty <= 1'b0;
     end

   assign full = (equal && (in_ptr[11]!=out_ptr[11])) ? 1'b1 : 1'b0;

endmodule
