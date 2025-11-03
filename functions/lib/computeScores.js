"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.recomputeScores = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const config_1 = require("./config");
const utils_1 = require("./utils");
const db = admin.firestore();
/**
 * Вычислить базовый рейтинг
 */
function computeBaseScore(stats, weights) {
    const reviewsAvg = stats.reviewsAvg || 0;
    const reviewsCount = stats.reviewsCount || 0;
    // Байесовская оценка для холодного старта
    let adjustedRating = reviewsAvg;
    if (reviewsCount < weights.MIN_REVIEWS_FOR_BAYESIAN) {
        const totalWeight = reviewsCount + weights.BAYESIAN_WEIGHT;
        adjustedRating = (reviewsAvg * reviewsCount + weights.BAYESIAN_PRIOR * weights.BAYESIAN_WEIGHT) / totalWeight;
    }
    // Вовлечённость
    const impressions = Math.max(stats.impressions || 0, 1);
    const likes = stats.likes || 0;
    const comments = stats.comments || 0;
    const shares = stats.shares || 0;
    const engagement = (likes * 1 + comments * 2 + shares * 3) / impressions;
    // Конверсия просмотров в подписки
    const newFollowsFromViews = stats.newFollowsFromViews || 0;
    const conversion = newFollowsFromViews / impressions;
    // Завершённость заявок
    const requestsTotal = Math.max(stats.requestsTotal || 0, 1);
    const requestsCompleted = stats.requestsCompleted || 0;
    const completion = requestsCompleted / requestsTotal;
    // Подписчики (sqrt)
    const followers = stats.followers || 0;
    const followersScore = (0, utils_1.safeSqrt)(followers);
    // Актуальность
    const lastActivity = stats.lastActivityAt;
    let recency = 0;
    if (lastActivity) {
        const now = admin.firestore.Timestamp.now().toMillis();
        const activityTime = lastActivity.toMillis();
        const ageDays = (now - activityTime) / (1000 * 60 * 60 * 24);
        recency = (0, utils_1.exponentialDecay)(ageDays, weights.lambda);
    }
    // Базовый рейтинг
    const scoreBase = adjustedRating * weights.W_REV +
        engagement * weights.W_ENG +
        conversion * weights.W_CONV +
        completion * weights.W_COMP +
        followersScore * weights.W_FOLLOWERS_SQRT;
    return { scoreBase, recency };
}
/**
 * Вычислить недельный рейтинг (затухание за 7 дней)
 */
async function computeWeeklyScore(specId, weights) {
    const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 7 * 24 * 60 * 60 * 1000);
    // События за последние 7 дней
    const events = [
        db.collection('events_post_engagement')
            .where('specId', '==', specId)
            .where('createdAt', '>=', sevenDaysAgo)
            .get(),
        db.collection('events_follow')
            .where('specId', '==', specId)
            .where('createdAt', '>=', sevenDaysAgo)
            .get(),
        db.collection('events_requests')
            .where('specId', '==', specId)
            .where('createdAt', '>=', sevenDaysAgo)
            .get(),
    ];
    const [engagements, follows, requests] = await Promise.all(events);
    let weeklyScore = 0;
    const now = Date.now();
    // Веса событий
    const eventWeights = {
        like: 1,
        comment: 2,
        share: 3,
        follow: 5,
        'request:created': 2,
        'request:completed': 10,
    };
    engagements.forEach((doc) => {
        var _a;
        const data = doc.data();
        const type = data.type;
        const createdAt = ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toMillis()) || now;
        const hoursSince = (now - createdAt) / (1000 * 60 * 60);
        const weight = eventWeights[type] || 1;
        weeklyScore += weight * (0, utils_1.exponentialDecay)(hoursSince, weights.lambdaWeekly);
    });
    follows.forEach((doc) => {
        var _a;
        const data = doc.data();
        const createdAt = ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toMillis()) || now;
        const hoursSince = (now - createdAt) / (1000 * 60 * 60);
        weeklyScore += eventWeights.follow * (0, utils_1.exponentialDecay)(hoursSince, weights.lambdaWeekly);
    });
    requests.forEach((doc) => {
        var _a;
        const data = doc.data();
        const status = data.status;
        const createdAt = ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toMillis()) || now;
        const hoursSince = (now - createdAt) / (1000 * 60 * 60);
        const eventKey = `request:${status}`;
        const weight = eventWeights[eventKey] || 1;
        weeklyScore += weight * (0, utils_1.exponentialDecay)(hoursSince, weights.lambdaWeekly);
    });
    return weeklyScore;
}
/**
 * Пересчитать рейтинги для всех специалистов
 */
