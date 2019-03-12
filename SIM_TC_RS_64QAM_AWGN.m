% C�digo para an�lise entre c�digos de Canal Reed Solomon e Turbo.

N = 63;  % Tamanho da palavra c�digo
K = 51;  % Tamanho da mensagem
M = 64;  % Quantidade de simbolos da constela��o

numErrors = 200; % Quantidade de erros acumulados para controle do Loop While
numBits = 1e5; % Quantidade de bits recebidos para controle do Loop While.
ebnoVec = (-5:0.5:20)'; % Faixa de varredura em Eb/No [Energia por bit/Potencia de ru�do] do gr�fico
ber0 = deal(zeros(size(ebnoVec))); % Cria��o de vetor com EbNoVec posi��es.

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); % Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas vari�veis de entrada
% O Modulador configurado em ordem M.
% Configurado para entrada em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput', true,'NormalizationMethod','Average power'); % Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas vari�veis de entrada
% O Demodulador configurado em ordem M.
% Configurado para sa�da em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posi��es de estatistica de compara��o dos dados de entrada da transmiss�o com os dados de sa�da na recep��o.

rsEncoder = comm.RSEncoder(N,K,'BitInput',true); % Criando objeto Codificador Reed Solomon, com configura��es N [Palavra c�digo], K[Informa��o] e entrada de bit ativada.

rsDecoder = comm.RSDecoder(N,K,'BitInput',true); % Criando objeto Decodificador Reed Solomon, com configura��es N [Palavra c�digo], K[Informa��o] e entrada de bit ativada.

rate = K/N; %Taxa do c�digo Reed Solomon 

for k = 1:length(ebnoVec)
    
    snrdB = ebnoVec(k) + 10*log10(rate) + 10*log10(log2(M)); % Entender isso!!!
    errorStats = zeros(3,1); 

    while errorStats(2) < numErrors && errorStats(3) < numBits
        % Quantidade de erro < n�mero de bits e quantidade de bits < n�m de bits (1e^7)
        
        txData = randi([0 1],K*log2(M),1); % Cria��o do vetor bit informa��o com tamanho K x Quantidade de simbolos total na Constela��o
        
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

% Cria��o do gr�fico Reed Solomon
semilogy(ebnoVec,ber0,'o-')
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
grid
hold on

bps = log2(M); % Quantidade de Bits por S�mbolos
EbNo = (-5:0.5:20); %Varredura da Energia por bit/Pot�ncia de ru�do
frmLen = 500; %Tamanho do quadro a ser transmitido

ber = zeros(size(EbNo)); %Vetor para armazenar o BER, baseado no tamanho do vetor Eb/No.

turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port');%Criando o objeto Turbo Code, resumindo, criando o codificador Turbo definindo as suas vari�veis de entrada
% O Entrele�ador configurado no c�digo Turbo.

turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4);%Criando o objeto Turbo Decode, resumindo, criando o Decodificador Turbo definindo as suas vari�veis de entrada
% O Entrele�ador configurado no decoficador turbo.
% N�mero Itera��es configurado para 4.

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); % Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas vari�veis de entrada
% O Modulador configurado em ordem M.
% Configurado para entrada em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput',true,'NormalizationMethod','Average power','DecisionMethod','Log-likelihood ratio','VarianceSource','Input port'); %Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas vari�veis de entrada
% O Demodulador configurado em ordem M.
% Configurado para sa�da em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia
% Configurado o m�todo de decis�o em Log-likelihood ratio - LLR
% Configurado a fonte de variancia de ru�do.

awgnChannel = comm.AWGNChannel('NoiseMethod','Variance','Variance',1);% Criando objeto Canal AWGN, resumindo, criando o canal AWGN e seus par�metros.
% Configurado o level de ru�do para Variancia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posi��es de estatistica de compara��o dos dados de entrada da transmiss�o com os dados de sa�da na recep��o.

rate_tc = frmLen/(3*frmLen+4*3);%Calculo da taxa baseado no codificador padr�o Turbo, com treli�a padr�o poly2trellis(4, [13 15], 13). [https://www.mathworks.com/help/comm/ref/turboencoder.html]
% Em rela��o a Taxa, um vetor de 64 bits de entrada gera um vetor de sa�da
% de 204 bits, dos quais 192 bits s�o referentes a 3 fluxos de 64 bits
% referente ao bit informa��o, bit de paridade do primeiro codificador
% convolucional e o bit de paridade de paridade do secundo codificador
% convolucional.

for k = 1:length(EbNo); %Loop para varrer a Eb/No de -5 a 20
    
    errorStats = zeros(1,3); % Cria��o de um vetor de 3 posi��es para armazenar a estatisticas de BER

    EsNo = EbNo(k) + 10*log10(bps); % Energia do s�mbolo/Pot�ncia de ru�do � equivalente a soma em dB do Eb/No mais quantidade de bits por simbolo em dB.    
    snrdB = EsNo + 10*log10(rate_tc); % ENTENDER!!!!
    noiseVar = 1./(10.^(snrdB/10)); % ENTENDER!!!!

    awgnChannel.Variance = noiseVar; % A variancia do ru�do referente ao Eb/No � adicionado ao canal AWGN

    %Loop continuar� enquando a quantidade de error for menor que 100 -E-
    %quantidade de bits recebidos for menor que 100.000 bits.
    while errorStats(2) < 100 && errorStats(3) < 1e5;

        data = randi([0 1],frmLen,1); % Cria��o aleat�ria da informa��o origem com o tamanho do quadro

        intrlvrInd = randperm(frmLen); %Cria��o dos indices do Entrela�ador em rela��o ao tamanho do quadro. A fun��o randperm cria um vetor de 1 a N em ordem aleat�ria.

        encodedData = step(turboEnc,data,intrlvrInd); % Codifica��o Turbo com entrela�ador criado no item anterior na informa��o origem.

        modSignal = step(qamModulator,encodedData); % Modula��o 64QAM no dado codificado.

        receivedSignal = step(awgnChannel,modSignal); %O sinal modulado atravessa o canal AWGN

        demodSignal = step(qamDemodulator,receivedSignal,noiseVar); %Demodula��o do sinal modulado em 64QAM

        receivedBits = step(turboDec,-demodSignal,intrlvrInd); %Decodificador Turbo, o mesmo aguarda o sinal inverso da demodula��o 64QAM.

        errorStats = step(errorRate,data,receivedBits); % Objeto criado errorRate compara os dados de origem com os dados na saida do decodificador e gera um vetor de estatistica.
    end
    
    ber(k) = errorStats(1); % A primeira posi��o do vetor de estatistica errorStats � o percentual de bits errados recebidos, o mesmo � adicionado na posi��o k de BER.
    reset(errorRate); % Limpa o vetor objeto estatistico errorRate
    
end

% Gera��o do gr�fico do c�digo Turbo
semilogy(EbNo,ber,'-o');
grid on
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate');
legend('RS(63,51)','Turbo','location','sw');
