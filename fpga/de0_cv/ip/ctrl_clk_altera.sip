set_global_assignment -entity "ctrl_clk_altera" -library "lib_ctrl_clk_altera" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ctrl_clk_altera" -library "lib_ctrl_clk_altera" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "ctrl_clk_altera" -library "lib_ctrl_clk_altera" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ctrl_clk_altera" -name SPD_FILE [file join $::quartus(sip_path) "ctrl_clk_altera.spd"]

set_global_assignment -library "lib_ctrl_clk_altera" -name MISC_FILE [file join $::quartus(sip_path) "ctrl_clk_altera_sim/ctrl_clk_altera.vo"]
