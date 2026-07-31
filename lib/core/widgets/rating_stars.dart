import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double iconSize;
  final ValueChanged<int>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.iconSize = 32,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= rating;

        return InkWell(
          key: ValueKey('rating_star_$starNumber'),
          borderRadius: BorderRadius.circular(20),
          onTap: onRatingChanged != null ? () => onRatingChanged!(starNumber) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : AppColors.cardBorder,
              size: iconSize,
            ),
          ),
        );
      }),
    );
  }
}
