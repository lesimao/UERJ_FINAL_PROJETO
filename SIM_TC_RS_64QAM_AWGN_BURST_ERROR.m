% C�digo para compara��o entre os c�digos Turbo e Reed Solomon para erro em
% rajadas!
% Modula��o 64QAM.

N = 63; % Tamanho da palavra c�digo 
K = 51; % Tamanho da mensagem
M = 64; % Quantidade de s�mbolos por constela��o em QAM

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power');% Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas vari�veis de entrada
% O Modulador configurado em ordem da posi��o J do vetor M.
% Configurado para entrada em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput', true,'NormalizationMethod','Average power');% Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas vari�veis de entrada
% O Demodulador configurado em ordem da posi��o J do vetor M.
% Configurado para sa�da em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posi��es de estatistica de compara��o dos dados de entrada da transmiss�o com os dados de sa�da na recep��o.

rsEncoder = comm.RSEncoder(N,K,'BitInput',true); % Criando objeto Codificador Reed Solomon, com configura��es N [Palavra c�digo], K[Informa��o] e entrada de bit ativada.

rsDecoder = comm.RSDecoder(N,K,'BitInput',true); % Criando objeto Decodificador Reed Solomon, com configura��es N [Palavra c�digo], K[Informa��o] e entrada de bit ativada.

rate = K/N; %Taxa do c�digo Reed Solomon 

errorStats = zeros(1,3); % Cria��o de um vetor de 3 posi��es para armazenar a estatisticas de BER
tic
for j = 1:2.65*10^3 
    
    txData = randi([0 1],K*log2(M),1); % Cria��o do vetor bit informa��o com tamanho K x Quantidade de simbolos total na Constela��o
        
    encData = step(rsEncoder,txData); % Codificando a informa��o com c�digo Reed Solomon e gerando a palavra c�digo.
        
    encData(1:36)=0; % Inser��o de uma rajada de 36 bits com erros
        
    txSig = step(qamModulator,encData); % Modulando em QAM
              
    demodSig = step(qamDemodulator,txSig); % Demodula��o em QAM 
                     
    rxData = step(rsDecoder,demodSig); % Decodifica��o do RS
        
    errorStats = step(errorRate, txData, rxData); % Avalia��o do BER (bit errror)

    end
toc
t1 = toc % Temporiza��o de processamento
Probabilidade_erro_BIT_RS = errorStats(1) %Probabilidade de Erro para rajada de 37 bits
    
%------------------------------------

bps = log2(M); % Bits por s�mbolo
frmLen = 408; % Tamanho do quadro 

turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port'); % Criando objeto codificador Turbo com entrele�ador

turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4); % Criando decodificador turbo com 4 itera��es e entrele�ador

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); % Criando objeto modulador 64QAM 

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput',true,'NormalizationMethod','Average power','DecisionMethod','Log-likelihood ratio','VarianceSource','Input port'); % Criando objeto demodulador 64QAM

errorRate = comm.ErrorRate; % Criando objeto para c�lculo BER

rate_tc = frmLen/(3*frmLen+4*3); % Taxa de transmiss�o do turbo c�digo

errorStats = zeros(1,3); % Cria��o de um vetor de 3 posi��es para armazenar a estatisticas de BER

EsNo = 20 + 10*log10(bps); % C�lculo de energia por s�mbolo       
snrdB = EsNo + 10*log10(rate_tc); % C�lculo de SNR
noiseVar = 1./(10.^(snrdB/10));  % C�lculo de vari�ncia

tic
    for k = 1:2.45*10^3;
        
        data = randi([0 1],frmLen,1); % Cria��o do vetor mensagem

        intrlvrInd = randperm(frmLen); % Cria��o do entrele�ador

        encodedData = step(turboEnc,data,intrlvrInd); % Atravessando a mensagem no codificador turbo

        encodedData(1:36)= 0; %Inserindo uma rajada de 36 erros.
        
        modSignal = step(qamModulator,encodedData); % Modulando 64QAM o sinal codificado
        
        demodSignal = step(qamDemodulator,modSignal,noiseVar); % Demodulando o sinal 64QAM

        receivedBits = step(turboDec,-demodSignal,intrlvrInd); % Decodificando utilizando turbo

        errorStats = step(errorRate,data,receivedBits); % C�lculo do BER
    end
toc
t2 = toc

Probabilidade_erro_BIT_TC = errorStats(1) % Apresenta��o do BER - Bit Error
reset(errorRate);



