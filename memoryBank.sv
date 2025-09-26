`timescale 1ns / 1ps

module memoryBank # (
    parameter matrixSize = 4,
    parameter dataSize = 16
)(
    input logic clk,

    input logic writeInput, // if one input block is being written to, all of them are, although this is a simplification
    input logic [dataSize - 1:0] writeElementVector [matrixSize],
    input logic [$clog2(matrixSize) - 1:0] writeLocationVector [matrixSize],

    input logic [$clog2(matrixSize) - 1:0] readLocationVector [matrixSize],
    output logic [dataSize - 1:0] outputElementVector [matrixSize]
)

generate
    genvar i;
    for (i = 0; i < matrixSize; i = i + 1) begin : blockMemory
        inputBlock inputColumn # (
            .matrixSize(matrixSize),
            .dataSize(dataSize)
        ) (
            .clk(clk),

            .writeInput(writeInput),
            .writeElement(writeElementVector[i]),
            .writeLocation(writeLocationVector[i]),

            .readLocation(readLocationVector[i]),
            .outputElement(outputElementVector[i])
        )
    end
endgenerate

endmodule