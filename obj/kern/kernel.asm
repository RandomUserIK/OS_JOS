
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
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
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
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

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
f0100046:	b8 50 fc 16 f0       	mov    $0xf016fc50,%eax
f010004b:	2d 26 ed 16 f0       	sub    $0xf016ed26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 ed 16 f0       	push   $0xf016ed26
f0100058:	e8 2c 3a 00 00       	call   f0103a89 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 3f 10 f0       	push   $0xf0103f20
f010006f:	e8 88 2b 00 00       	call   f0102bfc <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 85 10 00 00       	call   f01010fe <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 c8 27 00 00       	call   f0102846 <env_init>
	trap_init();
f010007e:	e8 f3 2b 00 00       	call   f0102c76 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 93 11 f0       	push   $0xf0119356
f010008d:	e8 d8 28 00 00       	call   f010296a <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 84 ef 16 f0    	pushl  0xf016ef84
f010009b:	e8 db 2a 00 00       	call   f0102b7b <env_run>

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
f01000a8:	83 3d 40 fc 16 f0 00 	cmpl   $0x0,0xf016fc40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 fc 16 f0    	mov    %esi,0xf016fc40

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
f01000c5:	68 3b 3f 10 f0       	push   $0xf0103f3b
f01000ca:	e8 2d 2b 00 00       	call   f0102bfc <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 fd 2a 00 00       	call   f0102bd6 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 5c 42 10 f0 	movl   $0xf010425c,(%esp)
f01000e0:	e8 17 2b 00 00       	call   f0102bfc <cprintf>
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
f0100107:	68 53 3f 10 f0       	push   $0xf0103f53
f010010c:	e8 eb 2a 00 00       	call   f0102bfc <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 b9 2a 00 00       	call   f0102bd6 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 5c 42 10 f0 	movl   $0xf010425c,(%esp)
f0100124:	e8 d3 2a 00 00       	call   f0102bfc <cprintf>
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
f010015f:	8b 0d 64 ef 16 f0    	mov    0xf016ef64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 ef 16 f0    	mov    %edx,0xf016ef64
f010016e:	88 81 60 ed 16 f0    	mov    %al,-0xfe912a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 ef 16 f0 00 	movl   $0x0,0xf016ef64
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
f01001b5:	83 0d 40 ed 16 f0 40 	orl    $0x40,0xf016ed40
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
f01001cd:	8b 0d 40 ed 16 f0    	mov    0xf016ed40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 c0 40 10 f0 	movzbl -0xfefbf40(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 ed 16 f0       	mov    %eax,0xf016ed40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 ed 16 f0    	mov    0xf016ed40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 ed 16 f0    	mov    %ecx,0xf016ed40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 c0 40 10 f0 	movzbl -0xfefbf40(%edx),%eax
f0100226:	0b 05 40 ed 16 f0    	or     0xf016ed40,%eax
f010022c:	0f b6 8a c0 3f 10 f0 	movzbl -0xfefc040(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 ed 16 f0       	mov    %eax,0xf016ed40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d a0 3f 10 f0 	mov    -0xfefc060(,%ecx,4),%ecx
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
f010027d:	68 6d 3f 10 f0       	push   $0xf0103f6d
f0100282:	e8 75 29 00 00       	call   f0102bfc <cprintf>
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
f0100369:	0f b7 05 68 ef 16 f0 	movzwl 0xf016ef68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 ef 16 f0    	mov    %ax,0xf016ef68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c ef 16 f0    	mov    0xf016ef6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 ef 16 f0 	addw   $0x50,0xf016ef68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 ef 16 f0 	movzwl 0xf016ef68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 ef 16 f0    	mov    %ax,0xf016ef68
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
f01003f3:	0f b7 05 68 ef 16 f0 	movzwl 0xf016ef68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 ef 16 f0 	mov    %dx,0xf016ef68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c ef 16 f0    	mov    0xf016ef6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 ef 16 f0 	cmpw   $0x7cf,0xf016ef68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c ef 16 f0       	mov    0xf016ef6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 a0 36 00 00       	call   f0103ad6 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c ef 16 f0    	mov    0xf016ef6c,%edx
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
f0100457:	66 83 2d 68 ef 16 f0 	subw   $0x50,0xf016ef68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 ef 16 f0    	mov    0xf016ef70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 ef 16 f0 	movzwl 0xf016ef68,%ebx
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
f0100495:	80 3d 74 ef 16 f0 00 	cmpb   $0x0,0xf016ef74
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
f01004d3:	a1 60 ef 16 f0       	mov    0xf016ef60,%eax
f01004d8:	3b 05 64 ef 16 f0    	cmp    0xf016ef64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 ef 16 f0    	mov    %edx,0xf016ef60
f01004e9:	0f b6 88 60 ed 16 f0 	movzbl -0xfe912a0(%eax),%ecx
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
f01004fa:	c7 05 60 ef 16 f0 00 	movl   $0x0,0xf016ef60
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
f0100533:	c7 05 70 ef 16 f0 b4 	movl   $0x3b4,0xf016ef70
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
f010054b:	c7 05 70 ef 16 f0 d4 	movl   $0x3d4,0xf016ef70
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
f010055a:	8b 3d 70 ef 16 f0    	mov    0xf016ef70,%edi
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
f010057f:	89 35 6c ef 16 f0    	mov    %esi,0xf016ef6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 ef 16 f0    	mov    %ax,0xf016ef68
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
f01005eb:	0f 95 05 74 ef 16 f0 	setne  0xf016ef74
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
f0100600:	68 79 3f 10 f0       	push   $0xf0103f79
f0100605:	e8 f2 25 00 00       	call   f0102bfc <cprintf>
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
f0100646:	68 c0 41 10 f0       	push   $0xf01041c0
f010064b:	68 de 41 10 f0       	push   $0xf01041de
f0100650:	68 e3 41 10 f0       	push   $0xf01041e3
f0100655:	e8 a2 25 00 00       	call   f0102bfc <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 9c 42 10 f0       	push   $0xf010429c
f0100662:	68 ec 41 10 f0       	push   $0xf01041ec
f0100667:	68 e3 41 10 f0       	push   $0xf01041e3
f010066c:	e8 8b 25 00 00       	call   f0102bfc <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 c4 42 10 f0       	push   $0xf01042c4
f0100679:	68 f5 41 10 f0       	push   $0xf01041f5
f010067e:	68 e3 41 10 f0       	push   $0xf01041e3
f0100683:	e8 74 25 00 00       	call   f0102bfc <cprintf>
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
f0100695:	68 ff 41 10 f0       	push   $0xf01041ff
f010069a:	e8 5d 25 00 00       	call   f0102bfc <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 f0 42 10 f0       	push   $0xf01042f0
f01006ac:	e8 4b 25 00 00       	call   f0102bfc <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 18 43 10 f0       	push   $0xf0104318
f01006c3:	e8 34 25 00 00       	call   f0102bfc <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 11 3f 10 00       	push   $0x103f11
f01006d0:	68 11 3f 10 f0       	push   $0xf0103f11
f01006d5:	68 3c 43 10 f0       	push   $0xf010433c
f01006da:	e8 1d 25 00 00       	call   f0102bfc <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 ed 16 00       	push   $0x16ed26
f01006e7:	68 26 ed 16 f0       	push   $0xf016ed26
f01006ec:	68 60 43 10 f0       	push   $0xf0104360
f01006f1:	e8 06 25 00 00       	call   f0102bfc <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 fc 16 00       	push   $0x16fc50
f01006fe:	68 50 fc 16 f0       	push   $0xf016fc50
f0100703:	68 84 43 10 f0       	push   $0xf0104384
f0100708:	e8 ef 24 00 00       	call   f0102bfc <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 4f 00 17 f0       	mov    $0xf017004f,%eax
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
f010072e:	68 a8 43 10 f0       	push   $0xf01043a8
f0100733:	e8 c4 24 00 00       	call   f0102bfc <cprintf>
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
f010074a:	68 18 42 10 f0       	push   $0xf0104218
f010074f:	e8 a8 24 00 00       	call   f0102bfc <cprintf>
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
f0100767:	68 2b 42 10 f0       	push   $0xf010422b
f010076c:	e8 8b 24 00 00       	call   f0102bfc <cprintf>
		cprintf("%08x ", *(ebp+2));
f0100771:	83 c4 08             	add    $0x8,%esp
f0100774:	ff 73 08             	pushl  0x8(%ebx)
f0100777:	68 45 42 10 f0       	push   $0xf0104245
f010077c:	e8 7b 24 00 00       	call   f0102bfc <cprintf>
		cprintf("%08x ", *(ebp+3));
f0100781:	83 c4 08             	add    $0x8,%esp
f0100784:	ff 73 0c             	pushl  0xc(%ebx)
f0100787:	68 45 42 10 f0       	push   $0xf0104245
f010078c:	e8 6b 24 00 00       	call   f0102bfc <cprintf>
		cprintf("%08x ", *(ebp+4));
f0100791:	83 c4 08             	add    $0x8,%esp
f0100794:	ff 73 10             	pushl  0x10(%ebx)
f0100797:	68 45 42 10 f0       	push   $0xf0104245
f010079c:	e8 5b 24 00 00       	call   f0102bfc <cprintf>
		cprintf("%08x ", *(ebp+5));
f01007a1:	83 c4 08             	add    $0x8,%esp
f01007a4:	ff 73 14             	pushl  0x14(%ebx)
f01007a7:	68 45 42 10 f0       	push   $0xf0104245
f01007ac:	e8 4b 24 00 00       	call   f0102bfc <cprintf>
		cprintf("%08x", *(ebp+6));
f01007b1:	83 c4 08             	add    $0x8,%esp
f01007b4:	ff 73 18             	pushl  0x18(%ebx)
f01007b7:	68 9e 50 10 f0       	push   $0xf010509e
f01007bc:	e8 3b 24 00 00       	call   f0102bfc <cprintf>

		if(debuginfo_eip(eip, &info) == 0)
f01007c1:	83 c4 08             	add    $0x8,%esp
f01007c4:	57                   	push   %edi
f01007c5:	56                   	push   %esi
f01007c6:	e8 ee 28 00 00       	call   f01030b9 <debuginfo_eip>
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
f01007e5:	68 4b 42 10 f0       	push   $0xf010424b
f01007ea:	e8 0d 24 00 00       	call   f0102bfc <cprintf>
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
f0100812:	68 d4 43 10 f0       	push   $0xf01043d4
f0100817:	e8 e0 23 00 00       	call   f0102bfc <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081c:	c7 04 24 f8 43 10 f0 	movl   $0xf01043f8,(%esp)
f0100823:	e8 d4 23 00 00       	call   f0102bfc <cprintf>

	if (tf != NULL)
f0100828:	83 c4 10             	add    $0x10,%esp
f010082b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010082f:	74 0e                	je     f010083f <monitor+0x36>
		print_trapframe(tf);
f0100831:	83 ec 0c             	sub    $0xc,%esp
f0100834:	ff 75 08             	pushl  0x8(%ebp)
f0100837:	e8 d2 24 00 00       	call   f0102d0e <print_trapframe>
f010083c:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010083f:	83 ec 0c             	sub    $0xc,%esp
f0100842:	68 5e 42 10 f0       	push   $0xf010425e
f0100847:	e8 e6 2f 00 00       	call   f0103832 <readline>
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
f010087b:	68 62 42 10 f0       	push   $0xf0104262
f0100880:	e8 c7 31 00 00       	call   f0103a4c <strchr>
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
f010089b:	68 67 42 10 f0       	push   $0xf0104267
f01008a0:	e8 57 23 00 00       	call   f0102bfc <cprintf>
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
f01008c4:	68 62 42 10 f0       	push   $0xf0104262
f01008c9:	e8 7e 31 00 00       	call   f0103a4c <strchr>
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
f01008f2:	ff 34 85 20 44 10 f0 	pushl  -0xfefbbe0(,%eax,4)
f01008f9:	ff 75 a8             	pushl  -0x58(%ebp)
f01008fc:	e8 ed 30 00 00       	call   f01039ee <strcmp>
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
f0100916:	ff 14 85 28 44 10 f0 	call   *-0xfefbbd8(,%eax,4)
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
f0100937:	68 84 42 10 f0       	push   $0xf0104284
f010093c:	e8 bb 22 00 00       	call   f0102bfc <cprintf>
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
f010095c:	e8 34 22 00 00       	call   f0102b95 <mc146818_read>
f0100961:	89 c6                	mov    %eax,%esi
f0100963:	83 c3 01             	add    $0x1,%ebx
f0100966:	89 1c 24             	mov    %ebx,(%esp)
f0100969:	e8 27 22 00 00       	call   f0102b95 <mc146818_read>
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
f0100990:	3b 0d 44 fc 16 f0    	cmp    0xf016fc44,%ecx
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
f010099f:	68 44 44 10 f0       	push   $0xf0104444
f01009a4:	68 46 03 00 00       	push   $0x346
f01009a9:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01009e4:	83 3d 78 ef 16 f0 00 	cmpl   $0x0,0xf016ef78
f01009eb:	75 11                	jne    f01009fe <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ed:	ba 4f 0c 17 f0       	mov    $0xf0170c4f,%edx
f01009f2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009f8:	89 15 78 ef 16 f0    	mov    %edx,0xf016ef78
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n < 0) panic("boot_alloc: cannot allocate negative amount of memory!\n");

	if(n == 0) return nextfree;
f01009fe:	85 c0                	test   %eax,%eax
f0100a00:	75 07                	jne    f0100a09 <boot_alloc+0x2b>
f0100a02:	a1 78 ef 16 f0       	mov    0xf016ef78,%eax
f0100a07:	eb 54                	jmp    f0100a5d <boot_alloc+0x7f>

	else
	{
		result = nextfree;
f0100a09:	8b 15 78 ef 16 f0    	mov    0xf016ef78,%edx

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
f0100a23:	68 68 44 10 f0       	push   $0xf0104468
f0100a28:	6a 74                	push   $0x74
f0100a2a:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100a2f:	e8 6c f6 ff ff       	call   f01000a0 <_panic>

		if(PADDR(new) > 1024*1024*4) panic("boot_alloc: not enough memory!\n");
f0100a34:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100a3a:	81 f9 00 00 40 00    	cmp    $0x400000,%ecx
f0100a40:	76 14                	jbe    f0100a56 <boot_alloc+0x78>
f0100a42:	83 ec 04             	sub    $0x4,%esp
f0100a45:	68 8c 44 10 f0       	push   $0xf010448c
f0100a4a:	6a 74                	push   $0x74
f0100a4c:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100a51:	e8 4a f6 ff ff       	call   f01000a0 <_panic>

		else
		{
			nextfree = new;
f0100a56:	a3 78 ef 16 f0       	mov    %eax,0xf016ef78
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
f0100a78:	68 ac 44 10 f0       	push   $0xf01044ac
f0100a7d:	68 82 02 00 00       	push   $0x282
f0100a82:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0100a9a:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
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
f0100ad0:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c
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
f0100ada:	8b 1d 7c ef 16 f0    	mov    0xf016ef7c,%ebx
f0100ae0:	eb 53                	jmp    f0100b35 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ae2:	89 d8                	mov    %ebx,%eax
f0100ae4:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
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
f0100afe:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0100b04:	72 12                	jb     f0100b18 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b06:	50                   	push   %eax
f0100b07:	68 44 44 10 f0       	push   $0xf0104444
f0100b0c:	6a 56                	push   $0x56
f0100b0e:	68 26 4c 10 f0       	push   $0xf0104c26
f0100b13:	e8 88 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b18:	83 ec 04             	sub    $0x4,%esp
f0100b1b:	68 80 00 00 00       	push   $0x80
f0100b20:	68 97 00 00 00       	push   $0x97
f0100b25:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b2a:	50                   	push   %eax
f0100b2b:	e8 59 2f 00 00       	call   f0103a89 <memset>
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
f0100b46:	8b 15 7c ef 16 f0    	mov    0xf016ef7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b4c:	8b 0d 4c fc 16 f0    	mov    0xf016fc4c,%ecx
		assert(pp < pages + npages);
f0100b52:	a1 44 fc 16 f0       	mov    0xf016fc44,%eax
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
f0100b71:	68 34 4c 10 f0       	push   $0xf0104c34
f0100b76:	68 40 4c 10 f0       	push   $0xf0104c40
f0100b7b:	68 9c 02 00 00       	push   $0x29c
f0100b80:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100b85:	e8 16 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b8a:	39 fa                	cmp    %edi,%edx
f0100b8c:	72 19                	jb     f0100ba7 <check_page_free_list+0x148>
f0100b8e:	68 55 4c 10 f0       	push   $0xf0104c55
f0100b93:	68 40 4c 10 f0       	push   $0xf0104c40
f0100b98:	68 9d 02 00 00       	push   $0x29d
f0100b9d:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100ba2:	e8 f9 f4 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ba7:	89 d0                	mov    %edx,%eax
f0100ba9:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100bac:	a8 07                	test   $0x7,%al
f0100bae:	74 19                	je     f0100bc9 <check_page_free_list+0x16a>
f0100bb0:	68 d0 44 10 f0       	push   $0xf01044d0
f0100bb5:	68 40 4c 10 f0       	push   $0xf0104c40
f0100bba:	68 9e 02 00 00       	push   $0x29e
f0100bbf:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0100bd3:	68 69 4c 10 f0       	push   $0xf0104c69
f0100bd8:	68 40 4c 10 f0       	push   $0xf0104c40
f0100bdd:	68 a1 02 00 00       	push   $0x2a1
f0100be2:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100be7:	e8 b4 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bec:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bf1:	75 19                	jne    f0100c0c <check_page_free_list+0x1ad>
f0100bf3:	68 7a 4c 10 f0       	push   $0xf0104c7a
f0100bf8:	68 40 4c 10 f0       	push   $0xf0104c40
f0100bfd:	68 a2 02 00 00       	push   $0x2a2
f0100c02:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100c07:	e8 94 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c0c:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c11:	75 19                	jne    f0100c2c <check_page_free_list+0x1cd>
f0100c13:	68 04 45 10 f0       	push   $0xf0104504
f0100c18:	68 40 4c 10 f0       	push   $0xf0104c40
f0100c1d:	68 a3 02 00 00       	push   $0x2a3
f0100c22:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100c27:	e8 74 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c2c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c31:	75 19                	jne    f0100c4c <check_page_free_list+0x1ed>
f0100c33:	68 93 4c 10 f0       	push   $0xf0104c93
f0100c38:	68 40 4c 10 f0       	push   $0xf0104c40
f0100c3d:	68 a4 02 00 00       	push   $0x2a4
f0100c42:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0100c5e:	68 44 44 10 f0       	push   $0xf0104444
f0100c63:	6a 56                	push   $0x56
f0100c65:	68 26 4c 10 f0       	push   $0xf0104c26
f0100c6a:	e8 31 f4 ff ff       	call   f01000a0 <_panic>
f0100c6f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c74:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c77:	76 1e                	jbe    f0100c97 <check_page_free_list+0x238>
f0100c79:	68 28 45 10 f0       	push   $0xf0104528
f0100c7e:	68 40 4c 10 f0       	push   $0xf0104c40
f0100c83:	68 a5 02 00 00       	push   $0x2a5
f0100c88:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0100cac:	68 ad 4c 10 f0       	push   $0xf0104cad
f0100cb1:	68 40 4c 10 f0       	push   $0xf0104c40
f0100cb6:	68 ad 02 00 00       	push   $0x2ad
f0100cbb:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100cc0:	e8 db f3 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100cc5:	85 db                	test   %ebx,%ebx
f0100cc7:	7f 19                	jg     f0100ce2 <check_page_free_list+0x283>
f0100cc9:	68 bf 4c 10 f0       	push   $0xf0104cbf
f0100cce:	68 40 4c 10 f0       	push   $0xf0104c40
f0100cd3:	68 ae 02 00 00       	push   $0x2ae
f0100cd8:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100cdd:	e8 be f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ce2:	83 ec 0c             	sub    $0xc,%esp
f0100ce5:	68 70 45 10 f0       	push   $0xf0104570
f0100cea:	e8 0d 1f 00 00       	call   f0102bfc <cprintf>
}
f0100cef:	eb 29                	jmp    f0100d1a <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cf1:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f0100cf6:	85 c0                	test   %eax,%eax
f0100cf8:	0f 85 8e fd ff ff    	jne    f0100a8c <check_page_free_list+0x2d>
f0100cfe:	e9 72 fd ff ff       	jmp    f0100a75 <check_page_free_list+0x16>
f0100d03:	83 3d 7c ef 16 f0 00 	cmpl   $0x0,0xf016ef7c
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
f0100d2b:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
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
f0100d57:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
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
f0100d7f:	68 68 44 10 f0       	push   $0xf0104468
f0100d84:	68 2c 01 00 00       	push   $0x12c
f0100d89:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100d8e:	e8 0d f3 ff ff       	call   f01000a0 <_panic>
f0100d93:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d98:	39 d8                	cmp    %ebx,%eax
f0100d9a:	76 0e                	jbe    f0100daa <page_init+0x88>
		{
			pages[i].pp_ref = 1;
f0100d9c:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0100da1:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
			continue;
f0100da8:	eb 23                	jmp    f0100dcd <page_init+0xab>
		}
			
		pages[i].pp_ref = 0;  
f0100daa:	89 f0                	mov    %esi,%eax
f0100dac:	03 05 4c fc 16 f0    	add    0xf016fc4c,%eax
f0100db2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100db8:	8b 15 7c ef 16 f0    	mov    0xf016ef7c,%edx
f0100dbe:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100dc0:	89 f0                	mov    %esi,%eax
f0100dc2:	03 05 4c fc 16 f0    	add    0xf016fc4c,%eax
f0100dc8:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages; i++) 
f0100dcd:	83 c7 01             	add    $0x1,%edi
f0100dd0:	83 c6 08             	add    $0x8,%esi
f0100dd3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100dd9:	3b 3d 44 fc 16 f0    	cmp    0xf016fc44,%edi
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
f0100df4:	8b 1d 7c ef 16 f0    	mov    0xf016ef7c,%ebx
f0100dfa:	85 db                	test   %ebx,%ebx
f0100dfc:	74 58                	je     f0100e56 <page_alloc+0x69>

	struct PageInfo *page = NULL;

	page = page_free_list;

	page_free_list = page_free_list->pp_link;
f0100dfe:	8b 03                	mov    (%ebx),%eax
f0100e00:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c

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
f0100e13:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0100e19:	c1 f8 03             	sar    $0x3,%eax
f0100e1c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e1f:	89 c2                	mov    %eax,%edx
f0100e21:	c1 ea 0c             	shr    $0xc,%edx
f0100e24:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0100e2a:	72 12                	jb     f0100e3e <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e2c:	50                   	push   %eax
f0100e2d:	68 44 44 10 f0       	push   $0xf0104444
f0100e32:	6a 56                	push   $0x56
f0100e34:	68 26 4c 10 f0       	push   $0xf0104c26
f0100e39:	e8 62 f2 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(page), '\0', PGSIZE);
f0100e3e:	83 ec 04             	sub    $0x4,%esp
f0100e41:	68 00 10 00 00       	push   $0x1000
f0100e46:	6a 00                	push   $0x0
f0100e48:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e4d:	50                   	push   %eax
f0100e4e:	e8 36 2c 00 00       	call   f0103a89 <memset>
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
f0100e75:	68 94 45 10 f0       	push   $0xf0104594
f0100e7a:	68 63 01 00 00       	push   $0x163
f0100e7f:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0100e84:	e8 17 f2 ff ff       	call   f01000a0 <_panic>
	
	pp->pp_link  = page_free_list;
f0100e89:	8b 15 7c ef 16 f0    	mov    0xf016ef7c,%edx
f0100e8f:	89 10                	mov    %edx,(%eax)

	page_free_list = pp;
