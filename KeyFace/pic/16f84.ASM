;
	LIST C=.128,P=16F84,R=dec
;
; ***********************************************************************
; *									*
; *				    					*
; * Obsluha PROFACE Keyboard - AT V1.0					*
; *									*
; * Verzia pre PIC84 - ladiaca						*
; *									*
; * 									*
; * (C)MDV 08.08.1997							*
; *									*
; *				 					*
; ***********************************************************************
;
;**************
;
; Predefinicie
;
	include	"P16F84.INC"
;
; MACRA
;
	include "mdv1.mac"
;
;**************
;
; Procesor: PIC16C84/XT ~4Mhz 
;
	__CONFIG 	_CP_OFF & _PWRTE_OFF & _WDT_ON & _HS_OSC
;
;******************************
;
; TYP AT V1.0
;
k_typ	equ	0xF1		;F0 = XT, F1 = AT
k_ver	equ	0xF1		;V1.0	(1)
k_ver1	equ	0xF0		;	(0)	
;
;
;**********************************************************
;
; Priradenie portov - VAZBA na HARDWARE
;
; Brana A
; 
#define	clki	PORTA,0	;CLK z key 			IN
#define datai 	PORTA,1	;Data z key  			IN
#define clko 	PORTA,2	;CLK do key			OUT
#define	datao	PORTA,3	;DATA do key 			OUT
;
; Mod pre branu A
;
mode_A	equ	b'11110011'
ini_A	equ	b'00001100'	;INICIALIZACIA A
;
;**
;
; Brana B
;
; A0-A2 ... B0..B2 	;Adresa do 8804
;
#define	d0	PORTB,3	;Data do 8804 bit 0		OUT
#define	d1	PORTB,4	;Data do 8804 bit 1		OUT
#define	d2	PORTB,5	;Data do 8804 bit 2		OUT
#define	wr1	PORTB,6	;WR do 8804 1.			OUT
#define	wr2	PORTB,7	;WR do 8804 2.			OUT
	
amask	equ	0x07	;Maska adresy v 8804 na PORT-e B
;
; Mod pre branu B
;
mode_B	equ	b'00000000'
ini_B	equ	b'00000000'
;
;******************************
;
; Obsadenie registrov - ZAKLAD
;
;**************
;
	cblock	0x20
;
;**************
;
	i	;Univerzalne registre
	j

	flag
	flag2	
	last
;
;****
;
	endc
	cblock 0xC
;
;****
;	
	scan	;Pamat vstupu key
	
	mc0	;Pamat matice
	mc1	
	mc2
	mc3
	mc4
;
; Registre programovatelnych klaves
;
	k_F1
	k_F2
	k_F3
	k_F4
	k_F5
	k_F6
	k_F7
	k_F8
	k_INS
	k_DEL
	k_HOME
	k_END
	k_PGUP
	k_PGDW
;	
;
;**************
;
	endc	;!!!
;
;******************************
;
; Duplovane priradenia
;
zx_key	equ	scan
flag3	equ	last
;
; Registre pri SCAN rezime
;
ukr	equ	flag2		;ukazovatel pre citanie z buffra    (5biyov!)
ukw	equ	last		;ukazovatel pre zapis do buffra     (5bitov!)
muk	equ	0x1f		;Maska platnych bitov ukazovatelov
buff	equ	mc0		;Buffer klavesnice 19 byte
b_siz	equ	.19		;velkost BUFF
;
;******************************
;
; Bitove priznaky
;
#define	k_CS	mc0,0		;Klavesa CS v matici
#define	k_SS	mc1,7		;Klavesa SS v matici
;
;***
;
; FLAG:
;
#define	pALT	flag,7		;priznak stlacenia ALT
#define	pCTRL	flag,6		;priznak stlacenia CTRL
#define	pSH	flag,5		;priznak stlacenia SHIFT

#define	sine	flag,3		;povolenie sinclair JOYSTICKU 	:1-ANO
#define	exte	flag,2		;povolenie extend		:0-ANO
#define	kone	flag,1		;povolenie konverzie AT 0-9	:0-ANO
#define	scane	flag,0		;=1 SCAN			:1-ANO

bscane	equ	0		;Cislo bitu SCANE


mALT	equ	0x80		;maska bitu ALT ...
mCTRL	equ	0x40
mSH	equ	0x20
mSINE	equ	0x08
mEXTE	equ	0x04
mKONE	equ	0x02

mcFLAG	equ	0x06		;Maska nulovanie FLAG, ostane mod klavesnice
;
;***
;
#define	pE0	STATUS,7	;priznak kodu prefixu E0
#define	pF0	STATUS,6	;priznak pustenia klavesy 
;
;***
;
; FLAG2:
;
#define	pRG	flag2,0		;priznak stlacenia CURR RIGHT, CS+8
#define	pLF	flag2,1		;...		   CURR LEFT , CS+5
#define	pDW	flag2,2		;...		   CURR DOWN , CS+6
#define	pUP	flag2,3		;...		   CURR UP   , CS+7
#define	pKK	flag2,4		;Priznak stlacenej konvertovanej klavesy
#define	pEK	flag2,5		;Priznak stlacenej klavesy s EXT modom
#define	set_k	flag2,7		;prizkak kodu programovatelnej klavesy

mRG	equ	0x01		;masky priznakovych bitov
mLF	equ	0x02
mDW	equ	0x04
mUP	equ	0x08
mCUR	equ	0x0f		;maska pre vsetky priznaky
mset_k	equ	0x80		;Maska priznaku definovania klavesy
;
;
; FLAG3:	
;
#define	kZ	flag3,7		;Priznak potvrdenia scan klavesou Z
#define	sOUT	flag3,6		;Priznak, ze je odoslany SCAN kod 

