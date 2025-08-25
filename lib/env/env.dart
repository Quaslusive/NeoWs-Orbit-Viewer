import 'package:envied/envied.dart';

part 'env.g.dart';
// @Envied(path: '.env', obfuscate: true)
@Envied(path: '.env') // or just '.env'
abstract class Env {
  @EnviedField(varName: 'NASA_API_KEY')
  static const String nasaApiKey = _Env.nasaApiKey;
}
