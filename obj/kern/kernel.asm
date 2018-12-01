
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
f0100048:	83 3d 80 ee 22 f0 00 	cmpl   $0x0,0xf022ee80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ee 22 f0    	mov    %esi,0xf022ee80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 f9 56 00 00       	call   f010575a <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 00 5e 10 f0       	push   $0xf0105e00
f010006d:	e8 0c 36 00 00       	call   f010367e <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 dc 35 00 00       	call   f0103658 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 bc 61 10 f0 	movl   $0xf01061bc,(%esp)
f0100083:	e8 f6 35 00 00       	call   f010367e <cprintf>
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
f01000a1:	b8 08 00 27 f0       	mov    $0xf0270008,%eax
f01000a6:	2d 10 d9 22 f0       	sub    $0xf022d910,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 10 d9 22 f0       	push   $0xf022d910
f01000b3:	e8 82 50 00 00       	call   f010513a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 6c 5e 10 f0       	push   $0xf0105e6c
f01000ca:	e8 af 35 00 00       	call   f010367e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 b1 12 00 00       	call   f0101385 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 0f 2e 00 00       	call   f0102ee8 <env_init>
	trap_init();
f01000d9:	e8 95 36 00 00       	call   f0103773 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 6d 53 00 00       	call   f0105450 <mp_init>
	lapic_init();
f01000e3:	e8 8d 56 00 00       	call   f0105775 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 b8 34 00 00       	call   f01035a5 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 cf 58 00 00       	call   f01059c8 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ee 22 f0 07 	cmpl   $0x7,0xf022ee88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 24 5e 10 f0       	push   $0xf0105e24
f010010f:	6a 56                	push   $0x56
f0100111:	68 87 5e 10 f0       	push   $0xf0105e87
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 b6 53 10 f0       	mov    $0xf01053b6,%eax
f0100123:	2d 3c 53 10 f0       	sub    $0xf010533c,%eax
f0100128:	50                   	push   %eax
f0100129:	68 3c 53 10 f0       	push   $0xf010533c
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 4f 50 00 00       	call   f0105187 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 f0 22 f0       	mov    $0xf022f020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 13 56 00 00       	call   f010575a <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 f0 22 f0       	sub    $0xf022f020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 80 23 f0       	add    $0xf0238000,%eax
f010016b:	a3 84 ee 22 f0       	mov    %eax,0xf022ee84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 42 57 00 00       	call   f01058c3 <lapic_startap>
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
f010018f:	6b 05 c4 f3 22 f0 74 	imul   $0x74,0xf022f3c4,%eax
f0100196:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 1c f7 1f f0       	push   $0xf01ff71c
f01001a9:	e8 07 2f 00 00       	call   f01030b5 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 8c 3f 00 00       	call   f010413f <sched_yield>

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
f01001b9:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 48 5e 10 f0       	push   $0xf0105e48
f01001cb:	6a 6d                	push   $0x6d
f01001cd:	68 87 5e 10 f0       	push   $0xf0105e87
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 76 55 00 00       	call   f010575a <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 93 5e 10 f0       	push   $0xf0105e93
f01001ed:	e8 8c 34 00 00       	call   f010367e <cprintf>

	lapic_init();
f01001f2:	e8 7e 55 00 00       	call   f0105775 <lapic_init>
	env_init_percpu();
