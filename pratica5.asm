; Pratica 5 : Interface de teclado matricial
; Programador: Francisco Edno
;
; Sistema de Acesso
;
; O programa continuamente faz a leitura de um teclado matricial
; na porta P2 e imprime em um display de 7 segmentos (Como feedback). 
; Apos a confirmacao de ENTER (#) os numeros digitados serao comparados
; com a senha padrao em tabela, ou com a senha na e2prom. Senha de 4 digitos.
;
; O Codigo de interface com teclado matricial e baseado num exemplo do livro
; do Scott Mackenzie.
;
; Teclado matricial:
; C1: P2.1 | C2: P2.2 | C3: P2.3
; L1: P2.4 | L2: P2.5 | L3: P2.6 | L4: P2.7
;
; Registrador de deslocamento:
; SHD: P0.0 | SHCK: P0.1 | SHLTCH: P0.2

; ****************************************************************************
; EQUATES
; ****************************************************************************

SHD     equ     p0.0
SHCK    equ     p0.1
SHLTCH  equ     p0.2

; ****************************************************************************
; Inicio
; ****************************************************************************
Main:       call    KeyIn
            mov     b, acc
            ajmp    Main

; ****************************************************************************
; SUB-ROTINAS
; ****************************************************************************

; ----------------------------------------------------------------------------
; KeyIn
; ----------------------------------------------------------------------------
; Faz a leitura do teclado com 'Software Debouncing' para o pressionar e o
; liberar da tecla (50 operacoes para cada).
; ----------------------------------------------------------------------------
KeyIn:      mov     r3, #50     ; Contador para o debouncing
Back:       call    GetKey      ; Tecla pressionada?
            jnc     KeyIn       ; Nao: tentar ler denovo (Pode mudar)
            djnz    r3, Back    ; Sim: repete 50 vezes
            push    acc         ; Salva o codigo da tecla

Back2:      mov     r3, #50     ; Espera a tecla ser liberada novamente
Back3:      call    GetKey      ; Tecla pressionada?
            jc      Back2       ; Sim: Cotinue checkando
            djnz    r3, Back3   ; Nao: Repete 50 vezes
            pop     acc         ; Recupera o codigo da tecla
            ret                 ; Retorna

; ---------------------------------------------------------------------------
; GetKey
; ---------------------------------------------------------------------------
; Pega o status do teclado
; Retorna: C = 0 se nenhuma tecla foi pressionada
;        : C = 1 e o codigo da tecla no ACC caso tenha sido pressionada
; ---------------------------------------------------------------------------
GetKey:     mov     a, #0FDh         ; Comeca com a coluna 0
            mov     r6, #3           ; Usa R6 como contador
Test:       mov     p2, a            ; Ativa uma coluna
            mov     r7, a            ; Salva ACC
            mov     a, p2            ; Agora leio a porta novamente
            anl     a, #0F0h         ; Isolo as linhas
            cjne    a, #0F0h, KeyHit ; Alguma linha ativa?
            mov     a, r7            ; Nao: va para a proxima coluna
            rl      a
            djnz    r6, Test
            clr     c                ; Nenuma tecla pressionada :(
            sjmp    Exit             ; Retorna com c = 0

KeyHit:     mov     r7, a            ; Salvo em r7 o scan
            mov     a, #4            ; Preparacao para o calculo da coluna
            clr     c
            subb    a, r6            ; 3 - R6 = numero da coluna (0:3)
            mov     r6, a            ; Salvo o numero da coluna em R6
            mov     a, r7            ; Restauro o que foi lido da P2
            swap    a                ; Boto as linhas no nibble menor

            mov     r5, #4
Again:      rrc     a                ; Rotaciona ate C = 0
            jnc     Done             ; Done quando C = 0
            inc     r6
            inc     r6
            inc     r6
            djnz    r5, Again
            
Done:       cjne    r6, #0Bh, Done2   ; O codigo = 0Bh (11) ?
            mov     r6, #0           ; sim: O codigo e o 0

Done2:      setb    c                ; C = 1 (tecla pressionada)
            mov     a, r6            ; Codigo no ACC
Exit:       ret

; ****************************************************************************
            end
; ****************************************************************************
