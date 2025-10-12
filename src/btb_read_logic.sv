module btb_read_logic(
    input  logic [127:0] set_data,   
    input  logic [26:0]  pc_tag,     
    output logic         hit1,
    output logic         hit2,          
    output logic [31:0]  target,     
    output logic         valid,
    output logic         predictedTaken   
);

    // Split set into two branches
    logic        valid1, valid2;
    logic [26:0] tag1, tag2;
    logic [31:0] target1, target2;
    logic [1:0]  fsm1, fsm2;

    // Branch 1
    assign valid1  = set_data[127];
    assign tag1    = set_data[126:100];
    assign target1 = set_data[99:68];
    assign fsm1    = set_data[67:66];

    // Branch 2
    assign valid2  = set_data[63];
    assign tag2    = set_data[62:36];
    assign target2 = set_data[35:4];
    assign fsm2    = set_data[3:2];

    // Compare tags to determine hit
    assign hit1 = valid1 && (pc_tag == tag1);
    assign hit2 = valid2 && (pc_tag == tag2);

    assign target    = hit1 ? target1 : target2;
    assign fsm_state = hit1 ? fsm1 : (hit2 ? fsm2 : 2'b00);

    assign valid          = hit1 || hit2;
    assign predictedTaken = fsm_state[1];

endmodule
