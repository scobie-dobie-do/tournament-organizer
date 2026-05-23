import 'package:flutter/material.dart';
import '../services/logo_service.dart';
import '../storage/logo_storage_service.dart';
import '../widgets/team_logo_widget.dart';

class LogoSearchScreen extends StatefulWidget {
  const LogoSearchScreen({super.key});

  @override
  State<LogoSearchScreen> createState() => _LogoSearchScreenState();
}

class _LogoSearchScreenState extends State<LogoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LogoService _logoService = LogoService();
  final LogoStorageService _storageService = LogoStorageService();

  List<LogoSearchResult> _results = [];
  bool _isLoadingIndex = true;
  bool _isDownloading = false;
  bool _hasError = false;
  String _statusMessage = 'Loading logo database...';

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIndex() async {
    if (!mounted) return;
    setState(() {
      _isLoadingIndex = true;
      _hasError = false;
      _statusMessage = 'Loading logo database...';
    });
    try {
      await _logoService.init();
      final initialResults = await _logoService.searchLogos('');
      if (!mounted) return;
      setState(() {
        _results = initialResults;
        _isLoadingIndex = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingIndex = false;
        _hasError = true;
        _statusMessage = 'Failed to load logo database. Please check your internet connection.';
      });
    }
  }

  Future<void> _onSearchChanged(String value) async {
    try {
      final results = await _logoService.searchLogos(value);
      if (!mounted) return;
      setState(() {
        _results = results;
      });
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  Future<void> _selectLogo(LogoSearchResult logo) async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading logo...';
    });

    final localPath = await _storageService.downloadLogo(logo.logoUrl, logo.id);

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
    });

    if (localPath != null && mounted) {
      Navigator.pop(context, localPath);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to download logo. Please check network connection.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importFromGallery() async {
    final localPath = await _storageService.importLogoFromGallery();
    if (localPath != null && mounted) {
      Navigator.pop(context, localPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Select Team Logo'),
          ),
          body: Column(
            children: [
              // 1. Search Box & Gallery Action
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        FocusScope.of(context).unfocus();
                        _onSearchChanged(value);
                      },
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Search Logos (football-logos.cc)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        hintText: 'e.g. Manchester United, Juventus...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.primary.withAlpha((255 * 0.15).toInt()),
                      child: InkWell(
                        onTap: _importFromGallery,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.photo_library_outlined, color: primaryColor),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Import Custom Logo',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pick an image file from your device gallery',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main content area
              Expanded(
                child: _isLoadingIndex
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage,
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : _hasError
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_rounded, size: 54, color: Colors.red.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _statusMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadIndex,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade600),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No logos found',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try searching for another keyword',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Compute column count responsively
                              int crossAxisCount = 3;
                              if (constraints.maxWidth > 600) {
                                crossAxisCount = 5;
                              }
                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final logo = _results[index];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: InkWell(
                                      onTap: () => _selectLogo(logo),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: TeamLogoWidget(
                                                  logoPath: logo.logoUrl,
                                                  teamName: logo.name,
                                                  size: 54,
                                                  hasBorder: false,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              logo.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              logo.categoryName,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        if (_isDownloading)
          Container(
            color: Colors.black.withAlpha((255 * 0.75).toInt()),
            child: Center(
              child: Card(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