f01001f7:	e8 bc 2c 00 00       	call   f0102eb8 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 91 34 00 00       	call   f0103692 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 54 55 00 00       	call   f010575a <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 f0 22 f0    	add    $0xf022f020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010021f:	e8 a4 57 00 00       	call   f01059c8 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100224:	e8 16 3f 00 00       	call   f010413f <sched_yield>

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
f0100239:	68 a9 5e 10 f0       	push   $0xf0105ea9
f010023e:	e8 3b 34 00 00       	call   f010367e <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 09 34 00 00       	call   f0103658 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 bc 61 10 f0 	movl   $0xf01061bc,(%esp)
f0100256:	e8 23 34 00 00       	call   f010367e <cprintf>
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
f0100291:	8b 0d 24 e2 22 f0    	mov    0xf022e224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 e2 22 f0    	mov    %edx,0xf022e224
f01002a0:	88 81 20 e0 22 f0    	mov    %al,-0xfdd1fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 e2 22 f0 00 	movl   $0x0,0xf022e224
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
f01002e7:	83 0d 00 e0 22 f0 40 	orl    $0x40,0xf022e000
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
f01002ff:	8b 0d 00 e0 22 f0    	mov    0xf022e000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 20 60 10 f0 	movzbl -0xfef9fe0(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 e0 22 f0       	mov    %eax,0xf022e000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 e0 22 f0    	mov    0xf022e000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 e0 22 f0    	mov    %ecx,0xf022e000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 20 60 10 f0 	movzbl -0xfef9fe0(%edx),%eax
f0100358:	0b 05 00 e0 22 f0    	or     0xf022e000,%eax
f010035e:	0f b6 8a 20 5f 10 f0 	movzbl -0xfefa0e0(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 e0 22 f0       	mov    %eax,0xf022e000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d 00 5f 10 f0 	mov    -0xfefa100(,%ecx,4),%ecx
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
f01003af:	68 c3 5e 10 f0       	push   $0xf0105ec3
f01003b4:	e8 c5 32 00 00       	call   f010367e <cprintf>
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
f010049b:	0f b7 05 28 e2 22 f0 	movzwl 0xf022e228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 e2 22 f0    	mov    %ax,0xf022e228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c e2 22 f0    	mov    0xf022e22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 e2 22 f0 	addw   $0x50,0xf022e228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 e2 22 f0 	movzwl 0xf022e228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 e2 22 f0    	mov    %ax,0xf022e228
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
f0100525:	0f b7 05 28 e2 22 f0 	movzwl 0xf022e228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 e2 22 f0 	mov    %dx,0xf022e228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c e2 22 f0    	mov    0xf022e22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 e2 22 f0 	cmpw   $0x7cf,0xf022e228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c e2 22 f0       	mov    0xf022e22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 1f 4c 00 00       	call   f0105187 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c e2 22 f0    	mov    0xf022e22c,%edx
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
f0100589:	66 83 2d 28 e2 22 f0 	subw   $0x50,0xf022e228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 e2 22 f0    	mov    0xf022e230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 e2 22 f0 	movzwl 0xf022e228,%ebx
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
f01005c7:	80 3d 34 e2 22 f0 00 	cmpb   $0x0,0xf022e234
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
f0100605:	a1 20 e2 22 f0       	mov    0xf022e220,%eax
f010060a:	3b 05 24 e2 22 f0    	cmp    0xf022e224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 e2 22 f0    	mov    %edx,0xf022e220
f010061b:	0f b6 88 20 e0 22 f0 	movzbl -0xfdd1fe0(%eax),%ecx
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
f010062c:	c7 05 20 e2 22 f0 00 	movl   $0x0,0xf022e220
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
f0100665:	c7 05 30 e2 22 f0 b4 	movl   $0x3b4,0xf022e230
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
f010067d:	c7 05 30 e2 22 f0 d4 	movl   $0x3d4,0xf022e230
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
f010068c:	8b 3d 30 e2 22 f0    	mov    0xf022e230,%edi
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
f01006b1:	89 35 2c e2 22 f0    	mov    %esi,0xf022e22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 e2 22 f0    	mov    %ax,0xf022e228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 51 2e 00 00       	call   f010352d <irq_setmask_8259A>
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
f010073a:	0f 95 05 34 e2 22 f0 	setne  0xf022e234
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
f010074f:	68 cf 5e 10 f0       	push   $0xf0105ecf
f0100754:	e8 25 2f 00 00       	call   f010367e <cprintf>
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
f0100795:	68 20 61 10 f0       	push   $0xf0106120
f010079a:	68 3e 61 10 f0       	push   $0xf010613e
f010079f:	68 43 61 10 f0       	push   $0xf0106143
f01007a4:	e8 d5 2e 00 00       	call   f010367e <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 fc 61 10 f0       	push   $0xf01061fc
f01007b1:	68 4c 61 10 f0       	push   $0xf010614c
f01007b6:	68 43 61 10 f0       	push   $0xf0106143
f01007bb:	e8 be 2e 00 00       	call   f010367e <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	68 24 62 10 f0       	push   $0xf0106224
f01007c8:	68 55 61 10 f0       	push   $0xf0106155
f01007cd:	68 43 61 10 f0       	push   $0xf0106143
f01007d2:	e8 a7 2e 00 00       	call   f010367e <cprintf>
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
f01007e4:	68 5f 61 10 f0       	push   $0xf010615f
f01007e9:	e8 90 2e 00 00       	call   f010367e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ee:	83 c4 08             	add    $0x8,%esp
f01007f1:	68 0c 00 10 00       	push   $0x10000c
f01007f6:	68 50 62 10 f0       	push   $0xf0106250
f01007fb:	e8 7e 2e 00 00       	call   f010367e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 0c 00 10 00       	push   $0x10000c
f0100808:	68 0c 00 10 f0       	push   $0xf010000c
f010080d:	68 78 62 10 f0       	push   $0xf0106278
f0100812:	e8 67 2e 00 00       	call   f010367e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 e1 5d 10 00       	push   $0x105de1
f010081f:	68 e1 5d 10 f0       	push   $0xf0105de1
f0100824:	68 9c 62 10 f0       	push   $0xf010629c
f0100829:	e8 50 2e 00 00       	call   f010367e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 10 d9 22 00       	push   $0x22d910
f0100836:	68 10 d9 22 f0       	push   $0xf022d910
f010083b:	68 c0 62 10 f0       	push   $0xf01062c0
f0100840:	e8 39 2e 00 00       	call   f010367e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100845:	83 c4 0c             	add    $0xc,%esp
f0100848:	68 08 00 27 00       	push   $0x270008
f010084d:	68 08 00 27 f0       	push   $0xf0270008
f0100852:	68 e4 62 10 f0       	push   $0xf01062e4
f0100857:	e8 22 2e 00 00       	call   f010367e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010085c:	b8 07 04 27 f0       	mov    $0xf0270407,%eax
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
f010087d:	68 08 63 10 f0       	push   $0xf0106308
f0100882:	e8 f7 2d 00 00       	call   f010367e <cprintf>
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
f0100899:	68 78 61 10 f0       	push   $0xf0106178
f010089e:	e8 db 2d 00 00       	call   f010367e <cprintf>
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
f01008b6:	68 8b 61 10 f0       	push   $0xf010618b
f01008bb:	e8 be 2d 00 00       	call   f010367e <cprintf>
		cprintf("%08x ", *(ebp+2));
f01008c0:	83 c4 08             	add    $0x8,%esp
f01008c3:	ff 73 08             	pushl  0x8(%ebx)
f01008c6:	68 a5 61 10 f0       	push   $0xf01061a5
f01008cb:	e8 ae 2d 00 00       	call   f010367e <cprintf>
		cprintf("%08x ", *(ebp+3));
f01008d0:	83 c4 08             	add    $0x8,%esp
f01008d3:	ff 73 0c             	pushl  0xc(%ebx)
f01008d6:	68 a5 61 10 f0       	push   $0xf01061a5
f01008db:	e8 9e 2d 00 00       	call   f010367e <cprintf>
		cprintf("%08x ", *(ebp+4));
f01008e0:	83 c4 08             	add    $0x8,%esp
f01008e3:	ff 73 10             	pushl  0x10(%ebx)
f01008e6:	68 a5 61 10 f0       	push   $0xf01061a5
f01008eb:	e8 8e 2d 00 00       	call   f010367e <cprintf>
		cprintf("%08x ", *(ebp+5));
f01008f0:	83 c4 08             	add    $0x8,%esp
f01008f3:	ff 73 14             	pushl  0x14(%ebx)
f01008f6:	68 a5 61 10 f0       	push   $0xf01061a5
f01008fb:	e8 7e 2d 00 00       	call   f010367e <cprintf>
		cprintf("%08x", *(ebp+6));
f0100900:	83 c4 08             	add    $0x8,%esp
f0100903:	ff 73 18             	pushl  0x18(%ebx)
f0100906:	68 42 72 10 f0       	push   $0xf0107242
f010090b:	e8 6e 2d 00 00       	call   f010367e <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f0100910:	83 c4 08             	add    $0x8,%esp
f0100913:	57                   	push   %edi
f0100914:	56                   	push   %esi
f0100915:	e8 ae 3d 00 00       	call   f01046c8 <debuginfo_eip>
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
f0100934:	68 ab 61 10 f0       	push   $0xf01061ab
f0100939:	e8 40 2d 00 00       	call   f010367e <cprintf>
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
f0100961:	68 34 63 10 f0       	push   $0xf0106334
f0100966:	e8 13 2d 00 00       	call   f010367e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010096b:	c7 04 24 58 63 10 f0 	movl   $0xf0106358,(%esp)
f0100972:	e8 07 2d 00 00       	call   f010367e <cprintf>

	if (tf != NULL)
f0100977:	83 c4 10             	add    $0x10,%esp
f010097a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010097e:	74 0e                	je     f010098e <monitor+0x36>
		print_trapframe(tf);
f0100980:	83 ec 0c             	sub    $0xc,%esp
f0100983:	ff 75 08             	pushl  0x8(%ebp)
f0100986:	e8 b4 31 00 00       	call   f0103b3f <print_trapframe>
f010098b:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010098e:	83 ec 0c             	sub    $0xc,%esp
f0100991:	68 be 61 10 f0       	push   $0xf01061be
f0100996:	e8 48 45 00 00       	call   f0104ee3 <readline>
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
f01009ca:	68 c2 61 10 f0       	push   $0xf01061c2
f01009cf:	e8 29 47 00 00       	call   f01050fd <strchr>
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
f01009ea:	68 c7 61 10 f0       	push   $0xf01061c7
f01009ef:	e8 8a 2c 00 00       	call   f010367e <cprintf>
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
f0100a13:	68 c2 61 10 f0       	push   $0xf01061c2
f0100a18:	e8 e0 46 00 00       	call   f01050fd <strchr>
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
f0100a41:	ff 34 85 80 63 10 f0 	pushl  -0xfef9c80(,%eax,4)
f0100a48:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a4b:	e8 4f 46 00 00       	call   f010509f <strcmp>
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
f0100a65:	ff 14 85 88 63 10 f0 	call   *-0xfef9c78(,%eax,4)
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
f0100a86:	68 e4 61 10 f0       	push   $0xf01061e4
f0100a8b:	e8 ee 2b 00 00       	call   f010367e <cprintf>
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
f0100aab:	e8 4f 2a 00 00       	call   f01034ff <mc146818_read>
f0100ab0:	89 c6                	mov    %eax,%esi
f0100ab2:	83 c3 01             	add    $0x1,%ebx
f0100ab5:	89 1c 24             	mov    %ebx,(%esp)
f0100ab8:	e8 42 2a 00 00       	call   f01034ff <mc146818_read>
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
f0100adf:	3b 0d 88 ee 22 f0    	cmp    0xf022ee88,%ecx
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
f0100aee:	68 24 5e 10 f0       	push   $0xf0105e24
f0100af3:	68 c5 03 00 00       	push   $0x3c5
f0100af8:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0100b33:	83 3d 38 e2 22 f0 00 	cmpl   $0x0,0xf022e238
f0100b3a:	75 11                	jne    f0100b4d <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b3c:	ba 07 10 27 f0       	mov    $0xf0271007,%edx
f0100b41:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b47:	89 15 38 e2 22 f0    	mov    %edx,0xf022e238
	//
	// LAB 2: Your code here.
	if(n < 0) 
		panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) 
f0100b4d:	85 c0                	test   %eax,%eax
f0100b4f:	75 07                	jne    f0100b58 <boot_alloc+0x2b>
		return nextfree;
f0100b51:	a1 38 e2 22 f0       	mov    0xf022e238,%eax
f0100b56:	eb 54                	jmp    f0100bac <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f0100b58:	8b 15 38 e2 22 f0    	mov    0xf022e238,%edx

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
f0100b72:	68 48 5e 10 f0       	push   $0xf0105e48
f0100b77:	6a 78                	push   $0x78
f0100b79:	68 45 6d 10 f0       	push   $0xf0106d45
f0100b7e:	e8 bd f4 ff ff       	call   f0100040 <_panic>

		if(PADDR(new) > 1024*1024*4) 
f0100b83:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100b89:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100b8f:	76 14                	jbe    f0100ba5 <boot_alloc+0x78>
			panic("boot_alloc: not enough memory!\n");
f0100b91:	83 ec 04             	sub    $0x4,%esp
f0100b94:	68 a4 63 10 f0       	push   $0xf01063a4
f0100b99:	6a 79                	push   $0x79
f0100b9b:	68 45 6d 10 f0       	push   $0xf0106d45
f0100ba0:	e8 9b f4 ff ff       	call   f0100040 <_panic>

		else
		{
			nextfree = new;
f0100ba5:	a3 38 e2 22 f0       	mov    %eax,0xf022e238
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
f0100bc7:	68 c4 63 10 f0       	push   $0xf01063c4
f0100bcc:	68 f8 02 00 00       	push   $0x2f8
f0100bd1:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0100be9:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
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
f0100c1f:	a3 40 e2 22 f0       	mov    %eax,0xf022e240
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
f0100c29:	8b 1d 40 e2 22 f0    	mov    0xf022e240,%ebx
f0100c2f:	eb 53                	jmp    f0100c84 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c31:	89 d8                	mov    %ebx,%eax
f0100c33:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0100c4d:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0100c53:	72 12                	jb     f0100c67 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c55:	50                   	push   %eax
f0100c56:	68 24 5e 10 f0       	push   $0xf0105e24
f0100c5b:	6a 58                	push   $0x58
f0100c5d:	68 51 6d 10 f0       	push   $0xf0106d51
f0100c62:	e8 d9 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c67:	83 ec 04             	sub    $0x4,%esp
f0100c6a:	68 80 00 00 00       	push   $0x80
f0100c6f:	68 97 00 00 00       	push   $0x97
f0100c74:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c79:	50                   	push   %eax
f0100c7a:	e8 bb 44 00 00       	call   f010513a <memset>
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
f0100c95:	8b 15 40 e2 22 f0    	mov    0xf022e240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c9b:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
		assert(pp < pages + npages);
f0100ca1:	a1 88 ee 22 f0       	mov    0xf022ee88,%eax
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
f0100cc0:	68 5f 6d 10 f0       	push   $0xf0106d5f
f0100cc5:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100cca:	68 12 03 00 00       	push   $0x312
f0100ccf:	68 45 6d 10 f0       	push   $0xf0106d45
f0100cd4:	e8 67 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cd9:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cdc:	72 19                	jb     f0100cf7 <check_page_free_list+0x149>
f0100cde:	68 80 6d 10 f0       	push   $0xf0106d80
f0100ce3:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100ce8:	68 13 03 00 00       	push   $0x313
f0100ced:	68 45 6d 10 f0       	push   $0xf0106d45
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cf7:	89 d0                	mov    %edx,%eax
f0100cf9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100cfc:	a8 07                	test   $0x7,%al
f0100cfe:	74 19                	je     f0100d19 <check_page_free_list+0x16b>
f0100d00:	68 e8 63 10 f0       	push   $0xf01063e8
f0100d05:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100d0a:	68 14 03 00 00       	push   $0x314
f0100d0f:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0100d23:	68 94 6d 10 f0       	push   $0xf0106d94
f0100d28:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100d2d:	68 17 03 00 00       	push   $0x317
f0100d32:	68 45 6d 10 f0       	push   $0xf0106d45
f0100d37:	e8 04 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d3c:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d41:	75 19                	jne    f0100d5c <check_page_free_list+0x1ae>
f0100d43:	68 a5 6d 10 f0       	push   $0xf0106da5
f0100d48:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100d4d:	68 18 03 00 00       	push   $0x318
f0100d52:	68 45 6d 10 f0       	push   $0xf0106d45
f0100d57:	e8 e4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d5c:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d61:	75 19                	jne    f0100d7c <check_page_free_list+0x1ce>
f0100d63:	68 1c 64 10 f0       	push   $0xf010641c
f0100d68:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100d6d:	68 19 03 00 00       	push   $0x319
f0100d72:	68 45 6d 10 f0       	push   $0xf0106d45
f0100d77:	e8 c4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d7c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d81:	75 19                	jne    f0100d9c <check_page_free_list+0x1ee>
f0100d83:	68 be 6d 10 f0       	push   $0xf0106dbe
f0100d88:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100d8d:	68 1a 03 00 00       	push   $0x31a
f0100d92:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0100db2:	68 24 5e 10 f0       	push   $0xf0105e24
f0100db7:	6a 58                	push   $0x58
f0100db9:	68 51 6d 10 f0       	push   $0xf0106d51
f0100dbe:	e8 7d f2 ff ff       	call   f0100040 <_panic>
f0100dc3:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100dc9:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100dcc:	0f 86 b6 00 00 00    	jbe    f0100e88 <check_page_free_list+0x2da>
f0100dd2:	68 40 64 10 f0       	push   $0xf0106440
f0100dd7:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100ddc:	68 1b 03 00 00       	push   $0x31b
f0100de1:	68 45 6d 10 f0       	push   $0xf0106d45
f0100de6:	e8 55 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100deb:	68 d8 6d 10 f0       	push   $0xf0106dd8
f0100df0:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100df5:	68 1d 03 00 00       	push   $0x31d
f0100dfa:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0100e1a:	68 f5 6d 10 f0       	push   $0xf0106df5
f0100e1f:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100e24:	68 25 03 00 00       	push   $0x325
f0100e29:	68 45 6d 10 f0       	push   $0xf0106d45
f0100e2e:	e8 0d f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e33:	85 db                	test   %ebx,%ebx
f0100e35:	7f 19                	jg     f0100e50 <check_page_free_list+0x2a2>
f0100e37:	68 07 6e 10 f0       	push   $0xf0106e07
f0100e3c:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0100e41:	68 26 03 00 00       	push   $0x326
f0100e46:	68 45 6d 10 f0       	push   $0xf0106d45
f0100e4b:	e8 f0 f1 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e50:	83 ec 0c             	sub    $0xc,%esp
f0100e53:	68 88 64 10 f0       	push   $0xf0106488
f0100e58:	e8 21 28 00 00       	call   f010367e <cprintf>
}
f0100e5d:	eb 49                	jmp    f0100ea8 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e5f:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
f0100e64:	85 c0                	test   %eax,%eax
f0100e66:	0f 85 6f fd ff ff    	jne    f0100bdb <check_page_free_list+0x2d>
f0100e6c:	e9 53 fd ff ff       	jmp    f0100bc4 <check_page_free_list+0x16>
f0100e71:	83 3d 40 e2 22 f0 00 	cmpl   $0x0,0xf022e240
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
f0100eb9:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
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
f0100ee7:	03 05 90 ee 22 f0    	add    0xf022ee90,%eax
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
f0100f18:	68 48 5e 10 f0       	push   $0xf0105e48
f0100f1d:	68 5a 01 00 00       	push   $0x15a
f0100f22:	68 45 6d 10 f0       	push   $0xf0106d45
f0100f27:	e8 14 f1 ff ff       	call   f0100040 <_panic>
f0100f2c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f31:	39 d8                	cmp    %ebx,%eax
f0100f33:	76 16                	jbe    f0100f4b <page_init+0x9b>
		{
			pages[i].pp_ref = 1;
f0100f35:	89 f0                	mov    %esi,%eax
f0100f37:	03 05 90 ee 22 f0    	add    0xf022ee90,%eax
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
f0100f5a:	03 05 90 ee 22 f0    	add    0xf022ee90,%eax
f0100f60:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f66:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100f6c:	eb 23                	jmp    f0100f91 <page_init+0xe1>
		}
			
		pages[i].pp_ref = 0;  
f0100f6e:	89 f0                	mov    %esi,%eax
f0100f70:	03 05 90 ee 22 f0    	add    0xf022ee90,%eax
f0100f76:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100f7c:	8b 15 40 e2 22 f0    	mov    0xf022e240,%edx
f0100f82:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100f84:	89 f0                	mov    %esi,%eax
f0100f86:	03 05 90 ee 22 f0    	add    0xf022ee90,%eax
f0100f8c:	a3 40 e2 22 f0       	mov    %eax,0xf022e240
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;	

	for (i = 1; i < npages; ++i) 
f0100f91:	83 c7 01             	add    $0x1,%edi
f0100f94:	83 c6 08             	add    $0x8,%esi
f0100f97:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f9d:	3b 3d 88 ee 22 f0    	cmp    0xf022ee88,%edi
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
f0100fb8:	8b 1d 40 e2 22 f0    	mov    0xf022e240,%ebx
f0100fbe:	85 db                	test   %ebx,%ebx
f0100fc0:	74 58                	je     f010101a <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100fc2:	8b 03                	mov    (%ebx),%eax
f0100fc4:	a3 40 e2 22 f0       	mov    %eax,0xf022e240

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
f0100fd7:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0100fdd:	c1 f8 03             	sar    $0x3,%eax
f0100fe0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe3:	89 c2                	mov    %eax,%edx
f0100fe5:	c1 ea 0c             	shr    $0xc,%edx
f0100fe8:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0100fee:	72 12                	jb     f0101002 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff0:	50                   	push   %eax
f0100ff1:	68 24 5e 10 f0       	push   $0xf0105e24
f0100ff6:	6a 58                	push   $0x58
f0100ff8:	68 51 6d 10 f0       	push   $0xf0106d51
f0100ffd:	e8 3e f0 ff ff       	call   f0100040 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0101002:	83 ec 04             	sub    $0x4,%esp
f0101005:	68 00 10 00 00       	push   $0x1000
f010100a:	6a 00                	push   $0x0
f010100c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101011:	50                   	push   %eax
f0101012:	e8 23 41 00 00       	call   f010513a <memset>
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
f0101039:	68 ac 64 10 f0       	push   $0xf01064ac
f010103e:	68 9b 01 00 00       	push   $0x19b
f0101043:	68 45 6d 10 f0       	push   $0xf0106d45
f0101048:	e8 f3 ef ff ff       	call   f0100040 <_panic>

	
	pp->pp_link  = page_free_list;
f010104d:	8b 15 40 e2 22 f0    	mov    0xf022e240,%edx
f0101053:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;	
f0101055:	a3 40 e2 22 f0       	mov    %eax,0xf022e240
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
f01010cb:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f01010d1:	c1 fa 03             	sar    $0x3,%edx
f01010d4:	c1 e2 0c             	shl    $0xc,%edx
f01010d7:	83 ca 07             	or     $0x7,%edx
f01010da:	89 13                	mov    %edx,(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010dc:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f01010e2:	c1 f8 03             	sar    $0x3,%eax
f01010e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010e8:	89 c2                	mov    %eax,%edx
f01010ea:	c1 ea 0c             	shr    $0xc,%edx
f01010ed:	39 15 88 ee 22 f0    	cmp    %edx,0xf022ee88
f01010f3:	77 15                	ja     f010110a <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010f5:	50                   	push   %eax
f01010f6:	68 24 5e 10 f0       	push   $0xf0105e24
f01010fb:	68 dd 01 00 00       	push   $0x1dd
f0101100:	68 45 6d 10 f0       	push   $0xf0106d45
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
f010111b:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0101121:	72 15                	jb     f0101138 <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101123:	50                   	push   %eax
f0101124:	68 24 5e 10 f0       	push   $0xf0105e24
f0101129:	68 e1 01 00 00       	push   $0x1e1
f010112e:	68 45 6d 10 f0       	push   $0xf0106d45
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
f010119b:	68 e4 64 10 f0       	push   $0xf01064e4
f01011a0:	68 fe 01 00 00       	push   $0x1fe
f01011a5:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01011f5:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f01011fb:	72 14                	jb     f0101211 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01011fd:	83 ec 04             	sub    $0x4,%esp
f0101200:	68 14 65 10 f0       	push   $0xf0106514
f0101205:	6a 51                	push   $0x51
f0101207:	68 51 6d 10 f0       	push   $0xf0106d51
f010120c:	e8 2f ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101211:	8b 15 90 ee 22 f0    	mov    0xf022ee90,%edx
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
f010122c:	e8 29 45 00 00       	call   f010575a <cpunum>
f0101231:	6b c0 74             	imul   $0x74,%eax,%eax
f0101234:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f010123b:	74 16                	je     f0101253 <tlb_invalidate+0x2d>
f010123d:	e8 18 45 00 00       	call   f010575a <cpunum>
f0101242:	6b c0 74             	imul   $0x74,%eax,%eax
f0101245:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
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
f01012f8:	2b 1d 90 ee 22 f0    	sub    0xf022ee90,%ebx
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
f0101338:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f010133e:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101341:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0101346:	76 17                	jbe    f010135f <mmio_map_region+0x3d>
		panic("mmio_map_region: Not enough memory!");
f0101348:	83 ec 04             	sub    $0x4,%esp
f010134b:	68 34 65 10 f0       	push   $0xf0106534
f0101350:	68 a4 02 00 00       	push   $0x2a4
f0101355:	68 45 6d 10 f0       	push   $0xf0106d45
f010135a:	e8 e1 ec ff ff       	call   f0100040 <_panic>
	
	boot_map_region(kern_pgdir, base, size, pa, (PTE_PCD | PTE_PWT | PTE_W));
f010135f:	83 ec 08             	sub    $0x8,%esp
f0101362:	6a 1a                	push   $0x1a
f0101364:	ff 75 08             	pushl  0x8(%ebp)
f0101367:	89 d9                	mov    %ebx,%ecx
f0101369:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f010136e:	e8 e2 fd ff ff       	call   f0101155 <boot_map_region>

	base += size;
f0101373:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f0101378:	01 c3                	add    %eax,%ebx
f010137a:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300

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
f01013ce:	89 15 88 ee 22 f0    	mov    %edx,0xf022ee88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d4:	89 c2                	mov    %eax,%edx
f01013d6:	29 da                	sub    %ebx,%edx
f01013d8:	52                   	push   %edx
f01013d9:	53                   	push   %ebx
f01013da:	50                   	push   %eax
f01013db:	68 58 65 10 f0       	push   $0xf0106558
f01013e0:	e8 99 22 00 00       	call   f010367e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013e5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013ea:	e8 3e f7 ff ff       	call   f0100b2d <boot_alloc>
f01013ef:	a3 8c ee 22 f0       	mov    %eax,0xf022ee8c
	memset(kern_pgdir, 0, PGSIZE);
f01013f4:	83 c4 0c             	add    $0xc,%esp
f01013f7:	68 00 10 00 00       	push   $0x1000
f01013fc:	6a 00                	push   $0x0
f01013fe:	50                   	push   %eax
f01013ff:	e8 36 3d 00 00       	call   f010513a <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101404:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f0101414:	68 48 5e 10 f0       	push   $0xf0105e48
f0101419:	68 a5 00 00 00       	push   $0xa5
f010141e:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101437:	a1 88 ee 22 f0       	mov    0xf022ee88,%eax
f010143c:	c1 e0 03             	shl    $0x3,%eax
f010143f:	e8 e9 f6 ff ff       	call   f0100b2d <boot_alloc>
f0101444:	a3 90 ee 22 f0       	mov    %eax,0xf022ee90
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f0101449:	83 ec 04             	sub    $0x4,%esp
f010144c:	8b 0d 88 ee 22 f0    	mov    0xf022ee88,%ecx
f0101452:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101459:	52                   	push   %edx
f010145a:	6a 00                	push   $0x0
f010145c:	50                   	push   %eax
f010145d:	e8 d8 3c 00 00       	call   f010513a <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f0101462:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101467:	e8 c1 f6 ff ff       	call   f0100b2d <boot_alloc>
f010146c:	a3 44 e2 22 f0       	mov    %eax,0xf022e244
	memset(envs, '\0', sizeof(struct Env) * NENV);
f0101471:	83 c4 0c             	add    $0xc,%esp
f0101474:	68 00 f0 01 00       	push   $0x1f000
f0101479:	6a 00                	push   $0x0
f010147b:	50                   	push   %eax
f010147c:	e8 b9 3c 00 00       	call   f010513a <memset>
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
f0101493:	83 3d 90 ee 22 f0 00 	cmpl   $0x0,0xf022ee90
f010149a:	75 17                	jne    f01014b3 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f010149c:	83 ec 04             	sub    $0x4,%esp
f010149f:	68 18 6e 10 f0       	push   $0xf0106e18
f01014a4:	68 39 03 00 00       	push   $0x339
f01014a9:	68 45 6d 10 f0       	push   $0xf0106d45
f01014ae:	e8 8d eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014b3:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
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
f01014db:	68 33 6e 10 f0       	push   $0xf0106e33
f01014e0:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01014e5:	68 41 03 00 00       	push   $0x341
f01014ea:	68 45 6d 10 f0       	push   $0xf0106d45
f01014ef:	e8 4c eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01014f4:	83 ec 0c             	sub    $0xc,%esp
f01014f7:	6a 00                	push   $0x0
f01014f9:	e8 b3 fa ff ff       	call   f0100fb1 <page_alloc>
f01014fe:	89 c6                	mov    %eax,%esi
f0101500:	83 c4 10             	add    $0x10,%esp
f0101503:	85 c0                	test   %eax,%eax
f0101505:	75 19                	jne    f0101520 <mem_init+0x19b>
f0101507:	68 49 6e 10 f0       	push   $0xf0106e49
f010150c:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101511:	68 42 03 00 00       	push   $0x342
f0101516:	68 45 6d 10 f0       	push   $0xf0106d45
f010151b:	e8 20 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101520:	83 ec 0c             	sub    $0xc,%esp
f0101523:	6a 00                	push   $0x0
f0101525:	e8 87 fa ff ff       	call   f0100fb1 <page_alloc>
f010152a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010152d:	83 c4 10             	add    $0x10,%esp
f0101530:	85 c0                	test   %eax,%eax
f0101532:	75 19                	jne    f010154d <mem_init+0x1c8>
f0101534:	68 5f 6e 10 f0       	push   $0xf0106e5f
f0101539:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010153e:	68 43 03 00 00       	push   $0x343
f0101543:	68 45 6d 10 f0       	push   $0xf0106d45
f0101548:	e8 f3 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010154d:	39 f7                	cmp    %esi,%edi
f010154f:	75 19                	jne    f010156a <mem_init+0x1e5>
f0101551:	68 75 6e 10 f0       	push   $0xf0106e75
f0101556:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010155b:	68 46 03 00 00       	push   $0x346
f0101560:	68 45 6d 10 f0       	push   $0xf0106d45
f0101565:	e8 d6 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010156a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010156d:	39 c6                	cmp    %eax,%esi
f010156f:	74 04                	je     f0101575 <mem_init+0x1f0>
f0101571:	39 c7                	cmp    %eax,%edi
f0101573:	75 19                	jne    f010158e <mem_init+0x209>
f0101575:	68 94 65 10 f0       	push   $0xf0106594
f010157a:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010157f:	68 47 03 00 00       	push   $0x347
f0101584:	68 45 6d 10 f0       	push   $0xf0106d45
f0101589:	e8 b2 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010158e:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101594:	8b 15 88 ee 22 f0    	mov    0xf022ee88,%edx
f010159a:	c1 e2 0c             	shl    $0xc,%edx
f010159d:	89 f8                	mov    %edi,%eax
f010159f:	29 c8                	sub    %ecx,%eax
f01015a1:	c1 f8 03             	sar    $0x3,%eax
f01015a4:	c1 e0 0c             	shl    $0xc,%eax
f01015a7:	39 d0                	cmp    %edx,%eax
f01015a9:	72 19                	jb     f01015c4 <mem_init+0x23f>
f01015ab:	68 87 6e 10 f0       	push   $0xf0106e87
f01015b0:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01015b5:	68 48 03 00 00       	push   $0x348
f01015ba:	68 45 6d 10 f0       	push   $0xf0106d45
f01015bf:	e8 7c ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01015c4:	89 f0                	mov    %esi,%eax
f01015c6:	29 c8                	sub    %ecx,%eax
f01015c8:	c1 f8 03             	sar    $0x3,%eax
f01015cb:	c1 e0 0c             	shl    $0xc,%eax
f01015ce:	39 c2                	cmp    %eax,%edx
f01015d0:	77 19                	ja     f01015eb <mem_init+0x266>
f01015d2:	68 a4 6e 10 f0       	push   $0xf0106ea4
f01015d7:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01015dc:	68 49 03 00 00       	push   $0x349
f01015e1:	68 45 6d 10 f0       	push   $0xf0106d45
f01015e6:	e8 55 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015eb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ee:	29 c8                	sub    %ecx,%eax
f01015f0:	c1 f8 03             	sar    $0x3,%eax
f01015f3:	c1 e0 0c             	shl    $0xc,%eax
f01015f6:	39 c2                	cmp    %eax,%edx
f01015f8:	77 19                	ja     f0101613 <mem_init+0x28e>
f01015fa:	68 c1 6e 10 f0       	push   $0xf0106ec1
f01015ff:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101604:	68 4a 03 00 00       	push   $0x34a
f0101609:	68 45 6d 10 f0       	push   $0xf0106d45
f010160e:	e8 2d ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101613:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
f0101618:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010161b:	c7 05 40 e2 22 f0 00 	movl   $0x0,0xf022e240
f0101622:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 82 f9 ff ff       	call   f0100fb1 <page_alloc>
f010162f:	83 c4 10             	add    $0x10,%esp
f0101632:	85 c0                	test   %eax,%eax
f0101634:	74 19                	je     f010164f <mem_init+0x2ca>
f0101636:	68 de 6e 10 f0       	push   $0xf0106ede
f010163b:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101640:	68 51 03 00 00       	push   $0x351
f0101645:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101680:	68 33 6e 10 f0       	push   $0xf0106e33
f0101685:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010168a:	68 58 03 00 00       	push   $0x358
f010168f:	68 45 6d 10 f0       	push   $0xf0106d45
f0101694:	e8 a7 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101699:	83 ec 0c             	sub    $0xc,%esp
f010169c:	6a 00                	push   $0x0
f010169e:	e8 0e f9 ff ff       	call   f0100fb1 <page_alloc>
f01016a3:	89 c7                	mov    %eax,%edi
f01016a5:	83 c4 10             	add    $0x10,%esp
f01016a8:	85 c0                	test   %eax,%eax
f01016aa:	75 19                	jne    f01016c5 <mem_init+0x340>
f01016ac:	68 49 6e 10 f0       	push   $0xf0106e49
f01016b1:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01016b6:	68 59 03 00 00       	push   $0x359
f01016bb:	68 45 6d 10 f0       	push   $0xf0106d45
f01016c0:	e8 7b e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016c5:	83 ec 0c             	sub    $0xc,%esp
f01016c8:	6a 00                	push   $0x0
f01016ca:	e8 e2 f8 ff ff       	call   f0100fb1 <page_alloc>
f01016cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016d2:	83 c4 10             	add    $0x10,%esp
f01016d5:	85 c0                	test   %eax,%eax
f01016d7:	75 19                	jne    f01016f2 <mem_init+0x36d>
f01016d9:	68 5f 6e 10 f0       	push   $0xf0106e5f
f01016de:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01016e3:	68 5a 03 00 00       	push   $0x35a
f01016e8:	68 45 6d 10 f0       	push   $0xf0106d45
f01016ed:	e8 4e e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016f2:	39 fe                	cmp    %edi,%esi
f01016f4:	75 19                	jne    f010170f <mem_init+0x38a>
f01016f6:	68 75 6e 10 f0       	push   $0xf0106e75
f01016fb:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101700:	68 5c 03 00 00       	push   $0x35c
f0101705:	68 45 6d 10 f0       	push   $0xf0106d45
f010170a:	e8 31 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010170f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101712:	39 c7                	cmp    %eax,%edi
f0101714:	74 04                	je     f010171a <mem_init+0x395>
f0101716:	39 c6                	cmp    %eax,%esi
f0101718:	75 19                	jne    f0101733 <mem_init+0x3ae>
f010171a:	68 94 65 10 f0       	push   $0xf0106594
f010171f:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101724:	68 5d 03 00 00       	push   $0x35d
f0101729:	68 45 6d 10 f0       	push   $0xf0106d45
f010172e:	e8 0d e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101733:	83 ec 0c             	sub    $0xc,%esp
f0101736:	6a 00                	push   $0x0
f0101738:	e8 74 f8 ff ff       	call   f0100fb1 <page_alloc>
f010173d:	83 c4 10             	add    $0x10,%esp
f0101740:	85 c0                	test   %eax,%eax
f0101742:	74 19                	je     f010175d <mem_init+0x3d8>
f0101744:	68 de 6e 10 f0       	push   $0xf0106ede
f0101749:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010174e:	68 5e 03 00 00       	push   $0x35e
f0101753:	68 45 6d 10 f0       	push   $0xf0106d45
f0101758:	e8 e3 e8 ff ff       	call   f0100040 <_panic>
f010175d:	89 f0                	mov    %esi,%eax
f010175f:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0101765:	c1 f8 03             	sar    $0x3,%eax
f0101768:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010176b:	89 c2                	mov    %eax,%edx
f010176d:	c1 ea 0c             	shr    $0xc,%edx
f0101770:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0101776:	72 12                	jb     f010178a <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101778:	50                   	push   %eax
f0101779:	68 24 5e 10 f0       	push   $0xf0105e24
f010177e:	6a 58                	push   $0x58
f0101780:	68 51 6d 10 f0       	push   $0xf0106d51
f0101785:	e8 b6 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010178a:	83 ec 04             	sub    $0x4,%esp
f010178d:	68 00 10 00 00       	push   $0x1000
f0101792:	6a 01                	push   $0x1
f0101794:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101799:	50                   	push   %eax
f010179a:	e8 9b 39 00 00       	call   f010513a <memset>
	page_free(pp0);
f010179f:	89 34 24             	mov    %esi,(%esp)
f01017a2:	e8 7a f8 ff ff       	call   f0101021 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017a7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017ae:	e8 fe f7 ff ff       	call   f0100fb1 <page_alloc>
f01017b3:	83 c4 10             	add    $0x10,%esp
f01017b6:	85 c0                	test   %eax,%eax
f01017b8:	75 19                	jne    f01017d3 <mem_init+0x44e>
f01017ba:	68 ed 6e 10 f0       	push   $0xf0106eed
f01017bf:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01017c4:	68 63 03 00 00       	push   $0x363
f01017c9:	68 45 6d 10 f0       	push   $0xf0106d45
f01017ce:	e8 6d e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01017d3:	39 c6                	cmp    %eax,%esi
f01017d5:	74 19                	je     f01017f0 <mem_init+0x46b>
f01017d7:	68 0b 6f 10 f0       	push   $0xf0106f0b
f01017dc:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01017e1:	68 64 03 00 00       	push   $0x364
f01017e6:	68 45 6d 10 f0       	push   $0xf0106d45
f01017eb:	e8 50 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017f0:	89 f0                	mov    %esi,%eax
f01017f2:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f01017f8:	c1 f8 03             	sar    $0x3,%eax
f01017fb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017fe:	89 c2                	mov    %eax,%edx
f0101800:	c1 ea 0c             	shr    $0xc,%edx
f0101803:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0101809:	72 12                	jb     f010181d <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010180b:	50                   	push   %eax
f010180c:	68 24 5e 10 f0       	push   $0xf0105e24
f0101811:	6a 58                	push   $0x58
f0101813:	68 51 6d 10 f0       	push   $0xf0106d51
f0101818:	e8 23 e8 ff ff       	call   f0100040 <_panic>
f010181d:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101823:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101829:	80 38 00             	cmpb   $0x0,(%eax)
f010182c:	74 19                	je     f0101847 <mem_init+0x4c2>
f010182e:	68 1b 6f 10 f0       	push   $0xf0106f1b
f0101833:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101838:	68 67 03 00 00       	push   $0x367
f010183d:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101851:	a3 40 e2 22 f0       	mov    %eax,0xf022e240

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
f0101872:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
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
f0101889:	68 25 6f 10 f0       	push   $0xf0106f25
f010188e:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101893:	68 74 03 00 00       	push   $0x374
f0101898:	68 45 6d 10 f0       	push   $0xf0106d45
f010189d:	e8 9e e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01018a2:	83 ec 0c             	sub    $0xc,%esp
f01018a5:	68 b4 65 10 f0       	push   $0xf01065b4
f01018aa:	e8 cf 1d 00 00       	call   f010367e <cprintf>
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
f01018c5:	68 33 6e 10 f0       	push   $0xf0106e33
f01018ca:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01018cf:	68 da 03 00 00       	push   $0x3da
f01018d4:	68 45 6d 10 f0       	push   $0xf0106d45
f01018d9:	e8 62 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018de:	83 ec 0c             	sub    $0xc,%esp
f01018e1:	6a 00                	push   $0x0
f01018e3:	e8 c9 f6 ff ff       	call   f0100fb1 <page_alloc>
f01018e8:	89 c3                	mov    %eax,%ebx
f01018ea:	83 c4 10             	add    $0x10,%esp
f01018ed:	85 c0                	test   %eax,%eax
f01018ef:	75 19                	jne    f010190a <mem_init+0x585>
f01018f1:	68 49 6e 10 f0       	push   $0xf0106e49
f01018f6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01018fb:	68 db 03 00 00       	push   $0x3db
f0101900:	68 45 6d 10 f0       	push   $0xf0106d45
f0101905:	e8 36 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010190a:	83 ec 0c             	sub    $0xc,%esp
f010190d:	6a 00                	push   $0x0
f010190f:	e8 9d f6 ff ff       	call   f0100fb1 <page_alloc>
f0101914:	89 c6                	mov    %eax,%esi
f0101916:	83 c4 10             	add    $0x10,%esp
f0101919:	85 c0                	test   %eax,%eax
f010191b:	75 19                	jne    f0101936 <mem_init+0x5b1>
f010191d:	68 5f 6e 10 f0       	push   $0xf0106e5f
f0101922:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101927:	68 dc 03 00 00       	push   $0x3dc
f010192c:	68 45 6d 10 f0       	push   $0xf0106d45
f0101931:	e8 0a e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101936:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101939:	75 19                	jne    f0101954 <mem_init+0x5cf>
f010193b:	68 75 6e 10 f0       	push   $0xf0106e75
f0101940:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101945:	68 df 03 00 00       	push   $0x3df
f010194a:	68 45 6d 10 f0       	push   $0xf0106d45
f010194f:	e8 ec e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101954:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101957:	74 04                	je     f010195d <mem_init+0x5d8>
f0101959:	39 c3                	cmp    %eax,%ebx
f010195b:	75 19                	jne    f0101976 <mem_init+0x5f1>
f010195d:	68 94 65 10 f0       	push   $0xf0106594
f0101962:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101967:	68 e0 03 00 00       	push   $0x3e0
f010196c:	68 45 6d 10 f0       	push   $0xf0106d45
f0101971:	e8 ca e6 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101976:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
f010197b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010197e:	c7 05 40 e2 22 f0 00 	movl   $0x0,0xf022e240
f0101985:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101988:	83 ec 0c             	sub    $0xc,%esp
f010198b:	6a 00                	push   $0x0
f010198d:	e8 1f f6 ff ff       	call   f0100fb1 <page_alloc>
f0101992:	83 c4 10             	add    $0x10,%esp
f0101995:	85 c0                	test   %eax,%eax
f0101997:	74 19                	je     f01019b2 <mem_init+0x62d>
f0101999:	68 de 6e 10 f0       	push   $0xf0106ede
f010199e:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01019a3:	68 e7 03 00 00       	push   $0x3e7
f01019a8:	68 45 6d 10 f0       	push   $0xf0106d45
f01019ad:	e8 8e e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019b2:	83 ec 04             	sub    $0x4,%esp
f01019b5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019b8:	50                   	push   %eax
f01019b9:	6a 00                	push   $0x0
f01019bb:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f01019c1:	e8 06 f8 ff ff       	call   f01011cc <page_lookup>
f01019c6:	83 c4 10             	add    $0x10,%esp
f01019c9:	85 c0                	test   %eax,%eax
f01019cb:	74 19                	je     f01019e6 <mem_init+0x661>
f01019cd:	68 d4 65 10 f0       	push   $0xf01065d4
f01019d2:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01019d7:	68 ea 03 00 00       	push   $0x3ea
f01019dc:	68 45 6d 10 f0       	push   $0xf0106d45
f01019e1:	e8 5a e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019e6:	6a 02                	push   $0x2
f01019e8:	6a 00                	push   $0x0
f01019ea:	53                   	push   %ebx
f01019eb:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f01019f1:	e8 ba f8 ff ff       	call   f01012b0 <page_insert>
f01019f6:	83 c4 10             	add    $0x10,%esp
f01019f9:	85 c0                	test   %eax,%eax
f01019fb:	78 19                	js     f0101a16 <mem_init+0x691>
f01019fd:	68 0c 66 10 f0       	push   $0xf010660c
f0101a02:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101a07:	68 ed 03 00 00       	push   $0x3ed
f0101a0c:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101a26:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101a2c:	e8 7f f8 ff ff       	call   f01012b0 <page_insert>
f0101a31:	83 c4 20             	add    $0x20,%esp
f0101a34:	85 c0                	test   %eax,%eax
f0101a36:	74 19                	je     f0101a51 <mem_init+0x6cc>
f0101a38:	68 3c 66 10 f0       	push   $0xf010663c
f0101a3d:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101a42:	68 f1 03 00 00       	push   $0x3f1
f0101a47:	68 45 6d 10 f0       	push   $0xf0106d45
f0101a4c:	e8 ef e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a51:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a57:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
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
f0101a78:	68 6c 66 10 f0       	push   $0xf010666c
f0101a7d:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101a82:	68 f2 03 00 00       	push   $0x3f2
f0101a87:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101aac:	68 94 66 10 f0       	push   $0xf0106694
f0101ab1:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101ab6:	68 f3 03 00 00       	push   $0x3f3
f0101abb:	68 45 6d 10 f0       	push   $0xf0106d45
f0101ac0:	e8 7b e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ac5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101aca:	74 19                	je     f0101ae5 <mem_init+0x760>
f0101acc:	68 30 6f 10 f0       	push   $0xf0106f30
f0101ad1:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101ad6:	68 f4 03 00 00       	push   $0x3f4
f0101adb:	68 45 6d 10 f0       	push   $0xf0106d45
f0101ae0:	e8 5b e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101ae5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aed:	74 19                	je     f0101b08 <mem_init+0x783>
f0101aef:	68 41 6f 10 f0       	push   $0xf0106f41
f0101af4:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101af9:	68 f5 03 00 00       	push   $0x3f5
f0101afe:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101b1d:	68 c4 66 10 f0       	push   $0xf01066c4
f0101b22:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101b27:	68 f8 03 00 00       	push   $0x3f8
f0101b2c:	68 45 6d 10 f0       	push   $0xf0106d45
f0101b31:	e8 0a e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b36:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b3b:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0101b40:	e8 84 ef ff ff       	call   f0100ac9 <check_va2pa>
f0101b45:	89 f2                	mov    %esi,%edx
f0101b47:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f0101b4d:	c1 fa 03             	sar    $0x3,%edx
f0101b50:	c1 e2 0c             	shl    $0xc,%edx
f0101b53:	39 d0                	cmp    %edx,%eax
f0101b55:	74 19                	je     f0101b70 <mem_init+0x7eb>
f0101b57:	68 00 67 10 f0       	push   $0xf0106700
f0101b5c:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101b61:	68 f9 03 00 00       	push   $0x3f9
f0101b66:	68 45 6d 10 f0       	push   $0xf0106d45
f0101b6b:	e8 d0 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b70:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b75:	74 19                	je     f0101b90 <mem_init+0x80b>
f0101b77:	68 52 6f 10 f0       	push   $0xf0106f52
f0101b7c:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101b81:	68 fa 03 00 00       	push   $0x3fa
f0101b86:	68 45 6d 10 f0       	push   $0xf0106d45
f0101b8b:	e8 b0 e4 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b90:	83 ec 0c             	sub    $0xc,%esp
f0101b93:	6a 00                	push   $0x0
f0101b95:	e8 17 f4 ff ff       	call   f0100fb1 <page_alloc>
f0101b9a:	83 c4 10             	add    $0x10,%esp
f0101b9d:	85 c0                	test   %eax,%eax
f0101b9f:	74 19                	je     f0101bba <mem_init+0x835>
f0101ba1:	68 de 6e 10 f0       	push   $0xf0106ede
f0101ba6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101bab:	68 fd 03 00 00       	push   $0x3fd
f0101bb0:	68 45 6d 10 f0       	push   $0xf0106d45
f0101bb5:	e8 86 e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bba:	6a 02                	push   $0x2
f0101bbc:	68 00 10 00 00       	push   $0x1000
f0101bc1:	56                   	push   %esi
f0101bc2:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101bc8:	e8 e3 f6 ff ff       	call   f01012b0 <page_insert>
f0101bcd:	83 c4 10             	add    $0x10,%esp
f0101bd0:	85 c0                	test   %eax,%eax
f0101bd2:	74 19                	je     f0101bed <mem_init+0x868>
f0101bd4:	68 c4 66 10 f0       	push   $0xf01066c4
f0101bd9:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101bde:	68 00 04 00 00       	push   $0x400
f0101be3:	68 45 6d 10 f0       	push   $0xf0106d45
f0101be8:	e8 53 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bed:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bf2:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0101bf7:	e8 cd ee ff ff       	call   f0100ac9 <check_va2pa>
f0101bfc:	89 f2                	mov    %esi,%edx
f0101bfe:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f0101c04:	c1 fa 03             	sar    $0x3,%edx
f0101c07:	c1 e2 0c             	shl    $0xc,%edx
f0101c0a:	39 d0                	cmp    %edx,%eax
f0101c0c:	74 19                	je     f0101c27 <mem_init+0x8a2>
f0101c0e:	68 00 67 10 f0       	push   $0xf0106700
f0101c13:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101c18:	68 01 04 00 00       	push   $0x401
f0101c1d:	68 45 6d 10 f0       	push   $0xf0106d45
f0101c22:	e8 19 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c27:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c2c:	74 19                	je     f0101c47 <mem_init+0x8c2>
f0101c2e:	68 52 6f 10 f0       	push   $0xf0106f52
f0101c33:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101c38:	68 02 04 00 00       	push   $0x402
f0101c3d:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101c58:	68 de 6e 10 f0       	push   $0xf0106ede
f0101c5d:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101c62:	68 06 04 00 00       	push   $0x406
f0101c67:	68 45 6d 10 f0       	push   $0xf0106d45
f0101c6c:	e8 cf e3 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c71:	8b 15 8c ee 22 f0    	mov    0xf022ee8c,%edx
f0101c77:	8b 02                	mov    (%edx),%eax
f0101c79:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c7e:	89 c1                	mov    %eax,%ecx
f0101c80:	c1 e9 0c             	shr    $0xc,%ecx
f0101c83:	3b 0d 88 ee 22 f0    	cmp    0xf022ee88,%ecx
f0101c89:	72 15                	jb     f0101ca0 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c8b:	50                   	push   %eax
f0101c8c:	68 24 5e 10 f0       	push   $0xf0105e24
f0101c91:	68 09 04 00 00       	push   $0x409
f0101c96:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101cc5:	68 30 67 10 f0       	push   $0xf0106730
f0101cca:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101ccf:	68 0a 04 00 00       	push   $0x40a
f0101cd4:	68 45 6d 10 f0       	push   $0xf0106d45
f0101cd9:	e8 62 e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cde:	6a 06                	push   $0x6
f0101ce0:	68 00 10 00 00       	push   $0x1000
f0101ce5:	56                   	push   %esi
f0101ce6:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101cec:	e8 bf f5 ff ff       	call   f01012b0 <page_insert>
f0101cf1:	83 c4 10             	add    $0x10,%esp
f0101cf4:	85 c0                	test   %eax,%eax
f0101cf6:	74 19                	je     f0101d11 <mem_init+0x98c>
f0101cf8:	68 70 67 10 f0       	push   $0xf0106770
f0101cfd:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101d02:	68 0d 04 00 00       	push   $0x40d
f0101d07:	68 45 6d 10 f0       	push   $0xf0106d45
f0101d0c:	e8 2f e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d11:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101d17:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d1c:	89 f8                	mov    %edi,%eax
f0101d1e:	e8 a6 ed ff ff       	call   f0100ac9 <check_va2pa>
f0101d23:	89 f2                	mov    %esi,%edx
f0101d25:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f0101d2b:	c1 fa 03             	sar    $0x3,%edx
f0101d2e:	c1 e2 0c             	shl    $0xc,%edx
f0101d31:	39 d0                	cmp    %edx,%eax
f0101d33:	74 19                	je     f0101d4e <mem_init+0x9c9>
f0101d35:	68 00 67 10 f0       	push   $0xf0106700
f0101d3a:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101d3f:	68 0e 04 00 00       	push   $0x40e
f0101d44:	68 45 6d 10 f0       	push   $0xf0106d45
f0101d49:	e8 f2 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d4e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d53:	74 19                	je     f0101d6e <mem_init+0x9e9>
f0101d55:	68 52 6f 10 f0       	push   $0xf0106f52
f0101d5a:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101d5f:	68 0f 04 00 00       	push   $0x40f
f0101d64:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101d86:	68 b0 67 10 f0       	push   $0xf01067b0
f0101d8b:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101d90:	68 10 04 00 00       	push   $0x410
f0101d95:	68 45 6d 10 f0       	push   $0xf0106d45
f0101d9a:	e8 a1 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d9f:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0101da4:	f6 00 04             	testb  $0x4,(%eax)
f0101da7:	75 19                	jne    f0101dc2 <mem_init+0xa3d>
f0101da9:	68 63 6f 10 f0       	push   $0xf0106f63
f0101dae:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101db3:	68 11 04 00 00       	push   $0x411
f0101db8:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101dd7:	68 c4 66 10 f0       	push   $0xf01066c4
f0101ddc:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101de1:	68 14 04 00 00       	push   $0x414
f0101de6:	68 45 6d 10 f0       	push   $0xf0106d45
f0101deb:	e8 50 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101df0:	83 ec 04             	sub    $0x4,%esp
f0101df3:	6a 00                	push   $0x0
f0101df5:	68 00 10 00 00       	push   $0x1000
f0101dfa:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101e00:	e8 7e f2 ff ff       	call   f0101083 <pgdir_walk>
f0101e05:	83 c4 10             	add    $0x10,%esp
f0101e08:	f6 00 02             	testb  $0x2,(%eax)
f0101e0b:	75 19                	jne    f0101e26 <mem_init+0xaa1>
f0101e0d:	68 e4 67 10 f0       	push   $0xf01067e4
f0101e12:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101e17:	68 15 04 00 00       	push   $0x415
f0101e1c:	68 45 6d 10 f0       	push   $0xf0106d45
f0101e21:	e8 1a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e26:	83 ec 04             	sub    $0x4,%esp
f0101e29:	6a 00                	push   $0x0
f0101e2b:	68 00 10 00 00       	push   $0x1000
f0101e30:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101e36:	e8 48 f2 ff ff       	call   f0101083 <pgdir_walk>
f0101e3b:	83 c4 10             	add    $0x10,%esp
f0101e3e:	f6 00 04             	testb  $0x4,(%eax)
f0101e41:	74 19                	je     f0101e5c <mem_init+0xad7>
f0101e43:	68 18 68 10 f0       	push   $0xf0106818
f0101e48:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101e4d:	68 16 04 00 00       	push   $0x416
f0101e52:	68 45 6d 10 f0       	push   $0xf0106d45
f0101e57:	e8 e4 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e5c:	6a 02                	push   $0x2
f0101e5e:	68 00 00 40 00       	push   $0x400000
f0101e63:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e66:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101e6c:	e8 3f f4 ff ff       	call   f01012b0 <page_insert>
f0101e71:	83 c4 10             	add    $0x10,%esp
f0101e74:	85 c0                	test   %eax,%eax
f0101e76:	78 19                	js     f0101e91 <mem_init+0xb0c>
f0101e78:	68 50 68 10 f0       	push   $0xf0106850
f0101e7d:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101e82:	68 19 04 00 00       	push   $0x419
f0101e87:	68 45 6d 10 f0       	push   $0xf0106d45
f0101e8c:	e8 af e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e91:	6a 02                	push   $0x2
f0101e93:	68 00 10 00 00       	push   $0x1000
f0101e98:	53                   	push   %ebx
f0101e99:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101e9f:	e8 0c f4 ff ff       	call   f01012b0 <page_insert>
f0101ea4:	83 c4 10             	add    $0x10,%esp
f0101ea7:	85 c0                	test   %eax,%eax
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xb3f>
f0101eab:	68 88 68 10 f0       	push   $0xf0106888
f0101eb0:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101eb5:	68 1c 04 00 00       	push   $0x41c
f0101eba:	68 45 6d 10 f0       	push   $0xf0106d45
f0101ebf:	e8 7c e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ec4:	83 ec 04             	sub    $0x4,%esp
f0101ec7:	6a 00                	push   $0x0
f0101ec9:	68 00 10 00 00       	push   $0x1000
f0101ece:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101ed4:	e8 aa f1 ff ff       	call   f0101083 <pgdir_walk>
f0101ed9:	83 c4 10             	add    $0x10,%esp
f0101edc:	f6 00 04             	testb  $0x4,(%eax)
f0101edf:	74 19                	je     f0101efa <mem_init+0xb75>
f0101ee1:	68 18 68 10 f0       	push   $0xf0106818
f0101ee6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101eeb:	68 1d 04 00 00       	push   $0x41d
f0101ef0:	68 45 6d 10 f0       	push   $0xf0106d45
f0101ef5:	e8 46 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101efa:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101f00:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f05:	89 f8                	mov    %edi,%eax
f0101f07:	e8 bd eb ff ff       	call   f0100ac9 <check_va2pa>
f0101f0c:	89 c1                	mov    %eax,%ecx
f0101f0e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f11:	89 d8                	mov    %ebx,%eax
f0101f13:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0101f19:	c1 f8 03             	sar    $0x3,%eax
f0101f1c:	c1 e0 0c             	shl    $0xc,%eax
f0101f1f:	39 c1                	cmp    %eax,%ecx
f0101f21:	74 19                	je     f0101f3c <mem_init+0xbb7>
f0101f23:	68 c4 68 10 f0       	push   $0xf01068c4
f0101f28:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101f2d:	68 20 04 00 00       	push   $0x420
f0101f32:	68 45 6d 10 f0       	push   $0xf0106d45
f0101f37:	e8 04 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f3c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f41:	89 f8                	mov    %edi,%eax
f0101f43:	e8 81 eb ff ff       	call   f0100ac9 <check_va2pa>
f0101f48:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101f4b:	74 19                	je     f0101f66 <mem_init+0xbe1>
f0101f4d:	68 f0 68 10 f0       	push   $0xf01068f0
f0101f52:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101f57:	68 21 04 00 00       	push   $0x421
f0101f5c:	68 45 6d 10 f0       	push   $0xf0106d45
f0101f61:	e8 da e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f66:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f6b:	74 19                	je     f0101f86 <mem_init+0xc01>
f0101f6d:	68 79 6f 10 f0       	push   $0xf0106f79
f0101f72:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101f77:	68 23 04 00 00       	push   $0x423
f0101f7c:	68 45 6d 10 f0       	push   $0xf0106d45
f0101f81:	e8 ba e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f86:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f8b:	74 19                	je     f0101fa6 <mem_init+0xc21>
f0101f8d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101f92:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101f97:	68 24 04 00 00       	push   $0x424
f0101f9c:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0101fbb:	68 20 69 10 f0       	push   $0xf0106920
f0101fc0:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0101fc5:	68 27 04 00 00       	push   $0x427
f0101fca:	68 45 6d 10 f0       	push   $0xf0106d45
f0101fcf:	e8 6c e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101fd4:	83 ec 08             	sub    $0x8,%esp
f0101fd7:	6a 00                	push   $0x0
f0101fd9:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101fdf:	e8 77 f2 ff ff       	call   f010125b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fe4:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101fea:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fef:	89 f8                	mov    %edi,%eax
f0101ff1:	e8 d3 ea ff ff       	call   f0100ac9 <check_va2pa>
f0101ff6:	83 c4 10             	add    $0x10,%esp
f0101ff9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ffc:	74 19                	je     f0102017 <mem_init+0xc92>
f0101ffe:	68 44 69 10 f0       	push   $0xf0106944
f0102003:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102008:	68 2b 04 00 00       	push   $0x42b
f010200d:	68 45 6d 10 f0       	push   $0xf0106d45
f0102012:	e8 29 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102017:	ba 00 10 00 00       	mov    $0x1000,%edx
f010201c:	89 f8                	mov    %edi,%eax
f010201e:	e8 a6 ea ff ff       	call   f0100ac9 <check_va2pa>
f0102023:	89 da                	mov    %ebx,%edx
f0102025:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f010202b:	c1 fa 03             	sar    $0x3,%edx
f010202e:	c1 e2 0c             	shl    $0xc,%edx
f0102031:	39 d0                	cmp    %edx,%eax
f0102033:	74 19                	je     f010204e <mem_init+0xcc9>
f0102035:	68 f0 68 10 f0       	push   $0xf01068f0
f010203a:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010203f:	68 2c 04 00 00       	push   $0x42c
f0102044:	68 45 6d 10 f0       	push   $0xf0106d45
f0102049:	e8 f2 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010204e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102053:	74 19                	je     f010206e <mem_init+0xce9>
f0102055:	68 30 6f 10 f0       	push   $0xf0106f30
f010205a:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010205f:	68 2d 04 00 00       	push   $0x42d
f0102064:	68 45 6d 10 f0       	push   $0xf0106d45
f0102069:	e8 d2 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010206e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102073:	74 19                	je     f010208e <mem_init+0xd09>
f0102075:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010207a:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010207f:	68 2e 04 00 00       	push   $0x42e
f0102084:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01020a3:	68 68 69 10 f0       	push   $0xf0106968
f01020a8:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01020ad:	68 31 04 00 00       	push   $0x431
f01020b2:	68 45 6d 10 f0       	push   $0xf0106d45
f01020b7:	e8 84 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01020bc:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020c1:	75 19                	jne    f01020dc <mem_init+0xd57>
f01020c3:	68 9b 6f 10 f0       	push   $0xf0106f9b
f01020c8:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01020cd:	68 32 04 00 00       	push   $0x432
f01020d2:	68 45 6d 10 f0       	push   $0xf0106d45
f01020d7:	e8 64 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01020dc:	83 3b 00             	cmpl   $0x0,(%ebx)
f01020df:	74 19                	je     f01020fa <mem_init+0xd75>
f01020e1:	68 a7 6f 10 f0       	push   $0xf0106fa7
f01020e6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01020eb:	68 33 04 00 00       	push   $0x433
f01020f0:	68 45 6d 10 f0       	push   $0xf0106d45
f01020f5:	e8 46 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020fa:	83 ec 08             	sub    $0x8,%esp
f01020fd:	68 00 10 00 00       	push   $0x1000
f0102102:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102108:	e8 4e f1 ff ff       	call   f010125b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010210d:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0102113:	ba 00 00 00 00       	mov    $0x0,%edx
f0102118:	89 f8                	mov    %edi,%eax
f010211a:	e8 aa e9 ff ff       	call   f0100ac9 <check_va2pa>
f010211f:	83 c4 10             	add    $0x10,%esp
f0102122:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102125:	74 19                	je     f0102140 <mem_init+0xdbb>
f0102127:	68 44 69 10 f0       	push   $0xf0106944
f010212c:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102131:	68 37 04 00 00       	push   $0x437
f0102136:	68 45 6d 10 f0       	push   $0xf0106d45
f010213b:	e8 00 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102140:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102145:	89 f8                	mov    %edi,%eax
f0102147:	e8 7d e9 ff ff       	call   f0100ac9 <check_va2pa>
f010214c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010214f:	74 19                	je     f010216a <mem_init+0xde5>
f0102151:	68 a0 69 10 f0       	push   $0xf01069a0
f0102156:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010215b:	68 38 04 00 00       	push   $0x438
f0102160:	68 45 6d 10 f0       	push   $0xf0106d45
f0102165:	e8 d6 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010216a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010216f:	74 19                	je     f010218a <mem_init+0xe05>
f0102171:	68 bc 6f 10 f0       	push   $0xf0106fbc
f0102176:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010217b:	68 39 04 00 00       	push   $0x439
f0102180:	68 45 6d 10 f0       	push   $0xf0106d45
f0102185:	e8 b6 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010218a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010218f:	74 19                	je     f01021aa <mem_init+0xe25>
f0102191:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102196:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010219b:	68 3a 04 00 00       	push   $0x43a
f01021a0:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01021bf:	68 c8 69 10 f0       	push   $0xf01069c8
f01021c4:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01021c9:	68 3d 04 00 00       	push   $0x43d
f01021ce:	68 45 6d 10 f0       	push   $0xf0106d45
f01021d3:	e8 68 de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021d8:	83 ec 0c             	sub    $0xc,%esp
f01021db:	6a 00                	push   $0x0
f01021dd:	e8 cf ed ff ff       	call   f0100fb1 <page_alloc>
f01021e2:	83 c4 10             	add    $0x10,%esp
f01021e5:	85 c0                	test   %eax,%eax
f01021e7:	74 19                	je     f0102202 <mem_init+0xe7d>
f01021e9:	68 de 6e 10 f0       	push   $0xf0106ede
f01021ee:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01021f3:	68 40 04 00 00       	push   $0x440
f01021f8:	68 45 6d 10 f0       	push   $0xf0106d45
f01021fd:	e8 3e de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102202:	8b 0d 8c ee 22 f0    	mov    0xf022ee8c,%ecx
f0102208:	8b 11                	mov    (%ecx),%edx
f010220a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102210:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102213:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0102219:	c1 f8 03             	sar    $0x3,%eax
f010221c:	c1 e0 0c             	shl    $0xc,%eax
f010221f:	39 c2                	cmp    %eax,%edx
f0102221:	74 19                	je     f010223c <mem_init+0xeb7>
f0102223:	68 6c 66 10 f0       	push   $0xf010666c
f0102228:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010222d:	68 43 04 00 00       	push   $0x443
f0102232:	68 45 6d 10 f0       	push   $0xf0106d45
f0102237:	e8 04 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010223c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102242:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102245:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010224a:	74 19                	je     f0102265 <mem_init+0xee0>
f010224c:	68 41 6f 10 f0       	push   $0xf0106f41
f0102251:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102256:	68 45 04 00 00       	push   $0x445
f010225b:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102281:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102287:	e8 f7 ed ff ff       	call   f0101083 <pgdir_walk>
f010228c:	89 c7                	mov    %eax,%edi
f010228e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102291:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0102296:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102299:	8b 40 04             	mov    0x4(%eax),%eax
f010229c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022a1:	8b 0d 88 ee 22 f0    	mov    0xf022ee88,%ecx
f01022a7:	89 c2                	mov    %eax,%edx
f01022a9:	c1 ea 0c             	shr    $0xc,%edx
f01022ac:	83 c4 10             	add    $0x10,%esp
f01022af:	39 ca                	cmp    %ecx,%edx
f01022b1:	72 15                	jb     f01022c8 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022b3:	50                   	push   %eax
f01022b4:	68 24 5e 10 f0       	push   $0xf0105e24
f01022b9:	68 4c 04 00 00       	push   $0x44c
f01022be:	68 45 6d 10 f0       	push   $0xf0106d45
f01022c3:	e8 78 dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01022c8:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01022cd:	39 c7                	cmp    %eax,%edi
f01022cf:	74 19                	je     f01022ea <mem_init+0xf65>
f01022d1:	68 cd 6f 10 f0       	push   $0xf0106fcd
f01022d6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01022db:	68 4d 04 00 00       	push   $0x44d
f01022e0:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01022fd:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0102313:	68 24 5e 10 f0       	push   $0xf0105e24
f0102318:	6a 58                	push   $0x58
f010231a:	68 51 6d 10 f0       	push   $0xf0106d51
f010231f:	e8 1c dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102324:	83 ec 04             	sub    $0x4,%esp
f0102327:	68 00 10 00 00       	push   $0x1000
f010232c:	68 ff 00 00 00       	push   $0xff
f0102331:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102336:	50                   	push   %eax
f0102337:	e8 fe 2d 00 00       	call   f010513a <memset>
	page_free(pp0);
f010233c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010233f:	89 3c 24             	mov    %edi,(%esp)
f0102342:	e8 da ec ff ff       	call   f0101021 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102347:	83 c4 0c             	add    $0xc,%esp
f010234a:	6a 01                	push   $0x1
f010234c:	6a 00                	push   $0x0
f010234e:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102354:	e8 2a ed ff ff       	call   f0101083 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102359:	89 fa                	mov    %edi,%edx
f010235b:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
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
f010236f:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f0102375:	72 12                	jb     f0102389 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102377:	52                   	push   %edx
f0102378:	68 24 5e 10 f0       	push   $0xf0105e24
f010237d:	6a 58                	push   $0x58
f010237f:	68 51 6d 10 f0       	push   $0xf0106d51
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
f010239d:	68 e5 6f 10 f0       	push   $0xf0106fe5
f01023a2:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01023a7:	68 57 04 00 00       	push   $0x457
f01023ac:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01023bd:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f01023c2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01023c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023cb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01023d1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01023d4:	89 0d 40 e2 22 f0    	mov    %ecx,0xf022e240

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
f010242d:	68 ec 69 10 f0       	push   $0xf01069ec
f0102432:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102437:	68 67 04 00 00       	push   $0x467
f010243c:	68 45 6d 10 f0       	push   $0xf0106d45
f0102441:	e8 fa db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102446:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010244c:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102452:	77 08                	ja     f010245c <mem_init+0x10d7>
f0102454:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010245a:	77 19                	ja     f0102475 <mem_init+0x10f0>
f010245c:	68 14 6a 10 f0       	push   $0xf0106a14
f0102461:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102466:	68 68 04 00 00       	push   $0x468
f010246b:	68 45 6d 10 f0       	push   $0xf0106d45
f0102470:	e8 cb db ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102475:	89 da                	mov    %ebx,%edx
f0102477:	09 f2                	or     %esi,%edx
f0102479:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010247f:	74 19                	je     f010249a <mem_init+0x1115>
f0102481:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0102486:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010248b:	68 6a 04 00 00       	push   $0x46a
f0102490:	68 45 6d 10 f0       	push   $0xf0106d45
f0102495:	e8 a6 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010249a:	39 c6                	cmp    %eax,%esi
f010249c:	73 19                	jae    f01024b7 <mem_init+0x1132>
f010249e:	68 fc 6f 10 f0       	push   $0xf0106ffc
f01024a3:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01024a8:	68 6c 04 00 00       	push   $0x46c
f01024ad:	68 45 6d 10 f0       	push   $0xf0106d45
f01024b2:	e8 89 db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01024b7:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f01024bd:	89 da                	mov    %ebx,%edx
f01024bf:	89 f8                	mov    %edi,%eax
f01024c1:	e8 03 e6 ff ff       	call   f0100ac9 <check_va2pa>
f01024c6:	85 c0                	test   %eax,%eax
f01024c8:	74 19                	je     f01024e3 <mem_init+0x115e>
f01024ca:	68 64 6a 10 f0       	push   $0xf0106a64
f01024cf:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01024d4:	68 6e 04 00 00       	push   $0x46e
f01024d9:	68 45 6d 10 f0       	push   $0xf0106d45
f01024de:	e8 5d db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01024e3:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01024e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01024ec:	89 c2                	mov    %eax,%edx
f01024ee:	89 f8                	mov    %edi,%eax
f01024f0:	e8 d4 e5 ff ff       	call   f0100ac9 <check_va2pa>
f01024f5:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01024fa:	74 19                	je     f0102515 <mem_init+0x1190>
f01024fc:	68 88 6a 10 f0       	push   $0xf0106a88
f0102501:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102506:	68 6f 04 00 00       	push   $0x46f
f010250b:	68 45 6d 10 f0       	push   $0xf0106d45
f0102510:	e8 2b db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102515:	89 f2                	mov    %esi,%edx
f0102517:	89 f8                	mov    %edi,%eax
f0102519:	e8 ab e5 ff ff       	call   f0100ac9 <check_va2pa>
f010251e:	85 c0                	test   %eax,%eax
f0102520:	74 19                	je     f010253b <mem_init+0x11b6>
f0102522:	68 b8 6a 10 f0       	push   $0xf0106ab8
f0102527:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010252c:	68 70 04 00 00       	push   $0x470
f0102531:	68 45 6d 10 f0       	push   $0xf0106d45
f0102536:	e8 05 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010253b:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102541:	89 f8                	mov    %edi,%eax
f0102543:	e8 81 e5 ff ff       	call   f0100ac9 <check_va2pa>
f0102548:	83 f8 ff             	cmp    $0xffffffff,%eax
f010254b:	74 19                	je     f0102566 <mem_init+0x11e1>
f010254d:	68 dc 6a 10 f0       	push   $0xf0106adc
f0102552:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102557:	68 71 04 00 00       	push   $0x471
f010255c:	68 45 6d 10 f0       	push   $0xf0106d45
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
f010257a:	68 08 6b 10 f0       	push   $0xf0106b08
f010257f:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102584:	68 73 04 00 00       	push   $0x473
f0102589:	68 45 6d 10 f0       	push   $0xf0106d45
f010258e:	e8 ad da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102593:	83 ec 04             	sub    $0x4,%esp
f0102596:	6a 00                	push   $0x0
f0102598:	53                   	push   %ebx
f0102599:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f010259f:	e8 df ea ff ff       	call   f0101083 <pgdir_walk>
f01025a4:	8b 00                	mov    (%eax),%eax
f01025a6:	83 c4 10             	add    $0x10,%esp
f01025a9:	83 e0 04             	and    $0x4,%eax
f01025ac:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01025af:	74 19                	je     f01025ca <mem_init+0x1245>
f01025b1:	68 4c 6b 10 f0       	push   $0xf0106b4c
f01025b6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01025bb:	68 74 04 00 00       	push   $0x474
f01025c0:	68 45 6d 10 f0       	push   $0xf0106d45
f01025c5:	e8 76 da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01025ca:	83 ec 04             	sub    $0x4,%esp
f01025cd:	6a 00                	push   $0x0
f01025cf:	53                   	push   %ebx
f01025d0:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f01025d6:	e8 a8 ea ff ff       	call   f0101083 <pgdir_walk>
f01025db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01025e1:	83 c4 0c             	add    $0xc,%esp
f01025e4:	6a 00                	push   $0x0
f01025e6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01025e9:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f01025ef:	e8 8f ea ff ff       	call   f0101083 <pgdir_walk>
f01025f4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01025fa:	83 c4 0c             	add    $0xc,%esp
f01025fd:	6a 00                	push   $0x0
f01025ff:	56                   	push   %esi
f0102600:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102606:	e8 78 ea ff ff       	call   f0101083 <pgdir_walk>
f010260b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102611:	c7 04 24 0e 70 10 f0 	movl   $0xf010700e,(%esp)
f0102618:	e8 61 10 00 00       	call   f010367e <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_U));
f010261d:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
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
f010262d:	68 48 5e 10 f0       	push   $0xf0105e48
f0102632:	68 cd 00 00 00       	push   $0xcd
f0102637:	68 45 6d 10 f0       	push   $0xf0106d45
f010263c:	e8 ff d9 ff ff       	call   f0100040 <_panic>
f0102641:	83 ec 08             	sub    $0x8,%esp
f0102644:	6a 05                	push   $0x5
f0102646:	05 00 00 00 10       	add    $0x10000000,%eax
f010264b:	50                   	push   %eax
f010264c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102651:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102656:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f010265b:	e8 f5 ea ff ff       	call   f0101155 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_U));
f0102660:	a1 44 e2 22 f0       	mov    0xf022e244,%eax
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
f0102670:	68 48 5e 10 f0       	push   $0xf0105e48
f0102675:	68 d7 00 00 00       	push   $0xd7
f010267a:	68 45 6d 10 f0       	push   $0xf0106d45
f010267f:	e8 bc d9 ff ff       	call   f0100040 <_panic>
f0102684:	83 ec 08             	sub    $0x8,%esp
f0102687:	6a 05                	push   $0x5
f0102689:	05 00 00 00 10       	add    $0x10000000,%eax
f010268e:	50                   	push   %eax
f010268f:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102694:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102699:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f010269e:	e8 b2 ea ff ff       	call   f0101155 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a3:	83 c4 10             	add    $0x10,%esp
f01026a6:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01026ab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026b0:	77 15                	ja     f01026c7 <mem_init+0x1342>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b2:	50                   	push   %eax
f01026b3:	68 48 5e 10 f0       	push   $0xf0105e48
f01026b8:	68 e4 00 00 00       	push   $0xe4
f01026bd:	68 45 6d 10 f0       	push   $0xf0106d45
f01026c2:	e8 79 d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01026c7:	83 ec 08             	sub    $0x8,%esp
f01026ca:	6a 02                	push   $0x2
f01026cc:	68 00 50 11 00       	push   $0x115000
f01026d1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026d6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026db:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f01026f6:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f01026fb:	e8 55 ea ff ff       	call   f0101155 <boot_map_region>
f0102700:	c7 45 c4 00 00 23 f0 	movl   $0xf0230000,-0x3c(%ebp)
f0102707:	83 c4 10             	add    $0x10,%esp
f010270a:	bb 00 00 23 f0       	mov    $0xf0230000,%ebx
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
f010271d:	68 48 5e 10 f0       	push   $0xf0105e48
f0102722:	68 24 01 00 00       	push   $0x124
f0102727:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102744:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0102749:	e8 07 ea ff ff       	call   f0101155 <boot_map_region>
f010274e:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102754:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	size_t i = 0;
	
	for( ; i < NCPU; ++i)
