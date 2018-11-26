
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
f0100058:	e8 af 42 00 00       	call   f010430c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 47 10 f0       	push   $0xf01047a0
f010006f:	e8 bd 2e 00 00       	call   f0102f31 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 9c 10 00 00       	call   f0101115 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 fb 28 00 00       	call   f0102979 <env_init>
	trap_init();
f010007e:	e8 1f 2f 00 00       	call   f0102fa2 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 c6 fb 12 f0       	push   $0xf012fbc6
f010008d:	e8 95 2a 00 00       	call   f0102b27 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f010009b:	e8 c8 2d 00 00       	call   f0102e68 <env_run>

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
f01000ca:	e8 62 2e 00 00       	call   f0102f31 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 32 2e 00 00       	call   f0102f0b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 dc 4a 10 f0 	movl   $0xf0104adc,(%esp)
f01000e0:	e8 4c 2e 00 00       	call   f0102f31 <cprintf>
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
f010010c:	e8 20 2e 00 00       	call   f0102f31 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 ee 2d 00 00       	call   f0102f0b <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 dc 4a 10 f0 	movl   $0xf0104adc,(%esp)
f0100124:	e8 08 2e 00 00       	call   f0102f31 <cprintf>
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
f0100282:	e8 aa 2c 00 00       	call   f0102f31 <cprintf>
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
f0100431:	e8 23 3f 00 00       	call   f0104359 <memmove>
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
f0100605:	e8 27 29 00 00       	call   f0102f31 <cprintf>
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
f0100655:	e8 d7 28 00 00       	call   f0102f31 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0100662:	68 6c 4a 10 f0       	push   $0xf0104a6c
f0100667:	68 63 4a 10 f0       	push   $0xf0104a63
f010066c:	e8 c0 28 00 00       	call   f0102f31 <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 44 4b 10 f0       	push   $0xf0104b44
f0100679:	68 75 4a 10 f0       	push   $0xf0104a75
f010067e:	68 63 4a 10 f0       	push   $0xf0104a63
f0100683:	e8 a9 28 00 00       	call   f0102f31 <cprintf>
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
f010069a:	e8 92 28 00 00       	call   f0102f31 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 70 4b 10 f0       	push   $0xf0104b70
f01006ac:	e8 80 28 00 00       	call   f0102f31 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 98 4b 10 f0       	push   $0xf0104b98
f01006c3:	e8 69 28 00 00       	call   f0102f31 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 91 47 10 00       	push   $0x104791
f01006d0:	68 91 47 10 f0       	push   $0xf0104791
f01006d5:	68 bc 4b 10 f0       	push   $0xf0104bbc
f01006da:	e8 52 28 00 00       	call   f0102f31 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 1d 17 00       	push   $0x171d26
f01006e7:	68 26 1d 17 f0       	push   $0xf0171d26
f01006ec:	68 e0 4b 10 f0       	push   $0xf0104be0
f01006f1:	e8 3b 28 00 00       	call   f0102f31 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 2c 17 00       	push   $0x172c50
f01006fe:	68 50 2c 17 f0       	push   $0xf0172c50
f0100703:	68 04 4c 10 f0       	push   $0xf0104c04
f0100708:	e8 24 28 00 00       	call   f0102f31 <cprintf>
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
f0100733:	e8 f9 27 00 00       	call   f0102f31 <cprintf>
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
f010074f:	e8 dd 27 00 00       	call   f0102f31 <cprintf>
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
f010076c:	e8 c0 27 00 00       	call   f0102f31 <cprintf>
		cprintf("%08x ", *(ebp+2));
f0100771:	83 c4 08             	add    $0x8,%esp
f0100774:	ff 73 08             	pushl  0x8(%ebx)
f0100777:	68 c5 4a 10 f0       	push   $0xf0104ac5
f010077c:	e8 b0 27 00 00       	call   f0102f31 <cprintf>
		cprintf("%08x ", *(ebp+3));
f0100781:	83 c4 08             	add    $0x8,%esp
f0100784:	ff 73 0c             	pushl  0xc(%ebx)
f0100787:	68 c5 4a 10 f0       	push   $0xf0104ac5
f010078c:	e8 a0 27 00 00       	call   f0102f31 <cprintf>
		cprintf("%08x ", *(ebp+4));
f0100791:	83 c4 08             	add    $0x8,%esp
f0100794:	ff 73 10             	pushl  0x10(%ebx)
f0100797:	68 c5 4a 10 f0       	push   $0xf0104ac5
f010079c:	e8 90 27 00 00       	call   f0102f31 <cprintf>
		cprintf("%08x ", *(ebp+5));
f01007a1:	83 c4 08             	add    $0x8,%esp
f01007a4:	ff 73 14             	pushl  0x14(%ebx)
f01007a7:	68 c5 4a 10 f0       	push   $0xf0104ac5
f01007ac:	e8 80 27 00 00       	call   f0102f31 <cprintf>
		cprintf("%08x", *(ebp+6));
f01007b1:	83 c4 08             	add    $0x8,%esp
f01007b4:	ff 73 18             	pushl  0x18(%ebx)
f01007b7:	68 c1 59 10 f0       	push   $0xf01059c1
f01007bc:	e8 70 27 00 00       	call   f0102f31 <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01007c1:	83 c4 08             	add    $0x8,%esp
f01007c4:	57                   	push   %edi
f01007c5:	56                   	push   %esi
f01007c6:	e8 e8 30 00 00       	call   f01038b3 <debuginfo_eip>
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
f01007ea:	e8 42 27 00 00       	call   f0102f31 <cprintf>
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
f0100817:	e8 15 27 00 00       	call   f0102f31 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081c:	c7 04 24 78 4c 10 f0 	movl   $0xf0104c78,(%esp)
f0100823:	e8 09 27 00 00       	call   f0102f31 <cprintf>

	if (tf != NULL)
f0100828:	83 c4 10             	add    $0x10,%esp
f010082b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010082f:	74 0e                	je     f010083f <monitor+0x36>
		print_trapframe(tf);
f0100831:	83 ec 0c             	sub    $0xc,%esp
f0100834:	ff 75 08             	pushl  0x8(%ebp)
f0100837:	e8 2f 2b 00 00       	call   f010336b <print_trapframe>
f010083c:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010083f:	83 ec 0c             	sub    $0xc,%esp
f0100842:	68 de 4a 10 f0       	push   $0xf0104ade
f0100847:	e8 69 38 00 00       	call   f01040b5 <readline>
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
f0100880:	e8 4a 3a 00 00       	call   f01042cf <strchr>
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
f01008a0:	e8 8c 26 00 00       	call   f0102f31 <cprintf>
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
f01008c9:	e8 01 3a 00 00       	call   f01042cf <strchr>
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
f01008fc:	e8 70 39 00 00       	call   f0104271 <strcmp>
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
f010093c:	e8 f0 25 00 00       	call   f0102f31 <cprintf>
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
f010095c:	e8 69 25 00 00       	call   f0102eca <mc146818_read>
f0100961:	89 c6                	mov    %eax,%esi
f0100963:	83 c3 01             	add    $0x1,%ebx
f0100966:	89 1c 24             	mov    %ebx,(%esp)
f0100969:	e8 5c 25 00 00       	call   f0102eca <mc146818_read>
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
f01009a4:	68 56 03 00 00       	push   $0x356
f01009a9:	68 01 55 10 f0       	push   $0xf0105501
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
f0100a2a:	68 01 55 10 f0       	push   $0xf0105501
f0100a2f:	e8 6c f6 ff ff       	call   f01000a0 <_panic>

		if(PADDR(new) > 1024*1024*4) panic("boot_alloc: not enough memory!\n");
f0100a34:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100a3a:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100a40:	76 14                	jbe    f0100a56 <boot_alloc+0x78>
f0100a42:	83 ec 04             	sub    $0x4,%esp
f0100a45:	68 0c 4d 10 f0       	push   $0xf0104d0c
f0100a4a:	6a 74                	push   $0x74
f0100a4c:	68 01 55 10 f0       	push   $0xf0105501
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
f0100a7d:	68 92 02 00 00       	push   $0x292
f0100a82:	68 01 55 10 f0       	push   $0xf0105501
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
f0100b0e:	68 0d 55 10 f0       	push   $0xf010550d
f0100b13:	e8 88 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b18:	83 ec 04             	sub    $0x4,%esp
f0100b1b:	68 80 00 00 00       	push   $0x80
f0100b20:	68 97 00 00 00       	push   $0x97
f0100b25:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b2a:	50                   	push   %eax
f0100b2b:	e8 dc 37 00 00       	call   f010430c <memset>
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
f0100b71:	68 1b 55 10 f0       	push   $0xf010551b
f0100b76:	68 27 55 10 f0       	push   $0xf0105527
f0100b7b:	68 ac 02 00 00       	push   $0x2ac
f0100b80:	68 01 55 10 f0       	push   $0xf0105501
f0100b85:	e8 16 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b8a:	39 fa                	cmp    %edi,%edx
f0100b8c:	72 19                	jb     f0100ba7 <check_page_free_list+0x148>
f0100b8e:	68 3c 55 10 f0       	push   $0xf010553c
f0100b93:	68 27 55 10 f0       	push   $0xf0105527
f0100b98:	68 ad 02 00 00       	push   $0x2ad
f0100b9d:	68 01 55 10 f0       	push   $0xf0105501
f0100ba2:	e8 f9 f4 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ba7:	89 d0                	mov    %edx,%eax
f0100ba9:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100bac:	a8 07                	test   $0x7,%al
f0100bae:	74 19                	je     f0100bc9 <check_page_free_list+0x16a>
f0100bb0:	68 50 4d 10 f0       	push   $0xf0104d50
f0100bb5:	68 27 55 10 f0       	push   $0xf0105527
f0100bba:	68 ae 02 00 00       	push   $0x2ae
f0100bbf:	68 01 55 10 f0       	push   $0xf0105501
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
f0100bd3:	68 50 55 10 f0       	push   $0xf0105550
f0100bd8:	68 27 55 10 f0       	push   $0xf0105527
f0100bdd:	68 b1 02 00 00       	push   $0x2b1
f0100be2:	68 01 55 10 f0       	push   $0xf0105501
f0100be7:	e8 b4 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bec:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bf1:	75 19                	jne    f0100c0c <check_page_free_list+0x1ad>
f0100bf3:	68 61 55 10 f0       	push   $0xf0105561
f0100bf8:	68 27 55 10 f0       	push   $0xf0105527
f0100bfd:	68 b2 02 00 00       	push   $0x2b2
f0100c02:	68 01 55 10 f0       	push   $0xf0105501
f0100c07:	e8 94 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c0c:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c11:	75 19                	jne    f0100c2c <check_page_free_list+0x1cd>
f0100c13:	68 84 4d 10 f0       	push   $0xf0104d84
f0100c18:	68 27 55 10 f0       	push   $0xf0105527
f0100c1d:	68 b3 02 00 00       	push   $0x2b3
f0100c22:	68 01 55 10 f0       	push   $0xf0105501
f0100c27:	e8 74 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c2c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c31:	75 19                	jne    f0100c4c <check_page_free_list+0x1ed>
f0100c33:	68 7a 55 10 f0       	push   $0xf010557a
f0100c38:	68 27 55 10 f0       	push   $0xf0105527
f0100c3d:	68 b4 02 00 00       	push   $0x2b4
f0100c42:	68 01 55 10 f0       	push   $0xf0105501
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
f0100c65:	68 0d 55 10 f0       	push   $0xf010550d
f0100c6a:	e8 31 f4 ff ff       	call   f01000a0 <_panic>
f0100c6f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c74:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c77:	76 1e                	jbe    f0100c97 <check_page_free_list+0x238>
f0100c79:	68 a8 4d 10 f0       	push   $0xf0104da8
f0100c7e:	68 27 55 10 f0       	push   $0xf0105527
f0100c83:	68 b5 02 00 00       	push   $0x2b5
f0100c88:	68 01 55 10 f0       	push   $0xf0105501
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
f0100cac:	68 94 55 10 f0       	push   $0xf0105594
f0100cb1:	68 27 55 10 f0       	push   $0xf0105527
f0100cb6:	68 bd 02 00 00       	push   $0x2bd
f0100cbb:	68 01 55 10 f0       	push   $0xf0105501
f0100cc0:	e8 db f3 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100cc5:	85 db                	test   %ebx,%ebx
f0100cc7:	7f 19                	jg     f0100ce2 <check_page_free_list+0x283>
f0100cc9:	68 a6 55 10 f0       	push   $0xf01055a6
f0100cce:	68 27 55 10 f0       	push   $0xf0105527
f0100cd3:	68 be 02 00 00       	push   $0x2be
f0100cd8:	68 01 55 10 f0       	push   $0xf0105501
f0100cdd:	e8 be f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ce2:	83 ec 0c             	sub    $0xc,%esp
f0100ce5:	68 f0 4d 10 f0       	push   $0xf0104df0
f0100cea:	e8 42 22 00 00       	call   f0102f31 <cprintf>
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
f0100d89:	68 01 55 10 f0       	push   $0xf0105501
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
f0100e34:	68 0d 55 10 f0       	push   $0xf010550d
f0100e39:	e8 62 f2 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0100e3e:	83 ec 04             	sub    $0x4,%esp
f0100e41:	68 00 10 00 00       	push   $0x1000
f0100e46:	6a 00                	push   $0x0
f0100e48:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e4d:	50                   	push   %eax
f0100e4e:	e8 b9 34 00 00       	call   f010430c <memset>
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
	if((pp->pp_ref != 0) || (pp->pp_link != NULL)) 
f0100e66:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e6b:	75 05                	jne    f0100e72 <page_free+0x15>
f0100e6d:	83 38 00             	cmpl   $0x0,(%eax)
f0100e70:	74 17                	je     f0100e89 <page_free+0x2c>
		panic("page_free: cannot free the page which is still in use!\n");
f0100e72:	83 ec 04             	sub    $0x4,%esp
f0100e75:	68 14 4e 10 f0       	push   $0xf0104e14
f0100e7a:	68 64 01 00 00       	push   $0x164
f0100e7f:	68 01 55 10 f0       	push   $0xf0105501
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
f0100f37:	68 a4 01 00 00       	push   $0x1a4
f0100f3c:	68 01 55 10 f0       	push   $0xf0105501
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
f0100f65:	68 a8 01 00 00       	push   $0x1a8
f0100f6a:	68 01 55 10 f0       	push   $0xf0105501
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

		if(ptable_entry == NULL)
			panic("boot_map_region: Failed to allocate new PTE!");
		
		*ptable_entry = pa | perm | PTE_P;
f0100fb1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb4:	83 c8 01             	or     $0x1,%eax
f0100fb7:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100fba:	eb 3f                	jmp    f0100ffb <boot_map_region+0x6a>
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0100fbc:	83 ec 04             	sub    $0x4,%esp
f0100fbf:	6a 01                	push   $0x1
f0100fc1:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100fc4:	50                   	push   %eax
f0100fc5:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fc8:	e8 f2 fe ff ff       	call   f0100ebf <pgdir_walk>

		if(ptable_entry == NULL)
f0100fcd:	83 c4 10             	add    $0x10,%esp
f0100fd0:	85 c0                	test   %eax,%eax
f0100fd2:	75 17                	jne    f0100feb <boot_map_region+0x5a>
			panic("boot_map_region: Failed to allocate new PTE!");
f0100fd4:	83 ec 04             	sub    $0x4,%esp
f0100fd7:	68 4c 4e 10 f0       	push   $0xf0104e4c
f0100fdc:	68 c5 01 00 00       	push   $0x1c5
f0100fe1:	68 01 55 10 f0       	push   $0xf0105501
f0100fe6:	e8 b5 f0 ff ff       	call   f01000a0 <_panic>
		
		*ptable_entry = pa | perm | PTE_P;
f0100feb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fee:	09 da                	or     %ebx,%edx
f0100ff0:	89 10                	mov    %edx,(%eax)

		pa += PGSIZE;
f0100ff2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100ff8:	83 c6 01             	add    $0x1,%esi
f0100ffb:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100ffe:	75 bc                	jne    f0100fbc <boot_map_region+0x2b>

		pa += PGSIZE;
		va += PGSIZE;
	}
		
}
f0101000:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101003:	5b                   	pop    %ebx
f0101004:	5e                   	pop    %esi
f0101005:	5f                   	pop    %edi
f0101006:	5d                   	pop    %ebp
f0101007:	c3                   	ret    

f0101008 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101008:	55                   	push   %ebp
f0101009:	89 e5                	mov    %esp,%ebp
f010100b:	53                   	push   %ebx
f010100c:	83 ec 08             	sub    $0x8,%esp
f010100f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
f0101012:	6a 00                	push   $0x0
f0101014:	ff 75 0c             	pushl  0xc(%ebp)
f0101017:	ff 75 08             	pushl  0x8(%ebp)
f010101a:	e8 a0 fe ff ff       	call   f0100ebf <pgdir_walk>
	
	if(!ptEntry) 
f010101f:	83 c4 10             	add    $0x10,%esp
f0101022:	85 c0                	test   %eax,%eax
f0101024:	74 32                	je     f0101058 <page_lookup+0x50>
		return NULL;

	if(pte_store)
f0101026:	85 db                	test   %ebx,%ebx
f0101028:	74 02                	je     f010102c <page_lookup+0x24>
	{
		*pte_store = ptEntry;
f010102a:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010102c:	8b 00                	mov    (%eax),%eax
f010102e:	c1 e8 0c             	shr    $0xc,%eax
f0101031:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0101037:	72 14                	jb     f010104d <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101039:	83 ec 04             	sub    $0x4,%esp
f010103c:	68 7c 4e 10 f0       	push   $0xf0104e7c
f0101041:	6a 4f                	push   $0x4f
f0101043:	68 0d 55 10 f0       	push   $0xf010550d
f0101048:	e8 53 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f010104d:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0101053:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
f0101056:	eb 05                	jmp    f010105d <page_lookup+0x55>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
	
	if(!ptEntry) 
		return NULL;
f0101058:	b8 00 00 00 00       	mov    $0x0,%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
}
f010105d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101060:	c9                   	leave  
f0101061:	c3                   	ret    

f0101062 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101062:	55                   	push   %ebp
f0101063:	89 e5                	mov    %esp,%ebp
f0101065:	53                   	push   %ebx
f0101066:	83 ec 18             	sub    $0x18,%esp
f0101069:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = NULL;
f010106c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &ptEntry);
f0101073:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101076:	50                   	push   %eax
f0101077:	53                   	push   %ebx
f0101078:	ff 75 08             	pushl  0x8(%ebp)
f010107b:	e8 88 ff ff ff       	call   f0101008 <page_lookup>

	if(!page || !(*ptEntry & PTE_P)) 
f0101080:	83 c4 10             	add    $0x10,%esp
f0101083:	85 c0                	test   %eax,%eax
f0101085:	74 20                	je     f01010a7 <page_remove+0x45>
f0101087:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010108a:	f6 02 01             	testb  $0x1,(%edx)
f010108d:	74 18                	je     f01010a7 <page_remove+0x45>
		return;

	page_decref(page);
f010108f:	83 ec 0c             	sub    $0xc,%esp
f0101092:	50                   	push   %eax
f0101093:	e8 00 fe ff ff       	call   f0100e98 <page_decref>

	*ptEntry = 0;
f0101098:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010109b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010a1:	0f 01 3b             	invlpg (%ebx)
f01010a4:	83 c4 10             	add    $0x10,%esp

	tlb_invalidate(pgdir, va);
}
f01010a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010aa:	c9                   	leave  
f01010ab:	c3                   	ret    

f01010ac <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010ac:	55                   	push   %ebp
f01010ad:	89 e5                	mov    %esp,%ebp
f01010af:	57                   	push   %edi
f01010b0:	56                   	push   %esi
f01010b1:	53                   	push   %ebx
f01010b2:	83 ec 10             	sub    $0x10,%esp
f01010b5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010b8:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
f01010bb:	6a 01                	push   $0x1
f01010bd:	56                   	push   %esi
f01010be:	ff 75 08             	pushl  0x8(%ebp)
f01010c1:	e8 f9 fd ff ff       	call   f0100ebf <pgdir_walk>
	
	if(!ptEntry) 
f01010c6:	83 c4 10             	add    $0x10,%esp
f01010c9:	85 c0                	test   %eax,%eax
f01010cb:	74 3b                	je     f0101108 <page_insert+0x5c>
f01010cd:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;
	
	pp->pp_ref++;
f01010cf:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*ptEntry & PTE_P)
f01010d4:	f6 00 01             	testb  $0x1,(%eax)
f01010d7:	74 12                	je     f01010eb <page_insert+0x3f>
	{
		page_remove(pgdir, va);
f01010d9:	83 ec 08             	sub    $0x8,%esp
f01010dc:	56                   	push   %esi
f01010dd:	ff 75 08             	pushl  0x8(%ebp)
f01010e0:	e8 7d ff ff ff       	call   f0101062 <page_remove>
f01010e5:	0f 01 3e             	invlpg (%esi)
f01010e8:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;
f01010eb:	2b 1d 4c 2c 17 f0    	sub    0xf0172c4c,%ebx
f01010f1:	c1 fb 03             	sar    $0x3,%ebx
f01010f4:	c1 e3 0c             	shl    $0xc,%ebx
f01010f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010fa:	83 c8 01             	or     $0x1,%eax
f01010fd:	09 c3                	or     %eax,%ebx
f01010ff:	89 1f                	mov    %ebx,(%edi)

	return 0;
f0101101:	b8 00 00 00 00       	mov    $0x0,%eax
f0101106:	eb 05                	jmp    f010110d <page_insert+0x61>
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
	
	if(!ptEntry) 
		return -E_NO_MEM;
f0101108:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;

	return 0;
}
f010110d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101110:	5b                   	pop    %ebx
f0101111:	5e                   	pop    %esi
f0101112:	5f                   	pop    %edi
f0101113:	5d                   	pop    %ebp
f0101114:	c3                   	ret    

f0101115 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101115:	55                   	push   %ebp
f0101116:	89 e5                	mov    %esp,%ebp
f0101118:	57                   	push   %edi
f0101119:	56                   	push   %esi
f010111a:	53                   	push   %ebx
f010111b:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010111e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101123:	e8 29 f8 ff ff       	call   f0100951 <nvram_read>
f0101128:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010112a:	b8 17 00 00 00       	mov    $0x17,%eax
f010112f:	e8 1d f8 ff ff       	call   f0100951 <nvram_read>
f0101134:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101136:	b8 34 00 00 00       	mov    $0x34,%eax
f010113b:	e8 11 f8 ff ff       	call   f0100951 <nvram_read>
f0101140:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101143:	85 c0                	test   %eax,%eax
f0101145:	74 07                	je     f010114e <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101147:	05 00 40 00 00       	add    $0x4000,%eax
f010114c:	eb 0b                	jmp    f0101159 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010114e:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101154:	85 f6                	test   %esi,%esi
f0101156:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101159:	89 c2                	mov    %eax,%edx
f010115b:	c1 ea 02             	shr    $0x2,%edx
f010115e:	89 15 44 2c 17 f0    	mov    %edx,0xf0172c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101164:	89 c2                	mov    %eax,%edx
f0101166:	29 da                	sub    %ebx,%edx
f0101168:	52                   	push   %edx
f0101169:	53                   	push   %ebx
f010116a:	50                   	push   %eax
f010116b:	68 9c 4e 10 f0       	push   $0xf0104e9c
f0101170:	e8 bc 1d 00 00       	call   f0102f31 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101175:	b8 00 10 00 00       	mov    $0x1000,%eax
f010117a:	e8 5f f8 ff ff       	call   f01009de <boot_alloc>
f010117f:	a3 48 2c 17 f0       	mov    %eax,0xf0172c48
	memset(kern_pgdir, 0, PGSIZE);
f0101184:	83 c4 0c             	add    $0xc,%esp
f0101187:	68 00 10 00 00       	push   $0x1000
f010118c:	6a 00                	push   $0x0
f010118e:	50                   	push   %eax
f010118f:	e8 78 31 00 00       	call   f010430c <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101194:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101199:	83 c4 10             	add    $0x10,%esp
f010119c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01011a1:	77 15                	ja     f01011b8 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011a3:	50                   	push   %eax
f01011a4:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01011a9:	68 a0 00 00 00       	push   $0xa0
f01011ae:	68 01 55 10 f0       	push   $0xf0105501
f01011b3:	e8 e8 ee ff ff       	call   f01000a0 <_panic>
f01011b8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011be:	83 ca 05             	or     $0x5,%edx
f01011c1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof(struct PageInfo)*npages);
f01011c7:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f01011cc:	c1 e0 03             	shl    $0x3,%eax
f01011cf:	e8 0a f8 ff ff       	call   f01009de <boot_alloc>
f01011d4:	a3 4c 2c 17 f0       	mov    %eax,0xf0172c4c
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f01011d9:	83 ec 04             	sub    $0x4,%esp
f01011dc:	8b 3d 44 2c 17 f0    	mov    0xf0172c44,%edi
f01011e2:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01011e9:	52                   	push   %edx
f01011ea:	6a 00                	push   $0x0
f01011ec:	50                   	push   %eax
f01011ed:	e8 1a 31 00 00       	call   f010430c <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f01011f2:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011f7:	e8 e2 f7 ff ff       	call   f01009de <boot_alloc>
f01011fc:	a3 88 1f 17 f0       	mov    %eax,0xf0171f88
	memset(envs, '\0', sizeof(struct Env) * NENV);
f0101201:	83 c4 0c             	add    $0xc,%esp
f0101204:	68 00 80 01 00       	push   $0x18000
f0101209:	6a 00                	push   $0x0
f010120b:	50                   	push   %eax
f010120c:	e8 fb 30 00 00       	call   f010430c <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101211:	e8 0c fb ff ff       	call   f0100d22 <page_init>

	check_page_free_list(1);
f0101216:	b8 01 00 00 00       	mov    $0x1,%eax
f010121b:	e8 3f f8 ff ff       	call   f0100a5f <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101220:	83 c4 10             	add    $0x10,%esp
f0101223:	83 3d 4c 2c 17 f0 00 	cmpl   $0x0,0xf0172c4c
f010122a:	75 17                	jne    f0101243 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f010122c:	83 ec 04             	sub    $0x4,%esp
f010122f:	68 b7 55 10 f0       	push   $0xf01055b7
f0101234:	68 d1 02 00 00       	push   $0x2d1
f0101239:	68 01 55 10 f0       	push   $0xf0105501
f010123e:	e8 5d ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101243:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101248:	bb 00 00 00 00       	mov    $0x0,%ebx
f010124d:	eb 05                	jmp    f0101254 <mem_init+0x13f>
		++nfree;
f010124f:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101252:	8b 00                	mov    (%eax),%eax
f0101254:	85 c0                	test   %eax,%eax
f0101256:	75 f7                	jne    f010124f <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101258:	83 ec 0c             	sub    $0xc,%esp
f010125b:	6a 00                	push   $0x0
f010125d:	e8 8b fb ff ff       	call   f0100ded <page_alloc>
f0101262:	89 c7                	mov    %eax,%edi
f0101264:	83 c4 10             	add    $0x10,%esp
f0101267:	85 c0                	test   %eax,%eax
f0101269:	75 19                	jne    f0101284 <mem_init+0x16f>
f010126b:	68 d2 55 10 f0       	push   $0xf01055d2
f0101270:	68 27 55 10 f0       	push   $0xf0105527
f0101275:	68 d9 02 00 00       	push   $0x2d9
f010127a:	68 01 55 10 f0       	push   $0xf0105501
f010127f:	e8 1c ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101284:	83 ec 0c             	sub    $0xc,%esp
f0101287:	6a 00                	push   $0x0
f0101289:	e8 5f fb ff ff       	call   f0100ded <page_alloc>
f010128e:	89 c6                	mov    %eax,%esi
f0101290:	83 c4 10             	add    $0x10,%esp
f0101293:	85 c0                	test   %eax,%eax
f0101295:	75 19                	jne    f01012b0 <mem_init+0x19b>
f0101297:	68 e8 55 10 f0       	push   $0xf01055e8
f010129c:	68 27 55 10 f0       	push   $0xf0105527
f01012a1:	68 da 02 00 00       	push   $0x2da
f01012a6:	68 01 55 10 f0       	push   $0xf0105501
f01012ab:	e8 f0 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012b0:	83 ec 0c             	sub    $0xc,%esp
f01012b3:	6a 00                	push   $0x0
f01012b5:	e8 33 fb ff ff       	call   f0100ded <page_alloc>
f01012ba:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012bd:	83 c4 10             	add    $0x10,%esp
f01012c0:	85 c0                	test   %eax,%eax
f01012c2:	75 19                	jne    f01012dd <mem_init+0x1c8>
f01012c4:	68 fe 55 10 f0       	push   $0xf01055fe
f01012c9:	68 27 55 10 f0       	push   $0xf0105527
f01012ce:	68 db 02 00 00       	push   $0x2db
f01012d3:	68 01 55 10 f0       	push   $0xf0105501
f01012d8:	e8 c3 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012dd:	39 f7                	cmp    %esi,%edi
f01012df:	75 19                	jne    f01012fa <mem_init+0x1e5>
f01012e1:	68 14 56 10 f0       	push   $0xf0105614
f01012e6:	68 27 55 10 f0       	push   $0xf0105527
f01012eb:	68 de 02 00 00       	push   $0x2de
f01012f0:	68 01 55 10 f0       	push   $0xf0105501
f01012f5:	e8 a6 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012fd:	39 c6                	cmp    %eax,%esi
f01012ff:	74 04                	je     f0101305 <mem_init+0x1f0>
f0101301:	39 c7                	cmp    %eax,%edi
f0101303:	75 19                	jne    f010131e <mem_init+0x209>
f0101305:	68 d8 4e 10 f0       	push   $0xf0104ed8
f010130a:	68 27 55 10 f0       	push   $0xf0105527
f010130f:	68 df 02 00 00       	push   $0x2df
f0101314:	68 01 55 10 f0       	push   $0xf0105501
f0101319:	e8 82 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010131e:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101324:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f010132a:	c1 e2 0c             	shl    $0xc,%edx
f010132d:	89 f8                	mov    %edi,%eax
f010132f:	29 c8                	sub    %ecx,%eax
f0101331:	c1 f8 03             	sar    $0x3,%eax
f0101334:	c1 e0 0c             	shl    $0xc,%eax
f0101337:	39 d0                	cmp    %edx,%eax
f0101339:	72 19                	jb     f0101354 <mem_init+0x23f>
f010133b:	68 26 56 10 f0       	push   $0xf0105626
f0101340:	68 27 55 10 f0       	push   $0xf0105527
f0101345:	68 e0 02 00 00       	push   $0x2e0
f010134a:	68 01 55 10 f0       	push   $0xf0105501
f010134f:	e8 4c ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101354:	89 f0                	mov    %esi,%eax
f0101356:	29 c8                	sub    %ecx,%eax
f0101358:	c1 f8 03             	sar    $0x3,%eax
f010135b:	c1 e0 0c             	shl    $0xc,%eax
f010135e:	39 c2                	cmp    %eax,%edx
f0101360:	77 19                	ja     f010137b <mem_init+0x266>
f0101362:	68 43 56 10 f0       	push   $0xf0105643
f0101367:	68 27 55 10 f0       	push   $0xf0105527
f010136c:	68 e1 02 00 00       	push   $0x2e1
f0101371:	68 01 55 10 f0       	push   $0xf0105501
f0101376:	e8 25 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010137b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010137e:	29 c8                	sub    %ecx,%eax
f0101380:	c1 f8 03             	sar    $0x3,%eax
f0101383:	c1 e0 0c             	shl    $0xc,%eax
f0101386:	39 c2                	cmp    %eax,%edx
f0101388:	77 19                	ja     f01013a3 <mem_init+0x28e>
f010138a:	68 60 56 10 f0       	push   $0xf0105660
f010138f:	68 27 55 10 f0       	push   $0xf0105527
f0101394:	68 e2 02 00 00       	push   $0x2e2
f0101399:	68 01 55 10 f0       	push   $0xf0105501
f010139e:	e8 fd ec ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013a3:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f01013a8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01013ab:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f01013b2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013b5:	83 ec 0c             	sub    $0xc,%esp
f01013b8:	6a 00                	push   $0x0
f01013ba:	e8 2e fa ff ff       	call   f0100ded <page_alloc>
f01013bf:	83 c4 10             	add    $0x10,%esp
f01013c2:	85 c0                	test   %eax,%eax
f01013c4:	74 19                	je     f01013df <mem_init+0x2ca>
f01013c6:	68 7d 56 10 f0       	push   $0xf010567d
f01013cb:	68 27 55 10 f0       	push   $0xf0105527
f01013d0:	68 e9 02 00 00       	push   $0x2e9
f01013d5:	68 01 55 10 f0       	push   $0xf0105501
f01013da:	e8 c1 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013df:	83 ec 0c             	sub    $0xc,%esp
f01013e2:	57                   	push   %edi
f01013e3:	e8 75 fa ff ff       	call   f0100e5d <page_free>
	page_free(pp1);
