/*
todo license
 */


/**
 This is the private module for the TMP112 driver.

@author Tod Landis <go@todlandis.com>
 */

#include <TinyError.h>

#define CLIENT_ADDRESS 0x48   // use 0x48 = 1001000 for ADD0 connected to ground
                              //     0x49 = 1001001 for ADD0 connected to V+
                              //          = 1001010 for ADD0 connected to SDA
                              //          = 1001011 for ADD0 connected to SCL

// possible values for the Pointer Register (Datasheet, p. 7)
#define TEMP_REGISTER    0   
#define CONFIG_REGISTER  1
#define TLOW_REGISTER    2
#define THIGH_REGISTER   3

uint8_t pointerReg;
uint8_t tempData[2];

module TMP112P {
   provides interface Read<uint16_t> as ReadTemp;
   uses {
    interface Resource;
    interface I2CPacket<TI2CBasicAddr> as I2C;        
  }
}


implementation {  

  /*
     Convenience method for debugging.  Set a breakpoint here to see the
     stack just before the driver returns an error.
  */     
  int errorBreakpoint() {
    nop();
  }
  command error_t ReadTemp.read(){
    return call Resource.request();  // see granted()
  }

  /*
     Signal an unsuccesful read.  Using tasks to call readDone avoids using
     nested interrupts and a compile time warning.
  */
  task void readError() {
    //TEP114 says this MUST be a 0
    signal ReadTemp.readDone(FAIL, 0);
  }

  /* 
     Signal a successful read and pass readDone the data.  Depending on how the
     TMP112 is configured, the first 12 or 13 bits of the data word will contain
     a reading.   See the README for more.
  */
  task void readSuccess() {
    uint16_t temp;
    temp = tempData[0];
    temp <<= 8;
    temp |=  tempData[1];
    signal ReadTemp.readDone(SUCCESS, temp);
  }

  /*
    Called when access to the I2C is granted.  This writes a request to read the temperature.
  */
  event void Resource.granted(){
    pointerReg = TEMP_REGISTER;

    if(SUCCESS != call I2C.write((I2C_START | I2C_STOP), CLIENT_ADDRESS, 1, &pointerReg)) {  // see writeDone
      call Resource.release();
      errorBreakpoint();
      post readError();
    }
  }

  /*
    Called when the write to the I2C completes.  This reads the temperature data.
  */
  async event void I2C.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data) {
    if(SUCCESS != call I2C.read((I2C_START | I2C_STOP),  CLIENT_ADDRESS, 2, tempData)) {  // see readDone
      call Resource.release();
      post readError();  
    } 
  }   


  /*
    Called when the I2C read completes.  
  */
  async event void I2C.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
     call Resource.release();
     if(error == SUCCESS) {
       post readSuccess();
     } else {
       post readError();
     }
  }
}
