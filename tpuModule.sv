`timescale 1ns / 1ps

module tpuModule # (
    parameter matrixSize = 8,
    parameter dataSize = 16,
    parameter accSize = 32
) (
    input logic clk,
    input logic reset,
    input logic start,

    input logic signed [dataSize - 1:0] topInputRow [matrixSize],
    input logic signed [dataSize - 1:0] leftInputColumn [matrixSize],

    output logic done,

    // testbench/handshaking signals (so we can pass rows)
    output logic writeEnable,
    output logic currentBuffer // 0 if the first buffer, 1 if the second buffer
);

logic [$clog2(matrixSize) - 1:0] writeLocationVector [matrixSize];
logic [$clog2(matrixSize) - 1:0] readLocationVector [matrixSize];
logic currentWrittenBuffer; // 0 is the first buffer is being written, 1 if the second buffer is being written

logic clearSignals [matrixSize][matrixSize];
logic enableSignals [matrixSize][matrixSize];

controlUnit # (
    .matrixSize(matrixSize),
    .dataSize(dataSize),
    .accSize(accSize)
) controlUnit (
    .clk(clk),
    .reset(reset),
    .start(start),

    .writeEnable(writeEnable),
    .writeLocationVector(writeLocationVector),
    .readLocationVector(readLocationVector),
    .currentBuffer(currentBuffer),
    .currentWrittenBuffer(currentWrittenBuffer),

    .clearSignals(clearSignals),
    .enableSignals(enableSignals),
    .done(done)
);

logic signed [dataSize - 1:0] topInputs [matrixSize];
logic signed [dataSize - 1:0] leftInputs [matrixSize];

logic signed [accSize - 1:0] outputArray [matrixSize][matrixSize]; // output matrix

// outputs of top and left memory banks, sourced from buffers A and B
logic signed [dataSize - 1:0] topInputsA [matrixSize]; 
logic signed [dataSize - 1:0] topInputsB [matrixSize];

logic signed [dataSize - 1:0] leftInputsA [matrixSize]; 
logic signed [dataSize - 1:0] leftInputsB [matrixSize];

// decide which inputs to use dependent on which buffer is currently being used
assign topInputs = (currentBuffer) ? topInputsB : topInputsA;
assign leftInputs = (currentBuffer) ? leftInputsB : leftInputsA;

systolicArray # (
    .matrixSize(matrixSize),
    .dataSize(dataSize),
    .accSize(accSize)
) systolicArray (
    .clk(clk),
    .reset(reset),

    .topInputs(topInputs),
    .leftInputs(leftInputs),

    .clearSignals(clearSignals),
    .enableSignals(enableSignals),

    .outputArray(outputArray)
);

// buffer A's top and left memory banks
memoryBank # (
    .matrixSize(matrixSize),
    .dataSize(dataSize)
) topBankA (
    .clk(clk),
    
    .writeEnable(writeEnable && ~currentWrittenBuffer),
    .writeElementVector(topInputRow), // passed data
    .writeLocationVector(writeLocationVector),

    .readLocationVector(readLocationVector),
    .outputElementVector(topInputsA)
);

memoryBank # (
    .matrixSize(matrixSize),
    .dataSize(dataSize)
) leftBankA (
    .clk(clk),
    
    .writeEnable(writeEnable && ~currentWrittenBuffer),
    .writeElementVector(leftInputColumn), // passed data
    .writeLocationVector(writeLocationVector),

    .readLocationVector(readLocationVector),
    .outputElementVector(leftInputsA)
);


// buffer B's top and left memory banks
memoryBank # (
    .matrixSize(matrixSize),
    .dataSize(dataSize)
) topBankB (
    .clk(clk),
    
    .writeEnable(writeEnable && currentWrittenBuffer),
    .writeElementVector(topInputRow), // passed data
    .writeLocationVector(writeLocationVector),

    .readLocationVector(readLocationVector),
    .outputElementVector(topInputsB)
);

memoryBank # (
    .matrixSize(matrixSize),
    .dataSize(dataSize)
) leftBankB (
    .clk(clk),
    
    .writeEnable(writeEnable && currentWrittenBuffer),
    .writeElementVector(leftInputColumn), // passed data
    .writeLocationVector(writeLocationVector),

    .readLocationVector(readLocationVector),
    .outputElementVector(leftInputsB)
);


endmodule