import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_storage_constants.dart';
import 'package:flutter/material.dart';

@immutable
class CloudGarment {
  final String documentId;
  final String ownerUserId;
  final String text;

  const CloudGarment({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
  });

  CloudGarment.fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName],
        text = snapshot.data()[textFieldName] as String;
}
