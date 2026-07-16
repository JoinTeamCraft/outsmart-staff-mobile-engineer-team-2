import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/lesson.dart';

/// Single row in the Lesson Feed (OU-6). Kept as its own widget rather than
/// inlined in the ListView.builder itemBuilder so it can be profiled
/// independently in DevTools later (OU-22 rebuild audit).
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;

  const LessonCard({super.key, required this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Thumbnail scales with the card's actual available width instead
        // of a fixed pixel value — stays proportional on a small phone and
        // a tablet alike. Clamped so it never gets so small it's useless
        // or so large it dwarfs the text on a wide screen.
        final thumbnailSize = (constraints.maxWidth * 0.18).clamp(56.0, 96.0);

        // Decode resolution follows the device's actual pixel density,
        // not a hardcoded guess — a 3x-density phone needs a sharper
        // decode than a 2x one to look crisp at the same logical size,
        // and this avoids over-decoding on lower-density devices too.
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final cacheDimension = (thumbnailSize * devicePixelRatio).round();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: thumbnailSize,
                      height: thumbnailSize,
                      child: CachedNetworkImage(
                        imageUrl: lesson.thumbnail,
                        fit: BoxFit.cover,
                        memCacheWidth: cacheDimension,
                        memCacheHeight: cacheDimension,
                        maxWidthDiskCache: cacheDimension * 2,
                        maxHeightDiskCache: cacheDimension * 2,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (context, url) => const ColoredBox(
                          color: Color(0xFFEDEDED),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: Color(0xFFEDEDED),
                          child: Icon(Icons.broken_image_outlined, size: 24),
                        ),
                        //cacheManager: lessonImageCacheManager,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          // titleMedium already respects the system font
                          // scale (accessibility text size), so titles
                          // are responsive to user settings with no
                          // extra work here.
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _TopicChip(topic: lesson.topic),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String topic;
  const _TopicChip({required this.topic});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        topic,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