f0100e91:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c
	
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
f0100f07:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0100f0d:	c1 fa 03             	sar    $0x3,%edx
f0100f10:	c1 e2 0c             	shl    $0xc,%edx
f0100f13:	83 ca 07             	or     $0x7,%edx
f0100f16:	89 13                	mov    %edx,(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f18:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0100f1e:	c1 f8 03             	sar    $0x3,%eax
f0100f21:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f24:	89 c2                	mov    %eax,%edx
f0100f26:	c1 ea 0c             	shr    $0xc,%edx
f0100f29:	39 15 44 fc 16 f0    	cmp    %edx,0xf016fc44
f0100f2f:	77 15                	ja     f0100f46 <pgdir_walk+0x87>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f31:	50                   	push   %eax
f0100f32:	68 44 44 10 f0       	push   $0xf0104444
f0100f37:	68 a3 01 00 00       	push   $0x1a3
f0100f3c:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0100f57:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0100f5d:	72 15                	jb     f0100f74 <pgdir_walk+0xb5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f5f:	50                   	push   %eax
f0100f60:	68 44 44 10 f0       	push   $0xf0104444
f0100f65:	68 a7 01 00 00       	push   $0x1a7
f0100f6a:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f010101a:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0101020:	72 14                	jb     f0101036 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101022:	83 ec 04             	sub    $0x4,%esp
f0101025:	68 cc 45 10 f0       	push   $0xf01045cc
f010102a:	6a 4f                	push   $0x4f
f010102c:	68 26 4c 10 f0       	push   $0xf0104c26
f0101031:	e8 6a f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0101036:	8b 15 4c fc 16 f0    	mov    0xf016fc4c,%edx
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
f01010d4:	2b 1d 4c fc 16 f0    	sub    0xf016fc4c,%ebx
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
f0101147:	89 15 44 fc 16 f0    	mov    %edx,0xf016fc44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010114d:	89 c2                	mov    %eax,%edx
f010114f:	29 da                	sub    %ebx,%edx
f0101151:	52                   	push   %edx
f0101152:	53                   	push   %ebx
f0101153:	50                   	push   %eax
f0101154:	68 ec 45 10 f0       	push   $0xf01045ec
f0101159:	e8 9e 1a 00 00       	call   f0102bfc <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010115e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101163:	e8 76 f8 ff ff       	call   f01009de <boot_alloc>
f0101168:	a3 48 fc 16 f0       	mov    %eax,0xf016fc48
	memset(kern_pgdir, 0, PGSIZE);
f010116d:	83 c4 0c             	add    $0xc,%esp
f0101170:	68 00 10 00 00       	push   $0x1000
f0101175:	6a 00                	push   $0x0
f0101177:	50                   	push   %eax
f0101178:	e8 0c 29 00 00       	call   f0103a89 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010117d:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
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
f010118d:	68 68 44 10 f0       	push   $0xf0104468
f0101192:	68 a0 00 00 00       	push   $0xa0
f0101197:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01011b0:	a1 44 fc 16 f0       	mov    0xf016fc44,%eax
f01011b5:	c1 e0 03             	shl    $0x3,%eax
f01011b8:	e8 21 f8 ff ff       	call   f01009de <boot_alloc>
f01011bd:	a3 4c fc 16 f0       	mov    %eax,0xf016fc4c
	memset(pages, 0, sizeof(struct PageInfo)*npages);
f01011c2:	83 ec 04             	sub    $0x4,%esp
f01011c5:	8b 3d 44 fc 16 f0    	mov    0xf016fc44,%edi
f01011cb:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01011d2:	52                   	push   %edx
f01011d3:	6a 00                	push   $0x0
f01011d5:	50                   	push   %eax
f01011d6:	e8 ae 28 00 00       	call   f0103a89 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(sizeof(struct Env) * NENV);
f01011db:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011e0:	e8 f9 f7 ff ff       	call   f01009de <boot_alloc>
f01011e5:	a3 84 ef 16 f0       	mov    %eax,0xf016ef84
	memset(envs, 0, sizeof(struct Env) * NENV);
f01011ea:	83 c4 0c             	add    $0xc,%esp
f01011ed:	68 00 80 01 00       	push   $0x18000
f01011f2:	6a 00                	push   $0x0
f01011f4:	50                   	push   %eax
f01011f5:	e8 8f 28 00 00       	call   f0103a89 <memset>
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
f010120c:	83 3d 4c fc 16 f0 00 	cmpl   $0x0,0xf016fc4c
f0101213:	75 17                	jne    f010122c <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f0101215:	83 ec 04             	sub    $0x4,%esp
f0101218:	68 d0 4c 10 f0       	push   $0xf0104cd0
f010121d:	68 c1 02 00 00       	push   $0x2c1
f0101222:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101227:	e8 74 ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010122c:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
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
f0101254:	68 eb 4c 10 f0       	push   $0xf0104ceb
f0101259:	68 40 4c 10 f0       	push   $0xf0104c40
f010125e:	68 c9 02 00 00       	push   $0x2c9
f0101263:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101268:	e8 33 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010126d:	83 ec 0c             	sub    $0xc,%esp
f0101270:	6a 00                	push   $0x0
f0101272:	e8 76 fb ff ff       	call   f0100ded <page_alloc>
f0101277:	89 c6                	mov    %eax,%esi
f0101279:	83 c4 10             	add    $0x10,%esp
f010127c:	85 c0                	test   %eax,%eax
f010127e:	75 19                	jne    f0101299 <mem_init+0x19b>
f0101280:	68 01 4d 10 f0       	push   $0xf0104d01
f0101285:	68 40 4c 10 f0       	push   $0xf0104c40
f010128a:	68 ca 02 00 00       	push   $0x2ca
f010128f:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101294:	e8 07 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101299:	83 ec 0c             	sub    $0xc,%esp
f010129c:	6a 00                	push   $0x0
f010129e:	e8 4a fb ff ff       	call   f0100ded <page_alloc>
f01012a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012a6:	83 c4 10             	add    $0x10,%esp
f01012a9:	85 c0                	test   %eax,%eax
f01012ab:	75 19                	jne    f01012c6 <mem_init+0x1c8>
f01012ad:	68 17 4d 10 f0       	push   $0xf0104d17
f01012b2:	68 40 4c 10 f0       	push   $0xf0104c40
f01012b7:	68 cb 02 00 00       	push   $0x2cb
f01012bc:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01012c1:	e8 da ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012c6:	39 f7                	cmp    %esi,%edi
f01012c8:	75 19                	jne    f01012e3 <mem_init+0x1e5>
f01012ca:	68 2d 4d 10 f0       	push   $0xf0104d2d
f01012cf:	68 40 4c 10 f0       	push   $0xf0104c40
f01012d4:	68 ce 02 00 00       	push   $0x2ce
f01012d9:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01012de:	e8 bd ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012e6:	39 c6                	cmp    %eax,%esi
f01012e8:	74 04                	je     f01012ee <mem_init+0x1f0>
f01012ea:	39 c7                	cmp    %eax,%edi
f01012ec:	75 19                	jne    f0101307 <mem_init+0x209>
f01012ee:	68 28 46 10 f0       	push   $0xf0104628
f01012f3:	68 40 4c 10 f0       	push   $0xf0104c40
f01012f8:	68 cf 02 00 00       	push   $0x2cf
f01012fd:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101302:	e8 99 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101307:	8b 0d 4c fc 16 f0    	mov    0xf016fc4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010130d:	8b 15 44 fc 16 f0    	mov    0xf016fc44,%edx
f0101313:	c1 e2 0c             	shl    $0xc,%edx
f0101316:	89 f8                	mov    %edi,%eax
f0101318:	29 c8                	sub    %ecx,%eax
f010131a:	c1 f8 03             	sar    $0x3,%eax
f010131d:	c1 e0 0c             	shl    $0xc,%eax
f0101320:	39 d0                	cmp    %edx,%eax
f0101322:	72 19                	jb     f010133d <mem_init+0x23f>
f0101324:	68 3f 4d 10 f0       	push   $0xf0104d3f
f0101329:	68 40 4c 10 f0       	push   $0xf0104c40
f010132e:	68 d0 02 00 00       	push   $0x2d0
f0101333:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101338:	e8 63 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010133d:	89 f0                	mov    %esi,%eax
f010133f:	29 c8                	sub    %ecx,%eax
f0101341:	c1 f8 03             	sar    $0x3,%eax
f0101344:	c1 e0 0c             	shl    $0xc,%eax
f0101347:	39 c2                	cmp    %eax,%edx
f0101349:	77 19                	ja     f0101364 <mem_init+0x266>
f010134b:	68 5c 4d 10 f0       	push   $0xf0104d5c
f0101350:	68 40 4c 10 f0       	push   $0xf0104c40
f0101355:	68 d1 02 00 00       	push   $0x2d1
f010135a:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010135f:	e8 3c ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101364:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101367:	29 c8                	sub    %ecx,%eax
f0101369:	c1 f8 03             	sar    $0x3,%eax
f010136c:	c1 e0 0c             	shl    $0xc,%eax
f010136f:	39 c2                	cmp    %eax,%edx
f0101371:	77 19                	ja     f010138c <mem_init+0x28e>
f0101373:	68 79 4d 10 f0       	push   $0xf0104d79
f0101378:	68 40 4c 10 f0       	push   $0xf0104c40
f010137d:	68 d2 02 00 00       	push   $0x2d2
f0101382:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101387:	e8 14 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010138c:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f0101391:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101394:	c7 05 7c ef 16 f0 00 	movl   $0x0,0xf016ef7c
f010139b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010139e:	83 ec 0c             	sub    $0xc,%esp
f01013a1:	6a 00                	push   $0x0
f01013a3:	e8 45 fa ff ff       	call   f0100ded <page_alloc>
f01013a8:	83 c4 10             	add    $0x10,%esp
f01013ab:	85 c0                	test   %eax,%eax
f01013ad:	74 19                	je     f01013c8 <mem_init+0x2ca>
f01013af:	68 96 4d 10 f0       	push   $0xf0104d96
f01013b4:	68 40 4c 10 f0       	push   $0xf0104c40
f01013b9:	68 d9 02 00 00       	push   $0x2d9
f01013be:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01013f9:	68 eb 4c 10 f0       	push   $0xf0104ceb
f01013fe:	68 40 4c 10 f0       	push   $0xf0104c40
f0101403:	68 e0 02 00 00       	push   $0x2e0
f0101408:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010140d:	e8 8e ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101412:	83 ec 0c             	sub    $0xc,%esp
f0101415:	6a 00                	push   $0x0
f0101417:	e8 d1 f9 ff ff       	call   f0100ded <page_alloc>
f010141c:	89 c7                	mov    %eax,%edi
f010141e:	83 c4 10             	add    $0x10,%esp
f0101421:	85 c0                	test   %eax,%eax
f0101423:	75 19                	jne    f010143e <mem_init+0x340>
f0101425:	68 01 4d 10 f0       	push   $0xf0104d01
f010142a:	68 40 4c 10 f0       	push   $0xf0104c40
f010142f:	68 e1 02 00 00       	push   $0x2e1
f0101434:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101439:	e8 62 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010143e:	83 ec 0c             	sub    $0xc,%esp
f0101441:	6a 00                	push   $0x0
f0101443:	e8 a5 f9 ff ff       	call   f0100ded <page_alloc>
f0101448:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	85 c0                	test   %eax,%eax
f0101450:	75 19                	jne    f010146b <mem_init+0x36d>
f0101452:	68 17 4d 10 f0       	push   $0xf0104d17
f0101457:	68 40 4c 10 f0       	push   $0xf0104c40
f010145c:	68 e2 02 00 00       	push   $0x2e2
f0101461:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101466:	e8 35 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010146b:	39 fe                	cmp    %edi,%esi
f010146d:	75 19                	jne    f0101488 <mem_init+0x38a>
f010146f:	68 2d 4d 10 f0       	push   $0xf0104d2d
f0101474:	68 40 4c 10 f0       	push   $0xf0104c40
f0101479:	68 e4 02 00 00       	push   $0x2e4
f010147e:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101483:	e8 18 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101488:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010148b:	39 c7                	cmp    %eax,%edi
f010148d:	74 04                	je     f0101493 <mem_init+0x395>
f010148f:	39 c6                	cmp    %eax,%esi
f0101491:	75 19                	jne    f01014ac <mem_init+0x3ae>
f0101493:	68 28 46 10 f0       	push   $0xf0104628
f0101498:	68 40 4c 10 f0       	push   $0xf0104c40
f010149d:	68 e5 02 00 00       	push   $0x2e5
f01014a2:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01014a7:	e8 f4 eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014ac:	83 ec 0c             	sub    $0xc,%esp
f01014af:	6a 00                	push   $0x0
f01014b1:	e8 37 f9 ff ff       	call   f0100ded <page_alloc>
f01014b6:	83 c4 10             	add    $0x10,%esp
f01014b9:	85 c0                	test   %eax,%eax
f01014bb:	74 19                	je     f01014d6 <mem_init+0x3d8>
f01014bd:	68 96 4d 10 f0       	push   $0xf0104d96
f01014c2:	68 40 4c 10 f0       	push   $0xf0104c40
f01014c7:	68 e6 02 00 00       	push   $0x2e6
f01014cc:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01014d1:	e8 ca eb ff ff       	call   f01000a0 <_panic>
f01014d6:	89 f0                	mov    %esi,%eax
f01014d8:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f01014de:	c1 f8 03             	sar    $0x3,%eax
f01014e1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014e4:	89 c2                	mov    %eax,%edx
f01014e6:	c1 ea 0c             	shr    $0xc,%edx
f01014e9:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f01014ef:	72 12                	jb     f0101503 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f1:	50                   	push   %eax
f01014f2:	68 44 44 10 f0       	push   $0xf0104444
f01014f7:	6a 56                	push   $0x56
f01014f9:	68 26 4c 10 f0       	push   $0xf0104c26
f01014fe:	e8 9d eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101503:	83 ec 04             	sub    $0x4,%esp
f0101506:	68 00 10 00 00       	push   $0x1000
f010150b:	6a 01                	push   $0x1
f010150d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101512:	50                   	push   %eax
f0101513:	e8 71 25 00 00       	call   f0103a89 <memset>
	page_free(pp0);
f0101518:	89 34 24             	mov    %esi,(%esp)
f010151b:	e8 3d f9 ff ff       	call   f0100e5d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101520:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101527:	e8 c1 f8 ff ff       	call   f0100ded <page_alloc>
f010152c:	83 c4 10             	add    $0x10,%esp
f010152f:	85 c0                	test   %eax,%eax
f0101531:	75 19                	jne    f010154c <mem_init+0x44e>
f0101533:	68 a5 4d 10 f0       	push   $0xf0104da5
f0101538:	68 40 4c 10 f0       	push   $0xf0104c40
f010153d:	68 eb 02 00 00       	push   $0x2eb
f0101542:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101547:	e8 54 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010154c:	39 c6                	cmp    %eax,%esi
f010154e:	74 19                	je     f0101569 <mem_init+0x46b>
f0101550:	68 c3 4d 10 f0       	push   $0xf0104dc3
f0101555:	68 40 4c 10 f0       	push   $0xf0104c40
f010155a:	68 ec 02 00 00       	push   $0x2ec
f010155f:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101564:	e8 37 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101569:	89 f0                	mov    %esi,%eax
f010156b:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0101571:	c1 f8 03             	sar    $0x3,%eax
f0101574:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101577:	89 c2                	mov    %eax,%edx
f0101579:	c1 ea 0c             	shr    $0xc,%edx
f010157c:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0101582:	72 12                	jb     f0101596 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101584:	50                   	push   %eax
f0101585:	68 44 44 10 f0       	push   $0xf0104444
f010158a:	6a 56                	push   $0x56
f010158c:	68 26 4c 10 f0       	push   $0xf0104c26
f0101591:	e8 0a eb ff ff       	call   f01000a0 <_panic>
f0101596:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010159c:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015a2:	80 38 00             	cmpb   $0x0,(%eax)
f01015a5:	74 19                	je     f01015c0 <mem_init+0x4c2>
f01015a7:	68 d3 4d 10 f0       	push   $0xf0104dd3
f01015ac:	68 40 4c 10 f0       	push   $0xf0104c40
f01015b1:	68 ef 02 00 00       	push   $0x2ef
f01015b6:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01015ca:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c

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
f01015eb:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
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
f0101602:	68 dd 4d 10 f0       	push   $0xf0104ddd
f0101607:	68 40 4c 10 f0       	push   $0xf0104c40
f010160c:	68 fc 02 00 00       	push   $0x2fc
f0101611:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101616:	e8 85 ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010161b:	83 ec 0c             	sub    $0xc,%esp
f010161e:	68 48 46 10 f0       	push   $0xf0104648
f0101623:	e8 d4 15 00 00       	call   f0102bfc <cprintf>
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
f010163e:	68 eb 4c 10 f0       	push   $0xf0104ceb
f0101643:	68 40 4c 10 f0       	push   $0xf0104c40
f0101648:	68 5a 03 00 00       	push   $0x35a
f010164d:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101652:	e8 49 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101657:	83 ec 0c             	sub    $0xc,%esp
f010165a:	6a 00                	push   $0x0
f010165c:	e8 8c f7 ff ff       	call   f0100ded <page_alloc>
f0101661:	89 c3                	mov    %eax,%ebx
f0101663:	83 c4 10             	add    $0x10,%esp
f0101666:	85 c0                	test   %eax,%eax
f0101668:	75 19                	jne    f0101683 <mem_init+0x585>
f010166a:	68 01 4d 10 f0       	push   $0xf0104d01
f010166f:	68 40 4c 10 f0       	push   $0xf0104c40
f0101674:	68 5b 03 00 00       	push   $0x35b
f0101679:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010167e:	e8 1d ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101683:	83 ec 0c             	sub    $0xc,%esp
f0101686:	6a 00                	push   $0x0
f0101688:	e8 60 f7 ff ff       	call   f0100ded <page_alloc>
f010168d:	89 c6                	mov    %eax,%esi
f010168f:	83 c4 10             	add    $0x10,%esp
f0101692:	85 c0                	test   %eax,%eax
f0101694:	75 19                	jne    f01016af <mem_init+0x5b1>
f0101696:	68 17 4d 10 f0       	push   $0xf0104d17
f010169b:	68 40 4c 10 f0       	push   $0xf0104c40
f01016a0:	68 5c 03 00 00       	push   $0x35c
f01016a5:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01016aa:	e8 f1 e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016af:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016b2:	75 19                	jne    f01016cd <mem_init+0x5cf>
f01016b4:	68 2d 4d 10 f0       	push   $0xf0104d2d
f01016b9:	68 40 4c 10 f0       	push   $0xf0104c40
f01016be:	68 5f 03 00 00       	push   $0x35f
f01016c3:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01016c8:	e8 d3 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016cd:	39 c3                	cmp    %eax,%ebx
f01016cf:	74 05                	je     f01016d6 <mem_init+0x5d8>
f01016d1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016d4:	75 19                	jne    f01016ef <mem_init+0x5f1>
f01016d6:	68 28 46 10 f0       	push   $0xf0104628
f01016db:	68 40 4c 10 f0       	push   $0xf0104c40
f01016e0:	68 60 03 00 00       	push   $0x360
f01016e5:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01016ea:	e8 b1 e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016ef:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f01016f4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016f7:	c7 05 7c ef 16 f0 00 	movl   $0x0,0xf016ef7c
f01016fe:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101701:	83 ec 0c             	sub    $0xc,%esp
f0101704:	6a 00                	push   $0x0
f0101706:	e8 e2 f6 ff ff       	call   f0100ded <page_alloc>
f010170b:	83 c4 10             	add    $0x10,%esp
f010170e:	85 c0                	test   %eax,%eax
f0101710:	74 19                	je     f010172b <mem_init+0x62d>
f0101712:	68 96 4d 10 f0       	push   $0xf0104d96
f0101717:	68 40 4c 10 f0       	push   $0xf0104c40
f010171c:	68 67 03 00 00       	push   $0x367
f0101721:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101726:	e8 75 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010172b:	83 ec 04             	sub    $0x4,%esp
f010172e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101731:	50                   	push   %eax
f0101732:	6a 00                	push   $0x0
f0101734:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f010173a:	e8 b2 f8 ff ff       	call   f0100ff1 <page_lookup>
f010173f:	83 c4 10             	add    $0x10,%esp
f0101742:	85 c0                	test   %eax,%eax
f0101744:	74 19                	je     f010175f <mem_init+0x661>
f0101746:	68 68 46 10 f0       	push   $0xf0104668
f010174b:	68 40 4c 10 f0       	push   $0xf0104c40
f0101750:	68 6a 03 00 00       	push   $0x36a
f0101755:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010175a:	e8 41 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010175f:	6a 02                	push   $0x2
f0101761:	6a 00                	push   $0x0
f0101763:	53                   	push   %ebx
f0101764:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f010176a:	e8 26 f9 ff ff       	call   f0101095 <page_insert>
f010176f:	83 c4 10             	add    $0x10,%esp
f0101772:	85 c0                	test   %eax,%eax
f0101774:	78 19                	js     f010178f <mem_init+0x691>
f0101776:	68 a0 46 10 f0       	push   $0xf01046a0
f010177b:	68 40 4c 10 f0       	push   $0xf0104c40
f0101780:	68 6d 03 00 00       	push   $0x36d
f0101785:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f010179f:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01017a5:	e8 eb f8 ff ff       	call   f0101095 <page_insert>
f01017aa:	83 c4 20             	add    $0x20,%esp
f01017ad:	85 c0                	test   %eax,%eax
f01017af:	74 19                	je     f01017ca <mem_init+0x6cc>
f01017b1:	68 d0 46 10 f0       	push   $0xf01046d0
f01017b6:	68 40 4c 10 f0       	push   $0xf0104c40
f01017bb:	68 71 03 00 00       	push   $0x371
f01017c0:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01017c5:	e8 d6 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017ca:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d0:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
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
f01017f1:	68 00 47 10 f0       	push   $0xf0104700
f01017f6:	68 40 4c 10 f0       	push   $0xf0104c40
f01017fb:	68 72 03 00 00       	push   $0x372
f0101800:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101825:	68 28 47 10 f0       	push   $0xf0104728
f010182a:	68 40 4c 10 f0       	push   $0xf0104c40
f010182f:	68 73 03 00 00       	push   $0x373
f0101834:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101839:	e8 62 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f010183e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101843:	74 19                	je     f010185e <mem_init+0x760>
f0101845:	68 e8 4d 10 f0       	push   $0xf0104de8
f010184a:	68 40 4c 10 f0       	push   $0xf0104c40
f010184f:	68 74 03 00 00       	push   $0x374
f0101854:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101859:	e8 42 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f010185e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101861:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101866:	74 19                	je     f0101881 <mem_init+0x783>
f0101868:	68 f9 4d 10 f0       	push   $0xf0104df9
f010186d:	68 40 4c 10 f0       	push   $0xf0104c40
f0101872:	68 75 03 00 00       	push   $0x375
f0101877:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101896:	68 58 47 10 f0       	push   $0xf0104758
f010189b:	68 40 4c 10 f0       	push   $0xf0104c40
f01018a0:	68 78 03 00 00       	push   $0x378
f01018a5:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01018aa:	e8 f1 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018af:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018b4:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f01018b9:	e8 bc f0 ff ff       	call   f010097a <check_va2pa>
f01018be:	89 f2                	mov    %esi,%edx
f01018c0:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f01018c6:	c1 fa 03             	sar    $0x3,%edx
f01018c9:	c1 e2 0c             	shl    $0xc,%edx
f01018cc:	39 d0                	cmp    %edx,%eax
f01018ce:	74 19                	je     f01018e9 <mem_init+0x7eb>
f01018d0:	68 94 47 10 f0       	push   $0xf0104794
f01018d5:	68 40 4c 10 f0       	push   $0xf0104c40
f01018da:	68 79 03 00 00       	push   $0x379
f01018df:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01018e4:	e8 b7 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018e9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018ee:	74 19                	je     f0101909 <mem_init+0x80b>
f01018f0:	68 0a 4e 10 f0       	push   $0xf0104e0a
f01018f5:	68 40 4c 10 f0       	push   $0xf0104c40
f01018fa:	68 7a 03 00 00       	push   $0x37a
f01018ff:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101904:	e8 97 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101909:	83 ec 0c             	sub    $0xc,%esp
f010190c:	6a 00                	push   $0x0
f010190e:	e8 da f4 ff ff       	call   f0100ded <page_alloc>
f0101913:	83 c4 10             	add    $0x10,%esp
f0101916:	85 c0                	test   %eax,%eax
f0101918:	74 19                	je     f0101933 <mem_init+0x835>
f010191a:	68 96 4d 10 f0       	push   $0xf0104d96
f010191f:	68 40 4c 10 f0       	push   $0xf0104c40
f0101924:	68 7d 03 00 00       	push   $0x37d
f0101929:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010192e:	e8 6d e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101933:	6a 02                	push   $0x2
f0101935:	68 00 10 00 00       	push   $0x1000
f010193a:	56                   	push   %esi
f010193b:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101941:	e8 4f f7 ff ff       	call   f0101095 <page_insert>
f0101946:	83 c4 10             	add    $0x10,%esp
f0101949:	85 c0                	test   %eax,%eax
f010194b:	74 19                	je     f0101966 <mem_init+0x868>
f010194d:	68 58 47 10 f0       	push   $0xf0104758
f0101952:	68 40 4c 10 f0       	push   $0xf0104c40
f0101957:	68 80 03 00 00       	push   $0x380
f010195c:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101961:	e8 3a e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101966:	ba 00 10 00 00       	mov    $0x1000,%edx
f010196b:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0101970:	e8 05 f0 ff ff       	call   f010097a <check_va2pa>
f0101975:	89 f2                	mov    %esi,%edx
f0101977:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f010197d:	c1 fa 03             	sar    $0x3,%edx
f0101980:	c1 e2 0c             	shl    $0xc,%edx
f0101983:	39 d0                	cmp    %edx,%eax
f0101985:	74 19                	je     f01019a0 <mem_init+0x8a2>
f0101987:	68 94 47 10 f0       	push   $0xf0104794
f010198c:	68 40 4c 10 f0       	push   $0xf0104c40
f0101991:	68 81 03 00 00       	push   $0x381
f0101996:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010199b:	e8 00 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019a0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019a5:	74 19                	je     f01019c0 <mem_init+0x8c2>
f01019a7:	68 0a 4e 10 f0       	push   $0xf0104e0a
f01019ac:	68 40 4c 10 f0       	push   $0xf0104c40
f01019b1:	68 82 03 00 00       	push   $0x382
f01019b6:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01019d1:	68 96 4d 10 f0       	push   $0xf0104d96
f01019d6:	68 40 4c 10 f0       	push   $0xf0104c40
f01019db:	68 86 03 00 00       	push   $0x386
f01019e0:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01019e5:	e8 b6 e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019ea:	8b 15 48 fc 16 f0    	mov    0xf016fc48,%edx
f01019f0:	8b 02                	mov    (%edx),%eax
f01019f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019f7:	89 c1                	mov    %eax,%ecx
f01019f9:	c1 e9 0c             	shr    $0xc,%ecx
f01019fc:	3b 0d 44 fc 16 f0    	cmp    0xf016fc44,%ecx
f0101a02:	72 15                	jb     f0101a19 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a04:	50                   	push   %eax
f0101a05:	68 44 44 10 f0       	push   $0xf0104444
f0101a0a:	68 89 03 00 00       	push   $0x389
f0101a0f:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101a3e:	68 c4 47 10 f0       	push   $0xf01047c4
f0101a43:	68 40 4c 10 f0       	push   $0xf0104c40
f0101a48:	68 8a 03 00 00       	push   $0x38a
f0101a4d:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101a52:	e8 49 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a57:	6a 06                	push   $0x6
f0101a59:	68 00 10 00 00       	push   $0x1000
f0101a5e:	56                   	push   %esi
f0101a5f:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101a65:	e8 2b f6 ff ff       	call   f0101095 <page_insert>
f0101a6a:	83 c4 10             	add    $0x10,%esp
f0101a6d:	85 c0                	test   %eax,%eax
f0101a6f:	74 19                	je     f0101a8a <mem_init+0x98c>
f0101a71:	68 04 48 10 f0       	push   $0xf0104804
f0101a76:	68 40 4c 10 f0       	push   $0xf0104c40
f0101a7b:	68 8d 03 00 00       	push   $0x38d
f0101a80:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101a85:	e8 16 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a8a:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101a90:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a95:	89 f8                	mov    %edi,%eax
f0101a97:	e8 de ee ff ff       	call   f010097a <check_va2pa>
f0101a9c:	89 f2                	mov    %esi,%edx
f0101a9e:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0101aa4:	c1 fa 03             	sar    $0x3,%edx
f0101aa7:	c1 e2 0c             	shl    $0xc,%edx
f0101aaa:	39 d0                	cmp    %edx,%eax
f0101aac:	74 19                	je     f0101ac7 <mem_init+0x9c9>
f0101aae:	68 94 47 10 f0       	push   $0xf0104794
f0101ab3:	68 40 4c 10 f0       	push   $0xf0104c40
f0101ab8:	68 8e 03 00 00       	push   $0x38e
f0101abd:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101ac2:	e8 d9 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101ac7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101acc:	74 19                	je     f0101ae7 <mem_init+0x9e9>
f0101ace:	68 0a 4e 10 f0       	push   $0xf0104e0a
f0101ad3:	68 40 4c 10 f0       	push   $0xf0104c40
f0101ad8:	68 8f 03 00 00       	push   $0x38f
f0101add:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101aff:	68 44 48 10 f0       	push   $0xf0104844
f0101b04:	68 40 4c 10 f0       	push   $0xf0104c40
f0101b09:	68 90 03 00 00       	push   $0x390
f0101b0e:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101b13:	e8 88 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b18:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0101b1d:	f6 00 04             	testb  $0x4,(%eax)
f0101b20:	75 19                	jne    f0101b3b <mem_init+0xa3d>
f0101b22:	68 1b 4e 10 f0       	push   $0xf0104e1b
f0101b27:	68 40 4c 10 f0       	push   $0xf0104c40
f0101b2c:	68 91 03 00 00       	push   $0x391
f0101b31:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101b50:	68 58 47 10 f0       	push   $0xf0104758
f0101b55:	68 40 4c 10 f0       	push   $0xf0104c40
f0101b5a:	68 94 03 00 00       	push   $0x394
f0101b5f:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101b64:	e8 37 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b69:	83 ec 04             	sub    $0x4,%esp
f0101b6c:	6a 00                	push   $0x0
f0101b6e:	68 00 10 00 00       	push   $0x1000
f0101b73:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101b79:	e8 41 f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	f6 00 02             	testb  $0x2,(%eax)
f0101b84:	75 19                	jne    f0101b9f <mem_init+0xaa1>
f0101b86:	68 78 48 10 f0       	push   $0xf0104878
f0101b8b:	68 40 4c 10 f0       	push   $0xf0104c40
f0101b90:	68 95 03 00 00       	push   $0x395
f0101b95:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101b9a:	e8 01 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b9f:	83 ec 04             	sub    $0x4,%esp
f0101ba2:	6a 00                	push   $0x0
f0101ba4:	68 00 10 00 00       	push   $0x1000
f0101ba9:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101baf:	e8 0b f3 ff ff       	call   f0100ebf <pgdir_walk>
f0101bb4:	83 c4 10             	add    $0x10,%esp
f0101bb7:	f6 00 04             	testb  $0x4,(%eax)
f0101bba:	74 19                	je     f0101bd5 <mem_init+0xad7>
f0101bbc:	68 ac 48 10 f0       	push   $0xf01048ac
f0101bc1:	68 40 4c 10 f0       	push   $0xf0104c40
f0101bc6:	68 96 03 00 00       	push   $0x396
f0101bcb:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101bd0:	e8 cb e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bd5:	6a 02                	push   $0x2
f0101bd7:	68 00 00 40 00       	push   $0x400000
f0101bdc:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bdf:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101be5:	e8 ab f4 ff ff       	call   f0101095 <page_insert>
f0101bea:	83 c4 10             	add    $0x10,%esp
f0101bed:	85 c0                	test   %eax,%eax
f0101bef:	78 19                	js     f0101c0a <mem_init+0xb0c>
f0101bf1:	68 e4 48 10 f0       	push   $0xf01048e4
f0101bf6:	68 40 4c 10 f0       	push   $0xf0104c40
f0101bfb:	68 99 03 00 00       	push   $0x399
f0101c00:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101c05:	e8 96 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c0a:	6a 02                	push   $0x2
f0101c0c:	68 00 10 00 00       	push   $0x1000
f0101c11:	53                   	push   %ebx
f0101c12:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101c18:	e8 78 f4 ff ff       	call   f0101095 <page_insert>
f0101c1d:	83 c4 10             	add    $0x10,%esp
f0101c20:	85 c0                	test   %eax,%eax
f0101c22:	74 19                	je     f0101c3d <mem_init+0xb3f>
f0101c24:	68 1c 49 10 f0       	push   $0xf010491c
f0101c29:	68 40 4c 10 f0       	push   $0xf0104c40
f0101c2e:	68 9c 03 00 00       	push   $0x39c
f0101c33:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101c38:	e8 63 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c3d:	83 ec 04             	sub    $0x4,%esp
f0101c40:	6a 00                	push   $0x0
f0101c42:	68 00 10 00 00       	push   $0x1000
f0101c47:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101c4d:	e8 6d f2 ff ff       	call   f0100ebf <pgdir_walk>
f0101c52:	83 c4 10             	add    $0x10,%esp
f0101c55:	f6 00 04             	testb  $0x4,(%eax)
f0101c58:	74 19                	je     f0101c73 <mem_init+0xb75>
f0101c5a:	68 ac 48 10 f0       	push   $0xf01048ac
f0101c5f:	68 40 4c 10 f0       	push   $0xf0104c40
f0101c64:	68 9d 03 00 00       	push   $0x39d
f0101c69:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101c6e:	e8 2d e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c73:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101c79:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c7e:	89 f8                	mov    %edi,%eax
f0101c80:	e8 f5 ec ff ff       	call   f010097a <check_va2pa>
f0101c85:	89 c1                	mov    %eax,%ecx
f0101c87:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c8a:	89 d8                	mov    %ebx,%eax
f0101c8c:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0101c92:	c1 f8 03             	sar    $0x3,%eax
f0101c95:	c1 e0 0c             	shl    $0xc,%eax
f0101c98:	39 c1                	cmp    %eax,%ecx
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0xbb7>
f0101c9c:	68 58 49 10 f0       	push   $0xf0104958
f0101ca1:	68 40 4c 10 f0       	push   $0xf0104c40
f0101ca6:	68 a0 03 00 00       	push   $0x3a0
f0101cab:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101cb0:	e8 eb e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cb5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cba:	89 f8                	mov    %edi,%eax
f0101cbc:	e8 b9 ec ff ff       	call   f010097a <check_va2pa>
f0101cc1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xbe1>
f0101cc6:	68 84 49 10 f0       	push   $0xf0104984
f0101ccb:	68 40 4c 10 f0       	push   $0xf0104c40
f0101cd0:	68 a1 03 00 00       	push   $0x3a1
f0101cd5:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101cda:	e8 c1 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cdf:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ce4:	74 19                	je     f0101cff <mem_init+0xc01>
f0101ce6:	68 31 4e 10 f0       	push   $0xf0104e31
f0101ceb:	68 40 4c 10 f0       	push   $0xf0104c40
f0101cf0:	68 a3 03 00 00       	push   $0x3a3
f0101cf5:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101cfa:	e8 a1 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101cff:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d04:	74 19                	je     f0101d1f <mem_init+0xc21>
f0101d06:	68 42 4e 10 f0       	push   $0xf0104e42
f0101d0b:	68 40 4c 10 f0       	push   $0xf0104c40
f0101d10:	68 a4 03 00 00       	push   $0x3a4
f0101d15:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101d34:	68 b4 49 10 f0       	push   $0xf01049b4
f0101d39:	68 40 4c 10 f0       	push   $0xf0104c40
f0101d3e:	68 a7 03 00 00       	push   $0x3a7
f0101d43:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101d48:	e8 53 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d4d:	83 ec 08             	sub    $0x8,%esp
f0101d50:	6a 00                	push   $0x0
f0101d52:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101d58:	e8 ee f2 ff ff       	call   f010104b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d5d:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101d63:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d68:	89 f8                	mov    %edi,%eax
f0101d6a:	e8 0b ec ff ff       	call   f010097a <check_va2pa>
f0101d6f:	83 c4 10             	add    $0x10,%esp
f0101d72:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d75:	74 19                	je     f0101d90 <mem_init+0xc92>
f0101d77:	68 d8 49 10 f0       	push   $0xf01049d8
f0101d7c:	68 40 4c 10 f0       	push   $0xf0104c40
f0101d81:	68 ab 03 00 00       	push   $0x3ab
f0101d86:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101d8b:	e8 10 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d90:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d95:	89 f8                	mov    %edi,%eax
f0101d97:	e8 de eb ff ff       	call   f010097a <check_va2pa>
f0101d9c:	89 da                	mov    %ebx,%edx
f0101d9e:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0101da4:	c1 fa 03             	sar    $0x3,%edx
f0101da7:	c1 e2 0c             	shl    $0xc,%edx
f0101daa:	39 d0                	cmp    %edx,%eax
f0101dac:	74 19                	je     f0101dc7 <mem_init+0xcc9>
f0101dae:	68 84 49 10 f0       	push   $0xf0104984
f0101db3:	68 40 4c 10 f0       	push   $0xf0104c40
f0101db8:	68 ac 03 00 00       	push   $0x3ac
f0101dbd:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101dc2:	e8 d9 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dc7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dcc:	74 19                	je     f0101de7 <mem_init+0xce9>
f0101dce:	68 e8 4d 10 f0       	push   $0xf0104de8
f0101dd3:	68 40 4c 10 f0       	push   $0xf0104c40
f0101dd8:	68 ad 03 00 00       	push   $0x3ad
f0101ddd:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101de2:	e8 b9 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101de7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dec:	74 19                	je     f0101e07 <mem_init+0xd09>
f0101dee:	68 42 4e 10 f0       	push   $0xf0104e42
f0101df3:	68 40 4c 10 f0       	push   $0xf0104c40
f0101df8:	68 ae 03 00 00       	push   $0x3ae
f0101dfd:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101e1c:	68 fc 49 10 f0       	push   $0xf01049fc
f0101e21:	68 40 4c 10 f0       	push   $0xf0104c40
f0101e26:	68 b1 03 00 00       	push   $0x3b1
f0101e2b:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101e30:	e8 6b e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e35:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e3a:	75 19                	jne    f0101e55 <mem_init+0xd57>
f0101e3c:	68 53 4e 10 f0       	push   $0xf0104e53
f0101e41:	68 40 4c 10 f0       	push   $0xf0104c40
f0101e46:	68 b2 03 00 00       	push   $0x3b2
f0101e4b:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101e50:	e8 4b e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e55:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e58:	74 19                	je     f0101e73 <mem_init+0xd75>
f0101e5a:	68 5f 4e 10 f0       	push   $0xf0104e5f
f0101e5f:	68 40 4c 10 f0       	push   $0xf0104c40
f0101e64:	68 b3 03 00 00       	push   $0x3b3
f0101e69:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101e6e:	e8 2d e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e73:	83 ec 08             	sub    $0x8,%esp
f0101e76:	68 00 10 00 00       	push   $0x1000
f0101e7b:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101e81:	e8 c5 f1 ff ff       	call   f010104b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e86:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101e8c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e91:	89 f8                	mov    %edi,%eax
f0101e93:	e8 e2 ea ff ff       	call   f010097a <check_va2pa>
f0101e98:	83 c4 10             	add    $0x10,%esp
f0101e9b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e9e:	74 19                	je     f0101eb9 <mem_init+0xdbb>
f0101ea0:	68 d8 49 10 f0       	push   $0xf01049d8
f0101ea5:	68 40 4c 10 f0       	push   $0xf0104c40
f0101eaa:	68 b7 03 00 00       	push   $0x3b7
f0101eaf:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101eb4:	e8 e7 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eb9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ebe:	89 f8                	mov    %edi,%eax
f0101ec0:	e8 b5 ea ff ff       	call   f010097a <check_va2pa>
f0101ec5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec8:	74 19                	je     f0101ee3 <mem_init+0xde5>
f0101eca:	68 34 4a 10 f0       	push   $0xf0104a34
f0101ecf:	68 40 4c 10 f0       	push   $0xf0104c40
f0101ed4:	68 b8 03 00 00       	push   $0x3b8
f0101ed9:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101ede:	e8 bd e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101ee3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ee8:	74 19                	je     f0101f03 <mem_init+0xe05>
f0101eea:	68 74 4e 10 f0       	push   $0xf0104e74
f0101eef:	68 40 4c 10 f0       	push   $0xf0104c40
f0101ef4:	68 b9 03 00 00       	push   $0x3b9
f0101ef9:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101efe:	e8 9d e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f03:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f08:	74 19                	je     f0101f23 <mem_init+0xe25>
f0101f0a:	68 42 4e 10 f0       	push   $0xf0104e42
f0101f0f:	68 40 4c 10 f0       	push   $0xf0104c40
f0101f14:	68 ba 03 00 00       	push   $0x3ba
f0101f19:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101f38:	68 5c 4a 10 f0       	push   $0xf0104a5c
f0101f3d:	68 40 4c 10 f0       	push   $0xf0104c40
f0101f42:	68 bd 03 00 00       	push   $0x3bd
f0101f47:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101f4c:	e8 4f e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f51:	83 ec 0c             	sub    $0xc,%esp
f0101f54:	6a 00                	push   $0x0
f0101f56:	e8 92 ee ff ff       	call   f0100ded <page_alloc>
f0101f5b:	83 c4 10             	add    $0x10,%esp
f0101f5e:	85 c0                	test   %eax,%eax
f0101f60:	74 19                	je     f0101f7b <mem_init+0xe7d>
f0101f62:	68 96 4d 10 f0       	push   $0xf0104d96
f0101f67:	68 40 4c 10 f0       	push   $0xf0104c40
f0101f6c:	68 c0 03 00 00       	push   $0x3c0
f0101f71:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101f76:	e8 25 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f7b:	8b 0d 48 fc 16 f0    	mov    0xf016fc48,%ecx
f0101f81:	8b 11                	mov    (%ecx),%edx
f0101f83:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f8c:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0101f92:	c1 f8 03             	sar    $0x3,%eax
f0101f95:	c1 e0 0c             	shl    $0xc,%eax
f0101f98:	39 c2                	cmp    %eax,%edx
f0101f9a:	74 19                	je     f0101fb5 <mem_init+0xeb7>
f0101f9c:	68 00 47 10 f0       	push   $0xf0104700
f0101fa1:	68 40 4c 10 f0       	push   $0xf0104c40
f0101fa6:	68 c3 03 00 00       	push   $0x3c3
f0101fab:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0101fb0:	e8 eb e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101fb5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fbb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fbe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fc3:	74 19                	je     f0101fde <mem_init+0xee0>
f0101fc5:	68 f9 4d 10 f0       	push   $0xf0104df9
f0101fca:	68 40 4c 10 f0       	push   $0xf0104c40
f0101fcf:	68 c5 03 00 00       	push   $0x3c5
f0101fd4:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0101ffa:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0102000:	e8 ba ee ff ff       	call   f0100ebf <pgdir_walk>
f0102005:	89 c7                	mov    %eax,%edi
f0102007:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010200a:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f010200f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102012:	8b 40 04             	mov    0x4(%eax),%eax
f0102015:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010201a:	8b 0d 44 fc 16 f0    	mov    0xf016fc44,%ecx
f0102020:	89 c2                	mov    %eax,%edx
f0102022:	c1 ea 0c             	shr    $0xc,%edx
f0102025:	83 c4 10             	add    $0x10,%esp
f0102028:	39 ca                	cmp    %ecx,%edx
f010202a:	72 15                	jb     f0102041 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010202c:	50                   	push   %eax
f010202d:	68 44 44 10 f0       	push   $0xf0104444
f0102032:	68 cc 03 00 00       	push   $0x3cc
f0102037:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010203c:	e8 5f e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102041:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102046:	39 c7                	cmp    %eax,%edi
f0102048:	74 19                	je     f0102063 <mem_init+0xf65>
f010204a:	68 85 4e 10 f0       	push   $0xf0104e85
f010204f:	68 40 4c 10 f0       	push   $0xf0104c40
f0102054:	68 cd 03 00 00       	push   $0x3cd
f0102059:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0102076:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
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
f010208c:	68 44 44 10 f0       	push   $0xf0104444
f0102091:	6a 56                	push   $0x56
f0102093:	68 26 4c 10 f0       	push   $0xf0104c26
f0102098:	e8 03 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010209d:	83 ec 04             	sub    $0x4,%esp
f01020a0:	68 00 10 00 00       	push   $0x1000
f01020a5:	68 ff 00 00 00       	push   $0xff
f01020aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020af:	50                   	push   %eax
f01020b0:	e8 d4 19 00 00       	call   f0103a89 <memset>
	page_free(pp0);
f01020b5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020b8:	89 3c 24             	mov    %edi,(%esp)
f01020bb:	e8 9d ed ff ff       	call   f0100e5d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020c0:	83 c4 0c             	add    $0xc,%esp
f01020c3:	6a 01                	push   $0x1
f01020c5:	6a 00                	push   $0x0
f01020c7:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01020cd:	e8 ed ed ff ff       	call   f0100ebf <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020d2:	89 fa                	mov    %edi,%edx
f01020d4:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
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
f01020e8:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f01020ee:	72 12                	jb     f0102102 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020f0:	52                   	push   %edx
f01020f1:	68 44 44 10 f0       	push   $0xf0104444
f01020f6:	6a 56                	push   $0x56
f01020f8:	68 26 4c 10 f0       	push   $0xf0104c26
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
f0102116:	68 9d 4e 10 f0       	push   $0xf0104e9d
f010211b:	68 40 4c 10 f0       	push   $0xf0104c40
f0102120:	68 d7 03 00 00       	push   $0x3d7
f0102125:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0102136:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f010213b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102141:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102144:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010214a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010214d:	89 3d 7c ef 16 f0    	mov    %edi,0xf016ef7c

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
f010216c:	c7 04 24 b4 4e 10 f0 	movl   $0xf0104eb4,(%esp)
f0102173:	e8 84 0a 00 00       	call   f0102bfc <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), (PTE_P | PTE_W));
f0102178:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
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
f0102188:	68 68 44 10 f0       	push   $0xf0104468
f010218d:	68 c8 00 00 00       	push   $0xc8
f0102192:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0102197:	e8 04 df ff ff       	call   f01000a0 <_panic>
f010219c:	83 ec 08             	sub    $0x8,%esp
f010219f:	6a 03                	push   $0x3
f01021a1:	05 00 00 00 10       	add    $0x10000000,%eax
f01021a6:	50                   	push   %eax
f01021a7:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01021ac:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021b1:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f01021b6:	e8 d6 ed ff ff       	call   f0100f91 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(sizeof(struct Env)*NENV, PGSIZE), PADDR(envs), (PTE_P | PTE_W));
f01021bb:	a1 84 ef 16 f0       	mov    0xf016ef84,%eax
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
f01021cb:	68 68 44 10 f0       	push   $0xf0104468
f01021d0:	68 d2 00 00 00       	push   $0xd2
f01021d5:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01021da:	e8 c1 de ff ff       	call   f01000a0 <_panic>
f01021df:	83 ec 08             	sub    $0x8,%esp
f01021e2:	6a 03                	push   $0x3
f01021e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01021e9:	50                   	push   %eax
f01021ea:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021ef:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021f4:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f01021f9:	e8 93 ed ff ff       	call   f0100f91 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021fe:	83 c4 10             	add    $0x10,%esp
f0102201:	b8 00 f0 10 f0       	mov    $0xf010f000,%eax
f0102206:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010220b:	77 15                	ja     f0102222 <mem_init+0x1124>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010220d:	50                   	push   %eax
f010220e:	68 68 44 10 f0       	push   $0xf0104468
f0102213:	68 df 00 00 00       	push   $0xdf
f0102218:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010221d:	e8 7e de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102222:	83 ec 08             	sub    $0x8,%esp
f0102225:	6a 02                	push   $0x2
f0102227:	68 00 f0 10 00       	push   $0x10f000
f010222c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102231:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102236:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
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
f0102251:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0102256:	e8 36 ed ff ff       	call   f0100f91 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010225b:	8b 1d 48 fc 16 f0    	mov    0xf016fc48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102261:	a1 44 fc 16 f0       	mov    0xf016fc44,%eax
f0102266:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102269:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102270:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102275:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102278:	8b 3d 4c fc 16 f0    	mov    0xf016fc4c,%edi
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
f01022a2:	68 68 44 10 f0       	push   $0xf0104468
f01022a7:	68 14 03 00 00       	push   $0x314
f01022ac:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01022b1:	e8 ea dd ff ff       	call   f01000a0 <_panic>
f01022b6:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022bd:	39 d0                	cmp    %edx,%eax
f01022bf:	74 19                	je     f01022da <mem_init+0x11dc>
f01022c1:	68 80 4a 10 f0       	push   $0xf0104a80
f01022c6:	68 40 4c 10 f0       	push   $0xf0104c40
f01022cb:	68 14 03 00 00       	push   $0x314
f01022d0:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01022e5:	8b 3d 84 ef 16 f0    	mov    0xf016ef84,%edi
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
f0102306:	68 68 44 10 f0       	push   $0xf0104468
f010230b:	68 19 03 00 00       	push   $0x319
f0102310:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0102315:	e8 86 dd ff ff       	call   f01000a0 <_panic>
f010231a:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102321:	39 c2                	cmp    %eax,%edx
f0102323:	74 19                	je     f010233e <mem_init+0x1240>
f0102325:	68 b4 4a 10 f0       	push   $0xf0104ab4
f010232a:	68 40 4c 10 f0       	push   $0xf0104c40
f010232f:	68 19 03 00 00       	push   $0x319
f0102334:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f010236a:	68 e8 4a 10 f0       	push   $0xf0104ae8
f010236f:	68 40 4c 10 f0       	push   $0xf0104c40
f0102374:	68 1d 03 00 00       	push   $0x31d
f0102379:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f010239b:	8d 96 00 70 11 10    	lea    0x10117000(%esi),%edx
f01023a1:	39 c2                	cmp    %eax,%edx
f01023a3:	74 19                	je     f01023be <mem_init+0x12c0>
f01023a5:	68 10 4b 10 f0       	push   $0xf0104b10
f01023aa:	68 40 4c 10 f0       	push   $0xf0104c40
f01023af:	68 21 03 00 00       	push   $0x321
f01023b4:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01023dd:	68 58 4b 10 f0       	push   $0xf0104b58
f01023e2:	68 40 4c 10 f0       	push   $0xf0104c40
f01023e7:	68 22 03 00 00       	push   $0x322
f01023ec:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0102415:	68 cd 4e 10 f0       	push   $0xf0104ecd
f010241a:	68 40 4c 10 f0       	push   $0xf0104c40
f010241f:	68 2b 03 00 00       	push   $0x32b
f0102424:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0102442:	68 cd 4e 10 f0       	push   $0xf0104ecd
f0102447:	68 40 4c 10 f0       	push   $0xf0104c40
f010244c:	68 2f 03 00 00       	push   $0x32f
f0102451:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0102456:	e8 45 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010245b:	f6 c2 02             	test   $0x2,%dl
f010245e:	75 38                	jne    f0102498 <mem_init+0x139a>
f0102460:	68 de 4e 10 f0       	push   $0xf0104ede
f0102465:	68 40 4c 10 f0       	push   $0xf0104c40
f010246a:	68 30 03 00 00       	push   $0x330
f010246f:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0102474:	e8 27 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102479:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010247d:	74 19                	je     f0102498 <mem_init+0x139a>
f010247f:	68 ef 4e 10 f0       	push   $0xf0104eef
f0102484:	68 40 4c 10 f0       	push   $0xf0104c40
f0102489:	68 32 03 00 00       	push   $0x332
f010248e:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01024a9:	68 88 4b 10 f0       	push   $0xf0104b88
f01024ae:	e8 49 07 00 00       	call   f0102bfc <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024b3:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
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
f01024c3:	68 68 44 10 f0       	push   $0xf0104468
f01024c8:	68 f3 00 00 00       	push   $0xf3
f01024cd:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f010250a:	68 eb 4c 10 f0       	push   $0xf0104ceb
f010250f:	68 40 4c 10 f0       	push   $0xf0104c40
f0102514:	68 f2 03 00 00       	push   $0x3f2
f0102519:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010251e:	e8 7d db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102523:	83 ec 0c             	sub    $0xc,%esp
f0102526:	6a 00                	push   $0x0
f0102528:	e8 c0 e8 ff ff       	call   f0100ded <page_alloc>
f010252d:	89 c6                	mov    %eax,%esi
f010252f:	83 c4 10             	add    $0x10,%esp
f0102532:	85 c0                	test   %eax,%eax
f0102534:	75 19                	jne    f010254f <mem_init+0x1451>
f0102536:	68 01 4d 10 f0       	push   $0xf0104d01
f010253b:	68 40 4c 10 f0       	push   $0xf0104c40
f0102540:	68 f3 03 00 00       	push   $0x3f3
f0102545:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010254a:	e8 51 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010254f:	83 ec 0c             	sub    $0xc,%esp
f0102552:	6a 00                	push   $0x0
f0102554:	e8 94 e8 ff ff       	call   f0100ded <page_alloc>
f0102559:	89 c3                	mov    %eax,%ebx
f010255b:	83 c4 10             	add    $0x10,%esp
f010255e:	85 c0                	test   %eax,%eax
f0102560:	75 19                	jne    f010257b <mem_init+0x147d>
f0102562:	68 17 4d 10 f0       	push   $0xf0104d17
f0102567:	68 40 4c 10 f0       	push   $0xf0104c40
f010256c:	68 f4 03 00 00       	push   $0x3f4
f0102571:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f0102586:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
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
f010259a:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f01025a0:	72 12                	jb     f01025b4 <mem_init+0x14b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025a2:	50                   	push   %eax
f01025a3:	68 44 44 10 f0       	push   $0xf0104444
f01025a8:	6a 56                	push   $0x56
f01025aa:	68 26 4c 10 f0       	push   $0xf0104c26
f01025af:	e8 ec da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025b4:	83 ec 04             	sub    $0x4,%esp
f01025b7:	68 00 10 00 00       	push   $0x1000
f01025bc:	6a 01                	push   $0x1
f01025be:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025c3:	50                   	push   %eax
f01025c4:	e8 c0 14 00 00       	call   f0103a89 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025c9:	89 d8                	mov    %ebx,%eax
f01025cb:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
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
f01025df:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f01025e5:	72 12                	jb     f01025f9 <mem_init+0x14fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025e7:	50                   	push   %eax
f01025e8:	68 44 44 10 f0       	push   $0xf0104444
f01025ed:	6a 56                	push   $0x56
f01025ef:	68 26 4c 10 f0       	push   $0xf0104c26
f01025f4:	e8 a7 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025f9:	83 ec 04             	sub    $0x4,%esp
f01025fc:	68 00 10 00 00       	push   $0x1000
f0102601:	6a 02                	push   $0x2
f0102603:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102608:	50                   	push   %eax
f0102609:	e8 7b 14 00 00       	call   f0103a89 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010260e:	6a 02                	push   $0x2
f0102610:	68 00 10 00 00       	push   $0x1000
f0102615:	56                   	push   %esi
f0102616:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f010261c:	e8 74 ea ff ff       	call   f0101095 <page_insert>
	assert(pp1->pp_ref == 1);
