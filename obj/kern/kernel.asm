
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 2c 17 f0       	mov    $0xf0172c50,%eax
f010004b:	2d 26 1d 17 f0       	sub    $0xf0171d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 1d 17 f0       	push   $0xf0171d26
f0100058:	e8 99 42 00 00       	call   f01042f6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 47 10 f0       	push   $0xf01047a0
f010006f:	e8 a8 2e 00 00       	call   f0102f1c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 85 10 00 00       	call   f01010fe <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 e6 28 00 00       	call   f0102964 <env_init>
	trap_init();
f010007e:	e8 0a 2f 00 00       	call   f0102f8d <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 b3 11 f0       	push   $0xf011b356
f010008d:	e8 80 2a 00 00       	call   f0102b12 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f010009b:	e8 b3 2d 00 00       	call   f0102e53 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 2c 17 f0 00 	cmpl   $0x0,0xf0172c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 2c 17 f0    	mov    %esi,0xf0172c40

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 bb 47 10 f0       	push   $0xf01047bb
f01000ca:	e8 4d 2e 00 00       	call   f0102f1c <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 1d 2e 00 00       	call   f0102ef6 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 dc 4a 10 f0 	movl   $0xf0104adc,(%esp)
f01000e0:	e8 37 2e 00 00       	call   f0102f1c <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 17 07 00 00       	call   f0100809 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 d3 47 10 f0       	push   $0xf01047d3
f010010c:	e8 0b 2e 00 00       	call   f0102f1c <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 d9 2d 00 00       	call   f0102ef6 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 dc 4a 10 f0 	movl   $0xf0104adc,(%esp)
f0100124:	e8 f3 2d 00 00       	call   f0102f1c <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 1f 17 f0    	mov    0xf0171f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 1f 17 f0    	mov    %edx,0xf0171f64
f010016e:	88 81 60 1d 17 f0    	mov    %al,-0xfe8e2a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 1f 17 f0 00 	movl   $0x0,0xf0171f64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 40 1d 17 f0 40 	orl    $0x40,0xf0171d40
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 40 49 10 f0 	movzbl -0xfefb6c0(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 1d 17 f0    	mov    %ecx,0xf0171d40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 40 49 10 f0 	movzbl -0xfefb6c0(%edx),%eax
f0100226:	0b 05 40 1d 17 f0    	or     0xf0171d40,%eax
f010022c:	0f b6 8a 40 48 10 f0 	movzbl -0xfefb7c0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 20 48 10 f0 	mov    -0xfefb7e0(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 ed 47 10 f0       	push   $0xf01047ed
f0100282:	e8 95 2c 00 00       	call   f0102f1c <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 1f 17 f0 	addw   $0x50,0xf0171f68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 1f 17 f0 	mov    %dx,0xf0171f68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 1f 17 f0 	cmpw   $0x7cf,0xf0171f68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c 1f 17 f0       	mov    0xf0171f6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 0d 3f 00 00       	call   f0104343 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 68 1f 17 f0 	subw   $0x50,0xf0171f68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 1f 17 f0    	mov    0xf0171f70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 1f 17 f0 	movzwl 0xf0171f68,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 74 1f 17 f0 00 	cmpb   $0x0,0xf0171f74
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 60 1f 17 f0       	mov    0xf0171f60,%eax
f01004d8:	3b 05 64 1f 17 f0    	cmp    0xf0171f64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 1f 17 f0    	mov    %edx,0xf0171f60
f01004e9:	0f b6 88 60 1d 17 f0 	movzbl -0xfe8e2a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 60 1f 17 f0 00 	movl   $0x0,0xf0171f60
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 70 1f 17 f0 b4 	movl   $0x3b4,0xf0171f70
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 70 1f 17 f0 d4 	movl   $0x3d4,0xf0171f70
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 70 1f 17 f0    	mov    0xf0171f70,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 6c 1f 17 f0    	mov    %esi,0xf0171f6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 74 1f 17 f0 	setne  0xf0171f74
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 f9 47 10 f0       	push   $0xf01047f9
f0100605:	e8 12 29 00 00       	call   f0102f1c <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 40 4a 10 f0       	push   $0xf0104a40
f010064b:	68 5e 4a 10 f0       	push   $0xf0104a5e
f0100650:	68 63 4a 10 f0       	push   $0xf0104a63
f0100655:	e8 c2 28 00 00       	call   f0102f1c <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0100662:	68 6c 4a 10 f0       	push   $0xf0104a6c
f0100667:	68 63 4a 10 f0       	push   $0xf0104a63
f010066c:	e8 ab 28 00 00       	call   f0102f1c <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 44 4b 10 f0       	push   $0xf0104b44
f0100679:	68 75 4a 10 f0       	push   $0xf0104a75
f010067e:	68 63 4a 10 f0       	push   $0xf0104a63
f0100683:	e8 94 28 00 00       	call   f0102f1c <cprintf>
	return 0;
}
f0100688:	b8 00 00 00 00       	mov    $0x0,%eax
f010068d:	c9                   	leave  
f010068e:	c3                   	ret    

f010068f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010068f:	55                   	push   %ebp
f0100690:	89 e5                	mov    %esp,%ebp
f0100692:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100695:	68 7f 4a 10 f0       	push   $0xf0104a7f
f010069a:	e8 7d 28 00 00       	call   f0102f1c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 70 4b 10 f0       	push   $0xf0104b70
f01006ac:	e8 6b 28 00 00       	call   f0102f1c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 98 4b 10 f0       	push   $0xf0104b98
f01006c3:	e8 54 28 00 00       	call   f0102f1c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 81 47 10 00       	push   $0x104781
f01006d0:	68 81 47 10 f0       	push   $0xf0104781
f01006d5:	68 bc 4b 10 f0       	push   $0xf0104bbc
f01006da:	e8 3d 28 00 00       	call   f0102f1c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 1d 17 00       	push   $0x171d26
f01006e7:	68 26 1d 17 f0       	push   $0xf0171d26
f01006ec:	68 e0 4b 10 f0       	push   $0xf0104be0
f01006f1:	e8 26 28 00 00       	call   f0102f1c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 2c 17 00       	push   $0x172c50
f01006fe:	68 50 2c 17 f0       	push   $0xf0172c50
f0100703:	68 04 4c 10 f0       	push   $0xf0104c04
f0100708:	e8 0f 28 00 00       	call   f0102f1c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 4f 30 17 f0       	mov    $0xf017304f,%eax
f0100712:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100717:	83 c4 08             	add    $0x8,%esp
f010071a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010071f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100725:	85 c0                	test   %eax,%eax
f0100727:	0f 48 c2             	cmovs  %edx,%eax
f010072a:	c1 f8 0a             	sar    $0xa,%eax
f010072d:	50                   	push   %eax
f010072e:	68 28 4c 10 f0       	push   $0xf0104c28
f0100733:	e8 e4 27 00 00       	call   f0102f1c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100738:	b8 00 00 00 00       	mov    $0x0,%eax
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	57                   	push   %edi
f0100743:	56                   	push   %esi
f0100744:	53                   	push   %ebx
f0100745:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100748:	89 eb                	mov    %ebp,%ebx
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
f010074a:	68 98 4a 10 f0       	push   $0xf0104a98
f010074f:	e8 c8 27 00 00       	call   f0102f1c <cprintf>
	while(ebp)
f0100754:	83 c4 10             	add    $0x10,%esp
		cprintf("%08x ", *(ebp+3));
		cprintf("%08x ", *(ebp+4));
		cprintf("%08x ", *(ebp+5));
		cprintf("%08x", *(ebp+6));

		if(debuginfo_eip(eip, &info) == 0)
f0100757:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f010075a:	e9 95 00 00 00       	jmp    f01007f4 <mon_backtrace+0xb5>
	{
		eip = *(ebp+1);
f010075f:	8b 73 04             	mov    0x4(%ebx),%esi

		cprintf("ebp %08x  eip %08x  args ", ebp, eip);
f0100762:	83 ec 04             	sub    $0x4,%esp
f0100765:	56                   	push   %esi
f0100766:	53                   	push   %ebx
f0100767:	68 ab 4a 10 f0       	push   $0xf0104aab
f010076c:	e8 ab 27 00 00       	call   f0102f1c <cprintf>
		cprintf("%08x ", *(ebp+2));
f0100771:	83 c4 08             	add    $0x8,%esp
f0100774:	ff 73 08             	pushl  0x8(%ebx)
f0100777:	68 c5 4a 10 f0       	push   $0xf0104ac5
f010077c:	e8 9b 27 00 00       	call   f0102f1c <cprintf>
		cprintf("%08x ", *(ebp+3));
f0100781:	83 c4 08             	add    $0x8,%esp
f0100784:	ff 73 0c             	pushl  0xc(%ebx)
f0100787:	68 c5 4a 10 f0       	push   $0xf0104ac5
f010078c:	e8 8b 27 00 00       	call   f0102f1c <cprintf>
		cprintf("%08x ", *(ebp+4));
f0100791:	83 c4 08             	add    $0x8,%esp
f0100794:	ff 73 10             	pushl  0x10(%ebx)
f0100797:	68 c5 4a 10 f0       	push   $0xf0104ac5
f010079c:	e8 7b 27 00 00       	call   f0102f1c <cprintf>
		cprintf("%08x ", *(ebp+5));
f01007a1:	83 c4 08             	add    $0x8,%esp
f01007a4:	ff 73 14             	pushl  0x14(%ebx)
f01007a7:	68 c5 4a 10 f0       	push   $0xf0104ac5
f01007ac:	e8 6b 27 00 00       	call   f0102f1c <cprintf>
		cprintf("%08x", *(ebp+6));
f01007b1:	83 c4 08             	add    $0x8,%esp
f01007b4:	ff 73 18             	pushl  0x18(%ebx)
f01007b7:	68 91 59 10 f0       	push   $0xf0105991
f01007bc:	e8 5b 27 00 00       	call   f0102f1c <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01007c1:	83 c4 08             	add    $0x8,%esp
f01007c4:	57                   	push   %edi
f01007c5:	56                   	push   %esi
f01007c6:	e8 d2 30 00 00       	call   f010389d <debuginfo_eip>
f01007cb:	83 c4 10             	add    $0x10,%esp
f01007ce:	85 c0                	test   %eax,%eax
f01007d0:	75 20                	jne    f01007f2 <mon_backtrace+0xb3>
		{
			cprintf("\t %s:%d: %.*s+%d\n\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 											      info.eip_fn_name, eip-info.eip_fn_addr);
f01007d2:	83 ec 08             	sub    $0x8,%esp
f01007d5:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01007d8:	56                   	push   %esi
f01007d9:	ff 75 d8             	pushl  -0x28(%ebp)
f01007dc:	ff 75 dc             	pushl  -0x24(%ebp)
f01007df:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007e2:	ff 75 d0             	pushl  -0x30(%ebp)
f01007e5:	68 cb 4a 10 f0       	push   $0xf0104acb
f01007ea:	e8 2d 27 00 00       	call   f0102f1c <cprintf>
f01007ef:	83 c4 20             	add    $0x20,%esp
		}

		ebp = (uint32_t*) *ebp;
f01007f2:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f01007f4:	85 db                	test   %ebx,%ebx
f01007f6:	0f 85 63 ff ff ff    	jne    f010075f <mon_backtrace+0x20>
		}

		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f01007fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100801:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100804:	5b                   	pop    %ebx
f0100805:	5e                   	pop    %esi
f0100806:	5f                   	pop    %edi
f0100807:	5d                   	pop    %ebp
f0100808:	c3                   	ret    

f0100809 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100809:	55                   	push   %ebp
f010080a:	89 e5                	mov    %esp,%ebp
f010080c:	57                   	push   %edi
f010080d:	56                   	push   %esi
f010080e:	53                   	push   %ebx
f010080f:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100812:	68 54 4c 10 f0       	push   $0xf0104c54
f0100817:	e8 00 27 00 00       	call   f0102f1c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081c:	c7 04 24 78 4c 10 f0 	movl   $0xf0104c78,(%esp)
f0100823:	e8 f4 26 00 00       	call   f0102f1c <cprintf>

	if (tf != NULL)
f0100828:	83 c4 10             	add    $0x10,%esp
f010082b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010082f:	74 0e                	je     f010083f <monitor+0x36>
		print_trapframe(tf);
f0100831:	83 ec 0c             	sub    $0xc,%esp
f0100834:	ff 75 08             	pushl  0x8(%ebp)
f0100837:	e8 1a 2b 00 00       	call   f0103356 <print_trapframe>
f010083c:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010083f:	83 ec 0c             	sub    $0xc,%esp
f0100842:	68 de 4a 10 f0       	push   $0xf0104ade
f0100847:	e8 53 38 00 00       	call   f010409f <readline>
f010084c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010084e:	83 c4 10             	add    $0x10,%esp
f0100851:	85 c0                	test   %eax,%eax
f0100853:	74 ea                	je     f010083f <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100855:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010085c:	be 00 00 00 00       	mov    $0x0,%esi
f0100861:	eb 0a                	jmp    f010086d <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100863:	c6 03 00             	movb   $0x0,(%ebx)
f0100866:	89 f7                	mov    %esi,%edi
f0100868:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010086b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010086d:	0f b6 03             	movzbl (%ebx),%eax
f0100870:	84 c0                	test   %al,%al
f0100872:	74 63                	je     f01008d7 <monitor+0xce>
f0100874:	83 ec 08             	sub    $0x8,%esp
f0100877:	0f be c0             	movsbl %al,%eax
f010087a:	50                   	push   %eax
f010087b:	68 e2 4a 10 f0       	push   $0xf0104ae2
f0100880:	e8 34 3a 00 00       	call   f01042b9 <strchr>
f0100885:	83 c4 10             	add    $0x10,%esp
f0100888:	85 c0                	test   %eax,%eax
f010088a:	75 d7                	jne    f0100863 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010088c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010088f:	74 46                	je     f01008d7 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100891:	83 fe 0f             	cmp    $0xf,%esi
f0100894:	75 14                	jne    f01008aa <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100896:	83 ec 08             	sub    $0x8,%esp
f0100899:	6a 10                	push   $0x10
f010089b:	68 e7 4a 10 f0       	push   $0xf0104ae7
f01008a0:	e8 77 26 00 00       	call   f0102f1c <cprintf>
f01008a5:	83 c4 10             	add    $0x10,%esp
f01008a8:	eb 95                	jmp    f010083f <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01008aa:	8d 7e 01             	lea    0x1(%esi),%edi
f01008ad:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008b1:	eb 03                	jmp    f01008b6 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008b3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008b6:	0f b6 03             	movzbl (%ebx),%eax
f01008b9:	84 c0                	test   %al,%al
f01008bb:	74 ae                	je     f010086b <monitor+0x62>
f01008bd:	83 ec 08             	sub    $0x8,%esp
f01008c0:	0f be c0             	movsbl %al,%eax
f01008c3:	50                   	push   %eax
f01008c4:	68 e2 4a 10 f0       	push   $0xf0104ae2
f01008c9:	e8 eb 39 00 00       	call   f01042b9 <strchr>
f01008ce:	83 c4 10             	add    $0x10,%esp
f01008d1:	85 c0                	test   %eax,%eax
f01008d3:	74 de                	je     f01008b3 <monitor+0xaa>
f01008d5:	eb 94                	jmp    f010086b <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008d7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008de:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008df:	85 f6                	test   %esi,%esi
f01008e1:	0f 84 58 ff ff ff    	je     f010083f <monitor+0x36>
f01008e7:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ec:	83 ec 08             	sub    $0x8,%esp
f01008ef:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f2:	ff 34 85 a0 4c 10 f0 	pushl  -0xfefb360(,%eax,4)
f01008f9:	ff 75 a8             	pushl  -0x58(%ebp)
f01008fc:	e8 5a 39 00 00       	call   f010425b <strcmp>
f0100901:	83 c4 10             	add    $0x10,%esp
f0100904:	85 c0                	test   %eax,%eax
f0100906:	75 21                	jne    f0100929 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100908:	83 ec 04             	sub    $0x4,%esp
f010090b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010090e:	ff 75 08             	pushl  0x8(%ebp)
f0100911:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100914:	52                   	push   %edx
f0100915:	56                   	push   %esi
f0100916:	ff 14 85 a8 4c 10 f0 	call   *-0xfefb358(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010091d:	83 c4 10             	add    $0x10,%esp
f0100920:	85 c0                	test   %eax,%eax
f0100922:	78 25                	js     f0100949 <monitor+0x140>
f0100924:	e9 16 ff ff ff       	jmp    f010083f <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100929:	83 c3 01             	add    $0x1,%ebx
f010092c:	83 fb 03             	cmp    $0x3,%ebx
f010092f:	75 bb                	jne    f01008ec <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100931:	83 ec 08             	sub    $0x8,%esp
f0100934:	ff 75 a8             	pushl  -0x58(%ebp)
f0100937:	68 04 4b 10 f0       	push   $0xf0104b04
f010093c:	e8 db 25 00 00       	call   f0102f1c <cprintf>
f0100941:	83 c4 10             	add    $0x10,%esp
f0100944:	e9 f6 fe ff ff       	jmp    f010083f <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100949:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010094c:	5b                   	pop    %ebx
f010094d:	5e                   	pop    %esi
f010094e:	5f                   	pop    %edi
f010094f:	5d                   	pop    %ebp
f0100950:	c3                   	ret    

f0100951 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100951:	55                   	push   %ebp
f0100952:	89 e5                	mov    %esp,%ebp
f0100954:	56                   	push   %esi
f0100955:	53                   	push   %ebx
f0100956:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100958:	83 ec 0c             	sub    $0xc,%esp
f010095b:	50                   	push   %eax
f010095c:	e8 54 25 00 00       	call   f0102eb5 <mc146818_read>
f0100961:	89 c6                	mov    %eax,%esi
f0100963:	83 c3 01             	add    $0x1,%ebx
f0100966:	89 1c 24             	mov    %ebx,(%esp)
f0100969:	e8 47 25 00 00       	call   f0102eb5 <mc146818_read>
f010096e:	c1 e0 08             	shl    $0x8,%eax
f0100971:	09 f0                	or     %esi,%eax
}
f0100973:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100976:	5b                   	pop    %ebx
f0100977:	5e                   	pop    %esi
f0100978:	5d                   	pop    %ebp
f0100979:	c3                   	ret    

f010097a <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010097a:	89 d1                	mov    %edx,%ecx
f010097c:	c1 e9 16             	shr    $0x16,%ecx
f010097f:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100982:	a8 01                	test   $0x1,%al
f0100984:	74 52                	je     f01009d8 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100986:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010098b:	89 c1                	mov    %eax,%ecx
f010098d:	c1 e9 0c             	shr    $0xc,%ecx
f0100990:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f0100996:	72 1b                	jb     f01009b3 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100998:	55                   	push   %ebp
f0100999:	89 e5                	mov    %esp,%ebp
f010099b:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010099e:	50                   	push   %eax
f010099f:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01009a4:	68 55 03 00 00       	push   $0x355
f01009a9:	68 d1 54 10 f0       	push   $0xf01054d1
f01009ae:	e8 ed f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009b3:	c1 ea 0c             	shr    $0xc,%edx
f01009b6:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009bc:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009c3:	89 c2                	mov    %eax,%edx
f01009c5:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009c8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009cd:	85 d2                	test   %edx,%edx
f01009cf:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009d4:	0f 44 c2             	cmove  %edx,%eax
f01009d7:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009dd:	c3                   	ret    

f01009de <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009de:	55                   	push   %ebp
f01009df:	89 e5                	mov    %esp,%ebp
f01009e1:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009e4:	83 3d 78 1f 17 f0 00 	cmpl   $0x0,0xf0171f78
f01009eb:	75 11                	jne    f01009fe <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ed:	ba 4f 3c 17 f0       	mov    $0xf0173c4f,%edx
f01009f2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009f8:	89 15 78 1f 17 f0    	mov    %edx,0xf0171f78
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n < 0) panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) return nextfree;
f01009fe:	85 c0                	test   %eax,%eax
f0100a00:	75 07                	jne    f0100a09 <boot_alloc+0x2b>
f0100a02:	a1 78 1f 17 f0       	mov    0xf0171f78,%eax
f0100a07:	eb 54                	jmp    f0100a5d <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f0100a09:	8b 15 78 1f 17 f0    	mov    0xf0171f78,%edx

		char* new = ROUNDUP(nextfree+n, PGSIZE);
f0100a0f:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100a16:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a1b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100a20:	77 12                	ja     f0100a34 <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a22:	50                   	push   %eax
f0100a23:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0100a28:	6a 74                	push   $0x74
f0100a2a:	68 d1 54 10 f0       	push   $0xf01054d1
f0100a2f:	e8 6c f6 ff ff       	call   f01000a0 <_panic>

		if(PADDR(new) > 1024*1024*4) panic("boot_alloc: not enough memory!\n");
f0100a34:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100a3a:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100a40:	76 14                	jbe    f0100a56 <boot_alloc+0x78>
f0100a42:	83 ec 04             	sub    $0x4,%esp
f0100a45:	68 0c 4d 10 f0       	push   $0xf0104d0c
f0100a4a:	6a 74                	push   $0x74
f0100a4c:	68 d1 54 10 f0       	push   $0xf01054d1
f0100a51:	e8 4a f6 ff ff       	call   f01000a0 <_panic>

		else
		{
			nextfree = new;
f0100a56:	a3 78 1f 17 f0       	mov    %eax,0xf0171f78
		}
	}

	return result;
f0100a5b:	89 d0                	mov    %edx,%eax
}
f0100a5d:	c9                   	leave  
f0100a5e:	c3                   	ret    

f0100a5f <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a5f:	55                   	push   %ebp
f0100a60:	89 e5                	mov    %esp,%ebp
f0100a62:	57                   	push   %edi
f0100a63:	56                   	push   %esi
f0100a64:	53                   	push   %ebx
f0100a65:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a68:	84 c0                	test   %al,%al
f0100a6a:	0f 85 81 02 00 00    	jne    f0100cf1 <check_page_free_list+0x292>
f0100a70:	e9 8e 02 00 00       	jmp    f0100d03 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a75:	83 ec 04             	sub    $0x4,%esp
f0100a78:	68 2c 4d 10 f0       	push   $0xf0104d2c
f0100a7d:	68 91 02 00 00       	push   $0x291
f0100a82:	68 d1 54 10 f0       	push   $0xf01054d1
f0100a87:	e8 14 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a8c:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a8f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a92:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a95:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a98:	89 c2                	mov    %eax,%edx
f0100a9a:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0100aa0:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100aa6:	0f 95 c2             	setne  %dl
f0100aa9:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100aac:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ab0:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ab2:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab6:	8b 00                	mov    (%eax),%eax
f0100ab8:	85 c0                	test   %eax,%eax
f0100aba:	75 dc                	jne    f0100a98 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100abc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100abf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ac5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ac8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100acb:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100acd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ad0:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ad5:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ada:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100ae0:	eb 53                	jmp    f0100b35 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ae2:	89 d8                	mov    %ebx,%eax
f0100ae4:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100aea:	c1 f8 03             	sar    $0x3,%eax
f0100aed:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100af0:	89 c2                	mov    %eax,%edx
f0100af2:	c1 ea 16             	shr    $0x16,%edx
f0100af5:	39 f2                	cmp    %esi,%edx
f0100af7:	73 3a                	jae    f0100b33 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100af9:	89 c2                	mov    %eax,%edx
f0100afb:	c1 ea 0c             	shr    $0xc,%edx
f0100afe:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100b04:	72 12                	jb     f0100b18 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b06:	50                   	push   %eax
f0100b07:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0100b0c:	6a 56                	push   $0x56
f0100b0e:	68 dd 54 10 f0       	push   $0xf01054dd
f0100b13:	e8 88 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b18:	83 ec 04             	sub    $0x4,%esp
f0100b1b:	68 80 00 00 00       	push   $0x80
f0100b20:	68 97 00 00 00       	push   $0x97
f0100b25:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b2a:	50                   	push   %eax
f0100b2b:	e8 c6 37 00 00       	call   f01042f6 <memset>
f0100b30:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b33:	8b 1b                	mov    (%ebx),%ebx
f0100b35:	85 db                	test   %ebx,%ebx
f0100b37:	75 a9                	jne    f0100ae2 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b39:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b3e:	e8 9b fe ff ff       	call   f01009de <boot_alloc>
f0100b43:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b46:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b4c:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
		assert(pp < pages + npages);
f0100b52:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0100b57:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b5a:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b5d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b60:	be 00 00 00 00       	mov    $0x0,%esi
f0100b65:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b68:	e9 30 01 00 00       	jmp    f0100c9d <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b6d:	39 ca                	cmp    %ecx,%edx
f0100b6f:	73 19                	jae    f0100b8a <check_page_free_list+0x12b>
f0100b71:	68 eb 54 10 f0       	push   $0xf01054eb
f0100b76:	68 f7 54 10 f0       	push   $0xf01054f7
f0100b7b:	68 ab 02 00 00       	push   $0x2ab
f0100b80:	68 d1 54 10 f0       	push   $0xf01054d1
f0100b85:	e8 16 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b8a:	39 fa                	cmp    %edi,%edx
f0100b8c:	72 19                	jb     f0100ba7 <check_page_free_list+0x148>
f0100b8e:	68 0c 55 10 f0       	push   $0xf010550c
f0100b93:	68 f7 54 10 f0       	push   $0xf01054f7
f0100b98:	68 ac 02 00 00       	push   $0x2ac
f0100b9d:	68 d1 54 10 f0       	push   $0xf01054d1
f0100ba2:	e8 f9 f4 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ba7:	89 d0                	mov    %edx,%eax
f0100ba9:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100bac:	a8 07                	test   $0x7,%al
f0100bae:	74 19                	je     f0100bc9 <check_page_free_list+0x16a>
f0100bb0:	68 50 4d 10 f0       	push   $0xf0104d50
f0100bb5:	68 f7 54 10 f0       	push   $0xf01054f7
f0100bba:	68 ad 02 00 00       	push   $0x2ad
f0100bbf:	68 d1 54 10 f0       	push   $0xf01054d1
f0100bc4:	e8 d7 f4 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bc9:	c1 f8 03             	sar    $0x3,%eax
f0100bcc:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bcf:	85 c0                	test   %eax,%eax
f0100bd1:	75 19                	jne    f0100bec <check_page_free_list+0x18d>
f0100bd3:	68 20 55 10 f0       	push   $0xf0105520
f0100bd8:	68 f7 54 10 f0       	push   $0xf01054f7
f0100bdd:	68 b0 02 00 00       	push   $0x2b0
f0100be2:	68 d1 54 10 f0       	push   $0xf01054d1
f0100be7:	e8 b4 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bec:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bf1:	75 19                	jne    f0100c0c <check_page_free_list+0x1ad>
f0100bf3:	68 31 55 10 f0       	push   $0xf0105531
f0100bf8:	68 f7 54 10 f0       	push   $0xf01054f7
f0100bfd:	68 b1 02 00 00       	push   $0x2b1
f0100c02:	68 d1 54 10 f0       	push   $0xf01054d1
f0100c07:	e8 94 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c0c:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c11:	75 19                	jne    f0100c2c <check_page_free_list+0x1cd>
f0100c13:	68 84 4d 10 f0       	push   $0xf0104d84
f0100c18:	68 f7 54 10 f0       	push   $0xf01054f7
f0100c1d:	68 b2 02 00 00       	push   $0x2b2
f0100c22:	68 d1 54 10 f0       	push   $0xf01054d1
f0100c27:	e8 74 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c2c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c31:	75 19                	jne    f0100c4c <check_page_free_list+0x1ed>
f0100c33:	68 4a 55 10 f0       	push   $0xf010554a
f0100c38:	68 f7 54 10 f0       	push   $0xf01054f7
f0100c3d:	68 b3 02 00 00       	push   $0x2b3
f0100c42:	68 d1 54 10 f0       	push   $0xf01054d1
f0100c47:	e8 54 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c4c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c51:	76 3f                	jbe    f0100c92 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c53:	89 c3                	mov    %eax,%ebx
f0100c55:	c1 eb 0c             	shr    $0xc,%ebx
f0100c58:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c5b:	77 12                	ja     f0100c6f <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c5d:	50                   	push   %eax
f0100c5e:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0100c63:	6a 56                	push   $0x56
f0100c65:	68 dd 54 10 f0       	push   $0xf01054dd
f0100c6a:	e8 31 f4 ff ff       	call   f01000a0 <_panic>
f0100c6f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c74:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c77:	76 1e                	jbe    f0100c97 <check_page_free_list+0x238>
f0100c79:	68 a8 4d 10 f0       	push   $0xf0104da8
f0100c7e:	68 f7 54 10 f0       	push   $0xf01054f7
f0100c83:	68 b4 02 00 00       	push   $0x2b4
f0100c88:	68 d1 54 10 f0       	push   $0xf01054d1
f0100c8d:	e8 0e f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c92:	83 c6 01             	add    $0x1,%esi
f0100c95:	eb 04                	jmp    f0100c9b <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c97:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c9b:	8b 12                	mov    (%edx),%edx
f0100c9d:	85 d2                	test   %edx,%edx
f0100c9f:	0f 85 c8 fe ff ff    	jne    f0100b6d <check_page_free_list+0x10e>
f0100ca5:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100ca8:	85 f6                	test   %esi,%esi
f0100caa:	7f 19                	jg     f0100cc5 <check_page_free_list+0x266>
f0100cac:	68 64 55 10 f0       	push   $0xf0105564
f0100cb1:	68 f7 54 10 f0       	push   $0xf01054f7
f0100cb6:	68 bc 02 00 00       	push   $0x2bc
f0100cbb:	68 d1 54 10 f0       	push   $0xf01054d1
f0100cc0:	e8 db f3 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100cc5:	85 db                	test   %ebx,%ebx
f0100cc7:	7f 19                	jg     f0100ce2 <check_page_free_list+0x283>
f0100cc9:	68 76 55 10 f0       	push   $0xf0105576
f0100cce:	68 f7 54 10 f0       	push   $0xf01054f7
f0100cd3:	68 bd 02 00 00       	push   $0x2bd
f0100cd8:	68 d1 54 10 f0       	push   $0xf01054d1
f0100cdd:	e8 be f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ce2:	83 ec 0c             	sub    $0xc,%esp
f0100ce5:	68 f0 4d 10 f0       	push   $0xf0104df0
f0100cea:	e8 2d 22 00 00       	call   f0102f1c <cprintf>
}
f0100cef:	eb 29                	jmp    f0100d1a <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cf1:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0100cf6:	85 c0                	test   %eax,%eax
f0100cf8:	0f 85 8e fd ff ff    	jne    f0100a8c <check_page_free_list+0x2d>
f0100cfe:	e9 72 fd ff ff       	jmp    f0100a75 <check_page_free_list+0x16>
f0100d03:	83 3d 80 1f 17 f0 00 	cmpl   $0x0,0xf0171f80
f0100d0a:	0f 84 65 fd ff ff    	je     f0100a75 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d10:	be 00 04 00 00       	mov    $0x400,%esi
f0100d15:	e9 c0 fd ff ff       	jmp    f0100ada <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100d1a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d1d:	5b                   	pop    %ebx
f0100d1e:	5e                   	pop    %esi
f0100d1f:	5f                   	pop    %edi
f0100d20:	5d                   	pop    %ebp
f0100d21:	c3                   	ret    

f0100d22 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d22:	55                   	push   %ebp
f0100d23:	89 e5                	mov    %esp,%ebp
f0100d25:	57                   	push   %edi
f0100d26:	56                   	push   %esi
f0100d27:	53                   	push   %ebx
f0100d28:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
f0100d2b:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d30:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages; i++) 
f0100d36:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100d3b:	be 08 00 00 00       	mov    $0x8,%esi
f0100d40:	bf 01 00 00 00       	mov    $0x1,%edi
f0100d45:	e9 8f 00 00 00       	jmp    f0100dd9 <page_init+0xb7>
	{
		if((i*PGSIZE  >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM))
f0100d4a:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100d50:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100d55:	77 0e                	ja     f0100d65 <page_init+0x43>
		{
			pages[i].pp_ref = 1;
f0100d57:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d5c:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;	
f0100d63:	eb 68                	jmp    f0100dcd <page_init+0xab>
		}

		if((i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))))
f0100d65:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100d6b:	76 3d                	jbe    f0100daa <page_init+0x88>
f0100d6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d72:	e8 67 fc ff ff       	call   f01009de <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d77:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d7c:	77 15                	ja     f0100d93 <page_init+0x71>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d7e:	50                   	push   %eax
f0100d7f:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0100d84:	68 2c 01 00 00       	push   $0x12c
f0100d89:	68 d1 54 10 f0       	push   $0xf01054d1
f0100d8e:	e8 0d f3 ff ff       	call   f01000a0 <_panic>
f0100d93:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d98:	39 d8                	cmp    %ebx,%eax
f0100d9a:	76 0e                	jbe    f0100daa <page_init+0x88>
		{
			pages[i].pp_ref = 1;
f0100d9c:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100da1:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100da8:	eb 23                	jmp    f0100dcd <page_init+0xab>
		}
			
		pages[i].pp_ref = 0;  
f0100daa:	89 f0                	mov    %esi,%eax
f0100dac:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100db2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100db8:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100dbe:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100dc0:	89 f0                	mov    %esi,%eax
f0100dc2:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100dc8:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages; i++) 
f0100dcd:	83 c7 01             	add    $0x1,%edi
f0100dd0:	83 c6 08             	add    $0x8,%esi
f0100dd3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100dd9:	3b 3d 44 2c 17 f0    	cmp    0xf0172c44,%edi
f0100ddf:	0f 82 65 ff ff ff    	jb     f0100d4a <page_init+0x28>
			
		pages[i].pp_ref = 0;  
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100de5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100de8:	5b                   	pop    %ebx
f0100de9:	5e                   	pop    %esi
f0100dea:	5f                   	pop    %edi
f0100deb:	5d                   	pop    %ebp
f0100dec:	c3                   	ret    