mkZ	equ	0x80		;Maska na inverziu KZ
;	
;*************************************************************************
;
; Scan kody 
;
sc_ESC	equ	0x13
sc_CTRL	equ	0x14
sc_ALT	equ	0x11
sc_DEL	equ	0x20
sc_NBB	equ	0x6F
sc_APS	equ	0x5F
sc_SHR	equ	0x59
sc_SHL	equ	0x12
sc_F10	equ	0x9
sc_F11	equ	0x8
sc_F12	equ	0x7
sc_UP	equ	0x3F
sc_DW	equ	0x40
sc_LF	equ	0x38
sc_RG	equ	0x39
;	
;*****
;
; Klavesy ZX
;
zx_CS	equ	.0
zx_A	equ	.1
zx_Q	equ	.2
zx_1	equ	.3	
zx_0	equ	.4
zx_P	equ	.5
zx_ENT	equ	.6
zx_SP	equ	.7
zx_Z	equ	.8
zx_S	equ	.9 
zx_W	equ	.10
zx_2	equ	.11
zx_9	equ	.12
zx_O	equ	.13
zx_L	equ	.14
zx_SS	equ	.15
zx_X	equ	.16
zx_D	equ	.17
zx_E	equ	.18
zx_3	equ	.19
zx_8	equ	.20
zx_I	equ	.21
zx_K	equ	.22
zx_M	equ	.23
zx_C	equ	.24
zx_F	equ	.25
zx_R	equ	.26
zx_4	equ	.27
zx_7	equ	.28
zx_U	equ	.29
zx_J	equ	.30
zx_N	equ	.31
zx_V	equ	.32
zx_G	equ	.33
zx_T	equ	.34
zx_5	equ	.35
zx_6	equ	.36 
zx_Y	equ	.37
zx_H	equ	.38
zx_B	equ	.39
;
; Prefixi
;
pCS	equ	.40
pSS	equ	.80
pEXT	equ	.120
pEXT_CS	equ	.160
pEXT_SS	equ	.200
;
; Programovatelne klavesy
;
pk_F1	equ	.240	
pk_F2	equ	.241
pk_F3	equ	.242
pk_F4	equ	.243
pk_F5	equ	.244
pk_F6	equ	.245
pk_F7	equ	.246
pk_F8	equ	.247
pk_INS	equ	.248
pk_DEL	equ	.249
pk_HOME	equ	.250
pk_END	equ	.251
pk_PGUP	equ	.252
pk_PGDW	equ	.253
;
; Ziadna klavesa
;
zx_NIC	equ	.255		
;

;*****************************************************************************
;
; Prva polovica PAMATE - STRANKA 0
;
;*****************************************************************************
;
	org	0

	goto	main		;Pre PIC 84
;
;******************************
;
; Tabulky
;
;******************************
;
; Konverzia SCAN kodov >6F na kody do 6F
;
rdkon1:	addwf	PCL,f

	retlw	0x68		;70 -> 	68	NB0
	retlw	0x6F		;71 -> 	6F	NB.
	retlw	0x6A		;72 -> 	6A	NB2
	retlw	0x67		;73 -> 	67	NB5
	retlw	0x65		;74 -> 	65	NB6
	retlw	0x6D		;75 -> 	6D	NB8
	retlw	0x13		;76 -> 	13	ESC
	retlw	0x57		;77 -> 	57	NUM LOCK
	retlw	0x08		;78 -> 	08	F11
	retlw	0x63		;79 -> 	63	NB+
	retlw	0x64		;7A -> 	64	NB3
	retlw	0x62		;7B -> 	62	NB-
	retlw	0x60		;7C -> 	60	NB*
	retlw	0x6E		;7D -> 	6E	NB9
	retlw	0x56		;7E -> 	56	SCROLL LOCK
	retlw	0x50		;7F -> 	50	Nedefinovana
;
;******************************
;
; Konverzia SCAN kodu na SCAN kod. Najprv NOVA hodnota, potom STARA
;
; I-polozka, J-offset
;
rdkon:	movf	i,w
	addwf	j,w
	addwf	PCL,f
;
	nop			;Nepouzity prvok tabulky
;
; kody s E0 editacne
;
st1:	retlw	0x5E		;NB /
	retlw	0x4A

	retlw	0x18		;END
	retlw	0x69

	retlw	0x38		;CURR LEFT
	retlw	0x6B

	retlw	0x17		;HOME
	retlw	0x6C

	retlw	0x19		;INSERT
	retlw	0x70

	retlw	0x20		;DELETE
	retlw	0x71

	retlw	0x40		;CURR DOWN
	retlw	0x72

	retlw	0x39		;CURR RIGHT
	retlw	0x74

	retlw	0x3F		;CURR UP
	retlw	0x75

	retlw	0x48		;PAGE DOWN
	retlw	0x7A

	retlw	0x28		;PRINT SCREER
	retlw	0x7C

	retlw	0x47		;PAGE UP
	retlw	0x7D
