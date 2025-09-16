# DTInsight

The purpose of this project is to provide users with a graphical and interactive representation of a Digital Twin.

<img width="1075" alt="image" src="https://github.com/user-attachments/assets/6841f934-bf88-4eb5-9e41-3e4e1e57c05b">

## YouTube Overview

[![DTInsight video](https://img.youtube.com/vi/CD0pdK-eGXY/0.jpg)](https://www.youtube.com/watch?v=CD0pdK-eGXY)

# About this project

This tool was built with the aim of being cross compatible with any digital twin ontology built with the Ontology Modeling Lanuage (OML) vocabulary available at "https://github.com/oakeslabmtl/DTDF". To build such ontologies we recommend tools such as openCAESAR Rosetta available at "https://github.com/opencaesar/oml-rosetta".

To benefit from all of the real time communication features you will need a related digital twin simulator publishing its data with RabbitMQ, similar to this project "https://github.com/INTO-CPS-Association/example_digital-twin_incubator", as well as an ontology providing the necessary data to connect it to the visualization.

# How to use

To demonstrate how to use this tool we will take the example of the incubator project available with the links provided in the "About this project" section.

## Settings

Click on the gear on the bottom left button to access the settings panel.

## Load an ontology

### Load from Fuseki

This method will be used while developing new ontologies and allow users to transfer a digital twin's ontology in the visualizer.

In open CAESAR Rosetta, once the ontology is ready and buildable, you will need to access the "Gradle Tasks" tab. There you will be able to start a Fuseki server, it allows a network communication between Rosetta and the visualizer. Once the server starts, you will have to load the ontology's information in Fuseki with the task "LoadOML".

<img width="364" alt="image" src="https://github.com/user-attachments/assets/c6a36115-5984-497b-91fb-4bd2d9c2b795">

With the Fuseki server ready your Digital Twin will be available in one click in the visualizer with the "Call Fuseki" button.

<img width="47" alt="image" src="https://github.com/user-attachments/assets/1771428d-2f6d-493e-bd4b-a698f8d09989">

### Load from a dump

If a dump from an existing Digital Twin was created you will be able to access your visualization without going through the process of setting up a Fuseki server. You will only have to select the correct file from the file picker in the visualizer and click on the "Load" button.

<img width="205" alt="image" src="https://github.com/user-attachments/assets/528b65ee-4860-4f25-8fe0-de4867ef6846">

#### Create a dump

To create a dump, you will first have to load an ontology in the visualizer, then you will be able to put a dump file location in the correct input box and click on the "Dump" button. ** This dump can be read to check on the informations currently loaded in the visualizer **

## Navigate the Digital Twin

Once a Digital Twin is loaded into the visualizer, you will have a top-down view of its architecture and of its functional components.

**Camera controls :**

*QWERTY keyboard :* \
W - Move up \
S - Move down \
A - Move left \
D - Move Right \
Q - Zoom out \
E - Zoom in

*AZERTY keyboard :* \
Z - Move up \
S - Move down \
Q - Move left \
D - Move Right \
A - Zoom out \
E - Zoom in

*You can also move the camera by clicking and dragging it*

**Highlighting relationships :**

By hovering the mouse pointer on top of a component in the visualization, you will be able to highlight the selected component as well as its connected components. This feature allows you to visualize interconnections within your Digital Twin and understand how the data flow into it.

<img width="506" alt="image" src="https://github.com/user-attachments/assets/cbc60aa2-ce5b-4b8c-a7f1-de2831155364">

## Real-Time Data

If you have a Digital Twin publishing some data on RabbitMQ exchanges and an ontology providing the necessary linking data you will be able to access real time information on your Digital Twin components in the visualization.

<img width="268" alt="image" src="https://github.com/user-attachments/assets/74f23110-d190-467a-8b8b-1e16ad56fc95">

To access this functionality, you will have to load an ontology and then click on the switch "Record data form RabbitMQ". Once this switch is activated, real time data will be displayed in the DIgital Twin's component as well as a button. This button allows you to access a real time graph recording the last hundred messages coming from RabbitMQ. (At this time this graph can display numerical or boolean values.

<img width="361" alt="image" src="[https://github.com/user-attachments/assets/3cecf426-0d57-4a29-ad28-12fd7f64936d](https://github.com/user-attachments/assets/8f6d9343-2fb9-44ef-9594-b66e5959323)">

**If nothing happens when enabling real time information, it either means that your ontology is missing the linking data or that there are no messages in the RabbitMQ exchange. You can explore a dump file with a text editor to check if linking data was correctly loaded.**

## Access Digital Twin Visualization

### Preparation

- Create or Open another Godot project containing your visualization. **Warning: Godot software version must match DTInsight's**.
- Create a scene called `main.tscn` that will host your visualization.
- Configure a function `_on_message(message)` that will receive raw real-time data from DTInsight.
- Export the project as a `.pck`

### Use

If the OML description is properly configured (by having the `DTDFVocab:HasVisualization true` property), simply pick the exported `.pck` file and you will be able to open the visualization on DTInsight.

<img width="221" height="82" alt="Screenshot 2025-07-11 133809" src="https://github.com/user-attachments/assets/bffa7c0f-5e4c-4efe-8425-fede0fa82bc6" />

## Access Digital Twin script

If you have your Digital Twin's scripts on your pc and an ontology providing a relative path to those files, you will be able to access those script files from the visualizer.

To allow for better compatibility, the ontology should only contain relative paths to your files. Those path must be relative to a software folder that you will be able to select from the visualizer.

<img width="184" alt="image" src="https://github.com/user-attachments/assets/73f975d1-541c-4516-a836-24f14f805d9c">

<img width="194" alt="image" src="https://github.com/user-attachments/assets/2af1630a-f2ca-4333-9c27-532b979edeee">

Once loaded if a script is associated with a Digital Twin component, a new button will be displayed in this component with the name of the script and by clicking it you will have access to the corresponding script.

<img width="366" alt="image" src="https://github.com/user-attachments/assets/f01d9038-facd-4854-b922-830af1a2e467">

# Credits

@Ryskann / Louis Malassigné-Onfroy \
@Kérian Fiter \
Under the supervision of [Prof. Bentley Oakes](https://bentleyjoakes.github.io/)

# License

This project is licensed under the 
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).
