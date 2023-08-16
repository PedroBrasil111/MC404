	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p0_m2p0_a2p0_f2p0_d2p0"
	.file	"prog.c"
	.globl	main
	.p2align	2
	.type	main,@function
main:
	addi	sp, sp, -16
	sw	ra, 12(sp)
	sw	s0, 8(sp)
	addi	s0, sp, 16
	li	a0, 0
	sw	a0, -12(s0)
	li	a0, 42
	lw	ra, 12(sp)
	lw	s0, 8(sp)
	addi	sp, sp, 16
	ret
.Lfunc_end0:
	.size	main, .Lfunc_end0-main

	.ident	"clang version 15.0.7 (Fedora 15.0.7-1.fc37)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
