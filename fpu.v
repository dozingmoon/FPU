
//	IEEE 754 SINGLE PRECISION ALU	//

module fpu(	out, nan_in, overflow, in_exact, zero, op_nan
			, clk_in, rst, opa_in, opb_in, mode_in, op_code);
output	[31:0]	out;
output			nan_in, overflow, in_exact, zero, op_nan;
input 	[31:0]	opa_in, opb_in;
input	[1:0]	op_code;
input	[1:0]	mode_in;
input			clk_in, rst;

wire	[24:0]	a_mantissa, b_mantissa;

reg		[7:0]	pre_exponent;
reg 			pre_a_sign;
reg		[27:0]	pre_a_mantissa;
reg 			pre_b_sign;
reg		[27:0]	pre_b_mantissa;
reg		[7:0]	pre_tmp_exponent;

reg		[27:0]	adder_mantissa;
reg		[7:0]	adder_exponent;
reg				adder_sign;

reg				post_sign;
reg		[8:0]  	post_exponent;
reg		[27:0] 	post_mantissa;

`define ADD		2'b00;
`define SUB		2'b01;
`define MUL		2'b10;
`define DIV 	2'b11;

assign out = {post_sign, post_exponent[7:0], post_mantissa[25:3]};

always @ ( * )begin
	if(rst) begin
		adder_sign = 1'bz;
		post_exponent = 8'bz;
		post_mantissa = 23'bz;
	end
	case(op_code)
		//	Adder
		2'b00: begin
			if(opa_in[30:23] == 255 && opb_in[22:0] == 0) begin
				nan_in = 1;
				
			end
			
		
			//	Pre-Normalization
			pre_tmp_exponent = opa_in[30:23] - opb_in[30:23];
			pre_a_sign = opa_in[31];
			pre_b_sign = opb_in[31];
			if(opa_in[30:23] > opb_in[30:23]) begin
				pre_exponent = opa_in[30:23];
				pre_a_mantissa = {2'b01, opa_in[22:0], 3'b000};
				pre_b_mantissa = {{2'b01, opb_in[22:0]}>>pre_tmp_exponent), 3'b000};
			end
			else begin
				pre_exponent = opb_in[30:23];
				pre_a_mantissa = {{2'b01, opa_in[22:0]}>>(-pre_tmp_exponent), 3'b000};
				pre_b_mantissa = {2'b01, opb_in[22:0], 3'b000};
			end
			
			//	Adder
			if( pre_a_sign == pre_b_sign) begin
				adder_mantissa = pre_a_mantissa + pre_b_mantissa;
				adder_exponent = pre_exponent;
				adder_sign = pre_a_sign;
			end
			else begin
				if( pre_a_mantissa > pre_b_mantissa) begin
					adder_exponent = pre_exponent;
					adder_sign = pre_a_sign;
				end
				else if ( pre_b_mantissa > pre_a_mantissa )begin
					adder_exponent = pre_exponent;
					adder_sign = pre_b_sign;
				end
				else begin
					adder_exponent = 8'b0;
					adder_sign = 0;
				end
				adder_mantissa = pre_a_mantissa - pre_b_mantissa;
			end
			
			//	Post-normalization
			post_sign = adder_sign;
			if( (adder_mantissa[25] != 1) && (adder_exponent != 0) ) begin
				if (adder_mantissa[25:5] == 21'b000000000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 20;
					post_mantissa = adder_mantissa << 20;
				end else if (adder_mantissa[25:6] == 20'b00000000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 19;
					post_mantissa = adder_mantissa << 19;
				end else if (adder_mantissa[25:7] == 19'b0000000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 18;
					post_mantissa = adder_mantissa << 18;
				end else if (adder_mantissa[25:8] == 18'b000000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 17;
					post_mantissa = adder_mantissa << 17;
				end else if (adder_mantissa[25:9] == 17'b00000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 16;
					post_mantissa = adder_mantissa << 16;
				end else if (adder_mantissa[25:10] == 16'b0000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 15;
					post_mantissa = adder_mantissa << 15;
				end else if (adder_mantissa[25:11] == 15'b000000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 14;
					post_mantissa = adder_mantissa << 14;
				end else if (adder_mantissa[25:12] == 14'b00000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 13;
					post_mantissa = adder_mantissa << 13;
				end else if (adder_mantissa[25:13] == 13'b0000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 12;
					post_mantissa = adder_mantissa << 12;
				end else if (adder_mantissa[25:14] == 12'b000000000001) begin
					post_exponent = {1'b0, adder_exponent} - 11;
					post_mantissa = adder_mantissa << 11;
				end else if (adder_mantissa[25:15] == 11'b00000000001) begin
					post_exponent = {1'b0, adder_exponent} - 10;
					post_mantissa = adder_mantissa << 10;
				end else if (adder_mantissa[25:16] == 10'b0000000001) begin
					post_exponent = {1'b0, adder_exponent} - 9;
					post_mantissa = adder_mantissa << 9;
				end else if (adder_mantissa[25:17] == 9'b000000001) begin
					post_exponent = {1'b0, adder_exponent} - 8;
					post_mantissa = adder_mantissa << 8;
				end else if (adder_mantissa[25:18] == 8'b00000001) begin
					post_exponent = {1'b0, adder_exponent} - 7;
					post_mantissa = adder_mantissa << 7;
				end else if (adder_mantissa[25:19] == 7'b0000001) begin
					post_exponent = {1'b0, adder_exponent} - 6;
					post_mantissa = adder_mantissa << 6;
				end else if (adder_mantissa[25:20] == 6'b000001) begin
					post_exponent = {1'b0, adder_exponent} - 5;
					post_mantissa = adder_mantissa << 5;
				end else if (adder_mantissa[25:21] == 5'b00001) begin
					post_exponent = {1'b0, adder_exponent} - 4;
					post_mantissa = adder_mantissa << 4;
				end else if (adder_mantissa[25:22] == 4'b0001) begin
					post_exponent = {1'b0, adder_exponent} - 3;
					post_mantissa = adder_mantissa << 3;
				end else if (adder_mantissa[25:23] == 3'b001) begin
					post_exponent = {1'b0, adder_exponent} - 2;
					post_mantissa = adder_mantissa << 2;
				end else if (adder_mantissa[25:24] == 2'b01) begin
					post_exponent = {1'b0, adder_exponent} - 1;
					post_mantissa = adder_mantissa << 1;
				end
			end
			if(adder_mantissa[27] == 1) begin
				post_exponent = {1'b0, {1'b0, adder_exponent}} + 1;
				post_mantissa = adder_mantissa >> 1;
			end
			else begin
				post_exponent = {1'b0, {1'b0, adder_exponent}};
				post_mantissa = adder_mantissa;
			end
		end
	endcase
end
endmodule
