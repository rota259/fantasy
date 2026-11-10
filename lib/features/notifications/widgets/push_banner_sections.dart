part of 'push_banner.dart';

extension _BannerStateSections1 on _BannerState {
  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onClose();
  }

  Widget _buildBody(BuildContext context) {
    final look = _look(widget.kind);
    final slide = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(slide),
        child: FadeTransition(
          opacity: _c,
          child: Dismissible(
            key: const ValueKey('push-banner'),
            direction: DismissDirection.up,
            onDismissed: (_) {
              _closing = true;
              _timer?.cancel();
              widget.onClose();
            },
            child: Material(
              color: Colors.transparent,
              child: Pressable(
                onTap: () {
                  widget.onTap();
                  _close();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xF2101814),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: look.color.withValues(alpha: 0.55), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: look.color.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8)),
                      const BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 14, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: look.color.withValues(alpha: 0.18),
                                border: Border.all(color: look.color.withValues(alpha: 0.6)),
                              ),
                              child: Icon(look.icon, color: look.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.h(14, color: Colors.white),
                                  ),
                                  if (widget.body.isNotEmpty)
                                    Text(
                                      widget.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(12, color: Colors.white.withValues(alpha: 0.78), height: 1.4),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.5), size: 20),
                          ],
                        ),
                      ),
                      // شريط بيخلص مع وقت الإشعار
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1, end: 0),
                        duration: _BannerState._stay,
                        builder: (_, v, _) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 3, color: look.color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
