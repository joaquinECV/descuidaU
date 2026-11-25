import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fs_service.dart';
import '../theme/app_theme.dart';
import 'dart:typed_data';

class DetallePage extends StatefulWidget {
  const DetallePage({
    super.key,
    required this.publicacionId,
    required this.data,
  });

  final String publicacionId;
  final Map<String, dynamic> data;

  @override
  State<DetallePage> createState() => _DetallePageState();
}

class _DetallePageState extends State<DetallePage> {
  late String _estado;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.data['estado'] ?? 'Vigente';
  }

  Future<void> _marcarDevuelto() async {
    setState(() {
      _procesando = true;
    });

    try {
      await FsService().marcarComoDevuelto(widget.publicacionId);
      if (!mounted) return;
      setState(() {
        _estado = 'Devuelto';
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.data['titulo']} ha sido devuelto'),
          backgroundColor: AppTheme.mediumGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el estado.'),
          backgroundColor: AppTheme.perdidoColor,
        ),
      );
    }
  }

  Future<void> _confirmarYBorrar() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar publicación'),
        content: Text(
          '¿Estás seguro de que deseas borrar esta publicación? Se eliminará permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.perdidoColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _procesando = true;
    });

    try {
      await FsService().borrarPublicacion(widget.publicacionId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publicación eliminada correctamente.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la publicación.'),
          backgroundColor: AppTheme.perdidoColor,
        ),
      );
    }
  }

  Uint8List? _obtenerBytesFoto(dynamic valorFoto) {
    if (valorFoto is Blob) return valorFoto.bytes;
    if (valorFoto is Uint8List) return valorFoto;
    if (valorFoto is List) {
      return Uint8List.fromList(valorFoto.cast<int>());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = widget.data['titulo'] ?? 'Sin título';
    final String descripcion = widget.data['descripcion'] ?? '';
    final String tipo = widget.data['tipo'] ?? 'Perdido';
    final String categoria = widget.data['categoria'] ?? 'Otros';
    final String lugar = widget.data['lugar'] ?? 'No especificado';
    final String fechaHora = widget.data['fechaHora'] ?? '';
    final String autorNombre = widget.data['autorNombre'] ?? 'Usuario Campus';
    final String autorUid = widget.data['autorUid'] ?? '';
    final Uint8List? fotoBytes = _obtenerBytesFoto(widget.data['foto']);
    final String? uidActual = AuthService().currentUser?.uid;
    final bool esAutor = uidActual != null && uidActual == autorUid;
    final bool esDevuelto = _estado == 'Devuelto';
    final bool esPerdido = tipo == 'Perdido';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Objeto'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: fotoBytes != null
                  ? Image.memory(
                      fotoBytes,
                      fit: BoxFit.contain,
                    )
                  : SizedBox(
                      height: 220,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: esPerdido ? AppTheme.perdidoBg : AppTheme.encontradoBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tipo.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: esPerdido
                        ? AppTheme.perdidoColor
                        : AppTheme.encontradoColor,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: esDevuelto
                      ? AppTheme.devueltoBg
                      : Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esDevuelto ? Icons.check_circle : Icons.schedule,
                      size: 16,
                      color: esDevuelto
                          ? AppTheme.devueltoColor
                          : AppTheme.accentMint,
                    ),
                    SizedBox(width: 6),
                    Text(
                      _estado,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: esDevuelto
                            ? AppTheme.devueltoColor
                            : AppTheme.accentMint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Categoría', style: TextStyle(fontSize: 12, color: Colors.grey.shade600),),
                    subtitle: Text(categoria, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),),
                    leading: Icon(Icons.category, size: 20, color: AppTheme.mediumGreen),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Lugar', style: TextStyle(fontSize: 12, color: Colors.grey.shade600),),
                    subtitle: Text(lugar, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),),
                    leading: Icon(Icons.place_outlined, size: 20, color: AppTheme.mediumGreen),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Fecha y Hora', style: TextStyle(fontSize: 12, color: Colors.grey.shade600),),
                    subtitle: Text(fechaHora, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),),
                    leading: Icon(Icons.access_time_outlined, size: 20, color: AppTheme.mediumGreen),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Publicado por', style: TextStyle(fontSize: 12, color: Colors.grey.shade600),),
                    subtitle: Text(autorNombre, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),),
                    leading: Icon(Icons.person_outline, size: 20, color: AppTheme.mediumGreen),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (esAutor) ...[
            SizedBox(height: 24),
            if (!esDevuelto)
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _procesando ? null : _marcarDevuelto,
                  icon: Icon(Icons.check_circle_outline_rounded),
                  label: Text('Marcar como Devuelto'),
                ),
              ),
            if (!esDevuelto) SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _procesando ? null : _confirmarYBorrar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.perdidoColor,
                  side: BorderSide(
                    color: AppTheme.perdidoColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.delete_outline_rounded),
                label: Text(
                  'Eliminar Publicación',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

