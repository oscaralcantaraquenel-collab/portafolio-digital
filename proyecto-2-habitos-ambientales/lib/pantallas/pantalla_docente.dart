import 'dart:math';
import 'dart:convert'; // <--- Importamos para la foto Base64
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pantalla_login.dart';
import 'detalle_clase_docente.dart';
import 'pantalla_perfil_docente.dart';

class PantallaDocente extends StatefulWidget {
  final Map<String, dynamic> usuarioLogueado;

  const PantallaDocente({super.key, required this.usuarioLogueado});

  @override
  State<PantallaDocente> createState() => _PantallaDocenteState();
}

class _PantallaDocenteState extends State<PantallaDocente> {
  final user = FirebaseAuth.instance.currentUser;

  // Variable de estado para actualizar el perfil al instante
  late Map<String, dynamic> _usuarioActualDocente;

  @override
  void initState() {
    super.initState();
    // Inicializamos con los datos que vienen del Login
    _usuarioActualDocente = Map<String, dynamic>.from(widget.usuarioLogueado);
  }

  // --- FUNCIÓN: Crear clase con código aleatorio ---
  void _mostrarDialogoCrearClase() {
    final nombreClaseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Crear Nueva Clase', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nombreClaseController,
          decoration: InputDecoration(
            labelText: 'Nombre de la materia/grupo',
            hintText: 'Ej. Ecología 101',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              if (nombreClaseController.text.isNotEmpty && user != null) {
                // Generamos un código único de 4 dígitos
                String codigoUnico = 'VERDE-${Random().nextInt(9000) + 1000}';

                await FirebaseFirestore.instance.collection('clases').add({
                  'nombre_clase': nombreClaseController.text.trim(),
                  'codigo': codigoUnico,
                  'docente_id': user!.uid,
                  'docente_nombre': _usuarioActualDocente['name'],
                  'fecha_creacion': FieldValue.serverTimestamp(),
                });

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clase creada con éxito'), backgroundColor: Colors.green)
                );
              }
            },
            child: const Text('Crear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Función para cerrar sesión de forma segura
  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaLogin()));
  }

  @override
  Widget build(BuildContext context) {
    Color colorDocente = Colors.green.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Fondo moderno
      appBar: AppBar(
        title: const Text('Panel de Docente', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorDocente,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // --- DRAWER ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: colorDocente),
              accountName: Text(
                _usuarioActualDocente['name'] ?? 'Docente',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text('Modo Profesor Administrador'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.green.shade100,
                  // Lógica Base64 para la foto
                  backgroundImage: (_usuarioActualDocente['foto_base64'] != null && _usuarioActualDocente['foto_base64'].toString().isNotEmpty)
                      ? MemoryImage(base64Decode(_usuarioActualDocente['foto_base64']))
                      : null,
                  child: (_usuarioActualDocente['foto_base64'] == null || _usuarioActualDocente['foto_base64'].toString().isEmpty)
                      ? Icon(Icons.school, color: colorDocente, size: 40)
                      : null,
                ),
              ),
            ),

            // Opciones del menú
            _crearElementoMenu(Icons.class_outlined, 'Mis Clases', () => Navigator.pop(context), colorDocente, true),
            const Divider(),

            // Acceso al perfil del Docente
            _crearElementoMenu(Icons.account_circle_outlined, 'Mi Perfil Prof.', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaPerfilDocente(
                usuario: _usuarioActualDocente,
                onPerfilActualizado: (datosActualizados) {
                  setState(() => _usuarioActualDocente = datosActualizados);
                },
              )));
            }, colorDocente, false),

            const Spacer(),
            const Divider(),
            _crearElementoMenu(Icons.logout, 'Cerrar Sesión', _cerrarSesion, Colors.red, false),
            const SizedBox(height: 10),
          ],
        ),
      ),

      // --- PANTALLA PRINCIPAL ---
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tus Clases Activas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorDocente)),
                const SizedBox(height: 5),
                Text('Administra tus grupos y monitorea el progreso ambiental.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clases')
                  .where('docente_id', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 15),
                          Text('No has creado ninguna clase aún.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        ],
                      )
                  );
                }

                final clases = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: clases.length,
                  itemBuilder: (context, index) {
                    final doc = clases[index];
                    final clase = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.grey.shade200,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleClaseDocente(
                                claseId: doc.id,
                                nombreClase: clase['nombre_clase'] ?? '',
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.school, color: colorDocente, size: 28),
                        ),
                        title: Text(clase['nombre_clase'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.vpn_key_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 5),
                              Text('${clase['codigo']}', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            ],
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearClase,
        backgroundColor: colorDocente,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Clase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- Widget para dibujar los items del menú de forma elegante ---
  Widget _crearElementoMenu(IconData icono, String titulo, VoidCallback accion, Color colorTema, bool estaActivo) {
    return ListTile(
      leading: Icon(icono, color: estaActivo ? colorTema : Colors.grey.shade600),
      title: Text(
        titulo,
        style: TextStyle(
          color: estaActivo ? colorTema : Colors.black87,
          fontWeight: estaActivo ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: estaActivo,
      selectedTileColor: colorTema.withOpacity(0.05),
      onTap: accion,
    );
  }
}