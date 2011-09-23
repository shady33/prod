/*
todo
 */

/**
   Driver for the LIS3DHP accelerometer.
 */


generic module LIS3DHP() {
  provides interface Read<uint16_t> as AccelX;  
  provides interface Read<uint16_t> as AccelY;
  provides interface Read<uint16_t> as AccelZ;

  uses interface Resource as AccelXResource;
  uses interface Resource as AccelYResource;
  uses interface Resource as AccelZResource;

  uses interface SpiPacket;
  uses interface HplMsp430GeneralIO as CS;
}

#define CTRL_REG1 0x20      // p. 26, LIS3DH data sheet 

#define READ_BIT  0x01      // p. 22

#define XEN       0x01      // p. 29  CTRL_REG1 bit for x enable
#define YEN       0x20      //                      for y      
#define ZEN       0x40      //                      for z
#define LPEN      0x80      //                      for low power enable

implementation {
  enum {
    S_IDLE,
    S_GET_XL,
    S_GET_XH,
    S_GET_YL,
    S_GET_YH,
    S_GET_ZL,
    S_GET_ZH,
  };

  uint8_t txBuf[2], rxBuf[2];

  void errorBreakpoint() {

  }

  /*                                                                          
     Signal an unsuccesful read.  Using tasks to call readDone avoids using   
     nested interrupts and a compile time warning.                            
  */
  task void readError() {
    //TEP114 says this MUST be a 0                                            
    signal AccelX.readDone(FAIL, 0);
  }

  /*                                                                          
     Signal a successful read and pass readDone the data.  Depending on how the                                               TMP112 is configured, the first 12 or 13 bits of the data word will contain                                              a reading.   See the README for more.                                    
  */
  task void readSuccess() {
    uint16_t temp;
    //hack
    temp = 17;

    //temp = tempData[0];
    //temp <<= 8;
    //temp |=  tempData[1];
    signal AccelX.readDone(SUCCESS, temp);
  }

  command error_t AccelX.read() {
    return call AccelXResource.request();        // see AccelXResource.granted
  }
  command error_t AccelY.read() {
    //return call AccelYResource.request();        // see AccelYResource.granted
  }
  command error_t AccelZ.read() {
    //return call AccelZResource.request();        // see AccelZResource.granted
  }
  
  event void AccelXResource.granted() {

    txBuf[0] = READ_BIT | (CTRL_REG1 << 2);  // datasheet, p. 23
    txBuf[1] = XEN; //later: | YEN | ZEN;

    call CS.clr(); 
    call SpiPacket.send(txBuf, rxBuf, 2);
  }

  event void AccelYResource.granted() {
    nop();;
//    errorResult = call Hpl.getReg(LIS3L02DQ_OUTY_H);
//    if (errorResult != SUCCESS) {
//      state = S_GET_YL;
//      post complete_Task();
//    }
//    state = S_GET_YH;
//
  }

  event void AccelZResource.granted() {
    nop();;
  }

  async event void SpiPacket.sendDone( uint8_t* tx, uint8_t* rx, uint16_t len,
                             error_t error ) {
    if(error != SUCCESS) {
      errorBreakpoint();
      post readError();
    } else {
      post readSuccess();
    }
  }

}
