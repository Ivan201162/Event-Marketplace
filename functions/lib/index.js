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
exports.recomputeScores = exports.onReviewWrite = exports.onRequestEventCreated = exports.onFollowCreated = exports.onPostEngagementCreated = exports.onProfileViewCreated = void 0;
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// Экспорт триггеров
var triggers_1 = require("./triggers");
Object.defineProperty(exports, "onProfileViewCreated", { enumerable: true, get: function () { return triggers_1.onProfileViewCreated; } });
Object.defineProperty(exports, "onPostEngagementCreated", { enumerable: true, get: function () { return triggers_1.onPostEngagementCreated; } });
Object.defineProperty(exports, "onFollowCreated", { enumerable: true, get: function () { return triggers_1.onFollowCreated; } });
Object.defineProperty(exports, "onRequestEventCreated", { enumerable: true, get: function () { return triggers_1.onRequestEventCreated; } });
Object.defineProperty(exports, "onReviewWrite", { enumerable: true, get: function () { return triggers_1.onReviewWrite; } });
// Экспорт cron функции
var computeScores_1 = require("./computeScores");
Object.defineProperty(exports, "recomputeScores", { enumerable: true, get: function () { return computeScores_1.recomputeScores; } });
//# sourceMappingURL=index.js.map