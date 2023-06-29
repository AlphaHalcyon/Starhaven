![image](https://github.com/AlphaHalcyon/Starhaven/assets/74324748/256cab16-917a-4f28-a418-ec66d660a3c5)# Starhaven
 An event horizon explorer.
 An open-source spaceflight and combat game. Watch enemies engage in laser warfare as you collect black holes randomly scattered through the starry conflict region.
 
 ## FIXES, UPDATES, AND SOLUTIONS
 ### Update: Moonbase and Such
1. **Planet**: The Planet class represents a celestial body in the scene. It includes methods for adding other objects (such as a Moonbase) to the surface of the planet at specific latitudinal and longitudinal coordinates. The method `addObject` was updated to ensure that added objects are properly oriented relative to the planet's surface. This is done by creating a downward direction vector, which points towards the center of the planet from the object's position, and then rotating the object to align its downward direction with this vector. In other words, objects are now properly "gravity-aligned" with the planet.

Possible improvements for this class could be creating helper methods for common tasks such as adding multiple similar objects (like an array of Moonbases) at once or creating a method to adjust an object's position after it's been added to the planet.

2. **Moonbase**: The Moonbase class represents a moon base object in the scene. It includes methods to load various parts of the base, such as a habitat module (`loadHab`), railgun bases (`loadRailgunBase`), solar panels (`loadPanels`), and a railgun turret (`loadTurret`). The Moonbase class is also set up to manage these individual parts, allowing the base to be easily modified or extended in the future.

Quaternions (often abbreviated to "quats") are used in the `Planet` class's `addObject` method.

1. First, it's essential to understand that quaternions are a mathematical tool used to represent and manipulate rotations in 3D space. They are more complex than Euler angles or rotation matrices, but they have some significant advantages: they are more numerically stable, they don't suffer from "gimbal lock" (a problem where you lose a degree of freedom due to aligned rotation axes), and it's easy to interpolate between them smoothly.

2. In the `addObject` method, a quaternion is used to orient an added object so that its downward direction aligns with the vector pointing towards the planet's center.

3. First, a direction vector `downDirection` is computed. This vector points from the object's position towards the planet's center. The direction is made to be "down" by negating the normalized position vector.

4. Then, a quaternion `rotation` is created using `simd_quatf(from:to:)`. This function returns a quaternion that represents a rotation from one direction to another. In this case, it's a rotation from the direction `(0, -1, 0)` (which is the default "down" direction in SceneKit) to the `downDirection` computed earlier.

5. Finally, this quaternion is applied to the object, orienting it so that its down direction points towards the planet's center. The object's orientation is stored as a quaternion (`simdOrientation`), allowing for easy and efficient manipulation of its orientation later on.

The use of quaternions here makes the task of aligning the object with the planet's surface straightforward and numerically stable, even as the object's position changes.

 ### Update: Solution to Floating Point Precision Errors in SceneKit
Our latest update to Starhaven tackles a critical issue that was limiting the scale of our in-game world: floating point precision errors in SceneKit.

SceneKit, the 3D graphics API we use for rendering the game world, conducts all of its calculations using floating point numbers (floats) instead of doubles. Floats are less precise than doubles, especially for large numbers, which leads to noticeable precision errors as objects move far away from the origin.

In our case, this limitation was causing jittery movement in the spaceship when it was more than approximately 100,000 meters (SceneKit units) away from the origin.

Our solution to this problem was to implement a 'player-centric' approach. Instead of having the player move around in the world, we now move the world around the player. To do this, we recenter the world to the player's position every frame, effectively keeping the player at the origin at all times.

Here's how it works in detail:

We start by storing all objects in the world in an array sceneObjects.

1. **In the renderer(_:updateAtTime:) method,** which is called every frame, we call updateObjectPositions(). We will limit the number of calls made to the function dynamically in the future, based on when the player and camera rig have exceeded a maximum distance from the origin.

2. **updateObjectPositions()** iterates over all objects in sceneObjects and updates their positions relative to the player's position. Effectively, it moves the entire world so that the player is at the origin.

3. **Finally**, we reset the player's position to the origin.

4. **This approach** allows us to simulate the player moving through the world while keeping all objects within a relatively small distance from the origin, thus avoiding precision errors.

5. **With this update,** we're able to maintain the ambitious scale of our world while reducing the vector component sizes SceneKit has to work with when doing origin-based calculations, leading to smoother and more realistic movement for the spaceship.

 ### Refactoring: Managers (6/17/2023)
 
 **This update primarily focuses on applying the single-responsibility principle to our codebase. Previously, most of our components were managed in one view model, creating complexities and dependencies that we needed to resolve.**
 The key changes include:
1. **PhysicsManager:**
This class is responsible for the physical interactions in our game world.
2. **CollisionHandlers:** 
These handle the behavior of objects when they collide in our game world.
3. **Levels:**
Represent the stages or levels in our game, including the objects present and their arrangements.
4. **SceneManager:** 
Manages the rendering of our scenes. Includes the rendering loop where update functions are called.
5. **SceneObjects:**
Represent the various entities present in our scenes. They are mapped to their respective nodes in a SceneManager.
6. **CameraManager**
This new class is responsible for managing the camera's movements. We have separated the navigation logic from the camera logic, which was previously intertwined.
7. **CameraTrackingState**
This new enumeration provides us with more flexibility in positioning our camera.
8. **ShipManager:**
This class manages the player's control of the ship. This functionality is set to be further generalized in the future to accommodate other control objects.
9. **InputManager and PlayerObjectManager:**
We plan to break down the ShipManager into these two new classes for improved organization and modularity.
10. **Interpolation Feature:**
Leveraged the flexibility of the CameraManager to add a mixing factor, enabling smoother rotations when turning.

**This refactoring aims to streamline our application's architecture and improve the rendering experience. We hope to continue improving our codebase with inspirations from the previous code.**

 ### Accessibility: Settings Screen (6/12/2023)
 **This update describes the introduction of an in-game settings screen and button.**
 
 #### Changes:
 Users now have access to a beta Settings Screen from which they can adjust a variety of parameters, including skybox intensity, camera follow distance, audio volume, 1st/3rdPOV toggle in beta, etc.). This foreshadows further customizations around the app in the future.
 
 ### Optimization: OBJ. Model Sharing (6/11/2023)
 **This update describes solutions created in struggling with memory management.**
 
 #### Changes:
 We implemented an optimization approach to reduce memory usage and improve performance for our Raider models, missiles, and larger ships. Previously, the program was loading the same 3D model multiple times for each object, resulting in multiple copies of the same model being stored in memory. This was causing memory errors and impacting performance.