f01013e8:	89 34 24             	mov    %esi,(%esp)
f01013eb:	e8 6d fa ff ff       	call   f0100e5d <page_free>
	page_free(pp2);
f01013f0:	83 c4 04             	add    $0x4,%esp
f01013f3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013f6:	e8 62 fa ff ff       	call   f0100e5d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101402:	e8 e6 f9 ff ff       	call   f0100ded <page_alloc>
f0101407:	89 c6                	mov    %eax,%esi
f0101409:	83 c4 10             	add    $0x10,%esp
f010140c:	85 c0                	test   %eax,%eax
f010140e:	75 19                	jne    f0101429 <mem_init+0x314>
f0101410:	68 d2 55 10 f0       	push   $0xf01055d2
f0101415:	68 27 55 10 f0       	push   $0xf0105527
f010141a:	68 f0 02 00 00       	push   $0x2f0
f010141f:	68 01 55 10 f0       	push   $0xf0105501
f0101424:	e8 77 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101429:	83 ec 0c             	sub    $0xc,%esp
f010142c:	6a 00                	push   $0x0
f010142e:	e8 ba f9 ff ff       	call   f0100ded <page_alloc>
f0101433:	89 c7                	mov    %eax,%edi
f0101435:	83 c4 10             	add    $0x10,%esp
f0101438:	85 c0                	test   %eax,%eax
f010143a:	75 19                	jne    f0101455 <mem_init+0x340>
f010143c:	68 e8 55 10 f0       	push   $0xf01055e8
f0101441:	68 27 55 10 f0       	push   $0xf0105527
f0101446:	68 f1 02 00 00       	push   $0x2f1
f010144b:	68 01 55 10 f0       	push   $0xf0105501
f0101450:	e8 4b ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101455:	83 ec 0c             	sub    $0xc,%esp
f0101458:	6a 00                	push   $0x0
f010145a:	e8 8e f9 ff ff       	call   f0100ded <page_alloc>
f010145f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101462:	83 c4 10             	add    $0x10,%esp
f0101465:	85 c0                	test   %eax,%eax
f0101467:	75 19                	jne    f0101482 <mem_init+0x36d>
f0101469:	68 fe 55 10 f0       	push   $0xf01055fe
f010146e:	68 27 55 10 f0       	push   $0xf0105527
f0101473:	68 f2 02 00 00       	push   $0x2f2
f0101478:	68 01 55 10 f0       	push   $0xf0105501
f010147d:	e8 1e ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101482:	39 fe                	cmp    %edi,%esi
f0101484:	75 19                	jne    f010149f <mem_init+0x38a>
f0101486:	68 14 56 10 f0       	push   $0xf0105614
f010148b:	68 27 55 10 f0       	push   $0xf0105527
f0101490:	68 f4 02 00 00       	push   $0x2f4
f0101495:	68 01 55 10 f0       	push   $0xf0105501
f010149a:	e8 01 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010149f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014a2:	39 c7                	cmp    %eax,%edi
f01014a4:	74 04                	je     f01014aa <mem_init+0x395>
f01014a6:	39 c6                	cmp    %eax,%esi
f01014a8:	75 19                	jne    f01014c3 <mem_init+0x3ae>
f01014aa:	68 d8 4e 10 f0       	push   $0xf0104ed8
f01014af:	68 27 55 10 f0       	push   $0xf0105527
f01014b4:	68 f5 02 00 00       	push   $0x2f5
f01014b9:	68 01 55 10 f0       	push   $0xf0105501
f01014be:	e8 dd eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014c3:	83 ec 0c             	sub    $0xc,%esp
f01014c6:	6a 00                	push   $0x0
f01014c8:	e8 20 f9 ff ff       	call   f0100ded <page_alloc>
f01014cd:	83 c4 10             	add    $0x10,%esp
f01014d0:	85 c0                	test   %eax,%eax
f01014d2:	74 19                	je     f01014ed <mem_init+0x3d8>
f01014d4:	68 7d 56 10 f0       	push   $0xf010567d
f01014d9:	68 27 55 10 f0       	push   $0xf0105527
f01014de:	68 f6 02 00 00       	push   $0x2f6
f01014e3:	68 01 55 10 f0       	push   $0xf0105501
f01014e8:	e8 b3 eb ff ff       	call   f01000a0 <_panic>
f01014ed:	89 f0                	mov    %esi,%eax
f01014ef:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01014f5:	c1 f8 03             	sar    $0x3,%eax
f01014f8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014fb:	89 c2                	mov    %eax,%edx
f01014fd:	c1 ea 0c             	shr    $0xc,%edx
f0101500:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0101506:	72 12                	jb     f010151a <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101508:	50                   	push   %eax
f0101509:	68 c4 4c 10 f0       	push   $0xf0104cc4
f010150e:	6a 56                	push   $0x56
f0101510:	68 0d 55 10 f0       	push   $0xf010550d
f0101515:	e8 86 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010151a:	83 ec 04             	sub    $0x4,%esp
f010151d:	68 00 10 00 00       	push   $0x1000
f0101522:	6a 01                	push   $0x1
f0101524:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101529:	50                   	push   %eax
f010152a:	e8 dd 2d 00 00       	call   f010430c <memset>
	page_free(pp0);
f010152f:	89 34 24             	mov    %esi,(%esp)
f0101532:	e8 26 f9 ff ff       	call   f0100e5d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101537:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010153e:	e8 aa f8 ff ff       	call   f0100ded <page_alloc>
f0101543:	83 c4 10             	add    $0x10,%esp
f0101546:	85 c0                	test   %eax,%eax
f0101548:	75 19                	jne    f0101563 <mem_init+0x44e>
f010154a:	68 8c 56 10 f0       	push   $0xf010568c
f010154f:	68 27 55 10 f0       	push   $0xf0105527
f0101554:	68 fb 02 00 00       	push   $0x2fb
f0101559:	68 01 55 10 f0       	push   $0xf0105501
f010155e:	e8 3d eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101563:	39 c6                	cmp    %eax,%esi
f0101565:	74 19                	je     f0101580 <mem_init+0x46b>
f0101567:	68 aa 56 10 f0       	push   $0xf01056aa
f010156c:	68 27 55 10 f0       	push   $0xf0105527
f0101571:	68 fc 02 00 00       	push   $0x2fc
f0101576:	68 01 55 10 f0       	push   $0xf0105501
f010157b:	e8 20 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101580:	89 f0                	mov    %esi,%eax
f0101582:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101588:	c1 f8 03             	sar    $0x3,%eax
f010158b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010158e:	89 c2                	mov    %eax,%edx
f0101590:	c1 ea 0c             	shr    $0xc,%edx
f0101593:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0101599:	72 12                	jb     f01015ad <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010159b:	50                   	push   %eax
f010159c:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01015a1:	6a 56                	push   $0x56
f01015a3:	68 0d 55 10 f0       	push   $0xf010550d
f01015a8:	e8 f3 ea ff ff       	call   f01000a0 <_panic>
f01015ad:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01015b3:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015b9:	80 38 00             	cmpb   $0x0,(%eax)
f01015bc:	74 19                	je     f01015d7 <mem_init+0x4c2>
f01015be:	68 ba 56 10 f0       	push   $0xf01056ba
f01015c3:	68 27 55 10 f0       	push   $0xf0105527
f01015c8:	68 ff 02 00 00       	push   $0x2ff
f01015cd:	68 01 55 10 f0       	push   $0xf0105501
f01015d2:	e8 c9 ea ff ff       	call   f01000a0 <_panic>
f01015d7:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015da:	39 d0                	cmp    %edx,%eax
f01015dc:	75 db                	jne    f01015b9 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015de:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015e1:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	// free the pages we took
	page_free(pp0);
f01015e6:	83 ec 0c             	sub    $0xc,%esp
f01015e9:	56                   	push   %esi
f01015ea:	e8 6e f8 ff ff       	call   f0100e5d <page_free>
	page_free(pp1);
f01015ef:	89 3c 24             	mov    %edi,(%esp)
f01015f2:	e8 66 f8 ff ff       	call   f0100e5d <page_free>
	page_free(pp2);
f01015f7:	83 c4 04             	add    $0x4,%esp
f01015fa:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015fd:	e8 5b f8 ff ff       	call   f0100e5d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101602:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101607:	83 c4 10             	add    $0x10,%esp
f010160a:	eb 05                	jmp    f0101611 <mem_init+0x4fc>
		--nfree;
f010160c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010160f:	8b 00                	mov    (%eax),%eax
f0101611:	85 c0                	test   %eax,%eax
f0101613:	75 f7                	jne    f010160c <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f0101615:	85 db                	test   %ebx,%ebx
f0101617:	74 19                	je     f0101632 <mem_init+0x51d>
f0101619:	68 c4 56 10 f0       	push   $0xf01056c4
f010161e:	68 27 55 10 f0       	push   $0xf0105527
f0101623:	68 0c 03 00 00       	push   $0x30c
f0101628:	68 01 55 10 f0       	push   $0xf0105501
f010162d:	e8 6e ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101632:	83 ec 0c             	sub    $0xc,%esp
f0101635:	68 f8 4e 10 f0       	push   $0xf0104ef8
f010163a:	e8 f2 18 00 00       	call   f0102f31 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010163f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101646:	e8 a2 f7 ff ff       	call   f0100ded <page_alloc>
f010164b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010164e:	83 c4 10             	add    $0x10,%esp
f0101651:	85 c0                	test   %eax,%eax
f0101653:	75 19                	jne    f010166e <mem_init+0x559>
f0101655:	68 d2 55 10 f0       	push   $0xf01055d2
f010165a:	68 27 55 10 f0       	push   $0xf0105527
f010165f:	68 6a 03 00 00       	push   $0x36a
f0101664:	68 01 55 10 f0       	push   $0xf0105501
f0101669:	e8 32 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010166e:	83 ec 0c             	sub    $0xc,%esp
f0101671:	6a 00                	push   $0x0
f0101673:	e8 75 f7 ff ff       	call   f0100ded <page_alloc>
f0101678:	89 c3                	mov    %eax,%ebx
f010167a:	83 c4 10             	add    $0x10,%esp
f010167d:	85 c0                	test   %eax,%eax
f010167f:	75 19                	jne    f010169a <mem_init+0x585>
f0101681:	68 e8 55 10 f0       	push   $0xf01055e8
f0101686:	68 27 55 10 f0       	push   $0xf0105527
f010168b:	68 6b 03 00 00       	push   $0x36b
f0101690:	68 01 55 10 f0       	push   $0xf0105501
f0101695:	e8 06 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010169a:	83 ec 0c             	sub    $0xc,%esp
f010169d:	6a 00                	push   $0x0
f010169f:	e8 49 f7 ff ff       	call   f0100ded <page_alloc>
f01016a4:	89 c6                	mov    %eax,%esi
f01016a6:	83 c4 10             	add    $0x10,%esp
f01016a9:	85 c0                	test   %eax,%eax
f01016ab:	75 19                	jne    f01016c6 <mem_init+0x5b1>
f01016ad:	68 fe 55 10 f0       	push   $0xf01055fe
f01016b2:	68 27 55 10 f0       	push   $0xf0105527
f01016b7:	68 6c 03 00 00       	push   $0x36c
f01016bc:	68 01 55 10 f0       	push   $0xf0105501
f01016c1:	e8 da e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016c6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016c9:	75 19                	jne    f01016e4 <mem_init+0x5cf>
f01016cb:	68 14 56 10 f0       	push   $0xf0105614
f01016d0:	68 27 55 10 f0       	push   $0xf0105527
f01016d5:	68 6f 03 00 00       	push   $0x36f
f01016da:	68 01 55 10 f0       	push   $0xf0105501
f01016df:	e8 bc e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016e4:	39 c3                	cmp    %eax,%ebx
f01016e6:	74 05                	je     f01016ed <mem_init+0x5d8>
f01016e8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016eb:	75 19                	jne    f0101706 <mem_init+0x5f1>
f01016ed:	68 d8 4e 10 f0       	push   $0xf0104ed8
f01016f2:	68 27 55 10 f0       	push   $0xf0105527
f01016f7:	68 70 03 00 00       	push   $0x370
f01016fc:	68 01 55 10 f0       	push   $0xf0105501
f0101701:	e8 9a e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101706:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f010170b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010170e:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0101715:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101718:	83 ec 0c             	sub    $0xc,%esp
f010171b:	6a 00                	push   $0x0
f010171d:	e8 cb f6 ff ff       	call   f0100ded <page_alloc>
f0101722:	83 c4 10             	add    $0x10,%esp
f0101725:	85 c0                	test   %eax,%eax
f0101727:	74 19                	je     f0101742 <mem_init+0x62d>
f0101729:	68 7d 56 10 f0       	push   $0xf010567d
f010172e:	68 27 55 10 f0       	push   $0xf0105527
f0101733:	68 77 03 00 00       	push   $0x377
f0101738:	68 01 55 10 f0       	push   $0xf0105501
f010173d:	e8 5e e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101742:	83 ec 04             	sub    $0x4,%esp
f0101745:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101748:	50                   	push   %eax
f0101749:	6a 00                	push   $0x0
f010174b:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101751:	e8 b2 f8 ff ff       	call   f0101008 <page_lookup>
f0101756:	83 c4 10             	add    $0x10,%esp
f0101759:	85 c0                	test   %eax,%eax
f010175b:	74 19                	je     f0101776 <mem_init+0x661>
f010175d:	68 18 4f 10 f0       	push   $0xf0104f18
f0101762:	68 27 55 10 f0       	push   $0xf0105527
f0101767:	68 7a 03 00 00       	push   $0x37a
f010176c:	68 01 55 10 f0       	push   $0xf0105501
f0101771:	e8 2a e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101776:	6a 02                	push   $0x2
f0101778:	6a 00                	push   $0x0
f010177a:	53                   	push   %ebx
f010177b:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101781:	e8 26 f9 ff ff       	call   f01010ac <page_insert>
f0101786:	83 c4 10             	add    $0x10,%esp
f0101789:	85 c0                	test   %eax,%eax
f010178b:	78 19                	js     f01017a6 <mem_init+0x691>
f010178d:	68 50 4f 10 f0       	push   $0xf0104f50
f0101792:	68 27 55 10 f0       	push   $0xf0105527
f0101797:	68 7d 03 00 00       	push   $0x37d
f010179c:	68 01 55 10 f0       	push   $0xf0105501
f01017a1:	e8 fa e8 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01017a6:	83 ec 0c             	sub    $0xc,%esp
f01017a9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017ac:	e8 ac f6 ff ff       	call   f0100e5d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01017b1:	6a 02                	push   $0x2
f01017b3:	6a 00                	push   $0x0
f01017b5:	53                   	push   %ebx
f01017b6:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01017bc:	e8 eb f8 ff ff       	call   f01010ac <page_insert>
f01017c1:	83 c4 20             	add    $0x20,%esp
f01017c4:	85 c0                	test   %eax,%eax
f01017c6:	74 19                	je     f01017e1 <mem_init+0x6cc>
f01017c8:	68 80 4f 10 f0       	push   $0xf0104f80
f01017cd:	68 27 55 10 f0       	push   $0xf0105527
f01017d2:	68 81 03 00 00       	push   $0x381
f01017d7:	68 01 55 10 f0       	push   $0xf0105501
f01017dc:	e8 bf e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017e1:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017e7:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f01017ec:	89 c1                	mov    %eax,%ecx
f01017ee:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017f1:	8b 17                	mov    (%edi),%edx
f01017f3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017fc:	29 c8                	sub    %ecx,%eax
f01017fe:	c1 f8 03             	sar    $0x3,%eax
f0101801:	c1 e0 0c             	shl    $0xc,%eax
f0101804:	39 c2                	cmp    %eax,%edx
f0101806:	74 19                	je     f0101821 <mem_init+0x70c>
f0101808:	68 b0 4f 10 f0       	push   $0xf0104fb0
f010180d:	68 27 55 10 f0       	push   $0xf0105527
f0101812:	68 82 03 00 00       	push   $0x382
f0101817:	68 01 55 10 f0       	push   $0xf0105501
f010181c:	e8 7f e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101821:	ba 00 00 00 00       	mov    $0x0,%edx
f0101826:	89 f8                	mov    %edi,%eax
f0101828:	e8 4d f1 ff ff       	call   f010097a <check_va2pa>
f010182d:	89 da                	mov    %ebx,%edx
f010182f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101832:	c1 fa 03             	sar    $0x3,%edx
f0101835:	c1 e2 0c             	shl    $0xc,%edx
f0101838:	39 d0                	cmp    %edx,%eax
f010183a:	74 19                	je     f0101855 <mem_init+0x740>
f010183c:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0101841:	68 27 55 10 f0       	push   $0xf0105527
f0101846:	68 83 03 00 00       	push   $0x383
f010184b:	68 01 55 10 f0       	push   $0xf0105501
f0101850:	e8 4b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101855:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010185a:	74 19                	je     f0101875 <mem_init+0x760>
f010185c:	68 cf 56 10 f0       	push   $0xf01056cf
f0101861:	68 27 55 10 f0       	push   $0xf0105527
f0101866:	68 84 03 00 00       	push   $0x384
f010186b:	68 01 55 10 f0       	push   $0xf0105501
f0101870:	e8 2b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101875:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101878:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010187d:	74 19                	je     f0101898 <mem_init+0x783>
f010187f:	68 e0 56 10 f0       	push   $0xf01056e0
f0101884:	68 27 55 10 f0       	push   $0xf0105527
f0101889:	68 85 03 00 00       	push   $0x385
f010188e:	68 01 55 10 f0       	push   $0xf0105501
f0101893:	e8 08 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101898:	6a 02                	push   $0x2
f010189a:	68 00 10 00 00       	push   $0x1000
f010189f:	56                   	push   %esi
f01018a0:	57                   	push   %edi
f01018a1:	e8 06 f8 ff ff       	call   f01010ac <page_insert>
f01018a6:	83 c4 10             	add    $0x10,%esp
f01018a9:	85 c0                	test   %eax,%eax
f01018ab:	74 19                	je     f01018c6 <mem_init+0x7b1>
f01018ad:	68 08 50 10 f0       	push   $0xf0105008
f01018b2:	68 27 55 10 f0       	push   $0xf0105527
f01018b7:	68 88 03 00 00       	push   $0x388
f01018bc:	68 01 55 10 f0       	push   $0xf0105501
f01018c1:	e8 da e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018c6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018cb:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01018d0:	e8 a5 f0 ff ff       	call   f010097a <check_va2pa>
f01018d5:	89 f2                	mov    %esi,%edx
f01018d7:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01018dd:	c1 fa 03             	sar    $0x3,%edx
f01018e0:	c1 e2 0c             	shl    $0xc,%edx
f01018e3:	39 d0                	cmp    %edx,%eax
f01018e5:	74 19                	je     f0101900 <mem_init+0x7eb>
f01018e7:	68 44 50 10 f0       	push   $0xf0105044
f01018ec:	68 27 55 10 f0       	push   $0xf0105527
f01018f1:	68 89 03 00 00       	push   $0x389
f01018f6:	68 01 55 10 f0       	push   $0xf0105501
f01018fb:	e8 a0 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101900:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101905:	74 19                	je     f0101920 <mem_init+0x80b>
f0101907:	68 f1 56 10 f0       	push   $0xf01056f1
f010190c:	68 27 55 10 f0       	push   $0xf0105527
f0101911:	68 8a 03 00 00       	push   $0x38a
f0101916:	68 01 55 10 f0       	push   $0xf0105501
f010191b:	e8 80 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101920:	83 ec 0c             	sub    $0xc,%esp
f0101923:	6a 00                	push   $0x0
f0101925:	e8 c3 f4 ff ff       	call   f0100ded <page_alloc>
f010192a:	83 c4 10             	add    $0x10,%esp
f010192d:	85 c0                	test   %eax,%eax
f010192f:	74 19                	je     f010194a <mem_init+0x835>
f0101931:	68 7d 56 10 f0       	push   $0xf010567d
f0101936:	68 27 55 10 f0       	push   $0xf0105527
f010193b:	68 8d 03 00 00       	push   $0x38d
f0101940:	68 01 55 10 f0       	push   $0xf0105501
f0101945:	e8 56 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010194a:	6a 02                	push   $0x2
f010194c:	68 00 10 00 00       	push   $0x1000
f0101951:	56                   	push   %esi
f0101952:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101958:	e8 4f f7 ff ff       	call   f01010ac <page_insert>
f010195d:	83 c4 10             	add    $0x10,%esp
f0101960:	85 c0                	test   %eax,%eax
f0101962:	74 19                	je     f010197d <mem_init+0x868>
f0101964:	68 08 50 10 f0       	push   $0xf0105008
f0101969:	68 27 55 10 f0       	push   $0xf0105527
f010196e:	68 90 03 00 00       	push   $0x390
f0101973:	68 01 55 10 f0       	push   $0xf0105501
f0101978:	e8 23 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010197d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101982:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101987:	e8 ee ef ff ff       	call   f010097a <check_va2pa>
f010198c:	89 f2                	mov    %esi,%edx
f010198e:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101994:	c1 fa 03             	sar    $0x3,%edx
f0101997:	c1 e2 0c             	shl    $0xc,%edx
f010199a:	39 d0                	cmp    %edx,%eax
f010199c:	74 19                	je     f01019b7 <mem_init+0x8a2>
f010199e:	68 44 50 10 f0       	push   $0xf0105044
f01019a3:	68 27 55 10 f0       	push   $0xf0105527
f01019a8:	68 91 03 00 00       	push   $0x391
f01019ad:	68 01 55 10 f0       	push   $0xf0105501
f01019b2:	e8 e9 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019b7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019bc:	74 19                	je     f01019d7 <mem_init+0x8c2>
f01019be:	68 f1 56 10 f0       	push   $0xf01056f1
f01019c3:	68 27 55 10 f0       	push   $0xf0105527
f01019c8:	68 92 03 00 00       	push   $0x392
f01019cd:	68 01 55 10 f0       	push   $0xf0105501
f01019d2:	e8 c9 e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01019d7:	83 ec 0c             	sub    $0xc,%esp
f01019da:	6a 00                	push   $0x0
f01019dc:	e8 0c f4 ff ff       	call   f0100ded <page_alloc>
f01019e1:	83 c4 10             	add    $0x10,%esp
f01019e4:	85 c0                	test   %eax,%eax
f01019e6:	74 19                	je     f0101a01 <mem_init+0x8ec>
f01019e8:	68 7d 56 10 f0       	push   $0xf010567d
f01019ed:	68 27 55 10 f0       	push   $0xf0105527
f01019f2:	68 96 03 00 00       	push   $0x396
f01019f7:	68 01 55 10 f0       	push   $0xf0105501
f01019fc:	e8 9f e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a01:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f0101a07:	8b 02                	mov    (%edx),%eax
f0101a09:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a0e:	89 c1                	mov    %eax,%ecx
f0101a10:	c1 e9 0c             	shr    $0xc,%ecx
f0101a13:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f0101a19:	72 15                	jb     f0101a30 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a1b:	50                   	push   %eax
f0101a1c:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0101a21:	68 99 03 00 00       	push   $0x399
f0101a26:	68 01 55 10 f0       	push   $0xf0105501
f0101a2b:	e8 70 e6 ff ff       	call   f01000a0 <_panic>
f0101a30:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a35:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a38:	83 ec 04             	sub    $0x4,%esp
f0101a3b:	6a 00                	push   $0x0
f0101a3d:	68 00 10 00 00       	push   $0x1000
f0101a42:	52                   	push   %edx
f0101a43:	e8 77 f4 ff ff       	call   f0100ebf <pgdir_walk>
f0101a48:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a4b:	8d 57 04             	lea    0x4(%edi),%edx
f0101a4e:	83 c4 10             	add    $0x10,%esp
f0101a51:	39 d0                	cmp    %edx,%eax
f0101a53:	74 19                	je     f0101a6e <mem_init+0x959>
f0101a55:	68 74 50 10 f0       	push   $0xf0105074
f0101a5a:	68 27 55 10 f0       	push   $0xf0105527
f0101a5f:	68 9a 03 00 00       	push   $0x39a
f0101a64:	68 01 55 10 f0       	push   $0xf0105501
f0101a69:	e8 32 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a6e:	6a 06                	push   $0x6
f0101a70:	68 00 10 00 00       	push   $0x1000
f0101a75:	56                   	push   %esi
f0101a76:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101a7c:	e8 2b f6 ff ff       	call   f01010ac <page_insert>
f0101a81:	83 c4 10             	add    $0x10,%esp
f0101a84:	85 c0                	test   %eax,%eax
f0101a86:	74 19                	je     f0101aa1 <mem_init+0x98c>
f0101a88:	68 b4 50 10 f0       	push   $0xf01050b4
f0101a8d:	68 27 55 10 f0       	push   $0xf0105527
f0101a92:	68 9d 03 00 00       	push   $0x39d
f0101a97:	68 01 55 10 f0       	push   $0xf0105501
f0101a9c:	e8 ff e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aa1:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101aa7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aac:	89 f8                	mov    %edi,%eax
f0101aae:	e8 c7 ee ff ff       	call   f010097a <check_va2pa>
f0101ab3:	89 f2                	mov    %esi,%edx
f0101ab5:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101abb:	c1 fa 03             	sar    $0x3,%edx
f0101abe:	c1 e2 0c             	shl    $0xc,%edx
f0101ac1:	39 d0                	cmp    %edx,%eax
f0101ac3:	74 19                	je     f0101ade <mem_init+0x9c9>
f0101ac5:	68 44 50 10 f0       	push   $0xf0105044
f0101aca:	68 27 55 10 f0       	push   $0xf0105527
f0101acf:	68 9e 03 00 00       	push   $0x39e
f0101ad4:	68 01 55 10 f0       	push   $0xf0105501
f0101ad9:	e8 c2 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101ade:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ae3:	74 19                	je     f0101afe <mem_init+0x9e9>
f0101ae5:	68 f1 56 10 f0       	push   $0xf01056f1
f0101aea:	68 27 55 10 f0       	push   $0xf0105527
f0101aef:	68 9f 03 00 00       	push   $0x39f
f0101af4:	68 01 55 10 f0       	push   $0xf0105501
f0101af9:	e8 a2 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101afe:	83 ec 04             	sub    $0x4,%esp
f0101b01:	6a 00                	push   $0x0
f0101b03:	68 00 10 00 00       	push   $0x1000
f0101b08:	57                   	push   %edi
f0101b09:	e8 b1 f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101b0e:	83 c4 10             	add    $0x10,%esp
f0101b11:	f6 00 04             	testb  $0x4,(%eax)
f0101b14:	75 19                	jne    f0101b2f <mem_init+0xa1a>
f0101b16:	68 f4 50 10 f0       	push   $0xf01050f4
f0101b1b:	68 27 55 10 f0       	push   $0xf0105527
f0101b20:	68 a0 03 00 00       	push   $0x3a0
f0101b25:	68 01 55 10 f0       	push   $0xf0105501
f0101b2a:	e8 71 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b2f:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101b34:	f6 00 04             	testb  $0x4,(%eax)
f0101b37:	75 19                	jne    f0101b52 <mem_init+0xa3d>
f0101b39:	68 02 57 10 f0       	push   $0xf0105702
f0101b3e:	68 27 55 10 f0       	push   $0xf0105527
f0101b43:	68 a1 03 00 00       	push   $0x3a1
f0101b48:	68 01 55 10 f0       	push   $0xf0105501
f0101b4d:	e8 4e e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b52:	6a 02                	push   $0x2
f0101b54:	68 00 10 00 00       	push   $0x1000
f0101b59:	56                   	push   %esi
f0101b5a:	50                   	push   %eax
f0101b5b:	e8 4c f5 ff ff       	call   f01010ac <page_insert>
f0101b60:	83 c4 10             	add    $0x10,%esp
f0101b63:	85 c0                	test   %eax,%eax
f0101b65:	74 19                	je     f0101b80 <mem_init+0xa6b>
f0101b67:	68 08 50 10 f0       	push   $0xf0105008
f0101b6c:	68 27 55 10 f0       	push   $0xf0105527
f0101b71:	68 a4 03 00 00       	push   $0x3a4
f0101b76:	68 01 55 10 f0       	push   $0xf0105501
f0101b7b:	e8 20 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b80:	83 ec 04             	sub    $0x4,%esp
f0101b83:	6a 00                	push   $0x0
f0101b85:	68 00 10 00 00       	push   $0x1000
f0101b8a:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b90:	e8 2a f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101b95:	83 c4 10             	add    $0x10,%esp
f0101b98:	f6 00 02             	testb  $0x2,(%eax)
f0101b9b:	75 19                	jne    f0101bb6 <mem_init+0xaa1>
f0101b9d:	68 28 51 10 f0       	push   $0xf0105128
f0101ba2:	68 27 55 10 f0       	push   $0xf0105527
f0101ba7:	68 a5 03 00 00       	push   $0x3a5
f0101bac:	68 01 55 10 f0       	push   $0xf0105501
f0101bb1:	e8 ea e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bb6:	83 ec 04             	sub    $0x4,%esp
f0101bb9:	6a 00                	push   $0x0
f0101bbb:	68 00 10 00 00       	push   $0x1000
f0101bc0:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101bc6:	e8 f4 f2 ff ff       	call   f0100ebf <pgdir_walk>
f0101bcb:	83 c4 10             	add    $0x10,%esp
f0101bce:	f6 00 04             	testb  $0x4,(%eax)
f0101bd1:	74 19                	je     f0101bec <mem_init+0xad7>
f0101bd3:	68 5c 51 10 f0       	push   $0xf010515c
f0101bd8:	68 27 55 10 f0       	push   $0xf0105527
f0101bdd:	68 a6 03 00 00       	push   $0x3a6
f0101be2:	68 01 55 10 f0       	push   $0xf0105501
f0101be7:	e8 b4 e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bec:	6a 02                	push   $0x2
f0101bee:	68 00 00 40 00       	push   $0x400000
f0101bf3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bf6:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101bfc:	e8 ab f4 ff ff       	call   f01010ac <page_insert>
f0101c01:	83 c4 10             	add    $0x10,%esp
f0101c04:	85 c0                	test   %eax,%eax
f0101c06:	78 19                	js     f0101c21 <mem_init+0xb0c>
f0101c08:	68 94 51 10 f0       	push   $0xf0105194
f0101c0d:	68 27 55 10 f0       	push   $0xf0105527
f0101c12:	68 a9 03 00 00       	push   $0x3a9
f0101c17:	68 01 55 10 f0       	push   $0xf0105501
f0101c1c:	e8 7f e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c21:	6a 02                	push   $0x2
f0101c23:	68 00 10 00 00       	push   $0x1000
f0101c28:	53                   	push   %ebx
f0101c29:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c2f:	e8 78 f4 ff ff       	call   f01010ac <page_insert>
f0101c34:	83 c4 10             	add    $0x10,%esp
f0101c37:	85 c0                	test   %eax,%eax
f0101c39:	74 19                	je     f0101c54 <mem_init+0xb3f>
f0101c3b:	68 cc 51 10 f0       	push   $0xf01051cc
f0101c40:	68 27 55 10 f0       	push   $0xf0105527
f0101c45:	68 ac 03 00 00       	push   $0x3ac
f0101c4a:	68 01 55 10 f0       	push   $0xf0105501
f0101c4f:	e8 4c e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c54:	83 ec 04             	sub    $0x4,%esp
f0101c57:	6a 00                	push   $0x0
f0101c59:	68 00 10 00 00       	push   $0x1000
f0101c5e:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c64:	e8 56 f2 ff ff       	call   f0100ebf <pgdir_walk>
f0101c69:	83 c4 10             	add    $0x10,%esp
f0101c6c:	f6 00 04             	testb  $0x4,(%eax)
f0101c6f:	74 19                	je     f0101c8a <mem_init+0xb75>
f0101c71:	68 5c 51 10 f0       	push   $0xf010515c
f0101c76:	68 27 55 10 f0       	push   $0xf0105527
f0101c7b:	68 ad 03 00 00       	push   $0x3ad
f0101c80:	68 01 55 10 f0       	push   $0xf0105501
f0101c85:	e8 16 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c8a:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101c90:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c95:	89 f8                	mov    %edi,%eax
f0101c97:	e8 de ec ff ff       	call   f010097a <check_va2pa>
f0101c9c:	89 c1                	mov    %eax,%ecx
f0101c9e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ca1:	89 d8                	mov    %ebx,%eax
f0101ca3:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101ca9:	c1 f8 03             	sar    $0x3,%eax
f0101cac:	c1 e0 0c             	shl    $0xc,%eax
f0101caf:	39 c1                	cmp    %eax,%ecx
f0101cb1:	74 19                	je     f0101ccc <mem_init+0xbb7>
f0101cb3:	68 08 52 10 f0       	push   $0xf0105208
f0101cb8:	68 27 55 10 f0       	push   $0xf0105527
f0101cbd:	68 b0 03 00 00       	push   $0x3b0
f0101cc2:	68 01 55 10 f0       	push   $0xf0105501
f0101cc7:	e8 d4 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ccc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cd1:	89 f8                	mov    %edi,%eax
f0101cd3:	e8 a2 ec ff ff       	call   f010097a <check_va2pa>
f0101cd8:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xbe1>
f0101cdd:	68 34 52 10 f0       	push   $0xf0105234
f0101ce2:	68 27 55 10 f0       	push   $0xf0105527
f0101ce7:	68 b1 03 00 00       	push   $0x3b1
f0101cec:	68 01 55 10 f0       	push   $0xf0105501
f0101cf1:	e8 aa e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cf6:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101cfb:	74 19                	je     f0101d16 <mem_init+0xc01>
f0101cfd:	68 18 57 10 f0       	push   $0xf0105718
f0101d02:	68 27 55 10 f0       	push   $0xf0105527
f0101d07:	68 b3 03 00 00       	push   $0x3b3
f0101d0c:	68 01 55 10 f0       	push   $0xf0105501
f0101d11:	e8 8a e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d16:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d1b:	74 19                	je     f0101d36 <mem_init+0xc21>
f0101d1d:	68 29 57 10 f0       	push   $0xf0105729
f0101d22:	68 27 55 10 f0       	push   $0xf0105527
f0101d27:	68 b4 03 00 00       	push   $0x3b4
f0101d2c:	68 01 55 10 f0       	push   $0xf0105501
f0101d31:	e8 6a e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d36:	83 ec 0c             	sub    $0xc,%esp
f0101d39:	6a 00                	push   $0x0
f0101d3b:	e8 ad f0 ff ff       	call   f0100ded <page_alloc>
f0101d40:	83 c4 10             	add    $0x10,%esp
f0101d43:	39 c6                	cmp    %eax,%esi
f0101d45:	75 04                	jne    f0101d4b <mem_init+0xc36>
f0101d47:	85 c0                	test   %eax,%eax
f0101d49:	75 19                	jne    f0101d64 <mem_init+0xc4f>
f0101d4b:	68 64 52 10 f0       	push   $0xf0105264
f0101d50:	68 27 55 10 f0       	push   $0xf0105527
f0101d55:	68 b7 03 00 00       	push   $0x3b7
f0101d5a:	68 01 55 10 f0       	push   $0xf0105501
f0101d5f:	e8 3c e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d64:	83 ec 08             	sub    $0x8,%esp
f0101d67:	6a 00                	push   $0x0
f0101d69:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101d6f:	e8 ee f2 ff ff       	call   f0101062 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d74:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101d7a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d7f:	89 f8                	mov    %edi,%eax
f0101d81:	e8 f4 eb ff ff       	call   f010097a <check_va2pa>
f0101d86:	83 c4 10             	add    $0x10,%esp
f0101d89:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d8c:	74 19                	je     f0101da7 <mem_init+0xc92>
f0101d8e:	68 88 52 10 f0       	push   $0xf0105288
f0101d93:	68 27 55 10 f0       	push   $0xf0105527
f0101d98:	68 bb 03 00 00       	push   $0x3bb
f0101d9d:	68 01 55 10 f0       	push   $0xf0105501
f0101da2:	e8 f9 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101da7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dac:	89 f8                	mov    %edi,%eax
f0101dae:	e8 c7 eb ff ff       	call   f010097a <check_va2pa>
f0101db3:	89 da                	mov    %ebx,%edx
f0101db5:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101dbb:	c1 fa 03             	sar    $0x3,%edx
f0101dbe:	c1 e2 0c             	shl    $0xc,%edx
f0101dc1:	39 d0                	cmp    %edx,%eax
f0101dc3:	74 19                	je     f0101dde <mem_init+0xcc9>
f0101dc5:	68 34 52 10 f0       	push   $0xf0105234
f0101dca:	68 27 55 10 f0       	push   $0xf0105527
f0101dcf:	68 bc 03 00 00       	push   $0x3bc
f0101dd4:	68 01 55 10 f0       	push   $0xf0105501
f0101dd9:	e8 c2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dde:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101de3:	74 19                	je     f0101dfe <mem_init+0xce9>
f0101de5:	68 cf 56 10 f0       	push   $0xf01056cf
f0101dea:	68 27 55 10 f0       	push   $0xf0105527
f0101def:	68 bd 03 00 00       	push   $0x3bd
f0101df4:	68 01 55 10 f0       	push   $0xf0105501
f0101df9:	e8 a2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dfe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e03:	74 19                	je     f0101e1e <mem_init+0xd09>
f0101e05:	68 29 57 10 f0       	push   $0xf0105729
f0101e0a:	68 27 55 10 f0       	push   $0xf0105527
f0101e0f:	68 be 03 00 00       	push   $0x3be
f0101e14:	68 01 55 10 f0       	push   $0xf0105501
f0101e19:	e8 82 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e1e:	6a 00                	push   $0x0
f0101e20:	68 00 10 00 00       	push   $0x1000
f0101e25:	53                   	push   %ebx
f0101e26:	57                   	push   %edi
f0101e27:	e8 80 f2 ff ff       	call   f01010ac <page_insert>
f0101e2c:	83 c4 10             	add    $0x10,%esp
f0101e2f:	85 c0                	test   %eax,%eax
f0101e31:	74 19                	je     f0101e4c <mem_init+0xd37>
f0101e33:	68 ac 52 10 f0       	push   $0xf01052ac
f0101e38:	68 27 55 10 f0       	push   $0xf0105527
f0101e3d:	68 c1 03 00 00       	push   $0x3c1
f0101e42:	68 01 55 10 f0       	push   $0xf0105501
f0101e47:	e8 54 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e4c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e51:	75 19                	jne    f0101e6c <mem_init+0xd57>
f0101e53:	68 3a 57 10 f0       	push   $0xf010573a
f0101e58:	68 27 55 10 f0       	push   $0xf0105527
f0101e5d:	68 c2 03 00 00       	push   $0x3c2
f0101e62:	68 01 55 10 f0       	push   $0xf0105501
f0101e67:	e8 34 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e6c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e6f:	74 19                	je     f0101e8a <mem_init+0xd75>
f0101e71:	68 46 57 10 f0       	push   $0xf0105746
f0101e76:	68 27 55 10 f0       	push   $0xf0105527
f0101e7b:	68 c3 03 00 00       	push   $0x3c3
f0101e80:	68 01 55 10 f0       	push   $0xf0105501
f0101e85:	e8 16 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e8a:	83 ec 08             	sub    $0x8,%esp
f0101e8d:	68 00 10 00 00       	push   $0x1000
f0101e92:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101e98:	e8 c5 f1 ff ff       	call   f0101062 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e9d:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101ea3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea8:	89 f8                	mov    %edi,%eax
f0101eaa:	e8 cb ea ff ff       	call   f010097a <check_va2pa>
f0101eaf:	83 c4 10             	add    $0x10,%esp
f0101eb2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eb5:	74 19                	je     f0101ed0 <mem_init+0xdbb>
f0101eb7:	68 88 52 10 f0       	push   $0xf0105288
f0101ebc:	68 27 55 10 f0       	push   $0xf0105527
f0101ec1:	68 c7 03 00 00       	push   $0x3c7
f0101ec6:	68 01 55 10 f0       	push   $0xf0105501
f0101ecb:	e8 d0 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ed0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ed5:	89 f8                	mov    %edi,%eax
f0101ed7:	e8 9e ea ff ff       	call   f010097a <check_va2pa>
f0101edc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101edf:	74 19                	je     f0101efa <mem_init+0xde5>
f0101ee1:	68 e4 52 10 f0       	push   $0xf01052e4
f0101ee6:	68 27 55 10 f0       	push   $0xf0105527
f0101eeb:	68 c8 03 00 00       	push   $0x3c8
f0101ef0:	68 01 55 10 f0       	push   $0xf0105501
f0101ef5:	e8 a6 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101efa:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101eff:	74 19                	je     f0101f1a <mem_init+0xe05>
f0101f01:	68 5b 57 10 f0       	push   $0xf010575b
f0101f06:	68 27 55 10 f0       	push   $0xf0105527
f0101f0b:	68 c9 03 00 00       	push   $0x3c9
f0101f10:	68 01 55 10 f0       	push   $0xf0105501
f0101f15:	e8 86 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f1a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f1f:	74 19                	je     f0101f3a <mem_init+0xe25>
f0101f21:	68 29 57 10 f0       	push   $0xf0105729
f0101f26:	68 27 55 10 f0       	push   $0xf0105527
f0101f2b:	68 ca 03 00 00       	push   $0x3ca
f0101f30:	68 01 55 10 f0       	push   $0xf0105501
f0101f35:	e8 66 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f3a:	83 ec 0c             	sub    $0xc,%esp
f0101f3d:	6a 00                	push   $0x0
f0101f3f:	e8 a9 ee ff ff       	call   f0100ded <page_alloc>
f0101f44:	83 c4 10             	add    $0x10,%esp
f0101f47:	85 c0                	test   %eax,%eax
f0101f49:	74 04                	je     f0101f4f <mem_init+0xe3a>
f0101f4b:	39 c3                	cmp    %eax,%ebx
f0101f4d:	74 19                	je     f0101f68 <mem_init+0xe53>
f0101f4f:	68 0c 53 10 f0       	push   $0xf010530c
f0101f54:	68 27 55 10 f0       	push   $0xf0105527
f0101f59:	68 cd 03 00 00       	push   $0x3cd
f0101f5e:	68 01 55 10 f0       	push   $0xf0105501
f0101f63:	e8 38 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f68:	83 ec 0c             	sub    $0xc,%esp
f0101f6b:	6a 00                	push   $0x0
f0101f6d:	e8 7b ee ff ff       	call   f0100ded <page_alloc>
f0101f72:	83 c4 10             	add    $0x10,%esp
f0101f75:	85 c0                	test   %eax,%eax
f0101f77:	74 19                	je     f0101f92 <mem_init+0xe7d>
f0101f79:	68 7d 56 10 f0       	push   $0xf010567d
f0101f7e:	68 27 55 10 f0       	push   $0xf0105527
f0101f83:	68 d0 03 00 00       	push   $0x3d0
f0101f88:	68 01 55 10 f0       	push   $0xf0105501
f0101f8d:	e8 0e e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f92:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f0101f98:	8b 11                	mov    (%ecx),%edx
f0101f9a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fa0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa3:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101fa9:	c1 f8 03             	sar    $0x3,%eax
f0101fac:	c1 e0 0c             	shl    $0xc,%eax
f0101faf:	39 c2                	cmp    %eax,%edx
f0101fb1:	74 19                	je     f0101fcc <mem_init+0xeb7>
f0101fb3:	68 b0 4f 10 f0       	push   $0xf0104fb0
f0101fb8:	68 27 55 10 f0       	push   $0xf0105527
f0101fbd:	68 d3 03 00 00       	push   $0x3d3
f0101fc2:	68 01 55 10 f0       	push   $0xf0105501
f0101fc7:	e8 d4 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101fcc:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fd2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fd5:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fda:	74 19                	je     f0101ff5 <mem_init+0xee0>
f0101fdc:	68 e0 56 10 f0       	push   $0xf01056e0
f0101fe1:	68 27 55 10 f0       	push   $0xf0105527
f0101fe6:	68 d5 03 00 00       	push   $0x3d5
f0101feb:	68 01 55 10 f0       	push   $0xf0105501
f0101ff0:	e8 ab e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101ff5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ff8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ffe:	83 ec 0c             	sub    $0xc,%esp
f0102001:	50                   	push   %eax
f0102002:	e8 56 ee ff ff       	call   f0100e5d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102007:	83 c4 0c             	add    $0xc,%esp
f010200a:	6a 01                	push   $0x1
f010200c:	68 00 10 40 00       	push   $0x401000
f0102011:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102017:	e8 a3 ee ff ff       	call   f0100ebf <pgdir_walk>
f010201c:	89 c7                	mov    %eax,%edi
f010201e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102021:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102026:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102029:	8b 40 04             	mov    0x4(%eax),%eax
f010202c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102031:	8b 0d 44 2c 17 f0    	mov    0xf0172c44,%ecx
f0102037:	89 c2                	mov    %eax,%edx
f0102039:	c1 ea 0c             	shr    $0xc,%edx
f010203c:	83 c4 10             	add    $0x10,%esp
f010203f:	39 ca                	cmp    %ecx,%edx
f0102041:	72 15                	jb     f0102058 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102043:	50                   	push   %eax
f0102044:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102049:	68 dc 03 00 00       	push   $0x3dc
f010204e:	68 01 55 10 f0       	push   $0xf0105501
f0102053:	e8 48 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102058:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010205d:	39 c7                	cmp    %eax,%edi
f010205f:	74 19                	je     f010207a <mem_init+0xf65>
f0102061:	68 6c 57 10 f0       	push   $0xf010576c
f0102066:	68 27 55 10 f0       	push   $0xf0105527
f010206b:	68 dd 03 00 00       	push   $0x3dd
f0102070:	68 01 55 10 f0       	push   $0xf0105501
f0102075:	e8 26 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010207a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010207d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102084:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102087:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010208d:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102093:	c1 f8 03             	sar    $0x3,%eax
f0102096:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102099:	89 c2                	mov    %eax,%edx
f010209b:	c1 ea 0c             	shr    $0xc,%edx
f010209e:	39 d1                	cmp    %edx,%ecx
f01020a0:	77 12                	ja     f01020b4 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020a2:	50                   	push   %eax
f01020a3:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01020a8:	6a 56                	push   $0x56
f01020aa:	68 0d 55 10 f0       	push   $0xf010550d
f01020af:	e8 ec df ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020b4:	83 ec 04             	sub    $0x4,%esp
f01020b7:	68 00 10 00 00       	push   $0x1000
f01020bc:	68 ff 00 00 00       	push   $0xff
f01020c1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020c6:	50                   	push   %eax
f01020c7:	e8 40 22 00 00       	call   f010430c <memset>
	page_free(pp0);
