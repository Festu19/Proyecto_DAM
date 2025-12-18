// lib/screens/members_screen.dart

// lib/screens/members_screen.dart

import 'package:casazenn/models/reward_model.dart';
import 'package:casazenn/models/user_model.dart';
import 'package:casazenn/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha del historial

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUserData(currentUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final userModel = userSnapshot.data!;
        final homeId = userModel.homeId;
        if (homeId == null) return const Center(child: Text("Error"));

        return Scaffold(
          appBar: AppBar(
            title: const Text("Mi Casa"),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Ranking", icon: Icon(Icons.leaderboard)),
                Tab(text: "Tienda", icon: Icon(Icons.storefront)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // PESTAÑA 1: RANKING + HISTORIAL
              Column(
                children: [
                  // Parte superior: El Ranking (ocupa el espacio disponible)
                  Expanded(flex: 3, child: _buildMembersList(homeId)),
                  
                  const Divider(thickness: 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("📜 Historial de Actividad", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  
                  // Parte inferior: Historial (ocupa menos espacio)
                  Expanded(flex: 2, child: _buildHistoryList(homeId)),
                ],
              ),
              
              // PESTAÑA 2: TIENDA
              _buildRewardsShop(homeId, userModel),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comparte el código desde la Home para invitar.")));
              } else {
                 _showAddRewardDialog(context, homeId);
              }
            },
            child: Icon(_tabController.index == 0 ? Icons.person_add : Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildMembersList(String homeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getHomeMembersStream(homeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final members = snapshot.data!.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        members.sort((a, b) => b.points.compareTo(a.points)); 

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final bool isCurrentUser = member.uid == currentUserId;
            
            Widget? trophy;
            if (index == 0) trophy = const Icon(Icons.emoji_events, color: Colors.amber);
            else if (index == 1) trophy = const Icon(Icons.emoji_events, color: Colors.grey);
            else if (index == 2) trophy = const Icon(Icons.emoji_events, color: Colors.brown);

            return Card(
              elevation: isCurrentUser ? 4 : 1,
              color: isCurrentUser ? Colors.green.shade50 : null,
              child: ListTile(
                leading: CircleAvatar(child: Text(member.name.substring(0, 1).toUpperCase())),
                title: Text(member.name + (isCurrentUser ? " (Tú)" : ""), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${member.points} Puntos"),
                trailing: trophy,
              ),
            );
          },
        );
      },
    );
  }

  // --- NUEVO WIDGET: HISTORIAL ---
 Widget _buildHistoryList(String homeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getHistoryStream(homeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No hay pedidos pendientes.", style: TextStyle(color: Colors.grey)));
        }

        final historyDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: historyDocs.length,
          itemBuilder: (context, index) {
            final doc = historyDocs[index]; // Necesitamos el doc para su ID
            final data = doc.data() as Map<String, dynamic>;
            final text = data['text'] ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final dateStr = timestamp != null 
                ? DateFormat('dd/MM HH:mm').format(timestamp.toDate()) 
                : '';

            return Card(
              color: Colors.grey.shade50,
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell( // <--- Añadimos InkWell para detectar pulsaciones
                onLongPress: () {
                  // Mostrar diálogo de confirmación
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("¿Marcar como cumplido?"),
                      content: const Text("Esto eliminará el registro del historial. Úsalo cuando la recompensa se haya entregado en la vida real."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                        ElevatedButton(
                          onPressed: () {
                            _firestoreService.deleteHistoryItem(homeId, doc.id);
                            Navigator.pop(ctx);
                          },
                          child: const Text("Eliminar"),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modificado: Ahora pasamos el objeto user completo para tener el nombre
  Widget _buildRewardsShop(String homeId, UserModel currentUser) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Tus puntos disponibles: ${currentUser.points}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getRewardsStream(homeId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("La tienda está vacía.\n¡Añade recompensas con el botón +!", textAlign: TextAlign.center));
              }

              final rewards = snapshot.data!.docs.map((doc) => RewardModel.fromFirestore(doc)).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 10, 
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  final canAfford = currentUser.points >= reward.cost;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onLongPress: () => _firestoreService.deleteReward(homeId, reward.id),
                      onTap: () => _confirmPurchase(context, reward, currentUser, homeId),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getIconData(reward.icon), size: 40, color: canAfford ? Colors.orange : Colors.grey),
                          const SizedBox(height: 10),
                          Text(reward.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("${reward.cost} pts", style: TextStyle(color: canAfford ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'fastfood': return Icons.fastfood;
      case 'movie': return Icons.movie;
      case 'bed': return Icons.bed;
      case 'videogame_asset': return Icons.videogame_asset;
      case 'local_pizza': return Icons.local_pizza;
      case 'icecream': return Icons.icecream;
      default: return Icons.card_giftcard;
    }
  }

  // --- DIÁLOGOS ---

  void _showAddRewardDialog(BuildContext context, String homeId) {
    final titleController = TextEditingController();
    final costController = TextEditingController();
    String selectedIcon = 'fastfood'; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Nueva Recompensa"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Título (ej: Pizza)")),
                  TextField(controller: costController, decoration: const InputDecoration(labelText: "Coste (Puntos)"), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text("Elige un icono:"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 15,
                    children: [
                      _buildIconSelector('fastfood', selectedIcon, setStateDialog, (val) => selectedIcon = val),
                      _buildIconSelector('local_pizza', selectedIcon, setStateDialog, (val) => selectedIcon = val),
                      _buildIconSelector('movie', selectedIcon, setStateDialog, (val) => selectedIcon = val),
                      _buildIconSelector('videogame_asset', selectedIcon, setStateDialog, (val) => selectedIcon = val),
                      _buildIconSelector('bed', selectedIcon, setStateDialog, (val) => selectedIcon = val),
                      _buildIconSelector('icecream', selectedIcon, setStateDialog, (val) => selectedIcon = val),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () {
                  final cost = int.tryParse(costController.text) ?? 0;
                  if (titleController.text.isNotEmpty && cost > 0) {
                    _firestoreService.addReward(homeId, titleController.text, cost, selectedIcon);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Crear"),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildIconSelector(String iconName, String currentSelection, Function setStateDialog, Function(String) onSelect) {
    final isSelected = iconName == currentSelection;
    return GestureDetector(
      onTap: () {
        setStateDialog(() {
          onSelect(iconName);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.green) : null,
        ),
        child: Icon(_getIconData(iconName), color: isSelected ? Colors.green : Colors.grey),
      ),
    );
  }
  
  // Lógica de compra ACTUALIZADA
  void _confirmPurchase(BuildContext context, RewardModel reward, UserModel user, String homeId) {
    if (user.points < reward.cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No tienes suficientes puntos :(")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Canjear ${reward.title}?"),
        content: Text("Se te descontarán ${reward.cost} puntos."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // AQUÍ LLAMAMOS AL NUEVO MÉTODO CON TODOS LOS DATOS
              bool success = await _firestoreService.redeemReward(
                user.uid, 
                homeId, 
                user.name, 
                reward.title, 
                reward.cost
              );

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Disfruta tu ${reward.title}! 🎉")));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al canjear.")));
              }
            },
            child: const Text("¡LO QUIERO!"),
          ),
        ],
      ),
    );
  }
}