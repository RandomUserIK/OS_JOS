
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
f0100058:	e8 5a 31 00 00       	call   f01031b7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 36 10 f0       	push   $0xf0103660
f010006f:	e8 8a 26 00 00       	call   f01026fe <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 5c 10 00 00       	call   f01010d5 <mem_init>
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
f01000b0:	68 7b 36 10 f0       	push   $0xf010367b
f01000b5:	e8 44 26 00 00       	call   f01026fe <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 14 26 00 00       	call   f01026d8 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 a1 39 10 f0 	movl   $0xf01039a1,(%esp)
f01000cb:	e8 2e 26 00 00       	call   f01026fe <cprintf>
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
f01000f2:	68 93 36 10 f0       	push   $0xf0103693
f01000f7:	e8 02 26 00 00       	call   f01026fe <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 d0 25 00 00       	call   f01026d8 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 a1 39 10 f0 	movl   $0xf01039a1,(%esp)
f010010f:	e8 ea 25 00 00       	call   f01026fe <cprintf>
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
f01001ce:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
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
f010020a:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a 00 37 10 f0 	movzbl -0xfefc900(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d e0 36 10 f0 	mov    -0xfefc920(,%ecx,4),%ecx
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
f0100268:	68 ad 36 10 f0       	push   $0xf01036ad
f010026d:	e8 8c 24 00 00       	call   f01026fe <cprintf>
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
f010041c:	e8 e3 2d 00 00       	call   f0103204 <memmove>
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
f01005eb:	68 b9 36 10 f0       	push   $0xf01036b9
f01005f0:	e8 09 21 00 00       	call   f01026fe <cprintf>
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
f0100631:	68 00 39 10 f0       	push   $0xf0103900
f0100636:	68 1e 39 10 f0       	push   $0xf010391e
f010063b:	68 23 39 10 f0       	push   $0xf0103923
f0100640:	e8 b9 20 00 00       	call   f01026fe <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 e0 39 10 f0       	push   $0xf01039e0
f010064d:	68 2c 39 10 f0       	push   $0xf010392c
f0100652:	68 23 39 10 f0       	push   $0xf0103923
f0100657:	e8 a2 20 00 00       	call   f01026fe <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 08 3a 10 f0       	push   $0xf0103a08
f0100664:	68 35 39 10 f0       	push   $0xf0103935
f0100669:	68 23 39 10 f0       	push   $0xf0103923
f010066e:	e8 8b 20 00 00       	call   f01026fe <cprintf>
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
f0100680:	68 3f 39 10 f0       	push   $0xf010393f
f0100685:	e8 74 20 00 00       	call   f01026fe <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 34 3a 10 f0       	push   $0xf0103a34
f0100697:	e8 62 20 00 00       	call   f01026fe <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 5c 3a 10 f0       	push   $0xf0103a5c
f01006ae:	e8 4b 20 00 00       	call   f01026fe <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 41 36 10 00       	push   $0x103641
f01006bb:	68 41 36 10 f0       	push   $0xf0103641
f01006c0:	68 80 3a 10 f0       	push   $0xf0103a80
f01006c5:	e8 34 20 00 00       	call   f01026fe <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 a4 3a 10 f0       	push   $0xf0103aa4
f01006dc:	e8 1d 20 00 00       	call   f01026fe <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 50 79 11 00       	push   $0x117950
f01006e9:	68 50 79 11 f0       	push   $0xf0117950
f01006ee:	68 c8 3a 10 f0       	push   $0xf0103ac8
f01006f3:	e8 06 20 00 00       	call   f01026fe <cprintf>
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
f0100719:	68 ec 3a 10 f0       	push   $0xf0103aec
f010071e:	e8 db 1f 00 00       	call   f01026fe <cprintf>
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
f0100735:	68 58 39 10 f0       	push   $0xf0103958
f010073a:	e8 bf 1f 00 00       	call   f01026fe <cprintf>
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
f0100752:	68 6b 39 10 f0       	push   $0xf010396b
f0100757:	e8 a2 1f 00 00       	call   f01026fe <cprintf>
		cprintf("%08x ", *(ebp+2));
f010075c:	83 c4 08             	add    $0x8,%esp
f010075f:	ff 73 08             	pushl  0x8(%ebx)
f0100762:	68 85 39 10 f0       	push   $0xf0103985
f0100767:	e8 92 1f 00 00       	call   f01026fe <cprintf>
		cprintf("%08x ", *(ebp+3));
f010076c:	83 c4 08             	add    $0x8,%esp
f010076f:	ff 73 0c             	pushl  0xc(%ebx)
f0100772:	68 85 39 10 f0       	push   $0xf0103985
f0100777:	e8 82 1f 00 00       	call   f01026fe <cprintf>
		cprintf("%08x ", *(ebp+4));
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff 73 10             	pushl  0x10(%ebx)
f0100782:	68 85 39 10 f0       	push   $0xf0103985
f0100787:	e8 72 1f 00 00       	call   f01026fe <cprintf>
		cprintf("%08x ", *(ebp+5));
f010078c:	83 c4 08             	add    $0x8,%esp
f010078f:	ff 73 14             	pushl  0x14(%ebx)
f0100792:	68 85 39 10 f0       	push   $0xf0103985
f0100797:	e8 62 1f 00 00       	call   f01026fe <cprintf>
		cprintf("%08x", *(ebp+6));
f010079c:	83 c4 08             	add    $0x8,%esp
f010079f:	ff 73 18             	pushl  0x18(%ebx)
f01007a2:	68 8b 39 10 f0       	push   $0xf010398b
f01007a7:	e8 52 1f 00 00       	call   f01026fe <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01007ac:	83 c4 08             	add    $0x8,%esp
f01007af:	57                   	push   %edi
f01007b0:	56                   	push   %esi
f01007b1:	e8 52 20 00 00       	call   f0102808 <debuginfo_eip>
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
f01007d0:	68 90 39 10 f0       	push   $0xf0103990
f01007d5:	e8 24 1f 00 00       	call   f01026fe <cprintf>
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
f01007fd:	68 18 3b 10 f0       	push   $0xf0103b18
f0100802:	e8 f7 1e 00 00       	call   f01026fe <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100807:	c7 04 24 3c 3b 10 f0 	movl   $0xf0103b3c,(%esp)
f010080e:	e8 eb 1e 00 00       	call   f01026fe <cprintf>
f0100813:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100816:	83 ec 0c             	sub    $0xc,%esp
f0100819:	68 a3 39 10 f0       	push   $0xf01039a3
f010081e:	e8 3d 27 00 00       	call   f0102f60 <readline>
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
f0100852:	68 a7 39 10 f0       	push   $0xf01039a7
f0100857:	e8 1e 29 00 00       	call   f010317a <strchr>
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
f0100872:	68 ac 39 10 f0       	push   $0xf01039ac
f0100877:	e8 82 1e 00 00       	call   f01026fe <cprintf>
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
f010089b:	68 a7 39 10 f0       	push   $0xf01039a7
f01008a0:	e8 d5 28 00 00       	call   f010317a <strchr>
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
f01008c9:	ff 34 85 80 3b 10 f0 	pushl  -0xfefc480(,%eax,4)
f01008d0:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d3:	e8 44 28 00 00       	call   f010311c <strcmp>
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
f01008ed:	ff 14 85 88 3b 10 f0 	call   *-0xfefc478(,%eax,4)


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
f010090e:	68 c9 39 10 f0       	push   $0xf01039c9
f0100913:	e8 e6 1d 00 00       	call   f01026fe <cprintf>
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
f0100933:	e8 5f 1d 00 00       	call   f0102697 <mc146818_read>
f0100938:	89 c6                	mov    %eax,%esi
f010093a:	83 c3 01             	add    $0x1,%ebx
f010093d:	89 1c 24             	mov    %ebx,(%esp)
f0100940:	e8 52 1d 00 00       	call   f0102697 <mc146818_read>
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
f0100976:	68 a4 3b 10 f0       	push   $0xf0103ba4
f010097b:	68 04 03 00 00       	push   $0x304
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
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009b5:	55                   	push   %ebp
f01009b6:	89 e5                	mov    %esp,%ebp
f01009b8:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009bb:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f01009c2:	75 11                	jne    f01009d5 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009c4:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f01009c9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009cf:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n < 0) panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) return nextfree;
f01009d5:	85 c0                	test   %eax,%eax
f01009d7:	75 07                	jne    f01009e0 <boot_alloc+0x2b>
f01009d9:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f01009de:	eb 54                	jmp    f0100a34 <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f01009e0:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx

		char* new = ROUNDUP(nextfree+n, PGSIZE);
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
f01009fa:	68 c8 3b 10 f0       	push   $0xf0103bc8
f01009ff:	6a 73                	push   $0x73
f0100a01:	68 48 43 10 f0       	push   $0xf0104348
f0100a06:	e8 80 f6 ff ff       	call   f010008b <_panic>

		if(PADDR(new) > 1024*1024*4) panic("boot_alloc: not enough memory!\n");
f0100a0b:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100a11:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100a17:	76 14                	jbe    f0100a2d <boot_alloc+0x78>
f0100a19:	83 ec 04             	sub    $0x4,%esp
f0100a1c:	68 ec 3b 10 f0       	push   $0xf0103bec
f0100a21:	6a 73                	push   $0x73
f0100a23:	68 48 43 10 f0       	push   $0xf0104348
f0100a28:	e8 5e f6 ff ff       	call   f010008b <_panic>

		else
		{
			nextfree = new;
f0100a2d:	a3 38 75 11 f0       	mov    %eax,0xf0117538
		}
	}

	return result;
f0100a32:	89 d0                	mov    %edx,%eax
}
f0100a34:	c9                   	leave  
f0100a35:	c3                   	ret    

f0100a36 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a36:	55                   	push   %ebp
f0100a37:	89 e5                	mov    %esp,%ebp
f0100a39:	57                   	push   %edi
f0100a3a:	56                   	push   %esi
f0100a3b:	53                   	push   %ebx
f0100a3c:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a3f:	84 c0                	test   %al,%al
f0100a41:	0f 85 81 02 00 00    	jne    f0100cc8 <check_page_free_list+0x292>
f0100a47:	e9 8e 02 00 00       	jmp    f0100cda <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a4c:	83 ec 04             	sub    $0x4,%esp
f0100a4f:	68 0c 3c 10 f0       	push   $0xf0103c0c
f0100a54:	68 45 02 00 00       	push   $0x245
f0100a59:	68 48 43 10 f0       	push   $0xf0104348
f0100a5e:	e8 28 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a63:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a66:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a69:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a6c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a6f:	89 c2                	mov    %eax,%edx
f0100a71:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0100a77:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a7d:	0f 95 c2             	setne  %dl
f0100a80:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a83:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a87:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a89:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a8d:	8b 00                	mov    (%eax),%eax
f0100a8f:	85 c0                	test   %eax,%eax
f0100a91:	75 dc                	jne    f0100a6f <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a96:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a9c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a9f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aa2:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aa4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100aa7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aac:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ab1:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100ab7:	eb 53                	jmp    f0100b0c <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ab9:	89 d8                	mov    %ebx,%eax
f0100abb:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100ac1:	c1 f8 03             	sar    $0x3,%eax
f0100ac4:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ac7:	89 c2                	mov    %eax,%edx
f0100ac9:	c1 ea 16             	shr    $0x16,%edx
f0100acc:	39 f2                	cmp    %esi,%edx
f0100ace:	73 3a                	jae    f0100b0a <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ad0:	89 c2                	mov    %eax,%edx
f0100ad2:	c1 ea 0c             	shr    $0xc,%edx
f0100ad5:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100adb:	72 12                	jb     f0100aef <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100add:	50                   	push   %eax
f0100ade:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100ae3:	6a 52                	push   $0x52
f0100ae5:	68 54 43 10 f0       	push   $0xf0104354
f0100aea:	e8 9c f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aef:	83 ec 04             	sub    $0x4,%esp
f0100af2:	68 80 00 00 00       	push   $0x80
f0100af7:	68 97 00 00 00       	push   $0x97
f0100afc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b01:	50                   	push   %eax
f0100b02:	e8 b0 26 00 00       	call   f01031b7 <memset>
f0100b07:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0a:	8b 1b                	mov    (%ebx),%ebx
f0100b0c:	85 db                	test   %ebx,%ebx
f0100b0e:	75 a9                	jne    f0100ab9 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b15:	e8 9b fe ff ff       	call   f01009b5 <boot_alloc>
f0100b1a:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b1d:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b23:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
		assert(pp < pages + npages);
f0100b29:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100b2e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b31:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b34:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b37:	be 00 00 00 00       	mov    $0x0,%esi
f0100b3c:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b3f:	e9 30 01 00 00       	jmp    f0100c74 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b44:	39 ca                	cmp    %ecx,%edx
f0100b46:	73 19                	jae    f0100b61 <check_page_free_list+0x12b>
f0100b48:	68 62 43 10 f0       	push   $0xf0104362
f0100b4d:	68 6e 43 10 f0       	push   $0xf010436e
f0100b52:	68 5f 02 00 00       	push   $0x25f
f0100b57:	68 48 43 10 f0       	push   $0xf0104348
f0100b5c:	e8 2a f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b61:	39 fa                	cmp    %edi,%edx
f0100b63:	72 19                	jb     f0100b7e <check_page_free_list+0x148>
f0100b65:	68 83 43 10 f0       	push   $0xf0104383
f0100b6a:	68 6e 43 10 f0       	push   $0xf010436e
f0100b6f:	68 60 02 00 00       	push   $0x260
f0100b74:	68 48 43 10 f0       	push   $0xf0104348
f0100b79:	e8 0d f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b7e:	89 d0                	mov    %edx,%eax
f0100b80:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b83:	a8 07                	test   $0x7,%al
f0100b85:	74 19                	je     f0100ba0 <check_page_free_list+0x16a>
f0100b87:	68 30 3c 10 f0       	push   $0xf0103c30
f0100b8c:	68 6e 43 10 f0       	push   $0xf010436e
f0100b91:	68 61 02 00 00       	push   $0x261
f0100b96:	68 48 43 10 f0       	push   $0xf0104348
f0100b9b:	e8 eb f4 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ba0:	c1 f8 03             	sar    $0x3,%eax
f0100ba3:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ba6:	85 c0                	test   %eax,%eax
f0100ba8:	75 19                	jne    f0100bc3 <check_page_free_list+0x18d>
f0100baa:	68 97 43 10 f0       	push   $0xf0104397
f0100baf:	68 6e 43 10 f0       	push   $0xf010436e
f0100bb4:	68 64 02 00 00       	push   $0x264
f0100bb9:	68 48 43 10 f0       	push   $0xf0104348
f0100bbe:	e8 c8 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bc3:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bc8:	75 19                	jne    f0100be3 <check_page_free_list+0x1ad>
f0100bca:	68 a8 43 10 f0       	push   $0xf01043a8
f0100bcf:	68 6e 43 10 f0       	push   $0xf010436e
f0100bd4:	68 65 02 00 00       	push   $0x265
f0100bd9:	68 48 43 10 f0       	push   $0xf0104348
f0100bde:	e8 a8 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100be3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100be8:	75 19                	jne    f0100c03 <check_page_free_list+0x1cd>
f0100bea:	68 64 3c 10 f0       	push   $0xf0103c64
f0100bef:	68 6e 43 10 f0       	push   $0xf010436e
f0100bf4:	68 66 02 00 00       	push   $0x266
f0100bf9:	68 48 43 10 f0       	push   $0xf0104348
f0100bfe:	e8 88 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c03:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c08:	75 19                	jne    f0100c23 <check_page_free_list+0x1ed>
f0100c0a:	68 c1 43 10 f0       	push   $0xf01043c1
f0100c0f:	68 6e 43 10 f0       	push   $0xf010436e
f0100c14:	68 67 02 00 00       	push   $0x267
f0100c19:	68 48 43 10 f0       	push   $0xf0104348
f0100c1e:	e8 68 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c23:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c28:	76 3f                	jbe    f0100c69 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c2a:	89 c3                	mov    %eax,%ebx
f0100c2c:	c1 eb 0c             	shr    $0xc,%ebx
f0100c2f:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c32:	77 12                	ja     f0100c46 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c34:	50                   	push   %eax
f0100c35:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100c3a:	6a 52                	push   $0x52
f0100c3c:	68 54 43 10 f0       	push   $0xf0104354
f0100c41:	e8 45 f4 ff ff       	call   f010008b <_panic>
f0100c46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c4b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c4e:	76 1e                	jbe    f0100c6e <check_page_free_list+0x238>
f0100c50:	68 88 3c 10 f0       	push   $0xf0103c88
f0100c55:	68 6e 43 10 f0       	push   $0xf010436e
f0100c5a:	68 68 02 00 00       	push   $0x268
f0100c5f:	68 48 43 10 f0       	push   $0xf0104348
f0100c64:	e8 22 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c69:	83 c6 01             	add    $0x1,%esi
f0100c6c:	eb 04                	jmp    f0100c72 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c6e:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c72:	8b 12                	mov    (%edx),%edx
f0100c74:	85 d2                	test   %edx,%edx
f0100c76:	0f 85 c8 fe ff ff    	jne    f0100b44 <check_page_free_list+0x10e>
f0100c7c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c7f:	85 f6                	test   %esi,%esi
f0100c81:	7f 19                	jg     f0100c9c <check_page_free_list+0x266>
f0100c83:	68 db 43 10 f0       	push   $0xf01043db
f0100c88:	68 6e 43 10 f0       	push   $0xf010436e
f0100c8d:	68 70 02 00 00       	push   $0x270
f0100c92:	68 48 43 10 f0       	push   $0xf0104348
f0100c97:	e8 ef f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c9c:	85 db                	test   %ebx,%ebx
f0100c9e:	7f 19                	jg     f0100cb9 <check_page_free_list+0x283>
f0100ca0:	68 ed 43 10 f0       	push   $0xf01043ed
f0100ca5:	68 6e 43 10 f0       	push   $0xf010436e
f0100caa:	68 71 02 00 00       	push   $0x271
f0100caf:	68 48 43 10 f0       	push   $0xf0104348
f0100cb4:	e8 d2 f3 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100cb9:	83 ec 0c             	sub    $0xc,%esp
f0100cbc:	68 d0 3c 10 f0       	push   $0xf0103cd0
f0100cc1:	e8 38 1a 00 00       	call   f01026fe <cprintf>
}
f0100cc6:	eb 29                	jmp    f0100cf1 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cc8:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100ccd:	85 c0                	test   %eax,%eax
f0100ccf:	0f 85 8e fd ff ff    	jne    f0100a63 <check_page_free_list+0x2d>
f0100cd5:	e9 72 fd ff ff       	jmp    f0100a4c <check_page_free_list+0x16>
f0100cda:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100ce1:	0f 84 65 fd ff ff    	je     f0100a4c <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ce7:	be 00 04 00 00       	mov    $0x400,%esi
f0100cec:	e9 c0 fd ff ff       	jmp    f0100ab1 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cf1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cf4:	5b                   	pop    %ebx
f0100cf5:	5e                   	pop    %esi
f0100cf6:	5f                   	pop    %edi
f0100cf7:	5d                   	pop    %ebp
f0100cf8:	c3                   	ret    

f0100cf9 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cf9:	55                   	push   %ebp
f0100cfa:	89 e5                	mov    %esp,%ebp
f0100cfc:	57                   	push   %edi
f0100cfd:	56                   	push   %esi
f0100cfe:	53                   	push   %ebx
f0100cff:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
f0100d02:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100d07:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages; i++) 
f0100d0d:	bb 00 10 00 00       	mov    $0x1000,%ebx
f0100d12:	be 08 00 00 00       	mov    $0x8,%esi
f0100d17:	bf 01 00 00 00       	mov    $0x1,%edi
f0100d1c:	e9 8f 00 00 00       	jmp    f0100db0 <page_init+0xb7>
	{
		if((i*PGSIZE  >= IOPHYSMEM) && (i*PGSIZE < EXTPHYSMEM))
f0100d21:	8d 83 00 00 f6 ff    	lea    -0xa0000(%ebx),%eax
f0100d27:	3d ff ff 05 00       	cmp    $0x5ffff,%eax
f0100d2c:	77 0e                	ja     f0100d3c <page_init+0x43>
		{
			pages[i].pp_ref = 1;
f0100d2e:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100d33:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;	
f0100d3a:	eb 68                	jmp    f0100da4 <page_init+0xab>
		}

		if((i*PGSIZE >= EXTPHYSMEM) && (i*PGSIZE < PADDR(boot_alloc(0))))
f0100d3c:	81 fb ff ff 0f 00    	cmp    $0xfffff,%ebx
f0100d42:	76 3d                	jbe    f0100d81 <page_init+0x88>
f0100d44:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d49:	e8 67 fc ff ff       	call   f01009b5 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d4e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d53:	77 15                	ja     f0100d6a <page_init+0x71>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d55:	50                   	push   %eax
f0100d56:	68 c8 3b 10 f0       	push   $0xf0103bc8
f0100d5b:	68 1c 01 00 00       	push   $0x11c
f0100d60:	68 48 43 10 f0       	push   $0xf0104348
f0100d65:	e8 21 f3 ff ff       	call   f010008b <_panic>
f0100d6a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d6f:	39 d8                	cmp    %ebx,%eax
f0100d71:	76 0e                	jbe    f0100d81 <page_init+0x88>
		{
			pages[i].pp_ref = 1;
f0100d73:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100d78:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100d7f:	eb 23                	jmp    f0100da4 <page_init+0xab>
		}
			
		pages[i].pp_ref = 0;  
f0100d81:	89 f0                	mov    %esi,%eax
f0100d83:	03 05 4c 79 11 f0    	add    0xf011794c,%eax
f0100d89:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d8f:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d95:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100d97:	89 f0                	mov    %esi,%eax
f0100d99:	03 05 4c 79 11 f0    	add    0xf011794c,%eax
f0100d9f:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages; i++) 
f0100da4:	83 c7 01             	add    $0x1,%edi
f0100da7:	83 c6 08             	add    $0x8,%esi
f0100daa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100db0:	3b 3d 44 79 11 f0    	cmp    0xf0117944,%edi
f0100db6:	0f 82 65 ff ff ff    	jb     f0100d21 <page_init+0x28>
			
		pages[i].pp_ref = 0;  
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100dbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dbf:	5b                   	pop    %ebx
f0100dc0:	5e                   	pop    %esi
f0100dc1:	5f                   	pop    %edi
f0100dc2:	5d                   	pop    %ebp
f0100dc3:	c3                   	ret    

f0100dc4 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dc4:	55                   	push   %ebp
f0100dc5:	89 e5                	mov    %esp,%ebp
f0100dc7:	53                   	push   %ebx
f0100dc8:	83 ec 04             	sub    $0x4,%esp
	if(page_free_list == NULL) return NULL;
