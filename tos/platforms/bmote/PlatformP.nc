#include "hardware.h"
#include "cpu_stack.h"

extern uint16_t _etext, _end;

module PlatformP {
  provides {
    interface Init;
    interface Platform;
  }
  uses {
    interface Init as PlatformPins;
    interface Init as PlatformLeds;
    interface Init as PlatformClock;
    interface Init as MoteInit;
  }
}

implementation {

#define USEC_REG    TA0R
#define JIFFIES_REG TA1R

  command error_t Init.init() {
    WDTCTL = WDTPW + WDTHOLD;    // Stop watchdog timer

    call PlatformPins.init();   // Initializes the GIO pins

    call PlatformLeds.init();   // Initializes the Leds
    call PlatformClock.init();  // Initializes UCS
    return SUCCESS;
  }

  async command uint16_t Platform.usecsRaw()   { return USEC_REG; }
  async command uint16_t Platform.jiffiesRaw() { return JIFFIES_REG; }

}
