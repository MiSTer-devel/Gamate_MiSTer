//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign LED_USER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] scale = status[3:2];
wire [1:0] ar = status[122:121];

`include "build_id.v"
localparam CONF_STR = {
	"Gamate;;",
	"-;",
	"F1,bin,Load Cartridge;",
	"-;",
	"O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O[20],Flickerblend,On,Off;",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"OAB,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"O[21],Drop Shadows,On,Off;",
	"-;",
	"O7,Custom Palette,Off,On;",
	"D0FC3,SGBGBP,Load Palette;",
	"-;",
	"R0,Reset;",
	"J0,B,A,select,start;",
	"V,v",`BUILD_DATE
};

wire forced_scandoubler;
wire [15:0] joystick_0;
wire  [1:0] buttons;
wire [127:0] status;
wire [10:0] ps2_key;

wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;
wire ioctl_wr;
wire ioctl_download;
wire ioctl_wait;
wire [21:0] gamma_bus;
wire rom_download = ((~|ioctl_index[5:0] && ioctl_index[7:6] == 1) || ioctl_index[5:0] == 1) && ioctl_download;
wire bios_download = (~|ioctl_index[5:0] && ioctl_index[7:6] == 0) && ioctl_download;

wire clk_sys;
wire clk_vid; // Make a different clock to seperate intent in case the video rate needs change
wire clk_ram;
wire clock_locked;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.gamma_bus(gamma_bus),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({~status[7]}),

	.ps2_key(ps2_key),
	.joystick_0(joystick_0),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index)
);


pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_ram),
	.outclk_1(clk_sys), // 4.433 MHZ * 4 = 17.732mhz
	.locked(clock_locked)
);

assign clk_vid = clk_sys;

wire ce_pix;
wire freeze_sync;

wire hsync;
wire vsync;
wire hblank;
wire vblank;
wire vga_de;

logic [8:0] red, green, blue, rt, gt, bt;
wire palette_download = (ioctl_index[5:0] == 3) && ioctl_download;
wire reset = RESET | status[0] | buttons[1] | rom_download;

assign CLK_VIDEO = clk_vid;

wire [7:0] rom_dout, bios_dout;
wire [19:0] rom_addr;
wire [1:0] last_pixel, pixel, prev_pixel;
wire rom_cs;
reg [14:0] vbuffer_addr;
wire cart_busy;
reg [21:0] rom_mask = 19'h7FFFF;

assign ioctl_wait = cart_busy & rom_download;

gamate gamate
(
	.clk            (clk_sys),
	.reset          (reset),
	.joystick       (joystick_0),
	.bios_dout      (bios_dout),
	.cart_dout      (rom_dout),
	.rom_addr       (rom_addr),
	.rom_size       (rom_mask),
	.rom_read       (rom_cs),
	.audio_right    (AUDIO_R),
	.audio_left     (AUDIO_L),
	.hsync          (hsync),
	.hblank         (hblank),
	.ce_pix         (ce_pix),
	.vsync          (vsync),
	.vblank         (vblank),
	.pixel          (pixel)
);

logic [127:0] user_palette = 128'h828214_517356_305A5F_1A3B49_0000_0000;

wire [127:0] default_palette = 128'h828214_517356_305A5F_1A3B49_0000_0000;

logic [2:0][7:0] palette[4];

assign palette[0] = status[7] ? user_palette[127:104] : default_palette[127:104];
assign palette[1] = status[7] ? user_palette[103:80]  : default_palette[103:80];
assign palette[2] = status[7] ? user_palette[79:56]   : default_palette[79:56];
assign palette[3] = status[7] ? user_palette[55:32]   : default_palette[55:32];

reg [149:0][1:0] shadow_buffer;
reg [7:0] hpos;
reg [1:0] sc;

wire shadow_en = ~status[21] && ~|last_pixel && |sc;
assign red   = shadow_en ? ((rt >> 1) + (rt >> 2) + (~sc[1] ? (rt >> 3) : 1'd0) + (~sc[0] ? (rt >> 4) : 1'd0)) : rt;
assign green = shadow_en ? ((gt >> 1) + (gt >> 2) + (~sc[1] ? (gt >> 3) : 1'd0) + (~sc[0] ? (gt >> 4) : 1'd0)) : gt;
assign blue  = shadow_en ? ((bt >> 1) + (bt >> 2) + (~sc[1] ? (bt >> 3) : 1'd0) + (~sc[0] ? (bt >> 4) : 1'd0)) : bt;

