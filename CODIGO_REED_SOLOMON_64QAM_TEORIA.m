%CODIFICA��O RS 64QAM - TEORIA

N = 63;  % Tamanho da palavra c�digo
K = 51;  % Tamanho da mensagem
M = 64;  % Ordem da Modula��o

ebnoVec = (-10:40)'; 

berapprox = bercoding(ebnoVec,'RS','hard',N,K,'qam',64);
semilogy(ebnoVec,berapprox,'k--')
legend('Curva Te�rica - RS(63,51) | 64QAM','Location','southwest')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid on