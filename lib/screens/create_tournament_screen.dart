import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import 'match_list_screen.dart';
import '../widgets/team_logo_widget.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final List<Player> _teams = [];
  final TextEditingController _tournamentNameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  String? _selectedLogoPath;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _teamFormKey = GlobalKey<FormState>();
  TournamentFormat _selectedFormat = TournamentFormat.knockout;
  final ImagePicker _picker = ImagePicker();

  Future<void> _importLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedLogoPath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import logo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tournamentNameController.dispose();
    _teamNameController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  void _addTeam() {
    if (_teamFormKey.currentState!.validate()) {
      final teamName = _teamNameController.text.trim();
      final playerName = _playerNameController.text.trim();

      // Case-insensitive duplicate check
      final isDuplicate = _teams.any(
        (t) => t.teamName.toLowerCase() == teamName.toLowerCase()
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A team with this name already exists.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _teams.add(Player(
          id: '${DateTime.now().millisecondsSinceEpoch}_$teamName',
          teamName: teamName,
          name: playerName,
          logoPath: _selectedLogoPath,
        ));
        _selectedLogoPath = null;
      });
      
      _teamNameController.clear();
      _playerNameController.clear();
    }
  }

  void _removeTeam(String id) {
    setState(() {
      _teams.removeWhere((t) => t.id == id);
    });
  }

  void _quickAddTeams(int count) {
    final sampleTeams = [
      {'team': 'Tigers', 'player': 'Rahim'},
      {'team': 'Dragons', 'player': 'Karim'},
      {'team': 'Panthers', 'player': 'Fahim'},
      {'team': 'Wolves', 'player': 'Sajid'},
      {'team': 'Falcons', 'player': 'Tanvir'},
      {'team': 'Sharks', 'player': 'Imran'},
      {'team': 'Lions', 'player': 'Hassan'},
      {'team': 'Vipers', 'player': 'Zubair'},
      {'team': 'Titans', 'player': 'Nabil'},
      {'team': 'Knights', 'player': 'Riad'},
    ];

    setState(() {
      int added = 0;
      for (var st in sampleTeams) {
        if (added >= count) break;
        final team = st['team']!;
        final player = st['player']!;
        if (!_teams.any((t) => t.teamName.toLowerCase() == team.toLowerCase())) {
          _teams.add(Player(
            id: '${DateTime.now().millisecondsSinceEpoch}_${team}_$added',
            teamName: team,
            name: player,
          ));
          added++;
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _isTournamentConfigValid {
    if (_selectedFormat == TournamentFormat.knockout) {
      return _teams.length >= 4 && _teams.length % 2 == 0;
    } else {
      return _teams.length >= 3;
    }
  }

  Widget _buildWarningBox(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha((255 * 0.15).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withAlpha((255 * 0.3).toInt()),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade300,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTournament() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFormat == TournamentFormat.knockout) {
      if (_teams.length < 4) {
        _showError("Knockout requires at least 4 teams");
        return;
      }
      if (_teams.length.isOdd) {
        _showError("Knockout tournaments require an even number of teams");
        return;
      }
    } else {
      if (_teams.length < 3) {
        _showError('Please add at least 3 teams to start.');
        return;
      }
    }

    final tournamentName = _tournamentNameController.text.trim();
    final tournamentId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create and auto-persist the tournament inside the constructor
    final tournamentState = TournamentState(
      id: tournamentId,
      name: tournamentName,
      players: List.from(_teams),
      format: _selectedFormat,
    );

    // Navigate to Match Screen and clear previous stack so back goes to Home Screen
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MatchListScreen(tournamentState: tournamentState),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;

          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                
                // 1. General Tournament Configurations Form
                Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _tournamentNameController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Tournament Name *',
                              prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                              hintText: 'e.g. Summer Cup 2026',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tournament name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<TournamentFormat>(
                            initialValue: _selectedFormat,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Format',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                            ),
                            items: TournamentFormat.values.map((format) {
                              return DropdownMenuItem<TournamentFormat>(
                                value: format,
                                child: Row(
                                  children: [
                                    Icon(
                                      format == TournamentFormat.knockout
                                          ? Icons.account_tree_outlined
                                          : Icons.grid_view_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(format.displayName),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedFormat = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Team Registration Card Form
                Form(
                  key: _teamFormKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'TEAM REGISTRATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  InkWell(
                                    onTap: _importLogo,
                                    borderRadius: BorderRadius.circular(32),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        ListenableBuilder(
                                          listenable: _teamNameController,
                                          builder: (context, _) {
                                            return TeamLogoWidget(
                                              logoPath: _selectedLogoPath,
                                              teamName: _teamNameController.text.trim().isNotEmpty
                                                  ? _teamNameController.text.trim()
                                                  : 'Team',
                                              size: 64,
                                            );
                                          },
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.edit,
                                              size: 12,
                                              color: theme.colorScheme.surface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: _importLogo,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Import Logo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _teamNameController,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Team Name *',
                                        prefixIcon: Icon(Icons.shield_outlined),
                                        hintText: 'e.g. Red Dragons',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Team name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _playerNameController,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Player Name (Optional)',
                                        prefixIcon: Icon(Icons.person_outline_rounded),
                                        hintText: 'e.g. Karim',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _addTeam,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            label: const Text('Add Team to List'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Registered Teams Stats Header & Presets
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Registered Teams (${_teams.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.bolt, size: 14),
                          label: const Text('Add 4 Presets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          onPressed: () => _quickAddTeams(4),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.1).toInt()),
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.bolt, size: 14),
                          label: const Text('Add 8 Presets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          onPressed: () => _quickAddTeams(8),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.1).toInt()),
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. Team List
                _teams.isEmpty
                    ? Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha((255 * 0.05).toInt()),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 44,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No teams registered yet',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teams.length,
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: TeamLogoWidget(
                                logoPath: team.logoPath,
                                teamName: team.teamName,
                                size: 40,
                              ),
                              title: Text(
                                team.teamName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                team.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: Colors.red.shade400,
                                onPressed: () => _removeTeam(team.id),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 24),

                // 5. Start Tournament Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedFormat == TournamentFormat.knockout) ...[
                      if (_teams.length < 4) ...[
                        _buildWarningBox(theme, 'Knockout requires at least 4 teams'),
                        const SizedBox(height: 12),
                      ] else if (_teams.length.isOdd) ...[
                        _buildWarningBox(theme, 'Knockout tournaments require an even number of teams'),
                        const SizedBox(height: 12),
                      ],
                    ] else ...[
                      if (_teams.length < 3) ...[
                        _buildWarningBox(theme, 'Minimum 3 teams required to start'),
                        const SizedBox(height: 12),
                      ],
                    ],
                    ElevatedButton.icon(
                      onPressed: _isTournamentConfigValid ? _startTournament : null,
                      icon: const Icon(Icons.sports_rounded, size: 22),
                      label: const Text(
                        'Start Tournament',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: _isTournamentConfigValid
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withAlpha((255 * 0.3).toInt()),
                        foregroundColor: _isTournamentConfigValid
                            ? theme.colorScheme.surface
                            : Colors.white30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
