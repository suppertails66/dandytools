
;========================================
; basic stuff
;========================================

.psx

.fixloaddelay

;=======================
; include auto-generated index files
;=======================

.include "out/include/roboselect_overlaygrp.inc"

;========================================
; old functions
;========================================

  ;=====
  ; main
  ;=====

  decmpFontChar equ 0x80016A78
  sendCharToGpu equ 0x8001DDC0
  queueSubPacFileLoad equ 0x8003B914
  free equ 0x80030528

  ;=====
  ; ADV
  ;=====

  ; a0 = gpu dst line sub?
  ; a1 = gpu dst line num?
  ; a2 = value
  renderNumber equ 0x80075498
  
  ; a0 = ?
  ; a1 = num cells?
  createCharTransferQueue equ 0x80073CF0
  
  destroyCharTransferQueue equ 0x80074E6C

;========================================
; defines
;========================================

;getGlyphIndex equ 0x0208cb88
;allocHeapMem equ 0x02008a18

newStaticCodeSize equ 0x1000
newHeapEndAddress equ 0x801FE000-newStaticCodeSize
newStaticCodeStartAddress equ newHeapEndAddress

scriptExecStruct equ 0x80055E60
  scriptExecStruct_curTextOffset equ 0x98

printStruct equ 0x80059608
  printStruct_cellX equ 0x4
  printStruct_cellY equ 0x5
  
  ;===============================
  ; vwf composition consts
  ;===============================
  
  ; 2bpp 16x16 texture
  ; 4 bytes per line
  vwfCompositionBufferByteWidth equ 4
  vwfCompositionBufferPixelWidth equ 16
  vwfCompositionBufferLineHeight equ 16
  ; 16 lines per 16x16 texture
  vwfCompositionBufferByteSize equ vwfCompositionBufferByteWidth*vwfCompositionBufferLineHeight
  vwfCompositionBufferBothByteSize equ vwfCompositionBufferByteSize*2
  ; number of bytes we must add to a given position in the buffer
  ; to find the pixel immediately below it (in the full 32x16 buffer)
  vwfCompositionBufferLineSeparation equ vwfCompositionBufferByteWidth*2
  
  ; original font has 16 2bpp 16x16 chars per line
  oldFontDataCharByteWidth equ 4
  oldFontDataCharLineHeight equ 16
  oldFontDataCharsPerLine equ 16
  oldFontDataLineSeparation equ oldFontDataCharByteWidth*oldFontDataCharsPerLine
  ; number of bytes in one complete row of font data (1024)
  oldFontDataFullRowSize equ oldFontDataCharByteWidth*oldFontDataCharLineHeight*oldFontDataCharsPerLine
  
  ; pointer to start of font graphic (including 0x40-byte header)
  oldFontDataPointer equ 0x8005AC38
  oldFontDataHeaderSize equ 0x40
  
  ; number of characters in font graphic reserved for original font.
  ; the remainder is used for VWF composition.
  numOldFontReservedChars equ 0xB0
  
  ; starting index of characters in font reserved for misc string composition
  startingMiscStringCompIndex equ numOldFontReservedChars+0x30
  
  ; start of control op in original string
  ; (ASCII '\')
  oldStringControlOpStartChar equ 0x5C
  oldStringTerminatorChar equ 0x00
 
  ; oh wonderful, they used index 1 as "transparent" instead of 0.
  ; which means a simple OR won't work for compositing.
  ; fuck.
  ; well, i guess the worst we'll have to do is fix any unset
  ; nybbles on the final buffer send?
  fontBgColorByte equ 0xAA
  fontBgColorWord equ 0xAAAAAAAA

;========================================
; reduce the size of the heap.
; this enables us to use the space
; between the heap and the stack for
; new always-loaded code.
;========================================
  
  .open "out/asm/SINKOU.S3M", 0x80060A60
  .org 0x800617A0
  ;  lui $a1,hi(newHeapEndAddress)
  ;  ori $a1,$a1,lo(newHeapEndAddress)
    li $a1,newHeapEndAddress
  .close
  
  ; actually, looking more closely, the other code places
  ; the heap end at 0x801EE000, out of the range of our code.
  ; so what's this larger gap between the heap and stack used for?
  ; something seems to use the 0x801FE000+ range; more static variables??
  ; is 1FD000+ safe?
  
;  .open "out/asm/GAME.XM", 0x80060A60
;  .org 0x80060F94
;    li $a1,newHeapEndAddress
;  .close

;========================================
; test
;========================================
  
.open "out/asm/SLPS_022.43", 0x8000F800
; size field in exe header
.org 0x8000F800+0x1C
;  .word 0x1EE000-0x800
  .word 0x1EE000

/*; halve character spacing
;.org 0x80016230
;  sll $v0, $v1, 3-1
.org 0x8001622C
  sll $t0, $v1, 4-1

; double characters per line
.org 0x800168F4
  sltiu $v0, $v0, 0x000F*2

; gpu transfer x halve?
.org 0x800180C4
  sll $s0, $s0, 2-1

; gpu transfer w halve?
;.org 0x800180DC
;  addiu $v0, $zero, 0x0004/2 */

  ;============================================================================
  ; modifications
  ;============================================================================
  
  ; transfer width/height of textures in dlog display queue (-1?)
  .org 0x80015708
    addiu $t7, $zero, 0x000F+1

  ; no auto-linewrap
  .org 0x800168F4
;    sltiu $v0, $v0, 0x000F
    ; set X check value arbitrarily high so it won't pass
    sltiu $v0, $v0, 0x0FFF

  ; when advancing through a string that is to be printed to find where
  ; it ends, go one byte at a time, not two
  .org 0x80014F9C
    addiu $v0, $a2, 0x0002-1
  
  ; same as above for op 2c (messageInMenus):
  ; go one byte at a time, not two
  .org 0x80015080
    addiu $v0, $a0, 0x0002-1
  
  ; and again when skipping over text in a conditional block
  .org 0x80013828
    addiu $v0, $a0, 0x0002-1
    
  ; do not return nonzero from handleNextTextChar after a print
  ; (because prints are now done from our queue, and returning
  ; nonzero signals to advance 2 bytes in the input past what
  ; is assumed to be a 2-byte sequence of some sort)
;  .org 0x800168DC
;;    addiu $v0, $v0, 0x0001
;    addiu $v0, $v0, 0x0000

  ; when reading control code parameters from a script,
  ; the original game continues adding digits until it encounters a
  ; byte that is not an ASCII digit (0x30-0x39).
  ; however, we are now using a one-byte encoding where several characters
  ; conflict with this range, causing them to also get ignored.
  ; and as i write this it occurs to me to just move some of the characters
  ; from the alternate narrow font that will never(?) be used with such
  ; sequences into this range, meaning no code changes are required.
  ; well, if this ever becomes necessary, the relevant code is at 8001813C.

  ;============================================================================
  ; calls to new code
  ;============================================================================

  
  ;=========================================
  ; assign a char to the current char gpu slot
  ; and increment the slot.
  ; 
  ; returns:
  ; s0 = target gpu x
  ; s1 = target gpu y
  ;=========================================

  .org 0x800180C0
    j assignNextCharGpuSlot
    ; !! next instruction will get executed as a slot here,
    ;    but it doesn't matter and we'll need it later, so it stays
    
  .org 0x800168C4
    j preDlogDisplayXYLoad
    nop
  
  ; check for queue override
  .org 0x80016870
    j checkForVwfQueueOverride
    nop
  
  ; check for queue activation
  .org 0x80016880
    j checkForVwfQueueActivation
    nop
  
  ; use new x/y positions when generating dlog display queue
  .org 0x80016220
    j doNewDlogDisplayQueuePositioning
    nop
  
  ; newline reset
  .org 0x80016698
    j doVwfNewlineReset
    ; !! this replaces an old jump, so take the old slot instruction
  
  ; box clear reset
  .org 0x80016544
    j doVwfClearReset
    ; !! this replaces an old jump, so take the old slot instruction
  
  ; never return "0" to indicate a 2b input sequence has been handled
  ; and needs to be skipped after printing text
  .org 0x800168DC
    j doNoZeroRetAfterTextPrint
    nop
  
  ; do extra initialization in messageInMenus
  .org 0x80015044
    j extraMessageInMenusInit
    nop
  
  ; do extra initialization in dlog
  .org 0x80014FFC
    j extraDlogInit
    nop

  ;============================================================================
  ; NEW STUFF
  ;============================================================================
;.area 0x1000
  .org 0x801FD000
  ;  .ascii "test"
  
  ;=========================================
  ; for dlog op, reset vwf
  ; before starting new message
  ;=========================================
  
  extraDlogInit:
    ; trash something on the stack so we can save ra
    sw $ra,0($sp)
  
    ; queue off
    la $v0,vwfQueueActive
    ; reset positioning data
    jal resetVwfForLine
;    nop
    sb $zero,0($v0)
    
    ; make up work
    lw $ra,0($sp)
    nop
    jr $ra
    addiu $sp, $sp, 0x0008
  
  ;=========================================
  ; for messageInMenus op, reset vwf
  ; before starting new message
  ;=========================================
  
  extraMessageInMenusInit:
    ; queue off
    la $v0,vwfQueueActive
    ; reset positioning data
    jal resetVwfForLine
;    nop
    sb $zero,0($v0)
    
    ; make up work
    lui $v1, 0x8005
    addiu $v1, $v1, 0x5E60
    j 0x8001504C
    nop
  
  ;=========================================
  ; 
  ;=========================================
  
  doNoZeroRetAfterTextPrint:
    ; make up work
    addiu $v0, $v0, 0x0001
    sb $v0, 0x0004($s0)
;    lui $v0, 0x8006
;    addiu $a1, $v0, 0x9608
;    lbu $v0, 0x0004($a1)
    
    ; return nonzero = no input skip
    j 0x80016938
    li $v0,1
  
  ;=========================================
  ; reset vwf stuff when needed
  ;=========================================
  
  doVwfNewlineReset:
    jal resetVwfForLine
    nop
    
    j 0x800168E4
    nop
  
  doVwfClearReset:
    jal resetVwfForLine
    nop
    
    ; return zero
    j 0x80016938
    move $v0, $zero
  
  ;=========================================
  ; when generating entries for dlog display
  ; queue, use new vwf parameters
  ;=========================================
  
  doNewDlogDisplayQueuePositioning:
    ; a1 = srcCellY * 16
    ; this is used for the src address and should be kept.
    sll $a1, $v0, 4
    
    ; however, we need the dstY, not the srcY this function now uses.
    ; a3 = raw cell dstY
    lbu $a3, 0x80059608+printStruct_cellY
    nop
    ; multiply by 16
    sll $a3, 4
    ; add 0xA4 to get true target
    addiu $a3, 0x00A4
    
    ; now compute t0 = srcX
    andi $v1, $a0, 0xFFFF
    sll $t0, $v1, 4
    
    ; now compute v0 = putX
    la $v1,vwfPutX
    lhu $v0,0($v1)
    nop
    ; increment putX and write back to src
    addiu $t2,$v0,vwfCompositionBufferPixelWidth
    
    j 0x8001623C
    sh $t2,0($v1)
  
  ;=========================================
  ; check if vwf queue active
  ; and replace normal printing operations
  ; with it if so
  ;=========================================
  
  checkForVwfQueueOverride:
    ; make up work
;    andi $v0, $v0, 0x00FF
    
    ; the game relies on a few no-parameter control sequences (e.g. \t)
    ; being ignored by simply doing nothing and letting them be treated
    ; as ascii, which in the stock game is just skipped over.
    ; we are no longer ignoring ascii characters, so we need to filter
    ; for these cases.
    ; at entry, v0 = next character in the stream - 0x21
    ; if v0 == 0x3B (i.e. 5C, ascii '\'), this is a 2b control sequence.
    andi $v0, $v0, 0x00FF
    li $v1, 0x3B
    bne $v0, $v1, @@notBackslash
    lui $a0, 0x8005
      ; increment srcpos
      addiu $a0, $a0, 0x5E60
      lw $v1, 0x0098($a0)
      addiu $v0, $zero, 0x0002
      addu $v1, $v1, $v0
      sw $v1, 0x0098($a0)
      ; return nonzero!
      j 0x80016938
      li $v0, 0x0001
    @@notBackslash:
  
  checkForVwfQueueOverride_sub:
    
    ; if queue active, print from it
    lbu $v1,vwfQueueActive
    nop
    bne $v1,$zero,printNextVwfCell
    nop
;    j 0x80016878
;    sltiu $v0, $v0, 0x005E
    
    ; wait, we don't even need to make up the work here.
    ; the game was originally checking if the next symbol was < 0x80
    ; so it could tell whether it was a codepoint or not.
    ; we don't care and just treat everything as a codepoint.
    j 0x80016880
    nop
  
  printNextVwfCell:
    ; fetch next queue entry
    ; a0 = pointer to queue pointer
    la $a0,vwfTransferQueuePutPtr
    ; v0 = queue pointer
    lw $v0,0($a0)
    nop
    
    ; write back incremented queue pointer
    addiu $v1,$v0,1
    sw $v1,0($a0)
    
    ; v1 = entry index
    lbu $v1,0($v0)
    nop
    
    ; if entry is zero, we're done
    bne $v1,$zero,@@queueNotDone
    nop
      ; turn off queue
      la $v1,vwfQueueActive
      sb $zero,0($v1)
      
      ; suppress the next printing delay
      ; v0 = timerCurrent
      la $v0,0x80055E60+0xA0
      ; set to an arbitrarily high value that will definitely
      ; be higher than the trigger value for the next frame
      li $t0,0xFF
      sh $t0,0($v0)
      
      ; update getpos to saved value
      lw $v1,vwfOldStringResumePtr
      ; t1 = current text offset from script start
      la $t0,scriptExecStruct
      lw $t1,scriptExecStruct_curTextOffset($t0)
      nop
      ; add offset to src
      addu $t1,$v1
      ; subtract 2 because the caller will
      ; add 2 when this function returns nonzero
      ; (assuming the old behavior where 1 codepoint = 2 bytes)
;      addiu $t1,-2
      ; save src
      sw $t1,scriptExecStruct_curTextOffset($t0)
      
      ; return value = 1 (not handled, do not advance past "codepoint")
      j 0x80016938
      li $v0,1
    @@queueNotDone:
    
    ; if this entry or the next one is null, we're done.
    ; (it should always be the next one, unless the queue was generated
    ; completely empty -- not sure if that can actually happen.)
    ; set things up so that the next string content will print "immediately".
    ; note that there is actually a delay of 1 frame (usually accompanied
    ; by another delay as the game processes an upcoming command sequence)
/*    lbu $v1,0($v0)
    lbu $v0,1($v0)
    beq $v1,$zero,@@nextIsZero
    nop
    bne $v0,$zero,@@nextIsNonzero
;    lbu $v1,0($v0)
;    bne $v1,$zero,@@nextIsNonzero
    @@nextIsZero:
    ; suppress next "character's" timer delay
    ; v0 = timerCurrent
    la $v0,0x80055E60+0xA0
      ; set to an arbitrarily high value that will definitely
      ; be higher than the trigger value for the next frame
      li $t0,0xFF
      sh $t0,0($v0)
      
      ; turn off queue
      la $v0,vwfQueueActive
      sb $zero,0($v0)
      
      ; update getpos to saved value
      lw $v0,vwfOldStringResumePtr
      ; t1 = current text offset from script start
      la $t0,scriptExecStruct
      lw $t1,scriptExecStruct_curTextOffset($t0)
      nop
      ; add offset to src
      addu $t1,$v0
      ; subtract 2 because the caller will
      ; add 2 when this function returns nonzero
      ; (assuming the old behavior where 1 codepoint = 2 bytes)
;      addiu $t1,-2
      ; save src
      sw $t1,scriptExecStruct_curTextOffset($t0)
    @@nextIsNonzero: */
    
    ; set registers up for the normal print function
    ; v0 = simulated codepoint
    addiu $v0,$v1,1
    addiu $v0,0x8000
    andi $v0,0xFFFF
    j 0x800168A8
    nop
  
  ;=========================================
  ; check if vwf queue needs to be activated
  ;=========================================
  
  checkForVwfQueueActivation:
    ; do not activate queue if already active
    lbu $a0,vwfQueueActive
    nop
    bne $a0,$zero,@@done
    nop
    
      ; if this triggered at all, we encountered a new-font codepoint.
      ; trigger string rendering
      ; a0 = src
      jal renderDlogVwfString
      move $a0,$s1
      
      ; immediately handle initial content!
      j checkForVwfQueueOverride_sub
      nop
    
    @@done:
    ; return value = nonzero (not handled)
    j 0x80016938
;    li $v0,1
    li $v0,1
  
  ;=========================================
  ; assign a char to the current char gpu slot
  ; and increment the slot.
  ; 
  ; returns:
  ; s0 = target gpu x
  ; s1 = target gpu y
  ;=========================================
  
  currentCharGpuSlot:
    .db 0x00
  currentCharGpuSlotX:
    .db 0x00
  currentCharGpuSlotY:
    .db 0x00
  
  .align 4
  assignNextCharGpuSlot:
    ; make up work
    ; (doesn't matter)
;    andi $s0, 0xFFFF
    
    ;===============
    ; load and update slot index
    ;===============
    
    ; v0 = address of slot index
    la $v0,currentCharGpuSlot
    ; v1 = slot index
    lbu $v1,0($v0)
    nop
    ; ++slotindex
    addiu $v1,0x0001
    ; wrap at 45
    sltiu $t0,$v1,45
    bne $t0,$zero,@@noWrap
    nop
      li $v1,0
    @@noWrap:
    ; write back next index to memory
    sb $v1,0($v0)
    
    ;===============
    ; compute target x/y
    ;===============
    
    ; target Y is index/15, target X is index%15
    
    ; x
    move $s0,$v1
    ; y
    li $s1,0
    
    ; subtract 15 from X until it underflows, adding 1 to Y if it doesn't
    li $v0,15
    @@loop:
      subu $s0,$v0
      slti $v1,$s0,0
      bne $v1,$zero,@@done
      nop
      
      ; increment Y
      addiu $s1,1
      
      b @@loop
      nop
    @@done:
    
    ; make up for final underflow
    addu $s0,$v0
    
    ; save values
    sb $s0,currentCharGpuSlotX
    sb $s1,currentCharGpuSlotY
    
    j 0x800180C4
    nop
  
  ;=========================================
  ; load a0/a1 with char slot x/y
  ;=========================================
  
  preDlogDisplayXYLoad:
    lbu $a0,currentCharGpuSlotX
    lbu $a1,currentCharGpuSlotY
    
    j 0x800168CC
    nop
  
  
  
  
  
  
  
  
  
  
  ;============================================================================
  ; vwf composition
  ;============================================================================
  
  ;=========================================
  ; the composition buffer is structured,
  ; conceptually, as one continuous 32x16px 2bpp texture.
  ; normally, only the left 16x16px area is actually
  ; operated on.
  ; however, when we "overflow" material into the
  ; right 16x16 area, the left half is copied out
  ; to the font area, the right 16x16 area is
  ; copied over it, and then the right area is cleared.
  ; composition then proceeds as normal on the
  ; left half.
  ;=========================================
  
  .align 4
  
  vwfVariablesStart:
  
  vwfCompositionBuffer:
    .fill vwfCompositionBufferBothByteSize, fontBgColorByte
  vwfCompositionBufferLeft equ vwfCompositionBuffer
  vwfCompositionBufferRight equ vwfCompositionBuffer+vwfCompositionBufferByteWidth
  
  .align 4
  ; pointer to current position in transfer queue
  vwfTransferQueuePutPtr:
    .dw vwfTransferQueue
  
  ; pointer to pending old string data to be handled
  ; after current transfer queue
  vwfOldStringResumePtr:
    .dw 0
  
  .align 4
  vwfPutXAndFinalX:
    ; the x-position, in pixels, at which the next VWF cell should go.
    ; incremented by 16 after each sell is sent.
    ; this is set to vwfFinalX at the start of each new VWF string.
    vwfPutX:
      .dh 0x00
    ; !!!!!!!! DO NOT INSERT ANYTHING HERE !!!!!!!!!!
    ;          optimized for word-length clear
    ; the final x-position, in pixels, on the current line after
    ; all VWF characters are sent
    vwfFinalX:
      .dh 0x00
  ; !!!!!!!! DO NOT INSERT ANYTHING HERE !!!!!!!!!!
  vwfBufferXAndvwfNextOldFontIndex:
    ; current pixel position within vwf buffer.
    ; should range from 0-15 inclusive.
    vwfBufferX:
      .db 0x00
    ; next index to assign from old font.
    ; reset to numOldFontReservedChars at start of new string.
    vwfNextOldFontIndex:
      .db numOldFontReservedChars
    ; nonzero if queue needs to be handled
    vwfQueueActive:
      .db 0x00
    ; here so we can copy the previous three values as a word
    vwfDummy:
      .db 0x00
  
  
  ;=========================================
  ; vwf transfer queue
  ;
  ; each byte represents a tile index within
  ; the font graphic's new VWF area.
  ; these are sent to the screen one at a
  ; time, in order.
  ;=========================================
  
  vwfTransferQueueTerminator equ 0x00
  
  ; maximum possible transfer is 45 texture indices + terminator
  vwfTransferQueueSize equ 45
  vwfTransferQueue:
    .fill vwfTransferQueueSize+1, 0x00
  
  ; secondary queue for e.g. numbers, label composition
  vwfMiscTransferQueueSize equ 32
  vwfMiscTransferQueue:
    .fill vwfMiscTransferQueueSize+1, 0x00
  
  ; table, 1 byte per char, giving advance width of each char
  fontWidthTable:
    .incbin "out/img/font_width.bin"
  
  ;=====
  ; renderDlogVwfString originally used a fixed queue
  ; and composition space.
  ; this proved insufficient for situations where e.g. a number needs
  ; to be rendered while dialogue is printing elsewhere.
  ; this block holds the new parameters, for the sake of not
  ; having to rewrite a bunch of function calls with confusing stack-based
  ; parameters.
  ;=====
  
  .align 4
  
  vwfRenderParams:
    ; pointer to start of target queue
    vwfRenderParams_queueBasePtr:
    .dw vwfTransferQueue
    offset_vwfRenderParams_queueBasePtr equ (vwfRenderParams_queueBasePtr - vwfRenderParams)
    ; pointer to queue-active byte
;    vwfRenderParams_queueBasePtr:
;    .dw 0
;    offset_vwfRenderParams_queueBasePtr equ (vwfRenderParams_queueBasePtr - vwfRenderParams)
    ; index number of first chracter in font space used to store
    ; composed text
    vwfRenderParams_initialTargetCellId:
    .db 0
    offset_vwfRenderParams_initialTargetCellId equ (vwfRenderParams_initialTargetCellId - vwfRenderParams)
  
  ;=========================================
  ; render dialogue-type vwf string
  ;
  ; $a0 = string pointer
  ;=========================================
  
  .align 4
  
  renderDlogVwfString:
    ; set up parameters
    la $v0,vwfRenderParams
    la $v1,vwfTransferQueue
    sw $v1,offset_vwfRenderParams_queueBasePtr($v0)
    li $v1,numOldFontReservedChars
    sb $v1,offset_vwfRenderParams_initialTargetCellId($v0)
    
    j renderVwfString_sub
    nop
  
  ;=========================================
  ; render misc-type vwf string
  ;
  ; $a0 = string pointer
  ;
  ; returns v0 = vwfOldStringResumePtr for
  ; the given string
  ;=========================================
  
  .align 4
  
  renderMiscVwfString:
    ; save params
    addiu $sp,-24
    sw $ra,0($sp)
    sw $a0,4($sp)
    ; this may get called while the main queue is active and
    ; already in use, so all relevant static variables are
    ; saved and restored before calling the renderer:
    ;   - vwfTransferQueuePutPtr
    ;   - vwfOldStringResumePtr
    ;   - vwfPutXAndFinalX
    ;   - vwfBufferXAndvwfNextOldFontIndex
    ;   - vwfQueueActive
    la $v0,vwfVariablesStart
    lw $v1,(vwfTransferQueuePutPtr-vwfVariablesStart)($v0)
    lw $a1,(vwfOldStringResumePtr-vwfVariablesStart)($v0)
    sw $v1,8(sp)
    lw $v1,(vwfPutXAndFinalX-vwfVariablesStart)($v0)
    sw $a1,12(sp)
    lw $a1,(vwfBufferXAndvwfNextOldFontIndex-vwfVariablesStart)($v0)
    sw $v1,16(sp)
    sw $a1,20(sp)
    
      
      ; set up parameters
      la $v0,vwfRenderParams
      la $v1,vwfMiscTransferQueue
      sw $v1,offset_vwfRenderParams_queueBasePtr($v0)
      li $v1,startingMiscStringCompIndex
      sb $v1,offset_vwfRenderParams_initialTargetCellId($v0)
      
      ; reset positioning data
      jal resetVwfForLine
      nop
      
      ; retrieve string pointer
      lw $a0,4($sp)
      
      ; render string
      jal renderVwfString_sub
      nop
      
      ; a0 = final vwfOldStringResumePtr
      lw $a0,vwfOldStringResumePtr
    
    ; restore params
    lw $ra,0($sp)
    ; other
    lw $v1,8($sp)
    la $v0,vwfVariablesStart
    lw $a1,12($sp)
    sw $v1,(vwfTransferQueuePutPtr-vwfVariablesStart)($v0)
    lw $v1,16($sp)
    sw $a1,(vwfOldStringResumePtr-vwfVariablesStart)($v0)
    lw $a1,20($sp)
    sw $v1,(vwfPutXAndFinalX-vwfVariablesStart)($v0)
    sw $a1,(vwfBufferXAndvwfNextOldFontIndex-vwfVariablesStart)($v0)
    
    ; return final vwfOldStringResumePtr
    move $v0,$a0
    
    jr $ra
    addiu $sp,24
  
  ;=========================================
  ; render vwf string
  ;
  ; $a0 = string pointer
  ;=========================================
  
  .align 4
  
  renderVwfString_sub:
    ; save params
    addiu $sp,-12
    sw $ra,0($sp)
    sw $s0,4($sp)
    sw $s1,8($sp)
    
      ; s0 = string pointer (updated)
      move $s0,$a0
      ; s1 = string pointer (original)
      move $s1,$a0
      
      ;=======
      ; init
      ;=======
      
      ; reset vwf buffer
      jal clearVwfCompositionBuffer
      nop
      
      ; set vwfPutX to vwfFinalX
      lhu $v0,vwfFinalX
      sh $v0,vwfPutX
      
      ; reset bufferX and nextOldFontIndex
      la $v0,vwfBufferXAndvwfNextOldFontIndex
      sb $zero,0($v0)
;      li $v1,numOldFontReservedChars
;      sb $v1,1($v0)
      la $v1,vwfRenderParams
      lbu $a0,offset_vwfRenderParams_initialTargetCellId($v1)
      nop
      sb $a0,1($v0)
      
      ; reset queue putpos
;      la $v1,vwfRenderParams_queueBasePtr
;      lw $v1,0($v1)
      lw $a0,offset_vwfRenderParams_queueBasePtr($v1)
      la $v0,vwfTransferQueuePutPtr
      sw $a0,0($v0)
      
      ;=======
      ; render
      ;=======
      
      @@loop:
        ; fetch next byte
        lbu $a0,0($s0)
        ; stop when a control op or terminator is reached
        beq $a0,oldStringControlOpStartChar,@@done
        nop
        beq $a0,oldStringTerminatorChar,@@done
        nop
        
        ; render char
        ; move to next char in src string
        jal renderVwfChar
        addiu $s0,1
        
        b @@loop
        nop
      @@done:
      
      ;=======
      ; finish up
      ;=======
      
      ; send final buffer if it has content in it
      ; (vwfBufferX > 0)
      lbu $v0,vwfBufferX
      nop
      beq $v0,$zero,@@noFinalBufferSend
      nop
        jal queueAndSwapActiveBuffer
        nop
      @@noFinalBufferSend:
      
      ; add queue terminator
      la $v0,vwfTransferQueuePutPtr
      lw $v1,0($v0)
      nop
      sb $zero,0($v1)
      
      ; save resume offset
      subu $s0,$s1
      sw $s0,vwfOldStringResumePtr
      
      ; mark queue as active
      la $v0,vwfQueueActive
      li $v1,1
      sb $v1,0($v0)
      
      ; reset queue putpos (now used as getpos)
      la $v1,vwfRenderParams
      lw $a0,offset_vwfRenderParams_queueBasePtr($v1)
;      la $v0,vwfTransferQueue
;      sw $v1,vwfTransferQueuePutPtr
      la $v0,vwfTransferQueuePutPtr
      sw $a0,0($v0)
    
    ; restore params
    lw $ra,0($sp)
    lw $s0,4($sp)
    lw $s1,8($sp)
    
    jr $ra
    addiu $sp,12
  
  ;=========================================
  ; clear contents of vwf buffers
  ;=========================================
  
  clearVwfCompositionBuffer:
    la $v0,vwfCompositionBuffer
    li $v1,vwfCompositionBufferBothByteSize/4
    li $t0,fontBgColorWord
    
    @@loop:
      sw $t0,0($v0)
      addiu $v0,4
      subiu $v1,1
      bne $v1,$zero,@@loop
      nop
    
    jr $ra
    nop
  
  ;=========================================
  ; render new vwf char
  ;
  ; $a0 = char index
  ;=========================================
  
  renderVwfChar:
    ; save params
    addiu $sp,-12
    sw $ra,0($sp)
    sw $s0,4($sp)
    sw $s1,8($sp)
      
      ; s0 = char index
      ; v0 = pointer to codepoint's graphic
      jal getOldFontCharPointer
      move $s0,$a0
      
      ; t0 = pointer to codepoint's graphic
      move $t0,$v0
      
      ;=====
      ; composite left.
      ; shift right by vwfBufferX*2 bits,
      ; then OR with each line (word) of left buffer.
      ;=====
      
      ; t2 = shift amount
      lbu $t2,vwfBufferX
      ; t1 = dst = left buffer
      la $t1,vwfCompositionBufferLeft
      ; multiply shift amount by 2
      sll $t2,1
      ; t3 = counter
      move $t3,$zero
      ; t5 = mask
      li $t5,0xFFFFFFFF
      srlv $t5,$t2
      nor $t5,$t5
      
      @@compositeLeftLoop:
        ; v1 = fetch line from src
        lw $v1,0($v0)
        ; t4 = fetch line from dst
        lw $t4,0($t1)
        
        ; shift src line right by amount
        srlv $v1,$t2
        ; AND with mask to clear pixels to be replaced
        and $t4,$t5
        ; OR with dst
        or $v1,$t4
        ; write back to dst
        sw $v1,0($t1)
        
        ; advance src
        addiu $v0,oldFontDataLineSeparation
        
        ; loop
        ; advance dst
        addiu $t3,1
        bne $t3,vwfCompositionBufferLineHeight,@@compositeLeftLoop
        addiu $t1,vwfCompositionBufferLineSeparation
      
      ;=====
      ; composite right.
      ; shift left by -vwfBufferX*2 bits,
      ; then OR with each line (word) of right buffer.
      ;=====
      
      ; v0 = pointer to codepoint's graphic
      move $v0,$t0
      
      ; t2 = shift amount
      lbu $t2,vwfBufferX
      nop
      ; nothing to do if bufferX is zero (no spillover into right buffer)
      beq $t2,$zero,@@noRightComposite
      nop
        ; t1 = dst = right buffer
        la $t1,vwfCompositionBufferRight
        ; subtract 16 from shift amount to get left shift (negative)
;        addiu $t2,-16
        li $t3,16
        subu $t2,$t3,$t2
        ; multiply shift amount by 2
        sll $t2,1
        ; t3 = counter
        move $t3,$zero
        ; t5 = mask
        li $t5,0xFFFFFFFF
        sllv $t5,$t2
        nor $t5,$t5
        
        @@compositeRightLoop:
          ; v1 = fetch line from src
          lw $v1,0($v0)
          ; t4 = dst
          lw $t4,0($t1)
          
          ; shift src line left by amount
          sllv $v1,$t2
          ; advance src
          addiu $v0,oldFontDataLineSeparation
          
          ; mask off non-preserved bits from dst
          and $t4,$t5
          ; OR with src
          or $v1,$t4
          
          ; write to dst
          sw $v1,0($t1)
          
          ; loop
          ; advance dst
          addiu $t3,1
          bne $t3,vwfCompositionBufferLineHeight,@@compositeRightLoop
          addiu $t1,vwfCompositionBufferLineSeparation
      @@noRightComposite:
      
      ;=====
      ; update x positions
      ;=====
      
      ; look up character's width from table
      la $v1,fontWidthTable
      ; add codepoint
      addu $v1,$s0
      ; v0 = advance width
      lbu $v0,0($v1)
      
      ; update vwfFinalX
      
      ; v1 = pointer to vwfFinalX
      la $v1,vwfFinalX
      ; t0 = vwfFinalX
      lhu $t0,0($v1)
      nop
      ; add width to vwfFinalX
      addu $t0,$v0
      ; save updated vwfFinalX
      sh $t0,0($v1)
      
      ; update vwfBufferX
      
      ; v1 = pointer to vwfBufferX
      la $v1,vwfBufferX
      ; t0 = vwfBufferX
      lbu $t0,0($v1)
      nop
      ; add width to vwfBufferX
      addu $t0,$v0
      
      ;=====
      ; if updated vwfBufferX >= 16,
      ; send active buffer
      ;=====
      
      sltiu $t1,$t0,vwfCompositionBufferPixelWidth
      bne $t1,$zero,@@noBufferSend
      nop
        ; s1 = vwfBufferX pointer
        move $s1,$v1
        
        ; s0 = overflowed vwfBufferX
        ; send pending buffer
        jal queueAndSwapActiveBuffer
        move $s0,$t0
        
        ; subtract 16 from x to get new position
        addiu $s0,-vwfCompositionBufferPixelWidth
        
        ; move to expected reg for final update
        move $t0,$s0
        move $v1,$s1
      @@noBufferSend:
      
      ; save updated vwfBufferX
      sb $t0,0($v1)
    
    ; restore params
    lw $ra,0($sp)
    lw $s0,4($sp)
    lw $s1,8($sp)
    
    jr $ra
    addiu $sp,12
  
  ;=========================================
  ; send current vwf buffer to font
  ; and add queue entry for it.
  ; also copy right buffer to left buffer
  ; and clear right buffer.
  ;=========================================
  
  queueAndSwapActiveBuffer:
    ; save params
    addiu $sp,-4
    sw $ra,0($sp)
    
      ;=====
      ; look up next putpoint
      ;=====
      
      ; v0 = next index pointer
      la $v0,vwfNextOldFontIndex
      ; a0 = current vwf put codepoint
      lbu $a0,0($v0)
      nop
      ; v1 = putpoint+1
      addiu $v1,$a0,1
      ; write updated putpoint
      sb $v1,0($v0)
      
      ;=====
      ; write queue entry
      ;=====
      
      ; v0 = pointer to current transfer queue pointer
      la $v0,vwfTransferQueuePutPtr
      nop
      ; v1 = queue pointer
      lw $v1,0($v0)
      nop
      ; write new index to queue
      sb $a0,0($v1)
      ; increment queueptr
      addiu $v1,1
      ; save updated queueptr
      sw $v1,0($v0)
      
      ;=====
      ; look up copy target
      ;=====
      
      ; v0 = pointer to target graphic buffer
      jal getOldFontCharPointer
      nop
      
      ; t2 = pointer to target graphic buffer
      move $t2,$v0
      
      
      ;=====
      ; copy left buffer to target
      ;=====
      
      ; v1 = left buffer pointer
      li $v1,vwfCompositionBufferLeft
      ; t0 = counter
      move $t0,$zero
      
      @@leftBufCopyLoop:
        
        ; the game expects data for each row to consist of
        ; two little-endian halfwords with reversed halfnybble
        ; ordering compared to what we used to compose
        ; the buffers.
        ; do this conversion and write out the results.
        
        ; read first halfword from src
        lhu $a0,2($v1)
        ; convert
        jal doBitmapDataConversion_inline
        nop
        ; write to output
        sh $v0,0($t2)
        
        ; read second halfword from src
        lhu $a0,0($v1)
        ; convert
        jal doBitmapDataConversion_inline
        nop
        ; write to output
        sh $v0,2($t2)
        
        ; endianness must be reversed ("corrected")
        ; for final output.
/*;        lw $t1,0($v1)
        sw $t1,0($v1)
        lbu $t1,0($v1)
        
        lbu $t2,1($v1)
        sll $t1,8
        or $t1,$t2
        
        lbu $t2,2($v1)
        sll $t1,8
        or $t1,$t2
        
        lbu $t2,3($v1)
        sll $t1,8
        or $t1,$t2 */
        
        ; advance a line in src
        addiu $v1,vwfCompositionBufferLineSeparation
        
        ; copy to dst
        ; advance a line in dst
;        sw $t1,0($t2)
        addiu $t2,oldFontDataLineSeparation
        
        ; loop
        addiu $t0,1
        bne $t0,vwfCompositionBufferLineHeight,@@leftBufCopyLoop
        nop
      
      ;=====
      ; copy right buffer to left buffer,
      ; clearing right buffer in the process
      ;=====
      
      ; v0 = left buffer pointer
      li $v0,vwfCompositionBufferLeft
      ; v1 = right buffer pointer
      li $v1,vwfCompositionBufferRight
      ; t0 = counter
      move $t0,$zero
      
      @@rightBufCopyLoop:
        ; read word from src
        lw $t1,0($v1)
        ; t2 = clear word
        li $t2,fontBgColorWord
        
        ; clear old src word
        sw $t2,0($v1)
        
        ; advance a line in src
        addiu $v1,vwfCompositionBufferLineSeparation
        
        ; copy to dst
        ; advance a line in dst
        sw $t1,0($v0)
        addiu $v0,vwfCompositionBufferLineSeparation
        
        ; loop
        addiu $t0,1
        bne $t0,vwfCompositionBufferLineHeight,@@rightBufCopyLoop
        nop
    
    ; restore params
    lw $ra,0($sp)
    nop
    
    jr $ra
    addiu $sp,4
  
  ;=========================================
  ; convert from "left-to-right" halfword
  ; representation of a bitmap to regular
  ; game format
  ;
  ; a0 = input halfword
  ; note: does not dirty registers except v0
  ;=========================================
  
  doBitmapDataConversion_inline:
    ; save params
    addiu $sp,-8
    sw $v1,0($sp)
    sw $t0,4($sp)
    
      ; result
      li $v0,0
      ; counter
      li $t0,8
      
      @@loop:
        ; shift output left 2 bits
        sll $v0,2
        
        ; v1 = low 2 bits of input
        andi $v1,$a0,0x3
        ; OR to output
        or $v0,$v1
        
        ; loop
        ; shift input right 2 bits
        addiu $t0,-1
        bne $t0,$zero,@@loop
        srl $a0,2
      
      ; reverse endianness of output
;      andi $v1,$v0,0x00FF
;      sll $v1,8
;      srl $v0,8
;      or $v0,$v1
    
    ; restore params
    lw $v1,0($sp)
    lw $t0,4($sp)
    nop
    
    jr $ra
    addiu $sp,8
  
  ;=========================================
  ; return pointer to the graphic for a
  ; given codepoint within the old font data
  ;
  ; $a0 = codepoint
  ; 
  ; returns $v0 = pointer to graphic
  ;=========================================
  
  getOldFontCharPointer:
    
    ;=====
    ; compute pointer to source character within font data.
    ; formula: ((codepoint >> 4) * oldFontDataFullRowSize)
    ;            + ((codepoint & 0x0F) * oldFontDataCharByteWidth)
    ;            + *oldFontDataPointer
    ;            + oldFontDataHeaderSize
    ;=====
    
    ; v0 = codepoint >> 4
    move $v0,$a0
    srl $v0,4
    ; multiply by oldFontDataFullRowSize, which is 1024,
    ; i.e. left shift by 10
    sll $v0,10
    
    ; v1 = codepoint & 0x0F
    move $v1,$a0
    andi $v1,0xF
    ; multiply by oldFontDataCharByteWidth, which is 4,
    ; i.e. left shift by 2
    sll $v1,2
    
    ; v0 = target offset in raw graphic data
    addu $v0,$v1
    
    ; fetch font data pointer
    la $v1,oldFontDataPointer
    lw $v1,0($v1)
    nop
    ; add size of header
    addiu $v1,oldFontDataHeaderSize
    
    ; add graphic pointer to computed offset to get final result
    addu $v0,$v1
    
    jr $ra
    nop
  
  ;=========================================
  ; reset vwf for new line
  ;=========================================
  
  .align 4
  
  resetVwfForLine:
    ; reset putX and finalX
    la $v0,vwfPutXAndFinalX
    sw $zero,0($v0)
    ; reset bufferX and nextOldFontIndex
    sb $zero,4($v0)
;    li $v1,numOldFontReservedChars
;    sb $v1,5($v0)
    la $v1,vwfRenderParams
    lb $v1,offset_vwfRenderParams_initialTargetCellId($v1)
    nop
    sb $v1,5($v0)
    
    jr $ra
    nop
  
  ;=========================================
  ; reset vwf for new box
  ;=========================================
  
;  resetVwfForBox:
;    ; do normal line reset
;    jal resetVwfForLine
;    nop
;    
;    jr $ra
;    nop
  
  ;=========================================
  ; overflow
  ;=========================================
  
  newCharSequenceToVramOverflow:
      ;=====
      ; decompress
      ;=====
      
      jal decmpFontChar
      nop
      
      ;=====
      ; set up gpu transfer
      ;=====
      
      ; a0 = dstinfo struct stack pointer
      addiu $a0, $sp, 0x0010
      ; a1 = srcptr
      addu $a1, $s0, $zero
      
      ; set up dstbase
      addiu $v0, $s3, 0x0140
      sh $v0, 0x0010($sp)
      ; set up dstoffset
      addiu $v0, $s6, 0x0100
      sh $v0, 0x0012($sp)
      ; set up transfer width
      addiu $v0, $zero, 0x0004
      sh $v0, 0x0014($sp)
      ; set up transfer height
      addiu $v0, $zero, 0x0010
      
      ;=====
      ; transfer to gpu
      ;=====
      
      jal sendCharToGpu
      sh $v0, 0x0016($sp)
      
      ;=====
      ; do follow-up stuff
      ;=====
      
      ; update decompression array dstindex
      ; v0 = current index
      lhu $v0, 0($s1)
      ; v1 = index at which to wrap to zero
      lhu $v1, 0x000C($fp)
      ; increment index
      addiu $v0, $v0, 0x0001
      sh $v0, 0($s1)
      ; wrap at specified limit
      andi $v0, $v0, 0xFFFF
      sltu $v0, $v0, $v1
      bne $v0, $zero, @@something
      nop
        sh $zero, 0($s1)
      @@something:
      
      ; dstbase += 4
      j newCharSequenceToVramOverflowDone
      addiu $s3, $s3, 0x0004
  
    
;   ;=========================================
;   ; when sending digits to GPU for e.g.
;   ; file select screen, the game does a
;   ; raw copy from the font to the screen.
;   ; however, we are storing the font with
;   ; a different format for convenience of
;   ; VWF composition, so the characters will
;   ; be corrupted if left as-is.
;   ;
;   ; to compensate, we instead copy the
;   ; target character to the unused space
;   ; for font character 00 (which cannot be
;   ; printed, as it's the string terminator),
;   ; convert it to the output format, then
;   ; send that to the GPU.
;   ;=========================================
;   
;   ; from 80075A88
;   
;   setUpDigitConversion:
; ;     ; save params
; ;     addiu $sp,-4
; ;     sw $ra,0($sp)
; ;     
; ;       
; ;     
; ;     ; restore params
; ;     lw $ra,0($sp)
; ;     nop
; ;     jr $ra
; ;     addiu $sp,4
; ;   
; ;     ; restore params
; ; ;    lw $ra,0($sp)
; ; ;    nop
; 
;     ; input:
;     ; a0 = codepoint
;     
;     ; use "null" codepoint (0x8000) as src instead of target one
;     move $v0,0x8000
;     ; look up graphic from old codepoint
;     jal getOldFontCharPointer
;     sh $v0,0x18($sp)
;     ; now, v0 = pointer to src codepoint's graphic
;     
;     
;     ; make up work
;     addiu $a1, $sp, 0x0018
;     j 0x80075A90
;     lui $s1, 0x800A
  
  ;=========================================
  ; send 
  ;=========================================
  
  renderedNumberStringLength equ 10
  renderedNumberStringPaddingLength equ 2
  rawCharIdToCodepointOffset equ 0x8001
  maxRenderedNumberStringLength equ 13
  
  code_fwspace   equ 0xAA
  code_space6px  equ 0xAB
  code_space1px  equ 0xAC
  code_space14px equ 0xAD
  code_fwcomma   equ 0xAE
  code_space8px  equ 0xAF
  code_nothing   equ 0x5E
  code_space5px  equ 0x5D
  
  ; the original game sticks characters 14px apart,
  ; with each character occupying a 16px cell.
  ; however, we're now rendering numbers with the standard vwf
  ; printer, which does not do this 16px alignment.
  ; this means extra padding must be applied to the end of the
  ; queue to make sure we cover the full available space.
  ; additionally, we may or may not be reducing the spacing from
  ; 14px to something else to make things look nicer, which further
  ; necessitates pre-padding the string so the displayed number will
  ; end up right-aligned at the same position as the original.
  
  renderedNumberStringWithPrePadding:
    ; this padding should add up to the total width of the generated area
    ; (140 pixels) minus the maximum size of the string content.
    ; currently, the maximum-length string is 10 8-px digits plus 3
    ; 5-pixel commas = 95 pixels, so the pre-padding is 45 pixels.
    
;    .fill 1,code_space14px
;    .fill 1,code_space6px
;    .fill 1,code_space14px
;    .fill 1,code_space6px
;    .fill 1,code_space14px
;    .fill 1,code_space6px
    ; 36px
;    .fill 1,code_space14px
;    .fill 1,code_space14px
;    .fill 1,code_space8px
;    ; 9px
;    .fill 1,code_space8px
;    .fill 1,code_space1px
    ; 45px
    .fill 1,code_space14px
    .fill 1,code_space14px
    .fill 1,code_space8px
    .fill 1,code_space8px
    .fill 1,code_space1px
  renderedNumberStringCommaPadding:
    .fill 3,0x00
  renderedNumberString:
;    .fill renderedNumberStringLength,0x00
    .fill maxRenderedNumberStringLength,0x00
  renderedNumberStringPostPadding:
    ; difference between the "physical" width of this string in vram
    ; (160 pixels) and its "logical" width as displayed (140 pixels)
    ; = 20 pixels
    
    ; 20px
    .fill 1,code_space14px
    .fill 1,code_space6px
    ; terminator
    .fill 1,0x00
  
  ; pointer to current putpos in renderedNumberString
  .align 4
  renderedNumberStringPutPtr:
    .dw renderedNumberString
  
  .align 4
  resetRenderedNumberString:
    ; preserve a0 for makeup, everything else is fair game
    
    ; reset putptr
    li $v0,renderedNumberString
    sw $v0,renderedNumberStringPutPtr
    
    ; reset comma padding
;    la $v0,renderedNumberStringCommaPadding
;    li $v1,code_space8px
;    sb $v1,0($v0)
;    sb $v1,1($v0)
;    sb $v1,2($v0)
    
    ; make up work
    j 0x80075408
    nop
  
  ; a0 = codepoint
  ; a1 = ?
  ; a2 = dst??
  ; a3 = if nonzero, ???
  ; s1 = digit number.
  ;      0 = billions place, 9 = ones place
  sendCharToRenderedNumberString:
    ; v0 = convert from codepoint to raw index
    subiu $v0, $a0, rawCharIdToCodepointOffset
    ; get queue pointer
    la $v1,renderedNumberStringPutPtr
    ; a0 = queue pointer
    lw $a0,0($v1)
    andi $v0,0xFF
    ; write to new position
    sb $v0,0($a0)
    ; increment queue pointer
    addiu $a0,1
    
    ; figure out whether we need a comma here
    
    ; a1 = subtract 3 from digitnum repeatedly and see if we end up with zero
    ; a2 = index of target comma position (0-2)
    move $a1,$s1
    li $a2,-1
    @@commaCheckLoop:
      addiu $a2,1
      beq $a2,3,@@commaDone
      nop
      bne $a1,$zero,@@commaCheckLoop
      subiu $a1,3
      
      ; a1 = target comma padding position
      la $a1,renderedNumberStringCommaPadding
      ; we are at a comma position.
      ; was the character we wrote a space?
      ; if so, no comma needed
      bne $v0,code_fwspace,@@addComma
      addu $a1,$a2
      @@addNoComma:
        ; for comma pos
        li $a3,code_nothing
        ; for padding pos
        j @@commaPosDone
;        li $a2,code_space8px
        li $a2,code_space5px
      @@addComma:
        ; for comma pos
        li $a3,code_fwcomma
        ; for padding pos
        li $a2,code_nothing
      
      @@commaPosDone:
      ; write target char to comma pos
      sb $a3,0($a0)
      ; write target char to padding pos
      sb $a2,0($a1)
      
      ; increment queue pointer
      addiu $a0,1
      
    @@commaDone:
    
    ; write back queue pointer
    sw $a0,0($v1)
    
    ; make up work
    jr $ra
    nop
    
  ; s0 = "dst", needs to be incremented by 4 after each transfer
  ; s1 = free
  ; s2 = free
  ; s3 = free
  ; s4 = ? used as parameter
  sendRenderedNumberStringToGpu:
    ; reset positioning data
;    jal resetVwfForLine
;    nop
    
    ; print the number string
    la $a0,renderedNumberStringWithPrePadding
;    jal renderDlogVwfString
    jal renderMiscVwfString
    nop
    
    ; reset positioning data
;    jal resetVwfForLine
;    nop
    
    ; queue off
;    sb $r0,vwfQueueActive
    
    ; s1 = queue getpos
;    lw $s1,vwfTransferQueuePutPtr
;    nop
    la $s1,vwfMiscTransferQueue
    ; v0 = next queue value
    lbu $v0,0($s1)
    nop
    
    ; NOTE: we do not check for an empty queue
    ; (it should never be empty at this point)
    
    @@loop:
      ; prepare parameters to gpu transfer function
      ; a0 = char id
      addiu $a0,$v0,rawCharIdToCodepointOffset
      andi $a0,0xFFFF
      ; a1 = "dst"?
      andi $a1,$s0,0xFFFF
      ; a2 = ?
      andi $a2,$s4,0xFFFF
      
      ; transfer to gpu
      jal 0x80075A50
      ; a3 = 0
      move $a3,$r0
      
      ; increment "dst"
      addiu $s0,4
      
      ; increment getpos
      addiu $s1,1
      ; fetch next value
      lbu $v0,0($s1)
      nop
      ; done if terminator
      bne $v0,$zero,@@loop
      nop
    
    
    ; make up work
    lw $ra, 0x0024($sp)
    j 0x80075540
    lw $s4, 0x0020($sp)
  
;  roboselect_halveBudgetLabelWidth:
;    ; width
;    li $a1,0x0010003C
;    j 0x80064F28
;    sw $a1, 0x0014($a3)

  doExtraRoboSelectInit:
    ; max number of strings that can be displayed?
    ; (we aren't displaying any, but make it nonzero just in case)
    li $a0,1
    jal createCharTransferQueue
    ; max number of cells that can be transferred at once??
    ; (we're only ever doing one at a time)
    li $a1,30
    
    ; make up work
    j 0x80061E44
    lw $ra, 0x0030($sp)
  
  doExtraRoboSelectCleanup:
    jal destroyCharTransferQueue
    nop
    
    ; free subtitle file
    la $a1,roboSelect_subtitleFilePointer
    lw $a0,0($a1)
    nop
    beq $a0,$zero,@@isNull
    sw $zero,0($a1)
      jal free
      nop
    @@isNull:
    
    ; make up work
    j 0x80063BCC
    lw $ra, 0x001C($sp)
  
  checkForExtraCharTexPalettes:
    beq $v1, $v0, @@is2
    li $v0, 3
    beq $v1, $v0, @@is3
    li $v0,0x01
    
    ; something else: don't care
    j 0x80073B74
    nop
    
    @@is2:
    ; make up work
    j 0x80073B60
    addiu $v0, $zero, 0x00FF
    
    @@is3:
    ; load "near-black" palette
    sb $v0,-3($s0)
    j 0x80073B70
    sb $v0,-2($s0)
;    sb $v0,-1($s0)

  cancelAdvSpecialCharDummyPrints:
    j 0x80075B08
    sh $zero, 0xB54C($v0)
  
;.endarea

/*  displayTest:
    ; make up work
    jal 0x8003B4A4
    nop
    
    ; display
    
    addiu $sp, -0x20
      ; 1b slot -> a0
      ; 1b ? -> a1
      ; 1b cell count -> a2
      ; 2b x -> a3
      ; 2b y -> sp+0x10
      ; 1b srcLo -> sp+0x14
      ; 1b srcHi -> sp+0x18
      ; 1b palette -> sp+0x1C
      
      ; slot
      li $a0, 0
      ; ?
      li $a1, 0
      ; cell count
      li $a2, 16
      ; x
      li $a3, 0x20
      ; y
      li $v0, 0x20
      sw $v0, 0x10($sp)
      ; srcLo
      li $v0, 0
      sw $v0, 0x14($sp)
      ; srcHi
      li $v0, 0xA0
      sw $v0, 0x18($sp)
      ; palette
      li $v0, 1
      sw $v0, 0x1C($sp)
      
      ; vramSeqToScreen
      jal 0x800752E4
      nop
    addiu $sp, 0x20
    
    ; charBufsOn
    jal 0x80074DFC
    nop
    
    j 0x80064674
    nop */
  
;  displayTest2:
;    ; draw char bufs...
;;    lui $v0,0x8009
;;    lw $a0, 0xF810($v0)
;;    jal 0x8007397C
;;    nop
;    
;    jal 0x80064E00
;    addiu $a0, $zero, 0x0001
;    
;    j 0x800648FC
;    lw $ra, 0x002C($sp)
  
  ;=========================================
  ; robot select/deployment: subtitles
  ;=========================================

  ;=====
  ; memory
  ;=====
  
  .align 4
  
  roboSelect_sub_struct:
    ; pointer to current position in current subtitle stream
    roboSelect_subStreamPtr:
      .dw 0
    ; subtitle delay timer
    roboSelect_subDelayTimer:
      .dw 0
    ; position and size of subtitles
    roboSelect_subSrcHi:
      .dh 0
    roboSelect_subX:
      .dh 0
    roboSelect_subY:
      .dh 0
    roboSelect_subW:
      .dh 0
    roboSelect_subH:
      .dh 0
    ; are subtitles active?
    roboSelect_subActive:
      .db 0
  
  .align 4

  ;=====
  ; start a subtitle sequence
  ;
  ; a0 = pointer to start of subtitle script stream
  ;=====
  
  roboSelect_initSubSeq:
    la $a1,roboSelect_sub_struct
    ; reset stream pos
    sw $a0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a1)
    ; reset delay timer
    sw $zero,(roboSelect_subDelayTimer-roboSelect_sub_struct)($a1)
    ; reset subs active
    sb $zero,(roboSelect_subActive-roboSelect_sub_struct)($a1)
    
    jr $ra
    nop

  ;=====
  ; subtitle update routine.
  ; call once per engine iteration for as long as
  ; subtitle sequence is active.
  ;=====
  
  roboSelect_updateSubs:
    addiu $sp,-8
    sw $ra,0($sp)
    sw $s0,4($sp)

      ;=====
      ; update subtitle stream
      ;=====
    
      la $a0,roboSelect_sub_struct
      
      ; ensure stream not null
      lw $s0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a0)
      nop
      beq $s0,$zero,@@subStreamCheckDone
      nop
    
      ; check delay timer
;      la $a0,roboSelect_sub_struct
      lw $v0,(roboSelect_subDelayTimer-roboSelect_sub_struct)($a0)
      nop
      
      ; if delay timer is nonzero, decrement and do nothing
      beq $v0,$zero,@@checkNextCmd
      addiu $v0,-1
        j @@subStreamCheckDone
        sw $v0,(roboSelect_subDelayTimer-roboSelect_sub_struct)($a0)
      @@checkNextCmd:
      
      ; s0 = pointer to stream data
;      lw $s0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a0)
      @@interpreterLoop:
        la $a0,roboSelect_sub_struct
        lw $s0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a0)
        nop
        
        ; v0 = fetch command byte from stream
        lbu $v0,0($s0)
        nop
        
        ; increment script pointer
        addiu $s0,1
        ; write back to src
;        sw $s0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a0)
        
        ; zero = stream terminator
        bne $v0,$zero,@@notTerminator
        ; decrement command id
        addiu $v0,-1
          j @@subStreamCheckDone
          ; nullify stream pointer
          sw $zero,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a0)
        @@notTerminator:
        
        ; call handler from jump table
        sll $v0,2
        la $a1,roboSelect_subScriptJumpTable
        addu $v0,$a1
        lw $v0,0($v0)
        nop
        jalr $v0,$ra
        move $a0,$s0
        
        ; if handler returns nonzero, break
        beq $v0,$zero,@@interpreterLoop
        nop
        
    
      @@subStreamCheckDone:

      ;=====
      ; draw active subtitles
      ;=====
      
      la $a0,roboSelect_sub_struct
      
      lbu $v0,(roboSelect_subActive-roboSelect_sub_struct)($a0)
      nop
      beq $v0,$zero,@@subDrawDone
      nop
      
        ; get buffer selector bit
        lw $a2,(0x8008ED4C)
        nop
        lw $v1,0x130($a2)
    ;      nop
