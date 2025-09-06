import 'package:flutter/material.dart';

/// Interactive body silhouette widget for muscle group selection
/// Provides visual body part filtering for exercise selection
/// Enhanced with level badge overlay system for progress visualization
class BodySilhouette extends StatefulWidget {
  final String? selectedBodyPart;
  final Function(String bodyPart) onBodyPartSelected;
  final bool showLabels;
  final Map<String, int>? bodyPartLevels; // New: Body part level data
  final bool showLevelBadges; // New: Toggle level badge display

  const BodySilhouette({
    super.key,
    this.selectedBodyPart,
    required this.onBodyPartSelected,
    this.showLabels = false,
    this.bodyPartLevels,
    this.showLevelBadges = false,
  });

  @override
  State<BodySilhouette> createState() => _BodySilhouetteState();
}

class _BodySilhouetteState extends State<BodySilhouette> {
  String? _hoveredBodyPart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.accessibility_new, color: Color(0xFFFFB74D)),
                const SizedBox(width: 8),
                Text(
                  'Select Target Muscles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Body Silhouette with level badges
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Front View
                  Column(
                    children: [
                      Text(
                        'FRONT',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFFFB74D),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFrontView(),
                      ],
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Back View  
                  Column(
                    children: [
                      Text(
                        'BACK',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFFFB74D),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                      ),
                      const SizedBox(height: 12),
                      _buildBackView(),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Selected Body Part Info
            if (widget.selectedBodyPart != null || _hoveredBodyPart != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _hoveredBodyPart != null 
                    ? 'Tap to select: ${_hoveredBodyPart!.toUpperCase()}'
                    : 'Selected: ${widget.selectedBodyPart!.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFFB74D),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontView() {
    return Container(
      width: 149,
      height: 285,
      child: Stack(
        children: [
          // PNG Body Silhouette
          Transform(
            transform: Matrix4.diagonal3Values(1.8, 1.3, 1.0),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/body_silhouette_front.png',
              width: 149,
              height: 285,
              fit: BoxFit.fill,
            ),
          ),
          
          // Highlight overlay for selected body part
          if (widget.selectedBodyPart != null || _hoveredBodyPart != null)
            CustomPaint(
              size: const Size(149, 285),
              painter: BodyHighlightPainter(
                isBackView: false,
                selectedBodyPart: widget.selectedBodyPart,
                hoveredBodyPart: _hoveredBodyPart,
              ),
            ),
          
          // Clickable regions for front view
          ..._buildFrontClickableRegions(),
          
          // Level badges for front view
          if (widget.showLevelBadges && widget.bodyPartLevels != null)
            ..._buildFrontLevelBadges(),
        ],
      ),
    );
  }

  Widget _buildBackView() {
    return Container(
      width: 149,
      height: 285,
      child: Stack(
        children: [
          // PNG Body Silhouette
          Transform(
            transform: Matrix4.diagonal3Values(1.8, 1.3, 1.0),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/body_silhouette_back.png',
              width: 149,
              height: 285,
              fit: BoxFit.fill,
            ),
          ),
          
          // Highlight overlay for selected body part
          if (widget.selectedBodyPart != null || _hoveredBodyPart != null)
            CustomPaint(
              size: const Size(149, 285),
              painter: BodyHighlightPainter(
                isBackView: true,
                selectedBodyPart: widget.selectedBodyPart,
                hoveredBodyPart: _hoveredBodyPart,
              ),
            ),
          
          // Clickable regions for back view
          ..._buildBackClickableRegions(),
          
          // Level badges for back view
          if (widget.showLevelBadges && widget.bodyPartLevels != null)
            ..._buildBackLevelBadges(),
        ],
      ),
    );
  }

  List<Widget> _buildFrontClickableRegions() {
    return [
      // Chest
      _buildClickableRegion(
        bodyPart: 'chest',
        left: 35,
        top: 68,
        width: 61,
        height: 39,
      ),
      
      // Shoulders (front delts)
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 20,
        top: 52,
        width: 18,
        height: 32,
      ),
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 97,
        top: 52,
        width: 18,
        height: 32,
      ),
      
      // Upper Arms (biceps)
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 14,
        top: 79,
        width: 14,
        height: 41,
      ),
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 108,
        top: 79,
        width: 14,
        height: 41,
      ),
      
      // Lower Arms (forearms)
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 12,
        top: 113,
        width: 9,
        height: 34,
      ),
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 113,
        top: 113,
        width: 9,
        height: 34,
      ),
      
      // Waist (abs)
      _buildClickableRegion(
        bodyPart: 'waist',
        left: 39,
        top: 107,
        width: 56,
        height: 62,
      ),
      
      // Upper Legs (quads)
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 47,
        top: 180,
        width: 18,
        height: 56,
      ),
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 70,
        top: 180,
        width: 18,
        height: 56,
      ),
      
      // Lower Legs (calves)
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 47,
        top: 242,
        width: 14,
        height: 45,
      ),
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 74,
        top: 242,
        width: 14,
        height: 45,
      ),
    ];
  }

  List<Widget> _buildBackClickableRegions() {
    return [
      // Back (upper back)
      _buildClickableRegion(
        bodyPart: 'back',
        left: 36,
        top: 68,
        width: 63,
        height: 50,
      ),
      
      // Shoulders (rear delts)
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 20,
        top: 52,
        width: 18,
        height: 32,
      ),
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 97,
        top: 52,
        width: 18,
        height: 32,
      ),
      
      // Upper Arms (triceps)
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 14,
        top: 79,
        width: 14,
        height: 41,
      ),
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 108,
        top: 79,
        width: 14,
        height: 41,
      ),
      
      // Lower Arms (forearms back)
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 12,
        top: 113,
        width: 9,
        height: 34,
      ),
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 113,
        top: 113,
        width: 9,
        height: 34,
      ),
      
      // Upper Legs (glutes/hamstrings)
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 47,
        top: 180,
        width: 18,
        height: 56,
      ),
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 70,
        top: 180,
        width: 18,
        height: 56,
      ),
      
      // Lower Legs (calves back)
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 47,
        top: 242,
        width: 14,
        height: 45,
      ),
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 74,
        top: 242,
        width: 14,
        height: 45,
      ),
    ];
  }

  Widget _buildClickableRegion({
    required String bodyPart,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final isSelected = widget.selectedBodyPart == bodyPart;
    final isHovered = _hoveredBodyPart == bodyPart;
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          widget.onBodyPartSelected(bodyPart);
          setState(() {
            _hoveredBodyPart = null;
          });
        },
        onTapDown: (_) {
          setState(() {
            _hoveredBodyPart = bodyPart;
          });
        },
        onTapCancel: () {
          setState(() {
            _hoveredBodyPart = null;
          });
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isSelected 
              ? const Color(0xFFFFB74D).withOpacity(0.3)
              : isHovered 
                ? const Color(0xFFFFB74D).withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.showLabels
            ? Center(
                child: Text(
                  bodyPart.split(' ').map((word) => word[0].toUpperCase()).join(),
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        ),
      ),
    );
  }

  /// Build level badge overlays for front view
  List<Widget> _buildFrontLevelBadges() {
    return [
      // Chest level badge
      _buildLevelBadge('chest', 65, 52),
      
      // Shoulders level badges (show one badge for both shoulders)
      _buildLevelBadge('shoulders', 30, 35),
      
      // Upper arms level badges (show one badge for both arms)
      _buildLevelBadge('upper arms', 10, 65),
      
      // Lower arms level badge
      _buildLevelBadge('lower arms', 6, 95),
      
      // Waist (abs) level badge
      _buildLevelBadge('waist', 65, 125),
      
      // Upper legs level badge
      _buildLevelBadge('upper legs', 75, 165),
      
      // Lower legs level badge
      _buildLevelBadge('lower legs', 75, 220),
    ];
  }

  /// Build level badge overlays for back view
  List<Widget> _buildBackLevelBadges() {
    return [
      // Back level badge
      _buildLevelBadge('back', 65, 52),
      
      // Shoulders level badges (show one badge for both shoulders)
      _buildLevelBadge('shoulders', 30, 35),
      
      // Upper arms level badges (show one badge for both arms)
      _buildLevelBadge('upper arms', 10, 65),
      
      // Lower arms level badge
      _buildLevelBadge('lower arms', 6, 95),
      
      // Upper legs level badge (glutes/hamstrings)
      _buildLevelBadge('upper legs', 75, 165),
      
      // Lower legs level badge
      _buildLevelBadge('lower legs', 75, 220),
    ];
  }

  /// Build individual level badge widget
  Widget _buildLevelBadge(String bodyPart, double left, double top) {
    final level = widget.bodyPartLevels?[bodyPart];
    if (level == null || level <= 0) return const SizedBox.shrink();
    
    // Level-based colors and styling
    Color badgeColor;
    Color textColor = Colors.white;
    IconData? badgeIcon;
    
    if (level >= 20) {
      badgeColor = const Color(0xFFFFD700); // Gold
      textColor = Colors.black;
      badgeIcon = Icons.star;
    } else if (level >= 15) {
      badgeColor = const Color(0xFFE91E63); // Pink
      badgeIcon = Icons.diamond;
    } else if (level >= 10) {
      badgeColor = const Color(0xFF9C27B0); // Purple
      badgeIcon = Icons.military_tech;
    } else if (level >= 5) {
      badgeColor = const Color(0xFF2196F3); // Blue
      badgeIcon = Icons.shield;
    } else {
      badgeColor = const Color(0xFF4CAF50); // Green
      badgeIcon = Icons.fitness_center;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icon
            if (badgeIcon != null)
              Positioned.fill(
                child: Icon(
                  badgeIcon,
                  size: 14,
                  color: textColor.withOpacity(0.3),
                ),
              ),
            // Level text
            Positioned.fill(
              child: Center(
                child: Text(
                  level.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for muscle highlighting only (SVG handles silhouette)
class BodyHighlightPainter extends CustomPainter {
  final bool isBackView;
  final String? selectedBodyPart;
  final String? hoveredBodyPart;

  BodyHighlightPainter({
    required this.isBackView,
    this.selectedBodyPart,
    this.hoveredBodyPart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFB74D).withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.overlay;

    final selectedPaint = Paint()
      ..color = const Color(0xFFFFB74D).withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.overlay;

    // Draw highlights based on selected/hovered body parts
    final bodyPart = selectedBodyPart ?? hoveredBodyPart;
    if (bodyPart != null) {
      _drawBodyPartHighlight(canvas, size, bodyPart, 
        selectedBodyPart != null ? selectedPaint : highlightPaint);
    }
  }

  void _drawBodyPartHighlight(Canvas canvas, Size size, String bodyPart, Paint paint) {
    final width = size.width;
    final height = size.height;

    switch (bodyPart) {
      case 'chest':
        if (!isBackView) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(width * 0.35, height * 0.25, width * 0.3, height * 0.18),
              const Radius.circular(12),
            ),
            paint,
          );
        }
        break;
        
      case 'back':
        if (isBackView) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(width * 0.35, height * 0.25, width * 0.3, height * 0.25),
              const Radius.circular(12),
            ),
            paint,
          );
        }
        break;
        
      case 'shoulders':
        // Left shoulder
        canvas.drawCircle(
          Offset(width * 0.22, height * 0.27),
          width * 0.09,
          paint,
        );
        // Right shoulder
        canvas.drawCircle(
          Offset(width * 0.78, height * 0.27),
          width * 0.09,
          paint,
        );
        break;
        
      case 'upper arms':
        // Left arm
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.12, height * 0.32, width * 0.15, height * 0.28),
            const Radius.circular(8),
          ),
          paint,
        );
        // Right arm
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.73, height * 0.32, width * 0.15, height * 0.28),
            const Radius.circular(8),
          ),
          paint,
        );
        break;
        
      case 'lower arms':
        // Left forearm
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.16, height * 0.50, width * 0.12, height * 0.22),
            const Radius.circular(6),
          ),
          paint,
        );
        // Right forearm
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.72, height * 0.50, width * 0.12, height * 0.22),
            const Radius.circular(6),
          ),
          paint,
        );
        break;
        
      case 'waist':
        if (!isBackView) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(width * 0.38, height * 0.45, width * 0.24, height * 0.28),
              const Radius.circular(10),
            ),
            paint,
          );
        }
        break;
        
      case 'upper legs':
        // Left thigh
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.37, height * 0.67, width * 0.14, height * 0.32),
            const Radius.circular(8),
          ),
          paint,
        );
        // Right thigh
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.49, height * 0.67, width * 0.14, height * 0.32),
            const Radius.circular(8),
          ),
          paint,
        );
        break;
        
      case 'lower legs':
        // Left calf
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.35, height * 0.83, width * 0.12, height * 0.25),
            const Radius.circular(6),
          ),
          paint,
        );
        // Right calf
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.53, height * 0.83, width * 0.12, height * 0.25),
            const Radius.circular(6),
          ),
          paint,
        );
        break;
        
      case 'cardio':
        // Highlight full body for cardio
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * 0.15, height * 0.05, width * 0.7, height * 0.9),
            const Radius.circular(15),
          ),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(BodyHighlightPainter oldDelegate) {
    return oldDelegate.selectedBodyPart != selectedBodyPart ||
           oldDelegate.hoveredBodyPart != hoveredBodyPart ||
           oldDelegate.isBackView != isBackView;
  }
}