f010275a:	83 c4 10             	add    $0x10,%esp
f010275d:	b8 00 00 27 f0       	mov    $0xf0270000,%eax
f0102762:	39 d8                	cmp    %ebx,%eax
f0102764:	75 ae                	jne    f0102714 <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102766:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010276c:	a1 88 ee 22 f0       	mov    0xf022ee88,%eax
f0102771:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102774:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010277b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102780:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102783:	8b 35 90 ee 22 f0    	mov    0xf022ee90,%esi
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
f01027aa:	68 48 5e 10 f0       	push   $0xf0105e48
f01027af:	68 8c 03 00 00       	push   $0x38c
f01027b4:	68 45 6d 10 f0       	push   $0xf0106d45
f01027b9:	e8 82 d8 ff ff       	call   f0100040 <_panic>
f01027be:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01027c5:	39 c2                	cmp    %eax,%edx
f01027c7:	74 19                	je     f01027e2 <mem_init+0x145d>
f01027c9:	68 80 6b 10 f0       	push   $0xf0106b80
f01027ce:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01027d3:	68 8c 03 00 00       	push   $0x38c
f01027d8:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01027ed:	8b 35 44 e2 22 f0    	mov    0xf022e244,%esi
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
f010280e:	68 48 5e 10 f0       	push   $0xf0105e48
f0102813:	68 91 03 00 00       	push   $0x391
f0102818:	68 45 6d 10 f0       	push   $0xf0106d45
f010281d:	e8 1e d8 ff ff       	call   f0100040 <_panic>
f0102822:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102829:	39 d0                	cmp    %edx,%eax
f010282b:	74 19                	je     f0102846 <mem_init+0x14c1>
f010282d:	68 b4 6b 10 f0       	push   $0xf0106bb4
f0102832:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102837:	68 91 03 00 00       	push   $0x391
f010283c:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102872:	68 e8 6b 10 f0       	push   $0xf0106be8
f0102877:	68 6b 6d 10 f0       	push   $0xf0106d6b
f010287c:	68 95 03 00 00       	push   $0x395
f0102881:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01028cb:	68 48 5e 10 f0       	push   $0xf0105e48
f01028d0:	68 9d 03 00 00       	push   $0x39d
f01028d5:	68 45 6d 10 f0       	push   $0xf0106d45
f01028da:	e8 61 d7 ff ff       	call   f0100040 <_panic>
f01028df:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01028e2:	8d 94 0b 00 00 23 f0 	lea    -0xfdd0000(%ebx,%ecx,1),%edx
f01028e9:	39 d0                	cmp    %edx,%eax
f01028eb:	74 19                	je     f0102906 <mem_init+0x1581>
f01028ed:	68 10 6c 10 f0       	push   $0xf0106c10
f01028f2:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01028f7:	68 9d 03 00 00       	push   $0x39d
f01028fc:	68 45 6d 10 f0       	push   $0xf0106d45
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
f010292d:	68 58 6c 10 f0       	push   $0xf0106c58
f0102932:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102937:	68 9f 03 00 00       	push   $0x39f
f010293c:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102967:	b8 00 00 27 f0       	mov    $0xf0270000,%eax
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
f010298c:	68 27 70 10 f0       	push   $0xf0107027
f0102991:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102996:	68 aa 03 00 00       	push   $0x3aa
f010299b:	68 45 6d 10 f0       	push   $0xf0106d45
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
f01029b4:	68 27 70 10 f0       	push   $0xf0107027
f01029b9:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01029be:	68 ae 03 00 00       	push   $0x3ae
f01029c3:	68 45 6d 10 f0       	push   $0xf0106d45
f01029c8:	e8 73 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01029cd:	f6 c2 02             	test   $0x2,%dl
f01029d0:	75 38                	jne    f0102a0a <mem_init+0x1685>
f01029d2:	68 38 70 10 f0       	push   $0xf0107038
f01029d7:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01029dc:	68 af 03 00 00       	push   $0x3af
f01029e1:	68 45 6d 10 f0       	push   $0xf0106d45
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01029eb:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029ef:	74 19                	je     f0102a0a <mem_init+0x1685>
f01029f1:	68 49 70 10 f0       	push   $0xf0107049
f01029f6:	68 6b 6d 10 f0       	push   $0xf0106d6b
f01029fb:	68 b1 03 00 00       	push   $0x3b1
f0102a00:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102a1b:	68 7c 6c 10 f0       	push   $0xf0106c7c
f0102a20:	e8 59 0c 00 00       	call   f010367e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a25:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f0102a35:	68 48 5e 10 f0       	push   $0xf0105e48
f0102a3a:	68 fb 00 00 00       	push   $0xfb
f0102a3f:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102a7c:	68 33 6e 10 f0       	push   $0xf0106e33
f0102a81:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102a86:	68 89 04 00 00       	push   $0x489
f0102a8b:	68 45 6d 10 f0       	push   $0xf0106d45
f0102a90:	e8 ab d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a95:	83 ec 0c             	sub    $0xc,%esp
f0102a98:	6a 00                	push   $0x0
f0102a9a:	e8 12 e5 ff ff       	call   f0100fb1 <page_alloc>
f0102a9f:	89 c6                	mov    %eax,%esi
f0102aa1:	83 c4 10             	add    $0x10,%esp
f0102aa4:	85 c0                	test   %eax,%eax
f0102aa6:	75 19                	jne    f0102ac1 <mem_init+0x173c>
f0102aa8:	68 49 6e 10 f0       	push   $0xf0106e49
f0102aad:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102ab2:	68 8a 04 00 00       	push   $0x48a
f0102ab7:	68 45 6d 10 f0       	push   $0xf0106d45
f0102abc:	e8 7f d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ac1:	83 ec 0c             	sub    $0xc,%esp
f0102ac4:	6a 00                	push   $0x0
f0102ac6:	e8 e6 e4 ff ff       	call   f0100fb1 <page_alloc>
f0102acb:	89 c3                	mov    %eax,%ebx
f0102acd:	83 c4 10             	add    $0x10,%esp
f0102ad0:	85 c0                	test   %eax,%eax
f0102ad2:	75 19                	jne    f0102aed <mem_init+0x1768>
f0102ad4:	68 5f 6e 10 f0       	push   $0xf0106e5f
f0102ad9:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102ade:	68 8b 04 00 00       	push   $0x48b
f0102ae3:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102af8:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0102b0c:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102b12:	72 12                	jb     f0102b26 <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b14:	50                   	push   %eax
f0102b15:	68 24 5e 10 f0       	push   $0xf0105e24
f0102b1a:	6a 58                	push   $0x58
f0102b1c:	68 51 6d 10 f0       	push   $0xf0106d51
f0102b21:	e8 1a d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b26:	83 ec 04             	sub    $0x4,%esp
f0102b29:	68 00 10 00 00       	push   $0x1000
f0102b2e:	6a 01                	push   $0x1
f0102b30:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b35:	50                   	push   %eax
f0102b36:	e8 ff 25 00 00       	call   f010513a <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b3b:	89 d8                	mov    %ebx,%eax
f0102b3d:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0102b51:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102b57:	72 12                	jb     f0102b6b <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b59:	50                   	push   %eax
f0102b5a:	68 24 5e 10 f0       	push   $0xf0105e24
f0102b5f:	6a 58                	push   $0x58
f0102b61:	68 51 6d 10 f0       	push   $0xf0106d51
f0102b66:	e8 d5 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b6b:	83 ec 04             	sub    $0x4,%esp
f0102b6e:	68 00 10 00 00       	push   $0x1000
f0102b73:	6a 02                	push   $0x2
f0102b75:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b7a:	50                   	push   %eax
f0102b7b:	e8 ba 25 00 00       	call   f010513a <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b80:	6a 02                	push   $0x2
f0102b82:	68 00 10 00 00       	push   $0x1000
f0102b87:	56                   	push   %esi
f0102b88:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102b8e:	e8 1d e7 ff ff       	call   f01012b0 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b93:	83 c4 20             	add    $0x20,%esp
f0102b96:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b9b:	74 19                	je     f0102bb6 <mem_init+0x1831>
f0102b9d:	68 30 6f 10 f0       	push   $0xf0106f30
f0102ba2:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102ba7:	68 90 04 00 00       	push   $0x490
f0102bac:	68 45 6d 10 f0       	push   $0xf0106d45
f0102bb1:	e8 8a d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102bb6:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102bbd:	01 01 01 
f0102bc0:	74 19                	je     f0102bdb <mem_init+0x1856>
f0102bc2:	68 9c 6c 10 f0       	push   $0xf0106c9c
f0102bc7:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102bcc:	68 91 04 00 00       	push   $0x491
f0102bd1:	68 45 6d 10 f0       	push   $0xf0106d45
f0102bd6:	e8 65 d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bdb:	6a 02                	push   $0x2
f0102bdd:	68 00 10 00 00       	push   $0x1000
f0102be2:	53                   	push   %ebx
f0102be3:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102be9:	e8 c2 e6 ff ff       	call   f01012b0 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bee:	83 c4 10             	add    $0x10,%esp
f0102bf1:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bf8:	02 02 02 
f0102bfb:	74 19                	je     f0102c16 <mem_init+0x1891>
f0102bfd:	68 c0 6c 10 f0       	push   $0xf0106cc0
f0102c02:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102c07:	68 93 04 00 00       	push   $0x493
f0102c0c:	68 45 6d 10 f0       	push   $0xf0106d45
f0102c11:	e8 2a d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102c16:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c1b:	74 19                	je     f0102c36 <mem_init+0x18b1>
f0102c1d:	68 52 6f 10 f0       	push   $0xf0106f52
f0102c22:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102c27:	68 94 04 00 00       	push   $0x494
f0102c2c:	68 45 6d 10 f0       	push   $0xf0106d45
f0102c31:	e8 0a d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102c36:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c3b:	74 19                	je     f0102c56 <mem_init+0x18d1>
f0102c3d:	68 bc 6f 10 f0       	push   $0xf0106fbc
f0102c42:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102c47:	68 95 04 00 00       	push   $0x495
f0102c4c:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102c62:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0102c68:	c1 f8 03             	sar    $0x3,%eax
f0102c6b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c6e:	89 c2                	mov    %eax,%edx
f0102c70:	c1 ea 0c             	shr    $0xc,%edx
f0102c73:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102c79:	72 12                	jb     f0102c8d <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c7b:	50                   	push   %eax
f0102c7c:	68 24 5e 10 f0       	push   $0xf0105e24
f0102c81:	6a 58                	push   $0x58
f0102c83:	68 51 6d 10 f0       	push   $0xf0106d51
f0102c88:	e8 b3 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c8d:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c94:	03 03 03 
f0102c97:	74 19                	je     f0102cb2 <mem_init+0x192d>
f0102c99:	68 e4 6c 10 f0       	push   $0xf0106ce4
f0102c9e:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102ca3:	68 97 04 00 00       	push   $0x497
f0102ca8:	68 45 6d 10 f0       	push   $0xf0106d45
f0102cad:	e8 8e d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cb2:	83 ec 08             	sub    $0x8,%esp
f0102cb5:	68 00 10 00 00       	push   $0x1000
f0102cba:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102cc0:	e8 96 e5 ff ff       	call   f010125b <page_remove>
	assert(pp2->pp_ref == 0);
f0102cc5:	83 c4 10             	add    $0x10,%esp
f0102cc8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102ccd:	74 19                	je     f0102ce8 <mem_init+0x1963>
f0102ccf:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102cd4:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0102cd9:	68 99 04 00 00       	push   $0x499
f0102cde:	68 45 6d 10 f0       	push   $0xf0106d45
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
f0102d3b:	89 1d 3c e2 22 f0    	mov    %ebx,0xf022e23c
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
f0102d8d:	ff 35 3c e2 22 f0    	pushl  0xf022e23c
f0102d93:	ff 73 48             	pushl  0x48(%ebx)
f0102d96:	68 10 6d 10 f0       	push   $0xf0106d10
f0102d9b:	e8 de 08 00 00       	call   f010367e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102da0:	89 1c 24             	mov    %ebx,(%esp)
f0102da3:	e8 1d 06 00 00       	call   f01033c5 <env_destroy>
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
f0102de6:	68 58 70 10 f0       	push   $0xf0107058
f0102deb:	68 32 01 00 00       	push   $0x132
f0102df0:	68 a2 70 10 f0       	push   $0xf01070a2
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
f0102e2a:	e8 2b 29 00 00       	call   f010575a <cpunum>
f0102e2f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e32:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
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
f0102e4f:	03 1d 44 e2 22 f0    	add    0xf022e244,%ebx
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
f0102e74:	e8 e1 28 00 00       	call   f010575a <cpunum>
f0102e79:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e7c:	3b 98 28 f0 22 f0    	cmp    -0xfdd0fd8(%eax),%ebx
f0102e82:	74 26                	je     f0102eaa <envid2env+0x8f>
f0102e84:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e87:	e8 ce 28 00 00       	call   f010575a <cpunum>
f0102e8c:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e8f:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
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
f0102ebb:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
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
f0102eed:	8b 35 44 e2 22 f0    	mov    0xf022e244,%esi
f0102ef3:	8b 15 48 e2 22 f0    	mov    0xf022e248,%edx
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
f0102f17:	89 35 48 e2 22 f0    	mov    %esi,0xf022e248
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
f0102f2d:	8b 1d 48 e2 22 f0    	mov    0xf022e248,%ebx
f0102f33:	85 db                	test   %ebx,%ebx
f0102f35:	0f 84 69 01 00 00    	je     f01030a4 <env_alloc+0x17e>
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
f0102f4a:	0f 84 5b 01 00 00    	je     f01030ab <env_alloc+0x185>
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
f0102f55:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0102f5b:	c1 f8 03             	sar    $0x3,%eax
f0102f5e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f61:	89 c2                	mov    %eax,%edx
f0102f63:	c1 ea 0c             	shr    $0xc,%edx
f0102f66:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102f6c:	72 12                	jb     f0102f80 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f6e:	50                   	push   %eax
f0102f6f:	68 24 5e 10 f0       	push   $0xf0105e24
f0102f74:	6a 58                	push   $0x58
f0102f76:	68 51 6d 10 f0       	push   $0xf0106d51
f0102f7b:	e8 c0 d0 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = (pde_t*) page2kva(p);
f0102f80:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102f85:	89 43 60             	mov    %eax,0x60(%ebx)
f0102f88:	b8 ec 0e 00 00       	mov    $0xeec,%eax
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102f8d:	8b 15 8c ee 22 f0    	mov    0xf022ee8c,%edx
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
f0102fb1:	68 48 5e 10 f0       	push   $0xf0105e48
f0102fb6:	68 ca 00 00 00       	push   $0xca
f0102fbb:	68 a2 70 10 f0       	push   $0xf01070a2
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
f0102feb:	2b 15 44 e2 22 f0    	sub    0xf022e244,%edx
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
f0103022:	e8 13 21 00 00       	call   f010513a <memset>
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

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103046:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010304d:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103051:	8b 43 44             	mov    0x44(%ebx),%eax
f0103054:	a3 48 e2 22 f0       	mov    %eax,0xf022e248
	*newenv_store = e;
f0103059:	8b 45 08             	mov    0x8(%ebp),%eax
f010305c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010305e:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103061:	e8 f4 26 00 00       	call   f010575a <cpunum>
f0103066:	6b c0 74             	imul   $0x74,%eax,%eax
f0103069:	83 c4 10             	add    $0x10,%esp
f010306c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103071:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103078:	74 11                	je     f010308b <env_alloc+0x165>
f010307a:	e8 db 26 00 00       	call   f010575a <cpunum>
f010307f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103082:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103088:	8b 50 48             	mov    0x48(%eax),%edx
f010308b:	83 ec 04             	sub    $0x4,%esp
f010308e:	53                   	push   %ebx
f010308f:	52                   	push   %edx
f0103090:	68 ad 70 10 f0       	push   $0xf01070ad
f0103095:	e8 e4 05 00 00       	call   f010367e <cprintf>
	return 0;
f010309a:	83 c4 10             	add    $0x10,%esp
f010309d:	b8 00 00 00 00       	mov    $0x0,%eax
f01030a2:	eb 0c                	jmp    f01030b0 <env_alloc+0x18a>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01030a4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01030a9:	eb 05                	jmp    f01030b0 <env_alloc+0x18a>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01030ab:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01030b0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030b3:	c9                   	leave  
f01030b4:	c3                   	ret    

f01030b5 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01030b5:	55                   	push   %ebp
f01030b6:	89 e5                	mov    %esp,%ebp
f01030b8:	57                   	push   %edi
f01030b9:	56                   	push   %esi
f01030ba:	53                   	push   %ebx
f01030bb:	83 ec 34             	sub    $0x34,%esp
f01030be:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e = NULL;
f01030c1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uint32_t result = env_alloc(&e, 0);
f01030c8:	6a 00                	push   $0x0
f01030ca:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030cd:	50                   	push   %eax
f01030ce:	e8 53 fe ff ff       	call   f0102f26 <env_alloc>

	if(result !=  0)
f01030d3:	83 c4 10             	add    $0x10,%esp
f01030d6:	85 c0                	test   %eax,%eax
f01030d8:	74 15                	je     f01030ef <env_create+0x3a>
		panic("env_create: %e", result);
f01030da:	50                   	push   %eax
f01030db:	68 c2 70 10 f0       	push   $0xf01070c2
f01030e0:	68 a1 01 00 00       	push   $0x1a1
f01030e5:	68 a2 70 10 f0       	push   $0xf01070a2
f01030ea:	e8 51 cf ff ff       	call   f0100040 <_panic>

	load_icode(e, binary);
f01030ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph = NULL, *eph = NULL;
	struct Elf *elf = (struct Elf*) binary;
	
	if(elf->e_magic != ELF_MAGIC)
f01030f5:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030fb:	74 17                	je     f0103114 <env_create+0x5f>
		panic("load icode: Elf format not valid!");
f01030fd:	83 ec 04             	sub    $0x4,%esp
f0103100:	68 80 70 10 f0       	push   $0xf0107080
f0103105:	68 74 01 00 00       	push   $0x174
f010310a:	68 a2 70 10 f0       	push   $0xf01070a2
f010310f:	e8 2c cf ff ff       	call   f0100040 <_panic>

	ph = (struct Proghdr*) (binary + elf->e_phoff);
f0103114:	89 fb                	mov    %edi,%ebx
f0103116:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0103119:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f010311d:	c1 e6 05             	shl    $0x5,%esi
f0103120:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0103122:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103125:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103128:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010312d:	77 15                	ja     f0103144 <env_create+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010312f:	50                   	push   %eax
f0103130:	68 48 5e 10 f0       	push   $0xf0105e48
f0103135:	68 79 01 00 00       	push   $0x179
f010313a:	68 a2 70 10 f0       	push   $0xf01070a2
f010313f:	e8 fc ce ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103144:	05 00 00 00 10       	add    $0x10000000,%eax
f0103149:	0f 22 d8             	mov    %eax,%cr3
f010314c:	eb 44                	jmp    f0103192 <env_create+0xdd>

	for( ; ph < eph; ++ph)
	{
		if(ph->p_type != ELF_PROG_LOAD)
f010314e:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103151:	75 3c                	jne    f010318f <env_create+0xda>
			continue;		

		region_alloc(e, (void*) ph->p_va, ph->p_memsz);
f0103153:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103156:	8b 53 08             	mov    0x8(%ebx),%edx
f0103159:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010315c:	e8 4f fc ff ff       	call   f0102db0 <region_alloc>
		
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103161:	83 ec 04             	sub    $0x4,%esp
f0103164:	ff 73 10             	pushl  0x10(%ebx)
f0103167:	89 f8                	mov    %edi,%eax
f0103169:	03 43 04             	add    0x4(%ebx),%eax
f010316c:	50                   	push   %eax
f010316d:	ff 73 08             	pushl  0x8(%ebx)
f0103170:	e8 7a 20 00 00       	call   f01051ef <memcpy>
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
f0103175:	8b 43 10             	mov    0x10(%ebx),%eax
f0103178:	83 c4 0c             	add    $0xc,%esp
f010317b:	8b 53 14             	mov    0x14(%ebx),%edx
f010317e:	29 c2                	sub    %eax,%edx
f0103180:	52                   	push   %edx
f0103181:	6a 00                	push   $0x0
f0103183:	03 43 08             	add    0x8(%ebx),%eax
f0103186:	50                   	push   %eax
f0103187:	e8 ae 1f 00 00       	call   f010513a <memset>
f010318c:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr*) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	for( ; ph < eph; ++ph)
f010318f:	83 c3 20             	add    $0x20,%ebx
f0103192:	39 de                	cmp    %ebx,%esi
f0103194:	77 b8                	ja     f010314e <env_create+0x99>
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
	}

	e->env_tf.tf_eip = elf->e_entry;
f0103196:	8b 47 18             	mov    0x18(%edi),%eax
f0103199:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010319c:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*) USTACKTOP - PGSIZE, PGSIZE);
f010319f:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031a4:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031a9:	89 f8                	mov    %edi,%eax
f01031ab:	e8 00 fc ff ff       	call   f0102db0 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f01031b0:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031ba:	77 15                	ja     f01031d1 <env_create+0x11c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031bc:	50                   	push   %eax
f01031bd:	68 48 5e 10 f0       	push   $0xf0105e48
f01031c2:	68 8f 01 00 00       	push   $0x18f
f01031c7:	68 a2 70 10 f0       	push   $0xf01070a2
f01031cc:	e8 6f ce ff ff       	call   f0100040 <_panic>
f01031d1:	05 00 00 00 10       	add    $0x10000000,%eax
f01031d6:	0f 22 d8             	mov    %eax,%cr3

	if(result !=  0)
		panic("env_create: %e", result);

	load_icode(e, binary);
	e->env_type = type;
f01031d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031dc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031df:	89 50 50             	mov    %edx,0x50(%eax)
}
f01031e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031e5:	5b                   	pop    %ebx
f01031e6:	5e                   	pop    %esi
f01031e7:	5f                   	pop    %edi
f01031e8:	5d                   	pop    %ebp
f01031e9:	c3                   	ret    

f01031ea <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031ea:	55                   	push   %ebp
f01031eb:	89 e5                	mov    %esp,%ebp
f01031ed:	57                   	push   %edi
f01031ee:	56                   	push   %esi
f01031ef:	53                   	push   %ebx
f01031f0:	83 ec 1c             	sub    $0x1c,%esp
f01031f3:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031f6:	e8 5f 25 00 00       	call   f010575a <cpunum>
f01031fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01031fe:	39 b8 28 f0 22 f0    	cmp    %edi,-0xfdd0fd8(%eax)
f0103204:	75 29                	jne    f010322f <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f0103206:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010320b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103210:	77 15                	ja     f0103227 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103212:	50                   	push   %eax
f0103213:	68 48 5e 10 f0       	push   $0xf0105e48
f0103218:	68 b5 01 00 00       	push   $0x1b5
f010321d:	68 a2 70 10 f0       	push   $0xf01070a2
f0103222:	e8 19 ce ff ff       	call   f0100040 <_panic>
f0103227:	05 00 00 00 10       	add    $0x10000000,%eax
f010322c:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010322f:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103232:	e8 23 25 00 00       	call   f010575a <cpunum>
f0103237:	6b c0 74             	imul   $0x74,%eax,%eax
f010323a:	ba 00 00 00 00       	mov    $0x0,%edx
f010323f:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103246:	74 11                	je     f0103259 <env_free+0x6f>
f0103248:	e8 0d 25 00 00       	call   f010575a <cpunum>
f010324d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103250:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103256:	8b 50 48             	mov    0x48(%eax),%edx
f0103259:	83 ec 04             	sub    $0x4,%esp
f010325c:	53                   	push   %ebx
f010325d:	52                   	push   %edx
f010325e:	68 d1 70 10 f0       	push   $0xf01070d1
f0103263:	e8 16 04 00 00       	call   f010367e <cprintf>
f0103268:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010326b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103272:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103275:	89 d0                	mov    %edx,%eax
f0103277:	c1 e0 02             	shl    $0x2,%eax
f010327a:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010327d:	8b 47 60             	mov    0x60(%edi),%eax
f0103280:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103283:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103289:	0f 84 a8 00 00 00    	je     f0103337 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010328f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103295:	89 f0                	mov    %esi,%eax
f0103297:	c1 e8 0c             	shr    $0xc,%eax
f010329a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010329d:	39 05 88 ee 22 f0    	cmp    %eax,0xf022ee88
f01032a3:	77 15                	ja     f01032ba <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032a5:	56                   	push   %esi
f01032a6:	68 24 5e 10 f0       	push   $0xf0105e24
f01032ab:	68 c4 01 00 00       	push   $0x1c4
f01032b0:	68 a2 70 10 f0       	push   $0xf01070a2
f01032b5:	e8 86 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032bd:	c1 e0 16             	shl    $0x16,%eax
f01032c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032c3:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01032c8:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01032cf:	01 
f01032d0:	74 17                	je     f01032e9 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032d2:	83 ec 08             	sub    $0x8,%esp
f01032d5:	89 d8                	mov    %ebx,%eax
f01032d7:	c1 e0 0c             	shl    $0xc,%eax
f01032da:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032dd:	50                   	push   %eax
f01032de:	ff 77 60             	pushl  0x60(%edi)
f01032e1:	e8 75 df ff ff       	call   f010125b <page_remove>
f01032e6:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032e9:	83 c3 01             	add    $0x1,%ebx
f01032ec:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032f2:	75 d4                	jne    f01032c8 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032f4:	8b 47 60             	mov    0x60(%edi),%eax
f01032f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032fa:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103301:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103304:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f010330a:	72 14                	jb     f0103320 <env_free+0x136>
		panic("pa2page called with invalid pa");
f010330c:	83 ec 04             	sub    $0x4,%esp
f010330f:	68 14 65 10 f0       	push   $0xf0106514
f0103314:	6a 51                	push   $0x51
f0103316:	68 51 6d 10 f0       	push   $0xf0106d51
f010331b:	e8 20 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103320:	83 ec 0c             	sub    $0xc,%esp
f0103323:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
f0103328:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010332b:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f010332e:	50                   	push   %eax
f010332f:	e8 28 dd ff ff       	call   f010105c <page_decref>
f0103334:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103337:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010333b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010333e:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103343:	0f 85 29 ff ff ff    	jne    f0103272 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103349:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010334c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103351:	77 15                	ja     f0103368 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103353:	50                   	push   %eax
f0103354:	68 48 5e 10 f0       	push   $0xf0105e48
f0103359:	68 d2 01 00 00       	push   $0x1d2
f010335e:	68 a2 70 10 f0       	push   $0xf01070a2
f0103363:	e8 d8 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103368:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010336f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103374:	c1 e8 0c             	shr    $0xc,%eax
f0103377:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f010337d:	72 14                	jb     f0103393 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010337f:	83 ec 04             	sub    $0x4,%esp
f0103382:	68 14 65 10 f0       	push   $0xf0106514
f0103387:	6a 51                	push   $0x51
f0103389:	68 51 6d 10 f0       	push   $0xf0106d51
f010338e:	e8 ad cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103393:	83 ec 0c             	sub    $0xc,%esp
f0103396:	8b 15 90 ee 22 f0    	mov    0xf022ee90,%edx
f010339c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010339f:	50                   	push   %eax
f01033a0:	e8 b7 dc ff ff       	call   f010105c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01033a5:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01033ac:	a1 48 e2 22 f0       	mov    0xf022e248,%eax
f01033b1:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01033b4:	89 3d 48 e2 22 f0    	mov    %edi,0xf022e248
}
f01033ba:	83 c4 10             	add    $0x10,%esp
f01033bd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033c0:	5b                   	pop    %ebx
f01033c1:	5e                   	pop    %esi
f01033c2:	5f                   	pop    %edi
f01033c3:	5d                   	pop    %ebp
f01033c4:	c3                   	ret    

f01033c5 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01033c5:	55                   	push   %ebp
f01033c6:	89 e5                	mov    %esp,%ebp
f01033c8:	53                   	push   %ebx
f01033c9:	83 ec 04             	sub    $0x4,%esp
f01033cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01033cf:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01033d3:	75 19                	jne    f01033ee <env_destroy+0x29>
f01033d5:	e8 80 23 00 00       	call   f010575a <cpunum>
f01033da:	6b c0 74             	imul   $0x74,%eax,%eax
f01033dd:	3b 98 28 f0 22 f0    	cmp    -0xfdd0fd8(%eax),%ebx
f01033e3:	74 09                	je     f01033ee <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033e5:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033ec:	eb 33                	jmp    f0103421 <env_destroy+0x5c>
	}

	env_free(e);
f01033ee:	83 ec 0c             	sub    $0xc,%esp
f01033f1:	53                   	push   %ebx
f01033f2:	e8 f3 fd ff ff       	call   f01031ea <env_free>

	if (curenv == e) {
f01033f7:	e8 5e 23 00 00       	call   f010575a <cpunum>
f01033fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ff:	83 c4 10             	add    $0x10,%esp
f0103402:	3b 98 28 f0 22 f0    	cmp    -0xfdd0fd8(%eax),%ebx
f0103408:	75 17                	jne    f0103421 <env_destroy+0x5c>
		curenv = NULL;
f010340a:	e8 4b 23 00 00       	call   f010575a <cpunum>
f010340f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103412:	c7 80 28 f0 22 f0 00 	movl   $0x0,-0xfdd0fd8(%eax)
f0103419:	00 00 00 
		sched_yield();
f010341c:	e8 1e 0d 00 00       	call   f010413f <sched_yield>
	}
}
f0103421:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103424:	c9                   	leave  
f0103425:	c3                   	ret    

f0103426 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103426:	55                   	push   %ebp
f0103427:	89 e5                	mov    %esp,%ebp
f0103429:	53                   	push   %ebx
f010342a:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f010342d:	e8 28 23 00 00       	call   f010575a <cpunum>
f0103432:	6b c0 74             	imul   $0x74,%eax,%eax
f0103435:	8b 98 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%ebx
f010343b:	e8 1a 23 00 00       	call   f010575a <cpunum>
f0103440:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103443:	8b 65 08             	mov    0x8(%ebp),%esp
f0103446:	61                   	popa   
f0103447:	07                   	pop    %es
f0103448:	1f                   	pop    %ds
f0103449:	83 c4 08             	add    $0x8,%esp
f010344c:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010344d:	83 ec 04             	sub    $0x4,%esp
f0103450:	68 e7 70 10 f0       	push   $0xf01070e7
f0103455:	68 09 02 00 00       	push   $0x209
f010345a:	68 a2 70 10 f0       	push   $0xf01070a2
f010345f:	e8 dc cb ff ff       	call   f0100040 <_panic>

