class Asteroid {
  final String name;
  final double estimatedDiameter;
  final bool isHazardous;
  final String nasaJplUrl;
  final String asteroidDate;
  final double asteroidDistance;
  final double absoluteMagnitude;
  final double relativeVelocity;


  Asteroid({
    required this.name,
    required this.estimatedDiameter,
    required this.isHazardous,
    required this.nasaJplUrl,
    required this.asteroidDate,
    required this.asteroidDistance,
    required this.absoluteMagnitude,
    required this.relativeVelocity,

  });

  factory Asteroid.fromJson(Map<String, dynamic> json) {

    final closeApproachData = json['close_approach_data']
        != null && json['close_approach_data'].isNotEmpty
        ? json['close_approach_data'][0]
        : null;

    return Asteroid(
      name: json['name'],
      estimatedDiameter: json['estimated_diameter']['kilometers']['estimated_diameter_max'],
      isHazardous: json['is_potentially_hazardous_asteroid'],
      nasaJplUrl: json['nasa_jpl_url'],
      asteroidDate: closeApproachData != null ? closeApproachData['close_approach_date'] : 'Okänd datum ',
      asteroidDistance: closeApproachData != null
          ? double.parse(closeApproachData['miss_distance']['kilometers'])
          : 0.0,
      absoluteMagnitude: json['absolute_magnitude_h'],
      relativeVelocity: closeApproachData != null
          ? double.parse(closeApproachData['relative_velocity']['kilometers_per_hour'])
          : 0.0,
    );
  }
}