f0100ded <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ded:	55                   	push   %ebp
f0100dee:	89 e5                	mov    %esp,%ebp
f0100df0:	53                   	push   %ebx
f0100df1:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL) return NULL;
f0100df4:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100dfa:	85 db                	test   %ebx,%ebx
f0100dfc:	74 58                	je     f0100e56 <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100dfe:	8b 03                	mov    (%ebx),%eax
f0100e00:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	page->pp_link = NULL;
f0100e05:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100e0b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e0f:	74 45                	je     f0100e56 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e11:	89 d8                	mov    %ebx,%eax
f0100e13:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100e19:	c1 f8 03             	sar    $0x3,%eax
f0100e1c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e1f:	89 c2                	mov    %eax,%edx
f0100e21:	c1 ea 0c             	shr    $0xc,%edx
f0100e24:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100e2a:	72 12                	jb     f0100e3e <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e2c:	50                   	push   %eax
f0100e2d:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0100e32:	6a 56                	push   $0x56
f0100e34:	68 dd 54 10 f0       	push   $0xf01054dd
f0100e39:	e8 62 f2 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0100e3e:	83 ec 04             	sub    $0x4,%esp
f0100e41:	68 00 10 00 00       	push   $0x1000
f0100e46:	6a 00                	push   $0x0
f0100e48:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e4d:	50                   	push   %eax
f0100e4e:	e8 a3 34 00 00       	call   f01042f6 <memset>
f0100e53:	83 c4 10             	add    $0x10,%esp
	}

	return page;
}
f0100e56:	89 d8                	mov    %ebx,%eax
f0100e58:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e5b:	c9                   	leave  
f0100e5c:	c3                   	ret    

f0100e5d <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e5d:	55                   	push   %ebp
f0100e5e:	89 e5                	mov    %esp,%ebp
f0100e60:	83 ec 08             	sub    $0x8,%esp
f0100e63:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref > 0) || (pp->pp_link != NULL)) panic("page_free: cannot free the page which is still in use!\n");
f0100e66:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e6b:	75 05                	jne    f0100e72 <page_free+0x15>
f0100e6d:	83 38 00             	cmpl   $0x0,(%eax)
f0100e70:	74 17                	je     f0100e89 <page_free+0x2c>
f0100e72:	83 ec 04             	sub    $0x4,%esp
f0100e75:	68 14 4e 10 f0       	push   $0xf0104e14
f0100e7a:	68 63 01 00 00       	push   $0x163
f0100e7f:	68 d1 54 10 f0       	push   $0xf01054d1
f0100e84:	e8 17 f2 ff ff       	call   f01000a0 <_panic>
	
	pp->pp_link  = page_free_list;
f0100e89:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100e8f:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;
f0100e91:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
	
}
f0100e96:	c9                   	leave  
f0100e97:	c3                   	ret    

f0100e98 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	83 ec 08             	sub    $0x8,%esp
f0100e9e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100ea1:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100ea5:	83 e8 01             	sub    $0x1,%eax
f0100ea8:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100eac:	66 85 c0             	test   %ax,%ax
f0100eaf:	75 0c                	jne    f0100ebd <page_decref+0x25>
		page_free(pp);
f0100eb1:	83 ec 0c             	sub    $0xc,%esp
f0100eb4:	52                   	push   %edx
f0100eb5:	e8 a3 ff ff ff       	call   f0100e5d <page_free>
f0100eba:	83 c4 10             	add    $0x10,%esp
}
f0100ebd:	c9                   	leave  
f0100ebe:	c3                   	ret    

f0100ebf <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ebf:	55                   	push   %ebp
f0100ec0:	89 e5                	mov    %esp,%ebp
f0100ec2:	56                   	push   %esi
f0100ec3:	53                   	push   %ebx
f0100ec4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	size_t dirIndex = PDX(va);
	size_t tableIndex = PTX(va);
f0100ec7:	89 de                	mov    %ebx,%esi
f0100ec9:	c1 ee 0c             	shr    $0xc,%esi
f0100ecc:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];
f0100ed2:	c1 eb 16             	shr    $0x16,%ebx
f0100ed5:	c1 e3 02             	shl    $0x2,%ebx
f0100ed8:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pdir_entry & PTE_P))
f0100edb:	8b 03                	mov    (%ebx),%eax
f0100edd:	a8 01                	test   $0x1,%al
f0100edf:	75 6c                	jne    f0100f4d <pgdir_walk+0x8e>
	{
		if(create == false) return NULL;
f0100ee1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ee5:	0f 84 93 00 00 00    	je     f0100f7e <pgdir_walk+0xbf>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100eeb:	83 ec 0c             	sub    $0xc,%esp
f0100eee:	6a 01                	push   $0x1
f0100ef0:	e8 f8 fe ff ff       	call   f0100ded <page_alloc>

		if(page == NULL) return NULL;
f0100ef5:	83 c4 10             	add    $0x10,%esp
f0100ef8:	85 c0                	test   %eax,%eax
f0100efa:	0f 84 85 00 00 00    	je     f0100f85 <pgdir_walk+0xc6>

		page->pp_ref++;
f0100f00:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

		*pdir_entry = page2pa(page) | PTE_P | PTE_W | PTE_U;
f0100f05:	89 c2                	mov    %eax,%edx
f0100f07:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0100f0d:	c1 fa 03             	sar    $0x3,%edx
f0100f10:	c1 e2 0c             	shl    $0xc,%edx
f0100f13:	83 ca 07             	or     $0x7,%edx
f0100f16:	89 13                	mov    %edx,(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f18:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100f1e:	c1 f8 03             	sar    $0x3,%eax
f0100f21:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f24:	89 c2                	mov    %eax,%edx
f0100f26:	c1 ea 0c             	shr    $0xc,%edx
f0100f29:	39 15 44 2c 17 f0    	cmp    %edx,0xf0172c44
f0100f2f:	77 15                	ja     f0100f46 <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f31:	50                   	push   %eax
f0100f32:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0100f37:	68 a3 01 00 00       	push   $0x1a3
f0100f3c:	68 d1 54 10 f0       	push   $0xf01054d1
f0100f41:	e8 5a f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100f46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f4b:	eb 2c                	jmp    f0100f79 <pgdir_walk+0xba>
		
		ptable_entry = (pte_t*) KADDR(page2pa(page));
	}
	else
	{
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
f0100f4d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f52:	89 c2                	mov    %eax,%edx
f0100f54:	c1 ea 0c             	shr    $0xc,%edx
f0100f57:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100f5d:	72 15                	jb     f0100f74 <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f5f:	50                   	push   %eax
f0100f60:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0100f65:	68 a7 01 00 00       	push   $0x1a7
f0100f6a:	68 d1 54 10 f0       	push   $0xf01054d1
f0100f6f:	e8 2c f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100f74:	2d 00 00 00 10       	sub    $0x10000000,%eax
	}
	
	return ptable_entry + tableIndex;
f0100f79:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0100f7c:	eb 0c                	jmp    f0100f8a <pgdir_walk+0xcb>
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];

	if(!(*pdir_entry & PTE_P))
	{
		if(create == false) return NULL;
f0100f7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f83:	eb 05                	jmp    f0100f8a <pgdir_walk+0xcb>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);

		if(page == NULL) return NULL;
f0100f85:	b8 00 00 00 00       	mov    $0x0,%eax
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
	}
	
	return ptable_entry + tableIndex;
	
}
f0100f8a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f8d:	5b                   	pop    %ebx
f0100f8e:	5e                   	pop    %esi
f0100f8f:	5d                   	pop    %ebp
f0100f90:	c3                   	ret    

f0100f91 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f91:	55                   	push   %ebp
f0100f92:	89 e5                	mov    %esp,%ebp
f0100f94:	57                   	push   %edi
f0100f95:	56                   	push   %esi
f0100f96:	53                   	push   %ebx
f0100f97:	83 ec 1c             	sub    $0x1c,%esp
f0100f9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f9d:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100fa0:	c1 e9 0c             	shr    $0xc,%ecx
f0100fa3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100fa6:	89 c3                	mov    %eax,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;
f0100fa8:	be 00 00 00 00       	mov    $0x0,%esi

	for(i; i < size/PGSIZE; ++i)
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0100fad:	89 d7                	mov    %edx,%edi
f0100faf:	29 c7                	sub    %eax,%edi

		if(ptable_entry == NULL) return;
		
		*ptable_entry = pa | perm | PTE_P;
f0100fb1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb4:	83 c8 01             	or     $0x1,%eax
f0100fb7:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100fba:	eb 28                	jmp    f0100fe4 <boot_map_region+0x53>
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0100fbc:	83 ec 04             	sub    $0x4,%esp
f0100fbf:	6a 01                	push   $0x1
f0100fc1:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100fc4:	50                   	push   %eax
f0100fc5:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fc8:	e8 f2 fe ff ff       	call   f0100ebf <pgdir_walk>

		if(ptable_entry == NULL) return;
f0100fcd:	83 c4 10             	add    $0x10,%esp
f0100fd0:	85 c0                	test   %eax,%eax
f0100fd2:	74 15                	je     f0100fe9 <boot_map_region+0x58>
		
		*ptable_entry = pa | perm | PTE_P;
f0100fd4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fd7:	09 da                	or     %ebx,%edx
f0100fd9:	89 10                	mov    %edx,(%eax)

		pa += PGSIZE;
f0100fdb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100fe1:	83 c6 01             	add    $0x1,%esi
f0100fe4:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fe7:	75 d3                	jne    f0100fbc <boot_map_region+0x2b>

		pa += PGSIZE;
		va += PGSIZE;
	}
		
}
f0100fe9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fec:	5b                   	pop    %ebx
f0100fed:	5e                   	pop    %esi
f0100fee:	5f                   	pop    %edi
f0100fef:	5d                   	pop    %ebp
f0100ff0:	c3                   	ret    

f0100ff1 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ff1:	55                   	push   %ebp
f0100ff2:	89 e5                	mov    %esp,%ebp
f0100ff4:	53                   	push   %ebx
f0100ff5:	83 ec 08             	sub    $0x8,%esp
f0100ff8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
f0100ffb:	6a 00                	push   $0x0
f0100ffd:	ff 75 0c             	pushl  0xc(%ebp)
f0101000:	ff 75 08             	pushl  0x8(%ebp)
f0101003:	e8 b7 fe ff ff       	call   f0100ebf <pgdir_walk>
	
	if(!ptEntry) return NULL;
f0101008:	83 c4 10             	add    $0x10,%esp
f010100b:	85 c0                	test   %eax,%eax
f010100d:	74 32                	je     f0101041 <page_lookup+0x50>

	if(pte_store)
f010100f:	85 db                	test   %ebx,%ebx
f0101011:	74 02                	je     f0101015 <page_lookup+0x24>
	{
		*pte_store = ptEntry;
f0101013:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101015:	8b 00                	mov    (%eax),%eax
f0101017:	c1 e8 0c             	shr    $0xc,%eax
f010101a:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0101020:	72 14                	jb     f0101036 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101022:	83 ec 04             	sub    $0x4,%esp
f0101025:	68 4c 4e 10 f0       	push   $0xf0104e4c
f010102a:	6a 4f                	push   $0x4f
f010102c:	68 dd 54 10 f0       	push   $0xf01054dd
f0101031:	e8 6a f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0101036:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f010103c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
f010103f:	eb 05                	jmp    f0101046 <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
	
	if(!ptEntry) return NULL;
f0101041:	b8 00 00 00 00       	mov    $0x0,%eax
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;

}
f0101046:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101049:	c9                   	leave  
f010104a:	c3                   	ret    

f010104b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010104b:	55                   	push   %ebp
f010104c:	89 e5                	mov    %esp,%ebp
f010104e:	53                   	push   %ebx
f010104f:	83 ec 18             	sub    $0x18,%esp
f0101052:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = NULL;
f0101055:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &ptEntry);
f010105c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010105f:	50                   	push   %eax
f0101060:	53                   	push   %ebx
f0101061:	ff 75 08             	pushl  0x8(%ebp)
f0101064:	e8 88 ff ff ff       	call   f0100ff1 <page_lookup>

	if(!page || !(*ptEntry & PTE_P)) return;
f0101069:	83 c4 10             	add    $0x10,%esp
f010106c:	85 c0                	test   %eax,%eax
f010106e:	74 20                	je     f0101090 <page_remove+0x45>
f0101070:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101073:	f6 02 01             	testb  $0x1,(%edx)
f0101076:	74 18                	je     f0101090 <page_remove+0x45>

	page_decref(page);
f0101078:	83 ec 0c             	sub    $0xc,%esp
f010107b:	50                   	push   %eax
f010107c:	e8 17 fe ff ff       	call   f0100e98 <page_decref>

	*ptEntry = 0;
f0101081:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101084:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010108a:	0f 01 3b             	invlpg (%ebx)
f010108d:	83 c4 10             	add    $0x10,%esp

	tlb_invalidate(pgdir, va);
}
f0101090:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101093:	c9                   	leave  
f0101094:	c3                   	ret    

f0101095 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101095:	55                   	push   %ebp
f0101096:	89 e5                	mov    %esp,%ebp
f0101098:	57                   	push   %edi
f0101099:	56                   	push   %esi
f010109a:	53                   	push   %ebx
f010109b:	83 ec 10             	sub    $0x10,%esp
f010109e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010a1:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
f01010a4:	6a 01                	push   $0x1
f01010a6:	56                   	push   %esi
f01010a7:	ff 75 08             	pushl  0x8(%ebp)
f01010aa:	e8 10 fe ff ff       	call   f0100ebf <pgdir_walk>
	
	if(!ptEntry) return -E_NO_MEM;
f01010af:	83 c4 10             	add    $0x10,%esp
f01010b2:	85 c0                	test   %eax,%eax
f01010b4:	74 3b                	je     f01010f1 <page_insert+0x5c>
f01010b6:	89 c7                	mov    %eax,%edi
	
	pp->pp_ref++;
f01010b8:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*ptEntry & PTE_P)
f01010bd:	f6 00 01             	testb  $0x1,(%eax)
f01010c0:	74 12                	je     f01010d4 <page_insert+0x3f>
	{
		page_remove(pgdir, va);
f01010c2:	83 ec 08             	sub    $0x8,%esp
f01010c5:	56                   	push   %esi
f01010c6:	ff 75 08             	pushl  0x8(%ebp)
f01010c9:	e8 7d ff ff ff       	call   f010104b <page_remove>
f01010ce:	0f 01 3e             	invlpg (%esi)
f01010d1:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;
f01010d4:	2b 1d 4c 2c 17 f0    	sub    0xf0172c4c,%ebx
f01010da:	c1 fb 03             	sar    $0x3,%ebx
f01010dd:	c1 e3 0c             	shl    $0xc,%ebx
f01010e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e3:	83 c8 01             	or     $0x1,%eax
f01010e6:	09 c3                	or     %eax,%ebx
f01010e8:	89 1f                	mov    %ebx,(%edi)

	return 0;
f01010ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ef:	eb 05                	jmp    f01010f6 <page_insert+0x61>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
	
	if(!ptEntry) return -E_NO_MEM;
f01010f1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;

	return 0;
}
f01010f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010f9:	5b                   	pop    %ebx
f01010fa:	5e                   	pop    %esi
f01010fb:	5f                   	pop    %edi
f01010fc:	5d                   	pop    %ebp
f01010fd:	c3                   	ret    

f01010fe <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010fe:	55                   	push   %ebp
f01010ff:	89 e5                	mov    %esp,%ebp
f0101101:	57                   	push   %edi
f0101102:	56                   	push   %esi
f0101103:	53                   	push   %ebx
f0101104:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101107:	b8 15 00 00 00       	mov    $0x15,%eax
f010110c:	e8 40 f8 ff ff       	call   f0100951 <nvram_read>
f0101111:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101113:	b8 17 00 00 00       	mov    $0x17,%eax
f0101118:	e8 34 f8 ff ff       	call   f0100951 <nvram_read>
f010111d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010111f:	b8 34 00 00 00       	mov    $0x34,%eax
f0101124:	e8 28 f8 ff ff       	call   f0100951 <nvram_read>
f0101129:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010112c:	85 c0                	test   %eax,%eax
f010112e:	74 07                	je     f0101137 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101130:	05 00 40 00 00       	add    $0x4000,%eax
f0101135:	eb 0b                	jmp    f0101142 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101137:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010113d:	85 f6                	test   %esi,%esi
f010113f:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101142:	89 c2                	mov    %eax,%edx
f0101144:	c1 ea 02             	shr    $0x2,%edx
f0101147:	89 15 44 2c 17 f0    	mov    %edx,0xf0172c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010114d:	89 c2                	mov    %eax,%edx
f010114f:	29 da                	sub    %ebx,%edx
f0101151:	52                   	push   %edx
f0101152:	53                   	push   %ebx
f0101153:	50                   	push   %eax
f0101154:	68 6c 4e 10 f0       	push   $0xf0104e6c
f0101159:	e8 be 1d 00 00       	call   f0102f1c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010115e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101163:	e8 76 f8 ff ff       	call   f01009de <boot_alloc>
f0101168:	a3 48 2c 17 f0       	mov    %eax,0xf0172c48
	memset(kern_pgdir, 0, PGSIZE);
f010116d:	83 c4 0c             	add    $0xc,%esp
f0101170:	68 00 10 00 00       	push   $0x1000
f0101175:	6a 00                	push   $0x0
f0101177:	50                   	push   %eax
f0101178:	e8 79 31 00 00       	call   f01042f6 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010117d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101182:	83 c4 10             	add    $0x10,%esp
f0101185:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010118a:	77 15                	ja     f01011a1 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010118c:	50                   	push   %eax
f010118d:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0101192:	68 a0 00 00 00       	push   $0xa0
f0101197:	68 d1 54 10 f0       	push   $0xf01054d1
f010119c:	e8 ff ee ff ff       	call   f01000a0 <_panic>
f01011a1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011a7:	83 ca 05             	or     $0x5,%edx
f01011aa:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof(struct PageInfo)*npages);
f01011b0:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f01011b5:	c1 e0 03             	shl    $0x3,%eax
f01011b8:	e8 21 f8 ff ff       	call   f01009de <boot_alloc>
f01011bd:	a3 4c 2c 17 f0       	mov    %eax,0xf0172c4c
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f01011c2:	83 ec 04             	sub    $0x4,%esp
f01011c5:	8b 3d 44 2c 17 f0    	mov    0xf0172c44,%edi
f01011cb:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01011d2:	52                   	push   %edx
f01011d3:	6a 00                	push   $0x0
f01011d5:	50                   	push   %eax
f01011d6:	e8 1b 31 00 00       	call   f01042f6 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f01011db:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011e0:	e8 f9 f7 ff ff       	call   f01009de <boot_alloc>
f01011e5:	a3 88 1f 17 f0       	mov    %eax,0xf0171f88
	memset(envs, 0, sizeof(struct Env) * NENV);
f01011ea:	83 c4 0c             	add    $0xc,%esp
f01011ed:	68 00 80 01 00       	push   $0x18000
f01011f2:	6a 00                	push   $0x0
f01011f4:	50                   	push   %eax
f01011f5:	e8 fc 30 00 00       	call   f01042f6 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011fa:	e8 23 fb ff ff       	call   f0100d22 <page_init>

	check_page_free_list(1);
f01011ff:	b8 01 00 00 00       	mov    $0x1,%eax
f0101204:	e8 56 f8 ff ff       	call   f0100a5f <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101209:	83 c4 10             	add    $0x10,%esp
f010120c:	83 3d 4c 2c 17 f0 00 	cmpl   $0x0,0xf0172c4c
f0101213:	75 17                	jne    f010122c <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f0101215:	83 ec 04             	sub    $0x4,%esp
f0101218:	68 87 55 10 f0       	push   $0xf0105587
f010121d:	68 d0 02 00 00       	push   $0x2d0
f0101222:	68 d1 54 10 f0       	push   $0xf01054d1
f0101227:	e8 74 ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010122c:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101231:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101236:	eb 05                	jmp    f010123d <mem_init+0x13f>
		++nfree;
f0101238:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010123b:	8b 00                	mov    (%eax),%eax
f010123d:	85 c0                	test   %eax,%eax
f010123f:	75 f7                	jne    f0101238 <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101241:	83 ec 0c             	sub    $0xc,%esp
f0101244:	6a 00                	push   $0x0
f0101246:	e8 a2 fb ff ff       	call   f0100ded <page_alloc>
f010124b:	89 c7                	mov    %eax,%edi
f010124d:	83 c4 10             	add    $0x10,%esp
f0101250:	85 c0                	test   %eax,%eax
f0101252:	75 19                	jne    f010126d <mem_init+0x16f>
f0101254:	68 a2 55 10 f0       	push   $0xf01055a2
f0101259:	68 f7 54 10 f0       	push   $0xf01054f7
f010125e:	68 d8 02 00 00       	push   $0x2d8
f0101263:	68 d1 54 10 f0       	push   $0xf01054d1
f0101268:	e8 33 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010126d:	83 ec 0c             	sub    $0xc,%esp
f0101270:	6a 00                	push   $0x0
f0101272:	e8 76 fb ff ff       	call   f0100ded <page_alloc>
f0101277:	89 c6                	mov    %eax,%esi
f0101279:	83 c4 10             	add    $0x10,%esp
f010127c:	85 c0                	test   %eax,%eax
f010127e:	75 19                	jne    f0101299 <mem_init+0x19b>
f0101280:	68 b8 55 10 f0       	push   $0xf01055b8
f0101285:	68 f7 54 10 f0       	push   $0xf01054f7
f010128a:	68 d9 02 00 00       	push   $0x2d9
f010128f:	68 d1 54 10 f0       	push   $0xf01054d1
f0101294:	e8 07 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101299:	83 ec 0c             	sub    $0xc,%esp
f010129c:	6a 00                	push   $0x0
f010129e:	e8 4a fb ff ff       	call   f0100ded <page_alloc>
f01012a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012a6:	83 c4 10             	add    $0x10,%esp
f01012a9:	85 c0                	test   %eax,%eax
f01012ab:	75 19                	jne    f01012c6 <mem_init+0x1c8>
f01012ad:	68 ce 55 10 f0       	push   $0xf01055ce
f01012b2:	68 f7 54 10 f0       	push   $0xf01054f7
f01012b7:	68 da 02 00 00       	push   $0x2da
f01012bc:	68 d1 54 10 f0       	push   $0xf01054d1
f01012c1:	e8 da ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012c6:	39 f7                	cmp    %esi,%edi
f01012c8:	75 19                	jne    f01012e3 <mem_init+0x1e5>
f01012ca:	68 e4 55 10 f0       	push   $0xf01055e4
f01012cf:	68 f7 54 10 f0       	push   $0xf01054f7
f01012d4:	68 dd 02 00 00       	push   $0x2dd
f01012d9:	68 d1 54 10 f0       	push   $0xf01054d1
f01012de:	e8 bd ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012e6:	39 c6                	cmp    %eax,%esi
f01012e8:	74 04                	je     f01012ee <mem_init+0x1f0>
f01012ea:	39 c7                	cmp    %eax,%edi
f01012ec:	75 19                	jne    f0101307 <mem_init+0x209>
f01012ee:	68 a8 4e 10 f0       	push   $0xf0104ea8
f01012f3:	68 f7 54 10 f0       	push   $0xf01054f7
f01012f8:	68 de 02 00 00       	push   $0x2de
f01012fd:	68 d1 54 10 f0       	push   $0xf01054d1
f0101302:	e8 99 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101307:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010130d:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f0101313:	c1 e2 0c             	shl    $0xc,%edx
f0101316:	89 f8                	mov    %edi,%eax
f0101318:	29 c8                	sub    %ecx,%eax
f010131a:	c1 f8 03             	sar    $0x3,%eax
f010131d:	c1 e0 0c             	shl    $0xc,%eax
f0101320:	39 d0                	cmp    %edx,%eax
f0101322:	72 19                	jb     f010133d <mem_init+0x23f>
f0101324:	68 f6 55 10 f0       	push   $0xf01055f6
f0101329:	68 f7 54 10 f0       	push   $0xf01054f7
f010132e:	68 df 02 00 00       	push   $0x2df
f0101333:	68 d1 54 10 f0       	push   $0xf01054d1
f0101338:	e8 63 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010133d:	89 f0                	mov    %esi,%eax
f010133f:	29 c8                	sub    %ecx,%eax
f0101341:	c1 f8 03             	sar    $0x3,%eax
f0101344:	c1 e0 0c             	shl    $0xc,%eax
f0101347:	39 c2                	cmp    %eax,%edx
f0101349:	77 19                	ja     f0101364 <mem_init+0x266>
f010134b:	68 13 56 10 f0       	push   $0xf0105613
f0101350:	68 f7 54 10 f0       	push   $0xf01054f7
f0101355:	68 e0 02 00 00       	push   $0x2e0
f010135a:	68 d1 54 10 f0       	push   $0xf01054d1
f010135f:	e8 3c ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101364:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101367:	29 c8                	sub    %ecx,%eax
f0101369:	c1 f8 03             	sar    $0x3,%eax
f010136c:	c1 e0 0c             	shl    $0xc,%eax
f010136f:	39 c2                	cmp    %eax,%edx
f0101371:	77 19                	ja     f010138c <mem_init+0x28e>
f0101373:	68 30 56 10 f0       	push   $0xf0105630
f0101378:	68 f7 54 10 f0       	push   $0xf01054f7
f010137d:	68 e1 02 00 00       	push   $0x2e1
f0101382:	68 d1 54 10 f0       	push   $0xf01054d1
f0101387:	e8 14 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010138c:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101391:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101394:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f010139b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010139e:	83 ec 0c             	sub    $0xc,%esp
f01013a1:	6a 00                	push   $0x0
f01013a3:	e8 45 fa ff ff       	call   f0100ded <page_alloc>
f01013a8:	83 c4 10             	add    $0x10,%esp
f01013ab:	85 c0                	test   %eax,%eax
f01013ad:	74 19                	je     f01013c8 <mem_init+0x2ca>
f01013af:	68 4d 56 10 f0       	push   $0xf010564d
f01013b4:	68 f7 54 10 f0       	push   $0xf01054f7
f01013b9:	68 e8 02 00 00       	push   $0x2e8
f01013be:	68 d1 54 10 f0       	push   $0xf01054d1
f01013c3:	e8 d8 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013c8:	83 ec 0c             	sub    $0xc,%esp
f01013cb:	57                   	push   %edi
f01013cc:	e8 8c fa ff ff       	call   f0100e5d <page_free>
	page_free(pp1);
f01013d1:	89 34 24             	mov    %esi,(%esp)
f01013d4:	e8 84 fa ff ff       	call   f0100e5d <page_free>
	page_free(pp2);
f01013d9:	83 c4 04             	add    $0x4,%esp
f01013dc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013df:	e8 79 fa ff ff       	call   f0100e5d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013e4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013eb:	e8 fd f9 ff ff       	call   f0100ded <page_alloc>
f01013f0:	89 c6                	mov    %eax,%esi
f01013f2:	83 c4 10             	add    $0x10,%esp
f01013f5:	85 c0                	test   %eax,%eax
f01013f7:	75 19                	jne    f0101412 <mem_init+0x314>
f01013f9:	68 a2 55 10 f0       	push   $0xf01055a2
f01013fe:	68 f7 54 10 f0       	push   $0xf01054f7
f0101403:	68 ef 02 00 00       	push   $0x2ef
f0101408:	68 d1 54 10 f0       	push   $0xf01054d1
f010140d:	e8 8e ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101412:	83 ec 0c             	sub    $0xc,%esp
f0101415:	6a 00                	push   $0x0
f0101417:	e8 d1 f9 ff ff       	call   f0100ded <page_alloc>
f010141c:	89 c7                	mov    %eax,%edi
f010141e:	83 c4 10             	add    $0x10,%esp
f0101421:	85 c0                	test   %eax,%eax
f0101423:	75 19                	jne    f010143e <mem_init+0x340>
f0101425:	68 b8 55 10 f0       	push   $0xf01055b8
f010142a:	68 f7 54 10 f0       	push   $0xf01054f7
f010142f:	68 f0 02 00 00       	push   $0x2f0
f0101434:	68 d1 54 10 f0       	push   $0xf01054d1
f0101439:	e8 62 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010143e:	83 ec 0c             	sub    $0xc,%esp
f0101441:	6a 00                	push   $0x0
f0101443:	e8 a5 f9 ff ff       	call   f0100ded <page_alloc>
f0101448:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	85 c0                	test   %eax,%eax
f0101450:	75 19                	jne    f010146b <mem_init+0x36d>
f0101452:	68 ce 55 10 f0       	push   $0xf01055ce
f0101457:	68 f7 54 10 f0       	push   $0xf01054f7
f010145c:	68 f1 02 00 00       	push   $0x2f1
f0101461:	68 d1 54 10 f0       	push   $0xf01054d1
f0101466:	e8 35 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010146b:	39 fe                	cmp    %edi,%esi
f010146d:	75 19                	jne    f0101488 <mem_init+0x38a>
f010146f:	68 e4 55 10 f0       	push   $0xf01055e4
f0101474:	68 f7 54 10 f0       	push   $0xf01054f7
f0101479:	68 f3 02 00 00       	push   $0x2f3
f010147e:	68 d1 54 10 f0       	push   $0xf01054d1
f0101483:	e8 18 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101488:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010148b:	39 c7                	cmp    %eax,%edi
f010148d:	74 04                	je     f0101493 <mem_init+0x395>
f010148f:	39 c6                	cmp    %eax,%esi
f0101491:	75 19                	jne    f01014ac <mem_init+0x3ae>
f0101493:	68 a8 4e 10 f0       	push   $0xf0104ea8
f0101498:	68 f7 54 10 f0       	push   $0xf01054f7
f010149d:	68 f4 02 00 00       	push   $0x2f4
f01014a2:	68 d1 54 10 f0       	push   $0xf01054d1
f01014a7:	e8 f4 eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014ac:	83 ec 0c             	sub    $0xc,%esp
f01014af:	6a 00                	push   $0x0
f01014b1:	e8 37 f9 ff ff       	call   f0100ded <page_alloc>
f01014b6:	83 c4 10             	add    $0x10,%esp
f01014b9:	85 c0                	test   %eax,%eax
f01014bb:	74 19                	je     f01014d6 <mem_init+0x3d8>
f01014bd:	68 4d 56 10 f0       	push   $0xf010564d
f01014c2:	68 f7 54 10 f0       	push   $0xf01054f7
f01014c7:	68 f5 02 00 00       	push   $0x2f5
f01014cc:	68 d1 54 10 f0       	push   $0xf01054d1
f01014d1:	e8 ca eb ff ff       	call   f01000a0 <_panic>
f01014d6:	89 f0                	mov    %esi,%eax
f01014d8:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01014de:	c1 f8 03             	sar    $0x3,%eax
f01014e1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014e4:	89 c2                	mov    %eax,%edx
f01014e6:	c1 ea 0c             	shr    $0xc,%edx
f01014e9:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01014ef:	72 12                	jb     f0101503 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f1:	50                   	push   %eax
f01014f2:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01014f7:	6a 56                	push   $0x56
f01014f9:	68 dd 54 10 f0       	push   $0xf01054dd
f01014fe:	e8 9d eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101503:	83 ec 04             	sub    $0x4,%esp
f0101506:	68 00 10 00 00       	push   $0x1000
f010150b:	6a 01                	push   $0x1
f010150d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101512:	50                   	push   %eax
f0101513:	e8 de 2d 00 00       	call   f01042f6 <memset>
	page_free(pp0);
f0101518:	89 34 24             	mov    %esi,(%esp)
f010151b:	e8 3d f9 ff ff       	call   f0100e5d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101520:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101527:	e8 c1 f8 ff ff       	call   f0100ded <page_alloc>
f010152c:	83 c4 10             	add    $0x10,%esp
f010152f:	85 c0                	test   %eax,%eax
f0101531:	75 19                	jne    f010154c <mem_init+0x44e>
f0101533:	68 5c 56 10 f0       	push   $0xf010565c
f0101538:	68 f7 54 10 f0       	push   $0xf01054f7
f010153d:	68 fa 02 00 00       	push   $0x2fa
f0101542:	68 d1 54 10 f0       	push   $0xf01054d1
f0101547:	e8 54 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010154c:	39 c6                	cmp    %eax,%esi
f010154e:	74 19                	je     f0101569 <mem_init+0x46b>
f0101550:	68 7a 56 10 f0       	push   $0xf010567a
f0101555:	68 f7 54 10 f0       	push   $0xf01054f7
f010155a:	68 fb 02 00 00       	push   $0x2fb
f010155f:	68 d1 54 10 f0       	push   $0xf01054d1
f0101564:	e8 37 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101569:	89 f0                	mov    %esi,%eax
f010156b:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101571:	c1 f8 03             	sar    $0x3,%eax
f0101574:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101577:	89 c2                	mov    %eax,%edx
f0101579:	c1 ea 0c             	shr    $0xc,%edx
f010157c:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0101582:	72 12                	jb     f0101596 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101584:	50                   	push   %eax
f0101585:	68 c4 4c 10 f0       	push   $0xf0104cc4
f010158a:	6a 56                	push   $0x56
f010158c:	68 dd 54 10 f0       	push   $0xf01054dd
f0101591:	e8 0a eb ff ff       	call   f01000a0 <_panic>
f0101596:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010159c:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015a2:	80 38 00             	cmpb   $0x0,(%eax)
f01015a5:	74 19                	je     f01015c0 <mem_init+0x4c2>
f01015a7:	68 8a 56 10 f0       	push   $0xf010568a
f01015ac:	68 f7 54 10 f0       	push   $0xf01054f7
f01015b1:	68 fe 02 00 00       	push   $0x2fe
f01015b6:	68 d1 54 10 f0       	push   $0xf01054d1
f01015bb:	e8 e0 ea ff ff       	call   f01000a0 <_panic>
f01015c0:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015c3:	39 d0                	cmp    %edx,%eax
f01015c5:	75 db                	jne    f01015a2 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015c7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015ca:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	// free the pages we took
	page_free(pp0);