f01020cc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020cf:	89 3c 24             	mov    %edi,(%esp)
f01020d2:	e8 86 ed ff ff       	call   f0100e5d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020d7:	83 c4 0c             	add    $0xc,%esp
f01020da:	6a 01                	push   $0x1
f01020dc:	6a 00                	push   $0x0
f01020de:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01020e4:	e8 d6 ed ff ff       	call   f0100ebf <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020e9:	89 fa                	mov    %edi,%edx
f01020eb:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01020f1:	c1 fa 03             	sar    $0x3,%edx
f01020f4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020f7:	89 d0                	mov    %edx,%eax
f01020f9:	c1 e8 0c             	shr    $0xc,%eax
f01020fc:	83 c4 10             	add    $0x10,%esp
f01020ff:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102105:	72 12                	jb     f0102119 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102107:	52                   	push   %edx
f0102108:	68 c4 4c 10 f0       	push   $0xf0104cc4
f010210d:	6a 56                	push   $0x56
f010210f:	68 0d 55 10 f0       	push   $0xf010550d
f0102114:	e8 87 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102119:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010211f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102122:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102128:	f6 00 01             	testb  $0x1,(%eax)
f010212b:	74 19                	je     f0102146 <mem_init+0x1031>
f010212d:	68 84 57 10 f0       	push   $0xf0105784
f0102132:	68 27 55 10 f0       	push   $0xf0105527
f0102137:	68 e7 03 00 00       	push   $0x3e7
f010213c:	68 01 55 10 f0       	push   $0xf0105501
f0102141:	e8 5a df ff ff       	call   f01000a0 <_panic>
f0102146:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102149:	39 d0                	cmp    %edx,%eax
f010214b:	75 db                	jne    f0102128 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010214d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102152:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102158:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010215b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102161:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102164:	89 3d 80 1f 17 f0    	mov    %edi,0xf0171f80

	// free the pages we took
	page_free(pp0);
f010216a:	83 ec 0c             	sub    $0xc,%esp
f010216d:	50                   	push   %eax
f010216e:	e8 ea ec ff ff       	call   f0100e5d <page_free>
	page_free(pp1);
f0102173:	89 1c 24             	mov    %ebx,(%esp)
f0102176:	e8 e2 ec ff ff       	call   f0100e5d <page_free>
	page_free(pp2);
f010217b:	89 34 24             	mov    %esi,(%esp)
f010217e:	e8 da ec ff ff       	call   f0100e5d <page_free>

	cprintf("check_page() succeeded!\n");
f0102183:	c7 04 24 9b 57 10 f0 	movl   $0xf010579b,(%esp)
f010218a:	e8 a2 0d 00 00       	call   f0102f31 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_U));
f010218f:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102194:	83 c4 10             	add    $0x10,%esp
f0102197:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010219c:	77 15                	ja     f01021b3 <mem_init+0x109e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010219e:	50                   	push   %eax
f010219f:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01021a4:	68 c8 00 00 00       	push   $0xc8
f01021a9:	68 01 55 10 f0       	push   $0xf0105501
f01021ae:	e8 ed de ff ff       	call   f01000a0 <_panic>
f01021b3:	83 ec 08             	sub    $0x8,%esp
f01021b6:	6a 05                	push   $0x5
f01021b8:	05 00 00 00 10       	add    $0x10000000,%eax
f01021bd:	50                   	push   %eax
f01021be:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021c3:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021c8:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021cd:	e8 bf ed ff ff       	call   f0100f91 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_U));
f01021d2:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d7:	83 c4 10             	add    $0x10,%esp
f01021da:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021df:	77 15                	ja     f01021f6 <mem_init+0x10e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021e1:	50                   	push   %eax
f01021e2:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01021e7:	68 d2 00 00 00       	push   $0xd2
f01021ec:	68 01 55 10 f0       	push   $0xf0105501
f01021f1:	e8 aa de ff ff       	call   f01000a0 <_panic>
f01021f6:	83 ec 08             	sub    $0x8,%esp
f01021f9:	6a 05                	push   $0x5
f01021fb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102200:	50                   	push   %eax
f0102201:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102206:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010220b:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102210:	e8 7c ed ff ff       	call   f0100f91 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102215:	83 c4 10             	add    $0x10,%esp
f0102218:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f010221d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102222:	77 15                	ja     f0102239 <mem_init+0x1124>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102224:	50                   	push   %eax
f0102225:	68 e8 4c 10 f0       	push   $0xf0104ce8
f010222a:	68 df 00 00 00       	push   $0xdf
f010222f:	68 01 55 10 f0       	push   $0xf0105501
f0102234:	e8 67 de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102239:	83 ec 08             	sub    $0x8,%esp
f010223c:	6a 02                	push   $0x2
f010223e:	68 00 10 11 00       	push   $0x111000
f0102243:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102248:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010224d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102252:	e8 3a ed ff ff       	call   f0100f91 <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102257:	83 c4 08             	add    $0x8,%esp
f010225a:	6a 02                	push   $0x2
f010225c:	6a 00                	push   $0x0
f010225e:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102263:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102268:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010226d:	e8 1f ed ff ff       	call   f0100f91 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102272:	8b 1d 48 2c 17 f0    	mov    0xf0172c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102278:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f010227d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102280:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102287:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010228c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010228f:	8b 3d 4c 2c 17 f0    	mov    0xf0172c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102295:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102298:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010229b:	be 00 00 00 00       	mov    $0x0,%esi
f01022a0:	eb 55                	jmp    f01022f7 <mem_init+0x11e2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022a2:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01022a8:	89 d8                	mov    %ebx,%eax
f01022aa:	e8 cb e6 ff ff       	call   f010097a <check_va2pa>
f01022af:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022b6:	77 15                	ja     f01022cd <mem_init+0x11b8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022b8:	57                   	push   %edi
f01022b9:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01022be:	68 24 03 00 00       	push   $0x324
f01022c3:	68 01 55 10 f0       	push   $0xf0105501
f01022c8:	e8 d3 dd ff ff       	call   f01000a0 <_panic>
f01022cd:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022d4:	39 d0                	cmp    %edx,%eax
f01022d6:	74 19                	je     f01022f1 <mem_init+0x11dc>
f01022d8:	68 30 53 10 f0       	push   $0xf0105330
f01022dd:	68 27 55 10 f0       	push   $0xf0105527
f01022e2:	68 24 03 00 00       	push   $0x324
f01022e7:	68 01 55 10 f0       	push   $0xf0105501
f01022ec:	e8 af dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022f1:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022f7:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022fa:	77 a6                	ja     f01022a2 <mem_init+0x118d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022fc:	8b 3d 88 1f 17 f0    	mov    0xf0171f88,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102302:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102305:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010230a:	89 f2                	mov    %esi,%edx
f010230c:	89 d8                	mov    %ebx,%eax
f010230e:	e8 67 e6 ff ff       	call   f010097a <check_va2pa>
f0102313:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010231a:	77 15                	ja     f0102331 <mem_init+0x121c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010231c:	57                   	push   %edi
f010231d:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102322:	68 29 03 00 00       	push   $0x329
f0102327:	68 01 55 10 f0       	push   $0xf0105501
f010232c:	e8 6f dd ff ff       	call   f01000a0 <_panic>
f0102331:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102338:	39 c2                	cmp    %eax,%edx
f010233a:	74 19                	je     f0102355 <mem_init+0x1240>
f010233c:	68 64 53 10 f0       	push   $0xf0105364
f0102341:	68 27 55 10 f0       	push   $0xf0105527
f0102346:	68 29 03 00 00       	push   $0x329
f010234b:	68 01 55 10 f0       	push   $0xf0105501
f0102350:	e8 4b dd ff ff       	call   f01000a0 <_panic>
f0102355:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010235b:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102361:	75 a7                	jne    f010230a <mem_init+0x11f5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102363:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102366:	c1 e7 0c             	shl    $0xc,%edi
f0102369:	be 00 00 00 00       	mov    $0x0,%esi
f010236e:	eb 30                	jmp    f01023a0 <mem_init+0x128b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102370:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102376:	89 d8                	mov    %ebx,%eax
f0102378:	e8 fd e5 ff ff       	call   f010097a <check_va2pa>
f010237d:	39 c6                	cmp    %eax,%esi
f010237f:	74 19                	je     f010239a <mem_init+0x1285>
f0102381:	68 98 53 10 f0       	push   $0xf0105398
f0102386:	68 27 55 10 f0       	push   $0xf0105527
f010238b:	68 2d 03 00 00       	push   $0x32d
f0102390:	68 01 55 10 f0       	push   $0xf0105501
f0102395:	e8 06 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010239a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01023a0:	39 fe                	cmp    %edi,%esi
f01023a2:	72 cc                	jb     f0102370 <mem_init+0x125b>
f01023a4:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023a9:	89 f2                	mov    %esi,%edx
f01023ab:	89 d8                	mov    %ebx,%eax
f01023ad:	e8 c8 e5 ff ff       	call   f010097a <check_va2pa>
f01023b2:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01023b8:	39 c2                	cmp    %eax,%edx
f01023ba:	74 19                	je     f01023d5 <mem_init+0x12c0>
f01023bc:	68 c0 53 10 f0       	push   $0xf01053c0
f01023c1:	68 27 55 10 f0       	push   $0xf0105527
f01023c6:	68 31 03 00 00       	push   $0x331
f01023cb:	68 01 55 10 f0       	push   $0xf0105501
f01023d0:	e8 cb dc ff ff       	call   f01000a0 <_panic>
f01023d5:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023db:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023e1:	75 c6                	jne    f01023a9 <mem_init+0x1294>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023e3:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023e8:	89 d8                	mov    %ebx,%eax
f01023ea:	e8 8b e5 ff ff       	call   f010097a <check_va2pa>
f01023ef:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023f2:	74 51                	je     f0102445 <mem_init+0x1330>
f01023f4:	68 08 54 10 f0       	push   $0xf0105408
f01023f9:	68 27 55 10 f0       	push   $0xf0105527
f01023fe:	68 32 03 00 00       	push   $0x332
f0102403:	68 01 55 10 f0       	push   $0xf0105501
f0102408:	e8 93 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010240d:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102412:	72 36                	jb     f010244a <mem_init+0x1335>
f0102414:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102419:	76 07                	jbe    f0102422 <mem_init+0x130d>
f010241b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102420:	75 28                	jne    f010244a <mem_init+0x1335>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102422:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102426:	0f 85 83 00 00 00    	jne    f01024af <mem_init+0x139a>
f010242c:	68 b4 57 10 f0       	push   $0xf01057b4
f0102431:	68 27 55 10 f0       	push   $0xf0105527
f0102436:	68 3b 03 00 00       	push   $0x33b
f010243b:	68 01 55 10 f0       	push   $0xf0105501
f0102440:	e8 5b dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102445:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010244a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010244f:	76 3f                	jbe    f0102490 <mem_init+0x137b>
				assert(pgdir[i] & PTE_P);
