`timescale 1ns / 1ps

module inputBlock # (
    parameter matrixSize = 4,
    parameter dataSize = 16
) (
    input logic clk,

    input logic writeInput,
    input logic [dataSize - 1:0] writeElement,
    input logic [$clog2(matrixSize) - 1:0] writeLocation,

    input logic [$clog2(matrixSize) - 1:0] readElement,
    output logic [dataSize - 1:0] outputElement
);
// create input array, and enable combinational read port
logic [dataSize - 1:0] inputArray [matrixSize];
assign outputElement = inputArray[readElement];

always_ff @(posedge clk) begin
    if (writeInput) begin
        inputArray[writeLocation] <= writeElement;
    end
end

endmodule