f01015cf:	83 ec 0c             	sub    $0xc,%esp
f01015d2:	56                   	push   %esi
f01015d3:	e8 85 f8 ff ff       	call   f0100e5d <page_free>
	page_free(pp1);
f01015d8:	89 3c 24             	mov    %edi,(%esp)
f01015db:	e8 7d f8 ff ff       	call   f0100e5d <page_free>
	page_free(pp2);
f01015e0:	83 c4 04             	add    $0x4,%esp
f01015e3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015e6:	e8 72 f8 ff ff       	call   f0100e5d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015eb:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f01015f0:	83 c4 10             	add    $0x10,%esp
f01015f3:	eb 05                	jmp    f01015fa <mem_init+0x4fc>
		--nfree;
f01015f5:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015f8:	8b 00                	mov    (%eax),%eax
f01015fa:	85 c0                	test   %eax,%eax
f01015fc:	75 f7                	jne    f01015f5 <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f01015fe:	85 db                	test   %ebx,%ebx
f0101600:	74 19                	je     f010161b <mem_init+0x51d>
f0101602:	68 94 56 10 f0       	push   $0xf0105694
f0101607:	68 f7 54 10 f0       	push   $0xf01054f7
f010160c:	68 0b 03 00 00       	push   $0x30b
f0101611:	68 d1 54 10 f0       	push   $0xf01054d1
f0101616:	e8 85 ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010161b:	83 ec 0c             	sub    $0xc,%esp
f010161e:	68 c8 4e 10 f0       	push   $0xf0104ec8
f0101623:	e8 f4 18 00 00       	call   f0102f1c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101628:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162f:	e8 b9 f7 ff ff       	call   f0100ded <page_alloc>
f0101634:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101637:	83 c4 10             	add    $0x10,%esp
f010163a:	85 c0                	test   %eax,%eax
f010163c:	75 19                	jne    f0101657 <mem_init+0x559>
f010163e:	68 a2 55 10 f0       	push   $0xf01055a2
f0101643:	68 f7 54 10 f0       	push   $0xf01054f7
f0101648:	68 69 03 00 00       	push   $0x369
f010164d:	68 d1 54 10 f0       	push   $0xf01054d1
f0101652:	e8 49 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101657:	83 ec 0c             	sub    $0xc,%esp
f010165a:	6a 00                	push   $0x0
f010165c:	e8 8c f7 ff ff       	call   f0100ded <page_alloc>
f0101661:	89 c3                	mov    %eax,%ebx
f0101663:	83 c4 10             	add    $0x10,%esp
f0101666:	85 c0                	test   %eax,%eax
f0101668:	75 19                	jne    f0101683 <mem_init+0x585>
f010166a:	68 b8 55 10 f0       	push   $0xf01055b8
f010166f:	68 f7 54 10 f0       	push   $0xf01054f7
f0101674:	68 6a 03 00 00       	push   $0x36a
f0101679:	68 d1 54 10 f0       	push   $0xf01054d1
f010167e:	e8 1d ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101683:	83 ec 0c             	sub    $0xc,%esp
f0101686:	6a 00                	push   $0x0
f0101688:	e8 60 f7 ff ff       	call   f0100ded <page_alloc>
f010168d:	89 c6                	mov    %eax,%esi
f010168f:	83 c4 10             	add    $0x10,%esp
f0101692:	85 c0                	test   %eax,%eax
f0101694:	75 19                	jne    f01016af <mem_init+0x5b1>
f0101696:	68 ce 55 10 f0       	push   $0xf01055ce
f010169b:	68 f7 54 10 f0       	push   $0xf01054f7
f01016a0:	68 6b 03 00 00       	push   $0x36b
f01016a5:	68 d1 54 10 f0       	push   $0xf01054d1
f01016aa:	e8 f1 e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016af:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016b2:	75 19                	jne    f01016cd <mem_init+0x5cf>
f01016b4:	68 e4 55 10 f0       	push   $0xf01055e4
f01016b9:	68 f7 54 10 f0       	push   $0xf01054f7
f01016be:	68 6e 03 00 00       	push   $0x36e
f01016c3:	68 d1 54 10 f0       	push   $0xf01054d1
f01016c8:	e8 d3 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016cd:	39 c3                	cmp    %eax,%ebx
f01016cf:	74 05                	je     f01016d6 <mem_init+0x5d8>
f01016d1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016d4:	75 19                	jne    f01016ef <mem_init+0x5f1>
f01016d6:	68 a8 4e 10 f0       	push   $0xf0104ea8
f01016db:	68 f7 54 10 f0       	push   $0xf01054f7
f01016e0:	68 6f 03 00 00       	push   $0x36f
f01016e5:	68 d1 54 10 f0       	push   $0xf01054d1
f01016ea:	e8 b1 e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016ef:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f01016f4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016f7:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f01016fe:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101701:	83 ec 0c             	sub    $0xc,%esp
f0101704:	6a 00                	push   $0x0
f0101706:	e8 e2 f6 ff ff       	call   f0100ded <page_alloc>
f010170b:	83 c4 10             	add    $0x10,%esp
f010170e:	85 c0                	test   %eax,%eax
f0101710:	74 19                	je     f010172b <mem_init+0x62d>
f0101712:	68 4d 56 10 f0       	push   $0xf010564d
f0101717:	68 f7 54 10 f0       	push   $0xf01054f7
f010171c:	68 76 03 00 00       	push   $0x376
f0101721:	68 d1 54 10 f0       	push   $0xf01054d1
f0101726:	e8 75 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010172b:	83 ec 04             	sub    $0x4,%esp
f010172e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101731:	50                   	push   %eax
f0101732:	6a 00                	push   $0x0
f0101734:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010173a:	e8 b2 f8 ff ff       	call   f0100ff1 <page_lookup>
f010173f:	83 c4 10             	add    $0x10,%esp
f0101742:	85 c0                	test   %eax,%eax
f0101744:	74 19                	je     f010175f <mem_init+0x661>
f0101746:	68 e8 4e 10 f0       	push   $0xf0104ee8
f010174b:	68 f7 54 10 f0       	push   $0xf01054f7
f0101750:	68 79 03 00 00       	push   $0x379
f0101755:	68 d1 54 10 f0       	push   $0xf01054d1
f010175a:	e8 41 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010175f:	6a 02                	push   $0x2
f0101761:	6a 00                	push   $0x0
f0101763:	53                   	push   %ebx
f0101764:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010176a:	e8 26 f9 ff ff       	call   f0101095 <page_insert>
f010176f:	83 c4 10             	add    $0x10,%esp
f0101772:	85 c0                	test   %eax,%eax
f0101774:	78 19                	js     f010178f <mem_init+0x691>
f0101776:	68 20 4f 10 f0       	push   $0xf0104f20
f010177b:	68 f7 54 10 f0       	push   $0xf01054f7
f0101780:	68 7c 03 00 00       	push   $0x37c
f0101785:	68 d1 54 10 f0       	push   $0xf01054d1
f010178a:	e8 11 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010178f:	83 ec 0c             	sub    $0xc,%esp
f0101792:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101795:	e8 c3 f6 ff ff       	call   f0100e5d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010179a:	6a 02                	push   $0x2
f010179c:	6a 00                	push   $0x0
f010179e:	53                   	push   %ebx
f010179f:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01017a5:	e8 eb f8 ff ff       	call   f0101095 <page_insert>
f01017aa:	83 c4 20             	add    $0x20,%esp
f01017ad:	85 c0                	test   %eax,%eax
f01017af:	74 19                	je     f01017ca <mem_init+0x6cc>
f01017b1:	68 50 4f 10 f0       	push   $0xf0104f50
f01017b6:	68 f7 54 10 f0       	push   $0xf01054f7
f01017bb:	68 80 03 00 00       	push   $0x380
f01017c0:	68 d1 54 10 f0       	push   $0xf01054d1
f01017c5:	e8 d6 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017ca:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d0:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f01017d5:	89 c1                	mov    %eax,%ecx
f01017d7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017da:	8b 17                	mov    (%edi),%edx
f01017dc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017e5:	29 c8                	sub    %ecx,%eax
f01017e7:	c1 f8 03             	sar    $0x3,%eax
f01017ea:	c1 e0 0c             	shl    $0xc,%eax
f01017ed:	39 c2                	cmp    %eax,%edx
f01017ef:	74 19                	je     f010180a <mem_init+0x70c>
f01017f1:	68 80 4f 10 f0       	push   $0xf0104f80
f01017f6:	68 f7 54 10 f0       	push   $0xf01054f7
f01017fb:	68 81 03 00 00       	push   $0x381
f0101800:	68 d1 54 10 f0       	push   $0xf01054d1
f0101805:	e8 96 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010180a:	ba 00 00 00 00       	mov    $0x0,%edx
f010180f:	89 f8                	mov    %edi,%eax
f0101811:	e8 64 f1 ff ff       	call   f010097a <check_va2pa>
f0101816:	89 da                	mov    %ebx,%edx
f0101818:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010181b:	c1 fa 03             	sar    $0x3,%edx
f010181e:	c1 e2 0c             	shl    $0xc,%edx
f0101821:	39 d0                	cmp    %edx,%eax
f0101823:	74 19                	je     f010183e <mem_init+0x740>
f0101825:	68 a8 4f 10 f0       	push   $0xf0104fa8
f010182a:	68 f7 54 10 f0       	push   $0xf01054f7
f010182f:	68 82 03 00 00       	push   $0x382
f0101834:	68 d1 54 10 f0       	push   $0xf01054d1
f0101839:	e8 62 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f010183e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101843:	74 19                	je     f010185e <mem_init+0x760>
f0101845:	68 9f 56 10 f0       	push   $0xf010569f
f010184a:	68 f7 54 10 f0       	push   $0xf01054f7
f010184f:	68 83 03 00 00       	push   $0x383
f0101854:	68 d1 54 10 f0       	push   $0xf01054d1
f0101859:	e8 42 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f010185e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101861:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101866:	74 19                	je     f0101881 <mem_init+0x783>
f0101868:	68 b0 56 10 f0       	push   $0xf01056b0
f010186d:	68 f7 54 10 f0       	push   $0xf01054f7
f0101872:	68 84 03 00 00       	push   $0x384
f0101877:	68 d1 54 10 f0       	push   $0xf01054d1
f010187c:	e8 1f e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101881:	6a 02                	push   $0x2
f0101883:	68 00 10 00 00       	push   $0x1000
f0101888:	56                   	push   %esi
f0101889:	57                   	push   %edi
f010188a:	e8 06 f8 ff ff       	call   f0101095 <page_insert>
f010188f:	83 c4 10             	add    $0x10,%esp
f0101892:	85 c0                	test   %eax,%eax
f0101894:	74 19                	je     f01018af <mem_init+0x7b1>
f0101896:	68 d8 4f 10 f0       	push   $0xf0104fd8
f010189b:	68 f7 54 10 f0       	push   $0xf01054f7
f01018a0:	68 87 03 00 00       	push   $0x387
f01018a5:	68 d1 54 10 f0       	push   $0xf01054d1
f01018aa:	e8 f1 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018af:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018b4:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01018b9:	e8 bc f0 ff ff       	call   f010097a <check_va2pa>
f01018be:	89 f2                	mov    %esi,%edx
f01018c0:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01018c6:	c1 fa 03             	sar    $0x3,%edx
f01018c9:	c1 e2 0c             	shl    $0xc,%edx
f01018cc:	39 d0                	cmp    %edx,%eax
f01018ce:	74 19                	je     f01018e9 <mem_init+0x7eb>
f01018d0:	68 14 50 10 f0       	push   $0xf0105014
f01018d5:	68 f7 54 10 f0       	push   $0xf01054f7
f01018da:	68 88 03 00 00       	push   $0x388
f01018df:	68 d1 54 10 f0       	push   $0xf01054d1
f01018e4:	e8 b7 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018e9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018ee:	74 19                	je     f0101909 <mem_init+0x80b>
f01018f0:	68 c1 56 10 f0       	push   $0xf01056c1
f01018f5:	68 f7 54 10 f0       	push   $0xf01054f7
f01018fa:	68 89 03 00 00       	push   $0x389
f01018ff:	68 d1 54 10 f0       	push   $0xf01054d1
f0101904:	e8 97 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101909:	83 ec 0c             	sub    $0xc,%esp
f010190c:	6a 00                	push   $0x0
f010190e:	e8 da f4 ff ff       	call   f0100ded <page_alloc>
f0101913:	83 c4 10             	add    $0x10,%esp
f0101916:	85 c0                	test   %eax,%eax
f0101918:	74 19                	je     f0101933 <mem_init+0x835>
f010191a:	68 4d 56 10 f0       	push   $0xf010564d
f010191f:	68 f7 54 10 f0       	push   $0xf01054f7
f0101924:	68 8c 03 00 00       	push   $0x38c
f0101929:	68 d1 54 10 f0       	push   $0xf01054d1
f010192e:	e8 6d e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101933:	6a 02                	push   $0x2
f0101935:	68 00 10 00 00       	push   $0x1000
f010193a:	56                   	push   %esi
f010193b:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101941:	e8 4f f7 ff ff       	call   f0101095 <page_insert>
f0101946:	83 c4 10             	add    $0x10,%esp
f0101949:	85 c0                	test   %eax,%eax
f010194b:	74 19                	je     f0101966 <mem_init+0x868>
f010194d:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0101952:	68 f7 54 10 f0       	push   $0xf01054f7
f0101957:	68 8f 03 00 00       	push   $0x38f
f010195c:	68 d1 54 10 f0       	push   $0xf01054d1
f0101961:	e8 3a e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101966:	ba 00 10 00 00       	mov    $0x1000,%edx
f010196b:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101970:	e8 05 f0 ff ff       	call   f010097a <check_va2pa>
f0101975:	89 f2                	mov    %esi,%edx
f0101977:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f010197d:	c1 fa 03             	sar    $0x3,%edx
f0101980:	c1 e2 0c             	shl    $0xc,%edx
f0101983:	39 d0                	cmp    %edx,%eax
f0101985:	74 19                	je     f01019a0 <mem_init+0x8a2>
f0101987:	68 14 50 10 f0       	push   $0xf0105014
f010198c:	68 f7 54 10 f0       	push   $0xf01054f7
f0101991:	68 90 03 00 00       	push   $0x390
f0101996:	68 d1 54 10 f0       	push   $0xf01054d1
f010199b:	e8 00 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019a0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019a5:	74 19                	je     f01019c0 <mem_init+0x8c2>
f01019a7:	68 c1 56 10 f0       	push   $0xf01056c1
f01019ac:	68 f7 54 10 f0       	push   $0xf01054f7
f01019b1:	68 91 03 00 00       	push   $0x391
f01019b6:	68 d1 54 10 f0       	push   $0xf01054d1
f01019bb:	e8 e0 e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01019c0:	83 ec 0c             	sub    $0xc,%esp
f01019c3:	6a 00                	push   $0x0
f01019c5:	e8 23 f4 ff ff       	call   f0100ded <page_alloc>
f01019ca:	83 c4 10             	add    $0x10,%esp
f01019cd:	85 c0                	test   %eax,%eax
f01019cf:	74 19                	je     f01019ea <mem_init+0x8ec>
f01019d1:	68 4d 56 10 f0       	push   $0xf010564d
f01019d6:	68 f7 54 10 f0       	push   $0xf01054f7
f01019db:	68 95 03 00 00       	push   $0x395
f01019e0:	68 d1 54 10 f0       	push   $0xf01054d1
f01019e5:	e8 b6 e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019ea:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f01019f0:	8b 02                	mov    (%edx),%eax
f01019f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019f7:	89 c1                	mov    %eax,%ecx
f01019f9:	c1 e9 0c             	shr    $0xc,%ecx
f01019fc:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f0101a02:	72 15                	jb     f0101a19 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a04:	50                   	push   %eax
f0101a05:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0101a0a:	68 98 03 00 00       	push   $0x398
f0101a0f:	68 d1 54 10 f0       	push   $0xf01054d1
f0101a14:	e8 87 e6 ff ff       	call   f01000a0 <_panic>
f0101a19:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a1e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a21:	83 ec 04             	sub    $0x4,%esp
f0101a24:	6a 00                	push   $0x0
f0101a26:	68 00 10 00 00       	push   $0x1000
f0101a2b:	52                   	push   %edx
f0101a2c:	e8 8e f4 ff ff       	call   f0100ebf <pgdir_walk>
f0101a31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a34:	8d 57 04             	lea    0x4(%edi),%edx
f0101a37:	83 c4 10             	add    $0x10,%esp
f0101a3a:	39 d0                	cmp    %edx,%eax
f0101a3c:	74 19                	je     f0101a57 <mem_init+0x959>
f0101a3e:	68 44 50 10 f0       	push   $0xf0105044
f0101a43:	68 f7 54 10 f0       	push   $0xf01054f7
f0101a48:	68 99 03 00 00       	push   $0x399
f0101a4d:	68 d1 54 10 f0       	push   $0xf01054d1
f0101a52:	e8 49 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a57:	6a 06                	push   $0x6
f0101a59:	68 00 10 00 00       	push   $0x1000
f0101a5e:	56                   	push   %esi
f0101a5f:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101a65:	e8 2b f6 ff ff       	call   f0101095 <page_insert>
f0101a6a:	83 c4 10             	add    $0x10,%esp
f0101a6d:	85 c0                	test   %eax,%eax
f0101a6f:	74 19                	je     f0101a8a <mem_init+0x98c>
f0101a71:	68 84 50 10 f0       	push   $0xf0105084
f0101a76:	68 f7 54 10 f0       	push   $0xf01054f7
f0101a7b:	68 9c 03 00 00       	push   $0x39c
f0101a80:	68 d1 54 10 f0       	push   $0xf01054d1
f0101a85:	e8 16 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a8a:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101a90:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a95:	89 f8                	mov    %edi,%eax
f0101a97:	e8 de ee ff ff       	call   f010097a <check_va2pa>
f0101a9c:	89 f2                	mov    %esi,%edx
f0101a9e:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101aa4:	c1 fa 03             	sar    $0x3,%edx
f0101aa7:	c1 e2 0c             	shl    $0xc,%edx
f0101aaa:	39 d0                	cmp    %edx,%eax
f0101aac:	74 19                	je     f0101ac7 <mem_init+0x9c9>
f0101aae:	68 14 50 10 f0       	push   $0xf0105014
f0101ab3:	68 f7 54 10 f0       	push   $0xf01054f7
f0101ab8:	68 9d 03 00 00       	push   $0x39d
f0101abd:	68 d1 54 10 f0       	push   $0xf01054d1
f0101ac2:	e8 d9 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101ac7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101acc:	74 19                	je     f0101ae7 <mem_init+0x9e9>
f0101ace:	68 c1 56 10 f0       	push   $0xf01056c1
f0101ad3:	68 f7 54 10 f0       	push   $0xf01054f7
f0101ad8:	68 9e 03 00 00       	push   $0x39e
f0101add:	68 d1 54 10 f0       	push   $0xf01054d1
f0101ae2:	e8 b9 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ae7:	83 ec 04             	sub    $0x4,%esp
f0101aea:	6a 00                	push   $0x0
f0101aec:	68 00 10 00 00       	push   $0x1000
f0101af1:	57                   	push   %edi
f0101af2:	e8 c8 f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101af7:	83 c4 10             	add    $0x10,%esp
f0101afa:	f6 00 04             	testb  $0x4,(%eax)
f0101afd:	75 19                	jne    f0101b18 <mem_init+0xa1a>
f0101aff:	68 c4 50 10 f0       	push   $0xf01050c4
f0101b04:	68 f7 54 10 f0       	push   $0xf01054f7
f0101b09:	68 9f 03 00 00       	push   $0x39f
f0101b0e:	68 d1 54 10 f0       	push   $0xf01054d1
f0101b13:	e8 88 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b18:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101b1d:	f6 00 04             	testb  $0x4,(%eax)
f0101b20:	75 19                	jne    f0101b3b <mem_init+0xa3d>
f0101b22:	68 d2 56 10 f0       	push   $0xf01056d2
f0101b27:	68 f7 54 10 f0       	push   $0xf01054f7
f0101b2c:	68 a0 03 00 00       	push   $0x3a0
f0101b31:	68 d1 54 10 f0       	push   $0xf01054d1
f0101b36:	e8 65 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b3b:	6a 02                	push   $0x2
f0101b3d:	68 00 10 00 00       	push   $0x1000
f0101b42:	56                   	push   %esi
f0101b43:	50                   	push   %eax
f0101b44:	e8 4c f5 ff ff       	call   f0101095 <page_insert>
f0101b49:	83 c4 10             	add    $0x10,%esp
f0101b4c:	85 c0                	test   %eax,%eax
f0101b4e:	74 19                	je     f0101b69 <mem_init+0xa6b>
f0101b50:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0101b55:	68 f7 54 10 f0       	push   $0xf01054f7
f0101b5a:	68 a3 03 00 00       	push   $0x3a3
f0101b5f:	68 d1 54 10 f0       	push   $0xf01054d1
f0101b64:	e8 37 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b69:	83 ec 04             	sub    $0x4,%esp
f0101b6c:	6a 00                	push   $0x0
f0101b6e:	68 00 10 00 00       	push   $0x1000
f0101b73:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b79:	e8 41 f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	f6 00 02             	testb  $0x2,(%eax)
f0101b84:	75 19                	jne    f0101b9f <mem_init+0xaa1>
f0101b86:	68 f8 50 10 f0       	push   $0xf01050f8
f0101b8b:	68 f7 54 10 f0       	push   $0xf01054f7
f0101b90:	68 a4 03 00 00       	push   $0x3a4
f0101b95:	68 d1 54 10 f0       	push   $0xf01054d1
f0101b9a:	e8 01 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b9f:	83 ec 04             	sub    $0x4,%esp
f0101ba2:	6a 00                	push   $0x0
f0101ba4:	68 00 10 00 00       	push   $0x1000
f0101ba9:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101baf:	e8 0b f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101bb4:	83 c4 10             	add    $0x10,%esp
f0101bb7:	f6 00 04             	testb  $0x4,(%eax)
f0101bba:	74 19                	je     f0101bd5 <mem_init+0xad7>
f0101bbc:	68 2c 51 10 f0       	push   $0xf010512c
f0101bc1:	68 f7 54 10 f0       	push   $0xf01054f7
f0101bc6:	68 a5 03 00 00       	push   $0x3a5
f0101bcb:	68 d1 54 10 f0       	push   $0xf01054d1
f0101bd0:	e8 cb e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bd5:	6a 02                	push   $0x2
f0101bd7:	68 00 00 40 00       	push   $0x400000
f0101bdc:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bdf:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101be5:	e8 ab f4 ff ff       	call   f0101095 <page_insert>
f0101bea:	83 c4 10             	add    $0x10,%esp
f0101bed:	85 c0                	test   %eax,%eax
f0101bef:	78 19                	js     f0101c0a <mem_init+0xb0c>
f0101bf1:	68 64 51 10 f0       	push   $0xf0105164
f0101bf6:	68 f7 54 10 f0       	push   $0xf01054f7
f0101bfb:	68 a8 03 00 00       	push   $0x3a8
f0101c00:	68 d1 54 10 f0       	push   $0xf01054d1
f0101c05:	e8 96 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c0a:	6a 02                	push   $0x2
f0101c0c:	68 00 10 00 00       	push   $0x1000
f0101c11:	53                   	push   %ebx
f0101c12:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c18:	e8 78 f4 ff ff       	call   f0101095 <page_insert>
f0101c1d:	83 c4 10             	add    $0x10,%esp
f0101c20:	85 c0                	test   %eax,%eax
f0101c22:	74 19                	je     f0101c3d <mem_init+0xb3f>
f0101c24:	68 9c 51 10 f0       	push   $0xf010519c
f0101c29:	68 f7 54 10 f0       	push   $0xf01054f7
f0101c2e:	68 ab 03 00 00       	push   $0x3ab
f0101c33:	68 d1 54 10 f0       	push   $0xf01054d1
f0101c38:	e8 63 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c3d:	83 ec 04             	sub    $0x4,%esp
f0101c40:	6a 00                	push   $0x0
f0101c42:	68 00 10 00 00       	push   $0x1000
f0101c47:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c4d:	e8 6d f2 ff ff       	call   f0100ebf <pgdir_walk>
f0101c52:	83 c4 10             	add    $0x10,%esp
f0101c55:	f6 00 04             	testb  $0x4,(%eax)
f0101c58:	74 19                	je     f0101c73 <mem_init+0xb75>
f0101c5a:	68 2c 51 10 f0       	push   $0xf010512c
f0101c5f:	68 f7 54 10 f0       	push   $0xf01054f7
f0101c64:	68 ac 03 00 00       	push   $0x3ac
f0101c69:	68 d1 54 10 f0       	push   $0xf01054d1
f0101c6e:	e8 2d e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c73:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101c79:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c7e:	89 f8                	mov    %edi,%eax
f0101c80:	e8 f5 ec ff ff       	call   f010097a <check_va2pa>
f0101c85:	89 c1                	mov    %eax,%ecx
f0101c87:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c8a:	89 d8                	mov    %ebx,%eax
f0101c8c:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101c92:	c1 f8 03             	sar    $0x3,%eax
f0101c95:	c1 e0 0c             	shl    $0xc,%eax
f0101c98:	39 c1                	cmp    %eax,%ecx
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0xbb7>
f0101c9c:	68 d8 51 10 f0       	push   $0xf01051d8
f0101ca1:	68 f7 54 10 f0       	push   $0xf01054f7
f0101ca6:	68 af 03 00 00       	push   $0x3af
f0101cab:	68 d1 54 10 f0       	push   $0xf01054d1
f0101cb0:	e8 eb e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cb5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cba:	89 f8                	mov    %edi,%eax
f0101cbc:	e8 b9 ec ff ff       	call   f010097a <check_va2pa>
f0101cc1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xbe1>
f0101cc6:	68 04 52 10 f0       	push   $0xf0105204
f0101ccb:	68 f7 54 10 f0       	push   $0xf01054f7
f0101cd0:	68 b0 03 00 00       	push   $0x3b0
f0101cd5:	68 d1 54 10 f0       	push   $0xf01054d1
f0101cda:	e8 c1 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cdf:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ce4:	74 19                	je     f0101cff <mem_init+0xc01>
f0101ce6:	68 e8 56 10 f0       	push   $0xf01056e8
f0101ceb:	68 f7 54 10 f0       	push   $0xf01054f7
f0101cf0:	68 b2 03 00 00       	push   $0x3b2
f0101cf5:	68 d1 54 10 f0       	push   $0xf01054d1
f0101cfa:	e8 a1 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101cff:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d04:	74 19                	je     f0101d1f <mem_init+0xc21>
f0101d06:	68 f9 56 10 f0       	push   $0xf01056f9
f0101d0b:	68 f7 54 10 f0       	push   $0xf01054f7
f0101d10:	68 b3 03 00 00       	push   $0x3b3
f0101d15:	68 d1 54 10 f0       	push   $0xf01054d1
f0101d1a:	e8 81 e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d1f:	83 ec 0c             	sub    $0xc,%esp
f0101d22:	6a 00                	push   $0x0
f0101d24:	e8 c4 f0 ff ff       	call   f0100ded <page_alloc>
f0101d29:	83 c4 10             	add    $0x10,%esp
f0101d2c:	39 c6                	cmp    %eax,%esi
f0101d2e:	75 04                	jne    f0101d34 <mem_init+0xc36>
f0101d30:	85 c0                	test   %eax,%eax
f0101d32:	75 19                	jne    f0101d4d <mem_init+0xc4f>
f0101d34:	68 34 52 10 f0       	push   $0xf0105234
f0101d39:	68 f7 54 10 f0       	push   $0xf01054f7
f0101d3e:	68 b6 03 00 00       	push   $0x3b6
f0101d43:	68 d1 54 10 f0       	push   $0xf01054d1
f0101d48:	e8 53 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d4d:	83 ec 08             	sub    $0x8,%esp
f0101d50:	6a 00                	push   $0x0
f0101d52:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101d58:	e8 ee f2 ff ff       	call   f010104b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d5d:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101d63:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d68:	89 f8                	mov    %edi,%eax
f0101d6a:	e8 0b ec ff ff       	call   f010097a <check_va2pa>
f0101d6f:	83 c4 10             	add    $0x10,%esp
f0101d72:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d75:	74 19                	je     f0101d90 <mem_init+0xc92>
f0101d77:	68 58 52 10 f0       	push   $0xf0105258
f0101d7c:	68 f7 54 10 f0       	push   $0xf01054f7
f0101d81:	68 ba 03 00 00       	push   $0x3ba
f0101d86:	68 d1 54 10 f0       	push   $0xf01054d1
f0101d8b:	e8 10 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d90:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d95:	89 f8                	mov    %edi,%eax
f0101d97:	e8 de eb ff ff       	call   f010097a <check_va2pa>
f0101d9c:	89 da                	mov    %ebx,%edx
f0101d9e:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101da4:	c1 fa 03             	sar    $0x3,%edx
f0101da7:	c1 e2 0c             	shl    $0xc,%edx
f0101daa:	39 d0                	cmp    %edx,%eax
f0101dac:	74 19                	je     f0101dc7 <mem_init+0xcc9>
f0101dae:	68 04 52 10 f0       	push   $0xf0105204
f0101db3:	68 f7 54 10 f0       	push   $0xf01054f7
f0101db8:	68 bb 03 00 00       	push   $0x3bb
f0101dbd:	68 d1 54 10 f0       	push   $0xf01054d1
f0101dc2:	e8 d9 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dc7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dcc:	74 19                	je     f0101de7 <mem_init+0xce9>
f0101dce:	68 9f 56 10 f0       	push   $0xf010569f
f0101dd3:	68 f7 54 10 f0       	push   $0xf01054f7
f0101dd8:	68 bc 03 00 00       	push   $0x3bc
f0101ddd:	68 d1 54 10 f0       	push   $0xf01054d1
f0101de2:	e8 b9 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101de7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dec:	74 19                	je     f0101e07 <mem_init+0xd09>
f0101dee:	68 f9 56 10 f0       	push   $0xf01056f9
f0101df3:	68 f7 54 10 f0       	push   $0xf01054f7
f0101df8:	68 bd 03 00 00       	push   $0x3bd
f0101dfd:	68 d1 54 10 f0       	push   $0xf01054d1
f0101e02:	e8 99 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e07:	6a 00                	push   $0x0
f0101e09:	68 00 10 00 00       	push   $0x1000
f0101e0e:	53                   	push   %ebx
f0101e0f:	57                   	push   %edi
f0101e10:	e8 80 f2 ff ff       	call   f0101095 <page_insert>
f0101e15:	83 c4 10             	add    $0x10,%esp
f0101e18:	85 c0                	test   %eax,%eax
f0101e1a:	74 19                	je     f0101e35 <mem_init+0xd37>
f0101e1c:	68 7c 52 10 f0       	push   $0xf010527c
f0101e21:	68 f7 54 10 f0       	push   $0xf01054f7
f0101e26:	68 c0 03 00 00       	push   $0x3c0
f0101e2b:	68 d1 54 10 f0       	push   $0xf01054d1
f0101e30:	e8 6b e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e35:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e3a:	75 19                	jne    f0101e55 <mem_init+0xd57>
f0101e3c:	68 0a 57 10 f0       	push   $0xf010570a
f0101e41:	68 f7 54 10 f0       	push   $0xf01054f7
f0101e46:	68 c1 03 00 00       	push   $0x3c1
f0101e4b:	68 d1 54 10 f0       	push   $0xf01054d1
f0101e50:	e8 4b e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e55:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e58:	74 19                	je     f0101e73 <mem_init+0xd75>
f0101e5a:	68 16 57 10 f0       	push   $0xf0105716
f0101e5f:	68 f7 54 10 f0       	push   $0xf01054f7
f0101e64:	68 c2 03 00 00       	push   $0x3c2
f0101e69:	68 d1 54 10 f0       	push   $0xf01054d1
f0101e6e:	e8 2d e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e73:	83 ec 08             	sub    $0x8,%esp
f0101e76:	68 00 10 00 00       	push   $0x1000
f0101e7b:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101e81:	e8 c5 f1 ff ff       	call   f010104b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e86:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101e8c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e91:	89 f8                	mov    %edi,%eax
f0101e93:	e8 e2 ea ff ff       	call   f010097a <check_va2pa>
f0101e98:	83 c4 10             	add    $0x10,%esp
f0101e9b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e9e:	74 19                	je     f0101eb9 <mem_init+0xdbb>
f0101ea0:	68 58 52 10 f0       	push   $0xf0105258
f0101ea5:	68 f7 54 10 f0       	push   $0xf01054f7
f0101eaa:	68 c6 03 00 00       	push   $0x3c6
f0101eaf:	68 d1 54 10 f0       	push   $0xf01054d1
f0101eb4:	e8 e7 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eb9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ebe:	89 f8                	mov    %edi,%eax
f0101ec0:	e8 b5 ea ff ff       	call   f010097a <check_va2pa>
f0101ec5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec8:	74 19                	je     f0101ee3 <mem_init+0xde5>
f0101eca:	68 b4 52 10 f0       	push   $0xf01052b4
f0101ecf:	68 f7 54 10 f0       	push   $0xf01054f7
f0101ed4:	68 c7 03 00 00       	push   $0x3c7
f0101ed9:	68 d1 54 10 f0       	push   $0xf01054d1
f0101ede:	e8 bd e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101ee3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ee8:	74 19                	je     f0101f03 <mem_init+0xe05>
f0101eea:	68 2b 57 10 f0       	push   $0xf010572b
f0101eef:	68 f7 54 10 f0       	push   $0xf01054f7
f0101ef4:	68 c8 03 00 00       	push   $0x3c8
f0101ef9:	68 d1 54 10 f0       	push   $0xf01054d1
f0101efe:	e8 9d e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f03:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f08:	74 19                	je     f0101f23 <mem_init+0xe25>
f0101f0a:	68 f9 56 10 f0       	push   $0xf01056f9
f0101f0f:	68 f7 54 10 f0       	push   $0xf01054f7
f0101f14:	68 c9 03 00 00       	push   $0x3c9
f0101f19:	68 d1 54 10 f0       	push   $0xf01054d1
f0101f1e:	e8 7d e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f23:	83 ec 0c             	sub    $0xc,%esp
f0101f26:	6a 00                	push   $0x0
f0101f28:	e8 c0 ee ff ff       	call   f0100ded <page_alloc>
f0101f2d:	83 c4 10             	add    $0x10,%esp
f0101f30:	85 c0                	test   %eax,%eax
f0101f32:	74 04                	je     f0101f38 <mem_init+0xe3a>
f0101f34:	39 c3                	cmp    %eax,%ebx
f0101f36:	74 19                	je     f0101f51 <mem_init+0xe53>
f0101f38:	68 dc 52 10 f0       	push   $0xf01052dc
f0101f3d:	68 f7 54 10 f0       	push   $0xf01054f7
f0101f42:	68 cc 03 00 00       	push   $0x3cc
f0101f47:	68 d1 54 10 f0       	push   $0xf01054d1
f0101f4c:	e8 4f e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f51:	83 ec 0c             	sub    $0xc,%esp
f0101f54:	6a 00                	push   $0x0
f0101f56:	e8 92 ee ff ff       	call   f0100ded <page_alloc>
f0101f5b:	83 c4 10             	add    $0x10,%esp
f0101f5e:	85 c0                	test   %eax,%eax
f0101f60:	74 19                	je     f0101f7b <mem_init+0xe7d>
f0101f62:	68 4d 56 10 f0       	push   $0xf010564d
f0101f67:	68 f7 54 10 f0       	push   $0xf01054f7
f0101f6c:	68 cf 03 00 00       	push   $0x3cf
f0101f71:	68 d1 54 10 f0       	push   $0xf01054d1
f0101f76:	e8 25 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f7b:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f0101f81:	8b 11                	mov    (%ecx),%edx
f0101f83:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f8c:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101f92:	c1 f8 03             	sar    $0x3,%eax
f0101f95:	c1 e0 0c             	shl    $0xc,%eax
f0101f98:	39 c2                	cmp    %eax,%edx
f0101f9a:	74 19                	je     f0101fb5 <mem_init+0xeb7>
f0101f9c:	68 80 4f 10 f0       	push   $0xf0104f80
f0101fa1:	68 f7 54 10 f0       	push   $0xf01054f7
f0101fa6:	68 d2 03 00 00       	push   $0x3d2
f0101fab:	68 d1 54 10 f0       	push   $0xf01054d1
f0101fb0:	e8 eb e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101fb5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fbb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fbe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fc3:	74 19                	je     f0101fde <mem_init+0xee0>
f0101fc5:	68 b0 56 10 f0       	push   $0xf01056b0
f0101fca:	68 f7 54 10 f0       	push   $0xf01054f7
f0101fcf:	68 d4 03 00 00       	push   $0x3d4
f0101fd4:	68 d1 54 10 f0       	push   $0xf01054d1
f0101fd9:	e8 c2 e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101fde:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fe7:	83 ec 0c             	sub    $0xc,%esp
f0101fea:	50                   	push   %eax
f0101feb:	e8 6d ee ff ff       	call   f0100e5d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ff0:	83 c4 0c             	add    $0xc,%esp
f0101ff3:	6a 01                	push   $0x1
f0101ff5:	68 00 10 40 00       	push   $0x401000
f0101ffa:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102000:	e8 ba ee ff ff       	call   f0100ebf <pgdir_walk>
f0102005:	89 c7                	mov    %eax,%edi
f0102007:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010200a:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010200f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102012:	8b 40 04             	mov    0x4(%eax),%eax
f0102015:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010201a:	8b 0d 44 2c 17 f0    	mov    0xf0172c44,%ecx
f0102020:	89 c2                	mov    %eax,%edx
f0102022:	c1 ea 0c             	shr    $0xc,%edx
f0102025:	83 c4 10             	add    $0x10,%esp
f0102028:	39 ca                	cmp    %ecx,%edx
f010202a:	72 15                	jb     f0102041 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010202c:	50                   	push   %eax
f010202d:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102032:	68 db 03 00 00       	push   $0x3db
f0102037:	68 d1 54 10 f0       	push   $0xf01054d1
f010203c:	e8 5f e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102041:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102046:	39 c7                	cmp    %eax,%edi
f0102048:	74 19                	je     f0102063 <mem_init+0xf65>
f010204a:	68 3c 57 10 f0       	push   $0xf010573c
f010204f:	68 f7 54 10 f0       	push   $0xf01054f7
f0102054:	68 dc 03 00 00       	push   $0x3dc
f0102059:	68 d1 54 10 f0       	push   $0xf01054d1
f010205e:	e8 3d e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102063:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102066:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010206d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102070:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102076:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010207c:	c1 f8 03             	sar    $0x3,%eax
f010207f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102082:	89 c2                	mov    %eax,%edx
f0102084:	c1 ea 0c             	shr    $0xc,%edx
f0102087:	39 d1                	cmp    %edx,%ecx
f0102089:	77 12                	ja     f010209d <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010208b:	50                   	push   %eax
f010208c:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102091:	6a 56                	push   $0x56
f0102093:	68 dd 54 10 f0       	push   $0xf01054dd
f0102098:	e8 03 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010209d:	83 ec 04             	sub    $0x4,%esp
f01020a0:	68 00 10 00 00       	push   $0x1000
f01020a5:	68 ff 00 00 00       	push   $0xff
f01020aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020af:	50                   	push   %eax
f01020b0:	e8 41 22 00 00       	call   f01042f6 <memset>
	page_free(pp0);
