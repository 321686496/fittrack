import 'package:flutter/material.dart';
import '../services/achievement_service.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final double size;
  const AchievementBadge({
    required this.achievement,
    this.size = 80,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return Opacity(
      opacity: unlocked ? 1.0 : 0.3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
            child: Icon(
              unlocked ? Icons.emoji_events : Icons.lock_outline,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(achievement.title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(achievement.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
