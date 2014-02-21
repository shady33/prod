#include "hardware.h"

configuration PlatformC {
  provides {
    interface Init as PlatformInit;
    interface Platform;
  }
}

implementation {
  components PlatformP;
  Platform = PlatformP;
  
  PlatformInit = PlatformP;

  components PlatformPinsC;
  PlatformP.PlatformPins -> PlatformPinsC;

  components PlatformLedsC;
  PlatformP.PlatformLeds -> PlatformLedsC;

  components PlatformClockC;
  PlatformP.PlatformClock -> PlatformClockC;
}
