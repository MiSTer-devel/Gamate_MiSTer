module dma
(
	input clk,
	input [6:0] AB,
	input reset,
	input ce,
	input sys_cs,
	input cpu_rwn,
	input din
);


always_ff @(posedge clk) begin
	if (ce) begin
		if (cpu_rwn && sys_cs) begin
			case (AB)
				7'h20: sq1_freq[7:0] <= din;
				7'h21: sq1_freq[11:8] <= din[3:0];
				7'h22: sq2_freq_ps[7:0] <= din;
				7'h23: sq2_freq_ps[11:8] <= din[3:0];
				7'h24: ; // Read only, PWN value
				7'h25: ; // Unused
				7'h26: audio_ctl <= din;
				7'h27: volume;
				7'h28: volume;
				7'h29: volume;
				7'h2A: volume;
				7'h2B: volume;
				7'h2C: volume;
				7'h2D: volume;
				7'h2E: volume;
				7'h2F: volume;
				7'h30: timer_0_div <= din;
				7'h31: timer_int <= din;
				7'h32: ; // Unused
				7'h33: ; // Timer 1 enable?
				7'h34: ; // tcon reg for timer 1
				7'h35: ; // timer 1 prescaler
				7'h36: timer_int <= din;
				7'h37: ; // Unused
				7'h38: ; // Timer 1 enable?
				7'h39: ; // tcon reg for timer 1
				7'h3A: ; // timer 1 prescaler
			endcase
		end
	end
end

endmodule