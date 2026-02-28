import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/gemini_text_analyzer.dart';
import '../main.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({super.key, this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _isPinned;
  String? _category;
  String? _aiSummary;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isPinned = widget.note?.isPinned ?? false;
    _category = widget.note?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      actions: [
        IconButton(
          tooltip: 'Summarize with AI',
          icon: _isAnalyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          onPressed: _isAnalyzing ? null : _summarizeWithAi,
        ),
        IconButton(
          icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: _togglePinStatus,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveNote,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            maxLines: null,
          ),
          const SizedBox(height: 8),
          _buildCategoryChips(),
          const Divider(),
          const SizedBox(height: 8),
          if (_aiSummary != null && _aiSummary!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'AI Summary',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _aiSummary = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _aiSummary!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Start writing...',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 18),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['Personal', 'Work', 'Ideas', 'To-Do', 'Important'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _category == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _category = selected ? category : null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _togglePinStatus() {
    setState(() {
      _isPinned = !_isPinned;
    });
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save changes?'),
          content: const Text('Do you want to save your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('DISCARD'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('SAVE'),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveNote();
      }
      return shouldSave ?? false;
    }
    return true;
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final note = Note(
      id: widget.note?.id,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      category: _category,
      isPinned: _isPinned,
      updatedAt: DateTime.now(),
      createdAt: widget.note?.createdAt,
    );

    if (mounted) {
      Navigator.pop(context, note);
    }
  }

  Future<void> _summarizeWithAi() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something in the note before using AI.')),
      );
      return;
    }

    if (geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key is not configured.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analyzer = GeminiTextAnalyzer(geminiApiKey);
      final summary = await analyzer.summarizeNote(content);
      if (!mounted) return;
      setState(() {
        _aiSummary = summary.isEmpty ? 'No summary generated.' : summary;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('AI summary error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get AI summary: ${e.toString()}'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
}
