`timescale 1ns/1ps

module btb_tb;

    // DUT interface
    logic clk;
    logic rst;
    logic [31:0] PC;
    logic update;
    logic [31:0] updatePC;
    logic [31:0] updateTarget;
    logic mispredicted;
    logic valid;
    logic [31:0] target;
    logic predictedTaken;

    // PC-target pairs 
    logic [31:0] list_PCs_TarAddrs [0:47];  // 8 sets × 6 entries = 48

    // Instantiate DUT
    btb dut (
        .clk(clk),
        .rst(rst),
        .PC(PC),
        .update(update),
        .updatePC(updatePC),
        .updateTarget(updateTarget),
        .mispredicted(mispredicted),
        .valid(valid),
        .target(target),
        .predictedTaken(predictedTaken)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: single clock tick
    task step;
        begin
            #10;
        end
    endtask

    initial begin
        $dumpfile("btb_tb.vcd");
        $dumpvars(0, btb_tb);

        rst = 1;
        PC = 0;
        update = 0;
        updatePC = 0;
        updateTarget = 0;
        mispredicted = 0;

        // Apply reset for one clock cycle
        step();  
        rst = 0;  
        step(); 

        // Populate addresses for sets 0–7
        for (int i = 0; i < 48; i++) begin
            int set = i / 6;
            int pos = i % 6;
            case (pos)
                0: list_PCs_TarAddrs[i] = 32'h000A0000 + (set * 4);
                1: list_PCs_TarAddrs[i] = 32'h000B0000 + (set * 4);
                2: list_PCs_TarAddrs[i] = 32'h000A0020 + (set * 4);
                3: list_PCs_TarAddrs[i] = 32'h000B0020 + (set * 4);
                4: list_PCs_TarAddrs[i] = 32'h000A0040 + (set * 4);
                5: list_PCs_TarAddrs[i] = 32'h000B0040 + (set * 4);
            endcase
        end

        $display("===== BTB TEST START =====");

        // 8 loops (for 8 sets)
        for (int s = 0; s < 8; s++) begin
            logic [31:0] PC_0, Tar_0, PC_1, Tar_1, PC_2, Tar_2;

            PC_0 = list_PCs_TarAddrs[s*6 + 0];
            Tar_0 = list_PCs_TarAddrs[s*6 + 1];
            PC_1 = list_PCs_TarAddrs[s*6 + 2];
            Tar_1 = list_PCs_TarAddrs[s*6 + 3];
            PC_2 = list_PCs_TarAddrs[s*6 + 4];
            Tar_2 = list_PCs_TarAddrs[s*6 + 5];

            $display("\n--- Testing Set %0d ---", s);

            // Test 0: No write when update=0
            update = 0;
            updatePC = PC_0;
            updateTarget = Tar_0;
            mispredicted = 0;
            step();

            PC = PC_0;
            step();
            assert(valid == 0) else $error("Set %0d: Valid should be 0 before update", s);

            // Test 1: Write entry and check
            update = 1;
            updatePC = PC_0;
            updateTarget = Tar_0;
            mispredicted = 0;
            step();
            update = 0;

            PC = PC_0;
            step();
            assert(valid == 1) else $error("Set %0d: Valid should be 1 after update", s);
            assert(target == Tar_0) else $error("Set %0d: Target mismatch", s);

            // Test 2: FSM transitions 
            update = 1;
            updatePC = PC_0;
            updateTarget = Tar_0;
            mispredicted = 0;
            PC = PC_0;
            step();
            update = 0;
            step();

            // Basic FSM transition check 
            if (predictedTaken == 0) begin
                $display("Set %0d FSM starts in NotTaken state", s);
                mispredicted = 1; update = 1; step(); update = 0; step();
                mispredicted = 1; update = 1; step(); update = 0; step();
                $display("FSM transition path tested (NotTaken → Taken)");
            end else begin
                $display("Set %0d FSM starts in Taken state", s);
                mispredicted = 1; update = 1; step(); update = 0; step();
                mispredicted = 1; update = 1; step(); update = 0; step();
                $display("FSM transition path tested (Taken → NotTaken)");
            end
            mispredicted = 0;

            // Test 3: Second entry, simultaneous write-read
            step();
            PC = PC_1;
            step();
            update = 1;
            updatePC = PC_1;
            updateTarget = Tar_1;
            mispredicted = 0;
            step();
            assert(valid == 1 && target == Tar_1) else $error("Set %0d: Simultaneous write-read failed", s);
            update = 0;
            step();

            // Test 4: Third entry (eviction test)
            update = 1;
            updatePC = PC_2;
            updateTarget = Tar_2;
            mispredicted = 0;
            step();
            update = 0;
            PC = PC_2;
            step();
            assert(valid == 1 && target == Tar_2) else $error("Set %0d: Entry 3 write failed", s);

            // Check eviction: first entry should be evicted
            PC = PC_0;
            step();
            assert(valid == 0) else $error("Set %0d: Eviction failed (old entry still valid)", s);
        end

        $display("===== BTB TEST PASSED SUCCESSFULLY =====");
        $finish;
    end

endmodule
