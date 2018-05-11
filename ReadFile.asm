.386
.model flat,stdcall
option casemap:none

include     \masm32\include\windows.inc
include     \masm32\include\kernel32.inc
include     \masm32\include\user32.inc
include     \masm32\include\masm32.inc

includelib  \masm32\lib\kernel32.lib
includelib  \masm32\lib\user32.lib
includelib  \masm32\lib\masm32.lib

parseBufferToNode PROTO

.data

FileName    db 'input.txt',0     ; file to read

.data?

hFile       dd ?
FileSize    dd ?
hMem        dd ?
BytesRead   dd ?

.code

readFile PROC

    invoke  CreateFile,ADDR FileName,GENERIC_READ,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0            

    mov     hFile,eax

    invoke  GetFileSize,eax,0
	
    mov     FileSize,eax
    inc     eax

    invoke  GlobalAlloc,GMEM_FIXED,eax
    mov     hMem,eax

    add     eax,FileSize

    mov     BYTE PTR [eax],0   ; Set the last byte to NULL so that StdOut
                               ; can safely display the text in memory.

    invoke  ReadFile,hFile,hMem,FileSize,ADDR BytesRead,0
	
	mov esi, hMem
	
	invoke parseBufferToNode

    invoke  CloseHandle,hFile

    invoke  StdOut,hMem

    invoke  GlobalFree,hMem

    RET

readFile ENDP

END
