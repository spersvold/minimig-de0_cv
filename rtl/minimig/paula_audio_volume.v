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
// this module multiplies a signed 8 bit sample with an unsigned 6 bit volume setting
// it produces a 14bit signed result

module paula_audio_volume
  (
   input  wire [ 7:0] sample,      // signed sample input
   input  wire [ 5:0] volume,      // unsigned volume input
   output wire [13:0] out          // signed product out
   );

   wire [13:0]        sesample;    // sign extended sample
   wire [13:0]        sevolume;    // sign extended volume

   //sign extend input parameters
   assign sesample[13:0] = {{6{sample[7]}},sample[7:0]};
   assign sevolume[13:0] = {8'b00000000,volume[5:0]};

   //multiply, synthesizer should infer multiplier here
   assign out[13:0] = {sesample[13:0] * sevolume[13:0]};

endmodule
