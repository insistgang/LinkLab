import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/real_database_provider.dart';
import '../../services/real_database_repository.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_stage.dart';

class RealHelpRequestScreen extends ConsumerStatefulWidget {
  const RealHelpRequestScreen({super.key});

  @override
  ConsumerState<RealHelpRequestScreen> createState() =>
      _RealHelpRequestScreenState();
}

class _RealHelpRequestScreenState extends ConsumerState<RealHelpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: '出行協助');
  final _descriptionController = TextEditingController();

  bool _isSaving = false;
  String? _errorText;
  RealHelpRequest? _createdRequest;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
      _createdRequest = null;
    });

    try {
      final request = await ref
          .read(realDatabaseRepositoryProvider)
          .createHelpRequest(
            title: _titleController.text,
            description: _descriptionController.text,
          );
      ref.invalidate(realHomeSummaryProvider);
      if (!mounted) return;
      setState(() {
        _createdRequest = request;
      });
      showDemoStageSnackBar(
        context,
        message: '已創建真實求助記錄',
        icon: Icons.check_circle_outline_rounded,
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
        _errorText = '創建失敗，請確認已執行 Phase-3 SQL 且當前賬號已登錄。';
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
      title: '真實求助記錄',
      subtitle: '只寫入 help_requests，不觸發 AI、匹配、地圖、WebRTC 或 SOS',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            DemoSurfaceCard(
              semanticLabel: '真實數據庫說明',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DemoSectionTitle(
                    title: '最小 CRUD',
                    subtitle: '這一步只保存當前登錄用戶自己的求助記錄，狀態固定爲 created。',
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  AccessibleTextField(
                    controller: _titleController,
                    label: '求助標題',
                    hint: '例如：出行協助',
                    semanticLabel: '求助標題輸入框，請輸入本次求助的簡短標題',
                    textInputAction: TextInputAction.next,
                    enabled: !_isSaving,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '請輸入求助標題';
                      }
                      if (value.trim().length > 80) {
                        return '標題請控制在 80 字以內';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  AccessibleTextField(
                    controller: _descriptionController,
                    label: '補充說明',
                    hint: '例如：需要有人幫我確認路線和入口',
                    semanticLabel: '補充說明輸入框，請描述你需要什麼幫助',
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 5,
                    enabled: !_isSaving,
                    validator: (value) {
                      if ((value ?? '').trim().length > 500) {
                        return '補充說明請控制在 500 字以內';
                      }
                      return null;
                    },
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    AccessibleErrorText(_errorText!),
                  ],
                  if (_createdRequest != null) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    _CreatedRequestCard(request: _createdRequest!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomBar: AccessibleButton(
        label: '創建求助記錄',
        semanticLabel: '創建真實求助記錄',
        hint: '雙擊後使用當前登錄賬號寫入 help_requests 表',
        icon: Icons.add_task_rounded,
        isLoading: _isSaving,
        backgroundColor: AppTheme.stageAccent,
        foregroundColor: AppTheme.stageBackground,
        onPressed: _isSaving ? null : _submit,
      ),
    );
  }
}

class _CreatedRequestCard extends StatelessWidget {
  const _CreatedRequestCard({required this.request});

  final RealHelpRequest request;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '創建成功，求助狀態 ${request.status}',
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
              '已創建：${request.title}\n狀態：${request.status}',
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