f0103464 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103464:	55                   	push   %ebp
f0103465:	89 e5                	mov    %esp,%ebp
f0103467:	53                   	push   %ebx
f0103468:	83 ec 04             	sub    $0x4,%esp
f010346b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && (curenv->env_status == ENV_RUNNING))
f010346e:	e8 e7 22 00 00       	call   f010575a <cpunum>
f0103473:	6b c0 74             	imul   $0x74,%eax,%eax
f0103476:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f010347d:	74 29                	je     f01034a8 <env_run+0x44>
f010347f:	e8 d6 22 00 00       	call   f010575a <cpunum>
f0103484:	6b c0 74             	imul   $0x74,%eax,%eax
f0103487:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f010348d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103491:	75 15                	jne    f01034a8 <env_run+0x44>
	{
		curenv->env_status = ENV_RUNNABLE;
f0103493:	e8 c2 22 00 00       	call   f010575a <cpunum>
f0103498:	6b c0 74             	imul   $0x74,%eax,%eax
f010349b:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01034a1:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}

	curenv = e;
f01034a8:	e8 ad 22 00 00       	call   f010575a <cpunum>
f01034ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01034b0:	89 98 28 f0 22 f0    	mov    %ebx,-0xfdd0fd8(%eax)
	e->env_status = ENV_RUNNING;
f01034b6:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	e->env_runs++;
f01034bd:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(e->env_pgdir));
f01034c1:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034c9:	77 15                	ja     f01034e0 <env_run+0x7c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034cb:	50                   	push   %eax
f01034cc:	68 48 5e 10 f0       	push   $0xf0105e48
f01034d1:	68 2f 02 00 00       	push   $0x22f
f01034d6:	68 a2 70 10 f0       	push   $0xf01070a2
f01034db:	e8 60 cb ff ff       	call   f0100040 <_panic>
f01034e0:	05 00 00 00 10       	add    $0x10000000,%eax
f01034e5:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034e8:	83 ec 0c             	sub    $0xc,%esp
f01034eb:	68 c0 f3 11 f0       	push   $0xf011f3c0
f01034f0:	e8 70 25 00 00       	call   f0105a65 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034f5:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01034f7:	89 1c 24             	mov    %ebx,(%esp)
f01034fa:	e8 27 ff ff ff       	call   f0103426 <env_pop_tf>

f01034ff <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034ff:	55                   	push   %ebp
f0103500:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103502:	ba 70 00 00 00       	mov    $0x70,%edx
f0103507:	8b 45 08             	mov    0x8(%ebp),%eax
f010350a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010350b:	ba 71 00 00 00       	mov    $0x71,%edx
f0103510:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103511:	0f b6 c0             	movzbl %al,%eax
}
f0103514:	5d                   	pop    %ebp
f0103515:	c3                   	ret    

f0103516 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103516:	55                   	push   %ebp
f0103517:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103519:	ba 70 00 00 00       	mov    $0x70,%edx
f010351e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103521:	ee                   	out    %al,(%dx)
f0103522:	ba 71 00 00 00       	mov    $0x71,%edx
f0103527:	8b 45 0c             	mov    0xc(%ebp),%eax
f010352a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010352b:	5d                   	pop    %ebp
f010352c:	c3                   	ret    

f010352d <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010352d:	55                   	push   %ebp
f010352e:	89 e5                	mov    %esp,%ebp
f0103530:	56                   	push   %esi
f0103531:	53                   	push   %ebx
f0103532:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103535:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f010353b:	80 3d 4c e2 22 f0 00 	cmpb   $0x0,0xf022e24c
f0103542:	74 5a                	je     f010359e <irq_setmask_8259A+0x71>
f0103544:	89 c6                	mov    %eax,%esi
f0103546:	ba 21 00 00 00       	mov    $0x21,%edx
f010354b:	ee                   	out    %al,(%dx)
f010354c:	66 c1 e8 08          	shr    $0x8,%ax
f0103550:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103555:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103556:	83 ec 0c             	sub    $0xc,%esp
f0103559:	68 f3 70 10 f0       	push   $0xf01070f3
f010355e:	e8 1b 01 00 00       	call   f010367e <cprintf>
f0103563:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103566:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010356b:	0f b7 f6             	movzwl %si,%esi
f010356e:	f7 d6                	not    %esi
f0103570:	0f a3 de             	bt     %ebx,%esi
f0103573:	73 11                	jae    f0103586 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103575:	83 ec 08             	sub    $0x8,%esp
f0103578:	53                   	push   %ebx
f0103579:	68 b3 75 10 f0       	push   $0xf01075b3
f010357e:	e8 fb 00 00 00       	call   f010367e <cprintf>
f0103583:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103586:	83 c3 01             	add    $0x1,%ebx
f0103589:	83 fb 10             	cmp    $0x10,%ebx
f010358c:	75 e2                	jne    f0103570 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010358e:	83 ec 0c             	sub    $0xc,%esp
f0103591:	68 bc 61 10 f0       	push   $0xf01061bc
f0103596:	e8 e3 00 00 00       	call   f010367e <cprintf>
f010359b:	83 c4 10             	add    $0x10,%esp
}
f010359e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035a1:	5b                   	pop    %ebx
f01035a2:	5e                   	pop    %esi
f01035a3:	5d                   	pop    %ebp
f01035a4:	c3                   	ret    

f01035a5 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035a5:	c6 05 4c e2 22 f0 01 	movb   $0x1,0xf022e24c
f01035ac:	ba 21 00 00 00       	mov    $0x21,%edx
f01035b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035b6:	ee                   	out    %al,(%dx)
f01035b7:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035bc:	ee                   	out    %al,(%dx)
f01035bd:	ba 20 00 00 00       	mov    $0x20,%edx
f01035c2:	b8 11 00 00 00       	mov    $0x11,%eax
f01035c7:	ee                   	out    %al,(%dx)
f01035c8:	ba 21 00 00 00       	mov    $0x21,%edx
f01035cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01035d2:	ee                   	out    %al,(%dx)
f01035d3:	b8 04 00 00 00       	mov    $0x4,%eax
f01035d8:	ee                   	out    %al,(%dx)
f01035d9:	b8 03 00 00 00       	mov    $0x3,%eax
f01035de:	ee                   	out    %al,(%dx)
f01035df:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035e4:	b8 11 00 00 00       	mov    $0x11,%eax
f01035e9:	ee                   	out    %al,(%dx)
f01035ea:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035ef:	b8 28 00 00 00       	mov    $0x28,%eax
f01035f4:	ee                   	out    %al,(%dx)
f01035f5:	b8 02 00 00 00       	mov    $0x2,%eax
f01035fa:	ee                   	out    %al,(%dx)
f01035fb:	b8 01 00 00 00       	mov    $0x1,%eax
f0103600:	ee                   	out    %al,(%dx)
f0103601:	ba 20 00 00 00       	mov    $0x20,%edx
f0103606:	b8 68 00 00 00       	mov    $0x68,%eax
f010360b:	ee                   	out    %al,(%dx)
f010360c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103611:	ee                   	out    %al,(%dx)
f0103612:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103617:	b8 68 00 00 00       	mov    $0x68,%eax
f010361c:	ee                   	out    %al,(%dx)
f010361d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103622:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103623:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f010362a:	66 83 f8 ff          	cmp    $0xffff,%ax
f010362e:	74 13                	je     f0103643 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103630:	55                   	push   %ebp
f0103631:	89 e5                	mov    %esp,%ebp
f0103633:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103636:	0f b7 c0             	movzwl %ax,%eax
f0103639:	50                   	push   %eax
f010363a:	e8 ee fe ff ff       	call   f010352d <irq_setmask_8259A>
f010363f:	83 c4 10             	add    $0x10,%esp
}
f0103642:	c9                   	leave  
f0103643:	f3 c3                	repz ret 

f0103645 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103645:	55                   	push   %ebp
f0103646:	89 e5                	mov    %esp,%ebp
f0103648:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010364b:	ff 75 08             	pushl  0x8(%ebp)
f010364e:	e8 11 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0103653:	83 c4 10             	add    $0x10,%esp
f0103656:	c9                   	leave  
f0103657:	c3                   	ret    

f0103658 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103658:	55                   	push   %ebp
f0103659:	89 e5                	mov    %esp,%ebp
f010365b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010365e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103665:	ff 75 0c             	pushl  0xc(%ebp)
f0103668:	ff 75 08             	pushl  0x8(%ebp)
f010366b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010366e:	50                   	push   %eax
f010366f:	68 45 36 10 f0       	push   $0xf0103645
f0103674:	e8 55 14 00 00       	call   f0104ace <vprintfmt>
	return cnt;
}
f0103679:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010367c:	c9                   	leave  
f010367d:	c3                   	ret    

f010367e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010367e:	55                   	push   %ebp
f010367f:	89 e5                	mov    %esp,%ebp
f0103681:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103684:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103687:	50                   	push   %eax
f0103688:	ff 75 08             	pushl  0x8(%ebp)
f010368b:	e8 c8 ff ff ff       	call   f0103658 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103690:	c9                   	leave  
f0103691:	c3                   	ret    

f0103692 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103692:	55                   	push   %ebp
f0103693:	89 e5                	mov    %esp,%ebp
f0103695:	57                   	push   %edi
f0103696:	56                   	push   %esi
f0103697:	53                   	push   %ebx
f0103698:	83 ec 1c             	sub    $0x1c,%esp
	//
	// LAB 4: Your code here:	

	// Setup a TSS so that -we get the right stack
	// when we trap to the kernel.
	size_t id = thiscpu->cpu_id;
f010369b:	e8 ba 20 00 00       	call   f010575a <cpunum>
f01036a0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a3:	0f b6 b0 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%esi
f01036aa:	89 f0                	mov    %esi,%eax
f01036ac:	0f b6 d8             	movzbl %al,%ebx

	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f01036af:	e8 a6 20 00 00       	call   f010575a <cpunum>
f01036b4:	6b c0 74             	imul   $0x74,%eax,%eax
f01036b7:	66 c7 80 92 f0 22 f0 	movw   $0x68,-0xfdd0f6e(%eax)
f01036be:	68 00 
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036c0:	e8 95 20 00 00       	call   f010575a <cpunum>
f01036c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c8:	66 c7 80 34 f0 22 f0 	movw   $0x10,-0xfdd0fcc(%eax)
f01036cf:	10 00 
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - id * (KSTKSIZE + KSTKGAP);
f01036d1:	e8 84 20 00 00       	call   f010575a <cpunum>
f01036d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01036d9:	89 da                	mov    %ebx,%edx
f01036db:	f7 da                	neg    %edx
f01036dd:	c1 e2 10             	shl    $0x10,%edx
f01036e0:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01036e6:	89 90 30 f0 22 f0    	mov    %edx,-0xfdd0fd0(%eax)

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + id] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01036ec:	83 c3 05             	add    $0x5,%ebx
f01036ef:	e8 66 20 00 00       	call   f010575a <cpunum>
f01036f4:	89 c7                	mov    %eax,%edi
f01036f6:	e8 5f 20 00 00       	call   f010575a <cpunum>
f01036fb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036fe:	e8 57 20 00 00       	call   f010575a <cpunum>
f0103703:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f010370a:	f0 67 00 
f010370d:	6b ff 74             	imul   $0x74,%edi,%edi
f0103710:	81 c7 2c f0 22 f0    	add    $0xf022f02c,%edi
f0103716:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f010371d:	f0 
f010371e:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f0103722:	81 c2 2c f0 22 f0    	add    $0xf022f02c,%edx
f0103728:	c1 ea 10             	shr    $0x10,%edx
f010372b:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f0103732:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103739:	40 
f010373a:	6b c0 74             	imul   $0x74,%eax,%eax
f010373d:	05 2c f0 22 f0       	add    $0xf022f02c,%eax
f0103742:	c1 e8 18             	shr    $0x18,%eax
f0103745:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + id].sd_s = 0;
f010374c:	c6 04 dd 45 f3 11 f0 	movb   $0x89,-0xfee0cbb(,%ebx,8)
f0103753:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103754:	89 f0                	mov    %esi,%eax
f0103756:	0f b6 f0             	movzbl %al,%esi
f0103759:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f0103760:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103763:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103768:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (id << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f010376b:	83 c4 1c             	add    $0x1c,%esp
f010376e:	5b                   	pop    %ebx
f010376f:	5e                   	pop    %esi
f0103770:	5f                   	pop    %edi
f0103771:	5d                   	pop    %ebp
f0103772:	c3                   	ret    

f0103773 <trap_init>:
}


void
trap_init(void)
{
f0103773:	55                   	push   %ebp
f0103774:	89 e5                	mov    %esp,%ebp
f0103776:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0103779:	b8 f6 3f 10 f0       	mov    $0xf0103ff6,%eax
f010377e:	66 a3 60 e2 22 f0    	mov    %ax,0xf022e260
f0103784:	66 c7 05 62 e2 22 f0 	movw   $0x8,0xf022e262
f010378b:	08 00 
f010378d:	c6 05 64 e2 22 f0 00 	movb   $0x0,0xf022e264
f0103794:	c6 05 65 e2 22 f0 8e 	movb   $0x8e,0xf022e265
f010379b:	c1 e8 10             	shr    $0x10,%eax
f010379e:	66 a3 66 e2 22 f0    	mov    %ax,0xf022e266
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f01037a4:	b8 fc 3f 10 f0       	mov    $0xf0103ffc,%eax
f01037a9:	66 a3 68 e2 22 f0    	mov    %ax,0xf022e268
f01037af:	66 c7 05 6a e2 22 f0 	movw   $0x8,0xf022e26a
f01037b6:	08 00 
f01037b8:	c6 05 6c e2 22 f0 00 	movb   $0x0,0xf022e26c
f01037bf:	c6 05 6d e2 22 f0 8e 	movb   $0x8e,0xf022e26d
f01037c6:	c1 e8 10             	shr    $0x10,%eax
f01037c9:	66 a3 6e e2 22 f0    	mov    %ax,0xf022e26e
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f01037cf:	b8 02 40 10 f0       	mov    $0xf0104002,%eax
f01037d4:	66 a3 70 e2 22 f0    	mov    %ax,0xf022e270
f01037da:	66 c7 05 72 e2 22 f0 	movw   $0x8,0xf022e272
f01037e1:	08 00 
f01037e3:	c6 05 74 e2 22 f0 00 	movb   $0x0,0xf022e274
f01037ea:	c6 05 75 e2 22 f0 8e 	movb   $0x8e,0xf022e275
f01037f1:	c1 e8 10             	shr    $0x10,%eax
f01037f4:	66 a3 76 e2 22 f0    	mov    %ax,0xf022e276
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f01037fa:	b8 08 40 10 f0       	mov    $0xf0104008,%eax
f01037ff:	66 a3 78 e2 22 f0    	mov    %ax,0xf022e278
f0103805:	66 c7 05 7a e2 22 f0 	movw   $0x8,0xf022e27a
f010380c:	08 00 
f010380e:	c6 05 7c e2 22 f0 00 	movb   $0x0,0xf022e27c
f0103815:	c6 05 7d e2 22 f0 ee 	movb   $0xee,0xf022e27d
f010381c:	c1 e8 10             	shr    $0x10,%eax
f010381f:	66 a3 7e e2 22 f0    	mov    %ax,0xf022e27e
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f0103825:	b8 0e 40 10 f0       	mov    $0xf010400e,%eax
f010382a:	66 a3 80 e2 22 f0    	mov    %ax,0xf022e280
f0103830:	66 c7 05 82 e2 22 f0 	movw   $0x8,0xf022e282
f0103837:	08 00 
f0103839:	c6 05 84 e2 22 f0 00 	movb   $0x0,0xf022e284
f0103840:	c6 05 85 e2 22 f0 8e 	movb   $0x8e,0xf022e285
f0103847:	c1 e8 10             	shr    $0x10,%eax
f010384a:	66 a3 86 e2 22 f0    	mov    %ax,0xf022e286
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f0103850:	b8 14 40 10 f0       	mov    $0xf0104014,%eax
f0103855:	66 a3 88 e2 22 f0    	mov    %ax,0xf022e288
f010385b:	66 c7 05 8a e2 22 f0 	movw   $0x8,0xf022e28a
f0103862:	08 00 
f0103864:	c6 05 8c e2 22 f0 00 	movb   $0x0,0xf022e28c
f010386b:	c6 05 8d e2 22 f0 8e 	movb   $0x8e,0xf022e28d
f0103872:	c1 e8 10             	shr    $0x10,%eax
f0103875:	66 a3 8e e2 22 f0    	mov    %ax,0xf022e28e
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f010387b:	b8 1a 40 10 f0       	mov    $0xf010401a,%eax
f0103880:	66 a3 90 e2 22 f0    	mov    %ax,0xf022e290
f0103886:	66 c7 05 92 e2 22 f0 	movw   $0x8,0xf022e292
f010388d:	08 00 
f010388f:	c6 05 94 e2 22 f0 00 	movb   $0x0,0xf022e294
f0103896:	c6 05 95 e2 22 f0 8e 	movb   $0x8e,0xf022e295
f010389d:	c1 e8 10             	shr    $0x10,%eax
f01038a0:	66 a3 96 e2 22 f0    	mov    %ax,0xf022e296
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f01038a6:	b8 20 40 10 f0       	mov    $0xf0104020,%eax
f01038ab:	66 a3 98 e2 22 f0    	mov    %ax,0xf022e298
f01038b1:	66 c7 05 9a e2 22 f0 	movw   $0x8,0xf022e29a
f01038b8:	08 00 
f01038ba:	c6 05 9c e2 22 f0 00 	movb   $0x0,0xf022e29c
f01038c1:	c6 05 9d e2 22 f0 8e 	movb   $0x8e,0xf022e29d
f01038c8:	c1 e8 10             	shr    $0x10,%eax
f01038cb:	66 a3 9e e2 22 f0    	mov    %ax,0xf022e29e
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01038d1:	b8 26 40 10 f0       	mov    $0xf0104026,%eax
f01038d6:	66 a3 a0 e2 22 f0    	mov    %ax,0xf022e2a0
f01038dc:	66 c7 05 a2 e2 22 f0 	movw   $0x8,0xf022e2a2
f01038e3:	08 00 
f01038e5:	c6 05 a4 e2 22 f0 00 	movb   $0x0,0xf022e2a4
f01038ec:	c6 05 a5 e2 22 f0 8e 	movb   $0x8e,0xf022e2a5
f01038f3:	c1 e8 10             	shr    $0x10,%eax
f01038f6:	66 a3 a6 e2 22 f0    	mov    %ax,0xf022e2a6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f01038fc:	b8 2a 40 10 f0       	mov    $0xf010402a,%eax
f0103901:	66 a3 b0 e2 22 f0    	mov    %ax,0xf022e2b0
f0103907:	66 c7 05 b2 e2 22 f0 	movw   $0x8,0xf022e2b2
f010390e:	08 00 
f0103910:	c6 05 b4 e2 22 f0 00 	movb   $0x0,0xf022e2b4
f0103917:	c6 05 b5 e2 22 f0 8e 	movb   $0x8e,0xf022e2b5
f010391e:	c1 e8 10             	shr    $0x10,%eax
f0103921:	66 a3 b6 e2 22 f0    	mov    %ax,0xf022e2b6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f0103927:	b8 2e 40 10 f0       	mov    $0xf010402e,%eax
f010392c:	66 a3 b8 e2 22 f0    	mov    %ax,0xf022e2b8
f0103932:	66 c7 05 ba e2 22 f0 	movw   $0x8,0xf022e2ba
f0103939:	08 00 
f010393b:	c6 05 bc e2 22 f0 00 	movb   $0x0,0xf022e2bc
f0103942:	c6 05 bd e2 22 f0 8e 	movb   $0x8e,0xf022e2bd
f0103949:	c1 e8 10             	shr    $0x10,%eax
f010394c:	66 a3 be e2 22 f0    	mov    %ax,0xf022e2be
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f0103952:	b8 32 40 10 f0       	mov    $0xf0104032,%eax
f0103957:	66 a3 c0 e2 22 f0    	mov    %ax,0xf022e2c0
f010395d:	66 c7 05 c2 e2 22 f0 	movw   $0x8,0xf022e2c2
f0103964:	08 00 
f0103966:	c6 05 c4 e2 22 f0 00 	movb   $0x0,0xf022e2c4
f010396d:	c6 05 c5 e2 22 f0 8e 	movb   $0x8e,0xf022e2c5
f0103974:	c1 e8 10             	shr    $0x10,%eax
f0103977:	66 a3 c6 e2 22 f0    	mov    %ax,0xf022e2c6
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f010397d:	b8 36 40 10 f0       	mov    $0xf0104036,%eax
f0103982:	66 a3 c8 e2 22 f0    	mov    %ax,0xf022e2c8
f0103988:	66 c7 05 ca e2 22 f0 	movw   $0x8,0xf022e2ca
f010398f:	08 00 
f0103991:	c6 05 cc e2 22 f0 00 	movb   $0x0,0xf022e2cc
f0103998:	c6 05 cd e2 22 f0 8e 	movb   $0x8e,0xf022e2cd
f010399f:	c1 e8 10             	shr    $0x10,%eax
f01039a2:	66 a3 ce e2 22 f0    	mov    %ax,0xf022e2ce
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f01039a8:	b8 3a 40 10 f0       	mov    $0xf010403a,%eax
f01039ad:	66 a3 d0 e2 22 f0    	mov    %ax,0xf022e2d0
f01039b3:	66 c7 05 d2 e2 22 f0 	movw   $0x8,0xf022e2d2
f01039ba:	08 00 
f01039bc:	c6 05 d4 e2 22 f0 00 	movb   $0x0,0xf022e2d4
f01039c3:	c6 05 d5 e2 22 f0 8e 	movb   $0x8e,0xf022e2d5
f01039ca:	c1 e8 10             	shr    $0x10,%eax
f01039cd:	66 a3 d6 e2 22 f0    	mov    %ax,0xf022e2d6
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01039d3:	b8 3e 40 10 f0       	mov    $0xf010403e,%eax
f01039d8:	66 a3 e0 e2 22 f0    	mov    %ax,0xf022e2e0
f01039de:	66 c7 05 e2 e2 22 f0 	movw   $0x8,0xf022e2e2
f01039e5:	08 00 
f01039e7:	c6 05 e4 e2 22 f0 00 	movb   $0x0,0xf022e2e4
f01039ee:	c6 05 e5 e2 22 f0 8e 	movb   $0x8e,0xf022e2e5
f01039f5:	c1 e8 10             	shr    $0x10,%eax
f01039f8:	66 a3 e6 e2 22 f0    	mov    %ax,0xf022e2e6
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f01039fe:	b8 44 40 10 f0       	mov    $0xf0104044,%eax
f0103a03:	66 a3 e8 e2 22 f0    	mov    %ax,0xf022e2e8
f0103a09:	66 c7 05 ea e2 22 f0 	movw   $0x8,0xf022e2ea
f0103a10:	08 00 
f0103a12:	c6 05 ec e2 22 f0 00 	movb   $0x0,0xf022e2ec
f0103a19:	c6 05 ed e2 22 f0 8e 	movb   $0x8e,0xf022e2ed
f0103a20:	c1 e8 10             	shr    $0x10,%eax
f0103a23:	66 a3 ee e2 22 f0    	mov    %ax,0xf022e2ee
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103a29:	b8 48 40 10 f0       	mov    $0xf0104048,%eax
f0103a2e:	66 a3 f0 e2 22 f0    	mov    %ax,0xf022e2f0
f0103a34:	66 c7 05 f2 e2 22 f0 	movw   $0x8,0xf022e2f2
f0103a3b:	08 00 
f0103a3d:	c6 05 f4 e2 22 f0 00 	movb   $0x0,0xf022e2f4
f0103a44:	c6 05 f5 e2 22 f0 8e 	movb   $0x8e,0xf022e2f5
f0103a4b:	c1 e8 10             	shr    $0x10,%eax
f0103a4e:	66 a3 f6 e2 22 f0    	mov    %ax,0xf022e2f6
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103a54:	b8 4e 40 10 f0       	mov    $0xf010404e,%eax
f0103a59:	66 a3 f8 e2 22 f0    	mov    %ax,0xf022e2f8
f0103a5f:	66 c7 05 fa e2 22 f0 	movw   $0x8,0xf022e2fa
f0103a66:	08 00 
f0103a68:	c6 05 fc e2 22 f0 00 	movb   $0x0,0xf022e2fc
f0103a6f:	c6 05 fd e2 22 f0 8e 	movb   $0x8e,0xf022e2fd
f0103a76:	c1 e8 10             	shr    $0x10,%eax
f0103a79:	66 a3 fe e2 22 f0    	mov    %ax,0xf022e2fe
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f0103a7f:	b8 54 40 10 f0       	mov    $0xf0104054,%eax
f0103a84:	66 a3 e0 e3 22 f0    	mov    %ax,0xf022e3e0
f0103a8a:	66 c7 05 e2 e3 22 f0 	movw   $0x8,0xf022e3e2
f0103a91:	08 00 
f0103a93:	c6 05 e4 e3 22 f0 00 	movb   $0x0,0xf022e3e4
f0103a9a:	c6 05 e5 e3 22 f0 ef 	movb   $0xef,0xf022e3e5
f0103aa1:	c1 e8 10             	shr    $0x10,%eax
f0103aa4:	66 a3 e6 e3 22 f0    	mov    %ax,0xf022e3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103aaa:	e8 e3 fb ff ff       	call   f0103692 <trap_init_percpu>
}
f0103aaf:	c9                   	leave  
f0103ab0:	c3                   	ret    

f0103ab1 <print_regs>:
	}
}

void	
print_regs(struct PushRegs *regs)
{
f0103ab1:	55                   	push   %ebp
f0103ab2:	89 e5                	mov    %esp,%ebp
f0103ab4:	53                   	push   %ebx
f0103ab5:	83 ec 0c             	sub    $0xc,%esp
f0103ab8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103abb:	ff 33                	pushl  (%ebx)
f0103abd:	68 07 71 10 f0       	push   $0xf0107107
f0103ac2:	e8 b7 fb ff ff       	call   f010367e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ac7:	83 c4 08             	add    $0x8,%esp
f0103aca:	ff 73 04             	pushl  0x4(%ebx)
f0103acd:	68 16 71 10 f0       	push   $0xf0107116
f0103ad2:	e8 a7 fb ff ff       	call   f010367e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ad7:	83 c4 08             	add    $0x8,%esp
f0103ada:	ff 73 08             	pushl  0x8(%ebx)
f0103add:	68 25 71 10 f0       	push   $0xf0107125
f0103ae2:	e8 97 fb ff ff       	call   f010367e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103ae7:	83 c4 08             	add    $0x8,%esp
f0103aea:	ff 73 0c             	pushl  0xc(%ebx)
f0103aed:	68 34 71 10 f0       	push   $0xf0107134
f0103af2:	e8 87 fb ff ff       	call   f010367e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103af7:	83 c4 08             	add    $0x8,%esp
f0103afa:	ff 73 10             	pushl  0x10(%ebx)
f0103afd:	68 43 71 10 f0       	push   $0xf0107143
f0103b02:	e8 77 fb ff ff       	call   f010367e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b07:	83 c4 08             	add    $0x8,%esp
f0103b0a:	ff 73 14             	pushl  0x14(%ebx)
f0103b0d:	68 52 71 10 f0       	push   $0xf0107152
f0103b12:	e8 67 fb ff ff       	call   f010367e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b17:	83 c4 08             	add    $0x8,%esp
f0103b1a:	ff 73 18             	pushl  0x18(%ebx)
f0103b1d:	68 61 71 10 f0       	push   $0xf0107161
f0103b22:	e8 57 fb ff ff       	call   f010367e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b27:	83 c4 08             	add    $0x8,%esp
f0103b2a:	ff 73 1c             	pushl  0x1c(%ebx)
f0103b2d:	68 70 71 10 f0       	push   $0xf0107170
f0103b32:	e8 47 fb ff ff       	call   f010367e <cprintf>
}
f0103b37:	83 c4 10             	add    $0x10,%esp
f0103b3a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b3d:	c9                   	leave  
f0103b3e:	c3                   	ret    

f0103b3f <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b3f:	55                   	push   %ebp
f0103b40:	89 e5                	mov    %esp,%ebp
f0103b42:	56                   	push   %esi
f0103b43:	53                   	push   %ebx
f0103b44:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103b47:	e8 0e 1c 00 00       	call   f010575a <cpunum>
f0103b4c:	83 ec 04             	sub    $0x4,%esp
f0103b4f:	50                   	push   %eax
f0103b50:	53                   	push   %ebx
f0103b51:	68 d4 71 10 f0       	push   $0xf01071d4
f0103b56:	e8 23 fb ff ff       	call   f010367e <cprintf>
	print_regs(&tf->tf_regs);
f0103b5b:	89 1c 24             	mov    %ebx,(%esp)
f0103b5e:	e8 4e ff ff ff       	call   f0103ab1 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b63:	83 c4 08             	add    $0x8,%esp
f0103b66:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b6a:	50                   	push   %eax
f0103b6b:	68 f2 71 10 f0       	push   $0xf01071f2
f0103b70:	e8 09 fb ff ff       	call   f010367e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b75:	83 c4 08             	add    $0x8,%esp
f0103b78:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b7c:	50                   	push   %eax
f0103b7d:	68 05 72 10 f0       	push   $0xf0107205
f0103b82:	e8 f7 fa ff ff       	call   f010367e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b87:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103b8a:	83 c4 10             	add    $0x10,%esp
f0103b8d:	83 f8 13             	cmp    $0x13,%eax
f0103b90:	77 09                	ja     f0103b9b <print_trapframe+0x5c>
		return excnames[trapno];
f0103b92:	8b 14 85 a0 74 10 f0 	mov    -0xfef8b60(,%eax,4),%edx
f0103b99:	eb 1f                	jmp    f0103bba <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b9b:	83 f8 30             	cmp    $0x30,%eax
f0103b9e:	74 15                	je     f0103bb5 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ba0:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ba3:	83 fa 10             	cmp    $0x10,%edx
f0103ba6:	b9 9e 71 10 f0       	mov    $0xf010719e,%ecx
f0103bab:	ba 8b 71 10 f0       	mov    $0xf010718b,%edx
f0103bb0:	0f 43 d1             	cmovae %ecx,%edx
f0103bb3:	eb 05                	jmp    f0103bba <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103bb5:	ba 7f 71 10 f0       	mov    $0xf010717f,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bba:	83 ec 04             	sub    $0x4,%esp
f0103bbd:	52                   	push   %edx
f0103bbe:	50                   	push   %eax
f0103bbf:	68 18 72 10 f0       	push   $0xf0107218
f0103bc4:	e8 b5 fa ff ff       	call   f010367e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bc9:	83 c4 10             	add    $0x10,%esp
f0103bcc:	3b 1d 60 ea 22 f0    	cmp    0xf022ea60,%ebx
f0103bd2:	75 1a                	jne    f0103bee <print_trapframe+0xaf>
f0103bd4:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bd8:	75 14                	jne    f0103bee <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103bda:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103bdd:	83 ec 08             	sub    $0x8,%esp
f0103be0:	50                   	push   %eax
f0103be1:	68 2a 72 10 f0       	push   $0xf010722a
f0103be6:	e8 93 fa ff ff       	call   f010367e <cprintf>
f0103beb:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103bee:	83 ec 08             	sub    $0x8,%esp
f0103bf1:	ff 73 2c             	pushl  0x2c(%ebx)
f0103bf4:	68 39 72 10 f0       	push   $0xf0107239
f0103bf9:	e8 80 fa ff ff       	call   f010367e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bfe:	83 c4 10             	add    $0x10,%esp
f0103c01:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c05:	75 49                	jne    f0103c50 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c07:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c0a:	89 c2                	mov    %eax,%edx
f0103c0c:	83 e2 01             	and    $0x1,%edx
f0103c0f:	ba b8 71 10 f0       	mov    $0xf01071b8,%edx
f0103c14:	b9 ad 71 10 f0       	mov    $0xf01071ad,%ecx
f0103c19:	0f 44 ca             	cmove  %edx,%ecx
f0103c1c:	89 c2                	mov    %eax,%edx
f0103c1e:	83 e2 02             	and    $0x2,%edx
f0103c21:	ba ca 71 10 f0       	mov    $0xf01071ca,%edx
f0103c26:	be c4 71 10 f0       	mov    $0xf01071c4,%esi
f0103c2b:	0f 45 d6             	cmovne %esi,%edx
f0103c2e:	83 e0 04             	and    $0x4,%eax
f0103c31:	be 17 73 10 f0       	mov    $0xf0107317,%esi
f0103c36:	b8 cf 71 10 f0       	mov    $0xf01071cf,%eax
f0103c3b:	0f 44 c6             	cmove  %esi,%eax
f0103c3e:	51                   	push   %ecx
f0103c3f:	52                   	push   %edx
f0103c40:	50                   	push   %eax
f0103c41:	68 47 72 10 f0       	push   $0xf0107247
f0103c46:	e8 33 fa ff ff       	call   f010367e <cprintf>
f0103c4b:	83 c4 10             	add    $0x10,%esp
f0103c4e:	eb 10                	jmp    f0103c60 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c50:	83 ec 0c             	sub    $0xc,%esp
f0103c53:	68 bc 61 10 f0       	push   $0xf01061bc
f0103c58:	e8 21 fa ff ff       	call   f010367e <cprintf>
f0103c5d:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c60:	83 ec 08             	sub    $0x8,%esp
f0103c63:	ff 73 30             	pushl  0x30(%ebx)
f0103c66:	68 56 72 10 f0       	push   $0xf0107256
f0103c6b:	e8 0e fa ff ff       	call   f010367e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c70:	83 c4 08             	add    $0x8,%esp
f0103c73:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c77:	50                   	push   %eax
f0103c78:	68 65 72 10 f0       	push   $0xf0107265
f0103c7d:	e8 fc f9 ff ff       	call   f010367e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c82:	83 c4 08             	add    $0x8,%esp
f0103c85:	ff 73 38             	pushl  0x38(%ebx)
f0103c88:	68 78 72 10 f0       	push   $0xf0107278
f0103c8d:	e8 ec f9 ff ff       	call   f010367e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c92:	83 c4 10             	add    $0x10,%esp
f0103c95:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c99:	74 25                	je     f0103cc0 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c9b:	83 ec 08             	sub    $0x8,%esp
f0103c9e:	ff 73 3c             	pushl  0x3c(%ebx)
f0103ca1:	68 87 72 10 f0       	push   $0xf0107287
f0103ca6:	e8 d3 f9 ff ff       	call   f010367e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103cab:	83 c4 08             	add    $0x8,%esp
f0103cae:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103cb2:	50                   	push   %eax
f0103cb3:	68 96 72 10 f0       	push   $0xf0107296
f0103cb8:	e8 c1 f9 ff ff       	call   f010367e <cprintf>
f0103cbd:	83 c4 10             	add    $0x10,%esp
	}
}
f0103cc0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103cc3:	5b                   	pop    %ebx
f0103cc4:	5e                   	pop    %esi
f0103cc5:	5d                   	pop    %ebp
f0103cc6:	c3                   	ret    

f0103cc7 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cc7:	55                   	push   %ebp
f0103cc8:	89 e5                	mov    %esp,%ebp
f0103cca:	57                   	push   %edi
f0103ccb:	56                   	push   %esi
f0103ccc:	53                   	push   %ebx
f0103ccd:	83 ec 1c             	sub    $0x1c,%esp
f0103cd0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cd3:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f0103cd6:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103cda:	75 17                	jne    f0103cf3 <page_fault_handler+0x2c>
		panic("Kernel page fault!");	
