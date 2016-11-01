#include <mips/regdef.h>
#include <sys/syscall.h>

    # typedef struct param_t {
    #  0  float UL_re;
    #  4  float UL_im;
    #  8  float LR_re;
    # 12  float LR_im;
    # 16  float d_re;
    # 20  float d_im;
    # 24  float cp_re;
    # 28  float cp_im;
    # 32  size_t x_res;
    # 36  size_t y_res;
    # 40  size_t shades;
    # 44  FILE *fp;


#define	TAM_FRAME	92
#define	SRA_RA		84
#define	SRA_FP		80
#define	SRA_GP		76


  .text
  .globl mips32_plot
  .ent mips32_plot

mips32_plot:
  .frame	$fp,TAM_FRAME,ra   #creo stack
  .set	noreorder
  .cpload	t9
  .set	reorder
  subu	sp,sp,TAM_FRAME

  .cprestore	SRA_GP         #almaceno SRA
  sw		ra,SRA_RA(sp)
  sw		$fp,SRA_FP(sp)
  sw		gp,SRA_GP(sp)
  move	$fp,sp

  sw		a0,TAM_FRAME(sp)     #almaceno argumento

  lw    t1, TAM_FRAME(sp)
  l.s   $f0, 24(t1)          # cpr = parms->cp_re
  s.s   $f0, 60(sp)          # guardo cpr
  l.s   $f0, 28(t1)          # cpi = parms->cp_im
  s.s   $f0, 64(sp)          # guardo cpi
 
  lw    t0,TAM_FRAME(sp)
  lw    a0,44(t0)            #llamo a fdopen para abrir el archivo
  la    a1,1
  la    t9,fdopen
  jal   ra,t9
  la    a0, handler          
  sw    v0, 68(sp)           #guardo el resultado de fdopen en fp pos 68 

  lw    t0,TAM_FRAME(sp)
  lw    a0,68(sp)            #cargo en a0 fp
  la    a1, format2
  lw    a2,32(t0)            #x_res
  lw    a3,36(t0)            #y_res
  lw    a4,40(t0)            #shades
  la    t9,fprintf
  jal   ra,t9
  sw    v0, 56(sp)           #guardo el resultado de fprintf en res pos 56 

  lw    t0, 56(sp)
  bltz  t0, returnmenos1
 
  sw    zero, 48(sp)         # guardo y = 0
  lw    t1, TAM_FRAME(sp)
  l.s 	$f0, 4(t1)  			   # ci = UL_im
  s.s   $f0, 20(sp)          # guardo ci

for1:

  lw    t0, 32(sp)           # cargo y
  lw    t1, TAM_FRAME(sp)
  lw 	  t2, 36(t1)			     # cargo y_res
  bge	  t0, t2, if3	         # si y < y_res entra al for1 sino va a if3

  sw    zero, 44(sp)         # guardo x = 0
  lw    t1, TAM_FRAME(sp)
  l.s   $f0, 0(t1)		       # cargo en t2 = parms->UL_re
  s.s   $f0, 16(sp)          # guardo cr = parms->UL_re

for2:

  lw    t0, 44(sp)           #cargo x
  lw    t1, TAM_FRAME(sp)
  lw    t2, 32(t1)           #cargo parms->x_res
  bge   t0,t2,endFor2	       # si x < x_res entra al for2 sino va a endFor2

  l.s   $f0, 16(sp)          #cargo cr
  s.s   $f0, 24(sp)          #guardo zr = cr
  l.s   $f0, 20(sp)          #cargo ci
  s.s   $f0, 28(sp)          #guardo zi = ci

  sw    zero, 52(sp)         #guardo c=0

for3:

  lw    t0,	52(sp)  		    # cargo c
  lw    t1, TAM_FRAME(sp)
  lw    t2, 40(t1)			    # cargo shades
  bge 	t0, t2, endFor3     # si c < parms->shades entra a for3 sino va a endFor3

