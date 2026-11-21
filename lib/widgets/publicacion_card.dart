import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PublicacionCard extends StatelessWidget {
  const PublicacionCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String titulo = data['titulo'] ?? 'Sin título';
    final String tipo = data['tipo'] ?? 'Perdido';
    final String categoria = data['categoria'] ?? 'Otros';
    final String estado = data['estado'] ?? 'Vigente';
    final String lugar = data['lugar'] ?? '';
    final Blob? fotoBlob = data['foto'] is Blob ? data['foto'] as Blob : null;

    final bool esDevuelto = estado == 'Devuelto';
    final bool esPerdido = tipo == 'Perdido';

    final Color tipoColor =
        esPerdido ? AppTheme.perdidoColor : AppTheme.encontradoColor;
    final Color tipoBg =
        esPerdido ? AppTheme.perdidoBg : AppTheme.encontradoBg;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: esDevuelto ? const Color(0xFFF5F7F6) : AppTheme.cardSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: esDevuelto ? 0.55 : 1.0,
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: fotoBlob != null
                        ? Image.memory(
                            fotoBlob.bytes,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: esDevuelto ? AppTheme.devueltoBg : tipoBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tipo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: esDevuelto
                                  ? AppTheme.devueltoColor
                                  : tipoColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: esDevuelto
                                ? AppTheme.devueltoBg
                                : const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: esDevuelto
                                  ? AppTheme.devueltoColor.withValues(alpha: 0.4)
                                  : AppTheme.accentMint.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                esDevuelto
                                    ? Icons.check_circle
                                    : Icons.schedule,
                                size: 12,
                                color: esDevuelto
                                    ? AppTheme.devueltoColor
                                    : AppTheme.accentMint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estado,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 6),
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            esDevuelto ? TextDecoration.lineThrough : null,
                        color: esDevuelto
                            ? AppTheme.devueltoColor
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            categoria,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (lugar.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lugar,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}