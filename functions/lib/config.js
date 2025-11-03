"use strict";
/**
 * Конфигурация весов для расчёта рейтинга специалистов
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SCORING_WEIGHTS = void 0;
exports.getWeights = getWeights;
exports.SCORING_WEIGHTS = {
    // Веса компонентов базового рейтинга
    W_REV: 4.0, // Вес отзывов
    W_ENG: 2.0, // Вес вовлечённости
    W_CONV: 3.0, // Вес конверсии просмотров в подписки
    W_COMP: 3.5, // Вес завершённых заявок
    W_FOLLOWERS_SQRT: 0.2, // Вес sqrt(подписчиков)
    // Параметры временного затухания
    lambda: 0.18, // Коэффициент затухания для lastActivity
    lambdaWeekly: 0.06, // Коэффициент затухания для недельного рейтинга
    // Веса финального рейтинга
    ALPHA: 0.65, // Вес базового рейтинга
    BETA: 0.2, // Вес нормализации по стране
    GAMMA: 0.1, // Вес нормализации по городу
    DELTA: 0.05, // Вес актуальности (recency)
    // Байесовская оценка для холодного старта
    BAYESIAN_PRIOR: 4.5, // Априорная оценка
    BAYESIAN_WEIGHT: 3, // Вес априорной оценки
    MIN_REVIEWS_FOR_BAYESIAN: 3, // Минимум отзывов для применения
};
/**
 * Получить веса из переменных окружения или использовать дефолтные
 */
function getWeights() {
    return {
        W_REV: parseFloat(process.env.W_REV || exports.SCORING_WEIGHTS.W_REV.toString()),
        W_ENG: parseFloat(process.env.W_ENG || exports.SCORING_WEIGHTS.W_ENG.toString()),
        W_CONV: parseFloat(process.env.W_CONV || exports.SCORING_WEIGHTS.W_CONV.toString()),
        W_COMP: parseFloat(process.env.W_COMP || exports.SCORING_WEIGHTS.W_COMP.toString()),
        W_FOLLOWERS_SQRT: parseFloat(process.env.W_FOLLOWERS_SQRT || exports.SCORING_WEIGHTS.W_FOLLOWERS_SQRT.toString()),
        lambda: parseFloat(process.env.LAMBDA || exports.SCORING_WEIGHTS.lambda.toString()),
        lambdaWeekly: parseFloat(process.env.LAMBDA_WEEKLY || exports.SCORING_WEIGHTS.lambdaWeekly.toString()),
        ALPHA: parseFloat(process.env.ALPHA || exports.SCORING_WEIGHTS.ALPHA.toString()),
        BETA: parseFloat(process.env.BETA || exports.SCORING_WEIGHTS.BETA.toString()),
        GAMMA: parseFloat(process.env.GAMMA || exports.SCORING_WEIGHTS.GAMMA.toString()),
        DELTA: parseFloat(process.env.DELTA || exports.SCORING_WEIGHTS.DELTA.toString()),
        BAYESIAN_PRIOR: parseFloat(process.env.BAYESIAN_PRIOR || exports.SCORING_WEIGHTS.BAYESIAN_PRIOR.toString()),
        BAYESIAN_WEIGHT: parseFloat(process.env.BAYESIAN_WEIGHT || exports.SCORING_WEIGHTS.BAYESIAN_WEIGHT.toString()),
        MIN_REVIEWS_FOR_BAYESIAN: parseInt(process.env.MIN_REVIEWS_FOR_BAYESIAN || exports.SCORING_WEIGHTS.MIN_REVIEWS_FOR_BAYESIAN.toString()),
    };
}
//# sourceMappingURL=config.js.map