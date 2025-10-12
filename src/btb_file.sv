module btb_file(
    input  logic         clk,
    input  logic [2:0]   read_index,
    input  logic [2:0]   write_index,
    input  logic [127:0] write_set,
    input  logic         write_enable,
    input  logic [2:0]   update_index,
    output logic [127:0] read_set,
    output logic [127:0] update_set
);

    logic [127:0] btb_mem [7:0]; // 8 sets, 128 bits each

    // ----------- Initialization (simulation) -------------
    // All sets cleared to 0 on simulation start
    initial begin
        integer i;
        for (i = 0; i < 8; i = i + 1)
            btb_mem[i] = 128'b0;
    end

    // Read (combinational)
    assign read_set = (write_enable && read_index == write_index) ? write_set : btb_mem[read_index];

    // Write (sequential)
    always_ff @(posedge clk) begin
        if(write_enable)
            btb_mem[write_index] <= write_set;
    end

    // Update (combinational)
    assign update_set = btb_mem[update_index];

endmodule
