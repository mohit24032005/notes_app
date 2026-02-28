import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = false;
  String? _searchQuery;

  List<Note> get notes => _filteredNotes;
  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();
  bool get isLoading => _isLoading;
  String? get searchQuery => _searchQuery;

  // Load all notes from the database
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await DatabaseHelper.instance.readAllNotes();
      _filterNotes();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new note
  Future<void> addNote(Note note) async {
    try {
      final newNote = await DatabaseHelper.instance.create(note);
      _notes.insert(0, newNote);
      _filterNotes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding note: $e');
      rethrow;
    }
  }

  // Update an existing note
  Future<void> updateNote(Note updatedNote) async {
    try {
      await DatabaseHelper.instance.update(updatedNote);
      final index = _notes.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        _filterNotes();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  // Delete a note
  Future<void> deleteNote(String id) async {
    try {
      await DatabaseHelper.instance.delete(id);
      _notes.removeWhere((note) => note.id == id);
      _filterNotes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  // Toggle pin status of a note
  Future<void> togglePinStatus(Note note) async {
    try {
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await updateNote(updatedNote);
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      rethrow;
    }
  }

  // Search notes by query
  void searchNotes(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _filterNotes();
  }

  // Filter notes based on search query
  void _filterNotes() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      _filteredNotes = List.from(_notes);
    } else {
      final query = _searchQuery!.toLowerCase();
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
      }).toList();
    }
    // Sort notes by pinned status and then by updated time
    _filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  // Clear search
  void clearSearch() {
    _searchQuery = null;
    _filterNotes();
    notifyListeners();
  }
}
