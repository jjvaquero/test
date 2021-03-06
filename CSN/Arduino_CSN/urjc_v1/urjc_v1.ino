/* 
 Título: CSN Bluetooth v5.3
 Autor: Alberto Rodríguez Moreno
 Fecha: 5 diciembre 2012
 */

#include <avr/interrupt.h>
#include <avr/io.h>
#include <pins_arduino.h>
#include <SD.h>

#define INIT_TIMER_COUNT 34285
#define RESET_TIMER5 TCNT5 = INIT_TIMER_COUNT


// Variables de adquisición
uint16_t muestra;
uint16_t muestra_aux;
uint8_t* m;

// Variables de comunicación
uint16_t* hist_tx;

// Variables de almacenamiento
uint16_t hist1[1024];
uint16_t hist2[1024];

uint16_t* hist_alm;
File hist;
size_t s = 4;
uint32_t maxim = 0;
uint32_t maxim_aux = 0;

// Variables genéricas
char dat_hist[10];
int cont = 2;
int cont2 = 0;

//variable para el envio de datos
union hist{
  unsigned int data[1024];  //int 16 bits
  byte data_buffer[2048]; 
}hist_data;

//flag empleado para controlar la escritura en el buffer
boolean enviando = false;

int init_SD(){
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(47, OUTPUT);

  // see if the card is present and can be initialized:
  if (!SD.begin(47)) {
    return 0;
  }
  SD.remove("inst.txt");
  SD.remove("acum.txt");
  return 1;
}

void init_digitalIO(){
  
  
  for(int i = 0; i < 16; i++){
    pinMode(i+22, INPUT);
  }
  
  pinMode(3, INPUT);
  pinMode(2, INPUT); 

  //ahora configuro los pines de DesInt y ConvSt 
  //como salidas
  pinMode(34, OUTPUT);
  pinMode(35, OUTPUT);
  
  digitalWrite(34, HIGH);
  digitalWrite(35, HIGH);
  
  
  pinMode(8, INPUT); // Conexion BT
  pinMode(9, OUTPUT); // Reset BT 
  digitalWrite(9, LOW);
  pinMode(11, OUTPUT);
  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
  digitalWrite(11, LOW);
  digitalWrite(12, LOW);
  digitalWrite(13, LOW);
  pinMode(20, INPUT); // Interrupcion dato disponible
  
}

void init_histograms(){

  uint32_t cero = 0;
  uint8_t* d;
  d = (uint8_t*)&cero;

  for(int i = 0; i < 1024; i++){
    hist1[i] = 0;
    hist2[i] = 0;
    hist_data.data[i] = 0;
    //hist3[i] = 0;
  }
  hist = SD.open("acum.txt", FILE_WRITE);
  for(int i = 0; i < 1024; i++){
    hist.write(d, s);
  }
  hist.close();
  hist_alm = hist1;
  hist_tx = hist2;

}

void init_histograms2(){
   for(int i = 0; i < 1024; i++){
    hist1[i] = 0;
    hist2[i] = 0;
    hist_data.data[i] = 0;
    //hist3[i] = 0;
  } 
}

void init_interrupt_P3(){ // Interrupcion externa a traves del pin 3
  EICRB = (EICRB & ~((1 << ISC50) | (1 << ISC51))) | (FALLING << ISC50);
  EIMSK |= (1 << INT5);
}

void init_interrupt_P2(){ // Interrupcion externa a traves del pin 2
  EICRB = (EICRB & ~((1 << ISC40) | (1 << ISC41))) | (RISING << ISC40);
      EIMSK |= (1 << INT4);
}

void init_interrupt_TIMER5(){
  cli();
  //Timer5 Settings: Timer Prescaler /1024,
  TCCR5B |= (1<<CS52);
  TCCR5B &= ~(1<<CS51);
  TCCR5B |= (1<<CS50);
  // Use normal mode
  TCCR5A &= ~((1<<WGM51) | (1<<WGM50));
  // Use internal clock – external clock not used in Arduino
  ASSR &= ~(1<<AS2);
  //Timer5 Overflow Interrupt Enable
  TIMSK5 |= (1<<TOIE5);
  TIMSK5 &= ~(0<<OCIE5A);  
  RESET_TIMER5;
  sei();

}


ISR(INT5_vect) // Comp
{
  //espera el tiempo de integracion
  //de lo contrario salta a 1us
  for (int i = 0; i < 20; i++){
    asm("NOP");
  }
  PORTC &= ~(1 << 3);      
  PORTC |= (1 << 3);

}

