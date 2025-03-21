
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
Ft = 0;   % placeeholder value  
beta = 0.1;
theta = 1;

%% Define Constants shown in the block diagram
C1 = M + Ig_w/R^2 + Mu;
C2_ = Mu * Lg;
C2 = 1/C2_;
C5 = C2;
C4 = Mu * Lg^2 + Ig_u;
% C6 = -1 * Mu * g * Lg * (theta + beta);   



