
generic configuration LIS3DHC() {
  provides interface Init;
  provides interface SplitControl;
  provides interface LIS3DH;
}

implementation {
  components LIS3DHP;
  Init =         LIS3DHP.Init;
  SplitControl = LIS3DHP.SplitControl;
  LIS3DH =       LIS3DHP.LIS3DH;

  components new Msp430UsciSpiA3C() as Spi;
  LIS3DHP.SpiPacket -> Spi;

  components HplMsp430GeneralIOC  as Pins;  //todo refactor away the Hpl reference                                 
  LIS3DHP.CSN -> Pins.Port107;
}
