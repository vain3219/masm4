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
	GetClipboardData		PROTO, something:dword
	GlobalLock				PROTO, :DWORD
	OpenClipboard			PROTO, something:dword
	GlobalSize				PROTO, something:dword
	lstrcpy					PROTO, :DWORD, :DWORD
	GlobalUnlock			PROTO, :DWORD
	CloseClipboard			PROTO
	ExitProcess 			PROTO, dwExitCode:dword

	;Constants
HEAP_START		=		2000000
HEAP_MAX		=		400000000
BUFF_SIZE		=		512
	
	;Struct definitions
ListNode STRUCT
  NodeData 		DWORD 	?
  NextPtr  		DWORD 	?
  dPosition		DWORD	?
  heapHandle	HANDLE	?
ListNode ENDS

	;Macro definitions
	
	;Data segment
	.data
pListHead		DWORD		OFFSET	lListTail	
pLastAddr		DWORD		OFFSET	lListTail	
lListTail		ListNode	<0,0,0>
dCount			DWORD		0
mHeap			HANDLE		?
	
strInputFile	BYTE		"Input.txt"
strSaveFile		BYTE		"Save.txt"
hFileHandle		HANDLE		?
hSTDHandle		HANDLE		?	
dBytesWritten	DWORD		0	
	
strMenu0 		BYTE		9h, 9h, "MASM4 TEXT EDITOR", 0Ah
strMenuMem		BYTE		9h, "Data Structure Memory Consumption: ", 0
strMenuBytes	BYTE		" bytes", 0Ah
strMenu1 		BYTE		"<1> View all strings", 0Ah, 0Ah
strMenu2 		BYTE		"<2> Add string", 0Ah
strMenu2a		BYTE		9h, "<a> from Keyboard", 0Ah
strMenu2b		BYTE		9h, "<b> from File. Static file named input.txt", 0Ah
strMenu2c		BYTE		9h,	"<c> from the clipboard", 0Ah, 0Ah
strMenu3 		BYTE		"<3> Delete string. Given an index #, delete the string and de-allocate memory", 0Ah, 0Ah
strMenu4 		BYTE		"<4> Edit string. Given an index #, replace old string w/ new string. Allocate/De-allocate as needed.", 0Ah, 0Ah
strMenu5 		BYTE		"<5> String search. Regardless of case, return all strings that match the substring given.", 0Ah, 0Ah
strMenu6 		BYTE		"<6> Save File", 0Ah, 0Ah
strMenu7 		BYTE		"<7> Quit", 0Ah, 0
strListSF		BYTE		"	The List So Far...", 0Ah, 0Ah, 0
strNodeNum		BYTE		"          Item number: ", 0 
strNodeData		BYTE		"            Node data: ", 0
strAddr			BYTE		"         This Address: ", 0
strInput		BYTE		"Please enter a string to be saved in the list- ", 0Ah, 0 
strEmptyList	BYTE		"The list is empty.", 0Ah, 0
strIndexInput	BYTE		"Please input a node position (item #): ", 0
strSavePrompt	BYTE		"Would you like to append to the current data?(y/n): ", 0
strSubPrompt	BYTE		"Please enter a string to be searched for- ", 0Ah, 0

strBuffer		BYTE		512	DUP(0)
strSelection	BYTE		3 	DUP(0)
strSelNum		BYTE		2 	DUP(0)
dAllocatedBytes	DWORD 		0
dInt			DWORD		0

	;Code segment
	.code
main proc												;start of main ;start of program
	INVOKE	HeapCreate, 0, HEAP_START, HEAP_MAX			;allocate new private heap
.If	EAX == NULL
	CALL	WriteWindowsMsg
	JMP		QUIT
.ELSE
	MOV		mHeap,	EAX
.ENDIF

MENU:	
	CALL 	displayMenu									;display the menu
	
	CALL 	getSelection								;get the selection input
	JMP 	MENU
	
