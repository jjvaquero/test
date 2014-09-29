#include "inc/hw_ints.h"
#include "inc/hw_memmap.h"
#include "inc/hw_types.h"
#include "driverlib/gpio.h"
#include "driverlib/interrupt.h"
#include "driverlib/pin_map.h"
#include "driverlib/sysctl.h"
#include "driverlib/uart.h"
//#include "utils/uartstdio.h"
#include <stdio.h>
#include <stdlib.h>
#include "C11204PS.h"


unsigned char cmdOut[60];
char cmdIn[60];
int readChar;
unsigned char aux;
char cmd[15];
char* ptr;
float* ptrFloat;
float vars[5];



/**
 *  Copied from  http://www.programiz.com/c-programming/examples/hexadecimal-decimal-convert
 *
 */
void decimal_hex(int n, char hex[]) /* Function to convert decimal to hexadecimal. */
{
    int i=3,rem;  // i=4 I will only use numbers smaller than this
    while (n!=0 && i >= 0)
    {
        rem=n%16;
        switch(rem)
        {
            case 10:
              hex[i]='A';
              break;
            case 11:
              hex[i]='B';
              break;
            case 12:
              hex[i]='C';
              break;
            case 13:
              hex[i]='D';
              break;
            case 14:
              hex[i]='E';
              break;
            case 15:
              hex[i]='F';
              break;
            default:
              hex[i]=rem+'0';
              break;
        }
        i--;
        n/=16;
    }

}


int main(void) {

	int i = 0;
	//system clock config, 50 MHz, using PLL and a 16 Mhz XTAL,  to use 80 Mhz, sysctl_sysdiv_2_5
	SysCtlClockSet(SYSCTL_SYSDIV_2_5| SYSCTL_USE_PLL | SYSCTL_XTAL_16MHZ | SYSCTL_OSC_MAIN);




	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOF);

	//configure the UART to be used with the usb
	SysCtlPeripheralEnable(SYSCTL_PERIPH_UART0);
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOA);

	//LED pin
	GPIOPinTypeGPIOOutput(GPIO_PORTF_BASE, GPIO_PIN_2);

	//Pin config
	GPIOPinConfigure(GPIO_PA0_U0RX);
	GPIOPinConfigure(GPIO_PA1_U0TX);
	GPIOPinTypeUART(GPIO_PORTA_BASE, GPIO_PIN_0 | GPIO_PIN_1);
	UARTConfigSetExpClk(UART0_BASE, SysCtlClockGet(), 115200,
	(UART_CONFIG_WLEN_8 | UART_CONFIG_STOP_ONE | UART_CONFIG_PAR_NONE));

	startCommunication(UART3_BASE);




//	UARTStdioInit(0);
	//populate the array now
	  cmdOut[0] = 0x02;
	  cmdOut[1] = 0x48;
	  cmdOut[2] = 0x50;
	  cmdOut[3] = 0x4F;
	  cmdOut[4] = 0x03;
	  cmdOut[5] = 0x45; //0x00;
	  cmdOut[6] = 0x43; //0xEA; //x43;
	  cmdOut[7] = 0x0D;
	  //Now i will send the data thoroug the serial port

	  UARTCharPut(UART0_BASE, 'E');
	  UARTCharPut(UART0_BASE, 'n');
	  UARTCharPut(UART0_BASE, 't');
	  UARTCharPut(UART0_BASE, 'e');
	  UARTCharPut(UART0_BASE, 'r');
	  UARTCharPut(UART0_BASE, ' ');
	  UARTCharPut(UART0_BASE, 'T');
	  UARTCharPut(UART0_BASE, 'e');
	  UARTCharPut(UART0_BASE, 'x');
	  UARTCharPut(UART0_BASE, 't');
	  UARTCharPut(UART0_BASE, ':');
	  UARTCharPut(UART0_BASE, ' ');


	  while(1) //continous send read loop
	  {

		  //Send the hpo command until i get an answer from the system
		  //while (!UARTCharsAvail(UART3_BASE)){
		  aux = UARTCharGet(UART0_BASE);

		  for(i = 0; i < 60; i++){ cmdIn[i] = 0;}

			ptrFloat = getInfoAndStatus(UART3_BASE);

			for (i = 0; i < 5 ; i++){
				vars[i] = *ptrFloat;
				ptrFloat++;
				readChar += ltoa((long) vars[i], &cmdIn[readChar]);
				cmdIn[readChar] = ' ';
				readChar++;
			}



		  UARTCharPut(UART0_BASE,'\n');
		  UARTCharPut(UART0_BASE, readChar);
		  for (i = 0; i <readChar; i++){
			  UARTCharPut(UART0_BASE, cmdIn[i]);
		  }

		  readChar = 0;

		 //SysCtlDelay(5000000);
		// GPIOPinWrite(GPIO_PORTF_BASE, GPIO_PIN_2, 0x00);
		 //SysCtlDelay(5000000);

	  }





	return 0;
}
