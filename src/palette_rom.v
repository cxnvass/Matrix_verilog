/*
 * Copyright (c) 2025 James Ross
 * SPDX-License-Identifier: Apache-2.0
 *
 * Palette 0 (default): blue → cyan → purple gradient
 *   6-bit color format: [5:4]=RR  [3:2]=GG  [1:0]=BB  (2 bits each, 0-3)
 *
 *   level 0 → 7 maps dark-to-bright along the falling column.
 *   The very tip (head) is forced full-white (6'd63) in the top module,
 *   so level 7 is the "near-head" colour.
 *
 *   Gradient path:
 *     dim → blue → blue-teal → cyan → cyan-purple → purple → bright purple
 *
 *   Palette 1 – cooler (more blue-dominant)
 *   Palette 2 – warmer (more purple/magenta-dominant)
 *   Palette 3 – high-contrast neon (select via ui_in[1:0])
 */

`default_nettype none

module palette_rom(
	input  wire [2:0] cid, // color id  (brightness level 0-7)
	input  wire [1:0] pid, // palette   (0-3, from ui_in[1:0])
	output wire [5:0] color
);
	reg [5:0] palette[3:0][7:0];
	assign color = palette[pid][cid];

	initial begin
		// ---- Palette 0 : blue → cyan → purple (DEFAULT) ----
		// cid=0 is darkest (tail), cid=7 is near-head (brightest body)
		palette[0][0] = 6'b000000; // off / black
		palette[0][1] = 6'b000001; // very dim blue       R=0 G=0 B=1
		palette[0][2] = 6'b000010; // dim blue            R=0 G=0 B=2
		palette[0][3] = 6'b000011; // blue                R=0 G=0 B=3
		palette[0][4] = 6'b000111; // blue-cyan           R=0 G=1 B=3
		palette[0][5] = 6'b001111; // cyan                R=0 G=3 B=3
		palette[0][6] = 6'b100011; // medium purple       R=2 G=0 B=3
		palette[0][7] = 6'b110011; // bright purple/violet R=3 G=0 B=3

		// ---- Palette 1 : cool (pure blue dominant) ----
		palette[1][0] = 6'b000000; // off
		palette[1][1] = 6'b000001; // very dim blue
		palette[1][2] = 6'b000011; // blue
		palette[1][3] = 6'b000111; // blue-teal
		palette[1][4] = 6'b001111; // cyan
		palette[1][5] = 6'b011111; // light cyan          R=1 G=3 B=3
		palette[1][6] = 6'b001111; // back to cyan
		palette[1][7] = 6'b010111; // pale blue-cyan      R=1 G=1 B=3

		// ---- Palette 2 : warm (purple/magenta dominant) ----
		palette[2][0] = 6'b000000; // off
		palette[2][1] = 6'b010000; // very dim red-purple R=1 G=0 B=0
		palette[2][2] = 6'b010001; // dim purple          R=1 G=0 B=1
		palette[2][3] = 6'b100001; // purple              R=2 G=0 B=1
		palette[2][4] = 6'b100011; // violet              R=2 G=0 B=3
		palette[2][5] = 6'b110011; // bright purple       R=3 G=0 B=3
		palette[2][6] = 6'b110111; // purple-cyan         R=3 G=1 B=3
		palette[2][7] = 6'b111111; // white-purple head

		// ---- Palette 3 : neon (high-contrast) ----
		palette[3][0] = 6'b000000; // off
		palette[3][1] = 6'b000001; // dim blue
		palette[3][2] = 6'b000011; // blue
		palette[3][3] = 6'b001111; // cyan (skip mid-blue for punch)
		palette[3][4] = 6'b011011; // periwinkle          R=1 G=2 B=3
		palette[3][5] = 6'b110011; // purple
		palette[3][6] = 6'b110111; // purple-cyan
		palette[3][7] = 6'b111111; // white head
	end
endmodule
