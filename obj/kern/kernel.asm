
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 50 49 11 f0       	mov    $0xf0114950,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 32 20 00 00       	call   f010208f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 25 10 f0       	push   $0xf0102540
f010006f:	e8 62 15 00 00       	call   f01015d6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 b8 0e 00 00       	call   f0100f31 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 6e 07 00 00       	call   f01007f4 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 49 11 f0 00 	cmpl   $0x0,0xf0114940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 49 11 f0    	mov    %esi,0xf0114940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 5b 25 10 f0       	push   $0xf010255b
f01000b5:	e8 1c 15 00 00       	call   f01015d6 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 ec 14 00 00       	call   f01015b0 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 81 28 10 f0 	movl   $0xf0102881,(%esp)
f01000cb:	e8 06 15 00 00       	call   f01015d6 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 17 07 00 00       	call   f01007f4 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 73 25 10 f0       	push   $0xf0102573
f01000f7:	e8 da 14 00 00       	call   f01015d6 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 a8 14 00 00       	call   f01015b0 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 81 28 10 f0 	movl   $0xf0102881,(%esp)
f010010f:	e8 c2 14 00 00       	call   f01015d6 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 e0 26 10 f0 	movzbl -0xfefd920(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 e0 26 10 f0 	movzbl -0xfefd920(%edx),%eax
f0100211:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f0100217:	0f b6 8a e0 25 10 f0 	movzbl -0xfefda20(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d c0 25 10 f0 	mov    -0xfefda40(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 8d 25 10 f0       	push   $0xf010258d
f010026d:	e8 64 13 00 00       	call   f01015d6 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 bb 1c 00 00       	call   f01020dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004c3:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004d4:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 45 11 f0 	setne  0xf0114534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 99 25 10 f0       	push   $0xf0102599
f01005f0:	e8 e1 0f 00 00       	call   f01015d6 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 e0 27 10 f0       	push   $0xf01027e0
f0100636:	68 fe 27 10 f0       	push   $0xf01027fe
f010063b:	68 03 28 10 f0       	push   $0xf0102803
f0100640:	e8 91 0f 00 00       	call   f01015d6 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 c0 28 10 f0       	push   $0xf01028c0
f010064d:	68 0c 28 10 f0       	push   $0xf010280c
f0100652:	68 03 28 10 f0       	push   $0xf0102803
f0100657:	e8 7a 0f 00 00       	call   f01015d6 <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 e8 28 10 f0       	push   $0xf01028e8
f0100664:	68 15 28 10 f0       	push   $0xf0102815
f0100669:	68 03 28 10 f0       	push   $0xf0102803
f010066e:	e8 63 0f 00 00       	call   f01015d6 <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 1f 28 10 f0       	push   $0xf010281f
f0100685:	e8 4c 0f 00 00       	call   f01015d6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 14 29 10 f0       	push   $0xf0102914
f0100697:	e8 3a 0f 00 00       	call   f01015d6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 3c 29 10 f0       	push   $0xf010293c
f01006ae:	e8 23 0f 00 00       	call   f01015d6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 21 25 10 00       	push   $0x102521
f01006bb:	68 21 25 10 f0       	push   $0xf0102521
f01006c0:	68 60 29 10 f0       	push   $0xf0102960
f01006c5:	e8 0c 0f 00 00       	call   f01015d6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 43 11 00       	push   $0x114300
f01006d2:	68 00 43 11 f0       	push   $0xf0114300
f01006d7:	68 84 29 10 f0       	push   $0xf0102984
f01006dc:	e8 f5 0e 00 00       	call   f01015d6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 50 49 11 00       	push   $0x114950
f01006e9:	68 50 49 11 f0       	push   $0xf0114950
f01006ee:	68 a8 29 10 f0       	push   $0xf01029a8
f01006f3:	e8 de 0e 00 00       	call   f01015d6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 4f 4d 11 f0       	mov    $0xf0114d4f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 cc 29 10 f0       	push   $0xf01029cc
f010071e:	e8 b3 0e 00 00       	call   f01015d6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100733:	89 eb                	mov    %ebp,%ebx
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
f0100735:	68 38 28 10 f0       	push   $0xf0102838
f010073a:	e8 97 0e 00 00       	call   f01015d6 <cprintf>
	while(ebp)
f010073f:	83 c4 10             	add    $0x10,%esp
		cprintf("%08x ", *(ebp+3));
		cprintf("%08x ", *(ebp+4));
		cprintf("%08x ", *(ebp+5));
		cprintf("%08x", *(ebp+6));

		if(debuginfo_eip(eip, &info) == 0)
f0100742:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f0100745:	e9 95 00 00 00       	jmp    f01007df <mon_backtrace+0xb5>
	{
		eip = *(ebp+1);
f010074a:	8b 73 04             	mov    0x4(%ebx),%esi

		cprintf("ebp %08x  eip %08x  args ", ebp, eip);
f010074d:	83 ec 04             	sub    $0x4,%esp
f0100750:	56                   	push   %esi
f0100751:	53                   	push   %ebx
f0100752:	68 4b 28 10 f0       	push   $0xf010284b
f0100757:	e8 7a 0e 00 00       	call   f01015d6 <cprintf>
		cprintf("%08x ", *(ebp+2));
f010075c:	83 c4 08             	add    $0x8,%esp
f010075f:	ff 73 08             	pushl  0x8(%ebx)
f0100762:	68 65 28 10 f0       	push   $0xf0102865
f0100767:	e8 6a 0e 00 00       	call   f01015d6 <cprintf>
		cprintf("%08x ", *(ebp+3));
f010076c:	83 c4 08             	add    $0x8,%esp
f010076f:	ff 73 0c             	pushl  0xc(%ebx)
f0100772:	68 65 28 10 f0       	push   $0xf0102865
f0100777:	e8 5a 0e 00 00       	call   f01015d6 <cprintf>
		cprintf("%08x ", *(ebp+4));
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff 73 10             	pushl  0x10(%ebx)
f0100782:	68 65 28 10 f0       	push   $0xf0102865
f0100787:	e8 4a 0e 00 00       	call   f01015d6 <cprintf>
		cprintf("%08x ", *(ebp+5));
f010078c:	83 c4 08             	add    $0x8,%esp
f010078f:	ff 73 14             	pushl  0x14(%ebx)
f0100792:	68 65 28 10 f0       	push   $0xf0102865
f0100797:	e8 3a 0e 00 00       	call   f01015d6 <cprintf>
		cprintf("%08x", *(ebp+6));
f010079c:	83 c4 08             	add    $0x8,%esp
f010079f:	ff 73 18             	pushl  0x18(%ebx)
f01007a2:	68 6b 28 10 f0       	push   $0xf010286b
f01007a7:	e8 2a 0e 00 00       	call   f01015d6 <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01007ac:	83 c4 08             	add    $0x8,%esp
f01007af:	57                   	push   %edi
f01007b0:	56                   	push   %esi
f01007b1:	e8 2a 0f 00 00       	call   f01016e0 <debuginfo_eip>
f01007b6:	83 c4 10             	add    $0x10,%esp
f01007b9:	85 c0                	test   %eax,%eax
f01007bb:	75 20                	jne    f01007dd <mon_backtrace+0xb3>
		{
			cprintf("\t %s:%d: %.*s+%d\n\n", info.eip_file, info.eip_line, info.eip_fn_namelen, 											      info.eip_fn_name, eip-info.eip_fn_addr);
f01007bd:	83 ec 08             	sub    $0x8,%esp
f01007c0:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01007c3:	56                   	push   %esi
f01007c4:	ff 75 d8             	pushl  -0x28(%ebp)
f01007c7:	ff 75 dc             	pushl  -0x24(%ebp)
f01007ca:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007cd:	ff 75 d0             	pushl  -0x30(%ebp)
f01007d0:	68 70 28 10 f0       	push   $0xf0102870
f01007d5:	e8 fc 0d 00 00       	call   f01015d6 <cprintf>
f01007da:	83 c4 20             	add    $0x20,%esp
		}

		ebp = (uint32_t*) *ebp;
f01007dd:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t *ebp = (uint32_t*) read_ebp();
	struct Eipdebuginfo info;
	uint32_t eip;
	cprintf("Stack backtrace: \n");
	while(ebp)
f01007df:	85 db                	test   %ebx,%ebx
f01007e1:	0f 85 63 ff ff ff    	jne    f010074a <mon_backtrace+0x20>
		}

		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f01007e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007ef:	5b                   	pop    %ebx
f01007f0:	5e                   	pop    %esi
f01007f1:	5f                   	pop    %edi
f01007f2:	5d                   	pop    %ebp
f01007f3:	c3                   	ret    

f01007f4 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f4:	55                   	push   %ebp
f01007f5:	89 e5                	mov    %esp,%ebp
f01007f7:	57                   	push   %edi
f01007f8:	56                   	push   %esi
f01007f9:	53                   	push   %ebx
f01007fa:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fd:	68 f8 29 10 f0       	push   $0xf01029f8
f0100802:	e8 cf 0d 00 00       	call   f01015d6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100807:	c7 04 24 1c 2a 10 f0 	movl   $0xf0102a1c,(%esp)
f010080e:	e8 c3 0d 00 00       	call   f01015d6 <cprintf>
f0100813:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100816:	83 ec 0c             	sub    $0xc,%esp
f0100819:	68 83 28 10 f0       	push   $0xf0102883
f010081e:	e8 15 16 00 00       	call   f0101e38 <readline>
f0100823:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100825:	83 c4 10             	add    $0x10,%esp
f0100828:	85 c0                	test   %eax,%eax
f010082a:	74 ea                	je     f0100816 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010082c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100833:	be 00 00 00 00       	mov    $0x0,%esi
f0100838:	eb 0a                	jmp    f0100844 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010083a:	c6 03 00             	movb   $0x0,(%ebx)
f010083d:	89 f7                	mov    %esi,%edi
f010083f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100842:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100844:	0f b6 03             	movzbl (%ebx),%eax
f0100847:	84 c0                	test   %al,%al
f0100849:	74 63                	je     f01008ae <monitor+0xba>
f010084b:	83 ec 08             	sub    $0x8,%esp
f010084e:	0f be c0             	movsbl %al,%eax
f0100851:	50                   	push   %eax
f0100852:	68 87 28 10 f0       	push   $0xf0102887
f0100857:	e8 f6 17 00 00       	call   f0102052 <strchr>
f010085c:	83 c4 10             	add    $0x10,%esp
f010085f:	85 c0                	test   %eax,%eax
f0100861:	75 d7                	jne    f010083a <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100863:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100866:	74 46                	je     f01008ae <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100868:	83 fe 0f             	cmp    $0xf,%esi
f010086b:	75 14                	jne    f0100881 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086d:	83 ec 08             	sub    $0x8,%esp
f0100870:	6a 10                	push   $0x10
f0100872:	68 8c 28 10 f0       	push   $0xf010288c
f0100877:	e8 5a 0d 00 00       	call   f01015d6 <cprintf>
f010087c:	83 c4 10             	add    $0x10,%esp
f010087f:	eb 95                	jmp    f0100816 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100881:	8d 7e 01             	lea    0x1(%esi),%edi
f0100884:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100888:	eb 03                	jmp    f010088d <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010088a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010088d:	0f b6 03             	movzbl (%ebx),%eax
f0100890:	84 c0                	test   %al,%al
f0100892:	74 ae                	je     f0100842 <monitor+0x4e>
f0100894:	83 ec 08             	sub    $0x8,%esp
f0100897:	0f be c0             	movsbl %al,%eax
f010089a:	50                   	push   %eax
f010089b:	68 87 28 10 f0       	push   $0xf0102887
f01008a0:	e8 ad 17 00 00       	call   f0102052 <strchr>
f01008a5:	83 c4 10             	add    $0x10,%esp
f01008a8:	85 c0                	test   %eax,%eax
f01008aa:	74 de                	je     f010088a <monitor+0x96>
f01008ac:	eb 94                	jmp    f0100842 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008ae:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b6:	85 f6                	test   %esi,%esi
f01008b8:	0f 84 58 ff ff ff    	je     f0100816 <monitor+0x22>
f01008be:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c3:	83 ec 08             	sub    $0x8,%esp
f01008c6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c9:	ff 34 85 60 2a 10 f0 	pushl  -0xfefd5a0(,%eax,4)
f01008d0:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d3:	e8 1c 17 00 00       	call   f0101ff4 <strcmp>
f01008d8:	83 c4 10             	add    $0x10,%esp
f01008db:	85 c0                	test   %eax,%eax
f01008dd:	75 21                	jne    f0100900 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008df:	83 ec 04             	sub    $0x4,%esp
f01008e2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008e5:	ff 75 08             	pushl  0x8(%ebp)
f01008e8:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008eb:	52                   	push   %edx
f01008ec:	56                   	push   %esi
f01008ed:	ff 14 85 68 2a 10 f0 	call   *-0xfefd598(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f4:	83 c4 10             	add    $0x10,%esp
f01008f7:	85 c0                	test   %eax,%eax
f01008f9:	78 25                	js     f0100920 <monitor+0x12c>
f01008fb:	e9 16 ff ff ff       	jmp    f0100816 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100900:	83 c3 01             	add    $0x1,%ebx
f0100903:	83 fb 03             	cmp    $0x3,%ebx
f0100906:	75 bb                	jne    f01008c3 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	ff 75 a8             	pushl  -0x58(%ebp)
f010090e:	68 a9 28 10 f0       	push   $0xf01028a9
f0100913:	e8 be 0c 00 00       	call   f01015d6 <cprintf>
f0100918:	83 c4 10             	add    $0x10,%esp
f010091b:	e9 f6 fe ff ff       	jmp    f0100816 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100920:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100923:	5b                   	pop    %ebx
f0100924:	5e                   	pop    %esi
f0100925:	5f                   	pop    %edi
f0100926:	5d                   	pop    %ebp
f0100927:	c3                   	ret    

f0100928 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100928:	55                   	push   %ebp
f0100929:	89 e5                	mov    %esp,%ebp
f010092b:	56                   	push   %esi
f010092c:	53                   	push   %ebx
f010092d:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010092f:	83 ec 0c             	sub    $0xc,%esp
f0100932:	50                   	push   %eax
f0100933:	e8 37 0c 00 00       	call   f010156f <mc146818_read>
f0100938:	89 c6                	mov    %eax,%esi
f010093a:	83 c3 01             	add    $0x1,%ebx
f010093d:	89 1c 24             	mov    %ebx,(%esp)
f0100940:	e8 2a 0c 00 00       	call   f010156f <mc146818_read>
f0100945:	c1 e0 08             	shl    $0x8,%eax
f0100948:	09 f0                	or     %esi,%eax
}
f010094a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010094d:	5b                   	pop    %ebx
f010094e:	5e                   	pop    %esi
f010094f:	5d                   	pop    %ebp
f0100950:	c3                   	ret    

f0100951 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100951:	89 d1                	mov    %edx,%ecx
f0100953:	c1 e9 16             	shr    $0x16,%ecx
f0100956:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100959:	a8 01                	test   $0x1,%al
f010095b:	74 52                	je     f01009af <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010095d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100962:	89 c1                	mov    %eax,%ecx
f0100964:	c1 e9 0c             	shr    $0xc,%ecx
f0100967:	3b 0d 44 49 11 f0    	cmp    0xf0114944,%ecx
f010096d:	72 1b                	jb     f010098a <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010096f:	55                   	push   %ebp
f0100970:	89 e5                	mov    %esp,%ebp
f0100972:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100975:	50                   	push   %eax
f0100976:	68 84 2a 10 f0       	push   $0xf0102a84
f010097b:	68 dd 02 00 00       	push   $0x2dd
f0100980:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100985:	e8 01 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010098a:	c1 ea 0c             	shr    $0xc,%edx
f010098d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100993:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010099a:	89 c2                	mov    %eax,%edx
f010099c:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010099f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009a4:	85 d2                	test   %edx,%edx
f01009a6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009ab:	0f 44 c2             	cmove  %edx,%eax
f01009ae:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009b4:	c3                   	ret    

f01009b5 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009b5:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f01009bc:	75 11                	jne    f01009cf <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009be:	ba 4f 59 11 f0       	mov    $0xf011594f,%edx
f01009c3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009c9:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f01009cf:	85 c0                	test   %eax,%eax
f01009d1:	75 06                	jne    f01009d9 <boot_alloc+0x24>
		return nextfree;
f01009d3:	a1 38 45 11 f0       	mov    0xf0114538,%eax
	{
		nextfree = new;
	}	

	return result;
}
f01009d8:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009d9:	55                   	push   %ebp
f01009da:	89 e5                	mov    %esp,%ebp
f01009dc:	53                   	push   %ebx
f01009dd:	83 ec 04             	sub    $0x4,%esp
	//
	// LAB 2: Your code here.
	if(n == 0)
		return nextfree;
	
	result = nextfree;
f01009e0:	8b 15 38 45 11 f0    	mov    0xf0114538,%edx
	char* new = ROUNDUP(nextfree + n, PGSIZE);	
f01009e6:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01009ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01009f2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01009f7:	77 12                	ja     f0100a0b <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01009f9:	50                   	push   %eax
f01009fa:	68 a8 2a 10 f0       	push   $0xf0102aa8
f01009ff:	6a 6f                	push   $0x6f
f0100a01:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100a06:	e8 80 f6 ff ff       	call   f010008b <_panic>
	
	if(PADDR(new) > npages * PGSIZE)
f0100a0b:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f0100a11:	c1 e1 0c             	shl    $0xc,%ecx
f0100a14:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100a1a:	39 d9                	cmp    %ebx,%ecx
f0100a1c:	73 14                	jae    f0100a32 <boot_alloc+0x7d>
		panic("boot_alloc: out of memory!\n");
f0100a1e:	83 ec 04             	sub    $0x4,%esp
f0100a21:	68 c4 2c 10 f0       	push   $0xf0102cc4
f0100a26:	6a 70                	push   $0x70
f0100a28:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100a2d:	e8 59 f6 ff ff       	call   f010008b <_panic>
	else
	{
		nextfree = new;
f0100a32:	a3 38 45 11 f0       	mov    %eax,0xf0114538
	}	

	return result;
f0100a37:	89 d0                	mov    %edx,%eax
}
f0100a39:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a3c:	c9                   	leave  
f0100a3d:	c3                   	ret    

f0100a3e <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a3e:	55                   	push   %ebp
f0100a3f:	89 e5                	mov    %esp,%ebp
f0100a41:	57                   	push   %edi
f0100a42:	56                   	push   %esi
f0100a43:	53                   	push   %ebx
f0100a44:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a47:	84 c0                	test   %al,%al
f0100a49:	0f 85 81 02 00 00    	jne    f0100cd0 <check_page_free_list+0x292>
f0100a4f:	e9 8e 02 00 00       	jmp    f0100ce2 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a54:	83 ec 04             	sub    $0x4,%esp
f0100a57:	68 cc 2a 10 f0       	push   $0xf0102acc
f0100a5c:	68 1e 02 00 00       	push   $0x21e
f0100a61:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100a66:	e8 20 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a6b:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a6e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a71:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a74:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a77:	89 c2                	mov    %eax,%edx
f0100a79:	2b 15 4c 49 11 f0    	sub    0xf011494c,%edx
f0100a7f:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a85:	0f 95 c2             	setne  %dl
f0100a88:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a8b:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a8f:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a91:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a95:	8b 00                	mov    (%eax),%eax
f0100a97:	85 c0                	test   %eax,%eax
f0100a99:	75 dc                	jne    f0100a77 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a9b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a9e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aa4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aaa:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aac:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100aaf:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab4:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ab9:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100abf:	eb 53                	jmp    f0100b14 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ac1:	89 d8                	mov    %ebx,%eax
f0100ac3:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100ac9:	c1 f8 03             	sar    $0x3,%eax
f0100acc:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100acf:	89 c2                	mov    %eax,%edx
f0100ad1:	c1 ea 16             	shr    $0x16,%edx
f0100ad4:	39 f2                	cmp    %esi,%edx
f0100ad6:	73 3a                	jae    f0100b12 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ad8:	89 c2                	mov    %eax,%edx
f0100ada:	c1 ea 0c             	shr    $0xc,%edx
f0100add:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100ae3:	72 12                	jb     f0100af7 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae5:	50                   	push   %eax
f0100ae6:	68 84 2a 10 f0       	push   $0xf0102a84
f0100aeb:	6a 52                	push   $0x52
f0100aed:	68 e0 2c 10 f0       	push   $0xf0102ce0
f0100af2:	e8 94 f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100af7:	83 ec 04             	sub    $0x4,%esp
f0100afa:	68 80 00 00 00       	push   $0x80
f0100aff:	68 97 00 00 00       	push   $0x97
f0100b04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b09:	50                   	push   %eax
f0100b0a:	e8 80 15 00 00       	call   f010208f <memset>
f0100b0f:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b12:	8b 1b                	mov    (%ebx),%ebx
f0100b14:	85 db                	test   %ebx,%ebx
f0100b16:	75 a9                	jne    f0100ac1 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b18:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b1d:	e8 93 fe ff ff       	call   f01009b5 <boot_alloc>
f0100b22:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b25:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b2b:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
		assert(pp < pages + npages);
f0100b31:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100b36:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b39:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b3c:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b3f:	be 00 00 00 00       	mov    $0x0,%esi
f0100b44:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b47:	e9 30 01 00 00       	jmp    f0100c7c <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b4c:	39 ca                	cmp    %ecx,%edx
f0100b4e:	73 19                	jae    f0100b69 <check_page_free_list+0x12b>
f0100b50:	68 ee 2c 10 f0       	push   $0xf0102cee
f0100b55:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100b5a:	68 38 02 00 00       	push   $0x238
f0100b5f:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100b64:	e8 22 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b69:	39 fa                	cmp    %edi,%edx
f0100b6b:	72 19                	jb     f0100b86 <check_page_free_list+0x148>
f0100b6d:	68 0f 2d 10 f0       	push   $0xf0102d0f
f0100b72:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100b77:	68 39 02 00 00       	push   $0x239
f0100b7c:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100b81:	e8 05 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b86:	89 d0                	mov    %edx,%eax
f0100b88:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b8b:	a8 07                	test   $0x7,%al
f0100b8d:	74 19                	je     f0100ba8 <check_page_free_list+0x16a>
f0100b8f:	68 f0 2a 10 f0       	push   $0xf0102af0
f0100b94:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100b99:	68 3a 02 00 00       	push   $0x23a
f0100b9e:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100ba3:	e8 e3 f4 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ba8:	c1 f8 03             	sar    $0x3,%eax
f0100bab:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bae:	85 c0                	test   %eax,%eax
f0100bb0:	75 19                	jne    f0100bcb <check_page_free_list+0x18d>
f0100bb2:	68 23 2d 10 f0       	push   $0xf0102d23
f0100bb7:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100bbc:	68 3d 02 00 00       	push   $0x23d
f0100bc1:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100bc6:	e8 c0 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bcb:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bd0:	75 19                	jne    f0100beb <check_page_free_list+0x1ad>
f0100bd2:	68 34 2d 10 f0       	push   $0xf0102d34
f0100bd7:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100bdc:	68 3e 02 00 00       	push   $0x23e
f0100be1:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100be6:	e8 a0 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100beb:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bf0:	75 19                	jne    f0100c0b <check_page_free_list+0x1cd>
f0100bf2:	68 24 2b 10 f0       	push   $0xf0102b24
f0100bf7:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100bfc:	68 3f 02 00 00       	push   $0x23f
f0100c01:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100c06:	e8 80 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c0b:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c10:	75 19                	jne    f0100c2b <check_page_free_list+0x1ed>
f0100c12:	68 4d 2d 10 f0       	push   $0xf0102d4d
f0100c17:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100c1c:	68 40 02 00 00       	push   $0x240
f0100c21:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100c26:	e8 60 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c2b:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c30:	76 3f                	jbe    f0100c71 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c32:	89 c3                	mov    %eax,%ebx
f0100c34:	c1 eb 0c             	shr    $0xc,%ebx
f0100c37:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c3a:	77 12                	ja     f0100c4e <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3c:	50                   	push   %eax
f0100c3d:	68 84 2a 10 f0       	push   $0xf0102a84
f0100c42:	6a 52                	push   $0x52
f0100c44:	68 e0 2c 10 f0       	push   $0xf0102ce0
f0100c49:	e8 3d f4 ff ff       	call   f010008b <_panic>
f0100c4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c53:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c56:	76 1e                	jbe    f0100c76 <check_page_free_list+0x238>
f0100c58:	68 48 2b 10 f0       	push   $0xf0102b48
f0100c5d:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100c62:	68 41 02 00 00       	push   $0x241
f0100c67:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100c6c:	e8 1a f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c71:	83 c6 01             	add    $0x1,%esi
f0100c74:	eb 04                	jmp    f0100c7a <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c76:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7a:	8b 12                	mov    (%edx),%edx
f0100c7c:	85 d2                	test   %edx,%edx
f0100c7e:	0f 85 c8 fe ff ff    	jne    f0100b4c <check_page_free_list+0x10e>
f0100c84:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c87:	85 f6                	test   %esi,%esi
f0100c89:	7f 19                	jg     f0100ca4 <check_page_free_list+0x266>
f0100c8b:	68 67 2d 10 f0       	push   $0xf0102d67
f0100c90:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100c95:	68 49 02 00 00       	push   $0x249
f0100c9a:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100c9f:	e8 e7 f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100ca4:	85 db                	test   %ebx,%ebx
f0100ca6:	7f 19                	jg     f0100cc1 <check_page_free_list+0x283>
f0100ca8:	68 79 2d 10 f0       	push   $0xf0102d79
f0100cad:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0100cb2:	68 4a 02 00 00       	push   $0x24a
f0100cb7:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100cbc:	e8 ca f3 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100cc1:	83 ec 0c             	sub    $0xc,%esp
f0100cc4:	68 90 2b 10 f0       	push   $0xf0102b90
f0100cc9:	e8 08 09 00 00       	call   f01015d6 <cprintf>
}
f0100cce:	eb 29                	jmp    f0100cf9 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cd0:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100cd5:	85 c0                	test   %eax,%eax
f0100cd7:	0f 85 8e fd ff ff    	jne    f0100a6b <check_page_free_list+0x2d>
f0100cdd:	e9 72 fd ff ff       	jmp    f0100a54 <check_page_free_list+0x16>
f0100ce2:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
f0100ce9:	0f 84 65 fd ff ff    	je     f0100a54 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cef:	be 00 04 00 00       	mov    $0x400,%esi
f0100cf4:	e9 c0 fd ff ff       	jmp    f0100ab9 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cf9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cfc:	5b                   	pop    %ebx
f0100cfd:	5e                   	pop    %esi
f0100cfe:	5f                   	pop    %edi
f0100cff:	5d                   	pop    %ebp
f0100d00:	c3                   	ret    

