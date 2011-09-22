/*
todo
 */

/**
   Driver for the LIS3DHP accelerometer.
 */


generic module LIS3DHP() {
  provides interface Read<uint16_t> as AccelX;   // matches LIS3l02dq API
  provides interface Read<uint16_t> as AccelY;
  provides interface Read<uint16_t> as AccelZ;

  uses interface Resource as AccelXResource;
  uses interface Resource as AccelYResource;
  uses interface Resource as AccelZResource;
}

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

  }

  command error_t AccelX.read() {
    return call AccelXResource.request();        // see AccelXResource.granted
  }
  command error_t AccelY.read() {
    return call AccelYResource.request();        // see AccelYResource.granted
  }
  command error_t AccelZ.read() {
    return call AccelZResource.request();        // see AccelZResource.granted
  }
  
  event void AccelXResource.granted() {
    nop();;
    //    errorResult = call Hpl.getReg(LIS3L02DQ_OUTX_H);
    //if (errorResult != SUCCESS) {
    //  state = S_GET_XL;
    //  post complete_Task();
    //}
    //state = S_GET_XH;
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
//    errorResult = call Hpl.getReg(LIS3L02DQ_OUTZ_H);
//    if (errorResult != SUCCESS) {
//      state = S_GET_ZL;
//      post complete_Task();
//    }
//    state = S_GET_ZH;
//
  }
}
