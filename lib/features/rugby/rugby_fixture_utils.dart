import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';

const _finalStatusCodes = {
  'FT',
  'AET',
  'CANC',
  'PST',
  'POST',
  'ABD',
  'AWD',
  'WO',
};
const _liveStatusCodes = {
  'LIVE',
  '1H',
  'HT',
  '2H',
  'ET',
  'BT',
  'P',
  'INT',
  'INTR',
};
const _liveStatusLabels = [
  'live',
  'in play',
  'in progress',
  'first half',
  'half time',
  'halftime',
  'second half',
  'extra time',
  'break time',
  'interrupted',
  'pause',
];

class RugbyFixtureStatusInfo {
  const RugbyFixtureStatusInfo({
    required this.label,
    required this.color,
    required this.textColor,
    required this.background,
    required this.border,
    this.isLive = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final Color background;
  final Color border;
  final bool isLive;
}

String formatRugbyScore(RugbyFixtureScore score) {
  if (score.home == null || score.away == null) {
    return 'vs';
  }

  return '${score.home} - ${score.away}';
}

String formatRugbyKickoff(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date a venir';
  }

  final kickoff = DateTime.tryParse(value);
  if (kickoff == null) {
    return 'Date a venir';
  }

  final local = kickoff.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month - $hour:$minute';
}

int? rugbyFixtureKickoffTime(RugbyFixture fixture) {
  if (fixture.timestamp != null) {
    return fixture.timestamp! * 1000;
  }

  final kickoff = fixture.date == null
      ? null
      : DateTime.tryParse(fixture.date!);
  return kickoff?.millisecondsSinceEpoch;
}

RugbyFixtureStatusInfo rugbyFixtureStatus(RugbyFixture fixture) {
  if (_isFinalFixture(fixture)) {
    return const RugbyFixtureStatusInfo(
      label: 'Termine',
      color: Color(0xFF22C55E),
      textColor: Color(0xFFC7F7DC),
      background: Color(0x1F3FB984),
      border: Color(0x663FB984),
    );
  }

  if (_isLiveFixture(fixture) || _isLiveFixtureWindow(fixture)) {
    return const RugbyFixtureStatusInfo(
      label: 'Live',
      color: AppColors.live,
      textColor: Color(0xFFFECACA),
      background: Color(0x2EE63946),
      border: Color(0x66FF4655),
      isLive: true,
    );
  }

  if (fixture.score.home != null && fixture.score.away != null) {
    return const RugbyFixtureStatusInfo(
      label: 'Termine',
      color: Color(0xFF22C55E),
      textColor: Color(0xFFC7F7DC),
      background: Color(0x1F3FB984),
      border: Color(0x663FB984),
    );
  }

  return const RugbyFixtureStatusInfo(
    label: 'A venir',
    color: Color(0xFFFBBF24),
    textColor: Color(0xFFFDE68A),
    background: Color(0x24FBBF24),
    border: Color(0x66FBBF24),
  );
}

bool _isFinalFixture(RugbyFixture fixture) {
  final shortStatus = fixture.status.short?.toUpperCase();
  final longStatus = fixture.status.long?.toLowerCase();

  return (shortStatus != null && _finalStatusCodes.contains(shortStatus)) ||
      (longStatus?.contains('finished') ?? false) ||
      (longStatus?.contains('cancelled') ?? false) ||
      (longStatus?.contains('postponed') ?? false) ||
      (longStatus?.contains('abandoned') ?? false);
}

bool _isLiveFixture(RugbyFixture fixture) {
  final shortStatus = fixture.status.short?.toUpperCase();
  final longStatus = fixture.status.long?.toLowerCase();

  if (shortStatus != null && _liveStatusCodes.contains(shortStatus)) {
    return true;
  }

  if (fixture.status.elapsed != null) {
    return true;
  }

  return _liveStatusLabels.any((label) => longStatus?.contains(label) ?? false);
}

bool _isLiveFixtureWindow(RugbyFixture fixture) {
  final kickoff = fixture.date == null
      ? null
      : DateTime.tryParse(fixture.date!);
  final localKickoff = kickoff?.toLocal();
  final now = DateTime.now();
  final isLiveWindow =
      localKickoff != null &&
      now.isAfter(localKickoff.subtract(const Duration(minutes: 2))) &&
      now.isBefore(localKickoff.add(const Duration(hours: 3, minutes: 30)));
  return isLiveWindow;
}
