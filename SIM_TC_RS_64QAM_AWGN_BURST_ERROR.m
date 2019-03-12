% Código para comparação entre os códigos Turbo e Reed Solomon para erro em
% rajadas!
% Modulação 64QAM.

N = 63; % Tamanho da palavra código 
K = 51; % Tamanho da mensagem
M = 64; % Quantidade de símbolos por constelação em QAM

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power');% Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas variáveis de entrada
% O Modulador configurado em ordem da posição J do vetor M.
% Configurado para entrada em Bit
% Configurado o método de normalização de constelação em Média de Potência

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput', true,'NormalizationMethod','Average power');% Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas variáveis de entrada
% O Demodulador configurado em ordem da posição J do vetor M.
% Configurado para saída em Bit
% Configurado o método de normalização de constelação em Média de Potência

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posições de estatistica de comparação dos dados de entrada da transmissão com os dados de saída na recepção.

rsEncoder = comm.RSEncoder(N,K,'BitInput',true); % Criando objeto Codificador Reed Solomon, com configurações N [Palavra código], K[Informação] e entrada de bit ativada.

rsDecoder = comm.RSDecoder(N,K,'BitInput',true); % Criando objeto Decodificador Reed Solomon, com configurações N [Palavra código], K[Informação] e entrada de bit ativada.

rate = K/N; %Taxa do código Reed Solomon 

errorStats = zeros(1,3); % Criação de um vetor de 3 posições para armazenar a estatisticas de BER
tic
for j = 1:2.65*10^3 
    
    txData = randi([0 1],K*log2(M),1); % Criação do vetor bit informação com tamanho K x Quantidade de simbolos total na Constelação
        
    encData = step(rsEncoder,txData); % Codificando a informação com código Reed Solomon e gerando a palavra código.
        
    encData(1:36)=0; % Inserção de uma rajada de 36 bits com erros
        
    txSig = step(qamModulator,encData); % Modulando em QAM
              
    demodSig = step(qamDemodulator,txSig); % Demodulação em QAM 
                     
    rxData = step(rsDecoder,demodSig); % Decodificação do RS
        
    errorStats = step(errorRate, txData, rxData); % Avaliação do BER (bit errror)

    end
toc
t1 = toc % Temporização de processamento
Probabilidade_erro_BIT_RS = errorStats(1) %Probabilidade de Erro para rajada de 37 bits
    
%------------------------------------

bps = log2(M); % Bits por símbolo
frmLen = 408; % Tamanho do quadro 

turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port'); % Criando objeto codificador Turbo com entreleçador

turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4); % Criando decodificador turbo com 4 iterações e entreleçador

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); % Criando objeto modulador 64QAM 

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput',true,'NormalizationMethod','Average power','DecisionMethod','Log-likelihood ratio','VarianceSource','Input port'); % Criando objeto demodulador 64QAM

errorRate = comm.ErrorRate; % Criando objeto para cálculo BER

rate_tc = frmLen/(3*frmLen+4*3); % Taxa de transmissão do turbo código

errorStats = zeros(1,3); % Criação de um vetor de 3 posições para armazenar a estatisticas de BER

EsNo = 20 + 10*log10(bps); % Cálculo de energia por símbolo       
snrdB = EsNo + 10*log10(rate_tc); % Cálculo de SNR
noiseVar = 1./(10.^(snrdB/10));  % Cálculo de variância

tic
    for k = 1:2.45*10^3;
        
        data = randi([0 1],frmLen,1); % Criação do vetor mensagem

        intrlvrInd = randperm(frmLen); % Criação do entreleçador

        encodedData = step(turboEnc,data,intrlvrInd); % Atravessando a mensagem no codificador turbo

        encodedData(1:36)= 0; %Inserindo uma rajada de 36 erros.
        
        modSignal = step(qamModulator,encodedData); % Modulando 64QAM o sinal codificado
        
        demodSignal = step(qamDemodulator,modSignal,noiseVar); % Demodulando o sinal 64QAM

        receivedBits = step(turboDec,-demodSignal,intrlvrInd); % Decodificando utilizando turbo

        errorStats = step(errorRate,data,receivedBits); % Cálculo do BER
    end
toc
t2 = toc

Probabilidade_erro_BIT_TC = errorStats(1) % Apresentação do BER - Bit Error
reset(errorRate);



