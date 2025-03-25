clc;
clear all;

% 1) Define system parameters
M = 35;            
Mu = 66; 
Mb = 1.5;
Lg = 1; 
Lb = 1;
Ig_w = 0.02;       
Ig_u = 20;         
R = 0.127;         
g = 9.81;              

% Derived constants
C1 = M + Ig_w/(R^2) + Mu;
C2 = Mu * Lg;
C5 = Mu * Lg;
C4 = Mu * Lg^2 + Ig_u;

% 2) Range of Ft values
beta = -0.18;
Ft_values = 0:10:10000;
results = [];

% 3) Loop over Ft and run the model
for currentFt = Ft_values

    assignin('base', 'Ft', currentFt);

    % Run the model
    simOut = sim('human_transpoter_systemModel', 'StopTime', '10', ...
                 'ReturnWorkspaceOutputs', 'on');
    
    % Retrieve x(t) and theta(t)
    x_struct = simOut.simout;
    theta_struct = simOut.simout1;
    
    x = x_struct.signals.values;
    theta_vals = theta_struct.signals.values;

    % Define tipping threshold (e.g., > 90 degrees in radians)
    tip_threshold = pi/2;

    % Find index where tipping happens
    tipping_idx = find(abs(theta_vals) >= tip_threshold, 1);

    if ~isempty(tipping_idx)
        final_x = x(tipping_idx - 1);
        max_theta = max(abs(theta_vals(1:tipping_idx-1)));
    else
        final_x = x(end);
        max_theta = max(abs(theta_vals));
    end

    % Filter out absurd values (e.g., runaway simulations)
    if final_x < 10 && max_theta < tip_threshold && final_x > 0
        results = [results; currentFt, final_x, max_theta];
    end
end



% 5) Display results
disp('Ft   | Final x (m) | Max theta (rad)');
for i = 1:size(results,1)
    fprintf('%.0f   | %.4f     | %.4f\n', ...
            results(i,1), results(i,2), results(i,3));
end