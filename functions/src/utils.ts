// Utility functions for scoring calculations

/**
 * Вычислить z-score значения в массиве
 */
export function zscore(value: number, values: number[]): number {
  if (values.length === 0) return 0;
  
  const mean = values.reduce((sum, v) => sum + v, 0) / values.length;
  const variance = values.reduce((sum, v) => sum + Math.pow(v - mean, 2), 0) / values.length;
  const stdDev = Math.sqrt(variance);
  
  if (stdDev === 0) return 0;
  
  return (value - mean) / stdDev;
}

/**
 * Вычислить экспоненциальное затухание
 */
export function exponentialDecay(ageHours: number, lambda: number): number {
  return Math.exp(-lambda * ageHours);
}

/**
 * Вычислить sqrt с защитой от отрицательных значений
 */
export function safeSqrt(value: number): number {
  return Math.sqrt(Math.max(0, value));
}