ISR(INT4_vect) // NBusy
{
  cont2++;
  uint8_t port_c = 0;
  muestra = 0;
  m = (uint8_t*)&muestra;
  
  //variables para la lectura
  byte MSB = 0;
  byte MSB_aux = 0;
  byte LSB = 0;
  
  //lectura propiamente dicha
  /*LSB = PINA; MSB_aux = PINC;
  MSB_aux = (MSB_aux >>4) & 0x0F;
  MSB = ((MSB_aux & 0x01)*8) | ((MSB_aux & 0x02)*4)| 
  ((MSB_aux & 0x04)*2)|((MSB_aux & 0x08)*1);*/

  
  m[0] = *portInputRegister(1); // PORTA
  m[1] = *portInputRegister(3); // PORTC
  
  
  // Invertir el byte del PORTC, (Creo que no funciona bien) Hay que revisarlo
  port_c |= (bitRead(m[1], 0) << 7);
  port_c |= (bitRead(m[1], 1) << 6);
  //port_c |= (bitRead(m[1], 2) << 5);
  //port_c |= (bitRead(m[1], 3) << 4);
  port_c |= (bitRead(m[1], 4) << 3);
  port_c |= (bitRead(m[1], 5) << 2);
  port_c |= (bitRead(m[1], 6) << 1);
  port_c |= (bitRead(m[1], 7) << 0);
  
  m[1] = port_c;
  
  // Desplazamos bits
  //muestra_aux = word(MSB,LSB) >>2; 
  muestra_aux = muestra >> 2;
  
  //garantizo no salirme del indice maximo
  if(muestra_aux > 1023){
    muestra_aux = 1023;
  }  
  
  
  
  //condiciones para que no desborde y para quitar de paso
  //el ruido que aparece fuera del rango de interes
  if(hist_alm[muestra_aux] != 65535 && muestra_aux > 10 
      && muestra_aux < 900)
    hist_alm[muestra_aux]++;
    
  //pongo mis datos en el histograma
  //esta comprobacion se puede quitar
  if (!enviando && muestra_aux > 10 && muestra_aux < 900) 
    hist_data.data[muestra_aux]++;  
    
  PORTC &= ~(1 << 2);   
  PORTC |= (1 << 2);
  
  //espero por oscilaciones...
    for (int i = 0; i < 20; i++){
    asm("NOP");
  }

}

// Aruino runs at 16 Mhz, 
ISR(TIMER5_OVF_vect) {
  RESET_TIMER5;
    
  uint16_t* hist_aux;
  boolean conn = true;
  boolean connBT = false;
  char rec;

  // Mientras transmitimos los datos del histograma se 
  // puede seguir adquiriendo datos almacenandolos en otro buffer.
  // Las siguientes 3 instrucciones son importantes para que
  // la transmision y el almacenamiento no se solapen.
  hist_aux = hist_alm;
  hist_alm = hist_tx;
  hist_tx = hist_aux;
  //TODO todos los buffers comparten la memoria
  //si algo es sobreescrito durante la lectura es sobreescrito en todos
  //es mejor usar un flag para controlar cuando es posible escribir
  //en el buffer y cuando no
  //no pasa nada si se pierden los eventos que ocurren 
  //durante la escritura
  
  //otra cosa a mirar es si 
  
  uint32_t dato = 0;
  uint8_t* d;
  d = (uint8_t*)&dato;
  
  sei(); // Habilitamos las interrupciones globales
  //garantiza que se atiende a las interrupciones externas 
  //durante la escritura
  
  enviando = true;
  /*
  for(int i = 0; i < 1024; i++){
      sprintf(dat_hist, "%u ", hist_tx[i]);
      Serial1.write(dat_hist);
      hist_tx[i] = 0;
  }*/
  //envio los datos en crudo y en una sola instruccion
  //se puede modificar el buffer para meter cabeceras o lo que 
  //sea necesario
  Serial.write(hist_data.data_buffer,2048);
  //fin de linea...porque...tampoco esta de mas
  //Serial.println();
  //Serial1.println();
  // Inicializamos los histogramas
  init_histograms2();  
  enviando=false;
}

void setup(){
  
  // Configuramos los pines digitales de entrada/salida
  init_digitalIO();
  
  //para que le sea mas comodo a esteban
  //que lo conecte por el usb
  //Serial1.begin(2000000);
  //Serial.begin(9600);
  Serial.begin(115200);
  
  

  // Inicializamos los histogramas
  init_histograms();  
  
  // Interrupts initialization
  init_interrupt_P3();
  init_interrupt_P2();
  init_interrupt_TIMER5();  
}

void loop(){
  
}





