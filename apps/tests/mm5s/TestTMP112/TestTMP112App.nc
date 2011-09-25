/*
todo license
 */

/*
This is a test application for the TMP112 + I2C driver.
*/ 
configuration TestTMP112App {
}
implementation {
  components MainC, TestTMP112C as App;
  App.Boot -> MainC.Boot;

  components new TMP112C() as TempSensor;
  App.TempSensor -> TempSensor; 
  
  components new TimerMilliC() as Timer;
  App.TestTimer -> Timer;
}


