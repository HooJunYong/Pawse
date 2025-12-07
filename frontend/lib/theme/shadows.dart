import 'package:flutter/material.dart';

/// Shared shadows used across auth and therapist screens for consistent depth.
const List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
];

const List<BoxShadow> kPillShadow = [
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];

const List<BoxShadow> kButtonShadow = [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 20,
    offset: Offset(0, 10),
  ),
];
