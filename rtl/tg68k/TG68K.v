// --------------------------------------------------------------------------
// --------------------------------------------------------------------------
//
// Copyright (c) 2009-2013 Tobias Gubener --
// Patches by MikeJ, Till Harbaum, Rok Krajnk, Steffen Persvold, ...
// Subdesign fAMpIGA by TobiFlex --
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS For A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// --------------------------------------------------------------------------
// --------------------------------------------------------------------------
//
// 03-14-2016 - Converted to Verilog by Steffen Persvold <spersvold@gmail.com>
//
// --------------------------------------------------------------------------

module TG68K
  (
   input  wire                 clk,
   input  wire                 reset,         // low active
   input  wire                 clkena_in,
   input  wire [ 2:0]          IPL,
   input  wire                 dtack,
   input  wire                 vpa,
   input  wire                 ein,
   output wire [31:0]          addr,
   input  wire [15:0]          data_read,
   output wire [15:0]          data_write,
   output reg                  as,
   output reg                  uds,
   output reg                  lds,
   output reg                  rw,
   output reg                  e,
   output reg                  vma,
   output wire                 wrd,
   input  wire                 ena7RDreg,
   input  wire                 ena7WRreg,
   input  wire                 enaWRreg,
   input  wire [15:0]          fromram,
   input  wire                 ramready,
   input  wire [ 1:0]          cpu,
   input  wire [ 2:0]          fastramcfg,
   input  wire                 eth_en,
   output wire                 sel_eth,
   input  wire [15:0]          frometh,
   input  wire                 ethready,
   input  wire                 turbochipram,
   input  wire                 turbokick,
   output wire                 cache_inhibit,
   input  wire                 ovr,
   output wire [31:0]          ramaddr,
   output wire [ 5:0]          cpustate,
   output wire                 nResetOut,
   output wire                 skipFetch,
   output wire                 cpuDMA,
   output wire                 ramlds,
   output wire                 ramuds,
   output wire [ 3:0]          CACR_out,
   output wire [31:0]          VBR_out
   );

   //

   localparam SR_Read        = 2; // 0=>user,   1=>privileged,   2=>switchable with CPU(0)
   localparam VBR_Stackframe = 2; // 0=>no,     1=>yes/extended, 2=>switchable with CPU(0)
   localparam extAddr_Mode   = 2; // 0=>no,     1=>yes,          2=>switchable with CPU(1)
   localparam MUL_Mode       = 2; // 0=>16Bit,  1=>32Bit,        2=>switchable with CPU(1),  3=>no MUL,
   localparam DIV_Mode       = 2; // 0=>16Bit,  1=>32Bit,        2=>switchable with CPU(1),  3=>no DIV,
   localparam BitField       = 2; // 0=>no,     1=>yes,          2=>switchable with CPU(1)

   //

   wire [31:0]                  cpuaddr;
   reg [15:0]                   r_data;
   reg [ 2:0]                   cpuIPL;
   reg                          as_s;
   reg                          as_e;
   reg                          uds_s;
   reg                          uds_e;
   reg                          lds_s;
   reg                          lds_e;
   reg                          rw_s;
   reg                          rw_e;
   reg                          waitm;
   reg                          clkena_e;
   reg [ 1:0]                   S_state;
   wire                         wr;
   wire                         uds_in;
   wire                         lds_in;
   wire [ 1:0]                  state;
   reg                          clkena;
   reg                          vmaena;
   reg                          state_ena;
   reg                          eind;
   reg                          eindd;
   wire                         sel_autoconfig;
   reg [ 1:0]                   autoconfig_out;   // We use this as a counter since we have two cards to configure
   reg [ 3:0]                   autoconfig_data;  // Zorro II RAM
   reg [ 3:0]                   autoconfig_data2; // Zorro III RAM
   reg [ 3:0]                   autoconfig_data3; // Zorro III ethernet
   wire                         sel_fast;
   wire                         sel_chipram;
   reg                          turbochip_ena;
   reg                          turbochip_d;
   reg                          turbokick_d;
   reg [ 3:0]                   slower;

   localparam [3:0]
     SYNC0 = 4'd0, SYNC1 = 4'd1,
     SYNC2 = 4'd2, SYNC3 = 4'd3,
     SYNC4 = 4'd4, SYNC5 = 4'd5,
     SYNC6 = 4'd6, SYNC7 = 4'd7,
     SYNC8 = 4'd8, SYNC9 = 4'd9;

   reg [ 3:0]                   sync_state;

   wire [15:0]                  datatg68;
   wire                         ramcs;

   reg                          z2ram_ena;
   reg [ 7:0]                   z3ram_base;
   reg                          z3ram_ena;
