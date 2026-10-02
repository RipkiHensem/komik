import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/chapter.dart';

/// Editorial chapter row with a quiet divider and clear read/new labels.
class ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final String? coverUrl;
  final bool isRead;
  final bool isNew;
  final VoidCallback? onTap;
  final bool showDelete;
  final VoidCallback? onDelete;

  const ChapterTile({
    super.key,
    required this.chapter,
    this.coverUrl,
    this.isRead = false,
    this.isNew = false,
    this.onTap,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chapter.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                              color: isRead
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'BARU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isRead) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Sudah dibaca',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                chapter.relativeTime,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              if (isRead)
                Icon(Icons.check, size: 18, color: AppColors.textSecondary)
              else
                Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              if (showDelete)
                IconButton(
                  tooltip: 'Hapus chapter dari aplikasi',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
