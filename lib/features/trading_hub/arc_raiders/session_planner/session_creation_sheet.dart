import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/session_planner/session_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class SessionCreationSheet extends StatefulWidget {
  const SessionCreationSheet({super.key, required this.repository});

  final UagSessionRepository repository;

  static Future<void> show(
    BuildContext context,
    UagSessionRepository repository,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackgroundDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SessionCreationSheet(repository: repository),
    );
  }

  @override
  State<SessionCreationSheet> createState() => _SessionCreationSheetState();
}

class _SessionCreationSheetState extends State<SessionCreationSheet> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _embarkController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  String _type = 'trade';
  bool _saving = false;

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    _embarkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result != null && mounted) {
      setState(() => _date = result);
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);

    if (result != null && mounted) {
      setState(() => _time = result);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final otherUid = _uidController.text.trim();
    final otherName = _nameController.text.trim();

    if (otherUid.isEmpty || otherName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add the other player UID and display name.'),
        ),
      );
      return;
    }

    if (otherUid == widget.repository.currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot schedule a session with yourself.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final scheduledAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

      await widget.repository.createManualSession(
        type: _type,
        participantTwoUid: otherUid,
        participantTwoDisplayName: otherName,
        participantTwoEmbarkId: _embarkController.text.trim(),
        scheduledAt: scheduledAt,
        timezone: timezone,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create session: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spaceL,
          right: AppTheme.spaceL,
          top: AppTheme.spaceL,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              Text(
                'Schedule Session',
                style: AppTheme.tradingHeading(
                  fontSize: 24,
                  color: AppTheme.neonPink,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: AppTheme.tradingInputDecoration(label: 'Type'),
                dropdownColor: AppTheme.cardBackgroundAlt,
                items: const [
                  DropdownMenuItem(value: 'trade', child: Text('Trade')),
                  DropdownMenuItem(
                    value: 'matchmaking',
                    child: Text('Matchmaking'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _type = value ?? 'trade'),
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextField(
                controller: _uidController,
                enabled: !_saving,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.tradingInputDecoration(
                  label: 'Other player UID',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.tradingInputDecoration(
                  label: 'Other player display name',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextField(
                controller: _embarkController,
                enabled: !_saving,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.tradingInputDecoration(
                  label: 'Other player Embark ID',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text('${_date.day}/${_date.month}/${_date.year}'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(_time.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextField(
                controller: _notesController,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.tradingInputDecoration(label: 'Notes'),
              ),
              const SizedBox(height: AppTheme.spaceL),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving…' : 'Create Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
