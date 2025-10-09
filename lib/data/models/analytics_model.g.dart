// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsSummaryModel _$AnalyticsSummaryModelFromJson(
        Map<String, dynamic> json) =>
    AnalyticsSummaryModel(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      savingsRate: (json['savingsRate'] as num).toDouble(),
    );

Map<String, dynamic> _$AnalyticsSummaryModelToJson(
        AnalyticsSummaryModel instance) =>
    <String, dynamic>{
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'netBalance': instance.netBalance,
      'savingsRate': instance.savingsRate,
    };

CategoryBreakdownModel _$CategoryBreakdownModelFromJson(
        Map<String, dynamic> json) =>
    CategoryBreakdownModel(
      category:
          CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      budget: (json['budget'] as num).toDouble(),
      budgetUtilization: (json['budgetUtilization'] as num).toDouble(),
    );

Map<String, dynamic> _$CategoryBreakdownModelToJson(
        CategoryBreakdownModel instance) =>
    <String, dynamic>{
      'category': instance.category,
      'amount': instance.amount,
      'percentage': instance.percentage,
      'transactionCount': instance.transactionCount,
      'budget': instance.budget,
      'budgetUtilization': instance.budgetUtilization,
    };

MonthlyTrendModel _$MonthlyTrendModelFromJson(Map<String, dynamic> json) =>
    MonthlyTrendModel(
      month: json['month'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );

Map<String, dynamic> _$MonthlyTrendModelToJson(MonthlyTrendModel instance) =>
    <String, dynamic>{
      'month': instance.month,
      'income': instance.income,
      'expense': instance.expense,
    };

AnalyticsDataModel _$AnalyticsDataModelFromJson(Map<String, dynamic> json) =>
    AnalyticsDataModel(
      summary: AnalyticsSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>),
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>)
          .map(
              (e) => CategoryBreakdownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>)
          .map((e) => MonthlyTrendModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnalyticsDataModelToJson(AnalyticsDataModel instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'categoryBreakdown': instance.categoryBreakdown,
      'monthlyTrend': instance.monthlyTrend,
    };

AnalyticsResponse _$AnalyticsResponseFromJson(Map<String, dynamic> json) =>
    AnalyticsResponse(
      analytics: AnalyticsDataModel.fromJson(
          json['analytics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnalyticsResponseToJson(AnalyticsResponse instance) =>
    <String, dynamic>{
      'analytics': instance.analytics,
    };
