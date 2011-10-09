/*
todo license
 */

/**
  This is a test application for the LIS3DH driver.
*/ 
configuration TestLIS3DHApp {
}
implementation {
  components MainC, TestLIS3DHC as App;
  App.Boot -> MainC.Boot;

  components new LIS3DHC() as Accel;
  App.Accel  ->       Accel.LIS3DH;
  App.ControlAccel -> Accel.SplitControl;
  App.InitAccel ->    Accel.Init;  

  components new TimerMilliC() as PeriodTimer;
  App.PeriodTimer -> PeriodTimer;
}
