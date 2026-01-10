import 'package:flutter/material.dart';
import '../../services/update_service.dart';

/// Dialog showing update available notification
class UpdateDialog extends StatefulWidget {
  final UpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.updateService,
  });

  /// Show update dialog
  static Future<void> show(BuildContext context, UpdateService updateService) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpdateDialog(updateService: updateService),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  void initState() {
    super.initState();
    widget.updateService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.updateService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update,
                size: 32,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Доступно обновление!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // Version info
            Text(
              'Koleo Browser ${widget.updateService.latestVersion}',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Текущая версия: ${widget.updateService.currentVersion}',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            
            // Download progress
            if (widget.updateService.isDownloading) ...[
              LinearProgressIndicator(
                value: widget.updateService.downloadProgress,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Загрузка: ${(widget.updateService.downloadProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.updateService.isDownloading 
                        ? null 
                        : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Позже',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.updateService.isDownloading 
                        ? null 
                        : () => widget.updateService.downloadAndInstall(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.updateService.isDownloading ? 'Загрузка...' : 'Обновить',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
