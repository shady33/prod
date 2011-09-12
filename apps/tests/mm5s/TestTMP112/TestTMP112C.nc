/*
todo license
 */
 
#include "Timer.h"

module TestTMP112C {
  uses {
    interface Boot;
    interface Timer<TMilli> as  TestTimer;	
    interface Read<uint16_t> as TempSensor;
  }
}
implementation {  

  event void Boot.booted() {
    //    call TestTimer.startPeriodic(1024);

    call TempSensor.read();
  }
  
  event void TestTimer.fired(){
    call TempSensor.read();
    nop();
  }

  event void TempSensor.readDone(error_t error, uint16_t data){
    if (error == SUCCESS){
      nop();
      //      if (data > 2047) data -= (1<<12);    the z1 temp test does this?
      // data *=0.625;
    } else {
      nop();
    }
  }
}





