import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:descuidau/pages/detalle_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fs_service.dart';
import '../theme/app_theme.dart';
import '../widgets/publicacion_card.dart';
import 'publicar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaSeleccionada = 0;

  @override
  Widget build(BuildContext context) {
    final User? usuario = AuthService().currentUser;
    final String nombreUsuario = usuario?.displayName ?? 'Usuario';
    final String uidUsuario = usuario?.uid ?? '';

    final List<Widget> paginas = [
      _ListarPublicaciones(
        stream: FsService().getPublicacionesStream(),
        mensajeVacio: 'Aún no hay objetos publicados en la sede.',
      ),
      _ListarPublicaciones(
        stream: FsService().getMisPublicacionesStream(uidUsuario),
        ordenar: true,
        mensajeVacio: 'Todavía no has publicado ningún objeto.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'descuidaU',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Hola, $nombreUsuario',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFC8E6C9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _paginaSeleccionada,
        children: paginas,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_a_photo_outlined),
        label: Text('Publicar'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicarPage(),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _paginaSeleccionada,
        onDestinationSelected: (indice) {
          setState(() {
            _paginaSeleccionada = indice;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.primaryGreen),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared_rounded, color: AppTheme.primaryGreen),
            label: 'Mis Publicaciones',
          ),
        ],
      ),
    );
  }
}

class _ListarPublicaciones extends StatelessWidget {
  const _ListarPublicaciones({
    required this.stream,
    required this.mensajeVacio,
    this.ordenar = false,
  });

  final Stream<QuerySnapshot> stream;
  final String mensajeVacio;
  final bool ordenar;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ocurrió un error al cargar las publicaciones.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);

        if (ordenar && docs.length > 1) {
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final Timestamp? fechaA = dataA['fechaCreacion'] as Timestamp?;
            final Timestamp? fechaB = dataB['fechaCreacion'] as Timestamp?;
            if (fechaA == null || fechaB == null) return 0;
            return fechaB.compareTo(fechaA);
          });
        }

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 12),
                  Text(
                    mensajeVacio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: 8, bottom: 88),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return PublicacionCard(
              data: data,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetallePage(
                      publicacionId: doc.id,
                      data: data,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}