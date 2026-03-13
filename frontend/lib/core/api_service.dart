import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poll_model.dart';
import '../models/user_model.dart';

class ApiService {
  // Change this to your Railway URL after deployment
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // Web/iOS

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // ── Auth ──

  static Future<UserModel> signup(String deviceId, String team) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: _headers,
      body: jsonEncode({'device_id': deviceId, 'favorite_team': team}),
    );
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Signup failed: ${res.body}');
  }

  static Future<UserModel> getUser(String deviceId) async {
    final res = await http.get(Uri.parse('$baseUrl/user/$deviceId'));
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('User not found');
  }

  // ── Polls ──

  static Future<List<PollModel>> getPolls({String? userId}) async {
    String url = '$baseUrl/polls';
    if (userId != null) url += '?user_id=$userId';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => PollModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load polls');
  }

  static Future<PollResult> getPollResults(String pollId, {String? userId}) async {
    String url = '$baseUrl/poll/$pollId/results';
    if (userId != null) url += '?user_id=$userId';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      return PollResult.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load results');
  }

  // ── Votes ──

  static Future<PollModel?> vote(String userId, String pollId, String vote) async {
    final res = await http.post(
      Uri.parse('$baseUrl/vote'),
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'poll_id': pollId,
        'vote': vote,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['poll'] != null) {
        return PollModel.fromJson(data['poll']);
      }
      return null;
    } else if (res.statusCode == 409) {
      throw Exception('Already voted');
    }
    throw Exception('Vote failed: ${res.body}');
  }

  // ── Leaderboard ──

  static Future<List<LeaderboardEntry>> getLeaderboard(String period) async {
    final res = await http.get(Uri.parse('$baseUrl/leaderboard?period=$period'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['entries'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load leaderboard');
  }

  // ── Local Storage ──

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
  }

  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id');
  }

  static Future<void> saveTeam(String team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_team', team);
  }

  static Future<String?> getTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('favorite_team');
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }
}
