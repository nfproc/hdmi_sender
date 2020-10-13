// Test Bench for Video Test Pattern Sender 2020.08.30 Naoki F., AIT
// ライセンスについては LICENSE.txt を参照してください．

module sender_test ();
    logic         AXIS_VID_ACLK;
    logic         AXIS_VID_ARESETN;
    logic [23: 0] AXIS_VID_TDATA, AXIS_VID_TDATA2;
    logic         AXIS_VID_TLAST, AXIS_VID_TLAST2;
    logic [ 0: 0] AXIS_VID_TUSER, AXIS_VID_TUSER2;
    logic         AXIS_VID_TVALID, AXIS_VID_TVALID2;
    logic         AXIS_VID_TREADY;
    logic         GO;
    logic         RUN;

    AXIS_send sender1 (
        AXIS_VID_ACLK,
        AXIS_VID_ARESETN,
        AXIS_VID_TDATA,
        AXIS_VID_TLAST,
        AXIS_VID_TUSER,
        AXIS_VID_TVALID,
        AXIS_VID_TREADY,
        1'b0,
        GO,
        RUN);
        
    AXIS_send sender2 (
        AXIS_VID_ACLK,
        AXIS_VID_ARESETN,
        AXIS_VID_TDATA2,
        AXIS_VID_TLAST2,
        AXIS_VID_TUSER2,
        AXIS_VID_TVALID2,
        AXIS_VID_TREADY,
        1'b1,
        GO,
        RUN);

    logic [31:0] count, count2;

    assign AXIS_VID_TREADY = 1'b1;
    initial begin
        AXIS_VID_ARESETN = 1'b0; GO <= 1'b0; #50;
        AXIS_VID_ARESETN = 1'b1; #50;
        GO <= 1'b1;
    end

    always begin
        AXIS_VID_ACLK = 1'b1; #5;
        AXIS_VID_ACLK = 1'b0; #5;
    end

    always_ff @ (posedge AXIS_VID_ACLK) begin
        if (~ AXIS_VID_ARESETN) begin
            count  <= 0;
            count2 <= 0;
        end else begin
            count  <= (AXIS_VID_TVALID ) ? count  + 1'b1 : count;
            count2 <= (AXIS_VID_TVALID2) ? count2 + 1'b1 : count2;
        end
    end
endmodule