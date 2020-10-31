bits 16
org 0x7c00

mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00
mov bp, sp

start:
  ; set video mode to al=0x03 (VGA-Mode)
  mov ax, 0x03
  int 0x10

  ; hide curso
  mov ax, 0x0100
  mov ch, 00100000b
  mov cl, 0x00
  int 0x10

  call create_border

  game_logic:
    mov bl, 1 ; snake len

    mov word[SNAKE_POS], 5
    mov word[APPLE_POS], FIELD_SIZE_X * FIELD_SIZE_Y / 2 + FIELD_SIZE_X / 2

    mainloop:
      ; check if apple was eaten
      mov cx, word[SNAKE_POS]
      cmp cx, word[APPLE_POS]
      jne .no_apple_eaten
      inc bl

      rdtsc
      mov cx, FIELD_SIZE_X * FIELD_SIZE_Y
      div cx
      mov word[APPLE_POS], dx

      .no_apple_eaten:

      mov cx, 0 ; field counter
      mov dx, 0x0101 ; cursor pos (starts at (1|1) because of the border)

      draw_field:
        cmp cx, FIELD_SIZE_X * FIELD_SIZE_Y - 1
        je .done

        cmp dl, FIELD_SIZE_X * 2
        jl .line_end_not_reached
        mov dl, 0x01
        inc dh
        .line_end_not_reached:


        ; eax=pointer to current field
        mov eax, FIELD_MEM
        add eax, ecx

        ; check if snake head on current pos
        cmp word[SNAKE_POS], cx
        jne .snake_head_not_here

        cmp byte[eax], 0
        jne dead

        mov byte[eax], bl
        .snake_head_not_here:


        ; update cursor to be at current position
        call move_cursor


        ; check if snake body on curren pos
        cmp byte[eax], 0
        je .snake_body_not_here

        ; dec life of snake body
        dec byte[eax]

        ; print out sign for snake body
        mov al, SNAKE_SIGN
        call print.char
        mov al, " "
        call print.char

        jmp .something_was_here
        .snake_body_not_here:


        ; cehck if apple on current pos
        cmp word[APPLE_POS], cx
        jne .apple_not_here

        ; print out sign for apple
        mov al, APPLE_SIGN
        call print.char
        mov al, " "
        call print.char

        jmp .something_was_here
        .apple_not_here:

        ; nothing was at this field so print whitespace
        mov al, ' '
        call print.char
        call print.char



        .something_was_here:

        add dl, 2
        inc cx

        jmp draw_field


      .done:
        ; get keyboard input
        call process_keyboard


        mov eax, SLEEPTIME
        call sleep

        ; write movement in bx
        push bx
        mov bx, word[SNAKE_VEL]

        xor dx, dx
        mov cx, FIELD_SIZE_X
        mov ax, word[SNAKE_POS]
        div cx

        cmp dx, 0
        jne .not_left_edge
        cmp bx, -1
        je dead
        .not_left_edge:

        cmp dx, FIELD_SIZE_X - 1
        jne .not_right_edge
        cmp bx, 1
        je dead
        .not_right_edge:

        cmp ax, 0
        jne .not_top_edge

        cmp bx, -FIELD_SIZE_X
        je dead
        .not_top_edge:

        cmp ax, FIELD_SIZE_Y - 1
        jne .not_bottom_edge

        cmp bx, FIELD_SIZE_X
        je dead
        .not_bottom_edge:

        ; move snake head
        add word[SNAKE_POS], bx
        pop bx
        jmp mainloop

  dead:
  mov dx, 0
  mov dh, FIELD_SIZE_Y + 2
  call move_cursor
  mov si, text
  call print.string
  jmp exit

exit:
  jmp short exit

; -- DATA --
FRAME_SIGN equ "="
SNAKE_SIGN equ "*"
APPLE_SIGN equ "O"
FIELD_SIZE_X equ 20
FIELD_SIZE_Y equ 20
SLEEPTIME equ 0x09000000

UP_ARROW equ 0x48
DOWN_ARROW equ 0x50
LEFT_ARROW equ 0x4B
RIGHT_ARROW equ 0x4D

text db "Game Over!", 0xa, 0xd, 0

; -- MEMORY POINTER --

MEMORY: equ 0x7e00 ; start of memory region
  FIELD_MEM equ MEMORY
    FIELD_MEM_size equ FIELD_SIZE_X * FIELD_SIZE_Y + 32
  SNAKE_POS equ FIELD_MEM + FIELD_MEM_size
    SNAKE_POS_size equ 8
  APPLE_POS equ SNAKE_POS + SNAKE_POS_size
    APPLE_POS_size equ 8
  SNAKE_VEL equ APPLE_POS + APPLE_POS_size
    SNAKE_VEL_size: equ 8


; -- SUBROUTINES --
sleep:
  dec eax
  cmp eax, 0
  jnz sleep
  ret

process_keyboard:
  mov ah, 1
  int 0x16

  cmp ah, UP_ARROW
  jne .not_up
  mov word[SNAKE_VEL], -FIELD_SIZE_X
  .not_up:

  cmp ah, DOWN_ARROW
  jne .not_down
  mov word[SNAKE_VEL], FIELD_SIZE_X
  .not_down:

  cmp ah, RIGHT_ARROW
  jne .not_right
  mov word[SNAKE_VEL], 1
  .not_right:

  cmp ah, LEFT_ARROW
  jne .not_left
  mov word[SNAKE_VEL], -1
  .not_left:

  mov ah, 1
  int 0x16
  jz .buffer_is_clear
  .clear_keyboard_buffer:
  mov ah, 0
  int 0x16
  mov ah, 1
  int 0x16
  jnz .clear_keyboard_buffer
  .buffer_is_clear:


create_border:
    push ax
    push dx

    mov dx, 0
    mov al, FRAME_SIGN
    .x_rows:
      cmp dl, FIELD_SIZE_X * 2 + 2
      je .x_rows_done

      call move_cursor
      call print.char

      mov dh, FIELD_SIZE_Y +1
      call move_cursor
      call print.char
      mov dh, 0

      inc dl
      jmp .x_rows

    .x_rows_done:
    mov dx, 0
    .y_rows:
      cmp dh, FIELD_SIZE_Y + 1
      je .y_rows_done

      call move_cursor
      call print.char

      mov dl, FIELD_SIZE_X * 2 + 1
      call move_cursor
      call print.char
      mov dl, 0

      inc dh
      jmp .y_rows

    .y_rows_done:
      pop dx
      pop ax
      ret


move_cursor:
  push ax
  push bx
  xor bh, bh
  mov ah, 0x2
  int 0x10
  pop bx
  pop ax
  ret

print:
  push ax
  .string:
    ; write [si] to al and inc si
    lodsb

    ; check if al==0 and end if true
    or al, al
    jz .end

    ; BIOS interrup for write
    mov ah, 0x0e
    int 0x10

    jmp print.string

  .char:
    push ax
    mov ah, 0x0e
    int 0x10

  .end:
    pop ax
    ret

; -- PADDING --
times 510 - ($ - $$) db 0
dw 0xaa55