;
; konverzia SCAN na ZX pri konverzii klaves ~,_,... so SHIFT okrem 0..9
;
st4:	retlw	pEXT_SS+zx_A	;~		2
	retlw	0x0E		;`

	retlw	pSS+zx_0	;_		4
	retlw	0x4E		;-

	retlw	pSS+zx_K	;+		6
	retlw	0x55		;=

	retlw	pEXT_SS+zx_F	;{		8 
	retlw	0x54		;[
	
	retlw	pEXT_SS+zx_G	;}		10
	retlw	0x5B		;]

	retlw	pSS+zx_Z	;:		12
	retlw	0x4C		;;

	retlw	pSS+zx_P	;"		14
	retlw	0x52		;'

	retlw	pEXT_SS+zx_S	;|		16
	retlw	0x5D		;\

	retlw	pSS+zx_R	;<		18
	retlw	0x41		;,

	retlw	pSS+zx_T	;>		20
	retlw	0x49		;.

	retlw	pSS+zx_C	;?		22
	retlw	0x4A		;/
;
; 2. stupen klavesy 1..0 so SHIFT, vysledok=klavesa ZX
;
st5:	retlw	pSS+zx_1	;!		24	
	retlw	0x16		;1	
;
	retlw	pSS+zx_2	;@		26
	retlw	0x1E		;2
;
	retlw	pSS+zx_3	;#		28
	retlw	0x26		;3
;
	retlw	pSS+zx_4	;$		30
	retlw	0x25		;4
;
	retlw	pSS+zx_5	;%		32
	retlw	0x2E		;5
;
	retlw	pSS+zx_H	;^		34
	retlw	0x36		;6
;
	retlw	pSS+zx_6	;&		36
	retlw	0x3D		;7
;
	retlw	pSS+zx_B	;*		38
	retlw	0x3E		;8
;
	retlw	pSS+zx_8	;(		40
	retlw	0x46		;9
;
	retlw	pSS+zx_9	;)		42
	retlw	0x45		;0
;
st6:				;Adresa konca tabulky
;
;******************************
;
; Tabulka konverzie SCAN->ZX (kody 1..127)
;
rtab:	movf	scan,w		
	addwf	PCL,f
				;SCAN	KEY
	retlw	zx_NIC		;00
	retlw	zx_NIC		;01	F9
	retlw	pk_F7		;02	F7
	retlw	pk_F5		;03	F5
	retlw	pk_F3		;04	F3
	retlw	pk_F1		;05	F1
	retlw	pk_F2		;06	F2
	retlw	zx_NIC		;07	F12
	retlw	zx_NIC		;08	F11
	retlw	zx_NIC		;09	F10
	retlw	pk_F8		;0A	F8
	retlw	pk_F6		;0B	F6
	retlw	pk_F4		;0C	F4
	retlw	pCS+zx_1	;0D	TAB
	retlw	pSS+zx_X	;0E	`~
	retlw	zx_NIC		;0F	PAUSE
	retlw	zx_NIC		;10	CTRL+PAUSE
	retlw	zx_SS		;11	ALT
	retlw	zx_CS		;12	SHIFT L
	retlw	pCS+zx_SP	;13	ESC
	retlw	pCS+zx_SS	;14	CTRL
	retlw	zx_Q		;15	Q
	retlw	zx_1		;16	1!
	retlw	pk_HOME		;17	HOME
	retlw	pk_END		;18	END
	retlw	pk_INS		;19	INS
	retlw	zx_Z		;1A	Z
	retlw	zx_S		;1B	S
	retlw	zx_A		;1C	A
	retlw	zx_W		;1D	W
	retlw	zx_2		;1E	2@
	retlw	zx_NIC		;1F	WIN95 LW
	retlw	pk_DEL		;20	DEL
	retlw	zx_C		;21	C
	retlw	zx_X		;22	X
	retlw	zx_D		;23	D
	retlw	zx_E		;24	E
	retlw	zx_4		;25	4$
	retlw	zx_3		;26	3#
	retlw	zx_NIC		;27	WIN95 RW
	retlw	zx_NIC		;28	PRINT SCR
	retlw	zx_SP		;29	SPACE
	retlw	zx_V		;2A	V
	retlw	zx_F		;2B	F
	retlw	zx_T		;2C	T
	retlw	zx_R		;2D	R
	retlw	zx_5		;2E	5%
	retlw	zx_NIC		;2F	WIN95 menu
	retlw	zx_NIC		;30	
	retlw	zx_N		;31	N
	retlw	zx_B		;32	B
	retlw	zx_H		;33	H
	retlw	zx_G		;34	G
	retlw	zx_Y		;35	Y
	retlw	zx_6		;36	6^
	retlw	zx_NIC		;37	
	retlw	pCS+zx_5	;38	CURR LEFT
	retlw	pCS+zx_8	;39	CURR RIGHT
	retlw	zx_M		;3A	M
	retlw	zx_J		;3B	J
	retlw	zx_U		;3C	U
	retlw	zx_7		;3D	7&
	retlw	zx_8		;3E	8*
	retlw	pCS+zx_7	;3F	CURR UP
	retlw	pCS+zx_6	;40	CURR DW
	retlw	pSS+zx_N	;41	,<
	retlw	zx_K		;42	K
	retlw	zx_I		;43	I
	retlw	zx_O		;44	O
	retlw	zx_0		;45	0)
	retlw	zx_9		;46	9(
	retlw	pk_PGUP		;47	PG UP
	retlw	pk_PGDW		;48	PG DW
	retlw	pSS+zx_M	;49	.>
	retlw	pSS+zx_V	;4A	/?
	retlw	zx_L		;4B	L
	retlw	pSS+zx_O	;4C	;:
	retlw	zx_P		;4D	P
	retlw	pSS+zx_J	;4E	-_
	retlw	zx_NIC		;4F	
	retlw	zx_NIC		;50	
	retlw	zx_NIC		;51	
	retlw	pSS+zx_7	;52	' "
	retlw	zx_NIC		;53	
	retlw	pEXT_SS+zx_Y	;54	[{
	retlw	pSS+zx_L	;55	=+
	retlw	zx_NIC		;56	SCROLL LOCK
	retlw	zx_NIC		;57	NUM LOCK
	retlw	pCS+zx_2	;58	CAPS LOCK
	retlw	zx_CS		;59	SHIFT R
	retlw	zx_ENT		;5A	ENTER
	retlw	pEXT_SS+zx_U	;5B	]}
	retlw	zx_NIC		;5C	
	retlw	pEXT_SS+zx_D	;5D	\|
	retlw	pSS+zx_V	;5E	NB /
	retlw	zx_NIC		;5F	ALT+PRIT_SCREEN
	retlw	pSS+zx_B	;60	NB *
	retlw	pSS+zx_W	;61	<>
	retlw	pSS+zx_J	;62	NB -
	retlw	pSS+zx_K	;63	NB +
	retlw	zx_3		;64	NB 3
	retlw	zx_6		;65	NB 6
	retlw	pCS+zx_0	;66	BS <-
	retlw	zx_5		;67	NB 5
	retlw	zx_0		;68	NB 0
	retlw	zx_1		;69	NB 1
	retlw	zx_2		;6A	NB 2
	retlw	zx_4		;6B	NB 4
	retlw	zx_7		;6C	NB 7
	retlw	zx_8		;6D	NB 8
	retlw	zx_9		;6E	NB 9
	retlw	pSS+zx_M	;6F	NB .
;
;*****
;
; Citanie bitovej masky bitu W
;
rdmask:	andlw	7
	addwf	PCL,f
;
; Tabulka bitovej masky
;
	retlw	0x01		;Bit 0 
	retlw	0x02
	retlw	0x04
	retlw	0x08
	retlw	0x10
	retlw	0x20	
	retlw	0x40	
	retlw	0x80		;bit 7
;
;*****************************************************************************
;
; Druha polovica PAMATE - STRANKA 1
;
;*****************************************************************************
;
	;!!!!!!!!!org	0x1FF
;
;******************************
;
; Podprogramy
;
;******************************
;
;
; Nulovanie MATICE (72T)
;
cl_mat:	clrf	mc0		;Pamat matice
	clrf	mc1
	clrf	mc2
	clrf	mc3
	clrf	mc4
	movlw	mset_k
	andwf	flag2,f		;Priznaky ZX okrem set_k

	clrf	PORTB		;Stlpec 0, D0..D2=0
cl_mat0:bsf	wr1		;WR do 8804-1
	bcf	wr1
	bsf	wr2		;WR do 8804-2
	bcf	wr2		
	incf	PORTB,f		;Dalsi stlpec
	jnb	PORTB,3,cl_mat0	;Ak nie je adresa 8 nuluj dalsi 'riadok'
	retlw	0
;
;********
;
; Poslanie pamate matice do 8804 okrem MC7 (284T)
;
wr8804:	movlf	i,0x01		;Bitova MASKA = Pocitadlo 8 cyklov
	clrf	PORTB		;Pociatocny stav D0..D2=0 a ADR=0
	bcf	STATUS,C	;CY=0

wr8804l:movf	i,w		;podla bitu I z MC0 nastav D0
	andwf	mc0,w
	sz
	bsf	d0

	movf	i,w		;podla bitu I z MC1 nastav D1
	andwf	mc1,w
	sz
	bsf	d1
	
	movf	i,w		;podla bitu I z MC2 nastav D2
	andwf	mc2,w
	sz
	bsf	d2

	bsf	wr1		;Zapis do 8804-1
	bcf	wr1		;WR1=0

	movlw	amask		;Nulovanie DAT (adresa sa nezmeni) 
	andwf	PORTB,f

	movf	i,w		;podla bitu I z MC3 nastav D0
	andwf	mc3,w
	sz
	bsf	d0
	
	movf	i,w		;podla bitu I z MC4 nastav D1
	andwf	mc4,w
	sz
	bsf	d1

	bsf	wr2		;Zapis do 8804-2
	bcf	wr2		;WR2=0

	incf	PORTB,f		;Adresa stlpca+1

	movlw	amask		;Nulovanie DAT (adresa sa nezmeni) 
	andwf	PORTB,f

	rlf	i,f		;Posun MASKY na dalsi bit 
	jnc	wr8804l		;Ak CY=1 (8 cyklov) koniec, inak znova
	retlw	0
;	 
;**********************************************************
;
; PAUZY a pauzicky ....
;
wait1:	movlw	1		;Cas 1ms
;
; Pauza Wx1ms.
; Ak pF0=1       => RETLW. (Pri pustani klaves netreba cakat)
; Ak RTTC<>0     => RETLW. (Ak pride prikaz treba akceptovat)
;
wait:	movwf	j
	btfsc	pF0		;Ak pF0=0 preskok
	retlw	0
wait_0:	movlf	i,125		;Cyklus I = 1ms (1000T)
wait_1:	movf	TMR0,w		;TMR0=0?
	sz			;Ak ano preskok
	retlw	0
	djnz	i,wait_1
	djnz	j,wait_0
	retlw	0
;
;*****
;
wt164:	movlw	164
;
; Pauza Wx3us
;
wt:	movwf	i
wt0:	djnz	i,wt0
	retlw	0
;
;**********************************************************
;
; Obnova, STLACENIE a PUSTENIE klavesy CS
; Stlaci sa ak pSH=1 | Nejaka CURR key | pF0=0
;
obn_CS:	bcf	k_CS		;Pusti CS
	movlw	mCUR		;maska priznakov kurzor klaves
	andwf	flag2,w		;vymaskuj
	jnz	obn_CS0		;Ak nieco stlacene skok
	btfss	pSH		;Ak stlaceny SHIFT preskok
	btfss	pF0		;Ak pustenie preskok
obn_CS0:bsf	k_CS		;Stlac CS
	retlw	0
;
;******************************
;
; Konverzia SCAN kodu podla tabulky
;
; J=offset tabulky
; W=posledna polozka 2n+2 (n=0,1,2..)
; Ak bit0(I)=1 tak sa kod konvertoval!
;
konv:	movwf	i
konv0:	call	rdkon		;Citaj z tabulky SCAN KOD
	decf	i,f		;Ukazovatel na data
	subwf	scan,w		;Porovnaj
	jz	rdkon_s		;Ak NAJDENY ...
	djnz	i,konv0		;Dalsi prvok. Ak NIE SU preskok a koniec
	goto	ret_pg0
;
; Nacitanie z tabulky a zapis do SCAN
;
rdkon_s:call	rdkon		;Citaj novy SCAN
	movwf	scan		;Kod do SCAN
;
; Navrat a nastavenie stranky 0
; 
ret_pg0:retlw	0
;
;*************************************************************************
;
; Komunikacia z klavesnicou
;
;******************************
;
; Cakanie na scan - ak pride povel pre klavesnicu skace na INPUT
;
rdk:	clrwdt			;Nuluj PSA!
	
	mov	j,TMR0		;Vzorkuj TMR0 - sledovanie prichodu povelu
;
; Cakam na CLK cca 200us
;
	movlf	i,40

	bsf	clko		;Povol prenos kodu z klavsnice

rdk1:	jnb	clki,rdkl	;Ak prisiel CLK pre klavesnicu - citaj scan	
	
	djnz	i,rdk1
;
; Test ci neprisiel povel
;
	movf	TMR0,w		;Ak nie je povel skok
	jz	rdk	
	
	xorwf	j,w		;Ak nie je povel ustaleny skok
	jnz	rdk

	bcf	clko		;Blokuj prijem scan
	goto	input		;Vyhodnot prijem povelu
;
;**********************************************************
;
; Nacitanie znaku z klavesnice - nevyhodnocuje PARITU !
; Kod musi prist - t.j. 11x CLK H->L->H, inak bude WDT !
;
; DATAO musi byt =1
;
; Ak Z=1 je SCAN=0xFA (ACK)
;
rdkl:	bsf	clko
	call	wclk
	jb	datai,key_er	;Ak neplatny START

	movlf	i,9		;8data+1Parita

rdkl_0:	call	wclk

	rrf	scan,f

	bcf	STATUS,C
	btfsc	datai
	bsf	STATUS,C
	
	djnz	i,rdkl_0

	call	wclk
	jnb	datai,key_er

	bcf	clko		;Blokuj dalsi prenos

	cpi	scan,0xFA
	retlw	0
;
; Chyba klavesnice
;	
key_er:	goto	resetk		;Resetuj KEY
;
;****
;
; Cakaj na CLK H->L->H
;
wclk:	jb	clki,wclk
wclk1:	jnb	clki,wclk1
	retlw	0
;
;**************
;
; Zapis znaku vo W do klavesnice 
;
wrkl:	movwf	scan

	bcf	clko
	call	wt164		;Pauza 492us

	bcf	datao		;Priznak zapis / Start bit
	call	wt164		;Pauza 492us
		
	bsf	clko		;Uvolni CLK - Strobe START

	call	parit		;Priprav paritu do CY

	movlf	i,10		;Odosle sa 8 bitov + PARITA+ STOP

wrkl0:	jb	clki,wrkl0	;Cakaj na CLK=0
	btfss	scan,0		;Data bit na DATAO
	bcf	datao
	btfsc	scan,0			
	bsf	datao

	call	wclk1		;Cakaj na CLK=1

	rrf	scan,f
	bsf	STATUS,C	;STOP je =1

	djnz	i,wrkl0

	call	wclk		;Cakaj na dalsi CLK a potom testuj ACK

	jb	datai,key_er	;Ak neprisiel chyba klavesnice !

	goto	rdkl		;Dalej prijmi ACK !	
;
;**********************************************************
;
; Urcenie neparnej parity SCAN do CY
; Nici: I
;
parit:	swapf	scan,w		;7654 XOR 3210 = ABCD
	xorwf	scan,w
	movwf	i
	rrf	i,f
	rrf	i,f
	xorwf	i,w		;AB XOR CD = EF
	movwf	i
	rrf	i,f
	xorwf	i,f		;E XOR F=G
	movlw	0x01
	xorwf	i,f
	rrf	i,f		;Vysun do CY
	retlw	0
;
;**************************************
;
; Inicializacia programovatelnych klaves
;
ini_fk:	movlf	k_F1,pCS+zx_1		;EDIT
	movlf	k_F2,pCS+zx_2		;CAPS
	movlf	k_F3,pCS+zx_3		;T.VIDEO
	movlf	k_F4,pCS+zx_4		;I.VIDEO
	movlf	k_F5,pEXT_SS+zx_9	;CAT	
	movlf	k_F6,pEXT_SS+zx_6	;MOVE
	movlf	k_F7,pEXT_SS+zx_7	;ERASE
	movlf	k_F8,pEXT_SS+zx_0	;FORMAT
	movlf	k_INS,pCS+zx_9		;GRAPH
	movlf	k_DEL,pCS+zx_0		;DEL
	movlf	k_HOME,pSS+zx_Q		;<=
	movlf	k_END,pSS+zx_E		;=>
	movlf	k_PGUP,pCS+zx_4		;I.VIDEO
	movlf	k_PGDW,pCS+zx_3		;T.VIDEO
	retlw	0
;
;*************************************************************************
;*************************************************************************
;*************************************************************************
;
; Start systemu
;
;
main:	movlf	PORTA,ini_A
	movlw	mode_A
	tris	PORTA

	movlf	PORTB,ini_B
	movlw	mode_B
	tris	PORTB

	movlw	b'00101111'	;TMR0 z pinu, WDT max. TIME
	option			
;
;**************************************
;
; Inicializacna pauza
;
main_w:	movlf	scan,5		;Pauza na POWER-on klavesnice ... 2s

main_w0:clrf	j
main_w1:call	wt0
	clrwdt
	djnz	j,main_w1
	djnz	scan,main_w0
;
;**************************************
;
; Inicializacia programovatelnych klaves
;
main_p:	call	ini_fk
;
;**************************************
;
; Reset klavesnice
;
resetk:	movlw	0xFF
	call	wrkl
;
;**************************************
;
; Inicializacia premennych
;
main_c:	clrf	flag
	bsf	kone		;Blokuj konverziu 0-9 (Default ZX)

main_cr:clrf	flag2
	clrf	TMR0		;Povel nie je
	call	cl_mat
;
;*************************************************************************
;
; Hlavna slucka
;
main_h:
;
;**********************************************************
;**********************************************************
;
; Vyhodnotenie SCAN kodu
;
; -> upravuje kody do rozsahu 00..6F
; -> caka na klavesy, alebo povel
; -> sleduje NUM lock, meni bit PNUM a pri mode ZX aj meni LED
;
csc:	bcf	pE0		;Nuluj priznaky
	bcf	pF0

csc0:	call	rdk		;Citaj kod
;
	cpi	scan,0xE0	;Prefix E0 ?
	jnz	csc1
	bsf	pE0
	goto	csc0
	
csc1:	cpi	scan,0xF0	;Prefix F0 ?
	jnz	csc2
	bsf	pF0
	goto	csc0
;
csc2:	cpi	scan,0xE1	;Sekvencia PAUSE?
	jnz	csc3
;
;***
;
; Osetrenie sekvenice PAUSE
;
csop:	call	rdkl		;Pustenie / stlacenie
	cpi	scan,0xF0
	jnz	csop1

	bsf	pF0
	call	rdkl		;Nacitaj dalsie kody - ignoruj
	call	rdkl
	
csop1:	call	rdkl
	movlw	0x0F		;Kod klavesy pause
	goto	csc5		;Zapis do SCAN a konci
;
;***
;
csc3:	cpi	scan,0xAA	;Kod AA - koniec testu 
	jz	csc

	jnb	pE0,csc4	;Ak nie je kod z prefixom E0 skok
;
;***
;
; Spracovanie - konverzia kodov s prefixom E0
;
o_pE0:	cpi	scan,0x12	;E0 12?
	jz	csc		;Ak ano ignoruj

	clrf	j		;Offset =0	
	movlw	st4-st1		;Konverzia s E0
	call	konv		;Konvertuj 
;
;***
;
; Nasleduje konverzia kodov s hodnotou >6F
;
csc4:	cpi	scan,0x83	;Je to F7
	movlw	0x02
	jz	csc5		;Ak ano pouzi kod vo W

	cpi	scan,0x84	;Je to ALT+PRINT_SCREEN
	movlw	0x5F
	jz	csc5		;Ak ano pouzi kod vo W
	
	cpi	scan,0x70	;Kody 00..6F bez konverzie
	jnc	csc6

	andlw	0x1F		;Max. rozsah konverzie
	call	rdkon1		;Nacitaj novy kod z tabulky

csc5:	movwf	scan	
csc6:
;
;***
;
; Nastavenie priznakov pALT, pCTRL, pSH
;
n_pri:	cpi	scan,sc_ALT
	movlw	mALT
	jz	sb_flag

	cpi	scan,sc_CTRL
	movlw	mCTRL
	jz	sb_flag

	cpi	scan,sc_SHL
n_pri1:	movlw	mSH
	jz	sb_flag

	cpi	scan,sc_SHR
	jz	n_pri1


	goto	csc_e		
;
; Nastav bity vo FLAG podla masky W na hodnotu pF0
;
sb_flag:iorwf	flag,f
	btfsc	pF0
	xorwf	flag,f
;
;**************
;	
csc_e:
;
;**********************************************************
;**********************************************************
;
; Vyhodnotenie kombinacie ALT+...
;
o_alt:	jb	pF0,o_alte	;Ak je pustena klavesa nezaujem
	jnb	pALT,o_alte	;Ak nie je stlaceny ALT nic

	cpi	scan,sc_APS	;Je ALT PRINT SCREEN?
	jnz	o_alt1		;Ak nie 
;
; Aktivacia NMI
;
	movlf	PORTB,b'11000010' ;Aktivuj MNI=0
	bcf	pALT		  ;Nuluj priznak ALT aby sa neopakovalo
	clrf	PORTB		  ;MNI=1
	goto	csc
;
;**
;
; CTRL+ALT+DEL
;
o_alt1:	jnb	pCTRL,o_alte	;Ak nie je CTRL nic

	cpi	scan,sc_ESC	;Je to ESC
	jz	main_p		;Ak ano RESET klavesnice

	cpi	scan,sc_DEL	;Je to DEL
	jz	o_alt2

	cpi	scan,sc_NBB	;Je DEL na num. bloku

	jnz	o_alte		;Ak nie nic
;
; RESET pocitaca a klavesnice - PK sa nemenia
;
o_alt2:	movlf	PORTB,b'11000001' ;RESET

	movlw	0xFF		  ;Resetuj klavesnicu
	call	wrkl

	movlw	mcFLAG		  ;Inicializuj FLAG 		 
	andwf	flag,f
	goto	main_cr
;
;**
;
o_alte:
;
;*************************************************************************
;
; Vetvenie podla modu 
;
	jb	scane,wbuff
;
;*************************************************************************
;*************************************************************************
;
; ZX-mod
;
;******************************
;
; Nastavenie modu z klavesnice
;
vzx:	movf	scan,f		;Ak pretiekol BUFFER klavesnice - inicializuj
	jz	main_c	
;
	jb	pSH,vzx0	;Ak je SHIFT testuj F10-F12
	jnb	pALT,vzx1	;Ak nie je ALT netestuj F10-F12

vzx0:	cpi	scan,sc_F10	;Je to klavesa F9
	movlw	mKONE		;Maska KONE
	jz	sb_mod		;Ak ano skok
	cpi	scan,sc_F11	;Je to klavesa F10
	movlw	mEXTE		;Maska EXTE
	jz	sb_mod		;Ak ano skok
	cpi	scan,sc_F12	;Je to klavesa F12
	jnz	vzx1		;Ak nie preskok
	movlw	mSINE		;Maska SINE
;
; Nastavenie modu z klavesnice
;
sb_mod:	iorwf	flag,f		;Nastav zvoleny bit
	btfss	pALT		;Ak pALT=1 preskok
	xorwf	flag,f		;Inak ho invertuj (NULUJ)
	call	cl_mat		;Nuluj maticu
	goto	main_h		;Hlavny cyklus
;
;***
;
vzx1:	cpi	scan,sc_ESC	;Je to klavesa ESC
	jnz	vzx_2		;Ak nie skok
;
; Stlacena klavesa ESC. 
; Nuluje sa matica a priznaky FLAG2
; 
	call	cl_mat
	movlw	pCS+zx_SP	;kod stlacenia CS+SPC

vzx_w:	movwf	zx_key
	goto	vzx_n		;Vyhodnot ako normalny kod
;
;***
;
vzx_2:	jnb	sine,vzx_ne	;Ak nie je JOYSTICK povoleny preskok
;
; Konverzia klaves CTRL,UP,DW,LF,RG na sinclair JOYSTICK
;
	cpi	scan,sc_CTRL	;Je CTRL
	movlw	zx_0		;Klavesa FIRE
	jz	vzx_w		;Ak ano skok 
	cpi	scan,sc_UP	;....
	movlw	zx_9
	jz	vzx_w
	cpi	scan,sc_DW	
	movlw	zx_8
	jz	vzx_w
	cpi	scan,sc_LF
	movlw	zx_6
	jz	vzx_w
	cpi	scan,sc_RG
	movlw	zx_7
	jz	vzx_w
;
;***
;
vzx_ne:	btfss	pKK		;Ak je  stlacena nejaka KONV. klavesa preskok
	btfsc	pSH		;Ak nie je stlaceny SHIFT preskok
	goto	vzx_kk		;Inak blok pre konverziu klaves
;
;***
;
; Vyhodnotenie klavesy bez konverzie
;
vzx_nk:	call	rtab		;W=kombinacia key

	movwf	zx_key		;Kod do ZX_KEY
	incf	zx_key,w	;Je 255 (NIC)?
	jz	vzx_wr		;Ak ano len zapis matice
	cpi	zx_key,pk_F1	;Je to programovatelna klavesa?
	jnc	vzx_nk0		;Ak nie preskok

	movwf	FSR		;Ukazovatel - cislo prog. key
	movlw	k_F1		;Adresa 1. programovatelnej klavesy.
	addwf	FSR,f		;FSR ukazuje na register progr. klavesy
	movf	INDF,w		;jeho odsah do ZX_KEY
	movwf	zx_key

	cpi	zx_key,pk_F1	;Je to pouzitelny kod (<240)
	jc	vzx_wr		;Ak nie len zapis 

vzx_nk0	cpi	zx_key,pEXT	;Je to klavesa s EXT
	jc	vzx_ext		;Ak ano (>=) vyhodnotenie s EXT
;
; Stlacenie kombinacie KEY, CS+KEY, SS+KEY
;
vzx_n	cpi	zx_key,pSS	;>=pSS? (klavesa so SS?)
	jnc	vzx_n0		;Ak nie skok
;
; Klavesa so SS
;
	movwf	zx_key		;Kod klavesy do SCAN
	bcf	k_SS		;pusti SS
	btfss	pF0		;Ak pustenie klavesy preskok
	bsf	k_SS
	goto	vzx_n3
;
vzx_n0	cpi	zx_key,pCS	;>=pCS? (klavesa s CS?)
	jnc	vzx_n4
;
; Klavesa s CS
;
	movwf	zx_key		;Kod klavesy do ZX_KEY
;
	bcf	k_CS		;pusti CS
	cpi	zx_key,zx_5	;CS+5? =CURR LEFT
	movlw	mLF		;Maska
	jz	vzx_n1		;Ak ano skok
	cpi	zx_key,zx_6	;CS+6? =CURR DOWN
	movlw	mDW	
	jz	vzx_n1
	cpi	zx_key,zx_7	;CS+7? =CURR UP
	movlw	mUP
	jz	vzx_n1
	cpi	zx_key,zx_8	;CS+8? =CURR RIGHT
	movlw	mRG
	jnz	vzx_n2		;Ak nie NIC nenastavuj
vzx_n1:	iorwf	flag2,f		;nastav dany bit
	btfsc	pF0		;Ak stlacenie preskok
	xorwf	flag2,f		;Inak nuluj dany bit
vzx_n2:	call	obn_CS		;Obnov CS
;
; Stlacenie SHIFT-u a PAUZA na akceptovanie SHIFT-u
;
vzx_n3:	call	wr8804		;zapis maticu
	call	wait1		;Pauza 1.2ms na akceptovanie SHIFTU
;
;**************
;
; Stlacenie/Pustenie klavesy ZX_KEY v matici podla pF0 (ak pF0=0 Stlacenie)
; 0=bit0 mc0,39=bit7 mc4
;
vzx_n4:	movf	zx_key,w
	call	rdmask		;citanie bitovej masky (CY=0)
	movwf	j		;bitova maska do J
	rlf	zx_key,f	;Na pozicii 6-4 cislo riadku(bit0=0 CY bolo 0)
	swapf	zx_key,w	;Na poziciu 2-0
	andlw	0x7
	movwf	FSR		;Do ukazovatela 
	movlw	mc0		;Prvy riadok matice
	addwf	FSR,f		;FSR ukazuje na zvoleny riadok
	movf	j,w		;Maska do W
	iorwf	INDF,f		;Nastav pozadovany bit
	btfsc	pF0		;Ak pF0=0 (stlacenie) preskok
	xorwf	INDF,f		;Inak ho invertuj=VYNULUJ
;
; Zapis matice
;
vzx_wr:	call	wr8804
	goto	main_h		;Hlavny cyklus	
;
;******************************
;
; Osetrenie konverzie klavesy
;
vzx_kk:	movlw	st4-st1		
	movwf	j		;Offset tabulky do J
	movlw	st5-st4		;Konverzia okrem 0..9
	btfss	kone		;Ak blokovana konverzia 0..9 preskok
	movlw	st6-st4		;Konverzia aj s 0..9

	call	konv		;Konvertuj

	btfss	i,0		;Ak bola konverzia preskok
	goto	vzx_nk		;Inak vyhodnot klavesu bez konverzie
	btfss	pF0		;Ak pustenie preskok
	goto	vzx_kk1		;Inak stlacenie 
;
; Pustenie klavesy (asi konvertovanej)
;
	movf	last,w		
	subwf	zx_key,w	;Bola to klavesa ktora je zapamatana?
	jz	vzx_kk0		;Ak ano skok
;
; Inak Obnov SCAN kod (podla tabulky konverzie) a vyhodnot bez konverzie
;
	incf	i,f		;Krok dalej v tabulke (povodny znak)

	call	rdkon_s		;Nacitaj z tabulky do SCAN
	goto	vzx_nk		;A vyhodnot bez konverzie
;
; Pustenie klavesy z konverziou
;
vzx_kk0:bcf	pKK		;Nuluj	priznak KONVERZIE
	call	obn_CS		;Obnov CAPS SHIFT
	goto	vzx_kk2		;Vyhodnot
;
; Stlacenie klavesy po konverzii
;
vzx_kk1:btfss	pKK		;Ak uz je nejaka stlacena preskok
	btfsc	pEK		;Ak nie je nejaka EXTEND stlacena preskok
	goto	vzx_wr		;Inak SA NIC NESTLACI

	bcf	k_CS		;Pusti CS
	bsf	pKK		;Nastav priznak KONVERTOVANEJ klavesy
	movf	zx_key,w	;LAST=ZX_KEY
	movwf	last
;
; Vyhodnotenie klavesy po konverzii (jej ZX_KEY kod)
;
vzx_kk2:cpi	zx_key,pEXT	;Klavesa s EXTEND
	jnc	vzx_n		;Ak nie skok
	goto	vzx_ex0		;Vyhodnot EXT bez testu pKK
;
;*****
;
; Vyhodnotenie klavesy s EXTEND (W sa musi rovnat ZX_KEY-pEXT)
;
vzx_ext:jb	pKK,vzx_wr	;Ak pKK=1 ignoruj - uz je stlacena KONV. key
vzx_ex0:movwf	i		;Do I kod ZX_KEY bez EXTEND
	movf	zx_key,w	;Do W kod ZX_KEY
	btfss	pF0		;Ak pustenie preskok
	goto	vzx_ex1		;Inak STLAC EXTEND
;
; Pustenie klavesy s EXTEND
;
	subwf	last,w		;ZX_KEY=LAST?
	jnz	vzx_wr		;Ak nie ignoracia (taka nie je stlacena)
	bcf	pEK		;Nuluj priznak EXTEND
	movf	i,w
	movwf	zx_key		;Kod bez EXT do ZX_KEY
	goto	vzx_n		;A vyhodnot zvysok (pusti prislusne klavesy)
;
; Stlacenie EXTEND
;
vzx_ex1	jb	pEK,vzx_wr	;Ak nemozno akceptovat IGNORACIA
	movwf	last		;Uschovaj kod klavesy
	bsf	pEK		;Nastav priznak klavesy s EXTEND
	mov	zx_key,i	;Kod bez EXT do ZX_KEY
;
	jb	exte,vzx_n	;Ak nie je povoleny EXTEND, bez EXTEND
	bsf	k_SS		;Stlac SS
	bsf	k_CS		;Stlac CS
	call	wr8804		;Zapis
	movlw	.35		;Cas stlacenia EXTEND ÷35ms
	call	wait		
	bcf	k_SS		;Pusti SS
	bcf	k_CS		;Pusti CS
	call	wr8804		;Zapis
	call	wait1		;Pauza medzi stlacenim 1.2ms
	goto	vzx_n		;A vyhodnot zvysok (stlac klavesu)
;
;*****************************************************************************
;*****************************************************************************
;
; Obsluha vstupu prikazu
; Pozor MANIPULUJE SO ZASOBNIKOM !!!
;
;******************************
;
input:	clrf	scan		;SCAN=0 Priznak, ze sa neprime SCAN kod
	jb	set_k,set_pk	;Ak sa ocakava kod programovatelnej klavesy
			
	cpi	TMR0,0x3f	;Prikaz RESET KEYBOARD?
	jz	main		;Ak ano RESET
;
inp_0:	jb	TMR0,7,inp_e	;Ak bit7=1 koniec	[1xxx xxxx]
	jb	TMR0,6,inp_e	;Ak bit6=1 koniec	[01xx xxxx]
	jb	TMR0,5,inp_pk	;Ak bit5=1 preskok	[0010 xxxx]
	jb	TMR0,4,inp_sm	;Ak bit4=1 set mode	[0001 xxxx]
	jb	TMR0,3,inp_led	;Ak bit3=1 set LED	[0000 1xxx]

	btfsc	scane		;Ak nie je SCAN rezim preskok
inp_1:	call	rbuf		;Inak akceptovanie ACK
;
; Ukoncenie input navratom do RDK
;
inp_e:	clrf	TMR0		;Nuluj TMR0 pre dalsi prikaz
	goto	rdk
;
;******
;
; Nastavenie LED na klavesnici
;
inp_led:movlw	0xED		;Zapis do klavesnice - bez testu uspesnosti
	call	wrkl
	movf	TMR0,w
	andlw	0x7		;Maska LED
	call	wrkl
	goto	inp_e
;
;******
;
; Priprava na programovanie klavesy
;
inp_pk:	movf	TMR0,w
	andlw	0x0f		;Maska cisla klavesy
	movwf	i		;Cislo klavesy do I
	cpi	i,14		;Je cislo platne (<14) ?
	jc	inp_e		;Ak nie koniec
	movlw	k_F1		;Adresa 1. prog. klavesy
	addwf	i,w		;W adresa reg. prog. klavesy
	movwf	FSR		;Do ukazovatela
	movlw	0xFF		;Hodnota oznacujuca programovanu klavesu
	movwf	INDF		;Oznac
	bsf	set_k		;Priznak programovania klavesy
	goto	inp_e		;Koniec
;
; Naprogramovanie programovatelnej klavesy
;
set_pk:				;Hladanie oznacenej klavesy (255)
	movlw	k_F1		;Prva prog. klavesa
	movwf	FSR		
	movlw	14		;14 prog. klaves
	movwf	i
set_p0:	cpi	INDF,0xFF	;Oznacena
	jz	set_p1		;Ak ano skok
	incf	FSR,f		;Dalsia klavesa
	djnz	i,set_p0
	goto	set_p2		;Ak nic koniec
;
set_p1:	decf	TMR0,w		;Presun kodu do registra klavesy
	movwf	INDF		;Kod -1 (Aby bol kod od 0!)

set_p2	bcf	set_k		;Zrus priznak
	goto	inp_e		;Koniec
;
;*****
;
; Nastavenie MODU 
; (Pri prechode SCAN=1 na SCAN=0 inicializuje PROG. KLAVESY
;
inp_sm:	jnb	scane,inp_s0	   ;Ak nie je SCAN pokracuj
	jb	TMR0,bscane,inp_s0 ; Ak sa ma SCAN vypnut skok
;
	call	ini_fk		;Inicializacia prog. klaves
;
inp_s0:	movf	TMR0,w
	andlw	0x0f
	movwf	i		;I = mod
	movf	flag,w		
	andlw	0xf0		;Maska ostatnych bitov
	iorwf	i,w		;Doplnenie bitov modu
	movwf	flag		;Zapis do FLAG
;
	call	cl_mat		;Nulovanie matice
;
; Test na SCAN rezim. Ak je jeho INICIALIZACIA
;
	jnb	scane,inp_e	;Ak sa nestartuje SCAN koniec
	goto	inis		;Inak inicializacia SCAN
;
;*************************************************************************
;
; Citanie z buffra pri SCAN mode
;
;******************************
;
rbuf:	movf	ukr,w
	andlw	muk
	movwf	i		;Vymaskovanu UKR do I
	movf	ukw,w
	andlw	muk		;Platne bity
	subwf	i,w		;Je UKR<UKW
	jnc	wscan		;Ak ano skok
;
; Zrusenie priznakov SCAN kodu		
;
	clrf	PORTB		;Z,X="PUSTI"
	bsf	wr1		;Strobe DATA
	bcf	wr1	
	bcf	sOUT		;Priznak SCAN kod nieje vyslany
	retlw	0
;
; Poslanie SCAN z BUFF(UKR) do 8804 na MC7 (110T)
;
wscan:	movlw	buff		
	addwf	ukr,w		;W=adresa bunky so SCAN kodom
	andlw	0x3F		;Maskuj rozsah adries - bity 6,7 UKR maju ine
				;pouzitie
	movwf	FSR		;Do ukazovatela

	movlw	0x01		;Bitova MASKA = Pocitadlo 8 cyklov
	movwf	i
	clrf	PORTB		;Pociatocny stav dat 0
	bcf	STATUS,C	;CY=0
	bsf	sOUT		;Priznak - je poslany SCAN kod

wscan1:	movf	i,w		;podla bitu I z MC2 nastav D2
	andwf	INDF,w
	sz
	bsf	d2

	bsf	wr2		;Zapis do 8804-2
	bcf	wr2		;WR2=0
	movlw	amask		;Nulovanie DAT (adresa sa nezmeni) 
	andwf	PORTB,f
	incf	PORTB,f		;Adresa stlpca+1
	rlf	i,f		;Posun MASKY na dalsi bit 
	jnc	wscan1		;Ak CY=1 (8 cyklov) koniec, inak dalsi riadok
;
; Nastavenie priznaku platneho SCAN kodu Z, alebo X sa "STLACI" (podla kZ)
; Ak je stlacene Z, X na MC7 je SCAN kod pripraveny na prevzatie.
;
	movlw	B'00010000'	;Z="STLAC",X="PUSTI"
	btfsc	kZ		;Ak kZ=0 preskok (Z sa STLACI)
	movlw	B'00100000'	;Z="PUSTI",X="STLAC"
	movwf	PORTB		;Data do 8804
	bsf	wr1		;Strobe DATA
	bcf	wr1	

	incf	ukr,f		;Ukazovatel ++;
	movlw	mkZ		;maska
	xorwf	flag3,f		;Inverzia kZ - Pri dalsom SCAN to bude naopak
	retlw	0
;	 
;*****************************************************************************
;*****************************************************************************
;
; Vyhodnotenie klavesy SCAN mod
;
; Uvolnenie precitanych znakov 
;
wbuff:	mov	i,buff		;I=adresa 1. znaku BUFF
;
wbuf_0:	movf	i,w
	addwf	ukr,w		;W=adresa kde ukazuje UKR
	andlw	0x1f		;Je > 0x1f (koniec pamate)
	jz	wbuf_1		;Ak ANO koniec posuvu
	movwf	FSR		
	movf	INDF,w
	movwf	j		;J=(UKR)

	movf	i,w
	movwf	FSR		
	movf	j,w		
	movwf	INDF		;(I)=J

	incf	i,f		;Dalsi znak
	goto	wbuf_0	
;
wbuf_1:	movf	ukr,w		;UKW=UKW-UKR Posun UKW pri uvolneni BUFF
	andlw	muk		;Maska
	subwf	ukw,f		
	clrf	ukr		;UKR=0
	movf	ukw,w
	andlw	muk		;Maska platnych bitov
	movwf	i
	cpi	i,b_siz		;Je UKW na konci BUFF (BUFF FULL)?
	jz	wbuf_3		;Ak ano osetrenie BUFF FULL
	movlw	buff
	addwf	ukw,w		
	movwf	FSR		;FSR=Adresa kde sa zapise do BUFF

	movf	scan,w
	movwf	INDF		;Zapis scan kod
	btfsc	pF0		;Ak stlacenie preskok
	bsf	INDF,7		;Kod pustenie (+0x80)
	incf	ukw,f		;UKW++
;
; Odoslanie znaku ak nie je ziadny odoslany
;
wbuf_2:	jb	sOUT,main_h	;Ak  je odoslany SCAN kod - do hlavnej slucky
;
	call	rbuf		;Citanie z buff do MC7
	goto	main_h
;
; Osetrenie BUFF full - Miesto posledneho znaku sa ulozi 00
;
wbuf_3:	clrf	buff+b_siz-1
	goto	wbuf_2
;
;*****
;
; Inicializacia ukazovatel pre SCAN rezim
;
inis	movlf	buff,k_typ	;Pociatocna sekvencia TYP+VERZIA
	movlf	buff+1,k_ver
	movlf	buff+2,k_ver1
	clrf	buff+3		;Znak BUFF FULL
	clrf	ukr		;Ukazovatel citania na zaciatok
	movlw	4
	movwf	ukw		;Ukazovatel zapisu od 3. prvku
	goto	inp_1		;Vysli prvy znak na MC7
;
;*****************************************************************************
;
	org	0x3FF
	goto	main		;Skok do PAGE0 (po RESET PA0=0!)
;
;*****
;
	end