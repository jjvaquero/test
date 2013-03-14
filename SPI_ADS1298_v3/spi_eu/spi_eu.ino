/*
Probando el inclinometro de Eu
*/
// inslude the SPI library:
#include <SPI.h>


// set pin 10 as the slave select forthe digital pot:
const int slaveSelectPin = 53;
int valor_x,valor_y;

void setup() {
  // set the slaveSelectPin as an output:
  // initialize SPI:
  SPI.begin(); 
  SPI.setDataMode(SPI_MODE3);
  SPI.setBitOrder(MSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV16); 
  Serial.begin(9600);
}

void loop() {

  valor_x = leer_Xincl_Out();
  valor_y = leer_Yincl_Out();
  
  delay(100);
  
  Serial.print(valor_x);Serial.print(",");
  Serial.print(valor_y);Serial.print("\n");
}

int leer_Xincl_Out(){
  byte MSB, LSB;
  byte dir = 0x0C;
  int valor;
  //float valor_calc;
  
  //Comienzo la transferencia
  digitalWrite(slaveSelectPin,LOW);
  
  //pido los datos
  MSB = SPI.transfer(dir);
  LSB = SPI.transfer(dir);
  
  digitalWrite(slaveSelectPin,HIGH);
  
  delay(1);
  
  //comienzo otro ciclo para leer los datos
    digitalWrite(slaveSelectPin,LOW);
  
  //almaceno los datos
  MSB = SPI.transfer(dir);
  LSB = SPI.transfer(dir);
  
  digitalWrite(slaveSelectPin,HIGH);
  
  //hago ahora el procesado del valor
  //deberia comprobar los flags...
  //15 -- new_data
  //14 -- Error/Alarm
  //como es complemento a 2 
  //13 es el signo
  //signo_aux = MSB & 0x20;
  //me cargo los flags y el signo  
  MSB = MSB & 0x3F;
  valor = int(word(MSB,LSB));
  if (valor>8192) valor = (16384-valor+1)*(-1);
  
  //calculo el valor con la transformacion de la hoja de datos
  //valor_calc = float(valor) * 0.025;
  
  return valor; //valor_calc;
}

int leer_Yincl_Out(){
  byte MSB, LSB;
  byte dir = 0x0E;
  int valor;
 // float valor_calc;
  
  //Comienzo la transferencia
  digitalWrite(slaveSelectPin,LOW);
  
  //pido los datos
  MSB = SPI.transfer(dir);
  LSB = SPI.transfer(dir);
  
  digitalWrite(slaveSelectPin,HIGH);
  
   delay(1);
   
  //comienzo otro ciclo para leer los datos
    digitalWrite(slaveSelectPin,LOW);
  
  //almaceno los datos
  MSB = SPI.transfer(dir);
  LSB = SPI.transfer(dir);
  
  digitalWrite(slaveSelectPin,HIGH);
  
  //hago ahora el procesado del valor
  //deberia comprobar los flags...
  //15 -- new_data
  //14 -- Error/Alarm
  //como es complemento a 2 
  //13 es el signo
  //signo_aux = MSB & 0x20;
  //me cargo los flags y el signo  
  MSB = MSB & 0x3F;
  valor = int(word(MSB,LSB));
  if (valor>8192) valor = (16384-valor+1)*(-1);
  
  //calculo el valor con la transformacion de la hoja de datos
  //valor_calc = float(valor) * 0.025;
  
  return valor; //valor_calc;
}
