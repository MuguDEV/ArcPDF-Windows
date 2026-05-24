import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import 'tools_controller.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: DragToMoveArea(
                child: Container(
                  height: 36,
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Text('ArcPDF Tools', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      WindowCaption(
                        brightness: theme.brightness,
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar(
            floating: true,
            pinned: true,
            toolbarHeight: 48,
            title: Text('PDF Tools',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(context, 'Convert', const [
                  _ToolItem('Images to PDF', HugeIcons.strokeRoundedImage01, 'Convert images into a single PDF'),
                  _ToolItem('PDF to Images', HugeIcons.strokeRoundedImage02, 'Extract all pages as images'),
                  _ToolItem('Extract Text', HugeIcons.strokeRoundedText, 'Get raw text from a PDF'),
                  _ToolItem('Extract Images', HugeIcons.strokeRoundedImageDownload, 'Save all embedded images'),
                ]),
                const SizedBox(height: 24),
                _buildSection(context, 'Organize', const [
                  _ToolItem('Merge PDFs', HugeIcons.strokeRoundedLink04, 'Combine multiple PDFs'),
                  _ToolItem('Split PDF', Icons.cut_rounded, 'Separate into multiple files'),
                  _ToolItem('Remove Pages', HugeIcons.strokeRoundedDelete02, 'Delete specific pages'),
                  _ToolItem('Reorder Pages', HugeIcons.strokeRoundedSorting05, 'Change page order'),
                  _ToolItem('Rotate Pages', HugeIcons.strokeRoundedRefresh, 'Rotate document pages'),
                ]),
                const SizedBox(height: 24),
                _buildSection(context, 'Optimize', const [
                  _ToolItem('Compress', HugeIcons.strokeRoundedArchive02, 'Reduce file size'),
                  _ToolItem('Crop', HugeIcons.strokeRoundedCrop, 'Trim page margins'),
                  _ToolItem('Flatten', HugeIcons.strokeRoundedLayers01, 'Bake annotations into document'),
                ]),
                const SizedBox(height: 24),
                _buildSection(context, 'Security', const [
                  _ToolItem('Encrypt', HugeIcons.strokeRoundedLockPassword, 'Add password protection'),
                  _ToolItem('Decrypt', Icons.lock_open_rounded, 'Remove password'),
                  _ToolItem('Watermark', HugeIcons.strokeRoundedStamp01, 'Add a custom watermark'),
                ]),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<_ToolItem> tools) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.sizeOf(context).width / 250).floor().clamp(1, 4),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => ToolsController.handleToolAction(context, tool.title),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tool.icon, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tool.title,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool.description,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ToolItem {
  final String title;
  final IconData icon;
  final String description;

  const _ToolItem(this.title, this.icon, this.description);
}
