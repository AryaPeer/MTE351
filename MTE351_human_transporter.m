clc; clear; close all;

%% Define Symbolic Variables
syms M Mu Lg Ig_w Ig_u R g Ft beta theta real

%% Linearized Equations (applying small angle approximations)
% cos(theta + beta) ≈ 1 AND sin(theta + beta) ≈ (theta + beta) 
% Equation 1: (M + (Ig_w)/R^2 + Mu)x_ddot + Mu*Lg*theta_ddot= Ft
% Equation 2: (Mu*Lg^2 + Ig_u)theta_ddot + Mu*Lg*x_ddot - Mu*g*Lg*(theta + beta) = 0

%% Express System in Standard State-Variable Form
% Define constants using symbolic expressions
C1 = M + Ig_w/R^2 + Mu;
C2 = Mu * Lg;
C4 = Mu * Lg^2 + Ig_u;
C6 = Mu * g * Lg;

%% Calculate determinant to eliminate x_ddot and theta_ddot
% [ C1  C2 ] [x_ddot] = [ Ft]
% [ C2  C4 ] [theta_ddot] = [ C6*(theta + beta)]
% det_A = C1*C4 - C2^2;
% x_ddot = (Ft*C4 + C2*C6*(theta + beta)) / det_A
% theta_ddot = (-C2*Ft + C1*C6*(theta + beta)) / det_A
% Let states be: x1 = x, x2 = x_dot, x3 = theta, x4 = theta_dot
% Then: x_ddot1 = x2, x_dot2 = x_ddot, x_dot3 = x4, x_dot4 = theta_ddot
% Compute determinant
det_A = C1 * C4 - C2^2;

% Compute matrix elements
a23 = C2 * C6 / det_A;
a43 = C1 * C6 / det_A;
b21 = C4 / det_A;
b22 = C2 * C6 / det_A;
b41 = -C2 / det_A;
b42 = C1 * C6 / det_A;

% Define State-Space Matrices (Symbolic)
A = [
    0   1   0   0;
    0   0  a23  0;
    0   0   0   1;
    0   0  a43  0
];

B = [
    0    0;
    b21  b22;
    0    0;
    b41  b42
];

C = eye(4);  % Full-state output
D = zeros(4, 2); % No direct feedthrough

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
disp(['det(A) = ', char(det_A)])