f0103cdc:	83 ec 04             	sub    $0x4,%esp
f0103cdf:	68 a9 72 10 f0       	push   $0xf01072a9
f0103ce4:	68 38 01 00 00       	push   $0x138
f0103ce9:	68 bc 72 10 f0       	push   $0xf01072bc
f0103cee:	e8 4d c3 ff ff       	call   f0100040 <_panic>
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
f0103cf3:	e8 62 1a 00 00       	call   f010575a <cpunum>
f0103cf8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cfb:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103d01:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103d05:	0f 84 92 00 00 00    	je     f0103d9d <page_fault_handler+0xd6>
	{
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
		
		if(tf->tf_esp > USTACKTOP)
f0103d0b:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103d0e:	3d 00 e0 bf ee       	cmp    $0xeebfe000,%eax
f0103d13:	76 0d                	jbe    f0103d22 <page_fault_handler+0x5b>
		{
			size += 4;
			userTF = (struct UTrapframe*) (tf->tf_esp - size);
f0103d15:	83 e8 38             	sub    $0x38,%eax
f0103d18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
		
		if(tf->tf_esp > USTACKTOP)
		{
			size += 4;
f0103d1b:	bf 38 00 00 00       	mov    $0x38,%edi
f0103d20:	eb 0c                	jmp    f0103d2e <page_fault_handler+0x67>

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
	{
		size_t size = sizeof(struct UTrapframe);
		struct UTrapframe  *userTF = (struct UTrapframe*) (UXSTACKTOP - size);
f0103d22:	c7 45 e4 cc ff bf ee 	movl   $0xeebfffcc,-0x1c(%ebp)
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall)
	{
		size_t size = sizeof(struct UTrapframe);
f0103d29:	bf 34 00 00 00       	mov    $0x34,%edi
		{
			size += 4;
			userTF = (struct UTrapframe*) (tf->tf_esp - size);
		}

		user_mem_assert(curenv, (void *) userTF, size, (PTE_U | PTE_W));
f0103d2e:	e8 27 1a 00 00       	call   f010575a <cpunum>
f0103d33:	6a 06                	push   $0x6
f0103d35:	57                   	push   %edi
f0103d36:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d39:	57                   	push   %edi
f0103d3a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d3d:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103d43:	e8 1e f0 ff ff       	call   f0102d66 <user_mem_assert>

		userTF->utf_fault_va = fault_va;
f0103d48:	89 37                	mov    %esi,(%edi)
		userTF->utf_err = tf->tf_err; 
f0103d4a:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103d4d:	89 fa                	mov    %edi,%edx
f0103d4f:	89 47 04             	mov    %eax,0x4(%edi)
		userTF->utf_regs = tf->tf_regs;
f0103d52:	8d 7f 08             	lea    0x8(%edi),%edi
f0103d55:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103d5a:	89 de                	mov    %ebx,%esi
f0103d5c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		userTF->utf_eip = tf->tf_eip; 
f0103d5e:	8b 43 30             	mov    0x30(%ebx),%eax
f0103d61:	89 42 28             	mov    %eax,0x28(%edx)
		userTF->utf_eflags = tf->tf_eflags; 
f0103d64:	8b 43 38             	mov    0x38(%ebx),%eax
f0103d67:	89 42 2c             	mov    %eax,0x2c(%edx)
		userTF->utf_esp = tf->tf_esp;
f0103d6a:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103d6d:	89 42 30             	mov    %eax,0x30(%edx)

		tf->tf_esp = (uint32_t) userTF;
f0103d70:	89 53 3c             	mov    %edx,0x3c(%ebx)
		tf->tf_eip = (uint32_t) curenv->env_pgfault_upcall;
f0103d73:	e8 e2 19 00 00       	call   f010575a <cpunum>
f0103d78:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d7b:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103d81:	8b 40 64             	mov    0x64(%eax),%eax
f0103d84:	89 43 30             	mov    %eax,0x30(%ebx)

		env_run(curenv);		
f0103d87:	e8 ce 19 00 00       	call   f010575a <cpunum>
f0103d8c:	83 c4 04             	add    $0x4,%esp
f0103d8f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d92:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103d98:	e8 c7 f6 ff ff       	call   f0103464 <env_run>
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d9d:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103da0:	e8 b5 19 00 00       	call   f010575a <cpunum>

		env_run(curenv);		
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103da5:	57                   	push   %edi
f0103da6:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103da7:	6b c0 74             	imul   $0x74,%eax,%eax

		env_run(curenv);		
	}
	
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103daa:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103db0:	ff 70 48             	pushl  0x48(%eax)
f0103db3:	68 64 74 10 f0       	push   $0xf0107464
f0103db8:	e8 c1 f8 ff ff       	call   f010367e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103dbd:	89 1c 24             	mov    %ebx,(%esp)
f0103dc0:	e8 7a fd ff ff       	call   f0103b3f <print_trapframe>
	env_destroy(curenv);
f0103dc5:	e8 90 19 00 00       	call   f010575a <cpunum>
f0103dca:	83 c4 04             	add    $0x4,%esp
f0103dcd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd0:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103dd6:	e8 ea f5 ff ff       	call   f01033c5 <env_destroy>
}
f0103ddb:	83 c4 10             	add    $0x10,%esp
f0103dde:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103de1:	5b                   	pop    %ebx
f0103de2:	5e                   	pop    %esi
f0103de3:	5f                   	pop    %edi
f0103de4:	5d                   	pop    %ebp
f0103de5:	c3                   	ret    

f0103de6 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103de6:	55                   	push   %ebp
f0103de7:	89 e5                	mov    %esp,%ebp
f0103de9:	57                   	push   %edi
f0103dea:	56                   	push   %esi
f0103deb:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103dee:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103def:	83 3d 80 ee 22 f0 00 	cmpl   $0x0,0xf022ee80
f0103df6:	74 01                	je     f0103df9 <trap+0x13>
		asm volatile("hlt");
f0103df8:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103df9:	e8 5c 19 00 00       	call   f010575a <cpunum>
f0103dfe:	6b d0 74             	imul   $0x74,%eax,%edx
f0103e01:	81 c2 20 f0 22 f0    	add    $0xf022f020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103e07:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e0c:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103e10:	83 f8 02             	cmp    $0x2,%eax
f0103e13:	75 10                	jne    f0103e25 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103e15:	83 ec 0c             	sub    $0xc,%esp
f0103e18:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103e1d:	e8 a6 1b 00 00       	call   f01059c8 <spin_lock>
f0103e22:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103e25:	9c                   	pushf  
f0103e26:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103e27:	f6 c4 02             	test   $0x2,%ah
f0103e2a:	74 19                	je     f0103e45 <trap+0x5f>
f0103e2c:	68 c8 72 10 f0       	push   $0xf01072c8
f0103e31:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0103e36:	68 02 01 00 00       	push   $0x102
f0103e3b:	68 bc 72 10 f0       	push   $0xf01072bc
f0103e40:	e8 fb c1 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103e45:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103e49:	83 e0 03             	and    $0x3,%eax
f0103e4c:	66 83 f8 03          	cmp    $0x3,%ax
f0103e50:	0f 85 a0 00 00 00    	jne    f0103ef6 <trap+0x110>
f0103e56:	83 ec 0c             	sub    $0xc,%esp
f0103e59:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103e5e:	e8 65 1b 00 00       	call   f01059c8 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103e63:	e8 f2 18 00 00       	call   f010575a <cpunum>
f0103e68:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e6b:	83 c4 10             	add    $0x10,%esp
f0103e6e:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103e75:	75 19                	jne    f0103e90 <trap+0xaa>
f0103e77:	68 e1 72 10 f0       	push   $0xf01072e1
f0103e7c:	68 6b 6d 10 f0       	push   $0xf0106d6b
f0103e81:	68 0a 01 00 00       	push   $0x10a
f0103e86:	68 bc 72 10 f0       	push   $0xf01072bc
f0103e8b:	e8 b0 c1 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103e90:	e8 c5 18 00 00       	call   f010575a <cpunum>
f0103e95:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e98:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103e9e:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103ea2:	75 2d                	jne    f0103ed1 <trap+0xeb>
			env_free(curenv);
f0103ea4:	e8 b1 18 00 00       	call   f010575a <cpunum>
f0103ea9:	83 ec 0c             	sub    $0xc,%esp
f0103eac:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eaf:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103eb5:	e8 30 f3 ff ff       	call   f01031ea <env_free>
			curenv = NULL;
f0103eba:	e8 9b 18 00 00       	call   f010575a <cpunum>
f0103ebf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ec2:	c7 80 28 f0 22 f0 00 	movl   $0x0,-0xfdd0fd8(%eax)
f0103ec9:	00 00 00 
			sched_yield();
f0103ecc:	e8 6e 02 00 00       	call   f010413f <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103ed1:	e8 84 18 00 00       	call   f010575a <cpunum>
f0103ed6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ed9:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103edf:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103ee4:	89 c7                	mov    %eax,%edi
f0103ee6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103ee8:	e8 6d 18 00 00       	call   f010575a <cpunum>
f0103eed:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef0:	8b b0 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103ef6:	89 35 60 ea 22 f0    	mov    %esi,0xf022ea60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f0103efc:	8b 46 28             	mov    0x28(%esi),%eax
f0103eff:	83 f8 0e             	cmp    $0xe,%eax
f0103f02:	74 0c                	je     f0103f10 <trap+0x12a>
f0103f04:	83 f8 30             	cmp    $0x30,%eax
f0103f07:	74 29                	je     f0103f32 <trap+0x14c>
f0103f09:	83 f8 03             	cmp    $0x3,%eax
f0103f0c:	75 45                	jne    f0103f53 <trap+0x16d>
f0103f0e:	eb 11                	jmp    f0103f21 <trap+0x13b>
	{
		case T_PGFLT: 	  page_fault_handler(tf); 	return;
f0103f10:	83 ec 0c             	sub    $0xc,%esp
f0103f13:	56                   	push   %esi
f0103f14:	e8 ae fd ff ff       	call   f0103cc7 <page_fault_handler>
f0103f19:	83 c4 10             	add    $0x10,%esp
f0103f1c:	e9 94 00 00 00       	jmp    f0103fb5 <trap+0x1cf>

		case T_BRKPT:     monitor(tf);			return;
f0103f21:	83 ec 0c             	sub    $0xc,%esp
f0103f24:	56                   	push   %esi
f0103f25:	e8 2e ca ff ff       	call   f0100958 <monitor>
f0103f2a:	83 c4 10             	add    $0x10,%esp
f0103f2d:	e9 83 00 00 00       	jmp    f0103fb5 <trap+0x1cf>

		case T_SYSCALL:	  
				tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
f0103f32:	83 ec 08             	sub    $0x8,%esp
f0103f35:	ff 76 04             	pushl  0x4(%esi)
f0103f38:	ff 36                	pushl  (%esi)
f0103f3a:	ff 76 10             	pushl  0x10(%esi)
f0103f3d:	ff 76 18             	pushl  0x18(%esi)
f0103f40:	ff 76 14             	pushl  0x14(%esi)
f0103f43:	ff 76 1c             	pushl  0x1c(%esi)
f0103f46:	e8 a8 02 00 00       	call   f01041f3 <syscall>
f0103f4b:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103f4e:	83 c4 20             	add    $0x20,%esp
f0103f51:	eb 62                	jmp    f0103fb5 <trap+0x1cf>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103f53:	83 f8 27             	cmp    $0x27,%eax
f0103f56:	75 1a                	jne    f0103f72 <trap+0x18c>
		cprintf("Spurious interrupt on irq 7\n");
f0103f58:	83 ec 0c             	sub    $0xc,%esp
f0103f5b:	68 e8 72 10 f0       	push   $0xf01072e8
f0103f60:	e8 19 f7 ff ff       	call   f010367e <cprintf>
		print_trapframe(tf);
f0103f65:	89 34 24             	mov    %esi,(%esp)
f0103f68:	e8 d2 fb ff ff       	call   f0103b3f <print_trapframe>
f0103f6d:	83 c4 10             	add    $0x10,%esp
f0103f70:	eb 43                	jmp    f0103fb5 <trap+0x1cf>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103f72:	83 ec 0c             	sub    $0xc,%esp
f0103f75:	56                   	push   %esi
f0103f76:	e8 c4 fb ff ff       	call   f0103b3f <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103f7b:	83 c4 10             	add    $0x10,%esp
f0103f7e:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103f83:	75 17                	jne    f0103f9c <trap+0x1b6>
		panic("unhandled trap in kernel");
f0103f85:	83 ec 04             	sub    $0x4,%esp
f0103f88:	68 05 73 10 f0       	push   $0xf0107305
f0103f8d:	68 e8 00 00 00       	push   $0xe8
f0103f92:	68 bc 72 10 f0       	push   $0xf01072bc
f0103f97:	e8 a4 c0 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103f9c:	e8 b9 17 00 00       	call   f010575a <cpunum>
f0103fa1:	83 ec 0c             	sub    $0xc,%esp
f0103fa4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fa7:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103fad:	e8 13 f4 ff ff       	call   f01033c5 <env_destroy>
f0103fb2:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103fb5:	e8 a0 17 00 00       	call   f010575a <cpunum>
f0103fba:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fbd:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103fc4:	74 2a                	je     f0103ff0 <trap+0x20a>
f0103fc6:	e8 8f 17 00 00       	call   f010575a <cpunum>
f0103fcb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fce:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103fd4:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103fd8:	75 16                	jne    f0103ff0 <trap+0x20a>
		env_run(curenv);
f0103fda:	e8 7b 17 00 00       	call   f010575a <cpunum>
f0103fdf:	83 ec 0c             	sub    $0xc,%esp
f0103fe2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fe5:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103feb:	e8 74 f4 ff ff       	call   f0103464 <env_run>
	else
		sched_yield();
f0103ff0:	e8 4a 01 00 00       	call   f010413f <sched_yield>
f0103ff5:	90                   	nop

f0103ff6 <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f0103ff6:	6a 00                	push   $0x0
f0103ff8:	6a 00                	push   $0x0
f0103ffa:	eb 5e                	jmp    f010405a <_alltraps>

f0103ffc <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f0103ffc:	6a 00                	push   $0x0
f0103ffe:	6a 01                	push   $0x1
f0104000:	eb 58                	jmp    f010405a <_alltraps>

f0104002 <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f0104002:	6a 00                	push   $0x0
f0104004:	6a 02                	push   $0x2
f0104006:	eb 52                	jmp    f010405a <_alltraps>

f0104008 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f0104008:	6a 00                	push   $0x0
f010400a:	6a 03                	push   $0x3
f010400c:	eb 4c                	jmp    f010405a <_alltraps>

f010400e <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f010400e:	6a 00                	push   $0x0
f0104010:	6a 04                	push   $0x4
f0104012:	eb 46                	jmp    f010405a <_alltraps>

f0104014 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f0104014:	6a 00                	push   $0x0
f0104016:	6a 05                	push   $0x5
f0104018:	eb 40                	jmp    f010405a <_alltraps>

f010401a <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f010401a:	6a 00                	push   $0x0
f010401c:	6a 06                	push   $0x6
f010401e:	eb 3a                	jmp    f010405a <_alltraps>

f0104020 <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f0104020:	6a 00                	push   $0x0
f0104022:	6a 07                	push   $0x7
f0104024:	eb 34                	jmp    f010405a <_alltraps>

f0104026 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f0104026:	6a 08                	push   $0x8
f0104028:	eb 30                	jmp    f010405a <_alltraps>

f010402a <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f010402a:	6a 0a                	push   $0xa
f010402c:	eb 2c                	jmp    f010405a <_alltraps>

f010402e <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f010402e:	6a 0b                	push   $0xb
f0104030:	eb 28                	jmp    f010405a <_alltraps>

f0104032 <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f0104032:	6a 0c                	push   $0xc
f0104034:	eb 24                	jmp    f010405a <_alltraps>

f0104036 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f0104036:	6a 0d                	push   $0xd
f0104038:	eb 20                	jmp    f010405a <_alltraps>

f010403a <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f010403a:	6a 0e                	push   $0xe
f010403c:	eb 1c                	jmp    f010405a <_alltraps>

f010403e <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f010403e:	6a 00                	push   $0x0
f0104040:	6a 10                	push   $0x10
f0104042:	eb 16                	jmp    f010405a <_alltraps>

f0104044 <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f0104044:	6a 11                	push   $0x11
f0104046:	eb 12                	jmp    f010405a <_alltraps>

f0104048 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f0104048:	6a 00                	push   $0x0
f010404a:	6a 12                	push   $0x12
f010404c:	eb 0c                	jmp    f010405a <_alltraps>

f010404e <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f010404e:	6a 00                	push   $0x0
f0104050:	6a 13                	push   $0x13
f0104052:	eb 06                	jmp    f010405a <_alltraps>

f0104054 <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f0104054:	6a 00                	push   $0x0
f0104056:	6a 30                	push   $0x30
f0104058:	eb 00                	jmp    f010405a <_alltraps>

f010405a <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f010405a:	1e                   	push   %ds
	pushl	%es
f010405b:	06                   	push   %es
	pushal
f010405c:	60                   	pusha  
	mov	$GD_KD, %eax
f010405d:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f0104062:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f0104064:	8e d8                	mov    %eax,%ds
	pushl	%esp
f0104066:	54                   	push   %esp
	call	trap
f0104067:	e8 7a fd ff ff       	call   f0103de6 <trap>

f010406c <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010406c:	55                   	push   %ebp
f010406d:	89 e5                	mov    %esp,%ebp
f010406f:	83 ec 08             	sub    $0x8,%esp
f0104072:	a1 44 e2 22 f0       	mov    0xf022e244,%eax
f0104077:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010407a:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010407f:	8b 02                	mov    (%edx),%eax
f0104081:	83 e8 01             	sub    $0x1,%eax
f0104084:	83 f8 02             	cmp    $0x2,%eax
f0104087:	76 10                	jbe    f0104099 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104089:	83 c1 01             	add    $0x1,%ecx
f010408c:	83 c2 7c             	add    $0x7c,%edx
f010408f:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104095:	75 e8                	jne    f010407f <sched_halt+0x13>
f0104097:	eb 08                	jmp    f01040a1 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104099:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010409f:	75 1f                	jne    f01040c0 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f01040a1:	83 ec 0c             	sub    $0xc,%esp
f01040a4:	68 f0 74 10 f0       	push   $0xf01074f0
f01040a9:	e8 d0 f5 ff ff       	call   f010367e <cprintf>
f01040ae:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01040b1:	83 ec 0c             	sub    $0xc,%esp
f01040b4:	6a 00                	push   $0x0
f01040b6:	e8 9d c8 ff ff       	call   f0100958 <monitor>
f01040bb:	83 c4 10             	add    $0x10,%esp
f01040be:	eb f1                	jmp    f01040b1 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01040c0:	e8 95 16 00 00       	call   f010575a <cpunum>
f01040c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01040c8:	c7 80 28 f0 22 f0 00 	movl   $0x0,-0xfdd0fd8(%eax)
f01040cf:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01040d2:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01040d7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01040dc:	77 12                	ja     f01040f0 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01040de:	50                   	push   %eax
f01040df:	68 48 5e 10 f0       	push   $0xf0105e48
f01040e4:	6a 55                	push   $0x55
f01040e6:	68 19 75 10 f0       	push   $0xf0107519
f01040eb:	e8 50 bf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01040f0:	05 00 00 00 10       	add    $0x10000000,%eax
f01040f5:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01040f8:	e8 5d 16 00 00       	call   f010575a <cpunum>
f01040fd:	6b d0 74             	imul   $0x74,%eax,%edx
f0104100:	81 c2 20 f0 22 f0    	add    $0xf022f020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104106:	b8 02 00 00 00       	mov    $0x2,%eax
f010410b:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010410f:	83 ec 0c             	sub    $0xc,%esp
f0104112:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0104117:	e8 49 19 00 00       	call   f0105a65 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010411c:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010411e:	e8 37 16 00 00       	call   f010575a <cpunum>
f0104123:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104126:	8b 80 30 f0 22 f0    	mov    -0xfdd0fd0(%eax),%eax
f010412c:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104131:	89 c4                	mov    %eax,%esp
f0104133:	6a 00                	push   $0x0
f0104135:	6a 00                	push   $0x0
f0104137:	f4                   	hlt    
f0104138:	eb fd                	jmp    f0104137 <sched_halt+0xcb>
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f010413a:	83 c4 10             	add    $0x10,%esp
f010413d:	c9                   	leave  
f010413e:	c3                   	ret    

f010413f <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010413f:	55                   	push   %ebp
f0104140:	89 e5                	mov    %esp,%ebp
f0104142:	53                   	push   %ebx
f0104143:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here:
	size_t index = 0;

	if(curenv)
f0104146:	e8 0f 16 00 00       	call   f010575a <cpunum>
f010414b:	6b c0 74             	imul   $0x74,%eax,%eax
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here:
	size_t index = 0;
f010414e:	ba 00 00 00 00       	mov    $0x0,%edx

	if(curenv)
f0104153:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f010415a:	74 1a                	je     f0104176 <sched_yield+0x37>
		index = ENVX(curenv->env_id) + 1;
f010415c:	e8 f9 15 00 00       	call   f010575a <cpunum>
f0104161:	6b c0 74             	imul   $0x74,%eax,%eax
f0104164:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f010416a:	8b 50 48             	mov    0x48(%eax),%edx
f010416d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104173:	83 c2 01             	add    $0x1,%edx

	for(size_t i = 0; i < NENV; ++i)
	{
		index = (index + i) % NENV;
		
		if(envs[index].env_status == ENV_RUNNABLE)
f0104176:	8b 1d 44 e2 22 f0    	mov    0xf022e244,%ebx
	size_t index = 0;

	if(curenv)
		index = ENVX(curenv->env_id) + 1;

	for(size_t i = 0; i < NENV; ++i)
f010417c:	b9 00 00 00 00       	mov    $0x0,%ecx
	{
		index = (index + i) % NENV;
f0104181:	01 ca                	add    %ecx,%edx
f0104183:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
		
		if(envs[index].env_status == ENV_RUNNABLE)
f0104189:	6b c2 7c             	imul   $0x7c,%edx,%eax
f010418c:	01 d8                	add    %ebx,%eax
f010418e:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0104192:	74 0d                	je     f01041a1 <sched_yield+0x62>
	size_t index = 0;

	if(curenv)
		index = ENVX(curenv->env_id) + 1;

	for(size_t i = 0; i < NENV; ++i)
f0104194:	83 c1 01             	add    $0x1,%ecx
f0104197:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010419d:	75 e2                	jne    f0104181 <sched_yield+0x42>
f010419f:	eb 0d                	jmp    f01041ae <sched_yield+0x6f>
			idle = &envs[index];
			break;
		}
	}	
	
	if(idle)
f01041a1:	85 c0                	test   %eax,%eax
f01041a3:	74 09                	je     f01041ae <sched_yield+0x6f>
		env_run(idle);
f01041a5:	83 ec 0c             	sub    $0xc,%esp
f01041a8:	50                   	push   %eax
f01041a9:	e8 b6 f2 ff ff       	call   f0103464 <env_run>
	
	else
	{
		if(curenv && curenv->env_status == ENV_RUNNING)
f01041ae:	e8 a7 15 00 00       	call   f010575a <cpunum>
f01041b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01041b6:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f01041bd:	74 2a                	je     f01041e9 <sched_yield+0xaa>
f01041bf:	e8 96 15 00 00       	call   f010575a <cpunum>
f01041c4:	6b c0 74             	imul   $0x74,%eax,%eax
f01041c7:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01041cd:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01041d1:	75 16                	jne    f01041e9 <sched_yield+0xaa>
			env_run(curenv);
f01041d3:	e8 82 15 00 00       	call   f010575a <cpunum>
f01041d8:	83 ec 0c             	sub    $0xc,%esp
f01041db:	6b c0 74             	imul   $0x74,%eax,%eax
f01041de:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f01041e4:	e8 7b f2 ff ff       	call   f0103464 <env_run>
	}	

	// sched_halt never returns
	sched_halt();
f01041e9:	e8 7e fe ff ff       	call   f010406c <sched_halt>
}
f01041ee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041f1:	c9                   	leave  
f01041f2:	c3                   	ret    

f01041f3 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01041f3:	55                   	push   %ebp
f01041f4:	89 e5                	mov    %esp,%ebp
f01041f6:	57                   	push   %edi
f01041f7:	56                   	push   %esi
f01041f8:	53                   	push   %ebx
f01041f9:	83 ec 1c             	sub    $0x1c,%esp
f01041fc:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
f01041ff:	83 f8 0a             	cmp    $0xa,%eax
f0104202:	0f 87 bb 03 00 00    	ja     f01045c3 <syscall+0x3d0>
f0104208:	ff 24 85 60 75 10 f0 	jmp    *-0xfef8aa0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f010420f:	e8 46 15 00 00       	call   f010575a <cpunum>
f0104214:	6a 04                	push   $0x4
f0104216:	ff 75 10             	pushl  0x10(%ebp)
f0104219:	ff 75 0c             	pushl  0xc(%ebp)
f010421c:	6b c0 74             	imul   $0x74,%eax,%eax
f010421f:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0104225:	e8 3c eb ff ff       	call   f0102d66 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010422a:	83 c4 0c             	add    $0xc,%esp
f010422d:	ff 75 0c             	pushl  0xc(%ebp)
f0104230:	ff 75 10             	pushl  0x10(%ebp)
f0104233:	68 26 75 10 f0       	push   $0xf0107526
f0104238:	e8 41 f4 ff ff       	call   f010367e <cprintf>
f010423d:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
f0104240:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104245:	e9 7e 03 00 00       	jmp    f01045c8 <syscall+0x3d5>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010424a:	e8 a6 c3 ff ff       	call   f01005f5 <cons_getc>
f010424f:	89 c3                	mov    %eax,%ebx

	switch (syscallno) 
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			 return sys_cgetc();		
f0104251:	e9 72 03 00 00       	jmp    f01045c8 <syscall+0x3d5>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104256:	e8 ff 14 00 00       	call   f010575a <cpunum>
f010425b:	6b c0 74             	imul   $0x74,%eax,%eax
f010425e:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0104264:	8b 58 48             	mov    0x48(%eax),%ebx
	{
		case SYS_cputs:			 sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			 return sys_cgetc();		

		case SYS_getenvid:		 return sys_getenvid();
f0104267:	e9 5c 03 00 00       	jmp    f01045c8 <syscall+0x3d5>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010426c:	83 ec 04             	sub    $0x4,%esp
f010426f:	6a 01                	push   $0x1
f0104271:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104274:	50                   	push   %eax
f0104275:	ff 75 0c             	pushl  0xc(%ebp)
f0104278:	e8 9e eb ff ff       	call   f0102e1b <envid2env>
f010427d:	83 c4 10             	add    $0x10,%esp
f0104280:	85 c0                	test   %eax,%eax
f0104282:	78 69                	js     f01042ed <syscall+0xfa>
		return r;
	if (e == curenv)
f0104284:	e8 d1 14 00 00       	call   f010575a <cpunum>
f0104289:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010428c:	6b c0 74             	imul   $0x74,%eax,%eax
f010428f:	39 90 28 f0 22 f0    	cmp    %edx,-0xfdd0fd8(%eax)
f0104295:	75 23                	jne    f01042ba <syscall+0xc7>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104297:	e8 be 14 00 00       	call   f010575a <cpunum>
f010429c:	83 ec 08             	sub    $0x8,%esp
f010429f:	6b c0 74             	imul   $0x74,%eax,%eax
f01042a2:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01042a8:	ff 70 48             	pushl  0x48(%eax)
f01042ab:	68 2b 75 10 f0       	push   $0xf010752b
f01042b0:	e8 c9 f3 ff ff       	call   f010367e <cprintf>
f01042b5:	83 c4 10             	add    $0x10,%esp
f01042b8:	eb 25                	jmp    f01042df <syscall+0xec>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01042ba:	8b 5a 48             	mov    0x48(%edx),%ebx
f01042bd:	e8 98 14 00 00       	call   f010575a <cpunum>
f01042c2:	83 ec 04             	sub    $0x4,%esp
f01042c5:	53                   	push   %ebx
f01042c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01042c9:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01042cf:	ff 70 48             	pushl  0x48(%eax)
f01042d2:	68 46 75 10 f0       	push   $0xf0107546
f01042d7:	e8 a2 f3 ff ff       	call   f010367e <cprintf>
f01042dc:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01042df:	83 ec 0c             	sub    $0xc,%esp
f01042e2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01042e5:	e8 db f0 ff ff       	call   f01033c5 <env_destroy>
f01042ea:	83 c4 10             	add    $0x10,%esp

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01042ed:	e8 4d fe ff ff       	call   f010413f <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = env_alloc(&env, curenv->env_id);
f01042f2:	e8 63 14 00 00       	call   f010575a <cpunum>
f01042f7:	83 ec 08             	sub    $0x8,%esp
f01042fa:	6b c0 74             	imul   $0x74,%eax,%eax
f01042fd:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0104303:	ff 70 48             	pushl  0x48(%eax)
f0104306:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104309:	50                   	push   %eax
f010430a:	e8 17 ec ff ff       	call   f0102f26 <env_alloc>
f010430f:	89 c3                	mov    %eax,%ebx
	
	if(result)
f0104311:	83 c4 10             	add    $0x10,%esp
f0104314:	85 c0                	test   %eax,%eax
f0104316:	0f 85 ac 02 00 00    	jne    f01045c8 <syscall+0x3d5>
		return result;

	env->env_status = ENV_NOT_RUNNABLE;
f010431c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010431f:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	env->env_tf = curenv->env_tf;
f0104326:	e8 2f 14 00 00       	call   f010575a <cpunum>
f010432b:	6b c0 74             	imul   $0x74,%eax,%eax
f010432e:	8b b0 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%esi
f0104334:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104339:	89 df                	mov    %ebx,%edi
f010433b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	env->env_tf.tf_regs.reg_eax = 0;
f010433d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104340:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return env->env_id;
f0104347:	8b 58 48             	mov    0x48(%eax),%ebx

		case SYS_env_destroy:		 sys_env_destroy((envid_t) a1);
		
		case SYS_yield:			 sys_yield();			return 0;
	
		case SYS_exofork:		 return (int32_t) sys_exofork();
f010434a:	e9 79 02 00 00       	jmp    f01045c8 <syscall+0x3d5>
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f010434f:	83 ec 04             	sub    $0x4,%esp
f0104352:	6a 01                	push   $0x1
f0104354:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104357:	50                   	push   %eax
f0104358:	ff 75 0c             	pushl  0xc(%ebp)
f010435b:	e8 bb ea ff ff       	call   f0102e1b <envid2env>
f0104360:	89 c3                	mov    %eax,%ebx

	if(result)
f0104362:	83 c4 10             	add    $0x10,%esp
f0104365:	85 c0                	test   %eax,%eax
f0104367:	0f 85 5b 02 00 00    	jne    f01045c8 <syscall+0x3d5>
		return result;

	if(status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE)
f010436d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104370:	83 e8 02             	sub    $0x2,%eax
f0104373:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104378:	75 0e                	jne    f0104388 <syscall+0x195>
		return -E_INVAL;

	env->env_status = status;
f010437a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010437d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104380:	89 78 54             	mov    %edi,0x54(%eax)
f0104383:	e9 40 02 00 00       	jmp    f01045c8 <syscall+0x3d5>

	if(result)
		return result;

	if(status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE)
		return -E_INVAL;
f0104388:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		
		case SYS_yield:			 sys_yield();			return 0;
	
		case SYS_exofork:		 return (int32_t) sys_exofork();

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);
f010438d:	e9 36 02 00 00       	jmp    f01045c8 <syscall+0x3d5>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f0104392:	83 ec 04             	sub    $0x4,%esp
f0104395:	6a 01                	push   $0x1
f0104397:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010439a:	50                   	push   %eax
f010439b:	ff 75 0c             	pushl  0xc(%ebp)
f010439e:	e8 78 ea ff ff       	call   f0102e1b <envid2env>

	if(result)
f01043a3:	83 c4 10             	add    $0x10,%esp
f01043a6:	85 c0                	test   %eax,%eax
f01043a8:	75 69                	jne    f0104413 <syscall+0x220>
		return -E_BAD_ENV;

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
f01043aa:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01043b1:	77 6a                	ja     f010441d <syscall+0x22a>
f01043b3:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01043ba:	75 6b                	jne    f0104427 <syscall+0x234>
		return -E_INVAL;
	
	if(perm & ~PTE_SYSCALL)
f01043bc:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f01043c3:	75 6c                	jne    f0104431 <syscall+0x23e>
		return -E_INVAL;

	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))	
f01043c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01043c8:	83 e0 05             	and    $0x5,%eax
f01043cb:	83 f8 05             	cmp    $0x5,%eax
f01043ce:	75 6b                	jne    f010443b <syscall+0x248>
		return -E_INVAL;

	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01043d0:	83 ec 0c             	sub    $0xc,%esp
f01043d3:	6a 01                	push   $0x1
f01043d5:	e8 d7 cb ff ff       	call   f0100fb1 <page_alloc>
f01043da:	89 c6                	mov    %eax,%esi

	if(!page)
f01043dc:	83 c4 10             	add    $0x10,%esp
f01043df:	85 c0                	test   %eax,%eax
f01043e1:	74 62                	je     f0104445 <syscall+0x252>
		return -E_NO_MEM;

	result = page_insert(env->env_pgdir, page, va, perm);
f01043e3:	ff 75 14             	pushl  0x14(%ebp)
f01043e6:	ff 75 10             	pushl  0x10(%ebp)
f01043e9:	50                   	push   %eax
f01043ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043ed:	ff 70 60             	pushl  0x60(%eax)
f01043f0:	e8 bb ce ff ff       	call   f01012b0 <page_insert>
f01043f5:	89 c3                	mov    %eax,%ebx

	if(result)
f01043f7:	83 c4 10             	add    $0x10,%esp
f01043fa:	85 c0                	test   %eax,%eax
f01043fc:	0f 84 c6 01 00 00    	je     f01045c8 <syscall+0x3d5>
	{
		page_free(page);
f0104402:	83 ec 0c             	sub    $0xc,%esp
f0104405:	56                   	push   %esi
f0104406:	e8 16 cc ff ff       	call   f0101021 <page_free>
f010440b:	83 c4 10             	add    $0x10,%esp
f010440e:	e9 b5 01 00 00       	jmp    f01045c8 <syscall+0x3d5>
	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);

	if(result)
		return -E_BAD_ENV;
f0104413:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104418:	e9 ab 01 00 00       	jmp    f01045c8 <syscall+0x3d5>

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
		return -E_INVAL;
f010441d:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104422:	e9 a1 01 00 00       	jmp    f01045c8 <syscall+0x3d5>
f0104427:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010442c:	e9 97 01 00 00       	jmp    f01045c8 <syscall+0x3d5>
	
	if(perm & ~PTE_SYSCALL)
		return -E_INVAL;
f0104431:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104436:	e9 8d 01 00 00       	jmp    f01045c8 <syscall+0x3d5>

	if((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))	
		return -E_INVAL;
f010443b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104440:	e9 83 01 00 00       	jmp    f01045c8 <syscall+0x3d5>

	struct PageInfo *page = page_alloc(ALLOC_ZERO);

	if(!page)
		return -E_NO_MEM;
f0104445:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
	
		case SYS_exofork:		 return (int32_t) sys_exofork();

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
f010444a:	e9 79 01 00 00       	jmp    f01045c8 <syscall+0x3d5>
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	struct Env *src, *dst;
	size_t result_src = envid2env(srcenvid, &src, perm);
f010444f:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f0104453:	0f 95 c3             	setne  %bl
f0104456:	0f b6 db             	movzbl %bl,%ebx
f0104459:	83 ec 04             	sub    $0x4,%esp
f010445c:	53                   	push   %ebx
f010445d:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104460:	50                   	push   %eax
f0104461:	ff 75 0c             	pushl  0xc(%ebp)
f0104464:	e8 b2 e9 ff ff       	call   f0102e1b <envid2env>
f0104469:	89 c6                	mov    %eax,%esi
	size_t result_dst = envid2env(dstenvid, &dst, perm);
f010446b:	83 c4 0c             	add    $0xc,%esp
f010446e:	53                   	push   %ebx
f010446f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104472:	50                   	push   %eax
f0104473:	ff 75 14             	pushl  0x14(%ebp)
f0104476:	e8 a0 e9 ff ff       	call   f0102e1b <envid2env>
	
	if(result_src || result_dst)
f010447b:	83 c4 10             	add    $0x10,%esp
f010447e:	09 c6                	or     %eax,%esi
f0104480:	75 75                	jne    f01044f7 <syscall+0x304>
		return -E_BAD_ENV;

	if((((uint32_t) srcva >= UTOP) || ((uint32_t) srcva % PGSIZE != 0)) || 	
f0104482:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104489:	77 76                	ja     f0104501 <syscall+0x30e>
f010448b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104492:	75 77                	jne    f010450b <syscall+0x318>
f0104494:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010449b:	77 6e                	ja     f010450b <syscall+0x318>
	  	(((uint32_t) dstva >= UTOP) || ((uint32_t) dstva % PGSIZE != 0)))
f010449d:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f01044a4:	75 6f                	jne    f0104515 <syscall+0x322>
		return -E_INVAL;

	pte_t *pte;
	struct PageInfo *page = page_lookup(src->env_pgdir, srcva, &pte);
f01044a6:	83 ec 04             	sub    $0x4,%esp
f01044a9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044ac:	50                   	push   %eax
f01044ad:	ff 75 10             	pushl  0x10(%ebp)
f01044b0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01044b3:	ff 70 60             	pushl  0x60(%eax)
f01044b6:	e8 11 cd ff ff       	call   f01011cc <page_lookup>

	if(!page)
f01044bb:	83 c4 10             	add    $0x10,%esp
f01044be:	85 c0                	test   %eax,%eax
f01044c0:	74 5d                	je     f010451f <syscall+0x32c>
		return -E_INVAL;

	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))
f01044c2:	8b 55 1c             	mov    0x1c(%ebp),%edx
f01044c5:	83 e2 05             	and    $0x5,%edx
f01044c8:	83 fa 05             	cmp    $0x5,%edx
f01044cb:	75 5c                	jne    f0104529 <syscall+0x336>
		return -E_INVAL;

	if ((perm & PTE_W) && !(*pte & PTE_W))
f01044cd:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f01044d1:	74 08                	je     f01044db <syscall+0x2e8>
f01044d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01044d6:	f6 02 02             	testb  $0x2,(%edx)
f01044d9:	74 58                	je     f0104533 <syscall+0x340>
		return -E_INVAL;

	size_t result = page_insert(dst->env_pgdir, page, dstva, perm);
f01044db:	ff 75 1c             	pushl  0x1c(%ebp)
f01044de:	ff 75 18             	pushl  0x18(%ebp)
f01044e1:	50                   	push   %eax
f01044e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044e5:	ff 70 60             	pushl  0x60(%eax)
f01044e8:	e8 c3 cd ff ff       	call   f01012b0 <page_insert>
f01044ed:	89 c3                	mov    %eax,%ebx
f01044ef:	83 c4 10             	add    $0x10,%esp
f01044f2:	e9 d1 00 00 00       	jmp    f01045c8 <syscall+0x3d5>
	struct Env *src, *dst;
	size_t result_src = envid2env(srcenvid, &src, perm);
	size_t result_dst = envid2env(dstenvid, &dst, perm);
	
	if(result_src || result_dst)
		return -E_BAD_ENV;
f01044f7:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01044fc:	e9 c7 00 00 00       	jmp    f01045c8 <syscall+0x3d5>

	if((((uint32_t) srcva >= UTOP) || ((uint32_t) srcva % PGSIZE != 0)) || 	
	  	(((uint32_t) dstva >= UTOP) || ((uint32_t) dstva % PGSIZE != 0)))
		return -E_INVAL;
