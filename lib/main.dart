import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:prototipo_mapa/pages/mapa_page.dart';
import 'package:prototipo_mapa/pages/rota_page.dart';

import 'controllers/entregas_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(EntregasController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Carregamentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.light,
      home: RotaPage()//MapaPage()//EntregasPage(),
    );
  }
}
