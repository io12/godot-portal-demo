# Godot Portal Demo

Experimenting with portals in Godot Engine

[Web build](https://io12.github.io/godot-portal-demo/)

![screenshot](screenshot.png)

## Issues

This implementation has several issues that need to be fixed before
the portals can be fully seamless. To fix all of them, Godot needs
support for custom projection matrices and stencil buffering, which it
doesn't have yet.

- Fix holding RigidBody through portal
- Fix performance with stencil buffering
- Seamless first-person player teleportation
- Mesh culling for objects in portal (needs custom projection matrix)
- Collision masking for objects behind portal
- Lighting through portals
- Portal camera FOV sync with player FOV
- Portal dynamic updating in editor (optional, but nice)