f0104501:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104506:	e9 bd 00 00 00       	jmp    f01045c8 <syscall+0x3d5>
f010450b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104510:	e9 b3 00 00 00       	jmp    f01045c8 <syscall+0x3d5>
f0104515:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010451a:	e9 a9 00 00 00       	jmp    f01045c8 <syscall+0x3d5>

	pte_t *pte;
	struct PageInfo *page = page_lookup(src->env_pgdir, srcva, &pte);

	if(!page)
		return -E_INVAL;
f010451f:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104524:	e9 9f 00 00 00       	jmp    f01045c8 <syscall+0x3d5>

	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P))
		return -E_INVAL;
f0104529:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010452e:	e9 95 00 00 00       	jmp    f01045c8 <syscall+0x3d5>

	if ((perm & PTE_W) && !(*pte & PTE_W))
		return -E_INVAL;
f0104533:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		case SYS_env_set_status:	 return sys_env_set_status((envid_t) a1, (int) a2);

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);
f0104538:	e9 8b 00 00 00       	jmp    f01045c8 <syscall+0x3d5>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);
f010453d:	83 ec 04             	sub    $0x4,%esp
f0104540:	6a 01                	push   $0x1
f0104542:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104545:	50                   	push   %eax
f0104546:	ff 75 0c             	pushl  0xc(%ebp)
f0104549:	e8 cd e8 ff ff       	call   f0102e1b <envid2env>
f010454e:	89 c3                	mov    %eax,%ebx

	if(result)
f0104550:	83 c4 10             	add    $0x10,%esp
f0104553:	85 c0                	test   %eax,%eax
f0104555:	75 28                	jne    f010457f <syscall+0x38c>
		return -E_BAD_ENV;

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
f0104557:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010455e:	77 26                	ja     f0104586 <syscall+0x393>
f0104560:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104567:	75 24                	jne    f010458d <syscall+0x39a>
		return -E_INVAL;

	page_remove(env->env_pgdir, va);
f0104569:	83 ec 08             	sub    $0x8,%esp
f010456c:	ff 75 10             	pushl  0x10(%ebp)
f010456f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104572:	ff 70 60             	pushl  0x60(%eax)
f0104575:	e8 e1 cc ff ff       	call   f010125b <page_remove>
f010457a:	83 c4 10             	add    $0x10,%esp
f010457d:	eb 49                	jmp    f01045c8 <syscall+0x3d5>
	// LAB 4: Your code here.
	struct Env *env;
	size_t result = envid2env(envid, &env, 1);

	if(result)
		return -E_BAD_ENV;
f010457f:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104584:	eb 42                	jmp    f01045c8 <syscall+0x3d5>

	if(((uint32_t) va >= UTOP) || ((uint32_t) va % PGSIZE != 0))
		return -E_INVAL;
f0104586:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010458b:	eb 3b                	jmp    f01045c8 <syscall+0x3d5>
f010458d:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		case SYS_page_alloc:		 return sys_page_alloc((envid_t) a1, (void *) a2, (int) a3);
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);

		case SYS_page_unmap:		 return sys_page_unmap((envid_t) a1, (void *) a2);
f0104592:	eb 34                	jmp    f01045c8 <syscall+0x3d5>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *env;
	envid2env(envid, &env, 1);
f0104594:	83 ec 04             	sub    $0x4,%esp
f0104597:	6a 01                	push   $0x1
f0104599:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010459c:	50                   	push   %eax
f010459d:	ff 75 0c             	pushl  0xc(%ebp)
f01045a0:	e8 76 e8 ff ff       	call   f0102e1b <envid2env>

	if(!env)
f01045a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045a8:	83 c4 10             	add    $0x10,%esp
f01045ab:	85 c0                	test   %eax,%eax
f01045ad:	74 0d                	je     f01045bc <syscall+0x3c9>
		return -E_BAD_ENV;

	env->env_pgfault_upcall = func;
f01045af:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01045b2:	89 48 64             	mov    %ecx,0x64(%eax)

	return 0;
f01045b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01045ba:	eb 0c                	jmp    f01045c8 <syscall+0x3d5>
	// LAB 4: Your code here.
	struct Env *env;
	envid2env(envid, &env, 1);

	if(!env)
		return -E_BAD_ENV;
f01045bc:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
		
		case SYS_page_map:		 return sys_page_map((envid_t) a1, (void *) a2, (envid_t) a3, (void *) a4, (int) a5);

		case SYS_page_unmap:		 return sys_page_unmap((envid_t) a1, (void *) a2);
		
		case SYS_env_set_pgfault_upcall: return sys_env_set_pgfault_upcall((envid_t)a1, (void*)a2);
f01045c1:	eb 05                	jmp    f01045c8 <syscall+0x3d5>

		default:			 return -E_INVAL;
f01045c3:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
	}
}
f01045c8:	89 d8                	mov    %ebx,%eax
f01045ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045cd:	5b                   	pop    %ebx
f01045ce:	5e                   	pop    %esi
f01045cf:	5f                   	pop    %edi
f01045d0:	5d                   	pop    %ebp
f01045d1:	c3                   	ret    

f01045d2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01045d2:	55                   	push   %ebp
f01045d3:	89 e5                	mov    %esp,%ebp
f01045d5:	57                   	push   %edi
f01045d6:	56                   	push   %esi
f01045d7:	53                   	push   %ebx
f01045d8:	83 ec 14             	sub    $0x14,%esp
f01045db:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01045de:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01045e1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01045e4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01045e7:	8b 1a                	mov    (%edx),%ebx
f01045e9:	8b 01                	mov    (%ecx),%eax
f01045eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01045ee:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01045f5:	eb 7f                	jmp    f0104676 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01045f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01045fa:	01 d8                	add    %ebx,%eax
f01045fc:	89 c6                	mov    %eax,%esi
f01045fe:	c1 ee 1f             	shr    $0x1f,%esi
f0104601:	01 c6                	add    %eax,%esi
f0104603:	d1 fe                	sar    %esi
f0104605:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104608:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010460b:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010460e:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104610:	eb 03                	jmp    f0104615 <stab_binsearch+0x43>
			m--;
f0104612:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104615:	39 c3                	cmp    %eax,%ebx
f0104617:	7f 0d                	jg     f0104626 <stab_binsearch+0x54>
f0104619:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010461d:	83 ea 0c             	sub    $0xc,%edx
f0104620:	39 f9                	cmp    %edi,%ecx
f0104622:	75 ee                	jne    f0104612 <stab_binsearch+0x40>
f0104624:	eb 05                	jmp    f010462b <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104626:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104629:	eb 4b                	jmp    f0104676 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010462b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010462e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104631:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104635:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104638:	76 11                	jbe    f010464b <stab_binsearch+0x79>
			*region_left = m;
f010463a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010463d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010463f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104642:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104649:	eb 2b                	jmp    f0104676 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010464b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010464e:	73 14                	jae    f0104664 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104650:	83 e8 01             	sub    $0x1,%eax
f0104653:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104656:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104659:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010465b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104662:	eb 12                	jmp    f0104676 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104664:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104667:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104669:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010466d:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010466f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104676:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104679:	0f 8e 78 ff ff ff    	jle    f01045f7 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010467f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104683:	75 0f                	jne    f0104694 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104685:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104688:	8b 00                	mov    (%eax),%eax
f010468a:	83 e8 01             	sub    $0x1,%eax
f010468d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104690:	89 06                	mov    %eax,(%esi)
f0104692:	eb 2c                	jmp    f01046c0 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104694:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104697:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104699:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010469c:	8b 0e                	mov    (%esi),%ecx
f010469e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01046a1:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01046a4:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01046a7:	eb 03                	jmp    f01046ac <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01046a9:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01046ac:	39 c8                	cmp    %ecx,%eax
f01046ae:	7e 0b                	jle    f01046bb <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01046b0:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01046b4:	83 ea 0c             	sub    $0xc,%edx
f01046b7:	39 df                	cmp    %ebx,%edi
f01046b9:	75 ee                	jne    f01046a9 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01046bb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01046be:	89 06                	mov    %eax,(%esi)
	}
}
f01046c0:	83 c4 14             	add    $0x14,%esp
f01046c3:	5b                   	pop    %ebx
f01046c4:	5e                   	pop    %esi
f01046c5:	5f                   	pop    %edi
f01046c6:	5d                   	pop    %ebp
f01046c7:	c3                   	ret    

f01046c8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01046c8:	55                   	push   %ebp
f01046c9:	89 e5                	mov    %esp,%ebp
f01046cb:	57                   	push   %edi
f01046cc:	56                   	push   %esi
f01046cd:	53                   	push   %ebx
f01046ce:	83 ec 3c             	sub    $0x3c,%esp
f01046d1:	8b 7d 08             	mov    0x8(%ebp),%edi
f01046d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01046d7:	c7 03 8c 75 10 f0    	movl   $0xf010758c,(%ebx)
	info->eip_line = 0;
f01046dd:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01046e4:	c7 43 08 8c 75 10 f0 	movl   $0xf010758c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01046eb:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01046f2:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01046f5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01046fc:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104702:	0f 87 a3 00 00 00    	ja     f01047ab <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f0104708:	e8 4d 10 00 00       	call   f010575a <cpunum>
f010470d:	6a 04                	push   $0x4
f010470f:	6a 10                	push   $0x10
f0104711:	68 00 00 20 00       	push   $0x200000
f0104716:	6b c0 74             	imul   $0x74,%eax,%eax
f0104719:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f010471f:	e8 cc e5 ff ff       	call   f0102cf0 <user_mem_check>
f0104724:	83 c4 10             	add    $0x10,%esp
f0104727:	85 c0                	test   %eax,%eax
f0104729:	0f 84 3e 02 00 00    	je     f010496d <debuginfo_eip+0x2a5>
                        return -1;

		stabs = usd->stabs;
f010472f:	a1 00 00 20 00       	mov    0x200000,%eax
f0104734:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0104737:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f010473d:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104743:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104746:	a1 0c 00 20 00       	mov    0x20000c,%eax
f010474b:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f010474e:	e8 07 10 00 00       	call   f010575a <cpunum>
f0104753:	6a 04                	push   $0x4
f0104755:	89 f2                	mov    %esi,%edx
f0104757:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f010475a:	29 ca                	sub    %ecx,%edx
f010475c:	c1 fa 02             	sar    $0x2,%edx
f010475f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104765:	52                   	push   %edx
f0104766:	51                   	push   %ecx
f0104767:	6b c0 74             	imul   $0x74,%eax,%eax
f010476a:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0104770:	e8 7b e5 ff ff       	call   f0102cf0 <user_mem_check>
f0104775:	83 c4 10             	add    $0x10,%esp
f0104778:	85 c0                	test   %eax,%eax
f010477a:	0f 84 f4 01 00 00    	je     f0104974 <debuginfo_eip+0x2ac>
			return -1;

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f0104780:	e8 d5 0f 00 00       	call   f010575a <cpunum>
f0104785:	6a 04                	push   $0x4
f0104787:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010478a:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010478d:	29 ca                	sub    %ecx,%edx
f010478f:	52                   	push   %edx
f0104790:	51                   	push   %ecx
f0104791:	6b c0 74             	imul   $0x74,%eax,%eax
f0104794:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f010479a:	e8 51 e5 ff ff       	call   f0102cf0 <user_mem_check>
f010479f:	83 c4 10             	add    $0x10,%esp
f01047a2:	85 c0                	test   %eax,%eax
f01047a4:	75 1f                	jne    f01047c5 <debuginfo_eip+0xfd>
f01047a6:	e9 d0 01 00 00       	jmp    f010497b <debuginfo_eip+0x2b3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01047ab:	c7 45 bc b4 4f 11 f0 	movl   $0xf0114fb4,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01047b2:	c7 45 b8 fd 18 11 f0 	movl   $0xf01118fd,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01047b9:	be fc 18 11 f0       	mov    $0xf01118fc,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01047be:	c7 45 c0 74 7a 10 f0 	movl   $0xf0107a74,-0x40(%ebp)
		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01047c5:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01047c8:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f01047cb:	0f 83 b1 01 00 00    	jae    f0104982 <debuginfo_eip+0x2ba>
f01047d1:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01047d5:	0f 85 ae 01 00 00    	jne    f0104989 <debuginfo_eip+0x2c1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01047db:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01047e2:	2b 75 c0             	sub    -0x40(%ebp),%esi
f01047e5:	c1 fe 02             	sar    $0x2,%esi
f01047e8:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f01047ee:	83 e8 01             	sub    $0x1,%eax
f01047f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01047f4:	83 ec 08             	sub    $0x8,%esp
f01047f7:	57                   	push   %edi
f01047f8:	6a 64                	push   $0x64
f01047fa:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01047fd:	89 d1                	mov    %edx,%ecx
f01047ff:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104802:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104805:	89 f0                	mov    %esi,%eax
f0104807:	e8 c6 fd ff ff       	call   f01045d2 <stab_binsearch>
	if (lfile == 0)
f010480c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010480f:	83 c4 10             	add    $0x10,%esp
f0104812:	85 c0                	test   %eax,%eax
f0104814:	0f 84 76 01 00 00    	je     f0104990 <debuginfo_eip+0x2c8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010481a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010481d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104820:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104823:	83 ec 08             	sub    $0x8,%esp
f0104826:	57                   	push   %edi
f0104827:	6a 24                	push   $0x24
f0104829:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010482c:	89 d1                	mov    %edx,%ecx
f010482e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104831:	89 f0                	mov    %esi,%eax
f0104833:	e8 9a fd ff ff       	call   f01045d2 <stab_binsearch>

	if (lfun <= rfun) {
f0104838:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010483b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010483e:	83 c4 10             	add    $0x10,%esp
f0104841:	39 d0                	cmp    %edx,%eax
f0104843:	7f 2e                	jg     f0104873 <debuginfo_eip+0x1ab>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104845:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104848:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f010484b:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f010484e:	8b 36                	mov    (%esi),%esi
f0104850:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104853:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104856:	39 ce                	cmp    %ecx,%esi
f0104858:	73 06                	jae    f0104860 <debuginfo_eip+0x198>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010485a:	03 75 b8             	add    -0x48(%ebp),%esi
f010485d:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104860:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104863:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104866:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104869:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f010486b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010486e:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104871:	eb 0f                	jmp    f0104882 <debuginfo_eip+0x1ba>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104873:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104876:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104879:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010487c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010487f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104882:	83 ec 08             	sub    $0x8,%esp
f0104885:	6a 3a                	push   $0x3a
f0104887:	ff 73 08             	pushl  0x8(%ebx)
f010488a:	e8 8f 08 00 00       	call   f010511e <strfind>
f010488f:	2b 43 08             	sub    0x8(%ebx),%eax
f0104892:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104895:	83 c4 08             	add    $0x8,%esp
f0104898:	57                   	push   %edi
f0104899:	6a 44                	push   $0x44
f010489b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010489e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01048a1:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01048a4:	89 f8                	mov    %edi,%eax
f01048a6:	e8 27 fd ff ff       	call   f01045d2 <stab_binsearch>
	
	if(lline > rline)
f01048ab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01048ae:	83 c4 10             	add    $0x10,%esp
f01048b1:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01048b4:	0f 8f dd 00 00 00    	jg     f0104997 <debuginfo_eip+0x2cf>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f01048ba:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01048bd:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01048c0:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f01048c4:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01048c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048ca:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01048ce:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01048d1:	eb 0a                	jmp    f01048dd <debuginfo_eip+0x215>
f01048d3:	83 e8 01             	sub    $0x1,%eax
f01048d6:	83 ea 0c             	sub    $0xc,%edx
f01048d9:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01048dd:	39 c7                	cmp    %eax,%edi
f01048df:	7e 05                	jle    f01048e6 <debuginfo_eip+0x21e>
f01048e1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048e4:	eb 47                	jmp    f010492d <debuginfo_eip+0x265>
	       && stabs[lline].n_type != N_SOL
f01048e6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01048ea:	80 f9 84             	cmp    $0x84,%cl
f01048ed:	75 0e                	jne    f01048fd <debuginfo_eip+0x235>
f01048ef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048f2:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01048f6:	74 1c                	je     f0104914 <debuginfo_eip+0x24c>
f01048f8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01048fb:	eb 17                	jmp    f0104914 <debuginfo_eip+0x24c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01048fd:	80 f9 64             	cmp    $0x64,%cl
f0104900:	75 d1                	jne    f01048d3 <debuginfo_eip+0x20b>
f0104902:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104906:	74 cb                	je     f01048d3 <debuginfo_eip+0x20b>
f0104908:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010490b:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010490f:	74 03                	je     f0104914 <debuginfo_eip+0x24c>
f0104911:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104914:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104917:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010491a:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010491d:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104920:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104923:	29 f8                	sub    %edi,%eax
f0104925:	39 c2                	cmp    %eax,%edx
f0104927:	73 04                	jae    f010492d <debuginfo_eip+0x265>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104929:	01 fa                	add    %edi,%edx
f010492b:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010492d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104930:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104933:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104938:	39 f2                	cmp    %esi,%edx
f010493a:	7d 67                	jge    f01049a3 <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
f010493c:	83 c2 01             	add    $0x1,%edx
f010493f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104942:	89 d0                	mov    %edx,%eax
f0104944:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104947:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010494a:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010494d:	eb 04                	jmp    f0104953 <debuginfo_eip+0x28b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010494f:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104953:	39 c6                	cmp    %eax,%esi
f0104955:	7e 47                	jle    f010499e <debuginfo_eip+0x2d6>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104957:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010495b:	83 c0 01             	add    $0x1,%eax
f010495e:	83 c2 0c             	add    $0xc,%edx
f0104961:	80 f9 a0             	cmp    $0xa0,%cl
f0104964:	74 e9                	je     f010494f <debuginfo_eip+0x287>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104966:	b8 00 00 00 00       	mov    $0x0,%eax
f010496b:	eb 36                	jmp    f01049a3 <debuginfo_eip+0x2db>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
                        return -1;
f010496d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104972:	eb 2f                	jmp    f01049a3 <debuginfo_eip+0x2db>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
			return -1;
f0104974:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104979:	eb 28                	jmp    f01049a3 <debuginfo_eip+0x2db>

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f010497b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104980:	eb 21                	jmp    f01049a3 <debuginfo_eip+0x2db>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104982:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104987:	eb 1a                	jmp    f01049a3 <debuginfo_eip+0x2db>
f0104989:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010498e:	eb 13                	jmp    f01049a3 <debuginfo_eip+0x2db>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104990:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104995:	eb 0c                	jmp    f01049a3 <debuginfo_eip+0x2db>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0104997:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010499c:	eb 05                	jmp    f01049a3 <debuginfo_eip+0x2db>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010499e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01049a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01049a6:	5b                   	pop    %ebx
f01049a7:	5e                   	pop    %esi
f01049a8:	5f                   	pop    %edi
f01049a9:	5d                   	pop    %ebp
f01049aa:	c3                   	ret    

f01049ab <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01049ab:	55                   	push   %ebp
f01049ac:	89 e5                	mov    %esp,%ebp
f01049ae:	57                   	push   %edi
f01049af:	56                   	push   %esi
f01049b0:	53                   	push   %ebx
f01049b1:	83 ec 1c             	sub    $0x1c,%esp
f01049b4:	89 c7                	mov    %eax,%edi
f01049b6:	89 d6                	mov    %edx,%esi
f01049b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01049bb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01049be:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01049c1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01049c4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01049c7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01049cc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01049cf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01049d2:	39 d3                	cmp    %edx,%ebx
f01049d4:	72 05                	jb     f01049db <printnum+0x30>
f01049d6:	39 45 10             	cmp    %eax,0x10(%ebp)
f01049d9:	77 45                	ja     f0104a20 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01049db:	83 ec 0c             	sub    $0xc,%esp
f01049de:	ff 75 18             	pushl  0x18(%ebp)
f01049e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01049e4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01049e7:	53                   	push   %ebx
f01049e8:	ff 75 10             	pushl  0x10(%ebp)
f01049eb:	83 ec 08             	sub    $0x8,%esp
f01049ee:	ff 75 e4             	pushl  -0x1c(%ebp)
f01049f1:	ff 75 e0             	pushl  -0x20(%ebp)
f01049f4:	ff 75 dc             	pushl  -0x24(%ebp)
f01049f7:	ff 75 d8             	pushl  -0x28(%ebp)
f01049fa:	e8 61 11 00 00       	call   f0105b60 <__udivdi3>
f01049ff:	83 c4 18             	add    $0x18,%esp
f0104a02:	52                   	push   %edx
f0104a03:	50                   	push   %eax
f0104a04:	89 f2                	mov    %esi,%edx
f0104a06:	89 f8                	mov    %edi,%eax
f0104a08:	e8 9e ff ff ff       	call   f01049ab <printnum>
f0104a0d:	83 c4 20             	add    $0x20,%esp
f0104a10:	eb 18                	jmp    f0104a2a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104a12:	83 ec 08             	sub    $0x8,%esp
f0104a15:	56                   	push   %esi
f0104a16:	ff 75 18             	pushl  0x18(%ebp)
f0104a19:	ff d7                	call   *%edi
f0104a1b:	83 c4 10             	add    $0x10,%esp
f0104a1e:	eb 03                	jmp    f0104a23 <printnum+0x78>
f0104a20:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104a23:	83 eb 01             	sub    $0x1,%ebx
f0104a26:	85 db                	test   %ebx,%ebx
f0104a28:	7f e8                	jg     f0104a12 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104a2a:	83 ec 08             	sub    $0x8,%esp
f0104a2d:	56                   	push   %esi
f0104a2e:	83 ec 04             	sub    $0x4,%esp
f0104a31:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104a34:	ff 75 e0             	pushl  -0x20(%ebp)
f0104a37:	ff 75 dc             	pushl  -0x24(%ebp)
f0104a3a:	ff 75 d8             	pushl  -0x28(%ebp)
f0104a3d:	e8 4e 12 00 00       	call   f0105c90 <__umoddi3>
f0104a42:	83 c4 14             	add    $0x14,%esp
f0104a45:	0f be 80 96 75 10 f0 	movsbl -0xfef8a6a(%eax),%eax
f0104a4c:	50                   	push   %eax
f0104a4d:	ff d7                	call   *%edi
}
f0104a4f:	83 c4 10             	add    $0x10,%esp
f0104a52:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a55:	5b                   	pop    %ebx
f0104a56:	5e                   	pop    %esi
f0104a57:	5f                   	pop    %edi
f0104a58:	5d                   	pop    %ebp
f0104a59:	c3                   	ret    

f0104a5a <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104a5a:	55                   	push   %ebp
f0104a5b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104a5d:	83 fa 01             	cmp    $0x1,%edx
f0104a60:	7e 0e                	jle    f0104a70 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104a62:	8b 10                	mov    (%eax),%edx
f0104a64:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104a67:	89 08                	mov    %ecx,(%eax)
f0104a69:	8b 02                	mov    (%edx),%eax
f0104a6b:	8b 52 04             	mov    0x4(%edx),%edx
f0104a6e:	eb 22                	jmp    f0104a92 <getuint+0x38>
	else if (lflag)
f0104a70:	85 d2                	test   %edx,%edx
f0104a72:	74 10                	je     f0104a84 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104a74:	8b 10                	mov    (%eax),%edx
f0104a76:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104a79:	89 08                	mov    %ecx,(%eax)
f0104a7b:	8b 02                	mov    (%edx),%eax
f0104a7d:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a82:	eb 0e                	jmp    f0104a92 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104a84:	8b 10                	mov    (%eax),%edx
f0104a86:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104a89:	89 08                	mov    %ecx,(%eax)
f0104a8b:	8b 02                	mov    (%edx),%eax
f0104a8d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104a92:	5d                   	pop    %ebp
f0104a93:	c3                   	ret    

f0104a94 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104a94:	55                   	push   %ebp
f0104a95:	89 e5                	mov    %esp,%ebp
f0104a97:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104a9a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104a9e:	8b 10                	mov    (%eax),%edx
f0104aa0:	3b 50 04             	cmp    0x4(%eax),%edx
f0104aa3:	73 0a                	jae    f0104aaf <sprintputch+0x1b>
		*b->buf++ = ch;
f0104aa5:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104aa8:	89 08                	mov    %ecx,(%eax)
f0104aaa:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aad:	88 02                	mov    %al,(%edx)
}
f0104aaf:	5d                   	pop    %ebp
f0104ab0:	c3                   	ret    

f0104ab1 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104ab1:	55                   	push   %ebp
f0104ab2:	89 e5                	mov    %esp,%ebp
f0104ab4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104ab7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104aba:	50                   	push   %eax
f0104abb:	ff 75 10             	pushl  0x10(%ebp)
f0104abe:	ff 75 0c             	pushl  0xc(%ebp)
f0104ac1:	ff 75 08             	pushl  0x8(%ebp)
f0104ac4:	e8 05 00 00 00       	call   f0104ace <vprintfmt>
	va_end(ap);
}
f0104ac9:	83 c4 10             	add    $0x10,%esp
f0104acc:	c9                   	leave  
f0104acd:	c3                   	ret    

f0104ace <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104ace:	55                   	push   %ebp
f0104acf:	89 e5                	mov    %esp,%ebp
f0104ad1:	57                   	push   %edi
f0104ad2:	56                   	push   %esi
f0104ad3:	53                   	push   %ebx
f0104ad4:	83 ec 2c             	sub    $0x2c,%esp
f0104ad7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ada:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104add:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104ae0:	eb 12                	jmp    f0104af4 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104ae2:	85 c0                	test   %eax,%eax
f0104ae4:	0f 84 89 03 00 00    	je     f0104e73 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104aea:	83 ec 08             	sub    $0x8,%esp
f0104aed:	53                   	push   %ebx
f0104aee:	50                   	push   %eax
f0104aef:	ff d6                	call   *%esi
f0104af1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104af4:	83 c7 01             	add    $0x1,%edi
f0104af7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104afb:	83 f8 25             	cmp    $0x25,%eax
f0104afe:	75 e2                	jne    f0104ae2 <vprintfmt+0x14>
f0104b00:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104b04:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104b0b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104b12:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104b19:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b1e:	eb 07                	jmp    f0104b27 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b20:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104b23:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b27:	8d 47 01             	lea    0x1(%edi),%eax
f0104b2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104b2d:	0f b6 07             	movzbl (%edi),%eax
f0104b30:	0f b6 c8             	movzbl %al,%ecx
f0104b33:	83 e8 23             	sub    $0x23,%eax
f0104b36:	3c 55                	cmp    $0x55,%al
f0104b38:	0f 87 1a 03 00 00    	ja     f0104e58 <vprintfmt+0x38a>
f0104b3e:	0f b6 c0             	movzbl %al,%eax
f0104b41:	ff 24 85 60 76 10 f0 	jmp    *-0xfef89a0(,%eax,4)
f0104b48:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104b4b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104b4f:	eb d6                	jmp    f0104b27 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b54:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b59:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104b5c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104b5f:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104b63:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104b66:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104b69:	83 fa 09             	cmp    $0x9,%edx
f0104b6c:	77 39                	ja     f0104ba7 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104b6e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104b71:	eb e9                	jmp    f0104b5c <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104b73:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b76:	8d 48 04             	lea    0x4(%eax),%ecx
f0104b79:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104b7c:	8b 00                	mov    (%eax),%eax
f0104b7e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104b84:	eb 27                	jmp    f0104bad <vprintfmt+0xdf>
f0104b86:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b89:	85 c0                	test   %eax,%eax
f0104b8b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104b90:	0f 49 c8             	cmovns %eax,%ecx
f0104b93:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b99:	eb 8c                	jmp    f0104b27 <vprintfmt+0x59>
f0104b9b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104b9e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104ba5:	eb 80                	jmp    f0104b27 <vprintfmt+0x59>
f0104ba7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104baa:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104bad:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104bb1:	0f 89 70 ff ff ff    	jns    f0104b27 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104bb7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104bba:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104bbd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104bc4:	e9 5e ff ff ff       	jmp    f0104b27 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104bc9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104bcc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104bcf:	e9 53 ff ff ff       	jmp    f0104b27 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104bd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bd7:	8d 50 04             	lea    0x4(%eax),%edx
f0104bda:	89 55 14             	mov    %edx,0x14(%ebp)
f0104bdd:	83 ec 08             	sub    $0x8,%esp
f0104be0:	53                   	push   %ebx
f0104be1:	ff 30                	pushl  (%eax)
f0104be3:	ff d6                	call   *%esi
			break;
f0104be5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104be8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104beb:	e9 04 ff ff ff       	jmp    f0104af4 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104bf0:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bf3:	8d 50 04             	lea    0x4(%eax),%edx
f0104bf6:	89 55 14             	mov    %edx,0x14(%ebp)
f0104bf9:	8b 00                	mov    (%eax),%eax
f0104bfb:	99                   	cltd   
f0104bfc:	31 d0                	xor    %edx,%eax
f0104bfe:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104c00:	83 f8 08             	cmp    $0x8,%eax
f0104c03:	7f 0b                	jg     f0104c10 <vprintfmt+0x142>
f0104c05:	8b 14 85 c0 77 10 f0 	mov    -0xfef8840(,%eax,4),%edx
f0104c0c:	85 d2                	test   %edx,%edx
f0104c0e:	75 18                	jne    f0104c28 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104c10:	50                   	push   %eax
f0104c11:	68 ae 75 10 f0       	push   $0xf01075ae
f0104c16:	53                   	push   %ebx
f0104c17:	56                   	push   %esi
f0104c18:	e8 94 fe ff ff       	call   f0104ab1 <printfmt>
f0104c1d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c20:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104c23:	e9 cc fe ff ff       	jmp    f0104af4 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104c28:	52                   	push   %edx
f0104c29:	68 7d 6d 10 f0       	push   $0xf0106d7d
f0104c2e:	53                   	push   %ebx
f0104c2f:	56                   	push   %esi
f0104c30:	e8 7c fe ff ff       	call   f0104ab1 <printfmt>
f0104c35:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c3b:	e9 b4 fe ff ff       	jmp    f0104af4 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104c40:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c43:	8d 50 04             	lea    0x4(%eax),%edx
f0104c46:	89 55 14             	mov    %edx,0x14(%ebp)
f0104c49:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104c4b:	85 ff                	test   %edi,%edi
f0104c4d:	b8 a7 75 10 f0       	mov    $0xf01075a7,%eax
f0104c52:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104c55:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104c59:	0f 8e 94 00 00 00    	jle    f0104cf3 <vprintfmt+0x225>
f0104c5f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104c63:	0f 84 98 00 00 00    	je     f0104d01 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104c69:	83 ec 08             	sub    $0x8,%esp
f0104c6c:	ff 75 d0             	pushl  -0x30(%ebp)
f0104c6f:	57                   	push   %edi
f0104c70:	e8 5f 03 00 00       	call   f0104fd4 <strnlen>
f0104c75:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104c78:	29 c1                	sub    %eax,%ecx
f0104c7a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104c7d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104c80:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104c84:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c87:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104c8a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104c8c:	eb 0f                	jmp    f0104c9d <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104c8e:	83 ec 08             	sub    $0x8,%esp
f0104c91:	53                   	push   %ebx
f0104c92:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c95:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104c97:	83 ef 01             	sub    $0x1,%edi
f0104c9a:	83 c4 10             	add    $0x10,%esp
f0104c9d:	85 ff                	test   %edi,%edi
f0104c9f:	7f ed                	jg     f0104c8e <vprintfmt+0x1c0>
f0104ca1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104ca4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104ca7:	85 c9                	test   %ecx,%ecx
f0104ca9:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cae:	0f 49 c1             	cmovns %ecx,%eax
f0104cb1:	29 c1                	sub    %eax,%ecx
f0104cb3:	89 75 08             	mov    %esi,0x8(%ebp)
f0104cb6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104cb9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104cbc:	89 cb                	mov    %ecx,%ebx
f0104cbe:	eb 4d                	jmp    f0104d0d <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104cc0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104cc4:	74 1b                	je     f0104ce1 <vprintfmt+0x213>
f0104cc6:	0f be c0             	movsbl %al,%eax
f0104cc9:	83 e8 20             	sub    $0x20,%eax
f0104ccc:	83 f8 5e             	cmp    $0x5e,%eax
f0104ccf:	76 10                	jbe    f0104ce1 <vprintfmt+0x213>
					putch('?', putdat);
f0104cd1:	83 ec 08             	sub    $0x8,%esp
f0104cd4:	ff 75 0c             	pushl  0xc(%ebp)
f0104cd7:	6a 3f                	push   $0x3f
f0104cd9:	ff 55 08             	call   *0x8(%ebp)
f0104cdc:	83 c4 10             	add    $0x10,%esp
f0104cdf:	eb 0d                	jmp    f0104cee <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104ce1:	83 ec 08             	sub    $0x8,%esp
f0104ce4:	ff 75 0c             	pushl  0xc(%ebp)
f0104ce7:	52                   	push   %edx
f0104ce8:	ff 55 08             	call   *0x8(%ebp)
f0104ceb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104cee:	83 eb 01             	sub    $0x1,%ebx
f0104cf1:	eb 1a                	jmp    f0104d0d <vprintfmt+0x23f>
f0104cf3:	89 75 08             	mov    %esi,0x8(%ebp)
f0104cf6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104cf9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104cfc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104cff:	eb 0c                	jmp    f0104d0d <vprintfmt+0x23f>
f0104d01:	89 75 08             	mov    %esi,0x8(%ebp)
f0104d04:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104d07:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104d0a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104d0d:	83 c7 01             	add    $0x1,%edi
f0104d10:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104d14:	0f be d0             	movsbl %al,%edx
f0104d17:	85 d2                	test   %edx,%edx
f0104d19:	74 23                	je     f0104d3e <vprintfmt+0x270>
f0104d1b:	85 f6                	test   %esi,%esi
f0104d1d:	78 a1                	js     f0104cc0 <vprintfmt+0x1f2>
f0104d1f:	83 ee 01             	sub    $0x1,%esi
f0104d22:	79 9c                	jns    f0104cc0 <vprintfmt+0x1f2>
f0104d24:	89 df                	mov    %ebx,%edi
f0104d26:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d29:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d2c:	eb 18                	jmp    f0104d46 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104d2e:	83 ec 08             	sub    $0x8,%esp
f0104d31:	53                   	push   %ebx
f0104d32:	6a 20                	push   $0x20
f0104d34:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104d36:	83 ef 01             	sub    $0x1,%edi
f0104d39:	83 c4 10             	add    $0x10,%esp
f0104d3c:	eb 08                	jmp    f0104d46 <vprintfmt+0x278>
f0104d3e:	89 df                	mov    %ebx,%edi
f0104d40:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d43:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d46:	85 ff                	test   %edi,%edi
f0104d48:	7f e4                	jg     f0104d2e <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d4d:	e9 a2 fd ff ff       	jmp    f0104af4 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104d52:	83 fa 01             	cmp    $0x1,%edx
f0104d55:	7e 16                	jle    f0104d6d <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104d57:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d5a:	8d 50 08             	lea    0x8(%eax),%edx
f0104d5d:	89 55 14             	mov    %edx,0x14(%ebp)
f0104d60:	8b 50 04             	mov    0x4(%eax),%edx
f0104d63:	8b 00                	mov    (%eax),%eax
f0104d65:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104d68:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104d6b:	eb 32                	jmp    f0104d9f <vprintfmt+0x2d1>
	else if (lflag)
f0104d6d:	85 d2                	test   %edx,%edx
f0104d6f:	74 18                	je     f0104d89 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104d71:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d74:	8d 50 04             	lea    0x4(%eax),%edx
f0104d77:	89 55 14             	mov    %edx,0x14(%ebp)
f0104d7a:	8b 00                	mov    (%eax),%eax
f0104d7c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104d7f:	89 c1                	mov    %eax,%ecx
f0104d81:	c1 f9 1f             	sar    $0x1f,%ecx
f0104d84:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104d87:	eb 16                	jmp    f0104d9f <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104d89:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d8c:	8d 50 04             	lea    0x4(%eax),%edx
f0104d8f:	89 55 14             	mov    %edx,0x14(%ebp)
f0104d92:	8b 00                	mov    (%eax),%eax
f0104d94:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104d97:	89 c1                	mov    %eax,%ecx
f0104d99:	c1 f9 1f             	sar    $0x1f,%ecx
f0104d9c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104d9f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104da2:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104da5:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104daa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104dae:	79 74                	jns    f0104e24 <vprintfmt+0x356>
				putch('-', putdat);
f0104db0:	83 ec 08             	sub    $0x8,%esp
f0104db3:	53                   	push   %ebx
f0104db4:	6a 2d                	push   $0x2d
f0104db6:	ff d6                	call   *%esi
				num = -(long long) num;
f0104db8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104dbb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104dbe:	f7 d8                	neg    %eax
f0104dc0:	83 d2 00             	adc    $0x0,%edx
f0104dc3:	f7 da                	neg    %edx
f0104dc5:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104dc8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104dcd:	eb 55                	jmp    f0104e24 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104dcf:	8d 45 14             	lea    0x14(%ebp),%eax
f0104dd2:	e8 83 fc ff ff       	call   f0104a5a <getuint>
			base = 10;
f0104dd7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104ddc:	eb 46                	jmp    f0104e24 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104dde:	8d 45 14             	lea    0x14(%ebp),%eax
f0104de1:	e8 74 fc ff ff       	call   f0104a5a <getuint>
			base = 8;
f0104de6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104deb:	eb 37                	jmp    f0104e24 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104ded:	83 ec 08             	sub    $0x8,%esp
f0104df0:	53                   	push   %ebx
f0104df1:	6a 30                	push   $0x30
f0104df3:	ff d6                	call   *%esi
			putch('x', putdat);
