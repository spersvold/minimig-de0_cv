module denise_colortable_ram_mf
  (
   input              clock,
   input              enable,
   input              wren,
   input  wire [ 3:0] byteena_a,
   input  wire [ 7:0] rdaddress,
   input  wire [ 7:0] wraddress,
   input  wire [31:0] data,
   output reg  [31:0] q
   );

   reg [31:0]      mem[0:255];

   always @(posedge clock) begin
      if (enable) begin
         if (wren & byteena_a[0]) mem[wraddress][ 7: 0] <= data[ 7: 0];
         if (wren & byteena_a[1]) mem[wraddress][15: 8] <= data[15: 8];
         if (wren & byteena_a[2]) mem[wraddress][23:16] <= data[23:16];
         if (wren & byteena_a[2]) mem[wraddress][31:24] <= data[31:24];
         q <= mem[rdaddress];
      end
   end

endmodule // denise_colortable_ram_mf