f0100dcb:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100dd1:	85 db                	test   %ebx,%ebx
f0100dd3:	74 58                	je     f0100e2d <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100dd5:	8b 03                	mov    (%ebx),%eax
f0100dd7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	page->pp_link = NULL;
f0100ddc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100de2:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100de6:	74 45                	je     f0100e2d <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100de8:	89 d8                	mov    %ebx,%eax
f0100dea:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100df0:	c1 f8 03             	sar    $0x3,%eax
f0100df3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100df6:	89 c2                	mov    %eax,%edx
f0100df8:	c1 ea 0c             	shr    $0xc,%edx
f0100dfb:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100e01:	72 12                	jb     f0100e15 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e03:	50                   	push   %eax
f0100e04:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100e09:	6a 52                	push   $0x52
f0100e0b:	68 54 43 10 f0       	push   $0xf0104354
f0100e10:	e8 76 f2 ff ff       	call   f010008b <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0100e15:	83 ec 04             	sub    $0x4,%esp
f0100e18:	68 00 10 00 00       	push   $0x1000
f0100e1d:	6a 00                	push   $0x0
f0100e1f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e24:	50                   	push   %eax
f0100e25:	e8 8d 23 00 00       	call   f01031b7 <memset>
f0100e2a:	83 c4 10             	add    $0x10,%esp
	}

	return page;
}
f0100e2d:	89 d8                	mov    %ebx,%eax
f0100e2f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e32:	c9                   	leave  
f0100e33:	c3                   	ret    

f0100e34 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e34:	55                   	push   %ebp
f0100e35:	89 e5                	mov    %esp,%ebp
f0100e37:	83 ec 08             	sub    $0x8,%esp
f0100e3a:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if((pp->pp_ref > 0) || (pp->pp_link != NULL)) panic("page_free: cannot free the page which is still in use!\n");
f0100e3d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e42:	75 05                	jne    f0100e49 <page_free+0x15>
f0100e44:	83 38 00             	cmpl   $0x0,(%eax)
f0100e47:	74 17                	je     f0100e60 <page_free+0x2c>
f0100e49:	83 ec 04             	sub    $0x4,%esp
f0100e4c:	68 f4 3c 10 f0       	push   $0xf0103cf4
f0100e51:	68 53 01 00 00       	push   $0x153
f0100e56:	68 48 43 10 f0       	push   $0xf0104348
f0100e5b:	e8 2b f2 ff ff       	call   f010008b <_panic>
	
	pp->pp_link  = page_free_list;
f0100e60:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e66:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;
f0100e68:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	
}
f0100e6d:	c9                   	leave  
f0100e6e:	c3                   	ret    

f0100e6f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	83 ec 08             	sub    $0x8,%esp
f0100e75:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e78:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e7c:	83 e8 01             	sub    $0x1,%eax
f0100e7f:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e83:	66 85 c0             	test   %ax,%ax
f0100e86:	75 0c                	jne    f0100e94 <page_decref+0x25>
		page_free(pp);
f0100e88:	83 ec 0c             	sub    $0xc,%esp
f0100e8b:	52                   	push   %edx
f0100e8c:	e8 a3 ff ff ff       	call   f0100e34 <page_free>
f0100e91:	83 c4 10             	add    $0x10,%esp
}
f0100e94:	c9                   	leave  
f0100e95:	c3                   	ret    

f0100e96 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e96:	55                   	push   %ebp
f0100e97:	89 e5                	mov    %esp,%ebp
f0100e99:	56                   	push   %esi
f0100e9a:	53                   	push   %ebx
f0100e9b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	size_t dirIndex = PDX(va);
	size_t tableIndex = PTX(va);
f0100e9e:	89 de                	mov    %ebx,%esi
f0100ea0:	c1 ee 0c             	shr    $0xc,%esi
f0100ea3:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];
f0100ea9:	c1 eb 16             	shr    $0x16,%ebx
f0100eac:	c1 e3 02             	shl    $0x2,%ebx
f0100eaf:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pdir_entry & PTE_P))
f0100eb2:	8b 03                	mov    (%ebx),%eax
f0100eb4:	a8 01                	test   $0x1,%al
f0100eb6:	75 6c                	jne    f0100f24 <pgdir_walk+0x8e>
	{
		if(create == false) return NULL;
f0100eb8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ebc:	0f 84 93 00 00 00    	je     f0100f55 <pgdir_walk+0xbf>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100ec2:	83 ec 0c             	sub    $0xc,%esp
f0100ec5:	6a 01                	push   $0x1
f0100ec7:	e8 f8 fe ff ff       	call   f0100dc4 <page_alloc>

		if(page == NULL) return NULL;
f0100ecc:	83 c4 10             	add    $0x10,%esp
f0100ecf:	85 c0                	test   %eax,%eax
f0100ed1:	0f 84 85 00 00 00    	je     f0100f5c <pgdir_walk+0xc6>

		page->pp_ref++;
f0100ed7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

		*pdir_entry = page2pa(page) | PTE_P | PTE_W | PTE_U;
f0100edc:	89 c2                	mov    %eax,%edx
f0100ede:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0100ee4:	c1 fa 03             	sar    $0x3,%edx
f0100ee7:	c1 e2 0c             	shl    $0xc,%edx
f0100eea:	83 ca 07             	or     $0x7,%edx
f0100eed:	89 13                	mov    %edx,(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eef:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100ef5:	c1 f8 03             	sar    $0x3,%eax
f0100ef8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100efb:	89 c2                	mov    %eax,%edx
f0100efd:	c1 ea 0c             	shr    $0xc,%edx
f0100f00:	39 15 44 79 11 f0    	cmp    %edx,0xf0117944
f0100f06:	77 15                	ja     f0100f1d <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f08:	50                   	push   %eax
f0100f09:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100f0e:	68 93 01 00 00       	push   $0x193
f0100f13:	68 48 43 10 f0       	push   $0xf0104348
f0100f18:	e8 6e f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100f1d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f22:	eb 2c                	jmp    f0100f50 <pgdir_walk+0xba>
		
		ptable_entry = (pte_t*) KADDR(page2pa(page));
	}
	else
	{
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
f0100f24:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f29:	89 c2                	mov    %eax,%edx
f0100f2b:	c1 ea 0c             	shr    $0xc,%edx
f0100f2e:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100f34:	72 15                	jb     f0100f4b <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f36:	50                   	push   %eax
f0100f37:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100f3c:	68 97 01 00 00       	push   $0x197
f0100f41:	68 48 43 10 f0       	push   $0xf0104348
f0100f46:	e8 40 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100f4b:	2d 00 00 00 10       	sub    $0x10000000,%eax
	}
	
	return ptable_entry + tableIndex;
f0100f50:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0100f53:	eb 0c                	jmp    f0100f61 <pgdir_walk+0xcb>
	pte_t *ptable_entry = NULL;
	pde_t *pdir_entry = &pgdir[dirIndex];

	if(!(*pdir_entry & PTE_P))
	{
		if(create == false) return NULL;
f0100f55:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f5a:	eb 05                	jmp    f0100f61 <pgdir_walk+0xcb>

		struct PageInfo *page = page_alloc(ALLOC_ZERO);

		if(page == NULL) return NULL;
f0100f5c:	b8 00 00 00 00       	mov    $0x0,%eax
		ptable_entry = (pte_t*) KADDR(PTE_ADDR(*pdir_entry));
	}
	
	return ptable_entry + tableIndex;
	
}
f0100f61:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f64:	5b                   	pop    %ebx
f0100f65:	5e                   	pop    %esi
f0100f66:	5d                   	pop    %ebp
f0100f67:	c3                   	ret    

f0100f68 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f68:	55                   	push   %ebp
f0100f69:	89 e5                	mov    %esp,%ebp
f0100f6b:	57                   	push   %edi
f0100f6c:	56                   	push   %esi
f0100f6d:	53                   	push   %ebx
f0100f6e:	83 ec 1c             	sub    $0x1c,%esp
f0100f71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f74:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100f77:	c1 e9 0c             	shr    $0xc,%ecx
f0100f7a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f7d:	89 c3                	mov    %eax,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;
f0100f7f:	be 00 00 00 00       	mov    $0x0,%esi

	for(i; i < size/PGSIZE; ++i)
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0100f84:	89 d7                	mov    %edx,%edi
f0100f86:	29 c7                	sub    %eax,%edi

		if(ptable_entry == NULL) return;
		
		*ptable_entry = pa | perm | PTE_P;
f0100f88:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f8b:	83 c8 01             	or     $0x1,%eax
f0100f8e:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100f91:	eb 28                	jmp    f0100fbb <boot_map_region+0x53>
	{
		pte_t* ptable_entry = pgdir_walk(pgdir, (void*) va, 1);
f0100f93:	83 ec 04             	sub    $0x4,%esp
f0100f96:	6a 01                	push   $0x1
f0100f98:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f9b:	50                   	push   %eax
f0100f9c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f9f:	e8 f2 fe ff ff       	call   f0100e96 <pgdir_walk>

		if(ptable_entry == NULL) return;
f0100fa4:	83 c4 10             	add    $0x10,%esp
f0100fa7:	85 c0                	test   %eax,%eax
f0100fa9:	74 15                	je     f0100fc0 <boot_map_region+0x58>
		
		*ptable_entry = pa | perm | PTE_P;
f0100fab:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fae:	09 da                	or     %ebx,%edx
f0100fb0:	89 10                	mov    %edx,(%eax)

		pa += PGSIZE;
f0100fb2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t i = 0;

	for(i; i < size/PGSIZE; ++i)
f0100fb8:	83 c6 01             	add    $0x1,%esi
f0100fbb:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fbe:	75 d3                	jne    f0100f93 <boot_map_region+0x2b>

		pa += PGSIZE;
		va += PGSIZE;
	}
		
}
f0100fc0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc3:	5b                   	pop    %ebx
f0100fc4:	5e                   	pop    %esi
f0100fc5:	5f                   	pop    %edi
f0100fc6:	5d                   	pop    %ebp
f0100fc7:	c3                   	ret    

f0100fc8 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fc8:	55                   	push   %ebp
f0100fc9:	89 e5                	mov    %esp,%ebp
f0100fcb:	53                   	push   %ebx
f0100fcc:	83 ec 08             	sub    $0x8,%esp
f0100fcf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
f0100fd2:	6a 00                	push   $0x0
f0100fd4:	ff 75 0c             	pushl  0xc(%ebp)
f0100fd7:	ff 75 08             	pushl  0x8(%ebp)
f0100fda:	e8 b7 fe ff ff       	call   f0100e96 <pgdir_walk>
	
	if(!ptEntry) return NULL;
f0100fdf:	83 c4 10             	add    $0x10,%esp
f0100fe2:	85 c0                	test   %eax,%eax
f0100fe4:	74 32                	je     f0101018 <page_lookup+0x50>

	if(pte_store)
f0100fe6:	85 db                	test   %ebx,%ebx
f0100fe8:	74 02                	je     f0100fec <page_lookup+0x24>
	{
		*pte_store = ptEntry;
f0100fea:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fec:	8b 00                	mov    (%eax),%eax
f0100fee:	c1 e8 0c             	shr    $0xc,%eax
f0100ff1:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0100ff7:	72 14                	jb     f010100d <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100ff9:	83 ec 04             	sub    $0x4,%esp
f0100ffc:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0101001:	6a 4b                	push   $0x4b
f0101003:	68 54 43 10 f0       	push   $0xf0104354
f0101008:	e8 7e f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f010100d:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f0101013:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}	
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;
f0101016:	eb 05                	jmp    f010101d <page_lookup+0x55>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 0);
	
	if(!ptEntry) return NULL;
f0101018:	b8 00 00 00 00       	mov    $0x0,%eax
	
	struct PageInfo *page = (struct PageInfo*) pa2page(PTE_ADDR(*ptEntry));

	return page;

}
f010101d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101020:	c9                   	leave  
f0101021:	c3                   	ret    

f0101022 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101022:	55                   	push   %ebp
f0101023:	89 e5                	mov    %esp,%ebp
f0101025:	53                   	push   %ebx
f0101026:	83 ec 18             	sub    $0x18,%esp
f0101029:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *ptEntry = NULL;
f010102c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &ptEntry);
f0101033:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101036:	50                   	push   %eax
f0101037:	53                   	push   %ebx
f0101038:	ff 75 08             	pushl  0x8(%ebp)
f010103b:	e8 88 ff ff ff       	call   f0100fc8 <page_lookup>

	if(!page || !(*ptEntry & PTE_P)) return;
f0101040:	83 c4 10             	add    $0x10,%esp
f0101043:	85 c0                	test   %eax,%eax
f0101045:	74 20                	je     f0101067 <page_remove+0x45>
f0101047:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010104a:	f6 02 01             	testb  $0x1,(%edx)
f010104d:	74 18                	je     f0101067 <page_remove+0x45>

	page_decref(page);
f010104f:	83 ec 0c             	sub    $0xc,%esp
f0101052:	50                   	push   %eax
f0101053:	e8 17 fe ff ff       	call   f0100e6f <page_decref>

	*ptEntry = 0;
f0101058:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010105b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101061:	0f 01 3b             	invlpg (%ebx)
f0101064:	83 c4 10             	add    $0x10,%esp

	tlb_invalidate(pgdir, va);
}
f0101067:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010106a:	c9                   	leave  
f010106b:	c3                   	ret    

f010106c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010106c:	55                   	push   %ebp
f010106d:	89 e5                	mov    %esp,%ebp
f010106f:	57                   	push   %edi
f0101070:	56                   	push   %esi
f0101071:	53                   	push   %ebx
f0101072:	83 ec 10             	sub    $0x10,%esp
f0101075:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101078:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
f010107b:	6a 01                	push   $0x1
f010107d:	56                   	push   %esi
f010107e:	ff 75 08             	pushl  0x8(%ebp)
f0101081:	e8 10 fe ff ff       	call   f0100e96 <pgdir_walk>
	
	if(!ptEntry) return -E_NO_MEM;
f0101086:	83 c4 10             	add    $0x10,%esp
f0101089:	85 c0                	test   %eax,%eax
f010108b:	74 3b                	je     f01010c8 <page_insert+0x5c>
f010108d:	89 c7                	mov    %eax,%edi
	
	pp->pp_ref++;
f010108f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	if(*ptEntry & PTE_P)
f0101094:	f6 00 01             	testb  $0x1,(%eax)
f0101097:	74 12                	je     f01010ab <page_insert+0x3f>
	{
		page_remove(pgdir, va);
f0101099:	83 ec 08             	sub    $0x8,%esp
f010109c:	56                   	push   %esi
f010109d:	ff 75 08             	pushl  0x8(%ebp)
f01010a0:	e8 7d ff ff ff       	call   f0101022 <page_remove>
f01010a5:	0f 01 3e             	invlpg (%esi)
f01010a8:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;
f01010ab:	2b 1d 4c 79 11 f0    	sub    0xf011794c,%ebx
f01010b1:	c1 fb 03             	sar    $0x3,%ebx
f01010b4:	c1 e3 0c             	shl    $0xc,%ebx
f01010b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ba:	83 c8 01             	or     $0x1,%eax
f01010bd:	09 c3                	or     %eax,%ebx
f01010bf:	89 1f                	mov    %ebx,(%edi)

	return 0;
f01010c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c6:	eb 05                	jmp    f01010cd <page_insert+0x61>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *ptEntry = pgdir_walk(pgdir, va, 1);
	
	if(!ptEntry) return -E_NO_MEM;
f01010c8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*ptEntry = page2pa(pp) | perm | PTE_P;

	return 0;
}
f01010cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010d0:	5b                   	pop    %ebx
f01010d1:	5e                   	pop    %esi
f01010d2:	5f                   	pop    %edi
f01010d3:	5d                   	pop    %ebp
f01010d4:	c3                   	ret    

f01010d5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010d5:	55                   	push   %ebp
f01010d6:	89 e5                	mov    %esp,%ebp
f01010d8:	57                   	push   %edi
f01010d9:	56                   	push   %esi
f01010da:	53                   	push   %ebx
f01010db:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010de:	b8 15 00 00 00       	mov    $0x15,%eax
f01010e3:	e8 40 f8 ff ff       	call   f0100928 <nvram_read>
f01010e8:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010ea:	b8 17 00 00 00       	mov    $0x17,%eax
f01010ef:	e8 34 f8 ff ff       	call   f0100928 <nvram_read>
f01010f4:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010f6:	b8 34 00 00 00       	mov    $0x34,%eax
f01010fb:	e8 28 f8 ff ff       	call   f0100928 <nvram_read>
f0101100:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101103:	85 c0                	test   %eax,%eax
f0101105:	74 07                	je     f010110e <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101107:	05 00 40 00 00       	add    $0x4000,%eax
f010110c:	eb 0b                	jmp    f0101119 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010110e:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101114:	85 f6                	test   %esi,%esi
f0101116:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101119:	89 c2                	mov    %eax,%edx
f010111b:	c1 ea 02             	shr    $0x2,%edx
f010111e:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101124:	89 c2                	mov    %eax,%edx
f0101126:	29 da                	sub    %ebx,%edx
f0101128:	52                   	push   %edx
f0101129:	53                   	push   %ebx
f010112a:	50                   	push   %eax
f010112b:	68 4c 3d 10 f0       	push   $0xf0103d4c
f0101130:	e8 c9 15 00 00       	call   f01026fe <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101135:	b8 00 10 00 00       	mov    $0x1000,%eax
f010113a:	e8 76 f8 ff ff       	call   f01009b5 <boot_alloc>
f010113f:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f0101144:	83 c4 0c             	add    $0xc,%esp
f0101147:	68 00 10 00 00       	push   $0x1000
f010114c:	6a 00                	push   $0x0
f010114e:	50                   	push   %eax
f010114f:	e8 63 20 00 00       	call   f01031b7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101154:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101159:	83 c4 10             	add    $0x10,%esp
f010115c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101161:	77 15                	ja     f0101178 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101163:	50                   	push   %eax
f0101164:	68 c8 3b 10 f0       	push   $0xf0103bc8
f0101169:	68 9f 00 00 00       	push   $0x9f
f010116e:	68 48 43 10 f0       	push   $0xf0104348
f0101173:	e8 13 ef ff ff       	call   f010008b <_panic>
f0101178:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010117e:	83 ca 05             	or     $0x5,%edx
f0101181:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof(struct PageInfo)*npages);
f0101187:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f010118c:	c1 e0 03             	shl    $0x3,%eax
f010118f:	e8 21 f8 ff ff       	call   f01009b5 <boot_alloc>
f0101194:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f0101199:	83 ec 04             	sub    $0x4,%esp
f010119c:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f01011a2:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01011a9:	52                   	push   %edx
f01011aa:	6a 00                	push   $0x0
f01011ac:	50                   	push   %eax
f01011ad:	e8 05 20 00 00       	call   f01031b7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011b2:	e8 42 fb ff ff       	call   f0100cf9 <page_init>

	check_page_free_list(1);
f01011b7:	b8 01 00 00 00       	mov    $0x1,%eax
f01011bc:	e8 75 f8 ff ff       	call   f0100a36 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011c1:	83 c4 10             	add    $0x10,%esp
f01011c4:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01011cb:	75 17                	jne    f01011e4 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f01011cd:	83 ec 04             	sub    $0x4,%esp
f01011d0:	68 fe 43 10 f0       	push   $0xf01043fe
f01011d5:	68 84 02 00 00       	push   $0x284
f01011da:	68 48 43 10 f0       	push   $0xf0104348
f01011df:	e8 a7 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011e4:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011e9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011ee:	eb 05                	jmp    f01011f5 <mem_init+0x120>
		++nfree;
f01011f0:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011f3:	8b 00                	mov    (%eax),%eax
f01011f5:	85 c0                	test   %eax,%eax
f01011f7:	75 f7                	jne    f01011f0 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011f9:	83 ec 0c             	sub    $0xc,%esp
f01011fc:	6a 00                	push   $0x0
f01011fe:	e8 c1 fb ff ff       	call   f0100dc4 <page_alloc>
f0101203:	89 c7                	mov    %eax,%edi
f0101205:	83 c4 10             	add    $0x10,%esp
f0101208:	85 c0                	test   %eax,%eax
f010120a:	75 19                	jne    f0101225 <mem_init+0x150>
f010120c:	68 19 44 10 f0       	push   $0xf0104419
f0101211:	68 6e 43 10 f0       	push   $0xf010436e
f0101216:	68 8c 02 00 00       	push   $0x28c
f010121b:	68 48 43 10 f0       	push   $0xf0104348
f0101220:	e8 66 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101225:	83 ec 0c             	sub    $0xc,%esp
f0101228:	6a 00                	push   $0x0
f010122a:	e8 95 fb ff ff       	call   f0100dc4 <page_alloc>
f010122f:	89 c6                	mov    %eax,%esi
f0101231:	83 c4 10             	add    $0x10,%esp
f0101234:	85 c0                	test   %eax,%eax
f0101236:	75 19                	jne    f0101251 <mem_init+0x17c>
f0101238:	68 2f 44 10 f0       	push   $0xf010442f
f010123d:	68 6e 43 10 f0       	push   $0xf010436e
f0101242:	68 8d 02 00 00       	push   $0x28d
f0101247:	68 48 43 10 f0       	push   $0xf0104348
f010124c:	e8 3a ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101251:	83 ec 0c             	sub    $0xc,%esp
f0101254:	6a 00                	push   $0x0
f0101256:	e8 69 fb ff ff       	call   f0100dc4 <page_alloc>
f010125b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010125e:	83 c4 10             	add    $0x10,%esp
f0101261:	85 c0                	test   %eax,%eax
f0101263:	75 19                	jne    f010127e <mem_init+0x1a9>
f0101265:	68 45 44 10 f0       	push   $0xf0104445
f010126a:	68 6e 43 10 f0       	push   $0xf010436e
f010126f:	68 8e 02 00 00       	push   $0x28e
f0101274:	68 48 43 10 f0       	push   $0xf0104348
f0101279:	e8 0d ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010127e:	39 f7                	cmp    %esi,%edi
f0101280:	75 19                	jne    f010129b <mem_init+0x1c6>
f0101282:	68 5b 44 10 f0       	push   $0xf010445b
f0101287:	68 6e 43 10 f0       	push   $0xf010436e
f010128c:	68 91 02 00 00       	push   $0x291
f0101291:	68 48 43 10 f0       	push   $0xf0104348
f0101296:	e8 f0 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010129b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129e:	39 c6                	cmp    %eax,%esi
f01012a0:	74 04                	je     f01012a6 <mem_init+0x1d1>
f01012a2:	39 c7                	cmp    %eax,%edi
f01012a4:	75 19                	jne    f01012bf <mem_init+0x1ea>
f01012a6:	68 88 3d 10 f0       	push   $0xf0103d88
f01012ab:	68 6e 43 10 f0       	push   $0xf010436e
f01012b0:	68 92 02 00 00       	push   $0x292
f01012b5:	68 48 43 10 f0       	push   $0xf0104348
f01012ba:	e8 cc ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012bf:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012c5:	8b 15 44 79 11 f0    	mov    0xf0117944,%edx
f01012cb:	c1 e2 0c             	shl    $0xc,%edx
f01012ce:	89 f8                	mov    %edi,%eax
f01012d0:	29 c8                	sub    %ecx,%eax
f01012d2:	c1 f8 03             	sar    $0x3,%eax
f01012d5:	c1 e0 0c             	shl    $0xc,%eax
f01012d8:	39 d0                	cmp    %edx,%eax
f01012da:	72 19                	jb     f01012f5 <mem_init+0x220>
f01012dc:	68 6d 44 10 f0       	push   $0xf010446d
f01012e1:	68 6e 43 10 f0       	push   $0xf010436e
f01012e6:	68 93 02 00 00       	push   $0x293
f01012eb:	68 48 43 10 f0       	push   $0xf0104348
f01012f0:	e8 96 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012f5:	89 f0                	mov    %esi,%eax
f01012f7:	29 c8                	sub    %ecx,%eax
f01012f9:	c1 f8 03             	sar    $0x3,%eax
f01012fc:	c1 e0 0c             	shl    $0xc,%eax
f01012ff:	39 c2                	cmp    %eax,%edx
f0101301:	77 19                	ja     f010131c <mem_init+0x247>
f0101303:	68 8a 44 10 f0       	push   $0xf010448a
f0101308:	68 6e 43 10 f0       	push   $0xf010436e
f010130d:	68 94 02 00 00       	push   $0x294
f0101312:	68 48 43 10 f0       	push   $0xf0104348
f0101317:	e8 6f ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010131c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010131f:	29 c8                	sub    %ecx,%eax
f0101321:	c1 f8 03             	sar    $0x3,%eax
f0101324:	c1 e0 0c             	shl    $0xc,%eax
f0101327:	39 c2                	cmp    %eax,%edx
f0101329:	77 19                	ja     f0101344 <mem_init+0x26f>
f010132b:	68 a7 44 10 f0       	push   $0xf01044a7
f0101330:	68 6e 43 10 f0       	push   $0xf010436e
f0101335:	68 95 02 00 00       	push   $0x295
f010133a:	68 48 43 10 f0       	push   $0xf0104348
f010133f:	e8 47 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101344:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101349:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010134c:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101353:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101356:	83 ec 0c             	sub    $0xc,%esp
f0101359:	6a 00                	push   $0x0
f010135b:	e8 64 fa ff ff       	call   f0100dc4 <page_alloc>
f0101360:	83 c4 10             	add    $0x10,%esp
f0101363:	85 c0                	test   %eax,%eax
f0101365:	74 19                	je     f0101380 <mem_init+0x2ab>
f0101367:	68 c4 44 10 f0       	push   $0xf01044c4
f010136c:	68 6e 43 10 f0       	push   $0xf010436e
f0101371:	68 9c 02 00 00       	push   $0x29c
f0101376:	68 48 43 10 f0       	push   $0xf0104348
f010137b:	e8 0b ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101380:	83 ec 0c             	sub    $0xc,%esp
f0101383:	57                   	push   %edi
f0101384:	e8 ab fa ff ff       	call   f0100e34 <page_free>
	page_free(pp1);
