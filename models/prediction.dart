import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class Prediction {
  String uuid;
  String unrestrictedValue;
  String value;
  String pointType;
  String country;
  String region;
  String regionType;
  String city;
  String cityType;
  String street;
  String streetType;
  String streetWithType;
  String house;
  bool outOfTown;
  String houseType;
  int accuracyLevel;
  int radius;
  double lat;
  double lon;
  String type;

  StructuredFormatting structuredFormatting;

  Prediction({
    this.uuid,
    this.unrestrictedValue,
    this.value,
    this.pointType,
    this.country,
    this.region,
    this.regionType,
    this.city,
    this.cityType,
    this.street,
    this.streetType,
    this.streetWithType,
    this.house,
    this.outOfTown,
    this.houseType,
    this.accuracyLevel,
    this.radius,
    this.lat,
    this.lon,
    this.structuredFormatting,
    this.type,
  });

  Prediction copyWith(
    String uuid,
    String unrestrictedValue,
    String value,
    String pointType,
    String country,
    String region,
    String regionType,
    String city,
    String cityType,
    String street,
    String streetType,
    String streetWithType,
    String house,
    bool outOfTown,
    String houseType,
    int accuracyLevel,
    int radius,
    double lat,
    double lon,
    String type,
  ) {
    return Prediction(
        uuid: uuid ?? this.uuid,
        unrestrictedValue: unrestrictedValue ?? this.unrestrictedValue,
        value: value ?? this.value,
        pointType: pointType ?? this.pointType,
        country: country ?? this.country,
        region: region ?? this.region,
        regionType: regionType ?? this.regionType,
        city: city ?? this.city,
        cityType: cityType ?? this.cityType,
        street: street ?? this.street,
        streetType: streetType ?? this.streetType,
        streetWithType: streetWithType ?? this.streetWithType,
        house: house ?? this.house,
        outOfTown: outOfTown ?? this.outOfTown,
        houseType: houseType ?? this.houseType,
        accuracyLevel: accuracyLevel ?? this.accuracyLevel,
        radius: radius ?? this.radius,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        type: type ?? this.type,
    );
  }

  Prediction.fromJson(Map<String, dynamic> json) {
    pointType = json['point_type'];
    uuid = json['uuid'];
    unrestrictedValue = json['unrestricted_value'];
    value = json['value'];
    country = json['country'];
    region = json['region'];
    regionType = json['region_type'];
    city = json['city'];
    cityType = json['city_type'];
    street = json['street'];
    streetType = json['street_type'];
    streetWithType = json['street_with_type'];
    house = json['house'];
    outOfTown = json['out_of_town'];
    houseType = json['house_type'];
    accuracyLevel = json['accuracy_level'];
    radius = json['radius'];
    lat = json['lat'];
    lon = json['lon'];
    type = json['type'] == null ? null : json['type'];

    structuredFormatting = StructuredFormatting(this);
    print('uuid: $uuid');
  }

  Map<String, dynamic> toJson() => {
        'pointType': pointType,
        'uuid': uuid,
        'unrestrictedValue': unrestrictedValue,
        'value': value,
        'country': country,
        'region': region,
        'regionType': regionType,
        'city': city,
        'cityType': cityType,
        'street': street,
        'streetType': streetType,
        'streetWithType': streetWithType,
        'house': house,
        'outOfTown': outOfTown,
        'houseType': houseType,
        'accuracyLevel': accuracyLevel,
        'radius': radius,
        'lat': lat,
        'lon': lon,
        'type': type,
      };

  @override
  String toString() {
    return '{uuid: $uuid, unrestrictedValue: $unrestrictedValue, value: $value, pointType: $pointType, country: $country, region: $region, regionType: $regionType, city: $city, cityType: $cityType, street: $street, streetType: $streetType, streetWithType: $streetWithType, house: $house, outOfTown: $outOfTown, houseType: $houseType, accuracyLevel: $accuracyLevel, radius: $radius, lat: $lat, lon: $lon, type: $type}';
  }
}

class PlacesAutocompleteResponse {
  List<Prediction> _predictions;
  int _statusCode;

  List<Prediction> get predictions {
    if (_predictions == null) return null;
    return [..._predictions];
  }

  int get statusCode {
    return _statusCode;
  }

  getPredictions(String text) async {
    final url = 'https://crm.apis.stage.faem.pro/api/v2/addresses';
    Dio dio = Dio();
    try {
      final response = await dio.post(url, queryParameters: {'Content-Type': 'application/json'}, data: {'name': '$text'});
      _statusCode = response.statusCode;

      final List decodePredictions = response.data;
      if (decodePredictions == null) {
        return;
      }

      _predictions = decodePredictions.where((element) => element['point_type'] != 'city').map((item) {
        return Prediction.fromJson(item);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

class StructuredFormatting {
  static String _getMainText(Prediction pred) {
    String mainText = pred.street.isNotEmpty ? 'Ул. ${pred.street}' : '';
    if (pred.house.isNotEmpty) mainText += mainText.isNotEmpty ? ', ${pred.house}' : pred.house;
    return mainText;
  }

  static String _getSecondaryText(Prediction pred) {
    String mainText = pred.city.isNotEmpty ? pred.city : '';
    if (pred.region.isNotEmpty) mainText += mainText.isNotEmpty ? ', ${pred.region}' : pred.region;
    if (pred.country.isNotEmpty) mainText += mainText.isNotEmpty ? ', ${pred.country}' : pred.country;
    return mainText;
  }

  String mainText;

  String secondaryText;

  StructuredFormatting(Prediction prediction)
      : mainText = _getMainText(prediction),
        secondaryText = _getSecondaryText(prediction);
}
