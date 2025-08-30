package enumming;
    typedef enum {READ, WRITE} op_t;
    typedef enum {RANDOM_MODE, BOUNDARY_CROSSING_MODE, BURST_LENGTH_MODE, DATA_PATTERN_MODE} test_mode_t;
    typedef enum {RANDOM_DATA, ALL_ZEROS, ALL_ONES, ALTERNATING_AA, ALTERNATING_55} data_pattern_t;
    typedef enum {SINGLE_BEAT, SHORT_BURST, MEDIUM_BURST, LONG_BURST} burst_type_t;
endpackage