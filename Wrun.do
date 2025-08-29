vlog -f files.f +cover -covercells
vopt top -o opt +acc
vsim -c opt -do "add wave /top/dut/*; coverage save -onexit cov.ucdb; run -all; coverage report -details -output cov_report.txt" -cover