import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/alert_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.onInspect,
    required this.onOpenEducation,
  });

  final VoidCallback onInspect;
  final VoidCallback onOpenEducation;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<AlertItem> _alerts = AlertData.initial();
  AlertSeverity? _filter; // null means "All Alerts"
  bool _snoozed = false;

  @override
  void initState() {
    super.initState();
    _loadReviewed();
  }

  Future<void> _loadReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    final reviewed = prefs.getStringList('reviewed_alerts') ?? const [];
    if (reviewed.isEmpty || !mounted) return;
    setState(() {
      for (final a in _alerts) {
        if (reviewed.contains(a.title)) a.actionRequired = false;
      }
    });
  }

  Future<void> _saveReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'reviewed_alerts',
      _alerts.where((a) => !a.actionRequired).map((a) => a.title).toList(),
    );
  }

  int _count(AlertSeverity s) => _alerts.where((a) => a.severity == s).length;

  bool get _showBanner =>
      !_snoozed &&
      _alerts.any(
        (a) => a.severity == AlertSeverity.critical && a.actionRequired,
      );

  void _markReviewed() {
    setState(() {
      for (final a in _alerts) {
        a.actionRequired = false;
      }
    });
    _saveReviewed();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All alerts marked as reviewed')),
    );
  }

  void _snooze() {
    setState(() => _snoozed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert snoozed for 5 minutes')),
    );
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) setState(() => _snoozed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter == null
        ? _alerts
        : _alerts.where((a) => a.severity == _filter).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Alerts'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alerts & Incidents',
                    style: AppTheme.heading(size: 26),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _markReviewed,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text(
                    'Mark reviewed',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time thermal sensing & sensor telemetry status',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All Alerts', null),
                  _chip(
                    'Critical',
                    AlertSeverity.critical,
                    count: _count(AlertSeverity.critical),
                    badge: AppColors.critical,
                  ),
                  _chip(
                    'Warnings',
                    AlertSeverity.warning,
                    count: _count(AlertSeverity.warning),
                    badge: AppColors.primary,
                  ),
                  _chip('System', AlertSeverity.system),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_showBanner) ...[_criticalBanner(), const SizedBox(height: 16)],
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No alerts in this category',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              for (final a in visible) _alertTile(a),
            const SizedBox(height: 8),
            _monitorCard(),
            const SizedBox(height: 14),
            _safetyCard(),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, AlertSeverity? sev, {int? count, Color? badge}) {
    final selected = _filter == sev;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = sev),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Colors.white : badge,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _criticalBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.criticalSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.critical,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '14 mins ago',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Elevated Smoke & Heat Warning',
            style: AppTheme.heading(size: 20, color: AppColors.critical),
          ),
          const SizedBox(height: 4),
          const Text(
            'Zone 1: Kitchen Primary Cooktop Hub',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onInspect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.critical,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text(
                    'Inspect Readings',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _snooze,
                icon: const Icon(Icons.alarm, size: 16),
                label: const Text('Snooze 5m', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alertTile(AlertItem a) {
    final dotColor = switch (a.severity) {
      AlertSeverity.critical => AppColors.critical,
      AlertSeverity.warning => AppColors.primary,
      AlertSeverity.system => AppColors.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(a.icon, size: 18, color: dotColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      a.time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  a.message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (a.actionRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.criticalSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '! ACTION REQUIRED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.critical,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a.tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (a.severity == AlertSeverity.critical)
                      GestureDetector(
                        onTap: widget.onInspect,
                        child: Text(
                          '${a.trailing} >',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Text(
                        a.trailing,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEBD9C4), Color(0xFFB98B66)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KITCHEN MONITOR STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Zone 1 Optical Chamber',
                  style: AppTheme.heading(size: 17),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Visual telemetry confirmed clear exhaust…',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.blur_on, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _safetyCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.onOpenEducation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smoke detected? Immediate evacuation & grease fire '
                    'containment steps',
                    style: AppTheme.heading(size: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Never use water on cooktop flare-ups. View guided '
                    '30-second action drill →',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
