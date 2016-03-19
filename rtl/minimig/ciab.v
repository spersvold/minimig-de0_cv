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

module ciab
  (
   input  wire       clk,         // clock
   input  wire       clk7_en,
   input  wire       aen,         // adress enable
   input  wire       rd,          // read enable
   input  wire       wr,          // write enable
   input  wire       reset,       // reset
   input  wire [3:0] rs,          // register select (address)
   input  wire [7:0] data_in,     // bus data in
   output wire [7:0] data_out,    // bus data out
   input  wire       tick,        // tick (counter input for TOD timer)
   input  wire       eclk,        // eclk (counter input for timer A/B)
   input  wire       flag,        // flag (set FLG bit in ICR register)
   output wire       irq,         // interrupt request out
   input  wire [5:3] porta_in,    // input port
   output wire [7:6] porta_out,   // output port
   output wire [7:0] portb_out    // output port
   );

   // local signals
   wire [7:0]        icr_out;
   wire [7:0]        tmra_out;
   wire [7:0]        tmrb_out;
   wire [7:0]        tmrd_out;
   reg [7:0]         pa_out;
   reg [7:0]         pb_out;
   wire              alrm;        // TOD interrupt
   wire              ta;          // TIMER A interrupt
   wire              tb;          // TIMER B interrupt
   wire              tmra_ovf;    // TIMER A underflow (for Timer B)
   reg [7:0]         sdr_latch;
   wire [7:0]        sdr_out;
   reg               tick_del;    // required for edge detection

   //----------------------------------------------------------------------------------
   // address decoder
   //----------------------------------------------------------------------------------
   wire              pra,prb,ddra,ddrb,cra,talo,tahi,crb,tblo,tbhi,tdlo,tdme,tdhi,sdr,icrs;
   wire              enable;

   assign enable = aen & (rd | wr);

   // decoder
   assign  pra  = (enable && rs==4'h0) ? 1'b1 : 1'b0;
   assign  prb  = (enable && rs==4'h1) ? 1'b1 : 1'b0;
   assign  ddra = (enable && rs==4'h2) ? 1'b1 : 1'b0;
   assign  ddrb = (enable && rs==4'h3) ? 1'b1 : 1'b0;
   assign  talo = (enable && rs==4'h4) ? 1'b1 : 1'b0;
   assign  tahi = (enable && rs==4'h5) ? 1'b1 : 1'b0;
   assign  tblo = (enable && rs==4'h6) ? 1'b1 : 1'b0;
   assign  tbhi = (enable && rs==4'h7) ? 1'b1 : 1'b0;
   assign  tdlo = (enable && rs==4'h8) ? 1'b1 : 1'b0;
   assign  tdme = (enable && rs==4'h9) ? 1'b1 : 1'b0;
   assign  tdhi = (enable && rs==4'hA) ? 1'b1 : 1'b0;
   assign  sdr  = (enable && rs==4'hC) ? 1'b1 : 1'b0;
   assign  icrs = (enable && rs==4'hD) ? 1'b1 : 1'b0;
   assign  cra  = (enable && rs==4'hE) ? 1'b1 : 1'b0;
   assign  crb  = (enable && rs==4'hF) ? 1'b1 : 1'b0;

   //----------------------------------------------------------------------------------
   // data_out multiplexer
   //----------------------------------------------------------------------------------
   assign data_out = icr_out | tmra_out | tmrb_out | tmrd_out | sdr_out | pb_out | pa_out;

   // fake serial port data register
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          sdr_latch[7:0] <= 8'h00;
        else if (wr & sdr)
          sdr_latch[7:0] <= data_in[7:0];
     end

   // sdr register read
   assign sdr_out = (!wr && sdr) ? sdr_latch[7:0] : 8'h00;

   //----------------------------------------------------------------------------------
   // porta
   //----------------------------------------------------------------------------------
   reg [5:3] porta_in2;
   reg [7:0] regporta;
   reg [7:0] ddrporta;

   // synchronizing of input data
   always @(posedge clk)
     if (clk7_en) begin
        porta_in2[5:3] <= porta_in[5:3];
     end

   // writing of output port
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          regporta[7:0] <= 8'd0;
        else if (wr && pra)
          regporta[7:0] <= data_in[7:0];
     end

   // writing of ddr register
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          ddrporta[7:0] <= 8'd0;
        else if (wr && ddra)
          ddrporta[7:0] <= data_in[7:0];
     end

   // reading of port/ddr register
   always @(*) begin
      if (!wr && pra)
        pa_out[7:0] = {porta_out[7:6],porta_in2[5:3],3'b111};
      else if (!wr && ddra)
        pa_out[7:0] = ddrporta[7:0];
      else
        pa_out[7:0] = 8'h00;
   end

   // assignment of output port while keeping in mind that the original 8520 uses pull-ups
   assign porta_out[7:6] = (~ddrporta[7:6]) | regporta[7:6];

   //----------------------------------------------------------------------------------
   // portb
   //----------------------------------------------------------------------------------
   reg [7:0] regportb;
   reg [7:0] ddrportb;

   // writing of output port
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          regportb[7:0] <= 8'd0;
        else if (wr && prb)
          regportb[7:0] <= data_in[7:0];
     end

   // writing of ddr register
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          ddrportb[7:0] <= 8'd0;
        else if (wr && ddrb)
          ddrportb[7:0] <= data_in[7:0];
     end

   // reading of port/ddr register
   always @(*) begin
      if (!wr && prb)
        pb_out[7:0] = portb_out[7:0];
      else if (!wr && ddrb)
        pb_out[7:0] = ddrportb[7:0];
      else
        pb_out[7:0] = 8'h00;
   end

   // assignment of output port while keeping in mind that the original 8520 uses pull-ups
   assign portb_out[7:0] = (~ddrportb[7:0]) | regportb[7:0];

   // deleyed tick signal for edge detection
   always @(posedge clk)
     if (clk7_en) begin
        tick_del <= tick;
     end

   //----------------------------------------------------------------------------------
   // instantiate cia interrupt controller
   //----------------------------------------------------------------------------------
   cia_int cnt
     (
      .clk      (clk),
      .clk7_en  (clk7_en),
      .wr       (wr),
      .reset    (reset),
      .icrs     (icrs),
      .ta       (ta),
      .tb       (tb),
      .alrm     (alrm),
      .flag     (flag),
      .ser      (1'b0),
      .data_in  (data_in),
      .data_out (icr_out),
      .irq      (irq)
      );

   //----------------------------------------------------------------------------------
   // instantiate timer A
   //----------------------------------------------------------------------------------
   cia_timera tmra
     (
      .clk      (clk),
      .clk7_en  (clk7_en),
      .wr       (wr),
      .reset    (reset),
      .tlo      (talo),
      .thi      (tahi),
      .tcr      (cra),
      .data_in  (data_in),
      .data_out (tmra_out),
      .eclk     (eclk),
      .spmode   (),
      .tmra_ovf (tmra_ovf),
      .irq      (ta)
      );

   //----------------------------------------------------------------------------------
   // instantiate timer B
   //----------------------------------------------------------------------------------
   cia_timerb tmrb
     (
      .clk      (clk),
      .clk7_en  (clk7_en),
      .wr       (wr),
      .reset    (reset),
      .tlo      (tblo),
      .thi      (tbhi),
      .tcr      (crb),
      .data_in  (data_in),
      .data_out (tmrb_out),
      .eclk     (eclk),
      .tmra_ovf (tmra_ovf),
      .irq      (tb)
      );

   //----------------------------------------------------------------------------------
   // instantiate timer D
   //----------------------------------------------------------------------------------
   cia_timerd tmrd
     (
      .clk      (clk),
      .clk7_en  (clk7_en),
      .wr       (wr),
      .reset    (reset),
      .tlo      (tdlo),
      .tme      (tdme),
      .thi      (tdhi),
      .tcr      (crb),
      .data_in  (data_in),
      .data_out (tmrd_out),
      .count    (tick & ~tick_del),
      .irq      (alrm)
      );

endmodule