;        la $a1,0x8008ED58
        ; dstbase
        la $a1,(0x8008947C)
        ; reduce to low bit only
        andi $v1, 0x1
        
        ; multiply by 72 to get target slot offset
        sll $v0, $v1, 3
        addu $v0,$v1
        sll $v0,3
        
        ; a0 = base writepos
        addu $a1,$v0
        
        ; sequence:
        ; +00: XX XX XX 09: size + link
        ; +04: E1 00 02 1F: texpage
        ;              - x-base = 0xF
        ;              - y-base = 1
        ;              - semitransparency 0
        ;              - 4-bit color
        ; drop shadow
        ; +08: - 64 80 80 80: Textured Rectangle, variable size, opaque, texture-blending
        ; +12: - YY YY+1 XX XX+1: vertex (screen x/y pos)
        ; +16: - 7B 3A srchi 40: palette + src y/x
        ; +20: - hh hh ww ww: src h+y
        ; foreground
        ; +24: - 64 80 80 80: Textured Rectangle, variable size, opaque, texture-blending
        ; +28: - YY YY XX XX: vertex (screen x/y pos)
        ; +32: - 43 FC srchi 40: palette + src y/x
        ; +36: - hh hh ww ww: src h+y
        
        ; a3 = pointer to link table base
        lw $a3, 0x0100($a2)
        nop
        ; v0 = last link.
        ; note that using the last link rather than the second-to-last
        ; gives subtitles priority over fade effects.
        lw $v0,0($a3)
        ; OR with size of new link
        lui $v1,0x0900
        or $v0,$v1
        ; add to new link
        sw $v0,0($a1)
        
        ; link old position to new
        ; mask off high byte of pointer
        li $v1,0xFFFFFF
        and $v1,$a1
        ; write to last link position
        sw $v1,0($a3)
        
        ; write texpage command
        li $v0,0xE100021F
        sw $v0,4($a1)
        
        ; write rect command
        li $v0,0x64808080
        sw $v0,24($a1)
        ; drop shadow
        sw $v0,8($a1)
        
        ; write vertex command
        lhu $v1,(roboSelect_subY-roboSelect_sub_struct)($a0)
        lhu $v0,(roboSelect_subX-roboSelect_sub_struct)($a0)
        sll $v1,16
        or $v0,$v1
        sw $v0,28($a1)
        ; drop shadow
        ; offset x/y by 1
        li $v1,0x00010001
        addu $v0,$v1
        sw $v0,12($a1)
        
        ; write palette + src command
        lhu $v0,(roboSelect_subSrcHi-roboSelect_sub_struct)($a0)
        lui $v1,0x43FC  ; 87800 + 780 = 87F80
