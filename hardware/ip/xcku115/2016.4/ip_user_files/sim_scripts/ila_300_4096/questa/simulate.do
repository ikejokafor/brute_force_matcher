onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib ila_300_4096_opt

do {wave.do}

view wave
view structure
view signals

do {ila_300_4096.udo}

run -all

quit -force
