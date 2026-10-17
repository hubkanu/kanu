import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/member.dart';

/// Avatar d'un membre : photo distante si disponible, initiales sinon.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 52,
    this.showPremiumRing = true,
  });

  final Member member;
  final double size;
  final bool showPremiumRing;

  @override
  Widget build(BuildContext context) {
    final String? url = member.resolvedPhotoUrl;
    final bool premium = showPremiumRing && member.isPremium;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: premium ? AppColors.gold : AppColors.border,
          width: premium ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? _initials(context)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => _initials(context),
              errorWidget: (_, _, _) => _initials(context),
            ),
    );
  }

  Widget _initials(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, AppColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: size * 0.36,
          color: AppColors.silver,
        ),
      ),
    );
  }
}
