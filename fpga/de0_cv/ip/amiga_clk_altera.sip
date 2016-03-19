set_global_assignment -entity "amiga_clk_altera" -library "lib_amiga_clk_altera" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "amiga_clk_altera" -library "lib_amiga_clk_altera" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "amiga_clk_altera" -library "lib_amiga_clk_altera" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_amiga_clk_altera" -name SPD_FILE [file join $::quartus(sip_path) "amiga_clk_altera.spd"]

set_global_assignment -library "lib_amiga_clk_altera" -name MISC_FILE [file join $::quartus(sip_path) "amiga_clk_altera_sim/amiga_clk_altera.vo"]