always_ff @(posedge clk_vid) begin
	if (ce_pix) begin
		if (~hblank)
			hpos <= hpos + 1'd1;
		else
			hpos <= 0;

		shadow_buffer[hpos] <= vblank ? 2'b00 : pixel;
		sc <= shadow_buffer[hpos];
		
		rt <= ~status[20] ? (({1'b0, palette[pixel][2]} + palette[prev_pixel][2]) >> 1'd1) : palette[pixel][2];
		gt <= ~status[20] ? (({1'b0, palette[pixel][1]} + palette[prev_pixel][1]) >> 1'd1) : palette[pixel][1];
		bt <= ~status[20] ? (({1'b0, palette[pixel][0]} + palette[prev_pixel][0]) >> 1'd1) : palette[pixel][0];
		last_pixel <= pixel;

		if (~vblank && ~hblank)
			vbuffer_addr <= vbuffer_addr + 1'd1;

		if (vsync)
			vbuffer_addr <= 0;
	end
end

dpram #(.data_width(2), .addr_width(15)) vbuffer (
	.clock      (clk_sys),

	.address_a  (vbuffer_addr - 1'd1),
	.data_a     (last_pixel),
	.wren_a     (~vblank && ~hblank && CE_PIXEL),

	.address_b  (vbuffer_addr),
	.q_b        (prev_pixel)
);

always @(posedge clk_sys) begin
	if (rom_download && ioctl_wr)
		rom_mask <= ioctl_addr[18:0];
	if (palette_download)
		user_palette[{~ioctl_addr[3:0], 3'b000}+:8] <= ioctl_dout;
end

sdram cart_rom
(
	.SDRAM_DQ       (SDRAM_DQ),
	.SDRAM_A        (SDRAM_A),
	.SDRAM_DQML     (SDRAM_DQML),
	.SDRAM_DQMH     (SDRAM_DQMH),
	.SDRAM_BA       (SDRAM_BA),
	.SDRAM_nCS      (SDRAM_nCS),
	.SDRAM_nWE      (SDRAM_nWE),
	.SDRAM_nRAS     (SDRAM_nRAS),
	.SDRAM_nCAS     (SDRAM_nCAS),
	.SDRAM_CLK      (SDRAM_CLK),
	.SDRAM_CKE      (SDRAM_CKE),

	.init           (!clock_locked),
	.clk            (clk_ram),

	.ch0_addr       (rom_download ? ioctl_addr : (rom_addr & rom_mask)),
	.ch0_rd         (rom_cs && ~rom_download),
	.ch0_wr         (rom_download & ioctl_wr),
	.ch0_din        (ioctl_dout),
	.ch0_dout       (rom_dout),
	.ch0_busy       (cart_busy)
);

spram #(.addr_width(12)) bios
(
	.clock          (clk_sys),
	.address        (bios_download ? ioctl_addr[11:0] : rom_addr[11:0]),
	.data           (ioctl_dout),
	.wren           (bios_download & ioctl_wr),
	.q              (bios_dout)
);


video_freak video_freak
(
	.*,
	.VGA_DE_IN      (vga_de),
	.VGA_DE         (VGA_DE),
	.ARX            ((!ar) ? 12'd160 : (ar - 1'd1)),
	.ARY            ((!ar) ? 12'd150 : 12'd0),
	.CROP_SIZE      (0),
	.CROP_OFF       (0),
	.SCALE          (status[11:10])
);

video_mixer #(640, 0) mixer
(
	.*,
	.CE_PIXEL       (CE_PIXEL),
	.hq2x           (scale == 1),
	.scandoubler    (scale || forced_scandoubler),
	.gamma_bus      (gamma_bus),
	.R              (red[7:0]),
	.G              (green[7:0]),
	.B              (blue[7:0]),
	.HSync          (hsync),
	.VSync          (vsync),
	.HBlank         (hblank),
	.VBlank         (vblank),
	.VGA_R          (VGA_R),
	.VGA_G          (VGA_G),
	.VGA_B          (VGA_B),
	.VGA_VS         (VGA_VS),
	.VGA_HS         (VGA_HS),
	.VGA_DE         (vga_de)
);

endmodule
