import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  static const String cloudName = 'dj0tz1vxm';
  static const String uploadPreset = 'unsigned_flowlink';
  static const String folder = 'finolex/products';

  Future<String?> uploadImage(XFile file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData;
      if (kIsWeb) {
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: fileName,
          ),
          'upload_preset': uploadPreset,
          'folder': folder,
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
          'upload_preset': uploadPreset,
          'folder': folder,
        });
      }

      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      } else {
        print('Cloudinary Upload Error: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Upload Exception: $e');
      return null;
    }
  }
}