;        lui $v1,((0x01EC<<6)|(0x3A0>>4))  ; f6740
;        lui $v1,((0x01E0<<6)|(0x3C0>>4))  ; f0780
        sll $v0,8
        or $v1,$v0
        ; test
;        ori $v0,0x40
        sw $v1,32($a1)
        ; drop shadow
        lui $v1,((0x01EC<<6)|(0x3A0>>4))  ; f6740
        or $v1,$v0
        sw $v1,16($a1)
        
        ; write src h+w command
        lhu $v1,(roboSelect_subH-roboSelect_sub_struct)($a0)
        lhu $v0,(roboSelect_subW-roboSelect_sub_struct)($a0)
        sll $v1,16
        or $v0,$v1
        sw $v0,36($a1)
        ; drop shadow
        sw $v0,20($a1)
        
        ; add texwindow reset command
        jal roboSelect_injectOverlayTexWinReset
        nop
      
      @@subDrawDone:
    
    lw $ra,0($sp)
    lw $s0,4($sp)
    addiu $sp,8
    jr $ra
    nop

  ;=========================================
  ; robo select subtitle script commands
  ;=========================================
  
  ; jump table
  roboSelect_subScriptJumpTable:
    ; 01 = delay
    .dw roboSelect_subScript_delay
    ; 02
    .dw roboSelect_subScript_sendString
    ; 03
    .dw roboSelect_subScript_showSub
    ; 04
    .dw roboSelect_subScript_hideSub

  ;=====
  ; delay
  ;
  ; a0 = script pointer
  ;=====
    
  roboSelect_subScript_delay:
    la $a1,roboSelect_sub_struct
    
    ; v1 = fetch word-length param (big-endian) from stream
    lbu $v1,0($a0)
    nop
    sll $v1,8
    lbu $v0,1($a0)
    nop
    or $v1,$v0
    
    ; set delay timer
    ; subtract 1 to get correct initial timer value
    addiu $v1,-1
    sw $v1,(roboSelect_subDelayTimer-roboSelect_sub_struct)($a1)
    
    ; save updated stream pos
    addiu $a0,2
    sw $a0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a1)
    
    ; return nonzero (break interpreter loop)
    jr $ra
    li $v0,1

  ;=====
  ; send vwf string to vram
  ;
  ; a0 = script pointer
  ;=====
    
  roboSelect_subScript_sendString:
    addiu sp,-16
    sw $ra,0($sp)
    sw $s0,4($sp)
    sw $s1,8($sp)
    sw $s2,12($sp)
    
      move $s0,$a0
