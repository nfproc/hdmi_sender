// AXI-Stream Video Test Pattern Sender 2020.08.30 Naoki F., AIT
// ライセンスについては LICENSE.txt を参照してください．

module AXIS_send (
    input                AXIS_VID_ACLK,
    input                AXIS_VID_ARESETN,
    output logic [23: 0] AXIS_VID_TDATA,
    output logic         AXIS_VID_TLAST,
    output logic [ 0: 0] AXIS_VID_TUSER,
    output logic         AXIS_VID_TVALID,
    input  logic         AXIS_VID_TREADY,
    input  logic         SW,
    input  logic         GO,
    output logic         RUN);

    logic [10:0] disp_x;
    logic [ 9:0] disp_y;

    logic [ 8:0] frame_cnt, col_x;
    logic [ 7:0] col_y;
    logic [ 1:0] wait_cnt;
    logic        mode;

    logic [25:0] fifo_in, fifo_out;
    logic        fifo_we, fifo_re, fifo_empty, fifo_full, fifo_rst;

    logic [23:0] scale_tdata;
    logic        scale_tlast, scale_tuser, scale_tvalid, scale_tready;

    fifo #(.WIDTH(26), .SIZE(1024)) send_fifo (
        .CLK(AXIS_VID_ACLK),
        .RST(~ AXIS_VID_ARESETN),
        .DATA_W(fifo_in),
        .DATA_R(fifo_out),
        .WE(fifo_we),
        .RE(fifo_re),
        .EMPTY(fifo_empty),
        .FULL(fifo_full),
        .SOFT_RST(fifo_rst));

    scaler150 scale (
        .ACLK(AXIS_VID_ACLK),
        .ARESETN(AXIS_VID_ARESETN),
        .MODE(mode),
        .S_TDATA(scale_tdata),
        .S_TLAST(scale_tlast),
        .S_TUSER(scale_tuser),
        .S_TVALID(scale_tvalid),
        .S_TREADY(scale_tready),
        .M_TDATA(AXIS_VID_TDATA),
        .M_TLAST(AXIS_VID_TLAST),
        .M_TUSER(AXIS_VID_TUSER[0]),
        .M_TVALID(AXIS_VID_TVALID),
        .M_TREADY(AXIS_VID_TREADY));
    
    assign col_x = frame_cnt + disp_x[8:0];
    assign col_y = frame_cnt[8:1] + disp_y[7:0];
    assign fifo_in[25] = (disp_x == 11'd0 && disp_y == 10'd0);
    assign fifo_in[24] = (disp_x == 11'd799);
    assign fifo_in[23:16] = (col_x[8]) ? col_y : 8'h00;
    assign fifo_in[15: 8] = (col_x[6]) ? col_y : 8'h00;
    assign fifo_in[ 7: 0] = (col_x[7]) ? col_y : 8'h00;
    assign fifo_we = (disp_x <= 11'd799 && disp_y <= 10'd479 && wait_cnt == 2'd0);
    assign fifo_re = scale_tvalid & scale_tready;
    assign fifo_rst = GO & ~ RUN;
    assign scale_tuser  = fifo_out[25];
    assign scale_tlast  = fifo_out[24];
    assign scale_tdata  = fifo_out[23: 0];
    assign scale_tvalid = ~ fifo_empty;

    always_ff @ (posedge AXIS_VID_ACLK) begin
        if (~ AXIS_VID_ARESETN) begin
            RUN       <= 1'b0;
            mode      <= 1'b0;
            disp_x    <= 11'h7ff;
            disp_y    <= 10'h3ff;
            frame_cnt <= 9'd0;
            wait_cnt  <= 2'h3;
        end else begin
            if (~ RUN) begin
                if (GO) begin
                    RUN       <= 1'b1;
                    mode      <= SW;
                    disp_x    <= 11'd0;
                    disp_y    <= 10'd0;
                    frame_cnt <= 9'd0;
                    wait_cnt  <= 2'd0;
                end
            end else if (wait_cnt != 2'd0) begin
                wait_cnt  <= wait_cnt - 1'b1;
            end else if (~ fifo_full) begin
                disp_x    <= (disp_x == 11'd1055) ? 11'd0 : disp_x + 1'd1;
                disp_y    <= (disp_x != 11'd1055) ? disp_y :
                             (disp_y == 10'd524)  ? 10'd0 : disp_y + 1'd1;
                frame_cnt <= (disp_x == 11'd1055 && disp_y == 10'd524) ?
                             frame_cnt + 1'd1 : frame_cnt;
                wait_cnt  <= 2'd2;
            end
        end
    end
endmodule