1. To address this issue, we modified the code to load each 3D model once and reuse it for each object of the same type. This reduced the number of copies of each model in memory from n to just one, which helped reduce memory usage and improve performance. We used .flattenedCopy() to reduce the complexity of the root model for each.

2. The changes were made by modifying the relevant functions to load each model once before creating the objects, and then passing the loaded model as a parameter to the object's initializer. The classes for each object type were also modified to accept a `modelNode` parameter in their initializer and store it as a property of the class. The functions that create the objects were then modified to use this property instead of loading the model again.

3. These changes allowed the program to share the same instance of each 3D model between multiple instances of the same object type, while still allowing each object to appear as its own individual entity. This helped reduce memory usage and improve performance, while still maintaining the desired behavior of the program.
 
 ### Optimization: Introduction of ParticleManager for Consolidated Particle System Configurations
 **This update presents a major step in improving the performance of the game by introducing an efficient management of particle systems via a dedicated ParticleManager class.**

 **Changes:**
 ParticleManager Class: This class is the centralized location where we define and manage our particle system configurations. Instead of creating configurations on-the-fly, they are now predefined within this class and can be accessed when needed, thereby reducing computational overhead.

 1. Static Particle Systems: We've defined the configurations for different particle systems like lasers, missile trails, and explosions as static properties in the ParticleManager. This means we can use these configurations throughout our game without creating new ones each time, which significantly reduces memory usage and boosts rendering performance.

 2. Functions for Dynamic Configurations: For the particle systems that require more dynamic properties, such as color for missile trails, we have defined functions that return configured particle systems. This gives us the best of both worlds, maintaining the performance benefits of static configurations and providing flexibility where required.

 3. Applied Changes: We've applied these changes across the Laser, GhostMissile, and Explosion classes, which now utilize the ParticleManager for their particle systems.

 These improvements should result in noticeable performance gains, particularly in high-intensity scenes with many active particle systems.

### Optimization: Quaternion-based Rotations for Improved Ship Orientation (5/29/2023)
**This update addresses the issue of gimbal lock that was affecting the orientation and navigation of ships in our game. It describes the successful implementation of quaternion-based rotations to solve this problem and improve the game's performance.**

#### Changes:
Introduction of Quaternions: In order to overcome the issue of gimbal lock that is common with Euler angle-based rotations, we have moved to quaternion-based rotations. Quaternions, represented by SCNQuaternion in SceneKit, are complex numbers that can represent 3D rotations more efficiently and reliably. They are ultimately a four-dimensional godsend that allow us to represent orientations around an imaginary (read: whichever we want) axis.

1. Avoiding Gimbal Lock: Gimbal lock is a term from mechanics and control theory, related to the use of gimbals for achieving rotation around multiple axes. It's the loss of one degree of freedom in a three-dimensional, three-gimbal system that occurs when the axes of two of the three gimbals are driven into a parallel configuration, "locking" the system into rotation in a degenerate two-dimensional space.

To understand this, imagine you're in an aircraft and you want to change its orientation. You have three degrees of freedom – you can roll (tilt side-to-side), pitch (tilt forward or backward), or yaw (turn left or right). This can be achieved by rotations around the x, y, and z axes respectively.

However, if the pitch (tilt forward or backward) is 90 degrees, that is, the aircraft is pointing straight up or straight down, then roll and yaw both end up rotating the aircraft about the same axis. You've lost a degree of freedom, and certain maneuvers are now impossible. This situation is known as gimbal lock.

In 3D computer graphics and robotics, Euler angles are often used to represent rotations, but they suffer from this gimbal lock issue. When an object's orientation approaches gimbal lock, further rotations may not have the effect one expects, leading to awkward movement or sudden jumps in orientation. 

**Quaternions** operate in four dimensions, which allows for smooth and continuous rotation in 3D space. They have been employed to rotate our ships, ensuring the avoidance of gimbal lock. With this change, we have been able to ensure consistent and predictable rotation behavior for all ships, irrespective of their current orientation.

2. Application to SceneKit: We have applied this rotation mechanism to SceneKit by modifying the orientation property of the nodes representing the ships. This property is a quaternion and by manipulating it, we were able to control the rotation of the nodes, thus achieving the desired ship orientation.

3. User Interaction: While quaternions don't suffer from gimbal lock, converting between quaternions and Euler angles, if not handled properly, could reintroduce the problem. As our app involves user input and displays rotation in terms of Euler angles, we have ensured careful handling of these situations.

Result:

The use of quaternion-based rotations has led to smoother and more realistic ship movements in the game, enhancing the overall user experience. It has eliminated the possibility of unexpected orientation behavior due to gimbal lock.
