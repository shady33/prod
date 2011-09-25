/*
todo license
*/

/*
Read values from an LIS3DH accelerometer.
See the README for a description of the value returned.

@author Tod Landis <go@todlandis.com>
*/

generic configuration LIS3DHC() {
  provides interface Read<uint16_t> as AccelX;
}
implementation {
  components new LIS3DHP();
  AccelX = LIS3DHP.AccelX;

  components new Msp430UsciSpiA3C() as Spi;  
  LIS3DHP.AccelXResource -> Spi;
  LIS3DHP.AccelYResource -> Spi;
  LIS3DHP.AccelZResource -> Spi;

  LIS3DHP.SpiPacket -> Spi;

  components HplMsp430GeneralIOC  as Pins;  //todo refactor away the Hpl reference
  LIS3DHP.CS -> Pins.Port107;
}
