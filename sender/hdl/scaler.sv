// AXI-Stream Video Scaler (x1.5) 2020.08.30 Naoki F., AIT
// ライセンスについては LICENSE.txt を参照してください．

module scaler150 (
    input  logic         ACLK,
    input  logic         ARESETN,
    input  logic         MODE,
    input  logic [23: 0] S_TDATA,
    input  logic         S_TLAST,
    input  logic [ 0: 0] S_TUSER,
    input  logic         S_TVALID,
    output logic         S_TREADY,
    output logic [23: 0] M_TDATA,
    output logic         M_TLAST,
    output logic [ 0: 0] M_TUSER,
    output logic         M_TVALID,
    input  logic         M_TREADY);

    // note: WIDTH_SRC and HEIGHT_SRC must be even
    parameter WIDTH_SRC  = 800;
    parameter HEIGHT_SRC = 480;
    localparam WIDTH_BLK  = WIDTH_SRC / 2;
    localparam HEIGHT_BLK = HEIGHT_SRC / 2;
    localparam X_LEN = $clog2(WIDTH_SRC);
    localparam Y_LEN = $clog2(HEIGHT_SRC);
    localparam FIFO_LEN  = 2 ** $clog2(WIDTH_BLK * 3);

    logic [X_LEN-2:0] x_blk, n_x_blk;
    logic [Y_LEN-2:0] y_blk, n_y_blk;
    logic       [1:0] x_dst, y_dst, n_x_dst, n_y_dst;
    logic             top, bottom, left, right;
    logic             init, fini, n_init, n_fini;
    logic             proceed;
    logic             tready, n_tready;

    // Approx. (5:3) linear interpolation
    function [7:0] lin;
        input logic [7:0] p1, p2;
        input logic swap;
        logic [10:0] tmp;
        if (swap)
            tmp = p1 * 2'd3 + p2 * 3'd5;
        else
            tmp = p1 * 3'd5 + p2 * 2'd3;
        return tmp[10:3];
    endfunction

    function [23:0] lin_px;
        input logic [23:0] p1, p2;
        input logic swap;
        return {lin(p1[23:16], p2[23:16], swap),
                lin(p1[15: 8], p2[15: 8], swap),
                lin(p1[ 7: 0], p2[ 7: 0], swap)};
    endfunction

    // Pixel Data
    logic [23:0] pbuf1, pbuf2, n_pbuf1, n_pbuf2, pbuf_sel;
    logic        pen1,  pen2;

    // FIFOes
    logic [23:0] lf_in, lf_out;
    logic [25:0] of_in, of_out;
    logic        lf_we, lf_re;
    logic        of_we, of_re, of_empty, of_full;

    fifo #(.WIDTH(24), .SIZE(FIFO_LEN)) line_fifo (
        .CLK(ACLK),
        .RST(~ ARESETN),
        .DATA_W(lf_in),
        .DATA_R(lf_out),
        .WE(lf_we),
        .RE(lf_re),
        .EMPTY(),
        .FULL(),
        .SOFT_RST(1'b0));
    fifo #(.WIDTH(26), .SIZE(FIFO_LEN)) out_fifo (
        .CLK(ACLK),
        .RST(~ ARESETN),
        .DATA_W(of_in),
        .DATA_R(of_out),
        .WE(of_we),
        .RE(of_re),
        .EMPTY(of_empty),
        .FULL(of_full),
        .SOFT_RST(1'b0));

    // output stream
    assign M_TDATA    = (MODE) ? of_out[23:0] : S_TDATA;
    assign M_TLAST    = (MODE) ? of_out[24]   : S_TLAST;
    assign M_TUSER[0] = (MODE) ? of_out[25]   : S_TUSER[0];
    assign M_TVALID   = (MODE) ? ~ of_empty   : S_TVALID;
    assign of_re      = M_TVALID & M_TREADY;
    assign S_TREADY   = (MODE) ? tready       : M_TREADY;

    // combinatorial circuit (for computation)
    assign top      = (y_blk == 0);
    assign bottom   = (y_blk == HEIGHT_BLK - 1);
    assign left     = (x_blk == 0);
    assign right    = (x_blk == WIDTH_BLK - 1);
    assign n_pbuf1  = S_TDATA;
    assign n_pbuf2  = lin_px(pbuf1, S_TDATA, x_dst >= 2'd2);
    assign pbuf_sel = (x_dst == 2'd0) ? pbuf1 : pbuf2;

    always_comb begin
        proceed  = 1'b0;
        lf_in    = 24'h0;
        lf_we    = 1'b0;
        lf_re    = 1'b0;
        of_in    = 26'h0;
        of_we    = 1'b0;
        pen1     = 1'b0;
        pen2     = 1'b0;
        n_tready = S_TREADY;
        if (~ MODE) begin
            // nothing to do!
        end else if (S_TREADY) begin
            if (S_TVALID) begin
                n_tready = 1'b0;
                pen1     = (x_dst != 2'd1 || ~ right);
                pen2     = 1'b1;
            end
        end else begin
            if (init) begin
                proceed  = 1'b1;
                n_tready = (x_dst == 2'd0 || (x_dst == 2'd1 && ~ right));
                lf_in    = pbuf_sel;
                lf_we    = 1'b1;
            end else if (y_dst == 2'd0 || fini) begin
                of_in[23:0] = lf_out;
                of_in[24]   = (right && x_dst >= 2'd2);
                of_in[25]   = left & top;
                if (~ of_full) begin
                    proceed  = 1'b1;
                    n_tready = (right && x_dst >= 2'd2);
                    lf_in    = lf_out;
                    lf_we    = ~ fini;
                    lf_re    = 1'b1;
                    of_we    = 1'b1;
                end
            end else begin
                of_in[23:0] = lin_px(pbuf_sel, lf_out, y_dst >= 2'd2);
                of_in[24]   = (right && x_dst >= 2'd2);
                if (~ of_full) begin
                    proceed  = 1'b1;
                    n_tready = (x_dst == 2'd0) ? 1'b1 :
                               (x_dst == 2'd1) ? ~ right :
                               (y_dst == 2'd1 && right && ~ bottom);
                    lf_in    = pbuf_sel;
                    lf_we    = 1'b1;
                    lf_re    = 1'b1;
                    of_we    = 1'b1;
                end
            end
        end
    end

    // combinatorial circuit (for next position)
    always_comb begin
        n_x_blk = x_blk;
        n_y_blk = y_blk;
        n_x_dst = x_dst;
        n_y_dst = y_dst;
        n_init  = init;
        n_fini  = fini;
        if (proceed) begin
            n_x_dst = n_x_dst + 1'b1;
            if (n_x_dst == 2'd3) begin
                n_x_dst = 2'd0;
                n_x_blk = x_blk + 1'b1;
                if (x_blk == WIDTH_BLK - 1) begin
                    n_x_blk = 0; 
                    if (init) begin
                        n_init = 1'b0;
                    end else begin
                        n_y_dst = n_y_dst + 1'b1;
                        n_fini  = (n_y_dst == 2'd2 && bottom);
                    end
                end
            end
            if (n_y_dst == 2'd3) begin
                if (fini) begin
                    n_init  = 1'b1;
                    n_fini  = 1'b0;
                    n_y_dst = 2'd0;
                    n_y_blk = 0;
                end else begin
                    n_y_dst = 2'd0;
                    n_y_blk = y_blk + 1'b1;
                end
            end
        end
    end

    // update of registers
    always_ff @ (posedge ACLK) begin
        if (~ ARESETN) begin
            tready <= 1'b1;
            pbuf1  <= 24'h0;
            pbuf2  <= 24'h0;
            x_blk  <= 0;
            y_blk  <= 0;
            x_dst  <= 2'd0;
            y_dst  <= 2'd0;
            init   <= 1'b1;
            fini   <= 1'b0;
        end else begin
            tready <= n_tready;
            if (pen1) pbuf1  <= n_pbuf1;
            if (pen2) pbuf2  <= n_pbuf2;
            x_blk  <= n_x_blk;
            y_blk  <= n_y_blk;
            x_dst  <= n_x_dst;
            y_dst  <= n_y_dst;
            init   <= n_init;
            fini   <= n_fini;
        end
    end
endmodule