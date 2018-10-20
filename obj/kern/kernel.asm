
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100046:	b8 50 79 11 f0       	mov    $0xf0117950,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 37 31 00 00       	call   f0103194 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 36 10 f0       	push   $0xf0103640
f010006f:	e8 67 26 00 00       	call   f01026db <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 35 10 00 00       	call   f01010ae <mem_init>
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
f0100093:	83 3d 40 79 11 f0 00 	cmpl   $0x0,0xf0117940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 79 11 f0    	mov    %esi,0xf0117940

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
f01000b0:	68 5b 36 10 f0       	push   $0xf010365b
f01000b5:	e8 21 26 00 00       	call   f01026db <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 f1 25 00 00       	call   f01026b5 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 81 39 10 f0 	movl   $0xf0103981,(%esp)
f01000cb:	e8 0b 26 00 00       	call   f01026db <cprintf>
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
f01000f2:	68 73 36 10 f0       	push   $0xf0103673
f01000f7:	e8 df 25 00 00       	call   f01026db <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ad 25 00 00       	call   f01026b5 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 81 39 10 f0 	movl   $0xf0103981,(%esp)
f010010f:	e8 c7 25 00 00       	call   f01026db <cprintf>
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
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
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
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
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
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 e0 37 10 f0 	movzbl -0xfefc820(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 e0 37 10 f0 	movzbl -0xfefc820(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a e0 36 10 f0 	movzbl -0xfefc920(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d c0 36 10 f0 	mov    -0xfefc940(,%ecx,4),%ecx
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
f0100268:	68 8d 36 10 f0       	push   $0xf010368d
f010026d:	e8 69 24 00 00       	call   f01026db <cprintf>
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
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 c0 2d 00 00       	call   f01031e1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
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
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
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
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
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
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
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
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
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
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
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
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
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
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
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
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
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
f01005eb:	68 99 36 10 f0       	push   $0xf0103699
f01005f0:	e8 e6 20 00 00       	call   f01026db <cprintf>
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
f0100631:	68 e0 38 10 f0       	push   $0xf01038e0
f0100636:	68 fe 38 10 f0       	push   $0xf01038fe
f010063b:	68 03 39 10 f0       	push   $0xf0103903
f0100640:	e8 96 20 00 00       	call   f01026db <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 c0 39 10 f0       	push   $0xf01039c0
f010064d:	68 0c 39 10 f0       	push   $0xf010390c
f0100652:	68 03 39 10 f0       	push   $0xf0103903
f0100657:	e8 7f 20 00 00       	call   f01026db <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 e8 39 10 f0       	push   $0xf01039e8
f0100664:	68 15 39 10 f0       	push   $0xf0103915
f0100669:	68 03 39 10 f0       	push   $0xf0103903
f010066e:	e8 68 20 00 00       	call   f01026db <cprintf>
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
f0100680:	68 1f 39 10 f0       	push   $0xf010391f
f0100685:	e8 51 20 00 00       	call   f01026db <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 14 3a 10 f0       	push   $0xf0103a14
f0100697:	e8 3f 20 00 00       	call   f01026db <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 3c 3a 10 f0       	push   $0xf0103a3c
f01006ae:	e8 28 20 00 00       	call   f01026db <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 21 36 10 00       	push   $0x103621
f01006bb:	68 21 36 10 f0       	push   $0xf0103621
f01006c0:	68 60 3a 10 f0       	push   $0xf0103a60
f01006c5:	e8 11 20 00 00       	call   f01026db <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 84 3a 10 f0       	push   $0xf0103a84
f01006dc:	e8 fa 1f 00 00       	call   f01026db <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 50 79 11 00       	push   $0x117950
f01006e9:	68 50 79 11 f0       	push   $0xf0117950
f01006ee:	68 a8 3a 10 f0       	push   $0xf0103aa8
f01006f3:	e8 e3 1f 00 00       	call   f01026db <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 4f 7d 11 f0       	mov    $0xf0117d4f,%eax
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
f0100719:	68 cc 3a 10 f0       	push   $0xf0103acc
f010071e:	e8 b8 1f 00 00       	call   f01026db <cprintf>
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
f0100735:	68 38 39 10 f0       	push   $0xf0103938
f010073a:	e8 9c 1f 00 00       	call   f01026db <cprintf>
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
f0100752:	68 4b 39 10 f0       	push   $0xf010394b
f0100757:	e8 7f 1f 00 00       	call   f01026db <cprintf>
		cprintf("%08x ", *(ebp+2));
f010075c:	83 c4 08             	add    $0x8,%esp
f010075f:	ff 73 08             	pushl  0x8(%ebx)
f0100762:	68 65 39 10 f0       	push   $0xf0103965
f0100767:	e8 6f 1f 00 00       	call   f01026db <cprintf>
		cprintf("%08x ", *(ebp+3));
f010076c:	83 c4 08             	add    $0x8,%esp
f010076f:	ff 73 0c             	pushl  0xc(%ebx)
f0100772:	68 65 39 10 f0       	push   $0xf0103965
f0100777:	e8 5f 1f 00 00       	call   f01026db <cprintf>
		cprintf("%08x ", *(ebp+4));
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff 73 10             	pushl  0x10(%ebx)
f0100782:	68 65 39 10 f0       	push   $0xf0103965
f0100787:	e8 4f 1f 00 00       	call   f01026db <cprintf>
		cprintf("%08x ", *(ebp+5));
f010078c:	83 c4 08             	add    $0x8,%esp
f010078f:	ff 73 14             	pushl  0x14(%ebx)
f0100792:	68 65 39 10 f0       	push   $0xf0103965
f0100797:	e8 3f 1f 00 00       	call   f01026db <cprintf>
		cprintf("%08x", *(ebp+6));
f010079c:	83 c4 08             	add    $0x8,%esp
f010079f:	ff 73 18             	pushl  0x18(%ebx)
f01007a2:	68 6b 39 10 f0       	push   $0xf010396b
f01007a7:	e8 2f 1f 00 00       	call   f01026db <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01007ac:	83 c4 08             	add    $0x8,%esp
f01007af:	57                   	push   %edi
f01007b0:	56                   	push   %esi
f01007b1:	e8 2f 20 00 00       	call   f01027e5 <debuginfo_eip>
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
f01007d0:	68 70 39 10 f0       	push   $0xf0103970
f01007d5:	e8 01 1f 00 00       	call   f01026db <cprintf>
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
f01007fd:	68 f8 3a 10 f0       	push   $0xf0103af8
f0100802:	e8 d4 1e 00 00       	call   f01026db <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100807:	c7 04 24 1c 3b 10 f0 	movl   $0xf0103b1c,(%esp)
f010080e:	e8 c8 1e 00 00       	call   f01026db <cprintf>
f0100813:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100816:	83 ec 0c             	sub    $0xc,%esp
f0100819:	68 83 39 10 f0       	push   $0xf0103983
f010081e:	e8 1a 27 00 00       	call   f0102f3d <readline>
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
f0100852:	68 87 39 10 f0       	push   $0xf0103987
f0100857:	e8 fb 28 00 00       	call   f0103157 <strchr>
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
f0100872:	68 8c 39 10 f0       	push   $0xf010398c
f0100877:	e8 5f 1e 00 00       	call   f01026db <cprintf>
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
f010089b:	68 87 39 10 f0       	push   $0xf0103987
f01008a0:	e8 b2 28 00 00       	call   f0103157 <strchr>
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
f01008c9:	ff 34 85 60 3b 10 f0 	pushl  -0xfefc4a0(,%eax,4)
f01008d0:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d3:	e8 21 28 00 00       	call   f01030f9 <strcmp>
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
f01008ed:	ff 14 85 68 3b 10 f0 	call   *-0xfefc498(,%eax,4)


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
f010090e:	68 a9 39 10 f0       	push   $0xf01039a9
f0100913:	e8 c3 1d 00 00       	call   f01026db <cprintf>
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
f0100933:	e8 3c 1d 00 00       	call   f0102674 <mc146818_read>
f0100938:	89 c6                	mov    %eax,%esi
f010093a:	83 c3 01             	add    $0x1,%ebx
f010093d:	89 1c 24             	mov    %ebx,(%esp)
f0100940:	e8 2f 1d 00 00       	call   f0102674 <mc146818_read>
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
f0100967:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
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
f0100976:	68 84 3b 10 f0       	push   $0xf0103b84
f010097b:	68 0b 03 00 00       	push   $0x30b
f0100980:	68 48 43 10 f0       	push   $0xf0104348
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
f01009b5:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f01009bc:	75 11                	jne    f01009cf <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009be:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f01009c3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009c9:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f01009cf:	85 c0                	test   %eax,%eax
f01009d1:	75 06                	jne    f01009d9 <boot_alloc+0x24>
		return nextfree;
f01009d3:	a1 38 75 11 f0       	mov    0xf0117538,%eax
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
f01009e0:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx
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
f01009fa:	68 a8 3b 10 f0       	push   $0xf0103ba8
f01009ff:	6a 6f                	push   $0x6f
f0100a01:	68 48 43 10 f0       	push   $0xf0104348
f0100a06:	e8 80 f6 ff ff       	call   f010008b <_panic>
	
	if(PADDR(new) > npages * PGSIZE)
f0100a0b:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0100a11:	c1 e1 0c             	shl    $0xc,%ecx
f0100a14:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100a1a:	39 d9                	cmp    %ebx,%ecx
f0100a1c:	73 14                	jae    f0100a32 <boot_alloc+0x7d>
		panic("boot_alloc: out of memory!\n");
f0100a1e:	83 ec 04             	sub    $0x4,%esp
f0100a21:	68 54 43 10 f0       	push   $0xf0104354
f0100a26:	6a 70                	push   $0x70
f0100a28:	68 48 43 10 f0       	push   $0xf0104348
f0100a2d:	e8 59 f6 ff ff       	call   f010008b <_panic>
	else
	{
		nextfree = new;
f0100a32:	a3 38 75 11 f0       	mov    %eax,0xf0117538
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
f0100a57:	68 cc 3b 10 f0       	push   $0xf0103bcc
f0100a5c:	68 4c 02 00 00       	push   $0x24c
f0100a61:	68 48 43 10 f0       	push   $0xf0104348
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
f0100a79:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
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
f0100aaf:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
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
f0100ab9:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100abf:	eb 53                	jmp    f0100b14 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ac1:	89 d8                	mov    %ebx,%eax
f0100ac3:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
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
f0100add:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100ae3:	72 12                	jb     f0100af7 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae5:	50                   	push   %eax
f0100ae6:	68 84 3b 10 f0       	push   $0xf0103b84
f0100aeb:	6a 52                	push   $0x52
f0100aed:	68 70 43 10 f0       	push   $0xf0104370
f0100af2:	e8 94 f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100af7:	83 ec 04             	sub    $0x4,%esp
f0100afa:	68 80 00 00 00       	push   $0x80
f0100aff:	68 97 00 00 00       	push   $0x97
f0100b04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b09:	50                   	push   %eax
f0100b0a:	e8 85 26 00 00       	call   f0103194 <memset>
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
f0100b25:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b2b:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
		assert(pp < pages + npages);
f0100b31:	a1 44 79 11 f0       	mov    0xf0117944,%eax
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
f0100b50:	68 7e 43 10 f0       	push   $0xf010437e
f0100b55:	68 8a 43 10 f0       	push   $0xf010438a
f0100b5a:	68 66 02 00 00       	push   $0x266
f0100b5f:	68 48 43 10 f0       	push   $0xf0104348
f0100b64:	e8 22 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b69:	39 fa                	cmp    %edi,%edx
f0100b6b:	72 19                	jb     f0100b86 <check_page_free_list+0x148>
f0100b6d:	68 9f 43 10 f0       	push   $0xf010439f
f0100b72:	68 8a 43 10 f0       	push   $0xf010438a
f0100b77:	68 67 02 00 00       	push   $0x267
f0100b7c:	68 48 43 10 f0       	push   $0xf0104348
f0100b81:	e8 05 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b86:	89 d0                	mov    %edx,%eax
f0100b88:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b8b:	a8 07                	test   $0x7,%al
f0100b8d:	74 19                	je     f0100ba8 <check_page_free_list+0x16a>
f0100b8f:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100b94:	68 8a 43 10 f0       	push   $0xf010438a
f0100b99:	68 68 02 00 00       	push   $0x268
f0100b9e:	68 48 43 10 f0       	push   $0xf0104348
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
f0100bb2:	68 b3 43 10 f0       	push   $0xf01043b3
f0100bb7:	68 8a 43 10 f0       	push   $0xf010438a
f0100bbc:	68 6b 02 00 00       	push   $0x26b
f0100bc1:	68 48 43 10 f0       	push   $0xf0104348
f0100bc6:	e8 c0 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bcb:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bd0:	75 19                	jne    f0100beb <check_page_free_list+0x1ad>
f0100bd2:	68 c4 43 10 f0       	push   $0xf01043c4
f0100bd7:	68 8a 43 10 f0       	push   $0xf010438a
f0100bdc:	68 6c 02 00 00       	push   $0x26c
f0100be1:	68 48 43 10 f0       	push   $0xf0104348
f0100be6:	e8 a0 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100beb:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bf0:	75 19                	jne    f0100c0b <check_page_free_list+0x1cd>
f0100bf2:	68 24 3c 10 f0       	push   $0xf0103c24
f0100bf7:	68 8a 43 10 f0       	push   $0xf010438a
f0100bfc:	68 6d 02 00 00       	push   $0x26d
f0100c01:	68 48 43 10 f0       	push   $0xf0104348
f0100c06:	e8 80 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c0b:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c10:	75 19                	jne    f0100c2b <check_page_free_list+0x1ed>
f0100c12:	68 dd 43 10 f0       	push   $0xf01043dd
f0100c17:	68 8a 43 10 f0       	push   $0xf010438a
f0100c1c:	68 6e 02 00 00       	push   $0x26e
f0100c21:	68 48 43 10 f0       	push   $0xf0104348
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
f0100c3d:	68 84 3b 10 f0       	push   $0xf0103b84
f0100c42:	6a 52                	push   $0x52
f0100c44:	68 70 43 10 f0       	push   $0xf0104370
f0100c49:	e8 3d f4 ff ff       	call   f010008b <_panic>
f0100c4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c53:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c56:	76 1e                	jbe    f0100c76 <check_page_free_list+0x238>
f0100c58:	68 48 3c 10 f0       	push   $0xf0103c48
f0100c5d:	68 8a 43 10 f0       	push   $0xf010438a
f0100c62:	68 6f 02 00 00       	push   $0x26f
f0100c67:	68 48 43 10 f0       	push   $0xf0104348
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
f0100c8b:	68 f7 43 10 f0       	push   $0xf01043f7
f0100c90:	68 8a 43 10 f0       	push   $0xf010438a
f0100c95:	68 77 02 00 00       	push   $0x277
f0100c9a:	68 48 43 10 f0       	push   $0xf0104348
f0100c9f:	e8 e7 f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100ca4:	85 db                	test   %ebx,%ebx
f0100ca6:	7f 19                	jg     f0100cc1 <check_page_free_list+0x283>
f0100ca8:	68 09 44 10 f0       	push   $0xf0104409
f0100cad:	68 8a 43 10 f0       	push   $0xf010438a
f0100cb2:	68 78 02 00 00       	push   $0x278
f0100cb7:	68 48 43 10 f0       	push   $0xf0104348
f0100cbc:	e8 ca f3 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100cc1:	83 ec 0c             	sub    $0xc,%esp
f0100cc4:	68 90 3c 10 f0       	push   $0xf0103c90
f0100cc9:	e8 0d 1a 00 00       	call   f01026db <cprintf>
}
f0100cce:	eb 29                	jmp    f0100cf9 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cd0:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100cd5:	85 c0                	test   %eax,%eax
f0100cd7:	0f 85 8e fd ff ff    	jne    f0100a6b <check_page_free_list+0x2d>
f0100cdd:	e9 72 fd ff ff       	jmp    f0100a54 <check_page_free_list+0x16>
f0100ce2:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
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
f0100d0a:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
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
f0100d36:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
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
f0100d5e:	68 a8 3b 10 f0       	push   $0xf0103ba8
f0100d63:	68 17 01 00 00       	push   $0x117
f0100d68:	68 48 43 10 f0       	push   $0xf0104348
f0100d6d:	e8 19 f3 ff ff       	call   f010008b <_panic>
f0100d72:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d77:	39 d8                	cmp    %ebx,%eax
f0100d79:	76 0e                	jbe    f0100d89 <page_init+0x88>
		{
			pages[i].pp_ref = 1;
f0100d7b:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100d80:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100d87:	eb 23                	jmp    f0100dac <page_init+0xab>
		}

		pages[i].pp_ref = 0;  
f0100d89:	89 f0                	mov    %esi,%eax
f0100d8b:	03 05 4c 79 11 f0    	add    0xf011794c,%eax
f0100d91:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d97:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d9d:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100d9f:	89 f0                	mov    %esi,%eax
f0100da1:	03 05 4c 79 11 f0    	add    0xf011794c,%eax
f0100da7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages; i++) 
f0100dac:	83 c7 01             	add    $0x1,%edi
f0100daf:	83 c6 08             	add    $0x8,%esi
f0100db2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100db8:	3b 3d 44 79 11 f0    	cmp    0xf0117944,%edi
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
f0100dd3:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100dd9:	85 db                	test   %ebx,%ebx
f0100ddb:	74 58                	je     f0100e35 <page_alloc+0x69>
	{
		page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100ddd:	8b 03                	mov    (%ebx),%eax
f0100ddf:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
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
f0100df2:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100df8:	c1 f8 03             	sar    $0x3,%eax
f0100dfb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dfe:	89 c2                	mov    %eax,%edx
f0100e00:	c1 ea 0c             	shr    $0xc,%edx
f0100e03:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100e09:	72 12                	jb     f0100e1d <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e0b:	50                   	push   %eax
f0100e0c:	68 84 3b 10 f0       	push   $0xf0103b84
f0100e11:	6a 52                	push   $0x52
f0100e13:	68 70 43 10 f0       	push   $0xf0104370
f0100e18:	e8 6e f2 ff ff       	call   f010008b <_panic>
		{
			memset(page2kva(page), '\0', PGSIZE);
f0100e1d:	83 ec 04             	sub    $0x4,%esp
f0100e20:	68 00 10 00 00       	push   $0x1000
f0100e25:	6a 00                	push   $0x0
f0100e27:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e2c:	50                   	push   %eax
f0100e2d:	e8 62 23 00 00       	call   f0103194 <memset>
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
f0100e54:	68 b4 3c 10 f0       	push   $0xf0103cb4
f0100e59:	68 51 01 00 00       	push   $0x151
f0100e5e:	68 48 43 10 f0       	push   $0xf0104348
f0100e63:	e8 23 f2 ff ff       	call   f010008b <_panic>
	}	

	pp->pp_link = page_free_list;
f0100e68:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e6e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;	
f0100e70:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
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
f0100edb:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
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
f0100ef8:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100efe:	72 15                	jb     f0100f15 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f00:	50                   	push   %eax
f0100f01:	68 84 3b 10 f0       	push   $0xf0103b84
f0100f06:	68 97 01 00 00       	push   $0x197
f0100f0b:	68 48 43 10 f0       	push   $0xf0104348
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

f0100f31 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f31:	55                   	push   %ebp
f0100f32:	89 e5                	mov    %esp,%ebp
f0100f34:	57                   	push   %edi
f0100f35:	56                   	push   %esi
f0100f36:	53                   	push   %ebx
f0100f37:	83 ec 1c             	sub    $0x1c,%esp
f0100f3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f3d:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pte_t *ptable;
	size_t i = 0;
	for(i; i < size / PGSIZE; ++i)
f0100f40:	c1 e9 0c             	shr    $0xc,%ecx
f0100f43:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f46:	89 c3                	mov    %eax,%ebx
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *ptable;
	size_t i = 0;
f0100f48:	be 00 00 00 00       	mov    $0x0,%esi
	for(i; i < size / PGSIZE; ++i)
	{
		ptable = pgdir_walk(pgdir, (void *) va, 1);
f0100f4d:	89 d7                	mov    %edx,%edi
f0100f4f:	29 c7                	sub    %eax,%edi
		if(ptable == NULL)
		{
			panic("boot_map_region out of memory!\n");
		}

		*ptable = pa | perm | PTE_P;
f0100f51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f54:	83 c8 01             	or     $0x1,%eax
f0100f57:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *ptable;
	size_t i = 0;
	for(i; i < size / PGSIZE; ++i)
f0100f5a:	eb 3f                	jmp    f0100f9b <boot_map_region+0x6a>
	{
		ptable = pgdir_walk(pgdir, (void *) va, 1);
f0100f5c:	83 ec 04             	sub    $0x4,%esp
f0100f5f:	6a 01                	push   $0x1
f0100f61:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f64:	50                   	push   %eax
f0100f65:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f68:	e8 31 ff ff ff       	call   f0100e9e <pgdir_walk>
		
		if(ptable == NULL)
f0100f6d:	83 c4 10             	add    $0x10,%esp
f0100f70:	85 c0                	test   %eax,%eax
f0100f72:	75 17                	jne    f0100f8b <boot_map_region+0x5a>
		{
			panic("boot_map_region out of memory!\n");
f0100f74:	83 ec 04             	sub    $0x4,%esp
f0100f77:	68 0c 3d 10 f0       	push   $0xf0103d0c
f0100f7c:	68 b2 01 00 00       	push   $0x1b2
f0100f81:	68 48 43 10 f0       	push   $0xf0104348
f0100f86:	e8 00 f1 ff ff       	call   f010008b <_panic>
		}

		*ptable = pa | perm | PTE_P;
f0100f8b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f8e:	09 da                	or     %ebx,%edx
f0100f90:	89 10                	mov    %edx,(%eax)
		
		va += PGSIZE;
		pa += PGSIZE;
f0100f92:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *ptable;
	size_t i = 0;
	for(i; i < size / PGSIZE; ++i)
f0100f98:	83 c6 01             	add    $0x1,%esi
f0100f9b:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f9e:	75 bc                	jne    f0100f5c <boot_map_region+0x2b>
		*ptable = pa | perm | PTE_P;
		
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100fa0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fa3:	5b                   	pop    %ebx
f0100fa4:	5e                   	pop    %esi
f0100fa5:	5f                   	pop    %edi
f0100fa6:	5d                   	pop    %ebp
f0100fa7:	c3                   	ret    

f0100fa8 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fa8:	55                   	push   %ebp
f0100fa9:	89 e5                	mov    %esp,%ebp
f0100fab:	53                   	push   %ebx
f0100fac:	83 ec 08             	sub    $0x8,%esp
f0100faf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0); // only lookup
f0100fb2:	6a 00                	push   $0x0
f0100fb4:	ff 75 0c             	pushl  0xc(%ebp)
f0100fb7:	ff 75 08             	pushl  0x8(%ebp)
f0100fba:	e8 df fe ff ff       	call   f0100e9e <pgdir_walk>
	
	if(pte == NULL)
f0100fbf:	83 c4 10             	add    $0x10,%esp
f0100fc2:	85 c0                	test   %eax,%eax
f0100fc4:	74 32                	je     f0100ff8 <page_lookup+0x50>
	{
		return NULL;
	}
	
	if(pte_store != NULL)
f0100fc6:	85 db                	test   %ebx,%ebx
f0100fc8:	74 02                	je     f0100fcc <page_lookup+0x24>
	{
		*pte_store = pte;
f0100fca:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcc:	8b 00                	mov    (%eax),%eax
f0100fce:	c1 e8 0c             	shr    $0xc,%eax
f0100fd1:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0100fd7:	72 14                	jb     f0100fed <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fd9:	83 ec 04             	sub    $0x4,%esp
f0100fdc:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0100fe1:	6a 4b                	push   $0x4b
f0100fe3:	68 70 43 10 f0       	push   $0xf0104370
f0100fe8:	e8 9e f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fed:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f0100ff3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	
	return (struct PageInfo*) pa2page(PTE_ADDR(*pte));
f0100ff6:	eb 05                	jmp    f0100ffd <page_lookup+0x55>
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 0); // only lookup
	
	if(pte == NULL)
	{
		return NULL;
f0100ff8:	b8 00 00 00 00       	mov    $0x0,%eax
		*pte_store = pte;
	}
	
	return (struct PageInfo*) pa2page(PTE_ADDR(*pte));

}
f0100ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101000:	c9                   	leave  
f0101001:	c3                   	ret    

f0101002 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101002:	55                   	push   %ebp
f0101003:	89 e5                	mov    %esp,%ebp
f0101005:	53                   	push   %ebx
f0101006:	83 ec 18             	sub    $0x18,%esp
f0101009:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pg = page_lookup(pgdir, va, &pte);
f010100c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010100f:	50                   	push   %eax
f0101010:	53                   	push   %ebx
f0101011:	ff 75 08             	pushl  0x8(%ebp)
f0101014:	e8 8f ff ff ff       	call   f0100fa8 <page_lookup>
	
	if((pg == NULL) || !(*pte & PTE_P))
f0101019:	83 c4 10             	add    $0x10,%esp
f010101c:	85 c0                	test   %eax,%eax
f010101e:	74 20                	je     f0101040 <page_remove+0x3e>
f0101020:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101023:	f6 02 01             	testb  $0x1,(%edx)
f0101026:	74 18                	je     f0101040 <page_remove+0x3e>
	{
		return;
	}

	page_decref(pg);
f0101028:	83 ec 0c             	sub    $0xc,%esp
f010102b:	50                   	push   %eax
f010102c:	e8 46 fe ff ff       	call   f0100e77 <page_decref>
	
	*pte = 0;
f0101031:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101034:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010103a:	0f 01 3b             	invlpg (%ebx)
f010103d:	83 c4 10             	add    $0x10,%esp
	
	tlb_invalidate(pgdir, va);

}
f0101040:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101043:	c9                   	leave  
f0101044:	c3                   	ret    

f0101045 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101045:	55                   	push   %ebp
f0101046:	89 e5                	mov    %esp,%ebp
f0101048:	57                   	push   %edi
f0101049:	56                   	push   %esi
f010104a:	53                   	push   %ebx
f010104b:	83 ec 10             	sub    $0x10,%esp
f010104e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101051:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f0101054:	6a 01                	push   $0x1
f0101056:	56                   	push   %esi
f0101057:	ff 75 08             	pushl  0x8(%ebp)
f010105a:	e8 3f fe ff ff       	call   f0100e9e <pgdir_walk>
	
	if(pte == NULL)
f010105f:	83 c4 10             	add    $0x10,%esp
f0101062:	85 c0                	test   %eax,%eax
f0101064:	74 3b                	je     f01010a1 <page_insert+0x5c>
f0101066:	89 c7                	mov    %eax,%edi
	{
		return -E_NO_MEM;
	}

	pp->pp_ref++;
f0101068:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

	if(*pte & PTE_P)
f010106d:	f6 00 01             	testb  $0x1,(%eax)
f0101070:	74 12                	je     f0101084 <page_insert+0x3f>
f0101072:	0f 01 3e             	invlpg (%esi)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0101075:	83 ec 08             	sub    $0x8,%esp
f0101078:	56                   	push   %esi
f0101079:	ff 75 08             	pushl  0x8(%ebp)
f010107c:	e8 81 ff ff ff       	call   f0101002 <page_remove>
f0101081:	83 c4 10             	add    $0x10,%esp
	}

	*pte = page2pa(pp) | perm | PTE_P;
f0101084:	2b 1d 4c 79 11 f0    	sub    0xf011794c,%ebx
f010108a:	c1 fb 03             	sar    $0x3,%ebx
f010108d:	c1 e3 0c             	shl    $0xc,%ebx
f0101090:	8b 45 14             	mov    0x14(%ebp),%eax
f0101093:	83 c8 01             	or     $0x1,%eax
f0101096:	09 c3                	or     %eax,%ebx
f0101098:	89 1f                	mov    %ebx,(%edi)
	
	return 0;
f010109a:	b8 00 00 00 00       	mov    $0x0,%eax
f010109f:	eb 05                	jmp    f01010a6 <page_insert+0x61>
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
	
	if(pte == NULL)
	{
		return -E_NO_MEM;
f01010a1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*pte = page2pa(pp) | perm | PTE_P;
	
	return 0;
}
f01010a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010a9:	5b                   	pop    %ebx
f01010aa:	5e                   	pop    %esi
f01010ab:	5f                   	pop    %edi
f01010ac:	5d                   	pop    %ebp
f01010ad:	c3                   	ret    

f01010ae <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010ae:	55                   	push   %ebp
f01010af:	89 e5                	mov    %esp,%ebp
f01010b1:	57                   	push   %edi
f01010b2:	56                   	push   %esi
f01010b3:	53                   	push   %ebx
f01010b4:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010b7:	b8 15 00 00 00       	mov    $0x15,%eax
f01010bc:	e8 67 f8 ff ff       	call   f0100928 <nvram_read>
f01010c1:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010c3:	b8 17 00 00 00       	mov    $0x17,%eax
f01010c8:	e8 5b f8 ff ff       	call   f0100928 <nvram_read>
f01010cd:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010cf:	b8 34 00 00 00       	mov    $0x34,%eax
f01010d4:	e8 4f f8 ff ff       	call   f0100928 <nvram_read>
f01010d9:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010dc:	85 c0                	test   %eax,%eax
f01010de:	74 07                	je     f01010e7 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010e0:	05 00 40 00 00       	add    $0x4000,%eax
f01010e5:	eb 0b                	jmp    f01010f2 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010e7:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010ed:	85 f6                	test   %esi,%esi
f01010ef:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010f2:	89 c2                	mov    %eax,%edx
f01010f4:	c1 ea 02             	shr    $0x2,%edx
f01010f7:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010fd:	89 c2                	mov    %eax,%edx
f01010ff:	29 da                	sub    %ebx,%edx
f0101101:	52                   	push   %edx
f0101102:	53                   	push   %ebx
f0101103:	50                   	push   %eax
f0101104:	68 4c 3d 10 f0       	push   $0xf0103d4c
f0101109:	e8 cd 15 00 00       	call   f01026db <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010110e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101113:	e8 9d f8 ff ff       	call   f01009b5 <boot_alloc>
f0101118:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f010111d:	83 c4 0c             	add    $0xc,%esp
f0101120:	68 00 10 00 00       	push   $0x1000
f0101125:	6a 00                	push   $0x0
f0101127:	50                   	push   %eax
f0101128:	e8 67 20 00 00       	call   f0103194 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010112d:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101132:	83 c4 10             	add    $0x10,%esp
f0101135:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010113a:	77 15                	ja     f0101151 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010113c:	50                   	push   %eax
f010113d:	68 a8 3b 10 f0       	push   $0xf0103ba8
f0101142:	68 9a 00 00 00       	push   $0x9a
f0101147:	68 48 43 10 f0       	push   $0xf0104348
f010114c:	e8 3a ef ff ff       	call   f010008b <_panic>
f0101151:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101157:	83 ca 05             	or     $0x5,%edx
f010115a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101160:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0101165:	c1 e0 03             	shl    $0x3,%eax
f0101168:	e8 48 f8 ff ff       	call   f01009b5 <boot_alloc>
f010116d:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f0101172:	83 ec 04             	sub    $0x4,%esp
f0101175:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f010117b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101182:	52                   	push   %edx
f0101183:	6a 00                	push   $0x0
f0101185:	50                   	push   %eax
f0101186:	e8 09 20 00 00       	call   f0103194 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010118b:	e8 71 fb ff ff       	call   f0100d01 <page_init>

	check_page_free_list(1);
f0101190:	b8 01 00 00 00       	mov    $0x1,%eax
f0101195:	e8 a4 f8 ff ff       	call   f0100a3e <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010119a:	83 c4 10             	add    $0x10,%esp
f010119d:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01011a4:	75 17                	jne    f01011bd <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f01011a6:	83 ec 04             	sub    $0x4,%esp
f01011a9:	68 1a 44 10 f0       	push   $0xf010441a
f01011ae:	68 8b 02 00 00       	push   $0x28b
f01011b3:	68 48 43 10 f0       	push   $0xf0104348
f01011b8:	e8 ce ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011bd:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011c2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011c7:	eb 05                	jmp    f01011ce <mem_init+0x120>
		++nfree;
f01011c9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011cc:	8b 00                	mov    (%eax),%eax
f01011ce:	85 c0                	test   %eax,%eax
f01011d0:	75 f7                	jne    f01011c9 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011d2:	83 ec 0c             	sub    $0xc,%esp
f01011d5:	6a 00                	push   $0x0
f01011d7:	e8 f0 fb ff ff       	call   f0100dcc <page_alloc>
f01011dc:	89 c7                	mov    %eax,%edi
f01011de:	83 c4 10             	add    $0x10,%esp
f01011e1:	85 c0                	test   %eax,%eax
f01011e3:	75 19                	jne    f01011fe <mem_init+0x150>
f01011e5:	68 35 44 10 f0       	push   $0xf0104435
f01011ea:	68 8a 43 10 f0       	push   $0xf010438a
f01011ef:	68 93 02 00 00       	push   $0x293
f01011f4:	68 48 43 10 f0       	push   $0xf0104348
f01011f9:	e8 8d ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011fe:	83 ec 0c             	sub    $0xc,%esp
f0101201:	6a 00                	push   $0x0
f0101203:	e8 c4 fb ff ff       	call   f0100dcc <page_alloc>
f0101208:	89 c6                	mov    %eax,%esi
f010120a:	83 c4 10             	add    $0x10,%esp
f010120d:	85 c0                	test   %eax,%eax
f010120f:	75 19                	jne    f010122a <mem_init+0x17c>
f0101211:	68 4b 44 10 f0       	push   $0xf010444b
f0101216:	68 8a 43 10 f0       	push   $0xf010438a
f010121b:	68 94 02 00 00       	push   $0x294
f0101220:	68 48 43 10 f0       	push   $0xf0104348
f0101225:	e8 61 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010122a:	83 ec 0c             	sub    $0xc,%esp
f010122d:	6a 00                	push   $0x0
f010122f:	e8 98 fb ff ff       	call   f0100dcc <page_alloc>
f0101234:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101237:	83 c4 10             	add    $0x10,%esp
f010123a:	85 c0                	test   %eax,%eax
f010123c:	75 19                	jne    f0101257 <mem_init+0x1a9>
f010123e:	68 61 44 10 f0       	push   $0xf0104461
f0101243:	68 8a 43 10 f0       	push   $0xf010438a
f0101248:	68 95 02 00 00       	push   $0x295
f010124d:	68 48 43 10 f0       	push   $0xf0104348
f0101252:	e8 34 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101257:	39 f7                	cmp    %esi,%edi
f0101259:	75 19                	jne    f0101274 <mem_init+0x1c6>
f010125b:	68 77 44 10 f0       	push   $0xf0104477
f0101260:	68 8a 43 10 f0       	push   $0xf010438a
f0101265:	68 98 02 00 00       	push   $0x298
f010126a:	68 48 43 10 f0       	push   $0xf0104348
f010126f:	e8 17 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101274:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101277:	39 c6                	cmp    %eax,%esi
f0101279:	74 04                	je     f010127f <mem_init+0x1d1>
f010127b:	39 c7                	cmp    %eax,%edi
f010127d:	75 19                	jne    f0101298 <mem_init+0x1ea>
f010127f:	68 88 3d 10 f0       	push   $0xf0103d88
f0101284:	68 8a 43 10 f0       	push   $0xf010438a
f0101289:	68 99 02 00 00       	push   $0x299
f010128e:	68 48 43 10 f0       	push   $0xf0104348
f0101293:	e8 f3 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101298:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010129e:	8b 15 44 79 11 f0    	mov    0xf0117944,%edx
f01012a4:	c1 e2 0c             	shl    $0xc,%edx
f01012a7:	89 f8                	mov    %edi,%eax
f01012a9:	29 c8                	sub    %ecx,%eax
f01012ab:	c1 f8 03             	sar    $0x3,%eax
f01012ae:	c1 e0 0c             	shl    $0xc,%eax
f01012b1:	39 d0                	cmp    %edx,%eax
f01012b3:	72 19                	jb     f01012ce <mem_init+0x220>
f01012b5:	68 89 44 10 f0       	push   $0xf0104489
f01012ba:	68 8a 43 10 f0       	push   $0xf010438a
f01012bf:	68 9a 02 00 00       	push   $0x29a
f01012c4:	68 48 43 10 f0       	push   $0xf0104348
f01012c9:	e8 bd ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012ce:	89 f0                	mov    %esi,%eax
f01012d0:	29 c8                	sub    %ecx,%eax
f01012d2:	c1 f8 03             	sar    $0x3,%eax
f01012d5:	c1 e0 0c             	shl    $0xc,%eax
f01012d8:	39 c2                	cmp    %eax,%edx
f01012da:	77 19                	ja     f01012f5 <mem_init+0x247>
f01012dc:	68 a6 44 10 f0       	push   $0xf01044a6
f01012e1:	68 8a 43 10 f0       	push   $0xf010438a
f01012e6:	68 9b 02 00 00       	push   $0x29b
f01012eb:	68 48 43 10 f0       	push   $0xf0104348
f01012f0:	e8 96 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012f8:	29 c8                	sub    %ecx,%eax
f01012fa:	c1 f8 03             	sar    $0x3,%eax
f01012fd:	c1 e0 0c             	shl    $0xc,%eax
f0101300:	39 c2                	cmp    %eax,%edx
f0101302:	77 19                	ja     f010131d <mem_init+0x26f>
f0101304:	68 c3 44 10 f0       	push   $0xf01044c3
f0101309:	68 8a 43 10 f0       	push   $0xf010438a
f010130e:	68 9c 02 00 00       	push   $0x29c
f0101313:	68 48 43 10 f0       	push   $0xf0104348
f0101318:	e8 6e ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010131d:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101322:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101325:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010132c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010132f:	83 ec 0c             	sub    $0xc,%esp
f0101332:	6a 00                	push   $0x0
f0101334:	e8 93 fa ff ff       	call   f0100dcc <page_alloc>
f0101339:	83 c4 10             	add    $0x10,%esp
f010133c:	85 c0                	test   %eax,%eax
f010133e:	74 19                	je     f0101359 <mem_init+0x2ab>
f0101340:	68 e0 44 10 f0       	push   $0xf01044e0
f0101345:	68 8a 43 10 f0       	push   $0xf010438a
f010134a:	68 a3 02 00 00       	push   $0x2a3
f010134f:	68 48 43 10 f0       	push   $0xf0104348
f0101354:	e8 32 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101359:	83 ec 0c             	sub    $0xc,%esp
f010135c:	57                   	push   %edi
f010135d:	e8 da fa ff ff       	call   f0100e3c <page_free>
	page_free(pp1);
f0101362:	89 34 24             	mov    %esi,(%esp)
f0101365:	e8 d2 fa ff ff       	call   f0100e3c <page_free>
	page_free(pp2);
f010136a:	83 c4 04             	add    $0x4,%esp
f010136d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101370:	e8 c7 fa ff ff       	call   f0100e3c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101375:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010137c:	e8 4b fa ff ff       	call   f0100dcc <page_alloc>
f0101381:	89 c6                	mov    %eax,%esi
f0101383:	83 c4 10             	add    $0x10,%esp
f0101386:	85 c0                	test   %eax,%eax
f0101388:	75 19                	jne    f01013a3 <mem_init+0x2f5>
f010138a:	68 35 44 10 f0       	push   $0xf0104435
f010138f:	68 8a 43 10 f0       	push   $0xf010438a
f0101394:	68 aa 02 00 00       	push   $0x2aa
f0101399:	68 48 43 10 f0       	push   $0xf0104348
f010139e:	e8 e8 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013a3:	83 ec 0c             	sub    $0xc,%esp
f01013a6:	6a 00                	push   $0x0
f01013a8:	e8 1f fa ff ff       	call   f0100dcc <page_alloc>
f01013ad:	89 c7                	mov    %eax,%edi
f01013af:	83 c4 10             	add    $0x10,%esp
f01013b2:	85 c0                	test   %eax,%eax
f01013b4:	75 19                	jne    f01013cf <mem_init+0x321>
f01013b6:	68 4b 44 10 f0       	push   $0xf010444b
f01013bb:	68 8a 43 10 f0       	push   $0xf010438a
f01013c0:	68 ab 02 00 00       	push   $0x2ab
f01013c5:	68 48 43 10 f0       	push   $0xf0104348
f01013ca:	e8 bc ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013cf:	83 ec 0c             	sub    $0xc,%esp
f01013d2:	6a 00                	push   $0x0
f01013d4:	e8 f3 f9 ff ff       	call   f0100dcc <page_alloc>
f01013d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013dc:	83 c4 10             	add    $0x10,%esp
f01013df:	85 c0                	test   %eax,%eax
f01013e1:	75 19                	jne    f01013fc <mem_init+0x34e>
f01013e3:	68 61 44 10 f0       	push   $0xf0104461
f01013e8:	68 8a 43 10 f0       	push   $0xf010438a
f01013ed:	68 ac 02 00 00       	push   $0x2ac
f01013f2:	68 48 43 10 f0       	push   $0xf0104348
f01013f7:	e8 8f ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013fc:	39 fe                	cmp    %edi,%esi
f01013fe:	75 19                	jne    f0101419 <mem_init+0x36b>
f0101400:	68 77 44 10 f0       	push   $0xf0104477
f0101405:	68 8a 43 10 f0       	push   $0xf010438a
f010140a:	68 ae 02 00 00       	push   $0x2ae
f010140f:	68 48 43 10 f0       	push   $0xf0104348
f0101414:	e8 72 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101419:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010141c:	39 c6                	cmp    %eax,%esi
f010141e:	74 04                	je     f0101424 <mem_init+0x376>
f0101420:	39 c7                	cmp    %eax,%edi
f0101422:	75 19                	jne    f010143d <mem_init+0x38f>
f0101424:	68 88 3d 10 f0       	push   $0xf0103d88
f0101429:	68 8a 43 10 f0       	push   $0xf010438a
f010142e:	68 af 02 00 00       	push   $0x2af
f0101433:	68 48 43 10 f0       	push   $0xf0104348
f0101438:	e8 4e ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010143d:	83 ec 0c             	sub    $0xc,%esp
f0101440:	6a 00                	push   $0x0
f0101442:	e8 85 f9 ff ff       	call   f0100dcc <page_alloc>
f0101447:	83 c4 10             	add    $0x10,%esp
f010144a:	85 c0                	test   %eax,%eax
f010144c:	74 19                	je     f0101467 <mem_init+0x3b9>
f010144e:	68 e0 44 10 f0       	push   $0xf01044e0
f0101453:	68 8a 43 10 f0       	push   $0xf010438a
f0101458:	68 b0 02 00 00       	push   $0x2b0
f010145d:	68 48 43 10 f0       	push   $0xf0104348
f0101462:	e8 24 ec ff ff       	call   f010008b <_panic>
f0101467:	89 f0                	mov    %esi,%eax
f0101469:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010146f:	c1 f8 03             	sar    $0x3,%eax
f0101472:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101475:	89 c2                	mov    %eax,%edx
f0101477:	c1 ea 0c             	shr    $0xc,%edx
f010147a:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0101480:	72 12                	jb     f0101494 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101482:	50                   	push   %eax
f0101483:	68 84 3b 10 f0       	push   $0xf0103b84
f0101488:	6a 52                	push   $0x52
f010148a:	68 70 43 10 f0       	push   $0xf0104370
f010148f:	e8 f7 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101494:	83 ec 04             	sub    $0x4,%esp
f0101497:	68 00 10 00 00       	push   $0x1000
f010149c:	6a 01                	push   $0x1
f010149e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014a3:	50                   	push   %eax
f01014a4:	e8 eb 1c 00 00       	call   f0103194 <memset>
	page_free(pp0);
f01014a9:	89 34 24             	mov    %esi,(%esp)
f01014ac:	e8 8b f9 ff ff       	call   f0100e3c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014b8:	e8 0f f9 ff ff       	call   f0100dcc <page_alloc>
f01014bd:	83 c4 10             	add    $0x10,%esp
f01014c0:	85 c0                	test   %eax,%eax
f01014c2:	75 19                	jne    f01014dd <mem_init+0x42f>
f01014c4:	68 ef 44 10 f0       	push   $0xf01044ef
f01014c9:	68 8a 43 10 f0       	push   $0xf010438a
f01014ce:	68 b5 02 00 00       	push   $0x2b5
f01014d3:	68 48 43 10 f0       	push   $0xf0104348
f01014d8:	e8 ae eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014dd:	39 c6                	cmp    %eax,%esi
f01014df:	74 19                	je     f01014fa <mem_init+0x44c>
f01014e1:	68 0d 45 10 f0       	push   $0xf010450d
f01014e6:	68 8a 43 10 f0       	push   $0xf010438a
f01014eb:	68 b6 02 00 00       	push   $0x2b6
f01014f0:	68 48 43 10 f0       	push   $0xf0104348
f01014f5:	e8 91 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014fa:	89 f0                	mov    %esi,%eax
f01014fc:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101502:	c1 f8 03             	sar    $0x3,%eax
f0101505:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101508:	89 c2                	mov    %eax,%edx
f010150a:	c1 ea 0c             	shr    $0xc,%edx
f010150d:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0101513:	72 12                	jb     f0101527 <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101515:	50                   	push   %eax
f0101516:	68 84 3b 10 f0       	push   $0xf0103b84
f010151b:	6a 52                	push   $0x52
f010151d:	68 70 43 10 f0       	push   $0xf0104370
f0101522:	e8 64 eb ff ff       	call   f010008b <_panic>
f0101527:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010152d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101533:	80 38 00             	cmpb   $0x0,(%eax)
f0101536:	74 19                	je     f0101551 <mem_init+0x4a3>
f0101538:	68 1d 45 10 f0       	push   $0xf010451d
f010153d:	68 8a 43 10 f0       	push   $0xf010438a
f0101542:	68 b9 02 00 00       	push   $0x2b9
f0101547:	68 48 43 10 f0       	push   $0xf0104348
f010154c:	e8 3a eb ff ff       	call   f010008b <_panic>
f0101551:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101554:	39 d0                	cmp    %edx,%eax
f0101556:	75 db                	jne    f0101533 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101558:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010155b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101560:	83 ec 0c             	sub    $0xc,%esp
f0101563:	56                   	push   %esi
f0101564:	e8 d3 f8 ff ff       	call   f0100e3c <page_free>
	page_free(pp1);
f0101569:	89 3c 24             	mov    %edi,(%esp)
f010156c:	e8 cb f8 ff ff       	call   f0100e3c <page_free>
	page_free(pp2);
f0101571:	83 c4 04             	add    $0x4,%esp
f0101574:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101577:	e8 c0 f8 ff ff       	call   f0100e3c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010157c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101581:	83 c4 10             	add    $0x10,%esp
f0101584:	eb 05                	jmp    f010158b <mem_init+0x4dd>
		--nfree;
f0101586:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101589:	8b 00                	mov    (%eax),%eax
f010158b:	85 c0                	test   %eax,%eax
f010158d:	75 f7                	jne    f0101586 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f010158f:	85 db                	test   %ebx,%ebx
f0101591:	74 19                	je     f01015ac <mem_init+0x4fe>
f0101593:	68 27 45 10 f0       	push   $0xf0104527
f0101598:	68 8a 43 10 f0       	push   $0xf010438a
f010159d:	68 c6 02 00 00       	push   $0x2c6
f01015a2:	68 48 43 10 f0       	push   $0xf0104348
f01015a7:	e8 df ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015ac:	83 ec 0c             	sub    $0xc,%esp
f01015af:	68 a8 3d 10 f0       	push   $0xf0103da8
f01015b4:	e8 22 11 00 00       	call   f01026db <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c0:	e8 07 f8 ff ff       	call   f0100dcc <page_alloc>
f01015c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c8:	83 c4 10             	add    $0x10,%esp
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	75 19                	jne    f01015e8 <mem_init+0x53a>
f01015cf:	68 35 44 10 f0       	push   $0xf0104435
f01015d4:	68 8a 43 10 f0       	push   $0xf010438a
f01015d9:	68 1f 03 00 00       	push   $0x31f
f01015de:	68 48 43 10 f0       	push   $0xf0104348
f01015e3:	e8 a3 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015e8:	83 ec 0c             	sub    $0xc,%esp
f01015eb:	6a 00                	push   $0x0
f01015ed:	e8 da f7 ff ff       	call   f0100dcc <page_alloc>
f01015f2:	89 c3                	mov    %eax,%ebx
f01015f4:	83 c4 10             	add    $0x10,%esp
f01015f7:	85 c0                	test   %eax,%eax
f01015f9:	75 19                	jne    f0101614 <mem_init+0x566>
f01015fb:	68 4b 44 10 f0       	push   $0xf010444b
f0101600:	68 8a 43 10 f0       	push   $0xf010438a
f0101605:	68 20 03 00 00       	push   $0x320
f010160a:	68 48 43 10 f0       	push   $0xf0104348
f010160f:	e8 77 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101614:	83 ec 0c             	sub    $0xc,%esp
f0101617:	6a 00                	push   $0x0
f0101619:	e8 ae f7 ff ff       	call   f0100dcc <page_alloc>
f010161e:	89 c6                	mov    %eax,%esi
f0101620:	83 c4 10             	add    $0x10,%esp
f0101623:	85 c0                	test   %eax,%eax
f0101625:	75 19                	jne    f0101640 <mem_init+0x592>
f0101627:	68 61 44 10 f0       	push   $0xf0104461
f010162c:	68 8a 43 10 f0       	push   $0xf010438a
f0101631:	68 21 03 00 00       	push   $0x321
f0101636:	68 48 43 10 f0       	push   $0xf0104348
f010163b:	e8 4b ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101640:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101643:	75 19                	jne    f010165e <mem_init+0x5b0>
f0101645:	68 77 44 10 f0       	push   $0xf0104477
f010164a:	68 8a 43 10 f0       	push   $0xf010438a
f010164f:	68 24 03 00 00       	push   $0x324
f0101654:	68 48 43 10 f0       	push   $0xf0104348
f0101659:	e8 2d ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010165e:	39 c3                	cmp    %eax,%ebx
f0101660:	74 05                	je     f0101667 <mem_init+0x5b9>
f0101662:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101665:	75 19                	jne    f0101680 <mem_init+0x5d2>
f0101667:	68 88 3d 10 f0       	push   $0xf0103d88
f010166c:	68 8a 43 10 f0       	push   $0xf010438a
f0101671:	68 25 03 00 00       	push   $0x325
f0101676:	68 48 43 10 f0       	push   $0xf0104348
f010167b:	e8 0b ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101680:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101685:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101688:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010168f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101692:	83 ec 0c             	sub    $0xc,%esp
f0101695:	6a 00                	push   $0x0
f0101697:	e8 30 f7 ff ff       	call   f0100dcc <page_alloc>
f010169c:	83 c4 10             	add    $0x10,%esp
f010169f:	85 c0                	test   %eax,%eax
f01016a1:	74 19                	je     f01016bc <mem_init+0x60e>
f01016a3:	68 e0 44 10 f0       	push   $0xf01044e0
f01016a8:	68 8a 43 10 f0       	push   $0xf010438a
f01016ad:	68 2c 03 00 00       	push   $0x32c
f01016b2:	68 48 43 10 f0       	push   $0xf0104348
f01016b7:	e8 cf e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016bc:	83 ec 04             	sub    $0x4,%esp
f01016bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016c2:	50                   	push   %eax
f01016c3:	6a 00                	push   $0x0
f01016c5:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01016cb:	e8 d8 f8 ff ff       	call   f0100fa8 <page_lookup>
f01016d0:	83 c4 10             	add    $0x10,%esp
f01016d3:	85 c0                	test   %eax,%eax
f01016d5:	74 19                	je     f01016f0 <mem_init+0x642>
f01016d7:	68 c8 3d 10 f0       	push   $0xf0103dc8
f01016dc:	68 8a 43 10 f0       	push   $0xf010438a
f01016e1:	68 2f 03 00 00       	push   $0x32f
f01016e6:	68 48 43 10 f0       	push   $0xf0104348
f01016eb:	e8 9b e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016f0:	6a 02                	push   $0x2
f01016f2:	6a 00                	push   $0x0
f01016f4:	53                   	push   %ebx
f01016f5:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01016fb:	e8 45 f9 ff ff       	call   f0101045 <page_insert>
f0101700:	83 c4 10             	add    $0x10,%esp
f0101703:	85 c0                	test   %eax,%eax
f0101705:	78 19                	js     f0101720 <mem_init+0x672>
f0101707:	68 00 3e 10 f0       	push   $0xf0103e00
f010170c:	68 8a 43 10 f0       	push   $0xf010438a
f0101711:	68 32 03 00 00       	push   $0x332
f0101716:	68 48 43 10 f0       	push   $0xf0104348
f010171b:	e8 6b e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101720:	83 ec 0c             	sub    $0xc,%esp
f0101723:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101726:	e8 11 f7 ff ff       	call   f0100e3c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010172b:	6a 02                	push   $0x2
f010172d:	6a 00                	push   $0x0
f010172f:	53                   	push   %ebx
f0101730:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101736:	e8 0a f9 ff ff       	call   f0101045 <page_insert>
f010173b:	83 c4 20             	add    $0x20,%esp
f010173e:	85 c0                	test   %eax,%eax
f0101740:	74 19                	je     f010175b <mem_init+0x6ad>
f0101742:	68 30 3e 10 f0       	push   $0xf0103e30
f0101747:	68 8a 43 10 f0       	push   $0xf010438a
f010174c:	68 36 03 00 00       	push   $0x336
f0101751:	68 48 43 10 f0       	push   $0xf0104348
f0101756:	e8 30 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010175b:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101761:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0101766:	89 c1                	mov    %eax,%ecx
f0101768:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010176b:	8b 17                	mov    (%edi),%edx
f010176d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101773:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101776:	29 c8                	sub    %ecx,%eax
f0101778:	c1 f8 03             	sar    $0x3,%eax
f010177b:	c1 e0 0c             	shl    $0xc,%eax
f010177e:	39 c2                	cmp    %eax,%edx
f0101780:	74 19                	je     f010179b <mem_init+0x6ed>
f0101782:	68 60 3e 10 f0       	push   $0xf0103e60
f0101787:	68 8a 43 10 f0       	push   $0xf010438a
f010178c:	68 37 03 00 00       	push   $0x337
f0101791:	68 48 43 10 f0       	push   $0xf0104348
f0101796:	e8 f0 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010179b:	ba 00 00 00 00       	mov    $0x0,%edx
f01017a0:	89 f8                	mov    %edi,%eax
f01017a2:	e8 aa f1 ff ff       	call   f0100951 <check_va2pa>
f01017a7:	89 da                	mov    %ebx,%edx
f01017a9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017ac:	c1 fa 03             	sar    $0x3,%edx
f01017af:	c1 e2 0c             	shl    $0xc,%edx
f01017b2:	39 d0                	cmp    %edx,%eax
f01017b4:	74 19                	je     f01017cf <mem_init+0x721>
f01017b6:	68 88 3e 10 f0       	push   $0xf0103e88
f01017bb:	68 8a 43 10 f0       	push   $0xf010438a
f01017c0:	68 38 03 00 00       	push   $0x338
f01017c5:	68 48 43 10 f0       	push   $0xf0104348
f01017ca:	e8 bc e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017d4:	74 19                	je     f01017ef <mem_init+0x741>
f01017d6:	68 32 45 10 f0       	push   $0xf0104532
f01017db:	68 8a 43 10 f0       	push   $0xf010438a
f01017e0:	68 39 03 00 00       	push   $0x339
f01017e5:	68 48 43 10 f0       	push   $0xf0104348
f01017ea:	e8 9c e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017f2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017f7:	74 19                	je     f0101812 <mem_init+0x764>
f01017f9:	68 43 45 10 f0       	push   $0xf0104543
f01017fe:	68 8a 43 10 f0       	push   $0xf010438a
f0101803:	68 3a 03 00 00       	push   $0x33a
f0101808:	68 48 43 10 f0       	push   $0xf0104348
f010180d:	e8 79 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101812:	6a 02                	push   $0x2
f0101814:	68 00 10 00 00       	push   $0x1000
f0101819:	56                   	push   %esi
f010181a:	57                   	push   %edi
f010181b:	e8 25 f8 ff ff       	call   f0101045 <page_insert>
f0101820:	83 c4 10             	add    $0x10,%esp
f0101823:	85 c0                	test   %eax,%eax
f0101825:	74 19                	je     f0101840 <mem_init+0x792>
f0101827:	68 b8 3e 10 f0       	push   $0xf0103eb8
f010182c:	68 8a 43 10 f0       	push   $0xf010438a
f0101831:	68 3d 03 00 00       	push   $0x33d
f0101836:	68 48 43 10 f0       	push   $0xf0104348
f010183b:	e8 4b e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101840:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101845:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010184a:	e8 02 f1 ff ff       	call   f0100951 <check_va2pa>
f010184f:	89 f2                	mov    %esi,%edx
f0101851:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101857:	c1 fa 03             	sar    $0x3,%edx
f010185a:	c1 e2 0c             	shl    $0xc,%edx
f010185d:	39 d0                	cmp    %edx,%eax
f010185f:	74 19                	je     f010187a <mem_init+0x7cc>
f0101861:	68 f4 3e 10 f0       	push   $0xf0103ef4
f0101866:	68 8a 43 10 f0       	push   $0xf010438a
f010186b:	68 3e 03 00 00       	push   $0x33e
f0101870:	68 48 43 10 f0       	push   $0xf0104348
f0101875:	e8 11 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010187a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010187f:	74 19                	je     f010189a <mem_init+0x7ec>
f0101881:	68 54 45 10 f0       	push   $0xf0104554
f0101886:	68 8a 43 10 f0       	push   $0xf010438a
f010188b:	68 3f 03 00 00       	push   $0x33f
f0101890:	68 48 43 10 f0       	push   $0xf0104348
f0101895:	e8 f1 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010189a:	83 ec 0c             	sub    $0xc,%esp
f010189d:	6a 00                	push   $0x0
f010189f:	e8 28 f5 ff ff       	call   f0100dcc <page_alloc>
f01018a4:	83 c4 10             	add    $0x10,%esp
f01018a7:	85 c0                	test   %eax,%eax
f01018a9:	74 19                	je     f01018c4 <mem_init+0x816>
f01018ab:	68 e0 44 10 f0       	push   $0xf01044e0
f01018b0:	68 8a 43 10 f0       	push   $0xf010438a
f01018b5:	68 42 03 00 00       	push   $0x342
f01018ba:	68 48 43 10 f0       	push   $0xf0104348
f01018bf:	e8 c7 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018c4:	6a 02                	push   $0x2
f01018c6:	68 00 10 00 00       	push   $0x1000
f01018cb:	56                   	push   %esi
f01018cc:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018d2:	e8 6e f7 ff ff       	call   f0101045 <page_insert>
f01018d7:	83 c4 10             	add    $0x10,%esp
f01018da:	85 c0                	test   %eax,%eax
f01018dc:	74 19                	je     f01018f7 <mem_init+0x849>
f01018de:	68 b8 3e 10 f0       	push   $0xf0103eb8
f01018e3:	68 8a 43 10 f0       	push   $0xf010438a
f01018e8:	68 45 03 00 00       	push   $0x345
f01018ed:	68 48 43 10 f0       	push   $0xf0104348
f01018f2:	e8 94 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018f7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018fc:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101901:	e8 4b f0 ff ff       	call   f0100951 <check_va2pa>
f0101906:	89 f2                	mov    %esi,%edx
f0101908:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f010190e:	c1 fa 03             	sar    $0x3,%edx
f0101911:	c1 e2 0c             	shl    $0xc,%edx
f0101914:	39 d0                	cmp    %edx,%eax
f0101916:	74 19                	je     f0101931 <mem_init+0x883>
f0101918:	68 f4 3e 10 f0       	push   $0xf0103ef4
f010191d:	68 8a 43 10 f0       	push   $0xf010438a
f0101922:	68 46 03 00 00       	push   $0x346
f0101927:	68 48 43 10 f0       	push   $0xf0104348
f010192c:	e8 5a e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101931:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101936:	74 19                	je     f0101951 <mem_init+0x8a3>
f0101938:	68 54 45 10 f0       	push   $0xf0104554
f010193d:	68 8a 43 10 f0       	push   $0xf010438a
f0101942:	68 47 03 00 00       	push   $0x347
f0101947:	68 48 43 10 f0       	push   $0xf0104348
f010194c:	e8 3a e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101951:	83 ec 0c             	sub    $0xc,%esp
f0101954:	6a 00                	push   $0x0
f0101956:	e8 71 f4 ff ff       	call   f0100dcc <page_alloc>
f010195b:	83 c4 10             	add    $0x10,%esp
f010195e:	85 c0                	test   %eax,%eax
f0101960:	74 19                	je     f010197b <mem_init+0x8cd>
f0101962:	68 e0 44 10 f0       	push   $0xf01044e0
f0101967:	68 8a 43 10 f0       	push   $0xf010438a
f010196c:	68 4b 03 00 00       	push   $0x34b
f0101971:	68 48 43 10 f0       	push   $0xf0104348
f0101976:	e8 10 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010197b:	8b 15 48 79 11 f0    	mov    0xf0117948,%edx
f0101981:	8b 02                	mov    (%edx),%eax
f0101983:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101988:	89 c1                	mov    %eax,%ecx
f010198a:	c1 e9 0c             	shr    $0xc,%ecx
f010198d:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
f0101993:	72 15                	jb     f01019aa <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101995:	50                   	push   %eax
f0101996:	68 84 3b 10 f0       	push   $0xf0103b84
f010199b:	68 4e 03 00 00       	push   $0x34e
f01019a0:	68 48 43 10 f0       	push   $0xf0104348
f01019a5:	e8 e1 e6 ff ff       	call   f010008b <_panic>
f01019aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019b2:	83 ec 04             	sub    $0x4,%esp
f01019b5:	6a 00                	push   $0x0
f01019b7:	68 00 10 00 00       	push   $0x1000
f01019bc:	52                   	push   %edx
f01019bd:	e8 dc f4 ff ff       	call   f0100e9e <pgdir_walk>
f01019c2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019c5:	8d 51 04             	lea    0x4(%ecx),%edx
f01019c8:	83 c4 10             	add    $0x10,%esp
f01019cb:	39 d0                	cmp    %edx,%eax
f01019cd:	74 19                	je     f01019e8 <mem_init+0x93a>
f01019cf:	68 24 3f 10 f0       	push   $0xf0103f24
f01019d4:	68 8a 43 10 f0       	push   $0xf010438a
f01019d9:	68 4f 03 00 00       	push   $0x34f
f01019de:	68 48 43 10 f0       	push   $0xf0104348
f01019e3:	e8 a3 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019e8:	6a 06                	push   $0x6
f01019ea:	68 00 10 00 00       	push   $0x1000
f01019ef:	56                   	push   %esi
f01019f0:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01019f6:	e8 4a f6 ff ff       	call   f0101045 <page_insert>
f01019fb:	83 c4 10             	add    $0x10,%esp
f01019fe:	85 c0                	test   %eax,%eax
f0101a00:	74 19                	je     f0101a1b <mem_init+0x96d>
f0101a02:	68 64 3f 10 f0       	push   $0xf0103f64
f0101a07:	68 8a 43 10 f0       	push   $0xf010438a
f0101a0c:	68 52 03 00 00       	push   $0x352
f0101a11:	68 48 43 10 f0       	push   $0xf0104348
f0101a16:	e8 70 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a1b:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101a21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a26:	89 f8                	mov    %edi,%eax
f0101a28:	e8 24 ef ff ff       	call   f0100951 <check_va2pa>
f0101a2d:	89 f2                	mov    %esi,%edx
f0101a2f:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101a35:	c1 fa 03             	sar    $0x3,%edx
f0101a38:	c1 e2 0c             	shl    $0xc,%edx
f0101a3b:	39 d0                	cmp    %edx,%eax
f0101a3d:	74 19                	je     f0101a58 <mem_init+0x9aa>
f0101a3f:	68 f4 3e 10 f0       	push   $0xf0103ef4
f0101a44:	68 8a 43 10 f0       	push   $0xf010438a
f0101a49:	68 53 03 00 00       	push   $0x353
f0101a4e:	68 48 43 10 f0       	push   $0xf0104348
f0101a53:	e8 33 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a58:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a5d:	74 19                	je     f0101a78 <mem_init+0x9ca>
f0101a5f:	68 54 45 10 f0       	push   $0xf0104554
f0101a64:	68 8a 43 10 f0       	push   $0xf010438a
f0101a69:	68 54 03 00 00       	push   $0x354
f0101a6e:	68 48 43 10 f0       	push   $0xf0104348
f0101a73:	e8 13 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a78:	83 ec 04             	sub    $0x4,%esp
f0101a7b:	6a 00                	push   $0x0
f0101a7d:	68 00 10 00 00       	push   $0x1000
f0101a82:	57                   	push   %edi
f0101a83:	e8 16 f4 ff ff       	call   f0100e9e <pgdir_walk>
f0101a88:	83 c4 10             	add    $0x10,%esp
f0101a8b:	f6 00 04             	testb  $0x4,(%eax)
f0101a8e:	75 19                	jne    f0101aa9 <mem_init+0x9fb>
f0101a90:	68 a4 3f 10 f0       	push   $0xf0103fa4
f0101a95:	68 8a 43 10 f0       	push   $0xf010438a
f0101a9a:	68 55 03 00 00       	push   $0x355
f0101a9f:	68 48 43 10 f0       	push   $0xf0104348
f0101aa4:	e8 e2 e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101aa9:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101aae:	f6 00 04             	testb  $0x4,(%eax)
f0101ab1:	75 19                	jne    f0101acc <mem_init+0xa1e>
f0101ab3:	68 65 45 10 f0       	push   $0xf0104565
f0101ab8:	68 8a 43 10 f0       	push   $0xf010438a
f0101abd:	68 56 03 00 00       	push   $0x356
f0101ac2:	68 48 43 10 f0       	push   $0xf0104348
f0101ac7:	e8 bf e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101acc:	6a 02                	push   $0x2
f0101ace:	68 00 10 00 00       	push   $0x1000
f0101ad3:	56                   	push   %esi
f0101ad4:	50                   	push   %eax
f0101ad5:	e8 6b f5 ff ff       	call   f0101045 <page_insert>
f0101ada:	83 c4 10             	add    $0x10,%esp
f0101add:	85 c0                	test   %eax,%eax
f0101adf:	74 19                	je     f0101afa <mem_init+0xa4c>
f0101ae1:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101ae6:	68 8a 43 10 f0       	push   $0xf010438a
f0101aeb:	68 59 03 00 00       	push   $0x359
f0101af0:	68 48 43 10 f0       	push   $0xf0104348
f0101af5:	e8 91 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101afa:	83 ec 04             	sub    $0x4,%esp
f0101afd:	6a 00                	push   $0x0
f0101aff:	68 00 10 00 00       	push   $0x1000
f0101b04:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b0a:	e8 8f f3 ff ff       	call   f0100e9e <pgdir_walk>
f0101b0f:	83 c4 10             	add    $0x10,%esp
f0101b12:	f6 00 02             	testb  $0x2,(%eax)
f0101b15:	75 19                	jne    f0101b30 <mem_init+0xa82>
f0101b17:	68 d8 3f 10 f0       	push   $0xf0103fd8
f0101b1c:	68 8a 43 10 f0       	push   $0xf010438a
f0101b21:	68 5a 03 00 00       	push   $0x35a
f0101b26:	68 48 43 10 f0       	push   $0xf0104348
f0101b2b:	e8 5b e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b30:	83 ec 04             	sub    $0x4,%esp
f0101b33:	6a 00                	push   $0x0
f0101b35:	68 00 10 00 00       	push   $0x1000
f0101b3a:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b40:	e8 59 f3 ff ff       	call   f0100e9e <pgdir_walk>
f0101b45:	83 c4 10             	add    $0x10,%esp
f0101b48:	f6 00 04             	testb  $0x4,(%eax)
f0101b4b:	74 19                	je     f0101b66 <mem_init+0xab8>
f0101b4d:	68 0c 40 10 f0       	push   $0xf010400c
f0101b52:	68 8a 43 10 f0       	push   $0xf010438a
f0101b57:	68 5b 03 00 00       	push   $0x35b
f0101b5c:	68 48 43 10 f0       	push   $0xf0104348
f0101b61:	e8 25 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b66:	6a 02                	push   $0x2
f0101b68:	68 00 00 40 00       	push   $0x400000
f0101b6d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b70:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b76:	e8 ca f4 ff ff       	call   f0101045 <page_insert>
f0101b7b:	83 c4 10             	add    $0x10,%esp
f0101b7e:	85 c0                	test   %eax,%eax
f0101b80:	78 19                	js     f0101b9b <mem_init+0xaed>
f0101b82:	68 44 40 10 f0       	push   $0xf0104044
f0101b87:	68 8a 43 10 f0       	push   $0xf010438a
f0101b8c:	68 5e 03 00 00       	push   $0x35e
f0101b91:	68 48 43 10 f0       	push   $0xf0104348
f0101b96:	e8 f0 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b9b:	6a 02                	push   $0x2
f0101b9d:	68 00 10 00 00       	push   $0x1000
f0101ba2:	53                   	push   %ebx
f0101ba3:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ba9:	e8 97 f4 ff ff       	call   f0101045 <page_insert>
f0101bae:	83 c4 10             	add    $0x10,%esp
f0101bb1:	85 c0                	test   %eax,%eax
f0101bb3:	74 19                	je     f0101bce <mem_init+0xb20>
f0101bb5:	68 7c 40 10 f0       	push   $0xf010407c
f0101bba:	68 8a 43 10 f0       	push   $0xf010438a
f0101bbf:	68 61 03 00 00       	push   $0x361
f0101bc4:	68 48 43 10 f0       	push   $0xf0104348
f0101bc9:	e8 bd e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bce:	83 ec 04             	sub    $0x4,%esp
f0101bd1:	6a 00                	push   $0x0
f0101bd3:	68 00 10 00 00       	push   $0x1000
f0101bd8:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101bde:	e8 bb f2 ff ff       	call   f0100e9e <pgdir_walk>
f0101be3:	83 c4 10             	add    $0x10,%esp
f0101be6:	f6 00 04             	testb  $0x4,(%eax)
f0101be9:	74 19                	je     f0101c04 <mem_init+0xb56>
f0101beb:	68 0c 40 10 f0       	push   $0xf010400c
f0101bf0:	68 8a 43 10 f0       	push   $0xf010438a
f0101bf5:	68 62 03 00 00       	push   $0x362
f0101bfa:	68 48 43 10 f0       	push   $0xf0104348
f0101bff:	e8 87 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c04:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101c0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c0f:	89 f8                	mov    %edi,%eax
f0101c11:	e8 3b ed ff ff       	call   f0100951 <check_va2pa>
f0101c16:	89 c1                	mov    %eax,%ecx
f0101c18:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c1b:	89 d8                	mov    %ebx,%eax
f0101c1d:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101c23:	c1 f8 03             	sar    $0x3,%eax
f0101c26:	c1 e0 0c             	shl    $0xc,%eax
f0101c29:	39 c1                	cmp    %eax,%ecx
f0101c2b:	74 19                	je     f0101c46 <mem_init+0xb98>
f0101c2d:	68 b8 40 10 f0       	push   $0xf01040b8
f0101c32:	68 8a 43 10 f0       	push   $0xf010438a
f0101c37:	68 65 03 00 00       	push   $0x365
f0101c3c:	68 48 43 10 f0       	push   $0xf0104348
f0101c41:	e8 45 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c46:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c4b:	89 f8                	mov    %edi,%eax
f0101c4d:	e8 ff ec ff ff       	call   f0100951 <check_va2pa>
f0101c52:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c55:	74 19                	je     f0101c70 <mem_init+0xbc2>
f0101c57:	68 e4 40 10 f0       	push   $0xf01040e4
f0101c5c:	68 8a 43 10 f0       	push   $0xf010438a
f0101c61:	68 66 03 00 00       	push   $0x366
f0101c66:	68 48 43 10 f0       	push   $0xf0104348
f0101c6b:	e8 1b e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c70:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c75:	74 19                	je     f0101c90 <mem_init+0xbe2>
f0101c77:	68 7b 45 10 f0       	push   $0xf010457b
f0101c7c:	68 8a 43 10 f0       	push   $0xf010438a
f0101c81:	68 68 03 00 00       	push   $0x368
f0101c86:	68 48 43 10 f0       	push   $0xf0104348
f0101c8b:	e8 fb e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c95:	74 19                	je     f0101cb0 <mem_init+0xc02>
f0101c97:	68 8c 45 10 f0       	push   $0xf010458c
f0101c9c:	68 8a 43 10 f0       	push   $0xf010438a
f0101ca1:	68 69 03 00 00       	push   $0x369
f0101ca6:	68 48 43 10 f0       	push   $0xf0104348
f0101cab:	e8 db e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cb0:	83 ec 0c             	sub    $0xc,%esp
f0101cb3:	6a 00                	push   $0x0
f0101cb5:	e8 12 f1 ff ff       	call   f0100dcc <page_alloc>
f0101cba:	83 c4 10             	add    $0x10,%esp
f0101cbd:	39 c6                	cmp    %eax,%esi
f0101cbf:	75 04                	jne    f0101cc5 <mem_init+0xc17>
f0101cc1:	85 c0                	test   %eax,%eax
f0101cc3:	75 19                	jne    f0101cde <mem_init+0xc30>
f0101cc5:	68 14 41 10 f0       	push   $0xf0104114
f0101cca:	68 8a 43 10 f0       	push   $0xf010438a
f0101ccf:	68 6c 03 00 00       	push   $0x36c
f0101cd4:	68 48 43 10 f0       	push   $0xf0104348
f0101cd9:	e8 ad e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cde:	83 ec 08             	sub    $0x8,%esp
f0101ce1:	6a 00                	push   $0x0
f0101ce3:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ce9:	e8 14 f3 ff ff       	call   f0101002 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cee:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101cf4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cf9:	89 f8                	mov    %edi,%eax
f0101cfb:	e8 51 ec ff ff       	call   f0100951 <check_va2pa>
f0101d00:	83 c4 10             	add    $0x10,%esp
f0101d03:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d06:	74 19                	je     f0101d21 <mem_init+0xc73>
f0101d08:	68 38 41 10 f0       	push   $0xf0104138
f0101d0d:	68 8a 43 10 f0       	push   $0xf010438a
f0101d12:	68 70 03 00 00       	push   $0x370
f0101d17:	68 48 43 10 f0       	push   $0xf0104348
f0101d1c:	e8 6a e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d26:	89 f8                	mov    %edi,%eax
f0101d28:	e8 24 ec ff ff       	call   f0100951 <check_va2pa>
f0101d2d:	89 da                	mov    %ebx,%edx
f0101d2f:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101d35:	c1 fa 03             	sar    $0x3,%edx
f0101d38:	c1 e2 0c             	shl    $0xc,%edx
f0101d3b:	39 d0                	cmp    %edx,%eax
f0101d3d:	74 19                	je     f0101d58 <mem_init+0xcaa>
f0101d3f:	68 e4 40 10 f0       	push   $0xf01040e4
f0101d44:	68 8a 43 10 f0       	push   $0xf010438a
f0101d49:	68 71 03 00 00       	push   $0x371
f0101d4e:	68 48 43 10 f0       	push   $0xf0104348
f0101d53:	e8 33 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d58:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d5d:	74 19                	je     f0101d78 <mem_init+0xcca>
f0101d5f:	68 32 45 10 f0       	push   $0xf0104532
f0101d64:	68 8a 43 10 f0       	push   $0xf010438a
f0101d69:	68 72 03 00 00       	push   $0x372
f0101d6e:	68 48 43 10 f0       	push   $0xf0104348
f0101d73:	e8 13 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d78:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d7d:	74 19                	je     f0101d98 <mem_init+0xcea>
f0101d7f:	68 8c 45 10 f0       	push   $0xf010458c
f0101d84:	68 8a 43 10 f0       	push   $0xf010438a
f0101d89:	68 73 03 00 00       	push   $0x373
f0101d8e:	68 48 43 10 f0       	push   $0xf0104348
f0101d93:	e8 f3 e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d98:	6a 00                	push   $0x0
f0101d9a:	68 00 10 00 00       	push   $0x1000
f0101d9f:	53                   	push   %ebx
f0101da0:	57                   	push   %edi
f0101da1:	e8 9f f2 ff ff       	call   f0101045 <page_insert>
f0101da6:	83 c4 10             	add    $0x10,%esp
f0101da9:	85 c0                	test   %eax,%eax
f0101dab:	74 19                	je     f0101dc6 <mem_init+0xd18>
f0101dad:	68 5c 41 10 f0       	push   $0xf010415c
f0101db2:	68 8a 43 10 f0       	push   $0xf010438a
f0101db7:	68 76 03 00 00       	push   $0x376
f0101dbc:	68 48 43 10 f0       	push   $0xf0104348
f0101dc1:	e8 c5 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dc6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dcb:	75 19                	jne    f0101de6 <mem_init+0xd38>
f0101dcd:	68 9d 45 10 f0       	push   $0xf010459d
f0101dd2:	68 8a 43 10 f0       	push   $0xf010438a
f0101dd7:	68 77 03 00 00       	push   $0x377
f0101ddc:	68 48 43 10 f0       	push   $0xf0104348
f0101de1:	e8 a5 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101de6:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101de9:	74 19                	je     f0101e04 <mem_init+0xd56>
f0101deb:	68 a9 45 10 f0       	push   $0xf01045a9
f0101df0:	68 8a 43 10 f0       	push   $0xf010438a
f0101df5:	68 78 03 00 00       	push   $0x378
f0101dfa:	68 48 43 10 f0       	push   $0xf0104348
f0101dff:	e8 87 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e04:	83 ec 08             	sub    $0x8,%esp
f0101e07:	68 00 10 00 00       	push   $0x1000
f0101e0c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e12:	e8 eb f1 ff ff       	call   f0101002 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e17:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101e1d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e22:	89 f8                	mov    %edi,%eax
f0101e24:	e8 28 eb ff ff       	call   f0100951 <check_va2pa>
f0101e29:	83 c4 10             	add    $0x10,%esp
f0101e2c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e2f:	74 19                	je     f0101e4a <mem_init+0xd9c>
f0101e31:	68 38 41 10 f0       	push   $0xf0104138
f0101e36:	68 8a 43 10 f0       	push   $0xf010438a
f0101e3b:	68 7c 03 00 00       	push   $0x37c
f0101e40:	68 48 43 10 f0       	push   $0xf0104348
f0101e45:	e8 41 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e4a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e4f:	89 f8                	mov    %edi,%eax
f0101e51:	e8 fb ea ff ff       	call   f0100951 <check_va2pa>
f0101e56:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e59:	74 19                	je     f0101e74 <mem_init+0xdc6>
f0101e5b:	68 94 41 10 f0       	push   $0xf0104194
f0101e60:	68 8a 43 10 f0       	push   $0xf010438a
f0101e65:	68 7d 03 00 00       	push   $0x37d
f0101e6a:	68 48 43 10 f0       	push   $0xf0104348
f0101e6f:	e8 17 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e74:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e79:	74 19                	je     f0101e94 <mem_init+0xde6>
f0101e7b:	68 be 45 10 f0       	push   $0xf01045be
f0101e80:	68 8a 43 10 f0       	push   $0xf010438a
f0101e85:	68 7e 03 00 00       	push   $0x37e
f0101e8a:	68 48 43 10 f0       	push   $0xf0104348
f0101e8f:	e8 f7 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e94:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e99:	74 19                	je     f0101eb4 <mem_init+0xe06>
f0101e9b:	68 8c 45 10 f0       	push   $0xf010458c
f0101ea0:	68 8a 43 10 f0       	push   $0xf010438a
f0101ea5:	68 7f 03 00 00       	push   $0x37f
f0101eaa:	68 48 43 10 f0       	push   $0xf0104348
f0101eaf:	e8 d7 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eb4:	83 ec 0c             	sub    $0xc,%esp
f0101eb7:	6a 00                	push   $0x0
f0101eb9:	e8 0e ef ff ff       	call   f0100dcc <page_alloc>
f0101ebe:	83 c4 10             	add    $0x10,%esp
f0101ec1:	85 c0                	test   %eax,%eax
f0101ec3:	74 04                	je     f0101ec9 <mem_init+0xe1b>
f0101ec5:	39 c3                	cmp    %eax,%ebx
f0101ec7:	74 19                	je     f0101ee2 <mem_init+0xe34>
f0101ec9:	68 bc 41 10 f0       	push   $0xf01041bc
f0101ece:	68 8a 43 10 f0       	push   $0xf010438a
f0101ed3:	68 82 03 00 00       	push   $0x382
f0101ed8:	68 48 43 10 f0       	push   $0xf0104348
f0101edd:	e8 a9 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ee2:	83 ec 0c             	sub    $0xc,%esp
f0101ee5:	6a 00                	push   $0x0
f0101ee7:	e8 e0 ee ff ff       	call   f0100dcc <page_alloc>
f0101eec:	83 c4 10             	add    $0x10,%esp
f0101eef:	85 c0                	test   %eax,%eax
f0101ef1:	74 19                	je     f0101f0c <mem_init+0xe5e>
f0101ef3:	68 e0 44 10 f0       	push   $0xf01044e0
f0101ef8:	68 8a 43 10 f0       	push   $0xf010438a
f0101efd:	68 85 03 00 00       	push   $0x385
f0101f02:	68 48 43 10 f0       	push   $0xf0104348
f0101f07:	e8 7f e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f0c:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f0101f12:	8b 11                	mov    (%ecx),%edx
f0101f14:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f1d:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101f23:	c1 f8 03             	sar    $0x3,%eax
f0101f26:	c1 e0 0c             	shl    $0xc,%eax
f0101f29:	39 c2                	cmp    %eax,%edx
f0101f2b:	74 19                	je     f0101f46 <mem_init+0xe98>
f0101f2d:	68 60 3e 10 f0       	push   $0xf0103e60
f0101f32:	68 8a 43 10 f0       	push   $0xf010438a
f0101f37:	68 88 03 00 00       	push   $0x388
f0101f3c:	68 48 43 10 f0       	push   $0xf0104348
f0101f41:	e8 45 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f46:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f4f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f54:	74 19                	je     f0101f6f <mem_init+0xec1>
f0101f56:	68 43 45 10 f0       	push   $0xf0104543
f0101f5b:	68 8a 43 10 f0       	push   $0xf010438a
f0101f60:	68 8a 03 00 00       	push   $0x38a
f0101f65:	68 48 43 10 f0       	push   $0xf0104348
f0101f6a:	e8 1c e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f6f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f72:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f78:	83 ec 0c             	sub    $0xc,%esp
f0101f7b:	50                   	push   %eax
f0101f7c:	e8 bb ee ff ff       	call   f0100e3c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f81:	83 c4 0c             	add    $0xc,%esp
f0101f84:	6a 01                	push   $0x1
f0101f86:	68 00 10 40 00       	push   $0x401000
f0101f8b:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101f91:	e8 08 ef ff ff       	call   f0100e9e <pgdir_walk>
f0101f96:	89 c7                	mov    %eax,%edi
f0101f98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f9b:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101fa0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fa3:	8b 40 04             	mov    0x4(%eax),%eax
f0101fa6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fab:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0101fb1:	89 c2                	mov    %eax,%edx
f0101fb3:	c1 ea 0c             	shr    $0xc,%edx
f0101fb6:	83 c4 10             	add    $0x10,%esp
f0101fb9:	39 ca                	cmp    %ecx,%edx
f0101fbb:	72 15                	jb     f0101fd2 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbd:	50                   	push   %eax
f0101fbe:	68 84 3b 10 f0       	push   $0xf0103b84
f0101fc3:	68 91 03 00 00       	push   $0x391
f0101fc8:	68 48 43 10 f0       	push   $0xf0104348
f0101fcd:	e8 b9 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fd2:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fd7:	39 c7                	cmp    %eax,%edi
f0101fd9:	74 19                	je     f0101ff4 <mem_init+0xf46>
f0101fdb:	68 cf 45 10 f0       	push   $0xf01045cf
f0101fe0:	68 8a 43 10 f0       	push   $0xf010438a
f0101fe5:	68 92 03 00 00       	push   $0x392
f0101fea:	68 48 43 10 f0       	push   $0xf0104348
f0101fef:	e8 97 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ff4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ff7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101ffe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102001:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102007:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010200d:	c1 f8 03             	sar    $0x3,%eax
f0102010:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102013:	89 c2                	mov    %eax,%edx
f0102015:	c1 ea 0c             	shr    $0xc,%edx
f0102018:	39 d1                	cmp    %edx,%ecx
f010201a:	77 12                	ja     f010202e <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010201c:	50                   	push   %eax
f010201d:	68 84 3b 10 f0       	push   $0xf0103b84
f0102022:	6a 52                	push   $0x52
f0102024:	68 70 43 10 f0       	push   $0xf0104370
f0102029:	e8 5d e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010202e:	83 ec 04             	sub    $0x4,%esp
f0102031:	68 00 10 00 00       	push   $0x1000
f0102036:	68 ff 00 00 00       	push   $0xff
f010203b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102040:	50                   	push   %eax
f0102041:	e8 4e 11 00 00       	call   f0103194 <memset>
	page_free(pp0);
f0102046:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102049:	89 3c 24             	mov    %edi,(%esp)
f010204c:	e8 eb ed ff ff       	call   f0100e3c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102051:	83 c4 0c             	add    $0xc,%esp
f0102054:	6a 01                	push   $0x1
f0102056:	6a 00                	push   $0x0
f0102058:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010205e:	e8 3b ee ff ff       	call   f0100e9e <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102063:	89 fa                	mov    %edi,%edx
f0102065:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f010206b:	c1 fa 03             	sar    $0x3,%edx
f010206e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102071:	89 d0                	mov    %edx,%eax
f0102073:	c1 e8 0c             	shr    $0xc,%eax
f0102076:	83 c4 10             	add    $0x10,%esp
f0102079:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f010207f:	72 12                	jb     f0102093 <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102081:	52                   	push   %edx
f0102082:	68 84 3b 10 f0       	push   $0xf0103b84
f0102087:	6a 52                	push   $0x52
f0102089:	68 70 43 10 f0       	push   $0xf0104370
f010208e:	e8 f8 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102093:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102099:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010209c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020a2:	f6 00 01             	testb  $0x1,(%eax)
f01020a5:	74 19                	je     f01020c0 <mem_init+0x1012>
f01020a7:	68 e7 45 10 f0       	push   $0xf01045e7
f01020ac:	68 8a 43 10 f0       	push   $0xf010438a
f01020b1:	68 9c 03 00 00       	push   $0x39c
f01020b6:	68 48 43 10 f0       	push   $0xf0104348
f01020bb:	e8 cb df ff ff       	call   f010008b <_panic>
f01020c0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020c3:	39 d0                	cmp    %edx,%eax
f01020c5:	75 db                	jne    f01020a2 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020c7:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01020cc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020db:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020de:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01020e4:	83 ec 0c             	sub    $0xc,%esp
f01020e7:	50                   	push   %eax
f01020e8:	e8 4f ed ff ff       	call   f0100e3c <page_free>
	page_free(pp1);
f01020ed:	89 1c 24             	mov    %ebx,(%esp)
f01020f0:	e8 47 ed ff ff       	call   f0100e3c <page_free>
	page_free(pp2);
f01020f5:	89 34 24             	mov    %esi,(%esp)
f01020f8:	e8 3f ed ff ff       	call   f0100e3c <page_free>

	cprintf("check_page() succeeded!\n");
f01020fd:	c7 04 24 fe 45 10 f0 	movl   $0xf01045fe,(%esp)
f0102104:	e8 d2 05 00 00       	call   f01026db <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, sizeof(struct PageInfo)*npages, PADDR(pages), PTE_U | PTE_P);
f0102109:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010210e:	83 c4 10             	add    $0x10,%esp
f0102111:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102116:	77 15                	ja     f010212d <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102118:	50                   	push   %eax
f0102119:	68 a8 3b 10 f0       	push   $0xf0103ba8
f010211e:	68 bc 00 00 00       	push   $0xbc
f0102123:	68 48 43 10 f0       	push   $0xf0104348
f0102128:	e8 5e df ff ff       	call   f010008b <_panic>
f010212d:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0102133:	c1 e1 03             	shl    $0x3,%ecx
f0102136:	83 ec 08             	sub    $0x8,%esp
f0102139:	6a 05                	push   $0x5
f010213b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102140:	50                   	push   %eax
f0102141:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102146:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010214b:	e8 e1 ed ff ff       	call   f0100f31 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102150:	83 c4 10             	add    $0x10,%esp
f0102153:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102158:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010215d:	77 15                	ja     f0102174 <mem_init+0x10c6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010215f:	50                   	push   %eax
f0102160:	68 a8 3b 10 f0       	push   $0xf0103ba8
f0102165:	68 c9 00 00 00       	push   $0xc9
f010216a:	68 48 43 10 f0       	push   $0xf0104348
f010216f:	e8 17 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack),(PTE_W | PTE_P));
f0102174:	83 ec 08             	sub    $0x8,%esp
f0102177:	6a 03                	push   $0x3
f0102179:	68 00 d0 10 00       	push   $0x10d000
f010217e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102183:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102188:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010218d:	e8 9f ed ff ff       	call   f0100f31 <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE-1, 0, (PTE_W | PTE_P));	
f0102192:	83 c4 08             	add    $0x8,%esp
f0102195:	6a 03                	push   $0x3
f0102197:	6a 00                	push   $0x0
f0102199:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010219e:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021a3:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021a8:	e8 84 ed ff ff       	call   f0100f31 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021ad:	8b 35 48 79 11 f0    	mov    0xf0117948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021b3:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f01021b8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021bb:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ca:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021d3:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021d6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021db:	eb 55                	jmp    f0102232 <mem_init+0x1184>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021dd:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021e3:	89 f0                	mov    %esi,%eax
f01021e5:	e8 67 e7 ff ff       	call   f0100951 <check_va2pa>
f01021ea:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021f1:	77 15                	ja     f0102208 <mem_init+0x115a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021f3:	57                   	push   %edi
f01021f4:	68 a8 3b 10 f0       	push   $0xf0103ba8
f01021f9:	68 de 02 00 00       	push   $0x2de
f01021fe:	68 48 43 10 f0       	push   $0xf0104348
f0102203:	e8 83 de ff ff       	call   f010008b <_panic>
f0102208:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010220f:	39 c2                	cmp    %eax,%edx
f0102211:	74 19                	je     f010222c <mem_init+0x117e>
f0102213:	68 e0 41 10 f0       	push   $0xf01041e0
f0102218:	68 8a 43 10 f0       	push   $0xf010438a
f010221d:	68 de 02 00 00       	push   $0x2de
f0102222:	68 48 43 10 f0       	push   $0xf0104348
f0102227:	e8 5f de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010222c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102232:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102235:	77 a6                	ja     f01021dd <mem_init+0x112f>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102237:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010223a:	c1 e7 0c             	shl    $0xc,%edi
f010223d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102242:	eb 30                	jmp    f0102274 <mem_init+0x11c6>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102244:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010224a:	89 f0                	mov    %esi,%eax
f010224c:	e8 00 e7 ff ff       	call   f0100951 <check_va2pa>
f0102251:	39 c3                	cmp    %eax,%ebx
f0102253:	74 19                	je     f010226e <mem_init+0x11c0>
f0102255:	68 14 42 10 f0       	push   $0xf0104214
f010225a:	68 8a 43 10 f0       	push   $0xf010438a
f010225f:	68 e3 02 00 00       	push   $0x2e3
f0102264:	68 48 43 10 f0       	push   $0xf0104348
f0102269:	e8 1d de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010226e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102274:	39 fb                	cmp    %edi,%ebx
f0102276:	72 cc                	jb     f0102244 <mem_init+0x1196>
f0102278:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010227d:	89 da                	mov    %ebx,%edx
f010227f:	89 f0                	mov    %esi,%eax
f0102281:	e8 cb e6 ff ff       	call   f0100951 <check_va2pa>
f0102286:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f010228c:	39 c2                	cmp    %eax,%edx
f010228e:	74 19                	je     f01022a9 <mem_init+0x11fb>
f0102290:	68 3c 42 10 f0       	push   $0xf010423c
f0102295:	68 8a 43 10 f0       	push   $0xf010438a
f010229a:	68 e7 02 00 00       	push   $0x2e7
f010229f:	68 48 43 10 f0       	push   $0xf0104348
f01022a4:	e8 e2 dd ff ff       	call   f010008b <_panic>
f01022a9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022af:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022b5:	75 c6                	jne    f010227d <mem_init+0x11cf>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022b7:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022bc:	89 f0                	mov    %esi,%eax
f01022be:	e8 8e e6 ff ff       	call   f0100951 <check_va2pa>
f01022c3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022c6:	74 51                	je     f0102319 <mem_init+0x126b>
f01022c8:	68 84 42 10 f0       	push   $0xf0104284
f01022cd:	68 8a 43 10 f0       	push   $0xf010438a
f01022d2:	68 e8 02 00 00       	push   $0x2e8
f01022d7:	68 48 43 10 f0       	push   $0xf0104348
f01022dc:	e8 aa dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022e1:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022e6:	72 36                	jb     f010231e <mem_init+0x1270>
f01022e8:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022ed:	76 07                	jbe    f01022f6 <mem_init+0x1248>
f01022ef:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022f4:	75 28                	jne    f010231e <mem_init+0x1270>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022f6:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022fa:	0f 85 83 00 00 00    	jne    f0102383 <mem_init+0x12d5>
f0102300:	68 17 46 10 f0       	push   $0xf0104617
f0102305:	68 8a 43 10 f0       	push   $0xf010438a
f010230a:	68 f0 02 00 00       	push   $0x2f0
f010230f:	68 48 43 10 f0       	push   $0xf0104348
f0102314:	e8 72 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102319:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010231e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102323:	76 3f                	jbe    f0102364 <mem_init+0x12b6>
				assert(pgdir[i] & PTE_P);
