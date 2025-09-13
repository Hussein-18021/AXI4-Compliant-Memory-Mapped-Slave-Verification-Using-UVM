vlog -f files.f +cover -covercells
vopt top -o opt +acc
vsim -c opt -assertdebug -do "add wave /top/dut/*; coverage save -onexit cov.ucdb; run -all; assertion report -file assertions_report.txt; coverage report -details -output cov_report.txt; quit" -cover