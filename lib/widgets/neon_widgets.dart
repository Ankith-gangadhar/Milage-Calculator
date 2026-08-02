import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// UI Constants
class NeonColors {
  static const Color background = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF161622);
  static const Color cardBg = Color(0x99181826);
  static const Color primary = Color(0xFF8A2BE2); // Neon Purple
  static const Color secondary = Color(0xFFC84BFF); // Pink/Magenta
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9EAE);
  static const Color border = Color(0x33C84BFF);
}

// Glassmorphism Card Widget
class NeonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool hasGlow;

  const NeonCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 20.0,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: NeonColors.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: hasGlow ? NeonColors.secondary.withOpacity(0.5) : NeonColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (hasGlow)
            BoxShadow(
              color: NeonColors.primary.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: NeonColors.primary.withOpacity(0.2),
        highlightColor: NeonColors.secondary.withOpacity(0.1),
        child: card,
      );
    }
    return card;
  }
}

// Glowing Primary Button Widget
class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
        ],
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: NeonColors.primary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          colors: [NeonColors.primary, NeonColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: buttonContent,
      ),
    );
  }
}

// Glowing Floating Action Button Widget
class NeonFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const NeonFAB({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: NeonColors.secondary.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        gradient: const LinearGradient(
          colors: [NeonColors.primary, NeonColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

// Reusable Circular Progress Gauge
class NeonCircleGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0 representation
  final String label;
  final String valueText;
  final double size;

  const NeonCircleGauge({
    super.key,
    required this.value,
    required this.label,
    required this.valueText,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: size - 10,
            height: size - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NeonColors.primary.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Circular progress ring
          ShaderMask(
            shaderCallback: (rect) {
              return const SweepGradient(
                startAngle: 0.0,
                endAngle: 3.14 * 2,
                stops: [0.0, 0.5, 1.0],
                colors: [NeonColors.primary, NeonColors.secondary, NeonColors.primary],
              ).createShader(rect);
            },
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 10,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          // Text Details
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                valueText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Styled Input Field Widget
class NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const NeonTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NeonColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: NeonColors.cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: errorText != null ? Colors.redAccent.withOpacity(0.8) : NeonColors.border,
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: NeonColors.textSecondary.withOpacity(0.5)),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: NeonColors.secondary, size: 20) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0, fontSize: 0), // Hide default error label
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Custom Stat Card Widget
class NeonStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const NeonStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(14.0),
      borderRadius: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, color: NeonColors.secondary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Vehicle Icon Selector Helper
IconData getVehicleIcon(String type) {
  switch (type.toLowerCase()) {
    case 'car':
      return LucideIcons.car;
    case 'bike':
      return LucideIcons.bike;
    case 'scooter':
      return LucideIcons.toy_brick; // Scooter-like representation
    case 'truck':
      return LucideIcons.truck;
    default:
      return LucideIcons.circle_question_mark;
  }
}