if1:

  l.s   $f4,24(sp)          # cargo zr
  mul.s $f6,$f4,$f4 		    # f6 es zr*zr
  l.s   $f8,28(sp)          # cargo zi
  mul.s $f10,$f8,$f8     		# f10 es zi*zi
  add.s $f12,$f4,$f10    		# f4 = f4 + f10 = zr*zr + zi*zi
  s.s   $f12,40(sp)         # absz = f4
  l.s   $f14,cuatro
  c.lt.s  $f12,$f14 	      # si es menor a 4 continua, si es mayor o igual 4 rompe el ciclo
  bc1f  endFor3


  #calculo zr * zr - zi * zi + cpr

  sub.s $f10,$f6,$f10       # f6 - f8
  l.s   $f12,60(sp)         # cargo cpr
  add.s $f14,$f10,$f12      # zr * zr - zi * zi + cpr
  s.s   $f14,32(sp)         # guardo resultado en sr

  #calculo 2 * zr * zi + cpi

  l.s   $f16,dos
  mul.s $f16,$f16,$f4        # 2 * zr
  mul.s $f16,$f16,$f8        # 2 * zr * zi
  l.s   $f12,60(sp)          # cargo cpi
  add.s $f14,$f10,$f12       # 2 * zr * zi + cpi
  s.s   $f14,36(sp)          # guardo resultado en si

  l.s   $f0,32(sp)
  s.s   $f0,24(sp)           #zr = sr

  l.s   $f0,36(sp)
  s.s   $f0,28(sp)           #zi = si

endIf1:
  lw    t0,52(sp)            #cargo c
  addu  t0,t0,1              #++c
  sw    t0,52(sp)
  b     for3

endFor3:

  lw    t0,TAM_FRAME(sp)
  lw    a0, 44(sp)           #cargo fp
  la    a1,format1
  lw    a2,52(sp)			       # cargo C
  la    t9,fprintf           # imprimo 
  jal   ra,t9

  bltz  v0,if2

  lw    t0,44(sp)           #cargo x
  addu  t0,t0,1             #++x
  sw    t0,44(sp)
  lw    t2,TAM_FRAME(sp)
  l.s  	$f4,16(t2)			    # cargo d_re
  l.s   $f6,16(sp)          # cargo cr
  add.s	$f6,$f6,$f4			    # cr += d_re
  s.s   $f6,16(sp)          # guardo cr
  b     for2

if2:

  li	v0, SYS_write
  li	a0, 2                 # a0: stderr file descriptor.
  la	a1, io_error          # a1: mensaje de error.
  li	a2, 11	              # a2: data length
  syscall

  li    v0, zero            # return -1
  subu  v0,v0,1
  j ra

endFor2:

  lw    t1,48(sp)           # cargo y
  addu	t1,t1, 1			      # ++y
  sw    t1,48(sp)           # guardo y
  lw    t2,TAM_FRAME(sp)
  l.s  	$f4,20(t2)			    # cargo d_im
  l.s   $f6,20(sp)          # cargo ci
  sub.s $f6,$f6,$f4			    # ci -= d_im
  s.s   $f6,20(sp)          # guardo ci
  b     for1

if3:

  lw    a0, 44(sp)          # cargo fp
  la    t9,fflush           # llamo a fflush
  jal   ra,t9

  beqz  v0, end             # si es 0 termino sino es error

  li	v0, SYS_write
  li	a0, 2                 # a0: stderr file descriptor.
  la	a1, f_error           # a1: mensaje de error.
  li	a2, 26	              # a2: data length
  syscall

  li    v0, zero            # return -1
  subu  v0,v0,1
  j ra

returnmenos1:
  li  v0, SYS_write
  li  a0, 2                 # a0: stderr file descriptor.
  la  a1, io_error          # a1: mensaje de error.
  li  a2, 11                # a2: data length
  syscall
  li    v0, zero            # return -1
  subu  v0,v0,1
  j ra
  j ra
  b end

end:

  move	sp,$fp				       #detruyo stack
  lw		ra,SRA_RA(sp)
  lw		$fp,SRA_FP(sp)
  addu	sp,sp,TAM_FRAME
  j     ra

  .end mips32_plot

.data
handler:  .word 0
format1:  .asciiz "%u\n"
format2:  .asciiz "P2\n%u\n%u\n%u\n"
io_error: .asciiz "i/o error.\n"
f_error:  .asciiz "cannot flush output file.\n"
cuatro:   .float 4.0
tres:     .float 3.0
dos:      .float 2.0
