;----------------------------------------------------------------------------------------------------
;	FILE NAME :	MASM4.asm
;----------------------------------------------------------------------------------------------------
;
;		Program Name	:	MASM4
;		Programmer		:	Cody Thompson 
;		Class			:	CS 3B || Asm Lang
;		Date			:	4/26/2018
;		Purpose			:	
;		This program will simulate a text editor.  Text input will be allowed through the console or
;	from a specified file.  All strings can be viewed, deleted, edited, searched and saved.
;
;----------------------------------------------------------------------------------------------------

	.486

	;Includes
	include ..\..\Irvine\Irvine32.inc
	include ..\..\Irvine\Macros.inc

	;Prototypes
	getstring				PROTO Near32 stdcall, lpStringToGet:dword, dlength:dword
	ascint32 				PROTO Near32 stdcall, lpStringOfNumericChars:dword
	memoryallocBailey		PROTO NEAR32 stdcall, dSize:dword
	ExitProcess 			PROTO, dwExitCode:dword

	;Constants

	;Struct definitions
ListNode STRUCT
  NodeData 		DWORD 	?
  NextPtr  		DWORD 	?
  dPosition		DWORD	?
ListNode ENDS

	;Macro definitions
	
	;Data segment
	.data
pListHead		DWORD		0	
pLastAddr		DWORD		0	
lListTail		ListNode	<0,0,0>
dCount			DWORD		0
	
strFileName		BYTE		"Input.txt"	
hFileHandle		HANDLE		?
hSTDHandle		HANDLE		?	
	
strMenu0 		BYTE		9h, 9h, "MASM4 TEXT EDITOR", 0Ah
strMenuMem		BYTE		9h, "Data Structure Memory Consumption: ", 0
strMenuBytes	BYTE		" bytes", 0Ah
strMenu1 		BYTE		"<1> View all strings", 0Ah, 0Ah
strMenu2 		BYTE		"<2> Add string", 0Ah
strMenu2a		BYTE		9h, "<a> from Keyboard", 0Ah
strMenu2b		BYTE		9h, "<b> from File. Statis file named input.txt", 0Ah, 0Ah
strMenu3 		BYTE		"<3> Delete string. Given an index #, delete the string and de-allocate memory", 0Ah, 0Ah
strMenu4 		BYTE		"<4> Edit string. Given an index #, replace old string w/ new string. Allocate/De-allocate as needed.", 0Ah, 0Ah
strMenu5 		BYTE		"<5> String search. Regardless of case, return all strings that match the substring given.", 0Ah, 0Ah
strMenu6 		BYTE		"<6> Save File", 0Ah, 0Ah
strMenu7 		BYTE		"<7> Quit", 0Ah, 0
strListSF		BYTE		"	The List So Far...", 0Ah, 0Ah, 0
strNodeNum		BYTE		"          Item number: ", 0 
strNodeData		BYTE		"            Node data: ", 0
strAddr			BYTE		"         This Address: ", 0
strInput		BYTE		"Please input a string to be saved in the list- ", 0Ah, 0 
strEmptyList	BYTE		"The list is empty.", 0Ah, 0

strSelection	BYTE		3 DUP(0)
strSelNum		BYTE		2 DUP(0)
dAllocatedBytes	DWORD 		0

	;Code segment
	.code
main proc												;start of main ;start of program
MENU:	
	CALL displayMenu									;display the menu
	
	CALL getSelection									;get the selection input
	JMP MENU
	
	INVOKE ExitProcess,0								;terminate program
main ENDP												;end of main procedure



;---------------------------------------------------------------------------------------
displayMenu				PROC	USES EDX
;
;		This procedure will display the general menu and accept input via the keyboard.
;	The selection entered will be returned to the EAX register.
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
MENU:	
	CALL 	ClrScr										;clear the console screen
	MOV		EDX,	OFFSET strMenu0						;move the offset address of strMenu0 into EDX
	CALL	WriteString									;write the string to the console
	MOV		EAX, 	dAllocatedBytes						;move the value of dAllocatedBytes into EAX
	CALL 	WriteHex									;write hex value to console 
	MOV		EDX, 	OFFSET strMenuBytes					;move offset address of strMenuBytes into EDX
	CALL	WriteString									;finish menu output
	INVOKE 	getstring, addr strSelection, 2				;get the string from the console and store it into memory labeled 'strInput
	CALL 	validateSelection							;validate the input selection
	CMP		AL,		0									;compare result to 0 (false)
	JE		MENU										;jump to menu if AL = 0
	
	RET
