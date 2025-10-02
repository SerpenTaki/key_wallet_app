import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleziona un colore'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: (Color color) {
            setState(() => _currentColor = color);
          },
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
            child: const Text('OK'),
            onPressed: () {
              widget.onColorChanged(_currentColor);
              Navigator.of(context).pop();
            }),
      ],
    );
  }
}