f0102451:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102454:	f6 c2 01             	test   $0x1,%dl
f0102457:	75 19                	jne    f0102472 <mem_init+0x135d>
f0102459:	68 b4 57 10 f0       	push   $0xf01057b4
f010245e:	68 27 55 10 f0       	push   $0xf0105527
f0102463:	68 3f 03 00 00       	push   $0x33f
f0102468:	68 01 55 10 f0       	push   $0xf0105501
f010246d:	e8 2e dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102472:	f6 c2 02             	test   $0x2,%dl
f0102475:	75 38                	jne    f01024af <mem_init+0x139a>
f0102477:	68 c5 57 10 f0       	push   $0xf01057c5
f010247c:	68 27 55 10 f0       	push   $0xf0105527
f0102481:	68 40 03 00 00       	push   $0x340
f0102486:	68 01 55 10 f0       	push   $0xf0105501
f010248b:	e8 10 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102490:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102494:	74 19                	je     f01024af <mem_init+0x139a>
f0102496:	68 d6 57 10 f0       	push   $0xf01057d6
f010249b:	68 27 55 10 f0       	push   $0xf0105527
f01024a0:	68 42 03 00 00       	push   $0x342
f01024a5:	68 01 55 10 f0       	push   $0xf0105501
f01024aa:	e8 f1 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01024af:	83 c0 01             	add    $0x1,%eax
f01024b2:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024b7:	0f 86 50 ff ff ff    	jbe    f010240d <mem_init+0x12f8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024bd:	83 ec 0c             	sub    $0xc,%esp
f01024c0:	68 38 54 10 f0       	push   $0xf0105438
f01024c5:	e8 67 0a 00 00       	call   f0102f31 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024ca:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024cf:	83 c4 10             	add    $0x10,%esp
f01024d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024d7:	77 15                	ja     f01024ee <mem_init+0x13d9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024d9:	50                   	push   %eax
f01024da:	68 e8 4c 10 f0       	push   $0xf0104ce8
f01024df:	68 f3 00 00 00       	push   $0xf3
f01024e4:	68 01 55 10 f0       	push   $0xf0105501
f01024e9:	e8 b2 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01024ee:	05 00 00 00 10       	add    $0x10000000,%eax
f01024f3:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01024fb:	e8 5f e5 ff ff       	call   f0100a5f <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102500:	0f 20 c0             	mov    %cr0,%eax
f0102503:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102506:	0d 23 00 05 80       	or     $0x80050023,%eax
f010250b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010250e:	83 ec 0c             	sub    $0xc,%esp
f0102511:	6a 00                	push   $0x0
f0102513:	e8 d5 e8 ff ff       	call   f0100ded <page_alloc>
f0102518:	89 c7                	mov    %eax,%edi
f010251a:	83 c4 10             	add    $0x10,%esp
f010251d:	85 c0                	test   %eax,%eax
f010251f:	75 19                	jne    f010253a <mem_init+0x1425>
f0102521:	68 d2 55 10 f0       	push   $0xf01055d2
f0102526:	68 27 55 10 f0       	push   $0xf0105527
f010252b:	68 02 04 00 00       	push   $0x402
f0102530:	68 01 55 10 f0       	push   $0xf0105501
f0102535:	e8 66 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010253a:	83 ec 0c             	sub    $0xc,%esp
f010253d:	6a 00                	push   $0x0
f010253f:	e8 a9 e8 ff ff       	call   f0100ded <page_alloc>
f0102544:	89 c6                	mov    %eax,%esi
f0102546:	83 c4 10             	add    $0x10,%esp
f0102549:	85 c0                	test   %eax,%eax
f010254b:	75 19                	jne    f0102566 <mem_init+0x1451>
f010254d:	68 e8 55 10 f0       	push   $0xf01055e8
f0102552:	68 27 55 10 f0       	push   $0xf0105527
f0102557:	68 03 04 00 00       	push   $0x403
f010255c:	68 01 55 10 f0       	push   $0xf0105501
f0102561:	e8 3a db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102566:	83 ec 0c             	sub    $0xc,%esp
f0102569:	6a 00                	push   $0x0
f010256b:	e8 7d e8 ff ff       	call   f0100ded <page_alloc>
f0102570:	89 c3                	mov    %eax,%ebx
f0102572:	83 c4 10             	add    $0x10,%esp
f0102575:	85 c0                	test   %eax,%eax
f0102577:	75 19                	jne    f0102592 <mem_init+0x147d>
f0102579:	68 fe 55 10 f0       	push   $0xf01055fe
f010257e:	68 27 55 10 f0       	push   $0xf0105527
f0102583:	68 04 04 00 00       	push   $0x404
f0102588:	68 01 55 10 f0       	push   $0xf0105501
f010258d:	e8 0e db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102592:	83 ec 0c             	sub    $0xc,%esp
f0102595:	57                   	push   %edi
f0102596:	e8 c2 e8 ff ff       	call   f0100e5d <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010259b:	89 f0                	mov    %esi,%eax
f010259d:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01025a3:	c1 f8 03             	sar    $0x3,%eax
f01025a6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a9:	89 c2                	mov    %eax,%edx
f01025ab:	c1 ea 0c             	shr    $0xc,%edx
f01025ae:	83 c4 10             	add    $0x10,%esp
f01025b1:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01025b7:	72 12                	jb     f01025cb <mem_init+0x14b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b9:	50                   	push   %eax
f01025ba:	68 c4 4c 10 f0       	push   $0xf0104cc4
f01025bf:	6a 56                	push   $0x56
f01025c1:	68 0d 55 10 f0       	push   $0xf010550d
f01025c6:	e8 d5 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025cb:	83 ec 04             	sub    $0x4,%esp
f01025ce:	68 00 10 00 00       	push   $0x1000
f01025d3:	6a 01                	push   $0x1
f01025d5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025da:	50                   	push   %eax
f01025db:	e8 2c 1d 00 00       	call   f010430c <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025e0:	89 d8                	mov    %ebx,%eax
f01025e2:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01025e8:	c1 f8 03             	sar    $0x3,%eax
f01025eb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025ee:	89 c2                	mov    %eax,%edx
f01025f0:	c1 ea 0c             	shr    $0xc,%edx
f01025f3:	83 c4 10             	add    $0x10,%esp
f01025f6:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01025fc:	72 12                	jb     f0102610 <mem_init+0x14fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025fe:	50                   	push   %eax
f01025ff:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102604:	6a 56                	push   $0x56
f0102606:	68 0d 55 10 f0       	push   $0xf010550d
f010260b:	e8 90 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102610:	83 ec 04             	sub    $0x4,%esp
f0102613:	68 00 10 00 00       	push   $0x1000
f0102618:	6a 02                	push   $0x2
f010261a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010261f:	50                   	push   %eax
f0102620:	e8 e7 1c 00 00       	call   f010430c <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102625:	6a 02                	push   $0x2
f0102627:	68 00 10 00 00       	push   $0x1000
f010262c:	56                   	push   %esi
f010262d:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102633:	e8 74 ea ff ff       	call   f01010ac <page_insert>
	assert(pp1->pp_ref == 1);
f0102638:	83 c4 20             	add    $0x20,%esp
f010263b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102640:	74 19                	je     f010265b <mem_init+0x1546>
f0102642:	68 cf 56 10 f0       	push   $0xf01056cf
f0102647:	68 27 55 10 f0       	push   $0xf0105527
f010264c:	68 09 04 00 00       	push   $0x409
f0102651:	68 01 55 10 f0       	push   $0xf0105501
f0102656:	e8 45 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010265b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102662:	01 01 01 
f0102665:	74 19                	je     f0102680 <mem_init+0x156b>
f0102667:	68 58 54 10 f0       	push   $0xf0105458
f010266c:	68 27 55 10 f0       	push   $0xf0105527
f0102671:	68 0a 04 00 00       	push   $0x40a
f0102676:	68 01 55 10 f0       	push   $0xf0105501
f010267b:	e8 20 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102680:	6a 02                	push   $0x2
f0102682:	68 00 10 00 00       	push   $0x1000
f0102687:	53                   	push   %ebx
f0102688:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010268e:	e8 19 ea ff ff       	call   f01010ac <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102693:	83 c4 10             	add    $0x10,%esp
f0102696:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010269d:	02 02 02 
f01026a0:	74 19                	je     f01026bb <mem_init+0x15a6>
f01026a2:	68 7c 54 10 f0       	push   $0xf010547c
f01026a7:	68 27 55 10 f0       	push   $0xf0105527
f01026ac:	68 0c 04 00 00       	push   $0x40c
f01026b1:	68 01 55 10 f0       	push   $0xf0105501
f01026b6:	e8 e5 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026bb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026c0:	74 19                	je     f01026db <mem_init+0x15c6>
f01026c2:	68 f1 56 10 f0       	push   $0xf01056f1
f01026c7:	68 27 55 10 f0       	push   $0xf0105527
f01026cc:	68 0d 04 00 00       	push   $0x40d
f01026d1:	68 01 55 10 f0       	push   $0xf0105501
f01026d6:	e8 c5 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026db:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026e0:	74 19                	je     f01026fb <mem_init+0x15e6>
f01026e2:	68 5b 57 10 f0       	push   $0xf010575b
f01026e7:	68 27 55 10 f0       	push   $0xf0105527
f01026ec:	68 0e 04 00 00       	push   $0x40e
f01026f1:	68 01 55 10 f0       	push   $0xf0105501
f01026f6:	e8 a5 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026fb:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102702:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102705:	89 d8                	mov    %ebx,%eax
f0102707:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010270d:	c1 f8 03             	sar    $0x3,%eax
f0102710:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102713:	89 c2                	mov    %eax,%edx
f0102715:	c1 ea 0c             	shr    $0xc,%edx
f0102718:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f010271e:	72 12                	jb     f0102732 <mem_init+0x161d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102720:	50                   	push   %eax
f0102721:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102726:	6a 56                	push   $0x56
f0102728:	68 0d 55 10 f0       	push   $0xf010550d
f010272d:	e8 6e d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102732:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102739:	03 03 03 
f010273c:	74 19                	je     f0102757 <mem_init+0x1642>
f010273e:	68 a0 54 10 f0       	push   $0xf01054a0
f0102743:	68 27 55 10 f0       	push   $0xf0105527
f0102748:	68 10 04 00 00       	push   $0x410
f010274d:	68 01 55 10 f0       	push   $0xf0105501
f0102752:	e8 49 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102757:	83 ec 08             	sub    $0x8,%esp
f010275a:	68 00 10 00 00       	push   $0x1000
f010275f:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102765:	e8 f8 e8 ff ff       	call   f0101062 <page_remove>
	assert(pp2->pp_ref == 0);
f010276a:	83 c4 10             	add    $0x10,%esp
f010276d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102772:	74 19                	je     f010278d <mem_init+0x1678>
f0102774:	68 29 57 10 f0       	push   $0xf0105729
f0102779:	68 27 55 10 f0       	push   $0xf0105527
f010277e:	68 12 04 00 00       	push   $0x412
f0102783:	68 01 55 10 f0       	push   $0xf0105501
f0102788:	e8 13 d9 ff ff       	call   f01000a0 <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010278d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102790:	5b                   	pop    %ebx
f0102791:	5e                   	pop    %esi
f0102792:	5f                   	pop    %edi
f0102793:	5d                   	pop    %ebp
f0102794:	c3                   	ret    

f0102795 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102795:	55                   	push   %ebp
f0102796:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102798:	8b 45 0c             	mov    0xc(%ebp),%eax
f010279b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010279e:	5d                   	pop    %ebp
f010279f:	c3                   	ret    

f01027a0 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01027a0:	55                   	push   %ebp
f01027a1:	89 e5                	mov    %esp,%ebp
f01027a3:	57                   	push   %edi
f01027a4:	56                   	push   %esi
f01027a5:	53                   	push   %ebx
f01027a6:	83 ec 1c             	sub    $0x1c,%esp
f01027a9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01027ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01027af:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);
f01027b2:	89 d8                	mov    %ebx,%eax
f01027b4:	03 45 10             	add    0x10(%ebp),%eax
f01027b7:	05 ff 0f 00 00       	add    $0xfff,%eax
f01027bc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f01027c4:	eb 3e                	jmp    f0102804 <user_mem_check+0x64>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, va, 0);
f01027c6:	83 ec 04             	sub    $0x4,%esp
f01027c9:	6a 00                	push   $0x0
f01027cb:	53                   	push   %ebx
f01027cc:	ff 77 5c             	pushl  0x5c(%edi)
f01027cf:	e8 eb e6 ff ff       	call   f0100ebf <pgdir_walk>

		if ((va >= (void*) ULIM) || !pte || ((*pte & perm) != perm))
f01027d4:	83 c4 10             	add    $0x10,%esp
f01027d7:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01027dd:	77 0c                	ja     f01027eb <user_mem_check+0x4b>
f01027df:	85 c0                	test   %eax,%eax
f01027e1:	74 08                	je     f01027eb <user_mem_check+0x4b>
f01027e3:	89 f2                	mov    %esi,%edx
f01027e5:	23 10                	and    (%eax),%edx
f01027e7:	39 d6                	cmp    %edx,%esi
f01027e9:	74 0d                	je     f01027f8 <user_mem_check+0x58>
		{
			user_mem_check_addr = (uint32_t) va;
f01027eb:	89 1d 7c 1f 17 f0    	mov    %ebx,0xf0171f7c
			return -E_FAULT;
f01027f1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027f6:	eb 16                	jmp    f010280e <user_mem_check+0x6e>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	const void* end = ROUNDUP(va + len, PGSIZE);

	for (; va < end; va = ROUNDDOWN(va + PGSIZE, PGSIZE))
f01027f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027fe:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102804:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102807:	72 bd                	jb     f01027c6 <user_mem_check+0x26>
			user_mem_check_addr = (uint32_t) va;
			return -E_FAULT;
		}		
	}

	return 0;
f0102809:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010280e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102811:	5b                   	pop    %ebx
f0102812:	5e                   	pop    %esi
f0102813:	5f                   	pop    %edi
f0102814:	5d                   	pop    %ebp
f0102815:	c3                   	ret    

f0102816 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102816:	55                   	push   %ebp
f0102817:	89 e5                	mov    %esp,%ebp
f0102819:	53                   	push   %ebx
f010281a:	83 ec 04             	sub    $0x4,%esp
f010281d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102820:	8b 45 14             	mov    0x14(%ebp),%eax
f0102823:	83 c8 04             	or     $0x4,%eax
f0102826:	50                   	push   %eax
f0102827:	ff 75 10             	pushl  0x10(%ebp)
f010282a:	ff 75 0c             	pushl  0xc(%ebp)
f010282d:	53                   	push   %ebx
f010282e:	e8 6d ff ff ff       	call   f01027a0 <user_mem_check>
f0102833:	83 c4 10             	add    $0x10,%esp
f0102836:	85 c0                	test   %eax,%eax
f0102838:	79 21                	jns    f010285b <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f010283a:	83 ec 04             	sub    $0x4,%esp
f010283d:	ff 35 7c 1f 17 f0    	pushl  0xf0171f7c
f0102843:	ff 73 48             	pushl  0x48(%ebx)
f0102846:	68 cc 54 10 f0       	push   $0xf01054cc
f010284b:	e8 e1 06 00 00       	call   f0102f31 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102850:	89 1c 24             	mov    %ebx,(%esp)
f0102853:	e8 c0 05 00 00       	call   f0102e18 <env_destroy>
f0102858:	83 c4 10             	add    $0x10,%esp
	}
}
f010285b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010285e:	c9                   	leave  
f010285f:	c3                   	ret    

f0102860 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102860:	55                   	push   %ebp
f0102861:	89 e5                	mov    %esp,%ebp
f0102863:	57                   	push   %edi
f0102864:	56                   	push   %esi
f0102865:	53                   	push   %ebx
f0102866:	83 ec 0c             	sub    $0xc,%esp
f0102869:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
f010286b:	89 d3                	mov    %edx,%ebx
f010286d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);
f0102873:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010287a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; round_begin < round_end; round_begin += PGSIZE)
f0102880:	eb 3d                	jmp    f01028bf <region_alloc+0x5f>
	{
		page = page_alloc(0);
f0102882:	83 ec 0c             	sub    $0xc,%esp
f0102885:	6a 00                	push   $0x0
f0102887:	e8 61 e5 ff ff       	call   f0100ded <page_alloc>

		if(!page)
f010288c:	83 c4 10             	add    $0x10,%esp
f010288f:	85 c0                	test   %eax,%eax
f0102891:	75 17                	jne    f01028aa <region_alloc+0x4a>
			panic("region_alloc: page allocation failed!");
f0102893:	83 ec 04             	sub    $0x4,%esp
f0102896:	68 e4 57 10 f0       	push   $0xf01057e4
f010289b:	68 26 01 00 00       	push   $0x126
f01028a0:	68 66 58 10 f0       	push   $0xf0105866
f01028a5:	e8 f6 d7 ff ff       	call   f01000a0 <_panic>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
f01028aa:	6a 06                	push   $0x6
f01028ac:	53                   	push   %ebx
f01028ad:	50                   	push   %eax
f01028ae:	ff 77 5c             	pushl  0x5c(%edi)
f01028b1:	e8 f6 e7 ff ff       	call   f01010ac <page_insert>
	struct PageInfo *page = NULL;	

	uintptr_t round_begin = ROUNDDOWN((uintptr_t) va, PGSIZE);
	uintptr_t round_end = ROUNDUP((uintptr_t) va + len, PGSIZE);

	for(; round_begin < round_end; round_begin += PGSIZE)
f01028b6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028bc:	83 c4 10             	add    $0x10,%esp
f01028bf:	39 f3                	cmp    %esi,%ebx
f01028c1:	72 bf                	jb     f0102882 <region_alloc+0x22>

		page_insert(e->env_pgdir, page, (void*) round_begin, (PTE_U | PTE_W));
	}
	
	
}
f01028c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028c6:	5b                   	pop    %ebx
f01028c7:	5e                   	pop    %esi
f01028c8:	5f                   	pop    %edi
f01028c9:	5d                   	pop    %ebp
f01028ca:	c3                   	ret    

f01028cb <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01028cb:	55                   	push   %ebp
f01028cc:	89 e5                	mov    %esp,%ebp
f01028ce:	8b 55 08             	mov    0x8(%ebp),%edx
f01028d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01028d4:	85 d2                	test   %edx,%edx
f01028d6:	75 11                	jne    f01028e9 <envid2env+0x1e>
		*env_store = curenv;
f01028d8:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f01028dd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028e0:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01028e7:	eb 5e                	jmp    f0102947 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028e9:	89 d0                	mov    %edx,%eax
f01028eb:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028f0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028f3:	c1 e0 05             	shl    $0x5,%eax
f01028f6:	03 05 88 1f 17 f0    	add    0xf0171f88,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028fc:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102900:	74 05                	je     f0102907 <envid2env+0x3c>
f0102902:	3b 50 48             	cmp    0x48(%eax),%edx
f0102905:	74 10                	je     f0102917 <envid2env+0x4c>
		*env_store = 0;
f0102907:	8b 45 0c             	mov    0xc(%ebp),%eax
f010290a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102910:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102915:	eb 30                	jmp    f0102947 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102917:	84 c9                	test   %cl,%cl
f0102919:	74 22                	je     f010293d <envid2env+0x72>
f010291b:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102921:	39 d0                	cmp    %edx,%eax
f0102923:	74 18                	je     f010293d <envid2env+0x72>
f0102925:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102928:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010292b:	74 10                	je     f010293d <envid2env+0x72>
		*env_store = 0;
f010292d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102930:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102936:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010293b:	eb 0a                	jmp    f0102947 <envid2env+0x7c>
	}

	*env_store = e;
f010293d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102940:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102942:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102947:	5d                   	pop    %ebp
f0102948:	c3                   	ret    

f0102949 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102949:	55                   	push   %ebp
f010294a:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f010294c:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102951:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102954:	b8 23 00 00 00       	mov    $0x23,%eax
f0102959:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010295b:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010295d:	b8 10 00 00 00       	mov    $0x10,%eax
f0102962:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102964:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102966:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102968:	ea 6f 29 10 f0 08 00 	ljmp   $0x8,$0xf010296f
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f010296f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102974:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102977:	5d                   	pop    %ebp
f0102978:	c3                   	ret    

f0102979 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102979:	55                   	push   %ebp
f010297a:	89 e5                	mov    %esp,%ebp
f010297c:	56                   	push   %esi
f010297d:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
	{
		envs[i].env_id = 0;
f010297e:	8b 35 88 1f 17 f0    	mov    0xf0171f88,%esi
f0102984:	8b 15 8c 1f 17 f0    	mov    0xf0171f8c,%edx
f010298a:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102990:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102993:	89 c1                	mov    %eax,%ecx
f0102995:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f010299c:	89 50 44             	mov    %edx,0x44(%eax)
f010299f:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];	
f01029a2:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for(i = NENV - 1; i >= 0; --i)
f01029a4:	39 d8                	cmp    %ebx,%eax
f01029a6:	75 eb                	jne    f0102993 <env_init+0x1a>
f01029a8:	89 35 8c 1f 17 f0    	mov    %esi,0xf0171f8c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];	
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f01029ae:	e8 96 ff ff ff       	call   f0102949 <env_init_percpu>
}
f01029b3:	5b                   	pop    %ebx
f01029b4:	5e                   	pop    %esi
f01029b5:	5d                   	pop    %ebp
f01029b6:	c3                   	ret    

f01029b7 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029b7:	55                   	push   %ebp
f01029b8:	89 e5                	mov    %esp,%ebp
f01029ba:	53                   	push   %ebx
f01029bb:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029be:	8b 1d 8c 1f 17 f0    	mov    0xf0171f8c,%ebx
f01029c4:	85 db                	test   %ebx,%ebx
f01029c6:	0f 84 4a 01 00 00    	je     f0102b16 <env_alloc+0x15f>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01029cc:	83 ec 0c             	sub    $0xc,%esp
f01029cf:	6a 01                	push   $0x1
f01029d1:	e8 17 e4 ff ff       	call   f0100ded <page_alloc>
f01029d6:	83 c4 10             	add    $0x10,%esp
f01029d9:	85 c0                	test   %eax,%eax
f01029db:	0f 84 3c 01 00 00    	je     f0102b1d <env_alloc+0x166>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f01029e1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029e6:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01029ec:	c1 f8 03             	sar    $0x3,%eax
f01029ef:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029f2:	89 c2                	mov    %eax,%edx
f01029f4:	c1 ea 0c             	shr    $0xc,%edx
f01029f7:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01029fd:	72 12                	jb     f0102a11 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029ff:	50                   	push   %eax
f0102a00:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102a05:	6a 56                	push   $0x56
f0102a07:	68 0d 55 10 f0       	push   $0xf010550d
f0102a0c:	e8 8f d6 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = (pde_t*) page2kva(p);
f0102a11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a16:	89 43 5c             	mov    %eax,0x5c(%ebx)
f0102a19:	b8 ec 0e 00 00       	mov    $0xeec,%eax
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102a1e:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f0102a24:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102a27:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102a2a:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102a2d:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*) page2kva(p);
	
	for(i = PDX(UTOP); i < NPDENTRIES; ++i)
f0102a30:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102a35:	75 e7                	jne    f0102a1e <env_alloc+0x67>
		e->env_pgdir[i] = kern_pgdir[i];
	}

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102a37:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a3a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a3f:	77 15                	ja     f0102a56 <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a41:	50                   	push   %eax
f0102a42:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102a47:	68 c7 00 00 00       	push   $0xc7
f0102a4c:	68 66 58 10 f0       	push   $0xf0105866
f0102a51:	e8 4a d6 ff ff       	call   f01000a0 <_panic>
f0102a56:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a5c:	83 ca 05             	or     $0x5,%edx
f0102a5f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a65:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a68:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a6d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a72:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a77:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a7a:	89 da                	mov    %ebx,%edx
f0102a7c:	2b 15 88 1f 17 f0    	sub    0xf0171f88,%edx
f0102a82:	c1 fa 05             	sar    $0x5,%edx
f0102a85:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a8b:	09 d0                	or     %edx,%eax
f0102a8d:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a90:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a93:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a96:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a9d:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102aa4:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102aab:	83 ec 04             	sub    $0x4,%esp
f0102aae:	6a 44                	push   $0x44
f0102ab0:	6a 00                	push   $0x0
f0102ab2:	53                   	push   %ebx
f0102ab3:	e8 54 18 00 00       	call   f010430c <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102ab8:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102abe:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102ac4:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102aca:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102ad1:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102ad7:	8b 43 44             	mov    0x44(%ebx),%eax
f0102ada:	a3 8c 1f 17 f0       	mov    %eax,0xf0171f8c
	*newenv_store = e;
f0102adf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ae2:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ae4:	8b 53 48             	mov    0x48(%ebx),%edx
f0102ae7:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0102aec:	83 c4 10             	add    $0x10,%esp
f0102aef:	85 c0                	test   %eax,%eax
f0102af1:	74 05                	je     f0102af8 <env_alloc+0x141>
f0102af3:	8b 40 48             	mov    0x48(%eax),%eax
f0102af6:	eb 05                	jmp    f0102afd <env_alloc+0x146>
f0102af8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102afd:	83 ec 04             	sub    $0x4,%esp
f0102b00:	52                   	push   %edx
f0102b01:	50                   	push   %eax
f0102b02:	68 71 58 10 f0       	push   $0xf0105871
f0102b07:	e8 25 04 00 00       	call   f0102f31 <cprintf>
	return 0;
f0102b0c:	83 c4 10             	add    $0x10,%esp
f0102b0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b14:	eb 0c                	jmp    f0102b22 <env_alloc+0x16b>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102b16:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102b1b:	eb 05                	jmp    f0102b22 <env_alloc+0x16b>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102b1d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102b22:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b25:	c9                   	leave  
f0102b26:	c3                   	ret    

f0102b27 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102b27:	55                   	push   %ebp
f0102b28:	89 e5                	mov    %esp,%ebp
f0102b2a:	57                   	push   %edi
f0102b2b:	56                   	push   %esi
f0102b2c:	53                   	push   %ebx
f0102b2d:	83 ec 34             	sub    $0x34,%esp
f0102b30:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e = NULL;
f0102b33:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	uint32_t result = env_alloc(&e, 0);
f0102b3a:	6a 00                	push   $0x0
f0102b3c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102b3f:	50                   	push   %eax
f0102b40:	e8 72 fe ff ff       	call   f01029b7 <env_alloc>

	if(result !=  0)
f0102b45:	83 c4 10             	add    $0x10,%esp
f0102b48:	85 c0                	test   %eax,%eax
f0102b4a:	74 15                	je     f0102b61 <env_create+0x3a>
		panic("env_create: %e", result);
f0102b4c:	50                   	push   %eax
f0102b4d:	68 86 58 10 f0       	push   $0xf0105886
f0102b52:	68 95 01 00 00       	push   $0x195
f0102b57:	68 66 58 10 f0       	push   $0xf0105866
f0102b5c:	e8 3f d5 ff ff       	call   f01000a0 <_panic>

	load_icode(e, binary);
f0102b61:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b64:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph = NULL, *eph = NULL;
	struct Elf *elf = (struct Elf*) binary;
	
	if(elf->e_magic != ELF_MAGIC)
f0102b67:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b6d:	74 17                	je     f0102b86 <env_create+0x5f>
		panic("load icode: Elf format not valid!");
f0102b6f:	83 ec 04             	sub    $0x4,%esp
f0102b72:	68 0c 58 10 f0       	push   $0xf010580c
f0102b77:	68 68 01 00 00       	push   $0x168
f0102b7c:	68 66 58 10 f0       	push   $0xf0105866
f0102b81:	e8 1a d5 ff ff       	call   f01000a0 <_panic>

	ph = (struct Proghdr*) (binary + elf->e_phoff);
f0102b86:	89 fb                	mov    %edi,%ebx
f0102b88:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0102b8b:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b8f:	c1 e6 05             	shl    $0x5,%esi
f0102b92:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0102b94:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b97:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b9a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b9f:	77 15                	ja     f0102bb6 <env_create+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ba1:	50                   	push   %eax
f0102ba2:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102ba7:	68 6d 01 00 00       	push   $0x16d
f0102bac:	68 66 58 10 f0       	push   $0xf0105866
f0102bb1:	e8 ea d4 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102bb6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bbb:	0f 22 d8             	mov    %eax,%cr3
f0102bbe:	eb 44                	jmp    f0102c04 <env_create+0xdd>

	for( ; ph < eph; ++ph)
	{
		if(ph->p_type != ELF_PROG_LOAD)
f0102bc0:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102bc3:	75 3c                	jne    f0102c01 <env_create+0xda>
			continue;		

		region_alloc(e, (void*) ph->p_va, ph->p_memsz);
f0102bc5:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102bc8:	8b 53 08             	mov    0x8(%ebx),%edx
f0102bcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bce:	e8 8d fc ff ff       	call   f0102860 <region_alloc>
		
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102bd3:	83 ec 04             	sub    $0x4,%esp
f0102bd6:	ff 73 10             	pushl  0x10(%ebx)
f0102bd9:	89 f8                	mov    %edi,%eax
f0102bdb:	03 43 04             	add    0x4(%ebx),%eax
f0102bde:	50                   	push   %eax
f0102bdf:	ff 73 08             	pushl  0x8(%ebx)
f0102be2:	e8 da 17 00 00       	call   f01043c1 <memcpy>
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
f0102be7:	8b 43 10             	mov    0x10(%ebx),%eax
f0102bea:	83 c4 0c             	add    $0xc,%esp
f0102bed:	8b 53 14             	mov    0x14(%ebx),%edx
f0102bf0:	29 c2                	sub    %eax,%edx
f0102bf2:	52                   	push   %edx
f0102bf3:	6a 00                	push   $0x0
f0102bf5:	03 43 08             	add    0x8(%ebx),%eax
f0102bf8:	50                   	push   %eax
f0102bf9:	e8 0e 17 00 00       	call   f010430c <memset>
f0102bfe:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr*) (binary + elf->e_phoff);
	eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));

	for( ; ph < eph; ++ph)
f0102c01:	83 c3 20             	add    $0x20,%ebx
f0102c04:	39 de                	cmp    %ebx,%esi
f0102c06:	77 b8                	ja     f0102bc0 <env_create+0x99>
		memcpy((void*) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		
		memset((void*) ph->p_va + ph->p_filesz, '\0', ph->p_memsz - ph->p_filesz);
	}

	e->env_tf.tf_eip = elf->e_entry;
f0102c08:	8b 47 18             	mov    0x18(%edi),%eax
f0102c0b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c0e:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*) USTACKTOP - PGSIZE, PGSIZE);
f0102c11:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102c16:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102c1b:	89 f8                	mov    %edi,%eax
f0102c1d:	e8 3e fc ff ff       	call   f0102860 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f0102c22:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c27:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c2c:	77 15                	ja     f0102c43 <env_create+0x11c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c2e:	50                   	push   %eax
f0102c2f:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102c34:	68 83 01 00 00       	push   $0x183
f0102c39:	68 66 58 10 f0       	push   $0xf0105866
f0102c3e:	e8 5d d4 ff ff       	call   f01000a0 <_panic>
f0102c43:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c48:	0f 22 d8             	mov    %eax,%cr3

	if(result !=  0)
		panic("env_create: %e", result);

	load_icode(e, binary);
	e->env_type = type;
