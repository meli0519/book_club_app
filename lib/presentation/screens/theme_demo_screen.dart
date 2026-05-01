import 'package:flutter/material.dart';
import '../widgets/common/common_widgets.dart';

/// Demo screen to showcase the Alquimia Literaria theme and components.
/// This screen can be used for testing and demonstrating the visual design.
class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alquimia Literaria'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () {},
          ),
        ],
      ),
      body: AlchemicalBackground(
        isDark: isDark,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo
            const AlquimiaLogo(
              size: 150,
              showText: true,
              animate: true,
            ),
            const SizedBox(height: 32),

            // Mystical Divider
            const MysticalDivider(),
            const SizedBox(height: 24),

            // Section: Cards
            Text(
              'Alchemical Cards',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AlchemicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'El Nombre del Viento',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              'Patrick Rothfuss',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const StarRatingDisplay(
                    rating: 4.5,
                    showValue: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Una historia épica de magia, música y misterio que te transportará a un mundo de fantasía inolvidable.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            AlchemicalCard(
              showGlow: false,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reunión Próxima',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capítulos 5-8',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '15 Mayo, 2026',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const MysticalDivider(),
            const SizedBox(height: 24),

            // Section: Buttons
            Text(
              'Mystical Buttons',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Agregar Libro'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.event),
              label: const Text('Crear Reunión'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.info_outline),
              label: const Text('Más Información'),
            ),

            const SizedBox(height: 24),
            const MysticalDivider(),
            const SizedBox(height: 24),

            // Section: Ratings
            Text(
              'Star Ratings',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const StarRatingDisplay(rating: 5.0, showValue: true),
            const SizedBox(height: 8),
            const StarRatingDisplay(rating: 4.5, showValue: true),
            const SizedBox(height: 8),
            const StarRatingDisplay(rating: 3.0, showValue: true),
            const SizedBox(height: 8),
            const StarRatingDisplay(rating: 1.5, showValue: true),

            const SizedBox(height: 24),
            const MysticalDivider(),
            const SizedBox(height: 24),

            // Section: Input Fields
            Text(
              'Mystical Inputs',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Título del Libro',
                hintText: 'Ingresa el título',
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Autor',
                hintText: 'Nombre del autor',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Comentario',
                hintText: 'Comparte tus pensamientos...',
                prefixIcon: const Icon(Icons.comment),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ),
            ),

            const SizedBox(height: 24),
            const MysticalDivider(),
            const SizedBox(height: 24),

            // Section: Chips
            Text(
              'Genre Tags',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: const Text('Fantasía'),
                  avatar: const Icon(Icons.auto_fix_high, size: 18),
                ),
                Chip(
                  label: const Text('Aventura'),
                  avatar: const Icon(Icons.explore, size: 18),
                ),
                Chip(
                  label: const Text('Misterio'),
                  avatar: const Icon(Icons.search, size: 18),
                ),
                Chip(
                  label: const Text('Romance'),
                  avatar: const Icon(Icons.favorite, size: 18),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Alquimia Literaria',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFamily: 'serif',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Donde la magia y la literatura se encuentran',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.auto_fix_high),
      ),
    );
  }
}
