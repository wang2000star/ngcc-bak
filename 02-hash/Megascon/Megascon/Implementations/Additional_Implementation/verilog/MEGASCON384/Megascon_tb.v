`timescale 1ns / 1ps

module tb_hash_top;

    reg          clk;
    reg          rst_n;
    reg          start;

    reg          block_valid;
    reg [1279:0] block_in;
    reg          block_last;

    wire [383:0] digest;
    wire         done;
    wire         busy;
    wire         ready;

    integer i;

    hash_top uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),

        .block_valid (block_valid),
        .block_in    (block_in),
        .block_last  (block_last),

        .digest      (digest),
        .done        (done),
        .busy        (busy),
        .ready       (ready)
    );

    task print_rows_64;
        input [2047:0] s;
        integer row;
        integer word;
        begin
            for (row = 0; row < 8; row = row + 1) begin
                $write("x[%0d] = ", row);
                for (word = 0; word < 4; word = word + 1) begin
                    $write("%016h ", s[row*256 + word*64 +: 64]);
                end
                $write("\n");
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n       = 1'b0;
        start       = 1'b0;
        block_valid = 1'b0;
        block_last  = 1'b0;

        /*
            Empty-message padded block.

            If the C reference has:
                padded_input[0] = 8'h80;
                padded_input[1..159] = 0;

            and the Verilog mapping is:
                state_reg[8*j +: 8] <=> state[j],

            then this is correct:
                block_in[7:0] = 8'h80;
                all other bits are zero.
        */
        block_in = 1280'h80;

        $display("====================================");
        $display("TB started");
        $display("time = %0t", $time);
        $display("====================================");

        #30;
        rst_n = 1'b1;

        $display("====================================");
        $display("Reset released");
        $display("time = %0t", $time);
        $display("====================================");

        @(negedge clk);
        start = 1'b1;

        $display("====================================");
        $display("start asserted");
        $display("time = %0t", $time);
        $display("block_in = 0x%0320h", block_in);
        $display("====================================");

        @(negedge clk);
        start = 1'b0;

        $display("====================================");
        $display("start deasserted");
        $display("time = %0t", $time);
        $display("====================================");

        wait (ready == 1'b1);

        $display("====================================");
        $display("ready is high");
        $display("time = %0t", $time);
        $display("====================================");

        @(negedge clk);
        block_valid = 1'b1;
        block_last  = 1'b1;

        $display("====================================");
        $display("block_valid asserted");
        $display("time = %0t", $time);
        $display("block_last = %0d", block_last);
        $display("block_in = 0x%0320h", block_in);
        $display("====================================");

        @(negedge clk);
        block_valid = 1'b0;
        block_last  = 1'b0;

        $display("====================================");
        $display("block_valid deasserted");
        $display("time = %0t", $time);
        $display("====================================");

        wait (done == 1'b1);

        $display("====================================");
        $display("done is high");
        $display("time = %0t", $time);
        $display("====================================");

        #20;
        $finish;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            $display("time=%0t ctrl=%0d ready=%0d busy=%0d done=%0d round_id=%0d block_valid=%0d block_last=%0d",
                     $time,
                     uut.state_ctrl,
                     ready,
                     busy,
                     done,
                     uut.round_id,
                     block_valid,
                     block_last);
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin

            if (block_valid && ready) begin
                $display("====================================");
                $display("Absorb block");
                $display("time = %0t", $time);
                $display("block_last = %0d", block_last);
                $display("block_in = 0x%0320h", block_in);

                $display("State before absorb:");
                print_rows_64(uut.state_reg);

                $display("State after absorb:");
                print_rows_64({
                    uut.state_reg[2047:1280],
                    uut.state_reg[1279:0] ^ block_in
                });

                $display("====================================");
            end

            if (uut.state_ctrl == uut.S_PERMUTE) begin
                $display("------------------------------------");
                $display("Round %0d", uut.round_id);
                $display("time = %0t", $time);

                $display("state_in:");
                print_rows_64(uut.state_reg);

                $display("state_out:");
                print_rows_64(uut.state_next);

                $display("------------------------------------");
            end

            if (done) begin
                $display("====================================");
                $display("Hash done");
                $display("time = %0t", $time);

                $display("digest = 0x%096h", digest);

                $display("digest byte order:");
                for (i = 0; i < 48; i = i + 1) begin
                    $write("%02x ", digest[8*i +: 8]);

                    if ((i % 16) == 15) begin
                        $write("\n");
                    end
                end

                $display("====================================");
            end
        end
    end

endmodule