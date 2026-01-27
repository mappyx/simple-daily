import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/data_provider.dart';
import '../models/note.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _openNotes = [];
  Note? _activeNote;
  static const double leftPanelWidth = 360;

  void _openNote(Note note) {
    setState(() {
      if (!_openNotes.any((n) => n.id == note.id)) {
        _openNotes.add(note);
      }
      _activeNote = note;
    });
    // Sync with global provider
    Provider.of<DataProvider>(context, listen: false).setCurrentNote(note.id);
  }

  void _closeNote(Note note) {
    setState(() {
      final index = _openNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _openNotes.removeAt(index);
        if (_activeNote?.id == note.id) {
          _activeNote = _openNotes.isNotEmpty ? _openNotes.last : null;
        }
      }
    });
    // Sync with global provider
    Provider.of<DataProvider>(context, listen: false).setCurrentNote(_activeNote?.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
          if (data.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Ensure provider is in sync with local state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final provider = Provider.of<DataProvider>(context, listen: false);
            if (provider.currentNoteId != _activeNote?.id) {
              provider.setCurrentNote(_activeNote?.id);
            }
          });

          return Column(
            children: [
              // HEADER BAR WITH TABS
              Container(
                height: 64,
                color: AppColors.surface,
                child: Row(
                  children: [
                    // Left side - Notes title
                    SizedBox(
                      width: leftPanelWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Notes',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                padding: EdgeInsets.zero,
                                onPressed: () => _showNoteDialog(context),
                                tooltip: 'New note',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Vertical divider
                    Container(
                      width: 1,
                      color: AppColors.divider,
                    ),
                    // Right side - Tabs
                    Expanded(
                      child: _openNotes.isEmpty
                          ? const SizedBox.shrink()
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _openNotes.map((note) {
                                  final isActive = _activeNote?.id == note.id;
                                  return _buildTab(note, isActive);
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              // Horizontal divider below header
              Container(
                height: 1,
                color: AppColors.divider,
              ),
              
              // CONTENT AREA
              Expanded(
                child: Row(
                  children: [
                    // Left Panel - Notes List
                    Container(
                      width: leftPanelWidth,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
                      ),
                      child: data.notes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.note_add_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No notes yet",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 500.ms),
                            )
                          : ListView.builder(
                              itemCount: data.notes.length,
                              itemBuilder: (context, index) {
                                final note = data.notes[index];
                                final isSelected = _activeNote?.id == note.id;
                                
                                return _buildNoteListItem(note, isSelected)
                                    .animate()
                                    .fadeIn(duration: 300.ms, delay: (30 * index).ms);
                              },
                            ),
                    ),
                    
                    // Right Panel - Note Content
                    Expanded(
                      child: _activeNote == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Select a note to view",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 500.ms),
                            )
                          : _buildNoteContent(_activeNote!),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(Note note, bool isActive) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isActive ? AppColors.background : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeNote = note;
            });
            Provider.of<DataProvider>(context, listen: false).setCurrentNote(note.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    note.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _closeNote(note),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteListItem(Note note, bool isSelected) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: () => _openNote(note),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(left: BorderSide(color: AppColors.primary, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content.isEmpty ? 'No content' : note.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(note.lastModified),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    color: AppColors.textSecondary,
                    onPressed: () => _showNoteDialog(context, note: note),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    color: AppColors.error,
                    onPressed: () => _deleteNote(context, note),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteContent(Note note) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: note.content.isEmpty
            ? Text(
                'No content',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            : MarkdownBody(
                data: note.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.7,
                  ),
                  textAlign: WrapAlignment.spaceBetween,
                  h1: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  h2: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  h3: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  em: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  code: TextStyle(
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  listBullet: TextStyle(color: AppColors.primary),
                  blockSpacing: 16,
                ),
              ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _deleteNote(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(), // No rounded corners
        title: const Text("Delete note?"),
        content: Text("Are you sure you want to delete \"${note.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteNote(note.id);
              Navigator.pop(ctx);
              _closeNote(note);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(), // No rounded corners
        title: Text(note == null ? 'New Note' : 'Edit Note'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          hintText: 'Content (Markdown Supported)',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                        maxLines: null,
                        expands: true,
                      ),
                    ),
                    const VerticalDivider(color: Colors.white24),
                    Expanded(
                      child: Container(
                         padding: const EdgeInsets.all(8),
                         color: Colors.black12,
                         child: ValueListenableBuilder(
                           valueListenable: contentController,
                           builder: (context, TextEditingValue val, child) {
                             return Markdown(
                               data: val.text.isEmpty ? "Preview" : val.text,
                               styleSheet: MarkdownStyleSheet(
                                 p: const TextStyle(color: AppColors.textPrimary),
                               ),
                             );
                           },
                         ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                 if (note == null) {
                  final newNote = Note.create(
                    title: titleController.text,
                    content: contentController.text,
                  );
                  Provider.of<DataProvider>(context, listen: false).addNote(newNote);
                  _openNote(newNote);
                } else {
                  note.title = titleController.text;
                  note.content = contentController.text;
                  note.lastModified = DateTime.now();
                  Provider.of<DataProvider>(context, listen: false).updateNote(note);
                  setState(() {}); // Refresh to show updated title in tab
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
