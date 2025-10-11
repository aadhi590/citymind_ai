import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://reconcilable-paulene-lukewarmly.ngrok-free.dev";
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  // -------------------- Generic HTTP Helpers --------------------
 static Future<Map<String, dynamic>> _get(String endpoint, {bool useCache = false}) async {
  try {
    final url = '$baseUrl$endpoint';
    debugPrint("🌐 Request → $url");

    final response = await http.get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('Failed: ${response.statusCode}');
    }
  } on TimeoutException {
    throw ApiException('⏰ Request timed out. Try again.');
  } catch (e) {
    debugPrint("❌ GET error: $e");
    throw ApiException('Failed to connect: $e');
  }
}

  static Future<Map<String, dynamic>> getRequest(String endpoint) async {
    return await _get(endpoint);
  }

  static Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint("POST → $url\nBody: ${json.encode(body)}");

      final response = await http
          .post(Uri.parse(url), headers: _headers, body: json.encode(body))
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException('POST failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ApiException('⏰ Request timeout. Please check your connection.');
    } catch (e) {
      throw ApiException('❌ Failed to connect: ${e.toString()}');
    }
  }
  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
  return await _post(endpoint, body);
}
  

  // -------------------- Environment --------------------

  static Future<AirQualityData> getAirQuality({required String area}) async {
    final response = await _get('/environment/air-quality?area=$area');
    return AirQualityData.fromJson(response['data']);
  }

  static Future<WaterQualityData> getWaterQuality({required String lakeName}) async {
    final response = await _get('/environment/water-quality?lake_name=$lakeName');
    return WaterQualityData.fromJson(response['data']);
  }

  // -------------------- Fusion --------------------

  static Future<List<FusedInsight>> getFusedInsights() async {
    try {
      final response = await _get('/fusion/insights');
      final List<dynamic> data = response['data'] ?? response['insights'] ?? [];
      return data.map((item) => FusedInsight.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error getting fused insights: $e");
      return [];
    }
  }

  static Future<FusedInsight> getFusionInsight({required String area}) async {
    try {
      final response = await _get('/fusion/process?area=$area');
      return FusedInsight.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching fusion insight for $area: $e");
      throw ApiException('Failed to fetch insight for $area');
    }
  }

  // -------------------- Correlation (Sentiment + Analysis) --------------------

  static Future<Map<String, dynamic>> getCorrelationDummy() async {
    try {
      final response = await _get('/correlation/dummy');
      return response;
    } catch (e) {
      debugPrint("Error getting correlation dummy: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> analyzeCorrelation(String zone) async {
  try {
    final response = await _post('/correlation/analyze', {'zone': zone});
    return response;
  } catch (e) {
    debugPrint("Error analyzing correlation: $e");
    throw ApiException("Failed to analyze correlation for $zone");
  }
}

  // ✅ New endpoint for Sentiment Heatmap (Bengaluru Map)
  static Future<Map<String, dynamic>> getSentimentMapData() async {
    try {
      final response = await _get('/correlation/sentiment-map');
      if (response.containsKey('data')) {
        return response;
      } else {
        throw ApiException("Invalid response from backend");
      }
    } catch (e) {
      debugPrint("Error fetching sentiment map data: $e");
      throw ApiException("Failed to fetch sentiment map data: $e");
    }
  }

  // -------------------- Cascade Prediction --------------------

  static Future<Map<String, dynamic>> getCascadePredictions() async {
    try {
      return await _get('/cascade/predictions');
    } catch (e) {
      debugPrint("Error getting cascade predictions: $e");
      return {};
    }
  }

  // -------------------- Civic Issues --------------------

 // ---------------- CIVIC INTELLIGENCE (Objective 2) ----------------

// 1️⃣ Create a new civic report (AI + image upload)
static Future<Map<String, dynamic>> createCivicReport({
  required String userId,
  required String imageBase64,
  required String description,
  required double latitude,
  required double longitude,
}) async {
  final body = {
    "user_id": userId,
    "image_base64": imageBase64,
    "description": description,
    "latitude": latitude,
    "longitude": longitude,
  };
  return await _post("/civic/report", body);
}

// 2️⃣ Verify a civic report
static Future<Map<String, dynamic>> verifyCivicReport({
  required String reportId,
  required String userId,
  required bool isValid,
}) async {
  final body = {
    "report_id": reportId,
    "user_id": userId,
    "is_valid": isValid,
  };
  return await _post("/civic/verify", body);
}

// 3️⃣ Fetch all civic reports (optionally filter by status or category)
static Future<List<Map<String, dynamic>>> getAllCivicReports({
  String? status,
  String? category,
}) async {
  final queryParams = <String, String>{};
  if (status != null) queryParams["status"] = status;
  if (category != null) queryParams["category"] = category;

  final query = queryParams.entries
      .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
      .join("&");

  final response = await _get(
    "/civic/reports${query.isNotEmpty ? '?$query' : ''}",
    useCache: true,
  );

  return List<Map<String, dynamic>>.from(response["data"] ?? []);
}

// 4️⃣ Fetch a specific report by ID
static Future<Map<String, dynamic>> getCivicReportDetails(String reportId) async {
  final response = await _get("/civic/report/$reportId", useCache: true);
  return response["data"];
}

// 5️⃣ Fetch user statistics (points, badge, rewards)
static Future<Map<String, dynamic>> getUserStats(String userId) async {
  final response = await _get("/civic/user/$userId/stats", useCache: false);
  return response["data"];
}

// 6️⃣ Redeem a reward using user points
static Future<Map<String, dynamic>> redeemReward({
  required String userId,
  required String item,
}) async {
  return await _post("/civic/redeem/$userId", {"item": item});
}
// -------------------- ✅ Community Feed APIs --------------------
  /// Get all community posts (public civic reports)
  static Future<List<Map<String, dynamic>>> getCommunityFeed() async {
    try {
      final response = await _get("/civic/reports");
      final List<dynamic> data = response["data"] ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Error loading community feed: $e");
      throw ApiException("Failed to load community feed: $e");
    }
  }

  /// Post a new community message (optional — for future)
  static Future<Map<String, dynamic>> postCommunityUpdate({
    required String userId,
    required String description,
    String? imageBase64,
  }) async {
    final body = {
      "user_id": userId,
      "description": description,
      if (imageBase64 != null) "image_base64": imageBase64,
    };
    return await _post("/community/post", body);
  }

static Future<Map<String, dynamic>> runAgenticBrain({
  required String goal,
  String area = "Bengaluru",
}) async {
  try {
    final Uri url = Uri.parse("$baseUrl/agent/execute");
    debugPrint(" Running CityMind Agent for $area → Goal: $goal");

    final response = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true",
          },
          body: jsonEncode({
            "goal": goal,
            "area": area,
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      debugPrint(" Agent response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      debugPrint(" Agent failed: ${response.statusCode}");
      return {"success": false, "error": "Agent failed: ${response.statusCode}"};
    }
  } catch (e) {
    debugPrint(" Agent error: $e");
    return {"success": false, "error": e.toString()};
  }
}

  // -------------------- Health Check --------------------

  static Future<bool> healthCheck() async {
    try {
      final response = await _get('/');
      return response['message'] != null;
    } catch (e) {
      debugPrint("Health check failed: $e");
      return false;
    }
  }
}

//
// -------------------- Data Models --------------------
//

class AirQualityData {
  final int aqi;
  final String quality;
  final double pm25;
  final double pm10;
  final String location;
  final DateTime timestamp;

  AirQualityData({
    required this.aqi,
    required this.quality,
    required this.pm25,
    required this.pm10,
    required this.location,
    required this.timestamp,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    return AirQualityData(
      aqi: json['aqi'] ?? 0,
      quality: json['quality'] ?? 'Unknown',
      pm25: (json['pm25'] ?? 0).toDouble(),
      pm10: (json['pm10'] ?? 0).toDouble(),
      location: json['location'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get aqiLevel {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color get aqiColor {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }
}

class WaterQualityData {
  final bool safeForUse;
  final double phLevel;
  final int tds;
  final double turbidity;
  final String location;
  final DateTime timestamp;

  WaterQualityData({
    required this.safeForUse,
    required this.phLevel,
    required this.tds,
    required this.turbidity,
    required this.location,
    required this.timestamp,
  });

  factory WaterQualityData.fromJson(Map<String, dynamic> json) {
    return WaterQualityData(
      safeForUse: json['safe_for_use'] ?? false,
      phLevel: (json['ph_level'] ?? 7.0).toDouble(),
      tds: json['tds'] ?? 0,
      turbidity: (json['turbidity'] ?? 0).toDouble(),
      location: json['location'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get status => safeForUse ? 'Safe ✓' : 'Unsafe ✗';
  Color get statusColor => safeForUse ? Colors.green : Colors.red;
}

class FusedInsight {
  final String? title;
  final String? summary;
  final String? trafficData;
  final String? civicData;
  final String? insight;

  FusedInsight({
    this.title,
    this.summary,
    this.trafficData,
    this.civicData,
    this.insight,
  });

  factory FusedInsight.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FusedInsight(
      title: data['title'] ?? "AI Urban Insight",
      summary: data['summary'] ?? "No summary available",
      trafficData: data['traffic_data'] ?? data['trafficData'],
      civicData: data['civic_data'] ?? data['civicData'],
      insight: data['insight'] ??
          data['ai_insight'] ??
          "No AI insight generated yet.",
    );
  }
}

class SentimentPoint {
  final double latitude;
  final double longitude;
  final double sentimentScore;
  final String sentiment;
  final String color;
  final String zone;
  final DateTime timestamp;

  SentimentPoint({
    required this.latitude,
    required this.longitude,
    required this.sentimentScore,
    required this.sentiment,
    required this.color,
    required this.zone,
    required this.timestamp,
  });

  factory SentimentPoint.fromJson(Map<String, dynamic> json) {
    return SentimentPoint(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      sentimentScore: (json['sentiment_score'] ?? 0).toDouble(),
      sentiment: json['sentiment'] ?? 'Neutral',
      color: json['color'] ?? '#FFFFFF',
      zone: json['zone'] ?? 'Unknown',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}