f0102c4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c4e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c51:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c54:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c57:	5b                   	pop    %ebx
f0102c58:	5e                   	pop    %esi
f0102c59:	5f                   	pop    %edi
f0102c5a:	5d                   	pop    %ebp
f0102c5b:	c3                   	ret    

f0102c5c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c5c:	55                   	push   %ebp
f0102c5d:	89 e5                	mov    %esp,%ebp
f0102c5f:	57                   	push   %edi
f0102c60:	56                   	push   %esi
f0102c61:	53                   	push   %ebx
f0102c62:	83 ec 1c             	sub    $0x1c,%esp
f0102c65:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c68:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102c6e:	39 fa                	cmp    %edi,%edx
f0102c70:	75 29                	jne    f0102c9b <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c72:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c77:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c7c:	77 15                	ja     f0102c93 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c7e:	50                   	push   %eax
f0102c7f:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102c84:	68 a9 01 00 00       	push   $0x1a9
f0102c89:	68 66 58 10 f0       	push   $0xf0105866
f0102c8e:	e8 0d d4 ff ff       	call   f01000a0 <_panic>
f0102c93:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c98:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c9b:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c9e:	85 d2                	test   %edx,%edx
f0102ca0:	74 05                	je     f0102ca7 <env_free+0x4b>
f0102ca2:	8b 42 48             	mov    0x48(%edx),%eax
f0102ca5:	eb 05                	jmp    f0102cac <env_free+0x50>
f0102ca7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cac:	83 ec 04             	sub    $0x4,%esp
f0102caf:	51                   	push   %ecx
f0102cb0:	50                   	push   %eax
f0102cb1:	68 95 58 10 f0       	push   $0xf0105895
f0102cb6:	e8 76 02 00 00       	call   f0102f31 <cprintf>
f0102cbb:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102cbe:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102cc5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102cc8:	89 d0                	mov    %edx,%eax
f0102cca:	c1 e0 02             	shl    $0x2,%eax
f0102ccd:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102cd0:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cd3:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102cd6:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102cdc:	0f 84 a8 00 00 00    	je     f0102d8a <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102ce2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ce8:	89 f0                	mov    %esi,%eax
f0102cea:	c1 e8 0c             	shr    $0xc,%eax
f0102ced:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cf0:	39 05 44 2c 17 f0    	cmp    %eax,0xf0172c44
f0102cf6:	77 15                	ja     f0102d0d <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cf8:	56                   	push   %esi
f0102cf9:	68 c4 4c 10 f0       	push   $0xf0104cc4
f0102cfe:	68 b8 01 00 00       	push   $0x1b8
f0102d03:	68 66 58 10 f0       	push   $0xf0105866
f0102d08:	e8 93 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d0d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d10:	c1 e0 16             	shl    $0x16,%eax
f0102d13:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d16:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102d1b:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102d22:	01 
f0102d23:	74 17                	je     f0102d3c <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d25:	83 ec 08             	sub    $0x8,%esp
f0102d28:	89 d8                	mov    %ebx,%eax
f0102d2a:	c1 e0 0c             	shl    $0xc,%eax
f0102d2d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102d30:	50                   	push   %eax
f0102d31:	ff 77 5c             	pushl  0x5c(%edi)
f0102d34:	e8 29 e3 ff ff       	call   f0101062 <page_remove>
f0102d39:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d3c:	83 c3 01             	add    $0x1,%ebx
f0102d3f:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d45:	75 d4                	jne    f0102d1b <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d47:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d4a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d4d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d54:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d57:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102d5d:	72 14                	jb     f0102d73 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102d5f:	83 ec 04             	sub    $0x4,%esp
f0102d62:	68 7c 4e 10 f0       	push   $0xf0104e7c
f0102d67:	6a 4f                	push   $0x4f
f0102d69:	68 0d 55 10 f0       	push   $0xf010550d
f0102d6e:	e8 2d d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d73:	83 ec 0c             	sub    $0xc,%esp
f0102d76:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0102d7b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d7e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d81:	50                   	push   %eax
f0102d82:	e8 11 e1 ff ff       	call   f0100e98 <page_decref>
f0102d87:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d8a:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d91:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d96:	0f 85 29 ff ff ff    	jne    f0102cc5 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d9c:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d9f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102da4:	77 15                	ja     f0102dbb <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102da6:	50                   	push   %eax
f0102da7:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102dac:	68 c6 01 00 00       	push   $0x1c6
f0102db1:	68 66 58 10 f0       	push   $0xf0105866
f0102db6:	e8 e5 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102dbb:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dc2:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dc7:	c1 e8 0c             	shr    $0xc,%eax
f0102dca:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102dd0:	72 14                	jb     f0102de6 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102dd2:	83 ec 04             	sub    $0x4,%esp
f0102dd5:	68 7c 4e 10 f0       	push   $0xf0104e7c
f0102dda:	6a 4f                	push   $0x4f
f0102ddc:	68 0d 55 10 f0       	push   $0xf010550d
f0102de1:	e8 ba d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102de6:	83 ec 0c             	sub    $0xc,%esp
f0102de9:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0102def:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102df2:	50                   	push   %eax
f0102df3:	e8 a0 e0 ff ff       	call   f0100e98 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102df8:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102dff:	a1 8c 1f 17 f0       	mov    0xf0171f8c,%eax
f0102e04:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e07:	89 3d 8c 1f 17 f0    	mov    %edi,0xf0171f8c
}
f0102e0d:	83 c4 10             	add    $0x10,%esp
f0102e10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e13:	5b                   	pop    %ebx
f0102e14:	5e                   	pop    %esi
f0102e15:	5f                   	pop    %edi
f0102e16:	5d                   	pop    %ebp
f0102e17:	c3                   	ret    

f0102e18 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e18:	55                   	push   %ebp
f0102e19:	89 e5                	mov    %esp,%ebp
f0102e1b:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e1e:	ff 75 08             	pushl  0x8(%ebp)
f0102e21:	e8 36 fe ff ff       	call   f0102c5c <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e26:	c7 04 24 30 58 10 f0 	movl   $0xf0105830,(%esp)
f0102e2d:	e8 ff 00 00 00       	call   f0102f31 <cprintf>
f0102e32:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e35:	83 ec 0c             	sub    $0xc,%esp
f0102e38:	6a 00                	push   $0x0
f0102e3a:	e8 ca d9 ff ff       	call   f0100809 <monitor>
f0102e3f:	83 c4 10             	add    $0x10,%esp
f0102e42:	eb f1                	jmp    f0102e35 <env_destroy+0x1d>

f0102e44 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e44:	55                   	push   %ebp
f0102e45:	89 e5                	mov    %esp,%ebp
f0102e47:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102e4a:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e4d:	61                   	popa   
f0102e4e:	07                   	pop    %es
f0102e4f:	1f                   	pop    %ds
f0102e50:	83 c4 08             	add    $0x8,%esp
f0102e53:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e54:	68 ab 58 10 f0       	push   $0xf01058ab
f0102e59:	68 ef 01 00 00       	push   $0x1ef
f0102e5e:	68 66 58 10 f0       	push   $0xf0105866
f0102e63:	e8 38 d2 ff ff       	call   f01000a0 <_panic>

f0102e68 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e68:	55                   	push   %ebp
f0102e69:	89 e5                	mov    %esp,%ebp
f0102e6b:	83 ec 08             	sub    $0x8,%esp
f0102e6e:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && (curenv->env_status == ENV_RUNNING))
f0102e71:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102e77:	85 d2                	test   %edx,%edx
f0102e79:	74 0d                	je     f0102e88 <env_run+0x20>
f0102e7b:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e7f:	75 07                	jne    f0102e88 <env_run+0x20>
	{
		curenv->env_status = ENV_RUNNABLE;
f0102e81:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}

	curenv = e;
f0102e88:	a3 84 1f 17 f0       	mov    %eax,0xf0171f84
	e->env_status = ENV_RUNNING;
f0102e8d:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102e94:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0102e98:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e9b:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102ea1:	77 15                	ja     f0102eb8 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ea3:	52                   	push   %edx
f0102ea4:	68 e8 4c 10 f0       	push   $0xf0104ce8
f0102ea9:	68 15 02 00 00       	push   $0x215
f0102eae:	68 66 58 10 f0       	push   $0xf0105866
f0102eb3:	e8 e8 d1 ff ff       	call   f01000a0 <_panic>
f0102eb8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102ebe:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&e->env_tf);
f0102ec1:	83 ec 0c             	sub    $0xc,%esp
f0102ec4:	50                   	push   %eax
f0102ec5:	e8 7a ff ff ff       	call   f0102e44 <env_pop_tf>

f0102eca <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102eca:	55                   	push   %ebp
f0102ecb:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ecd:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ed2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ed5:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ed6:	ba 71 00 00 00       	mov    $0x71,%edx
f0102edb:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102edc:	0f b6 c0             	movzbl %al,%eax
}
f0102edf:	5d                   	pop    %ebp
f0102ee0:	c3                   	ret    

f0102ee1 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ee1:	55                   	push   %ebp
f0102ee2:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ee4:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ee9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102eec:	ee                   	out    %al,(%dx)
f0102eed:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ef2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ef5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ef6:	5d                   	pop    %ebp
f0102ef7:	c3                   	ret    

f0102ef8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ef8:	55                   	push   %ebp
f0102ef9:	89 e5                	mov    %esp,%ebp
f0102efb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102efe:	ff 75 08             	pushl  0x8(%ebp)
f0102f01:	e8 0f d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102f06:	83 c4 10             	add    $0x10,%esp
f0102f09:	c9                   	leave  
f0102f0a:	c3                   	ret    

f0102f0b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f0b:	55                   	push   %ebp
f0102f0c:	89 e5                	mov    %esp,%ebp
f0102f0e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102f11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f18:	ff 75 0c             	pushl  0xc(%ebp)
f0102f1b:	ff 75 08             	pushl  0x8(%ebp)
f0102f1e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f21:	50                   	push   %eax
f0102f22:	68 f8 2e 10 f0       	push   $0xf0102ef8
f0102f27:	e8 74 0d 00 00       	call   f0103ca0 <vprintfmt>
	return cnt;
}
f0102f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f2f:	c9                   	leave  
f0102f30:	c3                   	ret    

f0102f31 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f31:	55                   	push   %ebp
f0102f32:	89 e5                	mov    %esp,%ebp
f0102f34:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f37:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f3a:	50                   	push   %eax
f0102f3b:	ff 75 08             	pushl  0x8(%ebp)
f0102f3e:	e8 c8 ff ff ff       	call   f0102f0b <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f43:	c9                   	leave  
f0102f44:	c3                   	ret    

f0102f45 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f45:	55                   	push   %ebp
f0102f46:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f48:	b8 c0 27 17 f0       	mov    $0xf01727c0,%eax
f0102f4d:	c7 05 c4 27 17 f0 00 	movl   $0xf0000000,0xf01727c4
f0102f54:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f57:	66 c7 05 c8 27 17 f0 	movw   $0x10,0xf01727c8
f0102f5e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f60:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102f67:	67 00 
f0102f69:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0102f6f:	89 c2                	mov    %eax,%edx
f0102f71:	c1 ea 10             	shr    $0x10,%edx
f0102f74:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0102f7a:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0102f81:	c1 e8 18             	shr    $0x18,%eax
f0102f84:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f89:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f90:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f95:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f98:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0102f9d:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102fa0:	5d                   	pop    %ebp
f0102fa1:	c3                   	ret    

f0102fa2 <trap_init>:
}


void
trap_init(void)
{
f0102fa2:	55                   	push   %ebp
f0102fa3:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0102fa5:	b8 78 36 10 f0       	mov    $0xf0103678,%eax
f0102faa:	66 a3 a0 1f 17 f0    	mov    %ax,0xf0171fa0
f0102fb0:	66 c7 05 a2 1f 17 f0 	movw   $0x8,0xf0171fa2
f0102fb7:	08 00 
f0102fb9:	c6 05 a4 1f 17 f0 00 	movb   $0x0,0xf0171fa4
f0102fc0:	c6 05 a5 1f 17 f0 8e 	movb   $0x8e,0xf0171fa5
f0102fc7:	c1 e8 10             	shr    $0x10,%eax
f0102fca:	66 a3 a6 1f 17 f0    	mov    %ax,0xf0171fa6
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f0102fd0:	b8 7e 36 10 f0       	mov    $0xf010367e,%eax
f0102fd5:	66 a3 a8 1f 17 f0    	mov    %ax,0xf0171fa8
f0102fdb:	66 c7 05 aa 1f 17 f0 	movw   $0x8,0xf0171faa
f0102fe2:	08 00 
f0102fe4:	c6 05 ac 1f 17 f0 00 	movb   $0x0,0xf0171fac
f0102feb:	c6 05 ad 1f 17 f0 8e 	movb   $0x8e,0xf0171fad
f0102ff2:	c1 e8 10             	shr    $0x10,%eax
f0102ff5:	66 a3 ae 1f 17 f0    	mov    %ax,0xf0171fae
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f0102ffb:	b8 84 36 10 f0       	mov    $0xf0103684,%eax
f0103000:	66 a3 b0 1f 17 f0    	mov    %ax,0xf0171fb0
f0103006:	66 c7 05 b2 1f 17 f0 	movw   $0x8,0xf0171fb2
f010300d:	08 00 
f010300f:	c6 05 b4 1f 17 f0 00 	movb   $0x0,0xf0171fb4
f0103016:	c6 05 b5 1f 17 f0 8e 	movb   $0x8e,0xf0171fb5
f010301d:	c1 e8 10             	shr    $0x10,%eax
f0103020:	66 a3 b6 1f 17 f0    	mov    %ax,0xf0171fb6
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f0103026:	b8 8a 36 10 f0       	mov    $0xf010368a,%eax
f010302b:	66 a3 b8 1f 17 f0    	mov    %ax,0xf0171fb8
f0103031:	66 c7 05 ba 1f 17 f0 	movw   $0x8,0xf0171fba
f0103038:	08 00 
f010303a:	c6 05 bc 1f 17 f0 00 	movb   $0x0,0xf0171fbc
f0103041:	c6 05 bd 1f 17 f0 ee 	movb   $0xee,0xf0171fbd
f0103048:	c1 e8 10             	shr    $0x10,%eax
f010304b:	66 a3 be 1f 17 f0    	mov    %ax,0xf0171fbe
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f0103051:	b8 90 36 10 f0       	mov    $0xf0103690,%eax
f0103056:	66 a3 c0 1f 17 f0    	mov    %ax,0xf0171fc0
f010305c:	66 c7 05 c2 1f 17 f0 	movw   $0x8,0xf0171fc2
f0103063:	08 00 
f0103065:	c6 05 c4 1f 17 f0 00 	movb   $0x0,0xf0171fc4
f010306c:	c6 05 c5 1f 17 f0 8e 	movb   $0x8e,0xf0171fc5
f0103073:	c1 e8 10             	shr    $0x10,%eax
f0103076:	66 a3 c6 1f 17 f0    	mov    %ax,0xf0171fc6
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f010307c:	b8 96 36 10 f0       	mov    $0xf0103696,%eax
f0103081:	66 a3 c8 1f 17 f0    	mov    %ax,0xf0171fc8
f0103087:	66 c7 05 ca 1f 17 f0 	movw   $0x8,0xf0171fca
f010308e:	08 00 
f0103090:	c6 05 cc 1f 17 f0 00 	movb   $0x0,0xf0171fcc
f0103097:	c6 05 cd 1f 17 f0 8e 	movb   $0x8e,0xf0171fcd
f010309e:	c1 e8 10             	shr    $0x10,%eax
f01030a1:	66 a3 ce 1f 17 f0    	mov    %ax,0xf0171fce
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f01030a7:	b8 9c 36 10 f0       	mov    $0xf010369c,%eax
f01030ac:	66 a3 d0 1f 17 f0    	mov    %ax,0xf0171fd0
f01030b2:	66 c7 05 d2 1f 17 f0 	movw   $0x8,0xf0171fd2
f01030b9:	08 00 
f01030bb:	c6 05 d4 1f 17 f0 00 	movb   $0x0,0xf0171fd4
f01030c2:	c6 05 d5 1f 17 f0 8e 	movb   $0x8e,0xf0171fd5
f01030c9:	c1 e8 10             	shr    $0x10,%eax
f01030cc:	66 a3 d6 1f 17 f0    	mov    %ax,0xf0171fd6
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f01030d2:	b8 a2 36 10 f0       	mov    $0xf01036a2,%eax
f01030d7:	66 a3 d8 1f 17 f0    	mov    %ax,0xf0171fd8
f01030dd:	66 c7 05 da 1f 17 f0 	movw   $0x8,0xf0171fda
f01030e4:	08 00 
f01030e6:	c6 05 dc 1f 17 f0 00 	movb   $0x0,0xf0171fdc
f01030ed:	c6 05 dd 1f 17 f0 8e 	movb   $0x8e,0xf0171fdd
f01030f4:	c1 e8 10             	shr    $0x10,%eax
f01030f7:	66 a3 de 1f 17 f0    	mov    %ax,0xf0171fde
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01030fd:	b8 a8 36 10 f0       	mov    $0xf01036a8,%eax
f0103102:	66 a3 e0 1f 17 f0    	mov    %ax,0xf0171fe0
f0103108:	66 c7 05 e2 1f 17 f0 	movw   $0x8,0xf0171fe2
f010310f:	08 00 
f0103111:	c6 05 e4 1f 17 f0 00 	movb   $0x0,0xf0171fe4
f0103118:	c6 05 e5 1f 17 f0 8e 	movb   $0x8e,0xf0171fe5
f010311f:	c1 e8 10             	shr    $0x10,%eax
f0103122:	66 a3 e6 1f 17 f0    	mov    %ax,0xf0171fe6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f0103128:	b8 ac 36 10 f0       	mov    $0xf01036ac,%eax
f010312d:	66 a3 f0 1f 17 f0    	mov    %ax,0xf0171ff0
f0103133:	66 c7 05 f2 1f 17 f0 	movw   $0x8,0xf0171ff2
f010313a:	08 00 
f010313c:	c6 05 f4 1f 17 f0 00 	movb   $0x0,0xf0171ff4
f0103143:	c6 05 f5 1f 17 f0 8e 	movb   $0x8e,0xf0171ff5
f010314a:	c1 e8 10             	shr    $0x10,%eax
f010314d:	66 a3 f6 1f 17 f0    	mov    %ax,0xf0171ff6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f0103153:	b8 b0 36 10 f0       	mov    $0xf01036b0,%eax
f0103158:	66 a3 f8 1f 17 f0    	mov    %ax,0xf0171ff8
f010315e:	66 c7 05 fa 1f 17 f0 	movw   $0x8,0xf0171ffa
f0103165:	08 00 
f0103167:	c6 05 fc 1f 17 f0 00 	movb   $0x0,0xf0171ffc
f010316e:	c6 05 fd 1f 17 f0 8e 	movb   $0x8e,0xf0171ffd
f0103175:	c1 e8 10             	shr    $0x10,%eax
f0103178:	66 a3 fe 1f 17 f0    	mov    %ax,0xf0171ffe
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f010317e:	b8 b4 36 10 f0       	mov    $0xf01036b4,%eax
f0103183:	66 a3 00 20 17 f0    	mov    %ax,0xf0172000
f0103189:	66 c7 05 02 20 17 f0 	movw   $0x8,0xf0172002
f0103190:	08 00 
f0103192:	c6 05 04 20 17 f0 00 	movb   $0x0,0xf0172004
f0103199:	c6 05 05 20 17 f0 8e 	movb   $0x8e,0xf0172005
f01031a0:	c1 e8 10             	shr    $0x10,%eax
f01031a3:	66 a3 06 20 17 f0    	mov    %ax,0xf0172006
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f01031a9:	b8 b8 36 10 f0       	mov    $0xf01036b8,%eax
f01031ae:	66 a3 08 20 17 f0    	mov    %ax,0xf0172008
f01031b4:	66 c7 05 0a 20 17 f0 	movw   $0x8,0xf017200a
f01031bb:	08 00 
f01031bd:	c6 05 0c 20 17 f0 00 	movb   $0x0,0xf017200c
f01031c4:	c6 05 0d 20 17 f0 8e 	movb   $0x8e,0xf017200d
f01031cb:	c1 e8 10             	shr    $0x10,%eax
f01031ce:	66 a3 0e 20 17 f0    	mov    %ax,0xf017200e
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f01031d4:	b8 bc 36 10 f0       	mov    $0xf01036bc,%eax
f01031d9:	66 a3 10 20 17 f0    	mov    %ax,0xf0172010
f01031df:	66 c7 05 12 20 17 f0 	movw   $0x8,0xf0172012
f01031e6:	08 00 
f01031e8:	c6 05 14 20 17 f0 00 	movb   $0x0,0xf0172014
f01031ef:	c6 05 15 20 17 f0 8e 	movb   $0x8e,0xf0172015
f01031f6:	c1 e8 10             	shr    $0x10,%eax
f01031f9:	66 a3 16 20 17 f0    	mov    %ax,0xf0172016
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01031ff:	b8 c0 36 10 f0       	mov    $0xf01036c0,%eax
f0103204:	66 a3 20 20 17 f0    	mov    %ax,0xf0172020
f010320a:	66 c7 05 22 20 17 f0 	movw   $0x8,0xf0172022
f0103211:	08 00 
f0103213:	c6 05 24 20 17 f0 00 	movb   $0x0,0xf0172024
f010321a:	c6 05 25 20 17 f0 8e 	movb   $0x8e,0xf0172025
f0103221:	c1 e8 10             	shr    $0x10,%eax
f0103224:	66 a3 26 20 17 f0    	mov    %ax,0xf0172026
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f010322a:	b8 c6 36 10 f0       	mov    $0xf01036c6,%eax
f010322f:	66 a3 28 20 17 f0    	mov    %ax,0xf0172028
f0103235:	66 c7 05 2a 20 17 f0 	movw   $0x8,0xf017202a
f010323c:	08 00 
f010323e:	c6 05 2c 20 17 f0 00 	movb   $0x0,0xf017202c
f0103245:	c6 05 2d 20 17 f0 8e 	movb   $0x8e,0xf017202d
f010324c:	c1 e8 10             	shr    $0x10,%eax
f010324f:	66 a3 2e 20 17 f0    	mov    %ax,0xf017202e
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103255:	b8 ca 36 10 f0       	mov    $0xf01036ca,%eax
f010325a:	66 a3 30 20 17 f0    	mov    %ax,0xf0172030
f0103260:	66 c7 05 32 20 17 f0 	movw   $0x8,0xf0172032
f0103267:	08 00 
f0103269:	c6 05 34 20 17 f0 00 	movb   $0x0,0xf0172034
f0103270:	c6 05 35 20 17 f0 8e 	movb   $0x8e,0xf0172035
f0103277:	c1 e8 10             	shr    $0x10,%eax
f010327a:	66 a3 36 20 17 f0    	mov    %ax,0xf0172036
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103280:	b8 d0 36 10 f0       	mov    $0xf01036d0,%eax
f0103285:	66 a3 38 20 17 f0    	mov    %ax,0xf0172038
f010328b:	66 c7 05 3a 20 17 f0 	movw   $0x8,0xf017203a
f0103292:	08 00 
f0103294:	c6 05 3c 20 17 f0 00 	movb   $0x0,0xf017203c
f010329b:	c6 05 3d 20 17 f0 8e 	movb   $0x8e,0xf017203d
f01032a2:	c1 e8 10             	shr    $0x10,%eax
f01032a5:	66 a3 3e 20 17 f0    	mov    %ax,0xf017203e
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f01032ab:	b8 d6 36 10 f0       	mov    $0xf01036d6,%eax
f01032b0:	66 a3 20 21 17 f0    	mov    %ax,0xf0172120
f01032b6:	66 c7 05 22 21 17 f0 	movw   $0x8,0xf0172122
f01032bd:	08 00 
f01032bf:	c6 05 24 21 17 f0 00 	movb   $0x0,0xf0172124
f01032c6:	c6 05 25 21 17 f0 ef 	movb   $0xef,0xf0172125
f01032cd:	c1 e8 10             	shr    $0x10,%eax
f01032d0:	66 a3 26 21 17 f0    	mov    %ax,0xf0172126

	// Per-CPU setup 
	trap_init_percpu();
f01032d6:	e8 6a fc ff ff       	call   f0102f45 <trap_init_percpu>
}
f01032db:	5d                   	pop    %ebp
f01032dc:	c3                   	ret    

f01032dd <print_regs>:
	}
}

void	
print_regs(struct PushRegs *regs)
{
f01032dd:	55                   	push   %ebp
f01032de:	89 e5                	mov    %esp,%ebp
f01032e0:	53                   	push   %ebx
f01032e1:	83 ec 0c             	sub    $0xc,%esp
f01032e4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01032e7:	ff 33                	pushl  (%ebx)
f01032e9:	68 b7 58 10 f0       	push   $0xf01058b7
f01032ee:	e8 3e fc ff ff       	call   f0102f31 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01032f3:	83 c4 08             	add    $0x8,%esp
f01032f6:	ff 73 04             	pushl  0x4(%ebx)
f01032f9:	68 c6 58 10 f0       	push   $0xf01058c6
f01032fe:	e8 2e fc ff ff       	call   f0102f31 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103303:	83 c4 08             	add    $0x8,%esp
f0103306:	ff 73 08             	pushl  0x8(%ebx)
f0103309:	68 d5 58 10 f0       	push   $0xf01058d5
f010330e:	e8 1e fc ff ff       	call   f0102f31 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103313:	83 c4 08             	add    $0x8,%esp
f0103316:	ff 73 0c             	pushl  0xc(%ebx)
f0103319:	68 e4 58 10 f0       	push   $0xf01058e4
f010331e:	e8 0e fc ff ff       	call   f0102f31 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103323:	83 c4 08             	add    $0x8,%esp
f0103326:	ff 73 10             	pushl  0x10(%ebx)
f0103329:	68 f3 58 10 f0       	push   $0xf01058f3
f010332e:	e8 fe fb ff ff       	call   f0102f31 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103333:	83 c4 08             	add    $0x8,%esp
f0103336:	ff 73 14             	pushl  0x14(%ebx)
f0103339:	68 02 59 10 f0       	push   $0xf0105902
f010333e:	e8 ee fb ff ff       	call   f0102f31 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103343:	83 c4 08             	add    $0x8,%esp
f0103346:	ff 73 18             	pushl  0x18(%ebx)
f0103349:	68 11 59 10 f0       	push   $0xf0105911
f010334e:	e8 de fb ff ff       	call   f0102f31 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103353:	83 c4 08             	add    $0x8,%esp
f0103356:	ff 73 1c             	pushl  0x1c(%ebx)
f0103359:	68 20 59 10 f0       	push   $0xf0105920
f010335e:	e8 ce fb ff ff       	call   f0102f31 <cprintf>
}
f0103363:	83 c4 10             	add    $0x10,%esp
f0103366:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103369:	c9                   	leave  
f010336a:	c3                   	ret    

f010336b <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010336b:	55                   	push   %ebp
f010336c:	89 e5                	mov    %esp,%ebp
f010336e:	56                   	push   %esi
f010336f:	53                   	push   %ebx
f0103370:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103373:	83 ec 08             	sub    $0x8,%esp
f0103376:	53                   	push   %ebx
f0103377:	68 69 5a 10 f0       	push   $0xf0105a69
f010337c:	e8 b0 fb ff ff       	call   f0102f31 <cprintf>
	print_regs(&tf->tf_regs);
f0103381:	89 1c 24             	mov    %ebx,(%esp)
f0103384:	e8 54 ff ff ff       	call   f01032dd <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103389:	83 c4 08             	add    $0x8,%esp
f010338c:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103390:	50                   	push   %eax
f0103391:	68 71 59 10 f0       	push   $0xf0105971
f0103396:	e8 96 fb ff ff       	call   f0102f31 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010339b:	83 c4 08             	add    $0x8,%esp
f010339e:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01033a2:	50                   	push   %eax
f01033a3:	68 84 59 10 f0       	push   $0xf0105984
f01033a8:	e8 84 fb ff ff       	call   f0102f31 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033ad:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01033b0:	83 c4 10             	add    $0x10,%esp
f01033b3:	83 f8 13             	cmp    $0x13,%eax
f01033b6:	77 09                	ja     f01033c1 <print_trapframe+0x56>
		return excnames[trapno];
