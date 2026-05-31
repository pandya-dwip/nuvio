import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../models/folder_model.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/theme_provider.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  String _backupInterval = 'Never'; // Daily, Weekly, Monthly, Never
  List<FileSystemEntity> _backupFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadBackupHistory();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backupInterval = prefs.getString('backup_interval') ?? 'Never';
    });
  }

  Future<void> _updateInterval(String interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_interval', interval);
    setState(() {
      _backupInterval = interval;
    });
  }

  Future<Directory> _getBackupDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docs.path}/nuvio_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<void> _loadBackupHistory() async {
    setState(() => _isLoading = true);
    try {
      final dir = await _getBackupDirectory();
      final entities = await dir.list().toList();
      final jsonFiles = entities.where((e) {
        final name = e.path.split('/').last.split('\\').last;
        return name.startsWith('nuvio_backup_') && name.endsWith('.json');
      }).toList();

      // Sort by modified time descending
      jsonFiles.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      setState(() {
        _backupFiles = jsonFiles;
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _createBackupNow() async {
    setState(() => _isLoading = true);
    try {
      final notes = ref.read(notesProvider);
      final folders = ref.read(foldersProvider);

      final dataMap = {
        'notes': notes.map((n) => n.toJson()).toList(),
        'folders': folders.map((f) => f.toJson()).toList(),
      };

      final jsonStr = jsonEncode(dataMap);
      final dir = await _getBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final formattedDate = _formatDateTimeForFile(DateTime.now());
      final file = File('${dir.path}/nuvio_backup_${formattedDate}_$timestamp.json');

      await file.writeAsString(jsonStr);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_backup_time', DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      }
      _loadBackupHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create backup: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  String _formatDateTimeForFile(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}_'
        '${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}';
  }

  Future<void> _exportBackupJson() async {
    try {
      final notes = ref.read(notesProvider);
      final folders = ref.read(foldersProvider);

      final dataMap = {
        'notes': notes.map((n) => n.toJson()).toList(),
        'folders': folders.map((f) => f.toJson()).toList(),
      };

      final jsonStr = jsonEncode(dataMap);
      final bytes = utf8.encode(jsonStr);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'nuvio_backup_${_formatDateTimeForFile(DateTime.now())}_$timestamp.json';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Backup JSON',
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importBackupJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        await _processImportData(jsonStr);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _processImportData(String jsonStr) async {
    try {
      final Map<String, dynamic> dataMap = jsonDecode(jsonStr);
      int importedNotesCount = 0;
      int importedFoldersCount = 0;

      if (dataMap.containsKey('folders')) {
        final List<dynamic> foldersJson = dataMap['folders'];
        final folders = foldersJson.map((fj) => Folder.fromJson(fj as Map<String, dynamic>)).toList();
        ref.read(foldersProvider.notifier).importFolders(folders);
        importedFoldersCount = folders.length;
      }

      if (dataMap.containsKey('notes')) {
        final List<dynamic> notesJson = dataMap['notes'];
        final notes = notesJson.map((nj) => Note.fromJson(nj as Map<String, dynamic>)).toList();
        ref.read(notesProvider.notifier).importNotes(notes);
        importedNotesCount = notes.length;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $importedNotesCount notes and $importedFoldersCount folders!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid backup format: $e')),
        );
      }
    }
  }

  Future<void> _restoreLocalBackup(File file) async {
    try {
      final jsonStr = await file.readAsString();
      await _processImportData(jsonStr);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteLocalBackup(File file) async {
    try {
      await file.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup file deleted')),
        );
      }
      _loadBackupHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatFileDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customColor = ref.watch(customThemeColorProvider);
    final brandColor = (customColor.value == Colors.black.value && isDark)
        ? Colors.white
        : (customColor.value == Colors.white.value ? Colors.black : customColor);

    final scaffoldBg = isDark ? const Color(0xFF0D0E10) : const Color(0xFFF3F3F8);
    final cardBg = isDark ? const Color(0xFF1E2124) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? Colors.white38 : const Color(0xFF8F887F);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E2E7);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                  Text(
                    'Data Management',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 40.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  // --- SECTION 1: AUTOMATED BACKUP SCHEDULE ---
                  _buildSectionHeader('AUTOMATED BACKUP SCHEDULE', subtleColor),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderCol, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automatic JSON Backup',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nuvio will automatically backup your notes and folders to local storage at the selected interval.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: subtleColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Segmented choice chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Daily', 'Weekly', 'Monthly', 'Never'].map((interval) {
                            final isSelected = _backupInterval == interval;
                            return ChoiceChip(
                              label: Text(interval),
                              selected: isSelected,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (brandColor == Colors.white || brandColor.value == 0xFFFFFFFF ? Colors.black : Colors.white)
                                    : textColor.withOpacity(0.8),
                              ),
                              selectedColor: brandColor,
                              backgroundColor: isDark ? const Color(0xFF15171A) : const Color(0xFFE8E8ED),
                              checkmarkColor: brandColor == Colors.white || brandColor.value == 0xFFFFFFFF ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? brandColor : borderCol,
                                  width: 1,
                                ),
                              ),
                              onSelected: (_) => _updateInterval(interval),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Create backup now button
                        SizedBox(
                          width: double.maxFinite,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _createBackupNow,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                            label: Text(
                              'CREATE BACKUP NOW',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: brandColor,
                              side: BorderSide(color: brandColor.withOpacity(0.5), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- SECTION 2: IMPORT/EXPORT DATA ---
                  _buildSectionHeader('IMPORT & EXPORT DATA', subtleColor),
                  const SizedBox(height: 10),
                  // Import Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderCol, width: 1.0),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.cloud_download_outlined, color: brandColor, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Vault',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Restore your notes and folders from a Nuvio JSON backup file.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: subtleColor, height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _importBackupJson,
                                icon: const Icon(Icons.upload_file_outlined, size: 16),
                                label: Text(
                                  'UPLOAD JSON FILE',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandColor,
                                  foregroundColor: brandColor == Colors.white || brandColor.value == 0xFFFFFFFF ? Colors.black : Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Export Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderCol, width: 1.0),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.drive_folder_upload_outlined, color: brandColor, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Vault',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Save a backup of all your saved notes and folders to a secure JSON file.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: subtleColor, height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _exportBackupJson,
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: Text(
                                  'EXPORT JSON',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandColor,
                                  foregroundColor: brandColor == Colors.white || brandColor.value == 0xFFFFFFFF ? Colors.black : Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- SECTION 3: AUTOMATED BACKUP HISTORY ---
                  _buildSectionHeader('AUTOMATED BACKUP HISTORY', subtleColor),
                  const SizedBox(height: 10),
                  if (_isLoading && _backupFiles.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_backupFiles.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderCol, width: 1.0),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history_rounded, size: 40, color: subtleColor.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No backup files found locally',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: subtleColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _backupFiles.length,
                      itemBuilder: (context, index) {
                        final file = _backupFiles[index];
                        final filename = file.path.split('/').last.split('\\').last;
                        final stat = file.statSync();
                        final fileSize = _formatFileSize(stat.size);
                        final dateStr = _formatFileDate(stat.modified);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderCol, width: 1.0),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: brandColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.history_rounded, color: brandColor, size: 20),
                            ),
                            title: Text(
                              filename,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '$dateStr  •  $fileSize',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: subtleColor),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: subtleColor),
                              color: cardBg,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (val) {
                                if (val == 'restore') {
                                  _showConfirmRestoreDialog(context, file as File);
                                } else if (val == 'delete') {
                                  _deleteLocalBackup(file as File);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem<String>(
                                  value: 'restore',
                                  child: Row(
                                    children: [
                                      Icon(Icons.settings_backup_restore_rounded, color: textColor, size: 18),
                                      const SizedBox(width: 10),
                                      Text('Restore Backup', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      const SizedBox(width: 10),
                                      Text('Delete File', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showConfirmRestoreDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E2124)
              : Colors.white,
          title: Text(
            'Restore Backup',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to restore this backup? This will merge notes and folders. Existing items with matching IDs will be updated.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _restoreLocalBackup(file);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Restore',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