f01020b5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020b8:	89 3c 24             	mov    %edi,(%esp)
f01020bb:	e8 9d ed ff ff       	call   f0100e5d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020c0:	83 c4 0c             	add    $0xc,%esp
f01020c3:	6a 01                	push   $0x1
f01020c5:	6a 00                	push   $0x0
f01020c7:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01020cd:	e8 ed ed ff ff       	call   f0100ebf <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020d2:	89 fa                	mov    %edi,%edx
f01020d4:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01020da:	c1 fa 03             	sar    $0x3,%edx
f01020dd:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020e0:	89 d0                	mov    %edx,%eax
f01020e2:	c1 e8 0c             	shr    $0xc,%eax
f01020e5:	83 c4 10             	add    $0x10,%esp
f01020e8:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f01020ee:	72 12                	jb     f0102102 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020f0:	52                   	push   %edx
f01020f1:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01020f6:	6a 56                	push   $0x56
f01020f8:	68 dd 54 10 f0       	push   $0xf01054dd
f01020fd:	e8 9e df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102102:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102108:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010210b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102111:	f6 00 01             	testb  $0x1,(%eax)
f0102114:	74 19                	je     f010212f <mem_init+0x1031>
f0102116:	68 54 57 10 f0       	push   $0xf0105754
f010211b:	68 f7 54 10 f0       	push   $0xf01054f7
f0102120:	68 e6 03 00 00       	push   $0x3e6
f0102125:	68 d1 54 10 f0       	push   $0xf01054d1
f010212a:	e8 71 df ff ff       	call   f01000a0 <_panic>
f010212f:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102132:	39 d0                	cmp    %edx,%eax
f0102134:	75 db                	jne    f0102111 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102136:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010213b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102141:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102144:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010214a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010214d:	89 3d 80 1f 17 f0    	mov    %edi,0xf0171f80

	// free the pages we took
	page_free(pp0);
f0102153:	83 ec 0c             	sub    $0xc,%esp
f0102156:	50                   	push   %eax
f0102157:	e8 01 ed ff ff       	call   f0100e5d <page_free>
	page_free(pp1);
f010215c:	89 1c 24             	mov    %ebx,(%esp)
f010215f:	e8 f9 ec ff ff       	call   f0100e5d <page_free>
	page_free(pp2);
f0102164:	89 34 24             	mov    %esi,(%esp)
f0102167:	e8 f1 ec ff ff       	call   f0100e5d <page_free>

	cprintf("check_page() succeeded!\n");
f010216c:	c7 04 24 6b 57 10 f0 	movl   $0xf010576b,(%esp)
f0102173:	e8 a4 0d 00 00       	call   f0102f1c <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_W));
f0102178:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010217d:	83 c4 10             	add    $0x10,%esp
f0102180:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102185:	77 15                	ja     f010219c <mem_init+0x109e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102187:	50                   	push   %eax
f0102188:	68 e8 4c 10 f0       	push   $0xf0104ce8
f010218d:	68 c8 00 00 00       	push   $0xc8
f0102192:	68 d1 54 10 f0       	push   $0xf01054d1
f0102197:	e8 04 df ff ff       	call   f01000a0 <_panic>
f010219c:	83 ec 08             	sub    $0x8,%esp
f010219f:	6a 03                	push   $0x3
f01021a1:	05 00 00 00 10       	add    $0x10000000,%eax
f01021a6:	50                   	push   %eax
f01021a7:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021ac:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021b1:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021b6:	e8 d6 ed ff ff       	call   f0100f91 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_W));
f01021bb:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c0:	83 c4 10             	add    $0x10,%esp
f01021c3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021c8:	77 15                	ja     f01021df <mem_init+0x10e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ca:	50                   	push   %eax
f01021cb:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01021d0:	68 d2 00 00 00       	push   $0xd2
f01021d5:	68 d1 54 10 f0       	push   $0xf01054d1
f01021da:	e8 c1 de ff ff       	call   f01000a0 <_panic>
f01021df:	83 ec 08             	sub    $0x8,%esp
f01021e2:	6a 03                	push   $0x3
f01021e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01021e9:	50                   	push   %eax
f01021ea:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021ef:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021f4:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021f9:	e8 93 ed ff ff       	call   f0100f91 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021fe:	83 c4 10             	add    $0x10,%esp
f0102201:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102206:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010220b:	77 15                	ja     f0102222 <mem_init+0x1124>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010220d:	50                   	push   %eax
f010220e:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102213:	68 df 00 00 00       	push   $0xdf
f0102218:	68 d1 54 10 f0       	push   $0xf01054d1
f010221d:	e8 7e de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102222:	83 ec 08             	sub    $0x8,%esp
f0102225:	6a 02                	push   $0x2
f0102227:	68 00 10 11 00       	push   $0x111000
f010222c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102231:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102236:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010223b:	e8 51 ed ff ff       	call   f0100f91 <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102240:	83 c4 08             	add    $0x8,%esp
f0102243:	6a 02                	push   $0x2
f0102245:	6a 00                	push   $0x0
f0102247:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010224c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102251:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102256:	e8 36 ed ff ff       	call   f0100f91 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010225b:	8b 1d 48 2c 17 f0    	mov    0xf0172c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102261:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0102266:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102269:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102270:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102275:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102278:	8b 3d 4c 2c 17 f0    	mov    0xf0172c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010227e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102281:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102284:	be 00 00 00 00       	mov    $0x0,%esi
f0102289:	eb 55                	jmp    f01022e0 <mem_init+0x11e2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010228b:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102291:	89 d8                	mov    %ebx,%eax
f0102293:	e8 e2 e6 ff ff       	call   f010097a <check_va2pa>
f0102298:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010229f:	77 15                	ja     f01022b6 <mem_init+0x11b8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022a1:	57                   	push   %edi
f01022a2:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01022a7:	68 23 03 00 00       	push   $0x323
f01022ac:	68 d1 54 10 f0       	push   $0xf01054d1
f01022b1:	e8 ea dd ff ff       	call   f01000a0 <_panic>
f01022b6:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022bd:	39 d0                	cmp    %edx,%eax
f01022bf:	74 19                	je     f01022da <mem_init+0x11dc>
f01022c1:	68 00 53 10 f0       	push   $0xf0105300
f01022c6:	68 f7 54 10 f0       	push   $0xf01054f7
f01022cb:	68 23 03 00 00       	push   $0x323
f01022d0:	68 d1 54 10 f0       	push   $0xf01054d1
f01022d5:	e8 c6 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022da:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022e0:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022e3:	77 a6                	ja     f010228b <mem_init+0x118d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022e5:	8b 3d 88 1f 17 f0    	mov    0xf0171f88,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022eb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022ee:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022f3:	89 f2                	mov    %esi,%edx
f01022f5:	89 d8                	mov    %ebx,%eax
f01022f7:	e8 7e e6 ff ff       	call   f010097a <check_va2pa>
f01022fc:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102303:	77 15                	ja     f010231a <mem_init+0x121c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102305:	57                   	push   %edi
f0102306:	68 e8 4c 10 f0       	push   $0xf0104ce8
f010230b:	68 28 03 00 00       	push   $0x328
f0102310:	68 d1 54 10 f0       	push   $0xf01054d1
f0102315:	e8 86 dd ff ff       	call   f01000a0 <_panic>
f010231a:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102321:	39 c2                	cmp    %eax,%edx
f0102323:	74 19                	je     f010233e <mem_init+0x1240>
f0102325:	68 34 53 10 f0       	push   $0xf0105334
f010232a:	68 f7 54 10 f0       	push   $0xf01054f7
f010232f:	68 28 03 00 00       	push   $0x328
f0102334:	68 d1 54 10 f0       	push   $0xf01054d1
f0102339:	e8 62 dd ff ff       	call   f01000a0 <_panic>
f010233e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102344:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010234a:	75 a7                	jne    f01022f3 <mem_init+0x11f5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010234c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010234f:	c1 e7 0c             	shl    $0xc,%edi
f0102352:	be 00 00 00 00       	mov    $0x0,%esi
f0102357:	eb 30                	jmp    f0102389 <mem_init+0x128b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102359:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010235f:	89 d8                	mov    %ebx,%eax
f0102361:	e8 14 e6 ff ff       	call   f010097a <check_va2pa>
f0102366:	39 c6                	cmp    %eax,%esi
f0102368:	74 19                	je     f0102383 <mem_init+0x1285>
f010236a:	68 68 53 10 f0       	push   $0xf0105368
f010236f:	68 f7 54 10 f0       	push   $0xf01054f7
f0102374:	68 2c 03 00 00       	push   $0x32c
f0102379:	68 d1 54 10 f0       	push   $0xf01054d1
f010237e:	e8 1d dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102383:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102389:	39 fe                	cmp    %edi,%esi
f010238b:	72 cc                	jb     f0102359 <mem_init+0x125b>
f010238d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102392:	89 f2                	mov    %esi,%edx
f0102394:	89 d8                	mov    %ebx,%eax
f0102396:	e8 df e5 ff ff       	call   f010097a <check_va2pa>
f010239b:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01023a1:	39 c2                	cmp    %eax,%edx
f01023a3:	74 19                	je     f01023be <mem_init+0x12c0>
f01023a5:	68 90 53 10 f0       	push   $0xf0105390
f01023aa:	68 f7 54 10 f0       	push   $0xf01054f7
f01023af:	68 30 03 00 00       	push   $0x330
f01023b4:	68 d1 54 10 f0       	push   $0xf01054d1
f01023b9:	e8 e2 dc ff ff       	call   f01000a0 <_panic>
f01023be:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023c4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023ca:	75 c6                	jne    f0102392 <mem_init+0x1294>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023cc:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023d1:	89 d8                	mov    %ebx,%eax
f01023d3:	e8 a2 e5 ff ff       	call   f010097a <check_va2pa>
f01023d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023db:	74 51                	je     f010242e <mem_init+0x1330>
f01023dd:	68 d8 53 10 f0       	push   $0xf01053d8
f01023e2:	68 f7 54 10 f0       	push   $0xf01054f7
f01023e7:	68 31 03 00 00       	push   $0x331
f01023ec:	68 d1 54 10 f0       	push   $0xf01054d1
f01023f1:	e8 aa dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023f6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01023fb:	72 36                	jb     f0102433 <mem_init+0x1335>
f01023fd:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102402:	76 07                	jbe    f010240b <mem_init+0x130d>
f0102404:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102409:	75 28                	jne    f0102433 <mem_init+0x1335>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010240b:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010240f:	0f 85 83 00 00 00    	jne    f0102498 <mem_init+0x139a>
f0102415:	68 84 57 10 f0       	push   $0xf0105784
f010241a:	68 f7 54 10 f0       	push   $0xf01054f7
f010241f:	68 3a 03 00 00       	push   $0x33a
f0102424:	68 d1 54 10 f0       	push   $0xf01054d1
f0102429:	e8 72 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010242e:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102433:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102438:	76 3f                	jbe    f0102479 <mem_init+0x137b>
				assert(pgdir[i] & PTE_P);
f010243a:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010243d:	f6 c2 01             	test   $0x1,%dl
f0102440:	75 19                	jne    f010245b <mem_init+0x135d>
f0102442:	68 84 57 10 f0       	push   $0xf0105784
f0102447:	68 f7 54 10 f0       	push   $0xf01054f7
f010244c:	68 3e 03 00 00       	push   $0x33e
f0102451:	68 d1 54 10 f0       	push   $0xf01054d1
f0102456:	e8 45 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010245b:	f6 c2 02             	test   $0x2,%dl
f010245e:	75 38                	jne    f0102498 <mem_init+0x139a>
f0102460:	68 95 57 10 f0       	push   $0xf0105795
f0102465:	68 f7 54 10 f0       	push   $0xf01054f7
f010246a:	68 3f 03 00 00       	push   $0x33f
f010246f:	68 d1 54 10 f0       	push   $0xf01054d1
f0102474:	e8 27 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102479:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010247d:	74 19                	je     f0102498 <mem_init+0x139a>
f010247f:	68 a6 57 10 f0       	push   $0xf01057a6
f0102484:	68 f7 54 10 f0       	push   $0xf01054f7
f0102489:	68 41 03 00 00       	push   $0x341
f010248e:	68 d1 54 10 f0       	push   $0xf01054d1
f0102493:	e8 08 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102498:	83 c0 01             	add    $0x1,%eax
f010249b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024a0:	0f 86 50 ff ff ff    	jbe    f01023f6 <mem_init+0x12f8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024a6:	83 ec 0c             	sub    $0xc,%esp
f01024a9:	68 08 54 10 f0       	push   $0xf0105408
f01024ae:	e8 69 0a 00 00       	call   f0102f1c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024b3:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024b8:	83 c4 10             	add    $0x10,%esp
f01024bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024c0:	77 15                	ja     f01024d7 <mem_init+0x13d9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024c2:	50                   	push   %eax
f01024c3:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01024c8:	68 f3 00 00 00       	push   $0xf3
f01024cd:	68 d1 54 10 f0       	push   $0xf01054d1
f01024d2:	e8 c9 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01024d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01024dc:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024df:	b8 00 00 00 00       	mov    $0x0,%eax
f01024e4:	e8 76 e5 ff ff       	call   f0100a5f <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01024e9:	0f 20 c0             	mov    %cr0,%eax
f01024ec:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01024ef:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024f4:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024f7:	83 ec 0c             	sub    $0xc,%esp
f01024fa:	6a 00                	push   $0x0
f01024fc:	e8 ec e8 ff ff       	call   f0100ded <page_alloc>
f0102501:	89 c7                	mov    %eax,%edi
f0102503:	83 c4 10             	add    $0x10,%esp
f0102506:	85 c0                	test   %eax,%eax
f0102508:	75 19                	jne    f0102523 <mem_init+0x1425>
f010250a:	68 a2 55 10 f0       	push   $0xf01055a2
f010250f:	68 f7 54 10 f0       	push   $0xf01054f7
f0102514:	68 01 04 00 00       	push   $0x401
f0102519:	68 d1 54 10 f0       	push   $0xf01054d1
f010251e:	e8 7d db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102523:	83 ec 0c             	sub    $0xc,%esp
f0102526:	6a 00                	push   $0x0
f0102528:	e8 c0 e8 ff ff       	call   f0100ded <page_alloc>
f010252d:	89 c6                	mov    %eax,%esi
f010252f:	83 c4 10             	add    $0x10,%esp
f0102532:	85 c0                	test   %eax,%eax
f0102534:	75 19                	jne    f010254f <mem_init+0x1451>
f0102536:	68 b8 55 10 f0       	push   $0xf01055b8
f010253b:	68 f7 54 10 f0       	push   $0xf01054f7
f0102540:	68 02 04 00 00       	push   $0x402
f0102545:	68 d1 54 10 f0       	push   $0xf01054d1
f010254a:	e8 51 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010254f:	83 ec 0c             	sub    $0xc,%esp
f0102552:	6a 00                	push   $0x0
f0102554:	e8 94 e8 ff ff       	call   f0100ded <page_alloc>
f0102559:	89 c3                	mov    %eax,%ebx
f010255b:	83 c4 10             	add    $0x10,%esp
f010255e:	85 c0                	test   %eax,%eax
f0102560:	75 19                	jne    f010257b <mem_init+0x147d>
f0102562:	68 ce 55 10 f0       	push   $0xf01055ce
f0102567:	68 f7 54 10 f0       	push   $0xf01054f7
f010256c:	68 03 04 00 00       	push   $0x403
f0102571:	68 d1 54 10 f0       	push   $0xf01054d1
f0102576:	e8 25 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010257b:	83 ec 0c             	sub    $0xc,%esp
f010257e:	57                   	push   %edi
f010257f:	e8 d9 e8 ff ff       	call   f0100e5d <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102584:	89 f0                	mov    %esi,%eax
f0102586:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010258c:	c1 f8 03             	sar    $0x3,%eax
f010258f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102592:	89 c2                	mov    %eax,%edx
f0102594:	c1 ea 0c             	shr    $0xc,%edx
f0102597:	83 c4 10             	add    $0x10,%esp
f010259a:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01025a0:	72 12                	jb     f01025b4 <mem_init+0x14b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025a2:	50                   	push   %eax
f01025a3:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01025a8:	6a 56                	push   $0x56
f01025aa:	68 dd 54 10 f0       	push   $0xf01054dd
f01025af:	e8 ec da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025b4:	83 ec 04             	sub    $0x4,%esp
f01025b7:	68 00 10 00 00       	push   $0x1000
f01025bc:	6a 01                	push   $0x1
f01025be:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025c3:	50                   	push   %eax
f01025c4:	e8 2d 1d 00 00       	call   f01042f6 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025c9:	89 d8                	mov    %ebx,%eax
f01025cb:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01025d1:	c1 f8 03             	sar    $0x3,%eax
f01025d4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025d7:	89 c2                	mov    %eax,%edx
f01025d9:	c1 ea 0c             	shr    $0xc,%edx
f01025dc:	83 c4 10             	add    $0x10,%esp
f01025df:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01025e5:	72 12                	jb     f01025f9 <mem_init+0x14fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025e7:	50                   	push   %eax
f01025e8:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01025ed:	6a 56                	push   $0x56
f01025ef:	68 dd 54 10 f0       	push   $0xf01054dd
f01025f4:	e8 a7 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025f9:	83 ec 04             	sub    $0x4,%esp
f01025fc:	68 00 10 00 00       	push   $0x1000
f0102601:	6a 02                	push   $0x2
f0102603:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102608:	50                   	push   %eax
f0102609:	e8 e8 1c 00 00       	call   f01042f6 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010260e:	6a 02                	push   $0x2
f0102610:	68 00 10 00 00       	push   $0x1000
f0102615:	56                   	push   %esi
f0102616:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010261c:	e8 74 ea ff ff       	call   f0101095 <page_insert>
	assert(pp1->pp_ref == 1);
f0102621:	83 c4 20             	add    $0x20,%esp
f0102624:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102629:	74 19                	je     f0102644 <mem_init+0x1546>
f010262b:	68 9f 56 10 f0       	push   $0xf010569f
f0102630:	68 f7 54 10 f0       	push   $0xf01054f7
f0102635:	68 08 04 00 00       	push   $0x408
f010263a:	68 d1 54 10 f0       	push   $0xf01054d1
f010263f:	e8 5c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102644:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010264b:	01 01 01 
f010264e:	74 19                	je     f0102669 <mem_init+0x156b>
f0102650:	68 28 54 10 f0       	push   $0xf0105428
f0102655:	68 f7 54 10 f0       	push   $0xf01054f7
f010265a:	68 09 04 00 00       	push   $0x409
f010265f:	68 d1 54 10 f0       	push   $0xf01054d1
f0102664:	e8 37 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102669:	6a 02                	push   $0x2
f010266b:	68 00 10 00 00       	push   $0x1000
f0102670:	53                   	push   %ebx
f0102671:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102677:	e8 19 ea ff ff       	call   f0101095 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010267c:	83 c4 10             	add    $0x10,%esp
f010267f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102686:	02 02 02 
f0102689:	74 19                	je     f01026a4 <mem_init+0x15a6>
f010268b:	68 4c 54 10 f0       	push   $0xf010544c
f0102690:	68 f7 54 10 f0       	push   $0xf01054f7
f0102695:	68 0b 04 00 00       	push   $0x40b
f010269a:	68 d1 54 10 f0       	push   $0xf01054d1
f010269f:	e8 fc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026a4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026a9:	74 19                	je     f01026c4 <mem_init+0x15c6>
f01026ab:	68 c1 56 10 f0       	push   $0xf01056c1
f01026b0:	68 f7 54 10 f0       	push   $0xf01054f7
f01026b5:	68 0c 04 00 00       	push   $0x40c
f01026ba:	68 d1 54 10 f0       	push   $0xf01054d1
f01026bf:	e8 dc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026c4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026c9:	74 19                	je     f01026e4 <mem_init+0x15e6>
f01026cb:	68 2b 57 10 f0       	push   $0xf010572b
f01026d0:	68 f7 54 10 f0       	push   $0xf01054f7
f01026d5:	68 0d 04 00 00       	push   $0x40d
f01026da:	68 d1 54 10 f0       	push   $0xf01054d1
f01026df:	e8 bc d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026e4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026eb:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026ee:	89 d8                	mov    %ebx,%eax
f01026f0:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01026f6:	c1 f8 03             	sar    $0x3,%eax
f01026f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026fc:	89 c2                	mov    %eax,%edx
f01026fe:	c1 ea 0c             	shr    $0xc,%edx
f0102701:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102707:	72 12                	jb     f010271b <mem_init+0x161d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102709:	50                   	push   %eax
f010270a:	68 c4 4c 10 f0       	push   $0xf0104cc4
f010270f:	6a 56                	push   $0x56
f0102711:	68 dd 54 10 f0       	push   $0xf01054dd
f0102716:	e8 85 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010271b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102722:	03 03 03 
f0102725:	74 19                	je     f0102740 <mem_init+0x1642>
f0102727:	68 70 54 10 f0       	push   $0xf0105470
f010272c:	68 f7 54 10 f0       	push   $0xf01054f7
f0102731:	68 0f 04 00 00       	push   $0x40f
f0102736:	68 d1 54 10 f0       	push   $0xf01054d1
f010273b:	e8 60 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102740:	83 ec 08             	sub    $0x8,%esp
f0102743:	68 00 10 00 00       	push   $0x1000
f0102748:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010274e:	e8 f8 e8 ff ff       	call   f010104b <page_remove>
	assert(pp2->pp_ref == 0);
f0102753:	83 c4 10             	add    $0x10,%esp
f0102756:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010275b:	74 19                	je     f0102776 <mem_init+0x1678>
f010275d:	68 f9 56 10 f0       	push   $0xf01056f9
f0102762:	68 f7 54 10 f0       	push   $0xf01054f7
f0102767:	68 11 04 00 00       	push   $0x411
f010276c:	68 d1 54 10 f0       	push   $0xf01054d1
f0102771:	e8 2a d9 ff ff       	call   f01000a0 <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102776:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102779:	5b                   	pop    %ebx
f010277a:	5e                   	pop    %esi
f010277b:	5f                   	pop    %edi
f010277c:	5d                   	pop    %ebp
f010277d:	c3                   	ret    

f010277e <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010277e:	55                   	push   %ebp
f010277f:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102781:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102784:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102787:	5d                   	pop    %ebp
f0102788:	c3                   	ret    

f0102789 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102789:	55                   	push   %ebp
f010278a:	89 e5                	mov    %esp,%ebp
f010278c:	57                   	push   %edi
f010278d:	56                   	push   %esi
f010278e:	53                   	push   %ebx
f010278f:	83 ec 1c             	sub    $0x1c,%esp
f0102792:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102795:	8b 7d 14             	mov    0x14(%ebp),%edi
	// LAB 3: Your code here.
	uint32_t round_begin = (uint32_t) ROUNDDOWN(va, PGSIZE);
	uint32_t round_end = (uint32_t) ROUNDUP(va + len, PGSIZE);
f0102798:	89 f0                	mov    %esi,%eax
f010279a:	03 45 10             	add    0x10(%ebp),%eax
f010279d:	05 ff 0f 00 00       	add    $0xfff,%eax
f01027a2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	int i = round_begin;
f01027aa:	89 f3                	mov    %esi,%ebx
f01027ac:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	for( ; i < round_end; i += PGSIZE)
f01027b2:	eb 3b                	jmp    f01027ef <user_mem_check+0x66>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, va, 0);
f01027b4:	83 ec 04             	sub    $0x4,%esp
f01027b7:	6a 00                	push   $0x0
f01027b9:	56                   	push   %esi
f01027ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01027bd:	ff 70 5c             	pushl  0x5c(%eax)
f01027c0:	e8 fa e6 ff ff       	call   f0100ebf <pgdir_walk>
		
		if ((va >= (void*) ULIM) || !pte || ((*pte & perm) != perm))
f01027c5:	83 c4 10             	add    $0x10,%esp
f01027c8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01027ce:	77 0c                	ja     f01027dc <user_mem_check+0x53>
f01027d0:	85 c0                	test   %eax,%eax
f01027d2:	74 08                	je     f01027dc <user_mem_check+0x53>
f01027d4:	89 fa                	mov    %edi,%edx
f01027d6:	23 10                	and    (%eax),%edx
f01027d8:	39 d7                	cmp    %edx,%edi
f01027da:	74 0d                	je     f01027e9 <user_mem_check+0x60>
		{
			user_mem_check_addr = (uint32_t)va;
f01027dc:	89 35 7c 1f 17 f0    	mov    %esi,0xf0171f7c
			return -E_FAULT;
f01027e2:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027e7:	eb 10                	jmp    f01027f9 <user_mem_check+0x70>
	// LAB 3: Your code here.
	uint32_t round_begin = (uint32_t) ROUNDDOWN(va, PGSIZE);
	uint32_t round_end = (uint32_t) ROUNDUP(va + len, PGSIZE);

	int i = round_begin;
	for( ; i < round_end; i += PGSIZE)
f01027e9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027ef:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01027f2:	77 c0                	ja     f01027b4 <user_mem_check+0x2b>
			return -E_FAULT;
		}
	}


	return 0;
f01027f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027fc:	5b                   	pop    %ebx
f01027fd:	5e                   	pop    %esi
f01027fe:	5f                   	pop    %edi
f01027ff:	5d                   	pop    %ebp
f0102800:	c3                   	ret    

f0102801 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102801:	55                   	push   %ebp
f0102802:	89 e5                	mov    %esp,%ebp
f0102804:	53                   	push   %ebx
f0102805:	83 ec 04             	sub    $0x4,%esp
f0102808:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010280b:	8b 45 14             	mov    0x14(%ebp),%eax
f010280e:	83 c8 04             	or     $0x4,%eax
f0102811:	50                   	push   %eax
f0102812:	ff 75 10             	pushl  0x10(%ebp)
f0102815:	ff 75 0c             	pushl  0xc(%ebp)
f0102818:	53                   	push   %ebx
f0102819:	e8 6b ff ff ff       	call   f0102789 <user_mem_check>
f010281e:	83 c4 10             	add    $0x10,%esp
f0102821:	85 c0                	test   %eax,%eax
f0102823:	79 21                	jns    f0102846 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102825:	83 ec 04             	sub    $0x4,%esp
f0102828:	ff 35 7c 1f 17 f0    	pushl  0xf0171f7c
f010282e:	ff 73 48             	pushl  0x48(%ebx)
f0102831:	68 9c 54 10 f0       	push   $0xf010549c
f0102836:	e8 e1 06 00 00       	call   f0102f1c <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f010283b:	89 1c 24             	mov    %ebx,(%esp)
f010283e:	e8 c0 05 00 00       	call   f0102e03 <env_destroy>
f0102843:	83 c4 10             	add    $0x10,%esp
	}
}
f0102846:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102849:	c9                   	leave  
f010284a:	c3                   	ret    

f010284b <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010284b:	55                   	push   %ebp
f010284c:	89 e5                	mov    %esp,%ebp
f010284e:	57                   	push   %edi
f010284f:	56                   	push   %esi
f0102850:	53                   	push   %ebx
f0102851:	83 ec 0c             	sub    $0xc,%esp
f0102854:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
f0102856:	89 d3                	mov    %edx,%ebx
f0102858:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);
f010285e:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102865:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; round_begin < round_end; round_begin += PGSIZE)
f010286b:	eb 3d                	jmp    f01028aa <region_alloc+0x5f>
	{
		page = page_alloc(0);
f010286d:	83 ec 0c             	sub    $0xc,%esp
f0102870:	6a 00                	push   $0x0
f0102872:	e8 76 e5 ff ff       	call   f0100ded <page_alloc>

		if(!page)
f0102877:	83 c4 10             	add    $0x10,%esp
f010287a:	85 c0                	test   %eax,%eax
f010287c:	75 17                	jne    f0102895 <region_alloc+0x4a>
			panic("region_alloc: page allocation failed!");
f010287e:	83 ec 04             	sub    $0x4,%esp
f0102881:	68 b4 57 10 f0       	push   $0xf01057b4
f0102886:	68 26 01 00 00       	push   $0x126
f010288b:	68 36 58 10 f0       	push   $0xf0105836
f0102890:	e8 0b d8 ff ff       	call   f01000a0 <_panic>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
f0102895:	6a 06                	push   $0x6
f0102897:	53                   	push   %ebx
f0102898:	50                   	push   %eax
f0102899:	ff 77 5c             	pushl  0x5c(%edi)
f010289c:	e8 f4 e7 ff ff       	call   f0101095 <page_insert>
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);

	for(; round_begin < round_end; round_begin += PGSIZE)
