import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/auth_service.dart';
import 'edit_review-screen.dart';

// Strona wyświetlająca wszystkie recenzje użytkownika
class SeeMyReviewPage extends StatefulWidget {
  const SeeMyReviewPage({super.key});

  @override
  State<SeeMyReviewPage> createState() => _SeeMyReviewPageState();
}

class _SeeMyReviewPageState extends State<SeeMyReviewPage> {
  final DatabaseReference reviewsRef =
  FirebaseDatabase.instance.ref().child('reviews'); // Referencja do tabeli recenzji w Firebase

  List<Map<String, dynamic>> allReviews = [];
  List<Map<String, dynamic>> filteredReviews = [];

  String searchQuery = '';
  String? selectedType;
  String? selectedTransducer;
  String? selectedImpedance;
  String? selectedSound;
  String? selectedBrand;

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser; // Pobranie aktualnie zalogowanego użytkownika
    final String currentUserEmail = user?.email ?? 'Brak emaila'; // Pobranie emaila użytkownika lub default string

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje Recenzje'),
      ),
      body: Column(
        children: [
          // Wyszukiwarka
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Szukaj modelu lub marki',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                  _applyFilters();
                });
              },
            ),
          ),

          // Filtry
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildDropdown<String>(
                  label: 'Typ',
                  value: selectedType,
                  items: const ['przewodowe', 'bezprzewodowe'],
                  onChanged: (val) {
                    setState(() {
                      selectedType = val;
                      _applyFilters();
                    });
                  },
                ),
                _buildDropdown<String>(
                  label: 'Przetwornik',
                  value: selectedTransducer,
                  items: const ['Dynamiczny', 'Planarny', 'Elektrostatyczny'],
                  onChanged: (val) {
                    setState(() {
                      selectedTransducer = val;
                      _applyFilters();
                    });
                  },
                ),
                _buildDropdown<String>(
                  label: 'Impedancja',
                  value: selectedImpedance,
                  items: const ['16 Ω', '32 Ω', '64 Ω', '150 Ω', '300 Ω'],
                  onChanged: (val) {
                    setState(() {
                      selectedImpedance = val;
                      _applyFilters();
                    });
                  },
                ),
                _buildDropdown<String>(
                  label: 'Brzmienie',
                  value: selectedSound,
                  items: const ['Ciepłe', 'Neutralne', 'V-shape', 'Jasne'],
                  onChanged: (val) {
                    setState(() {
                      selectedSound = val;
                      _applyFilters();
                    });
                  },
                ),
                _buildDropdown<String>(
                  label: 'Marka',
                  value: selectedBrand,
                  items: const [
                    'Sony',
                    'Bose',
                    'Sennheiser',
                    'AKG',
                    'Audio-Technica'
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedBrand = val;
                      _applyFilters();
                    });
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      selectedType = null;
                      selectedTransducer = null;
                      selectedImpedance = null;
                      selectedSound = null;
                      selectedBrand = null;
                      filteredReviews = List.from(allReviews);
                    });
                  },
                  child: const Text('Resetuj filtry'),
                )
              ],
            ),
          ),

          // Lista recenzji
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: reviewsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Błąd: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('Brak recenzji'));
                }

                final data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                allReviews = data.entries.map((entry) {
                  final val = entry.value as Map<dynamic, dynamic>;
                  final userMap = val['user'] as Map<dynamic, dynamic>?;

                  String reviewEmail = userMap?['email']?.toString() ?? '';

                  List<Map<String, dynamic>> freqList = [];
                  if (val['frequencyResponse'] != null &&
                      val['frequencyResponse'] is List) {
                    freqList = (val['frequencyResponse'] as List)
                        .map((item) => {
                      'frequency': double.tryParse(
                          item['frequency'].toString()) ??
                          0.0,
                      'value': (item['value'] as num?)?.toDouble() ??
                          0.0
                    })
                        .toList();
                  }

                  List<String> images = [];
                  if (val['images'] != null && val['images'] is List) {
                    images = List<String>.from(val['images']);
                  }

                  return {
                    'key': entry.key,
                    'model': val['model']?.toString() ?? '',
                    'review': val['review']?.toString() ?? '',
                    'type': val['type']?.toString() ?? '',
                    'transducer': val['transducer']?.toString() ?? '',
                    'impedance': val['impedance']?.toString() ?? '',
                    'sound': val['sound']?.toString() ?? '',
                    'brand': val['brand']?.toString() ?? '',
                    'email': reviewEmail,
                    'images': images,
                    'frequencyResponse': freqList,
                  };
                }).where((review) {
                  return review['email'] == currentUserEmail;
                }).toList();

                if (filteredReviews.isEmpty &&
                    searchQuery.isEmpty &&
                    selectedType == null) {
                  filteredReviews = List.from(allReviews);
                }

                return filteredReviews.isEmpty
                    ? const Center(
                    child: Text('Brak recenzji do wyświetlenia'))
                    : ListView.builder(
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    final review = filteredReviews[index];
                    final shortReview = review['review'].length > 50
                        ? '${review['review'].substring(0, 50)}...'
                        : review['review'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: review['images'].isNotEmpty
                            ? Image.network(
                          review['images'][0],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.image),
                        title:
                        Text('${review['brand']} ${review['model']}'),
                        subtitle: Text(shortReview),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditReviewPage(
                                      reviewKey: review['key'],
                                      review: review,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  _deleteReview(review['key']),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullReviewPage(
                                brand: review['brand'],
                                model: review['model'],
                                review: review['review'],
                                images: review['images'],
                                user: review['email'],
                                frequencyResponse:
                                review['frequencyResponse'] ?? [],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<T>(
        hint: Text(label),
        value: value,
        items: [
           DropdownMenuItem<T>(
            value: null,
            child: Text('Wszystkie'),
          ),
          ...items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          ))
        ],
        onChanged: onChanged,
      ),
    );
  }

  void _applyFilters() {   // Funkcja do zastosowania filtrów
    filteredReviews = allReviews.where((review) {
      final matchesSearch = searchQuery.isEmpty ||
          review['model'].toLowerCase().contains(searchQuery) ||
          review['brand'].toLowerCase().contains(searchQuery);

      final matchesType =
          selectedType == null || review['type'] == selectedType;
      final matchesTransducer = selectedTransducer == null ||
          review['transducer'] == selectedTransducer;
      final matchesImpedance = selectedImpedance == null ||
          review['impedance'] == selectedImpedance;
      final matchesSound =
          selectedSound == null || review['sound'] == selectedSound;
      final matchesBrand =
          selectedBrand == null || review['brand'] == selectedBrand;

      return matchesSearch &&
          matchesType &&
          matchesTransducer &&
          matchesImpedance &&
          matchesSound &&
          matchesBrand;
    }).toList();
  }

  Future<void> _deleteReview(String key) async {
    try {
      await reviewsRef.child(key).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recenzja usunięta')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania: $e')),
      );
    }
  }
}

