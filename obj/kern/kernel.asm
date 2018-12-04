
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
f010005c:	e8 e5 57 00 00       	call   f0105846 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 e0 5e 10 f0       	push   $0xf0105ee0
f010006d:	e8 13 36 00 00       	call   f0103685 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 e3 35 00 00       	call   f010365f <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 9c 62 10 f0 	movl   $0xf010629c,(%esp)
f0100083:	e8 fd 35 00 00       	call   f0103685 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 c3 08 00 00       	call   f0100958 <monitor>
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
f01000b3:	e8 6d 51 00 00       	call   f0105225 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 4c 5f 10 f0       	push   $0xf0105f4c
f01000ca:	e8 b6 35 00 00       	call   f0103685 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 b1 12 00 00       	call   f0101385 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 0f 2e 00 00       	call   f0102ee8 <env_init>
	trap_init();
f01000d9:	e8 9c 36 00 00       	call   f010377a <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 59 54 00 00       	call   f010553c <mp_init>
	lapic_init();
f01000e3:	e8 79 57 00 00       	call   f0105861 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 bf 34 00 00       	call   f01035ac <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 bb 59 00 00       	call   f0105ab4 <spin_lock>
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
f010010a:	68 04 5f 10 f0       	push   $0xf0105f04
f010010f:	6a 56                	push   $0x56
f0100111:	68 67 5f 10 f0       	push   $0xf0105f67
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 a2 54 10 f0       	mov    $0xf01054a2,%eax
f0100123:	2d 28 54 10 f0       	sub    $0xf0105428,%eax
f0100128:	50                   	push   %eax
f0100129:	68 28 54 10 f0       	push   $0xf0105428
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 3a 51 00 00       	call   f0105272 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 00 23 f0       	mov    $0xf0230020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 ff 56 00 00       	call   f0105846 <cpunum>
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
f010017c:	e8 2e 58 00 00       	call   f01059af <lapic_startap>
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
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 1c 07 20 f0       	push   $0xf020071c
f01001a9:	e8 0e 2f 00 00       	call   f01030bc <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 6b 40 00 00       	call   f010421e <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 28 5f 10 f0       	push   $0xf0105f28
f01001cb:	6a 6d                	push   $0x6d
f01001cd:	68 67 5f 10 f0       	push   $0xf0105f67
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 62 56 00 00       	call   f0105846 <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 73 5f 10 f0       	push   $0xf0105f73
f01001ed:	e8 93 34 00 00       	call   f0103685 <cprintf>

	lapic_init();
f01001f2:	e8 6a 56 00 00       	call   f0105861 <lapic_init>
	env_init_percpu();
f01001f7:	e8 bc 2c 00 00       	call   f0102eb8 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 98 34 00 00       	call   f0103699 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 40 56 00 00       	call   f0105846 <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010021f:	e8 90 58 00 00       	call   f0105ab4 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100224:	e8 f5 3f 00 00       	call   f010421e <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 89 5f 10 f0       	push   $0xf0105f89
f010023e:	e8 42 34 00 00       	call   f0103685 <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 10 34 00 00       	call   f010365f <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 9c 62 10 f0 	movl   $0xf010629c,(%esp)
f0100256:	e8 2a 34 00 00       	call   f0103685 <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 f2 22 f0    	mov    0xf022f224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 f2 22 f0    	mov    %edx,0xf022f224
f01002a0:	88 81 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 f2 22 f0 00 	movl   $0x0,0xf022f224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f8 00 00 00    	je     f01003cb <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002d3:	a8 20                	test   $0x20,%al
f01002d5:	0f 85 f6 00 00 00    	jne    f01003d1 <kbd_proc_data+0x10c>
f01002db:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002e3:	3c e0                	cmp    $0xe0,%al
f01002e5:	75 0d                	jne    f01002f4 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002e7:	83 0d 00 f0 22 f0 40 	orl    $0x40,0xf022f000
		return 0;
f01002ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01002f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002f4:	55                   	push   %ebp
f01002f5:	89 e5                	mov    %esp,%ebp
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 36                	jns    f0100335 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002ff:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 00 61 10 f0 	movzbl -0xfef9f00(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 f0 22 f0       	mov    %eax,0xf022f000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 f0 22 f0    	mov    %ecx,0xf022f000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 00 61 10 f0 	movzbl -0xfef9f00(%edx),%eax
f0100358:	0b 05 00 f0 22 f0    	or     0xf022f000,%eax
f010035e:	0f b6 8a 00 60 10 f0 	movzbl -0xfefa000(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 f0 22 f0       	mov    %eax,0xf022f000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d e0 5f 10 f0 	mov    -0xfefa020(,%ecx,4),%ecx
f0100378:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010037c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010037f:	a8 08                	test   $0x8,%al
f0100381:	74 1b                	je     f010039e <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100383:	89 da                	mov    %ebx,%edx
f0100385:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100388:	83 f9 19             	cmp    $0x19,%ecx
f010038b:	77 05                	ja     f0100392 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010038d:	83 eb 20             	sub    $0x20,%ebx
f0100390:	eb 0c                	jmp    f010039e <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100392:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100395:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100398:	83 fa 19             	cmp    $0x19,%edx
f010039b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039e:	f7 d0                	not    %eax
f01003a0:	a8 06                	test   $0x6,%al
f01003a2:	75 33                	jne    f01003d7 <kbd_proc_data+0x112>
f01003a4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003aa:	75 2b                	jne    f01003d7 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ac:	83 ec 0c             	sub    $0xc,%esp
f01003af:	68 a3 5f 10 f0       	push   $0xf0105fa3
f01003b4:	e8 cc 32 00 00       	call   f0103685 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b9:	ba 92 00 00 00       	mov    $0x92,%edx
f01003be:	b8 03 00 00 00       	mov    $0x3,%eax
f01003c3:	ee                   	out    %al,(%dx)
f01003c4:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c7:	89 d8                	mov    %ebx,%eax
f01003c9:	eb 0e                	jmp    f01003d9 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003d0:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003d6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d7:	89 d8                	mov    %ebx,%eax
}
f01003d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003dc:	c9                   	leave  
f01003dd:	c3                   	ret    

f01003de <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003de:	55                   	push   %ebp
f01003df:	89 e5                	mov    %esp,%ebp
f01003e1:	57                   	push   %edi
f01003e2:	56                   	push   %esi
f01003e3:	53                   	push   %ebx
f01003e4:	83 ec 1c             	sub    $0x1c,%esp
f01003e7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003e9:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ee:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f8:	eb 09                	jmp    f0100403 <cons_putc+0x25>
f01003fa:	89 ca                	mov    %ecx,%edx
f01003fc:	ec                   	in     (%dx),%al
f01003fd:	ec                   	in     (%dx),%al
f01003fe:	ec                   	in     (%dx),%al
f01003ff:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100400:	83 c3 01             	add    $0x1,%ebx
f0100403:	89 f2                	mov    %esi,%edx
f0100405:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100406:	a8 20                	test   $0x20,%al
f0100408:	75 08                	jne    f0100412 <cons_putc+0x34>
f010040a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100410:	7e e8                	jle    f01003fa <cons_putc+0x1c>
f0100412:	89 f8                	mov    %edi,%eax
f0100414:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100417:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010041c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100422:	be 79 03 00 00       	mov    $0x379,%esi
f0100427:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042c:	eb 09                	jmp    f0100437 <cons_putc+0x59>
f010042e:	89 ca                	mov    %ecx,%edx
f0100430:	ec                   	in     (%dx),%al
f0100431:	ec                   	in     (%dx),%al
f0100432:	ec                   	in     (%dx),%al
f0100433:	ec                   	in     (%dx),%al
f0100434:	83 c3 01             	add    $0x1,%ebx
f0100437:	89 f2                	mov    %esi,%edx
f0100439:	ec                   	in     (%dx),%al
f010043a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100440:	7f 04                	jg     f0100446 <cons_putc+0x68>
f0100442:	84 c0                	test   %al,%al
f0100444:	79 e8                	jns    f010042e <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100446:	ba 78 03 00 00       	mov    $0x378,%edx
f010044b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010044f:	ee                   	out    %al,(%dx)
f0100450:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100455:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045a:	ee                   	out    %al,(%dx)
f010045b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100460:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100461:	89 fa                	mov    %edi,%edx
f0100463:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100469:	89 f8                	mov    %edi,%eax
f010046b:	80 cc 07             	or     $0x7,%ah
f010046e:	85 d2                	test   %edx,%edx
f0100470:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100473:	89 f8                	mov    %edi,%eax
f0100475:	0f b6 c0             	movzbl %al,%eax
f0100478:	83 f8 09             	cmp    $0x9,%eax
f010047b:	74 74                	je     f01004f1 <cons_putc+0x113>
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	7f 0a                	jg     f010048c <cons_putc+0xae>
f0100482:	83 f8 08             	cmp    $0x8,%eax
f0100485:	74 14                	je     f010049b <cons_putc+0xbd>
f0100487:	e9 99 00 00 00       	jmp    f0100525 <cons_putc+0x147>
f010048c:	83 f8 0a             	cmp    $0xa,%eax
f010048f:	74 3a                	je     f01004cb <cons_putc+0xed>
f0100491:	83 f8 0d             	cmp    $0xd,%eax
f0100494:	74 3d                	je     f01004d3 <cons_putc+0xf5>
f0100496:	e9 8a 00 00 00       	jmp    f0100525 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010049b:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 f2 22 f0 	addw   $0x50,0xf022f228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
f01004ef:	eb 52                	jmp    f0100543 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f6:	e8 e3 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 d9 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 cf fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 c5 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 bb fe ff ff       	call   f01003de <cons_putc>
f0100523:	eb 1e                	jmp    f0100543 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100525:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 f2 22 f0 	mov    %dx,0xf022f228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 f2 22 f0 	cmpw   $0x7cf,0xf022f228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c f2 22 f0       	mov    0xf022f22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 0a 4d 00 00       	call   f0105272 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010056e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100574:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057a:	83 c4 10             	add    $0x10,%esp
f010057d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100582:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100585:	39 d0                	cmp    %edx,%eax
f0100587:	75 f4                	jne    f010057d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100589:	66 83 2d 28 f2 22 f0 	subw   $0x50,0xf022f228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 f2 22 f0    	mov    0xf022f230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 f2 22 f0 	movzwl 0xf022f228,%ebx
f01005a6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005a9:	89 d8                	mov    %ebx,%eax
f01005ab:	66 c1 e8 08          	shr    $0x8,%ax
f01005af:	89 f2                	mov    %esi,%edx
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	89 d8                	mov    %ebx,%eax
f01005bc:	89 f2                	mov    %esi,%edx
f01005be:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005c2:	5b                   	pop    %ebx
f01005c3:	5e                   	pop    %esi
f01005c4:	5f                   	pop    %edi
f01005c5:	5d                   	pop    %ebp
f01005c6:	c3                   	ret    

f01005c7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005c7:	80 3d 34 f2 22 f0 00 	cmpb   $0x0,0xf022f234
f01005ce:	74 11                	je     f01005e1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005d0:	55                   	push   %ebp
f01005d1:	89 e5                	mov    %esp,%ebp
f01005d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005d6:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005db:	e8 a2 fc ff ff       	call   f0100282 <cons_intr>
}
f01005e0:	c9                   	leave  
f01005e1:	f3 c3                	repz ret 

f01005e3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005e3:	55                   	push   %ebp
f01005e4:	89 e5                	mov    %esp,%ebp
f01005e6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005e9:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005ee:	e8 8f fc ff ff       	call   f0100282 <cons_intr>
}
f01005f3:	c9                   	leave  
f01005f4:	c3                   	ret    

f01005f5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005f5:	55                   	push   %ebp
f01005f6:	89 e5                	mov    %esp,%ebp
f01005f8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005fb:	e8 c7 ff ff ff       	call   f01005c7 <serial_intr>
	kbd_intr();
f0100600:	e8 de ff ff ff       	call   f01005e3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100605:	a1 20 f2 22 f0       	mov    0xf022f220,%eax
f010060a:	3b 05 24 f2 22 f0    	cmp    0xf022f224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 f2 22 f0    	mov    %edx,0xf022f220
f010061b:	0f b6 88 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100622:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100624:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010062a:	75 11                	jne    f010063d <cons_getc+0x48>
			cons.rpos = 0;
f010062c:	c7 05 20 f2 22 f0 00 	movl   $0x0,0xf022f220
f0100633:	00 00 00 
f0100636:	eb 05                	jmp    f010063d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100638:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010063d:	c9                   	leave  
f010063e:	c3                   	ret    

f010063f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010063f:	55                   	push   %ebp
f0100640:	89 e5                	mov    %esp,%ebp
f0100642:	57                   	push   %edi
f0100643:	56                   	push   %esi
f0100644:	53                   	push   %ebx
f0100645:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100648:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010064f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100656:	5a a5 
	if (*cp != 0xA55A) {
f0100658:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010065f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100663:	74 11                	je     f0100676 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100665:	c7 05 30 f2 22 f0 b4 	movl   $0x3b4,0xf022f230
f010066c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010066f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100674:	eb 16                	jmp    f010068c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100676:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010067d:	c7 05 30 f2 22 f0 d4 	movl   $0x3d4,0xf022f230
f0100684:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100687:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010068c:	8b 3d 30 f2 22 f0    	mov    0xf022f230,%edi
f0100692:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100697:	89 fa                	mov    %edi,%edx
f0100699:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069a:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010069d:	89 da                	mov    %ebx,%edx
f010069f:	ec                   	in     (%dx),%al
f01006a0:	0f b6 c8             	movzbl %al,%ecx
f01006a3:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006ab:	89 fa                	mov    %edi,%edx
f01006ad:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ae:	89 da                	mov    %ebx,%edx
f01006b0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006b1:	89 35 2c f2 22 f0    	mov    %esi,0xf022f22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 58 2e 00 00       	call   f0103534 <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006dc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e6:	89 f2                	mov    %esi,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006ee:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006f9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006fe:	89 da                	mov    %ebx,%edx
f0100700:	ee                   	out    %al,(%dx)
f0100701:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100706:	b8 00 00 00 00       	mov    $0x0,%eax
f010070b:	ee                   	out    %al,(%dx)
f010070c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100711:	b8 03 00 00 00       	mov    $0x3,%eax
f0100716:	ee                   	out    %al,(%dx)
f0100717:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010071c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100721:	ee                   	out    %al,(%dx)
f0100722:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100727:	b8 01 00 00 00       	mov    $0x1,%eax
f010072c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010072d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100732:	ec                   	in     (%dx),%al
f0100733:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100735:	83 c4 10             	add    $0x10,%esp
f0100738:	3c ff                	cmp    $0xff,%al
f010073a:	0f 95 05 34 f2 22 f0 	setne  0xf022f234
f0100741:	89 f2                	mov    %esi,%edx
f0100743:	ec                   	in     (%dx),%al
f0100744:	89 da                	mov    %ebx,%edx
f0100746:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100747:	80 f9 ff             	cmp    $0xff,%cl
f010074a:	75 10                	jne    f010075c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	68 af 5f 10 f0       	push   $0xf0105faf
f0100754:	e8 2c 2f 00 00       	call   f0103685 <cprintf>
f0100759:	83 c4 10             	add    $0x10,%esp
}
f010075c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010075f:	5b                   	pop    %ebx
f0100760:	5e                   	pop    %esi
f0100761:	5f                   	pop    %edi
f0100762:	5d                   	pop    %ebp
f0100763:	c3                   	ret    

f0100764 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010076a:	8b 45 08             	mov    0x8(%ebp),%eax
f010076d:	e8 6c fc ff ff       	call   f01003de <cons_putc>
}
f0100772:	c9                   	leave  
f0100773:	c3                   	ret    

f0100774 <getchar>:

int
getchar(void)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010077a:	e8 76 fe ff ff       	call   f01005f5 <cons_getc>
f010077f:	85 c0                	test   %eax,%eax
f0100781:	74 f7                	je     f010077a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <iscons>:

int
iscons(int fdnum)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100788:	b8 01 00 00 00       	mov    $0x1,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100795:	68 00 62 10 f0       	push   $0xf0106200
f010079a:	68 1e 62 10 f0       	push   $0xf010621e
f010079f:	68 23 62 10 f0       	push   $0xf0106223
f01007a4:	e8 dc 2e 00 00       	call   f0103685 <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 dc 62 10 f0       	push   $0xf01062dc
f01007b1:	68 2c 62 10 f0       	push   $0xf010622c
f01007b6:	68 23 62 10 f0       	push   $0xf0106223
f01007bb:	e8 c5 2e 00 00       	call   f0103685 <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	68 04 63 10 f0       	push   $0xf0106304
f01007c8:	68 35 62 10 f0       	push   $0xf0106235
f01007cd:	68 23 62 10 f0       	push   $0xf0106223
f01007d2:	e8 ae 2e 00 00       	call   f0103685 <cprintf>
	return 0;
}
f01007d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dc:	c9                   	leave  
f01007dd:	c3                   	ret    

f01007de <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007de:	55                   	push   %ebp
f01007df:	89 e5                	mov    %esp,%ebp
f01007e1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007e4:	68 3f 62 10 f0       	push   $0xf010623f
f01007e9:	e8 97 2e 00 00       	call   f0103685 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ee:	83 c4 08             	add    $0x8,%esp
f01007f1:	68 0c 00 10 00       	push   $0x10000c
f01007f6:	68 30 63 10 f0       	push   $0xf0106330
f01007fb:	e8 85 2e 00 00       	call   f0103685 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 0c 00 10 00       	push   $0x10000c
f0100808:	68 0c 00 10 f0       	push   $0xf010000c
f010080d:	68 58 63 10 f0       	push   $0xf0106358
f0100812:	e8 6e 2e 00 00       	call   f0103685 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 c1 5e 10 00       	push   $0x105ec1
f010081f:	68 c1 5e 10 f0       	push   $0xf0105ec1
f0100824:	68 7c 63 10 f0       	push   $0xf010637c
f0100829:	e8 57 2e 00 00       	call   f0103685 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 10 e9 22 00       	push   $0x22e910
f0100836:	68 10 e9 22 f0       	push   $0xf022e910
f010083b:	68 a0 63 10 f0       	push   $0xf01063a0
f0100840:	e8 40 2e 00 00       	call   f0103685 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100845:	83 c4 0c             	add    $0xc,%esp
f0100848:	68 08 10 27 00       	push   $0x271008
f010084d:	68 08 10 27 f0       	push   $0xf0271008
f0100852:	68 c4 63 10 f0       	push   $0xf01063c4
f0100857:	e8 29 2e 00 00       	call   f0103685 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010085c:	b8 07 14 27 f0       	mov    $0xf0271407,%eax
f0100861:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100866:	83 c4 08             	add    $0x8,%esp
f0100869:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010086e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100874:	85 c0                	test   %eax,%eax
f0100876:	0f 48 c2             	cmovs  %edx,%eax
f0100879:	c1 f8 0a             	sar    $0xa,%eax
f010087c:	50                   	push   %eax
f010087d:	68 e8 63 10 f0       	push   $0xf01063e8
f0100882:	e8 fe 2d 00 00       	call   f0103685 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100887:	b8 00 00 00 00       	mov    $0x0,%eax
f010088c:	c9                   	leave  
f010088d:	c3                   	ret    

f010088e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010088e:	55                   	push   %ebp
f010088f:	89 e5                	mov    %esp,%ebp
f0100891:	57                   	push   %edi
f0100892:	56                   	push   %esi
f0100893:	53                   	push   %ebx
f0100894:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100897:	89 eb                	mov    %ebp,%ebx
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
f0100899:	68 58 62 10 f0       	push   $0xf0106258
f010089e:	e8 e2 2d 00 00       	call   f0103685 <cprintf>
	while(ebp)
f01008a3:	83 c4 10             	add    $0x10,%esp
		cprintf("%08x ", *(ebp+3));
		cprintf("%08x ", *(ebp+4));
		cprintf("%08x ", *(ebp+5));
		cprintf("%08x", *(ebp+6));

		if(debuginfo_eip(eip, &info) == 0)
f01008a6:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f01008a9:	e9 95 00 00 00       	jmp    f0100943 <mon_backtrace+0xb5>
	{
		eip = *(ebp+1);
f01008ae:	8b 73 04             	mov    0x4(%ebx),%esi

		cprintf("ebp %08x  eip %08x  args ", ebp, eip);
f01008b1:	83 ec 04             	sub    $0x4,%esp
f01008b4:	56                   	push   %esi
f01008b5:	53                   	push   %ebx
f01008b6:	68 6b 62 10 f0       	push   $0xf010626b
f01008bb:	e8 c5 2d 00 00       	call   f0103685 <cprintf>
		cprintf("%08x ", *(ebp+2));
f01008c0:	83 c4 08             	add    $0x8,%esp
f01008c3:	ff 73 08             	pushl  0x8(%ebx)
f01008c6:	68 85 62 10 f0       	push   $0xf0106285
f01008cb:	e8 b5 2d 00 00       	call   f0103685 <cprintf>
		cprintf("%08x ", *(ebp+3));
f01008d0:	83 c4 08             	add    $0x8,%esp
f01008d3:	ff 73 0c             	pushl  0xc(%ebx)
f01008d6:	68 85 62 10 f0       	push   $0xf0106285
f01008db:	e8 a5 2d 00 00       	call   f0103685 <cprintf>
		cprintf("%08x ", *(ebp+4));
f01008e0:	83 c4 08             	add    $0x8,%esp
f01008e3:	ff 73 10             	pushl  0x10(%ebx)
f01008e6:	68 85 62 10 f0       	push   $0xf0106285
f01008eb:	e8 95 2d 00 00       	call   f0103685 <cprintf>
		cprintf("%08x ", *(ebp+5));
f01008f0:	83 c4 08             	add    $0x8,%esp
f01008f3:	ff 73 14             	pushl  0x14(%ebx)
f01008f6:	68 85 62 10 f0       	push   $0xf0106285
f01008fb:	e8 85 2d 00 00       	call   f0103685 <cprintf>
		cprintf("%08x", *(ebp+6));
f0100900:	83 c4 08             	add    $0x8,%esp
f0100903:	ff 73 18             	pushl  0x18(%ebx)
f0100906:	68 22 73 10 f0       	push   $0xf0107322
f010090b:	e8 75 2d 00 00       	call   f0103685 <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f0100910:	83 c4 08             	add    $0x8,%esp
f0100913:	57                   	push   %edi
f0100914:	56                   	push   %esi
f0100915:	e8 99 3e 00 00       	call   f01047b3 <debuginfo_eip>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	75 20                	jne    f0100941 <mon_backtrace+0xb3>
		{
			cprintf("\t %s:%d: %.*s+%d\n\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 											      info.eip_fn_name, eip-info.eip_fn_addr);
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100927:	56                   	push   %esi
f0100928:	ff 75 d8             	pushl  -0x28(%ebp)
f010092b:	ff 75 dc             	pushl  -0x24(%ebp)
f010092e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100931:	ff 75 d0             	pushl  -0x30(%ebp)
f0100934:	68 8b 62 10 f0       	push   $0xf010628b
f0100939:	e8 47 2d 00 00       	call   f0103685 <cprintf>
f010093e:	83 c4 20             	add    $0x20,%esp
		}

		ebp = (uint32_t*) *ebp;
f0100941:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f0100943:	85 db                	test   %ebx,%ebx
f0100945:	0f 85 63 ff ff ff    	jne    f01008ae <mon_backtrace+0x20>
		}

		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f010094b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100950:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100953:	5b                   	pop    %ebx
f0100954:	5e                   	pop    %esi
f0100955:	5f                   	pop    %edi
f0100956:	5d                   	pop    %ebp
f0100957:	c3                   	ret    

f0100958 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100958:	55                   	push   %ebp
f0100959:	89 e5                	mov    %esp,%ebp
f010095b:	57                   	push   %edi
f010095c:	56                   	push   %esi
f010095d:	53                   	push   %ebx
f010095e:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100961:	68 14 64 10 f0       	push   $0xf0106414
f0100966:	e8 1a 2d 00 00       	call   f0103685 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010096b:	c7 04 24 38 64 10 f0 	movl   $0xf0106438,(%esp)
f0100972:	e8 0e 2d 00 00       	call   f0103685 <cprintf>

	if (tf != NULL)
f0100977:	83 c4 10             	add    $0x10,%esp
f010097a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010097e:	74 0e                	je     f010098e <monitor+0x36>
		print_trapframe(tf);
f0100980:	83 ec 0c             	sub    $0xc,%esp
f0100983:	ff 75 08             	pushl  0x8(%ebp)
f0100986:	e8 e6 31 00 00       	call   f0103b71 <print_trapframe>
f010098b:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010098e:	83 ec 0c             	sub    $0xc,%esp
f0100991:	68 9e 62 10 f0       	push   $0xf010629e
f0100996:	e8 33 46 00 00       	call   f0104fce <readline>
f010099b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010099d:	83 c4 10             	add    $0x10,%esp
f01009a0:	85 c0                	test   %eax,%eax
f01009a2:	74 ea                	je     f010098e <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009a4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009ab:	be 00 00 00 00       	mov    $0x0,%esi
f01009b0:	eb 0a                	jmp    f01009bc <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009b2:	c6 03 00             	movb   $0x0,(%ebx)
f01009b5:	89 f7                	mov    %esi,%edi
f01009b7:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009ba:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009bc:	0f b6 03             	movzbl (%ebx),%eax
f01009bf:	84 c0                	test   %al,%al
f01009c1:	74 63                	je     f0100a26 <monitor+0xce>
f01009c3:	83 ec 08             	sub    $0x8,%esp
f01009c6:	0f be c0             	movsbl %al,%eax
f01009c9:	50                   	push   %eax
f01009ca:	68 a2 62 10 f0       	push   $0xf01062a2
f01009cf:	e8 14 48 00 00       	call   f01051e8 <strchr>
f01009d4:	83 c4 10             	add    $0x10,%esp
f01009d7:	85 c0                	test   %eax,%eax
f01009d9:	75 d7                	jne    f01009b2 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009db:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009de:	74 46                	je     f0100a26 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009e0:	83 fe 0f             	cmp    $0xf,%esi
f01009e3:	75 14                	jne    f01009f9 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009e5:	83 ec 08             	sub    $0x8,%esp
f01009e8:	6a 10                	push   $0x10
f01009ea:	68 a7 62 10 f0       	push   $0xf01062a7
f01009ef:	e8 91 2c 00 00       	call   f0103685 <cprintf>
f01009f4:	83 c4 10             	add    $0x10,%esp
f01009f7:	eb 95                	jmp    f010098e <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009f9:	8d 7e 01             	lea    0x1(%esi),%edi
f01009fc:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a00:	eb 03                	jmp    f0100a05 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a02:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a05:	0f b6 03             	movzbl (%ebx),%eax
f0100a08:	84 c0                	test   %al,%al
f0100a0a:	74 ae                	je     f01009ba <monitor+0x62>
f0100a0c:	83 ec 08             	sub    $0x8,%esp
f0100a0f:	0f be c0             	movsbl %al,%eax
f0100a12:	50                   	push   %eax
f0100a13:	68 a2 62 10 f0       	push   $0xf01062a2
f0100a18:	e8 cb 47 00 00       	call   f01051e8 <strchr>
f0100a1d:	83 c4 10             	add    $0x10,%esp
f0100a20:	85 c0                	test   %eax,%eax
f0100a22:	74 de                	je     f0100a02 <monitor+0xaa>
f0100a24:	eb 94                	jmp    f01009ba <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100a26:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a2d:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a2e:	85 f6                	test   %esi,%esi
f0100a30:	0f 84 58 ff ff ff    	je     f010098e <monitor+0x36>
f0100a36:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a3b:	83 ec 08             	sub    $0x8,%esp
f0100a3e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a41:	ff 34 85 60 64 10 f0 	pushl  -0xfef9ba0(,%eax,4)
f0100a48:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a4b:	e8 3a 47 00 00       	call   f010518a <strcmp>
f0100a50:	83 c4 10             	add    $0x10,%esp
f0100a53:	85 c0                	test   %eax,%eax
f0100a55:	75 21                	jne    f0100a78 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a57:	83 ec 04             	sub    $0x4,%esp
f0100a5a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a5d:	ff 75 08             	pushl  0x8(%ebp)
f0100a60:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a63:	52                   	push   %edx
f0100a64:	56                   	push   %esi
f0100a65:	ff 14 85 68 64 10 f0 	call   *-0xfef9b98(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a6c:	83 c4 10             	add    $0x10,%esp
f0100a6f:	85 c0                	test   %eax,%eax
f0100a71:	78 25                	js     f0100a98 <monitor+0x140>
f0100a73:	e9 16 ff ff ff       	jmp    f010098e <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a78:	83 c3 01             	add    $0x1,%ebx
f0100a7b:	83 fb 03             	cmp    $0x3,%ebx
f0100a7e:	75 bb                	jne    f0100a3b <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a80:	83 ec 08             	sub    $0x8,%esp
f0100a83:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a86:	68 c4 62 10 f0       	push   $0xf01062c4
f0100a8b:	e8 f5 2b 00 00       	call   f0103685 <cprintf>
f0100a90:	83 c4 10             	add    $0x10,%esp
f0100a93:	e9 f6 fe ff ff       	jmp    f010098e <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a98:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a9b:	5b                   	pop    %ebx
f0100a9c:	5e                   	pop    %esi
f0100a9d:	5f                   	pop    %edi
f0100a9e:	5d                   	pop    %ebp
f0100a9f:	c3                   	ret    

f0100aa0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100aa0:	55                   	push   %ebp
f0100aa1:	89 e5                	mov    %esp,%ebp
f0100aa3:	56                   	push   %esi
f0100aa4:	53                   	push   %ebx
f0100aa5:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100aa7:	83 ec 0c             	sub    $0xc,%esp
f0100aaa:	50                   	push   %eax
f0100aab:	e8 56 2a 00 00       	call   f0103506 <mc146818_read>
f0100ab0:	89 c6                	mov    %eax,%esi
f0100ab2:	83 c3 01             	add    $0x1,%ebx
f0100ab5:	89 1c 24             	mov    %ebx,(%esp)
f0100ab8:	e8 49 2a 00 00       	call   f0103506 <mc146818_read>
f0100abd:	c1 e0 08             	shl    $0x8,%eax
f0100ac0:	09 f0                	or     %esi,%eax
}
f0100ac2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ac5:	5b                   	pop    %ebx
f0100ac6:	5e                   	pop    %esi
f0100ac7:	5d                   	pop    %ebp
f0100ac8:	c3                   	ret    

f0100ac9 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ac9:	89 d1                	mov    %edx,%ecx
f0100acb:	c1 e9 16             	shr    $0x16,%ecx
f0100ace:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100ad1:	a8 01                	test   $0x1,%al
f0100ad3:	74 52                	je     f0100b27 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ad5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ada:	89 c1                	mov    %eax,%ecx
f0100adc:	c1 e9 0c             	shr    $0xc,%ecx
f0100adf:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0100ae5:	72 1b                	jb     f0100b02 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ae7:	55                   	push   %ebp
f0100ae8:	89 e5                	mov    %esp,%ebp
f0100aea:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aed:	50                   	push   %eax
f0100aee:	68 04 5f 10 f0       	push   $0xf0105f04
f0100af3:	68 c5 03 00 00       	push   $0x3c5
f0100af8:	68 25 6e 10 f0       	push   $0xf0106e25
f0100afd:	e8 3e f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b02:	c1 ea 0c             	shr    $0xc,%edx
f0100b05:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b0b:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b12:	89 c2                	mov    %eax,%edx
f0100b14:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b17:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b1c:	85 d2                	test   %edx,%edx
f0100b1e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b23:	0f 44 c2             	cmove  %edx,%eax
f0100b26:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b2c:	c3                   	ret    

f0100b2d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b2d:	55                   	push   %ebp
f0100b2e:	89 e5                	mov    %esp,%ebp
f0100b30:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b33:	83 3d 38 f2 22 f0 00 	cmpl   $0x0,0xf022f238
f0100b3a:	75 11                	jne    f0100b4d <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b3c:	ba 07 20 27 f0       	mov    $0xf0272007,%edx
f0100b41:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b47:	89 15 38 f2 22 f0    	mov    %edx,0xf022f238
	//
	// LAB 2: Your code here.
	if(n < 0) 
		panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) 
f0100b4d:	85 c0                	test   %eax,%eax
f0100b4f:	75 07                	jne    f0100b58 <boot_alloc+0x2b>
		return nextfree;
f0100b51:	a1 38 f2 22 f0       	mov    0xf022f238,%eax
f0100b56:	eb 54                	jmp    f0100bac <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f0100b58:	8b 15 38 f2 22 f0    	mov    0xf022f238,%edx

		char* new = ROUNDUP(nextfree+n, PGSIZE);
f0100b5e:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100b65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b6a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b6f:	77 12                	ja     f0100b83 <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b71:	50                   	push   %eax
f0100b72:	68 28 5f 10 f0       	push   $0xf0105f28
f0100b77:	6a 78                	push   $0x78
f0100b79:	68 25 6e 10 f0       	push   $0xf0106e25
f0100b7e:	e8 bd f4 ff ff       	call   f0100040 <_panic>

		if(PADDR(new) > 1024*1024*4) 
f0100b83:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100b89:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100b8f:	76 14                	jbe    f0100ba5 <boot_alloc+0x78>
			panic("boot_alloc: not enough memory!\n");
f0100b91:	83 ec 04             	sub    $0x4,%esp
f0100b94:	68 84 64 10 f0       	push   $0xf0106484
f0100b99:	6a 79                	push   $0x79
f0100b9b:	68 25 6e 10 f0       	push   $0xf0106e25
f0100ba0:	e8 9b f4 ff ff       	call   f0100040 <_panic>

		else
		{
			nextfree = new;
f0100ba5:	a3 38 f2 22 f0       	mov    %eax,0xf022f238
		}
	}

	return result;
f0100baa:	89 d0                	mov    %edx,%eax
}
f0100bac:	c9                   	leave  
f0100bad:	c3                   	ret    

f0100bae <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100bae:	55                   	push   %ebp
f0100baf:	89 e5                	mov    %esp,%ebp
f0100bb1:	57                   	push   %edi
f0100bb2:	56                   	push   %esi
f0100bb3:	53                   	push   %ebx
f0100bb4:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bb7:	84 c0                	test   %al,%al
f0100bb9:	0f 85 a0 02 00 00    	jne    f0100e5f <check_page_free_list+0x2b1>
f0100bbf:	e9 ad 02 00 00       	jmp    f0100e71 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100bc4:	83 ec 04             	sub    $0x4,%esp
f0100bc7:	68 a4 64 10 f0       	push   $0xf01064a4
f0100bcc:	68 f8 02 00 00       	push   $0x2f8
f0100bd1:	68 25 6e 10 f0       	push   $0xf0106e25
f0100bd6:	e8 65 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100bdb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bde:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100be1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100be4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100be7:	89 c2                	mov    %eax,%edx
f0100be9:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0100bef:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100bf5:	0f 95 c2             	setne  %dl
f0100bf8:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100bfb:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100bff:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c01:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c05:	8b 00                	mov    (%eax),%eax
f0100c07:	85 c0                	test   %eax,%eax
f0100c09:	75 dc                	jne    f0100be7 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c0e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c1a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c1c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c1f:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c24:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c29:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100c2f:	eb 53                	jmp    f0100c84 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c31:	89 d8                	mov    %ebx,%eax
f0100c33:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100c39:	c1 f8 03             	sar    $0x3,%eax
f0100c3c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c3f:	89 c2                	mov    %eax,%edx
f0100c41:	c1 ea 16             	shr    $0x16,%edx
f0100c44:	39 f2                	cmp    %esi,%edx
f0100c46:	73 3a                	jae    f0100c82 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c48:	89 c2                	mov    %eax,%edx
f0100c4a:	c1 ea 0c             	shr    $0xc,%edx
f0100c4d:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100c53:	72 12                	jb     f0100c67 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c55:	50                   	push   %eax
f0100c56:	68 04 5f 10 f0       	push   $0xf0105f04
f0100c5b:	6a 58                	push   $0x58
f0100c5d:	68 31 6e 10 f0       	push   $0xf0106e31
f0100c62:	e8 d9 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c67:	83 ec 04             	sub    $0x4,%esp
f0100c6a:	68 80 00 00 00       	push   $0x80
f0100c6f:	68 97 00 00 00       	push   $0x97
f0100c74:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c79:	50                   	push   %eax
f0100c7a:	e8 a6 45 00 00       	call   f0105225 <memset>
f0100c7f:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c82:	8b 1b                	mov    (%ebx),%ebx
f0100c84:	85 db                	test   %ebx,%ebx
f0100c86:	75 a9                	jne    f0100c31 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c88:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8d:	e8 9b fe ff ff       	call   f0100b2d <boot_alloc>
f0100c92:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c95:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c9b:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
		assert(pp < pages + npages);
f0100ca1:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0100ca6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ca9:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100cac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100caf:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cb2:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cb7:	e9 52 01 00 00       	jmp    f0100e0e <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cbc:	39 ca                	cmp    %ecx,%edx
f0100cbe:	73 19                	jae    f0100cd9 <check_page_free_list+0x12b>
f0100cc0:	68 3f 6e 10 f0       	push   $0xf0106e3f
f0100cc5:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100cca:	68 12 03 00 00       	push   $0x312
f0100ccf:	68 25 6e 10 f0       	push   $0xf0106e25
f0100cd4:	e8 67 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cd9:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cdc:	72 19                	jb     f0100cf7 <check_page_free_list+0x149>
f0100cde:	68 60 6e 10 f0       	push   $0xf0106e60
f0100ce3:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100ce8:	68 13 03 00 00       	push   $0x313
f0100ced:	68 25 6e 10 f0       	push   $0xf0106e25
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cf7:	89 d0                	mov    %edx,%eax
f0100cf9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100cfc:	a8 07                	test   $0x7,%al
f0100cfe:	74 19                	je     f0100d19 <check_page_free_list+0x16b>
f0100d00:	68 c8 64 10 f0       	push   $0xf01064c8
f0100d05:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100d0a:	68 14 03 00 00       	push   $0x314
f0100d0f:	68 25 6e 10 f0       	push   $0xf0106e25
f0100d14:	e8 27 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d19:	c1 f8 03             	sar    $0x3,%eax
f0100d1c:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d1f:	85 c0                	test   %eax,%eax
f0100d21:	75 19                	jne    f0100d3c <check_page_free_list+0x18e>
f0100d23:	68 74 6e 10 f0       	push   $0xf0106e74
f0100d28:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100d2d:	68 17 03 00 00       	push   $0x317
f0100d32:	68 25 6e 10 f0       	push   $0xf0106e25
f0100d37:	e8 04 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d3c:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d41:	75 19                	jne    f0100d5c <check_page_free_list+0x1ae>
f0100d43:	68 85 6e 10 f0       	push   $0xf0106e85
f0100d48:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100d4d:	68 18 03 00 00       	push   $0x318
f0100d52:	68 25 6e 10 f0       	push   $0xf0106e25
f0100d57:	e8 e4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d5c:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d61:	75 19                	jne    f0100d7c <check_page_free_list+0x1ce>
f0100d63:	68 fc 64 10 f0       	push   $0xf01064fc
f0100d68:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100d6d:	68 19 03 00 00       	push   $0x319
f0100d72:	68 25 6e 10 f0       	push   $0xf0106e25
f0100d77:	e8 c4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d7c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d81:	75 19                	jne    f0100d9c <check_page_free_list+0x1ee>
f0100d83:	68 9e 6e 10 f0       	push   $0xf0106e9e
f0100d88:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100d8d:	68 1a 03 00 00       	push   $0x31a
f0100d92:	68 25 6e 10 f0       	push   $0xf0106e25
f0100d97:	e8 a4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d9c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100da1:	0f 86 f1 00 00 00    	jbe    f0100e98 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da7:	89 c7                	mov    %eax,%edi
f0100da9:	c1 ef 0c             	shr    $0xc,%edi
f0100dac:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100daf:	77 12                	ja     f0100dc3 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db1:	50                   	push   %eax
f0100db2:	68 04 5f 10 f0       	push   $0xf0105f04
f0100db7:	6a 58                	push   $0x58
f0100db9:	68 31 6e 10 f0       	push   $0xf0106e31
f0100dbe:	e8 7d f2 ff ff       	call   f0100040 <_panic>
f0100dc3:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100dc9:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100dcc:	0f 86 b6 00 00 00    	jbe    f0100e88 <check_page_free_list+0x2da>
f0100dd2:	68 20 65 10 f0       	push   $0xf0106520
f0100dd7:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100ddc:	68 1b 03 00 00       	push   $0x31b
f0100de1:	68 25 6e 10 f0       	push   $0xf0106e25
f0100de6:	e8 55 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100deb:	68 b8 6e 10 f0       	push   $0xf0106eb8
f0100df0:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100df5:	68 1d 03 00 00       	push   $0x31d
f0100dfa:	68 25 6e 10 f0       	push   $0xf0106e25
f0100dff:	e8 3c f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100e04:	83 c6 01             	add    $0x1,%esi
f0100e07:	eb 03                	jmp    f0100e0c <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100e09:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e0c:	8b 12                	mov    (%edx),%edx
f0100e0e:	85 d2                	test   %edx,%edx
f0100e10:	0f 85 a6 fe ff ff    	jne    f0100cbc <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100e16:	85 f6                	test   %esi,%esi
f0100e18:	7f 19                	jg     f0100e33 <check_page_free_list+0x285>
f0100e1a:	68 d5 6e 10 f0       	push   $0xf0106ed5
f0100e1f:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100e24:	68 25 03 00 00       	push   $0x325
f0100e29:	68 25 6e 10 f0       	push   $0xf0106e25
f0100e2e:	e8 0d f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e33:	85 db                	test   %ebx,%ebx
f0100e35:	7f 19                	jg     f0100e50 <check_page_free_list+0x2a2>
f0100e37:	68 e7 6e 10 f0       	push   $0xf0106ee7
f0100e3c:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0100e41:	68 26 03 00 00       	push   $0x326
f0100e46:	68 25 6e 10 f0       	push   $0xf0106e25
f0100e4b:	e8 f0 f1 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e50:	83 ec 0c             	sub    $0xc,%esp
f0100e53:	68 68 65 10 f0       	push   $0xf0106568
f0100e58:	e8 28 28 00 00       	call   f0103685 <cprintf>
}
f0100e5d:	eb 49                	jmp    f0100ea8 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e5f:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0100e64:	85 c0                	test   %eax,%eax
f0100e66:	0f 85 6f fd ff ff    	jne    f0100bdb <check_page_free_list+0x2d>
f0100e6c:	e9 53 fd ff ff       	jmp    f0100bc4 <check_page_free_list+0x16>
f0100e71:	83 3d 40 f2 22 f0 00 	cmpl   $0x0,0xf022f240
f0100e78:	0f 84 46 fd ff ff    	je     f0100bc4 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e7e:	be 00 04 00 00       	mov    $0x400,%esi
f0100e83:	e9 a1 fd ff ff       	jmp    f0100c29 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e88:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e8d:	0f 85 76 ff ff ff    	jne    f0100e09 <check_page_free_list+0x25b>
f0100e93:	e9 53 ff ff ff       	jmp    f0100deb <check_page_free_list+0x23d>
f0100e98:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e9d:	0f 85 61 ff ff ff    	jne    f0100e04 <check_page_free_list+0x256>
f0100ea3:	e9 43 ff ff ff       	jmp    f0100deb <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100ea8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eab:	5b                   	pop    %ebx
f0100eac:	5e                   	pop    %esi
f0100ead:	5f                   	pop    %edi
f0100eae:	5d                   	pop    %ebp
f0100eaf:	c3                   	ret    

f0100eb0 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100eb0:	55                   	push   %ebp
f0100eb1:	89 e5                	mov    %esp,%ebp
f0100eb3:	57                   	push   %edi
f0100eb4:	56                   	push   %esi
f0100eb5:	53                   	push   %ebx
f0100eb6:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	
f0100eb9:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100ebe:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

	for (i = 1; i < npages; ++i) 
f0100ec4:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100ec9:	be 08 00 00 00       	mov    $0x8,%esi
f0100ece:	bf 01 00 00 00       	mov    $0x1,%edi
f0100ed3:	e9 c5 00 00 00       	jmp    f0100f9d <page_init+0xed>
	{
		if((i*PGSIZE  >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM))
f0100ed8:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100ede:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100ee3:	77 19                	ja     f0100efe <page_init+0x4e>
		{
			pages[i].pp_ref = 1;
f0100ee5:	89 f0                	mov    %esi,%eax
f0100ee7:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100eed:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100ef3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;	
f0100ef9:	e9 93 00 00 00       	jmp    f0100f91 <page_init+0xe1>
		}

		if((i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))))
f0100efe:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100f04:	76 45                	jbe    f0100f4b <page_init+0x9b>
f0100f06:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f0b:	e8 1d fc ff ff       	call   f0100b2d <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f10:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f15:	77 15                	ja     f0100f2c <page_init+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f17:	50                   	push   %eax
f0100f18:	68 28 5f 10 f0       	push   $0xf0105f28
f0100f1d:	68 5a 01 00 00       	push   $0x15a
f0100f22:	68 25 6e 10 f0       	push   $0xf0106e25
f0100f27:	e8 14 f1 ff ff       	call   f0100040 <_panic>
f0100f2c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f31:	39 d8                	cmp    %ebx,%eax
f0100f33:	76 16                	jbe    f0100f4b <page_init+0x9b>
		{
			pages[i].pp_ref = 1;
f0100f35:	89 f0                	mov    %esi,%eax
f0100f37:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f3d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f43:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f49:	eb 46                	jmp    f0100f91 <page_init+0xe1>
		}

		if((i * PGSIZE >= MPENTRY_PADDR) && (i * PGSIZE < MPENTRY_PADDR + PGSIZE))
f0100f4b:	8d 83 00 90 ff ff    	lea    -0x7000(%ebx),%eax
f0100f51:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0100f56:	77 16                	ja     f0100f6e <page_init+0xbe>
		{
			pages[i].pp_ref = 1;
f0100f58:	89 f0                	mov    %esi,%eax
f0100f5a:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f60:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f66:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f6c:	eb 23                	jmp    f0100f91 <page_init+0xe1>
		}
			
		pages[i].pp_ref = 0;  
f0100f6e:	89 f0                	mov    %esi,%eax
f0100f70:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f76:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f7c:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100f82:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f84:	89 f0                	mov    %esi,%eax
f0100f86:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100f8c:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	

	for (i = 1; i < npages; ++i) 
f0100f91:	83 c7 01             	add    $0x1,%edi
f0100f94:	83 c6 08             	add    $0x8,%esi
f0100f97:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f9d:	3b 3d 88 fe 22 f0    	cmp    0xf022fe88,%edi
f0100fa3:	0f 82 2f ff ff ff    	jb     f0100ed8 <page_init+0x28>
			
		pages[i].pp_ref = 0;  
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100fa9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fac:	5b                   	pop    %ebx
f0100fad:	5e                   	pop    %esi
f0100fae:	5f                   	pop    %edi
f0100faf:	5d                   	pop    %ebp
f0100fb0:	c3                   	ret    

f0100fb1 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fb1:	55                   	push   %ebp
f0100fb2:	89 e5                	mov    %esp,%ebp
f0100fb4:	53                   	push   %ebx
f0100fb5:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL) 
f0100fb8:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100fbe:	85 db                	test   %ebx,%ebx
f0100fc0:	74 58                	je     f010101a <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100fc2:	8b 03                	mov    (%ebx),%eax
f0100fc4:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	page->pp_link = NULL;
f0100fc9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100fcf:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fd3:	74 45                	je     f010101a <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd5:	89 d8                	mov    %ebx,%eax
f0100fd7:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100fdd:	c1 f8 03             	sar    $0x3,%eax
f0100fe0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe3:	89 c2                	mov    %eax,%edx
f0100fe5:	c1 ea 0c             	shr    $0xc,%edx
f0100fe8:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100fee:	72 12                	jb     f0101002 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff0:	50                   	push   %eax
f0100ff1:	68 04 5f 10 f0       	push   $0xf0105f04
f0100ff6:	6a 58                	push   $0x58
f0100ff8:	68 31 6e 10 f0       	push   $0xf0106e31
f0100ffd:	e8 3e f0 ff ff       	call   f0100040 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0101002:	83 ec 04             	sub    $0x4,%esp
f0101005:	68 00 10 00 00       	push   $0x1000
f010100a:	6a 00                	push   $0x0
f010100c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101011:	50                   	push   %eax
f0101012:	e8 0e 42 00 00       	call   f0105225 <memset>
f0101017:	83 c4 10             	add    $0x10,%esp
	}

	return page;
}
f010101a:	89 d8                	mov    %ebx,%eax
f010101c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010101f:	c9                   	leave  
f0101020:	c3                   	ret    

f0101021 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101021:	55                   	push   %ebp
f0101022:	89 e5                	mov    %esp,%ebp
f0101024:	83 ec 08             	sub    $0x8,%esp
f0101027:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref != 0) || (pp->pp_link != NULL)) 
f010102a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010102f:	75 05                	jne    f0101036 <page_free+0x15>
f0101031:	83 38 00             	cmpl   $0x0,(%eax)
f0101034:	74 17                	je     f010104d <page_free+0x2c>
		panic("page_free: cannot free the page which is still in use!\n");
f0101036:	83 ec 04             	sub    $0x4,%esp
f0101039:	68 8c 65 10 f0       	push   $0xf010658c
f010103e:	68 9b 01 00 00       	push   $0x19b
f0101043:	68 25 6e 10 f0       	push   $0xf0106e25
f0101048:	e8 f3 ef ff ff       	call   f0100040 <_panic>

	
	pp->pp_link  = page_free_list;
f010104d:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0101053:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;	
f0101055:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
}
f010105a:	c9                   	leave  
f010105b:	c3                   	ret    

f010105c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010105c:	55                   	push   %ebp
f010105d:	89 e5                	mov    %esp,%ebp
f010105f:	83 ec 08             	sub    $0x8,%esp
f0101062:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101065:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101069:	83 e8 01             	sub    $0x1,%eax
f010106c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101070:	66 85 c0             	test   %ax,%ax
f0101073:	75 0c                	jne    f0101081 <page_decref+0x25>
		page_free(pp);
f0101075:	83 ec 0c             	sub    $0xc,%esp
f0101078:	52                   	push   %edx
f0101079:	e8 a3 ff ff ff       	call   f0101021 <page_free>
f010107e:	83 c4 10             	add    $0x10,%esp
}
f0101081:	c9                   	leave  
f0101082:	c3                   	ret    

f0101083 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101083:	55                   	push   %ebp
f0101084:	89 e5                	mov    %esp,%ebp
f0101086:	56                   	push   %esi
f0101087:	53                   	push   %ebx
f0101088:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	size_t dirIndex = PDX(va);
	size_t tableIndex = PTX(va);
f010108b:	89 de                	mov    %ebx,%esi
f010108d:	c1 ee 0c             	shr    $0xc,%esi
f0101090:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];
f0101096:	c1 eb 16             	shr    $0x16,%ebx
f0101099:	c1 e3 02             	shl    $0x2,%ebx
f010109c:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pdir_entry & PTE_P))
f010109f:	8b 03                	mov    (%ebx),%eax
f01010a1:	a8 01                	test   $0x1,%al
f01010a3:	75 6c                	jne    f0101111 <pgdir_walk+0x8e>
	{
		if(create == false) 
f01010a5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010a9:	0f 84 93 00 00 00    	je     f0101142 <pgdir_walk+0xbf>
			return NULL;

		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01010af:	83 ec 0c             	sub    $0xc,%esp
f01010b2:	6a 01                	push   $0x1
f01010b4:	e8 f8 fe ff ff       	call   f0100fb1 <page_alloc>

		if(page == NULL) 
f01010b9:	83 c4 10             	add    $0x10,%esp
f01010bc:	85 c0                	test   %eax,%eax
f01010be:	0f 84 85 00 00 00    	je     f0101149 <pgdir_walk+0xc6>
			return NULL;

		page->pp_ref++;
f01010c4:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

		*pdir_entry = page2pa(page) | PTE_P | PTE_W | PTE_U;
f01010c9:	89 c2                	mov    %eax,%edx
f01010cb:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f01010d1:	c1 fa 03             	sar    $0x3,%edx
f01010d4:	c1 e2 0c             	shl    $0xc,%edx
f01010d7:	83 ca 07             	or     $0x7,%edx
f01010da:	89 13                	mov    %edx,(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010dc:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01010e2:	c1 f8 03             	sar    $0x3,%eax
f01010e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e8:	89 c2                	mov    %eax,%edx
f01010ea:	c1 ea 0c             	shr    $0xc,%edx
f01010ed:	39 15 88 fe 22 f0    	cmp    %edx,0xf022fe88
f01010f3:	77 15                	ja     f010110a <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010f5:	50                   	push   %eax
f01010f6:	68 04 5f 10 f0       	push   $0xf0105f04
f01010fb:	68 dd 01 00 00       	push   $0x1dd
f0101100:	68 25 6e 10 f0       	push   $0xf0106e25
f0101105:	e8 36 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010110a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010110f:	eb 2c                	jmp    f010113d <pgdir_walk+0xba>
		
		ptable_entry = (pte_t*) KADDR(page2pa(page));
	}
	else
	{
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
f0101111:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101116:	89 c2                	mov    %eax,%edx
f0101118:	c1 ea 0c             	shr    $0xc,%edx
f010111b:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101121:	72 15                	jb     f0101138 <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101123:	50                   	push   %eax
f0101124:	68 04 5f 10 f0       	push   $0xf0105f04
f0101129:	68 e1 01 00 00       	push   $0x1e1
f010112e:	68 25 6e 10 f0       	push   $0xf0106e25
f0101133:	e8 08 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101138:	2d 00 00 00 10       	sub    $0x10000000,%eax
	}
	
	return ptable_entry + tableIndex;
f010113d:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0101140:	eb 0c                	jmp    f010114e <pgdir_walk+0xcb>
	pde_t *pdir_entry = &pgdir[dirIndex];

	if(!(*pdir_entry & PTE_P))
	{
		if(create == false) 
			return NULL;
f0101142:	b8 00 00 00 00       	mov    $0x0,%eax
f0101147:	eb 05                	jmp    f010114e <pgdir_walk+0xcb>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);

		if(page == NULL) 
			return NULL;
f0101149:	b8 00 00 00 00       	mov    $0x0,%eax
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
	}
	
	return ptable_entry + tableIndex;

}
f010114e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101151:	5b                   	pop    %ebx
f0101152:	5e                   	pop    %esi
f0101153:	5d                   	pop    %ebp
f0101154:	c3                   	ret    

f0101155 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101155:	55                   	push   %ebp
f0101156:	89 e5                	mov    %esp,%ebp
f0101158:	57                   	push   %edi
f0101159:	56                   	push   %esi
f010115a:	53                   	push   %ebx
f010115b:	83 ec 1c             	sub    $0x1c,%esp
f010115e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101161:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0101164:	c1 e9 0c             	shr    $0xc,%ecx
f0101167:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010116a:	89 c3                	mov    %eax,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;
f010116c:	be 00 00 00 00       	mov    $0x0,%esi

	for(i; i < size/PGSIZE; ++i)
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0101171:	89 d7                	mov    %edx,%edi
f0101173:	29 c7                	sub    %eax,%edi

		if(ptable_entry == NULL)
			panic("boot_map_region: Failed to allocate new PTE!");
		
		*ptable_entry = pa | perm | PTE_P;
f0101175:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101178:	83 c8 01             	or     $0x1,%eax
f010117b:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f010117e:	eb 3f                	jmp    f01011bf <boot_map_region+0x6a>
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0101180:	83 ec 04             	sub    $0x4,%esp
f0101183:	6a 01                	push   $0x1
f0101185:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101188:	50                   	push   %eax
f0101189:	ff 75 e0             	pushl  -0x20(%ebp)
f010118c:	e8 f2 fe ff ff       	call   f0101083 <pgdir_walk>

		if(ptable_entry == NULL)
f0101191:	83 c4 10             	add    $0x10,%esp
f0101194:	85 c0                	test   %eax,%eax
f0101196:	75 17                	jne    f01011af <boot_map_region+0x5a>
			panic("boot_map_region: Failed to allocate new PTE!");
f0101198:	83 ec 04             	sub    $0x4,%esp
f010119b:	68 c4 65 10 f0       	push   $0xf01065c4
f01011a0:	68 fe 01 00 00       	push   $0x1fe
f01011a5:	68 25 6e 10 f0       	push   $0xf0106e25
f01011aa:	e8 91 ee ff ff       	call   f0100040 <_panic>
		
		*ptable_entry = pa | perm | PTE_P;
f01011af:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011b2:	09 da                	or     %ebx,%edx
f01011b4:	89 10                	mov    %edx,(%eax)

		pa += PGSIZE;
f01011b6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f01011bc:	83 c6 01             	add    $0x1,%esi
f01011bf:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01011c2:	75 bc                	jne    f0101180 <boot_map_region+0x2b>

		pa += PGSIZE;
		va += PGSIZE;
	}
		
}
f01011c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c7:	5b                   	pop    %ebx
f01011c8:	5e                   	pop    %esi
f01011c9:	5f                   	pop    %edi
f01011ca:	5d                   	pop    %ebp
f01011cb:	c3                   	ret    

f01011cc <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011cc:	55                   	push   %ebp
f01011cd:	89 e5                	mov    %esp,%ebp
f01011cf:	53                   	push   %ebx
f01011d0:	83 ec 08             	sub    $0x8,%esp
f01011d3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
f01011d6:	6a 00                	push   $0x0
f01011d8:	ff 75 0c             	pushl  0xc(%ebp)
f01011db:	ff 75 08             	pushl  0x8(%ebp)
f01011de:	e8 a0 fe ff ff       	call   f0101083 <pgdir_walk>
	
	if(!ptEntry) 
f01011e3:	83 c4 10             	add    $0x10,%esp
f01011e6:	85 c0                	test   %eax,%eax
f01011e8:	74 32                	je     f010121c <page_lookup+0x50>
		return NULL;

	if(pte_store)
f01011ea:	85 db                	test   %ebx,%ebx
f01011ec:	74 02                	je     f01011f0 <page_lookup+0x24>
	{
		*pte_store = ptEntry;
f01011ee:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011f0:	8b 00                	mov    (%eax),%eax
f01011f2:	c1 e8 0c             	shr    $0xc,%eax
f01011f5:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01011fb:	72 14                	jb     f0101211 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01011fd:	83 ec 04             	sub    $0x4,%esp
f0101200:	68 f4 65 10 f0       	push   $0xf01065f4
f0101205:	6a 51                	push   $0x51
f0101207:	68 31 6e 10 f0       	push   $0xf0106e31
f010120c:	e8 2f ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101211:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0101217:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
f010121a:	eb 05                	jmp    f0101221 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
	
	if(!ptEntry) 
		return NULL;
f010121c:	b8 00 00 00 00       	mov    $0x0,%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
}
f0101221:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101224:	c9                   	leave  
f0101225:	c3                   	ret    

f0101226 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010122c:	e8 15 46 00 00       	call   f0105846 <cpunum>
f0101231:	6b c0 74             	imul   $0x74,%eax,%eax
f0101234:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010123b:	74 16                	je     f0101253 <tlb_invalidate+0x2d>
f010123d:	e8 04 46 00 00       	call   f0105846 <cpunum>
f0101242:	6b c0 74             	imul   $0x74,%eax,%eax
f0101245:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010124b:	8b 55 08             	mov    0x8(%ebp),%edx
f010124e:	39 50 60             	cmp    %edx,0x60(%eax)
f0101251:	75 06                	jne    f0101259 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101253:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101256:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101259:	c9                   	leave  
f010125a:	c3                   	ret    

f010125b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010125b:	55                   	push   %ebp
f010125c:	89 e5                	mov    %esp,%ebp
f010125e:	56                   	push   %esi
f010125f:	53                   	push   %ebx
f0101260:	83 ec 14             	sub    $0x14,%esp
f0101263:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101266:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *ptEntry = NULL;
f0101269:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &ptEntry);
f0101270:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101273:	50                   	push   %eax
f0101274:	56                   	push   %esi
f0101275:	53                   	push   %ebx
f0101276:	e8 51 ff ff ff       	call   f01011cc <page_lookup>

	if(!page || !(*ptEntry & PTE_P)) 
f010127b:	83 c4 10             	add    $0x10,%esp
f010127e:	85 c0                	test   %eax,%eax
f0101280:	74 27                	je     f01012a9 <page_remove+0x4e>
f0101282:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101285:	f6 02 01             	testb  $0x1,(%edx)
f0101288:	74 1f                	je     f01012a9 <page_remove+0x4e>
		return;

	page_decref(page);
f010128a:	83 ec 0c             	sub    $0xc,%esp
f010128d:	50                   	push   %eax
f010128e:	e8 c9 fd ff ff       	call   f010105c <page_decref>

	*ptEntry = 0;
f0101293:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101296:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	tlb_invalidate(pgdir, va);
f010129c:	83 c4 08             	add    $0x8,%esp
f010129f:	56                   	push   %esi
f01012a0:	53                   	push   %ebx
f01012a1:	e8 80 ff ff ff       	call   f0101226 <tlb_invalidate>
f01012a6:	83 c4 10             	add    $0x10,%esp
}
f01012a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012ac:	5b                   	pop    %ebx
f01012ad:	5e                   	pop    %esi
f01012ae:	5d                   	pop    %ebp
f01012af:	c3                   	ret    

f01012b0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	57                   	push   %edi
f01012b4:	56                   	push   %esi
f01012b5:	53                   	push   %ebx
f01012b6:	83 ec 10             	sub    $0x10,%esp
f01012b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01012bc:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
f01012bf:	6a 01                	push   $0x1
f01012c1:	57                   	push   %edi
f01012c2:	ff 75 08             	pushl  0x8(%ebp)
f01012c5:	e8 b9 fd ff ff       	call   f0101083 <pgdir_walk>
	
	if(!ptEntry) 
f01012ca:	83 c4 10             	add    $0x10,%esp
f01012cd:	85 c0                	test   %eax,%eax
f01012cf:	74 44                	je     f0101315 <page_insert+0x65>
f01012d1:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	
	pp->pp_ref++;
f01012d3:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*ptEntry & PTE_P)
f01012d8:	f6 00 01             	testb  $0x1,(%eax)
f01012db:	74 1b                	je     f01012f8 <page_insert+0x48>
	{
		page_remove(pgdir, va);
f01012dd:	83 ec 08             	sub    $0x8,%esp
f01012e0:	57                   	push   %edi
f01012e1:	ff 75 08             	pushl  0x8(%ebp)
f01012e4:	e8 72 ff ff ff       	call   f010125b <page_remove>
		tlb_invalidate(pgdir, va);
f01012e9:	83 c4 08             	add    $0x8,%esp
f01012ec:	57                   	push   %edi
f01012ed:	ff 75 08             	pushl  0x8(%ebp)
f01012f0:	e8 31 ff ff ff       	call   f0101226 <tlb_invalidate>
f01012f5:	83 c4 10             	add    $0x10,%esp
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;
f01012f8:	2b 1d 90 fe 22 f0    	sub    0xf022fe90,%ebx
f01012fe:	c1 fb 03             	sar    $0x3,%ebx
f0101301:	c1 e3 0c             	shl    $0xc,%ebx
f0101304:	8b 45 14             	mov    0x14(%ebp),%eax
f0101307:	83 c8 01             	or     $0x1,%eax
f010130a:	09 c3                	or     %eax,%ebx
f010130c:	89 1e                	mov    %ebx,(%esi)

	return 0;
f010130e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101313:	eb 05                	jmp    f010131a <page_insert+0x6a>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
	
	if(!ptEntry) 
		return -E_NO_MEM;
f0101315:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;

	return 0;
}
f010131a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010131d:	5b                   	pop    %ebx
f010131e:	5e                   	pop    %esi
f010131f:	5f                   	pop    %edi
f0101320:	5d                   	pop    %ebp
f0101321:	c3                   	ret    

f0101322 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101322:	55                   	push   %ebp
f0101323:	89 e5                	mov    %esp,%ebp
f0101325:	53                   	push   %ebx
f0101326:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f0101329:	8b 45 0c             	mov    0xc(%ebp),%eax
f010132c:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101332:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	if(base + size >= MMIOLIM)
f0101338:	8b 15 00 03 12 f0    	mov    0xf0120300,%edx
f010133e:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101341:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101346:	76 17                	jbe    f010135f <mmio_map_region+0x3d>
		panic("mmio_map_region: Not enough memory!");
f0101348:	83 ec 04             	sub    $0x4,%esp
f010134b:	68 14 66 10 f0       	push   $0xf0106614
f0101350:	68 a4 02 00 00       	push   $0x2a4
f0101355:	68 25 6e 10 f0       	push   $0xf0106e25
f010135a:	e8 e1 ec ff ff       	call   f0100040 <_panic>
	
	boot_map_region(kern_pgdir, base, size, pa, (PTE_PCD | PTE_PWT | PTE_W));
f010135f:	83 ec 08             	sub    $0x8,%esp
f0101362:	6a 1a                	push   $0x1a
f0101364:	ff 75 08             	pushl  0x8(%ebp)
f0101367:	89 d9                	mov    %ebx,%ecx
f0101369:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010136e:	e8 e2 fd ff ff       	call   f0101155 <boot_map_region>

	base += size;
f0101373:	a1 00 03 12 f0       	mov    0xf0120300,%eax
f0101378:	01 c3                	add    %eax,%ebx
f010137a:	89 1d 00 03 12 f0    	mov    %ebx,0xf0120300

	return (void *) (base - size);
	
}
f0101380:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101383:	c9                   	leave  
f0101384:	c3                   	ret    

f0101385 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101385:	55                   	push   %ebp
f0101386:	89 e5                	mov    %esp,%ebp
f0101388:	57                   	push   %edi
f0101389:	56                   	push   %esi
f010138a:	53                   	push   %ebx
f010138b:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010138e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101393:	e8 08 f7 ff ff       	call   f0100aa0 <nvram_read>
f0101398:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010139a:	b8 17 00 00 00       	mov    $0x17,%eax
f010139f:	e8 fc f6 ff ff       	call   f0100aa0 <nvram_read>
f01013a4:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013a6:	b8 34 00 00 00       	mov    $0x34,%eax
f01013ab:	e8 f0 f6 ff ff       	call   f0100aa0 <nvram_read>
f01013b0:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01013b3:	85 c0                	test   %eax,%eax
f01013b5:	74 07                	je     f01013be <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01013b7:	05 00 40 00 00       	add    $0x4000,%eax
f01013bc:	eb 0b                	jmp    f01013c9 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01013be:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013c4:	85 f6                	test   %esi,%esi
f01013c6:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01013c9:	89 c2                	mov    %eax,%edx
f01013cb:	c1 ea 02             	shr    $0x2,%edx
f01013ce:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d4:	89 c2                	mov    %eax,%edx
f01013d6:	29 da                	sub    %ebx,%edx
f01013d8:	52                   	push   %edx
f01013d9:	53                   	push   %ebx
f01013da:	50                   	push   %eax
f01013db:	68 38 66 10 f0       	push   $0xf0106638
f01013e0:	e8 a0 22 00 00       	call   f0103685 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013e5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013ea:	e8 3e f7 ff ff       	call   f0100b2d <boot_alloc>
f01013ef:	a3 8c fe 22 f0       	mov    %eax,0xf022fe8c
	memset(kern_pgdir, 0, PGSIZE);
f01013f4:	83 c4 0c             	add    $0xc,%esp
f01013f7:	68 00 10 00 00       	push   $0x1000
f01013fc:	6a 00                	push   $0x0
f01013fe:	50                   	push   %eax
f01013ff:	e8 21 3e 00 00       	call   f0105225 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101404:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101409:	83 c4 10             	add    $0x10,%esp
f010140c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101411:	77 15                	ja     f0101428 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101413:	50                   	push   %eax
f0101414:	68 28 5f 10 f0       	push   $0xf0105f28
f0101419:	68 a5 00 00 00       	push   $0xa5
f010141e:	68 25 6e 10 f0       	push   $0xf0106e25
f0101423:	e8 18 ec ff ff       	call   f0100040 <_panic>
f0101428:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010142e:	83 ca 05             	or     $0x5,%edx
f0101431:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof(struct PageInfo)*npages);
f0101437:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010143c:	c1 e0 03             	shl    $0x3,%eax
f010143f:	e8 e9 f6 ff ff       	call   f0100b2d <boot_alloc>
f0101444:	a3 90 fe 22 f0       	mov    %eax,0xf022fe90
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f0101449:	83 ec 04             	sub    $0x4,%esp
f010144c:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0101452:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101459:	52                   	push   %edx
f010145a:	6a 00                	push   $0x0
f010145c:	50                   	push   %eax
f010145d:	e8 c3 3d 00 00       	call   f0105225 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f0101462:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101467:	e8 c1 f6 ff ff       	call   f0100b2d <boot_alloc>
f010146c:	a3 44 f2 22 f0       	mov    %eax,0xf022f244
	memset(envs, '\0', sizeof(struct Env) * NENV);
f0101471:	83 c4 0c             	add    $0xc,%esp
f0101474:	68 00 f0 01 00       	push   $0x1f000
f0101479:	6a 00                	push   $0x0
f010147b:	50                   	push   %eax
f010147c:	e8 a4 3d 00 00       	call   f0105225 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101481:	e8 2a fa ff ff       	call   f0100eb0 <page_init>

	check_page_free_list(1);
f0101486:	b8 01 00 00 00       	mov    $0x1,%eax
f010148b:	e8 1e f7 ff ff       	call   f0100bae <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101490:	83 c4 10             	add    $0x10,%esp
f0101493:	83 3d 90 fe 22 f0 00 	cmpl   $0x0,0xf022fe90
f010149a:	75 17                	jne    f01014b3 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f010149c:	83 ec 04             	sub    $0x4,%esp
f010149f:	68 f8 6e 10 f0       	push   $0xf0106ef8
f01014a4:	68 39 03 00 00       	push   $0x339
f01014a9:	68 25 6e 10 f0       	push   $0xf0106e25
f01014ae:	e8 8d eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014b3:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01014b8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014bd:	eb 05                	jmp    f01014c4 <mem_init+0x13f>
		++nfree;
f01014bf:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c2:	8b 00                	mov    (%eax),%eax
f01014c4:	85 c0                	test   %eax,%eax
f01014c6:	75 f7                	jne    f01014bf <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014c8:	83 ec 0c             	sub    $0xc,%esp
f01014cb:	6a 00                	push   $0x0
f01014cd:	e8 df fa ff ff       	call   f0100fb1 <page_alloc>
f01014d2:	89 c7                	mov    %eax,%edi
f01014d4:	83 c4 10             	add    $0x10,%esp
f01014d7:	85 c0                	test   %eax,%eax
f01014d9:	75 19                	jne    f01014f4 <mem_init+0x16f>
f01014db:	68 13 6f 10 f0       	push   $0xf0106f13
f01014e0:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01014e5:	68 41 03 00 00       	push   $0x341
f01014ea:	68 25 6e 10 f0       	push   $0xf0106e25
f01014ef:	e8 4c eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01014f4:	83 ec 0c             	sub    $0xc,%esp
f01014f7:	6a 00                	push   $0x0
f01014f9:	e8 b3 fa ff ff       	call   f0100fb1 <page_alloc>
f01014fe:	89 c6                	mov    %eax,%esi
f0101500:	83 c4 10             	add    $0x10,%esp
f0101503:	85 c0                	test   %eax,%eax
f0101505:	75 19                	jne    f0101520 <mem_init+0x19b>
f0101507:	68 29 6f 10 f0       	push   $0xf0106f29
f010150c:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101511:	68 42 03 00 00       	push   $0x342
f0101516:	68 25 6e 10 f0       	push   $0xf0106e25
f010151b:	e8 20 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101520:	83 ec 0c             	sub    $0xc,%esp
f0101523:	6a 00                	push   $0x0
f0101525:	e8 87 fa ff ff       	call   f0100fb1 <page_alloc>
f010152a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010152d:	83 c4 10             	add    $0x10,%esp
f0101530:	85 c0                	test   %eax,%eax
f0101532:	75 19                	jne    f010154d <mem_init+0x1c8>
f0101534:	68 3f 6f 10 f0       	push   $0xf0106f3f
f0101539:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010153e:	68 43 03 00 00       	push   $0x343
f0101543:	68 25 6e 10 f0       	push   $0xf0106e25
f0101548:	e8 f3 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010154d:	39 f7                	cmp    %esi,%edi
f010154f:	75 19                	jne    f010156a <mem_init+0x1e5>
f0101551:	68 55 6f 10 f0       	push   $0xf0106f55
f0101556:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010155b:	68 46 03 00 00       	push   $0x346
f0101560:	68 25 6e 10 f0       	push   $0xf0106e25
f0101565:	e8 d6 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010156a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010156d:	39 c6                	cmp    %eax,%esi
f010156f:	74 04                	je     f0101575 <mem_init+0x1f0>
f0101571:	39 c7                	cmp    %eax,%edi
f0101573:	75 19                	jne    f010158e <mem_init+0x209>
f0101575:	68 74 66 10 f0       	push   $0xf0106674
f010157a:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010157f:	68 47 03 00 00       	push   $0x347
f0101584:	68 25 6e 10 f0       	push   $0xf0106e25
f0101589:	e8 b2 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010158e:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101594:	8b 15 88 fe 22 f0    	mov    0xf022fe88,%edx
f010159a:	c1 e2 0c             	shl    $0xc,%edx
f010159d:	89 f8                	mov    %edi,%eax
f010159f:	29 c8                	sub    %ecx,%eax
f01015a1:	c1 f8 03             	sar    $0x3,%eax
f01015a4:	c1 e0 0c             	shl    $0xc,%eax
f01015a7:	39 d0                	cmp    %edx,%eax
f01015a9:	72 19                	jb     f01015c4 <mem_init+0x23f>
f01015ab:	68 67 6f 10 f0       	push   $0xf0106f67
f01015b0:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01015b5:	68 48 03 00 00       	push   $0x348
f01015ba:	68 25 6e 10 f0       	push   $0xf0106e25
f01015bf:	e8 7c ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01015c4:	89 f0                	mov    %esi,%eax
f01015c6:	29 c8                	sub    %ecx,%eax
f01015c8:	c1 f8 03             	sar    $0x3,%eax
f01015cb:	c1 e0 0c             	shl    $0xc,%eax
f01015ce:	39 c2                	cmp    %eax,%edx
f01015d0:	77 19                	ja     f01015eb <mem_init+0x266>
f01015d2:	68 84 6f 10 f0       	push   $0xf0106f84
f01015d7:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01015dc:	68 49 03 00 00       	push   $0x349
f01015e1:	68 25 6e 10 f0       	push   $0xf0106e25
f01015e6:	e8 55 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015eb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ee:	29 c8                	sub    %ecx,%eax
f01015f0:	c1 f8 03             	sar    $0x3,%eax
f01015f3:	c1 e0 0c             	shl    $0xc,%eax
f01015f6:	39 c2                	cmp    %eax,%edx
f01015f8:	77 19                	ja     f0101613 <mem_init+0x28e>
f01015fa:	68 a1 6f 10 f0       	push   $0xf0106fa1
f01015ff:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101604:	68 4a 03 00 00       	push   $0x34a
f0101609:	68 25 6e 10 f0       	push   $0xf0106e25
f010160e:	e8 2d ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101613:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101618:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010161b:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101622:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 82 f9 ff ff       	call   f0100fb1 <page_alloc>
f010162f:	83 c4 10             	add    $0x10,%esp
f0101632:	85 c0                	test   %eax,%eax
f0101634:	74 19                	je     f010164f <mem_init+0x2ca>
f0101636:	68 be 6f 10 f0       	push   $0xf0106fbe
f010163b:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101640:	68 51 03 00 00       	push   $0x351
f0101645:	68 25 6e 10 f0       	push   $0xf0106e25
f010164a:	e8 f1 e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010164f:	83 ec 0c             	sub    $0xc,%esp
f0101652:	57                   	push   %edi
f0101653:	e8 c9 f9 ff ff       	call   f0101021 <page_free>
	page_free(pp1);
f0101658:	89 34 24             	mov    %esi,(%esp)
f010165b:	e8 c1 f9 ff ff       	call   f0101021 <page_free>
	page_free(pp2);
f0101660:	83 c4 04             	add    $0x4,%esp
f0101663:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101666:	e8 b6 f9 ff ff       	call   f0101021 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010166b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101672:	e8 3a f9 ff ff       	call   f0100fb1 <page_alloc>
f0101677:	89 c6                	mov    %eax,%esi
f0101679:	83 c4 10             	add    $0x10,%esp
f010167c:	85 c0                	test   %eax,%eax
f010167e:	75 19                	jne    f0101699 <mem_init+0x314>
f0101680:	68 13 6f 10 f0       	push   $0xf0106f13
f0101685:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010168a:	68 58 03 00 00       	push   $0x358
f010168f:	68 25 6e 10 f0       	push   $0xf0106e25
f0101694:	e8 a7 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101699:	83 ec 0c             	sub    $0xc,%esp
f010169c:	6a 00                	push   $0x0
f010169e:	e8 0e f9 ff ff       	call   f0100fb1 <page_alloc>
f01016a3:	89 c7                	mov    %eax,%edi
f01016a5:	83 c4 10             	add    $0x10,%esp
f01016a8:	85 c0                	test   %eax,%eax
f01016aa:	75 19                	jne    f01016c5 <mem_init+0x340>
f01016ac:	68 29 6f 10 f0       	push   $0xf0106f29
f01016b1:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01016b6:	68 59 03 00 00       	push   $0x359
f01016bb:	68 25 6e 10 f0       	push   $0xf0106e25
f01016c0:	e8 7b e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016c5:	83 ec 0c             	sub    $0xc,%esp
f01016c8:	6a 00                	push   $0x0
f01016ca:	e8 e2 f8 ff ff       	call   f0100fb1 <page_alloc>
f01016cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016d2:	83 c4 10             	add    $0x10,%esp
f01016d5:	85 c0                	test   %eax,%eax
f01016d7:	75 19                	jne    f01016f2 <mem_init+0x36d>
f01016d9:	68 3f 6f 10 f0       	push   $0xf0106f3f
f01016de:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01016e3:	68 5a 03 00 00       	push   $0x35a
f01016e8:	68 25 6e 10 f0       	push   $0xf0106e25
f01016ed:	e8 4e e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016f2:	39 fe                	cmp    %edi,%esi
f01016f4:	75 19                	jne    f010170f <mem_init+0x38a>
f01016f6:	68 55 6f 10 f0       	push   $0xf0106f55
f01016fb:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101700:	68 5c 03 00 00       	push   $0x35c
f0101705:	68 25 6e 10 f0       	push   $0xf0106e25
f010170a:	e8 31 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010170f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101712:	39 c7                	cmp    %eax,%edi
f0101714:	74 04                	je     f010171a <mem_init+0x395>
f0101716:	39 c6                	cmp    %eax,%esi
f0101718:	75 19                	jne    f0101733 <mem_init+0x3ae>
f010171a:	68 74 66 10 f0       	push   $0xf0106674
f010171f:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101724:	68 5d 03 00 00       	push   $0x35d
f0101729:	68 25 6e 10 f0       	push   $0xf0106e25
f010172e:	e8 0d e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101733:	83 ec 0c             	sub    $0xc,%esp
f0101736:	6a 00                	push   $0x0
f0101738:	e8 74 f8 ff ff       	call   f0100fb1 <page_alloc>
f010173d:	83 c4 10             	add    $0x10,%esp
f0101740:	85 c0                	test   %eax,%eax
f0101742:	74 19                	je     f010175d <mem_init+0x3d8>
f0101744:	68 be 6f 10 f0       	push   $0xf0106fbe
f0101749:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010174e:	68 5e 03 00 00       	push   $0x35e
f0101753:	68 25 6e 10 f0       	push   $0xf0106e25
f0101758:	e8 e3 e8 ff ff       	call   f0100040 <_panic>
f010175d:	89 f0                	mov    %esi,%eax
f010175f:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101765:	c1 f8 03             	sar    $0x3,%eax
f0101768:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010176b:	89 c2                	mov    %eax,%edx
f010176d:	c1 ea 0c             	shr    $0xc,%edx
f0101770:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101776:	72 12                	jb     f010178a <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101778:	50                   	push   %eax
f0101779:	68 04 5f 10 f0       	push   $0xf0105f04
f010177e:	6a 58                	push   $0x58
f0101780:	68 31 6e 10 f0       	push   $0xf0106e31
f0101785:	e8 b6 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010178a:	83 ec 04             	sub    $0x4,%esp
f010178d:	68 00 10 00 00       	push   $0x1000
f0101792:	6a 01                	push   $0x1
f0101794:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101799:	50                   	push   %eax
f010179a:	e8 86 3a 00 00       	call   f0105225 <memset>
	page_free(pp0);
f010179f:	89 34 24             	mov    %esi,(%esp)
f01017a2:	e8 7a f8 ff ff       	call   f0101021 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017a7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017ae:	e8 fe f7 ff ff       	call   f0100fb1 <page_alloc>
f01017b3:	83 c4 10             	add    $0x10,%esp
f01017b6:	85 c0                	test   %eax,%eax
f01017b8:	75 19                	jne    f01017d3 <mem_init+0x44e>
f01017ba:	68 cd 6f 10 f0       	push   $0xf0106fcd
f01017bf:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01017c4:	68 63 03 00 00       	push   $0x363
f01017c9:	68 25 6e 10 f0       	push   $0xf0106e25
f01017ce:	e8 6d e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01017d3:	39 c6                	cmp    %eax,%esi
f01017d5:	74 19                	je     f01017f0 <mem_init+0x46b>
f01017d7:	68 eb 6f 10 f0       	push   $0xf0106feb
f01017dc:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01017e1:	68 64 03 00 00       	push   $0x364
f01017e6:	68 25 6e 10 f0       	push   $0xf0106e25
f01017eb:	e8 50 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017f0:	89 f0                	mov    %esi,%eax
f01017f2:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01017f8:	c1 f8 03             	sar    $0x3,%eax
f01017fb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017fe:	89 c2                	mov    %eax,%edx
f0101800:	c1 ea 0c             	shr    $0xc,%edx
f0101803:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101809:	72 12                	jb     f010181d <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010180b:	50                   	push   %eax
f010180c:	68 04 5f 10 f0       	push   $0xf0105f04
f0101811:	6a 58                	push   $0x58
f0101813:	68 31 6e 10 f0       	push   $0xf0106e31
f0101818:	e8 23 e8 ff ff       	call   f0100040 <_panic>
f010181d:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101823:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101829:	80 38 00             	cmpb   $0x0,(%eax)
f010182c:	74 19                	je     f0101847 <mem_init+0x4c2>
f010182e:	68 fb 6f 10 f0       	push   $0xf0106ffb
f0101833:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101838:	68 67 03 00 00       	push   $0x367
f010183d:	68 25 6e 10 f0       	push   $0xf0106e25
f0101842:	e8 f9 e7 ff ff       	call   f0100040 <_panic>
f0101847:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010184a:	39 d0                	cmp    %edx,%eax
f010184c:	75 db                	jne    f0101829 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010184e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101851:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	// free the pages we took
	page_free(pp0);
f0101856:	83 ec 0c             	sub    $0xc,%esp
f0101859:	56                   	push   %esi
f010185a:	e8 c2 f7 ff ff       	call   f0101021 <page_free>
	page_free(pp1);
f010185f:	89 3c 24             	mov    %edi,(%esp)
f0101862:	e8 ba f7 ff ff       	call   f0101021 <page_free>
	page_free(pp2);
f0101867:	83 c4 04             	add    $0x4,%esp
f010186a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010186d:	e8 af f7 ff ff       	call   f0101021 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101872:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101877:	83 c4 10             	add    $0x10,%esp
f010187a:	eb 05                	jmp    f0101881 <mem_init+0x4fc>
		--nfree;
f010187c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010187f:	8b 00                	mov    (%eax),%eax
f0101881:	85 c0                	test   %eax,%eax
f0101883:	75 f7                	jne    f010187c <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f0101885:	85 db                	test   %ebx,%ebx
f0101887:	74 19                	je     f01018a2 <mem_init+0x51d>
f0101889:	68 05 70 10 f0       	push   $0xf0107005
f010188e:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101893:	68 74 03 00 00       	push   $0x374
f0101898:	68 25 6e 10 f0       	push   $0xf0106e25
f010189d:	e8 9e e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018a2:	83 ec 0c             	sub    $0xc,%esp
f01018a5:	68 94 66 10 f0       	push   $0xf0106694
f01018aa:	e8 d6 1d 00 00       	call   f0103685 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b6:	e8 f6 f6 ff ff       	call   f0100fb1 <page_alloc>
f01018bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018be:	83 c4 10             	add    $0x10,%esp
f01018c1:	85 c0                	test   %eax,%eax
f01018c3:	75 19                	jne    f01018de <mem_init+0x559>
f01018c5:	68 13 6f 10 f0       	push   $0xf0106f13
f01018ca:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01018cf:	68 da 03 00 00       	push   $0x3da
f01018d4:	68 25 6e 10 f0       	push   $0xf0106e25
f01018d9:	e8 62 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018de:	83 ec 0c             	sub    $0xc,%esp
f01018e1:	6a 00                	push   $0x0
f01018e3:	e8 c9 f6 ff ff       	call   f0100fb1 <page_alloc>
f01018e8:	89 c3                	mov    %eax,%ebx
f01018ea:	83 c4 10             	add    $0x10,%esp
f01018ed:	85 c0                	test   %eax,%eax
f01018ef:	75 19                	jne    f010190a <mem_init+0x585>
f01018f1:	68 29 6f 10 f0       	push   $0xf0106f29
f01018f6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01018fb:	68 db 03 00 00       	push   $0x3db
f0101900:	68 25 6e 10 f0       	push   $0xf0106e25
f0101905:	e8 36 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010190a:	83 ec 0c             	sub    $0xc,%esp
f010190d:	6a 00                	push   $0x0
f010190f:	e8 9d f6 ff ff       	call   f0100fb1 <page_alloc>
f0101914:	89 c6                	mov    %eax,%esi
f0101916:	83 c4 10             	add    $0x10,%esp
f0101919:	85 c0                	test   %eax,%eax
f010191b:	75 19                	jne    f0101936 <mem_init+0x5b1>
f010191d:	68 3f 6f 10 f0       	push   $0xf0106f3f
f0101922:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101927:	68 dc 03 00 00       	push   $0x3dc
f010192c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101931:	e8 0a e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101936:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101939:	75 19                	jne    f0101954 <mem_init+0x5cf>
f010193b:	68 55 6f 10 f0       	push   $0xf0106f55
f0101940:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101945:	68 df 03 00 00       	push   $0x3df
f010194a:	68 25 6e 10 f0       	push   $0xf0106e25
f010194f:	e8 ec e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101954:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101957:	74 04                	je     f010195d <mem_init+0x5d8>
f0101959:	39 c3                	cmp    %eax,%ebx
f010195b:	75 19                	jne    f0101976 <mem_init+0x5f1>
f010195d:	68 74 66 10 f0       	push   $0xf0106674
f0101962:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101967:	68 e0 03 00 00       	push   $0x3e0
f010196c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101971:	e8 ca e6 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101976:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f010197b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010197e:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101985:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101988:	83 ec 0c             	sub    $0xc,%esp
f010198b:	6a 00                	push   $0x0
f010198d:	e8 1f f6 ff ff       	call   f0100fb1 <page_alloc>
f0101992:	83 c4 10             	add    $0x10,%esp
f0101995:	85 c0                	test   %eax,%eax
f0101997:	74 19                	je     f01019b2 <mem_init+0x62d>
f0101999:	68 be 6f 10 f0       	push   $0xf0106fbe
f010199e:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01019a3:	68 e7 03 00 00       	push   $0x3e7
f01019a8:	68 25 6e 10 f0       	push   $0xf0106e25
f01019ad:	e8 8e e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019b2:	83 ec 04             	sub    $0x4,%esp
f01019b5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019b8:	50                   	push   %eax
f01019b9:	6a 00                	push   $0x0
f01019bb:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01019c1:	e8 06 f8 ff ff       	call   f01011cc <page_lookup>
f01019c6:	83 c4 10             	add    $0x10,%esp
f01019c9:	85 c0                	test   %eax,%eax
f01019cb:	74 19                	je     f01019e6 <mem_init+0x661>
f01019cd:	68 b4 66 10 f0       	push   $0xf01066b4
f01019d2:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01019d7:	68 ea 03 00 00       	push   $0x3ea
f01019dc:	68 25 6e 10 f0       	push   $0xf0106e25
f01019e1:	e8 5a e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019e6:	6a 02                	push   $0x2
f01019e8:	6a 00                	push   $0x0
f01019ea:	53                   	push   %ebx
f01019eb:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01019f1:	e8 ba f8 ff ff       	call   f01012b0 <page_insert>
f01019f6:	83 c4 10             	add    $0x10,%esp
f01019f9:	85 c0                	test   %eax,%eax
f01019fb:	78 19                	js     f0101a16 <mem_init+0x691>
f01019fd:	68 ec 66 10 f0       	push   $0xf01066ec
f0101a02:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101a07:	68 ed 03 00 00       	push   $0x3ed
f0101a0c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101a11:	e8 2a e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a16:	83 ec 0c             	sub    $0xc,%esp
f0101a19:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a1c:	e8 00 f6 ff ff       	call   f0101021 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a21:	6a 02                	push   $0x2
f0101a23:	6a 00                	push   $0x0
f0101a25:	53                   	push   %ebx
f0101a26:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101a2c:	e8 7f f8 ff ff       	call   f01012b0 <page_insert>
f0101a31:	83 c4 20             	add    $0x20,%esp
f0101a34:	85 c0                	test   %eax,%eax
f0101a36:	74 19                	je     f0101a51 <mem_init+0x6cc>
f0101a38:	68 1c 67 10 f0       	push   $0xf010671c
f0101a3d:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101a42:	68 f1 03 00 00       	push   $0x3f1
f0101a47:	68 25 6e 10 f0       	push   $0xf0106e25
f0101a4c:	e8 ef e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a51:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a57:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0101a5c:	89 c1                	mov    %eax,%ecx
f0101a5e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a61:	8b 17                	mov    (%edi),%edx
f0101a63:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a6c:	29 c8                	sub    %ecx,%eax
f0101a6e:	c1 f8 03             	sar    $0x3,%eax
f0101a71:	c1 e0 0c             	shl    $0xc,%eax
f0101a74:	39 c2                	cmp    %eax,%edx
f0101a76:	74 19                	je     f0101a91 <mem_init+0x70c>
f0101a78:	68 4c 67 10 f0       	push   $0xf010674c
f0101a7d:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101a82:	68 f2 03 00 00       	push   $0x3f2
f0101a87:	68 25 6e 10 f0       	push   $0xf0106e25
f0101a8c:	e8 af e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a91:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a96:	89 f8                	mov    %edi,%eax
f0101a98:	e8 2c f0 ff ff       	call   f0100ac9 <check_va2pa>
f0101a9d:	89 da                	mov    %ebx,%edx
f0101a9f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101aa2:	c1 fa 03             	sar    $0x3,%edx
f0101aa5:	c1 e2 0c             	shl    $0xc,%edx
f0101aa8:	39 d0                	cmp    %edx,%eax
f0101aaa:	74 19                	je     f0101ac5 <mem_init+0x740>
f0101aac:	68 74 67 10 f0       	push   $0xf0106774
f0101ab1:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101ab6:	68 f3 03 00 00       	push   $0x3f3
f0101abb:	68 25 6e 10 f0       	push   $0xf0106e25
f0101ac0:	e8 7b e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ac5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101aca:	74 19                	je     f0101ae5 <mem_init+0x760>
f0101acc:	68 10 70 10 f0       	push   $0xf0107010
f0101ad1:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101ad6:	68 f4 03 00 00       	push   $0x3f4
f0101adb:	68 25 6e 10 f0       	push   $0xf0106e25
f0101ae0:	e8 5b e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101ae5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aed:	74 19                	je     f0101b08 <mem_init+0x783>
f0101aef:	68 21 70 10 f0       	push   $0xf0107021
f0101af4:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101af9:	68 f5 03 00 00       	push   $0x3f5
f0101afe:	68 25 6e 10 f0       	push   $0xf0106e25
f0101b03:	e8 38 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b08:	6a 02                	push   $0x2
f0101b0a:	68 00 10 00 00       	push   $0x1000
f0101b0f:	56                   	push   %esi
f0101b10:	57                   	push   %edi
f0101b11:	e8 9a f7 ff ff       	call   f01012b0 <page_insert>
f0101b16:	83 c4 10             	add    $0x10,%esp
f0101b19:	85 c0                	test   %eax,%eax
f0101b1b:	74 19                	je     f0101b36 <mem_init+0x7b1>
f0101b1d:	68 a4 67 10 f0       	push   $0xf01067a4
f0101b22:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101b27:	68 f8 03 00 00       	push   $0x3f8
f0101b2c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101b31:	e8 0a e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b36:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b3b:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101b40:	e8 84 ef ff ff       	call   f0100ac9 <check_va2pa>
f0101b45:	89 f2                	mov    %esi,%edx
f0101b47:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101b4d:	c1 fa 03             	sar    $0x3,%edx
f0101b50:	c1 e2 0c             	shl    $0xc,%edx
f0101b53:	39 d0                	cmp    %edx,%eax
f0101b55:	74 19                	je     f0101b70 <mem_init+0x7eb>
f0101b57:	68 e0 67 10 f0       	push   $0xf01067e0
f0101b5c:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101b61:	68 f9 03 00 00       	push   $0x3f9
f0101b66:	68 25 6e 10 f0       	push   $0xf0106e25
f0101b6b:	e8 d0 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b70:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b75:	74 19                	je     f0101b90 <mem_init+0x80b>
f0101b77:	68 32 70 10 f0       	push   $0xf0107032
f0101b7c:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101b81:	68 fa 03 00 00       	push   $0x3fa
f0101b86:	68 25 6e 10 f0       	push   $0xf0106e25
f0101b8b:	e8 b0 e4 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b90:	83 ec 0c             	sub    $0xc,%esp
f0101b93:	6a 00                	push   $0x0
f0101b95:	e8 17 f4 ff ff       	call   f0100fb1 <page_alloc>
f0101b9a:	83 c4 10             	add    $0x10,%esp
f0101b9d:	85 c0                	test   %eax,%eax
f0101b9f:	74 19                	je     f0101bba <mem_init+0x835>
f0101ba1:	68 be 6f 10 f0       	push   $0xf0106fbe
f0101ba6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101bab:	68 fd 03 00 00       	push   $0x3fd
f0101bb0:	68 25 6e 10 f0       	push   $0xf0106e25
f0101bb5:	e8 86 e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bba:	6a 02                	push   $0x2
f0101bbc:	68 00 10 00 00       	push   $0x1000
f0101bc1:	56                   	push   %esi
f0101bc2:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101bc8:	e8 e3 f6 ff ff       	call   f01012b0 <page_insert>
f0101bcd:	83 c4 10             	add    $0x10,%esp
f0101bd0:	85 c0                	test   %eax,%eax
f0101bd2:	74 19                	je     f0101bed <mem_init+0x868>
f0101bd4:	68 a4 67 10 f0       	push   $0xf01067a4
f0101bd9:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101bde:	68 00 04 00 00       	push   $0x400
f0101be3:	68 25 6e 10 f0       	push   $0xf0106e25
f0101be8:	e8 53 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bed:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bf2:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101bf7:	e8 cd ee ff ff       	call   f0100ac9 <check_va2pa>
f0101bfc:	89 f2                	mov    %esi,%edx
f0101bfe:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101c04:	c1 fa 03             	sar    $0x3,%edx
f0101c07:	c1 e2 0c             	shl    $0xc,%edx
f0101c0a:	39 d0                	cmp    %edx,%eax
f0101c0c:	74 19                	je     f0101c27 <mem_init+0x8a2>
f0101c0e:	68 e0 67 10 f0       	push   $0xf01067e0
f0101c13:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101c18:	68 01 04 00 00       	push   $0x401
f0101c1d:	68 25 6e 10 f0       	push   $0xf0106e25
f0101c22:	e8 19 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c27:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c2c:	74 19                	je     f0101c47 <mem_init+0x8c2>
f0101c2e:	68 32 70 10 f0       	push   $0xf0107032
f0101c33:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101c38:	68 02 04 00 00       	push   $0x402
f0101c3d:	68 25 6e 10 f0       	push   $0xf0106e25
f0101c42:	e8 f9 e3 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c47:	83 ec 0c             	sub    $0xc,%esp
f0101c4a:	6a 00                	push   $0x0
f0101c4c:	e8 60 f3 ff ff       	call   f0100fb1 <page_alloc>
f0101c51:	83 c4 10             	add    $0x10,%esp
f0101c54:	85 c0                	test   %eax,%eax
f0101c56:	74 19                	je     f0101c71 <mem_init+0x8ec>
f0101c58:	68 be 6f 10 f0       	push   $0xf0106fbe
f0101c5d:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101c62:	68 06 04 00 00       	push   $0x406
f0101c67:	68 25 6e 10 f0       	push   $0xf0106e25
f0101c6c:	e8 cf e3 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c71:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0101c77:	8b 02                	mov    (%edx),%eax
f0101c79:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c7e:	89 c1                	mov    %eax,%ecx
f0101c80:	c1 e9 0c             	shr    $0xc,%ecx
f0101c83:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0101c89:	72 15                	jb     f0101ca0 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c8b:	50                   	push   %eax
f0101c8c:	68 04 5f 10 f0       	push   $0xf0105f04
f0101c91:	68 09 04 00 00       	push   $0x409
f0101c96:	68 25 6e 10 f0       	push   $0xf0106e25
f0101c9b:	e8 a0 e3 ff ff       	call   f0100040 <_panic>
f0101ca0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ca5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101ca8:	83 ec 04             	sub    $0x4,%esp
f0101cab:	6a 00                	push   $0x0
f0101cad:	68 00 10 00 00       	push   $0x1000
f0101cb2:	52                   	push   %edx
f0101cb3:	e8 cb f3 ff ff       	call   f0101083 <pgdir_walk>
f0101cb8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101cbb:	8d 51 04             	lea    0x4(%ecx),%edx
f0101cbe:	83 c4 10             	add    $0x10,%esp
f0101cc1:	39 d0                	cmp    %edx,%eax
f0101cc3:	74 19                	je     f0101cde <mem_init+0x959>
f0101cc5:	68 10 68 10 f0       	push   $0xf0106810
f0101cca:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101ccf:	68 0a 04 00 00       	push   $0x40a
f0101cd4:	68 25 6e 10 f0       	push   $0xf0106e25
f0101cd9:	e8 62 e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cde:	6a 06                	push   $0x6
f0101ce0:	68 00 10 00 00       	push   $0x1000
f0101ce5:	56                   	push   %esi
f0101ce6:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101cec:	e8 bf f5 ff ff       	call   f01012b0 <page_insert>
f0101cf1:	83 c4 10             	add    $0x10,%esp
f0101cf4:	85 c0                	test   %eax,%eax
f0101cf6:	74 19                	je     f0101d11 <mem_init+0x98c>
f0101cf8:	68 50 68 10 f0       	push   $0xf0106850
f0101cfd:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101d02:	68 0d 04 00 00       	push   $0x40d
f0101d07:	68 25 6e 10 f0       	push   $0xf0106e25
f0101d0c:	e8 2f e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d11:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101d17:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d1c:	89 f8                	mov    %edi,%eax
f0101d1e:	e8 a6 ed ff ff       	call   f0100ac9 <check_va2pa>
f0101d23:	89 f2                	mov    %esi,%edx
f0101d25:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101d2b:	c1 fa 03             	sar    $0x3,%edx
f0101d2e:	c1 e2 0c             	shl    $0xc,%edx
f0101d31:	39 d0                	cmp    %edx,%eax
f0101d33:	74 19                	je     f0101d4e <mem_init+0x9c9>
f0101d35:	68 e0 67 10 f0       	push   $0xf01067e0
f0101d3a:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101d3f:	68 0e 04 00 00       	push   $0x40e
f0101d44:	68 25 6e 10 f0       	push   $0xf0106e25
f0101d49:	e8 f2 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d4e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d53:	74 19                	je     f0101d6e <mem_init+0x9e9>
f0101d55:	68 32 70 10 f0       	push   $0xf0107032
f0101d5a:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101d5f:	68 0f 04 00 00       	push   $0x40f
f0101d64:	68 25 6e 10 f0       	push   $0xf0106e25
f0101d69:	e8 d2 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d6e:	83 ec 04             	sub    $0x4,%esp
f0101d71:	6a 00                	push   $0x0
f0101d73:	68 00 10 00 00       	push   $0x1000
f0101d78:	57                   	push   %edi
f0101d79:	e8 05 f3 ff ff       	call   f0101083 <pgdir_walk>
f0101d7e:	83 c4 10             	add    $0x10,%esp
f0101d81:	f6 00 04             	testb  $0x4,(%eax)
f0101d84:	75 19                	jne    f0101d9f <mem_init+0xa1a>
f0101d86:	68 90 68 10 f0       	push   $0xf0106890
f0101d8b:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101d90:	68 10 04 00 00       	push   $0x410
f0101d95:	68 25 6e 10 f0       	push   $0xf0106e25
f0101d9a:	e8 a1 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d9f:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101da4:	f6 00 04             	testb  $0x4,(%eax)
f0101da7:	75 19                	jne    f0101dc2 <mem_init+0xa3d>
f0101da9:	68 43 70 10 f0       	push   $0xf0107043
f0101dae:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101db3:	68 11 04 00 00       	push   $0x411
f0101db8:	68 25 6e 10 f0       	push   $0xf0106e25
f0101dbd:	e8 7e e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101dc2:	6a 02                	push   $0x2
f0101dc4:	68 00 10 00 00       	push   $0x1000
f0101dc9:	56                   	push   %esi
f0101dca:	50                   	push   %eax
f0101dcb:	e8 e0 f4 ff ff       	call   f01012b0 <page_insert>
f0101dd0:	83 c4 10             	add    $0x10,%esp
f0101dd3:	85 c0                	test   %eax,%eax
f0101dd5:	74 19                	je     f0101df0 <mem_init+0xa6b>
f0101dd7:	68 a4 67 10 f0       	push   $0xf01067a4
f0101ddc:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101de1:	68 14 04 00 00       	push   $0x414
f0101de6:	68 25 6e 10 f0       	push   $0xf0106e25
f0101deb:	e8 50 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101df0:	83 ec 04             	sub    $0x4,%esp
f0101df3:	6a 00                	push   $0x0
f0101df5:	68 00 10 00 00       	push   $0x1000
f0101dfa:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e00:	e8 7e f2 ff ff       	call   f0101083 <pgdir_walk>
f0101e05:	83 c4 10             	add    $0x10,%esp
f0101e08:	f6 00 02             	testb  $0x2,(%eax)
f0101e0b:	75 19                	jne    f0101e26 <mem_init+0xaa1>
f0101e0d:	68 c4 68 10 f0       	push   $0xf01068c4
f0101e12:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101e17:	68 15 04 00 00       	push   $0x415
f0101e1c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101e21:	e8 1a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e26:	83 ec 04             	sub    $0x4,%esp
f0101e29:	6a 00                	push   $0x0
f0101e2b:	68 00 10 00 00       	push   $0x1000
f0101e30:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e36:	e8 48 f2 ff ff       	call   f0101083 <pgdir_walk>
f0101e3b:	83 c4 10             	add    $0x10,%esp
f0101e3e:	f6 00 04             	testb  $0x4,(%eax)
f0101e41:	74 19                	je     f0101e5c <mem_init+0xad7>
f0101e43:	68 f8 68 10 f0       	push   $0xf01068f8
f0101e48:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101e4d:	68 16 04 00 00       	push   $0x416
f0101e52:	68 25 6e 10 f0       	push   $0xf0106e25
f0101e57:	e8 e4 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e5c:	6a 02                	push   $0x2
f0101e5e:	68 00 00 40 00       	push   $0x400000
f0101e63:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e66:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e6c:	e8 3f f4 ff ff       	call   f01012b0 <page_insert>
f0101e71:	83 c4 10             	add    $0x10,%esp
f0101e74:	85 c0                	test   %eax,%eax
f0101e76:	78 19                	js     f0101e91 <mem_init+0xb0c>
f0101e78:	68 30 69 10 f0       	push   $0xf0106930
f0101e7d:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101e82:	68 19 04 00 00       	push   $0x419
f0101e87:	68 25 6e 10 f0       	push   $0xf0106e25
f0101e8c:	e8 af e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e91:	6a 02                	push   $0x2
f0101e93:	68 00 10 00 00       	push   $0x1000
f0101e98:	53                   	push   %ebx
f0101e99:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e9f:	e8 0c f4 ff ff       	call   f01012b0 <page_insert>
f0101ea4:	83 c4 10             	add    $0x10,%esp
f0101ea7:	85 c0                	test   %eax,%eax
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xb3f>
f0101eab:	68 68 69 10 f0       	push   $0xf0106968
f0101eb0:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101eb5:	68 1c 04 00 00       	push   $0x41c
f0101eba:	68 25 6e 10 f0       	push   $0xf0106e25
f0101ebf:	e8 7c e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ec4:	83 ec 04             	sub    $0x4,%esp
f0101ec7:	6a 00                	push   $0x0
f0101ec9:	68 00 10 00 00       	push   $0x1000
f0101ece:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101ed4:	e8 aa f1 ff ff       	call   f0101083 <pgdir_walk>
f0101ed9:	83 c4 10             	add    $0x10,%esp
f0101edc:	f6 00 04             	testb  $0x4,(%eax)
f0101edf:	74 19                	je     f0101efa <mem_init+0xb75>
f0101ee1:	68 f8 68 10 f0       	push   $0xf01068f8
f0101ee6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101eeb:	68 1d 04 00 00       	push   $0x41d
f0101ef0:	68 25 6e 10 f0       	push   $0xf0106e25
f0101ef5:	e8 46 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101efa:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101f00:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f05:	89 f8                	mov    %edi,%eax
f0101f07:	e8 bd eb ff ff       	call   f0100ac9 <check_va2pa>
f0101f0c:	89 c1                	mov    %eax,%ecx
f0101f0e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f11:	89 d8                	mov    %ebx,%eax
f0101f13:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101f19:	c1 f8 03             	sar    $0x3,%eax
f0101f1c:	c1 e0 0c             	shl    $0xc,%eax
f0101f1f:	39 c1                	cmp    %eax,%ecx
f0101f21:	74 19                	je     f0101f3c <mem_init+0xbb7>
f0101f23:	68 a4 69 10 f0       	push   $0xf01069a4
f0101f28:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101f2d:	68 20 04 00 00       	push   $0x420
f0101f32:	68 25 6e 10 f0       	push   $0xf0106e25
f0101f37:	e8 04 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f3c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f41:	89 f8                	mov    %edi,%eax
f0101f43:	e8 81 eb ff ff       	call   f0100ac9 <check_va2pa>
f0101f48:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101f4b:	74 19                	je     f0101f66 <mem_init+0xbe1>
f0101f4d:	68 d0 69 10 f0       	push   $0xf01069d0
f0101f52:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101f57:	68 21 04 00 00       	push   $0x421
f0101f5c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101f61:	e8 da e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f66:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f6b:	74 19                	je     f0101f86 <mem_init+0xc01>
f0101f6d:	68 59 70 10 f0       	push   $0xf0107059
f0101f72:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101f77:	68 23 04 00 00       	push   $0x423
f0101f7c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101f81:	e8 ba e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f86:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f8b:	74 19                	je     f0101fa6 <mem_init+0xc21>
f0101f8d:	68 6a 70 10 f0       	push   $0xf010706a
f0101f92:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101f97:	68 24 04 00 00       	push   $0x424
f0101f9c:	68 25 6e 10 f0       	push   $0xf0106e25
f0101fa1:	e8 9a e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101fa6:	83 ec 0c             	sub    $0xc,%esp
f0101fa9:	6a 00                	push   $0x0
f0101fab:	e8 01 f0 ff ff       	call   f0100fb1 <page_alloc>
f0101fb0:	83 c4 10             	add    $0x10,%esp
f0101fb3:	39 c6                	cmp    %eax,%esi
f0101fb5:	75 04                	jne    f0101fbb <mem_init+0xc36>
f0101fb7:	85 c0                	test   %eax,%eax
f0101fb9:	75 19                	jne    f0101fd4 <mem_init+0xc4f>
f0101fbb:	68 00 6a 10 f0       	push   $0xf0106a00
f0101fc0:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0101fc5:	68 27 04 00 00       	push   $0x427
f0101fca:	68 25 6e 10 f0       	push   $0xf0106e25
f0101fcf:	e8 6c e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101fd4:	83 ec 08             	sub    $0x8,%esp
f0101fd7:	6a 00                	push   $0x0
f0101fd9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101fdf:	e8 77 f2 ff ff       	call   f010125b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fe4:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101fea:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fef:	89 f8                	mov    %edi,%eax
f0101ff1:	e8 d3 ea ff ff       	call   f0100ac9 <check_va2pa>
f0101ff6:	83 c4 10             	add    $0x10,%esp
f0101ff9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ffc:	74 19                	je     f0102017 <mem_init+0xc92>
f0101ffe:	68 24 6a 10 f0       	push   $0xf0106a24
f0102003:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102008:	68 2b 04 00 00       	push   $0x42b
f010200d:	68 25 6e 10 f0       	push   $0xf0106e25
f0102012:	e8 29 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102017:	ba 00 10 00 00       	mov    $0x1000,%edx
f010201c:	89 f8                	mov    %edi,%eax
f010201e:	e8 a6 ea ff ff       	call   f0100ac9 <check_va2pa>
f0102023:	89 da                	mov    %ebx,%edx
f0102025:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f010202b:	c1 fa 03             	sar    $0x3,%edx
f010202e:	c1 e2 0c             	shl    $0xc,%edx
f0102031:	39 d0                	cmp    %edx,%eax
f0102033:	74 19                	je     f010204e <mem_init+0xcc9>
f0102035:	68 d0 69 10 f0       	push   $0xf01069d0
f010203a:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010203f:	68 2c 04 00 00       	push   $0x42c
f0102044:	68 25 6e 10 f0       	push   $0xf0106e25
f0102049:	e8 f2 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010204e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102053:	74 19                	je     f010206e <mem_init+0xce9>
f0102055:	68 10 70 10 f0       	push   $0xf0107010
f010205a:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010205f:	68 2d 04 00 00       	push   $0x42d
f0102064:	68 25 6e 10 f0       	push   $0xf0106e25
f0102069:	e8 d2 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010206e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102073:	74 19                	je     f010208e <mem_init+0xd09>
f0102075:	68 6a 70 10 f0       	push   $0xf010706a
f010207a:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010207f:	68 2e 04 00 00       	push   $0x42e
f0102084:	68 25 6e 10 f0       	push   $0xf0106e25
f0102089:	e8 b2 df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010208e:	6a 00                	push   $0x0
f0102090:	68 00 10 00 00       	push   $0x1000
f0102095:	53                   	push   %ebx
f0102096:	57                   	push   %edi
f0102097:	e8 14 f2 ff ff       	call   f01012b0 <page_insert>
f010209c:	83 c4 10             	add    $0x10,%esp
f010209f:	85 c0                	test   %eax,%eax
f01020a1:	74 19                	je     f01020bc <mem_init+0xd37>
f01020a3:	68 48 6a 10 f0       	push   $0xf0106a48
f01020a8:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01020ad:	68 31 04 00 00       	push   $0x431
f01020b2:	68 25 6e 10 f0       	push   $0xf0106e25
f01020b7:	e8 84 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01020bc:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020c1:	75 19                	jne    f01020dc <mem_init+0xd57>
f01020c3:	68 7b 70 10 f0       	push   $0xf010707b
f01020c8:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01020cd:	68 32 04 00 00       	push   $0x432
f01020d2:	68 25 6e 10 f0       	push   $0xf0106e25
f01020d7:	e8 64 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01020dc:	83 3b 00             	cmpl   $0x0,(%ebx)
f01020df:	74 19                	je     f01020fa <mem_init+0xd75>
f01020e1:	68 87 70 10 f0       	push   $0xf0107087
f01020e6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01020eb:	68 33 04 00 00       	push   $0x433
f01020f0:	68 25 6e 10 f0       	push   $0xf0106e25
f01020f5:	e8 46 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020fa:	83 ec 08             	sub    $0x8,%esp
f01020fd:	68 00 10 00 00       	push   $0x1000
f0102102:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102108:	e8 4e f1 ff ff       	call   f010125b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010210d:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0102113:	ba 00 00 00 00       	mov    $0x0,%edx
f0102118:	89 f8                	mov    %edi,%eax
f010211a:	e8 aa e9 ff ff       	call   f0100ac9 <check_va2pa>
f010211f:	83 c4 10             	add    $0x10,%esp
f0102122:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102125:	74 19                	je     f0102140 <mem_init+0xdbb>
f0102127:	68 24 6a 10 f0       	push   $0xf0106a24
f010212c:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102131:	68 37 04 00 00       	push   $0x437
f0102136:	68 25 6e 10 f0       	push   $0xf0106e25
f010213b:	e8 00 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102140:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102145:	89 f8                	mov    %edi,%eax
f0102147:	e8 7d e9 ff ff       	call   f0100ac9 <check_va2pa>
f010214c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010214f:	74 19                	je     f010216a <mem_init+0xde5>
f0102151:	68 80 6a 10 f0       	push   $0xf0106a80
f0102156:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010215b:	68 38 04 00 00       	push   $0x438
f0102160:	68 25 6e 10 f0       	push   $0xf0106e25
f0102165:	e8 d6 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010216a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010216f:	74 19                	je     f010218a <mem_init+0xe05>
f0102171:	68 9c 70 10 f0       	push   $0xf010709c
f0102176:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010217b:	68 39 04 00 00       	push   $0x439
f0102180:	68 25 6e 10 f0       	push   $0xf0106e25
f0102185:	e8 b6 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010218a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010218f:	74 19                	je     f01021aa <mem_init+0xe25>
f0102191:	68 6a 70 10 f0       	push   $0xf010706a
f0102196:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010219b:	68 3a 04 00 00       	push   $0x43a
f01021a0:	68 25 6e 10 f0       	push   $0xf0106e25
f01021a5:	e8 96 de ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01021aa:	83 ec 0c             	sub    $0xc,%esp
f01021ad:	6a 00                	push   $0x0
f01021af:	e8 fd ed ff ff       	call   f0100fb1 <page_alloc>
f01021b4:	83 c4 10             	add    $0x10,%esp
f01021b7:	85 c0                	test   %eax,%eax
f01021b9:	74 04                	je     f01021bf <mem_init+0xe3a>
f01021bb:	39 c3                	cmp    %eax,%ebx
f01021bd:	74 19                	je     f01021d8 <mem_init+0xe53>
f01021bf:	68 a8 6a 10 f0       	push   $0xf0106aa8
f01021c4:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01021c9:	68 3d 04 00 00       	push   $0x43d
f01021ce:	68 25 6e 10 f0       	push   $0xf0106e25
f01021d3:	e8 68 de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021d8:	83 ec 0c             	sub    $0xc,%esp
f01021db:	6a 00                	push   $0x0
f01021dd:	e8 cf ed ff ff       	call   f0100fb1 <page_alloc>
f01021e2:	83 c4 10             	add    $0x10,%esp
f01021e5:	85 c0                	test   %eax,%eax
f01021e7:	74 19                	je     f0102202 <mem_init+0xe7d>
f01021e9:	68 be 6f 10 f0       	push   $0xf0106fbe
f01021ee:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01021f3:	68 40 04 00 00       	push   $0x440
f01021f8:	68 25 6e 10 f0       	push   $0xf0106e25
f01021fd:	e8 3e de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102202:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102208:	8b 11                	mov    (%ecx),%edx
f010220a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102210:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102213:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102219:	c1 f8 03             	sar    $0x3,%eax
f010221c:	c1 e0 0c             	shl    $0xc,%eax
f010221f:	39 c2                	cmp    %eax,%edx
f0102221:	74 19                	je     f010223c <mem_init+0xeb7>
f0102223:	68 4c 67 10 f0       	push   $0xf010674c
f0102228:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010222d:	68 43 04 00 00       	push   $0x443
f0102232:	68 25 6e 10 f0       	push   $0xf0106e25
f0102237:	e8 04 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010223c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102242:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102245:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010224a:	74 19                	je     f0102265 <mem_init+0xee0>
f010224c:	68 21 70 10 f0       	push   $0xf0107021
f0102251:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102256:	68 45 04 00 00       	push   $0x445
f010225b:	68 25 6e 10 f0       	push   $0xf0106e25
f0102260:	e8 db dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102265:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102268:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010226e:	83 ec 0c             	sub    $0xc,%esp
f0102271:	50                   	push   %eax
f0102272:	e8 aa ed ff ff       	call   f0101021 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102277:	83 c4 0c             	add    $0xc,%esp
f010227a:	6a 01                	push   $0x1
f010227c:	68 00 10 40 00       	push   $0x401000
f0102281:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102287:	e8 f7 ed ff ff       	call   f0101083 <pgdir_walk>
f010228c:	89 c7                	mov    %eax,%edi
f010228e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102291:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102296:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102299:	8b 40 04             	mov    0x4(%eax),%eax
f010229c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022a1:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01022a7:	89 c2                	mov    %eax,%edx
f01022a9:	c1 ea 0c             	shr    $0xc,%edx
f01022ac:	83 c4 10             	add    $0x10,%esp
f01022af:	39 ca                	cmp    %ecx,%edx
f01022b1:	72 15                	jb     f01022c8 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022b3:	50                   	push   %eax
f01022b4:	68 04 5f 10 f0       	push   $0xf0105f04
f01022b9:	68 4c 04 00 00       	push   $0x44c
f01022be:	68 25 6e 10 f0       	push   $0xf0106e25
f01022c3:	e8 78 dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01022c8:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01022cd:	39 c7                	cmp    %eax,%edi
f01022cf:	74 19                	je     f01022ea <mem_init+0xf65>
f01022d1:	68 ad 70 10 f0       	push   $0xf01070ad
f01022d6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01022db:	68 4d 04 00 00       	push   $0x44d
f01022e0:	68 25 6e 10 f0       	push   $0xf0106e25
f01022e5:	e8 56 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01022ea:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01022ed:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01022f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022fd:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102303:	c1 f8 03             	sar    $0x3,%eax
f0102306:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102309:	89 c2                	mov    %eax,%edx
f010230b:	c1 ea 0c             	shr    $0xc,%edx
f010230e:	39 d1                	cmp    %edx,%ecx
f0102310:	77 12                	ja     f0102324 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102312:	50                   	push   %eax
f0102313:	68 04 5f 10 f0       	push   $0xf0105f04
f0102318:	6a 58                	push   $0x58
f010231a:	68 31 6e 10 f0       	push   $0xf0106e31
f010231f:	e8 1c dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102324:	83 ec 04             	sub    $0x4,%esp
f0102327:	68 00 10 00 00       	push   $0x1000
f010232c:	68 ff 00 00 00       	push   $0xff
f0102331:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102336:	50                   	push   %eax
f0102337:	e8 e9 2e 00 00       	call   f0105225 <memset>
	page_free(pp0);
f010233c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010233f:	89 3c 24             	mov    %edi,(%esp)
f0102342:	e8 da ec ff ff       	call   f0101021 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102347:	83 c4 0c             	add    $0xc,%esp
f010234a:	6a 01                	push   $0x1
f010234c:	6a 00                	push   $0x0
f010234e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102354:	e8 2a ed ff ff       	call   f0101083 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102359:	89 fa                	mov    %edi,%edx
f010235b:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0102361:	c1 fa 03             	sar    $0x3,%edx
f0102364:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102367:	89 d0                	mov    %edx,%eax
f0102369:	c1 e8 0c             	shr    $0xc,%eax
f010236c:	83 c4 10             	add    $0x10,%esp
f010236f:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0102375:	72 12                	jb     f0102389 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102377:	52                   	push   %edx
f0102378:	68 04 5f 10 f0       	push   $0xf0105f04
f010237d:	6a 58                	push   $0x58
f010237f:	68 31 6e 10 f0       	push   $0xf0106e31
f0102384:	e8 b7 dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102389:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010238f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102392:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102398:	f6 00 01             	testb  $0x1,(%eax)
f010239b:	74 19                	je     f01023b6 <mem_init+0x1031>
f010239d:	68 c5 70 10 f0       	push   $0xf01070c5
f01023a2:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01023a7:	68 57 04 00 00       	push   $0x457
f01023ac:	68 25 6e 10 f0       	push   $0xf0106e25
f01023b1:	e8 8a dc ff ff       	call   f0100040 <_panic>
f01023b6:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01023b9:	39 d0                	cmp    %edx,%eax
f01023bb:	75 db                	jne    f0102398 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01023bd:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01023c2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01023c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023cb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01023d1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01023d4:	89 0d 40 f2 22 f0    	mov    %ecx,0xf022f240

	// free the pages we took
	page_free(pp0);
f01023da:	83 ec 0c             	sub    $0xc,%esp
f01023dd:	50                   	push   %eax
f01023de:	e8 3e ec ff ff       	call   f0101021 <page_free>
	page_free(pp1);
f01023e3:	89 1c 24             	mov    %ebx,(%esp)
f01023e6:	e8 36 ec ff ff       	call   f0101021 <page_free>
	page_free(pp2);
f01023eb:	89 34 24             	mov    %esi,(%esp)
f01023ee:	e8 2e ec ff ff       	call   f0101021 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01023f3:	83 c4 08             	add    $0x8,%esp
f01023f6:	68 01 10 00 00       	push   $0x1001
f01023fb:	6a 00                	push   $0x0
f01023fd:	e8 20 ef ff ff       	call   f0101322 <mmio_map_region>
f0102402:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102404:	83 c4 08             	add    $0x8,%esp
f0102407:	68 00 10 00 00       	push   $0x1000
f010240c:	6a 00                	push   $0x0
f010240e:	e8 0f ef ff ff       	call   f0101322 <mmio_map_region>
f0102413:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102415:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f010241b:	83 c4 10             	add    $0x10,%esp
f010241e:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102424:	76 07                	jbe    f010242d <mem_init+0x10a8>
f0102426:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010242b:	76 19                	jbe    f0102446 <mem_init+0x10c1>
f010242d:	68 cc 6a 10 f0       	push   $0xf0106acc
f0102432:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102437:	68 67 04 00 00       	push   $0x467
f010243c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102441:	e8 fa db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102446:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010244c:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102452:	77 08                	ja     f010245c <mem_init+0x10d7>
f0102454:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010245a:	77 19                	ja     f0102475 <mem_init+0x10f0>
f010245c:	68 f4 6a 10 f0       	push   $0xf0106af4
f0102461:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102466:	68 68 04 00 00       	push   $0x468
f010246b:	68 25 6e 10 f0       	push   $0xf0106e25
f0102470:	e8 cb db ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102475:	89 da                	mov    %ebx,%edx
f0102477:	09 f2                	or     %esi,%edx
f0102479:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010247f:	74 19                	je     f010249a <mem_init+0x1115>
f0102481:	68 1c 6b 10 f0       	push   $0xf0106b1c
f0102486:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010248b:	68 6a 04 00 00       	push   $0x46a
f0102490:	68 25 6e 10 f0       	push   $0xf0106e25
f0102495:	e8 a6 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010249a:	39 c6                	cmp    %eax,%esi
f010249c:	73 19                	jae    f01024b7 <mem_init+0x1132>
f010249e:	68 dc 70 10 f0       	push   $0xf01070dc
f01024a3:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01024a8:	68 6c 04 00 00       	push   $0x46c
f01024ad:	68 25 6e 10 f0       	push   $0xf0106e25
f01024b2:	e8 89 db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01024b7:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f01024bd:	89 da                	mov    %ebx,%edx
f01024bf:	89 f8                	mov    %edi,%eax
f01024c1:	e8 03 e6 ff ff       	call   f0100ac9 <check_va2pa>
f01024c6:	85 c0                	test   %eax,%eax
f01024c8:	74 19                	je     f01024e3 <mem_init+0x115e>
f01024ca:	68 44 6b 10 f0       	push   $0xf0106b44
f01024cf:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01024d4:	68 6e 04 00 00       	push   $0x46e
f01024d9:	68 25 6e 10 f0       	push   $0xf0106e25
f01024de:	e8 5d db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01024e3:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01024e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01024ec:	89 c2                	mov    %eax,%edx
f01024ee:	89 f8                	mov    %edi,%eax
f01024f0:	e8 d4 e5 ff ff       	call   f0100ac9 <check_va2pa>
f01024f5:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01024fa:	74 19                	je     f0102515 <mem_init+0x1190>
f01024fc:	68 68 6b 10 f0       	push   $0xf0106b68
f0102501:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102506:	68 6f 04 00 00       	push   $0x46f
f010250b:	68 25 6e 10 f0       	push   $0xf0106e25
f0102510:	e8 2b db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102515:	89 f2                	mov    %esi,%edx
f0102517:	89 f8                	mov    %edi,%eax
f0102519:	e8 ab e5 ff ff       	call   f0100ac9 <check_va2pa>
f010251e:	85 c0                	test   %eax,%eax
f0102520:	74 19                	je     f010253b <mem_init+0x11b6>
f0102522:	68 98 6b 10 f0       	push   $0xf0106b98
f0102527:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010252c:	68 70 04 00 00       	push   $0x470
f0102531:	68 25 6e 10 f0       	push   $0xf0106e25
f0102536:	e8 05 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010253b:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102541:	89 f8                	mov    %edi,%eax
f0102543:	e8 81 e5 ff ff       	call   f0100ac9 <check_va2pa>
f0102548:	83 f8 ff             	cmp    $0xffffffff,%eax
f010254b:	74 19                	je     f0102566 <mem_init+0x11e1>
f010254d:	68 bc 6b 10 f0       	push   $0xf0106bbc
f0102552:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102557:	68 71 04 00 00       	push   $0x471
f010255c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102561:	e8 da da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102566:	83 ec 04             	sub    $0x4,%esp
f0102569:	6a 00                	push   $0x0
f010256b:	53                   	push   %ebx
f010256c:	57                   	push   %edi
f010256d:	e8 11 eb ff ff       	call   f0101083 <pgdir_walk>
f0102572:	83 c4 10             	add    $0x10,%esp
f0102575:	f6 00 1a             	testb  $0x1a,(%eax)
f0102578:	75 19                	jne    f0102593 <mem_init+0x120e>
f010257a:	68 e8 6b 10 f0       	push   $0xf0106be8
f010257f:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102584:	68 73 04 00 00       	push   $0x473
f0102589:	68 25 6e 10 f0       	push   $0xf0106e25
f010258e:	e8 ad da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102593:	83 ec 04             	sub    $0x4,%esp
f0102596:	6a 00                	push   $0x0
f0102598:	53                   	push   %ebx
f0102599:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010259f:	e8 df ea ff ff       	call   f0101083 <pgdir_walk>
f01025a4:	8b 00                	mov    (%eax),%eax
f01025a6:	83 c4 10             	add    $0x10,%esp
f01025a9:	83 e0 04             	and    $0x4,%eax
f01025ac:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01025af:	74 19                	je     f01025ca <mem_init+0x1245>
f01025b1:	68 2c 6c 10 f0       	push   $0xf0106c2c
f01025b6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01025bb:	68 74 04 00 00       	push   $0x474
f01025c0:	68 25 6e 10 f0       	push   $0xf0106e25
f01025c5:	e8 76 da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01025ca:	83 ec 04             	sub    $0x4,%esp
f01025cd:	6a 00                	push   $0x0
f01025cf:	53                   	push   %ebx
f01025d0:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01025d6:	e8 a8 ea ff ff       	call   f0101083 <pgdir_walk>
f01025db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01025e1:	83 c4 0c             	add    $0xc,%esp
f01025e4:	6a 00                	push   $0x0
f01025e6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01025e9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01025ef:	e8 8f ea ff ff       	call   f0101083 <pgdir_walk>
f01025f4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01025fa:	83 c4 0c             	add    $0xc,%esp
f01025fd:	6a 00                	push   $0x0
f01025ff:	56                   	push   %esi
f0102600:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102606:	e8 78 ea ff ff       	call   f0101083 <pgdir_walk>
f010260b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102611:	c7 04 24 ee 70 10 f0 	movl   $0xf01070ee,(%esp)
f0102618:	e8 68 10 00 00       	call   f0103685 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_U));
f010261d:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102622:	83 c4 10             	add    $0x10,%esp
f0102625:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010262a:	77 15                	ja     f0102641 <mem_init+0x12bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010262c:	50                   	push   %eax
f010262d:	68 28 5f 10 f0       	push   $0xf0105f28
f0102632:	68 cd 00 00 00       	push   $0xcd
f0102637:	68 25 6e 10 f0       	push   $0xf0106e25
f010263c:	e8 ff d9 ff ff       	call   f0100040 <_panic>
f0102641:	83 ec 08             	sub    $0x8,%esp
f0102644:	6a 05                	push   $0x5
f0102646:	05 00 00 00 10       	add    $0x10000000,%eax
f010264b:	50                   	push   %eax
f010264c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102651:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102656:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010265b:	e8 f5 ea ff ff       	call   f0101155 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_U));
f0102660:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102665:	83 c4 10             	add    $0x10,%esp
f0102668:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010266d:	77 15                	ja     f0102684 <mem_init+0x12ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010266f:	50                   	push   %eax
f0102670:	68 28 5f 10 f0       	push   $0xf0105f28
f0102675:	68 d7 00 00 00       	push   $0xd7
f010267a:	68 25 6e 10 f0       	push   $0xf0106e25
f010267f:	e8 bc d9 ff ff       	call   f0100040 <_panic>
f0102684:	83 ec 08             	sub    $0x8,%esp
f0102687:	6a 05                	push   $0x5
f0102689:	05 00 00 00 10       	add    $0x10000000,%eax
f010268e:	50                   	push   %eax
f010268f:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102694:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102699:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010269e:	e8 b2 ea ff ff       	call   f0101155 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a3:	83 c4 10             	add    $0x10,%esp
f01026a6:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f01026ab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026b0:	77 15                	ja     f01026c7 <mem_init+0x1342>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b2:	50                   	push   %eax
f01026b3:	68 28 5f 10 f0       	push   $0xf0105f28
f01026b8:	68 e4 00 00 00       	push   $0xe4
f01026bd:	68 25 6e 10 f0       	push   $0xf0106e25
f01026c2:	e8 79 d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01026c7:	83 ec 08             	sub    $0x8,%esp
f01026ca:	6a 02                	push   $0x2
f01026cc:	68 00 60 11 00       	push   $0x116000
f01026d1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026d6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026db:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01026e0:	e8 70 ea ff ff       	call   f0101155 <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f01026e5:	83 c4 08             	add    $0x8,%esp
f01026e8:	6a 02                	push   $0x2
f01026ea:	6a 00                	push   $0x0
f01026ec:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01026f1:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026f6:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01026fb:	e8 55 ea ff ff       	call   f0101155 <boot_map_region>
f0102700:	c7 45 c4 00 10 23 f0 	movl   $0xf0231000,-0x3c(%ebp)
f0102707:	83 c4 10             	add    $0x10,%esp
f010270a:	bb 00 10 23 f0       	mov    $0xf0231000,%ebx
f010270f:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102714:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010271a:	77 15                	ja     f0102731 <mem_init+0x13ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010271c:	53                   	push   %ebx
f010271d:	68 28 5f 10 f0       	push   $0xf0105f28
f0102722:	68 24 01 00 00       	push   $0x124
f0102727:	68 25 6e 10 f0       	push   $0xf0106e25
f010272c:	e8 0f d9 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
	{
		boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE - i * (KSTKSIZE + KSTKGAP), KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f0102731:	83 ec 08             	sub    $0x8,%esp
f0102734:	6a 02                	push   $0x2
f0102736:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010273c:	50                   	push   %eax
f010273d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102742:	89 f2                	mov    %esi,%edx
f0102744:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102749:	e8 07 ea ff ff       	call   f0101155 <boot_map_region>
f010274e:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102754:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
f010275a:	83 c4 10             	add    $0x10,%esp
f010275d:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f0102762:	39 d8                	cmp    %ebx,%eax
f0102764:	75 ae                	jne    f0102714 <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102766:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010276c:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0102771:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102774:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010277b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102780:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102783:	8b 35 90 fe 22 f0    	mov    0xf022fe90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102789:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010278c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102791:	eb 55                	jmp    f01027e8 <mem_init+0x1463>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102793:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102799:	89 f8                	mov    %edi,%eax
f010279b:	e8 29 e3 ff ff       	call   f0100ac9 <check_va2pa>
f01027a0:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01027a7:	77 15                	ja     f01027be <mem_init+0x1439>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027a9:	56                   	push   %esi
f01027aa:	68 28 5f 10 f0       	push   $0xf0105f28
f01027af:	68 8c 03 00 00       	push   $0x38c
f01027b4:	68 25 6e 10 f0       	push   $0xf0106e25
f01027b9:	e8 82 d8 ff ff       	call   f0100040 <_panic>
f01027be:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01027c5:	39 c2                	cmp    %eax,%edx
f01027c7:	74 19                	je     f01027e2 <mem_init+0x145d>
f01027c9:	68 60 6c 10 f0       	push   $0xf0106c60
f01027ce:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01027d3:	68 8c 03 00 00       	push   $0x38c
f01027d8:	68 25 6e 10 f0       	push   $0xf0106e25
f01027dd:	e8 5e d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027e2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027e8:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01027eb:	77 a6                	ja     f0102793 <mem_init+0x140e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01027ed:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027f3:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027f6:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01027fb:	89 da                	mov    %ebx,%edx
f01027fd:	89 f8                	mov    %edi,%eax
f01027ff:	e8 c5 e2 ff ff       	call   f0100ac9 <check_va2pa>
f0102804:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010280b:	77 15                	ja     f0102822 <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010280d:	56                   	push   %esi
f010280e:	68 28 5f 10 f0       	push   $0xf0105f28
f0102813:	68 91 03 00 00       	push   $0x391
f0102818:	68 25 6e 10 f0       	push   $0xf0106e25
f010281d:	e8 1e d8 ff ff       	call   f0100040 <_panic>
f0102822:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102829:	39 d0                	cmp    %edx,%eax
f010282b:	74 19                	je     f0102846 <mem_init+0x14c1>
f010282d:	68 94 6c 10 f0       	push   $0xf0106c94
f0102832:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102837:	68 91 03 00 00       	push   $0x391
f010283c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102841:	e8 fa d7 ff ff       	call   f0100040 <_panic>
f0102846:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010284c:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102852:	75 a7                	jne    f01027fb <mem_init+0x1476>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102854:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102857:	c1 e6 0c             	shl    $0xc,%esi
f010285a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010285f:	eb 30                	jmp    f0102891 <mem_init+0x150c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102861:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102867:	89 f8                	mov    %edi,%eax
f0102869:	e8 5b e2 ff ff       	call   f0100ac9 <check_va2pa>
f010286e:	39 c3                	cmp    %eax,%ebx
f0102870:	74 19                	je     f010288b <mem_init+0x1506>
f0102872:	68 c8 6c 10 f0       	push   $0xf0106cc8
f0102877:	68 4b 6e 10 f0       	push   $0xf0106e4b
f010287c:	68 95 03 00 00       	push   $0x395
f0102881:	68 25 6e 10 f0       	push   $0xf0106e25
f0102886:	e8 b5 d7 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010288b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102891:	39 f3                	cmp    %esi,%ebx
f0102893:	72 cc                	jb     f0102861 <mem_init+0x14dc>
f0102895:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010289a:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010289d:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01028a0:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028a3:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01028a9:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01028ac:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01028ae:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01028b1:	05 00 80 00 20       	add    $0x20008000,%eax
f01028b6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01028b9:	89 da                	mov    %ebx,%edx
f01028bb:	89 f8                	mov    %edi,%eax
f01028bd:	e8 07 e2 ff ff       	call   f0100ac9 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028c2:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01028c8:	77 15                	ja     f01028df <mem_init+0x155a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028ca:	56                   	push   %esi
f01028cb:	68 28 5f 10 f0       	push   $0xf0105f28
f01028d0:	68 9d 03 00 00       	push   $0x39d
f01028d5:	68 25 6e 10 f0       	push   $0xf0106e25
f01028da:	e8 61 d7 ff ff       	call   f0100040 <_panic>
f01028df:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01028e2:	8d 94 0b 00 10 23 f0 	lea    -0xfdcf000(%ebx,%ecx,1),%edx
f01028e9:	39 d0                	cmp    %edx,%eax
f01028eb:	74 19                	je     f0102906 <mem_init+0x1581>
f01028ed:	68 f0 6c 10 f0       	push   $0xf0106cf0
f01028f2:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01028f7:	68 9d 03 00 00       	push   $0x39d
f01028fc:	68 25 6e 10 f0       	push   $0xf0106e25
f0102901:	e8 3a d7 ff ff       	call   f0100040 <_panic>
f0102906:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010290c:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f010290f:	75 a8                	jne    f01028b9 <mem_init+0x1534>
f0102911:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102914:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f010291a:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010291d:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010291f:	89 da                	mov    %ebx,%edx
f0102921:	89 f8                	mov    %edi,%eax
f0102923:	e8 a1 e1 ff ff       	call   f0100ac9 <check_va2pa>
f0102928:	83 f8 ff             	cmp    $0xffffffff,%eax
f010292b:	74 19                	je     f0102946 <mem_init+0x15c1>
f010292d:	68 38 6d 10 f0       	push   $0xf0106d38
f0102932:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102937:	68 9f 03 00 00       	push   $0x39f
f010293c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102941:	e8 fa d6 ff ff       	call   f0100040 <_panic>
f0102946:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f010294c:	39 f3                	cmp    %esi,%ebx
f010294e:	75 cf                	jne    f010291f <mem_init+0x159a>
f0102950:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102953:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f010295a:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102961:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102967:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f010296c:	39 f0                	cmp    %esi,%eax
f010296e:	0f 85 2c ff ff ff    	jne    f01028a0 <mem_init+0x151b>
f0102974:	b8 00 00 00 00       	mov    $0x0,%eax
f0102979:	eb 2a                	jmp    f01029a5 <mem_init+0x1620>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010297b:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102981:	83 fa 04             	cmp    $0x4,%edx
f0102984:	77 1f                	ja     f01029a5 <mem_init+0x1620>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102986:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010298a:	75 7e                	jne    f0102a0a <mem_init+0x1685>
f010298c:	68 07 71 10 f0       	push   $0xf0107107
f0102991:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102996:	68 aa 03 00 00       	push   $0x3aa
f010299b:	68 25 6e 10 f0       	push   $0xf0106e25
f01029a0:	e8 9b d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01029a5:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029aa:	76 3f                	jbe    f01029eb <mem_init+0x1666>
				assert(pgdir[i] & PTE_P);
f01029ac:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01029af:	f6 c2 01             	test   $0x1,%dl
f01029b2:	75 19                	jne    f01029cd <mem_init+0x1648>
f01029b4:	68 07 71 10 f0       	push   $0xf0107107
f01029b9:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01029be:	68 ae 03 00 00       	push   $0x3ae
f01029c3:	68 25 6e 10 f0       	push   $0xf0106e25
f01029c8:	e8 73 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01029cd:	f6 c2 02             	test   $0x2,%dl
f01029d0:	75 38                	jne    f0102a0a <mem_init+0x1685>
f01029d2:	68 18 71 10 f0       	push   $0xf0107118
f01029d7:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01029dc:	68 af 03 00 00       	push   $0x3af
f01029e1:	68 25 6e 10 f0       	push   $0xf0106e25
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01029eb:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029ef:	74 19                	je     f0102a0a <mem_init+0x1685>
f01029f1:	68 29 71 10 f0       	push   $0xf0107129
f01029f6:	68 4b 6e 10 f0       	push   $0xf0106e4b
f01029fb:	68 b1 03 00 00       	push   $0x3b1
f0102a00:	68 25 6e 10 f0       	push   $0xf0106e25
f0102a05:	e8 36 d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a0a:	83 c0 01             	add    $0x1,%eax
f0102a0d:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102a12:	0f 86 63 ff ff ff    	jbe    f010297b <mem_init+0x15f6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a18:	83 ec 0c             	sub    $0xc,%esp
f0102a1b:	68 5c 6d 10 f0       	push   $0xf0106d5c
f0102a20:	e8 60 0c 00 00       	call   f0103685 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a25:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a2a:	83 c4 10             	add    $0x10,%esp
f0102a2d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a32:	77 15                	ja     f0102a49 <mem_init+0x16c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a34:	50                   	push   %eax
f0102a35:	68 28 5f 10 f0       	push   $0xf0105f28
f0102a3a:	68 fb 00 00 00       	push   $0xfb
f0102a3f:	68 25 6e 10 f0       	push   $0xf0106e25
f0102a44:	e8 f7 d5 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a49:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a4e:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a51:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a56:	e8 53 e1 ff ff       	call   f0100bae <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a5b:	0f 20 c0             	mov    %cr0,%eax
f0102a5e:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a61:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a66:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a69:	83 ec 0c             	sub    $0xc,%esp
f0102a6c:	6a 00                	push   $0x0
f0102a6e:	e8 3e e5 ff ff       	call   f0100fb1 <page_alloc>
f0102a73:	89 c7                	mov    %eax,%edi
f0102a75:	83 c4 10             	add    $0x10,%esp
f0102a78:	85 c0                	test   %eax,%eax
f0102a7a:	75 19                	jne    f0102a95 <mem_init+0x1710>
f0102a7c:	68 13 6f 10 f0       	push   $0xf0106f13
f0102a81:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102a86:	68 89 04 00 00       	push   $0x489
f0102a8b:	68 25 6e 10 f0       	push   $0xf0106e25
f0102a90:	e8 ab d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a95:	83 ec 0c             	sub    $0xc,%esp
f0102a98:	6a 00                	push   $0x0
f0102a9a:	e8 12 e5 ff ff       	call   f0100fb1 <page_alloc>
f0102a9f:	89 c6                	mov    %eax,%esi
f0102aa1:	83 c4 10             	add    $0x10,%esp
f0102aa4:	85 c0                	test   %eax,%eax
f0102aa6:	75 19                	jne    f0102ac1 <mem_init+0x173c>
f0102aa8:	68 29 6f 10 f0       	push   $0xf0106f29
f0102aad:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102ab2:	68 8a 04 00 00       	push   $0x48a
f0102ab7:	68 25 6e 10 f0       	push   $0xf0106e25
f0102abc:	e8 7f d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ac1:	83 ec 0c             	sub    $0xc,%esp
f0102ac4:	6a 00                	push   $0x0
f0102ac6:	e8 e6 e4 ff ff       	call   f0100fb1 <page_alloc>
f0102acb:	89 c3                	mov    %eax,%ebx
f0102acd:	83 c4 10             	add    $0x10,%esp
f0102ad0:	85 c0                	test   %eax,%eax
f0102ad2:	75 19                	jne    f0102aed <mem_init+0x1768>
f0102ad4:	68 3f 6f 10 f0       	push   $0xf0106f3f
f0102ad9:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102ade:	68 8b 04 00 00       	push   $0x48b
f0102ae3:	68 25 6e 10 f0       	push   $0xf0106e25
f0102ae8:	e8 53 d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102aed:	83 ec 0c             	sub    $0xc,%esp
f0102af0:	57                   	push   %edi
f0102af1:	e8 2b e5 ff ff       	call   f0101021 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102af6:	89 f0                	mov    %esi,%eax
f0102af8:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102afe:	c1 f8 03             	sar    $0x3,%eax
f0102b01:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b04:	89 c2                	mov    %eax,%edx
f0102b06:	c1 ea 0c             	shr    $0xc,%edx
f0102b09:	83 c4 10             	add    $0x10,%esp
f0102b0c:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102b12:	72 12                	jb     f0102b26 <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b14:	50                   	push   %eax
f0102b15:	68 04 5f 10 f0       	push   $0xf0105f04
f0102b1a:	6a 58                	push   $0x58
f0102b1c:	68 31 6e 10 f0       	push   $0xf0106e31
f0102b21:	e8 1a d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b26:	83 ec 04             	sub    $0x4,%esp
f0102b29:	68 00 10 00 00       	push   $0x1000
f0102b2e:	6a 01                	push   $0x1
f0102b30:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b35:	50                   	push   %eax
f0102b36:	e8 ea 26 00 00       	call   f0105225 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b3b:	89 d8                	mov    %ebx,%eax
f0102b3d:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102b43:	c1 f8 03             	sar    $0x3,%eax
f0102b46:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b49:	89 c2                	mov    %eax,%edx
f0102b4b:	c1 ea 0c             	shr    $0xc,%edx
f0102b4e:	83 c4 10             	add    $0x10,%esp
f0102b51:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102b57:	72 12                	jb     f0102b6b <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b59:	50                   	push   %eax
f0102b5a:	68 04 5f 10 f0       	push   $0xf0105f04
f0102b5f:	6a 58                	push   $0x58
f0102b61:	68 31 6e 10 f0       	push   $0xf0106e31
f0102b66:	e8 d5 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b6b:	83 ec 04             	sub    $0x4,%esp
f0102b6e:	68 00 10 00 00       	push   $0x1000
f0102b73:	6a 02                	push   $0x2
f0102b75:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b7a:	50                   	push   %eax
f0102b7b:	e8 a5 26 00 00       	call   f0105225 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b80:	6a 02                	push   $0x2
f0102b82:	68 00 10 00 00       	push   $0x1000
f0102b87:	56                   	push   %esi
f0102b88:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102b8e:	e8 1d e7 ff ff       	call   f01012b0 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b93:	83 c4 20             	add    $0x20,%esp
f0102b96:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b9b:	74 19                	je     f0102bb6 <mem_init+0x1831>
f0102b9d:	68 10 70 10 f0       	push   $0xf0107010
f0102ba2:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102ba7:	68 90 04 00 00       	push   $0x490
f0102bac:	68 25 6e 10 f0       	push   $0xf0106e25
f0102bb1:	e8 8a d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bb6:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bbd:	01 01 01 
f0102bc0:	74 19                	je     f0102bdb <mem_init+0x1856>
f0102bc2:	68 7c 6d 10 f0       	push   $0xf0106d7c
f0102bc7:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102bcc:	68 91 04 00 00       	push   $0x491
f0102bd1:	68 25 6e 10 f0       	push   $0xf0106e25
f0102bd6:	e8 65 d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bdb:	6a 02                	push   $0x2
f0102bdd:	68 00 10 00 00       	push   $0x1000
f0102be2:	53                   	push   %ebx
f0102be3:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102be9:	e8 c2 e6 ff ff       	call   f01012b0 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bee:	83 c4 10             	add    $0x10,%esp
f0102bf1:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bf8:	02 02 02 
f0102bfb:	74 19                	je     f0102c16 <mem_init+0x1891>
f0102bfd:	68 a0 6d 10 f0       	push   $0xf0106da0
f0102c02:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102c07:	68 93 04 00 00       	push   $0x493
f0102c0c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102c11:	e8 2a d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102c16:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c1b:	74 19                	je     f0102c36 <mem_init+0x18b1>
f0102c1d:	68 32 70 10 f0       	push   $0xf0107032
f0102c22:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102c27:	68 94 04 00 00       	push   $0x494
f0102c2c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102c31:	e8 0a d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102c36:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c3b:	74 19                	je     f0102c56 <mem_init+0x18d1>
f0102c3d:	68 9c 70 10 f0       	push   $0xf010709c
f0102c42:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102c47:	68 95 04 00 00       	push   $0x495
f0102c4c:	68 25 6e 10 f0       	push   $0xf0106e25
f0102c51:	e8 ea d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c56:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c5d:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c60:	89 d8                	mov    %ebx,%eax
f0102c62:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102c68:	c1 f8 03             	sar    $0x3,%eax
f0102c6b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c6e:	89 c2                	mov    %eax,%edx
f0102c70:	c1 ea 0c             	shr    $0xc,%edx
f0102c73:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102c79:	72 12                	jb     f0102c8d <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c7b:	50                   	push   %eax
f0102c7c:	68 04 5f 10 f0       	push   $0xf0105f04
f0102c81:	6a 58                	push   $0x58
f0102c83:	68 31 6e 10 f0       	push   $0xf0106e31
f0102c88:	e8 b3 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c8d:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c94:	03 03 03 
f0102c97:	74 19                	je     f0102cb2 <mem_init+0x192d>
f0102c99:	68 c4 6d 10 f0       	push   $0xf0106dc4
f0102c9e:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102ca3:	68 97 04 00 00       	push   $0x497
f0102ca8:	68 25 6e 10 f0       	push   $0xf0106e25
f0102cad:	e8 8e d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cb2:	83 ec 08             	sub    $0x8,%esp
f0102cb5:	68 00 10 00 00       	push   $0x1000
f0102cba:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102cc0:	e8 96 e5 ff ff       	call   f010125b <page_remove>
	assert(pp2->pp_ref == 0);
f0102cc5:	83 c4 10             	add    $0x10,%esp
f0102cc8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102ccd:	74 19                	je     f0102ce8 <mem_init+0x1963>
f0102ccf:	68 6a 70 10 f0       	push   $0xf010706a
f0102cd4:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0102cd9:	68 99 04 00 00       	push   $0x499
f0102cde:	68 25 6e 10 f0       	push   $0xf0106e25
f0102ce3:	e8 58 d3 ff ff       	call   f0100040 <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ce8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ceb:	5b                   	pop    %ebx
f0102cec:	5e                   	pop    %esi
f0102ced:	5f                   	pop    %edi
f0102cee:	5d                   	pop    %ebp
f0102cef:	c3                   	ret    

f0102cf0 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102cf0:	55                   	push   %ebp
f0102cf1:	89 e5                	mov    %esp,%ebp
f0102cf3:	57                   	push   %edi
f0102cf4:	56                   	push   %esi
f0102cf5:	53                   	push   %ebx
f0102cf6:	83 ec 1c             	sub    $0x1c,%esp
f0102cf9:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102cfc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cff:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);
f0102d02:	89 d8                	mov    %ebx,%eax
f0102d04:	03 45 10             	add    0x10(%ebp),%eax
f0102d07:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102d0c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d11:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f0102d14:	eb 3e                	jmp    f0102d54 <user_mem_check+0x64>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, va, 0);
f0102d16:	83 ec 04             	sub    $0x4,%esp
f0102d19:	6a 00                	push   $0x0
f0102d1b:	53                   	push   %ebx
f0102d1c:	ff 77 60             	pushl  0x60(%edi)
f0102d1f:	e8 5f e3 ff ff       	call   f0101083 <pgdir_walk>

		if ((va >= (void*) ULIM) || !pte || ((*pte & perm) != perm))
f0102d24:	83 c4 10             	add    $0x10,%esp
f0102d27:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d2d:	77 0c                	ja     f0102d3b <user_mem_check+0x4b>
f0102d2f:	85 c0                	test   %eax,%eax
f0102d31:	74 08                	je     f0102d3b <user_mem_check+0x4b>
f0102d33:	89 f2                	mov    %esi,%edx
f0102d35:	23 10                	and    (%eax),%edx
f0102d37:	39 d6                	cmp    %edx,%esi
f0102d39:	74 0d                	je     f0102d48 <user_mem_check+0x58>
		{
			user_mem_check_addr = (uint32_t) va;
f0102d3b:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
			return -E_FAULT;
f0102d41:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d46:	eb 16                	jmp    f0102d5e <user_mem_check+0x6e>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f0102d48:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d4e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102d54:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d57:	72 bd                	jb     f0102d16 <user_mem_check+0x26>
			user_mem_check_addr = (uint32_t) va;
			return -E_FAULT;
		}		
	}

	return 0;
f0102d59:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d61:	5b                   	pop    %ebx
f0102d62:	5e                   	pop    %esi
f0102d63:	5f                   	pop    %edi
f0102d64:	5d                   	pop    %ebp
f0102d65:	c3                   	ret    

f0102d66 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d66:	55                   	push   %ebp
f0102d67:	89 e5                	mov    %esp,%ebp
f0102d69:	53                   	push   %ebx
f0102d6a:	83 ec 04             	sub    $0x4,%esp
f0102d6d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d70:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d73:	83 c8 04             	or     $0x4,%eax
f0102d76:	50                   	push   %eax
f0102d77:	ff 75 10             	pushl  0x10(%ebp)
f0102d7a:	ff 75 0c             	pushl  0xc(%ebp)
f0102d7d:	53                   	push   %ebx
f0102d7e:	e8 6d ff ff ff       	call   f0102cf0 <user_mem_check>
f0102d83:	83 c4 10             	add    $0x10,%esp
f0102d86:	85 c0                	test   %eax,%eax
f0102d88:	79 21                	jns    f0102dab <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d8a:	83 ec 04             	sub    $0x4,%esp
f0102d8d:	ff 35 3c f2 22 f0    	pushl  0xf022f23c
f0102d93:	ff 73 48             	pushl  0x48(%ebx)
f0102d96:	68 f0 6d 10 f0       	push   $0xf0106df0
f0102d9b:	e8 e5 08 00 00       	call   f0103685 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102da0:	89 1c 24             	mov    %ebx,(%esp)
f0102da3:	e8 24 06 00 00       	call   f01033cc <env_destroy>
f0102da8:	83 c4 10             	add    $0x10,%esp
	}
}
f0102dab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102dae:	c9                   	leave  
f0102daf:	c3                   	ret    

f0102db0 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102db0:	55                   	push   %ebp
f0102db1:	89 e5                	mov    %esp,%ebp
f0102db3:	57                   	push   %edi
f0102db4:	56                   	push   %esi
f0102db5:	53                   	push   %ebx
f0102db6:	83 ec 0c             	sub    $0xc,%esp
f0102db9:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
f0102dbb:	89 d3                	mov    %edx,%ebx
f0102dbd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);
f0102dc3:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102dca:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102dd0:	eb 3d                	jmp    f0102e0f <region_alloc+0x5f>
	{
		page = page_alloc(0);
f0102dd2:	83 ec 0c             	sub    $0xc,%esp
f0102dd5:	6a 00                	push   $0x0
f0102dd7:	e8 d5 e1 ff ff       	call   f0100fb1 <page_alloc>

		if(!page)
f0102ddc:	83 c4 10             	add    $0x10,%esp
f0102ddf:	85 c0                	test   %eax,%eax
f0102de1:	75 17                	jne    f0102dfa <region_alloc+0x4a>
			panic("region_alloc: page allocation failed!");
f0102de3:	83 ec 04             	sub    $0x4,%esp
f0102de6:	68 38 71 10 f0       	push   $0xf0107138
f0102deb:	68 33 01 00 00       	push   $0x133
f0102df0:	68 82 71 10 f0       	push   $0xf0107182
f0102df5:	e8 46 d2 ff ff       	call   f0100040 <_panic>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
f0102dfa:	6a 06                	push   $0x6
f0102dfc:	53                   	push   %ebx
f0102dfd:	50                   	push   %eax
f0102dfe:	ff 77 60             	pushl  0x60(%edi)
f0102e01:	e8 aa e4 ff ff       	call   f01012b0 <page_insert>
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102e06:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e0c:	83 c4 10             	add    $0x10,%esp
f0102e0f:	39 f3                	cmp    %esi,%ebx
f0102e11:	72 bf                	jb     f0102dd2 <region_alloc+0x22>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
	}
	
	
}
f0102e13:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e16:	5b                   	pop    %ebx
f0102e17:	5e                   	pop    %esi
f0102e18:	5f                   	pop    %edi
f0102e19:	5d                   	pop    %ebp
f0102e1a:	c3                   	ret    

f0102e1b <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e1b:	55                   	push   %ebp
f0102e1c:	89 e5                	mov    %esp,%ebp
f0102e1e:	56                   	push   %esi
f0102e1f:	53                   	push   %ebx
f0102e20:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e23:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e26:	85 c0                	test   %eax,%eax
f0102e28:	75 1a                	jne    f0102e44 <envid2env+0x29>
		*env_store = curenv;
f0102e2a:	e8 17 2a 00 00       	call   f0105846 <cpunum>
f0102e2f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e32:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102e38:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e3b:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e3d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e42:	eb 70                	jmp    f0102eb4 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e44:	89 c3                	mov    %eax,%ebx
f0102e46:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e4c:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e4f:	03 1d 44 f2 22 f0    	add    0xf022f244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e55:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e59:	74 05                	je     f0102e60 <envid2env+0x45>
f0102e5b:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e5e:	74 10                	je     f0102e70 <envid2env+0x55>
		*env_store = 0;
f0102e60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e63:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e69:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e6e:	eb 44                	jmp    f0102eb4 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e70:	84 d2                	test   %dl,%dl
f0102e72:	74 36                	je     f0102eaa <envid2env+0x8f>
f0102e74:	e8 cd 29 00 00       	call   f0105846 <cpunum>
f0102e79:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e7c:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0102e82:	74 26                	je     f0102eaa <envid2env+0x8f>
f0102e84:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e87:	e8 ba 29 00 00       	call   f0105846 <cpunum>
f0102e8c:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e8f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102e95:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e98:	74 10                	je     f0102eaa <envid2env+0x8f>
		*env_store = 0;
f0102e9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e9d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ea3:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ea8:	eb 0a                	jmp    f0102eb4 <envid2env+0x99>
	}

	*env_store = e;
f0102eaa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ead:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102eaf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102eb4:	5b                   	pop    %ebx
f0102eb5:	5e                   	pop    %esi
f0102eb6:	5d                   	pop    %ebp
f0102eb7:	c3                   	ret    

f0102eb8 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102eb8:	55                   	push   %ebp
f0102eb9:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102ebb:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0102ec0:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102ec3:	b8 23 00 00 00       	mov    $0x23,%eax
f0102ec8:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102eca:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102ecc:	b8 10 00 00 00       	mov    $0x10,%eax
f0102ed1:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102ed3:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102ed5:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102ed7:	ea de 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102ede
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102ede:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ee3:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102ee6:	5d                   	pop    %ebp
f0102ee7:	c3                   	ret    

f0102ee8 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102ee8:	55                   	push   %ebp
f0102ee9:	89 e5                	mov    %esp,%ebp
f0102eeb:	56                   	push   %esi
f0102eec:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
	{
		envs[i].env_id = 0;
f0102eed:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
f0102ef3:	8b 15 48 f2 22 f0    	mov    0xf022f248,%edx
f0102ef9:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102eff:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f02:	89 c1                	mov    %eax,%ecx
f0102f04:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102f0b:	89 50 44             	mov    %edx,0x44(%eax)
f0102f0e:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];	
f0102f11:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
f0102f13:	39 d8                	cmp    %ebx,%eax
f0102f15:	75 eb                	jne    f0102f02 <env_init+0x1a>
f0102f17:	89 35 48 f2 22 f0    	mov    %esi,0xf022f248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];	
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102f1d:	e8 96 ff ff ff       	call   f0102eb8 <env_init_percpu>
}
f0102f22:	5b                   	pop    %ebx
f0102f23:	5e                   	pop    %esi
f0102f24:	5d                   	pop    %ebp
f0102f25:	c3                   	ret    

f0102f26 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f26:	55                   	push   %ebp
f0102f27:	89 e5                	mov    %esp,%ebp
f0102f29:	53                   	push   %ebx
f0102f2a:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f2d:	8b 1d 48 f2 22 f0    	mov    0xf022f248,%ebx
f0102f33:	85 db                	test   %ebx,%ebx
f0102f35:	0f 84 70 01 00 00    	je     f01030ab <env_alloc+0x185>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f3b:	83 ec 0c             	sub    $0xc,%esp
f0102f3e:	6a 01                	push   $0x1
f0102f40:	e8 6c e0 ff ff       	call   f0100fb1 <page_alloc>
f0102f45:	83 c4 10             	add    $0x10,%esp
f0102f48:	85 c0                	test   %eax,%eax
f0102f4a:	0f 84 62 01 00 00    	je     f01030b2 <env_alloc+0x18c>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102f50:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f55:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102f5b:	c1 f8 03             	sar    $0x3,%eax
f0102f5e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f61:	89 c2                	mov    %eax,%edx
f0102f63:	c1 ea 0c             	shr    $0xc,%edx
f0102f66:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102f6c:	72 12                	jb     f0102f80 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f6e:	50                   	push   %eax
f0102f6f:	68 04 5f 10 f0       	push   $0xf0105f04
f0102f74:	6a 58                	push   $0x58
f0102f76:	68 31 6e 10 f0       	push   $0xf0106e31
f0102f7b:	e8 c0 d0 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = (pde_t*) page2kva(p);
f0102f80:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f85:	89 43 60             	mov    %eax,0x60(%ebx)
f0102f88:	b8 ec 0e 00 00       	mov    $0xeec,%eax
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102f8d:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0102f93:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102f96:	8b 53 60             	mov    0x60(%ebx),%edx
f0102f99:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102f9c:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*) page2kva(p);
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
f0102f9f:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102fa4:	75 e7                	jne    f0102f8d <env_alloc+0x67>
		e->env_pgdir[i] = kern_pgdir[i];
	}

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102fa6:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fa9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102fae:	77 15                	ja     f0102fc5 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fb0:	50                   	push   %eax
f0102fb1:	68 28 5f 10 f0       	push   $0xf0105f28
f0102fb6:	68 ca 00 00 00       	push   $0xca
f0102fbb:	68 82 71 10 f0       	push   $0xf0107182
f0102fc0:	e8 7b d0 ff ff       	call   f0100040 <_panic>
f0102fc5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102fcb:	83 ca 05             	or     $0x5,%edx
f0102fce:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fd4:	8b 43 48             	mov    0x48(%ebx),%eax
f0102fd7:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102fdc:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fe1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fe6:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102fe9:	89 da                	mov    %ebx,%edx
f0102feb:	2b 15 44 f2 22 f0    	sub    0xf022f244,%edx
f0102ff1:	c1 fa 02             	sar    $0x2,%edx
f0102ff4:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102ffa:	09 d0                	or     %edx,%eax
f0102ffc:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103002:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103005:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010300c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103013:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010301a:	83 ec 04             	sub    $0x4,%esp
f010301d:	6a 44                	push   $0x44
f010301f:	6a 00                	push   $0x0
f0103021:	53                   	push   %ebx
f0103022:	e8 fe 21 00 00       	call   f0105225 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103027:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010302d:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103033:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103039:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103040:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;	
f0103046:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010304d:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103054:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103058:	8b 43 44             	mov    0x44(%ebx),%eax
f010305b:	a3 48 f2 22 f0       	mov    %eax,0xf022f248
	*newenv_store = e;
f0103060:	8b 45 08             	mov    0x8(%ebp),%eax
f0103063:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103065:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103068:	e8 d9 27 00 00       	call   f0105846 <cpunum>
f010306d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103070:	83 c4 10             	add    $0x10,%esp
f0103073:	ba 00 00 00 00       	mov    $0x0,%edx
f0103078:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010307f:	74 11                	je     f0103092 <env_alloc+0x16c>
f0103081:	e8 c0 27 00 00       	call   f0105846 <cpunum>
f0103086:	6b c0 74             	imul   $0x74,%eax,%eax
f0103089:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010308f:	8b 50 48             	mov    0x48(%eax),%edx
f0103092:	83 ec 04             	sub    $0x4,%esp
f0103095:	53                   	push   %ebx
f0103096:	52                   	push   %edx
f0103097:	68 8d 71 10 f0       	push   $0xf010718d
f010309c:	e8 e4 05 00 00       	call   f0103685 <cprintf>
	return 0;
f01030a1:	83 c4 10             	add    $0x10,%esp
f01030a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01030a9:	eb 0c                	jmp    f01030b7 <env_alloc+0x191>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01030ab:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01030b0:	eb 05                	jmp    f01030b7 <env_alloc+0x191>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01030b2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01030b7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030ba:	c9                   	leave  
f01030bb:	c3                   	ret    

f01030bc <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01030bc:	55                   	push   %ebp
f01030bd:	89 e5                	mov    %esp,%ebp
f01030bf:	57                   	push   %edi
f01030c0:	56                   	push   %esi
f01030c1:	53                   	push   %ebx
f01030c2:	83 ec 34             	sub    $0x34,%esp
f01030c5:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e = NULL;
f01030c8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uint32_t result = env_alloc(&e, 0);
f01030cf:	6a 00                	push   $0x0
f01030d1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030d4:	50                   	push   %eax
f01030d5:	e8 4c fe ff ff       	call   f0102f26 <env_alloc>

	if(result !=  0)
f01030da:	83 c4 10             	add    $0x10,%esp
f01030dd:	85 c0                	test   %eax,%eax
f01030df:	74 15                	je     f01030f6 <env_create+0x3a>
		panic("env_create: %e", result);
f01030e1:	50                   	push   %eax
f01030e2:	68 a2 71 10 f0       	push   $0xf01071a2
f01030e7:	68 a2 01 00 00       	push   $0x1a2
f01030ec:	68 82 71 10 f0       	push   $0xf0107182
f01030f1:	e8 4a cf ff ff       	call   f0100040 <_panic>

	load_icode(e, binary);
f01030f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph = NULL, *eph = NULL;
	struct Elf *elf = (struct Elf*) binary;
	
	if(elf->e_magic != ELF_MAGIC)
f01030fc:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103102:	74 17                	je     f010311b <env_create+0x5f>
		panic("load icode: Elf format not valid!");
f0103104:	83 ec 04             	sub    $0x4,%esp
f0103107:	68 60 71 10 f0       	push   $0xf0107160
f010310c:	68 75 01 00 00       	push   $0x175
f0103111:	68 82 71 10 f0       	push   $0xf0107182
f0103116:	e8 25 cf ff ff       	call   f0100040 <_panic>

	ph = (struct Proghdr*) (binary + elf->e_phoff);
f010311b:	89 fb                	mov    %edi,%ebx
f010311d:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0103120:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103124:	c1 e6 05             	shl    $0x5,%esi
f0103127:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0103129:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010312c:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010312f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103134:	77 15                	ja     f010314b <env_create+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103136:	50                   	push   %eax
f0103137:	68 28 5f 10 f0       	push   $0xf0105f28
f010313c:	68 7a 01 00 00       	push   $0x17a
f0103141:	68 82 71 10 f0       	push   $0xf0107182
f0103146:	e8 f5 ce ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010314b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103150:	0f 22 d8             	mov    %eax,%cr3
f0103153:	eb 44                	jmp    f0103199 <env_create+0xdd>

	for( ; ph < eph; ++ph)
	{
		if(ph->p_type != ELF_PROG_LOAD)
f0103155:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103158:	75 3c                	jne    f0103196 <env_create+0xda>
			continue;		

		region_alloc(e, (void*) ph->p_va, ph->p_memsz);
f010315a:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010315d:	8b 53 08             	mov    0x8(%ebx),%edx
f0103160:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103163:	e8 48 fc ff ff       	call   f0102db0 <region_alloc>
		
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103168:	83 ec 04             	sub    $0x4,%esp
f010316b:	ff 73 10             	pushl  0x10(%ebx)
f010316e:	89 f8                	mov    %edi,%eax
f0103170:	03 43 04             	add    0x4(%ebx),%eax
f0103173:	50                   	push   %eax
f0103174:	ff 73 08             	pushl  0x8(%ebx)
f0103177:	e8 5e 21 00 00       	call   f01052da <memcpy>
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
f010317c:	8b 43 10             	mov    0x10(%ebx),%eax
f010317f:	83 c4 0c             	add    $0xc,%esp
f0103182:	8b 53 14             	mov    0x14(%ebx),%edx
f0103185:	29 c2                	sub    %eax,%edx
f0103187:	52                   	push   %edx
f0103188:	6a 00                	push   $0x0
f010318a:	03 43 08             	add    0x8(%ebx),%eax
f010318d:	50                   	push   %eax
f010318e:	e8 92 20 00 00       	call   f0105225 <memset>
f0103193:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr*) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	for( ; ph < eph; ++ph)
f0103196:	83 c3 20             	add    $0x20,%ebx
f0103199:	39 de                	cmp    %ebx,%esi
f010319b:	77 b8                	ja     f0103155 <env_create+0x99>
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
	}

	e->env_tf.tf_eip = elf->e_entry;
f010319d:	8b 47 18             	mov    0x18(%edi),%eax
f01031a0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01031a3:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*) USTACKTOP - PGSIZE, PGSIZE);
f01031a6:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031ab:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031b0:	89 f8                	mov    %edi,%eax
f01031b2:	e8 f9 fb ff ff       	call   f0102db0 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f01031b7:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031bc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031c1:	77 15                	ja     f01031d8 <env_create+0x11c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031c3:	50                   	push   %eax
f01031c4:	68 28 5f 10 f0       	push   $0xf0105f28
f01031c9:	68 90 01 00 00       	push   $0x190
f01031ce:	68 82 71 10 f0       	push   $0xf0107182
f01031d3:	e8 68 ce ff ff       	call   f0100040 <_panic>
f01031d8:	05 00 00 00 10       	add    $0x10000000,%eax
f01031dd:	0f 22 d8             	mov    %eax,%cr3

	if(result !=  0)
		panic("env_create: %e", result);

	load_icode(e, binary);
	e->env_type = type;
f01031e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031e3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031e6:	89 50 50             	mov    %edx,0x50(%eax)
}
f01031e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031ec:	5b                   	pop    %ebx
f01031ed:	5e                   	pop    %esi
f01031ee:	5f                   	pop    %edi
f01031ef:	5d                   	pop    %ebp
f01031f0:	c3                   	ret    

f01031f1 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031f1:	55                   	push   %ebp
f01031f2:	89 e5                	mov    %esp,%ebp
f01031f4:	57                   	push   %edi
f01031f5:	56                   	push   %esi
f01031f6:	53                   	push   %ebx
f01031f7:	83 ec 1c             	sub    $0x1c,%esp
f01031fa:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031fd:	e8 44 26 00 00       	call   f0105846 <cpunum>
f0103202:	6b c0 74             	imul   $0x74,%eax,%eax
f0103205:	39 b8 28 00 23 f0    	cmp    %edi,-0xfdcffd8(%eax)
f010320b:	75 29                	jne    f0103236 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010320d:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103212:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103217:	77 15                	ja     f010322e <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103219:	50                   	push   %eax
f010321a:	68 28 5f 10 f0       	push   $0xf0105f28
f010321f:	68 b6 01 00 00       	push   $0x1b6
f0103224:	68 82 71 10 f0       	push   $0xf0107182
f0103229:	e8 12 ce ff ff       	call   f0100040 <_panic>
f010322e:	05 00 00 00 10       	add    $0x10000000,%eax
f0103233:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103236:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103239:	e8 08 26 00 00       	call   f0105846 <cpunum>
f010323e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103241:	ba 00 00 00 00       	mov    $0x0,%edx
f0103246:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010324d:	74 11                	je     f0103260 <env_free+0x6f>
f010324f:	e8 f2 25 00 00       	call   f0105846 <cpunum>
f0103254:	6b c0 74             	imul   $0x74,%eax,%eax
f0103257:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010325d:	8b 50 48             	mov    0x48(%eax),%edx
f0103260:	83 ec 04             	sub    $0x4,%esp
f0103263:	53                   	push   %ebx
f0103264:	52                   	push   %edx
f0103265:	68 b1 71 10 f0       	push   $0xf01071b1
f010326a:	e8 16 04 00 00       	call   f0103685 <cprintf>
f010326f:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103272:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103279:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010327c:	89 d0                	mov    %edx,%eax
f010327e:	c1 e0 02             	shl    $0x2,%eax
f0103281:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103284:	8b 47 60             	mov    0x60(%edi),%eax
f0103287:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010328a:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103290:	0f 84 a8 00 00 00    	je     f010333e <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103296:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010329c:	89 f0                	mov    %esi,%eax
f010329e:	c1 e8 0c             	shr    $0xc,%eax
f01032a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01032a4:	39 05 88 fe 22 f0    	cmp    %eax,0xf022fe88
f01032aa:	77 15                	ja     f01032c1 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032ac:	56                   	push   %esi
f01032ad:	68 04 5f 10 f0       	push   $0xf0105f04
f01032b2:	68 c5 01 00 00       	push   $0x1c5
f01032b7:	68 82 71 10 f0       	push   $0xf0107182
f01032bc:	e8 7f cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032c4:	c1 e0 16             	shl    $0x16,%eax
f01032c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032ca:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01032cf:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01032d6:	01 
f01032d7:	74 17                	je     f01032f0 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032d9:	83 ec 08             	sub    $0x8,%esp
f01032dc:	89 d8                	mov    %ebx,%eax
f01032de:	c1 e0 0c             	shl    $0xc,%eax
f01032e1:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032e4:	50                   	push   %eax
f01032e5:	ff 77 60             	pushl  0x60(%edi)
f01032e8:	e8 6e df ff ff       	call   f010125b <page_remove>
f01032ed:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032f0:	83 c3 01             	add    $0x1,%ebx
f01032f3:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032f9:	75 d4                	jne    f01032cf <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032fb:	8b 47 60             	mov    0x60(%edi),%eax
f01032fe:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103301:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103308:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010330b:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103311:	72 14                	jb     f0103327 <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103313:	83 ec 04             	sub    $0x4,%esp
f0103316:	68 f4 65 10 f0       	push   $0xf01065f4
f010331b:	6a 51                	push   $0x51
f010331d:	68 31 6e 10 f0       	push   $0xf0106e31
f0103322:	e8 19 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103327:	83 ec 0c             	sub    $0xc,%esp
f010332a:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f010332f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103332:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103335:	50                   	push   %eax
f0103336:	e8 21 dd ff ff       	call   f010105c <page_decref>
f010333b:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010333e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103342:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103345:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010334a:	0f 85 29 ff ff ff    	jne    f0103279 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103350:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103353:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103358:	77 15                	ja     f010336f <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010335a:	50                   	push   %eax
f010335b:	68 28 5f 10 f0       	push   $0xf0105f28
f0103360:	68 d3 01 00 00       	push   $0x1d3
f0103365:	68 82 71 10 f0       	push   $0xf0107182
f010336a:	e8 d1 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010336f:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103376:	05 00 00 00 10       	add    $0x10000000,%eax
f010337b:	c1 e8 0c             	shr    $0xc,%eax
f010337e:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103384:	72 14                	jb     f010339a <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103386:	83 ec 04             	sub    $0x4,%esp
f0103389:	68 f4 65 10 f0       	push   $0xf01065f4
f010338e:	6a 51                	push   $0x51
f0103390:	68 31 6e 10 f0       	push   $0xf0106e31
f0103395:	e8 a6 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010339a:	83 ec 0c             	sub    $0xc,%esp
f010339d:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f01033a3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01033a6:	50                   	push   %eax
f01033a7:	e8 b0 dc ff ff       	call   f010105c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01033ac:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01033b3:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
f01033b8:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01033bb:	89 3d 48 f2 22 f0    	mov    %edi,0xf022f248
}
f01033c1:	83 c4 10             	add    $0x10,%esp
f01033c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033c7:	5b                   	pop    %ebx
f01033c8:	5e                   	pop    %esi
f01033c9:	5f                   	pop    %edi
f01033ca:	5d                   	pop    %ebp
f01033cb:	c3                   	ret    

f01033cc <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01033cc:	55                   	push   %ebp
f01033cd:	89 e5                	mov    %esp,%ebp
f01033cf:	53                   	push   %ebx
f01033d0:	83 ec 04             	sub    $0x4,%esp
f01033d3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01033d6:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01033da:	75 19                	jne    f01033f5 <env_destroy+0x29>
f01033dc:	e8 65 24 00 00       	call   f0105846 <cpunum>
f01033e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e4:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f01033ea:	74 09                	je     f01033f5 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033ec:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033f3:	eb 33                	jmp    f0103428 <env_destroy+0x5c>
	}

	env_free(e);
f01033f5:	83 ec 0c             	sub    $0xc,%esp
f01033f8:	53                   	push   %ebx
f01033f9:	e8 f3 fd ff ff       	call   f01031f1 <env_free>

	if (curenv == e) {
f01033fe:	e8 43 24 00 00       	call   f0105846 <cpunum>
f0103403:	6b c0 74             	imul   $0x74,%eax,%eax
f0103406:	83 c4 10             	add    $0x10,%esp
f0103409:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f010340f:	75 17                	jne    f0103428 <env_destroy+0x5c>
		curenv = NULL;
f0103411:	e8 30 24 00 00       	call   f0105846 <cpunum>
f0103416:	6b c0 74             	imul   $0x74,%eax,%eax
f0103419:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103420:	00 00 00 
		sched_yield();
f0103423:	e8 f6 0d 00 00       	call   f010421e <sched_yield>
	}
}
f0103428:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010342b:	c9                   	leave  
f010342c:	c3                   	ret    

f010342d <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010342d:	55                   	push   %ebp
f010342e:	89 e5                	mov    %esp,%ebp
f0103430:	53                   	push   %ebx
f0103431:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103434:	e8 0d 24 00 00       	call   f0105846 <cpunum>
f0103439:	6b c0 74             	imul   $0x74,%eax,%eax
f010343c:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f0103442:	e8 ff 23 00 00       	call   f0105846 <cpunum>
f0103447:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f010344a:	8b 65 08             	mov    0x8(%ebp),%esp
f010344d:	61                   	popa   
f010344e:	07                   	pop    %es
f010344f:	1f                   	pop    %ds
f0103450:	83 c4 08             	add    $0x8,%esp
f0103453:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103454:	83 ec 04             	sub    $0x4,%esp
f0103457:	68 c7 71 10 f0       	push   $0xf01071c7
f010345c:	68 0a 02 00 00       	push   $0x20a
f0103461:	68 82 71 10 f0       	push   $0xf0107182
f0103466:	e8 d5 cb ff ff       	call   f0100040 <_panic>

f010346b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010346b:	55                   	push   %ebp
f010346c:	89 e5                	mov    %esp,%ebp
f010346e:	53                   	push   %ebx
f010346f:	83 ec 04             	sub    $0x4,%esp
f0103472:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && (curenv->env_status == ENV_RUNNING))
f0103475:	e8 cc 23 00 00       	call   f0105846 <cpunum>
f010347a:	6b c0 74             	imul   $0x74,%eax,%eax
f010347d:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103484:	74 29                	je     f01034af <env_run+0x44>
f0103486:	e8 bb 23 00 00       	call   f0105846 <cpunum>
f010348b:	6b c0 74             	imul   $0x74,%eax,%eax
f010348e:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103494:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103498:	75 15                	jne    f01034af <env_run+0x44>
	{
		curenv->env_status = ENV_RUNNABLE;
f010349a:	e8 a7 23 00 00       	call   f0105846 <cpunum>
f010349f:	6b c0 74             	imul   $0x74,%eax,%eax
f01034a2:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01034a8:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}

	curenv = e;
f01034af:	e8 92 23 00 00       	call   f0105846 <cpunum>
f01034b4:	6b c0 74             	imul   $0x74,%eax,%eax
f01034b7:	89 98 28 00 23 f0    	mov    %ebx,-0xfdcffd8(%eax)
	e->env_status = ENV_RUNNING;
f01034bd:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	e->env_runs++;
f01034c4:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(e->env_pgdir));
f01034c8:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034cb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034d0:	77 15                	ja     f01034e7 <env_run+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034d2:	50                   	push   %eax
f01034d3:	68 28 5f 10 f0       	push   $0xf0105f28
f01034d8:	68 30 02 00 00       	push   $0x230
f01034dd:	68 82 71 10 f0       	push   $0xf0107182
f01034e2:	e8 59 cb ff ff       	call   f0100040 <_panic>
f01034e7:	05 00 00 00 10       	add    $0x10000000,%eax
f01034ec:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034ef:	83 ec 0c             	sub    $0xc,%esp
f01034f2:	68 c0 03 12 f0       	push   $0xf01203c0
f01034f7:	e8 55 26 00 00       	call   f0105b51 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034fc:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01034fe:	89 1c 24             	mov    %ebx,(%esp)
f0103501:	e8 27 ff ff ff       	call   f010342d <env_pop_tf>

f0103506 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103506:	55                   	push   %ebp
f0103507:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103509:	ba 70 00 00 00       	mov    $0x70,%edx
f010350e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103511:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103512:	ba 71 00 00 00       	mov    $0x71,%edx
f0103517:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103518:	0f b6 c0             	movzbl %al,%eax
}
f010351b:	5d                   	pop    %ebp
f010351c:	c3                   	ret    

f010351d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010351d:	55                   	push   %ebp
f010351e:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103520:	ba 70 00 00 00       	mov    $0x70,%edx
f0103525:	8b 45 08             	mov    0x8(%ebp),%eax
f0103528:	ee                   	out    %al,(%dx)
f0103529:	ba 71 00 00 00       	mov    $0x71,%edx
f010352e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103531:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103532:	5d                   	pop    %ebp
f0103533:	c3                   	ret    

f0103534 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103534:	55                   	push   %ebp
f0103535:	89 e5                	mov    %esp,%ebp
f0103537:	56                   	push   %esi
f0103538:	53                   	push   %ebx
f0103539:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010353c:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103542:	80 3d 4c f2 22 f0 00 	cmpb   $0x0,0xf022f24c
f0103549:	74 5a                	je     f01035a5 <irq_setmask_8259A+0x71>
f010354b:	89 c6                	mov    %eax,%esi
f010354d:	ba 21 00 00 00       	mov    $0x21,%edx
f0103552:	ee                   	out    %al,(%dx)
f0103553:	66 c1 e8 08          	shr    $0x8,%ax
f0103557:	ba a1 00 00 00       	mov    $0xa1,%edx
f010355c:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010355d:	83 ec 0c             	sub    $0xc,%esp
f0103560:	68 d3 71 10 f0       	push   $0xf01071d3
f0103565:	e8 1b 01 00 00       	call   f0103685 <cprintf>
f010356a:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010356d:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103572:	0f b7 f6             	movzwl %si,%esi
f0103575:	f7 d6                	not    %esi
f0103577:	0f a3 de             	bt     %ebx,%esi
f010357a:	73 11                	jae    f010358d <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010357c:	83 ec 08             	sub    $0x8,%esp
f010357f:	53                   	push   %ebx
f0103580:	68 93 76 10 f0       	push   $0xf0107693
f0103585:	e8 fb 00 00 00       	call   f0103685 <cprintf>
f010358a:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010358d:	83 c3 01             	add    $0x1,%ebx
f0103590:	83 fb 10             	cmp    $0x10,%ebx
f0103593:	75 e2                	jne    f0103577 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103595:	83 ec 0c             	sub    $0xc,%esp
f0103598:	68 9c 62 10 f0       	push   $0xf010629c
f010359d:	e8 e3 00 00 00       	call   f0103685 <cprintf>
f01035a2:	83 c4 10             	add    $0x10,%esp
}
f01035a5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035a8:	5b                   	pop    %ebx
f01035a9:	5e                   	pop    %esi
f01035aa:	5d                   	pop    %ebp
f01035ab:	c3                   	ret    

f01035ac <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035ac:	c6 05 4c f2 22 f0 01 	movb   $0x1,0xf022f24c
f01035b3:	ba 21 00 00 00       	mov    $0x21,%edx
f01035b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035bd:	ee                   	out    %al,(%dx)
f01035be:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035c3:	ee                   	out    %al,(%dx)
f01035c4:	ba 20 00 00 00       	mov    $0x20,%edx
f01035c9:	b8 11 00 00 00       	mov    $0x11,%eax
f01035ce:	ee                   	out    %al,(%dx)
f01035cf:	ba 21 00 00 00       	mov    $0x21,%edx
f01035d4:	b8 20 00 00 00       	mov    $0x20,%eax
f01035d9:	ee                   	out    %al,(%dx)
f01035da:	b8 04 00 00 00       	mov    $0x4,%eax
f01035df:	ee                   	out    %al,(%dx)
f01035e0:	b8 03 00 00 00       	mov    $0x3,%eax
f01035e5:	ee                   	out    %al,(%dx)
f01035e6:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035eb:	b8 11 00 00 00       	mov    $0x11,%eax
f01035f0:	ee                   	out    %al,(%dx)
f01035f1:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035f6:	b8 28 00 00 00       	mov    $0x28,%eax
f01035fb:	ee                   	out    %al,(%dx)
f01035fc:	b8 02 00 00 00       	mov    $0x2,%eax
f0103601:	ee                   	out    %al,(%dx)
f0103602:	b8 01 00 00 00       	mov    $0x1,%eax
f0103607:	ee                   	out    %al,(%dx)
f0103608:	ba 20 00 00 00       	mov    $0x20,%edx
f010360d:	b8 68 00 00 00       	mov    $0x68,%eax
f0103612:	ee                   	out    %al,(%dx)
f0103613:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103618:	ee                   	out    %al,(%dx)
f0103619:	ba a0 00 00 00       	mov    $0xa0,%edx
f010361e:	b8 68 00 00 00       	mov    $0x68,%eax
f0103623:	ee                   	out    %al,(%dx)
f0103624:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103629:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f010362a:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f0103631:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103635:	74 13                	je     f010364a <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103637:	55                   	push   %ebp
f0103638:	89 e5                	mov    %esp,%ebp
f010363a:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010363d:	0f b7 c0             	movzwl %ax,%eax
f0103640:	50                   	push   %eax
f0103641:	e8 ee fe ff ff       	call   f0103534 <irq_setmask_8259A>
f0103646:	83 c4 10             	add    $0x10,%esp
}
f0103649:	c9                   	leave  
f010364a:	f3 c3                	repz ret 

f010364c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010364c:	55                   	push   %ebp
f010364d:	89 e5                	mov    %esp,%ebp
f010364f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103652:	ff 75 08             	pushl  0x8(%ebp)
f0103655:	e8 0a d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f010365a:	83 c4 10             	add    $0x10,%esp
f010365d:	c9                   	leave  
f010365e:	c3                   	ret    

f010365f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010365f:	55                   	push   %ebp
f0103660:	89 e5                	mov    %esp,%ebp
f0103662:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103665:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010366c:	ff 75 0c             	pushl  0xc(%ebp)
f010366f:	ff 75 08             	pushl  0x8(%ebp)
f0103672:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103675:	50                   	push   %eax
f0103676:	68 4c 36 10 f0       	push   $0xf010364c
f010367b:	e8 39 15 00 00       	call   f0104bb9 <vprintfmt>
	return cnt;
}
f0103680:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103683:	c9                   	leave  
f0103684:	c3                   	ret    

f0103685 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103685:	55                   	push   %ebp
f0103686:	89 e5                	mov    %esp,%ebp
f0103688:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010368b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010368e:	50                   	push   %eax
f010368f:	ff 75 08             	pushl  0x8(%ebp)
f0103692:	e8 c8 ff ff ff       	call   f010365f <vcprintf>
	va_end(ap);

	return cnt;
}
f0103697:	c9                   	leave  
f0103698:	c3                   	ret    

f0103699 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103699:	55                   	push   %ebp
f010369a:	89 e5                	mov    %esp,%ebp
f010369c:	57                   	push   %edi
f010369d:	56                   	push   %esi
f010369e:	53                   	push   %ebx
f010369f:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:	

	// Setup a TSS so that -we get the right stack
	// when we trap to the kernel.
	size_t id = thiscpu->cpu_id;
f01036a2:	e8 9f 21 00 00       	call   f0105846 <cpunum>
f01036a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01036aa:	0f b6 b0 20 00 23 f0 	movzbl -0xfdcffe0(%eax),%esi
f01036b1:	89 f0                	mov    %esi,%eax
f01036b3:	0f b6 d8             	movzbl %al,%ebx

	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f01036b6:	e8 8b 21 00 00       	call   f0105846 <cpunum>
f01036bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01036be:	66 c7 80 92 00 23 f0 	movw   $0x68,-0xfdcff6e(%eax)
f01036c5:	68 00 
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036c7:	e8 7a 21 00 00       	call   f0105846 <cpunum>
f01036cc:	6b c0 74             	imul   $0x74,%eax,%eax
f01036cf:	66 c7 80 34 00 23 f0 	movw   $0x10,-0xfdcffcc(%eax)
f01036d6:	10 00 
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - id * (KSTKSIZE + KSTKGAP);
f01036d8:	e8 69 21 00 00       	call   f0105846 <cpunum>
f01036dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01036e0:	89 da                	mov    %ebx,%edx
f01036e2:	f7 da                	neg    %edx
f01036e4:	c1 e2 10             	shl    $0x10,%edx
f01036e7:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01036ed:	89 90 30 00 23 f0    	mov    %edx,-0xfdcffd0(%eax)

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01036f3:	83 c3 05             	add    $0x5,%ebx
f01036f6:	e8 4b 21 00 00       	call   f0105846 <cpunum>
f01036fb:	89 c7                	mov    %eax,%edi
f01036fd:	e8 44 21 00 00       	call   f0105846 <cpunum>
f0103702:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103705:	e8 3c 21 00 00       	call   f0105846 <cpunum>
f010370a:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f0103711:	f0 67 00 
f0103714:	6b ff 74             	imul   $0x74,%edi,%edi
f0103717:	81 c7 2c 00 23 f0    	add    $0xf023002c,%edi
f010371d:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f0103724:	f0 
f0103725:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103729:	81 c2 2c 00 23 f0    	add    $0xf023002c,%edx
f010372f:	c1 ea 10             	shr    $0x10,%edx
f0103732:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f0103739:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f0103740:	40 
f0103741:	6b c0 74             	imul   $0x74,%eax,%eax
f0103744:	05 2c 00 23 f0       	add    $0xf023002c,%eax
f0103749:	c1 e8 18             	shr    $0x18,%eax
f010374c:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + id].sd_s = 0;
f0103753:	c6 04 dd 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%ebx,8)
f010375a:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010375b:	89 f0                	mov    %esi,%eax
f010375d:	0f b6 f0             	movzbl %al,%esi
f0103760:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f0103767:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010376a:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f010376f:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (id << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103772:	83 c4 1c             	add    $0x1c,%esp
f0103775:	5b                   	pop    %ebx
f0103776:	5e                   	pop    %esi
f0103777:	5f                   	pop    %edi
f0103778:	5d                   	pop    %ebp
f0103779:	c3                   	ret    

f010377a <trap_init>:
}


void
trap_init(void)
{
f010377a:	55                   	push   %ebp
f010377b:	89 e5                	mov    %esp,%ebp
f010377d:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0103780:	b8 36 40 10 f0       	mov    $0xf0104036,%eax
f0103785:	66 a3 60 f2 22 f0    	mov    %ax,0xf022f260
f010378b:	66 c7 05 62 f2 22 f0 	movw   $0x8,0xf022f262
f0103792:	08 00 
f0103794:	c6 05 64 f2 22 f0 00 	movb   $0x0,0xf022f264
f010379b:	c6 05 65 f2 22 f0 8e 	movb   $0x8e,0xf022f265
f01037a2:	c1 e8 10             	shr    $0x10,%eax
f01037a5:	66 a3 66 f2 22 f0    	mov    %ax,0xf022f266
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f01037ab:	b8 40 40 10 f0       	mov    $0xf0104040,%eax
f01037b0:	66 a3 68 f2 22 f0    	mov    %ax,0xf022f268
f01037b6:	66 c7 05 6a f2 22 f0 	movw   $0x8,0xf022f26a
f01037bd:	08 00 
f01037bf:	c6 05 6c f2 22 f0 00 	movb   $0x0,0xf022f26c
f01037c6:	c6 05 6d f2 22 f0 8e 	movb   $0x8e,0xf022f26d
f01037cd:	c1 e8 10             	shr    $0x10,%eax
f01037d0:	66 a3 6e f2 22 f0    	mov    %ax,0xf022f26e
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f01037d6:	b8 4a 40 10 f0       	mov    $0xf010404a,%eax
f01037db:	66 a3 70 f2 22 f0    	mov    %ax,0xf022f270
f01037e1:	66 c7 05 72 f2 22 f0 	movw   $0x8,0xf022f272
f01037e8:	08 00 
f01037ea:	c6 05 74 f2 22 f0 00 	movb   $0x0,0xf022f274
f01037f1:	c6 05 75 f2 22 f0 8e 	movb   $0x8e,0xf022f275
f01037f8:	c1 e8 10             	shr    $0x10,%eax
f01037fb:	66 a3 76 f2 22 f0    	mov    %ax,0xf022f276
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f0103801:	b8 54 40 10 f0       	mov    $0xf0104054,%eax
f0103806:	66 a3 78 f2 22 f0    	mov    %ax,0xf022f278
f010380c:	66 c7 05 7a f2 22 f0 	movw   $0x8,0xf022f27a
f0103813:	08 00 
f0103815:	c6 05 7c f2 22 f0 00 	movb   $0x0,0xf022f27c
f010381c:	c6 05 7d f2 22 f0 ee 	movb   $0xee,0xf022f27d
f0103823:	c1 e8 10             	shr    $0x10,%eax
f0103826:	66 a3 7e f2 22 f0    	mov    %ax,0xf022f27e
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f010382c:	b8 5e 40 10 f0       	mov    $0xf010405e,%eax
f0103831:	66 a3 80 f2 22 f0    	mov    %ax,0xf022f280
f0103837:	66 c7 05 82 f2 22 f0 	movw   $0x8,0xf022f282
f010383e:	08 00 
f0103840:	c6 05 84 f2 22 f0 00 	movb   $0x0,0xf022f284
f0103847:	c6 05 85 f2 22 f0 8e 	movb   $0x8e,0xf022f285
f010384e:	c1 e8 10             	shr    $0x10,%eax
f0103851:	66 a3 86 f2 22 f0    	mov    %ax,0xf022f286
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f0103857:	b8 68 40 10 f0       	mov    $0xf0104068,%eax
f010385c:	66 a3 88 f2 22 f0    	mov    %ax,0xf022f288
f0103862:	66 c7 05 8a f2 22 f0 	movw   $0x8,0xf022f28a
f0103869:	08 00 
f010386b:	c6 05 8c f2 22 f0 00 	movb   $0x0,0xf022f28c
f0103872:	c6 05 8d f2 22 f0 8e 	movb   $0x8e,0xf022f28d
f0103879:	c1 e8 10             	shr    $0x10,%eax
f010387c:	66 a3 8e f2 22 f0    	mov    %ax,0xf022f28e
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f0103882:	b8 72 40 10 f0       	mov    $0xf0104072,%eax
f0103887:	66 a3 90 f2 22 f0    	mov    %ax,0xf022f290
f010388d:	66 c7 05 92 f2 22 f0 	movw   $0x8,0xf022f292
f0103894:	08 00 
f0103896:	c6 05 94 f2 22 f0 00 	movb   $0x0,0xf022f294
f010389d:	c6 05 95 f2 22 f0 8e 	movb   $0x8e,0xf022f295
f01038a4:	c1 e8 10             	shr    $0x10,%eax
f01038a7:	66 a3 96 f2 22 f0    	mov    %ax,0xf022f296
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f01038ad:	b8 7c 40 10 f0       	mov    $0xf010407c,%eax
f01038b2:	66 a3 98 f2 22 f0    	mov    %ax,0xf022f298
f01038b8:	66 c7 05 9a f2 22 f0 	movw   $0x8,0xf022f29a
f01038bf:	08 00 
f01038c1:	c6 05 9c f2 22 f0 00 	movb   $0x0,0xf022f29c
f01038c8:	c6 05 9d f2 22 f0 8e 	movb   $0x8e,0xf022f29d
f01038cf:	c1 e8 10             	shr    $0x10,%eax
f01038d2:	66 a3 9e f2 22 f0    	mov    %ax,0xf022f29e
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01038d8:	b8 86 40 10 f0       	mov    $0xf0104086,%eax
f01038dd:	66 a3 a0 f2 22 f0    	mov    %ax,0xf022f2a0
f01038e3:	66 c7 05 a2 f2 22 f0 	movw   $0x8,0xf022f2a2
f01038ea:	08 00 
f01038ec:	c6 05 a4 f2 22 f0 00 	movb   $0x0,0xf022f2a4
f01038f3:	c6 05 a5 f2 22 f0 8e 	movb   $0x8e,0xf022f2a5
f01038fa:	c1 e8 10             	shr    $0x10,%eax
f01038fd:	66 a3 a6 f2 22 f0    	mov    %ax,0xf022f2a6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f0103903:	b8 8e 40 10 f0       	mov    $0xf010408e,%eax
f0103908:	66 a3 b0 f2 22 f0    	mov    %ax,0xf022f2b0
f010390e:	66 c7 05 b2 f2 22 f0 	movw   $0x8,0xf022f2b2
f0103915:	08 00 
f0103917:	c6 05 b4 f2 22 f0 00 	movb   $0x0,0xf022f2b4
f010391e:	c6 05 b5 f2 22 f0 8e 	movb   $0x8e,0xf022f2b5
f0103925:	c1 e8 10             	shr    $0x10,%eax
f0103928:	66 a3 b6 f2 22 f0    	mov    %ax,0xf022f2b6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f010392e:	b8 96 40 10 f0       	mov    $0xf0104096,%eax
f0103933:	66 a3 b8 f2 22 f0    	mov    %ax,0xf022f2b8
f0103939:	66 c7 05 ba f2 22 f0 	movw   $0x8,0xf022f2ba
f0103940:	08 00 
f0103942:	c6 05 bc f2 22 f0 00 	movb   $0x0,0xf022f2bc
f0103949:	c6 05 bd f2 22 f0 8e 	movb   $0x8e,0xf022f2bd
f0103950:	c1 e8 10             	shr    $0x10,%eax
f0103953:	66 a3 be f2 22 f0    	mov    %ax,0xf022f2be
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f0103959:	b8 9e 40 10 f0       	mov    $0xf010409e,%eax
f010395e:	66 a3 c0 f2 22 f0    	mov    %ax,0xf022f2c0
f0103964:	66 c7 05 c2 f2 22 f0 	movw   $0x8,0xf022f2c2
f010396b:	08 00 
f010396d:	c6 05 c4 f2 22 f0 00 	movb   $0x0,0xf022f2c4
f0103974:	c6 05 c5 f2 22 f0 8e 	movb   $0x8e,0xf022f2c5
f010397b:	c1 e8 10             	shr    $0x10,%eax
f010397e:	66 a3 c6 f2 22 f0    	mov    %ax,0xf022f2c6
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f0103984:	b8 a6 40 10 f0       	mov    $0xf01040a6,%eax
f0103989:	66 a3 c8 f2 22 f0    	mov    %ax,0xf022f2c8
f010398f:	66 c7 05 ca f2 22 f0 	movw   $0x8,0xf022f2ca
f0103996:	08 00 
f0103998:	c6 05 cc f2 22 f0 00 	movb   $0x0,0xf022f2cc
f010399f:	c6 05 cd f2 22 f0 8e 	movb   $0x8e,0xf022f2cd
f01039a6:	c1 e8 10             	shr    $0x10,%eax
f01039a9:	66 a3 ce f2 22 f0    	mov    %ax,0xf022f2ce
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f01039af:	b8 ae 40 10 f0       	mov    $0xf01040ae,%eax
f01039b4:	66 a3 d0 f2 22 f0    	mov    %ax,0xf022f2d0
f01039ba:	66 c7 05 d2 f2 22 f0 	movw   $0x8,0xf022f2d2
f01039c1:	08 00 
f01039c3:	c6 05 d4 f2 22 f0 00 	movb   $0x0,0xf022f2d4
f01039ca:	c6 05 d5 f2 22 f0 8e 	movb   $0x8e,0xf022f2d5
f01039d1:	c1 e8 10             	shr    $0x10,%eax
f01039d4:	66 a3 d6 f2 22 f0    	mov    %ax,0xf022f2d6
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01039da:	b8 b6 40 10 f0       	mov    $0xf01040b6,%eax
f01039df:	66 a3 e0 f2 22 f0    	mov    %ax,0xf022f2e0
f01039e5:	66 c7 05 e2 f2 22 f0 	movw   $0x8,0xf022f2e2
f01039ec:	08 00 
f01039ee:	c6 05 e4 f2 22 f0 00 	movb   $0x0,0xf022f2e4
f01039f5:	c6 05 e5 f2 22 f0 8e 	movb   $0x8e,0xf022f2e5
f01039fc:	c1 e8 10             	shr    $0x10,%eax
f01039ff:	66 a3 e6 f2 22 f0    	mov    %ax,0xf022f2e6
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f0103a05:	b8 bc 40 10 f0       	mov    $0xf01040bc,%eax
f0103a0a:	66 a3 e8 f2 22 f0    	mov    %ax,0xf022f2e8
f0103a10:	66 c7 05 ea f2 22 f0 	movw   $0x8,0xf022f2ea
f0103a17:	08 00 
f0103a19:	c6 05 ec f2 22 f0 00 	movb   $0x0,0xf022f2ec
f0103a20:	c6 05 ed f2 22 f0 8e 	movb   $0x8e,0xf022f2ed
f0103a27:	c1 e8 10             	shr    $0x10,%eax
f0103a2a:	66 a3 ee f2 22 f0    	mov    %ax,0xf022f2ee
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103a30:	b8 c0 40 10 f0       	mov    $0xf01040c0,%eax
f0103a35:	66 a3 f0 f2 22 f0    	mov    %ax,0xf022f2f0
f0103a3b:	66 c7 05 f2 f2 22 f0 	movw   $0x8,0xf022f2f2
f0103a42:	08 00 
f0103a44:	c6 05 f4 f2 22 f0 00 	movb   $0x0,0xf022f2f4
f0103a4b:	c6 05 f5 f2 22 f0 8e 	movb   $0x8e,0xf022f2f5
f0103a52:	c1 e8 10             	shr    $0x10,%eax
f0103a55:	66 a3 f6 f2 22 f0    	mov    %ax,0xf022f2f6
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103a5b:	b8 c6 40 10 f0       	mov    $0xf01040c6,%eax
f0103a60:	66 a3 f8 f2 22 f0    	mov    %ax,0xf022f2f8
f0103a66:	66 c7 05 fa f2 22 f0 	movw   $0x8,0xf022f2fa
f0103a6d:	08 00 
f0103a6f:	c6 05 fc f2 22 f0 00 	movb   $0x0,0xf022f2fc
f0103a76:	c6 05 fd f2 22 f0 8e 	movb   $0x8e,0xf022f2fd
f0103a7d:	c1 e8 10             	shr    $0x10,%eax
f0103a80:	66 a3 fe f2 22 f0    	mov    %ax,0xf022f2fe
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 0, GD_KT, TH_SYSCALL, 3); 
f0103a86:	b8 cc 40 10 f0       	mov    $0xf01040cc,%eax
f0103a8b:	66 a3 e0 f3 22 f0    	mov    %ax,0xf022f3e0
f0103a91:	66 c7 05 e2 f3 22 f0 	movw   $0x8,0xf022f3e2
f0103a98:	08 00 
f0103a9a:	c6 05 e4 f3 22 f0 00 	movb   $0x0,0xf022f3e4
f0103aa1:	c6 05 e5 f3 22 f0 ee 	movb   $0xee,0xf022f3e5
f0103aa8:	c1 e8 10             	shr    $0x10,%eax
f0103aab:	66 a3 e6 f3 22 f0    	mov    %ax,0xf022f3e6
	
	extern void TH_IRQ_TIMER(); 	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, TH_IRQ_TIMER, 0);
f0103ab1:	b8 d2 40 10 f0       	mov    $0xf01040d2,%eax
f0103ab6:	66 a3 60 f3 22 f0    	mov    %ax,0xf022f360
f0103abc:	66 c7 05 62 f3 22 f0 	movw   $0x8,0xf022f362
f0103ac3:	08 00 
f0103ac5:	c6 05 64 f3 22 f0 00 	movb   $0x0,0xf022f364
f0103acc:	c6 05 65 f3 22 f0 8e 	movb   $0x8e,0xf022f365
f0103ad3:	c1 e8 10             	shr    $0x10,%eax
f0103ad6:	66 a3 66 f3 22 f0    	mov    %ax,0xf022f366
	extern void TH_IRQ_13();
	extern void TH_IRQ_IDE();
	extern void TH_IRQ_15();

	// Per-CPU setup 
	trap_init_percpu();
f0103adc:	e8 b8 fb ff ff       	call   f0103699 <trap_init_percpu>
}
f0103ae1:	c9                   	leave  
f0103ae2:	c3                   	ret    

f0103ae3 <print_regs>:
	}
}

void	
print_regs(struct PushRegs *regs)
{
f0103ae3:	55                   	push   %ebp
f0103ae4:	89 e5                	mov    %esp,%ebp
f0103ae6:	53                   	push   %ebx
f0103ae7:	83 ec 0c             	sub    $0xc,%esp
f0103aea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103aed:	ff 33                	pushl  (%ebx)
f0103aef:	68 e7 71 10 f0       	push   $0xf01071e7
f0103af4:	e8 8c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103af9:	83 c4 08             	add    $0x8,%esp
f0103afc:	ff 73 04             	pushl  0x4(%ebx)
f0103aff:	68 f6 71 10 f0       	push   $0xf01071f6
f0103b04:	e8 7c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b09:	83 c4 08             	add    $0x8,%esp
f0103b0c:	ff 73 08             	pushl  0x8(%ebx)
f0103b0f:	68 05 72 10 f0       	push   $0xf0107205
f0103b14:	e8 6c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b19:	83 c4 08             	add    $0x8,%esp
f0103b1c:	ff 73 0c             	pushl  0xc(%ebx)
f0103b1f:	68 14 72 10 f0       	push   $0xf0107214
f0103b24:	e8 5c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b29:	83 c4 08             	add    $0x8,%esp
f0103b2c:	ff 73 10             	pushl  0x10(%ebx)
f0103b2f:	68 23 72 10 f0       	push   $0xf0107223
f0103b34:	e8 4c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b39:	83 c4 08             	add    $0x8,%esp
f0103b3c:	ff 73 14             	pushl  0x14(%ebx)
f0103b3f:	68 32 72 10 f0       	push   $0xf0107232
f0103b44:	e8 3c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b49:	83 c4 08             	add    $0x8,%esp
f0103b4c:	ff 73 18             	pushl  0x18(%ebx)
f0103b4f:	68 41 72 10 f0       	push   $0xf0107241
f0103b54:	e8 2c fb ff ff       	call   f0103685 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b59:	83 c4 08             	add    $0x8,%esp
f0103b5c:	ff 73 1c             	pushl  0x1c(%ebx)
f0103b5f:	68 50 72 10 f0       	push   $0xf0107250
f0103b64:	e8 1c fb ff ff       	call   f0103685 <cprintf>
}
f0103b69:	83 c4 10             	add    $0x10,%esp
f0103b6c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b6f:	c9                   	leave  
f0103b70:	c3                   	ret    

f0103b71 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b71:	55                   	push   %ebp
f0103b72:	89 e5                	mov    %esp,%ebp
f0103b74:	56                   	push   %esi
f0103b75:	53                   	push   %ebx
f0103b76:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103b79:	e8 c8 1c 00 00       	call   f0105846 <cpunum>
f0103b7e:	83 ec 04             	sub    $0x4,%esp
f0103b81:	50                   	push   %eax
f0103b82:	53                   	push   %ebx
f0103b83:	68 b4 72 10 f0       	push   $0xf01072b4
f0103b88:	e8 f8 fa ff ff       	call   f0103685 <cprintf>
	print_regs(&tf->tf_regs);
f0103b8d:	89 1c 24             	mov    %ebx,(%esp)
f0103b90:	e8 4e ff ff ff       	call   f0103ae3 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b95:	83 c4 08             	add    $0x8,%esp
f0103b98:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b9c:	50                   	push   %eax
f0103b9d:	68 d2 72 10 f0       	push   $0xf01072d2
f0103ba2:	e8 de fa ff ff       	call   f0103685 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103ba7:	83 c4 08             	add    $0x8,%esp
f0103baa:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103bae:	50                   	push   %eax
f0103baf:	68 e5 72 10 f0       	push   $0xf01072e5
f0103bb4:	e8 cc fa ff ff       	call   f0103685 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bb9:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103bbc:	83 c4 10             	add    $0x10,%esp
f0103bbf:	83 f8 13             	cmp    $0x13,%eax
f0103bc2:	77 09                	ja     f0103bcd <print_trapframe+0x5c>
		return excnames[trapno];
f0103bc4:	8b 14 85 80 75 10 f0 	mov    -0xfef8a80(,%eax,4),%edx
f0103bcb:	eb 1f                	jmp    f0103bec <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103bcd:	83 f8 30             	cmp    $0x30,%eax
f0103bd0:	74 15                	je     f0103be7 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103bd2:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103bd5:	83 fa 10             	cmp    $0x10,%edx
f0103bd8:	b9 7e 72 10 f0       	mov    $0xf010727e,%ecx
f0103bdd:	ba 6b 72 10 f0       	mov    $0xf010726b,%edx
f0103be2:	0f 43 d1             	cmovae %ecx,%edx
f0103be5:	eb 05                	jmp    f0103bec <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103be7:	ba 5f 72 10 f0       	mov    $0xf010725f,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bec:	83 ec 04             	sub    $0x4,%esp
f0103bef:	52                   	push   %edx
f0103bf0:	50                   	push   %eax
f0103bf1:	68 f8 72 10 f0       	push   $0xf01072f8
f0103bf6:	e8 8a fa ff ff       	call   f0103685 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bfb:	83 c4 10             	add    $0x10,%esp
f0103bfe:	3b 1d 60 fa 22 f0    	cmp    0xf022fa60,%ebx
f0103c04:	75 1a                	jne    f0103c20 <print_trapframe+0xaf>
f0103c06:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c0a:	75 14                	jne    f0103c20 <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103c0c:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103c0f:	83 ec 08             	sub    $0x8,%esp
f0103c12:	50                   	push   %eax
f0103c13:	68 0a 73 10 f0       	push   $0xf010730a
f0103c18:	e8 68 fa ff ff       	call   f0103685 <cprintf>
f0103c1d:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103c20:	83 ec 08             	sub    $0x8,%esp
f0103c23:	ff 73 2c             	pushl  0x2c(%ebx)
f0103c26:	68 19 73 10 f0       	push   $0xf0107319
f0103c2b:	e8 55 fa ff ff       	call   f0103685 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103c30:	83 c4 10             	add    $0x10,%esp
f0103c33:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c37:	75 49                	jne    f0103c82 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c39:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c3c:	89 c2                	mov    %eax,%edx
f0103c3e:	83 e2 01             	and    $0x1,%edx
f0103c41:	ba 98 72 10 f0       	mov    $0xf0107298,%edx
f0103c46:	b9 8d 72 10 f0       	mov    $0xf010728d,%ecx
f0103c4b:	0f 44 ca             	cmove  %edx,%ecx
f0103c4e:	89 c2                	mov    %eax,%edx
f0103c50:	83 e2 02             	and    $0x2,%edx
f0103c53:	ba aa 72 10 f0       	mov    $0xf01072aa,%edx
f0103c58:	be a4 72 10 f0       	mov    $0xf01072a4,%esi
f0103c5d:	0f 45 d6             	cmovne %esi,%edx
f0103c60:	83 e0 04             	and    $0x4,%eax
f0103c63:	be f7 73 10 f0       	mov    $0xf01073f7,%esi
f0103c68:	b8 af 72 10 f0       	mov    $0xf01072af,%eax
f0103c6d:	0f 44 c6             	cmove  %esi,%eax
f0103c70:	51                   	push   %ecx
f0103c71:	52                   	push   %edx
f0103c72:	50                   	push   %eax
f0103c73:	68 27 73 10 f0       	push   $0xf0107327
f0103c78:	e8 08 fa ff ff       	call   f0103685 <cprintf>
f0103c7d:	83 c4 10             	add    $0x10,%esp
f0103c80:	eb 10                	jmp    f0103c92 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c82:	83 ec 0c             	sub    $0xc,%esp
f0103c85:	68 9c 62 10 f0       	push   $0xf010629c
f0103c8a:	e8 f6 f9 ff ff       	call   f0103685 <cprintf>
f0103c8f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c92:	83 ec 08             	sub    $0x8,%esp
f0103c95:	ff 73 30             	pushl  0x30(%ebx)
f0103c98:	68 36 73 10 f0       	push   $0xf0107336
f0103c9d:	e8 e3 f9 ff ff       	call   f0103685 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ca2:	83 c4 08             	add    $0x8,%esp
f0103ca5:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103ca9:	50                   	push   %eax
f0103caa:	68 45 73 10 f0       	push   $0xf0107345
f0103caf:	e8 d1 f9 ff ff       	call   f0103685 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103cb4:	83 c4 08             	add    $0x8,%esp
f0103cb7:	ff 73 38             	pushl  0x38(%ebx)
f0103cba:	68 58 73 10 f0       	push   $0xf0107358
f0103cbf:	e8 c1 f9 ff ff       	call   f0103685 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103cc4:	83 c4 10             	add    $0x10,%esp
f0103cc7:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ccb:	74 25                	je     f0103cf2 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103ccd:	83 ec 08             	sub    $0x8,%esp
f0103cd0:	ff 73 3c             	pushl  0x3c(%ebx)
f0103cd3:	68 67 73 10 f0       	push   $0xf0107367
f0103cd8:	e8 a8 f9 ff ff       	call   f0103685 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103cdd:	83 c4 08             	add    $0x8,%esp
f0103ce0:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103ce4:	50                   	push   %eax
f0103ce5:	68 76 73 10 f0       	push   $0xf0107376
f0103cea:	e8 96 f9 ff ff       	call   f0103685 <cprintf>
f0103cef:	83 c4 10             	add    $0x10,%esp
	}
}
f0103cf2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103cf5:	5b                   	pop    %ebx
f0103cf6:	5e                   	pop    %esi
f0103cf7:	5d                   	pop    %ebp
f0103cf8:	c3                   	ret    

f0103cf9 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cf9:	55                   	push   %ebp
f0103cfa:	89 e5                	mov    %esp,%ebp
f0103cfc:	57                   	push   %edi
f0103cfd:	56                   	push   %esi
f0103cfe:	53                   	push   %ebx
f0103cff:	83 ec 1c             	sub    $0x1c,%esp
f0103d02:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103d05:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f0103d08:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d0c:	75 17                	jne    f0103d25 <page_fault_handler+0x2c>
		panic("Kernel page fault!");	
f0103d0e:	83 ec 04             	sub    $0x4,%esp
f0103d11:	68 89 73 10 f0       	push   $0xf0107389
f0103d16:	68 50 01 00 00       	push   $0x150
f0103d1b:	68 9c 73 10 f0       	push   $0xf010739c
f0103d20:	e8 1b c3 ff ff       	call   f0100040 <_panic>
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
f0103d25:	e8 1c 1b 00 00       	call   f0105846 <cpunum>
f0103d2a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d2d:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103d33:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103d37:	0f 84 92 00 00 00    	je     f0103dcf <page_fault_handler+0xd6>
	{
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
		
		if(tf->tf_esp > USTACKTOP)
f0103d3d:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103d40:	3d 00 e0 bf ee       	cmp    $0xeebfe000,%eax
f0103d45:	76 0d                	jbe    f0103d54 <page_fault_handler+0x5b>
		{
			size += 4;
			userTF = (struct UTrapframe*) (tf->tf_esp - size);
f0103d47:	83 e8 38             	sub    $0x38,%eax
f0103d4a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
		
		if(tf->tf_esp > USTACKTOP)
		{
			size += 4;
f0103d4d:	bf 38 00 00 00       	mov    $0x38,%edi
f0103d52:	eb 0c                	jmp    f0103d60 <page_fault_handler+0x67>

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
	{
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
f0103d54:	c7 45 e4 cc ff bf ee 	movl   $0xeebfffcc,-0x1c(%ebp)
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
	{
		size_t size = sizeof(struct UTrapframe);
f0103d5b:	bf 34 00 00 00       	mov    $0x34,%edi
		{
			size += 4;
			userTF = (struct UTrapframe*) (tf->tf_esp - size);
		}

		user_mem_assert(curenv, (void *) userTF, size, (PTE_U | PTE_W));
f0103d60:	e8 e1 1a 00 00       	call   f0105846 <cpunum>
f0103d65:	6a 06                	push   $0x6
f0103d67:	57                   	push   %edi
f0103d68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d6b:	57                   	push   %edi
f0103d6c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d6f:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103d75:	e8 ec ef ff ff       	call   f0102d66 <user_mem_assert>

		userTF->utf_fault_va = fault_va;
f0103d7a:	89 37                	mov    %esi,(%edi)
		userTF->utf_err = tf->tf_err; 
f0103d7c:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103d7f:	89 fa                	mov    %edi,%edx
f0103d81:	89 47 04             	mov    %eax,0x4(%edi)
		userTF->utf_regs = tf->tf_regs;
f0103d84:	8d 7f 08             	lea    0x8(%edi),%edi
f0103d87:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103d8c:	89 de                	mov    %ebx,%esi
f0103d8e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		userTF->utf_eip = tf->tf_eip; 
f0103d90:	8b 43 30             	mov    0x30(%ebx),%eax
f0103d93:	89 42 28             	mov    %eax,0x28(%edx)
		userTF->utf_eflags = tf->tf_eflags; 
f0103d96:	8b 43 38             	mov    0x38(%ebx),%eax
f0103d99:	89 42 2c             	mov    %eax,0x2c(%edx)
		userTF->utf_esp = tf->tf_esp;
f0103d9c:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103d9f:	89 42 30             	mov    %eax,0x30(%edx)

		tf->tf_esp = (uint32_t) userTF;
f0103da2:	89 53 3c             	mov    %edx,0x3c(%ebx)
		tf->tf_eip = (uint32_t) curenv->env_pgfault_upcall;
f0103da5:	e8 9c 1a 00 00       	call   f0105846 <cpunum>
f0103daa:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dad:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103db3:	8b 40 64             	mov    0x64(%eax),%eax
f0103db6:	89 43 30             	mov    %eax,0x30(%ebx)

		env_run(curenv);		
f0103db9:	e8 88 1a 00 00       	call   f0105846 <cpunum>
f0103dbe:	83 c4 04             	add    $0x4,%esp
f0103dc1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dc4:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103dca:	e8 9c f6 ff ff       	call   f010346b <env_run>
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103dcf:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103dd2:	e8 6f 1a 00 00       	call   f0105846 <cpunum>

		env_run(curenv);		
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103dd7:	57                   	push   %edi
f0103dd8:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103dd9:	6b c0 74             	imul   $0x74,%eax,%eax

		env_run(curenv);		
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ddc:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103de2:	ff 70 48             	pushl  0x48(%eax)
f0103de5:	68 44 75 10 f0       	push   $0xf0107544
f0103dea:	e8 96 f8 ff ff       	call   f0103685 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103def:	89 1c 24             	mov    %ebx,(%esp)
f0103df2:	e8 7a fd ff ff       	call   f0103b71 <print_trapframe>
	env_destroy(curenv);
f0103df7:	e8 4a 1a 00 00       	call   f0105846 <cpunum>
f0103dfc:	83 c4 04             	add    $0x4,%esp
f0103dff:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e02:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103e08:	e8 bf f5 ff ff       	call   f01033cc <env_destroy>
}
f0103e0d:	83 c4 10             	add    $0x10,%esp
f0103e10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e13:	5b                   	pop    %ebx
f0103e14:	5e                   	pop    %esi
f0103e15:	5f                   	pop    %edi
f0103e16:	5d                   	pop    %ebp
f0103e17:	c3                   	ret    

f0103e18 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103e18:	55                   	push   %ebp
f0103e19:	89 e5                	mov    %esp,%ebp
f0103e1b:	57                   	push   %edi
f0103e1c:	56                   	push   %esi
f0103e1d:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103e20:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103e21:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f0103e28:	74 01                	je     f0103e2b <trap+0x13>
		asm volatile("hlt");
f0103e2a:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103e2b:	e8 16 1a 00 00       	call   f0105846 <cpunum>
f0103e30:	6b d0 74             	imul   $0x74,%eax,%edx
f0103e33:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103e39:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e3e:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103e42:	83 f8 02             	cmp    $0x2,%eax
f0103e45:	75 10                	jne    f0103e57 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103e47:	83 ec 0c             	sub    $0xc,%esp
f0103e4a:	68 c0 03 12 f0       	push   $0xf01203c0
f0103e4f:	e8 60 1c 00 00       	call   f0105ab4 <spin_lock>
f0103e54:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103e57:	9c                   	pushf  
f0103e58:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103e59:	f6 c4 02             	test   $0x2,%ah
f0103e5c:	74 19                	je     f0103e77 <trap+0x5f>
f0103e5e:	68 a8 73 10 f0       	push   $0xf01073a8
f0103e63:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0103e68:	68 1a 01 00 00       	push   $0x11a
f0103e6d:	68 9c 73 10 f0       	push   $0xf010739c
f0103e72:	e8 c9 c1 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103e77:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103e7b:	83 e0 03             	and    $0x3,%eax
f0103e7e:	66 83 f8 03          	cmp    $0x3,%ax
f0103e82:	0f 85 a0 00 00 00    	jne    f0103f28 <trap+0x110>
f0103e88:	83 ec 0c             	sub    $0xc,%esp
f0103e8b:	68 c0 03 12 f0       	push   $0xf01203c0
f0103e90:	e8 1f 1c 00 00       	call   f0105ab4 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103e95:	e8 ac 19 00 00       	call   f0105846 <cpunum>
f0103e9a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e9d:	83 c4 10             	add    $0x10,%esp
f0103ea0:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103ea7:	75 19                	jne    f0103ec2 <trap+0xaa>
f0103ea9:	68 c1 73 10 f0       	push   $0xf01073c1
f0103eae:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0103eb3:	68 22 01 00 00       	push   $0x122
f0103eb8:	68 9c 73 10 f0       	push   $0xf010739c
f0103ebd:	e8 7e c1 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103ec2:	e8 7f 19 00 00       	call   f0105846 <cpunum>
f0103ec7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eca:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103ed0:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103ed4:	75 2d                	jne    f0103f03 <trap+0xeb>
			env_free(curenv);
f0103ed6:	e8 6b 19 00 00       	call   f0105846 <cpunum>
f0103edb:	83 ec 0c             	sub    $0xc,%esp
f0103ede:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ee1:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103ee7:	e8 05 f3 ff ff       	call   f01031f1 <env_free>
			curenv = NULL;
f0103eec:	e8 55 19 00 00       	call   f0105846 <cpunum>
f0103ef1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef4:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103efb:	00 00 00 
			sched_yield();
f0103efe:	e8 1b 03 00 00       	call   f010421e <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103f03:	e8 3e 19 00 00       	call   f0105846 <cpunum>
f0103f08:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103f11:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103f16:	89 c7                	mov    %eax,%edi
f0103f18:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103f1a:	e8 27 19 00 00       	call   f0105846 <cpunum>
f0103f1f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f22:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103f28:	89 35 60 fa 22 f0    	mov    %esi,0xf022fa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f0103f2e:	8b 46 28             	mov    0x28(%esi),%eax
f0103f31:	83 f8 0e             	cmp    $0xe,%eax
f0103f34:	74 0c                	je     f0103f42 <trap+0x12a>
f0103f36:	83 f8 30             	cmp    $0x30,%eax
f0103f39:	74 29                	je     f0103f64 <trap+0x14c>
f0103f3b:	83 f8 03             	cmp    $0x3,%eax
f0103f3e:	75 45                	jne    f0103f85 <trap+0x16d>
f0103f40:	eb 11                	jmp    f0103f53 <trap+0x13b>
	{
		case T_PGFLT: 	  page_fault_handler(tf); 	return;
f0103f42:	83 ec 0c             	sub    $0xc,%esp
f0103f45:	56                   	push   %esi
f0103f46:	e8 ae fd ff ff       	call   f0103cf9 <page_fault_handler>
f0103f4b:	83 c4 10             	add    $0x10,%esp
f0103f4e:	e9 a3 00 00 00       	jmp    f0103ff6 <trap+0x1de>

		case T_BRKPT:     monitor(tf);			return;
f0103f53:	83 ec 0c             	sub    $0xc,%esp
f0103f56:	56                   	push   %esi
f0103f57:	e8 fc c9 ff ff       	call   f0100958 <monitor>
f0103f5c:	83 c4 10             	add    $0x10,%esp
f0103f5f:	e9 92 00 00 00       	jmp    f0103ff6 <trap+0x1de>

		case T_SYSCALL:	  
				tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
f0103f64:	83 ec 08             	sub    $0x8,%esp
f0103f67:	ff 76 04             	pushl  0x4(%esi)
f0103f6a:	ff 36                	pushl  (%esi)
f0103f6c:	ff 76 10             	pushl  0x10(%esi)
f0103f6f:	ff 76 18             	pushl  0x18(%esi)
f0103f72:	ff 76 14             	pushl  0x14(%esi)
f0103f75:	ff 76 1c             	pushl  0x1c(%esi)
f0103f78:	e8 51 03 00 00       	call   f01042ce <syscall>
f0103f7d:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103f80:	83 c4 20             	add    $0x20,%esp
f0103f83:	eb 71                	jmp    f0103ff6 <trap+0x1de>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103f85:	83 f8 27             	cmp    $0x27,%eax
f0103f88:	75 1a                	jne    f0103fa4 <trap+0x18c>
		cprintf("Spurious interrupt on irq 7\n");
f0103f8a:	83 ec 0c             	sub    $0xc,%esp
f0103f8d:	68 c8 73 10 f0       	push   $0xf01073c8
f0103f92:	e8 ee f6 ff ff       	call   f0103685 <cprintf>
		print_trapframe(tf);
f0103f97:	89 34 24             	mov    %esi,(%esp)
f0103f9a:	e8 d2 fb ff ff       	call   f0103b71 <print_trapframe>
f0103f9f:	83 c4 10             	add    $0x10,%esp
f0103fa2:	eb 52                	jmp    f0103ff6 <trap+0x1de>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if(tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER)
f0103fa4:	83 f8 20             	cmp    $0x20,%eax
f0103fa7:	75 0a                	jne    f0103fb3 <trap+0x19b>
	{
		lapic_eoi();
f0103fa9:	e8 e3 19 00 00       	call   f0105991 <lapic_eoi>
		sched_yield();
f0103fae:	e8 6b 02 00 00       	call   f010421e <sched_yield>
		return;
	}


	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103fb3:	83 ec 0c             	sub    $0xc,%esp
f0103fb6:	56                   	push   %esi
f0103fb7:	e8 b5 fb ff ff       	call   f0103b71 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103fbc:	83 c4 10             	add    $0x10,%esp
f0103fbf:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103fc4:	75 17                	jne    f0103fdd <trap+0x1c5>
		panic("unhandled trap in kernel");
f0103fc6:	83 ec 04             	sub    $0x4,%esp
f0103fc9:	68 e5 73 10 f0       	push   $0xf01073e5
f0103fce:	68 00 01 00 00       	push   $0x100
f0103fd3:	68 9c 73 10 f0       	push   $0xf010739c
f0103fd8:	e8 63 c0 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103fdd:	e8 64 18 00 00       	call   f0105846 <cpunum>
f0103fe2:	83 ec 0c             	sub    $0xc,%esp
f0103fe5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fe8:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103fee:	e8 d9 f3 ff ff       	call   f01033cc <env_destroy>
f0103ff3:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ff6:	e8 4b 18 00 00       	call   f0105846 <cpunum>
f0103ffb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ffe:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104005:	74 2a                	je     f0104031 <trap+0x219>
f0104007:	e8 3a 18 00 00       	call   f0105846 <cpunum>
f010400c:	6b c0 74             	imul   $0x74,%eax,%eax
f010400f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104015:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104019:	75 16                	jne    f0104031 <trap+0x219>
		env_run(curenv);
f010401b:	e8 26 18 00 00       	call   f0105846 <cpunum>
f0104020:	83 ec 0c             	sub    $0xc,%esp
f0104023:	6b c0 74             	imul   $0x74,%eax,%eax
f0104026:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010402c:	e8 3a f4 ff ff       	call   f010346b <env_run>
	else
		sched_yield();
f0104031:	e8 e8 01 00 00       	call   f010421e <sched_yield>

f0104036 <TH_DIVIDE>:
	.p2align 2
	.globl TRAPHANDLERS
TRAPHANDLERS:
.text

TRAPHANDLER_NOEC(TH_DIVIDE, T_DIVIDE)	// fault
f0104036:	6a 00                	push   $0x0
f0104038:	6a 00                	push   $0x0
f010403a:	e9 f9 00 00 00       	jmp    f0104138 <_alltraps>
f010403f:	90                   	nop

f0104040 <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, T_DEBUG)	// fault/trap
f0104040:	6a 00                	push   $0x0
f0104042:	6a 01                	push   $0x1
f0104044:	e9 ef 00 00 00       	jmp    f0104138 <_alltraps>
f0104049:	90                   	nop

f010404a <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, T_NMI)		//
f010404a:	6a 00                	push   $0x0
f010404c:	6a 02                	push   $0x2
f010404e:	e9 e5 00 00 00       	jmp    f0104138 <_alltraps>
f0104053:	90                   	nop

f0104054 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, T_BRKPT)	// trap
f0104054:	6a 00                	push   $0x0
f0104056:	6a 03                	push   $0x3
f0104058:	e9 db 00 00 00       	jmp    f0104138 <_alltraps>
f010405d:	90                   	nop

f010405e <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, T_OFLOW)	// trap
f010405e:	6a 00                	push   $0x0
f0104060:	6a 04                	push   $0x4
f0104062:	e9 d1 00 00 00       	jmp    f0104138 <_alltraps>
f0104067:	90                   	nop

f0104068 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, T_BOUND)	// fault
f0104068:	6a 00                	push   $0x0
f010406a:	6a 05                	push   $0x5
f010406c:	e9 c7 00 00 00       	jmp    f0104138 <_alltraps>
f0104071:	90                   	nop

f0104072 <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, T_ILLOP)	// fault
f0104072:	6a 00                	push   $0x0
f0104074:	6a 06                	push   $0x6
f0104076:	e9 bd 00 00 00       	jmp    f0104138 <_alltraps>
f010407b:	90                   	nop

f010407c <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, T_DEVICE)	// fault
f010407c:	6a 00                	push   $0x0
f010407e:	6a 07                	push   $0x7
f0104080:	e9 b3 00 00 00       	jmp    f0104138 <_alltraps>
f0104085:	90                   	nop

f0104086 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, T_DBLFLT)	// abort
f0104086:	6a 08                	push   $0x8
f0104088:	e9 ab 00 00 00       	jmp    f0104138 <_alltraps>
f010408d:	90                   	nop

f010408e <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, T_COPROC) // abort	
TRAPHANDLER     (TH_TSS, T_TSS)		// fault
f010408e:	6a 0a                	push   $0xa
f0104090:	e9 a3 00 00 00       	jmp    f0104138 <_alltraps>
f0104095:	90                   	nop

f0104096 <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, T_SEGNP)	// fault
f0104096:	6a 0b                	push   $0xb
f0104098:	e9 9b 00 00 00       	jmp    f0104138 <_alltraps>
f010409d:	90                   	nop

f010409e <TH_STACK>:
TRAPHANDLER     (TH_STACK, T_STACK)	// fault
f010409e:	6a 0c                	push   $0xc
f01040a0:	e9 93 00 00 00       	jmp    f0104138 <_alltraps>
f01040a5:	90                   	nop

f01040a6 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, T_GPFLT)	// fault/abort
f01040a6:	6a 0d                	push   $0xd
f01040a8:	e9 8b 00 00 00       	jmp    f0104138 <_alltraps>
f01040ad:	90                   	nop

f01040ae <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, T_PGFLT)	// fault
f01040ae:	6a 0e                	push   $0xe
f01040b0:	e9 83 00 00 00       	jmp    f0104138 <_alltraps>
f01040b5:	90                   	nop

f01040b6 <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, T_RES)	
TRAPHANDLER_NOEC(TH_FPERR, T_FPERR)	// fault
f01040b6:	6a 00                	push   $0x0
f01040b8:	6a 10                	push   $0x10
f01040ba:	eb 7c                	jmp    f0104138 <_alltraps>

f01040bc <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, T_ALIGN)	//
f01040bc:	6a 11                	push   $0x11
f01040be:	eb 78                	jmp    f0104138 <_alltraps>

f01040c0 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, T_MCHK)	//
f01040c0:	6a 00                	push   $0x0
f01040c2:	6a 12                	push   $0x12
f01040c4:	eb 72                	jmp    f0104138 <_alltraps>

f01040c6 <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, T_SIMDERR) //
f01040c6:	6a 00                	push   $0x0
f01040c8:	6a 13                	push   $0x13
f01040ca:	eb 6c                	jmp    f0104138 <_alltraps>

f01040cc <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, T_SYSCALL) // trap
f01040cc:	6a 00                	push   $0x0
f01040ce:	6a 30                	push   $0x30
f01040d0:	eb 66                	jmp    f0104138 <_alltraps>

f01040d2 <TH_IRQ_TIMER>:

TRAPHANDLER_NOEC(TH_IRQ_TIMER, IRQ_OFFSET+IRQ_TIMER)	// 0
f01040d2:	6a 00                	push   $0x0
f01040d4:	6a 20                	push   $0x20
f01040d6:	eb 60                	jmp    f0104138 <_alltraps>

f01040d8 <TH_IRQ_KBD>:
TRAPHANDLER_NOEC(TH_IRQ_KBD, IRQ_OFFSET+IRQ_KBD)	// 1
f01040d8:	6a 00                	push   $0x0
f01040da:	6a 21                	push   $0x21
f01040dc:	eb 5a                	jmp    f0104138 <_alltraps>

f01040de <TH_IRQ_2>:
TRAPHANDLER_NOEC(TH_IRQ_2, IRQ_OFFSET+2)
f01040de:	6a 00                	push   $0x0
f01040e0:	6a 22                	push   $0x22
f01040e2:	eb 54                	jmp    f0104138 <_alltraps>

f01040e4 <TH_IRQ_3>:
TRAPHANDLER_NOEC(TH_IRQ_3, IRQ_OFFSET+3)
f01040e4:	6a 00                	push   $0x0
f01040e6:	6a 23                	push   $0x23
f01040e8:	eb 4e                	jmp    f0104138 <_alltraps>

f01040ea <TH_IRQ_SERIAL>:
TRAPHANDLER_NOEC(TH_IRQ_SERIAL, IRQ_OFFSET+IRQ_SERIAL)	// 4
f01040ea:	6a 00                	push   $0x0
f01040ec:	6a 24                	push   $0x24
f01040ee:	eb 48                	jmp    f0104138 <_alltraps>

f01040f0 <TH_IRQ_5>:
TRAPHANDLER_NOEC(TH_IRQ_5, IRQ_OFFSET+5)
f01040f0:	6a 00                	push   $0x0
f01040f2:	6a 25                	push   $0x25
f01040f4:	eb 42                	jmp    f0104138 <_alltraps>

f01040f6 <TH_IRQ_6>:
TRAPHANDLER_NOEC(TH_IRQ_6, IRQ_OFFSET+6)
f01040f6:	6a 00                	push   $0x0
f01040f8:	6a 26                	push   $0x26
f01040fa:	eb 3c                	jmp    f0104138 <_alltraps>

f01040fc <TH_IRQ_SPURIOUS>:
TRAPHANDLER_NOEC(TH_IRQ_SPURIOUS, IRQ_OFFSET+IRQ_SPURIOUS) // 7
f01040fc:	6a 00                	push   $0x0
f01040fe:	6a 27                	push   $0x27
f0104100:	eb 36                	jmp    f0104138 <_alltraps>

f0104102 <TH_IRQ_8>:
TRAPHANDLER_NOEC(TH_IRQ_8, IRQ_OFFSET+8)
f0104102:	6a 00                	push   $0x0
f0104104:	6a 28                	push   $0x28
f0104106:	eb 30                	jmp    f0104138 <_alltraps>

f0104108 <TH_IRQ_9>:
TRAPHANDLER_NOEC(TH_IRQ_9, IRQ_OFFSET+9)
f0104108:	6a 00                	push   $0x0
f010410a:	6a 29                	push   $0x29
f010410c:	eb 2a                	jmp    f0104138 <_alltraps>

f010410e <TH_IRQ_10>:
TRAPHANDLER_NOEC(TH_IRQ_10, IRQ_OFFSET+10)
f010410e:	6a 00                	push   $0x0
f0104110:	6a 2a                	push   $0x2a
f0104112:	eb 24                	jmp    f0104138 <_alltraps>

f0104114 <TH_IRQ_11>:
TRAPHANDLER_NOEC(TH_IRQ_11, IRQ_OFFSET+11)
f0104114:	6a 00                	push   $0x0
f0104116:	6a 2b                	push   $0x2b
f0104118:	eb 1e                	jmp    f0104138 <_alltraps>

f010411a <TH_IRQ_12>:
TRAPHANDLER_NOEC(TH_IRQ_12, IRQ_OFFSET+12)
f010411a:	6a 00                	push   $0x0
f010411c:	6a 2c                	push   $0x2c
f010411e:	eb 18                	jmp    f0104138 <_alltraps>

f0104120 <TH_IRQ_13>:
TRAPHANDLER_NOEC(TH_IRQ_13, IRQ_OFFSET+13)
f0104120:	6a 00                	push   $0x0
f0104122:	6a 2d                	push   $0x2d
f0104124:	eb 12                	jmp    f0104138 <_alltraps>

f0104126 <TH_IRQ_IDE>:
TRAPHANDLER_NOEC(TH_IRQ_IDE, IRQ_OFFSET+IRQ_IDE)	// 14
f0104126:	6a 00                	push   $0x0
f0104128:	6a 2e                	push   $0x2e
f010412a:	eb 0c                	jmp    f0104138 <_alltraps>

f010412c <TH_IRQ_15>:
TRAPHANDLER_NOEC(TH_IRQ_15, IRQ_OFFSET+15)
f010412c:	6a 00                	push   $0x0
f010412e:	6a 2f                	push   $0x2f
f0104130:	eb 06                	jmp    f0104138 <_alltraps>

f0104132 <TH_IRQ_ERROR>:
TRAPHANDLER_NOEC(TH_IRQ_ERROR, IRQ_OFFSET+IRQ_ERROR)	// 19
f0104132:	6a 00                	push   $0x0
f0104134:	6a 33                	push   $0x33
f0104136:	eb 00                	jmp    f0104138 <_alltraps>

f0104138 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f0104138:	1e                   	push   %ds
	pushl	%es
f0104139:	06                   	push   %es
	pushal
f010413a:	60                   	pusha  
	mov	$GD_KD, %eax
f010413b:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f0104140:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f0104142:	8e d8                	mov    %eax,%ds
	pushl	%esp
f0104144:	54                   	push   %esp
	call	trap
f0104145:	e8 ce fc ff ff       	call   f0103e18 <trap>

f010414a <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010414a:	55                   	push   %ebp
f010414b:	89 e5                	mov    %esp,%ebp
f010414d:	83 ec 08             	sub    $0x8,%esp
f0104150:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
f0104155:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104158:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010415d:	8b 02                	mov    (%edx),%eax
f010415f:	83 e8 01             	sub    $0x1,%eax
f0104162:	83 f8 02             	cmp    $0x2,%eax
f0104165:	76 10                	jbe    f0104177 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104167:	83 c1 01             	add    $0x1,%ecx
f010416a:	83 c2 7c             	add    $0x7c,%edx
f010416d:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104173:	75 e8                	jne    f010415d <sched_halt+0x13>
f0104175:	eb 08                	jmp    f010417f <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104177:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010417d:	75 1f                	jne    f010419e <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f010417f:	83 ec 0c             	sub    $0xc,%esp
f0104182:	68 d0 75 10 f0       	push   $0xf01075d0
f0104187:	e8 f9 f4 ff ff       	call   f0103685 <cprintf>
f010418c:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f010418f:	83 ec 0c             	sub    $0xc,%esp
f0104192:	6a 00                	push   $0x0
f0104194:	e8 bf c7 ff ff       	call   f0100958 <monitor>
f0104199:	83 c4 10             	add    $0x10,%esp
f010419c:	eb f1                	jmp    f010418f <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010419e:	e8 a3 16 00 00       	call   f0105846 <cpunum>
f01041a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01041a6:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f01041ad:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01041b0:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01041b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01041ba:	77 12                	ja     f01041ce <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041bc:	50                   	push   %eax
f01041bd:	68 28 5f 10 f0       	push   $0xf0105f28
f01041c2:	6a 55                	push   $0x55
f01041c4:	68 f9 75 10 f0       	push   $0xf01075f9
f01041c9:	e8 72 be ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01041ce:	05 00 00 00 10       	add    $0x10000000,%eax
f01041d3:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01041d6:	e8 6b 16 00 00       	call   f0105846 <cpunum>
f01041db:	6b d0 74             	imul   $0x74,%eax,%edx
f01041de:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01041e4:	b8 02 00 00 00       	mov    $0x2,%eax
f01041e9:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041ed:	83 ec 0c             	sub    $0xc,%esp
f01041f0:	68 c0 03 12 f0       	push   $0xf01203c0
f01041f5:	e8 57 19 00 00       	call   f0105b51 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041fa:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041fc:	e8 45 16 00 00       	call   f0105846 <cpunum>
f0104201:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104204:	8b 80 30 00 23 f0    	mov    -0xfdcffd0(%eax),%eax
f010420a:	bd 00 00 00 00       	mov    $0x0,%ebp
f010420f:	89 c4                	mov    %eax,%esp
f0104211:	6a 00                	push   $0x0
f0104213:	6a 00                	push   $0x0
f0104215:	fb                   	sti    
f0104216:	f4                   	hlt    
f0104217:	eb fd                	jmp    f0104216 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104219:	83 c4 10             	add    $0x10,%esp
f010421c:	c9                   	leave  
f010421d:	c3                   	ret    

f010421e <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010421e:	55                   	push   %ebp
f010421f:	89 e5                	mov    %esp,%ebp
f0104221:	53                   	push   %ebx
f0104222:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here:
	size_t index = 0, first = 0;

	if(curenv)
f0104225:	e8 1c 16 00 00       	call   f0105846 <cpunum>
f010422a:	6b c0 74             	imul   $0x74,%eax,%eax
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here:
	size_t index = 0, first = 0;
f010422d:	ba 00 00 00 00       	mov    $0x0,%edx

	if(curenv)
f0104232:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104239:	74 1a                	je     f0104255 <sched_yield+0x37>
		first = ENVX(curenv->env_id) + 1;
f010423b:	e8 06 16 00 00       	call   f0105846 <cpunum>
f0104240:	6b c0 74             	imul   $0x74,%eax,%eax
f0104243:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104249:	8b 50 48             	mov    0x48(%eax),%edx
f010424c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104252:	83 c2 01             	add    $0x1,%edx

	for(size_t i = 0; i < NENV; ++i)
	{
		index = (first + i) % NENV;
		
		if(envs[index].env_status == ENV_RUNNABLE)
f0104255:	8b 0d 44 f2 22 f0    	mov    0xf022f244,%ecx
f010425b:	8d 9a 00 04 00 00    	lea    0x400(%edx),%ebx
f0104261:	89 d0                	mov    %edx,%eax
f0104263:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104268:	6b c0 7c             	imul   $0x7c,%eax,%eax
f010426b:	01 c8                	add    %ecx,%eax
f010426d:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0104271:	74 09                	je     f010427c <sched_yield+0x5e>
f0104273:	83 c2 01             	add    $0x1,%edx
	size_t index = 0, first = 0;

	if(curenv)
		first = ENVX(curenv->env_id) + 1;

	for(size_t i = 0; i < NENV; ++i)
f0104276:	39 da                	cmp    %ebx,%edx
f0104278:	75 e7                	jne    f0104261 <sched_yield+0x43>
f010427a:	eb 0d                	jmp    f0104289 <sched_yield+0x6b>
			idle = &envs[index];
			break;
		}
	}	
	
	if(idle)
f010427c:	85 c0                	test   %eax,%eax
f010427e:	74 09                	je     f0104289 <sched_yield+0x6b>
		env_run(idle);
f0104280:	83 ec 0c             	sub    $0xc,%esp
f0104283:	50                   	push   %eax
f0104284:	e8 e2 f1 ff ff       	call   f010346b <env_run>
	
	else
	{
		if(curenv && curenv->env_status == ENV_RUNNING)
f0104289:	e8 b8 15 00 00       	call   f0105846 <cpunum>
f010428e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104291:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104298:	74 2a                	je     f01042c4 <sched_yield+0xa6>
f010429a:	e8 a7 15 00 00       	call   f0105846 <cpunum>
f010429f:	6b c0 74             	imul   $0x74,%eax,%eax
f01042a2:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01042a8:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042ac:	75 16                	jne    f01042c4 <sched_yield+0xa6>
			env_run(curenv);
f01042ae:	e8 93 15 00 00       	call   f0105846 <cpunum>
f01042b3:	83 ec 0c             	sub    $0xc,%esp
f01042b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01042b9:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01042bf:	e8 a7 f1 ff ff       	call   f010346b <env_run>
	}	

	// sched_halt never returns
	sched_halt();
f01042c4:	e8 81 fe ff ff       	call   f010414a <sched_halt>
}
f01042c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042cc:	c9                   	leave  
f01042cd:	c3                   	ret    

f01042ce <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042ce:	55                   	push   %ebp
f01042cf:	89 e5                	mov    %esp,%ebp
f01042d1:	57                   	push   %edi
f01042d2:	56                   	push   %esi
f01042d3:	53                   	push   %ebx
f01042d4:	83 ec 1c             	sub    $0x1c,%esp
f01042d7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
f01042da:	83 f8 0a             	cmp    $0xa,%eax
f01042dd:	0f 87 cb 03 00 00    	ja     f01046ae <syscall+0x3e0>
f01042e3:	ff 24 85 40 76 10 f0 	jmp    *-0xfef89c0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01042ea:	e8 57 15 00 00       	call   f0105846 <cpunum>
f01042ef:	6a 04                	push   $0x4
f01042f1:	ff 75 10             	pushl  0x10(%ebp)
f01042f4:	ff 75 0c             	pushl  0xc(%ebp)
f01042f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01042fa:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104300:	e8 61 ea ff ff       	call   f0102d66 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104305:	83 c4 0c             	add    $0xc,%esp
f0104308:	ff 75 0c             	pushl  0xc(%ebp)
f010430b:	ff 75 10             	pushl  0x10(%ebp)
f010430e:	68 06 76 10 f0       	push   $0xf0107606
f0104313:	e8 6d f3 ff ff       	call   f0103685 <cprintf>
f0104318:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
f010431b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104320:	e9 8e 03 00 00       	jmp    f01046b3 <syscall+0x3e5>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104325:	e8 cb c2 ff ff       	call   f01005f5 <cons_getc>
f010432a:	89 c3                	mov    %eax,%ebx

	switch (syscallno) 
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			 return sys_cgetc();		
f010432c:	e9 82 03 00 00       	jmp    f01046b3 <syscall+0x3e5>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104331:	e8 10 15 00 00       	call   f0105846 <cpunum>
f0104336:	6b c0 74             	imul   $0x74,%eax,%eax
f0104339:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010433f:	8b 58 48             	mov    0x48(%eax),%ebx
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			 return sys_cgetc();		

		case SYS_getenvid:		 return sys_getenvid();
f0104342:	e9 6c 03 00 00       	jmp    f01046b3 <syscall+0x3e5>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104347:	83 ec 04             	sub    $0x4,%esp
f010434a:	6a 01                	push   $0x1
f010434c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010434f:	50                   	push   %eax
f0104350:	ff 75 0c             	pushl  0xc(%ebp)
f0104353:	e8 c3 ea ff ff       	call   f0102e1b <envid2env>
f0104358:	83 c4 10             	add    $0x10,%esp
		return r;
f010435b:	89 c3                	mov    %eax,%ebx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010435d:	85 c0                	test   %eax,%eax
f010435f:	0f 88 4e 03 00 00    	js     f01046b3 <syscall+0x3e5>
		return r;
	if (e == curenv)
f0104365:	e8 dc 14 00 00       	call   f0105846 <cpunum>
f010436a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010436d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104370:	39 90 28 00 23 f0    	cmp    %edx,-0xfdcffd8(%eax)
f0104376:	75 23                	jne    f010439b <syscall+0xcd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104378:	e8 c9 14 00 00       	call   f0105846 <cpunum>
f010437d:	83 ec 08             	sub    $0x8,%esp
f0104380:	6b c0 74             	imul   $0x74,%eax,%eax
f0104383:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104389:	ff 70 48             	pushl  0x48(%eax)
f010438c:	68 0b 76 10 f0       	push   $0xf010760b
f0104391:	e8 ef f2 ff ff       	call   f0103685 <cprintf>
f0104396:	83 c4 10             	add    $0x10,%esp
f0104399:	eb 25                	jmp    f01043c0 <syscall+0xf2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010439b:	8b 5a 48             	mov    0x48(%edx),%ebx
f010439e:	e8 a3 14 00 00       	call   f0105846 <cpunum>
f01043a3:	83 ec 04             	sub    $0x4,%esp
f01043a6:	53                   	push   %ebx
f01043a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01043aa:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01043b0:	ff 70 48             	pushl  0x48(%eax)
f01043b3:	68 26 76 10 f0       	push   $0xf0107626
f01043b8:	e8 c8 f2 ff ff       	call   f0103685 <cprintf>
f01043bd:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01043c0:	83 ec 0c             	sub    $0xc,%esp
f01043c3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01043c6:	e8 01 f0 ff ff       	call   f01033cc <env_destroy>
f01043cb:	83 c4 10             	add    $0x10,%esp
	return 0;
f01043ce:	bb 00 00 00 00       	mov    $0x0,%ebx
f01043d3:	e9 db 02 00 00       	jmp    f01046b3 <syscall+0x3e5>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01043d8:	e8 41 fe ff ff       	call   f010421e <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = env_alloc(&env, curenv->env_id);
f01043dd:	e8 64 14 00 00       	call   f0105846 <cpunum>
f01043e2:	83 ec 08             	sub    $0x8,%esp
f01043e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01043e8:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01043ee:	ff 70 48             	pushl  0x48(%eax)
f01043f1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043f4:	50                   	push   %eax
f01043f5:	e8 2c eb ff ff       	call   f0102f26 <env_alloc>
f01043fa:	89 c3                	mov    %eax,%ebx
	
	if(result)
f01043fc:	83 c4 10             	add    $0x10,%esp
f01043ff:	85 c0                	test   %eax,%eax
f0104401:	0f 85 ac 02 00 00    	jne    f01046b3 <syscall+0x3e5>
		return result;

	env->env_status = ENV_NOT_RUNNABLE;
f0104407:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010440a:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	env->env_tf = curenv->env_tf;
f0104411:	e8 30 14 00 00       	call   f0105846 <cpunum>
f0104416:	6b c0 74             	imul   $0x74,%eax,%eax
f0104419:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
f010441f:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104424:	89 df                	mov    %ebx,%edi
f0104426:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	env->env_tf.tf_regs.reg_eax = 0;
f0104428:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010442b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return env->env_id;
f0104432:	8b 58 48             	mov    0x48(%eax),%ebx

		case SYS_env_destroy:		 return sys_env_destroy((envid_t) a1);
		
		case SYS_yield:			 sys_yield();			return 0;
	
		case SYS_exofork:		 return (int32_t) sys_exofork();
f0104435:	e9 79 02 00 00       	jmp    f01046b3 <syscall+0x3e5>
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f010443a:	83 ec 04             	sub    $0x4,%esp
f010443d:	6a 01                	push   $0x1
f010443f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104442:	50                   	push   %eax
f0104443:	ff 75 0c             	pushl  0xc(%ebp)
f0104446:	e8 d0 e9 ff ff       	call   f0102e1b <envid2env>
f010444b:	89 c3                	mov    %eax,%ebx

	if(result)
f010444d:	83 c4 10             	add    $0x10,%esp
f0104450:	85 c0                	test   %eax,%eax
f0104452:	0f 85 5b 02 00 00    	jne    f01046b3 <syscall+0x3e5>
		return result;

	if(status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE)
f0104458:	8b 45 10             	mov    0x10(%ebp),%eax
f010445b:	83 e8 02             	sub    $0x2,%eax
f010445e:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104463:	75 0e                	jne    f0104473 <syscall+0x1a5>
		return -E_INVAL;

	env->env_status = status;
f0104465:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104468:	8b 7d 10             	mov    0x10(%ebp),%edi
f010446b:	89 78 54             	mov    %edi,0x54(%eax)
f010446e:	e9 40 02 00 00       	jmp    f01046b3 <syscall+0x3e5>

	if(result)
		return result;

	if(status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE)
		return -E_INVAL;
f0104473:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		
		case SYS_yield:			 sys_yield();			return 0;
	
		case SYS_exofork:		 return (int32_t) sys_exofork();

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);
f0104478:	e9 36 02 00 00       	jmp    f01046b3 <syscall+0x3e5>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f010447d:	83 ec 04             	sub    $0x4,%esp
f0104480:	6a 01                	push   $0x1
f0104482:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104485:	50                   	push   %eax
f0104486:	ff 75 0c             	pushl  0xc(%ebp)
f0104489:	e8 8d e9 ff ff       	call   f0102e1b <envid2env>

	if(result)
f010448e:	83 c4 10             	add    $0x10,%esp
f0104491:	85 c0                	test   %eax,%eax
f0104493:	75 69                	jne    f01044fe <syscall+0x230>
		return -E_BAD_ENV;

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
f0104495:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010449c:	77 6a                	ja     f0104508 <syscall+0x23a>
f010449e:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01044a5:	75 6b                	jne    f0104512 <syscall+0x244>
		return -E_INVAL;
	
	if(perm & ~PTE_SYSCALL)
f01044a7:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f01044ae:	75 6c                	jne    f010451c <syscall+0x24e>
		return -E_INVAL;

	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))	
f01044b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01044b3:	83 e0 05             	and    $0x5,%eax
f01044b6:	83 f8 05             	cmp    $0x5,%eax
f01044b9:	75 6b                	jne    f0104526 <syscall+0x258>
		return -E_INVAL;

	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01044bb:	83 ec 0c             	sub    $0xc,%esp
f01044be:	6a 01                	push   $0x1
f01044c0:	e8 ec ca ff ff       	call   f0100fb1 <page_alloc>
f01044c5:	89 c6                	mov    %eax,%esi

	if(!page)
f01044c7:	83 c4 10             	add    $0x10,%esp
f01044ca:	85 c0                	test   %eax,%eax
f01044cc:	74 62                	je     f0104530 <syscall+0x262>
		return -E_NO_MEM;

	result = page_insert(env->env_pgdir, page, va, perm);
f01044ce:	ff 75 14             	pushl  0x14(%ebp)
f01044d1:	ff 75 10             	pushl  0x10(%ebp)
f01044d4:	50                   	push   %eax
f01044d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044d8:	ff 70 60             	pushl  0x60(%eax)
f01044db:	e8 d0 cd ff ff       	call   f01012b0 <page_insert>
f01044e0:	89 c3                	mov    %eax,%ebx

	if(result)
f01044e2:	83 c4 10             	add    $0x10,%esp
f01044e5:	85 c0                	test   %eax,%eax
f01044e7:	0f 84 c6 01 00 00    	je     f01046b3 <syscall+0x3e5>
	{
		page_free(page);
f01044ed:	83 ec 0c             	sub    $0xc,%esp
f01044f0:	56                   	push   %esi
f01044f1:	e8 2b cb ff ff       	call   f0101021 <page_free>
f01044f6:	83 c4 10             	add    $0x10,%esp
f01044f9:	e9 b5 01 00 00       	jmp    f01046b3 <syscall+0x3e5>
	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);

	if(result)
		return -E_BAD_ENV;
f01044fe:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104503:	e9 ab 01 00 00       	jmp    f01046b3 <syscall+0x3e5>

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
		return -E_INVAL;
f0104508:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010450d:	e9 a1 01 00 00       	jmp    f01046b3 <syscall+0x3e5>
f0104512:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104517:	e9 97 01 00 00       	jmp    f01046b3 <syscall+0x3e5>
	
	if(perm & ~PTE_SYSCALL)
		return -E_INVAL;
f010451c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104521:	e9 8d 01 00 00       	jmp    f01046b3 <syscall+0x3e5>

	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))	
		return -E_INVAL;
f0104526:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010452b:	e9 83 01 00 00       	jmp    f01046b3 <syscall+0x3e5>

	struct PageInfo *page = page_alloc(ALLOC_ZERO);

	if(!page)
		return -E_NO_MEM;
f0104530:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
	
		case SYS_exofork:		 return (int32_t) sys_exofork();

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
f0104535:	e9 79 01 00 00       	jmp    f01046b3 <syscall+0x3e5>
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	struct Env *src, *dst;
	size_t result_src = envid2env(srcenvid, &src, perm);
f010453a:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f010453e:	0f 95 c3             	setne  %bl
f0104541:	0f b6 db             	movzbl %bl,%ebx
f0104544:	83 ec 04             	sub    $0x4,%esp
f0104547:	53                   	push   %ebx
f0104548:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010454b:	50                   	push   %eax
f010454c:	ff 75 0c             	pushl  0xc(%ebp)
f010454f:	e8 c7 e8 ff ff       	call   f0102e1b <envid2env>
f0104554:	89 c6                	mov    %eax,%esi
	size_t result_dst = envid2env(dstenvid, &dst, perm);
f0104556:	83 c4 0c             	add    $0xc,%esp
f0104559:	53                   	push   %ebx
f010455a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010455d:	50                   	push   %eax
f010455e:	ff 75 14             	pushl  0x14(%ebp)
f0104561:	e8 b5 e8 ff ff       	call   f0102e1b <envid2env>
	
	if(result_src || result_dst)
f0104566:	83 c4 10             	add    $0x10,%esp
f0104569:	09 c6                	or     %eax,%esi
f010456b:	75 75                	jne    f01045e2 <syscall+0x314>
		return -E_BAD_ENV;

	if((((uint32_t) srcva >= UTOP) || ((uint32_t) srcva % PGSIZE != 0)) || 	
f010456d:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104574:	77 76                	ja     f01045ec <syscall+0x31e>
f0104576:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010457d:	75 77                	jne    f01045f6 <syscall+0x328>
f010457f:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104586:	77 6e                	ja     f01045f6 <syscall+0x328>
	  	(((uint32_t) dstva >= UTOP) || ((uint32_t) dstva % PGSIZE != 0)))
f0104588:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f010458f:	75 6f                	jne    f0104600 <syscall+0x332>
		return -E_INVAL;

	pte_t *pte;
	struct PageInfo *page = page_lookup(src->env_pgdir, srcva, &pte);
f0104591:	83 ec 04             	sub    $0x4,%esp
f0104594:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104597:	50                   	push   %eax
f0104598:	ff 75 10             	pushl  0x10(%ebp)
f010459b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010459e:	ff 70 60             	pushl  0x60(%eax)
f01045a1:	e8 26 cc ff ff       	call   f01011cc <page_lookup>

	if(!page)
f01045a6:	83 c4 10             	add    $0x10,%esp
f01045a9:	85 c0                	test   %eax,%eax
f01045ab:	74 5d                	je     f010460a <syscall+0x33c>
		return -E_INVAL;

	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))
f01045ad:	8b 55 1c             	mov    0x1c(%ebp),%edx
f01045b0:	83 e2 05             	and    $0x5,%edx
f01045b3:	83 fa 05             	cmp    $0x5,%edx
f01045b6:	75 5c                	jne    f0104614 <syscall+0x346>
		return -E_INVAL;

	if ((perm & PTE_W) && !(*pte & PTE_W))
f01045b8:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f01045bc:	74 08                	je     f01045c6 <syscall+0x2f8>
f01045be:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045c1:	f6 02 02             	testb  $0x2,(%edx)
f01045c4:	74 58                	je     f010461e <syscall+0x350>
		return -E_INVAL;

	size_t result = page_insert(dst->env_pgdir, page, dstva, perm);
f01045c6:	ff 75 1c             	pushl  0x1c(%ebp)
f01045c9:	ff 75 18             	pushl  0x18(%ebp)
f01045cc:	50                   	push   %eax
f01045cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045d0:	ff 70 60             	pushl  0x60(%eax)
f01045d3:	e8 d8 cc ff ff       	call   f01012b0 <page_insert>
f01045d8:	89 c3                	mov    %eax,%ebx
f01045da:	83 c4 10             	add    $0x10,%esp
f01045dd:	e9 d1 00 00 00       	jmp    f01046b3 <syscall+0x3e5>
	struct Env *src, *dst;
	size_t result_src = envid2env(srcenvid, &src, perm);
	size_t result_dst = envid2env(dstenvid, &dst, perm);
	
	if(result_src || result_dst)
		return -E_BAD_ENV;
f01045e2:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01045e7:	e9 c7 00 00 00       	jmp    f01046b3 <syscall+0x3e5>

	if((((uint32_t) srcva >= UTOP) || ((uint32_t) srcva % PGSIZE != 0)) || 	
	  	(((uint32_t) dstva >= UTOP) || ((uint32_t) dstva % PGSIZE != 0)))
		return -E_INVAL;
f01045ec:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01045f1:	e9 bd 00 00 00       	jmp    f01046b3 <syscall+0x3e5>
f01045f6:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01045fb:	e9 b3 00 00 00       	jmp    f01046b3 <syscall+0x3e5>
f0104600:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104605:	e9 a9 00 00 00       	jmp    f01046b3 <syscall+0x3e5>

	pte_t *pte;
	struct PageInfo *page = page_lookup(src->env_pgdir, srcva, &pte);

	if(!page)
		return -E_INVAL;
f010460a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010460f:	e9 9f 00 00 00       	jmp    f01046b3 <syscall+0x3e5>

	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))
		return -E_INVAL;
f0104614:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104619:	e9 95 00 00 00       	jmp    f01046b3 <syscall+0x3e5>

	if ((perm & PTE_W) && !(*pte & PTE_W))
		return -E_INVAL;
f010461e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);
f0104623:	e9 8b 00 00 00       	jmp    f01046b3 <syscall+0x3e5>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f0104628:	83 ec 04             	sub    $0x4,%esp
f010462b:	6a 01                	push   $0x1
f010462d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104630:	50                   	push   %eax
f0104631:	ff 75 0c             	pushl  0xc(%ebp)
f0104634:	e8 e2 e7 ff ff       	call   f0102e1b <envid2env>
f0104639:	89 c3                	mov    %eax,%ebx

	if(result)
f010463b:	83 c4 10             	add    $0x10,%esp
f010463e:	85 c0                	test   %eax,%eax
f0104640:	75 28                	jne    f010466a <syscall+0x39c>
		return -E_BAD_ENV;

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
f0104642:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104649:	77 26                	ja     f0104671 <syscall+0x3a3>
f010464b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104652:	75 24                	jne    f0104678 <syscall+0x3aa>
		return -E_INVAL;

	page_remove(env->env_pgdir, va);
f0104654:	83 ec 08             	sub    $0x8,%esp
f0104657:	ff 75 10             	pushl  0x10(%ebp)
f010465a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010465d:	ff 70 60             	pushl  0x60(%eax)
f0104660:	e8 f6 cb ff ff       	call   f010125b <page_remove>
f0104665:	83 c4 10             	add    $0x10,%esp
f0104668:	eb 49                	jmp    f01046b3 <syscall+0x3e5>
	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);

	if(result)
		return -E_BAD_ENV;
f010466a:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f010466f:	eb 42                	jmp    f01046b3 <syscall+0x3e5>

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
		return -E_INVAL;
f0104671:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104676:	eb 3b                	jmp    f01046b3 <syscall+0x3e5>
f0104678:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);

		case SYS_page_unmap:		 return sys_page_unmap((envid_t) a1, (void *) a2);
f010467d:	eb 34                	jmp    f01046b3 <syscall+0x3e5>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *env;
	envid2env(envid, &env, 1);
f010467f:	83 ec 04             	sub    $0x4,%esp
f0104682:	6a 01                	push   $0x1
f0104684:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104687:	50                   	push   %eax
f0104688:	ff 75 0c             	pushl  0xc(%ebp)
f010468b:	e8 8b e7 ff ff       	call   f0102e1b <envid2env>

	if(!env)
f0104690:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104693:	83 c4 10             	add    $0x10,%esp
f0104696:	85 c0                	test   %eax,%eax
f0104698:	74 0d                	je     f01046a7 <syscall+0x3d9>
		return -E_BAD_ENV;

	env->env_pgfault_upcall = func;
f010469a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010469d:	89 48 64             	mov    %ecx,0x64(%eax)

	return 0;
f01046a0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01046a5:	eb 0c                	jmp    f01046b3 <syscall+0x3e5>
	// LAB 4: Your code here.
	struct Env *env;
	envid2env(envid, &env, 1);

	if(!env)
		return -E_BAD_ENV;
f01046a7:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);

		case SYS_page_unmap:		 return sys_page_unmap((envid_t) a1, (void *) a2);
		
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void*)a2);
f01046ac:	eb 05                	jmp    f01046b3 <syscall+0x3e5>

		default:			 return -E_INVAL;
f01046ae:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
	}
}
f01046b3:	89 d8                	mov    %ebx,%eax
f01046b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01046b8:	5b                   	pop    %ebx
f01046b9:	5e                   	pop    %esi
f01046ba:	5f                   	pop    %edi
f01046bb:	5d                   	pop    %ebp
f01046bc:	c3                   	ret    

f01046bd <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01046bd:	55                   	push   %ebp
f01046be:	89 e5                	mov    %esp,%ebp
f01046c0:	57                   	push   %edi
f01046c1:	56                   	push   %esi
f01046c2:	53                   	push   %ebx
f01046c3:	83 ec 14             	sub    $0x14,%esp
f01046c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01046c9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01046cc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01046cf:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01046d2:	8b 1a                	mov    (%edx),%ebx
f01046d4:	8b 01                	mov    (%ecx),%eax
f01046d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01046d9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01046e0:	eb 7f                	jmp    f0104761 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01046e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01046e5:	01 d8                	add    %ebx,%eax
f01046e7:	89 c6                	mov    %eax,%esi
f01046e9:	c1 ee 1f             	shr    $0x1f,%esi
f01046ec:	01 c6                	add    %eax,%esi
f01046ee:	d1 fe                	sar    %esi
f01046f0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01046f3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01046f6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01046f9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01046fb:	eb 03                	jmp    f0104700 <stab_binsearch+0x43>
			m--;
f01046fd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104700:	39 c3                	cmp    %eax,%ebx
f0104702:	7f 0d                	jg     f0104711 <stab_binsearch+0x54>
f0104704:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104708:	83 ea 0c             	sub    $0xc,%edx
f010470b:	39 f9                	cmp    %edi,%ecx
f010470d:	75 ee                	jne    f01046fd <stab_binsearch+0x40>
f010470f:	eb 05                	jmp    f0104716 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104711:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104714:	eb 4b                	jmp    f0104761 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104716:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104719:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010471c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104720:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104723:	76 11                	jbe    f0104736 <stab_binsearch+0x79>
			*region_left = m;
f0104725:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104728:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010472a:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010472d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104734:	eb 2b                	jmp    f0104761 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104736:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104739:	73 14                	jae    f010474f <stab_binsearch+0x92>
			*region_right = m - 1;
f010473b:	83 e8 01             	sub    $0x1,%eax
f010473e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104741:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104744:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104746:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010474d:	eb 12                	jmp    f0104761 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010474f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104752:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104754:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104758:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010475a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104761:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104764:	0f 8e 78 ff ff ff    	jle    f01046e2 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010476a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010476e:	75 0f                	jne    f010477f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104770:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104773:	8b 00                	mov    (%eax),%eax
f0104775:	83 e8 01             	sub    $0x1,%eax
f0104778:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010477b:	89 06                	mov    %eax,(%esi)
f010477d:	eb 2c                	jmp    f01047ab <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010477f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104782:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104784:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104787:	8b 0e                	mov    (%esi),%ecx
f0104789:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010478c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010478f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104792:	eb 03                	jmp    f0104797 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104794:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104797:	39 c8                	cmp    %ecx,%eax
f0104799:	7e 0b                	jle    f01047a6 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010479b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010479f:	83 ea 0c             	sub    $0xc,%edx
f01047a2:	39 df                	cmp    %ebx,%edi
f01047a4:	75 ee                	jne    f0104794 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01047a6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01047a9:	89 06                	mov    %eax,(%esi)
	}
}
f01047ab:	83 c4 14             	add    $0x14,%esp
f01047ae:	5b                   	pop    %ebx
f01047af:	5e                   	pop    %esi
f01047b0:	5f                   	pop    %edi
f01047b1:	5d                   	pop    %ebp
f01047b2:	c3                   	ret    

f01047b3 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01047b3:	55                   	push   %ebp
f01047b4:	89 e5                	mov    %esp,%ebp
f01047b6:	57                   	push   %edi
f01047b7:	56                   	push   %esi
f01047b8:	53                   	push   %ebx
f01047b9:	83 ec 3c             	sub    $0x3c,%esp
f01047bc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01047bf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01047c2:	c7 03 6c 76 10 f0    	movl   $0xf010766c,(%ebx)
	info->eip_line = 0;
f01047c8:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01047cf:	c7 43 08 6c 76 10 f0 	movl   $0xf010766c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01047d6:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01047dd:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01047e0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01047e7:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01047ed:	0f 87 a3 00 00 00    	ja     f0104896 <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f01047f3:	e8 4e 10 00 00       	call   f0105846 <cpunum>
f01047f8:	6a 04                	push   $0x4
f01047fa:	6a 10                	push   $0x10
f01047fc:	68 00 00 20 00       	push   $0x200000
f0104801:	6b c0 74             	imul   $0x74,%eax,%eax
f0104804:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010480a:	e8 e1 e4 ff ff       	call   f0102cf0 <user_mem_check>
f010480f:	83 c4 10             	add    $0x10,%esp
f0104812:	85 c0                	test   %eax,%eax
f0104814:	0f 84 3e 02 00 00    	je     f0104a58 <debuginfo_eip+0x2a5>
                        return -1;

		stabs = usd->stabs;
f010481a:	a1 00 00 20 00       	mov    0x200000,%eax
f010481f:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0104822:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104828:	8b 15 08 00 20 00    	mov    0x200008,%edx
f010482e:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104831:	a1 0c 00 20 00       	mov    0x20000c,%eax
f0104836:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f0104839:	e8 08 10 00 00       	call   f0105846 <cpunum>
f010483e:	6a 04                	push   $0x4
f0104840:	89 f2                	mov    %esi,%edx
f0104842:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104845:	29 ca                	sub    %ecx,%edx
f0104847:	c1 fa 02             	sar    $0x2,%edx
f010484a:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104850:	52                   	push   %edx
f0104851:	51                   	push   %ecx
f0104852:	6b c0 74             	imul   $0x74,%eax,%eax
f0104855:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010485b:	e8 90 e4 ff ff       	call   f0102cf0 <user_mem_check>
f0104860:	83 c4 10             	add    $0x10,%esp
f0104863:	85 c0                	test   %eax,%eax
f0104865:	0f 84 f4 01 00 00    	je     f0104a5f <debuginfo_eip+0x2ac>
			return -1;

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f010486b:	e8 d6 0f 00 00       	call   f0105846 <cpunum>
f0104870:	6a 04                	push   $0x4
f0104872:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104875:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104878:	29 ca                	sub    %ecx,%edx
f010487a:	52                   	push   %edx
f010487b:	51                   	push   %ecx
f010487c:	6b c0 74             	imul   $0x74,%eax,%eax
f010487f:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104885:	e8 66 e4 ff ff       	call   f0102cf0 <user_mem_check>
f010488a:	83 c4 10             	add    $0x10,%esp
f010488d:	85 c0                	test   %eax,%eax
f010488f:	75 1f                	jne    f01048b0 <debuginfo_eip+0xfd>
f0104891:	e9 d0 01 00 00       	jmp    f0104a66 <debuginfo_eip+0x2b3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104896:	c7 45 bc 6e 51 11 f0 	movl   $0xf011516e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010489d:	c7 45 b8 c1 1a 11 f0 	movl   $0xf0111ac1,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01048a4:	be c0 1a 11 f0       	mov    $0xf0111ac0,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01048a9:	c7 45 c0 54 7b 10 f0 	movl   $0xf0107b54,-0x40(%ebp)
		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01048b0:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01048b3:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f01048b6:	0f 83 b1 01 00 00    	jae    f0104a6d <debuginfo_eip+0x2ba>
f01048bc:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01048c0:	0f 85 ae 01 00 00    	jne    f0104a74 <debuginfo_eip+0x2c1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01048c6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01048cd:	2b 75 c0             	sub    -0x40(%ebp),%esi
f01048d0:	c1 fe 02             	sar    $0x2,%esi
f01048d3:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f01048d9:	83 e8 01             	sub    $0x1,%eax
f01048dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01048df:	83 ec 08             	sub    $0x8,%esp
f01048e2:	57                   	push   %edi
f01048e3:	6a 64                	push   $0x64
f01048e5:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01048e8:	89 d1                	mov    %edx,%ecx
f01048ea:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01048ed:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01048f0:	89 f0                	mov    %esi,%eax
f01048f2:	e8 c6 fd ff ff       	call   f01046bd <stab_binsearch>
	if (lfile == 0)
f01048f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048fa:	83 c4 10             	add    $0x10,%esp
f01048fd:	85 c0                	test   %eax,%eax
f01048ff:	0f 84 76 01 00 00    	je     f0104a7b <debuginfo_eip+0x2c8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104905:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104908:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010490b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010490e:	83 ec 08             	sub    $0x8,%esp
f0104911:	57                   	push   %edi
f0104912:	6a 24                	push   $0x24
f0104914:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104917:	89 d1                	mov    %edx,%ecx
f0104919:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010491c:	89 f0                	mov    %esi,%eax
f010491e:	e8 9a fd ff ff       	call   f01046bd <stab_binsearch>

	if (lfun <= rfun) {
f0104923:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104926:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104929:	83 c4 10             	add    $0x10,%esp
f010492c:	39 d0                	cmp    %edx,%eax
f010492e:	7f 2e                	jg     f010495e <debuginfo_eip+0x1ab>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104930:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104933:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104936:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104939:	8b 36                	mov    (%esi),%esi
f010493b:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010493e:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104941:	39 ce                	cmp    %ecx,%esi
f0104943:	73 06                	jae    f010494b <debuginfo_eip+0x198>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104945:	03 75 b8             	add    -0x48(%ebp),%esi
f0104948:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010494b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010494e:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104951:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104954:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104956:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104959:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010495c:	eb 0f                	jmp    f010496d <debuginfo_eip+0x1ba>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010495e:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104961:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104964:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104967:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010496a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010496d:	83 ec 08             	sub    $0x8,%esp
f0104970:	6a 3a                	push   $0x3a
f0104972:	ff 73 08             	pushl  0x8(%ebx)
f0104975:	e8 8f 08 00 00       	call   f0105209 <strfind>
f010497a:	2b 43 08             	sub    0x8(%ebx),%eax
f010497d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104980:	83 c4 08             	add    $0x8,%esp
f0104983:	57                   	push   %edi
f0104984:	6a 44                	push   $0x44
f0104986:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104989:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010498c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010498f:	89 f8                	mov    %edi,%eax
f0104991:	e8 27 fd ff ff       	call   f01046bd <stab_binsearch>
	
	if(lline > rline)
f0104996:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104999:	83 c4 10             	add    $0x10,%esp
f010499c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010499f:	0f 8f dd 00 00 00    	jg     f0104a82 <debuginfo_eip+0x2cf>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f01049a5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01049a8:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01049ab:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f01049af:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01049b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049b5:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01049b9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01049bc:	eb 0a                	jmp    f01049c8 <debuginfo_eip+0x215>
f01049be:	83 e8 01             	sub    $0x1,%eax
f01049c1:	83 ea 0c             	sub    $0xc,%edx
f01049c4:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01049c8:	39 c7                	cmp    %eax,%edi
f01049ca:	7e 05                	jle    f01049d1 <debuginfo_eip+0x21e>
f01049cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01049cf:	eb 47                	jmp    f0104a18 <debuginfo_eip+0x265>
	       && stabs[lline].n_type != N_SOL
f01049d1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01049d5:	80 f9 84             	cmp    $0x84,%cl
f01049d8:	75 0e                	jne    f01049e8 <debuginfo_eip+0x235>
f01049da:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01049dd:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01049e1:	74 1c                	je     f01049ff <debuginfo_eip+0x24c>
f01049e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01049e6:	eb 17                	jmp    f01049ff <debuginfo_eip+0x24c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01049e8:	80 f9 64             	cmp    $0x64,%cl
f01049eb:	75 d1                	jne    f01049be <debuginfo_eip+0x20b>
f01049ed:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01049f1:	74 cb                	je     f01049be <debuginfo_eip+0x20b>
f01049f3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01049f6:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01049fa:	74 03                	je     f01049ff <debuginfo_eip+0x24c>
f01049fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01049ff:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104a02:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104a05:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104a08:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a0b:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104a0e:	29 f8                	sub    %edi,%eax
f0104a10:	39 c2                	cmp    %eax,%edx
f0104a12:	73 04                	jae    f0104a18 <debuginfo_eip+0x265>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104a14:	01 fa                	add    %edi,%edx
f0104a16:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104a18:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104a1b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a1e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104a23:	39 f2                	cmp    %esi,%edx
f0104a25:	7d 67                	jge    f0104a8e <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
f0104a27:	83 c2 01             	add    $0x1,%edx
f0104a2a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104a2d:	89 d0                	mov    %edx,%eax
f0104a2f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104a32:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104a35:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104a38:	eb 04                	jmp    f0104a3e <debuginfo_eip+0x28b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104a3a:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104a3e:	39 c6                	cmp    %eax,%esi
f0104a40:	7e 47                	jle    f0104a89 <debuginfo_eip+0x2d6>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104a42:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104a46:	83 c0 01             	add    $0x1,%eax
f0104a49:	83 c2 0c             	add    $0xc,%edx
f0104a4c:	80 f9 a0             	cmp    $0xa0,%cl
f0104a4f:	74 e9                	je     f0104a3a <debuginfo_eip+0x287>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a51:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a56:	eb 36                	jmp    f0104a8e <debuginfo_eip+0x2db>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
                        return -1;
f0104a58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a5d:	eb 2f                	jmp    f0104a8e <debuginfo_eip+0x2db>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
			return -1;
f0104a5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a64:	eb 28                	jmp    f0104a8e <debuginfo_eip+0x2db>

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f0104a66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a6b:	eb 21                	jmp    f0104a8e <debuginfo_eip+0x2db>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104a6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a72:	eb 1a                	jmp    f0104a8e <debuginfo_eip+0x2db>
f0104a74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a79:	eb 13                	jmp    f0104a8e <debuginfo_eip+0x2db>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104a7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a80:	eb 0c                	jmp    f0104a8e <debuginfo_eip+0x2db>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0104a82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a87:	eb 05                	jmp    f0104a8e <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a89:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104a8e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a91:	5b                   	pop    %ebx
f0104a92:	5e                   	pop    %esi
f0104a93:	5f                   	pop    %edi
f0104a94:	5d                   	pop    %ebp
f0104a95:	c3                   	ret    

f0104a96 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104a96:	55                   	push   %ebp
f0104a97:	89 e5                	mov    %esp,%ebp
f0104a99:	57                   	push   %edi
f0104a9a:	56                   	push   %esi
f0104a9b:	53                   	push   %ebx
f0104a9c:	83 ec 1c             	sub    $0x1c,%esp
f0104a9f:	89 c7                	mov    %eax,%edi
f0104aa1:	89 d6                	mov    %edx,%esi
f0104aa3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aa6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104aa9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104aac:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104aaf:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104ab2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104ab7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104aba:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104abd:	39 d3                	cmp    %edx,%ebx
f0104abf:	72 05                	jb     f0104ac6 <printnum+0x30>
f0104ac1:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104ac4:	77 45                	ja     f0104b0b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104ac6:	83 ec 0c             	sub    $0xc,%esp
f0104ac9:	ff 75 18             	pushl  0x18(%ebp)
f0104acc:	8b 45 14             	mov    0x14(%ebp),%eax
f0104acf:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104ad2:	53                   	push   %ebx
f0104ad3:	ff 75 10             	pushl  0x10(%ebp)
f0104ad6:	83 ec 08             	sub    $0x8,%esp
f0104ad9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104adc:	ff 75 e0             	pushl  -0x20(%ebp)
f0104adf:	ff 75 dc             	pushl  -0x24(%ebp)
f0104ae2:	ff 75 d8             	pushl  -0x28(%ebp)
f0104ae5:	e8 56 11 00 00       	call   f0105c40 <__udivdi3>
f0104aea:	83 c4 18             	add    $0x18,%esp
f0104aed:	52                   	push   %edx
f0104aee:	50                   	push   %eax
f0104aef:	89 f2                	mov    %esi,%edx
f0104af1:	89 f8                	mov    %edi,%eax
f0104af3:	e8 9e ff ff ff       	call   f0104a96 <printnum>
f0104af8:	83 c4 20             	add    $0x20,%esp
f0104afb:	eb 18                	jmp    f0104b15 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104afd:	83 ec 08             	sub    $0x8,%esp
f0104b00:	56                   	push   %esi
f0104b01:	ff 75 18             	pushl  0x18(%ebp)
f0104b04:	ff d7                	call   *%edi
f0104b06:	83 c4 10             	add    $0x10,%esp
f0104b09:	eb 03                	jmp    f0104b0e <printnum+0x78>
f0104b0b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104b0e:	83 eb 01             	sub    $0x1,%ebx
f0104b11:	85 db                	test   %ebx,%ebx
f0104b13:	7f e8                	jg     f0104afd <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104b15:	83 ec 08             	sub    $0x8,%esp
f0104b18:	56                   	push   %esi
f0104b19:	83 ec 04             	sub    $0x4,%esp
f0104b1c:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104b1f:	ff 75 e0             	pushl  -0x20(%ebp)
f0104b22:	ff 75 dc             	pushl  -0x24(%ebp)
f0104b25:	ff 75 d8             	pushl  -0x28(%ebp)
f0104b28:	e8 43 12 00 00       	call   f0105d70 <__umoddi3>
f0104b2d:	83 c4 14             	add    $0x14,%esp
f0104b30:	0f be 80 76 76 10 f0 	movsbl -0xfef898a(%eax),%eax
f0104b37:	50                   	push   %eax
f0104b38:	ff d7                	call   *%edi
}
f0104b3a:	83 c4 10             	add    $0x10,%esp
f0104b3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b40:	5b                   	pop    %ebx
f0104b41:	5e                   	pop    %esi
f0104b42:	5f                   	pop    %edi
f0104b43:	5d                   	pop    %ebp
f0104b44:	c3                   	ret    

f0104b45 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104b45:	55                   	push   %ebp
f0104b46:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104b48:	83 fa 01             	cmp    $0x1,%edx
f0104b4b:	7e 0e                	jle    f0104b5b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104b4d:	8b 10                	mov    (%eax),%edx
f0104b4f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104b52:	89 08                	mov    %ecx,(%eax)
f0104b54:	8b 02                	mov    (%edx),%eax
f0104b56:	8b 52 04             	mov    0x4(%edx),%edx
f0104b59:	eb 22                	jmp    f0104b7d <getuint+0x38>
	else if (lflag)
f0104b5b:	85 d2                	test   %edx,%edx
f0104b5d:	74 10                	je     f0104b6f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104b5f:	8b 10                	mov    (%eax),%edx
f0104b61:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104b64:	89 08                	mov    %ecx,(%eax)
f0104b66:	8b 02                	mov    (%edx),%eax
f0104b68:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b6d:	eb 0e                	jmp    f0104b7d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104b6f:	8b 10                	mov    (%eax),%edx
f0104b71:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104b74:	89 08                	mov    %ecx,(%eax)
f0104b76:	8b 02                	mov    (%edx),%eax
f0104b78:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104b7d:	5d                   	pop    %ebp
f0104b7e:	c3                   	ret    

f0104b7f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104b7f:	55                   	push   %ebp
f0104b80:	89 e5                	mov    %esp,%ebp
f0104b82:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104b85:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104b89:	8b 10                	mov    (%eax),%edx
f0104b8b:	3b 50 04             	cmp    0x4(%eax),%edx
f0104b8e:	73 0a                	jae    f0104b9a <sprintputch+0x1b>
		*b->buf++ = ch;
f0104b90:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104b93:	89 08                	mov    %ecx,(%eax)
f0104b95:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b98:	88 02                	mov    %al,(%edx)
}
f0104b9a:	5d                   	pop    %ebp
f0104b9b:	c3                   	ret    

f0104b9c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104b9c:	55                   	push   %ebp
f0104b9d:	89 e5                	mov    %esp,%ebp
f0104b9f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104ba2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104ba5:	50                   	push   %eax
f0104ba6:	ff 75 10             	pushl  0x10(%ebp)
f0104ba9:	ff 75 0c             	pushl  0xc(%ebp)
f0104bac:	ff 75 08             	pushl  0x8(%ebp)
f0104baf:	e8 05 00 00 00       	call   f0104bb9 <vprintfmt>
	va_end(ap);
}
f0104bb4:	83 c4 10             	add    $0x10,%esp
f0104bb7:	c9                   	leave  
f0104bb8:	c3                   	ret    

f0104bb9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104bb9:	55                   	push   %ebp
f0104bba:	89 e5                	mov    %esp,%ebp
f0104bbc:	57                   	push   %edi
f0104bbd:	56                   	push   %esi
f0104bbe:	53                   	push   %ebx
f0104bbf:	83 ec 2c             	sub    $0x2c,%esp
f0104bc2:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bc5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bc8:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104bcb:	eb 12                	jmp    f0104bdf <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104bcd:	85 c0                	test   %eax,%eax
f0104bcf:	0f 84 89 03 00 00    	je     f0104f5e <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104bd5:	83 ec 08             	sub    $0x8,%esp
f0104bd8:	53                   	push   %ebx
f0104bd9:	50                   	push   %eax
f0104bda:	ff d6                	call   *%esi
f0104bdc:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104bdf:	83 c7 01             	add    $0x1,%edi
f0104be2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104be6:	83 f8 25             	cmp    $0x25,%eax
f0104be9:	75 e2                	jne    f0104bcd <vprintfmt+0x14>
f0104beb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104bef:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104bf6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104bfd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104c04:	ba 00 00 00 00       	mov    $0x0,%edx
f0104c09:	eb 07                	jmp    f0104c12 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104c0e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c12:	8d 47 01             	lea    0x1(%edi),%eax
f0104c15:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104c18:	0f b6 07             	movzbl (%edi),%eax
f0104c1b:	0f b6 c8             	movzbl %al,%ecx
f0104c1e:	83 e8 23             	sub    $0x23,%eax
f0104c21:	3c 55                	cmp    $0x55,%al
f0104c23:	0f 87 1a 03 00 00    	ja     f0104f43 <vprintfmt+0x38a>
f0104c29:	0f b6 c0             	movzbl %al,%eax
f0104c2c:	ff 24 85 40 77 10 f0 	jmp    *-0xfef88c0(,%eax,4)
f0104c33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104c36:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104c3a:	eb d6                	jmp    f0104c12 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c3c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c44:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104c47:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104c4a:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104c4e:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104c51:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104c54:	83 fa 09             	cmp    $0x9,%edx
f0104c57:	77 39                	ja     f0104c92 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104c59:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104c5c:	eb e9                	jmp    f0104c47 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104c5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c61:	8d 48 04             	lea    0x4(%eax),%ecx
f0104c64:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104c67:	8b 00                	mov    (%eax),%eax
f0104c69:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104c6f:	eb 27                	jmp    f0104c98 <vprintfmt+0xdf>
f0104c71:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c74:	85 c0                	test   %eax,%eax
f0104c76:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c7b:	0f 49 c8             	cmovns %eax,%ecx
f0104c7e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c84:	eb 8c                	jmp    f0104c12 <vprintfmt+0x59>
f0104c86:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104c89:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104c90:	eb 80                	jmp    f0104c12 <vprintfmt+0x59>
f0104c92:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104c95:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104c98:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104c9c:	0f 89 70 ff ff ff    	jns    f0104c12 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104ca2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104ca5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ca8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104caf:	e9 5e ff ff ff       	jmp    f0104c12 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104cb4:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cb7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104cba:	e9 53 ff ff ff       	jmp    f0104c12 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104cbf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc2:	8d 50 04             	lea    0x4(%eax),%edx
f0104cc5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104cc8:	83 ec 08             	sub    $0x8,%esp
f0104ccb:	53                   	push   %ebx
f0104ccc:	ff 30                	pushl  (%eax)
f0104cce:	ff d6                	call   *%esi
			break;
f0104cd0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cd3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104cd6:	e9 04 ff ff ff       	jmp    f0104bdf <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104cdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cde:	8d 50 04             	lea    0x4(%eax),%edx
f0104ce1:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ce4:	8b 00                	mov    (%eax),%eax
f0104ce6:	99                   	cltd   
f0104ce7:	31 d0                	xor    %edx,%eax
f0104ce9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104ceb:	83 f8 08             	cmp    $0x8,%eax
f0104cee:	7f 0b                	jg     f0104cfb <vprintfmt+0x142>
f0104cf0:	8b 14 85 a0 78 10 f0 	mov    -0xfef8760(,%eax,4),%edx
f0104cf7:	85 d2                	test   %edx,%edx
f0104cf9:	75 18                	jne    f0104d13 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104cfb:	50                   	push   %eax
f0104cfc:	68 8e 76 10 f0       	push   $0xf010768e
f0104d01:	53                   	push   %ebx
f0104d02:	56                   	push   %esi
f0104d03:	e8 94 fe ff ff       	call   f0104b9c <printfmt>
f0104d08:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104d0e:	e9 cc fe ff ff       	jmp    f0104bdf <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104d13:	52                   	push   %edx
f0104d14:	68 5d 6e 10 f0       	push   $0xf0106e5d
f0104d19:	53                   	push   %ebx
f0104d1a:	56                   	push   %esi
f0104d1b:	e8 7c fe ff ff       	call   f0104b9c <printfmt>
f0104d20:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d26:	e9 b4 fe ff ff       	jmp    f0104bdf <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104d2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d2e:	8d 50 04             	lea    0x4(%eax),%edx
f0104d31:	89 55 14             	mov    %edx,0x14(%ebp)
f0104d34:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104d36:	85 ff                	test   %edi,%edi
f0104d38:	b8 87 76 10 f0       	mov    $0xf0107687,%eax
f0104d3d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104d40:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104d44:	0f 8e 94 00 00 00    	jle    f0104dde <vprintfmt+0x225>
f0104d4a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104d4e:	0f 84 98 00 00 00    	je     f0104dec <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d54:	83 ec 08             	sub    $0x8,%esp
f0104d57:	ff 75 d0             	pushl  -0x30(%ebp)
f0104d5a:	57                   	push   %edi
f0104d5b:	e8 5f 03 00 00       	call   f01050bf <strnlen>
f0104d60:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104d63:	29 c1                	sub    %eax,%ecx
f0104d65:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104d68:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104d6b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104d6f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d72:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104d75:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d77:	eb 0f                	jmp    f0104d88 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104d79:	83 ec 08             	sub    $0x8,%esp
f0104d7c:	53                   	push   %ebx
f0104d7d:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d80:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d82:	83 ef 01             	sub    $0x1,%edi
f0104d85:	83 c4 10             	add    $0x10,%esp
f0104d88:	85 ff                	test   %edi,%edi
f0104d8a:	7f ed                	jg     f0104d79 <vprintfmt+0x1c0>
f0104d8c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104d8f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104d92:	85 c9                	test   %ecx,%ecx
f0104d94:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d99:	0f 49 c1             	cmovns %ecx,%eax
f0104d9c:	29 c1                	sub    %eax,%ecx
f0104d9e:	89 75 08             	mov    %esi,0x8(%ebp)
f0104da1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104da4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104da7:	89 cb                	mov    %ecx,%ebx
f0104da9:	eb 4d                	jmp    f0104df8 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104dab:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104daf:	74 1b                	je     f0104dcc <vprintfmt+0x213>
f0104db1:	0f be c0             	movsbl %al,%eax
f0104db4:	83 e8 20             	sub    $0x20,%eax
f0104db7:	83 f8 5e             	cmp    $0x5e,%eax
f0104dba:	76 10                	jbe    f0104dcc <vprintfmt+0x213>
					putch('?', putdat);
f0104dbc:	83 ec 08             	sub    $0x8,%esp
f0104dbf:	ff 75 0c             	pushl  0xc(%ebp)
f0104dc2:	6a 3f                	push   $0x3f
f0104dc4:	ff 55 08             	call   *0x8(%ebp)
f0104dc7:	83 c4 10             	add    $0x10,%esp
f0104dca:	eb 0d                	jmp    f0104dd9 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104dcc:	83 ec 08             	sub    $0x8,%esp
f0104dcf:	ff 75 0c             	pushl  0xc(%ebp)
f0104dd2:	52                   	push   %edx
f0104dd3:	ff 55 08             	call   *0x8(%ebp)
f0104dd6:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104dd9:	83 eb 01             	sub    $0x1,%ebx
f0104ddc:	eb 1a                	jmp    f0104df8 <vprintfmt+0x23f>
f0104dde:	89 75 08             	mov    %esi,0x8(%ebp)
f0104de1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104de4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104de7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104dea:	eb 0c                	jmp    f0104df8 <vprintfmt+0x23f>
f0104dec:	89 75 08             	mov    %esi,0x8(%ebp)
f0104def:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104df2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104df5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104df8:	83 c7 01             	add    $0x1,%edi
f0104dfb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104dff:	0f be d0             	movsbl %al,%edx
f0104e02:	85 d2                	test   %edx,%edx
f0104e04:	74 23                	je     f0104e29 <vprintfmt+0x270>
f0104e06:	85 f6                	test   %esi,%esi
f0104e08:	78 a1                	js     f0104dab <vprintfmt+0x1f2>
f0104e0a:	83 ee 01             	sub    $0x1,%esi
f0104e0d:	79 9c                	jns    f0104dab <vprintfmt+0x1f2>
f0104e0f:	89 df                	mov    %ebx,%edi
f0104e11:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104e17:	eb 18                	jmp    f0104e31 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104e19:	83 ec 08             	sub    $0x8,%esp
f0104e1c:	53                   	push   %ebx
f0104e1d:	6a 20                	push   $0x20
f0104e1f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104e21:	83 ef 01             	sub    $0x1,%edi
f0104e24:	83 c4 10             	add    $0x10,%esp
f0104e27:	eb 08                	jmp    f0104e31 <vprintfmt+0x278>
f0104e29:	89 df                	mov    %ebx,%edi
f0104e2b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e2e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104e31:	85 ff                	test   %edi,%edi
f0104e33:	7f e4                	jg     f0104e19 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e38:	e9 a2 fd ff ff       	jmp    f0104bdf <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104e3d:	83 fa 01             	cmp    $0x1,%edx
f0104e40:	7e 16                	jle    f0104e58 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104e42:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e45:	8d 50 08             	lea    0x8(%eax),%edx
f0104e48:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e4b:	8b 50 04             	mov    0x4(%eax),%edx
f0104e4e:	8b 00                	mov    (%eax),%eax
f0104e50:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e53:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104e56:	eb 32                	jmp    f0104e8a <vprintfmt+0x2d1>
	else if (lflag)
f0104e58:	85 d2                	test   %edx,%edx
f0104e5a:	74 18                	je     f0104e74 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104e5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e5f:	8d 50 04             	lea    0x4(%eax),%edx
f0104e62:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e65:	8b 00                	mov    (%eax),%eax
f0104e67:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e6a:	89 c1                	mov    %eax,%ecx
f0104e6c:	c1 f9 1f             	sar    $0x1f,%ecx
f0104e6f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104e72:	eb 16                	jmp    f0104e8a <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104e74:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e77:	8d 50 04             	lea    0x4(%eax),%edx
f0104e7a:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e7d:	8b 00                	mov    (%eax),%eax
f0104e7f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e82:	89 c1                	mov    %eax,%ecx
f0104e84:	c1 f9 1f             	sar    $0x1f,%ecx
f0104e87:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104e8a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104e8d:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104e90:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104e95:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104e99:	79 74                	jns    f0104f0f <vprintfmt+0x356>
				putch('-', putdat);
f0104e9b:	83 ec 08             	sub    $0x8,%esp
f0104e9e:	53                   	push   %ebx
f0104e9f:	6a 2d                	push   $0x2d
f0104ea1:	ff d6                	call   *%esi
				num = -(long long) num;
f0104ea3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104ea6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104ea9:	f7 d8                	neg    %eax
f0104eab:	83 d2 00             	adc    $0x0,%edx
f0104eae:	f7 da                	neg    %edx
f0104eb0:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104eb3:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104eb8:	eb 55                	jmp    f0104f0f <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104eba:	8d 45 14             	lea    0x14(%ebp),%eax
f0104ebd:	e8 83 fc ff ff       	call   f0104b45 <getuint>
			base = 10;
f0104ec2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104ec7:	eb 46                	jmp    f0104f0f <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104ec9:	8d 45 14             	lea    0x14(%ebp),%eax
f0104ecc:	e8 74 fc ff ff       	call   f0104b45 <getuint>
			base = 8;
f0104ed1:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104ed6:	eb 37                	jmp    f0104f0f <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104ed8:	83 ec 08             	sub    $0x8,%esp
f0104edb:	53                   	push   %ebx
f0104edc:	6a 30                	push   $0x30
f0104ede:	ff d6                	call   *%esi
			putch('x', putdat);
f0104ee0:	83 c4 08             	add    $0x8,%esp
f0104ee3:	53                   	push   %ebx
f0104ee4:	6a 78                	push   $0x78
f0104ee6:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104ee8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104eeb:	8d 50 04             	lea    0x4(%eax),%edx
f0104eee:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104ef1:	8b 00                	mov    (%eax),%eax
f0104ef3:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104ef8:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104efb:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104f00:	eb 0d                	jmp    f0104f0f <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104f02:	8d 45 14             	lea    0x14(%ebp),%eax
f0104f05:	e8 3b fc ff ff       	call   f0104b45 <getuint>
			base = 16;
f0104f0a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104f0f:	83 ec 0c             	sub    $0xc,%esp
f0104f12:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104f16:	57                   	push   %edi
f0104f17:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f1a:	51                   	push   %ecx
f0104f1b:	52                   	push   %edx
f0104f1c:	50                   	push   %eax
f0104f1d:	89 da                	mov    %ebx,%edx
f0104f1f:	89 f0                	mov    %esi,%eax
f0104f21:	e8 70 fb ff ff       	call   f0104a96 <printnum>
			break;
f0104f26:	83 c4 20             	add    $0x20,%esp
f0104f29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f2c:	e9 ae fc ff ff       	jmp    f0104bdf <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104f31:	83 ec 08             	sub    $0x8,%esp
f0104f34:	53                   	push   %ebx
f0104f35:	51                   	push   %ecx
f0104f36:	ff d6                	call   *%esi
			break;
f0104f38:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f3b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104f3e:	e9 9c fc ff ff       	jmp    f0104bdf <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104f43:	83 ec 08             	sub    $0x8,%esp
f0104f46:	53                   	push   %ebx
f0104f47:	6a 25                	push   $0x25
f0104f49:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104f4b:	83 c4 10             	add    $0x10,%esp
f0104f4e:	eb 03                	jmp    f0104f53 <vprintfmt+0x39a>
f0104f50:	83 ef 01             	sub    $0x1,%edi
f0104f53:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104f57:	75 f7                	jne    f0104f50 <vprintfmt+0x397>
f0104f59:	e9 81 fc ff ff       	jmp    f0104bdf <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104f5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f61:	5b                   	pop    %ebx
f0104f62:	5e                   	pop    %esi
f0104f63:	5f                   	pop    %edi
f0104f64:	5d                   	pop    %ebp
f0104f65:	c3                   	ret    

f0104f66 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104f66:	55                   	push   %ebp
f0104f67:	89 e5                	mov    %esp,%ebp
f0104f69:	83 ec 18             	sub    $0x18,%esp
f0104f6c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f6f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104f72:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104f75:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104f79:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104f7c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104f83:	85 c0                	test   %eax,%eax
f0104f85:	74 26                	je     f0104fad <vsnprintf+0x47>
f0104f87:	85 d2                	test   %edx,%edx
f0104f89:	7e 22                	jle    f0104fad <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104f8b:	ff 75 14             	pushl  0x14(%ebp)
f0104f8e:	ff 75 10             	pushl  0x10(%ebp)
f0104f91:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104f94:	50                   	push   %eax
f0104f95:	68 7f 4b 10 f0       	push   $0xf0104b7f
f0104f9a:	e8 1a fc ff ff       	call   f0104bb9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104f9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104fa2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104fa8:	83 c4 10             	add    $0x10,%esp
f0104fab:	eb 05                	jmp    f0104fb2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104fad:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104fb2:	c9                   	leave  
f0104fb3:	c3                   	ret    

f0104fb4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104fb4:	55                   	push   %ebp
f0104fb5:	89 e5                	mov    %esp,%ebp
f0104fb7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104fba:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104fbd:	50                   	push   %eax
f0104fbe:	ff 75 10             	pushl  0x10(%ebp)
f0104fc1:	ff 75 0c             	pushl  0xc(%ebp)
f0104fc4:	ff 75 08             	pushl  0x8(%ebp)
f0104fc7:	e8 9a ff ff ff       	call   f0104f66 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104fcc:	c9                   	leave  
f0104fcd:	c3                   	ret    

f0104fce <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104fce:	55                   	push   %ebp
f0104fcf:	89 e5                	mov    %esp,%ebp
f0104fd1:	57                   	push   %edi
f0104fd2:	56                   	push   %esi
f0104fd3:	53                   	push   %ebx
f0104fd4:	83 ec 0c             	sub    $0xc,%esp
f0104fd7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104fda:	85 c0                	test   %eax,%eax
f0104fdc:	74 11                	je     f0104fef <readline+0x21>
		cprintf("%s", prompt);
f0104fde:	83 ec 08             	sub    $0x8,%esp
f0104fe1:	50                   	push   %eax
f0104fe2:	68 5d 6e 10 f0       	push   $0xf0106e5d
f0104fe7:	e8 99 e6 ff ff       	call   f0103685 <cprintf>
f0104fec:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104fef:	83 ec 0c             	sub    $0xc,%esp
f0104ff2:	6a 00                	push   $0x0
f0104ff4:	e8 8c b7 ff ff       	call   f0100785 <iscons>
f0104ff9:	89 c7                	mov    %eax,%edi
f0104ffb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104ffe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105003:	e8 6c b7 ff ff       	call   f0100774 <getchar>
f0105008:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010500a:	85 c0                	test   %eax,%eax
f010500c:	79 18                	jns    f0105026 <readline+0x58>
			cprintf("read error: %e\n", c);
f010500e:	83 ec 08             	sub    $0x8,%esp
f0105011:	50                   	push   %eax
f0105012:	68 c4 78 10 f0       	push   $0xf01078c4
f0105017:	e8 69 e6 ff ff       	call   f0103685 <cprintf>
			return NULL;
f010501c:	83 c4 10             	add    $0x10,%esp
f010501f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105024:	eb 79                	jmp    f010509f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105026:	83 f8 08             	cmp    $0x8,%eax
f0105029:	0f 94 c2             	sete   %dl
f010502c:	83 f8 7f             	cmp    $0x7f,%eax
f010502f:	0f 94 c0             	sete   %al
f0105032:	08 c2                	or     %al,%dl
f0105034:	74 1a                	je     f0105050 <readline+0x82>
f0105036:	85 f6                	test   %esi,%esi
f0105038:	7e 16                	jle    f0105050 <readline+0x82>
			if (echoing)
f010503a:	85 ff                	test   %edi,%edi
f010503c:	74 0d                	je     f010504b <readline+0x7d>
				cputchar('\b');
f010503e:	83 ec 0c             	sub    $0xc,%esp
f0105041:	6a 08                	push   $0x8
f0105043:	e8 1c b7 ff ff       	call   f0100764 <cputchar>
f0105048:	83 c4 10             	add    $0x10,%esp
			i--;
f010504b:	83 ee 01             	sub    $0x1,%esi
f010504e:	eb b3                	jmp    f0105003 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105050:	83 fb 1f             	cmp    $0x1f,%ebx
f0105053:	7e 23                	jle    f0105078 <readline+0xaa>
f0105055:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010505b:	7f 1b                	jg     f0105078 <readline+0xaa>
			if (echoing)
f010505d:	85 ff                	test   %edi,%edi
f010505f:	74 0c                	je     f010506d <readline+0x9f>
				cputchar(c);
f0105061:	83 ec 0c             	sub    $0xc,%esp
f0105064:	53                   	push   %ebx
f0105065:	e8 fa b6 ff ff       	call   f0100764 <cputchar>
f010506a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010506d:	88 9e 80 fa 22 f0    	mov    %bl,-0xfdd0580(%esi)
f0105073:	8d 76 01             	lea    0x1(%esi),%esi
f0105076:	eb 8b                	jmp    f0105003 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105078:	83 fb 0a             	cmp    $0xa,%ebx
f010507b:	74 05                	je     f0105082 <readline+0xb4>
f010507d:	83 fb 0d             	cmp    $0xd,%ebx
f0105080:	75 81                	jne    f0105003 <readline+0x35>
			if (echoing)
f0105082:	85 ff                	test   %edi,%edi
f0105084:	74 0d                	je     f0105093 <readline+0xc5>
				cputchar('\n');
f0105086:	83 ec 0c             	sub    $0xc,%esp
f0105089:	6a 0a                	push   $0xa
f010508b:	e8 d4 b6 ff ff       	call   f0100764 <cputchar>
f0105090:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105093:	c6 86 80 fa 22 f0 00 	movb   $0x0,-0xfdd0580(%esi)
			return buf;
f010509a:	b8 80 fa 22 f0       	mov    $0xf022fa80,%eax
		}
	}
}
f010509f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01050a2:	5b                   	pop    %ebx
f01050a3:	5e                   	pop    %esi
f01050a4:	5f                   	pop    %edi
f01050a5:	5d                   	pop    %ebp
f01050a6:	c3                   	ret    

f01050a7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01050a7:	55                   	push   %ebp
f01050a8:	89 e5                	mov    %esp,%ebp
f01050aa:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01050ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01050b2:	eb 03                	jmp    f01050b7 <strlen+0x10>
		n++;
f01050b4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01050b7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01050bb:	75 f7                	jne    f01050b4 <strlen+0xd>
		n++;
	return n;
}
f01050bd:	5d                   	pop    %ebp
f01050be:	c3                   	ret    

f01050bf <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01050bf:	55                   	push   %ebp
f01050c0:	89 e5                	mov    %esp,%ebp
f01050c2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01050c5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01050c8:	ba 00 00 00 00       	mov    $0x0,%edx
f01050cd:	eb 03                	jmp    f01050d2 <strnlen+0x13>
		n++;
f01050cf:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01050d2:	39 c2                	cmp    %eax,%edx
f01050d4:	74 08                	je     f01050de <strnlen+0x1f>
f01050d6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01050da:	75 f3                	jne    f01050cf <strnlen+0x10>
f01050dc:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01050de:	5d                   	pop    %ebp
f01050df:	c3                   	ret    

f01050e0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01050e0:	55                   	push   %ebp
f01050e1:	89 e5                	mov    %esp,%ebp
f01050e3:	53                   	push   %ebx
f01050e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01050e7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01050ea:	89 c2                	mov    %eax,%edx
f01050ec:	83 c2 01             	add    $0x1,%edx
f01050ef:	83 c1 01             	add    $0x1,%ecx
f01050f2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01050f6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01050f9:	84 db                	test   %bl,%bl
f01050fb:	75 ef                	jne    f01050ec <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01050fd:	5b                   	pop    %ebx
f01050fe:	5d                   	pop    %ebp
f01050ff:	c3                   	ret    

f0105100 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105100:	55                   	push   %ebp
f0105101:	89 e5                	mov    %esp,%ebp
f0105103:	53                   	push   %ebx
f0105104:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105107:	53                   	push   %ebx
f0105108:	e8 9a ff ff ff       	call   f01050a7 <strlen>
f010510d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105110:	ff 75 0c             	pushl  0xc(%ebp)
f0105113:	01 d8                	add    %ebx,%eax
f0105115:	50                   	push   %eax
f0105116:	e8 c5 ff ff ff       	call   f01050e0 <strcpy>
	return dst;
}
f010511b:	89 d8                	mov    %ebx,%eax
f010511d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105120:	c9                   	leave  
f0105121:	c3                   	ret    

f0105122 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105122:	55                   	push   %ebp
f0105123:	89 e5                	mov    %esp,%ebp
f0105125:	56                   	push   %esi
f0105126:	53                   	push   %ebx
f0105127:	8b 75 08             	mov    0x8(%ebp),%esi
f010512a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010512d:	89 f3                	mov    %esi,%ebx
f010512f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105132:	89 f2                	mov    %esi,%edx
f0105134:	eb 0f                	jmp    f0105145 <strncpy+0x23>
		*dst++ = *src;
f0105136:	83 c2 01             	add    $0x1,%edx
f0105139:	0f b6 01             	movzbl (%ecx),%eax
f010513c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010513f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105142:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105145:	39 da                	cmp    %ebx,%edx
f0105147:	75 ed                	jne    f0105136 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105149:	89 f0                	mov    %esi,%eax
f010514b:	5b                   	pop    %ebx
f010514c:	5e                   	pop    %esi
f010514d:	5d                   	pop    %ebp
f010514e:	c3                   	ret    

f010514f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010514f:	55                   	push   %ebp
f0105150:	89 e5                	mov    %esp,%ebp
f0105152:	56                   	push   %esi
f0105153:	53                   	push   %ebx
f0105154:	8b 75 08             	mov    0x8(%ebp),%esi
f0105157:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010515a:	8b 55 10             	mov    0x10(%ebp),%edx
f010515d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010515f:	85 d2                	test   %edx,%edx
f0105161:	74 21                	je     f0105184 <strlcpy+0x35>
f0105163:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105167:	89 f2                	mov    %esi,%edx
f0105169:	eb 09                	jmp    f0105174 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010516b:	83 c2 01             	add    $0x1,%edx
f010516e:	83 c1 01             	add    $0x1,%ecx
f0105171:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105174:	39 c2                	cmp    %eax,%edx
f0105176:	74 09                	je     f0105181 <strlcpy+0x32>
f0105178:	0f b6 19             	movzbl (%ecx),%ebx
f010517b:	84 db                	test   %bl,%bl
f010517d:	75 ec                	jne    f010516b <strlcpy+0x1c>
f010517f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105181:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105184:	29 f0                	sub    %esi,%eax
}
f0105186:	5b                   	pop    %ebx
f0105187:	5e                   	pop    %esi
f0105188:	5d                   	pop    %ebp
f0105189:	c3                   	ret    

f010518a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010518a:	55                   	push   %ebp
f010518b:	89 e5                	mov    %esp,%ebp
f010518d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105190:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105193:	eb 06                	jmp    f010519b <strcmp+0x11>
		p++, q++;
f0105195:	83 c1 01             	add    $0x1,%ecx
f0105198:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010519b:	0f b6 01             	movzbl (%ecx),%eax
f010519e:	84 c0                	test   %al,%al
f01051a0:	74 04                	je     f01051a6 <strcmp+0x1c>
f01051a2:	3a 02                	cmp    (%edx),%al
f01051a4:	74 ef                	je     f0105195 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01051a6:	0f b6 c0             	movzbl %al,%eax
f01051a9:	0f b6 12             	movzbl (%edx),%edx
f01051ac:	29 d0                	sub    %edx,%eax
}
f01051ae:	5d                   	pop    %ebp
f01051af:	c3                   	ret    

f01051b0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01051b0:	55                   	push   %ebp
f01051b1:	89 e5                	mov    %esp,%ebp
f01051b3:	53                   	push   %ebx
f01051b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01051b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01051ba:	89 c3                	mov    %eax,%ebx
f01051bc:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01051bf:	eb 06                	jmp    f01051c7 <strncmp+0x17>
		n--, p++, q++;
f01051c1:	83 c0 01             	add    $0x1,%eax
f01051c4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01051c7:	39 d8                	cmp    %ebx,%eax
f01051c9:	74 15                	je     f01051e0 <strncmp+0x30>
f01051cb:	0f b6 08             	movzbl (%eax),%ecx
f01051ce:	84 c9                	test   %cl,%cl
f01051d0:	74 04                	je     f01051d6 <strncmp+0x26>
f01051d2:	3a 0a                	cmp    (%edx),%cl
f01051d4:	74 eb                	je     f01051c1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01051d6:	0f b6 00             	movzbl (%eax),%eax
f01051d9:	0f b6 12             	movzbl (%edx),%edx
f01051dc:	29 d0                	sub    %edx,%eax
f01051de:	eb 05                	jmp    f01051e5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01051e0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01051e5:	5b                   	pop    %ebx
f01051e6:	5d                   	pop    %ebp
f01051e7:	c3                   	ret    

f01051e8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01051e8:	55                   	push   %ebp
f01051e9:	89 e5                	mov    %esp,%ebp
f01051eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01051ee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01051f2:	eb 07                	jmp    f01051fb <strchr+0x13>
		if (*s == c)
f01051f4:	38 ca                	cmp    %cl,%dl
f01051f6:	74 0f                	je     f0105207 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01051f8:	83 c0 01             	add    $0x1,%eax
f01051fb:	0f b6 10             	movzbl (%eax),%edx
f01051fe:	84 d2                	test   %dl,%dl
f0105200:	75 f2                	jne    f01051f4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105202:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105207:	5d                   	pop    %ebp
f0105208:	c3                   	ret    

f0105209 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105209:	55                   	push   %ebp
f010520a:	89 e5                	mov    %esp,%ebp
f010520c:	8b 45 08             	mov    0x8(%ebp),%eax
f010520f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105213:	eb 03                	jmp    f0105218 <strfind+0xf>
f0105215:	83 c0 01             	add    $0x1,%eax
f0105218:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010521b:	38 ca                	cmp    %cl,%dl
f010521d:	74 04                	je     f0105223 <strfind+0x1a>
f010521f:	84 d2                	test   %dl,%dl
f0105221:	75 f2                	jne    f0105215 <strfind+0xc>
			break;
	return (char *) s;
}
f0105223:	5d                   	pop    %ebp
f0105224:	c3                   	ret    

f0105225 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105225:	55                   	push   %ebp
f0105226:	89 e5                	mov    %esp,%ebp
f0105228:	57                   	push   %edi
f0105229:	56                   	push   %esi
f010522a:	53                   	push   %ebx
f010522b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010522e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105231:	85 c9                	test   %ecx,%ecx
f0105233:	74 36                	je     f010526b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105235:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010523b:	75 28                	jne    f0105265 <memset+0x40>
f010523d:	f6 c1 03             	test   $0x3,%cl
f0105240:	75 23                	jne    f0105265 <memset+0x40>
		c &= 0xFF;
f0105242:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105246:	89 d3                	mov    %edx,%ebx
f0105248:	c1 e3 08             	shl    $0x8,%ebx
f010524b:	89 d6                	mov    %edx,%esi
f010524d:	c1 e6 18             	shl    $0x18,%esi
f0105250:	89 d0                	mov    %edx,%eax
f0105252:	c1 e0 10             	shl    $0x10,%eax
f0105255:	09 f0                	or     %esi,%eax
f0105257:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0105259:	89 d8                	mov    %ebx,%eax
f010525b:	09 d0                	or     %edx,%eax
f010525d:	c1 e9 02             	shr    $0x2,%ecx
f0105260:	fc                   	cld    
f0105261:	f3 ab                	rep stos %eax,%es:(%edi)
f0105263:	eb 06                	jmp    f010526b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105265:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105268:	fc                   	cld    
f0105269:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010526b:	89 f8                	mov    %edi,%eax
f010526d:	5b                   	pop    %ebx
f010526e:	5e                   	pop    %esi
f010526f:	5f                   	pop    %edi
f0105270:	5d                   	pop    %ebp
f0105271:	c3                   	ret    

f0105272 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105272:	55                   	push   %ebp
f0105273:	89 e5                	mov    %esp,%ebp
f0105275:	57                   	push   %edi
f0105276:	56                   	push   %esi
f0105277:	8b 45 08             	mov    0x8(%ebp),%eax
f010527a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010527d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105280:	39 c6                	cmp    %eax,%esi
f0105282:	73 35                	jae    f01052b9 <memmove+0x47>
f0105284:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105287:	39 d0                	cmp    %edx,%eax
f0105289:	73 2e                	jae    f01052b9 <memmove+0x47>
		s += n;
		d += n;
f010528b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010528e:	89 d6                	mov    %edx,%esi
f0105290:	09 fe                	or     %edi,%esi
f0105292:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105298:	75 13                	jne    f01052ad <memmove+0x3b>
f010529a:	f6 c1 03             	test   $0x3,%cl
f010529d:	75 0e                	jne    f01052ad <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010529f:	83 ef 04             	sub    $0x4,%edi
f01052a2:	8d 72 fc             	lea    -0x4(%edx),%esi
f01052a5:	c1 e9 02             	shr    $0x2,%ecx
f01052a8:	fd                   	std    
f01052a9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01052ab:	eb 09                	jmp    f01052b6 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01052ad:	83 ef 01             	sub    $0x1,%edi
f01052b0:	8d 72 ff             	lea    -0x1(%edx),%esi
f01052b3:	fd                   	std    
f01052b4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01052b6:	fc                   	cld    
f01052b7:	eb 1d                	jmp    f01052d6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01052b9:	89 f2                	mov    %esi,%edx
f01052bb:	09 c2                	or     %eax,%edx
f01052bd:	f6 c2 03             	test   $0x3,%dl
f01052c0:	75 0f                	jne    f01052d1 <memmove+0x5f>
f01052c2:	f6 c1 03             	test   $0x3,%cl
f01052c5:	75 0a                	jne    f01052d1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01052c7:	c1 e9 02             	shr    $0x2,%ecx
f01052ca:	89 c7                	mov    %eax,%edi
f01052cc:	fc                   	cld    
f01052cd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01052cf:	eb 05                	jmp    f01052d6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01052d1:	89 c7                	mov    %eax,%edi
f01052d3:	fc                   	cld    
f01052d4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01052d6:	5e                   	pop    %esi
f01052d7:	5f                   	pop    %edi
f01052d8:	5d                   	pop    %ebp
f01052d9:	c3                   	ret    

f01052da <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01052da:	55                   	push   %ebp
f01052db:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01052dd:	ff 75 10             	pushl  0x10(%ebp)
f01052e0:	ff 75 0c             	pushl  0xc(%ebp)
f01052e3:	ff 75 08             	pushl  0x8(%ebp)
f01052e6:	e8 87 ff ff ff       	call   f0105272 <memmove>
}
f01052eb:	c9                   	leave  
f01052ec:	c3                   	ret    

f01052ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01052ed:	55                   	push   %ebp
f01052ee:	89 e5                	mov    %esp,%ebp
f01052f0:	56                   	push   %esi
f01052f1:	53                   	push   %ebx
f01052f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01052f5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052f8:	89 c6                	mov    %eax,%esi
f01052fa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01052fd:	eb 1a                	jmp    f0105319 <memcmp+0x2c>
		if (*s1 != *s2)
f01052ff:	0f b6 08             	movzbl (%eax),%ecx
f0105302:	0f b6 1a             	movzbl (%edx),%ebx
f0105305:	38 d9                	cmp    %bl,%cl
f0105307:	74 0a                	je     f0105313 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105309:	0f b6 c1             	movzbl %cl,%eax
f010530c:	0f b6 db             	movzbl %bl,%ebx
f010530f:	29 d8                	sub    %ebx,%eax
f0105311:	eb 0f                	jmp    f0105322 <memcmp+0x35>
		s1++, s2++;
f0105313:	83 c0 01             	add    $0x1,%eax
f0105316:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105319:	39 f0                	cmp    %esi,%eax
f010531b:	75 e2                	jne    f01052ff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010531d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105322:	5b                   	pop    %ebx
f0105323:	5e                   	pop    %esi
f0105324:	5d                   	pop    %ebp
f0105325:	c3                   	ret    

f0105326 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105326:	55                   	push   %ebp
f0105327:	89 e5                	mov    %esp,%ebp
f0105329:	53                   	push   %ebx
f010532a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010532d:	89 c1                	mov    %eax,%ecx
f010532f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105332:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105336:	eb 0a                	jmp    f0105342 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105338:	0f b6 10             	movzbl (%eax),%edx
f010533b:	39 da                	cmp    %ebx,%edx
f010533d:	74 07                	je     f0105346 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010533f:	83 c0 01             	add    $0x1,%eax
f0105342:	39 c8                	cmp    %ecx,%eax
f0105344:	72 f2                	jb     f0105338 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105346:	5b                   	pop    %ebx
f0105347:	5d                   	pop    %ebp
f0105348:	c3                   	ret    

f0105349 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105349:	55                   	push   %ebp
f010534a:	89 e5                	mov    %esp,%ebp
f010534c:	57                   	push   %edi
f010534d:	56                   	push   %esi
f010534e:	53                   	push   %ebx
f010534f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105352:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105355:	eb 03                	jmp    f010535a <strtol+0x11>
		s++;
f0105357:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010535a:	0f b6 01             	movzbl (%ecx),%eax
f010535d:	3c 20                	cmp    $0x20,%al
f010535f:	74 f6                	je     f0105357 <strtol+0xe>
f0105361:	3c 09                	cmp    $0x9,%al
f0105363:	74 f2                	je     f0105357 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105365:	3c 2b                	cmp    $0x2b,%al
f0105367:	75 0a                	jne    f0105373 <strtol+0x2a>
		s++;
f0105369:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010536c:	bf 00 00 00 00       	mov    $0x0,%edi
f0105371:	eb 11                	jmp    f0105384 <strtol+0x3b>
f0105373:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105378:	3c 2d                	cmp    $0x2d,%al
f010537a:	75 08                	jne    f0105384 <strtol+0x3b>
		s++, neg = 1;
f010537c:	83 c1 01             	add    $0x1,%ecx
f010537f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105384:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010538a:	75 15                	jne    f01053a1 <strtol+0x58>
f010538c:	80 39 30             	cmpb   $0x30,(%ecx)
f010538f:	75 10                	jne    f01053a1 <strtol+0x58>
f0105391:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105395:	75 7c                	jne    f0105413 <strtol+0xca>
		s += 2, base = 16;
f0105397:	83 c1 02             	add    $0x2,%ecx
f010539a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010539f:	eb 16                	jmp    f01053b7 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01053a1:	85 db                	test   %ebx,%ebx
f01053a3:	75 12                	jne    f01053b7 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01053a5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01053aa:	80 39 30             	cmpb   $0x30,(%ecx)
f01053ad:	75 08                	jne    f01053b7 <strtol+0x6e>
		s++, base = 8;
f01053af:	83 c1 01             	add    $0x1,%ecx
f01053b2:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01053b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01053bc:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01053bf:	0f b6 11             	movzbl (%ecx),%edx
f01053c2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01053c5:	89 f3                	mov    %esi,%ebx
f01053c7:	80 fb 09             	cmp    $0x9,%bl
f01053ca:	77 08                	ja     f01053d4 <strtol+0x8b>
			dig = *s - '0';
f01053cc:	0f be d2             	movsbl %dl,%edx
f01053cf:	83 ea 30             	sub    $0x30,%edx
f01053d2:	eb 22                	jmp    f01053f6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01053d4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01053d7:	89 f3                	mov    %esi,%ebx
f01053d9:	80 fb 19             	cmp    $0x19,%bl
f01053dc:	77 08                	ja     f01053e6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01053de:	0f be d2             	movsbl %dl,%edx
f01053e1:	83 ea 57             	sub    $0x57,%edx
f01053e4:	eb 10                	jmp    f01053f6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01053e6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01053e9:	89 f3                	mov    %esi,%ebx
f01053eb:	80 fb 19             	cmp    $0x19,%bl
f01053ee:	77 16                	ja     f0105406 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01053f0:	0f be d2             	movsbl %dl,%edx
f01053f3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01053f6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01053f9:	7d 0b                	jge    f0105406 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01053fb:	83 c1 01             	add    $0x1,%ecx
f01053fe:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105402:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105404:	eb b9                	jmp    f01053bf <strtol+0x76>

	if (endptr)
f0105406:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010540a:	74 0d                	je     f0105419 <strtol+0xd0>
		*endptr = (char *) s;
f010540c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010540f:	89 0e                	mov    %ecx,(%esi)
f0105411:	eb 06                	jmp    f0105419 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105413:	85 db                	test   %ebx,%ebx
f0105415:	74 98                	je     f01053af <strtol+0x66>
f0105417:	eb 9e                	jmp    f01053b7 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0105419:	89 c2                	mov    %eax,%edx
f010541b:	f7 da                	neg    %edx
f010541d:	85 ff                	test   %edi,%edi
f010541f:	0f 45 c2             	cmovne %edx,%eax
}
f0105422:	5b                   	pop    %ebx
f0105423:	5e                   	pop    %esi
f0105424:	5f                   	pop    %edi
f0105425:	5d                   	pop    %ebp
f0105426:	c3                   	ret    
f0105427:	90                   	nop

f0105428 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105428:	fa                   	cli    

	xorw    %ax, %ax
f0105429:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010542b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010542d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010542f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105431:	0f 01 16             	lgdtl  (%esi)
f0105434:	74 70                	je     f01054a6 <mpsearch1+0x3>
	movl    %cr0, %eax
f0105436:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105439:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010543d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105440:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105446:	08 00                	or     %al,(%eax)

f0105448 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105448:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f010544c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010544e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105450:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105452:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105456:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105458:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010545a:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f010545f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105462:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105465:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010546a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f010546d:	8b 25 84 fe 22 f0    	mov    0xf022fe84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105473:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105478:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f010547d:	ff d0                	call   *%eax

f010547f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010547f:	eb fe                	jmp    f010547f <spin>
f0105481:	8d 76 00             	lea    0x0(%esi),%esi

f0105484 <gdt>:
	...
f010548c:	ff                   	(bad)  
f010548d:	ff 00                	incl   (%eax)
f010548f:	00 00                	add    %al,(%eax)
f0105491:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105498:	00                   	.byte 0x0
f0105499:	92                   	xchg   %eax,%edx
f010549a:	cf                   	iret   
	...

f010549c <gdtdesc>:
f010549c:	17                   	pop    %ss
f010549d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01054a2 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01054a2:	90                   	nop

f01054a3 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01054a3:	55                   	push   %ebp
f01054a4:	89 e5                	mov    %esp,%ebp
f01054a6:	57                   	push   %edi
f01054a7:	56                   	push   %esi
f01054a8:	53                   	push   %ebx
f01054a9:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01054ac:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01054b2:	89 c3                	mov    %eax,%ebx
f01054b4:	c1 eb 0c             	shr    $0xc,%ebx
f01054b7:	39 cb                	cmp    %ecx,%ebx
f01054b9:	72 12                	jb     f01054cd <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01054bb:	50                   	push   %eax
f01054bc:	68 04 5f 10 f0       	push   $0xf0105f04
f01054c1:	6a 57                	push   $0x57
f01054c3:	68 61 7a 10 f0       	push   $0xf0107a61
f01054c8:	e8 73 ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01054cd:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01054d3:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01054d5:	89 c2                	mov    %eax,%edx
f01054d7:	c1 ea 0c             	shr    $0xc,%edx
f01054da:	39 ca                	cmp    %ecx,%edx
f01054dc:	72 12                	jb     f01054f0 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01054de:	50                   	push   %eax
f01054df:	68 04 5f 10 f0       	push   $0xf0105f04
f01054e4:	6a 57                	push   $0x57
f01054e6:	68 61 7a 10 f0       	push   $0xf0107a61
f01054eb:	e8 50 ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01054f0:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01054f6:	eb 2f                	jmp    f0105527 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01054f8:	83 ec 04             	sub    $0x4,%esp
f01054fb:	6a 04                	push   $0x4
f01054fd:	68 71 7a 10 f0       	push   $0xf0107a71
f0105502:	53                   	push   %ebx
f0105503:	e8 e5 fd ff ff       	call   f01052ed <memcmp>
f0105508:	83 c4 10             	add    $0x10,%esp
f010550b:	85 c0                	test   %eax,%eax
f010550d:	75 15                	jne    f0105524 <mpsearch1+0x81>
f010550f:	89 da                	mov    %ebx,%edx
f0105511:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105514:	0f b6 0a             	movzbl (%edx),%ecx
f0105517:	01 c8                	add    %ecx,%eax
f0105519:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010551c:	39 d7                	cmp    %edx,%edi
f010551e:	75 f4                	jne    f0105514 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105520:	84 c0                	test   %al,%al
f0105522:	74 0e                	je     f0105532 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105524:	83 c3 10             	add    $0x10,%ebx
f0105527:	39 f3                	cmp    %esi,%ebx
f0105529:	72 cd                	jb     f01054f8 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010552b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105530:	eb 02                	jmp    f0105534 <mpsearch1+0x91>
f0105532:	89 d8                	mov    %ebx,%eax
}
f0105534:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105537:	5b                   	pop    %ebx
f0105538:	5e                   	pop    %esi
f0105539:	5f                   	pop    %edi
f010553a:	5d                   	pop    %ebp
f010553b:	c3                   	ret    

f010553c <mp_init>:
	return conf;
}

void
mp_init(void)
{
f010553c:	55                   	push   %ebp
f010553d:	89 e5                	mov    %esp,%ebp
f010553f:	57                   	push   %edi
f0105540:	56                   	push   %esi
f0105541:	53                   	push   %ebx
f0105542:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105545:	c7 05 c0 03 23 f0 20 	movl   $0xf0230020,0xf02303c0
f010554c:	00 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010554f:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105556:	75 16                	jne    f010556e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105558:	68 00 04 00 00       	push   $0x400
f010555d:	68 04 5f 10 f0       	push   $0xf0105f04
f0105562:	6a 6f                	push   $0x6f
f0105564:	68 61 7a 10 f0       	push   $0xf0107a61
f0105569:	e8 d2 aa ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010556e:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105575:	85 c0                	test   %eax,%eax
f0105577:	74 16                	je     f010558f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105579:	c1 e0 04             	shl    $0x4,%eax
f010557c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105581:	e8 1d ff ff ff       	call   f01054a3 <mpsearch1>
f0105586:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105589:	85 c0                	test   %eax,%eax
f010558b:	75 3c                	jne    f01055c9 <mp_init+0x8d>
f010558d:	eb 20                	jmp    f01055af <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010558f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105596:	c1 e0 0a             	shl    $0xa,%eax
f0105599:	2d 00 04 00 00       	sub    $0x400,%eax
f010559e:	ba 00 04 00 00       	mov    $0x400,%edx
f01055a3:	e8 fb fe ff ff       	call   f01054a3 <mpsearch1>
f01055a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01055ab:	85 c0                	test   %eax,%eax
f01055ad:	75 1a                	jne    f01055c9 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01055af:	ba 00 00 01 00       	mov    $0x10000,%edx
f01055b4:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01055b9:	e8 e5 fe ff ff       	call   f01054a3 <mpsearch1>
f01055be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01055c1:	85 c0                	test   %eax,%eax
f01055c3:	0f 84 5d 02 00 00    	je     f0105826 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01055c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01055cc:	8b 70 04             	mov    0x4(%eax),%esi
f01055cf:	85 f6                	test   %esi,%esi
f01055d1:	74 06                	je     f01055d9 <mp_init+0x9d>
f01055d3:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01055d7:	74 15                	je     f01055ee <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01055d9:	83 ec 0c             	sub    $0xc,%esp
f01055dc:	68 d4 78 10 f0       	push   $0xf01078d4
f01055e1:	e8 9f e0 ff ff       	call   f0103685 <cprintf>
f01055e6:	83 c4 10             	add    $0x10,%esp
f01055e9:	e9 38 02 00 00       	jmp    f0105826 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01055ee:	89 f0                	mov    %esi,%eax
f01055f0:	c1 e8 0c             	shr    $0xc,%eax
f01055f3:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01055f9:	72 15                	jb     f0105610 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01055fb:	56                   	push   %esi
f01055fc:	68 04 5f 10 f0       	push   $0xf0105f04
f0105601:	68 90 00 00 00       	push   $0x90
f0105606:	68 61 7a 10 f0       	push   $0xf0107a61
f010560b:	e8 30 aa ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105610:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105616:	83 ec 04             	sub    $0x4,%esp
f0105619:	6a 04                	push   $0x4
f010561b:	68 76 7a 10 f0       	push   $0xf0107a76
f0105620:	53                   	push   %ebx
f0105621:	e8 c7 fc ff ff       	call   f01052ed <memcmp>
f0105626:	83 c4 10             	add    $0x10,%esp
f0105629:	85 c0                	test   %eax,%eax
f010562b:	74 15                	je     f0105642 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f010562d:	83 ec 0c             	sub    $0xc,%esp
f0105630:	68 04 79 10 f0       	push   $0xf0107904
f0105635:	e8 4b e0 ff ff       	call   f0103685 <cprintf>
f010563a:	83 c4 10             	add    $0x10,%esp
f010563d:	e9 e4 01 00 00       	jmp    f0105826 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105642:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105646:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010564a:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f010564d:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105652:	b8 00 00 00 00       	mov    $0x0,%eax
f0105657:	eb 0d                	jmp    f0105666 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105659:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105660:	f0 
f0105661:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105663:	83 c0 01             	add    $0x1,%eax
f0105666:	39 c7                	cmp    %eax,%edi
f0105668:	75 ef                	jne    f0105659 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010566a:	84 d2                	test   %dl,%dl
f010566c:	74 15                	je     f0105683 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010566e:	83 ec 0c             	sub    $0xc,%esp
f0105671:	68 38 79 10 f0       	push   $0xf0107938
f0105676:	e8 0a e0 ff ff       	call   f0103685 <cprintf>
f010567b:	83 c4 10             	add    $0x10,%esp
f010567e:	e9 a3 01 00 00       	jmp    f0105826 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105683:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105687:	3c 01                	cmp    $0x1,%al
f0105689:	74 1d                	je     f01056a8 <mp_init+0x16c>
f010568b:	3c 04                	cmp    $0x4,%al
f010568d:	74 19                	je     f01056a8 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010568f:	83 ec 08             	sub    $0x8,%esp
f0105692:	0f b6 c0             	movzbl %al,%eax
f0105695:	50                   	push   %eax
f0105696:	68 5c 79 10 f0       	push   $0xf010795c
f010569b:	e8 e5 df ff ff       	call   f0103685 <cprintf>
f01056a0:	83 c4 10             	add    $0x10,%esp
f01056a3:	e9 7e 01 00 00       	jmp    f0105826 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01056a8:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01056ac:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01056b0:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01056b5:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f01056ba:	01 ce                	add    %ecx,%esi
f01056bc:	eb 0d                	jmp    f01056cb <mp_init+0x18f>
f01056be:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01056c5:	f0 
f01056c6:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01056c8:	83 c0 01             	add    $0x1,%eax
f01056cb:	39 c7                	cmp    %eax,%edi
f01056cd:	75 ef                	jne    f01056be <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01056cf:	89 d0                	mov    %edx,%eax
f01056d1:	02 43 2a             	add    0x2a(%ebx),%al
f01056d4:	74 15                	je     f01056eb <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01056d6:	83 ec 0c             	sub    $0xc,%esp
f01056d9:	68 7c 79 10 f0       	push   $0xf010797c
f01056de:	e8 a2 df ff ff       	call   f0103685 <cprintf>
f01056e3:	83 c4 10             	add    $0x10,%esp
f01056e6:	e9 3b 01 00 00       	jmp    f0105826 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01056eb:	85 db                	test   %ebx,%ebx
f01056ed:	0f 84 33 01 00 00    	je     f0105826 <mp_init+0x2ea>
		return;
	ismp = 1;
f01056f3:	c7 05 00 00 23 f0 01 	movl   $0x1,0xf0230000
f01056fa:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01056fd:	8b 43 24             	mov    0x24(%ebx),%eax
f0105700:	a3 00 10 27 f0       	mov    %eax,0xf0271000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105705:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105708:	be 00 00 00 00       	mov    $0x0,%esi
f010570d:	e9 85 00 00 00       	jmp    f0105797 <mp_init+0x25b>
		switch (*p) {
f0105712:	0f b6 07             	movzbl (%edi),%eax
f0105715:	84 c0                	test   %al,%al
f0105717:	74 06                	je     f010571f <mp_init+0x1e3>
f0105719:	3c 04                	cmp    $0x4,%al
f010571b:	77 55                	ja     f0105772 <mp_init+0x236>
f010571d:	eb 4e                	jmp    f010576d <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f010571f:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105723:	74 11                	je     f0105736 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105725:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f010572c:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105731:	a3 c0 03 23 f0       	mov    %eax,0xf02303c0
			if (ncpu < NCPU) {
f0105736:	a1 c4 03 23 f0       	mov    0xf02303c4,%eax
f010573b:	83 f8 07             	cmp    $0x7,%eax
f010573e:	7f 13                	jg     f0105753 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105740:	6b d0 74             	imul   $0x74,%eax,%edx
f0105743:	88 82 20 00 23 f0    	mov    %al,-0xfdcffe0(%edx)
				ncpu++;
f0105749:	83 c0 01             	add    $0x1,%eax
f010574c:	a3 c4 03 23 f0       	mov    %eax,0xf02303c4
f0105751:	eb 15                	jmp    f0105768 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105753:	83 ec 08             	sub    $0x8,%esp
f0105756:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010575a:	50                   	push   %eax
f010575b:	68 ac 79 10 f0       	push   $0xf01079ac
f0105760:	e8 20 df ff ff       	call   f0103685 <cprintf>
f0105765:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105768:	83 c7 14             	add    $0x14,%edi
			continue;
f010576b:	eb 27                	jmp    f0105794 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010576d:	83 c7 08             	add    $0x8,%edi
			continue;
f0105770:	eb 22                	jmp    f0105794 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105772:	83 ec 08             	sub    $0x8,%esp
f0105775:	0f b6 c0             	movzbl %al,%eax
f0105778:	50                   	push   %eax
f0105779:	68 d4 79 10 f0       	push   $0xf01079d4
f010577e:	e8 02 df ff ff       	call   f0103685 <cprintf>
			ismp = 0;
f0105783:	c7 05 00 00 23 f0 00 	movl   $0x0,0xf0230000
f010578a:	00 00 00 
			i = conf->entry;
f010578d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105791:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105794:	83 c6 01             	add    $0x1,%esi
f0105797:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010579b:	39 c6                	cmp    %eax,%esi
f010579d:	0f 82 6f ff ff ff    	jb     f0105712 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01057a3:	a1 c0 03 23 f0       	mov    0xf02303c0,%eax
f01057a8:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01057af:	83 3d 00 00 23 f0 00 	cmpl   $0x0,0xf0230000
f01057b6:	75 26                	jne    f01057de <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01057b8:	c7 05 c4 03 23 f0 01 	movl   $0x1,0xf02303c4
f01057bf:	00 00 00 
		lapicaddr = 0;
f01057c2:	c7 05 00 10 27 f0 00 	movl   $0x0,0xf0271000
f01057c9:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01057cc:	83 ec 0c             	sub    $0xc,%esp
f01057cf:	68 f4 79 10 f0       	push   $0xf01079f4
f01057d4:	e8 ac de ff ff       	call   f0103685 <cprintf>
		return;
f01057d9:	83 c4 10             	add    $0x10,%esp
f01057dc:	eb 48                	jmp    f0105826 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01057de:	83 ec 04             	sub    $0x4,%esp
f01057e1:	ff 35 c4 03 23 f0    	pushl  0xf02303c4
f01057e7:	0f b6 00             	movzbl (%eax),%eax
f01057ea:	50                   	push   %eax
f01057eb:	68 7b 7a 10 f0       	push   $0xf0107a7b
f01057f0:	e8 90 de ff ff       	call   f0103685 <cprintf>

	if (mp->imcrp) {
f01057f5:	83 c4 10             	add    $0x10,%esp
f01057f8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01057fb:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01057ff:	74 25                	je     f0105826 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105801:	83 ec 0c             	sub    $0xc,%esp
f0105804:	68 20 7a 10 f0       	push   $0xf0107a20
f0105809:	e8 77 de ff ff       	call   f0103685 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010580e:	ba 22 00 00 00       	mov    $0x22,%edx
f0105813:	b8 70 00 00 00       	mov    $0x70,%eax
f0105818:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105819:	ba 23 00 00 00       	mov    $0x23,%edx
f010581e:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010581f:	83 c8 01             	or     $0x1,%eax
f0105822:	ee                   	out    %al,(%dx)
f0105823:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105826:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105829:	5b                   	pop    %ebx
f010582a:	5e                   	pop    %esi
f010582b:	5f                   	pop    %edi
f010582c:	5d                   	pop    %ebp
f010582d:	c3                   	ret    

f010582e <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f010582e:	55                   	push   %ebp
f010582f:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105831:	8b 0d 04 10 27 f0    	mov    0xf0271004,%ecx
f0105837:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010583a:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010583c:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105841:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105844:	5d                   	pop    %ebp
f0105845:	c3                   	ret    

f0105846 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105846:	55                   	push   %ebp
f0105847:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105849:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f010584e:	85 c0                	test   %eax,%eax
f0105850:	74 08                	je     f010585a <cpunum+0x14>
		return lapic[ID] >> 24;
f0105852:	8b 40 20             	mov    0x20(%eax),%eax
f0105855:	c1 e8 18             	shr    $0x18,%eax
f0105858:	eb 05                	jmp    f010585f <cpunum+0x19>
	return 0;
f010585a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010585f:	5d                   	pop    %ebp
f0105860:	c3                   	ret    

f0105861 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105861:	a1 00 10 27 f0       	mov    0xf0271000,%eax
f0105866:	85 c0                	test   %eax,%eax
f0105868:	0f 84 21 01 00 00    	je     f010598f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010586e:	55                   	push   %ebp
f010586f:	89 e5                	mov    %esp,%ebp
f0105871:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105874:	68 00 10 00 00       	push   $0x1000
f0105879:	50                   	push   %eax
f010587a:	e8 a3 ba ff ff       	call   f0101322 <mmio_map_region>
f010587f:	a3 04 10 27 f0       	mov    %eax,0xf0271004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105884:	ba 27 01 00 00       	mov    $0x127,%edx
f0105889:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010588e:	e8 9b ff ff ff       	call   f010582e <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105893:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105898:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010589d:	e8 8c ff ff ff       	call   f010582e <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01058a2:	ba 20 00 02 00       	mov    $0x20020,%edx
f01058a7:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01058ac:	e8 7d ff ff ff       	call   f010582e <lapicw>
	lapicw(TICR, 10000000); 
f01058b1:	ba 80 96 98 00       	mov    $0x989680,%edx
f01058b6:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01058bb:	e8 6e ff ff ff       	call   f010582e <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01058c0:	e8 81 ff ff ff       	call   f0105846 <cpunum>
f01058c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01058c8:	05 20 00 23 f0       	add    $0xf0230020,%eax
f01058cd:	83 c4 10             	add    $0x10,%esp
f01058d0:	39 05 c0 03 23 f0    	cmp    %eax,0xf02303c0
f01058d6:	74 0f                	je     f01058e7 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01058d8:	ba 00 00 01 00       	mov    $0x10000,%edx
f01058dd:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01058e2:	e8 47 ff ff ff       	call   f010582e <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01058e7:	ba 00 00 01 00       	mov    $0x10000,%edx
f01058ec:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01058f1:	e8 38 ff ff ff       	call   f010582e <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01058f6:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f01058fb:	8b 40 30             	mov    0x30(%eax),%eax
f01058fe:	c1 e8 10             	shr    $0x10,%eax
f0105901:	3c 03                	cmp    $0x3,%al
f0105903:	76 0f                	jbe    f0105914 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105905:	ba 00 00 01 00       	mov    $0x10000,%edx
f010590a:	b8 d0 00 00 00       	mov    $0xd0,%eax
f010590f:	e8 1a ff ff ff       	call   f010582e <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105914:	ba 33 00 00 00       	mov    $0x33,%edx
f0105919:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010591e:	e8 0b ff ff ff       	call   f010582e <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105923:	ba 00 00 00 00       	mov    $0x0,%edx
f0105928:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010592d:	e8 fc fe ff ff       	call   f010582e <lapicw>
	lapicw(ESR, 0);
f0105932:	ba 00 00 00 00       	mov    $0x0,%edx
f0105937:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010593c:	e8 ed fe ff ff       	call   f010582e <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105941:	ba 00 00 00 00       	mov    $0x0,%edx
f0105946:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010594b:	e8 de fe ff ff       	call   f010582e <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105950:	ba 00 00 00 00       	mov    $0x0,%edx
f0105955:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010595a:	e8 cf fe ff ff       	call   f010582e <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f010595f:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105964:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105969:	e8 c0 fe ff ff       	call   f010582e <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010596e:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105974:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010597a:	f6 c4 10             	test   $0x10,%ah
f010597d:	75 f5                	jne    f0105974 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010597f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105984:	b8 20 00 00 00       	mov    $0x20,%eax
f0105989:	e8 a0 fe ff ff       	call   f010582e <lapicw>
}
f010598e:	c9                   	leave  
f010598f:	f3 c3                	repz ret 

f0105991 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105991:	83 3d 04 10 27 f0 00 	cmpl   $0x0,0xf0271004
f0105998:	74 13                	je     f01059ad <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010599a:	55                   	push   %ebp
f010599b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010599d:	ba 00 00 00 00       	mov    $0x0,%edx
f01059a2:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01059a7:	e8 82 fe ff ff       	call   f010582e <lapicw>
}
f01059ac:	5d                   	pop    %ebp
f01059ad:	f3 c3                	repz ret 

f01059af <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01059af:	55                   	push   %ebp
f01059b0:	89 e5                	mov    %esp,%ebp
f01059b2:	56                   	push   %esi
f01059b3:	53                   	push   %ebx
f01059b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01059b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01059ba:	ba 70 00 00 00       	mov    $0x70,%edx
f01059bf:	b8 0f 00 00 00       	mov    $0xf,%eax
f01059c4:	ee                   	out    %al,(%dx)
f01059c5:	ba 71 00 00 00       	mov    $0x71,%edx
f01059ca:	b8 0a 00 00 00       	mov    $0xa,%eax
f01059cf:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01059d0:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f01059d7:	75 19                	jne    f01059f2 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01059d9:	68 67 04 00 00       	push   $0x467
f01059de:	68 04 5f 10 f0       	push   $0xf0105f04
f01059e3:	68 98 00 00 00       	push   $0x98
f01059e8:	68 98 7a 10 f0       	push   $0xf0107a98
f01059ed:	e8 4e a6 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01059f2:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01059f9:	00 00 
	wrv[1] = addr >> 4;
f01059fb:	89 d8                	mov    %ebx,%eax
f01059fd:	c1 e8 04             	shr    $0x4,%eax
f0105a00:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105a06:	c1 e6 18             	shl    $0x18,%esi
f0105a09:	89 f2                	mov    %esi,%edx
f0105a0b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105a10:	e8 19 fe ff ff       	call   f010582e <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105a15:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105a1a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a1f:	e8 0a fe ff ff       	call   f010582e <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105a24:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105a29:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a2e:	e8 fb fd ff ff       	call   f010582e <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105a33:	c1 eb 0c             	shr    $0xc,%ebx
f0105a36:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105a39:	89 f2                	mov    %esi,%edx
f0105a3b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105a40:	e8 e9 fd ff ff       	call   f010582e <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105a45:	89 da                	mov    %ebx,%edx
f0105a47:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a4c:	e8 dd fd ff ff       	call   f010582e <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105a51:	89 f2                	mov    %esi,%edx
f0105a53:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105a58:	e8 d1 fd ff ff       	call   f010582e <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105a5d:	89 da                	mov    %ebx,%edx
f0105a5f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a64:	e8 c5 fd ff ff       	call   f010582e <lapicw>
		microdelay(200);
	}
}
f0105a69:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105a6c:	5b                   	pop    %ebx
f0105a6d:	5e                   	pop    %esi
f0105a6e:	5d                   	pop    %ebp
f0105a6f:	c3                   	ret    

f0105a70 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105a70:	55                   	push   %ebp
f0105a71:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105a73:	8b 55 08             	mov    0x8(%ebp),%edx
f0105a76:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105a7c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a81:	e8 a8 fd ff ff       	call   f010582e <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105a86:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105a8c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105a92:	f6 c4 10             	test   $0x10,%ah
f0105a95:	75 f5                	jne    f0105a8c <lapic_ipi+0x1c>
		;
}
f0105a97:	5d                   	pop    %ebp
f0105a98:	c3                   	ret    

f0105a99 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105a99:	55                   	push   %ebp
f0105a9a:	89 e5                	mov    %esp,%ebp
f0105a9c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105a9f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105aa5:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105aa8:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105aab:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105ab2:	5d                   	pop    %ebp
f0105ab3:	c3                   	ret    

f0105ab4 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105ab4:	55                   	push   %ebp
f0105ab5:	89 e5                	mov    %esp,%ebp
f0105ab7:	56                   	push   %esi
f0105ab8:	53                   	push   %ebx
f0105ab9:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105abc:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105abf:	74 14                	je     f0105ad5 <spin_lock+0x21>
f0105ac1:	8b 73 08             	mov    0x8(%ebx),%esi
f0105ac4:	e8 7d fd ff ff       	call   f0105846 <cpunum>
f0105ac9:	6b c0 74             	imul   $0x74,%eax,%eax
f0105acc:	05 20 00 23 f0       	add    $0xf0230020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105ad1:	39 c6                	cmp    %eax,%esi
f0105ad3:	74 07                	je     f0105adc <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105ad5:	ba 01 00 00 00       	mov    $0x1,%edx
f0105ada:	eb 20                	jmp    f0105afc <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105adc:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105adf:	e8 62 fd ff ff       	call   f0105846 <cpunum>
f0105ae4:	83 ec 0c             	sub    $0xc,%esp
f0105ae7:	53                   	push   %ebx
f0105ae8:	50                   	push   %eax
f0105ae9:	68 a8 7a 10 f0       	push   $0xf0107aa8
f0105aee:	6a 41                	push   $0x41
f0105af0:	68 0c 7b 10 f0       	push   $0xf0107b0c
f0105af5:	e8 46 a5 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105afa:	f3 90                	pause  
f0105afc:	89 d0                	mov    %edx,%eax
f0105afe:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105b01:	85 c0                	test   %eax,%eax
f0105b03:	75 f5                	jne    f0105afa <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105b05:	e8 3c fd ff ff       	call   f0105846 <cpunum>
f0105b0a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105b0d:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105b12:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105b15:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105b18:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105b1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0105b1f:	eb 0b                	jmp    f0105b2c <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105b21:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105b24:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105b27:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105b29:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105b2c:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105b32:	76 11                	jbe    f0105b45 <spin_lock+0x91>
f0105b34:	83 f8 09             	cmp    $0x9,%eax
f0105b37:	7e e8                	jle    f0105b21 <spin_lock+0x6d>
f0105b39:	eb 0a                	jmp    f0105b45 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105b3b:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105b42:	83 c0 01             	add    $0x1,%eax
f0105b45:	83 f8 09             	cmp    $0x9,%eax
f0105b48:	7e f1                	jle    f0105b3b <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105b4a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105b4d:	5b                   	pop    %ebx
f0105b4e:	5e                   	pop    %esi
f0105b4f:	5d                   	pop    %ebp
f0105b50:	c3                   	ret    

f0105b51 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105b51:	55                   	push   %ebp
f0105b52:	89 e5                	mov    %esp,%ebp
f0105b54:	57                   	push   %edi
f0105b55:	56                   	push   %esi
f0105b56:	53                   	push   %ebx
f0105b57:	83 ec 4c             	sub    $0x4c,%esp
f0105b5a:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105b5d:	83 3e 00             	cmpl   $0x0,(%esi)
f0105b60:	74 18                	je     f0105b7a <spin_unlock+0x29>
f0105b62:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105b65:	e8 dc fc ff ff       	call   f0105846 <cpunum>
f0105b6a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105b6d:	05 20 00 23 f0       	add    $0xf0230020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105b72:	39 c3                	cmp    %eax,%ebx
f0105b74:	0f 84 a5 00 00 00    	je     f0105c1f <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105b7a:	83 ec 04             	sub    $0x4,%esp
f0105b7d:	6a 28                	push   $0x28
f0105b7f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105b82:	50                   	push   %eax
f0105b83:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105b86:	53                   	push   %ebx
f0105b87:	e8 e6 f6 ff ff       	call   f0105272 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105b8c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105b8f:	0f b6 38             	movzbl (%eax),%edi
f0105b92:	8b 76 04             	mov    0x4(%esi),%esi
f0105b95:	e8 ac fc ff ff       	call   f0105846 <cpunum>
f0105b9a:	57                   	push   %edi
f0105b9b:	56                   	push   %esi
f0105b9c:	50                   	push   %eax
f0105b9d:	68 d4 7a 10 f0       	push   $0xf0107ad4
f0105ba2:	e8 de da ff ff       	call   f0103685 <cprintf>
f0105ba7:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105baa:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105bad:	eb 54                	jmp    f0105c03 <spin_unlock+0xb2>
f0105baf:	83 ec 08             	sub    $0x8,%esp
f0105bb2:	57                   	push   %edi
f0105bb3:	50                   	push   %eax
f0105bb4:	e8 fa eb ff ff       	call   f01047b3 <debuginfo_eip>
f0105bb9:	83 c4 10             	add    $0x10,%esp
f0105bbc:	85 c0                	test   %eax,%eax
f0105bbe:	78 27                	js     f0105be7 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105bc0:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105bc2:	83 ec 04             	sub    $0x4,%esp
f0105bc5:	89 c2                	mov    %eax,%edx
f0105bc7:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105bca:	52                   	push   %edx
f0105bcb:	ff 75 b0             	pushl  -0x50(%ebp)
f0105bce:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105bd1:	ff 75 ac             	pushl  -0x54(%ebp)
f0105bd4:	ff 75 a8             	pushl  -0x58(%ebp)
f0105bd7:	50                   	push   %eax
f0105bd8:	68 1c 7b 10 f0       	push   $0xf0107b1c
f0105bdd:	e8 a3 da ff ff       	call   f0103685 <cprintf>
f0105be2:	83 c4 20             	add    $0x20,%esp
f0105be5:	eb 12                	jmp    f0105bf9 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105be7:	83 ec 08             	sub    $0x8,%esp
f0105bea:	ff 36                	pushl  (%esi)
f0105bec:	68 33 7b 10 f0       	push   $0xf0107b33
f0105bf1:	e8 8f da ff ff       	call   f0103685 <cprintf>
f0105bf6:	83 c4 10             	add    $0x10,%esp
f0105bf9:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105bfc:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105bff:	39 c3                	cmp    %eax,%ebx
f0105c01:	74 08                	je     f0105c0b <spin_unlock+0xba>
f0105c03:	89 de                	mov    %ebx,%esi
f0105c05:	8b 03                	mov    (%ebx),%eax
f0105c07:	85 c0                	test   %eax,%eax
f0105c09:	75 a4                	jne    f0105baf <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105c0b:	83 ec 04             	sub    $0x4,%esp
f0105c0e:	68 3b 7b 10 f0       	push   $0xf0107b3b
f0105c13:	6a 67                	push   $0x67
f0105c15:	68 0c 7b 10 f0       	push   $0xf0107b0c
f0105c1a:	e8 21 a4 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105c1f:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105c26:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105c2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c32:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105c35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105c38:	5b                   	pop    %ebx
f0105c39:	5e                   	pop    %esi
f0105c3a:	5f                   	pop    %edi
f0105c3b:	5d                   	pop    %ebp
f0105c3c:	c3                   	ret    
f0105c3d:	66 90                	xchg   %ax,%ax
f0105c3f:	90                   	nop

f0105c40 <__udivdi3>:
f0105c40:	55                   	push   %ebp
f0105c41:	57                   	push   %edi
f0105c42:	56                   	push   %esi
f0105c43:	53                   	push   %ebx
f0105c44:	83 ec 1c             	sub    $0x1c,%esp
f0105c47:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105c4b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105c4f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105c53:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105c57:	85 f6                	test   %esi,%esi
f0105c59:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105c5d:	89 ca                	mov    %ecx,%edx
f0105c5f:	89 f8                	mov    %edi,%eax
f0105c61:	75 3d                	jne    f0105ca0 <__udivdi3+0x60>
f0105c63:	39 cf                	cmp    %ecx,%edi
f0105c65:	0f 87 c5 00 00 00    	ja     f0105d30 <__udivdi3+0xf0>
f0105c6b:	85 ff                	test   %edi,%edi
f0105c6d:	89 fd                	mov    %edi,%ebp
f0105c6f:	75 0b                	jne    f0105c7c <__udivdi3+0x3c>
f0105c71:	b8 01 00 00 00       	mov    $0x1,%eax
f0105c76:	31 d2                	xor    %edx,%edx
f0105c78:	f7 f7                	div    %edi
f0105c7a:	89 c5                	mov    %eax,%ebp
f0105c7c:	89 c8                	mov    %ecx,%eax
f0105c7e:	31 d2                	xor    %edx,%edx
f0105c80:	f7 f5                	div    %ebp
f0105c82:	89 c1                	mov    %eax,%ecx
f0105c84:	89 d8                	mov    %ebx,%eax
f0105c86:	89 cf                	mov    %ecx,%edi
f0105c88:	f7 f5                	div    %ebp
f0105c8a:	89 c3                	mov    %eax,%ebx
f0105c8c:	89 d8                	mov    %ebx,%eax
f0105c8e:	89 fa                	mov    %edi,%edx
f0105c90:	83 c4 1c             	add    $0x1c,%esp
f0105c93:	5b                   	pop    %ebx
f0105c94:	5e                   	pop    %esi
f0105c95:	5f                   	pop    %edi
f0105c96:	5d                   	pop    %ebp
f0105c97:	c3                   	ret    
f0105c98:	90                   	nop
f0105c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105ca0:	39 ce                	cmp    %ecx,%esi
f0105ca2:	77 74                	ja     f0105d18 <__udivdi3+0xd8>
f0105ca4:	0f bd fe             	bsr    %esi,%edi
f0105ca7:	83 f7 1f             	xor    $0x1f,%edi
f0105caa:	0f 84 98 00 00 00    	je     f0105d48 <__udivdi3+0x108>
f0105cb0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105cb5:	89 f9                	mov    %edi,%ecx
f0105cb7:	89 c5                	mov    %eax,%ebp
f0105cb9:	29 fb                	sub    %edi,%ebx
f0105cbb:	d3 e6                	shl    %cl,%esi
f0105cbd:	89 d9                	mov    %ebx,%ecx
f0105cbf:	d3 ed                	shr    %cl,%ebp
f0105cc1:	89 f9                	mov    %edi,%ecx
f0105cc3:	d3 e0                	shl    %cl,%eax
f0105cc5:	09 ee                	or     %ebp,%esi
f0105cc7:	89 d9                	mov    %ebx,%ecx
f0105cc9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105ccd:	89 d5                	mov    %edx,%ebp
f0105ccf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105cd3:	d3 ed                	shr    %cl,%ebp
f0105cd5:	89 f9                	mov    %edi,%ecx
f0105cd7:	d3 e2                	shl    %cl,%edx
f0105cd9:	89 d9                	mov    %ebx,%ecx
f0105cdb:	d3 e8                	shr    %cl,%eax
f0105cdd:	09 c2                	or     %eax,%edx
f0105cdf:	89 d0                	mov    %edx,%eax
f0105ce1:	89 ea                	mov    %ebp,%edx
f0105ce3:	f7 f6                	div    %esi
f0105ce5:	89 d5                	mov    %edx,%ebp
f0105ce7:	89 c3                	mov    %eax,%ebx
f0105ce9:	f7 64 24 0c          	mull   0xc(%esp)
f0105ced:	39 d5                	cmp    %edx,%ebp
f0105cef:	72 10                	jb     f0105d01 <__udivdi3+0xc1>
f0105cf1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105cf5:	89 f9                	mov    %edi,%ecx
f0105cf7:	d3 e6                	shl    %cl,%esi
f0105cf9:	39 c6                	cmp    %eax,%esi
f0105cfb:	73 07                	jae    f0105d04 <__udivdi3+0xc4>
f0105cfd:	39 d5                	cmp    %edx,%ebp
f0105cff:	75 03                	jne    f0105d04 <__udivdi3+0xc4>
f0105d01:	83 eb 01             	sub    $0x1,%ebx
f0105d04:	31 ff                	xor    %edi,%edi
f0105d06:	89 d8                	mov    %ebx,%eax
f0105d08:	89 fa                	mov    %edi,%edx
f0105d0a:	83 c4 1c             	add    $0x1c,%esp
f0105d0d:	5b                   	pop    %ebx
f0105d0e:	5e                   	pop    %esi
f0105d0f:	5f                   	pop    %edi
f0105d10:	5d                   	pop    %ebp
f0105d11:	c3                   	ret    
f0105d12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105d18:	31 ff                	xor    %edi,%edi
f0105d1a:	31 db                	xor    %ebx,%ebx
f0105d1c:	89 d8                	mov    %ebx,%eax
f0105d1e:	89 fa                	mov    %edi,%edx
f0105d20:	83 c4 1c             	add    $0x1c,%esp
f0105d23:	5b                   	pop    %ebx
f0105d24:	5e                   	pop    %esi
f0105d25:	5f                   	pop    %edi
f0105d26:	5d                   	pop    %ebp
f0105d27:	c3                   	ret    
f0105d28:	90                   	nop
f0105d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105d30:	89 d8                	mov    %ebx,%eax
f0105d32:	f7 f7                	div    %edi
f0105d34:	31 ff                	xor    %edi,%edi
f0105d36:	89 c3                	mov    %eax,%ebx
f0105d38:	89 d8                	mov    %ebx,%eax
f0105d3a:	89 fa                	mov    %edi,%edx
f0105d3c:	83 c4 1c             	add    $0x1c,%esp
f0105d3f:	5b                   	pop    %ebx
f0105d40:	5e                   	pop    %esi
f0105d41:	5f                   	pop    %edi
f0105d42:	5d                   	pop    %ebp
f0105d43:	c3                   	ret    
f0105d44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105d48:	39 ce                	cmp    %ecx,%esi
f0105d4a:	72 0c                	jb     f0105d58 <__udivdi3+0x118>
f0105d4c:	31 db                	xor    %ebx,%ebx
f0105d4e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105d52:	0f 87 34 ff ff ff    	ja     f0105c8c <__udivdi3+0x4c>
f0105d58:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105d5d:	e9 2a ff ff ff       	jmp    f0105c8c <__udivdi3+0x4c>
f0105d62:	66 90                	xchg   %ax,%ax
f0105d64:	66 90                	xchg   %ax,%ax
f0105d66:	66 90                	xchg   %ax,%ax
f0105d68:	66 90                	xchg   %ax,%ax
f0105d6a:	66 90                	xchg   %ax,%ax
f0105d6c:	66 90                	xchg   %ax,%ax
f0105d6e:	66 90                	xchg   %ax,%ax

f0105d70 <__umoddi3>:
f0105d70:	55                   	push   %ebp
f0105d71:	57                   	push   %edi
f0105d72:	56                   	push   %esi
f0105d73:	53                   	push   %ebx
f0105d74:	83 ec 1c             	sub    $0x1c,%esp
f0105d77:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105d7b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105d7f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105d83:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105d87:	85 d2                	test   %edx,%edx
f0105d89:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105d8d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105d91:	89 f3                	mov    %esi,%ebx
f0105d93:	89 3c 24             	mov    %edi,(%esp)
f0105d96:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105d9a:	75 1c                	jne    f0105db8 <__umoddi3+0x48>
f0105d9c:	39 f7                	cmp    %esi,%edi
f0105d9e:	76 50                	jbe    f0105df0 <__umoddi3+0x80>
f0105da0:	89 c8                	mov    %ecx,%eax
f0105da2:	89 f2                	mov    %esi,%edx
f0105da4:	f7 f7                	div    %edi
f0105da6:	89 d0                	mov    %edx,%eax
f0105da8:	31 d2                	xor    %edx,%edx
f0105daa:	83 c4 1c             	add    $0x1c,%esp
f0105dad:	5b                   	pop    %ebx
f0105dae:	5e                   	pop    %esi
f0105daf:	5f                   	pop    %edi
f0105db0:	5d                   	pop    %ebp
f0105db1:	c3                   	ret    
f0105db2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105db8:	39 f2                	cmp    %esi,%edx
f0105dba:	89 d0                	mov    %edx,%eax
f0105dbc:	77 52                	ja     f0105e10 <__umoddi3+0xa0>
f0105dbe:	0f bd ea             	bsr    %edx,%ebp
f0105dc1:	83 f5 1f             	xor    $0x1f,%ebp
f0105dc4:	75 5a                	jne    f0105e20 <__umoddi3+0xb0>
f0105dc6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105dca:	0f 82 e0 00 00 00    	jb     f0105eb0 <__umoddi3+0x140>
f0105dd0:	39 0c 24             	cmp    %ecx,(%esp)
f0105dd3:	0f 86 d7 00 00 00    	jbe    f0105eb0 <__umoddi3+0x140>
f0105dd9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105ddd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105de1:	83 c4 1c             	add    $0x1c,%esp
f0105de4:	5b                   	pop    %ebx
f0105de5:	5e                   	pop    %esi
f0105de6:	5f                   	pop    %edi
f0105de7:	5d                   	pop    %ebp
f0105de8:	c3                   	ret    
f0105de9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105df0:	85 ff                	test   %edi,%edi
f0105df2:	89 fd                	mov    %edi,%ebp
f0105df4:	75 0b                	jne    f0105e01 <__umoddi3+0x91>
f0105df6:	b8 01 00 00 00       	mov    $0x1,%eax
f0105dfb:	31 d2                	xor    %edx,%edx
f0105dfd:	f7 f7                	div    %edi
f0105dff:	89 c5                	mov    %eax,%ebp
f0105e01:	89 f0                	mov    %esi,%eax
f0105e03:	31 d2                	xor    %edx,%edx
f0105e05:	f7 f5                	div    %ebp
f0105e07:	89 c8                	mov    %ecx,%eax
f0105e09:	f7 f5                	div    %ebp
f0105e0b:	89 d0                	mov    %edx,%eax
f0105e0d:	eb 99                	jmp    f0105da8 <__umoddi3+0x38>
f0105e0f:	90                   	nop
f0105e10:	89 c8                	mov    %ecx,%eax
f0105e12:	89 f2                	mov    %esi,%edx
f0105e14:	83 c4 1c             	add    $0x1c,%esp
f0105e17:	5b                   	pop    %ebx
f0105e18:	5e                   	pop    %esi
f0105e19:	5f                   	pop    %edi
f0105e1a:	5d                   	pop    %ebp
f0105e1b:	c3                   	ret    
f0105e1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105e20:	8b 34 24             	mov    (%esp),%esi
f0105e23:	bf 20 00 00 00       	mov    $0x20,%edi
f0105e28:	89 e9                	mov    %ebp,%ecx
f0105e2a:	29 ef                	sub    %ebp,%edi
f0105e2c:	d3 e0                	shl    %cl,%eax
f0105e2e:	89 f9                	mov    %edi,%ecx
f0105e30:	89 f2                	mov    %esi,%edx
f0105e32:	d3 ea                	shr    %cl,%edx
f0105e34:	89 e9                	mov    %ebp,%ecx
f0105e36:	09 c2                	or     %eax,%edx
f0105e38:	89 d8                	mov    %ebx,%eax
f0105e3a:	89 14 24             	mov    %edx,(%esp)
f0105e3d:	89 f2                	mov    %esi,%edx
f0105e3f:	d3 e2                	shl    %cl,%edx
f0105e41:	89 f9                	mov    %edi,%ecx
f0105e43:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105e47:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105e4b:	d3 e8                	shr    %cl,%eax
f0105e4d:	89 e9                	mov    %ebp,%ecx
f0105e4f:	89 c6                	mov    %eax,%esi
f0105e51:	d3 e3                	shl    %cl,%ebx
f0105e53:	89 f9                	mov    %edi,%ecx
f0105e55:	89 d0                	mov    %edx,%eax
f0105e57:	d3 e8                	shr    %cl,%eax
f0105e59:	89 e9                	mov    %ebp,%ecx
f0105e5b:	09 d8                	or     %ebx,%eax
f0105e5d:	89 d3                	mov    %edx,%ebx
f0105e5f:	89 f2                	mov    %esi,%edx
f0105e61:	f7 34 24             	divl   (%esp)
f0105e64:	89 d6                	mov    %edx,%esi
f0105e66:	d3 e3                	shl    %cl,%ebx
f0105e68:	f7 64 24 04          	mull   0x4(%esp)
f0105e6c:	39 d6                	cmp    %edx,%esi
f0105e6e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105e72:	89 d1                	mov    %edx,%ecx
f0105e74:	89 c3                	mov    %eax,%ebx
f0105e76:	72 08                	jb     f0105e80 <__umoddi3+0x110>
f0105e78:	75 11                	jne    f0105e8b <__umoddi3+0x11b>
f0105e7a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0105e7e:	73 0b                	jae    f0105e8b <__umoddi3+0x11b>
f0105e80:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105e84:	1b 14 24             	sbb    (%esp),%edx
f0105e87:	89 d1                	mov    %edx,%ecx
f0105e89:	89 c3                	mov    %eax,%ebx
f0105e8b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105e8f:	29 da                	sub    %ebx,%edx
f0105e91:	19 ce                	sbb    %ecx,%esi
f0105e93:	89 f9                	mov    %edi,%ecx
f0105e95:	89 f0                	mov    %esi,%eax
f0105e97:	d3 e0                	shl    %cl,%eax
f0105e99:	89 e9                	mov    %ebp,%ecx
f0105e9b:	d3 ea                	shr    %cl,%edx
f0105e9d:	89 e9                	mov    %ebp,%ecx
f0105e9f:	d3 ee                	shr    %cl,%esi
f0105ea1:	09 d0                	or     %edx,%eax
f0105ea3:	89 f2                	mov    %esi,%edx
f0105ea5:	83 c4 1c             	add    $0x1c,%esp
f0105ea8:	5b                   	pop    %ebx
f0105ea9:	5e                   	pop    %esi
f0105eaa:	5f                   	pop    %edi
f0105eab:	5d                   	pop    %ebp
f0105eac:	c3                   	ret    
f0105ead:	8d 76 00             	lea    0x0(%esi),%esi
f0105eb0:	29 f9                	sub    %edi,%ecx
f0105eb2:	19 d6                	sbb    %edx,%esi
f0105eb4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105eb8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105ebc:	e9 18 ff ff ff       	jmp    f0105dd9 <__umoddi3+0x69>
