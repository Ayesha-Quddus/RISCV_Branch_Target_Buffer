module lru (
    input  logic        clk,
    input  logic [2:0]  read_index,       
    input  logic        branch1_used,     
    input  logic        branch2_used,     
    input  logic [2:0]  update_index,     
    input  logic        new_entry,        
    output logic        lru_read_bit,     
    output logic        lru_write_bit     
);

    // LRU table — 8 sets, each 1 bit (since 2-way BTB)
    logic [7:0] lru_reg;


    // ----------- IF Stage -------------

    // Read current LRU bit for this set
    assign lru_read_bit = lru_reg[read_index];

    // Compute new LRU bit after IF stage (if branch used)
    // 0 → branch1 used recently
    // 1 → branch2 used recently
    always_ff @(posedge clk) begin
        if (branch1_used)
            lru_reg[read_index] <= 1'b0;
        else if (branch2_used)
            lru_reg[read_index] <= 1'b1;
    end


endmodule