f0102325:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102328:	f6 c2 01             	test   $0x1,%dl
f010232b:	75 19                	jne    f0102346 <mem_init+0x1298>
f010232d:	68 17 46 10 f0       	push   $0xf0104617
f0102332:	68 8a 43 10 f0       	push   $0xf010438a
f0102337:	68 f4 02 00 00       	push   $0x2f4
f010233c:	68 48 43 10 f0       	push   $0xf0104348
f0102341:	e8 45 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102346:	f6 c2 02             	test   $0x2,%dl
f0102349:	75 38                	jne    f0102383 <mem_init+0x12d5>
f010234b:	68 28 46 10 f0       	push   $0xf0104628
f0102350:	68 8a 43 10 f0       	push   $0xf010438a
f0102355:	68 f5 02 00 00       	push   $0x2f5
f010235a:	68 48 43 10 f0       	push   $0xf0104348
f010235f:	e8 27 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102364:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102368:	74 19                	je     f0102383 <mem_init+0x12d5>
f010236a:	68 39 46 10 f0       	push   $0xf0104639
f010236f:	68 8a 43 10 f0       	push   $0xf010438a
f0102374:	68 f7 02 00 00       	push   $0x2f7
f0102379:	68 48 43 10 f0       	push   $0xf0104348
f010237e:	e8 08 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102383:	83 c0 01             	add    $0x1,%eax
f0102386:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010238b:	0f 86 50 ff ff ff    	jbe    f01022e1 <mem_init+0x1233>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102391:	83 ec 0c             	sub    $0xc,%esp
f0102394:	68 b4 42 10 f0       	push   $0xf01042b4
f0102399:	e8 3d 03 00 00       	call   f01026db <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010239e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023a3:	83 c4 10             	add    $0x10,%esp
f01023a6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023ab:	77 15                	ja     f01023c2 <mem_init+0x1314>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023ad:	50                   	push   %eax
f01023ae:	68 a8 3b 10 f0       	push   $0xf0103ba8
f01023b3:	68 df 00 00 00       	push   $0xdf
f01023b8:	68 48 43 10 f0       	push   $0xf0104348
f01023bd:	e8 c9 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023c2:	05 00 00 00 10       	add    $0x10000000,%eax
f01023c7:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01023cf:	e8 6a e6 ff ff       	call   f0100a3e <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023d4:	0f 20 c0             	mov    %cr0,%eax
f01023d7:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023da:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023df:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023e2:	83 ec 0c             	sub    $0xc,%esp
f01023e5:	6a 00                	push   $0x0
f01023e7:	e8 e0 e9 ff ff       	call   f0100dcc <page_alloc>
f01023ec:	89 c7                	mov    %eax,%edi
f01023ee:	83 c4 10             	add    $0x10,%esp
f01023f1:	85 c0                	test   %eax,%eax
f01023f3:	75 19                	jne    f010240e <mem_init+0x1360>
f01023f5:	68 35 44 10 f0       	push   $0xf0104435
f01023fa:	68 8a 43 10 f0       	push   $0xf010438a
f01023ff:	68 b7 03 00 00       	push   $0x3b7
f0102404:	68 48 43 10 f0       	push   $0xf0104348
f0102409:	e8 7d dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010240e:	83 ec 0c             	sub    $0xc,%esp
f0102411:	6a 00                	push   $0x0
f0102413:	e8 b4 e9 ff ff       	call   f0100dcc <page_alloc>
f0102418:	89 c6                	mov    %eax,%esi
f010241a:	83 c4 10             	add    $0x10,%esp
f010241d:	85 c0                	test   %eax,%eax
f010241f:	75 19                	jne    f010243a <mem_init+0x138c>
f0102421:	68 4b 44 10 f0       	push   $0xf010444b
f0102426:	68 8a 43 10 f0       	push   $0xf010438a
f010242b:	68 b8 03 00 00       	push   $0x3b8
f0102430:	68 48 43 10 f0       	push   $0xf0104348
f0102435:	e8 51 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010243a:	83 ec 0c             	sub    $0xc,%esp
f010243d:	6a 00                	push   $0x0
f010243f:	e8 88 e9 ff ff       	call   f0100dcc <page_alloc>
f0102444:	89 c3                	mov    %eax,%ebx
f0102446:	83 c4 10             	add    $0x10,%esp
f0102449:	85 c0                	test   %eax,%eax
f010244b:	75 19                	jne    f0102466 <mem_init+0x13b8>
f010244d:	68 61 44 10 f0       	push   $0xf0104461
f0102452:	68 8a 43 10 f0       	push   $0xf010438a
f0102457:	68 b9 03 00 00       	push   $0x3b9
f010245c:	68 48 43 10 f0       	push   $0xf0104348
f0102461:	e8 25 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102466:	83 ec 0c             	sub    $0xc,%esp
f0102469:	57                   	push   %edi
f010246a:	e8 cd e9 ff ff       	call   f0100e3c <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010246f:	89 f0                	mov    %esi,%eax
f0102471:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0102477:	c1 f8 03             	sar    $0x3,%eax
f010247a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010247d:	89 c2                	mov    %eax,%edx
f010247f:	c1 ea 0c             	shr    $0xc,%edx
f0102482:	83 c4 10             	add    $0x10,%esp
f0102485:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f010248b:	72 12                	jb     f010249f <mem_init+0x13f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010248d:	50                   	push   %eax
f010248e:	68 84 3b 10 f0       	push   $0xf0103b84
f0102493:	6a 52                	push   $0x52
f0102495:	68 70 43 10 f0       	push   $0xf0104370
f010249a:	e8 ec db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010249f:	83 ec 04             	sub    $0x4,%esp
f01024a2:	68 00 10 00 00       	push   $0x1000
f01024a7:	6a 01                	push   $0x1
f01024a9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ae:	50                   	push   %eax
f01024af:	e8 e0 0c 00 00       	call   f0103194 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024b4:	89 d8                	mov    %ebx,%eax
f01024b6:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01024bc:	c1 f8 03             	sar    $0x3,%eax
f01024bf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024c2:	89 c2                	mov    %eax,%edx
f01024c4:	c1 ea 0c             	shr    $0xc,%edx
f01024c7:	83 c4 10             	add    $0x10,%esp
f01024ca:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01024d0:	72 12                	jb     f01024e4 <mem_init+0x1436>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d2:	50                   	push   %eax
f01024d3:	68 84 3b 10 f0       	push   $0xf0103b84
f01024d8:	6a 52                	push   $0x52
f01024da:	68 70 43 10 f0       	push   $0xf0104370
f01024df:	e8 a7 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024e4:	83 ec 04             	sub    $0x4,%esp
f01024e7:	68 00 10 00 00       	push   $0x1000
f01024ec:	6a 02                	push   $0x2
f01024ee:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024f3:	50                   	push   %eax
f01024f4:	e8 9b 0c 00 00       	call   f0103194 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024f9:	6a 02                	push   $0x2
f01024fb:	68 00 10 00 00       	push   $0x1000
f0102500:	56                   	push   %esi
f0102501:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102507:	e8 39 eb ff ff       	call   f0101045 <page_insert>
	assert(pp1->pp_ref == 1);
