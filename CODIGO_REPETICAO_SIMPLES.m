% Código de Repetição Simples
% Código do livro PROAKIS, John G. Contemporany Comunication Systems Using MATLAB. 03 ed. Cengage Learning, 2011.
echo on
ep=0.3;
for i=1 :2:61
p(i)=0;
for j=(i+ 1 )/2:i
p(i)=p(i)+prod(1 :i)/(prod(1 :j)*prod(1 :(i-j)))*ep^j*(1-ep)^(i-j);
echo off ;
end
end
echo on ;
figure
stem((1 :2:61 ),p(1 :2:61))
xlabel( 'n - Tamanho da Palavra Código ' )
grid on
ylabel('Pe - Probabilidade de Erro')
title('Probabilidade de erro como função de n - simples repetições')