;      la $a1,roboSelect_sub_struct
      
      ; s1 = param 0 = dst low
      lbu $s1,0($s0)
      addiu $s0,1
      
      ; s2 = param 1 = dst high
      lbu $s2,0($s0)
      addiu $s0,1
      
      ; print vwf string
      jal renderMiscVwfString
      move $a0,$s0
      
      ; save updated stream pos using returned size of string
      addu $s0,$v0
      addiu $s0,1
      sw $s0,roboSelect_subStreamPtr
      
      ; send to the target gpu position
      la $s0,vwfMiscTransferQueue
      ; v0 = next queue value
      lbu $v0,0($s0)
      ; target correct vram area
      ori $s1,0x0A00
      srl $s1,2
      @@loop:
        ; prepare parameters to gpu transfer function
        ; a0 = char id
        addiu $a0,$v0,rawCharIdToCodepointOffset
        andi $a0,0xFFFF
        ; a1 = dst low
        andi $a1,$s1,0xFFFF
        ; a2 = dst high
        andi $a2,$s2,0xFFFF
        
        ; transfer to gpu
        jal 0x80075A50
        ; a3 = 0
        move $a3,$r0
        
        ; increment dst low
        addiu $s1,4
        
        ; increment getpos
        addiu $s0,1
        ; fetch next value
        lbu $v0,0($s0)
        nop
        ; done if terminator
        bne $v0,$zero,@@loop
        nop
    
    lw $ra,0($sp)
    lw $s0,4($sp)
    lw $s1,8($sp)
    lw $s2,12($sp)
    addiu $sp,16
    jr $ra
    ; return zero (continue processing)
    move $v0,$zero

  ;=====
  ; show a subtitle block
  ;
  ; a0 = script pointer
  ;=====
    
  roboSelect_subScript_showSub:
    la $a1,roboSelect_sub_struct
    
    ; params: srchi x y w h
    
    lbu $v0,0($a0)
    lbu $v1,1($a0)
    sh $v0,(roboSelect_subSrcHi-roboSelect_sub_struct)($a1)
    lbu $v0,2($a0)
    sh $v1,(roboSelect_subX-roboSelect_sub_struct)($a1)
    lbu $v1,3($a0)
    sh $v0,(roboSelect_subY-roboSelect_sub_struct)($a1)
    lbu $v0,4($a0)
    ; we want to allow a width of 256, so treat zero as that.
    ; H is maxed at 255.
    bne $v1,$zero,@@wNotZero
    nop
      li $v1,0x100
    @@wNotZero:
    sh $v1,(roboSelect_subW-roboSelect_sub_struct)($a1)
    sh $v0,(roboSelect_subH-roboSelect_sub_struct)($a1)
    
    ; update streamptr
    addiu $a0,5
    sw $a0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a1)
    
    ; flag subs active
    li $v0,1
    sb $v0,roboSelect_subActive
    
    jr $ra
    ; return zero (continue processing)
    move $v0,$zero

  ;=====
  ; hide subtitles
  ;
  ; a0 = script pointer
  ;=====
    
  roboSelect_subScript_hideSub:
    la $a1,roboSelect_sub_struct
    ; disable sub
    sb $zero,(roboSelect_subActive-roboSelect_sub_struct)($a1)
    ; save updated streamptr
    sw $a0,(roboSelect_subStreamPtr-roboSelect_sub_struct)($a1)
    
    jr $ra
    ; return zero (continue processing)
    move $v0,$zero
    
  
  testSubData:
    ; delay: 64 steps (note: this is counting in 20fps frames)
    .db 0x01,0x00,0x40
    ; send subtitles...
    ; dstlow  = 0x00
    ; dsthigh = 0xA0
    ; content = "01234"
    .db 0x02,0x00,0xA0,0x01,0x02,0x03,0x04,0x05,0x06,0x7,0x8,0x9,0xA,0xB,0xC,0xD,0xE,0xF,0x00
    .db 0x02,0x00,0xB0,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x00
    ; show sub
    ;   cmd  src  x  y  w   h
    .db 0x03,0xA0,32,32,256,32
    ; delay: 256 steps
    .db 0x01,0x01,0x00
    ; hide sub
    .db 0x04
    ; terminator
    .db 0x00
  .align 4

  ;=====
  ; injects a texture window reset command before the
  ; third-to-last link the gpu rendering list
  ; on the robot select/deployment screen
  ;=====
  
  roboSelect_injectOverlayTexWinReset:
    ; fetch "buffer slot" target bit.
    ; the game alternates between front/back buffers for all drawing
    ; operations; bit 0 of this word determines which we are currently on.
    lw $a2,(0x8008ED4C)
    nop
    lw $v1,0x130($a2)
