part of '../supporter_screen.dart';

String _eventLabel(String type) {
  return switch (type) {
    'FAVORITE_TEAM_ADDED' => 'Equipe favorite ajoutee',
    'FAVORITE_CLUB_ADDED' => 'Club favori ajoute',
    'FAVORITE_COMPETITION_ADDED' => 'Competition favorite ajoutee',
    'MATCH_VIEWED' => 'Fiche match consultee',
    'LIVE_MATCH_FOLLOWED' => 'Match live suivi',
    'FINISHED_MATCH_VIEWED' => 'Match termine consulte',
    'PROFILE_COMPLETED' => 'Profil complete',
    'DAILY_ACTIVE' => 'Jour actif',
    'TEAM_VIEWED' => 'Equipe visitee',
    'COMPETITION_VIEWED' => 'Championnat visite',
    'BADGE_UNLOCKED' => 'Badge debloque',
    _ => type,
  };
}

String _formatEventDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month - $hour:$minute';
}
