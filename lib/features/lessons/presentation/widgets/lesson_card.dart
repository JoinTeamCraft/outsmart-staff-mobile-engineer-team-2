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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _LessonThumbnail(url: lesson.thumbnail),
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
  }
}

class _LessonThumbnail extends StatelessWidget {
  final String url;
  const _LessonThumbnail({required this.url});

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
    if (url.trim().isEmpty) return _placeholder;

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      // Decode at ~2x display size (retina headroom), not the source
      // image's native resolution — this is what actually avoids jank on
      // a low-RAM device: a 3000px source photo decoded into a 64x64 slot
      // without this would allocate a full-res bitmap in memory for no
      // visual benefit, then downscale it every paint.
      memCacheWidth: 128,
      memCacheHeight: 128,
      // Caps what's written to the on-disk cache too, so a large source
      // image doesn't bloat local storage on a low-storage device even
      // though it's never displayed at that resolution.
      maxWidthDiskCache: 256,
      maxHeightDiskCache: 256,
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