f01028a1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028a7:	83 c4 10             	add    $0x10,%esp
f01028aa:	39 f3                	cmp    %esi,%ebx
f01028ac:	72 bf                	jb     f010286d <region_alloc+0x22>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
	}
	
	
}
f01028ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028b1:	5b                   	pop    %ebx
f01028b2:	5e                   	pop    %esi
f01028b3:	5f                   	pop    %edi
f01028b4:	5d                   	pop    %ebp
f01028b5:	c3                   	ret    

f01028b6 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01028b6:	55                   	push   %ebp
f01028b7:	89 e5                	mov    %esp,%ebp
f01028b9:	8b 55 08             	mov    0x8(%ebp),%edx
f01028bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01028bf:	85 d2                	test   %edx,%edx
f01028c1:	75 11                	jne    f01028d4 <envid2env+0x1e>
		*env_store = curenv;
f01028c3:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f01028c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028cb:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d2:	eb 5e                	jmp    f0102932 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028d4:	89 d0                	mov    %edx,%eax
f01028d6:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028db:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028de:	c1 e0 05             	shl    $0x5,%eax
f01028e1:	03 05 88 1f 17 f0    	add    0xf0171f88,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028e7:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01028eb:	74 05                	je     f01028f2 <envid2env+0x3c>
f01028ed:	3b 50 48             	cmp    0x48(%eax),%edx
f01028f0:	74 10                	je     f0102902 <envid2env+0x4c>
		*env_store = 0;
f01028f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028f5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028fb:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102900:	eb 30                	jmp    f0102932 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102902:	84 c9                	test   %cl,%cl
f0102904:	74 22                	je     f0102928 <envid2env+0x72>
f0102906:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f010290c:	39 d0                	cmp    %edx,%eax
f010290e:	74 18                	je     f0102928 <envid2env+0x72>
f0102910:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102913:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102916:	74 10                	je     f0102928 <envid2env+0x72>
		*env_store = 0;
f0102918:	8b 45 0c             	mov    0xc(%ebp),%eax
f010291b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102921:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102926:	eb 0a                	jmp    f0102932 <envid2env+0x7c>
	}

	*env_store = e;
f0102928:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010292b:	89 01                	mov    %eax,(%ecx)
	return 0;
f010292d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102932:	5d                   	pop    %ebp
f0102933:	c3                   	ret    

f0102934 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102934:	55                   	push   %ebp
f0102935:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102937:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f010293c:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f010293f:	b8 23 00 00 00       	mov    $0x23,%eax
f0102944:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102946:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102948:	b8 10 00 00 00       	mov    $0x10,%eax
f010294d:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f010294f:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102951:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102953:	ea 5a 29 10 f0 08 00 	ljmp   $0x8,$0xf010295a
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f010295a:	b8 00 00 00 00       	mov    $0x0,%eax
f010295f:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102962:	5d                   	pop    %ebp
f0102963:	c3                   	ret    

f0102964 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102964:	55                   	push   %ebp
f0102965:	89 e5                	mov    %esp,%ebp
f0102967:	56                   	push   %esi
f0102968:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
	{
		envs[i].env_id = 0;
f0102969:	8b 35 88 1f 17 f0    	mov    0xf0171f88,%esi
f010296f:	8b 15 8c 1f 17 f0    	mov    0xf0171f8c,%edx
f0102975:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010297b:	8d 5e a0             	lea    -0x60(%esi),%ebx
f010297e:	89 c1                	mov    %eax,%ecx
f0102980:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102987:	89 50 44             	mov    %edx,0x44(%eax)
f010298a:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];	
f010298d:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
f010298f:	39 d8                	cmp    %ebx,%eax
f0102991:	75 eb                	jne    f010297e <env_init+0x1a>
f0102993:	89 35 8c 1f 17 f0    	mov    %esi,0xf0171f8c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];	
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102999:	e8 96 ff ff ff       	call   f0102934 <env_init_percpu>
}
f010299e:	5b                   	pop    %ebx
f010299f:	5e                   	pop    %esi
f01029a0:	5d                   	pop    %ebp
f01029a1:	c3                   	ret    

f01029a2 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029a2:	55                   	push   %ebp
f01029a3:	89 e5                	mov    %esp,%ebp
f01029a5:	53                   	push   %ebx
f01029a6:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029a9:	8b 1d 8c 1f 17 f0    	mov    0xf0171f8c,%ebx
f01029af:	85 db                	test   %ebx,%ebx
f01029b1:	0f 84 4a 01 00 00    	je     f0102b01 <env_alloc+0x15f>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01029b7:	83 ec 0c             	sub    $0xc,%esp
f01029ba:	6a 01                	push   $0x1
f01029bc:	e8 2c e4 ff ff       	call   f0100ded <page_alloc>
f01029c1:	83 c4 10             	add    $0x10,%esp
f01029c4:	85 c0                	test   %eax,%eax
f01029c6:	0f 84 3c 01 00 00    	je     f0102b08 <env_alloc+0x166>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f01029cc:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029d1:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01029d7:	c1 f8 03             	sar    $0x3,%eax
f01029da:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029dd:	89 c2                	mov    %eax,%edx
f01029df:	c1 ea 0c             	shr    $0xc,%edx
f01029e2:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01029e8:	72 12                	jb     f01029fc <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029ea:	50                   	push   %eax
f01029eb:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01029f0:	6a 56                	push   $0x56
f01029f2:	68 dd 54 10 f0       	push   $0xf01054dd
f01029f7:	e8 a4 d6 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = (pde_t*) page2kva(p);
f01029fc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a01:	89 43 5c             	mov    %eax,0x5c(%ebx)
f0102a04:	b8 ec 0e 00 00       	mov    $0xeec,%eax
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102a09:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f0102a0f:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102a12:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102a15:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102a18:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*) page2kva(p);
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
f0102a1b:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102a20:	75 e7                	jne    f0102a09 <env_alloc+0x67>
		e->env_pgdir[i] = kern_pgdir[i];
	}

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102a22:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a25:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a2a:	77 15                	ja     f0102a41 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a2c:	50                   	push   %eax
f0102a2d:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102a32:	68 c7 00 00 00       	push   $0xc7
f0102a37:	68 36 58 10 f0       	push   $0xf0105836
f0102a3c:	e8 5f d6 ff ff       	call   f01000a0 <_panic>
f0102a41:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a47:	83 ca 05             	or     $0x5,%edx
f0102a4a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a50:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a53:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a58:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a5d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a62:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a65:	89 da                	mov    %ebx,%edx
f0102a67:	2b 15 88 1f 17 f0    	sub    0xf0171f88,%edx
f0102a6d:	c1 fa 05             	sar    $0x5,%edx
f0102a70:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a76:	09 d0                	or     %edx,%eax
f0102a78:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a7b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a7e:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a81:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a88:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a8f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a96:	83 ec 04             	sub    $0x4,%esp
f0102a99:	6a 44                	push   $0x44
f0102a9b:	6a 00                	push   $0x0
f0102a9d:	53                   	push   %ebx
f0102a9e:	e8 53 18 00 00       	call   f01042f6 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102aa3:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102aa9:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102aaf:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102ab5:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102abc:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102ac2:	8b 43 44             	mov    0x44(%ebx),%eax
f0102ac5:	a3 8c 1f 17 f0       	mov    %eax,0xf0171f8c
	*newenv_store = e;
f0102aca:	8b 45 08             	mov    0x8(%ebp),%eax
f0102acd:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102acf:	8b 53 48             	mov    0x48(%ebx),%edx
f0102ad2:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0102ad7:	83 c4 10             	add    $0x10,%esp
f0102ada:	85 c0                	test   %eax,%eax
f0102adc:	74 05                	je     f0102ae3 <env_alloc+0x141>
f0102ade:	8b 40 48             	mov    0x48(%eax),%eax
f0102ae1:	eb 05                	jmp    f0102ae8 <env_alloc+0x146>
f0102ae3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ae8:	83 ec 04             	sub    $0x4,%esp
f0102aeb:	52                   	push   %edx
f0102aec:	50                   	push   %eax
f0102aed:	68 41 58 10 f0       	push   $0xf0105841
f0102af2:	e8 25 04 00 00       	call   f0102f1c <cprintf>
	return 0;
f0102af7:	83 c4 10             	add    $0x10,%esp
f0102afa:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aff:	eb 0c                	jmp    f0102b0d <env_alloc+0x16b>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102b01:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102b06:	eb 05                	jmp    f0102b0d <env_alloc+0x16b>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102b08:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102b0d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b10:	c9                   	leave  
f0102b11:	c3                   	ret    

f0102b12 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102b12:	55                   	push   %ebp
f0102b13:	89 e5                	mov    %esp,%ebp
f0102b15:	57                   	push   %edi
f0102b16:	56                   	push   %esi
f0102b17:	53                   	push   %ebx
f0102b18:	83 ec 34             	sub    $0x34,%esp
f0102b1b:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e = NULL;
f0102b1e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uint32_t result = env_alloc(&e, 0);
f0102b25:	6a 00                	push   $0x0
f0102b27:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102b2a:	50                   	push   %eax
f0102b2b:	e8 72 fe ff ff       	call   f01029a2 <env_alloc>

	if(result !=  0)
f0102b30:	83 c4 10             	add    $0x10,%esp
f0102b33:	85 c0                	test   %eax,%eax
f0102b35:	74 15                	je     f0102b4c <env_create+0x3a>
		panic("env_create: %e", result);
f0102b37:	50                   	push   %eax
f0102b38:	68 56 58 10 f0       	push   $0xf0105856
f0102b3d:	68 95 01 00 00       	push   $0x195
f0102b42:	68 36 58 10 f0       	push   $0xf0105836
f0102b47:	e8 54 d5 ff ff       	call   f01000a0 <_panic>

	load_icode(e, binary);
f0102b4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b4f:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph = NULL, *eph = NULL;
	struct Elf *elf = (struct Elf*) binary;
	
	if(elf->e_magic != ELF_MAGIC)
f0102b52:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b58:	74 17                	je     f0102b71 <env_create+0x5f>
		panic("load icode: Elf format not valid!");
f0102b5a:	83 ec 04             	sub    $0x4,%esp
f0102b5d:	68 dc 57 10 f0       	push   $0xf01057dc
f0102b62:	68 68 01 00 00       	push   $0x168
f0102b67:	68 36 58 10 f0       	push   $0xf0105836
f0102b6c:	e8 2f d5 ff ff       	call   f01000a0 <_panic>

	ph = (struct Proghdr*) (binary + elf->e_phoff);
f0102b71:	89 fb                	mov    %edi,%ebx
f0102b73:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0102b76:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b7a:	c1 e6 05             	shl    $0x5,%esi
f0102b7d:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0102b7f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b82:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b85:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b8a:	77 15                	ja     f0102ba1 <env_create+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b8c:	50                   	push   %eax
f0102b8d:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102b92:	68 6d 01 00 00       	push   $0x16d
f0102b97:	68 36 58 10 f0       	push   $0xf0105836
f0102b9c:	e8 ff d4 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ba1:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ba6:	0f 22 d8             	mov    %eax,%cr3
f0102ba9:	eb 44                	jmp    f0102bef <env_create+0xdd>

	for( ; ph < eph; ++ph)
	{
		if(ph->p_type != ELF_PROG_LOAD)
f0102bab:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102bae:	75 3c                	jne    f0102bec <env_create+0xda>
			continue;		

		region_alloc(e, (void*) ph->p_va, ph->p_memsz);
f0102bb0:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102bb3:	8b 53 08             	mov    0x8(%ebx),%edx
f0102bb6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bb9:	e8 8d fc ff ff       	call   f010284b <region_alloc>
		
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102bbe:	83 ec 04             	sub    $0x4,%esp
f0102bc1:	ff 73 10             	pushl  0x10(%ebx)
f0102bc4:	89 f8                	mov    %edi,%eax
f0102bc6:	03 43 04             	add    0x4(%ebx),%eax
f0102bc9:	50                   	push   %eax
f0102bca:	ff 73 08             	pushl  0x8(%ebx)
f0102bcd:	e8 d9 17 00 00       	call   f01043ab <memcpy>
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
f0102bd2:	8b 43 10             	mov    0x10(%ebx),%eax
f0102bd5:	83 c4 0c             	add    $0xc,%esp
f0102bd8:	8b 53 14             	mov    0x14(%ebx),%edx
f0102bdb:	29 c2                	sub    %eax,%edx
f0102bdd:	52                   	push   %edx
f0102bde:	6a 00                	push   $0x0
f0102be0:	03 43 08             	add    0x8(%ebx),%eax
f0102be3:	50                   	push   %eax
f0102be4:	e8 0d 17 00 00       	call   f01042f6 <memset>
f0102be9:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr*) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	for( ; ph < eph; ++ph)
f0102bec:	83 c3 20             	add    $0x20,%ebx
f0102bef:	39 de                	cmp    %ebx,%esi
f0102bf1:	77 b8                	ja     f0102bab <env_create+0x99>
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
	}

	e->env_tf.tf_eip = elf->e_entry;
f0102bf3:	8b 47 18             	mov    0x18(%edi),%eax
f0102bf6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102bf9:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*) USTACKTOP - PGSIZE, PGSIZE);
f0102bfc:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102c01:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102c06:	89 f8                	mov    %edi,%eax
f0102c08:	e8 3e fc ff ff       	call   f010284b <region_alloc>

	lcr3(PADDR(kern_pgdir));
f0102c0d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c12:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c17:	77 15                	ja     f0102c2e <env_create+0x11c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c19:	50                   	push   %eax
f0102c1a:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102c1f:	68 83 01 00 00       	push   $0x183
f0102c24:	68 36 58 10 f0       	push   $0xf0105836
f0102c29:	e8 72 d4 ff ff       	call   f01000a0 <_panic>
f0102c2e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c33:	0f 22 d8             	mov    %eax,%cr3

	if(result !=  0)
		panic("env_create: %e", result);

	load_icode(e, binary);
	e->env_type = type;
f0102c36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c39:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c3c:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c3f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c42:	5b                   	pop    %ebx
f0102c43:	5e                   	pop    %esi
f0102c44:	5f                   	pop    %edi
f0102c45:	5d                   	pop    %ebp
f0102c46:	c3                   	ret    

f0102c47 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c47:	55                   	push   %ebp
f0102c48:	89 e5                	mov    %esp,%ebp
f0102c4a:	57                   	push   %edi
f0102c4b:	56                   	push   %esi
f0102c4c:	53                   	push   %ebx
f0102c4d:	83 ec 1c             	sub    $0x1c,%esp
f0102c50:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c53:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102c59:	39 fa                	cmp    %edi,%edx
f0102c5b:	75 29                	jne    f0102c86 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c5d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c62:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c67:	77 15                	ja     f0102c7e <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c69:	50                   	push   %eax
f0102c6a:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102c6f:	68 a9 01 00 00       	push   $0x1a9
f0102c74:	68 36 58 10 f0       	push   $0xf0105836
f0102c79:	e8 22 d4 ff ff       	call   f01000a0 <_panic>
f0102c7e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c83:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c86:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c89:	85 d2                	test   %edx,%edx
f0102c8b:	74 05                	je     f0102c92 <env_free+0x4b>
f0102c8d:	8b 42 48             	mov    0x48(%edx),%eax
f0102c90:	eb 05                	jmp    f0102c97 <env_free+0x50>
f0102c92:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c97:	83 ec 04             	sub    $0x4,%esp
f0102c9a:	51                   	push   %ecx
f0102c9b:	50                   	push   %eax
f0102c9c:	68 65 58 10 f0       	push   $0xf0105865
f0102ca1:	e8 76 02 00 00       	call   f0102f1c <cprintf>
f0102ca6:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ca9:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102cb0:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102cb3:	89 d0                	mov    %edx,%eax
f0102cb5:	c1 e0 02             	shl    $0x2,%eax
f0102cb8:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102cbb:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cbe:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102cc1:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102cc7:	0f 84 a8 00 00 00    	je     f0102d75 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102ccd:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cd3:	89 f0                	mov    %esi,%eax
f0102cd5:	c1 e8 0c             	shr    $0xc,%eax
f0102cd8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cdb:	39 05 44 2c 17 f0    	cmp    %eax,0xf0172c44
f0102ce1:	77 15                	ja     f0102cf8 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ce3:	56                   	push   %esi
f0102ce4:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102ce9:	68 b8 01 00 00       	push   $0x1b8
f0102cee:	68 36 58 10 f0       	push   $0xf0105836
f0102cf3:	e8 a8 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cf8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cfb:	c1 e0 16             	shl    $0x16,%eax
f0102cfe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d01:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102d06:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102d0d:	01 
f0102d0e:	74 17                	je     f0102d27 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d10:	83 ec 08             	sub    $0x8,%esp
f0102d13:	89 d8                	mov    %ebx,%eax
f0102d15:	c1 e0 0c             	shl    $0xc,%eax
f0102d18:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102d1b:	50                   	push   %eax
f0102d1c:	ff 77 5c             	pushl  0x5c(%edi)
f0102d1f:	e8 27 e3 ff ff       	call   f010104b <page_remove>
f0102d24:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d27:	83 c3 01             	add    $0x1,%ebx
f0102d2a:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d30:	75 d4                	jne    f0102d06 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d32:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d35:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d38:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d3f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d42:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102d48:	72 14                	jb     f0102d5e <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102d4a:	83 ec 04             	sub    $0x4,%esp
f0102d4d:	68 4c 4e 10 f0       	push   $0xf0104e4c
f0102d52:	6a 4f                	push   $0x4f
f0102d54:	68 dd 54 10 f0       	push   $0xf01054dd
f0102d59:	e8 42 d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d5e:	83 ec 0c             	sub    $0xc,%esp
f0102d61:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0102d66:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d69:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d6c:	50                   	push   %eax
f0102d6d:	e8 26 e1 ff ff       	call   f0100e98 <page_decref>
f0102d72:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d75:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d79:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d7c:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d81:	0f 85 29 ff ff ff    	jne    f0102cb0 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d87:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d8a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d8f:	77 15                	ja     f0102da6 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d91:	50                   	push   %eax
f0102d92:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102d97:	68 c6 01 00 00       	push   $0x1c6
f0102d9c:	68 36 58 10 f0       	push   $0xf0105836
f0102da1:	e8 fa d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102da6:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dad:	05 00 00 00 10       	add    $0x10000000,%eax
f0102db2:	c1 e8 0c             	shr    $0xc,%eax
f0102db5:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102dbb:	72 14                	jb     f0102dd1 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102dbd:	83 ec 04             	sub    $0x4,%esp
f0102dc0:	68 4c 4e 10 f0       	push   $0xf0104e4c
f0102dc5:	6a 4f                	push   $0x4f
f0102dc7:	68 dd 54 10 f0       	push   $0xf01054dd
f0102dcc:	e8 cf d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102dd1:	83 ec 0c             	sub    $0xc,%esp
f0102dd4:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0102dda:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102ddd:	50                   	push   %eax
f0102dde:	e8 b5 e0 ff ff       	call   f0100e98 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102de3:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102dea:	a1 8c 1f 17 f0       	mov    0xf0171f8c,%eax
f0102def:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102df2:	89 3d 8c 1f 17 f0    	mov    %edi,0xf0171f8c
}
f0102df8:	83 c4 10             	add    $0x10,%esp
f0102dfb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dfe:	5b                   	pop    %ebx
f0102dff:	5e                   	pop    %esi
f0102e00:	5f                   	pop    %edi
f0102e01:	5d                   	pop    %ebp
f0102e02:	c3                   	ret    

f0102e03 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e03:	55                   	push   %ebp
f0102e04:	89 e5                	mov    %esp,%ebp
f0102e06:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e09:	ff 75 08             	pushl  0x8(%ebp)
f0102e0c:	e8 36 fe ff ff       	call   f0102c47 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e11:	c7 04 24 00 58 10 f0 	movl   $0xf0105800,(%esp)
f0102e18:	e8 ff 00 00 00       	call   f0102f1c <cprintf>
f0102e1d:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e20:	83 ec 0c             	sub    $0xc,%esp
f0102e23:	6a 00                	push   $0x0
f0102e25:	e8 df d9 ff ff       	call   f0100809 <monitor>
f0102e2a:	83 c4 10             	add    $0x10,%esp
f0102e2d:	eb f1                	jmp    f0102e20 <env_destroy+0x1d>

f0102e2f <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e2f:	55                   	push   %ebp
f0102e30:	89 e5                	mov    %esp,%ebp
f0102e32:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102e35:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e38:	61                   	popa   
f0102e39:	07                   	pop    %es
f0102e3a:	1f                   	pop    %ds
f0102e3b:	83 c4 08             	add    $0x8,%esp
f0102e3e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e3f:	68 7b 58 10 f0       	push   $0xf010587b
f0102e44:	68 ef 01 00 00       	push   $0x1ef
f0102e49:	68 36 58 10 f0       	push   $0xf0105836
f0102e4e:	e8 4d d2 ff ff       	call   f01000a0 <_panic>

f0102e53 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e53:	55                   	push   %ebp
f0102e54:	89 e5                	mov    %esp,%ebp
f0102e56:	83 ec 08             	sub    $0x8,%esp
f0102e59:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && (curenv->env_status == ENV_RUNNING))
f0102e5c:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102e62:	85 d2                	test   %edx,%edx
f0102e64:	74 0d                	je     f0102e73 <env_run+0x20>
f0102e66:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e6a:	75 07                	jne    f0102e73 <env_run+0x20>
	{
		curenv->env_status = ENV_RUNNABLE;
f0102e6c:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}

	curenv = e;
f0102e73:	a3 84 1f 17 f0       	mov    %eax,0xf0171f84
	e->env_status = ENV_RUNNING;
f0102e78:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102e7f:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0102e83:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e86:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e8c:	77 15                	ja     f0102ea3 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e8e:	52                   	push   %edx
f0102e8f:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102e94:	68 15 02 00 00       	push   $0x215
f0102e99:	68 36 58 10 f0       	push   $0xf0105836
f0102e9e:	e8 fd d1 ff ff       	call   f01000a0 <_panic>
f0102ea3:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102ea9:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&e->env_tf);
f0102eac:	83 ec 0c             	sub    $0xc,%esp
f0102eaf:	50                   	push   %eax
f0102eb0:	e8 7a ff ff ff       	call   f0102e2f <env_pop_tf>

f0102eb5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102eb5:	55                   	push   %ebp
f0102eb6:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102eb8:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ebd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ec0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ec1:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ec6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ec7:	0f b6 c0             	movzbl %al,%eax
}
f0102eca:	5d                   	pop    %ebp
f0102ecb:	c3                   	ret    

f0102ecc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ecc:	55                   	push   %ebp
f0102ecd:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ecf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ed4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ed7:	ee                   	out    %al,(%dx)
f0102ed8:	ba 71 00 00 00       	mov    $0x71,%edx
f0102edd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ee0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ee1:	5d                   	pop    %ebp
f0102ee2:	c3                   	ret    

f0102ee3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ee3:	55                   	push   %ebp
f0102ee4:	89 e5                	mov    %esp,%ebp
f0102ee6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102ee9:	ff 75 08             	pushl  0x8(%ebp)
f0102eec:	e8 24 d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102ef1:	83 c4 10             	add    $0x10,%esp
f0102ef4:	c9                   	leave  
f0102ef5:	c3                   	ret    

f0102ef6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ef6:	55                   	push   %ebp
f0102ef7:	89 e5                	mov    %esp,%ebp
f0102ef9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102efc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f03:	ff 75 0c             	pushl  0xc(%ebp)
f0102f06:	ff 75 08             	pushl  0x8(%ebp)
f0102f09:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f0c:	50                   	push   %eax
f0102f0d:	68 e3 2e 10 f0       	push   $0xf0102ee3
f0102f12:	e8 73 0d 00 00       	call   f0103c8a <vprintfmt>
	return cnt;
}
f0102f17:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f1a:	c9                   	leave  
f0102f1b:	c3                   	ret    

f0102f1c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f1c:	55                   	push   %ebp
f0102f1d:	89 e5                	mov    %esp,%ebp
f0102f1f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f22:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f25:	50                   	push   %eax
f0102f26:	ff 75 08             	pushl  0x8(%ebp)
f0102f29:	e8 c8 ff ff ff       	call   f0102ef6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f2e:	c9                   	leave  
f0102f2f:	c3                   	ret    

f0102f30 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f30:	55                   	push   %ebp
f0102f31:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f33:	b8 c0 27 17 f0       	mov    $0xf01727c0,%eax
f0102f38:	c7 05 c4 27 17 f0 00 	movl   $0xf0000000,0xf01727c4
f0102f3f:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f42:	66 c7 05 c8 27 17 f0 	movw   $0x10,0xf01727c8
f0102f49:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f4b:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102f52:	67 00 
f0102f54:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0102f5a:	89 c2                	mov    %eax,%edx
f0102f5c:	c1 ea 10             	shr    $0x10,%edx
f0102f5f:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0102f65:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0102f6c:	c1 e8 18             	shr    $0x18,%eax
f0102f6f:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f74:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f7b:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f80:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f83:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0102f88:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f8b:	5d                   	pop    %ebp
f0102f8c:	c3                   	ret    

f0102f8d <trap_init>:
}


void
trap_init(void)
{
f0102f8d:	55                   	push   %ebp
f0102f8e:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0102f90:	b8 62 36 10 f0       	mov    $0xf0103662,%eax
f0102f95:	66 a3 a0 1f 17 f0    	mov    %ax,0xf0171fa0
f0102f9b:	66 c7 05 a2 1f 17 f0 	movw   $0x8,0xf0171fa2
f0102fa2:	08 00 
f0102fa4:	c6 05 a4 1f 17 f0 00 	movb   $0x0,0xf0171fa4
f0102fab:	c6 05 a5 1f 17 f0 8e 	movb   $0x8e,0xf0171fa5
f0102fb2:	c1 e8 10             	shr    $0x10,%eax
f0102fb5:	66 a3 a6 1f 17 f0    	mov    %ax,0xf0171fa6
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f0102fbb:	b8 68 36 10 f0       	mov    $0xf0103668,%eax
f0102fc0:	66 a3 a8 1f 17 f0    	mov    %ax,0xf0171fa8
f0102fc6:	66 c7 05 aa 1f 17 f0 	movw   $0x8,0xf0171faa
f0102fcd:	08 00 
f0102fcf:	c6 05 ac 1f 17 f0 00 	movb   $0x0,0xf0171fac
f0102fd6:	c6 05 ad 1f 17 f0 8e 	movb   $0x8e,0xf0171fad
f0102fdd:	c1 e8 10             	shr    $0x10,%eax
f0102fe0:	66 a3 ae 1f 17 f0    	mov    %ax,0xf0171fae
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f0102fe6:	b8 6e 36 10 f0       	mov    $0xf010366e,%eax
f0102feb:	66 a3 b0 1f 17 f0    	mov    %ax,0xf0171fb0
f0102ff1:	66 c7 05 b2 1f 17 f0 	movw   $0x8,0xf0171fb2
f0102ff8:	08 00 
f0102ffa:	c6 05 b4 1f 17 f0 00 	movb   $0x0,0xf0171fb4
f0103001:	c6 05 b5 1f 17 f0 8e 	movb   $0x8e,0xf0171fb5
f0103008:	c1 e8 10             	shr    $0x10,%eax
f010300b:	66 a3 b6 1f 17 f0    	mov    %ax,0xf0171fb6
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f0103011:	b8 74 36 10 f0       	mov    $0xf0103674,%eax
f0103016:	66 a3 b8 1f 17 f0    	mov    %ax,0xf0171fb8
f010301c:	66 c7 05 ba 1f 17 f0 	movw   $0x8,0xf0171fba
f0103023:	08 00 
f0103025:	c6 05 bc 1f 17 f0 00 	movb   $0x0,0xf0171fbc
f010302c:	c6 05 bd 1f 17 f0 ee 	movb   $0xee,0xf0171fbd
f0103033:	c1 e8 10             	shr    $0x10,%eax
f0103036:	66 a3 be 1f 17 f0    	mov    %ax,0xf0171fbe
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f010303c:	b8 7a 36 10 f0       	mov    $0xf010367a,%eax
f0103041:	66 a3 c0 1f 17 f0    	mov    %ax,0xf0171fc0
f0103047:	66 c7 05 c2 1f 17 f0 	movw   $0x8,0xf0171fc2
f010304e:	08 00 
f0103050:	c6 05 c4 1f 17 f0 00 	movb   $0x0,0xf0171fc4
f0103057:	c6 05 c5 1f 17 f0 8e 	movb   $0x8e,0xf0171fc5
f010305e:	c1 e8 10             	shr    $0x10,%eax
f0103061:	66 a3 c6 1f 17 f0    	mov    %ax,0xf0171fc6
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f0103067:	b8 80 36 10 f0       	mov    $0xf0103680,%eax
f010306c:	66 a3 c8 1f 17 f0    	mov    %ax,0xf0171fc8
f0103072:	66 c7 05 ca 1f 17 f0 	movw   $0x8,0xf0171fca
f0103079:	08 00 
f010307b:	c6 05 cc 1f 17 f0 00 	movb   $0x0,0xf0171fcc
f0103082:	c6 05 cd 1f 17 f0 8e 	movb   $0x8e,0xf0171fcd
f0103089:	c1 e8 10             	shr    $0x10,%eax
f010308c:	66 a3 ce 1f 17 f0    	mov    %ax,0xf0171fce
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f0103092:	b8 86 36 10 f0       	mov    $0xf0103686,%eax
f0103097:	66 a3 d0 1f 17 f0    	mov    %ax,0xf0171fd0
f010309d:	66 c7 05 d2 1f 17 f0 	movw   $0x8,0xf0171fd2
f01030a4:	08 00 
f01030a6:	c6 05 d4 1f 17 f0 00 	movb   $0x0,0xf0171fd4
f01030ad:	c6 05 d5 1f 17 f0 8e 	movb   $0x8e,0xf0171fd5
f01030b4:	c1 e8 10             	shr    $0x10,%eax
f01030b7:	66 a3 d6 1f 17 f0    	mov    %ax,0xf0171fd6
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f01030bd:	b8 8c 36 10 f0       	mov    $0xf010368c,%eax
f01030c2:	66 a3 d8 1f 17 f0    	mov    %ax,0xf0171fd8
f01030c8:	66 c7 05 da 1f 17 f0 	movw   $0x8,0xf0171fda
f01030cf:	08 00 
f01030d1:	c6 05 dc 1f 17 f0 00 	movb   $0x0,0xf0171fdc
f01030d8:	c6 05 dd 1f 17 f0 8e 	movb   $0x8e,0xf0171fdd
f01030df:	c1 e8 10             	shr    $0x10,%eax
f01030e2:	66 a3 de 1f 17 f0    	mov    %ax,0xf0171fde
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01030e8:	b8 92 36 10 f0       	mov    $0xf0103692,%eax
f01030ed:	66 a3 e0 1f 17 f0    	mov    %ax,0xf0171fe0
f01030f3:	66 c7 05 e2 1f 17 f0 	movw   $0x8,0xf0171fe2
f01030fa:	08 00 
f01030fc:	c6 05 e4 1f 17 f0 00 	movb   $0x0,0xf0171fe4
f0103103:	c6 05 e5 1f 17 f0 8e 	movb   $0x8e,0xf0171fe5
f010310a:	c1 e8 10             	shr    $0x10,%eax
f010310d:	66 a3 e6 1f 17 f0    	mov    %ax,0xf0171fe6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f0103113:	b8 96 36 10 f0       	mov    $0xf0103696,%eax
f0103118:	66 a3 f0 1f 17 f0    	mov    %ax,0xf0171ff0
f010311e:	66 c7 05 f2 1f 17 f0 	movw   $0x8,0xf0171ff2
f0103125:	08 00 
f0103127:	c6 05 f4 1f 17 f0 00 	movb   $0x0,0xf0171ff4
f010312e:	c6 05 f5 1f 17 f0 8e 	movb   $0x8e,0xf0171ff5
f0103135:	c1 e8 10             	shr    $0x10,%eax
f0103138:	66 a3 f6 1f 17 f0    	mov    %ax,0xf0171ff6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f010313e:	b8 9a 36 10 f0       	mov    $0xf010369a,%eax
f0103143:	66 a3 f8 1f 17 f0    	mov    %ax,0xf0171ff8
f0103149:	66 c7 05 fa 1f 17 f0 	movw   $0x8,0xf0171ffa
f0103150:	08 00 
f0103152:	c6 05 fc 1f 17 f0 00 	movb   $0x0,0xf0171ffc
f0103159:	c6 05 fd 1f 17 f0 8e 	movb   $0x8e,0xf0171ffd
f0103160:	c1 e8 10             	shr    $0x10,%eax
f0103163:	66 a3 fe 1f 17 f0    	mov    %ax,0xf0171ffe
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f0103169:	b8 9e 36 10 f0       	mov    $0xf010369e,%eax
f010316e:	66 a3 00 20 17 f0    	mov    %ax,0xf0172000
f0103174:	66 c7 05 02 20 17 f0 	movw   $0x8,0xf0172002
f010317b:	08 00 
f010317d:	c6 05 04 20 17 f0 00 	movb   $0x0,0xf0172004
f0103184:	c6 05 05 20 17 f0 8e 	movb   $0x8e,0xf0172005
f010318b:	c1 e8 10             	shr    $0x10,%eax
f010318e:	66 a3 06 20 17 f0    	mov    %ax,0xf0172006
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f0103194:	b8 a2 36 10 f0       	mov    $0xf01036a2,%eax
f0103199:	66 a3 08 20 17 f0    	mov    %ax,0xf0172008
f010319f:	66 c7 05 0a 20 17 f0 	movw   $0x8,0xf017200a
f01031a6:	08 00 
f01031a8:	c6 05 0c 20 17 f0 00 	movb   $0x0,0xf017200c
f01031af:	c6 05 0d 20 17 f0 8e 	movb   $0x8e,0xf017200d
f01031b6:	c1 e8 10             	shr    $0x10,%eax
f01031b9:	66 a3 0e 20 17 f0    	mov    %ax,0xf017200e
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f01031bf:	b8 a6 36 10 f0       	mov    $0xf01036a6,%eax
f01031c4:	66 a3 10 20 17 f0    	mov    %ax,0xf0172010
f01031ca:	66 c7 05 12 20 17 f0 	movw   $0x8,0xf0172012
f01031d1:	08 00 
f01031d3:	c6 05 14 20 17 f0 00 	movb   $0x0,0xf0172014
f01031da:	c6 05 15 20 17 f0 8e 	movb   $0x8e,0xf0172015
f01031e1:	c1 e8 10             	shr    $0x10,%eax
f01031e4:	66 a3 16 20 17 f0    	mov    %ax,0xf0172016
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01031ea:	b8 aa 36 10 f0       	mov    $0xf01036aa,%eax
f01031ef:	66 a3 20 20 17 f0    	mov    %ax,0xf0172020
f01031f5:	66 c7 05 22 20 17 f0 	movw   $0x8,0xf0172022
f01031fc:	08 00 
f01031fe:	c6 05 24 20 17 f0 00 	movb   $0x0,0xf0172024
f0103205:	c6 05 25 20 17 f0 8e 	movb   $0x8e,0xf0172025
f010320c:	c1 e8 10             	shr    $0x10,%eax
f010320f:	66 a3 26 20 17 f0    	mov    %ax,0xf0172026
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f0103215:	b8 b0 36 10 f0       	mov    $0xf01036b0,%eax
f010321a:	66 a3 28 20 17 f0    	mov    %ax,0xf0172028
f0103220:	66 c7 05 2a 20 17 f0 	movw   $0x8,0xf017202a
f0103227:	08 00 
f0103229:	c6 05 2c 20 17 f0 00 	movb   $0x0,0xf017202c
f0103230:	c6 05 2d 20 17 f0 8e 	movb   $0x8e,0xf017202d
f0103237:	c1 e8 10             	shr    $0x10,%eax
f010323a:	66 a3 2e 20 17 f0    	mov    %ax,0xf017202e
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103240:	b8 b4 36 10 f0       	mov    $0xf01036b4,%eax
f0103245:	66 a3 30 20 17 f0    	mov    %ax,0xf0172030
f010324b:	66 c7 05 32 20 17 f0 	movw   $0x8,0xf0172032
f0103252:	08 00 
f0103254:	c6 05 34 20 17 f0 00 	movb   $0x0,0xf0172034
f010325b:	c6 05 35 20 17 f0 8e 	movb   $0x8e,0xf0172035
f0103262:	c1 e8 10             	shr    $0x10,%eax
f0103265:	66 a3 36 20 17 f0    	mov    %ax,0xf0172036
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f010326b:	b8 ba 36 10 f0       	mov    $0xf01036ba,%eax
f0103270:	66 a3 38 20 17 f0    	mov    %ax,0xf0172038
f0103276:	66 c7 05 3a 20 17 f0 	movw   $0x8,0xf017203a
f010327d:	08 00 
f010327f:	c6 05 3c 20 17 f0 00 	movb   $0x0,0xf017203c
f0103286:	c6 05 3d 20 17 f0 8e 	movb   $0x8e,0xf017203d
f010328d:	c1 e8 10             	shr    $0x10,%eax
f0103290:	66 a3 3e 20 17 f0    	mov    %ax,0xf017203e
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f0103296:	b8 c0 36 10 f0       	mov    $0xf01036c0,%eax
f010329b:	66 a3 20 21 17 f0    	mov    %ax,0xf0172120
f01032a1:	66 c7 05 22 21 17 f0 	movw   $0x8,0xf0172122
f01032a8:	08 00 
f01032aa:	c6 05 24 21 17 f0 00 	movb   $0x0,0xf0172124
f01032b1:	c6 05 25 21 17 f0 ef 	movb   $0xef,0xf0172125
f01032b8:	c1 e8 10             	shr    $0x10,%eax
f01032bb:	66 a3 26 21 17 f0    	mov    %ax,0xf0172126

	// Per-CPU setup 
	trap_init_percpu();
f01032c1:	e8 6a fc ff ff       	call   f0102f30 <trap_init_percpu>
}
f01032c6:	5d                   	pop    %ebp
f01032c7:	c3                   	ret    

