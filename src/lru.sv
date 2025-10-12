module lru (
    input  logic        clk,
    input  logic        rst,
    input  logic [2:0]  read_index,       
    input  logic        branch1_used,     
    input  logic        branch2_used,     
    input  logic [2:0]  update_index,     
    input  logic        update_branch1,
    input  logic        update_branch2,     
    output logic        lru_read_bit,     
    output logic        lru_write_bit     
);

    // LRU table — 8 sets, each 1 bit (since 2-way BTB)
    logic [7:0] lru_reg;

    // ----------- Initialization (simulation) -------------
    // Sets all entries to branch1 recently used by default
    initial begin
        lru_reg = 8'b0;
    end


    // ----------- IF Stage -------------

    // Read current LRU bit for this set
    assign lru_read_bit = lru_reg[read_index];

    // Compute new LRU bit after IF stage (if branch used)
    // 0 → branch1 used recently
    // 1 → branch2 used recently
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            lru_reg <= 8'b0;  
        else if (branch1_used)
            lru_reg[read_index] <= 1'b0;
        else if (branch2_used)
            lru_reg[read_index] <= 1'b1;
    end


    // ----------- EX Stage -------------
    
    // Determine what to write into LRU when a new entry is inserted/replaced
    assign lru_write_bit = lru_reg[update_index];

    logic new_entry;
    logic insert_branch1, insert_branch2;

    assign new_entry = ~(update_branch1 || update_branch2); // if no hit, this is a new entry

    assign insert_branch1 = new_entry ? lru_write_bit : 1'b0;
    assign insert_branch2 = new_entry ? lru_write_bit : 1'b1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            lru_reg <= 8'b0;  
        else if (new_entry) begin
            // If a new entry inserted in branch1 → mark branch1 as recently used (0)
            // If in branch2 → mark branch2 as recently used (1)
            if (insert_branch1)
                lru_reg[update_index] <= 1'b0;
            else if (insert_branch2)
                lru_reg[update_index] <= 1'b1;
        end
    end

endmodule