;      nop
    la $a0,0x8008ED58
    ; reduce to low bit only
    andi $v1, 0x1
    ; multiply by 12
    sll $v0,$v1,1
    addu $v0,$v1
    sll $v0,2
    ; a0 = add 0x8008ED58 to derive pointer to target slot
    addu $a0,$v0
    
    ; write the command content.
    ; this is simply:
    ; E2000000 (no texture window)
    ; 00000000 (nop, for timing?)
    li $v0,0xE2000000
    sw $v0, 4($a0)
    sw $r0, 8($a0)
    
    ; insert this new data into the gpu render linked list.
    ; get pointer to end of linked list table
    lw $a1,0x100($a2)
    nop
    ; fetch the third-to-last entry
    lw $v0,8($a1)
    ; OR with 02000000 (size = 2 words)
    ; to form the link field for our new command
    li $v1,0x02000000
    or $v0,$v1
    ; save to our command
    sw $v0, 0($a0)
    ; change source link to low 24 bits of address of our new command
    li $v1,0x00FFFFFF
    and $v1,$a0
    
    jr $ra
    sw $v1,8($a1)
  
  roboSelect_doSubUpdate_generic:
    addiu $sp,-4
    sw $ra,0($sp)
    
      ; do update
      jal roboSelect_updateSubs
      nop
      
      ; make up work
      ; draw?
      jal 0x80063104
      nop
    
    lw $ra,0($sp)
    nop
    jr $ra
    addiu $sp,4
  
  roboSelect_triggerDeploymentSubs:
    ; make up work
    jal 0x8003B4A4
    move $a0,$t1
    
    ; test
