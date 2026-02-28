import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import 'note_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      context.read<NotesProvider>().clearSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<NotesProvider>(
          builder: (context, notesProvider, _) {
            return RefreshIndicator(
              onRefresh: () => notesProvider.loadNotes(),
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),

                  // Pinned section
                  if (notesProvider.pinnedNotes.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'PINNED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.75),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildNoteCard(notesProvider.pinnedNotes[index], notesProvider),
                        childCount: notesProvider.pinnedNotes.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Divider(height: 1),
                    ),
                  ],

                  // Regular notes
                  if (notesProvider.notes.where((n) => !n.isPinned).isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notes = notesProvider.notes.where((n) => !n.isPinned).toList();
                          return _buildNoteCard(notes[index], notesProvider);
                        },
                        childCount: notesProvider.notes.where((n) => !n.isPinned).length,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteEditScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      titleSpacing: 0,
      title: _isSearching ? _buildSearchField() : const Text('Notes'),
      actions: _buildAppBarActions(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search notes...',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              _stopSearch();
            } else {
              _searchController.clear();
              context.read<NotesProvider>().searchNotes('');
            }
          },
        ),
      ),
      onChanged: (query) {
        context.read<NotesProvider>().searchNotes(query);
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch),
      ];
    } else {
      return [
        IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        const SizedBox(width: 6),
      ];
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.45),
            ),
            const SizedBox(height: 18),
            const Text(
              'No notes yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to create a new note. You can pin important notes so they stay on top.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, NotesProvider notesProvider) {
    // Provide a small colored indicator on the left and an avatar
    final avatarLetter = (note.title.isNotEmpty) ? note.title.trim()[0].toUpperCase() : '?';
    final leftColor = note.isPinned ? Theme.of(context).colorScheme.primary : Colors.transparent;

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Note'),
            content: const Text('Are you sure you want to delete this note?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('DELETE'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        final deleted = note;
        notesProvider.deleteNote(note.id);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Try to restore quickly. Provider should handle duplicates appropriately.
                await notesProvider.addNote(deleted);
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () => _navigateToNoteEditScreen(context, note: note),
        onLongPress: () => notesProvider.togglePinStatus(note),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              // color strip
              Container(width: 6, height: 86, decoration: BoxDecoration(color: leftColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
              Expanded(
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(child: Text(avatarLetter), radius: 22),
                  title: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(note.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                    color: note.isPinned ? Theme.of(context).colorScheme.primary : null,
                    onPressed: () => notesProvider.togglePinStatus(note),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToNoteEditScreen(BuildContext context, {Note? note}) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (context) => NoteEditScreen(note: note)),
    );

    if (result != null && context.mounted) {
      final notesProvider = context.read<NotesProvider>();
      if (note == null) {
        await notesProvider.addNote(result);
      } else {
        await notesProvider.updateNote(result);
      }
    }
  }
}
