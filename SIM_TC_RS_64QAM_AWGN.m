% Código para análise entre códigos de Canal Reed Solomon e Turbo.

N = 63;  % Tamanho da palavra código
K = 51;  % Tamanho da mensagem
M = 64;  % Quantidade de simbolos da constelação

numErrors = 200; % Quantidade de erros acumulados para controle do Loop While
numBits = 1e5; % Quantidade de bits recebidos para controle do Loop While.
ebnoVec = (-5:0.5:20)'; % Faixa de varredura em Eb/No [Energia por bit/Potencia de ruído] do gráfico
ber0 = deal(zeros(size(ebnoVec))); % Criação de vetor com EbNoVec posições.

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); % Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas variáveis de entrada
% O Modulador configurado em ordem M.
% Configurado para entrada em Bit
% Configurado o método de normalização de constelação em Média de Potência

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput', true,'NormalizationMethod','Average power'); % Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas variáveis de entrada
% O Demodulador configurado em ordem M.
% Configurado para saída em Bit
% Configurado o método de normalização de constelação em Média de Potência

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posições de estatistica de comparação dos dados de entrada da transmissão com os dados de saída na recepção.

rsEncoder = comm.RSEncoder(N,K,'BitInput',true); % Criando objeto Codificador Reed Solomon, com configurações N [Palavra código], K[Informação] e entrada de bit ativada.

rsDecoder = comm.RSDecoder(N,K,'BitInput',true); % Criando objeto Decodificador Reed Solomon, com configurações N [Palavra código], K[Informação] e entrada de bit ativada.

rate = K/N; %Taxa do código Reed Solomon 

for k = 1:length(ebnoVec)
    
    snrdB = ebnoVec(k) + 10*log10(rate) + 10*log10(log2(M)); % Entender isso!!!
    errorStats = zeros(3,1); 

    while errorStats(2) < numErrors && errorStats(3) < numBits
        % Quantidade de erro < número de bits e quantidade de bits < núm de bits (1e^7)
        
        txData = randi([0 1],K*log2(M),1); % Criação do vetor bit informação com tamanho K x Quantidade de simbolos total na Constelação
        
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

% Criação do gráfico Reed Solomon
semilogy(ebnoVec,ber0,'o-')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid
hold on

bps = log2(M); % Quantidade de Bits por Símbolos
EbNo = (-5:0.5:20); %Varredura da Energia por bit/Potência de ruído
frmLen = 500; %Tamanho do quadro a ser transmitido

ber = zeros(size(EbNo)); %Vetor para armazenar o BER, baseado no tamanho do vetor Eb/No.

turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port');%Criando o objeto Turbo Code, resumindo, criando o codificador Turbo definindo as suas variáveis de entrada
% O Entreleçador configurado no código Turbo.

turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4);%Criando o objeto Turbo Decode, resumindo, criando o Decodificador Turbo definindo as suas variáveis de entrada
% O Entreleçador configurado no decoficador turbo.
% Número Iterações configurado para 4.

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); % Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas variáveis de entrada
% O Modulador configurado em ordem M.
% Configurado para entrada em Bit
% Configurado o método de normalização de constelação em Média de Potência

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput',true,'NormalizationMethod','Average power','DecisionMethod','Log-likelihood ratio','VarianceSource','Input port'); %Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas variáveis de entrada
% O Demodulador configurado em ordem M.
% Configurado para saída em Bit
% Configurado o método de normalização de constelação em Média de Potência
% Configurado o método de decisão em Log-likelihood ratio - LLR
% Configurado a fonte de variancia de ruído.

awgnChannel = comm.AWGNChannel('NoiseMethod','Variance','Variance',1);% Criando objeto Canal AWGN, resumindo, criando o canal AWGN e seus parâmetros.
% Configurado o level de ruído para Variancia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posições de estatistica de comparação dos dados de entrada da transmissão com os dados de saída na recepção.

rate_tc = frmLen/(3*frmLen+4*3);%Calculo da taxa baseado no codificador padrão Turbo, com treliça padrão poly2trellis(4, [13 15], 13). [https://www.mathworks.com/help/comm/ref/turboencoder.html]
% Em relação a Taxa, um vetor de 64 bits de entrada gera um vetor de saída
% de 204 bits, dos quais 192 bits são referentes a 3 fluxos de 64 bits
% referente ao bit informação, bit de paridade do primeiro codificador
% convolucional e o bit de paridade de paridade do secundo codificador
% convolucional.

for k = 1:length(EbNo); %Loop para varrer a Eb/No de -5 a 20
    
    errorStats = zeros(1,3); % Criação de um vetor de 3 posições para armazenar a estatisticas de BER

    EsNo = EbNo(k) + 10*log10(bps); % Energia do símbolo/Potência de ruído é equivalente a soma em dB do Eb/No mais quantidade de bits por simbolo em dB.    
    snrdB = EsNo + 10*log10(rate_tc); % ENTENDER!!!!
    noiseVar = 1./(10.^(snrdB/10)); % ENTENDER!!!!

    awgnChannel.Variance = noiseVar; % A variancia do ruído referente ao Eb/No é adicionado ao canal AWGN

    %Loop continuará enquando a quantidade de error for menor que 100 -E-
    %quantidade de bits recebidos for menor que 100.000 bits.
    while errorStats(2) < 100 && errorStats(3) < 1e5;

        data = randi([0 1],frmLen,1); % Criação aleatória da informação origem com o tamanho do quadro

        intrlvrInd = randperm(frmLen); %Criação dos indices do Entrelaçador em relação ao tamanho do quadro. A função randperm cria um vetor de 1 a N em ordem aleatória.

        encodedData = step(turboEnc,data,intrlvrInd); % Codificação Turbo com entrelaçador criado no item anterior na informação origem.

        modSignal = step(qamModulator,encodedData); % Modulação 64QAM no dado codificado.

        receivedSignal = step(awgnChannel,modSignal); %O sinal modulado atravessa o canal AWGN

        demodSignal = step(qamDemodulator,receivedSignal,noiseVar); %Demodulação do sinal modulado em 64QAM

        receivedBits = step(turboDec,-demodSignal,intrlvrInd); %Decodificador Turbo, o mesmo aguarda o sinal inverso da demodulação 64QAM.

        errorStats = step(errorRate,data,receivedBits); % Objeto criado errorRate compara os dados de origem com os dados na saida do decodificador e gera um vetor de estatistica.
    end
    
    ber(k) = errorStats(1); % A primeira posição do vetor de estatistica errorStats é o percentual de bits errados recebidos, o mesmo é adicionado na posição k de BER.
    reset(errorRate); % Limpa o vetor objeto estatistico errorRate
    
end

% Geração do gráfico do código Turbo
semilogy(EbNo,ber,'-o');
grid on
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate');
legend('RS(63,51)','Turbo','location','sw');
