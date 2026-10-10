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
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Accept-Language': 'es-ES,es;q=0.9',
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
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Accept-Language': 'es-ES,es;q=0.9',
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
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Accept-Language': 'es-ES,es;q=0.9',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }
  
  static Future<http.Response> delete(String endpoint) async {
    final token = await getToken();
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Accept-Language': 'es-ES,es;q=0.9',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // Método MULTIPART para Fotos
  static Future<http.StreamedResponse> postMultipart(String endpoint, Map<String, String> fields, List<http.MultipartFile> files) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    
    // Configurar Cabeceras
    request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        'Accept-Language': 'es-ES,es;q=0.9',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    // Agregar variables de texto si existen
    request.fields.addAll(fields);

    // Agregar las fotos
    request.files.addAll(files);

    return await request.send();
  }
}
