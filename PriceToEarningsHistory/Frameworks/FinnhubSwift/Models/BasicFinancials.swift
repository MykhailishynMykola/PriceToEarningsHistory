//
//  BasicFinancials.swift
//  PriceToEarningsHistory
//
//  Created by Mykhailishyn, Mykola (ADM) on 08.08.2023.
//

import Foundation

public struct BasicFinancials: Mappable {
    public var symbol: String
    public var metricType: String
    public var metric: BasicFinancialsMetric
    public var series: BasicFinancialsSeries
}

public struct BasicFinancialsSeries: Mappable {
    public var annual: BasicFinancialsSeriesDetails
    public var quarterly: BasicFinancialsSeriesDetails
}

public struct BasicFinancialsSeriesDetails: Mappable {
    public var pe: [HistoryValue]?
    
//    public var bookValue: [HistoryValue]
//    public var cashRatio: [HistoryValue]
//    public var currentRatio: [HistoryValue]
//    public var ebitPerShare: [HistoryValue]
//    public var eps: [HistoryValue]
//    public var ev: [HistoryValue]
//    public var fcfMargin: [HistoryValue]
//    public var grossMargin: [HistoryValue]
//    public var inventoryTurnover: [HistoryValue]
//    public var longtermDebtTotalAsset: [HistoryValue]
//    public var longtermDebtTotalCapital: [HistoryValue]
//    public var longtermDebtTotalEquity: [HistoryValue]
//    public var netDebtToTotalCapital: [HistoryValue]
//    public var netDebtToTotalEquity: [HistoryValue]
//    public var netMargin: [HistoryValue]
//    public var operatingMargin: [HistoryValue]
//    public var payoutRatio: [HistoryValue]
//    public var pb: [HistoryValue]
//    public var pe: [HistoryValue]
//    public var pfcf: [HistoryValue]
//    public var pretaxMargin: [HistoryValue]
//    public var ps: [HistoryValue]
//    public var ptbv: [HistoryValue]
//    public var quickRatio: [HistoryValue]
//    public var receivablesTurnover: [HistoryValue]
//    public var roa: [HistoryValue]
//    public var roe: [HistoryValue]
//    public var roic: [HistoryValue]
//    public var rotc: [HistoryValue]
//    public var salesPerShare: [HistoryValue]
//    public var sgaToSale: [HistoryValue]
//    public var tangibleBookValue: [HistoryValue]
//    public var totalDebtToEquity: [HistoryValue]
//    public var totalDebtToTotalAsset: [HistoryValue]
//    public var totalDebtToTotalCapital: [HistoryValue]
//    public var totalRatio: [HistoryValue]
}

public struct HistoryValue: Mappable {
    public var period: String
    public var value: Float
    
    enum CodingKeys: String, CodingKey {
        case period = "period"
        case value = "v"
    }
}

