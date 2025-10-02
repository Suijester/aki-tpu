`timescale 1ns / 1ps

module inputBlock # (
    parameter matrixSize = 4,
    parameter dataSize = 16
) (
    input logic clk,

    input logic writeEnable,
    input logic [dataSize - 1:0] writeElement,
    input logic [$clog2(matrixSize) - 1:0] writeLocation,

    input logic [$clog2(matrixSize) - 1:0] readLocation,
    output logic [dataSize - 1:0] outputElement
);
// create input array
logic [dataSize - 1:0] inputArray [matrixSize];

// read is synchronous to minimize critical path (must wait till next cycle, but higher throughput)
always_ff @(posedge clk) begin
    outputElement <= inputArray[readLocation];
    if (writeEnable) begin
        inputArray[writeLocation] <= writeElement;
    end
end

endmodule