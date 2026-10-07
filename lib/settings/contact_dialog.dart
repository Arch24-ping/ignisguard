import 'package:flutter/material.dart';
import '../data/settings_store.dart';

class ContactDialog extends StatefulWidget {
  const ContactDialog({super.key, this.initial});
  final Contact? initial;

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  late final TextEditingController _name;
  late final TextEditingController _relation;
  late final TextEditingController _phone;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _relation = TextEditingController(text: widget.initial?.relation ?? '');
    _phone = TextEditingController(text: widget.initial?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _submitted = true);
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      Contact(
        name: _name.text.trim(),
        relation: _relation.text.trim().isEmpty
            ? 'Contact'
            : _relation.text.trim(),
        phone: _phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Add Emergency Contact' : 'Edit Contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full name',
                errorText: _submitted && _name.text.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _relation,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Relationship (e.g. Spouse)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '+263 700 000 000',
                errorText: _submitted && _phone.text.trim().isEmpty
                    ? 'Enter a phone number'
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}