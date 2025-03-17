clc; clear; close all;

syms M Mu Lg Ig_w Ig_u R g Ft beta theta real

C1 = M + Ig_w./(R^2) + Mu;
C2 = Mu*Lg;
C4 = Mu*(Lg^2) + Ig_u;
C6 = Mu*g*Lg;

detA = C1*C4 - C2^2;

x_ddot_expr     = ( C4*Ft + C2*C6*(theta + beta) ) / detA;
theta_ddot_expr = ( -C2*Ft + C1*C6*(theta + beta) ) / detA;

a23 = diff(x_ddot_expr, theta);
b2  = diff(x_ddot_expr, Ft); 

a43 = diff(theta_ddot_expr, theta);
b4  = diff(theta_ddot_expr, Ft);    

A = [
    0    1     0    0
    0    0    a23   0
    0    0     0    1
    0    0    a43   0
];
B = [
    0
    b2
    0
    b4
];

C = eye(4); 
D = zeros(4,1);

disp('Equation:   x_dot = A x + B u')
disp('States:     x1= x,  x2= dx,  x3= theta,  x4= dtheta')
disp('Input:      u  = Ft   (thrust force)')
disp(' ')
disp('A = '), disp(simplify(A))
disp('B = '), disp(simplify(B))
disp('C = '), disp(C)
disp('D = '), disp(D)
disp(' ')
disp('Constants:')
disp(['C1 = ', char(C1)])
disp(['C2 = ', char(C2)])
disp(['C4 = ', char(C4)])
disp(['C6 = ', char(C6)])
disp(['detA = ', char(detA)])