QUIT:	
	INVOKE 	HeapDestroy,	mHeap						;Destroy the private heap
.IF eax == NULL
	CALL 	WriteWindowsMsg 							; show error message
.ENDIF
	INVOKE 	ExitProcess,	0							;terminate program
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
	CMP		BL,		64h									;compare to ascii value 1 more than 'b'
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
	CALL	ClrScr										;call ClrScr, clear the screen
	
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
	.ELSEIF	BL == 62h
	
	
	;case 2c
	.ELSEIF	BL == 63h
	CALL	pasteClipBoard
	.ENDIF
	
	JMP		RETURN
.ELSEIF		EAX == 3
	CALL	deleteNode									;call deleteNode, deletes the target node and de-allocates memory
	JMP		RETURN
.ELSEIF		EAX == 4
	CALL	editTarget									;call editTarget, edits the target string and adjust memory as needed
	JMP		RETURN
.ELSEIF		EAX == 5
	CALL	substringSearch								;call substringSearch, display all strings that match the substring
	JMP		RETURN
.ELSEIF		EAX == 6
	CALL	saveListToFile								;call saveListToFile, writes all  ListNode strings to Save.txt (overwrites current file)
	JMP		RETURN
.ELSEIF		EAX == 7
	INVOKE 	HeapDestroy,	mHeap						;Destroy the private heap
.IF eax == NULL
	CALL 	WriteWindowsMsg 							; show error message
.ENDIF
	INVOKE ExitProcess,0								;exit process
	
.ENDIF

RETURN:
	CALL	Crlf										;call Crlf, go to the next line
	CALL	WaitMsg										;wait for any key to be pressed
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
	MOV 	ESI,	pListHead							;move the head of the list into ESI
	MOV		ECX,	(ListNode PTR [ESI]).dPosition		;move the position # of address ESI into ECX
	CMP		ECX,	0									;ensure the list is not empty
	JE		EMPTY										;if list is empty jump to EMPTY
	
	MOV 	EDX,	OFFSET strListSF					;move the offset of strListSF into EDX
	CALL	WriteString									;write string of address EDX to console

WLOOP:	
	CALL	Crlf										;call Crlf, go to the next line
	MOV 	EAX,	(ListNode PTR [ESI]).dPosition		;move current nodes dPosition value into EAX
	CALL 	WriteDec									;write decimal of value EAX to console
	mWrite	" "											;
	MOV 	EDX,	(ListNode PTR [ESI]).NodeData		;move current nodes nodeData into EDX
	CALL 	WriteString									;write string of address EDX to
	
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
START:
	INVOKE 	HeapAlloc, mHeap, HEAP_ZERO_MEMORY, 16		;allocate memory for a ListNode STRUCT
	
	;fail state
.IF 		EAX == NULL
	mWrite "HeapAlloc failed"							;write fail message to console
	jmp 	QUIT										;jump to quit
.ENDIF
	MOV		ECX,	dAllocatedBytes						;move value of dAllocatedBytes into ECX
	ADD		ECX,	16									;add 12 to current value in dAllocatedBytes
	MOV		dAllocatedBytes,		ECX					;save the new value to memory
	INC 	dCount										;move list count into ECX
	MOV 	EDX,	dCount								;move dCount into EDX
	MOV		ESI,	pLastAddr							;move the address in pLastAddr into ESI
	MOV	 	ECX,	(ListNode PTR [ESI]).dPosition		;increment count
	
	;set pointer if list is null
.IF ECX == 0			
	MOV	 	pListHead, EAX								;set list head to current address in EAX
	
	;set pointers if list has at least one element
.ELSE
	MOV		(ListNode PTR [ESI]).NextPtr, EAX			;set the last list items NextPtr equal to the address in EAX
	