f010250c:	83 c4 20             	add    $0x20,%esp
f010250f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102514:	74 19                	je     f010252f <mem_init+0x1481>
f0102516:	68 32 45 10 f0       	push   $0xf0104532
f010251b:	68 8a 43 10 f0       	push   $0xf010438a
f0102520:	68 be 03 00 00       	push   $0x3be
f0102525:	68 48 43 10 f0       	push   $0xf0104348
f010252a:	e8 5c db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010252f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102536:	01 01 01 
f0102539:	74 19                	je     f0102554 <mem_init+0x14a6>
f010253b:	68 d4 42 10 f0       	push   $0xf01042d4
f0102540:	68 8a 43 10 f0       	push   $0xf010438a
f0102545:	68 bf 03 00 00       	push   $0x3bf
f010254a:	68 48 43 10 f0       	push   $0xf0104348
f010254f:	e8 37 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102554:	6a 02                	push   $0x2
f0102556:	68 00 10 00 00       	push   $0x1000
f010255b:	53                   	push   %ebx
f010255c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102562:	e8 de ea ff ff       	call   f0101045 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102567:	83 c4 10             	add    $0x10,%esp
f010256a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102571:	02 02 02 
f0102574:	74 19                	je     f010258f <mem_init+0x14e1>
f0102576:	68 f8 42 10 f0       	push   $0xf01042f8
f010257b:	68 8a 43 10 f0       	push   $0xf010438a
f0102580:	68 c1 03 00 00       	push   $0x3c1
f0102585:	68 48 43 10 f0       	push   $0xf0104348
f010258a:	e8 fc da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010258f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102594:	74 19                	je     f01025af <mem_init+0x1501>
f0102596:	68 54 45 10 f0       	push   $0xf0104554
f010259b:	68 8a 43 10 f0       	push   $0xf010438a
f01025a0:	68 c2 03 00 00       	push   $0x3c2
f01025a5:	68 48 43 10 f0       	push   $0xf0104348
f01025aa:	e8 dc da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025af:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025b4:	74 19                	je     f01025cf <mem_init+0x1521>
f01025b6:	68 be 45 10 f0       	push   $0xf01045be
f01025bb:	68 8a 43 10 f0       	push   $0xf010438a
f01025c0:	68 c3 03 00 00       	push   $0x3c3
f01025c5:	68 48 43 10 f0       	push   $0xf0104348
f01025ca:	e8 bc da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025cf:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025d6:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d9:	89 d8                	mov    %ebx,%eax
f01025db:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01025e1:	c1 f8 03             	sar    $0x3,%eax
f01025e4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025e7:	89 c2                	mov    %eax,%edx
f01025e9:	c1 ea 0c             	shr    $0xc,%edx
f01025ec:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01025f2:	72 12                	jb     f0102606 <mem_init+0x1558>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f4:	50                   	push   %eax
f01025f5:	68 84 3b 10 f0       	push   $0xf0103b84
f01025fa:	6a 52                	push   $0x52
f01025fc:	68 70 43 10 f0       	push   $0xf0104370
f0102601:	e8 85 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102606:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010260d:	03 03 03 
f0102610:	74 19                	je     f010262b <mem_init+0x157d>
f0102612:	68 1c 43 10 f0       	push   $0xf010431c
f0102617:	68 8a 43 10 f0       	push   $0xf010438a
f010261c:	68 c5 03 00 00       	push   $0x3c5
f0102621:	68 48 43 10 f0       	push   $0xf0104348
f0102626:	e8 60 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010262b:	83 ec 08             	sub    $0x8,%esp
f010262e:	68 00 10 00 00       	push   $0x1000
f0102633:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102639:	e8 c4 e9 ff ff       	call   f0101002 <page_remove>
	assert(pp2->pp_ref == 0);
