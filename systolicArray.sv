`timescale 1ns / 1ps

module systolicArray # (
    parameter matrixSize = 8,
    parameter dataSize = 16,
    parameter accSize = 32
) (
    input logic clk,
    input logic reset,

    input logic signed [dataSize - 1:0] topInputs [matrixSize],
    input logic signed [dataSize - 1:0] leftInputs [matrixSize],

    input logic clearSignals [matrixSize][matrixSize],
    input logic enableSignals [matrixSize][matrixSize],

    output logic signed [accSize - 1:0] outputArray [matrixSize][matrixSize] // output matrix
);

// wiring mesh to pass top and left down
logic signed [dataSize - 1:0] topWires [matrixSize + 1][matrixSize];
logic signed [dataSize - 1:0] leftWires [matrixSize + 1][matrixSize]; // j and i are transposed to simplify assignment

assign topWires[0] = topInputs;
assign leftWires[0] = leftInputs;

generate
    genvar i, j;
    for (i = 0; i < matrixSize; i++) begin : rowUnits
        for (j = 0; j < matrixSize; j++) begin : columnUnits
            macUnit # (
                .dataSize(dataSize),
                .accSize(accSize)
            ) macUnits (
                .clk(clk),
                .reset(reset),
                .enable(enableSignals[i][j]),
                .clear(clearSignals[i][j]),

                .topInput(topWires[i][j]),
                .leftInput(leftWires[j][i]), // left wires are flipped j, i to represent vertical coordinates for them

                .topOutput(topWires[i+1][j]),
                .leftOutput(leftWires[j+1][i]),

                .accOutput(outputArray[i][j])
            );
        end
    end
endgenerate

endmodule