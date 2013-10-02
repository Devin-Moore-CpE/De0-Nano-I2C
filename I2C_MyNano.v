/********************************************************************
As of now this program can either read or write to a specified address
in the onboard EEPROM(24LC02B) using the I2C protocol. The number that SD_COUNTER
goes up to needs to be changed, and the assignments at the bottom of the file 
need to switched when switching from reading and writing. 
********************************************************************/


module I2C_MyNano(

//This is the system clock that comes in at 50mhz//
	CLOCK_50,
///////////////////////////////////////////////////

//This is a register that is used to show the data that was read from the EEPROM in binary.//
	LED,
/////////////////////////////////////////////////////////////////////////////////////////////

//This is an input from both of the buttons on board the De0-Nano//
	KEY,
///////////////////////////////////////////////////////////////////

//This is used to keep track of the position of the switch #1 on the De0-Nano board.//
//Flip it to the left for writing, and the right for reading.
	SW,
//////////////////////////////////////////////////////////////////////////////////////

//I2C Clock line, goes to the EEPROM right now//
	I2C_SCL,
////////////////////////////////////////////////

//I2C Data Line, goes to the EEPROM rigth now//
	I2C_SDA,
///////////////////////////////////////////////

//9 bit register that increments every time the 50mhz clock rises. This is used to step
//down the speed for the I2C. Really rough right now, we can make it more efficient im sure.//
	COUNT,
//////////////////////////////////////////////////////////////////////////////////////////////

//This is keeping track of the rudementary states. These will need to be lumped together using
//a multibit flag register eventually. 
	SD_COUNTER

);




input CLOCK_50;

output [7:0]  LED;

input [1:0] KEY;

//really doesnt need to be 4 bits... but im to lazy to change it.. and maybe we need more switches?//
input [3:0] 	SW;

//////////////////This is for the EEPROM's I2C connections/////////
output   I2C_SCL;
inout   	I2C_SDA;

//////////////////Keep track of clocks
output	[5:0] 	SD_COUNTER;
output  	[9:0]		COUNT;

//////////////////////Reg/Wire Declarations////////////////////
wire		reset_n;

reg 					SCL_CTRL;				//This is used for the clock. ----TEST!!!!!!
reg		[7:0]		DATAIN;					//This is where the data is stored when reading a byte
reg					GO;						//This signals the operation to start
reg		[6:0]		SD_COUNTER;
reg					SDI;						//place holder for I2C_SDA
reg					SCL;						//Place holder for I2C_SCL during start/stop
reg		[9:0]		COUNT;
reg 		[7:0] 	LEDOUT;					//I think I stopped using this? again too lazy right now to check.


//////////////Structural Coding///////////

assign 	reset_n = KEY[0];

//////////////The Clock values will need to be changed as previously mentioned//////////
always @ (posedge CLOCK_50) COUNT <= COUNT +1;


/////////////This just takes care of our "start operation" button/////////////////
always @ (posedge COUNT[9] or negedge reset_n)
begin
	if (!reset_n)
		GO <= 0;
	else	
		if(!KEY[1])
			GO <=1;
end

/////////////Testing Switch one to toggle read/write... not used any more I think...////////
always @ (posedge COUNT[9])
begin
	if(SW[0])
		LEDOUT <= 8'b01010101;
	else
		LEDOUT <= 8'b11110000;
end
///////////////////////////////////////////////////////////////////////

//////////////This Allows for one opperation. We will probably need to change this to do continuously, 
//or maybe just reset it everytime we need to read again?? something to think about.////////
always @ (posedge COUNT[9] or negedge reset_n)
begin
	if(!reset_n)
		SD_COUNTER <= 6'b0;
	else
	begin	
		if(!GO)
			SD_COUNTER <= 0;
		else
		
			/////////////////////////////////This should be 33 for write, 44 for read////////////////
			//////We will need to work out how to change this on the fly by its self/////////////////
			if(SD_COUNTER < 44)
				SD_COUNTER <= SD_COUNTER+1;
				
	end
end

//I2C Operation, Write////

