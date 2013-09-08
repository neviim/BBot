/*
 * BBoneConstants.h
 *
 *  Created on: Jul 4, 2013
 *      Author: Andy Gikling
 *
 *  This file contains constants for the BeagleBone's hardware
 */
#include <stdio.h>
#include <string>

#ifndef BBONECONSTANTS_H_
#define BBONECONSTANTS_H_

#define PINMUX_PATH_K3Dot2 "/sys/kernel/debug/omap_mux"
#define PATH_TO_LISTEN_THREAD_DEBUG_FILE "/home/root/Debug_ListenThread.txt"
#define PATH_TO_VOICE_THREAD_DEBUG_FILE "/home/root/Debug_VoiceThread.txt"
#define PATH_TO_LEGS_THREAD_DEBUG_FILE "/home/root/Debug_LegsThread.txt"
#define PATH_TO_MARK1FPGA_THREAD_DEBUG_FILE "/home/root/Debug_Mark1FPGAThread.txt"
#define PATH_TO_DEBUG_FILE_SIMLINK "/home/root/images/text.txt"

//UART Settings
#define BAUDRATE_UART1 B115200
#define BAUDRATE_UART4 B9600
#define MAX_SERIAL_BUFFER_SIZE 1024
/* change this definition for the correct port */
#define MODEMDEVICE_UART1 "/dev/ttyO1"
#define MODEMDEVICE_UART4 "/dev/ttyO4"
#define _POSIX_SOURCE 1 /* POSIX compliant source */

//GPIO and pin mux constants
//#define UART1_RXD_GPIO_PIN_NUM 			14		//P9_24 - Don't need - setup in the Overlay
//#define UART1_TXD_GPIO_PIN_NUM 			15		//P9_26 - Don't need - setup in the Overlay
#define UART_SELECT_0_GPIO_PIN_NUM 		66		//P8_07
#define UART_SELECT_1_GPIO_PIN_NUM 		69		//P8_09
#define UART_SELECT_2_GPIO_PIN_NUM 		45		//P8_11
#define MARK1_SOFTWARE_RESET_N			44		//P8_12


//Enable Trace statements
//If trace is set to true this software will be verbose
#define TRACE 1

#define FALSE 0
#define TRUE 1

//SPI Settings
#define SPI_PATH_TO_SPI_DEVICE 				"/dev/spidev1.0"
#define SPI_BLOCK_TRANSFER_NUM_BYTES 		4
#define SPI_BITS_PER_WORD 					8
#define SPI_BIT_RATE_HZ						4000000
#define SPI_MARK1_DATABLOCK_UPDATE_RATE_US 	1000000
//Struct that represents the 128bit data block that is passed to and from the
//FPGA on an interval in the Mark1FPGA thread.
struct Mark1_DataBlock_TX{
	int8_t Control;		//where	//bool MotorSignalSourceSelect_ctrl;
								//bool CamerPanTiltSignalSourceSelect_ctrl;
								//bool Ctrl2;
								//bool Ctrl3;
								//bool Ctrl4;
								//bool Ctrl5;
								//bool Ctrl6;
								//bool Ctrl7;
	int8_t Servo0_Position;		//Left Motor Speed
	int8_t Servo1_Position;		//Right Motor Speed
	int8_t Servo2_Position;		//Pan Position
	int8_t Servo3_Position;		//Tilt Position


};

struct Mark1_DataBlock_RX{
	int32_t SPIExchangeInterval;
	int32_t EncoderLeft_Count;
	int32_t EncoderRight_Count;
	int8_t GPIO;
};


std::string const VOICE_FUNC_0("V00");
std::string const VOICE_FUNC_1("V01");
std::string const VOICE_FUNC_2("V02");
std::string const VOICE_FUNC_3("V03");
std::string const VOICE_FUNC_4("V04");
std::string const VOICE_FUNC_5("V05");

std::string const LEGS_FUNC_0("L00");
std::string const LEGS_FUNC_1("L01");
std::string const LEGS_FUNC_2("L02");

std::string const CUSTOM_FUNC_0("C00");
std::string const CUSTOM_FUNC_1("C01");


#endif /* BBONECONSTANTS_H_ */