f01033b8:	8b 14 85 40 5c 10 f0 	mov    -0xfefa3c0(,%eax,4),%edx
f01033bf:	eb 10                	jmp    f01033d1 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01033c1:	83 f8 30             	cmp    $0x30,%eax
f01033c4:	b9 3b 59 10 f0       	mov    $0xf010593b,%ecx
f01033c9:	ba 2f 59 10 f0       	mov    $0xf010592f,%edx
f01033ce:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033d1:	83 ec 04             	sub    $0x4,%esp
f01033d4:	52                   	push   %edx
f01033d5:	50                   	push   %eax
f01033d6:	68 97 59 10 f0       	push   $0xf0105997
f01033db:	e8 51 fb ff ff       	call   f0102f31 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01033e0:	83 c4 10             	add    $0x10,%esp
f01033e3:	3b 1d a0 27 17 f0    	cmp    0xf01727a0,%ebx
f01033e9:	75 1a                	jne    f0103405 <print_trapframe+0x9a>
f01033eb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033ef:	75 14                	jne    f0103405 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01033f1:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01033f4:	83 ec 08             	sub    $0x8,%esp
f01033f7:	50                   	push   %eax
f01033f8:	68 a9 59 10 f0       	push   $0xf01059a9
f01033fd:	e8 2f fb ff ff       	call   f0102f31 <cprintf>
f0103402:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103405:	83 ec 08             	sub    $0x8,%esp
f0103408:	ff 73 2c             	pushl  0x2c(%ebx)
f010340b:	68 b8 59 10 f0       	push   $0xf01059b8
f0103410:	e8 1c fb ff ff       	call   f0102f31 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103415:	83 c4 10             	add    $0x10,%esp
f0103418:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010341c:	75 49                	jne    f0103467 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010341e:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103421:	89 c2                	mov    %eax,%edx
f0103423:	83 e2 01             	and    $0x1,%edx
f0103426:	ba 55 59 10 f0       	mov    $0xf0105955,%edx
f010342b:	b9 4a 59 10 f0       	mov    $0xf010594a,%ecx
f0103430:	0f 44 ca             	cmove  %edx,%ecx
f0103433:	89 c2                	mov    %eax,%edx
f0103435:	83 e2 02             	and    $0x2,%edx
f0103438:	ba 67 59 10 f0       	mov    $0xf0105967,%edx
f010343d:	be 61 59 10 f0       	mov    $0xf0105961,%esi
f0103442:	0f 45 d6             	cmovne %esi,%edx
f0103445:	83 e0 04             	and    $0x4,%eax
f0103448:	be 94 5a 10 f0       	mov    $0xf0105a94,%esi
f010344d:	b8 6c 59 10 f0       	mov    $0xf010596c,%eax
f0103452:	0f 44 c6             	cmove  %esi,%eax
f0103455:	51                   	push   %ecx
f0103456:	52                   	push   %edx
f0103457:	50                   	push   %eax
f0103458:	68 c6 59 10 f0       	push   $0xf01059c6
f010345d:	e8 cf fa ff ff       	call   f0102f31 <cprintf>
f0103462:	83 c4 10             	add    $0x10,%esp
f0103465:	eb 10                	jmp    f0103477 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103467:	83 ec 0c             	sub    $0xc,%esp
f010346a:	68 dc 4a 10 f0       	push   $0xf0104adc
f010346f:	e8 bd fa ff ff       	call   f0102f31 <cprintf>
f0103474:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103477:	83 ec 08             	sub    $0x8,%esp
f010347a:	ff 73 30             	pushl  0x30(%ebx)
f010347d:	68 d5 59 10 f0       	push   $0xf01059d5
f0103482:	e8 aa fa ff ff       	call   f0102f31 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103487:	83 c4 08             	add    $0x8,%esp
f010348a:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010348e:	50                   	push   %eax
f010348f:	68 e4 59 10 f0       	push   $0xf01059e4
f0103494:	e8 98 fa ff ff       	call   f0102f31 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103499:	83 c4 08             	add    $0x8,%esp
f010349c:	ff 73 38             	pushl  0x38(%ebx)
f010349f:	68 f7 59 10 f0       	push   $0xf01059f7
f01034a4:	e8 88 fa ff ff       	call   f0102f31 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01034a9:	83 c4 10             	add    $0x10,%esp
f01034ac:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034b0:	74 25                	je     f01034d7 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01034b2:	83 ec 08             	sub    $0x8,%esp
f01034b5:	ff 73 3c             	pushl  0x3c(%ebx)
f01034b8:	68 06 5a 10 f0       	push   $0xf0105a06
f01034bd:	e8 6f fa ff ff       	call   f0102f31 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01034c2:	83 c4 08             	add    $0x8,%esp
f01034c5:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01034c9:	50                   	push   %eax
f01034ca:	68 15 5a 10 f0       	push   $0xf0105a15
f01034cf:	e8 5d fa ff ff       	call   f0102f31 <cprintf>
f01034d4:	83 c4 10             	add    $0x10,%esp
	}
}
f01034d7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034da:	5b                   	pop    %ebx
f01034db:	5e                   	pop    %esi
f01034dc:	5d                   	pop    %ebp
f01034dd:	c3                   	ret    

f01034de <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034de:	55                   	push   %ebp
f01034df:	89 e5                	mov    %esp,%ebp
f01034e1:	53                   	push   %ebx
f01034e2:	83 ec 04             	sub    $0x4,%esp
f01034e5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01034e8:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs&3) == 0)
f01034eb:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034ef:	75 17                	jne    f0103508 <page_fault_handler+0x2a>
		panic("Kernel page fault!");	
f01034f1:	83 ec 04             	sub    $0x4,%esp
f01034f4:	68 28 5a 10 f0       	push   $0xf0105a28
f01034f9:	68 f1 00 00 00       	push   $0xf1
f01034fe:	68 3b 5a 10 f0       	push   $0xf0105a3b
f0103503:	e8 98 cb ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103508:	ff 73 30             	pushl  0x30(%ebx)
f010350b:	50                   	push   %eax
f010350c:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103511:	ff 70 48             	pushl  0x48(%eax)
f0103514:	68 e0 5b 10 f0       	push   $0xf0105be0
f0103519:	e8 13 fa ff ff       	call   f0102f31 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010351e:	89 1c 24             	mov    %ebx,(%esp)
f0103521:	e8 45 fe ff ff       	call   f010336b <print_trapframe>
	env_destroy(curenv);
f0103526:	83 c4 04             	add    $0x4,%esp
f0103529:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010352f:	e8 e4 f8 ff ff       	call   f0102e18 <env_destroy>
}
f0103534:	83 c4 10             	add    $0x10,%esp
f0103537:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010353a:	c9                   	leave  
f010353b:	c3                   	ret    

f010353c <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010353c:	55                   	push   %ebp
f010353d:	89 e5                	mov    %esp,%ebp
f010353f:	57                   	push   %edi
f0103540:	56                   	push   %esi
f0103541:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103544:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103545:	9c                   	pushf  
f0103546:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103547:	f6 c4 02             	test   $0x2,%ah
f010354a:	74 19                	je     f0103565 <trap+0x29>
f010354c:	68 47 5a 10 f0       	push   $0xf0105a47
f0103551:	68 27 55 10 f0       	push   $0xf0105527
f0103556:	68 c8 00 00 00       	push   $0xc8
f010355b:	68 3b 5a 10 f0       	push   $0xf0105a3b
f0103560:	e8 3b cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103565:	83 ec 08             	sub    $0x8,%esp
f0103568:	56                   	push   %esi
f0103569:	68 60 5a 10 f0       	push   $0xf0105a60
f010356e:	e8 be f9 ff ff       	call   f0102f31 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103573:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103577:	83 e0 03             	and    $0x3,%eax
f010357a:	83 c4 10             	add    $0x10,%esp
f010357d:	66 83 f8 03          	cmp    $0x3,%ax
f0103581:	75 31                	jne    f01035b4 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103583:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103588:	85 c0                	test   %eax,%eax
f010358a:	75 19                	jne    f01035a5 <trap+0x69>
f010358c:	68 7b 5a 10 f0       	push   $0xf0105a7b
f0103591:	68 27 55 10 f0       	push   $0xf0105527
f0103596:	68 ce 00 00 00       	push   $0xce
f010359b:	68 3b 5a 10 f0       	push   $0xf0105a3b
f01035a0:	e8 fb ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01035a5:	b9 11 00 00 00       	mov    $0x11,%ecx
f01035aa:	89 c7                	mov    %eax,%edi
f01035ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01035ae:	8b 35 84 1f 17 f0    	mov    0xf0171f84,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01035b4:	89 35 a0 27 17 f0    	mov    %esi,0xf01727a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f01035ba:	8b 46 28             	mov    0x28(%esi),%eax
f01035bd:	83 f8 0e             	cmp    $0xe,%eax
f01035c0:	74 0c                	je     f01035ce <trap+0x92>
f01035c2:	83 f8 30             	cmp    $0x30,%eax
f01035c5:	74 23                	je     f01035ea <trap+0xae>
f01035c7:	83 f8 03             	cmp    $0x3,%eax
f01035ca:	75 3f                	jne    f010360b <trap+0xcf>
f01035cc:	eb 0e                	jmp    f01035dc <trap+0xa0>
	{
		case T_PGFLT: 	  page_fault_handler(tf); 	return;
f01035ce:	83 ec 0c             	sub    $0xc,%esp
f01035d1:	56                   	push   %esi
f01035d2:	e8 07 ff ff ff       	call   f01034de <page_fault_handler>
f01035d7:	83 c4 10             	add    $0x10,%esp
f01035da:	eb 6a                	jmp    f0103646 <trap+0x10a>

		case T_BRKPT:     monitor(tf);			return;
f01035dc:	83 ec 0c             	sub    $0xc,%esp
f01035df:	56                   	push   %esi
f01035e0:	e8 24 d2 ff ff       	call   f0100809 <monitor>
f01035e5:	83 c4 10             	add    $0x10,%esp
f01035e8:	eb 5c                	jmp    f0103646 <trap+0x10a>

		case T_SYSCALL:	  
				tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx,
f01035ea:	83 ec 08             	sub    $0x8,%esp
f01035ed:	ff 76 04             	pushl  0x4(%esi)
f01035f0:	ff 36                	pushl  (%esi)
f01035f2:	ff 76 10             	pushl  0x10(%esi)
f01035f5:	ff 76 18             	pushl  0x18(%esi)
f01035f8:	ff 76 14             	pushl  0x14(%esi)
f01035fb:	ff 76 1c             	pushl  0x1c(%esi)
f01035fe:	e8 eb 00 00 00       	call   f01036ee <syscall>
f0103603:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103606:	83 c4 20             	add    $0x20,%esp
f0103609:	eb 3b                	jmp    f0103646 <trap+0x10a>
	}



	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010360b:	83 ec 0c             	sub    $0xc,%esp
f010360e:	56                   	push   %esi
f010360f:	e8 57 fd ff ff       	call   f010336b <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103614:	83 c4 10             	add    $0x10,%esp
f0103617:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010361c:	75 17                	jne    f0103635 <trap+0xf9>
		panic("unhandled trap in kernel");
f010361e:	83 ec 04             	sub    $0x4,%esp
f0103621:	68 82 5a 10 f0       	push   $0xf0105a82
f0103626:	68 b7 00 00 00       	push   $0xb7
f010362b:	68 3b 5a 10 f0       	push   $0xf0105a3b
f0103630:	e8 6b ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103635:	83 ec 0c             	sub    $0xc,%esp
f0103638:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010363e:	e8 d5 f7 ff ff       	call   f0102e18 <env_destroy>
f0103643:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103646:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f010364b:	85 c0                	test   %eax,%eax
f010364d:	74 06                	je     f0103655 <trap+0x119>
f010364f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103653:	74 19                	je     f010366e <trap+0x132>
f0103655:	68 04 5c 10 f0       	push   $0xf0105c04
f010365a:	68 27 55 10 f0       	push   $0xf0105527
f010365f:	68 e0 00 00 00       	push   $0xe0
f0103664:	68 3b 5a 10 f0       	push   $0xf0105a3b
f0103669:	e8 32 ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f010366e:	83 ec 0c             	sub    $0xc,%esp
f0103671:	50                   	push   %eax
f0103672:	e8 f1 f7 ff ff       	call   f0102e68 <env_run>
f0103677:	90                   	nop

f0103678 <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f0103678:	6a 00                	push   $0x0
f010367a:	6a 00                	push   $0x0
f010367c:	eb 5e                	jmp    f01036dc <_alltraps>

f010367e <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f010367e:	6a 00                	push   $0x0
f0103680:	6a 01                	push   $0x1
f0103682:	eb 58                	jmp    f01036dc <_alltraps>

f0103684 <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f0103684:	6a 00                	push   $0x0
f0103686:	6a 02                	push   $0x2
f0103688:	eb 52                	jmp    f01036dc <_alltraps>

f010368a <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f010368a:	6a 00                	push   $0x0
f010368c:	6a 03                	push   $0x3
f010368e:	eb 4c                	jmp    f01036dc <_alltraps>

f0103690 <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f0103690:	6a 00                	push   $0x0
f0103692:	6a 04                	push   $0x4
f0103694:	eb 46                	jmp    f01036dc <_alltraps>

f0103696 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f0103696:	6a 00                	push   $0x0
f0103698:	6a 05                	push   $0x5
f010369a:	eb 40                	jmp    f01036dc <_alltraps>

f010369c <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f010369c:	6a 00                	push   $0x0
f010369e:	6a 06                	push   $0x6
f01036a0:	eb 3a                	jmp    f01036dc <_alltraps>

f01036a2 <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f01036a2:	6a 00                	push   $0x0
f01036a4:	6a 07                	push   $0x7
f01036a6:	eb 34                	jmp    f01036dc <_alltraps>

f01036a8 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f01036a8:	6a 08                	push   $0x8
f01036aa:	eb 30                	jmp    f01036dc <_alltraps>

f01036ac <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f01036ac:	6a 0a                	push   $0xa
f01036ae:	eb 2c                	jmp    f01036dc <_alltraps>

f01036b0 <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f01036b0:	6a 0b                	push   $0xb
f01036b2:	eb 28                	jmp    f01036dc <_alltraps>

f01036b4 <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f01036b4:	6a 0c                	push   $0xc
f01036b6:	eb 24                	jmp    f01036dc <_alltraps>

f01036b8 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f01036b8:	6a 0d                	push   $0xd
f01036ba:	eb 20                	jmp    f01036dc <_alltraps>

f01036bc <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f01036bc:	6a 0e                	push   $0xe
f01036be:	eb 1c                	jmp    f01036dc <_alltraps>

f01036c0 <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f01036c0:	6a 00                	push   $0x0
f01036c2:	6a 10                	push   $0x10
f01036c4:	eb 16                	jmp    f01036dc <_alltraps>

f01036c6 <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f01036c6:	6a 11                	push   $0x11
f01036c8:	eb 12                	jmp    f01036dc <_alltraps>

f01036ca <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f01036ca:	6a 00                	push   $0x0
f01036cc:	6a 12                	push   $0x12
f01036ce:	eb 0c                	jmp    f01036dc <_alltraps>

f01036d0 <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f01036d0:	6a 00                	push   $0x0
f01036d2:	6a 13                	push   $0x13
f01036d4:	eb 06                	jmp    f01036dc <_alltraps>

f01036d6 <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f01036d6:	6a 00                	push   $0x0
f01036d8:	6a 30                	push   $0x30
f01036da:	eb 00                	jmp    f01036dc <_alltraps>

f01036dc <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f01036dc:	1e                   	push   %ds
	pushl	%es
f01036dd:	06                   	push   %es
	pushal
f01036de:	60                   	pusha  
	mov	$GD_KD, %eax
f01036df:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f01036e4:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f01036e6:	8e d8                	mov    %eax,%ds
	pushl	%esp
f01036e8:	54                   	push   %esp
	call	trap
f01036e9:	e8 4e fe ff ff       	call   f010353c <trap>

f01036ee <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01036ee:	55                   	push   %ebp
f01036ef:	89 e5                	mov    %esp,%ebp
f01036f1:	83 ec 18             	sub    $0x18,%esp
f01036f4:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
f01036f7:	83 f8 01             	cmp    $0x1,%eax
f01036fa:	74 44                	je     f0103740 <syscall+0x52>
f01036fc:	83 f8 01             	cmp    $0x1,%eax
f01036ff:	72 0f                	jb     f0103710 <syscall+0x22>
f0103701:	83 f8 02             	cmp    $0x2,%eax
f0103704:	74 41                	je     f0103747 <syscall+0x59>
f0103706:	83 f8 03             	cmp    $0x3,%eax
f0103709:	74 46                	je     f0103751 <syscall+0x63>
f010370b:	e9 a6 00 00 00       	jmp    f01037b6 <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f0103710:	6a 04                	push   $0x4
f0103712:	ff 75 10             	pushl  0x10(%ebp)
f0103715:	ff 75 0c             	pushl  0xc(%ebp)
f0103718:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010371e:	e8 f3 f0 ff ff       	call   f0102816 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103723:	83 c4 0c             	add    $0xc,%esp
f0103726:	ff 75 0c             	pushl  0xc(%ebp)
f0103729:	ff 75 10             	pushl  0x10(%ebp)
f010372c:	68 90 5c 10 f0       	push   $0xf0105c90
f0103731:	e8 fb f7 ff ff       	call   f0102f31 <cprintf>
f0103736:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) 
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
f0103739:	b8 00 00 00 00       	mov    $0x0,%eax
f010373e:	eb 7b                	jmp    f01037bb <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103740:	e8 7e cd ff ff       	call   f01004c3 <cons_getc>

	switch (syscallno) 
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			return sys_cgetc();		
f0103745:	eb 74                	jmp    f01037bb <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103747:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f010374c:	8b 40 48             	mov    0x48(%eax),%eax
	{
		case SYS_cputs:			sys_cputs((char*) a1, a2);	return 0;
		
		case SYS_cgetc:			return sys_cgetc();		

		case SYS_getenvid:		return sys_getenvid();
f010374f:	eb 6a                	jmp    f01037bb <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103751:	83 ec 04             	sub    $0x4,%esp
f0103754:	6a 01                	push   $0x1
f0103756:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103759:	50                   	push   %eax
f010375a:	ff 75 0c             	pushl  0xc(%ebp)
f010375d:	e8 69 f1 ff ff       	call   f01028cb <envid2env>
f0103762:	83 c4 10             	add    $0x10,%esp
f0103765:	85 c0                	test   %eax,%eax
f0103767:	78 46                	js     f01037af <syscall+0xc1>
		return r;
	if (e == curenv)
f0103769:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010376c:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0103772:	39 d0                	cmp    %edx,%eax
f0103774:	75 15                	jne    f010378b <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103776:	83 ec 08             	sub    $0x8,%esp
f0103779:	ff 70 48             	pushl  0x48(%eax)
f010377c:	68 95 5c 10 f0       	push   $0xf0105c95
f0103781:	e8 ab f7 ff ff       	call   f0102f31 <cprintf>
f0103786:	83 c4 10             	add    $0x10,%esp
f0103789:	eb 16                	jmp    f01037a1 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010378b:	83 ec 04             	sub    $0x4,%esp
f010378e:	ff 70 48             	pushl  0x48(%eax)
f0103791:	ff 72 48             	pushl  0x48(%edx)
f0103794:	68 b0 5c 10 f0       	push   $0xf0105cb0
f0103799:	e8 93 f7 ff ff       	call   f0102f31 <cprintf>
f010379e:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01037a1:	83 ec 0c             	sub    $0xc,%esp
f01037a4:	ff 75 f4             	pushl  -0xc(%ebp)
f01037a7:	e8 6c f6 ff ff       	call   f0102e18 <env_destroy>
f01037ac:	83 c4 10             	add    $0x10,%esp

		case SYS_getenvid:		return sys_getenvid();

		case SYS_env_destroy:		sys_env_destroy((envid_t) a1);

		default:			return -E_INVAL;
f01037af:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01037b4:	eb 05                	jmp    f01037bb <syscall+0xcd>
f01037b6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f01037bb:	c9                   	leave  
f01037bc:	c3                   	ret    

f01037bd <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01037bd:	55                   	push   %ebp
f01037be:	89 e5                	mov    %esp,%ebp
f01037c0:	57                   	push   %edi
f01037c1:	56                   	push   %esi
f01037c2:	53                   	push   %ebx
f01037c3:	83 ec 14             	sub    $0x14,%esp
f01037c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01037c9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01037cc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01037cf:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01037d2:	8b 1a                	mov    (%edx),%ebx
f01037d4:	8b 01                	mov    (%ecx),%eax
f01037d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037d9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01037e0:	eb 7f                	jmp    f0103861 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01037e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01037e5:	01 d8                	add    %ebx,%eax
f01037e7:	89 c6                	mov    %eax,%esi
f01037e9:	c1 ee 1f             	shr    $0x1f,%esi
f01037ec:	01 c6                	add    %eax,%esi
f01037ee:	d1 fe                	sar    %esi
f01037f0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01037f3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037f6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01037f9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037fb:	eb 03                	jmp    f0103800 <stab_binsearch+0x43>
			m--;
f01037fd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103800:	39 c3                	cmp    %eax,%ebx
f0103802:	7f 0d                	jg     f0103811 <stab_binsearch+0x54>
f0103804:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103808:	83 ea 0c             	sub    $0xc,%edx
f010380b:	39 f9                	cmp    %edi,%ecx
f010380d:	75 ee                	jne    f01037fd <stab_binsearch+0x40>
f010380f:	eb 05                	jmp    f0103816 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103811:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103814:	eb 4b                	jmp    f0103861 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103816:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103819:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010381c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103820:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103823:	76 11                	jbe    f0103836 <stab_binsearch+0x79>
			*region_left = m;
f0103825:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103828:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010382a:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010382d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103834:	eb 2b                	jmp    f0103861 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103836:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103839:	73 14                	jae    f010384f <stab_binsearch+0x92>
			*region_right = m - 1;
f010383b:	83 e8 01             	sub    $0x1,%eax
f010383e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103841:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103844:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103846:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010384d:	eb 12                	jmp    f0103861 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010384f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103852:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103854:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103858:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010385a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103861:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103864:	0f 8e 78 ff ff ff    	jle    f01037e2 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010386a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010386e:	75 0f                	jne    f010387f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103870:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103873:	8b 00                	mov    (%eax),%eax
f0103875:	83 e8 01             	sub    $0x1,%eax
f0103878:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010387b:	89 06                	mov    %eax,(%esi)
f010387d:	eb 2c                	jmp    f01038ab <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010387f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103882:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103884:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103887:	8b 0e                	mov    (%esi),%ecx
f0103889:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010388c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010388f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103892:	eb 03                	jmp    f0103897 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103894:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103897:	39 c8                	cmp    %ecx,%eax
f0103899:	7e 0b                	jle    f01038a6 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010389b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010389f:	83 ea 0c             	sub    $0xc,%edx
f01038a2:	39 df                	cmp    %ebx,%edi
f01038a4:	75 ee                	jne    f0103894 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01038a6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038a9:	89 06                	mov    %eax,(%esi)
	}
}
f01038ab:	83 c4 14             	add    $0x14,%esp
f01038ae:	5b                   	pop    %ebx
f01038af:	5e                   	pop    %esi
f01038b0:	5f                   	pop    %edi
f01038b1:	5d                   	pop    %ebp
f01038b2:	c3                   	ret    

f01038b3 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01038b3:	55                   	push   %ebp
f01038b4:	89 e5                	mov    %esp,%ebp
f01038b6:	57                   	push   %edi
f01038b7:	56                   	push   %esi
f01038b8:	53                   	push   %ebx
f01038b9:	83 ec 3c             	sub    $0x3c,%esp
f01038bc:	8b 75 08             	mov    0x8(%ebp),%esi
f01038bf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01038c2:	c7 03 c8 5c 10 f0    	movl   $0xf0105cc8,(%ebx)
	info->eip_line = 0;
f01038c8:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01038cf:	c7 43 08 c8 5c 10 f0 	movl   $0xf0105cc8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01038d6:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01038dd:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01038e0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01038e7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01038ed:	0f 87 8a 00 00 00    	ja     f010397d <debuginfo_eip+0xca>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f01038f3:	6a 04                	push   $0x4
f01038f5:	6a 10                	push   $0x10
f01038f7:	68 00 00 20 00       	push   $0x200000
f01038fc:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103902:	e8 99 ee ff ff       	call   f01027a0 <user_mem_check>
f0103907:	83 c4 10             	add    $0x10,%esp
f010390a:	85 c0                	test   %eax,%eax
f010390c:	0f 84 2d 02 00 00    	je     f0103b3f <debuginfo_eip+0x28c>
                        return -1;

		stabs = usd->stabs;
f0103912:	a1 00 00 20 00       	mov    0x200000,%eax
f0103917:	89 c1                	mov    %eax,%ecx
f0103919:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f010391c:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0103922:	a1 08 00 20 00       	mov    0x200008,%eax
f0103927:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010392a:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0103930:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
f0103933:	6a 04                	push   $0x4
f0103935:	89 f8                	mov    %edi,%eax
f0103937:	29 c8                	sub    %ecx,%eax
f0103939:	c1 f8 02             	sar    $0x2,%eax
f010393c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103942:	50                   	push   %eax
f0103943:	51                   	push   %ecx
f0103944:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010394a:	e8 51 ee ff ff       	call   f01027a0 <user_mem_check>
f010394f:	83 c4 10             	add    $0x10,%esp
f0103952:	85 c0                	test   %eax,%eax
f0103954:	0f 84 ec 01 00 00    	je     f0103b46 <debuginfo_eip+0x293>
			return -1;

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
f010395a:	6a 04                	push   $0x4
f010395c:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010395f:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0103962:	29 ca                	sub    %ecx,%edx
f0103964:	52                   	push   %edx
f0103965:	51                   	push   %ecx
f0103966:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010396c:	e8 2f ee ff ff       	call   f01027a0 <user_mem_check>
f0103971:	83 c4 10             	add    $0x10,%esp
f0103974:	85 c0                	test   %eax,%eax
f0103976:	75 1f                	jne    f0103997 <debuginfo_eip+0xe4>
f0103978:	e9 d0 01 00 00       	jmp    f0103b4d <debuginfo_eip+0x29a>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010397d:	c7 45 bc 92 02 11 f0 	movl   $0xf0110292,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103984:	c7 45 b8 e9 d7 10 f0 	movl   $0xf010d7e9,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010398b:	bf e8 d7 10 f0       	mov    $0xf010d7e8,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103990:	c7 45 c0 e0 5e 10 f0 	movl   $0xf0105ee0,-0x40(%ebp)
		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103997:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010399a:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f010399d:	0f 83 b1 01 00 00    	jae    f0103b54 <debuginfo_eip+0x2a1>
f01039a3:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01039a7:	0f 85 ae 01 00 00    	jne    f0103b5b <debuginfo_eip+0x2a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01039ad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01039b4:	2b 7d c0             	sub    -0x40(%ebp),%edi
f01039b7:	c1 ff 02             	sar    $0x2,%edi
f01039ba:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f01039c0:	83 e8 01             	sub    $0x1,%eax
f01039c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01039c6:	83 ec 08             	sub    $0x8,%esp
f01039c9:	56                   	push   %esi
f01039ca:	6a 64                	push   $0x64
f01039cc:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01039cf:	89 d1                	mov    %edx,%ecx
f01039d1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039d4:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01039d7:	89 f8                	mov    %edi,%eax
f01039d9:	e8 df fd ff ff       	call   f01037bd <stab_binsearch>
	if (lfile == 0)
