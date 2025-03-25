clc;
clear all;

%% Define system parameters
M = 35;            
Mu = 66; 
Mb = 1.5;
Lg = 1; 
Lb = 1;
Ig_w = 0.02;       
Ig_u = 20;         
R = 0.127;         
g = 9.81;            

% Thrust force is fixed but need to be found
Ft = 500;   % placeeholder value  
beta = -0.18;

%% Define Constants shown in the block diagram
C1 = M + Ig_w/(R^2) + Mu;
C2 = Mu * Lg;
C5 = Mu * Lg;
C4 = Mu * Lg^2 + Ig_u;
% C6 = -1 * Mu * g * Lg * (theta + beta);   

function transporterParamSweep()
    % transporterParamSweep.m
    %
    % This script systematically tests multiple combinations of:
    %   1) Simulation StopTime
    %   2) Lean angle beta
    %   3) Thrust force Ft
    %
    % For each combination, it runs your Simulink model "human_transpoter_systemModel"
    % and records how far x(t) gets before tipping. Then it displays which runs
    % achieve a final distance between 5 and 10 m.

    clc; clear;

    %%% 1) Define the parameter grids to test %%%
    timeValues = [0.5, 1, 5, 10, 15, 20];           % Different StopTimes to try
    betaValues = [-0.7,-0.6,-0.5,-0.4,-0.3,-0.20,-0.1, 0, 0.1, 0.20, 0.3, 0.4, 0.5, 0.6, 0.7];  % Different user lean angles
    ftValues   = 0 : 50 : 2000;            % Thrust forces (N), step of 50

    %%% 2) Allocate storage for results %%%
    % We'll store each run as: [StopTime, Beta, Ft, FinalX, TippedFlag]
    maxRuns = numel(timeValues) * numel(betaValues) * numel(ftValues);
    results = zeros(maxRuns, 5);  % preallocate for speed

    runCount = 0;

    %%% 3) Triple nested loops over all combinations %%%
    for tIdx = 1:numel(timeValues)
        Tsim = timeValues(tIdx);

        for bIdx = 1:numel(betaValues)
            betaVal = betaValues(bIdx);

            for fIdx = 1:numel(ftValues)
                currentFt = ftValues(fIdx);

                runCount = runCount + 1;

                % Run the simulation with these parameters
                [finalX, tippedFlag] = runSingleSim(Tsim, betaVal, currentFt);

                % Store the results
                results(runCount, :) = [Tsim, betaVal, currentFt, finalX, tippedFlag];
            end
        end
    end

    %%% 4) Convert the results to a table for clarity
    varNames = ["StopTime","Beta","Ft","FinalX","TippedFlag"];
    resultsTable = array2table(results, "VariableNames", varNames);

    %%% 5) Find runs where we traveled 5 to 10 m
    maskGood  = (resultsTable.FinalX >= 5) & (resultsTable.FinalX <= 10);
    goodRuns  = resultsTable(maskGood, :);

    % Sort those by descending FinalX so we see the "best" in that range first
    goodRuns  = sortrows(goodRuns, "FinalX", "descend");

    %%% 6) Display them
    fprintf('\n=== Runs achieving 5m to 10m final distance: ===\n');
    disp(goodRuns);

    if isempty(goodRuns)
        fprintf('No runs found with finalX between 5 and 10 m.\n');
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SUBFUNCTION: Run the simulation for one set of parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [finalX, tippedFlag] = runSingleSim(timeVal, betaVal, ftVal)
    % Assign parameters to the base workspace for Simulink
    assignin('base','beta', betaVal);
    assignin('base','Ft',   ftVal);

    % Run the Simulink model
    simOut = sim('human_transpoter_systemModel', ...
                 'StopTime', num2str(timeVal), ...
                 'ReturnWorkspaceOutputs','on');

    % Extract x(t) and theta(t) from the logged signals
    x_struct     = simOut.simout;    % adjust if your model logs differently
    theta_struct = simOut.simout1;   % adjust if your model logs differently

    x_vals       = x_struct.signals.values;
    theta_vals   = theta_struct.signals.values;

    % We define 'actual tilt' as (theta + beta)
    tiltVals = theta_vals + betaVal;

    % Tipping threshold: ±90 degrees
    tip_threshold = pi/2;

    % Find first index where the tilt crosses ±90 deg
    tipping_idx = find(abs(tiltVals) >= tip_threshold, 1);

    if ~isempty(tipping_idx)
        % Tipped during the simulation
        finalX     = x_vals(tipping_idx - 1);  % x-value just before tipping
        tippedFlag = 1;
    else
        % Never tipped by end of simulation
        finalX     = x_vals(end);
        tippedFlag = 0;
    end
end
