class PollModel {
  final String id;
  final String question;
  final String optionA;
  final String optionB;
  final String category;
  final bool active;
  final DateTime createdAt;
  int votesA;
  int votesB;
  int totalVotes;
  double percentageA;
  double percentageB;
  String? userVote;

  PollModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.category,
    required this.active,
    required this.createdAt,
    this.votesA = 0,
    this.votesB = 0,
    this.totalVotes = 0,
    this.percentageA = 0.0,
    this.percentageB = 0.0,
    this.userVote,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'],
      question: json['question'],
      optionA: json['option_a'] ?? 'Agree',
      optionB: json['option_b'] ?? 'Disagree',
      category: json['category'] ?? 'hot_take',
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      votesA: json['votes_a'] ?? 0,
      votesB: json['votes_b'] ?? 0,
      totalVotes: json['total_votes'] ?? 0,
      percentageA: (json['percentage_a'] ?? 0.0).toDouble(),
      percentageB: (json['percentage_b'] ?? 0.0).toDouble(),
      userVote: json['user_vote'],
    );
  }

  String get categoryEmoji {
    switch (category) {
      case 'goat':
        return '🐐';
      case 'team_battle':
        return '⚔️';
      case 'player_battle':
        return '👤';
      case 'prediction':
        return '🔮';
      case 'fun':
        return '🎉';
      default:
        return '🔥';
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'goat':
        return 'GOAT DEBATE';
      case 'team_battle':
        return 'TEAM BATTLE';
      case 'player_battle':
        return 'PLAYER BATTLE';
      case 'prediction':
        return 'PREDICTION';
      case 'fun':
        return 'FUN';
      default:
        return 'HOT TAKE';
    }
  }

  String get formattedVotes {
    if (totalVotes >= 1000000) {
      return '${(totalVotes / 1000000).toStringAsFixed(1)}M';
    } else if (totalVotes >= 1000) {
      return '${(totalVotes / 1000).toStringAsFixed(1)}K';
    }
    return totalVotes.toString();
  }

  void updateFromWs(Map<String, dynamic> data) {
    votesA = data['votes_a'] ?? votesA;
    votesB = data['votes_b'] ?? votesB;
    totalVotes = data['total_votes'] ?? totalVotes;
    percentageA = (data['percentage_a'] ?? percentageA).toDouble();
    percentageB = (data['percentage_b'] ?? percentageB).toDouble();
  }
}

class TeamBreakdown {
  final String team;
  final int votesA;
  final int votesB;
  final int total;
  final double percentageA;

  TeamBreakdown({
    required this.team,
    required this.votesA,
    required this.votesB,
    required this.total,
    required this.percentageA,
  });

  factory TeamBreakdown.fromJson(Map<String, dynamic> json) {
    return TeamBreakdown(
      team: json['team'],
      votesA: json['votes_a'] ?? 0,
      votesB: json['votes_b'] ?? 0,
      total: json['total'] ?? 0,
      percentageA: (json['percentage_a'] ?? 0.0).toDouble(),
    );
  }
}

class PollResult {
  final PollModel poll;
  final List<TeamBreakdown> teamBreakdown;

  PollResult({required this.poll, required this.teamBreakdown});

  factory PollResult.fromJson(Map<String, dynamic> json) {
    return PollResult(
      poll: PollModel.fromJson(json['poll']),
      teamBreakdown: (json['team_breakdown'] as List)
          .map((e) => TeamBreakdown.fromJson(e))
          .toList(),
    );
  }
}
