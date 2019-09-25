
import 'dart:io';
import 'package:dio/dio.dart';

main() async {

  var dio = new Dio();
  FormData formData = new FormData.from({
    "file": new UploadFileInfo(new File("/Users/xiaominfc/Pictures/origin_1.png"), "origin_1.png")
  });
  var response = await dio.post("http://msfs.xiaominfc.com/", data: formData);

  
  print(response.data);
  
}
