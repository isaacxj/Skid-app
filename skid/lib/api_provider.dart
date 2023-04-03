import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String apiKey = 'AIzaSyDsrdxHDGObMKB9WcdkxeZxaft2t0DEgkw';

  Future<List<dynamic>> searchPlaces(String searchTerm) async {
    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$searchTerm&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'];
    } else {
      throw Exception('Failed to fetch search results');
    }
  }
}
