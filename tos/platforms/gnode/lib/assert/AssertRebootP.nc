/*
 * Copyright (c) 2008-2012, SOWNet Technologies B.V.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * Handles failed assertions by rebooting the node.
 */
module AssertRebootP {
	uses {
		interface Reboot;
	}
}
implementation {

	/**
	 * Assert a condition is true.
	 */
	void doAssert(bool condition, uint16_t errorCode) __attribute__((C)) {
		if (!condition) call Reboot.reboot();
	}
	
	/**
	 * Assert a condition is false.
	 */
	void doAssertNot(bool condition, uint16_t errorCode) __attribute__((C)) {
		doAssert(!condition, errorCode);
	}
	
	/**
	 * Assert an error code is SUCCESS.
	 */
	void doAssertSuccess(error_t error, uint16_t errorCode) __attribute__((C)) {
		doAssert(error == SUCCESS, errorCode);
	}
	
	/**
	 * Assert a equals b.
	 */
	void doAssertEquals(uint32_t a, uint32_t b, uint16_t errorCode) __attribute__((C)) {
		doAssert(a == b, errorCode);
	}
	
}
