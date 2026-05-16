/*
 * Copyright (c) 2024-2025 James Ross
 * SPDX-License-Identifier: Apache-2.0
 *
 * Modified: "CARMONA PALENGKE" falling letters, blue-cyan-purple gradient
 */

`default_nettype none

module tt_um_vga_glyph_mode(
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	// VGA signals
	wire hsync, vsync, display_on;
	wire [10:0] hpos;
	wire [9:0] vpos;

	// TinyVGA PMOD
	assign uo_out = {hsync, RGB[0], RGB[2], RGB[4], vsync, RGB[1], RGB[3], RGB[5]};

	// Unused outputs assigned to 0.
	assign uio_out = 0;
	assign uio_oe  = 0;

	wire [7:0] xb = hpos[10:3];
	wire [6:0] x_mix = {xb[7] ^ xb[3], xb[1], xb[4], xb[1], xb[6], xb[0], xb[2]};
	wire [2:0] g_x = hpos[2:0];
	wire [5:0] yb;
	wire [3:0] _unused;
	assign {_unused, yb} = vpos / 10'd12;
	wire [5:0] g_unused;
	wire [3:0] g_y;
	assign {g_unused, g_y} = vpos - {yb, 3'b000} - {1'b0, yb, 2'b00};
	wire hl;

	reg [9:0] frame;
	reg rst_drop;

	// VGA sync generator
	hvsync_generator hvsync_gen(
		.clk(clk),
		.reset(~rst_n),
		.mode(ui_in[7:6]),
		.hsync(hsync),
		.vsync(vsync),
		.display_on(display_on),
		.hpos(hpos),
		.vpos(vpos)
	);

	// -------------------------------------------------------
	// "CARMONA PALENGKE" text ROM  (16 characters, repeating)
	//  Glyph ROM indices: A=0 B=1 C=2 D=3 E=4 F=5 G=6 H=7
	//                     I=8 J=9 K=10 L=11 M=12 N=13 O=14
	//                     P=15 Q=16 R=17 S=18 T=19 U=20 V=21
	//                     W=22 X=23 Y=24 Z=25  SPACE=26
	//
	//   C   A   R   M   O   N   A  SP   P   A   L   E   N   G   K   E
	//   2   0  17  12  14  13   0  26  15   0  11   4  13   6  10   4
	// -------------------------------------------------------
	reg [5:0] text_rom [0:15];
	initial begin
		text_rom[0]  = 6'd2;   // C
		text_rom[1]  = 6'd0;   // A
		text_rom[2]  = 6'd17;  // R
		text_rom[3]  = 6'd12;  // M
		text_rom[4]  = 6'd14;  // O
		text_rom[5]  = 6'd13;  // N
		text_rom[6]  = 6'd0;   // A
		text_rom[7]  = 6'd26;  // (space)
		text_rom[8]  = 6'd15;  // P
		text_rom[9]  = 6'd0;   // A
		text_rom[10] = 6'd11;  // L
		text_rom[11] = 6'd4;   // E
		text_rom[12] = 6'd13;  // N
		text_rom[13] = 6'd6;   // G
		text_rom[14] = 6'd10;  // K
		text_rom[15] = 6'd4;   // E
	end

	// Each column of 8px maps to one character in the phrase (cycles mod 16)
	wire [5:0] glyph_index = text_rom[xb[3:0]];

	// Glyph pixel lookup
	glyphs_rom glyphs(
		.c(glyph_index),
		.y(g_y),
		.x(g_x),
		.pixel(hl)
	);

	// Palette lookup (pid driven by ui_in[1:0]; default 0 = blue-cyan-purple)
	wire [5:0] color;
	palette_rom palettes(
		.cid(y),
		.pid(ui_in[1:0]),
		.color(color)
	);

	// -------------------------------------------------------
	// Rain animation signals (unchanged from original)
	// -------------------------------------------------------
	wire [1:0] a = xb[1:0];
	wire [3:0] b = xb[5:2];
	wire [2:0] d = xb[3:2] + 2'd3;

	// toggle-glyph flag (kept for timing parity; unused in text mode)
	wire t = &{xb[0] ^ yb[2] ^ frame[7], xb[1] ^ yb[1] ^ frame[8],
	            xb[2] ^ yb[3] ^ frame[9], xb[3] ^ yb[0]};

	// column speed (varies per column for organic look)
	wire s = ^xb[6:0];

	// n=0: all columns are lit; original used xb[1]^xb[3]^xb[5] which
	// silenced half the columns and made half the text invisible.
	wire n = 1'b0;

	wire [6:0] v = (s ? frame[8:2] : frame[9:3]) - yb - x_mix;
	wire [3:0] c = {1'b0, a} + d;
	wire [6:0] e = {3'b000, b} << c;
	wire [6:0] f = v & e;         // rain-drop spacing mask
	wire [6:0] x = v >> a;
	wire [2:0] y = ~x[2:0];      // palette brightness index (0=dim, 7=bright)
	wire [9:0] drop = {1'b0, yb, 3'd0} >> s;
	wire drop_bit = ({3'd0, x_mix} + drop > frame) & ~rst_drop;
	wire [5:0] glyph_color = {6{drop_bit}} ^ color;

	// Head of stream flashes full-white (6'd63); body uses palette
	wire [5:0] z = (&(~v[2:0]) & &(y)) ? 6'd63 : glyph_color;

	wire [5:0] RGB = (display_on & hl & ~(|f | n | drop_bit)) ? z : 6'd0;

	// Suppress unused-signal warnings
	wire _unused_ok = &{ena, ui_in[5:2], uio_in, t};

	always @(posedge vsync, negedge rst_n) begin
		if (~rst_n) begin
			rst_drop <= 0;
			frame    <= 0;
		end else begin
			if (&frame) rst_drop <= 1;
			frame <= frame + 1;
		end
	end

endmodule