f0100d01 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d01:	55                   	push   %ebp
f0100d02:	89 e5                	mov    %esp,%ebp
f0100d04:	57                   	push   %edi
f0100d05:	56                   	push   %esi
f0100d06:	53                   	push   %ebx
f0100d07:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
f0100d0a:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d0f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages; i++) 
f0100d15:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100d1a:	be 08 00 00 00       	mov    $0x8,%esi
f0100d1f:	bf 01 00 00 00       	mov    $0x1,%edi
f0100d24:	e9 8f 00 00 00       	jmp    f0100db8 <page_init+0xb7>
	{
		if((i*PGSIZE >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM))
f0100d29:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100d2f:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100d34:	77 0e                	ja     f0100d44 <page_init+0x43>
		{
			pages[i].pp_ref = 1;
f0100d36:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d3b:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100d42:	eb 68                	jmp    f0100dac <page_init+0xab>
		}
		else if((i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))))
f0100d44:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100d4a:	76 3d                	jbe    f0100d89 <page_init+0x88>
f0100d4c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d51:	e8 5f fc ff ff       	call   f01009b5 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d56:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d5b:	77 15                	ja     f0100d72 <page_init+0x71>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d5d:	50                   	push   %eax
f0100d5e:	68 a8 2a 10 f0       	push   $0xf0102aa8
f0100d63:	68 15 01 00 00       	push   $0x115
f0100d68:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100d6d:	e8 19 f3 ff ff       	call   f010008b <_panic>
f0100d72:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d77:	39 d8                	cmp    %ebx,%eax
f0100d79:	76 0e                	jbe    f0100d89 <page_init+0x88>
		{
			pages[i].pp_ref = 1;
f0100d7b:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d80:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100d87:	eb 23                	jmp    f0100dac <page_init+0xab>
		}

		pages[i].pp_ref = 0;  
f0100d89:	89 f0                	mov    %esi,%eax
f0100d8b:	03 05 4c 49 11 f0    	add    0xf011494c,%eax
f0100d91:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d97:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100d9d:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100d9f:	89 f0                	mov    %esi,%eax
f0100da1:	03 05 4c 49 11 f0    	add    0xf011494c,%eax
f0100da7:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages; i++) 
f0100dac:	83 c7 01             	add    $0x1,%edi
f0100daf:	83 c6 08             	add    $0x8,%esi
f0100db2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100db8:	3b 3d 44 49 11 f0    	cmp    0xf0114944,%edi
f0100dbe:	0f 82 65 ff ff ff    	jb     f0100d29 <page_init+0x28>

		pages[i].pp_ref = 0;  
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100dc4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dc7:	5b                   	pop    %ebx
f0100dc8:	5e                   	pop    %esi
f0100dc9:	5f                   	pop    %edi
f0100dca:	5d                   	pop    %ebp
f0100dcb:	c3                   	ret    

f0100dcc <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dcc:	55                   	push   %ebp
f0100dcd:	89 e5                	mov    %esp,%ebp
f0100dcf:	53                   	push   %ebx
f0100dd0:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo* page;

	if(page_free_list != NULL)
f0100dd3:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100dd9:	85 db                	test   %ebx,%ebx
f0100ddb:	74 58                	je     f0100e35 <page_alloc+0x69>
	{
		page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100ddd:	8b 03                	mov    (%ebx),%eax
f0100ddf:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
		page->pp_link = NULL;
f0100de4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		
		if(alloc_flags & ALLOC_ZERO)
f0100dea:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dee:	74 45                	je     f0100e35 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100df0:	89 d8                	mov    %ebx,%eax
f0100df2:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100df8:	c1 f8 03             	sar    $0x3,%eax
f0100dfb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dfe:	89 c2                	mov    %eax,%edx
f0100e00:	c1 ea 0c             	shr    $0xc,%edx
f0100e03:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100e09:	72 12                	jb     f0100e1d <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e0b:	50                   	push   %eax
f0100e0c:	68 84 2a 10 f0       	push   $0xf0102a84
f0100e11:	6a 52                	push   $0x52
f0100e13:	68 e0 2c 10 f0       	push   $0xf0102ce0
f0100e18:	e8 6e f2 ff ff       	call   f010008b <_panic>
		{
			memset(page2kva(page), '\0', PGSIZE);
f0100e1d:	83 ec 04             	sub    $0x4,%esp
f0100e20:	68 00 10 00 00       	push   $0x1000
f0100e25:	6a 00                	push   $0x0
f0100e27:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e2c:	50                   	push   %eax
f0100e2d:	e8 5d 12 00 00       	call   f010208f <memset>
f0100e32:	83 c4 10             	add    $0x10,%esp

		return page;
	}

	return NULL;
}
f0100e35:	89 d8                	mov    %ebx,%eax
f0100e37:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e3a:	c9                   	leave  
f0100e3b:	c3                   	ret    

f0100e3c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e3c:	55                   	push   %ebp
f0100e3d:	89 e5                	mov    %esp,%ebp
f0100e3f:	83 ec 08             	sub    $0x8,%esp
f0100e42:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref != 0) || (pp->pp_link != NULL))
f0100e45:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e4a:	75 05                	jne    f0100e51 <page_free+0x15>
f0100e4c:	83 38 00             	cmpl   $0x0,(%eax)
f0100e4f:	74 17                	je     f0100e68 <page_free+0x2c>
	{
		panic("page_free: current page is still being referenced to or is referencing to other pages\n");
f0100e51:	83 ec 04             	sub    $0x4,%esp
f0100e54:	68 b4 2b 10 f0       	push   $0xf0102bb4
f0100e59:	68 4f 01 00 00       	push   $0x14f
f0100e5e:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100e63:	e8 23 f2 ff ff       	call   f010008b <_panic>
	}	

	pp->pp_link = page_free_list;
f0100e68:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100e6e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;	
f0100e70:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100e75:	c9                   	leave  
f0100e76:	c3                   	ret    

f0100e77 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e77:	55                   	push   %ebp
f0100e78:	89 e5                	mov    %esp,%ebp
f0100e7a:	83 ec 08             	sub    $0x8,%esp
f0100e7d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e80:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e84:	83 e8 01             	sub    $0x1,%eax
f0100e87:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e8b:	66 85 c0             	test   %ax,%ax
f0100e8e:	75 0c                	jne    f0100e9c <page_decref+0x25>
		page_free(pp);
f0100e90:	83 ec 0c             	sub    $0xc,%esp
f0100e93:	52                   	push   %edx
f0100e94:	e8 a3 ff ff ff       	call   f0100e3c <page_free>
f0100e99:	83 c4 10             	add    $0x10,%esp
}
f0100e9c:	c9                   	leave  
f0100e9d:	c3                   	ret    

f0100e9e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e9e:	55                   	push   %ebp
f0100e9f:	89 e5                	mov    %esp,%ebp
f0100ea1:	56                   	push   %esi
f0100ea2:	53                   	push   %ebx
f0100ea3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	size_t dirIndex = PDX(va);
	size_t tableIndex = PTX(va);
