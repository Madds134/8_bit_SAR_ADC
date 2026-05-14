typedef enum int {
    SPI_FULL,
    SPI_ABORT_MID_CMD,
    SPI_ABORT_MID_DATA,
    SPI_EXTRA_CLOCKS
} spi_frame_kind_e;

class spi_txn;
    rand bit rw;
    rand bit [6:0] addr;
    rand bit [7:0] data;
    rand int unsigned gap_cycles;
    rand spi_frame_kind_e frame_kind;
    rand int unsigned abort_after_bits;
    rand int unsigned extra_clocks;

    function string kind_name();
        case (frame_kind)
            SPI_FULL:           return "FULL";
            SPI_ABORT_MID_CMD:  return "ABORT_MID_CMD";
            SPI_ABORT_MID_DATA: return "ABORT_MID_DATA";
            SPI_EXTRA_CLOCKS:   return "EXTRA_CLOCKS";
            default:            return "UNKNOWN";
        endcase
    endfunction

    function void print(string tag="TXN");
        $display("[%s] kind=%s rw=%0d addr=0x%02h data=0x%02h gap=%0d abort_bits=%0d extra_clocks=%0d",
                tag, kind_name(), rw, addr, data, gap_cycles, abort_after_bits, extra_clocks);
    endfunction
endclass

// Legal transaction class
// It allows: supported addresses, full frames, no aborts, no extra clocks
// IF/FUTURE: adc_result and status are read only, then the constraint needs to be tighened to only allow writes to 0x00 and 0x03
class spi_legal_txn extends spi_txn;

    constraint c_legal {
        addr inside {7'h00, 7'h01, 7'h02, 7'h03};
        frame_kind == SPI_FULL;
        gap_cycles inside {[1:5]};
        abort_after_bits == 0;
        extra_clocks == 0;
        rw dist {0 := 1, 1:= 1};
    }
endclass

// Stress transaction class
// It adds: unsupported addresses, short frames, aborts mid command, aborts mid data, extra clocks, back to back traffic
class spi_stress_txn extends spi_txn;
    constraint c_stress {
        rw dist {0 := 1, 1 := 1};

        // Supported plus unsupported space
        addr dist {
            [7'h00:7'h03] := 70,
            [7'h04:7'h7F] := 30
        };

        // Small gaps for back to back traffic
        gap_cycles inside {[0:2]};

        frame_kind dist {
            SPI_FULL := 40,
            SPI_ABORT_MID_CMD := 20,
            SPI_ABORT_MID_DATA := 20,
            SPI_EXTRA_CLOCKS := 20
        };

        if (frame_kind == SPI_FULL) {
            abort_after_bits == 0;
            extra_clocks == 0;
        }

        if (frame_kind == SPI_ABORT_MID_CMD) {
            abort_after_bits inside {[1:7]};
            extra_clocks == 0;
        }

        if (frame_kind == SPI_ABORT_MID_DATA) {
            abort_after_bits inside {[9:15]};
            extra_clocks == 0;
        }

        if (frame_kind == SPI_EXTRA_CLOCKS) {
            abort_after_bits == 0;
            extra_clocks inside {[1:8]};
        }
    }
endclass