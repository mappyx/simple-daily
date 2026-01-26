import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/data_provider.dart';
import '../models/note.dart';
import '../utils/constants.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
          if (data.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.notes.isEmpty) {
            return Center(
              child: Text(
                "No notes yet. Create one!",
                style: TextStyle(color: AppColors.textSecondary),
              ).animate().fadeIn(duration: 500.ms),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: data.notes.length,
              itemBuilder: (context, index) {
                final note = data.notes[index];
                return _buildNoteCard(context, note)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    return GestureDetector(
      onTap: () => _showNoteDialog(context, note: note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: MarkdownBody(
                data: note.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  strong: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
                fitContent: false,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d').format(note.lastModified),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, {Note? note}) {
    // We'll use a StatefulWidget here for toggle preview mode in future if needed
    // For now, simple text fields, but we should hint it supports Markdown
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
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
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
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
          if (note != null)
             TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false).deleteNote(note.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
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
                } else {
                  note.title = titleController.text;
                  note.content = contentController.text;
                  note.lastModified = DateTime.now();
                  Provider.of<DataProvider>(context, listen: false).updateNote(note);
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