public struct BasicFinancialsMetric: Mappable {
    public var epsAnnual: Float
    public var peAnnual: Float
    
//    public var 10DayAverageTradingVolume: Float
//    public var 13WeekPriceReturnDaily: Float
//    public var 26WeekPriceReturnDaily: Float
//    public var 3MonthADReturnStd: Float
//    public var 3MonthAverageTradingVolume: Float
//    public var 52WeekHigh: Float
//    public var 52WeekHighDate: String
//    public var 52WeekLow: Float
//    public var 52WeekLowDate: String
//    public var 52WeekPriceReturnDaily: Float
//    public var 5DayPriceReturnDaily: Float
//    public var assetTurnoverAnnual: Float
//    public var assetTurnoverTTM: Float
//    public var beta: Float
//    public var bookValuePerShareAnnual: Float
//    public var bookValuePerShareQuarterly: Float
//    public var bookValueShareGrowth5Y: Float
//    public var capexCagr5Y: Float
//    public var cashFlowPerShareAnnual: Float
//    public var cashFlowPerShareQuarterly: Float
//    public var cashFlowPerShareTTM: Float
//    public var cashPerSharePerShareAnnual: Float
//    public var cashPerSharePerShareQuarterly: Float
//    public var currentDividendYieldTTM: Float
//    public var currentEv/freeCashFlowAnnual: Float
//    public var currentEv/freeCashFlowTTM: Float
//    public var currentRatioAnnual: Float
//    public var currentRatioQuarterly: Float
//    public var dividendGrowthRate5Y: Float
//    public var dividendPerShareAnnual: Float
//    public var dividendPerShareTTM: Float
//    public var dividendYieldIndicatedAnnual: Float
//    public var dividendsPerShareTTM: Float
//    public var ebitdPerShareAnnual: Float
//    public var ebitdPerShareTTM: Float
//    public var ebitdaCagr5Y: Float
//    public var ebitdaInterimCagr5Y: Float
//    public var enterpriseValue: Float
//    public var epsAnnual: Float
//    public var epsBasicExclExtraItemsAnnual: Float
//    public var epsBasicExclExtraItemsTTM: Float
//    public var epsExclExtraItemsAnnual: Float
//    public var epsExclExtraItemsTTM: Float
//    public var epsGrowth3Y: Float
//    public var epsGrowth5Y: Float
//    public var epsGrowthQuarterlyYoy: Float
//    public var epsGrowthTTMYoy: Float
//    public var epsInclExtraItemsAnnual: Float
//    public var epsInclExtraItemsTTM: Float
//    public var epsNormalizedAnnual: Float
//    public var epsTTM: Float
//    public var focfCagr5Y: Float
//    public var grossMargin5Y: Float
//    public var grossMarginAnnual: Float
//    public var grossMarginTTM: Float
//    public var inventoryTurnoverAnnual: Float
//    public var inventoryTurnoverTTM: Float
//    public var longTermDebt/equityAnnual: Float
//    public var longTermDebt/equityQuarterly: Float
//    public var marketCapitalization: Float
//    public var monthToDatePriceReturnDaily: Float
//    public var netIncomeEmployeeAnnual: Float
//    public var netIncomeEmployeeTTM: Float
//    public var netInterestCoverageAnnual: Float
//    public var netInterestCoverageTTM: Float
//    public var netMarginGrowth5Y: Float
//    public var netProfitMargin5Y: Float
//    public var netProfitMarginAnnual: Float
//    public var netProfitMarginTTM: Float
//    public var operatingMargin5Y: Float
//    public var operatingMarginAnnual: Float
//    public var operatingMarginTTM: Float
//    public var payoutRatioAnnual: Float
//    public var payoutRatioTTM: Float
//    public var pbAnnual: Float
//    public var pbQuarterly: Float
//    public var pcfShareAnnual: Float
//    public var pcfShareTTM: Float
//    public var peAnnual: Float
//    public var peBasicExclExtraTTM: Float
//    public var peExclExtraAnnual: Float
//    public var peExclExtraTTM: Float
//    public var peInclExtraTTM: Float
//    public var peNormalizedAnnual: Float
//    public var peTTM: Float
//    public var pfcfShareAnnual: Float
//    public var pfcfShareTTM: Float
//    public var pretaxMargin5Y: Float
//    public var pretaxMarginAnnual: Float
//    public var pretaxMarginTTM: Float
//    public var priceRelativeToS&P50013Week: Float
//    public var priceRelativeToS&P50026Week: Float
//    public var priceRelativeToS&P5004Week: Float
//    public var priceRelativeToS&P50052Week: Float
//    public var priceRelativeToS&P500Ytd: Float
//    public var psAnnual: Float
//    public var psTTM: Float
//    public var ptbvAnnual: Float
//    public var ptbvQuarterly: Float
//    public var quickRatioAnnual: Float
//    public var quickRatioQuarterly: Float
//    public var receivablesTurnoverAnnual: Float
//    public var receivablesTurnoverTTM: Float
//    public var revenueEmployeeAnnual: Float
//    public var revenueEmployeeTTM: Float
//    public var revenueGrowth3Y: Float
//    public var revenueGrowth5Y: Float
//    public var revenueGrowthQuarterlyYoy: Float
//    public var revenueGrowthTTMYoy: Float
//    public var revenuePerShareAnnual: Float
//    public var revenuePerShareTTM: Float
//    public var revenueShareGrowth5Y: Float
//    public var roa5Y: Float
//    public var roaRfy: Float
//    public var roaTTM: Float
//    public var roe5Y: Float
//    public var roeRfy: Float
//    public var roeTTM: Float
//    public var roi5Y: Float
//    public var roiAnnual: Float
//    public var roiTTM: Float
//    public var tangibleBookValuePerShareAnnual: Float
//    public var tangibleBookValuePerShareQuarterly: Float
//    public var tbvCagr5Y: Float
//    public var totalDebt/totalEquityAnnual: Float
//    public var totalDebt/totalEquityQuarterly: Float
//    public var yearToDatePriceReturnDaily: Float
}
