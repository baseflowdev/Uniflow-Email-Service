import 'package:flutter/material.dart';
import 'package:uniflow/models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.onPin,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: isCompact ? _buildCompactCard(context) : _buildFullCard(context),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned)
                const Icon(Icons.push_pin, size: 16, color: Colors.orange),
              if (note.isPinned) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.preview,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(note.modifiedAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (note.isPinned)
                const Icon(Icons.push_pin, size: 20, color: Colors.orange),
              if (note.isPinned) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'pin':
                      onPin?.call();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: ListTile(
                      leading: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      ),
                      title: Text(note.isPinned ? 'Unpin' : 'Pin'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Content preview
          Text(
            note.preview,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Tags
          if (note.tags.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: note.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          
          const SizedBox(height: 8),
          
          // Footer
          Row(
            children: [
              Text(
                _formatDate(note.modifiedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
              const Spacer(),
              if (note.tags.length > 3)
                Text(
                  '+${note.tags.length - 3} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

