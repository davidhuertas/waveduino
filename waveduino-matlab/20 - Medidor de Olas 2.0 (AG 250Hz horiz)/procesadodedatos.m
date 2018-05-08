%% DETECTAR ACELERACIONES NULAS

% Busca las aceleraciones cercanas al cero (dentro del umbral de
% aceleraci�n nula), y crea una variable l�gica que avisa de si el muestreo
% est� o no en la zona del umbral

% C�lculo del m�dulo de la aceleraci�n
ac_mod = sqrt(ax.*ax + ay.*ay + az.*az);

% Filtro Paso Alto a la aceleraci�n
frecCorte = 0.001;
[b, a] = butter(1, (2*frecCorte)/(1/dt), 'high');
ac_modFilt = filtfilt(b, a, ac_mod);

% C�lculo del valor absoluto de la aceleraci�n filtrada
ac_modFilt = abs(ac_modFilt);

% Filtro Paso Bajo a la aceleraci�n
frecCorte = 5;
[b, a] = butter(1, (2*frecCorte)/(1/dt), 'low');
ac_modFilt = filtfilt(b, a, ac_modFilt);

% Detecci�n de los datos por debajo del umbral
umbral = ac_modFilt < 0.02;

%% REPRESENTAR DATOS DEL ACELER�METRO Y DEL GIROSCOPIO

% Adem�s se representa el m�dulo de la aceleraci�n filtrada y los tramos de
% datos por debajo del umbral.

figure('Position', [9 39 900 600], 'Number', 'off', 'Name',...
    'Datos del Sensor');
sensor(1) = subplot(2,1,1);
    hold on;
    plot(tiempo, gx, 'r');
    plot(tiempo, gy, 'g');
    plot(tiempo, gz, 'b');
    title('Giroscopio');
    xlabel('Tiempo (s)');
    ylabel('Velocidad angular (rad/s)');
    legend('X', 'Y', 'Z');
    hold off;
sensor(2) = subplot(2,1,2);
    hold on;
    plot(tiempo, ax, 'r');
    plot(tiempo, ay, 'g');
    plot(tiempo, az, 'b');
    plot(tiempo, ac_modFilt, ':k');
    plot(tiempo, umbral, 'k', 'LineWidth', 2);
    title('Aceler�metro');
    xlabel('Tiempo (s)');
    ylabel('Aceleraci�n (g)');
    legend('X', 'Y', 'Z', 'Acel. Filtrada', 'Umbral');
    hold off;
linkaxes(sensor,'x');

%% CALCULAR ORIENTACI�N

quat = zeros(length(tiempo), 4);
AHRSalgorithm = AHRS('SamplePeriod', 1/256, 'Kp', 1, 'KpInit', 1);

% Convergencia inicial
tConvInicial = 0;
sel = 1 : find(sign(tiempo-(tiempo(1)+tConvInicial))+1, 1);
for i = 1:2000
    AHRSalgorithm.UpdateIMU([0 0 0], [mean(ax(sel)) mean(ay(sel)) mean(az(sel))]);
end

% Orientaci�n de todos los datos
for t = 1:length(tiempo)
    if(umbral(t))
        AHRSalgorithm.Kp = 0.5;
    else
        AHRSalgorithm.Kp = 0;
    end
    AHRSalgorithm.UpdateIMU(deg2rad([gx(t) gy(t) gz(t)]), [ax(t) ay(t) az(t)]);
    quat(t,:) = AHRSalgorithm.Quaternion;
end

%% CALCULAR ACELERACIONES DE TRASLACI�N EN EJES ABSOLUTOS

% Aplicar rotaci�n por cuaterniones
acel = quaternRotate([ax ay az], quaternConj(quat));

% Convertir a m/s�
acel = acel * 9.81;

% Representar aceleraciones frente al tiempo
figure('Position', [9 39 900 300], 'Number', 'off', 'Name',...
    'Aceleraciones absolutas');
hold on;
plot(tiempo, acel(:,1), 'r');
plot(tiempo, acel(:,2), 'g');
plot(tiempo, acel(:,3), 'b');
title('Aceleraciones absolutas');
xlabel('Tiempo (s)');
ylabel('Aceleraci�n (m/s�)');
legend('X', 'Y', 'Z');
hold off;

%% CALCULAR VELOCIDADES

acel(:,3) = acel(:,3) - 9.81; % Sustraer la gravedad de la aceleraci�n en z

% Integrar la aceleraci�n para obtener la velocidad. Iguala a cero los
% valores situados por debajo del umbral de aceleraci�n nula.

