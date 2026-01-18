import 'package:flutter/material.dart';

/// Represents a law enforcement agency in Putnam County
class Agency {
  const Agency({
    required this.id,
    required this.name,
    required this.shortName,
    required this.icon,
    required this.description,
  });

  final String id; // Unique identifier for filtering
  final String name; // Full display name
  final String shortName; // Abbreviated name for headers
  final IconData icon;
  final String description;

  /// List of all agencies in Putnam County
  static const List<Agency> all = <Agency>[
    Agency(
      id: 'pcso',
      name: 'PUTNAM COUNTY SHERIFF\'S OFFICE',
      shortName: 'PCSO',
      icon: Icons.local_police,
      description: 'Primary law enforcement agency for Putnam County',
    ),
    Agency(
      id: 'palatka_pd',
      name: 'PALATKA POLICE DEPARTMENT',
      shortName: 'PALATKA PD',
      icon: Icons.shield,
      description: 'City of Palatka law enforcement',
    ),
    Agency(
      id: 'interlachen_pd',
      name: 'INTERLACHEN POLICE DEPARTMENT',
      shortName: 'INTERLACHEN PD',
      icon: Icons.shield,
      description: 'Town of Interlachen law enforcement',
    ),
    Agency(
      id: 'welaka_pd',
      name: 'WELAKA POLICE DEPARTMENT',
      shortName: 'WELAKA PD',
      icon: Icons.shield,
      description: 'Town of Welaka law enforcement',
    ),
    Agency(
      id: 'school_pd',
      name: 'PUTNAM COUNTY SCHOOL DISTRICT POLICE DEPARTMENT',
      shortName: 'SCHOOL PD',
      icon: Icons.shield,
      description: 'Putnam County School District law enforcement',
    ),
    Agency(
      id: 'fhp',
      name: 'FLORIDA HIGHWAY PATROL',
      shortName: 'FHP',
      icon: Icons.shield,
      description: 'State highway patrol operating in Putnam County',
    ),
    Agency(
      id: 'fwc',
      name: 'FLORIDA FISH AND WILDLIFE CONSERVATION COMMISSION (FWC)',
      shortName: 'FWC',
      icon: Icons.shield,
      description: 'Florida wildlife law enforcement',
    ),
  ];

  /// Find agency by ID
  static Agency? findById(String id) {
    try {
      return all.firstWhere((agency) => agency.id == id);
    } catch (e) {
      return null;
    }
  }
}

