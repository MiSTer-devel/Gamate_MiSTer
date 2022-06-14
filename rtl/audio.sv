module audio
(
	input clk,
	input [6:0] AB,
	input reset,
	input ce,
	input sys_cs,
	input cpu_rwn,
	input din
);

// 6mhz / 128 clock divider

reg [11:0] sq1_freq, sq2_freq_ps;

reg [7:0] audio_ctl, volume;

wire [3:0] audio_mode = audio_ctl[3:0];
wire [2:0] prescaler = audio_ctl[6:4];

// Modes:
// 0 - silence (bit 7 of 0017 runs to negative output inverted)
// 1 - PWM (single ended)
// 2 - square 1
// 3 - silence (both outputs low)
// 4 - square 2
// 5 - PWM (double ended, one signal out of phase. not used)
// 6 - square 1 + square 2
// 7 - silence (one output high, one output low)

// 8 - silence (bit 7 of 0017 will run to negative output)
// 9 - PWM (single ended + inverted) silent
// a - square 1
// b - silence (both outputs low)
// c - noise
// d - PWM (double ended + inverted)
// e - square 1 + noise
// f - silence (both outputs low)

// int B's are NOT generated for modes 0,2,8,A,C,E

always_ff @(posedge clk) begin
	if (ce) begin
		if (cpu_rwn && sys_cs) begin
			case (AB)
				7'h10: sq1_freq[7:0] <= din;
				7'h11: sq1_freq[11:8] <= din[3:0];
				7'h12: sq2_freq_ps[7:0] <= din;
				7'h13: sq2_freq_ps[11:8] <= din[3:0];
				7'h14: ; // Read only, PWN value
				7'h15: ; // Unused
				7'h16: audio_ctl <= din;
				7'h17: volume;
				// 18-1F unused
				7'h20: timer_0_div <= din;
				7'h21: timer_int <= din;
				7'h22: ; // Unused
				7'h23: ; // Timer 1 enable?
				7'h24: ; // tcon reg for timer 1
				7'h25: ; // timer 1 prescaler
				7'h26: ; // timer2
				
			endcase
		end
	end
end

endmodule