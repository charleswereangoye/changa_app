import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInput extends StatefulWidget {
  final void Function(String) onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool enabled;

  const PinInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _currentPin() => _controllers.map((c) => c.text).join();

  void _notifyPinChanged({bool checkCompletion = true}) {
    final pin = _currentPin();
    widget.onChanged?.call(pin);
    if (checkCompletion && pin.length == 6) {
      widget.onCompleted(pin);
    }
  }

  void _onChanged(String value, int index) {
    if (!widget.enabled) return;

    if (value.isEmpty) {
      _notifyPinChanged(checkCompletion: false);
      return;
    }

    if (value.length == 2) {
      _controllers[index].text = value.substring(1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _notifyPinChanged();
      return;
    }

    if (value.length > 2) {
      final pastedText = value.replaceAll(RegExp(r'[^0-9]'), '');
      _controllers[index].text = '';

      for (int i = 0; i < 6; i++) {
        _controllers[i].text = i < pastedText.length ? pastedText[i] : '';
      }

      if (pastedText.length >= 6) {
        _focusNodes[5].unfocus();
      } else {
        _focusNodes[pastedText.length].requestFocus();
      }
      _notifyPinChanged();
      return;
    }

    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    _notifyPinChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 288.0;
        final boxWidth = ((maxWidth - 30) / 6).clamp(28.0, 48.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: boxWidth,
              height: 52,
              child: Focus(
                onKeyEvent: (node, event) {
                  if (!widget.enabled) return KeyEventResult.ignored;
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace) {
                    if (_controllers[index].text.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                      _controllers[index - 1].clear();
                      _notifyPinChanged(checkCompletion: false);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: boxWidth < 38 ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: widget.hasError
                        ? colorScheme.error
                        : colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? colorScheme.error
                            : colorScheme.outline,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? colorScheme.error
                            : colorScheme.primary,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => _onChanged(value, index),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
