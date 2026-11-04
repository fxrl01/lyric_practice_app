import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';

/// Estado de un canal de stem en el mixer
class StemChannel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final bool isSolo;
  final bool isAvailable;

  const StemChannel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.volume = 0.8,
    this.isMuted = false,
    this.isSolo = false,
    this.isAvailable = true,
  });

  StemChannel copyWith({
    double? volume,
    bool? isMuted,
    bool? isSolo,
    bool? isAvailable,
  }) {
    return StemChannel(
      id: id,
      name: name,
      icon: icon,
      color: color,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Mixer de stems con controles Mute/Solo/Volume por canal
///
/// UI estilo DAW con indicadores visuales claros.
class StemMixer extends StatelessWidget {
  /// Canales de stems
  final List<StemChannel> channels;

  /// Callback cambio de volumen
  final void Function(String stemId, double volume)? onVolumeChanged;

  /// Callback mute
  final void Function(String stemId)? onMuteToggle;

  /// Callback solo
  final void Function(String stemId)? onSoloToggle;

  /// ¿Vista compacta?
  final bool compact;

  const StemMixer({
    super.key,
    required this.channels,
    this.onVolumeChanged,
    this.onMuteToggle,
    this.onSoloToggle,
    this.compact = false,
  });

  /// Stems predefinidos con colores y iconos
  static List<StemChannel> defaultChannels() {
    return const [
      StemChannel(
        id: 'vocals',
        name: 'Vocals',
        icon: Icons.mic_rounded,
        color: Color(0xFFEC4899),
      ),
      StemChannel(
        id: 'drums',
        name: 'Drums',
        icon: Icons.sports_mma_rounded,
        color: Color(0xFFF59E0B),
      ),
      StemChannel(
        id: 'bass',
        name: 'Bass',
        icon: Icons.graphic_eq_rounded,
        color: Color(0xFF22C55E),
      ),
      StemChannel(
        id: 'guitar',
        name: 'Guitar',
        icon: Icons.music_note_rounded,
        color: Color(0xFF3B82F6),
      ),
      StemChannel(
        id: 'piano',
        name: 'Piano',
        icon: Icons.piano_rounded,
        color: Color(0xFF8B5CF6),
      ),
      StemChannel(
        id: 'other',
        name: 'Other',
        icon: Icons.library_music_rounded,
        color: Color(0xFF6B7280),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactMixer(context);
    return _buildFullMixer(context);
  }

  Widget _buildFullMixer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Stem Mixer',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              // Reset all
              TextButton.icon(
                onPressed: () {
                  for (final ch in channels) {
                    onVolumeChanged?.call(ch.id, 0.8);
                  }
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkTextMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Channels
          ...channels.asMap().entries.map((entry) {
            final index = entry.key;
            final channel = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChannel(context, channel).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: index * 80),
                  ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChannel(BuildContext context, StemChannel channel) {
    final effectiveVolume =
        channel.isMuted ? 0.0 : channel.volume;
    final isActive = !channel.isMuted && channel.isAvailable;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: channel.isAvailable ? 1.0 : 0.4,
      child: Row(
        children: [
          // Icon + Name
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isActive
                        ? channel.color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                  ),
                  child: Icon(
                    channel.icon,
                    size: 16,
                    color: isActive ? channel.color : AppColors.darkTextMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    channel.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive ? null : AppColors.darkTextMuted,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Volume slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: channel.color,
                inactiveTrackColor: AppColors.darkBorder,
                thumbColor: channel.color,
                overlayColor: channel.color.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: effectiveVolume,
                onChanged: channel.isAvailable
                    ? (v) => onVolumeChanged?.call(channel.id, v)
                    : null,
              ),
            ),
          ),

          // Volume %
          SizedBox(
            width: 32,
            child: Text(
              '${(effectiveVolume * 100).toInt()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.darkTextMuted,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.right,
            ),
          ),

          const SizedBox(width: 8),

          // Mute button
          _buildToggleButton(
            context,
            label: 'M',
            isActive: channel.isMuted,
            activeColor: AppColors.error,
            onTap: channel.isAvailable
                ? () => onMuteToggle?.call(channel.id)
                : null,
          ),

          const SizedBox(width: 4),

          // Solo button
          _buildToggleButton(
            context,
            label: 'S',
            isActive: channel.isSolo,
            activeColor: AppColors.warning,
            onTap: channel.isAvailable
                ? () => onSoloToggle?.call(channel.id)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isActive
              ? activeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? activeColor : AppColors.darkTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMixer(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: channels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final isActive = !channel.isMuted && channel.isAvailable;

          return GestureDetector(
            onTap: channel.isAvailable
                ? () => onMuteToggle?.call(channel.id)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isActive
                    ? channel.color.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: isActive
                      ? channel.color.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    channel.icon,
                    size: 16,
                    color: isActive ? channel.color : AppColors.darkTextMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    channel.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? null : AppColors.darkTextMuted,
                    ),
                  ),
                  if (channel.isMuted) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.volume_off_rounded,
                        size: 12, color: AppColors.error),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