f0101389:	89 34 24             	mov    %esi,(%esp)
f010138c:	e8 a3 fa ff ff       	call   f0100e34 <page_free>
	page_free(pp2);
f0101391:	83 c4 04             	add    $0x4,%esp
f0101394:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101397:	e8 98 fa ff ff       	call   f0100e34 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010139c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a3:	e8 1c fa ff ff       	call   f0100dc4 <page_alloc>
f01013a8:	89 c6                	mov    %eax,%esi
f01013aa:	83 c4 10             	add    $0x10,%esp
f01013ad:	85 c0                	test   %eax,%eax
f01013af:	75 19                	jne    f01013ca <mem_init+0x2f5>
f01013b1:	68 19 44 10 f0       	push   $0xf0104419
f01013b6:	68 6e 43 10 f0       	push   $0xf010436e
f01013bb:	68 a3 02 00 00       	push   $0x2a3
f01013c0:	68 48 43 10 f0       	push   $0xf0104348
f01013c5:	e8 c1 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013ca:	83 ec 0c             	sub    $0xc,%esp
f01013cd:	6a 00                	push   $0x0
f01013cf:	e8 f0 f9 ff ff       	call   f0100dc4 <page_alloc>
f01013d4:	89 c7                	mov    %eax,%edi
f01013d6:	83 c4 10             	add    $0x10,%esp
f01013d9:	85 c0                	test   %eax,%eax
f01013db:	75 19                	jne    f01013f6 <mem_init+0x321>
f01013dd:	68 2f 44 10 f0       	push   $0xf010442f
f01013e2:	68 6e 43 10 f0       	push   $0xf010436e
f01013e7:	68 a4 02 00 00       	push   $0x2a4
f01013ec:	68 48 43 10 f0       	push   $0xf0104348
f01013f1:	e8 95 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013f6:	83 ec 0c             	sub    $0xc,%esp
f01013f9:	6a 00                	push   $0x0
f01013fb:	e8 c4 f9 ff ff       	call   f0100dc4 <page_alloc>
f0101400:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101403:	83 c4 10             	add    $0x10,%esp
f0101406:	85 c0                	test   %eax,%eax
f0101408:	75 19                	jne    f0101423 <mem_init+0x34e>
f010140a:	68 45 44 10 f0       	push   $0xf0104445
f010140f:	68 6e 43 10 f0       	push   $0xf010436e
f0101414:	68 a5 02 00 00       	push   $0x2a5
f0101419:	68 48 43 10 f0       	push   $0xf0104348
f010141e:	e8 68 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101423:	39 fe                	cmp    %edi,%esi
f0101425:	75 19                	jne    f0101440 <mem_init+0x36b>
f0101427:	68 5b 44 10 f0       	push   $0xf010445b
f010142c:	68 6e 43 10 f0       	push   $0xf010436e
f0101431:	68 a7 02 00 00       	push   $0x2a7
f0101436:	68 48 43 10 f0       	push   $0xf0104348
f010143b:	e8 4b ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101440:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101443:	39 c6                	cmp    %eax,%esi
f0101445:	74 04                	je     f010144b <mem_init+0x376>
f0101447:	39 c7                	cmp    %eax,%edi
f0101449:	75 19                	jne    f0101464 <mem_init+0x38f>
f010144b:	68 88 3d 10 f0       	push   $0xf0103d88
f0101450:	68 6e 43 10 f0       	push   $0xf010436e
f0101455:	68 a8 02 00 00       	push   $0x2a8
f010145a:	68 48 43 10 f0       	push   $0xf0104348
f010145f:	e8 27 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101464:	83 ec 0c             	sub    $0xc,%esp
f0101467:	6a 00                	push   $0x0
f0101469:	e8 56 f9 ff ff       	call   f0100dc4 <page_alloc>
f010146e:	83 c4 10             	add    $0x10,%esp
f0101471:	85 c0                	test   %eax,%eax
f0101473:	74 19                	je     f010148e <mem_init+0x3b9>
f0101475:	68 c4 44 10 f0       	push   $0xf01044c4
f010147a:	68 6e 43 10 f0       	push   $0xf010436e
f010147f:	68 a9 02 00 00       	push   $0x2a9
f0101484:	68 48 43 10 f0       	push   $0xf0104348
f0101489:	e8 fd eb ff ff       	call   f010008b <_panic>
f010148e:	89 f0                	mov    %esi,%eax
f0101490:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101496:	c1 f8 03             	sar    $0x3,%eax
f0101499:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010149c:	89 c2                	mov    %eax,%edx
f010149e:	c1 ea 0c             	shr    $0xc,%edx
f01014a1:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01014a7:	72 12                	jb     f01014bb <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014a9:	50                   	push   %eax
f01014aa:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01014af:	6a 52                	push   $0x52
f01014b1:	68 54 43 10 f0       	push   $0xf0104354
f01014b6:	e8 d0 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014bb:	83 ec 04             	sub    $0x4,%esp
f01014be:	68 00 10 00 00       	push   $0x1000
f01014c3:	6a 01                	push   $0x1
f01014c5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014ca:	50                   	push   %eax
f01014cb:	e8 e7 1c 00 00       	call   f01031b7 <memset>
	page_free(pp0);
f01014d0:	89 34 24             	mov    %esi,(%esp)
f01014d3:	e8 5c f9 ff ff       	call   f0100e34 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014df:	e8 e0 f8 ff ff       	call   f0100dc4 <page_alloc>
f01014e4:	83 c4 10             	add    $0x10,%esp
f01014e7:	85 c0                	test   %eax,%eax
f01014e9:	75 19                	jne    f0101504 <mem_init+0x42f>
f01014eb:	68 d3 44 10 f0       	push   $0xf01044d3
f01014f0:	68 6e 43 10 f0       	push   $0xf010436e
f01014f5:	68 ae 02 00 00       	push   $0x2ae
f01014fa:	68 48 43 10 f0       	push   $0xf0104348
f01014ff:	e8 87 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101504:	39 c6                	cmp    %eax,%esi
f0101506:	74 19                	je     f0101521 <mem_init+0x44c>
f0101508:	68 f1 44 10 f0       	push   $0xf01044f1
f010150d:	68 6e 43 10 f0       	push   $0xf010436e
f0101512:	68 af 02 00 00       	push   $0x2af
f0101517:	68 48 43 10 f0       	push   $0xf0104348
f010151c:	e8 6a eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101521:	89 f0                	mov    %esi,%eax
f0101523:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101529:	c1 f8 03             	sar    $0x3,%eax
f010152c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010152f:	89 c2                	mov    %eax,%edx
f0101531:	c1 ea 0c             	shr    $0xc,%edx
f0101534:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f010153a:	72 12                	jb     f010154e <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010153c:	50                   	push   %eax
f010153d:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101542:	6a 52                	push   $0x52
f0101544:	68 54 43 10 f0       	push   $0xf0104354
f0101549:	e8 3d eb ff ff       	call   f010008b <_panic>
f010154e:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101554:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010155a:	80 38 00             	cmpb   $0x0,(%eax)
f010155d:	74 19                	je     f0101578 <mem_init+0x4a3>
f010155f:	68 01 45 10 f0       	push   $0xf0104501
f0101564:	68 6e 43 10 f0       	push   $0xf010436e
f0101569:	68 b2 02 00 00       	push   $0x2b2
f010156e:	68 48 43 10 f0       	push   $0xf0104348
f0101573:	e8 13 eb ff ff       	call   f010008b <_panic>
f0101578:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010157b:	39 d0                	cmp    %edx,%eax
f010157d:	75 db                	jne    f010155a <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010157f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101582:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101587:	83 ec 0c             	sub    $0xc,%esp
f010158a:	56                   	push   %esi
f010158b:	e8 a4 f8 ff ff       	call   f0100e34 <page_free>
	page_free(pp1);
f0101590:	89 3c 24             	mov    %edi,(%esp)
f0101593:	e8 9c f8 ff ff       	call   f0100e34 <page_free>
	page_free(pp2);
f0101598:	83 c4 04             	add    $0x4,%esp
f010159b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010159e:	e8 91 f8 ff ff       	call   f0100e34 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015a3:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015a8:	83 c4 10             	add    $0x10,%esp
f01015ab:	eb 05                	jmp    f01015b2 <mem_init+0x4dd>
		--nfree;
