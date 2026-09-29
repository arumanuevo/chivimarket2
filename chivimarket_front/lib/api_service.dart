import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL a tu servidor Wiroos (cambiar aquí si luego es otro dominio)
  static const String baseUrl = 'https://chivimarket.arumasoft.com/api';

  // Obtener el token guardado localmente
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Guardar el token (Llamado después del login)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Eliminar token (Logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Método Genérico GET
  static Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // Método Genérico POST
  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // Método Genérico PATCH
  static Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final token = await getToken();
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // Método MULTIPART para Fotos
  static Future<http.StreamedResponse> postMultipart(String endpoint, Map<String, String> fields, List<http.MultipartFile> files) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    
    // Configurar Cabeceras
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    // Agregar variables de texto si existen
    request.fields.addAll(fields);

    // Agregar las fotos
    request.files.addAll(files);

    return await request.send();
  }
}
