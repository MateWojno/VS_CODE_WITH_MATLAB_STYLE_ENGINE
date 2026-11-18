%% ========================================================================
%% TEST 4: Neural Network XOR Classifier (test04_neural_network_xor.m)
%% ========================================================================
clear; clc; close all;
rand('seed', 42);

% XOR Dataset
X = [0 0; 0 1; 1 0; 1 1];
Y = [0; 1; 1; 0];

% Network architecture: 2 inputs -> 6 hidden -> 1 output
W1 = randn(2, 6) * 0.8; b1 = zeros(1, 6);
W2 = randn(6, 1) * 0.8; b2 = zeros(1, 1);

sigmoid = @(z) 1 ./ (1 + exp(-z));
lr = 0.5;
epochs = 4000;
loss_history = zeros(epochs, 1);

for ep = 1:epochs
    % Forward pass
    Z1 = X * W1 + b1;
    A1 = sigmoid(Z1);
    Z2 = A1 * W2 + b2;
    A2 = sigmoid(Z2);

    % Binary cross-entropy loss
    loss_history(ep) = -mean(Y .* log(A2 + 1e-8) + (1 - Y) .* log(1 - A2 + 1e-8));

    % Backpropagation
    dZ2 = A2 - Y;
    dW2 = (A1' * dZ2) / 4;
    db2 = mean(dZ2, 1);

    dA1 = dZ2 * W2';
    dZ1 = dA1 .* A1 .* (1 - A1);
    dW1 = (X' * dZ1) / 4;
    db1 = mean(dZ1, 1);

    % Gradient descent update
    W2 -= lr * dW2; b2 -= lr * db2;
    W1 -= lr * dW1; b1 -= lr * db1;
end

% Evaluate decision boundary across 2D grid
[gx, gy] = meshgrid(linspace(-0.2, 1.2, 100));
grid_pts = [gx(:), gy(:)];
preds = sigmoid(sigmoid(grid_pts * W1 + b1) * W2 + b2);
Z_pred = reshape(preds, size(gx));

figure('Name', 'Test 4: Neural Network XOR', 'NumberTitle', 'off');
subplot(1, 2, 1);
plot(1:epochs, loss_history, 'b-', 'LineWidth', 2);
grid on;
title('Neural Network Training Loss');
xlabel('Epoch'); ylabel('Cross-Entropy Loss');

subplot(1, 2, 2);
contourf(gx, gy, Z_pred, 20); hold on;
colormap('jet'); colorbar;
plot(X(Y==0, 1), X(Y==0, 2), 'wo', 'MarkerSize', 10, 'MarkerFaceColor', 'k', 'LineWidth', 2);
plot(X(Y==1, 1), X(Y==1, 2), 'ws', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 2);
title('Learned XOR Decision Boundary');
xlabel('Input X1'); ylabel('Input X2');
