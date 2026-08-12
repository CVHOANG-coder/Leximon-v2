import 'dart:convert';

import 'package:flutter/services.dart';

class GrammarAssetDataSource {
  GrammarAssetDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const contentVersion = 5;
  static const entries = <GrammarAssetEntry>[
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/bcqp0001.json',
      iconAsset: 'assets/images/grammar/beginner_pack1.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/bcqp0002.json',
      iconAsset: 'assets/images/grammar/beginner_pack2.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/ecqp0001.json',
      iconAsset: 'assets/images/grammar/Elementary_pack1.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/ecqp0002.json',
      iconAsset: 'assets/images/grammar/Elementary_pack2.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/ecqp0003.json',
      iconAsset: 'assets/images/grammar/Elementary_pack3.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/icqp0001.json',
      iconAsset: 'assets/images/grammar/intermediate_pack1.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/icqp0002.json',
      iconAsset: 'assets/images/grammar/intermediate_pack2.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/acqp0001.json',
      iconAsset: 'assets/images/grammar/advanced_pack1.png',
    ),
    GrammarAssetEntry(
      jsonAsset: 'assets/data/grammar/allpack/acqp0002.json',
      iconAsset: 'assets/images/grammar/advanced_pack2.png',
    ),
  ];

  final AssetBundle _bundle;

  Future<List<GrammarAssetPack>> loadAll() {
    return Future.wait([
      for (var index = 0; index < entries.length; index++)
        _load(entries[index], index),
    ]);
  }

  Future<GrammarAssetPack> _load(GrammarAssetEntry entry, int order) async {
    final raw = await _bundle.loadString(entry.jsonAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return GrammarAssetPack(
      guid: json['guid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      level: json['level'] as String? ?? '',
      iconAsset: entry.iconAsset,
      sortOrder: order,
      topics: (json['topics'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GrammarAssetTopic.new)
          .toList(growable: false),
    );
  }
}

class GrammarAssetEntry {
  const GrammarAssetEntry({required this.jsonAsset, required this.iconAsset});

  final String jsonAsset;
  final String iconAsset;
}

class GrammarAssetPack {
  const GrammarAssetPack({
    required this.guid,
    required this.title,
    required this.description,
    required this.level,
    required this.iconAsset,
    required this.sortOrder,
    required this.topics,
  });

  final String guid;
  final String title;
  final String description;
  final String level;
  final String iconAsset;
  final int sortOrder;
  final List<GrammarAssetTopic> topics;
}

class GrammarAssetTopic {
  GrammarAssetTopic(Map<String, dynamic> json)
    : title = (json['label'] ?? json['title']) as String? ?? '',
      description = json['description'] as String? ?? '',
      instructions = json['instructions'] ?? const <dynamic>[],
      questions =
          ((json['payload'] as Map<String, dynamic>?)?['questions']
                      as List<dynamic>? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);

  final String title;
  final String description;
  final Object instructions;
  final List<Map<String, dynamic>> questions;
}