;    la $a0,testSubData
;    jal roboSelect_initSubSeq
;    nop
    
    ; test
    lw $a1,roboSelect_subtitleFilePointer
    nop
    
    ; v0 = selected robot index
    lw $a0,0x8008ED4C
    nop
    lw $v0,0x0504($a0)
    ; v1 = target map index
    lw $v1,0x04B8($a0)
    ; convert robot index to file offset
    ; (*8)
    sll $v0,3
    
    ; if target map == 3, use short version of sequence
    li $a0,3
    bne $v1,$a0,@@notMap3
    nop
      ; target next script index
      addiu $v0,4
    @@notMap3:
    
    ; add to base pointer
    addu $a0,$a1,$v0
    ; fetch offset
    lw $v0,0($a0)
    ; add to file start to get script data pointer
    jal roboSelect_initSubSeq
    addu $a0,$a1,$v0
    
    j 0x80064674
    nop
  
  roboSelect_subtitleFilePointer:
    .dw 0
  
  roboSelect_loadSubtitleFile:
    ; load ADV/3/15, a new file containing the subtitle data
    jal queueSubPacFileLoad
    li $a2,15
    
    ; save the (future) position of this file for our use
    sw $v0,roboSelect_subtitleFilePointer
    
    ; make up work
    move $a0,$s1
    move $a1,$s0
    jal queueSubPacFileLoad
    li $a2,0xA
    j 0x80062C08
    nop 
    
  loadExtraRoboSelectGrp:
    ; make up work
    jal 0x80012F4C
    nop
    
    ; load new "graphic" containing pure-black palette
    lw $a0, 0x001C($sp)
    ; oops, this results in a displacement greater than 0x8000,
    ; so we have to to it the long way
    li $v0,roboSelectOverlayGrpPack_file12
    jal 0x80012F4C
;    addiu $a0,roboSelectOverlayGrpPack_file12
    addu $a0,$v0
    
    j 0x80062BB8
    nop
  
;  roboSelect_doSubUpdate_state2:
;    ; do update
;    jal roboSelect_updateSubs
;    nop
;    
;    ; make up work
;    ; draw?
;    jal 0x80063104
;    nop
;    
;    ; done
;    j 0x800648DC
;    nop
  
/*  displayTest2:
    ; add overlays
    jal 0x80064E00
    addiu $a0, $zero, 0x0001
    
    ; inject texture window reset
    jal roboSelect_injectOverlayTexWinReset
    nop
    
    ; make up work
    ; draw?
    jal 0x80063104
    nop
    
    ; done
    j 0x800648DC
    nop */
  
;  debugcredits:
;    lui $v0, 0x8007
;    li $v1,1
;    j 0x80062DB4
;    sw $v1, 0x4430($v0)

  ;============================================================================
  ; pad to end of sector
  ;============================================================================
  
  .align 0x800
  
.close




;============================================================================
; deployment subtitles
;============================================================================

; .create "out/asm/roboselect_subs.bin"
;   .dw 
;   
;   .loadtable 
;   robosubs_vordanDeployFull:
;     
;   
; .close


;============================================================================
; ADV.STM hacks
;============================================================================
  
.open "out/asm/ADV.STM", 0x80060A60

  ;============================================================================
  ; modifications
  ;============================================================================
  
;  .org 0x80075AB0
;    nop
  
  
;  .org 0x80073B5C
;    addiu $v0, $zero, 0x0001
;    sb $v0, 0xFFFD($s0)
;    addiu $v0, $zero, 0x0001
;    sb $v0, 0xFFFE($s0)
;    addiu $v0, $zero, 0x0001
;    sb $v0, 0xFFFF($s0)

  ; extra palettes for char textures
  .org 0x80073B58
    j checkForExtraCharTexPalettes
    nop
  
  
  ; uggh.
  ; when the game is initializing the stuff from e.g. initCharTexBufs,
  ; it calls the character print routine with param a3 as 1.
  ; this causes it to reset the destination slot index to zero.
  ; other params are dummy (0).
  ; however, the occurrence of a reset does not prevent the character
  ; transfer from occurring, and it proceeds to print codepoint 0000
  ; to gpu destination 0,0.
  ; my best guess is that this is a bug (forgot a return statement
  ; at the end of the if block for the reset?) that happened not to
  ; cause any problems in any of the original game's contexts.
  ; but now, we're using it in such a way that this will corrupt
  ; a small number of textures on the robot select screen if left as-is.
  ; so this modification causes the dummy print to get skipped, merely
  ; doing the reset instead before returning.
  ; in short: i have nooooo idea
  .org 0x80075A80
    j cancelAdvSpecialCharDummyPrints
    lui $v0, 0x8009
  
  
  ; spacing between 16x16 cells comprising a string displayed via
  ; vramSeqToScreen: 16, not 14
  .org 0x80073BA0
    addiu $s3, $s3, 0x000E+2
  
  ; spacing between 16x16 cells for vramSeqToScreen with relative
  ; positioning(?): 16
  .org 0x800734B8
    addiu $s2, $s2, 0x000E+2
  
  ; size of 16x16 cells for vramSeqToScreen with absolute positioning(?):
  ; 16, not 15
  .org 0x80073DA4
    addiu $a3, $zero, 0x000F+1
  
  ; spacing of cells for setTopMenuLabel/opCD, slot 0
  .org 0x80072A80
    addiu $a1, $a1, 0x000E+2
  
  ; spacing of cells for setTopMenuLabel/opCD, slot 1
  .org 0x80072BE4
    addiu $a1, $a1, 0x000E+2
  
  ; spacing of cells for topmenu, e.g. publicity budget label
  .org 0x80072B48
    addiu $a1, $a1, 0x000E+2
  
  
  
  ; TODO: this "corrects" the calculation of the width of the highlight for
  ; (scrolling?) menus from the original 14px spacing to 16px.
  ; however, this causes visual issues and will need a more complex
  ; hack
;  .org 0x800733D0
;    nop
  
  ; correct width of highlight for... some menus.
  ; non-scrolling ones only?
;  .org 0x80073AB4
;    nop


  
  ; when converting digits for display with standard font,
  ; use correct base codepoint
  .org 0x80075508
;    addiu $a0, $a0, 0x8001
    addiu $a0, $a0, 0x80A0+1
  
  ; when converting digits for display with standard font,
  ; use correct codepoint for space character
  .org 0x80075514
