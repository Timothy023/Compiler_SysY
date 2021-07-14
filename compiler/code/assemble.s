.LC0:
	.string	"%d"
.LC1:
	.string	"%d\n"
	.section	.rodata
	.align	4
	.type	N, @object
	.size	N, 4
N:
	.long	3
	.text
	.comm	a,72,32
	.text
	.globl	f
	.type	main, @function
f:
	pushq	%rbp
	pushq	%r8
	pushq	%r9
	movq	%rsp, %rbp
	subq	$4, %rsp
	movl	32(%rbp), %r8d
	movl	%r8d, -4(%rbp)
.L1:
	movl	-4(%rbp), %r8d
	movl	$1, %r9d
	cmpl	%r9d, %r8d
	je	.L2
	jne	.L3
.L2:
	subq	$12, %rsp
	movl	$1, %eax
	addq	$16, %rsp
	popq	%r9
	popq	%r8
	popq	%rbp
	ret
	addq	$12, %rsp
.L3:
	movl	$1, %edi
	subq	$4, %rsp
	movl	%edi, -8(%rbp)
	movl	-4(%rbp), %r8d
	movl	$1, %r9d
	subl	%r9d, %r8d
	subq	$4, %rsp
	movl	%r8d, -12(%rbp)
	movl	-12(%rbp), %r8d
	subq	$4, %rsp
	movl	%r8d, -16(%rbp)
	call	f
	subq	$4, %rsp
	movl	%eax, -20(%rbp)
	movl	-4(%rbp), %r8d
	movl	-20(%rbp), %r9d
	imull	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -24(%rbp)
	movl	-24(%rbp), %r9d
	movl	%r9d, -8(%rbp)
	movl	-8(%rbp), %eax
	addq	$24, %rsp
	popq	%r9
	popq	%r8
	popq	%rbp
	ret
	addq	$24, %rsp
	popq	%r9
	popq	%r8
	popq	%rbp
	ret
	.globl	main
	.type	main, @function
main:
	pushq	%rbp
	pushq	%r8
	pushq	%r9
	movq	%rsp, %rbp
	subq	$16, %rsp
	movl	$10, %r8d
	subq	$4, %rsp
	movl	%r8d, -20(%rbp)
	call	f
	subq	$4, %rsp
	movl	%eax, -24(%rbp)
	movl	-24(%rbp), %edi
	subq	$4, %rsp
	movl	%edi, -28(%rbp)
.L4:
	movl	-28(%rbp), %r8d
	movl	$3628800, %r9d
	cmpl	%r9d, %r8d
	jne	.L6
	je	.L5
.L5:
	movl	-28(%rbp), %r8d
	cmpl	$0, %r8d
	jne	.L6
	je	.L13
.L6:
	subq	$4, %rsp
	movl	$2333, %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	-28(%rbp), %eax
	testl	%eax, %eax
	sete	%al
	movzbl	%al, %eax
	subq	$4, %rsp
	movl	%eax, -36(%rbp)
.L7:
	movl	-36(%rbp), %r8d
	cmpl	$0, %r8d
	jne	.L8
	je	.L10
.L8:
	subq	$12, %rsp
	movl	-28(%rbp), %r8d
	movl	$10, %r9d
	subl	%r9d, %r8d
	subq	$4, %rsp
	movl	%r8d, -52(%rbp)
	movl	-52(%rbp), %r9d
	movl	%r9d, -28(%rbp)
	addq	$16, %rsp
.L9:
	jmp	.L11
.L10:
	subq	$12, %rsp
	movl	-28(%rbp), %r8d
	movl	$10, %r9d
	addl	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -52(%rbp)
	movl	-52(%rbp), %r9d
	movl	%r9d, -28(%rbp)
	addq	$16, %rsp
.L11:
	addq	$8, %rsp
.L12:
	jmp	.L14
.L13:
	subq	$4, %rsp
	movl	-28(%rbp), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	addq	$4, %rsp
.L14:
	subq	$4, %rsp
	movl	-28(%rbp), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	$0, %edi
	subq	$4, %rsp
	movl	%edi, -36(%rbp)
	movl	$0, %edi
	subq	$4, %rsp
	movl	%edi, -40(%rbp)
.L15:
	subq	$8, %rsp
.L16:
	movl	-36(%rbp), %r8d
	movl	$3, %r9d
	cmpl	%r9d, %r8d
	jle	.L18
	jg	.L17