f0104df5:	83 c4 08             	add    $0x8,%esp
f0104df8:	53                   	push   %ebx
f0104df9:	6a 78                	push   $0x78
f0104dfb:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104dfd:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e00:	8d 50 04             	lea    0x4(%eax),%edx
f0104e03:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104e06:	8b 00                	mov    (%eax),%eax
f0104e08:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104e0d:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104e10:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104e15:	eb 0d                	jmp    f0104e24 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104e17:	8d 45 14             	lea    0x14(%ebp),%eax
f0104e1a:	e8 3b fc ff ff       	call   f0104a5a <getuint>
			base = 16;
f0104e1f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104e24:	83 ec 0c             	sub    $0xc,%esp
f0104e27:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104e2b:	57                   	push   %edi
f0104e2c:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e2f:	51                   	push   %ecx
f0104e30:	52                   	push   %edx
f0104e31:	50                   	push   %eax
f0104e32:	89 da                	mov    %ebx,%edx
f0104e34:	89 f0                	mov    %esi,%eax
f0104e36:	e8 70 fb ff ff       	call   f01049ab <printnum>
			break;
f0104e3b:	83 c4 20             	add    $0x20,%esp
f0104e3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e41:	e9 ae fc ff ff       	jmp    f0104af4 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104e46:	83 ec 08             	sub    $0x8,%esp
f0104e49:	53                   	push   %ebx
f0104e4a:	51                   	push   %ecx
f0104e4b:	ff d6                	call   *%esi
			break;
f0104e4d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104e53:	e9 9c fc ff ff       	jmp    f0104af4 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104e58:	83 ec 08             	sub    $0x8,%esp
f0104e5b:	53                   	push   %ebx
f0104e5c:	6a 25                	push   $0x25
f0104e5e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104e60:	83 c4 10             	add    $0x10,%esp
f0104e63:	eb 03                	jmp    f0104e68 <vprintfmt+0x39a>
f0104e65:	83 ef 01             	sub    $0x1,%edi
f0104e68:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104e6c:	75 f7                	jne    f0104e65 <vprintfmt+0x397>
f0104e6e:	e9 81 fc ff ff       	jmp    f0104af4 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104e73:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e76:	5b                   	pop    %ebx
f0104e77:	5e                   	pop    %esi
f0104e78:	5f                   	pop    %edi
f0104e79:	5d                   	pop    %ebp
f0104e7a:	c3                   	ret    

f0104e7b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104e7b:	55                   	push   %ebp
f0104e7c:	89 e5                	mov    %esp,%ebp
f0104e7e:	83 ec 18             	sub    $0x18,%esp
f0104e81:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e84:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104e87:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104e8a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104e8e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104e91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104e98:	85 c0                	test   %eax,%eax
f0104e9a:	74 26                	je     f0104ec2 <vsnprintf+0x47>
f0104e9c:	85 d2                	test   %edx,%edx
f0104e9e:	7e 22                	jle    f0104ec2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104ea0:	ff 75 14             	pushl  0x14(%ebp)
f0104ea3:	ff 75 10             	pushl  0x10(%ebp)
f0104ea6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104ea9:	50                   	push   %eax
f0104eaa:	68 94 4a 10 f0       	push   $0xf0104a94
f0104eaf:	e8 1a fc ff ff       	call   f0104ace <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104eb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104eb7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104eba:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104ebd:	83 c4 10             	add    $0x10,%esp
f0104ec0:	eb 05                	jmp    f0104ec7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104ec2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104ec7:	c9                   	leave  
f0104ec8:	c3                   	ret    

f0104ec9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104ec9:	55                   	push   %ebp
f0104eca:	89 e5                	mov    %esp,%ebp
f0104ecc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104ecf:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104ed2:	50                   	push   %eax
f0104ed3:	ff 75 10             	pushl  0x10(%ebp)
f0104ed6:	ff 75 0c             	pushl  0xc(%ebp)
f0104ed9:	ff 75 08             	pushl  0x8(%ebp)
f0104edc:	e8 9a ff ff ff       	call   f0104e7b <vsnprintf>
	va_end(ap);

	return rc;
}
f0104ee1:	c9                   	leave  
f0104ee2:	c3                   	ret    

f0104ee3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104ee3:	55                   	push   %ebp
f0104ee4:	89 e5                	mov    %esp,%ebp
f0104ee6:	57                   	push   %edi
f0104ee7:	56                   	push   %esi
f0104ee8:	53                   	push   %ebx
f0104ee9:	83 ec 0c             	sub    $0xc,%esp
f0104eec:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104eef:	85 c0                	test   %eax,%eax
f0104ef1:	74 11                	je     f0104f04 <readline+0x21>
		cprintf("%s", prompt);
f0104ef3:	83 ec 08             	sub    $0x8,%esp
f0104ef6:	50                   	push   %eax
f0104ef7:	68 7d 6d 10 f0       	push   $0xf0106d7d
f0104efc:	e8 7d e7 ff ff       	call   f010367e <cprintf>
f0104f01:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104f04:	83 ec 0c             	sub    $0xc,%esp
f0104f07:	6a 00                	push   $0x0
f0104f09:	e8 77 b8 ff ff       	call   f0100785 <iscons>
f0104f0e:	89 c7                	mov    %eax,%edi
f0104f10:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104f13:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104f18:	e8 57 b8 ff ff       	call   f0100774 <getchar>
f0104f1d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104f1f:	85 c0                	test   %eax,%eax
f0104f21:	79 18                	jns    f0104f3b <readline+0x58>
			cprintf("read error: %e\n", c);
f0104f23:	83 ec 08             	sub    $0x8,%esp
f0104f26:	50                   	push   %eax
f0104f27:	68 e4 77 10 f0       	push   $0xf01077e4
f0104f2c:	e8 4d e7 ff ff       	call   f010367e <cprintf>
			return NULL;
f0104f31:	83 c4 10             	add    $0x10,%esp
f0104f34:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f39:	eb 79                	jmp    f0104fb4 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104f3b:	83 f8 08             	cmp    $0x8,%eax
f0104f3e:	0f 94 c2             	sete   %dl
f0104f41:	83 f8 7f             	cmp    $0x7f,%eax
f0104f44:	0f 94 c0             	sete   %al
f0104f47:	08 c2                	or     %al,%dl
f0104f49:	74 1a                	je     f0104f65 <readline+0x82>
f0104f4b:	85 f6                	test   %esi,%esi
f0104f4d:	7e 16                	jle    f0104f65 <readline+0x82>
			if (echoing)
f0104f4f:	85 ff                	test   %edi,%edi
f0104f51:	74 0d                	je     f0104f60 <readline+0x7d>
				cputchar('\b');
f0104f53:	83 ec 0c             	sub    $0xc,%esp
f0104f56:	6a 08                	push   $0x8
f0104f58:	e8 07 b8 ff ff       	call   f0100764 <cputchar>
f0104f5d:	83 c4 10             	add    $0x10,%esp
			i--;
f0104f60:	83 ee 01             	sub    $0x1,%esi
f0104f63:	eb b3                	jmp    f0104f18 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104f65:	83 fb 1f             	cmp    $0x1f,%ebx
f0104f68:	7e 23                	jle    f0104f8d <readline+0xaa>
f0104f6a:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104f70:	7f 1b                	jg     f0104f8d <readline+0xaa>
			if (echoing)
f0104f72:	85 ff                	test   %edi,%edi
f0104f74:	74 0c                	je     f0104f82 <readline+0x9f>
				cputchar(c);
f0104f76:	83 ec 0c             	sub    $0xc,%esp
f0104f79:	53                   	push   %ebx
f0104f7a:	e8 e5 b7 ff ff       	call   f0100764 <cputchar>
f0104f7f:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104f82:	88 9e 80 ea 22 f0    	mov    %bl,-0xfdd1580(%esi)
f0104f88:	8d 76 01             	lea    0x1(%esi),%esi
f0104f8b:	eb 8b                	jmp    f0104f18 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104f8d:	83 fb 0a             	cmp    $0xa,%ebx
f0104f90:	74 05                	je     f0104f97 <readline+0xb4>
f0104f92:	83 fb 0d             	cmp    $0xd,%ebx
f0104f95:	75 81                	jne    f0104f18 <readline+0x35>
			if (echoing)
f0104f97:	85 ff                	test   %edi,%edi
f0104f99:	74 0d                	je     f0104fa8 <readline+0xc5>
				cputchar('\n');
f0104f9b:	83 ec 0c             	sub    $0xc,%esp
f0104f9e:	6a 0a                	push   $0xa
f0104fa0:	e8 bf b7 ff ff       	call   f0100764 <cputchar>
f0104fa5:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104fa8:	c6 86 80 ea 22 f0 00 	movb   $0x0,-0xfdd1580(%esi)
			return buf;
f0104faf:	b8 80 ea 22 f0       	mov    $0xf022ea80,%eax
		}
	}
}
f0104fb4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104fb7:	5b                   	pop    %ebx
f0104fb8:	5e                   	pop    %esi
f0104fb9:	5f                   	pop    %edi
f0104fba:	5d                   	pop    %ebp
f0104fbb:	c3                   	ret    

f0104fbc <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104fbc:	55                   	push   %ebp
f0104fbd:	89 e5                	mov    %esp,%ebp
f0104fbf:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104fc2:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fc7:	eb 03                	jmp    f0104fcc <strlen+0x10>
		n++;
f0104fc9:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104fcc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104fd0:	75 f7                	jne    f0104fc9 <strlen+0xd>
		n++;
	return n;
}
f0104fd2:	5d                   	pop    %ebp
f0104fd3:	c3                   	ret    

f0104fd4 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104fd4:	55                   	push   %ebp
f0104fd5:	89 e5                	mov    %esp,%ebp
f0104fd7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104fda:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104fdd:	ba 00 00 00 00       	mov    $0x0,%edx
f0104fe2:	eb 03                	jmp    f0104fe7 <strnlen+0x13>
		n++;
f0104fe4:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104fe7:	39 c2                	cmp    %eax,%edx
f0104fe9:	74 08                	je     f0104ff3 <strnlen+0x1f>
f0104feb:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104fef:	75 f3                	jne    f0104fe4 <strnlen+0x10>
f0104ff1:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104ff3:	5d                   	pop    %ebp
f0104ff4:	c3                   	ret    

f0104ff5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104ff5:	55                   	push   %ebp
f0104ff6:	89 e5                	mov    %esp,%ebp
f0104ff8:	53                   	push   %ebx
f0104ff9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ffc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104fff:	89 c2                	mov    %eax,%edx
f0105001:	83 c2 01             	add    $0x1,%edx
f0105004:	83 c1 01             	add    $0x1,%ecx
f0105007:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010500b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010500e:	84 db                	test   %bl,%bl
f0105010:	75 ef                	jne    f0105001 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105012:	5b                   	pop    %ebx
f0105013:	5d                   	pop    %ebp
f0105014:	c3                   	ret    

f0105015 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105015:	55                   	push   %ebp
f0105016:	89 e5                	mov    %esp,%ebp
f0105018:	53                   	push   %ebx
f0105019:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010501c:	53                   	push   %ebx
f010501d:	e8 9a ff ff ff       	call   f0104fbc <strlen>
f0105022:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105025:	ff 75 0c             	pushl  0xc(%ebp)
f0105028:	01 d8                	add    %ebx,%eax
f010502a:	50                   	push   %eax
f010502b:	e8 c5 ff ff ff       	call   f0104ff5 <strcpy>
	return dst;
}
f0105030:	89 d8                	mov    %ebx,%eax
f0105032:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105035:	c9                   	leave  
f0105036:	c3                   	ret    

f0105037 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105037:	55                   	push   %ebp
f0105038:	89 e5                	mov    %esp,%ebp
f010503a:	56                   	push   %esi
f010503b:	53                   	push   %ebx
f010503c:	8b 75 08             	mov    0x8(%ebp),%esi
f010503f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105042:	89 f3                	mov    %esi,%ebx
f0105044:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105047:	89 f2                	mov    %esi,%edx
f0105049:	eb 0f                	jmp    f010505a <strncpy+0x23>
		*dst++ = *src;
f010504b:	83 c2 01             	add    $0x1,%edx
f010504e:	0f b6 01             	movzbl (%ecx),%eax
f0105051:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105054:	80 39 01             	cmpb   $0x1,(%ecx)
f0105057:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010505a:	39 da                	cmp    %ebx,%edx
f010505c:	75 ed                	jne    f010504b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010505e:	89 f0                	mov    %esi,%eax
f0105060:	5b                   	pop    %ebx
f0105061:	5e                   	pop    %esi
f0105062:	5d                   	pop    %ebp
f0105063:	c3                   	ret    

f0105064 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105064:	55                   	push   %ebp
f0105065:	89 e5                	mov    %esp,%ebp
f0105067:	56                   	push   %esi
f0105068:	53                   	push   %ebx
f0105069:	8b 75 08             	mov    0x8(%ebp),%esi
f010506c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010506f:	8b 55 10             	mov    0x10(%ebp),%edx
f0105072:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105074:	85 d2                	test   %edx,%edx
f0105076:	74 21                	je     f0105099 <strlcpy+0x35>
f0105078:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010507c:	89 f2                	mov    %esi,%edx
f010507e:	eb 09                	jmp    f0105089 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105080:	83 c2 01             	add    $0x1,%edx
f0105083:	83 c1 01             	add    $0x1,%ecx
f0105086:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105089:	39 c2                	cmp    %eax,%edx
f010508b:	74 09                	je     f0105096 <strlcpy+0x32>
f010508d:	0f b6 19             	movzbl (%ecx),%ebx
f0105090:	84 db                	test   %bl,%bl
f0105092:	75 ec                	jne    f0105080 <strlcpy+0x1c>
f0105094:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105096:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105099:	29 f0                	sub    %esi,%eax
}
f010509b:	5b                   	pop    %ebx
f010509c:	5e                   	pop    %esi
f010509d:	5d                   	pop    %ebp
f010509e:	c3                   	ret    

f010509f <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010509f:	55                   	push   %ebp
f01050a0:	89 e5                	mov    %esp,%ebp
f01050a2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01050a5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01050a8:	eb 06                	jmp    f01050b0 <strcmp+0x11>
		p++, q++;
f01050aa:	83 c1 01             	add    $0x1,%ecx
f01050ad:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01050b0:	0f b6 01             	movzbl (%ecx),%eax
f01050b3:	84 c0                	test   %al,%al
f01050b5:	74 04                	je     f01050bb <strcmp+0x1c>
f01050b7:	3a 02                	cmp    (%edx),%al
f01050b9:	74 ef                	je     f01050aa <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01050bb:	0f b6 c0             	movzbl %al,%eax
f01050be:	0f b6 12             	movzbl (%edx),%edx
f01050c1:	29 d0                	sub    %edx,%eax
}
f01050c3:	5d                   	pop    %ebp
f01050c4:	c3                   	ret    

f01050c5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01050c5:	55                   	push   %ebp
f01050c6:	89 e5                	mov    %esp,%ebp
f01050c8:	53                   	push   %ebx
f01050c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01050cc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01050cf:	89 c3                	mov    %eax,%ebx
f01050d1:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01050d4:	eb 06                	jmp    f01050dc <strncmp+0x17>
		n--, p++, q++;
f01050d6:	83 c0 01             	add    $0x1,%eax
f01050d9:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01050dc:	39 d8                	cmp    %ebx,%eax
f01050de:	74 15                	je     f01050f5 <strncmp+0x30>
f01050e0:	0f b6 08             	movzbl (%eax),%ecx
f01050e3:	84 c9                	test   %cl,%cl
f01050e5:	74 04                	je     f01050eb <strncmp+0x26>
f01050e7:	3a 0a                	cmp    (%edx),%cl
f01050e9:	74 eb                	je     f01050d6 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01050eb:	0f b6 00             	movzbl (%eax),%eax
f01050ee:	0f b6 12             	movzbl (%edx),%edx
f01050f1:	29 d0                	sub    %edx,%eax
f01050f3:	eb 05                	jmp    f01050fa <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01050f5:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01050fa:	5b                   	pop    %ebx
f01050fb:	5d                   	pop    %ebp
f01050fc:	c3                   	ret    

f01050fd <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01050fd:	55                   	push   %ebp
f01050fe:	89 e5                	mov    %esp,%ebp
f0105100:	8b 45 08             	mov    0x8(%ebp),%eax
f0105103:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105107:	eb 07                	jmp    f0105110 <strchr+0x13>
		if (*s == c)
f0105109:	38 ca                	cmp    %cl,%dl
f010510b:	74 0f                	je     f010511c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010510d:	83 c0 01             	add    $0x1,%eax
f0105110:	0f b6 10             	movzbl (%eax),%edx
f0105113:	84 d2                	test   %dl,%dl
f0105115:	75 f2                	jne    f0105109 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105117:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010511c:	5d                   	pop    %ebp
f010511d:	c3                   	ret    

f010511e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010511e:	55                   	push   %ebp
f010511f:	89 e5                	mov    %esp,%ebp
f0105121:	8b 45 08             	mov    0x8(%ebp),%eax
f0105124:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105128:	eb 03                	jmp    f010512d <strfind+0xf>
f010512a:	83 c0 01             	add    $0x1,%eax
f010512d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105130:	38 ca                	cmp    %cl,%dl
f0105132:	74 04                	je     f0105138 <strfind+0x1a>
f0105134:	84 d2                	test   %dl,%dl
f0105136:	75 f2                	jne    f010512a <strfind+0xc>
			break;
	return (char *) s;
}
f0105138:	5d                   	pop    %ebp
f0105139:	c3                   	ret    

f010513a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010513a:	55                   	push   %ebp
f010513b:	89 e5                	mov    %esp,%ebp
f010513d:	57                   	push   %edi
f010513e:	56                   	push   %esi
f010513f:	53                   	push   %ebx
f0105140:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105143:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105146:	85 c9                	test   %ecx,%ecx
f0105148:	74 36                	je     f0105180 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010514a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105150:	75 28                	jne    f010517a <memset+0x40>
f0105152:	f6 c1 03             	test   $0x3,%cl
f0105155:	75 23                	jne    f010517a <memset+0x40>
		c &= 0xFF;
f0105157:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010515b:	89 d3                	mov    %edx,%ebx
f010515d:	c1 e3 08             	shl    $0x8,%ebx
f0105160:	89 d6                	mov    %edx,%esi
f0105162:	c1 e6 18             	shl    $0x18,%esi
f0105165:	89 d0                	mov    %edx,%eax
f0105167:	c1 e0 10             	shl    $0x10,%eax
f010516a:	09 f0                	or     %esi,%eax
f010516c:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010516e:	89 d8                	mov    %ebx,%eax
f0105170:	09 d0                	or     %edx,%eax
f0105172:	c1 e9 02             	shr    $0x2,%ecx
f0105175:	fc                   	cld    
f0105176:	f3 ab                	rep stos %eax,%es:(%edi)
f0105178:	eb 06                	jmp    f0105180 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010517a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010517d:	fc                   	cld    
f010517e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105180:	89 f8                	mov    %edi,%eax
f0105182:	5b                   	pop    %ebx
f0105183:	5e                   	pop    %esi
f0105184:	5f                   	pop    %edi
f0105185:	5d                   	pop    %ebp
f0105186:	c3                   	ret    

f0105187 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105187:	55                   	push   %ebp
f0105188:	89 e5                	mov    %esp,%ebp
f010518a:	57                   	push   %edi
f010518b:	56                   	push   %esi
f010518c:	8b 45 08             	mov    0x8(%ebp),%eax
f010518f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105192:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105195:	39 c6                	cmp    %eax,%esi
f0105197:	73 35                	jae    f01051ce <memmove+0x47>
f0105199:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010519c:	39 d0                	cmp    %edx,%eax
f010519e:	73 2e                	jae    f01051ce <memmove+0x47>
		s += n;
		d += n;
f01051a0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01051a3:	89 d6                	mov    %edx,%esi
f01051a5:	09 fe                	or     %edi,%esi
f01051a7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01051ad:	75 13                	jne    f01051c2 <memmove+0x3b>
f01051af:	f6 c1 03             	test   $0x3,%cl
f01051b2:	75 0e                	jne    f01051c2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01051b4:	83 ef 04             	sub    $0x4,%edi
f01051b7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01051ba:	c1 e9 02             	shr    $0x2,%ecx
f01051bd:	fd                   	std    
f01051be:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01051c0:	eb 09                	jmp    f01051cb <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01051c2:	83 ef 01             	sub    $0x1,%edi
f01051c5:	8d 72 ff             	lea    -0x1(%edx),%esi
f01051c8:	fd                   	std    
f01051c9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01051cb:	fc                   	cld    
f01051cc:	eb 1d                	jmp    f01051eb <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01051ce:	89 f2                	mov    %esi,%edx
f01051d0:	09 c2                	or     %eax,%edx
f01051d2:	f6 c2 03             	test   $0x3,%dl
f01051d5:	75 0f                	jne    f01051e6 <memmove+0x5f>
f01051d7:	f6 c1 03             	test   $0x3,%cl
f01051da:	75 0a                	jne    f01051e6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01051dc:	c1 e9 02             	shr    $0x2,%ecx
f01051df:	89 c7                	mov    %eax,%edi
f01051e1:	fc                   	cld    
f01051e2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01051e4:	eb 05                	jmp    f01051eb <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01051e6:	89 c7                	mov    %eax,%edi
f01051e8:	fc                   	cld    
f01051e9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01051eb:	5e                   	pop    %esi
f01051ec:	5f                   	pop    %edi
f01051ed:	5d                   	pop    %ebp
f01051ee:	c3                   	ret    

f01051ef <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01051ef:	55                   	push   %ebp
f01051f0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01051f2:	ff 75 10             	pushl  0x10(%ebp)
f01051f5:	ff 75 0c             	pushl  0xc(%ebp)
f01051f8:	ff 75 08             	pushl  0x8(%ebp)
f01051fb:	e8 87 ff ff ff       	call   f0105187 <memmove>
}
f0105200:	c9                   	leave  
f0105201:	c3                   	ret    

f0105202 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105202:	55                   	push   %ebp
f0105203:	89 e5                	mov    %esp,%ebp
f0105205:	56                   	push   %esi
f0105206:	53                   	push   %ebx
f0105207:	8b 45 08             	mov    0x8(%ebp),%eax
f010520a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010520d:	89 c6                	mov    %eax,%esi
f010520f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105212:	eb 1a                	jmp    f010522e <memcmp+0x2c>
		if (*s1 != *s2)
f0105214:	0f b6 08             	movzbl (%eax),%ecx
f0105217:	0f b6 1a             	movzbl (%edx),%ebx
f010521a:	38 d9                	cmp    %bl,%cl
f010521c:	74 0a                	je     f0105228 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010521e:	0f b6 c1             	movzbl %cl,%eax
f0105221:	0f b6 db             	movzbl %bl,%ebx
f0105224:	29 d8                	sub    %ebx,%eax
f0105226:	eb 0f                	jmp    f0105237 <memcmp+0x35>
		s1++, s2++;
f0105228:	83 c0 01             	add    $0x1,%eax
f010522b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010522e:	39 f0                	cmp    %esi,%eax
f0105230:	75 e2                	jne    f0105214 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105232:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105237:	5b                   	pop    %ebx
f0105238:	5e                   	pop    %esi
f0105239:	5d                   	pop    %ebp
f010523a:	c3                   	ret    

f010523b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010523b:	55                   	push   %ebp
f010523c:	89 e5                	mov    %esp,%ebp
f010523e:	53                   	push   %ebx
f010523f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0105242:	89 c1                	mov    %eax,%ecx
f0105244:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105247:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010524b:	eb 0a                	jmp    f0105257 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010524d:	0f b6 10             	movzbl (%eax),%edx
f0105250:	39 da                	cmp    %ebx,%edx
f0105252:	74 07                	je     f010525b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105254:	83 c0 01             	add    $0x1,%eax
f0105257:	39 c8                	cmp    %ecx,%eax
f0105259:	72 f2                	jb     f010524d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010525b:	5b                   	pop    %ebx
f010525c:	5d                   	pop    %ebp
f010525d:	c3                   	ret    

f010525e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010525e:	55                   	push   %ebp
f010525f:	89 e5                	mov    %esp,%ebp
f0105261:	57                   	push   %edi
f0105262:	56                   	push   %esi
f0105263:	53                   	push   %ebx
f0105264:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105267:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010526a:	eb 03                	jmp    f010526f <strtol+0x11>
		s++;
f010526c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010526f:	0f b6 01             	movzbl (%ecx),%eax
f0105272:	3c 20                	cmp    $0x20,%al
f0105274:	74 f6                	je     f010526c <strtol+0xe>
f0105276:	3c 09                	cmp    $0x9,%al
f0105278:	74 f2                	je     f010526c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010527a:	3c 2b                	cmp    $0x2b,%al
f010527c:	75 0a                	jne    f0105288 <strtol+0x2a>
		s++;
f010527e:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105281:	bf 00 00 00 00       	mov    $0x0,%edi
f0105286:	eb 11                	jmp    f0105299 <strtol+0x3b>
f0105288:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010528d:	3c 2d                	cmp    $0x2d,%al
f010528f:	75 08                	jne    f0105299 <strtol+0x3b>
		s++, neg = 1;
f0105291:	83 c1 01             	add    $0x1,%ecx
f0105294:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105299:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010529f:	75 15                	jne    f01052b6 <strtol+0x58>
f01052a1:	80 39 30             	cmpb   $0x30,(%ecx)
f01052a4:	75 10                	jne    f01052b6 <strtol+0x58>
f01052a6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01052aa:	75 7c                	jne    f0105328 <strtol+0xca>
		s += 2, base = 16;
f01052ac:	83 c1 02             	add    $0x2,%ecx
f01052af:	bb 10 00 00 00       	mov    $0x10,%ebx
f01052b4:	eb 16                	jmp    f01052cc <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01052b6:	85 db                	test   %ebx,%ebx
f01052b8:	75 12                	jne    f01052cc <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01052ba:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01052bf:	80 39 30             	cmpb   $0x30,(%ecx)
f01052c2:	75 08                	jne    f01052cc <strtol+0x6e>
		s++, base = 8;
f01052c4:	83 c1 01             	add    $0x1,%ecx
f01052c7:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01052cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01052d1:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01052d4:	0f b6 11             	movzbl (%ecx),%edx
f01052d7:	8d 72 d0             	lea    -0x30(%edx),%esi
f01052da:	89 f3                	mov    %esi,%ebx
f01052dc:	80 fb 09             	cmp    $0x9,%bl
f01052df:	77 08                	ja     f01052e9 <strtol+0x8b>
			dig = *s - '0';
f01052e1:	0f be d2             	movsbl %dl,%edx
f01052e4:	83 ea 30             	sub    $0x30,%edx
f01052e7:	eb 22                	jmp    f010530b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01052e9:	8d 72 9f             	lea    -0x61(%edx),%esi
f01052ec:	89 f3                	mov    %esi,%ebx
f01052ee:	80 fb 19             	cmp    $0x19,%bl
f01052f1:	77 08                	ja     f01052fb <strtol+0x9d>
			dig = *s - 'a' + 10;
f01052f3:	0f be d2             	movsbl %dl,%edx
f01052f6:	83 ea 57             	sub    $0x57,%edx
f01052f9:	eb 10                	jmp    f010530b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01052fb:	8d 72 bf             	lea    -0x41(%edx),%esi
f01052fe:	89 f3                	mov    %esi,%ebx
f0105300:	80 fb 19             	cmp    $0x19,%bl
f0105303:	77 16                	ja     f010531b <strtol+0xbd>
			dig = *s - 'A' + 10;
f0105305:	0f be d2             	movsbl %dl,%edx
f0105308:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010530b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010530e:	7d 0b                	jge    f010531b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0105310:	83 c1 01             	add    $0x1,%ecx
f0105313:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105317:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105319:	eb b9                	jmp    f01052d4 <strtol+0x76>

	if (endptr)
f010531b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010531f:	74 0d                	je     f010532e <strtol+0xd0>
		*endptr = (char *) s;
f0105321:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105324:	89 0e                	mov    %ecx,(%esi)
f0105326:	eb 06                	jmp    f010532e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105328:	85 db                	test   %ebx,%ebx
f010532a:	74 98                	je     f01052c4 <strtol+0x66>
f010532c:	eb 9e                	jmp    f01052cc <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010532e:	89 c2                	mov    %eax,%edx
f0105330:	f7 da                	neg    %edx
f0105332:	85 ff                	test   %edi,%edi
f0105334:	0f 45 c2             	cmovne %edx,%eax
}
f0105337:	5b                   	pop    %ebx
f0105338:	5e                   	pop    %esi
f0105339:	5f                   	pop    %edi
f010533a:	5d                   	pop    %ebp
f010533b:	c3                   	ret    

f010533c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010533c:	fa                   	cli    

	xorw    %ax, %ax
f010533d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010533f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105341:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105343:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105345:	0f 01 16             	lgdtl  (%esi)
f0105348:	74 70                	je     f01053ba <mpsearch1+0x3>
	movl    %cr0, %eax
f010534a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010534d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105351:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105354:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010535a:	08 00                	or     %al,(%eax)

f010535c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010535c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105360:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105362:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105364:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105366:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010536a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010536c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010536e:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0105373:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105376:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105379:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010537e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105381:	8b 25 84 ee 22 f0    	mov    0xf022ee84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105387:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010538c:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f0105391:	ff d0                	call   *%eax

f0105393 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105393:	eb fe                	jmp    f0105393 <spin>
f0105395:	8d 76 00             	lea    0x0(%esi),%esi

f0105398 <gdt>:
	...
f01053a0:	ff                   	(bad)  
f01053a1:	ff 00                	incl   (%eax)
f01053a3:	00 00                	add    %al,(%eax)
f01053a5:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01053ac:	00                   	.byte 0x0
f01053ad:	92                   	xchg   %eax,%edx
f01053ae:	cf                   	iret   
	...

f01053b0 <gdtdesc>:
f01053b0:	17                   	pop    %ss
f01053b1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01053b6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01053b6:	90                   	nop

f01053b7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01053b7:	55                   	push   %ebp
f01053b8:	89 e5                	mov    %esp,%ebp
f01053ba:	57                   	push   %edi
f01053bb:	56                   	push   %esi
f01053bc:	53                   	push   %ebx
f01053bd:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01053c0:	8b 0d 88 ee 22 f0    	mov    0xf022ee88,%ecx
f01053c6:	89 c3                	mov    %eax,%ebx
f01053c8:	c1 eb 0c             	shr    $0xc,%ebx
f01053cb:	39 cb                	cmp    %ecx,%ebx
f01053cd:	72 12                	jb     f01053e1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01053cf:	50                   	push   %eax
f01053d0:	68 24 5e 10 f0       	push   $0xf0105e24
f01053d5:	6a 57                	push   $0x57
f01053d7:	68 81 79 10 f0       	push   $0xf0107981
f01053dc:	e8 5f ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01053e1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01053e7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01053e9:	89 c2                	mov    %eax,%edx
f01053eb:	c1 ea 0c             	shr    $0xc,%edx
f01053ee:	39 ca                	cmp    %ecx,%edx
f01053f0:	72 12                	jb     f0105404 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01053f2:	50                   	push   %eax
f01053f3:	68 24 5e 10 f0       	push   $0xf0105e24
f01053f8:	6a 57                	push   $0x57
f01053fa:	68 81 79 10 f0       	push   $0xf0107981
f01053ff:	e8 3c ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105404:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010540a:	eb 2f                	jmp    f010543b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010540c:	83 ec 04             	sub    $0x4,%esp
f010540f:	6a 04                	push   $0x4
f0105411:	68 91 79 10 f0       	push   $0xf0107991
f0105416:	53                   	push   %ebx
f0105417:	e8 e6 fd ff ff       	call   f0105202 <memcmp>
f010541c:	83 c4 10             	add    $0x10,%esp
f010541f:	85 c0                	test   %eax,%eax
f0105421:	75 15                	jne    f0105438 <mpsearch1+0x81>
f0105423:	89 da                	mov    %ebx,%edx
f0105425:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105428:	0f b6 0a             	movzbl (%edx),%ecx
f010542b:	01 c8                	add    %ecx,%eax
f010542d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105430:	39 d7                	cmp    %edx,%edi
f0105432:	75 f4                	jne    f0105428 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105434:	84 c0                	test   %al,%al
f0105436:	74 0e                	je     f0105446 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105438:	83 c3 10             	add    $0x10,%ebx
f010543b:	39 f3                	cmp    %esi,%ebx
f010543d:	72 cd                	jb     f010540c <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010543f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105444:	eb 02                	jmp    f0105448 <mpsearch1+0x91>
f0105446:	89 d8                	mov    %ebx,%eax
}
f0105448:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010544b:	5b                   	pop    %ebx
f010544c:	5e                   	pop    %esi
f010544d:	5f                   	pop    %edi
f010544e:	5d                   	pop    %ebp
f010544f:	c3                   	ret    

f0105450 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105450:	55                   	push   %ebp
f0105451:	89 e5                	mov    %esp,%ebp
f0105453:	57                   	push   %edi
f0105454:	56                   	push   %esi
f0105455:	53                   	push   %ebx
f0105456:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105459:	c7 05 c0 f3 22 f0 20 	movl   $0xf022f020,0xf022f3c0
f0105460:	f0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105463:	83 3d 88 ee 22 f0 00 	cmpl   $0x0,0xf022ee88
f010546a:	75 16                	jne    f0105482 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010546c:	68 00 04 00 00       	push   $0x400
f0105471:	68 24 5e 10 f0       	push   $0xf0105e24
f0105476:	6a 6f                	push   $0x6f
f0105478:	68 81 79 10 f0       	push   $0xf0107981
f010547d:	e8 be ab ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105482:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105489:	85 c0                	test   %eax,%eax
f010548b:	74 16                	je     f01054a3 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010548d:	c1 e0 04             	shl    $0x4,%eax
f0105490:	ba 00 04 00 00       	mov    $0x400,%edx
f0105495:	e8 1d ff ff ff       	call   f01053b7 <mpsearch1>
f010549a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010549d:	85 c0                	test   %eax,%eax
f010549f:	75 3c                	jne    f01054dd <mp_init+0x8d>
f01054a1:	eb 20                	jmp    f01054c3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f01054a3:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f01054aa:	c1 e0 0a             	shl    $0xa,%eax
f01054ad:	2d 00 04 00 00       	sub    $0x400,%eax
f01054b2:	ba 00 04 00 00       	mov    $0x400,%edx
f01054b7:	e8 fb fe ff ff       	call   f01053b7 <mpsearch1>
f01054bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01054bf:	85 c0                	test   %eax,%eax
f01054c1:	75 1a                	jne    f01054dd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01054c3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01054c8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01054cd:	e8 e5 fe ff ff       	call   f01053b7 <mpsearch1>
f01054d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01054d5:	85 c0                	test   %eax,%eax
f01054d7:	0f 84 5d 02 00 00    	je     f010573a <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01054dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01054e0:	8b 70 04             	mov    0x4(%eax),%esi
f01054e3:	85 f6                	test   %esi,%esi
f01054e5:	74 06                	je     f01054ed <mp_init+0x9d>
f01054e7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01054eb:	74 15                	je     f0105502 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01054ed:	83 ec 0c             	sub    $0xc,%esp
f01054f0:	68 f4 77 10 f0       	push   $0xf01077f4
f01054f5:	e8 84 e1 ff ff       	call   f010367e <cprintf>
f01054fa:	83 c4 10             	add    $0x10,%esp
f01054fd:	e9 38 02 00 00       	jmp    f010573a <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105502:	89 f0                	mov    %esi,%eax
f0105504:	c1 e8 0c             	shr    $0xc,%eax
f0105507:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f010550d:	72 15                	jb     f0105524 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010550f:	56                   	push   %esi
f0105510:	68 24 5e 10 f0       	push   $0xf0105e24
f0105515:	68 90 00 00 00       	push   $0x90
f010551a:	68 81 79 10 f0       	push   $0xf0107981
f010551f:	e8 1c ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105524:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010552a:	83 ec 04             	sub    $0x4,%esp
f010552d:	6a 04                	push   $0x4
f010552f:	68 96 79 10 f0       	push   $0xf0107996
f0105534:	53                   	push   %ebx
f0105535:	e8 c8 fc ff ff       	call   f0105202 <memcmp>
f010553a:	83 c4 10             	add    $0x10,%esp
f010553d:	85 c0                	test   %eax,%eax
f010553f:	74 15                	je     f0105556 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105541:	83 ec 0c             	sub    $0xc,%esp
f0105544:	68 24 78 10 f0       	push   $0xf0107824
f0105549:	e8 30 e1 ff ff       	call   f010367e <cprintf>
f010554e:	83 c4 10             	add    $0x10,%esp
f0105551:	e9 e4 01 00 00       	jmp    f010573a <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105556:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010555a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010555e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105561:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105566:	b8 00 00 00 00       	mov    $0x0,%eax
f010556b:	eb 0d                	jmp    f010557a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010556d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105574:	f0 
f0105575:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105577:	83 c0 01             	add    $0x1,%eax
f010557a:	39 c7                	cmp    %eax,%edi
f010557c:	75 ef                	jne    f010556d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010557e:	84 d2                	test   %dl,%dl
f0105580:	74 15                	je     f0105597 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105582:	83 ec 0c             	sub    $0xc,%esp
f0105585:	68 58 78 10 f0       	push   $0xf0107858
f010558a:	e8 ef e0 ff ff       	call   f010367e <cprintf>
f010558f:	83 c4 10             	add    $0x10,%esp
f0105592:	e9 a3 01 00 00       	jmp    f010573a <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105597:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010559b:	3c 01                	cmp    $0x1,%al
f010559d:	74 1d                	je     f01055bc <mp_init+0x16c>
f010559f:	3c 04                	cmp    $0x4,%al
f01055a1:	74 19                	je     f01055bc <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01055a3:	83 ec 08             	sub    $0x8,%esp
f01055a6:	0f b6 c0             	movzbl %al,%eax
f01055a9:	50                   	push   %eax
f01055aa:	68 7c 78 10 f0       	push   $0xf010787c
f01055af:	e8 ca e0 ff ff       	call   f010367e <cprintf>
f01055b4:	83 c4 10             	add    $0x10,%esp
f01055b7:	e9 7e 01 00 00       	jmp    f010573a <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01055bc:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01055c0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01055c4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01055c9:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f01055ce:	01 ce                	add    %ecx,%esi
f01055d0:	eb 0d                	jmp    f01055df <mp_init+0x18f>
f01055d2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01055d9:	f0 
f01055da:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01055dc:	83 c0 01             	add    $0x1,%eax
f01055df:	39 c7                	cmp    %eax,%edi
f01055e1:	75 ef                	jne    f01055d2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01055e3:	89 d0                	mov    %edx,%eax
f01055e5:	02 43 2a             	add    0x2a(%ebx),%al
f01055e8:	74 15                	je     f01055ff <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01055ea:	83 ec 0c             	sub    $0xc,%esp
f01055ed:	68 9c 78 10 f0       	push   $0xf010789c
f01055f2:	e8 87 e0 ff ff       	call   f010367e <cprintf>
f01055f7:	83 c4 10             	add    $0x10,%esp
f01055fa:	e9 3b 01 00 00       	jmp    f010573a <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01055ff:	85 db                	test   %ebx,%ebx
f0105601:	0f 84 33 01 00 00    	je     f010573a <mp_init+0x2ea>
		return;
	ismp = 1;
