import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/food_analysis.dart';

class FoodAnalysisChart extends StatelessWidget {
  final FoodAnalysis analysis;

  const FoodAnalysisChart({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Nutritional Breakdown',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: analysis.protein,
                  title: 'Protein',
                  color: Colors.blue,
                  radius: 100,
                ),
                PieChartSectionData(
                  value: analysis.carbs,
                  title: 'Carbs',
                  color: Colors.green,
                  radius: 100,
                ),
                PieChartSectionData(
                  value: analysis.fat,
                  title: 'Fat',
                  color: Colors.orange,
                  radius: 100,
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Health Score',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: analysis.healthScore,
                      color: Colors.purple,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
              titlesData: const FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
