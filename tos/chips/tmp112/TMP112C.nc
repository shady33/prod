
/*
todo license
*/

/*
Read the temperature from a TMP112.
*/
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