.ENDIF
	MOV		EBX,	mHeap
	MOV		(ListNode PTR [EAX]).heapHandle, EBX		;move mHeap into heapHandle
	MOV		(ListNode PTR [EAX]).NextPtr, OFFSET lListTail;set next pointer to NULL
	MOV 	pLastAddr, 	EAX								;save the last address to memory
	MOV 	(ListNode PTR [EAX]).dPosition, EDX			;move count # into dPosition
	MOV 	EDX,	OFFSET strInput						;move the offset address of strInput into EDX
	CALL	WriteString									;write the string of address EDX to the console
	CALL	getStringInput								;call getString, get string data from keyboard
	MOV		ESI,	EBX
	CALL	getCount
	ADD		ECX,	dAllocatedBytes
	MOV		dAllocatedBytes,	ECX
	MOV		(ListNode PTR [EAX]).NodeData, EBX			;move the new string address into .NodeData

QUIT:
	RET
createOne	ENDP



;---------------------------------------------------------------------------------------
getStringInput		PROC		USES	EAX	EDX	ECX ESI
;
;		This procedure is invoked by createOne and will display a prompt asking for an input
;	string.  512 bytes of memory will be allocated for the string and the new string will
;	be stored at that address.  The newly allocated memory's address will be returned in EBX.
;	Receives:	Nothing
;	Returns:	Newly allocated memory address in EBX register
;---------------------------------------------------------------------------------------
	INVOKE	getString, addr strBuffer, 512				;get the string from the console
	
	MOV		ESI,	OFFSET strBuffer
	CALL	getCount									;get the number of characters in strBuffer
	
	INVOKE 	HeapAlloc, mHeap, HEAP_ZERO_MEMORY, ECX		;allocate memory on the heap
	MOV 	EBX,	EAX									;move the address in EAX into EBX
	
	CALL	stringCopy									;copy strBuffer into new address
	
	RET
getStringInput		ENDP



;---------------------------------------------------------------------------------------
getCount		PROC		USES	EAX	ESI
;
;		This procedure will count how many characters are in the byte array addressed in ESI.
;	All characters will be counted until a null, 0h, is reached indicating the end of the 
;	string.
;	Receives:	address of string to be counter in ESI
;	Returns:	# of characters to ECX
;---------------------------------------------------------------------------------------
	MOV		ECX,	0									;clear ECX
	
L1:
	MOV		AL,		[ESI]								;move the nth element of [ESI] into AL
	CMP		AL,		0									;nth element to 0
	JE		RETURN										;jump if nth element equals 0
	INC		ESI											;go to nth + 1 element
	INC		ECX											;increment ECX
	JMP		L1											;jump to L1
RETURN:	
	RET
getCount		ENDP



;---------------------------------------------------------------------------------------
stringCopy		PROC		USES	EBX	ESI
;
;		This procedure copies the contents of strBuffer into a newly allocated string address.
;	All elements will be copied until a null character, 0h, is reached.  The address is 
;	received through the EAX register.
;
;	Receives:	New string address in EAX
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	MOV		ESI,	OFFSET strBuffer					;move the offset address of strBuffer into ESI
	
L1:
	MOV		BL,		[ESI]								;move the nth element of [ESI] into BL
	CMP		BL,		0									;compare nth element to 0
	JE		RETURN										;jump if nth element equals 0
	MOV		[EAX],	BL									;move BL into the nth element into [EAX]
	INC		ESI											;go to nth + 1 element of ESI
	INC		EAX											;go to nth + 1 element of EAX
	JMP		L1											;jump to L1
	
RETURN:
	;add CRLF and null characters
	MOV		BL,		13									;move CR into BL
	MOV		[EAX],		BL								;move BL into [EAX]
	MOV		BL,		0Ah									;move LF into BL
	MOV		[EAX + 1],	BL								;move BL into [EAX+1]
	MOV		BL,		0									;move null into BL
	MOV		[EAX + 2], 	BL								;move BL into [EAX+2]
	RET
stringCopy		ENDP



