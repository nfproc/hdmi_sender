// Video Test Pattern Sender 2020.08.29 Naoki F., AIT
// ライセンスについては LICENSE.txt を参照してください．

module sender_top (
    // AXI Lite 関連信号
    input          ACLK,
    input          ARESETN,
    input          SW,
    input  [ 3: 0] AXI_CTRL_AWADDR,
    input  [ 2: 0] AXI_CTRL_AWPROT,
    input          AXI_CTRL_AWVALID,
    output         AXI_CTRL_AWREADY,
    input  [31: 0] AXI_CTRL_WDATA,
    input  [ 3: 0] AXI_CTRL_WSTRB,
    input          AXI_CTRL_WVALID,
    output         AXI_CTRL_WREADY,
    output [ 1: 0] AXI_CTRL_BRESP,
    output         AXI_CTRL_BVALID,
    input          AXI_CTRL_BREADY,
    input  [ 3: 0] AXI_CTRL_ARADDR,
    input  [ 2: 0] AXI_CTRL_ARPROT,
    input          AXI_CTRL_ARVALID,
    output         AXI_CTRL_ARREADY,
    output [31: 0] AXI_CTRL_RDATA,
    output [ 1: 0] AXI_CTRL_RRESP,
    output         AXI_CTRL_RVALID,
    input          AXI_CTRL_RREADY,
    // AXI Stream 関連信号
    output [23: 0] AXIS_VID_TDATA,
    output         AXIS_VID_TLAST,
    output [ 0: 0] AXIS_VID_TUSER,
    output         AXIS_VID_TVALID,
    input          AXIS_VID_TREADY);

    wire           sender_go, sender_run;

    AXI_ctrl ctrl (
        .AXI_CTRL_ACLK(ACLK),
        .AXI_CTRL_ARESETN(ARESETN),
        .AXI_CTRL_AWADDR(AXI_CTRL_AWADDR),
        .AXI_CTRL_AWPROT(AXI_CTRL_AWPROT),
        .AXI_CTRL_AWVALID(AXI_CTRL_AWVALID),
        .AXI_CTRL_AWREADY(AXI_CTRL_AWREADY),
        .AXI_CTRL_WDATA(AXI_CTRL_WDATA),
        .AXI_CTRL_WSTRB(AXI_CTRL_WSTRB),
        .AXI_CTRL_WVALID(AXI_CTRL_WVALID),
        .AXI_CTRL_WREADY(AXI_CTRL_WREADY),
        .AXI_CTRL_BRESP(AXI_CTRL_BRESP),
        .AXI_CTRL_BVALID(AXI_CTRL_BVALID),
        .AXI_CTRL_BREADY(AXI_CTRL_BREADY),
        .AXI_CTRL_ARADDR(AXI_CTRL_ARADDR),
        .AXI_CTRL_ARPROT(AXI_CTRL_ARPROT),
        .AXI_CTRL_ARVALID(AXI_CTRL_ARVALID),
        .AXI_CTRL_ARREADY(AXI_CTRL_ARREADY),
        .AXI_CTRL_RDATA(AXI_CTRL_RDATA),
        .AXI_CTRL_RRESP(AXI_CTRL_RRESP),
        .AXI_CTRL_RVALID(AXI_CTRL_RVALID),
        .AXI_CTRL_RREADY(AXI_CTRL_RREADY),
        .SW(SW),
        .SENDER_GO(sender_go),
        .SENDER_RUN(sender_run));

    AXIS_send sender (
        .AXIS_VID_ACLK(ACLK),
        .AXIS_VID_ARESETN(ARESETN),
        .AXIS_VID_TDATA(AXIS_VID_TDATA),
        .AXIS_VID_TLAST(AXIS_VID_TLAST),
        .AXIS_VID_TUSER(AXIS_VID_TUSER),
        .AXIS_VID_TVALID(AXIS_VID_TVALID),
        .AXIS_VID_TREADY(AXIS_VID_TREADY),
        .SW(SW),
        .GO(sender_go),
        .RUN(sender_run));
endmodule
