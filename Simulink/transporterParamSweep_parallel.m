                function transporterParamSweep_parallel()
    % transporterParamSweep_parallel.m
    %
    % 1) Defines parameter sweeps for StopTime, Beta, and Ft.
    % 2) Uses PARFOR to run simulations in parallel.
    % 3) Records the final X distance before tipping (or the end of sim).
    % 4) Displays results where 5 <= finalX <= 10.
    % 5) Prints the total # of loops and the current loop # during execution.
 
    clc;
    clear;

    %% --- 1) Define system parameters ---
    M    = 35;
    Mu   = 66;
    Mb   = 1.5;
    Lg   = 1;
    Lb   = 1;
    Ig_w = 0.02;
    Ig_u = 20;
    R    = 0.127;
    g    = 9.81;

    Ft   = 500;  
    beta = -0.18;

    C1 = M + (Ig_w / R^2) + Mu;
    C2 = Mu * Lg;
    C4 = Mu * Lg^2 + Ig_u;
    C5 = Mu * Lg;

    %% --- 2) Sweep definitions ---
    timeValues = [10];
    betaValues = 0 : 0.01: 0.8;
    ftValues   = 65: 0.001 : 75;

    [T, B, F] = ndgrid(timeValues, betaValues, ftValues);
    combos    = [T(:), B(:), F(:)];
    numRuns   = size(combos, 1);

    fprintf('\nNumber of loops (simulations) to run: %d\n', numRuns);

    %% --- 3) Preallocate results ---
    results = zeros(numRuns, 5);

    %% --- 4) Parallel setup ---
    if isempty(gcp('nocreate'))
        parpool;
    end

    D = parallel.pool.DataQueue;
    afterEach(D, @(i) fprintf('Currently on iteration %d of %d\n', i, numRuns));

    %% --- 5) Run simulations in parallel ---
    parfor i = 1 : numRuns
        Tsim    = combos(i,1);
        betaVal = combos(i,2);
        ftVal   = combos(i,3);

        [finalX, tippedFlag] = runSingleSim(Tsim, betaVal, ftVal, ...
                                            M, Mu, Mb, Lg, Lb, Ig_w, Ig_u, R, g, ...
                                            C1, C2, C4, C5);

        results(i,:) = [Tsim, betaVal, ftVal, finalX, tippedFlag];
        send(D, i);
    end

    %% --- 6) Convert to table and save ---
    varNames     = ["StopTime","Beta","Ft","FinalX","TippedFlag"];
    resultsTable = array2table(results, 'VariableNames', varNames);

    save('transporterSweepResults_parallel.mat', 'resultsTable');
    fprintf('\nSaved results to transporterSweepResults_parallel.mat\n');

    %% --- 7) Filter for FinalX between 5 and 10
    maskGood = (resultsTable.FinalX >= 5) & (resultsTable.FinalX <= 10);
    goodRuns = resultsTable(maskGood, :);
    goodRuns = sortrows(goodRuns, "FinalX", "descend");

    %% --- 8) Display filtered results ---
    fprintf('\n=== Runs achieving 5m to 10m final distance: ===\n');
    disp(goodRuns);

    if isempty(goodRuns)
        fprintf('No runs found with finalX between 5 and 10 m.\n');
    end
end


%% --- Local function: runSingleSim --------------------------------------
function [finalX, tippedFlag] = runSingleSim(timeVal, betaVal, ftVal, ...
                                             M, Mu, Mb, Lg, Lb, Ig_w, Ig_u, R, g, ...
                                             C1, C2, C4, C5)
    % This function:
    %  1) Creates a SimulationInput for "human_transpoter_systemModel".
    %  2) Sets variables in that SimulationInput (to avoid base workspace conflicts).
    %  3) Runs the Simulink model for 'timeVal' seconds.
    %  4) Returns finalX and indicates if the system tipped (±90 deg).

    % Create a SimulationInput object
    in = Simulink.SimulationInput('human_transpoter_systemModel');

    % Assign parameters your model needs
    in = in.setVariable('M',    M);
    in = in.setVariable('Mu',   Mu);
    in = in.setVariable('Mb',   Mb);
    in = in.setVariable('Lg',   Lg);
    in = in.setVariable('Lb',   Lb);
    in = in.setVariable('Ig_w', Ig_w);
    in = in.setVariable('Ig_u', Ig_u);
    in = in.setVariable('R',    R);
    in = in.setVariable('g',    g);

    in = in.setVariable('C1',   C1);
    in = in.setVariable('C2',   C2);
    in = in.setVariable('C4',   C4);
    in = in.setVariable('C5',   C5);

    in = in.setVariable('beta', betaVal);
    in = in.setVariable('Ft',   ftVal);

    % Suppress algebraic loop warnings for this run
    in = in.setModelParameter('StopTime', num2str(timeVal), ...
                              'ReturnWorkspaceOutputs','on', ...
                              'AlgebraicLoopMsg','none');

    % Run simulation
    simOut = sim(in);

    % Extract x(t) and theta(t)
    x_vals     = simOut.simout.signals.values;     % from logged signal
    theta_vals = simOut.simout1.signals.values;    % from logged signal

    % Compute net tilt (theta + beta)
    tiltVals    = theta_vals + betaVal;
    tipThresh   = pi / 2;
    tipping_idx = find(abs(tiltVals) >= tipThresh, 1);

    if ~isempty(tipping_idx)
        % Tipped: finalX = x just before tipping
        if tipping_idx == 1
            finalX = x_vals(1);
        else
            finalX = x_vals(tipping_idx - 1);
        end
        tippedFlag = 1;
    else
        % Did not tip by the end
        finalX = x_vals(end);
        tippedFlag = 0;
    end
end
