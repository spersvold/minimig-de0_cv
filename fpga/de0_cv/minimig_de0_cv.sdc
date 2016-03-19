# time information
set_time_format -unit ns -decimal_places 3

#create clocks
create_clock -name pll_in_clk  -period 20.000  [get_ports {CLOCK_50}]
create_clock -name ctrl_pll_in -period 20.000  [get_ports {CLOCK2_50}]

# pll clocks
derive_pll_clocks

# name PLL clocks
set clk_sdram {amiga_clk|amiga_clk_i|amiga_clk_altera_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}
set clk_sys   {amiga_clk|amiga_clk_i|amiga_clk_altera_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}
set clk_chip  {amiga_clk|amiga_clk_i|amiga_clk_altera_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}
set clk_ctrl  {ctrl_top|ctrl_clk|ctrl_clk_i|ctrl_clk_altera_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}

# generated clocks
create_generated_clock -name clk_7   -source [get_pins $clk_chip] -divide_by  4 [get_pins {amiga_clk|clk7_cnt[1]|q}]
create_generated_clock -name spi_clk -source [get_pins $clk_ctrl] -divide_by  2 [get_pins {ctrl_top|ctrl_regs|spi_cnt[0]|q}]

# clock uncertainty
derive_clock_uncertainty

# false paths
set_false_path -from * -to [get_ports {LEDR*}]
set_false_path -from [get_ports {GPIO_*}] -to *
set_false_path -from [get_ports {SW*}] -to *
set_false_path -from [get_ports {RESET_N}] -to *
set_false_path -from * -to [get_ports {VGA_*}]
set_false_path -from * -to [get_ports {GPIO_*}]

# False path to the first D input of the first flop in a synchronizer
set_false_path -to {i_sync:*sync_0*}

# False path the first D input of the Minimig reset synchronizer
set_false_path -to {minimig:minimig|minimig_syscontrol:CONTROL1|smrst0}

# False path the output of SPI_CS_N
set_false_path -from {ctrl_top_nosram:ctrl_top|ctrl_regs:ctrl_regs|spi_cs_n[*]}

# multicycle paths
#set_multicycle_path -to [get_fanouts [get_pins {amiga_clk|clk7_en_reg|q*}]  -through [get_pins -hierarchical *|*ena*]] -setup -end 4
#set_multicycle_path -to [get_fanouts [get_pins {amiga_clk|clk7_en_reg|q*}]  -through [get_pins -hierarchical *|*ena*]] -hold  -end 3
#set_multicycle_path -to [get_fanouts [get_pins {amiga_clk|clk7n_en_reg|q*}] -through [get_pins -hierarchical *|*ena*]] -setup -end 4
#set_multicycle_path -to [get_fanouts [get_pins {amiga_clk|clk7n_en_reg|q*}] -through [get_pins -hierarchical *|*ena*]] -hold  -end 3

# Chip/Sys, Clk7/Sys
set_multicycle_path -from $clk_chip -to $clk_sys  -setup -end   2
set_multicycle_path -from $clk_chip -to $clk_sys  -hold  -end   2
set_multicycle_path -from clk_7     -to $clk_sys  -setup -end   2
set_multicycle_path -from clk_7     -to $clk_sys  -hold  -end   2

# SPI/Chip
set_multicycle_path -from $clk_chip -to spi_clk   -setup -start 2
set_multicycle_path -from $clk_chip -to spi_clk   -hold  -start 2
set_multicycle_path -from spi_clk   -to $clk_chip -setup -end   2
set_multicycle_path -from spi_clk   -to $clk_chip -hold  -end   2

# Ctrl/Sys
set_multicycle_path -from $clk_ctrl -to $clk_sys  -setup -end 2
set_multicycle_path -from $clk_ctrl -to $clk_sys  -hold  -end 2
set_multicycle_path -from $clk_sys  -to $clk_ctrl -setup -end 2
set_multicycle_path -from $clk_sys  -to $clk_ctrl -hold  -end 2