f0102621:	83 c4 20             	add    $0x20,%esp
f0102624:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102629:	74 19                	je     f0102644 <mem_init+0x1546>
f010262b:	68 e8 4d 10 f0       	push   $0xf0104de8
f0102630:	68 40 4c 10 f0       	push   $0xf0104c40
f0102635:	68 f9 03 00 00       	push   $0x3f9
f010263a:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010263f:	e8 5c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102644:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010264b:	01 01 01 
f010264e:	74 19                	je     f0102669 <mem_init+0x156b>
f0102650:	68 a8 4b 10 f0       	push   $0xf0104ba8
f0102655:	68 40 4c 10 f0       	push   $0xf0104c40
f010265a:	68 fa 03 00 00       	push   $0x3fa
f010265f:	68 1a 4c 10 f0       	push   $0xf0104c1a
f0102664:	e8 37 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102669:	6a 02                	push   $0x2
f010266b:	68 00 10 00 00       	push   $0x1000
f0102670:	53                   	push   %ebx
f0102671:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0102677:	e8 19 ea ff ff       	call   f0101095 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010267c:	83 c4 10             	add    $0x10,%esp
f010267f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102686:	02 02 02 
f0102689:	74 19                	je     f01026a4 <mem_init+0x15a6>
f010268b:	68 cc 4b 10 f0       	push   $0xf0104bcc
f0102690:	68 40 4c 10 f0       	push   $0xf0104c40
f0102695:	68 fc 03 00 00       	push   $0x3fc
f010269a:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010269f:	e8 fc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026a4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026a9:	74 19                	je     f01026c4 <mem_init+0x15c6>
f01026ab:	68 0a 4e 10 f0       	push   $0xf0104e0a
f01026b0:	68 40 4c 10 f0       	push   $0xf0104c40
f01026b5:	68 fd 03 00 00       	push   $0x3fd
f01026ba:	68 1a 4c 10 f0       	push   $0xf0104c1a
f01026bf:	e8 dc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026c4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026c9:	74 19                	je     f01026e4 <mem_init+0x15e6>
f01026cb:	68 74 4e 10 f0       	push   $0xf0104e74
f01026d0:	68 40 4c 10 f0       	push   $0xf0104c40
f01026d5:	68 fe 03 00 00       	push   $0x3fe
f01026da:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
f01026f0:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f01026f6:	c1 f8 03             	sar    $0x3,%eax
f01026f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026fc:	89 c2                	mov    %eax,%edx
f01026fe:	c1 ea 0c             	shr    $0xc,%edx
f0102701:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0102707:	72 12                	jb     f010271b <mem_init+0x161d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102709:	50                   	push   %eax
f010270a:	68 44 44 10 f0       	push   $0xf0104444
f010270f:	6a 56                	push   $0x56
f0102711:	68 26 4c 10 f0       	push   $0xf0104c26
f0102716:	e8 85 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010271b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102722:	03 03 03 
f0102725:	74 19                	je     f0102740 <mem_init+0x1642>
f0102727:	68 f0 4b 10 f0       	push   $0xf0104bf0
f010272c:	68 40 4c 10 f0       	push   $0xf0104c40
f0102731:	68 00 04 00 00       	push   $0x400
f0102736:	68 1a 4c 10 f0       	push   $0xf0104c1a
f010273b:	e8 60 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102740:	83 ec 08             	sub    $0x8,%esp
f0102743:	68 00 10 00 00       	push   $0x1000
f0102748:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f010274e:	e8 f8 e8 ff ff       	call   f010104b <page_remove>
	assert(pp2->pp_ref == 0);
