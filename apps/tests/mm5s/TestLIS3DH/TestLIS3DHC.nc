/*
todo license
 */
 
#include <stdio.h>
#include "Timer.h"

char buf[80];

module TestLIS3DHC {
  uses {
    interface Boot;
    interface Read<uint16_t> as AccelSensor;
    interface Timer<TMilli> as  TestTimer;  // not yet
  }
}
implementation {  

  event void Boot.booted() {
    call AccelSensor.readX();  // AIN'T GONNA WORK 
    call AccelSensor.readY();  // AIN'T GONNA WORK 
    call AccelSensor.readZ();  // AIN'T GONNA WORK 
  }
  
  event void TestTimer.fired(){
    nop();
  }

  event void AccelSensor.readDone(error_t error, uint16_t data) {
    if (error == SUCCESS) {
      sprintf(buf, "SUCCESS:  uhhhhhh");
    } else {
      sprintf(buf, "ERROR:  ");
    }
    nop();
  }
}





