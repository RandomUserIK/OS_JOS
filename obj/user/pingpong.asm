
obj/user/pingpong:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 8d 00 00 00       	call   8000be <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 1c             	sub    $0x1c,%esp
	envid_t who;

	if ((who = fork()) != 0) {
  80003c:	e8 99 0d 00 00       	call   800dda <fork>
  800041:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800044:	85 c0                	test   %eax,%eax
  800046:	74 27                	je     80006f <umain+0x3c>
  800048:	89 c3                	mov    %eax,%ebx
		// get the ball rolling
		cprintf("send 0 from %x to %x\n", sys_getenvid(), who);
  80004a:	e8 a4 0a 00 00       	call   800af3 <sys_getenvid>
  80004f:	83 ec 04             	sub    $0x4,%esp
  800052:	53                   	push   %ebx
  800053:	50                   	push   %eax
  800054:	68 c0 13 80 00       	push   $0x8013c0
  800059:	e8 4b 01 00 00       	call   8001a9 <cprintf>
		ipc_send(who, 0, 0, 0);
  80005e:	6a 00                	push   $0x0
  800060:	6a 00                	push   $0x0
  800062:	6a 00                	push   $0x0
  800064:	ff 75 e4             	pushl  -0x1c(%ebp)
  800067:	e8 50 0f 00 00       	call   800fbc <ipc_send>
  80006c:	83 c4 20             	add    $0x20,%esp
	}

	while (1) {
		uint32_t i = ipc_recv(&who, 0, 0);
  80006f:	8d 75 e4             	lea    -0x1c(%ebp),%esi
  800072:	83 ec 04             	sub    $0x4,%esp
  800075:	6a 00                	push   $0x0
  800077:	6a 00                	push   $0x0
  800079:	56                   	push   %esi
  80007a:	e8 d4 0e 00 00       	call   800f53 <ipc_recv>
  80007f:	89 c3                	mov    %eax,%ebx
		cprintf("%x got %d from %x\n", sys_getenvid(), i, who);
  800081:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800084:	e8 6a 0a 00 00       	call   800af3 <sys_getenvid>
  800089:	57                   	push   %edi
  80008a:	53                   	push   %ebx
  80008b:	50                   	push   %eax
  80008c:	68 d6 13 80 00       	push   $0x8013d6
  800091:	e8 13 01 00 00       	call   8001a9 <cprintf>
		if (i == 10)
  800096:	83 c4 20             	add    $0x20,%esp
  800099:	83 fb 0a             	cmp    $0xa,%ebx
  80009c:	74 18                	je     8000b6 <umain+0x83>
			return;
		i++;
  80009e:	83 c3 01             	add    $0x1,%ebx
		ipc_send(who, i, 0, 0);
  8000a1:	6a 00                	push   $0x0
  8000a3:	6a 00                	push   $0x0
  8000a5:	53                   	push   %ebx
  8000a6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8000a9:	e8 0e 0f 00 00       	call   800fbc <ipc_send>
		if (i == 10)
  8000ae:	83 c4 10             	add    $0x10,%esp
  8000b1:	83 fb 0a             	cmp    $0xa,%ebx
  8000b4:	75 bc                	jne    800072 <umain+0x3f>
			return;
	}

}
  8000b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000b9:	5b                   	pop    %ebx
  8000ba:	5e                   	pop    %esi
  8000bb:	5f                   	pop    %edi
  8000bc:	5d                   	pop    %ebp
  8000bd:	c3                   	ret    

008000be <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000be:	55                   	push   %ebp
  8000bf:	89 e5                	mov    %esp,%ebp
  8000c1:	56                   	push   %esi
  8000c2:	53                   	push   %ebx
  8000c3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000c6:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  8000c9:	e8 25 0a 00 00       	call   800af3 <sys_getenvid>
  8000ce:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000d3:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000d6:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000db:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000e0:	85 db                	test   %ebx,%ebx
  8000e2:	7e 07                	jle    8000eb <libmain+0x2d>
		binaryname = argv[0];
  8000e4:	8b 06                	mov    (%esi),%eax
  8000e6:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000eb:	83 ec 08             	sub    $0x8,%esp
  8000ee:	56                   	push   %esi
  8000ef:	53                   	push   %ebx
  8000f0:	e8 3e ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000f5:	e8 0a 00 00 00       	call   800104 <exit>
}
  8000fa:	83 c4 10             	add    $0x10,%esp
  8000fd:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800100:	5b                   	pop    %ebx
  800101:	5e                   	pop    %esi
  800102:	5d                   	pop    %ebp
  800103:	c3                   	ret    

00800104 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800104:	55                   	push   %ebp
  800105:	89 e5                	mov    %esp,%ebp
  800107:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80010a:	6a 00                	push   $0x0
  80010c:	e8 a1 09 00 00       	call   800ab2 <sys_env_destroy>
}
  800111:	83 c4 10             	add    $0x10,%esp
  800114:	c9                   	leave  
  800115:	c3                   	ret    

00800116 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800116:	55                   	push   %ebp
  800117:	89 e5                	mov    %esp,%ebp
  800119:	53                   	push   %ebx
  80011a:	83 ec 04             	sub    $0x4,%esp
  80011d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800120:	8b 13                	mov    (%ebx),%edx
  800122:	8d 42 01             	lea    0x1(%edx),%eax
  800125:	89 03                	mov    %eax,(%ebx)
  800127:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80012a:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80012e:	3d ff 00 00 00       	cmp    $0xff,%eax
  800133:	75 1a                	jne    80014f <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800135:	83 ec 08             	sub    $0x8,%esp
  800138:	68 ff 00 00 00       	push   $0xff
  80013d:	8d 43 08             	lea    0x8(%ebx),%eax
  800140:	50                   	push   %eax
  800141:	e8 2f 09 00 00       	call   800a75 <sys_cputs>
		b->idx = 0;
  800146:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80014c:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80014f:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800153:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800156:	c9                   	leave  
  800157:	c3                   	ret    

00800158 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800158:	55                   	push   %ebp
  800159:	89 e5                	mov    %esp,%ebp
  80015b:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800161:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800168:	00 00 00 
	b.cnt = 0;
  80016b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800172:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800175:	ff 75 0c             	pushl  0xc(%ebp)
  800178:	ff 75 08             	pushl  0x8(%ebp)
  80017b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800181:	50                   	push   %eax
  800182:	68 16 01 80 00       	push   $0x800116
  800187:	e8 54 01 00 00       	call   8002e0 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80018c:	83 c4 08             	add    $0x8,%esp
  80018f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800195:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80019b:	50                   	push   %eax
  80019c:	e8 d4 08 00 00       	call   800a75 <sys_cputs>

	return b.cnt;
}
  8001a1:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001a7:	c9                   	leave  
  8001a8:	c3                   	ret    

008001a9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001a9:	55                   	push   %ebp
  8001aa:	89 e5                	mov    %esp,%ebp
  8001ac:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001af:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001b2:	50                   	push   %eax
  8001b3:	ff 75 08             	pushl  0x8(%ebp)
  8001b6:	e8 9d ff ff ff       	call   800158 <vcprintf>
	va_end(ap);

	return cnt;
}
  8001bb:	c9                   	leave  
  8001bc:	c3                   	ret    

008001bd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001bd:	55                   	push   %ebp
  8001be:	89 e5                	mov    %esp,%ebp
  8001c0:	57                   	push   %edi
  8001c1:	56                   	push   %esi
  8001c2:	53                   	push   %ebx
  8001c3:	83 ec 1c             	sub    $0x1c,%esp
  8001c6:	89 c7                	mov    %eax,%edi
  8001c8:	89 d6                	mov    %edx,%esi
  8001ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8001cd:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001d3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001d6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8001d9:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001de:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8001e1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8001e4:	39 d3                	cmp    %edx,%ebx
  8001e6:	72 05                	jb     8001ed <printnum+0x30>
  8001e8:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001eb:	77 45                	ja     800232 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001ed:	83 ec 0c             	sub    $0xc,%esp
  8001f0:	ff 75 18             	pushl  0x18(%ebp)
  8001f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8001f6:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8001f9:	53                   	push   %ebx
  8001fa:	ff 75 10             	pushl  0x10(%ebp)
  8001fd:	83 ec 08             	sub    $0x8,%esp
  800200:	ff 75 e4             	pushl  -0x1c(%ebp)
  800203:	ff 75 e0             	pushl  -0x20(%ebp)
  800206:	ff 75 dc             	pushl  -0x24(%ebp)
  800209:	ff 75 d8             	pushl  -0x28(%ebp)
  80020c:	e8 1f 0f 00 00       	call   801130 <__udivdi3>
  800211:	83 c4 18             	add    $0x18,%esp
  800214:	52                   	push   %edx
  800215:	50                   	push   %eax
  800216:	89 f2                	mov    %esi,%edx
  800218:	89 f8                	mov    %edi,%eax
  80021a:	e8 9e ff ff ff       	call   8001bd <printnum>
  80021f:	83 c4 20             	add    $0x20,%esp
  800222:	eb 18                	jmp    80023c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800224:	83 ec 08             	sub    $0x8,%esp
  800227:	56                   	push   %esi
  800228:	ff 75 18             	pushl  0x18(%ebp)
  80022b:	ff d7                	call   *%edi
  80022d:	83 c4 10             	add    $0x10,%esp
  800230:	eb 03                	jmp    800235 <printnum+0x78>
  800232:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800235:	83 eb 01             	sub    $0x1,%ebx
  800238:	85 db                	test   %ebx,%ebx
  80023a:	7f e8                	jg     800224 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80023c:	83 ec 08             	sub    $0x8,%esp
  80023f:	56                   	push   %esi
  800240:	83 ec 04             	sub    $0x4,%esp
  800243:	ff 75 e4             	pushl  -0x1c(%ebp)
  800246:	ff 75 e0             	pushl  -0x20(%ebp)
  800249:	ff 75 dc             	pushl  -0x24(%ebp)
  80024c:	ff 75 d8             	pushl  -0x28(%ebp)
  80024f:	e8 0c 10 00 00       	call   801260 <__umoddi3>
  800254:	83 c4 14             	add    $0x14,%esp
  800257:	0f be 80 f3 13 80 00 	movsbl 0x8013f3(%eax),%eax
  80025e:	50                   	push   %eax
  80025f:	ff d7                	call   *%edi
}
  800261:	83 c4 10             	add    $0x10,%esp
  800264:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800267:	5b                   	pop    %ebx
  800268:	5e                   	pop    %esi
  800269:	5f                   	pop    %edi
  80026a:	5d                   	pop    %ebp
  80026b:	c3                   	ret    

0080026c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80026c:	55                   	push   %ebp
  80026d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80026f:	83 fa 01             	cmp    $0x1,%edx
  800272:	7e 0e                	jle    800282 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800274:	8b 10                	mov    (%eax),%edx
  800276:	8d 4a 08             	lea    0x8(%edx),%ecx
  800279:	89 08                	mov    %ecx,(%eax)
  80027b:	8b 02                	mov    (%edx),%eax
  80027d:	8b 52 04             	mov    0x4(%edx),%edx
  800280:	eb 22                	jmp    8002a4 <getuint+0x38>
	else if (lflag)
  800282:	85 d2                	test   %edx,%edx
  800284:	74 10                	je     800296 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800286:	8b 10                	mov    (%eax),%edx
  800288:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028b:	89 08                	mov    %ecx,(%eax)
  80028d:	8b 02                	mov    (%edx),%eax
  80028f:	ba 00 00 00 00       	mov    $0x0,%edx
  800294:	eb 0e                	jmp    8002a4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800296:	8b 10                	mov    (%eax),%edx
  800298:	8d 4a 04             	lea    0x4(%edx),%ecx
  80029b:	89 08                	mov    %ecx,(%eax)
  80029d:	8b 02                	mov    (%edx),%eax
  80029f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002a4:	5d                   	pop    %ebp
  8002a5:	c3                   	ret    

008002a6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002a6:	55                   	push   %ebp
  8002a7:	89 e5                	mov    %esp,%ebp
  8002a9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002ac:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002b0:	8b 10                	mov    (%eax),%edx
  8002b2:	3b 50 04             	cmp    0x4(%eax),%edx
  8002b5:	73 0a                	jae    8002c1 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002b7:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002ba:	89 08                	mov    %ecx,(%eax)
  8002bc:	8b 45 08             	mov    0x8(%ebp),%eax
  8002bf:	88 02                	mov    %al,(%edx)
}
  8002c1:	5d                   	pop    %ebp
  8002c2:	c3                   	ret    