f0102753:	83 c4 10             	add    $0x10,%esp
f0102756:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010275b:	74 19                	je     f0102776 <mem_init+0x1678>
f010275d:	68 42 4e 10 f0       	push   $0xf0104e42
f0102762:	68 40 4c 10 f0       	push   $0xf0104c40
f0102767:	68 02 04 00 00       	push   $0x402
f010276c:	68 1a 4c 10 f0       	push   $0xf0104c1a
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
	// LAB 3: Your code here.

	return 0;
}
f010278c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102791:	5d                   	pop    %ebp
f0102792:	c3                   	ret    

f0102793 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102793:	55                   	push   %ebp
f0102794:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102796:	5d                   	pop    %ebp
f0102797:	c3                   	ret    

f0102798 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102798:	55                   	push   %ebp
f0102799:	89 e5                	mov    %esp,%ebp
f010279b:	8b 55 08             	mov    0x8(%ebp),%edx
f010279e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01027a1:	85 d2                	test   %edx,%edx
f01027a3:	75 11                	jne    f01027b6 <envid2env+0x1e>
		*env_store = curenv;
f01027a5:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f01027aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01027ad:	89 01                	mov    %eax,(%ecx)
		return 0;
f01027af:	b8 00 00 00 00       	mov    $0x0,%eax
f01027b4:	eb 5e                	jmp    f0102814 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01027b6:	89 d0                	mov    %edx,%eax
f01027b8:	25 ff 03 00 00       	and    $0x3ff,%eax
f01027bd:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01027c0:	c1 e0 05             	shl    $0x5,%eax
f01027c3:	03 05 84 ef 16 f0    	add    0xf016ef84,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01027c9:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01027cd:	74 05                	je     f01027d4 <envid2env+0x3c>
f01027cf:	3b 50 48             	cmp    0x48(%eax),%edx
f01027d2:	74 10                	je     f01027e4 <envid2env+0x4c>
		*env_store = 0;
f01027d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027d7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01027dd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027e2:	eb 30                	jmp    f0102814 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01027e4:	84 c9                	test   %cl,%cl
f01027e6:	74 22                	je     f010280a <envid2env+0x72>
f01027e8:	8b 15 80 ef 16 f0    	mov    0xf016ef80,%edx
f01027ee:	39 d0                	cmp    %edx,%eax
f01027f0:	74 18                	je     f010280a <envid2env+0x72>
f01027f2:	8b 4a 48             	mov    0x48(%edx),%ecx
f01027f5:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01027f8:	74 10                	je     f010280a <envid2env+0x72>
		*env_store = 0;
f01027fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027fd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102803:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102808:	eb 0a                	jmp    f0102814 <envid2env+0x7c>
	}

	*env_store = e;
f010280a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010280d:	89 01                	mov    %eax,(%ecx)
	return 0;
f010280f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102814:	5d                   	pop    %ebp
f0102815:	c3                   	ret    

f0102816 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102816:	55                   	push   %ebp
f0102817:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102819:	b8 00 93 11 f0       	mov    $0xf0119300,%eax
f010281e:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102821:	b8 23 00 00 00       	mov    $0x23,%eax
f0102826:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102828:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010282a:	b8 10 00 00 00       	mov    $0x10,%eax
f010282f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102831:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102833:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102835:	ea 3c 28 10 f0 08 00 	ljmp   $0x8,$0xf010283c
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f010283c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102841:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102844:	5d                   	pop    %ebp
f0102845:	c3                   	ret    

f0102846 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102846:	55                   	push   %ebp
f0102847:	89 e5                	mov    %esp,%ebp
	// Set up envs array
	// LAB 3: Your code here.

	// Per-CPU part of the initialization
	env_init_percpu();
f0102849:	e8 c8 ff ff ff       	call   f0102816 <env_init_percpu>
}
f010284e:	5d                   	pop    %ebp
f010284f:	c3                   	ret    

f0102850 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102850:	55                   	push   %ebp
f0102851:	89 e5                	mov    %esp,%ebp
f0102853:	53                   	push   %ebx
f0102854:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102857:	8b 1d 88 ef 16 f0    	mov    0xf016ef88,%ebx
f010285d:	85 db                	test   %ebx,%ebx
f010285f:	0f 84 f4 00 00 00    	je     f0102959 <env_alloc+0x109>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102865:	83 ec 0c             	sub    $0xc,%esp
f0102868:	6a 01                	push   $0x1
f010286a:	e8 7e e5 ff ff       	call   f0100ded <page_alloc>
f010286f:	83 c4 10             	add    $0x10,%esp
f0102872:	85 c0                	test   %eax,%eax
f0102874:	0f 84 e6 00 00 00    	je     f0102960 <env_alloc+0x110>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010287a:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010287d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102882:	77 15                	ja     f0102899 <env_alloc+0x49>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102884:	50                   	push   %eax
f0102885:	68 68 44 10 f0       	push   $0xf0104468
f010288a:	68 b9 00 00 00       	push   $0xb9
f010288f:	68 36 4f 10 f0       	push   $0xf0104f36
f0102894:	e8 07 d8 ff ff       	call   f01000a0 <_panic>
f0102899:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010289f:	83 ca 05             	or     $0x5,%edx
f01028a2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01028a8:	8b 43 48             	mov    0x48(%ebx),%eax
f01028ab:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01028b0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01028b5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01028ba:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01028bd:	89 da                	mov    %ebx,%edx
f01028bf:	2b 15 84 ef 16 f0    	sub    0xf016ef84,%edx
f01028c5:	c1 fa 05             	sar    $0x5,%edx
f01028c8:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01028ce:	09 d0                	or     %edx,%eax
f01028d0:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01028d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028d6:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01028d9:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01028e0:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01028e7:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01028ee:	83 ec 04             	sub    $0x4,%esp
f01028f1:	6a 44                	push   $0x44
f01028f3:	6a 00                	push   $0x0
f01028f5:	53                   	push   %ebx
f01028f6:	e8 8e 11 00 00       	call   f0103a89 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01028fb:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102901:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102907:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010290d:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102914:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f010291a:	8b 43 44             	mov    0x44(%ebx),%eax
f010291d:	a3 88 ef 16 f0       	mov    %eax,0xf016ef88
	*newenv_store = e;
f0102922:	8b 45 08             	mov    0x8(%ebp),%eax
f0102925:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102927:	8b 53 48             	mov    0x48(%ebx),%edx
f010292a:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f010292f:	83 c4 10             	add    $0x10,%esp
f0102932:	85 c0                	test   %eax,%eax
f0102934:	74 05                	je     f010293b <env_alloc+0xeb>
f0102936:	8b 40 48             	mov    0x48(%eax),%eax
f0102939:	eb 05                	jmp    f0102940 <env_alloc+0xf0>
f010293b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102940:	83 ec 04             	sub    $0x4,%esp
f0102943:	52                   	push   %edx
f0102944:	50                   	push   %eax
f0102945:	68 41 4f 10 f0       	push   $0xf0104f41
f010294a:	e8 ad 02 00 00       	call   f0102bfc <cprintf>
	return 0;
f010294f:	83 c4 10             	add    $0x10,%esp
f0102952:	b8 00 00 00 00       	mov    $0x0,%eax
f0102957:	eb 0c                	jmp    f0102965 <env_alloc+0x115>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102959:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010295e:	eb 05                	jmp    f0102965 <env_alloc+0x115>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102960:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102965:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102968:	c9                   	leave  
f0102969:	c3                   	ret    

f010296a <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010296a:	55                   	push   %ebp
f010296b:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f010296d:	5d                   	pop    %ebp
f010296e:	c3                   	ret    

f010296f <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010296f:	55                   	push   %ebp
f0102970:	89 e5                	mov    %esp,%ebp
f0102972:	57                   	push   %edi
f0102973:	56                   	push   %esi
f0102974:	53                   	push   %ebx
f0102975:	83 ec 1c             	sub    $0x1c,%esp
f0102978:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010297b:	8b 15 80 ef 16 f0    	mov    0xf016ef80,%edx
f0102981:	39 fa                	cmp    %edi,%edx
f0102983:	75 29                	jne    f01029ae <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102985:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010298a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010298f:	77 15                	ja     f01029a6 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102991:	50                   	push   %eax
f0102992:	68 68 44 10 f0       	push   $0xf0104468
f0102997:	68 68 01 00 00       	push   $0x168
f010299c:	68 36 4f 10 f0       	push   $0xf0104f36
f01029a1:	e8 fa d6 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01029a6:	05 00 00 00 10       	add    $0x10000000,%eax
f01029ab:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01029ae:	8b 4f 48             	mov    0x48(%edi),%ecx
f01029b1:	85 d2                	test   %edx,%edx
f01029b3:	74 05                	je     f01029ba <env_free+0x4b>
f01029b5:	8b 42 48             	mov    0x48(%edx),%eax
f01029b8:	eb 05                	jmp    f01029bf <env_free+0x50>
f01029ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01029bf:	83 ec 04             	sub    $0x4,%esp
f01029c2:	51                   	push   %ecx
f01029c3:	50                   	push   %eax
f01029c4:	68 56 4f 10 f0       	push   $0xf0104f56
f01029c9:	e8 2e 02 00 00       	call   f0102bfc <cprintf>
f01029ce:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01029d1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01029d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01029db:	89 d0                	mov    %edx,%eax
f01029dd:	c1 e0 02             	shl    $0x2,%eax
f01029e0:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01029e3:	8b 47 5c             	mov    0x5c(%edi),%eax
f01029e6:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01029e9:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01029ef:	0f 84 a8 00 00 00    	je     f0102a9d <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01029f5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029fb:	89 f0                	mov    %esi,%eax
f01029fd:	c1 e8 0c             	shr    $0xc,%eax
f0102a00:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a03:	39 05 44 fc 16 f0    	cmp    %eax,0xf016fc44
f0102a09:	77 15                	ja     f0102a20 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a0b:	56                   	push   %esi
f0102a0c:	68 44 44 10 f0       	push   $0xf0104444
f0102a11:	68 77 01 00 00       	push   $0x177
f0102a16:	68 36 4f 10 f0       	push   $0xf0104f36
f0102a1b:	e8 80 d6 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102a20:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a23:	c1 e0 16             	shl    $0x16,%eax
f0102a26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102a29:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102a2e:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102a35:	01 
f0102a36:	74 17                	je     f0102a4f <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102a38:	83 ec 08             	sub    $0x8,%esp
f0102a3b:	89 d8                	mov    %ebx,%eax
f0102a3d:	c1 e0 0c             	shl    $0xc,%eax
f0102a40:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102a43:	50                   	push   %eax
f0102a44:	ff 77 5c             	pushl  0x5c(%edi)
f0102a47:	e8 ff e5 ff ff       	call   f010104b <page_remove>
f0102a4c:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102a4f:	83 c3 01             	add    $0x1,%ebx
f0102a52:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102a58:	75 d4                	jne    f0102a2e <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102a5a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102a5d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a60:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a67:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102a6a:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0102a70:	72 14                	jb     f0102a86 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102a72:	83 ec 04             	sub    $0x4,%esp
f0102a75:	68 cc 45 10 f0       	push   $0xf01045cc
f0102a7a:	6a 4f                	push   $0x4f
f0102a7c:	68 26 4c 10 f0       	push   $0xf0104c26
f0102a81:	e8 1a d6 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102a86:	83 ec 0c             	sub    $0xc,%esp
f0102a89:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0102a8e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a91:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102a94:	50                   	push   %eax
f0102a95:	e8 fe e3 ff ff       	call   f0100e98 <page_decref>
f0102a9a:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102a9d:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102aa1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102aa4:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102aa9:	0f 85 29 ff ff ff    	jne    f01029d8 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102aaf:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ab2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ab7:	77 15                	ja     f0102ace <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ab9:	50                   	push   %eax
f0102aba:	68 68 44 10 f0       	push   $0xf0104468
f0102abf:	68 85 01 00 00       	push   $0x185
f0102ac4:	68 36 4f 10 f0       	push   $0xf0104f36
f0102ac9:	e8 d2 d5 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102ace:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ad5:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ada:	c1 e8 0c             	shr    $0xc,%eax
f0102add:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0102ae3:	72 14                	jb     f0102af9 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102ae5:	83 ec 04             	sub    $0x4,%esp
f0102ae8:	68 cc 45 10 f0       	push   $0xf01045cc
f0102aed:	6a 4f                	push   $0x4f
f0102aef:	68 26 4c 10 f0       	push   $0xf0104c26
f0102af4:	e8 a7 d5 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102af9:	83 ec 0c             	sub    $0xc,%esp
f0102afc:	8b 15 4c fc 16 f0    	mov    0xf016fc4c,%edx
f0102b02:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102b05:	50                   	push   %eax
f0102b06:	e8 8d e3 ff ff       	call   f0100e98 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102b0b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102b12:	a1 88 ef 16 f0       	mov    0xf016ef88,%eax
f0102b17:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102b1a:	89 3d 88 ef 16 f0    	mov    %edi,0xf016ef88
}
f0102b20:	83 c4 10             	add    $0x10,%esp
f0102b23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b26:	5b                   	pop    %ebx
f0102b27:	5e                   	pop    %esi
f0102b28:	5f                   	pop    %edi
f0102b29:	5d                   	pop    %ebp
f0102b2a:	c3                   	ret    

