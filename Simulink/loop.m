%% --- Script: sweep_Ft.m ---
clc;
clear all;
% 1) Define system parameters in the base workspace
M = 35;            
Mu = 66; 
Mb = 1.5;  % base mass
Lg = 1; 
Lb = 1;
Ig_w = 0.02;       
Ig_u = 20;         
R = 0.127;         
g = 9.81;            

% We declare Ft = 0 initially; it will be overwritten in the loop
Ft = 5;  
beta = 11;
theta = 7;

% Derived constants
C1 = M + Ig_w/R^2 + Mu;
C2_ = Mu * Lg;
C2 = 1/C2_;
C5 = C2;
C4 = Mu * Lg^2 + Ig_u;

% 2) Range of Ft values
Ft_values = 5:5:100;
results = [];  % Will store [Ft, final_x, max_theta]

% 3) Loop over Ft and run the model
for currentFt = Ft_values

    % Place currentFt in the base workspace so the Simulink model sees it
    assignin('base', 'Ft', currentFt);
    
    % Run the model, capturing a single simulation output struct
    simOut = sim('human_transpoter_systemModel', 'StopTime', '10', ...
                 'ReturnWorkspaceOutputs', 'on');
    
    % Retrieve x(t) and theta(t) from simOut
    % -- these come from "To Workspace" blocks named simout / simout1
    x_struct = simOut.simout;      % structure with time
    theta_struct = simOut.simout1; % structure with time
    
    % Extract numeric arrays
    x = x_struct.signals.values;        % entire time series for x
    theta_vals = theta_struct.signals.values;  % entire time series for theta
    
    final_x = x(end);
    max_theta = max(abs(theta_vals));
    
    % 4) Record results in an array: columns = [Ft, final_x, max_theta]
    results = [results; currentFt, final_x, max_theta];
end

% 5) Display results
disp('Ft   | Final x (m) | Max theta');
for i = 1:size(results,1)
    fprintf('%.0f   | %.6f     | %.6f\n', ...
            results(i,1), results(i,2), results(i,3));
end