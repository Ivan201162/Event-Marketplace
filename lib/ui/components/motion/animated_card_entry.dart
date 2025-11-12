/// AnimatedCardEntry - карточка с анимацией появления
import 'package:flutter/material.dart';
import 'package:event_marketplace_app/theme/animations.dart';

class AnimatedCardEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  
  const AnimatedCardEntry({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
  }) : super(key: key);
  
  @override
  State<AnimatedCardEntry> createState() => _AnimatedCardEntryState();
}

class _AnimatedCardEntryState extends State<AnimatedCardEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.standard),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.smooth),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