f0102b2b <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102b2b:	55                   	push   %ebp
f0102b2c:	89 e5                	mov    %esp,%ebp
f0102b2e:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102b31:	ff 75 08             	pushl  0x8(%ebp)
f0102b34:	e8 36 fe ff ff       	call   f010296f <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102b39:	c7 04 24 00 4f 10 f0 	movl   $0xf0104f00,(%esp)
f0102b40:	e8 b7 00 00 00       	call   f0102bfc <cprintf>
f0102b45:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102b48:	83 ec 0c             	sub    $0xc,%esp
f0102b4b:	6a 00                	push   $0x0
f0102b4d:	e8 b7 dc ff ff       	call   f0100809 <monitor>
f0102b52:	83 c4 10             	add    $0x10,%esp
f0102b55:	eb f1                	jmp    f0102b48 <env_destroy+0x1d>

f0102b57 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102b57:	55                   	push   %ebp
f0102b58:	89 e5                	mov    %esp,%ebp
f0102b5a:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102b5d:	8b 65 08             	mov    0x8(%ebp),%esp
f0102b60:	61                   	popa   
f0102b61:	07                   	pop    %es
f0102b62:	1f                   	pop    %ds
f0102b63:	83 c4 08             	add    $0x8,%esp
f0102b66:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102b67:	68 6c 4f 10 f0       	push   $0xf0104f6c
f0102b6c:	68 ae 01 00 00       	push   $0x1ae
f0102b71:	68 36 4f 10 f0       	push   $0xf0104f36
f0102b76:	e8 25 d5 ff ff       	call   f01000a0 <_panic>

f0102b7b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102b7b:	55                   	push   %ebp
f0102b7c:	89 e5                	mov    %esp,%ebp
f0102b7e:	83 ec 0c             	sub    $0xc,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0102b81:	68 78 4f 10 f0       	push   $0xf0104f78
f0102b86:	68 cd 01 00 00       	push   $0x1cd
f0102b8b:	68 36 4f 10 f0       	push   $0xf0104f36
f0102b90:	e8 0b d5 ff ff       	call   f01000a0 <_panic>

f0102b95 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102b95:	55                   	push   %ebp
f0102b96:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102b98:	ba 70 00 00 00       	mov    $0x70,%edx
f0102b9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ba0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ba1:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ba6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ba7:	0f b6 c0             	movzbl %al,%eax
}
f0102baa:	5d                   	pop    %ebp
f0102bab:	c3                   	ret    

f0102bac <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102bac:	55                   	push   %ebp
f0102bad:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102baf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102bb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bb7:	ee                   	out    %al,(%dx)
f0102bb8:	ba 71 00 00 00       	mov    $0x71,%edx
f0102bbd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bc0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102bc1:	5d                   	pop    %ebp
f0102bc2:	c3                   	ret    

f0102bc3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102bc3:	55                   	push   %ebp
f0102bc4:	89 e5                	mov    %esp,%ebp
f0102bc6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102bc9:	ff 75 08             	pushl  0x8(%ebp)
f0102bcc:	e8 44 da ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102bd1:	83 c4 10             	add    $0x10,%esp
f0102bd4:	c9                   	leave  
f0102bd5:	c3                   	ret    

f0102bd6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102bd6:	55                   	push   %ebp
f0102bd7:	89 e5                	mov    %esp,%ebp
f0102bd9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102bdc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102be3:	ff 75 0c             	pushl  0xc(%ebp)
f0102be6:	ff 75 08             	pushl  0x8(%ebp)
f0102be9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102bec:	50                   	push   %eax
f0102bed:	68 c3 2b 10 f0       	push   $0xf0102bc3
f0102bf2:	e8 26 08 00 00       	call   f010341d <vprintfmt>
	return cnt;
}
f0102bf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102bfa:	c9                   	leave  
f0102bfb:	c3                   	ret    

f0102bfc <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102bfc:	55                   	push   %ebp
f0102bfd:	89 e5                	mov    %esp,%ebp
f0102bff:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102c02:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102c05:	50                   	push   %eax
f0102c06:	ff 75 08             	pushl  0x8(%ebp)
f0102c09:	e8 c8 ff ff ff       	call   f0102bd6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102c0e:	c9                   	leave  
f0102c0f:	c3                   	ret    

f0102c10 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102c10:	55                   	push   %ebp
f0102c11:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102c13:	b8 c0 f7 16 f0       	mov    $0xf016f7c0,%eax
f0102c18:	c7 05 c4 f7 16 f0 00 	movl   $0xf0000000,0xf016f7c4
f0102c1f:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102c22:	66 c7 05 c8 f7 16 f0 	movw   $0x10,0xf016f7c8
f0102c29:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0102c2b:	66 c7 05 26 f8 16 f0 	movw   $0x68,0xf016f826
f0102c32:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102c34:	66 c7 05 48 93 11 f0 	movw   $0x67,0xf0119348
f0102c3b:	67 00 
f0102c3d:	66 a3 4a 93 11 f0    	mov    %ax,0xf011934a
f0102c43:	89 c2                	mov    %eax,%edx
f0102c45:	c1 ea 10             	shr    $0x10,%edx
f0102c48:	88 15 4c 93 11 f0    	mov    %dl,0xf011934c
f0102c4e:	c6 05 4e 93 11 f0 40 	movb   $0x40,0xf011934e
f0102c55:	c1 e8 18             	shr    $0x18,%eax
f0102c58:	a2 4f 93 11 f0       	mov    %al,0xf011934f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102c5d:	c6 05 4d 93 11 f0 89 	movb   $0x89,0xf011934d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102c64:	b8 28 00 00 00       	mov    $0x28,%eax
f0102c69:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102c6c:	b8 50 93 11 f0       	mov    $0xf0119350,%eax
f0102c71:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102c74:	5d                   	pop    %ebp
f0102c75:	c3                   	ret    

f0102c76 <trap_init>:
}


void
trap_init(void)
{
f0102c76:	55                   	push   %ebp
f0102c77:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102c79:	e8 92 ff ff ff       	call   f0102c10 <trap_init_percpu>
}
f0102c7e:	5d                   	pop    %ebp
f0102c7f:	c3                   	ret    

f0102c80 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102c80:	55                   	push   %ebp
f0102c81:	89 e5                	mov    %esp,%ebp
f0102c83:	53                   	push   %ebx
f0102c84:	83 ec 0c             	sub    $0xc,%esp
f0102c87:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102c8a:	ff 33                	pushl  (%ebx)
f0102c8c:	68 94 4f 10 f0       	push   $0xf0104f94
f0102c91:	e8 66 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102c96:	83 c4 08             	add    $0x8,%esp
f0102c99:	ff 73 04             	pushl  0x4(%ebx)
f0102c9c:	68 a3 4f 10 f0       	push   $0xf0104fa3
f0102ca1:	e8 56 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102ca6:	83 c4 08             	add    $0x8,%esp
f0102ca9:	ff 73 08             	pushl  0x8(%ebx)
f0102cac:	68 b2 4f 10 f0       	push   $0xf0104fb2
f0102cb1:	e8 46 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102cb6:	83 c4 08             	add    $0x8,%esp
f0102cb9:	ff 73 0c             	pushl  0xc(%ebx)
f0102cbc:	68 c1 4f 10 f0       	push   $0xf0104fc1
f0102cc1:	e8 36 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102cc6:	83 c4 08             	add    $0x8,%esp
f0102cc9:	ff 73 10             	pushl  0x10(%ebx)
f0102ccc:	68 d0 4f 10 f0       	push   $0xf0104fd0
f0102cd1:	e8 26 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102cd6:	83 c4 08             	add    $0x8,%esp
f0102cd9:	ff 73 14             	pushl  0x14(%ebx)
f0102cdc:	68 df 4f 10 f0       	push   $0xf0104fdf
f0102ce1:	e8 16 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102ce6:	83 c4 08             	add    $0x8,%esp
f0102ce9:	ff 73 18             	pushl  0x18(%ebx)
f0102cec:	68 ee 4f 10 f0       	push   $0xf0104fee
f0102cf1:	e8 06 ff ff ff       	call   f0102bfc <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102cf6:	83 c4 08             	add    $0x8,%esp
f0102cf9:	ff 73 1c             	pushl  0x1c(%ebx)
f0102cfc:	68 fd 4f 10 f0       	push   $0xf0104ffd
f0102d01:	e8 f6 fe ff ff       	call   f0102bfc <cprintf>
}
f0102d06:	83 c4 10             	add    $0x10,%esp
f0102d09:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d0c:	c9                   	leave  
f0102d0d:	c3                   	ret    

f0102d0e <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102d0e:	55                   	push   %ebp
f0102d0f:	89 e5                	mov    %esp,%ebp
f0102d11:	56                   	push   %esi
f0102d12:	53                   	push   %ebx
f0102d13:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102d16:	83 ec 08             	sub    $0x8,%esp
f0102d19:	53                   	push   %ebx
f0102d1a:	68 33 51 10 f0       	push   $0xf0105133
f0102d1f:	e8 d8 fe ff ff       	call   f0102bfc <cprintf>
	print_regs(&tf->tf_regs);
f0102d24:	89 1c 24             	mov    %ebx,(%esp)
f0102d27:	e8 54 ff ff ff       	call   f0102c80 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102d2c:	83 c4 08             	add    $0x8,%esp
f0102d2f:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102d33:	50                   	push   %eax
f0102d34:	68 4e 50 10 f0       	push   $0xf010504e
f0102d39:	e8 be fe ff ff       	call   f0102bfc <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102d3e:	83 c4 08             	add    $0x8,%esp
f0102d41:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102d45:	50                   	push   %eax
f0102d46:	68 61 50 10 f0       	push   $0xf0105061
f0102d4b:	e8 ac fe ff ff       	call   f0102bfc <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102d50:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102d53:	83 c4 10             	add    $0x10,%esp
f0102d56:	83 f8 13             	cmp    $0x13,%eax
f0102d59:	77 09                	ja     f0102d64 <print_trapframe+0x56>
		return excnames[trapno];
f0102d5b:	8b 14 85 00 53 10 f0 	mov    -0xfefad00(,%eax,4),%edx
f0102d62:	eb 10                	jmp    f0102d74 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102d64:	83 f8 30             	cmp    $0x30,%eax
f0102d67:	b9 18 50 10 f0       	mov    $0xf0105018,%ecx
f0102d6c:	ba 0c 50 10 f0       	mov    $0xf010500c,%edx
f0102d71:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102d74:	83 ec 04             	sub    $0x4,%esp
f0102d77:	52                   	push   %edx
f0102d78:	50                   	push   %eax
f0102d79:	68 74 50 10 f0       	push   $0xf0105074
f0102d7e:	e8 79 fe ff ff       	call   f0102bfc <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102d83:	83 c4 10             	add    $0x10,%esp
f0102d86:	3b 1d a0 f7 16 f0    	cmp    0xf016f7a0,%ebx
f0102d8c:	75 1a                	jne    f0102da8 <print_trapframe+0x9a>
f0102d8e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102d92:	75 14                	jne    f0102da8 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102d94:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102d97:	83 ec 08             	sub    $0x8,%esp
f0102d9a:	50                   	push   %eax
f0102d9b:	68 86 50 10 f0       	push   $0xf0105086
f0102da0:	e8 57 fe ff ff       	call   f0102bfc <cprintf>
f0102da5:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102da8:	83 ec 08             	sub    $0x8,%esp
f0102dab:	ff 73 2c             	pushl  0x2c(%ebx)
f0102dae:	68 95 50 10 f0       	push   $0xf0105095
f0102db3:	e8 44 fe ff ff       	call   f0102bfc <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102db8:	83 c4 10             	add    $0x10,%esp
f0102dbb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102dbf:	75 49                	jne    f0102e0a <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102dc1:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102dc4:	89 c2                	mov    %eax,%edx
f0102dc6:	83 e2 01             	and    $0x1,%edx
f0102dc9:	ba 32 50 10 f0       	mov    $0xf0105032,%edx
f0102dce:	b9 27 50 10 f0       	mov    $0xf0105027,%ecx
f0102dd3:	0f 44 ca             	cmove  %edx,%ecx
f0102dd6:	89 c2                	mov    %eax,%edx
f0102dd8:	83 e2 02             	and    $0x2,%edx
f0102ddb:	ba 44 50 10 f0       	mov    $0xf0105044,%edx
f0102de0:	be 3e 50 10 f0       	mov    $0xf010503e,%esi
f0102de5:	0f 45 d6             	cmovne %esi,%edx
f0102de8:	83 e0 04             	and    $0x4,%eax
f0102deb:	be 5e 51 10 f0       	mov    $0xf010515e,%esi
f0102df0:	b8 49 50 10 f0       	mov    $0xf0105049,%eax
f0102df5:	0f 44 c6             	cmove  %esi,%eax
f0102df8:	51                   	push   %ecx
f0102df9:	52                   	push   %edx
f0102dfa:	50                   	push   %eax
f0102dfb:	68 a3 50 10 f0       	push   $0xf01050a3
f0102e00:	e8 f7 fd ff ff       	call   f0102bfc <cprintf>
f0102e05:	83 c4 10             	add    $0x10,%esp
f0102e08:	eb 10                	jmp    f0102e1a <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102e0a:	83 ec 0c             	sub    $0xc,%esp
f0102e0d:	68 5c 42 10 f0       	push   $0xf010425c
f0102e12:	e8 e5 fd ff ff       	call   f0102bfc <cprintf>
f0102e17:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102e1a:	83 ec 08             	sub    $0x8,%esp
f0102e1d:	ff 73 30             	pushl  0x30(%ebx)
f0102e20:	68 b2 50 10 f0       	push   $0xf01050b2
f0102e25:	e8 d2 fd ff ff       	call   f0102bfc <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102e2a:	83 c4 08             	add    $0x8,%esp
f0102e2d:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102e31:	50                   	push   %eax
f0102e32:	68 c1 50 10 f0       	push   $0xf01050c1
f0102e37:	e8 c0 fd ff ff       	call   f0102bfc <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102e3c:	83 c4 08             	add    $0x8,%esp
f0102e3f:	ff 73 38             	pushl  0x38(%ebx)
f0102e42:	68 d4 50 10 f0       	push   $0xf01050d4
f0102e47:	e8 b0 fd ff ff       	call   f0102bfc <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102e4c:	83 c4 10             	add    $0x10,%esp
f0102e4f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102e53:	74 25                	je     f0102e7a <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102e55:	83 ec 08             	sub    $0x8,%esp
f0102e58:	ff 73 3c             	pushl  0x3c(%ebx)
f0102e5b:	68 e3 50 10 f0       	push   $0xf01050e3
f0102e60:	e8 97 fd ff ff       	call   f0102bfc <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102e65:	83 c4 08             	add    $0x8,%esp
f0102e68:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102e6c:	50                   	push   %eax
f0102e6d:	68 f2 50 10 f0       	push   $0xf01050f2
f0102e72:	e8 85 fd ff ff       	call   f0102bfc <cprintf>
f0102e77:	83 c4 10             	add    $0x10,%esp
	}
}
f0102e7a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102e7d:	5b                   	pop    %ebx
f0102e7e:	5e                   	pop    %esi
f0102e7f:	5d                   	pop    %ebp
f0102e80:	c3                   	ret    

f0102e81 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102e81:	55                   	push   %ebp
f0102e82:	89 e5                	mov    %esp,%ebp
f0102e84:	57                   	push   %edi
f0102e85:	56                   	push   %esi
f0102e86:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0102e89:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0102e8a:	9c                   	pushf  
f0102e8b:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0102e8c:	f6 c4 02             	test   $0x2,%ah
f0102e8f:	74 19                	je     f0102eaa <trap+0x29>
f0102e91:	68 05 51 10 f0       	push   $0xf0105105
f0102e96:	68 40 4c 10 f0       	push   $0xf0104c40
f0102e9b:	68 a8 00 00 00       	push   $0xa8
f0102ea0:	68 1e 51 10 f0       	push   $0xf010511e
f0102ea5:	e8 f6 d1 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0102eaa:	83 ec 08             	sub    $0x8,%esp
f0102ead:	56                   	push   %esi
f0102eae:	68 2a 51 10 f0       	push   $0xf010512a
f0102eb3:	e8 44 fd ff ff       	call   f0102bfc <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0102eb8:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0102ebc:	83 e0 03             	and    $0x3,%eax
f0102ebf:	83 c4 10             	add    $0x10,%esp
f0102ec2:	66 83 f8 03          	cmp    $0x3,%ax
f0102ec6:	75 31                	jne    f0102ef9 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0102ec8:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102ecd:	85 c0                	test   %eax,%eax
f0102ecf:	75 19                	jne    f0102eea <trap+0x69>
f0102ed1:	68 45 51 10 f0       	push   $0xf0105145
f0102ed6:	68 40 4c 10 f0       	push   $0xf0104c40
f0102edb:	68 ae 00 00 00       	push   $0xae
f0102ee0:	68 1e 51 10 f0       	push   $0xf010511e
f0102ee5:	e8 b6 d1 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0102eea:	b9 11 00 00 00       	mov    $0x11,%ecx
f0102eef:	89 c7                	mov    %eax,%edi
f0102ef1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0102ef3:	8b 35 80 ef 16 f0    	mov    0xf016ef80,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0102ef9:	89 35 a0 f7 16 f0    	mov    %esi,0xf016f7a0
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0102eff:	83 ec 0c             	sub    $0xc,%esp
f0102f02:	56                   	push   %esi
f0102f03:	e8 06 fe ff ff       	call   f0102d0e <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0102f08:	83 c4 10             	add    $0x10,%esp
f0102f0b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0102f10:	75 17                	jne    f0102f29 <trap+0xa8>
		panic("unhandled trap in kernel");
f0102f12:	83 ec 04             	sub    $0x4,%esp
f0102f15:	68 4c 51 10 f0       	push   $0xf010514c
f0102f1a:	68 97 00 00 00       	push   $0x97
f0102f1f:	68 1e 51 10 f0       	push   $0xf010511e
f0102f24:	e8 77 d1 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0102f29:	83 ec 0c             	sub    $0xc,%esp
f0102f2c:	ff 35 80 ef 16 f0    	pushl  0xf016ef80
f0102f32:	e8 f4 fb ff ff       	call   f0102b2b <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0102f37:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102f3c:	83 c4 10             	add    $0x10,%esp
f0102f3f:	85 c0                	test   %eax,%eax
f0102f41:	74 06                	je     f0102f49 <trap+0xc8>
f0102f43:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102f47:	74 19                	je     f0102f62 <trap+0xe1>
f0102f49:	68 a8 52 10 f0       	push   $0xf01052a8
f0102f4e:	68 40 4c 10 f0       	push   $0xf0104c40
f0102f53:	68 c0 00 00 00       	push   $0xc0
f0102f58:	68 1e 51 10 f0       	push   $0xf010511e
f0102f5d:	e8 3e d1 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0102f62:	83 ec 0c             	sub    $0xc,%esp
f0102f65:	50                   	push   %eax
f0102f66:	e8 10 fc ff ff       	call   f0102b7b <env_run>

f0102f6b <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0102f6b:	55                   	push   %ebp
f0102f6c:	89 e5                	mov    %esp,%ebp
f0102f6e:	53                   	push   %ebx
f0102f6f:	83 ec 04             	sub    $0x4,%esp
f0102f72:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102f75:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0102f78:	ff 73 30             	pushl  0x30(%ebx)
f0102f7b:	50                   	push   %eax
f0102f7c:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102f81:	ff 70 48             	pushl  0x48(%eax)
f0102f84:	68 d4 52 10 f0       	push   $0xf01052d4
f0102f89:	e8 6e fc ff ff       	call   f0102bfc <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0102f8e:	89 1c 24             	mov    %ebx,(%esp)
f0102f91:	e8 78 fd ff ff       	call   f0102d0e <print_trapframe>
	env_destroy(curenv);
f0102f96:	83 c4 04             	add    $0x4,%esp
f0102f99:	ff 35 80 ef 16 f0    	pushl  0xf016ef80
f0102f9f:	e8 87 fb ff ff       	call   f0102b2b <env_destroy>
}
f0102fa4:	83 c4 10             	add    $0x10,%esp
f0102fa7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102faa:	c9                   	leave  
f0102fab:	c3                   	ret    

f0102fac <syscall>:
f0102fac:	55                   	push   %ebp
f0102fad:	89 e5                	mov    %esp,%ebp
f0102faf:	83 ec 0c             	sub    $0xc,%esp
f0102fb2:	68 50 53 10 f0       	push   $0xf0105350
f0102fb7:	6a 49                	push   $0x49
f0102fb9:	68 68 53 10 f0       	push   $0xf0105368
f0102fbe:	e8 dd d0 ff ff       	call   f01000a0 <_panic>

f0102fc3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102fc3:	55                   	push   %ebp
f0102fc4:	89 e5                	mov    %esp,%ebp
f0102fc6:	57                   	push   %edi
f0102fc7:	56                   	push   %esi
f0102fc8:	53                   	push   %ebx
f0102fc9:	83 ec 14             	sub    $0x14,%esp
f0102fcc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fcf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102fd2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102fd5:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102fd8:	8b 1a                	mov    (%edx),%ebx
f0102fda:	8b 01                	mov    (%ecx),%eax
f0102fdc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fdf:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102fe6:	eb 7f                	jmp    f0103067 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102fe8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102feb:	01 d8                	add    %ebx,%eax
f0102fed:	89 c6                	mov    %eax,%esi
f0102fef:	c1 ee 1f             	shr    $0x1f,%esi
f0102ff2:	01 c6                	add    %eax,%esi
f0102ff4:	d1 fe                	sar    %esi
f0102ff6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102ff9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102ffc:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102fff:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103001:	eb 03                	jmp    f0103006 <stab_binsearch+0x43>
			m--;
f0103003:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103006:	39 c3                	cmp    %eax,%ebx
f0103008:	7f 0d                	jg     f0103017 <stab_binsearch+0x54>
f010300a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010300e:	83 ea 0c             	sub    $0xc,%edx
f0103011:	39 f9                	cmp    %edi,%ecx
f0103013:	75 ee                	jne    f0103003 <stab_binsearch+0x40>
f0103015:	eb 05                	jmp    f010301c <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103017:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010301a:	eb 4b                	jmp    f0103067 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010301c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010301f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103022:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103026:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103029:	76 11                	jbe    f010303c <stab_binsearch+0x79>
			*region_left = m;
