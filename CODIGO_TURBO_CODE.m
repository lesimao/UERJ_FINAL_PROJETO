%https://www.mathworks.com/help/comm/ug/estimate-turbo-code-ber-performance-in-awgn.html
%[Refer�ncia utilizada acima]

%TURBO CODE 

M = 64; % N�mero de s�mbolos na constela��o
bps = log2(M); % Quantidade de bits por s�mbolo
EbNo = (-5:0.5:20); %Varredura da Energia por bit/Pot�ncia de ru�do
frmLen = 500; %Tamanho do quadro a ser transmitido

ber = zeros(size(EbNo)); %Vetor para armazenar o BER, baseado no tamanho do vetor Eb/No.

turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port'); %Criando o objeto Turbo Code, resumindo, criando o codificador Turbo definindo as suas vari�veis de entrada
% O Entrele�ador configurado no c�digo Turbo.

turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4); %Criando o objeto Turbo Decode, resumindo, criando o Decodificador Turbo definindo as suas vari�veis de entrada
% O Entrele�ador configurado no decoficador turbo.
% N�mero Itera��es configurado para 4.

qamModulator = comm.RectangularQAMModulator('ModulationOrder',M,'BitInput',true,'NormalizationMethod','Average power'); %Criando o objeto Modulador QAM, resumindo, criando o modulador QAM e definindo as suas vari�veis de entrada
% O Modulador configurado em ordem M.
% Configurado para entrada em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia

qamDemodulator = comm.RectangularQAMDemodulator('ModulationOrder',M,'BitOutput',true,'NormalizationMethod','Average power','DecisionMethod','Log-likelihood ratio','VarianceSource','Input port'); %Criando o objeto Demodulador QAM, resumindo, criando o demoduolador QAM definindo as suas vari�veis de entrada
% O Demodulador configurado em ordem M.
% Configurado para sa�da em Bit
% Configurado o m�todo de normaliza��o de constela��o em M�dia de Pot�ncia
% Configurado o m�todo de decis�o em Log-likelihood ratio - LLR
% Configurado a fonte de variancia de ru�do.

awgnChannel = comm.AWGNChannel('NoiseMethod','Variance','Variance',1); % Criando objeto Canal AWGN, resumindo, criando o canal AWGN e seus par�metros.
% Configurado o level de ru�do para Variancia

errorRate = comm.ErrorRate; % Criando objeto ErrorRate, objeto extramamente importante, pois gera um vetor acumulativo de 3 posi��es de estatistica de compara��o dos dados de entrada da transmiss�o com os dados de sa�da na recep��o.

rate = frmLen/(3*frmLen+4*3); %Calculo da taxa baseado no codificador padr�o Turbo, com treli�a padr�o poly2trellis(4, [13 15], 13). [https://www.mathworks.com/help/comm/ref/turboencoder.html]
% Em rela��o a Taxa, um vetor de 64 bits de entrada gera um vetor de sa�da
% de 204 bits, dos quais 192 bits s�o referentes a 3 fluxos de 64 bits
% referente ao bit informa��o, bit de paridade do primeiro codificador
% convolucional e o bit de paridade de paridade do secundo codificador
% convolucional.

for k = 1:length(EbNo); %Loop para varrer a Eb/No de -5 a 20
    
    errorStats = zeros(1,3); % Cria��o de um vetor de 3 posi��es para armazenar a estatisticas de BER

    EsNo = EbNo(k) + 10*log10(bps); %Energia do s�mbolo/Pot�ncia de ru�do � equivalente a soma em dB do Eb/No mais quantidade de bits por simbolo em dB.       
    snrdB = EsNo + 10*log10(rate); % ENTENDER!!!!
    noiseVar = 1./(10.^(snrdB/10)); % ENTENDER!!!!

    awgnChannel.Variance = noiseVar; % A variancia do ru�do referente ao Eb/No � adicionado ao canal AWGN
    
    %Loop continuar� enquando a quantidade de error for menor que 100 -E-
    %quantidade de bits recebidos for menor que 100.000 bits.
    while errorStats(2) < 100 && errorStats(3) < 1e5;

        data = randi([0 1],frmLen,1); %Cria��o aleat�ria da informa��o origem com o tamanho do quadro

        intrlvrInd = randperm(frmLen); %Cria��o dos indices do Entrela�ador em rela��o ao tamanho do quadro. A fun��o randperm cria um vetor de 1 a N em ordem aleat�ria.
       
        encodedData = step(turboEnc,data,intrlvrInd); %Codifica��o Turbo com entrela�ador criado no item anterior na informa��o origem.

        modSignal = step(qamModulator,encodedData); %Modula��o 64QAM no dado codificado.

        receivedSignal = step(awgnChannel,modSignal); %O sinal modulado atravessa o canal AWGN

        demodSignal = step(qamDemodulator,receivedSignal,noiseVar); %Demodula��o do sinal modulado em 64QAM

        receivedBits = step(turboDec,-demodSignal,intrlvrInd); %Decodificador Turbo, o mesmo aguarda o sinal inverso da demodula��o 64QAM.

        errorStats = step(errorRate,data,receivedBits); %Objeto criado errorRate compara os dados de origem com os dados na saida do decodificador e gera um vetor de estatistica.
    end
    
    ber(k) = errorStats(1); %A primeira posi��o do vetor de estatistica errorStats � o percentual de bits errados recebidos, o mesmo � adicionado na posi��o k de BER.
    reset(errorRate); %Limpa o vetor objeto estatistico errorRate
end

%Gera��o dos gr�ficos Eb/No [energia do bit pela Pot�ncia de ru�do] pelo
%BER [Bit Error Rate]
semilogy(EbNo,ber,'-o');
grid
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate');
uncodedBER = berawgn(EbNo,'qam',M);     %Gera��o do gr�fico Eb/No pelo BER de transmiss�o sem codifica��o.
hold on
semilogy(EbNo,uncodedBER);
legend('Turbo','Uncoded','location','sw');
