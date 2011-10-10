/*
todo license
 */
 
#include <stdio.h>
#include "Timer.h"
#include "LIS3DHRegisters.h"

char abuf[80];
char bufx[80];  // for  debugging messages
char bufy[80];
char bufz[80];

module TestLIS3DHC {
  uses {
    interface Boot;
    interface Init           as InitAccel;
    interface SplitControl   as ControlAccel;
    interface LIS3DH         as Accel;

    interface Timer<TMilli>  as PeriodTimer;
  }
}

implementation {  

  void whoAmI() {
    call Accel.getReg(WHO_AM_I);
  }

  event void Boot.booted() {

    P11DIR = (BIT2 | BIT1 | BIT0);
    P11SEL = (BIT2 | BIT1 | BIT0);

    call InitAccel.init();
    call ControlAccel.start();
  }
  
  event void ControlAccel.startDone(error_t error) {
    whoAmI();
    call ControlAccel.stop();
  }  

  event void ControlAccel.stopDone(error_t error) {
    //todo
  }  

  async event void Accel.getRegDone( error_t error, uint8_t regAddr, uint8_t val) {
    sprintf(abuf, "getRegDone  error=%x regAddr=%x val=%x (expecting 0x33)", error, regAddr, val);
  }  

  async event void Accel.alertThreshold() {
    //todo
  }  

  async event void Accel.setRegDone( error_t error , uint8_t regAddr, uint8_t val) {
    //todo
  }

  event void PeriodTimer.fired(){
    nop();
  }

}
