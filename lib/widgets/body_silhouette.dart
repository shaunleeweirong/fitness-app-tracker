import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Interactive body silhouette widget for muscle group selection
/// Provides visual body part filtering for exercise selection
class BodySilhouette extends StatefulWidget {
  final String? selectedBodyPart;
  final Function(String bodyPart) onBodyPartSelected;
  final bool showLabels;

  const BodySilhouette({
    super.key,
    this.selectedBodyPart,
    required this.onBodyPartSelected,
    this.showLabels = false,
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
            
            // Body Silhouette
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Front View
                Expanded(
                  child: Column(
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
                ),
                
                const SizedBox(width: 40),
                
                // Back View  
                Expanded(
                  child: Column(
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
                ),
              ],
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
    return SizedBox(
      width: 120,
      height: 280,
      child: Stack(
        children: [
          // SVG Body Silhouette
          SvgPicture.asset(
            'assets/images/body_silhouette_front.svg',
            width: 120,
            height: 280,
            fit: BoxFit.contain,
          ),
          
          // Highlight overlay for selected body part
          if (widget.selectedBodyPart != null || _hoveredBodyPart != null)
            CustomPaint(
              size: const Size(120, 280),
              painter: BodyHighlightPainter(
                isBackView: false,
                selectedBodyPart: widget.selectedBodyPart,
                hoveredBodyPart: _hoveredBodyPart,
              ),
            ),
          
          // Clickable regions for front view
          ..._buildFrontClickableRegions(),
        ],
      ),
    );
  }

  Widget _buildBackView() {
    return SizedBox(
      width: 120,
      height: 280,
      child: Stack(
        children: [
          // SVG Body Silhouette
          SvgPicture.asset(
            'assets/images/body_silhouette_back.svg',
            width: 120,
            height: 280,
            fit: BoxFit.contain,
          ),
          
          // Highlight overlay for selected body part
          if (widget.selectedBodyPart != null || _hoveredBodyPart != null)
            CustomPaint(
              size: const Size(120, 280),
              painter: BodyHighlightPainter(
                isBackView: true,
                selectedBodyPart: widget.selectedBodyPart,
                hoveredBodyPart: _hoveredBodyPart,
              ),
            ),
          
          // Clickable regions for back view
          ..._buildBackClickableRegions(),
        ],
      ),
    );
  }

  List<Widget> _buildFrontClickableRegions() {
    return [
      // Chest
      _buildClickableRegion(
        bodyPart: 'chest',
        left: 32,
        top: 60,
        width: 56,
        height: 35,
      ),
      
      // Shoulders (front delts)
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 18,
        top: 46,
        width: 16,
        height: 28,
      ),
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 86,
        top: 46,
        width: 16,
        height: 28,
      ),
      
      // Upper Arms (biceps)
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 12,
        top: 70,
        width: 12,
        height: 36,
      ),
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 96,
        top: 70,
        width: 12,
        height: 36,
      ),
      
      // Lower Arms (forearms)
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 11,
        top: 100,
        width: 8,
        height: 30,
      ),
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 101,
        top: 100,
        width: 8,
        height: 30,
      ),
      
      // Waist (abs)
      _buildClickableRegion(
        bodyPart: 'waist',
        left: 35,
        top: 95,
        width: 50,
        height: 55,
      ),
      
      // Upper Legs (quads)
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 42,
        top: 160,
        width: 16,
        height: 50,
      ),
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 62,
        top: 160,
        width: 16,
        height: 50,
      ),
      
      // Lower Legs (calves)
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 42,
        top: 215,
        width: 12,
        height: 40,
      ),
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 66,
        top: 215,
        width: 12,
        height: 40,
      ),
    ];
  }

  List<Widget> _buildBackClickableRegions() {
    return [
      // Back (upper back)
      _buildClickableRegion(
        bodyPart: 'back',
        left: 32,
        top: 60,
        width: 56,
        height: 45,
      ),
      
      // Shoulders (rear delts)
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 18,
        top: 46,
        width: 16,
        height: 28,
      ),
      _buildClickableRegion(
        bodyPart: 'shoulders',
        left: 86,
        top: 46,
        width: 16,
        height: 28,
      ),
      
      // Upper Arms (triceps)
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 12,
        top: 70,
        width: 12,
        height: 36,
      ),
      _buildClickableRegion(
        bodyPart: 'upper arms',
        left: 96,
        top: 70,
        width: 12,
        height: 36,
      ),
      
      // Lower Arms (forearms back)
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 11,
        top: 100,
        width: 8,
        height: 30,
      ),
      _buildClickableRegion(
        bodyPart: 'lower arms',
        left: 101,
        top: 100,
        width: 8,
        height: 30,
      ),
      
      // Upper Legs (glutes/hamstrings)
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 42,
        top: 160,
        width: 16,
        height: 50,
      ),
      _buildClickableRegion(
        bodyPart: 'upper legs',
        left: 62,
        top: 160,
        width: 16,
        height: 50,
      ),
      
      // Lower Legs (calves back)
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 42,
        top: 215,
        width: 12,
        height: 40,
      ),
      _buildClickableRegion(
        bodyPart: 'lower legs',
        left: 66,
        top: 215,
        width: 12,
        height: 40,
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