%% task_5.m
% Script that:
% 1) Disables algebraic loop messages
% 2) Sweeps thrust Ft
% 3) Picks the best result
% 4) Sweeps Mb
% 5) Prints all results neatly

clc; clear; close all;

% 0) Suppress algebraic loop messages for the Simulink model
set_param('human_transpoter_systemModel','AlgebraicLoopMsg','none');

% === 1) Define system parameters ===
M    = 35;            
Mu   = 66; 
Mb   = 1.5;          % Default base mass
Lg   = 1; 
Lb   = 1;
Ig_w = 0.02;       
Ig_u = 20;         
R    = 0.127;         
g    = 9.81;              

% Derived constants (if your Simulink model references them)
C1 = M + Ig_w/(R^2) + Mu;
C2 = Mu * Lg;
C4 = Mu * Lg^2 + Ig_u;
C5 = Mu * Lg;

% Assign them into base workspace if needed by your model
assignin('base','M',    M);
assignin('base','Mu',   Mu);
assignin('base','Mb',   Mb);
assignin('base','Lg',   Lg);
assignin('base','Lb',   Lb);
assignin('base','Ig_w', Ig_w);
assignin('base','Ig_u', Ig_u);
assignin('base','R',    R);
assignin('base','g',    g);

assignin('base','C1',   C1);
assignin('base','C2',   C2);
assignin('base','C4',   C4);
assignin('base','C5',   C5);

% === 2) Range of Ft values ===
beta = 0.5;            % Lean angle
assignin('base','beta', beta);
Ft_values = 300 : 0.1 : 700; 

% We'll store results as [Ft, finalX, tippedFlag]
results = [];

% === 3) Loop over Ft and run the model ===
for currentFt = Ft_values
    
    % Assign Ft in base for the model
    assignin('base','Ft', currentFt);

    % Run the Simulink model (StopTime=10s)
    simOut = sim('human_transpoter_systemModel', ...
                 'StopTime', '10', ...
                 'ReturnWorkspaceOutputs','on');

    % Extract x(t) and theta(t) from your logged signals
    % Adjust if your logging names differ
    x_struct     = simOut.simout;     
    theta_struct = simOut.simout1;    

    x_vals       = x_struct.signals.values;
    theta_vals   = theta_struct.signals.values;

    % Tipping threshold ±90°
    tip_threshold = pi/2;

    % Find first index where |theta| >= 90°
    tipping_idx = find(abs(theta_vals) >= tip_threshold, 1);

    if ~isempty(tipping_idx)
        % The system tips
        if tipping_idx == 1
            final_x = x_vals(1); % Tipped right away
        else
            final_x = x_vals(tipping_idx - 1);
        end
        tippedFlag = 1;
    else
        % Never tipped within sim time
        final_x   = x_vals(end);
        tippedFlag= 0;
    end

    % Keep only runs that end 5–10m
    if (final_x >= 5) && (final_x <= 10)
        results = [results; currentFt, final_x, tippedFlag];
    end
end

% === 4) Sort by finalX descending (best run = row 1) ===
[~, sortIdx] = sort(results(:,2), 'descend');
results      = results(sortIdx,:);

% === 5) Display them ===
disp('=== Thrust Sweep (Ft) Results: 5–10m Range ===');
disp('  Ft (N)   |  FinalX (m)  |  TippedFlag');
disp('---------------------------------------');
for i = 1:size(results,1)
    fprintf('%8.2f    |   %9.4f   |    %d\n', ...
        results(i,1), results(i,2), results(i,3));
end

% === 6) AFTER picking best Ft, sweep Mb ===
if isempty(results)
    disp('No runs found in 5–10 m range; cannot pick a best Ft.');
    return;
end

% The "best" Ft is the first row in results
bestFt = results(1,1);
disp(' ');
fprintf('Best Ft found: %.2f N (FinalX = %.4f)\n', bestFt, results(1,2));

% Prepare to sweep Mb
mbValues = 0.5 : 0.5 : 5.0;   % for example, 0.5 kg to 5 kg
massResults = [];            % will store [Mb, finalX, tippedFlag]

for mbVal = mbValues
    % Overwrite Mb in base
    assignin('base','Mb', mbVal);

    % Also ensure we set the best Ft in base
    assignin('base','Ft', bestFt);

    % Run again with the new Mb
    simOut = sim('human_transpoter_systemModel', ...
                 'StopTime','10', ...
                 'ReturnWorkspaceOutputs','on');

    % Extract x(t), theta(t)
    x_struct     = simOut.simout;  
    theta_struct = simOut.simout1; 
    x_vals       = x_struct.signals.values;
    theta_vals   = theta_struct.signals.values;

    % Check tipping
    tipping_idx = find(abs(theta_vals) >= (pi/2), 1);

    if ~isempty(tipping_idx)
        if tipping_idx == 1
            finalX = x_vals(1);
        else
            finalX = x_vals(tipping_idx - 1);
        end
        tippedFlag = 1;
    else
        finalX     = x_vals(end);
        tippedFlag = 0;
    end

    % We store all runs in the mass sweep
    massResults = [massResults; mbVal, finalX, tippedFlag];
end

% Sort massResults by descending finalX (optional)
[~, mSortIdx]  = sort(massResults(:,2), 'descend');
massResults    = massResults(mSortIdx,:);

% Print them
disp(' ');
disp('=== Sweeping Mb with Chosen Ft ===');
disp('   Mb (kg)   |  FinalX (m)   |  TippedFlag');
disp('-----------------------------------------');

for i = 1:size(massResults,1)
    fprintf('%10.2f | %12.4f |     %d\n', ...
        massResults(i,1), massResults(i,2), massResults(i,3));
end
