
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/crud_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final AuthService authService = AuthService();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  bool favoritesOnly = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ADD ITEM
  void openAddDialog() {
    nameCtrl.clear();
    qtyCtrl.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim());

              if (name.isEmpty || quantity == null || quantity < 0) {
                showMessage('Enter a valid name and quantity.');
                return;
              }

              Navigator.pop(dialogContext);

              try {
                await service.addItem(name, quantity);
                showMessage('Item added successfully!');
              } catch (e) {
                showMessage('Error adding item: $e');
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // EDIT ITEM
  void openEditDialog(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;

    nameCtrl.text = data['name']?.toString() ?? '';
    qtyCtrl.text = data['quantity']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim());

              if (name.isEmpty || quantity == null || quantity < 0) {
                showMessage('Enter a valid name and quantity.');
                return;
              }

              Navigator.pop(dialogContext);

              try {
                await service.updateItem(
                  item.id,
                  name,
                  quantity,
                );
                showMessage('Item updated successfully!');
              } catch (e) {
                showMessage('Error updating item: $e');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // DELETE ITEM
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item'),
        content: const Text(
          'Are you sure you want to delete this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await service.deleteItem(id);
                showMessage('Item deleted successfully!');
              } catch (e) {
                showMessage('Error deleting item: $e');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // FAVORITE ITEM
  Future<void> toggleFavorite(
    DocumentSnapshot item,
    bool currentFavorite,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(item.id)
          .update({
        'isFavorite': !currentFavorite,
      });
    } catch (e) {
      showMessage('Error updating favorite: $e');
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await authService.logout();
    } catch (e) {
      showMessage('Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Tacusalme, Renan Angelo'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          // FAVORITE FILTER
          IconButton(
            tooltip: favoritesOnly
                ? 'Show all items'
                : 'Show favorites only',
            icon: Icon(
              favoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                favoritesOnly = !favoritesOnly;
              });
            },
          ),

          // LOGOUT BUTTON
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: logout,
          ),
        ],
      ),

      // ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: openAddDialog,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      // FIRESTORE REAL-TIME ITEMS
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          final filteredDocs = favoritesOnly
              ? docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;
                  return data['isFavorite'] == true;
                }).toList()
              : docs;

          if (filteredDocs.isEmpty) {
            return Center(
              child: Text(
                favoritesOnly
                    ? 'No favorite items found'
                    : 'No items found',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final item = filteredDocs[index];
              final data =
                  item.data() as Map<String, dynamic>;

              final name =
                  data['name']?.toString() ?? 'Unnamed item';

              final quantity = data['quantity'] ?? 0;

              final isFavorite =
                  data['isFavorite'] == true;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 6,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Quantity $quantity',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FAVORITE BUTTON
                      IconButton(
                        tooltip: 'Favorite',
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.pink,
                        ),
                        onPressed: () {
                          toggleFavorite(item, isFavorite);
                        },
                      ),

                      // EDIT BUTTON
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          openEditDialog(item);
                        },
                      ),

                      // DELETE BUTTON
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          confirmDelete(item.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