f01039de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039e1:	83 c4 10             	add    $0x10,%esp
f01039e4:	85 c0                	test   %eax,%eax
f01039e6:	0f 84 76 01 00 00    	je     f0103b62 <debuginfo_eip+0x2af>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01039ec:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01039ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01039f5:	83 ec 08             	sub    $0x8,%esp
f01039f8:	56                   	push   %esi
f01039f9:	6a 24                	push   $0x24
f01039fb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01039fe:	89 d1                	mov    %edx,%ecx
f0103a00:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103a03:	89 f8                	mov    %edi,%eax
f0103a05:	e8 b3 fd ff ff       	call   f01037bd <stab_binsearch>

	if (lfun <= rfun) {
f0103a0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103a0d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a10:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103a13:	83 c4 10             	add    $0x10,%esp
f0103a16:	39 d0                	cmp    %edx,%eax
f0103a18:	7f 2b                	jg     f0103a45 <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103a1a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a1d:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103a20:	8b 11                	mov    (%ecx),%edx
f0103a22:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103a25:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103a28:	39 fa                	cmp    %edi,%edx
f0103a2a:	73 06                	jae    f0103a32 <debuginfo_eip+0x17f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103a2c:	03 55 b8             	add    -0x48(%ebp),%edx
f0103a2f:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a32:	8b 51 08             	mov    0x8(%ecx),%edx
f0103a35:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103a38:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103a3a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103a3d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103a40:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103a43:	eb 0f                	jmp    f0103a54 <debuginfo_eip+0x1a1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a45:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103a48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a4b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103a4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a51:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a54:	83 ec 08             	sub    $0x8,%esp
f0103a57:	6a 3a                	push   $0x3a
f0103a59:	ff 73 08             	pushl  0x8(%ebx)
f0103a5c:	e8 8f 08 00 00       	call   f01042f0 <strfind>
f0103a61:	2b 43 08             	sub    0x8(%ebx),%eax
f0103a64:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103a67:	83 c4 08             	add    $0x8,%esp
f0103a6a:	56                   	push   %esi
f0103a6b:	6a 44                	push   $0x44
f0103a6d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103a70:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103a73:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103a76:	89 f8                	mov    %edi,%eax
f0103a78:	e8 40 fd ff ff       	call   f01037bd <stab_binsearch>
	
	if(lline > rline)
f0103a7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a80:	83 c4 10             	add    $0x10,%esp
f0103a83:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103a86:	0f 8f dd 00 00 00    	jg     f0103b69 <debuginfo_eip+0x2b6>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f0103a8c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a8f:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103a92:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103a96:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a9c:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103aa0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103aa3:	eb 0a                	jmp    f0103aaf <debuginfo_eip+0x1fc>
f0103aa5:	83 e8 01             	sub    $0x1,%eax
f0103aa8:	83 ea 0c             	sub    $0xc,%edx
f0103aab:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103aaf:	39 c7                	cmp    %eax,%edi
f0103ab1:	7e 05                	jle    f0103ab8 <debuginfo_eip+0x205>
f0103ab3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ab6:	eb 47                	jmp    f0103aff <debuginfo_eip+0x24c>
	       && stabs[lline].n_type != N_SOL
f0103ab8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103abc:	80 f9 84             	cmp    $0x84,%cl
f0103abf:	75 0e                	jne    f0103acf <debuginfo_eip+0x21c>
f0103ac1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ac4:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103ac8:	74 1c                	je     f0103ae6 <debuginfo_eip+0x233>
f0103aca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103acd:	eb 17                	jmp    f0103ae6 <debuginfo_eip+0x233>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103acf:	80 f9 64             	cmp    $0x64,%cl
f0103ad2:	75 d1                	jne    f0103aa5 <debuginfo_eip+0x1f2>
f0103ad4:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103ad8:	74 cb                	je     f0103aa5 <debuginfo_eip+0x1f2>
f0103ada:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103add:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103ae1:	74 03                	je     f0103ae6 <debuginfo_eip+0x233>
f0103ae3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103ae6:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103ae9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103aec:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103aef:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103af2:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103af5:	29 f0                	sub    %esi,%eax
f0103af7:	39 c2                	cmp    %eax,%edx
f0103af9:	73 04                	jae    f0103aff <debuginfo_eip+0x24c>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103afb:	01 f2                	add    %esi,%edx
f0103afd:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103aff:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103b02:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b05:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103b0a:	39 f2                	cmp    %esi,%edx
f0103b0c:	7d 67                	jge    f0103b75 <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
f0103b0e:	83 c2 01             	add    $0x1,%edx
f0103b11:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103b14:	89 d0                	mov    %edx,%eax
f0103b16:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103b19:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b1c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103b1f:	eb 04                	jmp    f0103b25 <debuginfo_eip+0x272>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103b21:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103b25:	39 c6                	cmp    %eax,%esi
f0103b27:	7e 47                	jle    f0103b70 <debuginfo_eip+0x2bd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103b29:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103b2d:	83 c0 01             	add    $0x1,%eax
f0103b30:	83 c2 0c             	add    $0xc,%edx
f0103b33:	80 f9 a0             	cmp    $0xa0,%cl
f0103b36:	74 e9                	je     f0103b21 <debuginfo_eip+0x26e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b38:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b3d:	eb 36                	jmp    f0103b75 <debuginfo_eip+0x2c2>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (!user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
                        return -1;
f0103b3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b44:	eb 2f                	jmp    f0103b75 <debuginfo_eip+0x2c2>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.

		if (!user_mem_check(curenv, stabs, stab_end - stabs, PTE_U))
			return -1;
f0103b46:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b4b:	eb 28                	jmp    f0103b75 <debuginfo_eip+0x2c2>

		if (!user_mem_check(curenv, stabstr, stabstr_end - stabstr, PTE_U))
			return -1;
f0103b4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b52:	eb 21                	jmp    f0103b75 <debuginfo_eip+0x2c2>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b59:	eb 1a                	jmp    f0103b75 <debuginfo_eip+0x2c2>
f0103b5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b60:	eb 13                	jmp    f0103b75 <debuginfo_eip+0x2c2>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b67:	eb 0c                	jmp    f0103b75 <debuginfo_eip+0x2c2>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0103b69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b6e:	eb 05                	jmp    f0103b75 <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b70:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b78:	5b                   	pop    %ebx
f0103b79:	5e                   	pop    %esi
f0103b7a:	5f                   	pop    %edi
f0103b7b:	5d                   	pop    %ebp
f0103b7c:	c3                   	ret    

f0103b7d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b7d:	55                   	push   %ebp
f0103b7e:	89 e5                	mov    %esp,%ebp
f0103b80:	57                   	push   %edi
f0103b81:	56                   	push   %esi
f0103b82:	53                   	push   %ebx
f0103b83:	83 ec 1c             	sub    $0x1c,%esp
f0103b86:	89 c7                	mov    %eax,%edi
f0103b88:	89 d6                	mov    %edx,%esi
f0103b8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b8d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b90:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b93:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b96:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b99:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b9e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103ba1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103ba4:	39 d3                	cmp    %edx,%ebx
f0103ba6:	72 05                	jb     f0103bad <printnum+0x30>
f0103ba8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103bab:	77 45                	ja     f0103bf2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103bad:	83 ec 0c             	sub    $0xc,%esp
f0103bb0:	ff 75 18             	pushl  0x18(%ebp)
f0103bb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bb6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103bb9:	53                   	push   %ebx
f0103bba:	ff 75 10             	pushl  0x10(%ebp)
f0103bbd:	83 ec 08             	sub    $0x8,%esp
f0103bc0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bc3:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bc6:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bc9:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bcc:	e8 3f 09 00 00       	call   f0104510 <__udivdi3>
f0103bd1:	83 c4 18             	add    $0x18,%esp
f0103bd4:	52                   	push   %edx
f0103bd5:	50                   	push   %eax
f0103bd6:	89 f2                	mov    %esi,%edx
f0103bd8:	89 f8                	mov    %edi,%eax
f0103bda:	e8 9e ff ff ff       	call   f0103b7d <printnum>
f0103bdf:	83 c4 20             	add    $0x20,%esp
f0103be2:	eb 18                	jmp    f0103bfc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103be4:	83 ec 08             	sub    $0x8,%esp
f0103be7:	56                   	push   %esi
f0103be8:	ff 75 18             	pushl  0x18(%ebp)
f0103beb:	ff d7                	call   *%edi
f0103bed:	83 c4 10             	add    $0x10,%esp
f0103bf0:	eb 03                	jmp    f0103bf5 <printnum+0x78>
f0103bf2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103bf5:	83 eb 01             	sub    $0x1,%ebx
f0103bf8:	85 db                	test   %ebx,%ebx
f0103bfa:	7f e8                	jg     f0103be4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103bfc:	83 ec 08             	sub    $0x8,%esp
f0103bff:	56                   	push   %esi
f0103c00:	83 ec 04             	sub    $0x4,%esp
f0103c03:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c06:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c09:	ff 75 dc             	pushl  -0x24(%ebp)
f0103c0c:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c0f:	e8 2c 0a 00 00       	call   f0104640 <__umoddi3>
f0103c14:	83 c4 14             	add    $0x14,%esp
f0103c17:	0f be 80 d2 5c 10 f0 	movsbl -0xfefa32e(%eax),%eax
f0103c1e:	50                   	push   %eax
f0103c1f:	ff d7                	call   *%edi
}
f0103c21:	83 c4 10             	add    $0x10,%esp
f0103c24:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c27:	5b                   	pop    %ebx
f0103c28:	5e                   	pop    %esi
f0103c29:	5f                   	pop    %edi
f0103c2a:	5d                   	pop    %ebp
f0103c2b:	c3                   	ret    

f0103c2c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103c2c:	55                   	push   %ebp
f0103c2d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103c2f:	83 fa 01             	cmp    $0x1,%edx
f0103c32:	7e 0e                	jle    f0103c42 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103c34:	8b 10                	mov    (%eax),%edx
f0103c36:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103c39:	89 08                	mov    %ecx,(%eax)
f0103c3b:	8b 02                	mov    (%edx),%eax
f0103c3d:	8b 52 04             	mov    0x4(%edx),%edx
f0103c40:	eb 22                	jmp    f0103c64 <getuint+0x38>
	else if (lflag)
f0103c42:	85 d2                	test   %edx,%edx
f0103c44:	74 10                	je     f0103c56 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103c46:	8b 10                	mov    (%eax),%edx
f0103c48:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c4b:	89 08                	mov    %ecx,(%eax)
f0103c4d:	8b 02                	mov    (%edx),%eax
f0103c4f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c54:	eb 0e                	jmp    f0103c64 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103c56:	8b 10                	mov    (%eax),%edx
f0103c58:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c5b:	89 08                	mov    %ecx,(%eax)
f0103c5d:	8b 02                	mov    (%edx),%eax
f0103c5f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c64:	5d                   	pop    %ebp
f0103c65:	c3                   	ret    

f0103c66 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c66:	55                   	push   %ebp
f0103c67:	89 e5                	mov    %esp,%ebp
f0103c69:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c6c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c70:	8b 10                	mov    (%eax),%edx
f0103c72:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c75:	73 0a                	jae    f0103c81 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c77:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c7a:	89 08                	mov    %ecx,(%eax)
f0103c7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c7f:	88 02                	mov    %al,(%edx)
}
f0103c81:	5d                   	pop    %ebp
f0103c82:	c3                   	ret    

f0103c83 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c83:	55                   	push   %ebp
f0103c84:	89 e5                	mov    %esp,%ebp
f0103c86:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c89:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c8c:	50                   	push   %eax
f0103c8d:	ff 75 10             	pushl  0x10(%ebp)
f0103c90:	ff 75 0c             	pushl  0xc(%ebp)
f0103c93:	ff 75 08             	pushl  0x8(%ebp)
f0103c96:	e8 05 00 00 00       	call   f0103ca0 <vprintfmt>
	va_end(ap);
}
f0103c9b:	83 c4 10             	add    $0x10,%esp
f0103c9e:	c9                   	leave  
f0103c9f:	c3                   	ret    

f0103ca0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103ca0:	55                   	push   %ebp
f0103ca1:	89 e5                	mov    %esp,%ebp
f0103ca3:	57                   	push   %edi
f0103ca4:	56                   	push   %esi
f0103ca5:	53                   	push   %ebx
f0103ca6:	83 ec 2c             	sub    $0x2c,%esp
f0103ca9:	8b 75 08             	mov    0x8(%ebp),%esi
f0103cac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103caf:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103cb2:	eb 12                	jmp    f0103cc6 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103cb4:	85 c0                	test   %eax,%eax
f0103cb6:	0f 84 89 03 00 00    	je     f0104045 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103cbc:	83 ec 08             	sub    $0x8,%esp
f0103cbf:	53                   	push   %ebx
f0103cc0:	50                   	push   %eax
f0103cc1:	ff d6                	call   *%esi
f0103cc3:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103cc6:	83 c7 01             	add    $0x1,%edi
f0103cc9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ccd:	83 f8 25             	cmp    $0x25,%eax
f0103cd0:	75 e2                	jne    f0103cb4 <vprintfmt+0x14>
f0103cd2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103cd6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103cdd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103ce4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103ceb:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cf0:	eb 07                	jmp    f0103cf9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cf2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103cf5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cf9:	8d 47 01             	lea    0x1(%edi),%eax
f0103cfc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103cff:	0f b6 07             	movzbl (%edi),%eax
f0103d02:	0f b6 c8             	movzbl %al,%ecx
f0103d05:	83 e8 23             	sub    $0x23,%eax
f0103d08:	3c 55                	cmp    $0x55,%al
f0103d0a:	0f 87 1a 03 00 00    	ja     f010402a <vprintfmt+0x38a>
f0103d10:	0f b6 c0             	movzbl %al,%eax
f0103d13:	ff 24 85 5c 5d 10 f0 	jmp    *-0xfefa2a4(,%eax,4)
f0103d1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103d1d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103d21:	eb d6                	jmp    f0103cf9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d26:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d2b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103d2e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103d31:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103d35:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103d38:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103d3b:	83 fa 09             	cmp    $0x9,%edx
f0103d3e:	77 39                	ja     f0103d79 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d40:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103d43:	eb e9                	jmp    f0103d2e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d48:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d4b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d4e:	8b 00                	mov    (%eax),%eax
f0103d50:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d56:	eb 27                	jmp    f0103d7f <vprintfmt+0xdf>
f0103d58:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d5b:	85 c0                	test   %eax,%eax
f0103d5d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d62:	0f 49 c8             	cmovns %eax,%ecx
f0103d65:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d6b:	eb 8c                	jmp    f0103cf9 <vprintfmt+0x59>
f0103d6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d70:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d77:	eb 80                	jmp    f0103cf9 <vprintfmt+0x59>
f0103d79:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d7c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d7f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d83:	0f 89 70 ff ff ff    	jns    f0103cf9 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d89:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d8c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d8f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d96:	e9 5e ff ff ff       	jmp    f0103cf9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d9b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d9e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103da1:	e9 53 ff ff ff       	jmp    f0103cf9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103da6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103da9:	8d 50 04             	lea    0x4(%eax),%edx
f0103dac:	89 55 14             	mov    %edx,0x14(%ebp)
f0103daf:	83 ec 08             	sub    $0x8,%esp
f0103db2:	53                   	push   %ebx
f0103db3:	ff 30                	pushl  (%eax)
f0103db5:	ff d6                	call   *%esi
			break;
f0103db7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103dbd:	e9 04 ff ff ff       	jmp    f0103cc6 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103dc2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dc5:	8d 50 04             	lea    0x4(%eax),%edx
f0103dc8:	89 55 14             	mov    %edx,0x14(%ebp)
f0103dcb:	8b 00                	mov    (%eax),%eax
f0103dcd:	99                   	cltd   
f0103dce:	31 d0                	xor    %edx,%eax
f0103dd0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103dd2:	83 f8 06             	cmp    $0x6,%eax
f0103dd5:	7f 0b                	jg     f0103de2 <vprintfmt+0x142>
f0103dd7:	8b 14 85 b4 5e 10 f0 	mov    -0xfefa14c(,%eax,4),%edx
f0103dde:	85 d2                	test   %edx,%edx
f0103de0:	75 18                	jne    f0103dfa <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103de2:	50                   	push   %eax
f0103de3:	68 ea 5c 10 f0       	push   $0xf0105cea
f0103de8:	53                   	push   %ebx
f0103de9:	56                   	push   %esi
f0103dea:	e8 94 fe ff ff       	call   f0103c83 <printfmt>
f0103def:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103df2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103df5:	e9 cc fe ff ff       	jmp    f0103cc6 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103dfa:	52                   	push   %edx
f0103dfb:	68 39 55 10 f0       	push   $0xf0105539
f0103e00:	53                   	push   %ebx
f0103e01:	56                   	push   %esi
f0103e02:	e8 7c fe ff ff       	call   f0103c83 <printfmt>
f0103e07:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e0a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e0d:	e9 b4 fe ff ff       	jmp    f0103cc6 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103e12:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e15:	8d 50 04             	lea    0x4(%eax),%edx
f0103e18:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e1b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103e1d:	85 ff                	test   %edi,%edi
f0103e1f:	b8 e3 5c 10 f0       	mov    $0xf0105ce3,%eax
f0103e24:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103e27:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e2b:	0f 8e 94 00 00 00    	jle    f0103ec5 <vprintfmt+0x225>
f0103e31:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103e35:	0f 84 98 00 00 00    	je     f0103ed3 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e3b:	83 ec 08             	sub    $0x8,%esp
f0103e3e:	ff 75 d0             	pushl  -0x30(%ebp)
f0103e41:	57                   	push   %edi
f0103e42:	e8 5f 03 00 00       	call   f01041a6 <strnlen>
f0103e47:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e4a:	29 c1                	sub    %eax,%ecx
f0103e4c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103e4f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e52:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e56:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e59:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e5c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e5e:	eb 0f                	jmp    f0103e6f <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103e60:	83 ec 08             	sub    $0x8,%esp
f0103e63:	53                   	push   %ebx
f0103e64:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e67:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e69:	83 ef 01             	sub    $0x1,%edi
f0103e6c:	83 c4 10             	add    $0x10,%esp
f0103e6f:	85 ff                	test   %edi,%edi
f0103e71:	7f ed                	jg     f0103e60 <vprintfmt+0x1c0>
f0103e73:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e76:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103e79:	85 c9                	test   %ecx,%ecx
f0103e7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e80:	0f 49 c1             	cmovns %ecx,%eax
f0103e83:	29 c1                	sub    %eax,%ecx
f0103e85:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e88:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e8b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e8e:	89 cb                	mov    %ecx,%ebx
f0103e90:	eb 4d                	jmp    f0103edf <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e92:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e96:	74 1b                	je     f0103eb3 <vprintfmt+0x213>
f0103e98:	0f be c0             	movsbl %al,%eax
f0103e9b:	83 e8 20             	sub    $0x20,%eax
f0103e9e:	83 f8 5e             	cmp    $0x5e,%eax
f0103ea1:	76 10                	jbe    f0103eb3 <vprintfmt+0x213>
					putch('?', putdat);
f0103ea3:	83 ec 08             	sub    $0x8,%esp
f0103ea6:	ff 75 0c             	pushl  0xc(%ebp)
f0103ea9:	6a 3f                	push   $0x3f
f0103eab:	ff 55 08             	call   *0x8(%ebp)
f0103eae:	83 c4 10             	add    $0x10,%esp
f0103eb1:	eb 0d                	jmp    f0103ec0 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103eb3:	83 ec 08             	sub    $0x8,%esp
f0103eb6:	ff 75 0c             	pushl  0xc(%ebp)
f0103eb9:	52                   	push   %edx
f0103eba:	ff 55 08             	call   *0x8(%ebp)
f0103ebd:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103ec0:	83 eb 01             	sub    $0x1,%ebx
f0103ec3:	eb 1a                	jmp    f0103edf <vprintfmt+0x23f>
f0103ec5:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ec8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ecb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ece:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103ed1:	eb 0c                	jmp    f0103edf <vprintfmt+0x23f>
f0103ed3:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ed6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ed9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103edc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103edf:	83 c7 01             	add    $0x1,%edi
f0103ee2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ee6:	0f be d0             	movsbl %al,%edx
f0103ee9:	85 d2                	test   %edx,%edx
f0103eeb:	74 23                	je     f0103f10 <vprintfmt+0x270>
f0103eed:	85 f6                	test   %esi,%esi
f0103eef:	78 a1                	js     f0103e92 <vprintfmt+0x1f2>
f0103ef1:	83 ee 01             	sub    $0x1,%esi
f0103ef4:	79 9c                	jns    f0103e92 <vprintfmt+0x1f2>
f0103ef6:	89 df                	mov    %ebx,%edi
f0103ef8:	8b 75 08             	mov    0x8(%ebp),%esi
f0103efb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103efe:	eb 18                	jmp    f0103f18 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103f00:	83 ec 08             	sub    $0x8,%esp
f0103f03:	53                   	push   %ebx
f0103f04:	6a 20                	push   $0x20
f0103f06:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103f08:	83 ef 01             	sub    $0x1,%edi
f0103f0b:	83 c4 10             	add    $0x10,%esp
f0103f0e:	eb 08                	jmp    f0103f18 <vprintfmt+0x278>
f0103f10:	89 df                	mov    %ebx,%edi
f0103f12:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f15:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f18:	85 ff                	test   %edi,%edi
f0103f1a:	7f e4                	jg     f0103f00 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f1f:	e9 a2 fd ff ff       	jmp    f0103cc6 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f24:	83 fa 01             	cmp    $0x1,%edx
f0103f27:	7e 16                	jle    f0103f3f <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103f29:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f2c:	8d 50 08             	lea    0x8(%eax),%edx
f0103f2f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f32:	8b 50 04             	mov    0x4(%eax),%edx
f0103f35:	8b 00                	mov    (%eax),%eax
f0103f37:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f3a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103f3d:	eb 32                	jmp    f0103f71 <vprintfmt+0x2d1>
	else if (lflag)
f0103f3f:	85 d2                	test   %edx,%edx
f0103f41:	74 18                	je     f0103f5b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103f43:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f46:	8d 50 04             	lea    0x4(%eax),%edx
f0103f49:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f4c:	8b 00                	mov    (%eax),%eax
f0103f4e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f51:	89 c1                	mov    %eax,%ecx
f0103f53:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f56:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f59:	eb 16                	jmp    f0103f71 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103f5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f5e:	8d 50 04             	lea    0x4(%eax),%edx
f0103f61:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f64:	8b 00                	mov    (%eax),%eax
f0103f66:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f69:	89 c1                	mov    %eax,%ecx
f0103f6b:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f6e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f71:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f74:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f77:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f7c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f80:	79 74                	jns    f0103ff6 <vprintfmt+0x356>
				putch('-', putdat);
f0103f82:	83 ec 08             	sub    $0x8,%esp
f0103f85:	53                   	push   %ebx
f0103f86:	6a 2d                	push   $0x2d
f0103f88:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f8a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f8d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f90:	f7 d8                	neg    %eax
f0103f92:	83 d2 00             	adc    $0x0,%edx
f0103f95:	f7 da                	neg    %edx
f0103f97:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f9a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103f9f:	eb 55                	jmp    f0103ff6 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103fa1:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fa4:	e8 83 fc ff ff       	call   f0103c2c <getuint>
			base = 10;
f0103fa9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103fae:	eb 46                	jmp    f0103ff6 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103fb0:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fb3:	e8 74 fc ff ff       	call   f0103c2c <getuint>
			base = 8;
f0103fb8:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103fbd:	eb 37                	jmp    f0103ff6 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103fbf:	83 ec 08             	sub    $0x8,%esp
f0103fc2:	53                   	push   %ebx
f0103fc3:	6a 30                	push   $0x30
f0103fc5:	ff d6                	call   *%esi
			putch('x', putdat);
f0103fc7:	83 c4 08             	add    $0x8,%esp
f0103fca:	53                   	push   %ebx
f0103fcb:	6a 78                	push   $0x78
f0103fcd:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103fcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fd2:	8d 50 04             	lea    0x4(%eax),%edx
f0103fd5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103fd8:	8b 00                	mov    (%eax),%eax
f0103fda:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103fdf:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103fe2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103fe7:	eb 0d                	jmp    f0103ff6 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103fe9:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fec:	e8 3b fc ff ff       	call   f0103c2c <getuint>
			base = 16;
f0103ff1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103ff6:	83 ec 0c             	sub    $0xc,%esp
f0103ff9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103ffd:	57                   	push   %edi
f0103ffe:	ff 75 e0             	pushl  -0x20(%ebp)
f0104001:	51                   	push   %ecx
f0104002:	52                   	push   %edx
f0104003:	50                   	push   %eax
f0104004:	89 da                	mov    %ebx,%edx
f0104006:	89 f0                	mov    %esi,%eax
f0104008:	e8 70 fb ff ff       	call   f0103b7d <printnum>
			break;
f010400d:	83 c4 20             	add    $0x20,%esp
f0104010:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104013:	e9 ae fc ff ff       	jmp    f0103cc6 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104018:	83 ec 08             	sub    $0x8,%esp
f010401b:	53                   	push   %ebx
f010401c:	51                   	push   %ecx
f010401d:	ff d6                	call   *%esi
			break;
f010401f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104022:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104025:	e9 9c fc ff ff       	jmp    f0103cc6 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010402a:	83 ec 08             	sub    $0x8,%esp
f010402d:	53                   	push   %ebx
f010402e:	6a 25                	push   $0x25
f0104030:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104032:	83 c4 10             	add    $0x10,%esp
f0104035:	eb 03                	jmp    f010403a <vprintfmt+0x39a>
f0104037:	83 ef 01             	sub    $0x1,%edi
f010403a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010403e:	75 f7                	jne    f0104037 <vprintfmt+0x397>
f0104040:	e9 81 fc ff ff       	jmp    f0103cc6 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104045:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104048:	5b                   	pop    %ebx
f0104049:	5e                   	pop    %esi
f010404a:	5f                   	pop    %edi
f010404b:	5d                   	pop    %ebp
f010404c:	c3                   	ret    

f010404d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010404d:	55                   	push   %ebp
f010404e:	89 e5                	mov    %esp,%ebp
f0104050:	83 ec 18             	sub    $0x18,%esp
f0104053:	8b 45 08             	mov    0x8(%ebp),%eax
f0104056:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104059:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010405c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104060:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104063:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010406a:	85 c0                	test   %eax,%eax
f010406c:	74 26                	je     f0104094 <vsnprintf+0x47>
f010406e:	85 d2                	test   %edx,%edx
f0104070:	7e 22                	jle    f0104094 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104072:	ff 75 14             	pushl  0x14(%ebp)
f0104075:	ff 75 10             	pushl  0x10(%ebp)
f0104078:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010407b:	50                   	push   %eax
f010407c:	68 66 3c 10 f0       	push   $0xf0103c66
f0104081:	e8 1a fc ff ff       	call   f0103ca0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104086:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104089:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010408c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010408f:	83 c4 10             	add    $0x10,%esp
f0104092:	eb 05                	jmp    f0104099 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104094:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104099:	c9                   	leave  
f010409a:	c3                   	ret    

f010409b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010409b:	55                   	push   %ebp
f010409c:	89 e5                	mov    %esp,%ebp
f010409e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01040a1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01040a4:	50                   	push   %eax
f01040a5:	ff 75 10             	pushl  0x10(%ebp)
f01040a8:	ff 75 0c             	pushl  0xc(%ebp)
f01040ab:	ff 75 08             	pushl  0x8(%ebp)
f01040ae:	e8 9a ff ff ff       	call   f010404d <vsnprintf>
	va_end(ap);

	return rc;
}
f01040b3:	c9                   	leave  
f01040b4:	c3                   	ret    

f01040b5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01040b5:	55                   	push   %ebp
f01040b6:	89 e5                	mov    %esp,%ebp
f01040b8:	57                   	push   %edi
f01040b9:	56                   	push   %esi
f01040ba:	53                   	push   %ebx
f01040bb:	83 ec 0c             	sub    $0xc,%esp
f01040be:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01040c1:	85 c0                	test   %eax,%eax
f01040c3:	74 11                	je     f01040d6 <readline+0x21>
		cprintf("%s", prompt);
f01040c5:	83 ec 08             	sub    $0x8,%esp
f01040c8:	50                   	push   %eax
f01040c9:	68 39 55 10 f0       	push   $0xf0105539
f01040ce:	e8 5e ee ff ff       	call   f0102f31 <cprintf>
f01040d3:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01040d6:	83 ec 0c             	sub    $0xc,%esp
f01040d9:	6a 00                	push   $0x0
f01040db:	e8 56 c5 ff ff       	call   f0100636 <iscons>
f01040e0:	89 c7                	mov    %eax,%edi
f01040e2:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01040e5:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040ea:	e8 36 c5 ff ff       	call   f0100625 <getchar>
f01040ef:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01040f1:	85 c0                	test   %eax,%eax
f01040f3:	79 18                	jns    f010410d <readline+0x58>
			cprintf("read error: %e\n", c);
f01040f5:	83 ec 08             	sub    $0x8,%esp
f01040f8:	50                   	push   %eax
f01040f9:	68 d0 5e 10 f0       	push   $0xf0105ed0
f01040fe:	e8 2e ee ff ff       	call   f0102f31 <cprintf>
			return NULL;
f0104103:	83 c4 10             	add    $0x10,%esp
f0104106:	b8 00 00 00 00       	mov    $0x0,%eax
f010410b:	eb 79                	jmp    f0104186 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010410d:	83 f8 08             	cmp    $0x8,%eax
f0104110:	0f 94 c2             	sete   %dl
f0104113:	83 f8 7f             	cmp    $0x7f,%eax
f0104116:	0f 94 c0             	sete   %al
f0104119:	08 c2                	or     %al,%dl
f010411b:	74 1a                	je     f0104137 <readline+0x82>
f010411d:	85 f6                	test   %esi,%esi
f010411f:	7e 16                	jle    f0104137 <readline+0x82>
			if (echoing)
f0104121:	85 ff                	test   %edi,%edi
f0104123:	74 0d                	je     f0104132 <readline+0x7d>
				cputchar('\b');
f0104125:	83 ec 0c             	sub    $0xc,%esp
f0104128:	6a 08                	push   $0x8
f010412a:	e8 e6 c4 ff ff       	call   f0100615 <cputchar>
f010412f:	83 c4 10             	add    $0x10,%esp
			i--;
f0104132:	83 ee 01             	sub    $0x1,%esi
f0104135:	eb b3                	jmp    f01040ea <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104137:	83 fb 1f             	cmp    $0x1f,%ebx
f010413a:	7e 23                	jle    f010415f <readline+0xaa>
f010413c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104142:	7f 1b                	jg     f010415f <readline+0xaa>
			if (echoing)
f0104144:	85 ff                	test   %edi,%edi
f0104146:	74 0c                	je     f0104154 <readline+0x9f>
				cputchar(c);
f0104148:	83 ec 0c             	sub    $0xc,%esp
f010414b:	53                   	push   %ebx
f010414c:	e8 c4 c4 ff ff       	call   f0100615 <cputchar>
f0104151:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104154:	88 9e 40 28 17 f0    	mov    %bl,-0xfe8d7c0(%esi)
f010415a:	8d 76 01             	lea    0x1(%esi),%esi
f010415d:	eb 8b                	jmp    f01040ea <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010415f:	83 fb 0a             	cmp    $0xa,%ebx
f0104162:	74 05                	je     f0104169 <readline+0xb4>
f0104164:	83 fb 0d             	cmp    $0xd,%ebx
f0104167:	75 81                	jne    f01040ea <readline+0x35>
			if (echoing)
f0104169:	85 ff                	test   %edi,%edi
f010416b:	74 0d                	je     f010417a <readline+0xc5>
				cputchar('\n');
f010416d:	83 ec 0c             	sub    $0xc,%esp
f0104170:	6a 0a                	push   $0xa
f0104172:	e8 9e c4 ff ff       	call   f0100615 <cputchar>
f0104177:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010417a:	c6 86 40 28 17 f0 00 	movb   $0x0,-0xfe8d7c0(%esi)
			return buf;
f0104181:	b8 40 28 17 f0       	mov    $0xf0172840,%eax
		}
	}
}
f0104186:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104189:	5b                   	pop    %ebx
f010418a:	5e                   	pop    %esi
f010418b:	5f                   	pop    %edi
f010418c:	5d                   	pop    %ebp
f010418d:	c3                   	ret    

f010418e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010418e:	55                   	push   %ebp
f010418f:	89 e5                	mov    %esp,%ebp
f0104191:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104194:	b8 00 00 00 00       	mov    $0x0,%eax
f0104199:	eb 03                	jmp    f010419e <strlen+0x10>
		n++;
f010419b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010419e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01041a2:	75 f7                	jne    f010419b <strlen+0xd>
		n++;
	return n;
}
f01041a4:	5d                   	pop    %ebp
f01041a5:	c3                   	ret    

f01041a6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01041a6:	55                   	push   %ebp
f01041a7:	89 e5                	mov    %esp,%ebp
f01041a9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041af:	ba 00 00 00 00       	mov    $0x0,%edx
f01041b4:	eb 03                	jmp    f01041b9 <strnlen+0x13>
		n++;
f01041b6:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041b9:	39 c2                	cmp    %eax,%edx
f01041bb:	74 08                	je     f01041c5 <strnlen+0x1f>
f01041bd:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01041c1:	75 f3                	jne    f01041b6 <strnlen+0x10>
f01041c3:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01041c5:	5d                   	pop    %ebp
f01041c6:	c3                   	ret    

f01041c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041c7:	55                   	push   %ebp
f01041c8:	89 e5                	mov    %esp,%ebp
f01041ca:	53                   	push   %ebx
f01041cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01041ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041d1:	89 c2                	mov    %eax,%edx
f01041d3:	83 c2 01             	add    $0x1,%edx
f01041d6:	83 c1 01             	add    $0x1,%ecx
f01041d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01041dd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01041e0:	84 db                	test   %bl,%bl
f01041e2:	75 ef                	jne    f01041d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01041e4:	5b                   	pop    %ebx
f01041e5:	5d                   	pop    %ebp
f01041e6:	c3                   	ret    

f01041e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01041e7:	55                   	push   %ebp
f01041e8:	89 e5                	mov    %esp,%ebp
f01041ea:	53                   	push   %ebx
f01041eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01041ee:	53                   	push   %ebx
f01041ef:	e8 9a ff ff ff       	call   f010418e <strlen>
f01041f4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01041f7:	ff 75 0c             	pushl  0xc(%ebp)
f01041fa:	01 d8                	add    %ebx,%eax
f01041fc:	50                   	push   %eax
f01041fd:	e8 c5 ff ff ff       	call   f01041c7 <strcpy>
	return dst;
}
f0104202:	89 d8                	mov    %ebx,%eax
f0104204:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104207:	c9                   	leave  
f0104208:	c3                   	ret    

f0104209 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104209:	55                   	push   %ebp
f010420a:	89 e5                	mov    %esp,%ebp
f010420c:	56                   	push   %esi
f010420d:	53                   	push   %ebx
f010420e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104211:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104214:	89 f3                	mov    %esi,%ebx
f0104216:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104219:	89 f2                	mov    %esi,%edx
f010421b:	eb 0f                	jmp    f010422c <strncpy+0x23>
		*dst++ = *src;
f010421d:	83 c2 01             	add    $0x1,%edx
f0104220:	0f b6 01             	movzbl (%ecx),%eax
f0104223:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104226:	80 39 01             	cmpb   $0x1,(%ecx)
f0104229:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010422c:	39 da                	cmp    %ebx,%edx
f010422e:	75 ed                	jne    f010421d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104230:	89 f0                	mov    %esi,%eax
f0104232:	5b                   	pop    %ebx
f0104233:	5e                   	pop    %esi
f0104234:	5d                   	pop    %ebp
f0104235:	c3                   	ret    