f010263e:	83 c4 10             	add    $0x10,%esp
f0102641:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102646:	74 19                	je     f0102661 <mem_init+0x15b3>
f0102648:	68 8c 45 10 f0       	push   $0xf010458c
f010264d:	68 8a 43 10 f0       	push   $0xf010438a
f0102652:	68 c7 03 00 00       	push   $0x3c7
f0102657:	68 48 43 10 f0       	push   $0xf0104348
f010265c:	e8 2a da ff ff       	call   f010008b <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102661:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102664:	5b                   	pop    %ebx
f0102665:	5e                   	pop    %esi
f0102666:	5f                   	pop    %edi
f0102667:	5d                   	pop    %ebp
f0102668:	c3                   	ret    

f0102669 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102669:	55                   	push   %ebp
f010266a:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010266c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010266f:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102672:	5d                   	pop    %ebp
f0102673:	c3                   	ret    

f0102674 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102674:	55                   	push   %ebp
f0102675:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102677:	ba 70 00 00 00       	mov    $0x70,%edx
f010267c:	8b 45 08             	mov    0x8(%ebp),%eax
f010267f:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102680:	ba 71 00 00 00       	mov    $0x71,%edx
f0102685:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102686:	0f b6 c0             	movzbl %al,%eax
}
f0102689:	5d                   	pop    %ebp
f010268a:	c3                   	ret    

