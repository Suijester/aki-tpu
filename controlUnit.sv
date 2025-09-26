`timescale 1ns / 1ps

module controlUnit # (
    matrixSize = 8,
    dataSize = 16,
    accSize = 32
) (
    input logic clk,
    input logic reset,
    input logic start,

    input logic [dataSize - 1:0] matrixA [matrixSize][matrixSize], // (0, 0) is top left of the matrix)
    input logic [dataSize - 1:0] matrixB [matrixSize][matrixSize],

    output logic writeEnable,
    output logic [dataSize - 1:0] writeElementVector [matrixSize],
    output logic [$clog2(matrixSize) - 1:0] writeLocationVector [matrixSize],
    output logic [$clog2(matrixSize) - 1:0] readLocationVector [matrixSize],
    output logic currentBuffer, // 0 if the first buffer, 1 if the second buffer

    output logic clearSignals [matrixSize][matrixSize],
    output logic enableSignals [matrixSize][matrixSize],
    output logic done
)

typedef enum logic [2:0] {
    idleState,
    writingState,
    computingStateA,
    computingStateB,
    completedState
} tpuStates;

tpuStates currentState;
tpuStates nextState;

// counts the number of writes we need to make
logic [$clog2(matrixSize) - 1:0] writeCounter;

// to determine how long computation must last, calculated via formula ((matrixSize) * 3) - 1
logic [$clog2((matrixSize * 3) - 1) - 1:0] cycleCounter; 


always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        currentState <= idleState;
        writeCounter <= 0;
        cycleCounter <= 0;
        currentBuffer <= 0;
    end else begin
        currentState <= nextState;
        case (currentState)
            idleState: begin
                if (start) begin
                    writeCounter <= 0;
                    cycleCounter <= 0;
                end
            end

            writingState: begin
                // if we've written to every row, we can reset the writeCounter for next use, otherwise we increment
                writeCounter <= (nextState == computingStateA) ? 0 : writeCounter + 1;
            end

            computingStateA: begin
                // reset cycle counter if we switch buffers; else, increment
                cycleCounter <= (nextState == computingStateB) ? 0 : cycleCounter + 1; 
            end

            computingStateB: begin
                // if we finish, empty cycle counter, otherwise increment
                cycleCounter <= (nextState == completedStated) ? 0 : cycleCounter + 1;
            end
        endcase
    end
end

always_comb begin
    nextState = currentState;
    writeEnable = 0;
    done = 0;
    writeElementVector = 

    case (currentState)
        idleState: nextState = (start) ? writingState : idleState;

        writingState: begin
            writeEnable = 1;
            writeLocationVector = matrixA[writeCounter];
            // if on the next clock cycle, we'll finish writing the vectors, then continue to the first computation state
            nextState = (writeCounter == matrixSize - 1) ? computingStateA : writingState;
        end

        computingStateA: begin
            localparam maxCycles = (matrixSize * 3) - 1; // the number of cycles required during computation for completion

            // writing to secondary buffer while doing computation
            writeEnable = 1;
            writeLocationVector = matrixB[writeCounter];

            // signals and read locations during computation

            // enable signal compute
            genvar i, j;
            for (i = 0; i < matrixSize; i = i + 1) begin
                for (j = 0; j < matrixSize; j = j + 1) begin
                    // if the location sums to cycleCounter or less, then activate
                    // but if the location coordinates have already been on for matrixSize cycles, then deactivate
                    if ((i + j <= cycleCounter) & (cycleCounter < (i + j + matrixSize))) begin
                        enableSignals[i][j] = 1;
                    end
                end
            end

            // read location compute

        end
    endcase
end

endmodule