008002c3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002c3:	55                   	push   %ebp
  8002c4:	89 e5                	mov    %esp,%ebp
  8002c6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002c9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002cc:	50                   	push   %eax
  8002cd:	ff 75 10             	pushl  0x10(%ebp)
  8002d0:	ff 75 0c             	pushl  0xc(%ebp)
  8002d3:	ff 75 08             	pushl  0x8(%ebp)
  8002d6:	e8 05 00 00 00       	call   8002e0 <vprintfmt>
	va_end(ap);
}
  8002db:	83 c4 10             	add    $0x10,%esp
  8002de:	c9                   	leave  
  8002df:	c3                   	ret    

008002e0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002e0:	55                   	push   %ebp
  8002e1:	89 e5                	mov    %esp,%ebp
  8002e3:	57                   	push   %edi
  8002e4:	56                   	push   %esi
  8002e5:	53                   	push   %ebx
  8002e6:	83 ec 2c             	sub    $0x2c,%esp
  8002e9:	8b 75 08             	mov    0x8(%ebp),%esi
  8002ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002ef:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002f2:	eb 12                	jmp    800306 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	0f 84 89 03 00 00    	je     800685 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  8002fc:	83 ec 08             	sub    $0x8,%esp
  8002ff:	53                   	push   %ebx
  800300:	50                   	push   %eax
  800301:	ff d6                	call   *%esi
  800303:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800306:	83 c7 01             	add    $0x1,%edi
  800309:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80030d:	83 f8 25             	cmp    $0x25,%eax
  800310:	75 e2                	jne    8002f4 <vprintfmt+0x14>
  800312:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800316:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80031d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800324:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80032b:	ba 00 00 00 00       	mov    $0x0,%edx
  800330:	eb 07                	jmp    800339 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800332:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800335:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800339:	8d 47 01             	lea    0x1(%edi),%eax
  80033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80033f:	0f b6 07             	movzbl (%edi),%eax
  800342:	0f b6 c8             	movzbl %al,%ecx
  800345:	83 e8 23             	sub    $0x23,%eax
  800348:	3c 55                	cmp    $0x55,%al
  80034a:	0f 87 1a 03 00 00    	ja     80066a <vprintfmt+0x38a>
  800350:	0f b6 c0             	movzbl %al,%eax
  800353:	ff 24 85 c0 14 80 00 	jmp    *0x8014c0(,%eax,4)
  80035a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80035d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800361:	eb d6                	jmp    800339 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800363:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800366:	b8 00 00 00 00       	mov    $0x0,%eax
  80036b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80036e:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800371:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800375:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800378:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80037b:	83 fa 09             	cmp    $0x9,%edx
  80037e:	77 39                	ja     8003b9 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800380:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800383:	eb e9                	jmp    80036e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800385:	8b 45 14             	mov    0x14(%ebp),%eax
  800388:	8d 48 04             	lea    0x4(%eax),%ecx
  80038b:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80038e:	8b 00                	mov    (%eax),%eax
  800390:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800393:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800396:	eb 27                	jmp    8003bf <vprintfmt+0xdf>
  800398:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80039b:	85 c0                	test   %eax,%eax
  80039d:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003a2:	0f 49 c8             	cmovns %eax,%ecx
  8003a5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ab:	eb 8c                	jmp    800339 <vprintfmt+0x59>
  8003ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003b0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003b7:	eb 80                	jmp    800339 <vprintfmt+0x59>
  8003b9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8003bc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003bf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003c3:	0f 89 70 ff ff ff    	jns    800339 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003c9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003cc:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003cf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003d6:	e9 5e ff ff ff       	jmp    800339 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003db:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003e1:	e9 53 ff ff ff       	jmp    800339 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e9:	8d 50 04             	lea    0x4(%eax),%edx
  8003ec:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ef:	83 ec 08             	sub    $0x8,%esp
  8003f2:	53                   	push   %ebx
  8003f3:	ff 30                	pushl  (%eax)
  8003f5:	ff d6                	call   *%esi
			break;
  8003f7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003fd:	e9 04 ff ff ff       	jmp    800306 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800402:	8b 45 14             	mov    0x14(%ebp),%eax
  800405:	8d 50 04             	lea    0x4(%eax),%edx
  800408:	89 55 14             	mov    %edx,0x14(%ebp)
  80040b:	8b 00                	mov    (%eax),%eax
  80040d:	99                   	cltd   
  80040e:	31 d0                	xor    %edx,%eax
  800410:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800412:	83 f8 08             	cmp    $0x8,%eax
  800415:	7f 0b                	jg     800422 <vprintfmt+0x142>
  800417:	8b 14 85 20 16 80 00 	mov    0x801620(,%eax,4),%edx
  80041e:	85 d2                	test   %edx,%edx
  800420:	75 18                	jne    80043a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800422:	50                   	push   %eax
  800423:	68 0b 14 80 00       	push   $0x80140b
  800428:	53                   	push   %ebx
  800429:	56                   	push   %esi
  80042a:	e8 94 fe ff ff       	call   8002c3 <printfmt>
  80042f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800432:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800435:	e9 cc fe ff ff       	jmp    800306 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80043a:	52                   	push   %edx
  80043b:	68 14 14 80 00       	push   $0x801414
  800440:	53                   	push   %ebx
  800441:	56                   	push   %esi
  800442:	e8 7c fe ff ff       	call   8002c3 <printfmt>
  800447:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80044d:	e9 b4 fe ff ff       	jmp    800306 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800452:	8b 45 14             	mov    0x14(%ebp),%eax
  800455:	8d 50 04             	lea    0x4(%eax),%edx
  800458:	89 55 14             	mov    %edx,0x14(%ebp)
  80045b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80045d:	85 ff                	test   %edi,%edi
  80045f:	b8 04 14 80 00       	mov    $0x801404,%eax
  800464:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800467:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80046b:	0f 8e 94 00 00 00    	jle    800505 <vprintfmt+0x225>
  800471:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800475:	0f 84 98 00 00 00    	je     800513 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80047b:	83 ec 08             	sub    $0x8,%esp
  80047e:	ff 75 d0             	pushl  -0x30(%ebp)
  800481:	57                   	push   %edi
  800482:	e8 86 02 00 00       	call   80070d <strnlen>
  800487:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80048a:	29 c1                	sub    %eax,%ecx
  80048c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80048f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800492:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800496:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800499:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80049c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80049e:	eb 0f                	jmp    8004af <vprintfmt+0x1cf>
					putch(padc, putdat);
  8004a0:	83 ec 08             	sub    $0x8,%esp
  8004a3:	53                   	push   %ebx
  8004a4:	ff 75 e0             	pushl  -0x20(%ebp)
  8004a7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a9:	83 ef 01             	sub    $0x1,%edi
  8004ac:	83 c4 10             	add    $0x10,%esp
  8004af:	85 ff                	test   %edi,%edi
  8004b1:	7f ed                	jg     8004a0 <vprintfmt+0x1c0>
  8004b3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004b6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8004b9:	85 c9                	test   %ecx,%ecx
  8004bb:	b8 00 00 00 00       	mov    $0x0,%eax
  8004c0:	0f 49 c1             	cmovns %ecx,%eax
  8004c3:	29 c1                	sub    %eax,%ecx
  8004c5:	89 75 08             	mov    %esi,0x8(%ebp)
  8004c8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004cb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ce:	89 cb                	mov    %ecx,%ebx
  8004d0:	eb 4d                	jmp    80051f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004d2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004d6:	74 1b                	je     8004f3 <vprintfmt+0x213>
  8004d8:	0f be c0             	movsbl %al,%eax
  8004db:	83 e8 20             	sub    $0x20,%eax
  8004de:	83 f8 5e             	cmp    $0x5e,%eax
  8004e1:	76 10                	jbe    8004f3 <vprintfmt+0x213>
					putch('?', putdat);
  8004e3:	83 ec 08             	sub    $0x8,%esp
  8004e6:	ff 75 0c             	pushl  0xc(%ebp)
  8004e9:	6a 3f                	push   $0x3f
  8004eb:	ff 55 08             	call   *0x8(%ebp)
  8004ee:	83 c4 10             	add    $0x10,%esp
  8004f1:	eb 0d                	jmp    800500 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004f3:	83 ec 08             	sub    $0x8,%esp
  8004f6:	ff 75 0c             	pushl  0xc(%ebp)
  8004f9:	52                   	push   %edx
  8004fa:	ff 55 08             	call   *0x8(%ebp)
  8004fd:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800500:	83 eb 01             	sub    $0x1,%ebx
  800503:	eb 1a                	jmp    80051f <vprintfmt+0x23f>
  800505:	89 75 08             	mov    %esi,0x8(%ebp)
  800508:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80050b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80050e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800511:	eb 0c                	jmp    80051f <vprintfmt+0x23f>
  800513:	89 75 08             	mov    %esi,0x8(%ebp)
  800516:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800519:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80051c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80051f:	83 c7 01             	add    $0x1,%edi
  800522:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800526:	0f be d0             	movsbl %al,%edx
  800529:	85 d2                	test   %edx,%edx
  80052b:	74 23                	je     800550 <vprintfmt+0x270>
  80052d:	85 f6                	test   %esi,%esi
  80052f:	78 a1                	js     8004d2 <vprintfmt+0x1f2>
  800531:	83 ee 01             	sub    $0x1,%esi
  800534:	79 9c                	jns    8004d2 <vprintfmt+0x1f2>
  800536:	89 df                	mov    %ebx,%edi
  800538:	8b 75 08             	mov    0x8(%ebp),%esi
  80053b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80053e:	eb 18                	jmp    800558 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800540:	83 ec 08             	sub    $0x8,%esp
  800543:	53                   	push   %ebx
  800544:	6a 20                	push   $0x20
  800546:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800548:	83 ef 01             	sub    $0x1,%edi
  80054b:	83 c4 10             	add    $0x10,%esp
  80054e:	eb 08                	jmp    800558 <vprintfmt+0x278>
  800550:	89 df                	mov    %ebx,%edi
  800552:	8b 75 08             	mov    0x8(%ebp),%esi
  800555:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800558:	85 ff                	test   %edi,%edi
  80055a:	7f e4                	jg     800540 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80055f:	e9 a2 fd ff ff       	jmp    800306 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800564:	83 fa 01             	cmp    $0x1,%edx
  800567:	7e 16                	jle    80057f <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  800569:	8b 45 14             	mov    0x14(%ebp),%eax
  80056c:	8d 50 08             	lea    0x8(%eax),%edx
  80056f:	89 55 14             	mov    %edx,0x14(%ebp)
  800572:	8b 50 04             	mov    0x4(%eax),%edx
  800575:	8b 00                	mov    (%eax),%eax
  800577:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80057a:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80057d:	eb 32                	jmp    8005b1 <vprintfmt+0x2d1>
	else if (lflag)
  80057f:	85 d2                	test   %edx,%edx
  800581:	74 18                	je     80059b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800583:	8b 45 14             	mov    0x14(%ebp),%eax
  800586:	8d 50 04             	lea    0x4(%eax),%edx
  800589:	89 55 14             	mov    %edx,0x14(%ebp)
  80058c:	8b 00                	mov    (%eax),%eax
  80058e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800591:	89 c1                	mov    %eax,%ecx
  800593:	c1 f9 1f             	sar    $0x1f,%ecx
  800596:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800599:	eb 16                	jmp    8005b1 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80059b:	8b 45 14             	mov    0x14(%ebp),%eax
  80059e:	8d 50 04             	lea    0x4(%eax),%edx
  8005a1:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a4:	8b 00                	mov    (%eax),%eax
  8005a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a9:	89 c1                	mov    %eax,%ecx
  8005ab:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ae:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8005b4:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005b7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005bc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005c0:	79 74                	jns    800636 <vprintfmt+0x356>
				putch('-', putdat);
  8005c2:	83 ec 08             	sub    $0x8,%esp
  8005c5:	53                   	push   %ebx
  8005c6:	6a 2d                	push   $0x2d
  8005c8:	ff d6                	call   *%esi
				num = -(long long) num;
  8005ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8005cd:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8005d0:	f7 d8                	neg    %eax
  8005d2:	83 d2 00             	adc    $0x0,%edx
  8005d5:	f7 da                	neg    %edx
  8005d7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8005da:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8005df:	eb 55                	jmp    800636 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005e1:	8d 45 14             	lea    0x14(%ebp),%eax
  8005e4:	e8 83 fc ff ff       	call   80026c <getuint>
			base = 10;
  8005e9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8005ee:	eb 46                	jmp    800636 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8005f0:	8d 45 14             	lea    0x14(%ebp),%eax
  8005f3:	e8 74 fc ff ff       	call   80026c <getuint>
			base = 8;
  8005f8:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8005fd:	eb 37                	jmp    800636 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  8005ff:	83 ec 08             	sub    $0x8,%esp
  800602:	53                   	push   %ebx
  800603:	6a 30                	push   $0x30
  800605:	ff d6                	call   *%esi
			putch('x', putdat);
  800607:	83 c4 08             	add    $0x8,%esp
  80060a:	53                   	push   %ebx
  80060b:	6a 78                	push   $0x78
  80060d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80060f:	8b 45 14             	mov    0x14(%ebp),%eax
  800612:	8d 50 04             	lea    0x4(%eax),%edx
  800615:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800618:	8b 00                	mov    (%eax),%eax
  80061a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80061f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800622:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800627:	eb 0d                	jmp    800636 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800629:	8d 45 14             	lea    0x14(%ebp),%eax
  80062c:	e8 3b fc ff ff       	call   80026c <getuint>
			base = 16;
  800631:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800636:	83 ec 0c             	sub    $0xc,%esp
  800639:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80063d:	57                   	push   %edi
  80063e:	ff 75 e0             	pushl  -0x20(%ebp)
  800641:	51                   	push   %ecx
  800642:	52                   	push   %edx
  800643:	50                   	push   %eax
  800644:	89 da                	mov    %ebx,%edx
  800646:	89 f0                	mov    %esi,%eax
  800648:	e8 70 fb ff ff       	call   8001bd <printnum>
			break;
  80064d:	83 c4 20             	add    $0x20,%esp
  800650:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800653:	e9 ae fc ff ff       	jmp    800306 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800658:	83 ec 08             	sub    $0x8,%esp
  80065b:	53                   	push   %ebx
  80065c:	51                   	push   %ecx
  80065d:	ff d6                	call   *%esi
			break;
  80065f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800662:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800665:	e9 9c fc ff ff       	jmp    800306 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80066a:	83 ec 08             	sub    $0x8,%esp
  80066d:	53                   	push   %ebx
  80066e:	6a 25                	push   $0x25
  800670:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800672:	83 c4 10             	add    $0x10,%esp
  800675:	eb 03                	jmp    80067a <vprintfmt+0x39a>
  800677:	83 ef 01             	sub    $0x1,%edi
  80067a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80067e:	75 f7                	jne    800677 <vprintfmt+0x397>
  800680:	e9 81 fc ff ff       	jmp    800306 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800685:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800688:	5b                   	pop    %ebx
  800689:	5e                   	pop    %esi
  80068a:	5f                   	pop    %edi
  80068b:	5d                   	pop    %ebp
  80068c:	c3                   	ret    

