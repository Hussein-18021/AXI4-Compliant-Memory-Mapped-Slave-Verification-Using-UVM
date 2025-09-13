# AXI4 Memory-Mapped Slave UVM Verification Environment

## Table of Contents
- [Overview](#overview)
- [Design Under Test (DUT)](#design-under-test-dut)
- [UVM Environment Architecture](#uvm-environment-architecture)
- [File Structure](#file-structure)
- [Component Details](#component-details)
- [Test Scenarios](#test-scenarios)
- [Coverage Model](#coverage-model)
- [Building and Running](#building-and-running)
- [Configuration](#configuration)
- [Debug and Analysis](#debug-and-analysis)
- [Known Issues](#known-issues)

## Overview

This repository contains a comprehensive UVM-based verification environment for an AXI4 memory-mapped slave module. The environment provides thorough testing of AXI4 protocol compliance, memory operations, and error handling scenarios.

### Key Features
- ✅ Full AXI4 protocol compliance verification
- ✅ Comprehensive functional coverage model
- ✅ Advanced scoreboarding with golden model
- ✅ Multiple test scenarios (burst types, boundary crossing, error conditions)
- ✅ Configurable memory depth and data width
- ✅ Detailed transaction-level analysis
- ✅ Performance metrics and statistics

### Supported Operations
- **Write Operations**: Single and burst writes with full handshake verification
- **Read Operations**: Single and burst reads with data integrity checking
- **Error Handling**: Boundary crossing detection, memory range violations
- **Protocol Features**: Variable burst lengths (1-21 beats), size support, response handling

## Design Under Test (DUT)

### AXI4 Memory-Mapped Slave (`axi4.v`)

The DUT implements a compliant AXI4 memory-mapped slave with the following characteristics:

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `DATA_WIDTH` | 32 | Data bus width in bits |
| `ADDR_WIDTH` | 16 | Address bus width in bits |
| `MEMORY_DEPTH` | 1024 | Number of memory locations |

#### Supported Features
- **Write Channel**: Full write address, data, and response channel implementation
- **Read Channel**: Complete read address and data channel support
- **Burst Support**: Variable length bursts (INCR type)
- **Error Detection**: SLVERR for boundary crossing and address range violations
- **Memory Protection**: 4KB boundary crossing detection

#### State Machines
```
Write FSM: W_IDLE → W_ADDR → W_DATA → W_RESP → W_IDLE
Read FSM:  R_IDLE → R_ADDR → R_DATA → R_IDLE
```

## UVM Environment Architecture

```
┌─────────────────────────────────────────┐
│                  Test                   │
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│               Environment               │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │    Agent    │ │     Scoreboard      ││
│  │ ┌─────────┐ │ │                     ││
│  │ │Sequencer│ │ │   Golden Model +    ││
│  │ └─────────┘ │ │   Checker Logic     ││
│  │ ┌─────────┐ │ │                     ││
│  │ │ Driver  │ │ │                     ││
│  │ └─────────┘ │ └─────────────────────┘│
│  │ ┌─────────┐ │ ┌─────────────────────┐│
│  │ │ Monitor │ │ │      Coverage       ││
│  │ └─────────┘ │ │                     ││
│  └─────────────┘ │   Functional +      ││
│                  │   Protocol Cov      ││
│                  │                     ││
│                  └─────────────────────┘│
└─────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────┐
│            Interface (DUT)              │
└─────────────────────────────────────────┘
```

## File Structure

### Verification Files
```
Verification_Files/
├── agent.sv              # UVM agent with driver, monitor, sequencer
├── common_cfg.sv         # Common configuration object
├── coverage.sv           # Functional coverage collector
├── driver.sv             # AXI4 transaction driver
├── enum_pkg.sv           # Enumeration package
├── env.sv                # Top-level environment
├── intf.sv               # SystemVerilog interface
├── monitor.sv            # Protocol monitor
├── pkg.sv                # Package wrapper
├── scoreboard.sv         # Golden model + checker
├── sequence.sv           # Test sequences
├── sequencer.sv          # UVM sequencer
└── transaction.sv        # Transaction class
└── top.sv                # top module class
└── assertions.sv         # assertions module

```

### Design Files
```
Design_Files/
├── axi4.v                # Main AXI4 slave module
└── axi_memory.v          # Memory subsystem
```

## Component Details

### Transaction Class (`transaction.sv`)
The transaction class supports comprehensive AXI4 operations with the following key features:

#### Core Fields
```systemverilog
// Operation and test configuration
rand op_t OP;                    // READ/WRITE
rand test_mode_t test_mode;      // Test scenario type
rand burst_type_t burst_type;    // Burst length category
rand data_pattern_t data_pattern; // Data generation pattern

// AXI4 Write Channel
rand logic [ADDR_WIDTH-1:0] AWADDR;
rand logic [7:0] AWLEN;
logic [2:0] AWSIZE;
rand logic [DATA_WIDTH-1:0] WDATA[];

// AXI4 Read Channel  
rand logic [ADDR_WIDTH-1:0] ARADDR;
rand logic [7:0] ARLEN;
logic [DATA_WIDTH-1:0] RDATA[];

// Response handling
logic [1:0] BRESP, RRESP;
```

#### Constraint Categories
- **Address Constraints**: Memory range, alignment, boundary targeting
- **Burst Constraints**: Length distribution based on burst type
- **Pattern Constraints**: Data generation for different test modes
- **Protocol Constraints**: Valid signal timing and handshake behavior

### Driver (`driver.sv`)
Implements the comprehensive AXI4 protocol driving with:

#### Write Transaction Flow
1. **Address Phase**: Drive AWADDR, AWLEN, AWSIZE with AWVALID
2. **Data Phase**: Stream WDATA beats with WVALID/WLAST
3. **Response Phase**: Handle BRESP with BREADY

#### Read Transaction Flow  
1. **Address Phase**: Drive ARADDR, ARLEN, ARSIZE with ARVALID
2. **Data Phase**: Collect RDATA beats with RREADY

#### Advanced Features
- Configurable delays and backpressure
- Transaction abortion scenarios
- Timeout detection
- Performance statistics

### Monitor (`monitor.sv`)
Protocol-aware transaction collection:
- **Write Monitoring**: Complete transaction capture from address to response
- **Read Monitoring**: Full burst data collection with RLAST detection
- **Statistics**: Transaction counting and completion tracking

### Scoreboard (`scoreboard.sv`)
Golden model implementation with:

#### Memory Model
```systemverilog
logic [DATA_WIDTH-1:0] golden_memory [MEMORY_DEPTH];
```

#### Checking Logic
- **Write Verification**: Response code validation, memory update verification
- **Read Verification**: Data integrity checking against golden memory
- **Error Detection**: Boundary crossing and range violation validation
- **Statistics**: Pass/fail rates, error analysis

### Coverage (`coverage.sv`)
Multi-dimensional functional coverage, including:

#### Coverage Groups
```systemverilog
// Burst length coverage
covergroup burst_coverage_cg;
    burst_len_cp: coverpoint (tr.OP == WRITE ? tr.AWLEN : tr.ARLEN) {
        bins single = {0};
        bins short_burst[] = {[1:3]};
        bins medium_burst[] = {[4:8]};
        bins long_burst[] = {[9:15]};
        bins verylongp[] = {[16:20]};
    }
endgroup

// Address space coverage
covergroup memory_address_cg;
    addr_combined_cp: coverpoint (word_address) {
        bins low_addr[] = {[0:255]};
        bins mid_addr[] = {[256:511]};
        bins high_addr[] = {[512:1023]};
    }
endgroup
```

## Test Scenarios

### Basic Sequences

#### Simple Write/Read (`simple_write_sequence`, `simple_read_sequence`)
- Single beat transactions
- Baseline functionality verification
- Basic handshake validation

### Advanced Test Scenarios

#### Burst Type Coverage (`burst_type_coverage_sequence`)
Systematically tests all burst lengths:
- **Single Beat**: AWLEN/ARLEN = 0
- **Short Burst**: AWLEN/ARLEN = 1-3  
- **Medium Burst**: AWLEN/ARLEN = 4-8
- **Long Burst**: AWLEN/ARLEN = 9-15
- **Very Long**: AWLEN/ARLEN = 16-20

#### Address Coverage (`address_coverage_sequence`)
Comprehensive address space testing:
- **Low Range**: Addresses 0-255 (word addresses)
- **Mid Range**: Addresses 256-511  
- **High Range**: Addresses 512-1023
- **Cross Coverage**: All combinations with burst types

#### Data Pattern Testing (`data_pattern_coverage_sequence`)
Validates data integrity with patterns:
- **Random Data**: Pseudo-random values
- **All Zeros**: 0x00000000
- **All Ones**: 0xFFFFFFFF  
- **Alternating AA**: 0xAAAAAAAA
- **Alternating 55**: 0x55555555

#### Protocol Coverage (`handshake_coverage_sequence`)
Tests AXI4 handshake scenarios:
- **Normal Operation**: All valid signals asserted
- **Response Ignored**: BREADY/RREADY deasserted
- **Address Abort**: AWVALID/ARVALID not asserted
- **Data Abort**: WVALID patterns
- **Delayed Ready**: Backpressure scenarios

#### Boundary and Error Testing (`boundary_memory_sequence`)
- **4KB Boundary Crossing**: Transactions crossing 4KB boundaries
- **Memory Range Violations**: Addresses beyond valid range
- **Error Response Validation**: SLVERR generation and handling

### Comprehensive Test (`comprehensive_coverage_sequence`)
Executes all test phases sequentially for maximum coverage.

## Coverage Model

### Coverage Categories

| Category | Target | Description |
|----------|---------|-------------|
| **Burst Coverage** | >99% | All burst length bins |
| **Address Coverage** | >99% | Full address space |
| **Data Pattern Coverage** | >99% | All data patterns |
| **Protocol Coverage** | >99% | Handshake scenarios |
| **Cross Coverage** | >99% | Feature interactions |

### Coverage Analysis
The environment provides detailed coverage reports:

```
[COVERAGE_REPORT] ============= COVERAGE REPORT =============
[COVERAGE_REPORT] Burst Coverage:        100.00%
[COVERAGE_REPORT] Address Coverage:      100.00%
[COVERAGE_REPORT] Data Pattern Coverage: 100.00%
[COVERAGE_REPORT] Protocol Coverage:     100.00%
[COVERAGE_REPORT] Cross Coverage:        100.00%
[COVERAGE_REPORT] ==========================================
[COVERAGE_REPORT] TOTAL COVERAGE:        100.00%
[COVERAGE_REPORT] ==========================================
[COVERAGE_REPORT] *** COVERAGE TARGET ACHIEVED! ***
```

<img width="1208" height="185" alt="image" src="https://github.com/user-attachments/assets/2f795450-dade-449d-be71-e0cdbde4c57d" />


### Coverage Gaps Detection
Automatic detection of coverage holes with recommendations:
- Insufficient burst type variety
- Limited address range testing  
- Missing data patterns
- Incomplete handshake scenarios

### Assertions Analysis
The environment provides a detailed assertions report, showing none of the assertions ever failed.

<img width="1523" height="790" alt="image" src="https://github.com/user-attachments/assets/beb50c2b-9339-4981-bcb5-30b2fad573e8" />

### Cover Directives
<img width="1275" height="219" alt="image" src="https://github.com/user-attachments/assets/c7e1f94a-185d-4bb4-978d-28a86c3c7895" />


## Configuration

### Memory Configuration
```systemverilog
// Modify in design parameters
parameter DATA_WIDTH = 32;      // 32/64 bit support
parameter ADDR_WIDTH = 16;      // Address space size  
parameter MEMORY_DEPTH = 1024;  // Memory locations
```

### Test Configuration
```systemverilog
// In test sequences
int num_transactions = 1000;    // Number of transactions
test_mode_t test_mode = RANDOM_MODE; // Test focus area
```

### UVM Configuration
```systemverilog
// Set agent as active/passive
uvm_config_db#(uvm_active_passive_enum)::set(null, "*", "is_active", UVM_ACTIVE);

// Configure interface
uvm_config_db#(virtual intf)::set(null, "*", "intf", vif);
```
## Building and Running

### Prerequisites
- SystemVerilog simulator (i.e., QuestaSim)
- UVM library (IEEE 1800.2 compatible)
- Make utility

### Compilation
```bash
# Compile design and verification files and optimize them
vlog -f files.f +cover -covercells
vopt top -o opt +acc
```

### Execution
```bash
vsim -c opt -assertdebug -do "add wave /top/dut/*; coverage save -onexit cov.ucdb; run -all; coverage report -details -output cov_report.txt" -cover
```

### Waveform
- Write transaction - burst mode - AWLEN=3 (no. of beats = 4)

<img width="1891" height="756" alt="image" src="https://github.com/user-attachments/assets/5c48f115-28d7-4271-9ab8-d45e5efe9f86" />

- Read transaction - burst mode - AWLEN=15 (no. of beats = 16)

<img width="1886" height="433" alt="image" src="https://github.com/user-attachments/assets/e58a72f1-fc53-4d5a-bc02-f2acddc43bd6" />


### Simulation Analysis
The simulation run provides a detailed transcript as follows:

```
[SCOREBOARD] ========== FINAL SCOREBOARD REPORT ==========
[SCOREBOARD] TOTAL TESTS          =  25649
[SCOREBOARD] PASS COUNT           =  25649 (100.0%)
[SCOREBOARD] ERROR COUNT          =      0 (0.0%)
[SCOREBOARD] ============================================
[SCOREBOARD] WRITE COUNT          =  13315 (51.9%)
[SCOREBOARD] READ COUNT           =  12334 (48.1%)
[SCOREBOARD] OKAY RESPONSES       =  25443
[SCOREBOARD] SLVERR RESPONSES     =    206
[SCOREBOARD] ============================================
[SCOREBOARD] NORMAL TRANSACTIONS  =  25443 (99.2%)
[SCOREBOARD] ABORTED TRANSACTIONS =    206 (0.8%)
[SCOREBOARD] BOUNDARY CROSSINGS   =    196 (0.8%)
[SCOREBOARD] MEMORY VIOLATIONS    =    206 (0.8%)
[SCOREBOARD] ============================================
[SCOREBOARD] *** ALL TESTS PASSED! ***
[SCOREBOARD] =============================================

[DRV_STATS] === DRIVER PERFORMANCE STATISTICS ===
[DRV_STATS] Total Write Transactions: 13804
[DRV_STATS] Total Read Transactions:  12796
[DRV_STATS] Total Write Beats:        81137
[DRV_STATS] Total Read Beats:         74864
[DRV_STATS] Failed Transactions:      0
[DRV_STATS] OKAY Responses:           13212
[DRV_STATS] SLVERR Responses:         103
[DRV_STATS] Average Write Burst Size: 5.88
[DRV_STATS] Average Read Burst Size:  5.85
[DRV_STATS] *** ALL DRIVER TRANSACTIONS SUCCESSFUL ***
[DRV_STATS] ======================================

[MON_STATS] === MONITOR STATISTICS ===
[MON_STATS] Write transactions started: 13315
[MON_STATS] Write transactions sent:    13315
[MON_STATS] Read transactions started:  12334
[MON_STATS] Read transactions sent:     12334
[MON_STATS] ==========================
```
## Debug and Analysis

### Verbosity Levels
- **UVM_LOW**: Essential information, pass/fail status
- **UVM_MEDIUM**: Transaction details, coverage updates  
- **UVM_HIGH**: Detailed protocol analysis
- **UVM_DEBUG**: Full signal-level information

### --- UVM Report Summary ---
```
# ** Report counts by severity
# UVM_INFO :327801
# UVM_WARNING :    1
# UVM_ERROR :    0
# UVM_FATAL :    0
# ** Report counts by id
# [CHECK_READ] 12334
# [CHECK_WRITE] 13315
# [COVERAGE_REPORT]    12
# [DRV] 199395
# [DRV_STATS]    12
# [GOLDEN_READ] 12334
# [GOLDEN_WRITE] 13315
# [MON_DEBUG] 25649
# [MON_READ] 12334
# [MON_STATS]     6
# [MON_WRITE] 13315
# [Questa UVM]     2
# [RNTST]     1
# [SCOREBOARD] 25667
# [TEST_DONE]     1
# [UVMTOP]     1
# [address_coverage_sequence]     4
# [agent]     1
# [boundary_memory_sequence]     4
# [burst_type_coverage_sequence]     4
# [comprehensive_coverage_sequence]     8
# [coverage_]     1
# [data_pattern_coverage_sequence]    44
# [driver]     1
# [env]     1
# [handshake_coverage_sequence]     4
# [mixed_operation_sequence]     2
# [monitor]     1
# [protocol_response_coverage_sequence]     4
# [scoreboard]     2
# [sequencer]     1
# [simple_read_sequence]     3
# [simple_write_sequence]     2
# [test]    22
# ** Note: $finish    : C:/questasim64_2021.1/win64/../verilog_src/uvm-1.1d/src/base/uvm_root.svh(430)
#    Time: 1638862 ns  Iteration: 54  Instance: /top
```
### Key Debug Features

#### Transaction Tracing
```systemverilog
`uvm_info("DRV", $sformatf("=== RECEIVED TRANSACTION ===\n%s", 
          req.convert2string()), UVM_MEDIUM)
```

#### Performance Monitoring
- Transaction throughput analysis
- Average burst size calculations
- Error rate statistics
- Memory utilization tracking

#### Protocol Validation
- Handshake timing verification
- Signal assertion checking
- Response code validation
- Burst boundary detection


## Known Issues

### Current Limitations
1. **AXI4-Lite**: Not currently supported (requires separate verification)
2. **Outstanding Transactions**: Single outstanding transaction only
3. **WRAP Bursts**: INCR burst type only supported
4. **Byte Strobes**: WSTRB not implemented

### Planned Enhancements
- [ ] AXI4-Lite protocol support
- [ ] Multiple outstanding transaction support  
- [ ] WRAP/FIXED burst type support
- [ ] Byte-level write enable support
- [ ] AXI4-Stream interface verification
- [ ] Performance benchmarking suite

### Workarounds
- For byte-level testing: Use multiple word-aligned transactions
- For WRAP bursts: Implement a custom sequence with address calculation
- For AXI4-Lite: Use AWLEN/ARLEN = 0 with single beat sequences

---

## Contributing

### Code Style Guidelines
- Follow SystemVerilog LRM naming conventions
- Use meaningful signal and variable names
- Comment complex constraint logic
- Maintain consistent indentation (4 spaces)

### Adding New Features
1. Update the transaction class with new fields
2. Modify constraints as needed
3. Add coverage bins for new features  
4. Create focused test sequence
5. Update documentation


---

**Repository**: AXI4-Compliant-Memory-Mapped-Slave-Verification-Using-UVM 
**Version**: 1.0  
**Last Updated**: September 2025  

If you have any questions or support, please open an issue in the repository.