f01015ad:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015b0:	8b 00                	mov    (%eax),%eax
f01015b2:	85 c0                	test   %eax,%eax
f01015b4:	75 f7                	jne    f01015ad <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f01015b6:	85 db                	test   %ebx,%ebx
f01015b8:	74 19                	je     f01015d3 <mem_init+0x4fe>
f01015ba:	68 0b 45 10 f0       	push   $0xf010450b
f01015bf:	68 6e 43 10 f0       	push   $0xf010436e
f01015c4:	68 bf 02 00 00       	push   $0x2bf
f01015c9:	68 48 43 10 f0       	push   $0xf0104348
f01015ce:	e8 b8 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015d3:	83 ec 0c             	sub    $0xc,%esp
f01015d6:	68 a8 3d 10 f0       	push   $0xf0103da8
f01015db:	e8 1e 11 00 00       	call   f01026fe <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e7:	e8 d8 f7 ff ff       	call   f0100dc4 <page_alloc>
f01015ec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015ef:	83 c4 10             	add    $0x10,%esp
f01015f2:	85 c0                	test   %eax,%eax
f01015f4:	75 19                	jne    f010160f <mem_init+0x53a>
f01015f6:	68 19 44 10 f0       	push   $0xf0104419
f01015fb:	68 6e 43 10 f0       	push   $0xf010436e
f0101600:	68 18 03 00 00       	push   $0x318
f0101605:	68 48 43 10 f0       	push   $0xf0104348
f010160a:	e8 7c ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010160f:	83 ec 0c             	sub    $0xc,%esp
f0101612:	6a 00                	push   $0x0
f0101614:	e8 ab f7 ff ff       	call   f0100dc4 <page_alloc>
f0101619:	89 c3                	mov    %eax,%ebx
f010161b:	83 c4 10             	add    $0x10,%esp
f010161e:	85 c0                	test   %eax,%eax
f0101620:	75 19                	jne    f010163b <mem_init+0x566>
f0101622:	68 2f 44 10 f0       	push   $0xf010442f
f0101627:	68 6e 43 10 f0       	push   $0xf010436e
f010162c:	68 19 03 00 00       	push   $0x319
f0101631:	68 48 43 10 f0       	push   $0xf0104348
f0101636:	e8 50 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010163b:	83 ec 0c             	sub    $0xc,%esp
f010163e:	6a 00                	push   $0x0
f0101640:	e8 7f f7 ff ff       	call   f0100dc4 <page_alloc>
f0101645:	89 c6                	mov    %eax,%esi
f0101647:	83 c4 10             	add    $0x10,%esp
f010164a:	85 c0                	test   %eax,%eax
f010164c:	75 19                	jne    f0101667 <mem_init+0x592>
f010164e:	68 45 44 10 f0       	push   $0xf0104445
f0101653:	68 6e 43 10 f0       	push   $0xf010436e
f0101658:	68 1a 03 00 00       	push   $0x31a
f010165d:	68 48 43 10 f0       	push   $0xf0104348
f0101662:	e8 24 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101667:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010166a:	75 19                	jne    f0101685 <mem_init+0x5b0>
f010166c:	68 5b 44 10 f0       	push   $0xf010445b
f0101671:	68 6e 43 10 f0       	push   $0xf010436e
f0101676:	68 1d 03 00 00       	push   $0x31d
f010167b:	68 48 43 10 f0       	push   $0xf0104348
f0101680:	e8 06 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101685:	39 c3                	cmp    %eax,%ebx
f0101687:	74 05                	je     f010168e <mem_init+0x5b9>
f0101689:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010168c:	75 19                	jne    f01016a7 <mem_init+0x5d2>
f010168e:	68 88 3d 10 f0       	push   $0xf0103d88
f0101693:	68 6e 43 10 f0       	push   $0xf010436e
f0101698:	68 1e 03 00 00       	push   $0x31e
f010169d:	68 48 43 10 f0       	push   $0xf0104348
f01016a2:	e8 e4 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016a7:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016ac:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016af:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01016b6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016b9:	83 ec 0c             	sub    $0xc,%esp
f01016bc:	6a 00                	push   $0x0
f01016be:	e8 01 f7 ff ff       	call   f0100dc4 <page_alloc>
f01016c3:	83 c4 10             	add    $0x10,%esp
f01016c6:	85 c0                	test   %eax,%eax
f01016c8:	74 19                	je     f01016e3 <mem_init+0x60e>
f01016ca:	68 c4 44 10 f0       	push   $0xf01044c4
f01016cf:	68 6e 43 10 f0       	push   $0xf010436e
f01016d4:	68 25 03 00 00       	push   $0x325
f01016d9:	68 48 43 10 f0       	push   $0xf0104348
f01016de:	e8 a8 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016e3:	83 ec 04             	sub    $0x4,%esp
f01016e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016e9:	50                   	push   %eax
f01016ea:	6a 00                	push   $0x0
f01016ec:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01016f2:	e8 d1 f8 ff ff       	call   f0100fc8 <page_lookup>
f01016f7:	83 c4 10             	add    $0x10,%esp
f01016fa:	85 c0                	test   %eax,%eax
f01016fc:	74 19                	je     f0101717 <mem_init+0x642>
f01016fe:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0101703:	68 6e 43 10 f0       	push   $0xf010436e
f0101708:	68 28 03 00 00       	push   $0x328
f010170d:	68 48 43 10 f0       	push   $0xf0104348
f0101712:	e8 74 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101717:	6a 02                	push   $0x2
f0101719:	6a 00                	push   $0x0
f010171b:	53                   	push   %ebx
f010171c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101722:	e8 45 f9 ff ff       	call   f010106c <page_insert>
f0101727:	83 c4 10             	add    $0x10,%esp
f010172a:	85 c0                	test   %eax,%eax
f010172c:	78 19                	js     f0101747 <mem_init+0x672>
f010172e:	68 00 3e 10 f0       	push   $0xf0103e00
f0101733:	68 6e 43 10 f0       	push   $0xf010436e
f0101738:	68 2b 03 00 00       	push   $0x32b
f010173d:	68 48 43 10 f0       	push   $0xf0104348
f0101742:	e8 44 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101747:	83 ec 0c             	sub    $0xc,%esp
f010174a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010174d:	e8 e2 f6 ff ff       	call   f0100e34 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101752:	6a 02                	push   $0x2
f0101754:	6a 00                	push   $0x0
f0101756:	53                   	push   %ebx
f0101757:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010175d:	e8 0a f9 ff ff       	call   f010106c <page_insert>
f0101762:	83 c4 20             	add    $0x20,%esp
f0101765:	85 c0                	test   %eax,%eax
f0101767:	74 19                	je     f0101782 <mem_init+0x6ad>
f0101769:	68 30 3e 10 f0       	push   $0xf0103e30
f010176e:	68 6e 43 10 f0       	push   $0xf010436e
f0101773:	68 2f 03 00 00       	push   $0x32f
f0101778:	68 48 43 10 f0       	push   $0xf0104348
f010177d:	e8 09 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101782:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101788:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f010178d:	89 c1                	mov    %eax,%ecx
f010178f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101792:	8b 17                	mov    (%edi),%edx
f0101794:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010179a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179d:	29 c8                	sub    %ecx,%eax
f010179f:	c1 f8 03             	sar    $0x3,%eax
f01017a2:	c1 e0 0c             	shl    $0xc,%eax
f01017a5:	39 c2                	cmp    %eax,%edx
f01017a7:	74 19                	je     f01017c2 <mem_init+0x6ed>
f01017a9:	68 60 3e 10 f0       	push   $0xf0103e60
f01017ae:	68 6e 43 10 f0       	push   $0xf010436e
f01017b3:	68 30 03 00 00       	push   $0x330
f01017b8:	68 48 43 10 f0       	push   $0xf0104348
f01017bd:	e8 c9 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01017c7:	89 f8                	mov    %edi,%eax
f01017c9:	e8 83 f1 ff ff       	call   f0100951 <check_va2pa>
f01017ce:	89 da                	mov    %ebx,%edx
f01017d0:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017d3:	c1 fa 03             	sar    $0x3,%edx
f01017d6:	c1 e2 0c             	shl    $0xc,%edx
f01017d9:	39 d0                	cmp    %edx,%eax
f01017db:	74 19                	je     f01017f6 <mem_init+0x721>
f01017dd:	68 88 3e 10 f0       	push   $0xf0103e88
f01017e2:	68 6e 43 10 f0       	push   $0xf010436e
f01017e7:	68 31 03 00 00       	push   $0x331
f01017ec:	68 48 43 10 f0       	push   $0xf0104348
f01017f1:	e8 95 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017f6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017fb:	74 19                	je     f0101816 <mem_init+0x741>
f01017fd:	68 16 45 10 f0       	push   $0xf0104516
f0101802:	68 6e 43 10 f0       	push   $0xf010436e
f0101807:	68 32 03 00 00       	push   $0x332
f010180c:	68 48 43 10 f0       	push   $0xf0104348
f0101811:	e8 75 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101816:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101819:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010181e:	74 19                	je     f0101839 <mem_init+0x764>
f0101820:	68 27 45 10 f0       	push   $0xf0104527
f0101825:	68 6e 43 10 f0       	push   $0xf010436e
f010182a:	68 33 03 00 00       	push   $0x333
f010182f:	68 48 43 10 f0       	push   $0xf0104348
f0101834:	e8 52 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101839:	6a 02                	push   $0x2
f010183b:	68 00 10 00 00       	push   $0x1000
f0101840:	56                   	push   %esi
f0101841:	57                   	push   %edi
f0101842:	e8 25 f8 ff ff       	call   f010106c <page_insert>
f0101847:	83 c4 10             	add    $0x10,%esp
f010184a:	85 c0                	test   %eax,%eax
f010184c:	74 19                	je     f0101867 <mem_init+0x792>
f010184e:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101853:	68 6e 43 10 f0       	push   $0xf010436e
f0101858:	68 36 03 00 00       	push   $0x336
f010185d:	68 48 43 10 f0       	push   $0xf0104348
f0101862:	e8 24 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101867:	ba 00 10 00 00       	mov    $0x1000,%edx
f010186c:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101871:	e8 db f0 ff ff       	call   f0100951 <check_va2pa>
f0101876:	89 f2                	mov    %esi,%edx
f0101878:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f010187e:	c1 fa 03             	sar    $0x3,%edx
f0101881:	c1 e2 0c             	shl    $0xc,%edx
f0101884:	39 d0                	cmp    %edx,%eax
f0101886:	74 19                	je     f01018a1 <mem_init+0x7cc>
f0101888:	68 f4 3e 10 f0       	push   $0xf0103ef4
f010188d:	68 6e 43 10 f0       	push   $0xf010436e
f0101892:	68 37 03 00 00       	push   $0x337
f0101897:	68 48 43 10 f0       	push   $0xf0104348
f010189c:	e8 ea e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018a1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018a6:	74 19                	je     f01018c1 <mem_init+0x7ec>
f01018a8:	68 38 45 10 f0       	push   $0xf0104538
f01018ad:	68 6e 43 10 f0       	push   $0xf010436e
f01018b2:	68 38 03 00 00       	push   $0x338
f01018b7:	68 48 43 10 f0       	push   $0xf0104348
f01018bc:	e8 ca e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018c1:	83 ec 0c             	sub    $0xc,%esp
f01018c4:	6a 00                	push   $0x0
f01018c6:	e8 f9 f4 ff ff       	call   f0100dc4 <page_alloc>
f01018cb:	83 c4 10             	add    $0x10,%esp
f01018ce:	85 c0                	test   %eax,%eax
f01018d0:	74 19                	je     f01018eb <mem_init+0x816>
f01018d2:	68 c4 44 10 f0       	push   $0xf01044c4
f01018d7:	68 6e 43 10 f0       	push   $0xf010436e
f01018dc:	68 3b 03 00 00       	push   $0x33b
f01018e1:	68 48 43 10 f0       	push   $0xf0104348
f01018e6:	e8 a0 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018eb:	6a 02                	push   $0x2
f01018ed:	68 00 10 00 00       	push   $0x1000
f01018f2:	56                   	push   %esi
f01018f3:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018f9:	e8 6e f7 ff ff       	call   f010106c <page_insert>
f01018fe:	83 c4 10             	add    $0x10,%esp
f0101901:	85 c0                	test   %eax,%eax
f0101903:	74 19                	je     f010191e <mem_init+0x849>
f0101905:	68 b8 3e 10 f0       	push   $0xf0103eb8
f010190a:	68 6e 43 10 f0       	push   $0xf010436e
f010190f:	68 3e 03 00 00       	push   $0x33e
f0101914:	68 48 43 10 f0       	push   $0xf0104348
f0101919:	e8 6d e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010191e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101923:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101928:	e8 24 f0 ff ff       	call   f0100951 <check_va2pa>
f010192d:	89 f2                	mov    %esi,%edx
f010192f:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101935:	c1 fa 03             	sar    $0x3,%edx
f0101938:	c1 e2 0c             	shl    $0xc,%edx
f010193b:	39 d0                	cmp    %edx,%eax
f010193d:	74 19                	je     f0101958 <mem_init+0x883>
f010193f:	68 f4 3e 10 f0       	push   $0xf0103ef4
f0101944:	68 6e 43 10 f0       	push   $0xf010436e
f0101949:	68 3f 03 00 00       	push   $0x33f
f010194e:	68 48 43 10 f0       	push   $0xf0104348
f0101953:	e8 33 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101958:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010195d:	74 19                	je     f0101978 <mem_init+0x8a3>
f010195f:	68 38 45 10 f0       	push   $0xf0104538
f0101964:	68 6e 43 10 f0       	push   $0xf010436e
f0101969:	68 40 03 00 00       	push   $0x340
f010196e:	68 48 43 10 f0       	push   $0xf0104348
f0101973:	e8 13 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101978:	83 ec 0c             	sub    $0xc,%esp
f010197b:	6a 00                	push   $0x0
f010197d:	e8 42 f4 ff ff       	call   f0100dc4 <page_alloc>
f0101982:	83 c4 10             	add    $0x10,%esp
f0101985:	85 c0                	test   %eax,%eax
f0101987:	74 19                	je     f01019a2 <mem_init+0x8cd>
f0101989:	68 c4 44 10 f0       	push   $0xf01044c4
f010198e:	68 6e 43 10 f0       	push   $0xf010436e
f0101993:	68 44 03 00 00       	push   $0x344
f0101998:	68 48 43 10 f0       	push   $0xf0104348
f010199d:	e8 e9 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019a2:	8b 15 48 79 11 f0    	mov    0xf0117948,%edx
f01019a8:	8b 02                	mov    (%edx),%eax
f01019aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019af:	89 c1                	mov    %eax,%ecx
f01019b1:	c1 e9 0c             	shr    $0xc,%ecx
f01019b4:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
f01019ba:	72 15                	jb     f01019d1 <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019bc:	50                   	push   %eax
f01019bd:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01019c2:	68 47 03 00 00       	push   $0x347
f01019c7:	68 48 43 10 f0       	push   $0xf0104348
f01019cc:	e8 ba e6 ff ff       	call   f010008b <_panic>
f01019d1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019d9:	83 ec 04             	sub    $0x4,%esp
f01019dc:	6a 00                	push   $0x0
f01019de:	68 00 10 00 00       	push   $0x1000
f01019e3:	52                   	push   %edx
f01019e4:	e8 ad f4 ff ff       	call   f0100e96 <pgdir_walk>
f01019e9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019ec:	8d 51 04             	lea    0x4(%ecx),%edx
f01019ef:	83 c4 10             	add    $0x10,%esp
f01019f2:	39 d0                	cmp    %edx,%eax
f01019f4:	74 19                	je     f0101a0f <mem_init+0x93a>
f01019f6:	68 24 3f 10 f0       	push   $0xf0103f24
f01019fb:	68 6e 43 10 f0       	push   $0xf010436e
f0101a00:	68 48 03 00 00       	push   $0x348
f0101a05:	68 48 43 10 f0       	push   $0xf0104348
f0101a0a:	e8 7c e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a0f:	6a 06                	push   $0x6
f0101a11:	68 00 10 00 00       	push   $0x1000
f0101a16:	56                   	push   %esi
f0101a17:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101a1d:	e8 4a f6 ff ff       	call   f010106c <page_insert>
f0101a22:	83 c4 10             	add    $0x10,%esp
f0101a25:	85 c0                	test   %eax,%eax
f0101a27:	74 19                	je     f0101a42 <mem_init+0x96d>
f0101a29:	68 64 3f 10 f0       	push   $0xf0103f64
f0101a2e:	68 6e 43 10 f0       	push   $0xf010436e
f0101a33:	68 4b 03 00 00       	push   $0x34b
f0101a38:	68 48 43 10 f0       	push   $0xf0104348
f0101a3d:	e8 49 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a42:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101a48:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a4d:	89 f8                	mov    %edi,%eax
f0101a4f:	e8 fd ee ff ff       	call   f0100951 <check_va2pa>
f0101a54:	89 f2                	mov    %esi,%edx
f0101a56:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101a5c:	c1 fa 03             	sar    $0x3,%edx
f0101a5f:	c1 e2 0c             	shl    $0xc,%edx
f0101a62:	39 d0                	cmp    %edx,%eax
f0101a64:	74 19                	je     f0101a7f <mem_init+0x9aa>
f0101a66:	68 f4 3e 10 f0       	push   $0xf0103ef4
f0101a6b:	68 6e 43 10 f0       	push   $0xf010436e
f0101a70:	68 4c 03 00 00       	push   $0x34c
f0101a75:	68 48 43 10 f0       	push   $0xf0104348
f0101a7a:	e8 0c e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a7f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a84:	74 19                	je     f0101a9f <mem_init+0x9ca>
f0101a86:	68 38 45 10 f0       	push   $0xf0104538
f0101a8b:	68 6e 43 10 f0       	push   $0xf010436e
f0101a90:	68 4d 03 00 00       	push   $0x34d
f0101a95:	68 48 43 10 f0       	push   $0xf0104348
f0101a9a:	e8 ec e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a9f:	83 ec 04             	sub    $0x4,%esp
f0101aa2:	6a 00                	push   $0x0
f0101aa4:	68 00 10 00 00       	push   $0x1000
f0101aa9:	57                   	push   %edi
f0101aaa:	e8 e7 f3 ff ff       	call   f0100e96 <pgdir_walk>
f0101aaf:	83 c4 10             	add    $0x10,%esp
f0101ab2:	f6 00 04             	testb  $0x4,(%eax)
f0101ab5:	75 19                	jne    f0101ad0 <mem_init+0x9fb>
f0101ab7:	68 a4 3f 10 f0       	push   $0xf0103fa4
f0101abc:	68 6e 43 10 f0       	push   $0xf010436e
f0101ac1:	68 4e 03 00 00       	push   $0x34e
f0101ac6:	68 48 43 10 f0       	push   $0xf0104348
f0101acb:	e8 bb e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ad0:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ad5:	f6 00 04             	testb  $0x4,(%eax)
f0101ad8:	75 19                	jne    f0101af3 <mem_init+0xa1e>
f0101ada:	68 49 45 10 f0       	push   $0xf0104549
f0101adf:	68 6e 43 10 f0       	push   $0xf010436e
f0101ae4:	68 4f 03 00 00       	push   $0x34f
f0101ae9:	68 48 43 10 f0       	push   $0xf0104348
f0101aee:	e8 98 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af3:	6a 02                	push   $0x2
f0101af5:	68 00 10 00 00       	push   $0x1000
f0101afa:	56                   	push   %esi
f0101afb:	50                   	push   %eax
f0101afc:	e8 6b f5 ff ff       	call   f010106c <page_insert>
f0101b01:	83 c4 10             	add    $0x10,%esp
f0101b04:	85 c0                	test   %eax,%eax
f0101b06:	74 19                	je     f0101b21 <mem_init+0xa4c>
f0101b08:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101b0d:	68 6e 43 10 f0       	push   $0xf010436e
f0101b12:	68 52 03 00 00       	push   $0x352
f0101b17:	68 48 43 10 f0       	push   $0xf0104348
f0101b1c:	e8 6a e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b21:	83 ec 04             	sub    $0x4,%esp
f0101b24:	6a 00                	push   $0x0
f0101b26:	68 00 10 00 00       	push   $0x1000
f0101b2b:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b31:	e8 60 f3 ff ff       	call   f0100e96 <pgdir_walk>
f0101b36:	83 c4 10             	add    $0x10,%esp
f0101b39:	f6 00 02             	testb  $0x2,(%eax)
f0101b3c:	75 19                	jne    f0101b57 <mem_init+0xa82>
f0101b3e:	68 d8 3f 10 f0       	push   $0xf0103fd8
f0101b43:	68 6e 43 10 f0       	push   $0xf010436e
f0101b48:	68 53 03 00 00       	push   $0x353
f0101b4d:	68 48 43 10 f0       	push   $0xf0104348
f0101b52:	e8 34 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b57:	83 ec 04             	sub    $0x4,%esp
f0101b5a:	6a 00                	push   $0x0
f0101b5c:	68 00 10 00 00       	push   $0x1000
f0101b61:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b67:	e8 2a f3 ff ff       	call   f0100e96 <pgdir_walk>
f0101b6c:	83 c4 10             	add    $0x10,%esp
f0101b6f:	f6 00 04             	testb  $0x4,(%eax)
f0101b72:	74 19                	je     f0101b8d <mem_init+0xab8>
f0101b74:	68 0c 40 10 f0       	push   $0xf010400c
f0101b79:	68 6e 43 10 f0       	push   $0xf010436e
f0101b7e:	68 54 03 00 00       	push   $0x354
f0101b83:	68 48 43 10 f0       	push   $0xf0104348
f0101b88:	e8 fe e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b8d:	6a 02                	push   $0x2
f0101b8f:	68 00 00 40 00       	push   $0x400000
f0101b94:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b97:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b9d:	e8 ca f4 ff ff       	call   f010106c <page_insert>
f0101ba2:	83 c4 10             	add    $0x10,%esp
f0101ba5:	85 c0                	test   %eax,%eax
f0101ba7:	78 19                	js     f0101bc2 <mem_init+0xaed>
f0101ba9:	68 44 40 10 f0       	push   $0xf0104044
f0101bae:	68 6e 43 10 f0       	push   $0xf010436e
f0101bb3:	68 57 03 00 00       	push   $0x357
f0101bb8:	68 48 43 10 f0       	push   $0xf0104348
f0101bbd:	e8 c9 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bc2:	6a 02                	push   $0x2
f0101bc4:	68 00 10 00 00       	push   $0x1000
f0101bc9:	53                   	push   %ebx
f0101bca:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101bd0:	e8 97 f4 ff ff       	call   f010106c <page_insert>
f0101bd5:	83 c4 10             	add    $0x10,%esp
f0101bd8:	85 c0                	test   %eax,%eax
f0101bda:	74 19                	je     f0101bf5 <mem_init+0xb20>
f0101bdc:	68 7c 40 10 f0       	push   $0xf010407c
f0101be1:	68 6e 43 10 f0       	push   $0xf010436e
f0101be6:	68 5a 03 00 00       	push   $0x35a
f0101beb:	68 48 43 10 f0       	push   $0xf0104348
f0101bf0:	e8 96 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bf5:	83 ec 04             	sub    $0x4,%esp
f0101bf8:	6a 00                	push   $0x0
f0101bfa:	68 00 10 00 00       	push   $0x1000
f0101bff:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101c05:	e8 8c f2 ff ff       	call   f0100e96 <pgdir_walk>
f0101c0a:	83 c4 10             	add    $0x10,%esp
f0101c0d:	f6 00 04             	testb  $0x4,(%eax)
f0101c10:	74 19                	je     f0101c2b <mem_init+0xb56>
f0101c12:	68 0c 40 10 f0       	push   $0xf010400c
f0101c17:	68 6e 43 10 f0       	push   $0xf010436e
f0101c1c:	68 5b 03 00 00       	push   $0x35b
f0101c21:	68 48 43 10 f0       	push   $0xf0104348
f0101c26:	e8 60 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c2b:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101c31:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c36:	89 f8                	mov    %edi,%eax
f0101c38:	e8 14 ed ff ff       	call   f0100951 <check_va2pa>
f0101c3d:	89 c1                	mov    %eax,%ecx
f0101c3f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c42:	89 d8                	mov    %ebx,%eax
f0101c44:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101c4a:	c1 f8 03             	sar    $0x3,%eax
f0101c4d:	c1 e0 0c             	shl    $0xc,%eax
f0101c50:	39 c1                	cmp    %eax,%ecx
f0101c52:	74 19                	je     f0101c6d <mem_init+0xb98>
f0101c54:	68 b8 40 10 f0       	push   $0xf01040b8
f0101c59:	68 6e 43 10 f0       	push   $0xf010436e
f0101c5e:	68 5e 03 00 00       	push   $0x35e
f0101c63:	68 48 43 10 f0       	push   $0xf0104348
f0101c68:	e8 1e e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c6d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c72:	89 f8                	mov    %edi,%eax
f0101c74:	e8 d8 ec ff ff       	call   f0100951 <check_va2pa>
f0101c79:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c7c:	74 19                	je     f0101c97 <mem_init+0xbc2>
f0101c7e:	68 e4 40 10 f0       	push   $0xf01040e4
f0101c83:	68 6e 43 10 f0       	push   $0xf010436e
f0101c88:	68 5f 03 00 00       	push   $0x35f
f0101c8d:	68 48 43 10 f0       	push   $0xf0104348
f0101c92:	e8 f4 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c97:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c9c:	74 19                	je     f0101cb7 <mem_init+0xbe2>
f0101c9e:	68 5f 45 10 f0       	push   $0xf010455f
f0101ca3:	68 6e 43 10 f0       	push   $0xf010436e
f0101ca8:	68 61 03 00 00       	push   $0x361
f0101cad:	68 48 43 10 f0       	push   $0xf0104348
f0101cb2:	e8 d4 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cb7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cbc:	74 19                	je     f0101cd7 <mem_init+0xc02>
f0101cbe:	68 70 45 10 f0       	push   $0xf0104570
f0101cc3:	68 6e 43 10 f0       	push   $0xf010436e
f0101cc8:	68 62 03 00 00       	push   $0x362
f0101ccd:	68 48 43 10 f0       	push   $0xf0104348
f0101cd2:	e8 b4 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cd7:	83 ec 0c             	sub    $0xc,%esp
f0101cda:	6a 00                	push   $0x0
f0101cdc:	e8 e3 f0 ff ff       	call   f0100dc4 <page_alloc>
f0101ce1:	83 c4 10             	add    $0x10,%esp
f0101ce4:	39 c6                	cmp    %eax,%esi
f0101ce6:	75 04                	jne    f0101cec <mem_init+0xc17>
f0101ce8:	85 c0                	test   %eax,%eax
f0101cea:	75 19                	jne    f0101d05 <mem_init+0xc30>
f0101cec:	68 14 41 10 f0       	push   $0xf0104114
f0101cf1:	68 6e 43 10 f0       	push   $0xf010436e
f0101cf6:	68 65 03 00 00       	push   $0x365
f0101cfb:	68 48 43 10 f0       	push   $0xf0104348
f0101d00:	e8 86 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d05:	83 ec 08             	sub    $0x8,%esp
f0101d08:	6a 00                	push   $0x0
f0101d0a:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d10:	e8 0d f3 ff ff       	call   f0101022 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d15:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101d1b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d20:	89 f8                	mov    %edi,%eax
f0101d22:	e8 2a ec ff ff       	call   f0100951 <check_va2pa>
f0101d27:	83 c4 10             	add    $0x10,%esp
f0101d2a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d2d:	74 19                	je     f0101d48 <mem_init+0xc73>
f0101d2f:	68 38 41 10 f0       	push   $0xf0104138
f0101d34:	68 6e 43 10 f0       	push   $0xf010436e
f0101d39:	68 69 03 00 00       	push   $0x369
f0101d3e:	68 48 43 10 f0       	push   $0xf0104348
f0101d43:	e8 43 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d48:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d4d:	89 f8                	mov    %edi,%eax
f0101d4f:	e8 fd eb ff ff       	call   f0100951 <check_va2pa>
f0101d54:	89 da                	mov    %ebx,%edx
f0101d56:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101d5c:	c1 fa 03             	sar    $0x3,%edx
f0101d5f:	c1 e2 0c             	shl    $0xc,%edx
f0101d62:	39 d0                	cmp    %edx,%eax
f0101d64:	74 19                	je     f0101d7f <mem_init+0xcaa>
f0101d66:	68 e4 40 10 f0       	push   $0xf01040e4
f0101d6b:	68 6e 43 10 f0       	push   $0xf010436e
f0101d70:	68 6a 03 00 00       	push   $0x36a
f0101d75:	68 48 43 10 f0       	push   $0xf0104348
f0101d7a:	e8 0c e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d7f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d84:	74 19                	je     f0101d9f <mem_init+0xcca>
f0101d86:	68 16 45 10 f0       	push   $0xf0104516
f0101d8b:	68 6e 43 10 f0       	push   $0xf010436e
f0101d90:	68 6b 03 00 00       	push   $0x36b
f0101d95:	68 48 43 10 f0       	push   $0xf0104348
f0101d9a:	e8 ec e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d9f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101da4:	74 19                	je     f0101dbf <mem_init+0xcea>
f0101da6:	68 70 45 10 f0       	push   $0xf0104570
f0101dab:	68 6e 43 10 f0       	push   $0xf010436e
f0101db0:	68 6c 03 00 00       	push   $0x36c
f0101db5:	68 48 43 10 f0       	push   $0xf0104348
f0101dba:	e8 cc e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dbf:	6a 00                	push   $0x0
f0101dc1:	68 00 10 00 00       	push   $0x1000
f0101dc6:	53                   	push   %ebx
f0101dc7:	57                   	push   %edi
f0101dc8:	e8 9f f2 ff ff       	call   f010106c <page_insert>
f0101dcd:	83 c4 10             	add    $0x10,%esp
f0101dd0:	85 c0                	test   %eax,%eax
f0101dd2:	74 19                	je     f0101ded <mem_init+0xd18>
f0101dd4:	68 5c 41 10 f0       	push   $0xf010415c
f0101dd9:	68 6e 43 10 f0       	push   $0xf010436e
f0101dde:	68 6f 03 00 00       	push   $0x36f
f0101de3:	68 48 43 10 f0       	push   $0xf0104348
f0101de8:	e8 9e e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101ded:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df2:	75 19                	jne    f0101e0d <mem_init+0xd38>
f0101df4:	68 81 45 10 f0       	push   $0xf0104581
f0101df9:	68 6e 43 10 f0       	push   $0xf010436e
f0101dfe:	68 70 03 00 00       	push   $0x370
f0101e03:	68 48 43 10 f0       	push   $0xf0104348
f0101e08:	e8 7e e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101e0d:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e10:	74 19                	je     f0101e2b <mem_init+0xd56>
f0101e12:	68 8d 45 10 f0       	push   $0xf010458d
f0101e17:	68 6e 43 10 f0       	push   $0xf010436e
f0101e1c:	68 71 03 00 00       	push   $0x371
f0101e21:	68 48 43 10 f0       	push   $0xf0104348
f0101e26:	e8 60 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e2b:	83 ec 08             	sub    $0x8,%esp
f0101e2e:	68 00 10 00 00       	push   $0x1000
f0101e33:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e39:	e8 e4 f1 ff ff       	call   f0101022 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e3e:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101e44:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e49:	89 f8                	mov    %edi,%eax
f0101e4b:	e8 01 eb ff ff       	call   f0100951 <check_va2pa>
f0101e50:	83 c4 10             	add    $0x10,%esp
f0101e53:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e56:	74 19                	je     f0101e71 <mem_init+0xd9c>
f0101e58:	68 38 41 10 f0       	push   $0xf0104138
f0101e5d:	68 6e 43 10 f0       	push   $0xf010436e
f0101e62:	68 75 03 00 00       	push   $0x375
f0101e67:	68 48 43 10 f0       	push   $0xf0104348
f0101e6c:	e8 1a e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e71:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e76:	89 f8                	mov    %edi,%eax
f0101e78:	e8 d4 ea ff ff       	call   f0100951 <check_va2pa>
f0101e7d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e80:	74 19                	je     f0101e9b <mem_init+0xdc6>
f0101e82:	68 94 41 10 f0       	push   $0xf0104194
f0101e87:	68 6e 43 10 f0       	push   $0xf010436e
f0101e8c:	68 76 03 00 00       	push   $0x376
f0101e91:	68 48 43 10 f0       	push   $0xf0104348
f0101e96:	e8 f0 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e9b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ea0:	74 19                	je     f0101ebb <mem_init+0xde6>
f0101ea2:	68 a2 45 10 f0       	push   $0xf01045a2
f0101ea7:	68 6e 43 10 f0       	push   $0xf010436e
f0101eac:	68 77 03 00 00       	push   $0x377
f0101eb1:	68 48 43 10 f0       	push   $0xf0104348
f0101eb6:	e8 d0 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ebb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ec0:	74 19                	je     f0101edb <mem_init+0xe06>
f0101ec2:	68 70 45 10 f0       	push   $0xf0104570
f0101ec7:	68 6e 43 10 f0       	push   $0xf010436e
f0101ecc:	68 78 03 00 00       	push   $0x378
f0101ed1:	68 48 43 10 f0       	push   $0xf0104348
f0101ed6:	e8 b0 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101edb:	83 ec 0c             	sub    $0xc,%esp
f0101ede:	6a 00                	push   $0x0
f0101ee0:	e8 df ee ff ff       	call   f0100dc4 <page_alloc>
f0101ee5:	83 c4 10             	add    $0x10,%esp
f0101ee8:	85 c0                	test   %eax,%eax
f0101eea:	74 04                	je     f0101ef0 <mem_init+0xe1b>
f0101eec:	39 c3                	cmp    %eax,%ebx
f0101eee:	74 19                	je     f0101f09 <mem_init+0xe34>
f0101ef0:	68 bc 41 10 f0       	push   $0xf01041bc
f0101ef5:	68 6e 43 10 f0       	push   $0xf010436e
f0101efa:	68 7b 03 00 00       	push   $0x37b
f0101eff:	68 48 43 10 f0       	push   $0xf0104348
f0101f04:	e8 82 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f09:	83 ec 0c             	sub    $0xc,%esp
f0101f0c:	6a 00                	push   $0x0
f0101f0e:	e8 b1 ee ff ff       	call   f0100dc4 <page_alloc>
f0101f13:	83 c4 10             	add    $0x10,%esp
f0101f16:	85 c0                	test   %eax,%eax
f0101f18:	74 19                	je     f0101f33 <mem_init+0xe5e>
f0101f1a:	68 c4 44 10 f0       	push   $0xf01044c4
f0101f1f:	68 6e 43 10 f0       	push   $0xf010436e
f0101f24:	68 7e 03 00 00       	push   $0x37e
f0101f29:	68 48 43 10 f0       	push   $0xf0104348
f0101f2e:	e8 58 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f33:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f0101f39:	8b 11                	mov    (%ecx),%edx
f0101f3b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f44:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101f4a:	c1 f8 03             	sar    $0x3,%eax
f0101f4d:	c1 e0 0c             	shl    $0xc,%eax
f0101f50:	39 c2                	cmp    %eax,%edx
f0101f52:	74 19                	je     f0101f6d <mem_init+0xe98>
f0101f54:	68 60 3e 10 f0       	push   $0xf0103e60
f0101f59:	68 6e 43 10 f0       	push   $0xf010436e
f0101f5e:	68 81 03 00 00       	push   $0x381
f0101f63:	68 48 43 10 f0       	push   $0xf0104348
f0101f68:	e8 1e e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f6d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f76:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f7b:	74 19                	je     f0101f96 <mem_init+0xec1>
f0101f7d:	68 27 45 10 f0       	push   $0xf0104527
f0101f82:	68 6e 43 10 f0       	push   $0xf010436e
f0101f87:	68 83 03 00 00       	push   $0x383
f0101f8c:	68 48 43 10 f0       	push   $0xf0104348
f0101f91:	e8 f5 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f96:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f99:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f9f:	83 ec 0c             	sub    $0xc,%esp
f0101fa2:	50                   	push   %eax
f0101fa3:	e8 8c ee ff ff       	call   f0100e34 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fa8:	83 c4 0c             	add    $0xc,%esp
f0101fab:	6a 01                	push   $0x1
f0101fad:	68 00 10 40 00       	push   $0x401000
f0101fb2:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101fb8:	e8 d9 ee ff ff       	call   f0100e96 <pgdir_walk>
f0101fbd:	89 c7                	mov    %eax,%edi
f0101fbf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fc2:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101fc7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fca:	8b 40 04             	mov    0x4(%eax),%eax
f0101fcd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fd2:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0101fd8:	89 c2                	mov    %eax,%edx
f0101fda:	c1 ea 0c             	shr    $0xc,%edx
f0101fdd:	83 c4 10             	add    $0x10,%esp
f0101fe0:	39 ca                	cmp    %ecx,%edx
f0101fe2:	72 15                	jb     f0101ff9 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe4:	50                   	push   %eax
f0101fe5:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101fea:	68 8a 03 00 00       	push   $0x38a
f0101fef:	68 48 43 10 f0       	push   $0xf0104348
f0101ff4:	e8 92 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ff9:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ffe:	39 c7                	cmp    %eax,%edi
f0102000:	74 19                	je     f010201b <mem_init+0xf46>
f0102002:	68 b3 45 10 f0       	push   $0xf01045b3
f0102007:	68 6e 43 10 f0       	push   $0xf010436e
f010200c:	68 8b 03 00 00       	push   $0x38b
f0102011:	68 48 43 10 f0       	push   $0xf0104348
f0102016:	e8 70 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010201b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010201e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102025:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102028:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202e:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0102034:	c1 f8 03             	sar    $0x3,%eax
f0102037:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010203a:	89 c2                	mov    %eax,%edx
f010203c:	c1 ea 0c             	shr    $0xc,%edx
f010203f:	39 d1                	cmp    %edx,%ecx
f0102041:	77 12                	ja     f0102055 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102043:	50                   	push   %eax
f0102044:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0102049:	6a 52                	push   $0x52
f010204b:	68 54 43 10 f0       	push   $0xf0104354
f0102050:	e8 36 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102055:	83 ec 04             	sub    $0x4,%esp
f0102058:	68 00 10 00 00       	push   $0x1000
f010205d:	68 ff 00 00 00       	push   $0xff
f0102062:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102067:	50                   	push   %eax
f0102068:	e8 4a 11 00 00       	call   f01031b7 <memset>
	page_free(pp0);