f0100ea6:	89 de                	mov    %ebx,%esi
f0100ea8:	c1 ee 0c             	shr    $0xc,%esi
f0100eab:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	
	pde_t *dirEntry = &pgdir[dirIndex];
f0100eb1:	c1 eb 16             	shr    $0x16,%ebx
f0100eb4:	c1 e3 02             	shl    $0x2,%ebx
f0100eb7:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *tableEntry = NULL;	

	if(!(*dirEntry & PTE_P))
f0100eba:	f6 03 01             	testb  $0x1,(%ebx)
f0100ebd:	75 2d                	jne    f0100eec <pgdir_walk+0x4e>
	{
		if(!create)
f0100ebf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ec3:	74 59                	je     f0100f1e <pgdir_walk+0x80>
		{
			return NULL;
		}

		struct PageInfo *pg = page_alloc(ALLOC_ZERO); // for page_alloc, zero the returned physical page
f0100ec5:	83 ec 0c             	sub    $0xc,%esp
f0100ec8:	6a 01                	push   $0x1
f0100eca:	e8 fd fe ff ff       	call   f0100dcc <page_alloc>
			
		if(pg == NULL)
f0100ecf:	83 c4 10             	add    $0x10,%esp
f0100ed2:	85 c0                	test   %eax,%eax
f0100ed4:	74 4f                	je     f0100f25 <pgdir_walk+0x87>
		{
			return NULL;
		}
			
		pg->pp_ref++;
f0100ed6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*dirEntry = page2pa(pg) | PTE_P | PTE_U | PTE_W;		
f0100edb:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100ee1:	c1 f8 03             	sar    $0x3,%eax
f0100ee4:	c1 e0 0c             	shl    $0xc,%eax
f0100ee7:	83 c8 07             	or     $0x7,%eax
f0100eea:	89 03                	mov    %eax,(%ebx)
	
	}
	
	tableEntry = (pte_t *) KADDR(PTE_ADDR(*dirEntry));
f0100eec:	8b 03                	mov    (%ebx),%eax
f0100eee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef3:	89 c2                	mov    %eax,%edx
f0100ef5:	c1 ea 0c             	shr    $0xc,%edx
f0100ef8:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100efe:	72 15                	jb     f0100f15 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f00:	50                   	push   %eax
f0100f01:	68 84 2a 10 f0       	push   $0xf0102a84
f0100f06:	68 95 01 00 00       	push   $0x195
f0100f0b:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100f10:	e8 76 f1 ff ff       	call   f010008b <_panic>
	return tableEntry + tableIndex;
f0100f15:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100f1c:	eb 0c                	jmp    f0100f2a <pgdir_walk+0x8c>

	if(!(*dirEntry & PTE_P))
	{
		if(!create)
		{
			return NULL;
f0100f1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f23:	eb 05                	jmp    f0100f2a <pgdir_walk+0x8c>

		struct PageInfo *pg = page_alloc(ALLOC_ZERO); // for page_alloc, zero the returned physical page
			
		if(pg == NULL)
		{
			return NULL;
f0100f25:	b8 00 00 00 00       	mov    $0x0,%eax
	
	}
	
	tableEntry = (pte_t *) KADDR(PTE_ADDR(*dirEntry));
	return tableEntry + tableIndex;
}
f0100f2a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f2d:	5b                   	pop    %ebx
f0100f2e:	5e                   	pop    %esi
f0100f2f:	5d                   	pop    %ebp
f0100f30:	c3                   	ret    

f0100f31 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f31:	55                   	push   %ebp
f0100f32:	89 e5                	mov    %esp,%ebp
f0100f34:	57                   	push   %edi
f0100f35:	56                   	push   %esi
f0100f36:	53                   	push   %ebx
f0100f37:	83 ec 1c             	sub    $0x1c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100f3a:	b8 15 00 00 00       	mov    $0x15,%eax
f0100f3f:	e8 e4 f9 ff ff       	call   f0100928 <nvram_read>
f0100f44:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100f46:	b8 17 00 00 00       	mov    $0x17,%eax
f0100f4b:	e8 d8 f9 ff ff       	call   f0100928 <nvram_read>
f0100f50:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100f52:	b8 34 00 00 00       	mov    $0x34,%eax
f0100f57:	e8 cc f9 ff ff       	call   f0100928 <nvram_read>
f0100f5c:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100f5f:	85 c0                	test   %eax,%eax
f0100f61:	74 07                	je     f0100f6a <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100f63:	05 00 40 00 00       	add    $0x4000,%eax
f0100f68:	eb 0b                	jmp    f0100f75 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100f6a:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100f70:	85 f6                	test   %esi,%esi
f0100f72:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100f75:	89 c2                	mov    %eax,%edx
f0100f77:	c1 ea 02             	shr    $0x2,%edx
f0100f7a:	89 15 44 49 11 f0    	mov    %edx,0xf0114944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f80:	89 c2                	mov    %eax,%edx
f0100f82:	29 da                	sub    %ebx,%edx
f0100f84:	52                   	push   %edx
f0100f85:	53                   	push   %ebx
f0100f86:	50                   	push   %eax
f0100f87:	68 0c 2c 10 f0       	push   $0xf0102c0c
f0100f8c:	e8 45 06 00 00       	call   f01015d6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100f91:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100f96:	e8 1a fa ff ff       	call   f01009b5 <boot_alloc>
f0100f9b:	a3 48 49 11 f0       	mov    %eax,0xf0114948
	memset(kern_pgdir, 0, PGSIZE);
f0100fa0:	83 c4 0c             	add    $0xc,%esp
f0100fa3:	68 00 10 00 00       	push   $0x1000
f0100fa8:	6a 00                	push   $0x0
f0100faa:	50                   	push   %eax
f0100fab:	e8 df 10 00 00       	call   f010208f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100fb0:	a1 48 49 11 f0       	mov    0xf0114948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fb5:	83 c4 10             	add    $0x10,%esp
f0100fb8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100fbd:	77 15                	ja     f0100fd4 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fbf:	50                   	push   %eax
f0100fc0:	68 a8 2a 10 f0       	push   $0xf0102aa8
f0100fc5:	68 9a 00 00 00       	push   $0x9a
f0100fca:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0100fcf:	e8 b7 f0 ff ff       	call   f010008b <_panic>
f0100fd4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100fda:	83 ca 05             	or     $0x5,%edx
f0100fdd:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0100fe3:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100fe8:	c1 e0 03             	shl    $0x3,%eax
f0100feb:	e8 c5 f9 ff ff       	call   f01009b5 <boot_alloc>
f0100ff0:	a3 4c 49 11 f0       	mov    %eax,0xf011494c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f0100ff5:	83 ec 04             	sub    $0x4,%esp
f0100ff8:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f0100ffe:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101005:	52                   	push   %edx
f0101006:	6a 00                	push   $0x0
f0101008:	50                   	push   %eax
f0101009:	e8 81 10 00 00       	call   f010208f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010100e:	e8 ee fc ff ff       	call   f0100d01 <page_init>

	check_page_free_list(1);
f0101013:	b8 01 00 00 00       	mov    $0x1,%eax
f0101018:	e8 21 fa ff ff       	call   f0100a3e <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010101d:	83 c4 10             	add    $0x10,%esp
f0101020:	83 3d 4c 49 11 f0 00 	cmpl   $0x0,0xf011494c
f0101027:	75 17                	jne    f0101040 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f0101029:	83 ec 04             	sub    $0x4,%esp
f010102c:	68 8a 2d 10 f0       	push   $0xf0102d8a
f0101031:	68 5d 02 00 00       	push   $0x25d
f0101036:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010103b:	e8 4b f0 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101040:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101045:	bb 00 00 00 00       	mov    $0x0,%ebx
f010104a:	eb 05                	jmp    f0101051 <mem_init+0x120>
		++nfree;
f010104c:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010104f:	8b 00                	mov    (%eax),%eax
f0101051:	85 c0                	test   %eax,%eax
f0101053:	75 f7                	jne    f010104c <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101055:	83 ec 0c             	sub    $0xc,%esp
f0101058:	6a 00                	push   $0x0
f010105a:	e8 6d fd ff ff       	call   f0100dcc <page_alloc>
f010105f:	89 c7                	mov    %eax,%edi
f0101061:	83 c4 10             	add    $0x10,%esp
f0101064:	85 c0                	test   %eax,%eax
f0101066:	75 19                	jne    f0101081 <mem_init+0x150>
f0101068:	68 a5 2d 10 f0       	push   $0xf0102da5
f010106d:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101072:	68 65 02 00 00       	push   $0x265
f0101077:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010107c:	e8 0a f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101081:	83 ec 0c             	sub    $0xc,%esp
f0101084:	6a 00                	push   $0x0
f0101086:	e8 41 fd ff ff       	call   f0100dcc <page_alloc>
f010108b:	89 c6                	mov    %eax,%esi
f010108d:	83 c4 10             	add    $0x10,%esp
f0101090:	85 c0                	test   %eax,%eax
f0101092:	75 19                	jne    f01010ad <mem_init+0x17c>
f0101094:	68 bb 2d 10 f0       	push   $0xf0102dbb
f0101099:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010109e:	68 66 02 00 00       	push   $0x266
f01010a3:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01010a8:	e8 de ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01010ad:	83 ec 0c             	sub    $0xc,%esp
f01010b0:	6a 00                	push   $0x0
f01010b2:	e8 15 fd ff ff       	call   f0100dcc <page_alloc>
f01010b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010ba:	83 c4 10             	add    $0x10,%esp
f01010bd:	85 c0                	test   %eax,%eax
f01010bf:	75 19                	jne    f01010da <mem_init+0x1a9>
f01010c1:	68 d1 2d 10 f0       	push   $0xf0102dd1
f01010c6:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01010cb:	68 67 02 00 00       	push   $0x267
f01010d0:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01010d5:	e8 b1 ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010da:	39 f7                	cmp    %esi,%edi
f01010dc:	75 19                	jne    f01010f7 <mem_init+0x1c6>
f01010de:	68 e7 2d 10 f0       	push   $0xf0102de7
f01010e3:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01010e8:	68 6a 02 00 00       	push   $0x26a
f01010ed:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01010f2:	e8 94 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01010f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010fa:	39 c7                	cmp    %eax,%edi
f01010fc:	74 04                	je     f0101102 <mem_init+0x1d1>
f01010fe:	39 c6                	cmp    %eax,%esi
f0101100:	75 19                	jne    f010111b <mem_init+0x1ea>
f0101102:	68 48 2c 10 f0       	push   $0xf0102c48
f0101107:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010110c:	68 6b 02 00 00       	push   $0x26b
f0101111:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101116:	e8 70 ef ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010111b:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101121:	8b 15 44 49 11 f0    	mov    0xf0114944,%edx
f0101127:	c1 e2 0c             	shl    $0xc,%edx
f010112a:	89 f8                	mov    %edi,%eax
f010112c:	29 c8                	sub    %ecx,%eax
f010112e:	c1 f8 03             	sar    $0x3,%eax
f0101131:	c1 e0 0c             	shl    $0xc,%eax
f0101134:	39 d0                	cmp    %edx,%eax
f0101136:	72 19                	jb     f0101151 <mem_init+0x220>
f0101138:	68 f9 2d 10 f0       	push   $0xf0102df9
f010113d:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101142:	68 6c 02 00 00       	push   $0x26c
f0101147:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010114c:	e8 3a ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101151:	89 f0                	mov    %esi,%eax
f0101153:	29 c8                	sub    %ecx,%eax
f0101155:	c1 f8 03             	sar    $0x3,%eax
f0101158:	c1 e0 0c             	shl    $0xc,%eax
f010115b:	39 c2                	cmp    %eax,%edx
f010115d:	77 19                	ja     f0101178 <mem_init+0x247>
f010115f:	68 16 2e 10 f0       	push   $0xf0102e16
f0101164:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101169:	68 6d 02 00 00       	push   $0x26d
f010116e:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101173:	e8 13 ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101178:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010117b:	29 c8                	sub    %ecx,%eax
f010117d:	c1 f8 03             	sar    $0x3,%eax
f0101180:	c1 e0 0c             	shl    $0xc,%eax
f0101183:	39 c2                	cmp    %eax,%edx
f0101185:	77 19                	ja     f01011a0 <mem_init+0x26f>
f0101187:	68 33 2e 10 f0       	push   $0xf0102e33
f010118c:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101191:	68 6e 02 00 00       	push   $0x26e
f0101196:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010119b:	e8 eb ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01011a0:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01011a5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01011a8:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01011af:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01011b2:	83 ec 0c             	sub    $0xc,%esp
f01011b5:	6a 00                	push   $0x0
f01011b7:	e8 10 fc ff ff       	call   f0100dcc <page_alloc>
f01011bc:	83 c4 10             	add    $0x10,%esp
f01011bf:	85 c0                	test   %eax,%eax
f01011c1:	74 19                	je     f01011dc <mem_init+0x2ab>
f01011c3:	68 50 2e 10 f0       	push   $0xf0102e50
f01011c8:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01011cd:	68 75 02 00 00       	push   $0x275
f01011d2:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01011d7:	e8 af ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01011dc:	83 ec 0c             	sub    $0xc,%esp
f01011df:	57                   	push   %edi
f01011e0:	e8 57 fc ff ff       	call   f0100e3c <page_free>
	page_free(pp1);
f01011e5:	89 34 24             	mov    %esi,(%esp)
f01011e8:	e8 4f fc ff ff       	call   f0100e3c <page_free>
	page_free(pp2);
f01011ed:	83 c4 04             	add    $0x4,%esp
f01011f0:	ff 75 e4             	pushl  -0x1c(%ebp)
f01011f3:	e8 44 fc ff ff       	call   f0100e3c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01011ff:	e8 c8 fb ff ff       	call   f0100dcc <page_alloc>
f0101204:	89 c6                	mov    %eax,%esi
f0101206:	83 c4 10             	add    $0x10,%esp
f0101209:	85 c0                	test   %eax,%eax
f010120b:	75 19                	jne    f0101226 <mem_init+0x2f5>
f010120d:	68 a5 2d 10 f0       	push   $0xf0102da5
f0101212:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101217:	68 7c 02 00 00       	push   $0x27c
f010121c:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101221:	e8 65 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101226:	83 ec 0c             	sub    $0xc,%esp
f0101229:	6a 00                	push   $0x0
f010122b:	e8 9c fb ff ff       	call   f0100dcc <page_alloc>
f0101230:	89 c7                	mov    %eax,%edi
f0101232:	83 c4 10             	add    $0x10,%esp
f0101235:	85 c0                	test   %eax,%eax
f0101237:	75 19                	jne    f0101252 <mem_init+0x321>
f0101239:	68 bb 2d 10 f0       	push   $0xf0102dbb
f010123e:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101243:	68 7d 02 00 00       	push   $0x27d
f0101248:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010124d:	e8 39 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101252:	83 ec 0c             	sub    $0xc,%esp
f0101255:	6a 00                	push   $0x0
f0101257:	e8 70 fb ff ff       	call   f0100dcc <page_alloc>
f010125c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010125f:	83 c4 10             	add    $0x10,%esp
f0101262:	85 c0                	test   %eax,%eax
f0101264:	75 19                	jne    f010127f <mem_init+0x34e>
f0101266:	68 d1 2d 10 f0       	push   $0xf0102dd1
f010126b:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101270:	68 7e 02 00 00       	push   $0x27e
f0101275:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010127a:	e8 0c ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010127f:	39 fe                	cmp    %edi,%esi
f0101281:	75 19                	jne    f010129c <mem_init+0x36b>
f0101283:	68 e7 2d 10 f0       	push   $0xf0102de7
f0101288:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010128d:	68 80 02 00 00       	push   $0x280
f0101292:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101297:	e8 ef ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010129c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010129f:	39 c6                	cmp    %eax,%esi
f01012a1:	74 04                	je     f01012a7 <mem_init+0x376>
f01012a3:	39 c7                	cmp    %eax,%edi
f01012a5:	75 19                	jne    f01012c0 <mem_init+0x38f>
f01012a7:	68 48 2c 10 f0       	push   $0xf0102c48
f01012ac:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01012b1:	68 81 02 00 00       	push   $0x281
f01012b6:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01012bb:	e8 cb ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01012c0:	83 ec 0c             	sub    $0xc,%esp
f01012c3:	6a 00                	push   $0x0
f01012c5:	e8 02 fb ff ff       	call   f0100dcc <page_alloc>
f01012ca:	83 c4 10             	add    $0x10,%esp
f01012cd:	85 c0                	test   %eax,%eax
f01012cf:	74 19                	je     f01012ea <mem_init+0x3b9>
f01012d1:	68 50 2e 10 f0       	push   $0xf0102e50
f01012d6:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01012db:	68 82 02 00 00       	push   $0x282
f01012e0:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01012e5:	e8 a1 ed ff ff       	call   f010008b <_panic>
f01012ea:	89 f0                	mov    %esi,%eax
f01012ec:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f01012f2:	c1 f8 03             	sar    $0x3,%eax
f01012f5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012f8:	89 c2                	mov    %eax,%edx
f01012fa:	c1 ea 0c             	shr    $0xc,%edx
f01012fd:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0101303:	72 12                	jb     f0101317 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101305:	50                   	push   %eax
f0101306:	68 84 2a 10 f0       	push   $0xf0102a84
f010130b:	6a 52                	push   $0x52
f010130d:	68 e0 2c 10 f0       	push   $0xf0102ce0
f0101312:	e8 74 ed ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101317:	83 ec 04             	sub    $0x4,%esp
f010131a:	68 00 10 00 00       	push   $0x1000
f010131f:	6a 01                	push   $0x1
f0101321:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101326:	50                   	push   %eax
f0101327:	e8 63 0d 00 00       	call   f010208f <memset>
	page_free(pp0);
f010132c:	89 34 24             	mov    %esi,(%esp)
f010132f:	e8 08 fb ff ff       	call   f0100e3c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101334:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010133b:	e8 8c fa ff ff       	call   f0100dcc <page_alloc>
f0101340:	83 c4 10             	add    $0x10,%esp
f0101343:	85 c0                	test   %eax,%eax
f0101345:	75 19                	jne    f0101360 <mem_init+0x42f>
f0101347:	68 5f 2e 10 f0       	push   $0xf0102e5f
f010134c:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101351:	68 87 02 00 00       	push   $0x287
f0101356:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010135b:	e8 2b ed ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101360:	39 c6                	cmp    %eax,%esi
f0101362:	74 19                	je     f010137d <mem_init+0x44c>
f0101364:	68 7d 2e 10 f0       	push   $0xf0102e7d
f0101369:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010136e:	68 88 02 00 00       	push   $0x288
f0101373:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101378:	e8 0e ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010137d:	89 f0                	mov    %esi,%eax
f010137f:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0101385:	c1 f8 03             	sar    $0x3,%eax
f0101388:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010138b:	89 c2                	mov    %eax,%edx
f010138d:	c1 ea 0c             	shr    $0xc,%edx
f0101390:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0101396:	72 12                	jb     f01013aa <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101398:	50                   	push   %eax
f0101399:	68 84 2a 10 f0       	push   $0xf0102a84
f010139e:	6a 52                	push   $0x52
f01013a0:	68 e0 2c 10 f0       	push   $0xf0102ce0
f01013a5:	e8 e1 ec ff ff       	call   f010008b <_panic>
f01013aa:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01013b0:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013b6:	80 38 00             	cmpb   $0x0,(%eax)
f01013b9:	74 19                	je     f01013d4 <mem_init+0x4a3>
f01013bb:	68 8d 2e 10 f0       	push   $0xf0102e8d
f01013c0:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01013c5:	68 8b 02 00 00       	push   $0x28b
f01013ca:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01013cf:	e8 b7 ec ff ff       	call   f010008b <_panic>
f01013d4:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01013d7:	39 d0                	cmp    %edx,%eax
f01013d9:	75 db                	jne    f01013b6 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01013db:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013de:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f01013e3:	83 ec 0c             	sub    $0xc,%esp
f01013e6:	56                   	push   %esi
f01013e7:	e8 50 fa ff ff       	call   f0100e3c <page_free>
	page_free(pp1);
f01013ec:	89 3c 24             	mov    %edi,(%esp)
f01013ef:	e8 48 fa ff ff       	call   f0100e3c <page_free>
	page_free(pp2);
f01013f4:	83 c4 04             	add    $0x4,%esp
f01013f7:	ff 75 e4             	pushl  -0x1c(%ebp)
f01013fa:	e8 3d fa ff ff       	call   f0100e3c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01013ff:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101404:	83 c4 10             	add    $0x10,%esp
f0101407:	eb 05                	jmp    f010140e <mem_init+0x4dd>
		--nfree;
f0101409:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010140c:	8b 00                	mov    (%eax),%eax
f010140e:	85 c0                	test   %eax,%eax
f0101410:	75 f7                	jne    f0101409 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101412:	85 db                	test   %ebx,%ebx
f0101414:	74 19                	je     f010142f <mem_init+0x4fe>
f0101416:	68 97 2e 10 f0       	push   $0xf0102e97
f010141b:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101420:	68 98 02 00 00       	push   $0x298
f0101425:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010142a:	e8 5c ec ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010142f:	83 ec 0c             	sub    $0xc,%esp
f0101432:	68 68 2c 10 f0       	push   $0xf0102c68
f0101437:	e8 9a 01 00 00       	call   f01015d6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010143c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101443:	e8 84 f9 ff ff       	call   f0100dcc <page_alloc>
f0101448:	89 c3                	mov    %eax,%ebx
f010144a:	83 c4 10             	add    $0x10,%esp
f010144d:	85 c0                	test   %eax,%eax
f010144f:	75 19                	jne    f010146a <mem_init+0x539>
f0101451:	68 a5 2d 10 f0       	push   $0xf0102da5
f0101456:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010145b:	68 f1 02 00 00       	push   $0x2f1
f0101460:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101465:	e8 21 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010146a:	83 ec 0c             	sub    $0xc,%esp
f010146d:	6a 00                	push   $0x0
f010146f:	e8 58 f9 ff ff       	call   f0100dcc <page_alloc>
f0101474:	89 c6                	mov    %eax,%esi
f0101476:	83 c4 10             	add    $0x10,%esp
f0101479:	85 c0                	test   %eax,%eax
f010147b:	75 19                	jne    f0101496 <mem_init+0x565>
f010147d:	68 bb 2d 10 f0       	push   $0xf0102dbb
f0101482:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101487:	68 f2 02 00 00       	push   $0x2f2
f010148c:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101491:	e8 f5 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101496:	83 ec 0c             	sub    $0xc,%esp
f0101499:	6a 00                	push   $0x0
f010149b:	e8 2c f9 ff ff       	call   f0100dcc <page_alloc>
f01014a0:	83 c4 10             	add    $0x10,%esp
f01014a3:	85 c0                	test   %eax,%eax
f01014a5:	75 19                	jne    f01014c0 <mem_init+0x58f>
f01014a7:	68 d1 2d 10 f0       	push   $0xf0102dd1
f01014ac:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01014b1:	68 f3 02 00 00       	push   $0x2f3
f01014b6:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01014bb:	e8 cb eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014c0:	39 f3                	cmp    %esi,%ebx
f01014c2:	75 19                	jne    f01014dd <mem_init+0x5ac>
f01014c4:	68 e7 2d 10 f0       	push   $0xf0102de7
f01014c9:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01014ce:	68 f6 02 00 00       	push   $0x2f6
f01014d3:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01014d8:	e8 ae eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014dd:	39 c6                	cmp    %eax,%esi
f01014df:	74 04                	je     f01014e5 <mem_init+0x5b4>
f01014e1:	39 c3                	cmp    %eax,%ebx
f01014e3:	75 19                	jne    f01014fe <mem_init+0x5cd>
f01014e5:	68 48 2c 10 f0       	push   $0xf0102c48
f01014ea:	68 fa 2c 10 f0       	push   $0xf0102cfa
f01014ef:	68 f7 02 00 00       	push   $0x2f7
f01014f4:	68 b8 2c 10 f0       	push   $0xf0102cb8
f01014f9:	e8 8d eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f01014fe:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0101505:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101508:	83 ec 0c             	sub    $0xc,%esp
f010150b:	6a 00                	push   $0x0
f010150d:	e8 ba f8 ff ff       	call   f0100dcc <page_alloc>
f0101512:	83 c4 10             	add    $0x10,%esp
f0101515:	85 c0                	test   %eax,%eax
f0101517:	74 19                	je     f0101532 <mem_init+0x601>
f0101519:	68 50 2e 10 f0       	push   $0xf0102e50
f010151e:	68 fa 2c 10 f0       	push   $0xf0102cfa
f0101523:	68 fe 02 00 00       	push   $0x2fe
f0101528:	68 b8 2c 10 f0       	push   $0xf0102cb8
f010152d:	e8 59 eb ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101532:	68 88 2c 10 f0       	push   $0xf0102c88
f0101537:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010153c:	68 04 03 00 00       	push   $0x304
f0101541:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101546:	e8 40 eb ff ff       	call   f010008b <_panic>

f010154b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010154b:	55                   	push   %ebp
f010154c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f010154e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101553:	5d                   	pop    %ebp
f0101554:	c3                   	ret    

f0101555 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101555:	55                   	push   %ebp
f0101556:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101558:	b8 00 00 00 00       	mov    $0x0,%eax
f010155d:	5d                   	pop    %ebp
f010155e:	c3                   	ret    

f010155f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010155f:	55                   	push   %ebp
f0101560:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0101562:	5d                   	pop    %ebp
f0101563:	c3                   	ret    

f0101564 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101567:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010156d:	5d                   	pop    %ebp
f010156e:	c3                   	ret    

f010156f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010156f:	55                   	push   %ebp
f0101570:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101572:	ba 70 00 00 00       	mov    $0x70,%edx
f0101577:	8b 45 08             	mov    0x8(%ebp),%eax
f010157a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010157b:	ba 71 00 00 00       	mov    $0x71,%edx
f0101580:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0101581:	0f b6 c0             	movzbl %al,%eax
}
f0101584:	5d                   	pop    %ebp
f0101585:	c3                   	ret    

