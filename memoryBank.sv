`timescale 1ns / 1ps

module memoryBank # (
    parameter matrixSize = 4,
    parameter dataSize = 16
)(
    input logic clk,

    input logic writeEnable, // if one input block is being written to, all of them are, although this is a simplification
    input logic signed [dataSize - 1:0] writeElementVector [matrixSize], // what element to write into any given inputBlock
    input logic [$clog2(matrixSize) - 1:0] writeLocationVector [matrixSize], // where to write the element inside of inputBlock

    input logic [$clog2(matrixSize) - 1:0] readLocationVector [matrixSize],
    output logic signed [dataSize - 1:0] outputElementVector [matrixSize]
);

generate
    genvar i;
    for (i = 0; i < matrixSize; i = i + 1) begin : blockMemory
        inputBlock # (
            .matrixSize(matrixSize),
            .dataSize(dataSize)
        ) inputColumn (
            .clk(clk),

            .writeEnable(writeEnable),
            .writeElement(writeElementVector[i]),
            .writeLocation(writeLocationVector[i]),

            .readLocation(readLocationVector[i]),
            .outputElement(outputElementVector[i])
        );
    end
endgenerate

endmodule