// Pełny widok recenzji
class FullReviewPage extends StatelessWidget {
  final String brand;
  final String model;
  final String review;
  final List<String> images;
  final String user;
  final List<Map<String, dynamic>> frequencyResponse;

  const FullReviewPage({
    super.key,
    required this.brand,
    required this.model,
    required this.review,
    required this.images,
    required this.user,
    required this.frequencyResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$brand $model'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recenzja od: $user',
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.network(images[index], fit: BoxFit.cover),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(review, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text("Frequency Response:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            FrequencyResponseDisplay(freqData: frequencyResponse),
          ],
        ),
      ),
    );
  }
}

// wykres FR
class FrequencyResponseDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> freqData;

  const FrequencyResponseDisplay({super.key, required this.freqData});

  @override
  Widget build(BuildContext context) {
    if (freqData.isEmpty) {
      return const Text('Brak danych FR');
    }

    List<FlSpot> spots = freqData
        .map((e) => FlSpot(
        (e['frequency'] as double?) ?? 0.0, (e['value'] as double?) ?? 0.0))
        .toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.purple,
              dotData: FlDotData(show: false),
            )
          ],
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles:
                SideTitles(showTitles: true, reservedSize: 40, interval: 5)),
            bottomTitles: AxisTitles(
                sideTitles:
                SideTitles(showTitles: true, interval: 1000)),
          ),
        ),
      ),
    );
  }
}
