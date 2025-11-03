"use strict";
// Utility functions for scoring calculations
Object.defineProperty(exports, "__esModule", { value: true });
exports.zscore = zscore;
exports.exponentialDecay = exponentialDecay;
exports.safeSqrt = safeSqrt;
/**
 * Вычислить z-score значения в массиве
 */
function zscore(value, values) {
    if (values.length === 0)
        return 0;
    const mean = values.reduce((sum, v) => sum + v, 0) / values.length;
    const variance = values.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / values.length;
    const stdDev = Math.sqrt(variance);
    if (stdDev === 0)
        return 0;
    return (value - mean) / stdDev;
}
/**
 * Вычислить экспоненциальное затухание
 */
function exponentialDecay(ageHours, lambda) {
    return Math.exp(-lambda * ageHours);
}
/**
 * Вычислить sqrt с защитой от отрицательных значений
 */
function safeSqrt(value) {
    return Math.sqrt(Math.max(0, value));
}
//# sourceMappingURL=utils.js.map