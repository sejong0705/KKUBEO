import 'dart:convert';
import 'package:http/http.dart' as http;

const apiKey = String.fromEnvironment('OPENAI_API_KEY'); // ← dart-define으로 주입

Future<String> sendMessageToGPT(String userMessage) async {
  final endpoint = "https://api.openai.com/v1/chat/completions";

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": userMessage},
      ]
    }),
  );

  if (response.statusCode == 200) {
    final decoded = utf8.decode(response.bodyBytes); // 한글 깨짐 방지
    final data = jsonDecode(decoded);
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception("GPT 호출 실패: ${response.body}");
  }

}
