function  Steppermotor()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
arduino = serialport("COM4", 9600); % puerto de comunicacion serial
pause(1); % Esperar que la conexión se establezca

% Enviar comando a Arduino
writeline(arduino, 'S'); % Envía 'S' para iniciar el movimiento
end