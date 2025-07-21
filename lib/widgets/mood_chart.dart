// lib/widgets/mood_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MoodChart extends StatelessWidget {
  final Map<String, int> moodData;

  const MoodChart({super.key, required this.moodData});

  // Fungsi untuk memetakan nama mood ke warna
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'senang':
        return Colors.green;
      case 'sedih':
        return Colors.blue;
      case 'marah':
        return Colors.red;
      case 'lelah':
        return Colors.orange;
      case 'biasa aja':
        return Colors.grey.shade600;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (moodData.isEmpty) {
      return const Center(child: Text("Tidak ada data untuk ditampilkan."));
    }

    // Mengubah data map menjadi format yang bisa dibaca oleh fl_chart
    final List<BarChartGroupData> barGroups = [];
    int x = 0;
    moodData.forEach((mood, count) {
      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: _getMoodColor(mood),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      x++;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          // Judul di bagian bawah (sumbu X)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < moodData.keys.length) {
                  final mood = moodData.keys.elementAt(index);
                  // Ambil 3 huruf pertama dan kapitalisasi
                  final shortMood = mood.length > 3 ? mood.substring(0, 3) : mood;
                  final displayText = '${shortMood[0].toUpperCase()}${shortMood.substring(1)}';
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(displayText, style: const TextStyle(fontSize: 10)),
                  );
                }
                return Container();
              },
              reservedSize: 30,
            ),
          ),
          // Sembunyikan judul di kiri, kanan, dan atas
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        // Konfigurasi lainnya
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final mood = moodData.keys.elementAt(group.x);
              final moodLabel = '${mood[0].toUpperCase()}${mood.substring(1)}';
              return BarTooltipItem(
                '$moodLabel\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: (rod.toY.toInt()).toString(),
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}