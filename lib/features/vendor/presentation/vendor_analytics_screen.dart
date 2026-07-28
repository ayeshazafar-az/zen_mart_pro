import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Store Analytics')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .where('vendorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!shopSnapshot.hasData || shopSnapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No shop assigned to your account.'));
          }

          final shopId = shopSnapshot.data!.docs.first.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Store Overview',
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
                    _buildOrdersStatCard(shopId),
                    _buildProductsStatCard(shopId),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Earnings Trend (Last 7 Days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildRevenueChart(shopId, context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersStatCard(String shopId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('shopId', isEqualTo: shopId)
          .snapshots(),
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }

        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.withValues(alpha: 0.8), Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const Spacer(),
                  Text(
                    count,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text(
                    'Total Orders',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsStatCard(String shopId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .snapshots(),
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }

        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.withValues(alpha: 0.8), Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.inventory, color: Colors.white, size: 28),
                  const Spacer(),
                  Text(
                    count,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text(
                    'Total Products',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart(String shopId, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('shopId', isEqualTo: shopId)
          .snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 250, child: Center(child: CircularProgressIndicator()));
        }

        // Calculate Last 7 Days Revenue (Earnings = Subtotal)
        List<double> dailyRevenue = List.filled(7, 0.0);
        DateTime now = DateTime.now();
        DateTime startOfDay = DateTime(now.year, now.month, now.day);

        if (orderSnapshot.hasData) {
          for (var doc in orderSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['createdAt'] as Timestamp?;
            final status = data['status']?.toString();

            // Only count non-rejected orders ideally, but since we are mirroring admin, we'll just sum.
            // (Assuming earnings only if not cancelled/rejected)
            if (status != 'Rejected' && status != 'Cancelled' && ts != null) {
              DateTime orderDate = ts.toDate();
              DateTime orderDay =
                  DateTime(orderDate.year, orderDate.month, orderDate.day);
              int daysAgo = startOfDay.difference(orderDay).inDays;

              if (daysAgo >= 0 && daysAgo < 7) {
                int xIndex = 6 - daysAgo; // 0 is 6 days ago, 6 is today
                double subtotal =
                    double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0;

                // Fallback to totalAmount if subtotal doesn't exist for older orders
                if (subtotal == 0) {
                  subtotal =
                      double.tryParse(data['totalAmount']?.toString() ?? '0') ??
                          0;
                }

                dailyRevenue[xIndex] += subtotal;
              }
            }
          }
        }

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        'Rs. ${spot.y.toStringAsFixed(2)}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Text('Rs.${value.toInt()}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < 0 || value.toInt() > 6) {
                        return const SizedBox.shrink();
                      }
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
                    return FlSpot(index.toDouble(), dailyRevenue[index]);
                  }),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                      show: true, color: Colors.blue.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