0080068d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80068d:	55                   	push   %ebp
  80068e:	89 e5                	mov    %esp,%ebp
  800690:	83 ec 18             	sub    $0x18,%esp
  800693:	8b 45 08             	mov    0x8(%ebp),%eax
  800696:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800699:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80069c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006a0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006aa:	85 c0                	test   %eax,%eax
  8006ac:	74 26                	je     8006d4 <vsnprintf+0x47>
  8006ae:	85 d2                	test   %edx,%edx
  8006b0:	7e 22                	jle    8006d4 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006b2:	ff 75 14             	pushl  0x14(%ebp)
  8006b5:	ff 75 10             	pushl  0x10(%ebp)
  8006b8:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006bb:	50                   	push   %eax
  8006bc:	68 a6 02 80 00       	push   $0x8002a6
  8006c1:	e8 1a fc ff ff       	call   8002e0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006c9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006cf:	83 c4 10             	add    $0x10,%esp
  8006d2:	eb 05                	jmp    8006d9 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006d4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006d9:	c9                   	leave  
  8006da:	c3                   	ret    

008006db <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006db:	55                   	push   %ebp
  8006dc:	89 e5                	mov    %esp,%ebp
  8006de:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006e1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006e4:	50                   	push   %eax
  8006e5:	ff 75 10             	pushl  0x10(%ebp)
  8006e8:	ff 75 0c             	pushl  0xc(%ebp)
  8006eb:	ff 75 08             	pushl  0x8(%ebp)
  8006ee:	e8 9a ff ff ff       	call   80068d <vsnprintf>
	va_end(ap);

	return rc;
}
  8006f3:	c9                   	leave  
  8006f4:	c3                   	ret    

008006f5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8006f5:	55                   	push   %ebp
  8006f6:	89 e5                	mov    %esp,%ebp
  8006f8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8006fb:	b8 00 00 00 00       	mov    $0x0,%eax
  800700:	eb 03                	jmp    800705 <strlen+0x10>
		n++;
  800702:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800705:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800709:	75 f7                	jne    800702 <strlen+0xd>
		n++;
	return n;
}
  80070b:	5d                   	pop    %ebp
  80070c:	c3                   	ret    

0080070d <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80070d:	55                   	push   %ebp
  80070e:	89 e5                	mov    %esp,%ebp
  800710:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800713:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800716:	ba 00 00 00 00       	mov    $0x0,%edx
  80071b:	eb 03                	jmp    800720 <strnlen+0x13>
		n++;
  80071d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800720:	39 c2                	cmp    %eax,%edx
  800722:	74 08                	je     80072c <strnlen+0x1f>
  800724:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800728:	75 f3                	jne    80071d <strnlen+0x10>
  80072a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80072c:	5d                   	pop    %ebp
  80072d:	c3                   	ret    

0080072e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80072e:	55                   	push   %ebp
  80072f:	89 e5                	mov    %esp,%ebp
  800731:	53                   	push   %ebx
  800732:	8b 45 08             	mov    0x8(%ebp),%eax
  800735:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800738:	89 c2                	mov    %eax,%edx
  80073a:	83 c2 01             	add    $0x1,%edx
  80073d:	83 c1 01             	add    $0x1,%ecx
  800740:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800744:	88 5a ff             	mov    %bl,-0x1(%edx)
  800747:	84 db                	test   %bl,%bl
  800749:	75 ef                	jne    80073a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80074b:	5b                   	pop    %ebx
  80074c:	5d                   	pop    %ebp
  80074d:	c3                   	ret    

0080074e <strcat>:

char *
strcat(char *dst, const char *src)
{
  80074e:	55                   	push   %ebp
  80074f:	89 e5                	mov    %esp,%ebp
  800751:	53                   	push   %ebx
  800752:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800755:	53                   	push   %ebx
  800756:	e8 9a ff ff ff       	call   8006f5 <strlen>
  80075b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80075e:	ff 75 0c             	pushl  0xc(%ebp)
  800761:	01 d8                	add    %ebx,%eax
  800763:	50                   	push   %eax
  800764:	e8 c5 ff ff ff       	call   80072e <strcpy>
	return dst;
}
  800769:	89 d8                	mov    %ebx,%eax
  80076b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80076e:	c9                   	leave  
  80076f:	c3                   	ret    

00800770 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800770:	55                   	push   %ebp
  800771:	89 e5                	mov    %esp,%ebp
  800773:	56                   	push   %esi
  800774:	53                   	push   %ebx
  800775:	8b 75 08             	mov    0x8(%ebp),%esi
  800778:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80077b:	89 f3                	mov    %esi,%ebx
  80077d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800780:	89 f2                	mov    %esi,%edx
  800782:	eb 0f                	jmp    800793 <strncpy+0x23>
		*dst++ = *src;
  800784:	83 c2 01             	add    $0x1,%edx
  800787:	0f b6 01             	movzbl (%ecx),%eax
  80078a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80078d:	80 39 01             	cmpb   $0x1,(%ecx)
  800790:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800793:	39 da                	cmp    %ebx,%edx
  800795:	75 ed                	jne    800784 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800797:	89 f0                	mov    %esi,%eax
  800799:	5b                   	pop    %ebx
  80079a:	5e                   	pop    %esi
  80079b:	5d                   	pop    %ebp
  80079c:	c3                   	ret    

0080079d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80079d:	55                   	push   %ebp
  80079e:	89 e5                	mov    %esp,%ebp
  8007a0:	56                   	push   %esi
  8007a1:	53                   	push   %ebx
  8007a2:	8b 75 08             	mov    0x8(%ebp),%esi
  8007a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007a8:	8b 55 10             	mov    0x10(%ebp),%edx
  8007ab:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007ad:	85 d2                	test   %edx,%edx
  8007af:	74 21                	je     8007d2 <strlcpy+0x35>
  8007b1:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007b5:	89 f2                	mov    %esi,%edx
  8007b7:	eb 09                	jmp    8007c2 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007b9:	83 c2 01             	add    $0x1,%edx
  8007bc:	83 c1 01             	add    $0x1,%ecx
  8007bf:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007c2:	39 c2                	cmp    %eax,%edx
  8007c4:	74 09                	je     8007cf <strlcpy+0x32>
  8007c6:	0f b6 19             	movzbl (%ecx),%ebx
  8007c9:	84 db                	test   %bl,%bl
  8007cb:	75 ec                	jne    8007b9 <strlcpy+0x1c>
  8007cd:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007cf:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007d2:	29 f0                	sub    %esi,%eax
}
  8007d4:	5b                   	pop    %ebx
  8007d5:	5e                   	pop    %esi
  8007d6:	5d                   	pop    %ebp
  8007d7:	c3                   	ret    

008007d8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007d8:	55                   	push   %ebp
  8007d9:	89 e5                	mov    %esp,%ebp
  8007db:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007de:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007e1:	eb 06                	jmp    8007e9 <strcmp+0x11>
		p++, q++;
  8007e3:	83 c1 01             	add    $0x1,%ecx
  8007e6:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8007e9:	0f b6 01             	movzbl (%ecx),%eax
  8007ec:	84 c0                	test   %al,%al
  8007ee:	74 04                	je     8007f4 <strcmp+0x1c>
  8007f0:	3a 02                	cmp    (%edx),%al
  8007f2:	74 ef                	je     8007e3 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8007f4:	0f b6 c0             	movzbl %al,%eax
  8007f7:	0f b6 12             	movzbl (%edx),%edx
  8007fa:	29 d0                	sub    %edx,%eax
}
  8007fc:	5d                   	pop    %ebp
  8007fd:	c3                   	ret    

008007fe <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8007fe:	55                   	push   %ebp
  8007ff:	89 e5                	mov    %esp,%ebp
  800801:	53                   	push   %ebx
  800802:	8b 45 08             	mov    0x8(%ebp),%eax
  800805:	8b 55 0c             	mov    0xc(%ebp),%edx
  800808:	89 c3                	mov    %eax,%ebx
  80080a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80080d:	eb 06                	jmp    800815 <strncmp+0x17>
		n--, p++, q++;
  80080f:	83 c0 01             	add    $0x1,%eax
  800812:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800815:	39 d8                	cmp    %ebx,%eax
  800817:	74 15                	je     80082e <strncmp+0x30>
  800819:	0f b6 08             	movzbl (%eax),%ecx
  80081c:	84 c9                	test   %cl,%cl
  80081e:	74 04                	je     800824 <strncmp+0x26>
  800820:	3a 0a                	cmp    (%edx),%cl
  800822:	74 eb                	je     80080f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800824:	0f b6 00             	movzbl (%eax),%eax
  800827:	0f b6 12             	movzbl (%edx),%edx
  80082a:	29 d0                	sub    %edx,%eax
  80082c:	eb 05                	jmp    800833 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80082e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800833:	5b                   	pop    %ebx
  800834:	5d                   	pop    %ebp
  800835:	c3                   	ret    

00800836 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800836:	55                   	push   %ebp
  800837:	89 e5                	mov    %esp,%ebp
  800839:	8b 45 08             	mov    0x8(%ebp),%eax
  80083c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800840:	eb 07                	jmp    800849 <strchr+0x13>
		if (*s == c)
  800842:	38 ca                	cmp    %cl,%dl
  800844:	74 0f                	je     800855 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800846:	83 c0 01             	add    $0x1,%eax
  800849:	0f b6 10             	movzbl (%eax),%edx
  80084c:	84 d2                	test   %dl,%dl
  80084e:	75 f2                	jne    800842 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800850:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800855:	5d                   	pop    %ebp
  800856:	c3                   	ret    

00800857 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800857:	55                   	push   %ebp
  800858:	89 e5                	mov    %esp,%ebp
  80085a:	8b 45 08             	mov    0x8(%ebp),%eax
  80085d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800861:	eb 03                	jmp    800866 <strfind+0xf>
  800863:	83 c0 01             	add    $0x1,%eax
  800866:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800869:	38 ca                	cmp    %cl,%dl
  80086b:	74 04                	je     800871 <strfind+0x1a>
  80086d:	84 d2                	test   %dl,%dl
  80086f:	75 f2                	jne    800863 <strfind+0xc>
			break;
	return (char *) s;
}
  800871:	5d                   	pop    %ebp
  800872:	c3                   	ret    

