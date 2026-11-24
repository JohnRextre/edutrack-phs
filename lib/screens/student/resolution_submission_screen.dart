import 'package:flutter/material.dart';

enum ResolutionType {
  penalty,
  repair,
  replacement;

  String get label => switch (this) {
    penalty => 'Penalty Payment Required',
    repair => 'Item Repair Required',
    replacement => 'Item Replacement Required',
  };

  String get title => switch (this) {
    penalty => 'Penalty Compliance Submission',
    repair => 'Repaired Item Resubmission',
    replacement => 'Replacement Item Resubmission',
  };

  String get message => switch (this) {
    penalty =>
      'Your return requires penalty compliance. Please upload your proof of payment below so the administrator can verify and close your transaction.',
    repair =>
      'The administrator requires the damaged resource to be repaired. Please upload proof of the repaired item for a follow-up inspection.',
    replacement =>
      'The administrator requires a replacement for the unserviceable or lost resource. Please upload photos of the replacement item for review.',
  };

  String get adminLabel =>
      this == penalty ? 'Admin Reason' : 'Admin Inspection Notes';
  String get adminNote => switch (this) {
    penalty =>
      'A penalty was issued because the calculator display was damaged during the borrowing period.',
    repair =>
      'The calculator display is cracked and must be professionally repaired before reinspection.',
    replacement =>
      'The calculator is unserviceable and requires an equivalent replacement item.',
  };

  String get uploadLabel => switch (this) {
    penalty => 'Upload Receipt / Official Receipt Image',
    repair => 'Upload Repaired Item Photo',
    replacement => 'Upload Replacement Item Photo',
  };

  String get remarksLabel => switch (this) {
    penalty => 'Borrower Remarks',
    repair => 'Repair Remarks',
    replacement => 'Replacement Remarks',
  };

  String get hint => switch (this) {
    penalty => 'Enter additional notes here...',
    repair => 'Describe the repairs made...',
    replacement => 'Provide details about the replacement item...',
  };

  String get submitLabel => switch (this) {
    penalty => 'Submit Payment Proof',
    repair => 'Resubmit Repaired Item',
    replacement => 'Resubmit Replacement Item',
  };

  String get resultingStatus => switch (this) {
    penalty => 'Pending Penalty Compliance',
    repair => 'Pending Repaired',
    replacement => 'Pending Replaced',
  };
}

class ResolutionSubmissionScreen extends StatefulWidget {
  const ResolutionSubmissionScreen({super.key, required this.resolution});
  final ResolutionType resolution;
  @override
  State<ResolutionSubmissionScreen> createState() =>
      _ResolutionSubmissionScreenState();
}

class _ResolutionSubmissionScreenState
    extends State<ResolutionSubmissionScreen> {
  final _remarksController = TextEditingController();
  bool _proofAttached = false;
  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    final type = widget.resolution;
    if (!_proofAttached ||
        (type != ResolutionType.penalty &&
            _remarksController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please attach the required proof and complete all required remarks.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(type.resultingStatus);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.resolution;
    return Scaffold(
      appBar: AppBar(title: Text(type.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(type.message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.adminLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(type.adminNote),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _proofAttached = true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _proofAttached
                        ? Icons.check_circle
                        : Icons.upload_file_outlined,
                    size: 38,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _proofAttached ? 'Proof Attached' : type.uploadLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tap to capture or select from gallery'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _remarksController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText:
                  '${type.remarksLabel}${type == ResolutionType.penalty ? ' (Optional)' : ''}',
              hintText: type.hint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: Text(type.submitLabel),
          ),
        ],
      ),
    );
  }
}
