import 'package:flutter/material.dart';
import '../../services/download_service.dart';
import '../theme/theme.dart';

/// Downloads panel widget
class DownloadsPanel extends StatelessWidget {
  final DownloadService downloadService;
  final VoidCallback? onClose;

  const DownloadsPanel({
    super.key,
    required this.downloadService,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final downloads = downloadService.downloads;

        return Container(
          width: 380,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, color: textColor, size: 20),
                    const SizedBox(width: 10),
                    Text('Загрузки', style: KoleoTypography.headline.copyWith(color: textColor, fontSize: 16)),
                    const Spacer(),
                    if (downloads.isNotEmpty)
                      TextButton(
                        onPressed: () => downloadService.clearCompleted(),
                        child: Text('Очистить', style: TextStyle(color: secondaryColor, fontSize: 13)),
                      ),
                    IconButton(
                      onPressed: () => downloadService.openDownloadsFolder(),
                      icon: Icon(Icons.folder_open_rounded, color: secondaryColor, size: 20),
                      tooltip: 'Открыть папку',
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
              // Downloads list
              if (downloads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.download_done_rounded, color: secondaryColor, size: 48),
                      const SizedBox(height: 12),
                      Text('Нет загрузок', style: KoleoTypography.body.copyWith(color: secondaryColor)),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) => _DownloadItemTile(
                      item: downloads[index],
                      downloadService: downloadService,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadItemTile extends StatelessWidget {
  final DownloadItem item;
  final DownloadService downloadService;

  const _DownloadItemTile({required this.item, required this.downloadService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);
    final accentColor = isDark ? KoleoColors.darkAccent : KoleoColors.lightAccent;

    return InkWell(
      onTap: item.status == DownloadStatus.completed ? () => downloadService.openFile(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(item.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getStatusIcon(item.status), color: _getStatusColor(item.status), size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: KoleoTypography.body.copyWith(color: textColor, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.status == DownloadStatus.downloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(accentColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    _getStatusText(item),
                    style: KoleoTypography.caption.copyWith(color: secondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Actions
            if (item.status == DownloadStatus.downloading)
              IconButton(
                onPressed: () => downloadService.cancelDownload(item.id),
                icon: Icon(Icons.close_rounded, color: secondaryColor, size: 18),
                tooltip: 'Отменить',
              )
            else if (item.status == DownloadStatus.completed)
              IconButton(
                onPressed: () => downloadService.openFile(item),
                icon: Icon(Icons.folder_open_rounded, color: secondaryColor, size: 18),
                tooltip: 'Открыть',
              )
            else
              IconButton(
                onPressed: () => downloadService.removeDownload(item.id),
                icon: Icon(Icons.delete_outline_rounded, color: secondaryColor, size: 18),
                tooltip: 'Удалить',
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DownloadStatus status) => switch (status) {
    DownloadStatus.pending => Colors.grey,
    DownloadStatus.downloading => Colors.blue,
    DownloadStatus.completed => Colors.green,
    DownloadStatus.failed => Colors.red,
    DownloadStatus.cancelled => Colors.orange,
  };

  IconData _getStatusIcon(DownloadStatus status) => switch (status) {
    DownloadStatus.pending => Icons.schedule_rounded,
    DownloadStatus.downloading => Icons.downloading_rounded,
    DownloadStatus.completed => Icons.check_circle_rounded,
    DownloadStatus.failed => Icons.error_rounded,
    DownloadStatus.cancelled => Icons.cancel_rounded,
  };

  String _getStatusText(DownloadItem item) => switch (item.status) {
    DownloadStatus.pending => 'Ожидание...',
    DownloadStatus.downloading => item.progressText,
    DownloadStatus.completed => 'Завершено',
    DownloadStatus.failed => item.error ?? 'Ошибка',
    DownloadStatus.cancelled => 'Отменено',
  };
}
