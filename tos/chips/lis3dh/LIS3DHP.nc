/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * This module is the driver component for the LIS3DH
 * accelerometer in 4 wire SPI mode. It requires the SPI packet
 * interface and assumes the ability to manually toggle the chip select
 * via a GPIO. It provides the HplLIS3DH HPL interface.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @author Kaisen Lin <klin@archrock.com>
 *
 * LIS3DHC.nc is  HplLIS3L02DQLogicSPIP.nc (2006-12-12 18:23:06) with changes.
 * @author Tod Landis
 */

#include "LIS3DHRegisters.h"

module LIS3DHP
{
  provides interface Init;
  provides interface SplitControl;
  provides interface LIS3DH;           // getReg() and setReg()

  uses interface SpiPacket;
  //todo  uses interface GpioInterrupt as InterruptAlert;
  //  uses interface GeneralIO as CSN;
  uses interface HplMsp430GeneralIO as CSN;
}

#define READ_BIT  0x01      // p. 22 of the datasheet
#define XEN       0x01      // p. 29  CTRL_REG1 bit for x enable                
#define YEN       0x20      //                      for y                       
#define ZEN       0x40      //                      for z                       
#define LPEN      0x80      //                      for low power enable        

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_GETREG,
    STATE_SETREG,
    STATE_ERROR
  };

  uint8_t rx[4], tx[4];
  uint8_t mState;
  bool    misInited = FALSE;
  norace error_t mSSError;


  task void StartDone() {
    atomic mState = STATE_IDLE;
    signal SplitControl.startDone(SUCCESS);
    return;
  }

  task void StopDone() {
    signal SplitControl.stopDone(mSSError);
    return;
  }

  command error_t Init.init() {
    atomic {
      if (!misInited) {
	misInited = TRUE;
	mState = STATE_STOPPED;
      }
      // Control CS pin manually
      call CSN.makeOutput();
      call CSN.set();
    }
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
	mState = STATE_STARTING;
      } else {
	error = EBUSY;
      }
    }
    if (error) 
      return error;

    //old
    //    mSPITxBuf[0] = LIS3L02DQ_CTRL_REG1;
    //mSPITxBuf[1] = 0;
    //mSPITxBuf[1] = (LIS3L01DQ_CTRL_REG1_PD(1) | LIS3L01DQ_CTRL_REG1_XEN | LIS3L01DQ_CTRL_REG1_YEN | LIS3L01DQ_CTRL_REG1_ZEN);

    // new
    //    tx[0] = (CTRL_REG1 << 2);  // datasheet, p. 23  (careful:  not the same as the LIS3L02)                          
    //  tx[1] = XEN | YEN | ZEN;

    //call CSN.clr(); // CS LOW
    //error = call SpiPacket.send(tx, rx, 2);

    return error;
  }

  command error_t SplitControl.stop() {
    error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = STATE_STOPPING;
      } else { 
	error = EBUSY;
      }
    }
    if (error)
      return error;

    tx[0] = CTRL_REG1;
    // old
//    mSPITxBuf[1] = 0;
//    mSPITxBuf[1] = (LIS3L01DQ_CTRL_REG1_PD(0));

    // new
    tx[1] = 0;        // power done mode, datasheet p. 30

    call CSN.clr(); // CS LOW
    error = call SpiPacket.send(tx, rx, 2);
    return error;
  }
  
  command error_t LIS3DH.getReg(uint8_t regAddr) {
    error_t error = SUCCESS;

    //hack
    uint8_t d = regAddr << 2;
    uint8_t d2 = (1 << 7);
    uint8_t d3 = d | d2;

    if((regAddr < 0x07) || (regAddr > 0x3D)) {  // for the  LIS3DH - varies from device to device
      error = EINVAL;
      return error;
    }


    tx[0] = (regAddr << 2) | (1 << 7); // datasheet p. 23
    rx[0] = 0;

    sprintf(abuf, "d=%x  d2=%x  d3=%x    regAddr = %x  tx[0] = %x", d, d2, d3, regAddr, tx[0]);

#define CIRE
#ifdef CIRE
    tx[0] = 0x55;
    tx[1] = 0x55;

    while (1) {
      call SpiPacket.send(tx, rx, 2);
    }
#endif

    atomic mState = STATE_GETREG;
    call CSN.clr(); // CS LOW
    error = call SpiPacket.send(tx, rx, 1);

    return error;

  }
  
  command error_t LIS3DH.setReg(uint8_t regAddr, uint8_t val) {
    error_t error = SUCCESS;

    if((regAddr < 0x07) || (regAddr > 0x3D)) {  // LIS3DH changed this
      error = EINVAL;
      return error;
    }
    tx[0] = regAddr;
    tx[1] = val;
    atomic mState = STATE_SETREG;
    error = call SpiPacket.send(tx, rx, 2);

    return error;
  }

  async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t spi_error ) {
    error_t error = spi_error;

    atomic {
    switch (mState) {
    case STATE_GETREG:
      mState = STATE_IDLE;
  
      sprintf(abuf, "txBuf[0] = %x  rxBuf[0] = %x  len=%d error=%d", txBuf[0], rxBuf[0], len, error);


      call CSN.set(); // CS HIGH
      signal LIS3DH.getRegDone(error, (txBuf[0] & 0x7F) , rxBuf[1]);   // clears the read bit?
      break;
    case STATE_SETREG:
      mState = STATE_IDLE;
      signal LIS3DH.setRegDone(error, (txBuf[0] & 0x7F), txBuf[1]);
      break;
    case STATE_STARTING:
      mState = STATE_IDLE;
      call CSN.set();
      post StartDone();
      break;
    case STATE_STOPPING:
      mState = STATE_STOPPED;
      post StopDone();
    default:
      mState = STATE_IDLE;
      break;
    }
    }
    return;
  }

  //  async event void InterruptAlert.fired() {
  //    signal LIS3DH.alertThreshold();
  //    return;
  //  }

  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }

  default async event void LIS3DH.alertThreshold(){ return; }
}
