/*
todo license
 */
 
#include <stdio.h>
#include "Timer.h"

char buf[80];

module TestTMP112C {
  uses {
    interface Boot;
    interface Read<uint16_t> as TempSensor;
    interface Timer<TMilli> as  TestTimer;  // not yet
  }
}
implementation {  

  event void Boot.booted() {
    call TempSensor.read();
  }
  
  event void TestTimer.fired(){
    call TempSensor.read();
    nop();
  }

  event void TempSensor.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      sprintf(buf, "SUCCESS:  Temperature reading = %x", data);
    } else {
      sprintf(buf, "ERROR:  TempSensor returned an error");
    }
    nop();
  }
}





