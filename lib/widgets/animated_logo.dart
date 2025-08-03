import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class AnimatedLogo extends StatefulWidget {
  final ScrollController? scrollController;
  final bool showCompact;
  final Function(double)? onHeightChanged;

  const AnimatedLogo({
    super.key,
    this.scrollController,
    this.showCompact = false,
    this.onHeightChanged,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _scrollAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _compactProgress;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _splitOffset;
  late Animation<Offset> _matesOffset;
  late Animation<double> _iconOpacity;
  late Animation<double> _emojiScale;
  late Animation<double> _heightProgress;

  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _scrollAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _compactProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrollAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _scrollAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _scrollAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrollAnimationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _emojiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrollAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _heightProgress = Tween<double>(begin: 130.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _scrollAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _splitOffset = Tween<Offset>(begin: const Offset(-2.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    _matesOffset = Tween<Offset>(begin: const Offset(2.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }

    _scrollAnimationController.addListener(() {
      if (widget.onHeightChanged != null) {
        widget.onHeightChanged!(_heightProgress.value);
      }
    });

    if (widget.showCompact) {
      _scrollProgress = 1.0;
      _scrollAnimationController.value = 1.0;
      _startTextAnimation();
    }
  }

  void _onScroll() {
    if (widget.scrollController == null) return;

    final offset = widget.scrollController!.offset;
    final maxOffset = 100.0;

    final newProgress = (offset / maxOffset).clamp(0.0, 1.0);

    if (newProgress != _scrollProgress) {
      setState(() {
        _scrollProgress = newProgress;
      });

      _scrollAnimationController.animateTo(newProgress);

      if (newProgress > 0.5 &&
          _textAnimationController.status == AnimationStatus.dismissed) {
        _startTextAnimation();
      } else if (newProgress <= 0.3) {
        _textAnimationController.reset();
      }
    }
  }

  void _startTextAnimation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _scrollProgress > 0.3) {
        _textAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    _scrollAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scrollAnimationController,
        _textAnimationController,
      ]),
      builder: (context, child) {
        final isCompact = _compactProgress.value > 0.5;
        final currentHeight = 130.0 - (_compactProgress.value * 70.0);

        return SizedBox(
          width: 280,
          height: currentHeight,
          child: Stack(
            children: [
              // Original logo with icon and stacked text
              Positioned(
                left: 15,
                top: 5,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Split',
                                style: GoogleFonts.notoSansThaiTextTheme()
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40,
                                      color: AppConstants.primaryText,
                                      height: 1.2,
                                      // letterSpacing: 2.0,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 30.0),
                              child: Text(
                                'Mates',
                                style: GoogleFonts.notoSansThaiTextTheme()
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40,
                                      color: AppConstants.primaryText,
                                      height: 1.0,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Compact version with money emoji and animated text
              Positioned(
                left: 15,
                top: isCompact ? 5 : 10,
                child: Opacity(
                  opacity: _iconOpacity.value,
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: _emojiScale.value,
                        child: const Text('💰', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 8),
                      ClipRect(
                        child: Row(
                          children: [
                            SlideTransition(
                              position: _splitOffset,
                              child: Text(
                                'Split',
                                style: GoogleFonts.notoSansThaiTextTheme()
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppConstants.primaryText,
                                      height: 1.0,
                                    ),
                              ),
                            ),
                            SlideTransition(
                              position: _matesOffset,
                              child: Text(
                                ' Mates',
                                style: GoogleFonts.notoSansThaiTextTheme()
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppConstants.primaryText,
                                      height: 1.0,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
