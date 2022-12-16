
//	IEEE 754 SINGLE PRECISION ALU	//

module fpu(	out, nan_in, overflow, in_exact, zero, op_nan
			, clk_in, rst, opa_in, opb_in, mode_in, op_code);
output	[31:0]	out;
output			nan_in, overflow, in_exact, zero, op_nan;
input 	[31:0]	opa_in, opb_in;
input	[1:0]	op_code;
input	[1:0]	mode_in;
input			clk_in, rst;

wire 	[7:0] 	a_exponent	= opa_in[30:23];
wire 	[22:0] 	a_mantissa	= opa_in[22:0];
wire 	[7:0] 	b_exponent	= opb_in[30:23];
wire 	[22:0] 	b_mantissa	= opb_in[22:0];	
reg				o_sign;
reg		[7:0]  	o_exponent;
reg		[24:0] 	o_mantissa;

reg		[7:0] 	diff;
reg		[23:0] 	tmp_mantissa;
reg		[7:0] 	tmp_exponent;

assign out[31] = o_sign;
assign out[30:23] = o_exponent;
assign out[22:0] = o_mantissa[22:0];

//	Prepend a '1' to the fraction
assign a_sign = opa_in[31];
assign a_exponent[7:0] = (opa_in[30:23] == 0)?8'b00000001:opa_in[30:23];
assign a_mantissa[23:0] = (opa_in[30:23] == 0)?{1'b0, opa_in[22:0]}:{1'b1, opa_in[22:0]};

assign b_sign = opb_in[31];
assign b_exponent[7:0] = (opb_in[30:23] == 0)?8'b00000001:opb_in[30:23];
assign b_mantissa[23:0] = (opb_in[30:23] == 0)?{1'b0, opb_in[22:0]}:{1'b1, opb_in[22:0]};

//	Exception Unit
assign nan_in = (a_exponent == 255 && a_mantissa != 0)||
				(b_exponent == 255 && b_mantissa != 0);

`define ADD 2'b00;
`define SUB 2'b01;
`define MUL 2'b10;
`define DIV 2'b11;

function Adder; begin
	
		//	If a is NaN or b is zero return a
		if ((a_exp == 255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) begin
			o_sign = a_sign;
			o_exponent = a_exponent;
			o_mantissa = a_mantissa;
		end
		
		//	If b is NaN or a is zero return b
		else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) begin
			o_sign = b_sign;
			o_exponent = b_exponent;
			o_mantissa = b_mantissa;
		end
		
		//	If a or b is inf return inf
		else if ((a_exponent == 255) || (b_exponent == 255)) begin
			o_sign = a_sign ^ b_sign;
			o_exponent = 255;
			o_mantissa = 0;
		end
		
		//	Passed all corner cases
		else begin
			
			//	Equal exponents
			if(a_exponent == b_exponent) begin
				//	ADD
				if(a_sign == b_sign)begin
					o_exponent = a_exponent + 1;
					o_mantissa = (a_mantissa + b_mantissa) >> 1;
					o_sign = a_sign;
				end
				//	SUB
				else begin
					if(a_mantissa > b_mantissa) begin
						o_exponent = a_exponent;
						o_mantissa = a_mantissa - b_mantissa;
						o_sign = a_sign;
					end
					else begin
						o_exponent = a_exponent;
						o_mantissa = b_mantissa - a_mantissa;
						o_sign = b_sign;
					end
				end
			end
			
			//	Unequal exponents: A > B
			else if (a_exponent>b_exponent) begin
				o_exponent = a_exponent;
				o_sign = a_sign;
				diff = a_exponent - b_exponent;
				tmp_mantissa = a_mantissa >> diff;
				//	ADD
				if (a_sign == b_sign) begin
				  o_mantissa = a_mantissa + tmp_mantissa;
				//	SUB
				end else begin
					o_mantissa = a_mantissa - tmp_mantissa;
				end
			end
			
			//	Unequal exponents: B > A
			else if (b_exponent>a_exponent)	begin
				o_exponent = b_exponent;
				o_sign = b_sign;
				diff = b_exponent - a_exponent;
				tmp_mantissa = b_mantissa >> diff;
				//	ADD
				if (a_sign == b_sign)
					o_mantissa = b_mantissa + tmp_mantissa;
				//	SUB
				else
					o_mantissa = b_mantissa - tmp_mantissa;
			end
		end
