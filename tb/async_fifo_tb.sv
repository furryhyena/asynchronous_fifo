`timescale 1ns / 1ps

module terminal_explainer_tb;

    // -------------------------------------------------------------------------
    // 1. Parameters & Signals
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH = 32;
    localparam FIFO_DEPTH = 16;

    logic arst_n;
    logic wr_clk, rd_clk;
    logic wr_en, rd_en;
    logic [DATA_WIDTH-1:0] wr_data, rd_data;
    logic full, empty;

    integer WAVEFORM_PHASE = 0; 

    // -------------------------------------------------------------------------
    // 2. Instantiate the DUT
    // -------------------------------------------------------------------------
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .arst_n(arst_n),
        .wr_clk(wr_clk), .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    // -------------------------------------------------------------------------
    // 3. Clocks
    // -------------------------------------------------------------------------
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk; // 10ns period (Fast Write)
    end

    initial begin
        rd_clk = 0;
        forever #13 rd_clk = ~rd_clk; // 26ns period (Slow Read)
    end

    // -------------------------------------------------------------------------
    // 4. Custom Tasks for Clean Terminal Output
    // -------------------------------------------------------------------------
    task print_banner(input string phase_name);
        $display("\n============================================================");
        $display(" >>> %s", phase_name);
        $display("============================================================");
    endtask

    task write_word(input [31:0] data);
        @(posedge wr_clk); #1; 
        wr_en = 1;
        wr_data = data;
        $display("[%0t ns] [WRITE] Pushed 0x%08h | wbin: %2d | full: %b", 
                 $time, data, dut.wbin, dut.full);
        @(posedge wr_clk); #1; 
        wr_en = 0;
    endtask

    task read_word();
        @(posedge rd_clk); #1; 
        rd_en = 1;
        @(posedge rd_clk); #1; // Wait 1 cycle for data to appear
        rd_en = 0;
        $display("[%0t ns] [READ ] Pulled 0x%08h | rbin: %2d | empty: %b", 
                 $time, rd_data, dut.rbin, dut.empty);
    endtask

    // -------------------------------------------------------------------------
    // 5. Main Sequence
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("presentation_waveform.vcd");
        $dumpvars(0, terminal_explainer_tb);
        
        arst_n = 1; wr_en = 0; rd_en = 0; wr_data = 0;
        
        // =====================================================================
        WAVEFORM_PHASE = 1; 
        print_banner("PHASE 1: Hardware Reset");
        // =====================================================================
        $display("[%0t ns] Asserting Asynchronous Reset...", $time);
        #12 arst_n = 0; 
        #25 arst_n = 1; 
        $display("[%0t ns] Reset Released. Waiting for synchronizers...", $time);
        #60; 
        $display("[%0t ns] empty flag is currently: %b", $time, empty);

        // =====================================================================
        WAVEFORM_PHASE = 2; 
        print_banner("PHASE 2: Three Distinct Writes");
        // =====================================================================
        write_word(32'hAAAA_1111);
        write_word(32'hBBBB_2222);
        write_word(32'hCCCC_3333);

        // =====================================================================
        WAVEFORM_PHASE = 3; 
        print_banner("PHASE 3: Clock Domain Crossing (CDC) Wait Time");
        // =====================================================================
        $display("[%0t ns] Halting stimulus. Watch the 'empty' flag drop...", $time);
        // Wait long enough for wgray to pass through rq1 and rq2 in the read domain
        #150; 
        $display("[%0t ns] After CDC delay, empty flag is: %b", $time, empty);

        // =====================================================================
        WAVEFORM_PHASE = 4; 
        print_banner("PHASE 4: Reading the Three Words");
        // =====================================================================
        read_word();
        read_word();
        read_word();

        // =====================================================================
        WAVEFORM_PHASE = 5; 
        print_banner("PHASE 5: Burst Write to FULL");
        // =====================================================================
        $display("[%0t ns] Blasting data until FULL flag triggers...", $time);
        wr_data = 32'h0000_0001;
        while (!full) begin
            @(posedge wr_clk); #1; 
            wr_en = 1;
            wr_data = wr_data + 1;
        end
        @(posedge wr_clk); #1; wr_en = 0;
        $display("[%0t ns] Stopped writing. full flag is: %b | wbin: %2d", $time, full, dut.wbin);

        // =====================================================================
        WAVEFORM_PHASE = 6; 
        print_banner("PHASE 6: Drain to EMPTY");
        // =====================================================================
        $display("[%0t ns] Draining FIFO completely...", $time);
        while (!empty) begin
            @(posedge rd_clk); #1; 
            rd_en = 1;
        end
        @(posedge rd_clk); #1; rd_en = 0;
        $display("[%0t ns] Stopped reading. empty flag is: %b | rbin: %2d", $time, empty, dut.rbin);

        print_banner("SIMULATION COMPLETE");
        #50;
        $finish;
    end
endmodule