f010302b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010302e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103030:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103033:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010303a:	eb 2b                	jmp    f0103067 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010303c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010303f:	73 14                	jae    f0103055 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103041:	83 e8 01             	sub    $0x1,%eax
f0103044:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103047:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010304a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010304c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103053:	eb 12                	jmp    f0103067 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103055:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103058:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010305a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010305e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103060:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103067:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010306a:	0f 8e 78 ff ff ff    	jle    f0102fe8 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103070:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103074:	75 0f                	jne    f0103085 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103076:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103079:	8b 00                	mov    (%eax),%eax
f010307b:	83 e8 01             	sub    $0x1,%eax
f010307e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103081:	89 06                	mov    %eax,(%esi)
f0103083:	eb 2c                	jmp    f01030b1 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103085:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103088:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010308a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010308d:	8b 0e                	mov    (%esi),%ecx
f010308f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103092:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103095:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103098:	eb 03                	jmp    f010309d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010309a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010309d:	39 c8                	cmp    %ecx,%eax
f010309f:	7e 0b                	jle    f01030ac <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01030a1:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01030a5:	83 ea 0c             	sub    $0xc,%edx
f01030a8:	39 df                	cmp    %ebx,%edi
f01030aa:	75 ee                	jne    f010309a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01030ac:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01030af:	89 06                	mov    %eax,(%esi)
	}
}
f01030b1:	83 c4 14             	add    $0x14,%esp
f01030b4:	5b                   	pop    %ebx
f01030b5:	5e                   	pop    %esi
f01030b6:	5f                   	pop    %edi
f01030b7:	5d                   	pop    %ebp
f01030b8:	c3                   	ret    

f01030b9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01030b9:	55                   	push   %ebp
f01030ba:	89 e5                	mov    %esp,%ebp
f01030bc:	57                   	push   %edi
f01030bd:	56                   	push   %esi
f01030be:	53                   	push   %ebx
f01030bf:	83 ec 3c             	sub    $0x3c,%esp
f01030c2:	8b 75 08             	mov    0x8(%ebp),%esi
f01030c5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01030c8:	c7 03 77 53 10 f0    	movl   $0xf0105377,(%ebx)
	info->eip_line = 0;
f01030ce:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01030d5:	c7 43 08 77 53 10 f0 	movl   $0xf0105377,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01030dc:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01030e3:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01030e6:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01030ed:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01030f3:	77 21                	ja     f0103116 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01030f5:	a1 00 00 20 00       	mov    0x200000,%eax
f01030fa:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f01030fd:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103102:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103108:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010310b:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103111:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103114:	eb 1a                	jmp    f0103130 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103116:	c7 45 c0 13 ef 10 f0 	movl   $0xf010ef13,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010311d:	c7 45 b8 8d c5 10 f0 	movl   $0xf010c58d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103124:	b8 8c c5 10 f0       	mov    $0xf010c58c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103129:	c7 45 bc 90 55 10 f0 	movl   $0xf0105590,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103130:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103133:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103136:	0f 83 95 01 00 00    	jae    f01032d1 <debuginfo_eip+0x218>
f010313c:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103140:	0f 85 92 01 00 00    	jne    f01032d8 <debuginfo_eip+0x21f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103146:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010314d:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103150:	29 f8                	sub    %edi,%eax
f0103152:	c1 f8 02             	sar    $0x2,%eax
f0103155:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010315b:	83 e8 01             	sub    $0x1,%eax
f010315e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103161:	56                   	push   %esi
f0103162:	6a 64                	push   $0x64
f0103164:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103167:	89 c1                	mov    %eax,%ecx
f0103169:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010316c:	89 f8                	mov    %edi,%eax
f010316e:	e8 50 fe ff ff       	call   f0102fc3 <stab_binsearch>
	if (lfile == 0)
f0103173:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103176:	83 c4 08             	add    $0x8,%esp
f0103179:	85 c0                	test   %eax,%eax
f010317b:	0f 84 5e 01 00 00    	je     f01032df <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103181:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103184:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103187:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010318a:	56                   	push   %esi
f010318b:	6a 24                	push   $0x24
f010318d:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103190:	89 c1                	mov    %eax,%ecx
f0103192:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103195:	89 f8                	mov    %edi,%eax
f0103197:	e8 27 fe ff ff       	call   f0102fc3 <stab_binsearch>

	if (lfun <= rfun) {
f010319c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010319f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01031a2:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01031a5:	83 c4 08             	add    $0x8,%esp
f01031a8:	39 d0                	cmp    %edx,%eax
f01031aa:	7f 2b                	jg     f01031d7 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01031ac:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031af:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f01031b2:	8b 11                	mov    (%ecx),%edx
f01031b4:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01031b7:	2b 7d b8             	sub    -0x48(%ebp),%edi
f01031ba:	39 fa                	cmp    %edi,%edx
f01031bc:	73 06                	jae    f01031c4 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01031be:	03 55 b8             	add    -0x48(%ebp),%edx
f01031c1:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01031c4:	8b 51 08             	mov    0x8(%ecx),%edx
f01031c7:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01031ca:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01031cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01031cf:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01031d2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01031d5:	eb 0f                	jmp    f01031e6 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01031d7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01031da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01031e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01031e6:	83 ec 08             	sub    $0x8,%esp
f01031e9:	6a 3a                	push   $0x3a
f01031eb:	ff 73 08             	pushl  0x8(%ebx)
f01031ee:	e8 7a 08 00 00       	call   f0103a6d <strfind>
f01031f3:	2b 43 08             	sub    0x8(%ebx),%eax
f01031f6:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01031f9:	83 c4 08             	add    $0x8,%esp
f01031fc:	56                   	push   %esi
f01031fd:	6a 44                	push   $0x44
f01031ff:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103202:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103205:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103208:	89 f0                	mov    %esi,%eax
f010320a:	e8 b4 fd ff ff       	call   f0102fc3 <stab_binsearch>
	
	if(lline > rline)
f010320f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103212:	83 c4 10             	add    $0x10,%esp
f0103215:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103218:	0f 8f c8 00 00 00    	jg     f01032e6 <debuginfo_eip+0x22d>
	{
		return -1;
	}
	else
	{
		info->eip_line = stabs[lline].n_desc;
f010321e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103221:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103224:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103228:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010322b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010322e:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103232:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103235:	eb 0a                	jmp    f0103241 <debuginfo_eip+0x188>
f0103237:	83 e8 01             	sub    $0x1,%eax
f010323a:	83 ea 0c             	sub    $0xc,%edx
f010323d:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103241:	39 c7                	cmp    %eax,%edi
f0103243:	7e 05                	jle    f010324a <debuginfo_eip+0x191>
f0103245:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103248:	eb 47                	jmp    f0103291 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f010324a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010324e:	80 f9 84             	cmp    $0x84,%cl
f0103251:	75 0e                	jne    f0103261 <debuginfo_eip+0x1a8>
f0103253:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103256:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010325a:	74 1c                	je     f0103278 <debuginfo_eip+0x1bf>
f010325c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010325f:	eb 17                	jmp    f0103278 <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103261:	80 f9 64             	cmp    $0x64,%cl
f0103264:	75 d1                	jne    f0103237 <debuginfo_eip+0x17e>
f0103266:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010326a:	74 cb                	je     f0103237 <debuginfo_eip+0x17e>
f010326c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010326f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103273:	74 03                	je     f0103278 <debuginfo_eip+0x1bf>
f0103275:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103278:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010327b:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010327e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103281:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103284:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103287:	29 f0                	sub    %esi,%eax
f0103289:	39 c2                	cmp    %eax,%edx
f010328b:	73 04                	jae    f0103291 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010328d:	01 f2                	add    %esi,%edx
f010328f:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103291:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103294:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103297:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010329c:	39 f2                	cmp    %esi,%edx
f010329e:	7d 52                	jge    f01032f2 <debuginfo_eip+0x239>
		for (lline = lfun + 1;
f01032a0:	83 c2 01             	add    $0x1,%edx
f01032a3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01032a6:	89 d0                	mov    %edx,%eax
f01032a8:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01032ab:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01032ae:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01032b1:	eb 04                	jmp    f01032b7 <debuginfo_eip+0x1fe>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01032b3:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01032b7:	39 c6                	cmp    %eax,%esi
f01032b9:	7e 32                	jle    f01032ed <debuginfo_eip+0x234>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01032bb:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01032bf:	83 c0 01             	add    $0x1,%eax
f01032c2:	83 c2 0c             	add    $0xc,%edx
f01032c5:	80 f9 a0             	cmp    $0xa0,%cl
f01032c8:	74 e9                	je     f01032b3 <debuginfo_eip+0x1fa>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01032cf:	eb 21                	jmp    f01032f2 <debuginfo_eip+0x239>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01032d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032d6:	eb 1a                	jmp    f01032f2 <debuginfo_eip+0x239>
f01032d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032dd:	eb 13                	jmp    f01032f2 <debuginfo_eip+0x239>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01032df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032e4:	eb 0c                	jmp    f01032f2 <debuginfo_eip+0x239>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline > rline)
	{
		return -1;
f01032e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032eb:	eb 05                	jmp    f01032f2 <debuginfo_eip+0x239>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032f5:	5b                   	pop    %ebx
f01032f6:	5e                   	pop    %esi
f01032f7:	5f                   	pop    %edi
f01032f8:	5d                   	pop    %ebp
f01032f9:	c3                   	ret    

f01032fa <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01032fa:	55                   	push   %ebp
f01032fb:	89 e5                	mov    %esp,%ebp
f01032fd:	57                   	push   %edi
f01032fe:	56                   	push   %esi
f01032ff:	53                   	push   %ebx
f0103300:	83 ec 1c             	sub    $0x1c,%esp
f0103303:	89 c7                	mov    %eax,%edi
f0103305:	89 d6                	mov    %edx,%esi
f0103307:	8b 45 08             	mov    0x8(%ebp),%eax
f010330a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010330d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103310:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103313:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103316:	bb 00 00 00 00       	mov    $0x0,%ebx
f010331b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010331e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103321:	39 d3                	cmp    %edx,%ebx
f0103323:	72 05                	jb     f010332a <printnum+0x30>
f0103325:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103328:	77 45                	ja     f010336f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010332a:	83 ec 0c             	sub    $0xc,%esp
f010332d:	ff 75 18             	pushl  0x18(%ebp)
f0103330:	8b 45 14             	mov    0x14(%ebp),%eax
f0103333:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103336:	53                   	push   %ebx
f0103337:	ff 75 10             	pushl  0x10(%ebp)
f010333a:	83 ec 08             	sub    $0x8,%esp
f010333d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103340:	ff 75 e0             	pushl  -0x20(%ebp)
f0103343:	ff 75 dc             	pushl  -0x24(%ebp)
f0103346:	ff 75 d8             	pushl  -0x28(%ebp)
f0103349:	e8 42 09 00 00       	call   f0103c90 <__udivdi3>
f010334e:	83 c4 18             	add    $0x18,%esp
f0103351:	52                   	push   %edx
f0103352:	50                   	push   %eax
f0103353:	89 f2                	mov    %esi,%edx
f0103355:	89 f8                	mov    %edi,%eax
f0103357:	e8 9e ff ff ff       	call   f01032fa <printnum>
f010335c:	83 c4 20             	add    $0x20,%esp
f010335f:	eb 18                	jmp    f0103379 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103361:	83 ec 08             	sub    $0x8,%esp
f0103364:	56                   	push   %esi
f0103365:	ff 75 18             	pushl  0x18(%ebp)
f0103368:	ff d7                	call   *%edi
f010336a:	83 c4 10             	add    $0x10,%esp
f010336d:	eb 03                	jmp    f0103372 <printnum+0x78>
f010336f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103372:	83 eb 01             	sub    $0x1,%ebx
f0103375:	85 db                	test   %ebx,%ebx
f0103377:	7f e8                	jg     f0103361 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103379:	83 ec 08             	sub    $0x8,%esp
f010337c:	56                   	push   %esi
f010337d:	83 ec 04             	sub    $0x4,%esp
f0103380:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103383:	ff 75 e0             	pushl  -0x20(%ebp)
f0103386:	ff 75 dc             	pushl  -0x24(%ebp)
f0103389:	ff 75 d8             	pushl  -0x28(%ebp)
f010338c:	e8 2f 0a 00 00       	call   f0103dc0 <__umoddi3>
f0103391:	83 c4 14             	add    $0x14,%esp
f0103394:	0f be 80 81 53 10 f0 	movsbl -0xfefac7f(%eax),%eax
f010339b:	50                   	push   %eax
f010339c:	ff d7                	call   *%edi
}
f010339e:	83 c4 10             	add    $0x10,%esp
f01033a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033a4:	5b                   	pop    %ebx
f01033a5:	5e                   	pop    %esi
f01033a6:	5f                   	pop    %edi
f01033a7:	5d                   	pop    %ebp
f01033a8:	c3                   	ret    

f01033a9 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01033a9:	55                   	push   %ebp
f01033aa:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01033ac:	83 fa 01             	cmp    $0x1,%edx
f01033af:	7e 0e                	jle    f01033bf <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01033b1:	8b 10                	mov    (%eax),%edx
f01033b3:	8d 4a 08             	lea    0x8(%edx),%ecx
f01033b6:	89 08                	mov    %ecx,(%eax)
f01033b8:	8b 02                	mov    (%edx),%eax
f01033ba:	8b 52 04             	mov    0x4(%edx),%edx
f01033bd:	eb 22                	jmp    f01033e1 <getuint+0x38>
	else if (lflag)
f01033bf:	85 d2                	test   %edx,%edx
f01033c1:	74 10                	je     f01033d3 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01033c3:	8b 10                	mov    (%eax),%edx
f01033c5:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033c8:	89 08                	mov    %ecx,(%eax)
f01033ca:	8b 02                	mov    (%edx),%eax
f01033cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01033d1:	eb 0e                	jmp    f01033e1 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01033d3:	8b 10                	mov    (%eax),%edx
f01033d5:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033d8:	89 08                	mov    %ecx,(%eax)
f01033da:	8b 02                	mov    (%edx),%eax
f01033dc:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01033e1:	5d                   	pop    %ebp
f01033e2:	c3                   	ret    

f01033e3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01033e3:	55                   	push   %ebp
f01033e4:	89 e5                	mov    %esp,%ebp
f01033e6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01033e9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01033ed:	8b 10                	mov    (%eax),%edx
f01033ef:	3b 50 04             	cmp    0x4(%eax),%edx
f01033f2:	73 0a                	jae    f01033fe <sprintputch+0x1b>
		*b->buf++ = ch;
f01033f4:	8d 4a 01             	lea    0x1(%edx),%ecx
f01033f7:	89 08                	mov    %ecx,(%eax)
f01033f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01033fc:	88 02                	mov    %al,(%edx)
}
f01033fe:	5d                   	pop    %ebp
f01033ff:	c3                   	ret    

f0103400 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103400:	55                   	push   %ebp
f0103401:	89 e5                	mov    %esp,%ebp
f0103403:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103406:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103409:	50                   	push   %eax
f010340a:	ff 75 10             	pushl  0x10(%ebp)
f010340d:	ff 75 0c             	pushl  0xc(%ebp)
f0103410:	ff 75 08             	pushl  0x8(%ebp)
f0103413:	e8 05 00 00 00       	call   f010341d <vprintfmt>
	va_end(ap);
}
f0103418:	83 c4 10             	add    $0x10,%esp
f010341b:	c9                   	leave  
f010341c:	c3                   	ret    

f010341d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010341d:	55                   	push   %ebp
f010341e:	89 e5                	mov    %esp,%ebp
f0103420:	57                   	push   %edi
f0103421:	56                   	push   %esi
f0103422:	53                   	push   %ebx
f0103423:	83 ec 2c             	sub    $0x2c,%esp
f0103426:	8b 75 08             	mov    0x8(%ebp),%esi
f0103429:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010342c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010342f:	eb 12                	jmp    f0103443 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103431:	85 c0                	test   %eax,%eax
f0103433:	0f 84 89 03 00 00    	je     f01037c2 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103439:	83 ec 08             	sub    $0x8,%esp
f010343c:	53                   	push   %ebx
f010343d:	50                   	push   %eax
f010343e:	ff d6                	call   *%esi
f0103440:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103443:	83 c7 01             	add    $0x1,%edi
f0103446:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010344a:	83 f8 25             	cmp    $0x25,%eax
f010344d:	75 e2                	jne    f0103431 <vprintfmt+0x14>
f010344f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103453:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010345a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103461:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103468:	ba 00 00 00 00       	mov    $0x0,%edx
f010346d:	eb 07                	jmp    f0103476 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010346f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103472:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103476:	8d 47 01             	lea    0x1(%edi),%eax
f0103479:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010347c:	0f b6 07             	movzbl (%edi),%eax
f010347f:	0f b6 c8             	movzbl %al,%ecx
f0103482:	83 e8 23             	sub    $0x23,%eax
f0103485:	3c 55                	cmp    $0x55,%al
f0103487:	0f 87 1a 03 00 00    	ja     f01037a7 <vprintfmt+0x38a>
f010348d:	0f b6 c0             	movzbl %al,%eax
f0103490:	ff 24 85 0c 54 10 f0 	jmp    *-0xfefabf4(,%eax,4)
f0103497:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010349a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010349e:	eb d6                	jmp    f0103476 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01034a8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01034ab:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01034ae:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01034b2:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01034b5:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01034b8:	83 fa 09             	cmp    $0x9,%edx
f01034bb:	77 39                	ja     f01034f6 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01034bd:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01034c0:	eb e9                	jmp    f01034ab <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01034c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01034c5:	8d 48 04             	lea    0x4(%eax),%ecx
f01034c8:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01034cb:	8b 00                	mov    (%eax),%eax
f01034cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01034d3:	eb 27                	jmp    f01034fc <vprintfmt+0xdf>
f01034d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034d8:	85 c0                	test   %eax,%eax
f01034da:	b9 00 00 00 00       	mov    $0x0,%ecx
f01034df:	0f 49 c8             	cmovns %eax,%ecx
f01034e2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034e5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034e8:	eb 8c                	jmp    f0103476 <vprintfmt+0x59>
f01034ea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01034ed:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01034f4:	eb 80                	jmp    f0103476 <vprintfmt+0x59>
f01034f6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034f9:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01034fc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103500:	0f 89 70 ff ff ff    	jns    f0103476 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103506:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103509:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010350c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103513:	e9 5e ff ff ff       	jmp    f0103476 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103518:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010351b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010351e:	e9 53 ff ff ff       	jmp    f0103476 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103523:	8b 45 14             	mov    0x14(%ebp),%eax
f0103526:	8d 50 04             	lea    0x4(%eax),%edx
f0103529:	89 55 14             	mov    %edx,0x14(%ebp)
f010352c:	83 ec 08             	sub    $0x8,%esp
f010352f:	53                   	push   %ebx
f0103530:	ff 30                	pushl  (%eax)
f0103532:	ff d6                	call   *%esi
			break;
f0103534:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103537:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010353a:	e9 04 ff ff ff       	jmp    f0103443 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010353f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103542:	8d 50 04             	lea    0x4(%eax),%edx
f0103545:	89 55 14             	mov    %edx,0x14(%ebp)
f0103548:	8b 00                	mov    (%eax),%eax
f010354a:	99                   	cltd   
f010354b:	31 d0                	xor    %edx,%eax
f010354d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010354f:	83 f8 06             	cmp    $0x6,%eax
f0103552:	7f 0b                	jg     f010355f <vprintfmt+0x142>
f0103554:	8b 14 85 64 55 10 f0 	mov    -0xfefaa9c(,%eax,4),%edx
f010355b:	85 d2                	test   %edx,%edx
f010355d:	75 18                	jne    f0103577 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f010355f:	50                   	push   %eax
f0103560:	68 99 53 10 f0       	push   $0xf0105399
f0103565:	53                   	push   %ebx
f0103566:	56                   	push   %esi
f0103567:	e8 94 fe ff ff       	call   f0103400 <printfmt>
f010356c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010356f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103572:	e9 cc fe ff ff       	jmp    f0103443 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103577:	52                   	push   %edx
f0103578:	68 52 4c 10 f0       	push   $0xf0104c52
f010357d:	53                   	push   %ebx
f010357e:	56                   	push   %esi
f010357f:	e8 7c fe ff ff       	call   f0103400 <printfmt>
f0103584:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103587:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010358a:	e9 b4 fe ff ff       	jmp    f0103443 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010358f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103592:	8d 50 04             	lea    0x4(%eax),%edx
f0103595:	89 55 14             	mov    %edx,0x14(%ebp)
f0103598:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010359a:	85 ff                	test   %edi,%edi
f010359c:	b8 92 53 10 f0       	mov    $0xf0105392,%eax
f01035a1:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01035a4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035a8:	0f 8e 94 00 00 00    	jle    f0103642 <vprintfmt+0x225>
f01035ae:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01035b2:	0f 84 98 00 00 00    	je     f0103650 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01035b8:	83 ec 08             	sub    $0x8,%esp
f01035bb:	ff 75 d0             	pushl  -0x30(%ebp)
f01035be:	57                   	push   %edi
f01035bf:	e8 5f 03 00 00       	call   f0103923 <strnlen>
f01035c4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01035c7:	29 c1                	sub    %eax,%ecx
f01035c9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01035cc:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01035cf:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01035d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01035d6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01035d9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01035db:	eb 0f                	jmp    f01035ec <vprintfmt+0x1cf>
					putch(padc, putdat);
f01035dd:	83 ec 08             	sub    $0x8,%esp
f01035e0:	53                   	push   %ebx
f01035e1:	ff 75 e0             	pushl  -0x20(%ebp)
f01035e4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01035e6:	83 ef 01             	sub    $0x1,%edi
f01035e9:	83 c4 10             	add    $0x10,%esp
f01035ec:	85 ff                	test   %edi,%edi
f01035ee:	7f ed                	jg     f01035dd <vprintfmt+0x1c0>
f01035f0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01035f3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01035f6:	85 c9                	test   %ecx,%ecx
f01035f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01035fd:	0f 49 c1             	cmovns %ecx,%eax
f0103600:	29 c1                	sub    %eax,%ecx
f0103602:	89 75 08             	mov    %esi,0x8(%ebp)
f0103605:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103608:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010360b:	89 cb                	mov    %ecx,%ebx
f010360d:	eb 4d                	jmp    f010365c <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010360f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103613:	74 1b                	je     f0103630 <vprintfmt+0x213>
f0103615:	0f be c0             	movsbl %al,%eax
f0103618:	83 e8 20             	sub    $0x20,%eax
f010361b:	83 f8 5e             	cmp    $0x5e,%eax
f010361e:	76 10                	jbe    f0103630 <vprintfmt+0x213>
					putch('?', putdat);
