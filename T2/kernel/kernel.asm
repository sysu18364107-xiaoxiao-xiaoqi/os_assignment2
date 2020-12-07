
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	de478793          	addi	a5,a5,-540 # 80005e40 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	544080e7          	jalr	1348(ra) # 8000266a <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	9d4080e7          	jalr	-1580(ra) # 80001ba2 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	1d4080e7          	jalr	468(ra) # 800023b2 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	3fa080e7          	jalr	1018(ra) # 80002614 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	3c4080e7          	jalr	964(ra) # 800026c0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	0e8080e7          	jalr	232(ra) # 80002538 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	c82080e7          	jalr	-894(ra) # 80002538 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	a62080e7          	jalr	-1438(ra) # 800023b2 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	fdc080e7          	jalr	-36(ra) # 80001b86 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	faa080e7          	jalr	-86(ra) # 80001b86 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	f9e080e7          	jalr	-98(ra) # 80001b86 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	f86080e7          	jalr	-122(ra) # 80001b86 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	f46080e7          	jalr	-186(ra) # 80001b86 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	f1a080e7          	jalr	-230(ra) # 80001b86 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	cb0080e7          	jalr	-848(ra) # 80001b76 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	c94080e7          	jalr	-876(ra) # 80001b76 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	208080e7          	jalr	520(ra) # 80001104 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	8fc080e7          	jalr	-1796(ra) # 80002800 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	f74080e7          	jalr	-140(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	1be080e7          	jalr	446(ra) # 800020d2 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	464080e7          	jalr	1124(ra) # 800013c8 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	198080e7          	jalr	408(ra) # 80001104 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	b32080e7          	jalr	-1230(ra) # 80001aa6 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	85c080e7          	jalr	-1956(ra) # 800027d8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	87c080e7          	jalr	-1924(ra) # 80002800 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	ede080e7          	jalr	-290(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	eec080e7          	jalr	-276(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	070080e7          	jalr	112(ra) # 8000300c <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	700080e7          	jalr	1792(ra) # 800036a4 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	69e080e7          	jalr	1694(ra) # 8000464a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	fd4080e7          	jalr	-44(ra) # 80005f88 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	eb0080e7          	jalr	-336(ra) # 80001e6c <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <print_recursively>:
    return -1;
  }
}

static void print_recursively(pagetable_t pagetable, int level)
{
    80000fd4:	7119                	addi	sp,sp,-128
    80000fd6:	fc86                	sd	ra,120(sp)
    80000fd8:	f8a2                	sd	s0,112(sp)
    80000fda:	f4a6                	sd	s1,104(sp)
    80000fdc:	f0ca                	sd	s2,96(sp)
    80000fde:	ecce                	sd	s3,88(sp)
    80000fe0:	e8d2                	sd	s4,80(sp)
    80000fe2:	e4d6                	sd	s5,72(sp)
    80000fe4:	e0da                	sd	s6,64(sp)
    80000fe6:	fc5e                	sd	s7,56(sp)
    80000fe8:	f862                	sd	s8,48(sp)
    80000fea:	f466                	sd	s9,40(sp)
    80000fec:	f06a                	sd	s10,32(sp)
    80000fee:	ec6e                	sd	s11,24(sp)
    80000ff0:	0100                	addi	s0,sp,128
    80000ff2:	8aae                	mv	s5,a1
  //? 参数：
  //*   pagetable_t pagetable: 传入的需要打印的页表
  //*   int level: 打印的递归层数
  //? 返回值：
  //*   无返回值
  for(int i = 0; i < 512; i++)
    80000ff4:	892a                	mv	s2,a0
    80000ff6:	4481                	li	s1,0
  {
    pte_t pte = pagetable[i]; // 获取页表pagetable中的项
    
    char state[5]; // 用于输出该页权限的字符串
    int ind = 0; // 控制字符串state的写入
    80000ff8:	4981                	li	s3,0
    // 表征权限的四个位：PTE_R, PTE_W, PTE_X, PTE_U
    // 将pte与四个位分别做与运算，取出对应位置的置位值
    if(pte & PTE_R)
      state[ind++] = 'R';
    80000ffa:	05200c93          	li	s9,82
    80000ffe:	4a05                	li	s4,1
    if(pte & PTE_W)
      state[ind++] = 'W';
    80001000:	05700c13          	li	s8,87
    if(pte & PTE_X)
      state[ind++] = 'X';
    80001004:	05800b93          	li	s7,88
    if(pte & PTE_U)
      state[ind++] = 'U';
    80001008:	05500b13          	li	s6,85
        printf(".. ..%d: pte %p (%s) pa %p\n", i, pte, state, child);
        print_recursively((pagetable_t)child, level + 1);
      }
      else // 最后一层递归，打印后返回
      {
        printf(".. .. ..%d: pte %p (%s) pa %p\n", i, pte, state, child);
    8000100c:	00007d17          	auipc	s10,0x7
    80001010:	104d0d13          	addi	s10,s10,260 # 80008110 <digits+0xd0>
    80001014:	a099                	j	8000105a <print_recursively+0x86>
        printf("..%d: pte %p (%s) pa %p\n", i, pte, state, child);
    80001016:	876e                	mv	a4,s11
    80001018:	f8840693          	addi	a3,s0,-120
    8000101c:	85a6                	mv	a1,s1
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	56c080e7          	jalr	1388(ra) # 80000592 <printf>
        print_recursively((pagetable_t)child, level + 1);
    8000102e:	85d2                	mv	a1,s4
    80001030:	856e                	mv	a0,s11
    80001032:	00000097          	auipc	ra,0x0
    80001036:	fa2080e7          	jalr	-94(ra) # 80000fd4 <print_recursively>
    8000103a:	a811                	j	8000104e <print_recursively+0x7a>
        printf(".. .. ..%d: pte %p (%s) pa %p\n", i, pte, state, child);
    8000103c:	876e                	mv	a4,s11
    8000103e:	f8840693          	addi	a3,s0,-120
    80001042:	85a6                	mv	a1,s1
    80001044:	856a                	mv	a0,s10
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	54c080e7          	jalr	1356(ra) # 80000592 <printf>
  for(int i = 0; i < 512; i++)
    8000104e:	2485                	addiw	s1,s1,1
    80001050:	0921                	addi	s2,s2,8
    80001052:	20000793          	li	a5,512
    80001056:	08f48863          	beq	s1,a5,800010e6 <print_recursively+0x112>
    pte_t pte = pagetable[i]; // 获取页表pagetable中的项
    8000105a:	00093603          	ld	a2,0(s2)
    if(pte & PTE_R)
    8000105e:	00267713          	andi	a4,a2,2
    int ind = 0; // 控制字符串state的写入
    80001062:	87ce                	mv	a5,s3
    if(pte & PTE_R)
    80001064:	c701                	beqz	a4,8000106c <print_recursively+0x98>
      state[ind++] = 'R';
    80001066:	f9940423          	sb	s9,-120(s0)
    8000106a:	87d2                	mv	a5,s4
    if(pte & PTE_W)
    8000106c:	00467713          	andi	a4,a2,4
    80001070:	c719                	beqz	a4,8000107e <print_recursively+0xaa>
      state[ind++] = 'W';
    80001072:	f9040713          	addi	a4,s0,-112
    80001076:	973e                	add	a4,a4,a5
    80001078:	ff870c23          	sb	s8,-8(a4)
    8000107c:	2785                	addiw	a5,a5,1
    if(pte & PTE_X)
    8000107e:	00867713          	andi	a4,a2,8
    80001082:	c719                	beqz	a4,80001090 <print_recursively+0xbc>
      state[ind++] = 'X';
    80001084:	f9040713          	addi	a4,s0,-112
    80001088:	973e                	add	a4,a4,a5
    8000108a:	ff770c23          	sb	s7,-8(a4)
    8000108e:	2785                	addiw	a5,a5,1
    if(pte & PTE_U)
    80001090:	01067713          	andi	a4,a2,16
    80001094:	c719                	beqz	a4,800010a2 <print_recursively+0xce>
      state[ind++] = 'U';
    80001096:	f9040713          	addi	a4,s0,-112
    8000109a:	973e                	add	a4,a4,a5
    8000109c:	ff670c23          	sb	s6,-8(a4)
    800010a0:	2785                	addiw	a5,a5,1
    state[ind] = '\0';
    800010a2:	f9040713          	addi	a4,s0,-112
    800010a6:	97ba                	add	a5,a5,a4
    800010a8:	fe078c23          	sb	zero,-8(a5)
    if(pte & PTE_V) // 该页合法，可访问
    800010ac:	00167793          	andi	a5,a2,1
    800010b0:	dfd9                	beqz	a5,8000104e <print_recursively+0x7a>
      uint64 child = PTE2PA(pte); // 利用移位函数PTE2PA取出子页面的地址
    800010b2:	00a65d93          	srli	s11,a2,0xa
    800010b6:	0db2                	slli	s11,s11,0xc
      if(level == 0)
    800010b8:	f40a8fe3          	beqz	s5,80001016 <print_recursively+0x42>
      else if(level == 1)
    800010bc:	f94a90e3          	bne	s5,s4,8000103c <print_recursively+0x68>
        printf(".. ..%d: pte %p (%s) pa %p\n", i, pte, state, child);
    800010c0:	876e                	mv	a4,s11
    800010c2:	f8840693          	addi	a3,s0,-120
    800010c6:	85a6                	mv	a1,s1
    800010c8:	00007517          	auipc	a0,0x7
    800010cc:	02850513          	addi	a0,a0,40 # 800080f0 <digits+0xb0>
    800010d0:	fffff097          	auipc	ra,0xfffff
    800010d4:	4c2080e7          	jalr	1218(ra) # 80000592 <printf>
        print_recursively((pagetable_t)child, level + 1);
    800010d8:	4589                	li	a1,2
    800010da:	856e                	mv	a0,s11
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	ef8080e7          	jalr	-264(ra) # 80000fd4 <print_recursively>
    800010e4:	b7ad                	j	8000104e <print_recursively+0x7a>
      }
    }
  }
}
    800010e6:	70e6                	ld	ra,120(sp)
    800010e8:	7446                	ld	s0,112(sp)
    800010ea:	74a6                	ld	s1,104(sp)
    800010ec:	7906                	ld	s2,96(sp)
    800010ee:	69e6                	ld	s3,88(sp)
    800010f0:	6a46                	ld	s4,80(sp)
    800010f2:	6aa6                	ld	s5,72(sp)
    800010f4:	6b06                	ld	s6,64(sp)
    800010f6:	7be2                	ld	s7,56(sp)
    800010f8:	7c42                	ld	s8,48(sp)
    800010fa:	7ca2                	ld	s9,40(sp)
    800010fc:	7d02                	ld	s10,32(sp)
    800010fe:	6de2                	ld	s11,24(sp)
    80001100:	6109                	addi	sp,sp,128
    80001102:	8082                	ret

0000000080001104 <kvminithart>:
{
    80001104:	1141                	addi	sp,sp,-16
    80001106:	e422                	sd	s0,8(sp)
    80001108:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000110a:	00008797          	auipc	a5,0x8
    8000110e:	f067b783          	ld	a5,-250(a5) # 80009010 <kernel_pagetable>
    80001112:	83b1                	srli	a5,a5,0xc
    80001114:	577d                	li	a4,-1
    80001116:	177e                	slli	a4,a4,0x3f
    80001118:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000111a:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000111e:	12000073          	sfence.vma
}
    80001122:	6422                	ld	s0,8(sp)
    80001124:	0141                	addi	sp,sp,16
    80001126:	8082                	ret

0000000080001128 <walk>:
{
    80001128:	7139                	addi	sp,sp,-64
    8000112a:	fc06                	sd	ra,56(sp)
    8000112c:	f822                	sd	s0,48(sp)
    8000112e:	f426                	sd	s1,40(sp)
    80001130:	f04a                	sd	s2,32(sp)
    80001132:	ec4e                	sd	s3,24(sp)
    80001134:	e852                	sd	s4,16(sp)
    80001136:	e456                	sd	s5,8(sp)
    80001138:	e05a                	sd	s6,0(sp)
    8000113a:	0080                	addi	s0,sp,64
    8000113c:	84aa                	mv	s1,a0
    8000113e:	89ae                	mv	s3,a1
    80001140:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001142:	57fd                	li	a5,-1
    80001144:	83e9                	srli	a5,a5,0x1a
    80001146:	4a79                	li	s4,30
  for(int level = 2; level > 0; level--) {
    80001148:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000114a:	04b7f263          	bgeu	a5,a1,8000118e <walk+0x66>
    panic("walk");
    8000114e:	00007517          	auipc	a0,0x7
    80001152:	fe250513          	addi	a0,a0,-30 # 80008130 <digits+0xf0>
    80001156:	fffff097          	auipc	ra,0xfffff
    8000115a:	3f2080e7          	jalr	1010(ra) # 80000548 <panic>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000115e:	060a8663          	beqz	s5,800011ca <walk+0xa2>
    80001162:	00000097          	auipc	ra,0x0
    80001166:	9be080e7          	jalr	-1602(ra) # 80000b20 <kalloc>
    8000116a:	84aa                	mv	s1,a0
    8000116c:	c529                	beqz	a0,800011b6 <walk+0x8e>
      memset(pagetable, 0, PGSIZE);
    8000116e:	6605                	lui	a2,0x1
    80001170:	4581                	li	a1,0
    80001172:	00000097          	auipc	ra,0x0
    80001176:	b9a080e7          	jalr	-1126(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000117a:	00c4d793          	srli	a5,s1,0xc
    8000117e:	07aa                	slli	a5,a5,0xa
    80001180:	0017e793          	ori	a5,a5,1
    80001184:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001188:	3a5d                	addiw	s4,s4,-9
    8000118a:	036a0063          	beq	s4,s6,800011aa <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000118e:	0149d933          	srl	s2,s3,s4
    80001192:	1ff97913          	andi	s2,s2,511
    80001196:	090e                	slli	s2,s2,0x3
    80001198:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000119a:	00093483          	ld	s1,0(s2)
    8000119e:	0014f793          	andi	a5,s1,1
    800011a2:	dfd5                	beqz	a5,8000115e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011a4:	80a9                	srli	s1,s1,0xa
    800011a6:	04b2                	slli	s1,s1,0xc
    800011a8:	b7c5                	j	80001188 <walk+0x60>
  return &pagetable[PX(0, va)];
    800011aa:	00c9d513          	srli	a0,s3,0xc
    800011ae:	1ff57513          	andi	a0,a0,511
    800011b2:	050e                	slli	a0,a0,0x3
    800011b4:	9526                	add	a0,a0,s1
}
    800011b6:	70e2                	ld	ra,56(sp)
    800011b8:	7442                	ld	s0,48(sp)
    800011ba:	74a2                	ld	s1,40(sp)
    800011bc:	7902                	ld	s2,32(sp)
    800011be:	69e2                	ld	s3,24(sp)
    800011c0:	6a42                	ld	s4,16(sp)
    800011c2:	6aa2                	ld	s5,8(sp)
    800011c4:	6b02                	ld	s6,0(sp)
    800011c6:	6121                	addi	sp,sp,64
    800011c8:	8082                	ret
        return 0;
    800011ca:	4501                	li	a0,0
    800011cc:	b7ed                	j	800011b6 <walk+0x8e>

00000000800011ce <kvmpa>:
{
    800011ce:	1101                	addi	sp,sp,-32
    800011d0:	ec06                	sd	ra,24(sp)
    800011d2:	e822                	sd	s0,16(sp)
    800011d4:	e426                	sd	s1,8(sp)
    800011d6:	1000                	addi	s0,sp,32
    800011d8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800011da:	1552                	slli	a0,a0,0x34
    800011dc:	03455493          	srli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    800011e0:	4601                	li	a2,0
    800011e2:	00008517          	auipc	a0,0x8
    800011e6:	e2e53503          	ld	a0,-466(a0) # 80009010 <kernel_pagetable>
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f3e080e7          	jalr	-194(ra) # 80001128 <walk>
  if(pte == 0)
    800011f2:	cd09                	beqz	a0,8000120c <kvmpa+0x3e>
  if((*pte & PTE_V) == 0)
    800011f4:	6108                	ld	a0,0(a0)
    800011f6:	00157793          	andi	a5,a0,1
    800011fa:	c38d                	beqz	a5,8000121c <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    800011fc:	8129                	srli	a0,a0,0xa
    800011fe:	0532                	slli	a0,a0,0xc
}
    80001200:	9526                	add	a0,a0,s1
    80001202:	60e2                	ld	ra,24(sp)
    80001204:	6442                	ld	s0,16(sp)
    80001206:	64a2                	ld	s1,8(sp)
    80001208:	6105                	addi	sp,sp,32
    8000120a:	8082                	ret
    panic("kvmpa");
    8000120c:	00007517          	auipc	a0,0x7
    80001210:	f2c50513          	addi	a0,a0,-212 # 80008138 <digits+0xf8>
    80001214:	fffff097          	auipc	ra,0xfffff
    80001218:	334080e7          	jalr	820(ra) # 80000548 <panic>
    panic("kvmpa");
    8000121c:	00007517          	auipc	a0,0x7
    80001220:	f1c50513          	addi	a0,a0,-228 # 80008138 <digits+0xf8>
    80001224:	fffff097          	auipc	ra,0xfffff
    80001228:	324080e7          	jalr	804(ra) # 80000548 <panic>

000000008000122c <mappages>:
{
    8000122c:	715d                	addi	sp,sp,-80
    8000122e:	e486                	sd	ra,72(sp)
    80001230:	e0a2                	sd	s0,64(sp)
    80001232:	fc26                	sd	s1,56(sp)
    80001234:	f84a                	sd	s2,48(sp)
    80001236:	f44e                	sd	s3,40(sp)
    80001238:	f052                	sd	s4,32(sp)
    8000123a:	ec56                	sd	s5,24(sp)
    8000123c:	e85a                	sd	s6,16(sp)
    8000123e:	e45e                	sd	s7,8(sp)
    80001240:	0880                	addi	s0,sp,80
    80001242:	8aaa                	mv	s5,a0
    80001244:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80001246:	777d                	lui	a4,0xfffff
    80001248:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000124c:	167d                	addi	a2,a2,-1
    8000124e:	00b609b3          	add	s3,a2,a1
    80001252:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001256:	893e                	mv	s2,a5
    80001258:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    8000125c:	6b85                	lui	s7,0x1
    8000125e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001262:	4605                	li	a2,1
    80001264:	85ca                	mv	a1,s2
    80001266:	8556                	mv	a0,s5
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	ec0080e7          	jalr	-320(ra) # 80001128 <walk>
    80001270:	c51d                	beqz	a0,8000129e <mappages+0x72>
    if(*pte & PTE_V)
    80001272:	611c                	ld	a5,0(a0)
    80001274:	8b85                	andi	a5,a5,1
    80001276:	ef81                	bnez	a5,8000128e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001278:	80b1                	srli	s1,s1,0xc
    8000127a:	04aa                	slli	s1,s1,0xa
    8000127c:	0164e4b3          	or	s1,s1,s6
    80001280:	0014e493          	ori	s1,s1,1
    80001284:	e104                	sd	s1,0(a0)
    if(a == last)
    80001286:	03390863          	beq	s2,s3,800012b6 <mappages+0x8a>
    a += PGSIZE;
    8000128a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000128c:	bfc9                	j	8000125e <mappages+0x32>
      panic("remap");
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	eb250513          	addi	a0,a0,-334 # 80008140 <digits+0x100>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	2b2080e7          	jalr	690(ra) # 80000548 <panic>
      return -1;
    8000129e:	557d                	li	a0,-1
}
    800012a0:	60a6                	ld	ra,72(sp)
    800012a2:	6406                	ld	s0,64(sp)
    800012a4:	74e2                	ld	s1,56(sp)
    800012a6:	7942                	ld	s2,48(sp)
    800012a8:	79a2                	ld	s3,40(sp)
    800012aa:	7a02                	ld	s4,32(sp)
    800012ac:	6ae2                	ld	s5,24(sp)
    800012ae:	6b42                	ld	s6,16(sp)
    800012b0:	6ba2                	ld	s7,8(sp)
    800012b2:	6161                	addi	sp,sp,80
    800012b4:	8082                	ret
  return 0;
    800012b6:	4501                	li	a0,0
    800012b8:	b7e5                	j	800012a0 <mappages+0x74>

00000000800012ba <walkaddr>:
{
    800012ba:	7179                	addi	sp,sp,-48
    800012bc:	f406                	sd	ra,40(sp)
    800012be:	f022                	sd	s0,32(sp)
    800012c0:	ec26                	sd	s1,24(sp)
    800012c2:	e84a                	sd	s2,16(sp)
    800012c4:	e44e                	sd	s3,8(sp)
    800012c6:	e052                	sd	s4,0(sp)
    800012c8:	1800                	addi	s0,sp,48
    800012ca:	892a                	mv	s2,a0
    800012cc:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800012ce:	00001097          	auipc	ra,0x1
    800012d2:	8d4080e7          	jalr	-1836(ra) # 80001ba2 <myproc>
  if(va >= MAXVA)
    800012d6:	57fd                	li	a5,-1
    800012d8:	83e9                	srli	a5,a5,0x1a
    800012da:	0097fc63          	bgeu	a5,s1,800012f2 <walkaddr+0x38>
    return 0;
    800012de:	4901                	li	s2,0
}
    800012e0:	854a                	mv	a0,s2
    800012e2:	70a2                	ld	ra,40(sp)
    800012e4:	7402                	ld	s0,32(sp)
    800012e6:	64e2                	ld	s1,24(sp)
    800012e8:	6942                	ld	s2,16(sp)
    800012ea:	69a2                	ld	s3,8(sp)
    800012ec:	6a02                	ld	s4,0(sp)
    800012ee:	6145                	addi	sp,sp,48
    800012f0:	8082                	ret
    800012f2:	89aa                	mv	s3,a0
  pte = walk(pagetable, va, 0);
    800012f4:	4601                	li	a2,0
    800012f6:	85a6                	mv	a1,s1
    800012f8:	854a                	mv	a0,s2
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	e2e080e7          	jalr	-466(ra) # 80001128 <walk>
  if(pte == 0 || (*pte & PTE_V) == 0)
    80001302:	c509                	beqz	a0,8000130c <walkaddr+0x52>
    80001304:	611c                	ld	a5,0(a0)
    80001306:	0017f713          	andi	a4,a5,1
    8000130a:	eb3d                	bnez	a4,80001380 <walkaddr+0xc6>
    if (va >= p->sz || va < PGROUNDUP(p->trapframe->sp))
    8000130c:	0489b783          	ld	a5,72(s3) # 1048 <_entry-0x7fffefb8>
      return 0;
    80001310:	4901                	li	s2,0
    if (va >= p->sz || va < PGROUNDUP(p->trapframe->sp))
    80001312:	fcf4f7e3          	bgeu	s1,a5,800012e0 <walkaddr+0x26>
    80001316:	0589b783          	ld	a5,88(s3)
    8000131a:	7b9c                	ld	a5,48(a5)
    8000131c:	6705                	lui	a4,0x1
    8000131e:	177d                	addi	a4,a4,-1
    80001320:	97ba                	add	a5,a5,a4
    80001322:	777d                	lui	a4,0xfffff
    80001324:	8ff9                	and	a5,a5,a4
    80001326:	faf4ede3          	bltu	s1,a5,800012e0 <walkaddr+0x26>
    char *mem = kalloc();
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	7f6080e7          	jalr	2038(ra) # 80000b20 <kalloc>
    80001332:	8a2a                	mv	s4,a0
    if (mem == 0)
    80001334:	cd0d                	beqz	a0,8000136e <walkaddr+0xb4>
    if (mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0)
    80001336:	892a                	mv	s2,a0
    80001338:	4779                	li	a4,30
    8000133a:	86aa                	mv	a3,a0
    8000133c:	6605                	lui	a2,0x1
    8000133e:	75fd                	lui	a1,0xfffff
    80001340:	8de5                	and	a1,a1,s1
    80001342:	0509b503          	ld	a0,80(s3)
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	ee6080e7          	jalr	-282(ra) # 8000122c <mappages>
    8000134e:	d949                	beqz	a0,800012e0 <walkaddr+0x26>
      printf("walkaddr: mappages failed\n");
    80001350:	00007517          	auipc	a0,0x7
    80001354:	e1850513          	addi	a0,a0,-488 # 80008168 <digits+0x128>
    80001358:	fffff097          	auipc	ra,0xfffff
    8000135c:	23a080e7          	jalr	570(ra) # 80000592 <printf>
      kfree(mem);
    80001360:	8552                	mv	a0,s4
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	6c2080e7          	jalr	1730(ra) # 80000a24 <kfree>
      return 0;
    8000136a:	4901                	li	s2,0
    8000136c:	bf95                	j	800012e0 <walkaddr+0x26>
      printf("walkaddr: kalloc failed\n");
    8000136e:	00007517          	auipc	a0,0x7
    80001372:	dda50513          	addi	a0,a0,-550 # 80008148 <digits+0x108>
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	21c080e7          	jalr	540(ra) # 80000592 <printf>
      return 0;
    8000137e:	b78d                	j	800012e0 <walkaddr+0x26>
  if((*pte & PTE_U) == 0)
    80001380:	0107f913          	andi	s2,a5,16
    80001384:	f4090ee3          	beqz	s2,800012e0 <walkaddr+0x26>
  pa = PTE2PA(*pte);
    80001388:	00a7d913          	srli	s2,a5,0xa
    8000138c:	0932                	slli	s2,s2,0xc
  return pa;
    8000138e:	bf89                	j	800012e0 <walkaddr+0x26>

0000000080001390 <kvmmap>:
{
    80001390:	1141                	addi	sp,sp,-16
    80001392:	e406                	sd	ra,8(sp)
    80001394:	e022                	sd	s0,0(sp)
    80001396:	0800                	addi	s0,sp,16
    80001398:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000139a:	86ae                	mv	a3,a1
    8000139c:	85aa                	mv	a1,a0
    8000139e:	00008517          	auipc	a0,0x8
    800013a2:	c7253503          	ld	a0,-910(a0) # 80009010 <kernel_pagetable>
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	e86080e7          	jalr	-378(ra) # 8000122c <mappages>
    800013ae:	e509                	bnez	a0,800013b8 <kvmmap+0x28>
}
    800013b0:	60a2                	ld	ra,8(sp)
    800013b2:	6402                	ld	s0,0(sp)
    800013b4:	0141                	addi	sp,sp,16
    800013b6:	8082                	ret
    panic("kvmmap");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	dd050513          	addi	a0,a0,-560 # 80008188 <digits+0x148>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	188080e7          	jalr	392(ra) # 80000548 <panic>

00000000800013c8 <kvminit>:
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	74e080e7          	jalr	1870(ra) # 80000b20 <kalloc>
    800013da:	00008797          	auipc	a5,0x8
    800013de:	c2a7bb23          	sd	a0,-970(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800013e2:	6605                	lui	a2,0x1
    800013e4:	4581                	li	a1,0
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	926080e7          	jalr	-1754(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013ee:	4699                	li	a3,6
    800013f0:	6605                	lui	a2,0x1
    800013f2:	100005b7          	lui	a1,0x10000
    800013f6:	10000537          	lui	a0,0x10000
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	f96080e7          	jalr	-106(ra) # 80001390 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001402:	4699                	li	a3,6
    80001404:	6605                	lui	a2,0x1
    80001406:	100015b7          	lui	a1,0x10001
    8000140a:	10001537          	lui	a0,0x10001
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	f82080e7          	jalr	-126(ra) # 80001390 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001416:	4699                	li	a3,6
    80001418:	6641                	lui	a2,0x10
    8000141a:	020005b7          	lui	a1,0x2000
    8000141e:	02000537          	lui	a0,0x2000
    80001422:	00000097          	auipc	ra,0x0
    80001426:	f6e080e7          	jalr	-146(ra) # 80001390 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000142a:	4699                	li	a3,6
    8000142c:	00400637          	lui	a2,0x400
    80001430:	0c0005b7          	lui	a1,0xc000
    80001434:	0c000537          	lui	a0,0xc000
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	f58080e7          	jalr	-168(ra) # 80001390 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001440:	00007497          	auipc	s1,0x7
    80001444:	bc048493          	addi	s1,s1,-1088 # 80008000 <etext>
    80001448:	46a9                	li	a3,10
    8000144a:	80007617          	auipc	a2,0x80007
    8000144e:	bb660613          	addi	a2,a2,-1098 # 8000 <_entry-0x7fff8000>
    80001452:	4585                	li	a1,1
    80001454:	05fe                	slli	a1,a1,0x1f
    80001456:	852e                	mv	a0,a1
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f38080e7          	jalr	-200(ra) # 80001390 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001460:	4699                	li	a3,6
    80001462:	4645                	li	a2,17
    80001464:	066e                	slli	a2,a2,0x1b
    80001466:	8e05                	sub	a2,a2,s1
    80001468:	85a6                	mv	a1,s1
    8000146a:	8526                	mv	a0,s1
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	f24080e7          	jalr	-220(ra) # 80001390 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001474:	46a9                	li	a3,10
    80001476:	6605                	lui	a2,0x1
    80001478:	00006597          	auipc	a1,0x6
    8000147c:	b8858593          	addi	a1,a1,-1144 # 80007000 <_trampoline>
    80001480:	04000537          	lui	a0,0x4000
    80001484:	157d                	addi	a0,a0,-1
    80001486:	0532                	slli	a0,a0,0xc
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	f08080e7          	jalr	-248(ra) # 80001390 <kvmmap>
}
    80001490:	60e2                	ld	ra,24(sp)
    80001492:	6442                	ld	s0,16(sp)
    80001494:	64a2                	ld	s1,8(sp)
    80001496:	6105                	addi	sp,sp,32
    80001498:	8082                	ret

000000008000149a <uvmunmap>:
{
    8000149a:	715d                	addi	sp,sp,-80
    8000149c:	e486                	sd	ra,72(sp)
    8000149e:	e0a2                	sd	s0,64(sp)
    800014a0:	fc26                	sd	s1,56(sp)
    800014a2:	f84a                	sd	s2,48(sp)
    800014a4:	f44e                	sd	s3,40(sp)
    800014a6:	f052                	sd	s4,32(sp)
    800014a8:	ec56                	sd	s5,24(sp)
    800014aa:	e85a                	sd	s6,16(sp)
    800014ac:	e45e                	sd	s7,8(sp)
    800014ae:	0880                	addi	s0,sp,80
  if((va % PGSIZE) != 0)
    800014b0:	03459793          	slli	a5,a1,0x34
    800014b4:	e795                	bnez	a5,800014e0 <uvmunmap+0x46>
    800014b6:	8a2a                	mv	s4,a0
    800014b8:	892e                	mv	s2,a1
    800014ba:	8b36                	mv	s6,a3
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014bc:	0632                	slli	a2,a2,0xc
    800014be:	00b609b3          	add	s3,a2,a1
    if(PTE_FLAGS(*pte) == PTE_V)
    800014c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014c4:	6a85                	lui	s5,0x1
    800014c6:	0535ec63          	bltu	a1,s3,8000151e <uvmunmap+0x84>
}
    800014ca:	60a6                	ld	ra,72(sp)
    800014cc:	6406                	ld	s0,64(sp)
    800014ce:	74e2                	ld	s1,56(sp)
    800014d0:	7942                	ld	s2,48(sp)
    800014d2:	79a2                	ld	s3,40(sp)
    800014d4:	7a02                	ld	s4,32(sp)
    800014d6:	6ae2                	ld	s5,24(sp)
    800014d8:	6b42                	ld	s6,16(sp)
    800014da:	6ba2                	ld	s7,8(sp)
    800014dc:	6161                	addi	sp,sp,80
    800014de:	8082                	ret
    panic("uvmunmap: not aligned");
    800014e0:	00007517          	auipc	a0,0x7
    800014e4:	cb050513          	addi	a0,a0,-848 # 80008190 <digits+0x150>
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	060080e7          	jalr	96(ra) # 80000548 <panic>
      *pte = 0;
    800014f0:	00053023          	sd	zero,0(a0)
      continue;
    800014f4:	a015                	j	80001518 <uvmunmap+0x7e>
      panic("uvmunmap: not a leaf");
    800014f6:	00007517          	auipc	a0,0x7
    800014fa:	cb250513          	addi	a0,a0,-846 # 800081a8 <digits+0x168>
    800014fe:	fffff097          	auipc	ra,0xfffff
    80001502:	04a080e7          	jalr	74(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001506:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001508:	00c79513          	slli	a0,a5,0xc
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	518080e7          	jalr	1304(ra) # 80000a24 <kfree>
    *pte = 0;
    80001514:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001518:	9956                	add	s2,s2,s5
    8000151a:	fb3978e3          	bgeu	s2,s3,800014ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000151e:	4601                	li	a2,0
    80001520:	85ca                	mv	a1,s2
    80001522:	8552                	mv	a0,s4
    80001524:	00000097          	auipc	ra,0x0
    80001528:	c04080e7          	jalr	-1020(ra) # 80001128 <walk>
    8000152c:	84aa                	mv	s1,a0
    8000152e:	d56d                	beqz	a0,80001518 <uvmunmap+0x7e>
    if((*pte & PTE_V) == 0)
    80001530:	611c                	ld	a5,0(a0)
    80001532:	0017f713          	andi	a4,a5,1
    80001536:	df4d                	beqz	a4,800014f0 <uvmunmap+0x56>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001538:	3ff7f713          	andi	a4,a5,1023
    8000153c:	fb770de3          	beq	a4,s7,800014f6 <uvmunmap+0x5c>
    if(do_free){
    80001540:	fc0b0ae3          	beqz	s6,80001514 <uvmunmap+0x7a>
    80001544:	b7c9                	j	80001506 <uvmunmap+0x6c>

0000000080001546 <uvmcreate>:
{
    80001546:	1101                	addi	sp,sp,-32
    80001548:	ec06                	sd	ra,24(sp)
    8000154a:	e822                	sd	s0,16(sp)
    8000154c:	e426                	sd	s1,8(sp)
    8000154e:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	5d0080e7          	jalr	1488(ra) # 80000b20 <kalloc>
    80001558:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000155a:	c519                	beqz	a0,80001568 <uvmcreate+0x22>
  memset(pagetable, 0, PGSIZE);
    8000155c:	6605                	lui	a2,0x1
    8000155e:	4581                	li	a1,0
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	7ac080e7          	jalr	1964(ra) # 80000d0c <memset>
}
    80001568:	8526                	mv	a0,s1
    8000156a:	60e2                	ld	ra,24(sp)
    8000156c:	6442                	ld	s0,16(sp)
    8000156e:	64a2                	ld	s1,8(sp)
    80001570:	6105                	addi	sp,sp,32
    80001572:	8082                	ret

0000000080001574 <uvminit>:
{
    80001574:	7179                	addi	sp,sp,-48
    80001576:	f406                	sd	ra,40(sp)
    80001578:	f022                	sd	s0,32(sp)
    8000157a:	ec26                	sd	s1,24(sp)
    8000157c:	e84a                	sd	s2,16(sp)
    8000157e:	e44e                	sd	s3,8(sp)
    80001580:	e052                	sd	s4,0(sp)
    80001582:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    80001584:	6785                	lui	a5,0x1
    80001586:	04f67863          	bgeu	a2,a5,800015d6 <uvminit+0x62>
    8000158a:	8a2a                	mv	s4,a0
    8000158c:	89ae                	mv	s3,a1
    8000158e:	84b2                	mv	s1,a2
  mem = kalloc();
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	590080e7          	jalr	1424(ra) # 80000b20 <kalloc>
    80001598:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000159a:	6605                	lui	a2,0x1
    8000159c:	4581                	li	a1,0
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	76e080e7          	jalr	1902(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800015a6:	4779                	li	a4,30
    800015a8:	86ca                	mv	a3,s2
    800015aa:	6605                	lui	a2,0x1
    800015ac:	4581                	li	a1,0
    800015ae:	8552                	mv	a0,s4
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	c7c080e7          	jalr	-900(ra) # 8000122c <mappages>
  memmove(mem, src, sz);
    800015b8:	8626                	mv	a2,s1
    800015ba:	85ce                	mv	a1,s3
    800015bc:	854a                	mv	a0,s2
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	7ae080e7          	jalr	1966(ra) # 80000d6c <memmove>
}
    800015c6:	70a2                	ld	ra,40(sp)
    800015c8:	7402                	ld	s0,32(sp)
    800015ca:	64e2                	ld	s1,24(sp)
    800015cc:	6942                	ld	s2,16(sp)
    800015ce:	69a2                	ld	s3,8(sp)
    800015d0:	6a02                	ld	s4,0(sp)
    800015d2:	6145                	addi	sp,sp,48
    800015d4:	8082                	ret
    panic("inituvm: more than a page");
    800015d6:	00007517          	auipc	a0,0x7
    800015da:	bea50513          	addi	a0,a0,-1046 # 800081c0 <digits+0x180>
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	f6a080e7          	jalr	-150(ra) # 80000548 <panic>

00000000800015e6 <uvmdealloc>:
{
    800015e6:	1101                	addi	sp,sp,-32
    800015e8:	ec06                	sd	ra,24(sp)
    800015ea:	e822                	sd	s0,16(sp)
    800015ec:	e426                	sd	s1,8(sp)
    800015ee:	1000                	addi	s0,sp,32
    return oldsz;
    800015f0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015f2:	00b67d63          	bgeu	a2,a1,8000160c <uvmdealloc+0x26>
    800015f6:	84b2                	mv	s1,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015f8:	6785                	lui	a5,0x1
    800015fa:	17fd                	addi	a5,a5,-1
    800015fc:	00f60733          	add	a4,a2,a5
    80001600:	767d                	lui	a2,0xfffff
    80001602:	8f71                	and	a4,a4,a2
    80001604:	97ae                	add	a5,a5,a1
    80001606:	8ff1                	and	a5,a5,a2
    80001608:	00f76863          	bltu	a4,a5,80001618 <uvmdealloc+0x32>
}
    8000160c:	8526                	mv	a0,s1
    8000160e:	60e2                	ld	ra,24(sp)
    80001610:	6442                	ld	s0,16(sp)
    80001612:	64a2                	ld	s1,8(sp)
    80001614:	6105                	addi	sp,sp,32
    80001616:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001618:	8f99                	sub	a5,a5,a4
    8000161a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000161c:	4685                	li	a3,1
    8000161e:	0007861b          	sext.w	a2,a5
    80001622:	85ba                	mv	a1,a4
    80001624:	00000097          	auipc	ra,0x0
    80001628:	e76080e7          	jalr	-394(ra) # 8000149a <uvmunmap>
    8000162c:	b7c5                	j	8000160c <uvmdealloc+0x26>

000000008000162e <uvmalloc>:
  if(newsz < oldsz)
    8000162e:	0ab66163          	bltu	a2,a1,800016d0 <uvmalloc+0xa2>
{
    80001632:	7139                	addi	sp,sp,-64
    80001634:	fc06                	sd	ra,56(sp)
    80001636:	f822                	sd	s0,48(sp)
    80001638:	f426                	sd	s1,40(sp)
    8000163a:	f04a                	sd	s2,32(sp)
    8000163c:	ec4e                	sd	s3,24(sp)
    8000163e:	e852                	sd	s4,16(sp)
    80001640:	e456                	sd	s5,8(sp)
    80001642:	0080                	addi	s0,sp,64
    80001644:	8aaa                	mv	s5,a0
    80001646:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001648:	6985                	lui	s3,0x1
    8000164a:	19fd                	addi	s3,s3,-1
    8000164c:	95ce                	add	a1,a1,s3
    8000164e:	79fd                	lui	s3,0xfffff
    80001650:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001654:	08c9f063          	bgeu	s3,a2,800016d4 <uvmalloc+0xa6>
    80001658:	894e                	mv	s2,s3
    mem = kalloc();
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	4c6080e7          	jalr	1222(ra) # 80000b20 <kalloc>
    80001662:	84aa                	mv	s1,a0
    if(mem == 0){
    80001664:	c51d                	beqz	a0,80001692 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001666:	6605                	lui	a2,0x1
    80001668:	4581                	li	a1,0
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	6a2080e7          	jalr	1698(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001672:	4779                	li	a4,30
    80001674:	86a6                	mv	a3,s1
    80001676:	6605                	lui	a2,0x1
    80001678:	85ca                	mv	a1,s2
    8000167a:	8556                	mv	a0,s5
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	bb0080e7          	jalr	-1104(ra) # 8000122c <mappages>
    80001684:	e905                	bnez	a0,800016b4 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001686:	6785                	lui	a5,0x1
    80001688:	993e                	add	s2,s2,a5
    8000168a:	fd4968e3          	bltu	s2,s4,8000165a <uvmalloc+0x2c>
  return newsz;
    8000168e:	8552                	mv	a0,s4
    80001690:	a809                	j	800016a2 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001692:	864e                	mv	a2,s3
    80001694:	85ca                	mv	a1,s2
    80001696:	8556                	mv	a0,s5
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	f4e080e7          	jalr	-178(ra) # 800015e6 <uvmdealloc>
      return 0;
    800016a0:	4501                	li	a0,0
}
    800016a2:	70e2                	ld	ra,56(sp)
    800016a4:	7442                	ld	s0,48(sp)
    800016a6:	74a2                	ld	s1,40(sp)
    800016a8:	7902                	ld	s2,32(sp)
    800016aa:	69e2                	ld	s3,24(sp)
    800016ac:	6a42                	ld	s4,16(sp)
    800016ae:	6aa2                	ld	s5,8(sp)
    800016b0:	6121                	addi	sp,sp,64
    800016b2:	8082                	ret
      kfree(mem);
    800016b4:	8526                	mv	a0,s1
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	36e080e7          	jalr	878(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016be:	864e                	mv	a2,s3
    800016c0:	85ca                	mv	a1,s2
    800016c2:	8556                	mv	a0,s5
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	f22080e7          	jalr	-222(ra) # 800015e6 <uvmdealloc>
      return 0;
    800016cc:	4501                	li	a0,0
    800016ce:	bfd1                	j	800016a2 <uvmalloc+0x74>
    return oldsz;
    800016d0:	852e                	mv	a0,a1
}
    800016d2:	8082                	ret
  return newsz;
    800016d4:	8532                	mv	a0,a2
    800016d6:	b7f1                	j	800016a2 <uvmalloc+0x74>

00000000800016d8 <freewalk>:
{
    800016d8:	7179                	addi	sp,sp,-48
    800016da:	f406                	sd	ra,40(sp)
    800016dc:	f022                	sd	s0,32(sp)
    800016de:	ec26                	sd	s1,24(sp)
    800016e0:	e84a                	sd	s2,16(sp)
    800016e2:	e44e                	sd	s3,8(sp)
    800016e4:	e052                	sd	s4,0(sp)
    800016e6:	1800                	addi	s0,sp,48
    800016e8:	8a2a                	mv	s4,a0
  for(int i = 0; i < 512; i++){
    800016ea:	84aa                	mv	s1,a0
    800016ec:	6905                	lui	s2,0x1
    800016ee:	992a                	add	s2,s2,a0
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016f0:	4985                	li	s3,1
    800016f2:	a821                	j	8000170a <freewalk+0x32>
      uint64 child = PTE2PA(pte);
    800016f4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016f6:	0532                	slli	a0,a0,0xc
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	fe0080e7          	jalr	-32(ra) # 800016d8 <freewalk>
      pagetable[i] = 0;
    80001700:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001704:	04a1                	addi	s1,s1,8
    80001706:	03248163          	beq	s1,s2,80001728 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000170a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000170c:	00f57793          	andi	a5,a0,15
    80001710:	ff3782e3          	beq	a5,s3,800016f4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001714:	8905                	andi	a0,a0,1
    80001716:	d57d                	beqz	a0,80001704 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001718:	00007517          	auipc	a0,0x7
    8000171c:	ac850513          	addi	a0,a0,-1336 # 800081e0 <digits+0x1a0>
    80001720:	fffff097          	auipc	ra,0xfffff
    80001724:	e28080e7          	jalr	-472(ra) # 80000548 <panic>
  kfree((void*)pagetable);
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	2fa080e7          	jalr	762(ra) # 80000a24 <kfree>
}
    80001732:	70a2                	ld	ra,40(sp)
    80001734:	7402                	ld	s0,32(sp)
    80001736:	64e2                	ld	s1,24(sp)
    80001738:	6942                	ld	s2,16(sp)
    8000173a:	69a2                	ld	s3,8(sp)
    8000173c:	6a02                	ld	s4,0(sp)
    8000173e:	6145                	addi	sp,sp,48
    80001740:	8082                	ret

0000000080001742 <uvmfree>:
{
    80001742:	1101                	addi	sp,sp,-32
    80001744:	ec06                	sd	ra,24(sp)
    80001746:	e822                	sd	s0,16(sp)
    80001748:	e426                	sd	s1,8(sp)
    8000174a:	1000                	addi	s0,sp,32
    8000174c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000174e:	e999                	bnez	a1,80001764 <uvmfree+0x22>
  freewalk(pagetable);
    80001750:	8526                	mv	a0,s1
    80001752:	00000097          	auipc	ra,0x0
    80001756:	f86080e7          	jalr	-122(ra) # 800016d8 <freewalk>
}
    8000175a:	60e2                	ld	ra,24(sp)
    8000175c:	6442                	ld	s0,16(sp)
    8000175e:	64a2                	ld	s1,8(sp)
    80001760:	6105                	addi	sp,sp,32
    80001762:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001764:	6605                	lui	a2,0x1
    80001766:	167d                	addi	a2,a2,-1
    80001768:	962e                	add	a2,a2,a1
    8000176a:	4685                	li	a3,1
    8000176c:	8231                	srli	a2,a2,0xc
    8000176e:	4581                	li	a1,0
    80001770:	00000097          	auipc	ra,0x0
    80001774:	d2a080e7          	jalr	-726(ra) # 8000149a <uvmunmap>
    80001778:	bfe1                	j	80001750 <uvmfree+0xe>

000000008000177a <uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){
    8000177a:	ca4d                	beqz	a2,8000182c <uvmcopy+0xb2>
{
    8000177c:	715d                	addi	sp,sp,-80
    8000177e:	e486                	sd	ra,72(sp)
    80001780:	e0a2                	sd	s0,64(sp)
    80001782:	fc26                	sd	s1,56(sp)
    80001784:	f84a                	sd	s2,48(sp)
    80001786:	f44e                	sd	s3,40(sp)
    80001788:	f052                	sd	s4,32(sp)
    8000178a:	ec56                	sd	s5,24(sp)
    8000178c:	e85a                	sd	s6,16(sp)
    8000178e:	e45e                	sd	s7,8(sp)
    80001790:	0880                	addi	s0,sp,80
    80001792:	8aaa                	mv	s5,a0
    80001794:	8b2e                	mv	s6,a1
    80001796:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001798:	4481                	li	s1,0
    8000179a:	a029                	j	800017a4 <uvmcopy+0x2a>
    8000179c:	6785                	lui	a5,0x1
    8000179e:	94be                	add	s1,s1,a5
    800017a0:	0744fa63          	bgeu	s1,s4,80001814 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800017a4:	4601                	li	a2,0
    800017a6:	85a6                	mv	a1,s1
    800017a8:	8556                	mv	a0,s5
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	97e080e7          	jalr	-1666(ra) # 80001128 <walk>
    800017b2:	d56d                	beqz	a0,8000179c <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800017b4:	6118                	ld	a4,0(a0)
    800017b6:	00177793          	andi	a5,a4,1
    800017ba:	d3ed                	beqz	a5,8000179c <uvmcopy+0x22>
    pa = PTE2PA(*pte);
    800017bc:	00a75593          	srli	a1,a4,0xa
    800017c0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017c4:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800017c8:	fffff097          	auipc	ra,0xfffff
    800017cc:	358080e7          	jalr	856(ra) # 80000b20 <kalloc>
    800017d0:	89aa                	mv	s3,a0
    800017d2:	c515                	beqz	a0,800017fe <uvmcopy+0x84>
    memmove(mem, (char*)pa, PGSIZE);
    800017d4:	6605                	lui	a2,0x1
    800017d6:	85de                	mv	a1,s7
    800017d8:	fffff097          	auipc	ra,0xfffff
    800017dc:	594080e7          	jalr	1428(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800017e0:	874a                	mv	a4,s2
    800017e2:	86ce                	mv	a3,s3
    800017e4:	6605                	lui	a2,0x1
    800017e6:	85a6                	mv	a1,s1
    800017e8:	855a                	mv	a0,s6
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	a42080e7          	jalr	-1470(ra) # 8000122c <mappages>
    800017f2:	d54d                	beqz	a0,8000179c <uvmcopy+0x22>
      kfree(mem);
    800017f4:	854e                	mv	a0,s3
    800017f6:	fffff097          	auipc	ra,0xfffff
    800017fa:	22e080e7          	jalr	558(ra) # 80000a24 <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017fe:	4685                	li	a3,1
    80001800:	00c4d613          	srli	a2,s1,0xc
    80001804:	4581                	li	a1,0
    80001806:	855a                	mv	a0,s6
    80001808:	00000097          	auipc	ra,0x0
    8000180c:	c92080e7          	jalr	-878(ra) # 8000149a <uvmunmap>
  return -1;
    80001810:	557d                	li	a0,-1
    80001812:	a011                	j	80001816 <uvmcopy+0x9c>
  return 0;
    80001814:	4501                	li	a0,0
}
    80001816:	60a6                	ld	ra,72(sp)
    80001818:	6406                	ld	s0,64(sp)
    8000181a:	74e2                	ld	s1,56(sp)
    8000181c:	7942                	ld	s2,48(sp)
    8000181e:	79a2                	ld	s3,40(sp)
    80001820:	7a02                	ld	s4,32(sp)
    80001822:	6ae2                	ld	s5,24(sp)
    80001824:	6b42                	ld	s6,16(sp)
    80001826:	6ba2                	ld	s7,8(sp)
    80001828:	6161                	addi	sp,sp,80
    8000182a:	8082                	ret
  return 0;
    8000182c:	4501                	li	a0,0
}
    8000182e:	8082                	ret

0000000080001830 <uvmclear>:
{
    80001830:	1141                	addi	sp,sp,-16
    80001832:	e406                	sd	ra,8(sp)
    80001834:	e022                	sd	s0,0(sp)
    80001836:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001838:	4601                	li	a2,0
    8000183a:	00000097          	auipc	ra,0x0
    8000183e:	8ee080e7          	jalr	-1810(ra) # 80001128 <walk>
  if(pte == 0)
    80001842:	c901                	beqz	a0,80001852 <uvmclear+0x22>
  *pte &= ~PTE_U;
    80001844:	611c                	ld	a5,0(a0)
    80001846:	9bbd                	andi	a5,a5,-17
    80001848:	e11c                	sd	a5,0(a0)
}
    8000184a:	60a2                	ld	ra,8(sp)
    8000184c:	6402                	ld	s0,0(sp)
    8000184e:	0141                	addi	sp,sp,16
    80001850:	8082                	ret
    panic("uvmclear");
    80001852:	00007517          	auipc	a0,0x7
    80001856:	99e50513          	addi	a0,a0,-1634 # 800081f0 <digits+0x1b0>
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	cee080e7          	jalr	-786(ra) # 80000548 <panic>

0000000080001862 <copyout>:
  while(len > 0){
    80001862:	c6bd                	beqz	a3,800018d0 <copyout+0x6e>
{
    80001864:	715d                	addi	sp,sp,-80
    80001866:	e486                	sd	ra,72(sp)
    80001868:	e0a2                	sd	s0,64(sp)
    8000186a:	fc26                	sd	s1,56(sp)
    8000186c:	f84a                	sd	s2,48(sp)
    8000186e:	f44e                	sd	s3,40(sp)
    80001870:	f052                	sd	s4,32(sp)
    80001872:	ec56                	sd	s5,24(sp)
    80001874:	e85a                	sd	s6,16(sp)
    80001876:	e45e                	sd	s7,8(sp)
    80001878:	e062                	sd	s8,0(sp)
    8000187a:	0880                	addi	s0,sp,80
    8000187c:	8b2a                	mv	s6,a0
    8000187e:	8c2e                	mv	s8,a1
    80001880:	8a32                	mv	s4,a2
    80001882:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001884:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (dstva - va0);
    80001886:	6a85                	lui	s5,0x1
    80001888:	a015                	j	800018ac <copyout+0x4a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000188a:	9562                	add	a0,a0,s8
    8000188c:	0004861b          	sext.w	a2,s1
    80001890:	85d2                	mv	a1,s4
    80001892:	41250533          	sub	a0,a0,s2
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	4d6080e7          	jalr	1238(ra) # 80000d6c <memmove>
    len -= n;
    8000189e:	409989b3          	sub	s3,s3,s1
    src += n;
    800018a2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800018a4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018a8:	02098263          	beqz	s3,800018cc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800018ac:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018b0:	85ca                	mv	a1,s2
    800018b2:	855a                	mv	a0,s6
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	a06080e7          	jalr	-1530(ra) # 800012ba <walkaddr>
    if(pa0 == 0)
    800018bc:	cd01                	beqz	a0,800018d4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800018be:	418904b3          	sub	s1,s2,s8
    800018c2:	94d6                	add	s1,s1,s5
    if(n > len)
    800018c4:	fc99f3e3          	bgeu	s3,s1,8000188a <copyout+0x28>
    800018c8:	84ce                	mv	s1,s3
    800018ca:	b7c1                	j	8000188a <copyout+0x28>
  return 0;
    800018cc:	4501                	li	a0,0
    800018ce:	a021                	j	800018d6 <copyout+0x74>
    800018d0:	4501                	li	a0,0
}
    800018d2:	8082                	ret
      return -1;
    800018d4:	557d                	li	a0,-1
}
    800018d6:	60a6                	ld	ra,72(sp)
    800018d8:	6406                	ld	s0,64(sp)
    800018da:	74e2                	ld	s1,56(sp)
    800018dc:	7942                	ld	s2,48(sp)
    800018de:	79a2                	ld	s3,40(sp)
    800018e0:	7a02                	ld	s4,32(sp)
    800018e2:	6ae2                	ld	s5,24(sp)
    800018e4:	6b42                	ld	s6,16(sp)
    800018e6:	6ba2                	ld	s7,8(sp)
    800018e8:	6c02                	ld	s8,0(sp)
    800018ea:	6161                	addi	sp,sp,80
    800018ec:	8082                	ret

00000000800018ee <copyin>:
  while(len > 0){
    800018ee:	c6bd                	beqz	a3,8000195c <copyin+0x6e>
{
    800018f0:	715d                	addi	sp,sp,-80
    800018f2:	e486                	sd	ra,72(sp)
    800018f4:	e0a2                	sd	s0,64(sp)
    800018f6:	fc26                	sd	s1,56(sp)
    800018f8:	f84a                	sd	s2,48(sp)
    800018fa:	f44e                	sd	s3,40(sp)
    800018fc:	f052                	sd	s4,32(sp)
    800018fe:	ec56                	sd	s5,24(sp)
    80001900:	e85a                	sd	s6,16(sp)
    80001902:	e45e                	sd	s7,8(sp)
    80001904:	e062                	sd	s8,0(sp)
    80001906:	0880                	addi	s0,sp,80
    80001908:	8b2a                	mv	s6,a0
    8000190a:	8a2e                	mv	s4,a1
    8000190c:	8c32                	mv	s8,a2
    8000190e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001910:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (srcva - va0);
    80001912:	6a85                	lui	s5,0x1
    80001914:	a015                	j	80001938 <copyin+0x4a>
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001916:	9562                	add	a0,a0,s8
    80001918:	0004861b          	sext.w	a2,s1
    8000191c:	412505b3          	sub	a1,a0,s2
    80001920:	8552                	mv	a0,s4
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	44a080e7          	jalr	1098(ra) # 80000d6c <memmove>
    len -= n;
    8000192a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000192e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001930:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001934:	02098263          	beqz	s3,80001958 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001938:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000193c:	85ca                	mv	a1,s2
    8000193e:	855a                	mv	a0,s6
    80001940:	00000097          	auipc	ra,0x0
    80001944:	97a080e7          	jalr	-1670(ra) # 800012ba <walkaddr>
    if(pa0 == 0)
    80001948:	cd01                	beqz	a0,80001960 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000194a:	418904b3          	sub	s1,s2,s8
    8000194e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001950:	fc99f3e3          	bgeu	s3,s1,80001916 <copyin+0x28>
    80001954:	84ce                	mv	s1,s3
    80001956:	b7c1                	j	80001916 <copyin+0x28>
  return 0;
    80001958:	4501                	li	a0,0
    8000195a:	a021                	j	80001962 <copyin+0x74>
    8000195c:	4501                	li	a0,0
}
    8000195e:	8082                	ret
      return -1;
    80001960:	557d                	li	a0,-1
}
    80001962:	60a6                	ld	ra,72(sp)
    80001964:	6406                	ld	s0,64(sp)
    80001966:	74e2                	ld	s1,56(sp)
    80001968:	7942                	ld	s2,48(sp)
    8000196a:	79a2                	ld	s3,40(sp)
    8000196c:	7a02                	ld	s4,32(sp)
    8000196e:	6ae2                	ld	s5,24(sp)
    80001970:	6b42                	ld	s6,16(sp)
    80001972:	6ba2                	ld	s7,8(sp)
    80001974:	6c02                	ld	s8,0(sp)
    80001976:	6161                	addi	sp,sp,80
    80001978:	8082                	ret

000000008000197a <copyinstr>:
  while(got_null == 0 && max > 0){
    8000197a:	c6c5                	beqz	a3,80001a22 <copyinstr+0xa8>
{
    8000197c:	715d                	addi	sp,sp,-80
    8000197e:	e486                	sd	ra,72(sp)
    80001980:	e0a2                	sd	s0,64(sp)
    80001982:	fc26                	sd	s1,56(sp)
    80001984:	f84a                	sd	s2,48(sp)
    80001986:	f44e                	sd	s3,40(sp)
    80001988:	f052                	sd	s4,32(sp)
    8000198a:	ec56                	sd	s5,24(sp)
    8000198c:	e85a                	sd	s6,16(sp)
    8000198e:	e45e                	sd	s7,8(sp)
    80001990:	0880                	addi	s0,sp,80
    80001992:	8a2a                	mv	s4,a0
    80001994:	8b2e                	mv	s6,a1
    80001996:	8bb2                	mv	s7,a2
    80001998:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000199a:	7afd                	lui	s5,0xfffff
    n = PGSIZE - (srcva - va0);
    8000199c:	6985                	lui	s3,0x1
    8000199e:	a035                	j	800019ca <copyinstr+0x50>
        *dst = '\0';
    800019a0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019a4:	4785                	li	a5,1
  if(got_null){
    800019a6:	0017b793          	seqz	a5,a5
    800019aa:	40f00533          	neg	a0,a5
}
    800019ae:	60a6                	ld	ra,72(sp)
    800019b0:	6406                	ld	s0,64(sp)
    800019b2:	74e2                	ld	s1,56(sp)
    800019b4:	7942                	ld	s2,48(sp)
    800019b6:	79a2                	ld	s3,40(sp)
    800019b8:	7a02                	ld	s4,32(sp)
    800019ba:	6ae2                	ld	s5,24(sp)
    800019bc:	6b42                	ld	s6,16(sp)
    800019be:	6ba2                	ld	s7,8(sp)
    800019c0:	6161                	addi	sp,sp,80
    800019c2:	8082                	ret
    srcva = va0 + PGSIZE;
    800019c4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019c8:	c8a9                	beqz	s1,80001a1a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019ca:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019ce:	85ca                	mv	a1,s2
    800019d0:	8552                	mv	a0,s4
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	8e8080e7          	jalr	-1816(ra) # 800012ba <walkaddr>
    if(pa0 == 0)
    800019da:	c131                	beqz	a0,80001a1e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019dc:	41790833          	sub	a6,s2,s7
    800019e0:	984e                	add	a6,a6,s3
    if(n > max)
    800019e2:	0104f363          	bgeu	s1,a6,800019e8 <copyinstr+0x6e>
    800019e6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019e8:	955e                	add	a0,a0,s7
    800019ea:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019ee:	fc080be3          	beqz	a6,800019c4 <copyinstr+0x4a>
    800019f2:	985a                	add	a6,a6,s6
    800019f4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019f6:	41650633          	sub	a2,a0,s6
    800019fa:	14fd                	addi	s1,s1,-1
    800019fc:	9b26                	add	s6,s6,s1
    800019fe:	00f60733          	add	a4,a2,a5
    80001a02:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001a06:	df49                	beqz	a4,800019a0 <copyinstr+0x26>
        *dst = *p;
    80001a08:	00e78023          	sb	a4,0(a5)
      --max;
    80001a0c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a10:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a12:	ff0796e3          	bne	a5,a6,800019fe <copyinstr+0x84>
      dst++;
    80001a16:	8b42                	mv	s6,a6
    80001a18:	b775                	j	800019c4 <copyinstr+0x4a>
    80001a1a:	4781                	li	a5,0
    80001a1c:	b769                	j	800019a6 <copyinstr+0x2c>
      return -1;
    80001a1e:	557d                	li	a0,-1
    80001a20:	b779                	j	800019ae <copyinstr+0x34>
  int got_null = 0;
    80001a22:	4781                	li	a5,0
  if(got_null){
    80001a24:	0017b793          	seqz	a5,a5
    80001a28:	40f00533          	neg	a0,a5
}
    80001a2c:	8082                	ret

0000000080001a2e <vmprint>:

void vmprint(pagetable_t pagetable)
{
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	1000                	addi	s0,sp,32
    80001a38:	84aa                	mv	s1,a0
  // 打印页表地址
  printf("page table %p\n", pagetable);
    80001a3a:	85aa                	mv	a1,a0
    80001a3c:	00006517          	auipc	a0,0x6
    80001a40:	7c450513          	addi	a0,a0,1988 # 80008200 <digits+0x1c0>
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	b4e080e7          	jalr	-1202(ra) # 80000592 <printf>
  // 递归打印页表内容
  print_recursively(pagetable, 0); 
    80001a4c:	4581                	li	a1,0
    80001a4e:	8526                	mv	a0,s1
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	584080e7          	jalr	1412(ra) # 80000fd4 <print_recursively>
}
    80001a58:	60e2                	ld	ra,24(sp)
    80001a5a:	6442                	ld	s0,16(sp)
    80001a5c:	64a2                	ld	s1,8(sp)
    80001a5e:	6105                	addi	sp,sp,32
    80001a60:	8082                	ret

0000000080001a62 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a62:	1101                	addi	sp,sp,-32
    80001a64:	ec06                	sd	ra,24(sp)
    80001a66:	e822                	sd	s0,16(sp)
    80001a68:	e426                	sd	s1,8(sp)
    80001a6a:	1000                	addi	s0,sp,32
    80001a6c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	128080e7          	jalr	296(ra) # 80000b96 <holding>
    80001a76:	c909                	beqz	a0,80001a88 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a78:	749c                	ld	a5,40(s1)
    80001a7a:	00978f63          	beq	a5,s1,80001a98 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6105                	addi	sp,sp,32
    80001a86:	8082                	ret
    panic("wakeup1");
    80001a88:	00006517          	auipc	a0,0x6
    80001a8c:	78850513          	addi	a0,a0,1928 # 80008210 <digits+0x1d0>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	ab8080e7          	jalr	-1352(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a98:	4c98                	lw	a4,24(s1)
    80001a9a:	4785                	li	a5,1
    80001a9c:	fef711e3          	bne	a4,a5,80001a7e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001aa0:	4789                	li	a5,2
    80001aa2:	cc9c                	sw	a5,24(s1)
}
    80001aa4:	bfe9                	j	80001a7e <wakeup1+0x1c>

0000000080001aa6 <procinit>:
{
    80001aa6:	715d                	addi	sp,sp,-80
    80001aa8:	e486                	sd	ra,72(sp)
    80001aaa:	e0a2                	sd	s0,64(sp)
    80001aac:	fc26                	sd	s1,56(sp)
    80001aae:	f84a                	sd	s2,48(sp)
    80001ab0:	f44e                	sd	s3,40(sp)
    80001ab2:	f052                	sd	s4,32(sp)
    80001ab4:	ec56                	sd	s5,24(sp)
    80001ab6:	e85a                	sd	s6,16(sp)
    80001ab8:	e45e                	sd	s7,8(sp)
    80001aba:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001abc:	00006597          	auipc	a1,0x6
    80001ac0:	75c58593          	addi	a1,a1,1884 # 80008218 <digits+0x1d8>
    80001ac4:	00010517          	auipc	a0,0x10
    80001ac8:	e8c50513          	addi	a0,a0,-372 # 80011950 <pid_lock>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	0b4080e7          	jalr	180(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad4:	00010917          	auipc	s2,0x10
    80001ad8:	29490913          	addi	s2,s2,660 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001adc:	00006b97          	auipc	s7,0x6
    80001ae0:	744b8b93          	addi	s7,s7,1860 # 80008220 <digits+0x1e0>
      uint64 va = KSTACK((int) (p - proc));
    80001ae4:	8b4a                	mv	s6,s2
    80001ae6:	00006a97          	auipc	s5,0x6
    80001aea:	51aa8a93          	addi	s5,s5,1306 # 80008000 <etext>
    80001aee:	040009b7          	lui	s3,0x4000
    80001af2:	19fd                	addi	s3,s3,-1
    80001af4:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001af6:	00016a17          	auipc	s4,0x16
    80001afa:	c72a0a13          	addi	s4,s4,-910 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001afe:	85de                	mv	a1,s7
    80001b00:	854a                	mv	a0,s2
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	07e080e7          	jalr	126(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	016080e7          	jalr	22(ra) # 80000b20 <kalloc>
    80001b12:	85aa                	mv	a1,a0
      if(pa == 0)
    80001b14:	c929                	beqz	a0,80001b66 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001b16:	416904b3          	sub	s1,s2,s6
    80001b1a:	848d                	srai	s1,s1,0x3
    80001b1c:	000ab783          	ld	a5,0(s5)
    80001b20:	02f484b3          	mul	s1,s1,a5
    80001b24:	2485                	addiw	s1,s1,1
    80001b26:	00d4949b          	slliw	s1,s1,0xd
    80001b2a:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b2e:	4699                	li	a3,6
    80001b30:	6605                	lui	a2,0x1
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	85c080e7          	jalr	-1956(ra) # 80001390 <kvmmap>
      p->kstack = va;
    80001b3c:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b40:	16890913          	addi	s2,s2,360
    80001b44:	fb491de3          	bne	s2,s4,80001afe <procinit+0x58>
  kvminithart();
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	5bc080e7          	jalr	1468(ra) # 80001104 <kvminithart>
}
    80001b50:	60a6                	ld	ra,72(sp)
    80001b52:	6406                	ld	s0,64(sp)
    80001b54:	74e2                	ld	s1,56(sp)
    80001b56:	7942                	ld	s2,48(sp)
    80001b58:	79a2                	ld	s3,40(sp)
    80001b5a:	7a02                	ld	s4,32(sp)
    80001b5c:	6ae2                	ld	s5,24(sp)
    80001b5e:	6b42                	ld	s6,16(sp)
    80001b60:	6ba2                	ld	s7,8(sp)
    80001b62:	6161                	addi	sp,sp,80
    80001b64:	8082                	ret
        panic("kalloc");
    80001b66:	00006517          	auipc	a0,0x6
    80001b6a:	6c250513          	addi	a0,a0,1730 # 80008228 <digits+0x1e8>
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	9da080e7          	jalr	-1574(ra) # 80000548 <panic>

0000000080001b76 <cpuid>:
{
    80001b76:	1141                	addi	sp,sp,-16
    80001b78:	e422                	sd	s0,8(sp)
    80001b7a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b7c:	8512                	mv	a0,tp
}
    80001b7e:	2501                	sext.w	a0,a0
    80001b80:	6422                	ld	s0,8(sp)
    80001b82:	0141                	addi	sp,sp,16
    80001b84:	8082                	ret

0000000080001b86 <mycpu>:
mycpu(void) {
    80001b86:	1141                	addi	sp,sp,-16
    80001b88:	e422                	sd	s0,8(sp)
    80001b8a:	0800                	addi	s0,sp,16
    80001b8c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b8e:	2781                	sext.w	a5,a5
    80001b90:	079e                	slli	a5,a5,0x7
}
    80001b92:	00010517          	auipc	a0,0x10
    80001b96:	dd650513          	addi	a0,a0,-554 # 80011968 <cpus>
    80001b9a:	953e                	add	a0,a0,a5
    80001b9c:	6422                	ld	s0,8(sp)
    80001b9e:	0141                	addi	sp,sp,16
    80001ba0:	8082                	ret

0000000080001ba2 <myproc>:
myproc(void) {
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	1000                	addi	s0,sp,32
  push_off();
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	018080e7          	jalr	24(ra) # 80000bc4 <push_off>
    80001bb4:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001bb6:	2781                	sext.w	a5,a5
    80001bb8:	079e                	slli	a5,a5,0x7
    80001bba:	00010717          	auipc	a4,0x10
    80001bbe:	d9670713          	addi	a4,a4,-618 # 80011950 <pid_lock>
    80001bc2:	97ba                	add	a5,a5,a4
    80001bc4:	6f84                	ld	s1,24(a5)
  pop_off();
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	09e080e7          	jalr	158(ra) # 80000c64 <pop_off>
}
    80001bce:	8526                	mv	a0,s1
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <forkret>:
{
    80001bda:	1141                	addi	sp,sp,-16
    80001bdc:	e406                	sd	ra,8(sp)
    80001bde:	e022                	sd	s0,0(sp)
    80001be0:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	fc0080e7          	jalr	-64(ra) # 80001ba2 <myproc>
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	0da080e7          	jalr	218(ra) # 80000cc4 <release>
  if (first) {
    80001bf2:	00007797          	auipc	a5,0x7
    80001bf6:	cee7a783          	lw	a5,-786(a5) # 800088e0 <first.1668>
    80001bfa:	eb89                	bnez	a5,80001c0c <forkret+0x32>
  usertrapret();
    80001bfc:	00001097          	auipc	ra,0x1
    80001c00:	c1c080e7          	jalr	-996(ra) # 80002818 <usertrapret>
}
    80001c04:	60a2                	ld	ra,8(sp)
    80001c06:	6402                	ld	s0,0(sp)
    80001c08:	0141                	addi	sp,sp,16
    80001c0a:	8082                	ret
    first = 0;
    80001c0c:	00007797          	auipc	a5,0x7
    80001c10:	cc07aa23          	sw	zero,-812(a5) # 800088e0 <first.1668>
    fsinit(ROOTDEV);
    80001c14:	4505                	li	a0,1
    80001c16:	00002097          	auipc	ra,0x2
    80001c1a:	a0e080e7          	jalr	-1522(ra) # 80003624 <fsinit>
    80001c1e:	bff9                	j	80001bfc <forkret+0x22>

0000000080001c20 <allocpid>:
allocpid() {
    80001c20:	1101                	addi	sp,sp,-32
    80001c22:	ec06                	sd	ra,24(sp)
    80001c24:	e822                	sd	s0,16(sp)
    80001c26:	e426                	sd	s1,8(sp)
    80001c28:	e04a                	sd	s2,0(sp)
    80001c2a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c2c:	00010917          	auipc	s2,0x10
    80001c30:	d2490913          	addi	s2,s2,-732 # 80011950 <pid_lock>
    80001c34:	854a                	mv	a0,s2
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	fda080e7          	jalr	-38(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001c3e:	00007797          	auipc	a5,0x7
    80001c42:	ca678793          	addi	a5,a5,-858 # 800088e4 <nextpid>
    80001c46:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c48:	0014871b          	addiw	a4,s1,1
    80001c4c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c4e:	854a                	mv	a0,s2
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	074080e7          	jalr	116(ra) # 80000cc4 <release>
}
    80001c58:	8526                	mv	a0,s1
    80001c5a:	60e2                	ld	ra,24(sp)
    80001c5c:	6442                	ld	s0,16(sp)
    80001c5e:	64a2                	ld	s1,8(sp)
    80001c60:	6902                	ld	s2,0(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret

0000000080001c66 <proc_pagetable>:
{
    80001c66:	1101                	addi	sp,sp,-32
    80001c68:	ec06                	sd	ra,24(sp)
    80001c6a:	e822                	sd	s0,16(sp)
    80001c6c:	e426                	sd	s1,8(sp)
    80001c6e:	e04a                	sd	s2,0(sp)
    80001c70:	1000                	addi	s0,sp,32
    80001c72:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	8d2080e7          	jalr	-1838(ra) # 80001546 <uvmcreate>
    80001c7c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c7e:	c121                	beqz	a0,80001cbe <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c80:	4729                	li	a4,10
    80001c82:	00005697          	auipc	a3,0x5
    80001c86:	37e68693          	addi	a3,a3,894 # 80007000 <_trampoline>
    80001c8a:	6605                	lui	a2,0x1
    80001c8c:	040005b7          	lui	a1,0x4000
    80001c90:	15fd                	addi	a1,a1,-1
    80001c92:	05b2                	slli	a1,a1,0xc
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	598080e7          	jalr	1432(ra) # 8000122c <mappages>
    80001c9c:	02054863          	bltz	a0,80001ccc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ca0:	4719                	li	a4,6
    80001ca2:	05893683          	ld	a3,88(s2)
    80001ca6:	6605                	lui	a2,0x1
    80001ca8:	020005b7          	lui	a1,0x2000
    80001cac:	15fd                	addi	a1,a1,-1
    80001cae:	05b6                	slli	a1,a1,0xd
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	57a080e7          	jalr	1402(ra) # 8000122c <mappages>
    80001cba:	02054163          	bltz	a0,80001cdc <proc_pagetable+0x76>
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret
    uvmfree(pagetable, 0);
    80001ccc:	4581                	li	a1,0
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	a72080e7          	jalr	-1422(ra) # 80001742 <uvmfree>
    return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	b7d5                	j	80001cbe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cdc:	4681                	li	a3,0
    80001cde:	4605                	li	a2,1
    80001ce0:	040005b7          	lui	a1,0x4000
    80001ce4:	15fd                	addi	a1,a1,-1
    80001ce6:	05b2                	slli	a1,a1,0xc
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	7b0080e7          	jalr	1968(ra) # 8000149a <uvmunmap>
    uvmfree(pagetable, 0);
    80001cf2:	4581                	li	a1,0
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	a4c080e7          	jalr	-1460(ra) # 80001742 <uvmfree>
    return 0;
    80001cfe:	4481                	li	s1,0
    80001d00:	bf7d                	j	80001cbe <proc_pagetable+0x58>

0000000080001d02 <proc_freepagetable>:
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	e04a                	sd	s2,0(sp)
    80001d0c:	1000                	addi	s0,sp,32
    80001d0e:	84aa                	mv	s1,a0
    80001d10:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d12:	4681                	li	a3,0
    80001d14:	4605                	li	a2,1
    80001d16:	040005b7          	lui	a1,0x4000
    80001d1a:	15fd                	addi	a1,a1,-1
    80001d1c:	05b2                	slli	a1,a1,0xc
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	77c080e7          	jalr	1916(ra) # 8000149a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d26:	4681                	li	a3,0
    80001d28:	4605                	li	a2,1
    80001d2a:	020005b7          	lui	a1,0x2000
    80001d2e:	15fd                	addi	a1,a1,-1
    80001d30:	05b6                	slli	a1,a1,0xd
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	766080e7          	jalr	1894(ra) # 8000149a <uvmunmap>
  uvmfree(pagetable, sz);
    80001d3c:	85ca                	mv	a1,s2
    80001d3e:	8526                	mv	a0,s1
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	a02080e7          	jalr	-1534(ra) # 80001742 <uvmfree>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret

0000000080001d54 <freeproc>:
{
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d60:	6d28                	ld	a0,88(a0)
    80001d62:	c509                	beqz	a0,80001d6c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	cc0080e7          	jalr	-832(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001d6c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d70:	68a8                	ld	a0,80(s1)
    80001d72:	c511                	beqz	a0,80001d7e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d74:	64ac                	ld	a1,72(s1)
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	f8c080e7          	jalr	-116(ra) # 80001d02 <proc_freepagetable>
  p->pagetable = 0;
    80001d7e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d82:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d86:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d8a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d8e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d92:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d96:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d9a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d9e:	0004ac23          	sw	zero,24(s1)
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <allocproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db8:	00010497          	auipc	s1,0x10
    80001dbc:	fb048493          	addi	s1,s1,-80 # 80011d68 <proc>
    80001dc0:	00016917          	auipc	s2,0x16
    80001dc4:	9a890913          	addi	s2,s2,-1624 # 80017768 <tickslock>
    acquire(&p->lock);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	e46080e7          	jalr	-442(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001dd2:	4c9c                	lw	a5,24(s1)
    80001dd4:	cf81                	beqz	a5,80001dec <allocproc+0x40>
      release(&p->lock);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	eec080e7          	jalr	-276(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de0:	16848493          	addi	s1,s1,360
    80001de4:	ff2492e3          	bne	s1,s2,80001dc8 <allocproc+0x1c>
  return 0;
    80001de8:	4481                	li	s1,0
    80001dea:	a0b9                	j	80001e38 <allocproc+0x8c>
  p->pid = allocpid();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	e34080e7          	jalr	-460(ra) # 80001c20 <allocpid>
    80001df4:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	d2a080e7          	jalr	-726(ra) # 80000b20 <kalloc>
    80001dfe:	892a                	mv	s2,a0
    80001e00:	eca8                	sd	a0,88(s1)
    80001e02:	c131                	beqz	a0,80001e46 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001e04:	8526                	mv	a0,s1
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	e60080e7          	jalr	-416(ra) # 80001c66 <proc_pagetable>
    80001e0e:	892a                	mv	s2,a0
    80001e10:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e12:	c129                	beqz	a0,80001e54 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001e14:	07000613          	li	a2,112
    80001e18:	4581                	li	a1,0
    80001e1a:	06048513          	addi	a0,s1,96
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	eee080e7          	jalr	-274(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001e26:	00000797          	auipc	a5,0x0
    80001e2a:	db478793          	addi	a5,a5,-588 # 80001bda <forkret>
    80001e2e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e30:	60bc                	ld	a5,64(s1)
    80001e32:	6705                	lui	a4,0x1
    80001e34:	97ba                	add	a5,a5,a4
    80001e36:	f4bc                	sd	a5,104(s1)
}
    80001e38:	8526                	mv	a0,s1
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
    release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e7c080e7          	jalr	-388(ra) # 80000cc4 <release>
    return 0;
    80001e50:	84ca                	mv	s1,s2
    80001e52:	b7dd                	j	80001e38 <allocproc+0x8c>
    freeproc(p);
    80001e54:	8526                	mv	a0,s1
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	efe080e7          	jalr	-258(ra) # 80001d54 <freeproc>
    release(&p->lock);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e64080e7          	jalr	-412(ra) # 80000cc4 <release>
    return 0;
    80001e68:	84ca                	mv	s1,s2
    80001e6a:	b7f9                	j	80001e38 <allocproc+0x8c>

0000000080001e6c <userinit>:
{
    80001e6c:	1101                	addi	sp,sp,-32
    80001e6e:	ec06                	sd	ra,24(sp)
    80001e70:	e822                	sd	s0,16(sp)
    80001e72:	e426                	sd	s1,8(sp)
    80001e74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	f36080e7          	jalr	-202(ra) # 80001dac <allocproc>
    80001e7e:	84aa                	mv	s1,a0
  initproc = p;
    80001e80:	00007797          	auipc	a5,0x7
    80001e84:	18a7bc23          	sd	a0,408(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e88:	03400613          	li	a2,52
    80001e8c:	00007597          	auipc	a1,0x7
    80001e90:	a6458593          	addi	a1,a1,-1436 # 800088f0 <initcode>
    80001e94:	6928                	ld	a0,80(a0)
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	6de080e7          	jalr	1758(ra) # 80001574 <uvminit>
  p->sz = PGSIZE;
    80001e9e:	6785                	lui	a5,0x1
    80001ea0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ea2:	6cb8                	ld	a4,88(s1)
    80001ea4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ea8:	6cb8                	ld	a4,88(s1)
    80001eaa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eac:	4641                	li	a2,16
    80001eae:	00006597          	auipc	a1,0x6
    80001eb2:	38258593          	addi	a1,a1,898 # 80008230 <digits+0x1f0>
    80001eb6:	15848513          	addi	a0,s1,344
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	fa8080e7          	jalr	-88(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001ec2:	00006517          	auipc	a0,0x6
    80001ec6:	37e50513          	addi	a0,a0,894 # 80008240 <digits+0x200>
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	186080e7          	jalr	390(ra) # 80004050 <namei>
    80001ed2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ed6:	4789                	li	a5,2
    80001ed8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001eda:	8526                	mv	a0,s1
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	de8080e7          	jalr	-536(ra) # 80000cc4 <release>
}
    80001ee4:	60e2                	ld	ra,24(sp)
    80001ee6:	6442                	ld	s0,16(sp)
    80001ee8:	64a2                	ld	s1,8(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret

0000000080001eee <growproc>:
{
    80001eee:	1101                	addi	sp,sp,-32
    80001ef0:	ec06                	sd	ra,24(sp)
    80001ef2:	e822                	sd	s0,16(sp)
    80001ef4:	e426                	sd	s1,8(sp)
    80001ef6:	e04a                	sd	s2,0(sp)
    80001ef8:	1000                	addi	s0,sp,32
    80001efa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	ca6080e7          	jalr	-858(ra) # 80001ba2 <myproc>
    80001f04:	892a                	mv	s2,a0
  sz = p->sz;
    80001f06:	652c                	ld	a1,72(a0)
    80001f08:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f0c:	00904f63          	bgtz	s1,80001f2a <growproc+0x3c>
  } else if(n < 0){
    80001f10:	0204cc63          	bltz	s1,80001f48 <growproc+0x5a>
  p->sz = sz;
    80001f14:	1602                	slli	a2,a2,0x20
    80001f16:	9201                	srli	a2,a2,0x20
    80001f18:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f1c:	4501                	li	a0,0
}
    80001f1e:	60e2                	ld	ra,24(sp)
    80001f20:	6442                	ld	s0,16(sp)
    80001f22:	64a2                	ld	s1,8(sp)
    80001f24:	6902                	ld	s2,0(sp)
    80001f26:	6105                	addi	sp,sp,32
    80001f28:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f2a:	9e25                	addw	a2,a2,s1
    80001f2c:	1602                	slli	a2,a2,0x20
    80001f2e:	9201                	srli	a2,a2,0x20
    80001f30:	1582                	slli	a1,a1,0x20
    80001f32:	9181                	srli	a1,a1,0x20
    80001f34:	6928                	ld	a0,80(a0)
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	6f8080e7          	jalr	1784(ra) # 8000162e <uvmalloc>
    80001f3e:	0005061b          	sext.w	a2,a0
    80001f42:	fa69                	bnez	a2,80001f14 <growproc+0x26>
      return -1;
    80001f44:	557d                	li	a0,-1
    80001f46:	bfe1                	j	80001f1e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f48:	9e25                	addw	a2,a2,s1
    80001f4a:	1602                	slli	a2,a2,0x20
    80001f4c:	9201                	srli	a2,a2,0x20
    80001f4e:	1582                	slli	a1,a1,0x20
    80001f50:	9181                	srli	a1,a1,0x20
    80001f52:	6928                	ld	a0,80(a0)
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	692080e7          	jalr	1682(ra) # 800015e6 <uvmdealloc>
    80001f5c:	0005061b          	sext.w	a2,a0
    80001f60:	bf55                	j	80001f14 <growproc+0x26>

0000000080001f62 <fork>:
{
    80001f62:	7179                	addi	sp,sp,-48
    80001f64:	f406                	sd	ra,40(sp)
    80001f66:	f022                	sd	s0,32(sp)
    80001f68:	ec26                	sd	s1,24(sp)
    80001f6a:	e84a                	sd	s2,16(sp)
    80001f6c:	e44e                	sd	s3,8(sp)
    80001f6e:	e052                	sd	s4,0(sp)
    80001f70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	c30080e7          	jalr	-976(ra) # 80001ba2 <myproc>
    80001f7a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f7c:	00000097          	auipc	ra,0x0
    80001f80:	e30080e7          	jalr	-464(ra) # 80001dac <allocproc>
    80001f84:	c175                	beqz	a0,80002068 <fork+0x106>
    80001f86:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f88:	04893603          	ld	a2,72(s2)
    80001f8c:	692c                	ld	a1,80(a0)
    80001f8e:	05093503          	ld	a0,80(s2)
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	7e8080e7          	jalr	2024(ra) # 8000177a <uvmcopy>
    80001f9a:	04054863          	bltz	a0,80001fea <fork+0x88>
  np->sz = p->sz;
    80001f9e:	04893783          	ld	a5,72(s2)
    80001fa2:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001fa6:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001faa:	05893683          	ld	a3,88(s2)
    80001fae:	87b6                	mv	a5,a3
    80001fb0:	0589b703          	ld	a4,88(s3)
    80001fb4:	12068693          	addi	a3,a3,288
    80001fb8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fbc:	6788                	ld	a0,8(a5)
    80001fbe:	6b8c                	ld	a1,16(a5)
    80001fc0:	6f90                	ld	a2,24(a5)
    80001fc2:	01073023          	sd	a6,0(a4)
    80001fc6:	e708                	sd	a0,8(a4)
    80001fc8:	eb0c                	sd	a1,16(a4)
    80001fca:	ef10                	sd	a2,24(a4)
    80001fcc:	02078793          	addi	a5,a5,32
    80001fd0:	02070713          	addi	a4,a4,32
    80001fd4:	fed792e3          	bne	a5,a3,80001fb8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fd8:	0589b783          	ld	a5,88(s3)
    80001fdc:	0607b823          	sd	zero,112(a5)
    80001fe0:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fe4:	15000a13          	li	s4,336
    80001fe8:	a03d                	j	80002016 <fork+0xb4>
    freeproc(np);
    80001fea:	854e                	mv	a0,s3
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	d68080e7          	jalr	-664(ra) # 80001d54 <freeproc>
    release(&np->lock);
    80001ff4:	854e                	mv	a0,s3
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	cce080e7          	jalr	-818(ra) # 80000cc4 <release>
    return -1;
    80001ffe:	54fd                	li	s1,-1
    80002000:	a899                	j	80002056 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002002:	00002097          	auipc	ra,0x2
    80002006:	6da080e7          	jalr	1754(ra) # 800046dc <filedup>
    8000200a:	009987b3          	add	a5,s3,s1
    8000200e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002010:	04a1                	addi	s1,s1,8
    80002012:	01448763          	beq	s1,s4,80002020 <fork+0xbe>
    if(p->ofile[i])
    80002016:	009907b3          	add	a5,s2,s1
    8000201a:	6388                	ld	a0,0(a5)
    8000201c:	f17d                	bnez	a0,80002002 <fork+0xa0>
    8000201e:	bfcd                	j	80002010 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002020:	15093503          	ld	a0,336(s2)
    80002024:	00002097          	auipc	ra,0x2
    80002028:	83a080e7          	jalr	-1990(ra) # 8000385e <idup>
    8000202c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002030:	4641                	li	a2,16
    80002032:	15890593          	addi	a1,s2,344
    80002036:	15898513          	addi	a0,s3,344
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	e28080e7          	jalr	-472(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80002042:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002046:	4789                	li	a5,2
    80002048:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000204c:	854e                	mv	a0,s3
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c76080e7          	jalr	-906(ra) # 80000cc4 <release>
}
    80002056:	8526                	mv	a0,s1
    80002058:	70a2                	ld	ra,40(sp)
    8000205a:	7402                	ld	s0,32(sp)
    8000205c:	64e2                	ld	s1,24(sp)
    8000205e:	6942                	ld	s2,16(sp)
    80002060:	69a2                	ld	s3,8(sp)
    80002062:	6a02                	ld	s4,0(sp)
    80002064:	6145                	addi	sp,sp,48
    80002066:	8082                	ret
    return -1;
    80002068:	54fd                	li	s1,-1
    8000206a:	b7f5                	j	80002056 <fork+0xf4>

000000008000206c <reparent>:
{
    8000206c:	7179                	addi	sp,sp,-48
    8000206e:	f406                	sd	ra,40(sp)
    80002070:	f022                	sd	s0,32(sp)
    80002072:	ec26                	sd	s1,24(sp)
    80002074:	e84a                	sd	s2,16(sp)
    80002076:	e44e                	sd	s3,8(sp)
    80002078:	e052                	sd	s4,0(sp)
    8000207a:	1800                	addi	s0,sp,48
    8000207c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000207e:	00010497          	auipc	s1,0x10
    80002082:	cea48493          	addi	s1,s1,-790 # 80011d68 <proc>
      pp->parent = initproc;
    80002086:	00007a17          	auipc	s4,0x7
    8000208a:	f92a0a13          	addi	s4,s4,-110 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000208e:	00015997          	auipc	s3,0x15
    80002092:	6da98993          	addi	s3,s3,1754 # 80017768 <tickslock>
    80002096:	a029                	j	800020a0 <reparent+0x34>
    80002098:	16848493          	addi	s1,s1,360
    8000209c:	03348363          	beq	s1,s3,800020c2 <reparent+0x56>
    if(pp->parent == p){
    800020a0:	709c                	ld	a5,32(s1)
    800020a2:	ff279be3          	bne	a5,s2,80002098 <reparent+0x2c>
      acquire(&pp->lock);
    800020a6:	8526                	mv	a0,s1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b68080e7          	jalr	-1176(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    800020b0:	000a3783          	ld	a5,0(s4)
    800020b4:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	c0c080e7          	jalr	-1012(ra) # 80000cc4 <release>
    800020c0:	bfe1                	j	80002098 <reparent+0x2c>
}
    800020c2:	70a2                	ld	ra,40(sp)
    800020c4:	7402                	ld	s0,32(sp)
    800020c6:	64e2                	ld	s1,24(sp)
    800020c8:	6942                	ld	s2,16(sp)
    800020ca:	69a2                	ld	s3,8(sp)
    800020cc:	6a02                	ld	s4,0(sp)
    800020ce:	6145                	addi	sp,sp,48
    800020d0:	8082                	ret

00000000800020d2 <scheduler>:
{
    800020d2:	711d                	addi	sp,sp,-96
    800020d4:	ec86                	sd	ra,88(sp)
    800020d6:	e8a2                	sd	s0,80(sp)
    800020d8:	e4a6                	sd	s1,72(sp)
    800020da:	e0ca                	sd	s2,64(sp)
    800020dc:	fc4e                	sd	s3,56(sp)
    800020de:	f852                	sd	s4,48(sp)
    800020e0:	f456                	sd	s5,40(sp)
    800020e2:	f05a                	sd	s6,32(sp)
    800020e4:	ec5e                	sd	s7,24(sp)
    800020e6:	e862                	sd	s8,16(sp)
    800020e8:	e466                	sd	s9,8(sp)
    800020ea:	1080                	addi	s0,sp,96
    800020ec:	8792                	mv	a5,tp
  int id = r_tp();
    800020ee:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020f0:	00779c13          	slli	s8,a5,0x7
    800020f4:	00010717          	auipc	a4,0x10
    800020f8:	85c70713          	addi	a4,a4,-1956 # 80011950 <pid_lock>
    800020fc:	9762                	add	a4,a4,s8
    800020fe:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002102:	00010717          	auipc	a4,0x10
    80002106:	86e70713          	addi	a4,a4,-1938 # 80011970 <cpus+0x8>
    8000210a:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    8000210c:	4a89                	li	s5,2
        c->proc = p;
    8000210e:	079e                	slli	a5,a5,0x7
    80002110:	00010b17          	auipc	s6,0x10
    80002114:	840b0b13          	addi	s6,s6,-1984 # 80011950 <pid_lock>
    80002118:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000211a:	00015a17          	auipc	s4,0x15
    8000211e:	64ea0a13          	addi	s4,s4,1614 # 80017768 <tickslock>
    int nproc = 0;
    80002122:	4c81                	li	s9,0
    80002124:	a8a1                	j	8000217c <scheduler+0xaa>
        p->state = RUNNING;
    80002126:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    8000212a:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000212e:	06048593          	addi	a1,s1,96
    80002132:	8562                	mv	a0,s8
    80002134:	00000097          	auipc	ra,0x0
    80002138:	63a080e7          	jalr	1594(ra) # 8000276e <swtch>
        c->proc = 0;
    8000213c:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002140:	8526                	mv	a0,s1
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b82080e7          	jalr	-1150(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000214a:	16848493          	addi	s1,s1,360
    8000214e:	01448d63          	beq	s1,s4,80002168 <scheduler+0x96>
      acquire(&p->lock);
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	abc080e7          	jalr	-1348(ra) # 80000c10 <acquire>
      if(p->state != UNUSED) {
    8000215c:	4c9c                	lw	a5,24(s1)
    8000215e:	d3ed                	beqz	a5,80002140 <scheduler+0x6e>
        nproc++;
    80002160:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002162:	fd579fe3          	bne	a5,s5,80002140 <scheduler+0x6e>
    80002166:	b7c1                	j	80002126 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002168:	013aca63          	blt	s5,s3,8000217c <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002170:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002174:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002178:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000217c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002180:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002184:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002188:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    8000218a:	00010497          	auipc	s1,0x10
    8000218e:	bde48493          	addi	s1,s1,-1058 # 80011d68 <proc>
        p->state = RUNNING;
    80002192:	4b8d                	li	s7,3
    80002194:	bf7d                	j	80002152 <scheduler+0x80>

0000000080002196 <sched>:
{
    80002196:	7179                	addi	sp,sp,-48
    80002198:	f406                	sd	ra,40(sp)
    8000219a:	f022                	sd	s0,32(sp)
    8000219c:	ec26                	sd	s1,24(sp)
    8000219e:	e84a                	sd	s2,16(sp)
    800021a0:	e44e                	sd	s3,8(sp)
    800021a2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	9fe080e7          	jalr	-1538(ra) # 80001ba2 <myproc>
    800021ac:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	9e8080e7          	jalr	-1560(ra) # 80000b96 <holding>
    800021b6:	c93d                	beqz	a0,8000222c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021ba:	2781                	sext.w	a5,a5
    800021bc:	079e                	slli	a5,a5,0x7
    800021be:	0000f717          	auipc	a4,0xf
    800021c2:	79270713          	addi	a4,a4,1938 # 80011950 <pid_lock>
    800021c6:	97ba                	add	a5,a5,a4
    800021c8:	0907a703          	lw	a4,144(a5)
    800021cc:	4785                	li	a5,1
    800021ce:	06f71763          	bne	a4,a5,8000223c <sched+0xa6>
  if(p->state == RUNNING)
    800021d2:	4c98                	lw	a4,24(s1)
    800021d4:	478d                	li	a5,3
    800021d6:	06f70b63          	beq	a4,a5,8000224c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021da:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021de:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021e0:	efb5                	bnez	a5,8000225c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021e2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021e4:	0000f917          	auipc	s2,0xf
    800021e8:	76c90913          	addi	s2,s2,1900 # 80011950 <pid_lock>
    800021ec:	2781                	sext.w	a5,a5
    800021ee:	079e                	slli	a5,a5,0x7
    800021f0:	97ca                	add	a5,a5,s2
    800021f2:	0947a983          	lw	s3,148(a5)
    800021f6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021f8:	2781                	sext.w	a5,a5
    800021fa:	079e                	slli	a5,a5,0x7
    800021fc:	0000f597          	auipc	a1,0xf
    80002200:	77458593          	addi	a1,a1,1908 # 80011970 <cpus+0x8>
    80002204:	95be                	add	a1,a1,a5
    80002206:	06048513          	addi	a0,s1,96
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	564080e7          	jalr	1380(ra) # 8000276e <swtch>
    80002212:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002214:	2781                	sext.w	a5,a5
    80002216:	079e                	slli	a5,a5,0x7
    80002218:	97ca                	add	a5,a5,s2
    8000221a:	0937aa23          	sw	s3,148(a5)
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6145                	addi	sp,sp,48
    8000222a:	8082                	ret
    panic("sched p->lock");
    8000222c:	00006517          	auipc	a0,0x6
    80002230:	01c50513          	addi	a0,a0,28 # 80008248 <digits+0x208>
    80002234:	ffffe097          	auipc	ra,0xffffe
    80002238:	314080e7          	jalr	788(ra) # 80000548 <panic>
    panic("sched locks");
    8000223c:	00006517          	auipc	a0,0x6
    80002240:	01c50513          	addi	a0,a0,28 # 80008258 <digits+0x218>
    80002244:	ffffe097          	auipc	ra,0xffffe
    80002248:	304080e7          	jalr	772(ra) # 80000548 <panic>
    panic("sched running");
    8000224c:	00006517          	auipc	a0,0x6
    80002250:	01c50513          	addi	a0,a0,28 # 80008268 <digits+0x228>
    80002254:	ffffe097          	auipc	ra,0xffffe
    80002258:	2f4080e7          	jalr	756(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000225c:	00006517          	auipc	a0,0x6
    80002260:	01c50513          	addi	a0,a0,28 # 80008278 <digits+0x238>
    80002264:	ffffe097          	auipc	ra,0xffffe
    80002268:	2e4080e7          	jalr	740(ra) # 80000548 <panic>

000000008000226c <exit>:
{
    8000226c:	7179                	addi	sp,sp,-48
    8000226e:	f406                	sd	ra,40(sp)
    80002270:	f022                	sd	s0,32(sp)
    80002272:	ec26                	sd	s1,24(sp)
    80002274:	e84a                	sd	s2,16(sp)
    80002276:	e44e                	sd	s3,8(sp)
    80002278:	e052                	sd	s4,0(sp)
    8000227a:	1800                	addi	s0,sp,48
    8000227c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000227e:	00000097          	auipc	ra,0x0
    80002282:	924080e7          	jalr	-1756(ra) # 80001ba2 <myproc>
    80002286:	89aa                	mv	s3,a0
  if(p == initproc)
    80002288:	00007797          	auipc	a5,0x7
    8000228c:	d907b783          	ld	a5,-624(a5) # 80009018 <initproc>
    80002290:	0d050493          	addi	s1,a0,208
    80002294:	15050913          	addi	s2,a0,336
    80002298:	02a79363          	bne	a5,a0,800022be <exit+0x52>
    panic("init exiting");
    8000229c:	00006517          	auipc	a0,0x6
    800022a0:	ff450513          	addi	a0,a0,-12 # 80008290 <digits+0x250>
    800022a4:	ffffe097          	auipc	ra,0xffffe
    800022a8:	2a4080e7          	jalr	676(ra) # 80000548 <panic>
      fileclose(f);
    800022ac:	00002097          	auipc	ra,0x2
    800022b0:	482080e7          	jalr	1154(ra) # 8000472e <fileclose>
      p->ofile[fd] = 0;
    800022b4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022b8:	04a1                	addi	s1,s1,8
    800022ba:	01248563          	beq	s1,s2,800022c4 <exit+0x58>
    if(p->ofile[fd]){
    800022be:	6088                	ld	a0,0(s1)
    800022c0:	f575                	bnez	a0,800022ac <exit+0x40>
    800022c2:	bfdd                	j	800022b8 <exit+0x4c>
  begin_op();
    800022c4:	00002097          	auipc	ra,0x2
    800022c8:	f98080e7          	jalr	-104(ra) # 8000425c <begin_op>
  iput(p->cwd);
    800022cc:	1509b503          	ld	a0,336(s3)
    800022d0:	00001097          	auipc	ra,0x1
    800022d4:	786080e7          	jalr	1926(ra) # 80003a56 <iput>
  end_op();
    800022d8:	00002097          	auipc	ra,0x2
    800022dc:	004080e7          	jalr	4(ra) # 800042dc <end_op>
  p->cwd = 0;
    800022e0:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800022e4:	00007497          	auipc	s1,0x7
    800022e8:	d3448493          	addi	s1,s1,-716 # 80009018 <initproc>
    800022ec:	6088                	ld	a0,0(s1)
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	922080e7          	jalr	-1758(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    800022f6:	6088                	ld	a0,0(s1)
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	76a080e7          	jalr	1898(ra) # 80001a62 <wakeup1>
  release(&initproc->lock);
    80002300:	6088                	ld	a0,0(s1)
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	9c2080e7          	jalr	-1598(ra) # 80000cc4 <release>
  acquire(&p->lock);
    8000230a:	854e                	mv	a0,s3
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	904080e7          	jalr	-1788(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002314:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002318:	854e                	mv	a0,s3
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	9aa080e7          	jalr	-1622(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8ec080e7          	jalr	-1812(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    8000232c:	854e                	mv	a0,s3
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8e2080e7          	jalr	-1822(ra) # 80000c10 <acquire>
  reparent(p);
    80002336:	854e                	mv	a0,s3
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	d34080e7          	jalr	-716(ra) # 8000206c <reparent>
  wakeup1(original_parent);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	720080e7          	jalr	1824(ra) # 80001a62 <wakeup1>
  p->xstate = status;
    8000234a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000234e:	4791                	li	a5,4
    80002350:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	96e080e7          	jalr	-1682(ra) # 80000cc4 <release>
  sched();
    8000235e:	00000097          	auipc	ra,0x0
    80002362:	e38080e7          	jalr	-456(ra) # 80002196 <sched>
  panic("zombie exit");
    80002366:	00006517          	auipc	a0,0x6
    8000236a:	f3a50513          	addi	a0,a0,-198 # 800082a0 <digits+0x260>
    8000236e:	ffffe097          	auipc	ra,0xffffe
    80002372:	1da080e7          	jalr	474(ra) # 80000548 <panic>

0000000080002376 <yield>:
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002380:	00000097          	auipc	ra,0x0
    80002384:	822080e7          	jalr	-2014(ra) # 80001ba2 <myproc>
    80002388:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	886080e7          	jalr	-1914(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    80002392:	4789                	li	a5,2
    80002394:	cc9c                	sw	a5,24(s1)
  sched();
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	e00080e7          	jalr	-512(ra) # 80002196 <sched>
  release(&p->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	924080e7          	jalr	-1756(ra) # 80000cc4 <release>
}
    800023a8:	60e2                	ld	ra,24(sp)
    800023aa:	6442                	ld	s0,16(sp)
    800023ac:	64a2                	ld	s1,8(sp)
    800023ae:	6105                	addi	sp,sp,32
    800023b0:	8082                	ret

00000000800023b2 <sleep>:
{
    800023b2:	7179                	addi	sp,sp,-48
    800023b4:	f406                	sd	ra,40(sp)
    800023b6:	f022                	sd	s0,32(sp)
    800023b8:	ec26                	sd	s1,24(sp)
    800023ba:	e84a                	sd	s2,16(sp)
    800023bc:	e44e                	sd	s3,8(sp)
    800023be:	1800                	addi	s0,sp,48
    800023c0:	89aa                	mv	s3,a0
    800023c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	7de080e7          	jalr	2014(ra) # 80001ba2 <myproc>
    800023cc:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800023ce:	05250663          	beq	a0,s2,8000241a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	83e080e7          	jalr	-1986(ra) # 80000c10 <acquire>
    release(lk);
    800023da:	854a                	mv	a0,s2
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8e8080e7          	jalr	-1816(ra) # 80000cc4 <release>
  p->chan = chan;
    800023e4:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800023e8:	4785                	li	a5,1
    800023ea:	cc9c                	sw	a5,24(s1)
  sched();
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	daa080e7          	jalr	-598(ra) # 80002196 <sched>
  p->chan = 0;
    800023f4:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	8ca080e7          	jalr	-1846(ra) # 80000cc4 <release>
    acquire(lk);
    80002402:	854a                	mv	a0,s2
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	80c080e7          	jalr	-2036(ra) # 80000c10 <acquire>
}
    8000240c:	70a2                	ld	ra,40(sp)
    8000240e:	7402                	ld	s0,32(sp)
    80002410:	64e2                	ld	s1,24(sp)
    80002412:	6942                	ld	s2,16(sp)
    80002414:	69a2                	ld	s3,8(sp)
    80002416:	6145                	addi	sp,sp,48
    80002418:	8082                	ret
  p->chan = chan;
    8000241a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000241e:	4785                	li	a5,1
    80002420:	cd1c                	sw	a5,24(a0)
  sched();
    80002422:	00000097          	auipc	ra,0x0
    80002426:	d74080e7          	jalr	-652(ra) # 80002196 <sched>
  p->chan = 0;
    8000242a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000242e:	bff9                	j	8000240c <sleep+0x5a>

0000000080002430 <wait>:
{
    80002430:	715d                	addi	sp,sp,-80
    80002432:	e486                	sd	ra,72(sp)
    80002434:	e0a2                	sd	s0,64(sp)
    80002436:	fc26                	sd	s1,56(sp)
    80002438:	f84a                	sd	s2,48(sp)
    8000243a:	f44e                	sd	s3,40(sp)
    8000243c:	f052                	sd	s4,32(sp)
    8000243e:	ec56                	sd	s5,24(sp)
    80002440:	e85a                	sd	s6,16(sp)
    80002442:	e45e                	sd	s7,8(sp)
    80002444:	e062                	sd	s8,0(sp)
    80002446:	0880                	addi	s0,sp,80
    80002448:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	758080e7          	jalr	1880(ra) # 80001ba2 <myproc>
    80002452:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002454:	8c2a                	mv	s8,a0
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	7ba080e7          	jalr	1978(ra) # 80000c10 <acquire>
    havekids = 0;
    8000245e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002460:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002462:	00015997          	auipc	s3,0x15
    80002466:	30698993          	addi	s3,s3,774 # 80017768 <tickslock>
        havekids = 1;
    8000246a:	4a85                	li	s5,1
    havekids = 0;
    8000246c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000246e:	00010497          	auipc	s1,0x10
    80002472:	8fa48493          	addi	s1,s1,-1798 # 80011d68 <proc>
    80002476:	a08d                	j	800024d8 <wait+0xa8>
          pid = np->pid;
    80002478:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000247c:	000b0e63          	beqz	s6,80002498 <wait+0x68>
    80002480:	4691                	li	a3,4
    80002482:	03448613          	addi	a2,s1,52
    80002486:	85da                	mv	a1,s6
    80002488:	05093503          	ld	a0,80(s2)
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	3d6080e7          	jalr	982(ra) # 80001862 <copyout>
    80002494:	02054263          	bltz	a0,800024b8 <wait+0x88>
          freeproc(np);
    80002498:	8526                	mv	a0,s1
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	8ba080e7          	jalr	-1862(ra) # 80001d54 <freeproc>
          release(&np->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	820080e7          	jalr	-2016(ra) # 80000cc4 <release>
          release(&p->lock);
    800024ac:	854a                	mv	a0,s2
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	816080e7          	jalr	-2026(ra) # 80000cc4 <release>
          return pid;
    800024b6:	a8a9                	j	80002510 <wait+0xe0>
            release(&np->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	80a080e7          	jalr	-2038(ra) # 80000cc4 <release>
            release(&p->lock);
    800024c2:	854a                	mv	a0,s2
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	800080e7          	jalr	-2048(ra) # 80000cc4 <release>
            return -1;
    800024cc:	59fd                	li	s3,-1
    800024ce:	a089                	j	80002510 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800024d0:	16848493          	addi	s1,s1,360
    800024d4:	03348463          	beq	s1,s3,800024fc <wait+0xcc>
      if(np->parent == p){
    800024d8:	709c                	ld	a5,32(s1)
    800024da:	ff279be3          	bne	a5,s2,800024d0 <wait+0xa0>
        acquire(&np->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	730080e7          	jalr	1840(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    800024e8:	4c9c                	lw	a5,24(s1)
    800024ea:	f94787e3          	beq	a5,s4,80002478 <wait+0x48>
        release(&np->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	7d4080e7          	jalr	2004(ra) # 80000cc4 <release>
        havekids = 1;
    800024f8:	8756                	mv	a4,s5
    800024fa:	bfd9                	j	800024d0 <wait+0xa0>
    if(!havekids || p->killed){
    800024fc:	c701                	beqz	a4,80002504 <wait+0xd4>
    800024fe:	03092783          	lw	a5,48(s2)
    80002502:	c785                	beqz	a5,8000252a <wait+0xfa>
      release(&p->lock);
    80002504:	854a                	mv	a0,s2
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	7be080e7          	jalr	1982(ra) # 80000cc4 <release>
      return -1;
    8000250e:	59fd                	li	s3,-1
}
    80002510:	854e                	mv	a0,s3
    80002512:	60a6                	ld	ra,72(sp)
    80002514:	6406                	ld	s0,64(sp)
    80002516:	74e2                	ld	s1,56(sp)
    80002518:	7942                	ld	s2,48(sp)
    8000251a:	79a2                	ld	s3,40(sp)
    8000251c:	7a02                	ld	s4,32(sp)
    8000251e:	6ae2                	ld	s5,24(sp)
    80002520:	6b42                	ld	s6,16(sp)
    80002522:	6ba2                	ld	s7,8(sp)
    80002524:	6c02                	ld	s8,0(sp)
    80002526:	6161                	addi	sp,sp,80
    80002528:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000252a:	85e2                	mv	a1,s8
    8000252c:	854a                	mv	a0,s2
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	e84080e7          	jalr	-380(ra) # 800023b2 <sleep>
    havekids = 0;
    80002536:	bf1d                	j	8000246c <wait+0x3c>

0000000080002538 <wakeup>:
{
    80002538:	7139                	addi	sp,sp,-64
    8000253a:	fc06                	sd	ra,56(sp)
    8000253c:	f822                	sd	s0,48(sp)
    8000253e:	f426                	sd	s1,40(sp)
    80002540:	f04a                	sd	s2,32(sp)
    80002542:	ec4e                	sd	s3,24(sp)
    80002544:	e852                	sd	s4,16(sp)
    80002546:	e456                	sd	s5,8(sp)
    80002548:	0080                	addi	s0,sp,64
    8000254a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000254c:	00010497          	auipc	s1,0x10
    80002550:	81c48493          	addi	s1,s1,-2020 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002554:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002556:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002558:	00015917          	auipc	s2,0x15
    8000255c:	21090913          	addi	s2,s2,528 # 80017768 <tickslock>
    80002560:	a821                	j	80002578 <wakeup+0x40>
      p->state = RUNNABLE;
    80002562:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	75c080e7          	jalr	1884(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002570:	16848493          	addi	s1,s1,360
    80002574:	01248e63          	beq	s1,s2,80002590 <wakeup+0x58>
    acquire(&p->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	696080e7          	jalr	1686(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002582:	4c9c                	lw	a5,24(s1)
    80002584:	ff3791e3          	bne	a5,s3,80002566 <wakeup+0x2e>
    80002588:	749c                	ld	a5,40(s1)
    8000258a:	fd479ee3          	bne	a5,s4,80002566 <wakeup+0x2e>
    8000258e:	bfd1                	j	80002562 <wakeup+0x2a>
}
    80002590:	70e2                	ld	ra,56(sp)
    80002592:	7442                	ld	s0,48(sp)
    80002594:	74a2                	ld	s1,40(sp)
    80002596:	7902                	ld	s2,32(sp)
    80002598:	69e2                	ld	s3,24(sp)
    8000259a:	6a42                	ld	s4,16(sp)
    8000259c:	6aa2                	ld	s5,8(sp)
    8000259e:	6121                	addi	sp,sp,64
    800025a0:	8082                	ret

00000000800025a2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025a2:	7179                	addi	sp,sp,-48
    800025a4:	f406                	sd	ra,40(sp)
    800025a6:	f022                	sd	s0,32(sp)
    800025a8:	ec26                	sd	s1,24(sp)
    800025aa:	e84a                	sd	s2,16(sp)
    800025ac:	e44e                	sd	s3,8(sp)
    800025ae:	1800                	addi	s0,sp,48
    800025b0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025b2:	0000f497          	auipc	s1,0xf
    800025b6:	7b648493          	addi	s1,s1,1974 # 80011d68 <proc>
    800025ba:	00015997          	auipc	s3,0x15
    800025be:	1ae98993          	addi	s3,s3,430 # 80017768 <tickslock>
    acquire(&p->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	64c080e7          	jalr	1612(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800025cc:	5c9c                	lw	a5,56(s1)
    800025ce:	01278d63          	beq	a5,s2,800025e8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6f0080e7          	jalr	1776(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025dc:	16848493          	addi	s1,s1,360
    800025e0:	ff3491e3          	bne	s1,s3,800025c2 <kill+0x20>
  }
  return -1;
    800025e4:	557d                	li	a0,-1
    800025e6:	a829                	j	80002600 <kill+0x5e>
      p->killed = 1;
    800025e8:	4785                	li	a5,1
    800025ea:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800025ec:	4c98                	lw	a4,24(s1)
    800025ee:	4785                	li	a5,1
    800025f0:	00f70f63          	beq	a4,a5,8000260e <kill+0x6c>
      release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	6ce080e7          	jalr	1742(ra) # 80000cc4 <release>
      return 0;
    800025fe:	4501                	li	a0,0
}
    80002600:	70a2                	ld	ra,40(sp)
    80002602:	7402                	ld	s0,32(sp)
    80002604:	64e2                	ld	s1,24(sp)
    80002606:	6942                	ld	s2,16(sp)
    80002608:	69a2                	ld	s3,8(sp)
    8000260a:	6145                	addi	sp,sp,48
    8000260c:	8082                	ret
        p->state = RUNNABLE;
    8000260e:	4789                	li	a5,2
    80002610:	cc9c                	sw	a5,24(s1)
    80002612:	b7cd                	j	800025f4 <kill+0x52>

0000000080002614 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002614:	7179                	addi	sp,sp,-48
    80002616:	f406                	sd	ra,40(sp)
    80002618:	f022                	sd	s0,32(sp)
    8000261a:	ec26                	sd	s1,24(sp)
    8000261c:	e84a                	sd	s2,16(sp)
    8000261e:	e44e                	sd	s3,8(sp)
    80002620:	e052                	sd	s4,0(sp)
    80002622:	1800                	addi	s0,sp,48
    80002624:	84aa                	mv	s1,a0
    80002626:	892e                	mv	s2,a1
    80002628:	89b2                	mv	s3,a2
    8000262a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	576080e7          	jalr	1398(ra) # 80001ba2 <myproc>
  if(user_dst){
    80002634:	c08d                	beqz	s1,80002656 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002636:	86d2                	mv	a3,s4
    80002638:	864e                	mv	a2,s3
    8000263a:	85ca                	mv	a1,s2
    8000263c:	6928                	ld	a0,80(a0)
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	224080e7          	jalr	548(ra) # 80001862 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002646:	70a2                	ld	ra,40(sp)
    80002648:	7402                	ld	s0,32(sp)
    8000264a:	64e2                	ld	s1,24(sp)
    8000264c:	6942                	ld	s2,16(sp)
    8000264e:	69a2                	ld	s3,8(sp)
    80002650:	6a02                	ld	s4,0(sp)
    80002652:	6145                	addi	sp,sp,48
    80002654:	8082                	ret
    memmove((char *)dst, src, len);
    80002656:	000a061b          	sext.w	a2,s4
    8000265a:	85ce                	mv	a1,s3
    8000265c:	854a                	mv	a0,s2
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	70e080e7          	jalr	1806(ra) # 80000d6c <memmove>
    return 0;
    80002666:	8526                	mv	a0,s1
    80002668:	bff9                	j	80002646 <either_copyout+0x32>

000000008000266a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000266a:	7179                	addi	sp,sp,-48
    8000266c:	f406                	sd	ra,40(sp)
    8000266e:	f022                	sd	s0,32(sp)
    80002670:	ec26                	sd	s1,24(sp)
    80002672:	e84a                	sd	s2,16(sp)
    80002674:	e44e                	sd	s3,8(sp)
    80002676:	e052                	sd	s4,0(sp)
    80002678:	1800                	addi	s0,sp,48
    8000267a:	892a                	mv	s2,a0
    8000267c:	84ae                	mv	s1,a1
    8000267e:	89b2                	mv	s3,a2
    80002680:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002682:	fffff097          	auipc	ra,0xfffff
    80002686:	520080e7          	jalr	1312(ra) # 80001ba2 <myproc>
  if(user_src){
    8000268a:	c08d                	beqz	s1,800026ac <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000268c:	86d2                	mv	a3,s4
    8000268e:	864e                	mv	a2,s3
    80002690:	85ca                	mv	a1,s2
    80002692:	6928                	ld	a0,80(a0)
    80002694:	fffff097          	auipc	ra,0xfffff
    80002698:	25a080e7          	jalr	602(ra) # 800018ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000269c:	70a2                	ld	ra,40(sp)
    8000269e:	7402                	ld	s0,32(sp)
    800026a0:	64e2                	ld	s1,24(sp)
    800026a2:	6942                	ld	s2,16(sp)
    800026a4:	69a2                	ld	s3,8(sp)
    800026a6:	6a02                	ld	s4,0(sp)
    800026a8:	6145                	addi	sp,sp,48
    800026aa:	8082                	ret
    memmove(dst, (char*)src, len);
    800026ac:	000a061b          	sext.w	a2,s4
    800026b0:	85ce                	mv	a1,s3
    800026b2:	854a                	mv	a0,s2
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	6b8080e7          	jalr	1720(ra) # 80000d6c <memmove>
    return 0;
    800026bc:	8526                	mv	a0,s1
    800026be:	bff9                	j	8000269c <either_copyin+0x32>

00000000800026c0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026c0:	715d                	addi	sp,sp,-80
    800026c2:	e486                	sd	ra,72(sp)
    800026c4:	e0a2                	sd	s0,64(sp)
    800026c6:	fc26                	sd	s1,56(sp)
    800026c8:	f84a                	sd	s2,48(sp)
    800026ca:	f44e                	sd	s3,40(sp)
    800026cc:	f052                	sd	s4,32(sp)
    800026ce:	ec56                	sd	s5,24(sp)
    800026d0:	e85a                	sd	s6,16(sp)
    800026d2:	e45e                	sd	s7,8(sp)
    800026d4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026d6:	00006517          	auipc	a0,0x6
    800026da:	9f250513          	addi	a0,a0,-1550 # 800080c8 <digits+0x88>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	eb4080e7          	jalr	-332(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e6:	0000f497          	auipc	s1,0xf
    800026ea:	7da48493          	addi	s1,s1,2010 # 80011ec0 <proc+0x158>
    800026ee:	00015917          	auipc	s2,0x15
    800026f2:	1d290913          	addi	s2,s2,466 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f6:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800026f8:	00006997          	auipc	s3,0x6
    800026fc:	bb898993          	addi	s3,s3,-1096 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    80002700:	00006a97          	auipc	s5,0x6
    80002704:	bb8a8a93          	addi	s5,s5,-1096 # 800082b8 <digits+0x278>
    printf("\n");
    80002708:	00006a17          	auipc	s4,0x6
    8000270c:	9c0a0a13          	addi	s4,s4,-1600 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002710:	00006b97          	auipc	s7,0x6
    80002714:	be0b8b93          	addi	s7,s7,-1056 # 800082f0 <states.1708>
    80002718:	a00d                	j	8000273a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000271a:	ee06a583          	lw	a1,-288(a3)
    8000271e:	8556                	mv	a0,s5
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	e72080e7          	jalr	-398(ra) # 80000592 <printf>
    printf("\n");
    80002728:	8552                	mv	a0,s4
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	e68080e7          	jalr	-408(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002732:	16848493          	addi	s1,s1,360
    80002736:	03248163          	beq	s1,s2,80002758 <procdump+0x98>
    if(p->state == UNUSED)
    8000273a:	86a6                	mv	a3,s1
    8000273c:	ec04a783          	lw	a5,-320(s1)
    80002740:	dbed                	beqz	a5,80002732 <procdump+0x72>
      state = "???";
    80002742:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002744:	fcfb6be3          	bltu	s6,a5,8000271a <procdump+0x5a>
    80002748:	1782                	slli	a5,a5,0x20
    8000274a:	9381                	srli	a5,a5,0x20
    8000274c:	078e                	slli	a5,a5,0x3
    8000274e:	97de                	add	a5,a5,s7
    80002750:	6390                	ld	a2,0(a5)
    80002752:	f661                	bnez	a2,8000271a <procdump+0x5a>
      state = "???";
    80002754:	864e                	mv	a2,s3
    80002756:	b7d1                	j	8000271a <procdump+0x5a>
  }
}
    80002758:	60a6                	ld	ra,72(sp)
    8000275a:	6406                	ld	s0,64(sp)
    8000275c:	74e2                	ld	s1,56(sp)
    8000275e:	7942                	ld	s2,48(sp)
    80002760:	79a2                	ld	s3,40(sp)
    80002762:	7a02                	ld	s4,32(sp)
    80002764:	6ae2                	ld	s5,24(sp)
    80002766:	6b42                	ld	s6,16(sp)
    80002768:	6ba2                	ld	s7,8(sp)
    8000276a:	6161                	addi	sp,sp,80
    8000276c:	8082                	ret

000000008000276e <swtch>:
    8000276e:	00153023          	sd	ra,0(a0)
    80002772:	00253423          	sd	sp,8(a0)
    80002776:	e900                	sd	s0,16(a0)
    80002778:	ed04                	sd	s1,24(a0)
    8000277a:	03253023          	sd	s2,32(a0)
    8000277e:	03353423          	sd	s3,40(a0)
    80002782:	03453823          	sd	s4,48(a0)
    80002786:	03553c23          	sd	s5,56(a0)
    8000278a:	05653023          	sd	s6,64(a0)
    8000278e:	05753423          	sd	s7,72(a0)
    80002792:	05853823          	sd	s8,80(a0)
    80002796:	05953c23          	sd	s9,88(a0)
    8000279a:	07a53023          	sd	s10,96(a0)
    8000279e:	07b53423          	sd	s11,104(a0)
    800027a2:	0005b083          	ld	ra,0(a1)
    800027a6:	0085b103          	ld	sp,8(a1)
    800027aa:	6980                	ld	s0,16(a1)
    800027ac:	6d84                	ld	s1,24(a1)
    800027ae:	0205b903          	ld	s2,32(a1)
    800027b2:	0285b983          	ld	s3,40(a1)
    800027b6:	0305ba03          	ld	s4,48(a1)
    800027ba:	0385ba83          	ld	s5,56(a1)
    800027be:	0405bb03          	ld	s6,64(a1)
    800027c2:	0485bb83          	ld	s7,72(a1)
    800027c6:	0505bc03          	ld	s8,80(a1)
    800027ca:	0585bc83          	ld	s9,88(a1)
    800027ce:	0605bd03          	ld	s10,96(a1)
    800027d2:	0685bd83          	ld	s11,104(a1)
    800027d6:	8082                	ret

00000000800027d8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027d8:	1141                	addi	sp,sp,-16
    800027da:	e406                	sd	ra,8(sp)
    800027dc:	e022                	sd	s0,0(sp)
    800027de:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027e0:	00006597          	auipc	a1,0x6
    800027e4:	b3858593          	addi	a1,a1,-1224 # 80008318 <states.1708+0x28>
    800027e8:	00015517          	auipc	a0,0x15
    800027ec:	f8050513          	addi	a0,a0,-128 # 80017768 <tickslock>
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	390080e7          	jalr	912(ra) # 80000b80 <initlock>
}
    800027f8:	60a2                	ld	ra,8(sp)
    800027fa:	6402                	ld	s0,0(sp)
    800027fc:	0141                	addi	sp,sp,16
    800027fe:	8082                	ret

0000000080002800 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002800:	1141                	addi	sp,sp,-16
    80002802:	e422                	sd	s0,8(sp)
    80002804:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002806:	00003797          	auipc	a5,0x3
    8000280a:	5aa78793          	addi	a5,a5,1450 # 80005db0 <kernelvec>
    8000280e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002812:	6422                	ld	s0,8(sp)
    80002814:	0141                	addi	sp,sp,16
    80002816:	8082                	ret

0000000080002818 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002818:	1141                	addi	sp,sp,-16
    8000281a:	e406                	sd	ra,8(sp)
    8000281c:	e022                	sd	s0,0(sp)
    8000281e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	382080e7          	jalr	898(ra) # 80001ba2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002828:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000282c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002832:	00004617          	auipc	a2,0x4
    80002836:	7ce60613          	addi	a2,a2,1998 # 80007000 <_trampoline>
    8000283a:	00004697          	auipc	a3,0x4
    8000283e:	7c668693          	addi	a3,a3,1990 # 80007000 <_trampoline>
    80002842:	8e91                	sub	a3,a3,a2
    80002844:	040007b7          	lui	a5,0x4000
    80002848:	17fd                	addi	a5,a5,-1
    8000284a:	07b2                	slli	a5,a5,0xc
    8000284c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002852:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002854:	180026f3          	csrr	a3,satp
    80002858:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000285a:	6d38                	ld	a4,88(a0)
    8000285c:	6134                	ld	a3,64(a0)
    8000285e:	6585                	lui	a1,0x1
    80002860:	96ae                	add	a3,a3,a1
    80002862:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002864:	6d38                	ld	a4,88(a0)
    80002866:	00000697          	auipc	a3,0x0
    8000286a:	13868693          	addi	a3,a3,312 # 8000299e <usertrap>
    8000286e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002870:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002872:	8692                	mv	a3,tp
    80002874:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002876:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000287a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000287e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002882:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002886:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002888:	6f18                	ld	a4,24(a4)
    8000288a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000288e:	692c                	ld	a1,80(a0)
    80002890:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002892:	00004717          	auipc	a4,0x4
    80002896:	7fe70713          	addi	a4,a4,2046 # 80007090 <userret>
    8000289a:	8f11                	sub	a4,a4,a2
    8000289c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000289e:	577d                	li	a4,-1
    800028a0:	177e                	slli	a4,a4,0x3f
    800028a2:	8dd9                	or	a1,a1,a4
    800028a4:	02000537          	lui	a0,0x2000
    800028a8:	157d                	addi	a0,a0,-1
    800028aa:	0536                	slli	a0,a0,0xd
    800028ac:	9782                	jalr	a5
}
    800028ae:	60a2                	ld	ra,8(sp)
    800028b0:	6402                	ld	s0,0(sp)
    800028b2:	0141                	addi	sp,sp,16
    800028b4:	8082                	ret

00000000800028b6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028b6:	1101                	addi	sp,sp,-32
    800028b8:	ec06                	sd	ra,24(sp)
    800028ba:	e822                	sd	s0,16(sp)
    800028bc:	e426                	sd	s1,8(sp)
    800028be:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028c0:	00015497          	auipc	s1,0x15
    800028c4:	ea848493          	addi	s1,s1,-344 # 80017768 <tickslock>
    800028c8:	8526                	mv	a0,s1
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	346080e7          	jalr	838(ra) # 80000c10 <acquire>
  ticks++;
    800028d2:	00006517          	auipc	a0,0x6
    800028d6:	74e50513          	addi	a0,a0,1870 # 80009020 <ticks>
    800028da:	411c                	lw	a5,0(a0)
    800028dc:	2785                	addiw	a5,a5,1
    800028de:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	c58080e7          	jalr	-936(ra) # 80002538 <wakeup>
  release(&tickslock);
    800028e8:	8526                	mv	a0,s1
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	3da080e7          	jalr	986(ra) # 80000cc4 <release>
}
    800028f2:	60e2                	ld	ra,24(sp)
    800028f4:	6442                	ld	s0,16(sp)
    800028f6:	64a2                	ld	s1,8(sp)
    800028f8:	6105                	addi	sp,sp,32
    800028fa:	8082                	ret

00000000800028fc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028fc:	1101                	addi	sp,sp,-32
    800028fe:	ec06                	sd	ra,24(sp)
    80002900:	e822                	sd	s0,16(sp)
    80002902:	e426                	sd	s1,8(sp)
    80002904:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002906:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000290a:	00074d63          	bltz	a4,80002924 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000290e:	57fd                	li	a5,-1
    80002910:	17fe                	slli	a5,a5,0x3f
    80002912:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002914:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002916:	06f70363          	beq	a4,a5,8000297c <devintr+0x80>
  }
}
    8000291a:	60e2                	ld	ra,24(sp)
    8000291c:	6442                	ld	s0,16(sp)
    8000291e:	64a2                	ld	s1,8(sp)
    80002920:	6105                	addi	sp,sp,32
    80002922:	8082                	ret
     (scause & 0xff) == 9){
    80002924:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002928:	46a5                	li	a3,9
    8000292a:	fed792e3          	bne	a5,a3,8000290e <devintr+0x12>
    int irq = plic_claim();
    8000292e:	00003097          	auipc	ra,0x3
    80002932:	58a080e7          	jalr	1418(ra) # 80005eb8 <plic_claim>
    80002936:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002938:	47a9                	li	a5,10
    8000293a:	02f50763          	beq	a0,a5,80002968 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000293e:	4785                	li	a5,1
    80002940:	02f50963          	beq	a0,a5,80002972 <devintr+0x76>
    return 1;
    80002944:	4505                	li	a0,1
    } else if(irq){
    80002946:	d8f1                	beqz	s1,8000291a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002948:	85a6                	mv	a1,s1
    8000294a:	00006517          	auipc	a0,0x6
    8000294e:	9d650513          	addi	a0,a0,-1578 # 80008320 <states.1708+0x30>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	c40080e7          	jalr	-960(ra) # 80000592 <printf>
      plic_complete(irq);
    8000295a:	8526                	mv	a0,s1
    8000295c:	00003097          	auipc	ra,0x3
    80002960:	580080e7          	jalr	1408(ra) # 80005edc <plic_complete>
    return 1;
    80002964:	4505                	li	a0,1
    80002966:	bf55                	j	8000291a <devintr+0x1e>
      uartintr();
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	06c080e7          	jalr	108(ra) # 800009d4 <uartintr>
    80002970:	b7ed                	j	8000295a <devintr+0x5e>
      virtio_disk_intr();
    80002972:	00004097          	auipc	ra,0x4
    80002976:	a04080e7          	jalr	-1532(ra) # 80006376 <virtio_disk_intr>
    8000297a:	b7c5                	j	8000295a <devintr+0x5e>
    if(cpuid() == 0){
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	1fa080e7          	jalr	506(ra) # 80001b76 <cpuid>
    80002984:	c901                	beqz	a0,80002994 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002986:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000298a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000298c:	14479073          	csrw	sip,a5
    return 2;
    80002990:	4509                	li	a0,2
    80002992:	b761                	j	8000291a <devintr+0x1e>
      clockintr();
    80002994:	00000097          	auipc	ra,0x0
    80002998:	f22080e7          	jalr	-222(ra) # 800028b6 <clockintr>
    8000299c:	b7ed                	j	80002986 <devintr+0x8a>

000000008000299e <usertrap>:
{
    8000299e:	7179                	addi	sp,sp,-48
    800029a0:	f406                	sd	ra,40(sp)
    800029a2:	f022                	sd	s0,32(sp)
    800029a4:	ec26                	sd	s1,24(sp)
    800029a6:	e84a                	sd	s2,16(sp)
    800029a8:	e44e                	sd	s3,8(sp)
    800029aa:	e052                	sd	s4,0(sp)
    800029ac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ae:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029b2:	1007f793          	andi	a5,a5,256
    800029b6:	e7a5                	bnez	a5,80002a1e <usertrap+0x80>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b8:	00003797          	auipc	a5,0x3
    800029bc:	3f878793          	addi	a5,a5,1016 # 80005db0 <kernelvec>
    800029c0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	1de080e7          	jalr	478(ra) # 80001ba2 <myproc>
    800029cc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029ce:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d0:	14102773          	csrr	a4,sepc
    800029d4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029da:	47a1                	li	a5,8
    800029dc:	04f71f63          	bne	a4,a5,80002a3a <usertrap+0x9c>
    if(p->killed)
    800029e0:	591c                	lw	a5,48(a0)
    800029e2:	e7b1                	bnez	a5,80002a2e <usertrap+0x90>
    p->trapframe->epc += 4;
    800029e4:	6cb8                	ld	a4,88(s1)
    800029e6:	6f1c                	ld	a5,24(a4)
    800029e8:	0791                	addi	a5,a5,4
    800029ea:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029f0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f4:	10079073          	csrw	sstatus,a5
    syscall();
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	39c080e7          	jalr	924(ra) # 80002d94 <syscall>
  if(p->killed)
    80002a00:	589c                	lw	a5,48(s1)
    80002a02:	12079a63          	bnez	a5,80002b36 <usertrap+0x198>
  usertrapret();
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	e12080e7          	jalr	-494(ra) # 80002818 <usertrapret>
}
    80002a0e:	70a2                	ld	ra,40(sp)
    80002a10:	7402                	ld	s0,32(sp)
    80002a12:	64e2                	ld	s1,24(sp)
    80002a14:	6942                	ld	s2,16(sp)
    80002a16:	69a2                	ld	s3,8(sp)
    80002a18:	6a02                	ld	s4,0(sp)
    80002a1a:	6145                	addi	sp,sp,48
    80002a1c:	8082                	ret
    panic("usertrap: not from user mode");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	92250513          	addi	a0,a0,-1758 # 80008340 <states.1708+0x50>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b22080e7          	jalr	-1246(ra) # 80000548 <panic>
      exit(-1);
    80002a2e:	557d                	li	a0,-1
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	83c080e7          	jalr	-1988(ra) # 8000226c <exit>
    80002a38:	b775                	j	800029e4 <usertrap+0x46>
  else if((which_dev = devintr()) != 0){
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	ec2080e7          	jalr	-318(ra) # 800028fc <devintr>
    80002a42:	892a                	mv	s2,a0
    80002a44:	e575                	bnez	a0,80002b30 <usertrap+0x192>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a46:	142027f3          	csrr	a5,scause
    if (scause == 13 || scause == 15)
    80002a4a:	9bf5                	andi	a5,a5,-3
    80002a4c:	4735                	li	a4,13
    80002a4e:	02e78c63          	beq	a5,a4,80002a86 <usertrap+0xe8>
    80002a52:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a56:	5c90                	lw	a2,56(s1)
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	98850513          	addi	a0,a0,-1656 # 800083e0 <states.1708+0xf0>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b32080e7          	jalr	-1230(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6c:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	9a050513          	addi	a0,a0,-1632 # 80008410 <states.1708+0x120>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b1a080e7          	jalr	-1254(ra) # 80000592 <printf>
      p->killed = 1;
    80002a80:	4785                	li	a5,1
    80002a82:	d89c                	sw	a5,48(s1)
    80002a84:	a855                	j	80002b38 <usertrap+0x19a>
    80002a86:	143027f3          	csrr	a5,stval
      if (va >= p->sz)
    80002a8a:	64b8                	ld	a4,72(s1)
    80002a8c:	06e7f163          	bgeu	a5,a4,80002aee <usertrap+0x150>
      if (va <= PGROUNDDOWN(p->trapframe->sp))
    80002a90:	6cb8                	ld	a4,88(s1)
    80002a92:	7b14                	ld	a3,48(a4)
    80002a94:	777d                	lui	a4,0xfffff
    80002a96:	8f75                	and	a4,a4,a3
    80002a98:	06f77663          	bgeu	a4,a5,80002b04 <usertrap+0x166>
      va = PGROUNDDOWN(va);
    80002a9c:	79fd                	lui	s3,0xfffff
    80002a9e:	0137f9b3          	and	s3,a5,s3
      char *mem = kalloc();
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	07e080e7          	jalr	126(ra) # 80000b20 <kalloc>
    80002aaa:	8a2a                	mv	s4,a0
      if (mem == 0)
    80002aac:	c53d                	beqz	a0,80002b1a <usertrap+0x17c>
      memset(mem, 0, PGSIZE);
    80002aae:	6605                	lui	a2,0x1
    80002ab0:	4581                	li	a1,0
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	25a080e7          	jalr	602(ra) # 80000d0c <memset>
      if (mappages(p->pagetable, va, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0)
    80002aba:	4779                	li	a4,30
    80002abc:	86d2                	mv	a3,s4
    80002abe:	6605                	lui	a2,0x1
    80002ac0:	85ce                	mv	a1,s3
    80002ac2:	68a8                	ld	a0,80(s1)
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	768080e7          	jalr	1896(ra) # 8000122c <mappages>
    80002acc:	d915                	beqz	a0,80002a00 <usertrap+0x62>
        printf("usertrap: mappages falied\n");
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	8f250513          	addi	a0,a0,-1806 # 800083c0 <states.1708+0xd0>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	abc080e7          	jalr	-1348(ra) # 80000592 <printf>
        kfree(mem);
    80002ade:	8552                	mv	a0,s4
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	f44080e7          	jalr	-188(ra) # 80000a24 <kfree>
        p->killed = 1;
    80002ae8:	4785                	li	a5,1
    80002aea:	d89c                	sw	a5,48(s1)
        goto done;
    80002aec:	a0b1                	j	80002b38 <usertrap+0x19a>
        printf("usertrap: invalid virtual address\n");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	87250513          	addi	a0,a0,-1934 # 80008360 <states.1708+0x70>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a9c080e7          	jalr	-1380(ra) # 80000592 <printf>
        p->killed = 1;
    80002afe:	4785                	li	a5,1
    80002b00:	d89c                	sw	a5,48(s1)
        goto done;
    80002b02:	a81d                	j	80002b38 <usertrap+0x19a>
        printf("usertrap: guard page\n");
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	88450513          	addi	a0,a0,-1916 # 80008388 <states.1708+0x98>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a86080e7          	jalr	-1402(ra) # 80000592 <printf>
        p->killed = 1;
    80002b14:	4785                	li	a5,1
    80002b16:	d89c                	sw	a5,48(s1)
        goto done;
    80002b18:	a005                	j	80002b38 <usertrap+0x19a>
        printf("usertrap: out of memory\n");
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	88650513          	addi	a0,a0,-1914 # 800083a0 <states.1708+0xb0>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a70080e7          	jalr	-1424(ra) # 80000592 <printf>
        p->killed = 1;
    80002b2a:	4785                	li	a5,1
    80002b2c:	d89c                	sw	a5,48(s1)
        goto done;
    80002b2e:	a029                	j	80002b38 <usertrap+0x19a>
  if(p->killed)
    80002b30:	589c                	lw	a5,48(s1)
    80002b32:	cb81                	beqz	a5,80002b42 <usertrap+0x1a4>
    80002b34:	a011                	j	80002b38 <usertrap+0x19a>
    80002b36:	4901                	li	s2,0
    exit(-1);
    80002b38:	557d                	li	a0,-1
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	732080e7          	jalr	1842(ra) # 8000226c <exit>
  if(which_dev == 2)
    80002b42:	4789                	li	a5,2
    80002b44:	ecf911e3          	bne	s2,a5,80002a06 <usertrap+0x68>
    yield();
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	82e080e7          	jalr	-2002(ra) # 80002376 <yield>
    80002b50:	bd5d                	j	80002a06 <usertrap+0x68>

0000000080002b52 <kerneltrap>:
{
    80002b52:	7179                	addi	sp,sp,-48
    80002b54:	f406                	sd	ra,40(sp)
    80002b56:	f022                	sd	s0,32(sp)
    80002b58:	ec26                	sd	s1,24(sp)
    80002b5a:	e84a                	sd	s2,16(sp)
    80002b5c:	e44e                	sd	s3,8(sp)
    80002b5e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b60:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b64:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b68:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b6c:	1004f793          	andi	a5,s1,256
    80002b70:	cb85                	beqz	a5,80002ba0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b76:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b78:	ef85                	bnez	a5,80002bb0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	d82080e7          	jalr	-638(ra) # 800028fc <devintr>
    80002b82:	cd1d                	beqz	a0,80002bc0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b84:	4789                	li	a5,2
    80002b86:	06f50a63          	beq	a0,a5,80002bfa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b8a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8e:	10049073          	csrw	sstatus,s1
}
    80002b92:	70a2                	ld	ra,40(sp)
    80002b94:	7402                	ld	s0,32(sp)
    80002b96:	64e2                	ld	s1,24(sp)
    80002b98:	6942                	ld	s2,16(sp)
    80002b9a:	69a2                	ld	s3,8(sp)
    80002b9c:	6145                	addi	sp,sp,48
    80002b9e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ba0:	00006517          	auipc	a0,0x6
    80002ba4:	89050513          	addi	a0,a0,-1904 # 80008430 <states.1708+0x140>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9a0080e7          	jalr	-1632(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	8a850513          	addi	a0,a0,-1880 # 80008458 <states.1708+0x168>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	990080e7          	jalr	-1648(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002bc0:	85ce                	mv	a1,s3
    80002bc2:	00006517          	auipc	a0,0x6
    80002bc6:	8b650513          	addi	a0,a0,-1866 # 80008478 <states.1708+0x188>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	9c8080e7          	jalr	-1592(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bda:	00006517          	auipc	a0,0x6
    80002bde:	8ae50513          	addi	a0,a0,-1874 # 80008488 <states.1708+0x198>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	9b0080e7          	jalr	-1616(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002bea:	00006517          	auipc	a0,0x6
    80002bee:	8b650513          	addi	a0,a0,-1866 # 800084a0 <states.1708+0x1b0>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	956080e7          	jalr	-1706(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	fa8080e7          	jalr	-88(ra) # 80001ba2 <myproc>
    80002c02:	d541                	beqz	a0,80002b8a <kerneltrap+0x38>
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	f9e080e7          	jalr	-98(ra) # 80001ba2 <myproc>
    80002c0c:	4d18                	lw	a4,24(a0)
    80002c0e:	478d                	li	a5,3
    80002c10:	f6f71de3          	bne	a4,a5,80002b8a <kerneltrap+0x38>
    yield();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	762080e7          	jalr	1890(ra) # 80002376 <yield>
    80002c1c:	b7bd                	j	80002b8a <kerneltrap+0x38>

0000000080002c1e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	e426                	sd	s1,8(sp)
    80002c26:	1000                	addi	s0,sp,32
    80002c28:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	f78080e7          	jalr	-136(ra) # 80001ba2 <myproc>
  switch (n) {
    80002c32:	4795                	li	a5,5
    80002c34:	0497e163          	bltu	a5,s1,80002c76 <argraw+0x58>
    80002c38:	048a                	slli	s1,s1,0x2
    80002c3a:	00006717          	auipc	a4,0x6
    80002c3e:	89e70713          	addi	a4,a4,-1890 # 800084d8 <states.1708+0x1e8>
    80002c42:	94ba                	add	s1,s1,a4
    80002c44:	409c                	lw	a5,0(s1)
    80002c46:	97ba                	add	a5,a5,a4
    80002c48:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c4a:	6d3c                	ld	a5,88(a0)
    80002c4c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret
    return p->trapframe->a1;
    80002c58:	6d3c                	ld	a5,88(a0)
    80002c5a:	7fa8                	ld	a0,120(a5)
    80002c5c:	bfcd                	j	80002c4e <argraw+0x30>
    return p->trapframe->a2;
    80002c5e:	6d3c                	ld	a5,88(a0)
    80002c60:	63c8                	ld	a0,128(a5)
    80002c62:	b7f5                	j	80002c4e <argraw+0x30>
    return p->trapframe->a3;
    80002c64:	6d3c                	ld	a5,88(a0)
    80002c66:	67c8                	ld	a0,136(a5)
    80002c68:	b7dd                	j	80002c4e <argraw+0x30>
    return p->trapframe->a4;
    80002c6a:	6d3c                	ld	a5,88(a0)
    80002c6c:	6bc8                	ld	a0,144(a5)
    80002c6e:	b7c5                	j	80002c4e <argraw+0x30>
    return p->trapframe->a5;
    80002c70:	6d3c                	ld	a5,88(a0)
    80002c72:	6fc8                	ld	a0,152(a5)
    80002c74:	bfe9                	j	80002c4e <argraw+0x30>
  panic("argraw");
    80002c76:	00006517          	auipc	a0,0x6
    80002c7a:	83a50513          	addi	a0,a0,-1990 # 800084b0 <states.1708+0x1c0>
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	8ca080e7          	jalr	-1846(ra) # 80000548 <panic>

0000000080002c86 <fetchaddr>:
{
    80002c86:	1101                	addi	sp,sp,-32
    80002c88:	ec06                	sd	ra,24(sp)
    80002c8a:	e822                	sd	s0,16(sp)
    80002c8c:	e426                	sd	s1,8(sp)
    80002c8e:	e04a                	sd	s2,0(sp)
    80002c90:	1000                	addi	s0,sp,32
    80002c92:	84aa                	mv	s1,a0
    80002c94:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	f0c080e7          	jalr	-244(ra) # 80001ba2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c9e:	653c                	ld	a5,72(a0)
    80002ca0:	02f4f863          	bgeu	s1,a5,80002cd0 <fetchaddr+0x4a>
    80002ca4:	00848713          	addi	a4,s1,8
    80002ca8:	02e7e663          	bltu	a5,a4,80002cd4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cac:	46a1                	li	a3,8
    80002cae:	8626                	mv	a2,s1
    80002cb0:	85ca                	mv	a1,s2
    80002cb2:	6928                	ld	a0,80(a0)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	c3a080e7          	jalr	-966(ra) # 800018ee <copyin>
    80002cbc:	00a03533          	snez	a0,a0
    80002cc0:	40a00533          	neg	a0,a0
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6902                	ld	s2,0(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret
    return -1;
    80002cd0:	557d                	li	a0,-1
    80002cd2:	bfcd                	j	80002cc4 <fetchaddr+0x3e>
    80002cd4:	557d                	li	a0,-1
    80002cd6:	b7fd                	j	80002cc4 <fetchaddr+0x3e>

0000000080002cd8 <fetchstr>:
{
    80002cd8:	7179                	addi	sp,sp,-48
    80002cda:	f406                	sd	ra,40(sp)
    80002cdc:	f022                	sd	s0,32(sp)
    80002cde:	ec26                	sd	s1,24(sp)
    80002ce0:	e84a                	sd	s2,16(sp)
    80002ce2:	e44e                	sd	s3,8(sp)
    80002ce4:	1800                	addi	s0,sp,48
    80002ce6:	892a                	mv	s2,a0
    80002ce8:	84ae                	mv	s1,a1
    80002cea:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	eb6080e7          	jalr	-330(ra) # 80001ba2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cf4:	86ce                	mv	a3,s3
    80002cf6:	864a                	mv	a2,s2
    80002cf8:	85a6                	mv	a1,s1
    80002cfa:	6928                	ld	a0,80(a0)
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	c7e080e7          	jalr	-898(ra) # 8000197a <copyinstr>
  if(err < 0)
    80002d04:	00054763          	bltz	a0,80002d12 <fetchstr+0x3a>
  return strlen(buf);
    80002d08:	8526                	mv	a0,s1
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	18a080e7          	jalr	394(ra) # 80000e94 <strlen>
}
    80002d12:	70a2                	ld	ra,40(sp)
    80002d14:	7402                	ld	s0,32(sp)
    80002d16:	64e2                	ld	s1,24(sp)
    80002d18:	6942                	ld	s2,16(sp)
    80002d1a:	69a2                	ld	s3,8(sp)
    80002d1c:	6145                	addi	sp,sp,48
    80002d1e:	8082                	ret

0000000080002d20 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	e426                	sd	s1,8(sp)
    80002d28:	1000                	addi	s0,sp,32
    80002d2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	ef2080e7          	jalr	-270(ra) # 80002c1e <argraw>
    80002d34:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d36:	4501                	li	a0,0
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	64a2                	ld	s1,8(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret

0000000080002d42 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	e426                	sd	s1,8(sp)
    80002d4a:	1000                	addi	s0,sp,32
    80002d4c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	ed0080e7          	jalr	-304(ra) # 80002c1e <argraw>
    80002d56:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d58:	4501                	li	a0,0
    80002d5a:	60e2                	ld	ra,24(sp)
    80002d5c:	6442                	ld	s0,16(sp)
    80002d5e:	64a2                	ld	s1,8(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	e426                	sd	s1,8(sp)
    80002d6c:	e04a                	sd	s2,0(sp)
    80002d6e:	1000                	addi	s0,sp,32
    80002d70:	84ae                	mv	s1,a1
    80002d72:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	eaa080e7          	jalr	-342(ra) # 80002c1e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d7c:	864a                	mv	a2,s2
    80002d7e:	85a6                	mv	a1,s1
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	f58080e7          	jalr	-168(ra) # 80002cd8 <fetchstr>
}
    80002d88:	60e2                	ld	ra,24(sp)
    80002d8a:	6442                	ld	s0,16(sp)
    80002d8c:	64a2                	ld	s1,8(sp)
    80002d8e:	6902                	ld	s2,0(sp)
    80002d90:	6105                	addi	sp,sp,32
    80002d92:	8082                	ret

0000000080002d94 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d94:	1101                	addi	sp,sp,-32
    80002d96:	ec06                	sd	ra,24(sp)
    80002d98:	e822                	sd	s0,16(sp)
    80002d9a:	e426                	sd	s1,8(sp)
    80002d9c:	e04a                	sd	s2,0(sp)
    80002d9e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	e02080e7          	jalr	-510(ra) # 80001ba2 <myproc>
    80002da8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002daa:	05853903          	ld	s2,88(a0)
    80002dae:	0a893783          	ld	a5,168(s2)
    80002db2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002db6:	37fd                	addiw	a5,a5,-1
    80002db8:	4751                	li	a4,20
    80002dba:	00f76f63          	bltu	a4,a5,80002dd8 <syscall+0x44>
    80002dbe:	00369713          	slli	a4,a3,0x3
    80002dc2:	00005797          	auipc	a5,0x5
    80002dc6:	72e78793          	addi	a5,a5,1838 # 800084f0 <syscalls>
    80002dca:	97ba                	add	a5,a5,a4
    80002dcc:	639c                	ld	a5,0(a5)
    80002dce:	c789                	beqz	a5,80002dd8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002dd0:	9782                	jalr	a5
    80002dd2:	06a93823          	sd	a0,112(s2)
    80002dd6:	a839                	j	80002df4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dd8:	15848613          	addi	a2,s1,344
    80002ddc:	5c8c                	lw	a1,56(s1)
    80002dde:	00005517          	auipc	a0,0x5
    80002de2:	6da50513          	addi	a0,a0,1754 # 800084b8 <states.1708+0x1c8>
    80002de6:	ffffd097          	auipc	ra,0xffffd
    80002dea:	7ac080e7          	jalr	1964(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dee:	6cbc                	ld	a5,88(s1)
    80002df0:	577d                	li	a4,-1
    80002df2:	fbb8                	sd	a4,112(a5)
  }
}
    80002df4:	60e2                	ld	ra,24(sp)
    80002df6:	6442                	ld	s0,16(sp)
    80002df8:	64a2                	ld	s1,8(sp)
    80002dfa:	6902                	ld	s2,0(sp)
    80002dfc:	6105                	addi	sp,sp,32
    80002dfe:	8082                	ret

0000000080002e00 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e00:	1101                	addi	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e08:	fec40593          	addi	a1,s0,-20
    80002e0c:	4501                	li	a0,0
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	f12080e7          	jalr	-238(ra) # 80002d20 <argint>
    return -1;
    80002e16:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e18:	00054963          	bltz	a0,80002e2a <sys_exit+0x2a>
  exit(n);
    80002e1c:	fec42503          	lw	a0,-20(s0)
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	44c080e7          	jalr	1100(ra) # 8000226c <exit>
  return 0;  // not reached
    80002e28:	4781                	li	a5,0
}
    80002e2a:	853e                	mv	a0,a5
    80002e2c:	60e2                	ld	ra,24(sp)
    80002e2e:	6442                	ld	s0,16(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e34:	1141                	addi	sp,sp,-16
    80002e36:	e406                	sd	ra,8(sp)
    80002e38:	e022                	sd	s0,0(sp)
    80002e3a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	d66080e7          	jalr	-666(ra) # 80001ba2 <myproc>
}
    80002e44:	5d08                	lw	a0,56(a0)
    80002e46:	60a2                	ld	ra,8(sp)
    80002e48:	6402                	ld	s0,0(sp)
    80002e4a:	0141                	addi	sp,sp,16
    80002e4c:	8082                	ret

0000000080002e4e <sys_fork>:

uint64
sys_fork(void)
{
    80002e4e:	1141                	addi	sp,sp,-16
    80002e50:	e406                	sd	ra,8(sp)
    80002e52:	e022                	sd	s0,0(sp)
    80002e54:	0800                	addi	s0,sp,16
  return fork();
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	10c080e7          	jalr	268(ra) # 80001f62 <fork>
}
    80002e5e:	60a2                	ld	ra,8(sp)
    80002e60:	6402                	ld	s0,0(sp)
    80002e62:	0141                	addi	sp,sp,16
    80002e64:	8082                	ret

0000000080002e66 <sys_wait>:

uint64
sys_wait(void)
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e6e:	fe840593          	addi	a1,s0,-24
    80002e72:	4501                	li	a0,0
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	ece080e7          	jalr	-306(ra) # 80002d42 <argaddr>
    80002e7c:	87aa                	mv	a5,a0
    return -1;
    80002e7e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e80:	0007c863          	bltz	a5,80002e90 <sys_wait+0x2a>
  return wait(p);
    80002e84:	fe843503          	ld	a0,-24(s0)
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	5a8080e7          	jalr	1448(ra) # 80002430 <wait>
}
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	6105                	addi	sp,sp,32
    80002e96:	8082                	ret

0000000080002e98 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e98:	7179                	addi	sp,sp,-48
    80002e9a:	f406                	sd	ra,40(sp)
    80002e9c:	f022                	sd	s0,32(sp)
    80002e9e:	ec26                	sd	s1,24(sp)
    80002ea0:	e84a                	sd	s2,16(sp)
    80002ea2:	1800                	addi	s0,sp,48
  int n;
  struct proc *proc = myproc();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	cfe080e7          	jalr	-770(ra) # 80001ba2 <myproc>
    80002eac:	84aa                	mv	s1,a0

  if(argint(0, &n) < 0)
    80002eae:	fdc40593          	addi	a1,s0,-36
    80002eb2:	4501                	li	a0,0
    80002eb4:	00000097          	auipc	ra,0x0
    80002eb8:	e6c080e7          	jalr	-404(ra) # 80002d20 <argint>
    80002ebc:	02054663          	bltz	a0,80002ee8 <sys_sbrk+0x50>
    return -1;
  
  uint64 oldsz = proc->sz;
    80002ec0:	0484b903          	ld	s2,72(s1)
  
  if (n > 0)
    80002ec4:	fdc42503          	lw	a0,-36(s0)
    80002ec8:	00a05b63          	blez	a0,80002ede <sys_sbrk+0x46>
  {
    proc->sz += n;
    80002ecc:	954a                	add	a0,a0,s2
    80002ece:	e4a8                	sd	a0,72(s1)
  {
    growproc(n);
  }
  
  return oldsz;
}
    80002ed0:	854a                	mv	a0,s2
    80002ed2:	70a2                	ld	ra,40(sp)
    80002ed4:	7402                	ld	s0,32(sp)
    80002ed6:	64e2                	ld	s1,24(sp)
    80002ed8:	6942                	ld	s2,16(sp)
    80002eda:	6145                	addi	sp,sp,48
    80002edc:	8082                	ret
    growproc(n);
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	010080e7          	jalr	16(ra) # 80001eee <growproc>
    80002ee6:	b7ed                	j	80002ed0 <sys_sbrk+0x38>
    return -1;
    80002ee8:	597d                	li	s2,-1
    80002eea:	b7dd                	j	80002ed0 <sys_sbrk+0x38>

0000000080002eec <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eec:	7139                	addi	sp,sp,-64
    80002eee:	fc06                	sd	ra,56(sp)
    80002ef0:	f822                	sd	s0,48(sp)
    80002ef2:	f426                	sd	s1,40(sp)
    80002ef4:	f04a                	sd	s2,32(sp)
    80002ef6:	ec4e                	sd	s3,24(sp)
    80002ef8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002efa:	fcc40593          	addi	a1,s0,-52
    80002efe:	4501                	li	a0,0
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	e20080e7          	jalr	-480(ra) # 80002d20 <argint>
    return -1;
    80002f08:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f0a:	06054563          	bltz	a0,80002f74 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f0e:	00015517          	auipc	a0,0x15
    80002f12:	85a50513          	addi	a0,a0,-1958 # 80017768 <tickslock>
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	cfa080e7          	jalr	-774(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002f1e:	00006917          	auipc	s2,0x6
    80002f22:	10292903          	lw	s2,258(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f26:	fcc42783          	lw	a5,-52(s0)
    80002f2a:	cf85                	beqz	a5,80002f62 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f2c:	00015997          	auipc	s3,0x15
    80002f30:	83c98993          	addi	s3,s3,-1988 # 80017768 <tickslock>
    80002f34:	00006497          	auipc	s1,0x6
    80002f38:	0ec48493          	addi	s1,s1,236 # 80009020 <ticks>
    if(myproc()->killed){
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	c66080e7          	jalr	-922(ra) # 80001ba2 <myproc>
    80002f44:	591c                	lw	a5,48(a0)
    80002f46:	ef9d                	bnez	a5,80002f84 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f48:	85ce                	mv	a1,s3
    80002f4a:	8526                	mv	a0,s1
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	466080e7          	jalr	1126(ra) # 800023b2 <sleep>
  while(ticks - ticks0 < n){
    80002f54:	409c                	lw	a5,0(s1)
    80002f56:	412787bb          	subw	a5,a5,s2
    80002f5a:	fcc42703          	lw	a4,-52(s0)
    80002f5e:	fce7efe3          	bltu	a5,a4,80002f3c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f62:	00015517          	auipc	a0,0x15
    80002f66:	80650513          	addi	a0,a0,-2042 # 80017768 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	d5a080e7          	jalr	-678(ra) # 80000cc4 <release>
  return 0;
    80002f72:	4781                	li	a5,0
}
    80002f74:	853e                	mv	a0,a5
    80002f76:	70e2                	ld	ra,56(sp)
    80002f78:	7442                	ld	s0,48(sp)
    80002f7a:	74a2                	ld	s1,40(sp)
    80002f7c:	7902                	ld	s2,32(sp)
    80002f7e:	69e2                	ld	s3,24(sp)
    80002f80:	6121                	addi	sp,sp,64
    80002f82:	8082                	ret
      release(&tickslock);
    80002f84:	00014517          	auipc	a0,0x14
    80002f88:	7e450513          	addi	a0,a0,2020 # 80017768 <tickslock>
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	d38080e7          	jalr	-712(ra) # 80000cc4 <release>
      return -1;
    80002f94:	57fd                	li	a5,-1
    80002f96:	bff9                	j	80002f74 <sys_sleep+0x88>

0000000080002f98 <sys_kill>:

uint64
sys_kill(void)
{
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fa0:	fec40593          	addi	a1,s0,-20
    80002fa4:	4501                	li	a0,0
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	d7a080e7          	jalr	-646(ra) # 80002d20 <argint>
    80002fae:	87aa                	mv	a5,a0
    return -1;
    80002fb0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fb2:	0007c863          	bltz	a5,80002fc2 <sys_kill+0x2a>
  return kill(pid);
    80002fb6:	fec42503          	lw	a0,-20(s0)
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	5e8080e7          	jalr	1512(ra) # 800025a2 <kill>
}
    80002fc2:	60e2                	ld	ra,24(sp)
    80002fc4:	6442                	ld	s0,16(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret

0000000080002fca <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	e426                	sd	s1,8(sp)
    80002fd2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fd4:	00014517          	auipc	a0,0x14
    80002fd8:	79450513          	addi	a0,a0,1940 # 80017768 <tickslock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	c34080e7          	jalr	-972(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002fe4:	00006497          	auipc	s1,0x6
    80002fe8:	03c4a483          	lw	s1,60(s1) # 80009020 <ticks>
  release(&tickslock);
    80002fec:	00014517          	auipc	a0,0x14
    80002ff0:	77c50513          	addi	a0,a0,1916 # 80017768 <tickslock>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	cd0080e7          	jalr	-816(ra) # 80000cc4 <release>
  return xticks;
}
    80002ffc:	02049513          	slli	a0,s1,0x20
    80003000:	9101                	srli	a0,a0,0x20
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	64a2                	ld	s1,8(sp)
    80003008:	6105                	addi	sp,sp,32
    8000300a:	8082                	ret

000000008000300c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000300c:	7179                	addi	sp,sp,-48
    8000300e:	f406                	sd	ra,40(sp)
    80003010:	f022                	sd	s0,32(sp)
    80003012:	ec26                	sd	s1,24(sp)
    80003014:	e84a                	sd	s2,16(sp)
    80003016:	e44e                	sd	s3,8(sp)
    80003018:	e052                	sd	s4,0(sp)
    8000301a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000301c:	00005597          	auipc	a1,0x5
    80003020:	58458593          	addi	a1,a1,1412 # 800085a0 <syscalls+0xb0>
    80003024:	00014517          	auipc	a0,0x14
    80003028:	75c50513          	addi	a0,a0,1884 # 80017780 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	b54080e7          	jalr	-1196(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003034:	0001c797          	auipc	a5,0x1c
    80003038:	74c78793          	addi	a5,a5,1868 # 8001f780 <bcache+0x8000>
    8000303c:	0001d717          	auipc	a4,0x1d
    80003040:	9ac70713          	addi	a4,a4,-1620 # 8001f9e8 <bcache+0x8268>
    80003044:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003048:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000304c:	00014497          	auipc	s1,0x14
    80003050:	74c48493          	addi	s1,s1,1868 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80003054:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003056:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003058:	00005a17          	auipc	s4,0x5
    8000305c:	550a0a13          	addi	s4,s4,1360 # 800085a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003060:	2b893783          	ld	a5,696(s2)
    80003064:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003066:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000306a:	85d2                	mv	a1,s4
    8000306c:	01048513          	addi	a0,s1,16
    80003070:	00001097          	auipc	ra,0x1
    80003074:	4b0080e7          	jalr	1200(ra) # 80004520 <initsleeplock>
    bcache.head.next->prev = b;
    80003078:	2b893783          	ld	a5,696(s2)
    8000307c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000307e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003082:	45848493          	addi	s1,s1,1112
    80003086:	fd349de3          	bne	s1,s3,80003060 <binit+0x54>
  }
}
    8000308a:	70a2                	ld	ra,40(sp)
    8000308c:	7402                	ld	s0,32(sp)
    8000308e:	64e2                	ld	s1,24(sp)
    80003090:	6942                	ld	s2,16(sp)
    80003092:	69a2                	ld	s3,8(sp)
    80003094:	6a02                	ld	s4,0(sp)
    80003096:	6145                	addi	sp,sp,48
    80003098:	8082                	ret

000000008000309a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000309a:	7179                	addi	sp,sp,-48
    8000309c:	f406                	sd	ra,40(sp)
    8000309e:	f022                	sd	s0,32(sp)
    800030a0:	ec26                	sd	s1,24(sp)
    800030a2:	e84a                	sd	s2,16(sp)
    800030a4:	e44e                	sd	s3,8(sp)
    800030a6:	1800                	addi	s0,sp,48
    800030a8:	89aa                	mv	s3,a0
    800030aa:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030ac:	00014517          	auipc	a0,0x14
    800030b0:	6d450513          	addi	a0,a0,1748 # 80017780 <bcache>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	b5c080e7          	jalr	-1188(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030bc:	0001d497          	auipc	s1,0x1d
    800030c0:	97c4b483          	ld	s1,-1668(s1) # 8001fa38 <bcache+0x82b8>
    800030c4:	0001d797          	auipc	a5,0x1d
    800030c8:	92478793          	addi	a5,a5,-1756 # 8001f9e8 <bcache+0x8268>
    800030cc:	02f48f63          	beq	s1,a5,8000310a <bread+0x70>
    800030d0:	873e                	mv	a4,a5
    800030d2:	a021                	j	800030da <bread+0x40>
    800030d4:	68a4                	ld	s1,80(s1)
    800030d6:	02e48a63          	beq	s1,a4,8000310a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030da:	449c                	lw	a5,8(s1)
    800030dc:	ff379ce3          	bne	a5,s3,800030d4 <bread+0x3a>
    800030e0:	44dc                	lw	a5,12(s1)
    800030e2:	ff2799e3          	bne	a5,s2,800030d4 <bread+0x3a>
      b->refcnt++;
    800030e6:	40bc                	lw	a5,64(s1)
    800030e8:	2785                	addiw	a5,a5,1
    800030ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	69450513          	addi	a0,a0,1684 # 80017780 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	bd0080e7          	jalr	-1072(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800030fc:	01048513          	addi	a0,s1,16
    80003100:	00001097          	auipc	ra,0x1
    80003104:	45a080e7          	jalr	1114(ra) # 8000455a <acquiresleep>
      return b;
    80003108:	a8b9                	j	80003166 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310a:	0001d497          	auipc	s1,0x1d
    8000310e:	9264b483          	ld	s1,-1754(s1) # 8001fa30 <bcache+0x82b0>
    80003112:	0001d797          	auipc	a5,0x1d
    80003116:	8d678793          	addi	a5,a5,-1834 # 8001f9e8 <bcache+0x8268>
    8000311a:	00f48863          	beq	s1,a5,8000312a <bread+0x90>
    8000311e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003120:	40bc                	lw	a5,64(s1)
    80003122:	cf81                	beqz	a5,8000313a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003124:	64a4                	ld	s1,72(s1)
    80003126:	fee49de3          	bne	s1,a4,80003120 <bread+0x86>
  panic("bget: no buffers");
    8000312a:	00005517          	auipc	a0,0x5
    8000312e:	48650513          	addi	a0,a0,1158 # 800085b0 <syscalls+0xc0>
    80003132:	ffffd097          	auipc	ra,0xffffd
    80003136:	416080e7          	jalr	1046(ra) # 80000548 <panic>
      b->dev = dev;
    8000313a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000313e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003142:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003146:	4785                	li	a5,1
    80003148:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	63650513          	addi	a0,a0,1590 # 80017780 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b72080e7          	jalr	-1166(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000315a:	01048513          	addi	a0,s1,16
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	3fc080e7          	jalr	1020(ra) # 8000455a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003166:	409c                	lw	a5,0(s1)
    80003168:	cb89                	beqz	a5,8000317a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000316a:	8526                	mv	a0,s1
    8000316c:	70a2                	ld	ra,40(sp)
    8000316e:	7402                	ld	s0,32(sp)
    80003170:	64e2                	ld	s1,24(sp)
    80003172:	6942                	ld	s2,16(sp)
    80003174:	69a2                	ld	s3,8(sp)
    80003176:	6145                	addi	sp,sp,48
    80003178:	8082                	ret
    virtio_disk_rw(b, 0);
    8000317a:	4581                	li	a1,0
    8000317c:	8526                	mv	a0,s1
    8000317e:	00003097          	auipc	ra,0x3
    80003182:	f4e080e7          	jalr	-178(ra) # 800060cc <virtio_disk_rw>
    b->valid = 1;
    80003186:	4785                	li	a5,1
    80003188:	c09c                	sw	a5,0(s1)
  return b;
    8000318a:	b7c5                	j	8000316a <bread+0xd0>

000000008000318c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000318c:	1101                	addi	sp,sp,-32
    8000318e:	ec06                	sd	ra,24(sp)
    80003190:	e822                	sd	s0,16(sp)
    80003192:	e426                	sd	s1,8(sp)
    80003194:	1000                	addi	s0,sp,32
    80003196:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003198:	0541                	addi	a0,a0,16
    8000319a:	00001097          	auipc	ra,0x1
    8000319e:	45a080e7          	jalr	1114(ra) # 800045f4 <holdingsleep>
    800031a2:	cd01                	beqz	a0,800031ba <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031a4:	4585                	li	a1,1
    800031a6:	8526                	mv	a0,s1
    800031a8:	00003097          	auipc	ra,0x3
    800031ac:	f24080e7          	jalr	-220(ra) # 800060cc <virtio_disk_rw>
}
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	64a2                	ld	s1,8(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret
    panic("bwrite");
    800031ba:	00005517          	auipc	a0,0x5
    800031be:	40e50513          	addi	a0,a0,1038 # 800085c8 <syscalls+0xd8>
    800031c2:	ffffd097          	auipc	ra,0xffffd
    800031c6:	386080e7          	jalr	902(ra) # 80000548 <panic>

00000000800031ca <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031ca:	1101                	addi	sp,sp,-32
    800031cc:	ec06                	sd	ra,24(sp)
    800031ce:	e822                	sd	s0,16(sp)
    800031d0:	e426                	sd	s1,8(sp)
    800031d2:	e04a                	sd	s2,0(sp)
    800031d4:	1000                	addi	s0,sp,32
    800031d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031d8:	01050913          	addi	s2,a0,16
    800031dc:	854a                	mv	a0,s2
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	416080e7          	jalr	1046(ra) # 800045f4 <holdingsleep>
    800031e6:	c92d                	beqz	a0,80003258 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00001097          	auipc	ra,0x1
    800031ee:	3c6080e7          	jalr	966(ra) # 800045b0 <releasesleep>

  acquire(&bcache.lock);
    800031f2:	00014517          	auipc	a0,0x14
    800031f6:	58e50513          	addi	a0,a0,1422 # 80017780 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	a16080e7          	jalr	-1514(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	37fd                	addiw	a5,a5,-1
    80003206:	0007871b          	sext.w	a4,a5
    8000320a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000320c:	eb05                	bnez	a4,8000323c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000320e:	68bc                	ld	a5,80(s1)
    80003210:	64b8                	ld	a4,72(s1)
    80003212:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003214:	64bc                	ld	a5,72(s1)
    80003216:	68b8                	ld	a4,80(s1)
    80003218:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000321a:	0001c797          	auipc	a5,0x1c
    8000321e:	56678793          	addi	a5,a5,1382 # 8001f780 <bcache+0x8000>
    80003222:	2b87b703          	ld	a4,696(a5)
    80003226:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003228:	0001c717          	auipc	a4,0x1c
    8000322c:	7c070713          	addi	a4,a4,1984 # 8001f9e8 <bcache+0x8268>
    80003230:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003232:	2b87b703          	ld	a4,696(a5)
    80003236:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003238:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000323c:	00014517          	auipc	a0,0x14
    80003240:	54450513          	addi	a0,a0,1348 # 80017780 <bcache>
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	a80080e7          	jalr	-1408(ra) # 80000cc4 <release>
}
    8000324c:	60e2                	ld	ra,24(sp)
    8000324e:	6442                	ld	s0,16(sp)
    80003250:	64a2                	ld	s1,8(sp)
    80003252:	6902                	ld	s2,0(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret
    panic("brelse");
    80003258:	00005517          	auipc	a0,0x5
    8000325c:	37850513          	addi	a0,a0,888 # 800085d0 <syscalls+0xe0>
    80003260:	ffffd097          	auipc	ra,0xffffd
    80003264:	2e8080e7          	jalr	744(ra) # 80000548 <panic>

0000000080003268 <bpin>:

void
bpin(struct buf *b) {
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003274:	00014517          	auipc	a0,0x14
    80003278:	50c50513          	addi	a0,a0,1292 # 80017780 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	994080e7          	jalr	-1644(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003284:	40bc                	lw	a5,64(s1)
    80003286:	2785                	addiw	a5,a5,1
    80003288:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000328a:	00014517          	auipc	a0,0x14
    8000328e:	4f650513          	addi	a0,a0,1270 # 80017780 <bcache>
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	a32080e7          	jalr	-1486(ra) # 80000cc4 <release>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	64a2                	ld	s1,8(sp)
    800032a0:	6105                	addi	sp,sp,32
    800032a2:	8082                	ret

00000000800032a4 <bunpin>:

void
bunpin(struct buf *b) {
    800032a4:	1101                	addi	sp,sp,-32
    800032a6:	ec06                	sd	ra,24(sp)
    800032a8:	e822                	sd	s0,16(sp)
    800032aa:	e426                	sd	s1,8(sp)
    800032ac:	1000                	addi	s0,sp,32
    800032ae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b0:	00014517          	auipc	a0,0x14
    800032b4:	4d050513          	addi	a0,a0,1232 # 80017780 <bcache>
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	958080e7          	jalr	-1704(ra) # 80000c10 <acquire>
  b->refcnt--;
    800032c0:	40bc                	lw	a5,64(s1)
    800032c2:	37fd                	addiw	a5,a5,-1
    800032c4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032c6:	00014517          	auipc	a0,0x14
    800032ca:	4ba50513          	addi	a0,a0,1210 # 80017780 <bcache>
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	9f6080e7          	jalr	-1546(ra) # 80000cc4 <release>
}
    800032d6:	60e2                	ld	ra,24(sp)
    800032d8:	6442                	ld	s0,16(sp)
    800032da:	64a2                	ld	s1,8(sp)
    800032dc:	6105                	addi	sp,sp,32
    800032de:	8082                	ret

00000000800032e0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032e0:	1101                	addi	sp,sp,-32
    800032e2:	ec06                	sd	ra,24(sp)
    800032e4:	e822                	sd	s0,16(sp)
    800032e6:	e426                	sd	s1,8(sp)
    800032e8:	e04a                	sd	s2,0(sp)
    800032ea:	1000                	addi	s0,sp,32
    800032ec:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032ee:	00d5d59b          	srliw	a1,a1,0xd
    800032f2:	0001d797          	auipc	a5,0x1d
    800032f6:	b6a7a783          	lw	a5,-1174(a5) # 8001fe5c <sb+0x1c>
    800032fa:	9dbd                	addw	a1,a1,a5
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	d9e080e7          	jalr	-610(ra) # 8000309a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003304:	0074f713          	andi	a4,s1,7
    80003308:	4785                	li	a5,1
    8000330a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000330e:	14ce                	slli	s1,s1,0x33
    80003310:	90d9                	srli	s1,s1,0x36
    80003312:	00950733          	add	a4,a0,s1
    80003316:	05874703          	lbu	a4,88(a4)
    8000331a:	00e7f6b3          	and	a3,a5,a4
    8000331e:	c69d                	beqz	a3,8000334c <bfree+0x6c>
    80003320:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003322:	94aa                	add	s1,s1,a0
    80003324:	fff7c793          	not	a5,a5
    80003328:	8ff9                	and	a5,a5,a4
    8000332a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000332e:	00001097          	auipc	ra,0x1
    80003332:	104080e7          	jalr	260(ra) # 80004432 <log_write>
  brelse(bp);
    80003336:	854a                	mv	a0,s2
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	e92080e7          	jalr	-366(ra) # 800031ca <brelse>
}
    80003340:	60e2                	ld	ra,24(sp)
    80003342:	6442                	ld	s0,16(sp)
    80003344:	64a2                	ld	s1,8(sp)
    80003346:	6902                	ld	s2,0(sp)
    80003348:	6105                	addi	sp,sp,32
    8000334a:	8082                	ret
    panic("freeing free block");
    8000334c:	00005517          	auipc	a0,0x5
    80003350:	28c50513          	addi	a0,a0,652 # 800085d8 <syscalls+0xe8>
    80003354:	ffffd097          	auipc	ra,0xffffd
    80003358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>

000000008000335c <balloc>:
{
    8000335c:	711d                	addi	sp,sp,-96
    8000335e:	ec86                	sd	ra,88(sp)
    80003360:	e8a2                	sd	s0,80(sp)
    80003362:	e4a6                	sd	s1,72(sp)
    80003364:	e0ca                	sd	s2,64(sp)
    80003366:	fc4e                	sd	s3,56(sp)
    80003368:	f852                	sd	s4,48(sp)
    8000336a:	f456                	sd	s5,40(sp)
    8000336c:	f05a                	sd	s6,32(sp)
    8000336e:	ec5e                	sd	s7,24(sp)
    80003370:	e862                	sd	s8,16(sp)
    80003372:	e466                	sd	s9,8(sp)
    80003374:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003376:	0001d797          	auipc	a5,0x1d
    8000337a:	ace7a783          	lw	a5,-1330(a5) # 8001fe44 <sb+0x4>
    8000337e:	cbd1                	beqz	a5,80003412 <balloc+0xb6>
    80003380:	8baa                	mv	s7,a0
    80003382:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003384:	0001db17          	auipc	s6,0x1d
    80003388:	abcb0b13          	addi	s6,s6,-1348 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000338c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000338e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003390:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003392:	6c89                	lui	s9,0x2
    80003394:	a831                	j	800033b0 <balloc+0x54>
    brelse(bp);
    80003396:	854a                	mv	a0,s2
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	e32080e7          	jalr	-462(ra) # 800031ca <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033a0:	015c87bb          	addw	a5,s9,s5
    800033a4:	00078a9b          	sext.w	s5,a5
    800033a8:	004b2703          	lw	a4,4(s6)
    800033ac:	06eaf363          	bgeu	s5,a4,80003412 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033b0:	41fad79b          	sraiw	a5,s5,0x1f
    800033b4:	0137d79b          	srliw	a5,a5,0x13
    800033b8:	015787bb          	addw	a5,a5,s5
    800033bc:	40d7d79b          	sraiw	a5,a5,0xd
    800033c0:	01cb2583          	lw	a1,28(s6)
    800033c4:	9dbd                	addw	a1,a1,a5
    800033c6:	855e                	mv	a0,s7
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	cd2080e7          	jalr	-814(ra) # 8000309a <bread>
    800033d0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d2:	004b2503          	lw	a0,4(s6)
    800033d6:	000a849b          	sext.w	s1,s5
    800033da:	8662                	mv	a2,s8
    800033dc:	faa4fde3          	bgeu	s1,a0,80003396 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033e0:	41f6579b          	sraiw	a5,a2,0x1f
    800033e4:	01d7d69b          	srliw	a3,a5,0x1d
    800033e8:	00c6873b          	addw	a4,a3,a2
    800033ec:	00777793          	andi	a5,a4,7
    800033f0:	9f95                	subw	a5,a5,a3
    800033f2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033f6:	4037571b          	sraiw	a4,a4,0x3
    800033fa:	00e906b3          	add	a3,s2,a4
    800033fe:	0586c683          	lbu	a3,88(a3)
    80003402:	00d7f5b3          	and	a1,a5,a3
    80003406:	cd91                	beqz	a1,80003422 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003408:	2605                	addiw	a2,a2,1
    8000340a:	2485                	addiw	s1,s1,1
    8000340c:	fd4618e3          	bne	a2,s4,800033dc <balloc+0x80>
    80003410:	b759                	j	80003396 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	1de50513          	addi	a0,a0,478 # 800085f0 <syscalls+0x100>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	12e080e7          	jalr	302(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003422:	974a                	add	a4,a4,s2
    80003424:	8fd5                	or	a5,a5,a3
    80003426:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	006080e7          	jalr	6(ra) # 80004432 <log_write>
        brelse(bp);
    80003434:	854a                	mv	a0,s2
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	d94080e7          	jalr	-620(ra) # 800031ca <brelse>
  bp = bread(dev, bno);
    8000343e:	85a6                	mv	a1,s1
    80003440:	855e                	mv	a0,s7
    80003442:	00000097          	auipc	ra,0x0
    80003446:	c58080e7          	jalr	-936(ra) # 8000309a <bread>
    8000344a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000344c:	40000613          	li	a2,1024
    80003450:	4581                	li	a1,0
    80003452:	05850513          	addi	a0,a0,88
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	8b6080e7          	jalr	-1866(ra) # 80000d0c <memset>
  log_write(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	00001097          	auipc	ra,0x1
    80003464:	fd2080e7          	jalr	-46(ra) # 80004432 <log_write>
  brelse(bp);
    80003468:	854a                	mv	a0,s2
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	d60080e7          	jalr	-672(ra) # 800031ca <brelse>
}
    80003472:	8526                	mv	a0,s1
    80003474:	60e6                	ld	ra,88(sp)
    80003476:	6446                	ld	s0,80(sp)
    80003478:	64a6                	ld	s1,72(sp)
    8000347a:	6906                	ld	s2,64(sp)
    8000347c:	79e2                	ld	s3,56(sp)
    8000347e:	7a42                	ld	s4,48(sp)
    80003480:	7aa2                	ld	s5,40(sp)
    80003482:	7b02                	ld	s6,32(sp)
    80003484:	6be2                	ld	s7,24(sp)
    80003486:	6c42                	ld	s8,16(sp)
    80003488:	6ca2                	ld	s9,8(sp)
    8000348a:	6125                	addi	sp,sp,96
    8000348c:	8082                	ret

000000008000348e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000348e:	7179                	addi	sp,sp,-48
    80003490:	f406                	sd	ra,40(sp)
    80003492:	f022                	sd	s0,32(sp)
    80003494:	ec26                	sd	s1,24(sp)
    80003496:	e84a                	sd	s2,16(sp)
    80003498:	e44e                	sd	s3,8(sp)
    8000349a:	e052                	sd	s4,0(sp)
    8000349c:	1800                	addi	s0,sp,48
    8000349e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034a0:	47ad                	li	a5,11
    800034a2:	04b7fe63          	bgeu	a5,a1,800034fe <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034a6:	ff45849b          	addiw	s1,a1,-12
    800034aa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034ae:	0ff00793          	li	a5,255
    800034b2:	0ae7e363          	bltu	a5,a4,80003558 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034b6:	08052583          	lw	a1,128(a0)
    800034ba:	c5ad                	beqz	a1,80003524 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034bc:	00092503          	lw	a0,0(s2)
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	bda080e7          	jalr	-1062(ra) # 8000309a <bread>
    800034c8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034ca:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034ce:	02049593          	slli	a1,s1,0x20
    800034d2:	9181                	srli	a1,a1,0x20
    800034d4:	058a                	slli	a1,a1,0x2
    800034d6:	00b784b3          	add	s1,a5,a1
    800034da:	0004a983          	lw	s3,0(s1)
    800034de:	04098d63          	beqz	s3,80003538 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034e2:	8552                	mv	a0,s4
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	ce6080e7          	jalr	-794(ra) # 800031ca <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034ec:	854e                	mv	a0,s3
    800034ee:	70a2                	ld	ra,40(sp)
    800034f0:	7402                	ld	s0,32(sp)
    800034f2:	64e2                	ld	s1,24(sp)
    800034f4:	6942                	ld	s2,16(sp)
    800034f6:	69a2                	ld	s3,8(sp)
    800034f8:	6a02                	ld	s4,0(sp)
    800034fa:	6145                	addi	sp,sp,48
    800034fc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034fe:	02059493          	slli	s1,a1,0x20
    80003502:	9081                	srli	s1,s1,0x20
    80003504:	048a                	slli	s1,s1,0x2
    80003506:	94aa                	add	s1,s1,a0
    80003508:	0504a983          	lw	s3,80(s1)
    8000350c:	fe0990e3          	bnez	s3,800034ec <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003510:	4108                	lw	a0,0(a0)
    80003512:	00000097          	auipc	ra,0x0
    80003516:	e4a080e7          	jalr	-438(ra) # 8000335c <balloc>
    8000351a:	0005099b          	sext.w	s3,a0
    8000351e:	0534a823          	sw	s3,80(s1)
    80003522:	b7e9                	j	800034ec <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003524:	4108                	lw	a0,0(a0)
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	e36080e7          	jalr	-458(ra) # 8000335c <balloc>
    8000352e:	0005059b          	sext.w	a1,a0
    80003532:	08b92023          	sw	a1,128(s2)
    80003536:	b759                	j	800034bc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003538:	00092503          	lw	a0,0(s2)
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	e20080e7          	jalr	-480(ra) # 8000335c <balloc>
    80003544:	0005099b          	sext.w	s3,a0
    80003548:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000354c:	8552                	mv	a0,s4
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	ee4080e7          	jalr	-284(ra) # 80004432 <log_write>
    80003556:	b771                	j	800034e2 <bmap+0x54>
  panic("bmap: out of range");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	0b050513          	addi	a0,a0,176 # 80008608 <syscalls+0x118>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fe8080e7          	jalr	-24(ra) # 80000548 <panic>

0000000080003568 <iget>:
{
    80003568:	7179                	addi	sp,sp,-48
    8000356a:	f406                	sd	ra,40(sp)
    8000356c:	f022                	sd	s0,32(sp)
    8000356e:	ec26                	sd	s1,24(sp)
    80003570:	e84a                	sd	s2,16(sp)
    80003572:	e44e                	sd	s3,8(sp)
    80003574:	e052                	sd	s4,0(sp)
    80003576:	1800                	addi	s0,sp,48
    80003578:	89aa                	mv	s3,a0
    8000357a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000357c:	0001d517          	auipc	a0,0x1d
    80003580:	8e450513          	addi	a0,a0,-1820 # 8001fe60 <icache>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	68c080e7          	jalr	1676(ra) # 80000c10 <acquire>
  empty = 0;
    8000358c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000358e:	0001d497          	auipc	s1,0x1d
    80003592:	8ea48493          	addi	s1,s1,-1814 # 8001fe78 <icache+0x18>
    80003596:	0001e697          	auipc	a3,0x1e
    8000359a:	37268693          	addi	a3,a3,882 # 80021908 <log>
    8000359e:	a039                	j	800035ac <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035a0:	02090b63          	beqz	s2,800035d6 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035a4:	08848493          	addi	s1,s1,136
    800035a8:	02d48a63          	beq	s1,a3,800035dc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035ac:	449c                	lw	a5,8(s1)
    800035ae:	fef059e3          	blez	a5,800035a0 <iget+0x38>
    800035b2:	4098                	lw	a4,0(s1)
    800035b4:	ff3716e3          	bne	a4,s3,800035a0 <iget+0x38>
    800035b8:	40d8                	lw	a4,4(s1)
    800035ba:	ff4713e3          	bne	a4,s4,800035a0 <iget+0x38>
      ip->ref++;
    800035be:	2785                	addiw	a5,a5,1
    800035c0:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800035c2:	0001d517          	auipc	a0,0x1d
    800035c6:	89e50513          	addi	a0,a0,-1890 # 8001fe60 <icache>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	6fa080e7          	jalr	1786(ra) # 80000cc4 <release>
      return ip;
    800035d2:	8926                	mv	s2,s1
    800035d4:	a03d                	j	80003602 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d6:	f7f9                	bnez	a5,800035a4 <iget+0x3c>
    800035d8:	8926                	mv	s2,s1
    800035da:	b7e9                	j	800035a4 <iget+0x3c>
  if(empty == 0)
    800035dc:	02090c63          	beqz	s2,80003614 <iget+0xac>
  ip->dev = dev;
    800035e0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035e4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035e8:	4785                	li	a5,1
    800035ea:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035ee:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035f2:	0001d517          	auipc	a0,0x1d
    800035f6:	86e50513          	addi	a0,a0,-1938 # 8001fe60 <icache>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	6ca080e7          	jalr	1738(ra) # 80000cc4 <release>
}
    80003602:	854a                	mv	a0,s2
    80003604:	70a2                	ld	ra,40(sp)
    80003606:	7402                	ld	s0,32(sp)
    80003608:	64e2                	ld	s1,24(sp)
    8000360a:	6942                	ld	s2,16(sp)
    8000360c:	69a2                	ld	s3,8(sp)
    8000360e:	6a02                	ld	s4,0(sp)
    80003610:	6145                	addi	sp,sp,48
    80003612:	8082                	ret
    panic("iget: no inodes");
    80003614:	00005517          	auipc	a0,0x5
    80003618:	00c50513          	addi	a0,a0,12 # 80008620 <syscalls+0x130>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>

0000000080003624 <fsinit>:
fsinit(int dev) {
    80003624:	7179                	addi	sp,sp,-48
    80003626:	f406                	sd	ra,40(sp)
    80003628:	f022                	sd	s0,32(sp)
    8000362a:	ec26                	sd	s1,24(sp)
    8000362c:	e84a                	sd	s2,16(sp)
    8000362e:	e44e                	sd	s3,8(sp)
    80003630:	1800                	addi	s0,sp,48
    80003632:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003634:	4585                	li	a1,1
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	a64080e7          	jalr	-1436(ra) # 8000309a <bread>
    8000363e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003640:	0001d997          	auipc	s3,0x1d
    80003644:	80098993          	addi	s3,s3,-2048 # 8001fe40 <sb>
    80003648:	02000613          	li	a2,32
    8000364c:	05850593          	addi	a1,a0,88
    80003650:	854e                	mv	a0,s3
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	71a080e7          	jalr	1818(ra) # 80000d6c <memmove>
  brelse(bp);
    8000365a:	8526                	mv	a0,s1
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	b6e080e7          	jalr	-1170(ra) # 800031ca <brelse>
  if(sb.magic != FSMAGIC)
    80003664:	0009a703          	lw	a4,0(s3)
    80003668:	102037b7          	lui	a5,0x10203
    8000366c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003670:	02f71263          	bne	a4,a5,80003694 <fsinit+0x70>
  initlog(dev, &sb);
    80003674:	0001c597          	auipc	a1,0x1c
    80003678:	7cc58593          	addi	a1,a1,1996 # 8001fe40 <sb>
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	b3c080e7          	jalr	-1220(ra) # 800041ba <initlog>
}
    80003686:	70a2                	ld	ra,40(sp)
    80003688:	7402                	ld	s0,32(sp)
    8000368a:	64e2                	ld	s1,24(sp)
    8000368c:	6942                	ld	s2,16(sp)
    8000368e:	69a2                	ld	s3,8(sp)
    80003690:	6145                	addi	sp,sp,48
    80003692:	8082                	ret
    panic("invalid file system");
    80003694:	00005517          	auipc	a0,0x5
    80003698:	f9c50513          	addi	a0,a0,-100 # 80008630 <syscalls+0x140>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	eac080e7          	jalr	-340(ra) # 80000548 <panic>

00000000800036a4 <iinit>:
{
    800036a4:	7179                	addi	sp,sp,-48
    800036a6:	f406                	sd	ra,40(sp)
    800036a8:	f022                	sd	s0,32(sp)
    800036aa:	ec26                	sd	s1,24(sp)
    800036ac:	e84a                	sd	s2,16(sp)
    800036ae:	e44e                	sd	s3,8(sp)
    800036b0:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036b2:	00005597          	auipc	a1,0x5
    800036b6:	f9658593          	addi	a1,a1,-106 # 80008648 <syscalls+0x158>
    800036ba:	0001c517          	auipc	a0,0x1c
    800036be:	7a650513          	addi	a0,a0,1958 # 8001fe60 <icache>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	4be080e7          	jalr	1214(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036ca:	0001c497          	auipc	s1,0x1c
    800036ce:	7be48493          	addi	s1,s1,1982 # 8001fe88 <icache+0x28>
    800036d2:	0001e997          	auipc	s3,0x1e
    800036d6:	24698993          	addi	s3,s3,582 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800036da:	00005917          	auipc	s2,0x5
    800036de:	f7690913          	addi	s2,s2,-138 # 80008650 <syscalls+0x160>
    800036e2:	85ca                	mv	a1,s2
    800036e4:	8526                	mv	a0,s1
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	e3a080e7          	jalr	-454(ra) # 80004520 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036ee:	08848493          	addi	s1,s1,136
    800036f2:	ff3498e3          	bne	s1,s3,800036e2 <iinit+0x3e>
}
    800036f6:	70a2                	ld	ra,40(sp)
    800036f8:	7402                	ld	s0,32(sp)
    800036fa:	64e2                	ld	s1,24(sp)
    800036fc:	6942                	ld	s2,16(sp)
    800036fe:	69a2                	ld	s3,8(sp)
    80003700:	6145                	addi	sp,sp,48
    80003702:	8082                	ret

0000000080003704 <ialloc>:
{
    80003704:	715d                	addi	sp,sp,-80
    80003706:	e486                	sd	ra,72(sp)
    80003708:	e0a2                	sd	s0,64(sp)
    8000370a:	fc26                	sd	s1,56(sp)
    8000370c:	f84a                	sd	s2,48(sp)
    8000370e:	f44e                	sd	s3,40(sp)
    80003710:	f052                	sd	s4,32(sp)
    80003712:	ec56                	sd	s5,24(sp)
    80003714:	e85a                	sd	s6,16(sp)
    80003716:	e45e                	sd	s7,8(sp)
    80003718:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000371a:	0001c717          	auipc	a4,0x1c
    8000371e:	73272703          	lw	a4,1842(a4) # 8001fe4c <sb+0xc>
    80003722:	4785                	li	a5,1
    80003724:	04e7fa63          	bgeu	a5,a4,80003778 <ialloc+0x74>
    80003728:	8aaa                	mv	s5,a0
    8000372a:	8bae                	mv	s7,a1
    8000372c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000372e:	0001ca17          	auipc	s4,0x1c
    80003732:	712a0a13          	addi	s4,s4,1810 # 8001fe40 <sb>
    80003736:	00048b1b          	sext.w	s6,s1
    8000373a:	0044d593          	srli	a1,s1,0x4
    8000373e:	018a2783          	lw	a5,24(s4)
    80003742:	9dbd                	addw	a1,a1,a5
    80003744:	8556                	mv	a0,s5
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	954080e7          	jalr	-1708(ra) # 8000309a <bread>
    8000374e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003750:	05850993          	addi	s3,a0,88
    80003754:	00f4f793          	andi	a5,s1,15
    80003758:	079a                	slli	a5,a5,0x6
    8000375a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000375c:	00099783          	lh	a5,0(s3)
    80003760:	c785                	beqz	a5,80003788 <ialloc+0x84>
    brelse(bp);
    80003762:	00000097          	auipc	ra,0x0
    80003766:	a68080e7          	jalr	-1432(ra) # 800031ca <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000376a:	0485                	addi	s1,s1,1
    8000376c:	00ca2703          	lw	a4,12(s4)
    80003770:	0004879b          	sext.w	a5,s1
    80003774:	fce7e1e3          	bltu	a5,a4,80003736 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	ee050513          	addi	a0,a0,-288 # 80008658 <syscalls+0x168>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dc8080e7          	jalr	-568(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003788:	04000613          	li	a2,64
    8000378c:	4581                	li	a1,0
    8000378e:	854e                	mv	a0,s3
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	57c080e7          	jalr	1404(ra) # 80000d0c <memset>
      dip->type = type;
    80003798:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000379c:	854a                	mv	a0,s2
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	c94080e7          	jalr	-876(ra) # 80004432 <log_write>
      brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	a22080e7          	jalr	-1502(ra) # 800031ca <brelse>
      return iget(dev, inum);
    800037b0:	85da                	mv	a1,s6
    800037b2:	8556                	mv	a0,s5
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	db4080e7          	jalr	-588(ra) # 80003568 <iget>
}
    800037bc:	60a6                	ld	ra,72(sp)
    800037be:	6406                	ld	s0,64(sp)
    800037c0:	74e2                	ld	s1,56(sp)
    800037c2:	7942                	ld	s2,48(sp)
    800037c4:	79a2                	ld	s3,40(sp)
    800037c6:	7a02                	ld	s4,32(sp)
    800037c8:	6ae2                	ld	s5,24(sp)
    800037ca:	6b42                	ld	s6,16(sp)
    800037cc:	6ba2                	ld	s7,8(sp)
    800037ce:	6161                	addi	sp,sp,80
    800037d0:	8082                	ret

00000000800037d2 <iupdate>:
{
    800037d2:	1101                	addi	sp,sp,-32
    800037d4:	ec06                	sd	ra,24(sp)
    800037d6:	e822                	sd	s0,16(sp)
    800037d8:	e426                	sd	s1,8(sp)
    800037da:	e04a                	sd	s2,0(sp)
    800037dc:	1000                	addi	s0,sp,32
    800037de:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e0:	415c                	lw	a5,4(a0)
    800037e2:	0047d79b          	srliw	a5,a5,0x4
    800037e6:	0001c597          	auipc	a1,0x1c
    800037ea:	6725a583          	lw	a1,1650(a1) # 8001fe58 <sb+0x18>
    800037ee:	9dbd                	addw	a1,a1,a5
    800037f0:	4108                	lw	a0,0(a0)
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	8a8080e7          	jalr	-1880(ra) # 8000309a <bread>
    800037fa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037fc:	05850793          	addi	a5,a0,88
    80003800:	40c8                	lw	a0,4(s1)
    80003802:	893d                	andi	a0,a0,15
    80003804:	051a                	slli	a0,a0,0x6
    80003806:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003808:	04449703          	lh	a4,68(s1)
    8000380c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003810:	04649703          	lh	a4,70(s1)
    80003814:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003818:	04849703          	lh	a4,72(s1)
    8000381c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003820:	04a49703          	lh	a4,74(s1)
    80003824:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003828:	44f8                	lw	a4,76(s1)
    8000382a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000382c:	03400613          	li	a2,52
    80003830:	05048593          	addi	a1,s1,80
    80003834:	0531                	addi	a0,a0,12
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	536080e7          	jalr	1334(ra) # 80000d6c <memmove>
  log_write(bp);
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	bf2080e7          	jalr	-1038(ra) # 80004432 <log_write>
  brelse(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	980080e7          	jalr	-1664(ra) # 800031ca <brelse>
}
    80003852:	60e2                	ld	ra,24(sp)
    80003854:	6442                	ld	s0,16(sp)
    80003856:	64a2                	ld	s1,8(sp)
    80003858:	6902                	ld	s2,0(sp)
    8000385a:	6105                	addi	sp,sp,32
    8000385c:	8082                	ret

000000008000385e <idup>:
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	e426                	sd	s1,8(sp)
    80003866:	1000                	addi	s0,sp,32
    80003868:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000386a:	0001c517          	auipc	a0,0x1c
    8000386e:	5f650513          	addi	a0,a0,1526 # 8001fe60 <icache>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	39e080e7          	jalr	926(ra) # 80000c10 <acquire>
  ip->ref++;
    8000387a:	449c                	lw	a5,8(s1)
    8000387c:	2785                	addiw	a5,a5,1
    8000387e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003880:	0001c517          	auipc	a0,0x1c
    80003884:	5e050513          	addi	a0,a0,1504 # 8001fe60 <icache>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	43c080e7          	jalr	1084(ra) # 80000cc4 <release>
}
    80003890:	8526                	mv	a0,s1
    80003892:	60e2                	ld	ra,24(sp)
    80003894:	6442                	ld	s0,16(sp)
    80003896:	64a2                	ld	s1,8(sp)
    80003898:	6105                	addi	sp,sp,32
    8000389a:	8082                	ret

000000008000389c <ilock>:
{
    8000389c:	1101                	addi	sp,sp,-32
    8000389e:	ec06                	sd	ra,24(sp)
    800038a0:	e822                	sd	s0,16(sp)
    800038a2:	e426                	sd	s1,8(sp)
    800038a4:	e04a                	sd	s2,0(sp)
    800038a6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038a8:	c115                	beqz	a0,800038cc <ilock+0x30>
    800038aa:	84aa                	mv	s1,a0
    800038ac:	451c                	lw	a5,8(a0)
    800038ae:	00f05f63          	blez	a5,800038cc <ilock+0x30>
  acquiresleep(&ip->lock);
    800038b2:	0541                	addi	a0,a0,16
    800038b4:	00001097          	auipc	ra,0x1
    800038b8:	ca6080e7          	jalr	-858(ra) # 8000455a <acquiresleep>
  if(ip->valid == 0){
    800038bc:	40bc                	lw	a5,64(s1)
    800038be:	cf99                	beqz	a5,800038dc <ilock+0x40>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6902                	ld	s2,0(sp)
    800038c8:	6105                	addi	sp,sp,32
    800038ca:	8082                	ret
    panic("ilock");
    800038cc:	00005517          	auipc	a0,0x5
    800038d0:	da450513          	addi	a0,a0,-604 # 80008670 <syscalls+0x180>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	c74080e7          	jalr	-908(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038dc:	40dc                	lw	a5,4(s1)
    800038de:	0047d79b          	srliw	a5,a5,0x4
    800038e2:	0001c597          	auipc	a1,0x1c
    800038e6:	5765a583          	lw	a1,1398(a1) # 8001fe58 <sb+0x18>
    800038ea:	9dbd                	addw	a1,a1,a5
    800038ec:	4088                	lw	a0,0(s1)
    800038ee:	fffff097          	auipc	ra,0xfffff
    800038f2:	7ac080e7          	jalr	1964(ra) # 8000309a <bread>
    800038f6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038f8:	05850593          	addi	a1,a0,88
    800038fc:	40dc                	lw	a5,4(s1)
    800038fe:	8bbd                	andi	a5,a5,15
    80003900:	079a                	slli	a5,a5,0x6
    80003902:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003904:	00059783          	lh	a5,0(a1)
    80003908:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000390c:	00259783          	lh	a5,2(a1)
    80003910:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003914:	00459783          	lh	a5,4(a1)
    80003918:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000391c:	00659783          	lh	a5,6(a1)
    80003920:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003924:	459c                	lw	a5,8(a1)
    80003926:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003928:	03400613          	li	a2,52
    8000392c:	05b1                	addi	a1,a1,12
    8000392e:	05048513          	addi	a0,s1,80
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	43a080e7          	jalr	1082(ra) # 80000d6c <memmove>
    brelse(bp);
    8000393a:	854a                	mv	a0,s2
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	88e080e7          	jalr	-1906(ra) # 800031ca <brelse>
    ip->valid = 1;
    80003944:	4785                	li	a5,1
    80003946:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003948:	04449783          	lh	a5,68(s1)
    8000394c:	fbb5                	bnez	a5,800038c0 <ilock+0x24>
      panic("ilock: no type");
    8000394e:	00005517          	auipc	a0,0x5
    80003952:	d2a50513          	addi	a0,a0,-726 # 80008678 <syscalls+0x188>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	bf2080e7          	jalr	-1038(ra) # 80000548 <panic>

000000008000395e <iunlock>:
{
    8000395e:	1101                	addi	sp,sp,-32
    80003960:	ec06                	sd	ra,24(sp)
    80003962:	e822                	sd	s0,16(sp)
    80003964:	e426                	sd	s1,8(sp)
    80003966:	e04a                	sd	s2,0(sp)
    80003968:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000396a:	c905                	beqz	a0,8000399a <iunlock+0x3c>
    8000396c:	84aa                	mv	s1,a0
    8000396e:	01050913          	addi	s2,a0,16
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	c80080e7          	jalr	-896(ra) # 800045f4 <holdingsleep>
    8000397c:	cd19                	beqz	a0,8000399a <iunlock+0x3c>
    8000397e:	449c                	lw	a5,8(s1)
    80003980:	00f05d63          	blez	a5,8000399a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003984:	854a                	mv	a0,s2
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	c2a080e7          	jalr	-982(ra) # 800045b0 <releasesleep>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6902                	ld	s2,0(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret
    panic("iunlock");
    8000399a:	00005517          	auipc	a0,0x5
    8000399e:	cee50513          	addi	a0,a0,-786 # 80008688 <syscalls+0x198>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	ba6080e7          	jalr	-1114(ra) # 80000548 <panic>

00000000800039aa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039aa:	7179                	addi	sp,sp,-48
    800039ac:	f406                	sd	ra,40(sp)
    800039ae:	f022                	sd	s0,32(sp)
    800039b0:	ec26                	sd	s1,24(sp)
    800039b2:	e84a                	sd	s2,16(sp)
    800039b4:	e44e                	sd	s3,8(sp)
    800039b6:	e052                	sd	s4,0(sp)
    800039b8:	1800                	addi	s0,sp,48
    800039ba:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039bc:	05050493          	addi	s1,a0,80
    800039c0:	08050913          	addi	s2,a0,128
    800039c4:	a021                	j	800039cc <itrunc+0x22>
    800039c6:	0491                	addi	s1,s1,4
    800039c8:	01248d63          	beq	s1,s2,800039e2 <itrunc+0x38>
    if(ip->addrs[i]){
    800039cc:	408c                	lw	a1,0(s1)
    800039ce:	dde5                	beqz	a1,800039c6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039d0:	0009a503          	lw	a0,0(s3)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	90c080e7          	jalr	-1780(ra) # 800032e0 <bfree>
      ip->addrs[i] = 0;
    800039dc:	0004a023          	sw	zero,0(s1)
    800039e0:	b7dd                	j	800039c6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039e2:	0809a583          	lw	a1,128(s3)
    800039e6:	e185                	bnez	a1,80003a06 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039e8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039ec:	854e                	mv	a0,s3
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	de4080e7          	jalr	-540(ra) # 800037d2 <iupdate>
}
    800039f6:	70a2                	ld	ra,40(sp)
    800039f8:	7402                	ld	s0,32(sp)
    800039fa:	64e2                	ld	s1,24(sp)
    800039fc:	6942                	ld	s2,16(sp)
    800039fe:	69a2                	ld	s3,8(sp)
    80003a00:	6a02                	ld	s4,0(sp)
    80003a02:	6145                	addi	sp,sp,48
    80003a04:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a06:	0009a503          	lw	a0,0(s3)
    80003a0a:	fffff097          	auipc	ra,0xfffff
    80003a0e:	690080e7          	jalr	1680(ra) # 8000309a <bread>
    80003a12:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a14:	05850493          	addi	s1,a0,88
    80003a18:	45850913          	addi	s2,a0,1112
    80003a1c:	a811                	j	80003a30 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a1e:	0009a503          	lw	a0,0(s3)
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	8be080e7          	jalr	-1858(ra) # 800032e0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a2a:	0491                	addi	s1,s1,4
    80003a2c:	01248563          	beq	s1,s2,80003a36 <itrunc+0x8c>
      if(a[j])
    80003a30:	408c                	lw	a1,0(s1)
    80003a32:	dde5                	beqz	a1,80003a2a <itrunc+0x80>
    80003a34:	b7ed                	j	80003a1e <itrunc+0x74>
    brelse(bp);
    80003a36:	8552                	mv	a0,s4
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	792080e7          	jalr	1938(ra) # 800031ca <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a40:	0809a583          	lw	a1,128(s3)
    80003a44:	0009a503          	lw	a0,0(s3)
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	898080e7          	jalr	-1896(ra) # 800032e0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a50:	0809a023          	sw	zero,128(s3)
    80003a54:	bf51                	j	800039e8 <itrunc+0x3e>

0000000080003a56 <iput>:
{
    80003a56:	1101                	addi	sp,sp,-32
    80003a58:	ec06                	sd	ra,24(sp)
    80003a5a:	e822                	sd	s0,16(sp)
    80003a5c:	e426                	sd	s1,8(sp)
    80003a5e:	e04a                	sd	s2,0(sp)
    80003a60:	1000                	addi	s0,sp,32
    80003a62:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a64:	0001c517          	auipc	a0,0x1c
    80003a68:	3fc50513          	addi	a0,a0,1020 # 8001fe60 <icache>
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	1a4080e7          	jalr	420(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a74:	4498                	lw	a4,8(s1)
    80003a76:	4785                	li	a5,1
    80003a78:	02f70363          	beq	a4,a5,80003a9e <iput+0x48>
  ip->ref--;
    80003a7c:	449c                	lw	a5,8(s1)
    80003a7e:	37fd                	addiw	a5,a5,-1
    80003a80:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a82:	0001c517          	auipc	a0,0x1c
    80003a86:	3de50513          	addi	a0,a0,990 # 8001fe60 <icache>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	23a080e7          	jalr	570(ra) # 80000cc4 <release>
}
    80003a92:	60e2                	ld	ra,24(sp)
    80003a94:	6442                	ld	s0,16(sp)
    80003a96:	64a2                	ld	s1,8(sp)
    80003a98:	6902                	ld	s2,0(sp)
    80003a9a:	6105                	addi	sp,sp,32
    80003a9c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a9e:	40bc                	lw	a5,64(s1)
    80003aa0:	dff1                	beqz	a5,80003a7c <iput+0x26>
    80003aa2:	04a49783          	lh	a5,74(s1)
    80003aa6:	fbf9                	bnez	a5,80003a7c <iput+0x26>
    acquiresleep(&ip->lock);
    80003aa8:	01048913          	addi	s2,s1,16
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	aac080e7          	jalr	-1364(ra) # 8000455a <acquiresleep>
    release(&icache.lock);
    80003ab6:	0001c517          	auipc	a0,0x1c
    80003aba:	3aa50513          	addi	a0,a0,938 # 8001fe60 <icache>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	206080e7          	jalr	518(ra) # 80000cc4 <release>
    itrunc(ip);
    80003ac6:	8526                	mv	a0,s1
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	ee2080e7          	jalr	-286(ra) # 800039aa <itrunc>
    ip->type = 0;
    80003ad0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ad4:	8526                	mv	a0,s1
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	cfc080e7          	jalr	-772(ra) # 800037d2 <iupdate>
    ip->valid = 0;
    80003ade:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	acc080e7          	jalr	-1332(ra) # 800045b0 <releasesleep>
    acquire(&icache.lock);
    80003aec:	0001c517          	auipc	a0,0x1c
    80003af0:	37450513          	addi	a0,a0,884 # 8001fe60 <icache>
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	11c080e7          	jalr	284(ra) # 80000c10 <acquire>
    80003afc:	b741                	j	80003a7c <iput+0x26>

0000000080003afe <iunlockput>:
{
    80003afe:	1101                	addi	sp,sp,-32
    80003b00:	ec06                	sd	ra,24(sp)
    80003b02:	e822                	sd	s0,16(sp)
    80003b04:	e426                	sd	s1,8(sp)
    80003b06:	1000                	addi	s0,sp,32
    80003b08:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	e54080e7          	jalr	-428(ra) # 8000395e <iunlock>
  iput(ip);
    80003b12:	8526                	mv	a0,s1
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	f42080e7          	jalr	-190(ra) # 80003a56 <iput>
}
    80003b1c:	60e2                	ld	ra,24(sp)
    80003b1e:	6442                	ld	s0,16(sp)
    80003b20:	64a2                	ld	s1,8(sp)
    80003b22:	6105                	addi	sp,sp,32
    80003b24:	8082                	ret

0000000080003b26 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b26:	1141                	addi	sp,sp,-16
    80003b28:	e422                	sd	s0,8(sp)
    80003b2a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b2c:	411c                	lw	a5,0(a0)
    80003b2e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b30:	415c                	lw	a5,4(a0)
    80003b32:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b34:	04451783          	lh	a5,68(a0)
    80003b38:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b3c:	04a51783          	lh	a5,74(a0)
    80003b40:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b44:	04c56783          	lwu	a5,76(a0)
    80003b48:	e99c                	sd	a5,16(a1)
}
    80003b4a:	6422                	ld	s0,8(sp)
    80003b4c:	0141                	addi	sp,sp,16
    80003b4e:	8082                	ret

0000000080003b50 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b50:	457c                	lw	a5,76(a0)
    80003b52:	0ed7e963          	bltu	a5,a3,80003c44 <readi+0xf4>
{
    80003b56:	7159                	addi	sp,sp,-112
    80003b58:	f486                	sd	ra,104(sp)
    80003b5a:	f0a2                	sd	s0,96(sp)
    80003b5c:	eca6                	sd	s1,88(sp)
    80003b5e:	e8ca                	sd	s2,80(sp)
    80003b60:	e4ce                	sd	s3,72(sp)
    80003b62:	e0d2                	sd	s4,64(sp)
    80003b64:	fc56                	sd	s5,56(sp)
    80003b66:	f85a                	sd	s6,48(sp)
    80003b68:	f45e                	sd	s7,40(sp)
    80003b6a:	f062                	sd	s8,32(sp)
    80003b6c:	ec66                	sd	s9,24(sp)
    80003b6e:	e86a                	sd	s10,16(sp)
    80003b70:	e46e                	sd	s11,8(sp)
    80003b72:	1880                	addi	s0,sp,112
    80003b74:	8baa                	mv	s7,a0
    80003b76:	8c2e                	mv	s8,a1
    80003b78:	8ab2                	mv	s5,a2
    80003b7a:	84b6                	mv	s1,a3
    80003b7c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b7e:	9f35                	addw	a4,a4,a3
    return 0;
    80003b80:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b82:	0ad76063          	bltu	a4,a3,80003c22 <readi+0xd2>
  if(off + n > ip->size)
    80003b86:	00e7f463          	bgeu	a5,a4,80003b8e <readi+0x3e>
    n = ip->size - off;
    80003b8a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b8e:	0a0b0963          	beqz	s6,80003c40 <readi+0xf0>
    80003b92:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b94:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b98:	5cfd                	li	s9,-1
    80003b9a:	a82d                	j	80003bd4 <readi+0x84>
    80003b9c:	020a1d93          	slli	s11,s4,0x20
    80003ba0:	020ddd93          	srli	s11,s11,0x20
    80003ba4:	05890613          	addi	a2,s2,88
    80003ba8:	86ee                	mv	a3,s11
    80003baa:	963a                	add	a2,a2,a4
    80003bac:	85d6                	mv	a1,s5
    80003bae:	8562                	mv	a0,s8
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	a64080e7          	jalr	-1436(ra) # 80002614 <either_copyout>
    80003bb8:	05950d63          	beq	a0,s9,80003c12 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	fffff097          	auipc	ra,0xfffff
    80003bc2:	60c080e7          	jalr	1548(ra) # 800031ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc6:	013a09bb          	addw	s3,s4,s3
    80003bca:	009a04bb          	addw	s1,s4,s1
    80003bce:	9aee                	add	s5,s5,s11
    80003bd0:	0569f763          	bgeu	s3,s6,80003c1e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bd4:	000ba903          	lw	s2,0(s7)
    80003bd8:	00a4d59b          	srliw	a1,s1,0xa
    80003bdc:	855e                	mv	a0,s7
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	8b0080e7          	jalr	-1872(ra) # 8000348e <bmap>
    80003be6:	0005059b          	sext.w	a1,a0
    80003bea:	854a                	mv	a0,s2
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	4ae080e7          	jalr	1198(ra) # 8000309a <bread>
    80003bf4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf6:	3ff4f713          	andi	a4,s1,1023
    80003bfa:	40ed07bb          	subw	a5,s10,a4
    80003bfe:	413b06bb          	subw	a3,s6,s3
    80003c02:	8a3e                	mv	s4,a5
    80003c04:	2781                	sext.w	a5,a5
    80003c06:	0006861b          	sext.w	a2,a3
    80003c0a:	f8f679e3          	bgeu	a2,a5,80003b9c <readi+0x4c>
    80003c0e:	8a36                	mv	s4,a3
    80003c10:	b771                	j	80003b9c <readi+0x4c>
      brelse(bp);
    80003c12:	854a                	mv	a0,s2
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	5b6080e7          	jalr	1462(ra) # 800031ca <brelse>
      tot = -1;
    80003c1c:	59fd                	li	s3,-1
  }
  return tot;
    80003c1e:	0009851b          	sext.w	a0,s3
}
    80003c22:	70a6                	ld	ra,104(sp)
    80003c24:	7406                	ld	s0,96(sp)
    80003c26:	64e6                	ld	s1,88(sp)
    80003c28:	6946                	ld	s2,80(sp)
    80003c2a:	69a6                	ld	s3,72(sp)
    80003c2c:	6a06                	ld	s4,64(sp)
    80003c2e:	7ae2                	ld	s5,56(sp)
    80003c30:	7b42                	ld	s6,48(sp)
    80003c32:	7ba2                	ld	s7,40(sp)
    80003c34:	7c02                	ld	s8,32(sp)
    80003c36:	6ce2                	ld	s9,24(sp)
    80003c38:	6d42                	ld	s10,16(sp)
    80003c3a:	6da2                	ld	s11,8(sp)
    80003c3c:	6165                	addi	sp,sp,112
    80003c3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c40:	89da                	mv	s3,s6
    80003c42:	bff1                	j	80003c1e <readi+0xce>
    return 0;
    80003c44:	4501                	li	a0,0
}
    80003c46:	8082                	ret

0000000080003c48 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c48:	457c                	lw	a5,76(a0)
    80003c4a:	10d7e763          	bltu	a5,a3,80003d58 <writei+0x110>
{
    80003c4e:	7159                	addi	sp,sp,-112
    80003c50:	f486                	sd	ra,104(sp)
    80003c52:	f0a2                	sd	s0,96(sp)
    80003c54:	eca6                	sd	s1,88(sp)
    80003c56:	e8ca                	sd	s2,80(sp)
    80003c58:	e4ce                	sd	s3,72(sp)
    80003c5a:	e0d2                	sd	s4,64(sp)
    80003c5c:	fc56                	sd	s5,56(sp)
    80003c5e:	f85a                	sd	s6,48(sp)
    80003c60:	f45e                	sd	s7,40(sp)
    80003c62:	f062                	sd	s8,32(sp)
    80003c64:	ec66                	sd	s9,24(sp)
    80003c66:	e86a                	sd	s10,16(sp)
    80003c68:	e46e                	sd	s11,8(sp)
    80003c6a:	1880                	addi	s0,sp,112
    80003c6c:	8baa                	mv	s7,a0
    80003c6e:	8c2e                	mv	s8,a1
    80003c70:	8ab2                	mv	s5,a2
    80003c72:	8936                	mv	s2,a3
    80003c74:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c76:	00e687bb          	addw	a5,a3,a4
    80003c7a:	0ed7e163          	bltu	a5,a3,80003d5c <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c7e:	00043737          	lui	a4,0x43
    80003c82:	0cf76f63          	bltu	a4,a5,80003d60 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c86:	0a0b0863          	beqz	s6,80003d36 <writei+0xee>
    80003c8a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c8c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c90:	5cfd                	li	s9,-1
    80003c92:	a091                	j	80003cd6 <writei+0x8e>
    80003c94:	02099d93          	slli	s11,s3,0x20
    80003c98:	020ddd93          	srli	s11,s11,0x20
    80003c9c:	05848513          	addi	a0,s1,88
    80003ca0:	86ee                	mv	a3,s11
    80003ca2:	8656                	mv	a2,s5
    80003ca4:	85e2                	mv	a1,s8
    80003ca6:	953a                	add	a0,a0,a4
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	9c2080e7          	jalr	-1598(ra) # 8000266a <either_copyin>
    80003cb0:	07950263          	beq	a0,s9,80003d14 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003cb4:	8526                	mv	a0,s1
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	77c080e7          	jalr	1916(ra) # 80004432 <log_write>
    brelse(bp);
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	fffff097          	auipc	ra,0xfffff
    80003cc4:	50a080e7          	jalr	1290(ra) # 800031ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc8:	01498a3b          	addw	s4,s3,s4
    80003ccc:	0129893b          	addw	s2,s3,s2
    80003cd0:	9aee                	add	s5,s5,s11
    80003cd2:	056a7763          	bgeu	s4,s6,80003d20 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cd6:	000ba483          	lw	s1,0(s7)
    80003cda:	00a9559b          	srliw	a1,s2,0xa
    80003cde:	855e                	mv	a0,s7
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	7ae080e7          	jalr	1966(ra) # 8000348e <bmap>
    80003ce8:	0005059b          	sext.w	a1,a0
    80003cec:	8526                	mv	a0,s1
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	3ac080e7          	jalr	940(ra) # 8000309a <bread>
    80003cf6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf8:	3ff97713          	andi	a4,s2,1023
    80003cfc:	40ed07bb          	subw	a5,s10,a4
    80003d00:	414b06bb          	subw	a3,s6,s4
    80003d04:	89be                	mv	s3,a5
    80003d06:	2781                	sext.w	a5,a5
    80003d08:	0006861b          	sext.w	a2,a3
    80003d0c:	f8f674e3          	bgeu	a2,a5,80003c94 <writei+0x4c>
    80003d10:	89b6                	mv	s3,a3
    80003d12:	b749                	j	80003c94 <writei+0x4c>
      brelse(bp);
    80003d14:	8526                	mv	a0,s1
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	4b4080e7          	jalr	1204(ra) # 800031ca <brelse>
      n = -1;
    80003d1e:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003d20:	04cba783          	lw	a5,76(s7)
    80003d24:	0127f463          	bgeu	a5,s2,80003d2c <writei+0xe4>
      ip->size = off;
    80003d28:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d2c:	855e                	mv	a0,s7
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	aa4080e7          	jalr	-1372(ra) # 800037d2 <iupdate>
  }

  return n;
    80003d36:	000b051b          	sext.w	a0,s6
}
    80003d3a:	70a6                	ld	ra,104(sp)
    80003d3c:	7406                	ld	s0,96(sp)
    80003d3e:	64e6                	ld	s1,88(sp)
    80003d40:	6946                	ld	s2,80(sp)
    80003d42:	69a6                	ld	s3,72(sp)
    80003d44:	6a06                	ld	s4,64(sp)
    80003d46:	7ae2                	ld	s5,56(sp)
    80003d48:	7b42                	ld	s6,48(sp)
    80003d4a:	7ba2                	ld	s7,40(sp)
    80003d4c:	7c02                	ld	s8,32(sp)
    80003d4e:	6ce2                	ld	s9,24(sp)
    80003d50:	6d42                	ld	s10,16(sp)
    80003d52:	6da2                	ld	s11,8(sp)
    80003d54:	6165                	addi	sp,sp,112
    80003d56:	8082                	ret
    return -1;
    80003d58:	557d                	li	a0,-1
}
    80003d5a:	8082                	ret
    return -1;
    80003d5c:	557d                	li	a0,-1
    80003d5e:	bff1                	j	80003d3a <writei+0xf2>
    return -1;
    80003d60:	557d                	li	a0,-1
    80003d62:	bfe1                	j	80003d3a <writei+0xf2>

0000000080003d64 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d64:	1141                	addi	sp,sp,-16
    80003d66:	e406                	sd	ra,8(sp)
    80003d68:	e022                	sd	s0,0(sp)
    80003d6a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d6c:	4639                	li	a2,14
    80003d6e:	ffffd097          	auipc	ra,0xffffd
    80003d72:	07a080e7          	jalr	122(ra) # 80000de8 <strncmp>
}
    80003d76:	60a2                	ld	ra,8(sp)
    80003d78:	6402                	ld	s0,0(sp)
    80003d7a:	0141                	addi	sp,sp,16
    80003d7c:	8082                	ret

0000000080003d7e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d7e:	7139                	addi	sp,sp,-64
    80003d80:	fc06                	sd	ra,56(sp)
    80003d82:	f822                	sd	s0,48(sp)
    80003d84:	f426                	sd	s1,40(sp)
    80003d86:	f04a                	sd	s2,32(sp)
    80003d88:	ec4e                	sd	s3,24(sp)
    80003d8a:	e852                	sd	s4,16(sp)
    80003d8c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d8e:	04451703          	lh	a4,68(a0)
    80003d92:	4785                	li	a5,1
    80003d94:	00f71a63          	bne	a4,a5,80003da8 <dirlookup+0x2a>
    80003d98:	892a                	mv	s2,a0
    80003d9a:	89ae                	mv	s3,a1
    80003d9c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9e:	457c                	lw	a5,76(a0)
    80003da0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003da2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da4:	e79d                	bnez	a5,80003dd2 <dirlookup+0x54>
    80003da6:	a8a5                	j	80003e1e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003da8:	00005517          	auipc	a0,0x5
    80003dac:	8e850513          	addi	a0,a0,-1816 # 80008690 <syscalls+0x1a0>
    80003db0:	ffffc097          	auipc	ra,0xffffc
    80003db4:	798080e7          	jalr	1944(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003db8:	00005517          	auipc	a0,0x5
    80003dbc:	8f050513          	addi	a0,a0,-1808 # 800086a8 <syscalls+0x1b8>
    80003dc0:	ffffc097          	auipc	ra,0xffffc
    80003dc4:	788080e7          	jalr	1928(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc8:	24c1                	addiw	s1,s1,16
    80003dca:	04c92783          	lw	a5,76(s2)
    80003dce:	04f4f763          	bgeu	s1,a5,80003e1c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd2:	4741                	li	a4,16
    80003dd4:	86a6                	mv	a3,s1
    80003dd6:	fc040613          	addi	a2,s0,-64
    80003dda:	4581                	li	a1,0
    80003ddc:	854a                	mv	a0,s2
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	d72080e7          	jalr	-654(ra) # 80003b50 <readi>
    80003de6:	47c1                	li	a5,16
    80003de8:	fcf518e3          	bne	a0,a5,80003db8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dec:	fc045783          	lhu	a5,-64(s0)
    80003df0:	dfe1                	beqz	a5,80003dc8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003df2:	fc240593          	addi	a1,s0,-62
    80003df6:	854e                	mv	a0,s3
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	f6c080e7          	jalr	-148(ra) # 80003d64 <namecmp>
    80003e00:	f561                	bnez	a0,80003dc8 <dirlookup+0x4a>
      if(poff)
    80003e02:	000a0463          	beqz	s4,80003e0a <dirlookup+0x8c>
        *poff = off;
    80003e06:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e0a:	fc045583          	lhu	a1,-64(s0)
    80003e0e:	00092503          	lw	a0,0(s2)
    80003e12:	fffff097          	auipc	ra,0xfffff
    80003e16:	756080e7          	jalr	1878(ra) # 80003568 <iget>
    80003e1a:	a011                	j	80003e1e <dirlookup+0xa0>
  return 0;
    80003e1c:	4501                	li	a0,0
}
    80003e1e:	70e2                	ld	ra,56(sp)
    80003e20:	7442                	ld	s0,48(sp)
    80003e22:	74a2                	ld	s1,40(sp)
    80003e24:	7902                	ld	s2,32(sp)
    80003e26:	69e2                	ld	s3,24(sp)
    80003e28:	6a42                	ld	s4,16(sp)
    80003e2a:	6121                	addi	sp,sp,64
    80003e2c:	8082                	ret

0000000080003e2e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e2e:	711d                	addi	sp,sp,-96
    80003e30:	ec86                	sd	ra,88(sp)
    80003e32:	e8a2                	sd	s0,80(sp)
    80003e34:	e4a6                	sd	s1,72(sp)
    80003e36:	e0ca                	sd	s2,64(sp)
    80003e38:	fc4e                	sd	s3,56(sp)
    80003e3a:	f852                	sd	s4,48(sp)
    80003e3c:	f456                	sd	s5,40(sp)
    80003e3e:	f05a                	sd	s6,32(sp)
    80003e40:	ec5e                	sd	s7,24(sp)
    80003e42:	e862                	sd	s8,16(sp)
    80003e44:	e466                	sd	s9,8(sp)
    80003e46:	1080                	addi	s0,sp,96
    80003e48:	84aa                	mv	s1,a0
    80003e4a:	8b2e                	mv	s6,a1
    80003e4c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e4e:	00054703          	lbu	a4,0(a0)
    80003e52:	02f00793          	li	a5,47
    80003e56:	02f70363          	beq	a4,a5,80003e7c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e5a:	ffffe097          	auipc	ra,0xffffe
    80003e5e:	d48080e7          	jalr	-696(ra) # 80001ba2 <myproc>
    80003e62:	15053503          	ld	a0,336(a0)
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	9f8080e7          	jalr	-1544(ra) # 8000385e <idup>
    80003e6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e70:	02f00913          	li	s2,47
  len = path - s;
    80003e74:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e76:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e78:	4c05                	li	s8,1
    80003e7a:	a865                	j	80003f32 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e7c:	4585                	li	a1,1
    80003e7e:	4505                	li	a0,1
    80003e80:	fffff097          	auipc	ra,0xfffff
    80003e84:	6e8080e7          	jalr	1768(ra) # 80003568 <iget>
    80003e88:	89aa                	mv	s3,a0
    80003e8a:	b7dd                	j	80003e70 <namex+0x42>
      iunlockput(ip);
    80003e8c:	854e                	mv	a0,s3
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	c70080e7          	jalr	-912(ra) # 80003afe <iunlockput>
      return 0;
    80003e96:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e98:	854e                	mv	a0,s3
    80003e9a:	60e6                	ld	ra,88(sp)
    80003e9c:	6446                	ld	s0,80(sp)
    80003e9e:	64a6                	ld	s1,72(sp)
    80003ea0:	6906                	ld	s2,64(sp)
    80003ea2:	79e2                	ld	s3,56(sp)
    80003ea4:	7a42                	ld	s4,48(sp)
    80003ea6:	7aa2                	ld	s5,40(sp)
    80003ea8:	7b02                	ld	s6,32(sp)
    80003eaa:	6be2                	ld	s7,24(sp)
    80003eac:	6c42                	ld	s8,16(sp)
    80003eae:	6ca2                	ld	s9,8(sp)
    80003eb0:	6125                	addi	sp,sp,96
    80003eb2:	8082                	ret
      iunlock(ip);
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	aa8080e7          	jalr	-1368(ra) # 8000395e <iunlock>
      return ip;
    80003ebe:	bfe9                	j	80003e98 <namex+0x6a>
      iunlockput(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	c3c080e7          	jalr	-964(ra) # 80003afe <iunlockput>
      return 0;
    80003eca:	89d2                	mv	s3,s4
    80003ecc:	b7f1                	j	80003e98 <namex+0x6a>
  len = path - s;
    80003ece:	40b48633          	sub	a2,s1,a1
    80003ed2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ed6:	094cd463          	bge	s9,s4,80003f5e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003eda:	4639                	li	a2,14
    80003edc:	8556                	mv	a0,s5
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	e8e080e7          	jalr	-370(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003ee6:	0004c783          	lbu	a5,0(s1)
    80003eea:	01279763          	bne	a5,s2,80003ef8 <namex+0xca>
    path++;
    80003eee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef0:	0004c783          	lbu	a5,0(s1)
    80003ef4:	ff278de3          	beq	a5,s2,80003eee <namex+0xc0>
    ilock(ip);
    80003ef8:	854e                	mv	a0,s3
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	9a2080e7          	jalr	-1630(ra) # 8000389c <ilock>
    if(ip->type != T_DIR){
    80003f02:	04499783          	lh	a5,68(s3)
    80003f06:	f98793e3          	bne	a5,s8,80003e8c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f0a:	000b0563          	beqz	s6,80003f14 <namex+0xe6>
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	d3cd                	beqz	a5,80003eb4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f14:	865e                	mv	a2,s7
    80003f16:	85d6                	mv	a1,s5
    80003f18:	854e                	mv	a0,s3
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	e64080e7          	jalr	-412(ra) # 80003d7e <dirlookup>
    80003f22:	8a2a                	mv	s4,a0
    80003f24:	dd51                	beqz	a0,80003ec0 <namex+0x92>
    iunlockput(ip);
    80003f26:	854e                	mv	a0,s3
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	bd6080e7          	jalr	-1066(ra) # 80003afe <iunlockput>
    ip = next;
    80003f30:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f32:	0004c783          	lbu	a5,0(s1)
    80003f36:	05279763          	bne	a5,s2,80003f84 <namex+0x156>
    path++;
    80003f3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f3c:	0004c783          	lbu	a5,0(s1)
    80003f40:	ff278de3          	beq	a5,s2,80003f3a <namex+0x10c>
  if(*path == 0)
    80003f44:	c79d                	beqz	a5,80003f72 <namex+0x144>
    path++;
    80003f46:	85a6                	mv	a1,s1
  len = path - s;
    80003f48:	8a5e                	mv	s4,s7
    80003f4a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f4c:	01278963          	beq	a5,s2,80003f5e <namex+0x130>
    80003f50:	dfbd                	beqz	a5,80003ece <namex+0xa0>
    path++;
    80003f52:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f54:	0004c783          	lbu	a5,0(s1)
    80003f58:	ff279ce3          	bne	a5,s2,80003f50 <namex+0x122>
    80003f5c:	bf8d                	j	80003ece <namex+0xa0>
    memmove(name, s, len);
    80003f5e:	2601                	sext.w	a2,a2
    80003f60:	8556                	mv	a0,s5
    80003f62:	ffffd097          	auipc	ra,0xffffd
    80003f66:	e0a080e7          	jalr	-502(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003f6a:	9a56                	add	s4,s4,s5
    80003f6c:	000a0023          	sb	zero,0(s4)
    80003f70:	bf9d                	j	80003ee6 <namex+0xb8>
  if(nameiparent){
    80003f72:	f20b03e3          	beqz	s6,80003e98 <namex+0x6a>
    iput(ip);
    80003f76:	854e                	mv	a0,s3
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	ade080e7          	jalr	-1314(ra) # 80003a56 <iput>
    return 0;
    80003f80:	4981                	li	s3,0
    80003f82:	bf19                	j	80003e98 <namex+0x6a>
  if(*path == 0)
    80003f84:	d7fd                	beqz	a5,80003f72 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f86:	0004c783          	lbu	a5,0(s1)
    80003f8a:	85a6                	mv	a1,s1
    80003f8c:	b7d1                	j	80003f50 <namex+0x122>

0000000080003f8e <dirlink>:
{
    80003f8e:	7139                	addi	sp,sp,-64
    80003f90:	fc06                	sd	ra,56(sp)
    80003f92:	f822                	sd	s0,48(sp)
    80003f94:	f426                	sd	s1,40(sp)
    80003f96:	f04a                	sd	s2,32(sp)
    80003f98:	ec4e                	sd	s3,24(sp)
    80003f9a:	e852                	sd	s4,16(sp)
    80003f9c:	0080                	addi	s0,sp,64
    80003f9e:	892a                	mv	s2,a0
    80003fa0:	8a2e                	mv	s4,a1
    80003fa2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fa4:	4601                	li	a2,0
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	dd8080e7          	jalr	-552(ra) # 80003d7e <dirlookup>
    80003fae:	e93d                	bnez	a0,80004024 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb0:	04c92483          	lw	s1,76(s2)
    80003fb4:	c49d                	beqz	s1,80003fe2 <dirlink+0x54>
    80003fb6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb8:	4741                	li	a4,16
    80003fba:	86a6                	mv	a3,s1
    80003fbc:	fc040613          	addi	a2,s0,-64
    80003fc0:	4581                	li	a1,0
    80003fc2:	854a                	mv	a0,s2
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	b8c080e7          	jalr	-1140(ra) # 80003b50 <readi>
    80003fcc:	47c1                	li	a5,16
    80003fce:	06f51163          	bne	a0,a5,80004030 <dirlink+0xa2>
    if(de.inum == 0)
    80003fd2:	fc045783          	lhu	a5,-64(s0)
    80003fd6:	c791                	beqz	a5,80003fe2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd8:	24c1                	addiw	s1,s1,16
    80003fda:	04c92783          	lw	a5,76(s2)
    80003fde:	fcf4ede3          	bltu	s1,a5,80003fb8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fe2:	4639                	li	a2,14
    80003fe4:	85d2                	mv	a1,s4
    80003fe6:	fc240513          	addi	a0,s0,-62
    80003fea:	ffffd097          	auipc	ra,0xffffd
    80003fee:	e3a080e7          	jalr	-454(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003ff2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff6:	4741                	li	a4,16
    80003ff8:	86a6                	mv	a3,s1
    80003ffa:	fc040613          	addi	a2,s0,-64
    80003ffe:	4581                	li	a1,0
    80004000:	854a                	mv	a0,s2
    80004002:	00000097          	auipc	ra,0x0
    80004006:	c46080e7          	jalr	-954(ra) # 80003c48 <writei>
    8000400a:	872a                	mv	a4,a0
    8000400c:	47c1                	li	a5,16
  return 0;
    8000400e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004010:	02f71863          	bne	a4,a5,80004040 <dirlink+0xb2>
}
    80004014:	70e2                	ld	ra,56(sp)
    80004016:	7442                	ld	s0,48(sp)
    80004018:	74a2                	ld	s1,40(sp)
    8000401a:	7902                	ld	s2,32(sp)
    8000401c:	69e2                	ld	s3,24(sp)
    8000401e:	6a42                	ld	s4,16(sp)
    80004020:	6121                	addi	sp,sp,64
    80004022:	8082                	ret
    iput(ip);
    80004024:	00000097          	auipc	ra,0x0
    80004028:	a32080e7          	jalr	-1486(ra) # 80003a56 <iput>
    return -1;
    8000402c:	557d                	li	a0,-1
    8000402e:	b7dd                	j	80004014 <dirlink+0x86>
      panic("dirlink read");
    80004030:	00004517          	auipc	a0,0x4
    80004034:	68850513          	addi	a0,a0,1672 # 800086b8 <syscalls+0x1c8>
    80004038:	ffffc097          	auipc	ra,0xffffc
    8000403c:	510080e7          	jalr	1296(ra) # 80000548 <panic>
    panic("dirlink");
    80004040:	00004517          	auipc	a0,0x4
    80004044:	79850513          	addi	a0,a0,1944 # 800087d8 <syscalls+0x2e8>
    80004048:	ffffc097          	auipc	ra,0xffffc
    8000404c:	500080e7          	jalr	1280(ra) # 80000548 <panic>

0000000080004050 <namei>:

struct inode*
namei(char *path)
{
    80004050:	1101                	addi	sp,sp,-32
    80004052:	ec06                	sd	ra,24(sp)
    80004054:	e822                	sd	s0,16(sp)
    80004056:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004058:	fe040613          	addi	a2,s0,-32
    8000405c:	4581                	li	a1,0
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	dd0080e7          	jalr	-560(ra) # 80003e2e <namex>
}
    80004066:	60e2                	ld	ra,24(sp)
    80004068:	6442                	ld	s0,16(sp)
    8000406a:	6105                	addi	sp,sp,32
    8000406c:	8082                	ret

000000008000406e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000406e:	1141                	addi	sp,sp,-16
    80004070:	e406                	sd	ra,8(sp)
    80004072:	e022                	sd	s0,0(sp)
    80004074:	0800                	addi	s0,sp,16
    80004076:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004078:	4585                	li	a1,1
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	db4080e7          	jalr	-588(ra) # 80003e2e <namex>
}
    80004082:	60a2                	ld	ra,8(sp)
    80004084:	6402                	ld	s0,0(sp)
    80004086:	0141                	addi	sp,sp,16
    80004088:	8082                	ret

000000008000408a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000408a:	1101                	addi	sp,sp,-32
    8000408c:	ec06                	sd	ra,24(sp)
    8000408e:	e822                	sd	s0,16(sp)
    80004090:	e426                	sd	s1,8(sp)
    80004092:	e04a                	sd	s2,0(sp)
    80004094:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004096:	0001e917          	auipc	s2,0x1e
    8000409a:	87290913          	addi	s2,s2,-1934 # 80021908 <log>
    8000409e:	01892583          	lw	a1,24(s2)
    800040a2:	02892503          	lw	a0,40(s2)
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	ff4080e7          	jalr	-12(ra) # 8000309a <bread>
    800040ae:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040b0:	02c92683          	lw	a3,44(s2)
    800040b4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040b6:	02d05763          	blez	a3,800040e4 <write_head+0x5a>
    800040ba:	0001e797          	auipc	a5,0x1e
    800040be:	87e78793          	addi	a5,a5,-1922 # 80021938 <log+0x30>
    800040c2:	05c50713          	addi	a4,a0,92
    800040c6:	36fd                	addiw	a3,a3,-1
    800040c8:	1682                	slli	a3,a3,0x20
    800040ca:	9281                	srli	a3,a3,0x20
    800040cc:	068a                	slli	a3,a3,0x2
    800040ce:	0001e617          	auipc	a2,0x1e
    800040d2:	86e60613          	addi	a2,a2,-1938 # 8002193c <log+0x34>
    800040d6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040d8:	4390                	lw	a2,0(a5)
    800040da:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040dc:	0791                	addi	a5,a5,4
    800040de:	0711                	addi	a4,a4,4
    800040e0:	fed79ce3          	bne	a5,a3,800040d8 <write_head+0x4e>
  }
  bwrite(buf);
    800040e4:	8526                	mv	a0,s1
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	0a6080e7          	jalr	166(ra) # 8000318c <bwrite>
  brelse(buf);
    800040ee:	8526                	mv	a0,s1
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	0da080e7          	jalr	218(ra) # 800031ca <brelse>
}
    800040f8:	60e2                	ld	ra,24(sp)
    800040fa:	6442                	ld	s0,16(sp)
    800040fc:	64a2                	ld	s1,8(sp)
    800040fe:	6902                	ld	s2,0(sp)
    80004100:	6105                	addi	sp,sp,32
    80004102:	8082                	ret

0000000080004104 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004104:	0001e797          	auipc	a5,0x1e
    80004108:	8307a783          	lw	a5,-2000(a5) # 80021934 <log+0x2c>
    8000410c:	0af05663          	blez	a5,800041b8 <install_trans+0xb4>
{
    80004110:	7139                	addi	sp,sp,-64
    80004112:	fc06                	sd	ra,56(sp)
    80004114:	f822                	sd	s0,48(sp)
    80004116:	f426                	sd	s1,40(sp)
    80004118:	f04a                	sd	s2,32(sp)
    8000411a:	ec4e                	sd	s3,24(sp)
    8000411c:	e852                	sd	s4,16(sp)
    8000411e:	e456                	sd	s5,8(sp)
    80004120:	0080                	addi	s0,sp,64
    80004122:	0001ea97          	auipc	s5,0x1e
    80004126:	816a8a93          	addi	s5,s5,-2026 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000412a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000412c:	0001d997          	auipc	s3,0x1d
    80004130:	7dc98993          	addi	s3,s3,2012 # 80021908 <log>
    80004134:	0189a583          	lw	a1,24(s3)
    80004138:	014585bb          	addw	a1,a1,s4
    8000413c:	2585                	addiw	a1,a1,1
    8000413e:	0289a503          	lw	a0,40(s3)
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	f58080e7          	jalr	-168(ra) # 8000309a <bread>
    8000414a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000414c:	000aa583          	lw	a1,0(s5)
    80004150:	0289a503          	lw	a0,40(s3)
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	f46080e7          	jalr	-186(ra) # 8000309a <bread>
    8000415c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000415e:	40000613          	li	a2,1024
    80004162:	05890593          	addi	a1,s2,88
    80004166:	05850513          	addi	a0,a0,88
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	c02080e7          	jalr	-1022(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004172:	8526                	mv	a0,s1
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	018080e7          	jalr	24(ra) # 8000318c <bwrite>
    bunpin(dbuf);
    8000417c:	8526                	mv	a0,s1
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	126080e7          	jalr	294(ra) # 800032a4 <bunpin>
    brelse(lbuf);
    80004186:	854a                	mv	a0,s2
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	042080e7          	jalr	66(ra) # 800031ca <brelse>
    brelse(dbuf);
    80004190:	8526                	mv	a0,s1
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	038080e7          	jalr	56(ra) # 800031ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000419a:	2a05                	addiw	s4,s4,1
    8000419c:	0a91                	addi	s5,s5,4
    8000419e:	02c9a783          	lw	a5,44(s3)
    800041a2:	f8fa49e3          	blt	s4,a5,80004134 <install_trans+0x30>
}
    800041a6:	70e2                	ld	ra,56(sp)
    800041a8:	7442                	ld	s0,48(sp)
    800041aa:	74a2                	ld	s1,40(sp)
    800041ac:	7902                	ld	s2,32(sp)
    800041ae:	69e2                	ld	s3,24(sp)
    800041b0:	6a42                	ld	s4,16(sp)
    800041b2:	6aa2                	ld	s5,8(sp)
    800041b4:	6121                	addi	sp,sp,64
    800041b6:	8082                	ret
    800041b8:	8082                	ret

00000000800041ba <initlog>:
{
    800041ba:	7179                	addi	sp,sp,-48
    800041bc:	f406                	sd	ra,40(sp)
    800041be:	f022                	sd	s0,32(sp)
    800041c0:	ec26                	sd	s1,24(sp)
    800041c2:	e84a                	sd	s2,16(sp)
    800041c4:	e44e                	sd	s3,8(sp)
    800041c6:	1800                	addi	s0,sp,48
    800041c8:	892a                	mv	s2,a0
    800041ca:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041cc:	0001d497          	auipc	s1,0x1d
    800041d0:	73c48493          	addi	s1,s1,1852 # 80021908 <log>
    800041d4:	00004597          	auipc	a1,0x4
    800041d8:	4f458593          	addi	a1,a1,1268 # 800086c8 <syscalls+0x1d8>
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	9a2080e7          	jalr	-1630(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    800041e6:	0149a583          	lw	a1,20(s3)
    800041ea:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041ec:	0109a783          	lw	a5,16(s3)
    800041f0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041f2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041f6:	854a                	mv	a0,s2
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	ea2080e7          	jalr	-350(ra) # 8000309a <bread>
  log.lh.n = lh->n;
    80004200:	4d3c                	lw	a5,88(a0)
    80004202:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004204:	02f05563          	blez	a5,8000422e <initlog+0x74>
    80004208:	05c50713          	addi	a4,a0,92
    8000420c:	0001d697          	auipc	a3,0x1d
    80004210:	72c68693          	addi	a3,a3,1836 # 80021938 <log+0x30>
    80004214:	37fd                	addiw	a5,a5,-1
    80004216:	1782                	slli	a5,a5,0x20
    80004218:	9381                	srli	a5,a5,0x20
    8000421a:	078a                	slli	a5,a5,0x2
    8000421c:	06050613          	addi	a2,a0,96
    80004220:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004222:	4310                	lw	a2,0(a4)
    80004224:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004226:	0711                	addi	a4,a4,4
    80004228:	0691                	addi	a3,a3,4
    8000422a:	fef71ce3          	bne	a4,a5,80004222 <initlog+0x68>
  brelse(buf);
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	f9c080e7          	jalr	-100(ra) # 800031ca <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	ece080e7          	jalr	-306(ra) # 80004104 <install_trans>
  log.lh.n = 0;
    8000423e:	0001d797          	auipc	a5,0x1d
    80004242:	6e07ab23          	sw	zero,1782(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	e44080e7          	jalr	-444(ra) # 8000408a <write_head>
}
    8000424e:	70a2                	ld	ra,40(sp)
    80004250:	7402                	ld	s0,32(sp)
    80004252:	64e2                	ld	s1,24(sp)
    80004254:	6942                	ld	s2,16(sp)
    80004256:	69a2                	ld	s3,8(sp)
    80004258:	6145                	addi	sp,sp,48
    8000425a:	8082                	ret

000000008000425c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000425c:	1101                	addi	sp,sp,-32
    8000425e:	ec06                	sd	ra,24(sp)
    80004260:	e822                	sd	s0,16(sp)
    80004262:	e426                	sd	s1,8(sp)
    80004264:	e04a                	sd	s2,0(sp)
    80004266:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004268:	0001d517          	auipc	a0,0x1d
    8000426c:	6a050513          	addi	a0,a0,1696 # 80021908 <log>
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	9a0080e7          	jalr	-1632(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004278:	0001d497          	auipc	s1,0x1d
    8000427c:	69048493          	addi	s1,s1,1680 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004280:	4979                	li	s2,30
    80004282:	a039                	j	80004290 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004284:	85a6                	mv	a1,s1
    80004286:	8526                	mv	a0,s1
    80004288:	ffffe097          	auipc	ra,0xffffe
    8000428c:	12a080e7          	jalr	298(ra) # 800023b2 <sleep>
    if(log.committing){
    80004290:	50dc                	lw	a5,36(s1)
    80004292:	fbed                	bnez	a5,80004284 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004294:	509c                	lw	a5,32(s1)
    80004296:	0017871b          	addiw	a4,a5,1
    8000429a:	0007069b          	sext.w	a3,a4
    8000429e:	0027179b          	slliw	a5,a4,0x2
    800042a2:	9fb9                	addw	a5,a5,a4
    800042a4:	0017979b          	slliw	a5,a5,0x1
    800042a8:	54d8                	lw	a4,44(s1)
    800042aa:	9fb9                	addw	a5,a5,a4
    800042ac:	00f95963          	bge	s2,a5,800042be <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042b0:	85a6                	mv	a1,s1
    800042b2:	8526                	mv	a0,s1
    800042b4:	ffffe097          	auipc	ra,0xffffe
    800042b8:	0fe080e7          	jalr	254(ra) # 800023b2 <sleep>
    800042bc:	bfd1                	j	80004290 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042be:	0001d517          	auipc	a0,0x1d
    800042c2:	64a50513          	addi	a0,a0,1610 # 80021908 <log>
    800042c6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	9fc080e7          	jalr	-1540(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800042d0:	60e2                	ld	ra,24(sp)
    800042d2:	6442                	ld	s0,16(sp)
    800042d4:	64a2                	ld	s1,8(sp)
    800042d6:	6902                	ld	s2,0(sp)
    800042d8:	6105                	addi	sp,sp,32
    800042da:	8082                	ret

00000000800042dc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042dc:	7139                	addi	sp,sp,-64
    800042de:	fc06                	sd	ra,56(sp)
    800042e0:	f822                	sd	s0,48(sp)
    800042e2:	f426                	sd	s1,40(sp)
    800042e4:	f04a                	sd	s2,32(sp)
    800042e6:	ec4e                	sd	s3,24(sp)
    800042e8:	e852                	sd	s4,16(sp)
    800042ea:	e456                	sd	s5,8(sp)
    800042ec:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ee:	0001d497          	auipc	s1,0x1d
    800042f2:	61a48493          	addi	s1,s1,1562 # 80021908 <log>
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	918080e7          	jalr	-1768(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    80004300:	509c                	lw	a5,32(s1)
    80004302:	37fd                	addiw	a5,a5,-1
    80004304:	0007891b          	sext.w	s2,a5
    80004308:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000430a:	50dc                	lw	a5,36(s1)
    8000430c:	efb9                	bnez	a5,8000436a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000430e:	06091663          	bnez	s2,8000437a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004312:	0001d497          	auipc	s1,0x1d
    80004316:	5f648493          	addi	s1,s1,1526 # 80021908 <log>
    8000431a:	4785                	li	a5,1
    8000431c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000431e:	8526                	mv	a0,s1
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	9a4080e7          	jalr	-1628(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004328:	54dc                	lw	a5,44(s1)
    8000432a:	06f04763          	bgtz	a5,80004398 <end_op+0xbc>
    acquire(&log.lock);
    8000432e:	0001d497          	auipc	s1,0x1d
    80004332:	5da48493          	addi	s1,s1,1498 # 80021908 <log>
    80004336:	8526                	mv	a0,s1
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	8d8080e7          	jalr	-1832(ra) # 80000c10 <acquire>
    log.committing = 0;
    80004340:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004344:	8526                	mv	a0,s1
    80004346:	ffffe097          	auipc	ra,0xffffe
    8000434a:	1f2080e7          	jalr	498(ra) # 80002538 <wakeup>
    release(&log.lock);
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	974080e7          	jalr	-1676(ra) # 80000cc4 <release>
}
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	74a2                	ld	s1,40(sp)
    8000435e:	7902                	ld	s2,32(sp)
    80004360:	69e2                	ld	s3,24(sp)
    80004362:	6a42                	ld	s4,16(sp)
    80004364:	6aa2                	ld	s5,8(sp)
    80004366:	6121                	addi	sp,sp,64
    80004368:	8082                	ret
    panic("log.committing");
    8000436a:	00004517          	auipc	a0,0x4
    8000436e:	36650513          	addi	a0,a0,870 # 800086d0 <syscalls+0x1e0>
    80004372:	ffffc097          	auipc	ra,0xffffc
    80004376:	1d6080e7          	jalr	470(ra) # 80000548 <panic>
    wakeup(&log);
    8000437a:	0001d497          	auipc	s1,0x1d
    8000437e:	58e48493          	addi	s1,s1,1422 # 80021908 <log>
    80004382:	8526                	mv	a0,s1
    80004384:	ffffe097          	auipc	ra,0xffffe
    80004388:	1b4080e7          	jalr	436(ra) # 80002538 <wakeup>
  release(&log.lock);
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	936080e7          	jalr	-1738(ra) # 80000cc4 <release>
  if(do_commit){
    80004396:	b7c9                	j	80004358 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004398:	0001da97          	auipc	s5,0x1d
    8000439c:	5a0a8a93          	addi	s5,s5,1440 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043a0:	0001da17          	auipc	s4,0x1d
    800043a4:	568a0a13          	addi	s4,s4,1384 # 80021908 <log>
    800043a8:	018a2583          	lw	a1,24(s4)
    800043ac:	012585bb          	addw	a1,a1,s2
    800043b0:	2585                	addiw	a1,a1,1
    800043b2:	028a2503          	lw	a0,40(s4)
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	ce4080e7          	jalr	-796(ra) # 8000309a <bread>
    800043be:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043c0:	000aa583          	lw	a1,0(s5)
    800043c4:	028a2503          	lw	a0,40(s4)
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	cd2080e7          	jalr	-814(ra) # 8000309a <bread>
    800043d0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043d2:	40000613          	li	a2,1024
    800043d6:	05850593          	addi	a1,a0,88
    800043da:	05848513          	addi	a0,s1,88
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	98e080e7          	jalr	-1650(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800043e6:	8526                	mv	a0,s1
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	da4080e7          	jalr	-604(ra) # 8000318c <bwrite>
    brelse(from);
    800043f0:	854e                	mv	a0,s3
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	dd8080e7          	jalr	-552(ra) # 800031ca <brelse>
    brelse(to);
    800043fa:	8526                	mv	a0,s1
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	dce080e7          	jalr	-562(ra) # 800031ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004404:	2905                	addiw	s2,s2,1
    80004406:	0a91                	addi	s5,s5,4
    80004408:	02ca2783          	lw	a5,44(s4)
    8000440c:	f8f94ee3          	blt	s2,a5,800043a8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004410:	00000097          	auipc	ra,0x0
    80004414:	c7a080e7          	jalr	-902(ra) # 8000408a <write_head>
    install_trans(); // Now install writes to home locations
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	cec080e7          	jalr	-788(ra) # 80004104 <install_trans>
    log.lh.n = 0;
    80004420:	0001d797          	auipc	a5,0x1d
    80004424:	5007aa23          	sw	zero,1300(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	c62080e7          	jalr	-926(ra) # 8000408a <write_head>
    80004430:	bdfd                	j	8000432e <end_op+0x52>

0000000080004432 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004432:	1101                	addi	sp,sp,-32
    80004434:	ec06                	sd	ra,24(sp)
    80004436:	e822                	sd	s0,16(sp)
    80004438:	e426                	sd	s1,8(sp)
    8000443a:	e04a                	sd	s2,0(sp)
    8000443c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000443e:	0001d717          	auipc	a4,0x1d
    80004442:	4f672703          	lw	a4,1270(a4) # 80021934 <log+0x2c>
    80004446:	47f5                	li	a5,29
    80004448:	08e7c063          	blt	a5,a4,800044c8 <log_write+0x96>
    8000444c:	84aa                	mv	s1,a0
    8000444e:	0001d797          	auipc	a5,0x1d
    80004452:	4d67a783          	lw	a5,1238(a5) # 80021924 <log+0x1c>
    80004456:	37fd                	addiw	a5,a5,-1
    80004458:	06f75863          	bge	a4,a5,800044c8 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000445c:	0001d797          	auipc	a5,0x1d
    80004460:	4cc7a783          	lw	a5,1228(a5) # 80021928 <log+0x20>
    80004464:	06f05a63          	blez	a5,800044d8 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004468:	0001d917          	auipc	s2,0x1d
    8000446c:	4a090913          	addi	s2,s2,1184 # 80021908 <log>
    80004470:	854a                	mv	a0,s2
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	79e080e7          	jalr	1950(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000447a:	02c92603          	lw	a2,44(s2)
    8000447e:	06c05563          	blez	a2,800044e8 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004482:	44cc                	lw	a1,12(s1)
    80004484:	0001d717          	auipc	a4,0x1d
    80004488:	4b470713          	addi	a4,a4,1204 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000448e:	4314                	lw	a3,0(a4)
    80004490:	04b68d63          	beq	a3,a1,800044ea <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004494:	2785                	addiw	a5,a5,1
    80004496:	0711                	addi	a4,a4,4
    80004498:	fec79be3          	bne	a5,a2,8000448e <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000449c:	0621                	addi	a2,a2,8
    8000449e:	060a                	slli	a2,a2,0x2
    800044a0:	0001d797          	auipc	a5,0x1d
    800044a4:	46878793          	addi	a5,a5,1128 # 80021908 <log>
    800044a8:	963e                	add	a2,a2,a5
    800044aa:	44dc                	lw	a5,12(s1)
    800044ac:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044ae:	8526                	mv	a0,s1
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	db8080e7          	jalr	-584(ra) # 80003268 <bpin>
    log.lh.n++;
    800044b8:	0001d717          	auipc	a4,0x1d
    800044bc:	45070713          	addi	a4,a4,1104 # 80021908 <log>
    800044c0:	575c                	lw	a5,44(a4)
    800044c2:	2785                	addiw	a5,a5,1
    800044c4:	d75c                	sw	a5,44(a4)
    800044c6:	a83d                	j	80004504 <log_write+0xd2>
    panic("too big a transaction");
    800044c8:	00004517          	auipc	a0,0x4
    800044cc:	21850513          	addi	a0,a0,536 # 800086e0 <syscalls+0x1f0>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	078080e7          	jalr	120(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	22050513          	addi	a0,a0,544 # 800086f8 <syscalls+0x208>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	068080e7          	jalr	104(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044e8:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044ea:	00878713          	addi	a4,a5,8
    800044ee:	00271693          	slli	a3,a4,0x2
    800044f2:	0001d717          	auipc	a4,0x1d
    800044f6:	41670713          	addi	a4,a4,1046 # 80021908 <log>
    800044fa:	9736                	add	a4,a4,a3
    800044fc:	44d4                	lw	a3,12(s1)
    800044fe:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004500:	faf607e3          	beq	a2,a5,800044ae <log_write+0x7c>
  }
  release(&log.lock);
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	40450513          	addi	a0,a0,1028 # 80021908 <log>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	7b8080e7          	jalr	1976(ra) # 80000cc4 <release>
}
    80004514:	60e2                	ld	ra,24(sp)
    80004516:	6442                	ld	s0,16(sp)
    80004518:	64a2                	ld	s1,8(sp)
    8000451a:	6902                	ld	s2,0(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004520:	1101                	addi	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	e426                	sd	s1,8(sp)
    80004528:	e04a                	sd	s2,0(sp)
    8000452a:	1000                	addi	s0,sp,32
    8000452c:	84aa                	mv	s1,a0
    8000452e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004530:	00004597          	auipc	a1,0x4
    80004534:	1e858593          	addi	a1,a1,488 # 80008718 <syscalls+0x228>
    80004538:	0521                	addi	a0,a0,8
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	646080e7          	jalr	1606(ra) # 80000b80 <initlock>
  lk->name = name;
    80004542:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004546:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000454a:	0204a423          	sw	zero,40(s1)
}
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	64a2                	ld	s1,8(sp)
    80004554:	6902                	ld	s2,0(sp)
    80004556:	6105                	addi	sp,sp,32
    80004558:	8082                	ret

000000008000455a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000455a:	1101                	addi	sp,sp,-32
    8000455c:	ec06                	sd	ra,24(sp)
    8000455e:	e822                	sd	s0,16(sp)
    80004560:	e426                	sd	s1,8(sp)
    80004562:	e04a                	sd	s2,0(sp)
    80004564:	1000                	addi	s0,sp,32
    80004566:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004568:	00850913          	addi	s2,a0,8
    8000456c:	854a                	mv	a0,s2
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	6a2080e7          	jalr	1698(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004576:	409c                	lw	a5,0(s1)
    80004578:	cb89                	beqz	a5,8000458a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000457a:	85ca                	mv	a1,s2
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffe097          	auipc	ra,0xffffe
    80004582:	e34080e7          	jalr	-460(ra) # 800023b2 <sleep>
  while (lk->locked) {
    80004586:	409c                	lw	a5,0(s1)
    80004588:	fbed                	bnez	a5,8000457a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000458a:	4785                	li	a5,1
    8000458c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000458e:	ffffd097          	auipc	ra,0xffffd
    80004592:	614080e7          	jalr	1556(ra) # 80001ba2 <myproc>
    80004596:	5d1c                	lw	a5,56(a0)
    80004598:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000459a:	854a                	mv	a0,s2
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	728080e7          	jalr	1832(ra) # 80000cc4 <release>
}
    800045a4:	60e2                	ld	ra,24(sp)
    800045a6:	6442                	ld	s0,16(sp)
    800045a8:	64a2                	ld	s1,8(sp)
    800045aa:	6902                	ld	s2,0(sp)
    800045ac:	6105                	addi	sp,sp,32
    800045ae:	8082                	ret

00000000800045b0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b0:	1101                	addi	sp,sp,-32
    800045b2:	ec06                	sd	ra,24(sp)
    800045b4:	e822                	sd	s0,16(sp)
    800045b6:	e426                	sd	s1,8(sp)
    800045b8:	e04a                	sd	s2,0(sp)
    800045ba:	1000                	addi	s0,sp,32
    800045bc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045be:	00850913          	addi	s2,a0,8
    800045c2:	854a                	mv	a0,s2
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	64c080e7          	jalr	1612(ra) # 80000c10 <acquire>
  lk->locked = 0;
    800045cc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffe097          	auipc	ra,0xffffe
    800045da:	f62080e7          	jalr	-158(ra) # 80002538 <wakeup>
  release(&lk->lk);
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6e4080e7          	jalr	1764(ra) # 80000cc4 <release>
}
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6902                	ld	s2,0(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045f4:	7179                	addi	sp,sp,-48
    800045f6:	f406                	sd	ra,40(sp)
    800045f8:	f022                	sd	s0,32(sp)
    800045fa:	ec26                	sd	s1,24(sp)
    800045fc:	e84a                	sd	s2,16(sp)
    800045fe:	e44e                	sd	s3,8(sp)
    80004600:	1800                	addi	s0,sp,48
    80004602:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004604:	00850913          	addi	s2,a0,8
    80004608:	854a                	mv	a0,s2
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004612:	409c                	lw	a5,0(s1)
    80004614:	ef99                	bnez	a5,80004632 <holdingsleep+0x3e>
    80004616:	4481                	li	s1,0
  release(&lk->lk);
    80004618:	854a                	mv	a0,s2
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	6aa080e7          	jalr	1706(ra) # 80000cc4 <release>
  return r;
}
    80004622:	8526                	mv	a0,s1
    80004624:	70a2                	ld	ra,40(sp)
    80004626:	7402                	ld	s0,32(sp)
    80004628:	64e2                	ld	s1,24(sp)
    8000462a:	6942                	ld	s2,16(sp)
    8000462c:	69a2                	ld	s3,8(sp)
    8000462e:	6145                	addi	sp,sp,48
    80004630:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004632:	0284a983          	lw	s3,40(s1)
    80004636:	ffffd097          	auipc	ra,0xffffd
    8000463a:	56c080e7          	jalr	1388(ra) # 80001ba2 <myproc>
    8000463e:	5d04                	lw	s1,56(a0)
    80004640:	413484b3          	sub	s1,s1,s3
    80004644:	0014b493          	seqz	s1,s1
    80004648:	bfc1                	j	80004618 <holdingsleep+0x24>

000000008000464a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000464a:	1141                	addi	sp,sp,-16
    8000464c:	e406                	sd	ra,8(sp)
    8000464e:	e022                	sd	s0,0(sp)
    80004650:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004652:	00004597          	auipc	a1,0x4
    80004656:	0d658593          	addi	a1,a1,214 # 80008728 <syscalls+0x238>
    8000465a:	0001d517          	auipc	a0,0x1d
    8000465e:	3f650513          	addi	a0,a0,1014 # 80021a50 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	51e080e7          	jalr	1310(ra) # 80000b80 <initlock>
}
    8000466a:	60a2                	ld	ra,8(sp)
    8000466c:	6402                	ld	s0,0(sp)
    8000466e:	0141                	addi	sp,sp,16
    80004670:	8082                	ret

0000000080004672 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004672:	1101                	addi	sp,sp,-32
    80004674:	ec06                	sd	ra,24(sp)
    80004676:	e822                	sd	s0,16(sp)
    80004678:	e426                	sd	s1,8(sp)
    8000467a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000467c:	0001d517          	auipc	a0,0x1d
    80004680:	3d450513          	addi	a0,a0,980 # 80021a50 <ftable>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	58c080e7          	jalr	1420(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000468c:	0001d497          	auipc	s1,0x1d
    80004690:	3dc48493          	addi	s1,s1,988 # 80021a68 <ftable+0x18>
    80004694:	0001e717          	auipc	a4,0x1e
    80004698:	37470713          	addi	a4,a4,884 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    8000469c:	40dc                	lw	a5,4(s1)
    8000469e:	cf99                	beqz	a5,800046bc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a0:	02848493          	addi	s1,s1,40
    800046a4:	fee49ce3          	bne	s1,a4,8000469c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046a8:	0001d517          	auipc	a0,0x1d
    800046ac:	3a850513          	addi	a0,a0,936 # 80021a50 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	614080e7          	jalr	1556(ra) # 80000cc4 <release>
  return 0;
    800046b8:	4481                	li	s1,0
    800046ba:	a819                	j	800046d0 <filealloc+0x5e>
      f->ref = 1;
    800046bc:	4785                	li	a5,1
    800046be:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	39050513          	addi	a0,a0,912 # 80021a50 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5fc080e7          	jalr	1532(ra) # 80000cc4 <release>
}
    800046d0:	8526                	mv	a0,s1
    800046d2:	60e2                	ld	ra,24(sp)
    800046d4:	6442                	ld	s0,16(sp)
    800046d6:	64a2                	ld	s1,8(sp)
    800046d8:	6105                	addi	sp,sp,32
    800046da:	8082                	ret

00000000800046dc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046dc:	1101                	addi	sp,sp,-32
    800046de:	ec06                	sd	ra,24(sp)
    800046e0:	e822                	sd	s0,16(sp)
    800046e2:	e426                	sd	s1,8(sp)
    800046e4:	1000                	addi	s0,sp,32
    800046e6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	36850513          	addi	a0,a0,872 # 80021a50 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	520080e7          	jalr	1312(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800046f8:	40dc                	lw	a5,4(s1)
    800046fa:	02f05263          	blez	a5,8000471e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046fe:	2785                	addiw	a5,a5,1
    80004700:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	34e50513          	addi	a0,a0,846 # 80021a50 <ftable>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	5ba080e7          	jalr	1466(ra) # 80000cc4 <release>
  return f;
}
    80004712:	8526                	mv	a0,s1
    80004714:	60e2                	ld	ra,24(sp)
    80004716:	6442                	ld	s0,16(sp)
    80004718:	64a2                	ld	s1,8(sp)
    8000471a:	6105                	addi	sp,sp,32
    8000471c:	8082                	ret
    panic("filedup");
    8000471e:	00004517          	auipc	a0,0x4
    80004722:	01250513          	addi	a0,a0,18 # 80008730 <syscalls+0x240>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	e22080e7          	jalr	-478(ra) # 80000548 <panic>

000000008000472e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000472e:	7139                	addi	sp,sp,-64
    80004730:	fc06                	sd	ra,56(sp)
    80004732:	f822                	sd	s0,48(sp)
    80004734:	f426                	sd	s1,40(sp)
    80004736:	f04a                	sd	s2,32(sp)
    80004738:	ec4e                	sd	s3,24(sp)
    8000473a:	e852                	sd	s4,16(sp)
    8000473c:	e456                	sd	s5,8(sp)
    8000473e:	0080                	addi	s0,sp,64
    80004740:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004742:	0001d517          	auipc	a0,0x1d
    80004746:	30e50513          	addi	a0,a0,782 # 80021a50 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	4c6080e7          	jalr	1222(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004752:	40dc                	lw	a5,4(s1)
    80004754:	06f05163          	blez	a5,800047b6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004758:	37fd                	addiw	a5,a5,-1
    8000475a:	0007871b          	sext.w	a4,a5
    8000475e:	c0dc                	sw	a5,4(s1)
    80004760:	06e04363          	bgtz	a4,800047c6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004764:	0004a903          	lw	s2,0(s1)
    80004768:	0094ca83          	lbu	s5,9(s1)
    8000476c:	0104ba03          	ld	s4,16(s1)
    80004770:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004774:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004778:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000477c:	0001d517          	auipc	a0,0x1d
    80004780:	2d450513          	addi	a0,a0,724 # 80021a50 <ftable>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	540080e7          	jalr	1344(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    8000478c:	4785                	li	a5,1
    8000478e:	04f90d63          	beq	s2,a5,800047e8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004792:	3979                	addiw	s2,s2,-2
    80004794:	4785                	li	a5,1
    80004796:	0527e063          	bltu	a5,s2,800047d6 <fileclose+0xa8>
    begin_op();
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	ac2080e7          	jalr	-1342(ra) # 8000425c <begin_op>
    iput(ff.ip);
    800047a2:	854e                	mv	a0,s3
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	2b2080e7          	jalr	690(ra) # 80003a56 <iput>
    end_op();
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	b30080e7          	jalr	-1232(ra) # 800042dc <end_op>
    800047b4:	a00d                	j	800047d6 <fileclose+0xa8>
    panic("fileclose");
    800047b6:	00004517          	auipc	a0,0x4
    800047ba:	f8250513          	addi	a0,a0,-126 # 80008738 <syscalls+0x248>
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	d8a080e7          	jalr	-630(ra) # 80000548 <panic>
    release(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	28a50513          	addi	a0,a0,650 # 80021a50 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	4f6080e7          	jalr	1270(ra) # 80000cc4 <release>
  }
}
    800047d6:	70e2                	ld	ra,56(sp)
    800047d8:	7442                	ld	s0,48(sp)
    800047da:	74a2                	ld	s1,40(sp)
    800047dc:	7902                	ld	s2,32(sp)
    800047de:	69e2                	ld	s3,24(sp)
    800047e0:	6a42                	ld	s4,16(sp)
    800047e2:	6aa2                	ld	s5,8(sp)
    800047e4:	6121                	addi	sp,sp,64
    800047e6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047e8:	85d6                	mv	a1,s5
    800047ea:	8552                	mv	a0,s4
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	372080e7          	jalr	882(ra) # 80004b5e <pipeclose>
    800047f4:	b7cd                	j	800047d6 <fileclose+0xa8>

00000000800047f6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047f6:	715d                	addi	sp,sp,-80
    800047f8:	e486                	sd	ra,72(sp)
    800047fa:	e0a2                	sd	s0,64(sp)
    800047fc:	fc26                	sd	s1,56(sp)
    800047fe:	f84a                	sd	s2,48(sp)
    80004800:	f44e                	sd	s3,40(sp)
    80004802:	0880                	addi	s0,sp,80
    80004804:	84aa                	mv	s1,a0
    80004806:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004808:	ffffd097          	auipc	ra,0xffffd
    8000480c:	39a080e7          	jalr	922(ra) # 80001ba2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004810:	409c                	lw	a5,0(s1)
    80004812:	37f9                	addiw	a5,a5,-2
    80004814:	4705                	li	a4,1
    80004816:	04f76763          	bltu	a4,a5,80004864 <filestat+0x6e>
    8000481a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000481c:	6c88                	ld	a0,24(s1)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	07e080e7          	jalr	126(ra) # 8000389c <ilock>
    stati(f->ip, &st);
    80004826:	fb840593          	addi	a1,s0,-72
    8000482a:	6c88                	ld	a0,24(s1)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	2fa080e7          	jalr	762(ra) # 80003b26 <stati>
    iunlock(f->ip);
    80004834:	6c88                	ld	a0,24(s1)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	128080e7          	jalr	296(ra) # 8000395e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000483e:	46e1                	li	a3,24
    80004840:	fb840613          	addi	a2,s0,-72
    80004844:	85ce                	mv	a1,s3
    80004846:	05093503          	ld	a0,80(s2)
    8000484a:	ffffd097          	auipc	ra,0xffffd
    8000484e:	018080e7          	jalr	24(ra) # 80001862 <copyout>
    80004852:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004856:	60a6                	ld	ra,72(sp)
    80004858:	6406                	ld	s0,64(sp)
    8000485a:	74e2                	ld	s1,56(sp)
    8000485c:	7942                	ld	s2,48(sp)
    8000485e:	79a2                	ld	s3,40(sp)
    80004860:	6161                	addi	sp,sp,80
    80004862:	8082                	ret
  return -1;
    80004864:	557d                	li	a0,-1
    80004866:	bfc5                	j	80004856 <filestat+0x60>

0000000080004868 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004868:	7179                	addi	sp,sp,-48
    8000486a:	f406                	sd	ra,40(sp)
    8000486c:	f022                	sd	s0,32(sp)
    8000486e:	ec26                	sd	s1,24(sp)
    80004870:	e84a                	sd	s2,16(sp)
    80004872:	e44e                	sd	s3,8(sp)
    80004874:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004876:	00854783          	lbu	a5,8(a0)
    8000487a:	c3d5                	beqz	a5,8000491e <fileread+0xb6>
    8000487c:	84aa                	mv	s1,a0
    8000487e:	89ae                	mv	s3,a1
    80004880:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004882:	411c                	lw	a5,0(a0)
    80004884:	4705                	li	a4,1
    80004886:	04e78963          	beq	a5,a4,800048d8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000488a:	470d                	li	a4,3
    8000488c:	04e78d63          	beq	a5,a4,800048e6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004890:	4709                	li	a4,2
    80004892:	06e79e63          	bne	a5,a4,8000490e <fileread+0xa6>
    ilock(f->ip);
    80004896:	6d08                	ld	a0,24(a0)
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	004080e7          	jalr	4(ra) # 8000389c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048a0:	874a                	mv	a4,s2
    800048a2:	5094                	lw	a3,32(s1)
    800048a4:	864e                	mv	a2,s3
    800048a6:	4585                	li	a1,1
    800048a8:	6c88                	ld	a0,24(s1)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	2a6080e7          	jalr	678(ra) # 80003b50 <readi>
    800048b2:	892a                	mv	s2,a0
    800048b4:	00a05563          	blez	a0,800048be <fileread+0x56>
      f->off += r;
    800048b8:	509c                	lw	a5,32(s1)
    800048ba:	9fa9                	addw	a5,a5,a0
    800048bc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048be:	6c88                	ld	a0,24(s1)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	09e080e7          	jalr	158(ra) # 8000395e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048c8:	854a                	mv	a0,s2
    800048ca:	70a2                	ld	ra,40(sp)
    800048cc:	7402                	ld	s0,32(sp)
    800048ce:	64e2                	ld	s1,24(sp)
    800048d0:	6942                	ld	s2,16(sp)
    800048d2:	69a2                	ld	s3,8(sp)
    800048d4:	6145                	addi	sp,sp,48
    800048d6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048d8:	6908                	ld	a0,16(a0)
    800048da:	00000097          	auipc	ra,0x0
    800048de:	418080e7          	jalr	1048(ra) # 80004cf2 <piperead>
    800048e2:	892a                	mv	s2,a0
    800048e4:	b7d5                	j	800048c8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048e6:	02451783          	lh	a5,36(a0)
    800048ea:	03079693          	slli	a3,a5,0x30
    800048ee:	92c1                	srli	a3,a3,0x30
    800048f0:	4725                	li	a4,9
    800048f2:	02d76863          	bltu	a4,a3,80004922 <fileread+0xba>
    800048f6:	0792                	slli	a5,a5,0x4
    800048f8:	0001d717          	auipc	a4,0x1d
    800048fc:	0b870713          	addi	a4,a4,184 # 800219b0 <devsw>
    80004900:	97ba                	add	a5,a5,a4
    80004902:	639c                	ld	a5,0(a5)
    80004904:	c38d                	beqz	a5,80004926 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004906:	4505                	li	a0,1
    80004908:	9782                	jalr	a5
    8000490a:	892a                	mv	s2,a0
    8000490c:	bf75                	j	800048c8 <fileread+0x60>
    panic("fileread");
    8000490e:	00004517          	auipc	a0,0x4
    80004912:	e3a50513          	addi	a0,a0,-454 # 80008748 <syscalls+0x258>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
    return -1;
    8000491e:	597d                	li	s2,-1
    80004920:	b765                	j	800048c8 <fileread+0x60>
      return -1;
    80004922:	597d                	li	s2,-1
    80004924:	b755                	j	800048c8 <fileread+0x60>
    80004926:	597d                	li	s2,-1
    80004928:	b745                	j	800048c8 <fileread+0x60>

000000008000492a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000492a:	00954783          	lbu	a5,9(a0)
    8000492e:	14078563          	beqz	a5,80004a78 <filewrite+0x14e>
{
    80004932:	715d                	addi	sp,sp,-80
    80004934:	e486                	sd	ra,72(sp)
    80004936:	e0a2                	sd	s0,64(sp)
    80004938:	fc26                	sd	s1,56(sp)
    8000493a:	f84a                	sd	s2,48(sp)
    8000493c:	f44e                	sd	s3,40(sp)
    8000493e:	f052                	sd	s4,32(sp)
    80004940:	ec56                	sd	s5,24(sp)
    80004942:	e85a                	sd	s6,16(sp)
    80004944:	e45e                	sd	s7,8(sp)
    80004946:	e062                	sd	s8,0(sp)
    80004948:	0880                	addi	s0,sp,80
    8000494a:	892a                	mv	s2,a0
    8000494c:	8aae                	mv	s5,a1
    8000494e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004950:	411c                	lw	a5,0(a0)
    80004952:	4705                	li	a4,1
    80004954:	02e78263          	beq	a5,a4,80004978 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004958:	470d                	li	a4,3
    8000495a:	02e78563          	beq	a5,a4,80004984 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000495e:	4709                	li	a4,2
    80004960:	10e79463          	bne	a5,a4,80004a68 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004964:	0ec05e63          	blez	a2,80004a60 <filewrite+0x136>
    int i = 0;
    80004968:	4981                	li	s3,0
    8000496a:	6b05                	lui	s6,0x1
    8000496c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004970:	6b85                	lui	s7,0x1
    80004972:	c00b8b9b          	addiw	s7,s7,-1024
    80004976:	a851                	j	80004a0a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004978:	6908                	ld	a0,16(a0)
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	254080e7          	jalr	596(ra) # 80004bce <pipewrite>
    80004982:	a85d                	j	80004a38 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004984:	02451783          	lh	a5,36(a0)
    80004988:	03079693          	slli	a3,a5,0x30
    8000498c:	92c1                	srli	a3,a3,0x30
    8000498e:	4725                	li	a4,9
    80004990:	0ed76663          	bltu	a4,a3,80004a7c <filewrite+0x152>
    80004994:	0792                	slli	a5,a5,0x4
    80004996:	0001d717          	auipc	a4,0x1d
    8000499a:	01a70713          	addi	a4,a4,26 # 800219b0 <devsw>
    8000499e:	97ba                	add	a5,a5,a4
    800049a0:	679c                	ld	a5,8(a5)
    800049a2:	cff9                	beqz	a5,80004a80 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800049a4:	4505                	li	a0,1
    800049a6:	9782                	jalr	a5
    800049a8:	a841                	j	80004a38 <filewrite+0x10e>
    800049aa:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	8ae080e7          	jalr	-1874(ra) # 8000425c <begin_op>
      ilock(f->ip);
    800049b6:	01893503          	ld	a0,24(s2)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	ee2080e7          	jalr	-286(ra) # 8000389c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049c2:	8762                	mv	a4,s8
    800049c4:	02092683          	lw	a3,32(s2)
    800049c8:	01598633          	add	a2,s3,s5
    800049cc:	4585                	li	a1,1
    800049ce:	01893503          	ld	a0,24(s2)
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	276080e7          	jalr	630(ra) # 80003c48 <writei>
    800049da:	84aa                	mv	s1,a0
    800049dc:	02a05f63          	blez	a0,80004a1a <filewrite+0xf0>
        f->off += r;
    800049e0:	02092783          	lw	a5,32(s2)
    800049e4:	9fa9                	addw	a5,a5,a0
    800049e6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049ea:	01893503          	ld	a0,24(s2)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	f70080e7          	jalr	-144(ra) # 8000395e <iunlock>
      end_op();
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	8e6080e7          	jalr	-1818(ra) # 800042dc <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049fe:	049c1963          	bne	s8,s1,80004a50 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a02:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a06:	0349d663          	bge	s3,s4,80004a32 <filewrite+0x108>
      int n1 = n - i;
    80004a0a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a0e:	84be                	mv	s1,a5
    80004a10:	2781                	sext.w	a5,a5
    80004a12:	f8fb5ce3          	bge	s6,a5,800049aa <filewrite+0x80>
    80004a16:	84de                	mv	s1,s7
    80004a18:	bf49                	j	800049aa <filewrite+0x80>
      iunlock(f->ip);
    80004a1a:	01893503          	ld	a0,24(s2)
    80004a1e:	fffff097          	auipc	ra,0xfffff
    80004a22:	f40080e7          	jalr	-192(ra) # 8000395e <iunlock>
      end_op();
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	8b6080e7          	jalr	-1866(ra) # 800042dc <end_op>
      if(r < 0)
    80004a2e:	fc04d8e3          	bgez	s1,800049fe <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a32:	8552                	mv	a0,s4
    80004a34:	033a1863          	bne	s4,s3,80004a64 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a38:	60a6                	ld	ra,72(sp)
    80004a3a:	6406                	ld	s0,64(sp)
    80004a3c:	74e2                	ld	s1,56(sp)
    80004a3e:	7942                	ld	s2,48(sp)
    80004a40:	79a2                	ld	s3,40(sp)
    80004a42:	7a02                	ld	s4,32(sp)
    80004a44:	6ae2                	ld	s5,24(sp)
    80004a46:	6b42                	ld	s6,16(sp)
    80004a48:	6ba2                	ld	s7,8(sp)
    80004a4a:	6c02                	ld	s8,0(sp)
    80004a4c:	6161                	addi	sp,sp,80
    80004a4e:	8082                	ret
        panic("short filewrite");
    80004a50:	00004517          	auipc	a0,0x4
    80004a54:	d0850513          	addi	a0,a0,-760 # 80008758 <syscalls+0x268>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	af0080e7          	jalr	-1296(ra) # 80000548 <panic>
    int i = 0;
    80004a60:	4981                	li	s3,0
    80004a62:	bfc1                	j	80004a32 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a64:	557d                	li	a0,-1
    80004a66:	bfc9                	j	80004a38 <filewrite+0x10e>
    panic("filewrite");
    80004a68:	00004517          	auipc	a0,0x4
    80004a6c:	d0050513          	addi	a0,a0,-768 # 80008768 <syscalls+0x278>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	ad8080e7          	jalr	-1320(ra) # 80000548 <panic>
    return -1;
    80004a78:	557d                	li	a0,-1
}
    80004a7a:	8082                	ret
      return -1;
    80004a7c:	557d                	li	a0,-1
    80004a7e:	bf6d                	j	80004a38 <filewrite+0x10e>
    80004a80:	557d                	li	a0,-1
    80004a82:	bf5d                	j	80004a38 <filewrite+0x10e>

0000000080004a84 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a84:	7179                	addi	sp,sp,-48
    80004a86:	f406                	sd	ra,40(sp)
    80004a88:	f022                	sd	s0,32(sp)
    80004a8a:	ec26                	sd	s1,24(sp)
    80004a8c:	e84a                	sd	s2,16(sp)
    80004a8e:	e44e                	sd	s3,8(sp)
    80004a90:	e052                	sd	s4,0(sp)
    80004a92:	1800                	addi	s0,sp,48
    80004a94:	84aa                	mv	s1,a0
    80004a96:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a98:	0005b023          	sd	zero,0(a1)
    80004a9c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	bd2080e7          	jalr	-1070(ra) # 80004672 <filealloc>
    80004aa8:	e088                	sd	a0,0(s1)
    80004aaa:	c551                	beqz	a0,80004b36 <pipealloc+0xb2>
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	bc6080e7          	jalr	-1082(ra) # 80004672 <filealloc>
    80004ab4:	00aa3023          	sd	a0,0(s4)
    80004ab8:	c92d                	beqz	a0,80004b2a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	066080e7          	jalr	102(ra) # 80000b20 <kalloc>
    80004ac2:	892a                	mv	s2,a0
    80004ac4:	c125                	beqz	a0,80004b24 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ac6:	4985                	li	s3,1
    80004ac8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004acc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ad0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ad4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ad8:	00004597          	auipc	a1,0x4
    80004adc:	ca058593          	addi	a1,a1,-864 # 80008778 <syscalls+0x288>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	0a0080e7          	jalr	160(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004ae8:	609c                	ld	a5,0(s1)
    80004aea:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aee:	609c                	ld	a5,0(s1)
    80004af0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004af4:	609c                	ld	a5,0(s1)
    80004af6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004afa:	609c                	ld	a5,0(s1)
    80004afc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b00:	000a3783          	ld	a5,0(s4)
    80004b04:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b08:	000a3783          	ld	a5,0(s4)
    80004b0c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b10:	000a3783          	ld	a5,0(s4)
    80004b14:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b18:	000a3783          	ld	a5,0(s4)
    80004b1c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b20:	4501                	li	a0,0
    80004b22:	a025                	j	80004b4a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b24:	6088                	ld	a0,0(s1)
    80004b26:	e501                	bnez	a0,80004b2e <pipealloc+0xaa>
    80004b28:	a039                	j	80004b36 <pipealloc+0xb2>
    80004b2a:	6088                	ld	a0,0(s1)
    80004b2c:	c51d                	beqz	a0,80004b5a <pipealloc+0xd6>
    fileclose(*f0);
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	c00080e7          	jalr	-1024(ra) # 8000472e <fileclose>
  if(*f1)
    80004b36:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b3a:	557d                	li	a0,-1
  if(*f1)
    80004b3c:	c799                	beqz	a5,80004b4a <pipealloc+0xc6>
    fileclose(*f1);
    80004b3e:	853e                	mv	a0,a5
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	bee080e7          	jalr	-1042(ra) # 8000472e <fileclose>
  return -1;
    80004b48:	557d                	li	a0,-1
}
    80004b4a:	70a2                	ld	ra,40(sp)
    80004b4c:	7402                	ld	s0,32(sp)
    80004b4e:	64e2                	ld	s1,24(sp)
    80004b50:	6942                	ld	s2,16(sp)
    80004b52:	69a2                	ld	s3,8(sp)
    80004b54:	6a02                	ld	s4,0(sp)
    80004b56:	6145                	addi	sp,sp,48
    80004b58:	8082                	ret
  return -1;
    80004b5a:	557d                	li	a0,-1
    80004b5c:	b7fd                	j	80004b4a <pipealloc+0xc6>

0000000080004b5e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b5e:	1101                	addi	sp,sp,-32
    80004b60:	ec06                	sd	ra,24(sp)
    80004b62:	e822                	sd	s0,16(sp)
    80004b64:	e426                	sd	s1,8(sp)
    80004b66:	e04a                	sd	s2,0(sp)
    80004b68:	1000                	addi	s0,sp,32
    80004b6a:	84aa                	mv	s1,a0
    80004b6c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	0a2080e7          	jalr	162(ra) # 80000c10 <acquire>
  if(writable){
    80004b76:	02090d63          	beqz	s2,80004bb0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b7a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b7e:	21848513          	addi	a0,s1,536
    80004b82:	ffffe097          	auipc	ra,0xffffe
    80004b86:	9b6080e7          	jalr	-1610(ra) # 80002538 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b8a:	2204b783          	ld	a5,544(s1)
    80004b8e:	eb95                	bnez	a5,80004bc2 <pipeclose+0x64>
    release(&pi->lock);
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	132080e7          	jalr	306(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	e88080e7          	jalr	-376(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004ba4:	60e2                	ld	ra,24(sp)
    80004ba6:	6442                	ld	s0,16(sp)
    80004ba8:	64a2                	ld	s1,8(sp)
    80004baa:	6902                	ld	s2,0(sp)
    80004bac:	6105                	addi	sp,sp,32
    80004bae:	8082                	ret
    pi->readopen = 0;
    80004bb0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bb4:	21c48513          	addi	a0,s1,540
    80004bb8:	ffffe097          	auipc	ra,0xffffe
    80004bbc:	980080e7          	jalr	-1664(ra) # 80002538 <wakeup>
    80004bc0:	b7e9                	j	80004b8a <pipeclose+0x2c>
    release(&pi->lock);
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	100080e7          	jalr	256(ra) # 80000cc4 <release>
}
    80004bcc:	bfe1                	j	80004ba4 <pipeclose+0x46>

0000000080004bce <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bce:	7119                	addi	sp,sp,-128
    80004bd0:	fc86                	sd	ra,120(sp)
    80004bd2:	f8a2                	sd	s0,112(sp)
    80004bd4:	f4a6                	sd	s1,104(sp)
    80004bd6:	f0ca                	sd	s2,96(sp)
    80004bd8:	ecce                	sd	s3,88(sp)
    80004bda:	e8d2                	sd	s4,80(sp)
    80004bdc:	e4d6                	sd	s5,72(sp)
    80004bde:	e0da                	sd	s6,64(sp)
    80004be0:	fc5e                	sd	s7,56(sp)
    80004be2:	f862                	sd	s8,48(sp)
    80004be4:	f466                	sd	s9,40(sp)
    80004be6:	f06a                	sd	s10,32(sp)
    80004be8:	ec6e                	sd	s11,24(sp)
    80004bea:	0100                	addi	s0,sp,128
    80004bec:	84aa                	mv	s1,a0
    80004bee:	8cae                	mv	s9,a1
    80004bf0:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	fb0080e7          	jalr	-80(ra) # 80001ba2 <myproc>
    80004bfa:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	012080e7          	jalr	18(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004c06:	0d605963          	blez	s6,80004cd8 <pipewrite+0x10a>
    80004c0a:	89a6                	mv	s3,s1
    80004c0c:	3b7d                	addiw	s6,s6,-1
    80004c0e:	1b02                	slli	s6,s6,0x20
    80004c10:	020b5b13          	srli	s6,s6,0x20
    80004c14:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c16:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c1a:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c1e:	5dfd                	li	s11,-1
    80004c20:	000b8d1b          	sext.w	s10,s7
    80004c24:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c26:	2184a783          	lw	a5,536(s1)
    80004c2a:	21c4a703          	lw	a4,540(s1)
    80004c2e:	2007879b          	addiw	a5,a5,512
    80004c32:	02f71b63          	bne	a4,a5,80004c68 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004c36:	2204a783          	lw	a5,544(s1)
    80004c3a:	cbad                	beqz	a5,80004cac <pipewrite+0xde>
    80004c3c:	03092783          	lw	a5,48(s2)
    80004c40:	e7b5                	bnez	a5,80004cac <pipewrite+0xde>
      wakeup(&pi->nread);
    80004c42:	8556                	mv	a0,s5
    80004c44:	ffffe097          	auipc	ra,0xffffe
    80004c48:	8f4080e7          	jalr	-1804(ra) # 80002538 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c4c:	85ce                	mv	a1,s3
    80004c4e:	8552                	mv	a0,s4
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	762080e7          	jalr	1890(ra) # 800023b2 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c58:	2184a783          	lw	a5,536(s1)
    80004c5c:	21c4a703          	lw	a4,540(s1)
    80004c60:	2007879b          	addiw	a5,a5,512
    80004c64:	fcf709e3          	beq	a4,a5,80004c36 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c68:	4685                	li	a3,1
    80004c6a:	019b8633          	add	a2,s7,s9
    80004c6e:	f8f40593          	addi	a1,s0,-113
    80004c72:	05093503          	ld	a0,80(s2)
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	c78080e7          	jalr	-904(ra) # 800018ee <copyin>
    80004c7e:	05b50e63          	beq	a0,s11,80004cda <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c82:	21c4a783          	lw	a5,540(s1)
    80004c86:	0017871b          	addiw	a4,a5,1
    80004c8a:	20e4ae23          	sw	a4,540(s1)
    80004c8e:	1ff7f793          	andi	a5,a5,511
    80004c92:	97a6                	add	a5,a5,s1
    80004c94:	f8f44703          	lbu	a4,-113(s0)
    80004c98:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c9c:	001d0c1b          	addiw	s8,s10,1
    80004ca0:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004ca4:	036b8b63          	beq	s7,s6,80004cda <pipewrite+0x10c>
    80004ca8:	8bbe                	mv	s7,a5
    80004caa:	bf9d                	j	80004c20 <pipewrite+0x52>
        release(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	016080e7          	jalr	22(ra) # 80000cc4 <release>
        return -1;
    80004cb6:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004cb8:	8562                	mv	a0,s8
    80004cba:	70e6                	ld	ra,120(sp)
    80004cbc:	7446                	ld	s0,112(sp)
    80004cbe:	74a6                	ld	s1,104(sp)
    80004cc0:	7906                	ld	s2,96(sp)
    80004cc2:	69e6                	ld	s3,88(sp)
    80004cc4:	6a46                	ld	s4,80(sp)
    80004cc6:	6aa6                	ld	s5,72(sp)
    80004cc8:	6b06                	ld	s6,64(sp)
    80004cca:	7be2                	ld	s7,56(sp)
    80004ccc:	7c42                	ld	s8,48(sp)
    80004cce:	7ca2                	ld	s9,40(sp)
    80004cd0:	7d02                	ld	s10,32(sp)
    80004cd2:	6de2                	ld	s11,24(sp)
    80004cd4:	6109                	addi	sp,sp,128
    80004cd6:	8082                	ret
  for(i = 0; i < n; i++){
    80004cd8:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004cda:	21848513          	addi	a0,s1,536
    80004cde:	ffffe097          	auipc	ra,0xffffe
    80004ce2:	85a080e7          	jalr	-1958(ra) # 80002538 <wakeup>
  release(&pi->lock);
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	fdc080e7          	jalr	-36(ra) # 80000cc4 <release>
  return i;
    80004cf0:	b7e1                	j	80004cb8 <pipewrite+0xea>

0000000080004cf2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cf2:	715d                	addi	sp,sp,-80
    80004cf4:	e486                	sd	ra,72(sp)
    80004cf6:	e0a2                	sd	s0,64(sp)
    80004cf8:	fc26                	sd	s1,56(sp)
    80004cfa:	f84a                	sd	s2,48(sp)
    80004cfc:	f44e                	sd	s3,40(sp)
    80004cfe:	f052                	sd	s4,32(sp)
    80004d00:	ec56                	sd	s5,24(sp)
    80004d02:	e85a                	sd	s6,16(sp)
    80004d04:	0880                	addi	s0,sp,80
    80004d06:	84aa                	mv	s1,a0
    80004d08:	892e                	mv	s2,a1
    80004d0a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	e96080e7          	jalr	-362(ra) # 80001ba2 <myproc>
    80004d14:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d16:	8b26                	mv	s6,s1
    80004d18:	8526                	mv	a0,s1
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	ef6080e7          	jalr	-266(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d22:	2184a703          	lw	a4,536(s1)
    80004d26:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d2a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2e:	02f71463          	bne	a4,a5,80004d56 <piperead+0x64>
    80004d32:	2244a783          	lw	a5,548(s1)
    80004d36:	c385                	beqz	a5,80004d56 <piperead+0x64>
    if(pr->killed){
    80004d38:	030a2783          	lw	a5,48(s4)
    80004d3c:	ebc1                	bnez	a5,80004dcc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3e:	85da                	mv	a1,s6
    80004d40:	854e                	mv	a0,s3
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	670080e7          	jalr	1648(ra) # 800023b2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4a:	2184a703          	lw	a4,536(s1)
    80004d4e:	21c4a783          	lw	a5,540(s1)
    80004d52:	fef700e3          	beq	a4,a5,80004d32 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d56:	09505263          	blez	s5,80004dda <piperead+0xe8>
    80004d5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d5e:	2184a783          	lw	a5,536(s1)
    80004d62:	21c4a703          	lw	a4,540(s1)
    80004d66:	02f70d63          	beq	a4,a5,80004da0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d6a:	0017871b          	addiw	a4,a5,1
    80004d6e:	20e4ac23          	sw	a4,536(s1)
    80004d72:	1ff7f793          	andi	a5,a5,511
    80004d76:	97a6                	add	a5,a5,s1
    80004d78:	0187c783          	lbu	a5,24(a5)
    80004d7c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d80:	4685                	li	a3,1
    80004d82:	fbf40613          	addi	a2,s0,-65
    80004d86:	85ca                	mv	a1,s2
    80004d88:	050a3503          	ld	a0,80(s4)
    80004d8c:	ffffd097          	auipc	ra,0xffffd
    80004d90:	ad6080e7          	jalr	-1322(ra) # 80001862 <copyout>
    80004d94:	01650663          	beq	a0,s6,80004da0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d98:	2985                	addiw	s3,s3,1
    80004d9a:	0905                	addi	s2,s2,1
    80004d9c:	fd3a91e3          	bne	s5,s3,80004d5e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004da0:	21c48513          	addi	a0,s1,540
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	794080e7          	jalr	1940(ra) # 80002538 <wakeup>
  release(&pi->lock);
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	f16080e7          	jalr	-234(ra) # 80000cc4 <release>
  return i;
}
    80004db6:	854e                	mv	a0,s3
    80004db8:	60a6                	ld	ra,72(sp)
    80004dba:	6406                	ld	s0,64(sp)
    80004dbc:	74e2                	ld	s1,56(sp)
    80004dbe:	7942                	ld	s2,48(sp)
    80004dc0:	79a2                	ld	s3,40(sp)
    80004dc2:	7a02                	ld	s4,32(sp)
    80004dc4:	6ae2                	ld	s5,24(sp)
    80004dc6:	6b42                	ld	s6,16(sp)
    80004dc8:	6161                	addi	sp,sp,80
    80004dca:	8082                	ret
      release(&pi->lock);
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	ef6080e7          	jalr	-266(ra) # 80000cc4 <release>
      return -1;
    80004dd6:	59fd                	li	s3,-1
    80004dd8:	bff9                	j	80004db6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dda:	4981                	li	s3,0
    80004ddc:	b7d1                	j	80004da0 <piperead+0xae>

0000000080004dde <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dde:	df010113          	addi	sp,sp,-528
    80004de2:	20113423          	sd	ra,520(sp)
    80004de6:	20813023          	sd	s0,512(sp)
    80004dea:	ffa6                	sd	s1,504(sp)
    80004dec:	fbca                	sd	s2,496(sp)
    80004dee:	f7ce                	sd	s3,488(sp)
    80004df0:	f3d2                	sd	s4,480(sp)
    80004df2:	efd6                	sd	s5,472(sp)
    80004df4:	ebda                	sd	s6,464(sp)
    80004df6:	e7de                	sd	s7,456(sp)
    80004df8:	e3e2                	sd	s8,448(sp)
    80004dfa:	ff66                	sd	s9,440(sp)
    80004dfc:	fb6a                	sd	s10,432(sp)
    80004dfe:	f76e                	sd	s11,424(sp)
    80004e00:	0c00                	addi	s0,sp,528
    80004e02:	84aa                	mv	s1,a0
    80004e04:	dea43c23          	sd	a0,-520(s0)
    80004e08:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	d96080e7          	jalr	-618(ra) # 80001ba2 <myproc>
    80004e14:	892a                	mv	s2,a0

  begin_op();
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	446080e7          	jalr	1094(ra) # 8000425c <begin_op>

  if((ip = namei(path)) == 0){
    80004e1e:	8526                	mv	a0,s1
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	230080e7          	jalr	560(ra) # 80004050 <namei>
    80004e28:	c92d                	beqz	a0,80004e9a <exec+0xbc>
    80004e2a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	a70080e7          	jalr	-1424(ra) # 8000389c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e34:	04000713          	li	a4,64
    80004e38:	4681                	li	a3,0
    80004e3a:	e4840613          	addi	a2,s0,-440
    80004e3e:	4581                	li	a1,0
    80004e40:	8526                	mv	a0,s1
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	d0e080e7          	jalr	-754(ra) # 80003b50 <readi>
    80004e4a:	04000793          	li	a5,64
    80004e4e:	00f51a63          	bne	a0,a5,80004e62 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e52:	e4842703          	lw	a4,-440(s0)
    80004e56:	464c47b7          	lui	a5,0x464c4
    80004e5a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e5e:	04f70463          	beq	a4,a5,80004ea6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e62:	8526                	mv	a0,s1
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	c9a080e7          	jalr	-870(ra) # 80003afe <iunlockput>
    end_op();
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	470080e7          	jalr	1136(ra) # 800042dc <end_op>
  }
  return -1;
    80004e74:	557d                	li	a0,-1
}
    80004e76:	20813083          	ld	ra,520(sp)
    80004e7a:	20013403          	ld	s0,512(sp)
    80004e7e:	74fe                	ld	s1,504(sp)
    80004e80:	795e                	ld	s2,496(sp)
    80004e82:	79be                	ld	s3,488(sp)
    80004e84:	7a1e                	ld	s4,480(sp)
    80004e86:	6afe                	ld	s5,472(sp)
    80004e88:	6b5e                	ld	s6,464(sp)
    80004e8a:	6bbe                	ld	s7,456(sp)
    80004e8c:	6c1e                	ld	s8,448(sp)
    80004e8e:	7cfa                	ld	s9,440(sp)
    80004e90:	7d5a                	ld	s10,432(sp)
    80004e92:	7dba                	ld	s11,424(sp)
    80004e94:	21010113          	addi	sp,sp,528
    80004e98:	8082                	ret
    end_op();
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	442080e7          	jalr	1090(ra) # 800042dc <end_op>
    return -1;
    80004ea2:	557d                	li	a0,-1
    80004ea4:	bfc9                	j	80004e76 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ea6:	854a                	mv	a0,s2
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	dbe080e7          	jalr	-578(ra) # 80001c66 <proc_pagetable>
    80004eb0:	8baa                	mv	s7,a0
    80004eb2:	d945                	beqz	a0,80004e62 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb4:	e6842983          	lw	s3,-408(s0)
    80004eb8:	e8045783          	lhu	a5,-384(s0)
    80004ebc:	c7ad                	beqz	a5,80004f26 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ebe:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec0:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004ec2:	6c85                	lui	s9,0x1
    80004ec4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ec8:	def43823          	sd	a5,-528(s0)
    80004ecc:	a489                	j	8000510e <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ece:	00004517          	auipc	a0,0x4
    80004ed2:	8b250513          	addi	a0,a0,-1870 # 80008780 <syscalls+0x290>
    80004ed6:	ffffb097          	auipc	ra,0xffffb
    80004eda:	672080e7          	jalr	1650(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ede:	8756                	mv	a4,s5
    80004ee0:	012d86bb          	addw	a3,s11,s2
    80004ee4:	4581                	li	a1,0
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	c68080e7          	jalr	-920(ra) # 80003b50 <readi>
    80004ef0:	2501                	sext.w	a0,a0
    80004ef2:	1caa9563          	bne	s5,a0,800050bc <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    80004ef6:	6785                	lui	a5,0x1
    80004ef8:	0127893b          	addw	s2,a5,s2
    80004efc:	77fd                	lui	a5,0xfffff
    80004efe:	01478a3b          	addw	s4,a5,s4
    80004f02:	1f897d63          	bgeu	s2,s8,800050fc <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004f06:	02091593          	slli	a1,s2,0x20
    80004f0a:	9181                	srli	a1,a1,0x20
    80004f0c:	95ea                	add	a1,a1,s10
    80004f0e:	855e                	mv	a0,s7
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	3aa080e7          	jalr	938(ra) # 800012ba <walkaddr>
    80004f18:	862a                	mv	a2,a0
    if(pa == 0)
    80004f1a:	d955                	beqz	a0,80004ece <exec+0xf0>
      n = PGSIZE;
    80004f1c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f1e:	fd9a70e3          	bgeu	s4,s9,80004ede <exec+0x100>
      n = sz - i;
    80004f22:	8ad2                	mv	s5,s4
    80004f24:	bf6d                	j	80004ede <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f26:	4901                	li	s2,0
  iunlockput(ip);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	bd4080e7          	jalr	-1068(ra) # 80003afe <iunlockput>
  end_op();
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	3aa080e7          	jalr	938(ra) # 800042dc <end_op>
  p = myproc();
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	c68080e7          	jalr	-920(ra) # 80001ba2 <myproc>
    80004f42:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f44:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f48:	6785                	lui	a5,0x1
    80004f4a:	17fd                	addi	a5,a5,-1
    80004f4c:	993e                	add	s2,s2,a5
    80004f4e:	757d                	lui	a0,0xfffff
    80004f50:	00a977b3          	and	a5,s2,a0
    80004f54:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f58:	6609                	lui	a2,0x2
    80004f5a:	963e                	add	a2,a2,a5
    80004f5c:	85be                	mv	a1,a5
    80004f5e:	855e                	mv	a0,s7
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	6ce080e7          	jalr	1742(ra) # 8000162e <uvmalloc>
    80004f68:	8b2a                	mv	s6,a0
  ip = 0;
    80004f6a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f6c:	14050863          	beqz	a0,800050bc <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f70:	75f9                	lui	a1,0xffffe
    80004f72:	95aa                	add	a1,a1,a0
    80004f74:	855e                	mv	a0,s7
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	8ba080e7          	jalr	-1862(ra) # 80001830 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f7e:	7c7d                	lui	s8,0xfffff
    80004f80:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f82:	e0043783          	ld	a5,-512(s0)
    80004f86:	6388                	ld	a0,0(a5)
    80004f88:	c535                	beqz	a0,80004ff4 <exec+0x216>
    80004f8a:	e8840993          	addi	s3,s0,-376
    80004f8e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f92:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	f00080e7          	jalr	-256(ra) # 80000e94 <strlen>
    80004f9c:	2505                	addiw	a0,a0,1
    80004f9e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fa2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fa6:	13896f63          	bltu	s2,s8,800050e4 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004faa:	e0043d83          	ld	s11,-512(s0)
    80004fae:	000dba03          	ld	s4,0(s11)
    80004fb2:	8552                	mv	a0,s4
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	ee0080e7          	jalr	-288(ra) # 80000e94 <strlen>
    80004fbc:	0015069b          	addiw	a3,a0,1
    80004fc0:	8652                	mv	a2,s4
    80004fc2:	85ca                	mv	a1,s2
    80004fc4:	855e                	mv	a0,s7
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	89c080e7          	jalr	-1892(ra) # 80001862 <copyout>
    80004fce:	10054f63          	bltz	a0,800050ec <exec+0x30e>
    ustack[argc] = sp;
    80004fd2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fd6:	0485                	addi	s1,s1,1
    80004fd8:	008d8793          	addi	a5,s11,8
    80004fdc:	e0f43023          	sd	a5,-512(s0)
    80004fe0:	008db503          	ld	a0,8(s11)
    80004fe4:	c911                	beqz	a0,80004ff8 <exec+0x21a>
    if(argc >= MAXARG)
    80004fe6:	09a1                	addi	s3,s3,8
    80004fe8:	fb3c96e3          	bne	s9,s3,80004f94 <exec+0x1b6>
  sz = sz1;
    80004fec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff0:	4481                	li	s1,0
    80004ff2:	a0e9                	j	800050bc <exec+0x2de>
  sp = sz;
    80004ff4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ff8:	00349793          	slli	a5,s1,0x3
    80004ffc:	f9040713          	addi	a4,s0,-112
    80005000:	97ba                	add	a5,a5,a4
    80005002:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80005006:	00148693          	addi	a3,s1,1
    8000500a:	068e                	slli	a3,a3,0x3
    8000500c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005010:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005014:	01897663          	bgeu	s2,s8,80005020 <exec+0x242>
  sz = sz1;
    80005018:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501c:	4481                	li	s1,0
    8000501e:	a879                	j	800050bc <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005020:	e8840613          	addi	a2,s0,-376
    80005024:	85ca                	mv	a1,s2
    80005026:	855e                	mv	a0,s7
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	83a080e7          	jalr	-1990(ra) # 80001862 <copyout>
    80005030:	0c054263          	bltz	a0,800050f4 <exec+0x316>
  p->trapframe->a1 = sp;
    80005034:	058ab783          	ld	a5,88(s5)
    80005038:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000503c:	df843783          	ld	a5,-520(s0)
    80005040:	0007c703          	lbu	a4,0(a5)
    80005044:	cf11                	beqz	a4,80005060 <exec+0x282>
    80005046:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005048:	02f00693          	li	a3,47
    8000504c:	a029                	j	80005056 <exec+0x278>
  for(last=s=path; *s; s++)
    8000504e:	0785                	addi	a5,a5,1
    80005050:	fff7c703          	lbu	a4,-1(a5)
    80005054:	c711                	beqz	a4,80005060 <exec+0x282>
    if(*s == '/')
    80005056:	fed71ce3          	bne	a4,a3,8000504e <exec+0x270>
      last = s+1;
    8000505a:	def43c23          	sd	a5,-520(s0)
    8000505e:	bfc5                	j	8000504e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005060:	4641                	li	a2,16
    80005062:	df843583          	ld	a1,-520(s0)
    80005066:	158a8513          	addi	a0,s5,344
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	df8080e7          	jalr	-520(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80005072:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005076:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000507a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000507e:	058ab783          	ld	a5,88(s5)
    80005082:	e6043703          	ld	a4,-416(s0)
    80005086:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005088:	058ab783          	ld	a5,88(s5)
    8000508c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005090:	85ea                	mv	a1,s10
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	c70080e7          	jalr	-912(ra) # 80001d02 <proc_freepagetable>
  if(p->pid==1)
    8000509a:	038aa703          	lw	a4,56(s5)
    8000509e:	4785                	li	a5,1
    800050a0:	00f70563          	beq	a4,a5,800050aa <exec+0x2cc>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050a4:	0004851b          	sext.w	a0,s1
    800050a8:	b3f9                	j	80004e76 <exec+0x98>
    vmprint(p->pagetable);
    800050aa:	050ab503          	ld	a0,80(s5)
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	980080e7          	jalr	-1664(ra) # 80001a2e <vmprint>
    800050b6:	b7fd                	j	800050a4 <exec+0x2c6>
    800050b8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050bc:	e0843583          	ld	a1,-504(s0)
    800050c0:	855e                	mv	a0,s7
    800050c2:	ffffd097          	auipc	ra,0xffffd
    800050c6:	c40080e7          	jalr	-960(ra) # 80001d02 <proc_freepagetable>
  if(ip){
    800050ca:	d8049ce3          	bnez	s1,80004e62 <exec+0x84>
  return -1;
    800050ce:	557d                	li	a0,-1
    800050d0:	b35d                	j	80004e76 <exec+0x98>
    800050d2:	e1243423          	sd	s2,-504(s0)
    800050d6:	b7dd                	j	800050bc <exec+0x2de>
    800050d8:	e1243423          	sd	s2,-504(s0)
    800050dc:	b7c5                	j	800050bc <exec+0x2de>
    800050de:	e1243423          	sd	s2,-504(s0)
    800050e2:	bfe9                	j	800050bc <exec+0x2de>
  sz = sz1;
    800050e4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050e8:	4481                	li	s1,0
    800050ea:	bfc9                	j	800050bc <exec+0x2de>
  sz = sz1;
    800050ec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f0:	4481                	li	s1,0
    800050f2:	b7e9                	j	800050bc <exec+0x2de>
  sz = sz1;
    800050f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f8:	4481                	li	s1,0
    800050fa:	b7c9                	j	800050bc <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050fc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005100:	2b05                	addiw	s6,s6,1
    80005102:	0389899b          	addiw	s3,s3,56
    80005106:	e8045783          	lhu	a5,-384(s0)
    8000510a:	e0fb5fe3          	bge	s6,a5,80004f28 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000510e:	2981                	sext.w	s3,s3
    80005110:	03800713          	li	a4,56
    80005114:	86ce                	mv	a3,s3
    80005116:	e1040613          	addi	a2,s0,-496
    8000511a:	4581                	li	a1,0
    8000511c:	8526                	mv	a0,s1
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	a32080e7          	jalr	-1486(ra) # 80003b50 <readi>
    80005126:	03800793          	li	a5,56
    8000512a:	f8f517e3          	bne	a0,a5,800050b8 <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    8000512e:	e1042783          	lw	a5,-496(s0)
    80005132:	4705                	li	a4,1
    80005134:	fce796e3          	bne	a5,a4,80005100 <exec+0x322>
    if(ph.memsz < ph.filesz)
    80005138:	e3843603          	ld	a2,-456(s0)
    8000513c:	e3043783          	ld	a5,-464(s0)
    80005140:	f8f669e3          	bltu	a2,a5,800050d2 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005144:	e2043783          	ld	a5,-480(s0)
    80005148:	963e                	add	a2,a2,a5
    8000514a:	f8f667e3          	bltu	a2,a5,800050d8 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000514e:	85ca                	mv	a1,s2
    80005150:	855e                	mv	a0,s7
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	4dc080e7          	jalr	1244(ra) # 8000162e <uvmalloc>
    8000515a:	e0a43423          	sd	a0,-504(s0)
    8000515e:	d141                	beqz	a0,800050de <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80005160:	e2043d03          	ld	s10,-480(s0)
    80005164:	df043783          	ld	a5,-528(s0)
    80005168:	00fd77b3          	and	a5,s10,a5
    8000516c:	fba1                	bnez	a5,800050bc <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000516e:	e1842d83          	lw	s11,-488(s0)
    80005172:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005176:	f80c03e3          	beqz	s8,800050fc <exec+0x31e>
    8000517a:	8a62                	mv	s4,s8
    8000517c:	4901                	li	s2,0
    8000517e:	b361                	j	80004f06 <exec+0x128>

0000000080005180 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005180:	7179                	addi	sp,sp,-48
    80005182:	f406                	sd	ra,40(sp)
    80005184:	f022                	sd	s0,32(sp)
    80005186:	ec26                	sd	s1,24(sp)
    80005188:	e84a                	sd	s2,16(sp)
    8000518a:	1800                	addi	s0,sp,48
    8000518c:	892e                	mv	s2,a1
    8000518e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005190:	fdc40593          	addi	a1,s0,-36
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	b8c080e7          	jalr	-1140(ra) # 80002d20 <argint>
    8000519c:	04054063          	bltz	a0,800051dc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051a0:	fdc42703          	lw	a4,-36(s0)
    800051a4:	47bd                	li	a5,15
    800051a6:	02e7ed63          	bltu	a5,a4,800051e0 <argfd+0x60>
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	9f8080e7          	jalr	-1544(ra) # 80001ba2 <myproc>
    800051b2:	fdc42703          	lw	a4,-36(s0)
    800051b6:	01a70793          	addi	a5,a4,26
    800051ba:	078e                	slli	a5,a5,0x3
    800051bc:	953e                	add	a0,a0,a5
    800051be:	611c                	ld	a5,0(a0)
    800051c0:	c395                	beqz	a5,800051e4 <argfd+0x64>
    return -1;
  if(pfd)
    800051c2:	00090463          	beqz	s2,800051ca <argfd+0x4a>
    *pfd = fd;
    800051c6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051ca:	4501                	li	a0,0
  if(pf)
    800051cc:	c091                	beqz	s1,800051d0 <argfd+0x50>
    *pf = f;
    800051ce:	e09c                	sd	a5,0(s1)
}
    800051d0:	70a2                	ld	ra,40(sp)
    800051d2:	7402                	ld	s0,32(sp)
    800051d4:	64e2                	ld	s1,24(sp)
    800051d6:	6942                	ld	s2,16(sp)
    800051d8:	6145                	addi	sp,sp,48
    800051da:	8082                	ret
    return -1;
    800051dc:	557d                	li	a0,-1
    800051de:	bfcd                	j	800051d0 <argfd+0x50>
    return -1;
    800051e0:	557d                	li	a0,-1
    800051e2:	b7fd                	j	800051d0 <argfd+0x50>
    800051e4:	557d                	li	a0,-1
    800051e6:	b7ed                	j	800051d0 <argfd+0x50>

00000000800051e8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051e8:	1101                	addi	sp,sp,-32
    800051ea:	ec06                	sd	ra,24(sp)
    800051ec:	e822                	sd	s0,16(sp)
    800051ee:	e426                	sd	s1,8(sp)
    800051f0:	1000                	addi	s0,sp,32
    800051f2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051f4:	ffffd097          	auipc	ra,0xffffd
    800051f8:	9ae080e7          	jalr	-1618(ra) # 80001ba2 <myproc>
    800051fc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051fe:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005202:	4501                	li	a0,0
    80005204:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005206:	6398                	ld	a4,0(a5)
    80005208:	cb19                	beqz	a4,8000521e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000520a:	2505                	addiw	a0,a0,1
    8000520c:	07a1                	addi	a5,a5,8
    8000520e:	fed51ce3          	bne	a0,a3,80005206 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005212:	557d                	li	a0,-1
}
    80005214:	60e2                	ld	ra,24(sp)
    80005216:	6442                	ld	s0,16(sp)
    80005218:	64a2                	ld	s1,8(sp)
    8000521a:	6105                	addi	sp,sp,32
    8000521c:	8082                	ret
      p->ofile[fd] = f;
    8000521e:	01a50793          	addi	a5,a0,26
    80005222:	078e                	slli	a5,a5,0x3
    80005224:	963e                	add	a2,a2,a5
    80005226:	e204                	sd	s1,0(a2)
      return fd;
    80005228:	b7f5                	j	80005214 <fdalloc+0x2c>

000000008000522a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000522a:	715d                	addi	sp,sp,-80
    8000522c:	e486                	sd	ra,72(sp)
    8000522e:	e0a2                	sd	s0,64(sp)
    80005230:	fc26                	sd	s1,56(sp)
    80005232:	f84a                	sd	s2,48(sp)
    80005234:	f44e                	sd	s3,40(sp)
    80005236:	f052                	sd	s4,32(sp)
    80005238:	ec56                	sd	s5,24(sp)
    8000523a:	0880                	addi	s0,sp,80
    8000523c:	89ae                	mv	s3,a1
    8000523e:	8ab2                	mv	s5,a2
    80005240:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005242:	fb040593          	addi	a1,s0,-80
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	e28080e7          	jalr	-472(ra) # 8000406e <nameiparent>
    8000524e:	892a                	mv	s2,a0
    80005250:	12050f63          	beqz	a0,8000538e <create+0x164>
    return 0;

  ilock(dp);
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	648080e7          	jalr	1608(ra) # 8000389c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000525c:	4601                	li	a2,0
    8000525e:	fb040593          	addi	a1,s0,-80
    80005262:	854a                	mv	a0,s2
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	b1a080e7          	jalr	-1254(ra) # 80003d7e <dirlookup>
    8000526c:	84aa                	mv	s1,a0
    8000526e:	c921                	beqz	a0,800052be <create+0x94>
    iunlockput(dp);
    80005270:	854a                	mv	a0,s2
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	88c080e7          	jalr	-1908(ra) # 80003afe <iunlockput>
    ilock(ip);
    8000527a:	8526                	mv	a0,s1
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	620080e7          	jalr	1568(ra) # 8000389c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005284:	2981                	sext.w	s3,s3
    80005286:	4789                	li	a5,2
    80005288:	02f99463          	bne	s3,a5,800052b0 <create+0x86>
    8000528c:	0444d783          	lhu	a5,68(s1)
    80005290:	37f9                	addiw	a5,a5,-2
    80005292:	17c2                	slli	a5,a5,0x30
    80005294:	93c1                	srli	a5,a5,0x30
    80005296:	4705                	li	a4,1
    80005298:	00f76c63          	bltu	a4,a5,800052b0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000529c:	8526                	mv	a0,s1
    8000529e:	60a6                	ld	ra,72(sp)
    800052a0:	6406                	ld	s0,64(sp)
    800052a2:	74e2                	ld	s1,56(sp)
    800052a4:	7942                	ld	s2,48(sp)
    800052a6:	79a2                	ld	s3,40(sp)
    800052a8:	7a02                	ld	s4,32(sp)
    800052aa:	6ae2                	ld	s5,24(sp)
    800052ac:	6161                	addi	sp,sp,80
    800052ae:	8082                	ret
    iunlockput(ip);
    800052b0:	8526                	mv	a0,s1
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	84c080e7          	jalr	-1972(ra) # 80003afe <iunlockput>
    return 0;
    800052ba:	4481                	li	s1,0
    800052bc:	b7c5                	j	8000529c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052be:	85ce                	mv	a1,s3
    800052c0:	00092503          	lw	a0,0(s2)
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	440080e7          	jalr	1088(ra) # 80003704 <ialloc>
    800052cc:	84aa                	mv	s1,a0
    800052ce:	c529                	beqz	a0,80005318 <create+0xee>
  ilock(ip);
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	5cc080e7          	jalr	1484(ra) # 8000389c <ilock>
  ip->major = major;
    800052d8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052dc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052e0:	4785                	li	a5,1
    800052e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	4ea080e7          	jalr	1258(ra) # 800037d2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052f0:	2981                	sext.w	s3,s3
    800052f2:	4785                	li	a5,1
    800052f4:	02f98a63          	beq	s3,a5,80005328 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052f8:	40d0                	lw	a2,4(s1)
    800052fa:	fb040593          	addi	a1,s0,-80
    800052fe:	854a                	mv	a0,s2
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	c8e080e7          	jalr	-882(ra) # 80003f8e <dirlink>
    80005308:	06054b63          	bltz	a0,8000537e <create+0x154>
  iunlockput(dp);
    8000530c:	854a                	mv	a0,s2
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	7f0080e7          	jalr	2032(ra) # 80003afe <iunlockput>
  return ip;
    80005316:	b759                	j	8000529c <create+0x72>
    panic("create: ialloc");
    80005318:	00003517          	auipc	a0,0x3
    8000531c:	48850513          	addi	a0,a0,1160 # 800087a0 <syscalls+0x2b0>
    80005320:	ffffb097          	auipc	ra,0xffffb
    80005324:	228080e7          	jalr	552(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005328:	04a95783          	lhu	a5,74(s2)
    8000532c:	2785                	addiw	a5,a5,1
    8000532e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005332:	854a                	mv	a0,s2
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	49e080e7          	jalr	1182(ra) # 800037d2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000533c:	40d0                	lw	a2,4(s1)
    8000533e:	00003597          	auipc	a1,0x3
    80005342:	47258593          	addi	a1,a1,1138 # 800087b0 <syscalls+0x2c0>
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	c46080e7          	jalr	-954(ra) # 80003f8e <dirlink>
    80005350:	00054f63          	bltz	a0,8000536e <create+0x144>
    80005354:	00492603          	lw	a2,4(s2)
    80005358:	00003597          	auipc	a1,0x3
    8000535c:	46058593          	addi	a1,a1,1120 # 800087b8 <syscalls+0x2c8>
    80005360:	8526                	mv	a0,s1
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	c2c080e7          	jalr	-980(ra) # 80003f8e <dirlink>
    8000536a:	f80557e3          	bgez	a0,800052f8 <create+0xce>
      panic("create dots");
    8000536e:	00003517          	auipc	a0,0x3
    80005372:	45250513          	addi	a0,a0,1106 # 800087c0 <syscalls+0x2d0>
    80005376:	ffffb097          	auipc	ra,0xffffb
    8000537a:	1d2080e7          	jalr	466(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000537e:	00003517          	auipc	a0,0x3
    80005382:	45250513          	addi	a0,a0,1106 # 800087d0 <syscalls+0x2e0>
    80005386:	ffffb097          	auipc	ra,0xffffb
    8000538a:	1c2080e7          	jalr	450(ra) # 80000548 <panic>
    return 0;
    8000538e:	84aa                	mv	s1,a0
    80005390:	b731                	j	8000529c <create+0x72>

0000000080005392 <sys_dup>:
{
    80005392:	7179                	addi	sp,sp,-48
    80005394:	f406                	sd	ra,40(sp)
    80005396:	f022                	sd	s0,32(sp)
    80005398:	ec26                	sd	s1,24(sp)
    8000539a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000539c:	fd840613          	addi	a2,s0,-40
    800053a0:	4581                	li	a1,0
    800053a2:	4501                	li	a0,0
    800053a4:	00000097          	auipc	ra,0x0
    800053a8:	ddc080e7          	jalr	-548(ra) # 80005180 <argfd>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ae:	02054363          	bltz	a0,800053d4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053b2:	fd843503          	ld	a0,-40(s0)
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	e32080e7          	jalr	-462(ra) # 800051e8 <fdalloc>
    800053be:	84aa                	mv	s1,a0
    return -1;
    800053c0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053c2:	00054963          	bltz	a0,800053d4 <sys_dup+0x42>
  filedup(f);
    800053c6:	fd843503          	ld	a0,-40(s0)
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	312080e7          	jalr	786(ra) # 800046dc <filedup>
  return fd;
    800053d2:	87a6                	mv	a5,s1
}
    800053d4:	853e                	mv	a0,a5
    800053d6:	70a2                	ld	ra,40(sp)
    800053d8:	7402                	ld	s0,32(sp)
    800053da:	64e2                	ld	s1,24(sp)
    800053dc:	6145                	addi	sp,sp,48
    800053de:	8082                	ret

00000000800053e0 <sys_read>:
{
    800053e0:	7179                	addi	sp,sp,-48
    800053e2:	f406                	sd	ra,40(sp)
    800053e4:	f022                	sd	s0,32(sp)
    800053e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e8:	fe840613          	addi	a2,s0,-24
    800053ec:	4581                	li	a1,0
    800053ee:	4501                	li	a0,0
    800053f0:	00000097          	auipc	ra,0x0
    800053f4:	d90080e7          	jalr	-624(ra) # 80005180 <argfd>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fa:	04054163          	bltz	a0,8000543c <sys_read+0x5c>
    800053fe:	fe440593          	addi	a1,s0,-28
    80005402:	4509                	li	a0,2
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	91c080e7          	jalr	-1764(ra) # 80002d20 <argint>
    return -1;
    8000540c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540e:	02054763          	bltz	a0,8000543c <sys_read+0x5c>
    80005412:	fd840593          	addi	a1,s0,-40
    80005416:	4505                	li	a0,1
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	92a080e7          	jalr	-1750(ra) # 80002d42 <argaddr>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005422:	00054d63          	bltz	a0,8000543c <sys_read+0x5c>
  return fileread(f, p, n);
    80005426:	fe442603          	lw	a2,-28(s0)
    8000542a:	fd843583          	ld	a1,-40(s0)
    8000542e:	fe843503          	ld	a0,-24(s0)
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	436080e7          	jalr	1078(ra) # 80004868 <fileread>
    8000543a:	87aa                	mv	a5,a0
}
    8000543c:	853e                	mv	a0,a5
    8000543e:	70a2                	ld	ra,40(sp)
    80005440:	7402                	ld	s0,32(sp)
    80005442:	6145                	addi	sp,sp,48
    80005444:	8082                	ret

0000000080005446 <sys_write>:
{
    80005446:	7179                	addi	sp,sp,-48
    80005448:	f406                	sd	ra,40(sp)
    8000544a:	f022                	sd	s0,32(sp)
    8000544c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544e:	fe840613          	addi	a2,s0,-24
    80005452:	4581                	li	a1,0
    80005454:	4501                	li	a0,0
    80005456:	00000097          	auipc	ra,0x0
    8000545a:	d2a080e7          	jalr	-726(ra) # 80005180 <argfd>
    return -1;
    8000545e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005460:	04054163          	bltz	a0,800054a2 <sys_write+0x5c>
    80005464:	fe440593          	addi	a1,s0,-28
    80005468:	4509                	li	a0,2
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	8b6080e7          	jalr	-1866(ra) # 80002d20 <argint>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005474:	02054763          	bltz	a0,800054a2 <sys_write+0x5c>
    80005478:	fd840593          	addi	a1,s0,-40
    8000547c:	4505                	li	a0,1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	8c4080e7          	jalr	-1852(ra) # 80002d42 <argaddr>
    return -1;
    80005486:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005488:	00054d63          	bltz	a0,800054a2 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000548c:	fe442603          	lw	a2,-28(s0)
    80005490:	fd843583          	ld	a1,-40(s0)
    80005494:	fe843503          	ld	a0,-24(s0)
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	492080e7          	jalr	1170(ra) # 8000492a <filewrite>
    800054a0:	87aa                	mv	a5,a0
}
    800054a2:	853e                	mv	a0,a5
    800054a4:	70a2                	ld	ra,40(sp)
    800054a6:	7402                	ld	s0,32(sp)
    800054a8:	6145                	addi	sp,sp,48
    800054aa:	8082                	ret

00000000800054ac <sys_close>:
{
    800054ac:	1101                	addi	sp,sp,-32
    800054ae:	ec06                	sd	ra,24(sp)
    800054b0:	e822                	sd	s0,16(sp)
    800054b2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054b4:	fe040613          	addi	a2,s0,-32
    800054b8:	fec40593          	addi	a1,s0,-20
    800054bc:	4501                	li	a0,0
    800054be:	00000097          	auipc	ra,0x0
    800054c2:	cc2080e7          	jalr	-830(ra) # 80005180 <argfd>
    return -1;
    800054c6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054c8:	02054463          	bltz	a0,800054f0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	6d6080e7          	jalr	1750(ra) # 80001ba2 <myproc>
    800054d4:	fec42783          	lw	a5,-20(s0)
    800054d8:	07e9                	addi	a5,a5,26
    800054da:	078e                	slli	a5,a5,0x3
    800054dc:	97aa                	add	a5,a5,a0
    800054de:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054e2:	fe043503          	ld	a0,-32(s0)
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	248080e7          	jalr	584(ra) # 8000472e <fileclose>
  return 0;
    800054ee:	4781                	li	a5,0
}
    800054f0:	853e                	mv	a0,a5
    800054f2:	60e2                	ld	ra,24(sp)
    800054f4:	6442                	ld	s0,16(sp)
    800054f6:	6105                	addi	sp,sp,32
    800054f8:	8082                	ret

00000000800054fa <sys_fstat>:
{
    800054fa:	1101                	addi	sp,sp,-32
    800054fc:	ec06                	sd	ra,24(sp)
    800054fe:	e822                	sd	s0,16(sp)
    80005500:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005502:	fe840613          	addi	a2,s0,-24
    80005506:	4581                	li	a1,0
    80005508:	4501                	li	a0,0
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	c76080e7          	jalr	-906(ra) # 80005180 <argfd>
    return -1;
    80005512:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005514:	02054563          	bltz	a0,8000553e <sys_fstat+0x44>
    80005518:	fe040593          	addi	a1,s0,-32
    8000551c:	4505                	li	a0,1
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	824080e7          	jalr	-2012(ra) # 80002d42 <argaddr>
    return -1;
    80005526:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005528:	00054b63          	bltz	a0,8000553e <sys_fstat+0x44>
  return filestat(f, st);
    8000552c:	fe043583          	ld	a1,-32(s0)
    80005530:	fe843503          	ld	a0,-24(s0)
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	2c2080e7          	jalr	706(ra) # 800047f6 <filestat>
    8000553c:	87aa                	mv	a5,a0
}
    8000553e:	853e                	mv	a0,a5
    80005540:	60e2                	ld	ra,24(sp)
    80005542:	6442                	ld	s0,16(sp)
    80005544:	6105                	addi	sp,sp,32
    80005546:	8082                	ret

0000000080005548 <sys_link>:
{
    80005548:	7169                	addi	sp,sp,-304
    8000554a:	f606                	sd	ra,296(sp)
    8000554c:	f222                	sd	s0,288(sp)
    8000554e:	ee26                	sd	s1,280(sp)
    80005550:	ea4a                	sd	s2,272(sp)
    80005552:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005554:	08000613          	li	a2,128
    80005558:	ed040593          	addi	a1,s0,-304
    8000555c:	4501                	li	a0,0
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	806080e7          	jalr	-2042(ra) # 80002d64 <argstr>
    return -1;
    80005566:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005568:	10054e63          	bltz	a0,80005684 <sys_link+0x13c>
    8000556c:	08000613          	li	a2,128
    80005570:	f5040593          	addi	a1,s0,-176
    80005574:	4505                	li	a0,1
    80005576:	ffffd097          	auipc	ra,0xffffd
    8000557a:	7ee080e7          	jalr	2030(ra) # 80002d64 <argstr>
    return -1;
    8000557e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005580:	10054263          	bltz	a0,80005684 <sys_link+0x13c>
  begin_op();
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	cd8080e7          	jalr	-808(ra) # 8000425c <begin_op>
  if((ip = namei(old)) == 0){
    8000558c:	ed040513          	addi	a0,s0,-304
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	ac0080e7          	jalr	-1344(ra) # 80004050 <namei>
    80005598:	84aa                	mv	s1,a0
    8000559a:	c551                	beqz	a0,80005626 <sys_link+0xde>
  ilock(ip);
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	300080e7          	jalr	768(ra) # 8000389c <ilock>
  if(ip->type == T_DIR){
    800055a4:	04449703          	lh	a4,68(s1)
    800055a8:	4785                	li	a5,1
    800055aa:	08f70463          	beq	a4,a5,80005632 <sys_link+0xea>
  ip->nlink++;
    800055ae:	04a4d783          	lhu	a5,74(s1)
    800055b2:	2785                	addiw	a5,a5,1
    800055b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	218080e7          	jalr	536(ra) # 800037d2 <iupdate>
  iunlock(ip);
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	39a080e7          	jalr	922(ra) # 8000395e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055cc:	fd040593          	addi	a1,s0,-48
    800055d0:	f5040513          	addi	a0,s0,-176
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	a9a080e7          	jalr	-1382(ra) # 8000406e <nameiparent>
    800055dc:	892a                	mv	s2,a0
    800055de:	c935                	beqz	a0,80005652 <sys_link+0x10a>
  ilock(dp);
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	2bc080e7          	jalr	700(ra) # 8000389c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055e8:	00092703          	lw	a4,0(s2)
    800055ec:	409c                	lw	a5,0(s1)
    800055ee:	04f71d63          	bne	a4,a5,80005648 <sys_link+0x100>
    800055f2:	40d0                	lw	a2,4(s1)
    800055f4:	fd040593          	addi	a1,s0,-48
    800055f8:	854a                	mv	a0,s2
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	994080e7          	jalr	-1644(ra) # 80003f8e <dirlink>
    80005602:	04054363          	bltz	a0,80005648 <sys_link+0x100>
  iunlockput(dp);
    80005606:	854a                	mv	a0,s2
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	4f6080e7          	jalr	1270(ra) # 80003afe <iunlockput>
  iput(ip);
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	444080e7          	jalr	1092(ra) # 80003a56 <iput>
  end_op();
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	cc2080e7          	jalr	-830(ra) # 800042dc <end_op>
  return 0;
    80005622:	4781                	li	a5,0
    80005624:	a085                	j	80005684 <sys_link+0x13c>
    end_op();
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	cb6080e7          	jalr	-842(ra) # 800042dc <end_op>
    return -1;
    8000562e:	57fd                	li	a5,-1
    80005630:	a891                	j	80005684 <sys_link+0x13c>
    iunlockput(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	4ca080e7          	jalr	1226(ra) # 80003afe <iunlockput>
    end_op();
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	ca0080e7          	jalr	-864(ra) # 800042dc <end_op>
    return -1;
    80005644:	57fd                	li	a5,-1
    80005646:	a83d                	j	80005684 <sys_link+0x13c>
    iunlockput(dp);
    80005648:	854a                	mv	a0,s2
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	4b4080e7          	jalr	1204(ra) # 80003afe <iunlockput>
  ilock(ip);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	248080e7          	jalr	584(ra) # 8000389c <ilock>
  ip->nlink--;
    8000565c:	04a4d783          	lhu	a5,74(s1)
    80005660:	37fd                	addiw	a5,a5,-1
    80005662:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	16a080e7          	jalr	362(ra) # 800037d2 <iupdate>
  iunlockput(ip);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	48c080e7          	jalr	1164(ra) # 80003afe <iunlockput>
  end_op();
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	c62080e7          	jalr	-926(ra) # 800042dc <end_op>
  return -1;
    80005682:	57fd                	li	a5,-1
}
    80005684:	853e                	mv	a0,a5
    80005686:	70b2                	ld	ra,296(sp)
    80005688:	7412                	ld	s0,288(sp)
    8000568a:	64f2                	ld	s1,280(sp)
    8000568c:	6952                	ld	s2,272(sp)
    8000568e:	6155                	addi	sp,sp,304
    80005690:	8082                	ret

0000000080005692 <sys_unlink>:
{
    80005692:	7151                	addi	sp,sp,-240
    80005694:	f586                	sd	ra,232(sp)
    80005696:	f1a2                	sd	s0,224(sp)
    80005698:	eda6                	sd	s1,216(sp)
    8000569a:	e9ca                	sd	s2,208(sp)
    8000569c:	e5ce                	sd	s3,200(sp)
    8000569e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056a0:	08000613          	li	a2,128
    800056a4:	f3040593          	addi	a1,s0,-208
    800056a8:	4501                	li	a0,0
    800056aa:	ffffd097          	auipc	ra,0xffffd
    800056ae:	6ba080e7          	jalr	1722(ra) # 80002d64 <argstr>
    800056b2:	18054163          	bltz	a0,80005834 <sys_unlink+0x1a2>
  begin_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	ba6080e7          	jalr	-1114(ra) # 8000425c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056be:	fb040593          	addi	a1,s0,-80
    800056c2:	f3040513          	addi	a0,s0,-208
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	9a8080e7          	jalr	-1624(ra) # 8000406e <nameiparent>
    800056ce:	84aa                	mv	s1,a0
    800056d0:	c979                	beqz	a0,800057a6 <sys_unlink+0x114>
  ilock(dp);
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	1ca080e7          	jalr	458(ra) # 8000389c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056da:	00003597          	auipc	a1,0x3
    800056de:	0d658593          	addi	a1,a1,214 # 800087b0 <syscalls+0x2c0>
    800056e2:	fb040513          	addi	a0,s0,-80
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	67e080e7          	jalr	1662(ra) # 80003d64 <namecmp>
    800056ee:	14050a63          	beqz	a0,80005842 <sys_unlink+0x1b0>
    800056f2:	00003597          	auipc	a1,0x3
    800056f6:	0c658593          	addi	a1,a1,198 # 800087b8 <syscalls+0x2c8>
    800056fa:	fb040513          	addi	a0,s0,-80
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	666080e7          	jalr	1638(ra) # 80003d64 <namecmp>
    80005706:	12050e63          	beqz	a0,80005842 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000570a:	f2c40613          	addi	a2,s0,-212
    8000570e:	fb040593          	addi	a1,s0,-80
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	66a080e7          	jalr	1642(ra) # 80003d7e <dirlookup>
    8000571c:	892a                	mv	s2,a0
    8000571e:	12050263          	beqz	a0,80005842 <sys_unlink+0x1b0>
  ilock(ip);
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	17a080e7          	jalr	378(ra) # 8000389c <ilock>
  if(ip->nlink < 1)
    8000572a:	04a91783          	lh	a5,74(s2)
    8000572e:	08f05263          	blez	a5,800057b2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005732:	04491703          	lh	a4,68(s2)
    80005736:	4785                	li	a5,1
    80005738:	08f70563          	beq	a4,a5,800057c2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000573c:	4641                	li	a2,16
    8000573e:	4581                	li	a1,0
    80005740:	fc040513          	addi	a0,s0,-64
    80005744:	ffffb097          	auipc	ra,0xffffb
    80005748:	5c8080e7          	jalr	1480(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000574c:	4741                	li	a4,16
    8000574e:	f2c42683          	lw	a3,-212(s0)
    80005752:	fc040613          	addi	a2,s0,-64
    80005756:	4581                	li	a1,0
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	4ee080e7          	jalr	1262(ra) # 80003c48 <writei>
    80005762:	47c1                	li	a5,16
    80005764:	0af51563          	bne	a0,a5,8000580e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005768:	04491703          	lh	a4,68(s2)
    8000576c:	4785                	li	a5,1
    8000576e:	0af70863          	beq	a4,a5,8000581e <sys_unlink+0x18c>
  iunlockput(dp);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	38a080e7          	jalr	906(ra) # 80003afe <iunlockput>
  ip->nlink--;
    8000577c:	04a95783          	lhu	a5,74(s2)
    80005780:	37fd                	addiw	a5,a5,-1
    80005782:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005786:	854a                	mv	a0,s2
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	04a080e7          	jalr	74(ra) # 800037d2 <iupdate>
  iunlockput(ip);
    80005790:	854a                	mv	a0,s2
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	36c080e7          	jalr	876(ra) # 80003afe <iunlockput>
  end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	b42080e7          	jalr	-1214(ra) # 800042dc <end_op>
  return 0;
    800057a2:	4501                	li	a0,0
    800057a4:	a84d                	j	80005856 <sys_unlink+0x1c4>
    end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	b36080e7          	jalr	-1226(ra) # 800042dc <end_op>
    return -1;
    800057ae:	557d                	li	a0,-1
    800057b0:	a05d                	j	80005856 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057b2:	00003517          	auipc	a0,0x3
    800057b6:	02e50513          	addi	a0,a0,46 # 800087e0 <syscalls+0x2f0>
    800057ba:	ffffb097          	auipc	ra,0xffffb
    800057be:	d8e080e7          	jalr	-626(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057c2:	04c92703          	lw	a4,76(s2)
    800057c6:	02000793          	li	a5,32
    800057ca:	f6e7f9e3          	bgeu	a5,a4,8000573c <sys_unlink+0xaa>
    800057ce:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057d2:	4741                	li	a4,16
    800057d4:	86ce                	mv	a3,s3
    800057d6:	f1840613          	addi	a2,s0,-232
    800057da:	4581                	li	a1,0
    800057dc:	854a                	mv	a0,s2
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	372080e7          	jalr	882(ra) # 80003b50 <readi>
    800057e6:	47c1                	li	a5,16
    800057e8:	00f51b63          	bne	a0,a5,800057fe <sys_unlink+0x16c>
    if(de.inum != 0)
    800057ec:	f1845783          	lhu	a5,-232(s0)
    800057f0:	e7a1                	bnez	a5,80005838 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057f2:	29c1                	addiw	s3,s3,16
    800057f4:	04c92783          	lw	a5,76(s2)
    800057f8:	fcf9ede3          	bltu	s3,a5,800057d2 <sys_unlink+0x140>
    800057fc:	b781                	j	8000573c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057fe:	00003517          	auipc	a0,0x3
    80005802:	ffa50513          	addi	a0,a0,-6 # 800087f8 <syscalls+0x308>
    80005806:	ffffb097          	auipc	ra,0xffffb
    8000580a:	d42080e7          	jalr	-702(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000580e:	00003517          	auipc	a0,0x3
    80005812:	00250513          	addi	a0,a0,2 # 80008810 <syscalls+0x320>
    80005816:	ffffb097          	auipc	ra,0xffffb
    8000581a:	d32080e7          	jalr	-718(ra) # 80000548 <panic>
    dp->nlink--;
    8000581e:	04a4d783          	lhu	a5,74(s1)
    80005822:	37fd                	addiw	a5,a5,-1
    80005824:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	fa8080e7          	jalr	-88(ra) # 800037d2 <iupdate>
    80005832:	b781                	j	80005772 <sys_unlink+0xe0>
    return -1;
    80005834:	557d                	li	a0,-1
    80005836:	a005                	j	80005856 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005838:	854a                	mv	a0,s2
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	2c4080e7          	jalr	708(ra) # 80003afe <iunlockput>
  iunlockput(dp);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	2ba080e7          	jalr	698(ra) # 80003afe <iunlockput>
  end_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	a90080e7          	jalr	-1392(ra) # 800042dc <end_op>
  return -1;
    80005854:	557d                	li	a0,-1
}
    80005856:	70ae                	ld	ra,232(sp)
    80005858:	740e                	ld	s0,224(sp)
    8000585a:	64ee                	ld	s1,216(sp)
    8000585c:	694e                	ld	s2,208(sp)
    8000585e:	69ae                	ld	s3,200(sp)
    80005860:	616d                	addi	sp,sp,240
    80005862:	8082                	ret

0000000080005864 <sys_open>:

uint64
sys_open(void)
{
    80005864:	7131                	addi	sp,sp,-192
    80005866:	fd06                	sd	ra,184(sp)
    80005868:	f922                	sd	s0,176(sp)
    8000586a:	f526                	sd	s1,168(sp)
    8000586c:	f14a                	sd	s2,160(sp)
    8000586e:	ed4e                	sd	s3,152(sp)
    80005870:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005872:	08000613          	li	a2,128
    80005876:	f5040593          	addi	a1,s0,-176
    8000587a:	4501                	li	a0,0
    8000587c:	ffffd097          	auipc	ra,0xffffd
    80005880:	4e8080e7          	jalr	1256(ra) # 80002d64 <argstr>
    return -1;
    80005884:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005886:	0c054163          	bltz	a0,80005948 <sys_open+0xe4>
    8000588a:	f4c40593          	addi	a1,s0,-180
    8000588e:	4505                	li	a0,1
    80005890:	ffffd097          	auipc	ra,0xffffd
    80005894:	490080e7          	jalr	1168(ra) # 80002d20 <argint>
    80005898:	0a054863          	bltz	a0,80005948 <sys_open+0xe4>

  begin_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	9c0080e7          	jalr	-1600(ra) # 8000425c <begin_op>

  if(omode & O_CREATE){
    800058a4:	f4c42783          	lw	a5,-180(s0)
    800058a8:	2007f793          	andi	a5,a5,512
    800058ac:	cbdd                	beqz	a5,80005962 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058ae:	4681                	li	a3,0
    800058b0:	4601                	li	a2,0
    800058b2:	4589                	li	a1,2
    800058b4:	f5040513          	addi	a0,s0,-176
    800058b8:	00000097          	auipc	ra,0x0
    800058bc:	972080e7          	jalr	-1678(ra) # 8000522a <create>
    800058c0:	892a                	mv	s2,a0
    if(ip == 0){
    800058c2:	c959                	beqz	a0,80005958 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058c4:	04491703          	lh	a4,68(s2)
    800058c8:	478d                	li	a5,3
    800058ca:	00f71763          	bne	a4,a5,800058d8 <sys_open+0x74>
    800058ce:	04695703          	lhu	a4,70(s2)
    800058d2:	47a5                	li	a5,9
    800058d4:	0ce7ec63          	bltu	a5,a4,800059ac <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	d9a080e7          	jalr	-614(ra) # 80004672 <filealloc>
    800058e0:	89aa                	mv	s3,a0
    800058e2:	10050263          	beqz	a0,800059e6 <sys_open+0x182>
    800058e6:	00000097          	auipc	ra,0x0
    800058ea:	902080e7          	jalr	-1790(ra) # 800051e8 <fdalloc>
    800058ee:	84aa                	mv	s1,a0
    800058f0:	0e054663          	bltz	a0,800059dc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058f4:	04491703          	lh	a4,68(s2)
    800058f8:	478d                	li	a5,3
    800058fa:	0cf70463          	beq	a4,a5,800059c2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058fe:	4789                	li	a5,2
    80005900:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005904:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005908:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000590c:	f4c42783          	lw	a5,-180(s0)
    80005910:	0017c713          	xori	a4,a5,1
    80005914:	8b05                	andi	a4,a4,1
    80005916:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000591a:	0037f713          	andi	a4,a5,3
    8000591e:	00e03733          	snez	a4,a4
    80005922:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005926:	4007f793          	andi	a5,a5,1024
    8000592a:	c791                	beqz	a5,80005936 <sys_open+0xd2>
    8000592c:	04491703          	lh	a4,68(s2)
    80005930:	4789                	li	a5,2
    80005932:	08f70f63          	beq	a4,a5,800059d0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005936:	854a                	mv	a0,s2
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	026080e7          	jalr	38(ra) # 8000395e <iunlock>
  end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	99c080e7          	jalr	-1636(ra) # 800042dc <end_op>

  return fd;
}
    80005948:	8526                	mv	a0,s1
    8000594a:	70ea                	ld	ra,184(sp)
    8000594c:	744a                	ld	s0,176(sp)
    8000594e:	74aa                	ld	s1,168(sp)
    80005950:	790a                	ld	s2,160(sp)
    80005952:	69ea                	ld	s3,152(sp)
    80005954:	6129                	addi	sp,sp,192
    80005956:	8082                	ret
      end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	984080e7          	jalr	-1660(ra) # 800042dc <end_op>
      return -1;
    80005960:	b7e5                	j	80005948 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005962:	f5040513          	addi	a0,s0,-176
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	6ea080e7          	jalr	1770(ra) # 80004050 <namei>
    8000596e:	892a                	mv	s2,a0
    80005970:	c905                	beqz	a0,800059a0 <sys_open+0x13c>
    ilock(ip);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	f2a080e7          	jalr	-214(ra) # 8000389c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000597a:	04491703          	lh	a4,68(s2)
    8000597e:	4785                	li	a5,1
    80005980:	f4f712e3          	bne	a4,a5,800058c4 <sys_open+0x60>
    80005984:	f4c42783          	lw	a5,-180(s0)
    80005988:	dba1                	beqz	a5,800058d8 <sys_open+0x74>
      iunlockput(ip);
    8000598a:	854a                	mv	a0,s2
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	172080e7          	jalr	370(ra) # 80003afe <iunlockput>
      end_op();
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	948080e7          	jalr	-1720(ra) # 800042dc <end_op>
      return -1;
    8000599c:	54fd                	li	s1,-1
    8000599e:	b76d                	j	80005948 <sys_open+0xe4>
      end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	93c080e7          	jalr	-1732(ra) # 800042dc <end_op>
      return -1;
    800059a8:	54fd                	li	s1,-1
    800059aa:	bf79                	j	80005948 <sys_open+0xe4>
    iunlockput(ip);
    800059ac:	854a                	mv	a0,s2
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	150080e7          	jalr	336(ra) # 80003afe <iunlockput>
    end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	926080e7          	jalr	-1754(ra) # 800042dc <end_op>
    return -1;
    800059be:	54fd                	li	s1,-1
    800059c0:	b761                	j	80005948 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059c2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059c6:	04691783          	lh	a5,70(s2)
    800059ca:	02f99223          	sh	a5,36(s3)
    800059ce:	bf2d                	j	80005908 <sys_open+0xa4>
    itrunc(ip);
    800059d0:	854a                	mv	a0,s2
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	fd8080e7          	jalr	-40(ra) # 800039aa <itrunc>
    800059da:	bfb1                	j	80005936 <sys_open+0xd2>
      fileclose(f);
    800059dc:	854e                	mv	a0,s3
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	d50080e7          	jalr	-688(ra) # 8000472e <fileclose>
    iunlockput(ip);
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	116080e7          	jalr	278(ra) # 80003afe <iunlockput>
    end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	8ec080e7          	jalr	-1812(ra) # 800042dc <end_op>
    return -1;
    800059f8:	54fd                	li	s1,-1
    800059fa:	b7b9                	j	80005948 <sys_open+0xe4>

00000000800059fc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059fc:	7175                	addi	sp,sp,-144
    800059fe:	e506                	sd	ra,136(sp)
    80005a00:	e122                	sd	s0,128(sp)
    80005a02:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	858080e7          	jalr	-1960(ra) # 8000425c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a0c:	08000613          	li	a2,128
    80005a10:	f7040593          	addi	a1,s0,-144
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	34e080e7          	jalr	846(ra) # 80002d64 <argstr>
    80005a1e:	02054963          	bltz	a0,80005a50 <sys_mkdir+0x54>
    80005a22:	4681                	li	a3,0
    80005a24:	4601                	li	a2,0
    80005a26:	4585                	li	a1,1
    80005a28:	f7040513          	addi	a0,s0,-144
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	7fe080e7          	jalr	2046(ra) # 8000522a <create>
    80005a34:	cd11                	beqz	a0,80005a50 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	0c8080e7          	jalr	200(ra) # 80003afe <iunlockput>
  end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	89e080e7          	jalr	-1890(ra) # 800042dc <end_op>
  return 0;
    80005a46:	4501                	li	a0,0
}
    80005a48:	60aa                	ld	ra,136(sp)
    80005a4a:	640a                	ld	s0,128(sp)
    80005a4c:	6149                	addi	sp,sp,144
    80005a4e:	8082                	ret
    end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	88c080e7          	jalr	-1908(ra) # 800042dc <end_op>
    return -1;
    80005a58:	557d                	li	a0,-1
    80005a5a:	b7fd                	j	80005a48 <sys_mkdir+0x4c>

0000000080005a5c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a5c:	7135                	addi	sp,sp,-160
    80005a5e:	ed06                	sd	ra,152(sp)
    80005a60:	e922                	sd	s0,144(sp)
    80005a62:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	7f8080e7          	jalr	2040(ra) # 8000425c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a6c:	08000613          	li	a2,128
    80005a70:	f7040593          	addi	a1,s0,-144
    80005a74:	4501                	li	a0,0
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	2ee080e7          	jalr	750(ra) # 80002d64 <argstr>
    80005a7e:	04054a63          	bltz	a0,80005ad2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a82:	f6c40593          	addi	a1,s0,-148
    80005a86:	4505                	li	a0,1
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	298080e7          	jalr	664(ra) # 80002d20 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a90:	04054163          	bltz	a0,80005ad2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a94:	f6840593          	addi	a1,s0,-152
    80005a98:	4509                	li	a0,2
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	286080e7          	jalr	646(ra) # 80002d20 <argint>
     argint(1, &major) < 0 ||
    80005aa2:	02054863          	bltz	a0,80005ad2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005aa6:	f6841683          	lh	a3,-152(s0)
    80005aaa:	f6c41603          	lh	a2,-148(s0)
    80005aae:	458d                	li	a1,3
    80005ab0:	f7040513          	addi	a0,s0,-144
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	776080e7          	jalr	1910(ra) # 8000522a <create>
     argint(2, &minor) < 0 ||
    80005abc:	c919                	beqz	a0,80005ad2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	040080e7          	jalr	64(ra) # 80003afe <iunlockput>
  end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	816080e7          	jalr	-2026(ra) # 800042dc <end_op>
  return 0;
    80005ace:	4501                	li	a0,0
    80005ad0:	a031                	j	80005adc <sys_mknod+0x80>
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	80a080e7          	jalr	-2038(ra) # 800042dc <end_op>
    return -1;
    80005ada:	557d                	li	a0,-1
}
    80005adc:	60ea                	ld	ra,152(sp)
    80005ade:	644a                	ld	s0,144(sp)
    80005ae0:	610d                	addi	sp,sp,160
    80005ae2:	8082                	ret

0000000080005ae4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ae4:	7135                	addi	sp,sp,-160
    80005ae6:	ed06                	sd	ra,152(sp)
    80005ae8:	e922                	sd	s0,144(sp)
    80005aea:	e526                	sd	s1,136(sp)
    80005aec:	e14a                	sd	s2,128(sp)
    80005aee:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005af0:	ffffc097          	auipc	ra,0xffffc
    80005af4:	0b2080e7          	jalr	178(ra) # 80001ba2 <myproc>
    80005af8:	892a                	mv	s2,a0
  
  begin_op();
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	762080e7          	jalr	1890(ra) # 8000425c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b02:	08000613          	li	a2,128
    80005b06:	f6040593          	addi	a1,s0,-160
    80005b0a:	4501                	li	a0,0
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	258080e7          	jalr	600(ra) # 80002d64 <argstr>
    80005b14:	04054b63          	bltz	a0,80005b6a <sys_chdir+0x86>
    80005b18:	f6040513          	addi	a0,s0,-160
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	534080e7          	jalr	1332(ra) # 80004050 <namei>
    80005b24:	84aa                	mv	s1,a0
    80005b26:	c131                	beqz	a0,80005b6a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	d74080e7          	jalr	-652(ra) # 8000389c <ilock>
  if(ip->type != T_DIR){
    80005b30:	04449703          	lh	a4,68(s1)
    80005b34:	4785                	li	a5,1
    80005b36:	04f71063          	bne	a4,a5,80005b76 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	e22080e7          	jalr	-478(ra) # 8000395e <iunlock>
  iput(p->cwd);
    80005b44:	15093503          	ld	a0,336(s2)
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	f0e080e7          	jalr	-242(ra) # 80003a56 <iput>
  end_op();
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	78c080e7          	jalr	1932(ra) # 800042dc <end_op>
  p->cwd = ip;
    80005b58:	14993823          	sd	s1,336(s2)
  return 0;
    80005b5c:	4501                	li	a0,0
}
    80005b5e:	60ea                	ld	ra,152(sp)
    80005b60:	644a                	ld	s0,144(sp)
    80005b62:	64aa                	ld	s1,136(sp)
    80005b64:	690a                	ld	s2,128(sp)
    80005b66:	610d                	addi	sp,sp,160
    80005b68:	8082                	ret
    end_op();
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	772080e7          	jalr	1906(ra) # 800042dc <end_op>
    return -1;
    80005b72:	557d                	li	a0,-1
    80005b74:	b7ed                	j	80005b5e <sys_chdir+0x7a>
    iunlockput(ip);
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	f86080e7          	jalr	-122(ra) # 80003afe <iunlockput>
    end_op();
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	75c080e7          	jalr	1884(ra) # 800042dc <end_op>
    return -1;
    80005b88:	557d                	li	a0,-1
    80005b8a:	bfd1                	j	80005b5e <sys_chdir+0x7a>

0000000080005b8c <sys_exec>:

uint64
sys_exec(void)
{
    80005b8c:	7145                	addi	sp,sp,-464
    80005b8e:	e786                	sd	ra,456(sp)
    80005b90:	e3a2                	sd	s0,448(sp)
    80005b92:	ff26                	sd	s1,440(sp)
    80005b94:	fb4a                	sd	s2,432(sp)
    80005b96:	f74e                	sd	s3,424(sp)
    80005b98:	f352                	sd	s4,416(sp)
    80005b9a:	ef56                	sd	s5,408(sp)
    80005b9c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b9e:	08000613          	li	a2,128
    80005ba2:	f4040593          	addi	a1,s0,-192
    80005ba6:	4501                	li	a0,0
    80005ba8:	ffffd097          	auipc	ra,0xffffd
    80005bac:	1bc080e7          	jalr	444(ra) # 80002d64 <argstr>
    return -1;
    80005bb0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bb2:	0c054a63          	bltz	a0,80005c86 <sys_exec+0xfa>
    80005bb6:	e3840593          	addi	a1,s0,-456
    80005bba:	4505                	li	a0,1
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	186080e7          	jalr	390(ra) # 80002d42 <argaddr>
    80005bc4:	0c054163          	bltz	a0,80005c86 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bc8:	10000613          	li	a2,256
    80005bcc:	4581                	li	a1,0
    80005bce:	e4040513          	addi	a0,s0,-448
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	13a080e7          	jalr	314(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bda:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bde:	89a6                	mv	s3,s1
    80005be0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005be2:	02000a13          	li	s4,32
    80005be6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bea:	00391513          	slli	a0,s2,0x3
    80005bee:	e3040593          	addi	a1,s0,-464
    80005bf2:	e3843783          	ld	a5,-456(s0)
    80005bf6:	953e                	add	a0,a0,a5
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	08e080e7          	jalr	142(ra) # 80002c86 <fetchaddr>
    80005c00:	02054a63          	bltz	a0,80005c34 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c04:	e3043783          	ld	a5,-464(s0)
    80005c08:	c3b9                	beqz	a5,80005c4e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c0a:	ffffb097          	auipc	ra,0xffffb
    80005c0e:	f16080e7          	jalr	-234(ra) # 80000b20 <kalloc>
    80005c12:	85aa                	mv	a1,a0
    80005c14:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c18:	cd11                	beqz	a0,80005c34 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c1a:	6605                	lui	a2,0x1
    80005c1c:	e3043503          	ld	a0,-464(s0)
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	0b8080e7          	jalr	184(ra) # 80002cd8 <fetchstr>
    80005c28:	00054663          	bltz	a0,80005c34 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c2c:	0905                	addi	s2,s2,1
    80005c2e:	09a1                	addi	s3,s3,8
    80005c30:	fb491be3          	bne	s2,s4,80005be6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c34:	10048913          	addi	s2,s1,256
    80005c38:	6088                	ld	a0,0(s1)
    80005c3a:	c529                	beqz	a0,80005c84 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c3c:	ffffb097          	auipc	ra,0xffffb
    80005c40:	de8080e7          	jalr	-536(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	04a1                	addi	s1,s1,8
    80005c46:	ff2499e3          	bne	s1,s2,80005c38 <sys_exec+0xac>
  return -1;
    80005c4a:	597d                	li	s2,-1
    80005c4c:	a82d                	j	80005c86 <sys_exec+0xfa>
      argv[i] = 0;
    80005c4e:	0a8e                	slli	s5,s5,0x3
    80005c50:	fc040793          	addi	a5,s0,-64
    80005c54:	9abe                	add	s5,s5,a5
    80005c56:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c5a:	e4040593          	addi	a1,s0,-448
    80005c5e:	f4040513          	addi	a0,s0,-192
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	17c080e7          	jalr	380(ra) # 80004dde <exec>
    80005c6a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c6c:	10048993          	addi	s3,s1,256
    80005c70:	6088                	ld	a0,0(s1)
    80005c72:	c911                	beqz	a0,80005c86 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c74:	ffffb097          	auipc	ra,0xffffb
    80005c78:	db0080e7          	jalr	-592(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7c:	04a1                	addi	s1,s1,8
    80005c7e:	ff3499e3          	bne	s1,s3,80005c70 <sys_exec+0xe4>
    80005c82:	a011                	j	80005c86 <sys_exec+0xfa>
  return -1;
    80005c84:	597d                	li	s2,-1
}
    80005c86:	854a                	mv	a0,s2
    80005c88:	60be                	ld	ra,456(sp)
    80005c8a:	641e                	ld	s0,448(sp)
    80005c8c:	74fa                	ld	s1,440(sp)
    80005c8e:	795a                	ld	s2,432(sp)
    80005c90:	79ba                	ld	s3,424(sp)
    80005c92:	7a1a                	ld	s4,416(sp)
    80005c94:	6afa                	ld	s5,408(sp)
    80005c96:	6179                	addi	sp,sp,464
    80005c98:	8082                	ret

0000000080005c9a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c9a:	7139                	addi	sp,sp,-64
    80005c9c:	fc06                	sd	ra,56(sp)
    80005c9e:	f822                	sd	s0,48(sp)
    80005ca0:	f426                	sd	s1,40(sp)
    80005ca2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ca4:	ffffc097          	auipc	ra,0xffffc
    80005ca8:	efe080e7          	jalr	-258(ra) # 80001ba2 <myproc>
    80005cac:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cae:	fd840593          	addi	a1,s0,-40
    80005cb2:	4501                	li	a0,0
    80005cb4:	ffffd097          	auipc	ra,0xffffd
    80005cb8:	08e080e7          	jalr	142(ra) # 80002d42 <argaddr>
    return -1;
    80005cbc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cbe:	0e054063          	bltz	a0,80005d9e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cc2:	fc840593          	addi	a1,s0,-56
    80005cc6:	fd040513          	addi	a0,s0,-48
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	dba080e7          	jalr	-582(ra) # 80004a84 <pipealloc>
    return -1;
    80005cd2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cd4:	0c054563          	bltz	a0,80005d9e <sys_pipe+0x104>
  fd0 = -1;
    80005cd8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cdc:	fd043503          	ld	a0,-48(s0)
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	508080e7          	jalr	1288(ra) # 800051e8 <fdalloc>
    80005ce8:	fca42223          	sw	a0,-60(s0)
    80005cec:	08054c63          	bltz	a0,80005d84 <sys_pipe+0xea>
    80005cf0:	fc843503          	ld	a0,-56(s0)
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	4f4080e7          	jalr	1268(ra) # 800051e8 <fdalloc>
    80005cfc:	fca42023          	sw	a0,-64(s0)
    80005d00:	06054863          	bltz	a0,80005d70 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d04:	4691                	li	a3,4
    80005d06:	fc440613          	addi	a2,s0,-60
    80005d0a:	fd843583          	ld	a1,-40(s0)
    80005d0e:	68a8                	ld	a0,80(s1)
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	b52080e7          	jalr	-1198(ra) # 80001862 <copyout>
    80005d18:	02054063          	bltz	a0,80005d38 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d1c:	4691                	li	a3,4
    80005d1e:	fc040613          	addi	a2,s0,-64
    80005d22:	fd843583          	ld	a1,-40(s0)
    80005d26:	0591                	addi	a1,a1,4
    80005d28:	68a8                	ld	a0,80(s1)
    80005d2a:	ffffc097          	auipc	ra,0xffffc
    80005d2e:	b38080e7          	jalr	-1224(ra) # 80001862 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d32:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d34:	06055563          	bgez	a0,80005d9e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d38:	fc442783          	lw	a5,-60(s0)
    80005d3c:	07e9                	addi	a5,a5,26
    80005d3e:	078e                	slli	a5,a5,0x3
    80005d40:	97a6                	add	a5,a5,s1
    80005d42:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d46:	fc042503          	lw	a0,-64(s0)
    80005d4a:	0569                	addi	a0,a0,26
    80005d4c:	050e                	slli	a0,a0,0x3
    80005d4e:	9526                	add	a0,a0,s1
    80005d50:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d54:	fd043503          	ld	a0,-48(s0)
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	9d6080e7          	jalr	-1578(ra) # 8000472e <fileclose>
    fileclose(wf);
    80005d60:	fc843503          	ld	a0,-56(s0)
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	9ca080e7          	jalr	-1590(ra) # 8000472e <fileclose>
    return -1;
    80005d6c:	57fd                	li	a5,-1
    80005d6e:	a805                	j	80005d9e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d70:	fc442783          	lw	a5,-60(s0)
    80005d74:	0007c863          	bltz	a5,80005d84 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d78:	01a78513          	addi	a0,a5,26
    80005d7c:	050e                	slli	a0,a0,0x3
    80005d7e:	9526                	add	a0,a0,s1
    80005d80:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d84:	fd043503          	ld	a0,-48(s0)
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	9a6080e7          	jalr	-1626(ra) # 8000472e <fileclose>
    fileclose(wf);
    80005d90:	fc843503          	ld	a0,-56(s0)
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	99a080e7          	jalr	-1638(ra) # 8000472e <fileclose>
    return -1;
    80005d9c:	57fd                	li	a5,-1
}
    80005d9e:	853e                	mv	a0,a5
    80005da0:	70e2                	ld	ra,56(sp)
    80005da2:	7442                	ld	s0,48(sp)
    80005da4:	74a2                	ld	s1,40(sp)
    80005da6:	6121                	addi	sp,sp,64
    80005da8:	8082                	ret
    80005daa:	0000                	unimp
    80005dac:	0000                	unimp
	...

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	d63fc0ef          	jal	ra,80002b52 <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	710c                	ld	a1,32(a0)
    80005e4c:	7510                	ld	a2,40(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	cee080e7          	jalr	-786(ra) # 80001b76 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	cb6080e7          	jalr	-842(ra) # 80001b76 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	c8e080e7          	jalr	-882(ra) # 80001b76 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	04a7cc63          	blt	a5,a0,80005f68 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f14:	0001d797          	auipc	a5,0x1d
    80005f18:	0ec78793          	addi	a5,a5,236 # 80023000 <disk>
    80005f1c:	00a78733          	add	a4,a5,a0
    80005f20:	6789                	lui	a5,0x2
    80005f22:	97ba                	add	a5,a5,a4
    80005f24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f28:	eba1                	bnez	a5,80005f78 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f2a:	00451713          	slli	a4,a0,0x4
    80005f2e:	0001f797          	auipc	a5,0x1f
    80005f32:	0d27b783          	ld	a5,210(a5) # 80025000 <disk+0x2000>
    80005f36:	97ba                	add	a5,a5,a4
    80005f38:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f3c:	0001d797          	auipc	a5,0x1d
    80005f40:	0c478793          	addi	a5,a5,196 # 80023000 <disk>
    80005f44:	97aa                	add	a5,a5,a0
    80005f46:	6509                	lui	a0,0x2
    80005f48:	953e                	add	a0,a0,a5
    80005f4a:	4785                	li	a5,1
    80005f4c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f50:	0001f517          	auipc	a0,0x1f
    80005f54:	0c850513          	addi	a0,a0,200 # 80025018 <disk+0x2018>
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	5e0080e7          	jalr	1504(ra) # 80002538 <wakeup>
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f68:	00003517          	auipc	a0,0x3
    80005f6c:	8b850513          	addi	a0,a0,-1864 # 80008820 <syscalls+0x330>
    80005f70:	ffffa097          	auipc	ra,0xffffa
    80005f74:	5d8080e7          	jalr	1496(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005f78:	00003517          	auipc	a0,0x3
    80005f7c:	8c050513          	addi	a0,a0,-1856 # 80008838 <syscalls+0x348>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5c8080e7          	jalr	1480(ra) # 80000548 <panic>

0000000080005f88 <virtio_disk_init>:
{
    80005f88:	1101                	addi	sp,sp,-32
    80005f8a:	ec06                	sd	ra,24(sp)
    80005f8c:	e822                	sd	s0,16(sp)
    80005f8e:	e426                	sd	s1,8(sp)
    80005f90:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f92:	00003597          	auipc	a1,0x3
    80005f96:	8be58593          	addi	a1,a1,-1858 # 80008850 <syscalls+0x360>
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	10e50513          	addi	a0,a0,270 # 800250a8 <disk+0x20a8>
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	bde080e7          	jalr	-1058(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005faa:	100017b7          	lui	a5,0x10001
    80005fae:	4398                	lw	a4,0(a5)
    80005fb0:	2701                	sext.w	a4,a4
    80005fb2:	747277b7          	lui	a5,0x74727
    80005fb6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fba:	0ef71163          	bne	a4,a5,8000609c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	43dc                	lw	a5,4(a5)
    80005fc4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc6:	4705                	li	a4,1
    80005fc8:	0ce79a63          	bne	a5,a4,8000609c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fcc:	100017b7          	lui	a5,0x10001
    80005fd0:	479c                	lw	a5,8(a5)
    80005fd2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fd4:	4709                	li	a4,2
    80005fd6:	0ce79363          	bne	a5,a4,8000609c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fda:	100017b7          	lui	a5,0x10001
    80005fde:	47d8                	lw	a4,12(a5)
    80005fe0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe2:	554d47b7          	lui	a5,0x554d4
    80005fe6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fea:	0af71963          	bne	a4,a5,8000609c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	100017b7          	lui	a5,0x10001
    80005ff2:	4705                	li	a4,1
    80005ff4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff6:	470d                	li	a4,3
    80005ff8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ffa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ffc:	c7ffe737          	lui	a4,0xc7ffe
    80006000:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80006004:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006006:	2701                	sext.w	a4,a4
    80006008:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600a:	472d                	li	a4,11
    8000600c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600e:	473d                	li	a4,15
    80006010:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006012:	6705                	lui	a4,0x1
    80006014:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006016:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000601a:	5bdc                	lw	a5,52(a5)
    8000601c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000601e:	c7d9                	beqz	a5,800060ac <virtio_disk_init+0x124>
  if(max < NUM)
    80006020:	471d                	li	a4,7
    80006022:	08f77d63          	bgeu	a4,a5,800060bc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006026:	100014b7          	lui	s1,0x10001
    8000602a:	47a1                	li	a5,8
    8000602c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000602e:	6609                	lui	a2,0x2
    80006030:	4581                	li	a1,0
    80006032:	0001d517          	auipc	a0,0x1d
    80006036:	fce50513          	addi	a0,a0,-50 # 80023000 <disk>
    8000603a:	ffffb097          	auipc	ra,0xffffb
    8000603e:	cd2080e7          	jalr	-814(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006042:	0001d717          	auipc	a4,0x1d
    80006046:	fbe70713          	addi	a4,a4,-66 # 80023000 <disk>
    8000604a:	00c75793          	srli	a5,a4,0xc
    8000604e:	2781                	sext.w	a5,a5
    80006050:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006052:	0001f797          	auipc	a5,0x1f
    80006056:	fae78793          	addi	a5,a5,-82 # 80025000 <disk+0x2000>
    8000605a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000605c:	0001d717          	auipc	a4,0x1d
    80006060:	02470713          	addi	a4,a4,36 # 80023080 <disk+0x80>
    80006064:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006066:	0001e717          	auipc	a4,0x1e
    8000606a:	f9a70713          	addi	a4,a4,-102 # 80024000 <disk+0x1000>
    8000606e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006070:	4705                	li	a4,1
    80006072:	00e78c23          	sb	a4,24(a5)
    80006076:	00e78ca3          	sb	a4,25(a5)
    8000607a:	00e78d23          	sb	a4,26(a5)
    8000607e:	00e78da3          	sb	a4,27(a5)
    80006082:	00e78e23          	sb	a4,28(a5)
    80006086:	00e78ea3          	sb	a4,29(a5)
    8000608a:	00e78f23          	sb	a4,30(a5)
    8000608e:	00e78fa3          	sb	a4,31(a5)
}
    80006092:	60e2                	ld	ra,24(sp)
    80006094:	6442                	ld	s0,16(sp)
    80006096:	64a2                	ld	s1,8(sp)
    80006098:	6105                	addi	sp,sp,32
    8000609a:	8082                	ret
    panic("could not find virtio disk");
    8000609c:	00002517          	auipc	a0,0x2
    800060a0:	7c450513          	addi	a0,a0,1988 # 80008860 <syscalls+0x370>
    800060a4:	ffffa097          	auipc	ra,0xffffa
    800060a8:	4a4080e7          	jalr	1188(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800060ac:	00002517          	auipc	a0,0x2
    800060b0:	7d450513          	addi	a0,a0,2004 # 80008880 <syscalls+0x390>
    800060b4:	ffffa097          	auipc	ra,0xffffa
    800060b8:	494080e7          	jalr	1172(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    800060bc:	00002517          	auipc	a0,0x2
    800060c0:	7e450513          	addi	a0,a0,2020 # 800088a0 <syscalls+0x3b0>
    800060c4:	ffffa097          	auipc	ra,0xffffa
    800060c8:	484080e7          	jalr	1156(ra) # 80000548 <panic>

00000000800060cc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060cc:	7119                	addi	sp,sp,-128
    800060ce:	fc86                	sd	ra,120(sp)
    800060d0:	f8a2                	sd	s0,112(sp)
    800060d2:	f4a6                	sd	s1,104(sp)
    800060d4:	f0ca                	sd	s2,96(sp)
    800060d6:	ecce                	sd	s3,88(sp)
    800060d8:	e8d2                	sd	s4,80(sp)
    800060da:	e4d6                	sd	s5,72(sp)
    800060dc:	e0da                	sd	s6,64(sp)
    800060de:	fc5e                	sd	s7,56(sp)
    800060e0:	f862                	sd	s8,48(sp)
    800060e2:	f466                	sd	s9,40(sp)
    800060e4:	f06a                	sd	s10,32(sp)
    800060e6:	0100                	addi	s0,sp,128
    800060e8:	892a                	mv	s2,a0
    800060ea:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060ec:	00c52c83          	lw	s9,12(a0)
    800060f0:	001c9c9b          	slliw	s9,s9,0x1
    800060f4:	1c82                	slli	s9,s9,0x20
    800060f6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060fa:	0001f517          	auipc	a0,0x1f
    800060fe:	fae50513          	addi	a0,a0,-82 # 800250a8 <disk+0x20a8>
    80006102:	ffffb097          	auipc	ra,0xffffb
    80006106:	b0e080e7          	jalr	-1266(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    8000610a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000610c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000610e:	0001db97          	auipc	s7,0x1d
    80006112:	ef2b8b93          	addi	s7,s7,-270 # 80023000 <disk>
    80006116:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006118:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000611a:	8a4e                	mv	s4,s3
    8000611c:	a051                	j	800061a0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000611e:	00fb86b3          	add	a3,s7,a5
    80006122:	96da                	add	a3,a3,s6
    80006124:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006128:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000612a:	0207c563          	bltz	a5,80006154 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000612e:	2485                	addiw	s1,s1,1
    80006130:	0711                	addi	a4,a4,4
    80006132:	23548d63          	beq	s1,s5,8000636c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006136:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006138:	0001f697          	auipc	a3,0x1f
    8000613c:	ee068693          	addi	a3,a3,-288 # 80025018 <disk+0x2018>
    80006140:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006142:	0006c583          	lbu	a1,0(a3)
    80006146:	fde1                	bnez	a1,8000611e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006148:	2785                	addiw	a5,a5,1
    8000614a:	0685                	addi	a3,a3,1
    8000614c:	ff879be3          	bne	a5,s8,80006142 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006150:	57fd                	li	a5,-1
    80006152:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006154:	02905a63          	blez	s1,80006188 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006158:	f9042503          	lw	a0,-112(s0)
    8000615c:	00000097          	auipc	ra,0x0
    80006160:	daa080e7          	jalr	-598(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006164:	4785                	li	a5,1
    80006166:	0297d163          	bge	a5,s1,80006188 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000616a:	f9442503          	lw	a0,-108(s0)
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	d98080e7          	jalr	-616(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006176:	4789                	li	a5,2
    80006178:	0097d863          	bge	a5,s1,80006188 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000617c:	f9842503          	lw	a0,-104(s0)
    80006180:	00000097          	auipc	ra,0x0
    80006184:	d86080e7          	jalr	-634(ra) # 80005f06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006188:	0001f597          	auipc	a1,0x1f
    8000618c:	f2058593          	addi	a1,a1,-224 # 800250a8 <disk+0x20a8>
    80006190:	0001f517          	auipc	a0,0x1f
    80006194:	e8850513          	addi	a0,a0,-376 # 80025018 <disk+0x2018>
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	21a080e7          	jalr	538(ra) # 800023b2 <sleep>
  for(int i = 0; i < 3; i++){
    800061a0:	f9040713          	addi	a4,s0,-112
    800061a4:	84ce                	mv	s1,s3
    800061a6:	bf41                	j	80006136 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800061a8:	4785                	li	a5,1
    800061aa:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800061ae:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800061b2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800061b6:	f9042983          	lw	s3,-112(s0)
    800061ba:	00499493          	slli	s1,s3,0x4
    800061be:	0001fa17          	auipc	s4,0x1f
    800061c2:	e42a0a13          	addi	s4,s4,-446 # 80025000 <disk+0x2000>
    800061c6:	000a3a83          	ld	s5,0(s4)
    800061ca:	9aa6                	add	s5,s5,s1
    800061cc:	f8040513          	addi	a0,s0,-128
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	ffe080e7          	jalr	-2(ra) # 800011ce <kvmpa>
    800061d8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800061dc:	000a3783          	ld	a5,0(s4)
    800061e0:	97a6                	add	a5,a5,s1
    800061e2:	4741                	li	a4,16
    800061e4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061e6:	000a3783          	ld	a5,0(s4)
    800061ea:	97a6                	add	a5,a5,s1
    800061ec:	4705                	li	a4,1
    800061ee:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061f2:	f9442703          	lw	a4,-108(s0)
    800061f6:	000a3783          	ld	a5,0(s4)
    800061fa:	97a6                	add	a5,a5,s1
    800061fc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006200:	0712                	slli	a4,a4,0x4
    80006202:	000a3783          	ld	a5,0(s4)
    80006206:	97ba                	add	a5,a5,a4
    80006208:	05890693          	addi	a3,s2,88
    8000620c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000620e:	000a3783          	ld	a5,0(s4)
    80006212:	97ba                	add	a5,a5,a4
    80006214:	40000693          	li	a3,1024
    80006218:	c794                	sw	a3,8(a5)
  if(write)
    8000621a:	100d0a63          	beqz	s10,8000632e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000621e:	0001f797          	auipc	a5,0x1f
    80006222:	de27b783          	ld	a5,-542(a5) # 80025000 <disk+0x2000>
    80006226:	97ba                	add	a5,a5,a4
    80006228:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000622c:	0001d517          	auipc	a0,0x1d
    80006230:	dd450513          	addi	a0,a0,-556 # 80023000 <disk>
    80006234:	0001f797          	auipc	a5,0x1f
    80006238:	dcc78793          	addi	a5,a5,-564 # 80025000 <disk+0x2000>
    8000623c:	6394                	ld	a3,0(a5)
    8000623e:	96ba                	add	a3,a3,a4
    80006240:	00c6d603          	lhu	a2,12(a3)
    80006244:	00166613          	ori	a2,a2,1
    80006248:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000624c:	f9842683          	lw	a3,-104(s0)
    80006250:	6390                	ld	a2,0(a5)
    80006252:	9732                	add	a4,a4,a2
    80006254:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006258:	20098613          	addi	a2,s3,512
    8000625c:	0612                	slli	a2,a2,0x4
    8000625e:	962a                	add	a2,a2,a0
    80006260:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006264:	00469713          	slli	a4,a3,0x4
    80006268:	6394                	ld	a3,0(a5)
    8000626a:	96ba                	add	a3,a3,a4
    8000626c:	6589                	lui	a1,0x2
    8000626e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006272:	94ae                	add	s1,s1,a1
    80006274:	94aa                	add	s1,s1,a0
    80006276:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006278:	6394                	ld	a3,0(a5)
    8000627a:	96ba                	add	a3,a3,a4
    8000627c:	4585                	li	a1,1
    8000627e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006280:	6394                	ld	a3,0(a5)
    80006282:	96ba                	add	a3,a3,a4
    80006284:	4509                	li	a0,2
    80006286:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000628a:	6394                	ld	a3,0(a5)
    8000628c:	9736                	add	a4,a4,a3
    8000628e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006292:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006296:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000629a:	6794                	ld	a3,8(a5)
    8000629c:	0026d703          	lhu	a4,2(a3)
    800062a0:	8b1d                	andi	a4,a4,7
    800062a2:	2709                	addiw	a4,a4,2
    800062a4:	0706                	slli	a4,a4,0x1
    800062a6:	9736                	add	a4,a4,a3
    800062a8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800062ac:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062b0:	6798                	ld	a4,8(a5)
    800062b2:	00275783          	lhu	a5,2(a4)
    800062b6:	2785                	addiw	a5,a5,1
    800062b8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c4:	00492703          	lw	a4,4(s2)
    800062c8:	4785                	li	a5,1
    800062ca:	02f71163          	bne	a4,a5,800062ec <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800062ce:	0001f997          	auipc	s3,0x1f
    800062d2:	dda98993          	addi	s3,s3,-550 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062d8:	85ce                	mv	a1,s3
    800062da:	854a                	mv	a0,s2
    800062dc:	ffffc097          	auipc	ra,0xffffc
    800062e0:	0d6080e7          	jalr	214(ra) # 800023b2 <sleep>
  while(b->disk == 1) {
    800062e4:	00492783          	lw	a5,4(s2)
    800062e8:	fe9788e3          	beq	a5,s1,800062d8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800062ec:	f9042483          	lw	s1,-112(s0)
    800062f0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800062f4:	00479713          	slli	a4,a5,0x4
    800062f8:	0001d797          	auipc	a5,0x1d
    800062fc:	d0878793          	addi	a5,a5,-760 # 80023000 <disk>
    80006300:	97ba                	add	a5,a5,a4
    80006302:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006306:	0001f917          	auipc	s2,0x1f
    8000630a:	cfa90913          	addi	s2,s2,-774 # 80025000 <disk+0x2000>
    free_desc(i);
    8000630e:	8526                	mv	a0,s1
    80006310:	00000097          	auipc	ra,0x0
    80006314:	bf6080e7          	jalr	-1034(ra) # 80005f06 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006318:	0492                	slli	s1,s1,0x4
    8000631a:	00093783          	ld	a5,0(s2)
    8000631e:	94be                	add	s1,s1,a5
    80006320:	00c4d783          	lhu	a5,12(s1)
    80006324:	8b85                	andi	a5,a5,1
    80006326:	cf89                	beqz	a5,80006340 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006328:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000632c:	b7cd                	j	8000630e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000632e:	0001f797          	auipc	a5,0x1f
    80006332:	cd27b783          	ld	a5,-814(a5) # 80025000 <disk+0x2000>
    80006336:	97ba                	add	a5,a5,a4
    80006338:	4689                	li	a3,2
    8000633a:	00d79623          	sh	a3,12(a5)
    8000633e:	b5fd                	j	8000622c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006340:	0001f517          	auipc	a0,0x1f
    80006344:	d6850513          	addi	a0,a0,-664 # 800250a8 <disk+0x20a8>
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	97c080e7          	jalr	-1668(ra) # 80000cc4 <release>
}
    80006350:	70e6                	ld	ra,120(sp)
    80006352:	7446                	ld	s0,112(sp)
    80006354:	74a6                	ld	s1,104(sp)
    80006356:	7906                	ld	s2,96(sp)
    80006358:	69e6                	ld	s3,88(sp)
    8000635a:	6a46                	ld	s4,80(sp)
    8000635c:	6aa6                	ld	s5,72(sp)
    8000635e:	6b06                	ld	s6,64(sp)
    80006360:	7be2                	ld	s7,56(sp)
    80006362:	7c42                	ld	s8,48(sp)
    80006364:	7ca2                	ld	s9,40(sp)
    80006366:	7d02                	ld	s10,32(sp)
    80006368:	6109                	addi	sp,sp,128
    8000636a:	8082                	ret
  if(write)
    8000636c:	e20d1ee3          	bnez	s10,800061a8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006370:	f8042023          	sw	zero,-128(s0)
    80006374:	bd2d                	j	800061ae <virtio_disk_rw+0xe2>

0000000080006376 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006376:	1101                	addi	sp,sp,-32
    80006378:	ec06                	sd	ra,24(sp)
    8000637a:	e822                	sd	s0,16(sp)
    8000637c:	e426                	sd	s1,8(sp)
    8000637e:	e04a                	sd	s2,0(sp)
    80006380:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006382:	0001f517          	auipc	a0,0x1f
    80006386:	d2650513          	addi	a0,a0,-730 # 800250a8 <disk+0x20a8>
    8000638a:	ffffb097          	auipc	ra,0xffffb
    8000638e:	886080e7          	jalr	-1914(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006392:	0001f717          	auipc	a4,0x1f
    80006396:	c6e70713          	addi	a4,a4,-914 # 80025000 <disk+0x2000>
    8000639a:	02075783          	lhu	a5,32(a4)
    8000639e:	6b18                	ld	a4,16(a4)
    800063a0:	00275683          	lhu	a3,2(a4)
    800063a4:	8ebd                	xor	a3,a3,a5
    800063a6:	8a9d                	andi	a3,a3,7
    800063a8:	cab9                	beqz	a3,800063fe <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063aa:	0001d917          	auipc	s2,0x1d
    800063ae:	c5690913          	addi	s2,s2,-938 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063b2:	0001f497          	auipc	s1,0x1f
    800063b6:	c4e48493          	addi	s1,s1,-946 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063ba:	078e                	slli	a5,a5,0x3
    800063bc:	97ba                	add	a5,a5,a4
    800063be:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063c0:	20078713          	addi	a4,a5,512
    800063c4:	0712                	slli	a4,a4,0x4
    800063c6:	974a                	add	a4,a4,s2
    800063c8:	03074703          	lbu	a4,48(a4)
    800063cc:	ef21                	bnez	a4,80006424 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063ce:	20078793          	addi	a5,a5,512
    800063d2:	0792                	slli	a5,a5,0x4
    800063d4:	97ca                	add	a5,a5,s2
    800063d6:	7798                	ld	a4,40(a5)
    800063d8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063dc:	7788                	ld	a0,40(a5)
    800063de:	ffffc097          	auipc	ra,0xffffc
    800063e2:	15a080e7          	jalr	346(ra) # 80002538 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063e6:	0204d783          	lhu	a5,32(s1)
    800063ea:	2785                	addiw	a5,a5,1
    800063ec:	8b9d                	andi	a5,a5,7
    800063ee:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063f2:	6898                	ld	a4,16(s1)
    800063f4:	00275683          	lhu	a3,2(a4)
    800063f8:	8a9d                	andi	a3,a3,7
    800063fa:	fcf690e3          	bne	a3,a5,800063ba <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063fe:	10001737          	lui	a4,0x10001
    80006402:	533c                	lw	a5,96(a4)
    80006404:	8b8d                	andi	a5,a5,3
    80006406:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006408:	0001f517          	auipc	a0,0x1f
    8000640c:	ca050513          	addi	a0,a0,-864 # 800250a8 <disk+0x20a8>
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	8b4080e7          	jalr	-1868(ra) # 80000cc4 <release>
}
    80006418:	60e2                	ld	ra,24(sp)
    8000641a:	6442                	ld	s0,16(sp)
    8000641c:	64a2                	ld	s1,8(sp)
    8000641e:	6902                	ld	s2,0(sp)
    80006420:	6105                	addi	sp,sp,32
    80006422:	8082                	ret
      panic("virtio_disk_intr status");
    80006424:	00002517          	auipc	a0,0x2
    80006428:	49c50513          	addi	a0,a0,1180 # 800088c0 <syscalls+0x3d0>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	11c080e7          	jalr	284(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
