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
  final _titleController = TextEditingController(text: '出行协助');
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
        message: '已创建真实求助记录',
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
        _errorText = '创建失败，请确认已执行 Phase-3 SQL 且当前账号已登录。';
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
      title: '真实求助记录',
      subtitle: '只写入 help_requests，不触发 AI、匹配、地图、WebRTC 或 SOS',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            DemoSurfaceCard(
              semanticLabel: '真实数据库说明',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DemoSectionTitle(
                    title: '最小 CRUD',
                    subtitle: '这一步只保存当前登录用户自己的求助记录，状态固定为 created。',
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  AccessibleTextField(
                    controller: _titleController,
                    label: '求助标题',
                    hint: '例如：出行协助',
                    semanticLabel: '求助标题输入框，请输入本次求助的简短标题',
                    textInputAction: TextInputAction.next,
                    enabled: !_isSaving,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入求助标题';
                      }
                      if (value.trim().length > 80) {
                        return '标题请控制在 80 字以内';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  AccessibleTextField(
                    controller: _descriptionController,
                    label: '补充说明',
                    hint: '例如：需要有人帮我确认路线和入口',
                    semanticLabel: '补充说明输入框，请描述你需要什么帮助',
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 5,
                    enabled: !_isSaving,
                    validator: (value) {
                      if ((value ?? '').trim().length > 500) {
                        return '补充说明请控制在 500 字以内';
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
        label: '创建求助记录',
        semanticLabel: '创建真实求助记录',
        hint: '双击后使用当前登录账号写入 help_requests 表',
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
      label: '创建成功，求助状态 ${request.status}',
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
              '已创建：${request.title}\n状态：${request.status}',
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
