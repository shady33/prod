 #include "hardware.h"
 
 configuration PlatformC
 {
   provides interface Init;
 }
 implementation
 {
   components PlatformP
     , Msp430XV2ClockC
     ;
 
   Init = PlatformP;
   PlatformP.Msp430ClockInit -> Msp430XV2ClockC.Init;
 }
 