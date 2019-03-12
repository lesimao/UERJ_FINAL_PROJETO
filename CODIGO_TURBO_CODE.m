%https://www.mathworks.com/help/comm/ug/estimate-turbo-code-ber-performance-in-awgn.html
%[Referência utilizada acima]

%TURBO CODE 

M = 64; % Número de símbolos na constelação
bps = log2(M); % Quantidade de bits por símbolo
EbNo = (-5:0.5:20); %Varredura da Energia por bit/Potência de ruído
frmLen = 500; %Tamanho do quadro a ser transmitido

ber = zeros(size(EbNo)); %Vetor para armazenar o BER, baseado no tamanho do vetor Eb/No.

turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port'); %Criando o objeto Turbo Code, resumindo, criando o codificador Turbo definindo as suas variáveis de entrada
% O Entreleçador configurado no código Turbo.

turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4); %Criando o objeto Turbo Decode, resumindo, criando o Decodificador Turbo definindo as suas variáveis de entrada
% O Entreleçador configurado no decoficador turbo.
% Número Iterações configurado para 4.

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); %Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas variáveis de entrada
% O Modulador configurado em ordem M.
% Configurado para entrada em Bit
% Configurado o método de normalização de constelação em Média de Potência

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput',true,'NormalizationMethod','Average power','DecisionMethod','Log-likelihood ratio','VarianceSource','Input port'); %Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas variáveis de entrada
% O Demodulador configurado em ordem M.
% Configurado para saída em Bit
% Configurado o método de normalização de constelação em Média de Potência
% Configurado o método de decisão em Log-likelihood ratio - LLR
% Configurado a fonte de variancia de ruído.

awgnChannel = comm.AWGNChannel('NoiseMethod','Variance','Variance',1); % Criando objeto Canal AWGN, resumindo, criando o canal AWGN e seus parâmetros.
% Configurado o level de ruído para Variancia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posições de estatistica de comparação dos dados de entrada da transmissão com os dados de saída na recepção.

rate = frmLen/(3*frmLen+4*3); %Calculo da taxa baseado no codificador padrão Turbo, com treliça padrão poly2trellis(4, [13 15], 13). [https://www.mathworks.com/help/comm/ref/turboencoder.html]
% Em relação a Taxa, um vetor de 64 bits de entrada gera um vetor de saída
% de 204 bits, dos quais 192 bits são referentes a 3 fluxos de 64 bits
% referente ao bit informação, bit de paridade do primeiro codificador
% convolucional e o bit de paridade de paridade do secundo codificador
% convolucional.

for k = 1:length(EbNo); %Loop para varrer a Eb/No de -5 a 20
    
    errorStats = zeros(1,3); % Criação de um vetor de 3 posições para armazenar a estatisticas de BER

    EsNo = EbNo(k) + 10*log10(bps); %Energia do símbolo/Potência de ruído é equivalente a soma em dB do Eb/No mais quantidade de bits por simbolo em dB.       
    snrdB = EsNo + 10*log10(rate); % ENTENDER!!!!
    noiseVar = 1./(10.^(snrdB/10)); % ENTENDER!!!!

    awgnChannel.Variance = noiseVar; % A variancia do ruído referente ao Eb/No é adicionado ao canal AWGN
    
    %Loop continuará enquando a quantidade de error for menor que 100 -E-
    %quantidade de bits recebidos for menor que 100.000 bits.
    while errorStats(2) < 100 && errorStats(3) < 1e5;

        data = randi([0 1],frmLen,1); %Criação aleatória da informação origem com o tamanho do quadro

        intrlvrInd = randperm(frmLen); %Criação dos indices do Entrelaçador em relação ao tamanho do quadro. A função randperm cria um vetor de 1 a N em ordem aleatória.
       
        encodedData = step(turboEnc,data,intrlvrInd); %Codificação Turbo com entrelaçador criado no item anterior na informação origem.

        modSignal = step(qamModulator,encodedData); %Modulação 64QAM no dado codificado.

        receivedSignal = step(awgnChannel,modSignal); %O sinal modulado atravessa o canal AWGN

        demodSignal = step(qamDemodulator,receivedSignal,noiseVar); %Demodulação do sinal modulado em 64QAM

        receivedBits = step(turboDec,-demodSignal,intrlvrInd); %Decodificador Turbo, o mesmo aguarda o sinal inverso da demodulação 64QAM.

        errorStats = step(errorRate,data,receivedBits); %Objeto criado errorRate compara os dados de origem com os dados na saida do decodificador e gera um vetor de estatistica.
    end
    
    ber(k) = errorStats(1); %A primeira posição do vetor de estatistica errorStats é o percentual de bits errados recebidos, o mesmo é adicionado na posição k de BER.
    reset(errorRate); %Limpa o vetor objeto estatistico errorRate
end

%Geração dos gráficos Eb/No [energia do bit pela Potência de ruído] pelo
%BER [Bit Error Rate]
semilogy(EbNo,ber,'-o');
grid
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate');
uncodedBER = berawgn(EbNo,'qam',M);     %Geração do gráfico Eb/No pelo BER de transmissão sem codificação.
hold on
semilogy(EbNo,uncodedBER);
legend('Turbo','Uncoded','location','sw');
