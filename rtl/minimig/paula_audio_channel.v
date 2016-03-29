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
// This module handles a single amiga audio channel. attached modes are not supported

module paula_audio_channel
  (
   input  wire        clk,              // bus clock
   input  wire        clk7_en,
   input  wire        cck,              // colour clock enable
   input  wire        reset,            // reset
   input  wire        aen,              // address enable
   input  wire        dmaena,           // dma enable
   input  wire [ 3:1] reg_address_in,   // register address input
   input  wire [15:0] data,             // bus data input
   output wire [ 6:0] volume,           // channel volume output
   output wire [ 7:0] sample,           // channel sample output
   output wire        intreq,           // interrupt request
   input  wire        intpen,           // interrupt pending input
   output  reg        dmareq,           // dma request
   output  reg        dmas,             // dma special (restart)
   input  wire        strhor            // horizontal strobe
   );

   //register names and addresses
   localparam  AUDLEN = 4'h4;
   localparam  AUDPER = 4'h6;
   localparam  AUDVOL = 4'h8;
   localparam  AUDDAT = 4'ha;

   //local signals
   reg [15:0]         audlen;         // audio length register
   reg [15:0]         audper;         // audio period register
   reg [ 6:0]         audvol;         // audio volume register
   reg [15:0]         auddat;         // audio data register

   reg [15:0]         datbuf;         // audio data buffer
   reg [ 2:0]         audio_state;    // audio current state
   reg [ 2:0]         audio_next;     // audio next state

   wire               datwrite;       // data register is written
   reg                volcntrld;      // not used

   reg                pbufld1;        // load output sample from sample buffer

   reg [15:0]         percnt;         // audio period counter
   reg                percount;       // decrease period counter
   reg                percntrld;      // reload period counter
   wire               perfin;         // period counter expired

   reg [15:0]         lencnt;         // audio length counter
   reg                lencount;       // decrease length counter
   reg                lencntrld;      // reload length counter
   wire               lenfin;         // length counter expired

   reg                AUDxDAT;        // audio data buffer was written
   wire               AUDxON;         // audio DMA channel is enabled
   reg                AUDxDR;         // audio DMA request
   reg                AUDxIR;         // audio interrupt request
   wire               AUDxIP;         // audio interrupt is pending

   reg                intreq2_set;
   reg                intreq2_clr;
   reg                intreq2;        // buffered interrupt request

   reg                dmasen;         // pointer register reloading request
   reg                penhi;          // enable high byte of sample buffer

   reg                silence;        // AMR: disable audio if repeat length is 1
   reg                silence_d;      // AMR: disable audio if repeat length is 1
   reg                dmaena_d;


   //length register bus write
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          audlen[15:0] <= 16'h00_00;
        else if (aen && (reg_address_in[3:1]==AUDLEN[3:1]))
          audlen[15:0] <= data[15:0];
     end

   //period register bus write
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          audper[15:0] <= 16'h00_00;
        else if (aen && (reg_address_in[3:1]==AUDPER[3:1]))
          audper[15:0] <= data[15:0];
     end

   //volume register bus write
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          audvol[6:0] <= 7'b000_0000;
        else if (aen && (reg_address_in[3:1]==AUDVOL[3:1]))
          audvol[6:0] <= data[6:0];
     end

   //data register strobe
   assign datwrite = (aen && (reg_address_in[3:1]==AUDDAT[3:1])) ? 1'b1 : 1'b0;

   //data register bus write
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          auddat[15:0] <= 16'h00_00;
        else if (datwrite)
          auddat[15:0] <= data[15:0];
     end

   always @(posedge clk)
     if (clk7_en) begin
        if (datwrite)
          AUDxDAT <= 1'b1;
        else if (cck)
          AUDxDAT <= 1'b0;
     end

   assign  AUDxON = dmaena;  //dma enable

   assign  AUDxIP = intpen;  //audio interrupt pending

   assign intreq = AUDxIR;    //audio interrupt request

   //period counter
   always @(posedge clk)
     if (clk7_en) begin
        if (percntrld && cck)//load period counter from audio period register
          percnt[15:0] <= audper[15:0];
        else if (percount && cck)//period counter count down
          percnt[15:0] <= percnt[15:0] - 16'd1;
     end

   assign perfin = (percnt[15:0]==1 && cck) ? 1'b1 : 1'b0;

   //length counter
   always @(posedge clk)
     if (clk7_en) begin
        if (lencntrld && cck) begin //load length counter from audio length register
           lencnt[15:0] <= (audlen[15:0]);
           silence<=1'b0;
           if(audlen==1 || audlen==0)
             silence<=1'b1;
        end
        else if (lencount && cck)//length counter count down
          lencnt[15:0] <= (lencnt[15:0] - 1);
        // Silence fix
        dmaena_d<=dmaena;
        if(dmaena_d==1'b1 && dmaena==1'b0) begin
           silence_d<=1'b1; // Prevent next write from unsilencing the channel.
           silence<=1'b1;
        end
        if(AUDxDAT && cck)  // Unsilence the channel if the CPU writes to AUDxDAT
          if(silence_d)
            silence_d<=1'b0;
          else
            silence<=1'b0;
     end

   assign lenfin = (lencnt[15:0]==1 && cck) ? 1'b1 : 1'b0;

   //audio buffer
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          datbuf[15:0] <= 16'h00_00;
        else if (pbufld1 && cck)
          datbuf[15:0] <= auddat[15:0];
     end

   //assign sample[7:0] = penhi ? datbuf[15:8] : datbuf[7:0];
   assign sample[7:0] = silence ? 8'b0 : (penhi ? datbuf[15:8] : datbuf[7:0]);

   //volume output
   assign volume[6:0] = audvol[6:0];

   //dma request logic
   always @(posedge clk)
     if (clk7_en) begin
        if (reset) begin
           dmareq <= 1'b0;
           dmas <= 1'b0;
        end
        else if (AUDxDR && cck) begin
           dmareq <= 1'b1;
           dmas <= dmasen | lenfin;
        end
        else if (strhor) begin //dma request are cleared when transfered to Agnus
           dmareq <= 1'b0;
           dmas <= 1'b0;
        end
     end

   //buffered interrupt request
   always @(posedge clk)
     if (clk7_en) begin
        if (cck)
          if (intreq2_set)
            intreq2 <= 1'b1;
          else if (intreq2_clr)
            intreq2 <= 1'b0;
     end

   //audio states
   localparam AUDIO_STATE_0 = 3'b000;
   localparam AUDIO_STATE_1 = 3'b001;
   localparam AUDIO_STATE_2 = 3'b011;
   localparam AUDIO_STATE_3 = 3'b010;
   localparam AUDIO_STATE_4 = 3'b110;

   //audio channel state machine
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          audio_state <= AUDIO_STATE_0;
        else if (cck)
          audio_state <= audio_next;
     end

   //transition function
   always @(*) begin
      case (audio_state)

        AUDIO_STATE_0: begin //audio FSM idle state
           intreq2_clr = 1'b1;
           intreq2_set = 1'b0;
           lencount = 1'b0;
           penhi = 1'b0;
           percount = 1'b0;
           percntrld = 1'b1;

           if (AUDxON) begin //start of DMA driven audio playback
              audio_next = AUDIO_STATE_1;
              AUDxDR = 1'b1;
              AUDxIR = 1'b0;
              dmasen = 1'b1;
              lencntrld = 1'b1;
              pbufld1 = 1'b0;
              volcntrld = 1'b0;
           end
           else if (AUDxDAT && !AUDxON && !AUDxIP) begin  //CPU driven audio playback
              audio_next = AUDIO_STATE_3;
              AUDxDR = 1'b0;
              AUDxIR = 1'b1;
              dmasen = 1'b0;
              lencntrld = 1'b0;
              pbufld1 = 1'b1;
              volcntrld = 1'b1;
           end
           else begin
              audio_next = AUDIO_STATE_0;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              dmasen = 1'b0;
              lencntrld = 1'b0;
              pbufld1 = 1'b0;
              volcntrld = 1'b0;
           end
        end

        AUDIO_STATE_1: begin //audio DMA has been enabled
           dmasen = 1'b0;
           intreq2_clr = 1'b1;
           intreq2_set = 1'b0;
           lencntrld = 1'b0;
           penhi = 1'b0;
           percount = 1'b0;

           if (AUDxON && AUDxDAT) begin //requested data has arrived
              audio_next = AUDIO_STATE_2;
              AUDxDR = 1'b1;
              AUDxIR = 1'b1;
              lencount = ~lenfin;
              pbufld1 = 1'b0;  //first data received, discard it since first data access is used to reload pointer
              percntrld = 1'b0;
              volcntrld = 1'b0;
           end
           else if (!AUDxON) begin //audio DMA has been switched off so go to IDLE state
              audio_next = AUDIO_STATE_0;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              lencount = 1'b0;
              pbufld1 = 1'b0;
              percntrld = 1'b0;
              volcntrld = 1'b0;
           end
           else begin
              audio_next = AUDIO_STATE_1;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              lencount = 1'b0;
              pbufld1 = 1'b0;
              percntrld = 1'b0;
              volcntrld = 1'b0;
           end
        end

        AUDIO_STATE_2: begin //audio DMA has been enabled
           dmasen = 1'b0;
           intreq2_clr = 1'b1;
           intreq2_set = 1'b0;
           lencntrld = 1'b0;
           penhi = 1'b0;
           percount = 1'b0;

           if (AUDxON && AUDxDAT) begin //requested data has arrived
              audio_next = AUDIO_STATE_3;
              AUDxDR = 1'b1;
              AUDxIR = 1'b0;
              lencount = ~lenfin;
              pbufld1 = 1'b1;  //new data has been just received so put it in the output buffer
              percntrld = 1'b1;
              volcntrld = 1'b1;
           end
           else if (!AUDxON) begin //audio DMA has been switched off so go to IDLE state
              audio_next = AUDIO_STATE_0;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              lencount = 1'b0;
              pbufld1 = 1'b0;
              percntrld = 1'b0;
              volcntrld = 1'b0;
           end
           else begin
              audio_next = AUDIO_STATE_2;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              lencount = 1'b0;
              pbufld1 = 1'b0;
              percntrld = 1'b0;
              volcntrld = 1'b0;
           end
        end

        AUDIO_STATE_3: begin //first sample is being output
           AUDxDR = 1'b0;
           AUDxIR = 1'b0;
           dmasen = 1'b0;
           intreq2_clr = 1'b0;
           intreq2_set = lenfin & AUDxON & AUDxDAT;
           lencount = ~lenfin & AUDxON & AUDxDAT;
           lencntrld = lenfin & AUDxON & AUDxDAT;
           pbufld1 = 1'b0;
           penhi = 1'b1;
           volcntrld = 1'b0;

           if (perfin) begin //if period counter expired output other sample from buffer
              audio_next = AUDIO_STATE_4;
              percount = 1'b0;
              percntrld = 1'b1;
           end
           else begin
              audio_next = AUDIO_STATE_3;
              percount = 1'b1;
              percntrld = 1'b0;
           end
        end

        AUDIO_STATE_4: begin //second sample is being output
           dmasen = 1'b0;
           intreq2_set = lenfin & AUDxON & AUDxDAT;
           lencount = ~lenfin & AUDxON & AUDxDAT;
           lencntrld = lenfin & AUDxON & AUDxDAT;
           penhi = 1'b0;
           volcntrld = 1'b0;

           if (perfin && (AUDxON || !AUDxIP)) begin //period counter expired and audio DMA active
              audio_next = AUDIO_STATE_3;
              AUDxDR = AUDxON;
              AUDxIR = (intreq2 & AUDxON) | ~AUDxON;
              intreq2_clr = intreq2;
              pbufld1 = 1'b1;
              percount = 1'b0;
              percntrld = 1'b1;
           end
           else if (perfin && !AUDxON && AUDxIP) begin //period counter expired and audio DMA inactive
              audio_next = AUDIO_STATE_0;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              intreq2_clr = 1'b0;
              pbufld1 = 1'b0;
              percount = 1'b0;
              percntrld = 1'b0;
           end
           else begin
              audio_next = AUDIO_STATE_4;
              AUDxDR = 1'b0;
              AUDxIR = 1'b0;
              intreq2_clr = 1'b0;
              pbufld1 = 1'b0;
              percount = 1'b1;
              percntrld = 1'b0;
           end
        end

        default: begin
           audio_next = AUDIO_STATE_0;
           AUDxDR = 1'b0;
           AUDxIR = 1'b0;
           dmasen = 1'b0;
           intreq2_clr = 1'b0;
           intreq2_set = 1'b0;
           lencntrld = 1'b0;
           lencount = 1'b0;
           pbufld1 = 1'b0;
           penhi = 1'b0;
           percount = 1'b0;
           percntrld = 1'b0;
           volcntrld = 1'b0;
        end
      endcase

   end

endmodule
