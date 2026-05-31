import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../themes/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final TextEditingController _checklistInputController = TextEditingController();

  late FocusNode _titleFocusNode;

  List<ChecklistItem> _checklistItems = [];
  int _colorValue = 0xFFFFFFFF;
  String? _folderId;

  List<NoteBlock> _blocks = [];
  final Map<String, TextEditingController> _blockControllers = {};
  final Map<String, FocusNode> _blockFocusNodes = {};

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final note = ref.watch(notesProvider).firstWhere(
            (n) => n.id == widget.noteId,
            orElse: () => Note(
              id: widget.noteId,
              title: '',
              content: '',
              isPinned: false,
              isFavorite: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              colorValue: 0xFFFFFFFF,
              checklist: [],
            ),
          );

      _titleController = TextEditingController(text: note.title)..addListener(_onTextChanged);
      _contentController = TextEditingController(text: note.content)..addListener(_onTextChanged);
      _checklistItems = List.from(note.checklist);
      _colorValue = note.colorValue;
      _folderId = note.folderId;
      _blocks = List.from(note.safeBlocks);
      _isInit = false;
    }
  }

  TextEditingController _getController(String blockId, String initialText) {
    if (!_blockControllers.containsKey(blockId)) {
      final controller = TextEditingController(text: initialText);
      controller.addListener(_onTextChanged);
      _blockControllers[blockId] = controller;
    }
    return _blockControllers[blockId]!;
  }

  FocusNode _getFocusNode(String blockId) {
    if (!_blockFocusNodes.containsKey(blockId)) {
      _blockFocusNodes[blockId] = FocusNode();
    }
    return _blockFocusNodes[blockId]!;
  }

  void _onTextChanged() {
    setState(() {}); // Dynamic rebuild to update real-time character count
  }

  void _cleanUpBlockControllerAndFocus(String blockId) {
    final controller = _blockControllers.remove(blockId);
    if (controller != null) {
      controller.removeListener(_onTextChanged);
      controller.dispose();
    }
    final focusNode = _blockFocusNodes.remove(blockId);
    if (focusNode != null) {
      focusNode.dispose();
    }
  }

  int _calculateTotalCharacters() {
    int total = _titleController.text.length;
    for (final block in _blocks) {
      if (block.type == BlockType.text || block.type == BlockType.quote || block.type == BlockType.task) {
        final controller = _blockControllers[block.id];
        total += controller != null ? controller.text.length : block.text.length;
      }
    }
    return total;
  }

  String _formatNoteDate(DateTime dt) {
    final day = dt.day;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];

    int hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;

    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '$day $month $hour:$minuteStr$ampm';
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();

    _titleController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    _checklistInputController.dispose();

    for (final c in _blockControllers.values) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final f in _blockFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncBlocksToLegacyData() {
    final contentBuffer = StringBuffer();
    final checklistResult = <ChecklistItem>[];

    for (final block in _blocks) {
      if (block.type == BlockType.text) {
        if (contentBuffer.isNotEmpty) contentBuffer.write('\n');
        contentBuffer.write(block.text);
      } else if (block.type == BlockType.quote) {
        if (contentBuffer.isNotEmpty) contentBuffer.write('\n');
        contentBuffer.write('"${block.text}"');
      } else if (block.type == BlockType.task) {
        checklistResult.add(ChecklistItem(text: block.text, isChecked: block.isChecked));
      }
    }

    _contentController.text = contentBuffer.toString();
    _checklistItems = checklistResult;
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    _syncBlocksToLegacyData();
    final content = _contentController.text.trim();

    final isBlocksEmpty = _blocks.every((b) =>
        (b.type == BlockType.text && b.text.trim().isEmpty) ||
        (b.type == BlockType.quote && b.text.trim().isEmpty) ||
        (b.type == BlockType.task && b.text.trim().isEmpty) ||
        (b.type == BlockType.image && b.images.isEmpty));

    if (title.isEmpty && isBlocksEmpty) {
      ref.read(notesProvider.notifier).deleteNote(widget.noteId);
    } else {
      ref.read(notesProvider.notifier).updateNote(
            widget.noteId,
            title: title,
            content: content,
            colorValue: _colorValue,
            checklist: _checklistItems,
            blocks: _blocks,
            folderId: _folderId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final folders = ref.watch(foldersProvider);

    // Find note to watch reactive updates for pin/favorite status
    final note = allNotes.firstWhere(
      (n) => n.id == widget.noteId,
      orElse: () => Note(
        id: widget.noteId,
        title: _titleController.text,
        content: _contentController.text,
        isPinned: false,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        colorValue: _colorValue,
        checklist: _checklistItems,
      ),
    );

    final colors = [
      0xFFFFFFFF,
      ...AppTheme.premiumColors.map((pc) => pc.color.value),
    ];
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Scaffold background for dark mode support when note color is default white
    final scaffoldBg = (_colorValue == 0xFFFFFFFF && isDarkTheme)
        ? Theme.of(context).scaffoldBackgroundColor
        : Color(_colorValue);
        
    final isBgDark = ThemeData.estimateBrightnessForColor(scaffoldBg) == Brightness.dark;
    final editorTextColor = isBgDark ? Colors.white : const Color(0xFF2C2A29);
    final iconColor = isBgDark ? Colors.white70 : const Color(0xFF2C2A29);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: iconColor, size: 20),
            onPressed: () {
              _saveNote();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned ? Theme.of(context).primaryColor : iconColor,
              ),
              onPressed: () {
                ref.read(notesProvider.notifier).togglePin(widget.noteId);
              },
            ),
            IconButton(
              icon: Icon(
                note.isFavorite ? Icons.star : Icons.star_border,
                color: note.isFavorite ? Theme.of(context).primaryColor : iconColor,
              ),
              onPressed: () {
                ref.read(notesProvider.notifier).toggleFavorite(widget.noteId);
              },
            ),
            IconButton(
              icon: Icon(Icons.ios_share, color: iconColor),
              tooltip: 'Export Note',
              onPressed: () => _exportSingleNote(note),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode, // Hook up focus node for typing hiding
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: editorTextColor,
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(color: editorTextColor.withAlpha(80)),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final charCount = _calculateTotalCharacters();
                          final charSuffix = charCount == 1 ? 'Character' : 'Characters';
                          final metadataLine = '${_formatNoteDate(note.updatedAt)} | $charCount $charSuffix';
                          return Text(
                            metadataLine,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: editorTextColor.withOpacity(0.55),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _blocks.length,
                        itemBuilder: (context, index) {
                          final block = _blocks[index];
                          if (block.type == BlockType.text) {
                            return _buildTextBlock(block, index);
                          } else if (block.type == BlockType.task) {
                            return _buildTaskBlock(block, index);
                          } else if (block.type == BlockType.quote) {
                            return _buildQuoteBlock(block, index);
                          } else if (block.type == BlockType.image) {
                            return _buildImageBlock(block, index);
                          } else if (block.type == BlockType.file) {
                            return _buildFileBlock(block, index);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: isDarkTheme ? const Color(0xFF15171A).withAlpha(220) : Colors.white.withAlpha(200),
                  border: Border(top: BorderSide(color: isDarkTheme ? Colors.white12 : const Color(0xFFE5DEC9), width: 0.8)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildActionButton(
                          icon: Icons.fact_check_outlined,
                          tooltip: 'Add Checklist',
                          iconColor: Theme.of(context).primaryColor == Colors.black ? const Color(0xFF7C3AED) : Theme.of(context).primaryColor,
                          onTap: () {
                            final newTaskBlock = NoteBlock(
                              id: 'task_${DateTime.now().microsecondsSinceEpoch}',
                              type: BlockType.task,
                              text: '',
                              isChecked: false,
                            );
                            _insertBlockAtCursor(newTaskBlock);
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          icon: Icons.add_photo_alternate_outlined,
                          tooltip: 'Add Image',
                          iconColor: Theme.of(context).primaryColor == Colors.black ? const Color(0xFF059669) : Theme.of(context).primaryColor,
                          onTap: () {
                            _showAddImageOptions(context);
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          icon: Icons.format_quote_outlined,
                          tooltip: 'Add Quote',
                          iconColor: Theme.of(context).primaryColor == Colors.black ? const Color(0xFFD97706) : Theme.of(context).primaryColor,
                          onTap: () {
                            final newQuoteBlock = NoteBlock(
                              id: 'quote_${DateTime.now().microsecondsSinceEpoch}',
                              type: BlockType.quote,
                              text: '',
                            );
                            _insertBlockAtCursor(newQuoteBlock);
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          icon: Icons.upload_file_outlined,
                          tooltip: 'Upload File',
                          iconColor: Theme.of(context).primaryColor == Colors.black ? const Color(0xFF2563EB) : Theme.of(context).primaryColor,
                          onTap: () {
                            _pickFile();
                          },
                        ),
                      ],
                    ),
                    if (!isKeyboardVisible) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE5DEC9), height: 1, thickness: 0.8),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: colors.length,
                          itemBuilder: (context, index) {
                            final cValue = colors[index];
                            final isSelected = cValue == _colorValue;
                            
                            final circleColor = Color(cValue);
                            final isCircleDark = ThemeData.estimateBrightnessForColor(circleColor) == Brightness.dark;
                            
                            final borderColor = isSelected 
                                ? (isBgDark ? Colors.white : const Color(0xFF2C2A29))
                                : (isDarkTheme ? Colors.white12 : const Color(0xFFE2E2E7));
                                
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Tooltip(
                                message: index == 0 ? 'Default Theme' : AppTheme.premiumColors[index - 1].name,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _colorValue = cValue;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: circleColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: borderColor,
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: circleColor.withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: isCircleDark ? Colors.white : Colors.black87,
                                            size: 20,
                                          )
                                        : (index == 0
                                            ? Icon(
                                                Icons.color_lens_outlined,
                                                color: isDarkTheme ? Colors.white30 : Colors.black26,
                                                size: 16,
                                              )
                                            : null),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last edited ${_formatTime(note.updatedAt)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isBgDark ? Colors.white70 : const Color(0xFF8F887F),
                          ),
                        ),
                        if (folders.isNotEmpty)
                          DropdownButton<String?>(
                            value: _folderId,
                            hint: Text(
                              'No Folder',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: editorTextColor.withAlpha(150)),
                            ),
                            underline: Container(),
                            dropdownColor: isDarkTheme ? const Color(0xFF1E2124) : const Color(0xFFFFFFFF),
                            style: GoogleFonts.plusJakartaSans(color: editorTextColor, fontSize: 12),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No Folder', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                              ),
                              ...folders.map((f) {
                                return DropdownMenuItem<String?>(
                                  value: f.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: Color(f.colorValue), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(f.name, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _folderId = val;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _findFocusedBlockId() {
    for (final entry in _blockFocusNodes.entries) {
      if (entry.value.hasFocus) {
        return entry.key;
      }
    }
    return null;
  }

  int _getCursorOffset(String blockId) {
    final controller = _blockControllers[blockId];
    if (controller != null) {
      return controller.selection.baseOffset;
    }
    return -1;
  }

  void _insertBlockAtCursor(NoteBlock newBlock) {
    final focusedId = _findFocusedBlockId();
    if (focusedId != null) {
      final index = _blocks.indexWhere((b) => b.id == focusedId);
      if (index != -1) {
        final currentBlock = _blocks[index];

        // Convert empty text blocks directly (except for images/files)
        if (currentBlock.type == BlockType.text && currentBlock.text.isEmpty && newBlock.type != BlockType.image && newBlock.type != BlockType.file) {
          setState(() {
            final updatedBlock = NoteBlock(
              id: currentBlock.id,
              type: newBlock.type,
              text: newBlock.text,
              isChecked: newBlock.isChecked,
              images: newBlock.images,
            );
            _blocks[index] = updatedBlock;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _getFocusNode(updatedBlock.id).requestFocus();
            });
          });
          return;
        }

        final cursorOffset = _getCursorOffset(focusedId);
        if (cursorOffset >= 0 && cursorOffset <= currentBlock.text.length) {
          final textBefore = currentBlock.text.substring(0, cursorOffset);
          final textAfter = currentBlock.text.substring(cursorOffset);

          setState(() {
            _blocks[index] = currentBlock.copyWith(text: textBefore);
            _blockControllers[focusedId]?.text = textBefore;

            final nextBlockIndex = index + 1;
            final hasTextBlockAfter = nextBlockIndex < _blocks.length && _blocks[nextBlockIndex].type == BlockType.text;

            _blocks.insert(index + 1, newBlock);

            if (hasTextBlockAfter) {
              final nextBlock = _blocks[nextBlockIndex + 1];
              final updatedNextBlock = nextBlock.copyWith(text: textAfter + nextBlock.text);
              _blocks[nextBlockIndex + 1] = updatedNextBlock;
              _blockControllers[nextBlock.id]?.text = updatedNextBlock.text;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (newBlock.type == BlockType.task || newBlock.type == BlockType.quote) {
                  _getFocusNode(newBlock.id).requestFocus();
                } else {
                  _getFocusNode(nextBlock.id).requestFocus();
                }
              });
            } else {
              final afterBlockId = 'text_${DateTime.now().microsecondsSinceEpoch}';
              final afterBlock = NoteBlock(
                id: afterBlockId,
                type: BlockType.text,
                text: textAfter,
              );
              _blocks.insert(index + 2, afterBlock);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (newBlock.type == BlockType.task || newBlock.type == BlockType.quote) {
                  _getFocusNode(newBlock.id).requestFocus();
                } else {
                  _getFocusNode(afterBlockId).requestFocus();
                }
              });
            }
          });
          return;
        }
      }
    }

    setState(() {
      _blocks.add(newBlock);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newBlock.type == BlockType.task || newBlock.type == BlockType.quote) {
          _getFocusNode(newBlock.id).requestFocus();
        }
      });
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2124) : Colors.white,
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFFE5DEC9), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextBlock(NoteBlock block, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = (_colorValue == 0xFFFFFFFF && isDark)
        ? Theme.of(context).scaffoldBackgroundColor
        : Color(_colorValue);
    final isBgDark = ThemeData.estimateBrightnessForColor(scaffoldBg) == Brightness.dark;
    final editorTextColor = isBgDark ? Colors.white : const Color(0xFF2C2A29);
    final editorHintColor = isBgDark ? Colors.white54 : const Color(0xFF6B665E).withAlpha(100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: _getController(block.id, block.text),
        focusNode: _getFocusNode(block.id),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          height: 1.6,
          color: editorTextColor,
        ),
        maxLines: null,
        decoration: InputDecoration(
          hintText: index == 0 ? 'Start writing...' : '',
          hintStyle: TextStyle(color: editorHintColor),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
        onChanged: (val) {
          _blocks[index] = block.copyWith(text: val);
        },
      ),
    );
  }

  Widget _buildTaskBlock(NoteBlock block, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = (_colorValue == 0xFFFFFFFF && isDark)
        ? Theme.of(context).scaffoldBackgroundColor
        : Color(_colorValue);
    final isBgDark = ThemeData.estimateBrightnessForColor(scaffoldBg) == Brightness.dark;
    final editorTextColor = isBgDark ? Colors.white : const Color(0xFF2C2A29);
    final editorHintColor = isBgDark ? Colors.white54 : const Color(0xFF6B665E).withAlpha(100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: block.isChecked,
            activeColor: Theme.of(context).primaryColor,
            side: BorderSide(color: editorTextColor.withAlpha(150), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              setState(() {
                _blocks[index] = block.copyWith(isChecked: val ?? false);
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _getController(block.id, block.text),
              focusNode: _getFocusNode(block.id),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                decoration: block.isChecked ? TextDecoration.lineThrough : null,
                color: block.isChecked ? Colors.grey : editorTextColor,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Checklist item',
                hintStyle: TextStyle(color: editorHintColor),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              onChanged: (val) {
                if (val.endsWith('\n')) {
                  final cleanText = val.substring(0, val.length - 1);
                  _getController(block.id, block.text).text = cleanText;
                  setState(() {
                    _blocks[index] = block.copyWith(text: cleanText);
                    final newBlock = NoteBlock(
                      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
                      type: BlockType.task,
                      text: '',
                      isChecked: false,
                    );
                    _blocks.insert(index + 1, newBlock);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _getFocusNode(newBlock.id).requestFocus();
                    });
                  });
                } else {
                  _blocks[index] = block.copyWith(text: val);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _blocks.removeAt(index);
                _cleanUpBlockControllerAndFocus(block.id);
                _mergeConsecutiveTextFields();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteBlock(NoteBlock block, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = (_colorValue == 0xFFFFFFFF && isDark)
        ? Theme.of(context).scaffoldBackgroundColor
        : Color(_colorValue);
    final isBgDark = ThemeData.estimateBrightnessForColor(scaffoldBg) == Brightness.dark;
    final editorTextColor = isBgDark ? Colors.white : const Color(0xFF2C2A29);
    final editorHintColor = isBgDark ? Colors.white54 : const Color(0xFF6B665E).withAlpha(100);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.08),
        border: Border(
          left: BorderSide(color: Theme.of(context).primaryColor, width: 4.0),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _getController(block.id, block.text),
              focusNode: _getFocusNode(block.id),
              style: GoogleFonts.merriweather(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: editorTextColor,
                height: 1.6,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Enter quote...',
                hintStyle: TextStyle(color: editorHintColor),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              onChanged: (val) {
                _blocks[index] = block.copyWith(text: val);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _blocks.removeAt(index);
                _cleanUpBlockControllerAndFocus(block.id);
                _mergeConsecutiveTextFields();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageBlock(NoteBlock block, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: block.images.map((noteImg) {
          final imgWidth = (MediaQuery.of(context).size.width - 60) / 2;
          return GestureDetector(
            onTap: () {
              _showImageDetailsBottomSheet(context, block.id, noteImg);
            },
            onLongPress: () {
              _showFullscreenImagePreview(context, noteImg);
            },
            child: Container(
              width: imgWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5DEC9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: _buildImageWidget(noteImg.url, imgWidth),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            noteImg.name.isNotEmpty ? noteImg.name : 'Tap to describe',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: noteImg.name.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                              color: noteImg.name.isNotEmpty ? const Color(0xFF2C2A29) : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileBlock(NoteBlock block, int index) {
    final parts = block.text.split('|');
    final filePath = parts.first;
    final fileName = parts.length > 1 ? parts[1] : filePath.split('/').last.split('\\').last;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = (_colorValue == 0xFFFFFFFF && isDark)
        ? Theme.of(context).scaffoldBackgroundColor
        : Color(_colorValue);
    final isBgDark = ThemeData.estimateBrightnessForColor(scaffoldBg) == Brightness.dark;
    final editorTextColor = isBgDark ? Colors.white : const Color(0xFF2C2A29);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2124) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5DEC9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: editorTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  filePath,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            onPressed: () {
              setState(() {
                _blocks.removeAt(index);
                _cleanUpBlockControllerAndFocus(block.id);
                _mergeConsecutiveTextFields();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        final fileBlock = NoteBlock(
          id: 'file_${DateTime.now().microsecondsSinceEpoch}',
          type: BlockType.file,
          text: '$filePath|$fileName',
        );
        
        _insertBlockAtCursor(fileBlock);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _showAddImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DEC9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).primaryColor),
                title: Text(
                  'Select from Gallery',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: Theme.of(context).primaryColor),
                title: Text(
                  'Take by Camera',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final List<String> paths = pickedFiles.map((file) => file.path).toList();
        _addImagesToNote(paths);
      }
    } catch (e) {
      debugPrint('Error picking gallery images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        _addImagesToNote([pickedFile.path]);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  void _addImagesToNote(List<String> paths) {
    final noteImages = paths.map((path) => NoteImage(
      id: 'img_${DateTime.now().microsecondsSinceEpoch}_${paths.indexOf(path)}',
      url: path,
    )).toList();

    final imageBlock = NoteBlock(
      id: 'block_img_${DateTime.now().microsecondsSinceEpoch}',
      type: BlockType.image,
      images: noteImages,
    );

    _insertBlockAtCursor(imageBlock);
  }

  Widget _buildImageWidget(String url, double width) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: 120,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(url),
        height: 120,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  void _showImageDetailsBottomSheet(BuildContext context, String blockId, NoteImage noteImage) {
    final nameController = TextEditingController(text: noteImage.name);
    final descController = TextEditingController(text: noteImage.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DEC9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Image Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2A29),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Image Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DEC9)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DEC9)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteImageConfirmation(context, blockId, noteImage);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedImage = noteImage.copyWith(
                            name: nameController.text.trim(),
                            description: descController.text.trim(),
                          );
                          _updateNoteImage(blockId, noteImage.id, updatedImage);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteImageConfirmation(BuildContext context, String blockId, NoteImage noteImage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Image',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this image? This action cannot be undone.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B665E), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteNoteImage(blockId, noteImage.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateNoteImage(String blockId, String imageId, NoteImage updatedImage) {
    setState(() {
      final blockIndex = _blocks.indexWhere((b) => b.id == blockId);
      if (blockIndex != -1) {
        final block = _blocks[blockIndex];
        final imageIndex = block.images.indexWhere((img) => img.id == imageId);
        if (imageIndex != -1) {
          final updatedImages = List<NoteImage>.from(block.images);
          updatedImages[imageIndex] = updatedImage;
          _blocks[blockIndex] = block.copyWith(images: updatedImages);
        }
      }
    });
  }

  void _deleteNoteImage(String blockId, String imageId) {
    setState(() {
      final blockIndex = _blocks.indexWhere((b) => b.id == blockId);
      if (blockIndex != -1) {
        final block = _blocks[blockIndex];
        final updatedImages = block.images.where((img) => img.id != imageId).toList();
        if (updatedImages.isEmpty) {
          _blocks.removeAt(blockIndex);
          _cleanUpBlockControllerAndFocus(blockId);
          _mergeConsecutiveTextFields();
        } else {
          _blocks[blockIndex] = block.copyWith(images: updatedImages);
        }
      }
    });
  }


  Future<void> _exportSingleNote(Note note) async {
    try {
      final jsonStr = jsonEncode(note.toJson());
      final bytes = utf8.encode(jsonStr);
      final sanitizedTitle = note.title.trim().isEmpty
          ? 'untitled'
          : note.title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'nuvio_note_$sanitizedTitle.json';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Note',
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export note: $e')),
        );
      }
    }
  }


  void _showFullscreenImagePreview(BuildContext context, NoteImage noteImg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: noteImg.id,
                    child: _buildFullscreenImage(noteImg.url),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              if (noteImg.name.isNotEmpty)
                Positioned(
                  bottom: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      noteImg.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullscreenImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
          );
        },
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
          );
        },
      );
    }
  }

  void _mergeConsecutiveTextFields() {
    for (int i = 0; i < _blocks.length - 1; i++) {
      if (_blocks[i].type == BlockType.text && _blocks[i + 1].type == BlockType.text) {
        final blockA = _blocks[i];
        final blockB = _blocks[i + 1];
        
        final mergedText = blockA.text + (blockA.text.isNotEmpty && blockB.text.isNotEmpty ? '\n' : '') + blockB.text;
        _blocks[i] = blockA.copyWith(text: mergedText);
        _blockControllers[blockA.id]?.text = mergedText;
        
        _blocks.removeAt(i + 1);
        _cleanUpBlockControllerAndFocus(blockB.id);
        i--; // check again at this index
      }
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    // Draw vertical grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Draw horizontal grid lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);

    // Center bracket crosshair
    final bracketPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 36, height: 36),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
