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
; Teclado matricial:
; C3: P2.0 | C2: P2.1 | C1: P2.2
; L4: P2.3 | L3: P2.4 | L2: P2.5 | L1: P2.6
;
; Registrador de deslocamento:
; SHD: P0.0 | SHCK: P0.1 | SHLTCH: P0.2

; ****************************************************************************
; EQUATES
; ****************************************************************************

SHD		equ		p0.0
SHCK	equ		p0.1
SHLTCH	equ		p0.2