f010206d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102070:	89 3c 24             	mov    %edi,(%esp)
f0102073:	e8 bc ed ff ff       	call   f0100e34 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102078:	83 c4 0c             	add    $0xc,%esp
f010207b:	6a 01                	push   $0x1
f010207d:	6a 00                	push   $0x0
f010207f:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102085:	e8 0c ee ff ff       	call   f0100e96 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010208a:	89 fa                	mov    %edi,%edx
f010208c:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0102092:	c1 fa 03             	sar    $0x3,%edx
f0102095:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102098:	89 d0                	mov    %edx,%eax
f010209a:	c1 e8 0c             	shr    $0xc,%eax
f010209d:	83 c4 10             	add    $0x10,%esp
f01020a0:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f01020a6:	72 12                	jb     f01020ba <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020a8:	52                   	push   %edx
f01020a9:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01020ae:	6a 52                	push   $0x52
f01020b0:	68 54 43 10 f0       	push   $0xf0104354
f01020b5:	e8 d1 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020ba:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020c3:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020c9:	f6 00 01             	testb  $0x1,(%eax)
f01020cc:	74 19                	je     f01020e7 <mem_init+0x1012>
f01020ce:	68 cb 45 10 f0       	push   $0xf01045cb
f01020d3:	68 6e 43 10 f0       	push   $0xf010436e
f01020d8:	68 95 03 00 00       	push   $0x395
f01020dd:	68 48 43 10 f0       	push   $0xf0104348
f01020e2:	e8 a4 df ff ff       	call   f010008b <_panic>
f01020e7:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020ea:	39 d0                	cmp    %edx,%eax
f01020ec:	75 db                	jne    f01020c9 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020ee:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01020f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020fc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102102:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102105:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010210b:	83 ec 0c             	sub    $0xc,%esp
f010210e:	50                   	push   %eax
f010210f:	e8 20 ed ff ff       	call   f0100e34 <page_free>
	page_free(pp1);
f0102114:	89 1c 24             	mov    %ebx,(%esp)
f0102117:	e8 18 ed ff ff       	call   f0100e34 <page_free>
	page_free(pp2);
f010211c:	89 34 24             	mov    %esi,(%esp)
f010211f:	e8 10 ed ff ff       	call   f0100e34 <page_free>

	cprintf("check_page() succeeded!\n");
f0102124:	c7 04 24 e2 45 10 f0 	movl   $0xf01045e2,(%esp)
f010212b:	e8 ce 05 00 00       	call   f01026fe <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_U));
f0102130:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102135:	83 c4 10             	add    $0x10,%esp
f0102138:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010213d:	77 15                	ja     f0102154 <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010213f:	50                   	push   %eax
f0102140:	68 c8 3b 10 f0       	push   $0xf0103bc8
f0102145:	68 c1 00 00 00       	push   $0xc1
f010214a:	68 48 43 10 f0       	push   $0xf0104348
f010214f:	e8 37 df ff ff       	call   f010008b <_panic>
f0102154:	83 ec 08             	sub    $0x8,%esp
f0102157:	6a 05                	push   $0x5
f0102159:	05 00 00 00 10       	add    $0x10000000,%eax
f010215e:	50                   	push   %eax
f010215f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102164:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102169:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010216e:	e8 f5 ed ff ff       	call   f0100f68 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102173:	83 c4 10             	add    $0x10,%esp
f0102176:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f010217b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102180:	77 15                	ja     f0102197 <mem_init+0x10c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102182:	50                   	push   %eax
f0102183:	68 c8 3b 10 f0       	push   $0xf0103bc8
f0102188:	68 cf 00 00 00       	push   $0xcf
f010218d:	68 48 43 10 f0       	push   $0xf0104348
f0102192:	e8 f4 de ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102197:	83 ec 08             	sub    $0x8,%esp
f010219a:	6a 02                	push   $0x2
f010219c:	68 00 d0 10 00       	push   $0x10d000
f01021a1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021a6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021ab:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021b0:	e8 b3 ed ff ff       	call   f0100f68 <boot_map_region>
	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f01021b5:	83 c4 08             	add    $0x8,%esp
f01021b8:	6a 02                	push   $0x2
f01021ba:	6a 00                	push   $0x0
f01021bc:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021c1:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021c6:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021cb:	e8 98 ed ff ff       	call   f0100f68 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021d0:	8b 35 48 79 11 f0    	mov    0xf0117948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021d6:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f01021db:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021de:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021e5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ed:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021f3:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021f6:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021f9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021fe:	eb 55                	jmp    f0102255 <mem_init+0x1180>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102200:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102206:	89 f0                	mov    %esi,%eax
f0102208:	e8 44 e7 ff ff       	call   f0100951 <check_va2pa>
f010220d:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102214:	77 15                	ja     f010222b <mem_init+0x1156>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102216:	57                   	push   %edi
f0102217:	68 c8 3b 10 f0       	push   $0xf0103bc8
f010221c:	68 d7 02 00 00       	push   $0x2d7
f0102221:	68 48 43 10 f0       	push   $0xf0104348
f0102226:	e8 60 de ff ff       	call   f010008b <_panic>
f010222b:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102232:	39 c2                	cmp    %eax,%edx
f0102234:	74 19                	je     f010224f <mem_init+0x117a>
f0102236:	68 e0 41 10 f0       	push   $0xf01041e0
f010223b:	68 6e 43 10 f0       	push   $0xf010436e
f0102240:	68 d7 02 00 00       	push   $0x2d7
f0102245:	68 48 43 10 f0       	push   $0xf0104348
f010224a:	e8 3c de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010224f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102255:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102258:	77 a6                	ja     f0102200 <mem_init+0x112b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010225a:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010225d:	c1 e7 0c             	shl    $0xc,%edi
f0102260:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102265:	eb 30                	jmp    f0102297 <mem_init+0x11c2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102267:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010226d:	89 f0                	mov    %esi,%eax
f010226f:	e8 dd e6 ff ff       	call   f0100951 <check_va2pa>
f0102274:	39 c3                	cmp    %eax,%ebx
f0102276:	74 19                	je     f0102291 <mem_init+0x11bc>
f0102278:	68 14 42 10 f0       	push   $0xf0104214
f010227d:	68 6e 43 10 f0       	push   $0xf010436e
f0102282:	68 dc 02 00 00       	push   $0x2dc
f0102287:	68 48 43 10 f0       	push   $0xf0104348
f010228c:	e8 fa dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102291:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102297:	39 fb                	cmp    %edi,%ebx
f0102299:	72 cc                	jb     f0102267 <mem_init+0x1192>
f010229b:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022a0:	89 da                	mov    %ebx,%edx
f01022a2:	89 f0                	mov    %esi,%eax
f01022a4:	e8 a8 e6 ff ff       	call   f0100951 <check_va2pa>
f01022a9:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022af:	39 c2                	cmp    %eax,%edx
f01022b1:	74 19                	je     f01022cc <mem_init+0x11f7>
f01022b3:	68 3c 42 10 f0       	push   $0xf010423c
f01022b8:	68 6e 43 10 f0       	push   $0xf010436e
f01022bd:	68 e0 02 00 00       	push   $0x2e0
f01022c2:	68 48 43 10 f0       	push   $0xf0104348
f01022c7:	e8 bf dd ff ff       	call   f010008b <_panic>
f01022cc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022d2:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022d8:	75 c6                	jne    f01022a0 <mem_init+0x11cb>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022da:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022df:	89 f0                	mov    %esi,%eax
f01022e1:	e8 6b e6 ff ff       	call   f0100951 <check_va2pa>
f01022e6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022e9:	74 51                	je     f010233c <mem_init+0x1267>
f01022eb:	68 84 42 10 f0       	push   $0xf0104284
f01022f0:	68 6e 43 10 f0       	push   $0xf010436e
f01022f5:	68 e1 02 00 00       	push   $0x2e1
f01022fa:	68 48 43 10 f0       	push   $0xf0104348
f01022ff:	e8 87 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102304:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102309:	72 36                	jb     f0102341 <mem_init+0x126c>
f010230b:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102310:	76 07                	jbe    f0102319 <mem_init+0x1244>
f0102312:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102317:	75 28                	jne    f0102341 <mem_init+0x126c>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102319:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010231d:	0f 85 83 00 00 00    	jne    f01023a6 <mem_init+0x12d1>
f0102323:	68 fb 45 10 f0       	push   $0xf01045fb
f0102328:	68 6e 43 10 f0       	push   $0xf010436e
f010232d:	68 e9 02 00 00       	push   $0x2e9
f0102332:	68 48 43 10 f0       	push   $0xf0104348
f0102337:	e8 4f dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010233c:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102341:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102346:	76 3f                	jbe    f0102387 <mem_init+0x12b2>
				assert(pgdir[i] & PTE_P);
f0102348:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010234b:	f6 c2 01             	test   $0x1,%dl
f010234e:	75 19                	jne    f0102369 <mem_init+0x1294>
f0102350:	68 fb 45 10 f0       	push   $0xf01045fb
f0102355:	68 6e 43 10 f0       	push   $0xf010436e
f010235a:	68 ed 02 00 00       	push   $0x2ed
f010235f:	68 48 43 10 f0       	push   $0xf0104348
f0102364:	e8 22 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102369:	f6 c2 02             	test   $0x2,%dl
f010236c:	75 38                	jne    f01023a6 <mem_init+0x12d1>
f010236e:	68 0c 46 10 f0       	push   $0xf010460c
f0102373:	68 6e 43 10 f0       	push   $0xf010436e
f0102378:	68 ee 02 00 00       	push   $0x2ee
f010237d:	68 48 43 10 f0       	push   $0xf0104348
f0102382:	e8 04 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102387:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010238b:	74 19                	je     f01023a6 <mem_init+0x12d1>
f010238d:	68 1d 46 10 f0       	push   $0xf010461d
f0102392:	68 6e 43 10 f0       	push   $0xf010436e
f0102397:	68 f0 02 00 00       	push   $0x2f0
f010239c:	68 48 43 10 f0       	push   $0xf0104348
f01023a1:	e8 e5 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023a6:	83 c0 01             	add    $0x1,%eax
f01023a9:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023ae:	0f 86 50 ff ff ff    	jbe    f0102304 <mem_init+0x122f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023b4:	83 ec 0c             	sub    $0xc,%esp
f01023b7:	68 b4 42 10 f0       	push   $0xf01042b4
f01023bc:	e8 3d 03 00 00       	call   f01026fe <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023c1:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023c6:	83 c4 10             	add    $0x10,%esp
f01023c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023ce:	77 15                	ja     f01023e5 <mem_init+0x1310>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023d0:	50                   	push   %eax
f01023d1:	68 c8 3b 10 f0       	push   $0xf0103bc8
f01023d6:	68 e3 00 00 00       	push   $0xe3
f01023db:	68 48 43 10 f0       	push   $0xf0104348
f01023e0:	e8 a6 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023e5:	05 00 00 00 10       	add    $0x10000000,%eax
f01023ea:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01023f2:	e8 3f e6 ff ff       	call   f0100a36 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023f7:	0f 20 c0             	mov    %cr0,%eax
f01023fa:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023fd:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102402:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102405:	83 ec 0c             	sub    $0xc,%esp
f0102408:	6a 00                	push   $0x0
f010240a:	e8 b5 e9 ff ff       	call   f0100dc4 <page_alloc>
f010240f:	89 c7                	mov    %eax,%edi
f0102411:	83 c4 10             	add    $0x10,%esp
f0102414:	85 c0                	test   %eax,%eax
f0102416:	75 19                	jne    f0102431 <mem_init+0x135c>
f0102418:	68 19 44 10 f0       	push   $0xf0104419
f010241d:	68 6e 43 10 f0       	push   $0xf010436e
f0102422:	68 b0 03 00 00       	push   $0x3b0
f0102427:	68 48 43 10 f0       	push   $0xf0104348
f010242c:	e8 5a dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102431:	83 ec 0c             	sub    $0xc,%esp
f0102434:	6a 00                	push   $0x0
f0102436:	e8 89 e9 ff ff       	call   f0100dc4 <page_alloc>
f010243b:	89 c6                	mov    %eax,%esi
f010243d:	83 c4 10             	add    $0x10,%esp
f0102440:	85 c0                	test   %eax,%eax
f0102442:	75 19                	jne    f010245d <mem_init+0x1388>
f0102444:	68 2f 44 10 f0       	push   $0xf010442f
f0102449:	68 6e 43 10 f0       	push   $0xf010436e
f010244e:	68 b1 03 00 00       	push   $0x3b1
f0102453:	68 48 43 10 f0       	push   $0xf0104348
f0102458:	e8 2e dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010245d:	83 ec 0c             	sub    $0xc,%esp
f0102460:	6a 00                	push   $0x0
f0102462:	e8 5d e9 ff ff       	call   f0100dc4 <page_alloc>
f0102467:	89 c3                	mov    %eax,%ebx
f0102469:	83 c4 10             	add    $0x10,%esp
f010246c:	85 c0                	test   %eax,%eax
f010246e:	75 19                	jne    f0102489 <mem_init+0x13b4>
f0102470:	68 45 44 10 f0       	push   $0xf0104445
f0102475:	68 6e 43 10 f0       	push   $0xf010436e
f010247a:	68 b2 03 00 00       	push   $0x3b2
f010247f:	68 48 43 10 f0       	push   $0xf0104348
f0102484:	e8 02 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102489:	83 ec 0c             	sub    $0xc,%esp
f010248c:	57                   	push   %edi
f010248d:	e8 a2 e9 ff ff       	call   f0100e34 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102492:	89 f0                	mov    %esi,%eax
f0102494:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010249a:	c1 f8 03             	sar    $0x3,%eax
f010249d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024a0:	89 c2                	mov    %eax,%edx
f01024a2:	c1 ea 0c             	shr    $0xc,%edx
f01024a5:	83 c4 10             	add    $0x10,%esp
f01024a8:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01024ae:	72 12                	jb     f01024c2 <mem_init+0x13ed>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024b0:	50                   	push   %eax
f01024b1:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01024b6:	6a 52                	push   $0x52
f01024b8:	68 54 43 10 f0       	push   $0xf0104354
f01024bd:	e8 c9 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024c2:	83 ec 04             	sub    $0x4,%esp
f01024c5:	68 00 10 00 00       	push   $0x1000
f01024ca:	6a 01                	push   $0x1
f01024cc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024d1:	50                   	push   %eax
f01024d2:	e8 e0 0c 00 00       	call   f01031b7 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024d7:	89 d8                	mov    %ebx,%eax
f01024d9:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01024df:	c1 f8 03             	sar    $0x3,%eax
f01024e2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024e5:	89 c2                	mov    %eax,%edx
f01024e7:	c1 ea 0c             	shr    $0xc,%edx
f01024ea:	83 c4 10             	add    $0x10,%esp
f01024ed:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01024f3:	72 12                	jb     f0102507 <mem_init+0x1432>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024f5:	50                   	push   %eax
f01024f6:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01024fb:	6a 52                	push   $0x52
f01024fd:	68 54 43 10 f0       	push   $0xf0104354
f0102502:	e8 84 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102507:	83 ec 04             	sub    $0x4,%esp
f010250a:	68 00 10 00 00       	push   $0x1000
f010250f:	6a 02                	push   $0x2
f0102511:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102516:	50                   	push   %eax
f0102517:	e8 9b 0c 00 00       	call   f01031b7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010251c:	6a 02                	push   $0x2
f010251e:	68 00 10 00 00       	push   $0x1000
f0102523:	56                   	push   %esi
f0102524:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010252a:	e8 3d eb ff ff       	call   f010106c <page_insert>
	assert(pp1->pp_ref == 1);
f010252f:	83 c4 20             	add    $0x20,%esp
f0102532:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102537:	74 19                	je     f0102552 <mem_init+0x147d>
f0102539:	68 16 45 10 f0       	push   $0xf0104516
f010253e:	68 6e 43 10 f0       	push   $0xf010436e
f0102543:	68 b7 03 00 00       	push   $0x3b7
f0102548:	68 48 43 10 f0       	push   $0xf0104348
f010254d:	e8 39 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102552:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102559:	01 01 01 
f010255c:	74 19                	je     f0102577 <mem_init+0x14a2>
f010255e:	68 d4 42 10 f0       	push   $0xf01042d4
f0102563:	68 6e 43 10 f0       	push   $0xf010436e
f0102568:	68 b8 03 00 00       	push   $0x3b8
f010256d:	68 48 43 10 f0       	push   $0xf0104348
f0102572:	e8 14 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102577:	6a 02                	push   $0x2
f0102579:	68 00 10 00 00       	push   $0x1000
f010257e:	53                   	push   %ebx
f010257f:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102585:	e8 e2 ea ff ff       	call   f010106c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010258a:	83 c4 10             	add    $0x10,%esp
f010258d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102594:	02 02 02 
f0102597:	74 19                	je     f01025b2 <mem_init+0x14dd>
f0102599:	68 f8 42 10 f0       	push   $0xf01042f8
f010259e:	68 6e 43 10 f0       	push   $0xf010436e
f01025a3:	68 ba 03 00 00       	push   $0x3ba
f01025a8:	68 48 43 10 f0       	push   $0xf0104348
f01025ad:	e8 d9 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025b2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025b7:	74 19                	je     f01025d2 <mem_init+0x14fd>
f01025b9:	68 38 45 10 f0       	push   $0xf0104538
f01025be:	68 6e 43 10 f0       	push   $0xf010436e
f01025c3:	68 bb 03 00 00       	push   $0x3bb
f01025c8:	68 48 43 10 f0       	push   $0xf0104348
f01025cd:	e8 b9 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025d2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025d7:	74 19                	je     f01025f2 <mem_init+0x151d>
f01025d9:	68 a2 45 10 f0       	push   $0xf01045a2
f01025de:	68 6e 43 10 f0       	push   $0xf010436e
f01025e3:	68 bc 03 00 00       	push   $0x3bc
f01025e8:	68 48 43 10 f0       	push   $0xf0104348
f01025ed:	e8 99 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025f2:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025f9:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025fc:	89 d8                	mov    %ebx,%eax
f01025fe:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0102604:	c1 f8 03             	sar    $0x3,%eax
f0102607:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010260a:	89 c2                	mov    %eax,%edx
f010260c:	c1 ea 0c             	shr    $0xc,%edx
f010260f:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0102615:	72 12                	jb     f0102629 <mem_init+0x1554>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102617:	50                   	push   %eax
f0102618:	68 a4 3b 10 f0       	push   $0xf0103ba4
f010261d:	6a 52                	push   $0x52
f010261f:	68 54 43 10 f0       	push   $0xf0104354
f0102624:	e8 62 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102629:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102630:	03 03 03 
f0102633:	74 19                	je     f010264e <mem_init+0x1579>
f0102635:	68 1c 43 10 f0       	push   $0xf010431c
f010263a:	68 6e 43 10 f0       	push   $0xf010436e
f010263f:	68 be 03 00 00       	push   $0x3be
f0102644:	68 48 43 10 f0       	push   $0xf0104348
f0102649:	e8 3d da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010264e:	83 ec 08             	sub    $0x8,%esp
f0102651:	68 00 10 00 00       	push   $0x1000
f0102656:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010265c:	e8 c1 e9 ff ff       	call   f0101022 <page_remove>
	assert(pp2->pp_ref == 0);
f0102661:	83 c4 10             	add    $0x10,%esp
f0102664:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102669:	74 19                	je     f0102684 <mem_init+0x15af>
f010266b:	68 70 45 10 f0       	push   $0xf0104570
f0102670:	68 6e 43 10 f0       	push   $0xf010436e
f0102675:	68 c0 03 00 00       	push   $0x3c0
f010267a:	68 48 43 10 f0       	push   $0xf0104348
f010267f:	e8 07 da ff ff       	call   f010008b <_panic>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102684:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102687:	5b                   	pop    %ebx
f0102688:	5e                   	pop    %esi
f0102689:	5f                   	pop    %edi
f010268a:	5d                   	pop    %ebp
f010268b:	c3                   	ret    

f010268c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010268c:	55                   	push   %ebp
f010268d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010268f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102692:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102695:	5d                   	pop    %ebp
f0102696:	c3                   	ret    

f0102697 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102697:	55                   	push   %ebp
f0102698:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010269a:	ba 70 00 00 00       	mov    $0x70,%edx
f010269f:	8b 45 08             	mov    0x8(%ebp),%eax
f01026a2:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026a3:	ba 71 00 00 00       	mov    $0x71,%edx
f01026a8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026a9:	0f b6 c0             	movzbl %al,%eax
}
f01026ac:	5d                   	pop    %ebp
f01026ad:	c3                   	ret    

f01026ae <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026ae:	55                   	push   %ebp
f01026af:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026b1:	ba 70 00 00 00       	mov    $0x70,%edx
f01026b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01026b9:	ee                   	out    %al,(%dx)
f01026ba:	ba 71 00 00 00       	mov    $0x71,%edx
f01026bf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026c2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026c3:	5d                   	pop    %ebp
f01026c4:	c3                   	ret    

f01026c5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026c5:	55                   	push   %ebp
f01026c6:	89 e5                	mov    %esp,%ebp
f01026c8:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026cb:	ff 75 08             	pushl  0x8(%ebp)
f01026ce:	e8 2d df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01026d3:	83 c4 10             	add    $0x10,%esp
f01026d6:	c9                   	leave  
f01026d7:	c3                   	ret    

f01026d8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026d8:	55                   	push   %ebp
f01026d9:	89 e5                	mov    %esp,%ebp
f01026db:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026de:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026e5:	ff 75 0c             	pushl  0xc(%ebp)
f01026e8:	ff 75 08             	pushl  0x8(%ebp)
f01026eb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026ee:	50                   	push   %eax
f01026ef:	68 c5 26 10 f0       	push   $0xf01026c5
f01026f4:	e8 52 04 00 00       	call   f0102b4b <vprintfmt>
	return cnt;
}
f01026f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026fc:	c9                   	leave  
f01026fd:	c3                   	ret    

