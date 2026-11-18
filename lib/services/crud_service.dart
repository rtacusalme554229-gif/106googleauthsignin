
import 'package:cloud_firestore/cloud_firestore.dart';

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  // CREATE
  Future<void> addItem(String name, int quantity) async {
    await items.add({
      'name': name,
      'quantity': quantity,
      'isFavorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  // READ
  Stream<QuerySnapshot> getItems() {
    return items
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // UPDATE
  Future<void> updateItem(
    String id,
    String name,
    int quantity,
  ) async {
    await items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  // FAVORITE
  Future<void> toggleFavorite(
    String id,
    bool isFavorite,
  ) async {
    await items.doc(id).update({
      'isFavorite': !isFavorite,
    });
  }

  // DELETE
  Future<void> deleteItem(String id) async {
    await items.doc(id).delete();
  }
}
