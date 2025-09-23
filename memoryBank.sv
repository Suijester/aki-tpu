module memoryBank # (
    parameter matrixSize = 4,
    parameter dataSize = 16
)(
    input logic clk,
    input logic reset,

    input logic [matrixSize - 1:0] writeInputVector,
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
            .reset(reset),

            .writeInput(writeInputVector[i]),
            .writeElement(writeElementVector[i]),
            .writeLocation(writeLocationVector[i]),

            .readLocation(readLocationVector[i]),
            .outputElement(outputElementVector[i])
        )
    end
endgenerate


endmodule