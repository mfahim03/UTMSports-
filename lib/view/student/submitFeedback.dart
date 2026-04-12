import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/feedback_model.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/feedback_viewmodel.dart';

class SubmitFeedbackPage extends StatefulWidget {
  final bool embedded;
  const SubmitFeedbackPage({super.key, this.embedded = false});

  @override
  State<SubmitFeedbackPage> createState() => _SubmitFeedbackPageState();
}

class _SubmitFeedbackPageState extends State<SubmitFeedbackPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackViewModel(),
      child: _SubmitFeedbackContent(embedded: widget.embedded),
    );
  }
}

class _SubmitFeedbackContent extends StatefulWidget {
  final bool embedded;
  const _SubmitFeedbackContent({required this.embedded});

  @override
  State<_SubmitFeedbackContent> createState() =>
      _SubmitFeedbackContentState();
}

class _SubmitFeedbackContentState
    extends State<_SubmitFeedbackContent> {
  static const _maroon = Color(0xFF800000);
  final _formKey = GlobalKey<FormState>();
  final _feedbackCtrl = TextEditingController();
  int _selectedCategory = 0;
  int _rating = 0;

  final _categories = ['Events', 'Facilities', 'App'];

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(FeedbackViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = context.read<AuthViewModel>().currentUser;

    final feedback = FeedbackModel(
      id: '',
      studentName: user?.name ?? 'Anonymous',
      studentEmail: user?.email ?? '',
      category: _categories[_selectedCategory],
      message: _feedbackCtrl.text.trim(),
      rating: _rating,
      submittedAt: DateTime.now(),
    );

    final ok = await vm.submit(feedback);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted. Thank you!'),
          backgroundColor: _maroon,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _feedbackCtrl.clear();
      setState(() {
        _rating = 0;
        _selectedCategory = 0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'Failed to submit feedback'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedbackViewModel>();

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_categories.length, (i) {
                final selected = _selectedCategory == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _maroon : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _maroon
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(_categories[i],
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.black87)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Rating',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < _rating
                        ? Colors.amber
                        : Colors.grey.shade300,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Your Feedback',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _feedbackCtrl,
              maxLines: 5,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Please enter your feedback'
                      : null,
              decoration: InputDecoration(
                hintText:
                    'Share your thoughts about the ${_categories[_selectedCategory].toLowerCase()}...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: _maroon, width: 1.8)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.busy ? null : () => _submit(vm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _maroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: vm.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Submit Feedback',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('Submit Feedback',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: body,
    );
  }
}