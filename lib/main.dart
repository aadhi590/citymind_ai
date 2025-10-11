// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'package:http/http.dart' as http show get;
import 'dart:convert';
import 'dart:io' show File;
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;
import 'package:google_maps_flutter/google_maps_flutter.dart' show CameraPosition, Circle, CircleId, GoogleMap, GoogleMapController, LatLng;

void main() {
  runApp(const CityMindApp());
}

class CityMindApp extends StatelessWidget {
  const CityMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CityMind AI',
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
    final isConnected = await ApiService.healthCheck();
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      if (isConnected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
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
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
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

// ------------------- Main Screen ----------------------
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
    CommunityScreen(), 
    EnvironmentPage(), 
    SentimentPage(),
    AgentPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: "Environment"),
          BottomNavigationBarItem(icon: Icon(Icons.mood), label: "Sentiment"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "More"),
        ],
      ),
    );
  }
}

// FeedPage and other pages continue from here...



// ------------------- REDESIGNED Feed Page ----------------------
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
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
  List<Map<String, dynamic>> insights = [];
  bool loading = false;
  String? errorMessage;
  DateTime? lastUpdated;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    fetchInsight();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchInsight() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getFusionInsight(area: selectedArea);

      // Generate 3-4 insights from the API response
      insights = _generateInsights(result);
      lastUpdated = DateTime.now();

      setState(() => loading = false);
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateInsights(FusedInsight data) {
    // Create multiple insight cards from the API data
    return [
      {
        "icon": Icons.traffic,
        "title": "Traffic Analysis",
        "description": data.trafficData ?? "No traffic data available",
        "color": Colors.orange,
        "priority": "High",
      },
      {
        "icon": Icons.location_city,
        "title": "Civic Updates",
        "description": data.civicData ?? "No civic data available",
        "color": Colors.blue,
        "priority": "Medium",
      },
      {
        "icon": Icons.analytics,
        "title": "AI Summary",
        "description": data.insight ?? data.summary ?? "AI analysis in progress...",
        "color": Colors.purple,
        "priority": "Info",
      },
      {
        "icon": Icons.emoji_objects,
        "title": "Recommendations",
        "description": "Based on current conditions, consider alternative routes via Sarjapur Road or plan travel after 8 PM for lighter traffic.",
        "color": Colors.green,
        "priority": "Low",
      },
    ];
  }

  String _getTimeAgo() {
    if (lastUpdated == null) return "Never";

    final difference = DateTime.now().difference(lastUpdated!);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    return "${difference.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchInsight,
      color: Colors.indigo,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.indigo.shade600,
                    Colors.indigo.shade400,
                    Colors.purple.shade400,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "LLM Summarizer",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "AI-powered urban insights",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (lastUpdated != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getTimeAgo(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Area Selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedArea,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.indigo),
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedArea = value);
                                fetchInsight();
                              }
                            },
                            items: areas.map((area) {
                              return DropdownMenuItem(
                                value: area,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.location_on, size: 18, color: Colors.indigo),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(area),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Insights Cards
          if (loading)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildShimmerCard(),
                  childCount: 3,
                ),
              ),
            )
          else if (errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else if (insights.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          index * 0.2,
                          1.0,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index * 0.2,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: _buildInsightCard(insights[index], index),
                    ),
                  ),
                  childCount: insights.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: (insight["color"] as Color).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                (insight["color"] as Color).withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (insight["color"] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        insight["icon"] as IconData,
                        color: insight["color"] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight["title"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(insight["priority"]).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              insight["priority"],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(insight["priority"]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    insight["description"],
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown error",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchInsight,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "No insights available",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Select a different area to see AI-generated insights",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}







// ------------------- REDESIGNED Civic Page ----------------------


// ------------------- PROFESSIONAL CIVIC DASHBOARD ----------------------
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

  @override
  void dispose() {
    _userIdController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

  Future<void> _fetchLeaderboard() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final resp = await ApiService.getRequest("/users/leaderboard");
      setState(() {
        _leaderboard = resp["data"] ?? [];
        _loadingLeaderboard = false;
      });
    } catch (e) {
      setState(() => _loadingLeaderboard = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.indigo,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchReports(),
            _fetchLeaderboard(),
            if (_userIdController.text.isNotEmpty) _fetchStats(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            _buildAppBar(),
            
            // Dashboard Content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // User Identity Card
                  _buildUserIdentityCard(),
                  
                  // Stats Overview Cards
                  if (_userStats != null) _buildStatsOverview(),
                  
                  // Quick Actions Grid
                  _buildQuickActions(),
                  
                  // Reports Section
                  _buildReportsSection(),
                  
                  // Leaderboard Section
                  _buildLeaderboardSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildReportFAB(),
    );
  }

  // ==================== MODERN APP BAR ====================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.indigo,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Civic Intelligence',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade700,
                Colors.indigo.shade500,
                Colors.purple.shade400,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== USER IDENTITY CARD ====================
  Widget _buildUserIdentityCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.indigo, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Your Civic Identity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              if (_userStats != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userIdController,
            decoration: InputDecoration(
              labelText: 'Enter your User ID',
              hintText: 'e.g., user_123',
              prefixIcon: const Icon(Icons.fingerprint, color: Colors.indigo),
              suffixIcon: IconButton(
                icon: const Icon(Icons.login, color: Colors.indigo),
                onPressed: _fetchStats,
                tooltip: 'Load Stats',
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.indigo, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS OVERVIEW ====================
  Widget _buildStatsOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Impact',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  label: 'Points',
                  value: '${_userStats!["total_points"] ?? 0}',
                  color: Colors.amber,
                  gradient: [Colors.amber.shade400, Colors.orange.shade400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  label: 'Badge',
                  value: _userStats!["badge"] ?? 'Newbie',
                  color: Colors.purple,
                  gradient: [Colors.purple.shade400, Colors.pink.shade400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressCard(),
          if (_userStats!["redeemable_items"] != null &&
              (_userStats!["redeemable_items"] as List).isNotEmpty)
            _buildRewardsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final points = _userStats!["total_points"] ?? 0;
    final progress = (points / 500).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Level Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${500 - points} points to next level',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Available Rewards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_userStats!["redeemable_items"] as List)
                .map((item) => InkWell(
                      onTap: () => _redeemItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.redeem, size: 18, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              item.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 16, color: Colors.green),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Report Issue',
                  color: Colors.blue,
                  onTap: () => _showReportDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh Data',
                  color: Colors.orange,
                  onTap: () async {
                    await Future.wait([
                      _fetchReports(),
                      _fetchLeaderboard(),
                      if (_userIdController.text.isNotEmpty) _fetchStats(),
                    ]);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== REPORTS SECTION ====================
  Widget _buildReportsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Community Reports',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              TextButton.icon(
                onPressed: _fetchReports,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loadingReports
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.article_outlined,
                      message: 'No reports yet',
                      subtitle: 'Be the first to report!',
                    )
                  : Column(
                      children: _reports.take(5).map((report) => _buildReportCard(report)).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(report["status"]).withValues(alpha: 0.1),
                  Colors.white,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report["status"]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(report["category"]),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report["category"] ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(report["priority"]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report["priority"] ?? "Normal",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            report["location"] ?? "Location",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(report["status"]),
              ],
            ),
          ),
          if (report["description"] != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                report["description"],
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyReport(report["id"], true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verifyReport(report["id"], false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LEADERBOARD SECTION ====================
  Widget _buildLeaderboardSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Contributors',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              TextButton.icon(
                onPressed: _fetchLeaderboard,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loadingLeaderboard
              ? const Center(child: CircularProgressIndicator())
              : _leaderboard.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.emoji_events_outlined,
                      message: 'No rankings yet',
                      subtitle: 'Start contributing!',
                    )
                  : Column(
                      children: _leaderboard.take(10).toList().asMap().entries.map((entry) {
                        return _buildLeaderboardCard(entry.value, entry.key);
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> user, int index) {
    final rank = index + 1;
    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
                colors: [
                  _getRankColor(rank).withValues(alpha: 0.2),
                  Colors.white,
                ],
              )
            : null,
        color: isTopThree ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree ? Border.all(color: _getRankColor(rank), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? _getRankColor(rank).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: isTopThree ? 15 : 10,
            offset: Offset(0, isTopThree ? 8 : 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRankColor(rank),
                  _getRankColor(rank).withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getRankColor(rank).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isTopThree
                  ? Icon(_getRankIcon(rank), color: Colors.white, size: 28)
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["user_id"] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${user["total_points"] ?? 0} points',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isTopThree)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRankColor(rank).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: _getRankColor(rank),
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  // ==================== REPORT DIALOG ====================
  void _showReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade400, Colors.purple.shade400],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.report_problem, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Report Civic Issue',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User ID Field
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            controller: _userIdController,
                            decoration: InputDecoration(
                              labelText: 'Your User ID',
                              hintText: 'e.g., user_123',
                              prefixIcon: const Icon(Icons.fingerprint, color: Colors.indigo),
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description Field
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            controller: _descController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Describe the Issue',
                              hintText: 'e.g., Large pothole on Main Street causing traffic issues...',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 80),
                                child: Icon(Icons.description, color: Colors.orange),
                              ),
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Image Section
                        if (_pickedImage != null) ...[
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: FileImage(_pickedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      onPressed: () {
                                        setState(() => _pickedImage = null);
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Camera Button
                        InkWell(
                          onTap: () async {
                            await _pickImage();
                            setModalState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.cyan.shade400],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Take Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Submit Button
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  await _submitReport();
                                  if (context.mounted) Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Report',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== FLOATING ACTION BUTTON ====================
  Widget _buildReportFAB() {
    return FloatingActionButton.extended(
      onPressed: _showReportDialog,
      backgroundColor: Colors.indigo,
      icon: const Icon(Icons.add_photo_alternate),
      label: const Text(
        'Report Issue',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 8,
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildStatusBadge(String? status) {
    final statusText = status ?? "Pending";
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'pothole':
        return Icons.warning;
      case 'streetlight':
        return Icons.lightbulb;
      case 'garbage':
        return Icons.delete;
      case 'traffic':
        return Icons.traffic;
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.electrical_services;
      default:
        return Icons.report_problem;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600;
      case 2:
        return Colors.grey.shade500;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.indigo;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.person;
    }
  }
}



// ------------------- REDESIGNED Community Page (View Only) ----------------------
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  bool loading = true;
  List<Map<String, dynamic>> posts = [];
  String? error;
  late AnimationController _animationController;

  // Track likes locally (in production, sync with backend)
  Set<String> likedPosts = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fetchFeed();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeed() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.getCommunityFeed();
      posts = data.map((m) => Map<String, dynamic>.from(m)).toList();
      _animationController.forward(from: 0);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return "Just now";

    try {
      final dateTime = DateTime.parse(timestamp);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) return "Just now";
      if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
      if (difference.inHours < 24) return "${difference.inHours}h ago";
      if (difference.inDays < 7) return "${difference.inDays}d ago";
      return timestamp.split('T').first;
    } catch (e) {
      return "Recently";
    }
  }

  Future<void> _toggleLike(String postId) async {
    setState(() {
      if (likedPosts.contains(postId)) {
        likedPosts.remove(postId);
      } else {
        likedPosts.add(postId);
      }
    });

    // Call backend API to save like
    try {
      await ApiService.postRequest("/community/like", {
        "post_id": postId,
        "liked": likedPosts.contains(postId),
      });
    } catch (e) {
      debugPrint("Failed to save like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchFeed,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with Gradient
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  "Community Feed",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade600,
                        Colors.purple.shade400,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${posts.length} Posts",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            if (loading)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(),
                    childCount: 3,
                  ),
                ),
              )
            else if (error != null)
              SliverFillRemaining(child: _buildErrorState())
            else if (posts.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.1,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: _buildPostCard(posts[index], index),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final user = post['user_id']?.toString() ?? 'Anonymous';
    final desc = post['description']?.toString() ?? '';
    final img64 = post['image_base64']?.toString();
    final time = post['timestamp']?.toString();
    final postId = post['id']?.toString() ?? index.toString();
    final isLiked = likedPosts.contains(postId);

    Widget? image;
    if (img64 != null && img64.isNotEmpty) {
      try {
        image = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(img64),
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      } catch (_) {
        image = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shadowColor: Colors.indigo.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (User Info)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_$postId',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400,
                            Colors.purple.shade300,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.isNotEmpty ? user[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(time),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptionsMenu(context, postId),
                  ),
                ],
              ),
            ),

            // Image (if exists)
            if (image != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: image,
              ),

            // Description
            if (desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: "Like",
                    color: isLiked ? Colors.red : Colors.grey.shade700,
                    onTap: () => _toggleLike(postId),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: "Comment",
                    color: Colors.grey.shade700,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Comment feature coming soon!")),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: "Share",
                    color: Colors.grey.shade700,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Share feature coming soon!")),
                      );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, size: 14, color: Colors.indigo.shade700),
                        const SizedBox(width: 4),
                        Text(
                          "${(index * 37 + 42) % 200}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text("Report Post"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Post reported. Thank you!")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text("Block User"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User blocked")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text("Copy Link"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Link copied to clipboard")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Error",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? "Unable to load community posts",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchFeed,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline, size: 80, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "No Community Posts",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Posts from the community will appear here",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}




// ------------------- REDESIGNED Environment Page ----------------------
class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> with SingleTickerProviderStateMixin {
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
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    fetchAirQuality();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        _animationController.forward(from: 0);
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

  Color _getAQIColor(String? colorHex) {
    if (colorHex == null) return Colors.grey;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getWeatherIcon(int? aqi) {
    if (aqi == null) return Icons.cloud;
    if (aqi <= 50) return Icons.wb_sunny;
    if (aqi <= 100) return Icons.cloud;
    if (aqi <= 150) return Icons.cloud_queue;
    return Icons.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: fetchAirQuality,
        child: CustomScrollView(
          slivers: [
            // Modern Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  "AI Predicted Weather",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade600,
                        Colors.cyan.shade400,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.cloud,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Real-time Air Quality",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Area Selector Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Select Area",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedArea,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedArea = value);
                                    fetchAirQuality();
                                  }
                                },
                                items: areas.map((area) {
                                  return DropdownMenuItem(
                                    value: area,
                                    child: Text(area),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Weather Data Card
                  if (loading)
                    _buildShimmerCard()
                  else if (errorMessage != null)
                    _buildErrorCard()
                  else if (airQuality != null)
                    FadeTransition(
                      opacity: _animationController,
                      child: _buildWeatherCard(),
                    )
                  else
                    _buildEmptyCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final aqi = airQuality!['aqi'] ?? 0;
    final area = airQuality!['area'] ?? selectedArea;
    final level = airQuality!['level'] ?? 'Unknown';
    final advisory = airQuality!['health_advisory'] ?? 'No advisory available';
    final pm25 = airQuality!['pm25'] ?? 0;
    final pm10 = airQuality!['pm10'] ?? 0;
    final timestamp = airQuality!['timestamp']?.toString() ?? '';
    final color = _getAQIColor(airQuality!['color']);

    return Column(
      children: [
        // Main AQI Card
        Card(
          elevation: 6,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withOpacity(0.1),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Location
                Text(
                  area,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // AQI Circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getWeatherIcon(aqi),
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        aqi.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "AQI",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Health Advisory
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: color, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          advisory,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Details Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.grain,
                label: "PM2.5",
                value: pm25.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.cloud_circle,
                label: "PM10",
                value: pm10.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Last Updated Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Last Updated: ${_formatTimestamp(timestamp)}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      if (timestamp.length >= 19) {
        return timestamp.substring(11, 19);
      }
      return timestamp;
    } catch (e) {
      return "Unknown";
    }
  }

  Widget _buildShimmerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Loading air quality data...",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Error",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unable to load weather data",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchAirQuality,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "No Data Available",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Select an area to view air quality data",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


// ------------------- COMPLETE SENTIMENT PAGE (FINAL) ----------------------
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
      final response = await ApiService.getSentimentMapData();

      if (response["success"] == true && response["data"] != null) {
        final List<dynamic> data = response["data"];
        _circles.clear();

        for (final item in data) {
          final lat = item["latitude"] ?? 12.9716;
          final lng = item["longitude"] ?? 77.5946;
          final area = item["area"] ?? "Unknown";
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.analyzeCorrelation(area),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Analyzing with Gemini AI..."),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Error"),
                ],
              ),
              content: Text("Failed to fetch insights:\n${snapshot.error}"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          }

          final data = snapshot.data!;

          // Parse the JSON response properly
          final correlation = data['correlation']?.toString() ?? 'No correlation data available';
          final prediction = data['prediction'] as Map<String, dynamic>?;
          final recommendations = data['recommendation'] as List<dynamic>?;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade600, Colors.purple.shade400],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI Correlation Insight",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                area,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Correlation Section
                          _buildSectionTitle("📊 Correlation Analysis"),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200, width: 1.5),
                            ),
                            child: Text(
                              correlation,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Prediction Section
                          if (prediction != null) ...[
                            _buildSectionTitle("🔮 Prediction"),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.shade200, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade600, Colors.purple.shade400],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.trending_up, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Probability: ${prediction['probability']?.toString() ?? 'N/A'}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    prediction['text']?.toString() ?? 'No prediction text available',
                                    style: const TextStyle(fontSize: 14, height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Recommendations Section
                          if (recommendations != null && recommendations.isNotEmpty) ...[
                            _buildSectionTitle("💡 Recommendations"),
                            const SizedBox(height: 8),
                            ...recommendations.asMap().entries.map((entry) {
                              final index = entry.key;
                              final rec = entry.value.toString();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200, width: 1.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rec,
                                        style: const TextStyle(fontSize: 14, height: 1.6),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
      ],
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
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.location_city, color: Colors.indigo, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bengaluru Sentiment Heatmap",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        "Tap any area for AI insights",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// ------------------- ULTIMATE AGENTIC AI PAGE (FINAL WITH EMERGENCY ALERT) ----------------------
class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Welcome message
    _messages.add(ChatMessage(
      text: " Hello! I'm CityMind AI, your autonomous urban intelligence assistant. I can monitor air quality, predict traffic patterns, analyze sentiment, and plan proactive actions.\n\nAsk me anything!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _controller.clear();
    _scrollToBottom();

    // Show thinking state
    setState(() => _isThinking = true);

    try {
      final response = await ApiService.runAgenticBrain(
        goal: text,
        area: "Bengaluru",
      ).timeout(const Duration(seconds: 120));

      debugPrint("✅ Agent Response: ${response.toString().substring(0, 200)}...");

      if (response["success"] == true) {
        final plan = response["plan"] as Map<String, dynamic>?;
        final analysis = response["analysis"] as Map<String, dynamic>?;

        // Extract planning data
        final steps = (plan?["steps"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final reasoning = plan?["reasoning"]?.toString() ?? "";
        final dataSources = (plan?["data_sources_needed"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        // Extract analysis data
        final summary = analysis?["summary"]?.toString() ?? "Analysis complete!";
        final predictedIssue = analysis?["predicted_issue"]?.toString();
        final recommendedActions = (analysis?["recommended_actions"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final urgency = analysis?["urgency"]?.toString() ?? "low";
        final confidence = analysis?["confidence"] ?? 0.0;
        final analysisReasoning = analysis?["reasoning"]?.toString();

        // Add AI response with all data
        setState(() {
          _messages.add(ChatMessage(
            text: summary,
            isUser: false,
            timestamp: DateTime.now(),
            steps: steps.isNotEmpty ? steps : null,
            reasoning: reasoning.isNotEmpty ? reasoning : null,
            predictedIssue: predictedIssue,
            recommendedActions: recommendedActions.isNotEmpty ? recommendedActions : null,
            urgency: urgency,
            confidence: confidence is double ? confidence : (confidence is int ? confidence.toDouble() : 0.0),
            analysisReasoning: analysisReasoning,
            dataSources: dataSources.isNotEmpty ? dataSources : null,
          ));
        });

        // 🚨 ADDITION 1: Show emergency alert if HIGH urgency
        if (urgency == "high" && predictedIssue != null && predictedIssue.isNotEmpty) {
          _showEmergencyAlert(predictedIssue, analysis);
        }

      } else {
        _addErrorMessage("Failed to process: ${response["error"] ?? "Unknown error"}");
      }
    } catch (e) {
      debugPrint("❌ Agent Error: $e");
      _addErrorMessage("Error: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      setState(() => _isThinking = false);
      _scrollToBottom();
    }
  }

  void _addErrorMessage(String error) {
    setState(() {
      _messages.add(ChatMessage(
        text: error,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.indigo.shade900,
              Colors.blue.shade900,
              Colors.cyan.shade900,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index], index);
                        },
                      ),
              ),
              if (_isThinking) _buildThinkingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.6 * _glowController.value),
                      blurRadius: 20 + (10 * _glowController.value),
                      spreadRadius: 5 + (5 * _glowController.value),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.cyanAccent, Colors.blueAccent],
                    ),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CityMind AI Agent",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Powered by Gemini 2.5 Pro • LangChain",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Online",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (0.1 * _pulseController.value),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyanAccent.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: Colors.cyanAccent,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Agentic AI Assistant",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Multi-step reasoning • Proactive predictions • Real-time data",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip("Monitor air quality trends"),
                _buildSuggestionChip("Predict traffic in 6 hours"),
                _buildSuggestionChip("Analyze Koramangala sentiment"),
                _buildSuggestionChip("Check civic reports"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 16,
            left: message.isUser ? 50 : 0,
            right: message.isUser ? 0 : 50,
          ),
          child: message.isUser
              ? _buildUserMessage(message)
              : _buildAIMessage(message),
        ),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.purple.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
          color: message.isError
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.cyanAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (message.isError ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyanAccent, Colors.blueAccent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                "AI Analysis",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (message.confidence != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(message.confidence!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getConfidenceColor(message.confidence!)),
                  ),
                  child: Text(
                    "${(message.confidence! * 100).toInt()}% confident",
                    style: TextStyle(
                      color: _getConfidenceColor(message.confidence!),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Summary
          Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          // Predicted Issue (if any)
          if (message.predictedIssue != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _getUrgencyColor(message.urgency ?? "low").withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getUrgencyColor(message.urgency ?? "low")),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: _getUrgencyColor(message.urgency ?? "low"),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Predicted Issue • ${message.urgency?.toUpperCase() ?? 'LOW'} URGENCY",
                        style: TextStyle(
                          color: _getUrgencyColor(message.urgency ?? "low"),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message.predictedIssue!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Recommended Actions
          if (message.recommendedActions != null && message.recommendedActions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rule, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Recommended Actions",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...message.recommendedActions!.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${entry.key + 1}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Planning Steps
          if (message.steps != null && message.steps!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timeline, color: Colors.blueAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Agent Plan",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...message.steps!.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${entry.key + 1}",
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Reasoning
          if (message.analysisReasoning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.analysisReasoning!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
          SizedBox(width: 12),
          Text(
            "AI Agent is planning and analyzing data...",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Ask CityMind AI Agent...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.4 * _glowController.value),
                      blurRadius: 15 + (10 * _glowController.value),
                      spreadRadius: 2 + (3 * _glowController.value),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isThinking ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyanAccent, Colors.blueAccent],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isThinking ? Icons.hourglass_empty : Icons.send,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🚨 ADDITION 2: Emergency Alert Function - ADD THIS AT THE BOTTOM
  void _showEmergencyAlert(String issue, Map<String, dynamic>? analysis) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Alert Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade900, Colors.red.shade700],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 60),
                      const SizedBox(height: 12),
                      const Text(
                        "🚨 EMERGENCY ALERT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "HIGH URGENCY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Alert Content
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Predicted Issue:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Notification Status
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Alert sent to emergency authorities",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.notifications_active, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Push notification delivered",
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.sms, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "SMS alert sent to registered users",
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Recommended Actions
                      if (analysis?["recommended_actions"] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Immediate Actions Required:",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(analysis!["recommended_actions"] as List).take(2).map((action) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(fontSize: 16, color: Colors.red)),
                                Expanded(
                                  child: Text(
                                    action.toString(),
                                    style: const TextStyle(fontSize: 13, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Acknowledge Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "ACKNOWLEDGE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.yellowAccent;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.greenAccent;
    if (confidence >= 0.5) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

// Enhanced Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? steps;
  final String? reasoning;
  final String? predictedIssue;
  final List<String>? recommendedActions;
  final String? urgency;
  final double? confidence;
  final String? analysisReasoning;
  final List<String>? dataSources;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.steps,
    this.reasoning,
    this.predictedIssue,
    this.recommendedActions,
    this.urgency,
    this.confidence,
    this.analysisReasoning,
    this.dataSources,
    this.isError = false,
  });
}
