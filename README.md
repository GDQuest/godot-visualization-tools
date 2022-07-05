# Godot Visualization Tools

/!\ Rewrite in progress with Godot 3.5. Documentation coming soon.

A collection of scripts and tools for debug visualizations of collision shapes.

This is a work-in-progress. Mose of this code comes from our project [Godot Node Essentials](https://github.com/GDQuest/godot-node-essentials).

## Outline

1. Introduction

  - Overview
  - Plus mention that the plugin is made with Godot 3.5 so is not compatible with previous versions.

2. Features

  - Intuitive inspector properties that update based on supported shapes and features.
  - Palette with a "Disabled" value that updates the `Disabled` property accordingly and vice-versa.
  - Theme. Simple, Dashed & Halo for 2D. Wireframe & Halo for 3D.
  - Simple & Dashed theme extra properties: Width & Sample. Width gives us the thickness of the outline. Sample sets the number of segments used for the outline.
  - Autoload singleton to easily manage visibility at runtime: `GDQuestVisualizationTools.set_is_debug_collision_visible()` & `GDQuestVisualizationTools.set_is_debug_navigation_visible()`.
  - Independent visibility toggle from `Debug > Visible Collision Shapes` and `Debug > Visible Navigation`.

3. Technical limitations and issues

  - 2D: When duplicating a node it's mandatory to make the `material` property unique. Otherwise a theme change will override all nodes and distort the visuals.
  - 3D: Can't toggle visibility in the editor by toggling visibility of a parent node. Visibility has to be toggled specifically on the debug nodes themselves.
  - 3D: The meshes are recreated from scratch each time a change happens with the transform or a relevent property. At runtime this might become a performance issue. Still needs investigation.

4. Technical details. 2D is built with `CanvasItem._draw()`, while 3D is built with `VisualServer`.
