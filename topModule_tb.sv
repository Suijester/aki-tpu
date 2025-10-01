`timescale 1ns / 1ps

module topModule_tb;

parameter dataSize = 16;
parameter matrixSize = 4;
parameter accSize = 32;


// TPU module inputs
logic clk;
logic reset;
logic start;

logic signed [dataSize - 1:0] topInputRow [matrixSize];
logic signed [dataSize - 1:0] leftInputColumn [matrixSize];
logic done;

logic writeEnable;
logic currentBuffer;

tpuModule # (
    .matrixSize(matrixSize),
    .dataSize(dataSize),
    .accSize(accSize)
) DUT (
    .clk(clk),
    .reset(reset),
    .start(start),

    .topInputRow(topInputRow),
    .leftInputColumn(leftInputColumn),

    .done(done),
    .writeEnable(writeEnable),
    .currentBuffer(currentBuffer)
);

// matrices we'll be passing
// first matrix set (A * B)
logic signed [dataSize - 1:0] matrixA [matrixSize][matrixSize] = '{
    '{1, 2, 3, 4},
    '{-1, -2, -3, -4},
    '{3, 4, 5, 6},
    '{-3, -4, -5, -6}
};

logic signed [dataSize - 1:0] matrixB [matrixSize][matrixSize] = '{
    '{7, 8, 9, 10},
    '{-7, -8, -9, -10},
    '{11, 12, 13, 14},
    '{-11, -12, -13, -14}
};

// second matrix set (C * D)
logic signed [dataSize - 1:0] matrixC [matrixSize][matrixSize] = '{
    '{3, 5, 7, 9},
    '{3, 5, 7, 9},
    '{3, 5, 7, 9},
    '{3, 5, 7, 9}
};

logic signed [dataSize - 1:0] matrixD [matrixSize][matrixSize] = '{
    '{1, 2, 3, 4},
    '{1, 2, 3, 4},
    '{1, 2, 3, 4},
    '{1, 2, 3, 4}
};

initial clk = 0;
always #5 clk = ~clk;

task feedMatrixRows(
    input logic signed [dataSize - 1:0] leftInputMatrix [matrixSize][matrixSize],
    input logic signed [dataSize - 1:0] topInputMatrix [matrixSize][matrixSize]
);
    int i, j;

    // Wait until writeEnable goes high
    wait(writeEnable);

    // Now provide all rows synchronously with clock
    for (i = 0; i < matrixSize; i++) begin
        @(posedge clk);
        topInputRow = topInputMatrix[i];
        for (j = 0; j < matrixSize; j = j + 1) begin
            leftInputColumn[j] = leftInputMatrix[j][i];
        end
    end
endtask

task displayOutputMatrix(
    input string matrixName
);
    int i, j;
    $display("\n========================================");
    $display("Output Matrix: %s", matrixName);
    $display("========================================");
    for (i = 0; i < matrixSize; i++) begin
        $write("Row %0d: ", i);
        for (j = 0; j < matrixSize; j++) begin
            $write("%10d ", DUT.systolicArray.outputArray[i][j]);
        end
        $display(""); // new line
    end
    $display("========================================\n");
endtask

initial begin
    reset = 0; // assert active-low reset
    start = 0;
    #20;
    reset = 1; // turn off the reset
    #20;
    start = 1; // begin the program
    
    $display("Feeding Matrices A, B");
    feedMatrixRows(matrixA, matrixB);
    $display("Feeding Matrices C, D");
    feedMatrixRows(matrixC, matrixD);
    
    // Wait for first computation to complete
    @(posedge done);
    @(posedge clk); // Wait one more cycle to ensure outputs are stable
    displayOutputMatrix("A * B");
    
    // Wait for second computation to complete
    @(posedge done);
    @(posedge clk); // Wait one more cycle to ensure outputs are stable
    displayOutputMatrix("C * D");
    
    #50; // Allow some time before finishing simulation
    $display("Simulation Complete");
    $finish;
end
endmodule