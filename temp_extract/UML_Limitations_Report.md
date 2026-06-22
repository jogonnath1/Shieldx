# UML 2.5 vs Mermaid Limitations Report

Mermaid is an incredible code-to-diagram tool, but it lacks support for the strict graphical notations defined in the OMG UML 2.5 standard. 

If you are importing these diagrams into a strict GUI tool like **draw.io** or **StarUML** for your academic defense, please make the following manual touch-ups:

### 1. Activity Diagram
* **Initial/Final Nodes:** Mermaid uses `[*]` which renders as a circle. In strict UML, make sure the Initial node is a solid black circle (●), and the Final node is a black circle enclosed in a white circle (◉).
* **Swimlanes:** Mermaid's `stateDiagram-v2` (needed for proper decision diamonds) does not natively support vertical swimlanes. In draw.io, draw two vertical partitions ("Citizen" and "System/Admin") and place the states inside them.

### 2. Use Case Diagram
* **Actors:** Mermaid's `flowchart` renders actors as circles `(( ))`. In StarUML, switch these to the standard Stick Figure graphic.
* **System Boundary:** Mermaid's `subgraph` draws a standard rectangle, but strict UML system boundaries require the name of the system to be anchored in the top-left corner of the box.

### 3. Class Diagram
* **Visibility:** Mermaid perfectly parses `+`, `-`, and `#`, but some visual tools might convert them to colored icons (green lock, red lock). Either is acceptable in modern UML.
* **Associations:** If you are using true Composition (◆) or Aggregation (◇) in your code logic (e.g. `EmergencyModel` is destroyed when `ProfileModel` is destroyed), ensure StarUML uses the solid/hollow diamonds. The Mermaid code handles the syntax correctly, but verify the render!

### 4. Sequence Diagram
* No major graphical limitations! Mermaid natively supports activation bars (`activate`), standard synchronous arrows (`->>`), and return dashed arrows (`-->>`), along with `alt` interaction fragments.

### 5. Component Diagram
* **Component Icon:** Mermaid cannot draw the official UML Component icon (a rectangle with two smaller rectangles jutting out of the left side, or the small component icon in the top-right corner).
* **Lollipop / Socket Interfaces:** Mermaid cannot natively draw the Ball-and-Socket (Provided/Required Interface) notation. You will need to manually connect components with lollipops/sockets in draw.io to represent API contracts.