f0101586 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101586:	55                   	push   %ebp
f0101587:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101589:	ba 70 00 00 00       	mov    $0x70,%edx
f010158e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101591:	ee                   	out    %al,(%dx)
f0101592:	ba 71 00 00 00       	mov    $0x71,%edx
f0101597:	8b 45 0c             	mov    0xc(%ebp),%eax
f010159a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010159b:	5d                   	pop    %ebp
f010159c:	c3                   	ret    

f010159d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010159d:	55                   	push   %ebp
f010159e:	89 e5                	mov    %esp,%ebp
f01015a0:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01015a3:	ff 75 08             	pushl  0x8(%ebp)
f01015a6:	e8 55 f0 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01015ab:	83 c4 10             	add    $0x10,%esp
f01015ae:	c9                   	leave  
f01015af:	c3                   	ret    

f01015b0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01015b0:	55                   	push   %ebp
f01015b1:	89 e5                	mov    %esp,%ebp
f01015b3:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01015b6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01015bd:	ff 75 0c             	pushl  0xc(%ebp)
f01015c0:	ff 75 08             	pushl  0x8(%ebp)
f01015c3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01015c6:	50                   	push   %eax
f01015c7:	68 9d 15 10 f0       	push   $0xf010159d
f01015cc:	e8 52 04 00 00       	call   f0101a23 <vprintfmt>
	return cnt;
}
f01015d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015d4:	c9                   	leave  
f01015d5:	c3                   	ret    

f01015d6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01015d6:	55                   	push   %ebp
f01015d7:	89 e5                	mov    %esp,%ebp
f01015d9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01015dc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01015df:	50                   	push   %eax
f01015e0:	ff 75 08             	pushl  0x8(%ebp)
f01015e3:	e8 c8 ff ff ff       	call   f01015b0 <vcprintf>
	va_end(ap);

	return cnt;
}
f01015e8:	c9                   	leave  
f01015e9:	c3                   	ret    

f01015ea <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01015ea:	55                   	push   %ebp
f01015eb:	89 e5                	mov    %esp,%ebp
f01015ed:	57                   	push   %edi
f01015ee:	56                   	push   %esi
f01015ef:	53                   	push   %ebx
f01015f0:	83 ec 14             	sub    $0x14,%esp
f01015f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01015f6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01015f9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01015fc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01015ff:	8b 1a                	mov    (%edx),%ebx
f0101601:	8b 01                	mov    (%ecx),%eax
f0101603:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101606:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010160d:	eb 7f                	jmp    f010168e <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010160f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101612:	01 d8                	add    %ebx,%eax
f0101614:	89 c6                	mov    %eax,%esi
f0101616:	c1 ee 1f             	shr    $0x1f,%esi
f0101619:	01 c6                	add    %eax,%esi
f010161b:	d1 fe                	sar    %esi
f010161d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101620:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101623:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101626:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101628:	eb 03                	jmp    f010162d <stab_binsearch+0x43>
			m--;
f010162a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010162d:	39 c3                	cmp    %eax,%ebx
f010162f:	7f 0d                	jg     f010163e <stab_binsearch+0x54>
f0101631:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101635:	83 ea 0c             	sub    $0xc,%edx
f0101638:	39 f9                	cmp    %edi,%ecx
f010163a:	75 ee                	jne    f010162a <stab_binsearch+0x40>
f010163c:	eb 05                	jmp    f0101643 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010163e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0101641:	eb 4b                	jmp    f010168e <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101643:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101646:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101649:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010164d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101650:	76 11                	jbe    f0101663 <stab_binsearch+0x79>
			*region_left = m;
f0101652:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101655:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0101657:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010165a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101661:	eb 2b                	jmp    f010168e <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101663:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101666:	73 14                	jae    f010167c <stab_binsearch+0x92>
			*region_right = m - 1;
f0101668:	83 e8 01             	sub    $0x1,%eax
f010166b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010166e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101671:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101673:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010167a:	eb 12                	jmp    f010168e <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010167c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010167f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101681:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101685:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101687:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010168e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0101691:	0f 8e 78 ff ff ff    	jle    f010160f <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101697:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010169b:	75 0f                	jne    f01016ac <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010169d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016a0:	8b 00                	mov    (%eax),%eax
f01016a2:	83 e8 01             	sub    $0x1,%eax
f01016a5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01016a8:	89 06                	mov    %eax,(%esi)
f01016aa:	eb 2c                	jmp    f01016d8 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01016ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016af:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01016b1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01016b4:	8b 0e                	mov    (%esi),%ecx
f01016b6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01016b9:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01016bc:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01016bf:	eb 03                	jmp    f01016c4 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01016c1:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01016c4:	39 c8                	cmp    %ecx,%eax
f01016c6:	7e 0b                	jle    f01016d3 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01016c8:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01016cc:	83 ea 0c             	sub    $0xc,%edx
f01016cf:	39 df                	cmp    %ebx,%edi
f01016d1:	75 ee                	jne    f01016c1 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01016d3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01016d6:	89 06                	mov    %eax,(%esi)
	}
}
f01016d8:	83 c4 14             	add    $0x14,%esp
f01016db:	5b                   	pop    %ebx
f01016dc:	5e                   	pop    %esi
f01016dd:	5f                   	pop    %edi
f01016de:	5d                   	pop    %ebp
f01016df:	c3                   	ret    

f01016e0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01016e0:	55                   	push   %ebp
f01016e1:	89 e5                	mov    %esp,%ebp
f01016e3:	57                   	push   %edi
f01016e4:	56                   	push   %esi
f01016e5:	53                   	push   %ebx
f01016e6:	83 ec 3c             	sub    $0x3c,%esp
f01016e9:	8b 75 08             	mov    0x8(%ebp),%esi
f01016ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01016ef:	c7 03 a2 2e 10 f0    	movl   $0xf0102ea2,(%ebx)
	info->eip_line = 0;
f01016f5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01016fc:	c7 43 08 a2 2e 10 f0 	movl   $0xf0102ea2,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101703:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010170a:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010170d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101714:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010171a:	76 11                	jbe    f010172d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010171c:	b8 87 9b 10 f0       	mov    $0xf0109b87,%eax
f0101721:	3d 31 7e 10 f0       	cmp    $0xf0107e31,%eax
f0101726:	77 19                	ja     f0101741 <debuginfo_eip+0x61>
f0101728:	e9 aa 01 00 00       	jmp    f01018d7 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010172d:	83 ec 04             	sub    $0x4,%esp
f0101730:	68 ac 2e 10 f0       	push   $0xf0102eac
f0101735:	6a 7f                	push   $0x7f
f0101737:	68 b9 2e 10 f0       	push   $0xf0102eb9
f010173c:	e8 4a e9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101741:	80 3d 86 9b 10 f0 00 	cmpb   $0x0,0xf0109b86
f0101748:	0f 85 90 01 00 00    	jne    f01018de <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010174e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101755:	b8 30 7e 10 f0       	mov    $0xf0107e30,%eax
f010175a:	2d d8 30 10 f0       	sub    $0xf01030d8,%eax
f010175f:	c1 f8 02             	sar    $0x2,%eax
f0101762:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101768:	83 e8 01             	sub    $0x1,%eax
f010176b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010176e:	83 ec 08             	sub    $0x8,%esp
f0101771:	56                   	push   %esi
f0101772:	6a 64                	push   $0x64
f0101774:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101777:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010177a:	b8 d8 30 10 f0       	mov    $0xf01030d8,%eax
f010177f:	e8 66 fe ff ff       	call   f01015ea <stab_binsearch>
	if (lfile == 0)