displayMenu ENDP



;---------------------------------------------------------------------------------------
validateSelection		PROC		USES	ESI	EBX	
;
;		This procedure will validate the input stored in strSelection to ensure it is
;	within the menu boundaries.  1 will be returned in the AL register if the input is validate
;	or 0 if the input is invalid.
;	Receives: 	Nothing
;	Returns:  	1 or 0 to the AL register
;---------------------------------------------------------------------------------------
	MOV 	ESI,	OFFSET	strSelection				;move the offset address of strSelection into ESI	

	MOV		BL,		[ESI]								;move nth index of strSelection into BL for comparison
	CMP		BL,		31h									;compare to ascii value of '1'
	JL 		FALSE1										;jump if BL is anything less than 31h
	CMP		BL,		37h									;compare to ascii value of '7'
	JG		FALSE1										;jump if bl is anything greater than 37h
	
	;if BL is equal to ascii value of '2'
.IF		BL == 32h
	MOV		BL,		[ESI+1]								;move the next index of strSelection into BL
	CMP		BL,		60h									;compare to ascii value 1 less than 'a'
	JLE		FALSE1										;jump if equal or anything less than 60h
	CMP		BL,		63h									;compare to ascii value 1 more than 'b'
	JGE		FALSE1										;jump if equal or anything greater than 63h
.ENDIF	
	
	MOV		AL,		1									;move 1 into AL (true state)
	JMP RETURN											;jump to return
	
FALSE1:
	MOV		AL,		0									;move o into AL (false state)

RETURN:	
	RET
validateSelection		ENDP



;---------------------------------------------------------------------------------------
getSelection			PROC		USES	ESI	EBX	EAX
;
;		This procedure will convert the input in strSelection to integer format and execute
;	the appropriate procedure.  
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	MOV		ESI, 	OFFSET strSelection					;move the offset address of strSelection into ESI
	MOV		BL, 	[ESI]								;move the first element of strSelection into BL	
	MOV		strSelNum,	BL								;move BL into strSelNum
	INVOKE	ascint32,	addr strSelNum					;convert strSelNum to integer format
	MOV		BL,		[ESI+1]								;move 2nd index of strSelection into BL
	
.IF			EAX == 1
	CALL 	dumpList									;call dumpList, display the entire list
	JMP		RETURN
	
.ELSEIF		EAX == 2
	;case 2a
	.IF		BL	== 61h
	CALL	createOne									;call createOne, insert a node with input via keyboard	

	;case 2b
	.ELSE
	
	.ENDIF
	
	JMP		RETURN
.ELSEIF		EAX == 3

	JMP		RETURN
.ELSEIF		EAX == 4

	JMP		RETURN
.ELSEIF		EAX == 5

	JMP		RETURN
.ELSEIF		EAX == 6

	JMP		RETURN
.ELSEIF		EAX == 7
	INVOKE ExitProcess,0		
	
.ENDIF

RETURN:
	RET
getSelection 			ENDP



;---------------------------------------------------------------------------------------
dumpList		PROC		USES	EDX	ESI	EAX	ECX
;
;		This procedure will display the entire list to the console in a first-to-last order.
;	The objects number, data and address will be displayed.
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	CALL	ClrScr										;call ClrScr, clear the screen
	MOV		ECX, 	dCount								;move dCount into ECX
	CMP		ECX,	0									;ensure the list is not empty
	JE		EMPTY										;if list is empty jump to EMPTY
	
	CALL	ClrScr										;call ClrScr, clear the console screen
	MOV 	EDX,	OFFSET strListSF					;move the offset of strListSF into EDX
	CALL	WriteString									;write string of address EDX to console
	MOV 	ESI,	pListHead							;move the head of the list into ESI

