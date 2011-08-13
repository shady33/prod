
configuration WiggleC {
}
implementation {
  components MainC, WiggleP, HplMsp430GeneralIOC as GeneralIOC;

  WiggleP -> MainC.Boot;

  components new Msp430GpioC() as P10;  // this provides interface GeneralIO
  P10 -> GeneralIOC.Port10;
  WiggleP.Port10 -> P10;

  components new Msp430GpioC() as P11;
  P11 -> GeneralIOC.Port11;
  WiggleP.Port11 -> P11;
}
