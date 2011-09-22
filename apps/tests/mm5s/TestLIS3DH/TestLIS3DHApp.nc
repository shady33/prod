/*
todo license
 */

/*
This is a test application for the LIS3DH + SPI driver.
*/ 
configuration TestLIS3DHApp {
}
implementation {
  components MainC, TestLIS3DHC as App;
  App.Boot -> MainC.Boot;

  components new LIS3DHC() as AccelSensor;
  App.AccelX -> AccelSensor.AccelX; 
  
  components new TimerMilliC() as Timer;
  App.TestTimer -> Timer;
}


