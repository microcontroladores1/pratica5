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

SHD     equ     p3.0
SHCK    equ     p3.1
SHLTCH  equ     p3.2

USRPSS  equ     30h  ; Senha no endereco 30h

LED_OK  equ     p3.3
LED_LCK equ     p3.4
BUZZER  equ     p3.5

; ****************************************************************************
; Inicio
; ****************************************************************************
Main:       mov     r4, #4   ; Usa r4 como contador
Loop:       call    KeyIn
            acall   Display  ; Imprimo no display o valor do ACC

            mov     a, #4      ; Peso para calculo do indice
            subb    a, r4      ; Encontro o valor do indice
            add     a, #USRPSS ; Preparo para guardar o valor no vetor
            mov     r0, a      ; Coloco o endereco no r0 para acesso indireto
            mov     @r0, b     ; Guardo o digito no vetor

            djnz    r4, Loop

            acall   CheckPsswd ; Checa se a senha que o usuario entrou esta ok

            jc      PassOK     ; Senha correta?
            clr     LED_LCK    ; nao: Liga o led indicativo de fechado
            clr     BUZZER     ; liga o buzzer
            acall   BuzzTime   ; Tempo para o buzzer
            setb    BUZZER     ; Desliga o Buzzer
            ajmp    Main       ; Volta para o inicio

PassOK:     setb    LED_LCK    ; Desliga o led de fechado
            clr     LED_OK     ; Liga o led de ok
            acall   OKTime     ; Tempo de aberto
            clr     LED_LCK    ; Liga o led de fechado
            setb    LED_OK     ; Desliga led de ok apos o tempo determinado
            setb    f0         ; Seta a flag f0, informando que o usuario ja
                               ; entrou com uma senha

            ajmp    Main

; ****************************************************************************
; SUB-ROTINAS
; ****************************************************************************

; ----------------------------------------------------------------------------
; KeyIn
; ----------------------------------------------------------------------------
; Faz a leitura do teclado com 'Software Debouncing' para o pressionar e o
; liberar da tecla (50 operacoes para cada). Apenas retorna quando uma tecla
; for pressionada.
; Retorna: Codigo da tecla no Registrador B.
; Usa: GetKey
; Registradores: r3 (contador)
; ----------------------------------------------------------------------------
KeyIn:      mov     r3, #50     ; Contador para o debouncing
Back:       call    GetKey      ; Tecla pressionada?
            jnc     KeyIn       ; Nao: tentar ler denovo (Pode mudar)
            djnz    r3, Back    ; Sim: repete 50 vezes
            push    b           ; Salva o codigo da tecla

Back2:      mov     r3, #50     ; Espera a tecla ser liberada novamente
Back3:      call    GetKey      ; Tecla pressionada?
            jc      Back2       ; Sim: Cotinue checkando
            djnz    r3, Back3   ; Nao: Repete 50 vezes
            pop     b           ; Recupera o codigo da tecla
            ret                 ; Retorna

; ---------------------------------------------------------------------------
; GetKey
; ---------------------------------------------------------------------------
; Pega o status do teclado
; Retorna: C = 0 se nenhuma tecla foi pressionada
;        : C = 1 e o codigo da tecla no Registrador B caso tenha sido 
;          pressionada
; Registradores: r5, r6, r7
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
            mov     b, r6            ; Codigo no Registrador B
Exit:       ret

; ---------------------------------------------------------------------------
; Display
; ---------------------------------------------------------------------------
; Imprime no display de 7 segmentos o digito do registrador B. Caso o valor 
; seja Maior que 9, a rotina faz nada.
; Registradores: r5
; ---------------------------------------------------------------------------
Display:    mov     a, b        ; Boto o valor da tecla no ACC para acessar TAB
            push    acc         ; Salvo o ACC
            add     a, #(not 9) ; Preparo para verificar se ACC > 9
            pop     acc         ; Restauro ACC

            jc      Exit2       ; Acc > 9 ?
            
            acall   LKDisp      ; Nao: Boto a decodificacao do display no ACC

            clr     SHLTCH      ; Trava o registrador

            mov     r5, #8      ; Usa r5 como contador
Here:       mov     c, acc.7    ; Pego o bit mais significativo do ACC
            mov     SHD, c      ; Envio para o Shift Register
            acall   CKPulse     ; Pulso de clock para entrar
            rl      a           ; Rotaciono para pegar o proximo bit
            djnz    r5, Here    

            setb    SHLTCH      ; Libera o registrador

Exit2:      ret

; ---------------------------------------------------------------------------
; LKDisp
; ---------------------------------------------------------------------------
; Look-up Table para decodificacao do display de 7 segmentos.
; Retorna: A decodificacao no acumulador.
; ---------------------------------------------------------------------------
LKDisp:     mov     dptr, #DECODING ; Passa o endereco da tabela para o dptr
            movc    a,@a+dptr       ; Acessa a Tabela

            ret                     ; Retorna com o valor no ACC

DECODING:   db  3Fh, 06h, 5Bh, 4Fh, 66h, 6Dh, 7Dh, 07h, 7Fh, 67h

; ---------------------------------------------------------------------------
; CheckPsswd
; ---------------------------------------------------------------------------
; Verifica se a senha que o usuario entrou esta correta. Caso uma senha
; nao tenha sido fornecida (verifico f0) a rotina retorna C = 0.
; Retorna: C = 1 caso esteja.
;        : C = 0 caso nao esteja ou caso nenhuma senha tenha sido fornecida.
; Registradores: r4
; ---------------------------------------------------------------------------
CheckPsswd:
            ret

; ---------------------------------------------------------------------------
; LKPsswd
; ---------------------------------------------------------------------------
; Look-Up Table para verificacao de senha padrao.
; ---------------------------------------------------------------------------
LKPsswd:    mov     dptr, #PASSWD
            movc    a, @a+dptr

            ret

PASSWD:     db  2, 6, 0, 5

; ---------------------------------------------------------------------------
; BuzzTime
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
BuzzTime:
            ret

; ---------------------------------------------------------------------------
; OKTime
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
OKTime:
            ret

; ---------------------------------------------------------------------------
; Delay
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
Delay:
            ret

; ---------------------------------------------------------------------------
; CKPulse
; ---------------------------------------------------------------------------
; Pulso de clock no registrador de deslocamento
; ---------------------------------------------------------------------------
CKPulse:    setb    SHCK
            clr     SHCK
            ret

; ****************************************************************************
            end
; ****************************************************************************
