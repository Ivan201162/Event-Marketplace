import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/localization_providers.dart';

/// Виджет для локализованного текста
class LocalizedText extends ConsumerWidget {
  final String textKey;
  final Map<String, dynamic>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallback;

  const LocalizedText(
    this.textKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String text;
    if (hasTranslation(textKey)) {
      text = translate(textKey, params: params);
    } else {
      text = fallback ?? textKey;
    }

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Виджет для локализованного текста с анимацией
class AnimatedLocalizedText extends ConsumerStatefulWidget {
  final String textKey;
  final Map<String, dynamic>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallback;
  final Duration duration;
  final Curve curve;

  const AnimatedLocalizedText(
    this.textKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallback,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  ConsumerState<AnimatedLocalizedText> createState() =>
      _AnimatedLocalizedTextState();
}

class _AnimatedLocalizedTextState extends ConsumerState<AnimatedLocalizedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String text;
    if (hasTranslation(widget.textKey)) {
      text = translate(widget.textKey, params: widget.params);
    } else {
      text = widget.fallback ?? widget.textKey;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _animation.value)),
            child: Text(
              text,
              style: widget.style,
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
            ),
          ),
        );
      },
    );
  }
}

/// Виджет для локализованной кнопки
class LocalizedButton extends ConsumerWidget {
  final String textKey;
  final Map<String, dynamic>? params;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final String? fallback;

  const LocalizedButton(
    this.textKey, {
    super.key,
    this.params,
    this.onPressed,
    this.style,
    this.icon,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String text;
    if (hasTranslation(textKey)) {
      text = translate(textKey, params: params);
    } else {
      text = fallback ?? textKey;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// Виджет для локализованного текстового поля
class LocalizedTextField extends ConsumerWidget {
  final String labelKey;
  final String? hintKey;
  final String? helperKey;
  final String? errorKey;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final String? fallbackLabel;
  final String? fallbackHint;
  final String? fallbackHelper;
  final String? fallbackError;

  const LocalizedTextField({
    super.key,
    required this.labelKey,
    this.hintKey,
    this.helperKey,
    this.errorKey,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.fallbackLabel,
    this.fallbackHint,
    this.fallbackHelper,
    this.fallbackError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String label;
    if (hasTranslation(labelKey)) {
      label = translate(labelKey);
    } else {
      label = fallbackLabel ?? labelKey;
    }

    String? hint;
    if (hintKey != null) {
      if (hasTranslation(hintKey!)) {
        hint = translate(hintKey!);
      } else {
        hint = fallbackHint ?? hintKey;
      }
    }

    String? helper;
    if (helperKey != null) {
      if (hasTranslation(helperKey!)) {
        helper = translate(helperKey!);
      } else {
        helper = fallbackHelper ?? helperKey;
      }
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Виджет для локализованного диалога
class LocalizedDialog extends ConsumerWidget {
  final String titleKey;
  final String? contentKey;
  final List<LocalizedDialogAction> actions;
  final String? fallbackTitle;
  final String? fallbackContent;

  const LocalizedDialog({
    super.key,
    required this.titleKey,
    this.contentKey,
    required this.actions,
    this.fallbackTitle,
    this.fallbackContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String title;
    if (hasTranslation(titleKey)) {
      title = translate(titleKey);
    } else {
      title = fallbackTitle ?? titleKey;
    }

    String? content;
    if (contentKey != null) {
      if (hasTranslation(contentKey!)) {
        content = translate(contentKey!);
      } else {
        content = fallbackContent ?? contentKey;
      }
    }

    return AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: actions.map((action) => action.build(ref)).toList(),
    );
  }
}

/// Действие для локализованного диалога
class LocalizedDialogAction {
  final String textKey;
  final VoidCallback? onPressed;
  final String? fallback;

  const LocalizedDialogAction({
    required this.textKey,
    this.onPressed,
    this.fallback,
  });

  Widget build(WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String text;
    if (hasTranslation(textKey)) {
      text = translate(textKey);
    } else {
      text = fallback ?? textKey;
    }

    return TextButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

/// Виджет для локализованного списка
class LocalizedListTile extends ConsumerWidget {
  final String titleKey;
  final String? subtitleKey;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Map<String, dynamic>? titleParams;
  final Map<String, dynamic>? subtitleParams;
  final String? fallbackTitle;
  final String? fallbackSubtitle;

  const LocalizedListTile({
    super.key,
    required this.titleKey,
    this.subtitleKey,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleParams,
    this.subtitleParams,
    this.fallbackTitle,
    this.fallbackSubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String title;
    if (hasTranslation(titleKey)) {
      title = translate(titleKey, params: titleParams);
    } else {
      title = fallbackTitle ?? titleKey;
    }

    String? subtitle;
    if (subtitleKey != null) {
      if (hasTranslation(subtitleKey!)) {
        subtitle = translate(subtitleKey!, params: subtitleParams);
      } else {
        subtitle = fallbackSubtitle ?? subtitleKey;
      }
    }

    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Виджет для локализованного AppBar
class LocalizedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String titleKey;
  final List<Widget>? actions;
  final Widget? leading;
  final Map<String, dynamic>? titleParams;
  final String? fallbackTitle;

  const LocalizedAppBar({
    super.key,
    required this.titleKey,
    this.actions,
    this.leading,
    this.titleParams,
    this.fallbackTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translate = ref.watch(translateProvider);
    final hasTranslation = ref.watch(hasTranslationProvider);

    String title;
    if (hasTranslation(titleKey)) {
      title = translate(titleKey, params: titleParams);
    } else {
      title = fallbackTitle ?? titleKey;
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
