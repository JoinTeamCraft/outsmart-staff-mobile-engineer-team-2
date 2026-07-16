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
        final double thumbnailSize =
            (constraints.maxWidth * 0.18).clamp(56.0, 96.0).toDouble();

        // Decode resolution follows the device's actual pixel density,
        // not a hardcoded guess.
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final int cacheDimension = (thumbnailSize * devicePixelRatio).round();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Semantics(
                    label: 'Thumbnail for ${lesson.title}',
                    image: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: thumbnailSize,
                        height: thumbnailSize,
                        child: _LessonThumbnail(
                          url: lesson.thumbnail,
                          cacheDimension: cacheDimension,
                        ),
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

class _LessonThumbnail extends StatelessWidget {
  final String url;
  final int cacheDimension;
  const _LessonThumbnail({required this.url, required this.cacheDimension});

  static const _placeholder = ColoredBox(
    color: Color(0xFFEDEDED),
    child: Icon(Icons.broken_image_outlined, size: 24),
  );

  @override
  Widget build(BuildContext context) {
    // Guard against empty/blank thumbnail URLs before ever reaching
    // CachedNetworkImage — an empty string is still a value it will try
    // to request, which wastes a network round-trip (or throws inside the
    // package) and adds log noise, for a case we already know will fail.
    if (url.trim().isEmpty) {
      return const ExcludeSemantics(child: _placeholder);
    }

    return ExcludeSemantics(
      // The outer Semantics(image: true, label: ...) in LessonCard already
      // fully describes this thumbnail — exclude the loading spinner/broken
      // -image icon's own default semantics so a screen reader doesn't
      // announce both.
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        // Decode resolution follows the device's actual pixel density and
        // the thumbnail's actual displayed size — not a hardcoded guess.
        // Avoids allocating a full-res bitmap in memory for no visual
        // benefit when the source image is much larger than the slot.
        memCacheWidth: cacheDimension,
        memCacheHeight: cacheDimension,
        // Caps what's written to the on-disk cache too, so a large source
        // image doesn't bloat local storage on a low-storage device even
        // though it's never displayed at that resolution.
        maxWidthDiskCache: cacheDimension * 2,
        maxHeightDiskCache: cacheDimension * 2,
        // Short fade avoids a jarring pop-in without adding a long-running
        // opacity animation on lower-end GPUs.
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
        errorWidget: (context, url, error) => _placeholder,
      ),
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