;---------------------------------------------------------------------------------------
deleteNode		PROC		USES	EDX	EDI	ESI	ECX	EAX	EBX	
;
;		This procedure will prompt for an node number (dPosition) to search for and delete.
;	If the node is found it will be 'unlinked' from the list and its memory de-allocated. A 
;	message will be displayed reflecting the result of the search/deletion.   
;
;---------------------------------------------------------------------------------------
	MOV		ESI,	pListHead							;ESI == N
.IF		ESI == OFFSET lListTail
	mWrite "The list is empty."							;display console message
	JMP		QUIT										;jump to quit
.ENDIF	

	MOV		EDX,	OFFSET strIndexInput				;move offset of strIndexInput into EDX
	CALL 	WriteString									;write the string of address EDX to the console
	INVOKE	getString, addr	strSelNum, 3				;get string input
	INVOKE	ascint32, addr strSelNum					;convert to 32 integer
	CALL	Crlf
	
	MOV 	EDX,	0
	
	MOV 	EDI,	OFFSET pListHead					;EDI == N - 1
	MOV		EBX,	(ListNode PTR [ESI]).NextPtr		;EBX == N + 1
	MOV		ECX,	(ListNode PTR [ESI]).dPosition		;ECX == N.dPosition
	
	;check for item
CHECKL:	
	;item not found
.IF			ECX == 0
	mWrite	"Node not found."							;write not found message to console		
	JMP		QUIT										;item is not found		;jump to QUIT

	;item is found
.ELSEIF		ECX == EAX
	JMP		FOUND										;item is found			;jump to FOUND
.ELSE	
	INC		EDX
	MOV		EDI,	ESI									;EDI == N				;next loops N - 1
	MOV		ESI,	EBX									;ESI == N + 1			;next loops N
	MOV		EBX,	(ListNode	PTR	[ESI]).NextPtr		;EBX == N + 2			;next loops N + 1
	MOV		ECX,	(ListNode PTR [ESI]).dPosition		;ECX == N.dPosition
	JMP		CHECKL
.ENDIF	
	
	;item found;;	De-allocate memory
FOUND:	
	;target item is last in the list
.IF		EBX == 0
	MOV		pLastAddr,	EDI								;move the previous address into memory labeled pLastAddr
.ENDIF
	;target item is first in the list
.IF		EDX == 0
	MOV		pListHead,	EBX								;move the next address into memory labeled pListHead
.ENDIF

	mWrite	"Delete successful!"						;write success message to the console 
	PUSH	ESI											;save contents of ESI
	MOV		EDX,	(ListNode PTR [ESI]).nodeData		;move nodeData into EDX
	MOV		ESI,	EDX									;move nodeData into ESI
	CALL	getCount									;call getCount
	ADD		ECX,	16									;add number of bytes for ListNode being deleted
	SUB		dAllocatedBytes, ECX						;move dAllocatedBytes value to EAX
	POP		ESI
	
	MOV		EAX,	(ListNode PTR [ESI]).heapHandle		;move the heap handle into EAX
	;MOV		mHeap,	EAX									;move heapHandle to memory for de-allocation
	INVOKE	HeapFree, EAX, 0, ESI						;de-allocate

	MOV		(listNode	PTR	[EDI]).NextPtr,	EBX			;move the next address into (previous address).NextPtr
	
	JMP QUIT
	;item not found
NOTFOUND:
	mWrite	"Node not found."							;write not found message to console
	JMP		QUIT
	;immediate quit
QUIT:
	RET
deleteNode		ENDP



;---------------------------------------------------------------------------------------
editTarget		PROC		USES	EDX	EDI	ESI	EBX	ECX	EAX
;
;		This procedure will prompt for a list index number and search the list for the given 
;	index.  If the index is found another prompt will be printed to the console asking for a 
;	replacement string.  The given string will have new memory generated from the heap and 
;	its address moved into the respective N.NodeData field of the STRUCT.
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	MOV		ESI,	pListHead							;ESI == N
.IF		ESI == OFFSET lListTail
	mWrite "The list is empty."							;display console message
	JMP		QUIT										;jump to quit
