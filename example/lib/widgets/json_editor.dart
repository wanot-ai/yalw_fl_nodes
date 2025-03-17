import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/json.dart';

class JsonEditorField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const JsonEditorField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<JsonEditorField> createState() => _JsonEditorFieldState();
}

class _JsonEditorFieldState extends State<JsonEditorField> {
  late CodeController _controller;
  late FocusNode _focusNode;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialValue,
      language: json,
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _lastSavedValue = widget.initialValue;
  }

  void _onFocusChange() {
    // When focus is lost, save the changes
    if (!_focusNode.hasFocus) {
      _saveChanges();
    }
  }

  void _saveChanges() {
    // Only call onChanged if the text actually changed
    if (_controller.text != _lastSavedValue) {
      _lastSavedValue = _controller.text;
      widget.onChanged(_controller.text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 300, // Fixed height container
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
                focusNode: _focusNode,
                textStyle:
                    const TextStyle(fontFamily: 'monospace', fontSize: 14),
                // Don't use expands: true here
                minLines: 10,
                maxLines: null, // Allow unlimited lines within the scroll view
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saveChanges,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
