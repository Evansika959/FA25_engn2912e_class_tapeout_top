current_design $::env(DESIGN_NAME)
set_units -time ns

set clk_period [expr double($::env(CLOCK_PERIOD))]
set input_delay_value [expr $clk_period * $::env(IO_DELAY_CONSTRAINT) / 100.0]
set output_delay_value [expr $clk_period * $::env(IO_DELAY_CONSTRAINT) / 100.0]
puts "\[INFO] Setting output delay to: $output_delay_value"
puts "\[INFO] Setting input delay to: $input_delay_value"

set clock_ports {clk1_PAD clk2_PAD clk3_PAD clk3_b_PAD}
set created_clocks {}
foreach port $clock_ports {
    set port_obj ""
    if {[catch {get_ports $port} port_obj]} {
        puts "\[WARNING] Clock port $port not found."
        continue
    }
    if {[llength $port_obj] > 0} {
        create_clock -name $port -period $clk_period $port_obj
        lappend created_clocks $port
    } else {
        puts "\[WARNING] Clock port $port not found."
    }
}

if {[llength $created_clocks] == 0} {
    puts "\[WARNING] No clocks created; instantiating virtual clock."
    create_clock -name VIRTUAL_CLK -period $clk_period
    set created_clocks {VIRTUAL_CLK}
}

set clock_objs [get_clocks $created_clocks]
set ref_clock [lindex $clock_objs 0]

set_max_fanout $::env(MAX_FANOUT_CONSTRAINT) [current_design]
if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}
if { [info exists ::env(MAX_CAPACITANCE_CONSTRAINT)] } {
    set_max_capacitance $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]
}

# Bidirectional pads
set bidir_ports [get_ports {bidir_PAD[*]}]
if {[llength $bidir_ports] > 0} {
    set_input_delay -min 0 -clock $ref_clock $bidir_ports
    set_input_delay -max $input_delay_value -clock $ref_clock $bidir_ports
    set_output_delay $output_delay_value -clock $ref_clock $bidir_ports
}

# Input-only pads
set input_ports [get_ports {input_PAD[*]}]
if {[llength $input_ports] > 0} {
    set_input_delay -min 0 -clock $ref_clock $input_ports
    set_input_delay -max $input_delay_value -clock $ref_clock $input_ports
}

# Treat asynchronous resets as false paths
set reset_ports [get_ports {rst_n1_PAD rst_n2_PAD rst_n3_PAD}]
if {[llength $reset_ports] > 0} {
    set_input_delay -min 0 -clock $ref_clock $reset_ports
    set_input_delay -max $input_delay_value -clock $ref_clock $reset_ports
    set_false_path -from $reset_ports
}

# Output load
set cap_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0]
puts "\[INFO] Setting load to: $cap_load"
set_load $cap_load [all_outputs]

puts "\[INFO] Setting clock uncertainty to: $::env(CLOCK_UNCERTAINTY_CONSTRAINT)"
set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) $clock_objs

puts "\[INFO] Setting clock transition to: $::env(CLOCK_TRANSITION_CONSTRAINT)"
set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) $clock_objs

puts "\[INFO] Setting timing derate to: $::env(TIME_DERATING_CONSTRAINT)%"
set_timing_derate -early [expr 1 - ($::env(TIME_DERATING_CONSTRAINT) / 100.0)]
set_timing_derate -late [expr 1 + ($::env(TIME_DERATING_CONSTRAINT) / 100.0)]

if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock $clock_objs
} else {
    set_propagated_clock $clock_objs
}

