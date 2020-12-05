import 'dart:convert';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

Future<String> _loadAsset() async {
  return await rootBundle.loadString('assets/data/arancel.json');
}

Future<Map> loadData() async{
  String jsonData = await _loadAsset();
  return jsonDecode(jsonData);
}