00800873 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800873:	55                   	push   %ebp
  800874:	89 e5                	mov    %esp,%ebp
  800876:	57                   	push   %edi
  800877:	56                   	push   %esi
  800878:	53                   	push   %ebx
  800879:	8b 7d 08             	mov    0x8(%ebp),%edi
  80087c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80087f:	85 c9                	test   %ecx,%ecx
  800881:	74 36                	je     8008b9 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800883:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800889:	75 28                	jne    8008b3 <memset+0x40>
  80088b:	f6 c1 03             	test   $0x3,%cl
  80088e:	75 23                	jne    8008b3 <memset+0x40>
		c &= 0xFF;
  800890:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800894:	89 d3                	mov    %edx,%ebx
  800896:	c1 e3 08             	shl    $0x8,%ebx
  800899:	89 d6                	mov    %edx,%esi
  80089b:	c1 e6 18             	shl    $0x18,%esi
  80089e:	89 d0                	mov    %edx,%eax
  8008a0:	c1 e0 10             	shl    $0x10,%eax
  8008a3:	09 f0                	or     %esi,%eax
  8008a5:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008a7:	89 d8                	mov    %ebx,%eax
  8008a9:	09 d0                	or     %edx,%eax
  8008ab:	c1 e9 02             	shr    $0x2,%ecx
  8008ae:	fc                   	cld    
  8008af:	f3 ab                	rep stos %eax,%es:(%edi)
  8008b1:	eb 06                	jmp    8008b9 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008b6:	fc                   	cld    
  8008b7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008b9:	89 f8                	mov    %edi,%eax
  8008bb:	5b                   	pop    %ebx
  8008bc:	5e                   	pop    %esi
  8008bd:	5f                   	pop    %edi
  8008be:	5d                   	pop    %ebp
  8008bf:	c3                   	ret    

008008c0 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008c0:	55                   	push   %ebp
  8008c1:	89 e5                	mov    %esp,%ebp
  8008c3:	57                   	push   %edi
  8008c4:	56                   	push   %esi
  8008c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c8:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008ce:	39 c6                	cmp    %eax,%esi
  8008d0:	73 35                	jae    800907 <memmove+0x47>
  8008d2:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008d5:	39 d0                	cmp    %edx,%eax
  8008d7:	73 2e                	jae    800907 <memmove+0x47>
		s += n;
		d += n;
  8008d9:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008dc:	89 d6                	mov    %edx,%esi
  8008de:	09 fe                	or     %edi,%esi
  8008e0:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008e6:	75 13                	jne    8008fb <memmove+0x3b>
  8008e8:	f6 c1 03             	test   $0x3,%cl
  8008eb:	75 0e                	jne    8008fb <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8008ed:	83 ef 04             	sub    $0x4,%edi
  8008f0:	8d 72 fc             	lea    -0x4(%edx),%esi
  8008f3:	c1 e9 02             	shr    $0x2,%ecx
  8008f6:	fd                   	std    
  8008f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008f9:	eb 09                	jmp    800904 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8008fb:	83 ef 01             	sub    $0x1,%edi
  8008fe:	8d 72 ff             	lea    -0x1(%edx),%esi
  800901:	fd                   	std    
  800902:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800904:	fc                   	cld    
  800905:	eb 1d                	jmp    800924 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800907:	89 f2                	mov    %esi,%edx
  800909:	09 c2                	or     %eax,%edx
  80090b:	f6 c2 03             	test   $0x3,%dl
  80090e:	75 0f                	jne    80091f <memmove+0x5f>
  800910:	f6 c1 03             	test   $0x3,%cl
  800913:	75 0a                	jne    80091f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800915:	c1 e9 02             	shr    $0x2,%ecx
  800918:	89 c7                	mov    %eax,%edi
  80091a:	fc                   	cld    
  80091b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80091d:	eb 05                	jmp    800924 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80091f:	89 c7                	mov    %eax,%edi
  800921:	fc                   	cld    
  800922:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800924:	5e                   	pop    %esi
  800925:	5f                   	pop    %edi
  800926:	5d                   	pop    %ebp
  800927:	c3                   	ret    

00800928 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800928:	55                   	push   %ebp
  800929:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80092b:	ff 75 10             	pushl  0x10(%ebp)
  80092e:	ff 75 0c             	pushl  0xc(%ebp)
  800931:	ff 75 08             	pushl  0x8(%ebp)
  800934:	e8 87 ff ff ff       	call   8008c0 <memmove>
}
  800939:	c9                   	leave  
  80093a:	c3                   	ret    

0080093b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80093b:	55                   	push   %ebp
  80093c:	89 e5                	mov    %esp,%ebp
  80093e:	56                   	push   %esi
  80093f:	53                   	push   %ebx
  800940:	8b 45 08             	mov    0x8(%ebp),%eax
  800943:	8b 55 0c             	mov    0xc(%ebp),%edx
  800946:	89 c6                	mov    %eax,%esi
  800948:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80094b:	eb 1a                	jmp    800967 <memcmp+0x2c>
		if (*s1 != *s2)
  80094d:	0f b6 08             	movzbl (%eax),%ecx
  800950:	0f b6 1a             	movzbl (%edx),%ebx
  800953:	38 d9                	cmp    %bl,%cl
  800955:	74 0a                	je     800961 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800957:	0f b6 c1             	movzbl %cl,%eax
  80095a:	0f b6 db             	movzbl %bl,%ebx
  80095d:	29 d8                	sub    %ebx,%eax
  80095f:	eb 0f                	jmp    800970 <memcmp+0x35>
		s1++, s2++;
  800961:	83 c0 01             	add    $0x1,%eax
  800964:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800967:	39 f0                	cmp    %esi,%eax
  800969:	75 e2                	jne    80094d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80096b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800970:	5b                   	pop    %ebx
  800971:	5e                   	pop    %esi
  800972:	5d                   	pop    %ebp
  800973:	c3                   	ret    

00800974 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800974:	55                   	push   %ebp
  800975:	89 e5                	mov    %esp,%ebp
  800977:	53                   	push   %ebx
  800978:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80097b:	89 c1                	mov    %eax,%ecx
  80097d:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800980:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800984:	eb 0a                	jmp    800990 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800986:	0f b6 10             	movzbl (%eax),%edx
  800989:	39 da                	cmp    %ebx,%edx
  80098b:	74 07                	je     800994 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80098d:	83 c0 01             	add    $0x1,%eax
  800990:	39 c8                	cmp    %ecx,%eax
  800992:	72 f2                	jb     800986 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800994:	5b                   	pop    %ebx
  800995:	5d                   	pop    %ebp
  800996:	c3                   	ret    

00800997 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800997:	55                   	push   %ebp
  800998:	89 e5                	mov    %esp,%ebp
  80099a:	57                   	push   %edi
  80099b:	56                   	push   %esi
  80099c:	53                   	push   %ebx
  80099d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009a0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009a3:	eb 03                	jmp    8009a8 <strtol+0x11>
		s++;
  8009a5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009a8:	0f b6 01             	movzbl (%ecx),%eax
  8009ab:	3c 20                	cmp    $0x20,%al
  8009ad:	74 f6                	je     8009a5 <strtol+0xe>
  8009af:	3c 09                	cmp    $0x9,%al
  8009b1:	74 f2                	je     8009a5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009b3:	3c 2b                	cmp    $0x2b,%al
  8009b5:	75 0a                	jne    8009c1 <strtol+0x2a>
		s++;
  8009b7:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009ba:	bf 00 00 00 00       	mov    $0x0,%edi
  8009bf:	eb 11                	jmp    8009d2 <strtol+0x3b>
  8009c1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009c6:	3c 2d                	cmp    $0x2d,%al
  8009c8:	75 08                	jne    8009d2 <strtol+0x3b>
		s++, neg = 1;
  8009ca:	83 c1 01             	add    $0x1,%ecx
  8009cd:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009d2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009d8:	75 15                	jne    8009ef <strtol+0x58>
  8009da:	80 39 30             	cmpb   $0x30,(%ecx)
  8009dd:	75 10                	jne    8009ef <strtol+0x58>
  8009df:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009e3:	75 7c                	jne    800a61 <strtol+0xca>
		s += 2, base = 16;
  8009e5:	83 c1 02             	add    $0x2,%ecx
  8009e8:	bb 10 00 00 00       	mov    $0x10,%ebx
  8009ed:	eb 16                	jmp    800a05 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  8009ef:	85 db                	test   %ebx,%ebx
  8009f1:	75 12                	jne    800a05 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  8009f3:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009f8:	80 39 30             	cmpb   $0x30,(%ecx)
  8009fb:	75 08                	jne    800a05 <strtol+0x6e>
		s++, base = 8;
  8009fd:	83 c1 01             	add    $0x1,%ecx
  800a00:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a05:	b8 00 00 00 00       	mov    $0x0,%eax
  800a0a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a0d:	0f b6 11             	movzbl (%ecx),%edx
  800a10:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a13:	89 f3                	mov    %esi,%ebx
  800a15:	80 fb 09             	cmp    $0x9,%bl
  800a18:	77 08                	ja     800a22 <strtol+0x8b>
			dig = *s - '0';
  800a1a:	0f be d2             	movsbl %dl,%edx
  800a1d:	83 ea 30             	sub    $0x30,%edx
  800a20:	eb 22                	jmp    800a44 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a22:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a25:	89 f3                	mov    %esi,%ebx
  800a27:	80 fb 19             	cmp    $0x19,%bl
  800a2a:	77 08                	ja     800a34 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a2c:	0f be d2             	movsbl %dl,%edx
  800a2f:	83 ea 57             	sub    $0x57,%edx
  800a32:	eb 10                	jmp    800a44 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a34:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a37:	89 f3                	mov    %esi,%ebx
  800a39:	80 fb 19             	cmp    $0x19,%bl
  800a3c:	77 16                	ja     800a54 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a3e:	0f be d2             	movsbl %dl,%edx
  800a41:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a44:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a47:	7d 0b                	jge    800a54 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a49:	83 c1 01             	add    $0x1,%ecx
  800a4c:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a50:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a52:	eb b9                	jmp    800a0d <strtol+0x76>

	if (endptr)
  800a54:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a58:	74 0d                	je     800a67 <strtol+0xd0>
		*endptr = (char *) s;
  800a5a:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a5d:	89 0e                	mov    %ecx,(%esi)
  800a5f:	eb 06                	jmp    800a67 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a61:	85 db                	test   %ebx,%ebx
  800a63:	74 98                	je     8009fd <strtol+0x66>
  800a65:	eb 9e                	jmp    800a05 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a67:	89 c2                	mov    %eax,%edx
  800a69:	f7 da                	neg    %edx
  800a6b:	85 ff                	test   %edi,%edi
  800a6d:	0f 45 c2             	cmovne %edx,%eax
}
  800a70:	5b                   	pop    %ebx
  800a71:	5e                   	pop    %esi
  800a72:	5f                   	pop    %edi
  800a73:	5d                   	pop    %ebp
  800a74:	c3                   	ret    

00800a75 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a75:	55                   	push   %ebp
  800a76:	89 e5                	mov    %esp,%ebp
  800a78:	57                   	push   %edi
  800a79:	56                   	push   %esi
  800a7a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a7b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a80:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a83:	8b 55 08             	mov    0x8(%ebp),%edx
  800a86:	89 c3                	mov    %eax,%ebx
  800a88:	89 c7                	mov    %eax,%edi
  800a8a:	89 c6                	mov    %eax,%esi
  800a8c:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a8e:	5b                   	pop    %ebx
  800a8f:	5e                   	pop    %esi
  800a90:	5f                   	pop    %edi
  800a91:	5d                   	pop    %ebp
  800a92:	c3                   	ret    

00800a93 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a93:	55                   	push   %ebp
  800a94:	89 e5                	mov    %esp,%ebp
  800a96:	57                   	push   %edi
  800a97:	56                   	push   %esi
  800a98:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a99:	ba 00 00 00 00       	mov    $0x0,%edx
  800a9e:	b8 01 00 00 00       	mov    $0x1,%eax
  800aa3:	89 d1                	mov    %edx,%ecx
  800aa5:	89 d3                	mov    %edx,%ebx
  800aa7:	89 d7                	mov    %edx,%edi
  800aa9:	89 d6                	mov    %edx,%esi
  800aab:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800aad:	5b                   	pop    %ebx
  800aae:	5e                   	pop    %esi
  800aaf:	5f                   	pop    %edi
  800ab0:	5d                   	pop    %ebp
  800ab1:	c3                   	ret    

