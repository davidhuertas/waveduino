%% ANIMACIÓN 3D

%posPlot = pos;
posPlot = pos;
quatPlot = quat;

% Retrasa el final de la animación
extraTime = 0;
onesVector = ones(extraTime*(floor(1/dt)), 1);
posPlot = [posPlot; [posPlot(end, 1)*onesVector, posPlot(end, 2)*...
    onesVector, posPlot(end, 3)*onesVector]];
quatPlot = [quatPlot; [quatPlot(end, 1)*onesVector, quatPlot(end, 2)*...
    onesVector, quatPlot(end, 3)*onesVector, quatPlot(end, 4)*onesVector]];

% Crear la animación 3D
SamplePlotFreq = 12;
disp('Animación en')
disp('3')
pause(1)
disp('2')
pause(1)
disp('1')
pause(1)
disp('Animación...')
SixDOFanimation(posPlot, quatern2rotMat(quatPlot), ...
                'SamplePlotFreq', SamplePlotFreq, 'Trail', 'Off', ...
                'Position', [9 39 1280 768],...
                'AxisLength', 0.1, 'ShowArrowHead', false, ...
                'Xlabel', 'X (m)', 'Ylabel', 'Y (m)',...
                'Zlabel', 'Z (m)', 'ShowLegend', false, ...
                'CreateAVI', false, 'AVIfileNameEnum', false,...
                'AVIfps', (floor((floor(1/dt))...
                / SamplePlotFreq)));