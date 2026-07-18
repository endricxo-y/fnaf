# Graph Report - .  (2026-07-18)

## Corpus Check
- Corpus is ~10,832 words - fits in a single context window. You may not need a graph.

## Summary
- 17 nodes · 16 edges · 8 communities (1 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Godot Git Plugin Core|Godot Git Plugin Core]]
- [[_COMMUNITY_libssh2 & BSD Licensing|libssh2 & BSD Licensing]]
- [[_COMMUNITY_Clar Testing & ISC License|Clar Testing & ISC License]]
- [[_COMMUNITY_godot-cpp Bindings & MIT|godot-cpp Bindings & MIT]]
- [[_COMMUNITY_libgit2 & GPL Licensing|libgit2 & GPL Licensing]]
- [[_COMMUNITY_OpenSSL & SSL License|OpenSSL & SSL License]]
- [[_COMMUNITY_ZLib Compression|ZLib Compression]]
- [[_COMMUNITY_FNAF Project Icon|FNAF Project Icon]]

## God Nodes (most connected - your core abstractions)
1. `Godot Git Plugin` - 8 edges
2. `godotengine/godot-cpp` - 2 edges
3. `libgit2/libgit2` - 2 edges
4. `libssh2/libssh2` - 2 edges
5. `OpenSSL` - 2 edges
6. `ZLib` - 2 edges
7. `Clar Framework` - 2 edges
8. `regex library (GNU C Library)` - 2 edges
9. `winhttp definition files` - 2 edges
10. `GNU LGPL v2.1` - 2 edges

## Surprising Connections (you probably didn't know these)
- `Godot Git Plugin` --references--> `Clar Framework`  [EXTRACTED]
  addons/godot-git-plugin/THIRDPARTY.md → addons/godot-git-plugin/THIRDPARTY.md  _Bridges community 0 → community 2_
- `Godot Git Plugin` --references--> `godotengine/godot-cpp`  [EXTRACTED]
  addons/godot-git-plugin/THIRDPARTY.md → addons/godot-git-plugin/THIRDPARTY.md  _Bridges community 0 → community 3_
- `Godot Git Plugin` --references--> `libgit2/libgit2`  [EXTRACTED]
  addons/godot-git-plugin/THIRDPARTY.md → addons/godot-git-plugin/THIRDPARTY.md  _Bridges community 0 → community 4_
- `Godot Git Plugin` --references--> `libssh2/libssh2`  [EXTRACTED]
  addons/godot-git-plugin/THIRDPARTY.md → addons/godot-git-plugin/THIRDPARTY.md  _Bridges community 0 → community 1_
- `Godot Git Plugin` --references--> `OpenSSL`  [EXTRACTED]
  addons/godot-git-plugin/THIRDPARTY.md → addons/godot-git-plugin/THIRDPARTY.md  _Bridges community 0 → community 5_

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Godot Git Plugin Third-Party Dependencies** — addons_godot_git_plugin_thirdparty_godotgitplugin, addons_godot_git_plugin_thirdparty_godotengine_godot_cpp, addons_godot_git_plugin_thirdparty_libgit2_libgit2, addons_godot_git_plugin_thirdparty_libssh2_libssh2, addons_godot_git_plugin_thirdparty_openssl, addons_godot_git_plugin_thirdparty_zlib, addons_godot_git_plugin_thirdparty_clarframework, addons_godot_git_plugin_thirdparty_regexlibrary, addons_godot_git_plugin_thirdparty_winhttp [EXTRACTED 1.00]

## Communities (8 total, 7 thin omitted)

### Community 0 - "Godot Git Plugin Core"
Cohesion: 0.67
Nodes (4): Godot Git Plugin, GNU LGPL v2.1, regex library (GNU C Library), winhttp definition files

## Knowledge Gaps
- **1 isolated node(s):** `FNAF Project Icon`
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Godot Git Plugin` connect `Godot Git Plugin Core` to `libssh2 & BSD Licensing`, `Clar Testing & ISC License`, `godot-cpp Bindings & MIT`, `libgit2 & GPL Licensing`, `OpenSSL & SSL License`, `ZLib Compression`?**
  _High betweenness centrality (0.804) - this node is a cross-community bridge._
- **Why does `godotengine/godot-cpp` connect `godot-cpp Bindings & MIT` to `Godot Git Plugin Core`?**
  _High betweenness centrality (0.117) - this node is a cross-community bridge._
- **Why does `libgit2/libgit2` connect `libgit2 & GPL Licensing` to `Godot Git Plugin Core`?**
  _High betweenness centrality (0.117) - this node is a cross-community bridge._
- **What connects `MIT License`, `GPLv2 with Linking Exception`, `BSD-3-Clause License` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._