end
endtask
function Addition_normaliser; begin
if( (o_mantissa[23] != 1) && (o_exponent != 0) ) begin
	if (o_mantissa[23:3] == 21'b000000000000000000001) begin
		o_exponent = o_exponent - 20;
		o_mantissa = o_mantissa << 20;
	end else if (o_mantissa[23:4] == 20'b00000000000000000001) begin
		o_exponent = o_exponent - 19;
		o_mantissa = o_mantissa << 19;
	end else if (o_mantissa[23:5] == 19'b0000000000000000001) begin
		o_exponent = o_exponent - 18;
		o_mantissa = o_mantissa << 18;
	end else if (o_mantissa[23:6] == 18'b000000000000000001) begin
		o_exponent = o_exponent - 17;
		o_mantissa = o_mantissa << 17;
	end else if (o_mantissa[23:7] == 17'b00000000000000001) begin
		o_exponent = o_exponent - 16;
		o_mantissa = o_mantissa << 16;
	end else if (o_mantissa[23:8] == 16'b0000000000000001) begin
		o_exponent = o_exponent - 15;
		o_mantissa = o_mantissa << 15;
	end else if (o_mantissa[23:9] == 15'b000000000000001) begin
		o_exponent = o_exponent - 14;
		o_mantissa = o_mantissa << 14;
	end else if (o_mantissa[23:10] == 14'b00000000000001) begin
		o_exponent = o_exponent - 13;
		o_mantissa = o_mantissa << 13;
	end else if (o_mantissa[23:11] == 13'b0000000000001) begin
		o_exponent = o_exponent - 12;
		o_mantissa = o_mantissa << 12;
	end else if (o_mantissa[23:12] == 12'b000000000001) begin
		o_exponent = o_exponent - 11;
		o_mantissa = o_mantissa << 11;
	end else if (o_mantissa[23:13] == 11'b00000000001) begin
		o_exponent = o_exponent - 10;
		o_mantissa = o_mantissa << 10;
	end else if (o_mantissa[23:14] == 10'b0000000001) begin
		o_exponent = o_exponent - 9;
		o_mantissa = o_mantissa << 9;
	end else if (o_mantissa[23:15] == 9'b000000001) begin
		o_exponent = o_exponent - 8;
		o_mantissa = o_mantissa << 8;
	end else if (o_mantissa[23:16] == 8'b00000001) begin
		o_exponent = o_exponent - 7;
		o_mantissa = o_mantissa << 7;
	end else if (o_mantissa[23:17] == 7'b0000001) begin
		o_exponent = o_exponent - 6;
		o_mantissa = o_mantissa << 6;
	end else if (o_mantissa[23:18] == 6'b000001) begin
		o_exponent = o_exponent - 5;
		o_mantissa = o_mantissa << 5;
	end else if (o_mantissa[23:19] == 5'b00001) begin
		o_exponent = o_exponent - 4;
		o_mantissa = o_mantissa << 4;
	end else if (o_mantissa[23:20] == 4'b0001) begin
		o_exponent = o_exponent - 3;
		o_mantissa = o_mantissa << 3;
	end else if (o_mantissa[23:21] == 3'b001) begin
		o_exponent = o_exponent - 2;
		o_mantissa = o_mantissa << 2;
	end else if (o_mantissa[23:22] == 2'b01) begin
		o_exponent = o_exponent - 1;
		o_mantissa = o_mantissa << 1;
	end
end
end
endtask

always @ (posedge clk_in) begin
	if(rst) begin
		o_sign = 1'bz;
		o_exp = 8'bz;
		o_mantissa = 23'bz;
	end
	else begin
		case(op_code)
		//	Adder
		`ADD: 
			Pre_Normalization(	opa_in, 
						opb_in, 
						clk_in, 
								
						pre_exponent, 
						pre_a_sign, 
						pre_a_mantissa, 
						pre_a_sign, 
						pre_b_mantissa
						);
			Adder(	pre_a_sign, 
				pre_a_mantissa,
				pre_b_sign,
				pre_b_mantissa,
				1'b1,
				clk_in,

				adder_sign,
				adder_mantissa
				);
			Post_Normalization(	mode_in,
						adder_sign,



						);
			end
		endcase
	end
end

always @ ( * )begin
	case(op_code)
	`ADD: begin
		
		end
	`SUB: begin
		end
	endcase
end
endmodule
