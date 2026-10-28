import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInput extends StatefulWidget {
  final void Function(String) onCompleted;
  final bool hasError;

  const PinInput({super.key, required this.onCompleted, this.hasError = false});

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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isEmpty) return;

    // Handle Paste: Intercept strings > 1 char, sanitize, and distribute
    if (value.length > 1) {
      final pastedText = value.replaceAll(RegExp(r'[^0-9]'), '');

      for (int i = 0; i < 6; i++) {
        if (i < pastedText.length) {
          _controllers[i].text = pastedText[i];
        }
      }

      if (pastedText.length >= 6) {
        _focusNodes[5].unfocus();
        widget.onCompleted(
          _controllers.map((c) => c.text).join().substring(0, 6),
        );
      } else {
        _focusNodes[pastedText.length].requestFocus();
      }
      return;
    }

    // Handle normal typing auto-advance
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      final pin = _controllers.map((c) => c.text).join();
      if (pin.length == 6) {
        widget.onCompleted(pin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: Focus(
            // Catch backspace when the field is already empty to advance backward
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_controllers[index].text.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                  _controllers[index - 1].clear();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength:
                  6, // Unlocks paste capacity (counter text hidden below)
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.hasError
                    ? colorScheme.error
                    : colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.hasError
                        ? colorScheme.error
                        : colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.hasError
                        ? colorScheme.error
                        : colorScheme.primary,
                    width: 2,
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
  }
}