exports.recomputeScores = functions.pubsub
    .schedule('every 30 minutes')
    .onRun(async () => {
    console.log('Starting score recomputation...');
    const weights = (0, config_1.getWeights)();
    // Получить все активные специалисты
    const specialistsSnapshot = await db
        .collection('specialists')
        .where('isActive', '==', true)
        .get();
    const specialistIds = specialistsSnapshot.docs.map((doc) => doc.id);
    console.log(`Processing ${specialistIds.length} specialists`);
    // Получить статистику
    const statsMap = new Map();
    const statsSnapshot = await db.collection('specialist_stats').get();
    statsSnapshot.forEach((doc) => {
        statsMap.set(doc.id, doc.data());
    });
    // Вычислить базовые рейтинги
    const baseScores = new Map();
    for (const specId of specialistIds) {
        const stats = statsMap.get(specId) || {};
        baseScores.set(specId, computeBaseScore(stats, weights));
    }
    // Группировка по стране и городу для нормализации
    const byCountry = new Map();
    const byCity = new Map();
    for (const [specId, { scoreBase }] of baseScores) {
        const stats = statsMap.get(specId) || {};
        const country = stats.country || 'RU';
        const city = stats.city || '';
        if (!byCountry.has(country)) {
            byCountry.set(country, []);
        }
        byCountry.get(country).push(scoreBase);
        if (city) {
            if (!byCity.has(city)) {
                byCity.set(city, []);
            }
            byCity.get(city).push(scoreBase);
        }
    }
    // Вычислить финальные рейтинги
    const batch = db.batch();
    let processed = 0;
    for (const specId of specialistIds) {
        const stats = statsMap.get(specId) || {};
        const baseResult = baseScores.get(specId);
        const scoreBase = (baseResult === null || baseResult === void 0 ? void 0 : baseResult.scoreBase) || 0;
        const recency = (baseResult === null || baseResult === void 0 ? void 0 : baseResult.recency) || 0;
        const weeklyScore = await computeWeeklyScore(specId, weights);
        // Нормализация
        const country = stats.country || 'RU';
        const city = stats.city || '';
        const countryScores = byCountry.get(country) || [];
        const cityScores = city ? byCity.get(city) || [] : [];
        const zCountry = countryScores.length > 0 ? (0, utils_1.zscore)(scoreBase, countryScores) : 0;
        const zCity = cityScores.length > 0 ? (0, utils_1.zscore)(scoreBase, cityScores) : 0;
        // Финальный рейтинг
        const scoreFinal = scoreBase * weights.ALPHA +
            zCountry * weights.BETA +
            zCity * weights.GAMMA +
            recency * weights.DELTA;
        // Вычислить метрики
        const impressions = Math.max(stats.impressions || 0, 1);
        const likes = stats.likes || 0;
        const comments = stats.comments || 0;
        const shares = stats.shares || 0;
        const engagementRate = (likes * 1 + comments * 2 + shares * 3) / impressions;
        const followAfterViewRate = (stats.newFollowsFromViews || 0) / impressions;
        const requestsTotal = Math.max(stats.requestsTotal || 0, 1);
        const completionRate = (stats.requestsCompleted || 0) / requestsTotal;
        // Обновить specialist_scores
        const scoresRef = db.collection('specialist_scores').doc(specId);
        batch.set(scoresRef, {
            scoreFinal,
            scoreWeekly: weeklyScore,
            engagementRate,
            followAfterViewRate,
            completionRate,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        processed++;
    }
    await batch.commit();
    console.log(`Score recomputation completed: ${processed} specialists processed`);
    return null;
});
//# sourceMappingURL=computeScores.js.map