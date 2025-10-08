import 'dart:async';
import 'package:flutter/material.dart';
import 'api/api_service.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const CityMindApp());
}

class CityMindApp extends StatelessWidget {
  const CityMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CityMind AI",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

// ------------------- Splash Screen ----------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    // Check if backend is reachable
    final isConnected = await ApiService.healthCheck();
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      if (isConnected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Connection Error"),
            content: const Text(
              "Cannot connect to backend. Please check:\n"
              "1. Backend is running\n"
              "2. Ngrok URL is correct\n"
              "3. Internet connection"
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _checkBackendConnection();
                },
                child: const Text("Retry"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                child: const Text("Continue Anyway"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "ನಮ್ಮ ಬೆಂಗಳೂರುಗಾಗಿ",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ------------------- Bottom Navigation ----------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    FeedPage(),
    CivicPage(),
    EnvironmentPage(),
    SentimentPage(),
    MorePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CityMind AI"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh current page
              setState(() {});
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Civic"),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: "Environment"),
          BottomNavigationBarItem(icon: Icon(Icons.mood), label: "Sentiment"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "More"),
        ],
      ),
    );
  }
}

// ------------------- Feed Page ----------------------
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<String> areas = [
    "Indiranagar",
    "Koramangala",
    "HSR Layout",
    "Whitefield",
    "Jayanagar",
    "BTM Layout",
    "MG Road",
    "Malleshwaram",
  ];

  String selectedArea = "Indiranagar";
  FusedInsight? fusedInsight;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInsight();
  }

  Future<void> fetchInsight() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getFusionInsight(area: selectedArea);
      setState(() {
        fusedInsight = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchInsight,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ Area Dropdown ------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Choose Area",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedArea,
                  icon: const Icon(Icons.location_on, color: Colors.indigo),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedArea = value);
                      fetchInsight();
                    }
                  },
                  items: areas.map((area) {
                    return DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ------------------ Loading / Error / Data States ------------------
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Center(
                child: Text(
                  "⚠️ $errorMessage",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (fusedInsight == null)
              const Center(child: Text("No insights available"))
            else
              _buildInsightCard(fusedInsight!),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(FusedInsight insight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ Title ------------------
            Text(
              "🚦 ${insight.title ?? "AI Urban Insight"}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),

            // ------------------ Sub Info ------------------
            if (insight.trafficData != null)
              Text("🚗 ${insight.trafficData}",
                  style: const TextStyle(fontSize: 15)),
            if (insight.civicData != null)
              Text("🏙️ ${insight.civicData}",
                  style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),

            // ------------------ AI Summary ------------------
            Text(
              insight.insight ??
                  insight.summary ??
                  "AI could not generate an insight.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // ------------------ Info Row (Badges) ------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBadge("Impact: High", Colors.orange),
                _buildBadge("Last Updated: ${TimeOfDay.now().format(context)}", Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ------------------- Civic Page ----------------------
// 🏙️ Civic Intelligence Page (with Leaderboard)
class CivicPage extends StatefulWidget {
  const CivicPage({super.key});

  @override
  State<CivicPage> createState() => _CivicPageState();
}

class _CivicPageState extends State<CivicPage> {
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  final _userIdController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;
  bool _loadingReports = true;
  bool _loadingLeaderboard = true;
  List<dynamic> _reports = [];
  List<dynamic> _leaderboard = [];
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _fetchLeaderboard();
  }

  // ✅ Fetch reports
  Future<void> _fetchReports() async {
    setState(() => _loadingReports = true);
    try {
      final resp = await ApiService.getRequest("/civic/reports");
      setState(() {
        _reports = resp["data"] ?? [];
        _loadingReports = false;
      });
    } catch (e) {
      _show("Failed to fetch reports: $e");
      setState(() => _loadingReports = false);
    }
  }

  // ✅ Fetch user stats
  Future<void> _fetchStats() async {
    if (_userIdController.text.isEmpty) {
      _show("Enter User ID to fetch stats");
      return;
    }
    try {
      final resp = await ApiService.getRequest("/civic/user/${_userIdController.text}/stats");
      setState(() => _userStats = resp["data"]);
    } catch (e) {
      _show("Failed to fetch stats: $e");
    }
  }

  // ✅ Fetch leaderboard (top 5)
  Future<void> _fetchLeaderboard() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final resp = await ApiService.getRequest("/users/leaderboard");
      setState(() {
        _leaderboard = resp["data"] ?? [];
        _loadingLeaderboard = false;
      });
    } catch (e) {
      debugPrint("Leaderboard fetch failed: $e");
      setState(() => _loadingLeaderboard = false);
    }
  }

  // ✅ Pick image
  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  // ✅ Create civic report
  Future<void> _submitReport() async {
    if (_userIdController.text.isEmpty || _descController.text.isEmpty) {
      _show("User ID and description required");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String imgBase64 = "";
      if (_pickedImage != null) {
        imgBase64 = base64Encode(await _pickedImage!.readAsBytes());
      }

      final body = {
        "user_id": _userIdController.text,
        "latitude": 12.9716,
        "longitude": 77.5946,
        "description": _descController.text,
        "image_base64": imgBase64,
      };

      final resp = await ApiService.postRequest("/civic/report", body);
      _show(resp["message"] ?? "Report submitted successfully");

      _descController.clear();
      setState(() => _pickedImage = null);
      await Future.wait([_fetchReports(), _fetchStats(), _fetchLeaderboard()]);
    } catch (e) {
      _show("Submission failed: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ✅ Verify report
  Future<void> _verifyReport(String id, bool valid) async {
    if (_userIdController.text.isEmpty) {
      _show("User ID required for verification");
      return;
    }

    try {
      final body = {"report_id": id, "user_id": _userIdController.text, "is_valid": valid};
      final resp = await ApiService.postRequest("/civic/verify", body);
      _show(resp["message"] ?? "Verification done");
      await Future.wait([_fetchReports(), _fetchStats()]);
    } catch (e) {
      _show("Verification failed: $e");
    }
  }

  // ✅ Redeem reward
  Future<void> _redeemItem(String item) async {
    try {
      final resp = await ApiService.postRequest("/civic/redeem/${_userIdController.text}", {"item": item});
      _show(resp["message"] ?? "Redeemed successfully!");
      await _fetchStats();
    } catch (e) {
      _show("Redeem failed: $e");
    }
  }

  void _show(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏙️ Civic Intelligence")),
      body: RefreshIndicator(
        onRefresh: () async =>
            await Future.wait([_fetchReports(), _fetchStats(), _fetchLeaderboard()]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 User Stats Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _userIdController,
                            decoration: const InputDecoration(labelText: "Enter User ID"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(onPressed: _fetchStats, child: const Text("Stats")),
                      ]),
                      const SizedBox(height: 8),
                      if (_userStats != null) ...[
                        Text("Points: ${_userStats!["total_points"] ?? 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: ((_userStats!["total_points"] ?? 0) / 500).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                        ),
                        const SizedBox(height: 6),
                        Text("Badge: ${_userStats!["badge"] ?? "N/A"}"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List<Widget>.from(
                            (_userStats!["redeemable_items"] ?? [])
                                .map((e) => ElevatedButton(
                                    onPressed: () => _redeemItem(e),
                                    child: Text("Redeem $e"))),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 Report Creation Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("📸 Report Civic Issue",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Description of the issue",
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Add Image"),
                          ),
                          const SizedBox(width: 10),
                          if (_pickedImage != null)
                            Expanded(
                              child: Image.file(_pickedImage!,
                                  height: 80, fit: BoxFit.cover),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Submit Report"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 Leaderboard Section
              const Text("🏆 Top Citizens Leaderboard",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_loadingLeaderboard)
                const Center(child: CircularProgressIndicator())
              else if (_leaderboard.isEmpty)
                const Text("No users yet")
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, i) {
                    final u = _leaderboard[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text("${i + 1}", style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(u["user_id"] ?? "Unknown"),
                      subtitle: Text("Points: ${u["total_points"] ?? 0}"),
                    );
                  },
                ),

              const SizedBox(height: 12),

              // 🔹 Reports List
              const Text("Community Reports",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_loadingReports)
                const Center(child: CircularProgressIndicator())
              else if (_reports.isEmpty)
                const Center(child: Text("No civic reports yet"))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reports.length,
                  itemBuilder: (context, i) {
                    final r = _reports[i];
                    return Card(
                      elevation: 1,
                      child: ListTile(
                        title: Text("${r["category"] ?? "Unknown"} - ${r["priority"] ?? ""}"),
                        subtitle: Text("Status: ${r["status"] ?? "Pending"}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == "confirm") _verifyReport(r["id"], true);
                            if (val == "reject") _verifyReport(r["id"], false);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: "confirm", child: Text("✅ Confirm")),
                            const PopupMenuItem(value: "reject", child: Text("❌ Reject")),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- Environment Page ----------------------
class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  final List<String> areas = [
    "Indiranagar",
    "Koramangala",
    "Whitefield",
    "MG Road",
    "HSR Layout",
    "Electronic City",
    "Marathahalli",
    "BTM Layout",
    "Jayanagar",
    "Malleshwaram"
  ];

  String selectedArea = "Indiranagar";
  Map<String, dynamic>? airQuality;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAirQuality();
  }

  Future<void> fetchAirQuality() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/environment/air-quality?area=$selectedArea"),
        headers: {"ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          airQuality = data["data"];
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load data (status ${response.statusCode})";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching air quality: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchAirQuality,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Select Area",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Dropdown to select area
          DropdownButtonFormField<String>(
            initialValue: selectedArea,
            items: areas
                .map((area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedArea = value);
                fetchAirQuality();
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          else if (airQuality != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${airQuality!['area']}",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "AQI: ${airQuality!['aqi']}",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(
                              int.parse(
                                  airQuality!['color'].replaceFirst('#', '0xff')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${airQuality!['level']}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          airQuality!['health_advisory'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "PM2.5: ${airQuality!['pm25']} | PM10: ${airQuality!['pm10']}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Last Updated: ${airQuality!['timestamp'].toString().substring(11, 19)}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            const Center(child: Text("No data available")),
        ],
      ),
    );
  }
}

// ------------------- Other Pages ----------------------
// ---------------- Sentiment Page (with Heatmap) ----------------
class SentimentPage extends StatefulWidget {
  const SentimentPage({super.key});

  @override
  State<SentimentPage> createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Circle> _circles = {};
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSentimentMap();
  }

  Future<void> fetchSentimentMap() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getRequest("/correlation/sentiment-map");

      if (response["success"] == true && response["data"] != null) {
        final List<dynamic> data = response["data"];
        _circles.clear();

        for (final item in data) {
          final lat = item["latitude"] ?? 12.9716;
          final lng = item["longitude"] ?? 77.5946;
          final area = item["area"] ?? "Unknown";
          final sentiment = item["sentiment"] ?? "Neutral";
          final colorHex = item["color"] ?? "#FFEA00";

          final color = _parseColor(colorHex);

          _circles.add(
            Circle(
              circleId: CircleId(area),
              center: LatLng(lat, lng),
              radius: 500,
              fillColor: color,
              strokeColor: Colors.transparent,
              consumeTapEvents: true,
              onTap: () => _showCorrelationInsight(area),
            ),
          );
        }

        setState(() => loading = false);
      } else {
        setState(() {
          loading = false;
          errorMessage = "No sentiment data available";
        });
      }
    } catch (e) {
      debugPrint("Error fetching sentiment map: $e");
      setState(() {
        loading = false;
        errorMessage = "Connection error. Please check your backend.";
      });
    }
  }

  Future<void> _showCorrelationInsight(String area) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.analyzeCorrelation(area),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text("⚠️ Failed to fetch insights for $area"),
              );
            }

            final data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🧠 AI Correlation Insight - $area",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data["insight_text"] ?? "No analysis available.",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "🔹 Model: ${data['model'] ?? 'Mock'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse("0x$hexColor"));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Analyzing city sentiment..."),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 12),
              Text(errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: fetchSentimentMap,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(12.9716, 77.5946),
            zoom: 12,
          ),
          circles: _circles,
          onMapCreated: (controller) => _controller.complete(controller),
          zoomControlsEnabled: false,
          myLocationEnabled: false,
          compassEnabled: true,
        ),
        Positioned(
          top: 20,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4)
              ],
            ),
            child: const Text(
              "Bengaluru Sentiment Heatmap",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: 24),
            const Text(
              "Predictive Cascades + Agentic Actions",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              "(Phase 2 Demo Area)",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}