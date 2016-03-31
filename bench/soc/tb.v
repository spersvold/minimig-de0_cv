`timescale 1ns/1ps

module tb;

   initial begin
      // this will cause %t to show simulation times using ns
      $timeformat(-9,3," ns",13);
      $display("%t INFO: module=%m, starting synopsys vpd dumpfile",$time);
      $vcdpluson;
   end

   wire           CLOCK_50;   // 50 MHz
   wire           CLOCK2_50;  // 50 MHz
   wire           CLOCK3_50;  // 50 MHz
   wire           CLOCK4_50;  // 50 MHz
   // reset input
   reg            RESET_N;
   // push button inputs
   reg [  4-1:0]  KEY;        // Pushbutton[3:0]
   // switch inputs
   reg [ 10-1:0]  SW;         // Toggle Switch[9:0]
   // 7-seg display outputs
   wire [  7-1:0] HEX0;       // Seven Segment Digit 0
   wire [  7-1:0] HEX1;       // Seven Segment Digit 1
   wire [  7-1:0] HEX2;       // Seven Segment Digit 2
   wire [  7-1:0] HEX3;       // Seven Segment Digit 3
   wire [  7-1:0] HEX4;       // Seven Segment Digit 4
   wire [  7-1:0] HEX5;       // Seven Segment Digit 5
   // LED outputs
   wire [ 10-1:0] LEDR;       // LED Red[9:0]
   // VGA
   wire           VGA_HS;     // VGA H_SYNC
   wire           VGA_VS;     // VGA V_SYNC
   wire [  4-1:0] VGA_R;      // VGA Red[3:0]
   wire [  4-1:0] VGA_G;      // VGA Green[3:0]
   wire [  4-1:0] VGA_B;      // VGA Blue[3:0]
   // PS2
   wire           PS2_DAT;    // PS2 Keyboard Data
   wire           PS2_CLK;    // PS2 Keyboard Clock
   wire           PS2_MDAT;   // PS2 Mouse Data
   wire           PS2_MCLK;   // PS2 Mouse Clock
   // SDRAM
   wire [ 16-1:0] DRAM_DQ;    // SDRAM Data bus 16 Bits
   wire [ 13-1:0] DRAM_ADDR;  // SDRAM Address bus 13 Bits
   wire           DRAM_LDQM;  // SDRAM Low-byte Data Mask
   wire           DRAM_UDQM;  // SDRAM High-byte Data Mask
   wire           DRAM_WE_N;  // SDRAM Write Enable
   wire           DRAM_CAS_N; // SDRAM Column Address Strobe
   wire           DRAM_RAS_N; // SDRAM Row Address Strobe
   wire           DRAM_CS_N;  // SDRAM Chip Select
   wire [  2-1:0] DRAM_BA;    // SDRAM Bank Address
   wire           DRAM_CLK;   // SDRAM Clock
   wire           DRAM_CKE;   // SDRAM Clock Enable
   // Micro SD-Card
   wire           SD_CLK;     // SD-Card serial clock      - spi CLK
   wire           SD_CMD;     // SD-Card command/response  - spi MOSI
   wire [  4-1:0] SD_DATA;    // SD-Card serial data       - spi MISO [0], spi CS [3]
   // GPIO
   wire [ 36-1:0] GPIO_0;     // General Purpose I/O Slot 0
   wire [ 36-1:0] GPIO_1;     // General Purpose I/O Slot 1


   minimig_de0_cv_top duti
     (.CLOCK_50    (CLOCK_50),
      .CLOCK2_50   (CLOCK2_50),
      .CLOCK3_50   (CLOCK3_50),
      .CLOCK4_50   (CLOCK4_50),

      .RESET_N     (RESET_N),

      .KEY         (KEY),

      .SW          (SW),

      .HEX0        (HEX0),
      .HEX1        (HEX1),
      .HEX2        (HEX2),
      .HEX3        (HEX3),
      .HEX4        (HEX4),
      .HEX5        (HEX5),

      .LEDR        (LEDR),

      .VGA_HS      (VGA_HS),
      .VGA_VS      (VGA_VS),
      .VGA_R       (VGA_R),
      .VGA_G       (VGA_G),
      .VGA_B       (VGA_B),

      .PS2_DAT     (PS2_DAT),
      .PS2_CLK     (PS2_CLK),
      .PS2_MDAT    (PS2_MDAT),
      .PS2_MCLK    (PS2_MCLK),

      .DRAM_DQ     (DRAM_DQ),
      .DRAM_ADDR   (DRAM_ADDR),
      .DRAM_LDQM   (DRAM_LDQM),
      .DRAM_UDQM   (DRAM_UDQM),
      .DRAM_WE_N   (DRAM_WE_N),
      .DRAM_CAS_N  (DRAM_CAS_N),
      .DRAM_RAS_N  (DRAM_RAS_N),
      .DRAM_CS_N   (DRAM_CS_N),
      .DRAM_BA     (DRAM_BA),
      .DRAM_CLK    (DRAM_CLK),
      .DRAM_CKE    (DRAM_CKE),

      .SD_CLK      (SD_CLK),
      .SD_CMD      (SD_CMD),
      .SD_DATA     (SD_DATA),

      .GPIO_0      (GPIO_0),
      .GPIO_1      (GPIO_1));

   //// SDRAM model ////
   mt48lc16m16a2 #
     (.tAC  (5.4),
      .tHZ  (5.4),
      .tOH  (2.5),
      .tMRD (2.0),    // 2 Clk Cycles
      .tRAS (40.0),
      .tRC  (58.0),
      .tRCD (18.0),
      .tRFC (60.0),
      .tRP  (18.0),
      .tRRD (12.0),
      .tWRa (7.0),     // A2 Version - Auto precharge mode (1 Clk + 7 ns)
      .tWRm (14.0))    // A2 Version - Manual precharge mode (14 ns)
   sdram
     (.Dq         (DRAM_DQ),
      .Addr       (DRAM_ADDR),
      .Ba         (DRAM_BA),
      .Clk        (DRAM_CLK),
      .Cke        (DRAM_CKE),
      .Cs_n       (DRAM_CS_N),
      .Ras_n      (DRAM_RAS_N),
      .Cas_n      (DRAM_CAS_N),
      .We_n       (DRAM_WE_N),
      .Dqm        ({DRAM_UDQM, DRAM_LDQM}));

/*
   sd_card #
     (.FNAME  ("sd-card.img"))
   sdcard
     (.sck          (SD_CLK     ),
      .ss           (SD_DATA[3] ),
      .mosi         (SD_CMD     ),
      .miso         (SD_DATA[0] ));
*/
   reg            clk; initial clk = 1'b0;
   always #10 clk = ~clk;

   assign CLOCK_50  = clk;
   assign CLOCK2_50 = clk;
   assign CLOCK3_50 = clk;
   assign CLOCK4_50 = clk;

   localparam [23:0]  REG_RST_ADR         = 24'h800000;  // reset reg  (bit 0 = ctrl reset, bit 1 = minimig reset, bit2 = cpu reset)
   localparam [23:0]  REG_SYS_ADR         = 24'h800004;  // system reg (bits [3:0] = cfg input, bits [18:15] = status output)
   localparam [23:0]  REG_SYS_STAT_ADR    = 24'h800008;  // system status (sdram init done, minimig reset status, cpu reset status, vsync)
   localparam [23:0]  REG_UART_TX_ADR     = 24'h80000c;  // uart transmit reg ([7:0] - transmit byte)
   localparam [23:0]  REG_UART_RX_ADR     = 24'h800010;  // uart receive reg ([7:0] - received byte)
   localparam [23:0]  REG_UART_STAT_ADR   = 24'h800014;  // uart status (bit 0 = rx_valid, 1 = rx_miss, 2 = rx_ready, 3 = tx_ready)
   localparam [23:0]  REG_TIMER_ADR       = 24'h800018;  // timer reg ([15:0] - timer counter)
   localparam [23:0]  REG_SPI_DIV_ADR     = 24'h80001c;  // SPI divider reg
   localparam [23:0]  REG_SPI_CS_ADR      = 24'h800020;  // SPI chip-select reg
   localparam [23:0]  REG_SPI_DAT_ADR     = 24'h800024;  // SPI data reg
   localparam [23:0]  REG_SPI_BLOCK_ADR   = 24'h800028;  // SPI block transfer counter reg

   localparam OSD_CMD_READ      = 32'h00;
   localparam OSD_CMD_RST       = 32'h08;
   localparam OSD_CMD_CLK       = 32'h18;
   localparam OSD_CMD_OSD       = 32'h28;
   localparam OSD_CMD_CHIP      = 32'h04;
   localparam OSD_CMD_CPU       = 32'h14;
   localparam OSD_CMD_MEM       = 32'h24;
   localparam OSD_CMD_VID       = 32'h34;
   localparam OSD_CMD_FLP       = 32'h44;
   localparam OSD_CMD_HDD       = 32'h54;
   localparam OSD_CMD_JOY       = 32'h64;
   localparam OSD_CMD_OSD_WR    = 32'h0c;
   localparam OSD_CMD_WR        = 32'h1c;

   localparam SPI_RST_USR       = 32'h1;
   localparam SPI_RST_CPU       = 32'h2;
   localparam SPI_CPU_HLT       = 32'h4;

   reg [31:0]     rstval;
   reg [31:0]     retval;

   initial begin
      RESET_N = 1'b0;
      KEY     = 4'b0000;
      SW      = 10'b1000000000;
      #1000;
      SW[0]   = 1'b1;
      #1000;
      // Disconnect the or1200 CPU
//      force tb.duti.ctrl_top.ctrl_cpu.icpu_cs = 1'b0;
//      force tb.duti.ctrl_top.ctrl_cpu.icpu_ack = 1'b0;
      RESET_N = 1'b1;
      #1000;
      wait (!tb.duti.ctrl_top.rst);
      #1000;

      SPI_normal();

      $display("%t Unresetting from ctrl block ...", $time);
      write32(REG_RST_ADR, 32'h0);

      $display("%t Waiting for Minimig reset to release", $time);
      wait (!tb.duti.minimig.reset);

      $display("%t INFO: module=%m, starting synopsys vpd dumpfile",$time);
      $vcdpluson;

/*
      $display("%t Initializing OSD controller", $time);
      EnableOsd();
      SPI(OSD_CMD_RST, retval);
      rstval = (SPI_RST_USR | SPI_RST_CPU | SPI_CPU_HLT);
      SPI(rstval, retval);
      DisableOsd();
      SPIN(); SPIN(); SPIN(); SPIN();
      EnableOsd();
      SPI(OSD_CMD_RST, retval);
      rstval = (SPI_RST_CPU | SPI_CPU_HLT);
      SPI(rstval, retval);
      DisableOsd();
      SPIN(); SPIN(); SPIN(); SPIN();
*/
      #1000;

      SPI_fast();

      #1000;

      UploadKickstart("KICK.ROM.hex", 32'h00F80000);

      #10000;
      $finish;
   end

   localparam KEYSIZE = 1544;
   reg [7:0] kickstart_rom[0:(512*1024)+11-1];
   reg [7:0] romkey[0:KEYSIZE-1];

   task SendFile(input have_key, input [31:0] base);
      integer i, j, keyidx;
      reg [31:0] adr, size, data, rdata;
      reg        decrypt;

      begin
         keyidx = 0;

         if (kickstart_rom[ 0] == "A" &&
             kickstart_rom[ 1] == "M" &&
             kickstart_rom[ 2] == "I" &&
             kickstart_rom[ 3] == "R" &&
             kickstart_rom[ 4] == "O" &&
             kickstart_rom[ 5] == "M" &&
             kickstart_rom[ 6] == "T" &&
             kickstart_rom[ 7] == "Y" &&
             kickstart_rom[ 8] == "P" &&
             kickstart_rom[ 9] == "E" &&
             kickstart_rom[10] == "1") begin
            $display("Kickstart ROM is encrypted");

            // The first 11 bytes are the Amiga Forever header
            for (i=0; i<(512*1024); i=i+1)
              kickstart_rom[i] = kickstart_rom[i+11];
            decrypt = 1;
         end
         else begin
            decrypt = 0;
         end

         $write("[");
         for (i=0; i<1024; i=i+1) begin
            if (!(i&31)) $write("*");

            // Decrypt sector if applicable
            if (decrypt) begin
               for (j=0; j<512; j=j+1) begin
                  kickstart_rom[j] = kickstart_rom[j]^romkey[keyidx];
                  keyidx = keyidx + 1;
                  if (keyidx >= KEYSIZE)
                    keyidx = keyidx - KEYSIZE;
               end
            end

            adr = base + i*512;
            EnableOsd();
            SPI(OSD_CMD_WR, rdata);
            SPIN(); SPIN(); SPIN(); SPIN();
            SPI(adr&32'hff, rdata); adr = adr>>8;
            SPI(adr&32'hff, rdata); adr = adr>>8;
            SPIN(); SPIN(); SPIN(); SPIN();
            SPI(adr&32'hff, rdata); adr = adr>>8;
            SPI(adr&32'hff, rdata); adr = adr>>8;
            SPIN(); SPIN(); SPIN(); SPIN();
            for (j=0; j<512; j=j+4) begin
               SPI(kickstart_rom[(i*512)+j+0], rdata);
               SPI(kickstart_rom[(i*512)+j+1], rdata);
               SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN();
               SPI(kickstart_rom[(i*512)+j+2], rdata);
               SPI(kickstart_rom[(i*512)+j+3], rdata);
               SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN();
               data = {kickstart_rom[(i*512)+j+0],
                       kickstart_rom[(i*512)+j+1],
                       kickstart_rom[(i*512)+j+2],
                       kickstart_rom[(i*512)+j+3]};
               read32(base+i*512+j, rdata);
               if (data != rdata) begin
		  $display("Mismatch @ 0x%08h : 0x%08h != 0x%08h", base+i*512+j, data, rdata);
                  #200;
                  $finish;
               end
            end
            DisableOsd();
         end
         $display("]");
      end
   endtask // SendFile

   task UploadKickstart(input [0:1023] fname, input [31:0] base);
      integer fd, have_key;

      begin
         have_key = 0;
         fd = $fopen("ROM.KEY.hex", "rb+");
         if (fd != 0) begin
            $fclose(fd);
            $readmemh("ROM.KEY.hex", romkey);
            have_key = 1;
         end

         fd = $fopen(fname, "rb+");
         if (fd != 0) begin
            $fclose(fd);
            $display("%t Uploading 512KB Kickstart ...", $time);
            $readmemh(fname, kickstart_rom);

            SendFile(have_key, base);
         end
         else begin
            $display("%t No %0s file!", $time, fname);
         end
      end
   endtask

   task write32(input [23:0] adr, input [31:0] data);
      begin
         @(posedge tb.duti.ctrl_top.ctrl_cpu.clk) #1;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_cs  = 1'b1;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_adr = adr;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_we  = 1'b1;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_sel = 4'b1111;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_dat_w = data;
         do begin
            @(posedge tb.duti.ctrl_top.ctrl_cpu.clk) #1;
         end while (tb.duti.ctrl_top.ctrl_cpu.dcpu_ack !== 1'b1);

         release tb.duti.ctrl_top.ctrl_cpu.dcpu_cs;
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_adr;
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_we;
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_sel;
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_dat_w;
      end
   endtask

   task read32(input [23:0] adr, output [31:0] data);
      begin
         @(posedge tb.duti.ctrl_top.ctrl_cpu.clk) #1;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_cs  = 1'b1;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_adr = adr;
         force tb.duti.ctrl_top.ctrl_cpu.dcpu_we  = 1'b0;
         do begin
            @(posedge tb.duti.ctrl_top.ctrl_cpu.clk) #1;
         end while (tb.duti.ctrl_top.ctrl_cpu.dcpu_ack !== 1'b1); // UNMATCHED !!
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_cs;
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_adr;
         release tb.duti.ctrl_top.ctrl_cpu.dcpu_we;
         @(posedge tb.duti.ctrl_top.ctrl_cpu.clk) #1;
         data = tb.duti.ctrl_top.ctrl_cpu.dcpu_dat_r;
      end
   endtask

   task SPI_normal();
      write32(REG_SPI_DIV_ADR, 32'h04);
   endtask

   task SPI_fast();
      write32(REG_SPI_DIV_ADR, 32'h00);
   endtask

   task SPI_write(input [31:0] data);
      write32(REG_SPI_DAT_ADR, data);
   endtask

   task SPI_read(output [31:0] data);
      read32(REG_SPI_DAT_ADR, data);
   endtask

   task SPI(input [31:0] wrdata, output [31:0] rddata);
      SPI_write(wrdata);
      SPI_read(rddata);
   endtask

   task EnableOsd();
      write32(REG_SPI_CS_ADR, 32'h44);
   endtask

   task DisableOsd();
      write32(REG_SPI_CS_ADR, 32'h40);
   endtask

   task SPIN();
      reg [31:0] nu;
      begin
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
         read32(REG_SPI_DIV_ADR, nu);
      end
   endtask // SPIN

endmodule