always @ (posedge COUNT[9] or negedge reset_n)
begin
	if(!reset_n)
	begin	
		SCL <= 1;
		SDI <= 1;
	end
	else
	
		///////This Section is for writing, If switch one is to the left////////////////////////
		//***************************************************************************************
		if (SW[0])
		begin
			case (SD_COUNTER)
				6'd0		: begin SDI <=1; SCL <= 1; SCL_CTRL <=0; end
				////////START///////////
				6'd1		:	SDI <= 0;
				6'd2		:	SCL <= 0;
				////////I2C Adress. 8th bit is 0 for write, then 9th is tristate for ACK///////
				6'd3		:	begin SDI <= 1;SCL_CTRL <=1; end
				6'd4		:	SDI <= 0; 
				6'd5		:	SDI <= 1;
				6'd6		:	SDI <= 0;
				6'd7		:	SDI <= 0;
				6'd8		:	SDI <= 0;
				6'd9		:	SDI <= 0;
				6'd10		:	SDI <= 0;
				6'd11		:	SDI <= 1'bz;
				/////////Memory Adress. Or reg adress for accel.///////////
				6'd12		:	SDI <= 0;
				6'd13		:	SDI <= 0;
				6'd14		:	SDI <= 0;
				6'd15		:	SDI <= 0;
				6'd16		:	SDI <= 0;
				6'd17		:	SDI <= 0;
				6'd18		:	SDI <= 0;
				6'd19		:	SDI <= 0;		
				6'd20		:	SDI <= 1'bz;
				//////////Data to be writen to the adress////////////////
				6'd21		:	SDI <= 1;
				6'd22		:	SDI <= 0;
				6'd23		:	SDI <= 1;
				6'd24		:	SDI <= 0;
				6'd25		:	SDI <= 1;
				6'd26		:	SDI <= 0;
				6'd27		:	SDI <= 1;		
				6'd28		:	SDI <= 0;
				6'd29		:	begin SDI <= 1'bz;SCL_CTRL <=0; end
				////////////Stop////////////////
				6'd30		:	begin SDI <= 1'b0; SCL <= 1'b1; end
				6'd31		:	SDI <= 1'b1;
			endcase
		end
		///*********************************************************************
		//////This Section is supposed to Read... Hopefully. Edit: yup it now works  :) /////////////////////
		///**********************************************************************
		else
		begin
			case (SD_COUNTER)
					6'd0		: begin SDI <=1; SCL <= 1; SCL_CTRL <=0;end
					////////START///////////
					6'd1		:	SDI <= 0;
					6'd2		:	SCL <= 0;
					////////I2C Adress. Still need to write first///////
					6'd3		:	begin SDI <= 1; SCL_CTRL <=1; end
					6'd4		:	SDI <= 0;
					6'd5		:	SDI <= 1;
					6'd6		:	SDI <= 0;
					6'd7		:	SDI <= 0;
					6'd8		:	SDI <= 0;
					6'd9		:	SDI <= 0;
					6'd10		:	SDI <= 0;
					6'd11		:	SDI <= 1'bz;
					/////////Memory Adress///////////
					6'd12		:	SDI <= 0;
					6'd13		:	SDI <= 0;
					6'd14		:	SDI <= 0;
					6'd15		:	SDI <= 0;
					6'd16		:	SDI <= 0;
					6'd17		:	SDI <= 0;
					6'd18		:	SDI <= 0;
					6'd19		:	SDI <= 0;		
					6'd20		:	begin SDI <= 1'bz; SCL <=1'bz; SCL_CTRL<=0;end
					//////////Data////////////////
					/////By Now the Adress should be ready to be read/////////////
					////Issue another start//////////////////
					
					6'd21		:	SDI <= 0;
					6'd22		:	SCL <= 0;
					//////I2C Adress with read bit/////////				
					
					6'd23		:	begin SDI <= 1;SCL_CTRL <=1;end
					6'd24		:	SDI <= 0;
					6'd25		:	SDI <= 1;
					6'd26		:	SDI <= 0;
					6'd27		:	SDI <= 0;		
					6'd28		:	SDI <= 0;
					6'd29		:	SDI <= 0;
					6'd30		:	SDI <= 1;				
					6'd31		:	SDI <= 1'bz;
					///////////I dont know why this has to be here?? clock stretching happening??????//////////////
					6'd32		:		;
					/////First byte of data transfer from the slave. Hehe slaves.//////////
					6'd33		:	DATAIN[7] <= I2C_SDA ;
					6'd34		:	DATAIN[6] <= I2C_SDA ;
					6'd35		:	DATAIN[5] <= I2C_SDA ;
					6'd36		:	DATAIN[4] <= I2C_SDA ;
					6'd37		:	DATAIN[3] <= I2C_SDA ;		
					6'd38		:	DATAIN[2] <= I2C_SDA ;
					6'd39		:	DATAIN[1] <= I2C_SDA ;	
					6'd40		:	begin DATAIN[0] <= I2C_SDA ;SCL_CTRL <=0; end				
					
					
					////////////Stop////////////////
					6'd41		:	begin SDI <= 1'b0; SCL <= 1'b1; end
					6'd42		:	SDI <= 1'b1;
				endcase
		end
end

////////This assignment is necesarry for the writing operation/////////////

//assign I2C_SCL = ((SD_COUNTER >=4) & (SD_COUNTER <=31))? ~COUNT[9] : SCL;

//*************************************************************************

////////Use This one for reading :( ///////////////////////////////////////////////////////////////////////////////

//assign I2C_SCL = (((SD_COUNTER >=4) & (SD_COUNTER <=20)) || ((SD_COUNTER >=24) & (SD_COUNTER <=40)))? ~COUNT[9] : SCL;


//TEST READ!!!!
assign I2C_SCL = (SCL_CTRL)? ~COUNT[9] : SCL;

//********************************************************************************************************************

//Yeah, just assign the placeholder SDI to the SDA line
assign I2C_SDA = SDI;

//Display the byte that was recived on the LEDs on the De0-Nano//////
assign LED = DATAIN;


endmodule






