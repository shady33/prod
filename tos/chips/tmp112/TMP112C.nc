/*
todo license
*/

/*
Read the temperature from a TMP112 digital thermometer.
See the README for a description of the value returned.

@author Tod Landis <go@todlandis.com>
*/

generic configuration TMP112C() {
  provides interface Read<uint16_t>;
}
implementation {
  components TMP112P;
  Read = TMP112P.ReadTemp;

  components new Msp430UsciI2CB3C() as I2C;  
  TMP112P.Resource -> I2C;
  TMP112P.I2C -> I2C;     
}
