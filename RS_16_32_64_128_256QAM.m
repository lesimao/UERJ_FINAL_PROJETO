% https://www.mathworks.com/help/comm/ug/transmit-and-receive-shortened-reed-solomon-codes.html?searchHighlight=Reed-Solomon&s_tid=doc_srchtitle
% Usado como referencia o c�digo do link acima

%C�DIGO REED SOLOMON - C�digo para simular diversos cen�rios de codifica��o
%de Canal RS em 5 constela��es da modula��o QAM.

M = [16 32 64 128 256];% Vetor Quantidade de simbolos total na Constela��o por posi��o.
B = [4 5 6 7 8]; % Quantidade de bits por s�mbolo
Ka = [1 2 3 4 5]; % Vetor Simbolos de mensagem de informa��o
Na = [1 2 3 4 5] % Vetor Quantidade total de simbolos mensagem a ser enviada ao modulador

numErrors = 200; % Quantidade de erros acumulados para controle do Loop While
numBits = 1e5; % Quantidade de bits recebidos para controle do Loop While.
ebnoVec = (-5:0.5:20)'; % Faixa de varredura em Eb/No [Energia por bit/Potencia de ru�do] do gr�fico
ber0 = deal(zeros(size(ebnoVec))); % Cria��o de vetor com EbNoVec posi��es.

for j=1:length(M)
    
% Bloco para montagem do c�digo Reed Solomon - RS(N,K)    
N = (2^B(j)) - 1; %Montando o c�digo RS
Na(j) = N; %Montando o c�digo RS
Mi=round(B(j)/2); %Montando o c�digo RS
Paridade = 2^Mi; %Montando o c�digo RS
K=N-Paridade; %Montando o c�digo RS
Ka(j) = K; %Montando o c�digo RS

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M(j),'BitInput',true,'NormalizationMethod','Average power'); % Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas vari�veis de entrada
% O Modulador configurado em ordem da posi��o J do vetor M.
% Configurado para entrada em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M(j),'BitOutput', true,'NormalizationMethod','Average power'); % Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas vari�veis de entrada
% O Demodulador configurado em ordem da posi��o J do vetor M.
% Configurado para sa�da em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posi��es de estatistica de compara��o dos dados de entrada da transmiss�o com os dados de sa�da na recep��o.

rsEncoder = comm.RSEncoder(N,K,'BitInput',true); % Criando objeto Codificador Reed Solomon, com configura��es N [Palavra c�digo], K[Informa��o] e entrada de bit ativada.

rsDecoder = comm.RSDecoder(N,K,'BitInput',true); % Criando objeto Decodificador Reed Solomon, com configura��es N [Palavra c�digo], K[Informa��o] e entrada de bit ativada.

rate = K/N; %Taxa do c�digo Reed Solomon 

for k = 1:length(ebnoVec)
    
    snrdB = ebnoVec(k) + 10*log10(rate) + 10*log10(log2(M(j))); % Entender essa parte!!!!
    errorStats = zeros(3,1);
    
    while errorStats(2) < numErrors && errorStats(3) < numBits
        % Quantidade de erro < n�mero de bits e quantidade de bits < n�m de bits (1e^7)
        
        txData = randi([0 1],K*log2(M(j)),1); % Cria��o do vetor bit informa��o com tamanho K x Quantidade de simbolos total na Constela��o
        
        encData = step(rsEncoder,txData); % Codificando a informa��o com c�digo Reed Solomon e gerando a palavra c�digo.
        
        txSig = step(qamModulator,encData); % Modulando em QAM a palavra c�digo.
        
        rxSig = awgn(txSig,snrdB); % Atravessando o canal AWGN utilizando com referencia a rela��o SNR.
        
        demodSig = step(qamDemodulator,rxSig); % Demodulando em QAM a palavra c�digo.

        rxData = step(rsDecoder,demodSig); % Decodificando a informa��o com c�digo Reed Solomon e gerando a informa��o origem.
        
        errorStats = step(errorRate, txData, rxData); % Objeto criado errorRate compara os dados de origem com os dados na saida do decodificador e gera um vetor de estatistica.

    end
    
    ber0(k) = errorStats(1); % A primeira posi��o do vetor de estatistica errorStats � o percentual de bits errados recebidos, o mesmo � adicionado na posi��o k de BER.
    reset(errorRate); % Limpa o vetor objeto estatistico errorRate
    
end

%Gera��o dos gr�ficos Eb/No [energia do bit pela Pot�ncia de ru�do] pelo
%BER [Bit Error Rate]
semilogy(ebnoVec,ber0,'o-')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid
hold on

end 

legend(['RS(' num2str(Na(1)) ',' num2str(Ka(1)) ')'],['RS(' num2str(Na(2)) ',' num2str(Ka(2)) ')'],['RS(' num2str(Na(3)) ',' num2str(Ka(3)) ')'],['RS(' num2str(Na(4)) ',' num2str(Ka(4)) ')'],['RS(' num2str(Na(5)) ',' num2str(Ka(5)) ')'], 'location','sw');
