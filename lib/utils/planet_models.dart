import 'package:flutter/material.dart';

class Planet {
  final String name;
  final double a; // semi-major axis (AU)
  final double e; // eccentricity
  final double i; // inclination (deg)
  final double omega; // argument of periapsis ω (deg)
  final double Omega; // longitude of ascending node Ω (deg)
  final double M0deg; // mean anomaly at epoch (deg)
  final DateTime epoch; // epoch of elements
  final Color color;
  final double radiusPx; // draw size on screen

  const Planet({
    required this.name,
    required this.a,
    required this.e,
    required this.i,
    required this.omega,
    required this.Omega,
    required this.M0deg,
    required this.epoch,
    required this.color,
    required this.radiusPx,
  });
}

/// Approximate J2000 elements (good enough for visualization)
final DateTime _j2000 = DateTime.utc(2000, 1, 1, 12);

const _mercury = Color(0xFF9E9E9E);
const _venus = Color(0xFFEED6A3);
const _earth = Color(0xFF66CCFF);
const _mars = Color(0xFFE07A5F);
const _jupiter = Color(0xFFDAB07E);
const _saturn = Color(0xFFF3E2A9);
const _uranus = Color(0xFF6AD2C9);
const _neptune = Color(0xFF5CA2F1);

final List<Planet> innerPlanets = [
  Planet(
    name: 'Mercury',
    a: 0.38709893,
    e: 0.20563069,
    i: 7.00487,
    omega: 29.12478,
    Omega: 48.33167,
    M0deg: 174.79588,
    epoch: _j2000,
    color: _mercury,
    radiusPx: 3.0,
  ),
  Planet(
    name: 'Venus',
    a: 0.72333199,
    e: 0.00677323,
    i: 3.39471,
    omega: 54.85229,
    Omega: 76.68069,
    M0deg: 50.115,
    // ~
    epoch: _j2000,
    color: _venus,
    radiusPx: 4.0,
  ),
  Planet(
    name: 'Earth',
    a: 1.00000011,
    e: 0.01671022,
    i: 0.00005,
    omega: 102.94719,
    Omega: 0.0,
    M0deg: 357.517,
    // ~
    epoch: _j2000,
    color: _earth,
    radiusPx: 4.0,
  ),
  Planet(
    name: 'Mars',
    a: 1.52366231,
    e: 0.09341233,
    i: 1.85061,
    omega: 286.46230,
    Omega: 49.57854,
    M0deg: 19.41248,
    epoch: _j2000,
    color: _mars,
    radiusPx: 3.5,
  ),
  Planet(
    name: 'Jupiter',
    a: 5.20260,
    e: 0.048498,
    i: 1.303,
    omega: 273.867,
    Omega: 100.492,
    M0deg: 19.8950,
    epoch: _j2000,
    color: _jupiter,
    radiusPx: 5.0,
  ),
  Planet(
    name: 'Saturn',
    a: 9.5549,
    e: 0.055508,
    i: 2.489,
    omega: 339.392,
    Omega: 113.642,
    M0deg: 317.0207,
    epoch: _j2000,
    color: _saturn,
    radiusPx: 5.0,
  ),
  Planet(
    name: 'Uranus',
    a: 19.2184,
    e: 0.046295,
    i: 0.773,
    omega: 96.998857,
    Omega: 74.016,
    M0deg: 142.2386,
    epoch: _j2000,
    color: _uranus,
    radiusPx: 4.5,
  ),
  Planet(
    name: 'Neptune',
    a: 30.1104,
    e: 0.008988,
    i: 1.770,
    omega: 276.336,
    Omega: 131.784,
    M0deg: 256.228,
    epoch: _j2000,
    color: _neptune,
    radiusPx: 4.5,
  ),
];
