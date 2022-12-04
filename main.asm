; =========================================================================================================
; UNIVERSIDADE FEDERAL DO RIO GRANDE DO SUL (UFRGS)
; INSTITUTO DE INFORMÁTICA
; ARQUITETURA E ORGANIZAÇÃO DE COMPUTADORES I, 2022/1
;
; MASM 6.11 para Intel x86: Criptografia
; Leonardo Azzi Martins
; =========================================================================================================
	.model		small 
	.stack 
	
CR		equ		0DH
LF		equ		0AH

; DATA ----------------------------------------------------------------------------------------------------
	.data	

MsgCRLF				db	    CR, LF, 0
	
MAXSTRING	        equ		200
String		        db		MAXSTRING dup (?)	

extTXT		        db		".txt", 0
extKRP 		        db 		".krp", 0

FileNameSrc		    db		256 dup (?) 		; Nome do arquivo a ser lido
FileNameDst		    db		256 dup (?)			; Nome do arquivo a ser escrito
FileHandleSrc	    dw		0					; Handler do arquivo de origem
FileHandleDst	    dw		0					; Handler do arquivo de destino
FileBuffer		    db		10 dup 	(?)			; Buffer do arquivo
ByteBuffer          db      10 dup  (?)         ; Buffer para criptografia
RegularMsg 	        db 		256 dup (?)			; Salva a mensagem digitada pelo usuário
SaveText 	        db 		256 dup (?)			; Salva texto do arquivo de entrada
charBuffer 			db 		256 dup (?) 		; Guarda o caracter obtido na GetChar
MaxFileSize 	    equ 	65535
FileSize		    dw 		0
PhraseSize			dw		0
Counter			    dw		26 dup (?)	; A=0, B=1, ..., Z=25
BufferWRWORD		db		10 dup (?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0

Intro				db		"Criptografia em MASM 6.11 para Intel x86, Leonardo Azzi Martins"
IntroSep			db		"---------------------------------------------------------------"
PrintFilename		db		"Nome do arquivo para leitura: ", 0
PrintMsg 			db 		"Mensagem a ser criptografada: ", 0
OpenFile			db 		"> Arquivo aberto para leitura.", 0
CreateFile 			db 		"> Arquivo criado.", 0
WriteFile			db 		"> Arquivo aberto para escrita.", 0
InputFileSize 		db 		"Tamanho do arquivo de entrada [bytes]: ", 0
WordSize 			db 		"Tamanho da frase [bytes]: ", 0
OutFilename 		db 		"Arquivo de saida: ", 0
NoError 			db 		"> Processamento finalizado com sucesso.", 0
ReadingFile			db		"Lendo arquivo", 0
ErrorOpenFile		db		"Erro - abertura do arquivo.", CR, LF, 0
ErrorCreateFile		db		"Erro - criacao do arquivo.", CR, LF, 0
ErrorReadFile		db		"Erro - leitura do arquivo.", CR, LF, 0
ErrorPhraseSize     db  	"Erro - frase e grande para ser criptografada.", CR, LF, 0
ErrorRange			db  	"Erro - caracteres fora da faixa de representacao.", CR, LF, 0
ErrorOpenFWrite 	db 		"Erro - nao foi possivel abrir o arquivo para escrita.", CR, LF, 0
ErrorEmptyFile      db 		"Erro - frase nao contem informacoes."
ErrorFileSize 		db 		"Erro - arquivo de tamanho incompativel.", CR, LF, 0

; CODE ----------------------------------------------------------------------------------------------------
	.code		
	.startup

CALL	GetFileName

; Nome do arquivo de saída
LEA 	BX, FileNameSrc 		
LEA 	DI, FileNameDst
CALL 	OutFile

; Adiciona a extensão .txt ao arquivo de entrada
LEA 	BX, FileNameSrc
LEA		DI, extTXT
CALL 	Ext

LEA 	BX, FileNameSrc
CALL	printf_s
LEA 	BX, MsgCRLF
CALL 	printf_s

; Adiciona a extensão .krp ao arquivo de saída
LEA 	BX, FileNameDst
LEA 	DI, extKRP
CALL 	Ext

; Recebe a mensagem a ser criptografada	
LEA 	BX, PrintMsg
CALL 	printf_s
LEA		BX, RegularMsg
CALL	gets
LEA 	BX, MsgCRLF
CALL 	printf_s

; Teste para criptografia
LEA 	BX, RegularMsg
CALL 	TestString
LEA 	BX, RegularMsg
CALL	LoopPhraseSize


openInputFile: 
; Abre arquivo .txt de entrada

	LEA 	BX, OpenFile
	CALL 	printf_s

	lea		dx,FileNameSrc
	CALL	fopen
	mov		FileHandleSrc,bx
	JNC		readFile

	; Caso de erro
	lea		bx,ErrorOpenFile
	call	printf_s
	.exit	1

readFile:
; Lê os caracteres do arquivo .txt

	MOV		BX, FileHandleSrc
	CALL	GetChar
    JC     	errorRead
	CMP		AX, 0
	JE		createOutputFile

	INC		FileSize
	MOV		CX, FileSize
	CMP		CX, MaxFileSize

	JA		errorPhrase
	JMP     readFile

errorRead:
; Mensagem de erro na leitura do arquivo

	LEA 	BX, ErrorReadFile
	CALL 	printf_s
	LEA 	BX, FileHandleSrc
	CALL 	printf_s
	.exit 	1

errorPhrase:
; Mensagem de erro para frases muito grandes

	LEA 	BX, ErrorPhraseSize
	CALL 	printf_s
	LEA 	BX, FileHandleSrc
	CALL 	printf_s
	.exit 	1


createOutputFile:
; Cria arquivo de saída

	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA 	BX, CreateFile
	CALL 	printf_s

	LEA 	DX, FileNameDst
	CALL 	fcreate

	MOV		FileHandleDst, BX
	JNC		openFWrite
	
	MOV		BX, FileHandleDst
	CALL	fclose
	LEA		BX, ErrorCreateFile
	CALL	printf_s
	.exit	1

openFWrite:
; Abre arquivo de saída para escrita
	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA 	BX, CreateFile
	CALL 	printf_s

	LEA 	DX, FileNameDst
	CALL 	fwrite
	MOV		FileHandleDst, BX

setFileName:
; Seta nome do arquivo de saída
	JNC		upper
	MOV		BX, FileHandleDst
	CALL	fclose
	LEA		BX, ErrorOpenFWrite
	CALL	printf_s

	.exit	1

upper:
; Transforma caracteres em maíusculo
	LEA 	BX, MsgCRLF
	CALL	printf_s
	LEA		BX, WriteFile
	CALL 	printf_s

	LEA 	BX, RegularMsg
	CALL 	ToUpper

LEA 	SI, RegularMsg	

iterateFile:	
; Leitura e escrita no arquivo

	; Se arquivo estiver vazio
	CMP 	byte ptr [SI], 0					
	JE 		EndProgram

	; Se arquivo conter espaço
	CMP 	byte ptr [SI], 32
	JE 		returnLoop						

	openTxt:	
		LEA		DX, FileNameSrc			
		CALL	fopen						
		MOV		FileHandleSrc, BX	
		JNC		charScan	
		LEA		BX, ErrorOpenFile
		CALL	printf_s
		.exit	1

	charScan:	
 		MOV 	BX, FileHandleSrc
		CALL 	GetChar		
		JC 		errorCarry	
		CMP 	AX, 0	
		JE 		endFile

		MOV		charBuffer, DL 					
		LEA 	BX, charBuffer
		CALL  	toupper
		MOV  	DL, charBuffer

		; Verifica o match
		CMP 	[SI], DL				
		JE 		writeInFile			
		INC   	Counter
		JMP 	charScan

	writeInFile:
		MOV 	BX, FileHandleDst
		LEA 	DI, Counter	
		MOV		DL, [DI]	
		CALL	setChar		
		INC		SI			
		MOV		Counter, 0	
		MOV		BX, FileHandleSrc				
		CALL 	fclose		
		JMP 	iterateFile
	
	endFile:
		INC 	SI
		MOV		BX, FileHandleSrc				
		CALL	fclose
		JMP 	iterateFile

	returnLoop:								
		INC		SI
		JMP 	iterateFile		

errorCarry:
; Informa o erro na leitura do arquivo
	LEA 	BX, ErrorReadFile
	CALL 	printf_s
	.exit 	1


EndProgram:
; Fim do programa

	CALL	TheEnd
	.exit 	0

TheEnd:
; Imprime o resumo das operações 

	mov		bx,FileHandleSrc	; Fecha arquivo origem
	call	fclose

	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, InputFileSize
	CALL 	printf_s
	MOV		AX, FileSize
	CALL    printNb
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, WordSize
	CALL 	printf_s
	MOV		AX, PhraseSize
	CALL    printNb
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, OutFilename
	CALL 	printf_s
	LEA 	BX, FileNameDst
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, NoError
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, MsgCRLF
	CALL 	printf_s
	.exit 0

errorFile:
; Erro de leitura no arquivo

	LEA 	BX, MsgCRLF
	CALL 	printf_s
	LEA 	BX, ErrorReadFile
	CALL 	printf_s
	.exit 	1

errorSizeFile:
; Erro caso o arquivo for grande

	LEA 	BX, ErrorFileSize
	CALL 	printf_s
	.exit 	1	

.exit 	0

; Funções -----------------------------------------------------------	

; ================================================
; Escreve arquivo
; • INT 21H
; • Entra
;   – AH = 40H
;   – BX = handle do arquivo
;   – CX = número de bytes a serem escritos
;   – DS:DX = endereço do buffer de escrita
; • Retorna
;   – Se ok: CF = 0 e AX = número de bytes escritos
; ================================================

SetChar		proc	near
	MOV		AH, 40h
	MOV		CX, 1
	MOV		FileBuffer, DL
	LEA		DX, FileBuffer
	INT		21h
	RET
SetChar		endp	

; ================================================
; Lê arquivo
; • INT 21H
; • Entra
;   – AH = 3FH
;   – BX = handle do arquivo
;   – CX = número de bytes a serem lidos
;   – DS:DX = endereço do buffer de leitura
; • Retorna
;   – Se ok: CF = 0 e AX = número de bytes lidos
;       • AX = 0 se for final do arquivo
; ================================================
GetChar		proc	near
	; mov		bx,FileHandleSrc
	MOV		AH, 3FH
	MOV		CX, 1
	LEA		DX, FileBuffer
	INT		21H
	MOV		DL, FileBuffer

	RET
GetChar		endp

; GetFileName
; Obtém string para nome do arquivo
GetFileName		proc	near
	LEA		BX, PrintFilename
	CALL	printf_s
		
	LEA		BX, FileNameSrc
	CALL	gets
	
	LEA		BX, MsgCRLF
	CALL	printf_s
	
	RET
GetFileName		endp

; printf_s
; Exibe mensagens na tela
printf_s	proc	near
	MOV		DL, [BX]
	CMP		DL, 0
	JE		Ret_printf_s

	PUSH 	BX
	MOV		AH, 2					
	INT		21H
	POP		BX

	INC		BX
	JMP		printf_s
		
Ret_printf_s:
	RET
printf_s	endp

;--------------------------------------------------------------------
;Fun��o: Escreve o valor de AX na tela
;		printf("%
;--------------------------------------------------------------------
printf_w	proc	near
	; sprintf_w(AX, BufferWRWORD)
	lea		bx,BufferWRWORD
	call	sprintf_w
	
	; printf_s(BufferWRWORD)
	lea		bx,BufferWRWORD
	call	printf_s
	
	ret
printf_w	endp


;--------------------------------------------------------------------
;Fun��o: Converte um inteiro (n) para (string)
;		 sprintf(string->BX, "%d", n->AX)
;--------------------------------------------------------------------
sprintf_w	proc	near
	mov		sw_n,ax
	mov		cx,5
	mov		sw_m,10000
	mov		sw_f,0
	
sw_do:
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
	mov		sw_n,dx
	
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	dec		cx
	cmp		cx,0
	jnz		sw_do

	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:

	mov		byte ptr[bx],0
	ret		
sprintf_w	endp


; ================================================
; gets
; Leitura de Teclado (string)
;
; • INT 21H
; • Entra
;   – AH = 0AH
;   – DS:DX = endereço do buffer de teclado
; • Conteúdo do buffer
;   – Byte[0]: número máximo de caracteres que 
;   podem ser colocados no buffer
;   – Byte[1]: número de caracteres efetivamente 
;   lidos (sem considerar o CR)
;   – Byte[2...]: caracteres lidos, incluindo o CR
; ================================================
gets		proc	near
	PUSH	BX

	MOV		AH, 0AH
	LEA		DX, String
	MOV		byte ptr String, MAXSTRING-4
	INT		21H

	LEA		SI, String+2
	POP		DI
	MOV		CL, String+1
	MOV		CH, 0
	MOV		AX, DS
	MOV		ES, AX
	REP 	MOVSB

	MOV		byte ptr ES:[DI], 0
	RET
gets		endp

; ================================================
; fopen
; Abre arquivo para leitura
;
; • INT 21H
; • Entra
;   – AH = 3DH
;   – AL = modo de acesso e compartilhamento
;       • 0 para read
;   – DS:DX = nome do arquivo
;       • String terminado com ‘\0’
; • Retorna
;   – Se ok: CF = 0 e AX = handle do arquivo
; ================================================
fopen		proc	near
	MOV		AL, 0
	; LEA 	DX, FileNameSrc
	MOV		AH, 3DH
	INT		21H
	MOV		BX, AX
	; MOV		FileHandleSrc, BX
	RET
fopen		endp

; ================================================
; fwrite
; Abre arquivo para escrita
;
; • INT 21H
; • Entra
;   – AH = 3DH
;   – AL = modo de acesso e compartilhamento
;       • 1 para write only
;   – DS:DX = nome do arquivo
;       • String terminado com ‘\0’
; • Retorna
;   – Se ok: CF = 0 e AX = handle do arquivo
; ================================================
fwrite 		proc 	near
	MOV		AL, 1
	MOV		AH, 3DH
	INT		21H
	MOV		BX, AX
	RET
fwrite 		endp

; ================================================
; fcreate
; Cria arquivo
;
; • INT 21H
; • Entra
;   – AH = 3CH
;   – CX=atributos do arquivo
;   – DS:DX = nome do arquivo
;       • String terminado com ‘\0’
; • Retorna
;   – Se ok: CF = 0 e AX = handle do arquivo
; ================================================
fcreate 	proc 	near
	MOV		CX, 0
	MOV		AH, 3CH
	INT		21H
	MOV		BX, AX	
	RET
fcreate 	endp

; ================================================
; fclose
; Fecha arquivo
;
; • INT 21H
; • Entra
;   – AH = 3EH
;   – BX = handle do arquivo
; • Retorna
;   – Se ok: CF = 0
; ================================================
fclose		proc	near
	mov		ah,3eh
	int		21h
	ret
fclose		endp

; Ext
; Adiciona extensão ao arquivo
Ext		proc 	near

	MOV 	AL, 0

	loopExt:
		CMP 	[BX], AL				; Compara a posição do ponteiro com zero
		JE		putExt					; Se igual a zero, fim da string
		INC 	BX						; Se não, incrementa o ponteiro que percorre a string
		JMP 	loopExt

	putExt:
		CMP		[DI], AL				; Compara o conteúdo do endereço apontado por DI com 0
		JE		retExt					; Se igual, todos os caracteres foram inseridos
		MOV		CX, [DI]				; Se não, move a extensão [DI] para o registrador CX
		MOV		[BX], CX				; Move a extensão para o nome do arquivo
		ADD		BX, 1
		ADD		DI, 1
		
		JMP 	putExt	

	retExt:
		MOV		AX, 0
		MOV		BX, 0
		MOV 	CX, 0
		MOV 	DI, 0						

		RET
Ext 	endp

; OutFile
; Copia nome do arquivo de entrada para o arquivo de destino
OutFile	    proc	near

	MOV 	AL, 0

	loopOutFile:
		CMP 	[BX], AL
		JE 		retOutFile
		MOV 	CX, [BX]
		MOV 	[DI], CX
		INC 	BX
		INC		DI
		JMP 	loopOutFile

	retOutFile:
		MOV 	AX, 0
		MOV 	BX, 0
		MOV 	CX, 0
		MOV 	DI, 0

		RET

OutFile 	endp

; TestString
; Testa condições para que a mensagem possa ser criptografada
TestString	proc 	near

	MOV 	AL, 0

	loopStringSize:
		CMP 	CX, 102						
		JE 		errorSize					
		CMP		[BX], AL					
		JE 		emptyWord
		INC 	BX
		INC     CX
		JMP 	loopStringSize

	emptyWord:
		CMP 	CX, 0
		JE 		errorEmpty

	resetConfig:	
		LEA  	BX, RegularMsg
		MOV 	AX, 0
		MOV 	CX, 0

	loopInt:
		CMP 	byte ptr [BX], ' '
		JL		errorInt
		CMP 	byte ptr [BX], '~'
		JG 		errorInt
		INC 	BX
		CMP 	[BX], CL 
		JE 		retTestString
		JMP     loopInt

	errorInt:
		LEA 	BX, ErrorRange
		CALL 	PrintError

	errorSize:
		LEA		BX, ErrorFileSize
		CALL 	PrintError

	errorEmpty:
		LEA  	BX, ErrorEmptyFile
		CALL 	PrintError

	retTestString:
		MOV		AX, 0						
		MOV 	BX, 0
		MOV 	CX, 0

		RET 
TestString 	endp

; PrintError
; Informa no console caso houverem erros no processamento ou execução
PrintError 	proc	near
		CALL 	printf_s
		LEA		BX, MsgCRLF
		CALL 	printf_s
		CALL 	fclose

		.exit 	1
		
PrintError 	endp

LoopPhraseSize		proc	near
	calcPhraseSize:
		CMP		byte ptr [BX], 0
		JE		returnLoopSize
		INC		BX
		INC		PhraseSize
		JMP		calcPhraseSize

	returnLoopSize:
		RET
LoopPhraseSize	endp

; ToUpper
; Transforma caracteres para maiúsculo
ToUpper 	proc 	near
	loopToUpper:
		CMP 	byte ptr [BX], 0					; Verifica se a string chegou ao final
		JE 		retToUpper

		CMP 	byte ptr [BX], 'A'					; Se menor que A
		JB 		incPtr
		CMP 	byte ptr [BX], 'Z'					; Se maior que Z
		JA 		tstLow					
		JMP 	incPtr
			
		tstLow:
			CMP		byte ptr [BX], 'a'			; Se menor que a
			JB		incPtr
			CMP		byte ptr [BX], 'z'			; Se maior que z		
			JA		incPtr
			SUB		byte ptr [BX], 20h	
		incPtr:	
			INC 	BX
		JMP 	loopToUpper

	retToUpper:
		MOV 	BX, 0
		RET
ToUpper 	endp

printNb		proc	near          
    MOV		CX, 0
    MOV 	DX, 0

    label1:
        CMP		AX, 0
        JE  	print1     
        MOV 	BX, 10       
        DIV 	BX                 
        PUSH 	DX             
        INC 	CX             
        XOR 	DX, DX
        JMP 	label1
    print1:
        CMP		CX, 0
        JE 		exit
        POP 	DX
        ADD 	DX, 48
        MOV 	AH, 02h
        INT 	21H
        DEC 	CX
        JMP 	print1
	exit:
		RET
	
printNb		endp

	end