`timescale 1ns / 1ps

module macUnit #(
    parameter dataSize = 16,
    parameter accSize = 32
) (
    input logic clk,
    input logic reset,

    input logic enable,
    input logic clear,

    input logic signed [dataSize - 1:0] topInput,
    input logic signed [dataSize - 1:0] leftInput,

    output logic signed [dataSize - 1:0] topOutput,
    output logic signed [dataSize - 1:0] leftOutput,
    output logic signed [accSize - 1:0] accOutput
);

// pipelined mac design, where we do register inputs, registeredInputs -> multiplier, multiplyReg -> adder -> output
logic signed [accSize - 1:0] accReg;
logic signed [(dataSize * 2) - 1:0] multiplyReg;
logic enableReg;
logic enableReg2;
logic signed [dataSize - 1:0] topInputReg;
logic signed [dataSize - 1:0] leftInputReg;

assign accOutput = accReg;

always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        multiplyReg <= 0;
        accReg <= 0;
        enableReg <= 0;
    end else begin
        topOutput <= topInput;
        leftOutput <= leftInput;
        
        topInputReg <= topInput;
        leftInputReg <= leftInput;
        enableReg <= enable;

        // multiplier stage (input -> multiplier)
        multiplyReg <= topInputReg * leftInputReg;
        enableReg2 <= clear ? 0 : enableReg;

        // adder & output stage (adder -> combinational register)
        if (clear) begin
            accReg <= 0;
        end else if (enableReg2) begin
            accReg <= accReg + multiplyReg;
        end
    end
end

endmodule