.ENDIF	
	
	MOV		EDX,	OFFSET strIndexInput				;move offset of strIndexInput into EDX
	CALL 	WriteString									;write the string of address EDX to the console
	INVOKE	getString, addr	strSelNum, 3				;get string input
	INVOKE	ascint32, addr strSelNum					;convert to 32 integer
	CALL	Crlf										;call Crlf, go to the next line
	MOV		EDX,	OFFSET strInput						;move the string address into EDX
	CALL	WriteString									;write prompt to console
	
	MOV 	EDX,	0
	
	MOV 	EDI,	OFFSET pListHead					;EDI == N - 1
	MOV		EBX,	(ListNode PTR [ESI]).NextPtr		;EBX == N + 1
	MOV		ECX,	(ListNode PTR [ESI]).dPosition		;ECX == N.dPosition
	
	;check for item
CHECKL:	
	;item not found
.IF			ECX == 0
	mWrite	"Node not found."							;write not found message to console		
	JMP		QUIT										;item is not found		;jump to QUIT

	;item is found
.ELSEIF		ECX == EAX
	JMP		FOUND										;item is found			;jump to FOUND
.ELSE	
	INC		EDX
	MOV		EDI,	ESI									;EDI == N				;next loops N - 1
	MOV		ESI,	EBX									;ESI == N + 1			;next loops N
	MOV		EBX,	(ListNode	PTR	[ESI]).NextPtr		;EBX == N + 2			;next loops N + 1
	MOV		ECX,	(ListNode PTR [ESI]).dPosition		;ECX == N.dPosition
	JMP		CHECKL
.ENDIF	
	
	;item found;;	Edit string
FOUND:	
	PUSH	ESI
	MOV		EAX,	ESI
	MOV		ESI,	(ListNode	PTR [EAX]).nodeData
	CALL	getCount
	SUB		dAllocatedBytes,	ECX
	;MOV		dAllocatedBytes,	ECX
	;target item is last in the list
	CALL	getStringInput								;get the new string
	MOV		ESI,	EBX
	CALL	getCount
	ADD		ECX,	dAllocatedBytes
	MOV		dAllocatedBytes,	ECX
	POP		ESI
	MOV		(ListNode	PTR	[ESI]).NodeData,	EBX		;move the new string address into nodeData
	
	CALL	Crlf										;call Crlf, go to the next line
	mWrite	"Edit successful!"							;write success message to the console 
	
	JMP QUIT
	;item not found
NOTFOUND:
	mWrite	"Node not found."							;write not found message to console
	JMP		QUIT
	;immediate quit
QUIT:
	RET
editTarget		ENDP



;-------------------------------------------------------------------------------------------------
pasteClipBoard		PROC
;
;		This procedure will copy any text data from the windows clipboard and dynamically allocate a
;	buffer to store the text.  Another procedure will be called to parse the text and add it to the
;	linked list.
;
;	Receives:	Nothing
;	Returns:	Nothing
;------------------------------------------------------------------------------------------------   
.data
	hDynamicBuffer		DWORD 	0
	hClipBoard			HANDLE 	0
	dBuffSize			DWORD	0
	
