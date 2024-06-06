module convert(IN_LINE, IN_CP, IN_DATA, OUT_CP, OUT_PX);
	input IN_LINE;
	input IN_CP;
	input[7:0] IN_DATA; //7~0 <-> D0~D7 <-> G3~R1
	
	output OUT_CP;
	reg FF_CP;
	output[3:0] OUT_PX; //3:0 <-> pixel4~pixel1
	reg[3:0] OUT_PX;
	
	reg[1:0] CNT_CP;
	
	reg[1:0] RGB_REM1;
	reg PX_REM;
	reg RGB_REM2;
	
	reg [3:0] CNT_PX; //loop 0~8
	
	// IN_DATA loop: RGBRGBRG BRGBRGBR GBRGBRGB
	always @(negedge IN_CP or posedge IN_LINE) begin
		if (IN_LINE) begin
			CNT_CP <= 2'b00;
			RGB_REM1 <= 2'b00;
			PX_REM <= 0;
			RGB_REM2 <= 0;
			OUT_PX <= 4'b0000;
			if (CNT_PX >= 4'D9) begin
				CNT_PX <= 4'D0;
			end
		end else begin
			case(CNT_CP)
			2'b00: begin
				OUT_PX[0] <= rgb_to_bool(IN_DATA[0], IN_DATA[1], IN_DATA[2], CNT_PX);
				OUT_PX[1] <= rgb_to_bool(IN_DATA[3], IN_DATA[4], IN_DATA[5], cnt_px_inc(CNT_PX, 4'D1));
				RGB_REM1 <= IN_DATA[7:6];
				CNT_PX <= cnt_px_inc(CNT_PX, 2'D2);
			end
			2'b01: begin
				OUT_PX[2] <= rgb_to_bool(RGB_REM1[0], RGB_REM1[1], IN_DATA[0], CNT_PX);
				OUT_PX[3] <= rgb_to_bool(IN_DATA[1], IN_DATA[2], IN_DATA[3], cnt_px_inc(CNT_PX, 4'D1));
				PX_REM    <= rgb_to_bool(IN_DATA[4], IN_DATA[5], IN_DATA[6], cnt_px_inc(CNT_PX, 4'D2));
				RGB_REM2 <= IN_DATA[7];
				FF_CP <= !FF_CP;
				CNT_PX <= cnt_px_inc(CNT_PX, 2'D3);
			end
			2'b10: begin
				OUT_PX[0] <= PX_REM;
				OUT_PX[1] <= rgb_to_bool(RGB_REM2, IN_DATA[0], IN_DATA[1], CNT_PX);
				OUT_PX[2] <= rgb_to_bool(IN_DATA[2], IN_DATA[3], IN_DATA[4], cnt_px_inc(CNT_PX, 4'D1));
				OUT_PX[3] <= rgb_to_bool(IN_DATA[5], IN_DATA[6], IN_DATA[7], cnt_px_inc(CNT_PX, 4'D2));
				FF_CP <= !FF_CP;
				CNT_PX <= cnt_px_inc(CNT_PX, 2'D3);
			end
			endcase
			
			if (CNT_CP == 2'b10) begin
				CNT_CP <= 2'b00;
			end else begin
				CNT_CP <= CNT_CP + 2'b01;
			end
		end
	end

	// 320*240 = 76800
	// 76800 mod 9 = 3         .. 9 - 3 = 6
	// (76800 - 6) mod 9 = 6   .. 9 - 6 = 3
	// (76800 - 3) mod 9 = 0
	// frame 1: RGBGBRBRG...
	// frame 2: GBRBRGRGB...
	// frame 3: BRGRGBGBR...
	function rgb_to_bool;
		input IN_R, IN_G, IN_B;
		input[3:0] IN_CNT_PX; //0~8
		// RGB GBR BRG
		// 012 345 678
		rgb_to_bool = 
			(IN_R && (IN_CNT_PX == 4'D0 || IN_CNT_PX == 4'D5 || IN_CNT_PX == 4'D7)) ||
			(IN_G && (IN_CNT_PX == 4'D1 || IN_CNT_PX == 4'D3 || IN_CNT_PX == 4'D8)) ||
			(IN_B && (IN_CNT_PX == 4'D2 || IN_CNT_PX == 4'D4 || IN_CNT_PX == 4'D6));
	endfunction
	
	function[3:0] cnt_px_inc;
		input[3:0] CNT_PX;
		input[1:0] IN_INC;
		if (CNT_PX + IN_INC >= 4'D9) begin
			cnt_px_inc = CNT_PX + IN_INC - 4'D9;
		end else begin
			cnt_px_inc = CNT_PX + IN_INC;
		end
	endfunction

	// generate CP pulse when toggling FF_CP
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT1;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT2;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT3;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT4;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT5;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT6;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT7;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT8;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT9;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT10;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT11;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT12;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT13;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT14;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT15;
	(*KEEP = "TRUE"*)wire WIRE_CP_NOT16;
	not DELAY1(WIRE_CP_NOT1, FF_CP);
	not DELAY2(WIRE_CP_NOT2, WIRE_CP_NOT1);
	not DELAY3(WIRE_CP_NOT3, WIRE_CP_NOT2);
	not DELAY4(WIRE_CP_NOT4, WIRE_CP_NOT3);
	not DELAY5(WIRE_CP_NOT5, WIRE_CP_NOT4);
	not DELAY6(WIRE_CP_NOT6, WIRE_CP_NOT5);
	not DELAY7(WIRE_CP_NOT7, WIRE_CP_NOT6);
	not DELAY8(WIRE_CP_NOT8, WIRE_CP_NOT7);
	not DELAY9(WIRE_CP_NOT9, WIRE_CP_NOT8);
	not DELAY10(WIRE_CP_NOT10, WIRE_CP_NOT9);
	not DELAY11(WIRE_CP_NOT11, WIRE_CP_NOT10);
	not DELAY12(WIRE_CP_NOT12, WIRE_CP_NOT11);
	not DELAY13(WIRE_CP_NOT13, WIRE_CP_NOT12);
	not DELAY14(WIRE_CP_NOT14, WIRE_CP_NOT13);
	not DELAY15(WIRE_CP_NOT15, WIRE_CP_NOT14);
	not DELAY16(WIRE_CP_NOT16, WIRE_CP_NOT15);
	assign OUT_CP = (FF_CP != WIRE_CP_NOT16);
endmodule