vel = zeros(size(acel));
for t = 2:length(vel)
    vel(t,:) = vel(t-1,:) + acel(t,:) * dt;
    if(umbral(t) == 1)
        vel(t,:) = [0 0 0];
    end
end


% Calcular el error de integraci�n de las velocidades tras el umbral

errorVel = zeros(size(vel));
inicioUmbral = find([0; diff(umbral)] == -1);
finUmbral = find([0; diff(umbral)] == 1);

if length(inicioUmbral)<length(finUmbral)
    inicioUmbral=[0; inicioUmbral];
elseif length(inicioUmbral)>length(finUmbral)
    finUmbral=[finUmbral; n];
end

for i = 1:numel(finUmbral)
    errorEstim = vel(finUmbral(i)-1, :) /...
        (finUmbral(i) - inicioUmbral(i));
    enum = 1:(finUmbral(i) - inicioUmbral(i));
    error = [enum'*errorEstim(1) enum'*errorEstim(2) enum'*errorEstim(3)];
    if (inicioUmbral(i)-finUmbral(i))>0
        errorVel(inicioUmbral(i):finUmbral(i)-1, :) = error;
    end
end

% Eliminar el error de integraci�n
vel = vel - errorVel;

% Representar velocidades frente al tiempo
figure('Position', [9 39 900 300], 'Number', 'off', 'Name', 'Velocidades');
hold on;
plot(tiempo, vel(:,1), 'r');
plot(tiempo, vel(:,2), 'g');
plot(tiempo, vel(:,3), 'b');
title('Velocidades');
xlabel('Tiempo (s)');
ylabel('Velocidad (m/s)');
legend('X', 'Y', 'Z');
hold off;

%% CALCULAR POSICIONES

% Integrar la velocidad para obtener la posici�n
pos = zeros(size(vel));
for t = 2:length(pos)
    pos(t,:) = pos(t-1,:) + vel(t,:) * dt;
end

% Representa la posici�n frente al tiempo
figure('Position', [9 39 900 600], 'Number', 'off', 'Name', 'Posiciones');
hold on;
plot(tiempo, pos(:,1), 'r');
plot(tiempo, pos(:,2), 'g');
plot(tiempo, pos(:,3), 'b');
title('Posiciones');
xlabel('Tiempo (s)');
ylabel('Posici�n (m)');
legend('X', 'Y', 'Z');
hold off;

% Aplica un filtro de paso alto para eliminar el error. �sto hace que
% siempre que se quede quieto se desplace lentamente hacia el origen.

orden = 1;
frecCorte = 0.8;
[b, a] = butter(orden, (2*frecCorte)/(1/dt), 'high');
posHP = filtfilt(b, a, pos);

% Representa la posici�n filtrada frente al tiempo
figure('Number', 'off', 'Name', 'Posici�n filtrada');
hold on;
plot(tiempo, posHP(:,1), 'r');
plot(tiempo, posHP(:,2), 'g');
plot(tiempo, posHP(:,3), 'b');
xlabel('Tiempo (s)');
ylabel('Posicion (m)');
title('Posici�n filtrada');
legend('X', 'Y', 'Z');

%% ANIMACI�N 3D

%posPlot = pos;
posPlot = posHP;
quatPlot = quat;

% Retrasa el final de la animaci�n
extraTime = 0;
onesVector = ones(extraTime*(floor(1/dt)), 1);
posPlot = [posPlot; [posPlot(end, 1)*onesVector, posPlot(end, 2)*...
    onesVector, posPlot(end, 3)*onesVector]];
quatPlot = [quatPlot; [quatPlot(end, 1)*onesVector, quatPlot(end, 2)*...
    onesVector, quatPlot(end, 3)*onesVector, quatPlot(end, 4)*onesVector]];

% Crear la animaci�n 3D
SamplePlotFreq = 12;
disp('Animaci�n en')
disp('3')
pause(1)
disp('2')
pause(1)
disp('1')
pause(1)
disp('Animaci�n...')
SixDOFanimation(posPlot, quatern2rotMat(quatPlot), ...
                'SamplePlotFreq', SamplePlotFreq, 'Trail', 'Off', ...
                'Position', [9 39 1280 768],...
                'AxisLength', 0.1, 'ShowArrowHead', false, ...
                'Xlabel', 'X (m)', 'Ylabel', 'Y (m)',...
                'Zlabel', 'Z (m)', 'ShowLegend', false, ...
                'CreateAVI', false, 'AVIfileNameEnum', false,...
                'AVIfps', (floor((floor(1/dt))...
                / SamplePlotFreq)));