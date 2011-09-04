/*
todo license
*/

/*
Read the temperature from a TMP112 digital thermometer.

When readDone() is called with SUCCESS set,
its data will the two's complement representation
of the temperature in degrees Centigrade divided by
0.0625.
*/

generic configuration TMP112C() {
  provides interface Read<uint16_t>;
}
implementation {
  components TMP112P;
  Read = TMP112P.ReadTemp;

  components new Msp430UsciI2CB3C() as I2C;   //todo this is platform specific
  TMP112P.Resource -> I2C;
  //  TMP112P.ResourceRequested -> I2C;
  TMP112P.I2C -> I2C;     
}

/*
module TMP112C {
  provides interface Read<uint16_t>;
}
implementation {
command error_t Read.read() {
  //  return call TMP175Resource.request();
  signal Read.readDone(SUCCESS, 100); 
  return SUCCESS;
}
}
*/
