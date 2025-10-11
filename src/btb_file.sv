module btb_file(
    input  logic         clk,
    input  logic [2:0]   read_index,
    output logic [127:0] read_set,
    input  logic [2:0]   write_index,
    input  logic [127:0] write_set,
    input  logic         write_enable
);
    logic [127:0] btb_mem [7:0]; // 8 sets, 128 bits each

    // Read (combinational)
    assign read_set = (write_enable && read_index == write_index) ? write_set : btb_mem[read_index];

    // Write (sequential)
    always_ff @(posedge clk) begin
        if(write_enable)
            btb_mem[write_index] <= write_set;
    end
    
endmodule