f01032c8 <print_regs>:
	}
}

void	
print_regs(struct PushRegs *regs)
{
f01032c8:	55                   	push   %ebp
f01032c9:	89 e5                	mov    %esp,%ebp
f01032cb:	53                   	push   %ebx
f01032cc:	83 ec 0c             	sub    $0xc,%esp
f01032cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01032d2:	ff 33                	pushl  (%ebx)
f01032d4:	68 87 58 10 f0       	push   $0xf0105887
f01032d9:	e8 3e fc ff ff       	call   f0102f1c <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01032de:	83 c4 08             	add    $0x8,%esp
f01032e1:	ff 73 04             	pushl  0x4(%ebx)
f01032e4:	68 96 58 10 f0       	push   $0xf0105896
f01032e9:	e8 2e fc ff ff       	call   f0102f1c <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01032ee:	83 c4 08             	add    $0x8,%esp
f01032f1:	ff 73 08             	pushl  0x8(%ebx)
f01032f4:	68 a5 58 10 f0       	push   $0xf01058a5
f01032f9:	e8 1e fc ff ff       	call   f0102f1c <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01032fe:	83 c4 08             	add    $0x8,%esp
f0103301:	ff 73 0c             	pushl  0xc(%ebx)
f0103304:	68 b4 58 10 f0       	push   $0xf01058b4
f0103309:	e8 0e fc ff ff       	call   f0102f1c <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010330e:	83 c4 08             	add    $0x8,%esp
f0103311:	ff 73 10             	pushl  0x10(%ebx)
f0103314:	68 c3 58 10 f0       	push   $0xf01058c3
f0103319:	e8 fe fb ff ff       	call   f0102f1c <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010331e:	83 c4 08             	add    $0x8,%esp
f0103321:	ff 73 14             	pushl  0x14(%ebx)
f0103324:	68 d2 58 10 f0       	push   $0xf01058d2
f0103329:	e8 ee fb ff ff       	call   f0102f1c <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010332e:	83 c4 08             	add    $0x8,%esp
f0103331:	ff 73 18             	pushl  0x18(%ebx)
f0103334:	68 e1 58 10 f0       	push   $0xf01058e1
f0103339:	e8 de fb ff ff       	call   f0102f1c <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010333e:	83 c4 08             	add    $0x8,%esp
f0103341:	ff 73 1c             	pushl  0x1c(%ebx)
f0103344:	68 f0 58 10 f0       	push   $0xf01058f0
f0103349:	e8 ce fb ff ff       	call   f0102f1c <cprintf>
}
f010334e:	83 c4 10             	add    $0x10,%esp
f0103351:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103354:	c9                   	leave  
f0103355:	c3                   	ret    

f0103356 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103356:	55                   	push   %ebp
f0103357:	89 e5                	mov    %esp,%ebp
f0103359:	56                   	push   %esi
f010335a:	53                   	push   %ebx
f010335b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010335e:	83 ec 08             	sub    $0x8,%esp
f0103361:	53                   	push   %ebx
f0103362:	68 39 5a 10 f0       	push   $0xf0105a39
f0103367:	e8 b0 fb ff ff       	call   f0102f1c <cprintf>
	print_regs(&tf->tf_regs);
f010336c:	89 1c 24             	mov    %ebx,(%esp)
f010336f:	e8 54 ff ff ff       	call   f01032c8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103374:	83 c4 08             	add    $0x8,%esp
f0103377:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010337b:	50                   	push   %eax
f010337c:	68 41 59 10 f0       	push   $0xf0105941
f0103381:	e8 96 fb ff ff       	call   f0102f1c <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103386:	83 c4 08             	add    $0x8,%esp
f0103389:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010338d:	50                   	push   %eax
f010338e:	68 54 59 10 f0       	push   $0xf0105954
f0103393:	e8 84 fb ff ff       	call   f0102f1c <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103398:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f010339b:	83 c4 10             	add    $0x10,%esp
f010339e:	83 f8 13             	cmp    $0x13,%eax
f01033a1:	77 09                	ja     f01033ac <print_trapframe+0x56>
		return excnames[trapno];
f01033a3:	8b 14 85 00 5c 10 f0 	mov    -0xfefa400(,%eax,4),%edx
f01033aa:	eb 10                	jmp    f01033bc <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01033ac:	83 f8 30             	cmp    $0x30,%eax
f01033af:	b9 0b 59 10 f0       	mov    $0xf010590b,%ecx
f01033b4:	ba ff 58 10 f0       	mov    $0xf01058ff,%edx
f01033b9:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033bc:	83 ec 04             	sub    $0x4,%esp
f01033bf:	52                   	push   %edx
f01033c0:	50                   	push   %eax
f01033c1:	68 67 59 10 f0       	push   $0xf0105967
f01033c6:	e8 51 fb ff ff       	call   f0102f1c <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01033cb:	83 c4 10             	add    $0x10,%esp
f01033ce:	3b 1d a0 27 17 f0    	cmp    0xf01727a0,%ebx
f01033d4:	75 1a                	jne    f01033f0 <print_trapframe+0x9a>
f01033d6:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033da:	75 14                	jne    f01033f0 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01033dc:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01033df:	83 ec 08             	sub    $0x8,%esp
f01033e2:	50                   	push   %eax
f01033e3:	68 79 59 10 f0       	push   $0xf0105979
f01033e8:	e8 2f fb ff ff       	call   f0102f1c <cprintf>
f01033ed:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01033f0:	83 ec 08             	sub    $0x8,%esp
f01033f3:	ff 73 2c             	pushl  0x2c(%ebx)
f01033f6:	68 88 59 10 f0       	push   $0xf0105988
f01033fb:	e8 1c fb ff ff       	call   f0102f1c <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103400:	83 c4 10             	add    $0x10,%esp
f0103403:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103407:	75 49                	jne    f0103452 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103409:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010340c:	89 c2                	mov    %eax,%edx
f010340e:	83 e2 01             	and    $0x1,%edx
f0103411:	ba 25 59 10 f0       	mov    $0xf0105925,%edx
f0103416:	b9 1a 59 10 f0       	mov    $0xf010591a,%ecx
f010341b:	0f 44 ca             	cmove  %edx,%ecx
f010341e:	89 c2                	mov    %eax,%edx
f0103420:	83 e2 02             	and    $0x2,%edx
f0103423:	ba 37 59 10 f0       	mov    $0xf0105937,%edx
f0103428:	be 31 59 10 f0       	mov    $0xf0105931,%esi
f010342d:	0f 45 d6             	cmovne %esi,%edx
f0103430:	83 e0 04             	and    $0x4,%eax
f0103433:	be 64 5a 10 f0       	mov    $0xf0105a64,%esi
f0103438:	b8 3c 59 10 f0       	mov    $0xf010593c,%eax
f010343d:	0f 44 c6             	cmove  %esi,%eax
f0103440:	51                   	push   %ecx
f0103441:	52                   	push   %edx
f0103442:	50                   	push   %eax
f0103443:	68 96 59 10 f0       	push   $0xf0105996
f0103448:	e8 cf fa ff ff       	call   f0102f1c <cprintf>
f010344d:	83 c4 10             	add    $0x10,%esp
f0103450:	eb 10                	jmp    f0103462 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103452:	83 ec 0c             	sub    $0xc,%esp
f0103455:	68 dc 4a 10 f0       	push   $0xf0104adc
f010345a:	e8 bd fa ff ff       	call   f0102f1c <cprintf>
f010345f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103462:	83 ec 08             	sub    $0x8,%esp
f0103465:	ff 73 30             	pushl  0x30(%ebx)
f0103468:	68 a5 59 10 f0       	push   $0xf01059a5
f010346d:	e8 aa fa ff ff       	call   f0102f1c <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103472:	83 c4 08             	add    $0x8,%esp
f0103475:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103479:	50                   	push   %eax
f010347a:	68 b4 59 10 f0       	push   $0xf01059b4
f010347f:	e8 98 fa ff ff       	call   f0102f1c <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103484:	83 c4 08             	add    $0x8,%esp
f0103487:	ff 73 38             	pushl  0x38(%ebx)
f010348a:	68 c7 59 10 f0       	push   $0xf01059c7
f010348f:	e8 88 fa ff ff       	call   f0102f1c <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103494:	83 c4 10             	add    $0x10,%esp
f0103497:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010349b:	74 25                	je     f01034c2 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010349d:	83 ec 08             	sub    $0x8,%esp
f01034a0:	ff 73 3c             	pushl  0x3c(%ebx)
f01034a3:	68 d6 59 10 f0       	push   $0xf01059d6
f01034a8:	e8 6f fa ff ff       	call   f0102f1c <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01034ad:	83 c4 08             	add    $0x8,%esp
f01034b0:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01034b4:	50                   	push   %eax
f01034b5:	68 e5 59 10 f0       	push   $0xf01059e5
f01034ba:	e8 5d fa ff ff       	call   f0102f1c <cprintf>
f01034bf:	83 c4 10             	add    $0x10,%esp
	}
}
f01034c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034c5:	5b                   	pop    %ebx
f01034c6:	5e                   	pop    %esi
f01034c7:	5d                   	pop    %ebp
f01034c8:	c3                   	ret    

f01034c9 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034c9:	55                   	push   %ebp
f01034ca:	89 e5                	mov    %esp,%ebp
f01034cc:	53                   	push   %ebx
f01034cd:	83 ec 04             	sub    $0x4,%esp
f01034d0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01034d3:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f01034d6:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034da:	75 17                	jne    f01034f3 <page_fault_handler+0x2a>
		panic("Kernel page fault!");	
f01034dc:	83 ec 04             	sub    $0x4,%esp
f01034df:	68 f8 59 10 f0       	push   $0xf01059f8
f01034e4:	68 f1 00 00 00       	push   $0xf1
f01034e9:	68 0b 5a 10 f0       	push   $0xf0105a0b
f01034ee:	e8 ad cb ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01034f3:	ff 73 30             	pushl  0x30(%ebx)
f01034f6:	50                   	push   %eax
f01034f7:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f01034fc:	ff 70 48             	pushl  0x48(%eax)
f01034ff:	68 b0 5b 10 f0       	push   $0xf0105bb0
f0103504:	e8 13 fa ff ff       	call   f0102f1c <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103509:	89 1c 24             	mov    %ebx,(%esp)
f010350c:	e8 45 fe ff ff       	call   f0103356 <print_trapframe>
	env_destroy(curenv);
f0103511:	83 c4 04             	add    $0x4,%esp
f0103514:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010351a:	e8 e4 f8 ff ff       	call   f0102e03 <env_destroy>
}
f010351f:	83 c4 10             	add    $0x10,%esp
f0103522:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103525:	c9                   	leave  
f0103526:	c3                   	ret    

f0103527 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103527:	55                   	push   %ebp
f0103528:	89 e5                	mov    %esp,%ebp
f010352a:	57                   	push   %edi
f010352b:	56                   	push   %esi
f010352c:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010352f:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103530:	9c                   	pushf  
f0103531:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103532:	f6 c4 02             	test   $0x2,%ah
f0103535:	74 19                	je     f0103550 <trap+0x29>
f0103537:	68 17 5a 10 f0       	push   $0xf0105a17
f010353c:	68 f7 54 10 f0       	push   $0xf01054f7
f0103541:	68 c8 00 00 00       	push   $0xc8
f0103546:	68 0b 5a 10 f0       	push   $0xf0105a0b
f010354b:	e8 50 cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103550:	83 ec 08             	sub    $0x8,%esp
f0103553:	56                   	push   %esi
f0103554:	68 30 5a 10 f0       	push   $0xf0105a30
f0103559:	e8 be f9 ff ff       	call   f0102f1c <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f010355e:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103562:	83 e0 03             	and    $0x3,%eax
f0103565:	83 c4 10             	add    $0x10,%esp
f0103568:	66 83 f8 03          	cmp    $0x3,%ax
f010356c:	75 31                	jne    f010359f <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f010356e:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103573:	85 c0                	test   %eax,%eax
f0103575:	75 19                	jne    f0103590 <trap+0x69>
f0103577:	68 4b 5a 10 f0       	push   $0xf0105a4b
f010357c:	68 f7 54 10 f0       	push   $0xf01054f7
f0103581:	68 ce 00 00 00       	push   $0xce
f0103586:	68 0b 5a 10 f0       	push   $0xf0105a0b
f010358b:	e8 10 cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103590:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103595:	89 c7                	mov    %eax,%edi
f0103597:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103599:	8b 35 84 1f 17 f0    	mov    0xf0171f84,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010359f:	89 35 a0 27 17 f0    	mov    %esi,0xf01727a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f01035a5:	8b 46 28             	mov    0x28(%esi),%eax
f01035a8:	83 f8 0e             	cmp    $0xe,%eax
f01035ab:	74 0c                	je     f01035b9 <trap+0x92>
f01035ad:	83 f8 30             	cmp    $0x30,%eax
f01035b0:	74 23                	je     f01035d5 <trap+0xae>
f01035b2:	83 f8 03             	cmp    $0x3,%eax
f01035b5:	75 3f                	jne    f01035f6 <trap+0xcf>
f01035b7:	eb 0e                	jmp    f01035c7 <trap+0xa0>
	{
		case T_PGFLT: 	  page_fault_handler(tf); 	return;
f01035b9:	83 ec 0c             	sub    $0xc,%esp
f01035bc:	56                   	push   %esi
f01035bd:	e8 07 ff ff ff       	call   f01034c9 <page_fault_handler>
f01035c2:	83 c4 10             	add    $0x10,%esp
f01035c5:	eb 6a                	jmp    f0103631 <trap+0x10a>

		case T_BRKPT:     monitor(tf);			return;
f01035c7:	83 ec 0c             	sub    $0xc,%esp
f01035ca:	56                   	push   %esi
f01035cb:	e8 39 d2 ff ff       	call   f0100809 <monitor>
f01035d0:	83 c4 10             	add    $0x10,%esp
f01035d3:	eb 5c                	jmp    f0103631 <trap+0x10a>

		case T_SYSCALL:	  
				tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
f01035d5:	83 ec 08             	sub    $0x8,%esp
f01035d8:	ff 76 04             	pushl  0x4(%esi)
f01035db:	ff 36                	pushl  (%esi)
f01035dd:	ff 76 10             	pushl  0x10(%esi)
f01035e0:	ff 76 18             	pushl  0x18(%esi)
f01035e3:	ff 76 14             	pushl  0x14(%esi)
f01035e6:	ff 76 1c             	pushl  0x1c(%esi)
f01035e9:	e8 ea 00 00 00       	call   f01036d8 <syscall>
f01035ee:	89 46 1c             	mov    %eax,0x1c(%esi)
f01035f1:	83 c4 20             	add    $0x20,%esp
f01035f4:	eb 3b                	jmp    f0103631 <trap+0x10a>
	}



	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01035f6:	83 ec 0c             	sub    $0xc,%esp
f01035f9:	56                   	push   %esi
f01035fa:	e8 57 fd ff ff       	call   f0103356 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01035ff:	83 c4 10             	add    $0x10,%esp
f0103602:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103607:	75 17                	jne    f0103620 <trap+0xf9>
		panic("unhandled trap in kernel");
f0103609:	83 ec 04             	sub    $0x4,%esp
f010360c:	68 52 5a 10 f0       	push   $0xf0105a52
f0103611:	68 b7 00 00 00       	push   $0xb7
f0103616:	68 0b 5a 10 f0       	push   $0xf0105a0b
f010361b:	e8 80 ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103620:	83 ec 0c             	sub    $0xc,%esp
f0103623:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103629:	e8 d5 f7 ff ff       	call   f0102e03 <env_destroy>
f010362e:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103631:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103636:	85 c0                	test   %eax,%eax
f0103638:	74 06                	je     f0103640 <trap+0x119>
f010363a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010363e:	74 19                	je     f0103659 <trap+0x132>
f0103640:	68 d4 5b 10 f0       	push   $0xf0105bd4
f0103645:	68 f7 54 10 f0       	push   $0xf01054f7
f010364a:	68 e0 00 00 00       	push   $0xe0
f010364f:	68 0b 5a 10 f0       	push   $0xf0105a0b
f0103654:	e8 47 ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103659:	83 ec 0c             	sub    $0xc,%esp
f010365c:	50                   	push   %eax
f010365d:	e8 f1 f7 ff ff       	call   f0102e53 <env_run>

f0103662 <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f0103662:	6a 00                	push   $0x0
f0103664:	6a 00                	push   $0x0
f0103666:	eb 5e                	jmp    f01036c6 <_alltraps>

f0103668 <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f0103668:	6a 00                	push   $0x0
f010366a:	6a 01                	push   $0x1
f010366c:	eb 58                	jmp    f01036c6 <_alltraps>

f010366e <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f010366e:	6a 00                	push   $0x0
f0103670:	6a 02                	push   $0x2
f0103672:	eb 52                	jmp    f01036c6 <_alltraps>

f0103674 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f0103674:	6a 00                	push   $0x0
f0103676:	6a 03                	push   $0x3
f0103678:	eb 4c                	jmp    f01036c6 <_alltraps>

f010367a <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f010367a:	6a 00                	push   $0x0
f010367c:	6a 04                	push   $0x4
f010367e:	eb 46                	jmp    f01036c6 <_alltraps>

f0103680 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f0103680:	6a 00                	push   $0x0
f0103682:	6a 05                	push   $0x5
f0103684:	eb 40                	jmp    f01036c6 <_alltraps>

f0103686 <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f0103686:	6a 00                	push   $0x0
f0103688:	6a 06                	push   $0x6
f010368a:	eb 3a                	jmp    f01036c6 <_alltraps>

f010368c <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f010368c:	6a 00                	push   $0x0
f010368e:	6a 07                	push   $0x7
f0103690:	eb 34                	jmp    f01036c6 <_alltraps>

f0103692 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f0103692:	6a 08                	push   $0x8
f0103694:	eb 30                	jmp    f01036c6 <_alltraps>

f0103696 <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f0103696:	6a 0a                	push   $0xa
f0103698:	eb 2c                	jmp    f01036c6 <_alltraps>

f010369a <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f010369a:	6a 0b                	push   $0xb
f010369c:	eb 28                	jmp    f01036c6 <_alltraps>

f010369e <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f010369e:	6a 0c                	push   $0xc
f01036a0:	eb 24                	jmp    f01036c6 <_alltraps>

f01036a2 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f01036a2:	6a 0d                	push   $0xd
f01036a4:	eb 20                	jmp    f01036c6 <_alltraps>

f01036a6 <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f01036a6:	6a 0e                	push   $0xe
f01036a8:	eb 1c                	jmp    f01036c6 <_alltraps>

f01036aa <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f01036aa:	6a 00                	push   $0x0
f01036ac:	6a 10                	push   $0x10
f01036ae:	eb 16                	jmp    f01036c6 <_alltraps>

f01036b0 <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f01036b0:	6a 11                	push   $0x11
f01036b2:	eb 12                	jmp    f01036c6 <_alltraps>

f01036b4 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f01036b4:	6a 00                	push   $0x0
f01036b6:	6a 12                	push   $0x12
f01036b8:	eb 0c                	jmp    f01036c6 <_alltraps>

f01036ba <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f01036ba:	6a 00                	push   $0x0
f01036bc:	6a 13                	push   $0x13
f01036be:	eb 06                	jmp    f01036c6 <_alltraps>

f01036c0 <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f01036c0:	6a 00                	push   $0x0
f01036c2:	6a 30                	push   $0x30
f01036c4:	eb 00                	jmp    f01036c6 <_alltraps>

f01036c6 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f01036c6:	1e                   	push   %ds
	pushl	%es
f01036c7:	06                   	push   %es
	pushal
f01036c8:	60                   	pusha  
	mov	$GD_KD, %eax
f01036c9:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f01036ce:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f01036d0:	8e d8                	mov    %eax,%ds
	pushl	%esp
f01036d2:	54                   	push   %esp
	call	trap
f01036d3:	e8 4f fe ff ff       	call   f0103527 <trap>

f01036d8 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01036d8:	55                   	push   %ebp
f01036d9:	89 e5                	mov    %esp,%ebp
f01036db:	83 ec 18             	sub    $0x18,%esp
f01036de:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
f01036e1:	83 f8 01             	cmp    $0x1,%eax
f01036e4:	74 44                	je     f010372a <syscall+0x52>
f01036e6:	83 f8 01             	cmp    $0x1,%eax
f01036e9:	72 0f                	jb     f01036fa <syscall+0x22>
f01036eb:	83 f8 02             	cmp    $0x2,%eax
f01036ee:	74 41                	je     f0103731 <syscall+0x59>
f01036f0:	83 f8 03             	cmp    $0x3,%eax
f01036f3:	74 46                	je     f010373b <syscall+0x63>
f01036f5:	e9 a6 00 00 00       	jmp    f01037a0 <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01036fa:	6a 04                	push   $0x4
f01036fc:	ff 75 10             	pushl  0x10(%ebp)
f01036ff:	ff 75 0c             	pushl  0xc(%ebp)
f0103702:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103708:	e8 f4 f0 ff ff       	call   f0102801 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010370d:	83 c4 0c             	add    $0xc,%esp
f0103710:	ff 75 0c             	pushl  0xc(%ebp)
f0103713:	ff 75 10             	pushl  0x10(%ebp)
f0103716:	68 50 5c 10 f0       	push   $0xf0105c50
f010371b:	e8 fc f7 ff ff       	call   f0102f1c <cprintf>
f0103720:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
f0103723:	b8 00 00 00 00       	mov    $0x0,%eax
f0103728:	eb 7b                	jmp    f01037a5 <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010372a:	e8 94 cd ff ff       	call   f01004c3 <cons_getc>

	switch (syscallno) 
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			return sys_cgetc();		
f010372f:	eb 74                	jmp    f01037a5 <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103731:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103736:	8b 40 48             	mov    0x48(%eax),%eax
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			return sys_cgetc();		

		case SYS_getenvid:		return sys_getenvid();
f0103739:	eb 6a                	jmp    f01037a5 <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010373b:	83 ec 04             	sub    $0x4,%esp
f010373e:	6a 01                	push   $0x1
f0103740:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103743:	50                   	push   %eax
f0103744:	ff 75 0c             	pushl  0xc(%ebp)
f0103747:	e8 6a f1 ff ff       	call   f01028b6 <envid2env>
f010374c:	83 c4 10             	add    $0x10,%esp
f010374f:	85 c0                	test   %eax,%eax
f0103751:	78 46                	js     f0103799 <syscall+0xc1>
		return r;
	if (e == curenv)
f0103753:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103756:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f010375c:	39 d0                	cmp    %edx,%eax
f010375e:	75 15                	jne    f0103775 <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103760:	83 ec 08             	sub    $0x8,%esp
f0103763:	ff 70 48             	pushl  0x48(%eax)
f0103766:	68 55 5c 10 f0       	push   $0xf0105c55
f010376b:	e8 ac f7 ff ff       	call   f0102f1c <cprintf>
f0103770:	83 c4 10             	add    $0x10,%esp
f0103773:	eb 16                	jmp    f010378b <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103775:	83 ec 04             	sub    $0x4,%esp
f0103778:	ff 70 48             	pushl  0x48(%eax)
f010377b:	ff 72 48             	pushl  0x48(%edx)
f010377e:	68 70 5c 10 f0       	push   $0xf0105c70
f0103783:	e8 94 f7 ff ff       	call   f0102f1c <cprintf>
f0103788:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010378b:	83 ec 0c             	sub    $0xc,%esp
f010378e:	ff 75 f4             	pushl  -0xc(%ebp)
f0103791:	e8 6d f6 ff ff       	call   f0102e03 <env_destroy>
f0103796:	83 c4 10             	add    $0x10,%esp

		case SYS_getenvid:		return sys_getenvid();

		case SYS_env_destroy:		sys_env_destroy((envid_t) a1);

		default:			return -E_INVAL;
f0103799:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010379e:	eb 05                	jmp    f01037a5 <syscall+0xcd>
f01037a0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f01037a5:	c9                   	leave  
f01037a6:	c3                   	ret    

f01037a7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01037a7:	55                   	push   %ebp
f01037a8:	89 e5                	mov    %esp,%ebp
f01037aa:	57                   	push   %edi
f01037ab:	56                   	push   %esi
f01037ac:	53                   	push   %ebx
f01037ad:	83 ec 14             	sub    $0x14,%esp
f01037b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01037b3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01037b6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01037b9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01037bc:	8b 1a                	mov    (%edx),%ebx
f01037be:	8b 01                	mov    (%ecx),%eax
f01037c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037c3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01037ca:	eb 7f                	jmp    f010384b <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01037cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01037cf:	01 d8                	add    %ebx,%eax
f01037d1:	89 c6                	mov    %eax,%esi
f01037d3:	c1 ee 1f             	shr    $0x1f,%esi
f01037d6:	01 c6                	add    %eax,%esi
f01037d8:	d1 fe                	sar    %esi
f01037da:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01037dd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037e0:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01037e3:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037e5:	eb 03                	jmp    f01037ea <stab_binsearch+0x43>
			m--;
f01037e7:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037ea:	39 c3                	cmp    %eax,%ebx
f01037ec:	7f 0d                	jg     f01037fb <stab_binsearch+0x54>
f01037ee:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01037f2:	83 ea 0c             	sub    $0xc,%edx
f01037f5:	39 f9                	cmp    %edi,%ecx
f01037f7:	75 ee                	jne    f01037e7 <stab_binsearch+0x40>
f01037f9:	eb 05                	jmp    f0103800 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01037fb:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01037fe:	eb 4b                	jmp    f010384b <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103800:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103803:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103806:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010380a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010380d:	76 11                	jbe    f0103820 <stab_binsearch+0x79>
			*region_left = m;
f010380f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103812:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103814:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103817:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010381e:	eb 2b                	jmp    f010384b <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103820:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103823:	73 14                	jae    f0103839 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103825:	83 e8 01             	sub    $0x1,%eax
f0103828:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010382b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010382e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103830:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103837:	eb 12                	jmp    f010384b <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103839:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010383c:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010383e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103842:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103844:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010384b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010384e:	0f 8e 78 ff ff ff    	jle    f01037cc <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103854:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103858:	75 0f                	jne    f0103869 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010385a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010385d:	8b 00                	mov    (%eax),%eax
f010385f:	83 e8 01             	sub    $0x1,%eax
f0103862:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103865:	89 06                	mov    %eax,(%esi)
f0103867:	eb 2c                	jmp    f0103895 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103869:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010386c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010386e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103871:	8b 0e                	mov    (%esi),%ecx
f0103873:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103876:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103879:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010387c:	eb 03                	jmp    f0103881 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010387e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103881:	39 c8                	cmp    %ecx,%eax
f0103883:	7e 0b                	jle    f0103890 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103885:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103889:	83 ea 0c             	sub    $0xc,%edx
f010388c:	39 df                	cmp    %ebx,%edi
f010388e:	75 ee                	jne    f010387e <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103890:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103893:	89 06                	mov    %eax,(%esi)
	}
}
f0103895:	83 c4 14             	add    $0x14,%esp
f0103898:	5b                   	pop    %ebx
f0103899:	5e                   	pop    %esi
f010389a:	5f                   	pop    %edi
f010389b:	5d                   	pop    %ebp
f010389c:	c3                   	ret    

f010389d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010389d:	55                   	push   %ebp
f010389e:	89 e5                	mov    %esp,%ebp
f01038a0:	57                   	push   %edi
f01038a1:	56                   	push   %esi
f01038a2:	53                   	push   %ebx
f01038a3:	83 ec 3c             	sub    $0x3c,%esp
f01038a6:	8b 75 08             	mov    0x8(%ebp),%esi
f01038a9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01038ac:	c7 03 88 5c 10 f0    	movl   $0xf0105c88,(%ebx)
	info->eip_line = 0;
f01038b2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01038b9:	c7 43 08 88 5c 10 f0 	movl   $0xf0105c88,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01038c0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01038c7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01038ca:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01038d1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01038d7:	0f 87 8a 00 00 00    	ja     f0103967 <debuginfo_eip+0xca>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f01038dd:	6a 04                	push   $0x4
f01038df:	6a 10                	push   $0x10
f01038e1:	68 00 00 20 00       	push   $0x200000
f01038e6:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f01038ec:	e8 98 ee ff ff       	call   f0102789 <user_mem_check>
f01038f1:	83 c4 10             	add    $0x10,%esp
f01038f4:	85 c0                	test   %eax,%eax
f01038f6:	0f 84 2d 02 00 00    	je     f0103b29 <debuginfo_eip+0x28c>
                        return -1;

		stabs = usd->stabs;
f01038fc:	a1 00 00 20 00       	mov    0x200000,%eax
f0103901:	89 c1                	mov    %eax,%ecx
f0103903:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103906:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f010390c:	a1 08 00 20 00       	mov    0x200008,%eax
f0103911:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103914:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010391a:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f010391d:	6a 04                	push   $0x4
f010391f:	89 f8                	mov    %edi,%eax
f0103921:	29 c8                	sub    %ecx,%eax
f0103923:	c1 f8 02             	sar    $0x2,%eax
f0103926:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010392c:	50                   	push   %eax
f010392d:	51                   	push   %ecx
f010392e:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103934:	e8 50 ee ff ff       	call   f0102789 <user_mem_check>
f0103939:	83 c4 10             	add    $0x10,%esp
f010393c:	85 c0                	test   %eax,%eax
f010393e:	0f 84 ec 01 00 00    	je     f0103b30 <debuginfo_eip+0x293>
			return -1;

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f0103944:	6a 04                	push   $0x4
f0103946:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103949:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010394c:	29 ca                	sub    %ecx,%edx
f010394e:	52                   	push   %edx
f010394f:	51                   	push   %ecx
f0103950:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103956:	e8 2e ee ff ff       	call   f0102789 <user_mem_check>
f010395b:	83 c4 10             	add    $0x10,%esp
f010395e:	85 c0                	test   %eax,%eax
f0103960:	75 1f                	jne    f0103981 <debuginfo_eip+0xe4>
f0103962:	e9 d0 01 00 00       	jmp    f0103b37 <debuginfo_eip+0x29a>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103967:	c7 45 bc 6a 02 11 f0 	movl   $0xf011026a,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010396e:	c7 45 b8 c1 d7 10 f0 	movl   $0xf010d7c1,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103975:	bf c0 d7 10 f0       	mov    $0xf010d7c0,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010397a:	c7 45 c0 a0 5e 10 f0 	movl   $0xf0105ea0,-0x40(%ebp)
		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103981:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103984:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0103987:	0f 83 b1 01 00 00    	jae    f0103b3e <debuginfo_eip+0x2a1>