WLOOP:	
	MOV 	EDX,	OFFSET strNodeNum					;move the offset of strNodeNum into EDX
	CALL	WriteString									;write string of address EDX to console
	MOV 	EAX,	(ListNode PTR [ESI]).dPosition		;move current nodes dPosition value into EAX
	CALL 	WriteDec									;write decimal of value EAX to console
	CALL	Crlf										;call Crlf, go to the next line
	MOV 	EDX,	OFFSET strNodeData					;move offset addresS of strNodeData into EDX
	CALL	WriteString									;write string of address EDX to console
	MOV 	EDX,	(ListNode PTR [ESI]).NodeData		;move current nodes nodeData into EDX
	CALL 	WriteString									;write string of address EDX to console
	CALL	Crlf										;call Crlf, go to the next line
	MOV 	EDX,	OFFSET strAddr						;move the offset address of strAddr into EDX
	CALL	WriteString									;write string of address EDX to console
	MOV 	EAX, 	ESI									;move the value of ESI (current nodes address) into EAX
	CALL	WriteHex									;write hex of value EAX to console

	CALL	Crlf										;call Crlf, go to the next line
	CALL	Crlf										;call Crlf, go to the next line
	CALL	Crlf										;call Crlf, go to the next line
	CALL	Crlf										;call Crlf, go to the next line

	MOV		EAX,	(ListNode PTR [ESI]).NextPtr		;move the next pointer into EAX
	MOV 	ESI,	EAX									;move the address in EAX into ESI
	MOV		ECX,	(ListNode PTR [ESI]).dPosition		;move the next nodes position into ECX
	CMP		ECX, 	0									;ensure end of list has not been reached
	JNE		WLOOP										;jump so long as dPosition != 0
	JMP 	RETURN										;jump to return

EMPTY:	
	MOV		EDX,	OFFSET strEmptyList					;move offset address of strEmptyList into EDX
	CALL	WriteString									;write string of address EDX to the console
	
RETURN:	
	CALL	WaitMsg										;wait for any key to be pressed
	
	RET
dumpList		ENDP


;---------------------------------------------------------------------------------------
createOne		PROC		USES	EAX	ESI	ECX	EBX	
;
;		This procedure will allocate memory for a new listNode object and populate its
;	attributes with proper data.  If memory can not be allocated a message will be displayed 
;	and the procedure will return to the main driver.
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	INVOKE memoryallocBailey, 12  						;allocate memory for listNode
	
	;fail state
.IF 		EAX == NULL
	mWrite "HeapAlloc failed"							;write fail message to console
	jmp 	QUIT										;jump to quit
.ENDIF
	MOV		ECX,	dAllocatedBytes						;move value of dAllocatedBytes into ECX
	ADD		ECX,	12									;add 12 to current value in dAllocatedBytes
	MOV		dAllocatedBytes,		ECX					;save the new value to memory
	INC 	dCount										;move list count into ECX
	MOV	 	ECX,	dCount								;increment count
	MOV		ESI,	pLastAddr							;move the address in pLastAddr into ESI
	
	;set pointer if list is null
.IF ECX == 1			
	MOV	 	pListHead, EAX								;set list head to current address in EAX
	
	;set pointers if list has at least one element
.ELSE
	MOV		(ListNode PTR [ESI]).NextPtr, EAX			;set the last list items NextPtr equal to the address in EAX
	
.ENDIF
	MOV		(ListNode PTR [EAX]).NextPtr, OFFSET lListTail;set next pointer to NULL
	MOV 	pLastAddr, 	EAX								;save the last address to memory
	MOV 	(ListNode PTR [EAX]).dPosition, ECX			;move data into list node
	CALL	getStringInput									;call getString, get string data from keyboard
	MOV		(ListNode PTR [EAX]).NodeData, EBX			;move the new string address into .NodeData
	
QUIT:
	RET
createOne	ENDP



;---------------------------------------------------------------------------------------
getStringInput		PROC		USES	EAX	EDX	ECX
;
;		This procedure is invoked by createOne and will display a prompt asking for an input
;	string.  512 bytes of memory will be allocated for the string and the new string will
;	be stored at that address.  The newly allocated memory's address will be returned in EBX.
;	Receives:	Nothing
;	Returns:	Newly allocated memory address in EBX register
;---------------------------------------------------------------------------------------
	CALL	ClrScr										;call ClrScr, clear the console screen
	INVOKE 	memoryallocBailey, 512  					;allocate 512 bytes of memory
	MOV		ECX,	dAllocatedBytes						;move value of dAllocatedBytes into ECX
	ADD		ECX,	512									;add 512 to current value in dAllocatedBytes
	MOV		dAllocatedBytes,		ECX					;save the new value to memory
	MOV 	EBX,	EAX									;move the address in EAX into EBX
	MOV 	EDX,	OFFSET strInput						;move the offset address of strInput into EDX
	CALL	WriteString									;write the string of address EDX to the console
	
	INVOKE	getString, EBX, 512							;get the string from the console
	
	RET
getStringInput		ENDP

end main												;end of main




