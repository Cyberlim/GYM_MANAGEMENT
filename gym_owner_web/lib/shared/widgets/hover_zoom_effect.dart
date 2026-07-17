import 'package:flutter/material.dart';

class HoverZoomEffect extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const HoverZoomEffect({
    super.key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverZoomEffect> createState() => _HoverZoomEffectState();
}

class _HoverZoomEffectState extends State<HoverZoomEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
