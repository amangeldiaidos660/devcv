import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/error_message.dart';
import '../../../core/widgets/form_page.dart';
import '../domain/developer_profile.dart';
import 'profile_providers.dart';
import 'unsaved_profile_dialog.dart';

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, required this.profile, required this.email});
  final DeveloperProfile? profile;
  final String email;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _dateText = TextEditingController();
  DateTime? _birthDate;
  String _originalName = '';
  String _originalCity = '';
  DateTime? _originalDate;

  @override
  void initState() {
    super.initState();
    _applyProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!ref.read(profileDirtyProvider)) _applyProfile();
  }

  String _formatDate(DateTime? date) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  void _applyProfile() {
    _originalName = widget.profile?.fullName ?? '';
    _originalCity = widget.profile?.city ?? '';
    _originalDate = widget.profile?.birthDate;
    _name.text = _originalName;
    _city.text = _originalCity;
    _birthDate = _originalDate;
    _dateText.text = _formatDate(_birthDate);
  }

  void _updateDirty() => ref
      .read(profileDirtyProvider.notifier)
      .setDirty(
        _name.text.trim() != _originalName.trim() ||
            _city.text.trim() != _originalCity.trim() ||
            _birthDate != _originalDate,
      );

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = DateTime(1900);
    final current =
        _birthDate ?? DateTime(today.year - 18, today.month, today.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first)
          ? first
          : current.isAfter(today)
          ? today
          : current,
      firstDate: first,
      lastDate: today,
      helpText: 'Дата рождения',
    );
    if (!mounted || selected == null) return;
    setState(() {
      _birthDate = selected;
      _dateText.text = _formatDate(selected);
    });
    _updateDirty();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final saved = await ref
        .read(profileActionsProvider.notifier)
        .save(fullName: _name.text, birthDate: _birthDate, city: _city.text);
    if (!mounted || !saved) return;
    _originalName = _name.text.trim();
    _originalCity = _city.text.trim();
    _originalDate = _birthDate;
    ref.read(profileDirtyProvider.notifier).setDirty(false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _dateText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(profileActionsProvider);
    final dirty = ref.watch(profileDirtyProvider);
    final busy = action.isLoading;
    final error = action.asError?.error;
    return PopScope(
      canPop: !dirty && !busy,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || busy) return;
        if (await confirmLeaveProfile(context) && context.mounted) {
          context.goNamed(RouteNames.home);
        }
      },
      child: FormPage(
        title: 'Профиль',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 36,
                  child: Icon(Icons.person_outline, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                child: SelectableText(widget.email),
              ),
              const SizedBox(height: 8),
              const Text('Email берётся из аккаунта и здесь не изменяется'),
              if (widget.profile == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Профиль ещё не создан. Заполните обязательные поля и сохраните.',
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                enabled: !busy,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.fullName,
                onChanged: (_) => _updateDirty(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateText,
                enabled: !busy,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Дата рождения',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: (_) => Validators.birthDate(_birthDate),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _city,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Город проживания',
                  border: OutlineInputBorder(),
                ),
                validator: Validators.city,
                onChanged: (_) => _updateDirty(),
              ),
              if (error != null) ErrorMessage(error: error),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : _save,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
