module btb(
    input  logic        clk,
    input  logic [31:0] PC,
    input  logic        update,
    input  logic [31:0] updatePC,
    input  logic [31:0] updateTarget,
    input  logic        mispredicted,
    output logic        valid,
    output logic [31:0] target,
    output logic        predictedTaken
);

    // ----------- IF Stage -------------

    // PC (32 bits) = Tag (27 bits) + Index (3 bits) + Byte offset (2 bits)
    logic [2:0]  index = PC[4:2];
    logic [26:0] tag   = PC[31:5];

    // BTB memory
    logic [127:0] read_set;

    logic [127:0] update_set;
    logic [2:0]   update_index = updatePC[4:2];
    logic [26:0]  update_tag   = updatePC[31:5];

    logic [127:0] write_set;
    logic [2:0]   write_index = updatePC[4:2];

    btb_file u_btb_file(
        .clk(clk),
        .read_index(index),
        .read_set(read_set),
        .write_index(write_index),
        .write_set(write_set),
        .write_enable(update),
        .update_index(update_index),   
        .update_set(update_set)
    );

    // Read branch entries and compare tags using btb_read_logic
    logic [1:0] current_fsm;
    logic       check_branch1, check_branch2; 

    btb_read_logic u_read(
        .set_data(read_set),  
        .pc_tag(tag),         
        .hit1(check_branch1),  
        .hit2(check_branch2),          
        .target(target),      
        .fsm_state(current_fsm) 
    );

    assign valid          = check_branch1 || check_branch2;
    assign predictedTaken = current_fsm[1];


    // ----------- EX Stage ------------

    // Use btb_read_logic to read the set for update
    logic [31:0] update_target;
    logic [1:0]  update_fsm;
    logic        update_branch1, update_branch2;

    btb_read_logic u_update_read(
        .set_data(update_set),
        .pc_tag(update_tag),   
        .hit1(update_branch1), 
        .hit2(update_branch2),      
        .target(update_target),
        .fsm_state(update_fsm) 
    );

    logic new_entry = ~(update_branch1 || update_branch2); // if no hit, this is a new entry
    logic lru_read, lru_write;
   
    // LRU tracking
    lru u_lru(
        .clk(clk),
        .read_index(index),
        .branch1_used(check_branch1),
        .branch2_used(check_branch2),
        .update_index(update_index),
        .new_entry(new_entry),
        .lru_read_bit(lru_read),
        .lru_write_bit(lru_write)
    );

   
endmodule
