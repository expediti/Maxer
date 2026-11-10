import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Reusable Organization Logo widget with local SVG asset pipeline
/// and graceful, high-contrast fallback container.
class OrganisationLogo extends StatelessWidget {
  final String? organisationId;
  final String? slug;
  final String? shortName;
  final String? name;
  final double size;
  final double borderRadius;

  const OrganisationLogo({
    super.key,
    this.organisationId,
    this.slug,
    this.shortName,
    this.name,
    this.size = 40.0,
    this.borderRadius = 10.0,
  });

  static const Map<String, String> _idMap = {
    'a0000000-0000-0000-0000-000000000001': 'assets/organisation_logos/upsc.svg',
    'a0000000-0000-0000-0000-000000000002': 'assets/organisation_logos/isro.svg',
    'a0000000-0000-0000-0000-000000000003': 'assets/organisation_logos/drdo.svg',
    'a0000000-0000-0000-0000-000000000004': 'assets/organisation_logos/sbi.svg',
    'a0000000-0000-0000-0000-000000000005': 'assets/organisation_logos/pmrf.svg',
    'a0000000-0000-0000-0000-000000000006': 'assets/organisation_logos/iocl.svg',
  };

  static const Map<String, List<String>> _aliasMap = {
    'assets/organisation_logos/upsc.svg': ['upsc', 'union public service', 'civil services'],
    'assets/organisation_logos/isro.svg': ['isro', 'space research', 'scientist/engineer'],
    'assets/organisation_logos/drdo.svg': ['drdo', 'defence research', 'rac advt'],
    'assets/organisation_logos/sbi.svg': ['sbi', 'state bank of india', 'state bank'],
    'assets/organisation_logos/pmrf.svg': ['pmrf', 'prime minister', 'research fellowship'],
    'assets/organisation_logos/iocl.svg': ['iocl', 'indian oil'],
    'assets/organisation_logos/ssc.svg': ['ssc', 'staff selection'],
    'assets/organisation_logos/ibps.svg': ['ibps', 'banking personnel'],
    'assets/organisation_logos/rrb.svg': ['rrb', 'railway recruitment'],
    'assets/organisation_logos/nta.svg': ['nta', 'national testing agency'],
  };

  String? _resolveAssetPath() {
    if (organisationId != null && _idMap.containsKey(organisationId)) {
      return _idMap[organisationId];
    }

    final combined = '${slug ?? ''} ${shortName ?? ''} ${name ?? ''}'.toLowerCase();
    for (final entry in _aliasMap.entries) {
      for (final alias in entry.value) {
        if (combined.contains(alias)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  String _getInitials() {
    if (shortName != null && shortName!.trim().isNotEmpty) {
      return shortName!.trim().toUpperCase();
    }
    if (name != null && name!.trim().isNotEmpty) {
      final parts = name!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, parts[0].length >= 3 ? 3 : parts[0].length).toUpperCase();
    }
    return 'RX';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _resolveAssetPath();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath != null
          ? Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => _buildFallback(),
              ),
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final initials = _getInitials();
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