.code	
	INVOKE 	OpenClipboard,NULL										;open the clipboard process
	
    INVOKE 	GetClipboardData, 1										;return a handle to the clipboards data
	MOV		hClipBoard,	EAX											;save the result into hClipBoard
	
	INVOKE 	GlobalSize, hClipBoard									;get the size of the data on the clipboard
	INC		EAX														;increment by 1 to account for null
	MOV		dBuffSize,	EAX											;move the new size into dBuffSize									
	ADD		dAllocatedBytes, EAX									;add EAX to the value labeled dAllocatedBytes
	
	INVOKE 	HeapAlloc, mHeap, HEAP_ZERO_MEMORY, dBuffSize			;allocate memory for the dynamic buffer
	MOV		hDynamicBuffer,		EAX									;move the handle for the allocated memory into hDynamicBuffer
	MOV		EAX,	hClipBoard										;move hClipBoard (clipboard data handle) into EAX
	
	INVOKE 	GlobalLock, EAX											;lock the clipboard data in memory and return the address of its first byte
	INVOKE 	lstrcpy, hDynamicBuffer, EAX							;copy the string at address EAX into memory labeled hDynamicBuffer
	INVOKE	GlobalUnlock, hClipBoard								;unlock the data in memory
	
	INVOKE	CloseClipboard											;close the clipboard process

	MOV		ESI,	hDynamicBuffer									;move hDynamicBuffer value into ESI for parseBufferToNode
	CALL	parseBufferToNode
	
	INVOKE	HeapFree, mHeap, 0, hDynamicBuffer						;de-allocate
	
	RET
pasteClipBoard		ENDP


;-------------------------------------------------------------------------------------------------------------------
parseBufferToNode			PROC	USES	EBX
;	
;		This procedure will receive a string in ESI and parse the string by ending each string with CRLF and a null.
;	After a new string has been allocated and copied it will be passed to the procedure "appendStrToList" which will 
;	add the newly allocated node to the end of the list and sets all of its data.
;
;	Receives:	Address of dynamic buffer in ESI
;	Returns:	Nothing
;-------------------------------------------------------------------------------------------------------------------
PARSE:
	MOV		ECX,	0									;clear ECX
	PUSH 	ESI											;save the pasted buffer address
	;get count for string allocation
COUNT:
	MOV		BL,		[ESI]								;move the nth element of [ESI] into BL
	CMP		BL,		0Ah									;compare nth element of ESI to BL
	JE		ALLOC										;if equal jump to ALLOC
	CMP		BL,		0
	JE		ALLOC										;if equal jump to EOC
	INC		ECX											;increment ECX
	INC		ESI											;increment ESI
	JMP		COUNT										;jump to COUNT
	
	;allocate memory for string
ALLOC:	
	ADD		ECX,	2									;add room to count for LF and null 

	POP		ESI											;restore ESI
	PUSH	ECX											;save ECX
	INVOKE 	HeapAlloc, mHeap, HEAP_ZERO_MEMORY, ECX		;allocate memory on the heap of size ECX
	MOV 	EDI,	EAX									;move the new address into EDI
	MOV		EBX,	EDI									;move EDI into EDX
	
	POP		ECX											;restore ECX
	INC		dAllocatedBytes								;increment dAllocatedBytes
	INC		dAllocatedBytes								;increment dAllocatedBytes
	DEC		ECX											;decrement ECX
	
	;copy string data
COPY:
	MOV		DL,		[ESI]								;move the nth element of [ESI] into BL
	MOV		[EDI],	DL									;move BL into the nth element into [EAX]
	INC		ESI											;go to nth + 1 element of ESI
	INC		EDI											;go to nth + 1 element of EAX
	DEC		dBuffSize									;decrement dBuffSize
	LOOP	COPY										;LOOP to COPY until ECX = 0

	;allocate node
STRDONE:	
	MOV		EDX, 	EAX									;move the address into EDX for appendStrToList
	CALL 	appendStrToList								;call appendStrToList
.IF		dBuffSize == 0			
	JMP		RETURN										;jump to return if dBuffSize == 0
.ENDIF		
	MOV		BL,		[ESI+1]								;move the next element of [ESI] into BL
	CMP		BL, 	0									;compare BL to 0
	JNE		PARSE										;jump to parse if they are not equal
	
RETURN:
	RET
parseBufferToNode			ENDP



