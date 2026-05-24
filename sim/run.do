vlib work
vlog design_alt.v tb_alt.v +cover -covercells
vsim -voptargs=+acc work.tb -cover
add wave *
add wave -position insertpoint sim:/tb/u_ram/*
add wave -position insertpoint sim:/tb/u_cache/*
add wave -position insertpoint  \
sim:/tb/u_ram/mem
add wave -position insertpoint  \
sim:/tb/u_cache/cache_valid \
sim:/tb/u_cache/cache_tag \
sim:/tb/u_cache/cache_data
add wave -position insertpoint  \
sim:/tb/Tempaddr
add wave -position insertpoint  \
sim:/tb/mem_temp
# (vsim-4077) Logging very large object: /tb/mem_temp
run -all

