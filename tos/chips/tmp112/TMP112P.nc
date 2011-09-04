/*
todo license
 */


/**
 This is the private module for the TMP112 driver.

@author Tod Landis <go@todlandis.com>
 */

//todo this assumes the configuration register has the correct values


#define CLIENT_ADDRESS 0x48   // 0x48 = 1001000 for ADD0 connected to ground

// possible values for the Pointer Register (Datasheet, p. 7)
// This driver uses TEMP_REGISTER only
#define TEMP_REGISTER    0   
#define CONFIG_REGISTER  1
#define TLOW_REGISTER    2
#define THIGH_REGISTER   3

module TMP112P {
   provides interface Read<uint16_t> as ReadTemp;
   uses {
    interface Resource;
    interface I2CPacket<TI2CBasicAddr> as I2C;        
  }
}

implementation {  
  uint16_t temp;
  uint8_t pointerReg;
  uint8_t tempData[2];
  uint8_t errCode;
  error_t e;

  command error_t ReadTemp.read(){
    atomic errCode = 0;  // no errors
    return call Resource.request();  // see granted()  //todo need a timeout
  }

  event void Resource.granted(){

    pointerReg = TEMP_REGISTER;

    e =  call I2C.write((I2C_START | I2C_STOP), CLIENT_ADDRESS, 1, &pointerReg);  // see writeDone

    if(e) {
      atomic errCode = 1;
      call Resource.release();
      signal ReadTemp.readDone(e, 0);
    }
  }
  
  async event void I2C.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data) {
    if(!error) 
      atomic error = call I2C.read((I2C_START | I2C_STOP),  CLIENT_ADDRESS, 2, tempData);  // see readDone
    
    if(error){
      atomic errCode = 2;
      call Resource.release();
      signal ReadTemp.readDone(error, 0);
    } 
  }   

  async event void I2C.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
     uint16_t temp0;

    if(!error && call Resource.isOwner()) {
      //      uint16_t tmp;
      //for(tmp=0;tmp<0xffff;tmp++);	//todo need this delay from TMP102?

      call Resource.release();

      // From the datasheet:  The  first 12 bits (or 13 in extended mode) contain
      // the temperature.  We use 12.
      //
      // One LSB equals 0.0625°C. Negative numbers are represented in 12 bit binary 
      // twos complement format. For example, -0.25 is 1111 1111 1100
  
      // first byte is the MSB

      temp0 = data[0];
      temp0 = temp0 << 8;

      // second is the LSB
      temp0 |=  data[1];
      temp0 = temp0 >> 4;   // left four bits are garbage
      atomic temp = temp0;

      // temp will contain a twos complement representation of the temperature
      // in degrees Centigrade divided by 0.0625
      signal ReadTemp.readDone(SUCCESS, temp);
    }
  }
}
