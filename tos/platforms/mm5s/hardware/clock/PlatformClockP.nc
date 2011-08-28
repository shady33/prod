/*
 * Copyright (c) 2011 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * Initilization of the Clock system for the MM5 series motes.
 *
 * MM5s are based on msp430f5438 series cpus.
 *
 * We want the following set up to be true when we are complete:
 *
 * 8 MHz clock.    The 5438a is spec'd for a max of 8MHz when
 * running at 1.8V.  So that is what we use.  Acutally 7995392 Hz
 * (.0576% error, it'll do).
 *
 * DCOCLK -> MCLK, SMCLK.   Also drives high speed timer that
 * provides TMicro.   1us (note, decimal microsecs).  DCOCLK
 * sync'd to FLL/XT1/32KiHz.
 *
 * MCLK /1: main  cpu clock.  Off DCOCLK.
 *
 * SMCLK /1: used for timers and peripherals.  We want to run the
 * SPI (SD, GPS, subsystems, etc.) quickly and this gives us the
 * option.  Off DCOCLK.
 *
 * ACLK: 32 KiHz.   Primarily used for slow speed timer that
 * provides TMilli.
 *
 * FLL: in use and clocked off the 32 KiHz XT1 input.
 *
 * Much of the system relies on the 32KiHz XT1 xtal working correctly.
 * We bring that up first and let it stabilize.
 *
 * The code loops up to 625ms waiting for XT1 stability.  If stability
 * is not achieved, the XT1 functionality is disabled.  This should
 * cause a hard_panic which results in writing a panic block in slow
 * mode.  Should never happen.
 *
 * Stabilization appears to take roughly 150ms.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

uint16_t xt1_ctr;

void __delay_cycles(uint32_t count);

module PlatformClockP {
  provides interface Init;
  uses interface Msp430XV2ClockControl;
  uses interface Init as SubInit;
} implementation {

  default command error_t SubInit.init () { }

  /*
   * We assume that the clock system after reset has been
   * set to some reasonable value.  ie ~1MHz.  We assume that
   * all the selects are 0, ie.  DIVA/1, XTS 0, XT2OFF, SELM 0,
   * DIVM/1, SELS 0, DIVS/1.  MCLK <- DCO, SMCLK <- DCO,
   * LFXT1S 32768, XCAP ~6pf
   *
   * We wait about a second for the 32KHz to stablize.
   *
   * PWR_UP_SEC is the number of times we need to wait for
   * TimerA to cycle (16 bits) when clocked at the default
   * msp430f5438 dco (about 2MHz).
   */

#define PWR_UP_SEC 16

  void wait_for_32K() __attribute__ ((noinline)) {
    nop();
  }

#ifdef notdef
    uint16_t left;

    TACTL = TACLR;			// also zeros out control bits
    TBCTL = TBCLR;
    TACTL = TASSEL_2 | MC_2;		// SMCLK/1, continuous
    TBCTL = TBSSEL_1 | MC_2;		//  ACLK/1, continuous
    TBCCTL0 = 0;

    /*
     * wait for about a sec for the 32KHz to come up and
     * stabilize.  We are guessing that it is stable and
     * on frequency after about a second but this needs
     * to be verified.
     *
     * FIX ME.  Need to verify stability of 32KHz.  It definitely
     * has a good looking waveform but what about its frequency
     * stability.  Needs to be measured.
     */
    left = PWR_UP_SEC;
    while (1) {
      if (TACTL & TAIFG) {
	/*
	 * wrapped, clear IFG, and decrement major count
	 */
	TACTL &= ~TAIFG;
	if (--left == 0)
	  break;
      }
    }
  }