f0101784:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101787:	83 c4 10             	add    $0x10,%esp
f010178a:	85 c0                	test   %eax,%eax
f010178c:	0f 84 53 01 00 00    	je     f01018e5 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101792:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101795:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101798:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010179b:	83 ec 08             	sub    $0x8,%esp
f010179e:	56                   	push   %esi
f010179f:	6a 24                	push   $0x24
f01017a1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01017a4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01017a7:	b8 d8 30 10 f0       	mov    $0xf01030d8,%eax
f01017ac:	e8 39 fe ff ff       	call   f01015ea <stab_binsearch>

	if (lfun <= rfun) {
f01017b1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01017b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01017b7:	83 c4 10             	add    $0x10,%esp
f01017ba:	39 d0                	cmp    %edx,%eax
f01017bc:	7f 40                	jg     f01017fe <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01017be:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01017c1:	c1 e1 02             	shl    $0x2,%ecx
f01017c4:	8d b9 d8 30 10 f0    	lea    -0xfefcf28(%ecx),%edi
f01017ca:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01017cd:	8b b9 d8 30 10 f0    	mov    -0xfefcf28(%ecx),%edi
f01017d3:	b9 87 9b 10 f0       	mov    $0xf0109b87,%ecx
f01017d8:	81 e9 31 7e 10 f0    	sub    $0xf0107e31,%ecx
f01017de:	39 cf                	cmp    %ecx,%edi
f01017e0:	73 09                	jae    f01017eb <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01017e2:	81 c7 31 7e 10 f0    	add    $0xf0107e31,%edi
f01017e8:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01017eb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01017ee:	8b 4f 08             	mov    0x8(%edi),%ecx
f01017f1:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01017f4:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01017f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01017f9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01017fc:	eb 0f                	jmp    f010180d <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01017fe:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101801:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101804:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101807:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010180a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010180d:	83 ec 08             	sub    $0x8,%esp
f0101810:	6a 3a                	push   $0x3a
f0101812:	ff 73 08             	pushl  0x8(%ebx)
f0101815:	e8 59 08 00 00       	call   f0102073 <strfind>
f010181a:	2b 43 08             	sub    0x8(%ebx),%eax
f010181d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101820:	83 c4 08             	add    $0x8,%esp
f0101823:	56                   	push   %esi
f0101824:	6a 44                	push   $0x44
f0101826:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101829:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010182c:	b8 d8 30 10 f0       	mov    $0xf01030d8,%eax
f0101831:	e8 b4 fd ff ff       	call   f01015ea <stab_binsearch>
	
	if(lline > rline)
f0101836:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101839:	83 c4 10             	add    $0x10,%esp
f010183c:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010183f:	0f 8f a7 00 00 00    	jg     f01018ec <debuginfo_eip+0x20c>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f0101845:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0101848:	8d 04 85 d8 30 10 f0 	lea    -0xfefcf28(,%eax,4),%eax
f010184f:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0101853:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101856:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101859:	eb 06                	jmp    f0101861 <debuginfo_eip+0x181>
f010185b:	83 ea 01             	sub    $0x1,%edx
f010185e:	83 e8 0c             	sub    $0xc,%eax
f0101861:	39 d6                	cmp    %edx,%esi
f0101863:	7f 34                	jg     f0101899 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0101865:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0101869:	80 f9 84             	cmp    $0x84,%cl
f010186c:	74 0b                	je     f0101879 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010186e:	80 f9 64             	cmp    $0x64,%cl
f0101871:	75 e8                	jne    f010185b <debuginfo_eip+0x17b>
f0101873:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0101877:	74 e2                	je     f010185b <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101879:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010187c:	8b 14 85 d8 30 10 f0 	mov    -0xfefcf28(,%eax,4),%edx
f0101883:	b8 87 9b 10 f0       	mov    $0xf0109b87,%eax
f0101888:	2d 31 7e 10 f0       	sub    $0xf0107e31,%eax
f010188d:	39 c2                	cmp    %eax,%edx
f010188f:	73 08                	jae    f0101899 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101891:	81 c2 31 7e 10 f0    	add    $0xf0107e31,%edx
f0101897:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101899:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010189c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010189f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01018a4:	39 f2                	cmp    %esi,%edx
f01018a6:	7d 50                	jge    f01018f8 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f01018a8:	83 c2 01             	add    $0x1,%edx
f01018ab:	89 d0                	mov    %edx,%eax
f01018ad:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01018b0:	8d 14 95 d8 30 10 f0 	lea    -0xfefcf28(,%edx,4),%edx
f01018b7:	eb 04                	jmp    f01018bd <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01018b9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01018bd:	39 c6                	cmp    %eax,%esi
f01018bf:	7e 32                	jle    f01018f3 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01018c1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01018c5:	83 c0 01             	add    $0x1,%eax
f01018c8:	83 c2 0c             	add    $0xc,%edx
f01018cb:	80 f9 a0             	cmp    $0xa0,%cl
f01018ce:	74 e9                	je     f01018b9 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01018d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01018d5:	eb 21                	jmp    f01018f8 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01018d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01018dc:	eb 1a                	jmp    f01018f8 <debuginfo_eip+0x218>
f01018de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01018e3:	eb 13                	jmp    f01018f8 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01018e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01018ea:	eb 0c                	jmp    f01018f8 <debuginfo_eip+0x218>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f01018ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01018f1:	eb 05                	jmp    f01018f8 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01018f3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01018f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01018fb:	5b                   	pop    %ebx
f01018fc:	5e                   	pop    %esi
f01018fd:	5f                   	pop    %edi
f01018fe:	5d                   	pop    %ebp
f01018ff:	c3                   	ret    

f0101900 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101900:	55                   	push   %ebp
f0101901:	89 e5                	mov    %esp,%ebp
f0101903:	57                   	push   %edi
f0101904:	56                   	push   %esi
f0101905:	53                   	push   %ebx
f0101906:	83 ec 1c             	sub    $0x1c,%esp
f0101909:	89 c7                	mov    %eax,%edi
f010190b:	89 d6                	mov    %edx,%esi
f010190d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101910:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101913:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101916:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101919:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010191c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101921:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101924:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101927:	39 d3                	cmp    %edx,%ebx
f0101929:	72 05                	jb     f0101930 <printnum+0x30>
f010192b:	39 45 10             	cmp    %eax,0x10(%ebp)
f010192e:	77 45                	ja     f0101975 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101930:	83 ec 0c             	sub    $0xc,%esp
f0101933:	ff 75 18             	pushl  0x18(%ebp)
f0101936:	8b 45 14             	mov    0x14(%ebp),%eax
f0101939:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010193c:	53                   	push   %ebx
f010193d:	ff 75 10             	pushl  0x10(%ebp)
f0101940:	83 ec 08             	sub    $0x8,%esp
f0101943:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101946:	ff 75 e0             	pushl  -0x20(%ebp)
f0101949:	ff 75 dc             	pushl  -0x24(%ebp)
f010194c:	ff 75 d8             	pushl  -0x28(%ebp)
f010194f:	e8 4c 09 00 00       	call   f01022a0 <__udivdi3>
f0101954:	83 c4 18             	add    $0x18,%esp
f0101957:	52                   	push   %edx
f0101958:	50                   	push   %eax
f0101959:	89 f2                	mov    %esi,%edx
f010195b:	89 f8                	mov    %edi,%eax
f010195d:	e8 9e ff ff ff       	call   f0101900 <printnum>
f0101962:	83 c4 20             	add    $0x20,%esp
f0101965:	eb 18                	jmp    f010197f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101967:	83 ec 08             	sub    $0x8,%esp
f010196a:	56                   	push   %esi
f010196b:	ff 75 18             	pushl  0x18(%ebp)
f010196e:	ff d7                	call   *%edi
f0101970:	83 c4 10             	add    $0x10,%esp
f0101973:	eb 03                	jmp    f0101978 <printnum+0x78>
f0101975:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101978:	83 eb 01             	sub    $0x1,%ebx
f010197b:	85 db                	test   %ebx,%ebx
f010197d:	7f e8                	jg     f0101967 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010197f:	83 ec 08             	sub    $0x8,%esp
f0101982:	56                   	push   %esi
f0101983:	83 ec 04             	sub    $0x4,%esp
f0101986:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101989:	ff 75 e0             	pushl  -0x20(%ebp)
f010198c:	ff 75 dc             	pushl  -0x24(%ebp)
f010198f:	ff 75 d8             	pushl  -0x28(%ebp)
f0101992:	e8 39 0a 00 00       	call   f01023d0 <__umoddi3>
f0101997:	83 c4 14             	add    $0x14,%esp
f010199a:	0f be 80 c7 2e 10 f0 	movsbl -0xfefd139(%eax),%eax
f01019a1:	50                   	push   %eax
f01019a2:	ff d7                	call   *%edi
}
f01019a4:	83 c4 10             	add    $0x10,%esp
f01019a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01019aa:	5b                   	pop    %ebx
f01019ab:	5e                   	pop    %esi
f01019ac:	5f                   	pop    %edi
f01019ad:	5d                   	pop    %ebp
f01019ae:	c3                   	ret    

f01019af <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01019af:	55                   	push   %ebp
f01019b0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01019b2:	83 fa 01             	cmp    $0x1,%edx
f01019b5:	7e 0e                	jle    f01019c5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01019b7:	8b 10                	mov    (%eax),%edx
f01019b9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01019bc:	89 08                	mov    %ecx,(%eax)
f01019be:	8b 02                	mov    (%edx),%eax
f01019c0:	8b 52 04             	mov    0x4(%edx),%edx
f01019c3:	eb 22                	jmp    f01019e7 <getuint+0x38>
	else if (lflag)
f01019c5:	85 d2                	test   %edx,%edx
f01019c7:	74 10                	je     f01019d9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01019c9:	8b 10                	mov    (%eax),%edx
f01019cb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01019ce:	89 08                	mov    %ecx,(%eax)
f01019d0:	8b 02                	mov    (%edx),%eax
f01019d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01019d7:	eb 0e                	jmp    f01019e7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01019d9:	8b 10                	mov    (%eax),%edx
f01019db:	8d 4a 04             	lea    0x4(%edx),%ecx
f01019de:	89 08                	mov    %ecx,(%eax)
f01019e0:	8b 02                	mov    (%edx),%eax
f01019e2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01019e7:	5d                   	pop    %ebp
f01019e8:	c3                   	ret    

f01019e9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01019e9:	55                   	push   %ebp
f01019ea:	89 e5                	mov    %esp,%ebp
f01019ec:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01019ef:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01019f3:	8b 10                	mov    (%eax),%edx
f01019f5:	3b 50 04             	cmp    0x4(%eax),%edx
f01019f8:	73 0a                	jae    f0101a04 <sprintputch+0x1b>
		*b->buf++ = ch;
f01019fa:	8d 4a 01             	lea    0x1(%edx),%ecx
f01019fd:	89 08                	mov    %ecx,(%eax)
f01019ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a02:	88 02                	mov    %al,(%edx)
}
f0101a04:	5d                   	pop    %ebp
f0101a05:	c3                   	ret    

f0101a06 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101a06:	55                   	push   %ebp
f0101a07:	89 e5                	mov    %esp,%ebp
f0101a09:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101a0c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101a0f:	50                   	push   %eax
f0101a10:	ff 75 10             	pushl  0x10(%ebp)
f0101a13:	ff 75 0c             	pushl  0xc(%ebp)
f0101a16:	ff 75 08             	pushl  0x8(%ebp)
f0101a19:	e8 05 00 00 00       	call   f0101a23 <vprintfmt>
	va_end(ap);
}
f0101a1e:	83 c4 10             	add    $0x10,%esp
f0101a21:	c9                   	leave  
f0101a22:	c3                   	ret    

f0101a23 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101a23:	55                   	push   %ebp
f0101a24:	89 e5                	mov    %esp,%ebp
f0101a26:	57                   	push   %edi
f0101a27:	56                   	push   %esi
f0101a28:	53                   	push   %ebx
f0101a29:	83 ec 2c             	sub    $0x2c,%esp
f0101a2c:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a2f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a32:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101a35:	eb 12                	jmp    f0101a49 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101a37:	85 c0                	test   %eax,%eax
f0101a39:	0f 84 89 03 00 00    	je     f0101dc8 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0101a3f:	83 ec 08             	sub    $0x8,%esp
f0101a42:	53                   	push   %ebx
f0101a43:	50                   	push   %eax
f0101a44:	ff d6                	call   *%esi
f0101a46:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101a49:	83 c7 01             	add    $0x1,%edi
f0101a4c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101a50:	83 f8 25             	cmp    $0x25,%eax
f0101a53:	75 e2                	jne    f0101a37 <vprintfmt+0x14>
f0101a55:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0101a59:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101a60:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a67:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0101a6e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a73:	eb 07                	jmp    f0101a7c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a75:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101a78:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a7c:	8d 47 01             	lea    0x1(%edi),%eax
f0101a7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101a82:	0f b6 07             	movzbl (%edi),%eax
f0101a85:	0f b6 c8             	movzbl %al,%ecx
f0101a88:	83 e8 23             	sub    $0x23,%eax
f0101a8b:	3c 55                	cmp    $0x55,%al
f0101a8d:	0f 87 1a 03 00 00    	ja     f0101dad <vprintfmt+0x38a>
f0101a93:	0f b6 c0             	movzbl %al,%eax
f0101a96:	ff 24 85 54 2f 10 f0 	jmp    *-0xfefd0ac(,%eax,4)
f0101a9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101aa0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101aa4:	eb d6                	jmp    f0101a7c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101aa6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101aa9:	b8 00 00 00 00       	mov    $0x0,%eax
f0101aae:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101ab1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101ab4:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101ab8:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101abb:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101abe:	83 fa 09             	cmp    $0x9,%edx
f0101ac1:	77 39                	ja     f0101afc <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101ac3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101ac6:	eb e9                	jmp    f0101ab1 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101ac8:	8b 45 14             	mov    0x14(%ebp),%eax
f0101acb:	8d 48 04             	lea    0x4(%eax),%ecx
f0101ace:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101ad1:	8b 00                	mov    (%eax),%eax
f0101ad3:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ad6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101ad9:	eb 27                	jmp    f0101b02 <vprintfmt+0xdf>
f0101adb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ade:	85 c0                	test   %eax,%eax
f0101ae0:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101ae5:	0f 49 c8             	cmovns %eax,%ecx
f0101ae8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101aeb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101aee:	eb 8c                	jmp    f0101a7c <vprintfmt+0x59>
f0101af0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101af3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101afa:	eb 80                	jmp    f0101a7c <vprintfmt+0x59>
f0101afc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101aff:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101b02:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101b06:	0f 89 70 ff ff ff    	jns    f0101a7c <vprintfmt+0x59>
				width = precision, precision = -1;
f0101b0c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b0f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b12:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101b19:	e9 5e ff ff ff       	jmp    f0101a7c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101b1e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101b24:	e9 53 ff ff ff       	jmp    f0101a7c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101b29:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b2c:	8d 50 04             	lea    0x4(%eax),%edx
f0101b2f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b32:	83 ec 08             	sub    $0x8,%esp
f0101b35:	53                   	push   %ebx
f0101b36:	ff 30                	pushl  (%eax)
f0101b38:	ff d6                	call   *%esi
			break;
