# Plumber 💧

**Plumber** is a powerful, intuitive, and beautiful automation utility for macOS that puts you in control of your files. Stop wasting time manually sorting your downloads, documents, and other folders. Create flexible "pipelines" to automatically organize your files based on rules you define, so you can focus on what's important.

Whether you're a developer sorting source code, a designer organizing assets, or just someone who wants a tidy system, Plumber is the tool for you.

## ✨ Features

* **Powerful Pipelines**: Create an unlimited number of automation "pipelines" that watch your chosen folders for new files.
* **Run in the Background**: Plumber lives in your menu bar, silently organizing files in the background without getting in your way.
* **Intuitive Rule Builder**: Our easy-to-use, multi-step editor walks you through creating even the most complex rules. No coding required.
* **Complex Logic, Made Simple**: Go beyond basic rules. Use `AND`/`OR` logic to create highly specific conditions with our **Grouped Conditions** feature.
* **Live Activity Log**: Watch your pipelines work in real-time with a live log of all file operations.
* **Safe Dry Run Mode**: Test your pipelines on a sample file *before* you enable them. Plumber will give you a full report of what actions it would have taken, so you can be confident your rules are correct.
* **Smart & Safe**: Plumber automatically handles file name conflicts to prevent accidentally overwriting your files.
* **Native macOS Design**: Built with modern SwiftUI, Plumber looks and feels right at home on your Mac, including support for Light and Dark modes.

---

## 🔧 How It Works

Plumber's core concept is the **Pipeline**. A pipeline defines a complete automation workflow.


1.  **Intake Pipe (The "Where")**: You start by choosing one or more folders for Plumber to monitor. This is your "Intake Pipe".
2.  **Valves (The "What")**: Each pipeline has one or more "Valves". A Valve is a set of conditions that a file must meet. You can match files based on:
    * **Name**: If it contains, starts with, or ends with certain text.
    * **File Extension**: `jpg`, `pdf`, `mp4`, etc.
    * **Kind**: A general category, like Image, Video, Document, or Archive.
    * **Date Added**: How recently the file was created.
    * **Size**: If the file is larger or smaller than a specific size.
    * **Grouped Conditions**: Combine any of the above with `AND`/`OR` logic for maximum precision!
3.  **Actions (The "How")**: If a file matches a Valve's conditions, Plumber will perform a series of actions on it. These are your "Outflow Pipes".
    * **Move to Folder**: The most common action. Move the file to a destination folder.
    * **Copy to Folder**: Make a copy of the file in another location.
    * **Rename with Pattern**: Rename files using powerful placeholders like `{filename}`, `{date}`, and `{ext}`.
    * **Add Tags**: Apply Finder tags for better organization.
    * **Run Shell Script**: For ultimate power, run any custom shell script on the matched file.

---

### Example: The Ultimate Downloads Folder Sorter

Tired of a messy `~/Downloads` folder? Here’s how you could build a pipeline in Plumber to fix it forever.


* **Intake Pipe**: `~/Downloads`
* **Valve 1: "Sort Images & Videos"**
    * **IF (Grouped Condition - Match ANY)**:
        * `Kind is Image`
        * `Kind is Video`
        * `File Extension is raw`
    * **THEN**:
        * `Move to Folder` -> `~/Pictures/Sorted Imports`
* **Valve 2: "Sort Installers"**
    * **IF (Grouped Condition - Match ANY)**:
        * `File Extension is dmg`
        * `File Extension is pkg`
    * **THEN**:
        * `Move to Folder` -> `~/Documents/Installers`
* **Valve 3: "Sort Documents"**
    * **IF**: `Kind is Documents`
    * **THEN**:
        * `Move to Folder` -> `~/Documents/Incoming`

Once you enable this pipeline, Plumber will automatically perform these actions on every new file that appears in your Downloads folder.

---

## 🚀 Getting Started

1.  **Download Plumber**: In Progress
2.  **Launch the App**: The Plumber icon will appear in your menu bar.
3.  **Build Your First Pipeline**:
    * Click the menu bar icon and select "Open Dashboard".
    * Click the `+` button to open the Pipeline Editor.
    * **Step 1: Basics**: Give your pipeline a name (e.g., "Sort Screenshots") and choose an Intake Pipe (e.g., your Desktop folder).
    * **Step 2: Valves**: Configure your rules. For our example, set the condition `IF Name begins with "Screenshot "`. Then, add a `THEN` action to `Move to Folder` and choose a new "Screenshots" folder.
    * **Step 3: Finish & Test**: Use the **Dry Run** feature to test your new rule on a sample file. Once you're happy, click **Save Pipeline**.
4.  **Enable Your Pipeline**: Back on the Dashboard, make sure the toggle switch on your new pipeline card is turned on.

That's it! Plumber is now actively monitoring your folder. Sit back and enjoy the automated organization.

---

## 💬 Feedback & Support

This app is actively developed and I'd love to hear your feedback! If you encounter any bugs, have a feature request, or just want to say hello, please open an issue on this GitHub repository or email me at `youremail@example.com`.

---

Built with ❤️ and Swift for macOS.