;---------------------------------------------------------------------------------------------------
appendStrToList			PROC		USES	ESI	EAX ECX	EDX
;
;	This procedure appends a node of address EAX into the linked list.
;
;	Receives:	New node address in EAX
;	Returns:	Nothing
;---------------------------------------------------------------------------------------------------
	PUSH 	EDX
	
	INVOKE 	HeapAlloc, mHeap, HEAP_ZERO_MEMORY, 16		;allocate memory for a ListNode STRUCT
	
	;fail state
.IF 		EAX == NULL
	mWrite "HeapAlloc failed"							;write fail message to console
	jmp 	QUIT										;jump to quit
.ENDIF
	ADD		dAllocatedBytes,	16						;save the new value to memory
	
	MOV		ESI,	pLastAddr							;move the address in pLastAddr into ESI
	MOV	 	ECX,	(ListNode PTR [ESI]).dPosition		;increment count
	
	;set pointer if list is null
.IF ECX == 0			
	MOV	 	pListHead, EAX								;set list head to current address in EAX
	
	;set pointers if list has at least one element
.ELSE
	MOV		(ListNode PTR [ESI]).NextPtr, EAX			;set the last list items NextPtr equal to the address in EAX
	
.ENDIF
	MOV		EBX,	mHeap
	MOV		(ListNode PTR [EAX]).heapHandle, EBX		;move mHeap into heapHandle
	MOV		(ListNode PTR [EAX]).NextPtr, OFFSET lListTail;set next pointer to NULL
	MOV 	pLastAddr, 	EAX								;save the last address to memory
	POP		EDX
	MOV		(ListNode PTR [EAX]).NodeData, EDX			;move the new string address into .NodeData
	INC 	dCount										;move list count into ECX
	MOV 	EDX,	dCount								;move dCount into EDX
	MOV 	(ListNode PTR [EAX]).dPosition, EDX			;move count # into dPosition

QUIT:
	RET
appendStrToList			ENDP



;---------------------------------------------------------------------------------------
substringSearch		PROC		USES	EAX	EBX	ECX	EDX	ESI EDI
;
;		This procedure will search all the strings in the linked list for a match to the sub 
;	string.  If a match is found the string will be printed to the console.
;
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	MOV		ESI,	pListHead							;ESI == N
	
.IF		ESI == OFFSET lListTail
	mWrite "The list is empty. "						;display console message
	JMP		QUIT										;jump to QUIT
.ELSE
	MOV		EDX,	OFFSET strSubPrompt					;move offset address of strSubPrompt into EDX
	CALL	WriteString									;write msg to the console
	CALL	getStringInput								;call getStringInput, dynamically allocate a string
	CALL	Crlf										;call Crlf, go to the next line
.ENDIF	

	MOV		EAX, 	EBX									;move the address of the new string into EDI
	MOV		ECX,	0									;clear ECX
	
START:
	MOV		EDI,	EAX									;restore to EDI
	MOV		EDX,	(ListNode PTR [ESI]).nodeData		;move N.nodeData into EDX
SUBSRCH:
	MOV		BL,		[EDX]								;move nth element of List string into BL
	
.IF		BL == 0
	.IF	BYTE PTR [EDI] == 0	
	JMP		MATCH										;match was found
	.ENDIF
	JMP		NEXT										;at the end of list string
.ENDIF	

.IF	BYTE PTR [EDI] == 13
	JMP		MATCH
.ENDIF
	
.IF	BYTE PTR [EDI] == BL
	INC		EDX											;go to the next list string element
	INC		EDI											;go to the next search string element
.ELSE
	MOV		EDI,	EAX									;restore EDX
	INC		EDX											;go to the next list string element
.ENDIF	
	JMP 	SUBSRCH										;jump subsrch

MATCH:	
	INC	ECX												;increment match counter
.IF		ECX == 1
	CALL	Crlf										;call Crlf, go to the next line
	mWrite	"Matches found: "							;display match msg
	CALL	Crlf										;call Crlf, go to the next line