f0101b3a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101b40:	e9 04 ff ff ff       	jmp    f0101a49 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101b45:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b48:	8d 50 04             	lea    0x4(%eax),%edx
f0101b4b:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b4e:	8b 00                	mov    (%eax),%eax
f0101b50:	99                   	cltd   
f0101b51:	31 d0                	xor    %edx,%eax
f0101b53:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101b55:	83 f8 06             	cmp    $0x6,%eax
f0101b58:	7f 0b                	jg     f0101b65 <vprintfmt+0x142>
f0101b5a:	8b 14 85 ac 30 10 f0 	mov    -0xfefcf54(,%eax,4),%edx
f0101b61:	85 d2                	test   %edx,%edx
f0101b63:	75 18                	jne    f0101b7d <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101b65:	50                   	push   %eax
f0101b66:	68 df 2e 10 f0       	push   $0xf0102edf
f0101b6b:	53                   	push   %ebx
f0101b6c:	56                   	push   %esi
f0101b6d:	e8 94 fe ff ff       	call   f0101a06 <printfmt>
f0101b72:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101b78:	e9 cc fe ff ff       	jmp    f0101a49 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101b7d:	52                   	push   %edx
f0101b7e:	68 0c 2d 10 f0       	push   $0xf0102d0c
f0101b83:	53                   	push   %ebx
f0101b84:	56                   	push   %esi
f0101b85:	e8 7c fe ff ff       	call   f0101a06 <printfmt>
f0101b8a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b90:	e9 b4 fe ff ff       	jmp    f0101a49 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101b95:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b98:	8d 50 04             	lea    0x4(%eax),%edx
f0101b9b:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b9e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101ba0:	85 ff                	test   %edi,%edi
f0101ba2:	b8 d8 2e 10 f0       	mov    $0xf0102ed8,%eax
f0101ba7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101baa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101bae:	0f 8e 94 00 00 00    	jle    f0101c48 <vprintfmt+0x225>
f0101bb4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101bb8:	0f 84 98 00 00 00    	je     f0101c56 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101bbe:	83 ec 08             	sub    $0x8,%esp
f0101bc1:	ff 75 d0             	pushl  -0x30(%ebp)
f0101bc4:	57                   	push   %edi
f0101bc5:	e8 5f 03 00 00       	call   f0101f29 <strnlen>
f0101bca:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101bcd:	29 c1                	sub    %eax,%ecx
f0101bcf:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101bd2:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101bd5:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101bd9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101bdc:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101bdf:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101be1:	eb 0f                	jmp    f0101bf2 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101be3:	83 ec 08             	sub    $0x8,%esp
f0101be6:	53                   	push   %ebx
f0101be7:	ff 75 e0             	pushl  -0x20(%ebp)
f0101bea:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101bec:	83 ef 01             	sub    $0x1,%edi
f0101bef:	83 c4 10             	add    $0x10,%esp
f0101bf2:	85 ff                	test   %edi,%edi
f0101bf4:	7f ed                	jg     f0101be3 <vprintfmt+0x1c0>
f0101bf6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101bf9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101bfc:	85 c9                	test   %ecx,%ecx
f0101bfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101c03:	0f 49 c1             	cmovns %ecx,%eax
f0101c06:	29 c1                	sub    %eax,%ecx
f0101c08:	89 75 08             	mov    %esi,0x8(%ebp)
f0101c0b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101c0e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101c11:	89 cb                	mov    %ecx,%ebx
f0101c13:	eb 4d                	jmp    f0101c62 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101c15:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101c19:	74 1b                	je     f0101c36 <vprintfmt+0x213>
f0101c1b:	0f be c0             	movsbl %al,%eax
f0101c1e:	83 e8 20             	sub    $0x20,%eax
f0101c21:	83 f8 5e             	cmp    $0x5e,%eax
f0101c24:	76 10                	jbe    f0101c36 <vprintfmt+0x213>
					putch('?', putdat);
f0101c26:	83 ec 08             	sub    $0x8,%esp
f0101c29:	ff 75 0c             	pushl  0xc(%ebp)
f0101c2c:	6a 3f                	push   $0x3f
f0101c2e:	ff 55 08             	call   *0x8(%ebp)
f0101c31:	83 c4 10             	add    $0x10,%esp
f0101c34:	eb 0d                	jmp    f0101c43 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101c36:	83 ec 08             	sub    $0x8,%esp
f0101c39:	ff 75 0c             	pushl  0xc(%ebp)
f0101c3c:	52                   	push   %edx
f0101c3d:	ff 55 08             	call   *0x8(%ebp)
f0101c40:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101c43:	83 eb 01             	sub    $0x1,%ebx
f0101c46:	eb 1a                	jmp    f0101c62 <vprintfmt+0x23f>
f0101c48:	89 75 08             	mov    %esi,0x8(%ebp)
f0101c4b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101c4e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101c51:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101c54:	eb 0c                	jmp    f0101c62 <vprintfmt+0x23f>
f0101c56:	89 75 08             	mov    %esi,0x8(%ebp)
f0101c59:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101c5c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101c5f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101c62:	83 c7 01             	add    $0x1,%edi
f0101c65:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101c69:	0f be d0             	movsbl %al,%edx
f0101c6c:	85 d2                	test   %edx,%edx
f0101c6e:	74 23                	je     f0101c93 <vprintfmt+0x270>
f0101c70:	85 f6                	test   %esi,%esi
f0101c72:	78 a1                	js     f0101c15 <vprintfmt+0x1f2>
f0101c74:	83 ee 01             	sub    $0x1,%esi
f0101c77:	79 9c                	jns    f0101c15 <vprintfmt+0x1f2>
f0101c79:	89 df                	mov    %ebx,%edi
f0101c7b:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c7e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101c81:	eb 18                	jmp    f0101c9b <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101c83:	83 ec 08             	sub    $0x8,%esp
f0101c86:	53                   	push   %ebx
f0101c87:	6a 20                	push   $0x20
f0101c89:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101c8b:	83 ef 01             	sub    $0x1,%edi
f0101c8e:	83 c4 10             	add    $0x10,%esp
f0101c91:	eb 08                	jmp    f0101c9b <vprintfmt+0x278>
f0101c93:	89 df                	mov    %ebx,%edi
f0101c95:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c98:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101c9b:	85 ff                	test   %edi,%edi
f0101c9d:	7f e4                	jg     f0101c83 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c9f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ca2:	e9 a2 fd ff ff       	jmp    f0101a49 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101ca7:	83 fa 01             	cmp    $0x1,%edx
f0101caa:	7e 16                	jle    f0101cc2 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101cac:	8b 45 14             	mov    0x14(%ebp),%eax
f0101caf:	8d 50 08             	lea    0x8(%eax),%edx
f0101cb2:	89 55 14             	mov    %edx,0x14(%ebp)
f0101cb5:	8b 50 04             	mov    0x4(%eax),%edx
f0101cb8:	8b 00                	mov    (%eax),%eax
f0101cba:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101cbd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101cc0:	eb 32                	jmp    f0101cf4 <vprintfmt+0x2d1>
	else if (lflag)
f0101cc2:	85 d2                	test   %edx,%edx
f0101cc4:	74 18                	je     f0101cde <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101cc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cc9:	8d 50 04             	lea    0x4(%eax),%edx
f0101ccc:	89 55 14             	mov    %edx,0x14(%ebp)
f0101ccf:	8b 00                	mov    (%eax),%eax
f0101cd1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101cd4:	89 c1                	mov    %eax,%ecx
f0101cd6:	c1 f9 1f             	sar    $0x1f,%ecx
f0101cd9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101cdc:	eb 16                	jmp    f0101cf4 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101cde:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ce1:	8d 50 04             	lea    0x4(%eax),%edx
f0101ce4:	89 55 14             	mov    %edx,0x14(%ebp)
f0101ce7:	8b 00                	mov    (%eax),%eax
f0101ce9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101cec:	89 c1                	mov    %eax,%ecx
f0101cee:	c1 f9 1f             	sar    $0x1f,%ecx
f0101cf1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101cf4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101cf7:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101cfa:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101cff:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101d03:	79 74                	jns    f0101d79 <vprintfmt+0x356>
				putch('-', putdat);
f0101d05:	83 ec 08             	sub    $0x8,%esp
f0101d08:	53                   	push   %ebx
f0101d09:	6a 2d                	push   $0x2d
f0101d0b:	ff d6                	call   *%esi
				num = -(long long) num;
f0101d0d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101d10:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101d13:	f7 d8                	neg    %eax
f0101d15:	83 d2 00             	adc    $0x0,%edx
f0101d18:	f7 da                	neg    %edx
f0101d1a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101d1d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101d22:	eb 55                	jmp    f0101d79 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101d24:	8d 45 14             	lea    0x14(%ebp),%eax
f0101d27:	e8 83 fc ff ff       	call   f01019af <getuint>
			base = 10;
f0101d2c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101d31:	eb 46                	jmp    f0101d79 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0101d33:	8d 45 14             	lea    0x14(%ebp),%eax
f0101d36:	e8 74 fc ff ff       	call   f01019af <getuint>
			base = 8;
f0101d3b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101d40:	eb 37                	jmp    f0101d79 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101d42:	83 ec 08             	sub    $0x8,%esp
f0101d45:	53                   	push   %ebx
f0101d46:	6a 30                	push   $0x30
f0101d48:	ff d6                	call   *%esi
			putch('x', putdat);
f0101d4a:	83 c4 08             	add    $0x8,%esp
f0101d4d:	53                   	push   %ebx
f0101d4e:	6a 78                	push   $0x78
f0101d50:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101d52:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d55:	8d 50 04             	lea    0x4(%eax),%edx
f0101d58:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101d5b:	8b 00                	mov    (%eax),%eax
f0101d5d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101d62:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101d65:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101d6a:	eb 0d                	jmp    f0101d79 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101d6c:	8d 45 14             	lea    0x14(%ebp),%eax
f0101d6f:	e8 3b fc ff ff       	call   f01019af <getuint>
			base = 16;
f0101d74:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101d79:	83 ec 0c             	sub    $0xc,%esp
f0101d7c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101d80:	57                   	push   %edi
f0101d81:	ff 75 e0             	pushl  -0x20(%ebp)
f0101d84:	51                   	push   %ecx
f0101d85:	52                   	push   %edx
f0101d86:	50                   	push   %eax
f0101d87:	89 da                	mov    %ebx,%edx
f0101d89:	89 f0                	mov    %esi,%eax
f0101d8b:	e8 70 fb ff ff       	call   f0101900 <printnum>
			break;
f0101d90:	83 c4 20             	add    $0x20,%esp
f0101d93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101d96:	e9 ae fc ff ff       	jmp    f0101a49 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101d9b:	83 ec 08             	sub    $0x8,%esp
f0101d9e:	53                   	push   %ebx
f0101d9f:	51                   	push   %ecx
f0101da0:	ff d6                	call   *%esi
			break;
f0101da2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101da5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101da8:	e9 9c fc ff ff       	jmp    f0101a49 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101dad:	83 ec 08             	sub    $0x8,%esp
f0101db0:	53                   	push   %ebx
f0101db1:	6a 25                	push   $0x25
f0101db3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101db5:	83 c4 10             	add    $0x10,%esp
f0101db8:	eb 03                	jmp    f0101dbd <vprintfmt+0x39a>
f0101dba:	83 ef 01             	sub    $0x1,%edi
f0101dbd:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101dc1:	75 f7                	jne    f0101dba <vprintfmt+0x397>
f0101dc3:	e9 81 fc ff ff       	jmp    f0101a49 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101dc8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101dcb:	5b                   	pop    %ebx
f0101dcc:	5e                   	pop    %esi
f0101dcd:	5f                   	pop    %edi
f0101dce:	5d                   	pop    %ebp
f0101dcf:	c3                   	ret    

f0101dd0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101dd0:	55                   	push   %ebp
f0101dd1:	89 e5                	mov    %esp,%ebp
f0101dd3:	83 ec 18             	sub    $0x18,%esp
f0101dd6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dd9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101ddc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101ddf:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101de3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101de6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101ded:	85 c0                	test   %eax,%eax
f0101def:	74 26                	je     f0101e17 <vsnprintf+0x47>
f0101df1:	85 d2                	test   %edx,%edx
f0101df3:	7e 22                	jle    f0101e17 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101df5:	ff 75 14             	pushl  0x14(%ebp)
f0101df8:	ff 75 10             	pushl  0x10(%ebp)
f0101dfb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101dfe:	50                   	push   %eax
f0101dff:	68 e9 19 10 f0       	push   $0xf01019e9
f0101e04:	e8 1a fc ff ff       	call   f0101a23 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101e09:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e0c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e12:	83 c4 10             	add    $0x10,%esp
f0101e15:	eb 05                	jmp    f0101e1c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101e17:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101e1c:	c9                   	leave  
f0101e1d:	c3                   	ret    

f0101e1e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101e1e:	55                   	push   %ebp
f0101e1f:	89 e5                	mov    %esp,%ebp
f0101e21:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101e24:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101e27:	50                   	push   %eax
f0101e28:	ff 75 10             	pushl  0x10(%ebp)
f0101e2b:	ff 75 0c             	pushl  0xc(%ebp)
f0101e2e:	ff 75 08             	pushl  0x8(%ebp)
f0101e31:	e8 9a ff ff ff       	call   f0101dd0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101e36:	c9                   	leave  
f0101e37:	c3                   	ret    

f0101e38 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101e38:	55                   	push   %ebp
f0101e39:	89 e5                	mov    %esp,%ebp
f0101e3b:	57                   	push   %edi
f0101e3c:	56                   	push   %esi
f0101e3d:	53                   	push   %ebx
f0101e3e:	83 ec 0c             	sub    $0xc,%esp
f0101e41:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101e44:	85 c0                	test   %eax,%eax
f0101e46:	74 11                	je     f0101e59 <readline+0x21>
		cprintf("%s", prompt);
f0101e48:	83 ec 08             	sub    $0x8,%esp
f0101e4b:	50                   	push   %eax
f0101e4c:	68 0c 2d 10 f0       	push   $0xf0102d0c
f0101e51:	e8 80 f7 ff ff       	call   f01015d6 <cprintf>
f0101e56:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101e59:	83 ec 0c             	sub    $0xc,%esp
f0101e5c:	6a 00                	push   $0x0
f0101e5e:	e8 be e7 ff ff       	call   f0100621 <iscons>
f0101e63:	89 c7                	mov    %eax,%edi
f0101e65:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101e68:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101e6d:	e8 9e e7 ff ff       	call   f0100610 <getchar>
f0101e72:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101e74:	85 c0                	test   %eax,%eax
f0101e76:	79 18                	jns    f0101e90 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101e78:	83 ec 08             	sub    $0x8,%esp
f0101e7b:	50                   	push   %eax
f0101e7c:	68 c8 30 10 f0       	push   $0xf01030c8
f0101e81:	e8 50 f7 ff ff       	call   f01015d6 <cprintf>
			return NULL;
f0101e86:	83 c4 10             	add    $0x10,%esp
f0101e89:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e8e:	eb 79                	jmp    f0101f09 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101e90:	83 f8 08             	cmp    $0x8,%eax
f0101e93:	0f 94 c2             	sete   %dl
f0101e96:	83 f8 7f             	cmp    $0x7f,%eax
f0101e99:	0f 94 c0             	sete   %al
f0101e9c:	08 c2                	or     %al,%dl
f0101e9e:	74 1a                	je     f0101eba <readline+0x82>
f0101ea0:	85 f6                	test   %esi,%esi
f0101ea2:	7e 16                	jle    f0101eba <readline+0x82>
			if (echoing)
f0101ea4:	85 ff                	test   %edi,%edi
f0101ea6:	74 0d                	je     f0101eb5 <readline+0x7d>
				cputchar('\b');
f0101ea8:	83 ec 0c             	sub    $0xc,%esp
f0101eab:	6a 08                	push   $0x8
f0101ead:	e8 4e e7 ff ff       	call   f0100600 <cputchar>
f0101eb2:	83 c4 10             	add    $0x10,%esp
			i--;
f0101eb5:	83 ee 01             	sub    $0x1,%esi
f0101eb8:	eb b3                	jmp    f0101e6d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101eba:	83 fb 1f             	cmp    $0x1f,%ebx
f0101ebd:	7e 23                	jle    f0101ee2 <readline+0xaa>
f0101ebf:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101ec5:	7f 1b                	jg     f0101ee2 <readline+0xaa>
			if (echoing)
f0101ec7:	85 ff                	test   %edi,%edi
f0101ec9:	74 0c                	je     f0101ed7 <readline+0x9f>
				cputchar(c);
f0101ecb:	83 ec 0c             	sub    $0xc,%esp
f0101ece:	53                   	push   %ebx
f0101ecf:	e8 2c e7 ff ff       	call   f0100600 <cputchar>
f0101ed4:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101ed7:	88 9e 40 45 11 f0    	mov    %bl,-0xfeebac0(%esi)
f0101edd:	8d 76 01             	lea    0x1(%esi),%esi
f0101ee0:	eb 8b                	jmp    f0101e6d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101ee2:	83 fb 0a             	cmp    $0xa,%ebx
f0101ee5:	74 05                	je     f0101eec <readline+0xb4>
f0101ee7:	83 fb 0d             	cmp    $0xd,%ebx
f0101eea:	75 81                	jne    f0101e6d <readline+0x35>
			if (echoing)
f0101eec:	85 ff                	test   %edi,%edi
f0101eee:	74 0d                	je     f0101efd <readline+0xc5>
				cputchar('\n');
f0101ef0:	83 ec 0c             	sub    $0xc,%esp
f0101ef3:	6a 0a                	push   $0xa
f0101ef5:	e8 06 e7 ff ff       	call   f0100600 <cputchar>
f0101efa:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101efd:	c6 86 40 45 11 f0 00 	movb   $0x0,-0xfeebac0(%esi)
			return buf;
f0101f04:	b8 40 45 11 f0       	mov    $0xf0114540,%eax
		}
	}
}
f0101f09:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101f0c:	5b                   	pop    %ebx
f0101f0d:	5e                   	pop    %esi
f0101f0e:	5f                   	pop    %edi
f0101f0f:	5d                   	pop    %ebp
f0101f10:	c3                   	ret    

f0101f11 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101f11:	55                   	push   %ebp
f0101f12:	89 e5                	mov    %esp,%ebp
f0101f14:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101f17:	b8 00 00 00 00       	mov    $0x0,%eax
f0101f1c:	eb 03                	jmp    f0101f21 <strlen+0x10>
		n++;
f0101f1e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101f21:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101f25:	75 f7                	jne    f0101f1e <strlen+0xd>
		n++;
	return n;
}
f0101f27:	5d                   	pop    %ebp
f0101f28:	c3                   	ret    