00800ab2 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ab2:	55                   	push   %ebp
  800ab3:	89 e5                	mov    %esp,%ebp
  800ab5:	57                   	push   %edi
  800ab6:	56                   	push   %esi
  800ab7:	53                   	push   %ebx
  800ab8:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800abb:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ac0:	b8 03 00 00 00       	mov    $0x3,%eax
  800ac5:	8b 55 08             	mov    0x8(%ebp),%edx
  800ac8:	89 cb                	mov    %ecx,%ebx
  800aca:	89 cf                	mov    %ecx,%edi
  800acc:	89 ce                	mov    %ecx,%esi
  800ace:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800ad0:	85 c0                	test   %eax,%eax
  800ad2:	7e 17                	jle    800aeb <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ad4:	83 ec 0c             	sub    $0xc,%esp
  800ad7:	50                   	push   %eax
  800ad8:	6a 03                	push   $0x3
  800ada:	68 44 16 80 00       	push   $0x801644
  800adf:	6a 23                	push   $0x23
  800ae1:	68 61 16 80 00       	push   $0x801661
  800ae6:	e8 5e 05 00 00       	call   801049 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800aeb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800aee:	5b                   	pop    %ebx
  800aef:	5e                   	pop    %esi
  800af0:	5f                   	pop    %edi
  800af1:	5d                   	pop    %ebp
  800af2:	c3                   	ret    

00800af3 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800af3:	55                   	push   %ebp
  800af4:	89 e5                	mov    %esp,%ebp
  800af6:	57                   	push   %edi
  800af7:	56                   	push   %esi
  800af8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800af9:	ba 00 00 00 00       	mov    $0x0,%edx
  800afe:	b8 02 00 00 00       	mov    $0x2,%eax
  800b03:	89 d1                	mov    %edx,%ecx
  800b05:	89 d3                	mov    %edx,%ebx
  800b07:	89 d7                	mov    %edx,%edi
  800b09:	89 d6                	mov    %edx,%esi
  800b0b:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b0d:	5b                   	pop    %ebx
  800b0e:	5e                   	pop    %esi
  800b0f:	5f                   	pop    %edi
  800b10:	5d                   	pop    %ebp
  800b11:	c3                   	ret    

00800b12 <sys_yield>:

void
sys_yield(void)
{
  800b12:	55                   	push   %ebp
  800b13:	89 e5                	mov    %esp,%ebp
  800b15:	57                   	push   %edi
  800b16:	56                   	push   %esi
  800b17:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b18:	ba 00 00 00 00       	mov    $0x0,%edx
  800b1d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b22:	89 d1                	mov    %edx,%ecx
  800b24:	89 d3                	mov    %edx,%ebx
  800b26:	89 d7                	mov    %edx,%edi
  800b28:	89 d6                	mov    %edx,%esi
  800b2a:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800b2c:	5b                   	pop    %ebx
  800b2d:	5e                   	pop    %esi
  800b2e:	5f                   	pop    %edi
  800b2f:	5d                   	pop    %ebp
  800b30:	c3                   	ret    

00800b31 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800b31:	55                   	push   %ebp
  800b32:	89 e5                	mov    %esp,%ebp
  800b34:	57                   	push   %edi
  800b35:	56                   	push   %esi
  800b36:	53                   	push   %ebx
  800b37:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b3a:	be 00 00 00 00       	mov    $0x0,%esi
  800b3f:	b8 04 00 00 00       	mov    $0x4,%eax
  800b44:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b47:	8b 55 08             	mov    0x8(%ebp),%edx
  800b4a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800b4d:	89 f7                	mov    %esi,%edi
  800b4f:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b51:	85 c0                	test   %eax,%eax
  800b53:	7e 17                	jle    800b6c <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b55:	83 ec 0c             	sub    $0xc,%esp
  800b58:	50                   	push   %eax
  800b59:	6a 04                	push   $0x4
  800b5b:	68 44 16 80 00       	push   $0x801644
  800b60:	6a 23                	push   $0x23
  800b62:	68 61 16 80 00       	push   $0x801661
  800b67:	e8 dd 04 00 00       	call   801049 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800b6c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b6f:	5b                   	pop    %ebx
  800b70:	5e                   	pop    %esi
  800b71:	5f                   	pop    %edi
  800b72:	5d                   	pop    %ebp
  800b73:	c3                   	ret    

00800b74 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800b74:	55                   	push   %ebp
  800b75:	89 e5                	mov    %esp,%ebp
  800b77:	57                   	push   %edi
  800b78:	56                   	push   %esi
  800b79:	53                   	push   %ebx
  800b7a:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7d:	b8 05 00 00 00       	mov    $0x5,%eax
  800b82:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b85:	8b 55 08             	mov    0x8(%ebp),%edx
  800b88:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800b8b:	8b 7d 14             	mov    0x14(%ebp),%edi
  800b8e:	8b 75 18             	mov    0x18(%ebp),%esi
  800b91:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b93:	85 c0                	test   %eax,%eax
  800b95:	7e 17                	jle    800bae <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b97:	83 ec 0c             	sub    $0xc,%esp
  800b9a:	50                   	push   %eax
  800b9b:	6a 05                	push   $0x5
  800b9d:	68 44 16 80 00       	push   $0x801644
  800ba2:	6a 23                	push   $0x23
  800ba4:	68 61 16 80 00       	push   $0x801661
  800ba9:	e8 9b 04 00 00       	call   801049 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800bae:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bb1:	5b                   	pop    %ebx
  800bb2:	5e                   	pop    %esi
  800bb3:	5f                   	pop    %edi
  800bb4:	5d                   	pop    %ebp
  800bb5:	c3                   	ret    

00800bb6 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800bb6:	55                   	push   %ebp
  800bb7:	89 e5                	mov    %esp,%ebp
  800bb9:	57                   	push   %edi
  800bba:	56                   	push   %esi
  800bbb:	53                   	push   %ebx
  800bbc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bbf:	bb 00 00 00 00       	mov    $0x0,%ebx
  800bc4:	b8 06 00 00 00       	mov    $0x6,%eax
  800bc9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bcc:	8b 55 08             	mov    0x8(%ebp),%edx
  800bcf:	89 df                	mov    %ebx,%edi
  800bd1:	89 de                	mov    %ebx,%esi
  800bd3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bd5:	85 c0                	test   %eax,%eax
  800bd7:	7e 17                	jle    800bf0 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bd9:	83 ec 0c             	sub    $0xc,%esp
  800bdc:	50                   	push   %eax
  800bdd:	6a 06                	push   $0x6
  800bdf:	68 44 16 80 00       	push   $0x801644
  800be4:	6a 23                	push   $0x23
  800be6:	68 61 16 80 00       	push   $0x801661
  800beb:	e8 59 04 00 00       	call   801049 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800bf0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bf3:	5b                   	pop    %ebx
  800bf4:	5e                   	pop    %esi
  800bf5:	5f                   	pop    %edi
  800bf6:	5d                   	pop    %ebp
  800bf7:	c3                   	ret    

00800bf8 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800bf8:	55                   	push   %ebp
  800bf9:	89 e5                	mov    %esp,%ebp
  800bfb:	57                   	push   %edi
  800bfc:	56                   	push   %esi
  800bfd:	53                   	push   %ebx
  800bfe:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c01:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c06:	b8 08 00 00 00       	mov    $0x8,%eax
  800c0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c0e:	8b 55 08             	mov    0x8(%ebp),%edx
  800c11:	89 df                	mov    %ebx,%edi
  800c13:	89 de                	mov    %ebx,%esi
  800c15:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c17:	85 c0                	test   %eax,%eax
  800c19:	7e 17                	jle    800c32 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c1b:	83 ec 0c             	sub    $0xc,%esp
  800c1e:	50                   	push   %eax
  800c1f:	6a 08                	push   $0x8
  800c21:	68 44 16 80 00       	push   $0x801644
  800c26:	6a 23                	push   $0x23
  800c28:	68 61 16 80 00       	push   $0x801661
  800c2d:	e8 17 04 00 00       	call   801049 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800c32:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c35:	5b                   	pop    %ebx
  800c36:	5e                   	pop    %esi
  800c37:	5f                   	pop    %edi
  800c38:	5d                   	pop    %ebp
  800c39:	c3                   	ret    

00800c3a <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800c3a:	55                   	push   %ebp
  800c3b:	89 e5                	mov    %esp,%ebp
  800c3d:	57                   	push   %edi
  800c3e:	56                   	push   %esi
  800c3f:	53                   	push   %ebx
  800c40:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c43:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c48:	b8 09 00 00 00       	mov    $0x9,%eax
  800c4d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c50:	8b 55 08             	mov    0x8(%ebp),%edx
  800c53:	89 df                	mov    %ebx,%edi
  800c55:	89 de                	mov    %ebx,%esi
  800c57:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c59:	85 c0                	test   %eax,%eax
  800c5b:	7e 17                	jle    800c74 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c5d:	83 ec 0c             	sub    $0xc,%esp
  800c60:	50                   	push   %eax
  800c61:	6a 09                	push   $0x9
  800c63:	68 44 16 80 00       	push   $0x801644
  800c68:	6a 23                	push   $0x23
  800c6a:	68 61 16 80 00       	push   $0x801661
  800c6f:	e8 d5 03 00 00       	call   801049 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800c74:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c77:	5b                   	pop    %ebx
  800c78:	5e                   	pop    %esi
  800c79:	5f                   	pop    %edi
  800c7a:	5d                   	pop    %ebp
  800c7b:	c3                   	ret    

00800c7c <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800c7c:	55                   	push   %ebp
  800c7d:	89 e5                	mov    %esp,%ebp
  800c7f:	57                   	push   %edi
  800c80:	56                   	push   %esi
  800c81:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c82:	be 00 00 00 00       	mov    $0x0,%esi
  800c87:	b8 0b 00 00 00       	mov    $0xb,%eax
  800c8c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c8f:	8b 55 08             	mov    0x8(%ebp),%edx
  800c92:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c95:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c98:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800c9a:	5b                   	pop    %ebx
  800c9b:	5e                   	pop    %esi
  800c9c:	5f                   	pop    %edi
  800c9d:	5d                   	pop    %ebp
  800c9e:	c3                   	ret    

00800c9f <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800c9f:	55                   	push   %ebp
  800ca0:	89 e5                	mov    %esp,%ebp
  800ca2:	57                   	push   %edi
  800ca3:	56                   	push   %esi
  800ca4:	53                   	push   %ebx
  800ca5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ca8:	b9 00 00 00 00       	mov    $0x0,%ecx
  800cad:	b8 0c 00 00 00       	mov    $0xc,%eax
  800cb2:	8b 55 08             	mov    0x8(%ebp),%edx
  800cb5:	89 cb                	mov    %ecx,%ebx
  800cb7:	89 cf                	mov    %ecx,%edi
  800cb9:	89 ce                	mov    %ecx,%esi
  800cbb:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cbd:	85 c0                	test   %eax,%eax
  800cbf:	7e 17                	jle    800cd8 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cc1:	83 ec 0c             	sub    $0xc,%esp
  800cc4:	50                   	push   %eax
  800cc5:	6a 0c                	push   $0xc
  800cc7:	68 44 16 80 00       	push   $0x801644
  800ccc:	6a 23                	push   $0x23
  800cce:	68 61 16 80 00       	push   $0x801661
  800cd3:	e8 71 03 00 00       	call   801049 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800cd8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cdb:	5b                   	pop    %ebx
  800cdc:	5e                   	pop    %esi
  800cdd:	5f                   	pop    %edi
  800cde:	5d                   	pop    %ebp
  800cdf:	c3                   	ret    

00800ce0 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800ce0:	55                   	push   %ebp
  800ce1:	89 e5                	mov    %esp,%ebp
  800ce3:	53                   	push   %ebx
  800ce4:	83 ec 04             	sub    $0x4,%esp
  800ce7:	8b 55 08             	mov    0x8(%ebp),%edx
	void *addr = (void *) utf->utf_fault_va;
  800cea:	8b 02                	mov    (%edx),%eax
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if (!((err & FEC_WR) && (uvpd[PDX(addr)] & PTE_P) && 
  800cec:	f6 42 04 02          	testb  $0x2,0x4(%edx)
  800cf0:	74 2e                	je     800d20 <pgfault+0x40>
  800cf2:	89 c2                	mov    %eax,%edx
  800cf4:	c1 ea 16             	shr    $0x16,%edx
  800cf7:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  800cfe:	f6 c2 01             	test   $0x1,%dl
  800d01:	74 1d                	je     800d20 <pgfault+0x40>
	   (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_COW)))
  800d03:	89 c2                	mov    %eax,%edx
  800d05:	c1 ea 0c             	shr    $0xc,%edx
  800d08:	8b 0c 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%ecx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if (!((err & FEC_WR) && (uvpd[PDX(addr)] & PTE_P) && 
  800d0f:	f6 c1 01             	test   $0x1,%cl
  800d12:	74 0c                	je     800d20 <pgfault+0x40>
	   (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_COW)))
  800d14:	8b 14 95 00 00 40 ef 	mov    -0x10c00000(,%edx,4),%edx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if (!((err & FEC_WR) && (uvpd[PDX(addr)] & PTE_P) && 
  800d1b:	f6 c6 08             	test   $0x8,%dh
  800d1e:	75 14                	jne    800d34 <pgfault+0x54>
	   (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_COW)))
			panic("not copy-on-write!");	
  800d20:	83 ec 04             	sub    $0x4,%esp
  800d23:	68 6f 16 80 00       	push   $0x80166f
  800d28:	6a 1e                	push   $0x1e
  800d2a:	68 82 16 80 00       	push   $0x801682
  800d2f:	e8 15 03 00 00       	call   801049 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr, PGSIZE);
  800d34:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  800d39:	89 c3                	mov    %eax,%ebx
	if (sys_page_alloc(0, PFTEMP, (PTE_W | PTE_U | PTE_P)))
  800d3b:	83 ec 04             	sub    $0x4,%esp
  800d3e:	6a 07                	push   $0x7
  800d40:	68 00 f0 7f 00       	push   $0x7ff000
  800d45:	6a 00                	push   $0x0
  800d47:	e8 e5 fd ff ff       	call   800b31 <sys_page_alloc>
  800d4c:	83 c4 10             	add    $0x10,%esp
  800d4f:	85 c0                	test   %eax,%eax
  800d51:	74 14                	je     800d67 <pgfault+0x87>
		panic("sys_page_alloc");
  800d53:	83 ec 04             	sub    $0x4,%esp
  800d56:	68 8d 16 80 00       	push   $0x80168d
  800d5b:	6a 29                	push   $0x29
  800d5d:	68 82 16 80 00       	push   $0x801682
  800d62:	e8 e2 02 00 00       	call   801049 <_panic>
	
	memcpy(PFTEMP, addr, PGSIZE);
  800d67:	83 ec 04             	sub    $0x4,%esp
  800d6a:	68 00 10 00 00       	push   $0x1000
  800d6f:	53                   	push   %ebx
  800d70:	68 00 f0 7f 00       	push   $0x7ff000
  800d75:	e8 ae fb ff ff       	call   800928 <memcpy>

	if(sys_page_map(0, PFTEMP, 0, addr, (PTE_W | PTE_U | PTE_P)))
  800d7a:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800d81:	53                   	push   %ebx
  800d82:	6a 00                	push   $0x0
  800d84:	68 00 f0 7f 00       	push   $0x7ff000
  800d89:	6a 00                	push   $0x0
  800d8b:	e8 e4 fd ff ff       	call   800b74 <sys_page_map>
  800d90:	83 c4 20             	add    $0x20,%esp
  800d93:	85 c0                	test   %eax,%eax
  800d95:	74 14                	je     800dab <pgfault+0xcb>
		panic("sys_page_map");
  800d97:	83 ec 04             	sub    $0x4,%esp
  800d9a:	68 9c 16 80 00       	push   $0x80169c
  800d9f:	6a 2e                	push   $0x2e
  800da1:	68 82 16 80 00       	push   $0x801682
  800da6:	e8 9e 02 00 00       	call   801049 <_panic>

	if (sys_page_unmap(0, PFTEMP))
  800dab:	83 ec 08             	sub    $0x8,%esp
  800dae:	68 00 f0 7f 00       	push   $0x7ff000
  800db3:	6a 00                	push   $0x0
  800db5:	e8 fc fd ff ff       	call   800bb6 <sys_page_unmap>
  800dba:	83 c4 10             	add    $0x10,%esp
  800dbd:	85 c0                	test   %eax,%eax
  800dbf:	74 14                	je     800dd5 <pgfault+0xf5>
		panic("sys_page_unmap");
  800dc1:	83 ec 04             	sub    $0x4,%esp
  800dc4:	68 a9 16 80 00       	push   $0x8016a9
  800dc9:	6a 31                	push   $0x31
  800dcb:	68 82 16 80 00       	push   $0x801682
  800dd0:	e8 74 02 00 00       	call   801049 <_panic>

	return;
}
  800dd5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800dd8:	c9                   	leave  
  800dd9:	c3                   	ret    