f01026fe <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026fe:	55                   	push   %ebp
f01026ff:	89 e5                	mov    %esp,%ebp
f0102701:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102704:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102707:	50                   	push   %eax
f0102708:	ff 75 08             	pushl  0x8(%ebp)
f010270b:	e8 c8 ff ff ff       	call   f01026d8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102710:	c9                   	leave  
f0102711:	c3                   	ret    

f0102712 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102712:	55                   	push   %ebp
f0102713:	89 e5                	mov    %esp,%ebp
f0102715:	57                   	push   %edi
f0102716:	56                   	push   %esi
f0102717:	53                   	push   %ebx
f0102718:	83 ec 14             	sub    $0x14,%esp
f010271b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010271e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102721:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102724:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102727:	8b 1a                	mov    (%edx),%ebx
f0102729:	8b 01                	mov    (%ecx),%eax
f010272b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010272e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102735:	eb 7f                	jmp    f01027b6 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102737:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010273a:	01 d8                	add    %ebx,%eax
f010273c:	89 c6                	mov    %eax,%esi
f010273e:	c1 ee 1f             	shr    $0x1f,%esi
f0102741:	01 c6                	add    %eax,%esi
f0102743:	d1 fe                	sar    %esi
f0102745:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102748:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010274b:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010274e:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102750:	eb 03                	jmp    f0102755 <stab_binsearch+0x43>
			m--;
f0102752:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102755:	39 c3                	cmp    %eax,%ebx
f0102757:	7f 0d                	jg     f0102766 <stab_binsearch+0x54>
f0102759:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010275d:	83 ea 0c             	sub    $0xc,%edx
f0102760:	39 f9                	cmp    %edi,%ecx
f0102762:	75 ee                	jne    f0102752 <stab_binsearch+0x40>
f0102764:	eb 05                	jmp    f010276b <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102766:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102769:	eb 4b                	jmp    f01027b6 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010276b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010276e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102771:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102775:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102778:	76 11                	jbe    f010278b <stab_binsearch+0x79>
			*region_left = m;
f010277a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010277d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010277f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102782:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102789:	eb 2b                	jmp    f01027b6 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010278b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010278e:	73 14                	jae    f01027a4 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102790:	83 e8 01             	sub    $0x1,%eax
f0102793:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102796:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102799:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010279b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027a2:	eb 12                	jmp    f01027b6 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027a7:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027a9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027ad:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027af:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027b6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027b9:	0f 8e 78 ff ff ff    	jle    f0102737 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027bf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027c3:	75 0f                	jne    f01027d4 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027c8:	8b 00                	mov    (%eax),%eax
f01027ca:	83 e8 01             	sub    $0x1,%eax
f01027cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027d0:	89 06                	mov    %eax,(%esi)
f01027d2:	eb 2c                	jmp    f0102800 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027d7:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027d9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027dc:	8b 0e                	mov    (%esi),%ecx
f01027de:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027e1:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027e4:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027e7:	eb 03                	jmp    f01027ec <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027e9:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027ec:	39 c8                	cmp    %ecx,%eax
f01027ee:	7e 0b                	jle    f01027fb <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027f0:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027f4:	83 ea 0c             	sub    $0xc,%edx
f01027f7:	39 df                	cmp    %ebx,%edi
f01027f9:	75 ee                	jne    f01027e9 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027fb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027fe:	89 06                	mov    %eax,(%esi)
	}
}
f0102800:	83 c4 14             	add    $0x14,%esp
f0102803:	5b                   	pop    %ebx
f0102804:	5e                   	pop    %esi
f0102805:	5f                   	pop    %edi
f0102806:	5d                   	pop    %ebp
f0102807:	c3                   	ret    

f0102808 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102808:	55                   	push   %ebp
f0102809:	89 e5                	mov    %esp,%ebp
f010280b:	57                   	push   %edi
f010280c:	56                   	push   %esi
f010280d:	53                   	push   %ebx
f010280e:	83 ec 3c             	sub    $0x3c,%esp
f0102811:	8b 75 08             	mov    0x8(%ebp),%esi
f0102814:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102817:	c7 03 2b 46 10 f0    	movl   $0xf010462b,(%ebx)
	info->eip_line = 0;
f010281d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102824:	c7 43 08 2b 46 10 f0 	movl   $0xf010462b,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010282b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102832:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102835:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010283c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102842:	76 11                	jbe    f0102855 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102844:	b8 88 c0 10 f0       	mov    $0xf010c088,%eax
f0102849:	3d 85 a2 10 f0       	cmp    $0xf010a285,%eax
f010284e:	77 19                	ja     f0102869 <debuginfo_eip+0x61>
f0102850:	e9 aa 01 00 00       	jmp    f01029ff <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102855:	83 ec 04             	sub    $0x4,%esp
f0102858:	68 35 46 10 f0       	push   $0xf0104635
f010285d:	6a 7f                	push   $0x7f
f010285f:	68 42 46 10 f0       	push   $0xf0104642
f0102864:	e8 22 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102869:	80 3d 87 c0 10 f0 00 	cmpb   $0x0,0xf010c087
f0102870:	0f 85 90 01 00 00    	jne    f0102a06 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102876:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010287d:	b8 84 a2 10 f0       	mov    $0xf010a284,%eax
f0102882:	2d 60 48 10 f0       	sub    $0xf0104860,%eax
f0102887:	c1 f8 02             	sar    $0x2,%eax
f010288a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102890:	83 e8 01             	sub    $0x1,%eax
f0102893:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102896:	83 ec 08             	sub    $0x8,%esp
f0102899:	56                   	push   %esi
f010289a:	6a 64                	push   $0x64
f010289c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010289f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028a2:	b8 60 48 10 f0       	mov    $0xf0104860,%eax
f01028a7:	e8 66 fe ff ff       	call   f0102712 <stab_binsearch>
	if (lfile == 0)
f01028ac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028af:	83 c4 10             	add    $0x10,%esp
f01028b2:	85 c0                	test   %eax,%eax
f01028b4:	0f 84 53 01 00 00    	je     f0102a0d <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028ba:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028c0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028c3:	83 ec 08             	sub    $0x8,%esp
f01028c6:	56                   	push   %esi
f01028c7:	6a 24                	push   $0x24
f01028c9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028cc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028cf:	b8 60 48 10 f0       	mov    $0xf0104860,%eax
f01028d4:	e8 39 fe ff ff       	call   f0102712 <stab_binsearch>

	if (lfun <= rfun) {
f01028d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028dc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028df:	83 c4 10             	add    $0x10,%esp
f01028e2:	39 d0                	cmp    %edx,%eax
f01028e4:	7f 40                	jg     f0102926 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028e6:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028e9:	c1 e1 02             	shl    $0x2,%ecx
f01028ec:	8d b9 60 48 10 f0    	lea    -0xfefb7a0(%ecx),%edi
f01028f2:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028f5:	8b b9 60 48 10 f0    	mov    -0xfefb7a0(%ecx),%edi
f01028fb:	b9 88 c0 10 f0       	mov    $0xf010c088,%ecx
f0102900:	81 e9 85 a2 10 f0    	sub    $0xf010a285,%ecx
f0102906:	39 cf                	cmp    %ecx,%edi
f0102908:	73 09                	jae    f0102913 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010290a:	81 c7 85 a2 10 f0    	add    $0xf010a285,%edi
f0102910:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102913:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102916:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102919:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010291c:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010291e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102921:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102924:	eb 0f                	jmp    f0102935 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102926:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102929:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010292c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010292f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102932:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102935:	83 ec 08             	sub    $0x8,%esp
f0102938:	6a 3a                	push   $0x3a
f010293a:	ff 73 08             	pushl  0x8(%ebx)
f010293d:	e8 59 08 00 00       	call   f010319b <strfind>
f0102942:	2b 43 08             	sub    0x8(%ebx),%eax
f0102945:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102948:	83 c4 08             	add    $0x8,%esp
f010294b:	56                   	push   %esi
f010294c:	6a 44                	push   $0x44
f010294e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102951:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102954:	b8 60 48 10 f0       	mov    $0xf0104860,%eax
f0102959:	e8 b4 fd ff ff       	call   f0102712 <stab_binsearch>
	
	if(lline > rline)
f010295e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102961:	83 c4 10             	add    $0x10,%esp
f0102964:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0102967:	0f 8f a7 00 00 00    	jg     f0102a14 <debuginfo_eip+0x20c>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f010296d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102970:	8d 04 85 60 48 10 f0 	lea    -0xfefb7a0(,%eax,4),%eax
f0102977:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f010297b:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010297e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102981:	eb 06                	jmp    f0102989 <debuginfo_eip+0x181>
f0102983:	83 ea 01             	sub    $0x1,%edx
f0102986:	83 e8 0c             	sub    $0xc,%eax
f0102989:	39 d6                	cmp    %edx,%esi
f010298b:	7f 34                	jg     f01029c1 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f010298d:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102991:	80 f9 84             	cmp    $0x84,%cl
f0102994:	74 0b                	je     f01029a1 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102996:	80 f9 64             	cmp    $0x64,%cl
f0102999:	75 e8                	jne    f0102983 <debuginfo_eip+0x17b>
f010299b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010299f:	74 e2                	je     f0102983 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029a1:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029a4:	8b 14 85 60 48 10 f0 	mov    -0xfefb7a0(,%eax,4),%edx
f01029ab:	b8 88 c0 10 f0       	mov    $0xf010c088,%eax
f01029b0:	2d 85 a2 10 f0       	sub    $0xf010a285,%eax
f01029b5:	39 c2                	cmp    %eax,%edx
f01029b7:	73 08                	jae    f01029c1 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029b9:	81 c2 85 a2 10 f0    	add    $0xf010a285,%edx
f01029bf:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029c1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029c4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029c7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029cc:	39 f2                	cmp    %esi,%edx
f01029ce:	7d 50                	jge    f0102a20 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f01029d0:	83 c2 01             	add    $0x1,%edx
f01029d3:	89 d0                	mov    %edx,%eax
f01029d5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029d8:	8d 14 95 60 48 10 f0 	lea    -0xfefb7a0(,%edx,4),%edx
f01029df:	eb 04                	jmp    f01029e5 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029e1:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029e5:	39 c6                	cmp    %eax,%esi
f01029e7:	7e 32                	jle    f0102a1b <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029e9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029ed:	83 c0 01             	add    $0x1,%eax
f01029f0:	83 c2 0c             	add    $0xc,%edx
f01029f3:	80 f9 a0             	cmp    $0xa0,%cl
f01029f6:	74 e9                	je     f01029e1 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029fd:	eb 21                	jmp    f0102a20 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a04:	eb 1a                	jmp    f0102a20 <debuginfo_eip+0x218>
f0102a06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a0b:	eb 13                	jmp    f0102a20 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a12:	eb 0c                	jmp    f0102a20 <debuginfo_eip+0x218>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f0102a14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a19:	eb 05                	jmp    f0102a20 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a23:	5b                   	pop    %ebx
f0102a24:	5e                   	pop    %esi
f0102a25:	5f                   	pop    %edi
f0102a26:	5d                   	pop    %ebp
f0102a27:	c3                   	ret    

f0102a28 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a28:	55                   	push   %ebp
f0102a29:	89 e5                	mov    %esp,%ebp
f0102a2b:	57                   	push   %edi
f0102a2c:	56                   	push   %esi
f0102a2d:	53                   	push   %ebx
f0102a2e:	83 ec 1c             	sub    $0x1c,%esp
f0102a31:	89 c7                	mov    %eax,%edi
f0102a33:	89 d6                	mov    %edx,%esi
f0102a35:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a38:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a3b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a3e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a41:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a44:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a49:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a4c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a4f:	39 d3                	cmp    %edx,%ebx
f0102a51:	72 05                	jb     f0102a58 <printnum+0x30>
f0102a53:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a56:	77 45                	ja     f0102a9d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a58:	83 ec 0c             	sub    $0xc,%esp
f0102a5b:	ff 75 18             	pushl  0x18(%ebp)
f0102a5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a61:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a64:	53                   	push   %ebx
f0102a65:	ff 75 10             	pushl  0x10(%ebp)
f0102a68:	83 ec 08             	sub    $0x8,%esp
f0102a6b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a6e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a71:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a74:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a77:	e8 44 09 00 00       	call   f01033c0 <__udivdi3>
f0102a7c:	83 c4 18             	add    $0x18,%esp
f0102a7f:	52                   	push   %edx
f0102a80:	50                   	push   %eax
f0102a81:	89 f2                	mov    %esi,%edx
f0102a83:	89 f8                	mov    %edi,%eax
f0102a85:	e8 9e ff ff ff       	call   f0102a28 <printnum>
f0102a8a:	83 c4 20             	add    $0x20,%esp
f0102a8d:	eb 18                	jmp    f0102aa7 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a8f:	83 ec 08             	sub    $0x8,%esp
f0102a92:	56                   	push   %esi
f0102a93:	ff 75 18             	pushl  0x18(%ebp)
f0102a96:	ff d7                	call   *%edi
f0102a98:	83 c4 10             	add    $0x10,%esp
f0102a9b:	eb 03                	jmp    f0102aa0 <printnum+0x78>
f0102a9d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102aa0:	83 eb 01             	sub    $0x1,%ebx
f0102aa3:	85 db                	test   %ebx,%ebx
f0102aa5:	7f e8                	jg     f0102a8f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102aa7:	83 ec 08             	sub    $0x8,%esp
f0102aaa:	56                   	push   %esi
f0102aab:	83 ec 04             	sub    $0x4,%esp
f0102aae:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ab1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ab4:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ab7:	ff 75 d8             	pushl  -0x28(%ebp)
f0102aba:	e8 31 0a 00 00       	call   f01034f0 <__umoddi3>
f0102abf:	83 c4 14             	add    $0x14,%esp
f0102ac2:	0f be 80 50 46 10 f0 	movsbl -0xfefb9b0(%eax),%eax
f0102ac9:	50                   	push   %eax
f0102aca:	ff d7                	call   *%edi
}
f0102acc:	83 c4 10             	add    $0x10,%esp
f0102acf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ad2:	5b                   	pop    %ebx
f0102ad3:	5e                   	pop    %esi
f0102ad4:	5f                   	pop    %edi
f0102ad5:	5d                   	pop    %ebp
f0102ad6:	c3                   	ret    

f0102ad7 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102ad7:	55                   	push   %ebp
f0102ad8:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ada:	83 fa 01             	cmp    $0x1,%edx
f0102add:	7e 0e                	jle    f0102aed <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102adf:	8b 10                	mov    (%eax),%edx
f0102ae1:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ae4:	89 08                	mov    %ecx,(%eax)
f0102ae6:	8b 02                	mov    (%edx),%eax
f0102ae8:	8b 52 04             	mov    0x4(%edx),%edx
f0102aeb:	eb 22                	jmp    f0102b0f <getuint+0x38>
	else if (lflag)
f0102aed:	85 d2                	test   %edx,%edx
f0102aef:	74 10                	je     f0102b01 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102af1:	8b 10                	mov    (%eax),%edx
f0102af3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102af6:	89 08                	mov    %ecx,(%eax)
f0102af8:	8b 02                	mov    (%edx),%eax
f0102afa:	ba 00 00 00 00       	mov    $0x0,%edx
f0102aff:	eb 0e                	jmp    f0102b0f <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b01:	8b 10                	mov    (%eax),%edx
f0102b03:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b06:	89 08                	mov    %ecx,(%eax)
f0102b08:	8b 02                	mov    (%edx),%eax
f0102b0a:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b0f:	5d                   	pop    %ebp
f0102b10:	c3                   	ret    

f0102b11 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b11:	55                   	push   %ebp
f0102b12:	89 e5                	mov    %esp,%ebp
f0102b14:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b17:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b1b:	8b 10                	mov    (%eax),%edx
f0102b1d:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b20:	73 0a                	jae    f0102b2c <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b22:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b25:	89 08                	mov    %ecx,(%eax)
f0102b27:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b2a:	88 02                	mov    %al,(%edx)
}
f0102b2c:	5d                   	pop    %ebp
f0102b2d:	c3                   	ret    

f0102b2e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b2e:	55                   	push   %ebp
f0102b2f:	89 e5                	mov    %esp,%ebp
f0102b31:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b34:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b37:	50                   	push   %eax
f0102b38:	ff 75 10             	pushl  0x10(%ebp)
f0102b3b:	ff 75 0c             	pushl  0xc(%ebp)
f0102b3e:	ff 75 08             	pushl  0x8(%ebp)
f0102b41:	e8 05 00 00 00       	call   f0102b4b <vprintfmt>
	va_end(ap);
}
f0102b46:	83 c4 10             	add    $0x10,%esp
f0102b49:	c9                   	leave  
f0102b4a:	c3                   	ret    

f0102b4b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b4b:	55                   	push   %ebp
f0102b4c:	89 e5                	mov    %esp,%ebp
f0102b4e:	57                   	push   %edi
f0102b4f:	56                   	push   %esi
f0102b50:	53                   	push   %ebx
f0102b51:	83 ec 2c             	sub    $0x2c,%esp
f0102b54:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b5a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b5d:	eb 12                	jmp    f0102b71 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b5f:	85 c0                	test   %eax,%eax
f0102b61:	0f 84 89 03 00 00    	je     f0102ef0 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b67:	83 ec 08             	sub    $0x8,%esp
f0102b6a:	53                   	push   %ebx
f0102b6b:	50                   	push   %eax
f0102b6c:	ff d6                	call   *%esi
f0102b6e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b71:	83 c7 01             	add    $0x1,%edi
f0102b74:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b78:	83 f8 25             	cmp    $0x25,%eax
f0102b7b:	75 e2                	jne    f0102b5f <vprintfmt+0x14>
f0102b7d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b81:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b88:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b8f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b96:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b9b:	eb 07                	jmp    f0102ba4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ba0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba4:	8d 47 01             	lea    0x1(%edi),%eax
f0102ba7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102baa:	0f b6 07             	movzbl (%edi),%eax
f0102bad:	0f b6 c8             	movzbl %al,%ecx
f0102bb0:	83 e8 23             	sub    $0x23,%eax
f0102bb3:	3c 55                	cmp    $0x55,%al
f0102bb5:	0f 87 1a 03 00 00    	ja     f0102ed5 <vprintfmt+0x38a>
f0102bbb:	0f b6 c0             	movzbl %al,%eax
f0102bbe:	ff 24 85 dc 46 10 f0 	jmp    *-0xfefb924(,%eax,4)
f0102bc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bc8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bcc:	eb d6                	jmp    f0102ba4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bd1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bd6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bd9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bdc:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102be0:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102be3:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102be6:	83 fa 09             	cmp    $0x9,%edx
f0102be9:	77 39                	ja     f0102c24 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102beb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bee:	eb e9                	jmp    f0102bd9 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bf0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bf3:	8d 48 04             	lea    0x4(%eax),%ecx
f0102bf6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102bf9:	8b 00                	mov    (%eax),%eax
f0102bfb:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bfe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c01:	eb 27                	jmp    f0102c2a <vprintfmt+0xdf>
f0102c03:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c06:	85 c0                	test   %eax,%eax
f0102c08:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c0d:	0f 49 c8             	cmovns %eax,%ecx
f0102c10:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c16:	eb 8c                	jmp    f0102ba4 <vprintfmt+0x59>
f0102c18:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c1b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c22:	eb 80                	jmp    f0102ba4 <vprintfmt+0x59>
f0102c24:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c27:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c2a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c2e:	0f 89 70 ff ff ff    	jns    f0102ba4 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c34:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c37:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c3a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c41:	e9 5e ff ff ff       	jmp    f0102ba4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c46:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c4c:	e9 53 ff ff ff       	jmp    f0102ba4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c51:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c54:	8d 50 04             	lea    0x4(%eax),%edx
f0102c57:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c5a:	83 ec 08             	sub    $0x8,%esp
f0102c5d:	53                   	push   %ebx
f0102c5e:	ff 30                	pushl  (%eax)
f0102c60:	ff d6                	call   *%esi
			break;
f0102c62:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c68:	e9 04 ff ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c70:	8d 50 04             	lea    0x4(%eax),%edx
f0102c73:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c76:	8b 00                	mov    (%eax),%eax
f0102c78:	99                   	cltd   
f0102c79:	31 d0                	xor    %edx,%eax
f0102c7b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c7d:	83 f8 06             	cmp    $0x6,%eax
f0102c80:	7f 0b                	jg     f0102c8d <vprintfmt+0x142>
f0102c82:	8b 14 85 34 48 10 f0 	mov    -0xfefb7cc(,%eax,4),%edx
f0102c89:	85 d2                	test   %edx,%edx
f0102c8b:	75 18                	jne    f0102ca5 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c8d:	50                   	push   %eax
f0102c8e:	68 68 46 10 f0       	push   $0xf0104668
f0102c93:	53                   	push   %ebx
f0102c94:	56                   	push   %esi
f0102c95:	e8 94 fe ff ff       	call   f0102b2e <printfmt>
f0102c9a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102ca0:	e9 cc fe ff ff       	jmp    f0102b71 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102ca5:	52                   	push   %edx
f0102ca6:	68 80 43 10 f0       	push   $0xf0104380
f0102cab:	53                   	push   %ebx
f0102cac:	56                   	push   %esi
f0102cad:	e8 7c fe ff ff       	call   f0102b2e <printfmt>
f0102cb2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cb8:	e9 b4 fe ff ff       	jmp    f0102b71 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc0:	8d 50 04             	lea    0x4(%eax),%edx
f0102cc3:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cc6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cc8:	85 ff                	test   %edi,%edi
f0102cca:	b8 61 46 10 f0       	mov    $0xf0104661,%eax
f0102ccf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cd2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cd6:	0f 8e 94 00 00 00    	jle    f0102d70 <vprintfmt+0x225>
f0102cdc:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102ce0:	0f 84 98 00 00 00    	je     f0102d7e <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ce6:	83 ec 08             	sub    $0x8,%esp
f0102ce9:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cec:	57                   	push   %edi
f0102ced:	e8 5f 03 00 00       	call   f0103051 <strnlen>
f0102cf2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cf5:	29 c1                	sub    %eax,%ecx
f0102cf7:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102cfa:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cfd:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d01:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d04:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d07:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d09:	eb 0f                	jmp    f0102d1a <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d0b:	83 ec 08             	sub    $0x8,%esp
f0102d0e:	53                   	push   %ebx
f0102d0f:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d12:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d14:	83 ef 01             	sub    $0x1,%edi
f0102d17:	83 c4 10             	add    $0x10,%esp
f0102d1a:	85 ff                	test   %edi,%edi
f0102d1c:	7f ed                	jg     f0102d0b <vprintfmt+0x1c0>
f0102d1e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d21:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d24:	85 c9                	test   %ecx,%ecx
f0102d26:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d2b:	0f 49 c1             	cmovns %ecx,%eax
f0102d2e:	29 c1                	sub    %eax,%ecx
f0102d30:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d33:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d36:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d39:	89 cb                	mov    %ecx,%ebx
f0102d3b:	eb 4d                	jmp    f0102d8a <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d3d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d41:	74 1b                	je     f0102d5e <vprintfmt+0x213>
f0102d43:	0f be c0             	movsbl %al,%eax
f0102d46:	83 e8 20             	sub    $0x20,%eax
f0102d49:	83 f8 5e             	cmp    $0x5e,%eax
f0102d4c:	76 10                	jbe    f0102d5e <vprintfmt+0x213>
					putch('?', putdat);
