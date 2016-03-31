`timescale 1ns/10ps

module tb;

   initial begin
      // this will cause %t to show simulation times using ns
      $timeformat(-9,3," ns",13);
   end

   //m68k pins
   wire [23:1]           cpu_address = 23'h0;     // m68k address bus
   wire [15:0]           cpu_data;                // m68k data bus
   wire [15:0]           cpudata_in = 16'h0;      // m68k data in
   wire [ 2:0]           _cpu_ipl;                // m68k interrupt request
   wire                  _cpu_as = 1'b1;          // m68k address strobe
   wire                  _cpu_uds = 1'b1;         // m68k upper data strobe
   wire                  _cpu_lds = 1'b1;         // m68k lower data strobe
   wire                  cpu_r_w = 1'b1;          // m68k read / write
   wire                  _cpu_dtack;              // m68k data acknowledge
   wire                  _cpu_reset;              // m68k reset
   wire                  _cpu_reset_in = 1'b1;    // m68k reset in
   wire [31:0]           cpu_vbr = 32'h0;         // m68k VBR
   wire                  ovr;                     // NMI address decoding override

   //sram pins
   wire [15:0]           ram_data;                // sram data bus
   wire [15:0]           ramdata_in = 16'h0;      // sram data bus in
   wire [21:1]           ram_address;             // sram address bus
   wire                  _ram_bhe;                // sram upper byte select
   wire                  _ram_ble;                // sram lower byte select
   wire                  _ram_we;                 // sram write enable
   wire                  _ram_oe;                 // sram output enable
   wire [47:0]           chip48 = 48'h0;          // big chipram read

   //system pins
   wire                  rst_ext;                 // reset from ctrl block
   wire                  rst_out;                 // minimig reset status
   wire                  clk;                     // 28.37516 MHz clock
   wire                  clk7_en;                 // 7MHz clock enable
   wire                  clk7n_en;                // 7MHz negedge clock enable
   wire                  c1;                      // clock enable signal
   wire                  c3;                      // clock enable signal
   wire                  cck;                     // colour clock enable
   wire [ 9:0]           eclk;                    // ECLK enable (1/10th of CLK)

   wire                  pll_locked;

   //rs232 pins
   wire                  rxd = 1'b0;
   wire                  txd;
   wire                  cts = 1'b0;
   wire                  rts;

   //I/O
   wire [ 7:0]           _joy1 = 8'hff;           // joystick 1 [fire2,fire,up,down,left,right] (default mouse port)
   wire [ 7:0]           _joy2 = 8'hff;           // joystick 2 [fire2,fire,up,down,left,right] (default joystick port)
   wire                  _15khz = 1'b1;           // scandoubler disable
   wire                  msdat;                   // PS2 mouse data
   wire                  msclk;                   // PS2 mouse clk
   wire                  kbddat;                  // PS2 keyboard data
   wire                  kbdclk;                  // PS2 keyboard clk

   //host controller interface (SPI)
   wire [ 2:0]           _scs = 3'b111;           // SPI chip select
   wire                  direct_sdi = 1'b1;       // SD Card direct in
   wire                  sdi = 1'b1;              // SPI data input
   wire                  sdo;                     // SPI data output
   wire                  sck = 1'b1;              // SPI clock

   //video
   wire                  _hsync;                  // horizontal sync
   wire                  _vsync;                  // vertical sync
   wire [ 7:0]           red;                     // red
   wire [ 7:0]           green;                   // green
   wire [ 7:0]           blue;                    // blue

   //audio
   wire                  left;                    // audio bitstream left
   wire                  right;                   // audio bitstream right
   wire [14:0]           ldata;                   // left DAC data
   wire [14:0]           rdata;                   // right DAC data

   // minimig top
   minimig minimig
     (
      //m68k pins
      .cpu_address      (cpu_address      ), // M68K address bus
      .cpu_data         (cpu_data         ), // M68K data bus
      .cpudata_in       (cpudata_in       ), // M68K data in
      ._cpu_ipl         (_cpu_ipl         ), // M68K interrupt request
      ._cpu_as          (_cpu_as          ), // M68K address strobe
      ._cpu_uds         (_cpu_uds         ), // M68K upper data strobe
      ._cpu_lds         (_cpu_lds         ), // M68K lower data strobe
      .cpu_r_w          (cpu_r_w          ), // M68K read / write
      ._cpu_dtack       (_cpu_dtack       ), // M68K data acknowledge
      ._cpu_reset       (_cpu_reset       ), // M68K reset
      ._cpu_reset_in    (_cpu_reset_in    ), // M68K reset out
      .cpu_vbr          (cpu_vbr          ), // M68K VBR
      .ovr              (ovr              ), // NMI override address decoding
      //sram pins
      .ram_data         (ram_data         ), // SRAM data bus
      .ramdata_in       (ramdata_in       ), // SRAM data bus in
      .ram_address      (ram_address      ), // SRAM address bus
      ._ram_bhe         (_ram_bhe         ), // SRAM upper byte select
      ._ram_ble         (_ram_ble         ), // SRAM lower byte select
      ._ram_we          (_ram_we          ), // SRAM write enable
      ._ram_oe          (_ram_oe          ), // SRAM output enable
      .chip48           (chip48           ), // big chipram read
      //system  pins
      .rst_ext          (rst_ext          ), // reset from ctrl block
      .rst_out          (rst_out          ), // minimig reset status
      .clk              (clk              ), // output clock c1 ( 28.687500MHz)
      .clk7_en          (clk7_en          ), // 7MHz clock enable
      .clk7n_en         (clk7n_en         ), // 7MHz negedge clock enable
      .c1               (c1               ), // clk28m clock domain signal synchronous with clk signal
      .c3               (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
      .cck              (cck              ), // colour clock output (3.54 MHz)
      .eclk             (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
      //rs232 pins
      .rxd              (rxd              ), // RS232 receive
      .txd              (txd              ), // RS232 send
      .cts              (cts              ), // RS232 clear to send
      .rts              (rts              ), // RS232 request to send
      //I/O
      ._joy1            (_joy1            ), // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right] (default mouse port)
      ._joy2            (_joy2            ), // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right] (default joystick port)
      ._15khz           (_15khz           ), // scandoubler disable
      .pwrled           (                 ), // power led
      .msdat            (msdat            ), // PS2 mouse data
      .msclk            (msclk            ), // PS2 mouse clk
      .kbddat           (kbddat           ), // PS2 keyboard data
      .kbdclk           (kbdclk           ), // PS2 keyboard clk
      //host controller interface (SPI)
      ._scs             (_scs             ), // SPI chip select
      .direct_sdi       (direct_sdi       ), // SD Card direct in
      .sdi              (sdi              ), // SPI data input
      .sdo              (sdo              ), // SPI data output
      .sck              (sck              ), // SPI clock
      //video
      ._hsync           (_hsync           ), // horizontal sync
      ._vsync           (_vsync           ), // vertical sync
      .red              (red              ), // red
      .green            (green            ), // green
      .blue             (blue             ), // blue
      //audio
      .left             (left             ), // audio bitstream left
      .right            (right            ), // audio bitstream right
      .ldata            (ldata            ), // left DAC data
      .rdata            (rdata            ), // right DAC data
      //user i/o
      .cpu_config       (                 ), // CPU config
      .memcfg           (                 ), // memory config
      .turbochipram     (                 ), // turbo chipRAM
      .turbokick        (                 ), // turbo kickstart
      .init_b           (                 ), // vertical sync for MCU (sync OSD update)
      .fifo_full        (                 ),
      // fifo / track display
      .trackdisp        (                 ), // floppy track number
      .secdisp          (                 ), // sector
      .floppy_fwr       (                 ), // floppy fifo writing
      .floppy_frd       (                 ), // floppy fifo reading
      .hd_fwr           (                 ), // hd fifo writing
      .hd_frd           (                 )  // hd fifo  ading
      );

   amiga_clk amiga_clk
     (
      .rst          (1'b0             ), // async reset input
      .clk_in       (1'b0             ), // input clock     ( 27.000000MHz)
      .clk_114      (                 ), // output clock c0 (114.750000MHz)
      .clk_sdram    (                 ), // output clock c2 (114.750000MHz, -146.25 deg)
      .clk_28       (clk              ), // output clock c1 ( 28.687500MHz)
      .clk_7        (                 ), // output clock 7  (  7.171875MHz)
      .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
      .clk7n_en     (clk7n_en         ), // 7MHz negedge output clock enable (on 28MHz clock domain)
      .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
      .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
      .cck          (cck              ), // colour clock output (3.54 MHz)
      .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
      .locked       (pll_locked       )  // pll locked output
      );

   wire [9:0]            tmds_data0;
   wire [9:0]            tmds_data1;
   wire [9:0]            tmds_data2;

   hdmi_encoder hdmi_encoder
     (.clk          (clk),
      .rst          (rst_out),
      .hsync        (~_hsync),
      .vsync        (~_vsync),
      .red          (red),
      .green        (green),
      .blue         (blue),
      .tmds_data0   (tmds_data0),
      .tmds_data1   (tmds_data1),
      .tmds_data2   (tmds_data2));

   assign rst_ext = !pll_locked;

   initial begin
      wait (rst_out == 1'b0);
      $display("%t INFO: module=%m, starting synopsys vpd dumpfile",$time);
      $vcdpluson;
      #1000000000;
      $finish;
   end

endmodule // tb

module hdmi_encoder
  (
   input  wire       clk,
   input  wire       rst,
   input  wire       hsync,
   input  wire       vsync,
   input  wire [7:0] red,
   input  wire [7:0] green,
   input  wire [7:0] blue,
   output wire [9:0] tmds_data0,
   output wire [9:0] tmds_data1,
   output wire [9:0] tmds_data2
   );

   reg               hsync_d;
   reg               vsync_d;
   reg               hss=0;
   reg               vss=0;
   reg [9:0]         hpos=0;
   reg [9:0]         vpos=0;

   wire              vde;

   always @(posedge clk or posedge rst) begin
      hsync_d <= hsync;
      vsync_d <= vsync;
      hss     <= hsync & ~hsync_d; // rising edge
      vss     <= vsync & ~vsync_d; // rising edge

      if (~hsync_d)
        hpos <= hpos + 10'd1;

      if (hss & ~vsync_d)
        vpos  <= vpos + 10'd1;

      if (hss)
        hpos <= 10'd0;

      if (vss)
        vpos <= 10'd0;
   end

   assign vde = (hpos >= 64) && (hpos < 818) && (vpos >= 32) && (vpos < 516);

   tmds_encode tmds_encode0
     (.clk        (clk),
      .rst        (rst),
      .vd         (red),
      .cd         (2'b00),
      .vde        (vde),
      .tmds       (tmds_data0));

   tmds_encode tmds_encode1
     (.clk        (clk),
      .rst        (rst),
      .vd         (green),
      .cd         (2'b00),
      .vde        (vde),
      .tmds       (tmds_data1));

   tmds_encode tmds_encode2
     (.clk        (clk),
      .rst        (rst),
      .vd         (blue),
      .cd         ({vsync, hsync}),
      .vde        (vde),
      .tmds       (tmds_data2));

endmodule // hdmi_encoder

////////////////////////////////////////////////////////////////////////
// TMDS encoder
// Used to encode HDMI/DVI video data
////////////////////////////////////////////////////////////////////////

module tmds_encode
  (
   input  wire       clk,
   input  wire       rst,
   input  wire [7:0] vd,
   input  wire [1:0] cd,
   input  wire       vde,
   output reg  [9:0] tmds
   );

   localparam CTRLTOKEN0 = 10'b1101010100;
   localparam CTRLTOKEN1 = 10'b0010101011;
   localparam CTRLTOKEN2 = 10'b0101010100;
   localparam CTRLTOKEN3 = 10'b1010101011;

   reg [3:0]         balance_acc;
   wire [3:0]        balance_q_m;
   reg [8:0]         q_m;
   reg [1:0]         cd_q;
   reg               vde_q;

   assign balance_q_m = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         balance_acc <= 4'd0;
         tmds <= 10'h0;
      end
      else begin
         // Cycle 1
         if ((vd[0] + vd[1] + vd[2] + vd[3] + vd[4] + vd[5] + vd[6] + vd[7])>(vd[0]?4'd4:4'd3)) begin
	    q_m <= {1'b0,~^vd[7:0],^vd[6:0],~^vd[5:0],^vd[4:0],~^vd[3:0],^vd[2:0],~^vd[1:0],vd[0]};
         end
         else begin
	    q_m <= {1'b1, ^vd[7:0],^vd[6:0], ^vd[5:0],^vd[4:0], ^vd[3:0],^vd[2:0], ^vd[1:0],vd[0]};
         end

         vde_q <= vde;
         cd_q  <= cd;

         // Cycle 2
         if (vde_q) begin
	    if (balance_q_m==4'h0 || balance_acc==4'h0) begin
	       if (q_m[8]) begin
	          tmds <= {1'b0, q_m[8], q_m[7:0]};
	          balance_acc <= balance_acc+balance_q_m;
	       end
               else begin
	          tmds <= {1'b1, q_m[8], ~q_m[7:0]};
	          balance_acc <= balance_acc-balance_q_m;
	       end
	    end
            else begin
	       if (balance_q_m>>3 == balance_acc[3]) begin
	          tmds <= {1'b1, q_m[8], ~q_m[7:0]};
	          balance_acc <= balance_acc+q_m[8]-balance_q_m;
	       end
               else begin
	          tmds <= {1'b0, q_m[8], q_m[7:0]};
	          balance_acc <= balance_acc-(~q_m[8])+balance_q_m;
	       end
	    end
         end
         else begin
	    balance_acc <= 4'h0;
            case (cd_q)
              2'b00:   tmds <= CTRLTOKEN0;
              2'b01:   tmds <= CTRLTOKEN1;
              2'b10:   tmds <= CTRLTOKEN2;
              default: tmds <= CTRLTOKEN3;
            endcase
         end
      end
   end

endmodule // tmds_encode

////////////////////////////////////////////////////////////////////////
// terc4 encoder
// used to encode the hdmi data packets such as audio
////////////////////////////////////////////////////////////////////////

module terc4_encoder
  (
   input  wire       clk,
   input  wire [3:0] data,
   output reg  [9:0] terc
   );

   reg [9:0]         terc_pre = 0;

   always @(posedge clk) begin
      // Cycle 1
      case (data)
	4'b0000: terc_pre <= 10'b1010011100;
	4'b0001: terc_pre <= 10'b1001100011;
	4'b0010: terc_pre <= 10'b1011100100;
	4'b0011: terc_pre <= 10'b1011100010;
	4'b0100: terc_pre <= 10'b0101110001;
	4'b0101: terc_pre <= 10'b0100011110;
	4'b0110: terc_pre <= 10'b0110001110;
	4'b0111: terc_pre <= 10'b0100111100;
	4'b1000: terc_pre <= 10'b1011001100;
	4'b1001: terc_pre <= 10'b0100111001;
	4'b1010: terc_pre <= 10'b0110011100;
	4'b1011: terc_pre <= 10'b1011000110;
	4'b1100: terc_pre <= 10'b1010001110;
	4'b1101: terc_pre <= 10'b1001110001;
	4'b1110: terc_pre <= 10'b0101100011;
	4'b1111: terc_pre <= 10'b1011000011;
      endcase
      // Cycle 2
      terc <= terc_pre;
   end

endmodule // terc4_encoder

