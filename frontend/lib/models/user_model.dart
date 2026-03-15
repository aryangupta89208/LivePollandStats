class UserModel {
  final String id;
  final String deviceId;
  final String displayName;
  final String favoriteTeam;
  final int fanIq;
  final int totalVotes;
  final int correctPredictions;
  final double accuracy;

  UserModel({
    required this.id,
    required this.deviceId,
    required this.displayName,
    required this.favoriteTeam,
    this.fanIq = 0,
    this.totalVotes = 0,
    this.correctPredictions = 0,
    this.accuracy = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      deviceId: json['device_id'],
      displayName: json['display_name'] ?? 'Anonymous',
      favoriteTeam: json['favorite_team'],
      fanIq: json['fan_iq'] ?? 0,
      totalVotes: json['total_votes'] ?? 0,
      correctPredictions: json['correct_predictions'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
    );
  }

  String get teamShort {
    final map = {
      'Chennai Super Kings': 'CSK',
      'Mumbai Indians': 'MI',
      'Royal Challengers Bengaluru': 'RCB',
      'Kolkata Knight Riders': 'KKR',
      'Rajasthan Royals': 'RR',
      'Sunrisers Hyderabad': 'SRH',
      'Delhi Capitals': 'DC',
      'Punjab Kings': 'PBKS',
      'Gujarat Titans': 'GT',
      'Lucknow Super Giants': 'LSG',
    };
    return map[favoriteTeam] ?? favoriteTeam;
  }

  String get formattedFanIq {
    if (fanIq >= 1000) {
      return '${(fanIq / 1000).toStringAsFixed(1)}K';
    }
    return fanIq.toString();
  }
}

class LeaderboardEntry {
  final int rank;
  final String id;
  final String displayName;
  final String favoriteTeam;
  final int fanIq;
  final int totalVotes;
  final double accuracy;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.displayName,
    required this.favoriteTeam,
    this.fanIq = 0,
    this.totalVotes = 0,
    this.accuracy = 0.0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      id: json['id'],
      displayName: json['display_name'] ?? 'Anonymous',
      favoriteTeam: json['favorite_team'],
      fanIq: json['fan_iq'] ?? 0,
      totalVotes: json['total_votes'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
    );
  }

  String get teamShort {
    final map = {
      'Chennai Super Kings': 'CSK',
      'Mumbai Indians': 'MI',
      'Royal Challengers Bengaluru': 'RCB',
      'Kolkata Knight Riders': 'KKR',
      'Rajasthan Royals': 'RR',
      'Sunrisers Hyderabad': 'SRH',
      'Delhi Capitals': 'DC',
      'Punjab Kings': 'PBKS',
      'Gujarat Titans': 'GT',
      'Lucknow Super Giants': 'LSG',
    };
    return map[favoriteTeam] ?? favoriteTeam;
  }
}