f010268b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010268b:	55                   	push   %ebp
f010268c:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010268e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102693:	8b 45 08             	mov    0x8(%ebp),%eax
f0102696:	ee                   	out    %al,(%dx)
f0102697:	ba 71 00 00 00       	mov    $0x71,%edx
f010269c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010269f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026a0:	5d                   	pop    %ebp
f01026a1:	c3                   	ret    

f01026a2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026a2:	55                   	push   %ebp
f01026a3:	89 e5                	mov    %esp,%ebp
f01026a5:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026a8:	ff 75 08             	pushl  0x8(%ebp)
f01026ab:	e8 50 df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01026b0:	83 c4 10             	add    $0x10,%esp
f01026b3:	c9                   	leave  
f01026b4:	c3                   	ret    

f01026b5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026b5:	55                   	push   %ebp
f01026b6:	89 e5                	mov    %esp,%ebp
f01026b8:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026bb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026c2:	ff 75 0c             	pushl  0xc(%ebp)
f01026c5:	ff 75 08             	pushl  0x8(%ebp)
f01026c8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026cb:	50                   	push   %eax
f01026cc:	68 a2 26 10 f0       	push   $0xf01026a2
f01026d1:	e8 52 04 00 00       	call   f0102b28 <vprintfmt>
	return cnt;
}
f01026d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026d9:	c9                   	leave  
f01026da:	c3                   	ret    

f01026db <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026db:	55                   	push   %ebp
f01026dc:	89 e5                	mov    %esp,%ebp
f01026de:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026e1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026e4:	50                   	push   %eax
f01026e5:	ff 75 08             	pushl  0x8(%ebp)
f01026e8:	e8 c8 ff ff ff       	call   f01026b5 <vcprintf>
	va_end(ap);

	return cnt;
}
f01026ed:	c9                   	leave  
f01026ee:	c3                   	ret    

f01026ef <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01026ef:	55                   	push   %ebp
f01026f0:	89 e5                	mov    %esp,%ebp
f01026f2:	57                   	push   %edi
f01026f3:	56                   	push   %esi
f01026f4:	53                   	push   %ebx
f01026f5:	83 ec 14             	sub    $0x14,%esp
f01026f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01026fb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01026fe:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102701:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102704:	8b 1a                	mov    (%edx),%ebx
f0102706:	8b 01                	mov    (%ecx),%eax
f0102708:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010270b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102712:	eb 7f                	jmp    f0102793 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102714:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102717:	01 d8                	add    %ebx,%eax
f0102719:	89 c6                	mov    %eax,%esi
f010271b:	c1 ee 1f             	shr    $0x1f,%esi
f010271e:	01 c6                	add    %eax,%esi
f0102720:	d1 fe                	sar    %esi
f0102722:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102725:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102728:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010272b:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010272d:	eb 03                	jmp    f0102732 <stab_binsearch+0x43>
			m--;
f010272f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102732:	39 c3                	cmp    %eax,%ebx
f0102734:	7f 0d                	jg     f0102743 <stab_binsearch+0x54>
f0102736:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010273a:	83 ea 0c             	sub    $0xc,%edx
f010273d:	39 f9                	cmp    %edi,%ecx
f010273f:	75 ee                	jne    f010272f <stab_binsearch+0x40>
f0102741:	eb 05                	jmp    f0102748 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102743:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102746:	eb 4b                	jmp    f0102793 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102748:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010274b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010274e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102752:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102755:	76 11                	jbe    f0102768 <stab_binsearch+0x79>
			*region_left = m;
f0102757:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010275a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010275c:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010275f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102766:	eb 2b                	jmp    f0102793 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102768:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010276b:	73 14                	jae    f0102781 <stab_binsearch+0x92>
			*region_right = m - 1;
f010276d:	83 e8 01             	sub    $0x1,%eax
f0102770:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102773:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102776:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102778:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010277f:	eb 12                	jmp    f0102793 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102781:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102784:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102786:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010278a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010278c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102793:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102796:	0f 8e 78 ff ff ff    	jle    f0102714 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010279c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027a0:	75 0f                	jne    f01027b1 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027a5:	8b 00                	mov    (%eax),%eax
f01027a7:	83 e8 01             	sub    $0x1,%eax
f01027aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027ad:	89 06                	mov    %eax,(%esi)
f01027af:	eb 2c                	jmp    f01027dd <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027b4:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027b6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027b9:	8b 0e                	mov    (%esi),%ecx
f01027bb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027be:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027c1:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027c4:	eb 03                	jmp    f01027c9 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027c6:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027c9:	39 c8                	cmp    %ecx,%eax
f01027cb:	7e 0b                	jle    f01027d8 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027cd:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027d1:	83 ea 0c             	sub    $0xc,%edx
f01027d4:	39 df                	cmp    %ebx,%edi
f01027d6:	75 ee                	jne    f01027c6 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027d8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027db:	89 06                	mov    %eax,(%esi)
	}
}
f01027dd:	83 c4 14             	add    $0x14,%esp
f01027e0:	5b                   	pop    %ebx
f01027e1:	5e                   	pop    %esi
f01027e2:	5f                   	pop    %edi
f01027e3:	5d                   	pop    %ebp
f01027e4:	c3                   	ret    