//   reg [ 7:0]                   eth_base;
//   reg                          eth_cfgd;
   wire                         sel_z2ram;
   wire                         sel_z3ram;
   wire                         sel_kickram;

   wire [15:0]                  NMI_vector;
   reg [31:0]                   NMI_addr;
   reg                          NMI_active;
   wire                         sel_interrupt;

   //

   TG68KdotC_Kernel #
     (.SR_Read        (SR_Read),
      .VBR_Stackframe (VBR_Stackframe),
      .extAddr_Mode   (extAddr_Mode),
      .MUL_Mode       (MUL_Mode),
      .DIV_Mode       (DIV_Mode),
      .BitField       (BitField))
   TG68KdotC_Kernel_inst
     (.clk            (clk),
      .nReset         (reset),
      .clkena_in      (clkena),
      .data_in        (datatg68),
      .IPL            (cpuIPL),
      .IPL_autovector (1'b1),
      .berr           (1'b0),
      .CPU            (cpu),
      .addr_out       (cpuaddr),
      .data_write     (data_write),
      .nWr            (wr),
      .nUDS           (uds_in),
      .nLDS           (lds_in),
      .busstate       (state),
      .nResetOut      (nResetOut),
      .FC             ( ),
      .clr_berr       ( ),
      // for debug
      .skipFetch      (skipFetch),
      .regin_out      ( ),
      .CACR_out       (CACR_out),
      .VBR_out        (VBR_out)
      );

   // NMI
   always @(posedge clk) begin
      NMI_addr <= VBR_out + 32'h0000007c;
      if (IPL == 3'b000)
        NMI_active <= 1'b1;
      else if (cpuaddr[23:1] == 23'b1111111111111111111111)
        NMI_active <= 1'b0;

      if (~reset) begin
         NMI_addr   <= 32'h0000007c;
         NMI_active <= 1'b0;
      end
   end

   assign NMI_vector = (cpuaddr[1] == 1'b1) ? 16'h000c : 16'h00a0; // 16-bit bus!

   assign wrd  = wr;
   assign addr = cpuaddr;

   assign datatg68 = (sel_interrupt) ? NMI_vector :
                     (sel_fast)      ? fromram    :
                     //(sel_eth)       ? frometh    :
                     (sel_autoconfig & (autoconfig_out == 2'b01)) ? {autoconfig_data, r_data[11:0]}  : // Zorro II RAM autoconfig
                     (sel_autoconfig & (autoconfig_out == 2'b10)) ? {autoconfig_data2, r_data[11:0]} : // Zorro III RAM autoconfig
                     //(sel_autoconfig & (autoconfig_out == 2'b11)) ? {autoconfig_data3, r_data[11:0]} : // Zorro III ethernet autoconfig
                     r_data;

   assign sel_autoconfig = (fastramcfg[2:0] != 3'b000) & (cpuaddr[23:19] == 5'b11101) & (autoconfig_out != 2'b00); // $E80000 - $EFFFFF
   assign sel_z3ram      = (cpuaddr[31:24] == z3ram_base) & (z3ram_ena == 1'b1);
   assign sel_z2ram      = (cpuaddr[31:24] == 8'b00000000) & ((cpuaddr[23:21] == 3'b001) |
                                                              (cpuaddr[23:21] == 3'b010) |
                                                              (cpuaddr[23:21] == 3'b011) |
                                                              (cpuaddr[23:21] == 3'b100)) & (z2ram_ena == 1'b1);
//   assign sel_eth        = (cpuaddr[31:24] == eth_base) & (eth_cfgd == 1'b1);
   assign sel_chipram    = (cpuaddr[31:24] == 8'b00000000) & (cpuaddr[23:21] == 3'b000) & (turbochip_ena == 1'b1) & (turbochip_d == 1'b1); // $000000 - $1FFFFF
//   assign sel_chipram    = (sel_z3ram != 1'b1) & (turbochip_ena == 1'b1) & (turbochip_d == 1'b1) & (cpuaddr[23:21] == 3'b000);             // $000000 - $1FFFFF
   assign sel_kickram    = (cpuaddr[31:24] == 8'b00000000) & ((cpuaddr[23:19] == 5'b11111) | (cpuaddr[23:19] == 5'b11100)) & (turbochip_ena == 1'b1) & (turbokick_d == 1'b1); // $f8xxxx, e0xxxx
//   assign sel_kickram    = (sel_z3ram != 1'b1) & (turbochip_ena == 1'b1) & (turbokick_d == 1'b1) & (cpuaddr[23:19] == 5'b11111); // $f8xxxx
   assign sel_interrupt  = (cpuaddr[31:2] == NMI_addr[31:2]) & (wr == 1'b0);
   assign sel_fast       = (state != 2'b01) & (sel_z2ram | sel_z3ram | sel_chipram | sel_kickram);
//   assign sel_fast       = (state != 2'b01) & ((cpuaddr[23:21] == 3'b001) |
//                                               (cpuaddr[23:21] == 3'b010) |
//                                               (cpuaddr[23:21] == 3'b011) |
//                                               (cpuaddr[23:21] == 3'b100) |
//                                               (sel_z3ram      == 1'b1) |
//                                               (sel_chipram    == 1'b1) |
//                                               (sel_kickram    == 1'b1)); // $200000 - $9FFFFF

   assign cache_inhibit = (sel_chipram == 1'b1) | (sel_kickram == 1'b1);

//   assign ramcs = (~sel_fast & ~sel_eth) | slower[0]; // | (state[0] & ~state[1]);
   assign ramcs = (~sel_fast) | slower[0]; // | (state[0] & ~state[1]);

   assign cpuDMA = sel_fast;
   assign cpustate = {clkena , slower[1:0], ramcs, state};
   assign ramlds = lds_in;
   assign ramuds = uds_in;
   assign ramaddr[31:25] = 7'b0000000;
   assign ramaddr[   24] = sel_z3ram;  // Remap the Zorro III RAM to 0x1000000
   assign ramaddr[23:21] = ({sel_z2ram, cpuaddr[23:21]} == 4'b1001) ? 3'b100 : // 2 -> 8
                           ({sel_z2ram, cpuaddr[23:21]} == 4'b1010) ? 3'b101 : // 4 -> A
                           ({sel_z2ram, cpuaddr[23:21]} == 4'b1011) ? 3'b110 : // 6 -> C
                           ({sel_z2ram, cpuaddr[23:21]} == 4'b1100) ? 3'b111 : // 8 -> E
                           (sel_kickram == 1'b1                   ) ? 3'b001 :
                           cpuaddr[23:21];                                     // pass through others
   assign ramaddr[20:19] = (sel_kickram == 1'b1 & cpuaddr[23:19] == 5'b11111) ? 2'b11 :
                           (sel_kickram == 1'b1 & cpuaddr[23:19] == 5'b11100) ? 2'b00 :
                           cpuaddr[20:19];

//   assign ramaddr[23:21] = ({sel_z3ram, cpuaddr[23:21]} == 4'b0001) ? 3'b100 : // 2 -> 8
//                           ({sel_z3ram, cpuaddr[23:21]} == 4'b0010) ? 3'b101 : // 4 -> A
//                           ({sel_z3ram, cpuaddr[23:21]} == 4'b0011) ? 3'b110 : // 6 -> C
//                           ({sel_z3ram, cpuaddr[23:21]} == 4'b0100) ? 3'b111 : // 8 -> E
//                           (sel_kickram == 1'b1                   ) ? 3'b001 :
//                           cpuaddr[23:21];                                     // pass through others
//   assign ramaddr[20:19] = (sel_kickram == 1'b1 & cpuaddr[23:19] == 5'b11111) ? 2'b11 :
//                           cpuaddr[20:19];
   assign ramaddr[18: 0] = cpuaddr[18: 0];

   always @(posedge clk) begin
      if (state == 2'b01) begin // No mem access, so safe to switch chipram access mode
         turbochip_d <= turbochipram;
         turbokick_d <= turbokick;
      end

      if (~reset) begin
         turbochip_d <= 1'b0;
         turbokick_d <= 1'b0;
      end
   end

   always @(*) begin : comb_autoconfig_data
      // Zorro II RAM (Up to 8 meg at 0x200000)
      autoconfig_data = 4'b1111;
      if (fastramcfg != 3'b000) begin
         case (cpuaddr[6:1])
           6'b000000: autoconfig_data = 4'b1110;    // Zorro-II card, add mem, no ROM
           6'b000001: begin //autoconfig_data = 4'b0111;   // 4MB
              case (fastramcfg[1:0])
                2'b01:   autoconfig_data = 4'b0110;  // 2MB
                2'b10:   autoconfig_data = 4'b0111;  // 4MB
                default: autoconfig_data = 4'b0000;  // 8MB
              endcase
           end
           6'b001000: autoconfig_data = 4'b1110;    // Manufacturer ID: 0x139c
           6'b001001: autoconfig_data = 4'b1100;
           6'b001010: autoconfig_data = 4'b0110;
           6'b001011: autoconfig_data = 4'b0011;
           6'b010011: autoconfig_data = 4'b1110;    // serial=1
           default: ;
         endcase
      end
   end

   always @(*) begin : comb_autoconfig_data2
      // Zorro III RAM (Up to 16 meg, address assigned by ROM)
      autoconfig_data2 = 4'b1111;
      if (fastramcfg[2] == 1'b1) begin // Zorro III RAM
         case (cpuaddr[6:1])
           6'b000000: autoconfig_data2 = 4'b1010;    // Zorro-III card, add mem, no ROM
           6'b000001: autoconfig_data2 = 4'b0000;    // 8MB (extended to 16 in reg 08)
           6'b000010: autoconfig_data2 = 4'b1110;    // ProductID=0x10 (only setting upper nibble)
           6'b000100: autoconfig_data2 = 4'b0000;    // Memory card, not silenceable, Extended size (16 meg), reserved.
           6'b000101: autoconfig_data2 = 4'b1111;    // 0000 - logical size matches physical size TODO change this to 0001, so it is autosized by the OS, WHEN it will be 24MB.
           6'b001000: autoconfig_data2 = 4'b1110;    // Manufacturer ID: 0x139c
           6'b001001: autoconfig_data2 = 4'b1100;
           6'b001010: autoconfig_data2 = 4'b0110;
           6'b001011: autoconfig_data2 = 4'b0011;
           6'b010011: autoconfig_data2 = 4'b1101;    // serial=2
           default: ;
         endcase
      end
   end

   always @(*) begin : comb_autoconfig_data3
      // Zorro III ethernet
      autoconfig_data3 = 4'b1111;
      if (eth_en == 1'b1) begin
         case (cpuaddr[6:1])
           6'b000000: autoconfig_data3 = 4'b1000;    // 00H: Zorro-III card, no link, no ROM
           6'b000001: autoconfig_data3 = 4'b0001;    // 00L: next board not related, size 64K
           6'b000010: autoconfig_data3 = 4'b1101;    // 04H: ProductID=0x20 (only setting upper nibble)
           6'b000100: autoconfig_data3 = 4'b1110;    // 08H: Not memory, silenceable, normal size, Zorro III
           6'b000101: autoconfig_data3 = 4'b1101;    // 08L: Logical size 64K
           6'b001000: autoconfig_data3 = 4'b1110;    // Manufacturer ID: 0x139c
           6'b001001: autoconfig_data3 = 4'b1100;
           6'b001010: autoconfig_data3 = 4'b0110;
           6'b001011: autoconfig_data3 = 4'b0011;
           6'b010011: autoconfig_data3 = 4'b1100;    // serial=2
           default: ;
         endcase
      end
   end

   always @(posedge clk) begin
      if (enaWRreg == 1'b1) begin
         if (sel_autoconfig == 1'b1 && state == 2'b11 && uds_in == 1'b0 && clkena == 1'b1) begin
            case (cpuaddr[6:1])
              6'b100100: begin // Register 0x48 - config
                 if (autoconfig_out == 2'b01) begin
                    z2ram_ena      <= 1'b1;
                    autoconfig_out <= {fastramcfg[2], 1'b0};
                 end
                 turbochip_ena <= 1'b1;  // enable turbo_chipram after autoconfig has been done...
                                         // FIXME - this is a hack to allow ROM overlay to work.
              end
              6'b100010: begin // Register 0x44, assign base address to ZIII RAM.
                 // We ought to take 16 bits here, but for now we take liberties and use a single byte.
                 if (autoconfig_out == 2'b10) begin
                    z3ram_base     <= data_write[15:8];
                    z3ram_ena      <= 1'b1;
//                    autoconfig_out <= {eth_en, eth_en};
                 end
//                 else if (autoconfig_out == 2'b11) begin
//                    eth_base       <= data_write[15:8];
//                    eth_cfgd       <= 1'b1;
//                    autoconfig_out <= 2'b00;
//                 end
              end
              default: ;
            endcase
         end
      end

      if (~reset) begin
         autoconfig_out <= 2'b01;    // autoconfig on
         turbochip_ena  <= 1'b0;     // disable turbo_chipram until we know kickstart's running...
         z2ram_ena      <= 1'b0;
         z3ram_ena      <= 1'b0;
         z3ram_base     <= 8'h01;
         // eth_cfgd    <= 1'b0;
         // eth_base    <= 8'h02;
      end
   end

   always @(posedge clk) begin
      if (ena7RDreg == 1'b1) begin
        vmaena <= 1'b0;
         if (sync_state == SYNC5) begin
            e <= 1'b1;
         end
         if (sync_state == SYNC9) begin
            e      <= 1'b0;
            vmaena <= ~vma;
         end
      end

      if (~reset) begin
         vmaena <= 1'b0;
         e      <= 1'b0;
      end
   end

   always @(posedge clk) begin
      if (ena7WRreg == 1'b1) begin
         eind  <= ein;
         eindd <= eind;

         case (sync_state)
           SYNC0: sync_state <= SYNC1;
           SYNC1: sync_state <= SYNC2;
           SYNC2: sync_state <= SYNC3;
           SYNC3: begin
              sync_state <= SYNC4;
              vma        <= vpa;
           end
           SYNC4: sync_state <= SYNC5;
           SYNC5: sync_state <= SYNC6;
           SYNC6: sync_state <= SYNC7;
           SYNC7: sync_state <= SYNC8;
           SYNC8: sync_state <= SYNC9;
           default: begin
              sync_state <= SYNC0;
              vma        <= 1'b1;
           end
         endcase

         if (eind == 1'b1 & eindd == 1'b0)
           sync_state <= SYNC7;
      end
   end

   always @(*) begin
//      if ((clkena_in == 1'b1) && (enaWRreg == 1'b1) && ((state == 2'b01) || ((ena7RDreg == 1'b1) && (clkena_e == 1'b1)) || (ramready == 1'b1) || (ethready == 1'b1)))
      if ((clkena_in == 1'b1) && (enaWRreg == 1'b1) && ((state == 2'b01) || ((ena7RDreg == 1'b1) && (clkena_e == 1'b1)) || (ramready == 1'b1)))
        clkena = 1'b1;
      else
        clkena = 1'b0;

      state_ena = 1'b0;
      if (state == 2'b01)
        state_ena = 1'b1;
   end

   always @(posedge clk) begin
      if (clkena == 1'b1) begin
         slower <= 4'b0111;
      end
      else begin
         slower[3:0] <= {1'b0, slower[3:1]}; // {enaWRreg, slower[3:1]};
//         slower[0]   <= ~slower[3] & ~slower[2];
      end
   end

   always @(*) begin
      if (state == 2'b01) begin
         as  = 1'b1;
         rw  = 1'b1;
         uds = 1'b1;
         lds = 1'b1;
      end
      else begin
         as  = (as_s  & as_e) | sel_fast;
         rw  = (rw_s  & rw_e);
         uds = (uds_s & uds_e);
         lds = (lds_s & lds_e);
      end
   end

   always @(posedge clk) begin
      if (ena7WRreg == 1'b1) begin
         as_s  <= 1'b1;
         rw_s  <= 1'b1;
         uds_s <= 1'b1;
         lds_s <= 1'b1;
         case (S_state)
           2'b00: begin
              if ((state != 2'b01) && (sel_fast == 1'b0)) begin
                 uds_s   <= uds_in;
                 lds_s   <= lds_in;
                 S_state <= 2'b01;
              end
           end
           2'b01: begin
              as_s    <= 1'b0;
              rw_s    <= wr;
              uds_s   <= uds_in;
              lds_s   <= lds_in;
              S_state <= 2'b10;
           end
           2'b10: begin
              r_data <= data_read;
              if ((waitm == 1'b0) || ((vma == 1'b0) && (sync_state == SYNC9))) begin
                 S_state <= 2'b11;
              end
              else begin
                 as_s  <= 1'b0;
                 rw_s  <= wr;
                 uds_s <= uds_in;
                 lds_s <= lds_in;
              end
           end
           2'b11: begin
              S_state <= 2'b00;
           end
           default: ;
         endcase
      end

      if (~reset) begin
         S_state <= 2'b00;
         as_s    <= 1'b1;
         rw_s    <= 1'b1;
         uds_s   <= 1'b1;
         lds_s   <= 1'b1;
      end
   end

   always @(posedge clk) begin
      if (ena7RDreg == 1'b1) begin
         as_e     <= 1'b1;
         rw_e     <= 1'b1;
         uds_e    <= 1'b1;
         lds_e    <= 1'b1;
         clkena_e <= 1'b0;

         case (S_state)
           2'b00: begin
              cpuIPL <= IPL;
              if (sel_fast == 1'b0) begin
                 if (state != 2'b01)
                   as_e <= 1'b0;
                 rw_e <= wr;
                 if (wr == 1'b1) begin
                    uds_e <= uds_in;
                    lds_e <= lds_in;
                 end
              end
           end
           2'b01: begin
              as_e  <= 1'b0;
              rw_e  <= wr;
              uds_e <= uds_in;
              lds_e <= lds_in;
           end
           2'b10: begin
              rw_e   <= wr;
              cpuIPL <= IPL;
              waitm  <= dtack;
           end
           default: clkena_e <= 1'b1;
         endcase
      end

      if (~reset) begin
         as_e     <= 1'b1;
         rw_e     <= 1'b1;
         uds_e    <= 1'b1;
         lds_e    <= 1'b1;
         clkena_e <= 1'b0;
      end
   end

endmodule // TG68K