f010398d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103991:	0f 85 ae 01 00 00    	jne    f0103b45 <debuginfo_eip+0x2a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103997:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010399e:	2b 7d c0             	sub    -0x40(%ebp),%edi
f01039a1:	c1 ff 02             	sar    $0x2,%edi
f01039a4:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f01039aa:	83 e8 01             	sub    $0x1,%eax
f01039ad:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01039b0:	83 ec 08             	sub    $0x8,%esp
f01039b3:	56                   	push   %esi
f01039b4:	6a 64                	push   $0x64
f01039b6:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01039b9:	89 d1                	mov    %edx,%ecx
f01039bb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039be:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01039c1:	89 f8                	mov    %edi,%eax
f01039c3:	e8 df fd ff ff       	call   f01037a7 <stab_binsearch>
	if (lfile == 0)
f01039c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039cb:	83 c4 10             	add    $0x10,%esp
f01039ce:	85 c0                	test   %eax,%eax
f01039d0:	0f 84 76 01 00 00    	je     f0103b4c <debuginfo_eip+0x2af>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01039d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01039d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039dc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01039df:	83 ec 08             	sub    $0x8,%esp
f01039e2:	56                   	push   %esi
f01039e3:	6a 24                	push   $0x24
f01039e5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01039e8:	89 d1                	mov    %edx,%ecx
f01039ea:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01039ed:	89 f8                	mov    %edi,%eax
f01039ef:	e8 b3 fd ff ff       	call   f01037a7 <stab_binsearch>

	if (lfun <= rfun) {
f01039f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039f7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01039fa:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01039fd:	83 c4 10             	add    $0x10,%esp
f0103a00:	39 d0                	cmp    %edx,%eax
f0103a02:	7f 2b                	jg     f0103a2f <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103a04:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a07:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103a0a:	8b 11                	mov    (%ecx),%edx
f0103a0c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103a0f:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103a12:	39 fa                	cmp    %edi,%edx
f0103a14:	73 06                	jae    f0103a1c <debuginfo_eip+0x17f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103a16:	03 55 b8             	add    -0x48(%ebp),%edx
f0103a19:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a1c:	8b 51 08             	mov    0x8(%ecx),%edx
f0103a1f:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103a22:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103a24:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103a27:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103a2a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a2d:	eb 0f                	jmp    f0103a3e <debuginfo_eip+0x1a1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a2f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103a32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a35:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103a38:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a3b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a3e:	83 ec 08             	sub    $0x8,%esp
f0103a41:	6a 3a                	push   $0x3a
f0103a43:	ff 73 08             	pushl  0x8(%ebx)
f0103a46:	e8 8f 08 00 00       	call   f01042da <strfind>
f0103a4b:	2b 43 08             	sub    0x8(%ebx),%eax
f0103a4e:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103a51:	83 c4 08             	add    $0x8,%esp
f0103a54:	56                   	push   %esi
f0103a55:	6a 44                	push   $0x44
f0103a57:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103a5a:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103a5d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103a60:	89 f8                	mov    %edi,%eax
f0103a62:	e8 40 fd ff ff       	call   f01037a7 <stab_binsearch>
	
	if(lline > rline)
f0103a67:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a6a:	83 c4 10             	add    $0x10,%esp
f0103a6d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103a70:	0f 8f dd 00 00 00    	jg     f0103b53 <debuginfo_eip+0x2b6>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f0103a76:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a79:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103a7c:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103a80:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a86:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103a8a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a8d:	eb 0a                	jmp    f0103a99 <debuginfo_eip+0x1fc>
f0103a8f:	83 e8 01             	sub    $0x1,%eax
f0103a92:	83 ea 0c             	sub    $0xc,%edx
f0103a95:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103a99:	39 c7                	cmp    %eax,%edi
f0103a9b:	7e 05                	jle    f0103aa2 <debuginfo_eip+0x205>
f0103a9d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aa0:	eb 47                	jmp    f0103ae9 <debuginfo_eip+0x24c>
	       && stabs[lline].n_type != N_SOL
f0103aa2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103aa6:	80 f9 84             	cmp    $0x84,%cl
f0103aa9:	75 0e                	jne    f0103ab9 <debuginfo_eip+0x21c>
f0103aab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aae:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103ab2:	74 1c                	je     f0103ad0 <debuginfo_eip+0x233>
f0103ab4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103ab7:	eb 17                	jmp    f0103ad0 <debuginfo_eip+0x233>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103ab9:	80 f9 64             	cmp    $0x64,%cl
f0103abc:	75 d1                	jne    f0103a8f <debuginfo_eip+0x1f2>
f0103abe:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103ac2:	74 cb                	je     f0103a8f <debuginfo_eip+0x1f2>
f0103ac4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ac7:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103acb:	74 03                	je     f0103ad0 <debuginfo_eip+0x233>
f0103acd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103ad0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103ad3:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103ad6:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103ad9:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103adc:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103adf:	29 f0                	sub    %esi,%eax
f0103ae1:	39 c2                	cmp    %eax,%edx
f0103ae3:	73 04                	jae    f0103ae9 <debuginfo_eip+0x24c>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103ae5:	01 f2                	add    %esi,%edx
f0103ae7:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ae9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103aec:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103aef:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103af4:	39 f2                	cmp    %esi,%edx
f0103af6:	7d 67                	jge    f0103b5f <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
f0103af8:	83 c2 01             	add    $0x1,%edx
f0103afb:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103afe:	89 d0                	mov    %edx,%eax
f0103b00:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103b03:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b06:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103b09:	eb 04                	jmp    f0103b0f <debuginfo_eip+0x272>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103b0b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103b0f:	39 c6                	cmp    %eax,%esi
f0103b11:	7e 47                	jle    f0103b5a <debuginfo_eip+0x2bd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103b13:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103b17:	83 c0 01             	add    $0x1,%eax
f0103b1a:	83 c2 0c             	add    $0xc,%edx
f0103b1d:	80 f9 a0             	cmp    $0xa0,%cl
f0103b20:	74 e9                	je     f0103b0b <debuginfo_eip+0x26e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b22:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b27:	eb 36                	jmp    f0103b5f <debuginfo_eip+0x2c2>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
                        return -1;
f0103b29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b2e:	eb 2f                	jmp    f0103b5f <debuginfo_eip+0x2c2>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
			return -1;
f0103b30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b35:	eb 28                	jmp    f0103b5f <debuginfo_eip+0x2c2>

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f0103b37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b3c:	eb 21                	jmp    f0103b5f <debuginfo_eip+0x2c2>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b43:	eb 1a                	jmp    f0103b5f <debuginfo_eip+0x2c2>
f0103b45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b4a:	eb 13                	jmp    f0103b5f <debuginfo_eip+0x2c2>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b51:	eb 0c                	jmp    f0103b5f <debuginfo_eip+0x2c2>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0103b53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b58:	eb 05                	jmp    f0103b5f <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b62:	5b                   	pop    %ebx
f0103b63:	5e                   	pop    %esi
f0103b64:	5f                   	pop    %edi
f0103b65:	5d                   	pop    %ebp
f0103b66:	c3                   	ret    

f0103b67 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b67:	55                   	push   %ebp
f0103b68:	89 e5                	mov    %esp,%ebp
f0103b6a:	57                   	push   %edi
f0103b6b:	56                   	push   %esi
f0103b6c:	53                   	push   %ebx
f0103b6d:	83 ec 1c             	sub    $0x1c,%esp
f0103b70:	89 c7                	mov    %eax,%edi
f0103b72:	89 d6                	mov    %edx,%esi
f0103b74:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b77:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b7a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b7d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b80:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b83:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b88:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b8b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b8e:	39 d3                	cmp    %edx,%ebx
f0103b90:	72 05                	jb     f0103b97 <printnum+0x30>
f0103b92:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b95:	77 45                	ja     f0103bdc <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b97:	83 ec 0c             	sub    $0xc,%esp
f0103b9a:	ff 75 18             	pushl  0x18(%ebp)
f0103b9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ba0:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103ba3:	53                   	push   %ebx
f0103ba4:	ff 75 10             	pushl  0x10(%ebp)
f0103ba7:	83 ec 08             	sub    $0x8,%esp
f0103baa:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bad:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bb0:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bb3:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bb6:	e8 45 09 00 00       	call   f0104500 <__udivdi3>
f0103bbb:	83 c4 18             	add    $0x18,%esp
f0103bbe:	52                   	push   %edx
f0103bbf:	50                   	push   %eax
f0103bc0:	89 f2                	mov    %esi,%edx
f0103bc2:	89 f8                	mov    %edi,%eax
f0103bc4:	e8 9e ff ff ff       	call   f0103b67 <printnum>
f0103bc9:	83 c4 20             	add    $0x20,%esp
f0103bcc:	eb 18                	jmp    f0103be6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103bce:	83 ec 08             	sub    $0x8,%esp
f0103bd1:	56                   	push   %esi
f0103bd2:	ff 75 18             	pushl  0x18(%ebp)
f0103bd5:	ff d7                	call   *%edi
f0103bd7:	83 c4 10             	add    $0x10,%esp
f0103bda:	eb 03                	jmp    f0103bdf <printnum+0x78>
f0103bdc:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103bdf:	83 eb 01             	sub    $0x1,%ebx
f0103be2:	85 db                	test   %ebx,%ebx
f0103be4:	7f e8                	jg     f0103bce <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103be6:	83 ec 08             	sub    $0x8,%esp
f0103be9:	56                   	push   %esi
f0103bea:	83 ec 04             	sub    $0x4,%esp
f0103bed:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bf0:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bf3:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bf6:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bf9:	e8 32 0a 00 00       	call   f0104630 <__umoddi3>
f0103bfe:	83 c4 14             	add    $0x14,%esp
f0103c01:	0f be 80 92 5c 10 f0 	movsbl -0xfefa36e(%eax),%eax
f0103c08:	50                   	push   %eax
f0103c09:	ff d7                	call   *%edi
}
f0103c0b:	83 c4 10             	add    $0x10,%esp
f0103c0e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c11:	5b                   	pop    %ebx
f0103c12:	5e                   	pop    %esi
f0103c13:	5f                   	pop    %edi
f0103c14:	5d                   	pop    %ebp
f0103c15:	c3                   	ret    

f0103c16 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103c16:	55                   	push   %ebp
f0103c17:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103c19:	83 fa 01             	cmp    $0x1,%edx
f0103c1c:	7e 0e                	jle    f0103c2c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103c1e:	8b 10                	mov    (%eax),%edx
f0103c20:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103c23:	89 08                	mov    %ecx,(%eax)
f0103c25:	8b 02                	mov    (%edx),%eax
f0103c27:	8b 52 04             	mov    0x4(%edx),%edx
f0103c2a:	eb 22                	jmp    f0103c4e <getuint+0x38>
	else if (lflag)
f0103c2c:	85 d2                	test   %edx,%edx
f0103c2e:	74 10                	je     f0103c40 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103c30:	8b 10                	mov    (%eax),%edx
f0103c32:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c35:	89 08                	mov    %ecx,(%eax)
f0103c37:	8b 02                	mov    (%edx),%eax
f0103c39:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c3e:	eb 0e                	jmp    f0103c4e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103c40:	8b 10                	mov    (%eax),%edx
f0103c42:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c45:	89 08                	mov    %ecx,(%eax)
f0103c47:	8b 02                	mov    (%edx),%eax
f0103c49:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c4e:	5d                   	pop    %ebp
f0103c4f:	c3                   	ret    

f0103c50 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c50:	55                   	push   %ebp
f0103c51:	89 e5                	mov    %esp,%ebp
f0103c53:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c56:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c5a:	8b 10                	mov    (%eax),%edx
f0103c5c:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c5f:	73 0a                	jae    f0103c6b <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c61:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c64:	89 08                	mov    %ecx,(%eax)
f0103c66:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c69:	88 02                	mov    %al,(%edx)
}
f0103c6b:	5d                   	pop    %ebp
f0103c6c:	c3                   	ret    

f0103c6d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c6d:	55                   	push   %ebp
f0103c6e:	89 e5                	mov    %esp,%ebp
f0103c70:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c73:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c76:	50                   	push   %eax
f0103c77:	ff 75 10             	pushl  0x10(%ebp)
f0103c7a:	ff 75 0c             	pushl  0xc(%ebp)
f0103c7d:	ff 75 08             	pushl  0x8(%ebp)
f0103c80:	e8 05 00 00 00       	call   f0103c8a <vprintfmt>
	va_end(ap);
}
f0103c85:	83 c4 10             	add    $0x10,%esp
f0103c88:	c9                   	leave  
f0103c89:	c3                   	ret    

f0103c8a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c8a:	55                   	push   %ebp
f0103c8b:	89 e5                	mov    %esp,%ebp
f0103c8d:	57                   	push   %edi
f0103c8e:	56                   	push   %esi
f0103c8f:	53                   	push   %ebx
f0103c90:	83 ec 2c             	sub    $0x2c,%esp
f0103c93:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c96:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c99:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c9c:	eb 12                	jmp    f0103cb0 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c9e:	85 c0                	test   %eax,%eax
f0103ca0:	0f 84 89 03 00 00    	je     f010402f <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103ca6:	83 ec 08             	sub    $0x8,%esp
f0103ca9:	53                   	push   %ebx
f0103caa:	50                   	push   %eax
f0103cab:	ff d6                	call   *%esi
f0103cad:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103cb0:	83 c7 01             	add    $0x1,%edi
f0103cb3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103cb7:	83 f8 25             	cmp    $0x25,%eax
f0103cba:	75 e2                	jne    f0103c9e <vprintfmt+0x14>
f0103cbc:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103cc0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103cc7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103cce:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103cd5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cda:	eb 07                	jmp    f0103ce3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cdc:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103cdf:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ce3:	8d 47 01             	lea    0x1(%edi),%eax
f0103ce6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ce9:	0f b6 07             	movzbl (%edi),%eax
f0103cec:	0f b6 c8             	movzbl %al,%ecx
f0103cef:	83 e8 23             	sub    $0x23,%eax
f0103cf2:	3c 55                	cmp    $0x55,%al
f0103cf4:	0f 87 1a 03 00 00    	ja     f0104014 <vprintfmt+0x38a>
f0103cfa:	0f b6 c0             	movzbl %al,%eax
f0103cfd:	ff 24 85 1c 5d 10 f0 	jmp    *-0xfefa2e4(,%eax,4)
f0103d04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103d07:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103d0b:	eb d6                	jmp    f0103ce3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d10:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d15:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d18:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d1b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103d1f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103d22:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103d25:	83 fa 09             	cmp    $0x9,%edx
f0103d28:	77 39                	ja     f0103d63 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d2a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d2d:	eb e9                	jmp    f0103d18 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d2f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d32:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d35:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d38:	8b 00                	mov    (%eax),%eax
f0103d3a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d40:	eb 27                	jmp    f0103d69 <vprintfmt+0xdf>
f0103d42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d45:	85 c0                	test   %eax,%eax
f0103d47:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d4c:	0f 49 c8             	cmovns %eax,%ecx
f0103d4f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d55:	eb 8c                	jmp    f0103ce3 <vprintfmt+0x59>
f0103d57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d5a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d61:	eb 80                	jmp    f0103ce3 <vprintfmt+0x59>
f0103d63:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d66:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d69:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d6d:	0f 89 70 ff ff ff    	jns    f0103ce3 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d73:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d76:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d79:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d80:	e9 5e ff ff ff       	jmp    f0103ce3 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d85:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d88:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d8b:	e9 53 ff ff ff       	jmp    f0103ce3 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d90:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d93:	8d 50 04             	lea    0x4(%eax),%edx
f0103d96:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d99:	83 ec 08             	sub    $0x8,%esp
f0103d9c:	53                   	push   %ebx
f0103d9d:	ff 30                	pushl  (%eax)
f0103d9f:	ff d6                	call   *%esi
			break;
f0103da1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103da4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103da7:	e9 04 ff ff ff       	jmp    f0103cb0 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dac:	8b 45 14             	mov    0x14(%ebp),%eax
f0103daf:	8d 50 04             	lea    0x4(%eax),%edx
f0103db2:	89 55 14             	mov    %edx,0x14(%ebp)
f0103db5:	8b 00                	mov    (%eax),%eax
f0103db7:	99                   	cltd   
f0103db8:	31 d0                	xor    %edx,%eax
f0103dba:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103dbc:	83 f8 06             	cmp    $0x6,%eax
f0103dbf:	7f 0b                	jg     f0103dcc <vprintfmt+0x142>
f0103dc1:	8b 14 85 74 5e 10 f0 	mov    -0xfefa18c(,%eax,4),%edx
f0103dc8:	85 d2                	test   %edx,%edx
f0103dca:	75 18                	jne    f0103de4 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103dcc:	50                   	push   %eax
f0103dcd:	68 aa 5c 10 f0       	push   $0xf0105caa
f0103dd2:	53                   	push   %ebx
f0103dd3:	56                   	push   %esi
f0103dd4:	e8 94 fe ff ff       	call   f0103c6d <printfmt>
f0103dd9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ddc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103ddf:	e9 cc fe ff ff       	jmp    f0103cb0 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103de4:	52                   	push   %edx
f0103de5:	68 09 55 10 f0       	push   $0xf0105509
f0103dea:	53                   	push   %ebx
f0103deb:	56                   	push   %esi
f0103dec:	e8 7c fe ff ff       	call   f0103c6d <printfmt>
f0103df1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103df4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103df7:	e9 b4 fe ff ff       	jmp    f0103cb0 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103dfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dff:	8d 50 04             	lea    0x4(%eax),%edx
f0103e02:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e05:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103e07:	85 ff                	test   %edi,%edi
f0103e09:	b8 a3 5c 10 f0       	mov    $0xf0105ca3,%eax
f0103e0e:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103e11:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e15:	0f 8e 94 00 00 00    	jle    f0103eaf <vprintfmt+0x225>
f0103e1b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103e1f:	0f 84 98 00 00 00    	je     f0103ebd <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e25:	83 ec 08             	sub    $0x8,%esp
f0103e28:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e2b:	57                   	push   %edi
f0103e2c:	e8 5f 03 00 00       	call   f0104190 <strnlen>
f0103e31:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e34:	29 c1                	sub    %eax,%ecx
f0103e36:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103e39:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e3c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e40:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e43:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e46:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e48:	eb 0f                	jmp    f0103e59 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103e4a:	83 ec 08             	sub    $0x8,%esp
f0103e4d:	53                   	push   %ebx
f0103e4e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e51:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e53:	83 ef 01             	sub    $0x1,%edi
f0103e56:	83 c4 10             	add    $0x10,%esp
f0103e59:	85 ff                	test   %edi,%edi
f0103e5b:	7f ed                	jg     f0103e4a <vprintfmt+0x1c0>
f0103e5d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e60:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103e63:	85 c9                	test   %ecx,%ecx
f0103e65:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e6a:	0f 49 c1             	cmovns %ecx,%eax
f0103e6d:	29 c1                	sub    %eax,%ecx
f0103e6f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e72:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e75:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e78:	89 cb                	mov    %ecx,%ebx
f0103e7a:	eb 4d                	jmp    f0103ec9 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e7c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e80:	74 1b                	je     f0103e9d <vprintfmt+0x213>
f0103e82:	0f be c0             	movsbl %al,%eax
f0103e85:	83 e8 20             	sub    $0x20,%eax
f0103e88:	83 f8 5e             	cmp    $0x5e,%eax
f0103e8b:	76 10                	jbe    f0103e9d <vprintfmt+0x213>
					putch('?', putdat);
f0103e8d:	83 ec 08             	sub    $0x8,%esp
f0103e90:	ff 75 0c             	pushl  0xc(%ebp)
f0103e93:	6a 3f                	push   $0x3f
f0103e95:	ff 55 08             	call   *0x8(%ebp)
f0103e98:	83 c4 10             	add    $0x10,%esp
f0103e9b:	eb 0d                	jmp    f0103eaa <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103e9d:	83 ec 08             	sub    $0x8,%esp
f0103ea0:	ff 75 0c             	pushl  0xc(%ebp)
f0103ea3:	52                   	push   %edx
f0103ea4:	ff 55 08             	call   *0x8(%ebp)
f0103ea7:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103eaa:	83 eb 01             	sub    $0x1,%ebx
f0103ead:	eb 1a                	jmp    f0103ec9 <vprintfmt+0x23f>
f0103eaf:	89 75 08             	mov    %esi,0x8(%ebp)
f0103eb2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103eb5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103eb8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ebb:	eb 0c                	jmp    f0103ec9 <vprintfmt+0x23f>
f0103ebd:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ec0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ec3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ec6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ec9:	83 c7 01             	add    $0x1,%edi
f0103ecc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ed0:	0f be d0             	movsbl %al,%edx
f0103ed3:	85 d2                	test   %edx,%edx
f0103ed5:	74 23                	je     f0103efa <vprintfmt+0x270>
f0103ed7:	85 f6                	test   %esi,%esi
f0103ed9:	78 a1                	js     f0103e7c <vprintfmt+0x1f2>
f0103edb:	83 ee 01             	sub    $0x1,%esi
f0103ede:	79 9c                	jns    f0103e7c <vprintfmt+0x1f2>
f0103ee0:	89 df                	mov    %ebx,%edi
f0103ee2:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ee5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ee8:	eb 18                	jmp    f0103f02 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103eea:	83 ec 08             	sub    $0x8,%esp
f0103eed:	53                   	push   %ebx
f0103eee:	6a 20                	push   $0x20
f0103ef0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ef2:	83 ef 01             	sub    $0x1,%edi
f0103ef5:	83 c4 10             	add    $0x10,%esp
f0103ef8:	eb 08                	jmp    f0103f02 <vprintfmt+0x278>
f0103efa:	89 df                	mov    %ebx,%edi
f0103efc:	8b 75 08             	mov    0x8(%ebp),%esi
f0103eff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f02:	85 ff                	test   %edi,%edi
f0103f04:	7f e4                	jg     f0103eea <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f06:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f09:	e9 a2 fd ff ff       	jmp    f0103cb0 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f0e:	83 fa 01             	cmp    $0x1,%edx
f0103f11:	7e 16                	jle    f0103f29 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103f13:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f16:	8d 50 08             	lea    0x8(%eax),%edx
f0103f19:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f1c:	8b 50 04             	mov    0x4(%eax),%edx
f0103f1f:	8b 00                	mov    (%eax),%eax
f0103f21:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f24:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103f27:	eb 32                	jmp    f0103f5b <vprintfmt+0x2d1>
	else if (lflag)
f0103f29:	85 d2                	test   %edx,%edx
f0103f2b:	74 18                	je     f0103f45 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103f2d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f30:	8d 50 04             	lea    0x4(%eax),%edx
f0103f33:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f36:	8b 00                	mov    (%eax),%eax
f0103f38:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f3b:	89 c1                	mov    %eax,%ecx
f0103f3d:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f40:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f43:	eb 16                	jmp    f0103f5b <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103f45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f48:	8d 50 04             	lea    0x4(%eax),%edx
f0103f4b:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f4e:	8b 00                	mov    (%eax),%eax
f0103f50:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f53:	89 c1                	mov    %eax,%ecx
f0103f55:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f58:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f5b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f5e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f61:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f66:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f6a:	79 74                	jns    f0103fe0 <vprintfmt+0x356>
				putch('-', putdat);
f0103f6c:	83 ec 08             	sub    $0x8,%esp
f0103f6f:	53                   	push   %ebx
f0103f70:	6a 2d                	push   $0x2d
f0103f72:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f74:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f77:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f7a:	f7 d8                	neg    %eax
f0103f7c:	83 d2 00             	adc    $0x0,%edx
f0103f7f:	f7 da                	neg    %edx
f0103f81:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f84:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103f89:	eb 55                	jmp    f0103fe0 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103f8b:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f8e:	e8 83 fc ff ff       	call   f0103c16 <getuint>
			base = 10;
f0103f93:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103f98:	eb 46                	jmp    f0103fe0 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103f9a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f9d:	e8 74 fc ff ff       	call   f0103c16 <getuint>
			base = 8;
f0103fa2:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103fa7:	eb 37                	jmp    f0103fe0 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103fa9:	83 ec 08             	sub    $0x8,%esp
f0103fac:	53                   	push   %ebx
f0103fad:	6a 30                	push   $0x30
f0103faf:	ff d6                	call   *%esi
			putch('x', putdat);
f0103fb1:	83 c4 08             	add    $0x8,%esp
f0103fb4:	53                   	push   %ebx
f0103fb5:	6a 78                	push   $0x78
f0103fb7:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103fb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fbc:	8d 50 04             	lea    0x4(%eax),%edx
f0103fbf:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103fc2:	8b 00                	mov    (%eax),%eax
f0103fc4:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103fc9:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103fcc:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103fd1:	eb 0d                	jmp    f0103fe0 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103fd3:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fd6:	e8 3b fc ff ff       	call   f0103c16 <getuint>
			base = 16;
f0103fdb:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103fe0:	83 ec 0c             	sub    $0xc,%esp
f0103fe3:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103fe7:	57                   	push   %edi
f0103fe8:	ff 75 e0             	pushl  -0x20(%ebp)
f0103feb:	51                   	push   %ecx
f0103fec:	52                   	push   %edx
f0103fed:	50                   	push   %eax
f0103fee:	89 da                	mov    %ebx,%edx
f0103ff0:	89 f0                	mov    %esi,%eax
f0103ff2:	e8 70 fb ff ff       	call   f0103b67 <printnum>
			break;
f0103ff7:	83 c4 20             	add    $0x20,%esp
f0103ffa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ffd:	e9 ae fc ff ff       	jmp    f0103cb0 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104002:	83 ec 08             	sub    $0x8,%esp
f0104005:	53                   	push   %ebx
f0104006:	51                   	push   %ecx
f0104007:	ff d6                	call   *%esi
			break;
f0104009:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010400c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010400f:	e9 9c fc ff ff       	jmp    f0103cb0 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104014:	83 ec 08             	sub    $0x8,%esp
f0104017:	53                   	push   %ebx
f0104018:	6a 25                	push   $0x25
f010401a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010401c:	83 c4 10             	add    $0x10,%esp
f010401f:	eb 03                	jmp    f0104024 <vprintfmt+0x39a>
f0104021:	83 ef 01             	sub    $0x1,%edi
f0104024:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104028:	75 f7                	jne    f0104021 <vprintfmt+0x397>
f010402a:	e9 81 fc ff ff       	jmp    f0103cb0 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010402f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104032:	5b                   	pop    %ebx
f0104033:	5e                   	pop    %esi
f0104034:	5f                   	pop    %edi
f0104035:	5d                   	pop    %ebp
f0104036:	c3                   	ret    

f0104037 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104037:	55                   	push   %ebp
f0104038:	89 e5                	mov    %esp,%ebp
f010403a:	83 ec 18             	sub    $0x18,%esp
f010403d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104040:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104043:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104046:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010404a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010404d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104054:	85 c0                	test   %eax,%eax
f0104056:	74 26                	je     f010407e <vsnprintf+0x47>
f0104058:	85 d2                	test   %edx,%edx
f010405a:	7e 22                	jle    f010407e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010405c:	ff 75 14             	pushl  0x14(%ebp)
f010405f:	ff 75 10             	pushl  0x10(%ebp)
f0104062:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104065:	50                   	push   %eax
f0104066:	68 50 3c 10 f0       	push   $0xf0103c50
f010406b:	e8 1a fc ff ff       	call   f0103c8a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104070:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104073:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104076:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104079:	83 c4 10             	add    $0x10,%esp
f010407c:	eb 05                	jmp    f0104083 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010407e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104083:	c9                   	leave  
f0104084:	c3                   	ret    

f0104085 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104085:	55                   	push   %ebp
f0104086:	89 e5                	mov    %esp,%ebp
f0104088:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010408b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010408e:	50                   	push   %eax
f010408f:	ff 75 10             	pushl  0x10(%ebp)
f0104092:	ff 75 0c             	pushl  0xc(%ebp)
f0104095:	ff 75 08             	pushl  0x8(%ebp)
f0104098:	e8 9a ff ff ff       	call   f0104037 <vsnprintf>
	va_end(ap);

	return rc;
}
f010409d:	c9                   	leave  
f010409e:	c3                   	ret    

f010409f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010409f:	55                   	push   %ebp
f01040a0:	89 e5                	mov    %esp,%ebp
f01040a2:	57                   	push   %edi
f01040a3:	56                   	push   %esi
f01040a4:	53                   	push   %ebx
f01040a5:	83 ec 0c             	sub    $0xc,%esp
f01040a8:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01040ab:	85 c0                	test   %eax,%eax
f01040ad:	74 11                	je     f01040c0 <readline+0x21>
		cprintf("%s", prompt);
f01040af:	83 ec 08             	sub    $0x8,%esp
f01040b2:	50                   	push   %eax
f01040b3:	68 09 55 10 f0       	push   $0xf0105509
f01040b8:	e8 5f ee ff ff       	call   f0102f1c <cprintf>
f01040bd:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01040c0:	83 ec 0c             	sub    $0xc,%esp
f01040c3:	6a 00                	push   $0x0
f01040c5:	e8 6c c5 ff ff       	call   f0100636 <iscons>
f01040ca:	89 c7                	mov    %eax,%edi
f01040cc:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01040cf:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040d4:	e8 4c c5 ff ff       	call   f0100625 <getchar>
f01040d9:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01040db:	85 c0                	test   %eax,%eax
f01040dd:	79 18                	jns    f01040f7 <readline+0x58>
			cprintf("read error: %e\n", c);
f01040df:	83 ec 08             	sub    $0x8,%esp
f01040e2:	50                   	push   %eax
f01040e3:	68 90 5e 10 f0       	push   $0xf0105e90
f01040e8:	e8 2f ee ff ff       	call   f0102f1c <cprintf>
			return NULL;
f01040ed:	83 c4 10             	add    $0x10,%esp
f01040f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01040f5:	eb 79                	jmp    f0104170 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01040f7:	83 f8 08             	cmp    $0x8,%eax
f01040fa:	0f 94 c2             	sete   %dl
f01040fd:	83 f8 7f             	cmp    $0x7f,%eax
f0104100:	0f 94 c0             	sete   %al
f0104103:	08 c2                	or     %al,%dl
f0104105:	74 1a                	je     f0104121 <readline+0x82>
f0104107:	85 f6                	test   %esi,%esi
f0104109:	7e 16                	jle    f0104121 <readline+0x82>
			if (echoing)
f010410b:	85 ff                	test   %edi,%edi
f010410d:	74 0d                	je     f010411c <readline+0x7d>
				cputchar('\b');
f010410f:	83 ec 0c             	sub    $0xc,%esp
f0104112:	6a 08                	push   $0x8
f0104114:	e8 fc c4 ff ff       	call   f0100615 <cputchar>
f0104119:	83 c4 10             	add    $0x10,%esp
			i--;
f010411c:	83 ee 01             	sub    $0x1,%esi
f010411f:	eb b3                	jmp    f01040d4 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104121:	83 fb 1f             	cmp    $0x1f,%ebx
f0104124:	7e 23                	jle    f0104149 <readline+0xaa>
f0104126:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010412c:	7f 1b                	jg     f0104149 <readline+0xaa>
			if (echoing)
f010412e:	85 ff                	test   %edi,%edi
f0104130:	74 0c                	je     f010413e <readline+0x9f>
				cputchar(c);
f0104132:	83 ec 0c             	sub    $0xc,%esp
f0104135:	53                   	push   %ebx
f0104136:	e8 da c4 ff ff       	call   f0100615 <cputchar>
f010413b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010413e:	88 9e 40 28 17 f0    	mov    %bl,-0xfe8d7c0(%esi)
f0104144:	8d 76 01             	lea    0x1(%esi),%esi
f0104147:	eb 8b                	jmp    f01040d4 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104149:	83 fb 0a             	cmp    $0xa,%ebx
f010414c:	74 05                	je     f0104153 <readline+0xb4>
f010414e:	83 fb 0d             	cmp    $0xd,%ebx
f0104151:	75 81                	jne    f01040d4 <readline+0x35>
			if (echoing)
f0104153:	85 ff                	test   %edi,%edi
f0104155:	74 0d                	je     f0104164 <readline+0xc5>
				cputchar('\n');
f0104157:	83 ec 0c             	sub    $0xc,%esp
f010415a:	6a 0a                	push   $0xa
f010415c:	e8 b4 c4 ff ff       	call   f0100615 <cputchar>
f0104161:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104164:	c6 86 40 28 17 f0 00 	movb   $0x0,-0xfe8d7c0(%esi)
			return buf;
f010416b:	b8 40 28 17 f0       	mov    $0xf0172840,%eax
		}
	}
}
f0104170:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104173:	5b                   	pop    %ebx
f0104174:	5e                   	pop    %esi
f0104175:	5f                   	pop    %edi
f0104176:	5d                   	pop    %ebp
f0104177:	c3                   	ret    

f0104178 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104178:	55                   	push   %ebp
f0104179:	89 e5                	mov    %esp,%ebp
f010417b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010417e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104183:	eb 03                	jmp    f0104188 <strlen+0x10>
		n++;