f0103620:	83 ec 08             	sub    $0x8,%esp
f0103623:	ff 75 0c             	pushl  0xc(%ebp)
f0103626:	6a 3f                	push   $0x3f
f0103628:	ff 55 08             	call   *0x8(%ebp)
f010362b:	83 c4 10             	add    $0x10,%esp
f010362e:	eb 0d                	jmp    f010363d <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103630:	83 ec 08             	sub    $0x8,%esp
f0103633:	ff 75 0c             	pushl  0xc(%ebp)
f0103636:	52                   	push   %edx
f0103637:	ff 55 08             	call   *0x8(%ebp)
f010363a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010363d:	83 eb 01             	sub    $0x1,%ebx
f0103640:	eb 1a                	jmp    f010365c <vprintfmt+0x23f>
f0103642:	89 75 08             	mov    %esi,0x8(%ebp)
f0103645:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103648:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010364b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010364e:	eb 0c                	jmp    f010365c <vprintfmt+0x23f>
f0103650:	89 75 08             	mov    %esi,0x8(%ebp)
f0103653:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103656:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103659:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010365c:	83 c7 01             	add    $0x1,%edi
f010365f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103663:	0f be d0             	movsbl %al,%edx
f0103666:	85 d2                	test   %edx,%edx
f0103668:	74 23                	je     f010368d <vprintfmt+0x270>
f010366a:	85 f6                	test   %esi,%esi
f010366c:	78 a1                	js     f010360f <vprintfmt+0x1f2>
f010366e:	83 ee 01             	sub    $0x1,%esi
f0103671:	79 9c                	jns    f010360f <vprintfmt+0x1f2>
f0103673:	89 df                	mov    %ebx,%edi
f0103675:	8b 75 08             	mov    0x8(%ebp),%esi
f0103678:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010367b:	eb 18                	jmp    f0103695 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010367d:	83 ec 08             	sub    $0x8,%esp
f0103680:	53                   	push   %ebx
f0103681:	6a 20                	push   $0x20
f0103683:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103685:	83 ef 01             	sub    $0x1,%edi
f0103688:	83 c4 10             	add    $0x10,%esp
f010368b:	eb 08                	jmp    f0103695 <vprintfmt+0x278>
f010368d:	89 df                	mov    %ebx,%edi
f010368f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103692:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103695:	85 ff                	test   %edi,%edi
f0103697:	7f e4                	jg     f010367d <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103699:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010369c:	e9 a2 fd ff ff       	jmp    f0103443 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01036a1:	83 fa 01             	cmp    $0x1,%edx
f01036a4:	7e 16                	jle    f01036bc <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01036a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a9:	8d 50 08             	lea    0x8(%eax),%edx
f01036ac:	89 55 14             	mov    %edx,0x14(%ebp)
f01036af:	8b 50 04             	mov    0x4(%eax),%edx
f01036b2:	8b 00                	mov    (%eax),%eax
f01036b4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036b7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01036ba:	eb 32                	jmp    f01036ee <vprintfmt+0x2d1>
	else if (lflag)
f01036bc:	85 d2                	test   %edx,%edx
f01036be:	74 18                	je     f01036d8 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01036c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01036c3:	8d 50 04             	lea    0x4(%eax),%edx
f01036c6:	89 55 14             	mov    %edx,0x14(%ebp)
f01036c9:	8b 00                	mov    (%eax),%eax
f01036cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036ce:	89 c1                	mov    %eax,%ecx
f01036d0:	c1 f9 1f             	sar    $0x1f,%ecx
f01036d3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01036d6:	eb 16                	jmp    f01036ee <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01036d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01036db:	8d 50 04             	lea    0x4(%eax),%edx
f01036de:	89 55 14             	mov    %edx,0x14(%ebp)
f01036e1:	8b 00                	mov    (%eax),%eax
f01036e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036e6:	89 c1                	mov    %eax,%ecx
f01036e8:	c1 f9 1f             	sar    $0x1f,%ecx
f01036eb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01036ee:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01036f1:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01036f4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01036f9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01036fd:	79 74                	jns    f0103773 <vprintfmt+0x356>
				putch('-', putdat);
f01036ff:	83 ec 08             	sub    $0x8,%esp
f0103702:	53                   	push   %ebx
f0103703:	6a 2d                	push   $0x2d
f0103705:	ff d6                	call   *%esi
				num = -(long long) num;
f0103707:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010370a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010370d:	f7 d8                	neg    %eax
f010370f:	83 d2 00             	adc    $0x0,%edx
f0103712:	f7 da                	neg    %edx
f0103714:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103717:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010371c:	eb 55                	jmp    f0103773 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010371e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103721:	e8 83 fc ff ff       	call   f01033a9 <getuint>
			base = 10;
f0103726:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010372b:	eb 46                	jmp    f0103773 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f010372d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103730:	e8 74 fc ff ff       	call   f01033a9 <getuint>
			base = 8;
f0103735:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010373a:	eb 37                	jmp    f0103773 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010373c:	83 ec 08             	sub    $0x8,%esp
f010373f:	53                   	push   %ebx
f0103740:	6a 30                	push   $0x30
f0103742:	ff d6                	call   *%esi
			putch('x', putdat);
f0103744:	83 c4 08             	add    $0x8,%esp
f0103747:	53                   	push   %ebx
f0103748:	6a 78                	push   $0x78
f010374a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010374c:	8b 45 14             	mov    0x14(%ebp),%eax
f010374f:	8d 50 04             	lea    0x4(%eax),%edx
f0103752:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103755:	8b 00                	mov    (%eax),%eax
f0103757:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010375c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010375f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103764:	eb 0d                	jmp    f0103773 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103766:	8d 45 14             	lea    0x14(%ebp),%eax
f0103769:	e8 3b fc ff ff       	call   f01033a9 <getuint>
			base = 16;
f010376e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103773:	83 ec 0c             	sub    $0xc,%esp
f0103776:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010377a:	57                   	push   %edi
f010377b:	ff 75 e0             	pushl  -0x20(%ebp)
f010377e:	51                   	push   %ecx
f010377f:	52                   	push   %edx
f0103780:	50                   	push   %eax
f0103781:	89 da                	mov    %ebx,%edx
f0103783:	89 f0                	mov    %esi,%eax
f0103785:	e8 70 fb ff ff       	call   f01032fa <printnum>
			break;
f010378a:	83 c4 20             	add    $0x20,%esp
f010378d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103790:	e9 ae fc ff ff       	jmp    f0103443 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103795:	83 ec 08             	sub    $0x8,%esp
f0103798:	53                   	push   %ebx
f0103799:	51                   	push   %ecx
f010379a:	ff d6                	call   *%esi
			break;
f010379c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010379f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01037a2:	e9 9c fc ff ff       	jmp    f0103443 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01037a7:	83 ec 08             	sub    $0x8,%esp
f01037aa:	53                   	push   %ebx
f01037ab:	6a 25                	push   $0x25
f01037ad:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01037af:	83 c4 10             	add    $0x10,%esp
f01037b2:	eb 03                	jmp    f01037b7 <vprintfmt+0x39a>
f01037b4:	83 ef 01             	sub    $0x1,%edi
f01037b7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01037bb:	75 f7                	jne    f01037b4 <vprintfmt+0x397>
f01037bd:	e9 81 fc ff ff       	jmp    f0103443 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01037c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01037c5:	5b                   	pop    %ebx
f01037c6:	5e                   	pop    %esi
f01037c7:	5f                   	pop    %edi
f01037c8:	5d                   	pop    %ebp
f01037c9:	c3                   	ret    

f01037ca <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01037ca:	55                   	push   %ebp
f01037cb:	89 e5                	mov    %esp,%ebp
f01037cd:	83 ec 18             	sub    $0x18,%esp
f01037d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01037d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01037d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01037d9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01037dd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01037e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01037e7:	85 c0                	test   %eax,%eax
f01037e9:	74 26                	je     f0103811 <vsnprintf+0x47>
f01037eb:	85 d2                	test   %edx,%edx
f01037ed:	7e 22                	jle    f0103811 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01037ef:	ff 75 14             	pushl  0x14(%ebp)
f01037f2:	ff 75 10             	pushl  0x10(%ebp)
f01037f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01037f8:	50                   	push   %eax
f01037f9:	68 e3 33 10 f0       	push   $0xf01033e3
f01037fe:	e8 1a fc ff ff       	call   f010341d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103803:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103806:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103809:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010380c:	83 c4 10             	add    $0x10,%esp
f010380f:	eb 05                	jmp    f0103816 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103811:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103816:	c9                   	leave  
f0103817:	c3                   	ret    

f0103818 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103818:	55                   	push   %ebp
f0103819:	89 e5                	mov    %esp,%ebp
f010381b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010381e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103821:	50                   	push   %eax
f0103822:	ff 75 10             	pushl  0x10(%ebp)
f0103825:	ff 75 0c             	pushl  0xc(%ebp)
f0103828:	ff 75 08             	pushl  0x8(%ebp)
f010382b:	e8 9a ff ff ff       	call   f01037ca <vsnprintf>
	va_end(ap);

	return rc;
}
f0103830:	c9                   	leave  
f0103831:	c3                   	ret    

f0103832 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103832:	55                   	push   %ebp
f0103833:	89 e5                	mov    %esp,%ebp
f0103835:	57                   	push   %edi
f0103836:	56                   	push   %esi
f0103837:	53                   	push   %ebx
f0103838:	83 ec 0c             	sub    $0xc,%esp
f010383b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010383e:	85 c0                	test   %eax,%eax
f0103840:	74 11                	je     f0103853 <readline+0x21>
		cprintf("%s", prompt);
f0103842:	83 ec 08             	sub    $0x8,%esp
f0103845:	50                   	push   %eax
f0103846:	68 52 4c 10 f0       	push   $0xf0104c52
f010384b:	e8 ac f3 ff ff       	call   f0102bfc <cprintf>
f0103850:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103853:	83 ec 0c             	sub    $0xc,%esp
f0103856:	6a 00                	push   $0x0
f0103858:	e8 d9 cd ff ff       	call   f0100636 <iscons>
f010385d:	89 c7                	mov    %eax,%edi
f010385f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103862:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103867:	e8 b9 cd ff ff       	call   f0100625 <getchar>
f010386c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010386e:	85 c0                	test   %eax,%eax
f0103870:	79 18                	jns    f010388a <readline+0x58>
			cprintf("read error: %e\n", c);
f0103872:	83 ec 08             	sub    $0x8,%esp
f0103875:	50                   	push   %eax
f0103876:	68 80 55 10 f0       	push   $0xf0105580
f010387b:	e8 7c f3 ff ff       	call   f0102bfc <cprintf>
			return NULL;
f0103880:	83 c4 10             	add    $0x10,%esp
f0103883:	b8 00 00 00 00       	mov    $0x0,%eax
f0103888:	eb 79                	jmp    f0103903 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010388a:	83 f8 08             	cmp    $0x8,%eax
f010388d:	0f 94 c2             	sete   %dl
f0103890:	83 f8 7f             	cmp    $0x7f,%eax
f0103893:	0f 94 c0             	sete   %al
f0103896:	08 c2                	or     %al,%dl
f0103898:	74 1a                	je     f01038b4 <readline+0x82>
f010389a:	85 f6                	test   %esi,%esi
f010389c:	7e 16                	jle    f01038b4 <readline+0x82>
			if (echoing)
f010389e:	85 ff                	test   %edi,%edi
f01038a0:	74 0d                	je     f01038af <readline+0x7d>
				cputchar('\b');
f01038a2:	83 ec 0c             	sub    $0xc,%esp
f01038a5:	6a 08                	push   $0x8
f01038a7:	e8 69 cd ff ff       	call   f0100615 <cputchar>
f01038ac:	83 c4 10             	add    $0x10,%esp
			i--;
f01038af:	83 ee 01             	sub    $0x1,%esi
f01038b2:	eb b3                	jmp    f0103867 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01038b4:	83 fb 1f             	cmp    $0x1f,%ebx
f01038b7:	7e 23                	jle    f01038dc <readline+0xaa>
f01038b9:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01038bf:	7f 1b                	jg     f01038dc <readline+0xaa>
			if (echoing)
f01038c1:	85 ff                	test   %edi,%edi
f01038c3:	74 0c                	je     f01038d1 <readline+0x9f>
				cputchar(c);
f01038c5:	83 ec 0c             	sub    $0xc,%esp
f01038c8:	53                   	push   %ebx
f01038c9:	e8 47 cd ff ff       	call   f0100615 <cputchar>
f01038ce:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01038d1:	88 9e 40 f8 16 f0    	mov    %bl,-0xfe907c0(%esi)
f01038d7:	8d 76 01             	lea    0x1(%esi),%esi
f01038da:	eb 8b                	jmp    f0103867 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01038dc:	83 fb 0a             	cmp    $0xa,%ebx
f01038df:	74 05                	je     f01038e6 <readline+0xb4>
f01038e1:	83 fb 0d             	cmp    $0xd,%ebx
f01038e4:	75 81                	jne    f0103867 <readline+0x35>
			if (echoing)
f01038e6:	85 ff                	test   %edi,%edi
f01038e8:	74 0d                	je     f01038f7 <readline+0xc5>
				cputchar('\n');
f01038ea:	83 ec 0c             	sub    $0xc,%esp
f01038ed:	6a 0a                	push   $0xa
f01038ef:	e8 21 cd ff ff       	call   f0100615 <cputchar>
f01038f4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01038f7:	c6 86 40 f8 16 f0 00 	movb   $0x0,-0xfe907c0(%esi)
			return buf;
f01038fe:	b8 40 f8 16 f0       	mov    $0xf016f840,%eax
		}
	}
}
f0103903:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103906:	5b                   	pop    %ebx
f0103907:	5e                   	pop    %esi
f0103908:	5f                   	pop    %edi
f0103909:	5d                   	pop    %ebp
f010390a:	c3                   	ret    

f010390b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010390b:	55                   	push   %ebp
f010390c:	89 e5                	mov    %esp,%ebp
f010390e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103911:	b8 00 00 00 00       	mov    $0x0,%eax
f0103916:	eb 03                	jmp    f010391b <strlen+0x10>
		n++;
f0103918:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010391b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010391f:	75 f7                	jne    f0103918 <strlen+0xd>
		n++;
	return n;
}
f0103921:	5d                   	pop    %ebp
f0103922:	c3                   	ret    

f0103923 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103923:	55                   	push   %ebp
f0103924:	89 e5                	mov    %esp,%ebp
f0103926:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103929:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010392c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103931:	eb 03                	jmp    f0103936 <strnlen+0x13>
		n++;
f0103933:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103936:	39 c2                	cmp    %eax,%edx
f0103938:	74 08                	je     f0103942 <strnlen+0x1f>
f010393a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010393e:	75 f3                	jne    f0103933 <strnlen+0x10>
f0103940:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103942:	5d                   	pop    %ebp
f0103943:	c3                   	ret    

f0103944 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103944:	55                   	push   %ebp
f0103945:	89 e5                	mov    %esp,%ebp
f0103947:	53                   	push   %ebx
f0103948:	8b 45 08             	mov    0x8(%ebp),%eax
f010394b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010394e:	89 c2                	mov    %eax,%edx
f0103950:	83 c2 01             	add    $0x1,%edx
f0103953:	83 c1 01             	add    $0x1,%ecx
f0103956:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010395a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010395d:	84 db                	test   %bl,%bl
f010395f:	75 ef                	jne    f0103950 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103961:	5b                   	pop    %ebx
f0103962:	5d                   	pop    %ebp
f0103963:	c3                   	ret    

f0103964 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103964:	55                   	push   %ebp
f0103965:	89 e5                	mov    %esp,%ebp
f0103967:	53                   	push   %ebx
f0103968:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010396b:	53                   	push   %ebx
f010396c:	e8 9a ff ff ff       	call   f010390b <strlen>
f0103971:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103974:	ff 75 0c             	pushl  0xc(%ebp)
f0103977:	01 d8                	add    %ebx,%eax
f0103979:	50                   	push   %eax
f010397a:	e8 c5 ff ff ff       	call   f0103944 <strcpy>
	return dst;
}
f010397f:	89 d8                	mov    %ebx,%eax
f0103981:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103984:	c9                   	leave  
f0103985:	c3                   	ret    

f0103986 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103986:	55                   	push   %ebp
f0103987:	89 e5                	mov    %esp,%ebp
f0103989:	56                   	push   %esi
f010398a:	53                   	push   %ebx
f010398b:	8b 75 08             	mov    0x8(%ebp),%esi
f010398e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103991:	89 f3                	mov    %esi,%ebx
f0103993:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103996:	89 f2                	mov    %esi,%edx
f0103998:	eb 0f                	jmp    f01039a9 <strncpy+0x23>
		*dst++ = *src;
f010399a:	83 c2 01             	add    $0x1,%edx
f010399d:	0f b6 01             	movzbl (%ecx),%eax
f01039a0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01039a3:	80 39 01             	cmpb   $0x1,(%ecx)
f01039a6:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01039a9:	39 da                	cmp    %ebx,%edx
f01039ab:	75 ed                	jne    f010399a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01039ad:	89 f0                	mov    %esi,%eax
f01039af:	5b                   	pop    %ebx
f01039b0:	5e                   	pop    %esi
f01039b1:	5d                   	pop    %ebp
f01039b2:	c3                   	ret    

f01039b3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01039b3:	55                   	push   %ebp
f01039b4:	89 e5                	mov    %esp,%ebp
f01039b6:	56                   	push   %esi
f01039b7:	53                   	push   %ebx
f01039b8:	8b 75 08             	mov    0x8(%ebp),%esi
f01039bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01039be:	8b 55 10             	mov    0x10(%ebp),%edx
f01039c1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01039c3:	85 d2                	test   %edx,%edx
f01039c5:	74 21                	je     f01039e8 <strlcpy+0x35>
f01039c7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01039cb:	89 f2                	mov    %esi,%edx
f01039cd:	eb 09                	jmp    f01039d8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01039cf:	83 c2 01             	add    $0x1,%edx
f01039d2:	83 c1 01             	add    $0x1,%ecx
f01039d5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01039d8:	39 c2                	cmp    %eax,%edx
f01039da:	74 09                	je     f01039e5 <strlcpy+0x32>
f01039dc:	0f b6 19             	movzbl (%ecx),%ebx
f01039df:	84 db                	test   %bl,%bl
f01039e1:	75 ec                	jne    f01039cf <strlcpy+0x1c>
f01039e3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01039e5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01039e8:	29 f0                	sub    %esi,%eax
}
f01039ea:	5b                   	pop    %ebx
f01039eb:	5e                   	pop    %esi
f01039ec:	5d                   	pop    %ebp
f01039ed:	c3                   	ret    

f01039ee <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01039ee:	55                   	push   %ebp
f01039ef:	89 e5                	mov    %esp,%ebp
f01039f1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039f4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01039f7:	eb 06                	jmp    f01039ff <strcmp+0x11>
		p++, q++;
f01039f9:	83 c1 01             	add    $0x1,%ecx
f01039fc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01039ff:	0f b6 01             	movzbl (%ecx),%eax
f0103a02:	84 c0                	test   %al,%al
f0103a04:	74 04                	je     f0103a0a <strcmp+0x1c>
f0103a06:	3a 02                	cmp    (%edx),%al
f0103a08:	74 ef                	je     f01039f9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103a0a:	0f b6 c0             	movzbl %al,%eax
f0103a0d:	0f b6 12             	movzbl (%edx),%edx
f0103a10:	29 d0                	sub    %edx,%eax
}
f0103a12:	5d                   	pop    %ebp
f0103a13:	c3                   	ret    

f0103a14 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103a14:	55                   	push   %ebp
f0103a15:	89 e5                	mov    %esp,%ebp
f0103a17:	53                   	push   %ebx
f0103a18:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a1b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a1e:	89 c3                	mov    %eax,%ebx
f0103a20:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103a23:	eb 06                	jmp    f0103a2b <strncmp+0x17>
		n--, p++, q++;
f0103a25:	83 c0 01             	add    $0x1,%eax
f0103a28:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103a2b:	39 d8                	cmp    %ebx,%eax
f0103a2d:	74 15                	je     f0103a44 <strncmp+0x30>
f0103a2f:	0f b6 08             	movzbl (%eax),%ecx
f0103a32:	84 c9                	test   %cl,%cl
f0103a34:	74 04                	je     f0103a3a <strncmp+0x26>
f0103a36:	3a 0a                	cmp    (%edx),%cl
f0103a38:	74 eb                	je     f0103a25 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103a3a:	0f b6 00             	movzbl (%eax),%eax
f0103a3d:	0f b6 12             	movzbl (%edx),%edx
f0103a40:	29 d0                	sub    %edx,%eax
f0103a42:	eb 05                	jmp    f0103a49 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103a44:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103a49:	5b                   	pop    %ebx
f0103a4a:	5d                   	pop    %ebp
f0103a4b:	c3                   	ret    

f0103a4c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103a4c:	55                   	push   %ebp
f0103a4d:	89 e5                	mov    %esp,%ebp
f0103a4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a52:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103a56:	eb 07                	jmp    f0103a5f <strchr+0x13>
		if (*s == c)
f0103a58:	38 ca                	cmp    %cl,%dl
f0103a5a:	74 0f                	je     f0103a6b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103a5c:	83 c0 01             	add    $0x1,%eax
f0103a5f:	0f b6 10             	movzbl (%eax),%edx
f0103a62:	84 d2                	test   %dl,%dl
f0103a64:	75 f2                	jne    f0103a58 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103a66:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a6b:	5d                   	pop    %ebp
f0103a6c:	c3                   	ret    

f0103a6d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103a6d:	55                   	push   %ebp
f0103a6e:	89 e5                	mov    %esp,%ebp
f0103a70:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a73:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103a77:	eb 03                	jmp    f0103a7c <strfind+0xf>
f0103a79:	83 c0 01             	add    $0x1,%eax
f0103a7c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103a7f:	38 ca                	cmp    %cl,%dl
f0103a81:	74 04                	je     f0103a87 <strfind+0x1a>
f0103a83:	84 d2                	test   %dl,%dl
f0103a85:	75 f2                	jne    f0103a79 <strfind+0xc>
			break;
	return (char *) s;
}
f0103a87:	5d                   	pop    %ebp
f0103a88:	c3                   	ret    

f0103a89 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103a89:	55                   	push   %ebp
f0103a8a:	89 e5                	mov    %esp,%ebp
f0103a8c:	57                   	push   %edi
f0103a8d:	56                   	push   %esi
f0103a8e:	53                   	push   %ebx
f0103a8f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a92:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103a95:	85 c9                	test   %ecx,%ecx
f0103a97:	74 36                	je     f0103acf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103a99:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103a9f:	75 28                	jne    f0103ac9 <memset+0x40>
f0103aa1:	f6 c1 03             	test   $0x3,%cl
f0103aa4:	75 23                	jne    f0103ac9 <memset+0x40>
		c &= 0xFF;
f0103aa6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103aaa:	89 d3                	mov    %edx,%ebx
f0103aac:	c1 e3 08             	shl    $0x8,%ebx
f0103aaf:	89 d6                	mov    %edx,%esi
f0103ab1:	c1 e6 18             	shl    $0x18,%esi
f0103ab4:	89 d0                	mov    %edx,%eax
f0103ab6:	c1 e0 10             	shl    $0x10,%eax
f0103ab9:	09 f0                	or     %esi,%eax
f0103abb:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103abd:	89 d8                	mov    %ebx,%eax
f0103abf:	09 d0                	or     %edx,%eax
f0103ac1:	c1 e9 02             	shr    $0x2,%ecx
f0103ac4:	fc                   	cld    
f0103ac5:	f3 ab                	rep stos %eax,%es:(%edi)
f0103ac7:	eb 06                	jmp    f0103acf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103acc:	fc                   	cld    
f0103acd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103acf:	89 f8                	mov    %edi,%eax
f0103ad1:	5b                   	pop    %ebx
f0103ad2:	5e                   	pop    %esi
f0103ad3:	5f                   	pop    %edi
f0103ad4:	5d                   	pop    %ebp
f0103ad5:	c3                   	ret    

f0103ad6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ad6:	55                   	push   %ebp
f0103ad7:	89 e5                	mov    %esp,%ebp
f0103ad9:	57                   	push   %edi
f0103ada:	56                   	push   %esi
f0103adb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ade:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ae1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103ae4:	39 c6                	cmp    %eax,%esi
f0103ae6:	73 35                	jae    f0103b1d <memmove+0x47>
f0103ae8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103aeb:	39 d0                	cmp    %edx,%eax
f0103aed:	73 2e                	jae    f0103b1d <memmove+0x47>
		s += n;
		d += n;