f01027e5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01027e5:	55                   	push   %ebp
f01027e6:	89 e5                	mov    %esp,%ebp
f01027e8:	57                   	push   %edi
f01027e9:	56                   	push   %esi
f01027ea:	53                   	push   %ebx
f01027eb:	83 ec 3c             	sub    $0x3c,%esp
f01027ee:	8b 75 08             	mov    0x8(%ebp),%esi
f01027f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01027f4:	c7 03 47 46 10 f0    	movl   $0xf0104647,(%ebx)
	info->eip_line = 0;
f01027fa:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102801:	c7 43 08 47 46 10 f0 	movl   $0xf0104647,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102808:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010280f:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102812:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102819:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010281f:	76 11                	jbe    f0102832 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102821:	b8 0e c0 10 f0       	mov    $0xf010c00e,%eax
f0102826:	3d 1d a2 10 f0       	cmp    $0xf010a21d,%eax
f010282b:	77 19                	ja     f0102846 <debuginfo_eip+0x61>
f010282d:	e9 aa 01 00 00       	jmp    f01029dc <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102832:	83 ec 04             	sub    $0x4,%esp
f0102835:	68 51 46 10 f0       	push   $0xf0104651
f010283a:	6a 7f                	push   $0x7f
f010283c:	68 5e 46 10 f0       	push   $0xf010465e
f0102841:	e8 45 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102846:	80 3d 0d c0 10 f0 00 	cmpb   $0x0,0xf010c00d
f010284d:	0f 85 90 01 00 00    	jne    f01029e3 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102853:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010285a:	b8 1c a2 10 f0       	mov    $0xf010a21c,%eax
f010285f:	2d 7c 48 10 f0       	sub    $0xf010487c,%eax
f0102864:	c1 f8 02             	sar    $0x2,%eax
f0102867:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010286d:	83 e8 01             	sub    $0x1,%eax
f0102870:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102873:	83 ec 08             	sub    $0x8,%esp
f0102876:	56                   	push   %esi
f0102877:	6a 64                	push   $0x64
f0102879:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010287c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010287f:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f0102884:	e8 66 fe ff ff       	call   f01026ef <stab_binsearch>
	if (lfile == 0)
f0102889:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010288c:	83 c4 10             	add    $0x10,%esp
f010288f:	85 c0                	test   %eax,%eax
f0102891:	0f 84 53 01 00 00    	je     f01029ea <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102897:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010289a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010289d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028a0:	83 ec 08             	sub    $0x8,%esp
f01028a3:	56                   	push   %esi
f01028a4:	6a 24                	push   $0x24
f01028a6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028a9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028ac:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f01028b1:	e8 39 fe ff ff       	call   f01026ef <stab_binsearch>

	if (lfun <= rfun) {
f01028b6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028b9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028bc:	83 c4 10             	add    $0x10,%esp
f01028bf:	39 d0                	cmp    %edx,%eax
f01028c1:	7f 40                	jg     f0102903 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028c3:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028c6:	c1 e1 02             	shl    $0x2,%ecx
f01028c9:	8d b9 7c 48 10 f0    	lea    -0xfefb784(%ecx),%edi
f01028cf:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028d2:	8b b9 7c 48 10 f0    	mov    -0xfefb784(%ecx),%edi
f01028d8:	b9 0e c0 10 f0       	mov    $0xf010c00e,%ecx
f01028dd:	81 e9 1d a2 10 f0    	sub    $0xf010a21d,%ecx
f01028e3:	39 cf                	cmp    %ecx,%edi
f01028e5:	73 09                	jae    f01028f0 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01028e7:	81 c7 1d a2 10 f0    	add    $0xf010a21d,%edi
f01028ed:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01028f0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01028f3:	8b 4f 08             	mov    0x8(%edi),%ecx
f01028f6:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01028f9:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01028fb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01028fe:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102901:	eb 0f                	jmp    f0102912 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102903:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102906:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102909:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010290c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010290f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102912:	83 ec 08             	sub    $0x8,%esp
f0102915:	6a 3a                	push   $0x3a
f0102917:	ff 73 08             	pushl  0x8(%ebx)
f010291a:	e8 59 08 00 00       	call   f0103178 <strfind>
f010291f:	2b 43 08             	sub    0x8(%ebx),%eax
f0102922:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102925:	83 c4 08             	add    $0x8,%esp
f0102928:	56                   	push   %esi
f0102929:	6a 44                	push   $0x44
f010292b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010292e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102931:	b8 7c 48 10 f0       	mov    $0xf010487c,%eax
f0102936:	e8 b4 fd ff ff       	call   f01026ef <stab_binsearch>
	
	if(lline > rline)
f010293b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010293e:	83 c4 10             	add    $0x10,%esp
f0102941:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0102944:	0f 8f a7 00 00 00    	jg     f01029f1 <debuginfo_eip+0x20c>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f010294a:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010294d:	8d 04 85 7c 48 10 f0 	lea    -0xfefb784(,%eax,4),%eax
f0102954:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102958:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010295b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010295e:	eb 06                	jmp    f0102966 <debuginfo_eip+0x181>
f0102960:	83 ea 01             	sub    $0x1,%edx
f0102963:	83 e8 0c             	sub    $0xc,%eax
f0102966:	39 d6                	cmp    %edx,%esi
f0102968:	7f 34                	jg     f010299e <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f010296a:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f010296e:	80 f9 84             	cmp    $0x84,%cl
f0102971:	74 0b                	je     f010297e <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102973:	80 f9 64             	cmp    $0x64,%cl
f0102976:	75 e8                	jne    f0102960 <debuginfo_eip+0x17b>
f0102978:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010297c:	74 e2                	je     f0102960 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010297e:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102981:	8b 14 85 7c 48 10 f0 	mov    -0xfefb784(,%eax,4),%edx
f0102988:	b8 0e c0 10 f0       	mov    $0xf010c00e,%eax
f010298d:	2d 1d a2 10 f0       	sub    $0xf010a21d,%eax
f0102992:	39 c2                	cmp    %eax,%edx
f0102994:	73 08                	jae    f010299e <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102996:	81 c2 1d a2 10 f0    	add    $0xf010a21d,%edx
f010299c:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010299e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029a1:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029a4:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029a9:	39 f2                	cmp    %esi,%edx
f01029ab:	7d 50                	jge    f01029fd <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f01029ad:	83 c2 01             	add    $0x1,%edx
f01029b0:	89 d0                	mov    %edx,%eax
f01029b2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029b5:	8d 14 95 7c 48 10 f0 	lea    -0xfefb784(,%edx,4),%edx
f01029bc:	eb 04                	jmp    f01029c2 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029be:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029c2:	39 c6                	cmp    %eax,%esi
f01029c4:	7e 32                	jle    f01029f8 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029c6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029ca:	83 c0 01             	add    $0x1,%eax
f01029cd:	83 c2 0c             	add    $0xc,%edx
f01029d0:	80 f9 a0             	cmp    $0xa0,%cl
f01029d3:	74 e9                	je     f01029be <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01029da:	eb 21                	jmp    f01029fd <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029e1:	eb 1a                	jmp    f01029fd <debuginfo_eip+0x218>
f01029e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029e8:	eb 13                	jmp    f01029fd <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01029ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029ef:	eb 0c                	jmp    f01029fd <debuginfo_eip+0x218>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f01029f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029f6:	eb 05                	jmp    f01029fd <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a00:	5b                   	pop    %ebx
f0102a01:	5e                   	pop    %esi
f0102a02:	5f                   	pop    %edi
f0102a03:	5d                   	pop    %ebp
f0102a04:	c3                   	ret    

f0102a05 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a05:	55                   	push   %ebp
f0102a06:	89 e5                	mov    %esp,%ebp
f0102a08:	57                   	push   %edi
f0102a09:	56                   	push   %esi
f0102a0a:	53                   	push   %ebx
f0102a0b:	83 ec 1c             	sub    $0x1c,%esp
f0102a0e:	89 c7                	mov    %eax,%edi
f0102a10:	89 d6                	mov    %edx,%esi
f0102a12:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a15:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a18:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a1b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a1e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a21:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a26:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a29:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a2c:	39 d3                	cmp    %edx,%ebx
f0102a2e:	72 05                	jb     f0102a35 <printnum+0x30>
f0102a30:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a33:	77 45                	ja     f0102a7a <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a35:	83 ec 0c             	sub    $0xc,%esp
f0102a38:	ff 75 18             	pushl  0x18(%ebp)
f0102a3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a3e:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a41:	53                   	push   %ebx
f0102a42:	ff 75 10             	pushl  0x10(%ebp)
f0102a45:	83 ec 08             	sub    $0x8,%esp
f0102a48:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a4b:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a4e:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a51:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a54:	e8 47 09 00 00       	call   f01033a0 <__udivdi3>
f0102a59:	83 c4 18             	add    $0x18,%esp
f0102a5c:	52                   	push   %edx
f0102a5d:	50                   	push   %eax
f0102a5e:	89 f2                	mov    %esi,%edx
f0102a60:	89 f8                	mov    %edi,%eax
f0102a62:	e8 9e ff ff ff       	call   f0102a05 <printnum>
f0102a67:	83 c4 20             	add    $0x20,%esp
f0102a6a:	eb 18                	jmp    f0102a84 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a6c:	83 ec 08             	sub    $0x8,%esp
f0102a6f:	56                   	push   %esi
f0102a70:	ff 75 18             	pushl  0x18(%ebp)
f0102a73:	ff d7                	call   *%edi
f0102a75:	83 c4 10             	add    $0x10,%esp
f0102a78:	eb 03                	jmp    f0102a7d <printnum+0x78>
f0102a7a:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a7d:	83 eb 01             	sub    $0x1,%ebx
f0102a80:	85 db                	test   %ebx,%ebx
f0102a82:	7f e8                	jg     f0102a6c <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a84:	83 ec 08             	sub    $0x8,%esp
f0102a87:	56                   	push   %esi
f0102a88:	83 ec 04             	sub    $0x4,%esp
f0102a8b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a8e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a91:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a94:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a97:	e8 34 0a 00 00       	call   f01034d0 <__umoddi3>
f0102a9c:	83 c4 14             	add    $0x14,%esp
f0102a9f:	0f be 80 6c 46 10 f0 	movsbl -0xfefb994(%eax),%eax
f0102aa6:	50                   	push   %eax
f0102aa7:	ff d7                	call   *%edi
}
f0102aa9:	83 c4 10             	add    $0x10,%esp
f0102aac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aaf:	5b                   	pop    %ebx
f0102ab0:	5e                   	pop    %esi
f0102ab1:	5f                   	pop    %edi
f0102ab2:	5d                   	pop    %ebp
f0102ab3:	c3                   	ret    

f0102ab4 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102ab4:	55                   	push   %ebp
f0102ab5:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ab7:	83 fa 01             	cmp    $0x1,%edx
f0102aba:	7e 0e                	jle    f0102aca <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102abc:	8b 10                	mov    (%eax),%edx
f0102abe:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ac1:	89 08                	mov    %ecx,(%eax)
f0102ac3:	8b 02                	mov    (%edx),%eax
f0102ac5:	8b 52 04             	mov    0x4(%edx),%edx
f0102ac8:	eb 22                	jmp    f0102aec <getuint+0x38>
	else if (lflag)
f0102aca:	85 d2                	test   %edx,%edx
f0102acc:	74 10                	je     f0102ade <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102ace:	8b 10                	mov    (%eax),%edx
f0102ad0:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ad3:	89 08                	mov    %ecx,(%eax)
f0102ad5:	8b 02                	mov    (%edx),%eax
f0102ad7:	ba 00 00 00 00       	mov    $0x0,%edx
f0102adc:	eb 0e                	jmp    f0102aec <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102ade:	8b 10                	mov    (%eax),%edx
f0102ae0:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ae3:	89 08                	mov    %ecx,(%eax)
f0102ae5:	8b 02                	mov    (%edx),%eax
f0102ae7:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102aec:	5d                   	pop    %ebp
f0102aed:	c3                   	ret    

f0102aee <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102aee:	55                   	push   %ebp
f0102aef:	89 e5                	mov    %esp,%ebp
f0102af1:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102af4:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102af8:	8b 10                	mov    (%eax),%edx
f0102afa:	3b 50 04             	cmp    0x4(%eax),%edx
f0102afd:	73 0a                	jae    f0102b09 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102aff:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b02:	89 08                	mov    %ecx,(%eax)
f0102b04:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b07:	88 02                	mov    %al,(%edx)
}
f0102b09:	5d                   	pop    %ebp
f0102b0a:	c3                   	ret    

f0102b0b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b0b:	55                   	push   %ebp
f0102b0c:	89 e5                	mov    %esp,%ebp
f0102b0e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b11:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b14:	50                   	push   %eax
f0102b15:	ff 75 10             	pushl  0x10(%ebp)
f0102b18:	ff 75 0c             	pushl  0xc(%ebp)
f0102b1b:	ff 75 08             	pushl  0x8(%ebp)
f0102b1e:	e8 05 00 00 00       	call   f0102b28 <vprintfmt>
	va_end(ap);
}
f0102b23:	83 c4 10             	add    $0x10,%esp
f0102b26:	c9                   	leave  
f0102b27:	c3                   	ret    

f0102b28 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b28:	55                   	push   %ebp
f0102b29:	89 e5                	mov    %esp,%ebp
f0102b2b:	57                   	push   %edi
f0102b2c:	56                   	push   %esi
f0102b2d:	53                   	push   %ebx
f0102b2e:	83 ec 2c             	sub    $0x2c,%esp
f0102b31:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b34:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b37:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b3a:	eb 12                	jmp    f0102b4e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b3c:	85 c0                	test   %eax,%eax
f0102b3e:	0f 84 89 03 00 00    	je     f0102ecd <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b44:	83 ec 08             	sub    $0x8,%esp
f0102b47:	53                   	push   %ebx
f0102b48:	50                   	push   %eax
f0102b49:	ff d6                	call   *%esi
f0102b4b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b4e:	83 c7 01             	add    $0x1,%edi
f0102b51:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b55:	83 f8 25             	cmp    $0x25,%eax
f0102b58:	75 e2                	jne    f0102b3c <vprintfmt+0x14>
f0102b5a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b5e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b65:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b6c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b73:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b78:	eb 07                	jmp    f0102b81 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b7d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b81:	8d 47 01             	lea    0x1(%edi),%eax
f0102b84:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b87:	0f b6 07             	movzbl (%edi),%eax
f0102b8a:	0f b6 c8             	movzbl %al,%ecx
f0102b8d:	83 e8 23             	sub    $0x23,%eax
f0102b90:	3c 55                	cmp    $0x55,%al
f0102b92:	0f 87 1a 03 00 00    	ja     f0102eb2 <vprintfmt+0x38a>
f0102b98:	0f b6 c0             	movzbl %al,%eax
f0102b9b:	ff 24 85 f8 46 10 f0 	jmp    *-0xfefb908(,%eax,4)
f0102ba2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102ba5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102ba9:	eb d6                	jmp    f0102b81 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bae:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bb6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bb9:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102bbd:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102bc0:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bc3:	83 fa 09             	cmp    $0x9,%edx
f0102bc6:	77 39                	ja     f0102c01 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102bc8:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bcb:	eb e9                	jmp    f0102bb6 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bcd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bd0:	8d 48 04             	lea    0x4(%eax),%ecx
f0102bd3:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102bd6:	8b 00                	mov    (%eax),%eax
f0102bd8:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bdb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102bde:	eb 27                	jmp    f0102c07 <vprintfmt+0xdf>
f0102be0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102be3:	85 c0                	test   %eax,%eax
f0102be5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102bea:	0f 49 c8             	cmovns %eax,%ecx
f0102bed:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bf3:	eb 8c                	jmp    f0102b81 <vprintfmt+0x59>
f0102bf5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102bf8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102bff:	eb 80                	jmp    f0102b81 <vprintfmt+0x59>
f0102c01:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c04:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c07:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c0b:	0f 89 70 ff ff ff    	jns    f0102b81 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c11:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c14:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c17:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c1e:	e9 5e ff ff ff       	jmp    f0102b81 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c23:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c29:	e9 53 ff ff ff       	jmp    f0102b81 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c31:	8d 50 04             	lea    0x4(%eax),%edx
f0102c34:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c37:	83 ec 08             	sub    $0x8,%esp
f0102c3a:	53                   	push   %ebx
f0102c3b:	ff 30                	pushl  (%eax)
f0102c3d:	ff d6                	call   *%esi
			break;
f0102c3f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c45:	e9 04 ff ff ff       	jmp    f0102b4e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c4a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c4d:	8d 50 04             	lea    0x4(%eax),%edx
f0102c50:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c53:	8b 00                	mov    (%eax),%eax
f0102c55:	99                   	cltd   
f0102c56:	31 d0                	xor    %edx,%eax
f0102c58:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c5a:	83 f8 06             	cmp    $0x6,%eax
f0102c5d:	7f 0b                	jg     f0102c6a <vprintfmt+0x142>
f0102c5f:	8b 14 85 50 48 10 f0 	mov    -0xfefb7b0(,%eax,4),%edx
f0102c66:	85 d2                	test   %edx,%edx
f0102c68:	75 18                	jne    f0102c82 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c6a:	50                   	push   %eax
f0102c6b:	68 84 46 10 f0       	push   $0xf0104684
f0102c70:	53                   	push   %ebx
f0102c71:	56                   	push   %esi
f0102c72:	e8 94 fe ff ff       	call   f0102b0b <printfmt>
f0102c77:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c7d:	e9 cc fe ff ff       	jmp    f0102b4e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c82:	52                   	push   %edx
f0102c83:	68 9c 43 10 f0       	push   $0xf010439c
f0102c88:	53                   	push   %ebx
f0102c89:	56                   	push   %esi
f0102c8a:	e8 7c fe ff ff       	call   f0102b0b <printfmt>
f0102c8f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c95:	e9 b4 fe ff ff       	jmp    f0102b4e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c9a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c9d:	8d 50 04             	lea    0x4(%eax),%edx
f0102ca0:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ca3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102ca5:	85 ff                	test   %edi,%edi
f0102ca7:	b8 7d 46 10 f0       	mov    $0xf010467d,%eax
f0102cac:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102caf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cb3:	0f 8e 94 00 00 00    	jle    f0102d4d <vprintfmt+0x225>
f0102cb9:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cbd:	0f 84 98 00 00 00    	je     f0102d5b <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cc3:	83 ec 08             	sub    $0x8,%esp
f0102cc6:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cc9:	57                   	push   %edi
f0102cca:	e8 5f 03 00 00       	call   f010302e <strnlen>
f0102ccf:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cd2:	29 c1                	sub    %eax,%ecx
f0102cd4:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102cd7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cda:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102cde:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ce1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ce4:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ce6:	eb 0f                	jmp    f0102cf7 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102ce8:	83 ec 08             	sub    $0x8,%esp
f0102ceb:	53                   	push   %ebx
f0102cec:	ff 75 e0             	pushl  -0x20(%ebp)
f0102cef:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cf1:	83 ef 01             	sub    $0x1,%edi
f0102cf4:	83 c4 10             	add    $0x10,%esp
f0102cf7:	85 ff                	test   %edi,%edi
f0102cf9:	7f ed                	jg     f0102ce8 <vprintfmt+0x1c0>
f0102cfb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cfe:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d01:	85 c9                	test   %ecx,%ecx
f0102d03:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d08:	0f 49 c1             	cmovns %ecx,%eax
f0102d0b:	29 c1                	sub    %eax,%ecx
f0102d0d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d10:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d13:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d16:	89 cb                	mov    %ecx,%ebx
f0102d18:	eb 4d                	jmp    f0102d67 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d1a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d1e:	74 1b                	je     f0102d3b <vprintfmt+0x213>
f0102d20:	0f be c0             	movsbl %al,%eax
f0102d23:	83 e8 20             	sub    $0x20,%eax
f0102d26:	83 f8 5e             	cmp    $0x5e,%eax
f0102d29:	76 10                	jbe    f0102d3b <vprintfmt+0x213>
					putch('?', putdat);
f0102d2b:	83 ec 08             	sub    $0x8,%esp
f0102d2e:	ff 75 0c             	pushl  0xc(%ebp)
f0102d31:	6a 3f                	push   $0x3f
f0102d33:	ff 55 08             	call   *0x8(%ebp)
f0102d36:	83 c4 10             	add    $0x10,%esp
f0102d39:	eb 0d                	jmp    f0102d48 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d3b:	83 ec 08             	sub    $0x8,%esp
f0102d3e:	ff 75 0c             	pushl  0xc(%ebp)
f0102d41:	52                   	push   %edx
f0102d42:	ff 55 08             	call   *0x8(%ebp)
f0102d45:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d48:	83 eb 01             	sub    $0x1,%ebx
f0102d4b:	eb 1a                	jmp    f0102d67 <vprintfmt+0x23f>
f0102d4d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d50:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d53:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d56:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d59:	eb 0c                	jmp    f0102d67 <vprintfmt+0x23f>
f0102d5b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d5e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d61:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d64:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d67:	83 c7 01             	add    $0x1,%edi
f0102d6a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d6e:	0f be d0             	movsbl %al,%edx
f0102d71:	85 d2                	test   %edx,%edx
f0102d73:	74 23                	je     f0102d98 <vprintfmt+0x270>
f0102d75:	85 f6                	test   %esi,%esi
f0102d77:	78 a1                	js     f0102d1a <vprintfmt+0x1f2>
f0102d79:	83 ee 01             	sub    $0x1,%esi
f0102d7c:	79 9c                	jns    f0102d1a <vprintfmt+0x1f2>
f0102d7e:	89 df                	mov    %ebx,%edi
f0102d80:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d83:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d86:	eb 18                	jmp    f0102da0 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d88:	83 ec 08             	sub    $0x8,%esp
f0102d8b:	53                   	push   %ebx
f0102d8c:	6a 20                	push   $0x20
f0102d8e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d90:	83 ef 01             	sub    $0x1,%edi
f0102d93:	83 c4 10             	add    $0x10,%esp
f0102d96:	eb 08                	jmp    f0102da0 <vprintfmt+0x278>
f0102d98:	89 df                	mov    %ebx,%edi
f0102d9a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d9d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102da0:	85 ff                	test   %edi,%edi
f0102da2:	7f e4                	jg     f0102d88 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102da4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102da7:	e9 a2 fd ff ff       	jmp    f0102b4e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dac:	83 fa 01             	cmp    $0x1,%edx
f0102daf:	7e 16                	jle    f0102dc7 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102db1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102db4:	8d 50 08             	lea    0x8(%eax),%edx
f0102db7:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dba:	8b 50 04             	mov    0x4(%eax),%edx
f0102dbd:	8b 00                	mov    (%eax),%eax
f0102dbf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dc2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102dc5:	eb 32                	jmp    f0102df9 <vprintfmt+0x2d1>
	else if (lflag)
