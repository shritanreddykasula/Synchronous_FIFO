vlib work
vdel -all
vlib work

#compilation
vlog fifo_sync_adv.sv
vlog fifo_sync_adv_test.sv

# Elaboration
vsim -voptargs=+acc work.fifo_tb

# Add Wave
add wave *
add wave -r /fifo_tb/dut/*

#simulation
run -all

wave zoom full
