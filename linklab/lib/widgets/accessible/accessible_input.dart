import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../demo/linkable_icon.dart';
import 'accessible_text.dart';

/// 無障礙文本輸入框
/// 支持語音播報和完整的語義標籤
class AccessibleTextField extends StatelessWidget {
  const AccessibleTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.semanticLabel,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final String? semanticLabel;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    // 構建語義標籤
    final effectiveSemanticLabel =
        semanticLabel ??
        '${label ?? '文本輸入框'}，${hint ?? ''}'
            '${keyboardType == TextInputType.phone ? '，請輸入數字' : ''}';

    return Semantics(
      label: effectiveSemanticLabel,
      textField: true,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            AccessibleLabel(label!, required: validator != null),
            const SizedBox(height: AppTheme.spacingS),
          ],
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              errorText: errorText,
              prefixIcon: prefixIcon != null
                  ? SizedBox(
                      width: AppTheme.minTouchTarget,
                      height: AppTheme.minTouchTarget,
                      child: Center(child: prefixIcon),
                    )
                  : null,
              suffixIcon: suffixIcon != null
                  ? SizedBox(
                      width: AppTheme.minTouchTarget,
                      height: AppTheme.minTouchTarget,
                      child: Center(child: suffixIcon),
                    )
                  : null,
              counterText: maxLength != null ? '' : null,
            ),
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            enabled: enabled,
            readOnly: readOnly,
            autofocus: autofocus,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            onTap: onTap,
            validator: validator,
            autovalidateMode: autovalidateMode,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: AppTheme.fontSizeNormal),
          ),
        ],
      ),
    );
  }
}

/// 無障礙手機號輸入框
class AccessiblePhoneField extends StatelessWidget {
  const AccessiblePhoneField({
    super.key,
    this.controller,
    this.label = '手機號',
    this.hint = '請輸入11位手機號',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController? controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return AccessibleTextField(
      controller: controller,
      label: label,
      hint: hint,
      semanticLabel: '$label，$hint，請逐位輸入數字',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: const LinkableSvgIcon(
        icon: LinkableIconName.voiceCall,
        size: 28,
        semanticLabel: '手機號',
      ),
      maxLength: 11,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '請輸入手機號';
            }
            if (value.length != 11 ||
                !RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
              return '請輸入正確的11位手機號';
            }
            return null;
          },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
    );
  }
}

/// 無障礙驗證碼輸入框
class AccessibleCodeField extends StatelessWidget {
  const AccessibleCodeField({
    super.key,
    this.controller,
    this.label = '驗證碼',
    this.hint = '請輸入6位驗證碼',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.onSendCode,
    this.countdownSeconds = 60,
  });

  final TextEditingController? controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onSendCode;
  final int countdownSeconds;

  @override
  Widget build(BuildContext context) {
    return AccessibleTextField(
      controller: controller,
      label: label,
      hint: hint,
      semanticLabel: '$label，$hint，請逐位輸入數字',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 6,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請輸入驗證碼';
        }
        if (value.length != 6) {
          return '驗證碼爲6位數字';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      suffixIcon: onSendCode != null
          ? _CountdownButton(
              onPressed: onSendCode!,
              countdownSeconds: countdownSeconds,
            )
          : null,
    );
  }
}

/// 倒計時按鈕
class _CountdownButton extends StatefulWidget {
  const _CountdownButton({
    required this.onPressed,
    required this.countdownSeconds,
  });

  final VoidCallback onPressed;
  final int countdownSeconds;

  @override
  State<_CountdownButton> createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<_CountdownButton> {
  int _remainingSeconds = 0;
  bool _isCounting = false;

  void _startCountdown() {
    setState(() {
      _remainingSeconds = widget.countdownSeconds;
      _isCounting = true;
    });

    widget.onPressed();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          _isCounting = false;
        }
      }
      return _isCounting && mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isCounting ? null : _startCountdown,
      child: AccessibleText(
        _isCounting ? '$_remainingSeconds秒後重發' : '獲取驗證碼',
        style: TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: _isCounting ? AppTheme.textHint : AppTheme.primaryColor,
        ),
      ),
    );
  }
}

/// 無障礙單選按鈕組
class AccessibleRadioGroup<T> extends StatelessWidget {
  const AccessibleRadioGroup({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final String title;
  final List<AccessibleRadioOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.spacingS),
          RadioGroup<T>(
            groupValue: value,
            onChanged: onChanged,
            child: Column(
              children: options.map((option) {
                return Semantics(
                  label: option.label,
                  selected: value == option.value,
                  child: RadioListTile<T>(
                    title: AccessibleText(option.label),
                    subtitle: option.description != null
                        ? AccessibleText(
                            option.description!,
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppTheme.textHint,
                            ),
                          )
                        : null,
                    value: option.value,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 單選選項
class AccessibleRadioOption<T> {
  final T value;
  final String label;
  final String? description;

  const AccessibleRadioOption({
    required this.value,
    required this.label,
    this.description,
  });
}

/// 無障礙複選框組
class AccessibleCheckboxGroup extends StatelessWidget {
  const AccessibleCheckboxGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  final String title;
  final List<AccessibleCheckboxOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccessibleText(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option.value);
            return FilterChip(
              label: AccessibleText(option.label),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<String>.from(selectedValues);
                if (selected) {
                  newValues.add(option.value);
                } else {
                  newValues.remove(option.value);
                }
                onChanged(newValues);
              },
              selectedColor: AppTheme.primaryLight,
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 複選框選項
class AccessibleCheckboxOption {
  final String value;
  final String label;

  const AccessibleCheckboxOption({required this.value, required this.label});
}

/// AccessibleInput 別名
/// 爲了兼容性，AccessibleInput 是 AccessibleTextField 的別名
typedef AccessibleInput = AccessibleTextField;
