`timescale 1ns / 1ps

module controlUnit # (
    parameter matrixSize = 8,
    parameter dataSize = 16,
    parameter accSize = 32
) (
    input logic clk,
    input logic reset,
    input logic start,

    output logic writeEnable,
    output logic [$clog2(matrixSize) - 1:0] writeLocationVector [matrixSize],
    output logic [$clog2(matrixSize) - 1:0] readLocationVector [matrixSize],
    output logic currentBuffer, // 0 if the first buffer is being read, 1 if the second buffer is being read
    output logic currentWrittenBuffer, // 0 is the first buffer is being written, 1 if the second buffer is being written

    output logic clearSignals [matrixSize][matrixSize],
    output logic enableSignals [matrixSize][matrixSize],
    output logic done
);

typedef enum logic [1:0] {
    idleState,
    writingState,
    computingState
} tpuStates;

tpuStates currentState;
tpuStates nextState;

// if in the writing state, then the currentBuffer is also the written buffer
// if in the computing state, then the writtenBuffer is the other buffer
assign currentWrittenBuffer = (currentState == writingState) ? currentBuffer : ~currentBuffer;

// the number of cycles required during computation for completion, calculated via formula ((matrixSize) * 3) - 1
localparam maxCycles = (matrixSize * 3); 

// counts the number of writes we need to make
logic [$clog2(matrixSize + 1) - 1:0] writeCounter;

// to determine how long computation must last
logic [$clog2(maxCycles + 1) - 1:0] cycleCounter; 

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
                    currentBuffer <= 0;
                end
            end

            writingState: begin
                writeCounter <= (nextState == computingState) ? 0 : writeCounter + 1;
            end

            computingState: begin
                if (done) begin
                    currentBuffer <= ~currentBuffer;
                    cycleCounter <= 0;
                    writeCounter <= 0;
                end else begin
                    cycleCounter <= cycleCounter + 1;
                    writeCounter <= (writeCounter < matrixSize) ? writeCounter + 1 : writeCounter;
                end
            end
        endcase
    end
end

always_comb begin
    nextState = currentState;
    writeEnable = 0;
    writeLocationVector = '{default: '0};
    readLocationVector = '{default: '0};
    done = 0;
    clearSignals = '{default: '0};
    enableSignals = '{default: '0};

    case (currentState)
        idleState: nextState = (start) ? writingState : idleState;

        writingState: begin
            writeEnable = 1;

            // write to the writeCounter location in each input block
            for (int i = 0; i < matrixSize; i = i + 1) begin
                writeLocationVector[i] = writeCounter;
            end

            // if on the next clock cycle, we'll finish writing the vectors, then continue to the first computation state
            if (writeCounter == matrixSize - 1) begin
                clearSignals = '{default: 1'b1}; // empty the MACs
                nextState = computingState;
            end
        end

        computingState: begin
            // writing to secondary buffer while doing computation
            if (writeCounter < matrixSize) begin
                writeEnable = 1;
                for (int k = 0; k < matrixSize; k = k + 1) begin
                    writeLocationVector[k] = writeCounter;
                end
            end

            // signals and read locations during computation
            // enable signal compute
            for (int i = 0; i < matrixSize; i = i + 1) begin
                for (int j = 0; j < matrixSize; j = j + 1) begin
                    // if the location sums to cycleCounter or less, then activate
                    // but if the location coordinates have already been on for matrixSize cycles, then deactivate
                    if ((i + j <= cycleCounter) && (cycleCounter < (i + j + matrixSize))) begin
                        enableSignals[i][j] = 1;
                    end
                end
            end

            // read location compute, read one cycle ahead since read is registered - need to wait an extra cycle
            for (int k = 0; k < matrixSize; k = k + 1) begin
                if ((cycleCounter + 1 >= k) && (cycleCounter + 1 < matrixSize + k)) begin
                    readLocationVector[k] = cycleCounter + 1 - k;
                end else begin
                    readLocationVector[k] = 0;
                end
            end

            // check for completion of computation
            // maxCycles + 1 because of registered outputs
            if (cycleCounter == maxCycles) begin
                done = 1;
                clearSignals = '{default: 1'b1};
            end
        end
    endcase
end

endmodule