f0102d4e:	83 ec 08             	sub    $0x8,%esp
f0102d51:	ff 75 0c             	pushl  0xc(%ebp)
f0102d54:	6a 3f                	push   $0x3f
f0102d56:	ff 55 08             	call   *0x8(%ebp)
f0102d59:	83 c4 10             	add    $0x10,%esp
f0102d5c:	eb 0d                	jmp    f0102d6b <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d5e:	83 ec 08             	sub    $0x8,%esp
f0102d61:	ff 75 0c             	pushl  0xc(%ebp)
f0102d64:	52                   	push   %edx
f0102d65:	ff 55 08             	call   *0x8(%ebp)
f0102d68:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d6b:	83 eb 01             	sub    $0x1,%ebx
f0102d6e:	eb 1a                	jmp    f0102d8a <vprintfmt+0x23f>
f0102d70:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d73:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d76:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d79:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d7c:	eb 0c                	jmp    f0102d8a <vprintfmt+0x23f>
f0102d7e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d81:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d84:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d87:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d8a:	83 c7 01             	add    $0x1,%edi
f0102d8d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d91:	0f be d0             	movsbl %al,%edx
f0102d94:	85 d2                	test   %edx,%edx
f0102d96:	74 23                	je     f0102dbb <vprintfmt+0x270>
f0102d98:	85 f6                	test   %esi,%esi
f0102d9a:	78 a1                	js     f0102d3d <vprintfmt+0x1f2>
f0102d9c:	83 ee 01             	sub    $0x1,%esi
f0102d9f:	79 9c                	jns    f0102d3d <vprintfmt+0x1f2>
f0102da1:	89 df                	mov    %ebx,%edi
f0102da3:	8b 75 08             	mov    0x8(%ebp),%esi
f0102da6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102da9:	eb 18                	jmp    f0102dc3 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102dab:	83 ec 08             	sub    $0x8,%esp
f0102dae:	53                   	push   %ebx
f0102daf:	6a 20                	push   $0x20
f0102db1:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102db3:	83 ef 01             	sub    $0x1,%edi
f0102db6:	83 c4 10             	add    $0x10,%esp
f0102db9:	eb 08                	jmp    f0102dc3 <vprintfmt+0x278>
f0102dbb:	89 df                	mov    %ebx,%edi
f0102dbd:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dc0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dc3:	85 ff                	test   %edi,%edi
f0102dc5:	7f e4                	jg     f0102dab <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dca:	e9 a2 fd ff ff       	jmp    f0102b71 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dcf:	83 fa 01             	cmp    $0x1,%edx
f0102dd2:	7e 16                	jle    f0102dea <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102dd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd7:	8d 50 08             	lea    0x8(%eax),%edx
f0102dda:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ddd:	8b 50 04             	mov    0x4(%eax),%edx
f0102de0:	8b 00                	mov    (%eax),%eax
f0102de2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102de5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102de8:	eb 32                	jmp    f0102e1c <vprintfmt+0x2d1>
	else if (lflag)
f0102dea:	85 d2                	test   %edx,%edx
f0102dec:	74 18                	je     f0102e06 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102dee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df1:	8d 50 04             	lea    0x4(%eax),%edx
f0102df4:	89 55 14             	mov    %edx,0x14(%ebp)
f0102df7:	8b 00                	mov    (%eax),%eax
f0102df9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dfc:	89 c1                	mov    %eax,%ecx
f0102dfe:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e01:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e04:	eb 16                	jmp    f0102e1c <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e06:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e09:	8d 50 04             	lea    0x4(%eax),%edx
f0102e0c:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e0f:	8b 00                	mov    (%eax),%eax
f0102e11:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e14:	89 c1                	mov    %eax,%ecx
f0102e16:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e19:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e1c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e1f:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e22:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e27:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e2b:	79 74                	jns    f0102ea1 <vprintfmt+0x356>
				putch('-', putdat);
f0102e2d:	83 ec 08             	sub    $0x8,%esp
f0102e30:	53                   	push   %ebx
f0102e31:	6a 2d                	push   $0x2d
f0102e33:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e35:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e38:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e3b:	f7 d8                	neg    %eax
f0102e3d:	83 d2 00             	adc    $0x0,%edx
f0102e40:	f7 da                	neg    %edx
f0102e42:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e45:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e4a:	eb 55                	jmp    f0102ea1 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e4c:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e4f:	e8 83 fc ff ff       	call   f0102ad7 <getuint>
			base = 10;
f0102e54:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e59:	eb 46                	jmp    f0102ea1 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102e5b:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e5e:	e8 74 fc ff ff       	call   f0102ad7 <getuint>
			base = 8;
f0102e63:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e68:	eb 37                	jmp    f0102ea1 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e6a:	83 ec 08             	sub    $0x8,%esp
f0102e6d:	53                   	push   %ebx
f0102e6e:	6a 30                	push   $0x30
f0102e70:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e72:	83 c4 08             	add    $0x8,%esp
f0102e75:	53                   	push   %ebx
f0102e76:	6a 78                	push   $0x78
f0102e78:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e7d:	8d 50 04             	lea    0x4(%eax),%edx
f0102e80:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e83:	8b 00                	mov    (%eax),%eax
f0102e85:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e8a:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e8d:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e92:	eb 0d                	jmp    f0102ea1 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e94:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e97:	e8 3b fc ff ff       	call   f0102ad7 <getuint>
			base = 16;
f0102e9c:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102ea1:	83 ec 0c             	sub    $0xc,%esp
f0102ea4:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ea8:	57                   	push   %edi
f0102ea9:	ff 75 e0             	pushl  -0x20(%ebp)
f0102eac:	51                   	push   %ecx
f0102ead:	52                   	push   %edx
f0102eae:	50                   	push   %eax
f0102eaf:	89 da                	mov    %ebx,%edx
f0102eb1:	89 f0                	mov    %esi,%eax
f0102eb3:	e8 70 fb ff ff       	call   f0102a28 <printnum>
			break;
f0102eb8:	83 c4 20             	add    $0x20,%esp
f0102ebb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ebe:	e9 ae fc ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102ec3:	83 ec 08             	sub    $0x8,%esp
f0102ec6:	53                   	push   %ebx
f0102ec7:	51                   	push   %ecx
f0102ec8:	ff d6                	call   *%esi
			break;
f0102eca:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ecd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ed0:	e9 9c fc ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102ed5:	83 ec 08             	sub    $0x8,%esp
f0102ed8:	53                   	push   %ebx
f0102ed9:	6a 25                	push   $0x25
f0102edb:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102edd:	83 c4 10             	add    $0x10,%esp
f0102ee0:	eb 03                	jmp    f0102ee5 <vprintfmt+0x39a>
f0102ee2:	83 ef 01             	sub    $0x1,%edi
f0102ee5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ee9:	75 f7                	jne    f0102ee2 <vprintfmt+0x397>
f0102eeb:	e9 81 fc ff ff       	jmp    f0102b71 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ef0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ef3:	5b                   	pop    %ebx
f0102ef4:	5e                   	pop    %esi
f0102ef5:	5f                   	pop    %edi
f0102ef6:	5d                   	pop    %ebp
f0102ef7:	c3                   	ret    

f0102ef8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102ef8:	55                   	push   %ebp
f0102ef9:	89 e5                	mov    %esp,%ebp
f0102efb:	83 ec 18             	sub    $0x18,%esp
f0102efe:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f01:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f04:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f07:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f0b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f0e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f15:	85 c0                	test   %eax,%eax
f0102f17:	74 26                	je     f0102f3f <vsnprintf+0x47>
f0102f19:	85 d2                	test   %edx,%edx
f0102f1b:	7e 22                	jle    f0102f3f <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f1d:	ff 75 14             	pushl  0x14(%ebp)
f0102f20:	ff 75 10             	pushl  0x10(%ebp)
f0102f23:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f26:	50                   	push   %eax
f0102f27:	68 11 2b 10 f0       	push   $0xf0102b11
f0102f2c:	e8 1a fc ff ff       	call   f0102b4b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f31:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f34:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f3a:	83 c4 10             	add    $0x10,%esp
f0102f3d:	eb 05                	jmp    f0102f44 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f3f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f44:	c9                   	leave  
f0102f45:	c3                   	ret    

f0102f46 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f46:	55                   	push   %ebp
f0102f47:	89 e5                	mov    %esp,%ebp
f0102f49:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f4c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f4f:	50                   	push   %eax
f0102f50:	ff 75 10             	pushl  0x10(%ebp)
f0102f53:	ff 75 0c             	pushl  0xc(%ebp)
f0102f56:	ff 75 08             	pushl  0x8(%ebp)
f0102f59:	e8 9a ff ff ff       	call   f0102ef8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f5e:	c9                   	leave  
f0102f5f:	c3                   	ret    

f0102f60 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f60:	55                   	push   %ebp
f0102f61:	89 e5                	mov    %esp,%ebp
f0102f63:	57                   	push   %edi
f0102f64:	56                   	push   %esi
f0102f65:	53                   	push   %ebx
f0102f66:	83 ec 0c             	sub    $0xc,%esp
f0102f69:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f6c:	85 c0                	test   %eax,%eax
f0102f6e:	74 11                	je     f0102f81 <readline+0x21>
		cprintf("%s", prompt);
f0102f70:	83 ec 08             	sub    $0x8,%esp
f0102f73:	50                   	push   %eax
f0102f74:	68 80 43 10 f0       	push   $0xf0104380
f0102f79:	e8 80 f7 ff ff       	call   f01026fe <cprintf>
f0102f7e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f81:	83 ec 0c             	sub    $0xc,%esp
f0102f84:	6a 00                	push   $0x0
f0102f86:	e8 96 d6 ff ff       	call   f0100621 <iscons>
f0102f8b:	89 c7                	mov    %eax,%edi
f0102f8d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f90:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f95:	e8 76 d6 ff ff       	call   f0100610 <getchar>
f0102f9a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f9c:	85 c0                	test   %eax,%eax
f0102f9e:	79 18                	jns    f0102fb8 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fa0:	83 ec 08             	sub    $0x8,%esp
f0102fa3:	50                   	push   %eax
f0102fa4:	68 50 48 10 f0       	push   $0xf0104850
f0102fa9:	e8 50 f7 ff ff       	call   f01026fe <cprintf>
			return NULL;
f0102fae:	83 c4 10             	add    $0x10,%esp
f0102fb1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fb6:	eb 79                	jmp    f0103031 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fb8:	83 f8 08             	cmp    $0x8,%eax
f0102fbb:	0f 94 c2             	sete   %dl
f0102fbe:	83 f8 7f             	cmp    $0x7f,%eax
f0102fc1:	0f 94 c0             	sete   %al
f0102fc4:	08 c2                	or     %al,%dl
f0102fc6:	74 1a                	je     f0102fe2 <readline+0x82>
f0102fc8:	85 f6                	test   %esi,%esi
f0102fca:	7e 16                	jle    f0102fe2 <readline+0x82>
			if (echoing)
f0102fcc:	85 ff                	test   %edi,%edi
f0102fce:	74 0d                	je     f0102fdd <readline+0x7d>
				cputchar('\b');
f0102fd0:	83 ec 0c             	sub    $0xc,%esp
f0102fd3:	6a 08                	push   $0x8
f0102fd5:	e8 26 d6 ff ff       	call   f0100600 <cputchar>
f0102fda:	83 c4 10             	add    $0x10,%esp
			i--;
f0102fdd:	83 ee 01             	sub    $0x1,%esi
f0102fe0:	eb b3                	jmp    f0102f95 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102fe2:	83 fb 1f             	cmp    $0x1f,%ebx
f0102fe5:	7e 23                	jle    f010300a <readline+0xaa>
f0102fe7:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102fed:	7f 1b                	jg     f010300a <readline+0xaa>
			if (echoing)
f0102fef:	85 ff                	test   %edi,%edi
f0102ff1:	74 0c                	je     f0102fff <readline+0x9f>
				cputchar(c);
f0102ff3:	83 ec 0c             	sub    $0xc,%esp
f0102ff6:	53                   	push   %ebx
f0102ff7:	e8 04 d6 ff ff       	call   f0100600 <cputchar>
f0102ffc:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102fff:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f0103005:	8d 76 01             	lea    0x1(%esi),%esi
f0103008:	eb 8b                	jmp    f0102f95 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010300a:	83 fb 0a             	cmp    $0xa,%ebx
f010300d:	74 05                	je     f0103014 <readline+0xb4>
f010300f:	83 fb 0d             	cmp    $0xd,%ebx
f0103012:	75 81                	jne    f0102f95 <readline+0x35>
			if (echoing)
f0103014:	85 ff                	test   %edi,%edi
f0103016:	74 0d                	je     f0103025 <readline+0xc5>
				cputchar('\n');
f0103018:	83 ec 0c             	sub    $0xc,%esp
f010301b:	6a 0a                	push   $0xa
f010301d:	e8 de d5 ff ff       	call   f0100600 <cputchar>
f0103022:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103025:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f010302c:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f0103031:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103034:	5b                   	pop    %ebx
f0103035:	5e                   	pop    %esi
f0103036:	5f                   	pop    %edi
f0103037:	5d                   	pop    %ebp
f0103038:	c3                   	ret    

f0103039 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103039:	55                   	push   %ebp
f010303a:	89 e5                	mov    %esp,%ebp
f010303c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010303f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103044:	eb 03                	jmp    f0103049 <strlen+0x10>
		n++;
f0103046:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103049:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010304d:	75 f7                	jne    f0103046 <strlen+0xd>
		n++;
	return n;
}
f010304f:	5d                   	pop    %ebp
f0103050:	c3                   	ret    

f0103051 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103051:	55                   	push   %ebp
f0103052:	89 e5                	mov    %esp,%ebp
f0103054:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103057:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010305a:	ba 00 00 00 00       	mov    $0x0,%edx
f010305f:	eb 03                	jmp    f0103064 <strnlen+0x13>
		n++;
f0103061:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103064:	39 c2                	cmp    %eax,%edx
f0103066:	74 08                	je     f0103070 <strnlen+0x1f>
f0103068:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010306c:	75 f3                	jne    f0103061 <strnlen+0x10>
f010306e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103070:	5d                   	pop    %ebp
f0103071:	c3                   	ret    

f0103072 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103072:	55                   	push   %ebp
f0103073:	89 e5                	mov    %esp,%ebp
f0103075:	53                   	push   %ebx
f0103076:	8b 45 08             	mov    0x8(%ebp),%eax
f0103079:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010307c:	89 c2                	mov    %eax,%edx
f010307e:	83 c2 01             	add    $0x1,%edx
f0103081:	83 c1 01             	add    $0x1,%ecx
f0103084:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103088:	88 5a ff             	mov    %bl,-0x1(%edx)
f010308b:	84 db                	test   %bl,%bl
f010308d:	75 ef                	jne    f010307e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010308f:	5b                   	pop    %ebx
f0103090:	5d                   	pop    %ebp
f0103091:	c3                   	ret    

f0103092 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103092:	55                   	push   %ebp
f0103093:	89 e5                	mov    %esp,%ebp
f0103095:	53                   	push   %ebx
f0103096:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103099:	53                   	push   %ebx
f010309a:	e8 9a ff ff ff       	call   f0103039 <strlen>
f010309f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030a2:	ff 75 0c             	pushl  0xc(%ebp)
f01030a5:	01 d8                	add    %ebx,%eax
f01030a7:	50                   	push   %eax
f01030a8:	e8 c5 ff ff ff       	call   f0103072 <strcpy>
	return dst;
}
f01030ad:	89 d8                	mov    %ebx,%eax
f01030af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030b2:	c9                   	leave  
f01030b3:	c3                   	ret    

f01030b4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
f01030b7:	56                   	push   %esi
f01030b8:	53                   	push   %ebx
f01030b9:	8b 75 08             	mov    0x8(%ebp),%esi
f01030bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030bf:	89 f3                	mov    %esi,%ebx
f01030c1:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030c4:	89 f2                	mov    %esi,%edx
f01030c6:	eb 0f                	jmp    f01030d7 <strncpy+0x23>
		*dst++ = *src;
f01030c8:	83 c2 01             	add    $0x1,%edx
f01030cb:	0f b6 01             	movzbl (%ecx),%eax
f01030ce:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030d1:	80 39 01             	cmpb   $0x1,(%ecx)
f01030d4:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030d7:	39 da                	cmp    %ebx,%edx
f01030d9:	75 ed                	jne    f01030c8 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030db:	89 f0                	mov    %esi,%eax
f01030dd:	5b                   	pop    %ebx
f01030de:	5e                   	pop    %esi
f01030df:	5d                   	pop    %ebp
f01030e0:	c3                   	ret    

f01030e1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030e1:	55                   	push   %ebp
f01030e2:	89 e5                	mov    %esp,%ebp
f01030e4:	56                   	push   %esi
f01030e5:	53                   	push   %ebx
f01030e6:	8b 75 08             	mov    0x8(%ebp),%esi
f01030e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030ec:	8b 55 10             	mov    0x10(%ebp),%edx
f01030ef:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030f1:	85 d2                	test   %edx,%edx
f01030f3:	74 21                	je     f0103116 <strlcpy+0x35>
f01030f5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01030f9:	89 f2                	mov    %esi,%edx
f01030fb:	eb 09                	jmp    f0103106 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01030fd:	83 c2 01             	add    $0x1,%edx
f0103100:	83 c1 01             	add    $0x1,%ecx
f0103103:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103106:	39 c2                	cmp    %eax,%edx
f0103108:	74 09                	je     f0103113 <strlcpy+0x32>
f010310a:	0f b6 19             	movzbl (%ecx),%ebx
f010310d:	84 db                	test   %bl,%bl
f010310f:	75 ec                	jne    f01030fd <strlcpy+0x1c>
f0103111:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103113:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103116:	29 f0                	sub    %esi,%eax
}
f0103118:	5b                   	pop    %ebx
f0103119:	5e                   	pop    %esi
f010311a:	5d                   	pop    %ebp
f010311b:	c3                   	ret    

f010311c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010311c:	55                   	push   %ebp
f010311d:	89 e5                	mov    %esp,%ebp
f010311f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103122:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103125:	eb 06                	jmp    f010312d <strcmp+0x11>
		p++, q++;
f0103127:	83 c1 01             	add    $0x1,%ecx
f010312a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010312d:	0f b6 01             	movzbl (%ecx),%eax
f0103130:	84 c0                	test   %al,%al
f0103132:	74 04                	je     f0103138 <strcmp+0x1c>
f0103134:	3a 02                	cmp    (%edx),%al
f0103136:	74 ef                	je     f0103127 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103138:	0f b6 c0             	movzbl %al,%eax
f010313b:	0f b6 12             	movzbl (%edx),%edx
f010313e:	29 d0                	sub    %edx,%eax
}
f0103140:	5d                   	pop    %ebp
f0103141:	c3                   	ret    

f0103142 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103142:	55                   	push   %ebp
f0103143:	89 e5                	mov    %esp,%ebp
f0103145:	53                   	push   %ebx
f0103146:	8b 45 08             	mov    0x8(%ebp),%eax
f0103149:	8b 55 0c             	mov    0xc(%ebp),%edx
f010314c:	89 c3                	mov    %eax,%ebx
f010314e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103151:	eb 06                	jmp    f0103159 <strncmp+0x17>
		n--, p++, q++;
f0103153:	83 c0 01             	add    $0x1,%eax
f0103156:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103159:	39 d8                	cmp    %ebx,%eax
f010315b:	74 15                	je     f0103172 <strncmp+0x30>
f010315d:	0f b6 08             	movzbl (%eax),%ecx
f0103160:	84 c9                	test   %cl,%cl
f0103162:	74 04                	je     f0103168 <strncmp+0x26>
f0103164:	3a 0a                	cmp    (%edx),%cl
f0103166:	74 eb                	je     f0103153 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103168:	0f b6 00             	movzbl (%eax),%eax
f010316b:	0f b6 12             	movzbl (%edx),%edx
f010316e:	29 d0                	sub    %edx,%eax
f0103170:	eb 05                	jmp    f0103177 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103172:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103177:	5b                   	pop    %ebx
f0103178:	5d                   	pop    %ebp
f0103179:	c3                   	ret    

f010317a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010317a:	55                   	push   %ebp
f010317b:	89 e5                	mov    %esp,%ebp
f010317d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103180:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103184:	eb 07                	jmp    f010318d <strchr+0x13>
		if (*s == c)
f0103186:	38 ca                	cmp    %cl,%dl
f0103188:	74 0f                	je     f0103199 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010318a:	83 c0 01             	add    $0x1,%eax
f010318d:	0f b6 10             	movzbl (%eax),%edx
f0103190:	84 d2                	test   %dl,%dl
f0103192:	75 f2                	jne    f0103186 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103194:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103199:	5d                   	pop    %ebp
f010319a:	c3                   	ret    

f010319b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010319b:	55                   	push   %ebp
f010319c:	89 e5                	mov    %esp,%ebp
f010319e:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031a5:	eb 03                	jmp    f01031aa <strfind+0xf>
f01031a7:	83 c0 01             	add    $0x1,%eax
f01031aa:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031ad:	38 ca                	cmp    %cl,%dl
f01031af:	74 04                	je     f01031b5 <strfind+0x1a>
f01031b1:	84 d2                	test   %dl,%dl
f01031b3:	75 f2                	jne    f01031a7 <strfind+0xc>
			break;
	return (char *) s;
}
f01031b5:	5d                   	pop    %ebp
f01031b6:	c3                   	ret    

f01031b7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031b7:	55                   	push   %ebp
f01031b8:	89 e5                	mov    %esp,%ebp
f01031ba:	57                   	push   %edi
f01031bb:	56                   	push   %esi
f01031bc:	53                   	push   %ebx
f01031bd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031c3:	85 c9                	test   %ecx,%ecx
f01031c5:	74 36                	je     f01031fd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031c7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031cd:	75 28                	jne    f01031f7 <memset+0x40>
f01031cf:	f6 c1 03             	test   $0x3,%cl
f01031d2:	75 23                	jne    f01031f7 <memset+0x40>
		c &= 0xFF;
f01031d4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031d8:	89 d3                	mov    %edx,%ebx
f01031da:	c1 e3 08             	shl    $0x8,%ebx
f01031dd:	89 d6                	mov    %edx,%esi
f01031df:	c1 e6 18             	shl    $0x18,%esi
f01031e2:	89 d0                	mov    %edx,%eax
f01031e4:	c1 e0 10             	shl    $0x10,%eax
f01031e7:	09 f0                	or     %esi,%eax
f01031e9:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031eb:	89 d8                	mov    %ebx,%eax
f01031ed:	09 d0                	or     %edx,%eax
f01031ef:	c1 e9 02             	shr    $0x2,%ecx
f01031f2:	fc                   	cld    
f01031f3:	f3 ab                	rep stos %eax,%es:(%edi)
f01031f5:	eb 06                	jmp    f01031fd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031fa:	fc                   	cld    
f01031fb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01031fd:	89 f8                	mov    %edi,%eax
f01031ff:	5b                   	pop    %ebx
f0103200:	5e                   	pop    %esi
f0103201:	5f                   	pop    %edi
f0103202:	5d                   	pop    %ebp
f0103203:	c3                   	ret    

