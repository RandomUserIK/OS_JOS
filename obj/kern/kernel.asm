
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
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
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
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

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
f0100048:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 fe 22 f0    	mov    %esi,0xf022fe80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 85 5a 00 00       	call   f0105ae6 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 61 10 f0       	push   $0xf0106180
f010006d:	e8 31 36 00 00       	call   f01036a3 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 01 36 00 00       	call   f010367d <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 3c 65 10 f0 	movl   $0xf010653c,(%esp)
f0100083:	e8 1b 36 00 00       	call   f01036a3 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 e1 08 00 00       	call   f0100976 <monitor>
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
f01000a1:	b8 08 10 27 f0       	mov    $0xf0271008,%eax
f01000a6:	2d 10 e9 22 f0       	sub    $0xf022e910,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 10 e9 22 f0       	push   $0xf022e910
f01000b3:	e8 0d 54 00 00       	call   f01054c5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 a0 05 00 00       	call   f010065d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 61 10 f0       	push   $0xf01061ec
f01000ca:	e8 d4 35 00 00       	call   f01036a3 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 cf 12 00 00       	call   f01013a3 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 2d 2e 00 00       	call   f0102f06 <env_init>
	trap_init();
f01000d9:	e8 ba 36 00 00       	call   f0103798 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 f9 56 00 00       	call   f01057dc <mp_init>
	lapic_init();
f01000e3:	e8 19 5a 00 00       	call   f0105b01 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 dd 34 00 00       	call   f01035ca <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 5b 5c 00 00       	call   f0105d54 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 fe 22 f0 07 	cmpl   $0x7,0xf022fe88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 a4 61 10 f0       	push   $0xf01061a4
f010010f:	6a 56                	push   $0x56
f0100111:	68 07 62 10 f0       	push   $0xf0106207
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 42 57 10 f0       	mov    $0xf0105742,%eax
f0100123:	2d c8 56 10 f0       	sub    $0xf01056c8,%eax
f0100128:	50                   	push   %eax
f0100129:	68 c8 56 10 f0       	push   $0xf01056c8
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 da 53 00 00       	call   f0105512 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 00 23 f0       	mov    $0xf0230020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 9f 59 00 00       	call   f0105ae6 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 00 23 f0       	sub    $0xf0230020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 90 23 f0       	add    $0xf0239000,%eax
f010016b:	a3 84 fe 22 f0       	mov    %eax,0xf022fe84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 ce 5a 00 00       	call   f0105c4f <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0100196:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 ec 83 19 f0       	push   $0xf01983ec
f01001a9:	e8 2c 2f 00 00       	call   f01030da <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001ae:	83 c4 08             	add    $0x8,%esp
f01001b1:	6a 00                	push   $0x0
f01001b3:	68 ec 83 19 f0       	push   $0xf01983ec
f01001b8:	e8 1d 2f 00 00       	call   f01030da <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001bd:	83 c4 08             	add    $0x8,%esp
f01001c0:	6a 00                	push   $0x0
f01001c2:	68 ec 83 19 f0       	push   $0xf01983ec
f01001c7:	e8 0e 2f 00 00       	call   f01030da <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001cc:	e8 ed 42 00 00       	call   f01044be <sched_yield>

f01001d1 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001d1:	55                   	push   %ebp
f01001d2:	89 e5                	mov    %esp,%ebp
f01001d4:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001d7:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001e1:	77 12                	ja     f01001f5 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001e3:	50                   	push   %eax
f01001e4:	68 c8 61 10 f0       	push   $0xf01061c8
f01001e9:	6a 6d                	push   $0x6d
f01001eb:	68 07 62 10 f0       	push   $0xf0106207
f01001f0:	e8 4b fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001f5:	05 00 00 00 10       	add    $0x10000000,%eax
f01001fa:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001fd:	e8 e4 58 00 00       	call   f0105ae6 <cpunum>
f0100202:	83 ec 08             	sub    $0x8,%esp
f0100205:	50                   	push   %eax
f0100206:	68 13 62 10 f0       	push   $0xf0106213
f010020b:	e8 93 34 00 00       	call   f01036a3 <cprintf>

	lapic_init();
f0100210:	e8 ec 58 00 00       	call   f0105b01 <lapic_init>
	env_init_percpu();
f0100215:	e8 bc 2c 00 00       	call   f0102ed6 <env_init_percpu>
	trap_init_percpu();
f010021a:	e8 98 34 00 00       	call   f01036b7 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f010021f:	e8 c2 58 00 00       	call   f0105ae6 <cpunum>
f0100224:	6b d0 74             	imul   $0x74,%eax,%edx
f0100227:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010022d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100232:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100236:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010023d:	e8 12 5b 00 00       	call   f0105d54 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100242:	e8 77 42 00 00       	call   f01044be <sched_yield>

f0100247 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100247:	55                   	push   %ebp
f0100248:	89 e5                	mov    %esp,%ebp
f010024a:	53                   	push   %ebx
f010024b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010024e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100251:	ff 75 0c             	pushl  0xc(%ebp)
f0100254:	ff 75 08             	pushl  0x8(%ebp)
f0100257:	68 29 62 10 f0       	push   $0xf0106229
f010025c:	e8 42 34 00 00       	call   f01036a3 <cprintf>
	vcprintf(fmt, ap);
f0100261:	83 c4 08             	add    $0x8,%esp
f0100264:	53                   	push   %ebx
f0100265:	ff 75 10             	pushl  0x10(%ebp)
f0100268:	e8 10 34 00 00       	call   f010367d <vcprintf>
	cprintf("\n");
f010026d:	c7 04 24 3c 65 10 f0 	movl   $0xf010653c,(%esp)
f0100274:	e8 2a 34 00 00       	call   f01036a3 <cprintf>
	va_end(ap);
}
f0100279:	83 c4 10             	add    $0x10,%esp
f010027c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010027f:	c9                   	leave  
f0100280:	c3                   	ret    

f0100281 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100281:	55                   	push   %ebp
f0100282:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100284:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100289:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010028a:	a8 01                	test   $0x1,%al
f010028c:	74 0b                	je     f0100299 <serial_proc_data+0x18>
f010028e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100293:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100294:	0f b6 c0             	movzbl %al,%eax
f0100297:	eb 05                	jmp    f010029e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 04             	sub    $0x4,%esp
f01002a7:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002a9:	eb 2b                	jmp    f01002d6 <cons_intr+0x36>
		if (c == 0)
f01002ab:	85 c0                	test   %eax,%eax
f01002ad:	74 27                	je     f01002d6 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01002af:	8b 0d 24 f2 22 f0    	mov    0xf022f224,%ecx
f01002b5:	8d 51 01             	lea    0x1(%ecx),%edx
f01002b8:	89 15 24 f2 22 f0    	mov    %edx,0xf022f224
f01002be:	88 81 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002c4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ca:	75 0a                	jne    f01002d6 <cons_intr+0x36>
			cons.wpos = 0;
f01002cc:	c7 05 24 f2 22 f0 00 	movl   $0x0,0xf022f224
f01002d3:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d6:	ff d3                	call   *%ebx
f01002d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002db:	75 ce                	jne    f01002ab <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002dd:	83 c4 04             	add    $0x4,%esp
f01002e0:	5b                   	pop    %ebx
f01002e1:	5d                   	pop    %ebp
f01002e2:	c3                   	ret    

f01002e3 <kbd_proc_data>:
f01002e3:	ba 64 00 00 00       	mov    $0x64,%edx
f01002e8:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002e9:	a8 01                	test   $0x1,%al
f01002eb:	0f 84 f8 00 00 00    	je     f01003e9 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002f1:	a8 20                	test   $0x20,%al
f01002f3:	0f 85 f6 00 00 00    	jne    f01003ef <kbd_proc_data+0x10c>
f01002f9:	ba 60 00 00 00       	mov    $0x60,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100301:	3c e0                	cmp    $0xe0,%al
f0100303:	75 0d                	jne    f0100312 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f0100305:	83 0d 00 f0 22 f0 40 	orl    $0x40,0xf022f000
		return 0;
f010030c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100311:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100312:	55                   	push   %ebp
f0100313:	89 e5                	mov    %esp,%ebp
f0100315:	53                   	push   %ebx
f0100316:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100319:	84 c0                	test   %al,%al
f010031b:	79 36                	jns    f0100353 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010031d:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100323:	89 cb                	mov    %ecx,%ebx
f0100325:	83 e3 40             	and    $0x40,%ebx
f0100328:	83 e0 7f             	and    $0x7f,%eax
f010032b:	85 db                	test   %ebx,%ebx
f010032d:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100330:	0f b6 d2             	movzbl %dl,%edx
f0100333:	0f b6 82 a0 63 10 f0 	movzbl -0xfef9c60(%edx),%eax
f010033a:	83 c8 40             	or     $0x40,%eax
f010033d:	0f b6 c0             	movzbl %al,%eax
f0100340:	f7 d0                	not    %eax
f0100342:	21 c8                	and    %ecx,%eax
f0100344:	a3 00 f0 22 f0       	mov    %eax,0xf022f000
		return 0;
f0100349:	b8 00 00 00 00       	mov    $0x0,%eax
f010034e:	e9 a4 00 00 00       	jmp    f01003f7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100353:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100359:	f6 c1 40             	test   $0x40,%cl
f010035c:	74 0e                	je     f010036c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010035e:	83 c8 80             	or     $0xffffff80,%eax
f0100361:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100363:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100366:	89 0d 00 f0 22 f0    	mov    %ecx,0xf022f000
	}

	shift |= shiftcode[data];
f010036c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010036f:	0f b6 82 a0 63 10 f0 	movzbl -0xfef9c60(%edx),%eax
f0100376:	0b 05 00 f0 22 f0    	or     0xf022f000,%eax
f010037c:	0f b6 8a a0 62 10 f0 	movzbl -0xfef9d60(%edx),%ecx
f0100383:	31 c8                	xor    %ecx,%eax
f0100385:	a3 00 f0 22 f0       	mov    %eax,0xf022f000

	c = charcode[shift & (CTL | SHIFT)][data];
f010038a:	89 c1                	mov    %eax,%ecx
f010038c:	83 e1 03             	and    $0x3,%ecx
f010038f:	8b 0c 8d 80 62 10 f0 	mov    -0xfef9d80(,%ecx,4),%ecx
f0100396:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010039a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010039d:	a8 08                	test   $0x8,%al
f010039f:	74 1b                	je     f01003bc <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f01003a1:	89 da                	mov    %ebx,%edx
f01003a3:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003a6:	83 f9 19             	cmp    $0x19,%ecx
f01003a9:	77 05                	ja     f01003b0 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01003ab:	83 eb 20             	sub    $0x20,%ebx
f01003ae:	eb 0c                	jmp    f01003bc <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01003b0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003b3:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003b6:	83 fa 19             	cmp    $0x19,%edx
f01003b9:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003bc:	f7 d0                	not    %eax
f01003be:	a8 06                	test   $0x6,%al
f01003c0:	75 33                	jne    f01003f5 <kbd_proc_data+0x112>
f01003c2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003c8:	75 2b                	jne    f01003f5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ca:	83 ec 0c             	sub    $0xc,%esp
f01003cd:	68 43 62 10 f0       	push   $0xf0106243
f01003d2:	e8 cc 32 00 00       	call   f01036a3 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d7:	ba 92 00 00 00       	mov    $0x92,%edx
f01003dc:	b8 03 00 00 00       	mov    $0x3,%eax
f01003e1:	ee                   	out    %al,(%dx)
f01003e2:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003e5:	89 d8                	mov    %ebx,%eax
f01003e7:	eb 0e                	jmp    f01003f7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003ee:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003f4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f5:	89 d8                	mov    %ebx,%eax
}
f01003f7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003fa:	c9                   	leave  
f01003fb:	c3                   	ret    

f01003fc <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003fc:	55                   	push   %ebp
f01003fd:	89 e5                	mov    %esp,%ebp
f01003ff:	57                   	push   %edi
f0100400:	56                   	push   %esi
f0100401:	53                   	push   %ebx
f0100402:	83 ec 1c             	sub    $0x1c,%esp
f0100405:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100407:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010040c:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100411:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100416:	eb 09                	jmp    f0100421 <cons_putc+0x25>
f0100418:	89 ca                	mov    %ecx,%edx
f010041a:	ec                   	in     (%dx),%al
f010041b:	ec                   	in     (%dx),%al
f010041c:	ec                   	in     (%dx),%al
f010041d:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f010041e:	83 c3 01             	add    $0x1,%ebx
f0100421:	89 f2                	mov    %esi,%edx
f0100423:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100424:	a8 20                	test   $0x20,%al
f0100426:	75 08                	jne    f0100430 <cons_putc+0x34>
f0100428:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010042e:	7e e8                	jle    f0100418 <cons_putc+0x1c>
f0100430:	89 f8                	mov    %edi,%eax
f0100432:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100435:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010043a:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010043b:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100440:	be 79 03 00 00       	mov    $0x379,%esi
f0100445:	b9 84 00 00 00       	mov    $0x84,%ecx
f010044a:	eb 09                	jmp    f0100455 <cons_putc+0x59>
f010044c:	89 ca                	mov    %ecx,%edx
f010044e:	ec                   	in     (%dx),%al
f010044f:	ec                   	in     (%dx),%al
f0100450:	ec                   	in     (%dx),%al
f0100451:	ec                   	in     (%dx),%al
f0100452:	83 c3 01             	add    $0x1,%ebx
f0100455:	89 f2                	mov    %esi,%edx
f0100457:	ec                   	in     (%dx),%al
f0100458:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010045e:	7f 04                	jg     f0100464 <cons_putc+0x68>
f0100460:	84 c0                	test   %al,%al
f0100462:	79 e8                	jns    f010044c <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100464:	ba 78 03 00 00       	mov    $0x378,%edx
f0100469:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010046d:	ee                   	out    %al,(%dx)
f010046e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100473:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100478:	ee                   	out    %al,(%dx)
f0100479:	b8 08 00 00 00       	mov    $0x8,%eax
f010047e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010047f:	89 fa                	mov    %edi,%edx
f0100481:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100487:	89 f8                	mov    %edi,%eax
f0100489:	80 cc 07             	or     $0x7,%ah
f010048c:	85 d2                	test   %edx,%edx
f010048e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100491:	89 f8                	mov    %edi,%eax
f0100493:	0f b6 c0             	movzbl %al,%eax
f0100496:	83 f8 09             	cmp    $0x9,%eax
f0100499:	74 74                	je     f010050f <cons_putc+0x113>
f010049b:	83 f8 09             	cmp    $0x9,%eax
f010049e:	7f 0a                	jg     f01004aa <cons_putc+0xae>
f01004a0:	83 f8 08             	cmp    $0x8,%eax
f01004a3:	74 14                	je     f01004b9 <cons_putc+0xbd>
f01004a5:	e9 99 00 00 00       	jmp    f0100543 <cons_putc+0x147>
f01004aa:	83 f8 0a             	cmp    $0xa,%eax
f01004ad:	74 3a                	je     f01004e9 <cons_putc+0xed>
f01004af:	83 f8 0d             	cmp    $0xd,%eax
f01004b2:	74 3d                	je     f01004f1 <cons_putc+0xf5>
f01004b4:	e9 8a 00 00 00       	jmp    f0100543 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01004b9:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004c0:	66 85 c0             	test   %ax,%ax
f01004c3:	0f 84 e6 00 00 00    	je     f01005af <cons_putc+0x1b3>
			crt_pos--;
f01004c9:	83 e8 01             	sub    $0x1,%eax
f01004cc:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d2:	0f b7 c0             	movzwl %ax,%eax
f01004d5:	66 81 e7 00 ff       	and    $0xff00,%di
f01004da:	83 cf 20             	or     $0x20,%edi
f01004dd:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f01004e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004e7:	eb 78                	jmp    f0100561 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004e9:	66 83 05 28 f2 22 f0 	addw   $0x50,0xf022f228
f01004f0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004f1:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004f8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004fe:	c1 e8 16             	shr    $0x16,%eax
f0100501:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100504:	c1 e0 04             	shl    $0x4,%eax
f0100507:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
f010050d:	eb 52                	jmp    f0100561 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 e3 fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 d9 fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f0100523:	b8 20 00 00 00       	mov    $0x20,%eax
f0100528:	e8 cf fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f010052d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100532:	e8 c5 fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f0100537:	b8 20 00 00 00       	mov    $0x20,%eax
f010053c:	e8 bb fe ff ff       	call   f01003fc <cons_putc>
f0100541:	eb 1e                	jmp    f0100561 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100543:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f010054a:	8d 50 01             	lea    0x1(%eax),%edx
f010054d:	66 89 15 28 f2 22 f0 	mov    %dx,0xf022f228
f0100554:	0f b7 c0             	movzwl %ax,%eax
f0100557:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010055d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100561:	66 81 3d 28 f2 22 f0 	cmpw   $0x7cf,0xf022f228
f0100568:	cf 07 
f010056a:	76 43                	jbe    f01005af <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010056c:	a1 2c f2 22 f0       	mov    0xf022f22c,%eax
f0100571:	83 ec 04             	sub    $0x4,%esp
f0100574:	68 00 0f 00 00       	push   $0xf00
f0100579:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010057f:	52                   	push   %edx
f0100580:	50                   	push   %eax
f0100581:	e8 8c 4f 00 00       	call   f0105512 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100586:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010058c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100592:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100598:	83 c4 10             	add    $0x10,%esp
f010059b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005a0:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005a3:	39 d0                	cmp    %edx,%eax
f01005a5:	75 f4                	jne    f010059b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005a7:	66 83 2d 28 f2 22 f0 	subw   $0x50,0xf022f228
f01005ae:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005af:	8b 0d 30 f2 22 f0    	mov    0xf022f230,%ecx
f01005b5:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ba:	89 ca                	mov    %ecx,%edx
f01005bc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005bd:	0f b7 1d 28 f2 22 f0 	movzwl 0xf022f228,%ebx
f01005c4:	8d 71 01             	lea    0x1(%ecx),%esi
f01005c7:	89 d8                	mov    %ebx,%eax
f01005c9:	66 c1 e8 08          	shr    $0x8,%ax
f01005cd:	89 f2                	mov    %esi,%edx
f01005cf:	ee                   	out    %al,(%dx)
f01005d0:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d5:	89 ca                	mov    %ecx,%edx
f01005d7:	ee                   	out    %al,(%dx)
f01005d8:	89 d8                	mov    %ebx,%eax
f01005da:	89 f2                	mov    %esi,%edx
f01005dc:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005e0:	5b                   	pop    %ebx
f01005e1:	5e                   	pop    %esi
f01005e2:	5f                   	pop    %edi
f01005e3:	5d                   	pop    %ebp
f01005e4:	c3                   	ret    

f01005e5 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005e5:	80 3d 34 f2 22 f0 00 	cmpb   $0x0,0xf022f234
f01005ec:	74 11                	je     f01005ff <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005ee:	55                   	push   %ebp
f01005ef:	89 e5                	mov    %esp,%ebp
f01005f1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005f4:	b8 81 02 10 f0       	mov    $0xf0100281,%eax
f01005f9:	e8 a2 fc ff ff       	call   f01002a0 <cons_intr>
}
f01005fe:	c9                   	leave  
f01005ff:	f3 c3                	repz ret 

f0100601 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100607:	b8 e3 02 10 f0       	mov    $0xf01002e3,%eax
f010060c:	e8 8f fc ff ff       	call   f01002a0 <cons_intr>
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
f0100616:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100619:	e8 c7 ff ff ff       	call   f01005e5 <serial_intr>
	kbd_intr();
f010061e:	e8 de ff ff ff       	call   f0100601 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100623:	a1 20 f2 22 f0       	mov    0xf022f220,%eax
f0100628:	3b 05 24 f2 22 f0    	cmp    0xf022f224,%eax
f010062e:	74 26                	je     f0100656 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100630:	8d 50 01             	lea    0x1(%eax),%edx
f0100633:	89 15 20 f2 22 f0    	mov    %edx,0xf022f220
f0100639:	0f b6 88 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100640:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100642:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100648:	75 11                	jne    f010065b <cons_getc+0x48>
			cons.rpos = 0;
f010064a:	c7 05 20 f2 22 f0 00 	movl   $0x0,0xf022f220
f0100651:	00 00 00 
f0100654:	eb 05                	jmp    f010065b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100656:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	57                   	push   %edi
f0100661:	56                   	push   %esi
f0100662:	53                   	push   %ebx
f0100663:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100666:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010066d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100674:	5a a5 
	if (*cp != 0xA55A) {
f0100676:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010067d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100681:	74 11                	je     f0100694 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100683:	c7 05 30 f2 22 f0 b4 	movl   $0x3b4,0xf022f230
f010068a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010068d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100692:	eb 16                	jmp    f01006aa <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100694:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069b:	c7 05 30 f2 22 f0 d4 	movl   $0x3d4,0xf022f230
f01006a2:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a5:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006aa:	8b 3d 30 f2 22 f0    	mov    0xf022f230,%edi
f01006b0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006b5:	89 fa                	mov    %edi,%edx
f01006b7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006b8:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bb:	89 da                	mov    %ebx,%edx
f01006bd:	ec                   	in     (%dx),%al
f01006be:	0f b6 c8             	movzbl %al,%ecx
f01006c1:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006c9:	89 fa                	mov    %edi,%edx
f01006cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006cc:	89 da                	mov    %ebx,%edx
f01006ce:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006cf:	89 35 2c f2 22 f0    	mov    %esi,0xf022f22c
	crt_pos = pos;
f01006d5:	0f b6 c0             	movzbl %al,%eax
f01006d8:	09 c8                	or     %ecx,%eax
f01006da:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006e0:	e8 1c ff ff ff       	call   f0100601 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006e5:	83 ec 0c             	sub    $0xc,%esp
f01006e8:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006ef:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006f4:	50                   	push   %eax
f01006f5:	e8 58 2e 00 00       	call   f0103552 <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006fa:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0100704:	89 f2                	mov    %esi,%edx
f0100706:	ee                   	out    %al,(%dx)
f0100707:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010070c:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100711:	ee                   	out    %al,(%dx)
f0100712:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100717:	b8 0c 00 00 00       	mov    $0xc,%eax
f010071c:	89 da                	mov    %ebx,%edx
f010071e:	ee                   	out    %al,(%dx)
f010071f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100724:	b8 00 00 00 00       	mov    $0x0,%eax
f0100729:	ee                   	out    %al,(%dx)
f010072a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010072f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100734:	ee                   	out    %al,(%dx)
f0100735:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010073a:	b8 00 00 00 00       	mov    $0x0,%eax
f010073f:	ee                   	out    %al,(%dx)
f0100740:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100745:	b8 01 00 00 00       	mov    $0x1,%eax
f010074a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010074b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100750:	ec                   	in     (%dx),%al
f0100751:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100753:	83 c4 10             	add    $0x10,%esp
f0100756:	3c ff                	cmp    $0xff,%al
f0100758:	0f 95 05 34 f2 22 f0 	setne  0xf022f234
f010075f:	89 f2                	mov    %esi,%edx
f0100761:	ec                   	in     (%dx),%al
f0100762:	89 da                	mov    %ebx,%edx
f0100764:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100765:	80 f9 ff             	cmp    $0xff,%cl
f0100768:	75 10                	jne    f010077a <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010076a:	83 ec 0c             	sub    $0xc,%esp
f010076d:	68 4f 62 10 f0       	push   $0xf010624f
f0100772:	e8 2c 2f 00 00       	call   f01036a3 <cprintf>
f0100777:	83 c4 10             	add    $0x10,%esp
}
f010077a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010077d:	5b                   	pop    %ebx
f010077e:	5e                   	pop    %esi
f010077f:	5f                   	pop    %edi
f0100780:	5d                   	pop    %ebp
f0100781:	c3                   	ret    

f0100782 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100782:	55                   	push   %ebp
f0100783:	89 e5                	mov    %esp,%ebp
f0100785:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100788:	8b 45 08             	mov    0x8(%ebp),%eax
f010078b:	e8 6c fc ff ff       	call   f01003fc <cons_putc>
}
f0100790:	c9                   	leave  
f0100791:	c3                   	ret    

f0100792 <getchar>:

int
getchar(void)
{
f0100792:	55                   	push   %ebp
f0100793:	89 e5                	mov    %esp,%ebp
f0100795:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100798:	e8 76 fe ff ff       	call   f0100613 <cons_getc>
f010079d:	85 c0                	test   %eax,%eax
f010079f:	74 f7                	je     f0100798 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007a1:	c9                   	leave  
f01007a2:	c3                   	ret    

f01007a3 <iscons>:

int
iscons(int fdnum)
{
f01007a3:	55                   	push   %ebp
f01007a4:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01007ab:	5d                   	pop    %ebp
f01007ac:	c3                   	ret    

f01007ad <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007ad:	55                   	push   %ebp
f01007ae:	89 e5                	mov    %esp,%ebp
f01007b0:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007b3:	68 a0 64 10 f0       	push   $0xf01064a0
f01007b8:	68 be 64 10 f0       	push   $0xf01064be
f01007bd:	68 c3 64 10 f0       	push   $0xf01064c3
f01007c2:	e8 dc 2e 00 00       	call   f01036a3 <cprintf>
f01007c7:	83 c4 0c             	add    $0xc,%esp
f01007ca:	68 7c 65 10 f0       	push   $0xf010657c
f01007cf:	68 cc 64 10 f0       	push   $0xf01064cc
f01007d4:	68 c3 64 10 f0       	push   $0xf01064c3
f01007d9:	e8 c5 2e 00 00       	call   f01036a3 <cprintf>
f01007de:	83 c4 0c             	add    $0xc,%esp
f01007e1:	68 a4 65 10 f0       	push   $0xf01065a4
f01007e6:	68 d5 64 10 f0       	push   $0xf01064d5
f01007eb:	68 c3 64 10 f0       	push   $0xf01064c3
f01007f0:	e8 ae 2e 00 00       	call   f01036a3 <cprintf>
	return 0;
}
f01007f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007fa:	c9                   	leave  
f01007fb:	c3                   	ret    

f01007fc <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007fc:	55                   	push   %ebp
f01007fd:	89 e5                	mov    %esp,%ebp
f01007ff:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100802:	68 df 64 10 f0       	push   $0xf01064df
f0100807:	e8 97 2e 00 00       	call   f01036a3 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010080c:	83 c4 08             	add    $0x8,%esp
f010080f:	68 0c 00 10 00       	push   $0x10000c
f0100814:	68 d0 65 10 f0       	push   $0xf01065d0
f0100819:	e8 85 2e 00 00       	call   f01036a3 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010081e:	83 c4 0c             	add    $0xc,%esp
f0100821:	68 0c 00 10 00       	push   $0x10000c
f0100826:	68 0c 00 10 f0       	push   $0xf010000c
f010082b:	68 f8 65 10 f0       	push   $0xf01065f8
f0100830:	e8 6e 2e 00 00       	call   f01036a3 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 61 61 10 00       	push   $0x106161
f010083d:	68 61 61 10 f0       	push   $0xf0106161
f0100842:	68 1c 66 10 f0       	push   $0xf010661c
f0100847:	e8 57 2e 00 00       	call   f01036a3 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 10 e9 22 00       	push   $0x22e910
f0100854:	68 10 e9 22 f0       	push   $0xf022e910
f0100859:	68 40 66 10 f0       	push   $0xf0106640
f010085e:	e8 40 2e 00 00       	call   f01036a3 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100863:	83 c4 0c             	add    $0xc,%esp
f0100866:	68 08 10 27 00       	push   $0x271008
f010086b:	68 08 10 27 f0       	push   $0xf0271008
f0100870:	68 64 66 10 f0       	push   $0xf0106664
f0100875:	e8 29 2e 00 00       	call   f01036a3 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010087a:	b8 07 14 27 f0       	mov    $0xf0271407,%eax
f010087f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100884:	83 c4 08             	add    $0x8,%esp
f0100887:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010088c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100892:	85 c0                	test   %eax,%eax
f0100894:	0f 48 c2             	cmovs  %edx,%eax
f0100897:	c1 f8 0a             	sar    $0xa,%eax
f010089a:	50                   	push   %eax
f010089b:	68 88 66 10 f0       	push   $0xf0106688
f01008a0:	e8 fe 2d 00 00       	call   f01036a3 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008aa:	c9                   	leave  
f01008ab:	c3                   	ret    

f01008ac <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008ac:	55                   	push   %ebp
f01008ad:	89 e5                	mov    %esp,%ebp
f01008af:	57                   	push   %edi
f01008b0:	56                   	push   %esi
f01008b1:	53                   	push   %ebx
f01008b2:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b5:	89 eb                	mov    %ebp,%ebx
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
f01008b7:	68 f8 64 10 f0       	push   $0xf01064f8
f01008bc:	e8 e2 2d 00 00       	call   f01036a3 <cprintf>
	while(ebp)
f01008c1:	83 c4 10             	add    $0x10,%esp
		cprintf("%08x ", *(ebp+3));
		cprintf("%08x ", *(ebp+4));
		cprintf("%08x ", *(ebp+5));
		cprintf("%08x", *(ebp+6));

		if(debuginfo_eip(eip, &info) == 0)
f01008c4:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f01008c7:	e9 95 00 00 00       	jmp    f0100961 <mon_backtrace+0xb5>
	{
		eip = *(ebp+1);
f01008cc:	8b 73 04             	mov    0x4(%ebx),%esi

		cprintf("ebp %08x  eip %08x  args ", ebp, eip);
f01008cf:	83 ec 04             	sub    $0x4,%esp
f01008d2:	56                   	push   %esi
f01008d3:	53                   	push   %ebx
f01008d4:	68 0b 65 10 f0       	push   $0xf010650b
f01008d9:	e8 c5 2d 00 00       	call   f01036a3 <cprintf>
		cprintf("%08x ", *(ebp+2));
f01008de:	83 c4 08             	add    $0x8,%esp
f01008e1:	ff 73 08             	pushl  0x8(%ebx)
f01008e4:	68 25 65 10 f0       	push   $0xf0106525
f01008e9:	e8 b5 2d 00 00       	call   f01036a3 <cprintf>
		cprintf("%08x ", *(ebp+3));
f01008ee:	83 c4 08             	add    $0x8,%esp
f01008f1:	ff 73 0c             	pushl  0xc(%ebx)
f01008f4:	68 25 65 10 f0       	push   $0xf0106525
f01008f9:	e8 a5 2d 00 00       	call   f01036a3 <cprintf>
		cprintf("%08x ", *(ebp+4));
f01008fe:	83 c4 08             	add    $0x8,%esp
f0100901:	ff 73 10             	pushl  0x10(%ebx)
f0100904:	68 25 65 10 f0       	push   $0xf0106525
f0100909:	e8 95 2d 00 00       	call   f01036a3 <cprintf>
		cprintf("%08x ", *(ebp+5));
f010090e:	83 c4 08             	add    $0x8,%esp
f0100911:	ff 73 14             	pushl  0x14(%ebx)
f0100914:	68 25 65 10 f0       	push   $0xf0106525
f0100919:	e8 85 2d 00 00       	call   f01036a3 <cprintf>
		cprintf("%08x", *(ebp+6));
f010091e:	83 c4 08             	add    $0x8,%esp
f0100921:	ff 73 18             	pushl  0x18(%ebx)
f0100924:	68 c2 75 10 f0       	push   $0xf01075c2
f0100929:	e8 75 2d 00 00       	call   f01036a3 <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f010092e:	83 c4 08             	add    $0x8,%esp
f0100931:	57                   	push   %edi
f0100932:	56                   	push   %esi
f0100933:	e8 1b 41 00 00       	call   f0104a53 <debuginfo_eip>
f0100938:	83 c4 10             	add    $0x10,%esp
f010093b:	85 c0                	test   %eax,%eax
f010093d:	75 20                	jne    f010095f <mon_backtrace+0xb3>
		{
			cprintf("\t %s:%d: %.*s+%d\n\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 											      info.eip_fn_name, eip-info.eip_fn_addr);
f010093f:	83 ec 08             	sub    $0x8,%esp
f0100942:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100945:	56                   	push   %esi
f0100946:	ff 75 d8             	pushl  -0x28(%ebp)
f0100949:	ff 75 dc             	pushl  -0x24(%ebp)
f010094c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010094f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100952:	68 2b 65 10 f0       	push   $0xf010652b
f0100957:	e8 47 2d 00 00       	call   f01036a3 <cprintf>
f010095c:	83 c4 20             	add    $0x20,%esp
		}

		ebp = (uint32_t*) *ebp;
f010095f:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f0100961:	85 db                	test   %ebx,%ebx
f0100963:	0f 85 63 ff ff ff    	jne    f01008cc <mon_backtrace+0x20>
		}

		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f0100969:	b8 00 00 00 00       	mov    $0x0,%eax
f010096e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100971:	5b                   	pop    %ebx
f0100972:	5e                   	pop    %esi
f0100973:	5f                   	pop    %edi
f0100974:	5d                   	pop    %ebp
f0100975:	c3                   	ret    

f0100976 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100976:	55                   	push   %ebp
f0100977:	89 e5                	mov    %esp,%ebp
f0100979:	57                   	push   %edi
f010097a:	56                   	push   %esi
f010097b:	53                   	push   %ebx
f010097c:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010097f:	68 b4 66 10 f0       	push   $0xf01066b4
f0100984:	e8 1a 2d 00 00       	call   f01036a3 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100989:	c7 04 24 d8 66 10 f0 	movl   $0xf01066d8,(%esp)
f0100990:	e8 0e 2d 00 00       	call   f01036a3 <cprintf>

	if (tf != NULL)
f0100995:	83 c4 10             	add    $0x10,%esp
f0100998:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010099c:	74 0e                	je     f01009ac <monitor+0x36>
		print_trapframe(tf);
f010099e:	83 ec 0c             	sub    $0xc,%esp
f01009a1:	ff 75 08             	pushl  0x8(%ebp)
f01009a4:	e8 67 34 00 00       	call   f0103e10 <print_trapframe>
f01009a9:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009ac:	83 ec 0c             	sub    $0xc,%esp
f01009af:	68 3e 65 10 f0       	push   $0xf010653e
f01009b4:	e8 b5 48 00 00       	call   f010526e <readline>
f01009b9:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009bb:	83 c4 10             	add    $0x10,%esp
f01009be:	85 c0                	test   %eax,%eax
f01009c0:	74 ea                	je     f01009ac <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009c2:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009c9:	be 00 00 00 00       	mov    $0x0,%esi
f01009ce:	eb 0a                	jmp    f01009da <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009d0:	c6 03 00             	movb   $0x0,(%ebx)
f01009d3:	89 f7                	mov    %esi,%edi
f01009d5:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009d8:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009da:	0f b6 03             	movzbl (%ebx),%eax
f01009dd:	84 c0                	test   %al,%al
f01009df:	74 63                	je     f0100a44 <monitor+0xce>
f01009e1:	83 ec 08             	sub    $0x8,%esp
f01009e4:	0f be c0             	movsbl %al,%eax
f01009e7:	50                   	push   %eax
f01009e8:	68 42 65 10 f0       	push   $0xf0106542
f01009ed:	e8 96 4a 00 00       	call   f0105488 <strchr>
f01009f2:	83 c4 10             	add    $0x10,%esp
f01009f5:	85 c0                	test   %eax,%eax
f01009f7:	75 d7                	jne    f01009d0 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009f9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009fc:	74 46                	je     f0100a44 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009fe:	83 fe 0f             	cmp    $0xf,%esi
f0100a01:	75 14                	jne    f0100a17 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a03:	83 ec 08             	sub    $0x8,%esp
f0100a06:	6a 10                	push   $0x10
f0100a08:	68 47 65 10 f0       	push   $0xf0106547
f0100a0d:	e8 91 2c 00 00       	call   f01036a3 <cprintf>
f0100a12:	83 c4 10             	add    $0x10,%esp
f0100a15:	eb 95                	jmp    f01009ac <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100a17:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a1a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a1e:	eb 03                	jmp    f0100a23 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a20:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a23:	0f b6 03             	movzbl (%ebx),%eax
f0100a26:	84 c0                	test   %al,%al
f0100a28:	74 ae                	je     f01009d8 <monitor+0x62>
f0100a2a:	83 ec 08             	sub    $0x8,%esp
f0100a2d:	0f be c0             	movsbl %al,%eax
f0100a30:	50                   	push   %eax
f0100a31:	68 42 65 10 f0       	push   $0xf0106542
f0100a36:	e8 4d 4a 00 00       	call   f0105488 <strchr>
f0100a3b:	83 c4 10             	add    $0x10,%esp
f0100a3e:	85 c0                	test   %eax,%eax
f0100a40:	74 de                	je     f0100a20 <monitor+0xaa>
f0100a42:	eb 94                	jmp    f01009d8 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100a44:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a4b:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a4c:	85 f6                	test   %esi,%esi
f0100a4e:	0f 84 58 ff ff ff    	je     f01009ac <monitor+0x36>
f0100a54:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a59:	83 ec 08             	sub    $0x8,%esp
f0100a5c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a5f:	ff 34 85 00 67 10 f0 	pushl  -0xfef9900(,%eax,4)
f0100a66:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a69:	e8 bc 49 00 00       	call   f010542a <strcmp>
f0100a6e:	83 c4 10             	add    $0x10,%esp
f0100a71:	85 c0                	test   %eax,%eax
f0100a73:	75 21                	jne    f0100a96 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a75:	83 ec 04             	sub    $0x4,%esp
f0100a78:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a7b:	ff 75 08             	pushl  0x8(%ebp)
f0100a7e:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a81:	52                   	push   %edx
f0100a82:	56                   	push   %esi
f0100a83:	ff 14 85 08 67 10 f0 	call   *-0xfef98f8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a8a:	83 c4 10             	add    $0x10,%esp
f0100a8d:	85 c0                	test   %eax,%eax
f0100a8f:	78 25                	js     f0100ab6 <monitor+0x140>
f0100a91:	e9 16 ff ff ff       	jmp    f01009ac <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a96:	83 c3 01             	add    $0x1,%ebx
f0100a99:	83 fb 03             	cmp    $0x3,%ebx
f0100a9c:	75 bb                	jne    f0100a59 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a9e:	83 ec 08             	sub    $0x8,%esp
f0100aa1:	ff 75 a8             	pushl  -0x58(%ebp)
f0100aa4:	68 64 65 10 f0       	push   $0xf0106564
f0100aa9:	e8 f5 2b 00 00       	call   f01036a3 <cprintf>
f0100aae:	83 c4 10             	add    $0x10,%esp
f0100ab1:	e9 f6 fe ff ff       	jmp    f01009ac <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ab6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ab9:	5b                   	pop    %ebx
f0100aba:	5e                   	pop    %esi
f0100abb:	5f                   	pop    %edi
f0100abc:	5d                   	pop    %ebp
f0100abd:	c3                   	ret    

f0100abe <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100abe:	55                   	push   %ebp
f0100abf:	89 e5                	mov    %esp,%ebp
f0100ac1:	56                   	push   %esi
f0100ac2:	53                   	push   %ebx
f0100ac3:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ac5:	83 ec 0c             	sub    $0xc,%esp
f0100ac8:	50                   	push   %eax
f0100ac9:	e8 56 2a 00 00       	call   f0103524 <mc146818_read>
f0100ace:	89 c6                	mov    %eax,%esi
f0100ad0:	83 c3 01             	add    $0x1,%ebx
f0100ad3:	89 1c 24             	mov    %ebx,(%esp)
f0100ad6:	e8 49 2a 00 00       	call   f0103524 <mc146818_read>
f0100adb:	c1 e0 08             	shl    $0x8,%eax
f0100ade:	09 f0                	or     %esi,%eax
}
f0100ae0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ae3:	5b                   	pop    %ebx
f0100ae4:	5e                   	pop    %esi
f0100ae5:	5d                   	pop    %ebp
f0100ae6:	c3                   	ret    

f0100ae7 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ae7:	89 d1                	mov    %edx,%ecx
f0100ae9:	c1 e9 16             	shr    $0x16,%ecx
f0100aec:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100aef:	a8 01                	test   $0x1,%al
f0100af1:	74 52                	je     f0100b45 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100af3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100af8:	89 c1                	mov    %eax,%ecx
f0100afa:	c1 e9 0c             	shr    $0xc,%ecx
f0100afd:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0100b03:	72 1b                	jb     f0100b20 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b05:	55                   	push   %ebp
f0100b06:	89 e5                	mov    %esp,%ebp
f0100b08:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b0b:	50                   	push   %eax
f0100b0c:	68 a4 61 10 f0       	push   $0xf01061a4
f0100b11:	68 c5 03 00 00       	push   $0x3c5
f0100b16:	68 c5 70 10 f0       	push   $0xf01070c5
f0100b1b:	e8 20 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b20:	c1 ea 0c             	shr    $0xc,%edx
f0100b23:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b29:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b30:	89 c2                	mov    %eax,%edx
f0100b32:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b3a:	85 d2                	test   %edx,%edx
f0100b3c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b41:	0f 44 c2             	cmove  %edx,%eax
f0100b44:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b4a:	c3                   	ret    

f0100b4b <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b4b:	55                   	push   %ebp
f0100b4c:	89 e5                	mov    %esp,%ebp
f0100b4e:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b51:	83 3d 38 f2 22 f0 00 	cmpl   $0x0,0xf022f238
f0100b58:	75 11                	jne    f0100b6b <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b5a:	ba 07 20 27 f0       	mov    $0xf0272007,%edx
f0100b5f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b65:	89 15 38 f2 22 f0    	mov    %edx,0xf022f238
	//
	// LAB 2: Your code here.
	if(n < 0) 
		panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) 
f0100b6b:	85 c0                	test   %eax,%eax
f0100b6d:	75 07                	jne    f0100b76 <boot_alloc+0x2b>
		return nextfree;
f0100b6f:	a1 38 f2 22 f0       	mov    0xf022f238,%eax
f0100b74:	eb 54                	jmp    f0100bca <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f0100b76:	8b 15 38 f2 22 f0    	mov    0xf022f238,%edx

		char* new = ROUNDUP(nextfree+n, PGSIZE);
f0100b7c:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100b83:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b88:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b8d:	77 12                	ja     f0100ba1 <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b8f:	50                   	push   %eax
f0100b90:	68 c8 61 10 f0       	push   $0xf01061c8
f0100b95:	6a 78                	push   $0x78
f0100b97:	68 c5 70 10 f0       	push   $0xf01070c5
f0100b9c:	e8 9f f4 ff ff       	call   f0100040 <_panic>

		if(PADDR(new) > 1024*1024*4) 
f0100ba1:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100ba7:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100bad:	76 14                	jbe    f0100bc3 <boot_alloc+0x78>
			panic("boot_alloc: not enough memory!\n");
f0100baf:	83 ec 04             	sub    $0x4,%esp
f0100bb2:	68 24 67 10 f0       	push   $0xf0106724
f0100bb7:	6a 79                	push   $0x79
f0100bb9:	68 c5 70 10 f0       	push   $0xf01070c5
f0100bbe:	e8 7d f4 ff ff       	call   f0100040 <_panic>

		else
		{
			nextfree = new;
f0100bc3:	a3 38 f2 22 f0       	mov    %eax,0xf022f238
		}
	}

	return result;
f0100bc8:	89 d0                	mov    %edx,%eax
}
f0100bca:	c9                   	leave  
f0100bcb:	c3                   	ret    

f0100bcc <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100bcc:	55                   	push   %ebp
f0100bcd:	89 e5                	mov    %esp,%ebp
f0100bcf:	57                   	push   %edi
f0100bd0:	56                   	push   %esi
f0100bd1:	53                   	push   %ebx
f0100bd2:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bd5:	84 c0                	test   %al,%al
f0100bd7:	0f 85 a0 02 00 00    	jne    f0100e7d <check_page_free_list+0x2b1>
f0100bdd:	e9 ad 02 00 00       	jmp    f0100e8f <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100be2:	83 ec 04             	sub    $0x4,%esp
f0100be5:	68 44 67 10 f0       	push   $0xf0106744
f0100bea:	68 f8 02 00 00       	push   $0x2f8
f0100bef:	68 c5 70 10 f0       	push   $0xf01070c5
f0100bf4:	e8 47 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100bf9:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bfc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100bff:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c02:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c05:	89 c2                	mov    %eax,%edx
f0100c07:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0100c0d:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c13:	0f 95 c2             	setne  %dl
f0100c16:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c19:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c1d:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c1f:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c23:	8b 00                	mov    (%eax),%eax
f0100c25:	85 c0                	test   %eax,%eax
f0100c27:	75 dc                	jne    f0100c05 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c2c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c32:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c35:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c38:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c3a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c3d:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c42:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c47:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100c4d:	eb 53                	jmp    f0100ca2 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c4f:	89 d8                	mov    %ebx,%eax
f0100c51:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100c57:	c1 f8 03             	sar    $0x3,%eax
f0100c5a:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c5d:	89 c2                	mov    %eax,%edx
f0100c5f:	c1 ea 16             	shr    $0x16,%edx
f0100c62:	39 f2                	cmp    %esi,%edx
f0100c64:	73 3a                	jae    f0100ca0 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c66:	89 c2                	mov    %eax,%edx
f0100c68:	c1 ea 0c             	shr    $0xc,%edx
f0100c6b:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100c71:	72 12                	jb     f0100c85 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c73:	50                   	push   %eax
f0100c74:	68 a4 61 10 f0       	push   $0xf01061a4
f0100c79:	6a 58                	push   $0x58
f0100c7b:	68 d1 70 10 f0       	push   $0xf01070d1
f0100c80:	e8 bb f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c85:	83 ec 04             	sub    $0x4,%esp
f0100c88:	68 80 00 00 00       	push   $0x80
f0100c8d:	68 97 00 00 00       	push   $0x97
f0100c92:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c97:	50                   	push   %eax
f0100c98:	e8 28 48 00 00       	call   f01054c5 <memset>
f0100c9d:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ca0:	8b 1b                	mov    (%ebx),%ebx
f0100ca2:	85 db                	test   %ebx,%ebx
f0100ca4:	75 a9                	jne    f0100c4f <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ca6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cab:	e8 9b fe ff ff       	call   f0100b4b <boot_alloc>
f0100cb0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cb3:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cb9:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
		assert(pp < pages + npages);
f0100cbf:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0100cc4:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100cc7:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100cca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ccd:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cd0:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cd5:	e9 52 01 00 00       	jmp    f0100e2c <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cda:	39 ca                	cmp    %ecx,%edx
f0100cdc:	73 19                	jae    f0100cf7 <check_page_free_list+0x12b>
f0100cde:	68 df 70 10 f0       	push   $0xf01070df
f0100ce3:	68 eb 70 10 f0       	push   $0xf01070eb
f0100ce8:	68 12 03 00 00       	push   $0x312
f0100ced:	68 c5 70 10 f0       	push   $0xf01070c5
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cf7:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cfa:	72 19                	jb     f0100d15 <check_page_free_list+0x149>
f0100cfc:	68 00 71 10 f0       	push   $0xf0107100
f0100d01:	68 eb 70 10 f0       	push   $0xf01070eb
f0100d06:	68 13 03 00 00       	push   $0x313
f0100d0b:	68 c5 70 10 f0       	push   $0xf01070c5
f0100d10:	e8 2b f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d15:	89 d0                	mov    %edx,%eax
f0100d17:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100d1a:	a8 07                	test   $0x7,%al
f0100d1c:	74 19                	je     f0100d37 <check_page_free_list+0x16b>
f0100d1e:	68 68 67 10 f0       	push   $0xf0106768
f0100d23:	68 eb 70 10 f0       	push   $0xf01070eb
f0100d28:	68 14 03 00 00       	push   $0x314
f0100d2d:	68 c5 70 10 f0       	push   $0xf01070c5
f0100d32:	e8 09 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d37:	c1 f8 03             	sar    $0x3,%eax
f0100d3a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d3d:	85 c0                	test   %eax,%eax
f0100d3f:	75 19                	jne    f0100d5a <check_page_free_list+0x18e>
f0100d41:	68 14 71 10 f0       	push   $0xf0107114
f0100d46:	68 eb 70 10 f0       	push   $0xf01070eb
f0100d4b:	68 17 03 00 00       	push   $0x317
f0100d50:	68 c5 70 10 f0       	push   $0xf01070c5
f0100d55:	e8 e6 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d5a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d5f:	75 19                	jne    f0100d7a <check_page_free_list+0x1ae>
f0100d61:	68 25 71 10 f0       	push   $0xf0107125
f0100d66:	68 eb 70 10 f0       	push   $0xf01070eb
f0100d6b:	68 18 03 00 00       	push   $0x318
f0100d70:	68 c5 70 10 f0       	push   $0xf01070c5
f0100d75:	e8 c6 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d7a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d7f:	75 19                	jne    f0100d9a <check_page_free_list+0x1ce>
f0100d81:	68 9c 67 10 f0       	push   $0xf010679c
f0100d86:	68 eb 70 10 f0       	push   $0xf01070eb
f0100d8b:	68 19 03 00 00       	push   $0x319
f0100d90:	68 c5 70 10 f0       	push   $0xf01070c5
f0100d95:	e8 a6 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d9a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d9f:	75 19                	jne    f0100dba <check_page_free_list+0x1ee>
f0100da1:	68 3e 71 10 f0       	push   $0xf010713e
f0100da6:	68 eb 70 10 f0       	push   $0xf01070eb
f0100dab:	68 1a 03 00 00       	push   $0x31a
f0100db0:	68 c5 70 10 f0       	push   $0xf01070c5
f0100db5:	e8 86 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dba:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dbf:	0f 86 f1 00 00 00    	jbe    f0100eb6 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc5:	89 c7                	mov    %eax,%edi
f0100dc7:	c1 ef 0c             	shr    $0xc,%edi
f0100dca:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100dcd:	77 12                	ja     f0100de1 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dcf:	50                   	push   %eax
f0100dd0:	68 a4 61 10 f0       	push   $0xf01061a4
f0100dd5:	6a 58                	push   $0x58
f0100dd7:	68 d1 70 10 f0       	push   $0xf01070d1
f0100ddc:	e8 5f f2 ff ff       	call   f0100040 <_panic>
f0100de1:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100de7:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100dea:	0f 86 b6 00 00 00    	jbe    f0100ea6 <check_page_free_list+0x2da>
f0100df0:	68 c0 67 10 f0       	push   $0xf01067c0
f0100df5:	68 eb 70 10 f0       	push   $0xf01070eb
f0100dfa:	68 1b 03 00 00       	push   $0x31b
f0100dff:	68 c5 70 10 f0       	push   $0xf01070c5
f0100e04:	e8 37 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e09:	68 58 71 10 f0       	push   $0xf0107158
f0100e0e:	68 eb 70 10 f0       	push   $0xf01070eb
f0100e13:	68 1d 03 00 00       	push   $0x31d
f0100e18:	68 c5 70 10 f0       	push   $0xf01070c5
f0100e1d:	e8 1e f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100e22:	83 c6 01             	add    $0x1,%esi
f0100e25:	eb 03                	jmp    f0100e2a <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100e27:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e2a:	8b 12                	mov    (%edx),%edx
f0100e2c:	85 d2                	test   %edx,%edx
f0100e2e:	0f 85 a6 fe ff ff    	jne    f0100cda <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100e34:	85 f6                	test   %esi,%esi
f0100e36:	7f 19                	jg     f0100e51 <check_page_free_list+0x285>
f0100e38:	68 75 71 10 f0       	push   $0xf0107175
f0100e3d:	68 eb 70 10 f0       	push   $0xf01070eb
f0100e42:	68 25 03 00 00       	push   $0x325
f0100e47:	68 c5 70 10 f0       	push   $0xf01070c5
f0100e4c:	e8 ef f1 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e51:	85 db                	test   %ebx,%ebx
f0100e53:	7f 19                	jg     f0100e6e <check_page_free_list+0x2a2>
f0100e55:	68 87 71 10 f0       	push   $0xf0107187
f0100e5a:	68 eb 70 10 f0       	push   $0xf01070eb
f0100e5f:	68 26 03 00 00       	push   $0x326
f0100e64:	68 c5 70 10 f0       	push   $0xf01070c5
f0100e69:	e8 d2 f1 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e6e:	83 ec 0c             	sub    $0xc,%esp
f0100e71:	68 08 68 10 f0       	push   $0xf0106808
f0100e76:	e8 28 28 00 00       	call   f01036a3 <cprintf>
}
f0100e7b:	eb 49                	jmp    f0100ec6 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e7d:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0100e82:	85 c0                	test   %eax,%eax
f0100e84:	0f 85 6f fd ff ff    	jne    f0100bf9 <check_page_free_list+0x2d>
f0100e8a:	e9 53 fd ff ff       	jmp    f0100be2 <check_page_free_list+0x16>
f0100e8f:	83 3d 40 f2 22 f0 00 	cmpl   $0x0,0xf022f240
f0100e96:	0f 84 46 fd ff ff    	je     f0100be2 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e9c:	be 00 04 00 00       	mov    $0x400,%esi
f0100ea1:	e9 a1 fd ff ff       	jmp    f0100c47 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100ea6:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100eab:	0f 85 76 ff ff ff    	jne    f0100e27 <check_page_free_list+0x25b>
f0100eb1:	e9 53 ff ff ff       	jmp    f0100e09 <check_page_free_list+0x23d>
f0100eb6:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100ebb:	0f 85 61 ff ff ff    	jne    f0100e22 <check_page_free_list+0x256>
f0100ec1:	e9 43 ff ff ff       	jmp    f0100e09 <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100ec6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ec9:	5b                   	pop    %ebx
f0100eca:	5e                   	pop    %esi
f0100ecb:	5f                   	pop    %edi
f0100ecc:	5d                   	pop    %ebp
f0100ecd:	c3                   	ret    

f0100ece <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ece:	55                   	push   %ebp
f0100ecf:	89 e5                	mov    %esp,%ebp
f0100ed1:	57                   	push   %edi
f0100ed2:	56                   	push   %esi
f0100ed3:	53                   	push   %ebx
f0100ed4:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	
f0100ed7:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100edc:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

	for (i = 1; i < npages; ++i) 
f0100ee2:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100ee7:	be 08 00 00 00       	mov    $0x8,%esi
f0100eec:	bf 01 00 00 00       	mov    $0x1,%edi
f0100ef1:	e9 c5 00 00 00       	jmp    f0100fbb <page_init+0xed>
	{
		if((i*PGSIZE  >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM))
f0100ef6:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100efc:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100f01:	77 19                	ja     f0100f1c <page_init+0x4e>
		{
			pages[i].pp_ref = 1;
f0100f03:	89 f0                	mov    %esi,%eax
f0100f05:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f0b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f11:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;	
f0100f17:	e9 93 00 00 00       	jmp    f0100faf <page_init+0xe1>
		}

		if((i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))))
f0100f1c:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100f22:	76 45                	jbe    f0100f69 <page_init+0x9b>
f0100f24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f29:	e8 1d fc ff ff       	call   f0100b4b <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f2e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f33:	77 15                	ja     f0100f4a <page_init+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f35:	50                   	push   %eax
f0100f36:	68 c8 61 10 f0       	push   $0xf01061c8
f0100f3b:	68 5a 01 00 00       	push   $0x15a
f0100f40:	68 c5 70 10 f0       	push   $0xf01070c5
f0100f45:	e8 f6 f0 ff ff       	call   f0100040 <_panic>
f0100f4a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f4f:	39 d8                	cmp    %ebx,%eax
f0100f51:	76 16                	jbe    f0100f69 <page_init+0x9b>
		{
			pages[i].pp_ref = 1;
f0100f53:	89 f0                	mov    %esi,%eax
f0100f55:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f5b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f61:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f67:	eb 46                	jmp    f0100faf <page_init+0xe1>
		}

		if((i * PGSIZE >= MPENTRY_PADDR) && (i * PGSIZE < MPENTRY_PADDR + PGSIZE))
f0100f69:	8d 83 00 90 ff ff    	lea    -0x7000(%ebx),%eax
f0100f6f:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0100f74:	77 16                	ja     f0100f8c <page_init+0xbe>
		{
			pages[i].pp_ref = 1;
f0100f76:	89 f0                	mov    %esi,%eax
f0100f78:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f7e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f84:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f8a:	eb 23                	jmp    f0100faf <page_init+0xe1>
		}
			
		pages[i].pp_ref = 0;  
f0100f8c:	89 f0                	mov    %esi,%eax
f0100f8e:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f94:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f9a:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100fa0:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100fa2:	89 f0                	mov    %esi,%eax
f0100fa4:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100faa:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	

	for (i = 1; i < npages; ++i) 
f0100faf:	83 c7 01             	add    $0x1,%edi
f0100fb2:	83 c6 08             	add    $0x8,%esi
f0100fb5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100fbb:	3b 3d 88 fe 22 f0    	cmp    0xf022fe88,%edi
f0100fc1:	0f 82 2f ff ff ff    	jb     f0100ef6 <page_init+0x28>
			
		pages[i].pp_ref = 0;  
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100fc7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fca:	5b                   	pop    %ebx
f0100fcb:	5e                   	pop    %esi
f0100fcc:	5f                   	pop    %edi
f0100fcd:	5d                   	pop    %ebp
f0100fce:	c3                   	ret    

f0100fcf <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fcf:	55                   	push   %ebp
f0100fd0:	89 e5                	mov    %esp,%ebp
f0100fd2:	53                   	push   %ebx
f0100fd3:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL) 
f0100fd6:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100fdc:	85 db                	test   %ebx,%ebx
f0100fde:	74 58                	je     f0101038 <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100fe0:	8b 03                	mov    (%ebx),%eax
f0100fe2:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	page->pp_link = NULL;
f0100fe7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100fed:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ff1:	74 45                	je     f0101038 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ff3:	89 d8                	mov    %ebx,%eax
f0100ff5:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100ffb:	c1 f8 03             	sar    $0x3,%eax
f0100ffe:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101001:	89 c2                	mov    %eax,%edx
f0101003:	c1 ea 0c             	shr    $0xc,%edx
f0101006:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f010100c:	72 12                	jb     f0101020 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010100e:	50                   	push   %eax
f010100f:	68 a4 61 10 f0       	push   $0xf01061a4
f0101014:	6a 58                	push   $0x58
f0101016:	68 d1 70 10 f0       	push   $0xf01070d1
f010101b:	e8 20 f0 ff ff       	call   f0100040 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0101020:	83 ec 04             	sub    $0x4,%esp
f0101023:	68 00 10 00 00       	push   $0x1000
f0101028:	6a 00                	push   $0x0
f010102a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010102f:	50                   	push   %eax
f0101030:	e8 90 44 00 00       	call   f01054c5 <memset>
f0101035:	83 c4 10             	add    $0x10,%esp
	}

	return page;
}
f0101038:	89 d8                	mov    %ebx,%eax
f010103a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010103d:	c9                   	leave  
f010103e:	c3                   	ret    

f010103f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010103f:	55                   	push   %ebp
f0101040:	89 e5                	mov    %esp,%ebp
f0101042:	83 ec 08             	sub    $0x8,%esp
f0101045:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref != 0) || (pp->pp_link != NULL)) 
f0101048:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010104d:	75 05                	jne    f0101054 <page_free+0x15>
f010104f:	83 38 00             	cmpl   $0x0,(%eax)
f0101052:	74 17                	je     f010106b <page_free+0x2c>
		panic("page_free: cannot free the page which is still in use!\n");
f0101054:	83 ec 04             	sub    $0x4,%esp
f0101057:	68 2c 68 10 f0       	push   $0xf010682c
f010105c:	68 9b 01 00 00       	push   $0x19b
f0101061:	68 c5 70 10 f0       	push   $0xf01070c5
f0101066:	e8 d5 ef ff ff       	call   f0100040 <_panic>

	
	pp->pp_link  = page_free_list;
f010106b:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0101071:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;	
f0101073:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
}
f0101078:	c9                   	leave  
f0101079:	c3                   	ret    

f010107a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010107a:	55                   	push   %ebp
f010107b:	89 e5                	mov    %esp,%ebp
f010107d:	83 ec 08             	sub    $0x8,%esp
f0101080:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101083:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101087:	83 e8 01             	sub    $0x1,%eax
f010108a:	66 89 42 04          	mov    %ax,0x4(%edx)
f010108e:	66 85 c0             	test   %ax,%ax
f0101091:	75 0c                	jne    f010109f <page_decref+0x25>
		page_free(pp);
f0101093:	83 ec 0c             	sub    $0xc,%esp
f0101096:	52                   	push   %edx
f0101097:	e8 a3 ff ff ff       	call   f010103f <page_free>
f010109c:	83 c4 10             	add    $0x10,%esp
}
f010109f:	c9                   	leave  
f01010a0:	c3                   	ret    

f01010a1 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01010a1:	55                   	push   %ebp
f01010a2:	89 e5                	mov    %esp,%ebp
f01010a4:	56                   	push   %esi
f01010a5:	53                   	push   %ebx
f01010a6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	size_t dirIndex = PDX(va);
	size_t tableIndex = PTX(va);
f01010a9:	89 de                	mov    %ebx,%esi
f01010ab:	c1 ee 0c             	shr    $0xc,%esi
f01010ae:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];
f01010b4:	c1 eb 16             	shr    $0x16,%ebx
f01010b7:	c1 e3 02             	shl    $0x2,%ebx
f01010ba:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pdir_entry & PTE_P))
f01010bd:	8b 03                	mov    (%ebx),%eax
f01010bf:	a8 01                	test   $0x1,%al
f01010c1:	75 6c                	jne    f010112f <pgdir_walk+0x8e>
	{
		if(create == false) 
f01010c3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010c7:	0f 84 93 00 00 00    	je     f0101160 <pgdir_walk+0xbf>
			return NULL;

		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01010cd:	83 ec 0c             	sub    $0xc,%esp
f01010d0:	6a 01                	push   $0x1
f01010d2:	e8 f8 fe ff ff       	call   f0100fcf <page_alloc>

		if(page == NULL) 
f01010d7:	83 c4 10             	add    $0x10,%esp
f01010da:	85 c0                	test   %eax,%eax
f01010dc:	0f 84 85 00 00 00    	je     f0101167 <pgdir_walk+0xc6>
			return NULL;

		page->pp_ref++;
f01010e2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

		*pdir_entry = page2pa(page) | PTE_P | PTE_W | PTE_U;
f01010e7:	89 c2                	mov    %eax,%edx
f01010e9:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f01010ef:	c1 fa 03             	sar    $0x3,%edx
f01010f2:	c1 e2 0c             	shl    $0xc,%edx
f01010f5:	83 ca 07             	or     $0x7,%edx
f01010f8:	89 13                	mov    %edx,(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010fa:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101100:	c1 f8 03             	sar    $0x3,%eax
f0101103:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101106:	89 c2                	mov    %eax,%edx
f0101108:	c1 ea 0c             	shr    $0xc,%edx
f010110b:	39 15 88 fe 22 f0    	cmp    %edx,0xf022fe88
f0101111:	77 15                	ja     f0101128 <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101113:	50                   	push   %eax
f0101114:	68 a4 61 10 f0       	push   $0xf01061a4
f0101119:	68 dd 01 00 00       	push   $0x1dd
f010111e:	68 c5 70 10 f0       	push   $0xf01070c5
f0101123:	e8 18 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101128:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010112d:	eb 2c                	jmp    f010115b <pgdir_walk+0xba>
		
		ptable_entry = (pte_t*) KADDR(page2pa(page));
	}
	else
	{
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
f010112f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101134:	89 c2                	mov    %eax,%edx
f0101136:	c1 ea 0c             	shr    $0xc,%edx
f0101139:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f010113f:	72 15                	jb     f0101156 <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101141:	50                   	push   %eax
f0101142:	68 a4 61 10 f0       	push   $0xf01061a4
f0101147:	68 e1 01 00 00       	push   $0x1e1
f010114c:	68 c5 70 10 f0       	push   $0xf01070c5
f0101151:	e8 ea ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101156:	2d 00 00 00 10       	sub    $0x10000000,%eax
	}
	
	return ptable_entry + tableIndex;
f010115b:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f010115e:	eb 0c                	jmp    f010116c <pgdir_walk+0xcb>
	pde_t *pdir_entry = &pgdir[dirIndex];

	if(!(*pdir_entry & PTE_P))
	{
		if(create == false) 
			return NULL;
f0101160:	b8 00 00 00 00       	mov    $0x0,%eax
f0101165:	eb 05                	jmp    f010116c <pgdir_walk+0xcb>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);

		if(page == NULL) 
			return NULL;
f0101167:	b8 00 00 00 00       	mov    $0x0,%eax
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
	}
	
	return ptable_entry + tableIndex;

}
f010116c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010116f:	5b                   	pop    %ebx
f0101170:	5e                   	pop    %esi
f0101171:	5d                   	pop    %ebp
f0101172:	c3                   	ret    

f0101173 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101173:	55                   	push   %ebp
f0101174:	89 e5                	mov    %esp,%ebp
f0101176:	57                   	push   %edi
f0101177:	56                   	push   %esi
f0101178:	53                   	push   %ebx
f0101179:	83 ec 1c             	sub    $0x1c,%esp
f010117c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010117f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0101182:	c1 e9 0c             	shr    $0xc,%ecx
f0101185:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101188:	89 c3                	mov    %eax,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;
f010118a:	be 00 00 00 00       	mov    $0x0,%esi

	for(i; i < size/PGSIZE; ++i)
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f010118f:	89 d7                	mov    %edx,%edi
f0101191:	29 c7                	sub    %eax,%edi

		if(ptable_entry == NULL)
			panic("boot_map_region: Failed to allocate new PTE!");
		
		*ptable_entry = pa | perm | PTE_P;
f0101193:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101196:	83 c8 01             	or     $0x1,%eax
f0101199:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f010119c:	eb 3f                	jmp    f01011dd <boot_map_region+0x6a>
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f010119e:	83 ec 04             	sub    $0x4,%esp
f01011a1:	6a 01                	push   $0x1
f01011a3:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f01011a6:	50                   	push   %eax
f01011a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01011aa:	e8 f2 fe ff ff       	call   f01010a1 <pgdir_walk>

		if(ptable_entry == NULL)
f01011af:	83 c4 10             	add    $0x10,%esp
f01011b2:	85 c0                	test   %eax,%eax
f01011b4:	75 17                	jne    f01011cd <boot_map_region+0x5a>
			panic("boot_map_region: Failed to allocate new PTE!");
f01011b6:	83 ec 04             	sub    $0x4,%esp
f01011b9:	68 64 68 10 f0       	push   $0xf0106864
f01011be:	68 fe 01 00 00       	push   $0x1fe
f01011c3:	68 c5 70 10 f0       	push   $0xf01070c5
f01011c8:	e8 73 ee ff ff       	call   f0100040 <_panic>
		
		*ptable_entry = pa | perm | PTE_P;
f01011cd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011d0:	09 da                	or     %ebx,%edx
f01011d2:	89 10                	mov    %edx,(%eax)

		pa += PGSIZE;
f01011d4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f01011da:	83 c6 01             	add    $0x1,%esi
f01011dd:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01011e0:	75 bc                	jne    f010119e <boot_map_region+0x2b>

		pa += PGSIZE;
		va += PGSIZE;
	}
		
}
f01011e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011e5:	5b                   	pop    %ebx
f01011e6:	5e                   	pop    %esi
f01011e7:	5f                   	pop    %edi
f01011e8:	5d                   	pop    %ebp
f01011e9:	c3                   	ret    

f01011ea <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011ea:	55                   	push   %ebp
f01011eb:	89 e5                	mov    %esp,%ebp
f01011ed:	53                   	push   %ebx
f01011ee:	83 ec 08             	sub    $0x8,%esp
f01011f1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
f01011f4:	6a 00                	push   $0x0
f01011f6:	ff 75 0c             	pushl  0xc(%ebp)
f01011f9:	ff 75 08             	pushl  0x8(%ebp)
f01011fc:	e8 a0 fe ff ff       	call   f01010a1 <pgdir_walk>
	
	if(!ptEntry) 
f0101201:	83 c4 10             	add    $0x10,%esp
f0101204:	85 c0                	test   %eax,%eax
f0101206:	74 32                	je     f010123a <page_lookup+0x50>
		return NULL;

	if(pte_store)
f0101208:	85 db                	test   %ebx,%ebx
f010120a:	74 02                	je     f010120e <page_lookup+0x24>
	{
		*pte_store = ptEntry;
f010120c:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010120e:	8b 00                	mov    (%eax),%eax
f0101210:	c1 e8 0c             	shr    $0xc,%eax
f0101213:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0101219:	72 14                	jb     f010122f <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f010121b:	83 ec 04             	sub    $0x4,%esp
f010121e:	68 94 68 10 f0       	push   $0xf0106894
f0101223:	6a 51                	push   $0x51
f0101225:	68 d1 70 10 f0       	push   $0xf01070d1
f010122a:	e8 11 ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010122f:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0101235:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
f0101238:	eb 05                	jmp    f010123f <page_lookup+0x55>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
	
	if(!ptEntry) 
		return NULL;
f010123a:	b8 00 00 00 00       	mov    $0x0,%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
}
f010123f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101242:	c9                   	leave  
f0101243:	c3                   	ret    

f0101244 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101244:	55                   	push   %ebp
f0101245:	89 e5                	mov    %esp,%ebp
f0101247:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010124a:	e8 97 48 00 00       	call   f0105ae6 <cpunum>
f010124f:	6b c0 74             	imul   $0x74,%eax,%eax
f0101252:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0101259:	74 16                	je     f0101271 <tlb_invalidate+0x2d>
f010125b:	e8 86 48 00 00       	call   f0105ae6 <cpunum>
f0101260:	6b c0 74             	imul   $0x74,%eax,%eax
f0101263:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0101269:	8b 55 08             	mov    0x8(%ebp),%edx
f010126c:	39 50 60             	cmp    %edx,0x60(%eax)
f010126f:	75 06                	jne    f0101277 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101271:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101274:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101277:	c9                   	leave  
f0101278:	c3                   	ret    

f0101279 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101279:	55                   	push   %ebp
f010127a:	89 e5                	mov    %esp,%ebp
f010127c:	56                   	push   %esi
f010127d:	53                   	push   %ebx
f010127e:	83 ec 14             	sub    $0x14,%esp
f0101281:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101284:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *ptEntry = NULL;
f0101287:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &ptEntry);
f010128e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101291:	50                   	push   %eax
f0101292:	56                   	push   %esi
f0101293:	53                   	push   %ebx
f0101294:	e8 51 ff ff ff       	call   f01011ea <page_lookup>

	if(!page || !(*ptEntry & PTE_P)) 
f0101299:	83 c4 10             	add    $0x10,%esp
f010129c:	85 c0                	test   %eax,%eax
f010129e:	74 27                	je     f01012c7 <page_remove+0x4e>
f01012a0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01012a3:	f6 02 01             	testb  $0x1,(%edx)
f01012a6:	74 1f                	je     f01012c7 <page_remove+0x4e>
		return;

	page_decref(page);
f01012a8:	83 ec 0c             	sub    $0xc,%esp
f01012ab:	50                   	push   %eax
f01012ac:	e8 c9 fd ff ff       	call   f010107a <page_decref>

	*ptEntry = 0;
f01012b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	tlb_invalidate(pgdir, va);
f01012ba:	83 c4 08             	add    $0x8,%esp
f01012bd:	56                   	push   %esi
f01012be:	53                   	push   %ebx
f01012bf:	e8 80 ff ff ff       	call   f0101244 <tlb_invalidate>
f01012c4:	83 c4 10             	add    $0x10,%esp
}
f01012c7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012ca:	5b                   	pop    %ebx
f01012cb:	5e                   	pop    %esi
f01012cc:	5d                   	pop    %ebp
f01012cd:	c3                   	ret    

f01012ce <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012ce:	55                   	push   %ebp
f01012cf:	89 e5                	mov    %esp,%ebp
f01012d1:	57                   	push   %edi
f01012d2:	56                   	push   %esi
f01012d3:	53                   	push   %ebx
f01012d4:	83 ec 10             	sub    $0x10,%esp
f01012d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01012da:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
f01012dd:	6a 01                	push   $0x1
f01012df:	57                   	push   %edi
f01012e0:	ff 75 08             	pushl  0x8(%ebp)
f01012e3:	e8 b9 fd ff ff       	call   f01010a1 <pgdir_walk>
	
	if(!ptEntry) 
f01012e8:	83 c4 10             	add    $0x10,%esp
f01012eb:	85 c0                	test   %eax,%eax
f01012ed:	74 44                	je     f0101333 <page_insert+0x65>
f01012ef:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	
	pp->pp_ref++;
f01012f1:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*ptEntry & PTE_P)
f01012f6:	f6 00 01             	testb  $0x1,(%eax)
f01012f9:	74 1b                	je     f0101316 <page_insert+0x48>
	{
		page_remove(pgdir, va);
f01012fb:	83 ec 08             	sub    $0x8,%esp
f01012fe:	57                   	push   %edi
f01012ff:	ff 75 08             	pushl  0x8(%ebp)
f0101302:	e8 72 ff ff ff       	call   f0101279 <page_remove>
		tlb_invalidate(pgdir, va);
f0101307:	83 c4 08             	add    $0x8,%esp
f010130a:	57                   	push   %edi
f010130b:	ff 75 08             	pushl  0x8(%ebp)
f010130e:	e8 31 ff ff ff       	call   f0101244 <tlb_invalidate>
f0101313:	83 c4 10             	add    $0x10,%esp
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;
f0101316:	2b 1d 90 fe 22 f0    	sub    0xf022fe90,%ebx
f010131c:	c1 fb 03             	sar    $0x3,%ebx
f010131f:	c1 e3 0c             	shl    $0xc,%ebx
f0101322:	8b 45 14             	mov    0x14(%ebp),%eax
f0101325:	83 c8 01             	or     $0x1,%eax
f0101328:	09 c3                	or     %eax,%ebx
f010132a:	89 1e                	mov    %ebx,(%esi)

	return 0;
f010132c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101331:	eb 05                	jmp    f0101338 <page_insert+0x6a>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
	
	if(!ptEntry) 
		return -E_NO_MEM;
f0101333:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;

	return 0;
}
f0101338:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010133b:	5b                   	pop    %ebx
f010133c:	5e                   	pop    %esi
f010133d:	5f                   	pop    %edi
f010133e:	5d                   	pop    %ebp
f010133f:	c3                   	ret    

f0101340 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101340:	55                   	push   %ebp
f0101341:	89 e5                	mov    %esp,%ebp
f0101343:	53                   	push   %ebx
f0101344:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f0101347:	8b 45 0c             	mov    0xc(%ebp),%eax
f010134a:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101350:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	if(base + size >= MMIOLIM)
f0101356:	8b 15 00 03 12 f0    	mov    0xf0120300,%edx
f010135c:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f010135f:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101364:	76 17                	jbe    f010137d <mmio_map_region+0x3d>
		panic("mmio_map_region: Not enough memory!");
f0101366:	83 ec 04             	sub    $0x4,%esp
f0101369:	68 b4 68 10 f0       	push   $0xf01068b4
f010136e:	68 a4 02 00 00       	push   $0x2a4
f0101373:	68 c5 70 10 f0       	push   $0xf01070c5
f0101378:	e8 c3 ec ff ff       	call   f0100040 <_panic>
	
	boot_map_region(kern_pgdir, base, size, pa, (PTE_PCD | PTE_PWT | PTE_W));
f010137d:	83 ec 08             	sub    $0x8,%esp
f0101380:	6a 1a                	push   $0x1a
f0101382:	ff 75 08             	pushl  0x8(%ebp)
f0101385:	89 d9                	mov    %ebx,%ecx
f0101387:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010138c:	e8 e2 fd ff ff       	call   f0101173 <boot_map_region>

	base += size;
f0101391:	a1 00 03 12 f0       	mov    0xf0120300,%eax
f0101396:	01 c3                	add    %eax,%ebx
f0101398:	89 1d 00 03 12 f0    	mov    %ebx,0xf0120300

	return (void *) (base - size);
	
}
f010139e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013a1:	c9                   	leave  
f01013a2:	c3                   	ret    

f01013a3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01013a3:	55                   	push   %ebp
f01013a4:	89 e5                	mov    %esp,%ebp
f01013a6:	57                   	push   %edi
f01013a7:	56                   	push   %esi
f01013a8:	53                   	push   %ebx
f01013a9:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01013ac:	b8 15 00 00 00       	mov    $0x15,%eax
f01013b1:	e8 08 f7 ff ff       	call   f0100abe <nvram_read>
f01013b6:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01013b8:	b8 17 00 00 00       	mov    $0x17,%eax
f01013bd:	e8 fc f6 ff ff       	call   f0100abe <nvram_read>
f01013c2:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013c4:	b8 34 00 00 00       	mov    $0x34,%eax
f01013c9:	e8 f0 f6 ff ff       	call   f0100abe <nvram_read>
f01013ce:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01013d1:	85 c0                	test   %eax,%eax
f01013d3:	74 07                	je     f01013dc <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01013d5:	05 00 40 00 00       	add    $0x4000,%eax
f01013da:	eb 0b                	jmp    f01013e7 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01013dc:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013e2:	85 f6                	test   %esi,%esi
f01013e4:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01013e7:	89 c2                	mov    %eax,%edx
f01013e9:	c1 ea 02             	shr    $0x2,%edx
f01013ec:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013f2:	89 c2                	mov    %eax,%edx
f01013f4:	29 da                	sub    %ebx,%edx
f01013f6:	52                   	push   %edx
f01013f7:	53                   	push   %ebx
f01013f8:	50                   	push   %eax
f01013f9:	68 d8 68 10 f0       	push   $0xf01068d8
f01013fe:	e8 a0 22 00 00       	call   f01036a3 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101403:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101408:	e8 3e f7 ff ff       	call   f0100b4b <boot_alloc>
f010140d:	a3 8c fe 22 f0       	mov    %eax,0xf022fe8c
	memset(kern_pgdir, 0, PGSIZE);
f0101412:	83 c4 0c             	add    $0xc,%esp
f0101415:	68 00 10 00 00       	push   $0x1000
f010141a:	6a 00                	push   $0x0
f010141c:	50                   	push   %eax
f010141d:	e8 a3 40 00 00       	call   f01054c5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101422:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101427:	83 c4 10             	add    $0x10,%esp
f010142a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010142f:	77 15                	ja     f0101446 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101431:	50                   	push   %eax
f0101432:	68 c8 61 10 f0       	push   $0xf01061c8
f0101437:	68 a5 00 00 00       	push   $0xa5
f010143c:	68 c5 70 10 f0       	push   $0xf01070c5
f0101441:	e8 fa eb ff ff       	call   f0100040 <_panic>
f0101446:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010144c:	83 ca 05             	or     $0x5,%edx
f010144f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof(struct PageInfo)*npages);
f0101455:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010145a:	c1 e0 03             	shl    $0x3,%eax
f010145d:	e8 e9 f6 ff ff       	call   f0100b4b <boot_alloc>
f0101462:	a3 90 fe 22 f0       	mov    %eax,0xf022fe90
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f0101467:	83 ec 04             	sub    $0x4,%esp
f010146a:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0101470:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101477:	52                   	push   %edx
f0101478:	6a 00                	push   $0x0
f010147a:	50                   	push   %eax
f010147b:	e8 45 40 00 00       	call   f01054c5 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f0101480:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101485:	e8 c1 f6 ff ff       	call   f0100b4b <boot_alloc>
f010148a:	a3 44 f2 22 f0       	mov    %eax,0xf022f244
	memset(envs, '\0', sizeof(struct Env) * NENV);
f010148f:	83 c4 0c             	add    $0xc,%esp
f0101492:	68 00 f0 01 00       	push   $0x1f000
f0101497:	6a 00                	push   $0x0
f0101499:	50                   	push   %eax
f010149a:	e8 26 40 00 00       	call   f01054c5 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010149f:	e8 2a fa ff ff       	call   f0100ece <page_init>

	check_page_free_list(1);
f01014a4:	b8 01 00 00 00       	mov    $0x1,%eax
f01014a9:	e8 1e f7 ff ff       	call   f0100bcc <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01014ae:	83 c4 10             	add    $0x10,%esp
f01014b1:	83 3d 90 fe 22 f0 00 	cmpl   $0x0,0xf022fe90
f01014b8:	75 17                	jne    f01014d1 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f01014ba:	83 ec 04             	sub    $0x4,%esp
f01014bd:	68 98 71 10 f0       	push   $0xf0107198
f01014c2:	68 39 03 00 00       	push   $0x339
f01014c7:	68 c5 70 10 f0       	push   $0xf01070c5
f01014cc:	e8 6f eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014d1:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01014d6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014db:	eb 05                	jmp    f01014e2 <mem_init+0x13f>
		++nfree;
f01014dd:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014e0:	8b 00                	mov    (%eax),%eax
f01014e2:	85 c0                	test   %eax,%eax
f01014e4:	75 f7                	jne    f01014dd <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014e6:	83 ec 0c             	sub    $0xc,%esp
f01014e9:	6a 00                	push   $0x0
f01014eb:	e8 df fa ff ff       	call   f0100fcf <page_alloc>
f01014f0:	89 c7                	mov    %eax,%edi
f01014f2:	83 c4 10             	add    $0x10,%esp
f01014f5:	85 c0                	test   %eax,%eax
f01014f7:	75 19                	jne    f0101512 <mem_init+0x16f>
f01014f9:	68 b3 71 10 f0       	push   $0xf01071b3
f01014fe:	68 eb 70 10 f0       	push   $0xf01070eb
f0101503:	68 41 03 00 00       	push   $0x341
f0101508:	68 c5 70 10 f0       	push   $0xf01070c5
f010150d:	e8 2e eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101512:	83 ec 0c             	sub    $0xc,%esp
f0101515:	6a 00                	push   $0x0
f0101517:	e8 b3 fa ff ff       	call   f0100fcf <page_alloc>
f010151c:	89 c6                	mov    %eax,%esi
f010151e:	83 c4 10             	add    $0x10,%esp
f0101521:	85 c0                	test   %eax,%eax
f0101523:	75 19                	jne    f010153e <mem_init+0x19b>
f0101525:	68 c9 71 10 f0       	push   $0xf01071c9
f010152a:	68 eb 70 10 f0       	push   $0xf01070eb
f010152f:	68 42 03 00 00       	push   $0x342
f0101534:	68 c5 70 10 f0       	push   $0xf01070c5
f0101539:	e8 02 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010153e:	83 ec 0c             	sub    $0xc,%esp
f0101541:	6a 00                	push   $0x0
f0101543:	e8 87 fa ff ff       	call   f0100fcf <page_alloc>
f0101548:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010154b:	83 c4 10             	add    $0x10,%esp
f010154e:	85 c0                	test   %eax,%eax
f0101550:	75 19                	jne    f010156b <mem_init+0x1c8>
f0101552:	68 df 71 10 f0       	push   $0xf01071df
f0101557:	68 eb 70 10 f0       	push   $0xf01070eb
f010155c:	68 43 03 00 00       	push   $0x343
f0101561:	68 c5 70 10 f0       	push   $0xf01070c5
f0101566:	e8 d5 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010156b:	39 f7                	cmp    %esi,%edi
f010156d:	75 19                	jne    f0101588 <mem_init+0x1e5>
f010156f:	68 f5 71 10 f0       	push   $0xf01071f5
f0101574:	68 eb 70 10 f0       	push   $0xf01070eb
f0101579:	68 46 03 00 00       	push   $0x346
f010157e:	68 c5 70 10 f0       	push   $0xf01070c5
f0101583:	e8 b8 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101588:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010158b:	39 c6                	cmp    %eax,%esi
f010158d:	74 04                	je     f0101593 <mem_init+0x1f0>
f010158f:	39 c7                	cmp    %eax,%edi
f0101591:	75 19                	jne    f01015ac <mem_init+0x209>
f0101593:	68 14 69 10 f0       	push   $0xf0106914
f0101598:	68 eb 70 10 f0       	push   $0xf01070eb
f010159d:	68 47 03 00 00       	push   $0x347
f01015a2:	68 c5 70 10 f0       	push   $0xf01070c5
f01015a7:	e8 94 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015ac:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01015b2:	8b 15 88 fe 22 f0    	mov    0xf022fe88,%edx
f01015b8:	c1 e2 0c             	shl    $0xc,%edx
f01015bb:	89 f8                	mov    %edi,%eax
f01015bd:	29 c8                	sub    %ecx,%eax
f01015bf:	c1 f8 03             	sar    $0x3,%eax
f01015c2:	c1 e0 0c             	shl    $0xc,%eax
f01015c5:	39 d0                	cmp    %edx,%eax
f01015c7:	72 19                	jb     f01015e2 <mem_init+0x23f>
f01015c9:	68 07 72 10 f0       	push   $0xf0107207
f01015ce:	68 eb 70 10 f0       	push   $0xf01070eb
f01015d3:	68 48 03 00 00       	push   $0x348
f01015d8:	68 c5 70 10 f0       	push   $0xf01070c5
f01015dd:	e8 5e ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01015e2:	89 f0                	mov    %esi,%eax
f01015e4:	29 c8                	sub    %ecx,%eax
f01015e6:	c1 f8 03             	sar    $0x3,%eax
f01015e9:	c1 e0 0c             	shl    $0xc,%eax
f01015ec:	39 c2                	cmp    %eax,%edx
f01015ee:	77 19                	ja     f0101609 <mem_init+0x266>
f01015f0:	68 24 72 10 f0       	push   $0xf0107224
f01015f5:	68 eb 70 10 f0       	push   $0xf01070eb
f01015fa:	68 49 03 00 00       	push   $0x349
f01015ff:	68 c5 70 10 f0       	push   $0xf01070c5
f0101604:	e8 37 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101609:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010160c:	29 c8                	sub    %ecx,%eax
f010160e:	c1 f8 03             	sar    $0x3,%eax
f0101611:	c1 e0 0c             	shl    $0xc,%eax
f0101614:	39 c2                	cmp    %eax,%edx
f0101616:	77 19                	ja     f0101631 <mem_init+0x28e>
f0101618:	68 41 72 10 f0       	push   $0xf0107241
f010161d:	68 eb 70 10 f0       	push   $0xf01070eb
f0101622:	68 4a 03 00 00       	push   $0x34a
f0101627:	68 c5 70 10 f0       	push   $0xf01070c5
f010162c:	e8 0f ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101631:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101636:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101639:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101640:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101643:	83 ec 0c             	sub    $0xc,%esp
f0101646:	6a 00                	push   $0x0
f0101648:	e8 82 f9 ff ff       	call   f0100fcf <page_alloc>
f010164d:	83 c4 10             	add    $0x10,%esp
f0101650:	85 c0                	test   %eax,%eax
f0101652:	74 19                	je     f010166d <mem_init+0x2ca>
f0101654:	68 5e 72 10 f0       	push   $0xf010725e
f0101659:	68 eb 70 10 f0       	push   $0xf01070eb
f010165e:	68 51 03 00 00       	push   $0x351
f0101663:	68 c5 70 10 f0       	push   $0xf01070c5
f0101668:	e8 d3 e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010166d:	83 ec 0c             	sub    $0xc,%esp
f0101670:	57                   	push   %edi
f0101671:	e8 c9 f9 ff ff       	call   f010103f <page_free>
	page_free(pp1);
f0101676:	89 34 24             	mov    %esi,(%esp)
f0101679:	e8 c1 f9 ff ff       	call   f010103f <page_free>
	page_free(pp2);
f010167e:	83 c4 04             	add    $0x4,%esp
f0101681:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101684:	e8 b6 f9 ff ff       	call   f010103f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101689:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101690:	e8 3a f9 ff ff       	call   f0100fcf <page_alloc>
f0101695:	89 c6                	mov    %eax,%esi
f0101697:	83 c4 10             	add    $0x10,%esp
f010169a:	85 c0                	test   %eax,%eax
f010169c:	75 19                	jne    f01016b7 <mem_init+0x314>
f010169e:	68 b3 71 10 f0       	push   $0xf01071b3
f01016a3:	68 eb 70 10 f0       	push   $0xf01070eb
f01016a8:	68 58 03 00 00       	push   $0x358
f01016ad:	68 c5 70 10 f0       	push   $0xf01070c5
f01016b2:	e8 89 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016b7:	83 ec 0c             	sub    $0xc,%esp
f01016ba:	6a 00                	push   $0x0
f01016bc:	e8 0e f9 ff ff       	call   f0100fcf <page_alloc>
f01016c1:	89 c7                	mov    %eax,%edi
f01016c3:	83 c4 10             	add    $0x10,%esp
f01016c6:	85 c0                	test   %eax,%eax
f01016c8:	75 19                	jne    f01016e3 <mem_init+0x340>
f01016ca:	68 c9 71 10 f0       	push   $0xf01071c9
f01016cf:	68 eb 70 10 f0       	push   $0xf01070eb
f01016d4:	68 59 03 00 00       	push   $0x359
f01016d9:	68 c5 70 10 f0       	push   $0xf01070c5
f01016de:	e8 5d e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016e3:	83 ec 0c             	sub    $0xc,%esp
f01016e6:	6a 00                	push   $0x0
f01016e8:	e8 e2 f8 ff ff       	call   f0100fcf <page_alloc>
f01016ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016f0:	83 c4 10             	add    $0x10,%esp
f01016f3:	85 c0                	test   %eax,%eax
f01016f5:	75 19                	jne    f0101710 <mem_init+0x36d>
f01016f7:	68 df 71 10 f0       	push   $0xf01071df
f01016fc:	68 eb 70 10 f0       	push   $0xf01070eb
f0101701:	68 5a 03 00 00       	push   $0x35a
f0101706:	68 c5 70 10 f0       	push   $0xf01070c5
f010170b:	e8 30 e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101710:	39 fe                	cmp    %edi,%esi
f0101712:	75 19                	jne    f010172d <mem_init+0x38a>
f0101714:	68 f5 71 10 f0       	push   $0xf01071f5
f0101719:	68 eb 70 10 f0       	push   $0xf01070eb
f010171e:	68 5c 03 00 00       	push   $0x35c
f0101723:	68 c5 70 10 f0       	push   $0xf01070c5
f0101728:	e8 13 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010172d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101730:	39 c7                	cmp    %eax,%edi
f0101732:	74 04                	je     f0101738 <mem_init+0x395>
f0101734:	39 c6                	cmp    %eax,%esi
f0101736:	75 19                	jne    f0101751 <mem_init+0x3ae>
f0101738:	68 14 69 10 f0       	push   $0xf0106914
f010173d:	68 eb 70 10 f0       	push   $0xf01070eb
f0101742:	68 5d 03 00 00       	push   $0x35d
f0101747:	68 c5 70 10 f0       	push   $0xf01070c5
f010174c:	e8 ef e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101751:	83 ec 0c             	sub    $0xc,%esp
f0101754:	6a 00                	push   $0x0
f0101756:	e8 74 f8 ff ff       	call   f0100fcf <page_alloc>
f010175b:	83 c4 10             	add    $0x10,%esp
f010175e:	85 c0                	test   %eax,%eax
f0101760:	74 19                	je     f010177b <mem_init+0x3d8>
f0101762:	68 5e 72 10 f0       	push   $0xf010725e
f0101767:	68 eb 70 10 f0       	push   $0xf01070eb
f010176c:	68 5e 03 00 00       	push   $0x35e
f0101771:	68 c5 70 10 f0       	push   $0xf01070c5
f0101776:	e8 c5 e8 ff ff       	call   f0100040 <_panic>
f010177b:	89 f0                	mov    %esi,%eax
f010177d:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101783:	c1 f8 03             	sar    $0x3,%eax
f0101786:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101789:	89 c2                	mov    %eax,%edx
f010178b:	c1 ea 0c             	shr    $0xc,%edx
f010178e:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101794:	72 12                	jb     f01017a8 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101796:	50                   	push   %eax
f0101797:	68 a4 61 10 f0       	push   $0xf01061a4
f010179c:	6a 58                	push   $0x58
f010179e:	68 d1 70 10 f0       	push   $0xf01070d1
f01017a3:	e8 98 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01017a8:	83 ec 04             	sub    $0x4,%esp
f01017ab:	68 00 10 00 00       	push   $0x1000
f01017b0:	6a 01                	push   $0x1
f01017b2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017b7:	50                   	push   %eax
f01017b8:	e8 08 3d 00 00       	call   f01054c5 <memset>
	page_free(pp0);
f01017bd:	89 34 24             	mov    %esi,(%esp)
f01017c0:	e8 7a f8 ff ff       	call   f010103f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017cc:	e8 fe f7 ff ff       	call   f0100fcf <page_alloc>
f01017d1:	83 c4 10             	add    $0x10,%esp
f01017d4:	85 c0                	test   %eax,%eax
f01017d6:	75 19                	jne    f01017f1 <mem_init+0x44e>
f01017d8:	68 6d 72 10 f0       	push   $0xf010726d
f01017dd:	68 eb 70 10 f0       	push   $0xf01070eb
f01017e2:	68 63 03 00 00       	push   $0x363
f01017e7:	68 c5 70 10 f0       	push   $0xf01070c5
f01017ec:	e8 4f e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01017f1:	39 c6                	cmp    %eax,%esi
f01017f3:	74 19                	je     f010180e <mem_init+0x46b>
f01017f5:	68 8b 72 10 f0       	push   $0xf010728b
f01017fa:	68 eb 70 10 f0       	push   $0xf01070eb
f01017ff:	68 64 03 00 00       	push   $0x364
f0101804:	68 c5 70 10 f0       	push   $0xf01070c5
f0101809:	e8 32 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010180e:	89 f0                	mov    %esi,%eax
f0101810:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101816:	c1 f8 03             	sar    $0x3,%eax
f0101819:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010181c:	89 c2                	mov    %eax,%edx
f010181e:	c1 ea 0c             	shr    $0xc,%edx
f0101821:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101827:	72 12                	jb     f010183b <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101829:	50                   	push   %eax
f010182a:	68 a4 61 10 f0       	push   $0xf01061a4
f010182f:	6a 58                	push   $0x58
f0101831:	68 d1 70 10 f0       	push   $0xf01070d1
f0101836:	e8 05 e8 ff ff       	call   f0100040 <_panic>
f010183b:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101841:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101847:	80 38 00             	cmpb   $0x0,(%eax)
f010184a:	74 19                	je     f0101865 <mem_init+0x4c2>
f010184c:	68 9b 72 10 f0       	push   $0xf010729b
f0101851:	68 eb 70 10 f0       	push   $0xf01070eb
f0101856:	68 67 03 00 00       	push   $0x367
f010185b:	68 c5 70 10 f0       	push   $0xf01070c5
f0101860:	e8 db e7 ff ff       	call   f0100040 <_panic>
f0101865:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101868:	39 d0                	cmp    %edx,%eax
f010186a:	75 db                	jne    f0101847 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010186c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010186f:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	// free the pages we took
	page_free(pp0);
f0101874:	83 ec 0c             	sub    $0xc,%esp
f0101877:	56                   	push   %esi
f0101878:	e8 c2 f7 ff ff       	call   f010103f <page_free>
	page_free(pp1);
f010187d:	89 3c 24             	mov    %edi,(%esp)
f0101880:	e8 ba f7 ff ff       	call   f010103f <page_free>
	page_free(pp2);
f0101885:	83 c4 04             	add    $0x4,%esp
f0101888:	ff 75 d4             	pushl  -0x2c(%ebp)
f010188b:	e8 af f7 ff ff       	call   f010103f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101890:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101895:	83 c4 10             	add    $0x10,%esp
f0101898:	eb 05                	jmp    f010189f <mem_init+0x4fc>
		--nfree;
f010189a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010189d:	8b 00                	mov    (%eax),%eax
f010189f:	85 c0                	test   %eax,%eax
f01018a1:	75 f7                	jne    f010189a <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f01018a3:	85 db                	test   %ebx,%ebx
f01018a5:	74 19                	je     f01018c0 <mem_init+0x51d>
f01018a7:	68 a5 72 10 f0       	push   $0xf01072a5
f01018ac:	68 eb 70 10 f0       	push   $0xf01070eb
f01018b1:	68 74 03 00 00       	push   $0x374
f01018b6:	68 c5 70 10 f0       	push   $0xf01070c5
f01018bb:	e8 80 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018c0:	83 ec 0c             	sub    $0xc,%esp
f01018c3:	68 34 69 10 f0       	push   $0xf0106934
f01018c8:	e8 d6 1d 00 00       	call   f01036a3 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018d4:	e8 f6 f6 ff ff       	call   f0100fcf <page_alloc>
f01018d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018dc:	83 c4 10             	add    $0x10,%esp
f01018df:	85 c0                	test   %eax,%eax
f01018e1:	75 19                	jne    f01018fc <mem_init+0x559>
f01018e3:	68 b3 71 10 f0       	push   $0xf01071b3
f01018e8:	68 eb 70 10 f0       	push   $0xf01070eb
f01018ed:	68 da 03 00 00       	push   $0x3da
f01018f2:	68 c5 70 10 f0       	push   $0xf01070c5
f01018f7:	e8 44 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018fc:	83 ec 0c             	sub    $0xc,%esp
f01018ff:	6a 00                	push   $0x0
f0101901:	e8 c9 f6 ff ff       	call   f0100fcf <page_alloc>
f0101906:	89 c3                	mov    %eax,%ebx
f0101908:	83 c4 10             	add    $0x10,%esp
f010190b:	85 c0                	test   %eax,%eax
f010190d:	75 19                	jne    f0101928 <mem_init+0x585>
f010190f:	68 c9 71 10 f0       	push   $0xf01071c9
f0101914:	68 eb 70 10 f0       	push   $0xf01070eb
f0101919:	68 db 03 00 00       	push   $0x3db
f010191e:	68 c5 70 10 f0       	push   $0xf01070c5
f0101923:	e8 18 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101928:	83 ec 0c             	sub    $0xc,%esp
f010192b:	6a 00                	push   $0x0
f010192d:	e8 9d f6 ff ff       	call   f0100fcf <page_alloc>
f0101932:	89 c6                	mov    %eax,%esi
f0101934:	83 c4 10             	add    $0x10,%esp
f0101937:	85 c0                	test   %eax,%eax
f0101939:	75 19                	jne    f0101954 <mem_init+0x5b1>
f010193b:	68 df 71 10 f0       	push   $0xf01071df
f0101940:	68 eb 70 10 f0       	push   $0xf01070eb
f0101945:	68 dc 03 00 00       	push   $0x3dc
f010194a:	68 c5 70 10 f0       	push   $0xf01070c5
f010194f:	e8 ec e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101954:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101957:	75 19                	jne    f0101972 <mem_init+0x5cf>
f0101959:	68 f5 71 10 f0       	push   $0xf01071f5
f010195e:	68 eb 70 10 f0       	push   $0xf01070eb
f0101963:	68 df 03 00 00       	push   $0x3df
f0101968:	68 c5 70 10 f0       	push   $0xf01070c5
f010196d:	e8 ce e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101972:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101975:	74 04                	je     f010197b <mem_init+0x5d8>
f0101977:	39 c3                	cmp    %eax,%ebx
f0101979:	75 19                	jne    f0101994 <mem_init+0x5f1>
f010197b:	68 14 69 10 f0       	push   $0xf0106914
f0101980:	68 eb 70 10 f0       	push   $0xf01070eb
f0101985:	68 e0 03 00 00       	push   $0x3e0
f010198a:	68 c5 70 10 f0       	push   $0xf01070c5
f010198f:	e8 ac e6 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101994:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101999:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010199c:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f01019a3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019a6:	83 ec 0c             	sub    $0xc,%esp
f01019a9:	6a 00                	push   $0x0
f01019ab:	e8 1f f6 ff ff       	call   f0100fcf <page_alloc>
f01019b0:	83 c4 10             	add    $0x10,%esp
f01019b3:	85 c0                	test   %eax,%eax
f01019b5:	74 19                	je     f01019d0 <mem_init+0x62d>
f01019b7:	68 5e 72 10 f0       	push   $0xf010725e
f01019bc:	68 eb 70 10 f0       	push   $0xf01070eb
f01019c1:	68 e7 03 00 00       	push   $0x3e7
f01019c6:	68 c5 70 10 f0       	push   $0xf01070c5
f01019cb:	e8 70 e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019d0:	83 ec 04             	sub    $0x4,%esp
f01019d3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019d6:	50                   	push   %eax
f01019d7:	6a 00                	push   $0x0
f01019d9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01019df:	e8 06 f8 ff ff       	call   f01011ea <page_lookup>
f01019e4:	83 c4 10             	add    $0x10,%esp
f01019e7:	85 c0                	test   %eax,%eax
f01019e9:	74 19                	je     f0101a04 <mem_init+0x661>
f01019eb:	68 54 69 10 f0       	push   $0xf0106954
f01019f0:	68 eb 70 10 f0       	push   $0xf01070eb
f01019f5:	68 ea 03 00 00       	push   $0x3ea
f01019fa:	68 c5 70 10 f0       	push   $0xf01070c5
f01019ff:	e8 3c e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a04:	6a 02                	push   $0x2
f0101a06:	6a 00                	push   $0x0
f0101a08:	53                   	push   %ebx
f0101a09:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101a0f:	e8 ba f8 ff ff       	call   f01012ce <page_insert>
f0101a14:	83 c4 10             	add    $0x10,%esp
f0101a17:	85 c0                	test   %eax,%eax
f0101a19:	78 19                	js     f0101a34 <mem_init+0x691>
f0101a1b:	68 8c 69 10 f0       	push   $0xf010698c
f0101a20:	68 eb 70 10 f0       	push   $0xf01070eb
f0101a25:	68 ed 03 00 00       	push   $0x3ed
f0101a2a:	68 c5 70 10 f0       	push   $0xf01070c5
f0101a2f:	e8 0c e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a34:	83 ec 0c             	sub    $0xc,%esp
f0101a37:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a3a:	e8 00 f6 ff ff       	call   f010103f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a3f:	6a 02                	push   $0x2
f0101a41:	6a 00                	push   $0x0
f0101a43:	53                   	push   %ebx
f0101a44:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101a4a:	e8 7f f8 ff ff       	call   f01012ce <page_insert>
f0101a4f:	83 c4 20             	add    $0x20,%esp
f0101a52:	85 c0                	test   %eax,%eax
f0101a54:	74 19                	je     f0101a6f <mem_init+0x6cc>
f0101a56:	68 bc 69 10 f0       	push   $0xf01069bc
f0101a5b:	68 eb 70 10 f0       	push   $0xf01070eb
f0101a60:	68 f1 03 00 00       	push   $0x3f1
f0101a65:	68 c5 70 10 f0       	push   $0xf01070c5
f0101a6a:	e8 d1 e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a6f:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a75:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0101a7a:	89 c1                	mov    %eax,%ecx
f0101a7c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a7f:	8b 17                	mov    (%edi),%edx
f0101a81:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a87:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a8a:	29 c8                	sub    %ecx,%eax
f0101a8c:	c1 f8 03             	sar    $0x3,%eax
f0101a8f:	c1 e0 0c             	shl    $0xc,%eax
f0101a92:	39 c2                	cmp    %eax,%edx
f0101a94:	74 19                	je     f0101aaf <mem_init+0x70c>
f0101a96:	68 ec 69 10 f0       	push   $0xf01069ec
f0101a9b:	68 eb 70 10 f0       	push   $0xf01070eb
f0101aa0:	68 f2 03 00 00       	push   $0x3f2
f0101aa5:	68 c5 70 10 f0       	push   $0xf01070c5
f0101aaa:	e8 91 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101aaf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ab4:	89 f8                	mov    %edi,%eax
f0101ab6:	e8 2c f0 ff ff       	call   f0100ae7 <check_va2pa>
f0101abb:	89 da                	mov    %ebx,%edx
f0101abd:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ac0:	c1 fa 03             	sar    $0x3,%edx
f0101ac3:	c1 e2 0c             	shl    $0xc,%edx
f0101ac6:	39 d0                	cmp    %edx,%eax
f0101ac8:	74 19                	je     f0101ae3 <mem_init+0x740>
f0101aca:	68 14 6a 10 f0       	push   $0xf0106a14
f0101acf:	68 eb 70 10 f0       	push   $0xf01070eb
f0101ad4:	68 f3 03 00 00       	push   $0x3f3
f0101ad9:	68 c5 70 10 f0       	push   $0xf01070c5
f0101ade:	e8 5d e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ae3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ae8:	74 19                	je     f0101b03 <mem_init+0x760>
f0101aea:	68 b0 72 10 f0       	push   $0xf01072b0
f0101aef:	68 eb 70 10 f0       	push   $0xf01070eb
f0101af4:	68 f4 03 00 00       	push   $0x3f4
f0101af9:	68 c5 70 10 f0       	push   $0xf01070c5
f0101afe:	e8 3d e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101b03:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b06:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b0b:	74 19                	je     f0101b26 <mem_init+0x783>
f0101b0d:	68 c1 72 10 f0       	push   $0xf01072c1
f0101b12:	68 eb 70 10 f0       	push   $0xf01070eb
f0101b17:	68 f5 03 00 00       	push   $0x3f5
f0101b1c:	68 c5 70 10 f0       	push   $0xf01070c5
f0101b21:	e8 1a e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b26:	6a 02                	push   $0x2
f0101b28:	68 00 10 00 00       	push   $0x1000
f0101b2d:	56                   	push   %esi
f0101b2e:	57                   	push   %edi
f0101b2f:	e8 9a f7 ff ff       	call   f01012ce <page_insert>
f0101b34:	83 c4 10             	add    $0x10,%esp
f0101b37:	85 c0                	test   %eax,%eax
f0101b39:	74 19                	je     f0101b54 <mem_init+0x7b1>
f0101b3b:	68 44 6a 10 f0       	push   $0xf0106a44
f0101b40:	68 eb 70 10 f0       	push   $0xf01070eb
f0101b45:	68 f8 03 00 00       	push   $0x3f8
f0101b4a:	68 c5 70 10 f0       	push   $0xf01070c5
f0101b4f:	e8 ec e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b54:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b59:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101b5e:	e8 84 ef ff ff       	call   f0100ae7 <check_va2pa>
f0101b63:	89 f2                	mov    %esi,%edx
f0101b65:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101b6b:	c1 fa 03             	sar    $0x3,%edx
f0101b6e:	c1 e2 0c             	shl    $0xc,%edx
f0101b71:	39 d0                	cmp    %edx,%eax
f0101b73:	74 19                	je     f0101b8e <mem_init+0x7eb>
f0101b75:	68 80 6a 10 f0       	push   $0xf0106a80
f0101b7a:	68 eb 70 10 f0       	push   $0xf01070eb
f0101b7f:	68 f9 03 00 00       	push   $0x3f9
f0101b84:	68 c5 70 10 f0       	push   $0xf01070c5
f0101b89:	e8 b2 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b8e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b93:	74 19                	je     f0101bae <mem_init+0x80b>
f0101b95:	68 d2 72 10 f0       	push   $0xf01072d2
f0101b9a:	68 eb 70 10 f0       	push   $0xf01070eb
f0101b9f:	68 fa 03 00 00       	push   $0x3fa
f0101ba4:	68 c5 70 10 f0       	push   $0xf01070c5
f0101ba9:	e8 92 e4 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bae:	83 ec 0c             	sub    $0xc,%esp
f0101bb1:	6a 00                	push   $0x0
f0101bb3:	e8 17 f4 ff ff       	call   f0100fcf <page_alloc>
f0101bb8:	83 c4 10             	add    $0x10,%esp
f0101bbb:	85 c0                	test   %eax,%eax
f0101bbd:	74 19                	je     f0101bd8 <mem_init+0x835>
f0101bbf:	68 5e 72 10 f0       	push   $0xf010725e
f0101bc4:	68 eb 70 10 f0       	push   $0xf01070eb
f0101bc9:	68 fd 03 00 00       	push   $0x3fd
f0101bce:	68 c5 70 10 f0       	push   $0xf01070c5
f0101bd3:	e8 68 e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bd8:	6a 02                	push   $0x2
f0101bda:	68 00 10 00 00       	push   $0x1000
f0101bdf:	56                   	push   %esi
f0101be0:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101be6:	e8 e3 f6 ff ff       	call   f01012ce <page_insert>
f0101beb:	83 c4 10             	add    $0x10,%esp
f0101bee:	85 c0                	test   %eax,%eax
f0101bf0:	74 19                	je     f0101c0b <mem_init+0x868>
f0101bf2:	68 44 6a 10 f0       	push   $0xf0106a44
f0101bf7:	68 eb 70 10 f0       	push   $0xf01070eb
f0101bfc:	68 00 04 00 00       	push   $0x400
f0101c01:	68 c5 70 10 f0       	push   $0xf01070c5
f0101c06:	e8 35 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c0b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c10:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101c15:	e8 cd ee ff ff       	call   f0100ae7 <check_va2pa>
f0101c1a:	89 f2                	mov    %esi,%edx
f0101c1c:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101c22:	c1 fa 03             	sar    $0x3,%edx
f0101c25:	c1 e2 0c             	shl    $0xc,%edx
f0101c28:	39 d0                	cmp    %edx,%eax
f0101c2a:	74 19                	je     f0101c45 <mem_init+0x8a2>
f0101c2c:	68 80 6a 10 f0       	push   $0xf0106a80
f0101c31:	68 eb 70 10 f0       	push   $0xf01070eb
f0101c36:	68 01 04 00 00       	push   $0x401
f0101c3b:	68 c5 70 10 f0       	push   $0xf01070c5
f0101c40:	e8 fb e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c45:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c4a:	74 19                	je     f0101c65 <mem_init+0x8c2>
f0101c4c:	68 d2 72 10 f0       	push   $0xf01072d2
f0101c51:	68 eb 70 10 f0       	push   $0xf01070eb
f0101c56:	68 02 04 00 00       	push   $0x402
f0101c5b:	68 c5 70 10 f0       	push   $0xf01070c5
f0101c60:	e8 db e3 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c65:	83 ec 0c             	sub    $0xc,%esp
f0101c68:	6a 00                	push   $0x0
f0101c6a:	e8 60 f3 ff ff       	call   f0100fcf <page_alloc>
f0101c6f:	83 c4 10             	add    $0x10,%esp
f0101c72:	85 c0                	test   %eax,%eax
f0101c74:	74 19                	je     f0101c8f <mem_init+0x8ec>
f0101c76:	68 5e 72 10 f0       	push   $0xf010725e
f0101c7b:	68 eb 70 10 f0       	push   $0xf01070eb
f0101c80:	68 06 04 00 00       	push   $0x406
f0101c85:	68 c5 70 10 f0       	push   $0xf01070c5
f0101c8a:	e8 b1 e3 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c8f:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0101c95:	8b 02                	mov    (%edx),%eax
f0101c97:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c9c:	89 c1                	mov    %eax,%ecx
f0101c9e:	c1 e9 0c             	shr    $0xc,%ecx
f0101ca1:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0101ca7:	72 15                	jb     f0101cbe <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ca9:	50                   	push   %eax
f0101caa:	68 a4 61 10 f0       	push   $0xf01061a4
f0101caf:	68 09 04 00 00       	push   $0x409
f0101cb4:	68 c5 70 10 f0       	push   $0xf01070c5
f0101cb9:	e8 82 e3 ff ff       	call   f0100040 <_panic>
f0101cbe:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cc3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101cc6:	83 ec 04             	sub    $0x4,%esp
f0101cc9:	6a 00                	push   $0x0
f0101ccb:	68 00 10 00 00       	push   $0x1000
f0101cd0:	52                   	push   %edx
f0101cd1:	e8 cb f3 ff ff       	call   f01010a1 <pgdir_walk>
f0101cd6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101cd9:	8d 51 04             	lea    0x4(%ecx),%edx
f0101cdc:	83 c4 10             	add    $0x10,%esp
f0101cdf:	39 d0                	cmp    %edx,%eax
f0101ce1:	74 19                	je     f0101cfc <mem_init+0x959>
f0101ce3:	68 b0 6a 10 f0       	push   $0xf0106ab0
f0101ce8:	68 eb 70 10 f0       	push   $0xf01070eb
f0101ced:	68 0a 04 00 00       	push   $0x40a
f0101cf2:	68 c5 70 10 f0       	push   $0xf01070c5
f0101cf7:	e8 44 e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cfc:	6a 06                	push   $0x6
f0101cfe:	68 00 10 00 00       	push   $0x1000
f0101d03:	56                   	push   %esi
f0101d04:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d0a:	e8 bf f5 ff ff       	call   f01012ce <page_insert>
f0101d0f:	83 c4 10             	add    $0x10,%esp
f0101d12:	85 c0                	test   %eax,%eax
f0101d14:	74 19                	je     f0101d2f <mem_init+0x98c>
f0101d16:	68 f0 6a 10 f0       	push   $0xf0106af0
f0101d1b:	68 eb 70 10 f0       	push   $0xf01070eb
f0101d20:	68 0d 04 00 00       	push   $0x40d
f0101d25:	68 c5 70 10 f0       	push   $0xf01070c5
f0101d2a:	e8 11 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d2f:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101d35:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d3a:	89 f8                	mov    %edi,%eax
f0101d3c:	e8 a6 ed ff ff       	call   f0100ae7 <check_va2pa>
f0101d41:	89 f2                	mov    %esi,%edx
f0101d43:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101d49:	c1 fa 03             	sar    $0x3,%edx
f0101d4c:	c1 e2 0c             	shl    $0xc,%edx
f0101d4f:	39 d0                	cmp    %edx,%eax
f0101d51:	74 19                	je     f0101d6c <mem_init+0x9c9>
f0101d53:	68 80 6a 10 f0       	push   $0xf0106a80
f0101d58:	68 eb 70 10 f0       	push   $0xf01070eb
f0101d5d:	68 0e 04 00 00       	push   $0x40e
f0101d62:	68 c5 70 10 f0       	push   $0xf01070c5
f0101d67:	e8 d4 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d6c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d71:	74 19                	je     f0101d8c <mem_init+0x9e9>
f0101d73:	68 d2 72 10 f0       	push   $0xf01072d2
f0101d78:	68 eb 70 10 f0       	push   $0xf01070eb
f0101d7d:	68 0f 04 00 00       	push   $0x40f
f0101d82:	68 c5 70 10 f0       	push   $0xf01070c5
f0101d87:	e8 b4 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d8c:	83 ec 04             	sub    $0x4,%esp
f0101d8f:	6a 00                	push   $0x0
f0101d91:	68 00 10 00 00       	push   $0x1000
f0101d96:	57                   	push   %edi
f0101d97:	e8 05 f3 ff ff       	call   f01010a1 <pgdir_walk>
f0101d9c:	83 c4 10             	add    $0x10,%esp
f0101d9f:	f6 00 04             	testb  $0x4,(%eax)
f0101da2:	75 19                	jne    f0101dbd <mem_init+0xa1a>
f0101da4:	68 30 6b 10 f0       	push   $0xf0106b30
f0101da9:	68 eb 70 10 f0       	push   $0xf01070eb
f0101dae:	68 10 04 00 00       	push   $0x410
f0101db3:	68 c5 70 10 f0       	push   $0xf01070c5
f0101db8:	e8 83 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101dbd:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101dc2:	f6 00 04             	testb  $0x4,(%eax)
f0101dc5:	75 19                	jne    f0101de0 <mem_init+0xa3d>
f0101dc7:	68 e3 72 10 f0       	push   $0xf01072e3
f0101dcc:	68 eb 70 10 f0       	push   $0xf01070eb
f0101dd1:	68 11 04 00 00       	push   $0x411
f0101dd6:	68 c5 70 10 f0       	push   $0xf01070c5
f0101ddb:	e8 60 e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101de0:	6a 02                	push   $0x2
f0101de2:	68 00 10 00 00       	push   $0x1000
f0101de7:	56                   	push   %esi
f0101de8:	50                   	push   %eax
f0101de9:	e8 e0 f4 ff ff       	call   f01012ce <page_insert>
f0101dee:	83 c4 10             	add    $0x10,%esp
f0101df1:	85 c0                	test   %eax,%eax
f0101df3:	74 19                	je     f0101e0e <mem_init+0xa6b>
f0101df5:	68 44 6a 10 f0       	push   $0xf0106a44
f0101dfa:	68 eb 70 10 f0       	push   $0xf01070eb
f0101dff:	68 14 04 00 00       	push   $0x414
f0101e04:	68 c5 70 10 f0       	push   $0xf01070c5
f0101e09:	e8 32 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e0e:	83 ec 04             	sub    $0x4,%esp
f0101e11:	6a 00                	push   $0x0
f0101e13:	68 00 10 00 00       	push   $0x1000
f0101e18:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e1e:	e8 7e f2 ff ff       	call   f01010a1 <pgdir_walk>
f0101e23:	83 c4 10             	add    $0x10,%esp
f0101e26:	f6 00 02             	testb  $0x2,(%eax)
f0101e29:	75 19                	jne    f0101e44 <mem_init+0xaa1>
f0101e2b:	68 64 6b 10 f0       	push   $0xf0106b64
f0101e30:	68 eb 70 10 f0       	push   $0xf01070eb
f0101e35:	68 15 04 00 00       	push   $0x415
f0101e3a:	68 c5 70 10 f0       	push   $0xf01070c5
f0101e3f:	e8 fc e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e44:	83 ec 04             	sub    $0x4,%esp
f0101e47:	6a 00                	push   $0x0
f0101e49:	68 00 10 00 00       	push   $0x1000
f0101e4e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e54:	e8 48 f2 ff ff       	call   f01010a1 <pgdir_walk>
f0101e59:	83 c4 10             	add    $0x10,%esp
f0101e5c:	f6 00 04             	testb  $0x4,(%eax)
f0101e5f:	74 19                	je     f0101e7a <mem_init+0xad7>
f0101e61:	68 98 6b 10 f0       	push   $0xf0106b98
f0101e66:	68 eb 70 10 f0       	push   $0xf01070eb
f0101e6b:	68 16 04 00 00       	push   $0x416
f0101e70:	68 c5 70 10 f0       	push   $0xf01070c5
f0101e75:	e8 c6 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e7a:	6a 02                	push   $0x2
f0101e7c:	68 00 00 40 00       	push   $0x400000
f0101e81:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e84:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e8a:	e8 3f f4 ff ff       	call   f01012ce <page_insert>
f0101e8f:	83 c4 10             	add    $0x10,%esp
f0101e92:	85 c0                	test   %eax,%eax
f0101e94:	78 19                	js     f0101eaf <mem_init+0xb0c>
f0101e96:	68 d0 6b 10 f0       	push   $0xf0106bd0
f0101e9b:	68 eb 70 10 f0       	push   $0xf01070eb
f0101ea0:	68 19 04 00 00       	push   $0x419
f0101ea5:	68 c5 70 10 f0       	push   $0xf01070c5
f0101eaa:	e8 91 e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101eaf:	6a 02                	push   $0x2
f0101eb1:	68 00 10 00 00       	push   $0x1000
f0101eb6:	53                   	push   %ebx
f0101eb7:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101ebd:	e8 0c f4 ff ff       	call   f01012ce <page_insert>
f0101ec2:	83 c4 10             	add    $0x10,%esp
f0101ec5:	85 c0                	test   %eax,%eax
f0101ec7:	74 19                	je     f0101ee2 <mem_init+0xb3f>
f0101ec9:	68 08 6c 10 f0       	push   $0xf0106c08
f0101ece:	68 eb 70 10 f0       	push   $0xf01070eb
f0101ed3:	68 1c 04 00 00       	push   $0x41c
f0101ed8:	68 c5 70 10 f0       	push   $0xf01070c5
f0101edd:	e8 5e e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ee2:	83 ec 04             	sub    $0x4,%esp
f0101ee5:	6a 00                	push   $0x0
f0101ee7:	68 00 10 00 00       	push   $0x1000
f0101eec:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101ef2:	e8 aa f1 ff ff       	call   f01010a1 <pgdir_walk>
f0101ef7:	83 c4 10             	add    $0x10,%esp
f0101efa:	f6 00 04             	testb  $0x4,(%eax)
f0101efd:	74 19                	je     f0101f18 <mem_init+0xb75>
f0101eff:	68 98 6b 10 f0       	push   $0xf0106b98
f0101f04:	68 eb 70 10 f0       	push   $0xf01070eb
f0101f09:	68 1d 04 00 00       	push   $0x41d
f0101f0e:	68 c5 70 10 f0       	push   $0xf01070c5
f0101f13:	e8 28 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f18:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101f1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f23:	89 f8                	mov    %edi,%eax
f0101f25:	e8 bd eb ff ff       	call   f0100ae7 <check_va2pa>
f0101f2a:	89 c1                	mov    %eax,%ecx
f0101f2c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f2f:	89 d8                	mov    %ebx,%eax
f0101f31:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101f37:	c1 f8 03             	sar    $0x3,%eax
f0101f3a:	c1 e0 0c             	shl    $0xc,%eax
f0101f3d:	39 c1                	cmp    %eax,%ecx
f0101f3f:	74 19                	je     f0101f5a <mem_init+0xbb7>
f0101f41:	68 44 6c 10 f0       	push   $0xf0106c44
f0101f46:	68 eb 70 10 f0       	push   $0xf01070eb
f0101f4b:	68 20 04 00 00       	push   $0x420
f0101f50:	68 c5 70 10 f0       	push   $0xf01070c5
f0101f55:	e8 e6 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f5f:	89 f8                	mov    %edi,%eax
f0101f61:	e8 81 eb ff ff       	call   f0100ae7 <check_va2pa>
f0101f66:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101f69:	74 19                	je     f0101f84 <mem_init+0xbe1>
f0101f6b:	68 70 6c 10 f0       	push   $0xf0106c70
f0101f70:	68 eb 70 10 f0       	push   $0xf01070eb
f0101f75:	68 21 04 00 00       	push   $0x421
f0101f7a:	68 c5 70 10 f0       	push   $0xf01070c5
f0101f7f:	e8 bc e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f84:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f89:	74 19                	je     f0101fa4 <mem_init+0xc01>
f0101f8b:	68 f9 72 10 f0       	push   $0xf01072f9
f0101f90:	68 eb 70 10 f0       	push   $0xf01070eb
f0101f95:	68 23 04 00 00       	push   $0x423
f0101f9a:	68 c5 70 10 f0       	push   $0xf01070c5
f0101f9f:	e8 9c e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101fa4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fa9:	74 19                	je     f0101fc4 <mem_init+0xc21>
f0101fab:	68 0a 73 10 f0       	push   $0xf010730a
f0101fb0:	68 eb 70 10 f0       	push   $0xf01070eb
f0101fb5:	68 24 04 00 00       	push   $0x424
f0101fba:	68 c5 70 10 f0       	push   $0xf01070c5
f0101fbf:	e8 7c e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101fc4:	83 ec 0c             	sub    $0xc,%esp
f0101fc7:	6a 00                	push   $0x0
f0101fc9:	e8 01 f0 ff ff       	call   f0100fcf <page_alloc>
f0101fce:	83 c4 10             	add    $0x10,%esp
f0101fd1:	39 c6                	cmp    %eax,%esi
f0101fd3:	75 04                	jne    f0101fd9 <mem_init+0xc36>
f0101fd5:	85 c0                	test   %eax,%eax
f0101fd7:	75 19                	jne    f0101ff2 <mem_init+0xc4f>
f0101fd9:	68 a0 6c 10 f0       	push   $0xf0106ca0
f0101fde:	68 eb 70 10 f0       	push   $0xf01070eb
f0101fe3:	68 27 04 00 00       	push   $0x427
f0101fe8:	68 c5 70 10 f0       	push   $0xf01070c5
f0101fed:	e8 4e e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ff2:	83 ec 08             	sub    $0x8,%esp
f0101ff5:	6a 00                	push   $0x0
f0101ff7:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101ffd:	e8 77 f2 ff ff       	call   f0101279 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102002:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0102008:	ba 00 00 00 00       	mov    $0x0,%edx
f010200d:	89 f8                	mov    %edi,%eax
f010200f:	e8 d3 ea ff ff       	call   f0100ae7 <check_va2pa>
f0102014:	83 c4 10             	add    $0x10,%esp
f0102017:	83 f8 ff             	cmp    $0xffffffff,%eax
f010201a:	74 19                	je     f0102035 <mem_init+0xc92>
f010201c:	68 c4 6c 10 f0       	push   $0xf0106cc4
f0102021:	68 eb 70 10 f0       	push   $0xf01070eb
f0102026:	68 2b 04 00 00       	push   $0x42b
f010202b:	68 c5 70 10 f0       	push   $0xf01070c5
f0102030:	e8 0b e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102035:	ba 00 10 00 00       	mov    $0x1000,%edx
f010203a:	89 f8                	mov    %edi,%eax
f010203c:	e8 a6 ea ff ff       	call   f0100ae7 <check_va2pa>
f0102041:	89 da                	mov    %ebx,%edx
f0102043:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0102049:	c1 fa 03             	sar    $0x3,%edx
f010204c:	c1 e2 0c             	shl    $0xc,%edx
f010204f:	39 d0                	cmp    %edx,%eax
f0102051:	74 19                	je     f010206c <mem_init+0xcc9>
f0102053:	68 70 6c 10 f0       	push   $0xf0106c70
f0102058:	68 eb 70 10 f0       	push   $0xf01070eb
f010205d:	68 2c 04 00 00       	push   $0x42c
f0102062:	68 c5 70 10 f0       	push   $0xf01070c5
f0102067:	e8 d4 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010206c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102071:	74 19                	je     f010208c <mem_init+0xce9>
f0102073:	68 b0 72 10 f0       	push   $0xf01072b0
f0102078:	68 eb 70 10 f0       	push   $0xf01070eb
f010207d:	68 2d 04 00 00       	push   $0x42d
f0102082:	68 c5 70 10 f0       	push   $0xf01070c5
f0102087:	e8 b4 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010208c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102091:	74 19                	je     f01020ac <mem_init+0xd09>
f0102093:	68 0a 73 10 f0       	push   $0xf010730a
f0102098:	68 eb 70 10 f0       	push   $0xf01070eb
f010209d:	68 2e 04 00 00       	push   $0x42e
f01020a2:	68 c5 70 10 f0       	push   $0xf01070c5
f01020a7:	e8 94 df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01020ac:	6a 00                	push   $0x0
f01020ae:	68 00 10 00 00       	push   $0x1000
f01020b3:	53                   	push   %ebx
f01020b4:	57                   	push   %edi
f01020b5:	e8 14 f2 ff ff       	call   f01012ce <page_insert>
f01020ba:	83 c4 10             	add    $0x10,%esp
f01020bd:	85 c0                	test   %eax,%eax
f01020bf:	74 19                	je     f01020da <mem_init+0xd37>
f01020c1:	68 e8 6c 10 f0       	push   $0xf0106ce8
f01020c6:	68 eb 70 10 f0       	push   $0xf01070eb
f01020cb:	68 31 04 00 00       	push   $0x431
f01020d0:	68 c5 70 10 f0       	push   $0xf01070c5
f01020d5:	e8 66 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01020da:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020df:	75 19                	jne    f01020fa <mem_init+0xd57>
f01020e1:	68 1b 73 10 f0       	push   $0xf010731b
f01020e6:	68 eb 70 10 f0       	push   $0xf01070eb
f01020eb:	68 32 04 00 00       	push   $0x432
f01020f0:	68 c5 70 10 f0       	push   $0xf01070c5
f01020f5:	e8 46 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01020fa:	83 3b 00             	cmpl   $0x0,(%ebx)
f01020fd:	74 19                	je     f0102118 <mem_init+0xd75>
f01020ff:	68 27 73 10 f0       	push   $0xf0107327
f0102104:	68 eb 70 10 f0       	push   $0xf01070eb
f0102109:	68 33 04 00 00       	push   $0x433
f010210e:	68 c5 70 10 f0       	push   $0xf01070c5
f0102113:	e8 28 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102118:	83 ec 08             	sub    $0x8,%esp
f010211b:	68 00 10 00 00       	push   $0x1000
f0102120:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102126:	e8 4e f1 ff ff       	call   f0101279 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010212b:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0102131:	ba 00 00 00 00       	mov    $0x0,%edx
f0102136:	89 f8                	mov    %edi,%eax
f0102138:	e8 aa e9 ff ff       	call   f0100ae7 <check_va2pa>
f010213d:	83 c4 10             	add    $0x10,%esp
f0102140:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102143:	74 19                	je     f010215e <mem_init+0xdbb>
f0102145:	68 c4 6c 10 f0       	push   $0xf0106cc4
f010214a:	68 eb 70 10 f0       	push   $0xf01070eb
f010214f:	68 37 04 00 00       	push   $0x437
f0102154:	68 c5 70 10 f0       	push   $0xf01070c5
f0102159:	e8 e2 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010215e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102163:	89 f8                	mov    %edi,%eax
f0102165:	e8 7d e9 ff ff       	call   f0100ae7 <check_va2pa>
f010216a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010216d:	74 19                	je     f0102188 <mem_init+0xde5>
f010216f:	68 20 6d 10 f0       	push   $0xf0106d20
f0102174:	68 eb 70 10 f0       	push   $0xf01070eb
f0102179:	68 38 04 00 00       	push   $0x438
f010217e:	68 c5 70 10 f0       	push   $0xf01070c5
f0102183:	e8 b8 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102188:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010218d:	74 19                	je     f01021a8 <mem_init+0xe05>
f010218f:	68 3c 73 10 f0       	push   $0xf010733c
f0102194:	68 eb 70 10 f0       	push   $0xf01070eb
f0102199:	68 39 04 00 00       	push   $0x439
f010219e:	68 c5 70 10 f0       	push   $0xf01070c5
f01021a3:	e8 98 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01021a8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021ad:	74 19                	je     f01021c8 <mem_init+0xe25>
f01021af:	68 0a 73 10 f0       	push   $0xf010730a
f01021b4:	68 eb 70 10 f0       	push   $0xf01070eb
f01021b9:	68 3a 04 00 00       	push   $0x43a
f01021be:	68 c5 70 10 f0       	push   $0xf01070c5
f01021c3:	e8 78 de ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01021c8:	83 ec 0c             	sub    $0xc,%esp
f01021cb:	6a 00                	push   $0x0
f01021cd:	e8 fd ed ff ff       	call   f0100fcf <page_alloc>
f01021d2:	83 c4 10             	add    $0x10,%esp
f01021d5:	85 c0                	test   %eax,%eax
f01021d7:	74 04                	je     f01021dd <mem_init+0xe3a>
f01021d9:	39 c3                	cmp    %eax,%ebx
f01021db:	74 19                	je     f01021f6 <mem_init+0xe53>
f01021dd:	68 48 6d 10 f0       	push   $0xf0106d48
f01021e2:	68 eb 70 10 f0       	push   $0xf01070eb
f01021e7:	68 3d 04 00 00       	push   $0x43d
f01021ec:	68 c5 70 10 f0       	push   $0xf01070c5
f01021f1:	e8 4a de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021f6:	83 ec 0c             	sub    $0xc,%esp
f01021f9:	6a 00                	push   $0x0
f01021fb:	e8 cf ed ff ff       	call   f0100fcf <page_alloc>
f0102200:	83 c4 10             	add    $0x10,%esp
f0102203:	85 c0                	test   %eax,%eax
f0102205:	74 19                	je     f0102220 <mem_init+0xe7d>
f0102207:	68 5e 72 10 f0       	push   $0xf010725e
f010220c:	68 eb 70 10 f0       	push   $0xf01070eb
f0102211:	68 40 04 00 00       	push   $0x440
f0102216:	68 c5 70 10 f0       	push   $0xf01070c5
f010221b:	e8 20 de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102220:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102226:	8b 11                	mov    (%ecx),%edx
f0102228:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010222e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102231:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102237:	c1 f8 03             	sar    $0x3,%eax
f010223a:	c1 e0 0c             	shl    $0xc,%eax
f010223d:	39 c2                	cmp    %eax,%edx
f010223f:	74 19                	je     f010225a <mem_init+0xeb7>
f0102241:	68 ec 69 10 f0       	push   $0xf01069ec
f0102246:	68 eb 70 10 f0       	push   $0xf01070eb
f010224b:	68 43 04 00 00       	push   $0x443
f0102250:	68 c5 70 10 f0       	push   $0xf01070c5
f0102255:	e8 e6 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010225a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102260:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102263:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102268:	74 19                	je     f0102283 <mem_init+0xee0>
f010226a:	68 c1 72 10 f0       	push   $0xf01072c1
f010226f:	68 eb 70 10 f0       	push   $0xf01070eb
f0102274:	68 45 04 00 00       	push   $0x445
f0102279:	68 c5 70 10 f0       	push   $0xf01070c5
f010227e:	e8 bd dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102283:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102286:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010228c:	83 ec 0c             	sub    $0xc,%esp
f010228f:	50                   	push   %eax
f0102290:	e8 aa ed ff ff       	call   f010103f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102295:	83 c4 0c             	add    $0xc,%esp
f0102298:	6a 01                	push   $0x1
f010229a:	68 00 10 40 00       	push   $0x401000
f010229f:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01022a5:	e8 f7 ed ff ff       	call   f01010a1 <pgdir_walk>
f01022aa:	89 c7                	mov    %eax,%edi
f01022ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01022af:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01022b4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022b7:	8b 40 04             	mov    0x4(%eax),%eax
f01022ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022bf:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01022c5:	89 c2                	mov    %eax,%edx
f01022c7:	c1 ea 0c             	shr    $0xc,%edx
f01022ca:	83 c4 10             	add    $0x10,%esp
f01022cd:	39 ca                	cmp    %ecx,%edx
f01022cf:	72 15                	jb     f01022e6 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022d1:	50                   	push   %eax
f01022d2:	68 a4 61 10 f0       	push   $0xf01061a4
f01022d7:	68 4c 04 00 00       	push   $0x44c
f01022dc:	68 c5 70 10 f0       	push   $0xf01070c5
f01022e1:	e8 5a dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01022e6:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01022eb:	39 c7                	cmp    %eax,%edi
f01022ed:	74 19                	je     f0102308 <mem_init+0xf65>
f01022ef:	68 4d 73 10 f0       	push   $0xf010734d
f01022f4:	68 eb 70 10 f0       	push   $0xf01070eb
f01022f9:	68 4d 04 00 00       	push   $0x44d
f01022fe:	68 c5 70 10 f0       	push   $0xf01070c5
f0102303:	e8 38 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102308:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010230b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102312:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102315:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010231b:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102321:	c1 f8 03             	sar    $0x3,%eax
f0102324:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102327:	89 c2                	mov    %eax,%edx
f0102329:	c1 ea 0c             	shr    $0xc,%edx
f010232c:	39 d1                	cmp    %edx,%ecx
f010232e:	77 12                	ja     f0102342 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102330:	50                   	push   %eax
f0102331:	68 a4 61 10 f0       	push   $0xf01061a4
f0102336:	6a 58                	push   $0x58
f0102338:	68 d1 70 10 f0       	push   $0xf01070d1
f010233d:	e8 fe dc ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102342:	83 ec 04             	sub    $0x4,%esp
f0102345:	68 00 10 00 00       	push   $0x1000
f010234a:	68 ff 00 00 00       	push   $0xff
f010234f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102354:	50                   	push   %eax
f0102355:	e8 6b 31 00 00       	call   f01054c5 <memset>
	page_free(pp0);
f010235a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010235d:	89 3c 24             	mov    %edi,(%esp)
f0102360:	e8 da ec ff ff       	call   f010103f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102365:	83 c4 0c             	add    $0xc,%esp
f0102368:	6a 01                	push   $0x1
f010236a:	6a 00                	push   $0x0
f010236c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102372:	e8 2a ed ff ff       	call   f01010a1 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102377:	89 fa                	mov    %edi,%edx
f0102379:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f010237f:	c1 fa 03             	sar    $0x3,%edx
f0102382:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102385:	89 d0                	mov    %edx,%eax
f0102387:	c1 e8 0c             	shr    $0xc,%eax
f010238a:	83 c4 10             	add    $0x10,%esp
f010238d:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0102393:	72 12                	jb     f01023a7 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102395:	52                   	push   %edx
f0102396:	68 a4 61 10 f0       	push   $0xf01061a4
f010239b:	6a 58                	push   $0x58
f010239d:	68 d1 70 10 f0       	push   $0xf01070d1
f01023a2:	e8 99 dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01023a7:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01023ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01023b0:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01023b6:	f6 00 01             	testb  $0x1,(%eax)
f01023b9:	74 19                	je     f01023d4 <mem_init+0x1031>
f01023bb:	68 65 73 10 f0       	push   $0xf0107365
f01023c0:	68 eb 70 10 f0       	push   $0xf01070eb
f01023c5:	68 57 04 00 00       	push   $0x457
f01023ca:	68 c5 70 10 f0       	push   $0xf01070c5
f01023cf:	e8 6c dc ff ff       	call   f0100040 <_panic>
f01023d4:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01023d7:	39 d0                	cmp    %edx,%eax
f01023d9:	75 db                	jne    f01023b6 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01023db:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01023e0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01023e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023e9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01023ef:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01023f2:	89 0d 40 f2 22 f0    	mov    %ecx,0xf022f240

	// free the pages we took
	page_free(pp0);
f01023f8:	83 ec 0c             	sub    $0xc,%esp
f01023fb:	50                   	push   %eax
f01023fc:	e8 3e ec ff ff       	call   f010103f <page_free>
	page_free(pp1);
f0102401:	89 1c 24             	mov    %ebx,(%esp)
f0102404:	e8 36 ec ff ff       	call   f010103f <page_free>
	page_free(pp2);
f0102409:	89 34 24             	mov    %esi,(%esp)
f010240c:	e8 2e ec ff ff       	call   f010103f <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102411:	83 c4 08             	add    $0x8,%esp
f0102414:	68 01 10 00 00       	push   $0x1001
f0102419:	6a 00                	push   $0x0
f010241b:	e8 20 ef ff ff       	call   f0101340 <mmio_map_region>
f0102420:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102422:	83 c4 08             	add    $0x8,%esp
f0102425:	68 00 10 00 00       	push   $0x1000
f010242a:	6a 00                	push   $0x0
f010242c:	e8 0f ef ff ff       	call   f0101340 <mmio_map_region>
f0102431:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102433:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102439:	83 c4 10             	add    $0x10,%esp
f010243c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102442:	76 07                	jbe    f010244b <mem_init+0x10a8>
f0102444:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102449:	76 19                	jbe    f0102464 <mem_init+0x10c1>
f010244b:	68 6c 6d 10 f0       	push   $0xf0106d6c
f0102450:	68 eb 70 10 f0       	push   $0xf01070eb
f0102455:	68 67 04 00 00       	push   $0x467
f010245a:	68 c5 70 10 f0       	push   $0xf01070c5
f010245f:	e8 dc db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102464:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010246a:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102470:	77 08                	ja     f010247a <mem_init+0x10d7>
f0102472:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102478:	77 19                	ja     f0102493 <mem_init+0x10f0>
f010247a:	68 94 6d 10 f0       	push   $0xf0106d94
f010247f:	68 eb 70 10 f0       	push   $0xf01070eb
f0102484:	68 68 04 00 00       	push   $0x468
f0102489:	68 c5 70 10 f0       	push   $0xf01070c5
f010248e:	e8 ad db ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102493:	89 da                	mov    %ebx,%edx
f0102495:	09 f2                	or     %esi,%edx
f0102497:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010249d:	74 19                	je     f01024b8 <mem_init+0x1115>
f010249f:	68 bc 6d 10 f0       	push   $0xf0106dbc
f01024a4:	68 eb 70 10 f0       	push   $0xf01070eb
f01024a9:	68 6a 04 00 00       	push   $0x46a
f01024ae:	68 c5 70 10 f0       	push   $0xf01070c5
f01024b3:	e8 88 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01024b8:	39 c6                	cmp    %eax,%esi
f01024ba:	73 19                	jae    f01024d5 <mem_init+0x1132>
f01024bc:	68 7c 73 10 f0       	push   $0xf010737c
f01024c1:	68 eb 70 10 f0       	push   $0xf01070eb
f01024c6:	68 6c 04 00 00       	push   $0x46c
f01024cb:	68 c5 70 10 f0       	push   $0xf01070c5
f01024d0:	e8 6b db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01024d5:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f01024db:	89 da                	mov    %ebx,%edx
f01024dd:	89 f8                	mov    %edi,%eax
f01024df:	e8 03 e6 ff ff       	call   f0100ae7 <check_va2pa>
f01024e4:	85 c0                	test   %eax,%eax
f01024e6:	74 19                	je     f0102501 <mem_init+0x115e>
f01024e8:	68 e4 6d 10 f0       	push   $0xf0106de4
f01024ed:	68 eb 70 10 f0       	push   $0xf01070eb
f01024f2:	68 6e 04 00 00       	push   $0x46e
f01024f7:	68 c5 70 10 f0       	push   $0xf01070c5
f01024fc:	e8 3f db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102501:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102507:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010250a:	89 c2                	mov    %eax,%edx
f010250c:	89 f8                	mov    %edi,%eax
f010250e:	e8 d4 e5 ff ff       	call   f0100ae7 <check_va2pa>
f0102513:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102518:	74 19                	je     f0102533 <mem_init+0x1190>
f010251a:	68 08 6e 10 f0       	push   $0xf0106e08
f010251f:	68 eb 70 10 f0       	push   $0xf01070eb
f0102524:	68 6f 04 00 00       	push   $0x46f
f0102529:	68 c5 70 10 f0       	push   $0xf01070c5
f010252e:	e8 0d db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102533:	89 f2                	mov    %esi,%edx
f0102535:	89 f8                	mov    %edi,%eax
f0102537:	e8 ab e5 ff ff       	call   f0100ae7 <check_va2pa>
f010253c:	85 c0                	test   %eax,%eax
f010253e:	74 19                	je     f0102559 <mem_init+0x11b6>
f0102540:	68 38 6e 10 f0       	push   $0xf0106e38
f0102545:	68 eb 70 10 f0       	push   $0xf01070eb
f010254a:	68 70 04 00 00       	push   $0x470
f010254f:	68 c5 70 10 f0       	push   $0xf01070c5
f0102554:	e8 e7 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102559:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010255f:	89 f8                	mov    %edi,%eax
f0102561:	e8 81 e5 ff ff       	call   f0100ae7 <check_va2pa>
f0102566:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102569:	74 19                	je     f0102584 <mem_init+0x11e1>
f010256b:	68 5c 6e 10 f0       	push   $0xf0106e5c
f0102570:	68 eb 70 10 f0       	push   $0xf01070eb
f0102575:	68 71 04 00 00       	push   $0x471
f010257a:	68 c5 70 10 f0       	push   $0xf01070c5
f010257f:	e8 bc da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102584:	83 ec 04             	sub    $0x4,%esp
f0102587:	6a 00                	push   $0x0
f0102589:	53                   	push   %ebx
f010258a:	57                   	push   %edi
f010258b:	e8 11 eb ff ff       	call   f01010a1 <pgdir_walk>
f0102590:	83 c4 10             	add    $0x10,%esp
f0102593:	f6 00 1a             	testb  $0x1a,(%eax)
f0102596:	75 19                	jne    f01025b1 <mem_init+0x120e>
f0102598:	68 88 6e 10 f0       	push   $0xf0106e88
f010259d:	68 eb 70 10 f0       	push   $0xf01070eb
f01025a2:	68 73 04 00 00       	push   $0x473
f01025a7:	68 c5 70 10 f0       	push   $0xf01070c5
f01025ac:	e8 8f da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01025b1:	83 ec 04             	sub    $0x4,%esp
f01025b4:	6a 00                	push   $0x0
f01025b6:	53                   	push   %ebx
f01025b7:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01025bd:	e8 df ea ff ff       	call   f01010a1 <pgdir_walk>
f01025c2:	8b 00                	mov    (%eax),%eax
f01025c4:	83 c4 10             	add    $0x10,%esp
f01025c7:	83 e0 04             	and    $0x4,%eax
f01025ca:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01025cd:	74 19                	je     f01025e8 <mem_init+0x1245>
f01025cf:	68 cc 6e 10 f0       	push   $0xf0106ecc
f01025d4:	68 eb 70 10 f0       	push   $0xf01070eb
f01025d9:	68 74 04 00 00       	push   $0x474
f01025de:	68 c5 70 10 f0       	push   $0xf01070c5
f01025e3:	e8 58 da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01025e8:	83 ec 04             	sub    $0x4,%esp
f01025eb:	6a 00                	push   $0x0
f01025ed:	53                   	push   %ebx
f01025ee:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01025f4:	e8 a8 ea ff ff       	call   f01010a1 <pgdir_walk>
f01025f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01025ff:	83 c4 0c             	add    $0xc,%esp
f0102602:	6a 00                	push   $0x0
f0102604:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102607:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010260d:	e8 8f ea ff ff       	call   f01010a1 <pgdir_walk>
f0102612:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102618:	83 c4 0c             	add    $0xc,%esp
f010261b:	6a 00                	push   $0x0
f010261d:	56                   	push   %esi
f010261e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102624:	e8 78 ea ff ff       	call   f01010a1 <pgdir_walk>
f0102629:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010262f:	c7 04 24 8e 73 10 f0 	movl   $0xf010738e,(%esp)
f0102636:	e8 68 10 00 00       	call   f01036a3 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_U));
f010263b:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102640:	83 c4 10             	add    $0x10,%esp
f0102643:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102648:	77 15                	ja     f010265f <mem_init+0x12bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010264a:	50                   	push   %eax
f010264b:	68 c8 61 10 f0       	push   $0xf01061c8
f0102650:	68 cd 00 00 00       	push   $0xcd
f0102655:	68 c5 70 10 f0       	push   $0xf01070c5
f010265a:	e8 e1 d9 ff ff       	call   f0100040 <_panic>
f010265f:	83 ec 08             	sub    $0x8,%esp
f0102662:	6a 05                	push   $0x5
f0102664:	05 00 00 00 10       	add    $0x10000000,%eax
f0102669:	50                   	push   %eax
f010266a:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010266f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102674:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102679:	e8 f5 ea ff ff       	call   f0101173 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_U));
f010267e:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102683:	83 c4 10             	add    $0x10,%esp
f0102686:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010268b:	77 15                	ja     f01026a2 <mem_init+0x12ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010268d:	50                   	push   %eax
f010268e:	68 c8 61 10 f0       	push   $0xf01061c8
f0102693:	68 d7 00 00 00       	push   $0xd7
f0102698:	68 c5 70 10 f0       	push   $0xf01070c5
f010269d:	e8 9e d9 ff ff       	call   f0100040 <_panic>
f01026a2:	83 ec 08             	sub    $0x8,%esp
f01026a5:	6a 05                	push   $0x5
f01026a7:	05 00 00 00 10       	add    $0x10000000,%eax
f01026ac:	50                   	push   %eax
f01026ad:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f01026b2:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01026b7:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01026bc:	e8 b2 ea ff ff       	call   f0101173 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026c1:	83 c4 10             	add    $0x10,%esp
f01026c4:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f01026c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026ce:	77 15                	ja     f01026e5 <mem_init+0x1342>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026d0:	50                   	push   %eax
f01026d1:	68 c8 61 10 f0       	push   $0xf01061c8
f01026d6:	68 e4 00 00 00       	push   $0xe4
f01026db:	68 c5 70 10 f0       	push   $0xf01070c5
f01026e0:	e8 5b d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01026e5:	83 ec 08             	sub    $0x8,%esp
f01026e8:	6a 02                	push   $0x2
f01026ea:	68 00 60 11 00       	push   $0x116000
f01026ef:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026f4:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026f9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01026fe:	e8 70 ea ff ff       	call   f0101173 <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102703:	83 c4 08             	add    $0x8,%esp
f0102706:	6a 02                	push   $0x2
f0102708:	6a 00                	push   $0x0
f010270a:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010270f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102714:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102719:	e8 55 ea ff ff       	call   f0101173 <boot_map_region>
f010271e:	c7 45 c4 00 10 23 f0 	movl   $0xf0231000,-0x3c(%ebp)
f0102725:	83 c4 10             	add    $0x10,%esp
f0102728:	bb 00 10 23 f0       	mov    $0xf0231000,%ebx
f010272d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102732:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102738:	77 15                	ja     f010274f <mem_init+0x13ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010273a:	53                   	push   %ebx
f010273b:	68 c8 61 10 f0       	push   $0xf01061c8
f0102740:	68 24 01 00 00       	push   $0x124
f0102745:	68 c5 70 10 f0       	push   $0xf01070c5
f010274a:	e8 f1 d8 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
	{
		boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE - i * (KSTKSIZE + KSTKGAP), KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f010274f:	83 ec 08             	sub    $0x8,%esp
f0102752:	6a 02                	push   $0x2
f0102754:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010275a:	50                   	push   %eax
f010275b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102760:	89 f2                	mov    %esi,%edx
f0102762:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102767:	e8 07 ea ff ff       	call   f0101173 <boot_map_region>
f010276c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102772:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
f0102778:	83 c4 10             	add    $0x10,%esp
f010277b:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f0102780:	39 d8                	cmp    %ebx,%eax
f0102782:	75 ae                	jne    f0102732 <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102784:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010278a:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010278f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102792:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102799:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010279e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027a1:	8b 35 90 fe 22 f0    	mov    0xf022fe90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027a7:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027aa:	bb 00 00 00 00       	mov    $0x0,%ebx
f01027af:	eb 55                	jmp    f0102806 <mem_init+0x1463>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027b1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01027b7:	89 f8                	mov    %edi,%eax
f01027b9:	e8 29 e3 ff ff       	call   f0100ae7 <check_va2pa>
f01027be:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01027c5:	77 15                	ja     f01027dc <mem_init+0x1439>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027c7:	56                   	push   %esi
f01027c8:	68 c8 61 10 f0       	push   $0xf01061c8
f01027cd:	68 8c 03 00 00       	push   $0x38c
f01027d2:	68 c5 70 10 f0       	push   $0xf01070c5
f01027d7:	e8 64 d8 ff ff       	call   f0100040 <_panic>
f01027dc:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01027e3:	39 c2                	cmp    %eax,%edx
f01027e5:	74 19                	je     f0102800 <mem_init+0x145d>
f01027e7:	68 00 6f 10 f0       	push   $0xf0106f00
f01027ec:	68 eb 70 10 f0       	push   $0xf01070eb
f01027f1:	68 8c 03 00 00       	push   $0x38c
f01027f6:	68 c5 70 10 f0       	push   $0xf01070c5
f01027fb:	e8 40 d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102800:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102806:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102809:	77 a6                	ja     f01027b1 <mem_init+0x140e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010280b:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102811:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102814:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102819:	89 da                	mov    %ebx,%edx
f010281b:	89 f8                	mov    %edi,%eax
f010281d:	e8 c5 e2 ff ff       	call   f0100ae7 <check_va2pa>
f0102822:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102829:	77 15                	ja     f0102840 <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010282b:	56                   	push   %esi
f010282c:	68 c8 61 10 f0       	push   $0xf01061c8
f0102831:	68 91 03 00 00       	push   $0x391
f0102836:	68 c5 70 10 f0       	push   $0xf01070c5
f010283b:	e8 00 d8 ff ff       	call   f0100040 <_panic>
f0102840:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102847:	39 d0                	cmp    %edx,%eax
f0102849:	74 19                	je     f0102864 <mem_init+0x14c1>
f010284b:	68 34 6f 10 f0       	push   $0xf0106f34
f0102850:	68 eb 70 10 f0       	push   $0xf01070eb
f0102855:	68 91 03 00 00       	push   $0x391
f010285a:	68 c5 70 10 f0       	push   $0xf01070c5
f010285f:	e8 dc d7 ff ff       	call   f0100040 <_panic>
f0102864:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010286a:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102870:	75 a7                	jne    f0102819 <mem_init+0x1476>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102872:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102875:	c1 e6 0c             	shl    $0xc,%esi
f0102878:	bb 00 00 00 00       	mov    $0x0,%ebx
f010287d:	eb 30                	jmp    f01028af <mem_init+0x150c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010287f:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102885:	89 f8                	mov    %edi,%eax
f0102887:	e8 5b e2 ff ff       	call   f0100ae7 <check_va2pa>
f010288c:	39 c3                	cmp    %eax,%ebx
f010288e:	74 19                	je     f01028a9 <mem_init+0x1506>
f0102890:	68 68 6f 10 f0       	push   $0xf0106f68
f0102895:	68 eb 70 10 f0       	push   $0xf01070eb
f010289a:	68 95 03 00 00       	push   $0x395
f010289f:	68 c5 70 10 f0       	push   $0xf01070c5
f01028a4:	e8 97 d7 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028a9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028af:	39 f3                	cmp    %esi,%ebx
f01028b1:	72 cc                	jb     f010287f <mem_init+0x14dc>
f01028b3:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01028b8:	89 75 cc             	mov    %esi,-0x34(%ebp)
f01028bb:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01028be:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028c1:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01028c7:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01028ca:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01028cc:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01028cf:	05 00 80 00 20       	add    $0x20008000,%eax
f01028d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01028d7:	89 da                	mov    %ebx,%edx
f01028d9:	89 f8                	mov    %edi,%eax
f01028db:	e8 07 e2 ff ff       	call   f0100ae7 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028e0:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01028e6:	77 15                	ja     f01028fd <mem_init+0x155a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028e8:	56                   	push   %esi
f01028e9:	68 c8 61 10 f0       	push   $0xf01061c8
f01028ee:	68 9d 03 00 00       	push   $0x39d
f01028f3:	68 c5 70 10 f0       	push   $0xf01070c5
f01028f8:	e8 43 d7 ff ff       	call   f0100040 <_panic>
f01028fd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102900:	8d 94 0b 00 10 23 f0 	lea    -0xfdcf000(%ebx,%ecx,1),%edx
f0102907:	39 d0                	cmp    %edx,%eax
f0102909:	74 19                	je     f0102924 <mem_init+0x1581>
f010290b:	68 90 6f 10 f0       	push   $0xf0106f90
f0102910:	68 eb 70 10 f0       	push   $0xf01070eb
f0102915:	68 9d 03 00 00       	push   $0x39d
f010291a:	68 c5 70 10 f0       	push   $0xf01070c5
f010291f:	e8 1c d7 ff ff       	call   f0100040 <_panic>
f0102924:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010292a:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f010292d:	75 a8                	jne    f01028d7 <mem_init+0x1534>
f010292f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102932:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102938:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010293b:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010293d:	89 da                	mov    %ebx,%edx
f010293f:	89 f8                	mov    %edi,%eax
f0102941:	e8 a1 e1 ff ff       	call   f0100ae7 <check_va2pa>
f0102946:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102949:	74 19                	je     f0102964 <mem_init+0x15c1>
f010294b:	68 d8 6f 10 f0       	push   $0xf0106fd8
f0102950:	68 eb 70 10 f0       	push   $0xf01070eb
f0102955:	68 9f 03 00 00       	push   $0x39f
f010295a:	68 c5 70 10 f0       	push   $0xf01070c5
f010295f:	e8 dc d6 ff ff       	call   f0100040 <_panic>
f0102964:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f010296a:	39 f3                	cmp    %esi,%ebx
f010296c:	75 cf                	jne    f010293d <mem_init+0x159a>
f010296e:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102971:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102978:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010297f:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102985:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f010298a:	39 f0                	cmp    %esi,%eax
f010298c:	0f 85 2c ff ff ff    	jne    f01028be <mem_init+0x151b>
f0102992:	b8 00 00 00 00       	mov    $0x0,%eax
f0102997:	eb 2a                	jmp    f01029c3 <mem_init+0x1620>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102999:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010299f:	83 fa 04             	cmp    $0x4,%edx
f01029a2:	77 1f                	ja     f01029c3 <mem_init+0x1620>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f01029a4:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01029a8:	75 7e                	jne    f0102a28 <mem_init+0x1685>
f01029aa:	68 a7 73 10 f0       	push   $0xf01073a7
f01029af:	68 eb 70 10 f0       	push   $0xf01070eb
f01029b4:	68 aa 03 00 00       	push   $0x3aa
f01029b9:	68 c5 70 10 f0       	push   $0xf01070c5
f01029be:	e8 7d d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01029c3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029c8:	76 3f                	jbe    f0102a09 <mem_init+0x1666>
				assert(pgdir[i] & PTE_P);
f01029ca:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01029cd:	f6 c2 01             	test   $0x1,%dl
f01029d0:	75 19                	jne    f01029eb <mem_init+0x1648>
f01029d2:	68 a7 73 10 f0       	push   $0xf01073a7
f01029d7:	68 eb 70 10 f0       	push   $0xf01070eb
f01029dc:	68 ae 03 00 00       	push   $0x3ae
f01029e1:	68 c5 70 10 f0       	push   $0xf01070c5
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01029eb:	f6 c2 02             	test   $0x2,%dl
f01029ee:	75 38                	jne    f0102a28 <mem_init+0x1685>
f01029f0:	68 b8 73 10 f0       	push   $0xf01073b8
f01029f5:	68 eb 70 10 f0       	push   $0xf01070eb
f01029fa:	68 af 03 00 00       	push   $0x3af
f01029ff:	68 c5 70 10 f0       	push   $0xf01070c5
f0102a04:	e8 37 d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a09:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102a0d:	74 19                	je     f0102a28 <mem_init+0x1685>
f0102a0f:	68 c9 73 10 f0       	push   $0xf01073c9
f0102a14:	68 eb 70 10 f0       	push   $0xf01070eb
f0102a19:	68 b1 03 00 00       	push   $0x3b1
f0102a1e:	68 c5 70 10 f0       	push   $0xf01070c5
f0102a23:	e8 18 d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a28:	83 c0 01             	add    $0x1,%eax
f0102a2b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102a30:	0f 86 63 ff ff ff    	jbe    f0102999 <mem_init+0x15f6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a36:	83 ec 0c             	sub    $0xc,%esp
f0102a39:	68 fc 6f 10 f0       	push   $0xf0106ffc
f0102a3e:	e8 60 0c 00 00       	call   f01036a3 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a43:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a48:	83 c4 10             	add    $0x10,%esp
f0102a4b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a50:	77 15                	ja     f0102a67 <mem_init+0x16c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a52:	50                   	push   %eax
f0102a53:	68 c8 61 10 f0       	push   $0xf01061c8
f0102a58:	68 fb 00 00 00       	push   $0xfb
f0102a5d:	68 c5 70 10 f0       	push   $0xf01070c5
f0102a62:	e8 d9 d5 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a67:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a6c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a74:	e8 53 e1 ff ff       	call   f0100bcc <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a79:	0f 20 c0             	mov    %cr0,%eax
f0102a7c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a7f:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a84:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a87:	83 ec 0c             	sub    $0xc,%esp
f0102a8a:	6a 00                	push   $0x0
f0102a8c:	e8 3e e5 ff ff       	call   f0100fcf <page_alloc>
f0102a91:	89 c7                	mov    %eax,%edi
f0102a93:	83 c4 10             	add    $0x10,%esp
f0102a96:	85 c0                	test   %eax,%eax
f0102a98:	75 19                	jne    f0102ab3 <mem_init+0x1710>
f0102a9a:	68 b3 71 10 f0       	push   $0xf01071b3
f0102a9f:	68 eb 70 10 f0       	push   $0xf01070eb
f0102aa4:	68 89 04 00 00       	push   $0x489
f0102aa9:	68 c5 70 10 f0       	push   $0xf01070c5
f0102aae:	e8 8d d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102ab3:	83 ec 0c             	sub    $0xc,%esp
f0102ab6:	6a 00                	push   $0x0
f0102ab8:	e8 12 e5 ff ff       	call   f0100fcf <page_alloc>
f0102abd:	89 c6                	mov    %eax,%esi
f0102abf:	83 c4 10             	add    $0x10,%esp
f0102ac2:	85 c0                	test   %eax,%eax
f0102ac4:	75 19                	jne    f0102adf <mem_init+0x173c>
f0102ac6:	68 c9 71 10 f0       	push   $0xf01071c9
f0102acb:	68 eb 70 10 f0       	push   $0xf01070eb
f0102ad0:	68 8a 04 00 00       	push   $0x48a
f0102ad5:	68 c5 70 10 f0       	push   $0xf01070c5
f0102ada:	e8 61 d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102adf:	83 ec 0c             	sub    $0xc,%esp
f0102ae2:	6a 00                	push   $0x0
f0102ae4:	e8 e6 e4 ff ff       	call   f0100fcf <page_alloc>
f0102ae9:	89 c3                	mov    %eax,%ebx
f0102aeb:	83 c4 10             	add    $0x10,%esp
f0102aee:	85 c0                	test   %eax,%eax
f0102af0:	75 19                	jne    f0102b0b <mem_init+0x1768>
f0102af2:	68 df 71 10 f0       	push   $0xf01071df
f0102af7:	68 eb 70 10 f0       	push   $0xf01070eb
f0102afc:	68 8b 04 00 00       	push   $0x48b
f0102b01:	68 c5 70 10 f0       	push   $0xf01070c5
f0102b06:	e8 35 d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102b0b:	83 ec 0c             	sub    $0xc,%esp
f0102b0e:	57                   	push   %edi
f0102b0f:	e8 2b e5 ff ff       	call   f010103f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b14:	89 f0                	mov    %esi,%eax
f0102b16:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102b1c:	c1 f8 03             	sar    $0x3,%eax
f0102b1f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b22:	89 c2                	mov    %eax,%edx
f0102b24:	c1 ea 0c             	shr    $0xc,%edx
f0102b27:	83 c4 10             	add    $0x10,%esp
f0102b2a:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102b30:	72 12                	jb     f0102b44 <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b32:	50                   	push   %eax
f0102b33:	68 a4 61 10 f0       	push   $0xf01061a4
f0102b38:	6a 58                	push   $0x58
f0102b3a:	68 d1 70 10 f0       	push   $0xf01070d1
f0102b3f:	e8 fc d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b44:	83 ec 04             	sub    $0x4,%esp
f0102b47:	68 00 10 00 00       	push   $0x1000
f0102b4c:	6a 01                	push   $0x1
f0102b4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b53:	50                   	push   %eax
f0102b54:	e8 6c 29 00 00       	call   f01054c5 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b59:	89 d8                	mov    %ebx,%eax
f0102b5b:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102b61:	c1 f8 03             	sar    $0x3,%eax
f0102b64:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b67:	89 c2                	mov    %eax,%edx
f0102b69:	c1 ea 0c             	shr    $0xc,%edx
f0102b6c:	83 c4 10             	add    $0x10,%esp
f0102b6f:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102b75:	72 12                	jb     f0102b89 <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b77:	50                   	push   %eax
f0102b78:	68 a4 61 10 f0       	push   $0xf01061a4
f0102b7d:	6a 58                	push   $0x58
f0102b7f:	68 d1 70 10 f0       	push   $0xf01070d1
f0102b84:	e8 b7 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b89:	83 ec 04             	sub    $0x4,%esp
f0102b8c:	68 00 10 00 00       	push   $0x1000
f0102b91:	6a 02                	push   $0x2
f0102b93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b98:	50                   	push   %eax
f0102b99:	e8 27 29 00 00       	call   f01054c5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b9e:	6a 02                	push   $0x2
f0102ba0:	68 00 10 00 00       	push   $0x1000
f0102ba5:	56                   	push   %esi
f0102ba6:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102bac:	e8 1d e7 ff ff       	call   f01012ce <page_insert>
	assert(pp1->pp_ref == 1);
f0102bb1:	83 c4 20             	add    $0x20,%esp
f0102bb4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bb9:	74 19                	je     f0102bd4 <mem_init+0x1831>
f0102bbb:	68 b0 72 10 f0       	push   $0xf01072b0
f0102bc0:	68 eb 70 10 f0       	push   $0xf01070eb
f0102bc5:	68 90 04 00 00       	push   $0x490
f0102bca:	68 c5 70 10 f0       	push   $0xf01070c5
f0102bcf:	e8 6c d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bd4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bdb:	01 01 01 
f0102bde:	74 19                	je     f0102bf9 <mem_init+0x1856>
f0102be0:	68 1c 70 10 f0       	push   $0xf010701c
f0102be5:	68 eb 70 10 f0       	push   $0xf01070eb
f0102bea:	68 91 04 00 00       	push   $0x491
f0102bef:	68 c5 70 10 f0       	push   $0xf01070c5
f0102bf4:	e8 47 d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bf9:	6a 02                	push   $0x2
f0102bfb:	68 00 10 00 00       	push   $0x1000
f0102c00:	53                   	push   %ebx
f0102c01:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102c07:	e8 c2 e6 ff ff       	call   f01012ce <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c0c:	83 c4 10             	add    $0x10,%esp
f0102c0f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c16:	02 02 02 
f0102c19:	74 19                	je     f0102c34 <mem_init+0x1891>
f0102c1b:	68 40 70 10 f0       	push   $0xf0107040
f0102c20:	68 eb 70 10 f0       	push   $0xf01070eb
f0102c25:	68 93 04 00 00       	push   $0x493
f0102c2a:	68 c5 70 10 f0       	push   $0xf01070c5
f0102c2f:	e8 0c d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102c34:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c39:	74 19                	je     f0102c54 <mem_init+0x18b1>
f0102c3b:	68 d2 72 10 f0       	push   $0xf01072d2
f0102c40:	68 eb 70 10 f0       	push   $0xf01070eb
f0102c45:	68 94 04 00 00       	push   $0x494
f0102c4a:	68 c5 70 10 f0       	push   $0xf01070c5
f0102c4f:	e8 ec d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102c54:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c59:	74 19                	je     f0102c74 <mem_init+0x18d1>
f0102c5b:	68 3c 73 10 f0       	push   $0xf010733c
f0102c60:	68 eb 70 10 f0       	push   $0xf01070eb
f0102c65:	68 95 04 00 00       	push   $0x495
f0102c6a:	68 c5 70 10 f0       	push   $0xf01070c5
f0102c6f:	e8 cc d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c74:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c7b:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c7e:	89 d8                	mov    %ebx,%eax
f0102c80:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102c86:	c1 f8 03             	sar    $0x3,%eax
f0102c89:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c8c:	89 c2                	mov    %eax,%edx
f0102c8e:	c1 ea 0c             	shr    $0xc,%edx
f0102c91:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102c97:	72 12                	jb     f0102cab <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c99:	50                   	push   %eax
f0102c9a:	68 a4 61 10 f0       	push   $0xf01061a4
f0102c9f:	6a 58                	push   $0x58
f0102ca1:	68 d1 70 10 f0       	push   $0xf01070d1
f0102ca6:	e8 95 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102cab:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102cb2:	03 03 03 
f0102cb5:	74 19                	je     f0102cd0 <mem_init+0x192d>
f0102cb7:	68 64 70 10 f0       	push   $0xf0107064
f0102cbc:	68 eb 70 10 f0       	push   $0xf01070eb
f0102cc1:	68 97 04 00 00       	push   $0x497
f0102cc6:	68 c5 70 10 f0       	push   $0xf01070c5
f0102ccb:	e8 70 d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cd0:	83 ec 08             	sub    $0x8,%esp
f0102cd3:	68 00 10 00 00       	push   $0x1000
f0102cd8:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102cde:	e8 96 e5 ff ff       	call   f0101279 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ce3:	83 c4 10             	add    $0x10,%esp
f0102ce6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102ceb:	74 19                	je     f0102d06 <mem_init+0x1963>
f0102ced:	68 0a 73 10 f0       	push   $0xf010730a
f0102cf2:	68 eb 70 10 f0       	push   $0xf01070eb
f0102cf7:	68 99 04 00 00       	push   $0x499
f0102cfc:	68 c5 70 10 f0       	push   $0xf01070c5
f0102d01:	e8 3a d3 ff ff       	call   f0100040 <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d06:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d09:	5b                   	pop    %ebx
f0102d0a:	5e                   	pop    %esi
f0102d0b:	5f                   	pop    %edi
f0102d0c:	5d                   	pop    %ebp
f0102d0d:	c3                   	ret    

f0102d0e <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102d0e:	55                   	push   %ebp
f0102d0f:	89 e5                	mov    %esp,%ebp
f0102d11:	57                   	push   %edi
f0102d12:	56                   	push   %esi
f0102d13:	53                   	push   %ebx
f0102d14:	83 ec 1c             	sub    $0x1c,%esp
f0102d17:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102d1a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d1d:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);
f0102d20:	89 d8                	mov    %ebx,%eax
f0102d22:	03 45 10             	add    0x10(%ebp),%eax
f0102d25:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102d2a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d2f:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f0102d32:	eb 3e                	jmp    f0102d72 <user_mem_check+0x64>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, va, 0);
f0102d34:	83 ec 04             	sub    $0x4,%esp
f0102d37:	6a 00                	push   $0x0
f0102d39:	53                   	push   %ebx
f0102d3a:	ff 77 60             	pushl  0x60(%edi)
f0102d3d:	e8 5f e3 ff ff       	call   f01010a1 <pgdir_walk>

		if ((va >= (void*) ULIM) || !pte || ((*pte & perm) != perm))
f0102d42:	83 c4 10             	add    $0x10,%esp
f0102d45:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d4b:	77 0c                	ja     f0102d59 <user_mem_check+0x4b>
f0102d4d:	85 c0                	test   %eax,%eax
f0102d4f:	74 08                	je     f0102d59 <user_mem_check+0x4b>
f0102d51:	89 f2                	mov    %esi,%edx
f0102d53:	23 10                	and    (%eax),%edx
f0102d55:	39 d6                	cmp    %edx,%esi
f0102d57:	74 0d                	je     f0102d66 <user_mem_check+0x58>
		{
			user_mem_check_addr = (uint32_t) va;
f0102d59:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
			return -E_FAULT;
f0102d5f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d64:	eb 16                	jmp    f0102d7c <user_mem_check+0x6e>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f0102d66:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d6c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102d72:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d75:	72 bd                	jb     f0102d34 <user_mem_check+0x26>
			user_mem_check_addr = (uint32_t) va;
			return -E_FAULT;
		}		
	}

	return 0;
f0102d77:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d7f:	5b                   	pop    %ebx
f0102d80:	5e                   	pop    %esi
f0102d81:	5f                   	pop    %edi
f0102d82:	5d                   	pop    %ebp
f0102d83:	c3                   	ret    

f0102d84 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d84:	55                   	push   %ebp
f0102d85:	89 e5                	mov    %esp,%ebp
f0102d87:	53                   	push   %ebx
f0102d88:	83 ec 04             	sub    $0x4,%esp
f0102d8b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d91:	83 c8 04             	or     $0x4,%eax
f0102d94:	50                   	push   %eax
f0102d95:	ff 75 10             	pushl  0x10(%ebp)
f0102d98:	ff 75 0c             	pushl  0xc(%ebp)
f0102d9b:	53                   	push   %ebx
f0102d9c:	e8 6d ff ff ff       	call   f0102d0e <user_mem_check>
f0102da1:	83 c4 10             	add    $0x10,%esp
f0102da4:	85 c0                	test   %eax,%eax
f0102da6:	79 21                	jns    f0102dc9 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102da8:	83 ec 04             	sub    $0x4,%esp
f0102dab:	ff 35 3c f2 22 f0    	pushl  0xf022f23c
f0102db1:	ff 73 48             	pushl  0x48(%ebx)
f0102db4:	68 90 70 10 f0       	push   $0xf0107090
f0102db9:	e8 e5 08 00 00       	call   f01036a3 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102dbe:	89 1c 24             	mov    %ebx,(%esp)
f0102dc1:	e8 24 06 00 00       	call   f01033ea <env_destroy>
f0102dc6:	83 c4 10             	add    $0x10,%esp
	}
}
f0102dc9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102dcc:	c9                   	leave  
f0102dcd:	c3                   	ret    

f0102dce <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102dce:	55                   	push   %ebp
f0102dcf:	89 e5                	mov    %esp,%ebp
f0102dd1:	57                   	push   %edi
f0102dd2:	56                   	push   %esi
f0102dd3:	53                   	push   %ebx
f0102dd4:	83 ec 0c             	sub    $0xc,%esp
f0102dd7:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
f0102dd9:	89 d3                	mov    %edx,%ebx
f0102ddb:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);
f0102de1:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102de8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102dee:	eb 3d                	jmp    f0102e2d <region_alloc+0x5f>
	{
		page = page_alloc(0);
f0102df0:	83 ec 0c             	sub    $0xc,%esp
f0102df3:	6a 00                	push   $0x0
f0102df5:	e8 d5 e1 ff ff       	call   f0100fcf <page_alloc>

		if(!page)
f0102dfa:	83 c4 10             	add    $0x10,%esp
f0102dfd:	85 c0                	test   %eax,%eax
f0102dff:	75 17                	jne    f0102e18 <region_alloc+0x4a>
			panic("region_alloc: page allocation failed!");
f0102e01:	83 ec 04             	sub    $0x4,%esp
f0102e04:	68 d8 73 10 f0       	push   $0xf01073d8
f0102e09:	68 33 01 00 00       	push   $0x133
f0102e0e:	68 22 74 10 f0       	push   $0xf0107422
f0102e13:	e8 28 d2 ff ff       	call   f0100040 <_panic>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
f0102e18:	6a 06                	push   $0x6
f0102e1a:	53                   	push   %ebx
f0102e1b:	50                   	push   %eax
f0102e1c:	ff 77 60             	pushl  0x60(%edi)
f0102e1f:	e8 aa e4 ff ff       	call   f01012ce <page_insert>
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102e24:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e2a:	83 c4 10             	add    $0x10,%esp
f0102e2d:	39 f3                	cmp    %esi,%ebx
f0102e2f:	72 bf                	jb     f0102df0 <region_alloc+0x22>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
	}
	
	
}
f0102e31:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e34:	5b                   	pop    %ebx
f0102e35:	5e                   	pop    %esi
f0102e36:	5f                   	pop    %edi
f0102e37:	5d                   	pop    %ebp
f0102e38:	c3                   	ret    

f0102e39 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e39:	55                   	push   %ebp
f0102e3a:	89 e5                	mov    %esp,%ebp
f0102e3c:	56                   	push   %esi
f0102e3d:	53                   	push   %ebx
f0102e3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e41:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e44:	85 c0                	test   %eax,%eax
f0102e46:	75 1a                	jne    f0102e62 <envid2env+0x29>
		*env_store = curenv;
f0102e48:	e8 99 2c 00 00       	call   f0105ae6 <cpunum>
f0102e4d:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e50:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102e56:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e59:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e60:	eb 70                	jmp    f0102ed2 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e62:	89 c3                	mov    %eax,%ebx
f0102e64:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e6a:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e6d:	03 1d 44 f2 22 f0    	add    0xf022f244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e73:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e77:	74 05                	je     f0102e7e <envid2env+0x45>
f0102e79:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e7c:	74 10                	je     f0102e8e <envid2env+0x55>
		*env_store = 0;
f0102e7e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e81:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e87:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e8c:	eb 44                	jmp    f0102ed2 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e8e:	84 d2                	test   %dl,%dl
f0102e90:	74 36                	je     f0102ec8 <envid2env+0x8f>
f0102e92:	e8 4f 2c 00 00       	call   f0105ae6 <cpunum>
f0102e97:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e9a:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0102ea0:	74 26                	je     f0102ec8 <envid2env+0x8f>
f0102ea2:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102ea5:	e8 3c 2c 00 00       	call   f0105ae6 <cpunum>
f0102eaa:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ead:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102eb3:	3b 70 48             	cmp    0x48(%eax),%esi
f0102eb6:	74 10                	je     f0102ec8 <envid2env+0x8f>
		*env_store = 0;
f0102eb8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ebb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ec1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ec6:	eb 0a                	jmp    f0102ed2 <envid2env+0x99>
	}

	*env_store = e;
f0102ec8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ecb:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102ecd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ed2:	5b                   	pop    %ebx
f0102ed3:	5e                   	pop    %esi
f0102ed4:	5d                   	pop    %ebp
f0102ed5:	c3                   	ret    

f0102ed6 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102ed6:	55                   	push   %ebp
f0102ed7:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102ed9:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0102ede:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102ee1:	b8 23 00 00 00       	mov    $0x23,%eax
f0102ee6:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102ee8:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102eea:	b8 10 00 00 00       	mov    $0x10,%eax
f0102eef:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102ef1:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102ef3:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102ef5:	ea fc 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102efc
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102efc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f01:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102f04:	5d                   	pop    %ebp
f0102f05:	c3                   	ret    

f0102f06 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102f06:	55                   	push   %ebp
f0102f07:	89 e5                	mov    %esp,%ebp
f0102f09:	56                   	push   %esi
f0102f0a:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
	{
		envs[i].env_id = 0;
f0102f0b:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
f0102f11:	8b 15 48 f2 22 f0    	mov    0xf022f248,%edx
f0102f17:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102f1d:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f20:	89 c1                	mov    %eax,%ecx
f0102f22:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102f29:	89 50 44             	mov    %edx,0x44(%eax)
f0102f2c:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];	
f0102f2f:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
f0102f31:	39 d8                	cmp    %ebx,%eax
f0102f33:	75 eb                	jne    f0102f20 <env_init+0x1a>
f0102f35:	89 35 48 f2 22 f0    	mov    %esi,0xf022f248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];	
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102f3b:	e8 96 ff ff ff       	call   f0102ed6 <env_init_percpu>
}
f0102f40:	5b                   	pop    %ebx
f0102f41:	5e                   	pop    %esi
f0102f42:	5d                   	pop    %ebp
f0102f43:	c3                   	ret    

f0102f44 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f44:	55                   	push   %ebp
f0102f45:	89 e5                	mov    %esp,%ebp
f0102f47:	53                   	push   %ebx
f0102f48:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f4b:	8b 1d 48 f2 22 f0    	mov    0xf022f248,%ebx
f0102f51:	85 db                	test   %ebx,%ebx
f0102f53:	0f 84 70 01 00 00    	je     f01030c9 <env_alloc+0x185>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f59:	83 ec 0c             	sub    $0xc,%esp
f0102f5c:	6a 01                	push   $0x1
f0102f5e:	e8 6c e0 ff ff       	call   f0100fcf <page_alloc>
f0102f63:	83 c4 10             	add    $0x10,%esp
f0102f66:	85 c0                	test   %eax,%eax
f0102f68:	0f 84 62 01 00 00    	je     f01030d0 <env_alloc+0x18c>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102f6e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f73:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102f79:	c1 f8 03             	sar    $0x3,%eax
f0102f7c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f7f:	89 c2                	mov    %eax,%edx
f0102f81:	c1 ea 0c             	shr    $0xc,%edx
f0102f84:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102f8a:	72 12                	jb     f0102f9e <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f8c:	50                   	push   %eax
f0102f8d:	68 a4 61 10 f0       	push   $0xf01061a4
f0102f92:	6a 58                	push   $0x58
f0102f94:	68 d1 70 10 f0       	push   $0xf01070d1
f0102f99:	e8 a2 d0 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = (pde_t*) page2kva(p);
f0102f9e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102fa3:	89 43 60             	mov    %eax,0x60(%ebx)
f0102fa6:	b8 ec 0e 00 00       	mov    $0xeec,%eax
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102fab:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0102fb1:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102fb4:	8b 53 60             	mov    0x60(%ebx),%edx
f0102fb7:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102fba:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*) page2kva(p);
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
f0102fbd:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102fc2:	75 e7                	jne    f0102fab <env_alloc+0x67>
		e->env_pgdir[i] = kern_pgdir[i];
	}

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102fc4:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fc7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102fcc:	77 15                	ja     f0102fe3 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fce:	50                   	push   %eax
f0102fcf:	68 c8 61 10 f0       	push   $0xf01061c8
f0102fd4:	68 ca 00 00 00       	push   $0xca
f0102fd9:	68 22 74 10 f0       	push   $0xf0107422
f0102fde:	e8 5d d0 ff ff       	call   f0100040 <_panic>
f0102fe3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102fe9:	83 ca 05             	or     $0x5,%edx
f0102fec:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102ff2:	8b 43 48             	mov    0x48(%ebx),%eax
f0102ff5:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102ffa:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103004:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103007:	89 da                	mov    %ebx,%edx
f0103009:	2b 15 44 f2 22 f0    	sub    0xf022f244,%edx
f010300f:	c1 fa 02             	sar    $0x2,%edx
f0103012:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103018:	09 d0                	or     %edx,%eax
f010301a:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010301d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103020:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103023:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010302a:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103031:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103038:	83 ec 04             	sub    $0x4,%esp
f010303b:	6a 44                	push   $0x44
f010303d:	6a 00                	push   $0x0
f010303f:	53                   	push   %ebx
f0103040:	e8 80 24 00 00       	call   f01054c5 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103045:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010304b:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103051:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103057:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010305e:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;	
f0103064:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010306b:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103072:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103076:	8b 43 44             	mov    0x44(%ebx),%eax
f0103079:	a3 48 f2 22 f0       	mov    %eax,0xf022f248
	*newenv_store = e;
f010307e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103081:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103083:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103086:	e8 5b 2a 00 00       	call   f0105ae6 <cpunum>
f010308b:	6b c0 74             	imul   $0x74,%eax,%eax
f010308e:	83 c4 10             	add    $0x10,%esp
f0103091:	ba 00 00 00 00       	mov    $0x0,%edx
f0103096:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010309d:	74 11                	je     f01030b0 <env_alloc+0x16c>
f010309f:	e8 42 2a 00 00       	call   f0105ae6 <cpunum>
f01030a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01030a7:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01030ad:	8b 50 48             	mov    0x48(%eax),%edx
f01030b0:	83 ec 04             	sub    $0x4,%esp
f01030b3:	53                   	push   %ebx
f01030b4:	52                   	push   %edx
f01030b5:	68 2d 74 10 f0       	push   $0xf010742d
f01030ba:	e8 e4 05 00 00       	call   f01036a3 <cprintf>
	return 0;
f01030bf:	83 c4 10             	add    $0x10,%esp
f01030c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01030c7:	eb 0c                	jmp    f01030d5 <env_alloc+0x191>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01030c9:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01030ce:	eb 05                	jmp    f01030d5 <env_alloc+0x191>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01030d0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01030d5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030d8:	c9                   	leave  
f01030d9:	c3                   	ret    

f01030da <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01030da:	55                   	push   %ebp
f01030db:	89 e5                	mov    %esp,%ebp
f01030dd:	57                   	push   %edi
f01030de:	56                   	push   %esi
f01030df:	53                   	push   %ebx
f01030e0:	83 ec 34             	sub    $0x34,%esp
f01030e3:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e = NULL;
f01030e6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uint32_t result = env_alloc(&e, 0);
f01030ed:	6a 00                	push   $0x0
f01030ef:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030f2:	50                   	push   %eax
f01030f3:	e8 4c fe ff ff       	call   f0102f44 <env_alloc>

	if(result !=  0)
f01030f8:	83 c4 10             	add    $0x10,%esp
f01030fb:	85 c0                	test   %eax,%eax
f01030fd:	74 15                	je     f0103114 <env_create+0x3a>
		panic("env_create: %e", result);
f01030ff:	50                   	push   %eax
f0103100:	68 42 74 10 f0       	push   $0xf0107442
f0103105:	68 a2 01 00 00       	push   $0x1a2
f010310a:	68 22 74 10 f0       	push   $0xf0107422
f010310f:	e8 2c cf ff ff       	call   f0100040 <_panic>

	load_icode(e, binary);
f0103114:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103117:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph = NULL, *eph = NULL;
	struct Elf *elf = (struct Elf*) binary;
	
	if(elf->e_magic != ELF_MAGIC)
f010311a:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103120:	74 17                	je     f0103139 <env_create+0x5f>
		panic("load icode: Elf format not valid!");
f0103122:	83 ec 04             	sub    $0x4,%esp
f0103125:	68 00 74 10 f0       	push   $0xf0107400
f010312a:	68 75 01 00 00       	push   $0x175
f010312f:	68 22 74 10 f0       	push   $0xf0107422
f0103134:	e8 07 cf ff ff       	call   f0100040 <_panic>

	ph = (struct Proghdr*) (binary + elf->e_phoff);
f0103139:	89 fb                	mov    %edi,%ebx
f010313b:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f010313e:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103142:	c1 e6 05             	shl    $0x5,%esi
f0103145:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0103147:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010314a:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010314d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103152:	77 15                	ja     f0103169 <env_create+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103154:	50                   	push   %eax
f0103155:	68 c8 61 10 f0       	push   $0xf01061c8
f010315a:	68 7a 01 00 00       	push   $0x17a
f010315f:	68 22 74 10 f0       	push   $0xf0107422
f0103164:	e8 d7 ce ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103169:	05 00 00 00 10       	add    $0x10000000,%eax
f010316e:	0f 22 d8             	mov    %eax,%cr3
f0103171:	eb 44                	jmp    f01031b7 <env_create+0xdd>

	for( ; ph < eph; ++ph)
	{
		if(ph->p_type != ELF_PROG_LOAD)
f0103173:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103176:	75 3c                	jne    f01031b4 <env_create+0xda>
			continue;		

		region_alloc(e, (void*) ph->p_va, ph->p_memsz);
f0103178:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010317b:	8b 53 08             	mov    0x8(%ebx),%edx
f010317e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103181:	e8 48 fc ff ff       	call   f0102dce <region_alloc>
		
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103186:	83 ec 04             	sub    $0x4,%esp
f0103189:	ff 73 10             	pushl  0x10(%ebx)
f010318c:	89 f8                	mov    %edi,%eax
f010318e:	03 43 04             	add    0x4(%ebx),%eax
f0103191:	50                   	push   %eax
f0103192:	ff 73 08             	pushl  0x8(%ebx)
f0103195:	e8 e0 23 00 00       	call   f010557a <memcpy>
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
f010319a:	8b 43 10             	mov    0x10(%ebx),%eax
f010319d:	83 c4 0c             	add    $0xc,%esp
f01031a0:	8b 53 14             	mov    0x14(%ebx),%edx
f01031a3:	29 c2                	sub    %eax,%edx
f01031a5:	52                   	push   %edx
f01031a6:	6a 00                	push   $0x0
f01031a8:	03 43 08             	add    0x8(%ebx),%eax
f01031ab:	50                   	push   %eax
f01031ac:	e8 14 23 00 00       	call   f01054c5 <memset>
f01031b1:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr*) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	for( ; ph < eph; ++ph)
f01031b4:	83 c3 20             	add    $0x20,%ebx
f01031b7:	39 de                	cmp    %ebx,%esi
f01031b9:	77 b8                	ja     f0103173 <env_create+0x99>
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
	}

	e->env_tf.tf_eip = elf->e_entry;
f01031bb:	8b 47 18             	mov    0x18(%edi),%eax
f01031be:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01031c1:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*) USTACKTOP - PGSIZE, PGSIZE);
f01031c4:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031c9:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031ce:	89 f8                	mov    %edi,%eax
f01031d0:	e8 f9 fb ff ff       	call   f0102dce <region_alloc>

	lcr3(PADDR(kern_pgdir));
f01031d5:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031da:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031df:	77 15                	ja     f01031f6 <env_create+0x11c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031e1:	50                   	push   %eax
f01031e2:	68 c8 61 10 f0       	push   $0xf01061c8
f01031e7:	68 90 01 00 00       	push   $0x190
f01031ec:	68 22 74 10 f0       	push   $0xf0107422
f01031f1:	e8 4a ce ff ff       	call   f0100040 <_panic>
f01031f6:	05 00 00 00 10       	add    $0x10000000,%eax
f01031fb:	0f 22 d8             	mov    %eax,%cr3

	if(result !=  0)
		panic("env_create: %e", result);

	load_icode(e, binary);
	e->env_type = type;
f01031fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103201:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103204:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103207:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010320a:	5b                   	pop    %ebx
f010320b:	5e                   	pop    %esi
f010320c:	5f                   	pop    %edi
f010320d:	5d                   	pop    %ebp
f010320e:	c3                   	ret    

f010320f <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010320f:	55                   	push   %ebp
f0103210:	89 e5                	mov    %esp,%ebp
f0103212:	57                   	push   %edi
f0103213:	56                   	push   %esi
f0103214:	53                   	push   %ebx
f0103215:	83 ec 1c             	sub    $0x1c,%esp
f0103218:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010321b:	e8 c6 28 00 00       	call   f0105ae6 <cpunum>
f0103220:	6b c0 74             	imul   $0x74,%eax,%eax
f0103223:	39 b8 28 00 23 f0    	cmp    %edi,-0xfdcffd8(%eax)
f0103229:	75 29                	jne    f0103254 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010322b:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103230:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103235:	77 15                	ja     f010324c <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103237:	50                   	push   %eax
f0103238:	68 c8 61 10 f0       	push   $0xf01061c8
f010323d:	68 b6 01 00 00       	push   $0x1b6
f0103242:	68 22 74 10 f0       	push   $0xf0107422
f0103247:	e8 f4 cd ff ff       	call   f0100040 <_panic>
f010324c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103251:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103254:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103257:	e8 8a 28 00 00       	call   f0105ae6 <cpunum>
f010325c:	6b c0 74             	imul   $0x74,%eax,%eax
f010325f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103264:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010326b:	74 11                	je     f010327e <env_free+0x6f>
f010326d:	e8 74 28 00 00       	call   f0105ae6 <cpunum>
f0103272:	6b c0 74             	imul   $0x74,%eax,%eax
f0103275:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010327b:	8b 50 48             	mov    0x48(%eax),%edx
f010327e:	83 ec 04             	sub    $0x4,%esp
f0103281:	53                   	push   %ebx
f0103282:	52                   	push   %edx
f0103283:	68 51 74 10 f0       	push   $0xf0107451
f0103288:	e8 16 04 00 00       	call   f01036a3 <cprintf>
f010328d:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103290:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103297:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010329a:	89 d0                	mov    %edx,%eax
f010329c:	c1 e0 02             	shl    $0x2,%eax
f010329f:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01032a2:	8b 47 60             	mov    0x60(%edi),%eax
f01032a5:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01032a8:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01032ae:	0f 84 a8 00 00 00    	je     f010335c <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01032b4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032ba:	89 f0                	mov    %esi,%eax
f01032bc:	c1 e8 0c             	shr    $0xc,%eax
f01032bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01032c2:	39 05 88 fe 22 f0    	cmp    %eax,0xf022fe88
f01032c8:	77 15                	ja     f01032df <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032ca:	56                   	push   %esi
f01032cb:	68 a4 61 10 f0       	push   $0xf01061a4
f01032d0:	68 c5 01 00 00       	push   $0x1c5
f01032d5:	68 22 74 10 f0       	push   $0xf0107422
f01032da:	e8 61 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032df:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032e2:	c1 e0 16             	shl    $0x16,%eax
f01032e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032e8:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01032ed:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01032f4:	01 
f01032f5:	74 17                	je     f010330e <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032f7:	83 ec 08             	sub    $0x8,%esp
f01032fa:	89 d8                	mov    %ebx,%eax
f01032fc:	c1 e0 0c             	shl    $0xc,%eax
f01032ff:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103302:	50                   	push   %eax
f0103303:	ff 77 60             	pushl  0x60(%edi)
f0103306:	e8 6e df ff ff       	call   f0101279 <page_remove>
f010330b:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010330e:	83 c3 01             	add    $0x1,%ebx
f0103311:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103317:	75 d4                	jne    f01032ed <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103319:	8b 47 60             	mov    0x60(%edi),%eax
f010331c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010331f:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103326:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103329:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f010332f:	72 14                	jb     f0103345 <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103331:	83 ec 04             	sub    $0x4,%esp
f0103334:	68 94 68 10 f0       	push   $0xf0106894
f0103339:	6a 51                	push   $0x51
f010333b:	68 d1 70 10 f0       	push   $0xf01070d1
f0103340:	e8 fb cc ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103345:	83 ec 0c             	sub    $0xc,%esp
f0103348:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f010334d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103350:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103353:	50                   	push   %eax
f0103354:	e8 21 dd ff ff       	call   f010107a <page_decref>
f0103359:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010335c:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103360:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103363:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103368:	0f 85 29 ff ff ff    	jne    f0103297 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010336e:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103371:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103376:	77 15                	ja     f010338d <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103378:	50                   	push   %eax
f0103379:	68 c8 61 10 f0       	push   $0xf01061c8
f010337e:	68 d3 01 00 00       	push   $0x1d3
f0103383:	68 22 74 10 f0       	push   $0xf0107422
f0103388:	e8 b3 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010338d:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103394:	05 00 00 00 10       	add    $0x10000000,%eax
f0103399:	c1 e8 0c             	shr    $0xc,%eax
f010339c:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01033a2:	72 14                	jb     f01033b8 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f01033a4:	83 ec 04             	sub    $0x4,%esp
f01033a7:	68 94 68 10 f0       	push   $0xf0106894
f01033ac:	6a 51                	push   $0x51
f01033ae:	68 d1 70 10 f0       	push   $0xf01070d1
f01033b3:	e8 88 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f01033b8:	83 ec 0c             	sub    $0xc,%esp
f01033bb:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f01033c1:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01033c4:	50                   	push   %eax
f01033c5:	e8 b0 dc ff ff       	call   f010107a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01033ca:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01033d1:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
f01033d6:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01033d9:	89 3d 48 f2 22 f0    	mov    %edi,0xf022f248
}
f01033df:	83 c4 10             	add    $0x10,%esp
f01033e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033e5:	5b                   	pop    %ebx
f01033e6:	5e                   	pop    %esi
f01033e7:	5f                   	pop    %edi
f01033e8:	5d                   	pop    %ebp
f01033e9:	c3                   	ret    

f01033ea <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01033ea:	55                   	push   %ebp
f01033eb:	89 e5                	mov    %esp,%ebp
f01033ed:	53                   	push   %ebx
f01033ee:	83 ec 04             	sub    $0x4,%esp
f01033f1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01033f4:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01033f8:	75 19                	jne    f0103413 <env_destroy+0x29>
f01033fa:	e8 e7 26 00 00       	call   f0105ae6 <cpunum>
f01033ff:	6b c0 74             	imul   $0x74,%eax,%eax
f0103402:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0103408:	74 09                	je     f0103413 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f010340a:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103411:	eb 33                	jmp    f0103446 <env_destroy+0x5c>
	}

	env_free(e);
f0103413:	83 ec 0c             	sub    $0xc,%esp
f0103416:	53                   	push   %ebx
f0103417:	e8 f3 fd ff ff       	call   f010320f <env_free>

	if (curenv == e) {
f010341c:	e8 c5 26 00 00       	call   f0105ae6 <cpunum>
f0103421:	6b c0 74             	imul   $0x74,%eax,%eax
f0103424:	83 c4 10             	add    $0x10,%esp
f0103427:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f010342d:	75 17                	jne    f0103446 <env_destroy+0x5c>
		curenv = NULL;
f010342f:	e8 b2 26 00 00       	call   f0105ae6 <cpunum>
f0103434:	6b c0 74             	imul   $0x74,%eax,%eax
f0103437:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f010343e:	00 00 00 
		sched_yield();
f0103441:	e8 78 10 00 00       	call   f01044be <sched_yield>
	}
}
f0103446:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103449:	c9                   	leave  
f010344a:	c3                   	ret    

f010344b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010344b:	55                   	push   %ebp
f010344c:	89 e5                	mov    %esp,%ebp
f010344e:	53                   	push   %ebx
f010344f:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103452:	e8 8f 26 00 00       	call   f0105ae6 <cpunum>
f0103457:	6b c0 74             	imul   $0x74,%eax,%eax
f010345a:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f0103460:	e8 81 26 00 00       	call   f0105ae6 <cpunum>
f0103465:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103468:	8b 65 08             	mov    0x8(%ebp),%esp
f010346b:	61                   	popa   
f010346c:	07                   	pop    %es
f010346d:	1f                   	pop    %ds
f010346e:	83 c4 08             	add    $0x8,%esp
f0103471:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103472:	83 ec 04             	sub    $0x4,%esp
f0103475:	68 67 74 10 f0       	push   $0xf0107467
f010347a:	68 0a 02 00 00       	push   $0x20a
f010347f:	68 22 74 10 f0       	push   $0xf0107422
f0103484:	e8 b7 cb ff ff       	call   f0100040 <_panic>

f0103489 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103489:	55                   	push   %ebp
f010348a:	89 e5                	mov    %esp,%ebp
f010348c:	53                   	push   %ebx
f010348d:	83 ec 04             	sub    $0x4,%esp
f0103490:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && (curenv->env_status == ENV_RUNNING))
f0103493:	e8 4e 26 00 00       	call   f0105ae6 <cpunum>
f0103498:	6b c0 74             	imul   $0x74,%eax,%eax
f010349b:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01034a2:	74 29                	je     f01034cd <env_run+0x44>
f01034a4:	e8 3d 26 00 00       	call   f0105ae6 <cpunum>
f01034a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ac:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01034b2:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01034b6:	75 15                	jne    f01034cd <env_run+0x44>
	{
		curenv->env_status = ENV_RUNNABLE;
f01034b8:	e8 29 26 00 00       	call   f0105ae6 <cpunum>
f01034bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01034c0:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01034c6:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}

	curenv = e;
f01034cd:	e8 14 26 00 00       	call   f0105ae6 <cpunum>
f01034d2:	6b c0 74             	imul   $0x74,%eax,%eax
f01034d5:	89 98 28 00 23 f0    	mov    %ebx,-0xfdcffd8(%eax)
	e->env_status = ENV_RUNNING;
f01034db:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	e->env_runs++;
f01034e2:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(e->env_pgdir));
f01034e6:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034e9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034ee:	77 15                	ja     f0103505 <env_run+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034f0:	50                   	push   %eax
f01034f1:	68 c8 61 10 f0       	push   $0xf01061c8
f01034f6:	68 30 02 00 00       	push   $0x230
f01034fb:	68 22 74 10 f0       	push   $0xf0107422
f0103500:	e8 3b cb ff ff       	call   f0100040 <_panic>
f0103505:	05 00 00 00 10       	add    $0x10000000,%eax
f010350a:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010350d:	83 ec 0c             	sub    $0xc,%esp
f0103510:	68 c0 03 12 f0       	push   $0xf01203c0
f0103515:	e8 d7 28 00 00       	call   f0105df1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010351a:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f010351c:	89 1c 24             	mov    %ebx,(%esp)
f010351f:	e8 27 ff ff ff       	call   f010344b <env_pop_tf>

f0103524 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103524:	55                   	push   %ebp
f0103525:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103527:	ba 70 00 00 00       	mov    $0x70,%edx
f010352c:	8b 45 08             	mov    0x8(%ebp),%eax
f010352f:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103530:	ba 71 00 00 00       	mov    $0x71,%edx
f0103535:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103536:	0f b6 c0             	movzbl %al,%eax
}
f0103539:	5d                   	pop    %ebp
f010353a:	c3                   	ret    

f010353b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010353b:	55                   	push   %ebp
f010353c:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010353e:	ba 70 00 00 00       	mov    $0x70,%edx
f0103543:	8b 45 08             	mov    0x8(%ebp),%eax
f0103546:	ee                   	out    %al,(%dx)
f0103547:	ba 71 00 00 00       	mov    $0x71,%edx
f010354c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010354f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103550:	5d                   	pop    %ebp
f0103551:	c3                   	ret    

f0103552 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103552:	55                   	push   %ebp
f0103553:	89 e5                	mov    %esp,%ebp
f0103555:	56                   	push   %esi
f0103556:	53                   	push   %ebx
f0103557:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010355a:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103560:	80 3d 4c f2 22 f0 00 	cmpb   $0x0,0xf022f24c
f0103567:	74 5a                	je     f01035c3 <irq_setmask_8259A+0x71>
f0103569:	89 c6                	mov    %eax,%esi
f010356b:	ba 21 00 00 00       	mov    $0x21,%edx
f0103570:	ee                   	out    %al,(%dx)
f0103571:	66 c1 e8 08          	shr    $0x8,%ax
f0103575:	ba a1 00 00 00       	mov    $0xa1,%edx
f010357a:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010357b:	83 ec 0c             	sub    $0xc,%esp
f010357e:	68 73 74 10 f0       	push   $0xf0107473
f0103583:	e8 1b 01 00 00       	call   f01036a3 <cprintf>
f0103588:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010358b:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103590:	0f b7 f6             	movzwl %si,%esi
f0103593:	f7 d6                	not    %esi
f0103595:	0f a3 de             	bt     %ebx,%esi
f0103598:	73 11                	jae    f01035ab <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010359a:	83 ec 08             	sub    $0x8,%esp
f010359d:	53                   	push   %ebx
f010359e:	68 33 79 10 f0       	push   $0xf0107933
f01035a3:	e8 fb 00 00 00       	call   f01036a3 <cprintf>
f01035a8:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01035ab:	83 c3 01             	add    $0x1,%ebx
f01035ae:	83 fb 10             	cmp    $0x10,%ebx
f01035b1:	75 e2                	jne    f0103595 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01035b3:	83 ec 0c             	sub    $0xc,%esp
f01035b6:	68 3c 65 10 f0       	push   $0xf010653c
f01035bb:	e8 e3 00 00 00       	call   f01036a3 <cprintf>
f01035c0:	83 c4 10             	add    $0x10,%esp
}
f01035c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035c6:	5b                   	pop    %ebx
f01035c7:	5e                   	pop    %esi
f01035c8:	5d                   	pop    %ebp
f01035c9:	c3                   	ret    

f01035ca <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035ca:	c6 05 4c f2 22 f0 01 	movb   $0x1,0xf022f24c
f01035d1:	ba 21 00 00 00       	mov    $0x21,%edx
f01035d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035db:	ee                   	out    %al,(%dx)
f01035dc:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035e1:	ee                   	out    %al,(%dx)
f01035e2:	ba 20 00 00 00       	mov    $0x20,%edx
f01035e7:	b8 11 00 00 00       	mov    $0x11,%eax
f01035ec:	ee                   	out    %al,(%dx)
f01035ed:	ba 21 00 00 00       	mov    $0x21,%edx
f01035f2:	b8 20 00 00 00       	mov    $0x20,%eax
f01035f7:	ee                   	out    %al,(%dx)
f01035f8:	b8 04 00 00 00       	mov    $0x4,%eax
f01035fd:	ee                   	out    %al,(%dx)
f01035fe:	b8 03 00 00 00       	mov    $0x3,%eax
f0103603:	ee                   	out    %al,(%dx)
f0103604:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103609:	b8 11 00 00 00       	mov    $0x11,%eax
f010360e:	ee                   	out    %al,(%dx)
f010360f:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103614:	b8 28 00 00 00       	mov    $0x28,%eax
f0103619:	ee                   	out    %al,(%dx)
f010361a:	b8 02 00 00 00       	mov    $0x2,%eax
f010361f:	ee                   	out    %al,(%dx)
f0103620:	b8 01 00 00 00       	mov    $0x1,%eax
f0103625:	ee                   	out    %al,(%dx)
f0103626:	ba 20 00 00 00       	mov    $0x20,%edx
f010362b:	b8 68 00 00 00       	mov    $0x68,%eax
f0103630:	ee                   	out    %al,(%dx)
f0103631:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103636:	ee                   	out    %al,(%dx)
f0103637:	ba a0 00 00 00       	mov    $0xa0,%edx
f010363c:	b8 68 00 00 00       	mov    $0x68,%eax
f0103641:	ee                   	out    %al,(%dx)
f0103642:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103647:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103648:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f010364f:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103653:	74 13                	je     f0103668 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103655:	55                   	push   %ebp
f0103656:	89 e5                	mov    %esp,%ebp
f0103658:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010365b:	0f b7 c0             	movzwl %ax,%eax
f010365e:	50                   	push   %eax
f010365f:	e8 ee fe ff ff       	call   f0103552 <irq_setmask_8259A>
f0103664:	83 c4 10             	add    $0x10,%esp
}
f0103667:	c9                   	leave  
f0103668:	f3 c3                	repz ret 

f010366a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010366a:	55                   	push   %ebp
f010366b:	89 e5                	mov    %esp,%ebp
f010366d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103670:	ff 75 08             	pushl  0x8(%ebp)
f0103673:	e8 0a d1 ff ff       	call   f0100782 <cputchar>
	*cnt++;
}
f0103678:	83 c4 10             	add    $0x10,%esp
f010367b:	c9                   	leave  
f010367c:	c3                   	ret    

f010367d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010367d:	55                   	push   %ebp
f010367e:	89 e5                	mov    %esp,%ebp
f0103680:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103683:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010368a:	ff 75 0c             	pushl  0xc(%ebp)
f010368d:	ff 75 08             	pushl  0x8(%ebp)
f0103690:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103693:	50                   	push   %eax
f0103694:	68 6a 36 10 f0       	push   $0xf010366a
f0103699:	e8 bb 17 00 00       	call   f0104e59 <vprintfmt>
	return cnt;
}
f010369e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036a1:	c9                   	leave  
f01036a2:	c3                   	ret    

f01036a3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036a3:	55                   	push   %ebp
f01036a4:	89 e5                	mov    %esp,%ebp
f01036a6:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036a9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01036ac:	50                   	push   %eax
f01036ad:	ff 75 08             	pushl  0x8(%ebp)
f01036b0:	e8 c8 ff ff ff       	call   f010367d <vcprintf>
	va_end(ap);

	return cnt;
}
f01036b5:	c9                   	leave  
f01036b6:	c3                   	ret    

f01036b7 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01036b7:	55                   	push   %ebp
f01036b8:	89 e5                	mov    %esp,%ebp
f01036ba:	57                   	push   %edi
f01036bb:	56                   	push   %esi
f01036bc:	53                   	push   %ebx
f01036bd:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:	

	// Setup a TSS so that -we get the right stack
	// when we trap to the kernel.
	size_t id = thiscpu->cpu_id;
f01036c0:	e8 21 24 00 00       	call   f0105ae6 <cpunum>
f01036c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c8:	0f b6 b0 20 00 23 f0 	movzbl -0xfdcffe0(%eax),%esi
f01036cf:	89 f0                	mov    %esi,%eax
f01036d1:	0f b6 d8             	movzbl %al,%ebx

	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f01036d4:	e8 0d 24 00 00       	call   f0105ae6 <cpunum>
f01036d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01036dc:	66 c7 80 92 00 23 f0 	movw   $0x68,-0xfdcff6e(%eax)
f01036e3:	68 00 
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036e5:	e8 fc 23 00 00       	call   f0105ae6 <cpunum>
f01036ea:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ed:	66 c7 80 34 00 23 f0 	movw   $0x10,-0xfdcffcc(%eax)
f01036f4:	10 00 
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - id * (KSTKSIZE + KSTKGAP);
f01036f6:	e8 eb 23 00 00       	call   f0105ae6 <cpunum>
f01036fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01036fe:	89 da                	mov    %ebx,%edx
f0103700:	f7 da                	neg    %edx
f0103702:	c1 e2 10             	shl    $0x10,%edx
f0103705:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010370b:	89 90 30 00 23 f0    	mov    %edx,-0xfdcffd0(%eax)

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f0103711:	83 c3 05             	add    $0x5,%ebx
f0103714:	e8 cd 23 00 00       	call   f0105ae6 <cpunum>
f0103719:	89 c7                	mov    %eax,%edi
f010371b:	e8 c6 23 00 00       	call   f0105ae6 <cpunum>
f0103720:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103723:	e8 be 23 00 00       	call   f0105ae6 <cpunum>
f0103728:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f010372f:	f0 67 00 
f0103732:	6b ff 74             	imul   $0x74,%edi,%edi
f0103735:	81 c7 2c 00 23 f0    	add    $0xf023002c,%edi
f010373b:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f0103742:	f0 
f0103743:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103747:	81 c2 2c 00 23 f0    	add    $0xf023002c,%edx
f010374d:	c1 ea 10             	shr    $0x10,%edx
f0103750:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f0103757:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f010375e:	40 
f010375f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103762:	05 2c 00 23 f0       	add    $0xf023002c,%eax
f0103767:	c1 e8 18             	shr    $0x18,%eax
f010376a:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + id].sd_s = 0;
f0103771:	c6 04 dd 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%ebx,8)
f0103778:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103779:	89 f0                	mov    %esi,%eax
f010377b:	0f b6 f0             	movzbl %al,%esi
f010377e:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f0103785:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103788:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f010378d:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (id << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103790:	83 c4 1c             	add    $0x1c,%esp
f0103793:	5b                   	pop    %ebx
f0103794:	5e                   	pop    %esi
f0103795:	5f                   	pop    %edi
f0103796:	5d                   	pop    %ebp
f0103797:	c3                   	ret    

f0103798 <trap_init>:
}


void
trap_init(void)
{
f0103798:	55                   	push   %ebp
f0103799:	89 e5                	mov    %esp,%ebp
f010379b:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f010379e:	b8 d6 42 10 f0       	mov    $0xf01042d6,%eax
f01037a3:	66 a3 60 f2 22 f0    	mov    %ax,0xf022f260
f01037a9:	66 c7 05 62 f2 22 f0 	movw   $0x8,0xf022f262
f01037b0:	08 00 
f01037b2:	c6 05 64 f2 22 f0 00 	movb   $0x0,0xf022f264
f01037b9:	c6 05 65 f2 22 f0 8e 	movb   $0x8e,0xf022f265
f01037c0:	c1 e8 10             	shr    $0x10,%eax
f01037c3:	66 a3 66 f2 22 f0    	mov    %ax,0xf022f266
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f01037c9:	b8 e0 42 10 f0       	mov    $0xf01042e0,%eax
f01037ce:	66 a3 68 f2 22 f0    	mov    %ax,0xf022f268
f01037d4:	66 c7 05 6a f2 22 f0 	movw   $0x8,0xf022f26a
f01037db:	08 00 
f01037dd:	c6 05 6c f2 22 f0 00 	movb   $0x0,0xf022f26c
f01037e4:	c6 05 6d f2 22 f0 8e 	movb   $0x8e,0xf022f26d
f01037eb:	c1 e8 10             	shr    $0x10,%eax
f01037ee:	66 a3 6e f2 22 f0    	mov    %ax,0xf022f26e
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f01037f4:	b8 ea 42 10 f0       	mov    $0xf01042ea,%eax
f01037f9:	66 a3 70 f2 22 f0    	mov    %ax,0xf022f270
f01037ff:	66 c7 05 72 f2 22 f0 	movw   $0x8,0xf022f272
f0103806:	08 00 
f0103808:	c6 05 74 f2 22 f0 00 	movb   $0x0,0xf022f274
f010380f:	c6 05 75 f2 22 f0 8e 	movb   $0x8e,0xf022f275
f0103816:	c1 e8 10             	shr    $0x10,%eax
f0103819:	66 a3 76 f2 22 f0    	mov    %ax,0xf022f276
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f010381f:	b8 f4 42 10 f0       	mov    $0xf01042f4,%eax
f0103824:	66 a3 78 f2 22 f0    	mov    %ax,0xf022f278
f010382a:	66 c7 05 7a f2 22 f0 	movw   $0x8,0xf022f27a
f0103831:	08 00 
f0103833:	c6 05 7c f2 22 f0 00 	movb   $0x0,0xf022f27c
f010383a:	c6 05 7d f2 22 f0 ee 	movb   $0xee,0xf022f27d
f0103841:	c1 e8 10             	shr    $0x10,%eax
f0103844:	66 a3 7e f2 22 f0    	mov    %ax,0xf022f27e
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f010384a:	b8 fe 42 10 f0       	mov    $0xf01042fe,%eax
f010384f:	66 a3 80 f2 22 f0    	mov    %ax,0xf022f280
f0103855:	66 c7 05 82 f2 22 f0 	movw   $0x8,0xf022f282
f010385c:	08 00 
f010385e:	c6 05 84 f2 22 f0 00 	movb   $0x0,0xf022f284
f0103865:	c6 05 85 f2 22 f0 8e 	movb   $0x8e,0xf022f285
f010386c:	c1 e8 10             	shr    $0x10,%eax
f010386f:	66 a3 86 f2 22 f0    	mov    %ax,0xf022f286
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f0103875:	b8 08 43 10 f0       	mov    $0xf0104308,%eax
f010387a:	66 a3 88 f2 22 f0    	mov    %ax,0xf022f288
f0103880:	66 c7 05 8a f2 22 f0 	movw   $0x8,0xf022f28a
f0103887:	08 00 
f0103889:	c6 05 8c f2 22 f0 00 	movb   $0x0,0xf022f28c
f0103890:	c6 05 8d f2 22 f0 8e 	movb   $0x8e,0xf022f28d
f0103897:	c1 e8 10             	shr    $0x10,%eax
f010389a:	66 a3 8e f2 22 f0    	mov    %ax,0xf022f28e
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f01038a0:	b8 12 43 10 f0       	mov    $0xf0104312,%eax
f01038a5:	66 a3 90 f2 22 f0    	mov    %ax,0xf022f290
f01038ab:	66 c7 05 92 f2 22 f0 	movw   $0x8,0xf022f292
f01038b2:	08 00 
f01038b4:	c6 05 94 f2 22 f0 00 	movb   $0x0,0xf022f294
f01038bb:	c6 05 95 f2 22 f0 8e 	movb   $0x8e,0xf022f295
f01038c2:	c1 e8 10             	shr    $0x10,%eax
f01038c5:	66 a3 96 f2 22 f0    	mov    %ax,0xf022f296
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f01038cb:	b8 1c 43 10 f0       	mov    $0xf010431c,%eax
f01038d0:	66 a3 98 f2 22 f0    	mov    %ax,0xf022f298
f01038d6:	66 c7 05 9a f2 22 f0 	movw   $0x8,0xf022f29a
f01038dd:	08 00 
f01038df:	c6 05 9c f2 22 f0 00 	movb   $0x0,0xf022f29c
f01038e6:	c6 05 9d f2 22 f0 8e 	movb   $0x8e,0xf022f29d
f01038ed:	c1 e8 10             	shr    $0x10,%eax
f01038f0:	66 a3 9e f2 22 f0    	mov    %ax,0xf022f29e
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01038f6:	b8 26 43 10 f0       	mov    $0xf0104326,%eax
f01038fb:	66 a3 a0 f2 22 f0    	mov    %ax,0xf022f2a0
f0103901:	66 c7 05 a2 f2 22 f0 	movw   $0x8,0xf022f2a2
f0103908:	08 00 
f010390a:	c6 05 a4 f2 22 f0 00 	movb   $0x0,0xf022f2a4
f0103911:	c6 05 a5 f2 22 f0 8e 	movb   $0x8e,0xf022f2a5
f0103918:	c1 e8 10             	shr    $0x10,%eax
f010391b:	66 a3 a6 f2 22 f0    	mov    %ax,0xf022f2a6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f0103921:	b8 2e 43 10 f0       	mov    $0xf010432e,%eax
f0103926:	66 a3 b0 f2 22 f0    	mov    %ax,0xf022f2b0
f010392c:	66 c7 05 b2 f2 22 f0 	movw   $0x8,0xf022f2b2
f0103933:	08 00 
f0103935:	c6 05 b4 f2 22 f0 00 	movb   $0x0,0xf022f2b4
f010393c:	c6 05 b5 f2 22 f0 8e 	movb   $0x8e,0xf022f2b5
f0103943:	c1 e8 10             	shr    $0x10,%eax
f0103946:	66 a3 b6 f2 22 f0    	mov    %ax,0xf022f2b6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f010394c:	b8 36 43 10 f0       	mov    $0xf0104336,%eax
f0103951:	66 a3 b8 f2 22 f0    	mov    %ax,0xf022f2b8
f0103957:	66 c7 05 ba f2 22 f0 	movw   $0x8,0xf022f2ba
f010395e:	08 00 
f0103960:	c6 05 bc f2 22 f0 00 	movb   $0x0,0xf022f2bc
f0103967:	c6 05 bd f2 22 f0 8e 	movb   $0x8e,0xf022f2bd
f010396e:	c1 e8 10             	shr    $0x10,%eax
f0103971:	66 a3 be f2 22 f0    	mov    %ax,0xf022f2be
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f0103977:	b8 3e 43 10 f0       	mov    $0xf010433e,%eax
f010397c:	66 a3 c0 f2 22 f0    	mov    %ax,0xf022f2c0
f0103982:	66 c7 05 c2 f2 22 f0 	movw   $0x8,0xf022f2c2
f0103989:	08 00 
f010398b:	c6 05 c4 f2 22 f0 00 	movb   $0x0,0xf022f2c4
f0103992:	c6 05 c5 f2 22 f0 8e 	movb   $0x8e,0xf022f2c5
f0103999:	c1 e8 10             	shr    $0x10,%eax
f010399c:	66 a3 c6 f2 22 f0    	mov    %ax,0xf022f2c6
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f01039a2:	b8 46 43 10 f0       	mov    $0xf0104346,%eax
f01039a7:	66 a3 c8 f2 22 f0    	mov    %ax,0xf022f2c8
f01039ad:	66 c7 05 ca f2 22 f0 	movw   $0x8,0xf022f2ca
f01039b4:	08 00 
f01039b6:	c6 05 cc f2 22 f0 00 	movb   $0x0,0xf022f2cc
f01039bd:	c6 05 cd f2 22 f0 8e 	movb   $0x8e,0xf022f2cd
f01039c4:	c1 e8 10             	shr    $0x10,%eax
f01039c7:	66 a3 ce f2 22 f0    	mov    %ax,0xf022f2ce
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f01039cd:	b8 4e 43 10 f0       	mov    $0xf010434e,%eax
f01039d2:	66 a3 d0 f2 22 f0    	mov    %ax,0xf022f2d0
f01039d8:	66 c7 05 d2 f2 22 f0 	movw   $0x8,0xf022f2d2
f01039df:	08 00 
f01039e1:	c6 05 d4 f2 22 f0 00 	movb   $0x0,0xf022f2d4
f01039e8:	c6 05 d5 f2 22 f0 8e 	movb   $0x8e,0xf022f2d5
f01039ef:	c1 e8 10             	shr    $0x10,%eax
f01039f2:	66 a3 d6 f2 22 f0    	mov    %ax,0xf022f2d6
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01039f8:	b8 56 43 10 f0       	mov    $0xf0104356,%eax
f01039fd:	66 a3 e0 f2 22 f0    	mov    %ax,0xf022f2e0
f0103a03:	66 c7 05 e2 f2 22 f0 	movw   $0x8,0xf022f2e2
f0103a0a:	08 00 
f0103a0c:	c6 05 e4 f2 22 f0 00 	movb   $0x0,0xf022f2e4
f0103a13:	c6 05 e5 f2 22 f0 8e 	movb   $0x8e,0xf022f2e5
f0103a1a:	c1 e8 10             	shr    $0x10,%eax
f0103a1d:	66 a3 e6 f2 22 f0    	mov    %ax,0xf022f2e6
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f0103a23:	b8 5c 43 10 f0       	mov    $0xf010435c,%eax
f0103a28:	66 a3 e8 f2 22 f0    	mov    %ax,0xf022f2e8
f0103a2e:	66 c7 05 ea f2 22 f0 	movw   $0x8,0xf022f2ea
f0103a35:	08 00 
f0103a37:	c6 05 ec f2 22 f0 00 	movb   $0x0,0xf022f2ec
f0103a3e:	c6 05 ed f2 22 f0 8e 	movb   $0x8e,0xf022f2ed
f0103a45:	c1 e8 10             	shr    $0x10,%eax
f0103a48:	66 a3 ee f2 22 f0    	mov    %ax,0xf022f2ee
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103a4e:	b8 60 43 10 f0       	mov    $0xf0104360,%eax
f0103a53:	66 a3 f0 f2 22 f0    	mov    %ax,0xf022f2f0
f0103a59:	66 c7 05 f2 f2 22 f0 	movw   $0x8,0xf022f2f2
f0103a60:	08 00 
f0103a62:	c6 05 f4 f2 22 f0 00 	movb   $0x0,0xf022f2f4
f0103a69:	c6 05 f5 f2 22 f0 8e 	movb   $0x8e,0xf022f2f5
f0103a70:	c1 e8 10             	shr    $0x10,%eax
f0103a73:	66 a3 f6 f2 22 f0    	mov    %ax,0xf022f2f6
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103a79:	b8 66 43 10 f0       	mov    $0xf0104366,%eax
f0103a7e:	66 a3 f8 f2 22 f0    	mov    %ax,0xf022f2f8
f0103a84:	66 c7 05 fa f2 22 f0 	movw   $0x8,0xf022f2fa
f0103a8b:	08 00 
f0103a8d:	c6 05 fc f2 22 f0 00 	movb   $0x0,0xf022f2fc
f0103a94:	c6 05 fd f2 22 f0 8e 	movb   $0x8e,0xf022f2fd
f0103a9b:	c1 e8 10             	shr    $0x10,%eax
f0103a9e:	66 a3 fe f2 22 f0    	mov    %ax,0xf022f2fe
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 0, GD_KT, TH_SYSCALL, 3); 
f0103aa4:	b8 6c 43 10 f0       	mov    $0xf010436c,%eax
f0103aa9:	66 a3 e0 f3 22 f0    	mov    %ax,0xf022f3e0
f0103aaf:	66 c7 05 e2 f3 22 f0 	movw   $0x8,0xf022f3e2
f0103ab6:	08 00 
f0103ab8:	c6 05 e4 f3 22 f0 00 	movb   $0x0,0xf022f3e4
f0103abf:	c6 05 e5 f3 22 f0 ee 	movb   $0xee,0xf022f3e5
f0103ac6:	c1 e8 10             	shr    $0x10,%eax
f0103ac9:	66 a3 e6 f3 22 f0    	mov    %ax,0xf022f3e6
	
	extern void TH_IRQ_TIMER(); 	SETGATE(idt[IRQ_OFFSET + 0], 0, GD_KT, TH_IRQ_TIMER, 0);
f0103acf:	b8 72 43 10 f0       	mov    $0xf0104372,%eax
f0103ad4:	66 a3 60 f3 22 f0    	mov    %ax,0xf022f360
f0103ada:	66 c7 05 62 f3 22 f0 	movw   $0x8,0xf022f362
f0103ae1:	08 00 
f0103ae3:	c6 05 64 f3 22 f0 00 	movb   $0x0,0xf022f364
f0103aea:	c6 05 65 f3 22 f0 8e 	movb   $0x8e,0xf022f365
f0103af1:	89 c2                	mov    %eax,%edx
f0103af3:	c1 ea 10             	shr    $0x10,%edx
f0103af6:	66 89 15 66 f3 22 f0 	mov    %dx,0xf022f366
	extern void TH_IRQ_KBD();	SETGATE(idt[IRQ_OFFSET + 1], 0, GD_KT, TH_IRQ_TIMER, 0);
f0103afd:	66 a3 68 f3 22 f0    	mov    %ax,0xf022f368
f0103b03:	66 c7 05 6a f3 22 f0 	movw   $0x8,0xf022f36a
f0103b0a:	08 00 
f0103b0c:	c6 05 6c f3 22 f0 00 	movb   $0x0,0xf022f36c
f0103b13:	c6 05 6d f3 22 f0 8e 	movb   $0x8e,0xf022f36d
f0103b1a:	66 89 15 6e f3 22 f0 	mov    %dx,0xf022f36e
	extern void TH_IRQ_2();		SETGATE(idt[IRQ_OFFSET + 2], 0, GD_KT, TH_IRQ_2, 0);
f0103b21:	b8 7e 43 10 f0       	mov    $0xf010437e,%eax
f0103b26:	66 a3 70 f3 22 f0    	mov    %ax,0xf022f370
f0103b2c:	66 c7 05 72 f3 22 f0 	movw   $0x8,0xf022f372
f0103b33:	08 00 
f0103b35:	c6 05 74 f3 22 f0 00 	movb   $0x0,0xf022f374
f0103b3c:	c6 05 75 f3 22 f0 8e 	movb   $0x8e,0xf022f375
f0103b43:	c1 e8 10             	shr    $0x10,%eax
f0103b46:	66 a3 76 f3 22 f0    	mov    %ax,0xf022f376
	extern void TH_IRQ_3();		SETGATE(idt[IRQ_OFFSET + 3], 0, GD_KT, TH_IRQ_3, 0);
f0103b4c:	b8 84 43 10 f0       	mov    $0xf0104384,%eax
f0103b51:	66 a3 78 f3 22 f0    	mov    %ax,0xf022f378
f0103b57:	66 c7 05 7a f3 22 f0 	movw   $0x8,0xf022f37a
f0103b5e:	08 00 
f0103b60:	c6 05 7c f3 22 f0 00 	movb   $0x0,0xf022f37c
f0103b67:	c6 05 7d f3 22 f0 8e 	movb   $0x8e,0xf022f37d
f0103b6e:	c1 e8 10             	shr    $0x10,%eax
f0103b71:	66 a3 7e f3 22 f0    	mov    %ax,0xf022f37e
	extern void TH_IRQ_SERIAL();	SETGATE(idt[IRQ_OFFSET + 4], 0, GD_KT, TH_IRQ_SERIAL, 0);
f0103b77:	b8 8a 43 10 f0       	mov    $0xf010438a,%eax
f0103b7c:	66 a3 80 f3 22 f0    	mov    %ax,0xf022f380
f0103b82:	66 c7 05 82 f3 22 f0 	movw   $0x8,0xf022f382
f0103b89:	08 00 
f0103b8b:	c6 05 84 f3 22 f0 00 	movb   $0x0,0xf022f384
f0103b92:	c6 05 85 f3 22 f0 8e 	movb   $0x8e,0xf022f385
f0103b99:	c1 e8 10             	shr    $0x10,%eax
f0103b9c:	66 a3 86 f3 22 f0    	mov    %ax,0xf022f386
	extern void TH_IRQ_5();		SETGATE(idt[IRQ_OFFSET + 5], 0, GD_KT, TH_IRQ_5, 0);
f0103ba2:	b8 90 43 10 f0       	mov    $0xf0104390,%eax
f0103ba7:	66 a3 88 f3 22 f0    	mov    %ax,0xf022f388
f0103bad:	66 c7 05 8a f3 22 f0 	movw   $0x8,0xf022f38a
f0103bb4:	08 00 
f0103bb6:	c6 05 8c f3 22 f0 00 	movb   $0x0,0xf022f38c
f0103bbd:	c6 05 8d f3 22 f0 8e 	movb   $0x8e,0xf022f38d
f0103bc4:	c1 e8 10             	shr    $0x10,%eax
f0103bc7:	66 a3 8e f3 22 f0    	mov    %ax,0xf022f38e
	extern void TH_IRQ_6();		SETGATE(idt[IRQ_OFFSET + 6], 0, GD_KT, TH_IRQ_6, 0);
f0103bcd:	b8 96 43 10 f0       	mov    $0xf0104396,%eax
f0103bd2:	66 a3 90 f3 22 f0    	mov    %ax,0xf022f390
f0103bd8:	66 c7 05 92 f3 22 f0 	movw   $0x8,0xf022f392
f0103bdf:	08 00 
f0103be1:	c6 05 94 f3 22 f0 00 	movb   $0x0,0xf022f394
f0103be8:	c6 05 95 f3 22 f0 8e 	movb   $0x8e,0xf022f395
f0103bef:	c1 e8 10             	shr    $0x10,%eax
f0103bf2:	66 a3 96 f3 22 f0    	mov    %ax,0xf022f396
	extern void TH_IRQ_SPURIOUS();	SETGATE(idt[IRQ_OFFSET + 7], 0, GD_KT, TH_IRQ_SPURIOUS, 0);
f0103bf8:	b8 9c 43 10 f0       	mov    $0xf010439c,%eax
f0103bfd:	66 a3 98 f3 22 f0    	mov    %ax,0xf022f398
f0103c03:	66 c7 05 9a f3 22 f0 	movw   $0x8,0xf022f39a
f0103c0a:	08 00 
f0103c0c:	c6 05 9c f3 22 f0 00 	movb   $0x0,0xf022f39c
f0103c13:	c6 05 9d f3 22 f0 8e 	movb   $0x8e,0xf022f39d
f0103c1a:	c1 e8 10             	shr    $0x10,%eax
f0103c1d:	66 a3 9e f3 22 f0    	mov    %ax,0xf022f39e
	extern void TH_IRQ_8();		SETGATE(idt[IRQ_OFFSET + 8], 0, GD_KT, TH_IRQ_8, 0);
f0103c23:	b8 a2 43 10 f0       	mov    $0xf01043a2,%eax
f0103c28:	66 a3 a0 f3 22 f0    	mov    %ax,0xf022f3a0
f0103c2e:	66 c7 05 a2 f3 22 f0 	movw   $0x8,0xf022f3a2
f0103c35:	08 00 
f0103c37:	c6 05 a4 f3 22 f0 00 	movb   $0x0,0xf022f3a4
f0103c3e:	c6 05 a5 f3 22 f0 8e 	movb   $0x8e,0xf022f3a5
f0103c45:	c1 e8 10             	shr    $0x10,%eax
f0103c48:	66 a3 a6 f3 22 f0    	mov    %ax,0xf022f3a6
	extern void TH_IRQ_9();		SETGATE(idt[IRQ_OFFSET + 9], 0, GD_KT, TH_IRQ_9, 0);
f0103c4e:	b8 a8 43 10 f0       	mov    $0xf01043a8,%eax
f0103c53:	66 a3 a8 f3 22 f0    	mov    %ax,0xf022f3a8
f0103c59:	66 c7 05 aa f3 22 f0 	movw   $0x8,0xf022f3aa
f0103c60:	08 00 
f0103c62:	c6 05 ac f3 22 f0 00 	movb   $0x0,0xf022f3ac
f0103c69:	c6 05 ad f3 22 f0 8e 	movb   $0x8e,0xf022f3ad
f0103c70:	c1 e8 10             	shr    $0x10,%eax
f0103c73:	66 a3 ae f3 22 f0    	mov    %ax,0xf022f3ae
	extern void TH_IRQ_10();	SETGATE(idt[IRQ_OFFSET + 10], 0, GD_KT, TH_IRQ_10, 0);
f0103c79:	b8 ae 43 10 f0       	mov    $0xf01043ae,%eax
f0103c7e:	66 a3 b0 f3 22 f0    	mov    %ax,0xf022f3b0
f0103c84:	66 c7 05 b2 f3 22 f0 	movw   $0x8,0xf022f3b2
f0103c8b:	08 00 
f0103c8d:	c6 05 b4 f3 22 f0 00 	movb   $0x0,0xf022f3b4
f0103c94:	c6 05 b5 f3 22 f0 8e 	movb   $0x8e,0xf022f3b5
f0103c9b:	c1 e8 10             	shr    $0x10,%eax
f0103c9e:	66 a3 b6 f3 22 f0    	mov    %ax,0xf022f3b6
	extern void TH_IRQ_11();	SETGATE(idt[IRQ_OFFSET + 11], 0, GD_KT, TH_IRQ_11, 0);
f0103ca4:	b8 b4 43 10 f0       	mov    $0xf01043b4,%eax
f0103ca9:	66 a3 b8 f3 22 f0    	mov    %ax,0xf022f3b8
f0103caf:	66 c7 05 ba f3 22 f0 	movw   $0x8,0xf022f3ba
f0103cb6:	08 00 
f0103cb8:	c6 05 bc f3 22 f0 00 	movb   $0x0,0xf022f3bc
f0103cbf:	c6 05 bd f3 22 f0 8e 	movb   $0x8e,0xf022f3bd
f0103cc6:	c1 e8 10             	shr    $0x10,%eax
f0103cc9:	66 a3 be f3 22 f0    	mov    %ax,0xf022f3be
	extern void TH_IRQ_12();	SETGATE(idt[IRQ_OFFSET + 12], 0, GD_KT, TH_IRQ_12, 0);
f0103ccf:	b8 ba 43 10 f0       	mov    $0xf01043ba,%eax
f0103cd4:	66 a3 c0 f3 22 f0    	mov    %ax,0xf022f3c0
f0103cda:	66 c7 05 c2 f3 22 f0 	movw   $0x8,0xf022f3c2
f0103ce1:	08 00 
f0103ce3:	c6 05 c4 f3 22 f0 00 	movb   $0x0,0xf022f3c4
f0103cea:	c6 05 c5 f3 22 f0 8e 	movb   $0x8e,0xf022f3c5
f0103cf1:	c1 e8 10             	shr    $0x10,%eax
f0103cf4:	66 a3 c6 f3 22 f0    	mov    %ax,0xf022f3c6
	extern void TH_IRQ_13();	SETGATE(idt[IRQ_OFFSET + 13], 0, GD_KT, TH_IRQ_13, 0);
f0103cfa:	b8 c0 43 10 f0       	mov    $0xf01043c0,%eax
f0103cff:	66 a3 c8 f3 22 f0    	mov    %ax,0xf022f3c8
f0103d05:	66 c7 05 ca f3 22 f0 	movw   $0x8,0xf022f3ca
f0103d0c:	08 00 
f0103d0e:	c6 05 cc f3 22 f0 00 	movb   $0x0,0xf022f3cc
f0103d15:	c6 05 cd f3 22 f0 8e 	movb   $0x8e,0xf022f3cd
f0103d1c:	c1 e8 10             	shr    $0x10,%eax
f0103d1f:	66 a3 ce f3 22 f0    	mov    %ax,0xf022f3ce
	extern void TH_IRQ_IDE();	SETGATE(idt[IRQ_OFFSET + 14], 0, GD_KT, TH_IRQ_IDE, 0);
f0103d25:	b8 c6 43 10 f0       	mov    $0xf01043c6,%eax
f0103d2a:	66 a3 d0 f3 22 f0    	mov    %ax,0xf022f3d0
f0103d30:	66 c7 05 d2 f3 22 f0 	movw   $0x8,0xf022f3d2
f0103d37:	08 00 
f0103d39:	c6 05 d4 f3 22 f0 00 	movb   $0x0,0xf022f3d4
f0103d40:	c6 05 d5 f3 22 f0 8e 	movb   $0x8e,0xf022f3d5
f0103d47:	c1 e8 10             	shr    $0x10,%eax
f0103d4a:	66 a3 d6 f3 22 f0    	mov    %ax,0xf022f3d6
	extern void TH_IRQ_15();	SETGATE(idt[IRQ_OFFSET + 15], 0, GD_KT, TH_IRQ_15, 0);
f0103d50:	b8 cc 43 10 f0       	mov    $0xf01043cc,%eax
f0103d55:	66 a3 d8 f3 22 f0    	mov    %ax,0xf022f3d8
f0103d5b:	66 c7 05 da f3 22 f0 	movw   $0x8,0xf022f3da
f0103d62:	08 00 
f0103d64:	c6 05 dc f3 22 f0 00 	movb   $0x0,0xf022f3dc
f0103d6b:	c6 05 dd f3 22 f0 8e 	movb   $0x8e,0xf022f3dd
f0103d72:	c1 e8 10             	shr    $0x10,%eax
f0103d75:	66 a3 de f3 22 f0    	mov    %ax,0xf022f3de

	
	// Per-CPU setup 
	trap_init_percpu();
f0103d7b:	e8 37 f9 ff ff       	call   f01036b7 <trap_init_percpu>
}
f0103d80:	c9                   	leave  
f0103d81:	c3                   	ret    

f0103d82 <print_regs>:
	}
}

void	
print_regs(struct PushRegs *regs)
{
f0103d82:	55                   	push   %ebp
f0103d83:	89 e5                	mov    %esp,%ebp
f0103d85:	53                   	push   %ebx
f0103d86:	83 ec 0c             	sub    $0xc,%esp
f0103d89:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103d8c:	ff 33                	pushl  (%ebx)
f0103d8e:	68 87 74 10 f0       	push   $0xf0107487
f0103d93:	e8 0b f9 ff ff       	call   f01036a3 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103d98:	83 c4 08             	add    $0x8,%esp
f0103d9b:	ff 73 04             	pushl  0x4(%ebx)
f0103d9e:	68 96 74 10 f0       	push   $0xf0107496
f0103da3:	e8 fb f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103da8:	83 c4 08             	add    $0x8,%esp
f0103dab:	ff 73 08             	pushl  0x8(%ebx)
f0103dae:	68 a5 74 10 f0       	push   $0xf01074a5
f0103db3:	e8 eb f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103db8:	83 c4 08             	add    $0x8,%esp
f0103dbb:	ff 73 0c             	pushl  0xc(%ebx)
f0103dbe:	68 b4 74 10 f0       	push   $0xf01074b4
f0103dc3:	e8 db f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103dc8:	83 c4 08             	add    $0x8,%esp
f0103dcb:	ff 73 10             	pushl  0x10(%ebx)
f0103dce:	68 c3 74 10 f0       	push   $0xf01074c3
f0103dd3:	e8 cb f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103dd8:	83 c4 08             	add    $0x8,%esp
f0103ddb:	ff 73 14             	pushl  0x14(%ebx)
f0103dde:	68 d2 74 10 f0       	push   $0xf01074d2
f0103de3:	e8 bb f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103de8:	83 c4 08             	add    $0x8,%esp
f0103deb:	ff 73 18             	pushl  0x18(%ebx)
f0103dee:	68 e1 74 10 f0       	push   $0xf01074e1
f0103df3:	e8 ab f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103df8:	83 c4 08             	add    $0x8,%esp
f0103dfb:	ff 73 1c             	pushl  0x1c(%ebx)
f0103dfe:	68 f0 74 10 f0       	push   $0xf01074f0
f0103e03:	e8 9b f8 ff ff       	call   f01036a3 <cprintf>
}
f0103e08:	83 c4 10             	add    $0x10,%esp
f0103e0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103e0e:	c9                   	leave  
f0103e0f:	c3                   	ret    

f0103e10 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103e10:	55                   	push   %ebp
f0103e11:	89 e5                	mov    %esp,%ebp
f0103e13:	56                   	push   %esi
f0103e14:	53                   	push   %ebx
f0103e15:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103e18:	e8 c9 1c 00 00       	call   f0105ae6 <cpunum>
f0103e1d:	83 ec 04             	sub    $0x4,%esp
f0103e20:	50                   	push   %eax
f0103e21:	53                   	push   %ebx
f0103e22:	68 54 75 10 f0       	push   $0xf0107554
f0103e27:	e8 77 f8 ff ff       	call   f01036a3 <cprintf>
	print_regs(&tf->tf_regs);
f0103e2c:	89 1c 24             	mov    %ebx,(%esp)
f0103e2f:	e8 4e ff ff ff       	call   f0103d82 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103e34:	83 c4 08             	add    $0x8,%esp
f0103e37:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103e3b:	50                   	push   %eax
f0103e3c:	68 72 75 10 f0       	push   $0xf0107572
f0103e41:	e8 5d f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103e46:	83 c4 08             	add    $0x8,%esp
f0103e49:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103e4d:	50                   	push   %eax
f0103e4e:	68 85 75 10 f0       	push   $0xf0107585
f0103e53:	e8 4b f8 ff ff       	call   f01036a3 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e58:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103e5b:	83 c4 10             	add    $0x10,%esp
f0103e5e:	83 f8 13             	cmp    $0x13,%eax
f0103e61:	77 09                	ja     f0103e6c <print_trapframe+0x5c>
		return excnames[trapno];
f0103e63:	8b 14 85 20 78 10 f0 	mov    -0xfef87e0(,%eax,4),%edx
f0103e6a:	eb 1f                	jmp    f0103e8b <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103e6c:	83 f8 30             	cmp    $0x30,%eax
f0103e6f:	74 15                	je     f0103e86 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103e71:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103e74:	83 fa 10             	cmp    $0x10,%edx
f0103e77:	b9 1e 75 10 f0       	mov    $0xf010751e,%ecx
f0103e7c:	ba 0b 75 10 f0       	mov    $0xf010750b,%edx
f0103e81:	0f 43 d1             	cmovae %ecx,%edx
f0103e84:	eb 05                	jmp    f0103e8b <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103e86:	ba ff 74 10 f0       	mov    $0xf01074ff,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e8b:	83 ec 04             	sub    $0x4,%esp
f0103e8e:	52                   	push   %edx
f0103e8f:	50                   	push   %eax
f0103e90:	68 98 75 10 f0       	push   $0xf0107598
f0103e95:	e8 09 f8 ff ff       	call   f01036a3 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103e9a:	83 c4 10             	add    $0x10,%esp
f0103e9d:	3b 1d 60 fa 22 f0    	cmp    0xf022fa60,%ebx
f0103ea3:	75 1a                	jne    f0103ebf <print_trapframe+0xaf>
f0103ea5:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ea9:	75 14                	jne    f0103ebf <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103eab:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103eae:	83 ec 08             	sub    $0x8,%esp
f0103eb1:	50                   	push   %eax
f0103eb2:	68 aa 75 10 f0       	push   $0xf01075aa
f0103eb7:	e8 e7 f7 ff ff       	call   f01036a3 <cprintf>
f0103ebc:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103ebf:	83 ec 08             	sub    $0x8,%esp
f0103ec2:	ff 73 2c             	pushl  0x2c(%ebx)
f0103ec5:	68 b9 75 10 f0       	push   $0xf01075b9
f0103eca:	e8 d4 f7 ff ff       	call   f01036a3 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103ecf:	83 c4 10             	add    $0x10,%esp
f0103ed2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ed6:	75 49                	jne    f0103f21 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103ed8:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103edb:	89 c2                	mov    %eax,%edx
f0103edd:	83 e2 01             	and    $0x1,%edx
f0103ee0:	ba 38 75 10 f0       	mov    $0xf0107538,%edx
f0103ee5:	b9 2d 75 10 f0       	mov    $0xf010752d,%ecx
f0103eea:	0f 44 ca             	cmove  %edx,%ecx
f0103eed:	89 c2                	mov    %eax,%edx
f0103eef:	83 e2 02             	and    $0x2,%edx
f0103ef2:	ba 4a 75 10 f0       	mov    $0xf010754a,%edx
f0103ef7:	be 44 75 10 f0       	mov    $0xf0107544,%esi
f0103efc:	0f 45 d6             	cmovne %esi,%edx
f0103eff:	83 e0 04             	and    $0x4,%eax
f0103f02:	be 97 76 10 f0       	mov    $0xf0107697,%esi
f0103f07:	b8 4f 75 10 f0       	mov    $0xf010754f,%eax
f0103f0c:	0f 44 c6             	cmove  %esi,%eax
f0103f0f:	51                   	push   %ecx
f0103f10:	52                   	push   %edx
f0103f11:	50                   	push   %eax
f0103f12:	68 c7 75 10 f0       	push   $0xf01075c7
f0103f17:	e8 87 f7 ff ff       	call   f01036a3 <cprintf>
f0103f1c:	83 c4 10             	add    $0x10,%esp
f0103f1f:	eb 10                	jmp    f0103f31 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103f21:	83 ec 0c             	sub    $0xc,%esp
f0103f24:	68 3c 65 10 f0       	push   $0xf010653c
f0103f29:	e8 75 f7 ff ff       	call   f01036a3 <cprintf>
f0103f2e:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103f31:	83 ec 08             	sub    $0x8,%esp
f0103f34:	ff 73 30             	pushl  0x30(%ebx)
f0103f37:	68 d6 75 10 f0       	push   $0xf01075d6
f0103f3c:	e8 62 f7 ff ff       	call   f01036a3 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103f41:	83 c4 08             	add    $0x8,%esp
f0103f44:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103f48:	50                   	push   %eax
f0103f49:	68 e5 75 10 f0       	push   $0xf01075e5
f0103f4e:	e8 50 f7 ff ff       	call   f01036a3 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103f53:	83 c4 08             	add    $0x8,%esp
f0103f56:	ff 73 38             	pushl  0x38(%ebx)
f0103f59:	68 f8 75 10 f0       	push   $0xf01075f8
f0103f5e:	e8 40 f7 ff ff       	call   f01036a3 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103f63:	83 c4 10             	add    $0x10,%esp
f0103f66:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103f6a:	74 25                	je     f0103f91 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103f6c:	83 ec 08             	sub    $0x8,%esp
f0103f6f:	ff 73 3c             	pushl  0x3c(%ebx)
f0103f72:	68 07 76 10 f0       	push   $0xf0107607
f0103f77:	e8 27 f7 ff ff       	call   f01036a3 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103f7c:	83 c4 08             	add    $0x8,%esp
f0103f7f:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103f83:	50                   	push   %eax
f0103f84:	68 16 76 10 f0       	push   $0xf0107616
f0103f89:	e8 15 f7 ff ff       	call   f01036a3 <cprintf>
f0103f8e:	83 c4 10             	add    $0x10,%esp
	}
}
f0103f91:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103f94:	5b                   	pop    %ebx
f0103f95:	5e                   	pop    %esi
f0103f96:	5d                   	pop    %ebp
f0103f97:	c3                   	ret    

f0103f98 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103f98:	55                   	push   %ebp
f0103f99:	89 e5                	mov    %esp,%ebp
f0103f9b:	57                   	push   %edi
f0103f9c:	56                   	push   %esi
f0103f9d:	53                   	push   %ebx
f0103f9e:	83 ec 1c             	sub    $0x1c,%esp
f0103fa1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103fa4:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f0103fa7:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103fab:	75 17                	jne    f0103fc4 <page_fault_handler+0x2c>
		panic("Kernel page fault!");	
f0103fad:	83 ec 04             	sub    $0x4,%esp
f0103fb0:	68 29 76 10 f0       	push   $0xf0107629
f0103fb5:	68 51 01 00 00       	push   $0x151
f0103fba:	68 3c 76 10 f0       	push   $0xf010763c
f0103fbf:	e8 7c c0 ff ff       	call   f0100040 <_panic>
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
f0103fc4:	e8 1d 1b 00 00       	call   f0105ae6 <cpunum>
f0103fc9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fcc:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103fd2:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103fd6:	0f 84 92 00 00 00    	je     f010406e <page_fault_handler+0xd6>
	{
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
		
		if(tf->tf_esp > USTACKTOP)
f0103fdc:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103fdf:	3d 00 e0 bf ee       	cmp    $0xeebfe000,%eax
f0103fe4:	76 0d                	jbe    f0103ff3 <page_fault_handler+0x5b>
		{
			size += 4;
			userTF = (struct UTrapframe*) (tf->tf_esp - size);
f0103fe6:	83 e8 38             	sub    $0x38,%eax
f0103fe9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
		
		if(tf->tf_esp > USTACKTOP)
		{
			size += 4;
f0103fec:	bf 38 00 00 00       	mov    $0x38,%edi
f0103ff1:	eb 0c                	jmp    f0103fff <page_fault_handler+0x67>

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
	{
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
f0103ff3:	c7 45 e4 cc ff bf ee 	movl   $0xeebfffcc,-0x1c(%ebp)
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
	{
		size_t size = sizeof(struct UTrapframe);
f0103ffa:	bf 34 00 00 00       	mov    $0x34,%edi
		{
			size += 4;
			userTF = (struct UTrapframe*) (tf->tf_esp - size);
		}

		user_mem_assert(curenv, (void *) userTF, size, (PTE_U | PTE_W));
f0103fff:	e8 e2 1a 00 00       	call   f0105ae6 <cpunum>
f0104004:	6a 06                	push   $0x6
f0104006:	57                   	push   %edi
f0104007:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010400a:	57                   	push   %edi
f010400b:	6b c0 74             	imul   $0x74,%eax,%eax
f010400e:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104014:	e8 6b ed ff ff       	call   f0102d84 <user_mem_assert>

		userTF->utf_fault_va = fault_va;
f0104019:	89 37                	mov    %esi,(%edi)
		userTF->utf_err = tf->tf_err; 
f010401b:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010401e:	89 fa                	mov    %edi,%edx
f0104020:	89 47 04             	mov    %eax,0x4(%edi)
		userTF->utf_regs = tf->tf_regs;
f0104023:	8d 7f 08             	lea    0x8(%edi),%edi
f0104026:	b9 08 00 00 00       	mov    $0x8,%ecx
f010402b:	89 de                	mov    %ebx,%esi
f010402d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		userTF->utf_eip = tf->tf_eip; 
f010402f:	8b 43 30             	mov    0x30(%ebx),%eax
f0104032:	89 42 28             	mov    %eax,0x28(%edx)
		userTF->utf_eflags = tf->tf_eflags; 
f0104035:	8b 43 38             	mov    0x38(%ebx),%eax
f0104038:	89 42 2c             	mov    %eax,0x2c(%edx)
		userTF->utf_esp = tf->tf_esp;
f010403b:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010403e:	89 42 30             	mov    %eax,0x30(%edx)

		tf->tf_esp = (uint32_t) userTF;
f0104041:	89 53 3c             	mov    %edx,0x3c(%ebx)
		tf->tf_eip = (uint32_t) curenv->env_pgfault_upcall;
f0104044:	e8 9d 1a 00 00       	call   f0105ae6 <cpunum>
f0104049:	6b c0 74             	imul   $0x74,%eax,%eax
f010404c:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104052:	8b 40 64             	mov    0x64(%eax),%eax
f0104055:	89 43 30             	mov    %eax,0x30(%ebx)

		env_run(curenv);		
f0104058:	e8 89 1a 00 00       	call   f0105ae6 <cpunum>
f010405d:	83 c4 04             	add    $0x4,%esp
f0104060:	6b c0 74             	imul   $0x74,%eax,%eax
f0104063:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104069:	e8 1b f4 ff ff       	call   f0103489 <env_run>
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010406e:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104071:	e8 70 1a 00 00       	call   f0105ae6 <cpunum>

		env_run(curenv);		
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104076:	57                   	push   %edi
f0104077:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0104078:	6b c0 74             	imul   $0x74,%eax,%eax

		env_run(curenv);		
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010407b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104081:	ff 70 48             	pushl  0x48(%eax)
f0104084:	68 e4 77 10 f0       	push   $0xf01077e4
f0104089:	e8 15 f6 ff ff       	call   f01036a3 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010408e:	89 1c 24             	mov    %ebx,(%esp)
f0104091:	e8 7a fd ff ff       	call   f0103e10 <print_trapframe>
	env_destroy(curenv);
f0104096:	e8 4b 1a 00 00       	call   f0105ae6 <cpunum>
f010409b:	83 c4 04             	add    $0x4,%esp
f010409e:	6b c0 74             	imul   $0x74,%eax,%eax
f01040a1:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01040a7:	e8 3e f3 ff ff       	call   f01033ea <env_destroy>
}
f01040ac:	83 c4 10             	add    $0x10,%esp
f01040af:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040b2:	5b                   	pop    %ebx
f01040b3:	5e                   	pop    %esi
f01040b4:	5f                   	pop    %edi
f01040b5:	5d                   	pop    %ebp
f01040b6:	c3                   	ret    

f01040b7 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01040b7:	55                   	push   %ebp
f01040b8:	89 e5                	mov    %esp,%ebp
f01040ba:	57                   	push   %edi
f01040bb:	56                   	push   %esi
f01040bc:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01040bf:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f01040c0:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f01040c7:	74 01                	je     f01040ca <trap+0x13>
		asm volatile("hlt");
f01040c9:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f01040ca:	e8 17 1a 00 00       	call   f0105ae6 <cpunum>
f01040cf:	6b d0 74             	imul   $0x74,%eax,%edx
f01040d2:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01040d8:	b8 01 00 00 00       	mov    $0x1,%eax
f01040dd:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f01040e1:	83 f8 02             	cmp    $0x2,%eax
f01040e4:	75 10                	jne    f01040f6 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01040e6:	83 ec 0c             	sub    $0xc,%esp
f01040e9:	68 c0 03 12 f0       	push   $0xf01203c0
f01040ee:	e8 61 1c 00 00       	call   f0105d54 <spin_lock>
f01040f3:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01040f6:	9c                   	pushf  
f01040f7:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01040f8:	f6 c4 02             	test   $0x2,%ah
f01040fb:	74 19                	je     f0104116 <trap+0x5f>
f01040fd:	68 48 76 10 f0       	push   $0xf0107648
f0104102:	68 eb 70 10 f0       	push   $0xf01070eb
f0104107:	68 1b 01 00 00       	push   $0x11b
f010410c:	68 3c 76 10 f0       	push   $0xf010763c
f0104111:	e8 2a bf ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104116:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010411a:	83 e0 03             	and    $0x3,%eax
f010411d:	66 83 f8 03          	cmp    $0x3,%ax
f0104121:	0f 85 a0 00 00 00    	jne    f01041c7 <trap+0x110>
f0104127:	83 ec 0c             	sub    $0xc,%esp
f010412a:	68 c0 03 12 f0       	push   $0xf01203c0
f010412f:	e8 20 1c 00 00       	call   f0105d54 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0104134:	e8 ad 19 00 00       	call   f0105ae6 <cpunum>
f0104139:	6b c0 74             	imul   $0x74,%eax,%eax
f010413c:	83 c4 10             	add    $0x10,%esp
f010413f:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104146:	75 19                	jne    f0104161 <trap+0xaa>
f0104148:	68 61 76 10 f0       	push   $0xf0107661
f010414d:	68 eb 70 10 f0       	push   $0xf01070eb
f0104152:	68 23 01 00 00       	push   $0x123
f0104157:	68 3c 76 10 f0       	push   $0xf010763c
f010415c:	e8 df be ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0104161:	e8 80 19 00 00       	call   f0105ae6 <cpunum>
f0104166:	6b c0 74             	imul   $0x74,%eax,%eax
f0104169:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010416f:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104173:	75 2d                	jne    f01041a2 <trap+0xeb>
			env_free(curenv);
f0104175:	e8 6c 19 00 00       	call   f0105ae6 <cpunum>
f010417a:	83 ec 0c             	sub    $0xc,%esp
f010417d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104180:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104186:	e8 84 f0 ff ff       	call   f010320f <env_free>
			curenv = NULL;
f010418b:	e8 56 19 00 00       	call   f0105ae6 <cpunum>
f0104190:	6b c0 74             	imul   $0x74,%eax,%eax
f0104193:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f010419a:	00 00 00 
			sched_yield();
f010419d:	e8 1c 03 00 00       	call   f01044be <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01041a2:	e8 3f 19 00 00       	call   f0105ae6 <cpunum>
f01041a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01041aa:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01041b0:	b9 11 00 00 00       	mov    $0x11,%ecx
f01041b5:	89 c7                	mov    %eax,%edi
f01041b7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01041b9:	e8 28 19 00 00       	call   f0105ae6 <cpunum>
f01041be:	6b c0 74             	imul   $0x74,%eax,%eax
f01041c1:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01041c7:	89 35 60 fa 22 f0    	mov    %esi,0xf022fa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f01041cd:	8b 46 28             	mov    0x28(%esi),%eax
f01041d0:	83 f8 0e             	cmp    $0xe,%eax
f01041d3:	74 0c                	je     f01041e1 <trap+0x12a>
f01041d5:	83 f8 30             	cmp    $0x30,%eax
f01041d8:	74 29                	je     f0104203 <trap+0x14c>
f01041da:	83 f8 03             	cmp    $0x3,%eax
f01041dd:	75 45                	jne    f0104224 <trap+0x16d>
f01041df:	eb 11                	jmp    f01041f2 <trap+0x13b>
	{
		case T_PGFLT: 	  page_fault_handler(tf); 	return;
f01041e1:	83 ec 0c             	sub    $0xc,%esp
f01041e4:	56                   	push   %esi
f01041e5:	e8 ae fd ff ff       	call   f0103f98 <page_fault_handler>
f01041ea:	83 c4 10             	add    $0x10,%esp
f01041ed:	e9 a3 00 00 00       	jmp    f0104295 <trap+0x1de>

		case T_BRKPT:     monitor(tf);			return;
f01041f2:	83 ec 0c             	sub    $0xc,%esp
f01041f5:	56                   	push   %esi
f01041f6:	e8 7b c7 ff ff       	call   f0100976 <monitor>
f01041fb:	83 c4 10             	add    $0x10,%esp
f01041fe:	e9 92 00 00 00       	jmp    f0104295 <trap+0x1de>

		case T_SYSCALL:	  
				tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
f0104203:	83 ec 08             	sub    $0x8,%esp
f0104206:	ff 76 04             	pushl  0x4(%esi)
f0104209:	ff 36                	pushl  (%esi)
f010420b:	ff 76 10             	pushl  0x10(%esi)
f010420e:	ff 76 18             	pushl  0x18(%esi)
f0104211:	ff 76 14             	pushl  0x14(%esi)
f0104214:	ff 76 1c             	pushl  0x1c(%esi)
f0104217:	e8 52 03 00 00       	call   f010456e <syscall>
f010421c:	89 46 1c             	mov    %eax,0x1c(%esi)
f010421f:	83 c4 20             	add    $0x20,%esp
f0104222:	eb 71                	jmp    f0104295 <trap+0x1de>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104224:	83 f8 27             	cmp    $0x27,%eax
f0104227:	75 1a                	jne    f0104243 <trap+0x18c>
		cprintf("Spurious interrupt on irq 7\n");
f0104229:	83 ec 0c             	sub    $0xc,%esp
f010422c:	68 68 76 10 f0       	push   $0xf0107668
f0104231:	e8 6d f4 ff ff       	call   f01036a3 <cprintf>
		print_trapframe(tf);
f0104236:	89 34 24             	mov    %esi,(%esp)
f0104239:	e8 d2 fb ff ff       	call   f0103e10 <print_trapframe>
f010423e:	83 c4 10             	add    $0x10,%esp
f0104241:	eb 52                	jmp    f0104295 <trap+0x1de>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if(tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER)
f0104243:	83 f8 20             	cmp    $0x20,%eax
f0104246:	75 0a                	jne    f0104252 <trap+0x19b>
	{
		lapic_eoi();
f0104248:	e8 e4 19 00 00       	call   f0105c31 <lapic_eoi>
		sched_yield();
f010424d:	e8 6c 02 00 00       	call   f01044be <sched_yield>
		return;
	}


	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104252:	83 ec 0c             	sub    $0xc,%esp
f0104255:	56                   	push   %esi
f0104256:	e8 b5 fb ff ff       	call   f0103e10 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010425b:	83 c4 10             	add    $0x10,%esp
f010425e:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104263:	75 17                	jne    f010427c <trap+0x1c5>
		panic("unhandled trap in kernel");
f0104265:	83 ec 04             	sub    $0x4,%esp
f0104268:	68 85 76 10 f0       	push   $0xf0107685
f010426d:	68 01 01 00 00       	push   $0x101
f0104272:	68 3c 76 10 f0       	push   $0xf010763c
f0104277:	e8 c4 bd ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f010427c:	e8 65 18 00 00       	call   f0105ae6 <cpunum>
f0104281:	83 ec 0c             	sub    $0xc,%esp
f0104284:	6b c0 74             	imul   $0x74,%eax,%eax
f0104287:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010428d:	e8 58 f1 ff ff       	call   f01033ea <env_destroy>
f0104292:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104295:	e8 4c 18 00 00       	call   f0105ae6 <cpunum>
f010429a:	6b c0 74             	imul   $0x74,%eax,%eax
f010429d:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01042a4:	74 2a                	je     f01042d0 <trap+0x219>
f01042a6:	e8 3b 18 00 00       	call   f0105ae6 <cpunum>
f01042ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ae:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01042b4:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042b8:	75 16                	jne    f01042d0 <trap+0x219>
		env_run(curenv);
f01042ba:	e8 27 18 00 00       	call   f0105ae6 <cpunum>
f01042bf:	83 ec 0c             	sub    $0xc,%esp
f01042c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01042c5:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01042cb:	e8 b9 f1 ff ff       	call   f0103489 <env_run>
	else
		sched_yield();
f01042d0:	e8 e9 01 00 00       	call   f01044be <sched_yield>
f01042d5:	90                   	nop

f01042d6 <TH_DIVIDE>:
	.p2align 2
	.globl TRAPHANDLERS
TRAPHANDLERS:
.text

TRAPHANDLER_NOEC(TH_DIVIDE, T_DIVIDE)	// fault
f01042d6:	6a 00                	push   $0x0
f01042d8:	6a 00                	push   $0x0
f01042da:	e9 f9 00 00 00       	jmp    f01043d8 <_alltraps>
f01042df:	90                   	nop

f01042e0 <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, T_DEBUG)	// fault/trap
f01042e0:	6a 00                	push   $0x0
f01042e2:	6a 01                	push   $0x1
f01042e4:	e9 ef 00 00 00       	jmp    f01043d8 <_alltraps>
f01042e9:	90                   	nop

f01042ea <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, T_NMI)		//
f01042ea:	6a 00                	push   $0x0
f01042ec:	6a 02                	push   $0x2
f01042ee:	e9 e5 00 00 00       	jmp    f01043d8 <_alltraps>
f01042f3:	90                   	nop

f01042f4 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, T_BRKPT)	// trap
f01042f4:	6a 00                	push   $0x0
f01042f6:	6a 03                	push   $0x3
f01042f8:	e9 db 00 00 00       	jmp    f01043d8 <_alltraps>
f01042fd:	90                   	nop

f01042fe <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, T_OFLOW)	// trap
f01042fe:	6a 00                	push   $0x0
f0104300:	6a 04                	push   $0x4
f0104302:	e9 d1 00 00 00       	jmp    f01043d8 <_alltraps>
f0104307:	90                   	nop

f0104308 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, T_BOUND)	// fault
f0104308:	6a 00                	push   $0x0
f010430a:	6a 05                	push   $0x5
f010430c:	e9 c7 00 00 00       	jmp    f01043d8 <_alltraps>
f0104311:	90                   	nop

f0104312 <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, T_ILLOP)	// fault
f0104312:	6a 00                	push   $0x0
f0104314:	6a 06                	push   $0x6
f0104316:	e9 bd 00 00 00       	jmp    f01043d8 <_alltraps>
f010431b:	90                   	nop

f010431c <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, T_DEVICE)	// fault
f010431c:	6a 00                	push   $0x0
f010431e:	6a 07                	push   $0x7
f0104320:	e9 b3 00 00 00       	jmp    f01043d8 <_alltraps>
f0104325:	90                   	nop

f0104326 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, T_DBLFLT)	// abort
f0104326:	6a 08                	push   $0x8
f0104328:	e9 ab 00 00 00       	jmp    f01043d8 <_alltraps>
f010432d:	90                   	nop

f010432e <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, T_COPROC) // abort	
TRAPHANDLER     (TH_TSS, T_TSS)		// fault
f010432e:	6a 0a                	push   $0xa
f0104330:	e9 a3 00 00 00       	jmp    f01043d8 <_alltraps>
f0104335:	90                   	nop

f0104336 <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, T_SEGNP)	// fault
f0104336:	6a 0b                	push   $0xb
f0104338:	e9 9b 00 00 00       	jmp    f01043d8 <_alltraps>
f010433d:	90                   	nop

f010433e <TH_STACK>:
TRAPHANDLER     (TH_STACK, T_STACK)	// fault
f010433e:	6a 0c                	push   $0xc
f0104340:	e9 93 00 00 00       	jmp    f01043d8 <_alltraps>
f0104345:	90                   	nop

f0104346 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, T_GPFLT)	// fault/abort
f0104346:	6a 0d                	push   $0xd
f0104348:	e9 8b 00 00 00       	jmp    f01043d8 <_alltraps>
f010434d:	90                   	nop

f010434e <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, T_PGFLT)	// fault
f010434e:	6a 0e                	push   $0xe
f0104350:	e9 83 00 00 00       	jmp    f01043d8 <_alltraps>
f0104355:	90                   	nop

f0104356 <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, T_RES)	
TRAPHANDLER_NOEC(TH_FPERR, T_FPERR)	// fault
f0104356:	6a 00                	push   $0x0
f0104358:	6a 10                	push   $0x10
f010435a:	eb 7c                	jmp    f01043d8 <_alltraps>

f010435c <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, T_ALIGN)	//
f010435c:	6a 11                	push   $0x11
f010435e:	eb 78                	jmp    f01043d8 <_alltraps>

f0104360 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, T_MCHK)	//
f0104360:	6a 00                	push   $0x0
f0104362:	6a 12                	push   $0x12
f0104364:	eb 72                	jmp    f01043d8 <_alltraps>

f0104366 <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, T_SIMDERR) //
f0104366:	6a 00                	push   $0x0
f0104368:	6a 13                	push   $0x13
f010436a:	eb 6c                	jmp    f01043d8 <_alltraps>

f010436c <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, T_SYSCALL) // trap
f010436c:	6a 00                	push   $0x0
f010436e:	6a 30                	push   $0x30
f0104370:	eb 66                	jmp    f01043d8 <_alltraps>

f0104372 <TH_IRQ_TIMER>:

TRAPHANDLER_NOEC(TH_IRQ_TIMER, IRQ_OFFSET+IRQ_TIMER)	// 0
f0104372:	6a 00                	push   $0x0
f0104374:	6a 20                	push   $0x20
f0104376:	eb 60                	jmp    f01043d8 <_alltraps>

f0104378 <TH_IRQ_KBD>:
TRAPHANDLER_NOEC(TH_IRQ_KBD, IRQ_OFFSET+IRQ_KBD)	// 1
f0104378:	6a 00                	push   $0x0
f010437a:	6a 21                	push   $0x21
f010437c:	eb 5a                	jmp    f01043d8 <_alltraps>

f010437e <TH_IRQ_2>:
TRAPHANDLER_NOEC(TH_IRQ_2, IRQ_OFFSET+2)
f010437e:	6a 00                	push   $0x0
f0104380:	6a 22                	push   $0x22
f0104382:	eb 54                	jmp    f01043d8 <_alltraps>

f0104384 <TH_IRQ_3>:
TRAPHANDLER_NOEC(TH_IRQ_3, IRQ_OFFSET+3)
f0104384:	6a 00                	push   $0x0
f0104386:	6a 23                	push   $0x23
f0104388:	eb 4e                	jmp    f01043d8 <_alltraps>

f010438a <TH_IRQ_SERIAL>:
TRAPHANDLER_NOEC(TH_IRQ_SERIAL, IRQ_OFFSET+IRQ_SERIAL)	// 4
f010438a:	6a 00                	push   $0x0
f010438c:	6a 24                	push   $0x24
f010438e:	eb 48                	jmp    f01043d8 <_alltraps>

f0104390 <TH_IRQ_5>:
TRAPHANDLER_NOEC(TH_IRQ_5, IRQ_OFFSET+5)
f0104390:	6a 00                	push   $0x0
f0104392:	6a 25                	push   $0x25
f0104394:	eb 42                	jmp    f01043d8 <_alltraps>

f0104396 <TH_IRQ_6>:
TRAPHANDLER_NOEC(TH_IRQ_6, IRQ_OFFSET+6)
f0104396:	6a 00                	push   $0x0
f0104398:	6a 26                	push   $0x26
f010439a:	eb 3c                	jmp    f01043d8 <_alltraps>

f010439c <TH_IRQ_SPURIOUS>:
TRAPHANDLER_NOEC(TH_IRQ_SPURIOUS, IRQ_OFFSET+IRQ_SPURIOUS) // 7
f010439c:	6a 00                	push   $0x0
f010439e:	6a 27                	push   $0x27
f01043a0:	eb 36                	jmp    f01043d8 <_alltraps>

f01043a2 <TH_IRQ_8>:
TRAPHANDLER_NOEC(TH_IRQ_8, IRQ_OFFSET+8)
f01043a2:	6a 00                	push   $0x0
f01043a4:	6a 28                	push   $0x28
f01043a6:	eb 30                	jmp    f01043d8 <_alltraps>

f01043a8 <TH_IRQ_9>:
TRAPHANDLER_NOEC(TH_IRQ_9, IRQ_OFFSET+9)
f01043a8:	6a 00                	push   $0x0
f01043aa:	6a 29                	push   $0x29
f01043ac:	eb 2a                	jmp    f01043d8 <_alltraps>

f01043ae <TH_IRQ_10>:
TRAPHANDLER_NOEC(TH_IRQ_10, IRQ_OFFSET+10)
f01043ae:	6a 00                	push   $0x0
f01043b0:	6a 2a                	push   $0x2a
f01043b2:	eb 24                	jmp    f01043d8 <_alltraps>

f01043b4 <TH_IRQ_11>:
TRAPHANDLER_NOEC(TH_IRQ_11, IRQ_OFFSET+11)
f01043b4:	6a 00                	push   $0x0
f01043b6:	6a 2b                	push   $0x2b
f01043b8:	eb 1e                	jmp    f01043d8 <_alltraps>

f01043ba <TH_IRQ_12>:
TRAPHANDLER_NOEC(TH_IRQ_12, IRQ_OFFSET+12)
f01043ba:	6a 00                	push   $0x0
f01043bc:	6a 2c                	push   $0x2c
f01043be:	eb 18                	jmp    f01043d8 <_alltraps>

f01043c0 <TH_IRQ_13>:
TRAPHANDLER_NOEC(TH_IRQ_13, IRQ_OFFSET+13)
f01043c0:	6a 00                	push   $0x0
f01043c2:	6a 2d                	push   $0x2d
f01043c4:	eb 12                	jmp    f01043d8 <_alltraps>

f01043c6 <TH_IRQ_IDE>:
TRAPHANDLER_NOEC(TH_IRQ_IDE, IRQ_OFFSET+IRQ_IDE)	// 14
f01043c6:	6a 00                	push   $0x0
f01043c8:	6a 2e                	push   $0x2e
f01043ca:	eb 0c                	jmp    f01043d8 <_alltraps>

f01043cc <TH_IRQ_15>:
TRAPHANDLER_NOEC(TH_IRQ_15, IRQ_OFFSET+15)
f01043cc:	6a 00                	push   $0x0
f01043ce:	6a 2f                	push   $0x2f
f01043d0:	eb 06                	jmp    f01043d8 <_alltraps>

f01043d2 <TH_IRQ_ERROR>:
TRAPHANDLER_NOEC(TH_IRQ_ERROR, IRQ_OFFSET+IRQ_ERROR)	// 19
f01043d2:	6a 00                	push   $0x0
f01043d4:	6a 33                	push   $0x33
f01043d6:	eb 00                	jmp    f01043d8 <_alltraps>

f01043d8 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f01043d8:	1e                   	push   %ds
	pushl	%es
f01043d9:	06                   	push   %es
	pushal
f01043da:	60                   	pusha  
	mov	$GD_KD, %eax
f01043db:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f01043e0:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f01043e2:	8e d8                	mov    %eax,%ds
	pushl	%esp
f01043e4:	54                   	push   %esp
	call	trap
f01043e5:	e8 cd fc ff ff       	call   f01040b7 <trap>

f01043ea <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01043ea:	55                   	push   %ebp
f01043eb:	89 e5                	mov    %esp,%ebp
f01043ed:	83 ec 08             	sub    $0x8,%esp
f01043f0:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
f01043f5:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01043f8:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01043fd:	8b 02                	mov    (%edx),%eax
f01043ff:	83 e8 01             	sub    $0x1,%eax
f0104402:	83 f8 02             	cmp    $0x2,%eax
f0104405:	76 10                	jbe    f0104417 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104407:	83 c1 01             	add    $0x1,%ecx
f010440a:	83 c2 7c             	add    $0x7c,%edx
f010440d:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104413:	75 e8                	jne    f01043fd <sched_halt+0x13>
f0104415:	eb 08                	jmp    f010441f <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104417:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010441d:	75 1f                	jne    f010443e <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f010441f:	83 ec 0c             	sub    $0xc,%esp
f0104422:	68 70 78 10 f0       	push   $0xf0107870
f0104427:	e8 77 f2 ff ff       	call   f01036a3 <cprintf>
f010442c:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f010442f:	83 ec 0c             	sub    $0xc,%esp
f0104432:	6a 00                	push   $0x0
f0104434:	e8 3d c5 ff ff       	call   f0100976 <monitor>
f0104439:	83 c4 10             	add    $0x10,%esp
f010443c:	eb f1                	jmp    f010442f <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010443e:	e8 a3 16 00 00       	call   f0105ae6 <cpunum>
f0104443:	6b c0 74             	imul   $0x74,%eax,%eax
f0104446:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f010444d:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104450:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104455:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010445a:	77 12                	ja     f010446e <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010445c:	50                   	push   %eax
f010445d:	68 c8 61 10 f0       	push   $0xf01061c8
f0104462:	6a 55                	push   $0x55
f0104464:	68 99 78 10 f0       	push   $0xf0107899
f0104469:	e8 d2 bb ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010446e:	05 00 00 00 10       	add    $0x10000000,%eax
f0104473:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104476:	e8 6b 16 00 00       	call   f0105ae6 <cpunum>
f010447b:	6b d0 74             	imul   $0x74,%eax,%edx
f010447e:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104484:	b8 02 00 00 00       	mov    $0x2,%eax
f0104489:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010448d:	83 ec 0c             	sub    $0xc,%esp
f0104490:	68 c0 03 12 f0       	push   $0xf01203c0
f0104495:	e8 57 19 00 00       	call   f0105df1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010449a:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010449c:	e8 45 16 00 00       	call   f0105ae6 <cpunum>
f01044a1:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01044a4:	8b 80 30 00 23 f0    	mov    -0xfdcffd0(%eax),%eax
f01044aa:	bd 00 00 00 00       	mov    $0x0,%ebp
f01044af:	89 c4                	mov    %eax,%esp
f01044b1:	6a 00                	push   $0x0
f01044b3:	6a 00                	push   $0x0
f01044b5:	fb                   	sti    
f01044b6:	f4                   	hlt    
f01044b7:	eb fd                	jmp    f01044b6 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01044b9:	83 c4 10             	add    $0x10,%esp
f01044bc:	c9                   	leave  
f01044bd:	c3                   	ret    

f01044be <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01044be:	55                   	push   %ebp
f01044bf:	89 e5                	mov    %esp,%ebp
f01044c1:	53                   	push   %ebx
f01044c2:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here:
	size_t index = 0, first = 0;

	if(curenv)
f01044c5:	e8 1c 16 00 00       	call   f0105ae6 <cpunum>
f01044ca:	6b c0 74             	imul   $0x74,%eax,%eax
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here:
	size_t index = 0, first = 0;
f01044cd:	ba 00 00 00 00       	mov    $0x0,%edx

	if(curenv)
f01044d2:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01044d9:	74 1a                	je     f01044f5 <sched_yield+0x37>
		first = ENVX(curenv->env_id) + 1;
f01044db:	e8 06 16 00 00       	call   f0105ae6 <cpunum>
f01044e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01044e3:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01044e9:	8b 50 48             	mov    0x48(%eax),%edx
f01044ec:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01044f2:	83 c2 01             	add    $0x1,%edx

	for(size_t i = 0; i < NENV; ++i)
	{
		index = (first + i) % NENV;
		
		if(envs[index].env_status == ENV_RUNNABLE)
f01044f5:	8b 0d 44 f2 22 f0    	mov    0xf022f244,%ecx
f01044fb:	8d 9a 00 04 00 00    	lea    0x400(%edx),%ebx
f0104501:	89 d0                	mov    %edx,%eax
f0104503:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104508:	6b c0 7c             	imul   $0x7c,%eax,%eax
f010450b:	01 c8                	add    %ecx,%eax
f010450d:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0104511:	74 09                	je     f010451c <sched_yield+0x5e>
f0104513:	83 c2 01             	add    $0x1,%edx
	size_t index = 0, first = 0;

	if(curenv)
		first = ENVX(curenv->env_id) + 1;

	for(size_t i = 0; i < NENV; ++i)
f0104516:	39 da                	cmp    %ebx,%edx
f0104518:	75 e7                	jne    f0104501 <sched_yield+0x43>
f010451a:	eb 0d                	jmp    f0104529 <sched_yield+0x6b>
			idle = &envs[index];
			break;
		}
	}	
	
	if(idle)
f010451c:	85 c0                	test   %eax,%eax
f010451e:	74 09                	je     f0104529 <sched_yield+0x6b>
		env_run(idle);
f0104520:	83 ec 0c             	sub    $0xc,%esp
f0104523:	50                   	push   %eax
f0104524:	e8 60 ef ff ff       	call   f0103489 <env_run>
	
	else
	{
		if(curenv && curenv->env_status == ENV_RUNNING)
f0104529:	e8 b8 15 00 00       	call   f0105ae6 <cpunum>
f010452e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104531:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104538:	74 2a                	je     f0104564 <sched_yield+0xa6>
f010453a:	e8 a7 15 00 00       	call   f0105ae6 <cpunum>
f010453f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104542:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104548:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010454c:	75 16                	jne    f0104564 <sched_yield+0xa6>
			env_run(curenv);
f010454e:	e8 93 15 00 00       	call   f0105ae6 <cpunum>
f0104553:	83 ec 0c             	sub    $0xc,%esp
f0104556:	6b c0 74             	imul   $0x74,%eax,%eax
f0104559:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010455f:	e8 25 ef ff ff       	call   f0103489 <env_run>
	}	

	// sched_halt never returns
	sched_halt();
f0104564:	e8 81 fe ff ff       	call   f01043ea <sched_halt>
}
f0104569:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010456c:	c9                   	leave  
f010456d:	c3                   	ret    

f010456e <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010456e:	55                   	push   %ebp
f010456f:	89 e5                	mov    %esp,%ebp
f0104571:	57                   	push   %edi
f0104572:	56                   	push   %esi
f0104573:	53                   	push   %ebx
f0104574:	83 ec 1c             	sub    $0x1c,%esp
f0104577:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
f010457a:	83 f8 0a             	cmp    $0xa,%eax
f010457d:	0f 87 cb 03 00 00    	ja     f010494e <syscall+0x3e0>
f0104583:	ff 24 85 e0 78 10 f0 	jmp    *-0xfef8720(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f010458a:	e8 57 15 00 00       	call   f0105ae6 <cpunum>
f010458f:	6a 04                	push   $0x4
f0104591:	ff 75 10             	pushl  0x10(%ebp)
f0104594:	ff 75 0c             	pushl  0xc(%ebp)
f0104597:	6b c0 74             	imul   $0x74,%eax,%eax
f010459a:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01045a0:	e8 df e7 ff ff       	call   f0102d84 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01045a5:	83 c4 0c             	add    $0xc,%esp
f01045a8:	ff 75 0c             	pushl  0xc(%ebp)
f01045ab:	ff 75 10             	pushl  0x10(%ebp)
f01045ae:	68 a6 78 10 f0       	push   $0xf01078a6
f01045b3:	e8 eb f0 ff ff       	call   f01036a3 <cprintf>
f01045b8:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
f01045bb:	bb 00 00 00 00       	mov    $0x0,%ebx
f01045c0:	e9 8e 03 00 00       	jmp    f0104953 <syscall+0x3e5>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01045c5:	e8 49 c0 ff ff       	call   f0100613 <cons_getc>
f01045ca:	89 c3                	mov    %eax,%ebx

	switch (syscallno) 
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			 return sys_cgetc();		
f01045cc:	e9 82 03 00 00       	jmp    f0104953 <syscall+0x3e5>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01045d1:	e8 10 15 00 00       	call   f0105ae6 <cpunum>
f01045d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01045d9:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01045df:	8b 58 48             	mov    0x48(%eax),%ebx
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			 return sys_cgetc();		

		case SYS_getenvid:		 return sys_getenvid();
f01045e2:	e9 6c 03 00 00       	jmp    f0104953 <syscall+0x3e5>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01045e7:	83 ec 04             	sub    $0x4,%esp
f01045ea:	6a 01                	push   $0x1
f01045ec:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045ef:	50                   	push   %eax
f01045f0:	ff 75 0c             	pushl  0xc(%ebp)
f01045f3:	e8 41 e8 ff ff       	call   f0102e39 <envid2env>
f01045f8:	83 c4 10             	add    $0x10,%esp
		return r;
f01045fb:	89 c3                	mov    %eax,%ebx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01045fd:	85 c0                	test   %eax,%eax
f01045ff:	0f 88 4e 03 00 00    	js     f0104953 <syscall+0x3e5>
		return r;
	if (e == curenv)
f0104605:	e8 dc 14 00 00       	call   f0105ae6 <cpunum>
f010460a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010460d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104610:	39 90 28 00 23 f0    	cmp    %edx,-0xfdcffd8(%eax)
f0104616:	75 23                	jne    f010463b <syscall+0xcd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104618:	e8 c9 14 00 00       	call   f0105ae6 <cpunum>
f010461d:	83 ec 08             	sub    $0x8,%esp
f0104620:	6b c0 74             	imul   $0x74,%eax,%eax
f0104623:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104629:	ff 70 48             	pushl  0x48(%eax)
f010462c:	68 ab 78 10 f0       	push   $0xf01078ab
f0104631:	e8 6d f0 ff ff       	call   f01036a3 <cprintf>
f0104636:	83 c4 10             	add    $0x10,%esp
f0104639:	eb 25                	jmp    f0104660 <syscall+0xf2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010463b:	8b 5a 48             	mov    0x48(%edx),%ebx
f010463e:	e8 a3 14 00 00       	call   f0105ae6 <cpunum>
f0104643:	83 ec 04             	sub    $0x4,%esp
f0104646:	53                   	push   %ebx
f0104647:	6b c0 74             	imul   $0x74,%eax,%eax
f010464a:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104650:	ff 70 48             	pushl  0x48(%eax)
f0104653:	68 c6 78 10 f0       	push   $0xf01078c6
f0104658:	e8 46 f0 ff ff       	call   f01036a3 <cprintf>
f010465d:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104660:	83 ec 0c             	sub    $0xc,%esp
f0104663:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104666:	e8 7f ed ff ff       	call   f01033ea <env_destroy>
f010466b:	83 c4 10             	add    $0x10,%esp
	return 0;
f010466e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104673:	e9 db 02 00 00       	jmp    f0104953 <syscall+0x3e5>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104678:	e8 41 fe ff ff       	call   f01044be <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = env_alloc(&env, curenv->env_id);
f010467d:	e8 64 14 00 00       	call   f0105ae6 <cpunum>
f0104682:	83 ec 08             	sub    $0x8,%esp
f0104685:	6b c0 74             	imul   $0x74,%eax,%eax
f0104688:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010468e:	ff 70 48             	pushl  0x48(%eax)
f0104691:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104694:	50                   	push   %eax
f0104695:	e8 aa e8 ff ff       	call   f0102f44 <env_alloc>
f010469a:	89 c3                	mov    %eax,%ebx
	
	if(result)
f010469c:	83 c4 10             	add    $0x10,%esp
f010469f:	85 c0                	test   %eax,%eax
f01046a1:	0f 85 ac 02 00 00    	jne    f0104953 <syscall+0x3e5>
		return result;

	env->env_status = ENV_NOT_RUNNABLE;
f01046a7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01046aa:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	env->env_tf = curenv->env_tf;
f01046b1:	e8 30 14 00 00       	call   f0105ae6 <cpunum>
f01046b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01046b9:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
f01046bf:	b9 11 00 00 00       	mov    $0x11,%ecx
f01046c4:	89 df                	mov    %ebx,%edi
f01046c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	env->env_tf.tf_regs.reg_eax = 0;
f01046c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046cb:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return env->env_id;
f01046d2:	8b 58 48             	mov    0x48(%eax),%ebx

		case SYS_env_destroy:		 return sys_env_destroy((envid_t) a1);
		
		case SYS_yield:			 sys_yield();			return 0;
	
		case SYS_exofork:		 return (int32_t) sys_exofork();
f01046d5:	e9 79 02 00 00       	jmp    f0104953 <syscall+0x3e5>
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f01046da:	83 ec 04             	sub    $0x4,%esp
f01046dd:	6a 01                	push   $0x1
f01046df:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01046e2:	50                   	push   %eax
f01046e3:	ff 75 0c             	pushl  0xc(%ebp)
f01046e6:	e8 4e e7 ff ff       	call   f0102e39 <envid2env>
f01046eb:	89 c3                	mov    %eax,%ebx

	if(result)
f01046ed:	83 c4 10             	add    $0x10,%esp
f01046f0:	85 c0                	test   %eax,%eax
f01046f2:	0f 85 5b 02 00 00    	jne    f0104953 <syscall+0x3e5>
		return result;

	if(status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE)
f01046f8:	8b 45 10             	mov    0x10(%ebp),%eax
f01046fb:	83 e8 02             	sub    $0x2,%eax
f01046fe:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104703:	75 0e                	jne    f0104713 <syscall+0x1a5>
		return -E_INVAL;

	env->env_status = status;
f0104705:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104708:	8b 7d 10             	mov    0x10(%ebp),%edi
f010470b:	89 78 54             	mov    %edi,0x54(%eax)
f010470e:	e9 40 02 00 00       	jmp    f0104953 <syscall+0x3e5>

	if(result)
		return result;

	if(status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE)
		return -E_INVAL;
f0104713:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		
		case SYS_yield:			 sys_yield();			return 0;
	
		case SYS_exofork:		 return (int32_t) sys_exofork();

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);
f0104718:	e9 36 02 00 00       	jmp    f0104953 <syscall+0x3e5>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f010471d:	83 ec 04             	sub    $0x4,%esp
f0104720:	6a 01                	push   $0x1
f0104722:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104725:	50                   	push   %eax
f0104726:	ff 75 0c             	pushl  0xc(%ebp)
f0104729:	e8 0b e7 ff ff       	call   f0102e39 <envid2env>

	if(result)
f010472e:	83 c4 10             	add    $0x10,%esp
f0104731:	85 c0                	test   %eax,%eax
f0104733:	75 69                	jne    f010479e <syscall+0x230>
		return -E_BAD_ENV;

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
f0104735:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010473c:	77 6a                	ja     f01047a8 <syscall+0x23a>
f010473e:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104745:	75 6b                	jne    f01047b2 <syscall+0x244>
		return -E_INVAL;
	
	if(perm & ~PTE_SYSCALL)
f0104747:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f010474e:	75 6c                	jne    f01047bc <syscall+0x24e>
		return -E_INVAL;

	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))	
f0104750:	8b 45 14             	mov    0x14(%ebp),%eax
f0104753:	83 e0 05             	and    $0x5,%eax
f0104756:	83 f8 05             	cmp    $0x5,%eax
f0104759:	75 6b                	jne    f01047c6 <syscall+0x258>
		return -E_INVAL;

	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f010475b:	83 ec 0c             	sub    $0xc,%esp
f010475e:	6a 01                	push   $0x1
f0104760:	e8 6a c8 ff ff       	call   f0100fcf <page_alloc>
f0104765:	89 c6                	mov    %eax,%esi

	if(!page)
f0104767:	83 c4 10             	add    $0x10,%esp
f010476a:	85 c0                	test   %eax,%eax
f010476c:	74 62                	je     f01047d0 <syscall+0x262>
		return -E_NO_MEM;

	result = page_insert(env->env_pgdir, page, va, perm);
f010476e:	ff 75 14             	pushl  0x14(%ebp)
f0104771:	ff 75 10             	pushl  0x10(%ebp)
f0104774:	50                   	push   %eax
f0104775:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104778:	ff 70 60             	pushl  0x60(%eax)
f010477b:	e8 4e cb ff ff       	call   f01012ce <page_insert>
f0104780:	89 c3                	mov    %eax,%ebx

	if(result)
f0104782:	83 c4 10             	add    $0x10,%esp
f0104785:	85 c0                	test   %eax,%eax
f0104787:	0f 84 c6 01 00 00    	je     f0104953 <syscall+0x3e5>
	{
		page_free(page);
f010478d:	83 ec 0c             	sub    $0xc,%esp
f0104790:	56                   	push   %esi
f0104791:	e8 a9 c8 ff ff       	call   f010103f <page_free>
f0104796:	83 c4 10             	add    $0x10,%esp
f0104799:	e9 b5 01 00 00       	jmp    f0104953 <syscall+0x3e5>
	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);

	if(result)
		return -E_BAD_ENV;
f010479e:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01047a3:	e9 ab 01 00 00       	jmp    f0104953 <syscall+0x3e5>

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
		return -E_INVAL;
f01047a8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047ad:	e9 a1 01 00 00       	jmp    f0104953 <syscall+0x3e5>
f01047b2:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047b7:	e9 97 01 00 00       	jmp    f0104953 <syscall+0x3e5>
	
	if(perm & ~PTE_SYSCALL)
		return -E_INVAL;
f01047bc:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047c1:	e9 8d 01 00 00       	jmp    f0104953 <syscall+0x3e5>

	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))	
		return -E_INVAL;
f01047c6:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047cb:	e9 83 01 00 00       	jmp    f0104953 <syscall+0x3e5>

	struct PageInfo *page = page_alloc(ALLOC_ZERO);

	if(!page)
		return -E_NO_MEM;
f01047d0:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
	
		case SYS_exofork:		 return (int32_t) sys_exofork();

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
f01047d5:	e9 79 01 00 00       	jmp    f0104953 <syscall+0x3e5>
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	struct Env *src, *dst;
	size_t result_src = envid2env(srcenvid, &src, perm);
f01047da:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f01047de:	0f 95 c3             	setne  %bl
f01047e1:	0f b6 db             	movzbl %bl,%ebx
f01047e4:	83 ec 04             	sub    $0x4,%esp
f01047e7:	53                   	push   %ebx
f01047e8:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01047eb:	50                   	push   %eax
f01047ec:	ff 75 0c             	pushl  0xc(%ebp)
f01047ef:	e8 45 e6 ff ff       	call   f0102e39 <envid2env>
f01047f4:	89 c6                	mov    %eax,%esi
	size_t result_dst = envid2env(dstenvid, &dst, perm);
f01047f6:	83 c4 0c             	add    $0xc,%esp
f01047f9:	53                   	push   %ebx
f01047fa:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01047fd:	50                   	push   %eax
f01047fe:	ff 75 14             	pushl  0x14(%ebp)
f0104801:	e8 33 e6 ff ff       	call   f0102e39 <envid2env>
	
	if(result_src || result_dst)
f0104806:	83 c4 10             	add    $0x10,%esp
f0104809:	09 c6                	or     %eax,%esi
f010480b:	75 75                	jne    f0104882 <syscall+0x314>
		return -E_BAD_ENV;

	if((((uint32_t) srcva >= UTOP) || ((uint32_t) srcva % PGSIZE != 0)) || 	
f010480d:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104814:	77 76                	ja     f010488c <syscall+0x31e>
f0104816:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010481d:	75 77                	jne    f0104896 <syscall+0x328>
f010481f:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104826:	77 6e                	ja     f0104896 <syscall+0x328>
	  	(((uint32_t) dstva >= UTOP) || ((uint32_t) dstva % PGSIZE != 0)))
f0104828:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f010482f:	75 6f                	jne    f01048a0 <syscall+0x332>
		return -E_INVAL;

	pte_t *pte;
	struct PageInfo *page = page_lookup(src->env_pgdir, srcva, &pte);
f0104831:	83 ec 04             	sub    $0x4,%esp
f0104834:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104837:	50                   	push   %eax
f0104838:	ff 75 10             	pushl  0x10(%ebp)
f010483b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010483e:	ff 70 60             	pushl  0x60(%eax)
f0104841:	e8 a4 c9 ff ff       	call   f01011ea <page_lookup>

	if(!page)
f0104846:	83 c4 10             	add    $0x10,%esp
f0104849:	85 c0                	test   %eax,%eax
f010484b:	74 5d                	je     f01048aa <syscall+0x33c>
		return -E_INVAL;

	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))
f010484d:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104850:	83 e2 05             	and    $0x5,%edx
f0104853:	83 fa 05             	cmp    $0x5,%edx
f0104856:	75 5c                	jne    f01048b4 <syscall+0x346>
		return -E_INVAL;

	if ((perm & PTE_W) && !(*pte & PTE_W))
f0104858:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f010485c:	74 08                	je     f0104866 <syscall+0x2f8>
f010485e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104861:	f6 02 02             	testb  $0x2,(%edx)
f0104864:	74 58                	je     f01048be <syscall+0x350>
		return -E_INVAL;

	size_t result = page_insert(dst->env_pgdir, page, dstva, perm);
f0104866:	ff 75 1c             	pushl  0x1c(%ebp)
f0104869:	ff 75 18             	pushl  0x18(%ebp)
f010486c:	50                   	push   %eax
f010486d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104870:	ff 70 60             	pushl  0x60(%eax)
f0104873:	e8 56 ca ff ff       	call   f01012ce <page_insert>
f0104878:	89 c3                	mov    %eax,%ebx
f010487a:	83 c4 10             	add    $0x10,%esp
f010487d:	e9 d1 00 00 00       	jmp    f0104953 <syscall+0x3e5>
	struct Env *src, *dst;
	size_t result_src = envid2env(srcenvid, &src, perm);
	size_t result_dst = envid2env(dstenvid, &dst, perm);
	
	if(result_src || result_dst)
		return -E_BAD_ENV;
f0104882:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104887:	e9 c7 00 00 00       	jmp    f0104953 <syscall+0x3e5>

	if((((uint32_t) srcva >= UTOP) || ((uint32_t) srcva % PGSIZE != 0)) || 	
	  	(((uint32_t) dstva >= UTOP) || ((uint32_t) dstva % PGSIZE != 0)))
		return -E_INVAL;
f010488c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104891:	e9 bd 00 00 00       	jmp    f0104953 <syscall+0x3e5>
f0104896:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010489b:	e9 b3 00 00 00       	jmp    f0104953 <syscall+0x3e5>
f01048a0:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01048a5:	e9 a9 00 00 00       	jmp    f0104953 <syscall+0x3e5>

	pte_t *pte;
	struct PageInfo *page = page_lookup(src->env_pgdir, srcva, &pte);

	if(!page)
		return -E_INVAL;
f01048aa:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01048af:	e9 9f 00 00 00       	jmp    f0104953 <syscall+0x3e5>

	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))
		return -E_INVAL;
f01048b4:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01048b9:	e9 95 00 00 00       	jmp    f0104953 <syscall+0x3e5>

	if ((perm & PTE_W) && !(*pte & PTE_W))
		return -E_INVAL;
f01048be:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);
f01048c3:	e9 8b 00 00 00       	jmp    f0104953 <syscall+0x3e5>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f01048c8:	83 ec 04             	sub    $0x4,%esp
f01048cb:	6a 01                	push   $0x1
f01048cd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01048d0:	50                   	push   %eax
f01048d1:	ff 75 0c             	pushl  0xc(%ebp)
f01048d4:	e8 60 e5 ff ff       	call   f0102e39 <envid2env>
f01048d9:	89 c3                	mov    %eax,%ebx

	if(result)
f01048db:	83 c4 10             	add    $0x10,%esp
f01048de:	85 c0                	test   %eax,%eax
f01048e0:	75 28                	jne    f010490a <syscall+0x39c>
		return -E_BAD_ENV;

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
f01048e2:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01048e9:	77 26                	ja     f0104911 <syscall+0x3a3>
f01048eb:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01048f2:	75 24                	jne    f0104918 <syscall+0x3aa>
		return -E_INVAL;

	page_remove(env->env_pgdir, va);
f01048f4:	83 ec 08             	sub    $0x8,%esp
f01048f7:	ff 75 10             	pushl  0x10(%ebp)
f01048fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048fd:	ff 70 60             	pushl  0x60(%eax)
f0104900:	e8 74 c9 ff ff       	call   f0101279 <page_remove>
f0104905:	83 c4 10             	add    $0x10,%esp
f0104908:	eb 49                	jmp    f0104953 <syscall+0x3e5>
	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);

	if(result)
		return -E_BAD_ENV;
f010490a:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f010490f:	eb 42                	jmp    f0104953 <syscall+0x3e5>

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
		return -E_INVAL;
f0104911:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104916:	eb 3b                	jmp    f0104953 <syscall+0x3e5>
f0104918:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);

		case SYS_page_unmap:		 return sys_page_unmap((envid_t) a1, (void *) a2);
f010491d:	eb 34                	jmp    f0104953 <syscall+0x3e5>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *env;
	envid2env(envid, &env, 1);
f010491f:	83 ec 04             	sub    $0x4,%esp
f0104922:	6a 01                	push   $0x1
f0104924:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104927:	50                   	push   %eax
f0104928:	ff 75 0c             	pushl  0xc(%ebp)
f010492b:	e8 09 e5 ff ff       	call   f0102e39 <envid2env>

	if(!env)
f0104930:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104933:	83 c4 10             	add    $0x10,%esp
f0104936:	85 c0                	test   %eax,%eax
f0104938:	74 0d                	je     f0104947 <syscall+0x3d9>
		return -E_BAD_ENV;

	env->env_pgfault_upcall = func;
f010493a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010493d:	89 48 64             	mov    %ecx,0x64(%eax)

	return 0;
f0104940:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104945:	eb 0c                	jmp    f0104953 <syscall+0x3e5>
	// LAB 4: Your code here.
	struct Env *env;
	envid2env(envid, &env, 1);

	if(!env)
		return -E_BAD_ENV;
f0104947:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);

		case SYS_page_unmap:		 return sys_page_unmap((envid_t) a1, (void *) a2);
		
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void*)a2);
f010494c:	eb 05                	jmp    f0104953 <syscall+0x3e5>

		default:			 return -E_INVAL;
f010494e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
	}
}
f0104953:	89 d8                	mov    %ebx,%eax
f0104955:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104958:	5b                   	pop    %ebx
f0104959:	5e                   	pop    %esi
f010495a:	5f                   	pop    %edi
f010495b:	5d                   	pop    %ebp
f010495c:	c3                   	ret    

f010495d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010495d:	55                   	push   %ebp
f010495e:	89 e5                	mov    %esp,%ebp
f0104960:	57                   	push   %edi
f0104961:	56                   	push   %esi
f0104962:	53                   	push   %ebx
f0104963:	83 ec 14             	sub    $0x14,%esp
f0104966:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104969:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010496c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010496f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104972:	8b 1a                	mov    (%edx),%ebx
f0104974:	8b 01                	mov    (%ecx),%eax
f0104976:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104979:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104980:	eb 7f                	jmp    f0104a01 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104982:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104985:	01 d8                	add    %ebx,%eax
f0104987:	89 c6                	mov    %eax,%esi
f0104989:	c1 ee 1f             	shr    $0x1f,%esi
f010498c:	01 c6                	add    %eax,%esi
f010498e:	d1 fe                	sar    %esi
f0104990:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104993:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104996:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104999:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010499b:	eb 03                	jmp    f01049a0 <stab_binsearch+0x43>
			m--;
f010499d:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01049a0:	39 c3                	cmp    %eax,%ebx
f01049a2:	7f 0d                	jg     f01049b1 <stab_binsearch+0x54>
f01049a4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01049a8:	83 ea 0c             	sub    $0xc,%edx
f01049ab:	39 f9                	cmp    %edi,%ecx
f01049ad:	75 ee                	jne    f010499d <stab_binsearch+0x40>
f01049af:	eb 05                	jmp    f01049b6 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01049b1:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01049b4:	eb 4b                	jmp    f0104a01 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01049b6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01049b9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01049bc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01049c0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01049c3:	76 11                	jbe    f01049d6 <stab_binsearch+0x79>
			*region_left = m;
f01049c5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01049c8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01049ca:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01049cd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01049d4:	eb 2b                	jmp    f0104a01 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01049d6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01049d9:	73 14                	jae    f01049ef <stab_binsearch+0x92>
			*region_right = m - 1;
f01049db:	83 e8 01             	sub    $0x1,%eax
f01049de:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01049e1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01049e4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01049e6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01049ed:	eb 12                	jmp    f0104a01 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01049ef:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01049f2:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01049f4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01049f8:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01049fa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104a01:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104a04:	0f 8e 78 ff ff ff    	jle    f0104982 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104a0a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104a0e:	75 0f                	jne    f0104a1f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104a10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a13:	8b 00                	mov    (%eax),%eax
f0104a15:	83 e8 01             	sub    $0x1,%eax
f0104a18:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104a1b:	89 06                	mov    %eax,(%esi)
f0104a1d:	eb 2c                	jmp    f0104a4b <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104a1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a22:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104a24:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104a27:	8b 0e                	mov    (%esi),%ecx
f0104a29:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104a2c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104a2f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104a32:	eb 03                	jmp    f0104a37 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104a34:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104a37:	39 c8                	cmp    %ecx,%eax
f0104a39:	7e 0b                	jle    f0104a46 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104a3b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104a3f:	83 ea 0c             	sub    $0xc,%edx
f0104a42:	39 df                	cmp    %ebx,%edi
f0104a44:	75 ee                	jne    f0104a34 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104a46:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104a49:	89 06                	mov    %eax,(%esi)
	}
}
f0104a4b:	83 c4 14             	add    $0x14,%esp
f0104a4e:	5b                   	pop    %ebx
f0104a4f:	5e                   	pop    %esi
f0104a50:	5f                   	pop    %edi
f0104a51:	5d                   	pop    %ebp
f0104a52:	c3                   	ret    

f0104a53 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104a53:	55                   	push   %ebp
f0104a54:	89 e5                	mov    %esp,%ebp
f0104a56:	57                   	push   %edi
f0104a57:	56                   	push   %esi
f0104a58:	53                   	push   %ebx
f0104a59:	83 ec 3c             	sub    $0x3c,%esp
f0104a5c:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104a5f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104a62:	c7 03 0c 79 10 f0    	movl   $0xf010790c,(%ebx)
	info->eip_line = 0;
f0104a68:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104a6f:	c7 43 08 0c 79 10 f0 	movl   $0xf010790c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104a76:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104a7d:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104a80:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104a87:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104a8d:	0f 87 a3 00 00 00    	ja     f0104b36 <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f0104a93:	e8 4e 10 00 00       	call   f0105ae6 <cpunum>
f0104a98:	6a 04                	push   $0x4
f0104a9a:	6a 10                	push   $0x10
f0104a9c:	68 00 00 20 00       	push   $0x200000
f0104aa1:	6b c0 74             	imul   $0x74,%eax,%eax
f0104aa4:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104aaa:	e8 5f e2 ff ff       	call   f0102d0e <user_mem_check>
f0104aaf:	83 c4 10             	add    $0x10,%esp
f0104ab2:	85 c0                	test   %eax,%eax
f0104ab4:	0f 84 3e 02 00 00    	je     f0104cf8 <debuginfo_eip+0x2a5>
                        return -1;

		stabs = usd->stabs;
f0104aba:	a1 00 00 20 00       	mov    0x200000,%eax
f0104abf:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0104ac2:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104ac8:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104ace:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104ad1:	a1 0c 00 20 00       	mov    0x20000c,%eax
f0104ad6:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f0104ad9:	e8 08 10 00 00       	call   f0105ae6 <cpunum>
f0104ade:	6a 04                	push   $0x4
f0104ae0:	89 f2                	mov    %esi,%edx
f0104ae2:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104ae5:	29 ca                	sub    %ecx,%edx
f0104ae7:	c1 fa 02             	sar    $0x2,%edx
f0104aea:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104af0:	52                   	push   %edx
f0104af1:	51                   	push   %ecx
f0104af2:	6b c0 74             	imul   $0x74,%eax,%eax
f0104af5:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104afb:	e8 0e e2 ff ff       	call   f0102d0e <user_mem_check>
f0104b00:	83 c4 10             	add    $0x10,%esp
f0104b03:	85 c0                	test   %eax,%eax
f0104b05:	0f 84 f4 01 00 00    	je     f0104cff <debuginfo_eip+0x2ac>
			return -1;

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f0104b0b:	e8 d6 0f 00 00       	call   f0105ae6 <cpunum>
f0104b10:	6a 04                	push   $0x4
f0104b12:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104b15:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104b18:	29 ca                	sub    %ecx,%edx
f0104b1a:	52                   	push   %edx
f0104b1b:	51                   	push   %ecx
f0104b1c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b1f:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104b25:	e8 e4 e1 ff ff       	call   f0102d0e <user_mem_check>
f0104b2a:	83 c4 10             	add    $0x10,%esp
f0104b2d:	85 c0                	test   %eax,%eax
f0104b2f:	75 1f                	jne    f0104b50 <debuginfo_eip+0xfd>
f0104b31:	e9 d0 01 00 00       	jmp    f0104d06 <debuginfo_eip+0x2b3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104b36:	c7 45 bc da 54 11 f0 	movl   $0xf01154da,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104b3d:	c7 45 b8 2d 1e 11 f0 	movl   $0xf0111e2d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104b44:	be 2c 1e 11 f0       	mov    $0xf0111e2c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104b49:	c7 45 c0 f4 7d 10 f0 	movl   $0xf0107df4,-0x40(%ebp)
		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104b50:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104b53:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104b56:	0f 83 b1 01 00 00    	jae    f0104d0d <debuginfo_eip+0x2ba>
f0104b5c:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104b60:	0f 85 ae 01 00 00    	jne    f0104d14 <debuginfo_eip+0x2c1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104b66:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104b6d:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104b70:	c1 fe 02             	sar    $0x2,%esi
f0104b73:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104b79:	83 e8 01             	sub    $0x1,%eax
f0104b7c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104b7f:	83 ec 08             	sub    $0x8,%esp
f0104b82:	57                   	push   %edi
f0104b83:	6a 64                	push   $0x64
f0104b85:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104b88:	89 d1                	mov    %edx,%ecx
f0104b8a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104b8d:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104b90:	89 f0                	mov    %esi,%eax
f0104b92:	e8 c6 fd ff ff       	call   f010495d <stab_binsearch>
	if (lfile == 0)
f0104b97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b9a:	83 c4 10             	add    $0x10,%esp
f0104b9d:	85 c0                	test   %eax,%eax
f0104b9f:	0f 84 76 01 00 00    	je     f0104d1b <debuginfo_eip+0x2c8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104ba5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104ba8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104bab:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104bae:	83 ec 08             	sub    $0x8,%esp
f0104bb1:	57                   	push   %edi
f0104bb2:	6a 24                	push   $0x24
f0104bb4:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104bb7:	89 d1                	mov    %edx,%ecx
f0104bb9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104bbc:	89 f0                	mov    %esi,%eax
f0104bbe:	e8 9a fd ff ff       	call   f010495d <stab_binsearch>

	if (lfun <= rfun) {
f0104bc3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104bc6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104bc9:	83 c4 10             	add    $0x10,%esp
f0104bcc:	39 d0                	cmp    %edx,%eax
f0104bce:	7f 2e                	jg     f0104bfe <debuginfo_eip+0x1ab>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104bd0:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104bd3:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104bd6:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104bd9:	8b 36                	mov    (%esi),%esi
f0104bdb:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104bde:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104be1:	39 ce                	cmp    %ecx,%esi
f0104be3:	73 06                	jae    f0104beb <debuginfo_eip+0x198>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104be5:	03 75 b8             	add    -0x48(%ebp),%esi
f0104be8:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104beb:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104bee:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104bf1:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104bf4:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104bf6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104bf9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104bfc:	eb 0f                	jmp    f0104c0d <debuginfo_eip+0x1ba>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104bfe:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104c01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c04:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c0a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104c0d:	83 ec 08             	sub    $0x8,%esp
f0104c10:	6a 3a                	push   $0x3a
f0104c12:	ff 73 08             	pushl  0x8(%ebx)
f0104c15:	e8 8f 08 00 00       	call   f01054a9 <strfind>
f0104c1a:	2b 43 08             	sub    0x8(%ebx),%eax
f0104c1d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104c20:	83 c4 08             	add    $0x8,%esp
f0104c23:	57                   	push   %edi
f0104c24:	6a 44                	push   $0x44
f0104c26:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104c29:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104c2c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104c2f:	89 f8                	mov    %edi,%eax
f0104c31:	e8 27 fd ff ff       	call   f010495d <stab_binsearch>
	
	if(lline > rline)
f0104c36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104c39:	83 c4 10             	add    $0x10,%esp
f0104c3c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104c3f:	0f 8f dd 00 00 00    	jg     f0104d22 <debuginfo_eip+0x2cf>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f0104c45:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104c48:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104c4b:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0104c4f:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104c52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c55:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104c59:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104c5c:	eb 0a                	jmp    f0104c68 <debuginfo_eip+0x215>
f0104c5e:	83 e8 01             	sub    $0x1,%eax
f0104c61:	83 ea 0c             	sub    $0xc,%edx
f0104c64:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104c68:	39 c7                	cmp    %eax,%edi
f0104c6a:	7e 05                	jle    f0104c71 <debuginfo_eip+0x21e>
f0104c6c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c6f:	eb 47                	jmp    f0104cb8 <debuginfo_eip+0x265>
	       && stabs[lline].n_type != N_SOL
f0104c71:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104c75:	80 f9 84             	cmp    $0x84,%cl
f0104c78:	75 0e                	jne    f0104c88 <debuginfo_eip+0x235>
f0104c7a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c7d:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104c81:	74 1c                	je     f0104c9f <debuginfo_eip+0x24c>
f0104c83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104c86:	eb 17                	jmp    f0104c9f <debuginfo_eip+0x24c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104c88:	80 f9 64             	cmp    $0x64,%cl
f0104c8b:	75 d1                	jne    f0104c5e <debuginfo_eip+0x20b>
f0104c8d:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104c91:	74 cb                	je     f0104c5e <debuginfo_eip+0x20b>
f0104c93:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c96:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104c9a:	74 03                	je     f0104c9f <debuginfo_eip+0x24c>
f0104c9c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104c9f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104ca2:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104ca5:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104ca8:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104cab:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104cae:	29 f8                	sub    %edi,%eax
f0104cb0:	39 c2                	cmp    %eax,%edx
f0104cb2:	73 04                	jae    f0104cb8 <debuginfo_eip+0x265>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104cb4:	01 fa                	add    %edi,%edx
f0104cb6:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104cb8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104cbb:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104cbe:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104cc3:	39 f2                	cmp    %esi,%edx
f0104cc5:	7d 67                	jge    f0104d2e <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
f0104cc7:	83 c2 01             	add    $0x1,%edx
f0104cca:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104ccd:	89 d0                	mov    %edx,%eax
f0104ccf:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104cd2:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104cd5:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104cd8:	eb 04                	jmp    f0104cde <debuginfo_eip+0x28b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104cda:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104cde:	39 c6                	cmp    %eax,%esi
f0104ce0:	7e 47                	jle    f0104d29 <debuginfo_eip+0x2d6>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104ce2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104ce6:	83 c0 01             	add    $0x1,%eax
f0104ce9:	83 c2 0c             	add    $0xc,%edx
f0104cec:	80 f9 a0             	cmp    $0xa0,%cl
f0104cef:	74 e9                	je     f0104cda <debuginfo_eip+0x287>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104cf1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cf6:	eb 36                	jmp    f0104d2e <debuginfo_eip+0x2db>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
                        return -1;
f0104cf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104cfd:	eb 2f                	jmp    f0104d2e <debuginfo_eip+0x2db>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
			return -1;
f0104cff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d04:	eb 28                	jmp    f0104d2e <debuginfo_eip+0x2db>

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f0104d06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d0b:	eb 21                	jmp    f0104d2e <debuginfo_eip+0x2db>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104d0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d12:	eb 1a                	jmp    f0104d2e <debuginfo_eip+0x2db>
f0104d14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d19:	eb 13                	jmp    f0104d2e <debuginfo_eip+0x2db>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104d1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d20:	eb 0c                	jmp    f0104d2e <debuginfo_eip+0x2db>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0104d22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d27:	eb 05                	jmp    f0104d2e <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104d29:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d2e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d31:	5b                   	pop    %ebx
f0104d32:	5e                   	pop    %esi
f0104d33:	5f                   	pop    %edi
f0104d34:	5d                   	pop    %ebp
f0104d35:	c3                   	ret    

f0104d36 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104d36:	55                   	push   %ebp
f0104d37:	89 e5                	mov    %esp,%ebp
f0104d39:	57                   	push   %edi
f0104d3a:	56                   	push   %esi
f0104d3b:	53                   	push   %ebx
f0104d3c:	83 ec 1c             	sub    $0x1c,%esp
f0104d3f:	89 c7                	mov    %eax,%edi
f0104d41:	89 d6                	mov    %edx,%esi
f0104d43:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d46:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d49:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104d4c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104d4f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104d52:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104d57:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104d5a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104d5d:	39 d3                	cmp    %edx,%ebx
f0104d5f:	72 05                	jb     f0104d66 <printnum+0x30>
f0104d61:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104d64:	77 45                	ja     f0104dab <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104d66:	83 ec 0c             	sub    $0xc,%esp
f0104d69:	ff 75 18             	pushl  0x18(%ebp)
f0104d6c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d6f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104d72:	53                   	push   %ebx
f0104d73:	ff 75 10             	pushl  0x10(%ebp)
f0104d76:	83 ec 08             	sub    $0x8,%esp
f0104d79:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104d7c:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d7f:	ff 75 dc             	pushl  -0x24(%ebp)
f0104d82:	ff 75 d8             	pushl  -0x28(%ebp)
f0104d85:	e8 56 11 00 00       	call   f0105ee0 <__udivdi3>
f0104d8a:	83 c4 18             	add    $0x18,%esp
f0104d8d:	52                   	push   %edx
f0104d8e:	50                   	push   %eax
f0104d8f:	89 f2                	mov    %esi,%edx
f0104d91:	89 f8                	mov    %edi,%eax
f0104d93:	e8 9e ff ff ff       	call   f0104d36 <printnum>
f0104d98:	83 c4 20             	add    $0x20,%esp
f0104d9b:	eb 18                	jmp    f0104db5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104d9d:	83 ec 08             	sub    $0x8,%esp
f0104da0:	56                   	push   %esi
f0104da1:	ff 75 18             	pushl  0x18(%ebp)
f0104da4:	ff d7                	call   *%edi
f0104da6:	83 c4 10             	add    $0x10,%esp
f0104da9:	eb 03                	jmp    f0104dae <printnum+0x78>
f0104dab:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104dae:	83 eb 01             	sub    $0x1,%ebx
f0104db1:	85 db                	test   %ebx,%ebx
f0104db3:	7f e8                	jg     f0104d9d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104db5:	83 ec 08             	sub    $0x8,%esp
f0104db8:	56                   	push   %esi
f0104db9:	83 ec 04             	sub    $0x4,%esp
f0104dbc:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104dbf:	ff 75 e0             	pushl  -0x20(%ebp)
f0104dc2:	ff 75 dc             	pushl  -0x24(%ebp)
f0104dc5:	ff 75 d8             	pushl  -0x28(%ebp)
f0104dc8:	e8 43 12 00 00       	call   f0106010 <__umoddi3>
f0104dcd:	83 c4 14             	add    $0x14,%esp
f0104dd0:	0f be 80 16 79 10 f0 	movsbl -0xfef86ea(%eax),%eax
f0104dd7:	50                   	push   %eax
f0104dd8:	ff d7                	call   *%edi
}
f0104dda:	83 c4 10             	add    $0x10,%esp
f0104ddd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104de0:	5b                   	pop    %ebx
f0104de1:	5e                   	pop    %esi
f0104de2:	5f                   	pop    %edi
f0104de3:	5d                   	pop    %ebp
f0104de4:	c3                   	ret    

f0104de5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104de5:	55                   	push   %ebp
f0104de6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104de8:	83 fa 01             	cmp    $0x1,%edx
f0104deb:	7e 0e                	jle    f0104dfb <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104ded:	8b 10                	mov    (%eax),%edx
f0104def:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104df2:	89 08                	mov    %ecx,(%eax)
f0104df4:	8b 02                	mov    (%edx),%eax
f0104df6:	8b 52 04             	mov    0x4(%edx),%edx
f0104df9:	eb 22                	jmp    f0104e1d <getuint+0x38>
	else if (lflag)
f0104dfb:	85 d2                	test   %edx,%edx
f0104dfd:	74 10                	je     f0104e0f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104dff:	8b 10                	mov    (%eax),%edx
f0104e01:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104e04:	89 08                	mov    %ecx,(%eax)
f0104e06:	8b 02                	mov    (%edx),%eax
f0104e08:	ba 00 00 00 00       	mov    $0x0,%edx
f0104e0d:	eb 0e                	jmp    f0104e1d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104e0f:	8b 10                	mov    (%eax),%edx
f0104e11:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104e14:	89 08                	mov    %ecx,(%eax)
f0104e16:	8b 02                	mov    (%edx),%eax
f0104e18:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104e1d:	5d                   	pop    %ebp
f0104e1e:	c3                   	ret    

f0104e1f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104e1f:	55                   	push   %ebp
f0104e20:	89 e5                	mov    %esp,%ebp
f0104e22:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104e25:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104e29:	8b 10                	mov    (%eax),%edx
f0104e2b:	3b 50 04             	cmp    0x4(%eax),%edx
f0104e2e:	73 0a                	jae    f0104e3a <sprintputch+0x1b>
		*b->buf++ = ch;
f0104e30:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104e33:	89 08                	mov    %ecx,(%eax)
f0104e35:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e38:	88 02                	mov    %al,(%edx)
}
f0104e3a:	5d                   	pop    %ebp
f0104e3b:	c3                   	ret    

f0104e3c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104e3c:	55                   	push   %ebp
f0104e3d:	89 e5                	mov    %esp,%ebp
f0104e3f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104e42:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104e45:	50                   	push   %eax
f0104e46:	ff 75 10             	pushl  0x10(%ebp)
f0104e49:	ff 75 0c             	pushl  0xc(%ebp)
f0104e4c:	ff 75 08             	pushl  0x8(%ebp)
f0104e4f:	e8 05 00 00 00       	call   f0104e59 <vprintfmt>
	va_end(ap);
}
f0104e54:	83 c4 10             	add    $0x10,%esp
f0104e57:	c9                   	leave  
f0104e58:	c3                   	ret    

f0104e59 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104e59:	55                   	push   %ebp
f0104e5a:	89 e5                	mov    %esp,%ebp
f0104e5c:	57                   	push   %edi
f0104e5d:	56                   	push   %esi
f0104e5e:	53                   	push   %ebx
f0104e5f:	83 ec 2c             	sub    $0x2c,%esp
f0104e62:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e65:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104e68:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104e6b:	eb 12                	jmp    f0104e7f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104e6d:	85 c0                	test   %eax,%eax
f0104e6f:	0f 84 89 03 00 00    	je     f01051fe <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104e75:	83 ec 08             	sub    $0x8,%esp
f0104e78:	53                   	push   %ebx
f0104e79:	50                   	push   %eax
f0104e7a:	ff d6                	call   *%esi
f0104e7c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104e7f:	83 c7 01             	add    $0x1,%edi
f0104e82:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104e86:	83 f8 25             	cmp    $0x25,%eax
f0104e89:	75 e2                	jne    f0104e6d <vprintfmt+0x14>
f0104e8b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104e8f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104e96:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e9d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104ea4:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ea9:	eb 07                	jmp    f0104eb2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104eab:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104eae:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104eb2:	8d 47 01             	lea    0x1(%edi),%eax
f0104eb5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104eb8:	0f b6 07             	movzbl (%edi),%eax
f0104ebb:	0f b6 c8             	movzbl %al,%ecx
f0104ebe:	83 e8 23             	sub    $0x23,%eax
f0104ec1:	3c 55                	cmp    $0x55,%al
f0104ec3:	0f 87 1a 03 00 00    	ja     f01051e3 <vprintfmt+0x38a>
f0104ec9:	0f b6 c0             	movzbl %al,%eax
f0104ecc:	ff 24 85 e0 79 10 f0 	jmp    *-0xfef8620(,%eax,4)
f0104ed3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104ed6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104eda:	eb d6                	jmp    f0104eb2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104edc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104edf:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ee4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104ee7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104eea:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104eee:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104ef1:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104ef4:	83 fa 09             	cmp    $0x9,%edx
f0104ef7:	77 39                	ja     f0104f32 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104ef9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104efc:	eb e9                	jmp    f0104ee7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104efe:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f01:	8d 48 04             	lea    0x4(%eax),%ecx
f0104f04:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104f07:	8b 00                	mov    (%eax),%eax
f0104f09:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104f0f:	eb 27                	jmp    f0104f38 <vprintfmt+0xdf>
f0104f11:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104f14:	85 c0                	test   %eax,%eax
f0104f16:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104f1b:	0f 49 c8             	cmovns %eax,%ecx
f0104f1e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f24:	eb 8c                	jmp    f0104eb2 <vprintfmt+0x59>
f0104f26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104f29:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104f30:	eb 80                	jmp    f0104eb2 <vprintfmt+0x59>
f0104f32:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104f35:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104f38:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104f3c:	0f 89 70 ff ff ff    	jns    f0104eb2 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104f42:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104f45:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f48:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104f4f:	e9 5e ff ff ff       	jmp    f0104eb2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104f54:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104f5a:	e9 53 ff ff ff       	jmp    f0104eb2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104f5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f62:	8d 50 04             	lea    0x4(%eax),%edx
f0104f65:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f68:	83 ec 08             	sub    $0x8,%esp
f0104f6b:	53                   	push   %ebx
f0104f6c:	ff 30                	pushl  (%eax)
f0104f6e:	ff d6                	call   *%esi
			break;
f0104f70:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104f76:	e9 04 ff ff ff       	jmp    f0104e7f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104f7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f7e:	8d 50 04             	lea    0x4(%eax),%edx
f0104f81:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f84:	8b 00                	mov    (%eax),%eax
f0104f86:	99                   	cltd   
f0104f87:	31 d0                	xor    %edx,%eax
f0104f89:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104f8b:	83 f8 08             	cmp    $0x8,%eax
f0104f8e:	7f 0b                	jg     f0104f9b <vprintfmt+0x142>
f0104f90:	8b 14 85 40 7b 10 f0 	mov    -0xfef84c0(,%eax,4),%edx
f0104f97:	85 d2                	test   %edx,%edx
f0104f99:	75 18                	jne    f0104fb3 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104f9b:	50                   	push   %eax
f0104f9c:	68 2e 79 10 f0       	push   $0xf010792e
f0104fa1:	53                   	push   %ebx
f0104fa2:	56                   	push   %esi
f0104fa3:	e8 94 fe ff ff       	call   f0104e3c <printfmt>
f0104fa8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104fae:	e9 cc fe ff ff       	jmp    f0104e7f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104fb3:	52                   	push   %edx
f0104fb4:	68 fd 70 10 f0       	push   $0xf01070fd
f0104fb9:	53                   	push   %ebx
f0104fba:	56                   	push   %esi
f0104fbb:	e8 7c fe ff ff       	call   f0104e3c <printfmt>
f0104fc0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fc6:	e9 b4 fe ff ff       	jmp    f0104e7f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104fcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fce:	8d 50 04             	lea    0x4(%eax),%edx
f0104fd1:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fd4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104fd6:	85 ff                	test   %edi,%edi
f0104fd8:	b8 27 79 10 f0       	mov    $0xf0107927,%eax
f0104fdd:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104fe0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104fe4:	0f 8e 94 00 00 00    	jle    f010507e <vprintfmt+0x225>
f0104fea:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104fee:	0f 84 98 00 00 00    	je     f010508c <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ff4:	83 ec 08             	sub    $0x8,%esp
f0104ff7:	ff 75 d0             	pushl  -0x30(%ebp)
f0104ffa:	57                   	push   %edi
f0104ffb:	e8 5f 03 00 00       	call   f010535f <strnlen>
f0105000:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0105003:	29 c1                	sub    %eax,%ecx
f0105005:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0105008:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010500b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010500f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105012:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0105015:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105017:	eb 0f                	jmp    f0105028 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0105019:	83 ec 08             	sub    $0x8,%esp
f010501c:	53                   	push   %ebx
f010501d:	ff 75 e0             	pushl  -0x20(%ebp)
f0105020:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105022:	83 ef 01             	sub    $0x1,%edi
f0105025:	83 c4 10             	add    $0x10,%esp
f0105028:	85 ff                	test   %edi,%edi
f010502a:	7f ed                	jg     f0105019 <vprintfmt+0x1c0>
f010502c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010502f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0105032:	85 c9                	test   %ecx,%ecx
f0105034:	b8 00 00 00 00       	mov    $0x0,%eax
f0105039:	0f 49 c1             	cmovns %ecx,%eax
f010503c:	29 c1                	sub    %eax,%ecx
f010503e:	89 75 08             	mov    %esi,0x8(%ebp)
f0105041:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105044:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0105047:	89 cb                	mov    %ecx,%ebx
f0105049:	eb 4d                	jmp    f0105098 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010504b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010504f:	74 1b                	je     f010506c <vprintfmt+0x213>
f0105051:	0f be c0             	movsbl %al,%eax
f0105054:	83 e8 20             	sub    $0x20,%eax
f0105057:	83 f8 5e             	cmp    $0x5e,%eax
f010505a:	76 10                	jbe    f010506c <vprintfmt+0x213>
					putch('?', putdat);
f010505c:	83 ec 08             	sub    $0x8,%esp
f010505f:	ff 75 0c             	pushl  0xc(%ebp)
f0105062:	6a 3f                	push   $0x3f
f0105064:	ff 55 08             	call   *0x8(%ebp)
f0105067:	83 c4 10             	add    $0x10,%esp
f010506a:	eb 0d                	jmp    f0105079 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010506c:	83 ec 08             	sub    $0x8,%esp
f010506f:	ff 75 0c             	pushl  0xc(%ebp)
f0105072:	52                   	push   %edx
f0105073:	ff 55 08             	call   *0x8(%ebp)
f0105076:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105079:	83 eb 01             	sub    $0x1,%ebx
f010507c:	eb 1a                	jmp    f0105098 <vprintfmt+0x23f>
f010507e:	89 75 08             	mov    %esi,0x8(%ebp)
f0105081:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105084:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0105087:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010508a:	eb 0c                	jmp    f0105098 <vprintfmt+0x23f>
f010508c:	89 75 08             	mov    %esi,0x8(%ebp)
f010508f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105092:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0105095:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0105098:	83 c7 01             	add    $0x1,%edi
f010509b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010509f:	0f be d0             	movsbl %al,%edx
f01050a2:	85 d2                	test   %edx,%edx
f01050a4:	74 23                	je     f01050c9 <vprintfmt+0x270>
f01050a6:	85 f6                	test   %esi,%esi
f01050a8:	78 a1                	js     f010504b <vprintfmt+0x1f2>
f01050aa:	83 ee 01             	sub    $0x1,%esi
f01050ad:	79 9c                	jns    f010504b <vprintfmt+0x1f2>
f01050af:	89 df                	mov    %ebx,%edi
f01050b1:	8b 75 08             	mov    0x8(%ebp),%esi
f01050b4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01050b7:	eb 18                	jmp    f01050d1 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01050b9:	83 ec 08             	sub    $0x8,%esp
f01050bc:	53                   	push   %ebx
f01050bd:	6a 20                	push   $0x20
f01050bf:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01050c1:	83 ef 01             	sub    $0x1,%edi
f01050c4:	83 c4 10             	add    $0x10,%esp
f01050c7:	eb 08                	jmp    f01050d1 <vprintfmt+0x278>
f01050c9:	89 df                	mov    %ebx,%edi
f01050cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01050ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01050d1:	85 ff                	test   %edi,%edi
f01050d3:	7f e4                	jg     f01050b9 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050d8:	e9 a2 fd ff ff       	jmp    f0104e7f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01050dd:	83 fa 01             	cmp    $0x1,%edx
f01050e0:	7e 16                	jle    f01050f8 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01050e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01050e5:	8d 50 08             	lea    0x8(%eax),%edx
f01050e8:	89 55 14             	mov    %edx,0x14(%ebp)
f01050eb:	8b 50 04             	mov    0x4(%eax),%edx
f01050ee:	8b 00                	mov    (%eax),%eax
f01050f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01050f3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01050f6:	eb 32                	jmp    f010512a <vprintfmt+0x2d1>
	else if (lflag)
f01050f8:	85 d2                	test   %edx,%edx
f01050fa:	74 18                	je     f0105114 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01050fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01050ff:	8d 50 04             	lea    0x4(%eax),%edx
f0105102:	89 55 14             	mov    %edx,0x14(%ebp)
f0105105:	8b 00                	mov    (%eax),%eax
f0105107:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010510a:	89 c1                	mov    %eax,%ecx
f010510c:	c1 f9 1f             	sar    $0x1f,%ecx
f010510f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0105112:	eb 16                	jmp    f010512a <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0105114:	8b 45 14             	mov    0x14(%ebp),%eax
f0105117:	8d 50 04             	lea    0x4(%eax),%edx
f010511a:	89 55 14             	mov    %edx,0x14(%ebp)
f010511d:	8b 00                	mov    (%eax),%eax
f010511f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105122:	89 c1                	mov    %eax,%ecx
f0105124:	c1 f9 1f             	sar    $0x1f,%ecx
f0105127:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010512a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010512d:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105130:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105135:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105139:	79 74                	jns    f01051af <vprintfmt+0x356>
				putch('-', putdat);
f010513b:	83 ec 08             	sub    $0x8,%esp
f010513e:	53                   	push   %ebx
f010513f:	6a 2d                	push   $0x2d
f0105141:	ff d6                	call   *%esi
				num = -(long long) num;
f0105143:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105146:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105149:	f7 d8                	neg    %eax
f010514b:	83 d2 00             	adc    $0x0,%edx
f010514e:	f7 da                	neg    %edx
f0105150:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105153:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105158:	eb 55                	jmp    f01051af <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010515a:	8d 45 14             	lea    0x14(%ebp),%eax
f010515d:	e8 83 fc ff ff       	call   f0104de5 <getuint>
			base = 10;
f0105162:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105167:	eb 46                	jmp    f01051af <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0105169:	8d 45 14             	lea    0x14(%ebp),%eax
f010516c:	e8 74 fc ff ff       	call   f0104de5 <getuint>
			base = 8;
f0105171:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105176:	eb 37                	jmp    f01051af <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0105178:	83 ec 08             	sub    $0x8,%esp
f010517b:	53                   	push   %ebx
f010517c:	6a 30                	push   $0x30
f010517e:	ff d6                	call   *%esi
			putch('x', putdat);
f0105180:	83 c4 08             	add    $0x8,%esp
f0105183:	53                   	push   %ebx
f0105184:	6a 78                	push   $0x78
f0105186:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105188:	8b 45 14             	mov    0x14(%ebp),%eax
f010518b:	8d 50 04             	lea    0x4(%eax),%edx
f010518e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105191:	8b 00                	mov    (%eax),%eax
f0105193:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0105198:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010519b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01051a0:	eb 0d                	jmp    f01051af <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01051a2:	8d 45 14             	lea    0x14(%ebp),%eax
f01051a5:	e8 3b fc ff ff       	call   f0104de5 <getuint>
			base = 16;
f01051aa:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01051af:	83 ec 0c             	sub    $0xc,%esp
f01051b2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01051b6:	57                   	push   %edi
f01051b7:	ff 75 e0             	pushl  -0x20(%ebp)
f01051ba:	51                   	push   %ecx
f01051bb:	52                   	push   %edx
f01051bc:	50                   	push   %eax
f01051bd:	89 da                	mov    %ebx,%edx
f01051bf:	89 f0                	mov    %esi,%eax
f01051c1:	e8 70 fb ff ff       	call   f0104d36 <printnum>
			break;
f01051c6:	83 c4 20             	add    $0x20,%esp
f01051c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01051cc:	e9 ae fc ff ff       	jmp    f0104e7f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01051d1:	83 ec 08             	sub    $0x8,%esp
f01051d4:	53                   	push   %ebx
f01051d5:	51                   	push   %ecx
f01051d6:	ff d6                	call   *%esi
			break;
f01051d8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01051db:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01051de:	e9 9c fc ff ff       	jmp    f0104e7f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01051e3:	83 ec 08             	sub    $0x8,%esp
f01051e6:	53                   	push   %ebx
f01051e7:	6a 25                	push   $0x25
f01051e9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01051eb:	83 c4 10             	add    $0x10,%esp
f01051ee:	eb 03                	jmp    f01051f3 <vprintfmt+0x39a>
f01051f0:	83 ef 01             	sub    $0x1,%edi
f01051f3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01051f7:	75 f7                	jne    f01051f0 <vprintfmt+0x397>
f01051f9:	e9 81 fc ff ff       	jmp    f0104e7f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01051fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105201:	5b                   	pop    %ebx
f0105202:	5e                   	pop    %esi
f0105203:	5f                   	pop    %edi
f0105204:	5d                   	pop    %ebp
f0105205:	c3                   	ret    

f0105206 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105206:	55                   	push   %ebp
f0105207:	89 e5                	mov    %esp,%ebp
f0105209:	83 ec 18             	sub    $0x18,%esp
f010520c:	8b 45 08             	mov    0x8(%ebp),%eax
f010520f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105212:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105215:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105219:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010521c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105223:	85 c0                	test   %eax,%eax
f0105225:	74 26                	je     f010524d <vsnprintf+0x47>
f0105227:	85 d2                	test   %edx,%edx
f0105229:	7e 22                	jle    f010524d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010522b:	ff 75 14             	pushl  0x14(%ebp)
f010522e:	ff 75 10             	pushl  0x10(%ebp)
f0105231:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105234:	50                   	push   %eax
f0105235:	68 1f 4e 10 f0       	push   $0xf0104e1f
f010523a:	e8 1a fc ff ff       	call   f0104e59 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010523f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105242:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105245:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105248:	83 c4 10             	add    $0x10,%esp
f010524b:	eb 05                	jmp    f0105252 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010524d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105252:	c9                   	leave  
f0105253:	c3                   	ret    

f0105254 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105254:	55                   	push   %ebp
f0105255:	89 e5                	mov    %esp,%ebp
f0105257:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010525a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010525d:	50                   	push   %eax
f010525e:	ff 75 10             	pushl  0x10(%ebp)
f0105261:	ff 75 0c             	pushl  0xc(%ebp)
f0105264:	ff 75 08             	pushl  0x8(%ebp)
f0105267:	e8 9a ff ff ff       	call   f0105206 <vsnprintf>
	va_end(ap);

	return rc;
}
f010526c:	c9                   	leave  
f010526d:	c3                   	ret    

f010526e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010526e:	55                   	push   %ebp
f010526f:	89 e5                	mov    %esp,%ebp
f0105271:	57                   	push   %edi
f0105272:	56                   	push   %esi
f0105273:	53                   	push   %ebx
f0105274:	83 ec 0c             	sub    $0xc,%esp
f0105277:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010527a:	85 c0                	test   %eax,%eax
f010527c:	74 11                	je     f010528f <readline+0x21>
		cprintf("%s", prompt);
f010527e:	83 ec 08             	sub    $0x8,%esp
f0105281:	50                   	push   %eax
f0105282:	68 fd 70 10 f0       	push   $0xf01070fd
f0105287:	e8 17 e4 ff ff       	call   f01036a3 <cprintf>
f010528c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010528f:	83 ec 0c             	sub    $0xc,%esp
f0105292:	6a 00                	push   $0x0
f0105294:	e8 0a b5 ff ff       	call   f01007a3 <iscons>
f0105299:	89 c7                	mov    %eax,%edi
f010529b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010529e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01052a3:	e8 ea b4 ff ff       	call   f0100792 <getchar>
f01052a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01052aa:	85 c0                	test   %eax,%eax
f01052ac:	79 18                	jns    f01052c6 <readline+0x58>
			cprintf("read error: %e\n", c);
f01052ae:	83 ec 08             	sub    $0x8,%esp
f01052b1:	50                   	push   %eax
f01052b2:	68 64 7b 10 f0       	push   $0xf0107b64
f01052b7:	e8 e7 e3 ff ff       	call   f01036a3 <cprintf>
			return NULL;
f01052bc:	83 c4 10             	add    $0x10,%esp
f01052bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01052c4:	eb 79                	jmp    f010533f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01052c6:	83 f8 08             	cmp    $0x8,%eax
f01052c9:	0f 94 c2             	sete   %dl
f01052cc:	83 f8 7f             	cmp    $0x7f,%eax
f01052cf:	0f 94 c0             	sete   %al
f01052d2:	08 c2                	or     %al,%dl
f01052d4:	74 1a                	je     f01052f0 <readline+0x82>
f01052d6:	85 f6                	test   %esi,%esi
f01052d8:	7e 16                	jle    f01052f0 <readline+0x82>
			if (echoing)
f01052da:	85 ff                	test   %edi,%edi
f01052dc:	74 0d                	je     f01052eb <readline+0x7d>
				cputchar('\b');
f01052de:	83 ec 0c             	sub    $0xc,%esp
f01052e1:	6a 08                	push   $0x8
f01052e3:	e8 9a b4 ff ff       	call   f0100782 <cputchar>
f01052e8:	83 c4 10             	add    $0x10,%esp
			i--;
f01052eb:	83 ee 01             	sub    $0x1,%esi
f01052ee:	eb b3                	jmp    f01052a3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01052f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01052f3:	7e 23                	jle    f0105318 <readline+0xaa>
f01052f5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01052fb:	7f 1b                	jg     f0105318 <readline+0xaa>
			if (echoing)
f01052fd:	85 ff                	test   %edi,%edi
f01052ff:	74 0c                	je     f010530d <readline+0x9f>
				cputchar(c);
f0105301:	83 ec 0c             	sub    $0xc,%esp
f0105304:	53                   	push   %ebx
f0105305:	e8 78 b4 ff ff       	call   f0100782 <cputchar>
f010530a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010530d:	88 9e 80 fa 22 f0    	mov    %bl,-0xfdd0580(%esi)
f0105313:	8d 76 01             	lea    0x1(%esi),%esi
f0105316:	eb 8b                	jmp    f01052a3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105318:	83 fb 0a             	cmp    $0xa,%ebx
f010531b:	74 05                	je     f0105322 <readline+0xb4>
f010531d:	83 fb 0d             	cmp    $0xd,%ebx
f0105320:	75 81                	jne    f01052a3 <readline+0x35>
			if (echoing)
f0105322:	85 ff                	test   %edi,%edi
f0105324:	74 0d                	je     f0105333 <readline+0xc5>
				cputchar('\n');
f0105326:	83 ec 0c             	sub    $0xc,%esp
f0105329:	6a 0a                	push   $0xa
f010532b:	e8 52 b4 ff ff       	call   f0100782 <cputchar>
f0105330:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105333:	c6 86 80 fa 22 f0 00 	movb   $0x0,-0xfdd0580(%esi)
			return buf;
f010533a:	b8 80 fa 22 f0       	mov    $0xf022fa80,%eax
		}
	}
}
f010533f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105342:	5b                   	pop    %ebx
f0105343:	5e                   	pop    %esi
f0105344:	5f                   	pop    %edi
f0105345:	5d                   	pop    %ebp
f0105346:	c3                   	ret    

f0105347 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105347:	55                   	push   %ebp
f0105348:	89 e5                	mov    %esp,%ebp
f010534a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010534d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105352:	eb 03                	jmp    f0105357 <strlen+0x10>
		n++;
f0105354:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105357:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010535b:	75 f7                	jne    f0105354 <strlen+0xd>
		n++;
	return n;
}
f010535d:	5d                   	pop    %ebp
f010535e:	c3                   	ret    

f010535f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010535f:	55                   	push   %ebp
f0105360:	89 e5                	mov    %esp,%ebp
f0105362:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105365:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105368:	ba 00 00 00 00       	mov    $0x0,%edx
f010536d:	eb 03                	jmp    f0105372 <strnlen+0x13>
		n++;
f010536f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105372:	39 c2                	cmp    %eax,%edx
f0105374:	74 08                	je     f010537e <strnlen+0x1f>
f0105376:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010537a:	75 f3                	jne    f010536f <strnlen+0x10>
f010537c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010537e:	5d                   	pop    %ebp
f010537f:	c3                   	ret    

f0105380 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105380:	55                   	push   %ebp
f0105381:	89 e5                	mov    %esp,%ebp
f0105383:	53                   	push   %ebx
f0105384:	8b 45 08             	mov    0x8(%ebp),%eax
f0105387:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010538a:	89 c2                	mov    %eax,%edx
f010538c:	83 c2 01             	add    $0x1,%edx
f010538f:	83 c1 01             	add    $0x1,%ecx
f0105392:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105396:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105399:	84 db                	test   %bl,%bl
f010539b:	75 ef                	jne    f010538c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010539d:	5b                   	pop    %ebx
f010539e:	5d                   	pop    %ebp
f010539f:	c3                   	ret    

f01053a0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01053a0:	55                   	push   %ebp
f01053a1:	89 e5                	mov    %esp,%ebp
f01053a3:	53                   	push   %ebx
f01053a4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01053a7:	53                   	push   %ebx
f01053a8:	e8 9a ff ff ff       	call   f0105347 <strlen>
f01053ad:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01053b0:	ff 75 0c             	pushl  0xc(%ebp)
f01053b3:	01 d8                	add    %ebx,%eax
f01053b5:	50                   	push   %eax
f01053b6:	e8 c5 ff ff ff       	call   f0105380 <strcpy>
	return dst;
}
f01053bb:	89 d8                	mov    %ebx,%eax
f01053bd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01053c0:	c9                   	leave  
f01053c1:	c3                   	ret    

f01053c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01053c2:	55                   	push   %ebp
f01053c3:	89 e5                	mov    %esp,%ebp
f01053c5:	56                   	push   %esi
f01053c6:	53                   	push   %ebx
f01053c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01053ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01053cd:	89 f3                	mov    %esi,%ebx
f01053cf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01053d2:	89 f2                	mov    %esi,%edx
f01053d4:	eb 0f                	jmp    f01053e5 <strncpy+0x23>
		*dst++ = *src;
f01053d6:	83 c2 01             	add    $0x1,%edx
f01053d9:	0f b6 01             	movzbl (%ecx),%eax
f01053dc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01053df:	80 39 01             	cmpb   $0x1,(%ecx)
f01053e2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01053e5:	39 da                	cmp    %ebx,%edx
f01053e7:	75 ed                	jne    f01053d6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01053e9:	89 f0                	mov    %esi,%eax
f01053eb:	5b                   	pop    %ebx
f01053ec:	5e                   	pop    %esi
f01053ed:	5d                   	pop    %ebp
f01053ee:	c3                   	ret    

f01053ef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01053ef:	55                   	push   %ebp
f01053f0:	89 e5                	mov    %esp,%ebp
f01053f2:	56                   	push   %esi
f01053f3:	53                   	push   %ebx
f01053f4:	8b 75 08             	mov    0x8(%ebp),%esi
f01053f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01053fa:	8b 55 10             	mov    0x10(%ebp),%edx
f01053fd:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01053ff:	85 d2                	test   %edx,%edx
f0105401:	74 21                	je     f0105424 <strlcpy+0x35>
f0105403:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105407:	89 f2                	mov    %esi,%edx
f0105409:	eb 09                	jmp    f0105414 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010540b:	83 c2 01             	add    $0x1,%edx
f010540e:	83 c1 01             	add    $0x1,%ecx
f0105411:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105414:	39 c2                	cmp    %eax,%edx
f0105416:	74 09                	je     f0105421 <strlcpy+0x32>
f0105418:	0f b6 19             	movzbl (%ecx),%ebx
f010541b:	84 db                	test   %bl,%bl
f010541d:	75 ec                	jne    f010540b <strlcpy+0x1c>
f010541f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105421:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105424:	29 f0                	sub    %esi,%eax
}
f0105426:	5b                   	pop    %ebx
f0105427:	5e                   	pop    %esi
f0105428:	5d                   	pop    %ebp
f0105429:	c3                   	ret    

f010542a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010542a:	55                   	push   %ebp
f010542b:	89 e5                	mov    %esp,%ebp
f010542d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105430:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105433:	eb 06                	jmp    f010543b <strcmp+0x11>
		p++, q++;
f0105435:	83 c1 01             	add    $0x1,%ecx
f0105438:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010543b:	0f b6 01             	movzbl (%ecx),%eax
f010543e:	84 c0                	test   %al,%al
f0105440:	74 04                	je     f0105446 <strcmp+0x1c>
f0105442:	3a 02                	cmp    (%edx),%al
f0105444:	74 ef                	je     f0105435 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105446:	0f b6 c0             	movzbl %al,%eax
f0105449:	0f b6 12             	movzbl (%edx),%edx
f010544c:	29 d0                	sub    %edx,%eax
}
f010544e:	5d                   	pop    %ebp
f010544f:	c3                   	ret    

f0105450 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105450:	55                   	push   %ebp
f0105451:	89 e5                	mov    %esp,%ebp
f0105453:	53                   	push   %ebx
f0105454:	8b 45 08             	mov    0x8(%ebp),%eax
f0105457:	8b 55 0c             	mov    0xc(%ebp),%edx
f010545a:	89 c3                	mov    %eax,%ebx
f010545c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010545f:	eb 06                	jmp    f0105467 <strncmp+0x17>
		n--, p++, q++;
f0105461:	83 c0 01             	add    $0x1,%eax
f0105464:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105467:	39 d8                	cmp    %ebx,%eax
f0105469:	74 15                	je     f0105480 <strncmp+0x30>
f010546b:	0f b6 08             	movzbl (%eax),%ecx
f010546e:	84 c9                	test   %cl,%cl
f0105470:	74 04                	je     f0105476 <strncmp+0x26>
f0105472:	3a 0a                	cmp    (%edx),%cl
f0105474:	74 eb                	je     f0105461 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105476:	0f b6 00             	movzbl (%eax),%eax
f0105479:	0f b6 12             	movzbl (%edx),%edx
f010547c:	29 d0                	sub    %edx,%eax
f010547e:	eb 05                	jmp    f0105485 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105480:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105485:	5b                   	pop    %ebx
f0105486:	5d                   	pop    %ebp
f0105487:	c3                   	ret    

f0105488 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105488:	55                   	push   %ebp
f0105489:	89 e5                	mov    %esp,%ebp
f010548b:	8b 45 08             	mov    0x8(%ebp),%eax
f010548e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105492:	eb 07                	jmp    f010549b <strchr+0x13>
		if (*s == c)
f0105494:	38 ca                	cmp    %cl,%dl
f0105496:	74 0f                	je     f01054a7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105498:	83 c0 01             	add    $0x1,%eax
f010549b:	0f b6 10             	movzbl (%eax),%edx
f010549e:	84 d2                	test   %dl,%dl
f01054a0:	75 f2                	jne    f0105494 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01054a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054a7:	5d                   	pop    %ebp
f01054a8:	c3                   	ret    

f01054a9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01054a9:	55                   	push   %ebp
f01054aa:	89 e5                	mov    %esp,%ebp
f01054ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01054af:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01054b3:	eb 03                	jmp    f01054b8 <strfind+0xf>
f01054b5:	83 c0 01             	add    $0x1,%eax
f01054b8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01054bb:	38 ca                	cmp    %cl,%dl
f01054bd:	74 04                	je     f01054c3 <strfind+0x1a>
f01054bf:	84 d2                	test   %dl,%dl
f01054c1:	75 f2                	jne    f01054b5 <strfind+0xc>
			break;
	return (char *) s;
}
f01054c3:	5d                   	pop    %ebp
f01054c4:	c3                   	ret    

f01054c5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01054c5:	55                   	push   %ebp
f01054c6:	89 e5                	mov    %esp,%ebp
f01054c8:	57                   	push   %edi
f01054c9:	56                   	push   %esi
f01054ca:	53                   	push   %ebx
f01054cb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01054ce:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01054d1:	85 c9                	test   %ecx,%ecx
f01054d3:	74 36                	je     f010550b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01054d5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01054db:	75 28                	jne    f0105505 <memset+0x40>
f01054dd:	f6 c1 03             	test   $0x3,%cl
f01054e0:	75 23                	jne    f0105505 <memset+0x40>
		c &= 0xFF;
f01054e2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01054e6:	89 d3                	mov    %edx,%ebx
f01054e8:	c1 e3 08             	shl    $0x8,%ebx
f01054eb:	89 d6                	mov    %edx,%esi
f01054ed:	c1 e6 18             	shl    $0x18,%esi
f01054f0:	89 d0                	mov    %edx,%eax
f01054f2:	c1 e0 10             	shl    $0x10,%eax
f01054f5:	09 f0                	or     %esi,%eax
f01054f7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01054f9:	89 d8                	mov    %ebx,%eax
f01054fb:	09 d0                	or     %edx,%eax
f01054fd:	c1 e9 02             	shr    $0x2,%ecx
f0105500:	fc                   	cld    
f0105501:	f3 ab                	rep stos %eax,%es:(%edi)
f0105503:	eb 06                	jmp    f010550b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105505:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105508:	fc                   	cld    
f0105509:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010550b:	89 f8                	mov    %edi,%eax
f010550d:	5b                   	pop    %ebx
f010550e:	5e                   	pop    %esi
f010550f:	5f                   	pop    %edi
f0105510:	5d                   	pop    %ebp
f0105511:	c3                   	ret    

f0105512 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105512:	55                   	push   %ebp
f0105513:	89 e5                	mov    %esp,%ebp
f0105515:	57                   	push   %edi
f0105516:	56                   	push   %esi
f0105517:	8b 45 08             	mov    0x8(%ebp),%eax
f010551a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010551d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105520:	39 c6                	cmp    %eax,%esi
f0105522:	73 35                	jae    f0105559 <memmove+0x47>
f0105524:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105527:	39 d0                	cmp    %edx,%eax
f0105529:	73 2e                	jae    f0105559 <memmove+0x47>
		s += n;
		d += n;
f010552b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010552e:	89 d6                	mov    %edx,%esi
f0105530:	09 fe                	or     %edi,%esi
f0105532:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105538:	75 13                	jne    f010554d <memmove+0x3b>
f010553a:	f6 c1 03             	test   $0x3,%cl
f010553d:	75 0e                	jne    f010554d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010553f:	83 ef 04             	sub    $0x4,%edi
f0105542:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105545:	c1 e9 02             	shr    $0x2,%ecx
f0105548:	fd                   	std    
f0105549:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010554b:	eb 09                	jmp    f0105556 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010554d:	83 ef 01             	sub    $0x1,%edi
f0105550:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105553:	fd                   	std    
f0105554:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105556:	fc                   	cld    
f0105557:	eb 1d                	jmp    f0105576 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105559:	89 f2                	mov    %esi,%edx
f010555b:	09 c2                	or     %eax,%edx
f010555d:	f6 c2 03             	test   $0x3,%dl
f0105560:	75 0f                	jne    f0105571 <memmove+0x5f>
f0105562:	f6 c1 03             	test   $0x3,%cl
f0105565:	75 0a                	jne    f0105571 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0105567:	c1 e9 02             	shr    $0x2,%ecx
f010556a:	89 c7                	mov    %eax,%edi
f010556c:	fc                   	cld    
f010556d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010556f:	eb 05                	jmp    f0105576 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105571:	89 c7                	mov    %eax,%edi
f0105573:	fc                   	cld    
f0105574:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105576:	5e                   	pop    %esi
f0105577:	5f                   	pop    %edi
f0105578:	5d                   	pop    %ebp
f0105579:	c3                   	ret    

f010557a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010557a:	55                   	push   %ebp
f010557b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010557d:	ff 75 10             	pushl  0x10(%ebp)
f0105580:	ff 75 0c             	pushl  0xc(%ebp)
f0105583:	ff 75 08             	pushl  0x8(%ebp)
f0105586:	e8 87 ff ff ff       	call   f0105512 <memmove>
}
f010558b:	c9                   	leave  
f010558c:	c3                   	ret    

f010558d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010558d:	55                   	push   %ebp
f010558e:	89 e5                	mov    %esp,%ebp
f0105590:	56                   	push   %esi
f0105591:	53                   	push   %ebx
f0105592:	8b 45 08             	mov    0x8(%ebp),%eax
f0105595:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105598:	89 c6                	mov    %eax,%esi
f010559a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010559d:	eb 1a                	jmp    f01055b9 <memcmp+0x2c>
		if (*s1 != *s2)
f010559f:	0f b6 08             	movzbl (%eax),%ecx
f01055a2:	0f b6 1a             	movzbl (%edx),%ebx
f01055a5:	38 d9                	cmp    %bl,%cl
f01055a7:	74 0a                	je     f01055b3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01055a9:	0f b6 c1             	movzbl %cl,%eax
f01055ac:	0f b6 db             	movzbl %bl,%ebx
f01055af:	29 d8                	sub    %ebx,%eax
f01055b1:	eb 0f                	jmp    f01055c2 <memcmp+0x35>
		s1++, s2++;
f01055b3:	83 c0 01             	add    $0x1,%eax
f01055b6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01055b9:	39 f0                	cmp    %esi,%eax
f01055bb:	75 e2                	jne    f010559f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01055bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01055c2:	5b                   	pop    %ebx
f01055c3:	5e                   	pop    %esi
f01055c4:	5d                   	pop    %ebp
f01055c5:	c3                   	ret    

f01055c6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01055c6:	55                   	push   %ebp
f01055c7:	89 e5                	mov    %esp,%ebp
f01055c9:	53                   	push   %ebx
f01055ca:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01055cd:	89 c1                	mov    %eax,%ecx
f01055cf:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01055d2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01055d6:	eb 0a                	jmp    f01055e2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01055d8:	0f b6 10             	movzbl (%eax),%edx
f01055db:	39 da                	cmp    %ebx,%edx
f01055dd:	74 07                	je     f01055e6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01055df:	83 c0 01             	add    $0x1,%eax
f01055e2:	39 c8                	cmp    %ecx,%eax
f01055e4:	72 f2                	jb     f01055d8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01055e6:	5b                   	pop    %ebx
f01055e7:	5d                   	pop    %ebp
f01055e8:	c3                   	ret    

f01055e9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01055e9:	55                   	push   %ebp
f01055ea:	89 e5                	mov    %esp,%ebp
f01055ec:	57                   	push   %edi
f01055ed:	56                   	push   %esi
f01055ee:	53                   	push   %ebx
f01055ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01055f2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01055f5:	eb 03                	jmp    f01055fa <strtol+0x11>
		s++;
f01055f7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01055fa:	0f b6 01             	movzbl (%ecx),%eax
f01055fd:	3c 20                	cmp    $0x20,%al
f01055ff:	74 f6                	je     f01055f7 <strtol+0xe>
f0105601:	3c 09                	cmp    $0x9,%al
f0105603:	74 f2                	je     f01055f7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105605:	3c 2b                	cmp    $0x2b,%al
f0105607:	75 0a                	jne    f0105613 <strtol+0x2a>
		s++;
f0105609:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010560c:	bf 00 00 00 00       	mov    $0x0,%edi
f0105611:	eb 11                	jmp    f0105624 <strtol+0x3b>
f0105613:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105618:	3c 2d                	cmp    $0x2d,%al
f010561a:	75 08                	jne    f0105624 <strtol+0x3b>
		s++, neg = 1;
f010561c:	83 c1 01             	add    $0x1,%ecx
f010561f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105624:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010562a:	75 15                	jne    f0105641 <strtol+0x58>
f010562c:	80 39 30             	cmpb   $0x30,(%ecx)
f010562f:	75 10                	jne    f0105641 <strtol+0x58>
f0105631:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105635:	75 7c                	jne    f01056b3 <strtol+0xca>
		s += 2, base = 16;
f0105637:	83 c1 02             	add    $0x2,%ecx
f010563a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010563f:	eb 16                	jmp    f0105657 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105641:	85 db                	test   %ebx,%ebx
f0105643:	75 12                	jne    f0105657 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105645:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010564a:	80 39 30             	cmpb   $0x30,(%ecx)
f010564d:	75 08                	jne    f0105657 <strtol+0x6e>
		s++, base = 8;
f010564f:	83 c1 01             	add    $0x1,%ecx
f0105652:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105657:	b8 00 00 00 00       	mov    $0x0,%eax
f010565c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010565f:	0f b6 11             	movzbl (%ecx),%edx
f0105662:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105665:	89 f3                	mov    %esi,%ebx
f0105667:	80 fb 09             	cmp    $0x9,%bl
f010566a:	77 08                	ja     f0105674 <strtol+0x8b>
			dig = *s - '0';
f010566c:	0f be d2             	movsbl %dl,%edx
f010566f:	83 ea 30             	sub    $0x30,%edx
f0105672:	eb 22                	jmp    f0105696 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105674:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105677:	89 f3                	mov    %esi,%ebx
f0105679:	80 fb 19             	cmp    $0x19,%bl
f010567c:	77 08                	ja     f0105686 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010567e:	0f be d2             	movsbl %dl,%edx
f0105681:	83 ea 57             	sub    $0x57,%edx
f0105684:	eb 10                	jmp    f0105696 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0105686:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105689:	89 f3                	mov    %esi,%ebx
f010568b:	80 fb 19             	cmp    $0x19,%bl
f010568e:	77 16                	ja     f01056a6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0105690:	0f be d2             	movsbl %dl,%edx
f0105693:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105696:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105699:	7d 0b                	jge    f01056a6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010569b:	83 c1 01             	add    $0x1,%ecx
f010569e:	0f af 45 10          	imul   0x10(%ebp),%eax
f01056a2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01056a4:	eb b9                	jmp    f010565f <strtol+0x76>

	if (endptr)
f01056a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01056aa:	74 0d                	je     f01056b9 <strtol+0xd0>
		*endptr = (char *) s;
f01056ac:	8b 75 0c             	mov    0xc(%ebp),%esi
f01056af:	89 0e                	mov    %ecx,(%esi)
f01056b1:	eb 06                	jmp    f01056b9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01056b3:	85 db                	test   %ebx,%ebx
f01056b5:	74 98                	je     f010564f <strtol+0x66>
f01056b7:	eb 9e                	jmp    f0105657 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01056b9:	89 c2                	mov    %eax,%edx
f01056bb:	f7 da                	neg    %edx
f01056bd:	85 ff                	test   %edi,%edi
f01056bf:	0f 45 c2             	cmovne %edx,%eax
}
f01056c2:	5b                   	pop    %ebx
f01056c3:	5e                   	pop    %esi
f01056c4:	5f                   	pop    %edi
f01056c5:	5d                   	pop    %ebp
f01056c6:	c3                   	ret    
f01056c7:	90                   	nop

f01056c8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01056c8:	fa                   	cli    

	xorw    %ax, %ax
f01056c9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01056cb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01056cd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01056cf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01056d1:	0f 01 16             	lgdtl  (%esi)
f01056d4:	74 70                	je     f0105746 <mpsearch1+0x3>
	movl    %cr0, %eax
f01056d6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01056d9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01056dd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01056e0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01056e6:	08 00                	or     %al,(%eax)

f01056e8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01056e8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01056ec:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01056ee:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01056f0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01056f2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01056f6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01056f8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01056fa:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01056ff:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105702:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105705:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010570a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f010570d:	8b 25 84 fe 22 f0    	mov    0xf022fe84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105713:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105718:	b8 d1 01 10 f0       	mov    $0xf01001d1,%eax
	call    *%eax
f010571d:	ff d0                	call   *%eax

f010571f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010571f:	eb fe                	jmp    f010571f <spin>
f0105721:	8d 76 00             	lea    0x0(%esi),%esi

f0105724 <gdt>:
	...
f010572c:	ff                   	(bad)  
f010572d:	ff 00                	incl   (%eax)
f010572f:	00 00                	add    %al,(%eax)
f0105731:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105738:	00                   	.byte 0x0
f0105739:	92                   	xchg   %eax,%edx
f010573a:	cf                   	iret   
	...

f010573c <gdtdesc>:
f010573c:	17                   	pop    %ss
f010573d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105742 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105742:	90                   	nop

f0105743 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105743:	55                   	push   %ebp
f0105744:	89 e5                	mov    %esp,%ebp
f0105746:	57                   	push   %edi
f0105747:	56                   	push   %esi
f0105748:	53                   	push   %ebx
f0105749:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010574c:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0105752:	89 c3                	mov    %eax,%ebx
f0105754:	c1 eb 0c             	shr    $0xc,%ebx
f0105757:	39 cb                	cmp    %ecx,%ebx
f0105759:	72 12                	jb     f010576d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010575b:	50                   	push   %eax
f010575c:	68 a4 61 10 f0       	push   $0xf01061a4
f0105761:	6a 57                	push   $0x57
f0105763:	68 01 7d 10 f0       	push   $0xf0107d01
f0105768:	e8 d3 a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010576d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105773:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105775:	89 c2                	mov    %eax,%edx
f0105777:	c1 ea 0c             	shr    $0xc,%edx
f010577a:	39 ca                	cmp    %ecx,%edx
f010577c:	72 12                	jb     f0105790 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010577e:	50                   	push   %eax
f010577f:	68 a4 61 10 f0       	push   $0xf01061a4
f0105784:	6a 57                	push   $0x57
f0105786:	68 01 7d 10 f0       	push   $0xf0107d01
f010578b:	e8 b0 a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105790:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105796:	eb 2f                	jmp    f01057c7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105798:	83 ec 04             	sub    $0x4,%esp
f010579b:	6a 04                	push   $0x4
f010579d:	68 11 7d 10 f0       	push   $0xf0107d11
f01057a2:	53                   	push   %ebx
f01057a3:	e8 e5 fd ff ff       	call   f010558d <memcmp>
f01057a8:	83 c4 10             	add    $0x10,%esp
f01057ab:	85 c0                	test   %eax,%eax
f01057ad:	75 15                	jne    f01057c4 <mpsearch1+0x81>
f01057af:	89 da                	mov    %ebx,%edx
f01057b1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01057b4:	0f b6 0a             	movzbl (%edx),%ecx
f01057b7:	01 c8                	add    %ecx,%eax
f01057b9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01057bc:	39 d7                	cmp    %edx,%edi
f01057be:	75 f4                	jne    f01057b4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01057c0:	84 c0                	test   %al,%al
f01057c2:	74 0e                	je     f01057d2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01057c4:	83 c3 10             	add    $0x10,%ebx
f01057c7:	39 f3                	cmp    %esi,%ebx
f01057c9:	72 cd                	jb     f0105798 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01057cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01057d0:	eb 02                	jmp    f01057d4 <mpsearch1+0x91>
f01057d2:	89 d8                	mov    %ebx,%eax
}
f01057d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01057d7:	5b                   	pop    %ebx
f01057d8:	5e                   	pop    %esi
f01057d9:	5f                   	pop    %edi
f01057da:	5d                   	pop    %ebp
f01057db:	c3                   	ret    

f01057dc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01057dc:	55                   	push   %ebp
f01057dd:	89 e5                	mov    %esp,%ebp
f01057df:	57                   	push   %edi
f01057e0:	56                   	push   %esi
f01057e1:	53                   	push   %ebx
f01057e2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01057e5:	c7 05 c0 03 23 f0 20 	movl   $0xf0230020,0xf02303c0
f01057ec:	00 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01057ef:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f01057f6:	75 16                	jne    f010580e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01057f8:	68 00 04 00 00       	push   $0x400
f01057fd:	68 a4 61 10 f0       	push   $0xf01061a4
f0105802:	6a 6f                	push   $0x6f
f0105804:	68 01 7d 10 f0       	push   $0xf0107d01
f0105809:	e8 32 a8 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010580e:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105815:	85 c0                	test   %eax,%eax
f0105817:	74 16                	je     f010582f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105819:	c1 e0 04             	shl    $0x4,%eax
f010581c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105821:	e8 1d ff ff ff       	call   f0105743 <mpsearch1>
f0105826:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105829:	85 c0                	test   %eax,%eax
f010582b:	75 3c                	jne    f0105869 <mp_init+0x8d>
f010582d:	eb 20                	jmp    f010584f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010582f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105836:	c1 e0 0a             	shl    $0xa,%eax
f0105839:	2d 00 04 00 00       	sub    $0x400,%eax
f010583e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105843:	e8 fb fe ff ff       	call   f0105743 <mpsearch1>
f0105848:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010584b:	85 c0                	test   %eax,%eax
f010584d:	75 1a                	jne    f0105869 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010584f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105854:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105859:	e8 e5 fe ff ff       	call   f0105743 <mpsearch1>
f010585e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105861:	85 c0                	test   %eax,%eax
f0105863:	0f 84 5d 02 00 00    	je     f0105ac6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105869:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010586c:	8b 70 04             	mov    0x4(%eax),%esi
f010586f:	85 f6                	test   %esi,%esi
f0105871:	74 06                	je     f0105879 <mp_init+0x9d>
f0105873:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105877:	74 15                	je     f010588e <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105879:	83 ec 0c             	sub    $0xc,%esp
f010587c:	68 74 7b 10 f0       	push   $0xf0107b74
f0105881:	e8 1d de ff ff       	call   f01036a3 <cprintf>
f0105886:	83 c4 10             	add    $0x10,%esp
f0105889:	e9 38 02 00 00       	jmp    f0105ac6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010588e:	89 f0                	mov    %esi,%eax
f0105890:	c1 e8 0c             	shr    $0xc,%eax
f0105893:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0105899:	72 15                	jb     f01058b0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010589b:	56                   	push   %esi
f010589c:	68 a4 61 10 f0       	push   $0xf01061a4
f01058a1:	68 90 00 00 00       	push   $0x90
f01058a6:	68 01 7d 10 f0       	push   $0xf0107d01
f01058ab:	e8 90 a7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01058b0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01058b6:	83 ec 04             	sub    $0x4,%esp
f01058b9:	6a 04                	push   $0x4
f01058bb:	68 16 7d 10 f0       	push   $0xf0107d16
f01058c0:	53                   	push   %ebx
f01058c1:	e8 c7 fc ff ff       	call   f010558d <memcmp>
f01058c6:	83 c4 10             	add    $0x10,%esp
f01058c9:	85 c0                	test   %eax,%eax
f01058cb:	74 15                	je     f01058e2 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01058cd:	83 ec 0c             	sub    $0xc,%esp
f01058d0:	68 a4 7b 10 f0       	push   $0xf0107ba4
f01058d5:	e8 c9 dd ff ff       	call   f01036a3 <cprintf>
f01058da:	83 c4 10             	add    $0x10,%esp
f01058dd:	e9 e4 01 00 00       	jmp    f0105ac6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01058e2:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01058e6:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01058ea:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01058ed:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01058f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01058f7:	eb 0d                	jmp    f0105906 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01058f9:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105900:	f0 
f0105901:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105903:	83 c0 01             	add    $0x1,%eax
f0105906:	39 c7                	cmp    %eax,%edi
f0105908:	75 ef                	jne    f01058f9 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010590a:	84 d2                	test   %dl,%dl
f010590c:	74 15                	je     f0105923 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010590e:	83 ec 0c             	sub    $0xc,%esp
f0105911:	68 d8 7b 10 f0       	push   $0xf0107bd8
f0105916:	e8 88 dd ff ff       	call   f01036a3 <cprintf>
f010591b:	83 c4 10             	add    $0x10,%esp
f010591e:	e9 a3 01 00 00       	jmp    f0105ac6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105923:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105927:	3c 01                	cmp    $0x1,%al
f0105929:	74 1d                	je     f0105948 <mp_init+0x16c>
f010592b:	3c 04                	cmp    $0x4,%al
f010592d:	74 19                	je     f0105948 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010592f:	83 ec 08             	sub    $0x8,%esp
f0105932:	0f b6 c0             	movzbl %al,%eax
f0105935:	50                   	push   %eax
f0105936:	68 fc 7b 10 f0       	push   $0xf0107bfc
f010593b:	e8 63 dd ff ff       	call   f01036a3 <cprintf>
f0105940:	83 c4 10             	add    $0x10,%esp
f0105943:	e9 7e 01 00 00       	jmp    f0105ac6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105948:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010594c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105950:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105955:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010595a:	01 ce                	add    %ecx,%esi
f010595c:	eb 0d                	jmp    f010596b <mp_init+0x18f>
f010595e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105965:	f0 
f0105966:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105968:	83 c0 01             	add    $0x1,%eax
f010596b:	39 c7                	cmp    %eax,%edi
f010596d:	75 ef                	jne    f010595e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010596f:	89 d0                	mov    %edx,%eax
f0105971:	02 43 2a             	add    0x2a(%ebx),%al
f0105974:	74 15                	je     f010598b <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105976:	83 ec 0c             	sub    $0xc,%esp
f0105979:	68 1c 7c 10 f0       	push   $0xf0107c1c
f010597e:	e8 20 dd ff ff       	call   f01036a3 <cprintf>
f0105983:	83 c4 10             	add    $0x10,%esp
f0105986:	e9 3b 01 00 00       	jmp    f0105ac6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010598b:	85 db                	test   %ebx,%ebx
f010598d:	0f 84 33 01 00 00    	je     f0105ac6 <mp_init+0x2ea>
		return;
	ismp = 1;
f0105993:	c7 05 00 00 23 f0 01 	movl   $0x1,0xf0230000
f010599a:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010599d:	8b 43 24             	mov    0x24(%ebx),%eax
f01059a0:	a3 00 10 27 f0       	mov    %eax,0xf0271000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01059a5:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01059a8:	be 00 00 00 00       	mov    $0x0,%esi
f01059ad:	e9 85 00 00 00       	jmp    f0105a37 <mp_init+0x25b>
		switch (*p) {
f01059b2:	0f b6 07             	movzbl (%edi),%eax
f01059b5:	84 c0                	test   %al,%al
f01059b7:	74 06                	je     f01059bf <mp_init+0x1e3>
f01059b9:	3c 04                	cmp    $0x4,%al
f01059bb:	77 55                	ja     f0105a12 <mp_init+0x236>
f01059bd:	eb 4e                	jmp    f0105a0d <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01059bf:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01059c3:	74 11                	je     f01059d6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01059c5:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f01059cc:	05 20 00 23 f0       	add    $0xf0230020,%eax
f01059d1:	a3 c0 03 23 f0       	mov    %eax,0xf02303c0
			if (ncpu < NCPU) {
f01059d6:	a1 c4 03 23 f0       	mov    0xf02303c4,%eax
f01059db:	83 f8 07             	cmp    $0x7,%eax
f01059de:	7f 13                	jg     f01059f3 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01059e0:	6b d0 74             	imul   $0x74,%eax,%edx
f01059e3:	88 82 20 00 23 f0    	mov    %al,-0xfdcffe0(%edx)
				ncpu++;
f01059e9:	83 c0 01             	add    $0x1,%eax
f01059ec:	a3 c4 03 23 f0       	mov    %eax,0xf02303c4
f01059f1:	eb 15                	jmp    f0105a08 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01059f3:	83 ec 08             	sub    $0x8,%esp
f01059f6:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01059fa:	50                   	push   %eax
f01059fb:	68 4c 7c 10 f0       	push   $0xf0107c4c
f0105a00:	e8 9e dc ff ff       	call   f01036a3 <cprintf>
f0105a05:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105a08:	83 c7 14             	add    $0x14,%edi
			continue;
f0105a0b:	eb 27                	jmp    f0105a34 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105a0d:	83 c7 08             	add    $0x8,%edi
			continue;
f0105a10:	eb 22                	jmp    f0105a34 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105a12:	83 ec 08             	sub    $0x8,%esp
f0105a15:	0f b6 c0             	movzbl %al,%eax
f0105a18:	50                   	push   %eax
f0105a19:	68 74 7c 10 f0       	push   $0xf0107c74
f0105a1e:	e8 80 dc ff ff       	call   f01036a3 <cprintf>
			ismp = 0;
f0105a23:	c7 05 00 00 23 f0 00 	movl   $0x0,0xf0230000
f0105a2a:	00 00 00 
			i = conf->entry;
f0105a2d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105a31:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105a34:	83 c6 01             	add    $0x1,%esi
f0105a37:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105a3b:	39 c6                	cmp    %eax,%esi
f0105a3d:	0f 82 6f ff ff ff    	jb     f01059b2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105a43:	a1 c0 03 23 f0       	mov    0xf02303c0,%eax
f0105a48:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105a4f:	83 3d 00 00 23 f0 00 	cmpl   $0x0,0xf0230000
f0105a56:	75 26                	jne    f0105a7e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105a58:	c7 05 c4 03 23 f0 01 	movl   $0x1,0xf02303c4
f0105a5f:	00 00 00 
		lapicaddr = 0;
f0105a62:	c7 05 00 10 27 f0 00 	movl   $0x0,0xf0271000
f0105a69:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105a6c:	83 ec 0c             	sub    $0xc,%esp
f0105a6f:	68 94 7c 10 f0       	push   $0xf0107c94
f0105a74:	e8 2a dc ff ff       	call   f01036a3 <cprintf>
		return;
f0105a79:	83 c4 10             	add    $0x10,%esp
f0105a7c:	eb 48                	jmp    f0105ac6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105a7e:	83 ec 04             	sub    $0x4,%esp
f0105a81:	ff 35 c4 03 23 f0    	pushl  0xf02303c4
f0105a87:	0f b6 00             	movzbl (%eax),%eax
f0105a8a:	50                   	push   %eax
f0105a8b:	68 1b 7d 10 f0       	push   $0xf0107d1b
f0105a90:	e8 0e dc ff ff       	call   f01036a3 <cprintf>

	if (mp->imcrp) {
f0105a95:	83 c4 10             	add    $0x10,%esp
f0105a98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105a9b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105a9f:	74 25                	je     f0105ac6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105aa1:	83 ec 0c             	sub    $0xc,%esp
f0105aa4:	68 c0 7c 10 f0       	push   $0xf0107cc0
f0105aa9:	e8 f5 db ff ff       	call   f01036a3 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105aae:	ba 22 00 00 00       	mov    $0x22,%edx
f0105ab3:	b8 70 00 00 00       	mov    $0x70,%eax
f0105ab8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105ab9:	ba 23 00 00 00       	mov    $0x23,%edx
f0105abe:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105abf:	83 c8 01             	or     $0x1,%eax
f0105ac2:	ee                   	out    %al,(%dx)
f0105ac3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105ac6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105ac9:	5b                   	pop    %ebx
f0105aca:	5e                   	pop    %esi
f0105acb:	5f                   	pop    %edi
f0105acc:	5d                   	pop    %ebp
f0105acd:	c3                   	ret    

f0105ace <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105ace:	55                   	push   %ebp
f0105acf:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105ad1:	8b 0d 04 10 27 f0    	mov    0xf0271004,%ecx
f0105ad7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105ada:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105adc:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105ae1:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105ae4:	5d                   	pop    %ebp
f0105ae5:	c3                   	ret    

f0105ae6 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105ae6:	55                   	push   %ebp
f0105ae7:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105ae9:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105aee:	85 c0                	test   %eax,%eax
f0105af0:	74 08                	je     f0105afa <cpunum+0x14>
		return lapic[ID] >> 24;
f0105af2:	8b 40 20             	mov    0x20(%eax),%eax
f0105af5:	c1 e8 18             	shr    $0x18,%eax
f0105af8:	eb 05                	jmp    f0105aff <cpunum+0x19>
	return 0;
f0105afa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105aff:	5d                   	pop    %ebp
f0105b00:	c3                   	ret    

f0105b01 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105b01:	a1 00 10 27 f0       	mov    0xf0271000,%eax
f0105b06:	85 c0                	test   %eax,%eax
f0105b08:	0f 84 21 01 00 00    	je     f0105c2f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105b0e:	55                   	push   %ebp
f0105b0f:	89 e5                	mov    %esp,%ebp
f0105b11:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105b14:	68 00 10 00 00       	push   $0x1000
f0105b19:	50                   	push   %eax
f0105b1a:	e8 21 b8 ff ff       	call   f0101340 <mmio_map_region>
f0105b1f:	a3 04 10 27 f0       	mov    %eax,0xf0271004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105b24:	ba 27 01 00 00       	mov    $0x127,%edx
f0105b29:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105b2e:	e8 9b ff ff ff       	call   f0105ace <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105b33:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105b38:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105b3d:	e8 8c ff ff ff       	call   f0105ace <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105b42:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105b47:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105b4c:	e8 7d ff ff ff       	call   f0105ace <lapicw>
	lapicw(TICR, 10000000); 
f0105b51:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105b56:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105b5b:	e8 6e ff ff ff       	call   f0105ace <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105b60:	e8 81 ff ff ff       	call   f0105ae6 <cpunum>
f0105b65:	6b c0 74             	imul   $0x74,%eax,%eax
f0105b68:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105b6d:	83 c4 10             	add    $0x10,%esp
f0105b70:	39 05 c0 03 23 f0    	cmp    %eax,0xf02303c0
f0105b76:	74 0f                	je     f0105b87 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105b78:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b7d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105b82:	e8 47 ff ff ff       	call   f0105ace <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105b87:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b8c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105b91:	e8 38 ff ff ff       	call   f0105ace <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105b96:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105b9b:	8b 40 30             	mov    0x30(%eax),%eax
f0105b9e:	c1 e8 10             	shr    $0x10,%eax
f0105ba1:	3c 03                	cmp    $0x3,%al
f0105ba3:	76 0f                	jbe    f0105bb4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105ba5:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105baa:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105baf:	e8 1a ff ff ff       	call   f0105ace <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105bb4:	ba 33 00 00 00       	mov    $0x33,%edx
f0105bb9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105bbe:	e8 0b ff ff ff       	call   f0105ace <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105bc3:	ba 00 00 00 00       	mov    $0x0,%edx
f0105bc8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105bcd:	e8 fc fe ff ff       	call   f0105ace <lapicw>
	lapicw(ESR, 0);
f0105bd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0105bd7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105bdc:	e8 ed fe ff ff       	call   f0105ace <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105be1:	ba 00 00 00 00       	mov    $0x0,%edx
f0105be6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105beb:	e8 de fe ff ff       	call   f0105ace <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105bf0:	ba 00 00 00 00       	mov    $0x0,%edx
f0105bf5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bfa:	e8 cf fe ff ff       	call   f0105ace <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105bff:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105c04:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c09:	e8 c0 fe ff ff       	call   f0105ace <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105c0e:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105c14:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c1a:	f6 c4 10             	test   $0x10,%ah
f0105c1d:	75 f5                	jne    f0105c14 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105c1f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c24:	b8 20 00 00 00       	mov    $0x20,%eax
f0105c29:	e8 a0 fe ff ff       	call   f0105ace <lapicw>
}
f0105c2e:	c9                   	leave  
f0105c2f:	f3 c3                	repz ret 

f0105c31 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105c31:	83 3d 04 10 27 f0 00 	cmpl   $0x0,0xf0271004
f0105c38:	74 13                	je     f0105c4d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105c3a:	55                   	push   %ebp
f0105c3b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105c3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105c42:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105c47:	e8 82 fe ff ff       	call   f0105ace <lapicw>
}
f0105c4c:	5d                   	pop    %ebp
f0105c4d:	f3 c3                	repz ret 

f0105c4f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105c4f:	55                   	push   %ebp
f0105c50:	89 e5                	mov    %esp,%ebp
f0105c52:	56                   	push   %esi
f0105c53:	53                   	push   %ebx
f0105c54:	8b 75 08             	mov    0x8(%ebp),%esi
f0105c57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105c5a:	ba 70 00 00 00       	mov    $0x70,%edx
f0105c5f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105c64:	ee                   	out    %al,(%dx)
f0105c65:	ba 71 00 00 00       	mov    $0x71,%edx
f0105c6a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105c6f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105c70:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105c77:	75 19                	jne    f0105c92 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105c79:	68 67 04 00 00       	push   $0x467
f0105c7e:	68 a4 61 10 f0       	push   $0xf01061a4
f0105c83:	68 98 00 00 00       	push   $0x98
f0105c88:	68 38 7d 10 f0       	push   $0xf0107d38
f0105c8d:	e8 ae a3 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105c92:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105c99:	00 00 
	wrv[1] = addr >> 4;
f0105c9b:	89 d8                	mov    %ebx,%eax
f0105c9d:	c1 e8 04             	shr    $0x4,%eax
f0105ca0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105ca6:	c1 e6 18             	shl    $0x18,%esi
f0105ca9:	89 f2                	mov    %esi,%edx
f0105cab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105cb0:	e8 19 fe ff ff       	call   f0105ace <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105cb5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105cba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105cbf:	e8 0a fe ff ff       	call   f0105ace <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105cc4:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105cc9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105cce:	e8 fb fd ff ff       	call   f0105ace <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105cd3:	c1 eb 0c             	shr    $0xc,%ebx
f0105cd6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105cd9:	89 f2                	mov    %esi,%edx
f0105cdb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105ce0:	e8 e9 fd ff ff       	call   f0105ace <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105ce5:	89 da                	mov    %ebx,%edx
f0105ce7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105cec:	e8 dd fd ff ff       	call   f0105ace <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105cf1:	89 f2                	mov    %esi,%edx
f0105cf3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105cf8:	e8 d1 fd ff ff       	call   f0105ace <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105cfd:	89 da                	mov    %ebx,%edx
f0105cff:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d04:	e8 c5 fd ff ff       	call   f0105ace <lapicw>
		microdelay(200);
	}
}
f0105d09:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105d0c:	5b                   	pop    %ebx
f0105d0d:	5e                   	pop    %esi
f0105d0e:	5d                   	pop    %ebp
f0105d0f:	c3                   	ret    

f0105d10 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105d10:	55                   	push   %ebp
f0105d11:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105d13:	8b 55 08             	mov    0x8(%ebp),%edx
f0105d16:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105d1c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d21:	e8 a8 fd ff ff       	call   f0105ace <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105d26:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105d2c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105d32:	f6 c4 10             	test   $0x10,%ah
f0105d35:	75 f5                	jne    f0105d2c <lapic_ipi+0x1c>
		;
}
f0105d37:	5d                   	pop    %ebp
f0105d38:	c3                   	ret    

f0105d39 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105d39:	55                   	push   %ebp
f0105d3a:	89 e5                	mov    %esp,%ebp
f0105d3c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105d3f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105d45:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105d48:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105d4b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105d52:	5d                   	pop    %ebp
f0105d53:	c3                   	ret    

f0105d54 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105d54:	55                   	push   %ebp
f0105d55:	89 e5                	mov    %esp,%ebp
f0105d57:	56                   	push   %esi
f0105d58:	53                   	push   %ebx
f0105d59:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105d5c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105d5f:	74 14                	je     f0105d75 <spin_lock+0x21>
f0105d61:	8b 73 08             	mov    0x8(%ebx),%esi
f0105d64:	e8 7d fd ff ff       	call   f0105ae6 <cpunum>
f0105d69:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d6c:	05 20 00 23 f0       	add    $0xf0230020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105d71:	39 c6                	cmp    %eax,%esi
f0105d73:	74 07                	je     f0105d7c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105d75:	ba 01 00 00 00       	mov    $0x1,%edx
f0105d7a:	eb 20                	jmp    f0105d9c <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105d7c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105d7f:	e8 62 fd ff ff       	call   f0105ae6 <cpunum>
f0105d84:	83 ec 0c             	sub    $0xc,%esp
f0105d87:	53                   	push   %ebx
f0105d88:	50                   	push   %eax
f0105d89:	68 48 7d 10 f0       	push   $0xf0107d48
f0105d8e:	6a 41                	push   $0x41
f0105d90:	68 ac 7d 10 f0       	push   $0xf0107dac
f0105d95:	e8 a6 a2 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105d9a:	f3 90                	pause  
f0105d9c:	89 d0                	mov    %edx,%eax
f0105d9e:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105da1:	85 c0                	test   %eax,%eax
f0105da3:	75 f5                	jne    f0105d9a <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105da5:	e8 3c fd ff ff       	call   f0105ae6 <cpunum>
f0105daa:	6b c0 74             	imul   $0x74,%eax,%eax
f0105dad:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105db2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105db5:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105db8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105dba:	b8 00 00 00 00       	mov    $0x0,%eax
f0105dbf:	eb 0b                	jmp    f0105dcc <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105dc1:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105dc4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105dc7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105dc9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105dcc:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105dd2:	76 11                	jbe    f0105de5 <spin_lock+0x91>
f0105dd4:	83 f8 09             	cmp    $0x9,%eax
f0105dd7:	7e e8                	jle    f0105dc1 <spin_lock+0x6d>
f0105dd9:	eb 0a                	jmp    f0105de5 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105ddb:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105de2:	83 c0 01             	add    $0x1,%eax
f0105de5:	83 f8 09             	cmp    $0x9,%eax
f0105de8:	7e f1                	jle    f0105ddb <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105dea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105ded:	5b                   	pop    %ebx
f0105dee:	5e                   	pop    %esi
f0105def:	5d                   	pop    %ebp
f0105df0:	c3                   	ret    

f0105df1 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105df1:	55                   	push   %ebp
f0105df2:	89 e5                	mov    %esp,%ebp
f0105df4:	57                   	push   %edi
f0105df5:	56                   	push   %esi
f0105df6:	53                   	push   %ebx
f0105df7:	83 ec 4c             	sub    $0x4c,%esp
f0105dfa:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105dfd:	83 3e 00             	cmpl   $0x0,(%esi)
f0105e00:	74 18                	je     f0105e1a <spin_unlock+0x29>
f0105e02:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105e05:	e8 dc fc ff ff       	call   f0105ae6 <cpunum>
f0105e0a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105e0d:	05 20 00 23 f0       	add    $0xf0230020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105e12:	39 c3                	cmp    %eax,%ebx
f0105e14:	0f 84 a5 00 00 00    	je     f0105ebf <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105e1a:	83 ec 04             	sub    $0x4,%esp
f0105e1d:	6a 28                	push   $0x28
f0105e1f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105e22:	50                   	push   %eax
f0105e23:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105e26:	53                   	push   %ebx
f0105e27:	e8 e6 f6 ff ff       	call   f0105512 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105e2c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105e2f:	0f b6 38             	movzbl (%eax),%edi
f0105e32:	8b 76 04             	mov    0x4(%esi),%esi
f0105e35:	e8 ac fc ff ff       	call   f0105ae6 <cpunum>
f0105e3a:	57                   	push   %edi
f0105e3b:	56                   	push   %esi
f0105e3c:	50                   	push   %eax
f0105e3d:	68 74 7d 10 f0       	push   $0xf0107d74
f0105e42:	e8 5c d8 ff ff       	call   f01036a3 <cprintf>
f0105e47:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105e4a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105e4d:	eb 54                	jmp    f0105ea3 <spin_unlock+0xb2>
f0105e4f:	83 ec 08             	sub    $0x8,%esp
f0105e52:	57                   	push   %edi
f0105e53:	50                   	push   %eax
f0105e54:	e8 fa eb ff ff       	call   f0104a53 <debuginfo_eip>
f0105e59:	83 c4 10             	add    $0x10,%esp
f0105e5c:	85 c0                	test   %eax,%eax
f0105e5e:	78 27                	js     f0105e87 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105e60:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105e62:	83 ec 04             	sub    $0x4,%esp
f0105e65:	89 c2                	mov    %eax,%edx
f0105e67:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105e6a:	52                   	push   %edx
f0105e6b:	ff 75 b0             	pushl  -0x50(%ebp)
f0105e6e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105e71:	ff 75 ac             	pushl  -0x54(%ebp)
f0105e74:	ff 75 a8             	pushl  -0x58(%ebp)
f0105e77:	50                   	push   %eax
f0105e78:	68 bc 7d 10 f0       	push   $0xf0107dbc
f0105e7d:	e8 21 d8 ff ff       	call   f01036a3 <cprintf>
f0105e82:	83 c4 20             	add    $0x20,%esp
f0105e85:	eb 12                	jmp    f0105e99 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105e87:	83 ec 08             	sub    $0x8,%esp
f0105e8a:	ff 36                	pushl  (%esi)
f0105e8c:	68 d3 7d 10 f0       	push   $0xf0107dd3
f0105e91:	e8 0d d8 ff ff       	call   f01036a3 <cprintf>
f0105e96:	83 c4 10             	add    $0x10,%esp
f0105e99:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105e9c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105e9f:	39 c3                	cmp    %eax,%ebx
f0105ea1:	74 08                	je     f0105eab <spin_unlock+0xba>
f0105ea3:	89 de                	mov    %ebx,%esi
f0105ea5:	8b 03                	mov    (%ebx),%eax
f0105ea7:	85 c0                	test   %eax,%eax
f0105ea9:	75 a4                	jne    f0105e4f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105eab:	83 ec 04             	sub    $0x4,%esp
f0105eae:	68 db 7d 10 f0       	push   $0xf0107ddb
f0105eb3:	6a 67                	push   $0x67
f0105eb5:	68 ac 7d 10 f0       	push   $0xf0107dac
f0105eba:	e8 81 a1 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105ebf:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105ec6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105ecd:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ed2:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105ed5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105ed8:	5b                   	pop    %ebx
f0105ed9:	5e                   	pop    %esi
f0105eda:	5f                   	pop    %edi
f0105edb:	5d                   	pop    %ebp
f0105edc:	c3                   	ret    
f0105edd:	66 90                	xchg   %ax,%ax
f0105edf:	90                   	nop

f0105ee0 <__udivdi3>:
f0105ee0:	55                   	push   %ebp
f0105ee1:	57                   	push   %edi
f0105ee2:	56                   	push   %esi
f0105ee3:	53                   	push   %ebx
f0105ee4:	83 ec 1c             	sub    $0x1c,%esp
f0105ee7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105eeb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105eef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105ef3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105ef7:	85 f6                	test   %esi,%esi
f0105ef9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105efd:	89 ca                	mov    %ecx,%edx
f0105eff:	89 f8                	mov    %edi,%eax
f0105f01:	75 3d                	jne    f0105f40 <__udivdi3+0x60>
f0105f03:	39 cf                	cmp    %ecx,%edi
f0105f05:	0f 87 c5 00 00 00    	ja     f0105fd0 <__udivdi3+0xf0>
f0105f0b:	85 ff                	test   %edi,%edi
f0105f0d:	89 fd                	mov    %edi,%ebp
f0105f0f:	75 0b                	jne    f0105f1c <__udivdi3+0x3c>
f0105f11:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f16:	31 d2                	xor    %edx,%edx
f0105f18:	f7 f7                	div    %edi
f0105f1a:	89 c5                	mov    %eax,%ebp
f0105f1c:	89 c8                	mov    %ecx,%eax
f0105f1e:	31 d2                	xor    %edx,%edx
f0105f20:	f7 f5                	div    %ebp
f0105f22:	89 c1                	mov    %eax,%ecx
f0105f24:	89 d8                	mov    %ebx,%eax
f0105f26:	89 cf                	mov    %ecx,%edi
f0105f28:	f7 f5                	div    %ebp
f0105f2a:	89 c3                	mov    %eax,%ebx
f0105f2c:	89 d8                	mov    %ebx,%eax
f0105f2e:	89 fa                	mov    %edi,%edx
f0105f30:	83 c4 1c             	add    $0x1c,%esp
f0105f33:	5b                   	pop    %ebx
f0105f34:	5e                   	pop    %esi
f0105f35:	5f                   	pop    %edi
f0105f36:	5d                   	pop    %ebp
f0105f37:	c3                   	ret    
f0105f38:	90                   	nop
f0105f39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105f40:	39 ce                	cmp    %ecx,%esi
f0105f42:	77 74                	ja     f0105fb8 <__udivdi3+0xd8>
f0105f44:	0f bd fe             	bsr    %esi,%edi
f0105f47:	83 f7 1f             	xor    $0x1f,%edi
f0105f4a:	0f 84 98 00 00 00    	je     f0105fe8 <__udivdi3+0x108>
f0105f50:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105f55:	89 f9                	mov    %edi,%ecx
f0105f57:	89 c5                	mov    %eax,%ebp
f0105f59:	29 fb                	sub    %edi,%ebx
f0105f5b:	d3 e6                	shl    %cl,%esi
f0105f5d:	89 d9                	mov    %ebx,%ecx
f0105f5f:	d3 ed                	shr    %cl,%ebp
f0105f61:	89 f9                	mov    %edi,%ecx
f0105f63:	d3 e0                	shl    %cl,%eax
f0105f65:	09 ee                	or     %ebp,%esi
f0105f67:	89 d9                	mov    %ebx,%ecx
f0105f69:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105f6d:	89 d5                	mov    %edx,%ebp
f0105f6f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105f73:	d3 ed                	shr    %cl,%ebp
f0105f75:	89 f9                	mov    %edi,%ecx
f0105f77:	d3 e2                	shl    %cl,%edx
f0105f79:	89 d9                	mov    %ebx,%ecx
f0105f7b:	d3 e8                	shr    %cl,%eax
f0105f7d:	09 c2                	or     %eax,%edx
f0105f7f:	89 d0                	mov    %edx,%eax
f0105f81:	89 ea                	mov    %ebp,%edx
f0105f83:	f7 f6                	div    %esi
f0105f85:	89 d5                	mov    %edx,%ebp
f0105f87:	89 c3                	mov    %eax,%ebx
f0105f89:	f7 64 24 0c          	mull   0xc(%esp)
f0105f8d:	39 d5                	cmp    %edx,%ebp
f0105f8f:	72 10                	jb     f0105fa1 <__udivdi3+0xc1>
f0105f91:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105f95:	89 f9                	mov    %edi,%ecx
f0105f97:	d3 e6                	shl    %cl,%esi
f0105f99:	39 c6                	cmp    %eax,%esi
f0105f9b:	73 07                	jae    f0105fa4 <__udivdi3+0xc4>
f0105f9d:	39 d5                	cmp    %edx,%ebp
f0105f9f:	75 03                	jne    f0105fa4 <__udivdi3+0xc4>
f0105fa1:	83 eb 01             	sub    $0x1,%ebx
f0105fa4:	31 ff                	xor    %edi,%edi
f0105fa6:	89 d8                	mov    %ebx,%eax
f0105fa8:	89 fa                	mov    %edi,%edx
f0105faa:	83 c4 1c             	add    $0x1c,%esp
f0105fad:	5b                   	pop    %ebx
f0105fae:	5e                   	pop    %esi
f0105faf:	5f                   	pop    %edi
f0105fb0:	5d                   	pop    %ebp
f0105fb1:	c3                   	ret    
f0105fb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105fb8:	31 ff                	xor    %edi,%edi
f0105fba:	31 db                	xor    %ebx,%ebx
f0105fbc:	89 d8                	mov    %ebx,%eax
f0105fbe:	89 fa                	mov    %edi,%edx
f0105fc0:	83 c4 1c             	add    $0x1c,%esp
f0105fc3:	5b                   	pop    %ebx
f0105fc4:	5e                   	pop    %esi
f0105fc5:	5f                   	pop    %edi
f0105fc6:	5d                   	pop    %ebp
f0105fc7:	c3                   	ret    
f0105fc8:	90                   	nop
f0105fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105fd0:	89 d8                	mov    %ebx,%eax
f0105fd2:	f7 f7                	div    %edi
f0105fd4:	31 ff                	xor    %edi,%edi
f0105fd6:	89 c3                	mov    %eax,%ebx
f0105fd8:	89 d8                	mov    %ebx,%eax
f0105fda:	89 fa                	mov    %edi,%edx
f0105fdc:	83 c4 1c             	add    $0x1c,%esp
f0105fdf:	5b                   	pop    %ebx
f0105fe0:	5e                   	pop    %esi
f0105fe1:	5f                   	pop    %edi
f0105fe2:	5d                   	pop    %ebp
f0105fe3:	c3                   	ret    
f0105fe4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fe8:	39 ce                	cmp    %ecx,%esi
f0105fea:	72 0c                	jb     f0105ff8 <__udivdi3+0x118>
f0105fec:	31 db                	xor    %ebx,%ebx
f0105fee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105ff2:	0f 87 34 ff ff ff    	ja     f0105f2c <__udivdi3+0x4c>
f0105ff8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105ffd:	e9 2a ff ff ff       	jmp    f0105f2c <__udivdi3+0x4c>
f0106002:	66 90                	xchg   %ax,%ax
f0106004:	66 90                	xchg   %ax,%ax
f0106006:	66 90                	xchg   %ax,%ax
f0106008:	66 90                	xchg   %ax,%ax
f010600a:	66 90                	xchg   %ax,%ax
f010600c:	66 90                	xchg   %ax,%ax
f010600e:	66 90                	xchg   %ax,%ax

f0106010 <__umoddi3>:
f0106010:	55                   	push   %ebp
f0106011:	57                   	push   %edi
f0106012:	56                   	push   %esi
f0106013:	53                   	push   %ebx
f0106014:	83 ec 1c             	sub    $0x1c,%esp
f0106017:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010601b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010601f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106023:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106027:	85 d2                	test   %edx,%edx
f0106029:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010602d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106031:	89 f3                	mov    %esi,%ebx
f0106033:	89 3c 24             	mov    %edi,(%esp)
f0106036:	89 74 24 04          	mov    %esi,0x4(%esp)
f010603a:	75 1c                	jne    f0106058 <__umoddi3+0x48>
f010603c:	39 f7                	cmp    %esi,%edi
f010603e:	76 50                	jbe    f0106090 <__umoddi3+0x80>
f0106040:	89 c8                	mov    %ecx,%eax
f0106042:	89 f2                	mov    %esi,%edx
f0106044:	f7 f7                	div    %edi
f0106046:	89 d0                	mov    %edx,%eax
f0106048:	31 d2                	xor    %edx,%edx
f010604a:	83 c4 1c             	add    $0x1c,%esp
f010604d:	5b                   	pop    %ebx
f010604e:	5e                   	pop    %esi
f010604f:	5f                   	pop    %edi
f0106050:	5d                   	pop    %ebp
f0106051:	c3                   	ret    
f0106052:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106058:	39 f2                	cmp    %esi,%edx
f010605a:	89 d0                	mov    %edx,%eax
f010605c:	77 52                	ja     f01060b0 <__umoddi3+0xa0>
f010605e:	0f bd ea             	bsr    %edx,%ebp
f0106061:	83 f5 1f             	xor    $0x1f,%ebp
f0106064:	75 5a                	jne    f01060c0 <__umoddi3+0xb0>
f0106066:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010606a:	0f 82 e0 00 00 00    	jb     f0106150 <__umoddi3+0x140>
f0106070:	39 0c 24             	cmp    %ecx,(%esp)
f0106073:	0f 86 d7 00 00 00    	jbe    f0106150 <__umoddi3+0x140>
f0106079:	8b 44 24 08          	mov    0x8(%esp),%eax
f010607d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106081:	83 c4 1c             	add    $0x1c,%esp
f0106084:	5b                   	pop    %ebx
f0106085:	5e                   	pop    %esi
f0106086:	5f                   	pop    %edi
f0106087:	5d                   	pop    %ebp
f0106088:	c3                   	ret    
f0106089:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106090:	85 ff                	test   %edi,%edi
f0106092:	89 fd                	mov    %edi,%ebp
f0106094:	75 0b                	jne    f01060a1 <__umoddi3+0x91>
f0106096:	b8 01 00 00 00       	mov    $0x1,%eax
f010609b:	31 d2                	xor    %edx,%edx
f010609d:	f7 f7                	div    %edi
f010609f:	89 c5                	mov    %eax,%ebp
f01060a1:	89 f0                	mov    %esi,%eax
f01060a3:	31 d2                	xor    %edx,%edx
f01060a5:	f7 f5                	div    %ebp
f01060a7:	89 c8                	mov    %ecx,%eax
f01060a9:	f7 f5                	div    %ebp
f01060ab:	89 d0                	mov    %edx,%eax
f01060ad:	eb 99                	jmp    f0106048 <__umoddi3+0x38>
f01060af:	90                   	nop
f01060b0:	89 c8                	mov    %ecx,%eax
f01060b2:	89 f2                	mov    %esi,%edx
f01060b4:	83 c4 1c             	add    $0x1c,%esp
f01060b7:	5b                   	pop    %ebx
f01060b8:	5e                   	pop    %esi
f01060b9:	5f                   	pop    %edi
f01060ba:	5d                   	pop    %ebp
f01060bb:	c3                   	ret    
f01060bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01060c0:	8b 34 24             	mov    (%esp),%esi
f01060c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01060c8:	89 e9                	mov    %ebp,%ecx
f01060ca:	29 ef                	sub    %ebp,%edi
f01060cc:	d3 e0                	shl    %cl,%eax
f01060ce:	89 f9                	mov    %edi,%ecx
f01060d0:	89 f2                	mov    %esi,%edx
f01060d2:	d3 ea                	shr    %cl,%edx
f01060d4:	89 e9                	mov    %ebp,%ecx
f01060d6:	09 c2                	or     %eax,%edx
f01060d8:	89 d8                	mov    %ebx,%eax
f01060da:	89 14 24             	mov    %edx,(%esp)
f01060dd:	89 f2                	mov    %esi,%edx
f01060df:	d3 e2                	shl    %cl,%edx
f01060e1:	89 f9                	mov    %edi,%ecx
f01060e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01060e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01060eb:	d3 e8                	shr    %cl,%eax
f01060ed:	89 e9                	mov    %ebp,%ecx
f01060ef:	89 c6                	mov    %eax,%esi
f01060f1:	d3 e3                	shl    %cl,%ebx
f01060f3:	89 f9                	mov    %edi,%ecx
f01060f5:	89 d0                	mov    %edx,%eax
f01060f7:	d3 e8                	shr    %cl,%eax
f01060f9:	89 e9                	mov    %ebp,%ecx
f01060fb:	09 d8                	or     %ebx,%eax
f01060fd:	89 d3                	mov    %edx,%ebx
f01060ff:	89 f2                	mov    %esi,%edx
f0106101:	f7 34 24             	divl   (%esp)
f0106104:	89 d6                	mov    %edx,%esi
f0106106:	d3 e3                	shl    %cl,%ebx
f0106108:	f7 64 24 04          	mull   0x4(%esp)
f010610c:	39 d6                	cmp    %edx,%esi
f010610e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106112:	89 d1                	mov    %edx,%ecx
f0106114:	89 c3                	mov    %eax,%ebx
f0106116:	72 08                	jb     f0106120 <__umoddi3+0x110>
f0106118:	75 11                	jne    f010612b <__umoddi3+0x11b>
f010611a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010611e:	73 0b                	jae    f010612b <__umoddi3+0x11b>
f0106120:	2b 44 24 04          	sub    0x4(%esp),%eax
f0106124:	1b 14 24             	sbb    (%esp),%edx
f0106127:	89 d1                	mov    %edx,%ecx
f0106129:	89 c3                	mov    %eax,%ebx
f010612b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010612f:	29 da                	sub    %ebx,%edx
f0106131:	19 ce                	sbb    %ecx,%esi
f0106133:	89 f9                	mov    %edi,%ecx
f0106135:	89 f0                	mov    %esi,%eax
f0106137:	d3 e0                	shl    %cl,%eax
f0106139:	89 e9                	mov    %ebp,%ecx
f010613b:	d3 ea                	shr    %cl,%edx
f010613d:	89 e9                	mov    %ebp,%ecx
f010613f:	d3 ee                	shr    %cl,%esi
f0106141:	09 d0                	or     %edx,%eax
f0106143:	89 f2                	mov    %esi,%edx
f0106145:	83 c4 1c             	add    $0x1c,%esp
f0106148:	5b                   	pop    %ebx
f0106149:	5e                   	pop    %esi
f010614a:	5f                   	pop    %edi
f010614b:	5d                   	pop    %ebp
f010614c:	c3                   	ret    
f010614d:	8d 76 00             	lea    0x0(%esi),%esi
f0106150:	29 f9                	sub    %edi,%ecx
f0106152:	19 d6                	sbb    %edx,%esi
f0106154:	89 74 24 04          	mov    %esi,0x4(%esp)
f0106158:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010615c:	e9 18 ff ff ff       	jmp    f0106079 <__umoddi3+0x69>