f0102dc7:	85 d2                	test   %edx,%edx
f0102dc9:	74 18                	je     f0102de3 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102dcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dce:	8d 50 04             	lea    0x4(%eax),%edx
f0102dd1:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dd4:	8b 00                	mov    (%eax),%eax
f0102dd6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dd9:	89 c1                	mov    %eax,%ecx
f0102ddb:	c1 f9 1f             	sar    $0x1f,%ecx
f0102dde:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102de1:	eb 16                	jmp    f0102df9 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102de3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de6:	8d 50 04             	lea    0x4(%eax),%edx
f0102de9:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dec:	8b 00                	mov    (%eax),%eax
f0102dee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102df1:	89 c1                	mov    %eax,%ecx
f0102df3:	c1 f9 1f             	sar    $0x1f,%ecx
f0102df6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102df9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102dfc:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102dff:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e04:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e08:	79 74                	jns    f0102e7e <vprintfmt+0x356>
				putch('-', putdat);
f0102e0a:	83 ec 08             	sub    $0x8,%esp
f0102e0d:	53                   	push   %ebx
f0102e0e:	6a 2d                	push   $0x2d
f0102e10:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e12:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e15:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e18:	f7 d8                	neg    %eax
f0102e1a:	83 d2 00             	adc    $0x0,%edx
f0102e1d:	f7 da                	neg    %edx
f0102e1f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e22:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e27:	eb 55                	jmp    f0102e7e <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e29:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e2c:	e8 83 fc ff ff       	call   f0102ab4 <getuint>
			base = 10;
f0102e31:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e36:	eb 46                	jmp    f0102e7e <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102e38:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e3b:	e8 74 fc ff ff       	call   f0102ab4 <getuint>
			base = 8;
f0102e40:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e45:	eb 37                	jmp    f0102e7e <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e47:	83 ec 08             	sub    $0x8,%esp
f0102e4a:	53                   	push   %ebx
f0102e4b:	6a 30                	push   $0x30
f0102e4d:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e4f:	83 c4 08             	add    $0x8,%esp
f0102e52:	53                   	push   %ebx
f0102e53:	6a 78                	push   $0x78
f0102e55:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e57:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e5a:	8d 50 04             	lea    0x4(%eax),%edx
f0102e5d:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e60:	8b 00                	mov    (%eax),%eax
f0102e62:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e67:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e6a:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e6f:	eb 0d                	jmp    f0102e7e <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e71:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e74:	e8 3b fc ff ff       	call   f0102ab4 <getuint>
			base = 16;
f0102e79:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e7e:	83 ec 0c             	sub    $0xc,%esp
f0102e81:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e85:	57                   	push   %edi
f0102e86:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e89:	51                   	push   %ecx
f0102e8a:	52                   	push   %edx
f0102e8b:	50                   	push   %eax
f0102e8c:	89 da                	mov    %ebx,%edx
f0102e8e:	89 f0                	mov    %esi,%eax
f0102e90:	e8 70 fb ff ff       	call   f0102a05 <printnum>
			break;
f0102e95:	83 c4 20             	add    $0x20,%esp
f0102e98:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e9b:	e9 ae fc ff ff       	jmp    f0102b4e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102ea0:	83 ec 08             	sub    $0x8,%esp
f0102ea3:	53                   	push   %ebx
f0102ea4:	51                   	push   %ecx
f0102ea5:	ff d6                	call   *%esi
			break;
f0102ea7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102eaa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ead:	e9 9c fc ff ff       	jmp    f0102b4e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102eb2:	83 ec 08             	sub    $0x8,%esp
f0102eb5:	53                   	push   %ebx
f0102eb6:	6a 25                	push   $0x25
f0102eb8:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102eba:	83 c4 10             	add    $0x10,%esp
f0102ebd:	eb 03                	jmp    f0102ec2 <vprintfmt+0x39a>
f0102ebf:	83 ef 01             	sub    $0x1,%edi
f0102ec2:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ec6:	75 f7                	jne    f0102ebf <vprintfmt+0x397>
f0102ec8:	e9 81 fc ff ff       	jmp    f0102b4e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ecd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ed0:	5b                   	pop    %ebx
f0102ed1:	5e                   	pop    %esi
f0102ed2:	5f                   	pop    %edi
f0102ed3:	5d                   	pop    %ebp
f0102ed4:	c3                   	ret    

f0102ed5 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102ed5:	55                   	push   %ebp
f0102ed6:	89 e5                	mov    %esp,%ebp
f0102ed8:	83 ec 18             	sub    $0x18,%esp
f0102edb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ede:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102ee1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102ee4:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102ee8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102eeb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102ef2:	85 c0                	test   %eax,%eax
f0102ef4:	74 26                	je     f0102f1c <vsnprintf+0x47>
f0102ef6:	85 d2                	test   %edx,%edx
f0102ef8:	7e 22                	jle    f0102f1c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102efa:	ff 75 14             	pushl  0x14(%ebp)
f0102efd:	ff 75 10             	pushl  0x10(%ebp)
f0102f00:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f03:	50                   	push   %eax
f0102f04:	68 ee 2a 10 f0       	push   $0xf0102aee
f0102f09:	e8 1a fc ff ff       	call   f0102b28 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f11:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f14:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f17:	83 c4 10             	add    $0x10,%esp
f0102f1a:	eb 05                	jmp    f0102f21 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f1c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f21:	c9                   	leave  
f0102f22:	c3                   	ret    

f0102f23 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f23:	55                   	push   %ebp
f0102f24:	89 e5                	mov    %esp,%ebp
f0102f26:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f29:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f2c:	50                   	push   %eax
f0102f2d:	ff 75 10             	pushl  0x10(%ebp)
f0102f30:	ff 75 0c             	pushl  0xc(%ebp)
f0102f33:	ff 75 08             	pushl  0x8(%ebp)
f0102f36:	e8 9a ff ff ff       	call   f0102ed5 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f3b:	c9                   	leave  
f0102f3c:	c3                   	ret    

f0102f3d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f3d:	55                   	push   %ebp
f0102f3e:	89 e5                	mov    %esp,%ebp
f0102f40:	57                   	push   %edi
f0102f41:	56                   	push   %esi
f0102f42:	53                   	push   %ebx
f0102f43:	83 ec 0c             	sub    $0xc,%esp
f0102f46:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f49:	85 c0                	test   %eax,%eax
f0102f4b:	74 11                	je     f0102f5e <readline+0x21>
		cprintf("%s", prompt);
f0102f4d:	83 ec 08             	sub    $0x8,%esp
f0102f50:	50                   	push   %eax
f0102f51:	68 9c 43 10 f0       	push   $0xf010439c
f0102f56:	e8 80 f7 ff ff       	call   f01026db <cprintf>
f0102f5b:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f5e:	83 ec 0c             	sub    $0xc,%esp
f0102f61:	6a 00                	push   $0x0
f0102f63:	e8 b9 d6 ff ff       	call   f0100621 <iscons>
f0102f68:	89 c7                	mov    %eax,%edi
f0102f6a:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f6d:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f72:	e8 99 d6 ff ff       	call   f0100610 <getchar>
f0102f77:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f79:	85 c0                	test   %eax,%eax
f0102f7b:	79 18                	jns    f0102f95 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f7d:	83 ec 08             	sub    $0x8,%esp
f0102f80:	50                   	push   %eax
f0102f81:	68 6c 48 10 f0       	push   $0xf010486c
f0102f86:	e8 50 f7 ff ff       	call   f01026db <cprintf>
			return NULL;
f0102f8b:	83 c4 10             	add    $0x10,%esp
f0102f8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f93:	eb 79                	jmp    f010300e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f95:	83 f8 08             	cmp    $0x8,%eax
f0102f98:	0f 94 c2             	sete   %dl
f0102f9b:	83 f8 7f             	cmp    $0x7f,%eax
f0102f9e:	0f 94 c0             	sete   %al
f0102fa1:	08 c2                	or     %al,%dl
f0102fa3:	74 1a                	je     f0102fbf <readline+0x82>
f0102fa5:	85 f6                	test   %esi,%esi
f0102fa7:	7e 16                	jle    f0102fbf <readline+0x82>
			if (echoing)
f0102fa9:	85 ff                	test   %edi,%edi
f0102fab:	74 0d                	je     f0102fba <readline+0x7d>
				cputchar('\b');
f0102fad:	83 ec 0c             	sub    $0xc,%esp
f0102fb0:	6a 08                	push   $0x8
f0102fb2:	e8 49 d6 ff ff       	call   f0100600 <cputchar>
f0102fb7:	83 c4 10             	add    $0x10,%esp
			i--;
f0102fba:	83 ee 01             	sub    $0x1,%esi
f0102fbd:	eb b3                	jmp    f0102f72 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102fbf:	83 fb 1f             	cmp    $0x1f,%ebx
f0102fc2:	7e 23                	jle    f0102fe7 <readline+0xaa>
f0102fc4:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102fca:	7f 1b                	jg     f0102fe7 <readline+0xaa>
			if (echoing)
f0102fcc:	85 ff                	test   %edi,%edi
f0102fce:	74 0c                	je     f0102fdc <readline+0x9f>
				cputchar(c);
f0102fd0:	83 ec 0c             	sub    $0xc,%esp
f0102fd3:	53                   	push   %ebx
f0102fd4:	e8 27 d6 ff ff       	call   f0100600 <cputchar>
f0102fd9:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102fdc:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f0102fe2:	8d 76 01             	lea    0x1(%esi),%esi
f0102fe5:	eb 8b                	jmp    f0102f72 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102fe7:	83 fb 0a             	cmp    $0xa,%ebx
f0102fea:	74 05                	je     f0102ff1 <readline+0xb4>
f0102fec:	83 fb 0d             	cmp    $0xd,%ebx
f0102fef:	75 81                	jne    f0102f72 <readline+0x35>
			if (echoing)
f0102ff1:	85 ff                	test   %edi,%edi
f0102ff3:	74 0d                	je     f0103002 <readline+0xc5>
				cputchar('\n');
f0102ff5:	83 ec 0c             	sub    $0xc,%esp
f0102ff8:	6a 0a                	push   $0xa
f0102ffa:	e8 01 d6 ff ff       	call   f0100600 <cputchar>
f0102fff:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103002:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f0103009:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f010300e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103011:	5b                   	pop    %ebx
f0103012:	5e                   	pop    %esi
f0103013:	5f                   	pop    %edi
f0103014:	5d                   	pop    %ebp
f0103015:	c3                   	ret    

f0103016 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103016:	55                   	push   %ebp
f0103017:	89 e5                	mov    %esp,%ebp
f0103019:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010301c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103021:	eb 03                	jmp    f0103026 <strlen+0x10>
		n++;
f0103023:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103026:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010302a:	75 f7                	jne    f0103023 <strlen+0xd>
		n++;
	return n;
}
f010302c:	5d                   	pop    %ebp
f010302d:	c3                   	ret    

f010302e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010302e:	55                   	push   %ebp
f010302f:	89 e5                	mov    %esp,%ebp
f0103031:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103034:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103037:	ba 00 00 00 00       	mov    $0x0,%edx
f010303c:	eb 03                	jmp    f0103041 <strnlen+0x13>
		n++;
f010303e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103041:	39 c2                	cmp    %eax,%edx
f0103043:	74 08                	je     f010304d <strnlen+0x1f>
f0103045:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103049:	75 f3                	jne    f010303e <strnlen+0x10>
f010304b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010304d:	5d                   	pop    %ebp
f010304e:	c3                   	ret    

f010304f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010304f:	55                   	push   %ebp
f0103050:	89 e5                	mov    %esp,%ebp
f0103052:	53                   	push   %ebx
f0103053:	8b 45 08             	mov    0x8(%ebp),%eax
f0103056:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103059:	89 c2                	mov    %eax,%edx
f010305b:	83 c2 01             	add    $0x1,%edx
f010305e:	83 c1 01             	add    $0x1,%ecx
f0103061:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103065:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103068:	84 db                	test   %bl,%bl
f010306a:	75 ef                	jne    f010305b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010306c:	5b                   	pop    %ebx
f010306d:	5d                   	pop    %ebp
f010306e:	c3                   	ret    

f010306f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010306f:	55                   	push   %ebp
f0103070:	89 e5                	mov    %esp,%ebp
f0103072:	53                   	push   %ebx
f0103073:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103076:	53                   	push   %ebx
f0103077:	e8 9a ff ff ff       	call   f0103016 <strlen>
f010307c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010307f:	ff 75 0c             	pushl  0xc(%ebp)
f0103082:	01 d8                	add    %ebx,%eax
f0103084:	50                   	push   %eax
f0103085:	e8 c5 ff ff ff       	call   f010304f <strcpy>
	return dst;
}
f010308a:	89 d8                	mov    %ebx,%eax
f010308c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010308f:	c9                   	leave  
f0103090:	c3                   	ret    

f0103091 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103091:	55                   	push   %ebp
f0103092:	89 e5                	mov    %esp,%ebp
f0103094:	56                   	push   %esi
f0103095:	53                   	push   %ebx
f0103096:	8b 75 08             	mov    0x8(%ebp),%esi
f0103099:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010309c:	89 f3                	mov    %esi,%ebx
f010309e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030a1:	89 f2                	mov    %esi,%edx
f01030a3:	eb 0f                	jmp    f01030b4 <strncpy+0x23>
		*dst++ = *src;
f01030a5:	83 c2 01             	add    $0x1,%edx
f01030a8:	0f b6 01             	movzbl (%ecx),%eax
f01030ab:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030ae:	80 39 01             	cmpb   $0x1,(%ecx)
f01030b1:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030b4:	39 da                	cmp    %ebx,%edx
f01030b6:	75 ed                	jne    f01030a5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030b8:	89 f0                	mov    %esi,%eax
f01030ba:	5b                   	pop    %ebx
f01030bb:	5e                   	pop    %esi
f01030bc:	5d                   	pop    %ebp
f01030bd:	c3                   	ret    

f01030be <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030be:	55                   	push   %ebp
f01030bf:	89 e5                	mov    %esp,%ebp
f01030c1:	56                   	push   %esi
f01030c2:	53                   	push   %ebx
f01030c3:	8b 75 08             	mov    0x8(%ebp),%esi
f01030c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030c9:	8b 55 10             	mov    0x10(%ebp),%edx
f01030cc:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030ce:	85 d2                	test   %edx,%edx
f01030d0:	74 21                	je     f01030f3 <strlcpy+0x35>
f01030d2:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01030d6:	89 f2                	mov    %esi,%edx
f01030d8:	eb 09                	jmp    f01030e3 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01030da:	83 c2 01             	add    $0x1,%edx
f01030dd:	83 c1 01             	add    $0x1,%ecx
f01030e0:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01030e3:	39 c2                	cmp    %eax,%edx
f01030e5:	74 09                	je     f01030f0 <strlcpy+0x32>
f01030e7:	0f b6 19             	movzbl (%ecx),%ebx
f01030ea:	84 db                	test   %bl,%bl
f01030ec:	75 ec                	jne    f01030da <strlcpy+0x1c>
f01030ee:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01030f0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01030f3:	29 f0                	sub    %esi,%eax
}
f01030f5:	5b                   	pop    %ebx
f01030f6:	5e                   	pop    %esi
f01030f7:	5d                   	pop    %ebp
f01030f8:	c3                   	ret    

f01030f9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01030f9:	55                   	push   %ebp
f01030fa:	89 e5                	mov    %esp,%ebp
f01030fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030ff:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103102:	eb 06                	jmp    f010310a <strcmp+0x11>
		p++, q++;
f0103104:	83 c1 01             	add    $0x1,%ecx
f0103107:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010310a:	0f b6 01             	movzbl (%ecx),%eax
f010310d:	84 c0                	test   %al,%al
f010310f:	74 04                	je     f0103115 <strcmp+0x1c>
f0103111:	3a 02                	cmp    (%edx),%al
f0103113:	74 ef                	je     f0103104 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103115:	0f b6 c0             	movzbl %al,%eax
f0103118:	0f b6 12             	movzbl (%edx),%edx
f010311b:	29 d0                	sub    %edx,%eax
}
f010311d:	5d                   	pop    %ebp
f010311e:	c3                   	ret    

f010311f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010311f:	55                   	push   %ebp
f0103120:	89 e5                	mov    %esp,%ebp
f0103122:	53                   	push   %ebx
f0103123:	8b 45 08             	mov    0x8(%ebp),%eax
f0103126:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103129:	89 c3                	mov    %eax,%ebx
f010312b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010312e:	eb 06                	jmp    f0103136 <strncmp+0x17>
		n--, p++, q++;
f0103130:	83 c0 01             	add    $0x1,%eax
f0103133:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103136:	39 d8                	cmp    %ebx,%eax
f0103138:	74 15                	je     f010314f <strncmp+0x30>
f010313a:	0f b6 08             	movzbl (%eax),%ecx
f010313d:	84 c9                	test   %cl,%cl
f010313f:	74 04                	je     f0103145 <strncmp+0x26>
f0103141:	3a 0a                	cmp    (%edx),%cl
f0103143:	74 eb                	je     f0103130 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103145:	0f b6 00             	movzbl (%eax),%eax
f0103148:	0f b6 12             	movzbl (%edx),%edx
f010314b:	29 d0                	sub    %edx,%eax
f010314d:	eb 05                	jmp    f0103154 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010314f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103154:	5b                   	pop    %ebx
f0103155:	5d                   	pop    %ebp
f0103156:	c3                   	ret    

f0103157 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103157:	55                   	push   %ebp
f0103158:	89 e5                	mov    %esp,%ebp
f010315a:	8b 45 08             	mov    0x8(%ebp),%eax
f010315d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103161:	eb 07                	jmp    f010316a <strchr+0x13>
		if (*s == c)
f0103163:	38 ca                	cmp    %cl,%dl
f0103165:	74 0f                	je     f0103176 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103167:	83 c0 01             	add    $0x1,%eax
f010316a:	0f b6 10             	movzbl (%eax),%edx
f010316d:	84 d2                	test   %dl,%dl
f010316f:	75 f2                	jne    f0103163 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103171:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103176:	5d                   	pop    %ebp
f0103177:	c3                   	ret    

f0103178 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103178:	55                   	push   %ebp
f0103179:	89 e5                	mov    %esp,%ebp
f010317b:	8b 45 08             	mov    0x8(%ebp),%eax
f010317e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103182:	eb 03                	jmp    f0103187 <strfind+0xf>
f0103184:	83 c0 01             	add    $0x1,%eax
f0103187:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010318a:	38 ca                	cmp    %cl,%dl
f010318c:	74 04                	je     f0103192 <strfind+0x1a>
f010318e:	84 d2                	test   %dl,%dl
f0103190:	75 f2                	jne    f0103184 <strfind+0xc>
			break;
	return (char *) s;
}
f0103192:	5d                   	pop    %ebp
f0103193:	c3                   	ret    

f0103194 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103194:	55                   	push   %ebp
f0103195:	89 e5                	mov    %esp,%ebp
f0103197:	57                   	push   %edi
f0103198:	56                   	push   %esi
f0103199:	53                   	push   %ebx
f010319a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010319d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031a0:	85 c9                	test   %ecx,%ecx
f01031a2:	74 36                	je     f01031da <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031a4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031aa:	75 28                	jne    f01031d4 <memset+0x40>
f01031ac:	f6 c1 03             	test   $0x3,%cl
f01031af:	75 23                	jne    f01031d4 <memset+0x40>
		c &= 0xFF;
f01031b1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031b5:	89 d3                	mov    %edx,%ebx
f01031b7:	c1 e3 08             	shl    $0x8,%ebx
f01031ba:	89 d6                	mov    %edx,%esi
f01031bc:	c1 e6 18             	shl    $0x18,%esi
f01031bf:	89 d0                	mov    %edx,%eax
f01031c1:	c1 e0 10             	shl    $0x10,%eax
f01031c4:	09 f0                	or     %esi,%eax
f01031c6:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031c8:	89 d8                	mov    %ebx,%eax
f01031ca:	09 d0                	or     %edx,%eax
f01031cc:	c1 e9 02             	shr    $0x2,%ecx
f01031cf:	fc                   	cld    
f01031d0:	f3 ab                	rep stos %eax,%es:(%edi)
f01031d2:	eb 06                	jmp    f01031da <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031d7:	fc                   	cld    
f01031d8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01031da:	89 f8                	mov    %edi,%eax
f01031dc:	5b                   	pop    %ebx
f01031dd:	5e                   	pop    %esi
f01031de:	5f                   	pop    %edi
f01031df:	5d                   	pop    %ebp
f01031e0:	c3                   	ret    

f01031e1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031e1:	55                   	push   %ebp
f01031e2:	89 e5                	mov    %esp,%ebp
f01031e4:	57                   	push   %edi
f01031e5:	56                   	push   %esi
f01031e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01031ec:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01031ef:	39 c6                	cmp    %eax,%esi
f01031f1:	73 35                	jae    f0103228 <memmove+0x47>
f01031f3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01031f6:	39 d0                	cmp    %edx,%eax
f01031f8:	73 2e                	jae    f0103228 <memmove+0x47>
		s += n;
		d += n;