#endif


  command error_t Init.init () {
    uint16_t i;

    /*
     * Enable XT1, lowest capacitance.
     *
     * XT1 pins (7.0 and 7.1) default to Pins/In.   For the XT1
     * to function these have to be swithed to Module control.
     *
     * Surf code mumbles something about P5.0 and 1 must be clear
     * in P5DIR.   Shouldn't have any effect (the pins get kicked
     * over to the Module for the Xtal and so the direction should
     * be a don't care).   Regardless we don't change the P7DIR
     * from its power up value so will be cleared (IN).
     *
     * The surf code also talks about SMCLK being 4 per-mil faster
     * if XCAP_3 is retained.  Not sure what effect XCAP setting
     * should have on SMCLK because XCAP effects the LF osc in LF mode,
     * XTS=0 (which it will be).   So a strange comment.
     *
     * Surf found XCAP=0 worked nice.  We do the same thing but it should
     * be checked.
     *
     * FIXME. 
     */

    P7SEL |= (BIT0 | BIT1);
    UCSCTL6 &= ~(XT1OFF | XCAP_3);

    /*
     * From comments in Surf code.
     *
     * Spin waiting for a stable signal.  This loop runs somewhere
     * between 10K and 20K times; if it gets to 65536 without success,
     * assume the crystal's absent or broken.  At the power-up DCO
     * (RSEL: 2, DCO: 19, MOD: 27) rate of ~2MHz and no crystal, the
     * loop takes 625ms to complete.
     *
     * @note The UCS module will fall back to REFOCLK if configured
     * for LF-mode XT1 and XT1 is not stable.  It does not, however,
     * revert to XT1 upon stabilization: the UCS module documentation
     * implies that OFIFG must be cleared for this to occur.
     * Consequently, we have to wait for stabilization even if we
     * "know" a crystal is present.
     */

    /*
     * xtr_ctr is initialized to 0 and counts up, if it hits zero
     * again because it wrapped then we bail and panic.
     */
    do {
      xt1_ctr++;
      UCSCTL7 &= ~(XT1LFOFFG | DCOFFG);
      SFRIFG1 &= ~OFIFG;
      nop();
      nop();
      if ((SFRIFG1 & OFIFG) == 0)
	break;
    } while (xt1_ctr);

    /*
     * If the XT1 signal is still not valid, disable it.
     *
     * This is a major failure as we assume we have an XT1 xtal for
     * timing stability.   Flag it and try again?
     * FIXME
     */
    if (UCSCTL7 & XT1LFOFFG) {
      P7SEL &= ~(BIT0| BIT1);
      UCSCTL6 |= XT1OFF;
      while (1)
	nop();
      return FAIL;
    }

    /*
     * XT1 up,  lower the drive as suggested by TI.
     *
     * TI example code suggests clearing XT1DRIVE to reduce power.
     * Current measurement does not indicate any value in doing so,
     * at least not in LPM4, but it doesn't seem to hurt either.
     *
     * Note: we don't ever go into LPM4,  LPM3 is required for the
     * low speed timer to run (clocked from XT1).
     */
    UCSCTL6 &= ~(XT1DRIVE_3);                 // Xtal is now stable, reduce drive

    /*
     * We are no longer faulting, but we should still wait for the frequency to
     * stabilize.   Use wait_for_32k().
     */

    wait_for_32K();

    /*
     * ACLK is to be set to XT1CLK, assumed to be 32KiHz (2^15Hz).
     * This drives TA0 for TMilli.
     *
     * DCO is to be set as configured.  The clock divider is the
     * minimum value of 2.
     *
     */

    /* Disable FLL control */
    __bis_SR_register(SR_SCG0);

    /*
     * Use XT1CLK as the FLL input: if it isn't valid, the module
     * will fall back to REFOCLK.  Use FLLREFDIV value 1 (selected
     * by bits 000)
     */
    UCSCTL3 = SELREF__XT1CLK;

    /*
     * The appropriate value for DCORSEL is obtained from the DCO
     * Frequency table of the device datasheet.  Find the DCORSEL
     * value from that table where the maximum frequency with DCOx=31
     * is closest to your desired DCO frequency.   (Where did this
     * come from?)   I've chosen next range up, don't want to run out
     * of head room.
     *
     * 32768 * (243 + 1) = 7,995,392 Hz
     */

    UCSCTL0 = 0x0000;		     // Set lowest possible DCOx, MODx
    UCSCTL1 = DCORSEL_4;
    UCSCTL2 = FLLD_0 + 243;
    __bic_SR_register(SR_SCG0);               // Enable the FLL control loop

    // Worst-case settling time for the DCO when the DCO range bits have been
    // changed is n x 32 x 32 x f_MCLK / f_FLL_reference. See UCS chapter in 5xx
    // UG for optimization.
    // 32 x 32 x 8 MHz / 32,768 Hz = 256000 = MCLK cycles for DCO to settle

    for (i = 0; i < 10; i++)		/* really how long */
      __delay_cycles(25600);

    // Loop until DCO fault flag is cleared.  Ignore OFIFG, since it
    // incorporates XT1 and XT2 fault detection.
    do {
      UCSCTL7 &= ~(XT1LFOFFG | DCOFFG);
      SFRIFG1 &= ~OFIFG;                      // Clear fault flags
    } while (UCSCTL7 & DCOFFG); // Test DCO fault flag

    /*
     * ACLK is XT1/1, 32KiHz.
     * MCLK is set to DCOCLK/1.   8 MHz
     * SMCLK is set to DCOCLK/1.  8 MHz.
     * DCO drives TA1 for TMicro and is set to provide 1us ticks.
     * ACLK  drives TA0 for TMilli.
     */
    UCSCTL4 = SELA__XT1CLK | SELS__DCOCLK | SELM__DCOCLK;
    UCSCTL5 = DIVA__1 | DIVS__1 | DIVM__1;
    call Msp430XV2ClockControl.configureTimers();
    call Msp430XV2ClockControl.start32khzTimer();
    call Msp430XV2ClockControl.startMicroTimer();
    return SUCCESS;
  }
}
