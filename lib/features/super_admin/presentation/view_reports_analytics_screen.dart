import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewReportsAnalyticsScreen extends StatelessWidget {
  const ViewReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Platform Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                    'Total Users', 'users', Icons.people, Colors.blue),
                _buildStatCard(
                    'Total Shops', 'shops', Icons.store, Colors.orange),
                _buildStatCard('Total Products', 'products', Icons.shopping_bag,
                    Colors.purple,
                    isCollectionGroup: true),
                _buildStatCard(
                    'Total Orders', 'orders', Icons.receipt_long, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Revenue Trend (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()));
                  }

                  // Calculate Last 7 Days Revenue
                  List<double> dailyRevenue = List.filled(7, 0.0);
                  DateTime now = DateTime.now();
                  DateTime startOfDay = DateTime(now.year, now.month, now.day);

                  if (orderSnapshot.hasData) {
                    for (var doc in orderSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ts = data['createdAt'] as Timestamp?;
                      if (ts != null) {
                        DateTime orderDate = ts.toDate();
                        DateTime orderDay = DateTime(
                            orderDate.year, orderDate.month, orderDate.day);
                        int daysAgo = startOfDay.difference(orderDay).inDays;

                        if (daysAgo >= 0 && daysAgo < 7) {
                          int xIndex =
                              6 - daysAgo; // 0 is 6 days ago, 6 is today
                          double total = double.tryParse(
                                  data['totalAmount']?.toString() ?? '0') ??
                              0;
                          dailyRevenue[xIndex] += total;
                        }
                      }
                    }
                  }

                  return Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 4,
                            spreadRadius: 1)
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < 0 || value.toInt() > 6)
                                  return const SizedBox.shrink();
                                // Determine day name corresponding to the index
                                int daysAgo = 6 - value.toInt();
                                DateTime targetDate =
                                    now.subtract(Duration(days: daysAgo));
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun'
                                ];
                                String dayName = days[targetDate.weekday - 1];
                                return Text(dayName,
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(7, (index) {
                              return FlSpot(
                                  index.toDouble(), dailyRevenue[index]);
                            }),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withValues(alpha: 0.2)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            const SizedBox(height: 32),
            const Text(
              'User Acquisition Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()));
                  }

                  double customerCount = 0;
                  double vendorCount = 0;
                  double riderCount = 0;

                  if (userSnapshot.hasData) {
                    for (var doc in userSnapshot.data!.docs) {
                      final role = (doc.data() as Map<String, dynamic>)['role']
                          ?.toString()
                          .toLowerCase();
                      if (role == 'customer') customerCount++;
                      if (role == 'vendor') vendorCount++;
                      if (role == 'rider') riderCount++;
                    }
                  }

                  return Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 4,
                            spreadRadius: 1)
                      ],
                    ),
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final roles = [
                                  'Customers',
                                  'Vendors',
                                  'Riders'
                                ];
                                if (value.toInt() >= 0 &&
                                    value.toInt() < roles.length) {
                                  return Text(roles[value.toInt()],
                                      style: const TextStyle(fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(
                                toY: customerCount,
                                color: Colors.blue,
                                width: 16,
                                borderRadius: BorderRadius.circular(4))
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(
                                toY: vendorCount,
                                color: Colors.orange,
                                width: 16,
                                borderRadius: BorderRadius.circular(4))
                          ]),
                          BarChartGroupData(x: 2, barRods: [
                            BarChartRodData(
                                toY: riderCount,
                                color: Colors.purple,
                                width: 16,
                                borderRadius: BorderRadius.circular(4))
                          ]),
                        ],
                      ),
                    ),
                  );
                }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String collection, IconData icon, Color color,
      {bool isCollectionGroup = false}) {
    Stream<QuerySnapshot> stream = isCollectionGroup
        ? FirebaseFirestore.instance.collectionGroup(collection).snapshots()
        : FirebaseFirestore.instance.collection(collection).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }

        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 28),
                    Text(
                      count,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