;    ori $a0, $zero, 0x800B
    ori $a0, $zero, 0x80AA+1
  
  
  
  ; when rendering numbers for display, do digit queue reset
  .org 0x800754BC
    jal resetRenderedNumberString
  
  ; send digit characters to new queue
  .org 0x80075520
    jal sendCharToRenderedNumberString
  
  ; send queue once filled
  .org 0x80075538
    j sendRenderedNumberStringToGpu
    nop
  
  ; when initially prepping number queue, leave dst params constant.
  ; they will now be incremented when the final queue is sent instead.
  .org 0x80075534
    nop
    
  ;=====
  ; damage report screen character spacing
  ;=====
  
  ; damage report screen: character spacing 14->16
  ; for category labels
  .org 0x80081484
    addiu $a2, $a2, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for "torino defense force co., ltd"
  .org 0x800820B8
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ? (probably "report no."
  .org 0x8008218C
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x800823E4
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x80082554
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x800828AC
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x80082998
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x80082E50
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x80083258
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x80083764
    addiu $a3, $a3, 0x000E+2
  
  ; damage report screen: character spacing 14->16
  ; for ?
  .org 0x80083764
    addiu $a3, $a3, 0x000E+2
    
  
  
  ; base x-pos of text for scrolling menu on file select screens
  
  ; saving?
;  .org 0x8007AB10
;    addiu $a0, $zero, 0x0010+12
;  ; do not copy this register
;  .org 0x8007AB18
;    addiu $a2, $zero, 0x0010
;    
;  ; loading?
;  .org 0x8007ABD0
;    addiu $a0, $zero, 0x0010+12
;  ; do not copy this register
;  .org 0x8007ABD8
;    addiu $a2, $zero, 0x0010
  
    
  ;=====
  ; damage report screen positioning
  ;=====
  
  ; damage report screen:
  ; hardcoded x-position of "financial report" label
  .org 0x800820E4
    addiu $a3, $zero, 214-5
  
  ; damage report screen:
  ; hardcoded x-position of first digit of report number
  .org 0x80082220
;    addiu $v1, $zero, 228+33
;    addiu $v1, $zero, 228+25
    addiu $v1, $zero, 228+65-5
  
  ; damage report screen:
  ; hardcoded x-position of second digit of report number
  .org 0x800822E4
;    addiu $v1, $zero, 242+32
;    addiu $v1, $zero, 228+33+6
;    addiu $v1, $zero, 228+25+6
    addiu $v1, $zero, 228+65-5+6
    
  ;=====
  ; yen unit changes
  ;=====
  
  ; the original game likes to express things using various units that
  ; are common in japanese but are odd and arbitrary in english, such as
  ; hundreds of millions or tens of thousands.
  ; this attempts to make these more consistent and comprehensible.
  ; helpfully, our narrower font allows for more digits to be displayed.
  
  ; display topwin budget as millions of yen instead of hundreds of millions
  .org 0x80072AC8
    j 0x80072AD4
    nop
  .org 0x80072AD4
    jal 0x80075498
    nop
  
  ; show equipment purchase prices as millions of yen
  .org 0x80079FCC
    nop
    nop
    nop
    jal 0x80075498
    nop
  
  ; save file funds as millions of yen: "reception"
  .org 0x8007B380
    nop
    nop
    nop
    jal 0x80075498
    nop
  
  ; save file funds as millions of yen: quicksave
  .org 0x8007B2D4
    nop
    nop
    nop
    jal 0x80075498
    nop
  
;  .org 0x800733E0
;    nop
    
  ;=========================================
  ; charSequenceToVram (op 5A)
  ;
  ; at this point:
  ;     
  ;     s2 = script struct ptr?
  ;            +0 = current srcoffset 
  ;     s3 = param1 (incremented after each send)
  ;     s4 = script base ptr?
  ;     s6 = param2 (static)
  ;=========================================
  
  ; change size of stack allocation
  .org 0x80073E74
  addiu $sp, $sp, -(0x48+4)
  .org 0x80073FF8
  addiu $sp, $sp, (0x48+4)
  
  .org 0x80073EEC
  .area 0xD0
    ; check that param string is not null?
    lbu $s5, 0x0000($v1)
    nop 
    beq $s5, $zero, 0x80073FBC
    ; s6 = param2
    addu $s6, $v0, $zero
    
    ;=====
    ; render string
    ;=====
    
    ; reset positioning data
;    jal resetVwfForLine
    move $s5,$v1
    
;    jal renderDlogVwfString
    jal renderMiscVwfString
    ; a0 = pointer to target string
    move $a0,$s5
    
    ;=====
    ; update script srcoffset
    ;=====
    
    ; update getpos to saved value
    lw $v1,0($s2)
    nop
    ; add offset (taken from the return value of renderMiscVwfString)
    ; to src
    addu $v0,$v1
    ; save src
    sw $v0,0($s2)
    
    ;=====
    ; send queue content to gpu
    ;=====
    
    ; stuff we have to access for various calls
    ; s2/s3/s4/s6 are already set
    la $s1,0x8008B54C
    la $s5,0x80099EF0
    la $s7,0x8005AAD8
    la $fp,0x80099EF0
    
    ; queue srcpos to stack (we made room for this earlier)
    la $v0,vwfMiscTransferQueue
    sw $v0,0x48($sp)
    
    newCharSequenceToVramLoop:
      
      ;=====
      ; fetch next byte from queue
      ;=====
      
      ; retrieve queue srcpos
      lw $v0,0x48($sp)
      nop
      ; v1 = next queue value
      lbu $v1,0($v0)
      ; advance queue pointer
      addiu $v0,1
      
      ; if next value is zero, done
      beq $v1,$zero,newCharSequenceToVramLoopDone
      ; write back updated queue pointer
      sw $v0,0x48($sp)
      
      ;=====
      ; set up call to decompression function
      ;=====
      
      ; generate codepoint (0x80**) and place on pre-allocated stack space
      addiu $v1,0x8001
      sh $v1,0x0018($sp)
      
      ; a0 = dstptr
      lw $s0,0($s5)
      lhu $v0, 0($s1)
      nop
      sll $v0, $v0, 7
      addu $s0, $s0, $v0
      addu $a0, $s0, $zero
      
      ; a1 = pointer to target character codepoint
      ; (placed on pre-allocated stack space)
      addiu $a1, $sp, 0x0018
      
      ; a2 = pointer to fontsheet graphic header
      lw $a2, 0x0160($s7)
      
      ;=====
      ; out of space
      ;=====
      
      j newCharSequenceToVramOverflow
      nop
      newCharSequenceToVramOverflowDone:
      
      ;=====
      ; loop until done
      ;=====
      
      b newCharSequenceToVramLoop
      nop
    
    newCharSequenceToVramLoopDone:
    
    ;=====
    ; done
    ;=====
    
    j 0x80073FBC
    nop
  .endarea

  ;============================================================================
  ; test
  ;============================================================================
  
/*  .org 0x8006466C
    j displayTest
    addu $a0,$t1,$zero */
  
;  .org 0x800648F4
;    j displayTest2
;    lw $s2, 0x0028($sp)
  
;  .org 0x800648D4
;    j displayTest2
;    nop
  
;  .org 0x80064E14
;;    lui $a2, 0x6680
;    lui $a2, 0x6580

  ; init subtitles when needed
  .org 0x8006466C
    j roboSelect_triggerDeploymentSubs
  
  ; state 2: do sub update
  .org 0x800648D4
    jal roboSelect_doSubUpdate_generic
    nop
  
  ; state 3: do sub update
  .org 0x80064A7C
    jal roboSelect_doSubUpdate_generic
    nop
    
  ; state 4 is really short and doesn't redraw,
  ; so we'll just ignore it?
  
  ; state 5: do sub update
  .org 0x800660DC
    jal roboSelect_doSubUpdate_generic
    nop
  
  ; state 6: do sub update
  .org 0x80066280
    jal roboSelect_doSubUpdate_generic
    nop
  
  ; state 7: do sub update
  .org 0x800666E8
    jal roboSelect_doSubUpdate_generic
    nop
    
  ; load new file with subtitle data on sequence start
  .org 0x80062C00
    j roboSelect_loadSubtitleFile
    nop

  ;============================================================================
  ; hardcoded offsets for robot select overlay graphics
  ;============================================================================

  ; file 0 does nothing special...
  .org 0x80062B30+(0xC*0)
;    addiu $a0, $a0, roboSelectOverlayGrpPack_file0
  ; file 1
  .org 0x80062B30+(0xC*1)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file1
  ; file 2
  .org 0x80062B30+(0xC*2)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file2
  .org 0x80062B30+(0xC*3)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file3
  .org 0x80062B30+(0xC*4)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file4
  .org 0x80062B30+(0xC*5)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file5
  .org 0x80062B30+(0xC*6)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file6
  .org 0x80062B30+(0xC*7)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file7
  .org 0x80062B30+(0xC*8)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file8
  .org 0x80062B30+(0xC*9)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file9
  .org 0x80062B30+(0xC*10)
    addiu $a0, $a0, roboSelectOverlayGrpPack_file10
;  .org 0x80062B30+(0xC*11)
;    addiu $a0, $a0, roboSelectOverlayGrpPack_file11
  .org 0x80062BB0
    j loadExtraRoboSelectGrp
    addiu $a0, $a0, roboSelectOverlayGrpPack_file11
  
;  .org 0x80062B2C+(0xC*6)
;    nop
  
  ; width of displayed robot select overlay window labels
  .org 0x80064EC0
;    ori $t2, $t2, 0x003C
    ori $t2, $t2, 60*2
  
  ; height of window label textures
  .org 0x80064EAC
    lui $t2, 0x0010*2
  
  ; texpage of window label textures
  .org 0x80064E98
;    ori $t5, $t5, 0x021E
    ori $t5, $t5, 0x021F
  
  ; gpu srcpos for budget
  .org 0x80064F0C
;    ori $v0, $zero, 0xDC80
    ori $v0, $zero, 0x9040
  
  ; gpu srcpos for completion bonus
  .org 0x80064F68
;    ori $v0, $zero, 0xCC80
    ori $v0, $zero, 0xB040
  
  ; gpu srcpos for mobilization cost
  .org 0x80064FDC
;    ori $v0, $zero, 0xEC80
    ori $v0, $zero, 0xD040
    
  
  ; y-pos of completion bonus text needs to be lower to align
  ; with yen label
  .org 0x80064F2C
    lui $a1, 0x0035+2
  
  
  ; width of robot select windows
  .org 0x80064E84
    ori $v0, $v0, 0x0068+16
  
  ; x-pos of robot select windows
  .org 0x80064E34
    ori $a0, $a0, 0x00CE-16
  
  ; x-pos of "budget"
  .org 0x80064EA8
    ori $a1, $a1, 0x00D5-16
  
  ; x-pos of "completion bonus"
  .org 0x80064F40
    ori $a1, $a1, 0x00D5-16
  
  ; x-pos of "mobilization cost"
  .org 0x80064FD4
    ori $v0, $v0, 0x00D5-16
  
  ; exchange vram positions of "budget" and "completion bonus" labels.
  ; the game puts some other thing in a place where we don't want it,
  ; and this is easiest.
  
  ; "budget"
;  .org 0x80064F0C
;    ; gpu srcaddr
;;    ori $v0, $zero, 0xDC80
;    ori $v0, $zero, 0xCC80
;  
;  ; "completion bonus"
;  .org 0x80064F68
;    ; gpu srcaddr
;;    ori $v0, $zero, 0xCC80
;    ori $v0, $zero, 0xDC80
  
  ; make "budget" half the width of the other labels to hide this abnormality
;  .org 0x80064F20
;    j roboselect_halveBudgetLabelWidth
;    sw $a1, 0x000C($a3)
  
  ;=====
  ; render numbers through vwf
  ;=====
  
  .org 0x80065128
  .area 0x9C
    ; at this point, v0 = player budget.
    ; render and send to gpu.
    
    ; if current statevar is 1 (robot selected), clean up allocated
    ; resources and do not draw
    ; (wait, this will probably leak memory for the cases where the
    ; game skips the selection menu and only shows the deployment)
/*    lui $a2, 0x8009
    lw $a2, 0xED4C($a2)
    ; gpu dst lo
    li $a0,0x0A00
    lw $a2,0($a2)
    ; gpu dst hi
    li $a1,0x00A0
    beq $a2,$zero,@@notDone
    nop
      jal destroyCharTransferQueue
      nop
      j 0x800651C4
      nop
    @@notDone: */
    
    li $a0,0x0A00
    li $a1,0x00A0
    
    ; gpu dst lo
;    li $a0,0x0A00
    ; gpu dst hi
;    li $a1,0x00C0
    
    ; value to render
    jal renderNumber
    move $a2,$v0
    
    ; get completion bonus
    jal 0x8006F034
    nop
    
    ; gpu dst lo
;    li $a0,0x0A00
    ; gpu dst hi
;    li $a1,0x00D0
    ; gpu dst lo
    li $a0,0x0A00
    ; gpu dst hi
    li $a1,0x00C0
    ; value to render
    jal renderNumber
    move $a2,$v0
    
    ; get deployment cost
    lui $v0, 0x8009
    lw $v0, 0xED4C($v0)
    nop
    lw $a0, 0x0504($v0)
    jal 0x8006F058
    nop
    
    ; gpu dst lo
    li $a0,0x0A00
    ; gpu dst hi
    li $a1,0x00E0
    ; value to render
    jal renderNumber
    move $a2,$v0
    
    j 0x800651C4
    nop
    
    ; 0x980 0xCC = "budget"
  .endarea
  
  ; init char transfer buffers at start of selection screen.
  ; we need these to render text through renderNumber.
  
  .org 0x80061E3C
    j doExtraRoboSelectInit
    sw $v0, 0x04CC($v1)
  
  .org 0x80063BC4
    j doExtraRoboSelectCleanup
    lw $s2, 0x0018($sp)
  
  ;============================================================================
  ; modified topwindow label structures
  ;============================================================================
  
  ; format:
  ; - 1b srcX
  ; - 1b srcY
  ; - 1b length
  ; - 1b dummy
  
  .org 0x8008B4D0
    ; entry 0 - blank
    .db 0x00
    .db 0x00
    .db 0x00
    .db 0x00
    ; entry 1 - 応接室
    .db 0x00
    .db 0x00
    .db 0x04
    .db 0x00
    ; entry 2 - 戦闘記録
    .db 0x40
    .db 0x00
    .db 0x06
    .db 0x00
    ; entry 3 - 司令室
    .db 0xA0
    .db 0x00
    .db 0x05
    .db 0x00
    ; entry 4 - 財政状態
    .db 0x00
    .db 0x10
    .db 0x07
    .db 0x00
    ; entry 5 - 広報活動
    .db 0x70
    .db 0x10
    .db 0x04
    .db 0x00
    ; entry 6 - 資金調達
    .db 0xB0
    .db 0x10
    .db 0x05
    .db 0x00
    ; entry 7 - 装備購入
    .db 0x00
    .db 0x20
    .db 0x08
    .db 0x00
    ; entry 8 - 装甲強化
    .db 0x80
    .db 0x20
    .db 0x06
    .db 0x00
    ; entry 9 - 現在の装備
    .db 0x00
    .db 0x30
    .db 0x07
    .db 0x00
    ; entry 10 - 格納庫
    .db 0x70
    .db 0x30
    .db 0x03
    .db 0x00
    ; entry 11 - ロボット性能
    .db 0xA0
    .db 0x30
    .db 0x06
    .db 0x00
    ; entry 12 - 新兵器開発
    .db 0x00
    .db 0x40
    .db 0x09
    .db 0x00
    ; entry 13 - メガモーター強化
    .db 0x00
    .db 0x70
    .db 0x08
    .db 0x00
    ; entry 14 - 資金概算　　　　　億円
    .db 0x00
    .db 0x60
    .db 0x0B
    .db 0x00
    ; entry 15 - [ten spaces, reserved for budget number]
    ; NOTE: position has hardcoded reference in executable --
    ; easiest just to leave it at 0x50
    .db 0x00
    .db 0x50
    ; old width was 140 (14px spacing).
    ; now, with 16px spacing, the total vram area is 160px,
    ; but we only need the first 140px of it.
    .db 0x0A-1
    .db 0x00
    ; entry 16 - ジェットロボ　ヴォーダン
    .db 0x00
    .db 0x80
    .db 0x07
    .db 0x00
    ; entry 17 - スチームロボ　ガレス
    .db 0x70
    .db 0x80
    .db 0x08
    .db 0x00
    ; entry 18 - 原子力ロボ　ライオネル
    .db 0x00
    .db 0x90
    .db 0x08
    .db 0x00
    ; entry 19 - 電子ロボ　ペルスヴァル
    .db 0x00
    .db 0xA0
    .db 0x09
    .db 0x00
    ; entry 20 - ポケットステーション
    ; NOTE: moved out of original order
    .db 0x80
    .db 0x90
    .db 0x06
    .db 0x00

  ;============================================================================
  ; modified damage report string structures
  ;============================================================================
  
  ; format:
  ; - 2b srcX
  ; - 2b srcY
  ; - 4b length?
  
  .org 0x8008CF5C
    ; entry 0 - ?
    .dh 0x00
    .dh 0x00
    .dw 0x1
    ; entry 1 - ?
    .dh 0x10
    .dh 0x00
    .dw 0x1
    ; entry 2 - ?
    .dh 0x20
    .dh 0x00
    .dw 0x1
    ; entry 3 - ?
    .dh 0x30
    .dh 0x00
    .dw 0x1
    ; entry 4 - ?
    .dh 0x40
    .dh 0x00
    .dw 0x1
    ; entry 5 - ?
    .dh 0x50
    .dh 0x00
    .dw 0x1
    ; entry 6 - ?
    .dh 0x60
    .dh 0x00
    .dw 0x1
    ; entry 7 - ?
    .dh 0x70
    .dh 0x00
    .dw 0x1
    ; entry 8 - ?
    .dh 0x80
    .dh 0x00
    .dw 0x1
    ; entry 9 - ?
    .dh 0x90
    .dh 0x00
    .dw 0x1
    ; entry 10 - ?
    .dh 0xA0
    .dh 0x00
    .dw 0x1
    ;=====
    ; SEGMENT 0x0-0xB0
    ;=====
    ; entry 11 - "X"
    .dh 0xB0
    .dh 0x00
    .dw 0x1
    ;=====
    ; SEGMENT 0x10
    ;=====
    ; entry 12 - 民家
    .dh 0x00
    .dh 0x10
    .dw 0x4
    ; entry 13 - ビル
    .dh 0x40
    .dh 0x10
    .dw 0x2
    ; entry 14 - 車
    .dh 0x60
    .dh 0x10
    .dw 0x1
    ; entry 15 - 船
    .dh 0x70
    .dh 0x10
    .dw 0x2
    ; entry 16 - コンテナ
    .dh 0x90
    .dh 0x10
    .dw 0x3
    ; entry 17 - 信号機
    .dh 0xC0
    .dh 0x10
    .dw 0x4
    ;=====
    ; SEGMENT 0x20
    ;=====
    ; entry 18 - 美幸の家
    .dh 0x00
    .dh 0x20
    .dw 0x4
    ; entry 19 - 電車
    .dh 0x40
    .dh 0x20
    .dw 0x2
    ; entry 20 - 富士津商会
    .dh 0x60
    .dh 0x20
    .dw 0x3
    ; entry 21 - うおいち
    .dh 0x90
    .dh 0x20
    .dw 0x4
    ;=====
    ; SEGMENT 0x30
    ;=====
    ; entry 22 - Ｓマーケット
    .dh 0x00
    .dh 0x30
    .dw 0x4
    ; *** SKIP -> 59 ***
    ; entry 23 - コンビニ
    .dh 0x90
    .dh 0x30
    .dw 0x5
    ;=====
    ; SEGMENT 0x40
    ;=====
    ; entry 24 - ヒューマン支社
    .dh 0x00
    .dh 0x40
    .dw 0x5
    ; entry 25 - 駅
    .dh 0x50
    .dh 0x40
    .dw 0x2
    ; entry 26 - 神社
    .dh 0x70
    .dh 0x40
    .dw 0x2
    ; *** SKIP -> 62 ***
    ;=====
    ; SEGMENT 0x50
    ;=====
    ; entry 27 - 王座財閥ビル
    .dh 0x00
    .dh 0x50
    .dw 0x7
    ; entry 28 - 高速道路
    .dh 0x70
    .dh 0x50
    .dw 0x3
    ; *** SKIP -> 63 ***
    ;=====
    ; SEGMENT 0x60
    ;=====
    ; entry 29 - カニ鉄人
    .dh 0x00
    .dh 0x60
    .dw 0x3
    ; entry 30 - 原子力研究所
    .dh 0x30
    .dh 0x60
    .dw 0x7
    ;=====
    ; SEGMENT 0x70
    ;=====
    ; entry 31 - 鶏野発電所Ａ棟
    .dh 0x00
    .dh 0x70
    .dw 0x6
    ; entry 32 - 鶏野発電所Ｂ棟
    .dh 0x60
    .dh 0x70
    .dw 0x6
    ;=====
    ; SEGMENT 0x80
    ;=====
    ; entry 33 - 港湾施設
    .dh 0x00
    .dh 0x80
    .dw 0x5
    ; entry 34 - 展望台
    .dh 0x50
    .dh 0x80
    .dw 0x5
    ; entry 35 - 都庁第二庁舎
    .dh 0xA0
    .dh 0x80
    .dw 0x6
    ;=====
    ; SEGMENT 0x90
    ;=====
    ; entry 36 - 都庁議会棟
    .dh 0x00
    .dh 0x90
    .dw 0x7
    ; entry 37 - ビル型ゲート
    .dh 0x70
    .dh 0x90
    .dw 0x4
    ; *** SKIP -> 64 ***
    ;=====
    ; SEGMENT 0xA0
    ;=====
    ; entry 38 - （株）鶏野警備隊
    .dh 0x00
    .dh 0xA0
    .dw 0x8
    ; entry 39 - 第
;    .dh 0x80
;    .dh 0xA0
;    .dw 0x3
    ; threw in a longer version of this at the end
    .dh 0xA0
    .dh 0xE0
    .dw 0x5
    ; entry 40 - 回決算
    .dh 0xB0
    .dh 0xA0
    .dw 0x0 ; currently not used for translation
    ; entry 41 - 成功報酬
    .dh 0xB0
    .dh 0xA0
    .dw 0x5
    ;=====
    ; SEGMENT 0xB0
    ;=====
    ; entry 42 - 今回の損害
    .dh 0x00
    .dh 0xB0
    .dw 0x2
    ; entry 43 - [button_circle]ボタンで総計算
    .dh 0x20
    .dh 0xB0
    .dw 0x7
    ;=====
    ; SEGMENT 0xC0
    ;=====
    ; entry 44 - 出撃費用
    .dh 0x00
    .dh 0xC0
    .dw 0x5
    ; entry 45 - 差し引き
    .dh 0x50
    .dh 0xC0
    .dw 0x5
    ; entry 46 - 警備隊総予算
    .dh 0xA0
    .dh 0xC0
    .dw 0x3
    ;=====
    ; SEGMENT 0xD0
    ;=====
    ; entry 47 - this through 56 are digits 0-9
    .dh 0x00
    .dh 0xD0
    .dw 0x1
    ; entry 48 - 
    .dh 0x10
    .dh 0xD0
    .dw 0x1
    ; entry 49 - 
    .dh 0x20
    .dh 0xD0
    .dw 0x1
    ; entry 50 - 
    .dh 0x30
    .dh 0xD0
    .dw 0x1
    ; entry 51 - 
    .dh 0x40
    .dh 0xD0
    .dw 0x1
    ; entry 52 - 
    .dh 0x50
    .dh 0xD0
    .dw 0x1
    ; entry 53 - 
    .dh 0x60
    .dh 0xD0
    .dw 0x1
    ; entry 54 - 
    .dh 0x70
    .dh 0xD0
    .dw 0x1
    ; entry 55 - 
    .dh 0x80
    .dh 0xD0
    .dw 0x1
    ; entry 56 - 
    .dh 0x90
    .dh 0xD0
    .dw 0x1
    ; entry 57 - ‐
    .dh 0xA0
    .dh 0xD0
    .dw 0x1
    ; entry 58 - 倉庫
    .dh 0xB0
    .dh 0xD0
    .dw 0x4
    ;=====
    ; JUMP BACK TO SEGMENT 0x30
    ; because apparently they shoved in 輸送船 at some later point
    ;=====
    ; entry 59 - 輸送船
    .dh 0x40
    .dh 0x30
    .dw 0x5
    ;=====
    ; SEGMENT 0xE0
    ;=====
    ; entry 60 - 農地型ゲート
    .dh 0x00
    .dh 0xE0
    .dw 0x3
    ; entry 61 - 鶏野中学校
    .dh 0x30
    .dh 0xE0
    .dw 0x5
    ; *** SKIP -> 65 ***
    ;=====
    ; extras:
    ;=====
    ; entry 62 - 都庁連絡橋
    .dh 0x90
    .dh 0x40
    .dw 0x5
    ; entry 63 - 都庁第一庁舎
    .dh 0xA0
    .dh 0x50
    .dw 0x6
    ; entry 64 - 鶏野発電所
    .dh 0xB0
    .dh 0x90
    .dw 0x5
    ; entry 65 - クレーン
    .dh 0x80
    .dh 0xE0
    .dw 0x2


    
    
  
.close



;============================================================================
; SINKOU.S3M
;============================================================================

.open "out/asm/SINKOU.S3M", 0x80060A60

  ;========================================
  ; use newly generated offset table for
  ; unheadered archive SINKOU.PAC/9
  ;========================================
  .org 0x800612BC
    .incbin "out/include/sinkou9_index.bin"

  ;========================================
  ; fix hardcoded allocation size for models from SINKOU.PAC/9
  ;========================================
  
  .org 0x8006AF64
    li $a0,(filesize("out/SINKOU.PAC/9.bin")+2)

  ;========================================
  ; use newly generated offset table for
  ; unheadered archive SINKOU.PAC/69
  ;========================================
  .org 0x80060BE0
    .incbin "out/include/sinkou69_index.bin"

  ;========================================
  ; adjust delay between display of each
  ; image in the credits sequence
  ;========================================
  .org 0x800645B0
;    slti $v0, $v0, 0x004C
    slti $v0, $v0, 0x0014

  ;========================================
  ; DEBUG: force credits to run at startup
  ;========================================
;  .org 0x80062DAC
;    j debugcredits
;    nop

.close

;.open "buildfiles/gamefiles/arm7.bin", 0x02380000
  
  ;========================================
  ; NEW CODE
  ;========================================
  
;  .org arm7End
  
;.close

;============================================================================
; SONIC.AOE_4 (code overlay for battle mode interface overlay graphics?)
;============================================================================

.open "out/asm/sonicaoe_4.bin", 0x800B601C

  ;========================================
  ; width of "battle" label
  ;========================================
  
  .org 0x800B643C
    addiu $t2, $zero, 0x0050+0x10

  ;========================================
  ; base x-pos of "battle" label
  ;========================================
  
  .org 0x800B67CC
    addiu $v0, $zero, 0x0050-0x14

.close

  
