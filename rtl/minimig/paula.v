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
//
// This is paula
//
// 06-03-2005   -started coding
// 19-03-2005   -added interupt controller and uart
// 04-09-2005   -added blitter finished interrupt
// 19-10-2005   -removed cck (color clock enable) input
//                              -removed intb signal
//                              -added sof signal
// 23-10-2005   -added dmal signal
//                              -added paula part of DMACON
// 21-11-2005   -added floppy controller
//                              -added ADKCON/ADCONR registers
//                              -added local horbeam counter
// 27-11-2005   -den is now active low (_den)
//                              -some typo's fixed
// 11-12-2005   -disable syncword interrupt
// 13-12-2005   -enable syncword interrupt
// 27-12-2005   -cleaned up code
// 28-12-2005   -added audio module
// 03-01-2006   -added dmas to avoid interference with copper cycles
// 07-01-2006   -added dmas for disk controller
// 06-02-2006   -added user disk control input
// 03-07-2007   -moved interrupt controller and uart to this file to reduce number of sourcefiles
// JB:
// 2008-09-24   - code clean-up
//                              - added support for floppy _sel[3:1] signals
// 2008-09-30   - removed user disk control input
// 2008-10-12   - source clean-up
// 2009-01-08   - added audio_dmal, audio_dmas
// 2009-03-08   - removed horbeam counter and sol
//                              - added strhor
// 2009-04-05   - code clean-up
// 2009-05-24   - clean-up & renaming
// 2009-07-10   - implementation of intreq[14] (Unreal needs it)
// 2009-11-14 - added 28 MHz clock input for sigma-delta modulator
// RK:
// 2013-03-21 - translated & added a new more compatible uart core written by madeho@minimig.net