00800dda <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800dda:	55                   	push   %ebp
  800ddb:	89 e5                	mov    %esp,%ebp
  800ddd:	57                   	push   %edi
  800dde:	56                   	push   %esi
  800ddf:	53                   	push   %ebx
  800de0:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault);
  800de3:	68 e0 0c 80 00       	push   $0x800ce0
  800de8:	e8 a2 02 00 00       	call   80108f <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800ded:	b8 07 00 00 00       	mov    $0x7,%eax
  800df2:	cd 30                	int    $0x30
  800df4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.
	envid = sys_exofork();	 

	
	if (envid < 0)
  800df7:	83 c4 10             	add    $0x10,%esp
  800dfa:	85 c0                	test   %eax,%eax
  800dfc:	79 12                	jns    800e10 <fork+0x36>
		panic("sys_exofork: %e", envid);
  800dfe:	50                   	push   %eax
  800dff:	68 b8 16 80 00       	push   $0x8016b8
  800e04:	6a 7b                	push   $0x7b
  800e06:	68 82 16 80 00       	push   $0x801682
  800e0b:	e8 39 02 00 00       	call   801049 <_panic>
  800e10:	89 c7                	mov    %eax,%edi
  800e12:	bb 00 00 00 00       	mov    $0x0,%ebx
	
	if (envid == 0) 
  800e17:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800e1b:	75 21                	jne    800e3e <fork+0x64>
	{
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  800e1d:	e8 d1 fc ff ff       	call   800af3 <sys_getenvid>
  800e22:	25 ff 03 00 00       	and    $0x3ff,%eax
  800e27:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800e2a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800e2f:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800e34:	b8 00 00 00 00       	mov    $0x0,%eax
  800e39:	e9 f3 00 00 00       	jmp    800f31 <fork+0x157>
	}

	// We're the parent.
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE)
	{
		if((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_U)) 
  800e3e:	89 d8                	mov    %ebx,%eax
  800e40:	c1 e8 16             	shr    $0x16,%eax
  800e43:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  800e4a:	a8 01                	test   $0x1,%al
  800e4c:	74 7d                	je     800ecb <fork+0xf1>
  800e4e:	89 d8                	mov    %ebx,%eax
  800e50:	c1 e8 0c             	shr    $0xc,%eax
  800e53:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800e5a:	f6 c2 01             	test   $0x1,%dl
  800e5d:	74 6c                	je     800ecb <fork+0xf1>
  800e5f:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800e66:	f6 c2 04             	test   $0x4,%dl
  800e69:	74 60                	je     800ecb <fork+0xf1>
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void *addr = (void*)(pn * PGSIZE);
  800e6b:	89 c6                	mov    %eax,%esi
  800e6d:	c1 e6 0c             	shl    $0xc,%esi
	
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  800e70:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
  800e77:	f6 c2 02             	test   $0x2,%dl
  800e7a:	75 0c                	jne    800e88 <fork+0xae>
  800e7c:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800e83:	f6 c4 08             	test   $0x8,%ah
  800e86:	74 31                	je     800eb9 <fork+0xdf>
	{
		r = sys_page_map(0, addr, envid, addr, (PTE_COW | PTE_U | PTE_P));
  800e88:	83 ec 0c             	sub    $0xc,%esp
  800e8b:	68 05 08 00 00       	push   $0x805
  800e90:	56                   	push   %esi
  800e91:	57                   	push   %edi
  800e92:	56                   	push   %esi
  800e93:	6a 00                	push   $0x0
  800e95:	e8 da fc ff ff       	call   800b74 <sys_page_map>
		if (r)
  800e9a:	83 c4 20             	add    $0x20,%esp
  800e9d:	85 c0                	test   %eax,%eax
  800e9f:	75 2a                	jne    800ecb <fork+0xf1>
			return r;
	
		r = sys_page_map(0, addr, 0, addr, (PTE_COW | PTE_U | PTE_P));
  800ea1:	83 ec 0c             	sub    $0xc,%esp
  800ea4:	68 05 08 00 00       	push   $0x805
  800ea9:	56                   	push   %esi
  800eaa:	6a 00                	push   $0x0
  800eac:	56                   	push   %esi
  800ead:	6a 00                	push   $0x0
  800eaf:	e8 c0 fc ff ff       	call   800b74 <sys_page_map>
  800eb4:	83 c4 20             	add    $0x20,%esp
  800eb7:	eb 12                	jmp    800ecb <fork+0xf1>
		if (r)
			return r;
	}
	else
		sys_page_map(0, addr, envid, addr, (PTE_U | PTE_P));
  800eb9:	83 ec 0c             	sub    $0xc,%esp
  800ebc:	6a 05                	push   $0x5
  800ebe:	56                   	push   %esi
  800ebf:	57                   	push   %edi
  800ec0:	56                   	push   %esi
  800ec1:	6a 00                	push   $0x0
  800ec3:	e8 ac fc ff ff       	call   800b74 <sys_page_map>
  800ec8:	83 c4 20             	add    $0x20,%esp
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// We're the parent.
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE)
  800ecb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  800ed1:	81 fb 00 e0 bf ee    	cmp    $0xeebfe000,%ebx
  800ed7:	0f 85 61 ff ff ff    	jne    800e3e <fork+0x64>
	{
		if((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_U)) 
			duppage(envid, PGNUM(addr));
	}
	
	int r = sys_page_alloc(envid, (void*)(UXSTACKTOP-PGSIZE), PTE_W|PTE_U|PTE_P);
  800edd:	83 ec 04             	sub    $0x4,%esp
  800ee0:	6a 07                	push   $0x7
  800ee2:	68 00 f0 bf ee       	push   $0xeebff000
  800ee7:	ff 75 e4             	pushl  -0x1c(%ebp)
  800eea:	e8 42 fc ff ff       	call   800b31 <sys_page_alloc>
		
	if (r)
  800eef:	83 c4 10             	add    $0x10,%esp
  800ef2:	85 c0                	test   %eax,%eax
  800ef4:	75 3b                	jne    800f31 <fork+0x157>
		return r;
	
	extern void _pgfault_upcall();
	sys_env_set_pgfault_upcall(envid, (void*) _pgfault_upcall);
  800ef6:	83 ec 08             	sub    $0x8,%esp
  800ef9:	68 fe 10 80 00       	push   $0x8010fe
  800efe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800f01:	57                   	push   %edi
  800f02:	e8 33 fd ff ff       	call   800c3a <sys_env_set_pgfault_upcall>

	// Start the child environment running:
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)))
  800f07:	83 c4 08             	add    $0x8,%esp
  800f0a:	6a 02                	push   $0x2
  800f0c:	57                   	push   %edi
  800f0d:	e8 e6 fc ff ff       	call   800bf8 <sys_env_set_status>
  800f12:	83 c4 10             	add    $0x10,%esp
  800f15:	85 c0                	test   %eax,%eax
  800f17:	74 15                	je     800f2e <fork+0x154>
		panic("sys_env_set_status: %e", r);
  800f19:	50                   	push   %eax
  800f1a:	68 c8 16 80 00       	push   $0x8016c8
  800f1f:	68 98 00 00 00       	push   $0x98
  800f24:	68 82 16 80 00       	push   $0x801682
  800f29:	e8 1b 01 00 00       	call   801049 <_panic>

	return envid;
  800f2e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
  800f31:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800f34:	5b                   	pop    %ebx
  800f35:	5e                   	pop    %esi
  800f36:	5f                   	pop    %edi
  800f37:	5d                   	pop    %ebp
  800f38:	c3                   	ret    

00800f39 <sfork>:

// Challenge!
int
sfork(void)
{
  800f39:	55                   	push   %ebp
  800f3a:	89 e5                	mov    %esp,%ebp
  800f3c:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  800f3f:	68 df 16 80 00       	push   $0x8016df
  800f44:	68 a1 00 00 00       	push   $0xa1
  800f49:	68 82 16 80 00       	push   $0x801682
  800f4e:	e8 f6 00 00 00       	call   801049 <_panic>

00800f53 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  800f53:	55                   	push   %ebp
  800f54:	89 e5                	mov    %esp,%ebp
  800f56:	56                   	push   %esi
  800f57:	53                   	push   %ebx
  800f58:	8b 75 08             	mov    0x8(%ebp),%esi
  800f5b:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f5e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if(!pg)
  800f61:	85 c0                	test   %eax,%eax
		pg  = (void *) -1;
  800f63:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  800f68:	0f 44 c2             	cmove  %edx,%eax

	int r = sys_ipc_recv(pg);
  800f6b:	83 ec 0c             	sub    $0xc,%esp
  800f6e:	50                   	push   %eax
  800f6f:	e8 2b fd ff ff       	call   800c9f <sys_ipc_recv>
	
	if(r < 0)
  800f74:	83 c4 10             	add    $0x10,%esp
  800f77:	85 c0                	test   %eax,%eax
  800f79:	79 16                	jns    800f91 <ipc_recv+0x3e>
	{
		if(from_env_store)
  800f7b:	85 f6                	test   %esi,%esi
  800f7d:	74 06                	je     800f85 <ipc_recv+0x32>
			*from_env_store = 0;
  800f7f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)

		if(perm_store)
  800f85:	85 db                	test   %ebx,%ebx
  800f87:	74 2c                	je     800fb5 <ipc_recv+0x62>
			*perm_store = 0;
  800f89:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800f8f:	eb 24                	jmp    800fb5 <ipc_recv+0x62>

		return r;
	}	

	if(from_env_store)
  800f91:	85 f6                	test   %esi,%esi
  800f93:	74 0a                	je     800f9f <ipc_recv+0x4c>
		*from_env_store = thisenv->env_ipc_from;
  800f95:	a1 04 20 80 00       	mov    0x802004,%eax
  800f9a:	8b 40 74             	mov    0x74(%eax),%eax
  800f9d:	89 06                	mov    %eax,(%esi)

	if(perm_store)
  800f9f:	85 db                	test   %ebx,%ebx
  800fa1:	74 0a                	je     800fad <ipc_recv+0x5a>
		*perm_store = thisenv->env_ipc_perm;
  800fa3:	a1 04 20 80 00       	mov    0x802004,%eax
  800fa8:	8b 40 78             	mov    0x78(%eax),%eax
  800fab:	89 03                	mov    %eax,(%ebx)

	return thisenv->env_ipc_value;
  800fad:	a1 04 20 80 00       	mov    0x802004,%eax
  800fb2:	8b 40 70             	mov    0x70(%eax),%eax
}
  800fb5:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800fb8:	5b                   	pop    %ebx
  800fb9:	5e                   	pop    %esi
  800fba:	5d                   	pop    %ebp
  800fbb:	c3                   	ret    

00800fbc <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  800fbc:	55                   	push   %ebp
  800fbd:	89 e5                	mov    %esp,%ebp
  800fbf:	57                   	push   %edi
  800fc0:	56                   	push   %esi
  800fc1:	53                   	push   %ebx
  800fc2:	83 ec 0c             	sub    $0xc,%esp
  800fc5:	8b 7d 08             	mov    0x8(%ebp),%edi
  800fc8:	8b 75 0c             	mov    0xc(%ebp),%esi
  800fcb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	if(!pg)
  800fce:	85 db                	test   %ebx,%ebx
		pg = (void *) -1;
  800fd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800fd5:	0f 44 d8             	cmove  %eax,%ebx
  800fd8:	eb 1c                	jmp    800ff6 <ipc_send+0x3a>

	int r;

	while((r = sys_ipc_try_send(to_env, val, pg, perm)))
	{
		if(r != -E_IPC_NOT_RECV)
  800fda:	83 f8 f9             	cmp    $0xfffffff9,%eax
  800fdd:	74 12                	je     800ff1 <ipc_send+0x35>
			panic("not -E_IPC_NOT_RECV %e", r);
  800fdf:	50                   	push   %eax
  800fe0:	68 f5 16 80 00       	push   $0x8016f5
  800fe5:	6a 47                	push   $0x47
  800fe7:	68 0c 17 80 00       	push   $0x80170c
  800fec:	e8 58 00 00 00       	call   801049 <_panic>

		if(r == 0)
			break;

		sys_yield();
  800ff1:	e8 1c fb ff ff       	call   800b12 <sys_yield>
	if(!pg)
		pg = (void *) -1;

	int r;

	while((r = sys_ipc_try_send(to_env, val, pg, perm)))
  800ff6:	ff 75 14             	pushl  0x14(%ebp)
  800ff9:	53                   	push   %ebx
  800ffa:	56                   	push   %esi
  800ffb:	57                   	push   %edi
  800ffc:	e8 7b fc ff ff       	call   800c7c <sys_ipc_try_send>
  801001:	83 c4 10             	add    $0x10,%esp
  801004:	85 c0                	test   %eax,%eax
  801006:	75 d2                	jne    800fda <ipc_send+0x1e>
		if(r == 0)
			break;

		sys_yield();
	}
}
  801008:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80100b:	5b                   	pop    %ebx
  80100c:	5e                   	pop    %esi
  80100d:	5f                   	pop    %edi
  80100e:	5d                   	pop    %ebp
  80100f:	c3                   	ret    

00801010 <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  801010:	55                   	push   %ebp
  801011:	89 e5                	mov    %esp,%ebp
  801013:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  801016:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  80101b:	6b d0 7c             	imul   $0x7c,%eax,%edx
  80101e:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  801024:	8b 52 50             	mov    0x50(%edx),%edx
  801027:	39 ca                	cmp    %ecx,%edx
  801029:	75 0d                	jne    801038 <ipc_find_env+0x28>
			return envs[i].env_id;
  80102b:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80102e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801033:	8b 40 48             	mov    0x48(%eax),%eax
  801036:	eb 0f                	jmp    801047 <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  801038:	83 c0 01             	add    $0x1,%eax
  80103b:	3d 00 04 00 00       	cmp    $0x400,%eax
  801040:	75 d9                	jne    80101b <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  801042:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801047:	5d                   	pop    %ebp
  801048:	c3                   	ret    

00801049 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801049:	55                   	push   %ebp
  80104a:	89 e5                	mov    %esp,%ebp
  80104c:	56                   	push   %esi
  80104d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80104e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  801051:	8b 35 00 20 80 00    	mov    0x802000,%esi
  801057:	e8 97 fa ff ff       	call   800af3 <sys_getenvid>
  80105c:	83 ec 0c             	sub    $0xc,%esp
  80105f:	ff 75 0c             	pushl  0xc(%ebp)
  801062:	ff 75 08             	pushl  0x8(%ebp)
  801065:	56                   	push   %esi
  801066:	50                   	push   %eax
  801067:	68 18 17 80 00       	push   $0x801718
  80106c:	e8 38 f1 ff ff       	call   8001a9 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  801071:	83 c4 18             	add    $0x18,%esp
  801074:	53                   	push   %ebx
  801075:	ff 75 10             	pushl  0x10(%ebp)
  801078:	e8 db f0 ff ff       	call   800158 <vcprintf>
	cprintf("\n");
  80107d:	c7 04 24 e7 13 80 00 	movl   $0x8013e7,(%esp)
  801084:	e8 20 f1 ff ff       	call   8001a9 <cprintf>
  801089:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80108c:	cc                   	int3   
  80108d:	eb fd                	jmp    80108c <_panic+0x43>

0080108f <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  80108f:	55                   	push   %ebp
  801090:	89 e5                	mov    %esp,%ebp
  801092:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) 
  801095:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  80109c:	75 2c                	jne    8010ca <set_pgfault_handler+0x3b>
	{
		// First time through!
		// LAB 4: Your code here.
		if(sys_page_alloc(0, (void*)(UXSTACKTOP - PGSIZE), (PTE_P | PTE_U | PTE_W)) < 0)
  80109e:	83 ec 04             	sub    $0x4,%esp
  8010a1:	6a 07                	push   $0x7
  8010a3:	68 00 f0 bf ee       	push   $0xeebff000
  8010a8:	6a 00                	push   $0x0
  8010aa:	e8 82 fa ff ff       	call   800b31 <sys_page_alloc>
  8010af:	83 c4 10             	add    $0x10,%esp
  8010b2:	85 c0                	test   %eax,%eax
  8010b4:	79 14                	jns    8010ca <set_pgfault_handler+0x3b>
			panic("set_pgfault_handler: sys_page_alloc failed!");
  8010b6:	83 ec 04             	sub    $0x4,%esp
  8010b9:	68 3c 17 80 00       	push   $0x80173c
  8010be:	6a 22                	push   $0x22
  8010c0:	68 a0 17 80 00       	push   $0x8017a0
  8010c5:	e8 7f ff ff ff       	call   801049 <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  8010ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8010cd:	a3 08 20 80 00       	mov    %eax,0x802008

	if (sys_env_set_pgfault_upcall(0, _pgfault_upcall) < 0)
  8010d2:	83 ec 08             	sub    $0x8,%esp
  8010d5:	68 fe 10 80 00       	push   $0x8010fe
  8010da:	6a 00                	push   $0x0
  8010dc:	e8 59 fb ff ff       	call   800c3a <sys_env_set_pgfault_upcall>
  8010e1:	83 c4 10             	add    $0x10,%esp
  8010e4:	85 c0                	test   %eax,%eax
  8010e6:	79 14                	jns    8010fc <set_pgfault_handler+0x6d>
		panic("set_pgfault_handler: sys_env_set_pgfault_upcall failed!");
  8010e8:	83 ec 04             	sub    $0x4,%esp
  8010eb:	68 68 17 80 00       	push   $0x801768
  8010f0:	6a 29                	push   $0x29
  8010f2:	68 a0 17 80 00       	push   $0x8017a0
  8010f7:	e8 4d ff ff ff       	call   801049 <_panic>
}
  8010fc:	c9                   	leave  
  8010fd:	c3                   	ret    

008010fe <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  8010fe:	54                   	push   %esp
	movl _pgfault_handler, %eax
  8010ff:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  801104:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801106:	83 c4 04             	add    $0x4,%esp
	// registers are available for intermediate calculations.  You
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	movl 0x28(%esp), %ebx 	// utf_eip (eip in trap-time)
  801109:	8b 5c 24 28          	mov    0x28(%esp),%ebx
	subl $0x4, 0x30(%esp)	// we will store return eip onto stack *in-trap-time*
  80110d:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
				// so we need update orig esp (allocate space)
	movl 0x30(%esp), %eax 	// utf_esp (esp trap-time stack to return to)
  801112:	8b 44 24 30          	mov    0x30(%esp),%eax
	movl %ebx, (%eax)	// we save the eip causing page fault
  801116:	89 18                	mov    %ebx,(%eax)
	addl $0x8, %esp		// skip utf_fault_va and utf_err
  801118:	83 c4 08             	add    $0x8,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	popal			// from utf_regs restore regs
  80111b:	61                   	popa   

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp 	// skip utf_eip, now saved above struct UTF
  80111c:	83 c4 04             	add    $0x4,%esp
	popfl			// from utf_eflags restore eflags
  80111f:	9d                   	popf   

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp		// from utf_esp restore original esp
  801120:	5c                   	pop    %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
  801121:	c3                   	ret    
  801122:	66 90                	xchg   %ax,%ax
  801124:	66 90                	xchg   %ax,%ax
  801126:	66 90                	xchg   %ax,%ax
  801128:	66 90                	xchg   %ax,%ax
  80112a:	66 90                	xchg   %ax,%ax
  80112c:	66 90                	xchg   %ax,%ax
  80112e:	66 90                	xchg   %ax,%ax