.ENDIF
	MOV		EDX,	(ListNode PTR [ESI]).nodeData		;move N.nodeData into EDX
	CALL	WriteString									;Write the string to the console
	CALL	Crlf										;go to the next line
NEXT:
	MOV		EBX,	(ListNode PTR [ESI]).NextPtr		;move the next node address into EBX
	MOV		ESI,	EBX									;move the net address into ESI
	CMP		ESI,	OFFSET lListTail					;compare EBX to 0
	JE		RETURN										;jump if equal
	JMP START											;jump to start
	
RETURN:	
	mWrite 	"End of search."							;write ending search message to console
QUIT:
.IF		ECX == 0
	mWrite	"No matches were found."					;write no matches found msg to console
.ENDIF
	CALL	Crlf										;call Crlf, go to the next line
	
	RET
substringSearch		ENDP



;---------------------------------------------------------------------------------------
saveListToFile		PROC		USES	ESI	EAX	EBX	ECX	EDX	
;
;		This procedure saves every string in the list into an output file named 'Save.txt'.
;	After all items have been saved a message will output how many bytes were saved into 
;	the file.  This procedure completely overwrites the current Save.txt and all of its
;	contents.
;
;	Receives:	Nothing
;	Returns:	Nothing
;---------------------------------------------------------------------------------------
	MOV		ESI,	pListHead							;ESI == N
	
.IF		ESI == OFFSET lListTail
	mWrite "The list is empty."							;display console message
	JMP		QUIT										;jump to QUIT
.ENDIF	

	INVOKE 	CreateFile,	ADDR strSaveFile, GENERIC_WRITE, DO_NOT_SHARE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0

.IF		EAX == INVALID_HANDLE_VALUE
	mWrite "Error occured while opening file."			;write the error msg to the console
	JMP		QUIT
.ELSE
	mWrite "Opened file 'Save.txt'."					;write the success msg to the console
	CALL 	Crlf										;call Crlf, go to the next line
	MOV		hFileHandle,	EAX							;move the file handle to memory
.ENDIF

	MOV		EAX,	0									;clear EAX
	MOV		dBytesWritten, EAX							;clear dBytesWritten
	PUSH	0											;push 0 for the loop
WRITE:
	CMP		DWORD PTR (ListNode PTR [ESI]).dPosition, 0	;compare N.dPosition to 0
	JE		RETURN										;jump to RETURN if equal
	MOV		EDX,	(ListNode PTR [ESI]).nodeData		;move the node data into EDX
	PUSH	ESI											;push ESI onto the stack
	MOV		ESI,	EDX									;move EDX into ESI for getCount
	CALL	getCount									;call getCount, result is in ECX
	
	POP		ESI											;restore ESI
	
	;EDX = pointer to string, ECX = # of bytes to write to file, EAX = number of bytes written after execution
	INVOKE 	WriteFile, hFileHandle, EDX, ECX, addr dBytesWritten, 0 
	
	MOV		EBX, 	(ListNode PTR [ESI]).NextPtr		;move the next address into EBX
	MOV		ESI,	EBX									;move the next address into ESI ; ESI = n
	POP		EBX											;restore EBX   
	ADD		EBX,	dBytesWritten						;add bytes written to EBX
	PUSH	EBX											;push EBX
	JMP		WRITE										;jump to WRITE

RETURN:
	;close the file referenced by the handle hFileHandle
	INVOKE 	CloseHandle, hFileHandle					
	
	POP		EBX											;restore EBX
	MOV		EAX, 	EBX									;move EBX into EAX for WriteDec
	CALL	WriteDec									;call WriteDec, display EAXs value to the console
	mWrite	" bytes were written to the file."			;display the written bytes msg to the console
	
QUIT:	
	RET
saveListToFile		ENDP



;---------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------



;---------------------------------------------------------------------------------------

end main												;end of main

































