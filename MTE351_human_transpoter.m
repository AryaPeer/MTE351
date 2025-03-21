clc; clear; close all;

%% Define Symbolic Variables
syms M Mu Lg Ig_w Ig_u R g Ft beta theta real

%% Define Constants
C1 = M + Ig_w/R^2 + Mu;
C2 = Mu * Lg;
C4 = Mu * Lg^2 + Ig_u;
C6 = -1 * Mu * g * Lg * (theta + beta);

%% Define State Variables
syms x x_dot theta theta_dot real
x_vec = [x; x_dot; theta; theta_dot];

%% Define Input
u = Ft;

%% Linearized Equations
% Equation 1: (C1)*x_ddot + C2*theta_ddot = Ft
% Equation 2: (C4)*theta_ddot + C2*x_ddot - C6 = 0

% Solve for x_ddot and theta_ddot
syms x_ddot theta_ddot real
eq1 = C1*x_ddot + C2*theta_ddot == u;
eq2 = C4*theta_ddot + C2*x_ddot - C6 == 0;

% Solve the system of equations for x_ddot and theta_ddot
sol = solve([eq1, eq2], [x_ddot, theta_ddot]);

% Extract solutions
x_ddot_sol = sol.x_ddot;
theta_ddot_sol = sol.theta_ddot;

%% State-Space Representation
% State vector: [x; x_dot; theta; theta_dot]
% State derivatives: [x_dot; x_ddot; theta_dot; theta_ddot]

% Define state derivatives
% x_dot = x_dot;
x_ddot = x_ddot_sol;
% theta_dot = theta_dot;
theta_ddot = theta_ddot_sol;

% State derivative vector
x_dot_vec = [x_dot; x_ddot; theta_dot; theta_ddot];

% Express in standard state-variable form: dx/dt = A*x + B*u
% Extract coefficients for A and B matrices
A = jacobian(x_dot_vec, x_vec);
B = jacobian(x_dot_vec, u);

% Define C and D matrices for output
C = eye(4);  % Full-state output
D = zeros(4, 1); % No direct feedthrough

%% Display the Standard State-Variable Model
disp('Standard State-Variable Model:')
disp('[x_dot] = [A][x] + [B][u]')
disp('[y]     = [C][x] + [D][u]')
disp(' ')

% Display A, B, C, D Matrices 
disp('State Equation in Matrix Form:')
disp('A Matrix:')
disp(A)
disp('B Matrix:')
disp(B)
disp('C Matrix:')
disp(C)
disp('D Matrix:')
disp(D)
disp(' ')

% Display Key Constants
disp('Matrix Element Expressions:')
disp(['C1 = ', char(C1)])
disp(['C2 = ', char(C2)])
disp(['C4 = ', char(C4)])
disp(['C6 = ', char(C6)])