f0101f29 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101f29:	55                   	push   %ebp
f0101f2a:	89 e5                	mov    %esp,%ebp
f0101f2c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f2f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101f32:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f37:	eb 03                	jmp    f0101f3c <strnlen+0x13>
		n++;
f0101f39:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101f3c:	39 c2                	cmp    %eax,%edx
f0101f3e:	74 08                	je     f0101f48 <strnlen+0x1f>
f0101f40:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101f44:	75 f3                	jne    f0101f39 <strnlen+0x10>
f0101f46:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101f48:	5d                   	pop    %ebp
f0101f49:	c3                   	ret    

f0101f4a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101f4a:	55                   	push   %ebp
f0101f4b:	89 e5                	mov    %esp,%ebp
f0101f4d:	53                   	push   %ebx
f0101f4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f51:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101f54:	89 c2                	mov    %eax,%edx
f0101f56:	83 c2 01             	add    $0x1,%edx
f0101f59:	83 c1 01             	add    $0x1,%ecx
f0101f5c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101f60:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101f63:	84 db                	test   %bl,%bl
f0101f65:	75 ef                	jne    f0101f56 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101f67:	5b                   	pop    %ebx
f0101f68:	5d                   	pop    %ebp
f0101f69:	c3                   	ret    

f0101f6a <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101f6a:	55                   	push   %ebp
f0101f6b:	89 e5                	mov    %esp,%ebp
f0101f6d:	53                   	push   %ebx
f0101f6e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101f71:	53                   	push   %ebx
f0101f72:	e8 9a ff ff ff       	call   f0101f11 <strlen>
f0101f77:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101f7a:	ff 75 0c             	pushl  0xc(%ebp)
f0101f7d:	01 d8                	add    %ebx,%eax
f0101f7f:	50                   	push   %eax
f0101f80:	e8 c5 ff ff ff       	call   f0101f4a <strcpy>
	return dst;
}
f0101f85:	89 d8                	mov    %ebx,%eax
f0101f87:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101f8a:	c9                   	leave  
f0101f8b:	c3                   	ret    

f0101f8c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101f8c:	55                   	push   %ebp
f0101f8d:	89 e5                	mov    %esp,%ebp
f0101f8f:	56                   	push   %esi
f0101f90:	53                   	push   %ebx
f0101f91:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f94:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101f97:	89 f3                	mov    %esi,%ebx
f0101f99:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101f9c:	89 f2                	mov    %esi,%edx
f0101f9e:	eb 0f                	jmp    f0101faf <strncpy+0x23>
		*dst++ = *src;
f0101fa0:	83 c2 01             	add    $0x1,%edx
f0101fa3:	0f b6 01             	movzbl (%ecx),%eax
f0101fa6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101fa9:	80 39 01             	cmpb   $0x1,(%ecx)
f0101fac:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101faf:	39 da                	cmp    %ebx,%edx
f0101fb1:	75 ed                	jne    f0101fa0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101fb3:	89 f0                	mov    %esi,%eax
f0101fb5:	5b                   	pop    %ebx
f0101fb6:	5e                   	pop    %esi
f0101fb7:	5d                   	pop    %ebp
f0101fb8:	c3                   	ret    

f0101fb9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101fb9:	55                   	push   %ebp
f0101fba:	89 e5                	mov    %esp,%ebp
f0101fbc:	56                   	push   %esi
f0101fbd:	53                   	push   %ebx
f0101fbe:	8b 75 08             	mov    0x8(%ebp),%esi
f0101fc1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101fc4:	8b 55 10             	mov    0x10(%ebp),%edx
f0101fc7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101fc9:	85 d2                	test   %edx,%edx
f0101fcb:	74 21                	je     f0101fee <strlcpy+0x35>
f0101fcd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101fd1:	89 f2                	mov    %esi,%edx
f0101fd3:	eb 09                	jmp    f0101fde <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101fd5:	83 c2 01             	add    $0x1,%edx
f0101fd8:	83 c1 01             	add    $0x1,%ecx
f0101fdb:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101fde:	39 c2                	cmp    %eax,%edx
f0101fe0:	74 09                	je     f0101feb <strlcpy+0x32>
f0101fe2:	0f b6 19             	movzbl (%ecx),%ebx
f0101fe5:	84 db                	test   %bl,%bl
f0101fe7:	75 ec                	jne    f0101fd5 <strlcpy+0x1c>
f0101fe9:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101feb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101fee:	29 f0                	sub    %esi,%eax
}
f0101ff0:	5b                   	pop    %ebx
f0101ff1:	5e                   	pop    %esi
f0101ff2:	5d                   	pop    %ebp
f0101ff3:	c3                   	ret    

f0101ff4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101ff4:	55                   	push   %ebp
f0101ff5:	89 e5                	mov    %esp,%ebp
f0101ff7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101ffa:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101ffd:	eb 06                	jmp    f0102005 <strcmp+0x11>
		p++, q++;
f0101fff:	83 c1 01             	add    $0x1,%ecx
f0102002:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102005:	0f b6 01             	movzbl (%ecx),%eax
f0102008:	84 c0                	test   %al,%al
f010200a:	74 04                	je     f0102010 <strcmp+0x1c>
f010200c:	3a 02                	cmp    (%edx),%al
f010200e:	74 ef                	je     f0101fff <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102010:	0f b6 c0             	movzbl %al,%eax
f0102013:	0f b6 12             	movzbl (%edx),%edx
f0102016:	29 d0                	sub    %edx,%eax
}
f0102018:	5d                   	pop    %ebp
f0102019:	c3                   	ret    

f010201a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010201a:	55                   	push   %ebp
f010201b:	89 e5                	mov    %esp,%ebp
f010201d:	53                   	push   %ebx
f010201e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102021:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102024:	89 c3                	mov    %eax,%ebx
f0102026:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0102029:	eb 06                	jmp    f0102031 <strncmp+0x17>
		n--, p++, q++;
f010202b:	83 c0 01             	add    $0x1,%eax
f010202e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0102031:	39 d8                	cmp    %ebx,%eax
f0102033:	74 15                	je     f010204a <strncmp+0x30>
f0102035:	0f b6 08             	movzbl (%eax),%ecx
f0102038:	84 c9                	test   %cl,%cl
f010203a:	74 04                	je     f0102040 <strncmp+0x26>
f010203c:	3a 0a                	cmp    (%edx),%cl
f010203e:	74 eb                	je     f010202b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102040:	0f b6 00             	movzbl (%eax),%eax
f0102043:	0f b6 12             	movzbl (%edx),%edx
f0102046:	29 d0                	sub    %edx,%eax
f0102048:	eb 05                	jmp    f010204f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010204a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010204f:	5b                   	pop    %ebx
f0102050:	5d                   	pop    %ebp
f0102051:	c3                   	ret    

f0102052 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102052:	55                   	push   %ebp
f0102053:	89 e5                	mov    %esp,%ebp
f0102055:	8b 45 08             	mov    0x8(%ebp),%eax
f0102058:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010205c:	eb 07                	jmp    f0102065 <strchr+0x13>
		if (*s == c)
f010205e:	38 ca                	cmp    %cl,%dl
f0102060:	74 0f                	je     f0102071 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0102062:	83 c0 01             	add    $0x1,%eax
f0102065:	0f b6 10             	movzbl (%eax),%edx
f0102068:	84 d2                	test   %dl,%dl
f010206a:	75 f2                	jne    f010205e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010206c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102071:	5d                   	pop    %ebp
f0102072:	c3                   	ret    

f0102073 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0102073:	55                   	push   %ebp
f0102074:	89 e5                	mov    %esp,%ebp
f0102076:	8b 45 08             	mov    0x8(%ebp),%eax
f0102079:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010207d:	eb 03                	jmp    f0102082 <strfind+0xf>
f010207f:	83 c0 01             	add    $0x1,%eax
f0102082:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0102085:	38 ca                	cmp    %cl,%dl
f0102087:	74 04                	je     f010208d <strfind+0x1a>
f0102089:	84 d2                	test   %dl,%dl
f010208b:	75 f2                	jne    f010207f <strfind+0xc>
			break;
	return (char *) s;
}
f010208d:	5d                   	pop    %ebp
f010208e:	c3                   	ret    

f010208f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010208f:	55                   	push   %ebp
f0102090:	89 e5                	mov    %esp,%ebp
f0102092:	57                   	push   %edi
f0102093:	56                   	push   %esi
f0102094:	53                   	push   %ebx
f0102095:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102098:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010209b:	85 c9                	test   %ecx,%ecx
f010209d:	74 36                	je     f01020d5 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010209f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01020a5:	75 28                	jne    f01020cf <memset+0x40>
f01020a7:	f6 c1 03             	test   $0x3,%cl
f01020aa:	75 23                	jne    f01020cf <memset+0x40>
		c &= 0xFF;
f01020ac:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01020b0:	89 d3                	mov    %edx,%ebx
f01020b2:	c1 e3 08             	shl    $0x8,%ebx
f01020b5:	89 d6                	mov    %edx,%esi
f01020b7:	c1 e6 18             	shl    $0x18,%esi
f01020ba:	89 d0                	mov    %edx,%eax
f01020bc:	c1 e0 10             	shl    $0x10,%eax
f01020bf:	09 f0                	or     %esi,%eax
f01020c1:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01020c3:	89 d8                	mov    %ebx,%eax
f01020c5:	09 d0                	or     %edx,%eax
f01020c7:	c1 e9 02             	shr    $0x2,%ecx
f01020ca:	fc                   	cld    
f01020cb:	f3 ab                	rep stos %eax,%es:(%edi)
f01020cd:	eb 06                	jmp    f01020d5 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01020cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01020d2:	fc                   	cld    
f01020d3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01020d5:	89 f8                	mov    %edi,%eax
f01020d7:	5b                   	pop    %ebx
f01020d8:	5e                   	pop    %esi
f01020d9:	5f                   	pop    %edi
f01020da:	5d                   	pop    %ebp
f01020db:	c3                   	ret    

f01020dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01020dc:	55                   	push   %ebp
f01020dd:	89 e5                	mov    %esp,%ebp
f01020df:	57                   	push   %edi
f01020e0:	56                   	push   %esi
f01020e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01020e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01020e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01020ea:	39 c6                	cmp    %eax,%esi
f01020ec:	73 35                	jae    f0102123 <memmove+0x47>
f01020ee:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01020f1:	39 d0                	cmp    %edx,%eax
f01020f3:	73 2e                	jae    f0102123 <memmove+0x47>
		s += n;
		d += n;
f01020f5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01020f8:	89 d6                	mov    %edx,%esi
f01020fa:	09 fe                	or     %edi,%esi
f01020fc:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102102:	75 13                	jne    f0102117 <memmove+0x3b>
f0102104:	f6 c1 03             	test   $0x3,%cl
f0102107:	75 0e                	jne    f0102117 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102109:	83 ef 04             	sub    $0x4,%edi
f010210c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010210f:	c1 e9 02             	shr    $0x2,%ecx
f0102112:	fd                   	std    
f0102113:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102115:	eb 09                	jmp    f0102120 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102117:	83 ef 01             	sub    $0x1,%edi
f010211a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010211d:	fd                   	std    
f010211e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102120:	fc                   	cld    
f0102121:	eb 1d                	jmp    f0102140 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102123:	89 f2                	mov    %esi,%edx
f0102125:	09 c2                	or     %eax,%edx
f0102127:	f6 c2 03             	test   $0x3,%dl
f010212a:	75 0f                	jne    f010213b <memmove+0x5f>
f010212c:	f6 c1 03             	test   $0x3,%cl
f010212f:	75 0a                	jne    f010213b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0102131:	c1 e9 02             	shr    $0x2,%ecx
f0102134:	89 c7                	mov    %eax,%edi
f0102136:	fc                   	cld    
f0102137:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102139:	eb 05                	jmp    f0102140 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010213b:	89 c7                	mov    %eax,%edi
f010213d:	fc                   	cld    
f010213e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102140:	5e                   	pop    %esi
f0102141:	5f                   	pop    %edi
f0102142:	5d                   	pop    %ebp
f0102143:	c3                   	ret    

f0102144 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102144:	55                   	push   %ebp
f0102145:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102147:	ff 75 10             	pushl  0x10(%ebp)
f010214a:	ff 75 0c             	pushl  0xc(%ebp)
f010214d:	ff 75 08             	pushl  0x8(%ebp)
f0102150:	e8 87 ff ff ff       	call   f01020dc <memmove>
}
f0102155:	c9                   	leave  
f0102156:	c3                   	ret    

f0102157 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102157:	55                   	push   %ebp
f0102158:	89 e5                	mov    %esp,%ebp
f010215a:	56                   	push   %esi
f010215b:	53                   	push   %ebx
f010215c:	8b 45 08             	mov    0x8(%ebp),%eax
f010215f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102162:	89 c6                	mov    %eax,%esi
f0102164:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102167:	eb 1a                	jmp    f0102183 <memcmp+0x2c>
		if (*s1 != *s2)
f0102169:	0f b6 08             	movzbl (%eax),%ecx
f010216c:	0f b6 1a             	movzbl (%edx),%ebx
f010216f:	38 d9                	cmp    %bl,%cl
f0102171:	74 0a                	je     f010217d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0102173:	0f b6 c1             	movzbl %cl,%eax
f0102176:	0f b6 db             	movzbl %bl,%ebx
f0102179:	29 d8                	sub    %ebx,%eax
f010217b:	eb 0f                	jmp    f010218c <memcmp+0x35>
		s1++, s2++;
f010217d:	83 c0 01             	add    $0x1,%eax
f0102180:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102183:	39 f0                	cmp    %esi,%eax
f0102185:	75 e2                	jne    f0102169 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0102187:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010218c:	5b                   	pop    %ebx
f010218d:	5e                   	pop    %esi
f010218e:	5d                   	pop    %ebp
f010218f:	c3                   	ret    

f0102190 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102190:	55                   	push   %ebp
f0102191:	89 e5                	mov    %esp,%ebp
f0102193:	53                   	push   %ebx
f0102194:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102197:	89 c1                	mov    %eax,%ecx
f0102199:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010219c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01021a0:	eb 0a                	jmp    f01021ac <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01021a2:	0f b6 10             	movzbl (%eax),%edx
f01021a5:	39 da                	cmp    %ebx,%edx
f01021a7:	74 07                	je     f01021b0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01021a9:	83 c0 01             	add    $0x1,%eax
f01021ac:	39 c8                	cmp    %ecx,%eax
f01021ae:	72 f2                	jb     f01021a2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01021b0:	5b                   	pop    %ebx
f01021b1:	5d                   	pop    %ebp
f01021b2:	c3                   	ret    

f01021b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01021b3:	55                   	push   %ebp
f01021b4:	89 e5                	mov    %esp,%ebp
f01021b6:	57                   	push   %edi
f01021b7:	56                   	push   %esi
f01021b8:	53                   	push   %ebx
f01021b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01021bc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01021bf:	eb 03                	jmp    f01021c4 <strtol+0x11>
		s++;
f01021c1:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01021c4:	0f b6 01             	movzbl (%ecx),%eax
f01021c7:	3c 20                	cmp    $0x20,%al
f01021c9:	74 f6                	je     f01021c1 <strtol+0xe>
f01021cb:	3c 09                	cmp    $0x9,%al
f01021cd:	74 f2                	je     f01021c1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01021cf:	3c 2b                	cmp    $0x2b,%al
f01021d1:	75 0a                	jne    f01021dd <strtol+0x2a>
		s++;
f01021d3:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01021d6:	bf 00 00 00 00       	mov    $0x0,%edi
f01021db:	eb 11                	jmp    f01021ee <strtol+0x3b>
f01021dd:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01021e2:	3c 2d                	cmp    $0x2d,%al
f01021e4:	75 08                	jne    f01021ee <strtol+0x3b>
		s++, neg = 1;
f01021e6:	83 c1 01             	add    $0x1,%ecx
f01021e9:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01021ee:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01021f4:	75 15                	jne    f010220b <strtol+0x58>
f01021f6:	80 39 30             	cmpb   $0x30,(%ecx)
f01021f9:	75 10                	jne    f010220b <strtol+0x58>
f01021fb:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01021ff:	75 7c                	jne    f010227d <strtol+0xca>
		s += 2, base = 16;
f0102201:	83 c1 02             	add    $0x2,%ecx
f0102204:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102209:	eb 16                	jmp    f0102221 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010220b:	85 db                	test   %ebx,%ebx
f010220d:	75 12                	jne    f0102221 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010220f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102214:	80 39 30             	cmpb   $0x30,(%ecx)
f0102217:	75 08                	jne    f0102221 <strtol+0x6e>
		s++, base = 8;
f0102219:	83 c1 01             	add    $0x1,%ecx
f010221c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102221:	b8 00 00 00 00       	mov    $0x0,%eax
f0102226:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102229:	0f b6 11             	movzbl (%ecx),%edx
f010222c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010222f:	89 f3                	mov    %esi,%ebx
f0102231:	80 fb 09             	cmp    $0x9,%bl
f0102234:	77 08                	ja     f010223e <strtol+0x8b>
			dig = *s - '0';
