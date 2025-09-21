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


);

endmodule