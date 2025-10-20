module btb(
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] PC,
    input  logic        update,
    input  logic [31:0] updatePC,
    input  logic [31:0] updateTarget,
    input  logic        mispredicted,
    output logic        valid,
    output logic [31:0] target,
    output logic        predictedTaken
);

    // ----------- Internal Signals -------------

    // PC (32 bits) = Tag (27 bits) + Index (3 bits) + Byte offset (2 bits)
    logic [2:0]  index;
    logic [26:0] tag;   

    logic [127:0] read_set;
    logic [127:0] update_set;
    logic [2:0]   update_index;
    logic [26:0]  update_tag;
    logic [127:0] write_set;
    logic [2:0]   write_index;

    logic check_branch1, check_branch2;
    logic update_branch1, update_branch2;
    logic lru_read, lru_write;

    
    // ----------- IF Stage -------------
    
    // BTB memory
    assign index        = PC[4:2];
    assign tag          = PC[31:5];
    assign update_index = updatePC[4:2];
    assign update_tag   = updatePC[31:5];
    assign write_index  = updatePC[4:2];

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

    // Use btb_read_logic to read the set
    btb_read_logic u_read(
        .set_data(read_set),  
        .pc_tag(tag),         
        .hit1(check_branch1),  
        .hit2(check_branch2),          
        .target(target),      
        .valid(valid),
        .predictedTaken(predictedTaken)  
    );


    // ----------- EX Stage ------------

    // Use btb_read_logic to read the set for update
    btb_read_logic u_update_read(
        .set_data(update_set),
        .pc_tag(update_tag),   
        .hit1(update_branch1), 
        .hit2(update_branch2),      
        .target(),
        .valid(),
        .predictedTaken() 
    );

    // LRU tracking
    lru u_lru(
        .clk(clk),
        .rst(rst),
        .read_index(index),
        .branch1_used(check_branch1),
        .branch2_used(check_branch2),
        .update(update),
        .update_index(update_index),
        .update_branch1(update_branch1),
        .update_branch2(update_branch2),
        .lru_read_bit(lru_read),
        .lru_write_bit(lru_write)
    );

    // Build write set
    btb_write_logic u_write_logic (
        .old_set(update_set),
        .new_tag(update_tag),
        .new_target(updateTarget),
        .mispredicted(mispredicted),
        .update(update),
        .update_branch1(update_branch1),
        .update_branch2(update_branch2),
        .lru_write(lru_write),
        .write_set(write_set)
    );

endmodule