f0102236:	0f be d2             	movsbl %dl,%edx
f0102239:	83 ea 30             	sub    $0x30,%edx
f010223c:	eb 22                	jmp    f0102260 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010223e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102241:	89 f3                	mov    %esi,%ebx
f0102243:	80 fb 19             	cmp    $0x19,%bl
f0102246:	77 08                	ja     f0102250 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102248:	0f be d2             	movsbl %dl,%edx
f010224b:	83 ea 57             	sub    $0x57,%edx
f010224e:	eb 10                	jmp    f0102260 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0102250:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102253:	89 f3                	mov    %esi,%ebx
f0102255:	80 fb 19             	cmp    $0x19,%bl
f0102258:	77 16                	ja     f0102270 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010225a:	0f be d2             	movsbl %dl,%edx
f010225d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0102260:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102263:	7d 0b                	jge    f0102270 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0102265:	83 c1 01             	add    $0x1,%ecx
f0102268:	0f af 45 10          	imul   0x10(%ebp),%eax
f010226c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010226e:	eb b9                	jmp    f0102229 <strtol+0x76>

	if (endptr)
f0102270:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102274:	74 0d                	je     f0102283 <strtol+0xd0>
		*endptr = (char *) s;
f0102276:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102279:	89 0e                	mov    %ecx,(%esi)
f010227b:	eb 06                	jmp    f0102283 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010227d:	85 db                	test   %ebx,%ebx
f010227f:	74 98                	je     f0102219 <strtol+0x66>
f0102281:	eb 9e                	jmp    f0102221 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0102283:	89 c2                	mov    %eax,%edx
f0102285:	f7 da                	neg    %edx
f0102287:	85 ff                	test   %edi,%edi
f0102289:	0f 45 c2             	cmovne %edx,%eax
}
f010228c:	5b                   	pop    %ebx
f010228d:	5e                   	pop    %esi
f010228e:	5f                   	pop    %edi
f010228f:	5d                   	pop    %ebp
f0102290:	c3                   	ret    
f0102291:	66 90                	xchg   %ax,%ax
f0102293:	66 90                	xchg   %ax,%ax
f0102295:	66 90                	xchg   %ax,%ax
f0102297:	66 90                	xchg   %ax,%ax
f0102299:	66 90                	xchg   %ax,%ax
f010229b:	66 90                	xchg   %ax,%ax
f010229d:	66 90                	xchg   %ax,%ax
f010229f:	90                   	nop

f01022a0 <__udivdi3>:
f01022a0:	55                   	push   %ebp
f01022a1:	57                   	push   %edi
f01022a2:	56                   	push   %esi
f01022a3:	53                   	push   %ebx
f01022a4:	83 ec 1c             	sub    $0x1c,%esp
f01022a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01022ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01022af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01022b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01022b7:	85 f6                	test   %esi,%esi
f01022b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01022bd:	89 ca                	mov    %ecx,%edx
f01022bf:	89 f8                	mov    %edi,%eax
f01022c1:	75 3d                	jne    f0102300 <__udivdi3+0x60>
f01022c3:	39 cf                	cmp    %ecx,%edi
f01022c5:	0f 87 c5 00 00 00    	ja     f0102390 <__udivdi3+0xf0>
f01022cb:	85 ff                	test   %edi,%edi
f01022cd:	89 fd                	mov    %edi,%ebp
f01022cf:	75 0b                	jne    f01022dc <__udivdi3+0x3c>
f01022d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01022d6:	31 d2                	xor    %edx,%edx
f01022d8:	f7 f7                	div    %edi
f01022da:	89 c5                	mov    %eax,%ebp
f01022dc:	89 c8                	mov    %ecx,%eax
f01022de:	31 d2                	xor    %edx,%edx
f01022e0:	f7 f5                	div    %ebp
f01022e2:	89 c1                	mov    %eax,%ecx
f01022e4:	89 d8                	mov    %ebx,%eax
f01022e6:	89 cf                	mov    %ecx,%edi
f01022e8:	f7 f5                	div    %ebp
f01022ea:	89 c3                	mov    %eax,%ebx
f01022ec:	89 d8                	mov    %ebx,%eax
f01022ee:	89 fa                	mov    %edi,%edx
f01022f0:	83 c4 1c             	add    $0x1c,%esp
f01022f3:	5b                   	pop    %ebx
f01022f4:	5e                   	pop    %esi
f01022f5:	5f                   	pop    %edi
f01022f6:	5d                   	pop    %ebp
f01022f7:	c3                   	ret    
f01022f8:	90                   	nop
f01022f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102300:	39 ce                	cmp    %ecx,%esi
f0102302:	77 74                	ja     f0102378 <__udivdi3+0xd8>
f0102304:	0f bd fe             	bsr    %esi,%edi
f0102307:	83 f7 1f             	xor    $0x1f,%edi
f010230a:	0f 84 98 00 00 00    	je     f01023a8 <__udivdi3+0x108>
f0102310:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102315:	89 f9                	mov    %edi,%ecx
f0102317:	89 c5                	mov    %eax,%ebp
f0102319:	29 fb                	sub    %edi,%ebx
f010231b:	d3 e6                	shl    %cl,%esi
f010231d:	89 d9                	mov    %ebx,%ecx
f010231f:	d3 ed                	shr    %cl,%ebp
f0102321:	89 f9                	mov    %edi,%ecx
f0102323:	d3 e0                	shl    %cl,%eax
f0102325:	09 ee                	or     %ebp,%esi
f0102327:	89 d9                	mov    %ebx,%ecx
f0102329:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010232d:	89 d5                	mov    %edx,%ebp
f010232f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102333:	d3 ed                	shr    %cl,%ebp
f0102335:	89 f9                	mov    %edi,%ecx
f0102337:	d3 e2                	shl    %cl,%edx
f0102339:	89 d9                	mov    %ebx,%ecx
f010233b:	d3 e8                	shr    %cl,%eax
f010233d:	09 c2                	or     %eax,%edx
f010233f:	89 d0                	mov    %edx,%eax
f0102341:	89 ea                	mov    %ebp,%edx
f0102343:	f7 f6                	div    %esi
f0102345:	89 d5                	mov    %edx,%ebp
f0102347:	89 c3                	mov    %eax,%ebx
f0102349:	f7 64 24 0c          	mull   0xc(%esp)
f010234d:	39 d5                	cmp    %edx,%ebp
f010234f:	72 10                	jb     f0102361 <__udivdi3+0xc1>
f0102351:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102355:	89 f9                	mov    %edi,%ecx
f0102357:	d3 e6                	shl    %cl,%esi
f0102359:	39 c6                	cmp    %eax,%esi
f010235b:	73 07                	jae    f0102364 <__udivdi3+0xc4>
f010235d:	39 d5                	cmp    %edx,%ebp
f010235f:	75 03                	jne    f0102364 <__udivdi3+0xc4>
f0102361:	83 eb 01             	sub    $0x1,%ebx
f0102364:	31 ff                	xor    %edi,%edi
f0102366:	89 d8                	mov    %ebx,%eax
f0102368:	89 fa                	mov    %edi,%edx
f010236a:	83 c4 1c             	add    $0x1c,%esp
f010236d:	5b                   	pop    %ebx
f010236e:	5e                   	pop    %esi
f010236f:	5f                   	pop    %edi
f0102370:	5d                   	pop    %ebp
f0102371:	c3                   	ret    
f0102372:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102378:	31 ff                	xor    %edi,%edi
f010237a:	31 db                	xor    %ebx,%ebx
f010237c:	89 d8                	mov    %ebx,%eax
f010237e:	89 fa                	mov    %edi,%edx
f0102380:	83 c4 1c             	add    $0x1c,%esp
f0102383:	5b                   	pop    %ebx
f0102384:	5e                   	pop    %esi
f0102385:	5f                   	pop    %edi
f0102386:	5d                   	pop    %ebp
f0102387:	c3                   	ret    
f0102388:	90                   	nop
f0102389:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102390:	89 d8                	mov    %ebx,%eax
f0102392:	f7 f7                	div    %edi
f0102394:	31 ff                	xor    %edi,%edi
f0102396:	89 c3                	mov    %eax,%ebx
f0102398:	89 d8                	mov    %ebx,%eax
f010239a:	89 fa                	mov    %edi,%edx
f010239c:	83 c4 1c             	add    $0x1c,%esp
f010239f:	5b                   	pop    %ebx
f01023a0:	5e                   	pop    %esi
f01023a1:	5f                   	pop    %edi
f01023a2:	5d                   	pop    %ebp
f01023a3:	c3                   	ret    
f01023a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01023a8:	39 ce                	cmp    %ecx,%esi
f01023aa:	72 0c                	jb     f01023b8 <__udivdi3+0x118>
f01023ac:	31 db                	xor    %ebx,%ebx
f01023ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01023b2:	0f 87 34 ff ff ff    	ja     f01022ec <__udivdi3+0x4c>
f01023b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01023bd:	e9 2a ff ff ff       	jmp    f01022ec <__udivdi3+0x4c>
f01023c2:	66 90                	xchg   %ax,%ax
f01023c4:	66 90                	xchg   %ax,%ax
f01023c6:	66 90                	xchg   %ax,%ax
f01023c8:	66 90                	xchg   %ax,%ax
f01023ca:	66 90                	xchg   %ax,%ax
f01023cc:	66 90                	xchg   %ax,%ax
f01023ce:	66 90                	xchg   %ax,%ax

f01023d0 <__umoddi3>:
f01023d0:	55                   	push   %ebp
f01023d1:	57                   	push   %edi
f01023d2:	56                   	push   %esi
f01023d3:	53                   	push   %ebx
f01023d4:	83 ec 1c             	sub    $0x1c,%esp
f01023d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01023db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01023df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01023e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01023e7:	85 d2                	test   %edx,%edx
f01023e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01023ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01023f1:	89 f3                	mov    %esi,%ebx
f01023f3:	89 3c 24             	mov    %edi,(%esp)
f01023f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01023fa:	75 1c                	jne    f0102418 <__umoddi3+0x48>
f01023fc:	39 f7                	cmp    %esi,%edi
f01023fe:	76 50                	jbe    f0102450 <__umoddi3+0x80>
f0102400:	89 c8                	mov    %ecx,%eax
f0102402:	89 f2                	mov    %esi,%edx
f0102404:	f7 f7                	div    %edi
f0102406:	89 d0                	mov    %edx,%eax
f0102408:	31 d2                	xor    %edx,%edx
f010240a:	83 c4 1c             	add    $0x1c,%esp
f010240d:	5b                   	pop    %ebx
f010240e:	5e                   	pop    %esi
f010240f:	5f                   	pop    %edi
f0102410:	5d                   	pop    %ebp
f0102411:	c3                   	ret    
f0102412:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102418:	39 f2                	cmp    %esi,%edx
f010241a:	89 d0                	mov    %edx,%eax
f010241c:	77 52                	ja     f0102470 <__umoddi3+0xa0>
f010241e:	0f bd ea             	bsr    %edx,%ebp
f0102421:	83 f5 1f             	xor    $0x1f,%ebp
f0102424:	75 5a                	jne    f0102480 <__umoddi3+0xb0>
f0102426:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010242a:	0f 82 e0 00 00 00    	jb     f0102510 <__umoddi3+0x140>
f0102430:	39 0c 24             	cmp    %ecx,(%esp)
f0102433:	0f 86 d7 00 00 00    	jbe    f0102510 <__umoddi3+0x140>
f0102439:	8b 44 24 08          	mov    0x8(%esp),%eax
f010243d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102441:	83 c4 1c             	add    $0x1c,%esp
f0102444:	5b                   	pop    %ebx
f0102445:	5e                   	pop    %esi
f0102446:	5f                   	pop    %edi
f0102447:	5d                   	pop    %ebp
f0102448:	c3                   	ret    
f0102449:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102450:	85 ff                	test   %edi,%edi
f0102452:	89 fd                	mov    %edi,%ebp
f0102454:	75 0b                	jne    f0102461 <__umoddi3+0x91>
f0102456:	b8 01 00 00 00       	mov    $0x1,%eax
f010245b:	31 d2                	xor    %edx,%edx
f010245d:	f7 f7                	div    %edi
f010245f:	89 c5                	mov    %eax,%ebp
f0102461:	89 f0                	mov    %esi,%eax
f0102463:	31 d2                	xor    %edx,%edx
f0102465:	f7 f5                	div    %ebp
f0102467:	89 c8                	mov    %ecx,%eax
f0102469:	f7 f5                	div    %ebp
f010246b:	89 d0                	mov    %edx,%eax
f010246d:	eb 99                	jmp    f0102408 <__umoddi3+0x38>
f010246f:	90                   	nop
f0102470:	89 c8                	mov    %ecx,%eax
f0102472:	89 f2                	mov    %esi,%edx
f0102474:	83 c4 1c             	add    $0x1c,%esp
f0102477:	5b                   	pop    %ebx
f0102478:	5e                   	pop    %esi
f0102479:	5f                   	pop    %edi
f010247a:	5d                   	pop    %ebp
f010247b:	c3                   	ret    
f010247c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102480:	8b 34 24             	mov    (%esp),%esi
f0102483:	bf 20 00 00 00       	mov    $0x20,%edi
f0102488:	89 e9                	mov    %ebp,%ecx
f010248a:	29 ef                	sub    %ebp,%edi
f010248c:	d3 e0                	shl    %cl,%eax
f010248e:	89 f9                	mov    %edi,%ecx
f0102490:	89 f2                	mov    %esi,%edx
f0102492:	d3 ea                	shr    %cl,%edx
f0102494:	89 e9                	mov    %ebp,%ecx
f0102496:	09 c2                	or     %eax,%edx
f0102498:	89 d8                	mov    %ebx,%eax
f010249a:	89 14 24             	mov    %edx,(%esp)
f010249d:	89 f2                	mov    %esi,%edx
f010249f:	d3 e2                	shl    %cl,%edx
f01024a1:	89 f9                	mov    %edi,%ecx
f01024a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01024a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01024ab:	d3 e8                	shr    %cl,%eax
f01024ad:	89 e9                	mov    %ebp,%ecx
f01024af:	89 c6                	mov    %eax,%esi
f01024b1:	d3 e3                	shl    %cl,%ebx
f01024b3:	89 f9                	mov    %edi,%ecx
f01024b5:	89 d0                	mov    %edx,%eax
f01024b7:	d3 e8                	shr    %cl,%eax
f01024b9:	89 e9                	mov    %ebp,%ecx
f01024bb:	09 d8                	or     %ebx,%eax
f01024bd:	89 d3                	mov    %edx,%ebx
f01024bf:	89 f2                	mov    %esi,%edx
f01024c1:	f7 34 24             	divl   (%esp)
f01024c4:	89 d6                	mov    %edx,%esi
f01024c6:	d3 e3                	shl    %cl,%ebx
f01024c8:	f7 64 24 04          	mull   0x4(%esp)
f01024cc:	39 d6                	cmp    %edx,%esi
f01024ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01024d2:	89 d1                	mov    %edx,%ecx
f01024d4:	89 c3                	mov    %eax,%ebx
f01024d6:	72 08                	jb     f01024e0 <__umoddi3+0x110>
f01024d8:	75 11                	jne    f01024eb <__umoddi3+0x11b>
f01024da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01024de:	73 0b                	jae    f01024eb <__umoddi3+0x11b>
f01024e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01024e4:	1b 14 24             	sbb    (%esp),%edx
f01024e7:	89 d1                	mov    %edx,%ecx
f01024e9:	89 c3                	mov    %eax,%ebx
f01024eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01024ef:	29 da                	sub    %ebx,%edx
f01024f1:	19 ce                	sbb    %ecx,%esi
f01024f3:	89 f9                	mov    %edi,%ecx
f01024f5:	89 f0                	mov    %esi,%eax
f01024f7:	d3 e0                	shl    %cl,%eax
f01024f9:	89 e9                	mov    %ebp,%ecx
f01024fb:	d3 ea                	shr    %cl,%edx
f01024fd:	89 e9                	mov    %ebp,%ecx
f01024ff:	d3 ee                	shr    %cl,%esi
f0102501:	09 d0                	or     %edx,%eax
f0102503:	89 f2                	mov    %esi,%edx
f0102505:	83 c4 1c             	add    $0x1c,%esp
f0102508:	5b                   	pop    %ebx
f0102509:	5e                   	pop    %esi
f010250a:	5f                   	pop    %edi
f010250b:	5d                   	pop    %ebp
f010250c:	c3                   	ret    
f010250d:	8d 76 00             	lea    0x0(%esi),%esi
f0102510:	29 f9                	sub    %edi,%ecx
f0102512:	19 d6                	sbb    %edx,%esi
f0102514:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102518:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010251c:	e9 18 ff ff ff       	jmp    f0102439 <__umoddi3+0x69>
