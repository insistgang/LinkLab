import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/real_database_provider.dart';
import '../../services/real_database_repository.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_stage.dart';

class RealVolunteerProfileScreen extends ConsumerStatefulWidget {
  const RealVolunteerProfileScreen({super.key});

  @override
  ConsumerState<RealVolunteerProfileScreen> createState() =>
      _RealVolunteerProfileScreenState();
}

class _RealVolunteerProfileScreenState
    extends ConsumerState<RealVolunteerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _radiusController = TextEditingController(text: '3000');

  bool _isAvailable = true;
  bool _isSaving = false;
  String? _errorText;
  RealVolunteerProfile? _savedProfile;

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
      _savedProfile = null;
    });

    try {
      final profile = await ref
          .read(realDatabaseRepositoryProvider)
          .upsertVolunteerProfile(
            serviceRadiusM: int.parse(_radiusController.text),
            isAvailable: _isAvailable,
          );
      ref.invalidate(realHomeSummaryProvider);
      if (!mounted) return;
      setState(() {
        _savedProfile = profile;
      });
      showDemoStageSnackBar(
        context,
        message: '已保存志願者資料',
        icon: Icons.volunteer_activism_rounded,
        accentColor: AppTheme.stageSuccess,
      );
    } on RealDatabaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = '保存失敗，請確認已執行 Phase-3 SQL 且當前賬號已登錄。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '真實志願者資料',
      subtitle: '只寫入 volunteer_profiles，不做真實匹配和推送',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            FutureBuilder<RealVolunteerProfile?>(
              future: ref
                  .read(realDatabaseRepositoryProvider)
                  .fetchMyVolunteerProfile(),
              builder: (context, snapshot) {
                final existing = snapshot.data;
                if (existing == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                  child: _ExistingVolunteerCard(profile: existing),
                );
              },
            ),
            DemoSurfaceCard(
              semanticLabel: '志願者資料表單',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DemoSectionTitle(
                    title: '服務狀態',
                    subtitle: '保存當前賬號自己的志願者資料，RLS 會限制其他用戶寫入。',
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  AccessibleTextField(
                    controller: _radiusController,
                    label: '服務半徑，單位米',
                    hint: '3000',
                    semanticLabel: '服務半徑輸入框，請輸入米數',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enabled: !_isSaving,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final radius = int.tryParse(value ?? '');
                      if (radius == null) return '請輸入服務半徑';
                      if (radius < 0 || radius > 100000) {
                        return '服務半徑需在 0 到 100000 米之間';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Semantics(
                    label: _isAvailable ? '當前可接單' : '當前不可接單',
                    toggled: _isAvailable,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const AccessibleText('可接單'),
                      subtitle: const AccessibleText('僅保存狀態，不觸發真實匹配'),
                      value: _isAvailable,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    AccessibleErrorText(_errorText!),
                  ],
                  if (_savedProfile != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    _SavedVolunteerCard(profile: _savedProfile!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomBar: AccessibleButton(
        label: '保存志願者資料',
        semanticLabel: '保存真實志願者資料',
        hint: '雙擊後使用當前登錄賬號寫入 volunteer_profiles 表',
        icon: Icons.volunteer_activism_rounded,
        isLoading: _isSaving,
        backgroundColor: AppTheme.stageAccent,
        foregroundColor: AppTheme.stageBackground,
        onPressed: _isSaving ? null : _save,
      ),
    );
  }
}

class _ExistingVolunteerCard extends StatelessWidget {
  const _ExistingVolunteerCard({required this.profile});

  final RealVolunteerProfile profile;

  @override
  Widget build(BuildContext context) {
    final status = profile.isAvailable ? '可接單' : '不可接單';
    return DemoSurfaceCard(
      semanticLabel: '已讀取當前志願者資料，狀態$status',
      child: AccessibleText(
        '已讀取當前資料：$status，服務半徑 ${profile.serviceRadiusM} 米',
        style: TextStyle(
          color: AppTheme.stageTextPrimary,
          fontSize: AppTheme.fontSizeSmall,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SavedVolunteerCard extends StatelessWidget {
  const _SavedVolunteerCard({required this.profile});

  final RealVolunteerProfile profile;

  @override
  Widget build(BuildContext context) {
    final status = profile.isAvailable ? '可接單' : '不可接單';
    return Semantics(
      liveRegion: true,
      label: '保存成功，當前$status',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppTheme.stageSuccess,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: AccessibleText(
              '已保存：$status\n服務半徑：${profile.serviceRadiusM} 米',
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeSmall,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
