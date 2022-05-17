import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:prototipo_mapa/constants/app_constant.dart';

import '../models/carregamento_model.dart';
import '../models/mapa_model.dart';
import '../utils/http_service.dart';

class EntregasController extends GetxController {
  final _http = HttpService();

  static EntregasController instance = Get.find();

  Future<List<MapaModel>> obterRota(String origem, String destino) async {

    List<MapaModel> mapa = [];
    Response response;

    try {
      response = await _http.getRequest("${AppConstant.URL_MAPS}/origin=$origem&destination=$destino&key=${AppConstant.API_KEY}");
      if(response.statusCode == 200){
        final List<MapaModel> mapaData = response.data
            .map((json) => MapaModel.fromJson(json))
            .toList()
            .cast<MapaModel>();

        mapa = mapaData;
      }
    } catch (e) {
    }

    return mapa;
  }

  Future<List<CarregamentoModel>> obterCarregamento(String id) async {

    List<CarregamentoModel> carregamentos = [];
    Response response;

    try {
      response = await _http.getRequest("${AppConstant.URL}/$id");
      if(response.statusCode == 200){
        var carregamentoData = response.data["entregas"]
            .map((json) => CarregamentoModel.fromJson(json))
            .toList()
            .cast<CarregamentoModel>();

        carregamentos = carregamentoData;
      }
    } catch (e) {
      print(e.toString());
    }

    return carregamentos;
  }


}