module paula
  (
   // system bus interface
   input  wire        clk,                     // 28 MHz system clock
   input  wire        clk7_en,
   input  wire        clk7n_en,
   input  wire        cck,                     // colour clock enable
   input  wire        reset,                   // reset
   input  wire [ 8:1] reg_address_in,          // register address inputs
   input  wire [15:0] data_in,                 // bus data in
   output wire [15:0] data_out,                // bus data out
   //serial (uart)
   output wire        txd,                     // serial port transmitted data
   input  wire        rxd,                     // serial port received data
   //interrupts and dma
   input  wire        ntsc,                    // PAL/NTSC mode
   input  wire        sof,                     // start of vertical frame
   input  wire        strhor,                  // start of video line (latches audio DMA requests)
   input  wire        vblint,                  // vertical blanking interrupt trigger
   input  wire        int2,                    // level 2 interrupt
   input  wire        int3,                    // level 3 interrupt
   input  wire        int6,                    // level 6 interrupt
   output wire [ 2:0] _ipl,                    // m68k interrupt request
   output wire [ 3:0] audio_dmal,              // audio dma data transfer request (to Agnus)
   output wire [ 3:0] audio_dmas,              // audio dma location pointer restart (to Agnus)
   output wire        disk_dmal,               // disk dma data transfer request (to Agnus)
   output wire        disk_dmas,               // disk dma special request (to Agnus)
   //disk control signals from cia and user
   input  wire        _step,                   // step heads of disk
   input  wire        direc,                   // step heads direction
   input  wire [ 3:0] _sel,                    // disk select
   input  wire        side,                    // upper/lower disk head
   input  wire        _motor,                  // disk motor control
   output wire        _track0,                 // track zero detect
   output wire        _change,                 // disk has been removed from drive
   output wire        _ready,                  // disk is ready
   output wire        _wprot,                  // disk is write-protected
   output wire        index,                   // disk index pulse
   output wire        disk_led,                // disk activity LED
   //flash drive host controller interface (SPI)
   input  wire        _scs,                    // async. serial data enable
   input  wire        sdi,                     // async. serial data input
   output wire        sdo,                     // async. serial data output
   input  wire        sck,                     // async. serial data clock
   //audio outputs
   output wire        left,                    // audio bitstream left
   output wire        right,                   // audio bitstream right
   output wire [14:0] ldata,                   // left DAC data
   output wire [14:0] rdata,                   // right DAC data
   // system configuration
   input  wire [ 1:0] floppy_drives,           // number of extra floppy drives
   // direct sector read from SD card
   input  wire        direct_scs,              // spi select line for direct transfers from SD card
   input  wire        direct_sdi,              // spi data line for direct transfers from SD card
   // emulated Hard Disk Drive signals
   input  wire        hdd_cmd_req,             // command request
   input  wire        hdd_dat_req,             // data request
   output wire [ 2:0] hdd_addr,                // task file register address
   output wire [15:0] hdd_data_out,            // data bus output
   input  wire [15:0] hdd_data_in,             // data bus input
   output wire        hdd_wr,                  // task file write enable
   output wire        hdd_status_wr,           // drive status write enable
   output wire        hdd_data_wr,             // data port write enable
   output wire        hdd_data_rd,             // data port read enable
   // fifo / track display
   output wire [ 7:0] trackdisp,
   output wire [13:0] secdisp,
   output wire        floppy_fwr,
   output wire        floppy_frd
   );

   //--------------------------------------------------------------------------------------

   //register names and addresses
   parameter DMACON  = 9'h096;
   parameter ADKCON  = 9'h09e;
   parameter ADKCONR = 9'h010;

   //local signals
   reg  [4:0]         dmacon;                  // dmacon paula bits
   reg                dmaen;                   // master dma enable
   reg  [14:0]        adkcon;                  // audio and disk control register
   wire [15:0]        uartdata_out;            // UART data out
   wire [15:0]        intdata_out;             // interrupt controller data out
   wire [15:0]        diskdata_out;            // disk controller data out
   wire [15:0]        adkconr;                 // ADKCONR register data out
   wire               rbfmirror;               // rbf mirror (from uart to interrupt controller)
   wire               rxint;                   // uart rx interrupt request
   wire               txint;                   // uart tx interrupt request
   wire               blckint;                 // disk block finished interrupt
   wire               syncint;                 // disk syncword match interrupt
   wire [3:0]         audint;                  // audio channels 0,1,2,3 interrupt request
   wire [3:0]         audpen;                  // audio channels 0,1,2,3 interrupt pending
   wire [3:0]         auden;                   // audio channels 0,1,2,3 dma enable
   wire               dsken;                   // disk dma enable

   //--------------------------------------------------------------------------------------
   //--------------------------------------------------------------------------------------

   //data_out multiplexer
   assign data_out = uartdata_out | intdata_out | diskdata_out | adkconr;

   //--------------------------------------------------------------------------------------

   //DMACON register write
   //NOTE: this register is also present in the Agnus module,
   //there DMACONR (read) is implemented
   always @(posedge clk)
     if (clk7_en) begin
        if (reset) begin
           dmaen <= 0;
           dmacon <= 5'd0;
        end
        else if (reg_address_in[8:1]==DMACON[8:1]) begin
           if (data_in[15])
             {dmaen,dmacon[4:0]} <= {dmaen,dmacon[4:0]} | {data_in[9],data_in[4:0]};
           else
             {dmaen,dmacon[4:0]} <= {dmaen,dmacon[4:0]} & (~{data_in[9],data_in[4:0]});
        end
     end

   //assign disk and audio dma enable bits
   assign  dsken = dmacon[4] & dmaen;
   assign  auden[3] = dmacon[3] & dmaen;
   assign  auden[2] = dmacon[2] & dmaen;
   assign  auden[1] = dmacon[1] & dmaen;
   assign  auden[0] = dmacon[0] & dmaen;

   //--------------------------------------------------------------------------------------

   //ADKCON register write
   always @(posedge clk)
     if (clk7_en) begin
        if (reset)
          adkcon <= 15'd0;
        else if (reg_address_in[8:1]==ADKCON[8:1]) begin
           if (data_in[15])
             adkcon[14:0] <= adkcon[14:0] | data_in[14:0];
           else
             adkcon[14:0] <= adkcon[14:0] & (~data_in[14:0]);
        end
     end

   //ADKCONR register
   assign adkconr[15:0] = (reg_address_in[8:1]==ADKCONR[8:1]) ? {1'b0,adkcon[14:0]} : 16'h0000;

   //--------------------------------------------------------------------------------------

   //instantiate uart
   paula_uart pu1
     (
      .clk(clk),
      .clk7_en(clk7_en),
      .reset(reset),
      .rga_i(reg_address_in),
      .data_i(data_in),
      .data_o(uartdata_out),
      .uartbrk(adkcon[11]),
      .rbfmirror(rbfmirror),
      .rxint(rxint),
      .txint(txint),
      .rxd(rxd),
      .txd(txd)
      );

   //instantiate interrupt controller
   paula_intcontroller pi1
     (
      .clk(clk),
      .clk7_en(clk7_en),
      .reset(reset),
      .reg_address_in(reg_address_in),
      .data_in(data_in),
      .data_out(intdata_out),
      .rxint(rxint),
      .txint(txint),
      .vblint(vblint),
      .int2(int2),
      .int3(int3),
      .int6(int6),
      .blckint(blckint),
      .syncint(syncint),
      .audint(audint),
      .audpen(audpen),
      .rbfmirror(rbfmirror),
      ._ipl(_ipl)
      );

   //instantiate floppy controller / flashdrive host interface
   paula_floppy pf1
     (
      .clk(clk),
      .clk7_en(clk7_en),
      .clk7n_en(clk7n_en),
      .reset(reset),
      .ntsc(ntsc),
      .sof(sof),
      .enable(dsken),
      .reg_address_in(reg_address_in),
      .data_in(data_in),
      .data_out(diskdata_out),
      .dmal(disk_dmal),
      .dmas(disk_dmas),
      ._step(_step),
      .direc(direc),
      ._sel(_sel),
      .side(side),
      ._motor(_motor),
      ._track0(_track0),
      ._change(_change),
      ._ready(_ready),
      ._wprot(_wprot),
      .index(index),
      .blckint(blckint),
      .syncint(syncint),
      .wordsync(adkcon[10]),
      ._scs(_scs),
      .sdi(sdi),
      .sdo(sdo),
      .sck(sck),
      .disk_led(disk_led),
      .floppy_drives(floppy_drives),
      .direct_scs(direct_scs),
      .direct_sdi(direct_sdi),
      .hdd_cmd_req(hdd_cmd_req),
      .hdd_dat_req(hdd_dat_req),
      .hdd_addr(hdd_addr),
      .hdd_data_out(hdd_data_out),
      .hdd_data_in(hdd_data_in),
      .hdd_wr(hdd_wr),
      .hdd_status_wr(hdd_status_wr),
      .hdd_data_wr(hdd_data_wr),
      .hdd_data_rd(hdd_data_rd),
      // fifo / track display
      .trackdisp(trackdisp),
      .secdisp(secdisp),
      .floppy_fwr (floppy_fwr),
      .floppy_frd (floppy_frd)
      );

   //instantiate audio controller
   paula_audio ad1
     (
      .clk(clk),
      .clk7_en(clk7_en),
      .cck(cck),
      .rst(reset),
      .strhor(strhor),
      .reg_address_in(reg_address_in),
      .data_in(data_in),
      .dmaena(auden[3:0]),
      .audint(audint[3:0]),
      .audpen(audpen),
      .dmal(audio_dmal),
      .dmas(audio_dmas),
      .left(left),
      .right(right),
      .ldata(ldata),
      .rdata(rdata)
      );

endmodule