f0103204 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103204:	55                   	push   %ebp
f0103205:	89 e5                	mov    %esp,%ebp
f0103207:	57                   	push   %edi
f0103208:	56                   	push   %esi
f0103209:	8b 45 08             	mov    0x8(%ebp),%eax
f010320c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010320f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103212:	39 c6                	cmp    %eax,%esi
f0103214:	73 35                	jae    f010324b <memmove+0x47>
f0103216:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103219:	39 d0                	cmp    %edx,%eax
f010321b:	73 2e                	jae    f010324b <memmove+0x47>
		s += n;
		d += n;
f010321d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103220:	89 d6                	mov    %edx,%esi
f0103222:	09 fe                	or     %edi,%esi
f0103224:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010322a:	75 13                	jne    f010323f <memmove+0x3b>
f010322c:	f6 c1 03             	test   $0x3,%cl
f010322f:	75 0e                	jne    f010323f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103231:	83 ef 04             	sub    $0x4,%edi
f0103234:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103237:	c1 e9 02             	shr    $0x2,%ecx
f010323a:	fd                   	std    
f010323b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010323d:	eb 09                	jmp    f0103248 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010323f:	83 ef 01             	sub    $0x1,%edi
f0103242:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103245:	fd                   	std    
f0103246:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103248:	fc                   	cld    
f0103249:	eb 1d                	jmp    f0103268 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010324b:	89 f2                	mov    %esi,%edx
f010324d:	09 c2                	or     %eax,%edx
f010324f:	f6 c2 03             	test   $0x3,%dl
f0103252:	75 0f                	jne    f0103263 <memmove+0x5f>
f0103254:	f6 c1 03             	test   $0x3,%cl
f0103257:	75 0a                	jne    f0103263 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103259:	c1 e9 02             	shr    $0x2,%ecx
f010325c:	89 c7                	mov    %eax,%edi
f010325e:	fc                   	cld    
f010325f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103261:	eb 05                	jmp    f0103268 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103263:	89 c7                	mov    %eax,%edi
f0103265:	fc                   	cld    
f0103266:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103268:	5e                   	pop    %esi
f0103269:	5f                   	pop    %edi
f010326a:	5d                   	pop    %ebp
f010326b:	c3                   	ret    

f010326c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010326c:	55                   	push   %ebp
f010326d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010326f:	ff 75 10             	pushl  0x10(%ebp)
f0103272:	ff 75 0c             	pushl  0xc(%ebp)
f0103275:	ff 75 08             	pushl  0x8(%ebp)
f0103278:	e8 87 ff ff ff       	call   f0103204 <memmove>
}
f010327d:	c9                   	leave  
f010327e:	c3                   	ret    

f010327f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010327f:	55                   	push   %ebp
f0103280:	89 e5                	mov    %esp,%ebp
f0103282:	56                   	push   %esi
f0103283:	53                   	push   %ebx
f0103284:	8b 45 08             	mov    0x8(%ebp),%eax
f0103287:	8b 55 0c             	mov    0xc(%ebp),%edx
f010328a:	89 c6                	mov    %eax,%esi
f010328c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010328f:	eb 1a                	jmp    f01032ab <memcmp+0x2c>
		if (*s1 != *s2)
f0103291:	0f b6 08             	movzbl (%eax),%ecx
f0103294:	0f b6 1a             	movzbl (%edx),%ebx
f0103297:	38 d9                	cmp    %bl,%cl
f0103299:	74 0a                	je     f01032a5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010329b:	0f b6 c1             	movzbl %cl,%eax
f010329e:	0f b6 db             	movzbl %bl,%ebx
f01032a1:	29 d8                	sub    %ebx,%eax
f01032a3:	eb 0f                	jmp    f01032b4 <memcmp+0x35>
		s1++, s2++;
f01032a5:	83 c0 01             	add    $0x1,%eax
f01032a8:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032ab:	39 f0                	cmp    %esi,%eax
f01032ad:	75 e2                	jne    f0103291 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032af:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032b4:	5b                   	pop    %ebx
f01032b5:	5e                   	pop    %esi
f01032b6:	5d                   	pop    %ebp
f01032b7:	c3                   	ret    

f01032b8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032b8:	55                   	push   %ebp
f01032b9:	89 e5                	mov    %esp,%ebp
f01032bb:	53                   	push   %ebx
f01032bc:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032bf:	89 c1                	mov    %eax,%ecx
f01032c1:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032c4:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032c8:	eb 0a                	jmp    f01032d4 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032ca:	0f b6 10             	movzbl (%eax),%edx
f01032cd:	39 da                	cmp    %ebx,%edx
f01032cf:	74 07                	je     f01032d8 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032d1:	83 c0 01             	add    $0x1,%eax
f01032d4:	39 c8                	cmp    %ecx,%eax
f01032d6:	72 f2                	jb     f01032ca <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032d8:	5b                   	pop    %ebx
f01032d9:	5d                   	pop    %ebp
f01032da:	c3                   	ret    

f01032db <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032db:	55                   	push   %ebp
f01032dc:	89 e5                	mov    %esp,%ebp
f01032de:	57                   	push   %edi
f01032df:	56                   	push   %esi
f01032e0:	53                   	push   %ebx
f01032e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032e4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032e7:	eb 03                	jmp    f01032ec <strtol+0x11>
		s++;
f01032e9:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032ec:	0f b6 01             	movzbl (%ecx),%eax
f01032ef:	3c 20                	cmp    $0x20,%al
f01032f1:	74 f6                	je     f01032e9 <strtol+0xe>
f01032f3:	3c 09                	cmp    $0x9,%al
f01032f5:	74 f2                	je     f01032e9 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032f7:	3c 2b                	cmp    $0x2b,%al
f01032f9:	75 0a                	jne    f0103305 <strtol+0x2a>
		s++;
f01032fb:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01032fe:	bf 00 00 00 00       	mov    $0x0,%edi
f0103303:	eb 11                	jmp    f0103316 <strtol+0x3b>
f0103305:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010330a:	3c 2d                	cmp    $0x2d,%al
f010330c:	75 08                	jne    f0103316 <strtol+0x3b>
		s++, neg = 1;
f010330e:	83 c1 01             	add    $0x1,%ecx
f0103311:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103316:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010331c:	75 15                	jne    f0103333 <strtol+0x58>
f010331e:	80 39 30             	cmpb   $0x30,(%ecx)
f0103321:	75 10                	jne    f0103333 <strtol+0x58>
f0103323:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103327:	75 7c                	jne    f01033a5 <strtol+0xca>
		s += 2, base = 16;
f0103329:	83 c1 02             	add    $0x2,%ecx
f010332c:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103331:	eb 16                	jmp    f0103349 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103333:	85 db                	test   %ebx,%ebx
f0103335:	75 12                	jne    f0103349 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103337:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010333c:	80 39 30             	cmpb   $0x30,(%ecx)
f010333f:	75 08                	jne    f0103349 <strtol+0x6e>
		s++, base = 8;
f0103341:	83 c1 01             	add    $0x1,%ecx
f0103344:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103349:	b8 00 00 00 00       	mov    $0x0,%eax
f010334e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103351:	0f b6 11             	movzbl (%ecx),%edx
f0103354:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103357:	89 f3                	mov    %esi,%ebx
f0103359:	80 fb 09             	cmp    $0x9,%bl
f010335c:	77 08                	ja     f0103366 <strtol+0x8b>
			dig = *s - '0';
f010335e:	0f be d2             	movsbl %dl,%edx
f0103361:	83 ea 30             	sub    $0x30,%edx
f0103364:	eb 22                	jmp    f0103388 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103366:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103369:	89 f3                	mov    %esi,%ebx
f010336b:	80 fb 19             	cmp    $0x19,%bl
f010336e:	77 08                	ja     f0103378 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103370:	0f be d2             	movsbl %dl,%edx
f0103373:	83 ea 57             	sub    $0x57,%edx
f0103376:	eb 10                	jmp    f0103388 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103378:	8d 72 bf             	lea    -0x41(%edx),%esi
f010337b:	89 f3                	mov    %esi,%ebx
f010337d:	80 fb 19             	cmp    $0x19,%bl
f0103380:	77 16                	ja     f0103398 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103382:	0f be d2             	movsbl %dl,%edx
f0103385:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103388:	3b 55 10             	cmp    0x10(%ebp),%edx
f010338b:	7d 0b                	jge    f0103398 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010338d:	83 c1 01             	add    $0x1,%ecx
f0103390:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103394:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103396:	eb b9                	jmp    f0103351 <strtol+0x76>

	if (endptr)
f0103398:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010339c:	74 0d                	je     f01033ab <strtol+0xd0>
		*endptr = (char *) s;
f010339e:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033a1:	89 0e                	mov    %ecx,(%esi)
f01033a3:	eb 06                	jmp    f01033ab <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033a5:	85 db                	test   %ebx,%ebx
f01033a7:	74 98                	je     f0103341 <strtol+0x66>
f01033a9:	eb 9e                	jmp    f0103349 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033ab:	89 c2                	mov    %eax,%edx
f01033ad:	f7 da                	neg    %edx
f01033af:	85 ff                	test   %edi,%edi
f01033b1:	0f 45 c2             	cmovne %edx,%eax
}
f01033b4:	5b                   	pop    %ebx
f01033b5:	5e                   	pop    %esi
f01033b6:	5f                   	pop    %edi
f01033b7:	5d                   	pop    %ebp
f01033b8:	c3                   	ret    
f01033b9:	66 90                	xchg   %ax,%ax
f01033bb:	66 90                	xchg   %ax,%ax
f01033bd:	66 90                	xchg   %ax,%ax
f01033bf:	90                   	nop

f01033c0 <__udivdi3>:
f01033c0:	55                   	push   %ebp
f01033c1:	57                   	push   %edi
f01033c2:	56                   	push   %esi
f01033c3:	53                   	push   %ebx
f01033c4:	83 ec 1c             	sub    $0x1c,%esp
f01033c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033d7:	85 f6                	test   %esi,%esi
f01033d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033dd:	89 ca                	mov    %ecx,%edx
f01033df:	89 f8                	mov    %edi,%eax
f01033e1:	75 3d                	jne    f0103420 <__udivdi3+0x60>
f01033e3:	39 cf                	cmp    %ecx,%edi
f01033e5:	0f 87 c5 00 00 00    	ja     f01034b0 <__udivdi3+0xf0>
f01033eb:	85 ff                	test   %edi,%edi
f01033ed:	89 fd                	mov    %edi,%ebp
f01033ef:	75 0b                	jne    f01033fc <__udivdi3+0x3c>
f01033f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01033f6:	31 d2                	xor    %edx,%edx
f01033f8:	f7 f7                	div    %edi
f01033fa:	89 c5                	mov    %eax,%ebp
f01033fc:	89 c8                	mov    %ecx,%eax
f01033fe:	31 d2                	xor    %edx,%edx
f0103400:	f7 f5                	div    %ebp
f0103402:	89 c1                	mov    %eax,%ecx
f0103404:	89 d8                	mov    %ebx,%eax
f0103406:	89 cf                	mov    %ecx,%edi
f0103408:	f7 f5                	div    %ebp
f010340a:	89 c3                	mov    %eax,%ebx
f010340c:	89 d8                	mov    %ebx,%eax
f010340e:	89 fa                	mov    %edi,%edx
f0103410:	83 c4 1c             	add    $0x1c,%esp
f0103413:	5b                   	pop    %ebx
f0103414:	5e                   	pop    %esi
f0103415:	5f                   	pop    %edi
f0103416:	5d                   	pop    %ebp
f0103417:	c3                   	ret    
f0103418:	90                   	nop
f0103419:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103420:	39 ce                	cmp    %ecx,%esi
f0103422:	77 74                	ja     f0103498 <__udivdi3+0xd8>
f0103424:	0f bd fe             	bsr    %esi,%edi
f0103427:	83 f7 1f             	xor    $0x1f,%edi
f010342a:	0f 84 98 00 00 00    	je     f01034c8 <__udivdi3+0x108>
f0103430:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103435:	89 f9                	mov    %edi,%ecx
f0103437:	89 c5                	mov    %eax,%ebp
f0103439:	29 fb                	sub    %edi,%ebx
f010343b:	d3 e6                	shl    %cl,%esi
f010343d:	89 d9                	mov    %ebx,%ecx
f010343f:	d3 ed                	shr    %cl,%ebp
f0103441:	89 f9                	mov    %edi,%ecx
f0103443:	d3 e0                	shl    %cl,%eax
f0103445:	09 ee                	or     %ebp,%esi
f0103447:	89 d9                	mov    %ebx,%ecx
f0103449:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010344d:	89 d5                	mov    %edx,%ebp
f010344f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103453:	d3 ed                	shr    %cl,%ebp
f0103455:	89 f9                	mov    %edi,%ecx
f0103457:	d3 e2                	shl    %cl,%edx
f0103459:	89 d9                	mov    %ebx,%ecx
f010345b:	d3 e8                	shr    %cl,%eax
f010345d:	09 c2                	or     %eax,%edx
f010345f:	89 d0                	mov    %edx,%eax
f0103461:	89 ea                	mov    %ebp,%edx
f0103463:	f7 f6                	div    %esi
f0103465:	89 d5                	mov    %edx,%ebp
f0103467:	89 c3                	mov    %eax,%ebx
f0103469:	f7 64 24 0c          	mull   0xc(%esp)
f010346d:	39 d5                	cmp    %edx,%ebp
f010346f:	72 10                	jb     f0103481 <__udivdi3+0xc1>
f0103471:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103475:	89 f9                	mov    %edi,%ecx
f0103477:	d3 e6                	shl    %cl,%esi
f0103479:	39 c6                	cmp    %eax,%esi
f010347b:	73 07                	jae    f0103484 <__udivdi3+0xc4>
f010347d:	39 d5                	cmp    %edx,%ebp
f010347f:	75 03                	jne    f0103484 <__udivdi3+0xc4>
f0103481:	83 eb 01             	sub    $0x1,%ebx
f0103484:	31 ff                	xor    %edi,%edi
f0103486:	89 d8                	mov    %ebx,%eax
f0103488:	89 fa                	mov    %edi,%edx
f010348a:	83 c4 1c             	add    $0x1c,%esp
f010348d:	5b                   	pop    %ebx
f010348e:	5e                   	pop    %esi
f010348f:	5f                   	pop    %edi
f0103490:	5d                   	pop    %ebp
f0103491:	c3                   	ret    
f0103492:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103498:	31 ff                	xor    %edi,%edi
f010349a:	31 db                	xor    %ebx,%ebx
f010349c:	89 d8                	mov    %ebx,%eax
f010349e:	89 fa                	mov    %edi,%edx
f01034a0:	83 c4 1c             	add    $0x1c,%esp
f01034a3:	5b                   	pop    %ebx
f01034a4:	5e                   	pop    %esi
f01034a5:	5f                   	pop    %edi
f01034a6:	5d                   	pop    %ebp
f01034a7:	c3                   	ret    
f01034a8:	90                   	nop
f01034a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034b0:	89 d8                	mov    %ebx,%eax
f01034b2:	f7 f7                	div    %edi
f01034b4:	31 ff                	xor    %edi,%edi
f01034b6:	89 c3                	mov    %eax,%ebx
f01034b8:	89 d8                	mov    %ebx,%eax
f01034ba:	89 fa                	mov    %edi,%edx
f01034bc:	83 c4 1c             	add    $0x1c,%esp
f01034bf:	5b                   	pop    %ebx
f01034c0:	5e                   	pop    %esi
f01034c1:	5f                   	pop    %edi
f01034c2:	5d                   	pop    %ebp
f01034c3:	c3                   	ret    
f01034c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034c8:	39 ce                	cmp    %ecx,%esi
f01034ca:	72 0c                	jb     f01034d8 <__udivdi3+0x118>
f01034cc:	31 db                	xor    %ebx,%ebx
f01034ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034d2:	0f 87 34 ff ff ff    	ja     f010340c <__udivdi3+0x4c>
f01034d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034dd:	e9 2a ff ff ff       	jmp    f010340c <__udivdi3+0x4c>
f01034e2:	66 90                	xchg   %ax,%ax
f01034e4:	66 90                	xchg   %ax,%ax
f01034e6:	66 90                	xchg   %ax,%ax
f01034e8:	66 90                	xchg   %ax,%ax
f01034ea:	66 90                	xchg   %ax,%ax
f01034ec:	66 90                	xchg   %ax,%ax
f01034ee:	66 90                	xchg   %ax,%ax

f01034f0 <__umoddi3>:
f01034f0:	55                   	push   %ebp
f01034f1:	57                   	push   %edi
f01034f2:	56                   	push   %esi
f01034f3:	53                   	push   %ebx
f01034f4:	83 ec 1c             	sub    $0x1c,%esp
f01034f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01034fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01034ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103503:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103507:	85 d2                	test   %edx,%edx
f0103509:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010350d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103511:	89 f3                	mov    %esi,%ebx
f0103513:	89 3c 24             	mov    %edi,(%esp)
f0103516:	89 74 24 04          	mov    %esi,0x4(%esp)
f010351a:	75 1c                	jne    f0103538 <__umoddi3+0x48>
f010351c:	39 f7                	cmp    %esi,%edi
f010351e:	76 50                	jbe    f0103570 <__umoddi3+0x80>
f0103520:	89 c8                	mov    %ecx,%eax
f0103522:	89 f2                	mov    %esi,%edx
f0103524:	f7 f7                	div    %edi
f0103526:	89 d0                	mov    %edx,%eax
f0103528:	31 d2                	xor    %edx,%edx
f010352a:	83 c4 1c             	add    $0x1c,%esp
f010352d:	5b                   	pop    %ebx
f010352e:	5e                   	pop    %esi
f010352f:	5f                   	pop    %edi
f0103530:	5d                   	pop    %ebp
f0103531:	c3                   	ret    
f0103532:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103538:	39 f2                	cmp    %esi,%edx
f010353a:	89 d0                	mov    %edx,%eax
f010353c:	77 52                	ja     f0103590 <__umoddi3+0xa0>
f010353e:	0f bd ea             	bsr    %edx,%ebp
f0103541:	83 f5 1f             	xor    $0x1f,%ebp
f0103544:	75 5a                	jne    f01035a0 <__umoddi3+0xb0>
f0103546:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010354a:	0f 82 e0 00 00 00    	jb     f0103630 <__umoddi3+0x140>
f0103550:	39 0c 24             	cmp    %ecx,(%esp)
f0103553:	0f 86 d7 00 00 00    	jbe    f0103630 <__umoddi3+0x140>
f0103559:	8b 44 24 08          	mov    0x8(%esp),%eax
f010355d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103561:	83 c4 1c             	add    $0x1c,%esp
f0103564:	5b                   	pop    %ebx
f0103565:	5e                   	pop    %esi
f0103566:	5f                   	pop    %edi
f0103567:	5d                   	pop    %ebp
f0103568:	c3                   	ret    
f0103569:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103570:	85 ff                	test   %edi,%edi
f0103572:	89 fd                	mov    %edi,%ebp
f0103574:	75 0b                	jne    f0103581 <__umoddi3+0x91>
f0103576:	b8 01 00 00 00       	mov    $0x1,%eax
f010357b:	31 d2                	xor    %edx,%edx
f010357d:	f7 f7                	div    %edi
f010357f:	89 c5                	mov    %eax,%ebp
f0103581:	89 f0                	mov    %esi,%eax
f0103583:	31 d2                	xor    %edx,%edx
f0103585:	f7 f5                	div    %ebp
f0103587:	89 c8                	mov    %ecx,%eax
f0103589:	f7 f5                	div    %ebp
f010358b:	89 d0                	mov    %edx,%eax
f010358d:	eb 99                	jmp    f0103528 <__umoddi3+0x38>
f010358f:	90                   	nop
f0103590:	89 c8                	mov    %ecx,%eax
f0103592:	89 f2                	mov    %esi,%edx
f0103594:	83 c4 1c             	add    $0x1c,%esp
f0103597:	5b                   	pop    %ebx
f0103598:	5e                   	pop    %esi
f0103599:	5f                   	pop    %edi
f010359a:	5d                   	pop    %ebp
f010359b:	c3                   	ret    
f010359c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035a0:	8b 34 24             	mov    (%esp),%esi
f01035a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035a8:	89 e9                	mov    %ebp,%ecx
f01035aa:	29 ef                	sub    %ebp,%edi
f01035ac:	d3 e0                	shl    %cl,%eax
f01035ae:	89 f9                	mov    %edi,%ecx
f01035b0:	89 f2                	mov    %esi,%edx
f01035b2:	d3 ea                	shr    %cl,%edx
f01035b4:	89 e9                	mov    %ebp,%ecx
f01035b6:	09 c2                	or     %eax,%edx
f01035b8:	89 d8                	mov    %ebx,%eax
f01035ba:	89 14 24             	mov    %edx,(%esp)
f01035bd:	89 f2                	mov    %esi,%edx
f01035bf:	d3 e2                	shl    %cl,%edx
f01035c1:	89 f9                	mov    %edi,%ecx
f01035c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035cb:	d3 e8                	shr    %cl,%eax
f01035cd:	89 e9                	mov    %ebp,%ecx
f01035cf:	89 c6                	mov    %eax,%esi
f01035d1:	d3 e3                	shl    %cl,%ebx
f01035d3:	89 f9                	mov    %edi,%ecx
f01035d5:	89 d0                	mov    %edx,%eax
f01035d7:	d3 e8                	shr    %cl,%eax
f01035d9:	89 e9                	mov    %ebp,%ecx
f01035db:	09 d8                	or     %ebx,%eax
f01035dd:	89 d3                	mov    %edx,%ebx
f01035df:	89 f2                	mov    %esi,%edx
f01035e1:	f7 34 24             	divl   (%esp)
f01035e4:	89 d6                	mov    %edx,%esi
f01035e6:	d3 e3                	shl    %cl,%ebx
f01035e8:	f7 64 24 04          	mull   0x4(%esp)
f01035ec:	39 d6                	cmp    %edx,%esi
f01035ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035f2:	89 d1                	mov    %edx,%ecx
f01035f4:	89 c3                	mov    %eax,%ebx
f01035f6:	72 08                	jb     f0103600 <__umoddi3+0x110>
f01035f8:	75 11                	jne    f010360b <__umoddi3+0x11b>
f01035fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01035fe:	73 0b                	jae    f010360b <__umoddi3+0x11b>
f0103600:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103604:	1b 14 24             	sbb    (%esp),%edx
f0103607:	89 d1                	mov    %edx,%ecx
f0103609:	89 c3                	mov    %eax,%ebx
f010360b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010360f:	29 da                	sub    %ebx,%edx
f0103611:	19 ce                	sbb    %ecx,%esi
f0103613:	89 f9                	mov    %edi,%ecx
f0103615:	89 f0                	mov    %esi,%eax
f0103617:	d3 e0                	shl    %cl,%eax
f0103619:	89 e9                	mov    %ebp,%ecx
f010361b:	d3 ea                	shr    %cl,%edx
f010361d:	89 e9                	mov    %ebp,%ecx
f010361f:	d3 ee                	shr    %cl,%esi
f0103621:	09 d0                	or     %edx,%eax
f0103623:	89 f2                	mov    %esi,%edx
f0103625:	83 c4 1c             	add    $0x1c,%esp
f0103628:	5b                   	pop    %ebx
f0103629:	5e                   	pop    %esi
f010362a:	5f                   	pop    %edi
f010362b:	5d                   	pop    %ebp
f010362c:	c3                   	ret    
f010362d:	8d 76 00             	lea    0x0(%esi),%esi
f0103630:	29 f9                	sub    %edi,%ecx
f0103632:	19 d6                	sbb    %edx,%esi
f0103634:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103638:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010363c:	e9 18 ff ff ff       	jmp    f0103559 <__umoddi3+0x69>
