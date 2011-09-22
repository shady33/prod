/*
todo license
*/

/*
Read the temperature from a TMP112 digital thermometer.
See the README for a description of the value returned.

@author Tod Landis <go@todlandis.com>
*/

generic configuration LIS3DHC() {
  provides interface ReadX<uint16_t> as AccelX;
}
implementation {
  AccelX = LIS3DHP.AccelX;

  components new Msp430UsciSpiA3C() as Spi;  
  LIS3DHP.Resource -> Spi;
  //  LIS3DHP.Spi -> Spi;     
}
