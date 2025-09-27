import 'dart:async';
import 'package:flutter/material.dart';

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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: const Center(
        child: Text(
          "ನಮ್ಮ ಬೆಂಗಳೂರುಗಾಗಿ", // For Namma Bengaluru
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

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

// ------------------- Pages ----------------------

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            title: Text("Insight #$index"),
            subtitle: const Text("AI fused summary placeholder"),
          ),
        );
      },
    );
  }
}

class CivicPage extends StatelessWidget {
  const CivicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt),
            label: const Text("Report Civic Issue"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Community verification & escalation will appear here."),
        ],
      ),
    );
  }
}

class EnvironmentPage extends StatelessWidget {
  const EnvironmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      children: const [
        InfoCard(title: "Air Quality", value: "AQI 92"),
        InfoCard(title: "Water Quality", value: "Safe"),
        InfoCard(title: "Flood Alerts", value: "None"),
        InfoCard(title: "Heat Index", value: "32°C"),
      ],
    );
  }
}

class SentimentPage extends StatelessWidget {
  const SentimentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Urban mood map placeholder (to be integrated)."),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Predictive Cascades + Agentic Actions\n(Phase 2 Demo Area)",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// ------------------- Reusable Widgets ----------------------

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(color: Colors.indigo, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
