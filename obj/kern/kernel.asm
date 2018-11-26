
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ae 22 f0    	mov    %esi,0xf022ae80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 a5 52 00 00       	call   f0105306 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 a0 59 10 f0       	push   $0xf01059a0
f010006d:	e8 e6 35 00 00       	call   f0103658 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b6 35 00 00       	call   f0103632 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 5c 5d 10 f0 	movl   $0xf0105d5c,(%esp)
f0100083:	e8 d0 35 00 00       	call   f0103658 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 ab 08 00 00       	call   f0100940 <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 c0 26 f0       	mov    $0xf026c008,%eax
f01000a6:	2d 98 95 22 f0       	sub    $0xf0229598,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 98 95 22 f0       	push   $0xf0229598
f01000b3:	e8 2c 4c 00 00       	call   f0104ce4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 6a 05 00 00       	call   f0100627 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 0c 5a 10 f0       	push   $0xf0105a0c
f01000ca:	e8 89 35 00 00       	call   f0103658 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 99 12 00 00       	call   f010136d <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 f7 2d 00 00       	call   f0102ed0 <env_init>
	trap_init();
f01000d9:	e8 6f 36 00 00       	call   f010374d <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 19 4f 00 00       	call   f0104ffc <mp_init>
	lapic_init();
f01000e3:	e8 39 52 00 00       	call   f0105321 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 92 34 00 00       	call   f010357f <pic_init>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ed:	83 c4 10             	add    $0x10,%esp
f01000f0:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f01000f7:	77 16                	ja     f010010f <i386_init+0x75>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01000f9:	68 00 70 00 00       	push   $0x7000
f01000fe:	68 c4 59 10 f0       	push   $0xf01059c4
f0100103:	6a 53                	push   $0x53
f0100105:	68 27 5a 10 f0       	push   $0xf0105a27
f010010a:	e8 31 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010010f:	83 ec 04             	sub    $0x4,%esp
f0100112:	b8 62 4f 10 f0       	mov    $0xf0104f62,%eax
f0100117:	2d e8 4e 10 f0       	sub    $0xf0104ee8,%eax
f010011c:	50                   	push   %eax
f010011d:	68 e8 4e 10 f0       	push   $0xf0104ee8
f0100122:	68 00 70 00 f0       	push   $0xf0007000
f0100127:	e8 05 4c 00 00       	call   f0104d31 <memmove>
f010012c:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010012f:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100134:	eb 4d                	jmp    f0100183 <i386_init+0xe9>
		if (c == cpus + cpunum())  // We've started already.
f0100136:	e8 cb 51 00 00       	call   f0105306 <cpunum>
f010013b:	6b c0 74             	imul   $0x74,%eax,%eax
f010013e:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0100143:	39 c3                	cmp    %eax,%ebx
f0100145:	74 39                	je     f0100180 <i386_init+0xe6>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100147:	89 d8                	mov    %ebx,%eax
f0100149:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
f010014e:	c1 f8 02             	sar    $0x2,%eax
f0100151:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100157:	c1 e0 0f             	shl    $0xf,%eax
f010015a:	05 00 40 23 f0       	add    $0xf0234000,%eax
f010015f:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100164:	83 ec 08             	sub    $0x8,%esp
f0100167:	68 00 70 00 00       	push   $0x7000
f010016c:	0f b6 03             	movzbl (%ebx),%eax
f010016f:	50                   	push   %eax
f0100170:	e8 fa 52 00 00       	call   f010546f <lapic_startap>
f0100175:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100178:	8b 43 04             	mov    0x4(%ebx),%eax
f010017b:	83 f8 01             	cmp    $0x1,%eax
f010017e:	75 f8                	jne    f0100178 <i386_init+0xde>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100180:	83 c3 74             	add    $0x74,%ebx
f0100183:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f010018a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	72 a3                	jb     f0100136 <i386_init+0x9c>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
f0100193:	83 ec 08             	sub    $0x8,%esp
f0100196:	6a 00                	push   $0x0
f0100198:	68 c8 0b 22 f0       	push   $0xf0220bc8
f010019d:	e8 fb 2e 00 00       	call   f010309d <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001a2:	e8 b8 3e 00 00       	call   f010405f <sched_yield>

f01001a7 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001ad:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001b7:	77 12                	ja     f01001cb <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001b9:	50                   	push   %eax
f01001ba:	68 e8 59 10 f0       	push   $0xf01059e8
f01001bf:	6a 6a                	push   $0x6a
f01001c1:	68 27 5a 10 f0       	push   $0xf0105a27
f01001c6:	e8 75 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001d0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001d3:	e8 2e 51 00 00       	call   f0105306 <cpunum>
f01001d8:	83 ec 08             	sub    $0x8,%esp
f01001db:	50                   	push   %eax
f01001dc:	68 33 5a 10 f0       	push   $0xf0105a33
f01001e1:	e8 72 34 00 00       	call   f0103658 <cprintf>

	lapic_init();
f01001e6:	e8 36 51 00 00       	call   f0105321 <lapic_init>
	env_init_percpu();
f01001eb:	e8 b0 2c 00 00       	call   f0102ea0 <env_init_percpu>
	trap_init_percpu();
f01001f0:	e8 77 34 00 00       	call   f010366c <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001f5:	e8 0c 51 00 00       	call   f0105306 <cpunum>
f01001fa:	6b d0 74             	imul   $0x74,%eax,%edx
f01001fd:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100203:	b8 01 00 00 00       	mov    $0x1,%eax
f0100208:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010020c:	83 c4 10             	add    $0x10,%esp
f010020f:	eb fe                	jmp    f010020f <mp_main+0x68>

f0100211 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100211:	55                   	push   %ebp
f0100212:	89 e5                	mov    %esp,%ebp
f0100214:	53                   	push   %ebx
f0100215:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100218:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010021b:	ff 75 0c             	pushl  0xc(%ebp)
f010021e:	ff 75 08             	pushl  0x8(%ebp)
f0100221:	68 49 5a 10 f0       	push   $0xf0105a49
f0100226:	e8 2d 34 00 00       	call   f0103658 <cprintf>
	vcprintf(fmt, ap);
f010022b:	83 c4 08             	add    $0x8,%esp
f010022e:	53                   	push   %ebx
f010022f:	ff 75 10             	pushl  0x10(%ebp)
f0100232:	e8 fb 33 00 00       	call   f0103632 <vcprintf>
	cprintf("\n");
f0100237:	c7 04 24 5c 5d 10 f0 	movl   $0xf0105d5c,(%esp)
f010023e:	e8 15 34 00 00       	call   f0103658 <cprintf>
	va_end(ap);
}
f0100243:	83 c4 10             	add    $0x10,%esp
f0100246:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100249:	c9                   	leave  
f010024a:	c3                   	ret    

f010024b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010024b:	55                   	push   %ebp
f010024c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010024e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100253:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100254:	a8 01                	test   $0x1,%al
f0100256:	74 0b                	je     f0100263 <serial_proc_data+0x18>
f0100258:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010025d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010025e:	0f b6 c0             	movzbl %al,%eax
f0100261:	eb 05                	jmp    f0100268 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100263:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100268:	5d                   	pop    %ebp
f0100269:	c3                   	ret    

f010026a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010026a:	55                   	push   %ebp
f010026b:	89 e5                	mov    %esp,%ebp
f010026d:	53                   	push   %ebx
f010026e:	83 ec 04             	sub    $0x4,%esp
f0100271:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100273:	eb 2b                	jmp    f01002a0 <cons_intr+0x36>
		if (c == 0)
f0100275:	85 c0                	test   %eax,%eax
f0100277:	74 27                	je     f01002a0 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100279:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f010027f:	8d 51 01             	lea    0x1(%ecx),%edx
f0100282:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f0100288:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010028e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100294:	75 0a                	jne    f01002a0 <cons_intr+0x36>
			cons.wpos = 0;
f0100296:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
f010029d:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002a0:	ff d3                	call   *%ebx
f01002a2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002a5:	75 ce                	jne    f0100275 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002a7:	83 c4 04             	add    $0x4,%esp
f01002aa:	5b                   	pop    %ebx
f01002ab:	5d                   	pop    %ebp
f01002ac:	c3                   	ret    

f01002ad <kbd_proc_data>:
f01002ad:	ba 64 00 00 00       	mov    $0x64,%edx
f01002b2:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002b3:	a8 01                	test   $0x1,%al
f01002b5:	0f 84 f8 00 00 00    	je     f01003b3 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002bb:	a8 20                	test   $0x20,%al
f01002bd:	0f 85 f6 00 00 00    	jne    f01003b9 <kbd_proc_data+0x10c>
f01002c3:	ba 60 00 00 00       	mov    $0x60,%edx
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002cb:	3c e0                	cmp    $0xe0,%al
f01002cd:	75 0d                	jne    f01002dc <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002cf:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
		return 0;
f01002d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01002db:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002e3:	84 c0                	test   %al,%al
f01002e5:	79 36                	jns    f010031d <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002e7:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f01002ed:	89 cb                	mov    %ecx,%ebx
f01002ef:	83 e3 40             	and    $0x40,%ebx
f01002f2:	83 e0 7f             	and    $0x7f,%eax
f01002f5:	85 db                	test   %ebx,%ebx
f01002f7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002fa:	0f b6 d2             	movzbl %dl,%edx
f01002fd:	0f b6 82 c0 5b 10 f0 	movzbl -0xfefa440(%edx),%eax
f0100304:	83 c8 40             	or     $0x40,%eax
f0100307:	0f b6 c0             	movzbl %al,%eax
f010030a:	f7 d0                	not    %eax
f010030c:	21 c8                	and    %ecx,%eax
f010030e:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f0100313:	b8 00 00 00 00       	mov    $0x0,%eax
f0100318:	e9 a4 00 00 00       	jmp    f01003c1 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f010031d:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f0100323:	f6 c1 40             	test   $0x40,%cl
f0100326:	74 0e                	je     f0100336 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100328:	83 c8 80             	or     $0xffffff80,%eax
f010032b:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010032d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100330:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f0100336:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100339:	0f b6 82 c0 5b 10 f0 	movzbl -0xfefa440(%edx),%eax
f0100340:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f0100346:	0f b6 8a c0 5a 10 f0 	movzbl -0xfefa540(%edx),%ecx
f010034d:	31 c8                	xor    %ecx,%eax
f010034f:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100354:	89 c1                	mov    %eax,%ecx
f0100356:	83 e1 03             	and    $0x3,%ecx
f0100359:	8b 0c 8d a0 5a 10 f0 	mov    -0xfefa560(,%ecx,4),%ecx
f0100360:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100364:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100367:	a8 08                	test   $0x8,%al
f0100369:	74 1b                	je     f0100386 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010036b:	89 da                	mov    %ebx,%edx
f010036d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100370:	83 f9 19             	cmp    $0x19,%ecx
f0100373:	77 05                	ja     f010037a <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100375:	83 eb 20             	sub    $0x20,%ebx
f0100378:	eb 0c                	jmp    f0100386 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010037a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010037d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100380:	83 fa 19             	cmp    $0x19,%edx
f0100383:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100386:	f7 d0                	not    %eax
f0100388:	a8 06                	test   $0x6,%al
f010038a:	75 33                	jne    f01003bf <kbd_proc_data+0x112>
f010038c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100392:	75 2b                	jne    f01003bf <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100394:	83 ec 0c             	sub    $0xc,%esp
f0100397:	68 63 5a 10 f0       	push   $0xf0105a63
f010039c:	e8 b7 32 00 00       	call   f0103658 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003a1:	ba 92 00 00 00       	mov    $0x92,%edx
f01003a6:	b8 03 00 00 00       	mov    $0x3,%eax
f01003ab:	ee                   	out    %al,(%dx)
f01003ac:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003af:	89 d8                	mov    %ebx,%eax
f01003b1:	eb 0e                	jmp    f01003c1 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003b8:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003be:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003bf:	89 d8                	mov    %ebx,%eax
}
f01003c1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003c4:	c9                   	leave  
f01003c5:	c3                   	ret    

f01003c6 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003c6:	55                   	push   %ebp
f01003c7:	89 e5                	mov    %esp,%ebp
f01003c9:	57                   	push   %edi
f01003ca:	56                   	push   %esi
f01003cb:	53                   	push   %ebx
f01003cc:	83 ec 1c             	sub    $0x1c,%esp
f01003cf:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003d1:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003d6:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003db:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003e0:	eb 09                	jmp    f01003eb <cons_putc+0x25>
f01003e2:	89 ca                	mov    %ecx,%edx
f01003e4:	ec                   	in     (%dx),%al
f01003e5:	ec                   	in     (%dx),%al
f01003e6:	ec                   	in     (%dx),%al
f01003e7:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003e8:	83 c3 01             	add    $0x1,%ebx
f01003eb:	89 f2                	mov    %esi,%edx
f01003ed:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003ee:	a8 20                	test   $0x20,%al
f01003f0:	75 08                	jne    f01003fa <cons_putc+0x34>
f01003f2:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003f8:	7e e8                	jle    f01003e2 <cons_putc+0x1c>
f01003fa:	89 f8                	mov    %edi,%eax
f01003fc:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ff:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100404:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100405:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010040a:	be 79 03 00 00       	mov    $0x379,%esi
f010040f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100414:	eb 09                	jmp    f010041f <cons_putc+0x59>
f0100416:	89 ca                	mov    %ecx,%edx
f0100418:	ec                   	in     (%dx),%al
f0100419:	ec                   	in     (%dx),%al
f010041a:	ec                   	in     (%dx),%al
f010041b:	ec                   	in     (%dx),%al
f010041c:	83 c3 01             	add    $0x1,%ebx
f010041f:	89 f2                	mov    %esi,%edx
f0100421:	ec                   	in     (%dx),%al
f0100422:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100428:	7f 04                	jg     f010042e <cons_putc+0x68>
f010042a:	84 c0                	test   %al,%al
f010042c:	79 e8                	jns    f0100416 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010042e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100433:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100437:	ee                   	out    %al,(%dx)
f0100438:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010043d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100442:	ee                   	out    %al,(%dx)
f0100443:	b8 08 00 00 00       	mov    $0x8,%eax
f0100448:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100449:	89 fa                	mov    %edi,%edx
f010044b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100451:	89 f8                	mov    %edi,%eax
f0100453:	80 cc 07             	or     $0x7,%ah
f0100456:	85 d2                	test   %edx,%edx
f0100458:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010045b:	89 f8                	mov    %edi,%eax
f010045d:	0f b6 c0             	movzbl %al,%eax
f0100460:	83 f8 09             	cmp    $0x9,%eax
f0100463:	74 74                	je     f01004d9 <cons_putc+0x113>
f0100465:	83 f8 09             	cmp    $0x9,%eax
f0100468:	7f 0a                	jg     f0100474 <cons_putc+0xae>
f010046a:	83 f8 08             	cmp    $0x8,%eax
f010046d:	74 14                	je     f0100483 <cons_putc+0xbd>
f010046f:	e9 99 00 00 00       	jmp    f010050d <cons_putc+0x147>
f0100474:	83 f8 0a             	cmp    $0xa,%eax
f0100477:	74 3a                	je     f01004b3 <cons_putc+0xed>
f0100479:	83 f8 0d             	cmp    $0xd,%eax
f010047c:	74 3d                	je     f01004bb <cons_putc+0xf5>
f010047e:	e9 8a 00 00 00       	jmp    f010050d <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100483:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010048a:	66 85 c0             	test   %ax,%ax
f010048d:	0f 84 e6 00 00 00    	je     f0100579 <cons_putc+0x1b3>
			crt_pos--;
f0100493:	83 e8 01             	sub    $0x1,%eax
f0100496:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010049c:	0f b7 c0             	movzwl %ax,%eax
f010049f:	66 81 e7 00 ff       	and    $0xff00,%di
f01004a4:	83 cf 20             	or     $0x20,%edi
f01004a7:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004ad:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b1:	eb 78                	jmp    f010052b <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004b3:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004ba:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004bb:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004c2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004c8:	c1 e8 16             	shr    $0x16,%eax
f01004cb:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004ce:	c1 e0 04             	shl    $0x4,%eax
f01004d1:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004d7:	eb 52                	jmp    f010052b <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01004de:	e8 e3 fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f01004e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e8:	e8 d9 fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f01004ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f2:	e8 cf fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f01004f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fc:	e8 c5 fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f0100501:	b8 20 00 00 00       	mov    $0x20,%eax
f0100506:	e8 bb fe ff ff       	call   f01003c6 <cons_putc>
f010050b:	eb 1e                	jmp    f010052b <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010050d:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f0100514:	8d 50 01             	lea    0x1(%eax),%edx
f0100517:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f010051e:	0f b7 c0             	movzwl %ax,%eax
f0100521:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f0100527:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010052b:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f0100532:	cf 07 
f0100534:	76 43                	jbe    f0100579 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100536:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f010053b:	83 ec 04             	sub    $0x4,%esp
f010053e:	68 00 0f 00 00       	push   $0xf00
f0100543:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100549:	52                   	push   %edx
f010054a:	50                   	push   %eax
f010054b:	e8 e1 47 00 00       	call   f0104d31 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100550:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f0100556:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010055c:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100562:	83 c4 10             	add    $0x10,%esp
f0100565:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010056a:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010056d:	39 d0                	cmp    %edx,%eax
f010056f:	75 f4                	jne    f0100565 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100571:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f0100578:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100579:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f010057f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100584:	89 ca                	mov    %ecx,%edx
f0100586:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100587:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f010058e:	8d 71 01             	lea    0x1(%ecx),%esi
f0100591:	89 d8                	mov    %ebx,%eax
f0100593:	66 c1 e8 08          	shr    $0x8,%ax
f0100597:	89 f2                	mov    %esi,%edx
f0100599:	ee                   	out    %al,(%dx)
f010059a:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	89 d8                	mov    %ebx,%eax
f01005a4:	89 f2                	mov    %esi,%edx
f01005a6:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005aa:	5b                   	pop    %ebx
f01005ab:	5e                   	pop    %esi
f01005ac:	5f                   	pop    %edi
f01005ad:	5d                   	pop    %ebp
f01005ae:	c3                   	ret    

f01005af <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005af:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005b6:	74 11                	je     f01005c9 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005b8:	55                   	push   %ebp
f01005b9:	89 e5                	mov    %esp,%ebp
f01005bb:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005be:	b8 4b 02 10 f0       	mov    $0xf010024b,%eax
f01005c3:	e8 a2 fc ff ff       	call   f010026a <cons_intr>
}
f01005c8:	c9                   	leave  
f01005c9:	f3 c3                	repz ret 

f01005cb <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005cb:	55                   	push   %ebp
f01005cc:	89 e5                	mov    %esp,%ebp
f01005ce:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005d1:	b8 ad 02 10 f0       	mov    $0xf01002ad,%eax
f01005d6:	e8 8f fc ff ff       	call   f010026a <cons_intr>
}
f01005db:	c9                   	leave  
f01005dc:	c3                   	ret    

f01005dd <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005dd:	55                   	push   %ebp
f01005de:	89 e5                	mov    %esp,%ebp
f01005e0:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005e3:	e8 c7 ff ff ff       	call   f01005af <serial_intr>
	kbd_intr();
f01005e8:	e8 de ff ff ff       	call   f01005cb <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005ed:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f01005f2:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f01005f8:	74 26                	je     f0100620 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01005fa:	8d 50 01             	lea    0x1(%eax),%edx
f01005fd:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f0100603:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010060a:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010060c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100612:	75 11                	jne    f0100625 <cons_getc+0x48>
			cons.rpos = 0;
f0100614:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f010061b:	00 00 00 
f010061e:	eb 05                	jmp    f0100625 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100620:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100625:	c9                   	leave  
f0100626:	c3                   	ret    

f0100627 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100627:	55                   	push   %ebp
f0100628:	89 e5                	mov    %esp,%ebp
f010062a:	57                   	push   %edi
f010062b:	56                   	push   %esi
f010062c:	53                   	push   %ebx
f010062d:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100630:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100637:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010063e:	5a a5 
	if (*cp != 0xA55A) {
f0100640:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100647:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010064b:	74 11                	je     f010065e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010064d:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f0100654:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100657:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010065c:	eb 16                	jmp    f0100674 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010065e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100665:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f010066c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010066f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100674:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f010067a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010067f:	89 fa                	mov    %edi,%edx
f0100681:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100682:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100685:	89 da                	mov    %ebx,%edx
f0100687:	ec                   	in     (%dx),%al
f0100688:	0f b6 c8             	movzbl %al,%ecx
f010068b:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010068e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100693:	89 fa                	mov    %edi,%edx
f0100695:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100696:	89 da                	mov    %ebx,%edx
f0100698:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100699:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f010069f:	0f b6 c0             	movzbl %al,%eax
f01006a2:	09 c8                	or     %ecx,%eax
f01006a4:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006aa:	e8 1c ff ff ff       	call   f01005cb <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006af:	83 ec 0c             	sub    $0xc,%esp
f01006b2:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006b9:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006be:	50                   	push   %eax
f01006bf:	e8 43 2e 00 00       	call   f0103507 <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c4:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ce:	89 f2                	mov    %esi,%edx
f01006d0:	ee                   	out    %al,(%dx)
f01006d1:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006d6:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006db:	ee                   	out    %al,(%dx)
f01006dc:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006e1:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006e6:	89 da                	mov    %ebx,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01006ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006f9:	b8 03 00 00 00       	mov    $0x3,%eax
f01006fe:	ee                   	out    %al,(%dx)
f01006ff:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100704:	b8 00 00 00 00       	mov    $0x0,%eax
f0100709:	ee                   	out    %al,(%dx)
f010070a:	ba f9 03 00 00       	mov    $0x3f9,%edx
f010070f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100714:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100715:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010071a:	ec                   	in     (%dx),%al
f010071b:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010071d:	83 c4 10             	add    $0x10,%esp
f0100720:	3c ff                	cmp    $0xff,%al
f0100722:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f0100729:	89 f2                	mov    %esi,%edx
f010072b:	ec                   	in     (%dx),%al
f010072c:	89 da                	mov    %ebx,%edx
f010072e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010072f:	80 f9 ff             	cmp    $0xff,%cl
f0100732:	75 10                	jne    f0100744 <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f0100734:	83 ec 0c             	sub    $0xc,%esp
f0100737:	68 6f 5a 10 f0       	push   $0xf0105a6f
f010073c:	e8 17 2f 00 00       	call   f0103658 <cprintf>
f0100741:	83 c4 10             	add    $0x10,%esp
}
f0100744:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100747:	5b                   	pop    %ebx
f0100748:	5e                   	pop    %esi
f0100749:	5f                   	pop    %edi
f010074a:	5d                   	pop    %ebp
f010074b:	c3                   	ret    

f010074c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010074c:	55                   	push   %ebp
f010074d:	89 e5                	mov    %esp,%ebp
f010074f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100752:	8b 45 08             	mov    0x8(%ebp),%eax
f0100755:	e8 6c fc ff ff       	call   f01003c6 <cons_putc>
}
f010075a:	c9                   	leave  
f010075b:	c3                   	ret    

f010075c <getchar>:

int
getchar(void)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100762:	e8 76 fe ff ff       	call   f01005dd <cons_getc>
f0100767:	85 c0                	test   %eax,%eax
f0100769:	74 f7                	je     f0100762 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010076b:	c9                   	leave  
f010076c:	c3                   	ret    

f010076d <iscons>:

int
iscons(int fdnum)
{
f010076d:	55                   	push   %ebp
f010076e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100770:	b8 01 00 00 00       	mov    $0x1,%eax
f0100775:	5d                   	pop    %ebp
f0100776:	c3                   	ret    

f0100777 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010077d:	68 c0 5c 10 f0       	push   $0xf0105cc0
f0100782:	68 de 5c 10 f0       	push   $0xf0105cde
f0100787:	68 e3 5c 10 f0       	push   $0xf0105ce3
f010078c:	e8 c7 2e 00 00       	call   f0103658 <cprintf>
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	68 9c 5d 10 f0       	push   $0xf0105d9c
f0100799:	68 ec 5c 10 f0       	push   $0xf0105cec
f010079e:	68 e3 5c 10 f0       	push   $0xf0105ce3
f01007a3:	e8 b0 2e 00 00       	call   f0103658 <cprintf>
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	68 c4 5d 10 f0       	push   $0xf0105dc4
f01007b0:	68 f5 5c 10 f0       	push   $0xf0105cf5
f01007b5:	68 e3 5c 10 f0       	push   $0xf0105ce3
f01007ba:	e8 99 2e 00 00       	call   f0103658 <cprintf>
	return 0;
}
f01007bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c4:	c9                   	leave  
f01007c5:	c3                   	ret    

f01007c6 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c6:	55                   	push   %ebp
f01007c7:	89 e5                	mov    %esp,%ebp
f01007c9:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007cc:	68 ff 5c 10 f0       	push   $0xf0105cff
f01007d1:	e8 82 2e 00 00       	call   f0103658 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d6:	83 c4 08             	add    $0x8,%esp
f01007d9:	68 0c 00 10 00       	push   $0x10000c
f01007de:	68 f0 5d 10 f0       	push   $0xf0105df0
f01007e3:	e8 70 2e 00 00       	call   f0103658 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	68 0c 00 10 00       	push   $0x10000c
f01007f0:	68 0c 00 10 f0       	push   $0xf010000c
f01007f5:	68 18 5e 10 f0       	push   $0xf0105e18
f01007fa:	e8 59 2e 00 00       	call   f0103658 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ff:	83 c4 0c             	add    $0xc,%esp
f0100802:	68 81 59 10 00       	push   $0x105981
f0100807:	68 81 59 10 f0       	push   $0xf0105981
f010080c:	68 3c 5e 10 f0       	push   $0xf0105e3c
f0100811:	e8 42 2e 00 00       	call   f0103658 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100816:	83 c4 0c             	add    $0xc,%esp
f0100819:	68 98 95 22 00       	push   $0x229598
f010081e:	68 98 95 22 f0       	push   $0xf0229598
f0100823:	68 60 5e 10 f0       	push   $0xf0105e60
f0100828:	e8 2b 2e 00 00       	call   f0103658 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082d:	83 c4 0c             	add    $0xc,%esp
f0100830:	68 08 c0 26 00       	push   $0x26c008
f0100835:	68 08 c0 26 f0       	push   $0xf026c008
f010083a:	68 84 5e 10 f0       	push   $0xf0105e84
f010083f:	e8 14 2e 00 00       	call   f0103658 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100844:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f0100849:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010084e:	83 c4 08             	add    $0x8,%esp
f0100851:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100856:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010085c:	85 c0                	test   %eax,%eax
f010085e:	0f 48 c2             	cmovs  %edx,%eax
f0100861:	c1 f8 0a             	sar    $0xa,%eax
f0100864:	50                   	push   %eax
f0100865:	68 a8 5e 10 f0       	push   $0xf0105ea8
f010086a:	e8 e9 2d 00 00       	call   f0103658 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010086f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100874:	c9                   	leave  
f0100875:	c3                   	ret    

f0100876 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100876:	55                   	push   %ebp
f0100877:	89 e5                	mov    %esp,%ebp
f0100879:	57                   	push   %edi
f010087a:	56                   	push   %esi
f010087b:	53                   	push   %ebx
f010087c:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010087f:	89 eb                	mov    %ebp,%ebx
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
f0100881:	68 18 5d 10 f0       	push   $0xf0105d18
f0100886:	e8 cd 2d 00 00       	call   f0103658 <cprintf>
	while(ebp)
f010088b:	83 c4 10             	add    $0x10,%esp
		cprintf("%08x ", *(ebp+3));
		cprintf("%08x ", *(ebp+4));
		cprintf("%08x ", *(ebp+5));
		cprintf("%08x", *(ebp+6));

		if(debuginfo_eip(eip, &info) == 0)
f010088e:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f0100891:	e9 95 00 00 00       	jmp    f010092b <mon_backtrace+0xb5>
	{
		eip = *(ebp+1);
f0100896:	8b 73 04             	mov    0x4(%ebx),%esi

		cprintf("ebp %08x  eip %08x  args ", ebp, eip);
f0100899:	83 ec 04             	sub    $0x4,%esp
f010089c:	56                   	push   %esi
f010089d:	53                   	push   %ebx
f010089e:	68 2b 5d 10 f0       	push   $0xf0105d2b
f01008a3:	e8 b0 2d 00 00       	call   f0103658 <cprintf>
		cprintf("%08x ", *(ebp+2));
f01008a8:	83 c4 08             	add    $0x8,%esp
f01008ab:	ff 73 08             	pushl  0x8(%ebx)
f01008ae:	68 45 5d 10 f0       	push   $0xf0105d45
f01008b3:	e8 a0 2d 00 00       	call   f0103658 <cprintf>
		cprintf("%08x ", *(ebp+3));
f01008b8:	83 c4 08             	add    $0x8,%esp
f01008bb:	ff 73 0c             	pushl  0xc(%ebx)
f01008be:	68 45 5d 10 f0       	push   $0xf0105d45
f01008c3:	e8 90 2d 00 00       	call   f0103658 <cprintf>
		cprintf("%08x ", *(ebp+4));
f01008c8:	83 c4 08             	add    $0x8,%esp
f01008cb:	ff 73 10             	pushl  0x10(%ebx)
f01008ce:	68 45 5d 10 f0       	push   $0xf0105d45
f01008d3:	e8 80 2d 00 00       	call   f0103658 <cprintf>
		cprintf("%08x ", *(ebp+5));
f01008d8:	83 c4 08             	add    $0x8,%esp
f01008db:	ff 73 14             	pushl  0x14(%ebx)
f01008de:	68 45 5d 10 f0       	push   $0xf0105d45
f01008e3:	e8 70 2d 00 00       	call   f0103658 <cprintf>
		cprintf("%08x", *(ebp+6));
f01008e8:	83 c4 08             	add    $0x8,%esp
f01008eb:	ff 73 18             	pushl  0x18(%ebx)
f01008ee:	68 e2 6d 10 f0       	push   $0xf0106de2
f01008f3:	e8 60 2d 00 00       	call   f0103658 <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01008f8:	83 c4 08             	add    $0x8,%esp
f01008fb:	57                   	push   %edi
f01008fc:	56                   	push   %esi
f01008fd:	e8 70 39 00 00       	call   f0104272 <debuginfo_eip>
f0100902:	83 c4 10             	add    $0x10,%esp
f0100905:	85 c0                	test   %eax,%eax
f0100907:	75 20                	jne    f0100929 <mon_backtrace+0xb3>
		{
			cprintf("\t %s:%d: %.*s+%d\n\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 											      info.eip_fn_name, eip-info.eip_fn_addr);
f0100909:	83 ec 08             	sub    $0x8,%esp
f010090c:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010090f:	56                   	push   %esi
f0100910:	ff 75 d8             	pushl  -0x28(%ebp)
f0100913:	ff 75 dc             	pushl  -0x24(%ebp)
f0100916:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100919:	ff 75 d0             	pushl  -0x30(%ebp)
f010091c:	68 4b 5d 10 f0       	push   $0xf0105d4b
f0100921:	e8 32 2d 00 00       	call   f0103658 <cprintf>
f0100926:	83 c4 20             	add    $0x20,%esp
		}

		ebp = (uint32_t*) *ebp;
f0100929:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f010092b:	85 db                	test   %ebx,%ebx
f010092d:	0f 85 63 ff ff ff    	jne    f0100896 <mon_backtrace+0x20>
		}

		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f0100933:	b8 00 00 00 00       	mov    $0x0,%eax
f0100938:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010093b:	5b                   	pop    %ebx
f010093c:	5e                   	pop    %esi
f010093d:	5f                   	pop    %edi
f010093e:	5d                   	pop    %ebp
f010093f:	c3                   	ret    

f0100940 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100940:	55                   	push   %ebp
f0100941:	89 e5                	mov    %esp,%ebp
f0100943:	57                   	push   %edi
f0100944:	56                   	push   %esi
f0100945:	53                   	push   %ebx
f0100946:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100949:	68 d4 5e 10 f0       	push   $0xf0105ed4
f010094e:	e8 05 2d 00 00       	call   f0103658 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100953:	c7 04 24 f8 5e 10 f0 	movl   $0xf0105ef8,(%esp)
f010095a:	e8 f9 2c 00 00       	call   f0103658 <cprintf>

	if (tf != NULL)
f010095f:	83 c4 10             	add    $0x10,%esp
f0100962:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100966:	74 0e                	je     f0100976 <monitor+0x36>
		print_trapframe(tf);
f0100968:	83 ec 0c             	sub    $0xc,%esp
f010096b:	ff 75 08             	pushl  0x8(%ebp)
f010096e:	e8 a6 31 00 00       	call   f0103b19 <print_trapframe>
f0100973:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100976:	83 ec 0c             	sub    $0xc,%esp
f0100979:	68 5e 5d 10 f0       	push   $0xf0105d5e
f010097e:	e8 0a 41 00 00       	call   f0104a8d <readline>
f0100983:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100985:	83 c4 10             	add    $0x10,%esp
f0100988:	85 c0                	test   %eax,%eax
f010098a:	74 ea                	je     f0100976 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010098c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100993:	be 00 00 00 00       	mov    $0x0,%esi
f0100998:	eb 0a                	jmp    f01009a4 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010099a:	c6 03 00             	movb   $0x0,(%ebx)
f010099d:	89 f7                	mov    %esi,%edi
f010099f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009a2:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009a4:	0f b6 03             	movzbl (%ebx),%eax
f01009a7:	84 c0                	test   %al,%al
f01009a9:	74 63                	je     f0100a0e <monitor+0xce>
f01009ab:	83 ec 08             	sub    $0x8,%esp
f01009ae:	0f be c0             	movsbl %al,%eax
f01009b1:	50                   	push   %eax
f01009b2:	68 62 5d 10 f0       	push   $0xf0105d62
f01009b7:	e8 eb 42 00 00       	call   f0104ca7 <strchr>
f01009bc:	83 c4 10             	add    $0x10,%esp
f01009bf:	85 c0                	test   %eax,%eax
f01009c1:	75 d7                	jne    f010099a <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009c3:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009c6:	74 46                	je     f0100a0e <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009c8:	83 fe 0f             	cmp    $0xf,%esi
f01009cb:	75 14                	jne    f01009e1 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009cd:	83 ec 08             	sub    $0x8,%esp
f01009d0:	6a 10                	push   $0x10
f01009d2:	68 67 5d 10 f0       	push   $0xf0105d67
f01009d7:	e8 7c 2c 00 00       	call   f0103658 <cprintf>
f01009dc:	83 c4 10             	add    $0x10,%esp
f01009df:	eb 95                	jmp    f0100976 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009e1:	8d 7e 01             	lea    0x1(%esi),%edi
f01009e4:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009e8:	eb 03                	jmp    f01009ed <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009ea:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009ed:	0f b6 03             	movzbl (%ebx),%eax
f01009f0:	84 c0                	test   %al,%al
f01009f2:	74 ae                	je     f01009a2 <monitor+0x62>
f01009f4:	83 ec 08             	sub    $0x8,%esp
f01009f7:	0f be c0             	movsbl %al,%eax
f01009fa:	50                   	push   %eax
f01009fb:	68 62 5d 10 f0       	push   $0xf0105d62
f0100a00:	e8 a2 42 00 00       	call   f0104ca7 <strchr>
f0100a05:	83 c4 10             	add    $0x10,%esp
f0100a08:	85 c0                	test   %eax,%eax
f0100a0a:	74 de                	je     f01009ea <monitor+0xaa>
f0100a0c:	eb 94                	jmp    f01009a2 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100a0e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a15:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a16:	85 f6                	test   %esi,%esi
f0100a18:	0f 84 58 ff ff ff    	je     f0100976 <monitor+0x36>
f0100a1e:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a23:	83 ec 08             	sub    $0x8,%esp
f0100a26:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a29:	ff 34 85 20 5f 10 f0 	pushl  -0xfefa0e0(,%eax,4)
f0100a30:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a33:	e8 11 42 00 00       	call   f0104c49 <strcmp>
f0100a38:	83 c4 10             	add    $0x10,%esp
f0100a3b:	85 c0                	test   %eax,%eax
f0100a3d:	75 21                	jne    f0100a60 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a3f:	83 ec 04             	sub    $0x4,%esp
f0100a42:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a45:	ff 75 08             	pushl  0x8(%ebp)
f0100a48:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a4b:	52                   	push   %edx
f0100a4c:	56                   	push   %esi
f0100a4d:	ff 14 85 28 5f 10 f0 	call   *-0xfefa0d8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a54:	83 c4 10             	add    $0x10,%esp
f0100a57:	85 c0                	test   %eax,%eax
f0100a59:	78 25                	js     f0100a80 <monitor+0x140>
f0100a5b:	e9 16 ff ff ff       	jmp    f0100976 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a60:	83 c3 01             	add    $0x1,%ebx
f0100a63:	83 fb 03             	cmp    $0x3,%ebx
f0100a66:	75 bb                	jne    f0100a23 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a68:	83 ec 08             	sub    $0x8,%esp
f0100a6b:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a6e:	68 84 5d 10 f0       	push   $0xf0105d84
f0100a73:	e8 e0 2b 00 00       	call   f0103658 <cprintf>
f0100a78:	83 c4 10             	add    $0x10,%esp
f0100a7b:	e9 f6 fe ff ff       	jmp    f0100976 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a80:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a83:	5b                   	pop    %ebx
f0100a84:	5e                   	pop    %esi
f0100a85:	5f                   	pop    %edi
f0100a86:	5d                   	pop    %ebp
f0100a87:	c3                   	ret    

f0100a88 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a88:	55                   	push   %ebp
f0100a89:	89 e5                	mov    %esp,%ebp
f0100a8b:	56                   	push   %esi
f0100a8c:	53                   	push   %ebx
f0100a8d:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a8f:	83 ec 0c             	sub    $0xc,%esp
f0100a92:	50                   	push   %eax
f0100a93:	e8 41 2a 00 00       	call   f01034d9 <mc146818_read>
f0100a98:	89 c6                	mov    %eax,%esi
f0100a9a:	83 c3 01             	add    $0x1,%ebx
f0100a9d:	89 1c 24             	mov    %ebx,(%esp)
f0100aa0:	e8 34 2a 00 00       	call   f01034d9 <mc146818_read>
f0100aa5:	c1 e0 08             	shl    $0x8,%eax
f0100aa8:	09 f0                	or     %esi,%eax
}
f0100aaa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100aad:	5b                   	pop    %ebx
f0100aae:	5e                   	pop    %esi
f0100aaf:	5d                   	pop    %ebp
f0100ab0:	c3                   	ret    

f0100ab1 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ab1:	89 d1                	mov    %edx,%ecx
f0100ab3:	c1 e9 16             	shr    $0x16,%ecx
f0100ab6:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100ab9:	a8 01                	test   $0x1,%al
f0100abb:	74 52                	je     f0100b0f <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100abd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ac2:	89 c1                	mov    %eax,%ecx
f0100ac4:	c1 e9 0c             	shr    $0xc,%ecx
f0100ac7:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100acd:	72 1b                	jb     f0100aea <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
f0100ad2:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ad5:	50                   	push   %eax
f0100ad6:	68 c4 59 10 f0       	push   $0xf01059c4
f0100adb:	68 c5 03 00 00       	push   $0x3c5
f0100ae0:	68 e5 68 10 f0       	push   $0xf01068e5
f0100ae5:	e8 56 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100aea:	c1 ea 0c             	shr    $0xc,%edx
f0100aed:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100af3:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100afa:	89 c2                	mov    %eax,%edx
f0100afc:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b04:	85 d2                	test   %edx,%edx
f0100b06:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b0b:	0f 44 c2             	cmove  %edx,%eax
f0100b0e:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b14:	c3                   	ret    

f0100b15 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b15:	55                   	push   %ebp
f0100b16:	89 e5                	mov    %esp,%ebp
f0100b18:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b1b:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100b22:	75 11                	jne    f0100b35 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b24:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100b29:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b2f:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	//
	// LAB 2: Your code here.
	if(n < 0) 
		panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) 
f0100b35:	85 c0                	test   %eax,%eax
f0100b37:	75 07                	jne    f0100b40 <boot_alloc+0x2b>
		return nextfree;
f0100b39:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
f0100b3e:	eb 54                	jmp    f0100b94 <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f0100b40:	8b 15 38 a2 22 f0    	mov    0xf022a238,%edx

		char* new = ROUNDUP(nextfree+n, PGSIZE);
f0100b46:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100b4d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b52:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b57:	77 12                	ja     f0100b6b <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b59:	50                   	push   %eax
f0100b5a:	68 e8 59 10 f0       	push   $0xf01059e8
f0100b5f:	6a 78                	push   $0x78
f0100b61:	68 e5 68 10 f0       	push   $0xf01068e5
f0100b66:	e8 d5 f4 ff ff       	call   f0100040 <_panic>

		if(PADDR(new) > 1024*1024*4) 
f0100b6b:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100b71:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100b77:	76 14                	jbe    f0100b8d <boot_alloc+0x78>
			panic("boot_alloc: not enough memory!\n");
f0100b79:	83 ec 04             	sub    $0x4,%esp
f0100b7c:	68 44 5f 10 f0       	push   $0xf0105f44
f0100b81:	6a 79                	push   $0x79
f0100b83:	68 e5 68 10 f0       	push   $0xf01068e5
f0100b88:	e8 b3 f4 ff ff       	call   f0100040 <_panic>

		else
		{
			nextfree = new;
f0100b8d:	a3 38 a2 22 f0       	mov    %eax,0xf022a238
		}
	}

	return result;
f0100b92:	89 d0                	mov    %edx,%eax
}
f0100b94:	c9                   	leave  
f0100b95:	c3                   	ret    

f0100b96 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b96:	55                   	push   %ebp
f0100b97:	89 e5                	mov    %esp,%ebp
f0100b99:	57                   	push   %edi
f0100b9a:	56                   	push   %esi
f0100b9b:	53                   	push   %ebx
f0100b9c:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b9f:	84 c0                	test   %al,%al
f0100ba1:	0f 85 a0 02 00 00    	jne    f0100e47 <check_page_free_list+0x2b1>
f0100ba7:	e9 ad 02 00 00       	jmp    f0100e59 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100bac:	83 ec 04             	sub    $0x4,%esp
f0100baf:	68 64 5f 10 f0       	push   $0xf0105f64
f0100bb4:	68 f8 02 00 00       	push   $0x2f8
f0100bb9:	68 e5 68 10 f0       	push   $0xf01068e5
f0100bbe:	e8 7d f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100bc3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bc6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100bc9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bcc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100bcf:	89 c2                	mov    %eax,%edx
f0100bd1:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0100bd7:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100bdd:	0f 95 c2             	setne  %dl
f0100be0:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100be3:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100be7:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100be9:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bed:	8b 00                	mov    (%eax),%eax
f0100bef:	85 c0                	test   %eax,%eax
f0100bf1:	75 dc                	jne    f0100bcf <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100bf3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bf6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100bfc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bff:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c02:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c07:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c0c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c11:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100c17:	eb 53                	jmp    f0100c6c <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c19:	89 d8                	mov    %ebx,%eax
f0100c1b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100c21:	c1 f8 03             	sar    $0x3,%eax
f0100c24:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c27:	89 c2                	mov    %eax,%edx
f0100c29:	c1 ea 16             	shr    $0x16,%edx
f0100c2c:	39 f2                	cmp    %esi,%edx
f0100c2e:	73 3a                	jae    f0100c6a <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c30:	89 c2                	mov    %eax,%edx
f0100c32:	c1 ea 0c             	shr    $0xc,%edx
f0100c35:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100c3b:	72 12                	jb     f0100c4f <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3d:	50                   	push   %eax
f0100c3e:	68 c4 59 10 f0       	push   $0xf01059c4
f0100c43:	6a 58                	push   $0x58
f0100c45:	68 f1 68 10 f0       	push   $0xf01068f1
f0100c4a:	e8 f1 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c4f:	83 ec 04             	sub    $0x4,%esp
f0100c52:	68 80 00 00 00       	push   $0x80
f0100c57:	68 97 00 00 00       	push   $0x97
f0100c5c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c61:	50                   	push   %eax
f0100c62:	e8 7d 40 00 00       	call   f0104ce4 <memset>
f0100c67:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c6a:	8b 1b                	mov    (%ebx),%ebx
f0100c6c:	85 db                	test   %ebx,%ebx
f0100c6e:	75 a9                	jne    f0100c19 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c75:	e8 9b fe ff ff       	call   f0100b15 <boot_alloc>
f0100c7a:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7d:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c83:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100c89:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100c8e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c91:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c94:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c97:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c9a:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c9f:	e9 52 01 00 00       	jmp    f0100df6 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ca4:	39 ca                	cmp    %ecx,%edx
f0100ca6:	73 19                	jae    f0100cc1 <check_page_free_list+0x12b>
f0100ca8:	68 ff 68 10 f0       	push   $0xf01068ff
f0100cad:	68 0b 69 10 f0       	push   $0xf010690b
f0100cb2:	68 12 03 00 00       	push   $0x312
f0100cb7:	68 e5 68 10 f0       	push   $0xf01068e5
f0100cbc:	e8 7f f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cc1:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cc4:	72 19                	jb     f0100cdf <check_page_free_list+0x149>
f0100cc6:	68 20 69 10 f0       	push   $0xf0106920
f0100ccb:	68 0b 69 10 f0       	push   $0xf010690b
f0100cd0:	68 13 03 00 00       	push   $0x313
f0100cd5:	68 e5 68 10 f0       	push   $0xf01068e5
f0100cda:	e8 61 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cdf:	89 d0                	mov    %edx,%eax
f0100ce1:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100ce4:	a8 07                	test   $0x7,%al
f0100ce6:	74 19                	je     f0100d01 <check_page_free_list+0x16b>
f0100ce8:	68 88 5f 10 f0       	push   $0xf0105f88
f0100ced:	68 0b 69 10 f0       	push   $0xf010690b
f0100cf2:	68 14 03 00 00       	push   $0x314
f0100cf7:	68 e5 68 10 f0       	push   $0xf01068e5
f0100cfc:	e8 3f f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d01:	c1 f8 03             	sar    $0x3,%eax
f0100d04:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d07:	85 c0                	test   %eax,%eax
f0100d09:	75 19                	jne    f0100d24 <check_page_free_list+0x18e>
f0100d0b:	68 34 69 10 f0       	push   $0xf0106934
f0100d10:	68 0b 69 10 f0       	push   $0xf010690b
f0100d15:	68 17 03 00 00       	push   $0x317
f0100d1a:	68 e5 68 10 f0       	push   $0xf01068e5
f0100d1f:	e8 1c f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d24:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d29:	75 19                	jne    f0100d44 <check_page_free_list+0x1ae>
f0100d2b:	68 45 69 10 f0       	push   $0xf0106945
f0100d30:	68 0b 69 10 f0       	push   $0xf010690b
f0100d35:	68 18 03 00 00       	push   $0x318
f0100d3a:	68 e5 68 10 f0       	push   $0xf01068e5
f0100d3f:	e8 fc f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d44:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d49:	75 19                	jne    f0100d64 <check_page_free_list+0x1ce>
f0100d4b:	68 bc 5f 10 f0       	push   $0xf0105fbc
f0100d50:	68 0b 69 10 f0       	push   $0xf010690b
f0100d55:	68 19 03 00 00       	push   $0x319
f0100d5a:	68 e5 68 10 f0       	push   $0xf01068e5
f0100d5f:	e8 dc f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d64:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d69:	75 19                	jne    f0100d84 <check_page_free_list+0x1ee>
f0100d6b:	68 5e 69 10 f0       	push   $0xf010695e
f0100d70:	68 0b 69 10 f0       	push   $0xf010690b
f0100d75:	68 1a 03 00 00       	push   $0x31a
f0100d7a:	68 e5 68 10 f0       	push   $0xf01068e5
f0100d7f:	e8 bc f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d84:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d89:	0f 86 f1 00 00 00    	jbe    f0100e80 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d8f:	89 c7                	mov    %eax,%edi
f0100d91:	c1 ef 0c             	shr    $0xc,%edi
f0100d94:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d97:	77 12                	ja     f0100dab <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d99:	50                   	push   %eax
f0100d9a:	68 c4 59 10 f0       	push   $0xf01059c4
f0100d9f:	6a 58                	push   $0x58
f0100da1:	68 f1 68 10 f0       	push   $0xf01068f1
f0100da6:	e8 95 f2 ff ff       	call   f0100040 <_panic>
f0100dab:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100db1:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100db4:	0f 86 b6 00 00 00    	jbe    f0100e70 <check_page_free_list+0x2da>
f0100dba:	68 e0 5f 10 f0       	push   $0xf0105fe0
f0100dbf:	68 0b 69 10 f0       	push   $0xf010690b
f0100dc4:	68 1b 03 00 00       	push   $0x31b
f0100dc9:	68 e5 68 10 f0       	push   $0xf01068e5
f0100dce:	e8 6d f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100dd3:	68 78 69 10 f0       	push   $0xf0106978
f0100dd8:	68 0b 69 10 f0       	push   $0xf010690b
f0100ddd:	68 1d 03 00 00       	push   $0x31d
f0100de2:	68 e5 68 10 f0       	push   $0xf01068e5
f0100de7:	e8 54 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100dec:	83 c6 01             	add    $0x1,%esi
f0100def:	eb 03                	jmp    f0100df4 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100df1:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100df4:	8b 12                	mov    (%edx),%edx
f0100df6:	85 d2                	test   %edx,%edx
f0100df8:	0f 85 a6 fe ff ff    	jne    f0100ca4 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dfe:	85 f6                	test   %esi,%esi
f0100e00:	7f 19                	jg     f0100e1b <check_page_free_list+0x285>
f0100e02:	68 95 69 10 f0       	push   $0xf0106995
f0100e07:	68 0b 69 10 f0       	push   $0xf010690b
f0100e0c:	68 25 03 00 00       	push   $0x325
f0100e11:	68 e5 68 10 f0       	push   $0xf01068e5
f0100e16:	e8 25 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e1b:	85 db                	test   %ebx,%ebx
f0100e1d:	7f 19                	jg     f0100e38 <check_page_free_list+0x2a2>
f0100e1f:	68 a7 69 10 f0       	push   $0xf01069a7
f0100e24:	68 0b 69 10 f0       	push   $0xf010690b
f0100e29:	68 26 03 00 00       	push   $0x326
f0100e2e:	68 e5 68 10 f0       	push   $0xf01068e5
f0100e33:	e8 08 f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e38:	83 ec 0c             	sub    $0xc,%esp
f0100e3b:	68 28 60 10 f0       	push   $0xf0106028
f0100e40:	e8 13 28 00 00       	call   f0103658 <cprintf>
}
f0100e45:	eb 49                	jmp    f0100e90 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e47:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100e4c:	85 c0                	test   %eax,%eax
f0100e4e:	0f 85 6f fd ff ff    	jne    f0100bc3 <check_page_free_list+0x2d>
f0100e54:	e9 53 fd ff ff       	jmp    f0100bac <check_page_free_list+0x16>
f0100e59:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100e60:	0f 84 46 fd ff ff    	je     f0100bac <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e66:	be 00 04 00 00       	mov    $0x400,%esi
f0100e6b:	e9 a1 fd ff ff       	jmp    f0100c11 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e70:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e75:	0f 85 76 ff ff ff    	jne    f0100df1 <check_page_free_list+0x25b>
f0100e7b:	e9 53 ff ff ff       	jmp    f0100dd3 <check_page_free_list+0x23d>
f0100e80:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e85:	0f 85 61 ff ff ff    	jne    f0100dec <check_page_free_list+0x256>
f0100e8b:	e9 43 ff ff ff       	jmp    f0100dd3 <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100e90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e93:	5b                   	pop    %ebx
f0100e94:	5e                   	pop    %esi
f0100e95:	5f                   	pop    %edi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	57                   	push   %edi
f0100e9c:	56                   	push   %esi
f0100e9d:	53                   	push   %ebx
f0100e9e:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	
f0100ea1:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100ea6:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

	for (i = 1; i < npages; ++i) 
f0100eac:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100eb1:	be 08 00 00 00       	mov    $0x8,%esi
f0100eb6:	bf 01 00 00 00       	mov    $0x1,%edi
f0100ebb:	e9 c5 00 00 00       	jmp    f0100f85 <page_init+0xed>
	{
		if((i*PGSIZE  >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM))
f0100ec0:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100ec6:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100ecb:	77 19                	ja     f0100ee6 <page_init+0x4e>
		{
			pages[i].pp_ref = 1;
f0100ecd:	89 f0                	mov    %esi,%eax
f0100ecf:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100ed5:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100edb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;	
f0100ee1:	e9 93 00 00 00       	jmp    f0100f79 <page_init+0xe1>
		}

		if((i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))))
f0100ee6:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100eec:	76 45                	jbe    f0100f33 <page_init+0x9b>
f0100eee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef3:	e8 1d fc ff ff       	call   f0100b15 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ef8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100efd:	77 15                	ja     f0100f14 <page_init+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100eff:	50                   	push   %eax
f0100f00:	68 e8 59 10 f0       	push   $0xf01059e8
f0100f05:	68 5a 01 00 00       	push   $0x15a
f0100f0a:	68 e5 68 10 f0       	push   $0xf01068e5
f0100f0f:	e8 2c f1 ff ff       	call   f0100040 <_panic>
f0100f14:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f19:	39 d8                	cmp    %ebx,%eax
f0100f1b:	76 16                	jbe    f0100f33 <page_init+0x9b>
		{
			pages[i].pp_ref = 1;
f0100f1d:	89 f0                	mov    %esi,%eax
f0100f1f:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100f25:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f2b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f31:	eb 46                	jmp    f0100f79 <page_init+0xe1>
		}

		if((i * PGSIZE >= MPENTRY_PADDR) && (i * PGSIZE < MPENTRY_PADDR + PGSIZE))
f0100f33:	8d 83 00 90 ff ff    	lea    -0x7000(%ebx),%eax
f0100f39:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0100f3e:	77 16                	ja     f0100f56 <page_init+0xbe>
		{
			pages[i].pp_ref = 1;
f0100f40:	89 f0                	mov    %esi,%eax
f0100f42:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100f48:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f4e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f54:	eb 23                	jmp    f0100f79 <page_init+0xe1>
		}
			
		pages[i].pp_ref = 0;  
f0100f56:	89 f0                	mov    %esi,%eax
f0100f58:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100f5e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f64:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f6a:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f6c:	89 f0                	mov    %esi,%eax
f0100f6e:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100f74:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	

	for (i = 1; i < npages; ++i) 
f0100f79:	83 c7 01             	add    $0x1,%edi
f0100f7c:	83 c6 08             	add    $0x8,%esi
f0100f7f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f85:	3b 3d 88 ae 22 f0    	cmp    0xf022ae88,%edi
f0100f8b:	0f 82 2f ff ff ff    	jb     f0100ec0 <page_init+0x28>
			
		pages[i].pp_ref = 0;  
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100f91:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f94:	5b                   	pop    %ebx
f0100f95:	5e                   	pop    %esi
f0100f96:	5f                   	pop    %edi
f0100f97:	5d                   	pop    %ebp
f0100f98:	c3                   	ret    

f0100f99 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f99:	55                   	push   %ebp
f0100f9a:	89 e5                	mov    %esp,%ebp
f0100f9c:	53                   	push   %ebx
f0100f9d:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL) 
f0100fa0:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100fa6:	85 db                	test   %ebx,%ebx
f0100fa8:	74 58                	je     f0101002 <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100faa:	8b 03                	mov    (%ebx),%eax
f0100fac:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	page->pp_link = NULL;
f0100fb1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100fb7:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fbb:	74 45                	je     f0101002 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fbd:	89 d8                	mov    %ebx,%eax
f0100fbf:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100fc5:	c1 f8 03             	sar    $0x3,%eax
f0100fc8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcb:	89 c2                	mov    %eax,%edx
f0100fcd:	c1 ea 0c             	shr    $0xc,%edx
f0100fd0:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100fd6:	72 12                	jb     f0100fea <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd8:	50                   	push   %eax
f0100fd9:	68 c4 59 10 f0       	push   $0xf01059c4
f0100fde:	6a 58                	push   $0x58
f0100fe0:	68 f1 68 10 f0       	push   $0xf01068f1
f0100fe5:	e8 56 f0 ff ff       	call   f0100040 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0100fea:	83 ec 04             	sub    $0x4,%esp
f0100fed:	68 00 10 00 00       	push   $0x1000
f0100ff2:	6a 00                	push   $0x0
f0100ff4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ff9:	50                   	push   %eax
f0100ffa:	e8 e5 3c 00 00       	call   f0104ce4 <memset>
f0100fff:	83 c4 10             	add    $0x10,%esp
	}

	return page;
}
f0101002:	89 d8                	mov    %ebx,%eax
f0101004:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101007:	c9                   	leave  
f0101008:	c3                   	ret    

f0101009 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101009:	55                   	push   %ebp
f010100a:	89 e5                	mov    %esp,%ebp
f010100c:	83 ec 08             	sub    $0x8,%esp
f010100f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref != 0) || (pp->pp_link != NULL)) 
f0101012:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101017:	75 05                	jne    f010101e <page_free+0x15>
f0101019:	83 38 00             	cmpl   $0x0,(%eax)
f010101c:	74 17                	je     f0101035 <page_free+0x2c>
		panic("page_free: cannot free the page which is still in use!\n");
f010101e:	83 ec 04             	sub    $0x4,%esp
f0101021:	68 4c 60 10 f0       	push   $0xf010604c
f0101026:	68 9b 01 00 00       	push   $0x19b
f010102b:	68 e5 68 10 f0       	push   $0xf01068e5
f0101030:	e8 0b f0 ff ff       	call   f0100040 <_panic>

	
	pp->pp_link  = page_free_list;
f0101035:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f010103b:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;	
f010103d:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
}
f0101042:	c9                   	leave  
f0101043:	c3                   	ret    

f0101044 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101044:	55                   	push   %ebp
f0101045:	89 e5                	mov    %esp,%ebp
f0101047:	83 ec 08             	sub    $0x8,%esp
f010104a:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010104d:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101051:	83 e8 01             	sub    $0x1,%eax
f0101054:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101058:	66 85 c0             	test   %ax,%ax
f010105b:	75 0c                	jne    f0101069 <page_decref+0x25>
		page_free(pp);
f010105d:	83 ec 0c             	sub    $0xc,%esp
f0101060:	52                   	push   %edx
f0101061:	e8 a3 ff ff ff       	call   f0101009 <page_free>
f0101066:	83 c4 10             	add    $0x10,%esp
}
f0101069:	c9                   	leave  
f010106a:	c3                   	ret    

f010106b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010106b:	55                   	push   %ebp
f010106c:	89 e5                	mov    %esp,%ebp
f010106e:	56                   	push   %esi
f010106f:	53                   	push   %ebx
f0101070:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	size_t dirIndex = PDX(va);
	size_t tableIndex = PTX(va);
f0101073:	89 de                	mov    %ebx,%esi
f0101075:	c1 ee 0c             	shr    $0xc,%esi
f0101078:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];
f010107e:	c1 eb 16             	shr    $0x16,%ebx
f0101081:	c1 e3 02             	shl    $0x2,%ebx
f0101084:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pdir_entry & PTE_P))
f0101087:	8b 03                	mov    (%ebx),%eax
f0101089:	a8 01                	test   $0x1,%al
f010108b:	75 6c                	jne    f01010f9 <pgdir_walk+0x8e>
	{
		if(create == false) 
f010108d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101091:	0f 84 93 00 00 00    	je     f010112a <pgdir_walk+0xbf>
			return NULL;

		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0101097:	83 ec 0c             	sub    $0xc,%esp
f010109a:	6a 01                	push   $0x1
f010109c:	e8 f8 fe ff ff       	call   f0100f99 <page_alloc>

		if(page == NULL) 
f01010a1:	83 c4 10             	add    $0x10,%esp
f01010a4:	85 c0                	test   %eax,%eax
f01010a6:	0f 84 85 00 00 00    	je     f0101131 <pgdir_walk+0xc6>
			return NULL;

		page->pp_ref++;
f01010ac:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

		*pdir_entry = page2pa(page) | PTE_P | PTE_W | PTE_U;
f01010b1:	89 c2                	mov    %eax,%edx
f01010b3:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f01010b9:	c1 fa 03             	sar    $0x3,%edx
f01010bc:	c1 e2 0c             	shl    $0xc,%edx
f01010bf:	83 ca 07             	or     $0x7,%edx
f01010c2:	89 13                	mov    %edx,(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010c4:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01010ca:	c1 f8 03             	sar    $0x3,%eax
f01010cd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010d0:	89 c2                	mov    %eax,%edx
f01010d2:	c1 ea 0c             	shr    $0xc,%edx
f01010d5:	39 15 88 ae 22 f0    	cmp    %edx,0xf022ae88
f01010db:	77 15                	ja     f01010f2 <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010dd:	50                   	push   %eax
f01010de:	68 c4 59 10 f0       	push   $0xf01059c4
f01010e3:	68 dd 01 00 00       	push   $0x1dd
f01010e8:	68 e5 68 10 f0       	push   $0xf01068e5
f01010ed:	e8 4e ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01010f2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010f7:	eb 2c                	jmp    f0101125 <pgdir_walk+0xba>
		
		ptable_entry = (pte_t*) KADDR(page2pa(page));
	}
	else
	{
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
f01010f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010fe:	89 c2                	mov    %eax,%edx
f0101100:	c1 ea 0c             	shr    $0xc,%edx
f0101103:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101109:	72 15                	jb     f0101120 <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010110b:	50                   	push   %eax
f010110c:	68 c4 59 10 f0       	push   $0xf01059c4
f0101111:	68 e1 01 00 00       	push   $0x1e1
f0101116:	68 e5 68 10 f0       	push   $0xf01068e5
f010111b:	e8 20 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101120:	2d 00 00 00 10       	sub    $0x10000000,%eax
	}
	
	return ptable_entry + tableIndex;
f0101125:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0101128:	eb 0c                	jmp    f0101136 <pgdir_walk+0xcb>
	pde_t *pdir_entry = &pgdir[dirIndex];

	if(!(*pdir_entry & PTE_P))
	{
		if(create == false) 
			return NULL;
f010112a:	b8 00 00 00 00       	mov    $0x0,%eax
f010112f:	eb 05                	jmp    f0101136 <pgdir_walk+0xcb>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);

		if(page == NULL) 
			return NULL;
f0101131:	b8 00 00 00 00       	mov    $0x0,%eax
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
	}
	
	return ptable_entry + tableIndex;

}
f0101136:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101139:	5b                   	pop    %ebx
f010113a:	5e                   	pop    %esi
f010113b:	5d                   	pop    %ebp
f010113c:	c3                   	ret    

f010113d <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010113d:	55                   	push   %ebp
f010113e:	89 e5                	mov    %esp,%ebp
f0101140:	57                   	push   %edi
f0101141:	56                   	push   %esi
f0101142:	53                   	push   %ebx
f0101143:	83 ec 1c             	sub    $0x1c,%esp
f0101146:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101149:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f010114c:	c1 e9 0c             	shr    $0xc,%ecx
f010114f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101152:	89 c3                	mov    %eax,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;
f0101154:	be 00 00 00 00       	mov    $0x0,%esi

	for(i; i < size/PGSIZE; ++i)
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0101159:	89 d7                	mov    %edx,%edi
f010115b:	29 c7                	sub    %eax,%edi

		if(ptable_entry == NULL)
			panic("boot_map_region: Failed to allocate new PTE!");
		
		*ptable_entry = pa | perm | PTE_P;
f010115d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101160:	83 c8 01             	or     $0x1,%eax
f0101163:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0101166:	eb 3f                	jmp    f01011a7 <boot_map_region+0x6a>
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0101168:	83 ec 04             	sub    $0x4,%esp
f010116b:	6a 01                	push   $0x1
f010116d:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101170:	50                   	push   %eax
f0101171:	ff 75 e0             	pushl  -0x20(%ebp)
f0101174:	e8 f2 fe ff ff       	call   f010106b <pgdir_walk>

		if(ptable_entry == NULL)
f0101179:	83 c4 10             	add    $0x10,%esp
f010117c:	85 c0                	test   %eax,%eax
f010117e:	75 17                	jne    f0101197 <boot_map_region+0x5a>
			panic("boot_map_region: Failed to allocate new PTE!");
f0101180:	83 ec 04             	sub    $0x4,%esp
f0101183:	68 84 60 10 f0       	push   $0xf0106084
f0101188:	68 fe 01 00 00       	push   $0x1fe
f010118d:	68 e5 68 10 f0       	push   $0xf01068e5
f0101192:	e8 a9 ee ff ff       	call   f0100040 <_panic>
		
		*ptable_entry = pa | perm | PTE_P;
f0101197:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010119a:	09 da                	or     %ebx,%edx
f010119c:	89 10                	mov    %edx,(%eax)

		pa += PGSIZE;
f010119e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f01011a4:	83 c6 01             	add    $0x1,%esi
f01011a7:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01011aa:	75 bc                	jne    f0101168 <boot_map_region+0x2b>

		pa += PGSIZE;
		va += PGSIZE;
	}
		
}
f01011ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011af:	5b                   	pop    %ebx
f01011b0:	5e                   	pop    %esi
f01011b1:	5f                   	pop    %edi
f01011b2:	5d                   	pop    %ebp
f01011b3:	c3                   	ret    

f01011b4 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011b4:	55                   	push   %ebp
f01011b5:	89 e5                	mov    %esp,%ebp
f01011b7:	53                   	push   %ebx
f01011b8:	83 ec 08             	sub    $0x8,%esp
f01011bb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
f01011be:	6a 00                	push   $0x0
f01011c0:	ff 75 0c             	pushl  0xc(%ebp)
f01011c3:	ff 75 08             	pushl  0x8(%ebp)
f01011c6:	e8 a0 fe ff ff       	call   f010106b <pgdir_walk>
	
	if(!ptEntry) 
f01011cb:	83 c4 10             	add    $0x10,%esp
f01011ce:	85 c0                	test   %eax,%eax
f01011d0:	74 32                	je     f0101204 <page_lookup+0x50>
		return NULL;

	if(pte_store)
f01011d2:	85 db                	test   %ebx,%ebx
f01011d4:	74 02                	je     f01011d8 <page_lookup+0x24>
	{
		*pte_store = ptEntry;
f01011d6:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011d8:	8b 00                	mov    (%eax),%eax
f01011da:	c1 e8 0c             	shr    $0xc,%eax
f01011dd:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01011e3:	72 14                	jb     f01011f9 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01011e5:	83 ec 04             	sub    $0x4,%esp
f01011e8:	68 b4 60 10 f0       	push   $0xf01060b4
f01011ed:	6a 51                	push   $0x51
f01011ef:	68 f1 68 10 f0       	push   $0xf01068f1
f01011f4:	e8 47 ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01011f9:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01011ff:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
f0101202:	eb 05                	jmp    f0101209 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
	
	if(!ptEntry) 
		return NULL;
f0101204:	b8 00 00 00 00       	mov    $0x0,%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
}
f0101209:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010120c:	c9                   	leave  
f010120d:	c3                   	ret    

f010120e <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010120e:	55                   	push   %ebp
f010120f:	89 e5                	mov    %esp,%ebp
f0101211:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101214:	e8 ed 40 00 00       	call   f0105306 <cpunum>
f0101219:	6b c0 74             	imul   $0x74,%eax,%eax
f010121c:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0101223:	74 16                	je     f010123b <tlb_invalidate+0x2d>
f0101225:	e8 dc 40 00 00       	call   f0105306 <cpunum>
f010122a:	6b c0 74             	imul   $0x74,%eax,%eax
f010122d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0101233:	8b 55 08             	mov    0x8(%ebp),%edx
f0101236:	39 50 60             	cmp    %edx,0x60(%eax)
f0101239:	75 06                	jne    f0101241 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010123b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010123e:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101241:	c9                   	leave  
f0101242:	c3                   	ret    

f0101243 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101243:	55                   	push   %ebp
f0101244:	89 e5                	mov    %esp,%ebp
f0101246:	56                   	push   %esi
f0101247:	53                   	push   %ebx
f0101248:	83 ec 14             	sub    $0x14,%esp
f010124b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010124e:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *ptEntry = NULL;
f0101251:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &ptEntry);
f0101258:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010125b:	50                   	push   %eax
f010125c:	56                   	push   %esi
f010125d:	53                   	push   %ebx
f010125e:	e8 51 ff ff ff       	call   f01011b4 <page_lookup>

	if(!page || !(*ptEntry & PTE_P)) 
f0101263:	83 c4 10             	add    $0x10,%esp
f0101266:	85 c0                	test   %eax,%eax
f0101268:	74 27                	je     f0101291 <page_remove+0x4e>
f010126a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010126d:	f6 02 01             	testb  $0x1,(%edx)
f0101270:	74 1f                	je     f0101291 <page_remove+0x4e>
		return;

	page_decref(page);
f0101272:	83 ec 0c             	sub    $0xc,%esp
f0101275:	50                   	push   %eax
f0101276:	e8 c9 fd ff ff       	call   f0101044 <page_decref>

	*ptEntry = 0;
f010127b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010127e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	tlb_invalidate(pgdir, va);
f0101284:	83 c4 08             	add    $0x8,%esp
f0101287:	56                   	push   %esi
f0101288:	53                   	push   %ebx
f0101289:	e8 80 ff ff ff       	call   f010120e <tlb_invalidate>
f010128e:	83 c4 10             	add    $0x10,%esp
}
f0101291:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101294:	5b                   	pop    %ebx
f0101295:	5e                   	pop    %esi
f0101296:	5d                   	pop    %ebp
f0101297:	c3                   	ret    

f0101298 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101298:	55                   	push   %ebp
f0101299:	89 e5                	mov    %esp,%ebp
f010129b:	57                   	push   %edi
f010129c:	56                   	push   %esi
f010129d:	53                   	push   %ebx
f010129e:	83 ec 10             	sub    $0x10,%esp
f01012a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01012a4:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
f01012a7:	6a 01                	push   $0x1
f01012a9:	57                   	push   %edi
f01012aa:	ff 75 08             	pushl  0x8(%ebp)
f01012ad:	e8 b9 fd ff ff       	call   f010106b <pgdir_walk>
	
	if(!ptEntry) 
f01012b2:	83 c4 10             	add    $0x10,%esp
f01012b5:	85 c0                	test   %eax,%eax
f01012b7:	74 44                	je     f01012fd <page_insert+0x65>
f01012b9:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	
	pp->pp_ref++;
f01012bb:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*ptEntry & PTE_P)
f01012c0:	f6 00 01             	testb  $0x1,(%eax)
f01012c3:	74 1b                	je     f01012e0 <page_insert+0x48>
	{
		page_remove(pgdir, va);
f01012c5:	83 ec 08             	sub    $0x8,%esp
f01012c8:	57                   	push   %edi
f01012c9:	ff 75 08             	pushl  0x8(%ebp)
f01012cc:	e8 72 ff ff ff       	call   f0101243 <page_remove>
		tlb_invalidate(pgdir, va);
f01012d1:	83 c4 08             	add    $0x8,%esp
f01012d4:	57                   	push   %edi
f01012d5:	ff 75 08             	pushl  0x8(%ebp)
f01012d8:	e8 31 ff ff ff       	call   f010120e <tlb_invalidate>
f01012dd:	83 c4 10             	add    $0x10,%esp
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;
f01012e0:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
f01012e6:	c1 fb 03             	sar    $0x3,%ebx
f01012e9:	c1 e3 0c             	shl    $0xc,%ebx
f01012ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ef:	83 c8 01             	or     $0x1,%eax
f01012f2:	09 c3                	or     %eax,%ebx
f01012f4:	89 1e                	mov    %ebx,(%esi)

	return 0;
f01012f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012fb:	eb 05                	jmp    f0101302 <page_insert+0x6a>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
	
	if(!ptEntry) 
		return -E_NO_MEM;
f01012fd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;

	return 0;
}
f0101302:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101305:	5b                   	pop    %ebx
f0101306:	5e                   	pop    %esi
f0101307:	5f                   	pop    %edi
f0101308:	5d                   	pop    %ebp
f0101309:	c3                   	ret    

f010130a <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f010130a:	55                   	push   %ebp
f010130b:	89 e5                	mov    %esp,%ebp
f010130d:	53                   	push   %ebx
f010130e:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f0101311:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101314:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f010131a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	if(base + size >= MMIOLIM)
f0101320:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f0101326:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101329:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010132e:	76 17                	jbe    f0101347 <mmio_map_region+0x3d>
		panic("mmio_map_region: Not enough memory!");
f0101330:	83 ec 04             	sub    $0x4,%esp
f0101333:	68 d4 60 10 f0       	push   $0xf01060d4
f0101338:	68 a4 02 00 00       	push   $0x2a4
f010133d:	68 e5 68 10 f0       	push   $0xf01068e5
f0101342:	e8 f9 ec ff ff       	call   f0100040 <_panic>
	
	boot_map_region(kern_pgdir, base, size, pa, (PTE_PCD | PTE_PWT | PTE_W));
f0101347:	83 ec 08             	sub    $0x8,%esp
f010134a:	6a 1a                	push   $0x1a
f010134c:	ff 75 08             	pushl  0x8(%ebp)
f010134f:	89 d9                	mov    %ebx,%ecx
f0101351:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101356:	e8 e2 fd ff ff       	call   f010113d <boot_map_region>

	base += size;
f010135b:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f0101360:	01 c3                	add    %eax,%ebx
f0101362:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300

	return (void *) (base - size);
	
}
f0101368:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010136b:	c9                   	leave  
f010136c:	c3                   	ret    

f010136d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010136d:	55                   	push   %ebp
f010136e:	89 e5                	mov    %esp,%ebp
f0101370:	57                   	push   %edi
f0101371:	56                   	push   %esi
f0101372:	53                   	push   %ebx
f0101373:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101376:	b8 15 00 00 00       	mov    $0x15,%eax
f010137b:	e8 08 f7 ff ff       	call   f0100a88 <nvram_read>
f0101380:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101382:	b8 17 00 00 00       	mov    $0x17,%eax
f0101387:	e8 fc f6 ff ff       	call   f0100a88 <nvram_read>
f010138c:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010138e:	b8 34 00 00 00       	mov    $0x34,%eax
f0101393:	e8 f0 f6 ff ff       	call   f0100a88 <nvram_read>
f0101398:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010139b:	85 c0                	test   %eax,%eax
f010139d:	74 07                	je     f01013a6 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f010139f:	05 00 40 00 00       	add    $0x4000,%eax
f01013a4:	eb 0b                	jmp    f01013b1 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01013a6:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013ac:	85 f6                	test   %esi,%esi
f01013ae:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01013b1:	89 c2                	mov    %eax,%edx
f01013b3:	c1 ea 02             	shr    $0x2,%edx
f01013b6:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013bc:	89 c2                	mov    %eax,%edx
f01013be:	29 da                	sub    %ebx,%edx
f01013c0:	52                   	push   %edx
f01013c1:	53                   	push   %ebx
f01013c2:	50                   	push   %eax
f01013c3:	68 f8 60 10 f0       	push   $0xf01060f8
f01013c8:	e8 8b 22 00 00       	call   f0103658 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013cd:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013d2:	e8 3e f7 ff ff       	call   f0100b15 <boot_alloc>
f01013d7:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f01013dc:	83 c4 0c             	add    $0xc,%esp
f01013df:	68 00 10 00 00       	push   $0x1000
f01013e4:	6a 00                	push   $0x0
f01013e6:	50                   	push   %eax
f01013e7:	e8 f8 38 00 00       	call   f0104ce4 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013ec:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013f1:	83 c4 10             	add    $0x10,%esp
f01013f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013f9:	77 15                	ja     f0101410 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013fb:	50                   	push   %eax
f01013fc:	68 e8 59 10 f0       	push   $0xf01059e8
f0101401:	68 a5 00 00 00       	push   $0xa5
f0101406:	68 e5 68 10 f0       	push   $0xf01068e5
f010140b:	e8 30 ec ff ff       	call   f0100040 <_panic>
f0101410:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101416:	83 ca 05             	or     $0x5,%edx
f0101419:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof(struct PageInfo)*npages);
f010141f:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0101424:	c1 e0 03             	shl    $0x3,%eax
f0101427:	e8 e9 f6 ff ff       	call   f0100b15 <boot_alloc>
f010142c:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f0101431:	83 ec 04             	sub    $0x4,%esp
f0101434:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f010143a:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101441:	52                   	push   %edx
f0101442:	6a 00                	push   $0x0
f0101444:	50                   	push   %eax
f0101445:	e8 9a 38 00 00       	call   f0104ce4 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f010144a:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f010144f:	e8 c1 f6 ff ff       	call   f0100b15 <boot_alloc>
f0101454:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
	memset(envs, '\0', sizeof(struct Env) * NENV);
f0101459:	83 c4 0c             	add    $0xc,%esp
f010145c:	68 00 f0 01 00       	push   $0x1f000
f0101461:	6a 00                	push   $0x0
f0101463:	50                   	push   %eax
f0101464:	e8 7b 38 00 00       	call   f0104ce4 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101469:	e8 2a fa ff ff       	call   f0100e98 <page_init>

	check_page_free_list(1);
f010146e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101473:	e8 1e f7 ff ff       	call   f0100b96 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101478:	83 c4 10             	add    $0x10,%esp
f010147b:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f0101482:	75 17                	jne    f010149b <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f0101484:	83 ec 04             	sub    $0x4,%esp
f0101487:	68 b8 69 10 f0       	push   $0xf01069b8
f010148c:	68 39 03 00 00       	push   $0x339
f0101491:	68 e5 68 10 f0       	push   $0xf01068e5
f0101496:	e8 a5 eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010149b:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01014a0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014a5:	eb 05                	jmp    f01014ac <mem_init+0x13f>
		++nfree;
f01014a7:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014aa:	8b 00                	mov    (%eax),%eax
f01014ac:	85 c0                	test   %eax,%eax
f01014ae:	75 f7                	jne    f01014a7 <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014b0:	83 ec 0c             	sub    $0xc,%esp
f01014b3:	6a 00                	push   $0x0
f01014b5:	e8 df fa ff ff       	call   f0100f99 <page_alloc>
f01014ba:	89 c7                	mov    %eax,%edi
f01014bc:	83 c4 10             	add    $0x10,%esp
f01014bf:	85 c0                	test   %eax,%eax
f01014c1:	75 19                	jne    f01014dc <mem_init+0x16f>
f01014c3:	68 d3 69 10 f0       	push   $0xf01069d3
f01014c8:	68 0b 69 10 f0       	push   $0xf010690b
f01014cd:	68 41 03 00 00       	push   $0x341
f01014d2:	68 e5 68 10 f0       	push   $0xf01068e5
f01014d7:	e8 64 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01014dc:	83 ec 0c             	sub    $0xc,%esp
f01014df:	6a 00                	push   $0x0
f01014e1:	e8 b3 fa ff ff       	call   f0100f99 <page_alloc>
f01014e6:	89 c6                	mov    %eax,%esi
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	75 19                	jne    f0101508 <mem_init+0x19b>
f01014ef:	68 e9 69 10 f0       	push   $0xf01069e9
f01014f4:	68 0b 69 10 f0       	push   $0xf010690b
f01014f9:	68 42 03 00 00       	push   $0x342
f01014fe:	68 e5 68 10 f0       	push   $0xf01068e5
f0101503:	e8 38 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101508:	83 ec 0c             	sub    $0xc,%esp
f010150b:	6a 00                	push   $0x0
f010150d:	e8 87 fa ff ff       	call   f0100f99 <page_alloc>
f0101512:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	85 c0                	test   %eax,%eax
f010151a:	75 19                	jne    f0101535 <mem_init+0x1c8>
f010151c:	68 ff 69 10 f0       	push   $0xf01069ff
f0101521:	68 0b 69 10 f0       	push   $0xf010690b
f0101526:	68 43 03 00 00       	push   $0x343
f010152b:	68 e5 68 10 f0       	push   $0xf01068e5
f0101530:	e8 0b eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101535:	39 f7                	cmp    %esi,%edi
f0101537:	75 19                	jne    f0101552 <mem_init+0x1e5>
f0101539:	68 15 6a 10 f0       	push   $0xf0106a15
f010153e:	68 0b 69 10 f0       	push   $0xf010690b
f0101543:	68 46 03 00 00       	push   $0x346
f0101548:	68 e5 68 10 f0       	push   $0xf01068e5
f010154d:	e8 ee ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101552:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101555:	39 c6                	cmp    %eax,%esi
f0101557:	74 04                	je     f010155d <mem_init+0x1f0>
f0101559:	39 c7                	cmp    %eax,%edi
f010155b:	75 19                	jne    f0101576 <mem_init+0x209>
f010155d:	68 34 61 10 f0       	push   $0xf0106134
f0101562:	68 0b 69 10 f0       	push   $0xf010690b
f0101567:	68 47 03 00 00       	push   $0x347
f010156c:	68 e5 68 10 f0       	push   $0xf01068e5
f0101571:	e8 ca ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101576:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010157c:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f0101582:	c1 e2 0c             	shl    $0xc,%edx
f0101585:	89 f8                	mov    %edi,%eax
f0101587:	29 c8                	sub    %ecx,%eax
f0101589:	c1 f8 03             	sar    $0x3,%eax
f010158c:	c1 e0 0c             	shl    $0xc,%eax
f010158f:	39 d0                	cmp    %edx,%eax
f0101591:	72 19                	jb     f01015ac <mem_init+0x23f>
f0101593:	68 27 6a 10 f0       	push   $0xf0106a27
f0101598:	68 0b 69 10 f0       	push   $0xf010690b
f010159d:	68 48 03 00 00       	push   $0x348
f01015a2:	68 e5 68 10 f0       	push   $0xf01068e5
f01015a7:	e8 94 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01015ac:	89 f0                	mov    %esi,%eax
f01015ae:	29 c8                	sub    %ecx,%eax
f01015b0:	c1 f8 03             	sar    $0x3,%eax
f01015b3:	c1 e0 0c             	shl    $0xc,%eax
f01015b6:	39 c2                	cmp    %eax,%edx
f01015b8:	77 19                	ja     f01015d3 <mem_init+0x266>
f01015ba:	68 44 6a 10 f0       	push   $0xf0106a44
f01015bf:	68 0b 69 10 f0       	push   $0xf010690b
f01015c4:	68 49 03 00 00       	push   $0x349
f01015c9:	68 e5 68 10 f0       	push   $0xf01068e5
f01015ce:	e8 6d ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015d6:	29 c8                	sub    %ecx,%eax
f01015d8:	c1 f8 03             	sar    $0x3,%eax
f01015db:	c1 e0 0c             	shl    $0xc,%eax
f01015de:	39 c2                	cmp    %eax,%edx
f01015e0:	77 19                	ja     f01015fb <mem_init+0x28e>
f01015e2:	68 61 6a 10 f0       	push   $0xf0106a61
f01015e7:	68 0b 69 10 f0       	push   $0xf010690b
f01015ec:	68 4a 03 00 00       	push   $0x34a
f01015f1:	68 e5 68 10 f0       	push   $0xf01068e5
f01015f6:	e8 45 ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015fb:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101600:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101603:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010160a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010160d:	83 ec 0c             	sub    $0xc,%esp
f0101610:	6a 00                	push   $0x0
f0101612:	e8 82 f9 ff ff       	call   f0100f99 <page_alloc>
f0101617:	83 c4 10             	add    $0x10,%esp
f010161a:	85 c0                	test   %eax,%eax
f010161c:	74 19                	je     f0101637 <mem_init+0x2ca>
f010161e:	68 7e 6a 10 f0       	push   $0xf0106a7e
f0101623:	68 0b 69 10 f0       	push   $0xf010690b
f0101628:	68 51 03 00 00       	push   $0x351
f010162d:	68 e5 68 10 f0       	push   $0xf01068e5
f0101632:	e8 09 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101637:	83 ec 0c             	sub    $0xc,%esp
f010163a:	57                   	push   %edi
f010163b:	e8 c9 f9 ff ff       	call   f0101009 <page_free>
	page_free(pp1);
f0101640:	89 34 24             	mov    %esi,(%esp)
f0101643:	e8 c1 f9 ff ff       	call   f0101009 <page_free>
	page_free(pp2);
f0101648:	83 c4 04             	add    $0x4,%esp
f010164b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010164e:	e8 b6 f9 ff ff       	call   f0101009 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101653:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010165a:	e8 3a f9 ff ff       	call   f0100f99 <page_alloc>
f010165f:	89 c6                	mov    %eax,%esi
f0101661:	83 c4 10             	add    $0x10,%esp
f0101664:	85 c0                	test   %eax,%eax
f0101666:	75 19                	jne    f0101681 <mem_init+0x314>
f0101668:	68 d3 69 10 f0       	push   $0xf01069d3
f010166d:	68 0b 69 10 f0       	push   $0xf010690b
f0101672:	68 58 03 00 00       	push   $0x358
f0101677:	68 e5 68 10 f0       	push   $0xf01068e5
f010167c:	e8 bf e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101681:	83 ec 0c             	sub    $0xc,%esp
f0101684:	6a 00                	push   $0x0
f0101686:	e8 0e f9 ff ff       	call   f0100f99 <page_alloc>
f010168b:	89 c7                	mov    %eax,%edi
f010168d:	83 c4 10             	add    $0x10,%esp
f0101690:	85 c0                	test   %eax,%eax
f0101692:	75 19                	jne    f01016ad <mem_init+0x340>
f0101694:	68 e9 69 10 f0       	push   $0xf01069e9
f0101699:	68 0b 69 10 f0       	push   $0xf010690b
f010169e:	68 59 03 00 00       	push   $0x359
f01016a3:	68 e5 68 10 f0       	push   $0xf01068e5
f01016a8:	e8 93 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016ad:	83 ec 0c             	sub    $0xc,%esp
f01016b0:	6a 00                	push   $0x0
f01016b2:	e8 e2 f8 ff ff       	call   f0100f99 <page_alloc>
f01016b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016ba:	83 c4 10             	add    $0x10,%esp
f01016bd:	85 c0                	test   %eax,%eax
f01016bf:	75 19                	jne    f01016da <mem_init+0x36d>
f01016c1:	68 ff 69 10 f0       	push   $0xf01069ff
f01016c6:	68 0b 69 10 f0       	push   $0xf010690b
f01016cb:	68 5a 03 00 00       	push   $0x35a
f01016d0:	68 e5 68 10 f0       	push   $0xf01068e5
f01016d5:	e8 66 e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016da:	39 fe                	cmp    %edi,%esi
f01016dc:	75 19                	jne    f01016f7 <mem_init+0x38a>
f01016de:	68 15 6a 10 f0       	push   $0xf0106a15
f01016e3:	68 0b 69 10 f0       	push   $0xf010690b
f01016e8:	68 5c 03 00 00       	push   $0x35c
f01016ed:	68 e5 68 10 f0       	push   $0xf01068e5
f01016f2:	e8 49 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016f7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016fa:	39 c7                	cmp    %eax,%edi
f01016fc:	74 04                	je     f0101702 <mem_init+0x395>
f01016fe:	39 c6                	cmp    %eax,%esi
f0101700:	75 19                	jne    f010171b <mem_init+0x3ae>
f0101702:	68 34 61 10 f0       	push   $0xf0106134
f0101707:	68 0b 69 10 f0       	push   $0xf010690b
f010170c:	68 5d 03 00 00       	push   $0x35d
f0101711:	68 e5 68 10 f0       	push   $0xf01068e5
f0101716:	e8 25 e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010171b:	83 ec 0c             	sub    $0xc,%esp
f010171e:	6a 00                	push   $0x0
f0101720:	e8 74 f8 ff ff       	call   f0100f99 <page_alloc>
f0101725:	83 c4 10             	add    $0x10,%esp
f0101728:	85 c0                	test   %eax,%eax
f010172a:	74 19                	je     f0101745 <mem_init+0x3d8>
f010172c:	68 7e 6a 10 f0       	push   $0xf0106a7e
f0101731:	68 0b 69 10 f0       	push   $0xf010690b
f0101736:	68 5e 03 00 00       	push   $0x35e
f010173b:	68 e5 68 10 f0       	push   $0xf01068e5
f0101740:	e8 fb e8 ff ff       	call   f0100040 <_panic>
f0101745:	89 f0                	mov    %esi,%eax
f0101747:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010174d:	c1 f8 03             	sar    $0x3,%eax
f0101750:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101753:	89 c2                	mov    %eax,%edx
f0101755:	c1 ea 0c             	shr    $0xc,%edx
f0101758:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010175e:	72 12                	jb     f0101772 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101760:	50                   	push   %eax
f0101761:	68 c4 59 10 f0       	push   $0xf01059c4
f0101766:	6a 58                	push   $0x58
f0101768:	68 f1 68 10 f0       	push   $0xf01068f1
f010176d:	e8 ce e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101772:	83 ec 04             	sub    $0x4,%esp
f0101775:	68 00 10 00 00       	push   $0x1000
f010177a:	6a 01                	push   $0x1
f010177c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101781:	50                   	push   %eax
f0101782:	e8 5d 35 00 00       	call   f0104ce4 <memset>
	page_free(pp0);
f0101787:	89 34 24             	mov    %esi,(%esp)
f010178a:	e8 7a f8 ff ff       	call   f0101009 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010178f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101796:	e8 fe f7 ff ff       	call   f0100f99 <page_alloc>
f010179b:	83 c4 10             	add    $0x10,%esp
f010179e:	85 c0                	test   %eax,%eax
f01017a0:	75 19                	jne    f01017bb <mem_init+0x44e>
f01017a2:	68 8d 6a 10 f0       	push   $0xf0106a8d
f01017a7:	68 0b 69 10 f0       	push   $0xf010690b
f01017ac:	68 63 03 00 00       	push   $0x363
f01017b1:	68 e5 68 10 f0       	push   $0xf01068e5
f01017b6:	e8 85 e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01017bb:	39 c6                	cmp    %eax,%esi
f01017bd:	74 19                	je     f01017d8 <mem_init+0x46b>
f01017bf:	68 ab 6a 10 f0       	push   $0xf0106aab
f01017c4:	68 0b 69 10 f0       	push   $0xf010690b
f01017c9:	68 64 03 00 00       	push   $0x364
f01017ce:	68 e5 68 10 f0       	push   $0xf01068e5
f01017d3:	e8 68 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d8:	89 f0                	mov    %esi,%eax
f01017da:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01017e0:	c1 f8 03             	sar    $0x3,%eax
f01017e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017e6:	89 c2                	mov    %eax,%edx
f01017e8:	c1 ea 0c             	shr    $0xc,%edx
f01017eb:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01017f1:	72 12                	jb     f0101805 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017f3:	50                   	push   %eax
f01017f4:	68 c4 59 10 f0       	push   $0xf01059c4
f01017f9:	6a 58                	push   $0x58
f01017fb:	68 f1 68 10 f0       	push   $0xf01068f1
f0101800:	e8 3b e8 ff ff       	call   f0100040 <_panic>
f0101805:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010180b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101811:	80 38 00             	cmpb   $0x0,(%eax)
f0101814:	74 19                	je     f010182f <mem_init+0x4c2>
f0101816:	68 bb 6a 10 f0       	push   $0xf0106abb
f010181b:	68 0b 69 10 f0       	push   $0xf010690b
f0101820:	68 67 03 00 00       	push   $0x367
f0101825:	68 e5 68 10 f0       	push   $0xf01068e5
f010182a:	e8 11 e8 ff ff       	call   f0100040 <_panic>
f010182f:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101832:	39 d0                	cmp    %edx,%eax
f0101834:	75 db                	jne    f0101811 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101836:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101839:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f010183e:	83 ec 0c             	sub    $0xc,%esp
f0101841:	56                   	push   %esi
f0101842:	e8 c2 f7 ff ff       	call   f0101009 <page_free>
	page_free(pp1);
f0101847:	89 3c 24             	mov    %edi,(%esp)
f010184a:	e8 ba f7 ff ff       	call   f0101009 <page_free>
	page_free(pp2);
f010184f:	83 c4 04             	add    $0x4,%esp
f0101852:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101855:	e8 af f7 ff ff       	call   f0101009 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010185a:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010185f:	83 c4 10             	add    $0x10,%esp
f0101862:	eb 05                	jmp    f0101869 <mem_init+0x4fc>
		--nfree;
f0101864:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101867:	8b 00                	mov    (%eax),%eax
f0101869:	85 c0                	test   %eax,%eax
f010186b:	75 f7                	jne    f0101864 <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f010186d:	85 db                	test   %ebx,%ebx
f010186f:	74 19                	je     f010188a <mem_init+0x51d>
f0101871:	68 c5 6a 10 f0       	push   $0xf0106ac5
f0101876:	68 0b 69 10 f0       	push   $0xf010690b
f010187b:	68 74 03 00 00       	push   $0x374
f0101880:	68 e5 68 10 f0       	push   $0xf01068e5
f0101885:	e8 b6 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010188a:	83 ec 0c             	sub    $0xc,%esp
f010188d:	68 54 61 10 f0       	push   $0xf0106154
f0101892:	e8 c1 1d 00 00       	call   f0103658 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101897:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010189e:	e8 f6 f6 ff ff       	call   f0100f99 <page_alloc>
f01018a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018a6:	83 c4 10             	add    $0x10,%esp
f01018a9:	85 c0                	test   %eax,%eax
f01018ab:	75 19                	jne    f01018c6 <mem_init+0x559>
f01018ad:	68 d3 69 10 f0       	push   $0xf01069d3
f01018b2:	68 0b 69 10 f0       	push   $0xf010690b
f01018b7:	68 da 03 00 00       	push   $0x3da
f01018bc:	68 e5 68 10 f0       	push   $0xf01068e5
f01018c1:	e8 7a e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018c6:	83 ec 0c             	sub    $0xc,%esp
f01018c9:	6a 00                	push   $0x0
f01018cb:	e8 c9 f6 ff ff       	call   f0100f99 <page_alloc>
f01018d0:	89 c3                	mov    %eax,%ebx
f01018d2:	83 c4 10             	add    $0x10,%esp
f01018d5:	85 c0                	test   %eax,%eax
f01018d7:	75 19                	jne    f01018f2 <mem_init+0x585>
f01018d9:	68 e9 69 10 f0       	push   $0xf01069e9
f01018de:	68 0b 69 10 f0       	push   $0xf010690b
f01018e3:	68 db 03 00 00       	push   $0x3db
f01018e8:	68 e5 68 10 f0       	push   $0xf01068e5
f01018ed:	e8 4e e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f2:	83 ec 0c             	sub    $0xc,%esp
f01018f5:	6a 00                	push   $0x0
f01018f7:	e8 9d f6 ff ff       	call   f0100f99 <page_alloc>
f01018fc:	89 c6                	mov    %eax,%esi
f01018fe:	83 c4 10             	add    $0x10,%esp
f0101901:	85 c0                	test   %eax,%eax
f0101903:	75 19                	jne    f010191e <mem_init+0x5b1>
f0101905:	68 ff 69 10 f0       	push   $0xf01069ff
f010190a:	68 0b 69 10 f0       	push   $0xf010690b
f010190f:	68 dc 03 00 00       	push   $0x3dc
f0101914:	68 e5 68 10 f0       	push   $0xf01068e5
f0101919:	e8 22 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010191e:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101921:	75 19                	jne    f010193c <mem_init+0x5cf>
f0101923:	68 15 6a 10 f0       	push   $0xf0106a15
f0101928:	68 0b 69 10 f0       	push   $0xf010690b
f010192d:	68 df 03 00 00       	push   $0x3df
f0101932:	68 e5 68 10 f0       	push   $0xf01068e5
f0101937:	e8 04 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010193c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010193f:	74 04                	je     f0101945 <mem_init+0x5d8>
f0101941:	39 c3                	cmp    %eax,%ebx
f0101943:	75 19                	jne    f010195e <mem_init+0x5f1>
f0101945:	68 34 61 10 f0       	push   $0xf0106134
f010194a:	68 0b 69 10 f0       	push   $0xf010690b
f010194f:	68 e0 03 00 00       	push   $0x3e0
f0101954:	68 e5 68 10 f0       	push   $0xf01068e5
f0101959:	e8 e2 e6 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010195e:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101963:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101966:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010196d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101970:	83 ec 0c             	sub    $0xc,%esp
f0101973:	6a 00                	push   $0x0
f0101975:	e8 1f f6 ff ff       	call   f0100f99 <page_alloc>
f010197a:	83 c4 10             	add    $0x10,%esp
f010197d:	85 c0                	test   %eax,%eax
f010197f:	74 19                	je     f010199a <mem_init+0x62d>
f0101981:	68 7e 6a 10 f0       	push   $0xf0106a7e
f0101986:	68 0b 69 10 f0       	push   $0xf010690b
f010198b:	68 e7 03 00 00       	push   $0x3e7
f0101990:	68 e5 68 10 f0       	push   $0xf01068e5
f0101995:	e8 a6 e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010199a:	83 ec 04             	sub    $0x4,%esp
f010199d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019a0:	50                   	push   %eax
f01019a1:	6a 00                	push   $0x0
f01019a3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01019a9:	e8 06 f8 ff ff       	call   f01011b4 <page_lookup>
f01019ae:	83 c4 10             	add    $0x10,%esp
f01019b1:	85 c0                	test   %eax,%eax
f01019b3:	74 19                	je     f01019ce <mem_init+0x661>
f01019b5:	68 74 61 10 f0       	push   $0xf0106174
f01019ba:	68 0b 69 10 f0       	push   $0xf010690b
f01019bf:	68 ea 03 00 00       	push   $0x3ea
f01019c4:	68 e5 68 10 f0       	push   $0xf01068e5
f01019c9:	e8 72 e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019ce:	6a 02                	push   $0x2
f01019d0:	6a 00                	push   $0x0
f01019d2:	53                   	push   %ebx
f01019d3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01019d9:	e8 ba f8 ff ff       	call   f0101298 <page_insert>
f01019de:	83 c4 10             	add    $0x10,%esp
f01019e1:	85 c0                	test   %eax,%eax
f01019e3:	78 19                	js     f01019fe <mem_init+0x691>
f01019e5:	68 ac 61 10 f0       	push   $0xf01061ac
f01019ea:	68 0b 69 10 f0       	push   $0xf010690b
f01019ef:	68 ed 03 00 00       	push   $0x3ed
f01019f4:	68 e5 68 10 f0       	push   $0xf01068e5
f01019f9:	e8 42 e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019fe:	83 ec 0c             	sub    $0xc,%esp
f0101a01:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a04:	e8 00 f6 ff ff       	call   f0101009 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a09:	6a 02                	push   $0x2
f0101a0b:	6a 00                	push   $0x0
f0101a0d:	53                   	push   %ebx
f0101a0e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101a14:	e8 7f f8 ff ff       	call   f0101298 <page_insert>
f0101a19:	83 c4 20             	add    $0x20,%esp
f0101a1c:	85 c0                	test   %eax,%eax
f0101a1e:	74 19                	je     f0101a39 <mem_init+0x6cc>
f0101a20:	68 dc 61 10 f0       	push   $0xf01061dc
f0101a25:	68 0b 69 10 f0       	push   $0xf010690b
f0101a2a:	68 f1 03 00 00       	push   $0x3f1
f0101a2f:	68 e5 68 10 f0       	push   $0xf01068e5
f0101a34:	e8 07 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a39:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a3f:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0101a44:	89 c1                	mov    %eax,%ecx
f0101a46:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a49:	8b 17                	mov    (%edi),%edx
f0101a4b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a54:	29 c8                	sub    %ecx,%eax
f0101a56:	c1 f8 03             	sar    $0x3,%eax
f0101a59:	c1 e0 0c             	shl    $0xc,%eax
f0101a5c:	39 c2                	cmp    %eax,%edx
f0101a5e:	74 19                	je     f0101a79 <mem_init+0x70c>
f0101a60:	68 0c 62 10 f0       	push   $0xf010620c
f0101a65:	68 0b 69 10 f0       	push   $0xf010690b
f0101a6a:	68 f2 03 00 00       	push   $0x3f2
f0101a6f:	68 e5 68 10 f0       	push   $0xf01068e5
f0101a74:	e8 c7 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a79:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a7e:	89 f8                	mov    %edi,%eax
f0101a80:	e8 2c f0 ff ff       	call   f0100ab1 <check_va2pa>
f0101a85:	89 da                	mov    %ebx,%edx
f0101a87:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a8a:	c1 fa 03             	sar    $0x3,%edx
f0101a8d:	c1 e2 0c             	shl    $0xc,%edx
f0101a90:	39 d0                	cmp    %edx,%eax
f0101a92:	74 19                	je     f0101aad <mem_init+0x740>
f0101a94:	68 34 62 10 f0       	push   $0xf0106234
f0101a99:	68 0b 69 10 f0       	push   $0xf010690b
f0101a9e:	68 f3 03 00 00       	push   $0x3f3
f0101aa3:	68 e5 68 10 f0       	push   $0xf01068e5
f0101aa8:	e8 93 e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101aad:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ab2:	74 19                	je     f0101acd <mem_init+0x760>
f0101ab4:	68 d0 6a 10 f0       	push   $0xf0106ad0
f0101ab9:	68 0b 69 10 f0       	push   $0xf010690b
f0101abe:	68 f4 03 00 00       	push   $0x3f4
f0101ac3:	68 e5 68 10 f0       	push   $0xf01068e5
f0101ac8:	e8 73 e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101acd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ad0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ad5:	74 19                	je     f0101af0 <mem_init+0x783>
f0101ad7:	68 e1 6a 10 f0       	push   $0xf0106ae1
f0101adc:	68 0b 69 10 f0       	push   $0xf010690b
f0101ae1:	68 f5 03 00 00       	push   $0x3f5
f0101ae6:	68 e5 68 10 f0       	push   $0xf01068e5
f0101aeb:	e8 50 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af0:	6a 02                	push   $0x2
f0101af2:	68 00 10 00 00       	push   $0x1000
f0101af7:	56                   	push   %esi
f0101af8:	57                   	push   %edi
f0101af9:	e8 9a f7 ff ff       	call   f0101298 <page_insert>
f0101afe:	83 c4 10             	add    $0x10,%esp
f0101b01:	85 c0                	test   %eax,%eax
f0101b03:	74 19                	je     f0101b1e <mem_init+0x7b1>
f0101b05:	68 64 62 10 f0       	push   $0xf0106264
f0101b0a:	68 0b 69 10 f0       	push   $0xf010690b
f0101b0f:	68 f8 03 00 00       	push   $0x3f8
f0101b14:	68 e5 68 10 f0       	push   $0xf01068e5
f0101b19:	e8 22 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b1e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b23:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101b28:	e8 84 ef ff ff       	call   f0100ab1 <check_va2pa>
f0101b2d:	89 f2                	mov    %esi,%edx
f0101b2f:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101b35:	c1 fa 03             	sar    $0x3,%edx
f0101b38:	c1 e2 0c             	shl    $0xc,%edx
f0101b3b:	39 d0                	cmp    %edx,%eax
f0101b3d:	74 19                	je     f0101b58 <mem_init+0x7eb>
f0101b3f:	68 a0 62 10 f0       	push   $0xf01062a0
f0101b44:	68 0b 69 10 f0       	push   $0xf010690b
f0101b49:	68 f9 03 00 00       	push   $0x3f9
f0101b4e:	68 e5 68 10 f0       	push   $0xf01068e5
f0101b53:	e8 e8 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b58:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b5d:	74 19                	je     f0101b78 <mem_init+0x80b>
f0101b5f:	68 f2 6a 10 f0       	push   $0xf0106af2
f0101b64:	68 0b 69 10 f0       	push   $0xf010690b
f0101b69:	68 fa 03 00 00       	push   $0x3fa
f0101b6e:	68 e5 68 10 f0       	push   $0xf01068e5
f0101b73:	e8 c8 e4 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b78:	83 ec 0c             	sub    $0xc,%esp
f0101b7b:	6a 00                	push   $0x0
f0101b7d:	e8 17 f4 ff ff       	call   f0100f99 <page_alloc>
f0101b82:	83 c4 10             	add    $0x10,%esp
f0101b85:	85 c0                	test   %eax,%eax
f0101b87:	74 19                	je     f0101ba2 <mem_init+0x835>
f0101b89:	68 7e 6a 10 f0       	push   $0xf0106a7e
f0101b8e:	68 0b 69 10 f0       	push   $0xf010690b
f0101b93:	68 fd 03 00 00       	push   $0x3fd
f0101b98:	68 e5 68 10 f0       	push   $0xf01068e5
f0101b9d:	e8 9e e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ba2:	6a 02                	push   $0x2
f0101ba4:	68 00 10 00 00       	push   $0x1000
f0101ba9:	56                   	push   %esi
f0101baa:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101bb0:	e8 e3 f6 ff ff       	call   f0101298 <page_insert>
f0101bb5:	83 c4 10             	add    $0x10,%esp
f0101bb8:	85 c0                	test   %eax,%eax
f0101bba:	74 19                	je     f0101bd5 <mem_init+0x868>
f0101bbc:	68 64 62 10 f0       	push   $0xf0106264
f0101bc1:	68 0b 69 10 f0       	push   $0xf010690b
f0101bc6:	68 00 04 00 00       	push   $0x400
f0101bcb:	68 e5 68 10 f0       	push   $0xf01068e5
f0101bd0:	e8 6b e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bd5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bda:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101bdf:	e8 cd ee ff ff       	call   f0100ab1 <check_va2pa>
f0101be4:	89 f2                	mov    %esi,%edx
f0101be6:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101bec:	c1 fa 03             	sar    $0x3,%edx
f0101bef:	c1 e2 0c             	shl    $0xc,%edx
f0101bf2:	39 d0                	cmp    %edx,%eax
f0101bf4:	74 19                	je     f0101c0f <mem_init+0x8a2>
f0101bf6:	68 a0 62 10 f0       	push   $0xf01062a0
f0101bfb:	68 0b 69 10 f0       	push   $0xf010690b
f0101c00:	68 01 04 00 00       	push   $0x401
f0101c05:	68 e5 68 10 f0       	push   $0xf01068e5
f0101c0a:	e8 31 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c0f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c14:	74 19                	je     f0101c2f <mem_init+0x8c2>
f0101c16:	68 f2 6a 10 f0       	push   $0xf0106af2
f0101c1b:	68 0b 69 10 f0       	push   $0xf010690b
f0101c20:	68 02 04 00 00       	push   $0x402
f0101c25:	68 e5 68 10 f0       	push   $0xf01068e5
f0101c2a:	e8 11 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c2f:	83 ec 0c             	sub    $0xc,%esp
f0101c32:	6a 00                	push   $0x0
f0101c34:	e8 60 f3 ff ff       	call   f0100f99 <page_alloc>
f0101c39:	83 c4 10             	add    $0x10,%esp
f0101c3c:	85 c0                	test   %eax,%eax
f0101c3e:	74 19                	je     f0101c59 <mem_init+0x8ec>
f0101c40:	68 7e 6a 10 f0       	push   $0xf0106a7e
f0101c45:	68 0b 69 10 f0       	push   $0xf010690b
f0101c4a:	68 06 04 00 00       	push   $0x406
f0101c4f:	68 e5 68 10 f0       	push   $0xf01068e5
f0101c54:	e8 e7 e3 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c59:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101c5f:	8b 02                	mov    (%edx),%eax
f0101c61:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c66:	89 c1                	mov    %eax,%ecx
f0101c68:	c1 e9 0c             	shr    $0xc,%ecx
f0101c6b:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101c71:	72 15                	jb     f0101c88 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c73:	50                   	push   %eax
f0101c74:	68 c4 59 10 f0       	push   $0xf01059c4
f0101c79:	68 09 04 00 00       	push   $0x409
f0101c7e:	68 e5 68 10 f0       	push   $0xf01068e5
f0101c83:	e8 b8 e3 ff ff       	call   f0100040 <_panic>
f0101c88:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c8d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c90:	83 ec 04             	sub    $0x4,%esp
f0101c93:	6a 00                	push   $0x0
f0101c95:	68 00 10 00 00       	push   $0x1000
f0101c9a:	52                   	push   %edx
f0101c9b:	e8 cb f3 ff ff       	call   f010106b <pgdir_walk>
f0101ca0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101ca3:	8d 51 04             	lea    0x4(%ecx),%edx
f0101ca6:	83 c4 10             	add    $0x10,%esp
f0101ca9:	39 d0                	cmp    %edx,%eax
f0101cab:	74 19                	je     f0101cc6 <mem_init+0x959>
f0101cad:	68 d0 62 10 f0       	push   $0xf01062d0
f0101cb2:	68 0b 69 10 f0       	push   $0xf010690b
f0101cb7:	68 0a 04 00 00       	push   $0x40a
f0101cbc:	68 e5 68 10 f0       	push   $0xf01068e5
f0101cc1:	e8 7a e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cc6:	6a 06                	push   $0x6
f0101cc8:	68 00 10 00 00       	push   $0x1000
f0101ccd:	56                   	push   %esi
f0101cce:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101cd4:	e8 bf f5 ff ff       	call   f0101298 <page_insert>
f0101cd9:	83 c4 10             	add    $0x10,%esp
f0101cdc:	85 c0                	test   %eax,%eax
f0101cde:	74 19                	je     f0101cf9 <mem_init+0x98c>
f0101ce0:	68 10 63 10 f0       	push   $0xf0106310
f0101ce5:	68 0b 69 10 f0       	push   $0xf010690b
f0101cea:	68 0d 04 00 00       	push   $0x40d
f0101cef:	68 e5 68 10 f0       	push   $0xf01068e5
f0101cf4:	e8 47 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cf9:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101cff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d04:	89 f8                	mov    %edi,%eax
f0101d06:	e8 a6 ed ff ff       	call   f0100ab1 <check_va2pa>
f0101d0b:	89 f2                	mov    %esi,%edx
f0101d0d:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101d13:	c1 fa 03             	sar    $0x3,%edx
f0101d16:	c1 e2 0c             	shl    $0xc,%edx
f0101d19:	39 d0                	cmp    %edx,%eax
f0101d1b:	74 19                	je     f0101d36 <mem_init+0x9c9>
f0101d1d:	68 a0 62 10 f0       	push   $0xf01062a0
f0101d22:	68 0b 69 10 f0       	push   $0xf010690b
f0101d27:	68 0e 04 00 00       	push   $0x40e
f0101d2c:	68 e5 68 10 f0       	push   $0xf01068e5
f0101d31:	e8 0a e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d36:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d3b:	74 19                	je     f0101d56 <mem_init+0x9e9>
f0101d3d:	68 f2 6a 10 f0       	push   $0xf0106af2
f0101d42:	68 0b 69 10 f0       	push   $0xf010690b
f0101d47:	68 0f 04 00 00       	push   $0x40f
f0101d4c:	68 e5 68 10 f0       	push   $0xf01068e5
f0101d51:	e8 ea e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d56:	83 ec 04             	sub    $0x4,%esp
f0101d59:	6a 00                	push   $0x0
f0101d5b:	68 00 10 00 00       	push   $0x1000
f0101d60:	57                   	push   %edi
f0101d61:	e8 05 f3 ff ff       	call   f010106b <pgdir_walk>
f0101d66:	83 c4 10             	add    $0x10,%esp
f0101d69:	f6 00 04             	testb  $0x4,(%eax)
f0101d6c:	75 19                	jne    f0101d87 <mem_init+0xa1a>
f0101d6e:	68 50 63 10 f0       	push   $0xf0106350
f0101d73:	68 0b 69 10 f0       	push   $0xf010690b
f0101d78:	68 10 04 00 00       	push   $0x410
f0101d7d:	68 e5 68 10 f0       	push   $0xf01068e5
f0101d82:	e8 b9 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d87:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101d8c:	f6 00 04             	testb  $0x4,(%eax)
f0101d8f:	75 19                	jne    f0101daa <mem_init+0xa3d>
f0101d91:	68 03 6b 10 f0       	push   $0xf0106b03
f0101d96:	68 0b 69 10 f0       	push   $0xf010690b
f0101d9b:	68 11 04 00 00       	push   $0x411
f0101da0:	68 e5 68 10 f0       	push   $0xf01068e5
f0101da5:	e8 96 e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101daa:	6a 02                	push   $0x2
f0101dac:	68 00 10 00 00       	push   $0x1000
f0101db1:	56                   	push   %esi
f0101db2:	50                   	push   %eax
f0101db3:	e8 e0 f4 ff ff       	call   f0101298 <page_insert>
f0101db8:	83 c4 10             	add    $0x10,%esp
f0101dbb:	85 c0                	test   %eax,%eax
f0101dbd:	74 19                	je     f0101dd8 <mem_init+0xa6b>
f0101dbf:	68 64 62 10 f0       	push   $0xf0106264
f0101dc4:	68 0b 69 10 f0       	push   $0xf010690b
f0101dc9:	68 14 04 00 00       	push   $0x414
f0101dce:	68 e5 68 10 f0       	push   $0xf01068e5
f0101dd3:	e8 68 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dd8:	83 ec 04             	sub    $0x4,%esp
f0101ddb:	6a 00                	push   $0x0
f0101ddd:	68 00 10 00 00       	push   $0x1000
f0101de2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101de8:	e8 7e f2 ff ff       	call   f010106b <pgdir_walk>
f0101ded:	83 c4 10             	add    $0x10,%esp
f0101df0:	f6 00 02             	testb  $0x2,(%eax)
f0101df3:	75 19                	jne    f0101e0e <mem_init+0xaa1>
f0101df5:	68 84 63 10 f0       	push   $0xf0106384
f0101dfa:	68 0b 69 10 f0       	push   $0xf010690b
f0101dff:	68 15 04 00 00       	push   $0x415
f0101e04:	68 e5 68 10 f0       	push   $0xf01068e5
f0101e09:	e8 32 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e0e:	83 ec 04             	sub    $0x4,%esp
f0101e11:	6a 00                	push   $0x0
f0101e13:	68 00 10 00 00       	push   $0x1000
f0101e18:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101e1e:	e8 48 f2 ff ff       	call   f010106b <pgdir_walk>
f0101e23:	83 c4 10             	add    $0x10,%esp
f0101e26:	f6 00 04             	testb  $0x4,(%eax)
f0101e29:	74 19                	je     f0101e44 <mem_init+0xad7>
f0101e2b:	68 b8 63 10 f0       	push   $0xf01063b8
f0101e30:	68 0b 69 10 f0       	push   $0xf010690b
f0101e35:	68 16 04 00 00       	push   $0x416
f0101e3a:	68 e5 68 10 f0       	push   $0xf01068e5
f0101e3f:	e8 fc e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e44:	6a 02                	push   $0x2
f0101e46:	68 00 00 40 00       	push   $0x400000
f0101e4b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e4e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101e54:	e8 3f f4 ff ff       	call   f0101298 <page_insert>
f0101e59:	83 c4 10             	add    $0x10,%esp
f0101e5c:	85 c0                	test   %eax,%eax
f0101e5e:	78 19                	js     f0101e79 <mem_init+0xb0c>
f0101e60:	68 f0 63 10 f0       	push   $0xf01063f0
f0101e65:	68 0b 69 10 f0       	push   $0xf010690b
f0101e6a:	68 19 04 00 00       	push   $0x419
f0101e6f:	68 e5 68 10 f0       	push   $0xf01068e5
f0101e74:	e8 c7 e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e79:	6a 02                	push   $0x2
f0101e7b:	68 00 10 00 00       	push   $0x1000
f0101e80:	53                   	push   %ebx
f0101e81:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101e87:	e8 0c f4 ff ff       	call   f0101298 <page_insert>
f0101e8c:	83 c4 10             	add    $0x10,%esp
f0101e8f:	85 c0                	test   %eax,%eax
f0101e91:	74 19                	je     f0101eac <mem_init+0xb3f>
f0101e93:	68 28 64 10 f0       	push   $0xf0106428
f0101e98:	68 0b 69 10 f0       	push   $0xf010690b
f0101e9d:	68 1c 04 00 00       	push   $0x41c
f0101ea2:	68 e5 68 10 f0       	push   $0xf01068e5
f0101ea7:	e8 94 e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101eac:	83 ec 04             	sub    $0x4,%esp
f0101eaf:	6a 00                	push   $0x0
f0101eb1:	68 00 10 00 00       	push   $0x1000
f0101eb6:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ebc:	e8 aa f1 ff ff       	call   f010106b <pgdir_walk>
f0101ec1:	83 c4 10             	add    $0x10,%esp
f0101ec4:	f6 00 04             	testb  $0x4,(%eax)
f0101ec7:	74 19                	je     f0101ee2 <mem_init+0xb75>
f0101ec9:	68 b8 63 10 f0       	push   $0xf01063b8
f0101ece:	68 0b 69 10 f0       	push   $0xf010690b
f0101ed3:	68 1d 04 00 00       	push   $0x41d
f0101ed8:	68 e5 68 10 f0       	push   $0xf01068e5
f0101edd:	e8 5e e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ee2:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101ee8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eed:	89 f8                	mov    %edi,%eax
f0101eef:	e8 bd eb ff ff       	call   f0100ab1 <check_va2pa>
f0101ef4:	89 c1                	mov    %eax,%ecx
f0101ef6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ef9:	89 d8                	mov    %ebx,%eax
f0101efb:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101f01:	c1 f8 03             	sar    $0x3,%eax
f0101f04:	c1 e0 0c             	shl    $0xc,%eax
f0101f07:	39 c1                	cmp    %eax,%ecx
f0101f09:	74 19                	je     f0101f24 <mem_init+0xbb7>
f0101f0b:	68 64 64 10 f0       	push   $0xf0106464
f0101f10:	68 0b 69 10 f0       	push   $0xf010690b
f0101f15:	68 20 04 00 00       	push   $0x420
f0101f1a:	68 e5 68 10 f0       	push   $0xf01068e5
f0101f1f:	e8 1c e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f24:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f29:	89 f8                	mov    %edi,%eax
f0101f2b:	e8 81 eb ff ff       	call   f0100ab1 <check_va2pa>
f0101f30:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101f33:	74 19                	je     f0101f4e <mem_init+0xbe1>
f0101f35:	68 90 64 10 f0       	push   $0xf0106490
f0101f3a:	68 0b 69 10 f0       	push   $0xf010690b
f0101f3f:	68 21 04 00 00       	push   $0x421
f0101f44:	68 e5 68 10 f0       	push   $0xf01068e5
f0101f49:	e8 f2 e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f4e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f53:	74 19                	je     f0101f6e <mem_init+0xc01>
f0101f55:	68 19 6b 10 f0       	push   $0xf0106b19
f0101f5a:	68 0b 69 10 f0       	push   $0xf010690b
f0101f5f:	68 23 04 00 00       	push   $0x423
f0101f64:	68 e5 68 10 f0       	push   $0xf01068e5
f0101f69:	e8 d2 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f6e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f73:	74 19                	je     f0101f8e <mem_init+0xc21>
f0101f75:	68 2a 6b 10 f0       	push   $0xf0106b2a
f0101f7a:	68 0b 69 10 f0       	push   $0xf010690b
f0101f7f:	68 24 04 00 00       	push   $0x424
f0101f84:	68 e5 68 10 f0       	push   $0xf01068e5
f0101f89:	e8 b2 e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f8e:	83 ec 0c             	sub    $0xc,%esp
f0101f91:	6a 00                	push   $0x0
f0101f93:	e8 01 f0 ff ff       	call   f0100f99 <page_alloc>
f0101f98:	83 c4 10             	add    $0x10,%esp
f0101f9b:	39 c6                	cmp    %eax,%esi
f0101f9d:	75 04                	jne    f0101fa3 <mem_init+0xc36>
f0101f9f:	85 c0                	test   %eax,%eax
f0101fa1:	75 19                	jne    f0101fbc <mem_init+0xc4f>
f0101fa3:	68 c0 64 10 f0       	push   $0xf01064c0
f0101fa8:	68 0b 69 10 f0       	push   $0xf010690b
f0101fad:	68 27 04 00 00       	push   $0x427
f0101fb2:	68 e5 68 10 f0       	push   $0xf01068e5
f0101fb7:	e8 84 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101fbc:	83 ec 08             	sub    $0x8,%esp
f0101fbf:	6a 00                	push   $0x0
f0101fc1:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101fc7:	e8 77 f2 ff ff       	call   f0101243 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fcc:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101fd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fd7:	89 f8                	mov    %edi,%eax
f0101fd9:	e8 d3 ea ff ff       	call   f0100ab1 <check_va2pa>
f0101fde:	83 c4 10             	add    $0x10,%esp
f0101fe1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fe4:	74 19                	je     f0101fff <mem_init+0xc92>
f0101fe6:	68 e4 64 10 f0       	push   $0xf01064e4
f0101feb:	68 0b 69 10 f0       	push   $0xf010690b
f0101ff0:	68 2b 04 00 00       	push   $0x42b
f0101ff5:	68 e5 68 10 f0       	push   $0xf01068e5
f0101ffa:	e8 41 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102004:	89 f8                	mov    %edi,%eax
f0102006:	e8 a6 ea ff ff       	call   f0100ab1 <check_va2pa>
f010200b:	89 da                	mov    %ebx,%edx
f010200d:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102013:	c1 fa 03             	sar    $0x3,%edx
f0102016:	c1 e2 0c             	shl    $0xc,%edx
f0102019:	39 d0                	cmp    %edx,%eax
f010201b:	74 19                	je     f0102036 <mem_init+0xcc9>
f010201d:	68 90 64 10 f0       	push   $0xf0106490
f0102022:	68 0b 69 10 f0       	push   $0xf010690b
f0102027:	68 2c 04 00 00       	push   $0x42c
f010202c:	68 e5 68 10 f0       	push   $0xf01068e5
f0102031:	e8 0a e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102036:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010203b:	74 19                	je     f0102056 <mem_init+0xce9>
f010203d:	68 d0 6a 10 f0       	push   $0xf0106ad0
f0102042:	68 0b 69 10 f0       	push   $0xf010690b
f0102047:	68 2d 04 00 00       	push   $0x42d
f010204c:	68 e5 68 10 f0       	push   $0xf01068e5
f0102051:	e8 ea df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102056:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010205b:	74 19                	je     f0102076 <mem_init+0xd09>
f010205d:	68 2a 6b 10 f0       	push   $0xf0106b2a
f0102062:	68 0b 69 10 f0       	push   $0xf010690b
f0102067:	68 2e 04 00 00       	push   $0x42e
f010206c:	68 e5 68 10 f0       	push   $0xf01068e5
f0102071:	e8 ca df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102076:	6a 00                	push   $0x0
f0102078:	68 00 10 00 00       	push   $0x1000
f010207d:	53                   	push   %ebx
f010207e:	57                   	push   %edi
f010207f:	e8 14 f2 ff ff       	call   f0101298 <page_insert>
f0102084:	83 c4 10             	add    $0x10,%esp
f0102087:	85 c0                	test   %eax,%eax
f0102089:	74 19                	je     f01020a4 <mem_init+0xd37>
f010208b:	68 08 65 10 f0       	push   $0xf0106508
f0102090:	68 0b 69 10 f0       	push   $0xf010690b
f0102095:	68 31 04 00 00       	push   $0x431
f010209a:	68 e5 68 10 f0       	push   $0xf01068e5
f010209f:	e8 9c df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01020a4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020a9:	75 19                	jne    f01020c4 <mem_init+0xd57>
f01020ab:	68 3b 6b 10 f0       	push   $0xf0106b3b
f01020b0:	68 0b 69 10 f0       	push   $0xf010690b
f01020b5:	68 32 04 00 00       	push   $0x432
f01020ba:	68 e5 68 10 f0       	push   $0xf01068e5
f01020bf:	e8 7c df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01020c4:	83 3b 00             	cmpl   $0x0,(%ebx)
f01020c7:	74 19                	je     f01020e2 <mem_init+0xd75>
f01020c9:	68 47 6b 10 f0       	push   $0xf0106b47
f01020ce:	68 0b 69 10 f0       	push   $0xf010690b
f01020d3:	68 33 04 00 00       	push   $0x433
f01020d8:	68 e5 68 10 f0       	push   $0xf01068e5
f01020dd:	e8 5e df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020e2:	83 ec 08             	sub    $0x8,%esp
f01020e5:	68 00 10 00 00       	push   $0x1000
f01020ea:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01020f0:	e8 4e f1 ff ff       	call   f0101243 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020f5:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01020fb:	ba 00 00 00 00       	mov    $0x0,%edx
f0102100:	89 f8                	mov    %edi,%eax
f0102102:	e8 aa e9 ff ff       	call   f0100ab1 <check_va2pa>
f0102107:	83 c4 10             	add    $0x10,%esp
f010210a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010210d:	74 19                	je     f0102128 <mem_init+0xdbb>
f010210f:	68 e4 64 10 f0       	push   $0xf01064e4
f0102114:	68 0b 69 10 f0       	push   $0xf010690b
f0102119:	68 37 04 00 00       	push   $0x437
f010211e:	68 e5 68 10 f0       	push   $0xf01068e5
f0102123:	e8 18 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102128:	ba 00 10 00 00       	mov    $0x1000,%edx
f010212d:	89 f8                	mov    %edi,%eax
f010212f:	e8 7d e9 ff ff       	call   f0100ab1 <check_va2pa>
f0102134:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102137:	74 19                	je     f0102152 <mem_init+0xde5>
f0102139:	68 40 65 10 f0       	push   $0xf0106540
f010213e:	68 0b 69 10 f0       	push   $0xf010690b
f0102143:	68 38 04 00 00       	push   $0x438
f0102148:	68 e5 68 10 f0       	push   $0xf01068e5
f010214d:	e8 ee de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102152:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102157:	74 19                	je     f0102172 <mem_init+0xe05>
f0102159:	68 5c 6b 10 f0       	push   $0xf0106b5c
f010215e:	68 0b 69 10 f0       	push   $0xf010690b
f0102163:	68 39 04 00 00       	push   $0x439
f0102168:	68 e5 68 10 f0       	push   $0xf01068e5
f010216d:	e8 ce de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102172:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102177:	74 19                	je     f0102192 <mem_init+0xe25>
f0102179:	68 2a 6b 10 f0       	push   $0xf0106b2a
f010217e:	68 0b 69 10 f0       	push   $0xf010690b
f0102183:	68 3a 04 00 00       	push   $0x43a
f0102188:	68 e5 68 10 f0       	push   $0xf01068e5
f010218d:	e8 ae de ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102192:	83 ec 0c             	sub    $0xc,%esp
f0102195:	6a 00                	push   $0x0
f0102197:	e8 fd ed ff ff       	call   f0100f99 <page_alloc>
f010219c:	83 c4 10             	add    $0x10,%esp
f010219f:	85 c0                	test   %eax,%eax
f01021a1:	74 04                	je     f01021a7 <mem_init+0xe3a>
f01021a3:	39 c3                	cmp    %eax,%ebx
f01021a5:	74 19                	je     f01021c0 <mem_init+0xe53>
f01021a7:	68 68 65 10 f0       	push   $0xf0106568
f01021ac:	68 0b 69 10 f0       	push   $0xf010690b
f01021b1:	68 3d 04 00 00       	push   $0x43d
f01021b6:	68 e5 68 10 f0       	push   $0xf01068e5
f01021bb:	e8 80 de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021c0:	83 ec 0c             	sub    $0xc,%esp
f01021c3:	6a 00                	push   $0x0
f01021c5:	e8 cf ed ff ff       	call   f0100f99 <page_alloc>
f01021ca:	83 c4 10             	add    $0x10,%esp
f01021cd:	85 c0                	test   %eax,%eax
f01021cf:	74 19                	je     f01021ea <mem_init+0xe7d>
f01021d1:	68 7e 6a 10 f0       	push   $0xf0106a7e
f01021d6:	68 0b 69 10 f0       	push   $0xf010690b
f01021db:	68 40 04 00 00       	push   $0x440
f01021e0:	68 e5 68 10 f0       	push   $0xf01068e5
f01021e5:	e8 56 de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021ea:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f01021f0:	8b 11                	mov    (%ecx),%edx
f01021f2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021fb:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102201:	c1 f8 03             	sar    $0x3,%eax
f0102204:	c1 e0 0c             	shl    $0xc,%eax
f0102207:	39 c2                	cmp    %eax,%edx
f0102209:	74 19                	je     f0102224 <mem_init+0xeb7>
f010220b:	68 0c 62 10 f0       	push   $0xf010620c
f0102210:	68 0b 69 10 f0       	push   $0xf010690b
f0102215:	68 43 04 00 00       	push   $0x443
f010221a:	68 e5 68 10 f0       	push   $0xf01068e5
f010221f:	e8 1c de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102224:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010222a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010222d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102232:	74 19                	je     f010224d <mem_init+0xee0>
f0102234:	68 e1 6a 10 f0       	push   $0xf0106ae1
f0102239:	68 0b 69 10 f0       	push   $0xf010690b
f010223e:	68 45 04 00 00       	push   $0x445
f0102243:	68 e5 68 10 f0       	push   $0xf01068e5
f0102248:	e8 f3 dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010224d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102250:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102256:	83 ec 0c             	sub    $0xc,%esp
f0102259:	50                   	push   %eax
f010225a:	e8 aa ed ff ff       	call   f0101009 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010225f:	83 c4 0c             	add    $0xc,%esp
f0102262:	6a 01                	push   $0x1
f0102264:	68 00 10 40 00       	push   $0x401000
f0102269:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010226f:	e8 f7 ed ff ff       	call   f010106b <pgdir_walk>
f0102274:	89 c7                	mov    %eax,%edi
f0102276:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102279:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010227e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102281:	8b 40 04             	mov    0x4(%eax),%eax
f0102284:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102289:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f010228f:	89 c2                	mov    %eax,%edx
f0102291:	c1 ea 0c             	shr    $0xc,%edx
f0102294:	83 c4 10             	add    $0x10,%esp
f0102297:	39 ca                	cmp    %ecx,%edx
f0102299:	72 15                	jb     f01022b0 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010229b:	50                   	push   %eax
f010229c:	68 c4 59 10 f0       	push   $0xf01059c4
f01022a1:	68 4c 04 00 00       	push   $0x44c
f01022a6:	68 e5 68 10 f0       	push   $0xf01068e5
f01022ab:	e8 90 dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01022b0:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01022b5:	39 c7                	cmp    %eax,%edi
f01022b7:	74 19                	je     f01022d2 <mem_init+0xf65>
f01022b9:	68 6d 6b 10 f0       	push   $0xf0106b6d
f01022be:	68 0b 69 10 f0       	push   $0xf010690b
f01022c3:	68 4d 04 00 00       	push   $0x44d
f01022c8:	68 e5 68 10 f0       	push   $0xf01068e5
f01022cd:	e8 6e dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01022d2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01022d5:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01022dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022df:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022e5:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01022eb:	c1 f8 03             	sar    $0x3,%eax
f01022ee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022f1:	89 c2                	mov    %eax,%edx
f01022f3:	c1 ea 0c             	shr    $0xc,%edx
f01022f6:	39 d1                	cmp    %edx,%ecx
f01022f8:	77 12                	ja     f010230c <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022fa:	50                   	push   %eax
f01022fb:	68 c4 59 10 f0       	push   $0xf01059c4
f0102300:	6a 58                	push   $0x58
f0102302:	68 f1 68 10 f0       	push   $0xf01068f1
f0102307:	e8 34 dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010230c:	83 ec 04             	sub    $0x4,%esp
f010230f:	68 00 10 00 00       	push   $0x1000
f0102314:	68 ff 00 00 00       	push   $0xff
f0102319:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010231e:	50                   	push   %eax
f010231f:	e8 c0 29 00 00       	call   f0104ce4 <memset>
	page_free(pp0);
f0102324:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102327:	89 3c 24             	mov    %edi,(%esp)
f010232a:	e8 da ec ff ff       	call   f0101009 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010232f:	83 c4 0c             	add    $0xc,%esp
f0102332:	6a 01                	push   $0x1
f0102334:	6a 00                	push   $0x0
f0102336:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010233c:	e8 2a ed ff ff       	call   f010106b <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102341:	89 fa                	mov    %edi,%edx
f0102343:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102349:	c1 fa 03             	sar    $0x3,%edx
f010234c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010234f:	89 d0                	mov    %edx,%eax
f0102351:	c1 e8 0c             	shr    $0xc,%eax
f0102354:	83 c4 10             	add    $0x10,%esp
f0102357:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010235d:	72 12                	jb     f0102371 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010235f:	52                   	push   %edx
f0102360:	68 c4 59 10 f0       	push   $0xf01059c4
f0102365:	6a 58                	push   $0x58
f0102367:	68 f1 68 10 f0       	push   $0xf01068f1
f010236c:	e8 cf dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102371:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102377:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010237a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102380:	f6 00 01             	testb  $0x1,(%eax)
f0102383:	74 19                	je     f010239e <mem_init+0x1031>
f0102385:	68 85 6b 10 f0       	push   $0xf0106b85
f010238a:	68 0b 69 10 f0       	push   $0xf010690b
f010238f:	68 57 04 00 00       	push   $0x457
f0102394:	68 e5 68 10 f0       	push   $0xf01068e5
f0102399:	e8 a2 dc ff ff       	call   f0100040 <_panic>
f010239e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01023a1:	39 d0                	cmp    %edx,%eax
f01023a3:	75 db                	jne    f0102380 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01023a5:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01023aa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01023b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023b3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01023b9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01023bc:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f01023c2:	83 ec 0c             	sub    $0xc,%esp
f01023c5:	50                   	push   %eax
f01023c6:	e8 3e ec ff ff       	call   f0101009 <page_free>
	page_free(pp1);
f01023cb:	89 1c 24             	mov    %ebx,(%esp)
f01023ce:	e8 36 ec ff ff       	call   f0101009 <page_free>
	page_free(pp2);
f01023d3:	89 34 24             	mov    %esi,(%esp)
f01023d6:	e8 2e ec ff ff       	call   f0101009 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01023db:	83 c4 08             	add    $0x8,%esp
f01023de:	68 01 10 00 00       	push   $0x1001
f01023e3:	6a 00                	push   $0x0
f01023e5:	e8 20 ef ff ff       	call   f010130a <mmio_map_region>
f01023ea:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01023ec:	83 c4 08             	add    $0x8,%esp
f01023ef:	68 00 10 00 00       	push   $0x1000
f01023f4:	6a 00                	push   $0x0
f01023f6:	e8 0f ef ff ff       	call   f010130a <mmio_map_region>
f01023fb:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01023fd:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102403:	83 c4 10             	add    $0x10,%esp
f0102406:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010240c:	76 07                	jbe    f0102415 <mem_init+0x10a8>
f010240e:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102413:	76 19                	jbe    f010242e <mem_init+0x10c1>
f0102415:	68 8c 65 10 f0       	push   $0xf010658c
f010241a:	68 0b 69 10 f0       	push   $0xf010690b
f010241f:	68 67 04 00 00       	push   $0x467
f0102424:	68 e5 68 10 f0       	push   $0xf01068e5
f0102429:	e8 12 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f010242e:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102434:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010243a:	77 08                	ja     f0102444 <mem_init+0x10d7>
f010243c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102442:	77 19                	ja     f010245d <mem_init+0x10f0>
f0102444:	68 b4 65 10 f0       	push   $0xf01065b4
f0102449:	68 0b 69 10 f0       	push   $0xf010690b
f010244e:	68 68 04 00 00       	push   $0x468
f0102453:	68 e5 68 10 f0       	push   $0xf01068e5
f0102458:	e8 e3 db ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f010245d:	89 da                	mov    %ebx,%edx
f010245f:	09 f2                	or     %esi,%edx
f0102461:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102467:	74 19                	je     f0102482 <mem_init+0x1115>
f0102469:	68 dc 65 10 f0       	push   $0xf01065dc
f010246e:	68 0b 69 10 f0       	push   $0xf010690b
f0102473:	68 6a 04 00 00       	push   $0x46a
f0102478:	68 e5 68 10 f0       	push   $0xf01068e5
f010247d:	e8 be db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102482:	39 c6                	cmp    %eax,%esi
f0102484:	73 19                	jae    f010249f <mem_init+0x1132>
f0102486:	68 9c 6b 10 f0       	push   $0xf0106b9c
f010248b:	68 0b 69 10 f0       	push   $0xf010690b
f0102490:	68 6c 04 00 00       	push   $0x46c
f0102495:	68 e5 68 10 f0       	push   $0xf01068e5
f010249a:	e8 a1 db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010249f:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01024a5:	89 da                	mov    %ebx,%edx
f01024a7:	89 f8                	mov    %edi,%eax
f01024a9:	e8 03 e6 ff ff       	call   f0100ab1 <check_va2pa>
f01024ae:	85 c0                	test   %eax,%eax
f01024b0:	74 19                	je     f01024cb <mem_init+0x115e>
f01024b2:	68 04 66 10 f0       	push   $0xf0106604
f01024b7:	68 0b 69 10 f0       	push   $0xf010690b
f01024bc:	68 6e 04 00 00       	push   $0x46e
f01024c1:	68 e5 68 10 f0       	push   $0xf01068e5
f01024c6:	e8 75 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01024cb:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01024d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01024d4:	89 c2                	mov    %eax,%edx
f01024d6:	89 f8                	mov    %edi,%eax
f01024d8:	e8 d4 e5 ff ff       	call   f0100ab1 <check_va2pa>
f01024dd:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01024e2:	74 19                	je     f01024fd <mem_init+0x1190>
f01024e4:	68 28 66 10 f0       	push   $0xf0106628
f01024e9:	68 0b 69 10 f0       	push   $0xf010690b
f01024ee:	68 6f 04 00 00       	push   $0x46f
f01024f3:	68 e5 68 10 f0       	push   $0xf01068e5
f01024f8:	e8 43 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01024fd:	89 f2                	mov    %esi,%edx
f01024ff:	89 f8                	mov    %edi,%eax
f0102501:	e8 ab e5 ff ff       	call   f0100ab1 <check_va2pa>
f0102506:	85 c0                	test   %eax,%eax
f0102508:	74 19                	je     f0102523 <mem_init+0x11b6>
f010250a:	68 58 66 10 f0       	push   $0xf0106658
f010250f:	68 0b 69 10 f0       	push   $0xf010690b
f0102514:	68 70 04 00 00       	push   $0x470
f0102519:	68 e5 68 10 f0       	push   $0xf01068e5
f010251e:	e8 1d db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102523:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102529:	89 f8                	mov    %edi,%eax
f010252b:	e8 81 e5 ff ff       	call   f0100ab1 <check_va2pa>
f0102530:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102533:	74 19                	je     f010254e <mem_init+0x11e1>
f0102535:	68 7c 66 10 f0       	push   $0xf010667c
f010253a:	68 0b 69 10 f0       	push   $0xf010690b
f010253f:	68 71 04 00 00       	push   $0x471
f0102544:	68 e5 68 10 f0       	push   $0xf01068e5
f0102549:	e8 f2 da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010254e:	83 ec 04             	sub    $0x4,%esp
f0102551:	6a 00                	push   $0x0
f0102553:	53                   	push   %ebx
f0102554:	57                   	push   %edi
f0102555:	e8 11 eb ff ff       	call   f010106b <pgdir_walk>
f010255a:	83 c4 10             	add    $0x10,%esp
f010255d:	f6 00 1a             	testb  $0x1a,(%eax)
f0102560:	75 19                	jne    f010257b <mem_init+0x120e>
f0102562:	68 a8 66 10 f0       	push   $0xf01066a8
f0102567:	68 0b 69 10 f0       	push   $0xf010690b
f010256c:	68 73 04 00 00       	push   $0x473
f0102571:	68 e5 68 10 f0       	push   $0xf01068e5
f0102576:	e8 c5 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010257b:	83 ec 04             	sub    $0x4,%esp
f010257e:	6a 00                	push   $0x0
f0102580:	53                   	push   %ebx
f0102581:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102587:	e8 df ea ff ff       	call   f010106b <pgdir_walk>
f010258c:	8b 00                	mov    (%eax),%eax
f010258e:	83 c4 10             	add    $0x10,%esp
f0102591:	83 e0 04             	and    $0x4,%eax
f0102594:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102597:	74 19                	je     f01025b2 <mem_init+0x1245>
f0102599:	68 ec 66 10 f0       	push   $0xf01066ec
f010259e:	68 0b 69 10 f0       	push   $0xf010690b
f01025a3:	68 74 04 00 00       	push   $0x474
f01025a8:	68 e5 68 10 f0       	push   $0xf01068e5
f01025ad:	e8 8e da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01025b2:	83 ec 04             	sub    $0x4,%esp
f01025b5:	6a 00                	push   $0x0
f01025b7:	53                   	push   %ebx
f01025b8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01025be:	e8 a8 ea ff ff       	call   f010106b <pgdir_walk>
f01025c3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01025c9:	83 c4 0c             	add    $0xc,%esp
f01025cc:	6a 00                	push   $0x0
f01025ce:	ff 75 d4             	pushl  -0x2c(%ebp)
f01025d1:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01025d7:	e8 8f ea ff ff       	call   f010106b <pgdir_walk>
f01025dc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01025e2:	83 c4 0c             	add    $0xc,%esp
f01025e5:	6a 00                	push   $0x0
f01025e7:	56                   	push   %esi
f01025e8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01025ee:	e8 78 ea ff ff       	call   f010106b <pgdir_walk>
f01025f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01025f9:	c7 04 24 ae 6b 10 f0 	movl   $0xf0106bae,(%esp)
f0102600:	e8 53 10 00 00       	call   f0103658 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_U));
f0102605:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010260a:	83 c4 10             	add    $0x10,%esp
f010260d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102612:	77 15                	ja     f0102629 <mem_init+0x12bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102614:	50                   	push   %eax
f0102615:	68 e8 59 10 f0       	push   $0xf01059e8
f010261a:	68 cd 00 00 00       	push   $0xcd
f010261f:	68 e5 68 10 f0       	push   $0xf01068e5
f0102624:	e8 17 da ff ff       	call   f0100040 <_panic>
f0102629:	83 ec 08             	sub    $0x8,%esp
f010262c:	6a 05                	push   $0x5
f010262e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102633:	50                   	push   %eax
f0102634:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102639:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010263e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102643:	e8 f5 ea ff ff       	call   f010113d <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_U));
f0102648:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010264d:	83 c4 10             	add    $0x10,%esp
f0102650:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102655:	77 15                	ja     f010266c <mem_init+0x12ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102657:	50                   	push   %eax
f0102658:	68 e8 59 10 f0       	push   $0xf01059e8
f010265d:	68 d7 00 00 00       	push   $0xd7
f0102662:	68 e5 68 10 f0       	push   $0xf01068e5
f0102667:	e8 d4 d9 ff ff       	call   f0100040 <_panic>
f010266c:	83 ec 08             	sub    $0x8,%esp
f010266f:	6a 05                	push   $0x5
f0102671:	05 00 00 00 10       	add    $0x10000000,%eax
f0102676:	50                   	push   %eax
f0102677:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010267c:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102681:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102686:	e8 b2 ea ff ff       	call   f010113d <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010268b:	83 c4 10             	add    $0x10,%esp
f010268e:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f0102693:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102698:	77 15                	ja     f01026af <mem_init+0x1342>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010269a:	50                   	push   %eax
f010269b:	68 e8 59 10 f0       	push   $0xf01059e8
f01026a0:	68 e4 00 00 00       	push   $0xe4
f01026a5:	68 e5 68 10 f0       	push   $0xf01068e5
f01026aa:	e8 91 d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01026af:	83 ec 08             	sub    $0x8,%esp
f01026b2:	6a 02                	push   $0x2
f01026b4:	68 00 50 11 00       	push   $0x115000
f01026b9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026be:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026c3:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01026c8:	e8 70 ea ff ff       	call   f010113d <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f01026cd:	83 c4 08             	add    $0x8,%esp
f01026d0:	6a 02                	push   $0x2
f01026d2:	6a 00                	push   $0x0
f01026d4:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01026d9:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026de:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01026e3:	e8 55 ea ff ff       	call   f010113d <boot_map_region>
f01026e8:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f01026ef:	83 c4 10             	add    $0x10,%esp
f01026f2:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f01026f7:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026fc:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102702:	77 15                	ja     f0102719 <mem_init+0x13ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102704:	53                   	push   %ebx
f0102705:	68 e8 59 10 f0       	push   $0xf01059e8
f010270a:	68 24 01 00 00       	push   $0x124
f010270f:	68 e5 68 10 f0       	push   $0xf01068e5
f0102714:	e8 27 d9 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
	{
		boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE - i * (KSTKSIZE + KSTKGAP), KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f0102719:	83 ec 08             	sub    $0x8,%esp
f010271c:	6a 02                	push   $0x2
f010271e:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102724:	50                   	push   %eax
f0102725:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010272a:	89 f2                	mov    %esi,%edx
f010272c:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102731:	e8 07 ea ff ff       	call   f010113d <boot_map_region>
f0102736:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010273c:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
f0102742:	83 c4 10             	add    $0x10,%esp
f0102745:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f010274a:	39 d8                	cmp    %ebx,%eax
f010274c:	75 ae                	jne    f01026fc <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010274e:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102754:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0102759:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010275c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102763:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102768:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010276b:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102771:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102774:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102779:	eb 55                	jmp    f01027d0 <mem_init+0x1463>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010277b:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102781:	89 f8                	mov    %edi,%eax
f0102783:	e8 29 e3 ff ff       	call   f0100ab1 <check_va2pa>
f0102788:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010278f:	77 15                	ja     f01027a6 <mem_init+0x1439>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102791:	56                   	push   %esi
f0102792:	68 e8 59 10 f0       	push   $0xf01059e8
f0102797:	68 8c 03 00 00       	push   $0x38c
f010279c:	68 e5 68 10 f0       	push   $0xf01068e5
f01027a1:	e8 9a d8 ff ff       	call   f0100040 <_panic>
f01027a6:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01027ad:	39 c2                	cmp    %eax,%edx
f01027af:	74 19                	je     f01027ca <mem_init+0x145d>
f01027b1:	68 20 67 10 f0       	push   $0xf0106720
f01027b6:	68 0b 69 10 f0       	push   $0xf010690b
f01027bb:	68 8c 03 00 00       	push   $0x38c
f01027c0:	68 e5 68 10 f0       	push   $0xf01068e5
f01027c5:	e8 76 d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027ca:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027d0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01027d3:	77 a6                	ja     f010277b <mem_init+0x140e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01027d5:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027db:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027de:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01027e3:	89 da                	mov    %ebx,%edx
f01027e5:	89 f8                	mov    %edi,%eax
f01027e7:	e8 c5 e2 ff ff       	call   f0100ab1 <check_va2pa>
f01027ec:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01027f3:	77 15                	ja     f010280a <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027f5:	56                   	push   %esi
f01027f6:	68 e8 59 10 f0       	push   $0xf01059e8
f01027fb:	68 91 03 00 00       	push   $0x391
f0102800:	68 e5 68 10 f0       	push   $0xf01068e5
f0102805:	e8 36 d8 ff ff       	call   f0100040 <_panic>
f010280a:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102811:	39 d0                	cmp    %edx,%eax
f0102813:	74 19                	je     f010282e <mem_init+0x14c1>
f0102815:	68 54 67 10 f0       	push   $0xf0106754
f010281a:	68 0b 69 10 f0       	push   $0xf010690b
f010281f:	68 91 03 00 00       	push   $0x391
f0102824:	68 e5 68 10 f0       	push   $0xf01068e5
f0102829:	e8 12 d8 ff ff       	call   f0100040 <_panic>
f010282e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102834:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010283a:	75 a7                	jne    f01027e3 <mem_init+0x1476>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010283c:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010283f:	c1 e6 0c             	shl    $0xc,%esi
f0102842:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102847:	eb 30                	jmp    f0102879 <mem_init+0x150c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102849:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010284f:	89 f8                	mov    %edi,%eax
f0102851:	e8 5b e2 ff ff       	call   f0100ab1 <check_va2pa>
f0102856:	39 c3                	cmp    %eax,%ebx
f0102858:	74 19                	je     f0102873 <mem_init+0x1506>
f010285a:	68 88 67 10 f0       	push   $0xf0106788
f010285f:	68 0b 69 10 f0       	push   $0xf010690b
f0102864:	68 95 03 00 00       	push   $0x395
f0102869:	68 e5 68 10 f0       	push   $0xf01068e5
f010286e:	e8 cd d7 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102873:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102879:	39 f3                	cmp    %esi,%ebx
f010287b:	72 cc                	jb     f0102849 <mem_init+0x14dc>
f010287d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102882:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102885:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102888:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010288b:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102891:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102894:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102896:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102899:	05 00 80 00 20       	add    $0x20008000,%eax
f010289e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01028a1:	89 da                	mov    %ebx,%edx
f01028a3:	89 f8                	mov    %edi,%eax
f01028a5:	e8 07 e2 ff ff       	call   f0100ab1 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028aa:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01028b0:	77 15                	ja     f01028c7 <mem_init+0x155a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028b2:	56                   	push   %esi
f01028b3:	68 e8 59 10 f0       	push   $0xf01059e8
f01028b8:	68 9d 03 00 00       	push   $0x39d
f01028bd:	68 e5 68 10 f0       	push   $0xf01068e5
f01028c2:	e8 79 d7 ff ff       	call   f0100040 <_panic>
f01028c7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01028ca:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f01028d1:	39 d0                	cmp    %edx,%eax
f01028d3:	74 19                	je     f01028ee <mem_init+0x1581>
f01028d5:	68 b0 67 10 f0       	push   $0xf01067b0
f01028da:	68 0b 69 10 f0       	push   $0xf010690b
f01028df:	68 9d 03 00 00       	push   $0x39d
f01028e4:	68 e5 68 10 f0       	push   $0xf01068e5
f01028e9:	e8 52 d7 ff ff       	call   f0100040 <_panic>
f01028ee:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028f4:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01028f7:	75 a8                	jne    f01028a1 <mem_init+0x1534>
f01028f9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028fc:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102902:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102905:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102907:	89 da                	mov    %ebx,%edx
f0102909:	89 f8                	mov    %edi,%eax
f010290b:	e8 a1 e1 ff ff       	call   f0100ab1 <check_va2pa>
f0102910:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102913:	74 19                	je     f010292e <mem_init+0x15c1>
f0102915:	68 f8 67 10 f0       	push   $0xf01067f8
f010291a:	68 0b 69 10 f0       	push   $0xf010690b
f010291f:	68 9f 03 00 00       	push   $0x39f
f0102924:	68 e5 68 10 f0       	push   $0xf01068e5
f0102929:	e8 12 d7 ff ff       	call   f0100040 <_panic>
f010292e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102934:	39 f3                	cmp    %esi,%ebx
f0102936:	75 cf                	jne    f0102907 <mem_init+0x159a>
f0102938:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010293b:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102942:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102949:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f010294f:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f0102954:	39 f0                	cmp    %esi,%eax
f0102956:	0f 85 2c ff ff ff    	jne    f0102888 <mem_init+0x151b>
f010295c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102961:	eb 2a                	jmp    f010298d <mem_init+0x1620>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102963:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102969:	83 fa 04             	cmp    $0x4,%edx
f010296c:	77 1f                	ja     f010298d <mem_init+0x1620>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010296e:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102972:	75 7e                	jne    f01029f2 <mem_init+0x1685>
f0102974:	68 c7 6b 10 f0       	push   $0xf0106bc7
f0102979:	68 0b 69 10 f0       	push   $0xf010690b
f010297e:	68 aa 03 00 00       	push   $0x3aa
f0102983:	68 e5 68 10 f0       	push   $0xf01068e5
f0102988:	e8 b3 d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010298d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102992:	76 3f                	jbe    f01029d3 <mem_init+0x1666>
				assert(pgdir[i] & PTE_P);
f0102994:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102997:	f6 c2 01             	test   $0x1,%dl
f010299a:	75 19                	jne    f01029b5 <mem_init+0x1648>
f010299c:	68 c7 6b 10 f0       	push   $0xf0106bc7
f01029a1:	68 0b 69 10 f0       	push   $0xf010690b
f01029a6:	68 ae 03 00 00       	push   $0x3ae
f01029ab:	68 e5 68 10 f0       	push   $0xf01068e5
f01029b0:	e8 8b d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01029b5:	f6 c2 02             	test   $0x2,%dl
f01029b8:	75 38                	jne    f01029f2 <mem_init+0x1685>
f01029ba:	68 d8 6b 10 f0       	push   $0xf0106bd8
f01029bf:	68 0b 69 10 f0       	push   $0xf010690b
f01029c4:	68 af 03 00 00       	push   $0x3af
f01029c9:	68 e5 68 10 f0       	push   $0xf01068e5
f01029ce:	e8 6d d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01029d3:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029d7:	74 19                	je     f01029f2 <mem_init+0x1685>
f01029d9:	68 e9 6b 10 f0       	push   $0xf0106be9
f01029de:	68 0b 69 10 f0       	push   $0xf010690b
f01029e3:	68 b1 03 00 00       	push   $0x3b1
f01029e8:	68 e5 68 10 f0       	push   $0xf01068e5
f01029ed:	e8 4e d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029f2:	83 c0 01             	add    $0x1,%eax
f01029f5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01029fa:	0f 86 63 ff ff ff    	jbe    f0102963 <mem_init+0x15f6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a00:	83 ec 0c             	sub    $0xc,%esp
f0102a03:	68 1c 68 10 f0       	push   $0xf010681c
f0102a08:	e8 4b 0c 00 00       	call   f0103658 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a0d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a12:	83 c4 10             	add    $0x10,%esp
f0102a15:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a1a:	77 15                	ja     f0102a31 <mem_init+0x16c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a1c:	50                   	push   %eax
f0102a1d:	68 e8 59 10 f0       	push   $0xf01059e8
f0102a22:	68 fb 00 00 00       	push   $0xfb
f0102a27:	68 e5 68 10 f0       	push   $0xf01068e5
f0102a2c:	e8 0f d6 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a31:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a36:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a39:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a3e:	e8 53 e1 ff ff       	call   f0100b96 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a43:	0f 20 c0             	mov    %cr0,%eax
f0102a46:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a49:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a4e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a51:	83 ec 0c             	sub    $0xc,%esp
f0102a54:	6a 00                	push   $0x0
f0102a56:	e8 3e e5 ff ff       	call   f0100f99 <page_alloc>
f0102a5b:	89 c7                	mov    %eax,%edi
f0102a5d:	83 c4 10             	add    $0x10,%esp
f0102a60:	85 c0                	test   %eax,%eax
f0102a62:	75 19                	jne    f0102a7d <mem_init+0x1710>
f0102a64:	68 d3 69 10 f0       	push   $0xf01069d3
f0102a69:	68 0b 69 10 f0       	push   $0xf010690b
f0102a6e:	68 89 04 00 00       	push   $0x489
f0102a73:	68 e5 68 10 f0       	push   $0xf01068e5
f0102a78:	e8 c3 d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a7d:	83 ec 0c             	sub    $0xc,%esp
f0102a80:	6a 00                	push   $0x0
f0102a82:	e8 12 e5 ff ff       	call   f0100f99 <page_alloc>
f0102a87:	89 c6                	mov    %eax,%esi
f0102a89:	83 c4 10             	add    $0x10,%esp
f0102a8c:	85 c0                	test   %eax,%eax
f0102a8e:	75 19                	jne    f0102aa9 <mem_init+0x173c>
f0102a90:	68 e9 69 10 f0       	push   $0xf01069e9
f0102a95:	68 0b 69 10 f0       	push   $0xf010690b
f0102a9a:	68 8a 04 00 00       	push   $0x48a
f0102a9f:	68 e5 68 10 f0       	push   $0xf01068e5
f0102aa4:	e8 97 d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102aa9:	83 ec 0c             	sub    $0xc,%esp
f0102aac:	6a 00                	push   $0x0
f0102aae:	e8 e6 e4 ff ff       	call   f0100f99 <page_alloc>
f0102ab3:	89 c3                	mov    %eax,%ebx
f0102ab5:	83 c4 10             	add    $0x10,%esp
f0102ab8:	85 c0                	test   %eax,%eax
f0102aba:	75 19                	jne    f0102ad5 <mem_init+0x1768>
f0102abc:	68 ff 69 10 f0       	push   $0xf01069ff
f0102ac1:	68 0b 69 10 f0       	push   $0xf010690b
f0102ac6:	68 8b 04 00 00       	push   $0x48b
f0102acb:	68 e5 68 10 f0       	push   $0xf01068e5
f0102ad0:	e8 6b d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102ad5:	83 ec 0c             	sub    $0xc,%esp
f0102ad8:	57                   	push   %edi
f0102ad9:	e8 2b e5 ff ff       	call   f0101009 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ade:	89 f0                	mov    %esi,%eax
f0102ae0:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102ae6:	c1 f8 03             	sar    $0x3,%eax
f0102ae9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102aec:	89 c2                	mov    %eax,%edx
f0102aee:	c1 ea 0c             	shr    $0xc,%edx
f0102af1:	83 c4 10             	add    $0x10,%esp
f0102af4:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102afa:	72 12                	jb     f0102b0e <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102afc:	50                   	push   %eax
f0102afd:	68 c4 59 10 f0       	push   $0xf01059c4
f0102b02:	6a 58                	push   $0x58
f0102b04:	68 f1 68 10 f0       	push   $0xf01068f1
f0102b09:	e8 32 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b0e:	83 ec 04             	sub    $0x4,%esp
f0102b11:	68 00 10 00 00       	push   $0x1000
f0102b16:	6a 01                	push   $0x1
f0102b18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b1d:	50                   	push   %eax
f0102b1e:	e8 c1 21 00 00       	call   f0104ce4 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b23:	89 d8                	mov    %ebx,%eax
f0102b25:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b2b:	c1 f8 03             	sar    $0x3,%eax
f0102b2e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b31:	89 c2                	mov    %eax,%edx
f0102b33:	c1 ea 0c             	shr    $0xc,%edx
f0102b36:	83 c4 10             	add    $0x10,%esp
f0102b39:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102b3f:	72 12                	jb     f0102b53 <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b41:	50                   	push   %eax
f0102b42:	68 c4 59 10 f0       	push   $0xf01059c4
f0102b47:	6a 58                	push   $0x58
f0102b49:	68 f1 68 10 f0       	push   $0xf01068f1
f0102b4e:	e8 ed d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b53:	83 ec 04             	sub    $0x4,%esp
f0102b56:	68 00 10 00 00       	push   $0x1000
f0102b5b:	6a 02                	push   $0x2
f0102b5d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b62:	50                   	push   %eax
f0102b63:	e8 7c 21 00 00       	call   f0104ce4 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b68:	6a 02                	push   $0x2
f0102b6a:	68 00 10 00 00       	push   $0x1000
f0102b6f:	56                   	push   %esi
f0102b70:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102b76:	e8 1d e7 ff ff       	call   f0101298 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b7b:	83 c4 20             	add    $0x20,%esp
f0102b7e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b83:	74 19                	je     f0102b9e <mem_init+0x1831>
f0102b85:	68 d0 6a 10 f0       	push   $0xf0106ad0
f0102b8a:	68 0b 69 10 f0       	push   $0xf010690b
f0102b8f:	68 90 04 00 00       	push   $0x490
f0102b94:	68 e5 68 10 f0       	push   $0xf01068e5
f0102b99:	e8 a2 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b9e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ba5:	01 01 01 
f0102ba8:	74 19                	je     f0102bc3 <mem_init+0x1856>
f0102baa:	68 3c 68 10 f0       	push   $0xf010683c
f0102baf:	68 0b 69 10 f0       	push   $0xf010690b
f0102bb4:	68 91 04 00 00       	push   $0x491
f0102bb9:	68 e5 68 10 f0       	push   $0xf01068e5
f0102bbe:	e8 7d d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bc3:	6a 02                	push   $0x2
f0102bc5:	68 00 10 00 00       	push   $0x1000
f0102bca:	53                   	push   %ebx
f0102bcb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102bd1:	e8 c2 e6 ff ff       	call   f0101298 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bd6:	83 c4 10             	add    $0x10,%esp
f0102bd9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102be0:	02 02 02 
f0102be3:	74 19                	je     f0102bfe <mem_init+0x1891>
f0102be5:	68 60 68 10 f0       	push   $0xf0106860
f0102bea:	68 0b 69 10 f0       	push   $0xf010690b
f0102bef:	68 93 04 00 00       	push   $0x493
f0102bf4:	68 e5 68 10 f0       	push   $0xf01068e5
f0102bf9:	e8 42 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102bfe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c03:	74 19                	je     f0102c1e <mem_init+0x18b1>
f0102c05:	68 f2 6a 10 f0       	push   $0xf0106af2
f0102c0a:	68 0b 69 10 f0       	push   $0xf010690b
f0102c0f:	68 94 04 00 00       	push   $0x494
f0102c14:	68 e5 68 10 f0       	push   $0xf01068e5
f0102c19:	e8 22 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102c1e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c23:	74 19                	je     f0102c3e <mem_init+0x18d1>
f0102c25:	68 5c 6b 10 f0       	push   $0xf0106b5c
f0102c2a:	68 0b 69 10 f0       	push   $0xf010690b
f0102c2f:	68 95 04 00 00       	push   $0x495
f0102c34:	68 e5 68 10 f0       	push   $0xf01068e5
f0102c39:	e8 02 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c3e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c45:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c48:	89 d8                	mov    %ebx,%eax
f0102c4a:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102c50:	c1 f8 03             	sar    $0x3,%eax
f0102c53:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c56:	89 c2                	mov    %eax,%edx
f0102c58:	c1 ea 0c             	shr    $0xc,%edx
f0102c5b:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102c61:	72 12                	jb     f0102c75 <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c63:	50                   	push   %eax
f0102c64:	68 c4 59 10 f0       	push   $0xf01059c4
f0102c69:	6a 58                	push   $0x58
f0102c6b:	68 f1 68 10 f0       	push   $0xf01068f1
f0102c70:	e8 cb d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c75:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c7c:	03 03 03 
f0102c7f:	74 19                	je     f0102c9a <mem_init+0x192d>
f0102c81:	68 84 68 10 f0       	push   $0xf0106884
f0102c86:	68 0b 69 10 f0       	push   $0xf010690b
f0102c8b:	68 97 04 00 00       	push   $0x497
f0102c90:	68 e5 68 10 f0       	push   $0xf01068e5
f0102c95:	e8 a6 d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c9a:	83 ec 08             	sub    $0x8,%esp
f0102c9d:	68 00 10 00 00       	push   $0x1000
f0102ca2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102ca8:	e8 96 e5 ff ff       	call   f0101243 <page_remove>
	assert(pp2->pp_ref == 0);
f0102cad:	83 c4 10             	add    $0x10,%esp
f0102cb0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102cb5:	74 19                	je     f0102cd0 <mem_init+0x1963>
f0102cb7:	68 2a 6b 10 f0       	push   $0xf0106b2a
f0102cbc:	68 0b 69 10 f0       	push   $0xf010690b
f0102cc1:	68 99 04 00 00       	push   $0x499
f0102cc6:	68 e5 68 10 f0       	push   $0xf01068e5
f0102ccb:	e8 70 d3 ff ff       	call   f0100040 <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102cd0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cd3:	5b                   	pop    %ebx
f0102cd4:	5e                   	pop    %esi
f0102cd5:	5f                   	pop    %edi
f0102cd6:	5d                   	pop    %ebp
f0102cd7:	c3                   	ret    

f0102cd8 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102cd8:	55                   	push   %ebp
f0102cd9:	89 e5                	mov    %esp,%ebp
f0102cdb:	57                   	push   %edi
f0102cdc:	56                   	push   %esi
f0102cdd:	53                   	push   %ebx
f0102cde:	83 ec 1c             	sub    $0x1c,%esp
f0102ce1:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102ce4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ce7:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);
f0102cea:	89 d8                	mov    %ebx,%eax
f0102cec:	03 45 10             	add    0x10(%ebp),%eax
f0102cef:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102cf4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102cf9:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f0102cfc:	eb 3e                	jmp    f0102d3c <user_mem_check+0x64>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, va, 0);
f0102cfe:	83 ec 04             	sub    $0x4,%esp
f0102d01:	6a 00                	push   $0x0
f0102d03:	53                   	push   %ebx
f0102d04:	ff 77 60             	pushl  0x60(%edi)
f0102d07:	e8 5f e3 ff ff       	call   f010106b <pgdir_walk>

		if ((va >= (void*) ULIM) || !pte || ((*pte & perm) != perm))
f0102d0c:	83 c4 10             	add    $0x10,%esp
f0102d0f:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d15:	77 0c                	ja     f0102d23 <user_mem_check+0x4b>
f0102d17:	85 c0                	test   %eax,%eax
f0102d19:	74 08                	je     f0102d23 <user_mem_check+0x4b>
f0102d1b:	89 f2                	mov    %esi,%edx
f0102d1d:	23 10                	and    (%eax),%edx
f0102d1f:	39 d6                	cmp    %edx,%esi
f0102d21:	74 0d                	je     f0102d30 <user_mem_check+0x58>
		{
			user_mem_check_addr = (uint32_t) va;
f0102d23:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102d29:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d2e:	eb 16                	jmp    f0102d46 <user_mem_check+0x6e>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f0102d30:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d36:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102d3c:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d3f:	72 bd                	jb     f0102cfe <user_mem_check+0x26>
			user_mem_check_addr = (uint32_t) va;
			return -E_FAULT;
		}		
	}

	return 0;
f0102d41:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d46:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d49:	5b                   	pop    %ebx
f0102d4a:	5e                   	pop    %esi
f0102d4b:	5f                   	pop    %edi
f0102d4c:	5d                   	pop    %ebp
f0102d4d:	c3                   	ret    

f0102d4e <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d4e:	55                   	push   %ebp
f0102d4f:	89 e5                	mov    %esp,%ebp
f0102d51:	53                   	push   %ebx
f0102d52:	83 ec 04             	sub    $0x4,%esp
f0102d55:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d58:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d5b:	83 c8 04             	or     $0x4,%eax
f0102d5e:	50                   	push   %eax
f0102d5f:	ff 75 10             	pushl  0x10(%ebp)
f0102d62:	ff 75 0c             	pushl  0xc(%ebp)
f0102d65:	53                   	push   %ebx
f0102d66:	e8 6d ff ff ff       	call   f0102cd8 <user_mem_check>
f0102d6b:	83 c4 10             	add    $0x10,%esp
f0102d6e:	85 c0                	test   %eax,%eax
f0102d70:	79 21                	jns    f0102d93 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d72:	83 ec 04             	sub    $0x4,%esp
f0102d75:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102d7b:	ff 73 48             	pushl  0x48(%ebx)
f0102d7e:	68 b0 68 10 f0       	push   $0xf01068b0
f0102d83:	e8 d0 08 00 00       	call   f0103658 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d88:	89 1c 24             	mov    %ebx,(%esp)
f0102d8b:	e8 1d 06 00 00       	call   f01033ad <env_destroy>
f0102d90:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d93:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d96:	c9                   	leave  
f0102d97:	c3                   	ret    

f0102d98 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d98:	55                   	push   %ebp
f0102d99:	89 e5                	mov    %esp,%ebp
f0102d9b:	57                   	push   %edi
f0102d9c:	56                   	push   %esi
f0102d9d:	53                   	push   %ebx
f0102d9e:	83 ec 0c             	sub    $0xc,%esp
f0102da1:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
f0102da3:	89 d3                	mov    %edx,%ebx
f0102da5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);
f0102dab:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102db2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102db8:	eb 3d                	jmp    f0102df7 <region_alloc+0x5f>
	{
		page = page_alloc(0);
f0102dba:	83 ec 0c             	sub    $0xc,%esp
f0102dbd:	6a 00                	push   $0x0
f0102dbf:	e8 d5 e1 ff ff       	call   f0100f99 <page_alloc>

		if(!page)
f0102dc4:	83 c4 10             	add    $0x10,%esp
f0102dc7:	85 c0                	test   %eax,%eax
f0102dc9:	75 17                	jne    f0102de2 <region_alloc+0x4a>
			panic("region_alloc: page allocation failed!");
f0102dcb:	83 ec 04             	sub    $0x4,%esp
f0102dce:	68 f8 6b 10 f0       	push   $0xf0106bf8
f0102dd3:	68 32 01 00 00       	push   $0x132
f0102dd8:	68 42 6c 10 f0       	push   $0xf0106c42
f0102ddd:	e8 5e d2 ff ff       	call   f0100040 <_panic>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
f0102de2:	6a 06                	push   $0x6
f0102de4:	53                   	push   %ebx
f0102de5:	50                   	push   %eax
f0102de6:	ff 77 60             	pushl  0x60(%edi)
f0102de9:	e8 aa e4 ff ff       	call   f0101298 <page_insert>
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102dee:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102df4:	83 c4 10             	add    $0x10,%esp
f0102df7:	39 f3                	cmp    %esi,%ebx
f0102df9:	72 bf                	jb     f0102dba <region_alloc+0x22>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
	}
	
	
}
f0102dfb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dfe:	5b                   	pop    %ebx
f0102dff:	5e                   	pop    %esi
f0102e00:	5f                   	pop    %edi
f0102e01:	5d                   	pop    %ebp
f0102e02:	c3                   	ret    

f0102e03 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e03:	55                   	push   %ebp
f0102e04:	89 e5                	mov    %esp,%ebp
f0102e06:	56                   	push   %esi
f0102e07:	53                   	push   %ebx
f0102e08:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e0b:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e0e:	85 c0                	test   %eax,%eax
f0102e10:	75 1a                	jne    f0102e2c <envid2env+0x29>
		*env_store = curenv;
f0102e12:	e8 ef 24 00 00       	call   f0105306 <cpunum>
f0102e17:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e1a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e20:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e23:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e25:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e2a:	eb 70                	jmp    f0102e9c <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e2c:	89 c3                	mov    %eax,%ebx
f0102e2e:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e34:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e37:	03 1d 44 a2 22 f0    	add    0xf022a244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e3d:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e41:	74 05                	je     f0102e48 <envid2env+0x45>
f0102e43:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e46:	74 10                	je     f0102e58 <envid2env+0x55>
		*env_store = 0;
f0102e48:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e4b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e51:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e56:	eb 44                	jmp    f0102e9c <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e58:	84 d2                	test   %dl,%dl
f0102e5a:	74 36                	je     f0102e92 <envid2env+0x8f>
f0102e5c:	e8 a5 24 00 00       	call   f0105306 <cpunum>
f0102e61:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e64:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e6a:	74 26                	je     f0102e92 <envid2env+0x8f>
f0102e6c:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e6f:	e8 92 24 00 00       	call   f0105306 <cpunum>
f0102e74:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e77:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e7d:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e80:	74 10                	je     f0102e92 <envid2env+0x8f>
		*env_store = 0;
f0102e82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e85:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e8b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e90:	eb 0a                	jmp    f0102e9c <envid2env+0x99>
	}

	*env_store = e;
f0102e92:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e95:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e97:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e9c:	5b                   	pop    %ebx
f0102e9d:	5e                   	pop    %esi
f0102e9e:	5d                   	pop    %ebp
f0102e9f:	c3                   	ret    

f0102ea0 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102ea0:	55                   	push   %ebp
f0102ea1:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102ea3:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102ea8:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102eab:	b8 23 00 00 00       	mov    $0x23,%eax
f0102eb0:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102eb2:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102eb4:	b8 10 00 00 00       	mov    $0x10,%eax
f0102eb9:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102ebb:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102ebd:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102ebf:	ea c6 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102ec6
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102ec6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ecb:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102ece:	5d                   	pop    %ebp
f0102ecf:	c3                   	ret    

f0102ed0 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102ed0:	55                   	push   %ebp
f0102ed1:	89 e5                	mov    %esp,%ebp
f0102ed3:	56                   	push   %esi
f0102ed4:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
	{
		envs[i].env_id = 0;
f0102ed5:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
f0102edb:	8b 15 48 a2 22 f0    	mov    0xf022a248,%edx
f0102ee1:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102ee7:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102eea:	89 c1                	mov    %eax,%ecx
f0102eec:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102ef3:	89 50 44             	mov    %edx,0x44(%eax)
f0102ef6:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];	
f0102ef9:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
f0102efb:	39 d8                	cmp    %ebx,%eax
f0102efd:	75 eb                	jne    f0102eea <env_init+0x1a>
f0102eff:	89 35 48 a2 22 f0    	mov    %esi,0xf022a248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];	
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102f05:	e8 96 ff ff ff       	call   f0102ea0 <env_init_percpu>
}
f0102f0a:	5b                   	pop    %ebx
f0102f0b:	5e                   	pop    %esi
f0102f0c:	5d                   	pop    %ebp
f0102f0d:	c3                   	ret    

f0102f0e <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f0e:	55                   	push   %ebp
f0102f0f:	89 e5                	mov    %esp,%ebp
f0102f11:	53                   	push   %ebx
f0102f12:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f15:	8b 1d 48 a2 22 f0    	mov    0xf022a248,%ebx
f0102f1b:	85 db                	test   %ebx,%ebx
f0102f1d:	0f 84 69 01 00 00    	je     f010308c <env_alloc+0x17e>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f23:	83 ec 0c             	sub    $0xc,%esp
f0102f26:	6a 01                	push   $0x1
f0102f28:	e8 6c e0 ff ff       	call   f0100f99 <page_alloc>
f0102f2d:	83 c4 10             	add    $0x10,%esp
f0102f30:	85 c0                	test   %eax,%eax
f0102f32:	0f 84 5b 01 00 00    	je     f0103093 <env_alloc+0x185>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102f38:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f3d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102f43:	c1 f8 03             	sar    $0x3,%eax
f0102f46:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f49:	89 c2                	mov    %eax,%edx
f0102f4b:	c1 ea 0c             	shr    $0xc,%edx
f0102f4e:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102f54:	72 12                	jb     f0102f68 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f56:	50                   	push   %eax
f0102f57:	68 c4 59 10 f0       	push   $0xf01059c4
f0102f5c:	6a 58                	push   $0x58
f0102f5e:	68 f1 68 10 f0       	push   $0xf01068f1
f0102f63:	e8 d8 d0 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = (pde_t*) page2kva(p);
f0102f68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f6d:	89 43 60             	mov    %eax,0x60(%ebx)
f0102f70:	b8 ec 0e 00 00       	mov    $0xeec,%eax
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102f75:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0102f7b:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102f7e:	8b 53 60             	mov    0x60(%ebx),%edx
f0102f81:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102f84:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*) page2kva(p);
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
f0102f87:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102f8c:	75 e7                	jne    f0102f75 <env_alloc+0x67>
		e->env_pgdir[i] = kern_pgdir[i];
	}

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f8e:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f91:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f96:	77 15                	ja     f0102fad <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f98:	50                   	push   %eax
f0102f99:	68 e8 59 10 f0       	push   $0xf01059e8
f0102f9e:	68 ca 00 00 00       	push   $0xca
f0102fa3:	68 42 6c 10 f0       	push   $0xf0106c42
f0102fa8:	e8 93 d0 ff ff       	call   f0100040 <_panic>
f0102fad:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102fb3:	83 ca 05             	or     $0x5,%edx
f0102fb6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fbc:	8b 43 48             	mov    0x48(%ebx),%eax
f0102fbf:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102fc4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fce:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102fd1:	89 da                	mov    %ebx,%edx
f0102fd3:	2b 15 44 a2 22 f0    	sub    0xf022a244,%edx
f0102fd9:	c1 fa 02             	sar    $0x2,%edx
f0102fdc:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102fe2:	09 d0                	or     %edx,%eax
f0102fe4:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fe7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fea:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fed:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102ff4:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102ffb:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103002:	83 ec 04             	sub    $0x4,%esp
f0103005:	6a 44                	push   $0x44
f0103007:	6a 00                	push   $0x0
f0103009:	53                   	push   %ebx
f010300a:	e8 d5 1c 00 00       	call   f0104ce4 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010300f:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103015:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010301b:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103021:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103028:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010302e:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103035:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103039:	8b 43 44             	mov    0x44(%ebx),%eax
f010303c:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	*newenv_store = e;
f0103041:	8b 45 08             	mov    0x8(%ebp),%eax
f0103044:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103046:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103049:	e8 b8 22 00 00       	call   f0105306 <cpunum>
f010304e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103051:	83 c4 10             	add    $0x10,%esp
f0103054:	ba 00 00 00 00       	mov    $0x0,%edx
f0103059:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103060:	74 11                	je     f0103073 <env_alloc+0x165>
f0103062:	e8 9f 22 00 00       	call   f0105306 <cpunum>
f0103067:	6b c0 74             	imul   $0x74,%eax,%eax
f010306a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103070:	8b 50 48             	mov    0x48(%eax),%edx
f0103073:	83 ec 04             	sub    $0x4,%esp
f0103076:	53                   	push   %ebx
f0103077:	52                   	push   %edx
f0103078:	68 4d 6c 10 f0       	push   $0xf0106c4d
f010307d:	e8 d6 05 00 00       	call   f0103658 <cprintf>
	return 0;
f0103082:	83 c4 10             	add    $0x10,%esp
f0103085:	b8 00 00 00 00       	mov    $0x0,%eax
f010308a:	eb 0c                	jmp    f0103098 <env_alloc+0x18a>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010308c:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103091:	eb 05                	jmp    f0103098 <env_alloc+0x18a>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103093:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103098:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010309b:	c9                   	leave  
f010309c:	c3                   	ret    

f010309d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010309d:	55                   	push   %ebp
f010309e:	89 e5                	mov    %esp,%ebp
f01030a0:	57                   	push   %edi
f01030a1:	56                   	push   %esi
f01030a2:	53                   	push   %ebx
f01030a3:	83 ec 34             	sub    $0x34,%esp
f01030a6:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e = NULL;
f01030a9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uint32_t result = env_alloc(&e, 0);
f01030b0:	6a 00                	push   $0x0
f01030b2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030b5:	50                   	push   %eax
f01030b6:	e8 53 fe ff ff       	call   f0102f0e <env_alloc>

	if(result !=  0)
f01030bb:	83 c4 10             	add    $0x10,%esp
f01030be:	85 c0                	test   %eax,%eax
f01030c0:	74 15                	je     f01030d7 <env_create+0x3a>
		panic("env_create: %e", result);
f01030c2:	50                   	push   %eax
f01030c3:	68 62 6c 10 f0       	push   $0xf0106c62
f01030c8:	68 a1 01 00 00       	push   $0x1a1
f01030cd:	68 42 6c 10 f0       	push   $0xf0106c42
f01030d2:	e8 69 cf ff ff       	call   f0100040 <_panic>

	load_icode(e, binary);
f01030d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030da:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph = NULL, *eph = NULL;
	struct Elf *elf = (struct Elf*) binary;
	
	if(elf->e_magic != ELF_MAGIC)
f01030dd:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030e3:	74 17                	je     f01030fc <env_create+0x5f>
		panic("load icode: Elf format not valid!");
f01030e5:	83 ec 04             	sub    $0x4,%esp
f01030e8:	68 20 6c 10 f0       	push   $0xf0106c20
f01030ed:	68 74 01 00 00       	push   $0x174
f01030f2:	68 42 6c 10 f0       	push   $0xf0106c42
f01030f7:	e8 44 cf ff ff       	call   f0100040 <_panic>

	ph = (struct Proghdr*) (binary + elf->e_phoff);
f01030fc:	89 fb                	mov    %edi,%ebx
f01030fe:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0103101:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103105:	c1 e6 05             	shl    $0x5,%esi
f0103108:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f010310a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010310d:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103110:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103115:	77 15                	ja     f010312c <env_create+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103117:	50                   	push   %eax
f0103118:	68 e8 59 10 f0       	push   $0xf01059e8
f010311d:	68 79 01 00 00       	push   $0x179
f0103122:	68 42 6c 10 f0       	push   $0xf0106c42
f0103127:	e8 14 cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010312c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103131:	0f 22 d8             	mov    %eax,%cr3
f0103134:	eb 44                	jmp    f010317a <env_create+0xdd>

	for( ; ph < eph; ++ph)
	{
		if(ph->p_type != ELF_PROG_LOAD)
f0103136:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103139:	75 3c                	jne    f0103177 <env_create+0xda>
			continue;		

		region_alloc(e, (void*) ph->p_va, ph->p_memsz);
f010313b:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010313e:	8b 53 08             	mov    0x8(%ebx),%edx
f0103141:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103144:	e8 4f fc ff ff       	call   f0102d98 <region_alloc>
		
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103149:	83 ec 04             	sub    $0x4,%esp
f010314c:	ff 73 10             	pushl  0x10(%ebx)
f010314f:	89 f8                	mov    %edi,%eax
f0103151:	03 43 04             	add    0x4(%ebx),%eax
f0103154:	50                   	push   %eax
f0103155:	ff 73 08             	pushl  0x8(%ebx)
f0103158:	e8 3c 1c 00 00       	call   f0104d99 <memcpy>
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
f010315d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103160:	83 c4 0c             	add    $0xc,%esp
f0103163:	8b 53 14             	mov    0x14(%ebx),%edx
f0103166:	29 c2                	sub    %eax,%edx
f0103168:	52                   	push   %edx
f0103169:	6a 00                	push   $0x0
f010316b:	03 43 08             	add    0x8(%ebx),%eax
f010316e:	50                   	push   %eax
f010316f:	e8 70 1b 00 00       	call   f0104ce4 <memset>
f0103174:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr*) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	for( ; ph < eph; ++ph)
f0103177:	83 c3 20             	add    $0x20,%ebx
f010317a:	39 de                	cmp    %ebx,%esi
f010317c:	77 b8                	ja     f0103136 <env_create+0x99>
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
	}

	e->env_tf.tf_eip = elf->e_entry;
f010317e:	8b 47 18             	mov    0x18(%edi),%eax
f0103181:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103184:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*) USTACKTOP - PGSIZE, PGSIZE);
f0103187:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010318c:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103191:	89 f8                	mov    %edi,%eax
f0103193:	e8 00 fc ff ff       	call   f0102d98 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f0103198:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010319d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031a2:	77 15                	ja     f01031b9 <env_create+0x11c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031a4:	50                   	push   %eax
f01031a5:	68 e8 59 10 f0       	push   $0xf01059e8
f01031aa:	68 8f 01 00 00       	push   $0x18f
f01031af:	68 42 6c 10 f0       	push   $0xf0106c42
f01031b4:	e8 87 ce ff ff       	call   f0100040 <_panic>
f01031b9:	05 00 00 00 10       	add    $0x10000000,%eax
f01031be:	0f 22 d8             	mov    %eax,%cr3

	if(result !=  0)
		panic("env_create: %e", result);

	load_icode(e, binary);
	e->env_type = type;
f01031c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031c4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031c7:	89 50 50             	mov    %edx,0x50(%eax)
}
f01031ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031cd:	5b                   	pop    %ebx
f01031ce:	5e                   	pop    %esi
f01031cf:	5f                   	pop    %edi
f01031d0:	5d                   	pop    %ebp
f01031d1:	c3                   	ret    

f01031d2 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031d2:	55                   	push   %ebp
f01031d3:	89 e5                	mov    %esp,%ebp
f01031d5:	57                   	push   %edi
f01031d6:	56                   	push   %esi
f01031d7:	53                   	push   %ebx
f01031d8:	83 ec 1c             	sub    $0x1c,%esp
f01031db:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031de:	e8 23 21 00 00       	call   f0105306 <cpunum>
f01031e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01031e6:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f01031ec:	75 29                	jne    f0103217 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031ee:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031f3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031f8:	77 15                	ja     f010320f <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031fa:	50                   	push   %eax
f01031fb:	68 e8 59 10 f0       	push   $0xf01059e8
f0103200:	68 b5 01 00 00       	push   $0x1b5
f0103205:	68 42 6c 10 f0       	push   $0xf0106c42
f010320a:	e8 31 ce ff ff       	call   f0100040 <_panic>
f010320f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103214:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103217:	8b 5f 48             	mov    0x48(%edi),%ebx
f010321a:	e8 e7 20 00 00       	call   f0105306 <cpunum>
f010321f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103222:	ba 00 00 00 00       	mov    $0x0,%edx
f0103227:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010322e:	74 11                	je     f0103241 <env_free+0x6f>
f0103230:	e8 d1 20 00 00       	call   f0105306 <cpunum>
f0103235:	6b c0 74             	imul   $0x74,%eax,%eax
f0103238:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010323e:	8b 50 48             	mov    0x48(%eax),%edx
f0103241:	83 ec 04             	sub    $0x4,%esp
f0103244:	53                   	push   %ebx
f0103245:	52                   	push   %edx
f0103246:	68 71 6c 10 f0       	push   $0xf0106c71
f010324b:	e8 08 04 00 00       	call   f0103658 <cprintf>
f0103250:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103253:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010325a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010325d:	89 d0                	mov    %edx,%eax
f010325f:	c1 e0 02             	shl    $0x2,%eax
f0103262:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103265:	8b 47 60             	mov    0x60(%edi),%eax
f0103268:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010326b:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103271:	0f 84 a8 00 00 00    	je     f010331f <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103277:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010327d:	89 f0                	mov    %esi,%eax
f010327f:	c1 e8 0c             	shr    $0xc,%eax
f0103282:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103285:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f010328b:	77 15                	ja     f01032a2 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010328d:	56                   	push   %esi
f010328e:	68 c4 59 10 f0       	push   $0xf01059c4
f0103293:	68 c4 01 00 00       	push   $0x1c4
f0103298:	68 42 6c 10 f0       	push   $0xf0106c42
f010329d:	e8 9e cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032a5:	c1 e0 16             	shl    $0x16,%eax
f01032a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032ab:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01032b0:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01032b7:	01 
f01032b8:	74 17                	je     f01032d1 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032ba:	83 ec 08             	sub    $0x8,%esp
f01032bd:	89 d8                	mov    %ebx,%eax
f01032bf:	c1 e0 0c             	shl    $0xc,%eax
f01032c2:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032c5:	50                   	push   %eax
f01032c6:	ff 77 60             	pushl  0x60(%edi)
f01032c9:	e8 75 df ff ff       	call   f0101243 <page_remove>
f01032ce:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032d1:	83 c3 01             	add    $0x1,%ebx
f01032d4:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032da:	75 d4                	jne    f01032b0 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032dc:	8b 47 60             	mov    0x60(%edi),%eax
f01032df:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032e2:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032e9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032ec:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01032f2:	72 14                	jb     f0103308 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032f4:	83 ec 04             	sub    $0x4,%esp
f01032f7:	68 b4 60 10 f0       	push   $0xf01060b4
f01032fc:	6a 51                	push   $0x51
f01032fe:	68 f1 68 10 f0       	push   $0xf01068f1
f0103303:	e8 38 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103308:	83 ec 0c             	sub    $0xc,%esp
f010330b:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0103310:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103313:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103316:	50                   	push   %eax
f0103317:	e8 28 dd ff ff       	call   f0101044 <page_decref>
f010331c:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010331f:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103323:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103326:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010332b:	0f 85 29 ff ff ff    	jne    f010325a <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103331:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103334:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103339:	77 15                	ja     f0103350 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010333b:	50                   	push   %eax
f010333c:	68 e8 59 10 f0       	push   $0xf01059e8
f0103341:	68 d2 01 00 00       	push   $0x1d2
f0103346:	68 42 6c 10 f0       	push   $0xf0106c42
f010334b:	e8 f0 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103350:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103357:	05 00 00 00 10       	add    $0x10000000,%eax
f010335c:	c1 e8 0c             	shr    $0xc,%eax
f010335f:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103365:	72 14                	jb     f010337b <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103367:	83 ec 04             	sub    $0x4,%esp
f010336a:	68 b4 60 10 f0       	push   $0xf01060b4
f010336f:	6a 51                	push   $0x51
f0103371:	68 f1 68 10 f0       	push   $0xf01068f1
f0103376:	e8 c5 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010337b:	83 ec 0c             	sub    $0xc,%esp
f010337e:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f0103384:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103387:	50                   	push   %eax
f0103388:	e8 b7 dc ff ff       	call   f0101044 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010338d:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103394:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f0103399:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010339c:	89 3d 48 a2 22 f0    	mov    %edi,0xf022a248
}
f01033a2:	83 c4 10             	add    $0x10,%esp
f01033a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033a8:	5b                   	pop    %ebx
f01033a9:	5e                   	pop    %esi
f01033aa:	5f                   	pop    %edi
f01033ab:	5d                   	pop    %ebp
f01033ac:	c3                   	ret    

f01033ad <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01033ad:	55                   	push   %ebp
f01033ae:	89 e5                	mov    %esp,%ebp
f01033b0:	53                   	push   %ebx
f01033b1:	83 ec 04             	sub    $0x4,%esp
f01033b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01033b7:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01033bb:	75 19                	jne    f01033d6 <env_destroy+0x29>
f01033bd:	e8 44 1f 00 00       	call   f0105306 <cpunum>
f01033c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c5:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033cb:	74 09                	je     f01033d6 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033cd:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033d4:	eb 33                	jmp    f0103409 <env_destroy+0x5c>
	}

	env_free(e);
f01033d6:	83 ec 0c             	sub    $0xc,%esp
f01033d9:	53                   	push   %ebx
f01033da:	e8 f3 fd ff ff       	call   f01031d2 <env_free>

	if (curenv == e) {
f01033df:	e8 22 1f 00 00       	call   f0105306 <cpunum>
f01033e4:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e7:	83 c4 10             	add    $0x10,%esp
f01033ea:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033f0:	75 17                	jne    f0103409 <env_destroy+0x5c>
		curenv = NULL;
f01033f2:	e8 0f 1f 00 00       	call   f0105306 <cpunum>
f01033f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01033fa:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103401:	00 00 00 
		sched_yield();
f0103404:	e8 56 0c 00 00       	call   f010405f <sched_yield>
	}
}
f0103409:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010340c:	c9                   	leave  
f010340d:	c3                   	ret    

f010340e <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010340e:	55                   	push   %ebp
f010340f:	89 e5                	mov    %esp,%ebp
f0103411:	53                   	push   %ebx
f0103412:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103415:	e8 ec 1e 00 00       	call   f0105306 <cpunum>
f010341a:	6b c0 74             	imul   $0x74,%eax,%eax
f010341d:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f0103423:	e8 de 1e 00 00       	call   f0105306 <cpunum>
f0103428:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f010342b:	8b 65 08             	mov    0x8(%ebp),%esp
f010342e:	61                   	popa   
f010342f:	07                   	pop    %es
f0103430:	1f                   	pop    %ds
f0103431:	83 c4 08             	add    $0x8,%esp
f0103434:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103435:	83 ec 04             	sub    $0x4,%esp
f0103438:	68 87 6c 10 f0       	push   $0xf0106c87
f010343d:	68 09 02 00 00       	push   $0x209
f0103442:	68 42 6c 10 f0       	push   $0xf0106c42
f0103447:	e8 f4 cb ff ff       	call   f0100040 <_panic>

f010344c <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010344c:	55                   	push   %ebp
f010344d:	89 e5                	mov    %esp,%ebp
f010344f:	53                   	push   %ebx
f0103450:	83 ec 04             	sub    $0x4,%esp
f0103453:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && (curenv->env_status == ENV_RUNNING))
f0103456:	e8 ab 1e 00 00       	call   f0105306 <cpunum>
f010345b:	6b c0 74             	imul   $0x74,%eax,%eax
f010345e:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103465:	74 29                	je     f0103490 <env_run+0x44>
f0103467:	e8 9a 1e 00 00       	call   f0105306 <cpunum>
f010346c:	6b c0 74             	imul   $0x74,%eax,%eax
f010346f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103475:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103479:	75 15                	jne    f0103490 <env_run+0x44>
	{
		curenv->env_status = ENV_RUNNABLE;
f010347b:	e8 86 1e 00 00       	call   f0105306 <cpunum>
f0103480:	6b c0 74             	imul   $0x74,%eax,%eax
f0103483:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103489:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}

	curenv = e;
f0103490:	e8 71 1e 00 00       	call   f0105306 <cpunum>
f0103495:	6b c0 74             	imul   $0x74,%eax,%eax
f0103498:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	e->env_status = ENV_RUNNING;
f010349e:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	e->env_runs++;
f01034a5:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(e->env_pgdir));
f01034a9:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034ac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034b1:	77 15                	ja     f01034c8 <env_run+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034b3:	50                   	push   %eax
f01034b4:	68 e8 59 10 f0       	push   $0xf01059e8
f01034b9:	68 2f 02 00 00       	push   $0x22f
f01034be:	68 42 6c 10 f0       	push   $0xf0106c42
f01034c3:	e8 78 cb ff ff       	call   f0100040 <_panic>
f01034c8:	05 00 00 00 10       	add    $0x10000000,%eax
f01034cd:	0f 22 d8             	mov    %eax,%cr3
	env_pop_tf(&e->env_tf);
f01034d0:	83 ec 0c             	sub    $0xc,%esp
f01034d3:	53                   	push   %ebx
f01034d4:	e8 35 ff ff ff       	call   f010340e <env_pop_tf>

f01034d9 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034d9:	55                   	push   %ebp
f01034da:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034dc:	ba 70 00 00 00       	mov    $0x70,%edx
f01034e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01034e4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034e5:	ba 71 00 00 00       	mov    $0x71,%edx
f01034ea:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034eb:	0f b6 c0             	movzbl %al,%eax
}
f01034ee:	5d                   	pop    %ebp
f01034ef:	c3                   	ret    

f01034f0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01034f0:	55                   	push   %ebp
f01034f1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034f3:	ba 70 00 00 00       	mov    $0x70,%edx
f01034f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01034fb:	ee                   	out    %al,(%dx)
f01034fc:	ba 71 00 00 00       	mov    $0x71,%edx
f0103501:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103504:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103505:	5d                   	pop    %ebp
f0103506:	c3                   	ret    

f0103507 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103507:	55                   	push   %ebp
f0103508:	89 e5                	mov    %esp,%ebp
f010350a:	56                   	push   %esi
f010350b:	53                   	push   %ebx
f010350c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010350f:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103515:	80 3d 4c a2 22 f0 00 	cmpb   $0x0,0xf022a24c
f010351c:	74 5a                	je     f0103578 <irq_setmask_8259A+0x71>
f010351e:	89 c6                	mov    %eax,%esi
f0103520:	ba 21 00 00 00       	mov    $0x21,%edx
f0103525:	ee                   	out    %al,(%dx)
f0103526:	66 c1 e8 08          	shr    $0x8,%ax
f010352a:	ba a1 00 00 00       	mov    $0xa1,%edx
f010352f:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103530:	83 ec 0c             	sub    $0xc,%esp
f0103533:	68 93 6c 10 f0       	push   $0xf0106c93
f0103538:	e8 1b 01 00 00       	call   f0103658 <cprintf>
f010353d:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103540:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103545:	0f b7 f6             	movzwl %si,%esi
f0103548:	f7 d6                	not    %esi
f010354a:	0f a3 de             	bt     %ebx,%esi
f010354d:	73 11                	jae    f0103560 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010354f:	83 ec 08             	sub    $0x8,%esp
f0103552:	53                   	push   %ebx
f0103553:	68 25 71 10 f0       	push   $0xf0107125
f0103558:	e8 fb 00 00 00       	call   f0103658 <cprintf>
f010355d:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103560:	83 c3 01             	add    $0x1,%ebx
f0103563:	83 fb 10             	cmp    $0x10,%ebx
f0103566:	75 e2                	jne    f010354a <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103568:	83 ec 0c             	sub    $0xc,%esp
f010356b:	68 5c 5d 10 f0       	push   $0xf0105d5c
f0103570:	e8 e3 00 00 00       	call   f0103658 <cprintf>
f0103575:	83 c4 10             	add    $0x10,%esp
}
f0103578:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010357b:	5b                   	pop    %ebx
f010357c:	5e                   	pop    %esi
f010357d:	5d                   	pop    %ebp
f010357e:	c3                   	ret    

f010357f <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010357f:	c6 05 4c a2 22 f0 01 	movb   $0x1,0xf022a24c
f0103586:	ba 21 00 00 00       	mov    $0x21,%edx
f010358b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103590:	ee                   	out    %al,(%dx)
f0103591:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103596:	ee                   	out    %al,(%dx)
f0103597:	ba 20 00 00 00       	mov    $0x20,%edx
f010359c:	b8 11 00 00 00       	mov    $0x11,%eax
f01035a1:	ee                   	out    %al,(%dx)
f01035a2:	ba 21 00 00 00       	mov    $0x21,%edx
f01035a7:	b8 20 00 00 00       	mov    $0x20,%eax
f01035ac:	ee                   	out    %al,(%dx)
f01035ad:	b8 04 00 00 00       	mov    $0x4,%eax
f01035b2:	ee                   	out    %al,(%dx)
f01035b3:	b8 03 00 00 00       	mov    $0x3,%eax
f01035b8:	ee                   	out    %al,(%dx)
f01035b9:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035be:	b8 11 00 00 00       	mov    $0x11,%eax
f01035c3:	ee                   	out    %al,(%dx)
f01035c4:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035c9:	b8 28 00 00 00       	mov    $0x28,%eax
f01035ce:	ee                   	out    %al,(%dx)
f01035cf:	b8 02 00 00 00       	mov    $0x2,%eax
f01035d4:	ee                   	out    %al,(%dx)
f01035d5:	b8 01 00 00 00       	mov    $0x1,%eax
f01035da:	ee                   	out    %al,(%dx)
f01035db:	ba 20 00 00 00       	mov    $0x20,%edx
f01035e0:	b8 68 00 00 00       	mov    $0x68,%eax
f01035e5:	ee                   	out    %al,(%dx)
f01035e6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035eb:	ee                   	out    %al,(%dx)
f01035ec:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035f1:	b8 68 00 00 00       	mov    $0x68,%eax
f01035f6:	ee                   	out    %al,(%dx)
f01035f7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035fc:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01035fd:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103604:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103608:	74 13                	je     f010361d <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010360a:	55                   	push   %ebp
f010360b:	89 e5                	mov    %esp,%ebp
f010360d:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103610:	0f b7 c0             	movzwl %ax,%eax
f0103613:	50                   	push   %eax
f0103614:	e8 ee fe ff ff       	call   f0103507 <irq_setmask_8259A>
f0103619:	83 c4 10             	add    $0x10,%esp
}
f010361c:	c9                   	leave  
f010361d:	f3 c3                	repz ret 

f010361f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010361f:	55                   	push   %ebp
f0103620:	89 e5                	mov    %esp,%ebp
f0103622:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103625:	ff 75 08             	pushl  0x8(%ebp)
f0103628:	e8 1f d1 ff ff       	call   f010074c <cputchar>
	*cnt++;
}
f010362d:	83 c4 10             	add    $0x10,%esp
f0103630:	c9                   	leave  
f0103631:	c3                   	ret    

f0103632 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103632:	55                   	push   %ebp
f0103633:	89 e5                	mov    %esp,%ebp
f0103635:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103638:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010363f:	ff 75 0c             	pushl  0xc(%ebp)
f0103642:	ff 75 08             	pushl  0x8(%ebp)
f0103645:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103648:	50                   	push   %eax
f0103649:	68 1f 36 10 f0       	push   $0xf010361f
f010364e:	e8 25 10 00 00       	call   f0104678 <vprintfmt>
	return cnt;
}
f0103653:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103656:	c9                   	leave  
f0103657:	c3                   	ret    

f0103658 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103658:	55                   	push   %ebp
f0103659:	89 e5                	mov    %esp,%ebp
f010365b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010365e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103661:	50                   	push   %eax
f0103662:	ff 75 08             	pushl  0x8(%ebp)
f0103665:	e8 c8 ff ff ff       	call   f0103632 <vcprintf>
	va_end(ap);

	return cnt;
}
f010366a:	c9                   	leave  
f010366b:	c3                   	ret    

f010366c <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010366c:	55                   	push   %ebp
f010366d:	89 e5                	mov    %esp,%ebp
f010366f:	57                   	push   %edi
f0103670:	56                   	push   %esi
f0103671:	53                   	push   %ebx
f0103672:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that -we get the right stack
	// when we trap to the kernel.
	size_t id = thiscpu->cpu_id;
f0103675:	e8 8c 1c 00 00       	call   f0105306 <cpunum>
f010367a:	6b c0 74             	imul   $0x74,%eax,%eax
f010367d:	0f b6 b0 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%esi
f0103684:	89 f0                	mov    %esi,%eax
f0103686:	0f b6 d8             	movzbl %al,%ebx

	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0103689:	e8 78 1c 00 00       	call   f0105306 <cpunum>
f010368e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103691:	66 c7 80 92 b0 22 f0 	movw   $0x68,-0xfdd4f6e(%eax)
f0103698:	68 00 
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010369a:	e8 67 1c 00 00       	call   f0105306 <cpunum>
f010369f:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a2:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f01036a9:	10 00 
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - id * (KSTKSIZE + KSTKGAP);
f01036ab:	e8 56 1c 00 00       	call   f0105306 <cpunum>
f01036b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036b3:	89 da                	mov    %ebx,%edx
f01036b5:	f7 da                	neg    %edx
f01036b7:	c1 e2 10             	shl    $0x10,%edx
f01036ba:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01036c0:	89 90 30 b0 22 f0    	mov    %edx,-0xfdd4fd0(%eax)

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01036c6:	83 c3 05             	add    $0x5,%ebx
f01036c9:	e8 38 1c 00 00       	call   f0105306 <cpunum>
f01036ce:	89 c7                	mov    %eax,%edi
f01036d0:	e8 31 1c 00 00       	call   f0105306 <cpunum>
f01036d5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036d8:	e8 29 1c 00 00       	call   f0105306 <cpunum>
f01036dd:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f01036e4:	f0 67 00 
f01036e7:	6b ff 74             	imul   $0x74,%edi,%edi
f01036ea:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f01036f0:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f01036f7:	f0 
f01036f8:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f01036fc:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f0103702:	c1 ea 10             	shr    $0x10,%edx
f0103705:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f010370c:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103713:	40 
f0103714:	6b c0 74             	imul   $0x74,%eax,%eax
f0103717:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f010371c:	c1 e8 18             	shr    $0x18,%eax
f010371f:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + id].sd_s = 0;
f0103726:	c6 04 dd 45 f3 11 f0 	movb   $0x89,-0xfee0cbb(,%ebx,8)
f010372d:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010372e:	89 f0                	mov    %esi,%eax
f0103730:	0f b6 f0             	movzbl %al,%esi
f0103733:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f010373a:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010373d:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103742:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (id << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103745:	83 c4 1c             	add    $0x1c,%esp
f0103748:	5b                   	pop    %ebx
f0103749:	5e                   	pop    %esi
f010374a:	5f                   	pop    %edi
f010374b:	5d                   	pop    %ebp
f010374c:	c3                   	ret    

f010374d <trap_init>:
}


void
trap_init(void)
{
f010374d:	55                   	push   %ebp
f010374e:	89 e5                	mov    %esp,%ebp
f0103750:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0103753:	b8 16 3f 10 f0       	mov    $0xf0103f16,%eax
f0103758:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f010375e:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f0103765:	08 00 
f0103767:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f010376e:	c6 05 65 a2 22 f0 8e 	movb   $0x8e,0xf022a265
f0103775:	c1 e8 10             	shr    $0x10,%eax
f0103778:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f010377e:	b8 1c 3f 10 f0       	mov    $0xf0103f1c,%eax
f0103783:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f0103789:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f0103790:	08 00 
f0103792:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f0103799:	c6 05 6d a2 22 f0 8e 	movb   $0x8e,0xf022a26d
f01037a0:	c1 e8 10             	shr    $0x10,%eax
f01037a3:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f01037a9:	b8 22 3f 10 f0       	mov    $0xf0103f22,%eax
f01037ae:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f01037b4:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f01037bb:	08 00 
f01037bd:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f01037c4:	c6 05 75 a2 22 f0 8e 	movb   $0x8e,0xf022a275
f01037cb:	c1 e8 10             	shr    $0x10,%eax
f01037ce:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f01037d4:	b8 28 3f 10 f0       	mov    $0xf0103f28,%eax
f01037d9:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f01037df:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f01037e6:	08 00 
f01037e8:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f01037ef:	c6 05 7d a2 22 f0 ee 	movb   $0xee,0xf022a27d
f01037f6:	c1 e8 10             	shr    $0x10,%eax
f01037f9:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f01037ff:	b8 2e 3f 10 f0       	mov    $0xf0103f2e,%eax
f0103804:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f010380a:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103811:	08 00 
f0103813:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f010381a:	c6 05 85 a2 22 f0 8e 	movb   $0x8e,0xf022a285
f0103821:	c1 e8 10             	shr    $0x10,%eax
f0103824:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f010382a:	b8 34 3f 10 f0       	mov    $0xf0103f34,%eax
f010382f:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f0103835:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f010383c:	08 00 
f010383e:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f0103845:	c6 05 8d a2 22 f0 8e 	movb   $0x8e,0xf022a28d
f010384c:	c1 e8 10             	shr    $0x10,%eax
f010384f:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f0103855:	b8 3a 3f 10 f0       	mov    $0xf0103f3a,%eax
f010385a:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f0103860:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f0103867:	08 00 
f0103869:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f0103870:	c6 05 95 a2 22 f0 8e 	movb   $0x8e,0xf022a295
f0103877:	c1 e8 10             	shr    $0x10,%eax
f010387a:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f0103880:	b8 40 3f 10 f0       	mov    $0xf0103f40,%eax
f0103885:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f010388b:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f0103892:	08 00 
f0103894:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f010389b:	c6 05 9d a2 22 f0 8e 	movb   $0x8e,0xf022a29d
f01038a2:	c1 e8 10             	shr    $0x10,%eax
f01038a5:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01038ab:	b8 46 3f 10 f0       	mov    $0xf0103f46,%eax
f01038b0:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f01038b6:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f01038bd:	08 00 
f01038bf:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f01038c6:	c6 05 a5 a2 22 f0 8e 	movb   $0x8e,0xf022a2a5
f01038cd:	c1 e8 10             	shr    $0x10,%eax
f01038d0:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f01038d6:	b8 4a 3f 10 f0       	mov    $0xf0103f4a,%eax
f01038db:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f01038e1:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f01038e8:	08 00 
f01038ea:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f01038f1:	c6 05 b5 a2 22 f0 8e 	movb   $0x8e,0xf022a2b5
f01038f8:	c1 e8 10             	shr    $0x10,%eax
f01038fb:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f0103901:	b8 4e 3f 10 f0       	mov    $0xf0103f4e,%eax
f0103906:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f010390c:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103913:	08 00 
f0103915:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f010391c:	c6 05 bd a2 22 f0 8e 	movb   $0x8e,0xf022a2bd
f0103923:	c1 e8 10             	shr    $0x10,%eax
f0103926:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f010392c:	b8 52 3f 10 f0       	mov    $0xf0103f52,%eax
f0103931:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f0103937:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f010393e:	08 00 
f0103940:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f0103947:	c6 05 c5 a2 22 f0 8e 	movb   $0x8e,0xf022a2c5
f010394e:	c1 e8 10             	shr    $0x10,%eax
f0103951:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f0103957:	b8 56 3f 10 f0       	mov    $0xf0103f56,%eax
f010395c:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f0103962:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f0103969:	08 00 
f010396b:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f0103972:	c6 05 cd a2 22 f0 8e 	movb   $0x8e,0xf022a2cd
f0103979:	c1 e8 10             	shr    $0x10,%eax
f010397c:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f0103982:	b8 5a 3f 10 f0       	mov    $0xf0103f5a,%eax
f0103987:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f010398d:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f0103994:	08 00 
f0103996:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f010399d:	c6 05 d5 a2 22 f0 8e 	movb   $0x8e,0xf022a2d5
f01039a4:	c1 e8 10             	shr    $0x10,%eax
f01039a7:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01039ad:	b8 5e 3f 10 f0       	mov    $0xf0103f5e,%eax
f01039b2:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f01039b8:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f01039bf:	08 00 
f01039c1:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f01039c8:	c6 05 e5 a2 22 f0 8e 	movb   $0x8e,0xf022a2e5
f01039cf:	c1 e8 10             	shr    $0x10,%eax
f01039d2:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f01039d8:	b8 64 3f 10 f0       	mov    $0xf0103f64,%eax
f01039dd:	66 a3 e8 a2 22 f0    	mov    %ax,0xf022a2e8
f01039e3:	66 c7 05 ea a2 22 f0 	movw   $0x8,0xf022a2ea
f01039ea:	08 00 
f01039ec:	c6 05 ec a2 22 f0 00 	movb   $0x0,0xf022a2ec
f01039f3:	c6 05 ed a2 22 f0 8e 	movb   $0x8e,0xf022a2ed
f01039fa:	c1 e8 10             	shr    $0x10,%eax
f01039fd:	66 a3 ee a2 22 f0    	mov    %ax,0xf022a2ee
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103a03:	b8 68 3f 10 f0       	mov    $0xf0103f68,%eax
f0103a08:	66 a3 f0 a2 22 f0    	mov    %ax,0xf022a2f0
f0103a0e:	66 c7 05 f2 a2 22 f0 	movw   $0x8,0xf022a2f2
f0103a15:	08 00 
f0103a17:	c6 05 f4 a2 22 f0 00 	movb   $0x0,0xf022a2f4
f0103a1e:	c6 05 f5 a2 22 f0 8e 	movb   $0x8e,0xf022a2f5
f0103a25:	c1 e8 10             	shr    $0x10,%eax
f0103a28:	66 a3 f6 a2 22 f0    	mov    %ax,0xf022a2f6
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103a2e:	b8 6e 3f 10 f0       	mov    $0xf0103f6e,%eax
f0103a33:	66 a3 f8 a2 22 f0    	mov    %ax,0xf022a2f8
f0103a39:	66 c7 05 fa a2 22 f0 	movw   $0x8,0xf022a2fa
f0103a40:	08 00 
f0103a42:	c6 05 fc a2 22 f0 00 	movb   $0x0,0xf022a2fc
f0103a49:	c6 05 fd a2 22 f0 8e 	movb   $0x8e,0xf022a2fd
f0103a50:	c1 e8 10             	shr    $0x10,%eax
f0103a53:	66 a3 fe a2 22 f0    	mov    %ax,0xf022a2fe
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f0103a59:	b8 74 3f 10 f0       	mov    $0xf0103f74,%eax
f0103a5e:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a64:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a6b:	08 00 
f0103a6d:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a74:	c6 05 e5 a3 22 f0 ef 	movb   $0xef,0xf022a3e5
f0103a7b:	c1 e8 10             	shr    $0x10,%eax
f0103a7e:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103a84:	e8 e3 fb ff ff       	call   f010366c <trap_init_percpu>
}
f0103a89:	c9                   	leave  
f0103a8a:	c3                   	ret    

f0103a8b <print_regs>:
	}
}

void	
print_regs(struct PushRegs *regs)
{
f0103a8b:	55                   	push   %ebp
f0103a8c:	89 e5                	mov    %esp,%ebp
f0103a8e:	53                   	push   %ebx
f0103a8f:	83 ec 0c             	sub    $0xc,%esp
f0103a92:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a95:	ff 33                	pushl  (%ebx)
f0103a97:	68 a7 6c 10 f0       	push   $0xf0106ca7
f0103a9c:	e8 b7 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103aa1:	83 c4 08             	add    $0x8,%esp
f0103aa4:	ff 73 04             	pushl  0x4(%ebx)
f0103aa7:	68 b6 6c 10 f0       	push   $0xf0106cb6
f0103aac:	e8 a7 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ab1:	83 c4 08             	add    $0x8,%esp
f0103ab4:	ff 73 08             	pushl  0x8(%ebx)
f0103ab7:	68 c5 6c 10 f0       	push   $0xf0106cc5
f0103abc:	e8 97 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103ac1:	83 c4 08             	add    $0x8,%esp
f0103ac4:	ff 73 0c             	pushl  0xc(%ebx)
f0103ac7:	68 d4 6c 10 f0       	push   $0xf0106cd4
f0103acc:	e8 87 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103ad1:	83 c4 08             	add    $0x8,%esp
f0103ad4:	ff 73 10             	pushl  0x10(%ebx)
f0103ad7:	68 e3 6c 10 f0       	push   $0xf0106ce3
f0103adc:	e8 77 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103ae1:	83 c4 08             	add    $0x8,%esp
f0103ae4:	ff 73 14             	pushl  0x14(%ebx)
f0103ae7:	68 f2 6c 10 f0       	push   $0xf0106cf2
f0103aec:	e8 67 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103af1:	83 c4 08             	add    $0x8,%esp
f0103af4:	ff 73 18             	pushl  0x18(%ebx)
f0103af7:	68 01 6d 10 f0       	push   $0xf0106d01
f0103afc:	e8 57 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b01:	83 c4 08             	add    $0x8,%esp
f0103b04:	ff 73 1c             	pushl  0x1c(%ebx)
f0103b07:	68 10 6d 10 f0       	push   $0xf0106d10
f0103b0c:	e8 47 fb ff ff       	call   f0103658 <cprintf>
}
f0103b11:	83 c4 10             	add    $0x10,%esp
f0103b14:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b17:	c9                   	leave  
f0103b18:	c3                   	ret    

f0103b19 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b19:	55                   	push   %ebp
f0103b1a:	89 e5                	mov    %esp,%ebp
f0103b1c:	56                   	push   %esi
f0103b1d:	53                   	push   %ebx
f0103b1e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103b21:	e8 e0 17 00 00       	call   f0105306 <cpunum>
f0103b26:	83 ec 04             	sub    $0x4,%esp
f0103b29:	50                   	push   %eax
f0103b2a:	53                   	push   %ebx
f0103b2b:	68 74 6d 10 f0       	push   $0xf0106d74
f0103b30:	e8 23 fb ff ff       	call   f0103658 <cprintf>
	print_regs(&tf->tf_regs);
f0103b35:	89 1c 24             	mov    %ebx,(%esp)
f0103b38:	e8 4e ff ff ff       	call   f0103a8b <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b3d:	83 c4 08             	add    $0x8,%esp
f0103b40:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b44:	50                   	push   %eax
f0103b45:	68 92 6d 10 f0       	push   $0xf0106d92
f0103b4a:	e8 09 fb ff ff       	call   f0103658 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b4f:	83 c4 08             	add    $0x8,%esp
f0103b52:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b56:	50                   	push   %eax
f0103b57:	68 a5 6d 10 f0       	push   $0xf0106da5
f0103b5c:	e8 f7 fa ff ff       	call   f0103658 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b61:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103b64:	83 c4 10             	add    $0x10,%esp
f0103b67:	83 f8 13             	cmp    $0x13,%eax
f0103b6a:	77 09                	ja     f0103b75 <print_trapframe+0x5c>
		return excnames[trapno];
f0103b6c:	8b 14 85 40 70 10 f0 	mov    -0xfef8fc0(,%eax,4),%edx
f0103b73:	eb 1f                	jmp    f0103b94 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b75:	83 f8 30             	cmp    $0x30,%eax
f0103b78:	74 15                	je     f0103b8f <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b7a:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b7d:	83 fa 10             	cmp    $0x10,%edx
f0103b80:	b9 3e 6d 10 f0       	mov    $0xf0106d3e,%ecx
f0103b85:	ba 2b 6d 10 f0       	mov    $0xf0106d2b,%edx
f0103b8a:	0f 43 d1             	cmovae %ecx,%edx
f0103b8d:	eb 05                	jmp    f0103b94 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103b8f:	ba 1f 6d 10 f0       	mov    $0xf0106d1f,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b94:	83 ec 04             	sub    $0x4,%esp
f0103b97:	52                   	push   %edx
f0103b98:	50                   	push   %eax
f0103b99:	68 b8 6d 10 f0       	push   $0xf0106db8
f0103b9e:	e8 b5 fa ff ff       	call   f0103658 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ba3:	83 c4 10             	add    $0x10,%esp
f0103ba6:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103bac:	75 1a                	jne    f0103bc8 <print_trapframe+0xaf>
f0103bae:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bb2:	75 14                	jne    f0103bc8 <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103bb4:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103bb7:	83 ec 08             	sub    $0x8,%esp
f0103bba:	50                   	push   %eax
f0103bbb:	68 ca 6d 10 f0       	push   $0xf0106dca
f0103bc0:	e8 93 fa ff ff       	call   f0103658 <cprintf>
f0103bc5:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103bc8:	83 ec 08             	sub    $0x8,%esp
f0103bcb:	ff 73 2c             	pushl  0x2c(%ebx)
f0103bce:	68 d9 6d 10 f0       	push   $0xf0106dd9
f0103bd3:	e8 80 fa ff ff       	call   f0103658 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bd8:	83 c4 10             	add    $0x10,%esp
f0103bdb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bdf:	75 49                	jne    f0103c2a <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103be1:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103be4:	89 c2                	mov    %eax,%edx
f0103be6:	83 e2 01             	and    $0x1,%edx
f0103be9:	ba 58 6d 10 f0       	mov    $0xf0106d58,%edx
f0103bee:	b9 4d 6d 10 f0       	mov    $0xf0106d4d,%ecx
f0103bf3:	0f 44 ca             	cmove  %edx,%ecx
f0103bf6:	89 c2                	mov    %eax,%edx
f0103bf8:	83 e2 02             	and    $0x2,%edx
f0103bfb:	ba 6a 6d 10 f0       	mov    $0xf0106d6a,%edx
f0103c00:	be 64 6d 10 f0       	mov    $0xf0106d64,%esi
f0103c05:	0f 45 d6             	cmovne %esi,%edx
f0103c08:	83 e0 04             	and    $0x4,%eax
f0103c0b:	be b7 6e 10 f0       	mov    $0xf0106eb7,%esi
f0103c10:	b8 6f 6d 10 f0       	mov    $0xf0106d6f,%eax
f0103c15:	0f 44 c6             	cmove  %esi,%eax
f0103c18:	51                   	push   %ecx
f0103c19:	52                   	push   %edx
f0103c1a:	50                   	push   %eax
f0103c1b:	68 e7 6d 10 f0       	push   $0xf0106de7
f0103c20:	e8 33 fa ff ff       	call   f0103658 <cprintf>
f0103c25:	83 c4 10             	add    $0x10,%esp
f0103c28:	eb 10                	jmp    f0103c3a <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c2a:	83 ec 0c             	sub    $0xc,%esp
f0103c2d:	68 5c 5d 10 f0       	push   $0xf0105d5c
f0103c32:	e8 21 fa ff ff       	call   f0103658 <cprintf>
f0103c37:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c3a:	83 ec 08             	sub    $0x8,%esp
f0103c3d:	ff 73 30             	pushl  0x30(%ebx)
f0103c40:	68 f6 6d 10 f0       	push   $0xf0106df6
f0103c45:	e8 0e fa ff ff       	call   f0103658 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c4a:	83 c4 08             	add    $0x8,%esp
f0103c4d:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c51:	50                   	push   %eax
f0103c52:	68 05 6e 10 f0       	push   $0xf0106e05
f0103c57:	e8 fc f9 ff ff       	call   f0103658 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c5c:	83 c4 08             	add    $0x8,%esp
f0103c5f:	ff 73 38             	pushl  0x38(%ebx)
f0103c62:	68 18 6e 10 f0       	push   $0xf0106e18
f0103c67:	e8 ec f9 ff ff       	call   f0103658 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c6c:	83 c4 10             	add    $0x10,%esp
f0103c6f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c73:	74 25                	je     f0103c9a <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c75:	83 ec 08             	sub    $0x8,%esp
f0103c78:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c7b:	68 27 6e 10 f0       	push   $0xf0106e27
f0103c80:	e8 d3 f9 ff ff       	call   f0103658 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c85:	83 c4 08             	add    $0x8,%esp
f0103c88:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c8c:	50                   	push   %eax
f0103c8d:	68 36 6e 10 f0       	push   $0xf0106e36
f0103c92:	e8 c1 f9 ff ff       	call   f0103658 <cprintf>
f0103c97:	83 c4 10             	add    $0x10,%esp
	}
}
f0103c9a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c9d:	5b                   	pop    %ebx
f0103c9e:	5e                   	pop    %esi
f0103c9f:	5d                   	pop    %ebp
f0103ca0:	c3                   	ret    

f0103ca1 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103ca1:	55                   	push   %ebp
f0103ca2:	89 e5                	mov    %esp,%ebp
f0103ca4:	57                   	push   %edi
f0103ca5:	56                   	push   %esi
f0103ca6:	53                   	push   %ebx
f0103ca7:	83 ec 0c             	sub    $0xc,%esp
f0103caa:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cad:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f0103cb0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103cb4:	75 17                	jne    f0103ccd <page_fault_handler+0x2c>
		panic("Kernel page fault!");	
f0103cb6:	83 ec 04             	sub    $0x4,%esp
f0103cb9:	68 49 6e 10 f0       	push   $0xf0106e49
f0103cbe:	68 37 01 00 00       	push   $0x137
f0103cc3:	68 5c 6e 10 f0       	push   $0xf0106e5c
f0103cc8:	e8 73 c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ccd:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cd0:	e8 31 16 00 00       	call   f0105306 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cd5:	57                   	push   %edi
f0103cd6:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cd7:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cda:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103ce0:	ff 70 48             	pushl  0x48(%eax)
f0103ce3:	68 04 70 10 f0       	push   $0xf0107004
f0103ce8:	e8 6b f9 ff ff       	call   f0103658 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103ced:	89 1c 24             	mov    %ebx,(%esp)
f0103cf0:	e8 24 fe ff ff       	call   f0103b19 <print_trapframe>
	env_destroy(curenv);
f0103cf5:	e8 0c 16 00 00       	call   f0105306 <cpunum>
f0103cfa:	83 c4 04             	add    $0x4,%esp
f0103cfd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d00:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d06:	e8 a2 f6 ff ff       	call   f01033ad <env_destroy>
}
f0103d0b:	83 c4 10             	add    $0x10,%esp
f0103d0e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d11:	5b                   	pop    %ebx
f0103d12:	5e                   	pop    %esi
f0103d13:	5f                   	pop    %edi
f0103d14:	5d                   	pop    %ebp
f0103d15:	c3                   	ret    

f0103d16 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d16:	55                   	push   %ebp
f0103d17:	89 e5                	mov    %esp,%ebp
f0103d19:	57                   	push   %edi
f0103d1a:	56                   	push   %esi
f0103d1b:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d1e:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d1f:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103d26:	74 01                	je     f0103d29 <trap+0x13>
		asm volatile("hlt");
f0103d28:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d29:	e8 d8 15 00 00       	call   f0105306 <cpunum>
f0103d2e:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d31:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103d37:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d3c:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d40:	83 f8 02             	cmp    $0x2,%eax
f0103d43:	75 10                	jne    f0103d55 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d45:	83 ec 0c             	sub    $0xc,%esp
f0103d48:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d4d:	e8 22 18 00 00       	call   f0105574 <spin_lock>
f0103d52:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103d55:	9c                   	pushf  
f0103d56:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d57:	f6 c4 02             	test   $0x2,%ah
f0103d5a:	74 19                	je     f0103d75 <trap+0x5f>
f0103d5c:	68 68 6e 10 f0       	push   $0xf0106e68
f0103d61:	68 0b 69 10 f0       	push   $0xf010690b
f0103d66:	68 02 01 00 00       	push   $0x102
f0103d6b:	68 5c 6e 10 f0       	push   $0xf0106e5c
f0103d70:	e8 cb c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d75:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d79:	83 e0 03             	and    $0x3,%eax
f0103d7c:	66 83 f8 03          	cmp    $0x3,%ax
f0103d80:	0f 85 90 00 00 00    	jne    f0103e16 <trap+0x100>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f0103d86:	e8 7b 15 00 00       	call   f0105306 <cpunum>
f0103d8b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d8e:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103d95:	75 19                	jne    f0103db0 <trap+0x9a>
f0103d97:	68 81 6e 10 f0       	push   $0xf0106e81
f0103d9c:	68 0b 69 10 f0       	push   $0xf010690b
f0103da1:	68 09 01 00 00       	push   $0x109
f0103da6:	68 5c 6e 10 f0       	push   $0xf0106e5c
f0103dab:	e8 90 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103db0:	e8 51 15 00 00       	call   f0105306 <cpunum>
f0103db5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db8:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103dbe:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103dc2:	75 2d                	jne    f0103df1 <trap+0xdb>
			env_free(curenv);
f0103dc4:	e8 3d 15 00 00       	call   f0105306 <cpunum>
f0103dc9:	83 ec 0c             	sub    $0xc,%esp
f0103dcc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dcf:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103dd5:	e8 f8 f3 ff ff       	call   f01031d2 <env_free>
			curenv = NULL;
f0103dda:	e8 27 15 00 00       	call   f0105306 <cpunum>
f0103ddf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103de2:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103de9:	00 00 00 
			sched_yield();
f0103dec:	e8 6e 02 00 00       	call   f010405f <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103df1:	e8 10 15 00 00       	call   f0105306 <cpunum>
f0103df6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df9:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103dff:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e04:	89 c7                	mov    %eax,%edi
f0103e06:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e08:	e8 f9 14 00 00       	call   f0105306 <cpunum>
f0103e0d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e10:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e16:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f0103e1c:	8b 46 28             	mov    0x28(%esi),%eax
f0103e1f:	83 f8 0e             	cmp    $0xe,%eax
f0103e22:	74 0c                	je     f0103e30 <trap+0x11a>
f0103e24:	83 f8 30             	cmp    $0x30,%eax
f0103e27:	74 29                	je     f0103e52 <trap+0x13c>
f0103e29:	83 f8 03             	cmp    $0x3,%eax
f0103e2c:	75 45                	jne    f0103e73 <trap+0x15d>
f0103e2e:	eb 11                	jmp    f0103e41 <trap+0x12b>
	{
		case T_PGFLT: 	  page_fault_handler(tf); 	return;
f0103e30:	83 ec 0c             	sub    $0xc,%esp
f0103e33:	56                   	push   %esi
f0103e34:	e8 68 fe ff ff       	call   f0103ca1 <page_fault_handler>
f0103e39:	83 c4 10             	add    $0x10,%esp
f0103e3c:	e9 94 00 00 00       	jmp    f0103ed5 <trap+0x1bf>

		case T_BRKPT:     monitor(tf);			return;
f0103e41:	83 ec 0c             	sub    $0xc,%esp
f0103e44:	56                   	push   %esi
f0103e45:	e8 f6 ca ff ff       	call   f0100940 <monitor>
f0103e4a:	83 c4 10             	add    $0x10,%esp
f0103e4d:	e9 83 00 00 00       	jmp    f0103ed5 <trap+0x1bf>

		case T_SYSCALL:	  
				tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
f0103e52:	83 ec 08             	sub    $0x8,%esp
f0103e55:	ff 76 04             	pushl  0x4(%esi)
f0103e58:	ff 36                	pushl  (%esi)
f0103e5a:	ff 76 10             	pushl  0x10(%esi)
f0103e5d:	ff 76 18             	pushl  0x18(%esi)
f0103e60:	ff 76 14             	pushl  0x14(%esi)
f0103e63:	ff 76 1c             	pushl  0x1c(%esi)
f0103e66:	e8 01 02 00 00       	call   f010406c <syscall>
f0103e6b:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e6e:	83 c4 20             	add    $0x20,%esp
f0103e71:	eb 62                	jmp    f0103ed5 <trap+0x1bf>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e73:	83 f8 27             	cmp    $0x27,%eax
f0103e76:	75 1a                	jne    f0103e92 <trap+0x17c>
		cprintf("Spurious interrupt on irq 7\n");
f0103e78:	83 ec 0c             	sub    $0xc,%esp
f0103e7b:	68 88 6e 10 f0       	push   $0xf0106e88
f0103e80:	e8 d3 f7 ff ff       	call   f0103658 <cprintf>
		print_trapframe(tf);
f0103e85:	89 34 24             	mov    %esi,(%esp)
f0103e88:	e8 8c fc ff ff       	call   f0103b19 <print_trapframe>
f0103e8d:	83 c4 10             	add    $0x10,%esp
f0103e90:	eb 43                	jmp    f0103ed5 <trap+0x1bf>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e92:	83 ec 0c             	sub    $0xc,%esp
f0103e95:	56                   	push   %esi
f0103e96:	e8 7e fc ff ff       	call   f0103b19 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103e9b:	83 c4 10             	add    $0x10,%esp
f0103e9e:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ea3:	75 17                	jne    f0103ebc <trap+0x1a6>
		panic("unhandled trap in kernel");
f0103ea5:	83 ec 04             	sub    $0x4,%esp
f0103ea8:	68 a5 6e 10 f0       	push   $0xf0106ea5
f0103ead:	68 e8 00 00 00       	push   $0xe8
f0103eb2:	68 5c 6e 10 f0       	push   $0xf0106e5c
f0103eb7:	e8 84 c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103ebc:	e8 45 14 00 00       	call   f0105306 <cpunum>
f0103ec1:	83 ec 0c             	sub    $0xc,%esp
f0103ec4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ec7:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ecd:	e8 db f4 ff ff       	call   f01033ad <env_destroy>
f0103ed2:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ed5:	e8 2c 14 00 00       	call   f0105306 <cpunum>
f0103eda:	6b c0 74             	imul   $0x74,%eax,%eax
f0103edd:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103ee4:	74 2a                	je     f0103f10 <trap+0x1fa>
f0103ee6:	e8 1b 14 00 00       	call   f0105306 <cpunum>
f0103eeb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eee:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103ef4:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ef8:	75 16                	jne    f0103f10 <trap+0x1fa>
		env_run(curenv);
f0103efa:	e8 07 14 00 00       	call   f0105306 <cpunum>
f0103eff:	83 ec 0c             	sub    $0xc,%esp
f0103f02:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f05:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103f0b:	e8 3c f5 ff ff       	call   f010344c <env_run>
	else
		sched_yield();
f0103f10:	e8 4a 01 00 00       	call   f010405f <sched_yield>
f0103f15:	90                   	nop

f0103f16 <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f0103f16:	6a 00                	push   $0x0
f0103f18:	6a 00                	push   $0x0
f0103f1a:	eb 5e                	jmp    f0103f7a <_alltraps>

f0103f1c <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f0103f1c:	6a 00                	push   $0x0
f0103f1e:	6a 01                	push   $0x1
f0103f20:	eb 58                	jmp    f0103f7a <_alltraps>

f0103f22 <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f0103f22:	6a 00                	push   $0x0
f0103f24:	6a 02                	push   $0x2
f0103f26:	eb 52                	jmp    f0103f7a <_alltraps>

f0103f28 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f0103f28:	6a 00                	push   $0x0
f0103f2a:	6a 03                	push   $0x3
f0103f2c:	eb 4c                	jmp    f0103f7a <_alltraps>

f0103f2e <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f0103f2e:	6a 00                	push   $0x0
f0103f30:	6a 04                	push   $0x4
f0103f32:	eb 46                	jmp    f0103f7a <_alltraps>

f0103f34 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f0103f34:	6a 00                	push   $0x0
f0103f36:	6a 05                	push   $0x5
f0103f38:	eb 40                	jmp    f0103f7a <_alltraps>

f0103f3a <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f0103f3a:	6a 00                	push   $0x0
f0103f3c:	6a 06                	push   $0x6
f0103f3e:	eb 3a                	jmp    f0103f7a <_alltraps>

f0103f40 <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f0103f40:	6a 00                	push   $0x0
f0103f42:	6a 07                	push   $0x7
f0103f44:	eb 34                	jmp    f0103f7a <_alltraps>

f0103f46 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f0103f46:	6a 08                	push   $0x8
f0103f48:	eb 30                	jmp    f0103f7a <_alltraps>

f0103f4a <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f0103f4a:	6a 0a                	push   $0xa
f0103f4c:	eb 2c                	jmp    f0103f7a <_alltraps>

f0103f4e <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f0103f4e:	6a 0b                	push   $0xb
f0103f50:	eb 28                	jmp    f0103f7a <_alltraps>

f0103f52 <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f0103f52:	6a 0c                	push   $0xc
f0103f54:	eb 24                	jmp    f0103f7a <_alltraps>

f0103f56 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f0103f56:	6a 0d                	push   $0xd
f0103f58:	eb 20                	jmp    f0103f7a <_alltraps>

f0103f5a <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f0103f5a:	6a 0e                	push   $0xe
f0103f5c:	eb 1c                	jmp    f0103f7a <_alltraps>

f0103f5e <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f0103f5e:	6a 00                	push   $0x0
f0103f60:	6a 10                	push   $0x10
f0103f62:	eb 16                	jmp    f0103f7a <_alltraps>

f0103f64 <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f0103f64:	6a 11                	push   $0x11
f0103f66:	eb 12                	jmp    f0103f7a <_alltraps>

f0103f68 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f0103f68:	6a 00                	push   $0x0
f0103f6a:	6a 12                	push   $0x12
f0103f6c:	eb 0c                	jmp    f0103f7a <_alltraps>

f0103f6e <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f0103f6e:	6a 00                	push   $0x0
f0103f70:	6a 13                	push   $0x13
f0103f72:	eb 06                	jmp    f0103f7a <_alltraps>

f0103f74 <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f0103f74:	6a 00                	push   $0x0
f0103f76:	6a 30                	push   $0x30
f0103f78:	eb 00                	jmp    f0103f7a <_alltraps>

f0103f7a <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f0103f7a:	1e                   	push   %ds
	pushl	%es
f0103f7b:	06                   	push   %es
	pushal
f0103f7c:	60                   	pusha  
	mov	$GD_KD, %eax
f0103f7d:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f0103f82:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f0103f84:	8e d8                	mov    %eax,%ds
	pushl	%esp
f0103f86:	54                   	push   %esp
	call	trap
f0103f87:	e8 8a fd ff ff       	call   f0103d16 <trap>

f0103f8c <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103f8c:	55                   	push   %ebp
f0103f8d:	89 e5                	mov    %esp,%ebp
f0103f8f:	83 ec 08             	sub    $0x8,%esp
f0103f92:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0103f97:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f9a:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103f9f:	8b 02                	mov    (%edx),%eax
f0103fa1:	83 e8 01             	sub    $0x1,%eax
f0103fa4:	83 f8 02             	cmp    $0x2,%eax
f0103fa7:	76 10                	jbe    f0103fb9 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fa9:	83 c1 01             	add    $0x1,%ecx
f0103fac:	83 c2 7c             	add    $0x7c,%edx
f0103faf:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fb5:	75 e8                	jne    f0103f9f <sched_halt+0x13>
f0103fb7:	eb 08                	jmp    f0103fc1 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103fb9:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fbf:	75 1f                	jne    f0103fe0 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103fc1:	83 ec 0c             	sub    $0xc,%esp
f0103fc4:	68 90 70 10 f0       	push   $0xf0107090
f0103fc9:	e8 8a f6 ff ff       	call   f0103658 <cprintf>
f0103fce:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103fd1:	83 ec 0c             	sub    $0xc,%esp
f0103fd4:	6a 00                	push   $0x0
f0103fd6:	e8 65 c9 ff ff       	call   f0100940 <monitor>
f0103fdb:	83 c4 10             	add    $0x10,%esp
f0103fde:	eb f1                	jmp    f0103fd1 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103fe0:	e8 21 13 00 00       	call   f0105306 <cpunum>
f0103fe5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fe8:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103fef:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103ff2:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103ff7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103ffc:	77 12                	ja     f0104010 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ffe:	50                   	push   %eax
f0103fff:	68 e8 59 10 f0       	push   $0xf01059e8
f0104004:	6a 3d                	push   $0x3d
f0104006:	68 b9 70 10 f0       	push   $0xf01070b9
f010400b:	e8 30 c0 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104010:	05 00 00 00 10       	add    $0x10000000,%eax
f0104015:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104018:	e8 e9 12 00 00       	call   f0105306 <cpunum>
f010401d:	6b d0 74             	imul   $0x74,%eax,%edx
f0104020:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104026:	b8 02 00 00 00       	mov    $0x2,%eax
f010402b:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010402f:	83 ec 0c             	sub    $0xc,%esp
f0104032:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0104037:	e8 d5 15 00 00       	call   f0105611 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010403c:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010403e:	e8 c3 12 00 00       	call   f0105306 <cpunum>
f0104043:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104046:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f010404c:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104051:	89 c4                	mov    %eax,%esp
f0104053:	6a 00                	push   $0x0
f0104055:	6a 00                	push   $0x0
f0104057:	f4                   	hlt    
f0104058:	eb fd                	jmp    f0104057 <sched_halt+0xcb>
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f010405a:	83 c4 10             	add    $0x10,%esp
f010405d:	c9                   	leave  
f010405e:	c3                   	ret    

f010405f <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010405f:	55                   	push   %ebp
f0104060:	89 e5                	mov    %esp,%ebp
f0104062:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f0104065:	e8 22 ff ff ff       	call   f0103f8c <sched_halt>
}
f010406a:	c9                   	leave  
f010406b:	c3                   	ret    

f010406c <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010406c:	55                   	push   %ebp
f010406d:	89 e5                	mov    %esp,%ebp
f010406f:	53                   	push   %ebx
f0104070:	83 ec 14             	sub    $0x14,%esp
f0104073:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
f0104076:	83 f8 01             	cmp    $0x1,%eax
f0104079:	74 4f                	je     f01040ca <syscall+0x5e>
f010407b:	83 f8 01             	cmp    $0x1,%eax
f010407e:	72 0f                	jb     f010408f <syscall+0x23>
f0104080:	83 f8 02             	cmp    $0x2,%eax
f0104083:	74 4f                	je     f01040d4 <syscall+0x68>
f0104085:	83 f8 03             	cmp    $0x3,%eax
f0104088:	74 60                	je     f01040ea <syscall+0x7e>
f010408a:	e9 e3 00 00 00       	jmp    f0104172 <syscall+0x106>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f010408f:	e8 72 12 00 00       	call   f0105306 <cpunum>
f0104094:	6a 04                	push   $0x4
f0104096:	ff 75 10             	pushl  0x10(%ebp)
f0104099:	ff 75 0c             	pushl  0xc(%ebp)
f010409c:	6b c0 74             	imul   $0x74,%eax,%eax
f010409f:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01040a5:	e8 a4 ec ff ff       	call   f0102d4e <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01040aa:	83 c4 0c             	add    $0xc,%esp
f01040ad:	ff 75 0c             	pushl  0xc(%ebp)
f01040b0:	ff 75 10             	pushl  0x10(%ebp)
f01040b3:	68 c6 70 10 f0       	push   $0xf01070c6
f01040b8:	e8 9b f5 ff ff       	call   f0103658 <cprintf>
f01040bd:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
f01040c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01040c5:	e9 ad 00 00 00       	jmp    f0104177 <syscall+0x10b>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01040ca:	e8 0e c5 ff ff       	call   f01005dd <cons_getc>

	switch (syscallno) 
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			return sys_cgetc();		
f01040cf:	e9 a3 00 00 00       	jmp    f0104177 <syscall+0x10b>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01040d4:	e8 2d 12 00 00       	call   f0105306 <cpunum>
f01040d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01040dc:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01040e2:	8b 40 48             	mov    0x48(%eax),%eax
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			return sys_cgetc();		

		case SYS_getenvid:		return sys_getenvid();
f01040e5:	e9 8d 00 00 00       	jmp    f0104177 <syscall+0x10b>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01040ea:	83 ec 04             	sub    $0x4,%esp
f01040ed:	6a 01                	push   $0x1
f01040ef:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040f2:	50                   	push   %eax
f01040f3:	ff 75 0c             	pushl  0xc(%ebp)
f01040f6:	e8 08 ed ff ff       	call   f0102e03 <envid2env>
f01040fb:	83 c4 10             	add    $0x10,%esp
f01040fe:	85 c0                	test   %eax,%eax
f0104100:	78 69                	js     f010416b <syscall+0xff>
		return r;
	if (e == curenv)
f0104102:	e8 ff 11 00 00       	call   f0105306 <cpunum>
f0104107:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010410a:	6b c0 74             	imul   $0x74,%eax,%eax
f010410d:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f0104113:	75 23                	jne    f0104138 <syscall+0xcc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104115:	e8 ec 11 00 00       	call   f0105306 <cpunum>
f010411a:	83 ec 08             	sub    $0x8,%esp
f010411d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104120:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104126:	ff 70 48             	pushl  0x48(%eax)
f0104129:	68 cb 70 10 f0       	push   $0xf01070cb
f010412e:	e8 25 f5 ff ff       	call   f0103658 <cprintf>
f0104133:	83 c4 10             	add    $0x10,%esp
f0104136:	eb 25                	jmp    f010415d <syscall+0xf1>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104138:	8b 5a 48             	mov    0x48(%edx),%ebx
f010413b:	e8 c6 11 00 00       	call   f0105306 <cpunum>
f0104140:	83 ec 04             	sub    $0x4,%esp
f0104143:	53                   	push   %ebx
f0104144:	6b c0 74             	imul   $0x74,%eax,%eax
f0104147:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010414d:	ff 70 48             	pushl  0x48(%eax)
f0104150:	68 e6 70 10 f0       	push   $0xf01070e6
f0104155:	e8 fe f4 ff ff       	call   f0103658 <cprintf>
f010415a:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010415d:	83 ec 0c             	sub    $0xc,%esp
f0104160:	ff 75 f4             	pushl  -0xc(%ebp)
f0104163:	e8 45 f2 ff ff       	call   f01033ad <env_destroy>
f0104168:	83 c4 10             	add    $0x10,%esp

		case SYS_getenvid:		return sys_getenvid();

		case SYS_env_destroy:		sys_env_destroy((envid_t) a1);

		default:			return -E_INVAL;
f010416b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104170:	eb 05                	jmp    f0104177 <syscall+0x10b>
f0104172:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0104177:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010417a:	c9                   	leave  
f010417b:	c3                   	ret    

f010417c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010417c:	55                   	push   %ebp
f010417d:	89 e5                	mov    %esp,%ebp
f010417f:	57                   	push   %edi
f0104180:	56                   	push   %esi
f0104181:	53                   	push   %ebx
f0104182:	83 ec 14             	sub    $0x14,%esp
f0104185:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104188:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010418b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010418e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104191:	8b 1a                	mov    (%edx),%ebx
f0104193:	8b 01                	mov    (%ecx),%eax
f0104195:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104198:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010419f:	eb 7f                	jmp    f0104220 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01041a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01041a4:	01 d8                	add    %ebx,%eax
f01041a6:	89 c6                	mov    %eax,%esi
f01041a8:	c1 ee 1f             	shr    $0x1f,%esi
f01041ab:	01 c6                	add    %eax,%esi
f01041ad:	d1 fe                	sar    %esi
f01041af:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01041b2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041b5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01041b8:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041ba:	eb 03                	jmp    f01041bf <stab_binsearch+0x43>
			m--;
f01041bc:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041bf:	39 c3                	cmp    %eax,%ebx
f01041c1:	7f 0d                	jg     f01041d0 <stab_binsearch+0x54>
f01041c3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01041c7:	83 ea 0c             	sub    $0xc,%edx
f01041ca:	39 f9                	cmp    %edi,%ecx
f01041cc:	75 ee                	jne    f01041bc <stab_binsearch+0x40>
f01041ce:	eb 05                	jmp    f01041d5 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01041d0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01041d3:	eb 4b                	jmp    f0104220 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01041d5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01041d8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041db:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01041df:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041e2:	76 11                	jbe    f01041f5 <stab_binsearch+0x79>
			*region_left = m;
f01041e4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01041e7:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01041e9:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01041ec:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01041f3:	eb 2b                	jmp    f0104220 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01041f5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041f8:	73 14                	jae    f010420e <stab_binsearch+0x92>
			*region_right = m - 1;
f01041fa:	83 e8 01             	sub    $0x1,%eax
f01041fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104200:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104203:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104205:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010420c:	eb 12                	jmp    f0104220 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010420e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104211:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104213:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104217:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104219:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104220:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104223:	0f 8e 78 ff ff ff    	jle    f01041a1 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104229:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010422d:	75 0f                	jne    f010423e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010422f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104232:	8b 00                	mov    (%eax),%eax
f0104234:	83 e8 01             	sub    $0x1,%eax
f0104237:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010423a:	89 06                	mov    %eax,(%esi)
f010423c:	eb 2c                	jmp    f010426a <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010423e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104241:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104243:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104246:	8b 0e                	mov    (%esi),%ecx
f0104248:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010424b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010424e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104251:	eb 03                	jmp    f0104256 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104253:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104256:	39 c8                	cmp    %ecx,%eax
f0104258:	7e 0b                	jle    f0104265 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010425a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010425e:	83 ea 0c             	sub    $0xc,%edx
f0104261:	39 df                	cmp    %ebx,%edi
f0104263:	75 ee                	jne    f0104253 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104265:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104268:	89 06                	mov    %eax,(%esi)
	}
}
f010426a:	83 c4 14             	add    $0x14,%esp
f010426d:	5b                   	pop    %ebx
f010426e:	5e                   	pop    %esi
f010426f:	5f                   	pop    %edi
f0104270:	5d                   	pop    %ebp
f0104271:	c3                   	ret    

f0104272 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104272:	55                   	push   %ebp
f0104273:	89 e5                	mov    %esp,%ebp
f0104275:	57                   	push   %edi
f0104276:	56                   	push   %esi
f0104277:	53                   	push   %ebx
f0104278:	83 ec 3c             	sub    $0x3c,%esp
f010427b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010427e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104281:	c7 03 fe 70 10 f0    	movl   $0xf01070fe,(%ebx)
	info->eip_line = 0;
f0104287:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010428e:	c7 43 08 fe 70 10 f0 	movl   $0xf01070fe,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104295:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010429c:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010429f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01042a6:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01042ac:	0f 87 a3 00 00 00    	ja     f0104355 <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f01042b2:	e8 4f 10 00 00       	call   f0105306 <cpunum>
f01042b7:	6a 04                	push   $0x4
f01042b9:	6a 10                	push   $0x10
f01042bb:	68 00 00 20 00       	push   $0x200000
f01042c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01042c3:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01042c9:	e8 0a ea ff ff       	call   f0102cd8 <user_mem_check>
f01042ce:	83 c4 10             	add    $0x10,%esp
f01042d1:	85 c0                	test   %eax,%eax
f01042d3:	0f 84 3e 02 00 00    	je     f0104517 <debuginfo_eip+0x2a5>
                        return -1;

		stabs = usd->stabs;
f01042d9:	a1 00 00 20 00       	mov    0x200000,%eax
f01042de:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01042e1:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01042e7:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01042ed:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01042f0:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01042f5:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f01042f8:	e8 09 10 00 00       	call   f0105306 <cpunum>
f01042fd:	6a 04                	push   $0x4
f01042ff:	89 f2                	mov    %esi,%edx
f0104301:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104304:	29 ca                	sub    %ecx,%edx
f0104306:	c1 fa 02             	sar    $0x2,%edx
f0104309:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010430f:	52                   	push   %edx
f0104310:	51                   	push   %ecx
f0104311:	6b c0 74             	imul   $0x74,%eax,%eax
f0104314:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010431a:	e8 b9 e9 ff ff       	call   f0102cd8 <user_mem_check>
f010431f:	83 c4 10             	add    $0x10,%esp
f0104322:	85 c0                	test   %eax,%eax
f0104324:	0f 84 f4 01 00 00    	je     f010451e <debuginfo_eip+0x2ac>
			return -1;

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f010432a:	e8 d7 0f 00 00       	call   f0105306 <cpunum>
f010432f:	6a 04                	push   $0x4
f0104331:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104334:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104337:	29 ca                	sub    %ecx,%edx
f0104339:	52                   	push   %edx
f010433a:	51                   	push   %ecx
f010433b:	6b c0 74             	imul   $0x74,%eax,%eax
f010433e:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104344:	e8 8f e9 ff ff       	call   f0102cd8 <user_mem_check>
f0104349:	83 c4 10             	add    $0x10,%esp
f010434c:	85 c0                	test   %eax,%eax
f010434e:	75 1f                	jne    f010436f <debuginfo_eip+0xfd>
f0104350:	e9 d0 01 00 00       	jmp    f0104525 <debuginfo_eip+0x2b3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104355:	c7 45 bc 82 44 11 f0 	movl   $0xf0114482,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010435c:	c7 45 b8 2d 0e 11 f0 	movl   $0xf0110e2d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104363:	be 2c 0e 11 f0       	mov    $0xf0110e2c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104368:	c7 45 c0 d4 75 10 f0 	movl   $0xf01075d4,-0x40(%ebp)
		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010436f:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104372:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104375:	0f 83 b1 01 00 00    	jae    f010452c <debuginfo_eip+0x2ba>
f010437b:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010437f:	0f 85 ae 01 00 00    	jne    f0104533 <debuginfo_eip+0x2c1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104385:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010438c:	2b 75 c0             	sub    -0x40(%ebp),%esi
f010438f:	c1 fe 02             	sar    $0x2,%esi
f0104392:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104398:	83 e8 01             	sub    $0x1,%eax
f010439b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010439e:	83 ec 08             	sub    $0x8,%esp
f01043a1:	57                   	push   %edi
f01043a2:	6a 64                	push   $0x64
f01043a4:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01043a7:	89 d1                	mov    %edx,%ecx
f01043a9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01043ac:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01043af:	89 f0                	mov    %esi,%eax
f01043b1:	e8 c6 fd ff ff       	call   f010417c <stab_binsearch>
	if (lfile == 0)
f01043b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043b9:	83 c4 10             	add    $0x10,%esp
f01043bc:	85 c0                	test   %eax,%eax
f01043be:	0f 84 76 01 00 00    	je     f010453a <debuginfo_eip+0x2c8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01043c4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01043c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043ca:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01043cd:	83 ec 08             	sub    $0x8,%esp
f01043d0:	57                   	push   %edi
f01043d1:	6a 24                	push   $0x24
f01043d3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01043d6:	89 d1                	mov    %edx,%ecx
f01043d8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01043db:	89 f0                	mov    %esi,%eax
f01043dd:	e8 9a fd ff ff       	call   f010417c <stab_binsearch>

	if (lfun <= rfun) {
f01043e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01043e5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01043e8:	83 c4 10             	add    $0x10,%esp
f01043eb:	39 d0                	cmp    %edx,%eax
f01043ed:	7f 2e                	jg     f010441d <debuginfo_eip+0x1ab>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01043ef:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01043f2:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01043f5:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01043f8:	8b 36                	mov    (%esi),%esi
f01043fa:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01043fd:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104400:	39 ce                	cmp    %ecx,%esi
f0104402:	73 06                	jae    f010440a <debuginfo_eip+0x198>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104404:	03 75 b8             	add    -0x48(%ebp),%esi
f0104407:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010440a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010440d:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104410:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104413:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104415:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104418:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010441b:	eb 0f                	jmp    f010442c <debuginfo_eip+0x1ba>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010441d:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104423:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104426:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104429:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010442c:	83 ec 08             	sub    $0x8,%esp
f010442f:	6a 3a                	push   $0x3a
f0104431:	ff 73 08             	pushl  0x8(%ebx)
f0104434:	e8 8f 08 00 00       	call   f0104cc8 <strfind>
f0104439:	2b 43 08             	sub    0x8(%ebx),%eax
f010443c:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010443f:	83 c4 08             	add    $0x8,%esp
f0104442:	57                   	push   %edi
f0104443:	6a 44                	push   $0x44
f0104445:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104448:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010444b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010444e:	89 f8                	mov    %edi,%eax
f0104450:	e8 27 fd ff ff       	call   f010417c <stab_binsearch>
	
	if(lline > rline)
f0104455:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104458:	83 c4 10             	add    $0x10,%esp
f010445b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010445e:	0f 8f dd 00 00 00    	jg     f0104541 <debuginfo_eip+0x2cf>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f0104464:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104467:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010446a:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f010446e:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104471:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104474:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104478:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010447b:	eb 0a                	jmp    f0104487 <debuginfo_eip+0x215>
f010447d:	83 e8 01             	sub    $0x1,%eax
f0104480:	83 ea 0c             	sub    $0xc,%edx
f0104483:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104487:	39 c7                	cmp    %eax,%edi
f0104489:	7e 05                	jle    f0104490 <debuginfo_eip+0x21e>
f010448b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010448e:	eb 47                	jmp    f01044d7 <debuginfo_eip+0x265>
	       && stabs[lline].n_type != N_SOL
f0104490:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104494:	80 f9 84             	cmp    $0x84,%cl
f0104497:	75 0e                	jne    f01044a7 <debuginfo_eip+0x235>
f0104499:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010449c:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01044a0:	74 1c                	je     f01044be <debuginfo_eip+0x24c>
f01044a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01044a5:	eb 17                	jmp    f01044be <debuginfo_eip+0x24c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01044a7:	80 f9 64             	cmp    $0x64,%cl
f01044aa:	75 d1                	jne    f010447d <debuginfo_eip+0x20b>
f01044ac:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01044b0:	74 cb                	je     f010447d <debuginfo_eip+0x20b>
f01044b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01044b5:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01044b9:	74 03                	je     f01044be <debuginfo_eip+0x24c>
f01044bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01044be:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01044c1:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01044c4:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01044c7:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01044ca:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01044cd:	29 f8                	sub    %edi,%eax
f01044cf:	39 c2                	cmp    %eax,%edx
f01044d1:	73 04                	jae    f01044d7 <debuginfo_eip+0x265>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01044d3:	01 fa                	add    %edi,%edx
f01044d5:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01044da:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044dd:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044e2:	39 f2                	cmp    %esi,%edx
f01044e4:	7d 67                	jge    f010454d <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
f01044e6:	83 c2 01             	add    $0x1,%edx
f01044e9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01044ec:	89 d0                	mov    %edx,%eax
f01044ee:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01044f1:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01044f4:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01044f7:	eb 04                	jmp    f01044fd <debuginfo_eip+0x28b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01044f9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01044fd:	39 c6                	cmp    %eax,%esi
f01044ff:	7e 47                	jle    f0104548 <debuginfo_eip+0x2d6>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104501:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104505:	83 c0 01             	add    $0x1,%eax
f0104508:	83 c2 0c             	add    $0xc,%edx
f010450b:	80 f9 a0             	cmp    $0xa0,%cl
f010450e:	74 e9                	je     f01044f9 <debuginfo_eip+0x287>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104510:	b8 00 00 00 00       	mov    $0x0,%eax
f0104515:	eb 36                	jmp    f010454d <debuginfo_eip+0x2db>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
                        return -1;
f0104517:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010451c:	eb 2f                	jmp    f010454d <debuginfo_eip+0x2db>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
			return -1;
f010451e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104523:	eb 28                	jmp    f010454d <debuginfo_eip+0x2db>

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f0104525:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010452a:	eb 21                	jmp    f010454d <debuginfo_eip+0x2db>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010452c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104531:	eb 1a                	jmp    f010454d <debuginfo_eip+0x2db>
f0104533:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104538:	eb 13                	jmp    f010454d <debuginfo_eip+0x2db>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010453a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010453f:	eb 0c                	jmp    f010454d <debuginfo_eip+0x2db>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0104541:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104546:	eb 05                	jmp    f010454d <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104548:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010454d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104550:	5b                   	pop    %ebx
f0104551:	5e                   	pop    %esi
f0104552:	5f                   	pop    %edi
f0104553:	5d                   	pop    %ebp
f0104554:	c3                   	ret    

f0104555 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104555:	55                   	push   %ebp
f0104556:	89 e5                	mov    %esp,%ebp
f0104558:	57                   	push   %edi
f0104559:	56                   	push   %esi
f010455a:	53                   	push   %ebx
f010455b:	83 ec 1c             	sub    $0x1c,%esp
f010455e:	89 c7                	mov    %eax,%edi
f0104560:	89 d6                	mov    %edx,%esi
f0104562:	8b 45 08             	mov    0x8(%ebp),%eax
f0104565:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104568:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010456b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010456e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104571:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104576:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104579:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010457c:	39 d3                	cmp    %edx,%ebx
f010457e:	72 05                	jb     f0104585 <printnum+0x30>
f0104580:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104583:	77 45                	ja     f01045ca <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104585:	83 ec 0c             	sub    $0xc,%esp
f0104588:	ff 75 18             	pushl  0x18(%ebp)
f010458b:	8b 45 14             	mov    0x14(%ebp),%eax
f010458e:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104591:	53                   	push   %ebx
f0104592:	ff 75 10             	pushl  0x10(%ebp)
f0104595:	83 ec 08             	sub    $0x8,%esp
f0104598:	ff 75 e4             	pushl  -0x1c(%ebp)
f010459b:	ff 75 e0             	pushl  -0x20(%ebp)
f010459e:	ff 75 dc             	pushl  -0x24(%ebp)
f01045a1:	ff 75 d8             	pushl  -0x28(%ebp)
f01045a4:	e8 57 11 00 00       	call   f0105700 <__udivdi3>
f01045a9:	83 c4 18             	add    $0x18,%esp
f01045ac:	52                   	push   %edx
f01045ad:	50                   	push   %eax
f01045ae:	89 f2                	mov    %esi,%edx
f01045b0:	89 f8                	mov    %edi,%eax
f01045b2:	e8 9e ff ff ff       	call   f0104555 <printnum>
f01045b7:	83 c4 20             	add    $0x20,%esp
f01045ba:	eb 18                	jmp    f01045d4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01045bc:	83 ec 08             	sub    $0x8,%esp
f01045bf:	56                   	push   %esi
f01045c0:	ff 75 18             	pushl  0x18(%ebp)
f01045c3:	ff d7                	call   *%edi
f01045c5:	83 c4 10             	add    $0x10,%esp
f01045c8:	eb 03                	jmp    f01045cd <printnum+0x78>
f01045ca:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01045cd:	83 eb 01             	sub    $0x1,%ebx
f01045d0:	85 db                	test   %ebx,%ebx
f01045d2:	7f e8                	jg     f01045bc <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01045d4:	83 ec 08             	sub    $0x8,%esp
f01045d7:	56                   	push   %esi
f01045d8:	83 ec 04             	sub    $0x4,%esp
f01045db:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045de:	ff 75 e0             	pushl  -0x20(%ebp)
f01045e1:	ff 75 dc             	pushl  -0x24(%ebp)
f01045e4:	ff 75 d8             	pushl  -0x28(%ebp)
f01045e7:	e8 44 12 00 00       	call   f0105830 <__umoddi3>
f01045ec:	83 c4 14             	add    $0x14,%esp
f01045ef:	0f be 80 08 71 10 f0 	movsbl -0xfef8ef8(%eax),%eax
f01045f6:	50                   	push   %eax
f01045f7:	ff d7                	call   *%edi
}
f01045f9:	83 c4 10             	add    $0x10,%esp
f01045fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045ff:	5b                   	pop    %ebx
f0104600:	5e                   	pop    %esi
f0104601:	5f                   	pop    %edi
f0104602:	5d                   	pop    %ebp
f0104603:	c3                   	ret    

f0104604 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104604:	55                   	push   %ebp
f0104605:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104607:	83 fa 01             	cmp    $0x1,%edx
f010460a:	7e 0e                	jle    f010461a <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010460c:	8b 10                	mov    (%eax),%edx
f010460e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104611:	89 08                	mov    %ecx,(%eax)
f0104613:	8b 02                	mov    (%edx),%eax
f0104615:	8b 52 04             	mov    0x4(%edx),%edx
f0104618:	eb 22                	jmp    f010463c <getuint+0x38>
	else if (lflag)
f010461a:	85 d2                	test   %edx,%edx
f010461c:	74 10                	je     f010462e <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010461e:	8b 10                	mov    (%eax),%edx
f0104620:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104623:	89 08                	mov    %ecx,(%eax)
f0104625:	8b 02                	mov    (%edx),%eax
f0104627:	ba 00 00 00 00       	mov    $0x0,%edx
f010462c:	eb 0e                	jmp    f010463c <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010462e:	8b 10                	mov    (%eax),%edx
f0104630:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104633:	89 08                	mov    %ecx,(%eax)
f0104635:	8b 02                	mov    (%edx),%eax
f0104637:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010463c:	5d                   	pop    %ebp
f010463d:	c3                   	ret    

f010463e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010463e:	55                   	push   %ebp
f010463f:	89 e5                	mov    %esp,%ebp
f0104641:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104644:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104648:	8b 10                	mov    (%eax),%edx
f010464a:	3b 50 04             	cmp    0x4(%eax),%edx
f010464d:	73 0a                	jae    f0104659 <sprintputch+0x1b>
		*b->buf++ = ch;
f010464f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104652:	89 08                	mov    %ecx,(%eax)
f0104654:	8b 45 08             	mov    0x8(%ebp),%eax
f0104657:	88 02                	mov    %al,(%edx)
}
f0104659:	5d                   	pop    %ebp
f010465a:	c3                   	ret    

f010465b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010465b:	55                   	push   %ebp
f010465c:	89 e5                	mov    %esp,%ebp
f010465e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104661:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104664:	50                   	push   %eax
f0104665:	ff 75 10             	pushl  0x10(%ebp)
f0104668:	ff 75 0c             	pushl  0xc(%ebp)
f010466b:	ff 75 08             	pushl  0x8(%ebp)
f010466e:	e8 05 00 00 00       	call   f0104678 <vprintfmt>
	va_end(ap);
}
f0104673:	83 c4 10             	add    $0x10,%esp
f0104676:	c9                   	leave  
f0104677:	c3                   	ret    

f0104678 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104678:	55                   	push   %ebp
f0104679:	89 e5                	mov    %esp,%ebp
f010467b:	57                   	push   %edi
f010467c:	56                   	push   %esi
f010467d:	53                   	push   %ebx
f010467e:	83 ec 2c             	sub    $0x2c,%esp
f0104681:	8b 75 08             	mov    0x8(%ebp),%esi
f0104684:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104687:	8b 7d 10             	mov    0x10(%ebp),%edi
f010468a:	eb 12                	jmp    f010469e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010468c:	85 c0                	test   %eax,%eax
f010468e:	0f 84 89 03 00 00    	je     f0104a1d <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104694:	83 ec 08             	sub    $0x8,%esp
f0104697:	53                   	push   %ebx
f0104698:	50                   	push   %eax
f0104699:	ff d6                	call   *%esi
f010469b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010469e:	83 c7 01             	add    $0x1,%edi
f01046a1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01046a5:	83 f8 25             	cmp    $0x25,%eax
f01046a8:	75 e2                	jne    f010468c <vprintfmt+0x14>
f01046aa:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01046ae:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01046b5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01046bc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01046c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01046c8:	eb 07                	jmp    f01046d1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01046cd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046d1:	8d 47 01             	lea    0x1(%edi),%eax
f01046d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01046d7:	0f b6 07             	movzbl (%edi),%eax
f01046da:	0f b6 c8             	movzbl %al,%ecx
f01046dd:	83 e8 23             	sub    $0x23,%eax
f01046e0:	3c 55                	cmp    $0x55,%al
f01046e2:	0f 87 1a 03 00 00    	ja     f0104a02 <vprintfmt+0x38a>
f01046e8:	0f b6 c0             	movzbl %al,%eax
f01046eb:	ff 24 85 c0 71 10 f0 	jmp    *-0xfef8e40(,%eax,4)
f01046f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01046f5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01046f9:	eb d6                	jmp    f01046d1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104703:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104706:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104709:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010470d:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104710:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104713:	83 fa 09             	cmp    $0x9,%edx
f0104716:	77 39                	ja     f0104751 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104718:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010471b:	eb e9                	jmp    f0104706 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010471d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104720:	8d 48 04             	lea    0x4(%eax),%ecx
f0104723:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104726:	8b 00                	mov    (%eax),%eax
f0104728:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010472b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010472e:	eb 27                	jmp    f0104757 <vprintfmt+0xdf>
f0104730:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104733:	85 c0                	test   %eax,%eax
f0104735:	b9 00 00 00 00       	mov    $0x0,%ecx
f010473a:	0f 49 c8             	cmovns %eax,%ecx
f010473d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104740:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104743:	eb 8c                	jmp    f01046d1 <vprintfmt+0x59>
f0104745:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104748:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010474f:	eb 80                	jmp    f01046d1 <vprintfmt+0x59>
f0104751:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104754:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104757:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010475b:	0f 89 70 ff ff ff    	jns    f01046d1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104761:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104764:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104767:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010476e:	e9 5e ff ff ff       	jmp    f01046d1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104773:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104776:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104779:	e9 53 ff ff ff       	jmp    f01046d1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010477e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104781:	8d 50 04             	lea    0x4(%eax),%edx
f0104784:	89 55 14             	mov    %edx,0x14(%ebp)
f0104787:	83 ec 08             	sub    $0x8,%esp
f010478a:	53                   	push   %ebx
f010478b:	ff 30                	pushl  (%eax)
f010478d:	ff d6                	call   *%esi
			break;
f010478f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104792:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104795:	e9 04 ff ff ff       	jmp    f010469e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010479a:	8b 45 14             	mov    0x14(%ebp),%eax
f010479d:	8d 50 04             	lea    0x4(%eax),%edx
f01047a0:	89 55 14             	mov    %edx,0x14(%ebp)
f01047a3:	8b 00                	mov    (%eax),%eax
f01047a5:	99                   	cltd   
f01047a6:	31 d0                	xor    %edx,%eax
f01047a8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01047aa:	83 f8 08             	cmp    $0x8,%eax
f01047ad:	7f 0b                	jg     f01047ba <vprintfmt+0x142>
f01047af:	8b 14 85 20 73 10 f0 	mov    -0xfef8ce0(,%eax,4),%edx
f01047b6:	85 d2                	test   %edx,%edx
f01047b8:	75 18                	jne    f01047d2 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01047ba:	50                   	push   %eax
f01047bb:	68 20 71 10 f0       	push   $0xf0107120
f01047c0:	53                   	push   %ebx
f01047c1:	56                   	push   %esi
f01047c2:	e8 94 fe ff ff       	call   f010465b <printfmt>
f01047c7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01047cd:	e9 cc fe ff ff       	jmp    f010469e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01047d2:	52                   	push   %edx
f01047d3:	68 1d 69 10 f0       	push   $0xf010691d
f01047d8:	53                   	push   %ebx
f01047d9:	56                   	push   %esi
f01047da:	e8 7c fe ff ff       	call   f010465b <printfmt>
f01047df:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047e5:	e9 b4 fe ff ff       	jmp    f010469e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01047ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01047ed:	8d 50 04             	lea    0x4(%eax),%edx
f01047f0:	89 55 14             	mov    %edx,0x14(%ebp)
f01047f3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01047f5:	85 ff                	test   %edi,%edi
f01047f7:	b8 19 71 10 f0       	mov    $0xf0107119,%eax
f01047fc:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01047ff:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104803:	0f 8e 94 00 00 00    	jle    f010489d <vprintfmt+0x225>
f0104809:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010480d:	0f 84 98 00 00 00    	je     f01048ab <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104813:	83 ec 08             	sub    $0x8,%esp
f0104816:	ff 75 d0             	pushl  -0x30(%ebp)
f0104819:	57                   	push   %edi
f010481a:	e8 5f 03 00 00       	call   f0104b7e <strnlen>
f010481f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104822:	29 c1                	sub    %eax,%ecx
f0104824:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104827:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010482a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010482e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104831:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104834:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104836:	eb 0f                	jmp    f0104847 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104838:	83 ec 08             	sub    $0x8,%esp
f010483b:	53                   	push   %ebx
f010483c:	ff 75 e0             	pushl  -0x20(%ebp)
f010483f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104841:	83 ef 01             	sub    $0x1,%edi
f0104844:	83 c4 10             	add    $0x10,%esp
f0104847:	85 ff                	test   %edi,%edi
f0104849:	7f ed                	jg     f0104838 <vprintfmt+0x1c0>
f010484b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010484e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104851:	85 c9                	test   %ecx,%ecx
f0104853:	b8 00 00 00 00       	mov    $0x0,%eax
f0104858:	0f 49 c1             	cmovns %ecx,%eax
f010485b:	29 c1                	sub    %eax,%ecx
f010485d:	89 75 08             	mov    %esi,0x8(%ebp)
f0104860:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104863:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104866:	89 cb                	mov    %ecx,%ebx
f0104868:	eb 4d                	jmp    f01048b7 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010486a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010486e:	74 1b                	je     f010488b <vprintfmt+0x213>
f0104870:	0f be c0             	movsbl %al,%eax
f0104873:	83 e8 20             	sub    $0x20,%eax
f0104876:	83 f8 5e             	cmp    $0x5e,%eax
f0104879:	76 10                	jbe    f010488b <vprintfmt+0x213>
					putch('?', putdat);
f010487b:	83 ec 08             	sub    $0x8,%esp
f010487e:	ff 75 0c             	pushl  0xc(%ebp)
f0104881:	6a 3f                	push   $0x3f
f0104883:	ff 55 08             	call   *0x8(%ebp)
f0104886:	83 c4 10             	add    $0x10,%esp
f0104889:	eb 0d                	jmp    f0104898 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010488b:	83 ec 08             	sub    $0x8,%esp
f010488e:	ff 75 0c             	pushl  0xc(%ebp)
f0104891:	52                   	push   %edx
f0104892:	ff 55 08             	call   *0x8(%ebp)
f0104895:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104898:	83 eb 01             	sub    $0x1,%ebx
f010489b:	eb 1a                	jmp    f01048b7 <vprintfmt+0x23f>
f010489d:	89 75 08             	mov    %esi,0x8(%ebp)
f01048a0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01048a3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01048a6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01048a9:	eb 0c                	jmp    f01048b7 <vprintfmt+0x23f>
f01048ab:	89 75 08             	mov    %esi,0x8(%ebp)
f01048ae:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01048b1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01048b4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01048b7:	83 c7 01             	add    $0x1,%edi
f01048ba:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01048be:	0f be d0             	movsbl %al,%edx
f01048c1:	85 d2                	test   %edx,%edx
f01048c3:	74 23                	je     f01048e8 <vprintfmt+0x270>
f01048c5:	85 f6                	test   %esi,%esi
f01048c7:	78 a1                	js     f010486a <vprintfmt+0x1f2>
f01048c9:	83 ee 01             	sub    $0x1,%esi
f01048cc:	79 9c                	jns    f010486a <vprintfmt+0x1f2>
f01048ce:	89 df                	mov    %ebx,%edi
f01048d0:	8b 75 08             	mov    0x8(%ebp),%esi
f01048d3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048d6:	eb 18                	jmp    f01048f0 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01048d8:	83 ec 08             	sub    $0x8,%esp
f01048db:	53                   	push   %ebx
f01048dc:	6a 20                	push   $0x20
f01048de:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01048e0:	83 ef 01             	sub    $0x1,%edi
f01048e3:	83 c4 10             	add    $0x10,%esp
f01048e6:	eb 08                	jmp    f01048f0 <vprintfmt+0x278>
f01048e8:	89 df                	mov    %ebx,%edi
f01048ea:	8b 75 08             	mov    0x8(%ebp),%esi
f01048ed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048f0:	85 ff                	test   %edi,%edi
f01048f2:	7f e4                	jg     f01048d8 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048f7:	e9 a2 fd ff ff       	jmp    f010469e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01048fc:	83 fa 01             	cmp    $0x1,%edx
f01048ff:	7e 16                	jle    f0104917 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104901:	8b 45 14             	mov    0x14(%ebp),%eax
f0104904:	8d 50 08             	lea    0x8(%eax),%edx
f0104907:	89 55 14             	mov    %edx,0x14(%ebp)
f010490a:	8b 50 04             	mov    0x4(%eax),%edx
f010490d:	8b 00                	mov    (%eax),%eax
f010490f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104912:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104915:	eb 32                	jmp    f0104949 <vprintfmt+0x2d1>
	else if (lflag)
f0104917:	85 d2                	test   %edx,%edx
f0104919:	74 18                	je     f0104933 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010491b:	8b 45 14             	mov    0x14(%ebp),%eax
f010491e:	8d 50 04             	lea    0x4(%eax),%edx
f0104921:	89 55 14             	mov    %edx,0x14(%ebp)
f0104924:	8b 00                	mov    (%eax),%eax
f0104926:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104929:	89 c1                	mov    %eax,%ecx
f010492b:	c1 f9 1f             	sar    $0x1f,%ecx
f010492e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104931:	eb 16                	jmp    f0104949 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104933:	8b 45 14             	mov    0x14(%ebp),%eax
f0104936:	8d 50 04             	lea    0x4(%eax),%edx
f0104939:	89 55 14             	mov    %edx,0x14(%ebp)
f010493c:	8b 00                	mov    (%eax),%eax
f010493e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104941:	89 c1                	mov    %eax,%ecx
f0104943:	c1 f9 1f             	sar    $0x1f,%ecx
f0104946:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104949:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010494c:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010494f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104954:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104958:	79 74                	jns    f01049ce <vprintfmt+0x356>
				putch('-', putdat);
f010495a:	83 ec 08             	sub    $0x8,%esp
f010495d:	53                   	push   %ebx
f010495e:	6a 2d                	push   $0x2d
f0104960:	ff d6                	call   *%esi
				num = -(long long) num;
f0104962:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104965:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104968:	f7 d8                	neg    %eax
f010496a:	83 d2 00             	adc    $0x0,%edx
f010496d:	f7 da                	neg    %edx
f010496f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104972:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104977:	eb 55                	jmp    f01049ce <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104979:	8d 45 14             	lea    0x14(%ebp),%eax
f010497c:	e8 83 fc ff ff       	call   f0104604 <getuint>
			base = 10;
f0104981:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104986:	eb 46                	jmp    f01049ce <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104988:	8d 45 14             	lea    0x14(%ebp),%eax
f010498b:	e8 74 fc ff ff       	call   f0104604 <getuint>
			base = 8;
f0104990:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104995:	eb 37                	jmp    f01049ce <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104997:	83 ec 08             	sub    $0x8,%esp
f010499a:	53                   	push   %ebx
f010499b:	6a 30                	push   $0x30
f010499d:	ff d6                	call   *%esi
			putch('x', putdat);
f010499f:	83 c4 08             	add    $0x8,%esp
f01049a2:	53                   	push   %ebx
f01049a3:	6a 78                	push   $0x78
f01049a5:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01049a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01049aa:	8d 50 04             	lea    0x4(%eax),%edx
f01049ad:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01049b0:	8b 00                	mov    (%eax),%eax
f01049b2:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01049b7:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01049ba:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01049bf:	eb 0d                	jmp    f01049ce <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01049c1:	8d 45 14             	lea    0x14(%ebp),%eax
f01049c4:	e8 3b fc ff ff       	call   f0104604 <getuint>
			base = 16;
f01049c9:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01049ce:	83 ec 0c             	sub    $0xc,%esp
f01049d1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01049d5:	57                   	push   %edi
f01049d6:	ff 75 e0             	pushl  -0x20(%ebp)
f01049d9:	51                   	push   %ecx
f01049da:	52                   	push   %edx
f01049db:	50                   	push   %eax
f01049dc:	89 da                	mov    %ebx,%edx
f01049de:	89 f0                	mov    %esi,%eax
f01049e0:	e8 70 fb ff ff       	call   f0104555 <printnum>
			break;
f01049e5:	83 c4 20             	add    $0x20,%esp
f01049e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049eb:	e9 ae fc ff ff       	jmp    f010469e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01049f0:	83 ec 08             	sub    $0x8,%esp
f01049f3:	53                   	push   %ebx
f01049f4:	51                   	push   %ecx
f01049f5:	ff d6                	call   *%esi
			break;
f01049f7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01049fd:	e9 9c fc ff ff       	jmp    f010469e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104a02:	83 ec 08             	sub    $0x8,%esp
f0104a05:	53                   	push   %ebx
f0104a06:	6a 25                	push   $0x25
f0104a08:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104a0a:	83 c4 10             	add    $0x10,%esp
f0104a0d:	eb 03                	jmp    f0104a12 <vprintfmt+0x39a>
f0104a0f:	83 ef 01             	sub    $0x1,%edi
f0104a12:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104a16:	75 f7                	jne    f0104a0f <vprintfmt+0x397>
f0104a18:	e9 81 fc ff ff       	jmp    f010469e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104a1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a20:	5b                   	pop    %ebx
f0104a21:	5e                   	pop    %esi
f0104a22:	5f                   	pop    %edi
f0104a23:	5d                   	pop    %ebp
f0104a24:	c3                   	ret    

f0104a25 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a25:	55                   	push   %ebp
f0104a26:	89 e5                	mov    %esp,%ebp
f0104a28:	83 ec 18             	sub    $0x18,%esp
f0104a2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a31:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a34:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a38:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a42:	85 c0                	test   %eax,%eax
f0104a44:	74 26                	je     f0104a6c <vsnprintf+0x47>
f0104a46:	85 d2                	test   %edx,%edx
f0104a48:	7e 22                	jle    f0104a6c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a4a:	ff 75 14             	pushl  0x14(%ebp)
f0104a4d:	ff 75 10             	pushl  0x10(%ebp)
f0104a50:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a53:	50                   	push   %eax
f0104a54:	68 3e 46 10 f0       	push   $0xf010463e
f0104a59:	e8 1a fc ff ff       	call   f0104678 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a61:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a67:	83 c4 10             	add    $0x10,%esp
f0104a6a:	eb 05                	jmp    f0104a71 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104a6c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104a71:	c9                   	leave  
f0104a72:	c3                   	ret    

f0104a73 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a73:	55                   	push   %ebp
f0104a74:	89 e5                	mov    %esp,%ebp
f0104a76:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a79:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a7c:	50                   	push   %eax
f0104a7d:	ff 75 10             	pushl  0x10(%ebp)
f0104a80:	ff 75 0c             	pushl  0xc(%ebp)
f0104a83:	ff 75 08             	pushl  0x8(%ebp)
f0104a86:	e8 9a ff ff ff       	call   f0104a25 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a8b:	c9                   	leave  
f0104a8c:	c3                   	ret    

f0104a8d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104a8d:	55                   	push   %ebp
f0104a8e:	89 e5                	mov    %esp,%ebp
f0104a90:	57                   	push   %edi
f0104a91:	56                   	push   %esi
f0104a92:	53                   	push   %ebx
f0104a93:	83 ec 0c             	sub    $0xc,%esp
f0104a96:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104a99:	85 c0                	test   %eax,%eax
f0104a9b:	74 11                	je     f0104aae <readline+0x21>
		cprintf("%s", prompt);
f0104a9d:	83 ec 08             	sub    $0x8,%esp
f0104aa0:	50                   	push   %eax
f0104aa1:	68 1d 69 10 f0       	push   $0xf010691d
f0104aa6:	e8 ad eb ff ff       	call   f0103658 <cprintf>
f0104aab:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104aae:	83 ec 0c             	sub    $0xc,%esp
f0104ab1:	6a 00                	push   $0x0
f0104ab3:	e8 b5 bc ff ff       	call   f010076d <iscons>
f0104ab8:	89 c7                	mov    %eax,%edi
f0104aba:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104abd:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104ac2:	e8 95 bc ff ff       	call   f010075c <getchar>
f0104ac7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104ac9:	85 c0                	test   %eax,%eax
f0104acb:	79 18                	jns    f0104ae5 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104acd:	83 ec 08             	sub    $0x8,%esp
f0104ad0:	50                   	push   %eax
f0104ad1:	68 44 73 10 f0       	push   $0xf0107344
f0104ad6:	e8 7d eb ff ff       	call   f0103658 <cprintf>
			return NULL;
f0104adb:	83 c4 10             	add    $0x10,%esp
f0104ade:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ae3:	eb 79                	jmp    f0104b5e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104ae5:	83 f8 08             	cmp    $0x8,%eax
f0104ae8:	0f 94 c2             	sete   %dl
f0104aeb:	83 f8 7f             	cmp    $0x7f,%eax
f0104aee:	0f 94 c0             	sete   %al
f0104af1:	08 c2                	or     %al,%dl
f0104af3:	74 1a                	je     f0104b0f <readline+0x82>
f0104af5:	85 f6                	test   %esi,%esi
f0104af7:	7e 16                	jle    f0104b0f <readline+0x82>
			if (echoing)
f0104af9:	85 ff                	test   %edi,%edi
f0104afb:	74 0d                	je     f0104b0a <readline+0x7d>
				cputchar('\b');
f0104afd:	83 ec 0c             	sub    $0xc,%esp
f0104b00:	6a 08                	push   $0x8
f0104b02:	e8 45 bc ff ff       	call   f010074c <cputchar>
f0104b07:	83 c4 10             	add    $0x10,%esp
			i--;
f0104b0a:	83 ee 01             	sub    $0x1,%esi
f0104b0d:	eb b3                	jmp    f0104ac2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b0f:	83 fb 1f             	cmp    $0x1f,%ebx
f0104b12:	7e 23                	jle    f0104b37 <readline+0xaa>
f0104b14:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104b1a:	7f 1b                	jg     f0104b37 <readline+0xaa>
			if (echoing)
f0104b1c:	85 ff                	test   %edi,%edi
f0104b1e:	74 0c                	je     f0104b2c <readline+0x9f>
				cputchar(c);
f0104b20:	83 ec 0c             	sub    $0xc,%esp
f0104b23:	53                   	push   %ebx
f0104b24:	e8 23 bc ff ff       	call   f010074c <cputchar>
f0104b29:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104b2c:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104b32:	8d 76 01             	lea    0x1(%esi),%esi
f0104b35:	eb 8b                	jmp    f0104ac2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104b37:	83 fb 0a             	cmp    $0xa,%ebx
f0104b3a:	74 05                	je     f0104b41 <readline+0xb4>
f0104b3c:	83 fb 0d             	cmp    $0xd,%ebx
f0104b3f:	75 81                	jne    f0104ac2 <readline+0x35>
			if (echoing)
f0104b41:	85 ff                	test   %edi,%edi
f0104b43:	74 0d                	je     f0104b52 <readline+0xc5>
				cputchar('\n');
f0104b45:	83 ec 0c             	sub    $0xc,%esp
f0104b48:	6a 0a                	push   $0xa
f0104b4a:	e8 fd bb ff ff       	call   f010074c <cputchar>
f0104b4f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104b52:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104b59:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104b5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b61:	5b                   	pop    %ebx
f0104b62:	5e                   	pop    %esi
f0104b63:	5f                   	pop    %edi
f0104b64:	5d                   	pop    %ebp
f0104b65:	c3                   	ret    

f0104b66 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b66:	55                   	push   %ebp
f0104b67:	89 e5                	mov    %esp,%ebp
f0104b69:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b71:	eb 03                	jmp    f0104b76 <strlen+0x10>
		n++;
f0104b73:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b76:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104b7a:	75 f7                	jne    f0104b73 <strlen+0xd>
		n++;
	return n;
}
f0104b7c:	5d                   	pop    %ebp
f0104b7d:	c3                   	ret    

f0104b7e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104b7e:	55                   	push   %ebp
f0104b7f:	89 e5                	mov    %esp,%ebp
f0104b81:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b84:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b87:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b8c:	eb 03                	jmp    f0104b91 <strnlen+0x13>
		n++;
f0104b8e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b91:	39 c2                	cmp    %eax,%edx
f0104b93:	74 08                	je     f0104b9d <strnlen+0x1f>
f0104b95:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104b99:	75 f3                	jne    f0104b8e <strnlen+0x10>
f0104b9b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104b9d:	5d                   	pop    %ebp
f0104b9e:	c3                   	ret    

f0104b9f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104b9f:	55                   	push   %ebp
f0104ba0:	89 e5                	mov    %esp,%ebp
f0104ba2:	53                   	push   %ebx
f0104ba3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ba6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104ba9:	89 c2                	mov    %eax,%edx
f0104bab:	83 c2 01             	add    $0x1,%edx
f0104bae:	83 c1 01             	add    $0x1,%ecx
f0104bb1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104bb5:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104bb8:	84 db                	test   %bl,%bl
f0104bba:	75 ef                	jne    f0104bab <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104bbc:	5b                   	pop    %ebx
f0104bbd:	5d                   	pop    %ebp
f0104bbe:	c3                   	ret    

f0104bbf <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104bbf:	55                   	push   %ebp
f0104bc0:	89 e5                	mov    %esp,%ebp
f0104bc2:	53                   	push   %ebx
f0104bc3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104bc6:	53                   	push   %ebx
f0104bc7:	e8 9a ff ff ff       	call   f0104b66 <strlen>
f0104bcc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104bcf:	ff 75 0c             	pushl  0xc(%ebp)
f0104bd2:	01 d8                	add    %ebx,%eax
f0104bd4:	50                   	push   %eax
f0104bd5:	e8 c5 ff ff ff       	call   f0104b9f <strcpy>
	return dst;
}
f0104bda:	89 d8                	mov    %ebx,%eax
f0104bdc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104bdf:	c9                   	leave  
f0104be0:	c3                   	ret    

f0104be1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104be1:	55                   	push   %ebp
f0104be2:	89 e5                	mov    %esp,%ebp
f0104be4:	56                   	push   %esi
f0104be5:	53                   	push   %ebx
f0104be6:	8b 75 08             	mov    0x8(%ebp),%esi
f0104be9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bec:	89 f3                	mov    %esi,%ebx
f0104bee:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104bf1:	89 f2                	mov    %esi,%edx
f0104bf3:	eb 0f                	jmp    f0104c04 <strncpy+0x23>
		*dst++ = *src;
f0104bf5:	83 c2 01             	add    $0x1,%edx
f0104bf8:	0f b6 01             	movzbl (%ecx),%eax
f0104bfb:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104bfe:	80 39 01             	cmpb   $0x1,(%ecx)
f0104c01:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c04:	39 da                	cmp    %ebx,%edx
f0104c06:	75 ed                	jne    f0104bf5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104c08:	89 f0                	mov    %esi,%eax
f0104c0a:	5b                   	pop    %ebx
f0104c0b:	5e                   	pop    %esi
f0104c0c:	5d                   	pop    %ebp
f0104c0d:	c3                   	ret    

f0104c0e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104c0e:	55                   	push   %ebp
f0104c0f:	89 e5                	mov    %esp,%ebp
f0104c11:	56                   	push   %esi
f0104c12:	53                   	push   %ebx
f0104c13:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c16:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c19:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c1c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c1e:	85 d2                	test   %edx,%edx
f0104c20:	74 21                	je     f0104c43 <strlcpy+0x35>
f0104c22:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104c26:	89 f2                	mov    %esi,%edx
f0104c28:	eb 09                	jmp    f0104c33 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c2a:	83 c2 01             	add    $0x1,%edx
f0104c2d:	83 c1 01             	add    $0x1,%ecx
f0104c30:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104c33:	39 c2                	cmp    %eax,%edx
f0104c35:	74 09                	je     f0104c40 <strlcpy+0x32>
f0104c37:	0f b6 19             	movzbl (%ecx),%ebx
f0104c3a:	84 db                	test   %bl,%bl
f0104c3c:	75 ec                	jne    f0104c2a <strlcpy+0x1c>
f0104c3e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104c40:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104c43:	29 f0                	sub    %esi,%eax
}
f0104c45:	5b                   	pop    %ebx
f0104c46:	5e                   	pop    %esi
f0104c47:	5d                   	pop    %ebp
f0104c48:	c3                   	ret    

f0104c49 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c49:	55                   	push   %ebp
f0104c4a:	89 e5                	mov    %esp,%ebp
f0104c4c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c4f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c52:	eb 06                	jmp    f0104c5a <strcmp+0x11>
		p++, q++;
f0104c54:	83 c1 01             	add    $0x1,%ecx
f0104c57:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104c5a:	0f b6 01             	movzbl (%ecx),%eax
f0104c5d:	84 c0                	test   %al,%al
f0104c5f:	74 04                	je     f0104c65 <strcmp+0x1c>
f0104c61:	3a 02                	cmp    (%edx),%al
f0104c63:	74 ef                	je     f0104c54 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c65:	0f b6 c0             	movzbl %al,%eax
f0104c68:	0f b6 12             	movzbl (%edx),%edx
f0104c6b:	29 d0                	sub    %edx,%eax
}
f0104c6d:	5d                   	pop    %ebp
f0104c6e:	c3                   	ret    

f0104c6f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104c6f:	55                   	push   %ebp
f0104c70:	89 e5                	mov    %esp,%ebp
f0104c72:	53                   	push   %ebx
f0104c73:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c76:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c79:	89 c3                	mov    %eax,%ebx
f0104c7b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104c7e:	eb 06                	jmp    f0104c86 <strncmp+0x17>
		n--, p++, q++;
f0104c80:	83 c0 01             	add    $0x1,%eax
f0104c83:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104c86:	39 d8                	cmp    %ebx,%eax
f0104c88:	74 15                	je     f0104c9f <strncmp+0x30>
f0104c8a:	0f b6 08             	movzbl (%eax),%ecx
f0104c8d:	84 c9                	test   %cl,%cl
f0104c8f:	74 04                	je     f0104c95 <strncmp+0x26>
f0104c91:	3a 0a                	cmp    (%edx),%cl
f0104c93:	74 eb                	je     f0104c80 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c95:	0f b6 00             	movzbl (%eax),%eax
f0104c98:	0f b6 12             	movzbl (%edx),%edx
f0104c9b:	29 d0                	sub    %edx,%eax
f0104c9d:	eb 05                	jmp    f0104ca4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104c9f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104ca4:	5b                   	pop    %ebx
f0104ca5:	5d                   	pop    %ebp
f0104ca6:	c3                   	ret    

f0104ca7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104ca7:	55                   	push   %ebp
f0104ca8:	89 e5                	mov    %esp,%ebp
f0104caa:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cad:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cb1:	eb 07                	jmp    f0104cba <strchr+0x13>
		if (*s == c)
f0104cb3:	38 ca                	cmp    %cl,%dl
f0104cb5:	74 0f                	je     f0104cc6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104cb7:	83 c0 01             	add    $0x1,%eax
f0104cba:	0f b6 10             	movzbl (%eax),%edx
f0104cbd:	84 d2                	test   %dl,%dl
f0104cbf:	75 f2                	jne    f0104cb3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104cc1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cc6:	5d                   	pop    %ebp
f0104cc7:	c3                   	ret    

f0104cc8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104cc8:	55                   	push   %ebp
f0104cc9:	89 e5                	mov    %esp,%ebp
f0104ccb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cd2:	eb 03                	jmp    f0104cd7 <strfind+0xf>
f0104cd4:	83 c0 01             	add    $0x1,%eax
f0104cd7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104cda:	38 ca                	cmp    %cl,%dl
f0104cdc:	74 04                	je     f0104ce2 <strfind+0x1a>
f0104cde:	84 d2                	test   %dl,%dl
f0104ce0:	75 f2                	jne    f0104cd4 <strfind+0xc>
			break;
	return (char *) s;
}
f0104ce2:	5d                   	pop    %ebp
f0104ce3:	c3                   	ret    

f0104ce4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104ce4:	55                   	push   %ebp
f0104ce5:	89 e5                	mov    %esp,%ebp
f0104ce7:	57                   	push   %edi
f0104ce8:	56                   	push   %esi
f0104ce9:	53                   	push   %ebx
f0104cea:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104ced:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104cf0:	85 c9                	test   %ecx,%ecx
f0104cf2:	74 36                	je     f0104d2a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104cf4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104cfa:	75 28                	jne    f0104d24 <memset+0x40>
f0104cfc:	f6 c1 03             	test   $0x3,%cl
f0104cff:	75 23                	jne    f0104d24 <memset+0x40>
		c &= 0xFF;
f0104d01:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104d05:	89 d3                	mov    %edx,%ebx
f0104d07:	c1 e3 08             	shl    $0x8,%ebx
f0104d0a:	89 d6                	mov    %edx,%esi
f0104d0c:	c1 e6 18             	shl    $0x18,%esi
f0104d0f:	89 d0                	mov    %edx,%eax
f0104d11:	c1 e0 10             	shl    $0x10,%eax
f0104d14:	09 f0                	or     %esi,%eax
f0104d16:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104d18:	89 d8                	mov    %ebx,%eax
f0104d1a:	09 d0                	or     %edx,%eax
f0104d1c:	c1 e9 02             	shr    $0x2,%ecx
f0104d1f:	fc                   	cld    
f0104d20:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d22:	eb 06                	jmp    f0104d2a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d27:	fc                   	cld    
f0104d28:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d2a:	89 f8                	mov    %edi,%eax
f0104d2c:	5b                   	pop    %ebx
f0104d2d:	5e                   	pop    %esi
f0104d2e:	5f                   	pop    %edi
f0104d2f:	5d                   	pop    %ebp
f0104d30:	c3                   	ret    

f0104d31 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d31:	55                   	push   %ebp
f0104d32:	89 e5                	mov    %esp,%ebp
f0104d34:	57                   	push   %edi
f0104d35:	56                   	push   %esi
f0104d36:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d39:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d3c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d3f:	39 c6                	cmp    %eax,%esi
f0104d41:	73 35                	jae    f0104d78 <memmove+0x47>
f0104d43:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d46:	39 d0                	cmp    %edx,%eax
f0104d48:	73 2e                	jae    f0104d78 <memmove+0x47>
		s += n;
		d += n;
f0104d4a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d4d:	89 d6                	mov    %edx,%esi
f0104d4f:	09 fe                	or     %edi,%esi
f0104d51:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104d57:	75 13                	jne    f0104d6c <memmove+0x3b>
f0104d59:	f6 c1 03             	test   $0x3,%cl
f0104d5c:	75 0e                	jne    f0104d6c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104d5e:	83 ef 04             	sub    $0x4,%edi
f0104d61:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d64:	c1 e9 02             	shr    $0x2,%ecx
f0104d67:	fd                   	std    
f0104d68:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d6a:	eb 09                	jmp    f0104d75 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104d6c:	83 ef 01             	sub    $0x1,%edi
f0104d6f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104d72:	fd                   	std    
f0104d73:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104d75:	fc                   	cld    
f0104d76:	eb 1d                	jmp    f0104d95 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d78:	89 f2                	mov    %esi,%edx
f0104d7a:	09 c2                	or     %eax,%edx
f0104d7c:	f6 c2 03             	test   $0x3,%dl
f0104d7f:	75 0f                	jne    f0104d90 <memmove+0x5f>
f0104d81:	f6 c1 03             	test   $0x3,%cl
f0104d84:	75 0a                	jne    f0104d90 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104d86:	c1 e9 02             	shr    $0x2,%ecx
f0104d89:	89 c7                	mov    %eax,%edi
f0104d8b:	fc                   	cld    
f0104d8c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d8e:	eb 05                	jmp    f0104d95 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104d90:	89 c7                	mov    %eax,%edi
f0104d92:	fc                   	cld    
f0104d93:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104d95:	5e                   	pop    %esi
f0104d96:	5f                   	pop    %edi
f0104d97:	5d                   	pop    %ebp
f0104d98:	c3                   	ret    

f0104d99 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104d99:	55                   	push   %ebp
f0104d9a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104d9c:	ff 75 10             	pushl  0x10(%ebp)
f0104d9f:	ff 75 0c             	pushl  0xc(%ebp)
f0104da2:	ff 75 08             	pushl  0x8(%ebp)
f0104da5:	e8 87 ff ff ff       	call   f0104d31 <memmove>
}
f0104daa:	c9                   	leave  
f0104dab:	c3                   	ret    

f0104dac <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104dac:	55                   	push   %ebp
f0104dad:	89 e5                	mov    %esp,%ebp
f0104daf:	56                   	push   %esi
f0104db0:	53                   	push   %ebx
f0104db1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104db4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104db7:	89 c6                	mov    %eax,%esi
f0104db9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104dbc:	eb 1a                	jmp    f0104dd8 <memcmp+0x2c>
		if (*s1 != *s2)
f0104dbe:	0f b6 08             	movzbl (%eax),%ecx
f0104dc1:	0f b6 1a             	movzbl (%edx),%ebx
f0104dc4:	38 d9                	cmp    %bl,%cl
f0104dc6:	74 0a                	je     f0104dd2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104dc8:	0f b6 c1             	movzbl %cl,%eax
f0104dcb:	0f b6 db             	movzbl %bl,%ebx
f0104dce:	29 d8                	sub    %ebx,%eax
f0104dd0:	eb 0f                	jmp    f0104de1 <memcmp+0x35>
		s1++, s2++;
f0104dd2:	83 c0 01             	add    $0x1,%eax
f0104dd5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104dd8:	39 f0                	cmp    %esi,%eax
f0104dda:	75 e2                	jne    f0104dbe <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104ddc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104de1:	5b                   	pop    %ebx
f0104de2:	5e                   	pop    %esi
f0104de3:	5d                   	pop    %ebp
f0104de4:	c3                   	ret    

f0104de5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104de5:	55                   	push   %ebp
f0104de6:	89 e5                	mov    %esp,%ebp
f0104de8:	53                   	push   %ebx
f0104de9:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104dec:	89 c1                	mov    %eax,%ecx
f0104dee:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104df1:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104df5:	eb 0a                	jmp    f0104e01 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104df7:	0f b6 10             	movzbl (%eax),%edx
f0104dfa:	39 da                	cmp    %ebx,%edx
f0104dfc:	74 07                	je     f0104e05 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104dfe:	83 c0 01             	add    $0x1,%eax
f0104e01:	39 c8                	cmp    %ecx,%eax
f0104e03:	72 f2                	jb     f0104df7 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104e05:	5b                   	pop    %ebx
f0104e06:	5d                   	pop    %ebp
f0104e07:	c3                   	ret    

f0104e08 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104e08:	55                   	push   %ebp
f0104e09:	89 e5                	mov    %esp,%ebp
f0104e0b:	57                   	push   %edi
f0104e0c:	56                   	push   %esi
f0104e0d:	53                   	push   %ebx
f0104e0e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e11:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e14:	eb 03                	jmp    f0104e19 <strtol+0x11>
		s++;
f0104e16:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e19:	0f b6 01             	movzbl (%ecx),%eax
f0104e1c:	3c 20                	cmp    $0x20,%al
f0104e1e:	74 f6                	je     f0104e16 <strtol+0xe>
f0104e20:	3c 09                	cmp    $0x9,%al
f0104e22:	74 f2                	je     f0104e16 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104e24:	3c 2b                	cmp    $0x2b,%al
f0104e26:	75 0a                	jne    f0104e32 <strtol+0x2a>
		s++;
f0104e28:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104e2b:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e30:	eb 11                	jmp    f0104e43 <strtol+0x3b>
f0104e32:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104e37:	3c 2d                	cmp    $0x2d,%al
f0104e39:	75 08                	jne    f0104e43 <strtol+0x3b>
		s++, neg = 1;
f0104e3b:	83 c1 01             	add    $0x1,%ecx
f0104e3e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e43:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e49:	75 15                	jne    f0104e60 <strtol+0x58>
f0104e4b:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e4e:	75 10                	jne    f0104e60 <strtol+0x58>
f0104e50:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104e54:	75 7c                	jne    f0104ed2 <strtol+0xca>
		s += 2, base = 16;
f0104e56:	83 c1 02             	add    $0x2,%ecx
f0104e59:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104e5e:	eb 16                	jmp    f0104e76 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104e60:	85 db                	test   %ebx,%ebx
f0104e62:	75 12                	jne    f0104e76 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e64:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e69:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e6c:	75 08                	jne    f0104e76 <strtol+0x6e>
		s++, base = 8;
f0104e6e:	83 c1 01             	add    $0x1,%ecx
f0104e71:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104e76:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e7b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e7e:	0f b6 11             	movzbl (%ecx),%edx
f0104e81:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104e84:	89 f3                	mov    %esi,%ebx
f0104e86:	80 fb 09             	cmp    $0x9,%bl
f0104e89:	77 08                	ja     f0104e93 <strtol+0x8b>
			dig = *s - '0';
f0104e8b:	0f be d2             	movsbl %dl,%edx
f0104e8e:	83 ea 30             	sub    $0x30,%edx
f0104e91:	eb 22                	jmp    f0104eb5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104e93:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104e96:	89 f3                	mov    %esi,%ebx
f0104e98:	80 fb 19             	cmp    $0x19,%bl
f0104e9b:	77 08                	ja     f0104ea5 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104e9d:	0f be d2             	movsbl %dl,%edx
f0104ea0:	83 ea 57             	sub    $0x57,%edx
f0104ea3:	eb 10                	jmp    f0104eb5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104ea5:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104ea8:	89 f3                	mov    %esi,%ebx
f0104eaa:	80 fb 19             	cmp    $0x19,%bl
f0104ead:	77 16                	ja     f0104ec5 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104eaf:	0f be d2             	movsbl %dl,%edx
f0104eb2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104eb5:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104eb8:	7d 0b                	jge    f0104ec5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104eba:	83 c1 01             	add    $0x1,%ecx
f0104ebd:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104ec1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104ec3:	eb b9                	jmp    f0104e7e <strtol+0x76>

	if (endptr)
f0104ec5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104ec9:	74 0d                	je     f0104ed8 <strtol+0xd0>
		*endptr = (char *) s;
f0104ecb:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ece:	89 0e                	mov    %ecx,(%esi)
f0104ed0:	eb 06                	jmp    f0104ed8 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104ed2:	85 db                	test   %ebx,%ebx
f0104ed4:	74 98                	je     f0104e6e <strtol+0x66>
f0104ed6:	eb 9e                	jmp    f0104e76 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104ed8:	89 c2                	mov    %eax,%edx
f0104eda:	f7 da                	neg    %edx
f0104edc:	85 ff                	test   %edi,%edi
f0104ede:	0f 45 c2             	cmovne %edx,%eax
}
f0104ee1:	5b                   	pop    %ebx
f0104ee2:	5e                   	pop    %esi
f0104ee3:	5f                   	pop    %edi
f0104ee4:	5d                   	pop    %ebp
f0104ee5:	c3                   	ret    
f0104ee6:	66 90                	xchg   %ax,%ax

f0104ee8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104ee8:	fa                   	cli    

	xorw    %ax, %ax
f0104ee9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104eeb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104eed:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104eef:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104ef1:	0f 01 16             	lgdtl  (%esi)
f0104ef4:	74 70                	je     f0104f66 <mpsearch1+0x3>
	movl    %cr0, %eax
f0104ef6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104ef9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104efd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104f00:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104f06:	08 00                	or     %al,(%eax)

f0104f08 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104f08:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104f0c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104f0e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104f10:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104f12:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104f16:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104f18:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104f1a:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104f1f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104f22:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104f25:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104f2a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104f2d:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104f33:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104f38:	b8 a7 01 10 f0       	mov    $0xf01001a7,%eax
	call    *%eax
f0104f3d:	ff d0                	call   *%eax

f0104f3f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104f3f:	eb fe                	jmp    f0104f3f <spin>
f0104f41:	8d 76 00             	lea    0x0(%esi),%esi

f0104f44 <gdt>:
	...
f0104f4c:	ff                   	(bad)  
f0104f4d:	ff 00                	incl   (%eax)
f0104f4f:	00 00                	add    %al,(%eax)
f0104f51:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104f58:	00                   	.byte 0x0
f0104f59:	92                   	xchg   %eax,%edx
f0104f5a:	cf                   	iret   
	...

f0104f5c <gdtdesc>:
f0104f5c:	17                   	pop    %ss
f0104f5d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104f62 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104f62:	90                   	nop

f0104f63 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104f63:	55                   	push   %ebp
f0104f64:	89 e5                	mov    %esp,%ebp
f0104f66:	57                   	push   %edi
f0104f67:	56                   	push   %esi
f0104f68:	53                   	push   %ebx
f0104f69:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f6c:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0104f72:	89 c3                	mov    %eax,%ebx
f0104f74:	c1 eb 0c             	shr    $0xc,%ebx
f0104f77:	39 cb                	cmp    %ecx,%ebx
f0104f79:	72 12                	jb     f0104f8d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f7b:	50                   	push   %eax
f0104f7c:	68 c4 59 10 f0       	push   $0xf01059c4
f0104f81:	6a 57                	push   $0x57
f0104f83:	68 e1 74 10 f0       	push   $0xf01074e1
f0104f88:	e8 b3 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f8d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104f93:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f95:	89 c2                	mov    %eax,%edx
f0104f97:	c1 ea 0c             	shr    $0xc,%edx
f0104f9a:	39 ca                	cmp    %ecx,%edx
f0104f9c:	72 12                	jb     f0104fb0 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f9e:	50                   	push   %eax
f0104f9f:	68 c4 59 10 f0       	push   $0xf01059c4
f0104fa4:	6a 57                	push   $0x57
f0104fa6:	68 e1 74 10 f0       	push   $0xf01074e1
f0104fab:	e8 90 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104fb0:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104fb6:	eb 2f                	jmp    f0104fe7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fb8:	83 ec 04             	sub    $0x4,%esp
f0104fbb:	6a 04                	push   $0x4
f0104fbd:	68 f1 74 10 f0       	push   $0xf01074f1
f0104fc2:	53                   	push   %ebx
f0104fc3:	e8 e4 fd ff ff       	call   f0104dac <memcmp>
f0104fc8:	83 c4 10             	add    $0x10,%esp
f0104fcb:	85 c0                	test   %eax,%eax
f0104fcd:	75 15                	jne    f0104fe4 <mpsearch1+0x81>
f0104fcf:	89 da                	mov    %ebx,%edx
f0104fd1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104fd4:	0f b6 0a             	movzbl (%edx),%ecx
f0104fd7:	01 c8                	add    %ecx,%eax
f0104fd9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104fdc:	39 d7                	cmp    %edx,%edi
f0104fde:	75 f4                	jne    f0104fd4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fe0:	84 c0                	test   %al,%al
f0104fe2:	74 0e                	je     f0104ff2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104fe4:	83 c3 10             	add    $0x10,%ebx
f0104fe7:	39 f3                	cmp    %esi,%ebx
f0104fe9:	72 cd                	jb     f0104fb8 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104feb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ff0:	eb 02                	jmp    f0104ff4 <mpsearch1+0x91>
f0104ff2:	89 d8                	mov    %ebx,%eax
}
f0104ff4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ff7:	5b                   	pop    %ebx
f0104ff8:	5e                   	pop    %esi
f0104ff9:	5f                   	pop    %edi
f0104ffa:	5d                   	pop    %ebp
f0104ffb:	c3                   	ret    

f0104ffc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104ffc:	55                   	push   %ebp
f0104ffd:	89 e5                	mov    %esp,%ebp
f0104fff:	57                   	push   %edi
f0105000:	56                   	push   %esi
f0105001:	53                   	push   %ebx
f0105002:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105005:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f010500c:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010500f:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0105016:	75 16                	jne    f010502e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105018:	68 00 04 00 00       	push   $0x400
f010501d:	68 c4 59 10 f0       	push   $0xf01059c4
f0105022:	6a 6f                	push   $0x6f
f0105024:	68 e1 74 10 f0       	push   $0xf01074e1
f0105029:	e8 12 b0 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010502e:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105035:	85 c0                	test   %eax,%eax
f0105037:	74 16                	je     f010504f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105039:	c1 e0 04             	shl    $0x4,%eax
f010503c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105041:	e8 1d ff ff ff       	call   f0104f63 <mpsearch1>
f0105046:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105049:	85 c0                	test   %eax,%eax
f010504b:	75 3c                	jne    f0105089 <mp_init+0x8d>
f010504d:	eb 20                	jmp    f010506f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010504f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105056:	c1 e0 0a             	shl    $0xa,%eax
f0105059:	2d 00 04 00 00       	sub    $0x400,%eax
f010505e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105063:	e8 fb fe ff ff       	call   f0104f63 <mpsearch1>
f0105068:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010506b:	85 c0                	test   %eax,%eax
f010506d:	75 1a                	jne    f0105089 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010506f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105074:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105079:	e8 e5 fe ff ff       	call   f0104f63 <mpsearch1>
f010507e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105081:	85 c0                	test   %eax,%eax
f0105083:	0f 84 5d 02 00 00    	je     f01052e6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105089:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010508c:	8b 70 04             	mov    0x4(%eax),%esi
f010508f:	85 f6                	test   %esi,%esi
f0105091:	74 06                	je     f0105099 <mp_init+0x9d>
f0105093:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105097:	74 15                	je     f01050ae <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105099:	83 ec 0c             	sub    $0xc,%esp
f010509c:	68 54 73 10 f0       	push   $0xf0107354
f01050a1:	e8 b2 e5 ff ff       	call   f0103658 <cprintf>
f01050a6:	83 c4 10             	add    $0x10,%esp
f01050a9:	e9 38 02 00 00       	jmp    f01052e6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01050ae:	89 f0                	mov    %esi,%eax
f01050b0:	c1 e8 0c             	shr    $0xc,%eax
f01050b3:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01050b9:	72 15                	jb     f01050d0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01050bb:	56                   	push   %esi
f01050bc:	68 c4 59 10 f0       	push   $0xf01059c4
f01050c1:	68 90 00 00 00       	push   $0x90
f01050c6:	68 e1 74 10 f0       	push   $0xf01074e1
f01050cb:	e8 70 af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01050d0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01050d6:	83 ec 04             	sub    $0x4,%esp
f01050d9:	6a 04                	push   $0x4
f01050db:	68 f6 74 10 f0       	push   $0xf01074f6
f01050e0:	53                   	push   %ebx
f01050e1:	e8 c6 fc ff ff       	call   f0104dac <memcmp>
f01050e6:	83 c4 10             	add    $0x10,%esp
f01050e9:	85 c0                	test   %eax,%eax
f01050eb:	74 15                	je     f0105102 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01050ed:	83 ec 0c             	sub    $0xc,%esp
f01050f0:	68 84 73 10 f0       	push   $0xf0107384
f01050f5:	e8 5e e5 ff ff       	call   f0103658 <cprintf>
f01050fa:	83 c4 10             	add    $0x10,%esp
f01050fd:	e9 e4 01 00 00       	jmp    f01052e6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105102:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105106:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010510a:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f010510d:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105112:	b8 00 00 00 00       	mov    $0x0,%eax
f0105117:	eb 0d                	jmp    f0105126 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105119:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105120:	f0 
f0105121:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105123:	83 c0 01             	add    $0x1,%eax
f0105126:	39 c7                	cmp    %eax,%edi
f0105128:	75 ef                	jne    f0105119 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010512a:	84 d2                	test   %dl,%dl
f010512c:	74 15                	je     f0105143 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010512e:	83 ec 0c             	sub    $0xc,%esp
f0105131:	68 b8 73 10 f0       	push   $0xf01073b8
f0105136:	e8 1d e5 ff ff       	call   f0103658 <cprintf>
f010513b:	83 c4 10             	add    $0x10,%esp
f010513e:	e9 a3 01 00 00       	jmp    f01052e6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105143:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105147:	3c 01                	cmp    $0x1,%al
f0105149:	74 1d                	je     f0105168 <mp_init+0x16c>
f010514b:	3c 04                	cmp    $0x4,%al
f010514d:	74 19                	je     f0105168 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010514f:	83 ec 08             	sub    $0x8,%esp
f0105152:	0f b6 c0             	movzbl %al,%eax
f0105155:	50                   	push   %eax
f0105156:	68 dc 73 10 f0       	push   $0xf01073dc
f010515b:	e8 f8 e4 ff ff       	call   f0103658 <cprintf>
f0105160:	83 c4 10             	add    $0x10,%esp
f0105163:	e9 7e 01 00 00       	jmp    f01052e6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105168:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010516c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105170:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105175:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010517a:	01 ce                	add    %ecx,%esi
f010517c:	eb 0d                	jmp    f010518b <mp_init+0x18f>
f010517e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105185:	f0 
f0105186:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105188:	83 c0 01             	add    $0x1,%eax
f010518b:	39 c7                	cmp    %eax,%edi
f010518d:	75 ef                	jne    f010517e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010518f:	89 d0                	mov    %edx,%eax
f0105191:	02 43 2a             	add    0x2a(%ebx),%al
f0105194:	74 15                	je     f01051ab <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105196:	83 ec 0c             	sub    $0xc,%esp
f0105199:	68 fc 73 10 f0       	push   $0xf01073fc
f010519e:	e8 b5 e4 ff ff       	call   f0103658 <cprintf>
f01051a3:	83 c4 10             	add    $0x10,%esp
f01051a6:	e9 3b 01 00 00       	jmp    f01052e6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01051ab:	85 db                	test   %ebx,%ebx
f01051ad:	0f 84 33 01 00 00    	je     f01052e6 <mp_init+0x2ea>
		return;
	ismp = 1;
f01051b3:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f01051ba:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01051bd:	8b 43 24             	mov    0x24(%ebx),%eax
f01051c0:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01051c5:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01051c8:	be 00 00 00 00       	mov    $0x0,%esi
f01051cd:	e9 85 00 00 00       	jmp    f0105257 <mp_init+0x25b>
		switch (*p) {
f01051d2:	0f b6 07             	movzbl (%edi),%eax
f01051d5:	84 c0                	test   %al,%al
f01051d7:	74 06                	je     f01051df <mp_init+0x1e3>
f01051d9:	3c 04                	cmp    $0x4,%al
f01051db:	77 55                	ja     f0105232 <mp_init+0x236>
f01051dd:	eb 4e                	jmp    f010522d <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01051df:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01051e3:	74 11                	je     f01051f6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01051e5:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01051ec:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01051f1:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f01051f6:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f01051fb:	83 f8 07             	cmp    $0x7,%eax
f01051fe:	7f 13                	jg     f0105213 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105200:	6b d0 74             	imul   $0x74,%eax,%edx
f0105203:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f0105209:	83 c0 01             	add    $0x1,%eax
f010520c:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f0105211:	eb 15                	jmp    f0105228 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105213:	83 ec 08             	sub    $0x8,%esp
f0105216:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010521a:	50                   	push   %eax
f010521b:	68 2c 74 10 f0       	push   $0xf010742c
f0105220:	e8 33 e4 ff ff       	call   f0103658 <cprintf>
f0105225:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105228:	83 c7 14             	add    $0x14,%edi
			continue;
f010522b:	eb 27                	jmp    f0105254 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010522d:	83 c7 08             	add    $0x8,%edi
			continue;
f0105230:	eb 22                	jmp    f0105254 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105232:	83 ec 08             	sub    $0x8,%esp
f0105235:	0f b6 c0             	movzbl %al,%eax
f0105238:	50                   	push   %eax
f0105239:	68 54 74 10 f0       	push   $0xf0107454
f010523e:	e8 15 e4 ff ff       	call   f0103658 <cprintf>
			ismp = 0;
f0105243:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f010524a:	00 00 00 
			i = conf->entry;
f010524d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105251:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105254:	83 c6 01             	add    $0x1,%esi
f0105257:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010525b:	39 c6                	cmp    %eax,%esi
f010525d:	0f 82 6f ff ff ff    	jb     f01051d2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105263:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105268:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010526f:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f0105276:	75 26                	jne    f010529e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105278:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f010527f:	00 00 00 
		lapicaddr = 0;
f0105282:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f0105289:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010528c:	83 ec 0c             	sub    $0xc,%esp
f010528f:	68 74 74 10 f0       	push   $0xf0107474
f0105294:	e8 bf e3 ff ff       	call   f0103658 <cprintf>
		return;
f0105299:	83 c4 10             	add    $0x10,%esp
f010529c:	eb 48                	jmp    f01052e6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010529e:	83 ec 04             	sub    $0x4,%esp
f01052a1:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f01052a7:	0f b6 00             	movzbl (%eax),%eax
f01052aa:	50                   	push   %eax
f01052ab:	68 fb 74 10 f0       	push   $0xf01074fb
f01052b0:	e8 a3 e3 ff ff       	call   f0103658 <cprintf>

	if (mp->imcrp) {
f01052b5:	83 c4 10             	add    $0x10,%esp
f01052b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01052bb:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01052bf:	74 25                	je     f01052e6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01052c1:	83 ec 0c             	sub    $0xc,%esp
f01052c4:	68 a0 74 10 f0       	push   $0xf01074a0
f01052c9:	e8 8a e3 ff ff       	call   f0103658 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052ce:	ba 22 00 00 00       	mov    $0x22,%edx
f01052d3:	b8 70 00 00 00       	mov    $0x70,%eax
f01052d8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01052d9:	ba 23 00 00 00       	mov    $0x23,%edx
f01052de:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052df:	83 c8 01             	or     $0x1,%eax
f01052e2:	ee                   	out    %al,(%dx)
f01052e3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01052e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052e9:	5b                   	pop    %ebx
f01052ea:	5e                   	pop    %esi
f01052eb:	5f                   	pop    %edi
f01052ec:	5d                   	pop    %ebp
f01052ed:	c3                   	ret    

f01052ee <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01052ee:	55                   	push   %ebp
f01052ef:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01052f1:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f01052f7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01052fa:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01052fc:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105301:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105304:	5d                   	pop    %ebp
f0105305:	c3                   	ret    

f0105306 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105306:	55                   	push   %ebp
f0105307:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105309:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f010530e:	85 c0                	test   %eax,%eax
f0105310:	74 08                	je     f010531a <cpunum+0x14>
		return lapic[ID] >> 24;
f0105312:	8b 40 20             	mov    0x20(%eax),%eax
f0105315:	c1 e8 18             	shr    $0x18,%eax
f0105318:	eb 05                	jmp    f010531f <cpunum+0x19>
	return 0;
f010531a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010531f:	5d                   	pop    %ebp
f0105320:	c3                   	ret    

f0105321 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105321:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f0105326:	85 c0                	test   %eax,%eax
f0105328:	0f 84 21 01 00 00    	je     f010544f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010532e:	55                   	push   %ebp
f010532f:	89 e5                	mov    %esp,%ebp
f0105331:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105334:	68 00 10 00 00       	push   $0x1000
f0105339:	50                   	push   %eax
f010533a:	e8 cb bf ff ff       	call   f010130a <mmio_map_region>
f010533f:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105344:	ba 27 01 00 00       	mov    $0x127,%edx
f0105349:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010534e:	e8 9b ff ff ff       	call   f01052ee <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105353:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105358:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010535d:	e8 8c ff ff ff       	call   f01052ee <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105362:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105367:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010536c:	e8 7d ff ff ff       	call   f01052ee <lapicw>
	lapicw(TICR, 10000000); 
f0105371:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105376:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010537b:	e8 6e ff ff ff       	call   f01052ee <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105380:	e8 81 ff ff ff       	call   f0105306 <cpunum>
f0105385:	6b c0 74             	imul   $0x74,%eax,%eax
f0105388:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010538d:	83 c4 10             	add    $0x10,%esp
f0105390:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f0105396:	74 0f                	je     f01053a7 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105398:	ba 00 00 01 00       	mov    $0x10000,%edx
f010539d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01053a2:	e8 47 ff ff ff       	call   f01052ee <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01053a7:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053ac:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01053b1:	e8 38 ff ff ff       	call   f01052ee <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01053b6:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01053bb:	8b 40 30             	mov    0x30(%eax),%eax
f01053be:	c1 e8 10             	shr    $0x10,%eax
f01053c1:	3c 03                	cmp    $0x3,%al
f01053c3:	76 0f                	jbe    f01053d4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01053c5:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053ca:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01053cf:	e8 1a ff ff ff       	call   f01052ee <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01053d4:	ba 33 00 00 00       	mov    $0x33,%edx
f01053d9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01053de:	e8 0b ff ff ff       	call   f01052ee <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01053e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01053e8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053ed:	e8 fc fe ff ff       	call   f01052ee <lapicw>
	lapicw(ESR, 0);
f01053f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01053f7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053fc:	e8 ed fe ff ff       	call   f01052ee <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105401:	ba 00 00 00 00       	mov    $0x0,%edx
f0105406:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010540b:	e8 de fe ff ff       	call   f01052ee <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105410:	ba 00 00 00 00       	mov    $0x0,%edx
f0105415:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010541a:	e8 cf fe ff ff       	call   f01052ee <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f010541f:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105424:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105429:	e8 c0 fe ff ff       	call   f01052ee <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010542e:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105434:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010543a:	f6 c4 10             	test   $0x10,%ah
f010543d:	75 f5                	jne    f0105434 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010543f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105444:	b8 20 00 00 00       	mov    $0x20,%eax
f0105449:	e8 a0 fe ff ff       	call   f01052ee <lapicw>
}
f010544e:	c9                   	leave  
f010544f:	f3 c3                	repz ret 

f0105451 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105451:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105458:	74 13                	je     f010546d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010545a:	55                   	push   %ebp
f010545b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010545d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105462:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105467:	e8 82 fe ff ff       	call   f01052ee <lapicw>
}
f010546c:	5d                   	pop    %ebp
f010546d:	f3 c3                	repz ret 

f010546f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010546f:	55                   	push   %ebp
f0105470:	89 e5                	mov    %esp,%ebp
f0105472:	56                   	push   %esi
f0105473:	53                   	push   %ebx
f0105474:	8b 75 08             	mov    0x8(%ebp),%esi
f0105477:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010547a:	ba 70 00 00 00       	mov    $0x70,%edx
f010547f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105484:	ee                   	out    %al,(%dx)
f0105485:	ba 71 00 00 00       	mov    $0x71,%edx
f010548a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010548f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105490:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0105497:	75 19                	jne    f01054b2 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105499:	68 67 04 00 00       	push   $0x467
f010549e:	68 c4 59 10 f0       	push   $0xf01059c4
f01054a3:	68 98 00 00 00       	push   $0x98
f01054a8:	68 18 75 10 f0       	push   $0xf0107518
f01054ad:	e8 8e ab ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01054b2:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01054b9:	00 00 
	wrv[1] = addr >> 4;
f01054bb:	89 d8                	mov    %ebx,%eax
f01054bd:	c1 e8 04             	shr    $0x4,%eax
f01054c0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01054c6:	c1 e6 18             	shl    $0x18,%esi
f01054c9:	89 f2                	mov    %esi,%edx
f01054cb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054d0:	e8 19 fe ff ff       	call   f01052ee <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01054d5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01054da:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054df:	e8 0a fe ff ff       	call   f01052ee <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01054e4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01054e9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054ee:	e8 fb fd ff ff       	call   f01052ee <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054f3:	c1 eb 0c             	shr    $0xc,%ebx
f01054f6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054f9:	89 f2                	mov    %esi,%edx
f01054fb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105500:	e8 e9 fd ff ff       	call   f01052ee <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105505:	89 da                	mov    %ebx,%edx
f0105507:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010550c:	e8 dd fd ff ff       	call   f01052ee <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105511:	89 f2                	mov    %esi,%edx
f0105513:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105518:	e8 d1 fd ff ff       	call   f01052ee <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010551d:	89 da                	mov    %ebx,%edx
f010551f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105524:	e8 c5 fd ff ff       	call   f01052ee <lapicw>
		microdelay(200);
	}
}
f0105529:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010552c:	5b                   	pop    %ebx
f010552d:	5e                   	pop    %esi
f010552e:	5d                   	pop    %ebp
f010552f:	c3                   	ret    

f0105530 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105530:	55                   	push   %ebp
f0105531:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105533:	8b 55 08             	mov    0x8(%ebp),%edx
f0105536:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010553c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105541:	e8 a8 fd ff ff       	call   f01052ee <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105546:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f010554c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105552:	f6 c4 10             	test   $0x10,%ah
f0105555:	75 f5                	jne    f010554c <lapic_ipi+0x1c>
		;
}
f0105557:	5d                   	pop    %ebp
f0105558:	c3                   	ret    

f0105559 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105559:	55                   	push   %ebp
f010555a:	89 e5                	mov    %esp,%ebp
f010555c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f010555f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105565:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105568:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010556b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105572:	5d                   	pop    %ebp
f0105573:	c3                   	ret    

f0105574 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105574:	55                   	push   %ebp
f0105575:	89 e5                	mov    %esp,%ebp
f0105577:	56                   	push   %esi
f0105578:	53                   	push   %ebx
f0105579:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010557c:	83 3b 00             	cmpl   $0x0,(%ebx)
f010557f:	74 14                	je     f0105595 <spin_lock+0x21>
f0105581:	8b 73 08             	mov    0x8(%ebx),%esi
f0105584:	e8 7d fd ff ff       	call   f0105306 <cpunum>
f0105589:	6b c0 74             	imul   $0x74,%eax,%eax
f010558c:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105591:	39 c6                	cmp    %eax,%esi
f0105593:	74 07                	je     f010559c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105595:	ba 01 00 00 00       	mov    $0x1,%edx
f010559a:	eb 20                	jmp    f01055bc <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f010559c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010559f:	e8 62 fd ff ff       	call   f0105306 <cpunum>
f01055a4:	83 ec 0c             	sub    $0xc,%esp
f01055a7:	53                   	push   %ebx
f01055a8:	50                   	push   %eax
f01055a9:	68 28 75 10 f0       	push   $0xf0107528
f01055ae:	6a 41                	push   $0x41
f01055b0:	68 8c 75 10 f0       	push   $0xf010758c
f01055b5:	e8 86 aa ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01055ba:	f3 90                	pause  
f01055bc:	89 d0                	mov    %edx,%eax
f01055be:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01055c1:	85 c0                	test   %eax,%eax
f01055c3:	75 f5                	jne    f01055ba <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01055c5:	e8 3c fd ff ff       	call   f0105306 <cpunum>
f01055ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01055cd:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01055d2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01055d5:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01055d8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055da:	b8 00 00 00 00       	mov    $0x0,%eax
f01055df:	eb 0b                	jmp    f01055ec <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01055e1:	8b 4a 04             	mov    0x4(%edx),%ecx
f01055e4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01055e7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055e9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01055ec:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01055f2:	76 11                	jbe    f0105605 <spin_lock+0x91>
f01055f4:	83 f8 09             	cmp    $0x9,%eax
f01055f7:	7e e8                	jle    f01055e1 <spin_lock+0x6d>
f01055f9:	eb 0a                	jmp    f0105605 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01055fb:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105602:	83 c0 01             	add    $0x1,%eax
f0105605:	83 f8 09             	cmp    $0x9,%eax
f0105608:	7e f1                	jle    f01055fb <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010560a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010560d:	5b                   	pop    %ebx
f010560e:	5e                   	pop    %esi
f010560f:	5d                   	pop    %ebp
f0105610:	c3                   	ret    

f0105611 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105611:	55                   	push   %ebp
f0105612:	89 e5                	mov    %esp,%ebp
f0105614:	57                   	push   %edi
f0105615:	56                   	push   %esi
f0105616:	53                   	push   %ebx
f0105617:	83 ec 4c             	sub    $0x4c,%esp
f010561a:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010561d:	83 3e 00             	cmpl   $0x0,(%esi)
f0105620:	74 18                	je     f010563a <spin_unlock+0x29>
f0105622:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105625:	e8 dc fc ff ff       	call   f0105306 <cpunum>
f010562a:	6b c0 74             	imul   $0x74,%eax,%eax
f010562d:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105632:	39 c3                	cmp    %eax,%ebx
f0105634:	0f 84 a5 00 00 00    	je     f01056df <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010563a:	83 ec 04             	sub    $0x4,%esp
f010563d:	6a 28                	push   $0x28
f010563f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105642:	50                   	push   %eax
f0105643:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105646:	53                   	push   %ebx
f0105647:	e8 e5 f6 ff ff       	call   f0104d31 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010564c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010564f:	0f b6 38             	movzbl (%eax),%edi
f0105652:	8b 76 04             	mov    0x4(%esi),%esi
f0105655:	e8 ac fc ff ff       	call   f0105306 <cpunum>
f010565a:	57                   	push   %edi
f010565b:	56                   	push   %esi
f010565c:	50                   	push   %eax
f010565d:	68 54 75 10 f0       	push   $0xf0107554
f0105662:	e8 f1 df ff ff       	call   f0103658 <cprintf>
f0105667:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010566a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010566d:	eb 54                	jmp    f01056c3 <spin_unlock+0xb2>
f010566f:	83 ec 08             	sub    $0x8,%esp
f0105672:	57                   	push   %edi
f0105673:	50                   	push   %eax
f0105674:	e8 f9 eb ff ff       	call   f0104272 <debuginfo_eip>
f0105679:	83 c4 10             	add    $0x10,%esp
f010567c:	85 c0                	test   %eax,%eax
f010567e:	78 27                	js     f01056a7 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105680:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105682:	83 ec 04             	sub    $0x4,%esp
f0105685:	89 c2                	mov    %eax,%edx
f0105687:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010568a:	52                   	push   %edx
f010568b:	ff 75 b0             	pushl  -0x50(%ebp)
f010568e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105691:	ff 75 ac             	pushl  -0x54(%ebp)
f0105694:	ff 75 a8             	pushl  -0x58(%ebp)
f0105697:	50                   	push   %eax
f0105698:	68 9c 75 10 f0       	push   $0xf010759c
f010569d:	e8 b6 df ff ff       	call   f0103658 <cprintf>
f01056a2:	83 c4 20             	add    $0x20,%esp
f01056a5:	eb 12                	jmp    f01056b9 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01056a7:	83 ec 08             	sub    $0x8,%esp
f01056aa:	ff 36                	pushl  (%esi)
f01056ac:	68 b3 75 10 f0       	push   $0xf01075b3
f01056b1:	e8 a2 df ff ff       	call   f0103658 <cprintf>
f01056b6:	83 c4 10             	add    $0x10,%esp
f01056b9:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01056bc:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01056bf:	39 c3                	cmp    %eax,%ebx
f01056c1:	74 08                	je     f01056cb <spin_unlock+0xba>
f01056c3:	89 de                	mov    %ebx,%esi
f01056c5:	8b 03                	mov    (%ebx),%eax
f01056c7:	85 c0                	test   %eax,%eax
f01056c9:	75 a4                	jne    f010566f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01056cb:	83 ec 04             	sub    $0x4,%esp
f01056ce:	68 bb 75 10 f0       	push   $0xf01075bb
f01056d3:	6a 67                	push   $0x67
f01056d5:	68 8c 75 10 f0       	push   $0xf010758c
f01056da:	e8 61 a9 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01056df:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01056e6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01056ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01056f2:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f01056f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056f8:	5b                   	pop    %ebx
f01056f9:	5e                   	pop    %esi
f01056fa:	5f                   	pop    %edi
f01056fb:	5d                   	pop    %ebp
f01056fc:	c3                   	ret    
f01056fd:	66 90                	xchg   %ax,%ax
f01056ff:	90                   	nop

f0105700 <__udivdi3>:
f0105700:	55                   	push   %ebp
f0105701:	57                   	push   %edi
f0105702:	56                   	push   %esi
f0105703:	53                   	push   %ebx
f0105704:	83 ec 1c             	sub    $0x1c,%esp
f0105707:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010570b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010570f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105713:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105717:	85 f6                	test   %esi,%esi
f0105719:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010571d:	89 ca                	mov    %ecx,%edx
f010571f:	89 f8                	mov    %edi,%eax
f0105721:	75 3d                	jne    f0105760 <__udivdi3+0x60>
f0105723:	39 cf                	cmp    %ecx,%edi
f0105725:	0f 87 c5 00 00 00    	ja     f01057f0 <__udivdi3+0xf0>
f010572b:	85 ff                	test   %edi,%edi
f010572d:	89 fd                	mov    %edi,%ebp
f010572f:	75 0b                	jne    f010573c <__udivdi3+0x3c>
f0105731:	b8 01 00 00 00       	mov    $0x1,%eax
f0105736:	31 d2                	xor    %edx,%edx
f0105738:	f7 f7                	div    %edi
f010573a:	89 c5                	mov    %eax,%ebp
f010573c:	89 c8                	mov    %ecx,%eax
f010573e:	31 d2                	xor    %edx,%edx
f0105740:	f7 f5                	div    %ebp
f0105742:	89 c1                	mov    %eax,%ecx
f0105744:	89 d8                	mov    %ebx,%eax
f0105746:	89 cf                	mov    %ecx,%edi
f0105748:	f7 f5                	div    %ebp
f010574a:	89 c3                	mov    %eax,%ebx
f010574c:	89 d8                	mov    %ebx,%eax
f010574e:	89 fa                	mov    %edi,%edx
f0105750:	83 c4 1c             	add    $0x1c,%esp
f0105753:	5b                   	pop    %ebx
f0105754:	5e                   	pop    %esi
f0105755:	5f                   	pop    %edi
f0105756:	5d                   	pop    %ebp
f0105757:	c3                   	ret    
f0105758:	90                   	nop
f0105759:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105760:	39 ce                	cmp    %ecx,%esi
f0105762:	77 74                	ja     f01057d8 <__udivdi3+0xd8>
f0105764:	0f bd fe             	bsr    %esi,%edi
f0105767:	83 f7 1f             	xor    $0x1f,%edi
f010576a:	0f 84 98 00 00 00    	je     f0105808 <__udivdi3+0x108>
f0105770:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105775:	89 f9                	mov    %edi,%ecx
f0105777:	89 c5                	mov    %eax,%ebp
f0105779:	29 fb                	sub    %edi,%ebx
f010577b:	d3 e6                	shl    %cl,%esi
f010577d:	89 d9                	mov    %ebx,%ecx
f010577f:	d3 ed                	shr    %cl,%ebp
f0105781:	89 f9                	mov    %edi,%ecx
f0105783:	d3 e0                	shl    %cl,%eax
f0105785:	09 ee                	or     %ebp,%esi
f0105787:	89 d9                	mov    %ebx,%ecx
f0105789:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010578d:	89 d5                	mov    %edx,%ebp
f010578f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105793:	d3 ed                	shr    %cl,%ebp
f0105795:	89 f9                	mov    %edi,%ecx
f0105797:	d3 e2                	shl    %cl,%edx
f0105799:	89 d9                	mov    %ebx,%ecx
f010579b:	d3 e8                	shr    %cl,%eax
f010579d:	09 c2                	or     %eax,%edx
f010579f:	89 d0                	mov    %edx,%eax
f01057a1:	89 ea                	mov    %ebp,%edx
f01057a3:	f7 f6                	div    %esi
f01057a5:	89 d5                	mov    %edx,%ebp
f01057a7:	89 c3                	mov    %eax,%ebx
f01057a9:	f7 64 24 0c          	mull   0xc(%esp)
f01057ad:	39 d5                	cmp    %edx,%ebp
f01057af:	72 10                	jb     f01057c1 <__udivdi3+0xc1>
f01057b1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01057b5:	89 f9                	mov    %edi,%ecx
f01057b7:	d3 e6                	shl    %cl,%esi
f01057b9:	39 c6                	cmp    %eax,%esi
f01057bb:	73 07                	jae    f01057c4 <__udivdi3+0xc4>
f01057bd:	39 d5                	cmp    %edx,%ebp
f01057bf:	75 03                	jne    f01057c4 <__udivdi3+0xc4>
f01057c1:	83 eb 01             	sub    $0x1,%ebx
f01057c4:	31 ff                	xor    %edi,%edi
f01057c6:	89 d8                	mov    %ebx,%eax
f01057c8:	89 fa                	mov    %edi,%edx
f01057ca:	83 c4 1c             	add    $0x1c,%esp
f01057cd:	5b                   	pop    %ebx
f01057ce:	5e                   	pop    %esi
f01057cf:	5f                   	pop    %edi
f01057d0:	5d                   	pop    %ebp
f01057d1:	c3                   	ret    
f01057d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01057d8:	31 ff                	xor    %edi,%edi
f01057da:	31 db                	xor    %ebx,%ebx
f01057dc:	89 d8                	mov    %ebx,%eax
f01057de:	89 fa                	mov    %edi,%edx
f01057e0:	83 c4 1c             	add    $0x1c,%esp
f01057e3:	5b                   	pop    %ebx
f01057e4:	5e                   	pop    %esi
f01057e5:	5f                   	pop    %edi
f01057e6:	5d                   	pop    %ebp
f01057e7:	c3                   	ret    
f01057e8:	90                   	nop
f01057e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057f0:	89 d8                	mov    %ebx,%eax
f01057f2:	f7 f7                	div    %edi
f01057f4:	31 ff                	xor    %edi,%edi
f01057f6:	89 c3                	mov    %eax,%ebx
f01057f8:	89 d8                	mov    %ebx,%eax
f01057fa:	89 fa                	mov    %edi,%edx
f01057fc:	83 c4 1c             	add    $0x1c,%esp
f01057ff:	5b                   	pop    %ebx
f0105800:	5e                   	pop    %esi
f0105801:	5f                   	pop    %edi
f0105802:	5d                   	pop    %ebp
f0105803:	c3                   	ret    
f0105804:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105808:	39 ce                	cmp    %ecx,%esi
f010580a:	72 0c                	jb     f0105818 <__udivdi3+0x118>
f010580c:	31 db                	xor    %ebx,%ebx
f010580e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105812:	0f 87 34 ff ff ff    	ja     f010574c <__udivdi3+0x4c>
f0105818:	bb 01 00 00 00       	mov    $0x1,%ebx
f010581d:	e9 2a ff ff ff       	jmp    f010574c <__udivdi3+0x4c>
f0105822:	66 90                	xchg   %ax,%ax
f0105824:	66 90                	xchg   %ax,%ax
f0105826:	66 90                	xchg   %ax,%ax
f0105828:	66 90                	xchg   %ax,%ax
f010582a:	66 90                	xchg   %ax,%ax
f010582c:	66 90                	xchg   %ax,%ax
f010582e:	66 90                	xchg   %ax,%ax

f0105830 <__umoddi3>:
f0105830:	55                   	push   %ebp
f0105831:	57                   	push   %edi
f0105832:	56                   	push   %esi
f0105833:	53                   	push   %ebx
f0105834:	83 ec 1c             	sub    $0x1c,%esp
f0105837:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010583b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010583f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105843:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105847:	85 d2                	test   %edx,%edx
f0105849:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010584d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105851:	89 f3                	mov    %esi,%ebx
f0105853:	89 3c 24             	mov    %edi,(%esp)
f0105856:	89 74 24 04          	mov    %esi,0x4(%esp)
f010585a:	75 1c                	jne    f0105878 <__umoddi3+0x48>
f010585c:	39 f7                	cmp    %esi,%edi
f010585e:	76 50                	jbe    f01058b0 <__umoddi3+0x80>
f0105860:	89 c8                	mov    %ecx,%eax
f0105862:	89 f2                	mov    %esi,%edx
f0105864:	f7 f7                	div    %edi
f0105866:	89 d0                	mov    %edx,%eax
f0105868:	31 d2                	xor    %edx,%edx
f010586a:	83 c4 1c             	add    $0x1c,%esp
f010586d:	5b                   	pop    %ebx
f010586e:	5e                   	pop    %esi
f010586f:	5f                   	pop    %edi
f0105870:	5d                   	pop    %ebp
f0105871:	c3                   	ret    
f0105872:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105878:	39 f2                	cmp    %esi,%edx
f010587a:	89 d0                	mov    %edx,%eax
f010587c:	77 52                	ja     f01058d0 <__umoddi3+0xa0>
f010587e:	0f bd ea             	bsr    %edx,%ebp
f0105881:	83 f5 1f             	xor    $0x1f,%ebp
f0105884:	75 5a                	jne    f01058e0 <__umoddi3+0xb0>
f0105886:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010588a:	0f 82 e0 00 00 00    	jb     f0105970 <__umoddi3+0x140>
f0105890:	39 0c 24             	cmp    %ecx,(%esp)
f0105893:	0f 86 d7 00 00 00    	jbe    f0105970 <__umoddi3+0x140>
f0105899:	8b 44 24 08          	mov    0x8(%esp),%eax
f010589d:	8b 54 24 04          	mov    0x4(%esp),%edx
f01058a1:	83 c4 1c             	add    $0x1c,%esp
f01058a4:	5b                   	pop    %ebx
f01058a5:	5e                   	pop    %esi
f01058a6:	5f                   	pop    %edi
f01058a7:	5d                   	pop    %ebp
f01058a8:	c3                   	ret    
f01058a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01058b0:	85 ff                	test   %edi,%edi
f01058b2:	89 fd                	mov    %edi,%ebp
f01058b4:	75 0b                	jne    f01058c1 <__umoddi3+0x91>
f01058b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01058bb:	31 d2                	xor    %edx,%edx
f01058bd:	f7 f7                	div    %edi
f01058bf:	89 c5                	mov    %eax,%ebp
f01058c1:	89 f0                	mov    %esi,%eax
f01058c3:	31 d2                	xor    %edx,%edx
f01058c5:	f7 f5                	div    %ebp
f01058c7:	89 c8                	mov    %ecx,%eax
f01058c9:	f7 f5                	div    %ebp
f01058cb:	89 d0                	mov    %edx,%eax
f01058cd:	eb 99                	jmp    f0105868 <__umoddi3+0x38>
f01058cf:	90                   	nop
f01058d0:	89 c8                	mov    %ecx,%eax
f01058d2:	89 f2                	mov    %esi,%edx
f01058d4:	83 c4 1c             	add    $0x1c,%esp
f01058d7:	5b                   	pop    %ebx
f01058d8:	5e                   	pop    %esi
f01058d9:	5f                   	pop    %edi
f01058da:	5d                   	pop    %ebp
f01058db:	c3                   	ret    
f01058dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01058e0:	8b 34 24             	mov    (%esp),%esi
f01058e3:	bf 20 00 00 00       	mov    $0x20,%edi
f01058e8:	89 e9                	mov    %ebp,%ecx
f01058ea:	29 ef                	sub    %ebp,%edi
f01058ec:	d3 e0                	shl    %cl,%eax
f01058ee:	89 f9                	mov    %edi,%ecx
f01058f0:	89 f2                	mov    %esi,%edx
f01058f2:	d3 ea                	shr    %cl,%edx
f01058f4:	89 e9                	mov    %ebp,%ecx
f01058f6:	09 c2                	or     %eax,%edx
f01058f8:	89 d8                	mov    %ebx,%eax
f01058fa:	89 14 24             	mov    %edx,(%esp)
f01058fd:	89 f2                	mov    %esi,%edx
f01058ff:	d3 e2                	shl    %cl,%edx
f0105901:	89 f9                	mov    %edi,%ecx
f0105903:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105907:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010590b:	d3 e8                	shr    %cl,%eax
f010590d:	89 e9                	mov    %ebp,%ecx
f010590f:	89 c6                	mov    %eax,%esi
f0105911:	d3 e3                	shl    %cl,%ebx
f0105913:	89 f9                	mov    %edi,%ecx
f0105915:	89 d0                	mov    %edx,%eax
f0105917:	d3 e8                	shr    %cl,%eax
f0105919:	89 e9                	mov    %ebp,%ecx
f010591b:	09 d8                	or     %ebx,%eax
f010591d:	89 d3                	mov    %edx,%ebx
f010591f:	89 f2                	mov    %esi,%edx
f0105921:	f7 34 24             	divl   (%esp)
f0105924:	89 d6                	mov    %edx,%esi
f0105926:	d3 e3                	shl    %cl,%ebx
f0105928:	f7 64 24 04          	mull   0x4(%esp)
f010592c:	39 d6                	cmp    %edx,%esi
f010592e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105932:	89 d1                	mov    %edx,%ecx
f0105934:	89 c3                	mov    %eax,%ebx
f0105936:	72 08                	jb     f0105940 <__umoddi3+0x110>
f0105938:	75 11                	jne    f010594b <__umoddi3+0x11b>
f010593a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010593e:	73 0b                	jae    f010594b <__umoddi3+0x11b>
f0105940:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105944:	1b 14 24             	sbb    (%esp),%edx
f0105947:	89 d1                	mov    %edx,%ecx
f0105949:	89 c3                	mov    %eax,%ebx
f010594b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010594f:	29 da                	sub    %ebx,%edx
f0105951:	19 ce                	sbb    %ecx,%esi
f0105953:	89 f9                	mov    %edi,%ecx
f0105955:	89 f0                	mov    %esi,%eax
f0105957:	d3 e0                	shl    %cl,%eax
f0105959:	89 e9                	mov    %ebp,%ecx
f010595b:	d3 ea                	shr    %cl,%edx
f010595d:	89 e9                	mov    %ebp,%ecx
f010595f:	d3 ee                	shr    %cl,%esi
f0105961:	09 d0                	or     %edx,%eax
f0105963:	89 f2                	mov    %esi,%edx
f0105965:	83 c4 1c             	add    $0x1c,%esp
f0105968:	5b                   	pop    %ebx
f0105969:	5e                   	pop    %esi
f010596a:	5f                   	pop    %edi
f010596b:	5d                   	pop    %ebp
f010596c:	c3                   	ret    
f010596d:	8d 76 00             	lea    0x0(%esi),%esi
f0105970:	29 f9                	sub    %edi,%ecx
f0105972:	19 d6                	sbb    %edx,%esi
f0105974:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105978:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010597c:	e9 18 ff ff ff       	jmp    f0105899 <__umoddi3+0x69>
