//	*****************************	//
//	IEEE 754 SINGLE PRECISION ALU	//
//	*****************************	//

module fpu(	out, nan_in, overflow, in_exact, zero, op_nan
			, clk_in, rst, opa_in, opb_in, mode_in, op_code)
output	[31:0]	out;
output			nan_in, overflow, in_exact, zero, op_nan;
input 	[31:0]	opa_in, opb_in;
input	[4:0]	op_code;
input	[1:0]	mode_in;
input	clk_in, rst;

wire 	[7:0] 	a_exp	= opa_in[30:23];
wire 	[22:0] 	a_frac	= opa_in[22:0];
wire 	[7:0] 	b_exp	= opb_in[30:23];
wire 	[22:0] 	b_frac	= opb_in[22:0];	
reg        o_sign;
reg [7:0]  o_exp;
reg [24:0] o_frac;


reg [31:0] adder_a_in;
reg [31:0] adder_b_in;
wire [31:0] adder_out;

assign out[31] = o_sign;
assign out[30:23] = o_exp;
assign out[22:0] = o_mantissa[22:0];

//	Prepend a '1' to the fraction
assign a_sign = opa_in[31];
assign a_exponent[7:0] = (opa_in[30:23] == 0)?8'b00000001:opa_in[30:23];
assign a_mantissa[23:0] = (opa_in[30:23] == 0)?{1'b0, opa_in[22:0]}:{1'b1, opa_in[22:0]};

assign b_sign = opb_in[31];
assign b_exp[7:0] = (opb_in[30:23] == 0)?8'b00000001:opb_in[30:23];
assign b_frac[23:0] = (opb_in[30:23] == 0)?{1'b0, opb_in[22:0]}:{1'b1, opb_in[22:0]};

//	Exception Unit
assign nan_in = (a_exponent == 255 && a_mantissa != 0)||
				(b_exponent == 255 && b_mantissa != 0);
assign overflow = ;

`define ADD 2'b00;
`define SUB 2'b01;
/*
assign DIV = (op_code == 2'b10);
assign MUL = (op_code == 2'b11);*/

