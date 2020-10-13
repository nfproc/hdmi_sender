// Initializer of Video Test Pattern Sender 2020.10.13 Naoki F., AIT
// ライセンスについては LICENSE.txt を参照してください．

#include "xparameters.h"
#include "xil_io.h"
#include "xil_cache.h"
#define VWIDTH 1280
#define VHEIGHT 720

unsigned char fbuf[3][VHEIGHT][VWIDTH * 3] __attribute__((aligned(16)));

int main ()
{
  int sw, b, x, y;
  int pwidth, pheight;

  // フレームバッファを初期化
  for (b = 0; b < 3; b++) {
    for (y = 0; y < VHEIGHT; y++) {
      for (x = 0; x < VWIDTH * 3; x++) {
        fbuf[b][y][x] = (((x / 3) ^ y) & 0x10) ? 0x00 : 0x40;
      }
    }
  }
  Xil_DCacheFlushRange((unsigned int) fbuf, sizeof(fbuf));

  // トグルスイッチ入力をもとにパターンサイズを決定
  sw = Xil_In32(XPAR_SENDER_TOP_0_BASEADDR + 0x04);
  if (sw == 0) {
    pwidth = 800;
    pheight = 480;
  } else {
    pwidth = 1200;
    pheight = 720;
  }

  // VDMA を初期化
  x = (VWIDTH - pwidth) / 2;
  y = (VHEIGHT - pheight) / 2;
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x30, 0x8B);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0xAC, (unsigned int) &fbuf[0][y][x * 3]);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0xB0, (unsigned int) &fbuf[1][y][x * 3]);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0xB4, (unsigned int) &fbuf[2][y][x * 3]);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0xA8, VWIDTH * 3);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0xA4, pwidth * 3);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0xA0, pheight);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x00, 0x8B);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x5C, (unsigned int) &fbuf[0][0][0]);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x60, (unsigned int) &fbuf[1][0][0]);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x64, (unsigned int) &fbuf[2][0][0]);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x58, VWIDTH * 3);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x54, VWIDTH * 3);
  Xil_Out32(XPAR_AXI_VDMA_0_BASEADDR + 0x50, VHEIGHT);

  // パターン送信 IP コアを初期化
  Xil_Out32(XPAR_SENDER_TOP_0_BASEADDR + 0x00, 1);
}
