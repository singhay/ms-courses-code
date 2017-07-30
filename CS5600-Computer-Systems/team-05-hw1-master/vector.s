/*
 *  file:        vector.s
 *  description: defines symbols for OS trap vectors
 *
 *    CSG 112, Computer Systems, Northeastern CCIS
 *    Peter Desnoyers, Sept. 2008
 */

/*
 * Note that these indexes must match those used in setting up the
 * vector table in homework.c
 */
		_print   = 0x09002000 + (0 * 4)
		_readline = 0x09002000 + (1 * 4)
		_getarg  = 0x09002000 + (2 * 4)
		_yield12 = 0x09002000 + (3 * 4)
		_yield21 = 0x09002000 + (4 * 4)
		_uexit   = 0x09002000 + (5 * 4)

print:		mov	_print,%eax
		jmp	*%eax

readline:	mov	_readline,%eax
		jmp 	*%eax

getarg:		mov	_getarg,%eax
		jmp 	*%eax

yield12:	mov	_yield12,%eax
		jmp 	*%eax

yield21:	mov	_yield21,%eax
		jmp 	*%eax

uexit:		mov	_uexit,%eax
		jmp 	*%eax

	
/*
 * Export them as global symbols:
 */

        .global print, getline, readline, getarg, yield12, yield21, uexit

