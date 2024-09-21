module convert(IN_LINE, IN_CP, IN_DATA, OUT_CP, OUT_PX);
	input IN_LINE;
	input IN_CP;
	input[7:0] IN_DATA; //7~0 <-> D0~D7 <-> G3~R1
	
	output OUT_CP;
	reg FF_CP;
	output[3:0] OUT_PX; //3:0 <-> pixel4~pixel1
	reg[3:0] OUT_PX = 4'b0000;
	
	reg[1:0] CNT_CP;
	
	reg[1:0] RGB_REM1;
	reg[2:0] PX_REM;
	reg RGB_REM2;
	
	reg[11:0] RGB_CH = 12'b010100100001;
	
	function rgb_to_bool;
		input IN_R, IN_G, IN_B;
		input[1:0] IN_CNT_PX; //0~3
		input[11:0] RGB_CH;
		rgb_to_bool = 
			(IN_R && RGB_CH[(4'D3)*IN_CNT_PX + 4'D0]) ||
			(IN_G && RGB_CH[(4'D3)*IN_CNT_PX + 4'D1]) ||
			(IN_B && RGB_CH[(4'D3)*IN_CNT_PX + 4'D2]);
	endfunction

	// TODO: implement better pseudo random for a better CPLD
	always @(posedge OUT_CP) begin
		RGB_CH[0] <= RGB_CH[11] ^ RGB_CH[7];
		RGB_CH[1] <= RGB_CH[0] ^ RGB_CH[9];
		RGB_CH[2] <= RGB_CH[1] ^ RGB_CH[3];
		RGB_CH[3] <= RGB_CH[2] ^ RGB_CH[6];
		RGB_CH[4] <= RGB_CH[3] ^ RGB_CH[1];
		RGB_CH[5] <= RGB_CH[4] ^ RGB_CH[5];
		RGB_CH[6] <= RGB_CH[5] ^ RGB_CH[8];
		RGB_CH[7] <= RGB_CH[6] ^ RGB_CH[10];
		RGB_CH[8] <= RGB_CH[7] ^ RGB_CH[4];
		RGB_CH[9] <= RGB_CH[8] ^ RGB_CH[1];
		RGB_CH[10] <= RGB_CH[9] ^ RGB_CH[2];
		RGB_CH[11] <= RGB_CH[10] ^ RGB_CH[11];
	end

	// IN_DATA loop: RGBRGBRG BRGBRGBR GBRGBRGB
	always @(negedge IN_CP or posedge IN_LINE) begin
		if (IN_LINE) begin
			CNT_CP <= 2'b00;
			RGB_REM1 <= 2'b00;
			PX_REM <= 3'b000;
			RGB_REM2 <= 1'b0;
			OUT_PX <= 4'b0000;
		end else begin
			case (CNT_CP)
			2'b00: begin
				OUT_PX[0] <= rgb_to_bool(IN_DATA[0], IN_DATA[1], IN_DATA[2], 2'D0, RGB_CH);
				OUT_PX[1] <= rgb_to_bool(IN_DATA[3], IN_DATA[4], IN_DATA[5], 2'D1, RGB_CH);
				RGB_REM1 <= IN_DATA[7:6];
			end
			2'b01: begin
				OUT_PX[2] <= rgb_to_bool(RGB_REM1[0], RGB_REM1[1], IN_DATA[0], 2'D2, RGB_CH);
				OUT_PX[3] <= rgb_to_bool(IN_DATA[1], IN_DATA[2], IN_DATA[3], 2'D3, RGB_CH);
				PX_REM <= IN_DATA[6:4];
				RGB_REM2 <= IN_DATA[7];
				FF_CP <= !FF_CP;
			end
			2'b10: begin
				OUT_PX[0] <= rgb_to_bool(PX_REM[0], PX_REM[1], PX_REM[2], 2'D0, RGB_CH);
				OUT_PX[1] <= rgb_to_bool(RGB_REM2, IN_DATA[0], IN_DATA[1], 2'D1, RGB_CH);
				OUT_PX[2] <= rgb_to_bool(IN_DATA[2], IN_DATA[3], IN_DATA[4], 2'D2, RGB_CH);
				OUT_PX[3] <= rgb_to_bool(IN_DATA[5], IN_DATA[6], IN_DATA[7], 2'D3, RGB_CH);
				FF_CP <= !FF_CP;
			end
			endcase
			
			if (CNT_CP == 2'b10) begin
				CNT_CP <= 2'b00;
			end else begin
				CNT_CP <= CNT_CP + 2'b01;
			end
		end
	end

	// generate CP pulse when toggling FF_CP
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT1;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT2;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT3;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT4;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT5;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT6;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT7;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT8;
	not DELAY1(WIRE_CP_NOT1, FF_CP);
	not DELAY2(WIRE_CP_NOT2, WIRE_CP_NOT1);
	not DELAY3(WIRE_CP_NOT3, WIRE_CP_NOT2);
	not DELAY4(WIRE_CP_NOT4, WIRE_CP_NOT3);
	not DELAY5(WIRE_CP_NOT5, WIRE_CP_NOT4);
	not DELAY6(WIRE_CP_NOT6, WIRE_CP_NOT5);
	not DELAY7(WIRE_CP_NOT7, WIRE_CP_NOT6);
	not DELAY8(WIRE_CP_NOT8, WIRE_CP_NOT7);
	assign OUT_CP = (FF_CP != WIRE_CP_NOT8);
endmodule