f01031fa:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031fd:	89 d6                	mov    %edx,%esi
f01031ff:	09 fe                	or     %edi,%esi
f0103201:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103207:	75 13                	jne    f010321c <memmove+0x3b>
f0103209:	f6 c1 03             	test   $0x3,%cl
f010320c:	75 0e                	jne    f010321c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010320e:	83 ef 04             	sub    $0x4,%edi
f0103211:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103214:	c1 e9 02             	shr    $0x2,%ecx
f0103217:	fd                   	std    
f0103218:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010321a:	eb 09                	jmp    f0103225 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010321c:	83 ef 01             	sub    $0x1,%edi
f010321f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103222:	fd                   	std    
f0103223:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103225:	fc                   	cld    
f0103226:	eb 1d                	jmp    f0103245 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103228:	89 f2                	mov    %esi,%edx
f010322a:	09 c2                	or     %eax,%edx
f010322c:	f6 c2 03             	test   $0x3,%dl
f010322f:	75 0f                	jne    f0103240 <memmove+0x5f>
f0103231:	f6 c1 03             	test   $0x3,%cl
f0103234:	75 0a                	jne    f0103240 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103236:	c1 e9 02             	shr    $0x2,%ecx
f0103239:	89 c7                	mov    %eax,%edi
f010323b:	fc                   	cld    
f010323c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010323e:	eb 05                	jmp    f0103245 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103240:	89 c7                	mov    %eax,%edi
f0103242:	fc                   	cld    
f0103243:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103245:	5e                   	pop    %esi
f0103246:	5f                   	pop    %edi
f0103247:	5d                   	pop    %ebp
f0103248:	c3                   	ret    

f0103249 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103249:	55                   	push   %ebp
f010324a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010324c:	ff 75 10             	pushl  0x10(%ebp)
f010324f:	ff 75 0c             	pushl  0xc(%ebp)
f0103252:	ff 75 08             	pushl  0x8(%ebp)
f0103255:	e8 87 ff ff ff       	call   f01031e1 <memmove>
}
f010325a:	c9                   	leave  
f010325b:	c3                   	ret    

f010325c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010325c:	55                   	push   %ebp
f010325d:	89 e5                	mov    %esp,%ebp
f010325f:	56                   	push   %esi
f0103260:	53                   	push   %ebx
f0103261:	8b 45 08             	mov    0x8(%ebp),%eax
f0103264:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103267:	89 c6                	mov    %eax,%esi
f0103269:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010326c:	eb 1a                	jmp    f0103288 <memcmp+0x2c>
		if (*s1 != *s2)
f010326e:	0f b6 08             	movzbl (%eax),%ecx
f0103271:	0f b6 1a             	movzbl (%edx),%ebx
f0103274:	38 d9                	cmp    %bl,%cl
f0103276:	74 0a                	je     f0103282 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103278:	0f b6 c1             	movzbl %cl,%eax
f010327b:	0f b6 db             	movzbl %bl,%ebx
f010327e:	29 d8                	sub    %ebx,%eax
f0103280:	eb 0f                	jmp    f0103291 <memcmp+0x35>
		s1++, s2++;
f0103282:	83 c0 01             	add    $0x1,%eax
f0103285:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103288:	39 f0                	cmp    %esi,%eax
f010328a:	75 e2                	jne    f010326e <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010328c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103291:	5b                   	pop    %ebx
f0103292:	5e                   	pop    %esi
f0103293:	5d                   	pop    %ebp
f0103294:	c3                   	ret    

f0103295 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103295:	55                   	push   %ebp
f0103296:	89 e5                	mov    %esp,%ebp
f0103298:	53                   	push   %ebx
f0103299:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010329c:	89 c1                	mov    %eax,%ecx
f010329e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032a1:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032a5:	eb 0a                	jmp    f01032b1 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032a7:	0f b6 10             	movzbl (%eax),%edx
f01032aa:	39 da                	cmp    %ebx,%edx
f01032ac:	74 07                	je     f01032b5 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032ae:	83 c0 01             	add    $0x1,%eax
f01032b1:	39 c8                	cmp    %ecx,%eax
f01032b3:	72 f2                	jb     f01032a7 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032b5:	5b                   	pop    %ebx
f01032b6:	5d                   	pop    %ebp
f01032b7:	c3                   	ret    

f01032b8 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032b8:	55                   	push   %ebp
f01032b9:	89 e5                	mov    %esp,%ebp
f01032bb:	57                   	push   %edi
f01032bc:	56                   	push   %esi
f01032bd:	53                   	push   %ebx
f01032be:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032c1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032c4:	eb 03                	jmp    f01032c9 <strtol+0x11>
		s++;
f01032c6:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032c9:	0f b6 01             	movzbl (%ecx),%eax
f01032cc:	3c 20                	cmp    $0x20,%al
f01032ce:	74 f6                	je     f01032c6 <strtol+0xe>
f01032d0:	3c 09                	cmp    $0x9,%al
f01032d2:	74 f2                	je     f01032c6 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032d4:	3c 2b                	cmp    $0x2b,%al
f01032d6:	75 0a                	jne    f01032e2 <strtol+0x2a>
		s++;
f01032d8:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01032db:	bf 00 00 00 00       	mov    $0x0,%edi
f01032e0:	eb 11                	jmp    f01032f3 <strtol+0x3b>
f01032e2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01032e7:	3c 2d                	cmp    $0x2d,%al
f01032e9:	75 08                	jne    f01032f3 <strtol+0x3b>
		s++, neg = 1;
f01032eb:	83 c1 01             	add    $0x1,%ecx
f01032ee:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01032f3:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01032f9:	75 15                	jne    f0103310 <strtol+0x58>
f01032fb:	80 39 30             	cmpb   $0x30,(%ecx)
f01032fe:	75 10                	jne    f0103310 <strtol+0x58>
f0103300:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103304:	75 7c                	jne    f0103382 <strtol+0xca>
		s += 2, base = 16;
f0103306:	83 c1 02             	add    $0x2,%ecx
f0103309:	bb 10 00 00 00       	mov    $0x10,%ebx
f010330e:	eb 16                	jmp    f0103326 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103310:	85 db                	test   %ebx,%ebx
f0103312:	75 12                	jne    f0103326 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103314:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103319:	80 39 30             	cmpb   $0x30,(%ecx)
f010331c:	75 08                	jne    f0103326 <strtol+0x6e>
		s++, base = 8;
f010331e:	83 c1 01             	add    $0x1,%ecx
f0103321:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103326:	b8 00 00 00 00       	mov    $0x0,%eax
f010332b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010332e:	0f b6 11             	movzbl (%ecx),%edx
f0103331:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103334:	89 f3                	mov    %esi,%ebx
f0103336:	80 fb 09             	cmp    $0x9,%bl
f0103339:	77 08                	ja     f0103343 <strtol+0x8b>
			dig = *s - '0';
f010333b:	0f be d2             	movsbl %dl,%edx
f010333e:	83 ea 30             	sub    $0x30,%edx
f0103341:	eb 22                	jmp    f0103365 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103343:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103346:	89 f3                	mov    %esi,%ebx
f0103348:	80 fb 19             	cmp    $0x19,%bl
f010334b:	77 08                	ja     f0103355 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010334d:	0f be d2             	movsbl %dl,%edx
f0103350:	83 ea 57             	sub    $0x57,%edx
f0103353:	eb 10                	jmp    f0103365 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103355:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103358:	89 f3                	mov    %esi,%ebx
f010335a:	80 fb 19             	cmp    $0x19,%bl
f010335d:	77 16                	ja     f0103375 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010335f:	0f be d2             	movsbl %dl,%edx
f0103362:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103365:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103368:	7d 0b                	jge    f0103375 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010336a:	83 c1 01             	add    $0x1,%ecx
f010336d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103371:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103373:	eb b9                	jmp    f010332e <strtol+0x76>

	if (endptr)
f0103375:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103379:	74 0d                	je     f0103388 <strtol+0xd0>
		*endptr = (char *) s;
f010337b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010337e:	89 0e                	mov    %ecx,(%esi)
f0103380:	eb 06                	jmp    f0103388 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103382:	85 db                	test   %ebx,%ebx
f0103384:	74 98                	je     f010331e <strtol+0x66>
f0103386:	eb 9e                	jmp    f0103326 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103388:	89 c2                	mov    %eax,%edx
f010338a:	f7 da                	neg    %edx
f010338c:	85 ff                	test   %edi,%edi
f010338e:	0f 45 c2             	cmovne %edx,%eax
}
f0103391:	5b                   	pop    %ebx
f0103392:	5e                   	pop    %esi
f0103393:	5f                   	pop    %edi
f0103394:	5d                   	pop    %ebp
f0103395:	c3                   	ret    
f0103396:	66 90                	xchg   %ax,%ax
f0103398:	66 90                	xchg   %ax,%ax
f010339a:	66 90                	xchg   %ax,%ax
f010339c:	66 90                	xchg   %ax,%ax
f010339e:	66 90                	xchg   %ax,%ax

f01033a0 <__udivdi3>:
f01033a0:	55                   	push   %ebp
f01033a1:	57                   	push   %edi
f01033a2:	56                   	push   %esi
f01033a3:	53                   	push   %ebx
f01033a4:	83 ec 1c             	sub    $0x1c,%esp
f01033a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033b7:	85 f6                	test   %esi,%esi
f01033b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033bd:	89 ca                	mov    %ecx,%edx
f01033bf:	89 f8                	mov    %edi,%eax
f01033c1:	75 3d                	jne    f0103400 <__udivdi3+0x60>
f01033c3:	39 cf                	cmp    %ecx,%edi
f01033c5:	0f 87 c5 00 00 00    	ja     f0103490 <__udivdi3+0xf0>
f01033cb:	85 ff                	test   %edi,%edi
f01033cd:	89 fd                	mov    %edi,%ebp
f01033cf:	75 0b                	jne    f01033dc <__udivdi3+0x3c>
f01033d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01033d6:	31 d2                	xor    %edx,%edx
f01033d8:	f7 f7                	div    %edi
f01033da:	89 c5                	mov    %eax,%ebp
f01033dc:	89 c8                	mov    %ecx,%eax
f01033de:	31 d2                	xor    %edx,%edx
f01033e0:	f7 f5                	div    %ebp
f01033e2:	89 c1                	mov    %eax,%ecx
f01033e4:	89 d8                	mov    %ebx,%eax
f01033e6:	89 cf                	mov    %ecx,%edi
f01033e8:	f7 f5                	div    %ebp
f01033ea:	89 c3                	mov    %eax,%ebx
f01033ec:	89 d8                	mov    %ebx,%eax
f01033ee:	89 fa                	mov    %edi,%edx
f01033f0:	83 c4 1c             	add    $0x1c,%esp
f01033f3:	5b                   	pop    %ebx
f01033f4:	5e                   	pop    %esi
f01033f5:	5f                   	pop    %edi
f01033f6:	5d                   	pop    %ebp
f01033f7:	c3                   	ret    
f01033f8:	90                   	nop
f01033f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103400:	39 ce                	cmp    %ecx,%esi
f0103402:	77 74                	ja     f0103478 <__udivdi3+0xd8>
f0103404:	0f bd fe             	bsr    %esi,%edi
f0103407:	83 f7 1f             	xor    $0x1f,%edi
f010340a:	0f 84 98 00 00 00    	je     f01034a8 <__udivdi3+0x108>
f0103410:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103415:	89 f9                	mov    %edi,%ecx
f0103417:	89 c5                	mov    %eax,%ebp
f0103419:	29 fb                	sub    %edi,%ebx
f010341b:	d3 e6                	shl    %cl,%esi
f010341d:	89 d9                	mov    %ebx,%ecx
f010341f:	d3 ed                	shr    %cl,%ebp
f0103421:	89 f9                	mov    %edi,%ecx
f0103423:	d3 e0                	shl    %cl,%eax
f0103425:	09 ee                	or     %ebp,%esi
f0103427:	89 d9                	mov    %ebx,%ecx
f0103429:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010342d:	89 d5                	mov    %edx,%ebp
f010342f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103433:	d3 ed                	shr    %cl,%ebp
f0103435:	89 f9                	mov    %edi,%ecx
f0103437:	d3 e2                	shl    %cl,%edx
f0103439:	89 d9                	mov    %ebx,%ecx
f010343b:	d3 e8                	shr    %cl,%eax
f010343d:	09 c2                	or     %eax,%edx
f010343f:	89 d0                	mov    %edx,%eax
f0103441:	89 ea                	mov    %ebp,%edx
f0103443:	f7 f6                	div    %esi
f0103445:	89 d5                	mov    %edx,%ebp
f0103447:	89 c3                	mov    %eax,%ebx
f0103449:	f7 64 24 0c          	mull   0xc(%esp)
f010344d:	39 d5                	cmp    %edx,%ebp
f010344f:	72 10                	jb     f0103461 <__udivdi3+0xc1>
f0103451:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103455:	89 f9                	mov    %edi,%ecx
f0103457:	d3 e6                	shl    %cl,%esi
f0103459:	39 c6                	cmp    %eax,%esi
f010345b:	73 07                	jae    f0103464 <__udivdi3+0xc4>
f010345d:	39 d5                	cmp    %edx,%ebp
f010345f:	75 03                	jne    f0103464 <__udivdi3+0xc4>
f0103461:	83 eb 01             	sub    $0x1,%ebx
f0103464:	31 ff                	xor    %edi,%edi
f0103466:	89 d8                	mov    %ebx,%eax
f0103468:	89 fa                	mov    %edi,%edx
f010346a:	83 c4 1c             	add    $0x1c,%esp
f010346d:	5b                   	pop    %ebx
f010346e:	5e                   	pop    %esi
f010346f:	5f                   	pop    %edi
f0103470:	5d                   	pop    %ebp
f0103471:	c3                   	ret    
f0103472:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103478:	31 ff                	xor    %edi,%edi
f010347a:	31 db                	xor    %ebx,%ebx
f010347c:	89 d8                	mov    %ebx,%eax
f010347e:	89 fa                	mov    %edi,%edx
f0103480:	83 c4 1c             	add    $0x1c,%esp
f0103483:	5b                   	pop    %ebx
f0103484:	5e                   	pop    %esi
f0103485:	5f                   	pop    %edi
f0103486:	5d                   	pop    %ebp
f0103487:	c3                   	ret    
f0103488:	90                   	nop
f0103489:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103490:	89 d8                	mov    %ebx,%eax
f0103492:	f7 f7                	div    %edi
f0103494:	31 ff                	xor    %edi,%edi
f0103496:	89 c3                	mov    %eax,%ebx
f0103498:	89 d8                	mov    %ebx,%eax
f010349a:	89 fa                	mov    %edi,%edx
f010349c:	83 c4 1c             	add    $0x1c,%esp
f010349f:	5b                   	pop    %ebx
f01034a0:	5e                   	pop    %esi
f01034a1:	5f                   	pop    %edi
f01034a2:	5d                   	pop    %ebp
f01034a3:	c3                   	ret    
f01034a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034a8:	39 ce                	cmp    %ecx,%esi
f01034aa:	72 0c                	jb     f01034b8 <__udivdi3+0x118>
f01034ac:	31 db                	xor    %ebx,%ebx
f01034ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034b2:	0f 87 34 ff ff ff    	ja     f01033ec <__udivdi3+0x4c>
f01034b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034bd:	e9 2a ff ff ff       	jmp    f01033ec <__udivdi3+0x4c>
f01034c2:	66 90                	xchg   %ax,%ax
f01034c4:	66 90                	xchg   %ax,%ax
f01034c6:	66 90                	xchg   %ax,%ax
f01034c8:	66 90                	xchg   %ax,%ax
f01034ca:	66 90                	xchg   %ax,%ax
f01034cc:	66 90                	xchg   %ax,%ax
f01034ce:	66 90                	xchg   %ax,%ax

f01034d0 <__umoddi3>:
f01034d0:	55                   	push   %ebp
f01034d1:	57                   	push   %edi
f01034d2:	56                   	push   %esi
f01034d3:	53                   	push   %ebx
f01034d4:	83 ec 1c             	sub    $0x1c,%esp
f01034d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01034db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01034df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01034e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034e7:	85 d2                	test   %edx,%edx
f01034e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01034ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034f1:	89 f3                	mov    %esi,%ebx
f01034f3:	89 3c 24             	mov    %edi,(%esp)
f01034f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034fa:	75 1c                	jne    f0103518 <__umoddi3+0x48>
f01034fc:	39 f7                	cmp    %esi,%edi
f01034fe:	76 50                	jbe    f0103550 <__umoddi3+0x80>
f0103500:	89 c8                	mov    %ecx,%eax
f0103502:	89 f2                	mov    %esi,%edx
f0103504:	f7 f7                	div    %edi
f0103506:	89 d0                	mov    %edx,%eax
f0103508:	31 d2                	xor    %edx,%edx
f010350a:	83 c4 1c             	add    $0x1c,%esp
f010350d:	5b                   	pop    %ebx
f010350e:	5e                   	pop    %esi
f010350f:	5f                   	pop    %edi
f0103510:	5d                   	pop    %ebp
f0103511:	c3                   	ret    
f0103512:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103518:	39 f2                	cmp    %esi,%edx
f010351a:	89 d0                	mov    %edx,%eax
f010351c:	77 52                	ja     f0103570 <__umoddi3+0xa0>
f010351e:	0f bd ea             	bsr    %edx,%ebp
f0103521:	83 f5 1f             	xor    $0x1f,%ebp
f0103524:	75 5a                	jne    f0103580 <__umoddi3+0xb0>
f0103526:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010352a:	0f 82 e0 00 00 00    	jb     f0103610 <__umoddi3+0x140>
f0103530:	39 0c 24             	cmp    %ecx,(%esp)
f0103533:	0f 86 d7 00 00 00    	jbe    f0103610 <__umoddi3+0x140>
f0103539:	8b 44 24 08          	mov    0x8(%esp),%eax
f010353d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103541:	83 c4 1c             	add    $0x1c,%esp
f0103544:	5b                   	pop    %ebx
f0103545:	5e                   	pop    %esi
f0103546:	5f                   	pop    %edi
f0103547:	5d                   	pop    %ebp
f0103548:	c3                   	ret    
f0103549:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103550:	85 ff                	test   %edi,%edi
f0103552:	89 fd                	mov    %edi,%ebp
f0103554:	75 0b                	jne    f0103561 <__umoddi3+0x91>
f0103556:	b8 01 00 00 00       	mov    $0x1,%eax
f010355b:	31 d2                	xor    %edx,%edx
f010355d:	f7 f7                	div    %edi
f010355f:	89 c5                	mov    %eax,%ebp
f0103561:	89 f0                	mov    %esi,%eax
f0103563:	31 d2                	xor    %edx,%edx
f0103565:	f7 f5                	div    %ebp
f0103567:	89 c8                	mov    %ecx,%eax
f0103569:	f7 f5                	div    %ebp
f010356b:	89 d0                	mov    %edx,%eax
f010356d:	eb 99                	jmp    f0103508 <__umoddi3+0x38>
f010356f:	90                   	nop
f0103570:	89 c8                	mov    %ecx,%eax
f0103572:	89 f2                	mov    %esi,%edx
f0103574:	83 c4 1c             	add    $0x1c,%esp
f0103577:	5b                   	pop    %ebx
f0103578:	5e                   	pop    %esi
f0103579:	5f                   	pop    %edi
f010357a:	5d                   	pop    %ebp
f010357b:	c3                   	ret    
f010357c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103580:	8b 34 24             	mov    (%esp),%esi
f0103583:	bf 20 00 00 00       	mov    $0x20,%edi
f0103588:	89 e9                	mov    %ebp,%ecx
f010358a:	29 ef                	sub    %ebp,%edi
f010358c:	d3 e0                	shl    %cl,%eax
f010358e:	89 f9                	mov    %edi,%ecx
f0103590:	89 f2                	mov    %esi,%edx
f0103592:	d3 ea                	shr    %cl,%edx
f0103594:	89 e9                	mov    %ebp,%ecx
f0103596:	09 c2                	or     %eax,%edx
f0103598:	89 d8                	mov    %ebx,%eax
f010359a:	89 14 24             	mov    %edx,(%esp)
f010359d:	89 f2                	mov    %esi,%edx
f010359f:	d3 e2                	shl    %cl,%edx
f01035a1:	89 f9                	mov    %edi,%ecx
f01035a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035ab:	d3 e8                	shr    %cl,%eax
f01035ad:	89 e9                	mov    %ebp,%ecx
f01035af:	89 c6                	mov    %eax,%esi
f01035b1:	d3 e3                	shl    %cl,%ebx
f01035b3:	89 f9                	mov    %edi,%ecx
f01035b5:	89 d0                	mov    %edx,%eax
f01035b7:	d3 e8                	shr    %cl,%eax
f01035b9:	89 e9                	mov    %ebp,%ecx
f01035bb:	09 d8                	or     %ebx,%eax
f01035bd:	89 d3                	mov    %edx,%ebx
f01035bf:	89 f2                	mov    %esi,%edx
f01035c1:	f7 34 24             	divl   (%esp)
f01035c4:	89 d6                	mov    %edx,%esi
f01035c6:	d3 e3                	shl    %cl,%ebx
f01035c8:	f7 64 24 04          	mull   0x4(%esp)
f01035cc:	39 d6                	cmp    %edx,%esi
f01035ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035d2:	89 d1                	mov    %edx,%ecx
f01035d4:	89 c3                	mov    %eax,%ebx
f01035d6:	72 08                	jb     f01035e0 <__umoddi3+0x110>
f01035d8:	75 11                	jne    f01035eb <__umoddi3+0x11b>
f01035da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01035de:	73 0b                	jae    f01035eb <__umoddi3+0x11b>
f01035e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01035e4:	1b 14 24             	sbb    (%esp),%edx
f01035e7:	89 d1                	mov    %edx,%ecx
f01035e9:	89 c3                	mov    %eax,%ebx
f01035eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01035ef:	29 da                	sub    %ebx,%edx
f01035f1:	19 ce                	sbb    %ecx,%esi
f01035f3:	89 f9                	mov    %edi,%ecx
f01035f5:	89 f0                	mov    %esi,%eax
f01035f7:	d3 e0                	shl    %cl,%eax
f01035f9:	89 e9                	mov    %ebp,%ecx
f01035fb:	d3 ea                	shr    %cl,%edx
f01035fd:	89 e9                	mov    %ebp,%ecx
f01035ff:	d3 ee                	shr    %cl,%esi
f0103601:	09 d0                	or     %edx,%eax
f0103603:	89 f2                	mov    %esi,%edx
f0103605:	83 c4 1c             	add    $0x1c,%esp
f0103608:	5b                   	pop    %ebx
f0103609:	5e                   	pop    %esi
f010360a:	5f                   	pop    %edi
f010360b:	5d                   	pop    %ebp
f010360c:	c3                   	ret    
f010360d:	8d 76 00             	lea    0x0(%esi),%esi
f0103610:	29 f9                	sub    %edi,%ecx
f0103612:	19 d6                	sbb    %edx,%esi
f0103614:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103618:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010361c:	e9 18 ff ff ff       	jmp    f0103539 <__umoddi3+0x69>
