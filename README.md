# DTInsight: A Tool for Explicit, Interactive, and Continuous Digital Twin Reporting

[![DOI](https://img.shields.io/badge/DOI-10.1109%2Fmodels--c68889.2025.00030-blue)](https://doi.org/10.1109/models-c68889.2025.00030)
[![arXiv](https://img.shields.io/badge/arXiv-2508.18431-b31b1b.svg)](https://arxiv.org/pdf/2508.18431)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

DTInsight is a systematic and automated tool for producing **continuous reporting** for Digital Twins (DTs). It generates an interactive conceptual architecture visualization—called a **DT constellation**—from an ontological description of the DT, and integrates the output into a CI/CD-driven reporting page.

<img width="1075" alt="DTInsight conceptual architecture visualization" src="https://github.com/user-attachments/assets/6841f934-bf88-4eb5-9e41-3e4e1e57c05b">

## Key Features

DTInsight is built around **three pillars of DT reporting**:

| Pillar | What it does |
|---|---|
| **Explicit Reporting** | Model the DT using the 21 characteristics of the [DT Description Framework (DTDF)](https://github.com/oakeslabmtl/DTDF) in the Ontology Modeling Language (OML), providing a systematic and consistent description. |
| **Interactive Reporting** | Explore a DT constellation: a conceptual architecture showing data flow between Physical Twin components (Sensors, System, Environment, Operator, Machine) and DT capability layers (Models/Data, Enablers, Services). Supports real-time sensor data and 3D visualization. |
| **Continuous Reporting** | Auto-generate an up-to-date reporting page (characteristics table, architecture screenshot, interactive web embed) from a CI/CD pipeline on every commit. |

## YouTube Overview

[![DTInsight video](https://img.youtube.com/vi/CD0pdK-eGXY/0.jpg)](https://www.youtube.com/watch?v=CD0pdK-eGXY)

## Architecture & Technology Stack

DTInsight is built with the [Godot Engine](https://godotengine.org/) (v4.5, .NET/C#) and uses GDScript for the UI and visualization logic.

```
DTInsight/
├── MainScene/          # Main scene controller, CI/CD TCP server, settings
├── DTContainer/        # DT & PT constellation layout, link drawing, visual editing
├── GenericDisplay/     # Reusable DT component display, pop-up charts & scripts
├── Fuseki/             # SPARQL query catalogue, Fuseki server caller, data dump
├── RabbitMQ/           # RabbitMQ connection & real-time data handling (C#/.NET)
├── Camera/             # 2D camera controls (pan, zoom, keyboard)
├── Config/             # Global configuration (style, Fuseki, RabbitMQ, camera, etc.)
├── ControlPanel/       # Settings UI panel
├── Legends/            # Color legend for implementation status & timescale
├── Build/              # Pre-built exports (Linux, Web)
└── .github/workflows/  # GitHub Actions CI/CD for automated builds
```

**Key integrations:**
- **[Apache Jena Fuseki](https://jena.apache.org/documentation/fuseki2/)** — serves the DTDF ontology as an RDF triple store; DTInsight queries it via SPARQL over HTTP.
- **[RabbitMQ](https://www.rabbitmq.com/)** — message broker for subscribing to real-time sensor data streams (via the .NET RabbitMQ client library).
- **[openCAESAR Rosetta](https://github.com/opencaesar/oml-rosetta)** — recommended IDE for editing the OML description model.
- **GitHub Actions** — CI/CD workflow that exports Linux and Web builds on every push to `develop`.

## Getting Started

Note: You can view tutorial slides at https://1drv.ms/p/c/86984f2cdf02822a/IQDsOu-5YYM6QKA_Xj-bf8tYAROfy-sjk1sZlwdcaXVK_aY?e=CK9JFc

### Prerequisites

- **Godot Engine 4.5** (.NET / C# version) — [download](https://godotengine.org/download)
- **.NET 8 SDK** — required for the RabbitMQ C# integration
- **Apache Jena Fuseki** — bundled via openCAESAR Rosetta, or standalone
- A **DTDF-compatible OML ontology** — see the [DTDF repository](https://github.com/oakeslabmtl/DTDF)
- *(Optional)* A running **RabbitMQ** instance publishing DT sensor data

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/oakeslabmtl/DTInsight.git
   ```
2. Open the project in Godot Engine 4.5 (.NET version).
3. Build the C# solution to restore the RabbitMQ.Client NuGet package:
   ```bash
   dotnet restore
   dotnet build
   ```
4. Run the project from the Godot editor or export it for your platform.

## How to Use

### Settings

Click the **gear icon** (bottom-left) to open the settings panel.

### Loading an Ontology

#### Option A: Load from Fuseki (recommended for development)

1. Open your OML ontology project in **openCAESAR Rosetta**.
2. In the **Gradle Tasks** tab, start the Fuseki server with the **`startFuseki`** task and run the **`owlLoad`** task to push the ontology data.

   <img width="364" alt="Gradle tasks in Rosetta" src="https://github.com/user-attachments/assets/c6a36115-5984-497b-91fb-4bd2d9c2b795">

   On Windows, you can also call these tasks with:
   ```
   gradlew.bat startFuseki
   ```
   and then
   ```
   gradlew.bat owlLoad
   ```

4. In DTInsight, click the **"Call Fuseki"** button:

   <img width="47" alt="Call Fuseki button" src="https://github.com/user-attachments/assets/1771428d-2f6d-493e-bd4b-a698f8d09989">

#### Option B: Load from a dump file

If a dump was previously exported, select the file with the file picker and click **"Load"**.

<img width="205" alt="Load dump" src="https://github.com/user-attachments/assets/528b65ee-4860-4f25-8fe0-de4867ef6846">

##### Creating a dump

After loading an ontology, enter a file path in the dump input box and click **"Dump"**. The resulting file can also be inspected in a text editor to verify loaded data.

### Navigating the DT Constellation

Once loaded, you see a top-down conceptual architecture of the DT, structured as:

- **Left side (Physical Twin):** Operator, Machine, System, System Environment, Sensors/Data Transmission
- **Right side (Digital Twin):** Models/Data → Enablers → Services

Directional arrows show inter-component dependencies and data flow.

#### Camera Controls

| Action | QWERTY | AZERTY | Mouse |
|---|---|---|---|
| Move up | W | Z | Click + drag |
| Move down | S | S | Click + drag |
| Move left | A | Q | Click + drag |
| Move right | D | D | Click + drag |
| Zoom in | E | E | Scroll up |
| Zoom out | Q | A | Scroll down |

#### Highlighting Relationships

**Hover** over a component to highlight it and its connected components, revealing data-flow paths. **Click** to lock the highlight.

<img width="506" alt="Highlighting connected components" src="https://github.com/user-attachments/assets/cbc60aa2-ce5b-4b8c-a7f1-de2831155364">

#### Visual Editing

Enable **Visual Editing** mode from the control panel to:
- **Add** new components to any container via the `+` buttons
- **Rename** or edit descriptions by right-clicking a component
- **Draw links** by dragging from one component to another
- **Delete links** by enabling link deletion mode and clicking on a link

### Real-Time Data (RabbitMQ)

If your DT publishes sensor data via RabbitMQ and your ontology includes the necessary linking metadata:

1. Toggle **"Record data from RabbitMQ"** in the settings.
2. Real-time values will appear on the corresponding DT components.
3. Click the pop-up button on a component to view a **live chart** of the last 100 messages (supports numerical and boolean values).

<img width="268" alt="Real-time data" src="https://github.com/user-attachments/assets/74f23110-d190-467a-8b8b-1e16ad56fc95">

> **Note:** If nothing appears after enabling real-time data, either the ontology is missing the RabbitMQ linking data or no messages are being published. Inspect a dump file to verify the data.

### 3D Visualization (`.pck` resource pack)

1. Create a separate Godot project (same Godot version as DTInsight).
2. Create a scene called `main.tscn` with a `_on_message(message)` function to receive real-time data.
3. Export the project as a `.pck` file.
4. Ensure the OML description includes `DTDFVocab:HasVisualization true`.
5. In DTInsight, pick the `.pck` file to open the 3D visualization in a pop-up.

<img width="221" height="82" alt="Visualization pick" src="https://github.com/user-attachments/assets/bffa7c0f-5e4c-4efe-8425-fede0fa82bc6" />

The visualization reflects incoming sensor data (e.g., updated temperature labels, heater color changes).

### Viewing Component Scripts

If the ontology contains relative file paths to DT source code:

1. Select the **software folder** from the settings panel.

   <img width="184" alt="Script folder picker" src="https://github.com/user-attachments/assets/73f975d1-541c-4516-a836-24f14f805d9c">
   <img width="194" alt="Script folder selection" src="https://github.com/user-attachments/assets/2af1630a-f2ca-4333-9c27-532b979edeee">

2. Components with associated scripts will display a button with the script filename. Click to view.

   <img width="366" alt="Script viewer" src="https://github.com/user-attachments/assets/f01d9038-facd-4854-b922-830af1a2e467">

## Continuous Report Generation (CI/CD)

DTInsight integrates into a CI/CD pipeline (currently GitHub Actions) to automatically produce an up-to-date reporting page on every commit. The pipeline:

1. Loads the committed DTDF ontology into a Fuseki server.
2. Runs DTInsight (headless, via Linux `xvfb`) and triggers the internal TCP CI/CD server (port `9090`).
3. Outputs:
   - **HTML characteristics table** — summary of the 21 DTDF characteristics
   - **Architecture screenshot** — high-resolution tiled capture of the DT constellation
   - **YAML architecture dump** — machine-readable description of the constellation
4. Deploys the reporting page as a static website (via [Hugo](https://gohugo.io/)).

An example reporting page for the incubator DT is available at: [oakeslabmtl.github.io/DTDF](https://oakeslabmtl.github.io/DTDF/)

### Steps to set up continuous reporting for your DT

1. **Model your DT** in the DTDF using OML/OWL/RDF.
2. **Configure the static website** deployment (e.g., Hugo + GitHub Pages).
3. **Set up the CI/CD workflow** to load the ontology, run DTInsight, and deploy.

## Related Resources

- **DTDF Ontology & Example DT:** [oakeslabmtl/DTDF](https://github.com/oakeslabmtl/DTDF)
- **openCAESAR Rosetta:** [opencaesar/oml-rosetta](https://github.com/opencaesar/oml-rosetta)
- **Example DT (Incubator):** [INTO-CPS-Association/example_digital-twin_incubator](https://github.com/INTO-CPS-Association/example_digital-twin_incubator)

## Citation

If you use DTInsight in your research, please cite our paper. An open-access preprint is available on [arXiv](https://arxiv.org/pdf/2508.18431).

```bibtex
@INPROCEEDINGS{fiter2025dtinsight,
    author={Fiter, Kérian and Malassigné-Onfroy, Louis and Oakes, Bentley},
    booktitle={2025 ACM/IEEE 28th International Conference on Model Driven Engineering Languages and Systems Companion (MODELS-C)}, 
    title={DTInsight: A Tool for Explicit, Interactive, and Continuous Digital Twin Reporting}, 
    year={2025},
    volume={},
    number={},
    pages={139-143},
    keywords={Visualization;Three-dimensional displays;Systematics;Data visualization;Ontologies;Real-time systems;Software;Digital twins;Stakeholders;Monitoring;digital twins;software visualization;software documentation;decision-making;ontologies;OML;monitoring},
    doi={10.1109/MODELS-C68889.2025.00030}
}
```

## Credits

- **[Kérian Fiter](https://kerianfiter.github.io/)** (@KerianFiter)
- **Louis Malassigné-Onfroy** (@Ryskann)
- Under the supervision of **[Prof. Bentley Oakes](https://bentleyjoakes.github.io/)**

## License

This project is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).