f0103aef:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103af2:	89 d6                	mov    %edx,%esi
f0103af4:	09 fe                	or     %edi,%esi
f0103af6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103afc:	75 13                	jne    f0103b11 <memmove+0x3b>
f0103afe:	f6 c1 03             	test   $0x3,%cl
f0103b01:	75 0e                	jne    f0103b11 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103b03:	83 ef 04             	sub    $0x4,%edi
f0103b06:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103b09:	c1 e9 02             	shr    $0x2,%ecx
f0103b0c:	fd                   	std    
f0103b0d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103b0f:	eb 09                	jmp    f0103b1a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103b11:	83 ef 01             	sub    $0x1,%edi
f0103b14:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103b17:	fd                   	std    
f0103b18:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103b1a:	fc                   	cld    
f0103b1b:	eb 1d                	jmp    f0103b3a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103b1d:	89 f2                	mov    %esi,%edx
f0103b1f:	09 c2                	or     %eax,%edx
f0103b21:	f6 c2 03             	test   $0x3,%dl
f0103b24:	75 0f                	jne    f0103b35 <memmove+0x5f>
f0103b26:	f6 c1 03             	test   $0x3,%cl
f0103b29:	75 0a                	jne    f0103b35 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103b2b:	c1 e9 02             	shr    $0x2,%ecx
f0103b2e:	89 c7                	mov    %eax,%edi
f0103b30:	fc                   	cld    
f0103b31:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103b33:	eb 05                	jmp    f0103b3a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103b35:	89 c7                	mov    %eax,%edi
f0103b37:	fc                   	cld    
f0103b38:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103b3a:	5e                   	pop    %esi
f0103b3b:	5f                   	pop    %edi
f0103b3c:	5d                   	pop    %ebp
f0103b3d:	c3                   	ret    

f0103b3e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103b3e:	55                   	push   %ebp
f0103b3f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103b41:	ff 75 10             	pushl  0x10(%ebp)
f0103b44:	ff 75 0c             	pushl  0xc(%ebp)
f0103b47:	ff 75 08             	pushl  0x8(%ebp)
f0103b4a:	e8 87 ff ff ff       	call   f0103ad6 <memmove>
}
f0103b4f:	c9                   	leave  
f0103b50:	c3                   	ret    

f0103b51 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103b51:	55                   	push   %ebp
f0103b52:	89 e5                	mov    %esp,%ebp
f0103b54:	56                   	push   %esi
f0103b55:	53                   	push   %ebx
f0103b56:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b59:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b5c:	89 c6                	mov    %eax,%esi
f0103b5e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b61:	eb 1a                	jmp    f0103b7d <memcmp+0x2c>
		if (*s1 != *s2)
f0103b63:	0f b6 08             	movzbl (%eax),%ecx
f0103b66:	0f b6 1a             	movzbl (%edx),%ebx
f0103b69:	38 d9                	cmp    %bl,%cl
f0103b6b:	74 0a                	je     f0103b77 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103b6d:	0f b6 c1             	movzbl %cl,%eax
f0103b70:	0f b6 db             	movzbl %bl,%ebx
f0103b73:	29 d8                	sub    %ebx,%eax
f0103b75:	eb 0f                	jmp    f0103b86 <memcmp+0x35>
		s1++, s2++;
f0103b77:	83 c0 01             	add    $0x1,%eax
f0103b7a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b7d:	39 f0                	cmp    %esi,%eax
f0103b7f:	75 e2                	jne    f0103b63 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103b81:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b86:	5b                   	pop    %ebx
f0103b87:	5e                   	pop    %esi
f0103b88:	5d                   	pop    %ebp
f0103b89:	c3                   	ret    

f0103b8a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103b8a:	55                   	push   %ebp
f0103b8b:	89 e5                	mov    %esp,%ebp
f0103b8d:	53                   	push   %ebx
f0103b8e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103b91:	89 c1                	mov    %eax,%ecx
f0103b93:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103b96:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103b9a:	eb 0a                	jmp    f0103ba6 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103b9c:	0f b6 10             	movzbl (%eax),%edx
f0103b9f:	39 da                	cmp    %ebx,%edx
f0103ba1:	74 07                	je     f0103baa <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103ba3:	83 c0 01             	add    $0x1,%eax
f0103ba6:	39 c8                	cmp    %ecx,%eax
f0103ba8:	72 f2                	jb     f0103b9c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103baa:	5b                   	pop    %ebx
f0103bab:	5d                   	pop    %ebp
f0103bac:	c3                   	ret    

f0103bad <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103bad:	55                   	push   %ebp
f0103bae:	89 e5                	mov    %esp,%ebp
f0103bb0:	57                   	push   %edi
f0103bb1:	56                   	push   %esi
f0103bb2:	53                   	push   %ebx
f0103bb3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103bb6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103bb9:	eb 03                	jmp    f0103bbe <strtol+0x11>
		s++;
f0103bbb:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103bbe:	0f b6 01             	movzbl (%ecx),%eax
f0103bc1:	3c 20                	cmp    $0x20,%al
f0103bc3:	74 f6                	je     f0103bbb <strtol+0xe>
f0103bc5:	3c 09                	cmp    $0x9,%al
f0103bc7:	74 f2                	je     f0103bbb <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103bc9:	3c 2b                	cmp    $0x2b,%al
f0103bcb:	75 0a                	jne    f0103bd7 <strtol+0x2a>
		s++;
f0103bcd:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103bd0:	bf 00 00 00 00       	mov    $0x0,%edi
f0103bd5:	eb 11                	jmp    f0103be8 <strtol+0x3b>
f0103bd7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103bdc:	3c 2d                	cmp    $0x2d,%al
f0103bde:	75 08                	jne    f0103be8 <strtol+0x3b>
		s++, neg = 1;
f0103be0:	83 c1 01             	add    $0x1,%ecx
f0103be3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103be8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103bee:	75 15                	jne    f0103c05 <strtol+0x58>
f0103bf0:	80 39 30             	cmpb   $0x30,(%ecx)
f0103bf3:	75 10                	jne    f0103c05 <strtol+0x58>
f0103bf5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103bf9:	75 7c                	jne    f0103c77 <strtol+0xca>
		s += 2, base = 16;
f0103bfb:	83 c1 02             	add    $0x2,%ecx
f0103bfe:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103c03:	eb 16                	jmp    f0103c1b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103c05:	85 db                	test   %ebx,%ebx
f0103c07:	75 12                	jne    f0103c1b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103c09:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103c0e:	80 39 30             	cmpb   $0x30,(%ecx)
f0103c11:	75 08                	jne    f0103c1b <strtol+0x6e>
		s++, base = 8;
f0103c13:	83 c1 01             	add    $0x1,%ecx
f0103c16:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103c1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c20:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103c23:	0f b6 11             	movzbl (%ecx),%edx
f0103c26:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103c29:	89 f3                	mov    %esi,%ebx
f0103c2b:	80 fb 09             	cmp    $0x9,%bl
f0103c2e:	77 08                	ja     f0103c38 <strtol+0x8b>
			dig = *s - '0';
f0103c30:	0f be d2             	movsbl %dl,%edx
f0103c33:	83 ea 30             	sub    $0x30,%edx
f0103c36:	eb 22                	jmp    f0103c5a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103c38:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103c3b:	89 f3                	mov    %esi,%ebx
f0103c3d:	80 fb 19             	cmp    $0x19,%bl
f0103c40:	77 08                	ja     f0103c4a <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103c42:	0f be d2             	movsbl %dl,%edx
f0103c45:	83 ea 57             	sub    $0x57,%edx
f0103c48:	eb 10                	jmp    f0103c5a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103c4a:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103c4d:	89 f3                	mov    %esi,%ebx
f0103c4f:	80 fb 19             	cmp    $0x19,%bl
f0103c52:	77 16                	ja     f0103c6a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103c54:	0f be d2             	movsbl %dl,%edx
f0103c57:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103c5a:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103c5d:	7d 0b                	jge    f0103c6a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103c5f:	83 c1 01             	add    $0x1,%ecx
f0103c62:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103c66:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103c68:	eb b9                	jmp    f0103c23 <strtol+0x76>

	if (endptr)
f0103c6a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103c6e:	74 0d                	je     f0103c7d <strtol+0xd0>
		*endptr = (char *) s;
f0103c70:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c73:	89 0e                	mov    %ecx,(%esi)
f0103c75:	eb 06                	jmp    f0103c7d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103c77:	85 db                	test   %ebx,%ebx
f0103c79:	74 98                	je     f0103c13 <strtol+0x66>
f0103c7b:	eb 9e                	jmp    f0103c1b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103c7d:	89 c2                	mov    %eax,%edx
f0103c7f:	f7 da                	neg    %edx
f0103c81:	85 ff                	test   %edi,%edi
f0103c83:	0f 45 c2             	cmovne %edx,%eax
}
f0103c86:	5b                   	pop    %ebx
f0103c87:	5e                   	pop    %esi
f0103c88:	5f                   	pop    %edi
f0103c89:	5d                   	pop    %ebp
f0103c8a:	c3                   	ret    
f0103c8b:	66 90                	xchg   %ax,%ax
f0103c8d:	66 90                	xchg   %ax,%ax
f0103c8f:	90                   	nop

f0103c90 <__udivdi3>:
f0103c90:	55                   	push   %ebp
f0103c91:	57                   	push   %edi
f0103c92:	56                   	push   %esi
f0103c93:	53                   	push   %ebx
f0103c94:	83 ec 1c             	sub    $0x1c,%esp
f0103c97:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103c9b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103c9f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103ca3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ca7:	85 f6                	test   %esi,%esi
f0103ca9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103cad:	89 ca                	mov    %ecx,%edx
f0103caf:	89 f8                	mov    %edi,%eax
f0103cb1:	75 3d                	jne    f0103cf0 <__udivdi3+0x60>
f0103cb3:	39 cf                	cmp    %ecx,%edi
f0103cb5:	0f 87 c5 00 00 00    	ja     f0103d80 <__udivdi3+0xf0>
f0103cbb:	85 ff                	test   %edi,%edi
f0103cbd:	89 fd                	mov    %edi,%ebp
f0103cbf:	75 0b                	jne    f0103ccc <__udivdi3+0x3c>
f0103cc1:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cc6:	31 d2                	xor    %edx,%edx
f0103cc8:	f7 f7                	div    %edi
f0103cca:	89 c5                	mov    %eax,%ebp
f0103ccc:	89 c8                	mov    %ecx,%eax
f0103cce:	31 d2                	xor    %edx,%edx
f0103cd0:	f7 f5                	div    %ebp
f0103cd2:	89 c1                	mov    %eax,%ecx
f0103cd4:	89 d8                	mov    %ebx,%eax
f0103cd6:	89 cf                	mov    %ecx,%edi
f0103cd8:	f7 f5                	div    %ebp
f0103cda:	89 c3                	mov    %eax,%ebx
f0103cdc:	89 d8                	mov    %ebx,%eax
f0103cde:	89 fa                	mov    %edi,%edx
f0103ce0:	83 c4 1c             	add    $0x1c,%esp
f0103ce3:	5b                   	pop    %ebx
f0103ce4:	5e                   	pop    %esi
f0103ce5:	5f                   	pop    %edi
f0103ce6:	5d                   	pop    %ebp
f0103ce7:	c3                   	ret    
f0103ce8:	90                   	nop
f0103ce9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103cf0:	39 ce                	cmp    %ecx,%esi
f0103cf2:	77 74                	ja     f0103d68 <__udivdi3+0xd8>
f0103cf4:	0f bd fe             	bsr    %esi,%edi
f0103cf7:	83 f7 1f             	xor    $0x1f,%edi
f0103cfa:	0f 84 98 00 00 00    	je     f0103d98 <__udivdi3+0x108>
f0103d00:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103d05:	89 f9                	mov    %edi,%ecx
f0103d07:	89 c5                	mov    %eax,%ebp
f0103d09:	29 fb                	sub    %edi,%ebx
f0103d0b:	d3 e6                	shl    %cl,%esi
f0103d0d:	89 d9                	mov    %ebx,%ecx
f0103d0f:	d3 ed                	shr    %cl,%ebp
f0103d11:	89 f9                	mov    %edi,%ecx
f0103d13:	d3 e0                	shl    %cl,%eax
f0103d15:	09 ee                	or     %ebp,%esi
f0103d17:	89 d9                	mov    %ebx,%ecx
f0103d19:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d1d:	89 d5                	mov    %edx,%ebp
f0103d1f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d23:	d3 ed                	shr    %cl,%ebp
f0103d25:	89 f9                	mov    %edi,%ecx
f0103d27:	d3 e2                	shl    %cl,%edx
f0103d29:	89 d9                	mov    %ebx,%ecx
f0103d2b:	d3 e8                	shr    %cl,%eax
f0103d2d:	09 c2                	or     %eax,%edx
f0103d2f:	89 d0                	mov    %edx,%eax
f0103d31:	89 ea                	mov    %ebp,%edx
f0103d33:	f7 f6                	div    %esi
f0103d35:	89 d5                	mov    %edx,%ebp
f0103d37:	89 c3                	mov    %eax,%ebx
f0103d39:	f7 64 24 0c          	mull   0xc(%esp)
f0103d3d:	39 d5                	cmp    %edx,%ebp
f0103d3f:	72 10                	jb     f0103d51 <__udivdi3+0xc1>
f0103d41:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103d45:	89 f9                	mov    %edi,%ecx
f0103d47:	d3 e6                	shl    %cl,%esi
f0103d49:	39 c6                	cmp    %eax,%esi
f0103d4b:	73 07                	jae    f0103d54 <__udivdi3+0xc4>
f0103d4d:	39 d5                	cmp    %edx,%ebp
f0103d4f:	75 03                	jne    f0103d54 <__udivdi3+0xc4>
f0103d51:	83 eb 01             	sub    $0x1,%ebx
f0103d54:	31 ff                	xor    %edi,%edi
f0103d56:	89 d8                	mov    %ebx,%eax
f0103d58:	89 fa                	mov    %edi,%edx
f0103d5a:	83 c4 1c             	add    $0x1c,%esp
f0103d5d:	5b                   	pop    %ebx
f0103d5e:	5e                   	pop    %esi
f0103d5f:	5f                   	pop    %edi
f0103d60:	5d                   	pop    %ebp
f0103d61:	c3                   	ret    
f0103d62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d68:	31 ff                	xor    %edi,%edi
f0103d6a:	31 db                	xor    %ebx,%ebx
f0103d6c:	89 d8                	mov    %ebx,%eax
f0103d6e:	89 fa                	mov    %edi,%edx
f0103d70:	83 c4 1c             	add    $0x1c,%esp
f0103d73:	5b                   	pop    %ebx
f0103d74:	5e                   	pop    %esi
f0103d75:	5f                   	pop    %edi
f0103d76:	5d                   	pop    %ebp
f0103d77:	c3                   	ret    
f0103d78:	90                   	nop
f0103d79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d80:	89 d8                	mov    %ebx,%eax
f0103d82:	f7 f7                	div    %edi
f0103d84:	31 ff                	xor    %edi,%edi
f0103d86:	89 c3                	mov    %eax,%ebx
f0103d88:	89 d8                	mov    %ebx,%eax
f0103d8a:	89 fa                	mov    %edi,%edx
f0103d8c:	83 c4 1c             	add    $0x1c,%esp
f0103d8f:	5b                   	pop    %ebx
f0103d90:	5e                   	pop    %esi
f0103d91:	5f                   	pop    %edi
f0103d92:	5d                   	pop    %ebp
f0103d93:	c3                   	ret    
f0103d94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d98:	39 ce                	cmp    %ecx,%esi
f0103d9a:	72 0c                	jb     f0103da8 <__udivdi3+0x118>
f0103d9c:	31 db                	xor    %ebx,%ebx
f0103d9e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103da2:	0f 87 34 ff ff ff    	ja     f0103cdc <__udivdi3+0x4c>
f0103da8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103dad:	e9 2a ff ff ff       	jmp    f0103cdc <__udivdi3+0x4c>
f0103db2:	66 90                	xchg   %ax,%ax
f0103db4:	66 90                	xchg   %ax,%ax
f0103db6:	66 90                	xchg   %ax,%ax
f0103db8:	66 90                	xchg   %ax,%ax
f0103dba:	66 90                	xchg   %ax,%ax
f0103dbc:	66 90                	xchg   %ax,%ax
f0103dbe:	66 90                	xchg   %ax,%ax

f0103dc0 <__umoddi3>:
f0103dc0:	55                   	push   %ebp
f0103dc1:	57                   	push   %edi
f0103dc2:	56                   	push   %esi
f0103dc3:	53                   	push   %ebx
f0103dc4:	83 ec 1c             	sub    $0x1c,%esp
f0103dc7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103dcb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103dcf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103dd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103dd7:	85 d2                	test   %edx,%edx
f0103dd9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103ddd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103de1:	89 f3                	mov    %esi,%ebx
f0103de3:	89 3c 24             	mov    %edi,(%esp)
f0103de6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103dea:	75 1c                	jne    f0103e08 <__umoddi3+0x48>
f0103dec:	39 f7                	cmp    %esi,%edi
f0103dee:	76 50                	jbe    f0103e40 <__umoddi3+0x80>
f0103df0:	89 c8                	mov    %ecx,%eax
f0103df2:	89 f2                	mov    %esi,%edx
f0103df4:	f7 f7                	div    %edi
f0103df6:	89 d0                	mov    %edx,%eax
f0103df8:	31 d2                	xor    %edx,%edx
f0103dfa:	83 c4 1c             	add    $0x1c,%esp
f0103dfd:	5b                   	pop    %ebx
f0103dfe:	5e                   	pop    %esi
f0103dff:	5f                   	pop    %edi
f0103e00:	5d                   	pop    %ebp
f0103e01:	c3                   	ret    
f0103e02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e08:	39 f2                	cmp    %esi,%edx
f0103e0a:	89 d0                	mov    %edx,%eax
f0103e0c:	77 52                	ja     f0103e60 <__umoddi3+0xa0>
f0103e0e:	0f bd ea             	bsr    %edx,%ebp
f0103e11:	83 f5 1f             	xor    $0x1f,%ebp
f0103e14:	75 5a                	jne    f0103e70 <__umoddi3+0xb0>
f0103e16:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103e1a:	0f 82 e0 00 00 00    	jb     f0103f00 <__umoddi3+0x140>
f0103e20:	39 0c 24             	cmp    %ecx,(%esp)
f0103e23:	0f 86 d7 00 00 00    	jbe    f0103f00 <__umoddi3+0x140>
f0103e29:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e2d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103e31:	83 c4 1c             	add    $0x1c,%esp
f0103e34:	5b                   	pop    %ebx
f0103e35:	5e                   	pop    %esi
f0103e36:	5f                   	pop    %edi
f0103e37:	5d                   	pop    %ebp
f0103e38:	c3                   	ret    
f0103e39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e40:	85 ff                	test   %edi,%edi
f0103e42:	89 fd                	mov    %edi,%ebp
f0103e44:	75 0b                	jne    f0103e51 <__umoddi3+0x91>
f0103e46:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e4b:	31 d2                	xor    %edx,%edx
f0103e4d:	f7 f7                	div    %edi
f0103e4f:	89 c5                	mov    %eax,%ebp
f0103e51:	89 f0                	mov    %esi,%eax
f0103e53:	31 d2                	xor    %edx,%edx
f0103e55:	f7 f5                	div    %ebp
f0103e57:	89 c8                	mov    %ecx,%eax
f0103e59:	f7 f5                	div    %ebp
f0103e5b:	89 d0                	mov    %edx,%eax
f0103e5d:	eb 99                	jmp    f0103df8 <__umoddi3+0x38>
f0103e5f:	90                   	nop
f0103e60:	89 c8                	mov    %ecx,%eax
f0103e62:	89 f2                	mov    %esi,%edx
f0103e64:	83 c4 1c             	add    $0x1c,%esp
f0103e67:	5b                   	pop    %ebx
f0103e68:	5e                   	pop    %esi
f0103e69:	5f                   	pop    %edi
f0103e6a:	5d                   	pop    %ebp
f0103e6b:	c3                   	ret    
f0103e6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e70:	8b 34 24             	mov    (%esp),%esi
f0103e73:	bf 20 00 00 00       	mov    $0x20,%edi
f0103e78:	89 e9                	mov    %ebp,%ecx
f0103e7a:	29 ef                	sub    %ebp,%edi
f0103e7c:	d3 e0                	shl    %cl,%eax
f0103e7e:	89 f9                	mov    %edi,%ecx
f0103e80:	89 f2                	mov    %esi,%edx
f0103e82:	d3 ea                	shr    %cl,%edx
f0103e84:	89 e9                	mov    %ebp,%ecx
f0103e86:	09 c2                	or     %eax,%edx
f0103e88:	89 d8                	mov    %ebx,%eax
f0103e8a:	89 14 24             	mov    %edx,(%esp)
f0103e8d:	89 f2                	mov    %esi,%edx
f0103e8f:	d3 e2                	shl    %cl,%edx
f0103e91:	89 f9                	mov    %edi,%ecx
f0103e93:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103e97:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103e9b:	d3 e8                	shr    %cl,%eax
f0103e9d:	89 e9                	mov    %ebp,%ecx
f0103e9f:	89 c6                	mov    %eax,%esi
f0103ea1:	d3 e3                	shl    %cl,%ebx
f0103ea3:	89 f9                	mov    %edi,%ecx
f0103ea5:	89 d0                	mov    %edx,%eax
f0103ea7:	d3 e8                	shr    %cl,%eax
f0103ea9:	89 e9                	mov    %ebp,%ecx
f0103eab:	09 d8                	or     %ebx,%eax
f0103ead:	89 d3                	mov    %edx,%ebx
f0103eaf:	89 f2                	mov    %esi,%edx
f0103eb1:	f7 34 24             	divl   (%esp)
f0103eb4:	89 d6                	mov    %edx,%esi
f0103eb6:	d3 e3                	shl    %cl,%ebx
f0103eb8:	f7 64 24 04          	mull   0x4(%esp)
f0103ebc:	39 d6                	cmp    %edx,%esi
f0103ebe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103ec2:	89 d1                	mov    %edx,%ecx
f0103ec4:	89 c3                	mov    %eax,%ebx
f0103ec6:	72 08                	jb     f0103ed0 <__umoddi3+0x110>
f0103ec8:	75 11                	jne    f0103edb <__umoddi3+0x11b>
f0103eca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103ece:	73 0b                	jae    f0103edb <__umoddi3+0x11b>
f0103ed0:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103ed4:	1b 14 24             	sbb    (%esp),%edx
f0103ed7:	89 d1                	mov    %edx,%ecx
f0103ed9:	89 c3                	mov    %eax,%ebx
f0103edb:	8b 54 24 08          	mov    0x8(%esp),%edx
f0103edf:	29 da                	sub    %ebx,%edx
f0103ee1:	19 ce                	sbb    %ecx,%esi
f0103ee3:	89 f9                	mov    %edi,%ecx
f0103ee5:	89 f0                	mov    %esi,%eax
f0103ee7:	d3 e0                	shl    %cl,%eax
f0103ee9:	89 e9                	mov    %ebp,%ecx
f0103eeb:	d3 ea                	shr    %cl,%edx
f0103eed:	89 e9                	mov    %ebp,%ecx
f0103eef:	d3 ee                	shr    %cl,%esi
f0103ef1:	09 d0                	or     %edx,%eax
f0103ef3:	89 f2                	mov    %esi,%edx
f0103ef5:	83 c4 1c             	add    $0x1c,%esp
f0103ef8:	5b                   	pop    %ebx
f0103ef9:	5e                   	pop    %esi
f0103efa:	5f                   	pop    %edi
f0103efb:	5d                   	pop    %ebp
f0103efc:	c3                   	ret    
f0103efd:	8d 76 00             	lea    0x0(%esi),%esi
f0103f00:	29 f9                	sub    %edi,%ecx
f0103f02:	19 d6                	sbb    %edx,%esi
f0103f04:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f08:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f0c:	e9 18 ff ff ff       	jmp    f0103e29 <__umoddi3+0x69>
