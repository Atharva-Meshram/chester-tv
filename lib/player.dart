import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MediaKit imports
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class ChewieListPlayer extends StatefulWidget {
  const ChewieListPlayer({super.key});

  @override
  State<ChewieListPlayer> createState() => _ChewieListPlayerState();
}

class _ChewieListPlayerState extends State<ChewieListPlayer> {
  late final Player _player;
  late final VideoController _controller;

  List<dynamic> channels = [];
  List<dynamic> filteredChannels = [];

  Set<String> favoriteChannels = {};

  String selectedFilter = "All";
  String searchQuery = "";

  bool isLoading = true;

  final List<String> filters = [
    "All",
    "Favorite",
    "Music",
    "News",
    "Kids",
    "Movies",
    "Entertainment",
    "Sports",
    "Informative",
    "Hindi",
    "English",
    "Marathi",
    "Sony",
    "Star",
    "Warner Bros. Discovery",
    "Zee",
    "Nick",
    "&",
    "Colors",
    "Times Group",
    "B4U",
    "Epic",
  ];

  @override
  void initState() {
    super.initState();

    MediaKit.ensureInitialized();

    _player = Player();
    _controller = VideoController(_player);

    loadFavorites().then((_) => loadChannels());
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteChannels = (prefs.getStringList('favorites') ?? []).toSet();
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favoriteChannels.toList());
  }

  Future<void> loadChannels() async {
    final jsonString = await rootBundle.loadString('lib/channels.json');
    final data = jsonDecode(jsonString);

    channels = data['channels'];
    filteredChannels = List.from(channels);

    if (channels.isNotEmpty) {
      playChannel(channels[0]['channel_link']);
    }

    setState(() => isLoading = false);
  }

  void applyFilter(String value) {
    setState(() {
      selectedFilter = value;
      updateList();
    });
  }

  void search(String text) {
    setState(() {
      searchQuery = text;
      updateList();

      if (filteredChannels.isEmpty && text.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No Channel found")));
      }
    });
  }

  void updateList() {
    List list = List.from(channels);

    if (selectedFilter == "Favorite") {
      list = list.where((c) => favoriteChannels.contains(c["name"])).toList();
    } else if (selectedFilter != "All") {
      list = list.where((c) {
        return c["channel_type"] == selectedFilter ||
            c["channel_lang"] == selectedFilter ||
            c["Channel_comp"] == selectedFilter;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list.where((c) {
        return c["name"].toString().toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
      }).toList();
    }

    filteredChannels = list;
  }

  Future<void> playChannel(String url) async {
    if (url.isEmpty) return;

    await _player.open(Media(url));
  }

  Future<void> toggleFav(String name) async {
    setState(() {
      if (favoriteChannels.contains(name)) {
        favoriteChannels.remove(name);
      } else {
        favoriteChannels.add(name);
      }
    });

    await saveFavorites();
    updateList();
    setState(() {});
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Widget playerView() {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Video(controller: _controller, fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink, Colors.blue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          title: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  "Chester TV",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: search,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          playerView(),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Filter Channels',
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: filters.map((filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(
                    filter,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) applyFilter(value);
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading && channels.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredChannels.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final channel = filteredChannels[index];
                      final isFav = favoriteChannels.contains(channel["name"]);

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    playChannel(channel['channel_link'] ?? '');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(
                                      channel['channel_logo'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: 2,
                              left: 2,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  toggleFav(channel["name"]);
                                },
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
