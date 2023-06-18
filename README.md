# Starhaven
 An event horizon explorer.
 An open-source spaceflight and combat game. Watch enemies engage in laser warfare as you collect black holes randomly scattered through the starry conflict region.
 
 ## FIXES, UPDATES, AND SOLUTIONS
 ### Refactoring: Managers (6/17/2023)
 
 **This update primarily focuses on applying the single-responsibility principle to our codebase. Previously, most of our components were managed in one view model, creating complexities and dependencies that we needed to resolve.**
 The key changes include:
#### PhysicsManager: This class is responsible for the physical interactions in our game world.
#### CollisionHandlers: These handle the behavior of objects when they collide in our game world.
#### Levels: Represent the stages or levels in our game, including the objects present and their arrangements.
#### SceneManager: Manages the display of our scenes.
#### SceneObjects: Represent the various entities present in our scenes.
#### CameraManager: This new class is responsible for managing the camera's movements. We have separated the navigation logic from the camera logic, which was previously intertwined.
#### CameraTrackingState: This new enumeration provides us with more flexibility in positioning our camera.
#### ShipManager: This class manages the player's control of the ship. This functionality is set to be further generalized in the future to accommodate other control objects.
#### InputHandler and PlayerObjectManager: We plan to break down the ShipManager into these two new classes for improved organization and modularity.
#### Interpolation Feature: Leveraged the flexibility of the CameraManager to add a mixing factor, enabling smoother rotations when turning.
This refactoring aims to streamline our application's architecture and improve the rendering experience. We hope to continue improving our codebase with inspirations from the previous code.

 ### Accessibility: Settings Screen (6/12/2023)
 **This update describes the introduction of an in-game settings screen and button.**
 
 #### Changes:
 Users now have access to a beta Settings Screen from which they can adjust a variety of parameters, including skybox intensity, camera follow distance, audio volume, 1st/3rdPOV toggle in beta, etc.). This foreshadows further customizations around the app in the future.
 
 ### Optimization: OBJ. Model Sharing (6/11/2023)
 **This update describes solutions created in struggling with memory management.**
 
 #### Changes:
 We implemented an optimization approach to reduce memory usage and improve performance for our Raider models, missiles, and larger ships. Previously, the program was loading the same 3D model multiple times for each object, resulting in multiple copies of the same model being stored in memory. This was causing memory errors and impacting performance.

To address this issue, we modified the code to load each 3D model once and reuse it for each object of the same type. This reduced the number of copies of each model in memory from n to just one, which helped reduce memory usage and improve performance. We used .flattenedCopy() to reduce the complexity of the root model for each.

The changes were made by modifying the relevant functions to load each model once before creating the objects, and then passing the loaded model as a parameter to the object's initializer. The classes for each object type were also modified to accept a `modelNode` parameter in their initializer and store it as a property of the class. The functions that create the objects were then modified to use this property instead of loading the model again.

These changes allowed the program to share the same instance of each 3D model between multiple instances of the same object type, while still allowing each object to appear as its own individual entity. This helped reduce memory usage and improve performance, while still maintaining the desired behavior of the program.
 
 ### Optimization: Introduction of ParticleManager for Consolidated Particle System Configurations
 **This update presents a major step in improving the performance of the game by introducing an efficient management of particle systems via a dedicated ParticleManager class.**

 #### Changes:
 ParticleManager Class: This class is the centralized location where we define and manage our particle system configurations. Instead of creating configurations on-the-fly, they are now predefined within this class and can be accessed when needed, thereby reducing computational overhead.

 Static Particle Systems: We've defined the configurations for different particle systems like lasers, missile trails, and explosions as static properties in the ParticleManager. This means we can use these configurations throughout our game without creating new ones each time, which significantly reduces memory usage and boosts rendering performance.

 Functions for Dynamic Configurations: For the particle systems that require more dynamic properties, such as color for missile trails, we have defined functions that return configured particle systems. This gives us the best of both worlds, maintaining the performance benefits of static configurations and providing flexibility where required.

 Applied Changes: We've applied these changes across the Laser, GhostMissile, and Explosion classes, which now utilize the ParticleManager for their particle systems.

 These improvements should result in noticeable performance gains, particularly in high-intensity scenes with many active particle systems.

### Optimization: Quaternion-based Rotations for Improved Ship Orientation (5/29/2023)
**This update addresses the issue of gimbal lock that was affecting the orientation and navigation of ships in our game. It describes the successful implementation of quaternion-based rotations to solve this problem and improve the game's performance.**

#### Changes:
Introduction of Quaternions: In order to overcome the issue of gimbal lock that is common with Euler angle-based rotations, we have moved to quaternion-based rotations. Quaternions, represented by SCNQuaternion in SceneKit, are complex numbers that can represent 3D rotations more efficiently and reliably.

Avoiding Gimbal Lock: Quaternions operate in four dimensions, which allows for smooth and continuous rotation in 3D space. They have been employed to rotate our ships, ensuring the avoidance of gimbal lock. With this change, we have been able to ensure consistent and predictable rotation behavior for all ships, irrespective of their current orientation.

Application to SceneKit: We have applied this rotation mechanism to SceneKit by modifying the orientation property of the nodes representing the ships. This property is a quaternion and by manipulating it, we were able to control the rotation of the nodes, thus achieving the desired ship orientation.

User Interaction: While quaternions don't suffer from gimbal lock, converting between quaternions and Euler angles, if not handled properly, could reintroduce the problem. As our app involves user input and displays rotation in terms of Euler angles, we have ensured careful handling of these situations.

Result:

The use of quaternion-based rotations has led to smoother and more realistic ship movements in the game, enhancing the overall user experience. It has eliminated the possibility of unexpected orientation behavior due to gimbal lock.