00801130 <__udivdi3>:
  801130:	55                   	push   %ebp
  801131:	57                   	push   %edi
  801132:	56                   	push   %esi
  801133:	53                   	push   %ebx
  801134:	83 ec 1c             	sub    $0x1c,%esp
  801137:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80113b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80113f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801143:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801147:	85 f6                	test   %esi,%esi
  801149:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80114d:	89 ca                	mov    %ecx,%edx
  80114f:	89 f8                	mov    %edi,%eax
  801151:	75 3d                	jne    801190 <__udivdi3+0x60>
  801153:	39 cf                	cmp    %ecx,%edi
  801155:	0f 87 c5 00 00 00    	ja     801220 <__udivdi3+0xf0>
  80115b:	85 ff                	test   %edi,%edi
  80115d:	89 fd                	mov    %edi,%ebp
  80115f:	75 0b                	jne    80116c <__udivdi3+0x3c>
  801161:	b8 01 00 00 00       	mov    $0x1,%eax
  801166:	31 d2                	xor    %edx,%edx
  801168:	f7 f7                	div    %edi
  80116a:	89 c5                	mov    %eax,%ebp
  80116c:	89 c8                	mov    %ecx,%eax
  80116e:	31 d2                	xor    %edx,%edx
  801170:	f7 f5                	div    %ebp
  801172:	89 c1                	mov    %eax,%ecx
  801174:	89 d8                	mov    %ebx,%eax
  801176:	89 cf                	mov    %ecx,%edi
  801178:	f7 f5                	div    %ebp
  80117a:	89 c3                	mov    %eax,%ebx
  80117c:	89 d8                	mov    %ebx,%eax
  80117e:	89 fa                	mov    %edi,%edx
  801180:	83 c4 1c             	add    $0x1c,%esp
  801183:	5b                   	pop    %ebx
  801184:	5e                   	pop    %esi
  801185:	5f                   	pop    %edi
  801186:	5d                   	pop    %ebp
  801187:	c3                   	ret    
  801188:	90                   	nop
  801189:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801190:	39 ce                	cmp    %ecx,%esi
  801192:	77 74                	ja     801208 <__udivdi3+0xd8>
  801194:	0f bd fe             	bsr    %esi,%edi
  801197:	83 f7 1f             	xor    $0x1f,%edi
  80119a:	0f 84 98 00 00 00    	je     801238 <__udivdi3+0x108>
  8011a0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8011a5:	89 f9                	mov    %edi,%ecx
  8011a7:	89 c5                	mov    %eax,%ebp
  8011a9:	29 fb                	sub    %edi,%ebx
  8011ab:	d3 e6                	shl    %cl,%esi
  8011ad:	89 d9                	mov    %ebx,%ecx
  8011af:	d3 ed                	shr    %cl,%ebp
  8011b1:	89 f9                	mov    %edi,%ecx
  8011b3:	d3 e0                	shl    %cl,%eax
  8011b5:	09 ee                	or     %ebp,%esi
  8011b7:	89 d9                	mov    %ebx,%ecx
  8011b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011bd:	89 d5                	mov    %edx,%ebp
  8011bf:	8b 44 24 08          	mov    0x8(%esp),%eax
  8011c3:	d3 ed                	shr    %cl,%ebp
  8011c5:	89 f9                	mov    %edi,%ecx
  8011c7:	d3 e2                	shl    %cl,%edx
  8011c9:	89 d9                	mov    %ebx,%ecx
  8011cb:	d3 e8                	shr    %cl,%eax
  8011cd:	09 c2                	or     %eax,%edx
  8011cf:	89 d0                	mov    %edx,%eax
  8011d1:	89 ea                	mov    %ebp,%edx
  8011d3:	f7 f6                	div    %esi
  8011d5:	89 d5                	mov    %edx,%ebp
  8011d7:	89 c3                	mov    %eax,%ebx
  8011d9:	f7 64 24 0c          	mull   0xc(%esp)
  8011dd:	39 d5                	cmp    %edx,%ebp
  8011df:	72 10                	jb     8011f1 <__udivdi3+0xc1>
  8011e1:	8b 74 24 08          	mov    0x8(%esp),%esi
  8011e5:	89 f9                	mov    %edi,%ecx
  8011e7:	d3 e6                	shl    %cl,%esi
  8011e9:	39 c6                	cmp    %eax,%esi
  8011eb:	73 07                	jae    8011f4 <__udivdi3+0xc4>
  8011ed:	39 d5                	cmp    %edx,%ebp
  8011ef:	75 03                	jne    8011f4 <__udivdi3+0xc4>
  8011f1:	83 eb 01             	sub    $0x1,%ebx
  8011f4:	31 ff                	xor    %edi,%edi
  8011f6:	89 d8                	mov    %ebx,%eax
  8011f8:	89 fa                	mov    %edi,%edx
  8011fa:	83 c4 1c             	add    $0x1c,%esp
  8011fd:	5b                   	pop    %ebx
  8011fe:	5e                   	pop    %esi
  8011ff:	5f                   	pop    %edi
  801200:	5d                   	pop    %ebp
  801201:	c3                   	ret    
  801202:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801208:	31 ff                	xor    %edi,%edi
  80120a:	31 db                	xor    %ebx,%ebx
  80120c:	89 d8                	mov    %ebx,%eax
  80120e:	89 fa                	mov    %edi,%edx
  801210:	83 c4 1c             	add    $0x1c,%esp
  801213:	5b                   	pop    %ebx
  801214:	5e                   	pop    %esi
  801215:	5f                   	pop    %edi
  801216:	5d                   	pop    %ebp
  801217:	c3                   	ret    
  801218:	90                   	nop
  801219:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801220:	89 d8                	mov    %ebx,%eax
  801222:	f7 f7                	div    %edi
  801224:	31 ff                	xor    %edi,%edi
  801226:	89 c3                	mov    %eax,%ebx
  801228:	89 d8                	mov    %ebx,%eax
  80122a:	89 fa                	mov    %edi,%edx
  80122c:	83 c4 1c             	add    $0x1c,%esp
  80122f:	5b                   	pop    %ebx
  801230:	5e                   	pop    %esi
  801231:	5f                   	pop    %edi
  801232:	5d                   	pop    %ebp
  801233:	c3                   	ret    
  801234:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801238:	39 ce                	cmp    %ecx,%esi
  80123a:	72 0c                	jb     801248 <__udivdi3+0x118>
  80123c:	31 db                	xor    %ebx,%ebx
  80123e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801242:	0f 87 34 ff ff ff    	ja     80117c <__udivdi3+0x4c>
  801248:	bb 01 00 00 00       	mov    $0x1,%ebx
  80124d:	e9 2a ff ff ff       	jmp    80117c <__udivdi3+0x4c>
  801252:	66 90                	xchg   %ax,%ax
  801254:	66 90                	xchg   %ax,%ax
  801256:	66 90                	xchg   %ax,%ax
  801258:	66 90                	xchg   %ax,%ax
  80125a:	66 90                	xchg   %ax,%ax
  80125c:	66 90                	xchg   %ax,%ax
  80125e:	66 90                	xchg   %ax,%ax

00801260 <__umoddi3>:
  801260:	55                   	push   %ebp
  801261:	57                   	push   %edi
  801262:	56                   	push   %esi
  801263:	53                   	push   %ebx
  801264:	83 ec 1c             	sub    $0x1c,%esp
  801267:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80126b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80126f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801273:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801277:	85 d2                	test   %edx,%edx
  801279:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80127d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801281:	89 f3                	mov    %esi,%ebx
  801283:	89 3c 24             	mov    %edi,(%esp)
  801286:	89 74 24 04          	mov    %esi,0x4(%esp)
  80128a:	75 1c                	jne    8012a8 <__umoddi3+0x48>
  80128c:	39 f7                	cmp    %esi,%edi
  80128e:	76 50                	jbe    8012e0 <__umoddi3+0x80>
  801290:	89 c8                	mov    %ecx,%eax
  801292:	89 f2                	mov    %esi,%edx
  801294:	f7 f7                	div    %edi
  801296:	89 d0                	mov    %edx,%eax
  801298:	31 d2                	xor    %edx,%edx
  80129a:	83 c4 1c             	add    $0x1c,%esp
  80129d:	5b                   	pop    %ebx
  80129e:	5e                   	pop    %esi
  80129f:	5f                   	pop    %edi
  8012a0:	5d                   	pop    %ebp
  8012a1:	c3                   	ret    
  8012a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8012a8:	39 f2                	cmp    %esi,%edx
  8012aa:	89 d0                	mov    %edx,%eax
  8012ac:	77 52                	ja     801300 <__umoddi3+0xa0>
  8012ae:	0f bd ea             	bsr    %edx,%ebp
  8012b1:	83 f5 1f             	xor    $0x1f,%ebp
  8012b4:	75 5a                	jne    801310 <__umoddi3+0xb0>
  8012b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  8012ba:	0f 82 e0 00 00 00    	jb     8013a0 <__umoddi3+0x140>
  8012c0:	39 0c 24             	cmp    %ecx,(%esp)
  8012c3:	0f 86 d7 00 00 00    	jbe    8013a0 <__umoddi3+0x140>
  8012c9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8012cd:	8b 54 24 04          	mov    0x4(%esp),%edx
  8012d1:	83 c4 1c             	add    $0x1c,%esp
  8012d4:	5b                   	pop    %ebx
  8012d5:	5e                   	pop    %esi
  8012d6:	5f                   	pop    %edi
  8012d7:	5d                   	pop    %ebp
  8012d8:	c3                   	ret    
  8012d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8012e0:	85 ff                	test   %edi,%edi
  8012e2:	89 fd                	mov    %edi,%ebp
  8012e4:	75 0b                	jne    8012f1 <__umoddi3+0x91>
  8012e6:	b8 01 00 00 00       	mov    $0x1,%eax
  8012eb:	31 d2                	xor    %edx,%edx
  8012ed:	f7 f7                	div    %edi
  8012ef:	89 c5                	mov    %eax,%ebp
  8012f1:	89 f0                	mov    %esi,%eax
  8012f3:	31 d2                	xor    %edx,%edx
  8012f5:	f7 f5                	div    %ebp
  8012f7:	89 c8                	mov    %ecx,%eax
  8012f9:	f7 f5                	div    %ebp
  8012fb:	89 d0                	mov    %edx,%eax
  8012fd:	eb 99                	jmp    801298 <__umoddi3+0x38>
  8012ff:	90                   	nop
  801300:	89 c8                	mov    %ecx,%eax
  801302:	89 f2                	mov    %esi,%edx
  801304:	83 c4 1c             	add    $0x1c,%esp
  801307:	5b                   	pop    %ebx
  801308:	5e                   	pop    %esi
  801309:	5f                   	pop    %edi
  80130a:	5d                   	pop    %ebp
  80130b:	c3                   	ret    
  80130c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801310:	8b 34 24             	mov    (%esp),%esi
  801313:	bf 20 00 00 00       	mov    $0x20,%edi
  801318:	89 e9                	mov    %ebp,%ecx
  80131a:	29 ef                	sub    %ebp,%edi
  80131c:	d3 e0                	shl    %cl,%eax
  80131e:	89 f9                	mov    %edi,%ecx
  801320:	89 f2                	mov    %esi,%edx
  801322:	d3 ea                	shr    %cl,%edx
  801324:	89 e9                	mov    %ebp,%ecx
  801326:	09 c2                	or     %eax,%edx
  801328:	89 d8                	mov    %ebx,%eax
  80132a:	89 14 24             	mov    %edx,(%esp)
  80132d:	89 f2                	mov    %esi,%edx
  80132f:	d3 e2                	shl    %cl,%edx
  801331:	89 f9                	mov    %edi,%ecx
  801333:	89 54 24 04          	mov    %edx,0x4(%esp)
  801337:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80133b:	d3 e8                	shr    %cl,%eax
  80133d:	89 e9                	mov    %ebp,%ecx
  80133f:	89 c6                	mov    %eax,%esi
  801341:	d3 e3                	shl    %cl,%ebx
  801343:	89 f9                	mov    %edi,%ecx
  801345:	89 d0                	mov    %edx,%eax
  801347:	d3 e8                	shr    %cl,%eax
  801349:	89 e9                	mov    %ebp,%ecx
  80134b:	09 d8                	or     %ebx,%eax
  80134d:	89 d3                	mov    %edx,%ebx
  80134f:	89 f2                	mov    %esi,%edx
  801351:	f7 34 24             	divl   (%esp)
  801354:	89 d6                	mov    %edx,%esi
  801356:	d3 e3                	shl    %cl,%ebx
  801358:	f7 64 24 04          	mull   0x4(%esp)
  80135c:	39 d6                	cmp    %edx,%esi
  80135e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801362:	89 d1                	mov    %edx,%ecx
  801364:	89 c3                	mov    %eax,%ebx
  801366:	72 08                	jb     801370 <__umoddi3+0x110>
  801368:	75 11                	jne    80137b <__umoddi3+0x11b>
  80136a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80136e:	73 0b                	jae    80137b <__umoddi3+0x11b>
  801370:	2b 44 24 04          	sub    0x4(%esp),%eax
  801374:	1b 14 24             	sbb    (%esp),%edx
  801377:	89 d1                	mov    %edx,%ecx
  801379:	89 c3                	mov    %eax,%ebx
  80137b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80137f:	29 da                	sub    %ebx,%edx
  801381:	19 ce                	sbb    %ecx,%esi
  801383:	89 f9                	mov    %edi,%ecx
  801385:	89 f0                	mov    %esi,%eax
  801387:	d3 e0                	shl    %cl,%eax
  801389:	89 e9                	mov    %ebp,%ecx
  80138b:	d3 ea                	shr    %cl,%edx
  80138d:	89 e9                	mov    %ebp,%ecx
  80138f:	d3 ee                	shr    %cl,%esi
  801391:	09 d0                	or     %edx,%eax
  801393:	89 f2                	mov    %esi,%edx
  801395:	83 c4 1c             	add    $0x1c,%esp
  801398:	5b                   	pop    %ebx
  801399:	5e                   	pop    %esi
  80139a:	5f                   	pop    %edi
  80139b:	5d                   	pop    %ebp
  80139c:	c3                   	ret    
  80139d:	8d 76 00             	lea    0x0(%esi),%esi
  8013a0:	29 f9                	sub    %edi,%ecx
  8013a2:	19 d6                	sbb    %edx,%esi
  8013a4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8013a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8013ac:	e9 18 ff ff ff       	jmp    8012c9 <__umoddi3+0x69>
