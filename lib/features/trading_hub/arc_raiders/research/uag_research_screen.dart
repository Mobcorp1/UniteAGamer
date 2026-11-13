import 'package:flutter/material.dart';
import 'uag_research_catalogue.dart';
import 'uag_research_repository.dart';
import '../repositories/arc_blueprint_repository.dart';
import '../models/arc_blueprint_state.dart';

class UagResearchScreen extends StatefulWidget {
  const UagResearchScreen({
    super.key,
    this.embedded = false,
    this.initialCategory = 'blueprint',
  });
  final bool embedded;
  final String initialCategory;
  @override
  State<UagResearchScreen> createState() => _UagResearchScreenState();
}

class _UagResearchScreenState extends State<UagResearchScreen> {
  final UagResearchRepository _repo = UagResearchRepository();
  final ArcBlueprintRepository _blueprints = ArcBlueprintRepository();
  late String _category;
  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  static const _statuses = <String>[
    'Not started',
    'Step 1',
    'Step 2',
    'Completed',
  ];
  Future<void> _setStatus(
    UagResearchRecipe recipe,
    UagResearchProgress progress,
    int status,
  ) async {
    await _repo.save(
      recipe.id,
      UagResearchProgress(
        stage: status,
        collected: progress.collected,
        pointsCollected: progress.pointsCollected,
      ),
    );
  }

  Future<void> _setAmount(
    UagResearchRecipe recipe,
    UagResearchProgress progress,
    String name,
    int value,
  ) async {
    final amounts = Map<String, int>.from(progress.collected);
    amounts[name] = value.clamp(0, 999999);
    await _repo.save(
      recipe.id,
      UagResearchProgress(
        stage: progress.stage,
        collected: amounts,
        pointsCollected: progress.pointsCollected,
      ),
    );
  }

  Widget _counter(
    UagResearchRecipe recipe,
    UagResearchProgress progress,
    UagResearchRequirement requirement,
  ) {
    final amount = progress.collected[requirement.name] ?? 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${requirement.name}: $amount / ${requirement.quantity}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: amount == 0
              ? null
              : () =>
                    _setAmount(recipe, progress, requirement.name, amount - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: amount >= requirement.quantity
              ? null
              : () =>
                    _setAmount(recipe, progress, requirement.name, amount + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _card(
    UagResearchRecipe recipe,
    UagResearchProgress progress, {
    bool? blueprintOwned,
  }) => Card(
    color: const Color(0xFF17152B),
    child: ExpansionTile(
      title: Text(
        recipe.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${recipe.unlocks} · Research Station ${recipe.stationLevel} · ${_statuses[progress.stage]}${blueprintOwned == null
            ? ''
            : blueprintOwned
            ? ' · Owned in Blueprint Tracker'
            : ' · Missing in Blueprint Tracker'}',
        style: const TextStyle(color: Colors.cyanAccent),
      ),
      childrenPadding: const EdgeInsets.all(12),
      children: [
        Text(
          'Step 1: ${recipe.stepOne}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: progress.stage,
          dropdownColor: const Color(0xFF17152B),
          decoration: const InputDecoration(labelText: 'Research status'),
          items: [
            for (var i = 0; i < 4; i++)
              DropdownMenuItem(value: i, child: Text(_statuses[i])),
          ],
          onChanged: (value) {
            if (value != null) _setStatus(recipe, progress, value);
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Step 2: ${recipe.researchPoints} Research Points',
          style: const TextStyle(color: Colors.white),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Saved points: ${progress.pointsCollected}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: () => _repo.save(
                recipe.id,
                UagResearchProgress(
                  stage: progress.stage,
                  collected: progress.collected,
                  pointsCollected: (progress.pointsCollected - 100).clamp(
                    0,
                    recipe.researchPoints,
                  ),
                ),
              ),
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              onPressed: () => _repo.save(
                recipe.id,
                UagResearchProgress(
                  stage: progress.stage,
                  collected: progress.collected,
                  pointsCollected: (progress.pointsCollected + 100).clamp(
                    0,
                    recipe.researchPoints,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        for (final item in recipe.materials) _counter(recipe, progress, item),
        if (recipe.crafting.isNotEmpty) ...[
          const Divider(),
          const Text(
            'Crafting materials (separate from research)',
            style: TextStyle(color: Colors.cyanAccent),
          ),
          for (final item in recipe.crafting) _counter(recipe, progress, item),
        ],
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<Map<String, UagResearchProgress>>(
      stream: _repo.watchProgress(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text('Could not load research: ${snapshot.error}'),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final list = UagResearchCatalogue.recipes
            .where((r) => r.kind == _category)
            .toList();
        return Column(
          children: [
            if (!widget.embedded)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'amplification',
                      label: Text('Amplifications'),
                    ),
                    ButtonSegment(value: 'design', label: Text('Designs')),
                    ButtonSegment(
                      value: 'blueprint',
                      label: Text('Blueprints'),
                    ),
                  ],
                  selected: {_category},
                  onSelectionChanged: (selection) =>
                      setState(() => _category = selection.first),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final recipe = list[i];
                  if (recipe.kind != 'blueprint') {
                    return _card(
                      recipe,
                      snapshot.data![recipe.id] ??
                          UagResearchProgress.fromMap(null),
                    );
                  }
                  return StreamBuilder<Map<String, ArcBlueprintState>>(
                    stream: _blueprints.watchMyBlueprintStates(),
                    builder: (context, ownedSnapshot) {
                      final blueprintId = recipe.id.substring(
                        'blueprint-'.length,
                      );
                      final owned = ownedSnapshot.hasData
                          ? (ownedSnapshot.data![blueprintId]?.owned ?? false)
                          : null;
                      return _card(
                        recipe,
                        snapshot.data![recipe.id] ??
                            UagResearchProgress.fromMap(null),
                        blueprintOwned: owned,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0925),
      appBar: AppBar(title: const Text('Research Station')),
      body: content,
    );
  }
}
