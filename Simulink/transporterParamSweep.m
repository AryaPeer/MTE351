function transporterParamSweep()
% transporterParamSweep.m
%
% This function systematically tests multiple combinations of:
%   1) Simulation StopTime
%   2) Lean angle beta
%   3) Thrust force Ft
%
% For each combination, it runs your Simulink model "human_transpoter_systemModel"
% and records how far x(t) gets before tipping. Then it displays which runs
% achieve a final distance between 5 and 10 m.

    clc;  % Clear command window
    clear;  % Clear workspace variables (inside this function)

    %% --- Define system parameters ---
    M    = 35;
    Mu   = 66;
    Mb   = 1.5;
    Lg   = 1;
    Lb   = 1;
    Ig_w = 0.02;
    Ig_u = 20;
    R    = 0.127;
    g    = 9.81;

    % "Nominal" thrust force & lean angle (not actually used in the sweep, 
    % but assigned if your model needs them as initial guesses).
    Ft   = 500;    % placeholder value  
    beta = -0.18;

    %% --- Define constants shown in the block diagram ---
    C1 = M + Ig_w/(R^2) + Mu;     % etc.
    C2 = Mu * Lg;
    C4 = Mu * Lg^2 + Ig_u;
    C5 = Mu * Lg;
    % C6 = -Mu * g * Lg * (theta + beta);   % Example, if used

    % If the model references these parameters directly from the base workspace,
    % assign them in now:
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

    % Also assign the "default" Ft and beta if the model needs them in general:
    assignin('base','Ft',   Ft);
    assignin('base','beta', beta);

    %% --- 1) Define the parameter grids to test ---
    % Note: If you truly want a step of 50, use 0 : 50 : 2000; 
    % but here your code says 0 : 10 : 2000 (step of 10).
    timeValues = [10];       % Different StopTimes to try
    betaValues = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];
    ftValues   = 0 : 10 : 2000;  

    %% --- 2) Allocate storage for results ---
    % We'll store each run as: [StopTime, Beta, Ft, FinalX, TippedFlag]
    maxRuns = numel(timeValues) * numel(betaValues) * numel(ftValues);
    results = zeros(maxRuns, 5);  

    runCount = 0;

    %% --- 3) Triple nested loops over all combinations ---
    for tIdx = 1:numel(timeValues)
        Tsim = timeValues(tIdx);

        for bIdx = 1:numel(betaValues)
            betaVal = betaValues(bIdx);

            for fIdx = 1:numel(ftValues)
                currentFt = ftValues(fIdx);

                runCount = runCount + 1;

                % Run a single simulation with these parameters
                [finalX, tippedFlag] = runSingleSim(Tsim, betaVal, currentFt);

                % Store the results
                results(runCount, :) = [Tsim, betaVal, currentFt, finalX, tippedFlag];
            end
        end
    end

    %% --- 4) Convert the results to a table for clarity ---
    varNames    = ["StopTime","Beta","Ft","FinalX","TippedFlag"];
    resultsTable = array2table(results, 'VariableNames', varNames);

    %% --- 5) Find runs where we traveled 5 to 10 m ---
    maskGood = (resultsTable.FinalX >= 5) & (resultsTable.FinalX <= 10);
    goodRuns = resultsTable(maskGood, :);

    % Sort those by descending FinalX so we see the "best" in that range first
    goodRuns = sortrows(goodRuns, "FinalX", "descend");

    %% --- 6) Display them ---
    fprintf('\n=== Runs achieving 5m to 10m final distance: ===\n');
    disp(goodRuns);

    if isempty(goodRuns)
        fprintf('No runs found with finalX between 5 and 10 m.\n');
    end

end % end of main function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SUBFUNCTION: Run the simulation for one set of parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [finalX, tippedFlag] = runSingleSim(timeVal, betaVal, ftVal)
    % This function is called by transporterParamSweep() to:
    %  1) Assign parameters to the base workspace (so the model can use them).
    %  2) Run the Simulink model for the given Tsim, beta, Ft.
    %  3) Return finalX and a flag indicating if the vehicle tipped.

    % Put these parameters into the base workspace for the Simulink model.
    assignin('base','beta', betaVal);
    assignin('base','Ft',   ftVal);

    % Run the Simulink model for 'timeVal' seconds
    simOut = sim('human_transpoter_systemModel', ...
        'StopTime', num2str(timeVal), ...
        'ReturnWorkspaceOutputs', 'on');

    % Extract x(t) and theta(t) from the logged signals
    % NOTE: Adjust the next two lines if your Simulink logging uses different names
    x_struct     = simOut.simout; 
    theta_struct = simOut.simout1;

    x_vals    = x_struct.signals.values;
    theta_vals= theta_struct.signals.values;

    % We define 'actual tilt' as (theta + beta)
    tiltVals  = theta_vals + betaVal;

    % Tipping threshold: ±90 degrees (in radians => ±(pi/2))
    tip_threshold = pi/2;

    % Find first index where tilt crosses ±90 deg
    tipping_idx = find(abs(tiltVals) >= tip_threshold, 1);

    if ~isempty(tipping_idx)
        % Tipped during the simulation
        % Safeguard index if  tipping_idx = 1
        if tipping_idx == 1
            finalX = x_vals(1);
        else
            finalX = x_vals(tipping_idx - 1);  % x-value just before tipping
        end
        tippedFlag = 1;
    else
        % Never tipped by end of simulation
        finalX     = x_vals(end);
        tippedFlag = 0;
    end
end