.L17:
	addq	$8, %rsp
	jmp	.L26
.L18:
.L19:
	movl	-36(%rbp), %r8d
	movl	$1, %r9d
	cmpl	%r9d, %r8d
	je	.L20
	jne	.L21
.L20:
	movl	-36(%rbp), %r8d
	movl	$1, %r9d
	addl	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -52(%rbp)
	movl	-52(%rbp), %r9d
	movl	%r9d, -36(%rbp)
	addq	$12, %rsp
	jmp	.L15
	addq	$4, %rsp
.L21:
.L22:
	movl	-36(%rbp), %r8d
	movl	$3, %r9d
	cmpl	%r9d, %r8d
	je	.L23
	jne	.L24
.L23:
	addq	$8, %rsp
	jmp	.L26
	addq	$0, %rsp
.L24:
	movl	-36(%rbp), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	-36(%rbp), %r8d
	movl	$1, %r9d
	addl	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -52(%rbp)
	movl	-52(%rbp), %r9d
	movl	%r9d, -36(%rbp)
.L25:
	addq	$12, %rsp
	jmp	.L15
.L26:
	subq	$72, %rsp
	movl	$1, %r9d
	movl	%r9d, -36(%rbp)
	movl	-36(%rbp), %r8d
	movl	-36(%rbp), %r9d
	addl	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -116(%rbp)
	movl	-116(%rbp), %r9d
	movl	%r9d, -40(%rbp)
	subq	$4, %rsp
	movl	$0, -120(%rbp)
	movl	$0, %r8d
	imull	$1, %r8d
	addl	-120(%rbp), %r8d
	movl	%r8d, -120(%rbp)
	movl	$0, %r8d
	imull	$6, %r8d
	addl	-120(%rbp), %r8d
	movl	%r8d, -120(%rbp)
	movl	-40(%rbp), %r8d
	movl	$2, %r9d
	imull	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -124(%rbp)
	movl	-36(%rbp), %r8d
	movl	-124(%rbp), %r9d
	addl	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -128(%rbp)
	movl	-128(%rbp), %r9d
	movl	-120(%rbp), %eax
	cltq
	movl	%r9d, -112(%rbp, %rax, 4)
	subq	$4, %rsp
	movl	$0, -132(%rbp)
	movl	-40(%rbp), %r8d
	imull	$1, %r8d
	addl	-132(%rbp), %r8d
	movl	%r8d, -132(%rbp)
	movl	-36(%rbp), %r8d
	imull	$6, %r8d
	addl	-132(%rbp), %r8d
	movl	%r8d, -132(%rbp)
	movl	$3, %r9d
	movl	-132(%rbp), %eax
	cltq
	movl	%r9d, -112(%rbp, %rax, 4)
	subq	$4, %rsp
	movl	$0, -136(%rbp)
	movl	$0, %r8d
	imull	$1, %r8d
	addl	-136(%rbp), %r8d
	movl	%r8d, -136(%rbp)
	movl	$0, %r8d
	imull	$6, %r8d
	addl	-136(%rbp), %r8d
	movl	%r8d, -136(%rbp)
	subq	$8, %rsp
	movl	-136(%rbp), %eax
	cltq
	movl	-112(%rbp, %rax, 4), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	subq	$4, %rsp
	movl	$0, -148(%rbp)
	movl	-40(%rbp), %r8d
	imull	$1, %r8d
	addl	-148(%rbp), %r8d
	movl	%r8d, -148(%rbp)
	movl	-36(%rbp), %r8d
	imull	$6, %r8d
	addl	-148(%rbp), %r8d
	movl	%r8d, -148(%rbp)
	subq	$12, %rsp
	movl	-148(%rbp), %eax
	cltq
	movl	-112(%rbp, %rax, 4), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	subq	$4, %rsp
	movl	$0, -164(%rbp)
	movl	-40(%rbp), %r8d
	imull	$1, %r8d
	addl	-164(%rbp), %r8d
	movl	%r8d, -164(%rbp)
	movl	-36(%rbp), %r8d
	imull	$6, %r8d
	addl	-164(%rbp), %r8d
	movl	%r8d, -164(%rbp)
	subq	$4, %rsp
	movl	$0, -168(%rbp)
	movl	$0, %r8d
	imull	$1, %r8d
	addl	-168(%rbp), %r8d
	movl	%r8d, -168(%rbp)
	movl	$0, %r8d
	imull	$6, %r8d
	addl	-168(%rbp), %r8d
	movl	%r8d, -168(%rbp)
	movl	-164(%rbp), %eax
	cltq
	movl	-112(%rbp, %rax, 4), %r8d
	movl	-168(%rbp), %eax
	cltq
	movl	-112(%rbp, %rax, 4), %r9d
	addl	%r8d, %r9d
	subq	$4, %rsp
	movl	%r9d, -172(%rbp)
	movl	-172(%rbp), %edi
	subq	$4, %rsp
	movl	%edi, -176(%rbp)
	movl	-176(%rbp), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	subq	$4, %rsp
	movl	$0, -180(%rbp)
	movl	$0, %r8d
	imull	$1, %r8d
	addl	-180(%rbp), %r8d
	movl	%r8d, -180(%rbp)
	movl	$0, %r8d
	imull	$6, %r8d
	addl	-180(%rbp), %r8d
	movl	%r8d, -180(%rbp)
	movl	$5, %r9d
	movl	-180(%rbp), %eax
	cltq
	leaq	0(, %rax, 4), %rdx
	leaq	a(%rip), %rax
	movl	%r9d, (%rdx, %rax)
	subq	$4, %rsp
	movl	$0, -184(%rbp)
	movl	$1, %r8d
	imull	$1, %r8d
	addl	-184(%rbp), %r8d
	movl	%r8d, -184(%rbp)
	movl	$1, %r8d
	imull	$6, %r8d
	addl	-184(%rbp), %r8d
	movl	%r8d, -184(%rbp)
	movl	$2, %r9d
	movl	-184(%rbp), %eax
	cltq
	leaq	0(, %rax, 4), %rdx
	leaq	a(%rip), %rax
	movl	%r9d, (%rdx, %rax)
	subq	$4, %rsp
	movl	$0, -188(%rbp)
	movl	$0, %r8d
	imull	$1, %r8d
	addl	-188(%rbp), %r8d
	movl	%r8d, -188(%rbp)
	movl	$0, %r8d
	imull	$6, %r8d
	addl	-188(%rbp), %r8d
	movl	%r8d, -188(%rbp)
	subq	$4, %rsp
	movl	-188(%rbp), %eax
	cltq
	leaq	0(, %rax, 4), %rdx
	leaq	a(%rip), %rax
	movl	(%rdx, %rax), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	subq	$4, %rsp
	movl	$0, -196(%rbp)
	movl	$1, %r8d
	imull	$1, %r8d
	addl	-196(%rbp), %r8d
	movl	%r8d, -196(%rbp)
	movl	$1, %r8d
	imull	$6, %r8d
	addl	-196(%rbp), %r8d
	movl	%r8d, -196(%rbp)
	subq	$12, %rsp
	movl	-196(%rbp), %eax
	cltq
	leaq	0(, %rax, 4), %rdx
	leaq	a(%rip), %rax
	movl	(%rdx, %rax), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	subq	$4, %rsp
	movl	$0, -212(%rbp)
	movl	$1, %r8d
	imull	$1, %r8d
	addl	-212(%rbp), %r8d
	movl	%r8d, -212(%rbp)
	movl	$1, %r8d
	imull	$6, %r8d
	addl	-212(%rbp), %r8d
	movl	%r8d, -212(%rbp)
	subq	$12, %rsp
	movl	-212(%rbp), %eax
	cltq
	leaq	0(, %rax, 4), %rdx
	leaq	a(%rip), %rax
leaq	(%rdx, %rax), %rsi
	leaq	.LC0(%rip), %rdi
	movl	$0, %eax
	call	__isoc99_scanf@PLT
	subq	$4, %rsp
	movl	$0, -228(%rbp)
	movl	$1, %r8d
	imull	$1, %r8d
	addl	-228(%rbp), %r8d
	movl	%r8d, -228(%rbp)
	movl	$1, %r8d
	imull	$6, %r8d
	addl	-228(%rbp), %r8d
	movl	%r8d, -228(%rbp)
	subq	$12, %rsp
	movl	-228(%rbp), %eax
	cltq
	leaq	0(, %rax, 4), %rdx
	leaq	a(%rip), %rax
	movl	(%rdx, %rax), %esi
	leaq	.LC1(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movl	$0, %eax
	addq	$240, %rsp
	popq	%r9
	popq	%r8
	popq	%rbp
	ret
	addq	$240, %rsp
	popq	%r9
	popq	%r8
	popq	%rbp
	ret