always @ (posedge clk_in) begin
	if(rst) begin
		o_sign = 1'bz;
		o_exp = 8'bz;
		o_mantissa = 23'bz;
	end
	else begin
		case(op_code)
		
		//	Adder
		`ADD: begin
		
			//	Addition_normaliser
			if (i_m[23:3] == 21'b000000000000000000001) begin
				o_e = i_e - 20;
				o_m = i_m << 20;
			end else if (i_m[23:4] == 20'b00000000000000000001) begin
				o_e = i_e - 19;
				o_m = i_m << 19;
			end else if (i_m[23:5] == 19'b0000000000000000001) begin
				o_e = i_e - 18;
				o_m = i_m << 18;
			end else if (i_m[23:6] == 18'b000000000000000001) begin
				o_e = i_e - 17;
				o_m = i_m << 17;
			end else if (i_m[23:7] == 17'b00000000000000001) begin
				o_e = i_e - 16;
				o_m = i_m << 16;
			end else if (i_m[23:8] == 16'b0000000000000001) begin
				o_e = i_e - 15;
				o_m = i_m << 15;
			end else if (i_m[23:9] == 15'b000000000000001) begin
				o_e = i_e - 14;
				o_m = i_m << 14;
			end else if (i_m[23:10] == 14'b00000000000001) begin
				o_e = i_e - 13;
				o_m = i_m << 13;
			end else if (i_m[23:11] == 13'b0000000000001) begin
				o_e = i_e - 12;
				o_m = i_m << 12;
			end else if (i_m[23:12] == 12'b000000000001) begin
				o_e = i_e - 11;
				o_m = i_m << 11;
			end else if (i_m[23:13] == 11'b00000000001) begin
				o_e = i_e - 10;
				o_m = i_m << 10;
			end else if (i_m[23:14] == 10'b0000000001) begin
				o_e = i_e - 9;
				o_m = i_m << 9;
			end else if (i_m[23:15] == 9'b000000001) begin
				o_e = i_e - 8;
				o_m = i_m << 8;
			end else if (i_m[23:16] == 8'b00000001) begin
				o_e = i_e - 7;
				o_m = i_m << 7;
			end else if (i_m[23:17] == 7'b0000001) begin
				o_e = i_e - 6;
				o_m = i_m << 6;
			end else if (i_m[23:18] == 6'b000001) begin
				o_e = i_e - 5;
				o_m = i_m << 5;
			end else if (i_m[23:19] == 5'b00001) begin
				o_e = i_e - 4;
				o_m = i_m << 4;
			end else if (i_m[23:20] == 4'b0001) begin
				o_e = i_e - 3;
				o_m = i_m << 3;
			end else if (i_m[23:21] == 3'b001) begin
				o_e = i_e - 2;
				o_m = i_m << 2;
			end else if (i_m[23:22] == 2'b01) begin
				o_e = i_e - 1;
				o_m = i_m << 1;
			end
			
			if (a_exponent == b_exponent) begin // Equal exponents
				o_exponent = a_exponent;
				if (a_sign == b_sign) begin // Equal signs = add
					o_mantissa = a_mantissa + b_mantissa;
					//Signify to shift
					o_mantissa[24] = 1;
					o_sign = a_sign;
				end
				else begin // Opposite signs = subtract
					if(a_mantissa > b_mantissa) begin
						o_mantissa = a_mantissa - b_mantissa;
						o_sign = a_sign;
					end else begin
						o_mantissa = b_mantissa - a_mantissa;
						o_sign = b_sign;
					end
				end
			end else begin //Unequal exponents
				if (a_exponent > b_exponent) begin // A is bigger
					o_exponent = a_exponent;
					o_sign = a_sign;
					diff = a_exponent - b_exponent;
					tmp_mantissa = b_mantissa >> diff;
					if (a_sign == b_sign)
						o_mantissa = a_mantissa + tmp_mantissa;
					else
						o_mantissa = a_mantissa - tmp_mantissa;
				end
				else if (a_exponent < b_exponent) begin // B is bigger
					o_exponent = b_exponent;
					o_sign = b_sign;
					diff = b_exponent - a_exponent;
					tmp_mantissa = a_mantissa >> diff;
					if (a_sign == b_sign) begin
						o_mantissa = b_mantissa + tmp_mantissa;
				end
				else begin
					o_mantissa = b_mantissa - tmp_mantissa;
				end
			end
			if(o_mantissa[24] == 1) begin
			  o_exponent = o_exponent + 1;
			  o_mantissa = o_mantissa >> 1;
			end else if((o_mantissa[23] != 1) && (o_exponent != 0)) begin
			  i_e = o_exponent;
			  i_m = o_mantissa;
			  o_exponent = o_e;
			  o_mantissa = o_m;
			end
		end
	endcase
end

always @ ( * )begin
	case(op_code)
	`ADD: begin
		a_sign = opa_in[31];
		if(opa_in[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, opa_in[22:0]};
		end else begin
			a_exponent = opa_in[30:23];
			a_mantissa = {1'b1, opa_in[22:0]};
		end
		b_sign = opb_in[31];
		if(opb_in[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, opb_in[22:0]};
		end else begin
			b_exponent = opb_in[30:23];
			b_mantissa = {1'b1, opb_in[22:0]};
		end
		//If a is NaN or b is zero return a
		if ((a_exp == 255 && a_frac != 0) || (b_exp == 0) && (b_mantissa == 0)) begin
			o_sign = a_sign;
			o_exponent = a_exponent;
			o_mantissa = a_mantissa;
		//If b is NaN or a is zero return b
		end else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) begin
			o_sign = b_sign;
			o_exponent = b_exponent;
			o_mantissa = b_mantissa;
		//if a or b is inf return inf
		end else if ((a_exponent == 255) || (b_exponent == 255)) begin
			o_sign = a_sign ^ b_sign;
			o_exponent = 255;
			o_mantissa = 0;
		end else begin // Passed all corner cases
			adder_a_in = A;
			adder_b_in = B;
			o_sign = adder_out[31];
			o_exponent = adder_out[30:23];
			o_mantissa = adder_out[22:0];
		end
	`SUB: begin
		end
	
	endcase
end
endmodule

module adder(a, b, out)
input  [31:0] a, b;
output [31:0] out;

wire [31:0] out;
reg a_sign;
reg [7:0] a_exponent;
reg [23:0] a_mantissa;
reg b_sign;
reg [7:0] b_exponent;
reg [23:0] b_mantissa;

reg o_sign;
reg [7:0] o_exponent;
reg [24:0] o_mantissa;

reg [7:0] diff;
reg [23:0] tmp_mantissa;
reg [7:0] tmp_exponent;

reg  [7:0] i_e;
reg  [24:0] i_m;
wire [7:0] o_e;
wire [24:0] o_m;

/*
addition_normaliser norm1
(
.in_e(i_e),
.in_m(i_m),
.out_e(o_e),
.out_m(o_m)
);*/

endmodule