f0105607:	c7 05 00 f0 22 f0 01 	movl   $0x1,0xf022f000
f010560e:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105611:	8b 43 24             	mov    0x24(%ebx),%eax
f0105614:	a3 00 00 27 f0       	mov    %eax,0xf0270000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105619:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010561c:	be 00 00 00 00       	mov    $0x0,%esi
f0105621:	e9 85 00 00 00       	jmp    f01056ab <mp_init+0x25b>
		switch (*p) {
f0105626:	0f b6 07             	movzbl (%edi),%eax
f0105629:	84 c0                	test   %al,%al
f010562b:	74 06                	je     f0105633 <mp_init+0x1e3>
f010562d:	3c 04                	cmp    $0x4,%al
f010562f:	77 55                	ja     f0105686 <mp_init+0x236>
f0105631:	eb 4e                	jmp    f0105681 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105633:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105637:	74 11                	je     f010564a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105639:	6b 05 c4 f3 22 f0 74 	imul   $0x74,0xf022f3c4,%eax
f0105640:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f0105645:	a3 c0 f3 22 f0       	mov    %eax,0xf022f3c0
			if (ncpu < NCPU) {
f010564a:	a1 c4 f3 22 f0       	mov    0xf022f3c4,%eax
f010564f:	83 f8 07             	cmp    $0x7,%eax
f0105652:	7f 13                	jg     f0105667 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105654:	6b d0 74             	imul   $0x74,%eax,%edx
f0105657:	88 82 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%edx)
				ncpu++;
f010565d:	83 c0 01             	add    $0x1,%eax
f0105660:	a3 c4 f3 22 f0       	mov    %eax,0xf022f3c4
f0105665:	eb 15                	jmp    f010567c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105667:	83 ec 08             	sub    $0x8,%esp
f010566a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010566e:	50                   	push   %eax
f010566f:	68 cc 78 10 f0       	push   $0xf01078cc
f0105674:	e8 05 e0 ff ff       	call   f010367e <cprintf>
f0105679:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010567c:	83 c7 14             	add    $0x14,%edi
			continue;
f010567f:	eb 27                	jmp    f01056a8 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105681:	83 c7 08             	add    $0x8,%edi
			continue;
f0105684:	eb 22                	jmp    f01056a8 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105686:	83 ec 08             	sub    $0x8,%esp
f0105689:	0f b6 c0             	movzbl %al,%eax
f010568c:	50                   	push   %eax
f010568d:	68 f4 78 10 f0       	push   $0xf01078f4
f0105692:	e8 e7 df ff ff       	call   f010367e <cprintf>
			ismp = 0;
f0105697:	c7 05 00 f0 22 f0 00 	movl   $0x0,0xf022f000
f010569e:	00 00 00 
			i = conf->entry;
f01056a1:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f01056a5:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01056a8:	83 c6 01             	add    $0x1,%esi
f01056ab:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01056af:	39 c6                	cmp    %eax,%esi
f01056b1:	0f 82 6f ff ff ff    	jb     f0105626 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01056b7:	a1 c0 f3 22 f0       	mov    0xf022f3c0,%eax
f01056bc:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01056c3:	83 3d 00 f0 22 f0 00 	cmpl   $0x0,0xf022f000
f01056ca:	75 26                	jne    f01056f2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01056cc:	c7 05 c4 f3 22 f0 01 	movl   $0x1,0xf022f3c4
f01056d3:	00 00 00 
		lapicaddr = 0;
f01056d6:	c7 05 00 00 27 f0 00 	movl   $0x0,0xf0270000
f01056dd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01056e0:	83 ec 0c             	sub    $0xc,%esp
f01056e3:	68 14 79 10 f0       	push   $0xf0107914
f01056e8:	e8 91 df ff ff       	call   f010367e <cprintf>
		return;
f01056ed:	83 c4 10             	add    $0x10,%esp
f01056f0:	eb 48                	jmp    f010573a <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01056f2:	83 ec 04             	sub    $0x4,%esp
f01056f5:	ff 35 c4 f3 22 f0    	pushl  0xf022f3c4
f01056fb:	0f b6 00             	movzbl (%eax),%eax
f01056fe:	50                   	push   %eax
f01056ff:	68 9b 79 10 f0       	push   $0xf010799b
f0105704:	e8 75 df ff ff       	call   f010367e <cprintf>

	if (mp->imcrp) {
f0105709:	83 c4 10             	add    $0x10,%esp
f010570c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010570f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105713:	74 25                	je     f010573a <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105715:	83 ec 0c             	sub    $0xc,%esp
f0105718:	68 40 79 10 f0       	push   $0xf0107940
f010571d:	e8 5c df ff ff       	call   f010367e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105722:	ba 22 00 00 00       	mov    $0x22,%edx
f0105727:	b8 70 00 00 00       	mov    $0x70,%eax
f010572c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010572d:	ba 23 00 00 00       	mov    $0x23,%edx
f0105732:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105733:	83 c8 01             	or     $0x1,%eax
f0105736:	ee                   	out    %al,(%dx)
f0105737:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f010573a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010573d:	5b                   	pop    %ebx
f010573e:	5e                   	pop    %esi
f010573f:	5f                   	pop    %edi
f0105740:	5d                   	pop    %ebp
f0105741:	c3                   	ret    

f0105742 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105742:	55                   	push   %ebp
f0105743:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105745:	8b 0d 04 00 27 f0    	mov    0xf0270004,%ecx
f010574b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010574e:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105750:	a1 04 00 27 f0       	mov    0xf0270004,%eax
f0105755:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105758:	5d                   	pop    %ebp
f0105759:	c3                   	ret    

f010575a <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010575a:	55                   	push   %ebp
f010575b:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010575d:	a1 04 00 27 f0       	mov    0xf0270004,%eax
f0105762:	85 c0                	test   %eax,%eax
f0105764:	74 08                	je     f010576e <cpunum+0x14>
		return lapic[ID] >> 24;
f0105766:	8b 40 20             	mov    0x20(%eax),%eax
f0105769:	c1 e8 18             	shr    $0x18,%eax
f010576c:	eb 05                	jmp    f0105773 <cpunum+0x19>
	return 0;
f010576e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105773:	5d                   	pop    %ebp
f0105774:	c3                   	ret    

f0105775 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105775:	a1 00 00 27 f0       	mov    0xf0270000,%eax
f010577a:	85 c0                	test   %eax,%eax
f010577c:	0f 84 21 01 00 00    	je     f01058a3 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105782:	55                   	push   %ebp
f0105783:	89 e5                	mov    %esp,%ebp
f0105785:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105788:	68 00 10 00 00       	push   $0x1000
f010578d:	50                   	push   %eax
f010578e:	e8 8f bb ff ff       	call   f0101322 <mmio_map_region>
f0105793:	a3 04 00 27 f0       	mov    %eax,0xf0270004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105798:	ba 27 01 00 00       	mov    $0x127,%edx
f010579d:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01057a2:	e8 9b ff ff ff       	call   f0105742 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f01057a7:	ba 0b 00 00 00       	mov    $0xb,%edx
f01057ac:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01057b1:	e8 8c ff ff ff       	call   f0105742 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01057b6:	ba 20 00 02 00       	mov    $0x20020,%edx
f01057bb:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01057c0:	e8 7d ff ff ff       	call   f0105742 <lapicw>
	lapicw(TICR, 10000000); 
f01057c5:	ba 80 96 98 00       	mov    $0x989680,%edx
f01057ca:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01057cf:	e8 6e ff ff ff       	call   f0105742 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01057d4:	e8 81 ff ff ff       	call   f010575a <cpunum>
f01057d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01057dc:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f01057e1:	83 c4 10             	add    $0x10,%esp
f01057e4:	39 05 c0 f3 22 f0    	cmp    %eax,0xf022f3c0
f01057ea:	74 0f                	je     f01057fb <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01057ec:	ba 00 00 01 00       	mov    $0x10000,%edx
f01057f1:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01057f6:	e8 47 ff ff ff       	call   f0105742 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01057fb:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105800:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105805:	e8 38 ff ff ff       	call   f0105742 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010580a:	a1 04 00 27 f0       	mov    0xf0270004,%eax
f010580f:	8b 40 30             	mov    0x30(%eax),%eax
f0105812:	c1 e8 10             	shr    $0x10,%eax
f0105815:	3c 03                	cmp    $0x3,%al
f0105817:	76 0f                	jbe    f0105828 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105819:	ba 00 00 01 00       	mov    $0x10000,%edx
f010581e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105823:	e8 1a ff ff ff       	call   f0105742 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105828:	ba 33 00 00 00       	mov    $0x33,%edx
f010582d:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105832:	e8 0b ff ff ff       	call   f0105742 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105837:	ba 00 00 00 00       	mov    $0x0,%edx
f010583c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105841:	e8 fc fe ff ff       	call   f0105742 <lapicw>
	lapicw(ESR, 0);
f0105846:	ba 00 00 00 00       	mov    $0x0,%edx
f010584b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105850:	e8 ed fe ff ff       	call   f0105742 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105855:	ba 00 00 00 00       	mov    $0x0,%edx
f010585a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010585f:	e8 de fe ff ff       	call   f0105742 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105864:	ba 00 00 00 00       	mov    $0x0,%edx
f0105869:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010586e:	e8 cf fe ff ff       	call   f0105742 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105873:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105878:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010587d:	e8 c0 fe ff ff       	call   f0105742 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105882:	8b 15 04 00 27 f0    	mov    0xf0270004,%edx
f0105888:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010588e:	f6 c4 10             	test   $0x10,%ah
f0105891:	75 f5                	jne    f0105888 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105893:	ba 00 00 00 00       	mov    $0x0,%edx
f0105898:	b8 20 00 00 00       	mov    $0x20,%eax
f010589d:	e8 a0 fe ff ff       	call   f0105742 <lapicw>
}
f01058a2:	c9                   	leave  
f01058a3:	f3 c3                	repz ret 

f01058a5 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01058a5:	83 3d 04 00 27 f0 00 	cmpl   $0x0,0xf0270004
f01058ac:	74 13                	je     f01058c1 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f01058ae:	55                   	push   %ebp
f01058af:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f01058b1:	ba 00 00 00 00       	mov    $0x0,%edx
f01058b6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01058bb:	e8 82 fe ff ff       	call   f0105742 <lapicw>
}
f01058c0:	5d                   	pop    %ebp
f01058c1:	f3 c3                	repz ret 

f01058c3 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01058c3:	55                   	push   %ebp
f01058c4:	89 e5                	mov    %esp,%ebp
f01058c6:	56                   	push   %esi
f01058c7:	53                   	push   %ebx
f01058c8:	8b 75 08             	mov    0x8(%ebp),%esi
f01058cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01058ce:	ba 70 00 00 00       	mov    $0x70,%edx
f01058d3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01058d8:	ee                   	out    %al,(%dx)
f01058d9:	ba 71 00 00 00       	mov    $0x71,%edx
f01058de:	b8 0a 00 00 00       	mov    $0xa,%eax
f01058e3:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01058e4:	83 3d 88 ee 22 f0 00 	cmpl   $0x0,0xf022ee88
f01058eb:	75 19                	jne    f0105906 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058ed:	68 67 04 00 00       	push   $0x467
f01058f2:	68 24 5e 10 f0       	push   $0xf0105e24
f01058f7:	68 98 00 00 00       	push   $0x98
f01058fc:	68 b8 79 10 f0       	push   $0xf01079b8
f0105901:	e8 3a a7 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105906:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f010590d:	00 00 
	wrv[1] = addr >> 4;
f010590f:	89 d8                	mov    %ebx,%eax
f0105911:	c1 e8 04             	shr    $0x4,%eax
f0105914:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f010591a:	c1 e6 18             	shl    $0x18,%esi
f010591d:	89 f2                	mov    %esi,%edx
f010591f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105924:	e8 19 fe ff ff       	call   f0105742 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105929:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010592e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105933:	e8 0a fe ff ff       	call   f0105742 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105938:	ba 00 85 00 00       	mov    $0x8500,%edx
f010593d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105942:	e8 fb fd ff ff       	call   f0105742 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105947:	c1 eb 0c             	shr    $0xc,%ebx
f010594a:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010594d:	89 f2                	mov    %esi,%edx
f010594f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105954:	e8 e9 fd ff ff       	call   f0105742 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105959:	89 da                	mov    %ebx,%edx
f010595b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105960:	e8 dd fd ff ff       	call   f0105742 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105965:	89 f2                	mov    %esi,%edx
f0105967:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010596c:	e8 d1 fd ff ff       	call   f0105742 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105971:	89 da                	mov    %ebx,%edx
f0105973:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105978:	e8 c5 fd ff ff       	call   f0105742 <lapicw>
		microdelay(200);
	}
}
f010597d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105980:	5b                   	pop    %ebx
f0105981:	5e                   	pop    %esi
f0105982:	5d                   	pop    %ebp
f0105983:	c3                   	ret    

f0105984 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105984:	55                   	push   %ebp
f0105985:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105987:	8b 55 08             	mov    0x8(%ebp),%edx
f010598a:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105990:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105995:	e8 a8 fd ff ff       	call   f0105742 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010599a:	8b 15 04 00 27 f0    	mov    0xf0270004,%edx
f01059a0:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01059a6:	f6 c4 10             	test   $0x10,%ah
f01059a9:	75 f5                	jne    f01059a0 <lapic_ipi+0x1c>
		;
}
f01059ab:	5d                   	pop    %ebp
f01059ac:	c3                   	ret    

f01059ad <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01059ad:	55                   	push   %ebp
f01059ae:	89 e5                	mov    %esp,%ebp
f01059b0:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01059b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01059b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01059bc:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01059bf:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01059c6:	5d                   	pop    %ebp
f01059c7:	c3                   	ret    

f01059c8 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01059c8:	55                   	push   %ebp
f01059c9:	89 e5                	mov    %esp,%ebp
f01059cb:	56                   	push   %esi
f01059cc:	53                   	push   %ebx
f01059cd:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01059d0:	83 3b 00             	cmpl   $0x0,(%ebx)
f01059d3:	74 14                	je     f01059e9 <spin_lock+0x21>
f01059d5:	8b 73 08             	mov    0x8(%ebx),%esi
f01059d8:	e8 7d fd ff ff       	call   f010575a <cpunum>
f01059dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01059e0:	05 20 f0 22 f0       	add    $0xf022f020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01059e5:	39 c6                	cmp    %eax,%esi
f01059e7:	74 07                	je     f01059f0 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01059e9:	ba 01 00 00 00       	mov    $0x1,%edx
f01059ee:	eb 20                	jmp    f0105a10 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01059f0:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01059f3:	e8 62 fd ff ff       	call   f010575a <cpunum>
f01059f8:	83 ec 0c             	sub    $0xc,%esp
f01059fb:	53                   	push   %ebx
f01059fc:	50                   	push   %eax
f01059fd:	68 c8 79 10 f0       	push   $0xf01079c8
f0105a02:	6a 41                	push   $0x41
f0105a04:	68 2c 7a 10 f0       	push   $0xf0107a2c
f0105a09:	e8 32 a6 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105a0e:	f3 90                	pause  
f0105a10:	89 d0                	mov    %edx,%eax
f0105a12:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105a15:	85 c0                	test   %eax,%eax
f0105a17:	75 f5                	jne    f0105a0e <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105a19:	e8 3c fd ff ff       	call   f010575a <cpunum>
f0105a1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a21:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f0105a26:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105a29:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105a2c:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105a2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a33:	eb 0b                	jmp    f0105a40 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105a35:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105a38:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105a3b:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105a3d:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105a40:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105a46:	76 11                	jbe    f0105a59 <spin_lock+0x91>
f0105a48:	83 f8 09             	cmp    $0x9,%eax
f0105a4b:	7e e8                	jle    f0105a35 <spin_lock+0x6d>
f0105a4d:	eb 0a                	jmp    f0105a59 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105a4f:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105a56:	83 c0 01             	add    $0x1,%eax
f0105a59:	83 f8 09             	cmp    $0x9,%eax
f0105a5c:	7e f1                	jle    f0105a4f <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105a5e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105a61:	5b                   	pop    %ebx
f0105a62:	5e                   	pop    %esi
f0105a63:	5d                   	pop    %ebp
f0105a64:	c3                   	ret    

f0105a65 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105a65:	55                   	push   %ebp
f0105a66:	89 e5                	mov    %esp,%ebp
f0105a68:	57                   	push   %edi
f0105a69:	56                   	push   %esi
f0105a6a:	53                   	push   %ebx
f0105a6b:	83 ec 4c             	sub    $0x4c,%esp
f0105a6e:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105a71:	83 3e 00             	cmpl   $0x0,(%esi)
f0105a74:	74 18                	je     f0105a8e <spin_unlock+0x29>
f0105a76:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105a79:	e8 dc fc ff ff       	call   f010575a <cpunum>
f0105a7e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a81:	05 20 f0 22 f0       	add    $0xf022f020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105a86:	39 c3                	cmp    %eax,%ebx
f0105a88:	0f 84 a5 00 00 00    	je     f0105b33 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105a8e:	83 ec 04             	sub    $0x4,%esp
f0105a91:	6a 28                	push   $0x28
f0105a93:	8d 46 0c             	lea    0xc(%esi),%eax
f0105a96:	50                   	push   %eax
f0105a97:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105a9a:	53                   	push   %ebx
f0105a9b:	e8 e7 f6 ff ff       	call   f0105187 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105aa0:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105aa3:	0f b6 38             	movzbl (%eax),%edi
f0105aa6:	8b 76 04             	mov    0x4(%esi),%esi
f0105aa9:	e8 ac fc ff ff       	call   f010575a <cpunum>
f0105aae:	57                   	push   %edi
f0105aaf:	56                   	push   %esi
f0105ab0:	50                   	push   %eax
f0105ab1:	68 f4 79 10 f0       	push   $0xf01079f4
f0105ab6:	e8 c3 db ff ff       	call   f010367e <cprintf>
f0105abb:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105abe:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105ac1:	eb 54                	jmp    f0105b17 <spin_unlock+0xb2>
f0105ac3:	83 ec 08             	sub    $0x8,%esp
f0105ac6:	57                   	push   %edi
f0105ac7:	50                   	push   %eax
f0105ac8:	e8 fb eb ff ff       	call   f01046c8 <debuginfo_eip>
f0105acd:	83 c4 10             	add    $0x10,%esp
f0105ad0:	85 c0                	test   %eax,%eax
f0105ad2:	78 27                	js     f0105afb <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105ad4:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105ad6:	83 ec 04             	sub    $0x4,%esp
f0105ad9:	89 c2                	mov    %eax,%edx
f0105adb:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105ade:	52                   	push   %edx
f0105adf:	ff 75 b0             	pushl  -0x50(%ebp)
f0105ae2:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105ae5:	ff 75 ac             	pushl  -0x54(%ebp)
f0105ae8:	ff 75 a8             	pushl  -0x58(%ebp)
f0105aeb:	50                   	push   %eax
f0105aec:	68 3c 7a 10 f0       	push   $0xf0107a3c
f0105af1:	e8 88 db ff ff       	call   f010367e <cprintf>
f0105af6:	83 c4 20             	add    $0x20,%esp
f0105af9:	eb 12                	jmp    f0105b0d <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105afb:	83 ec 08             	sub    $0x8,%esp
f0105afe:	ff 36                	pushl  (%esi)
f0105b00:	68 53 7a 10 f0       	push   $0xf0107a53
f0105b05:	e8 74 db ff ff       	call   f010367e <cprintf>
f0105b0a:	83 c4 10             	add    $0x10,%esp
f0105b0d:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105b10:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105b13:	39 c3                	cmp    %eax,%ebx
f0105b15:	74 08                	je     f0105b1f <spin_unlock+0xba>
f0105b17:	89 de                	mov    %ebx,%esi
f0105b19:	8b 03                	mov    (%ebx),%eax
f0105b1b:	85 c0                	test   %eax,%eax
f0105b1d:	75 a4                	jne    f0105ac3 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105b1f:	83 ec 04             	sub    $0x4,%esp
f0105b22:	68 5b 7a 10 f0       	push   $0xf0107a5b
f0105b27:	6a 67                	push   $0x67
f0105b29:	68 2c 7a 10 f0       	push   $0xf0107a2c
f0105b2e:	e8 0d a5 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105b33:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105b3a:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105b41:	b8 00 00 00 00       	mov    $0x0,%eax
f0105b46:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105b49:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105b4c:	5b                   	pop    %ebx
f0105b4d:	5e                   	pop    %esi
f0105b4e:	5f                   	pop    %edi
f0105b4f:	5d                   	pop    %ebp
f0105b50:	c3                   	ret    
f0105b51:	66 90                	xchg   %ax,%ax
f0105b53:	66 90                	xchg   %ax,%ax
f0105b55:	66 90                	xchg   %ax,%ax
f0105b57:	66 90                	xchg   %ax,%ax
f0105b59:	66 90                	xchg   %ax,%ax
f0105b5b:	66 90                	xchg   %ax,%ax
f0105b5d:	66 90                	xchg   %ax,%ax
f0105b5f:	90                   	nop

f0105b60 <__udivdi3>:
f0105b60:	55                   	push   %ebp
f0105b61:	57                   	push   %edi
f0105b62:	56                   	push   %esi
f0105b63:	53                   	push   %ebx
f0105b64:	83 ec 1c             	sub    $0x1c,%esp
f0105b67:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105b6b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105b6f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105b73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105b77:	85 f6                	test   %esi,%esi
f0105b79:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105b7d:	89 ca                	mov    %ecx,%edx
f0105b7f:	89 f8                	mov    %edi,%eax
f0105b81:	75 3d                	jne    f0105bc0 <__udivdi3+0x60>
f0105b83:	39 cf                	cmp    %ecx,%edi
f0105b85:	0f 87 c5 00 00 00    	ja     f0105c50 <__udivdi3+0xf0>
f0105b8b:	85 ff                	test   %edi,%edi
f0105b8d:	89 fd                	mov    %edi,%ebp
f0105b8f:	75 0b                	jne    f0105b9c <__udivdi3+0x3c>
f0105b91:	b8 01 00 00 00       	mov    $0x1,%eax
f0105b96:	31 d2                	xor    %edx,%edx
f0105b98:	f7 f7                	div    %edi
f0105b9a:	89 c5                	mov    %eax,%ebp
f0105b9c:	89 c8                	mov    %ecx,%eax
f0105b9e:	31 d2                	xor    %edx,%edx
f0105ba0:	f7 f5                	div    %ebp
f0105ba2:	89 c1                	mov    %eax,%ecx
f0105ba4:	89 d8                	mov    %ebx,%eax
f0105ba6:	89 cf                	mov    %ecx,%edi
f0105ba8:	f7 f5                	div    %ebp
f0105baa:	89 c3                	mov    %eax,%ebx
f0105bac:	89 d8                	mov    %ebx,%eax
f0105bae:	89 fa                	mov    %edi,%edx
f0105bb0:	83 c4 1c             	add    $0x1c,%esp
f0105bb3:	5b                   	pop    %ebx
f0105bb4:	5e                   	pop    %esi
f0105bb5:	5f                   	pop    %edi
f0105bb6:	5d                   	pop    %ebp
f0105bb7:	c3                   	ret    
f0105bb8:	90                   	nop
f0105bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105bc0:	39 ce                	cmp    %ecx,%esi
f0105bc2:	77 74                	ja     f0105c38 <__udivdi3+0xd8>
f0105bc4:	0f bd fe             	bsr    %esi,%edi
f0105bc7:	83 f7 1f             	xor    $0x1f,%edi
f0105bca:	0f 84 98 00 00 00    	je     f0105c68 <__udivdi3+0x108>
f0105bd0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105bd5:	89 f9                	mov    %edi,%ecx
f0105bd7:	89 c5                	mov    %eax,%ebp
f0105bd9:	29 fb                	sub    %edi,%ebx
f0105bdb:	d3 e6                	shl    %cl,%esi
f0105bdd:	89 d9                	mov    %ebx,%ecx
f0105bdf:	d3 ed                	shr    %cl,%ebp
f0105be1:	89 f9                	mov    %edi,%ecx
f0105be3:	d3 e0                	shl    %cl,%eax
f0105be5:	09 ee                	or     %ebp,%esi
f0105be7:	89 d9                	mov    %ebx,%ecx
f0105be9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105bed:	89 d5                	mov    %edx,%ebp
f0105bef:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105bf3:	d3 ed                	shr    %cl,%ebp
f0105bf5:	89 f9                	mov    %edi,%ecx
f0105bf7:	d3 e2                	shl    %cl,%edx
f0105bf9:	89 d9                	mov    %ebx,%ecx
f0105bfb:	d3 e8                	shr    %cl,%eax
f0105bfd:	09 c2                	or     %eax,%edx
f0105bff:	89 d0                	mov    %edx,%eax
f0105c01:	89 ea                	mov    %ebp,%edx
f0105c03:	f7 f6                	div    %esi
f0105c05:	89 d5                	mov    %edx,%ebp
f0105c07:	89 c3                	mov    %eax,%ebx
f0105c09:	f7 64 24 0c          	mull   0xc(%esp)
f0105c0d:	39 d5                	cmp    %edx,%ebp
f0105c0f:	72 10                	jb     f0105c21 <__udivdi3+0xc1>
f0105c11:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105c15:	89 f9                	mov    %edi,%ecx
f0105c17:	d3 e6                	shl    %cl,%esi
f0105c19:	39 c6                	cmp    %eax,%esi
f0105c1b:	73 07                	jae    f0105c24 <__udivdi3+0xc4>
f0105c1d:	39 d5                	cmp    %edx,%ebp
f0105c1f:	75 03                	jne    f0105c24 <__udivdi3+0xc4>
f0105c21:	83 eb 01             	sub    $0x1,%ebx
f0105c24:	31 ff                	xor    %edi,%edi
f0105c26:	89 d8                	mov    %ebx,%eax
f0105c28:	89 fa                	mov    %edi,%edx
f0105c2a:	83 c4 1c             	add    $0x1c,%esp
f0105c2d:	5b                   	pop    %ebx
f0105c2e:	5e                   	pop    %esi
f0105c2f:	5f                   	pop    %edi
f0105c30:	5d                   	pop    %ebp
f0105c31:	c3                   	ret    
f0105c32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105c38:	31 ff                	xor    %edi,%edi
f0105c3a:	31 db                	xor    %ebx,%ebx
f0105c3c:	89 d8                	mov    %ebx,%eax
f0105c3e:	89 fa                	mov    %edi,%edx
f0105c40:	83 c4 1c             	add    $0x1c,%esp
f0105c43:	5b                   	pop    %ebx
f0105c44:	5e                   	pop    %esi
f0105c45:	5f                   	pop    %edi
f0105c46:	5d                   	pop    %ebp
f0105c47:	c3                   	ret    
f0105c48:	90                   	nop
f0105c49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105c50:	89 d8                	mov    %ebx,%eax
f0105c52:	f7 f7                	div    %edi
f0105c54:	31 ff                	xor    %edi,%edi
f0105c56:	89 c3                	mov    %eax,%ebx
f0105c58:	89 d8                	mov    %ebx,%eax
f0105c5a:	89 fa                	mov    %edi,%edx
f0105c5c:	83 c4 1c             	add    $0x1c,%esp
f0105c5f:	5b                   	pop    %ebx
f0105c60:	5e                   	pop    %esi
f0105c61:	5f                   	pop    %edi
f0105c62:	5d                   	pop    %ebp
f0105c63:	c3                   	ret    
f0105c64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105c68:	39 ce                	cmp    %ecx,%esi
f0105c6a:	72 0c                	jb     f0105c78 <__udivdi3+0x118>
f0105c6c:	31 db                	xor    %ebx,%ebx
f0105c6e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105c72:	0f 87 34 ff ff ff    	ja     f0105bac <__udivdi3+0x4c>
f0105c78:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105c7d:	e9 2a ff ff ff       	jmp    f0105bac <__udivdi3+0x4c>
f0105c82:	66 90                	xchg   %ax,%ax
f0105c84:	66 90                	xchg   %ax,%ax
f0105c86:	66 90                	xchg   %ax,%ax
f0105c88:	66 90                	xchg   %ax,%ax
f0105c8a:	66 90                	xchg   %ax,%ax
f0105c8c:	66 90                	xchg   %ax,%ax
f0105c8e:	66 90                	xchg   %ax,%ax

f0105c90 <__umoddi3>:
f0105c90:	55                   	push   %ebp
f0105c91:	57                   	push   %edi
f0105c92:	56                   	push   %esi
f0105c93:	53                   	push   %ebx
f0105c94:	83 ec 1c             	sub    $0x1c,%esp
f0105c97:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105c9b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105c9f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105ca3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105ca7:	85 d2                	test   %edx,%edx
f0105ca9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105cad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105cb1:	89 f3                	mov    %esi,%ebx
f0105cb3:	89 3c 24             	mov    %edi,(%esp)
f0105cb6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105cba:	75 1c                	jne    f0105cd8 <__umoddi3+0x48>
f0105cbc:	39 f7                	cmp    %esi,%edi
f0105cbe:	76 50                	jbe    f0105d10 <__umoddi3+0x80>
f0105cc0:	89 c8                	mov    %ecx,%eax
f0105cc2:	89 f2                	mov    %esi,%edx
f0105cc4:	f7 f7                	div    %edi
f0105cc6:	89 d0                	mov    %edx,%eax
f0105cc8:	31 d2                	xor    %edx,%edx
f0105cca:	83 c4 1c             	add    $0x1c,%esp
f0105ccd:	5b                   	pop    %ebx
f0105cce:	5e                   	pop    %esi
f0105ccf:	5f                   	pop    %edi
f0105cd0:	5d                   	pop    %ebp
f0105cd1:	c3                   	ret    
f0105cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105cd8:	39 f2                	cmp    %esi,%edx
f0105cda:	89 d0                	mov    %edx,%eax
f0105cdc:	77 52                	ja     f0105d30 <__umoddi3+0xa0>
f0105cde:	0f bd ea             	bsr    %edx,%ebp
f0105ce1:	83 f5 1f             	xor    $0x1f,%ebp
f0105ce4:	75 5a                	jne    f0105d40 <__umoddi3+0xb0>
f0105ce6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105cea:	0f 82 e0 00 00 00    	jb     f0105dd0 <__umoddi3+0x140>
f0105cf0:	39 0c 24             	cmp    %ecx,(%esp)
f0105cf3:	0f 86 d7 00 00 00    	jbe    f0105dd0 <__umoddi3+0x140>
f0105cf9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105cfd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105d01:	83 c4 1c             	add    $0x1c,%esp
f0105d04:	5b                   	pop    %ebx
f0105d05:	5e                   	pop    %esi
f0105d06:	5f                   	pop    %edi
f0105d07:	5d                   	pop    %ebp
f0105d08:	c3                   	ret    
f0105d09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105d10:	85 ff                	test   %edi,%edi
f0105d12:	89 fd                	mov    %edi,%ebp
f0105d14:	75 0b                	jne    f0105d21 <__umoddi3+0x91>
f0105d16:	b8 01 00 00 00       	mov    $0x1,%eax
f0105d1b:	31 d2                	xor    %edx,%edx
f0105d1d:	f7 f7                	div    %edi
f0105d1f:	89 c5                	mov    %eax,%ebp
f0105d21:	89 f0                	mov    %esi,%eax
f0105d23:	31 d2                	xor    %edx,%edx
f0105d25:	f7 f5                	div    %ebp
f0105d27:	89 c8                	mov    %ecx,%eax
f0105d29:	f7 f5                	div    %ebp
f0105d2b:	89 d0                	mov    %edx,%eax
f0105d2d:	eb 99                	jmp    f0105cc8 <__umoddi3+0x38>
f0105d2f:	90                   	nop
f0105d30:	89 c8                	mov    %ecx,%eax
f0105d32:	89 f2                	mov    %esi,%edx
f0105d34:	83 c4 1c             	add    $0x1c,%esp
f0105d37:	5b                   	pop    %ebx
f0105d38:	5e                   	pop    %esi
f0105d39:	5f                   	pop    %edi
f0105d3a:	5d                   	pop    %ebp
f0105d3b:	c3                   	ret    
f0105d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105d40:	8b 34 24             	mov    (%esp),%esi
f0105d43:	bf 20 00 00 00       	mov    $0x20,%edi
f0105d48:	89 e9                	mov    %ebp,%ecx
f0105d4a:	29 ef                	sub    %ebp,%edi
f0105d4c:	d3 e0                	shl    %cl,%eax
f0105d4e:	89 f9                	mov    %edi,%ecx
f0105d50:	89 f2                	mov    %esi,%edx
f0105d52:	d3 ea                	shr    %cl,%edx
f0105d54:	89 e9                	mov    %ebp,%ecx
f0105d56:	09 c2                	or     %eax,%edx
f0105d58:	89 d8                	mov    %ebx,%eax
f0105d5a:	89 14 24             	mov    %edx,(%esp)
f0105d5d:	89 f2                	mov    %esi,%edx
f0105d5f:	d3 e2                	shl    %cl,%edx
f0105d61:	89 f9                	mov    %edi,%ecx
f0105d63:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105d67:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105d6b:	d3 e8                	shr    %cl,%eax
f0105d6d:	89 e9                	mov    %ebp,%ecx
f0105d6f:	89 c6                	mov    %eax,%esi
f0105d71:	d3 e3                	shl    %cl,%ebx
f0105d73:	89 f9                	mov    %edi,%ecx
f0105d75:	89 d0                	mov    %edx,%eax
f0105d77:	d3 e8                	shr    %cl,%eax
f0105d79:	89 e9                	mov    %ebp,%ecx
f0105d7b:	09 d8                	or     %ebx,%eax
f0105d7d:	89 d3                	mov    %edx,%ebx
f0105d7f:	89 f2                	mov    %esi,%edx
f0105d81:	f7 34 24             	divl   (%esp)
f0105d84:	89 d6                	mov    %edx,%esi
f0105d86:	d3 e3                	shl    %cl,%ebx
f0105d88:	f7 64 24 04          	mull   0x4(%esp)
f0105d8c:	39 d6                	cmp    %edx,%esi
f0105d8e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105d92:	89 d1                	mov    %edx,%ecx
f0105d94:	89 c3                	mov    %eax,%ebx
f0105d96:	72 08                	jb     f0105da0 <__umoddi3+0x110>
f0105d98:	75 11                	jne    f0105dab <__umoddi3+0x11b>
f0105d9a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0105d9e:	73 0b                	jae    f0105dab <__umoddi3+0x11b>
f0105da0:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105da4:	1b 14 24             	sbb    (%esp),%edx
f0105da7:	89 d1                	mov    %edx,%ecx
f0105da9:	89 c3                	mov    %eax,%ebx
f0105dab:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105daf:	29 da                	sub    %ebx,%edx
f0105db1:	19 ce                	sbb    %ecx,%esi
f0105db3:	89 f9                	mov    %edi,%ecx
f0105db5:	89 f0                	mov    %esi,%eax
f0105db7:	d3 e0                	shl    %cl,%eax
f0105db9:	89 e9                	mov    %ebp,%ecx
f0105dbb:	d3 ea                	shr    %cl,%edx
f0105dbd:	89 e9                	mov    %ebp,%ecx
f0105dbf:	d3 ee                	shr    %cl,%esi
f0105dc1:	09 d0                	or     %edx,%eax
f0105dc3:	89 f2                	mov    %esi,%edx
f0105dc5:	83 c4 1c             	add    $0x1c,%esp
f0105dc8:	5b                   	pop    %ebx
f0105dc9:	5e                   	pop    %esi
f0105dca:	5f                   	pop    %edi
f0105dcb:	5d                   	pop    %ebp
f0105dcc:	c3                   	ret    
f0105dcd:	8d 76 00             	lea    0x0(%esi),%esi
f0105dd0:	29 f9                	sub    %edi,%ecx
f0105dd2:	19 d6                	sbb    %edx,%esi
f0105dd4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105dd8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105ddc:	e9 18 ff ff ff       	jmp    f0105cf9 <__umoddi3+0x69>
