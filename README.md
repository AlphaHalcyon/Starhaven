# Starhaven
An event horizon explorer.
An open-source spaceflight and combat game. Watch enemies engage in laser warfare as you collect black holes randomly scattered through the starry conflict region.

Optimization Update: Consolidation of Particle System Configurations

In this update, we've made significant improvements to the performance of the game by optimizing how we handle particle systems.

Changes:

Particle System Configuration Consolidation: Instead of recreating and recalculating the configurations for particle systems with every instance (like lasers, missile trails, and explosions), we've consolidated these configurations into static functions. These functions return a predefined configuration which we can use multiple times across different instances, thereby reducing computational overhead.

Shared Particle Systems: We've implemented shared particle systems across all instances of lasers, missiles, and explosions. This means we are not instantiating a new particle system for every single laser or missile, but instead reusing a static configuration, which significantly reduces memory usage and increases rendering performance.

Specific Class Changes: We've applied these changes across the Laser, GhostMissile, and Explosion classes. Each of these classes now have static functions for their respective particle systems, which are invoked during the object's creation or action (like detonation).

The changes should provide noticeable improvements in game performance, especially in scenes with a high number of active particle systems.

Future Work:

We'll continue monitoring performance and looking for additional opportunities to optimize our codebase. We'll also consider applying a similar pattern to other shared resources within the game.