f0104185:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104188:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010418c:	75 f7                	jne    f0104185 <strlen+0xd>
		n++;
	return n;
}
f010418e:	5d                   	pop    %ebp
f010418f:	c3                   	ret    

f0104190 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104190:	55                   	push   %ebp
f0104191:	89 e5                	mov    %esp,%ebp
f0104193:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104196:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104199:	ba 00 00 00 00       	mov    $0x0,%edx
f010419e:	eb 03                	jmp    f01041a3 <strnlen+0x13>
		n++;
f01041a0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041a3:	39 c2                	cmp    %eax,%edx
f01041a5:	74 08                	je     f01041af <strnlen+0x1f>
f01041a7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01041ab:	75 f3                	jne    f01041a0 <strnlen+0x10>
f01041ad:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01041af:	5d                   	pop    %ebp
f01041b0:	c3                   	ret    

f01041b1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041b1:	55                   	push   %ebp
f01041b2:	89 e5                	mov    %esp,%ebp
f01041b4:	53                   	push   %ebx
f01041b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01041b8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041bb:	89 c2                	mov    %eax,%edx
f01041bd:	83 c2 01             	add    $0x1,%edx
f01041c0:	83 c1 01             	add    $0x1,%ecx
f01041c3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01041c7:	88 5a ff             	mov    %bl,-0x1(%edx)
f01041ca:	84 db                	test   %bl,%bl
f01041cc:	75 ef                	jne    f01041bd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01041ce:	5b                   	pop    %ebx
f01041cf:	5d                   	pop    %ebp
f01041d0:	c3                   	ret    

f01041d1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01041d1:	55                   	push   %ebp
f01041d2:	89 e5                	mov    %esp,%ebp
f01041d4:	53                   	push   %ebx
f01041d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01041d8:	53                   	push   %ebx
f01041d9:	e8 9a ff ff ff       	call   f0104178 <strlen>
f01041de:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01041e1:	ff 75 0c             	pushl  0xc(%ebp)
f01041e4:	01 d8                	add    %ebx,%eax
f01041e6:	50                   	push   %eax
f01041e7:	e8 c5 ff ff ff       	call   f01041b1 <strcpy>
	return dst;
}
f01041ec:	89 d8                	mov    %ebx,%eax
f01041ee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041f1:	c9                   	leave  
f01041f2:	c3                   	ret    

f01041f3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01041f3:	55                   	push   %ebp
f01041f4:	89 e5                	mov    %esp,%ebp
f01041f6:	56                   	push   %esi
f01041f7:	53                   	push   %ebx
f01041f8:	8b 75 08             	mov    0x8(%ebp),%esi
f01041fb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041fe:	89 f3                	mov    %esi,%ebx
f0104200:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104203:	89 f2                	mov    %esi,%edx
f0104205:	eb 0f                	jmp    f0104216 <strncpy+0x23>
		*dst++ = *src;
f0104207:	83 c2 01             	add    $0x1,%edx
f010420a:	0f b6 01             	movzbl (%ecx),%eax
f010420d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104210:	80 39 01             	cmpb   $0x1,(%ecx)
f0104213:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104216:	39 da                	cmp    %ebx,%edx
f0104218:	75 ed                	jne    f0104207 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010421a:	89 f0                	mov    %esi,%eax
f010421c:	5b                   	pop    %ebx
f010421d:	5e                   	pop    %esi
f010421e:	5d                   	pop    %ebp
f010421f:	c3                   	ret    

f0104220 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104220:	55                   	push   %ebp
f0104221:	89 e5                	mov    %esp,%ebp
f0104223:	56                   	push   %esi
f0104224:	53                   	push   %ebx
f0104225:	8b 75 08             	mov    0x8(%ebp),%esi
f0104228:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010422b:	8b 55 10             	mov    0x10(%ebp),%edx
f010422e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104230:	85 d2                	test   %edx,%edx
f0104232:	74 21                	je     f0104255 <strlcpy+0x35>
f0104234:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104238:	89 f2                	mov    %esi,%edx
f010423a:	eb 09                	jmp    f0104245 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010423c:	83 c2 01             	add    $0x1,%edx
f010423f:	83 c1 01             	add    $0x1,%ecx
f0104242:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104245:	39 c2                	cmp    %eax,%edx
f0104247:	74 09                	je     f0104252 <strlcpy+0x32>
f0104249:	0f b6 19             	movzbl (%ecx),%ebx
f010424c:	84 db                	test   %bl,%bl
f010424e:	75 ec                	jne    f010423c <strlcpy+0x1c>
f0104250:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104252:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104255:	29 f0                	sub    %esi,%eax
}
f0104257:	5b                   	pop    %ebx
f0104258:	5e                   	pop    %esi
f0104259:	5d                   	pop    %ebp
f010425a:	c3                   	ret    

f010425b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010425b:	55                   	push   %ebp
f010425c:	89 e5                	mov    %esp,%ebp
f010425e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104261:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104264:	eb 06                	jmp    f010426c <strcmp+0x11>
		p++, q++;
f0104266:	83 c1 01             	add    $0x1,%ecx
f0104269:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010426c:	0f b6 01             	movzbl (%ecx),%eax
f010426f:	84 c0                	test   %al,%al
f0104271:	74 04                	je     f0104277 <strcmp+0x1c>
f0104273:	3a 02                	cmp    (%edx),%al
f0104275:	74 ef                	je     f0104266 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104277:	0f b6 c0             	movzbl %al,%eax
f010427a:	0f b6 12             	movzbl (%edx),%edx
f010427d:	29 d0                	sub    %edx,%eax
}
f010427f:	5d                   	pop    %ebp
f0104280:	c3                   	ret    

f0104281 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104281:	55                   	push   %ebp
f0104282:	89 e5                	mov    %esp,%ebp
f0104284:	53                   	push   %ebx
f0104285:	8b 45 08             	mov    0x8(%ebp),%eax
f0104288:	8b 55 0c             	mov    0xc(%ebp),%edx
f010428b:	89 c3                	mov    %eax,%ebx
f010428d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104290:	eb 06                	jmp    f0104298 <strncmp+0x17>
		n--, p++, q++;
f0104292:	83 c0 01             	add    $0x1,%eax
f0104295:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104298:	39 d8                	cmp    %ebx,%eax
f010429a:	74 15                	je     f01042b1 <strncmp+0x30>
f010429c:	0f b6 08             	movzbl (%eax),%ecx
f010429f:	84 c9                	test   %cl,%cl
f01042a1:	74 04                	je     f01042a7 <strncmp+0x26>
f01042a3:	3a 0a                	cmp    (%edx),%cl
f01042a5:	74 eb                	je     f0104292 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042a7:	0f b6 00             	movzbl (%eax),%eax
f01042aa:	0f b6 12             	movzbl (%edx),%edx
f01042ad:	29 d0                	sub    %edx,%eax
f01042af:	eb 05                	jmp    f01042b6 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01042b1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042b6:	5b                   	pop    %ebx
f01042b7:	5d                   	pop    %ebp
f01042b8:	c3                   	ret    

f01042b9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01042b9:	55                   	push   %ebp
f01042ba:	89 e5                	mov    %esp,%ebp
f01042bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01042bf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042c3:	eb 07                	jmp    f01042cc <strchr+0x13>
		if (*s == c)
f01042c5:	38 ca                	cmp    %cl,%dl
f01042c7:	74 0f                	je     f01042d8 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01042c9:	83 c0 01             	add    $0x1,%eax
f01042cc:	0f b6 10             	movzbl (%eax),%edx
f01042cf:	84 d2                	test   %dl,%dl
f01042d1:	75 f2                	jne    f01042c5 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01042d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042d8:	5d                   	pop    %ebp
f01042d9:	c3                   	ret    

f01042da <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01042da:	55                   	push   %ebp
f01042db:	89 e5                	mov    %esp,%ebp
f01042dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01042e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042e4:	eb 03                	jmp    f01042e9 <strfind+0xf>
f01042e6:	83 c0 01             	add    $0x1,%eax
f01042e9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01042ec:	38 ca                	cmp    %cl,%dl
f01042ee:	74 04                	je     f01042f4 <strfind+0x1a>
f01042f0:	84 d2                	test   %dl,%dl
f01042f2:	75 f2                	jne    f01042e6 <strfind+0xc>
			break;
	return (char *) s;
}
f01042f4:	5d                   	pop    %ebp
f01042f5:	c3                   	ret    

f01042f6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01042f6:	55                   	push   %ebp
f01042f7:	89 e5                	mov    %esp,%ebp
f01042f9:	57                   	push   %edi
f01042fa:	56                   	push   %esi
f01042fb:	53                   	push   %ebx
f01042fc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104302:	85 c9                	test   %ecx,%ecx
f0104304:	74 36                	je     f010433c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104306:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010430c:	75 28                	jne    f0104336 <memset+0x40>
f010430e:	f6 c1 03             	test   $0x3,%cl
f0104311:	75 23                	jne    f0104336 <memset+0x40>
		c &= 0xFF;
f0104313:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104317:	89 d3                	mov    %edx,%ebx
f0104319:	c1 e3 08             	shl    $0x8,%ebx
f010431c:	89 d6                	mov    %edx,%esi
f010431e:	c1 e6 18             	shl    $0x18,%esi
f0104321:	89 d0                	mov    %edx,%eax
f0104323:	c1 e0 10             	shl    $0x10,%eax
f0104326:	09 f0                	or     %esi,%eax
f0104328:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010432a:	89 d8                	mov    %ebx,%eax
f010432c:	09 d0                	or     %edx,%eax
f010432e:	c1 e9 02             	shr    $0x2,%ecx
f0104331:	fc                   	cld    
f0104332:	f3 ab                	rep stos %eax,%es:(%edi)
f0104334:	eb 06                	jmp    f010433c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104336:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104339:	fc                   	cld    
f010433a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010433c:	89 f8                	mov    %edi,%eax
f010433e:	5b                   	pop    %ebx
f010433f:	5e                   	pop    %esi
f0104340:	5f                   	pop    %edi
f0104341:	5d                   	pop    %ebp
f0104342:	c3                   	ret    

f0104343 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104343:	55                   	push   %ebp
f0104344:	89 e5                	mov    %esp,%ebp
f0104346:	57                   	push   %edi
f0104347:	56                   	push   %esi
f0104348:	8b 45 08             	mov    0x8(%ebp),%eax
f010434b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010434e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104351:	39 c6                	cmp    %eax,%esi
f0104353:	73 35                	jae    f010438a <memmove+0x47>
f0104355:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104358:	39 d0                	cmp    %edx,%eax
f010435a:	73 2e                	jae    f010438a <memmove+0x47>
		s += n;
		d += n;
f010435c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010435f:	89 d6                	mov    %edx,%esi
f0104361:	09 fe                	or     %edi,%esi
f0104363:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104369:	75 13                	jne    f010437e <memmove+0x3b>
f010436b:	f6 c1 03             	test   $0x3,%cl
f010436e:	75 0e                	jne    f010437e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104370:	83 ef 04             	sub    $0x4,%edi
f0104373:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104376:	c1 e9 02             	shr    $0x2,%ecx
f0104379:	fd                   	std    
f010437a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010437c:	eb 09                	jmp    f0104387 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010437e:	83 ef 01             	sub    $0x1,%edi
f0104381:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104384:	fd                   	std    
f0104385:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104387:	fc                   	cld    
f0104388:	eb 1d                	jmp    f01043a7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010438a:	89 f2                	mov    %esi,%edx
f010438c:	09 c2                	or     %eax,%edx
f010438e:	f6 c2 03             	test   $0x3,%dl
f0104391:	75 0f                	jne    f01043a2 <memmove+0x5f>
f0104393:	f6 c1 03             	test   $0x3,%cl
f0104396:	75 0a                	jne    f01043a2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104398:	c1 e9 02             	shr    $0x2,%ecx
f010439b:	89 c7                	mov    %eax,%edi
f010439d:	fc                   	cld    
f010439e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043a0:	eb 05                	jmp    f01043a7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01043a2:	89 c7                	mov    %eax,%edi
f01043a4:	fc                   	cld    
f01043a5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01043a7:	5e                   	pop    %esi
f01043a8:	5f                   	pop    %edi
f01043a9:	5d                   	pop    %ebp
f01043aa:	c3                   	ret    

f01043ab <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01043ab:	55                   	push   %ebp
f01043ac:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01043ae:	ff 75 10             	pushl  0x10(%ebp)
f01043b1:	ff 75 0c             	pushl  0xc(%ebp)
f01043b4:	ff 75 08             	pushl  0x8(%ebp)
f01043b7:	e8 87 ff ff ff       	call   f0104343 <memmove>
}
f01043bc:	c9                   	leave  
f01043bd:	c3                   	ret    

f01043be <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01043be:	55                   	push   %ebp
f01043bf:	89 e5                	mov    %esp,%ebp
f01043c1:	56                   	push   %esi
f01043c2:	53                   	push   %ebx
f01043c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01043c6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043c9:	89 c6                	mov    %eax,%esi
f01043cb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043ce:	eb 1a                	jmp    f01043ea <memcmp+0x2c>
		if (*s1 != *s2)
f01043d0:	0f b6 08             	movzbl (%eax),%ecx
f01043d3:	0f b6 1a             	movzbl (%edx),%ebx
f01043d6:	38 d9                	cmp    %bl,%cl
f01043d8:	74 0a                	je     f01043e4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01043da:	0f b6 c1             	movzbl %cl,%eax
f01043dd:	0f b6 db             	movzbl %bl,%ebx
f01043e0:	29 d8                	sub    %ebx,%eax
f01043e2:	eb 0f                	jmp    f01043f3 <memcmp+0x35>
		s1++, s2++;
f01043e4:	83 c0 01             	add    $0x1,%eax
f01043e7:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043ea:	39 f0                	cmp    %esi,%eax
f01043ec:	75 e2                	jne    f01043d0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01043ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043f3:	5b                   	pop    %ebx
f01043f4:	5e                   	pop    %esi
f01043f5:	5d                   	pop    %ebp
f01043f6:	c3                   	ret    

f01043f7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01043f7:	55                   	push   %ebp
f01043f8:	89 e5                	mov    %esp,%ebp
f01043fa:	53                   	push   %ebx
f01043fb:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01043fe:	89 c1                	mov    %eax,%ecx
f0104400:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104403:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104407:	eb 0a                	jmp    f0104413 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104409:	0f b6 10             	movzbl (%eax),%edx
f010440c:	39 da                	cmp    %ebx,%edx
f010440e:	74 07                	je     f0104417 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104410:	83 c0 01             	add    $0x1,%eax
f0104413:	39 c8                	cmp    %ecx,%eax
f0104415:	72 f2                	jb     f0104409 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104417:	5b                   	pop    %ebx
f0104418:	5d                   	pop    %ebp
f0104419:	c3                   	ret    

f010441a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010441a:	55                   	push   %ebp
f010441b:	89 e5                	mov    %esp,%ebp
f010441d:	57                   	push   %edi
f010441e:	56                   	push   %esi
f010441f:	53                   	push   %ebx
f0104420:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104423:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104426:	eb 03                	jmp    f010442b <strtol+0x11>
		s++;
f0104428:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010442b:	0f b6 01             	movzbl (%ecx),%eax
f010442e:	3c 20                	cmp    $0x20,%al
f0104430:	74 f6                	je     f0104428 <strtol+0xe>
f0104432:	3c 09                	cmp    $0x9,%al
f0104434:	74 f2                	je     f0104428 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104436:	3c 2b                	cmp    $0x2b,%al
f0104438:	75 0a                	jne    f0104444 <strtol+0x2a>
		s++;
f010443a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010443d:	bf 00 00 00 00       	mov    $0x0,%edi
f0104442:	eb 11                	jmp    f0104455 <strtol+0x3b>
f0104444:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104449:	3c 2d                	cmp    $0x2d,%al
f010444b:	75 08                	jne    f0104455 <strtol+0x3b>
		s++, neg = 1;
f010444d:	83 c1 01             	add    $0x1,%ecx
f0104450:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104455:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010445b:	75 15                	jne    f0104472 <strtol+0x58>
f010445d:	80 39 30             	cmpb   $0x30,(%ecx)
f0104460:	75 10                	jne    f0104472 <strtol+0x58>
f0104462:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104466:	75 7c                	jne    f01044e4 <strtol+0xca>
		s += 2, base = 16;
f0104468:	83 c1 02             	add    $0x2,%ecx
f010446b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104470:	eb 16                	jmp    f0104488 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104472:	85 db                	test   %ebx,%ebx
f0104474:	75 12                	jne    f0104488 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104476:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010447b:	80 39 30             	cmpb   $0x30,(%ecx)
f010447e:	75 08                	jne    f0104488 <strtol+0x6e>
		s++, base = 8;
f0104480:	83 c1 01             	add    $0x1,%ecx
f0104483:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104488:	b8 00 00 00 00       	mov    $0x0,%eax
f010448d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104490:	0f b6 11             	movzbl (%ecx),%edx
f0104493:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104496:	89 f3                	mov    %esi,%ebx
f0104498:	80 fb 09             	cmp    $0x9,%bl
f010449b:	77 08                	ja     f01044a5 <strtol+0x8b>
			dig = *s - '0';
f010449d:	0f be d2             	movsbl %dl,%edx
f01044a0:	83 ea 30             	sub    $0x30,%edx
f01044a3:	eb 22                	jmp    f01044c7 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01044a5:	8d 72 9f             	lea    -0x61(%edx),%esi
f01044a8:	89 f3                	mov    %esi,%ebx
f01044aa:	80 fb 19             	cmp    $0x19,%bl
f01044ad:	77 08                	ja     f01044b7 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01044af:	0f be d2             	movsbl %dl,%edx
f01044b2:	83 ea 57             	sub    $0x57,%edx
f01044b5:	eb 10                	jmp    f01044c7 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01044b7:	8d 72 bf             	lea    -0x41(%edx),%esi
f01044ba:	89 f3                	mov    %esi,%ebx
f01044bc:	80 fb 19             	cmp    $0x19,%bl
f01044bf:	77 16                	ja     f01044d7 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01044c1:	0f be d2             	movsbl %dl,%edx
f01044c4:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01044c7:	3b 55 10             	cmp    0x10(%ebp),%edx
f01044ca:	7d 0b                	jge    f01044d7 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01044cc:	83 c1 01             	add    $0x1,%ecx
f01044cf:	0f af 45 10          	imul   0x10(%ebp),%eax
f01044d3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01044d5:	eb b9                	jmp    f0104490 <strtol+0x76>

	if (endptr)
f01044d7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01044db:	74 0d                	je     f01044ea <strtol+0xd0>
		*endptr = (char *) s;
f01044dd:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044e0:	89 0e                	mov    %ecx,(%esi)
f01044e2:	eb 06                	jmp    f01044ea <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044e4:	85 db                	test   %ebx,%ebx
f01044e6:	74 98                	je     f0104480 <strtol+0x66>
f01044e8:	eb 9e                	jmp    f0104488 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01044ea:	89 c2                	mov    %eax,%edx
f01044ec:	f7 da                	neg    %edx
f01044ee:	85 ff                	test   %edi,%edi
f01044f0:	0f 45 c2             	cmovne %edx,%eax
}
f01044f3:	5b                   	pop    %ebx
f01044f4:	5e                   	pop    %esi
f01044f5:	5f                   	pop    %edi
f01044f6:	5d                   	pop    %ebp
f01044f7:	c3                   	ret    
f01044f8:	66 90                	xchg   %ax,%ax
f01044fa:	66 90                	xchg   %ax,%ax
f01044fc:	66 90                	xchg   %ax,%ax
f01044fe:	66 90                	xchg   %ax,%ax

f0104500 <__udivdi3>:
f0104500:	55                   	push   %ebp
f0104501:	57                   	push   %edi
f0104502:	56                   	push   %esi
f0104503:	53                   	push   %ebx
f0104504:	83 ec 1c             	sub    $0x1c,%esp
f0104507:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010450b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010450f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104513:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104517:	85 f6                	test   %esi,%esi
f0104519:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010451d:	89 ca                	mov    %ecx,%edx
f010451f:	89 f8                	mov    %edi,%eax
f0104521:	75 3d                	jne    f0104560 <__udivdi3+0x60>
f0104523:	39 cf                	cmp    %ecx,%edi
f0104525:	0f 87 c5 00 00 00    	ja     f01045f0 <__udivdi3+0xf0>
f010452b:	85 ff                	test   %edi,%edi
f010452d:	89 fd                	mov    %edi,%ebp
f010452f:	75 0b                	jne    f010453c <__udivdi3+0x3c>
f0104531:	b8 01 00 00 00       	mov    $0x1,%eax
f0104536:	31 d2                	xor    %edx,%edx
f0104538:	f7 f7                	div    %edi
f010453a:	89 c5                	mov    %eax,%ebp
f010453c:	89 c8                	mov    %ecx,%eax
f010453e:	31 d2                	xor    %edx,%edx
f0104540:	f7 f5                	div    %ebp
f0104542:	89 c1                	mov    %eax,%ecx
f0104544:	89 d8                	mov    %ebx,%eax
f0104546:	89 cf                	mov    %ecx,%edi
f0104548:	f7 f5                	div    %ebp
f010454a:	89 c3                	mov    %eax,%ebx
f010454c:	89 d8                	mov    %ebx,%eax
f010454e:	89 fa                	mov    %edi,%edx
f0104550:	83 c4 1c             	add    $0x1c,%esp
f0104553:	5b                   	pop    %ebx
f0104554:	5e                   	pop    %esi
f0104555:	5f                   	pop    %edi
f0104556:	5d                   	pop    %ebp
f0104557:	c3                   	ret    
f0104558:	90                   	nop
f0104559:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104560:	39 ce                	cmp    %ecx,%esi
f0104562:	77 74                	ja     f01045d8 <__udivdi3+0xd8>
f0104564:	0f bd fe             	bsr    %esi,%edi
f0104567:	83 f7 1f             	xor    $0x1f,%edi
f010456a:	0f 84 98 00 00 00    	je     f0104608 <__udivdi3+0x108>
f0104570:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104575:	89 f9                	mov    %edi,%ecx
f0104577:	89 c5                	mov    %eax,%ebp
f0104579:	29 fb                	sub    %edi,%ebx
f010457b:	d3 e6                	shl    %cl,%esi
f010457d:	89 d9                	mov    %ebx,%ecx
f010457f:	d3 ed                	shr    %cl,%ebp
f0104581:	89 f9                	mov    %edi,%ecx
f0104583:	d3 e0                	shl    %cl,%eax
f0104585:	09 ee                	or     %ebp,%esi
f0104587:	89 d9                	mov    %ebx,%ecx
f0104589:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010458d:	89 d5                	mov    %edx,%ebp
f010458f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104593:	d3 ed                	shr    %cl,%ebp
f0104595:	89 f9                	mov    %edi,%ecx
f0104597:	d3 e2                	shl    %cl,%edx
f0104599:	89 d9                	mov    %ebx,%ecx
f010459b:	d3 e8                	shr    %cl,%eax
f010459d:	09 c2                	or     %eax,%edx
f010459f:	89 d0                	mov    %edx,%eax
f01045a1:	89 ea                	mov    %ebp,%edx
f01045a3:	f7 f6                	div    %esi
f01045a5:	89 d5                	mov    %edx,%ebp
f01045a7:	89 c3                	mov    %eax,%ebx
f01045a9:	f7 64 24 0c          	mull   0xc(%esp)
f01045ad:	39 d5                	cmp    %edx,%ebp
f01045af:	72 10                	jb     f01045c1 <__udivdi3+0xc1>
f01045b1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045b5:	89 f9                	mov    %edi,%ecx
f01045b7:	d3 e6                	shl    %cl,%esi
f01045b9:	39 c6                	cmp    %eax,%esi
f01045bb:	73 07                	jae    f01045c4 <__udivdi3+0xc4>
f01045bd:	39 d5                	cmp    %edx,%ebp
f01045bf:	75 03                	jne    f01045c4 <__udivdi3+0xc4>
f01045c1:	83 eb 01             	sub    $0x1,%ebx
f01045c4:	31 ff                	xor    %edi,%edi
f01045c6:	89 d8                	mov    %ebx,%eax
f01045c8:	89 fa                	mov    %edi,%edx
f01045ca:	83 c4 1c             	add    $0x1c,%esp
f01045cd:	5b                   	pop    %ebx
f01045ce:	5e                   	pop    %esi
f01045cf:	5f                   	pop    %edi
f01045d0:	5d                   	pop    %ebp
f01045d1:	c3                   	ret    
f01045d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01045d8:	31 ff                	xor    %edi,%edi
f01045da:	31 db                	xor    %ebx,%ebx
f01045dc:	89 d8                	mov    %ebx,%eax
f01045de:	89 fa                	mov    %edi,%edx
f01045e0:	83 c4 1c             	add    $0x1c,%esp
f01045e3:	5b                   	pop    %ebx
f01045e4:	5e                   	pop    %esi
f01045e5:	5f                   	pop    %edi
f01045e6:	5d                   	pop    %ebp
f01045e7:	c3                   	ret    
f01045e8:	90                   	nop
f01045e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045f0:	89 d8                	mov    %ebx,%eax
f01045f2:	f7 f7                	div    %edi
f01045f4:	31 ff                	xor    %edi,%edi
f01045f6:	89 c3                	mov    %eax,%ebx
f01045f8:	89 d8                	mov    %ebx,%eax
f01045fa:	89 fa                	mov    %edi,%edx
f01045fc:	83 c4 1c             	add    $0x1c,%esp
f01045ff:	5b                   	pop    %ebx
f0104600:	5e                   	pop    %esi
f0104601:	5f                   	pop    %edi
f0104602:	5d                   	pop    %ebp
f0104603:	c3                   	ret    
f0104604:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104608:	39 ce                	cmp    %ecx,%esi
f010460a:	72 0c                	jb     f0104618 <__udivdi3+0x118>
f010460c:	31 db                	xor    %ebx,%ebx
f010460e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104612:	0f 87 34 ff ff ff    	ja     f010454c <__udivdi3+0x4c>
f0104618:	bb 01 00 00 00       	mov    $0x1,%ebx
f010461d:	e9 2a ff ff ff       	jmp    f010454c <__udivdi3+0x4c>
f0104622:	66 90                	xchg   %ax,%ax
f0104624:	66 90                	xchg   %ax,%ax
f0104626:	66 90                	xchg   %ax,%ax
f0104628:	66 90                	xchg   %ax,%ax
f010462a:	66 90                	xchg   %ax,%ax
f010462c:	66 90                	xchg   %ax,%ax
f010462e:	66 90                	xchg   %ax,%ax

f0104630 <__umoddi3>:
f0104630:	55                   	push   %ebp
f0104631:	57                   	push   %edi
f0104632:	56                   	push   %esi
f0104633:	53                   	push   %ebx
f0104634:	83 ec 1c             	sub    $0x1c,%esp
f0104637:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010463b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010463f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104643:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104647:	85 d2                	test   %edx,%edx
f0104649:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010464d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104651:	89 f3                	mov    %esi,%ebx
f0104653:	89 3c 24             	mov    %edi,(%esp)
f0104656:	89 74 24 04          	mov    %esi,0x4(%esp)
f010465a:	75 1c                	jne    f0104678 <__umoddi3+0x48>
f010465c:	39 f7                	cmp    %esi,%edi
f010465e:	76 50                	jbe    f01046b0 <__umoddi3+0x80>
f0104660:	89 c8                	mov    %ecx,%eax
f0104662:	89 f2                	mov    %esi,%edx
f0104664:	f7 f7                	div    %edi
f0104666:	89 d0                	mov    %edx,%eax
f0104668:	31 d2                	xor    %edx,%edx
f010466a:	83 c4 1c             	add    $0x1c,%esp
f010466d:	5b                   	pop    %ebx
f010466e:	5e                   	pop    %esi
f010466f:	5f                   	pop    %edi
f0104670:	5d                   	pop    %ebp
f0104671:	c3                   	ret    
f0104672:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104678:	39 f2                	cmp    %esi,%edx
f010467a:	89 d0                	mov    %edx,%eax
f010467c:	77 52                	ja     f01046d0 <__umoddi3+0xa0>
f010467e:	0f bd ea             	bsr    %edx,%ebp
f0104681:	83 f5 1f             	xor    $0x1f,%ebp
f0104684:	75 5a                	jne    f01046e0 <__umoddi3+0xb0>
f0104686:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010468a:	0f 82 e0 00 00 00    	jb     f0104770 <__umoddi3+0x140>
f0104690:	39 0c 24             	cmp    %ecx,(%esp)
f0104693:	0f 86 d7 00 00 00    	jbe    f0104770 <__umoddi3+0x140>
f0104699:	8b 44 24 08          	mov    0x8(%esp),%eax
f010469d:	8b 54 24 04          	mov    0x4(%esp),%edx
f01046a1:	83 c4 1c             	add    $0x1c,%esp
f01046a4:	5b                   	pop    %ebx
f01046a5:	5e                   	pop    %esi
f01046a6:	5f                   	pop    %edi
f01046a7:	5d                   	pop    %ebp
f01046a8:	c3                   	ret    
f01046a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046b0:	85 ff                	test   %edi,%edi
f01046b2:	89 fd                	mov    %edi,%ebp
f01046b4:	75 0b                	jne    f01046c1 <__umoddi3+0x91>
f01046b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01046bb:	31 d2                	xor    %edx,%edx
f01046bd:	f7 f7                	div    %edi
f01046bf:	89 c5                	mov    %eax,%ebp
f01046c1:	89 f0                	mov    %esi,%eax
f01046c3:	31 d2                	xor    %edx,%edx
f01046c5:	f7 f5                	div    %ebp
f01046c7:	89 c8                	mov    %ecx,%eax
f01046c9:	f7 f5                	div    %ebp
f01046cb:	89 d0                	mov    %edx,%eax
f01046cd:	eb 99                	jmp    f0104668 <__umoddi3+0x38>
f01046cf:	90                   	nop
f01046d0:	89 c8                	mov    %ecx,%eax
f01046d2:	89 f2                	mov    %esi,%edx
f01046d4:	83 c4 1c             	add    $0x1c,%esp
f01046d7:	5b                   	pop    %ebx
f01046d8:	5e                   	pop    %esi
f01046d9:	5f                   	pop    %edi
f01046da:	5d                   	pop    %ebp
f01046db:	c3                   	ret    
f01046dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046e0:	8b 34 24             	mov    (%esp),%esi
f01046e3:	bf 20 00 00 00       	mov    $0x20,%edi
f01046e8:	89 e9                	mov    %ebp,%ecx
f01046ea:	29 ef                	sub    %ebp,%edi
f01046ec:	d3 e0                	shl    %cl,%eax
f01046ee:	89 f9                	mov    %edi,%ecx
f01046f0:	89 f2                	mov    %esi,%edx
f01046f2:	d3 ea                	shr    %cl,%edx
f01046f4:	89 e9                	mov    %ebp,%ecx
f01046f6:	09 c2                	or     %eax,%edx
f01046f8:	89 d8                	mov    %ebx,%eax
f01046fa:	89 14 24             	mov    %edx,(%esp)
f01046fd:	89 f2                	mov    %esi,%edx
f01046ff:	d3 e2                	shl    %cl,%edx
f0104701:	89 f9                	mov    %edi,%ecx
f0104703:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104707:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010470b:	d3 e8                	shr    %cl,%eax
f010470d:	89 e9                	mov    %ebp,%ecx
f010470f:	89 c6                	mov    %eax,%esi
f0104711:	d3 e3                	shl    %cl,%ebx
f0104713:	89 f9                	mov    %edi,%ecx
f0104715:	89 d0                	mov    %edx,%eax
f0104717:	d3 e8                	shr    %cl,%eax
f0104719:	89 e9                	mov    %ebp,%ecx
f010471b:	09 d8                	or     %ebx,%eax
f010471d:	89 d3                	mov    %edx,%ebx
f010471f:	89 f2                	mov    %esi,%edx
f0104721:	f7 34 24             	divl   (%esp)
f0104724:	89 d6                	mov    %edx,%esi
f0104726:	d3 e3                	shl    %cl,%ebx
f0104728:	f7 64 24 04          	mull   0x4(%esp)
f010472c:	39 d6                	cmp    %edx,%esi
f010472e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104732:	89 d1                	mov    %edx,%ecx
f0104734:	89 c3                	mov    %eax,%ebx
f0104736:	72 08                	jb     f0104740 <__umoddi3+0x110>
f0104738:	75 11                	jne    f010474b <__umoddi3+0x11b>
f010473a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010473e:	73 0b                	jae    f010474b <__umoddi3+0x11b>
f0104740:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104744:	1b 14 24             	sbb    (%esp),%edx
f0104747:	89 d1                	mov    %edx,%ecx
f0104749:	89 c3                	mov    %eax,%ebx
f010474b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010474f:	29 da                	sub    %ebx,%edx
f0104751:	19 ce                	sbb    %ecx,%esi
f0104753:	89 f9                	mov    %edi,%ecx
f0104755:	89 f0                	mov    %esi,%eax
f0104757:	d3 e0                	shl    %cl,%eax
f0104759:	89 e9                	mov    %ebp,%ecx
f010475b:	d3 ea                	shr    %cl,%edx
f010475d:	89 e9                	mov    %ebp,%ecx
f010475f:	d3 ee                	shr    %cl,%esi
f0104761:	09 d0                	or     %edx,%eax
f0104763:	89 f2                	mov    %esi,%edx
f0104765:	83 c4 1c             	add    $0x1c,%esp
f0104768:	5b                   	pop    %ebx
f0104769:	5e                   	pop    %esi
f010476a:	5f                   	pop    %edi
f010476b:	5d                   	pop    %ebp
f010476c:	c3                   	ret    
f010476d:	8d 76 00             	lea    0x0(%esi),%esi
f0104770:	29 f9                	sub    %edi,%ecx
f0104772:	19 d6                	sbb    %edx,%esi
f0104774:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104778:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010477c:	e9 18 ff ff ff       	jmp    f0104699 <__umoddi3+0x69>
