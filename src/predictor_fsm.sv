module predictor_fsm(
    input  logic [1:0] currentState,
    input  logic       mispredicted,
    output logic [1:0] nextState
);

    always_comb begin
        case (currentState)
            2'b00: nextState = mispredicted ? 2'b01 : 2'b00; // strongNotTaken
            2'b01: nextState = mispredicted ? 2'b10 : 2'b00; // weakNotTaken
            2'b10: nextState = mispredicted ? 2'b11 : 2'b10; // strongTaken
            2'b11: nextState = mispredicted ? 2'b00 : 2'b10; // weakTaken
            default: nextState = 2'b00;
        endcase
    end

endmodule
