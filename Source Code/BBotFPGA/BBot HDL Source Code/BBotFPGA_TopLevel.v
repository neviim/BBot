`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:05:27 05/5/2013 
// Design Name: 
// Module Name:    BBotFPGA_TopLevel 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module BBotFPGA_TopLevel(

	input 	OSC_FPGA,
	
	input 	GPMC_AD12,	//SoftwareReset

	output 	LEDOutput0,
	output 	LEDOutput1,
	output 	LEDOutput2,
	output 	LEDOutput3,
	output 	LEDOutput4,
	output 	LEDOutput5,
	output 	LEDOutput6,
	output 	LEDOutput7,

	input 	Button0,
	input 	Button1,
	input 	Button2,
	input 	Button3,	//System Reset
	
	input 	DipSW0,
	input 	DipSW1,
	input 	DipSW2,
	input 	DipSW3,
	 
	//UART
	input 	SYS_TX,			//System_UART_TX - as in TX from the BBone
	output 	SYS_RX,			//System_UART_RX - as in RX to the BBone
	input 	GPMC_ADVN,		//UART_Mux_Select_0
	input 	GPMC_BE0N,		//UART_Mux_Select_1
	input		GPMC_AD13,		//UART_Mux_Select_2
	input 	PMOD4_3,			//Voice_UART_1_TX
	output 	PMOD4_4,			//Voice_UART_1_RX
	input 	PMOD4_7,			//UART_2_TX
	output 	PMOD4_8,			//UART_2_RX
	input 	PMOD4_9,			//UART_3_TX
	output 	PMOD4_10,		//UART_3_RX
	input 	PMOD3_1,			//XBee_UART_TX
	output 	PMOD3_2,			//XBee_UART_RX
	
	//SPI
	input 	SYS_SPI_SCK,	//SPI_Sck
	output	SYS_SPI_MISO,	//SPI_BiMo
	input		SYS_SPI_MOSI,	//SPI_BoMi
	input 	SYS_SPI_SS,		//SPI_Ss
	
	//Motors
	input 	PMOD3_8, 		//RC Rudd - Cam Pan 		
	input 	PMOD3_7, 		//RC Thro - Cam Tilt 	
	input 	PMOD3_4,   		//RC Elev - Motor L 		
	input 	PMOD3_3,   		//RC Aile - Motor R		
	output 	GPMC_AD11, 		//MotorL Signal PPM		
	output 	GPMC_AD10, 		//MotorR Signal PPM		
	output 	GPMC_CSN2, 		//Cam Tilt PPM				
	output 	GPMC_AD8, 		//Cam Pan PPM				
	
	//Encoders
	input 	PMOD3_9,
	input 	PMOD3_10,
	input 	GPMC_AD14,
	input 	GPMC_AD15,
	
	//Test outputs
	output	PMOD2_1,
	output 	PMOD2_2,
	output 	PMOD2_3
		
);


//-----------------------------------------------------------------------------------------
//	Variable Definitions
//-----------------------------------------------------------------------------------------
	parameter RC_ZeroPoint_Pulses = 75000;
	//percent * 250 = 25000 where 25000 50MHz pulses (.5ms) is the total range in one direction
	parameter RC_RangeMultiplier = 	250;
	
	reg[7:0] LED_reg;
	
	reg temp1, temp2, temp3;
	
	wire Reset_l;
	
	wire UART_Mux_Select_0, UART_Mux_Select_1, UART_Mux_Select_2;
	wire UART_1_TX, UART_1_RX;
	wire UART_2_TX, UART_2_RX;
	wire UART_3_TX, UART_3_RX;
	wire XBee_UART_TX, XBee_UART_RX;
	wire System_UART_TX, System_UART_RX;
	
	wire SPI_Sck, SPI_BiMo, SPI_BoMi, SPI_Ss;
	wire SPI_di_req_o, SPI_wren_i, SPI_wr_ack_o, SPI_do_valid_o;
	wire[31:0]SPI_di_i, SPI_do_o;
	reg [31:0]SPI_di_i_reg, SPI_do_o_reg;
	
	wire RC_MotorR_Aileron_In, RC_MotorL_Elevator_In, RC_CamPan_Rudder_In, RC_CamTilt_Throttle_In;
	wire MotorR_PPM_Out, MotorL_PPM_Out, CamPan_PPM_Out, CamTilt_PPM_Out;
	
	wire RC_MotorSignalSourceSelect;
	wire RC_MotorPulseGen_Left, RC_MotorPulseGen_Right;
	reg[7:0] LeftMotorSpeed_Percent, RightMotorSpeed_Percent;
	reg[31:0] LeftMotorSpeed_50MHzPulses, RightMotorSpeed_50MHzPulses;
	
	wire RC_CameraSignalSourceSelect;
	wire RC_CamPanPulseGen, RC_CamTiltPulseGen;
	reg[31:0] CameraPanPosition_Percent, CameraTiltPosition_Percent;
	reg[31:0] CameraPanPosition_50MHzPulses, CameraTiltPosition_50MHzPulses;
	
	wire Encoder_L_A_In, Encoder_L_B_In;
	wire Encoder_R_A_In, Encoder_R_B_In;
	
	reg [31:0] CurrentEncoderCount_Left_reg, CurrentEncoderCount_Right_reg;
	wire [31:0] CurrentEncoderCount_Left, CurrentEncoderCount_Right;
	wire Direction_Left, Direction_Right;
	
	reg [63:0] ClockEdgeCounter;
	reg [31:0] HBeatCounter;


//-----------------------------------------------------------------------------------------
//	Main Always Block
//-----------------------------------------------------------------------------------------
	always @(posedge OSC_FPGA)
	begin
		
		//Reset is active low
		if (Reset_l == 0)
		begin
		
			LED_reg[7:0] <= 8'h00;
			CurrentEncoderCount_Left_reg[31:0] <= 32'h80000000;	//Start at half way to avoid encoder roll over completely...
			CurrentEncoderCount_Right_reg[31:0] <= 32'h80000000;
			LeftMotorSpeed_Percent[7:0] <= 8'd0;
			RightMotorSpeed_Percent[7:0] <= 8'd0;
			CameraPanPosition_Percent[31:0] <= 32'd0;
			CameraTiltPosition_Percent[31:0] <= 32'd0;
			
			SPI_do_o_reg[31:0] <= 32'd0;
			//Data sent back to the beaglebone
			SPI_di_i_reg[31:0] <= 32'hDEADBEEF;
			
			//HBeat reaches 0 in 500ms when clock is running @ 50MHz
			HBeatCounter <= 32'd25000000;
			
		
		end
		else
		begin
		
			//Do this logic on every rising edge of the clock signal OSC_FPGA
			//Use LED bank for debug
			//Mode 0
			if (DipSW3 == 1'h0 && DipSW2 == 1'h0 && DipSW1 == 1'h0 && DipSW0 == 1'h0)
			begin
				CurrentEncoderCount_Left_reg[31:0] <= CurrentEncoderCount_Left[31:0];
				LED_reg[4:0] <= CurrentEncoderCount_Left_reg[11:7];
				LED_reg[5] <= Encoder_L_A_In;
				LED_reg[6] <= Encoder_L_B_In;
				LED_reg[7] <= 1'b1;
			end
			//Mode 1
			else if (DipSW3 == 1'h0 && DipSW2 == 1'h0 && DipSW1 == 1'h0 && DipSW0 == 1'h1)
			begin
				CurrentEncoderCount_Right_reg[31:0] <= CurrentEncoderCount_Right[31:0];
				LED_reg[4:0] <= CurrentEncoderCount_Right_reg[11:7];
				LED_reg[5] <= Encoder_R_A_In;
				LED_reg[6] <= Encoder_R_B_In;
				LED_reg[7] <= 1'b0;
			end
			//Mode 2
			else if (DipSW3 == 1'h0 && DipSW2 == 1'h0 && DipSW1 == 1'h1 && DipSW0 == 1'h0)
			begin
				LED_reg[2:0] <= {UART_Mux_Select_2, UART_Mux_Select_1, UART_Mux_Select_0};
				LED_reg[7:3] <= 5'h0;
			end
			
			//Show the hbeat if switches are set
			//Mode 7
			else if(DipSW3 == 1'h0 && DipSW2 == 1'h1 && DipSW1 == 1'h1 && DipSW0 == 1'h1)
			begin
				if (HBeatCounter == 32'h0)
				begin
					//Toggle HBeat
					LED_reg[7:0] <= ~LED_reg[7:0];
					HBeatCounter <= 32'd25000000;
				end
				else
				begin
					HBeatCounter <= HBeatCounter - 1;
				end				
			end
			
			//Mode 8
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h0 && DipSW1 == 1'h0 && DipSW0 == 1'h0)
			begin
				LED_reg[7:0] <= SPI_do_o_reg[7:0];
			end
			//Mode 9
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h0 && DipSW1 == 1'h0 && DipSW0 == 1'h1)
			begin				
				LED_reg[7:0] <= SPI_do_o_reg[15:8];
			end
			//Mode 10
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h0 && DipSW1 == 1'h1 && DipSW0 == 1'h0)
			begin				
				LED_reg[7:0] <= SPI_do_o_reg[23:16];
			end
			//Mode 11
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h0 && DipSW1 == 1'h1 && DipSW0 == 1'h1)
			begin				
				LED_reg[7:0] <= SPI_do_o_reg[31:24];
			end
			
			//Mode 12
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h1 && DipSW1 == 1'h0 && DipSW0 == 1'h0)
			begin
				LED_reg[7:0] <= RightMotorSpeed_50MHzPulses[7:0];
			end
			//Mode 13
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h1 && DipSW1 == 1'h0 && DipSW0 == 1'h1)
			begin				
				LED_reg[7:0] <= RightMotorSpeed_50MHzPulses[15:8];
			end
			//Mode 14
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h1 && DipSW1 == 1'h1 && DipSW0 == 1'h0)
			begin				
				LED_reg[7:0] <= RightMotorSpeed_50MHzPulses[23:16];
			end
			//Mode 15
			else if (DipSW3 == 1'h1 && DipSW2 == 1'h1 && DipSW1 == 1'h1 && DipSW0 == 1'h1)
			begin				
				LED_reg[7:0] <= RightMotorSpeed_50MHzPulses[31:24];
			end
			
		
			//temp1 <= 1'b0;
			//temp2 <= 1'b0;
			temp3 <= 1'b0;
			
			
			
			if(SPI_do_valid_o)
			begin
				//Grab the data out of the SPI_slave block
				//When it comes off the spi wire the bytes are in reverse order
				//Here is what it looks like on the wire:
				//
				//	CS -----\__________________________________________________/-----		
				//				MSB		 LSB 		MSB		 LSB		MSB		 LSB
				//				x x x x x x x     x x x x x x x     x x x x x x x 		..etc
				// 			BBotChar[0]  		BBotChar[1]  		BBotChar[3]
				//     		LeastSig										MostSig
				//				Byte												Byte
				//
				//And then SPI_do_o has the above bytes arranged as such:
				//								FPGA_MSByte						FPGA_LSByte
				//		SPI_do_o[31:0] = {BBotChar[0], BBotChar[1], BBotChar[2]};
				//
				//
				//So we need to swap the byte order so that the least significant 
				//byte of our DataBlock_TX struct in the C++ code correlates with 
				//SPI_do_o_reg[7:0]... not totally required but it makes it easier to
				//work with when routing the signals to FPGA peripherals	
				SPI_do_o_reg[7:0] <= SPI_do_o[31:24];
				SPI_do_o_reg[15:8] <= SPI_do_o[23:16];
				SPI_do_o_reg[23:16] <= SPI_do_o[15:8];
				SPI_do_o_reg[31:24] <= SPI_do_o[7:0];
				
				LeftMotorSpeed_Percent[7:0] <= 8'd50;
				RightMotorSpeed_Percent[7:0] <= SPI_do_o_reg[23:16];
				
			end
		

			//Convert speed percent set point to pulses for our 4 RC channels
			LeftMotorSpeed_50MHzPulses <= RC_ZeroPoint_Pulses + (LeftMotorSpeed_Percent * RC_RangeMultiplier);
			RightMotorSpeed_50MHzPulses <= RC_ZeroPoint_Pulses + (RightMotorSpeed_Percent * RC_RangeMultiplier);
			CameraPanPosition_50MHzPulses <= RC_ZeroPoint_Pulses + (CameraPanPosition_Percent * RC_RangeMultiplier);
			CameraTiltPosition_50MHzPulses <= RC_ZeroPoint_Pulses + (CameraTiltPosition_Percent * RC_RangeMultiplier);
			
			
			
			
			
		end
		
		
		
	end
	


//-----------------------------------------------------------------------------------------
//	Assignments
//-----------------------------------------------------------------------------------------
	
	//Reset input
	assign Reset_l = Button3 && GPMC_AD12;
	
	//System UART
	assign System_UART_TX = SYS_TX; 	//Here the direction seems odd but remember we're passing
	assign SYS_RX = System_UART_RX;  //tx and rx through the FPGA to the BBone												
	//UART Mux Selection
	assign UART_Mux_Select_0 = GPMC_ADVN;
	assign UART_Mux_Select_1 = GPMC_BE0N;
	assign UART_Mux_Select_2 = GPMC_AD13;
	//UART 1 signals
	assign Voice_UART_TX = PMOD4_3;
	assign PMOD4_4 = Voice_UART_RX;
	//UART 2 signals
	assign UART_2_TX = PMOD4_7;
	assign PMOD4_8 = UART_2_RX;
	//UART 3 signals
	assign UART_3_TX = PMOD4_9;
	assign PMOD4_10 = UART_3_RX;
	//RF Link UART signals
	assign XBee_UART_TX = PMOD3_1;
	assign PMOD3_2 = XBee_UART_RX;
	
	//SPI
	assign SPI_Sck = SYS_SPI_SCK;
	assign SYS_SPI_MISO = SPI_BiMo;
	assign SPI_BoMi = SYS_SPI_MOSI;
	assign SPI_Ss = SYS_SPI_SS;
	//Here we route the static data block signals to our subsystems
	//This data block is updated from the BBoneBlack on a time interval
	assign RC_MotorSignalSourceSelect = SPI_do_o_reg[0];
	assign RC_CameraSignalSourceSelect = SPI_do_o_reg[1];
	//Data to be sent back to the BeagleBone Black via our spi_slave block
	assign SPI_di_i[31:0] = SPI_di_i_reg[31:0];
	
	//RC Signals
	assign RC_CamPan_Rudder_In = PMOD3_8;
	assign RC_CamTilt_Throttle_In = PMOD3_7;
	assign RC_MotorL_Elevator_In = PMOD3_4;
	assign RC_MotorR_Aileron_In = PMOD3_3;
	assign GPMC_AD11 = MotorR_PPM_Out;
	assign GPMC_AD10 = MotorL_PPM_Out;
	assign GPMC_CSN2 = CamTilt_PPM_Out;
	assign GPMC_AD8 = CamPan_PPM_Out;
	
	//assign RC_MotorSignalSourceSelect = GPMC_AD12;
	//assign RC_CameraSignalSourceSelect = GPMC_CLK;
	assign MotorL_PPM_Out = RC_MotorSignalSourceSelect ? RC_MotorPulseGen_Left : RC_MotorL_Elevator_In;
	assign MotorR_PPM_Out = RC_MotorSignalSourceSelect ? RC_MotorPulseGen_Right : RC_MotorR_Aileron_In;
	assign CamPan_PPM_Out = RC_CameraSignalSourceSelect ? RC_CamPanPulseGen : RC_CamPan_Rudder_In;
	assign CamTilt_PPM_Out = RC_CameraSignalSourceSelect ? RC_CamTiltPulseGen : RC_CamTilt_Throttle_In;
		
	//Encoder inputs
	assign Encoder_L_A_In = PMOD3_9;
	assign Encoder_L_B_In = PMOD3_10;
	assign Encoder_R_A_In = GPMC_AD14;
	assign Encoder_R_B_In = GPMC_AD15;
	
	//LEDs
	assign LEDOutput0 = LED_reg[0];
	assign LEDOutput1 = LED_reg[1];
	assign LEDOutput2 = LED_reg[2];
	assign LEDOutput3 = LED_reg[3];
	assign LEDOutput4 = LED_reg[4];
	assign LEDOutput5 = LED_reg[5];
	assign LEDOutput6 = LED_reg[6];
	assign LEDOutput7 = LED_reg[7];
	
	//test
	assign PMOD2_1 = temp1;
	assign PMOD2_2 = temp2;
	assign PMOD2_3 = temp3;


//-----------------------------------------------------------------------------------------
//	Sub-Modules
//-----------------------------------------------------------------------------------------
	//UARTSmartMux instance
	//Here by default selectRoute(000) we want the XBee link signals to route to the 
	//FPGA System UART which ends up at the BBone.  But we need to correctly cross tx and rx wires too!
	//Se we need the smart mux - see its definition
	BBot_UartSmartMux UartSmartMux_1(
		.clock(OSC_FPGA),
		.reset_l(Reset_l),
		.selectRoute({UART_Mux_Select_2, UART_Mux_Select_1, UART_Mux_Select_0}),
		.tx3_in( ),
		.tx2_in( Voice_UART_TX ),
		.tx1_in( System_UART_TX ),
		.tx0_in( XBee_UART_TX ),		
		.rx3_out(  ),
		.rx2_out( Voice_UART_RX ),
		.rx1_out( System_UART_RX ),
		.rx0_out( XBee_UART_RX )
	);
	
	//OpenCores Slave Device
	spi_slave(
		.clk_i(OSC_FPGA),
		.spi_ssel_i(SPI_Ss),
		.spi_sck_i(SPI_Sck),
		.spi_mosi_i(SPI_BoMi),
		.spi_miso_o(SPI_BiMo),
		.di_req_o(SPI_di_req_o),
		.di_i(SPI_di_i),
		.wren_i(SPI_wren_i),
		.wr_ack_o(SPI_ack_o),
		.do_valid_o(SPI_do_valid_o),
		.do_o(SPI_do_o),
		.do_transfer_o(),
		.wren_o(),
		.rx_bit_next_o(),
		.state_dbg_o(),
		.sh_reg_dbg_o()
	);
		
	
	//Count the left motor's encoder
	BBot_SimpleQuadratureCounter QuadratureCounter_LeftMotor(
		.clock(OSC_FPGA),
		.reset_l(Reset_l),
		.A(Encoder_L_A_In),
		.B(Encoder_L_B_In),
		.CurrentCount(CurrentEncoderCount_Left),
		.Direction(Direction_Left)
	);
		
	//Count the right motor's encoder
	BBot_SimpleQuadratureCounter QuadratureCounter_RightMotor(
		.clock(OSC_FPGA),
		.reset_l(Reset_l),
		.A(Encoder_R_A_In),
		.B(Encoder_R_B_In),
		.CurrentCount(CurrentEncoderCount_Right),
		.Direction(Direction_Right)
	);	
	
	//Signal Generator for left motor
	//Here the period is 1.1E6 clocks because our oscillator is at 50MHz
	//This means the period is 22ms - required by motor driver chips
	//Overall pulse on time is 1.5ms +/- .5ms 
	//At 50MHz, 1.5ms is 75000 pulses and the range is then .5ms = 25000 pulses
	gh_Pulse_Generator LeftMotorSignalGen(
		.clk(OSC_FPGA),
		.rst(1'h0),
		.Period(32'd1100000),
		.Pulse_Width(32'd90000),
		//.ENABLE(RC_MotorSignalSourceSelect),
		.ENABLE(1'h1),
		.Pulse(RC_MotorPulseGen_Left)
	);
	
	//Signal Generator for right motor
	gh_Pulse_Generator RightMotorSignalGen(
		.clk(OSC_FPGA),
		//.rst(~Reset_l),
		.rst(1'h0),
		.Period(32'd1100000),
		.Pulse_Width(RightMotorSpeed_50MHzPulses),
		//.ENABLE(RC_MotorSignalSourceSelect),
		.ENABLE(1'h1),
		.Pulse(RC_MotorPulseGen_Right)
	);
	
	//Camera Pan Signal Gen
	gh_Pulse_Generator CameraPanSignalGen(
		.clk(OSC_FPGA),
		.rst(~Reset_l),
		.Period(32'd1100000),
		.Pulse_Width(CameraPanPosition_50MHzPulses),
		.ENABLE(RC_CameraSignalSourceSelect),
		.Pulse(RC_CamPanPulseGen)
	);
	
	//Camera Tilt Signal Gen
	gh_Pulse_Generator CameraTiltSignalGen(
		.clk(OSC_FPGA),
		.rst(~Reset_l),
		.Period(32'd1100000),
		.Pulse_Width(CameraTiltPosition_50MHzPulses),
		.ENABLE(RC_CameraSignalSourceSelect),
		.Pulse(RC_CamTiltPulseGen)
	);
	
endmodule