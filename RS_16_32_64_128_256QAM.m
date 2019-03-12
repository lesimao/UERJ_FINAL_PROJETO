% https://www.mathworks.com/help/comm/ug/transmit-and-receive-shortened-reed-solomon-codes.html?searchHighlight=Reed-Solomon&s_tid=doc_srchtitle
% Usado como referencia o código do link acima

%CÓDIGO REED SOLOMON - Código para simular diversos cenários de codificação
%de Canal RS em 5 constelações da modulação QAM.

M = [16 32 64 128 256];% Vetor Quantidade de simbolos total na Constelação por posição.
B = [4 5 6 7 8]; % Quantidade de bits por símbolo
Ka = [1 2 3 4 5]; % Vetor Simbolos de mensagem de informação
Na = [1 2 3 4 5] % Vetor Quantidade total de simbolos mensagem a ser enviada ao modulador

numErrors = 200; % Quantidade de erros acumulados para controle do Loop While
numBits = 1e5; % Quantidade de bits recebidos para controle do Loop While.
ebnoVec = (-5:0.5:20)'; % Faixa de varredura em Eb/No [Energia por bit/Potencia de ruído] do gráfico
ber0 = deal(zeros(size(ebnoVec))); % Criação de vetor com EbNoVec posições.

for j=1:length(M)
    
% Bloco para montagem do código Reed Solomon - RS(N,K)    
N = (2^B(j)) - 1; %Montando o código RS
Na(j) = N; %Montando o código RS
Mi=round(B(j)/2); %Montando o código RS
Paridade = 2^Mi; %Montando o código RS
K=N-Paridade; %Montando o código RS
Ka(j) = K; %Montando o código RS

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M(j),'BitInput',true,'NormalizationMethod','Average power'); % Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas variáveis de entrada
% O Modulador configurado em ordem da posição J do vetor M.
% Configurado para entrada em Bit
% Configurado o método de normalização de constelação em Média de Potência

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M(j),'BitOutput', true,'NormalizationMethod','Average power'); % Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas variáveis de entrada
% O Demodulador configurado em ordem da posição J do vetor M.
% Configurado para saída em Bit
% Configurado o método de normalização de constelação em Média de Potência

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posições de estatistica de comparação dos dados de entrada da transmissão com os dados de saída na recepção.

rsEncoder = comm.RSEncoder(N,K,'BitInput',true); % Criando objeto Codificador Reed Solomon, com configurações N [Palavra código], K[Informação] e entrada de bit ativada.

rsDecoder = comm.RSDecoder(N,K,'BitInput',true); % Criando objeto Decodificador Reed Solomon, com configurações N [Palavra código], K[Informação] e entrada de bit ativada.

rate = K/N; %Taxa do código Reed Solomon 

for k = 1:length(ebnoVec)
    
    snrdB = ebnoVec(k) + 10*log10(rate) + 10*log10(log2(M(j))); % Entender essa parte!!!!
    errorStats = zeros(3,1);
    
    while errorStats(2) < numErrors && errorStats(3) < numBits
        % Quantidade de erro < número de bits e quantidade de bits < núm de bits (1e^7)
        
        txData = randi([0 1],K*log2(M(j)),1); % Criação do vetor bit informação com tamanho K x Quantidade de simbolos total na Constelação
        
        encData = step(rsEncoder,txData); % Codificando a informação com código Reed Solomon e gerando a palavra código.
        
        txSig = step(qamModulator,encData); % Modulando em QAM a palavra código.
        
        rxSig = awgn(txSig,snrdB); % Atravessando o canal AWGN utilizando com referencia a relação SNR.
        
        demodSig = step(qamDemodulator,rxSig); % Demodulando em QAM a palavra código.

        rxData = step(rsDecoder,demodSig); % Decodificando a informação com código Reed Solomon e gerando a informação origem.
        
        errorStats = step(errorRate, txData, rxData); % Objeto criado errorRate compara os dados de origem com os dados na saida do decodificador e gera um vetor de estatistica.

    end
    
    ber0(k) = errorStats(1); % A primeira posição do vetor de estatistica errorStats é o percentual de bits errados recebidos, o mesmo é adicionado na posição k de BER.
    reset(errorRate); % Limpa o vetor objeto estatistico errorRate
    
end

%Geração dos gráficos Eb/No [energia do bit pela Potência de ruído] pelo
%BER [Bit Error Rate]
semilogy(ebnoVec,ber0,'o-')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid
hold on

end 

legend(['RS(' num2str(Na(1)) ',' num2str(Ka(1)) ')'],['RS(' num2str(Na(2)) ',' num2str(Ka(2)) ')'],['RS(' num2str(Na(3)) ',' num2str(Ka(3)) ')'],['RS(' num2str(Na(4)) ',' num2str(Ka(4)) ')'],['RS(' num2str(Na(5)) ',' num2str(Ka(5)) ')'], 'location','sw');