f0104236 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104236:	55                   	push   %ebp
f0104237:	89 e5                	mov    %esp,%ebp
f0104239:	56                   	push   %esi
f010423a:	53                   	push   %ebx
f010423b:	8b 75 08             	mov    0x8(%ebp),%esi
f010423e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104241:	8b 55 10             	mov    0x10(%ebp),%edx
f0104244:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104246:	85 d2                	test   %edx,%edx
f0104248:	74 21                	je     f010426b <strlcpy+0x35>
f010424a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010424e:	89 f2                	mov    %esi,%edx
f0104250:	eb 09                	jmp    f010425b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104252:	83 c2 01             	add    $0x1,%edx
f0104255:	83 c1 01             	add    $0x1,%ecx
f0104258:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010425b:	39 c2                	cmp    %eax,%edx
f010425d:	74 09                	je     f0104268 <strlcpy+0x32>
f010425f:	0f b6 19             	movzbl (%ecx),%ebx
f0104262:	84 db                	test   %bl,%bl
f0104264:	75 ec                	jne    f0104252 <strlcpy+0x1c>
f0104266:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104268:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010426b:	29 f0                	sub    %esi,%eax
}
f010426d:	5b                   	pop    %ebx
f010426e:	5e                   	pop    %esi
f010426f:	5d                   	pop    %ebp
f0104270:	c3                   	ret    

f0104271 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104271:	55                   	push   %ebp
f0104272:	89 e5                	mov    %esp,%ebp
f0104274:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104277:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010427a:	eb 06                	jmp    f0104282 <strcmp+0x11>
		p++, q++;
f010427c:	83 c1 01             	add    $0x1,%ecx
f010427f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104282:	0f b6 01             	movzbl (%ecx),%eax
f0104285:	84 c0                	test   %al,%al
f0104287:	74 04                	je     f010428d <strcmp+0x1c>
f0104289:	3a 02                	cmp    (%edx),%al
f010428b:	74 ef                	je     f010427c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010428d:	0f b6 c0             	movzbl %al,%eax
f0104290:	0f b6 12             	movzbl (%edx),%edx
f0104293:	29 d0                	sub    %edx,%eax
}
f0104295:	5d                   	pop    %ebp
f0104296:	c3                   	ret    

f0104297 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104297:	55                   	push   %ebp
f0104298:	89 e5                	mov    %esp,%ebp
f010429a:	53                   	push   %ebx
f010429b:	8b 45 08             	mov    0x8(%ebp),%eax
f010429e:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042a1:	89 c3                	mov    %eax,%ebx
f01042a3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01042a6:	eb 06                	jmp    f01042ae <strncmp+0x17>
		n--, p++, q++;
f01042a8:	83 c0 01             	add    $0x1,%eax
f01042ab:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01042ae:	39 d8                	cmp    %ebx,%eax
f01042b0:	74 15                	je     f01042c7 <strncmp+0x30>
f01042b2:	0f b6 08             	movzbl (%eax),%ecx
f01042b5:	84 c9                	test   %cl,%cl
f01042b7:	74 04                	je     f01042bd <strncmp+0x26>
f01042b9:	3a 0a                	cmp    (%edx),%cl
f01042bb:	74 eb                	je     f01042a8 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042bd:	0f b6 00             	movzbl (%eax),%eax
f01042c0:	0f b6 12             	movzbl (%edx),%edx
f01042c3:	29 d0                	sub    %edx,%eax
f01042c5:	eb 05                	jmp    f01042cc <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01042c7:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042cc:	5b                   	pop    %ebx
f01042cd:	5d                   	pop    %ebp
f01042ce:	c3                   	ret    

f01042cf <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01042cf:	55                   	push   %ebp
f01042d0:	89 e5                	mov    %esp,%ebp
f01042d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01042d5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042d9:	eb 07                	jmp    f01042e2 <strchr+0x13>
		if (*s == c)
f01042db:	38 ca                	cmp    %cl,%dl
f01042dd:	74 0f                	je     f01042ee <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01042df:	83 c0 01             	add    $0x1,%eax
f01042e2:	0f b6 10             	movzbl (%eax),%edx
f01042e5:	84 d2                	test   %dl,%dl
f01042e7:	75 f2                	jne    f01042db <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01042e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042ee:	5d                   	pop    %ebp
f01042ef:	c3                   	ret    

f01042f0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01042f0:	55                   	push   %ebp
f01042f1:	89 e5                	mov    %esp,%ebp
f01042f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01042f6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042fa:	eb 03                	jmp    f01042ff <strfind+0xf>
f01042fc:	83 c0 01             	add    $0x1,%eax
f01042ff:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104302:	38 ca                	cmp    %cl,%dl
f0104304:	74 04                	je     f010430a <strfind+0x1a>
f0104306:	84 d2                	test   %dl,%dl
f0104308:	75 f2                	jne    f01042fc <strfind+0xc>
			break;
	return (char *) s;
}
f010430a:	5d                   	pop    %ebp
f010430b:	c3                   	ret    

f010430c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010430c:	55                   	push   %ebp
f010430d:	89 e5                	mov    %esp,%ebp
f010430f:	57                   	push   %edi
f0104310:	56                   	push   %esi
f0104311:	53                   	push   %ebx
f0104312:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104315:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104318:	85 c9                	test   %ecx,%ecx
f010431a:	74 36                	je     f0104352 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010431c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104322:	75 28                	jne    f010434c <memset+0x40>
f0104324:	f6 c1 03             	test   $0x3,%cl
f0104327:	75 23                	jne    f010434c <memset+0x40>
		c &= 0xFF;
f0104329:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010432d:	89 d3                	mov    %edx,%ebx
f010432f:	c1 e3 08             	shl    $0x8,%ebx
f0104332:	89 d6                	mov    %edx,%esi
f0104334:	c1 e6 18             	shl    $0x18,%esi
f0104337:	89 d0                	mov    %edx,%eax
f0104339:	c1 e0 10             	shl    $0x10,%eax
f010433c:	09 f0                	or     %esi,%eax
f010433e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104340:	89 d8                	mov    %ebx,%eax
f0104342:	09 d0                	or     %edx,%eax
f0104344:	c1 e9 02             	shr    $0x2,%ecx
f0104347:	fc                   	cld    
f0104348:	f3 ab                	rep stos %eax,%es:(%edi)
f010434a:	eb 06                	jmp    f0104352 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010434c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010434f:	fc                   	cld    
f0104350:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104352:	89 f8                	mov    %edi,%eax
f0104354:	5b                   	pop    %ebx
f0104355:	5e                   	pop    %esi
f0104356:	5f                   	pop    %edi
f0104357:	5d                   	pop    %ebp
f0104358:	c3                   	ret    

f0104359 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104359:	55                   	push   %ebp
f010435a:	89 e5                	mov    %esp,%ebp
f010435c:	57                   	push   %edi
f010435d:	56                   	push   %esi
f010435e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104361:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104364:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104367:	39 c6                	cmp    %eax,%esi
f0104369:	73 35                	jae    f01043a0 <memmove+0x47>
f010436b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010436e:	39 d0                	cmp    %edx,%eax
f0104370:	73 2e                	jae    f01043a0 <memmove+0x47>
		s += n;
		d += n;
f0104372:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104375:	89 d6                	mov    %edx,%esi
f0104377:	09 fe                	or     %edi,%esi
f0104379:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010437f:	75 13                	jne    f0104394 <memmove+0x3b>
f0104381:	f6 c1 03             	test   $0x3,%cl
f0104384:	75 0e                	jne    f0104394 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104386:	83 ef 04             	sub    $0x4,%edi
f0104389:	8d 72 fc             	lea    -0x4(%edx),%esi
f010438c:	c1 e9 02             	shr    $0x2,%ecx
f010438f:	fd                   	std    
f0104390:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104392:	eb 09                	jmp    f010439d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104394:	83 ef 01             	sub    $0x1,%edi
f0104397:	8d 72 ff             	lea    -0x1(%edx),%esi
f010439a:	fd                   	std    
f010439b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010439d:	fc                   	cld    
f010439e:	eb 1d                	jmp    f01043bd <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043a0:	89 f2                	mov    %esi,%edx
f01043a2:	09 c2                	or     %eax,%edx
f01043a4:	f6 c2 03             	test   $0x3,%dl
f01043a7:	75 0f                	jne    f01043b8 <memmove+0x5f>
f01043a9:	f6 c1 03             	test   $0x3,%cl
f01043ac:	75 0a                	jne    f01043b8 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01043ae:	c1 e9 02             	shr    $0x2,%ecx
f01043b1:	89 c7                	mov    %eax,%edi
f01043b3:	fc                   	cld    
f01043b4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043b6:	eb 05                	jmp    f01043bd <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01043b8:	89 c7                	mov    %eax,%edi
f01043ba:	fc                   	cld    
f01043bb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01043bd:	5e                   	pop    %esi
f01043be:	5f                   	pop    %edi
f01043bf:	5d                   	pop    %ebp
f01043c0:	c3                   	ret    

f01043c1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01043c1:	55                   	push   %ebp
f01043c2:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01043c4:	ff 75 10             	pushl  0x10(%ebp)
f01043c7:	ff 75 0c             	pushl  0xc(%ebp)
f01043ca:	ff 75 08             	pushl  0x8(%ebp)
f01043cd:	e8 87 ff ff ff       	call   f0104359 <memmove>
}
f01043d2:	c9                   	leave  
f01043d3:	c3                   	ret    

f01043d4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01043d4:	55                   	push   %ebp
f01043d5:	89 e5                	mov    %esp,%ebp
f01043d7:	56                   	push   %esi
f01043d8:	53                   	push   %ebx
f01043d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01043dc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043df:	89 c6                	mov    %eax,%esi
f01043e1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043e4:	eb 1a                	jmp    f0104400 <memcmp+0x2c>
		if (*s1 != *s2)
f01043e6:	0f b6 08             	movzbl (%eax),%ecx
f01043e9:	0f b6 1a             	movzbl (%edx),%ebx
f01043ec:	38 d9                	cmp    %bl,%cl
f01043ee:	74 0a                	je     f01043fa <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01043f0:	0f b6 c1             	movzbl %cl,%eax
f01043f3:	0f b6 db             	movzbl %bl,%ebx
f01043f6:	29 d8                	sub    %ebx,%eax
f01043f8:	eb 0f                	jmp    f0104409 <memcmp+0x35>
		s1++, s2++;
f01043fa:	83 c0 01             	add    $0x1,%eax
f01043fd:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104400:	39 f0                	cmp    %esi,%eax
f0104402:	75 e2                	jne    f01043e6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104404:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104409:	5b                   	pop    %ebx
f010440a:	5e                   	pop    %esi
f010440b:	5d                   	pop    %ebp
f010440c:	c3                   	ret    

f010440d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010440d:	55                   	push   %ebp
f010440e:	89 e5                	mov    %esp,%ebp
f0104410:	53                   	push   %ebx
f0104411:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104414:	89 c1                	mov    %eax,%ecx
f0104416:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104419:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010441d:	eb 0a                	jmp    f0104429 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010441f:	0f b6 10             	movzbl (%eax),%edx
f0104422:	39 da                	cmp    %ebx,%edx
f0104424:	74 07                	je     f010442d <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104426:	83 c0 01             	add    $0x1,%eax
f0104429:	39 c8                	cmp    %ecx,%eax
f010442b:	72 f2                	jb     f010441f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010442d:	5b                   	pop    %ebx
f010442e:	5d                   	pop    %ebp
f010442f:	c3                   	ret    

f0104430 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104430:	55                   	push   %ebp
f0104431:	89 e5                	mov    %esp,%ebp
f0104433:	57                   	push   %edi
f0104434:	56                   	push   %esi
f0104435:	53                   	push   %ebx
f0104436:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104439:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010443c:	eb 03                	jmp    f0104441 <strtol+0x11>
		s++;
f010443e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104441:	0f b6 01             	movzbl (%ecx),%eax
f0104444:	3c 20                	cmp    $0x20,%al
f0104446:	74 f6                	je     f010443e <strtol+0xe>
f0104448:	3c 09                	cmp    $0x9,%al
f010444a:	74 f2                	je     f010443e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010444c:	3c 2b                	cmp    $0x2b,%al
f010444e:	75 0a                	jne    f010445a <strtol+0x2a>
		s++;
f0104450:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104453:	bf 00 00 00 00       	mov    $0x0,%edi
f0104458:	eb 11                	jmp    f010446b <strtol+0x3b>
f010445a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010445f:	3c 2d                	cmp    $0x2d,%al
f0104461:	75 08                	jne    f010446b <strtol+0x3b>
		s++, neg = 1;
f0104463:	83 c1 01             	add    $0x1,%ecx
f0104466:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010446b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104471:	75 15                	jne    f0104488 <strtol+0x58>
f0104473:	80 39 30             	cmpb   $0x30,(%ecx)
f0104476:	75 10                	jne    f0104488 <strtol+0x58>
f0104478:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010447c:	75 7c                	jne    f01044fa <strtol+0xca>
		s += 2, base = 16;
f010447e:	83 c1 02             	add    $0x2,%ecx
f0104481:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104486:	eb 16                	jmp    f010449e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104488:	85 db                	test   %ebx,%ebx
f010448a:	75 12                	jne    f010449e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010448c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104491:	80 39 30             	cmpb   $0x30,(%ecx)
f0104494:	75 08                	jne    f010449e <strtol+0x6e>
		s++, base = 8;
f0104496:	83 c1 01             	add    $0x1,%ecx
f0104499:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010449e:	b8 00 00 00 00       	mov    $0x0,%eax
f01044a3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01044a6:	0f b6 11             	movzbl (%ecx),%edx
f01044a9:	8d 72 d0             	lea    -0x30(%edx),%esi
f01044ac:	89 f3                	mov    %esi,%ebx
f01044ae:	80 fb 09             	cmp    $0x9,%bl
f01044b1:	77 08                	ja     f01044bb <strtol+0x8b>
			dig = *s - '0';
f01044b3:	0f be d2             	movsbl %dl,%edx
f01044b6:	83 ea 30             	sub    $0x30,%edx
f01044b9:	eb 22                	jmp    f01044dd <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01044bb:	8d 72 9f             	lea    -0x61(%edx),%esi
f01044be:	89 f3                	mov    %esi,%ebx
f01044c0:	80 fb 19             	cmp    $0x19,%bl
f01044c3:	77 08                	ja     f01044cd <strtol+0x9d>
			dig = *s - 'a' + 10;
f01044c5:	0f be d2             	movsbl %dl,%edx
f01044c8:	83 ea 57             	sub    $0x57,%edx
f01044cb:	eb 10                	jmp    f01044dd <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01044cd:	8d 72 bf             	lea    -0x41(%edx),%esi
f01044d0:	89 f3                	mov    %esi,%ebx
f01044d2:	80 fb 19             	cmp    $0x19,%bl
f01044d5:	77 16                	ja     f01044ed <strtol+0xbd>
			dig = *s - 'A' + 10;
f01044d7:	0f be d2             	movsbl %dl,%edx
f01044da:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01044dd:	3b 55 10             	cmp    0x10(%ebp),%edx
f01044e0:	7d 0b                	jge    f01044ed <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01044e2:	83 c1 01             	add    $0x1,%ecx
f01044e5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01044e9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01044eb:	eb b9                	jmp    f01044a6 <strtol+0x76>

	if (endptr)
f01044ed:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01044f1:	74 0d                	je     f0104500 <strtol+0xd0>
		*endptr = (char *) s;
f01044f3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044f6:	89 0e                	mov    %ecx,(%esi)
f01044f8:	eb 06                	jmp    f0104500 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044fa:	85 db                	test   %ebx,%ebx
f01044fc:	74 98                	je     f0104496 <strtol+0x66>
f01044fe:	eb 9e                	jmp    f010449e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104500:	89 c2                	mov    %eax,%edx
f0104502:	f7 da                	neg    %edx
f0104504:	85 ff                	test   %edi,%edi
f0104506:	0f 45 c2             	cmovne %edx,%eax
}
f0104509:	5b                   	pop    %ebx
f010450a:	5e                   	pop    %esi
f010450b:	5f                   	pop    %edi
f010450c:	5d                   	pop    %ebp
f010450d:	c3                   	ret    
f010450e:	66 90                	xchg   %ax,%ax

f0104510 <__udivdi3>:
f0104510:	55                   	push   %ebp
f0104511:	57                   	push   %edi
f0104512:	56                   	push   %esi
f0104513:	53                   	push   %ebx
f0104514:	83 ec 1c             	sub    $0x1c,%esp
f0104517:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010451b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010451f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104523:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104527:	85 f6                	test   %esi,%esi
f0104529:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010452d:	89 ca                	mov    %ecx,%edx
f010452f:	89 f8                	mov    %edi,%eax
f0104531:	75 3d                	jne    f0104570 <__udivdi3+0x60>
f0104533:	39 cf                	cmp    %ecx,%edi
f0104535:	0f 87 c5 00 00 00    	ja     f0104600 <__udivdi3+0xf0>
f010453b:	85 ff                	test   %edi,%edi
f010453d:	89 fd                	mov    %edi,%ebp
f010453f:	75 0b                	jne    f010454c <__udivdi3+0x3c>
f0104541:	b8 01 00 00 00       	mov    $0x1,%eax
f0104546:	31 d2                	xor    %edx,%edx
f0104548:	f7 f7                	div    %edi
f010454a:	89 c5                	mov    %eax,%ebp
f010454c:	89 c8                	mov    %ecx,%eax
f010454e:	31 d2                	xor    %edx,%edx
f0104550:	f7 f5                	div    %ebp
f0104552:	89 c1                	mov    %eax,%ecx
f0104554:	89 d8                	mov    %ebx,%eax
f0104556:	89 cf                	mov    %ecx,%edi
f0104558:	f7 f5                	div    %ebp
f010455a:	89 c3                	mov    %eax,%ebx
f010455c:	89 d8                	mov    %ebx,%eax
f010455e:	89 fa                	mov    %edi,%edx
f0104560:	83 c4 1c             	add    $0x1c,%esp
f0104563:	5b                   	pop    %ebx
f0104564:	5e                   	pop    %esi
f0104565:	5f                   	pop    %edi
f0104566:	5d                   	pop    %ebp
f0104567:	c3                   	ret    
f0104568:	90                   	nop
f0104569:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104570:	39 ce                	cmp    %ecx,%esi
f0104572:	77 74                	ja     f01045e8 <__udivdi3+0xd8>
f0104574:	0f bd fe             	bsr    %esi,%edi
f0104577:	83 f7 1f             	xor    $0x1f,%edi
f010457a:	0f 84 98 00 00 00    	je     f0104618 <__udivdi3+0x108>
f0104580:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104585:	89 f9                	mov    %edi,%ecx
f0104587:	89 c5                	mov    %eax,%ebp
f0104589:	29 fb                	sub    %edi,%ebx
f010458b:	d3 e6                	shl    %cl,%esi
f010458d:	89 d9                	mov    %ebx,%ecx
f010458f:	d3 ed                	shr    %cl,%ebp
f0104591:	89 f9                	mov    %edi,%ecx
f0104593:	d3 e0                	shl    %cl,%eax
f0104595:	09 ee                	or     %ebp,%esi
f0104597:	89 d9                	mov    %ebx,%ecx
f0104599:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010459d:	89 d5                	mov    %edx,%ebp
f010459f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045a3:	d3 ed                	shr    %cl,%ebp
f01045a5:	89 f9                	mov    %edi,%ecx
f01045a7:	d3 e2                	shl    %cl,%edx
f01045a9:	89 d9                	mov    %ebx,%ecx
f01045ab:	d3 e8                	shr    %cl,%eax
f01045ad:	09 c2                	or     %eax,%edx
f01045af:	89 d0                	mov    %edx,%eax
f01045b1:	89 ea                	mov    %ebp,%edx
f01045b3:	f7 f6                	div    %esi
f01045b5:	89 d5                	mov    %edx,%ebp
f01045b7:	89 c3                	mov    %eax,%ebx
f01045b9:	f7 64 24 0c          	mull   0xc(%esp)
f01045bd:	39 d5                	cmp    %edx,%ebp
f01045bf:	72 10                	jb     f01045d1 <__udivdi3+0xc1>
f01045c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045c5:	89 f9                	mov    %edi,%ecx
f01045c7:	d3 e6                	shl    %cl,%esi
f01045c9:	39 c6                	cmp    %eax,%esi
f01045cb:	73 07                	jae    f01045d4 <__udivdi3+0xc4>
f01045cd:	39 d5                	cmp    %edx,%ebp
f01045cf:	75 03                	jne    f01045d4 <__udivdi3+0xc4>
f01045d1:	83 eb 01             	sub    $0x1,%ebx
f01045d4:	31 ff                	xor    %edi,%edi
f01045d6:	89 d8                	mov    %ebx,%eax
f01045d8:	89 fa                	mov    %edi,%edx
f01045da:	83 c4 1c             	add    $0x1c,%esp
f01045dd:	5b                   	pop    %ebx
f01045de:	5e                   	pop    %esi
f01045df:	5f                   	pop    %edi
f01045e0:	5d                   	pop    %ebp
f01045e1:	c3                   	ret    
f01045e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01045e8:	31 ff                	xor    %edi,%edi
f01045ea:	31 db                	xor    %ebx,%ebx
f01045ec:	89 d8                	mov    %ebx,%eax
f01045ee:	89 fa                	mov    %edi,%edx
f01045f0:	83 c4 1c             	add    $0x1c,%esp
f01045f3:	5b                   	pop    %ebx
f01045f4:	5e                   	pop    %esi
f01045f5:	5f                   	pop    %edi
f01045f6:	5d                   	pop    %ebp
f01045f7:	c3                   	ret    
f01045f8:	90                   	nop
f01045f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104600:	89 d8                	mov    %ebx,%eax
f0104602:	f7 f7                	div    %edi
f0104604:	31 ff                	xor    %edi,%edi
f0104606:	89 c3                	mov    %eax,%ebx
f0104608:	89 d8                	mov    %ebx,%eax
f010460a:	89 fa                	mov    %edi,%edx
f010460c:	83 c4 1c             	add    $0x1c,%esp
f010460f:	5b                   	pop    %ebx
f0104610:	5e                   	pop    %esi
f0104611:	5f                   	pop    %edi
f0104612:	5d                   	pop    %ebp
f0104613:	c3                   	ret    
f0104614:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104618:	39 ce                	cmp    %ecx,%esi
f010461a:	72 0c                	jb     f0104628 <__udivdi3+0x118>
f010461c:	31 db                	xor    %ebx,%ebx
f010461e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104622:	0f 87 34 ff ff ff    	ja     f010455c <__udivdi3+0x4c>
f0104628:	bb 01 00 00 00       	mov    $0x1,%ebx
f010462d:	e9 2a ff ff ff       	jmp    f010455c <__udivdi3+0x4c>
f0104632:	66 90                	xchg   %ax,%ax
f0104634:	66 90                	xchg   %ax,%ax
f0104636:	66 90                	xchg   %ax,%ax
f0104638:	66 90                	xchg   %ax,%ax
f010463a:	66 90                	xchg   %ax,%ax
f010463c:	66 90                	xchg   %ax,%ax
f010463e:	66 90                	xchg   %ax,%ax

f0104640 <__umoddi3>:
f0104640:	55                   	push   %ebp
f0104641:	57                   	push   %edi
f0104642:	56                   	push   %esi
f0104643:	53                   	push   %ebx
f0104644:	83 ec 1c             	sub    $0x1c,%esp
f0104647:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010464b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010464f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104653:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104657:	85 d2                	test   %edx,%edx
f0104659:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010465d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104661:	89 f3                	mov    %esi,%ebx
f0104663:	89 3c 24             	mov    %edi,(%esp)
f0104666:	89 74 24 04          	mov    %esi,0x4(%esp)
f010466a:	75 1c                	jne    f0104688 <__umoddi3+0x48>
f010466c:	39 f7                	cmp    %esi,%edi
f010466e:	76 50                	jbe    f01046c0 <__umoddi3+0x80>
f0104670:	89 c8                	mov    %ecx,%eax
f0104672:	89 f2                	mov    %esi,%edx
f0104674:	f7 f7                	div    %edi
f0104676:	89 d0                	mov    %edx,%eax
f0104678:	31 d2                	xor    %edx,%edx
f010467a:	83 c4 1c             	add    $0x1c,%esp
f010467d:	5b                   	pop    %ebx
f010467e:	5e                   	pop    %esi
f010467f:	5f                   	pop    %edi
f0104680:	5d                   	pop    %ebp
f0104681:	c3                   	ret    
f0104682:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104688:	39 f2                	cmp    %esi,%edx
f010468a:	89 d0                	mov    %edx,%eax
f010468c:	77 52                	ja     f01046e0 <__umoddi3+0xa0>
f010468e:	0f bd ea             	bsr    %edx,%ebp
f0104691:	83 f5 1f             	xor    $0x1f,%ebp
f0104694:	75 5a                	jne    f01046f0 <__umoddi3+0xb0>
f0104696:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010469a:	0f 82 e0 00 00 00    	jb     f0104780 <__umoddi3+0x140>
f01046a0:	39 0c 24             	cmp    %ecx,(%esp)
f01046a3:	0f 86 d7 00 00 00    	jbe    f0104780 <__umoddi3+0x140>
f01046a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01046ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01046b1:	83 c4 1c             	add    $0x1c,%esp
f01046b4:	5b                   	pop    %ebx
f01046b5:	5e                   	pop    %esi
f01046b6:	5f                   	pop    %edi
f01046b7:	5d                   	pop    %ebp
f01046b8:	c3                   	ret    
f01046b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046c0:	85 ff                	test   %edi,%edi
f01046c2:	89 fd                	mov    %edi,%ebp
f01046c4:	75 0b                	jne    f01046d1 <__umoddi3+0x91>
f01046c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01046cb:	31 d2                	xor    %edx,%edx
f01046cd:	f7 f7                	div    %edi
f01046cf:	89 c5                	mov    %eax,%ebp
f01046d1:	89 f0                	mov    %esi,%eax
f01046d3:	31 d2                	xor    %edx,%edx
f01046d5:	f7 f5                	div    %ebp
f01046d7:	89 c8                	mov    %ecx,%eax
f01046d9:	f7 f5                	div    %ebp
f01046db:	89 d0                	mov    %edx,%eax
f01046dd:	eb 99                	jmp    f0104678 <__umoddi3+0x38>
f01046df:	90                   	nop
f01046e0:	89 c8                	mov    %ecx,%eax
f01046e2:	89 f2                	mov    %esi,%edx
f01046e4:	83 c4 1c             	add    $0x1c,%esp
f01046e7:	5b                   	pop    %ebx
f01046e8:	5e                   	pop    %esi
f01046e9:	5f                   	pop    %edi
f01046ea:	5d                   	pop    %ebp
f01046eb:	c3                   	ret    
f01046ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046f0:	8b 34 24             	mov    (%esp),%esi
f01046f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01046f8:	89 e9                	mov    %ebp,%ecx
f01046fa:	29 ef                	sub    %ebp,%edi
f01046fc:	d3 e0                	shl    %cl,%eax
f01046fe:	89 f9                	mov    %edi,%ecx
f0104700:	89 f2                	mov    %esi,%edx
f0104702:	d3 ea                	shr    %cl,%edx
f0104704:	89 e9                	mov    %ebp,%ecx
f0104706:	09 c2                	or     %eax,%edx
f0104708:	89 d8                	mov    %ebx,%eax
f010470a:	89 14 24             	mov    %edx,(%esp)
f010470d:	89 f2                	mov    %esi,%edx
f010470f:	d3 e2                	shl    %cl,%edx
f0104711:	89 f9                	mov    %edi,%ecx
f0104713:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104717:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010471b:	d3 e8                	shr    %cl,%eax
f010471d:	89 e9                	mov    %ebp,%ecx
f010471f:	89 c6                	mov    %eax,%esi
f0104721:	d3 e3                	shl    %cl,%ebx
f0104723:	89 f9                	mov    %edi,%ecx
f0104725:	89 d0                	mov    %edx,%eax
f0104727:	d3 e8                	shr    %cl,%eax
f0104729:	89 e9                	mov    %ebp,%ecx
f010472b:	09 d8                	or     %ebx,%eax
f010472d:	89 d3                	mov    %edx,%ebx
f010472f:	89 f2                	mov    %esi,%edx
f0104731:	f7 34 24             	divl   (%esp)
f0104734:	89 d6                	mov    %edx,%esi
f0104736:	d3 e3                	shl    %cl,%ebx
f0104738:	f7 64 24 04          	mull   0x4(%esp)
f010473c:	39 d6                	cmp    %edx,%esi
f010473e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104742:	89 d1                	mov    %edx,%ecx
f0104744:	89 c3                	mov    %eax,%ebx
f0104746:	72 08                	jb     f0104750 <__umoddi3+0x110>
f0104748:	75 11                	jne    f010475b <__umoddi3+0x11b>
f010474a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010474e:	73 0b                	jae    f010475b <__umoddi3+0x11b>
f0104750:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104754:	1b 14 24             	sbb    (%esp),%edx
f0104757:	89 d1                	mov    %edx,%ecx
f0104759:	89 c3                	mov    %eax,%ebx
f010475b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010475f:	29 da                	sub    %ebx,%edx
f0104761:	19 ce                	sbb    %ecx,%esi
f0104763:	89 f9                	mov    %edi,%ecx
f0104765:	89 f0                	mov    %esi,%eax
f0104767:	d3 e0                	shl    %cl,%eax
f0104769:	89 e9                	mov    %ebp,%ecx
f010476b:	d3 ea                	shr    %cl,%edx
f010476d:	89 e9                	mov    %ebp,%ecx
f010476f:	d3 ee                	shr    %cl,%esi
f0104771:	09 d0                	or     %edx,%eax
f0104773:	89 f2                	mov    %esi,%edx
f0104775:	83 c4 1c             	add    $0x1c,%esp
f0104778:	5b                   	pop    %ebx
f0104779:	5e                   	pop    %esi
f010477a:	5f                   	pop    %edi
f010477b:	5d                   	pop    %ebp
f010477c:	c3                   	ret    
f010477d:	8d 76 00             	lea    0x0(%esi),%esi
f0104780:	29 f9                	sub    %edi,%ecx
f0104782:	19 d6                	sbb    %edx,%esi
f0104784:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104788:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010478c:	e9 18 ff ff ff       	jmp    f01046a9 <__umoddi3+0x69>
